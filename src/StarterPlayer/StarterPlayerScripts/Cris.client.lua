-- Cris des bêtes (18/11) : de temps en temps, une bête proche pousse son cri — en son 3D, depuis
-- la bête elle-même ; la nuit, un loup hurle au loin et une chouette hulule dans les bois. Volume
-- de l'Ambiance (attribut VolAmbiance, Paramètres [O]). Rien sur le réseau : chaque client écoute
-- ce qui est autour de lui. Bruitages Pro Sound Effects (licence Roblox).

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local CRIS = {
	Mouton = { id = "rbxassetid://9113442867", vol = 0.55, range = 55 }, -- Billy Goat 7 : « bêêê »
	Vache = { id = "rbxassetid://9113626093", vol = 0.5, range = 60 }, -- Bull Bellows 7 : meuglement
}
local HOWL = { id = "rbxassetid://9120789596", vol = 0.45 } -- Wolf Howl Bay 2
local OWL = { id = "rbxassetid://9117181540", vol = 0.35 } -- Owl Hooting Reverberant

local function vol(): number
	local v = player:GetAttribute("VolAmbiance")
	return type(v) == "number" and v or 0.6
end

local function night(): boolean
	local m = workspace:GetAttribute("Minutes")
	local h = type(m) == "number" and (m / 60) % 24 or 12
	return h >= 21 or h < 5
end

-- un son placé dans le monde (attache sur le terrain), qui s'efface tout seul
local function cry(d, pos: Vector3, maxDist: number)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = workspace.Terrain
	local s = Instance.new("Sound")
	s.SoundId = d.id
	s.Volume = d.vol * vol()
	s.PlaybackSpeed = 0.9 + math.random() * 0.2 -- jamais deux fois tout à fait le même cri
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = maxDist
	s.Parent = a
	s:Play()
	Debris:AddItem(a, 12)
end

local function rootPos(): Vector3?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return r and r.Position or nil
end

-- bêtes de ferme proches (dossiers « Betes » des régions chargées)
local function nearbyBeasts(pos: Vector3)
	local out = {}
	local world = workspace:FindFirstChild("Monde")
	for _, reg in world and world:GetChildren() or {} do
		local folder = reg:FindFirstChild("Betes")
		if folder then
			for _, m in folder:GetChildren() do
				local d = CRIS[m.Name]
				if d and m:IsA("Model") then
					local p = m:GetPivot().Position
					if (p - pos).Magnitude < d.range then
						table.insert(out, { m = m, d = d, p = p })
					end
				end
			end
		end
	end
	return out
end

local function wolfFar(pos: Vector3): Vector3?
	local world = workspace:FindFirstChild("Monde")
	for _, reg in world and world:GetChildren() or {} do
		local folder = reg:FindFirstChild("Monstres")
		if folder then
			for _, m in folder:GetChildren() do
				if m.Name == "Loup" and m:IsA("Model") then
					local p = m:GetPivot().Position
					local dd = (p - pos).Magnitude
					if dd > 40 and dd < 220 then
						return p
					end
				end
			end
		end
	end
	return nil
end

task.spawn(function()
	task.wait(10)
	while true do
		task.wait(7 + math.random() * 9)
		local pos = rootPos()
		if pos and vol() > 0 and pos.Y > -40 then
			local beasts = nearbyBeasts(pos)
			if #beasts > 0 and math.random() < 0.7 then
				local b = beasts[math.random(1, #beasts)]
				cry(b.d, b.p + Vector3.new(0, 2, 0), b.d.range)
			end
			if night() then
				local w = math.random() < 0.25 and wolfFar(pos)
				if w then
					cry(HOWL, w + Vector3.new(0, 3, 0), 260)
				elseif math.random() < 0.2 then
					-- une chouette quelque part dans les arbres alentour
					local a = math.random() * math.pi * 2
					cry(OWL, pos + Vector3.new(math.cos(a) * 40, 18, math.sin(a) * 40), 120)
				end
			end
		end
	end
end)
