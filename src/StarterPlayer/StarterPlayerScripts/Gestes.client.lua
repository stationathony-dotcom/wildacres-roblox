-- Gestes (18/11) — sans animation à télécharger :
--   · gestes ponctuels : cueillir, fabriquer, manger, bâtir, commercer, offrir (dressage). Le serveur
--     pose sur le joueur l'attribut « Geste » = "type:n" (Util.geste) ;
--   · états continus : à cheval (attribut Riding : jambes écartées, genoux pliés), repos (Sleeping),
--     porter un corps
--     (attribut Carrying : bras tendus).
-- CHAQUE client anime tous les personnages (le sien et ceux des autres) en tournant leurs
-- articulations par-dessus l'animation Roblox : C0 pour un Motor6D, Attachment0 pour une
-- AnimationConstraint (nouveaux avatars). Une seule base par personnage (valeurs d'origine) :
-- base × état × geste, entrées et sorties adoucies ; au repos, chaque articulation retrouve
-- exactement sa valeur d'origine.
-- Axes (calibrés en Play) : épaule / hanche +X = vers l'avant ; taille / nuque −X = vers l'avant /
-- le bas ; genou / coude −X = plié ; hanche ±Z = jambe écartée.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local rad, sin, pi = math.rad, math.sin, math.pi
local function X(deg)
	return CFrame.Angles(rad(deg), 0, 0)
end
local function XZ(dx, dz)
	return CFrame.Angles(rad(dx), 0, rad(dz))
end

-- gestes ponctuels : p(t, w) avec t = temps écoulé (s), w = poids 0..1
local POSES = {
	sort = { dur = 0.72, p = function(t, w)
		local lance = math.clamp((t - 0.15) / 0.16, 0, 1)
		return {
			Waist = XZ((-5 - 7 * lance) * w, -5 * w), Neck = X(8 * w),
			RightShoulder = XZ((52 + 73 * lance) * w, (27 - 19 * lance) * w),
			RightElbow = X(-(84 - 70 * lance) * w),
			LeftShoulder = XZ(32 * w, -18 * w), LeftElbow = X(-36 * w),
		}
	end },
	cueillir = { dur = 1.0, p = function(t, w)
		local reach = sin(t * pi * 3) * 12
		return {
			Waist = X(-38 * w), Neck = X(-18 * w),
			RightShoulder = X((70 + reach) * w), RightElbow = X(-25 * w),
			LeftShoulder = X(35 * w),
			RightHip = X(30 * w), RightKnee = X(-45 * w), LeftHip = X(25 * w), LeftKnee = X(-40 * w),
		}
	end },
	fabriquer = { dur = 1.4, p = function(t, w)
		local hit = math.abs(sin(t * pi * 2.5)) -- trois coups de marteau
		return {
			Waist = X(-14 * w), Neck = X(-22 * w),
			RightShoulder = X((40 + hit * 75) * w), RightElbow = X(-(20 + hit * 40) * w),
			LeftShoulder = X(55 * w), LeftElbow = X(-50 * w),
		}
	end },
	manger = { dur = 1.2, son = "bouchee", sonA = 0.25, p = function(t, w)
		local bite = (sin(t * pi * 3) + 1) / 2 -- deux bouchées
		return {
			Neck = X(-6 * w * bite),
			RightShoulder = X((60 + bite * 40) * w), RightElbow = X(-(70 + bite * 40) * w),
		}
	end },
	batir = { dur = 0.55, p = function(t, w)
		return { Waist = X(-10 * w), RightShoulder = X(85 * w), LeftShoulder = X(70 * w), RightElbow = X(-15 * w), LeftElbow = X(-15 * w) }
	end },
	offrir = { dur = 2.2, p = function(t, w)
		local calm = sin(t * pi * 1.5) * 4 -- main qui tremble à peine
		return {
			Waist = X(-22 * w), Neck = X(-10 * w),
			RightShoulder = X((62 + calm) * w), RightElbow = X(-10 * w),
			RightHip = X(28 * w), RightKnee = X(-50 * w), LeftHip = X(10 * w), LeftKnee = X(-30 * w),
		}
	end },
	commerce = { dur = 0.7, p = function(t, w)
		return { RightShoulder = X(55 * w), RightElbow = X(-35 * w), Neck = X(-8 * w) }
	end },
	-- 21/11 : combat et outils (Combat.attack / shoot, Props.swing). Armement (0 → 0,35 de la durée) puis frappe.
	taille = { dur = 0.5, son = "fendre", p = function(t, w) -- épée, sabre : coup en diagonale
		local k = math.clamp(t / 0.5, 0, 1)
		local arme, frappe = math.min(1, k / 0.35), math.max(0, (k - 0.35) / 0.65)
		return {
			Waist = CFrame.Angles(0, rad((25 * arme - 55 * frappe) * w), 0),
			RightShoulder = XZ((130 * arme - 70 * frappe) * w, (35 * arme - 60 * frappe) * w), RightElbow = X(-(40 * arme - 30 * frappe) * w),
			LeftShoulder = X(25 * w),
		}
	end },
	estoc = { dur = 0.42, son = "fendre", p = function(t, w) -- dague, lance : coup droit vers l'avant
		local k = math.clamp(t / 0.42, 0, 1)
		local arme, frappe = math.min(1, k / 0.4), math.max(0, (k - 0.4) / 0.6)
		return {
			Waist = CFrame.Angles(rad(-8 * frappe * w), rad(20 * arme * w - 30 * frappe * w), 0),
			RightShoulder = X((60 + 30 * frappe) * w), RightElbow = X(-(95 * arme - 90 * frappe) * w),
			RightHip = X(-10 * frappe * w), LeftHip = X(25 * frappe * w),
		}
	end },
	lourd = { dur = 0.75, son = "lourd", p = function(t, w) -- hache, masse, marteau, espadon : à deux mains, par-dessus la tête
		local k = math.clamp(t / 0.75, 0, 1)
		local arme, frappe = math.min(1, k / 0.45), math.max(0, (k - 0.45) / 0.55)
		local lift = 160 * arme - 120 * frappe
		return {
			Waist = X((8 * arme - 30 * frappe) * w), Neck = X(-10 * frappe * w),
			RightShoulder = X(lift * w), LeftShoulder = X(lift * w), RightElbow = X(-30 * w), LeftElbow = X(-30 * w),
			RightKnee = X(-20 * frappe * w), LeftKnee = X(-20 * frappe * w),
		}
	end },
	poing = { dur = 0.38, son = "poing", sonA = 0.12, p = function(t, w, n) -- à mains nues : direct, un poing puis l'autre
		local k = math.clamp(t / 0.38, 0, 1)
		local arme, frappe = math.min(1, k / 0.3), math.max(0, (k - 0.3) / 0.7)
		local gauche = (n or 0) % 2 == 1
		local frappeur, garde = gauche and "Left" or "Right", gauche and "Right" or "Left"
		local s = gauche and -1 or 1 -- le buste tourne vers le poing qui part
		return {
			Waist = CFrame.Angles(rad(-10 * frappe * w), rad(s * (25 * arme - 45 * frappe) * w), 0),
			Neck = CFrame.Angles(0, rad(-s * 15 * frappe * w), 0),
			[frappeur .. "Shoulder"] = X((60 * arme + 35 * frappe) * w), [frappeur .. "Elbow"] = X(-(120 * arme - 115 * frappe) * w),
			[garde .. "Shoulder"] = X(70 * w), [garde .. "Elbow"] = X(-120 * w), -- garde haute
			[garde .. "Hip"] = X(20 * frappe * w), [frappeur .. "Knee"] = X(-15 * frappe * w), -- on avance d'un pas
		}
	end },
	tir = { dur = 0.85, son = "corde", sonA = 0.55, p = function(t, w) -- arc, arbalète : bander puis lâcher
		local tend = math.min(1, t / 0.55)
		local lache = t > 0.55 and 1 or 0
		return {
			Waist = CFrame.Angles(0, rad(-25 * w), 0), Neck = CFrame.Angles(0, rad(20 * w), 0),
			LeftShoulder = XZ(90 * w, -10 * w), LeftElbow = X(-5 * w),
			RightShoulder = X((90 - 5 * lache) * w), RightElbow = X(-(40 + 80 * tend - 60 * lache) * w),
		}
	end },
	lancer = { dur = 0.6, son = "fendre", p = function(t, w) -- javelot, couteau, hache de jet, fronde, harpon
		local k = math.clamp(t / 0.6, 0, 1)
		local arme, frappe = math.min(1, k / 0.5), math.max(0, (k - 0.5) / 0.5)
		return {
			Waist = CFrame.Angles(rad(-15 * frappe * w), rad((30 * arme - 50 * frappe) * w), 0),
			RightShoulder = X((150 * arme - 60 * frappe) * w), RightElbow = X(-(70 * arme - 60 * frappe) * w),
			LeftShoulder = X(50 * w), RightHip = X(-15 * frappe * w), LeftHip = X(25 * frappe * w),
		}
	end },
	abattre = { dur = 0.7, son = "lourd", p = function(t, w) -- hache de bûcheron : coup horizontal dans le tronc
		local k = math.clamp(t / 0.7, 0, 1)
		local arme, frappe = math.min(1, k / 0.45), math.max(0, (k - 0.45) / 0.55)
		return {
			Waist = CFrame.Angles(rad(-8 * w), rad((40 * arme - 70 * frappe) * w), 0),
			RightShoulder = XZ(85 * w, (60 * arme - 70 * frappe) * w), LeftShoulder = XZ(80 * w, (40 * arme - 60 * frappe) * w),
			RightElbow = X(-25 * w), LeftElbow = X(-35 * w), RightKnee = X(-15 * w), LeftKnee = X(-15 * w),
		}
	end },
	piocher = { dur = 0.7, son = "lourd", p = function(t, w) -- pioche : par-dessus l'épaule, vers le sol
		local k = math.clamp(t / 0.7, 0, 1)
		local arme, frappe = math.min(1, k / 0.45), math.max(0, (k - 0.45) / 0.55)
		local lift = 150 * arme - 140 * frappe
		return {
			Waist = X((10 * arme - 40 * frappe) * w), Neck = X(-15 * frappe * w),
			RightShoulder = X(lift * w), LeftShoulder = X((lift - 15) * w), RightElbow = X(-25 * w), LeftElbow = X(-40 * w),
			RightKnee = X(-25 * frappe * w), LeftKnee = X(-25 * frappe * w),
		}
	end },
	creuser = { dur = 0.8, p = function(t, w) -- pelle, houe : on enfonce puis on soulève
		local s = (sin(t * pi * 2.5) + 1) / 2
		return {
			Waist = X(-(25 + 15 * s) * w), Neck = X(-10 * w),
			RightShoulder = X((45 + 25 * s) * w), LeftShoulder = X((60 + 20 * s) * w), RightElbow = X(-30 * w), LeftElbow = X(-20 * w),
			RightKnee = X(-25 * w), LeftKnee = X(-30 * w), RightHip = X(15 * w), LeftHip = X(15 * w),
		}
	end },
	pecher = { dur = 0.9, son = "fendre", sonA = 0.4, p = function(t, w) -- lancer de ligne
		local k = math.clamp(t / 0.9, 0, 1)
		local arme, lance = math.min(1, k / 0.4), math.max(0, (k - 0.4) / 0.6)
		return {
			RightShoulder = X((140 * arme - 80 * lance) * w), RightElbow = X(-(50 * arme - 30 * lance) * w),
			Waist = X((6 * arme - 12 * lance) * w), LeftShoulder = X(30 * w),
		}
	end },
	arroser = { dur = 1.0, p = function(t, w) -- arrosoir penché, petit balancement
		local s = sin(t * pi * 3) * 8
		return { RightShoulder = XZ(55 * w, (10 + s) * w), RightElbow = X(-15 * w), Waist = X(-12 * w), Neck = X(-15 * w) }
	end },
	-- 19/11 : gestes de loisir (commandes /danse, /salut, /applaudir, /reverence)
	danse = { dur = 6, p = function(t, w)
		local s = sin(t * pi * 2.2)
		local c = math.cos(t * pi * 2.2)
		return {
			Waist = CFrame.Angles(0, rad(18 * s * w), rad(6 * c * w)), Neck = X(8 * c * w),
			RightShoulder = XZ((95 + 35 * s) * w, 25 * w), LeftShoulder = XZ((95 - 35 * s) * w, -25 * w),
			RightElbow = X(-50 * w), LeftElbow = X(-50 * w),
			RightHip = X(20 * math.max(0, s) * w), RightKnee = X(-35 * math.max(0, s) * w),
			LeftHip = X(20 * math.max(0, -s) * w), LeftKnee = X(-35 * math.max(0, -s) * w),
		}
	end },
	salut = { dur = 1.8, p = function(t, w)
		local wave = sin(t * pi * 5) * 22
		return { RightShoulder = XZ(150 * w, (20 + wave) * w), RightElbow = X(-20 * w), Neck = X(6 * w) }
	end },
	applaudir = { dur = 2.4, p = function(t, w)
		local clap = (sin(t * pi * 8) + 1) / 2
		return {
			RightShoulder = XZ(70 * w, (-25 - clap * 15) * w), LeftShoulder = XZ(70 * w, (25 + clap * 15) * w),
			RightElbow = X(-45 * w), LeftElbow = X(-45 * w),
		}
	end },
	reverence = { dur = 1.8, p = function(t, w)
		local bow = sin(math.min(1, t / 1.6) * pi)
		return {
			Waist = X(-45 * bow * w), Neck = X(-15 * bow * w), RightShoulder = XZ(35 * bow * w, -40 * bow * w),
			RightElbow = X(-70 * bow * w), RightHip = X(-10 * bow * w), LeftHip = X(15 * bow * w), LeftKnee = X(-20 * bow * w),
		}
	end },
}

-- états continus : attribut du joueur -> pose(w)
local STATES = {
	Riding = function(w)
		return {
			LeftHip = XZ(55 * w, -22 * w), RightHip = XZ(55 * w, 22 * w),
			LeftKnee = X(-75 * w), RightKnee = X(-75 * w),
			LeftShoulder = X(30 * w), RightShoulder = X(30 * w), LeftElbow = X(-40 * w), RightElbow = X(-40 * w),
		}
	end,
	-- repos (attribut Sleeping, posé par Game.sleep) : il s'assoupit, tête basse, épaules tombantes,
	-- et respire lentement
	Sleeping = function(w)
		local breath = sin(os.clock() * 1.6) * 3
		return {
			Neck = X((-38 + breath) * w), Waist = X((-12 - breath * 0.5) * w),
			LeftShoulder = X(-6 * w), RightShoulder = X(-6 * w), LeftKnee = X(-8 * w), RightKnee = X(-8 * w),
		}
	end,
	Carrying = function(w)
		return {
			LeftShoulder = X(75 * w), RightShoulder = X(75 * w), LeftElbow = X(-25 * w), RightElbow = X(-25 * w),
			Waist = X(6 * w), -- on se cambre un peu sous le poids
		}
	end,
}

local rigs = {} -- personnage -> { joints, base, gesture = {pose, t0}?, w = { [état] = poids }, dirty }

local function jointsOf(char: Model)
	local t = {}
	for _, d in char:GetDescendants() do
		if (d:IsA("Motor6D") or (d:IsA("AnimationConstraint") and d.Attachment0)) and not t[d.Name] then
			t[d.Name] = d
		end
	end
	return t
end

local function getCF(j): CFrame
	return j:IsA("Motor6D") and j.C0 or j.Attachment0.CFrame
end

local function setCF(j, cf: CFrame)
	if j:IsA("Motor6D") then
		j.C0 = cf
	elseif j.Attachment0 then
		j.Attachment0.CFrame = cf
	end
end

local function rigOf(char: Model)
	local r = rigs[char]
	if not r then
		local joints = jointsOf(char)
		local base = {}
		for name, j in joints do
			base[name] = getCF(j)
		end
		r = { joints = joints, base = base, w = {}, dirty = false }
		rigs[char] = r
	end
	return r
end

local function ease(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local last = os.clock()
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local dt = math.min(now - last, 0.1)
	last = now
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if char and char.Parent then
			local r = rigs[char]
			-- états voulus (on n'alloue un rig que s'il y a quelque chose à jouer)
			local wantAny = false
			for attr in STATES do
				if player:GetAttribute(attr) == true then
					wantAny = true
				end
			end
			if wantAny or (r and (r.gesture or r.dirty)) then
				r = r or rigOf(char)
				local offs = {}
				local active = false
				for attr, fn in STATES do
					local target = player:GetAttribute(attr) == true and 1 or 0
					local w = r.w[attr] or 0
					w += math.sign(target - w) * math.min(math.abs(target - w), dt / 0.25) -- 0,25 s
					r.w[attr] = w
					if w > 0.001 then
						active = true
						for name, cf in fn(ease(w)) do
							offs[name] = (offs[name] or CFrame.identity) * cf
						end
					end
				end
				local g = r.gesture
				if g then
					local t = now - g.t0
					if t >= g.pose.dur then
						r.gesture = nil
					else
						active = true
						local w = math.min(ease(t / 0.15), ease((g.pose.dur - t) / 0.2))
						local ok, res = pcall(g.pose.p, t, w, g.n)
						if ok then
							for name, cf in res do
								offs[name] = (offs[name] or CFrame.identity) * cf
							end
						end
					end
				end
				-- applique (ou remet exactement la base des articulations qui ne bougent plus)
				for name, j in r.joints do
					local base = r.base[name]
					if base and j.Parent then
						setCF(j, offs[name] and base * offs[name] or base)
					end
				end
				r.dirty = active
			end
		end
	end
end)

-- Sons des gestes (bibliothèque Roblox) : sifflement de l'arme, bouchée… joués au corps du personnage,
-- hauteur un peu variée à chaque fois. `deb`/`len` : on n'en joue qu'un morceau court.
local SONS = {
	fendre = { id = "rbxassetid://9120717850", deb = 0.05, len = 0.35, vol = 0.55, pitch = 1.25 }, -- lame qui fend l'air
	lourd = { id = "rbxassetid://9120717850", deb = 0.05, len = 0.5, vol = 0.65, pitch = 0.8 }, -- arme lourde
	poing = { id = "rbxassetid://9120717850", deb = 0.05, len = 0.22, vol = 0.4, pitch = 1.6 },
	corde = { id = "rbxassetid://9120717850", deb = 0.0, len = 0.25, vol = 0.5, pitch = 2.2 }, -- corde lâchée
	bouchee = { id = "rbxassetid://137096768206416", deb = 0, len = 0.6, vol = 0.5, pitch = 1 },
}
local function jouerSon(char: Model, nom: string)
	local s = SONS[nom]
	local root = s and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	-- même réglage que les autres bruitages (Paramètres → attribut VolAmbiance du joueur local)
	local v = Players.LocalPlayer:GetAttribute("VolAmbiance")
	local vol = (type(v) == "number" and math.clamp(v, 0, 1) or 0.6) / 0.6
	local snd = Instance.new("Sound")
	snd.SoundId = s.id
	snd.Volume = s.vol * vol
	snd.PlaybackSpeed = s.pitch * (0.92 + math.random() * 0.16)
	snd.TimePosition = s.deb
	snd.RollOffMaxDistance = 60
	snd.Parent = root
	snd:Play()
	task.delay(s.len / snd.PlaybackSpeed, function()
		snd:Destroy()
	end)
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("Geste"):Connect(function()
		local v = player:GetAttribute("Geste")
		local kind = type(v) == "string" and string.match(v, "^(%a+)")
		local char = player.Character
		local pose = kind and POSES[kind]
		if pose and char and char.Parent then
			local r = rigOf(char)
			r.gesture = { pose = pose, t0 = os.clock(), n = tonumber(string.match(v, ":(%d+)$")) } -- un nouveau geste remplace l'ancien
			r.dirty = true
			if pose.son then
				task.delay(pose.sonA or 0.15, jouerSon, char, pose.son) -- au moment de la frappe
			end
		end
	end)
	player.CharacterRemoving:Connect(function(char)
		rigs[char] = nil
	end)
end

for _, p in Players:GetPlayers() do
	watch(p)
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p)
	if p.Character then
		rigs[p.Character] = nil
	end
end)
