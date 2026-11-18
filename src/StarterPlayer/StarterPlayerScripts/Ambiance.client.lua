-- Ambiance (client) : dessine la météo décidée par le serveur (attributs du Workspace Weather,
-- WeatherT, Season) et joue les sons d'ambiance. Séparé d'Interface (limite de 200 locales).
--   pluie : averse autour de la caméra (neige dans la toundra), sol plus sombre, son de pluie
--   orage : idem + éclairs (Fx "lightning") : trait de foudre, flash, tonnerre retardé par la distance
--   brouillard : brume dense ; nuageux : nuages bas
-- Réglages du joueur (attributs du Player, posés par le menu Paramètres) :
--   VolAmbiance (0-1, défaut 0,6), ReduceFlash (pas de flash blanc), ReduceShake.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Eclairage = require(Shared:WaitForChild("Eclairage"))

if workspace:GetAttribute("Mode") == "accueil" then
	return
end

-- Sons (bibliothèque Roblox, gratuits ; à remplacer ici seulement)
local SOUNDS = Config.SOUNDS or {
	rain = "rbxassetid://9112854469", -- Rain On Water 1 (Pro Sound Effects)
	thunder = { "rbxassetid://72113341430811", "rbxassetid://105118686124791" },
	wind = "rbxassetid://8202539690",
}

local function newSound(id: string, looped: boolean): Sound
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Looped = looped
	s.Volume = 0
	s.Parent = SoundService
	return s
end

local rainSound = newSound(SOUNDS.rain, true)
local windSound = newSound(SOUNDS.wind, true)

local function vol(): number
	local v = player:GetAttribute("VolAmbiance")
	return type(v) == "number" and math.clamp(v, 0, 1) or 0.6
end

-- ---------------------------------------------------------------- Averse (pluie / neige)
local emitterPart = Instance.new("Part")
emitterPart.Name = "MeteoEmetteur"
emitterPart.Anchored = true
emitterPart.CanCollide = false
emitterPart.CanQuery = false
emitterPart.CanTouch = false
emitterPart.Transparency = 1
emitterPart.Size = Vector3.new(110, 1, 110)
emitterPart.Parent = workspace.CurrentCamera

local rain = Instance.new("ParticleEmitter")
rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
rain.Color = ColorSequence.new(Color3.fromRGB(190, 205, 225))
rain.LightEmission = 0.1
rain.Transparency = NumberSequence.new(0.35)
rain.Size = NumberSequence.new(0.09)
rain.Squash = NumberSequence.new(-5) -- étiré en hauteur : des traits de pluie
rain.Lifetime = NumberRange.new(0.9, 1.1)
rain.Speed = NumberRange.new(70, 80)
rain.EmissionDirection = Enum.NormalId.Bottom
rain.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
rain.Rate = 0
rain.Parent = emitterPart

local snow = Instance.new("ParticleEmitter")
snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
snow.Color = ColorSequence.new(Color3.fromRGB(250, 250, 255))
snow.Transparency = NumberSequence.new(0.15)
snow.Size = NumberSequence.new(0.28)
snow.Lifetime = NumberRange.new(6, 8)
snow.Speed = NumberRange.new(6, 9)
snow.SpreadAngle = Vector2.new(20, 20)
snow.RotSpeed = NumberRange.new(-40, 40)
snow.EmissionDirection = Enum.NormalId.Bottom
snow.Rate = 0
snow.Parent = emitterPart

-- ---------------------------------------------------------------- Nuages et brume
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover = 0.4
clouds.Density = 0.6
clouds.Parent = workspace.Terrain

local flash = Instance.new("ColorCorrectionEffect")
flash.Name = "Eclair"
flash.Parent = Lighting
local gloom = Instance.new("ColorCorrectionEffect")
gloom.Name = "Grisaille"
gloom.Parent = Lighting

local WG = nil
local function biomeAt(pos: Vector3): string
	local seed = workspace:GetAttribute("Seed")
	if not seed then
		return "prairie"
	end
	if not WG or WG.seed ~= seed then
		local ok, mod = pcall(require, Shared:WaitForChild("WorldGen"))
		if not ok then
			return "prairie"
		end
		WG = mod.new(seed, workspace:GetAttribute("Gen"))
	end
	local CELL, REGION = Config.CELL, Config.REGION
	local rx, rz = math.floor(pos.X / CELL / REGION), math.floor(pos.Z / CELL / REGION)
	local ok, b = pcall(WG.regionBiome, WG, rx, rz)
	return ok and b or "prairie"
end

