-- Gestes (18/11) : cueillir, fabriquer, manger, bâtir, commercer, offrir (dressage) — sans animation à télécharger.
-- Le serveur pose sur le joueur l'attribut « Geste » = "type:n" (Util.geste) ; CHAQUE client anime
-- le personnage concerné (le sien et ceux des autres) en tournant ses articulations par-dessus
-- l'animation de marche : C0 pour un Motor6D, Attachment0 pour une AnimationConstraint (nouveaux
-- avatars). Entrée et sortie adoucies ; à la fin, chaque articulation retrouve exactement sa valeur.
-- Axes (calibrés en Play) : épaule / hanche +X = vers l'avant ; taille / nuque −X = vers l'avant /
-- le bas ; genou / coude −X = plié.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local rad, sin, pi = math.rad, math.sin, math.pi
local function X(deg)
	return CFrame.Angles(rad(deg), 0, 0)
end

-- p(t, w) : t = temps écoulé (s), w = poids 0..1 ; renvoie { articulation = CFrame }
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

local active = {} -- personnage -> { pose, t0, joints, base }

local function jointsOf(char: Model)
	local t = {}
	for _, d in char:GetDescendants() do
		if (d:IsA("Motor6D") or (d:IsA("AnimationConstraint") and d.Attachment0)) and not t[d.Name] then
			t[d.Name] = d
		end
	end
	return t
end

local function getBase(j)
	return j:IsA("Motor6D") and j.C0 or j.Attachment0.CFrame
end

local function setRel(j, base: CFrame, cf: CFrame)
	if j:IsA("Motor6D") then
		j.C0 = base * cf
	elseif j.Attachment0 then
		j.Attachment0.CFrame = base * cf
	end
end

local function stop(char)
	local a = active[char]
	if not a then
		return
	end
	active[char] = nil
	for name, base in a.base do
		local j = a.joints[name]
		if j and j.Parent then
			setRel(j, base, CFrame.identity)
		end
	end
end

local function start(char: Model, kind: string)
	local pose = POSES[kind]
	if not pose or not char.Parent then
		return
	end
	local prev = active[char]
	stop(char) -- un nouveau geste remplace l'ancien (bases restaurées d'abord)
	local joints = (prev and prev.joints) or jointsOf(char)
	local base = {}
	for name, j in joints do
		base[name] = getBase(j)
	end
	active[char] = { pose = pose, t0 = os.clock(), joints = joints, base = base }
end

-- entrée en 0,15 s, sortie en 0,2 s (ease in-out)
local function weight(t: number, dur: number): number
	local function ease(x)
		x = math.clamp(x, 0, 1)
		return x * x * (3 - 2 * x)
	end
	return math.min(ease(t / 0.15), ease((dur - t) / 0.2))
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for char, a in active do
		local t = now - a.t0
		if t >= a.pose.dur or not char.Parent then
			stop(char)
		else
			local w = weight(t, a.pose.dur)
			local ok, offs = pcall(a.pose.p, t, w)
			if ok then
				for name, cf in offs do
					local j, base = a.joints[name], a.base[name]
					if j and base and j.Parent then
						setRel(j, base, cf)
					end
				end
			end
		end
	end
end)

local function watch(player: Player)
	player:GetAttributeChangedSignal("Geste"):Connect(function()
		local v = player:GetAttribute("Geste")
		local kind = type(v) == "string" and string.match(v, "^(%a+)")
		local char = player.Character
		if kind and char then
			start(char, kind)
		end
	end)
	player.CharacterRemoving:Connect(function(char)
		active[char] = nil
	end)
end

for _, p in Players:GetPlayers() do
	watch(p)
end
Players.PlayerAdded:Connect(watch)
