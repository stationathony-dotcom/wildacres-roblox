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
	manger = { dur = 1.2, p = function(t, w)
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
						local ok, res = pcall(g.pose.p, t, w)
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

local function watch(player: Player)
	player:GetAttributeChangedSignal("Geste"):Connect(function()
		local v = player:GetAttribute("Geste")
		local kind = type(v) == "string" and string.match(v, "^(%a+)")
		local char = player.Character
		local pose = kind and POSES[kind]
		if pose and char and char.Parent then
			local r = rigOf(char)
			r.gesture = { pose = pose, t0 = os.clock() } -- un nouveau geste remplace l'ancien
			r.dirty = true
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