-- Cibles selon l'état (interpolées en douceur : rien ne « saute »)
local TARGETS = {
	clair = { rain = 0, cover = 0.32, density = Eclairage.DENSITY_CLEAR, dark = 0, wind = 0.15 },
	nuageux = { rain = 0, cover = 0.7, density = 0.4, dark = 0.05, wind = 0.35 },
	pluie = { rain = 1, cover = 0.88, density = 0.46, dark = 0.12, wind = 0.25 },
	orage = { rain = 1.4, cover = 0.95, density = 0.5, dark = 0.22, wind = 0.6 },
	brouillard = { rain = 0, cover = 0.6, density = 0.72, dark = 0.06, wind = 0.05 },
}
local cur = { rain = 0, cover = 0.32, density = Eclairage.DENSITY_CLEAR, dark = 0, wind = 0.15 }
local biome, biomeT = "prairie", 0

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local kind = workspace:GetAttribute("Weather") or "clair"
	local t = TARGETS[kind] or TARGETS.clair
	local k = math.clamp(dt * 0.4, 0, 1) -- ~3 s pour changer d'état
	for key, v in t do
		cur[key] += (v * (key == "rain" and (workspace:GetAttribute("WeatherT") or 1) or 1) - cur[key]) * k
	end
	biomeT -= dt
	if biomeT <= 0 then
		biomeT = 1
		biome = biomeAt(cam.CFrame.Position)
	end
	-- sous un toit ? pas de pluie qui tombe dans la maison (rayon vers le ciel)
	local camPos = cam.CFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, cam }
	local covered = workspace:Raycast(camPos, Vector3.new(0, 60, 0), params) ~= nil
	emitterPart.CFrame = CFrame.new(camPos + Vector3.new(0, 35, 0) + cam.CFrame.LookVector * 20)
	local snowy = biome == "neige" or workspace:GetAttribute("Season") == "hiver" and biome ~= "desert"
	local dry = biome == "desert"
	local amount = (covered or dry) and 0 or cur.rain
	rain.Rate = snowy and 0 or amount * 900
	snow.Rate = snowy and amount * 260 or 0
	clouds.Cover = cur.cover
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		atm.Density = cur.density
	end
	gloom.Brightness = -cur.dark * 0.5
	gloom.Saturation = -cur.dark
	local v = vol()
	rainSound.Volume = (snowy or dry) and 0 or math.min(1, cur.rain) * 0.7 * v * (covered and 0.5 or 1)
	windSound.Volume = cur.wind * 0.5 * v
	if rainSound.Volume > 0.01 and not rainSound.IsPlaying then
		rainSound:Play()
	elseif rainSound.Volume <= 0.01 and rainSound.IsPlaying then
		rainSound:Stop()
	end
	if windSound.Volume > 0.01 and not windSound.IsPlaying then
		windSound:Play()
	end
end)

-- ---------------------------------------------------------------- Éclairs
local function bolt(pos: Vector3)
	local top = pos + Vector3.new(math.random(-20, 20), 180, math.random(-20, 20))
	local folder = Instance.new("Folder")
	folder.Name = "Foudre"
	folder.Parent = workspace.CurrentCamera
	local prev = top
	for i = 1, 8 do
		local a = i / 8
		local nextP = top:Lerp(pos, a) + (i < 8 and Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)) or Vector3.zero)
		local seg = Instance.new("Part")
		seg.Anchored = true
		seg.CanCollide = false
		seg.CanQuery = false
		seg.Material = Enum.Material.Neon
		seg.Color = Color3.fromRGB(220, 230, 255)
		local len = (nextP - prev).Magnitude
		seg.Size = Vector3.new(0.6, 0.6, len)
		seg.CFrame = CFrame.lookAt((prev + nextP) / 2, nextP)
		seg.Parent = folder
		prev = nextP
	end
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 6
	light.Color = Color3.fromRGB(200, 215, 255)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Position = pos + Vector3.new(0, 4, 0)
	anchor.Parent = folder
	light.Parent = anchor
	task.delay(0.18, function()
		folder:Destroy()
	end)
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
-- Bruitages (Pro Sound Effects, licence Roblox). Les fichiers contiennent plusieurs coups : on joue
-- un morceau court, à une hauteur légèrement variée (jamais deux fois exactement le même son).
local SFX = {
	hache = { id = "rbxassetid://9120891869", len = 0.5, vol = 0.8 },
	pioche = { id = "rbxassetid://9114084736", len = 0.6, vol = 0.7 },
	pelle = { id = "rbxassetid://9114092562", len = 0.6, vol = 0.6 },
	coup = { id = "rbxassetid://9113502506", len = 0.45, vol = 0.7 },
	pieces = { id = "rbxassetid://9113849492", len = 0.8, vol = 0.5 },
	forge = { id = "rbxassetid://9116652836", len = 0.7, vol = 0.6 },
	porte = { id = "rbxassetid://9114493937", len = 0.7, vol = 0.6 },
}
local lastSfx = {}

