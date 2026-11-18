-- Musique (18/11) — discrète, façon Minecraft : un morceau selon le lieu et l'heure, puis un long
-- silence (60 à 120 s) ; fondu de 3 s quand on change d'ambiance (entrer dans une grotte, la nuit
-- qui tombe, arriver au village). Volume réglable dans les Paramètres [O] (attribut VolMusique,
-- 0 = coupée). Morceaux de la bibliothèque sous licence Roblox (APM Music, DistroKid), libres
-- d'utilisation dans toute expérience.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local BASE = 0.32 -- plein volume du réglage = musique de fond, jamais par-dessus le jeu
local TRACKS = {
	jour = { "rbxassetid://121655004195658", "rbxassetid://87479584695420" }, -- Peaceful Kingdom, Ravensmoor Keep
	village = { "rbxassetid://138384771239589", "rbxassetid://1839906422" }, -- Cozy Tavern Ambience VII, Medieval Castle (APM)
	nuit = { "rbxassetid://120866009116648" }, -- Forest Library of Elders
	grotte = { "rbxassetid://96727522170625" }, -- strange hallway
}
local SILENCE_MIN, SILENCE_MAX = 60, 120

local group = Instance.new("SoundGroup")
group.Name = "Musique"
group.Volume = 1
group.Parent = SoundService

local sound: Sound? = nil
local context: string? = nil
local silenceUntil = os.clock() + 8 -- un premier morceau peu après l'arrivée
local lastIdx = {}

local function vol(): number
	local v = player:GetAttribute("VolMusique")
	return (type(v) == "number" and v or 0.5) * BASE
end

-- générateur du monde (lieux) : le même que le serveur, à partir des attributs du workspace
local wg = nil
local function world()
	local seed = workspace:GetAttribute("Seed")
	if not seed then
		return nil
	end
	if not wg or wg.seed ~= seed then
		local ok, WG = pcall(require, Shared:WaitForChild("WorldGen"))
		if not ok then
			return nil
		end
		wg = WG.new(seed, workspace:GetAttribute("Gen"))
	end
	return wg
end

local function contextNow(): string?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local pos = root.Position
	if pos.Y < -40 then
		return "grotte"
	end
	local minutes = workspace:GetAttribute("Minutes")
	local h = type(minutes) == "number" and (minutes / 60) % 24 or 12
	if h >= 20.5 or h < 5.5 then
		return "nuit"
	end
	local w = world()
	if w then
		local cx, cz = math.floor(pos.X / Config.CELL), math.floor(pos.Z / Config.CELL)
		local poi = w:poiOf(math.floor(cx / Config.REGION), math.floor(cz / Config.REGION))
		if poi and poi.kind == "village" and cx >= poi.x0 - 6 and cx <= poi.x0 + poi.w + 6 and cz >= poi.z0 - 6 and cz <= poi.z0 + poi.d + 6 then
			return "village"
		end
	end
	return "jour"
end

local function fadeOut(s: Sound, t: number)
	local tw = TweenService:Create(s, TweenInfo.new(t, Enum.EasingStyle.Sine), { Volume = 0 })
	tw.Completed:Connect(function()
		s:Destroy()
	end)
	tw:Play()
end

local function play(ctx: string)
	local list = TRACKS[ctx]
	if not list or #list == 0 then
		return
	end
	-- jamais deux fois de suite le même morceau dans une ambiance qui en a plusieurs
	local i = math.random(1, #list)
	if #list > 1 and i == lastIdx[ctx] then
		i = i % #list + 1
	end
	lastIdx[ctx] = i
	local s = Instance.new("Sound")
	s.Name = "Morceau"
	s.SoundId = list[i]
	s.Volume = 0
	s.SoundGroup = group
	s.Parent = group
	s.Ended:Connect(function()
		if sound == s then
			sound = nil
			silenceUntil = os.clock() + math.random(SILENCE_MIN, SILENCE_MAX)
		end
		s:Destroy()
	end)
	s:Play()
	TweenService:Create(s, TweenInfo.new(3, Enum.EasingStyle.Sine), { Volume = vol() }):Play()
	sound = s
end

player:GetAttributeChangedSignal("VolMusique"):Connect(function()
	if sound then
		sound.Volume = vol()
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		local ctx = contextNow()
		if ctx and ctx ~= context then
			-- changement d'ambiance : le morceau en cours s'éteint, le suivant vient vite
			local was = context
			context = ctx
			if sound then
				fadeOut(sound, 3)
				sound = nil
			end
			if was ~= nil then
				silenceUntil = math.min(silenceUntil, os.clock() + 4)
			end
		end
		if ctx and not sound and os.clock() >= silenceUntil and vol() > 0 then
			play(ctx)
		end
	end
end)