-- Ailes des moulins : rotation locale (aucun réseau), seulement près de la caméra
do
	local CS = game:GetService("CollectionService")
	local base = {}
	game:GetService("RunService").RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local a = os.clock() * 0.6
		for _, m in CS:GetTagged("AilesMoulin") do
			if m:IsA("Model") and m.PrimaryPart and m:IsDescendantOf(workspace) then
				local b = base[m]
				if not b then
					b = m:GetPivot()
					base[m] = b
				end
				if (b.Position - cam.CFrame.Position).Magnitude < 400 then
					m:PivotTo(b * CFrame.Angles(0, 0, a))
				end
			end
		end
	end)
end
-- préchargement : sinon le tout premier coup de hache serait muet (son pas encore téléchargé)
task.spawn(function()
	local list = {}
	for _, d in SFX do
		local s = Instance.new("Sound")
		s.SoundId = d.id
		table.insert(list, s)
	end
	pcall(function()
		game:GetService("ContentProvider"):PreloadAsync(list)
	end)
end)
local function playSfx(name: string, pos: Vector3)
	local d = SFX[name]
	if not d then
		return
	end
	local now = os.clock()
	if lastSfx[name] and now - lastSfx[name] < 0.08 then
		return -- pas de mitraillage du même son
	end
	lastSfx[name] = now
	local cam = workspace.CurrentCamera
	local s = Instance.new("Sound")
	s.SoundId = d.id
	s.Volume = d.vol * vol() * 1.4
	s.PlaybackSpeed = 0.92 + math.random() * 0.16
	if pos.Magnitude < 1 then
		s.Parent = SoundService -- son « dans la tête » (pièces)
	else
		if cam and (cam.CFrame.Position - pos).Magnitude > 90 then
			return
		end
		local a = Instance.new("Part")
		a.Anchored = true
		a.CanCollide = false
		a.CanQuery = false
		a.Transparency = 1
		a.Size = Vector3.one
		a.Position = pos
		a.Parent = workspace.CurrentCamera
		s.RollOffMaxDistance = 90
		s.RollOffMinDistance = 8
		s.Parent = a
		task.delay(d.len + 0.3, function()
			a:Destroy()
		end)
	end
	s:Play()
	task.delay(d.len, function()
		-- fondu de sortie (pas de coupure sèche)
		TweenService:Create(s, TweenInfo.new(0.2), { Volume = 0 }):Play()
		task.delay(0.25, function()
			s:Destroy()
		end)
	end)
end

Remotes:WaitForChild("Fx").OnClientEvent:Connect(function(kind: string, pos, p3)
	if kind == "sfx" then
		if type(pos) == "string" and typeof(p3) == "Vector3" then
			playSfx(pos, p3)
		end
		return
	end
	if kind ~= "lightning" or typeof(pos) ~= "Vector3" then
		return
	end
	bolt(pos)
	if not player:GetAttribute("ReduceFlash") then
		flash.Brightness = 0.45
		TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
	end
	-- le tonnerre arrive avec la vitesse du son (plafonné à 3 s pour rester lisible)
	local cam = workspace.CurrentCamera
	local dist = cam and (cam.CFrame.Position - pos).Magnitude or 50
	task.delay(math.min(3, dist / 120), function()
		local ids = SOUNDS.thunder
		local s = newSound(ids[math.random(1, #ids)], false)
		s.Volume = math.clamp(1.2 - dist / 300, 0.25, 1) * vol() * 1.2
		s:Play()
		s.Ended:Once(function()
			s:Destroy()
		end)
	end)
end)

-- ---------------------------------------------------------------- Paramètres [O] (étape 20)
-- Volume de l'ambiance, flashs d'éclair, secousses de caméra. Sauvegardés avec le perso
-- (action "settings") et réappliqués à chaque connexion (payload Inventory.settings).
do
	local UserInputService = game:GetService("UserInputService")
	local settings = { vol = 0.6, flash = false, shake = false }
	local function apply()
		player:SetAttribute("VolAmbiance", settings.vol)
		player:SetAttribute("ReduceFlash", settings.flash or nil)
		player:SetAttribute("ReduceShake", settings.shake or nil)
	end
	apply()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Parametres"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Parent = player:WaitForChild("PlayerGui")
	local GOLD = Color3.fromRGB(232, 186, 60)
	local function corner(p, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r or 6)
		c.Parent = p
	end
	local function txt(parent, text, size, pos, sizeT, color)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Text = text
		l.Font = Enum.Font.GothamBold
		l.TextSize = sizeT or 14
		l.TextColor3 = color or Color3.fromRGB(240, 230, 210)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Size = size
		l.Position = pos
		l.Parent = parent
		return l
	end
	local function btn(parent, text, size, pos, color, fn)
		local b = Instance.new("TextButton")
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 14
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.BackgroundColor3 = color
		b.AutoButtonColor = true
		b.Size = size
		b.Position = pos
		b.Parent = parent
		corner(b)
		b.Activated:Connect(function()
			-- petit rebond : le clic se sent
			b.Size = size - UDim2.fromOffset(4, 4)
			TweenService:Create(b, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = size }):Play()
			fn()
		end)
		return b
	end
	local panel = Instance.new("Frame")
	panel.Name = "Panneau"
	panel.Size = UDim2.fromOffset(330, 250)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(24, 19, 15)
	panel.Visible = false
	panel.Parent = gui
	corner(panel)
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(176, 140, 72)
	st.Thickness = 2.5
	st.Parent = panel
	txt(panel, "⚙️  Paramètres", UDim2.new(1, -50, 0, 30), UDim2.fromOffset(14, 8), 20, GOLD)
	local dirty = false
	local render
	local function close()
		panel.Visible = false
		if dirty then
			dirty = false
			Remotes.Action:FireServer("settings", settings)
		end
	end
	btn(panel, "X", UDim2.fromOffset(28, 28), UDim2.new(1, -36, 0, 8), Color3.fromRGB(190, 60, 50), close)
	txt(panel, "🔊 Ambiance (pluie, vent, tonnerre)", UDim2.new(1, -28, 0, 20), UDim2.fromOffset(14, 48), 13)
	local volRow = Instance.new("Frame")
	volRow.BackgroundTransparency = 1
	volRow.Size = UDim2.new(1, -28, 0, 34)
	volRow.Position = UDim2.fromOffset(14, 70)
	volRow.Parent = panel
	local toggles = {}
	local function toggle(y, label, key)
		txt(panel, label, UDim2.new(1, -110, 0, 30), UDim2.fromOffset(14, y), 13)
		toggles[key] = btn(panel, "", UDim2.fromOffset(80, 28), UDim2.new(1, -94, 0, y + 1), Color3.fromRGB(60, 50, 40), function()
			settings[key] = not settings[key]
			dirty = true
			apply()
			render()
		end)
	end
	toggle(116, "⚡ Réduire les flashs (éclairs)", "flash")
	toggle(152, "📳 Réduire les secousses", "shake")
	local help = txt(panel, "Dans le chat : /bloquer <pseudo> · /debloquer · /autoriser <pseudo> coffres|batir · /retirer <pseudo> · /autorises\n[O] Paramètres · [M] Carte",
		UDim2.new(1, -28, 0, 44), UDim2.fromOffset(14, 192), 11, Color3.fromRGB(150, 140, 120))
	help.TextWrapped = true
	render = function()
		volRow:ClearAllChildren()
		for i = 0, 5 do
			local v = i / 5
			local on = math.abs(settings.vol - v) < 0.05
			btn(volRow, i == 0 and "🔇" or tostring(i * 20), UDim2.fromOffset(46, 30), UDim2.fromOffset(i * 50, 2),
				on and GOLD or Color3.fromRGB(60, 50, 40), function()
					settings.vol = v
					dirty = true
					apply()
					render()
				end)
		end
		for key, b in toggles do
			b.Text = settings[key] and "Oui" or "Non"
			b.BackgroundColor3 = settings[key] and Color3.fromRGB(70, 140, 70) or Color3.fromRGB(60, 50, 40)
		end
	end
	render()
	local open = btn(gui, "⚙️", UDim2.fromOffset(40, 40), UDim2.new(1, -52, 0, 222), Color3.fromRGB(40, 32, 24), function()
		if panel.Visible then
			close()
		else
			render()
			panel.Visible = true
		end
	end)
	open.Name = "BoutonParametres"
	open.TextSize = 20
	-- sur PC, le bouton « Paramètres » du HUD (Interface) remplace ce petit bouton
	open.Visible = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local function toggleParams()
		if panel.Visible then
			close()
		else
			render()
			panel.Visible = true
		end
	end
	local ouvrir = Instance.new("BindableEvent")
	ouvrir.Name = "OuvrirParametres"
	ouvrir.Event:Connect(toggleParams)
	ouvrir.Parent = player
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.O then
			toggleParams()
		end
	end)
	Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function(data)
		if type(data) == "table" and type(data.settings) == "table" and not panel.Visible then
			settings.vol = tonumber(data.settings.vol) or settings.vol
			settings.flash = data.settings.flash == true
			settings.shake = data.settings.shake == true
			apply()
		end
	end)
end
