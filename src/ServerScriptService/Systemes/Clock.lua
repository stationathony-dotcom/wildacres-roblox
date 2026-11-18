-- Temps qui passe (multi : il ne s'arrête jamais) : cycle de 24 h, nouveau jour à 6 h, éclairage,
-- lampes allumées la nuit. Pas de saisons : chaque biome a ses couleurs de sol et de feuillage.
-- G.world.minutes va de 6 h (360) à 6 h le lendemain (1800) : Clock.now() reste croissant.

local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local Clock = {}
local G
local Config
local lampsOn = nil

local Eclairage = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Eclairage"))
local AUTUMN = { Color3.fromRGB(214, 120, 40), Color3.fromRGB(196, 70, 40), Color3.fromRGB(226, 170, 60), Color3.fromRGB(180, 90, 50) }

function Clock.init(g)
	G = g
	Config = G.Config
	-- lumière vive et chaude, peu de brume (réglages dans Shared.Eclairage, partagés avec l'aperçu Edit)
	Eclairage.apply(Lighting, workspace.Terrain)
end

function Clock.hour(): number
	return (G.world.minutes / 60) % 24
end

-- Minutes absolues depuis le début de la partie
function Clock.now(): number
	return G.world.day * 1440 + G.world.minutes
end

-- Biome à une position du monde
function Clock.biomeAt(pos: Vector3): string
	if not G.wg then
		return "prairie"
	end
	return G.wg:biome(math.floor(pos.X / Config.CELL), math.floor(pos.Z / Config.CELL))
end

function Clock.isNight(): boolean
	local h = Clock.hour()
	return h >= 21 or h < 6
end

-- Couleur d'un feuillage selon le biome
local function leafColor(p: BasePart, biome: string)
	local base = p:GetAttribute("CouleurPrintemps") or p.Color
	local caduc = p:GetAttribute("Caduc")
	p.Transparency = 0
	if biome == "foret" and caduc then
		local h = math.floor(math.abs(p.Position.X * 7 + p.Position.Z * 13)) % #AUTUMN + 1
		return AUTUMN[h]
	elseif biome == "neige" then
		return base:Lerp(Color3.fromRGB(240, 245, 250), 0.5)
	elseif biome == "desert" then
		return base:Lerp(Color3.fromRGB(176, 160, 92), 0.45)
	elseif biome == "marais" then
		return base:Lerp(Color3.fromRGB(56, 88, 48), 0.35)
	end
	return base
end

-- Teinte un modèle selon le biome où il est posé (nom gardé : appelé partout au chargement)
function Clock.seasonize(model: Instance)
	local pos = model:IsA("Model") and model:GetPivot().Position or (model:IsA("BasePart") and model.Position) or nil
	local b = pos and Clock.biomeAt(pos) or "prairie"
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and CollectionService:HasTag(d, "Feuillage") then
			d.Color = leafColor(d, b)
		end
		if d:IsA("BasePart") and CollectionService:HasTag(d, "LumiereNuit") then
			Clock.setLamp(d, lampsOn == true)
		end
		if d:IsA("BasePart") and CollectionService:HasTag(d, "Fenetre") then
			Clock.setWindow(d, lampsOn == true)
		end
	end
end

function Clock.setLamp(p: BasePart, on: boolean)
	p.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
	p.Color = on and Color3.fromRGB(255, 214, 120) or Color3.fromRGB(200, 180, 140)
	for _, l in p:GetChildren() do
		if l:IsA("Light") then
			l.Enabled = on
		end
	end
end

-- Fenêtres des maisons : vitre sombre le jour, chaude et lumineuse le soir (les gens sont rentrés)
function Clock.setWindow(p: BasePart, on: boolean)
	p.Material = on and Enum.Material.Neon or Enum.Material.Glass
	p.Color = on and Color3.fromRGB(255, 186, 96) or Color3.fromRGB(52, 62, 70)
	p.Transparency = on and 0.15 or 0.2
end

local function updateLighting()
	local h = Clock.hour()
	Lighting.ClockTime = h
	-- nuits bleutées mais lisibles
	local night = 0
	if h >= 19 or h < 5 then
		night = 1
	elseif h >= 17 then
		night = (h - 17) / 2
	elseif h < 7 then
		night = (7 - h) / 2
	end
	Lighting.OutdoorAmbient = Eclairage.OUTDOOR_DAY:Lerp(Eclairage.OUTDOOR_NIGHT, night)
	Lighting.Ambient = Eclairage.AMBIENT_DAY:Lerp(Eclairage.AMBIENT_NIGHT, night)
	local on = h >= 18.5 or h < 6.5
	if on ~= lampsOn then
		lampsOn = on
		for _, p in CollectionService:GetTagged("LumiereNuit") do
			if p:IsA("BasePart") and p:IsDescendantOf(workspace) then
				Clock.setLamp(p, on)
			end
		end
		for _, p in CollectionService:GetTagged("Fenetre") do
			if p:IsA("BasePart") and p:IsDescendantOf(workspace) then
				Clock.setWindow(p, on)
			end
		end
	end
end

function Clock.start()
	updateLighting()
	if G.Meteo and G.Meteo.start then
		G.Meteo.start()
	end
	if G.Barques and G.Barques.start then
		G.Barques.start()
	end
	if G.Avantpostes and G.Avantpostes.start then
		G.Avantpostes.start()
	end
	if G.Nasses and G.Nasses.start then
		G.Nasses.start()
	end
	workspace:SetAttribute("Day", G.world.day)
	workspace:SetAttribute("Minutes", G.world.minutes)
end

local acc = 0
function Clock.step(dt: number)
	G.world.minutes += dt * Config.GAME_MIN_PER_SEC * (G.timeScale or 1)
	acc += dt
	if acc > 0.25 then
		acc = 0
		updateLighting()
		workspace:SetAttribute("Minutes", G.world.minutes)
	end
	if G.world.minutes >= Config.DAY_START + 1440 then
		G.world.minutes -= 1440
		Clock.newDay()
	end
end

-- Nouveau jour à 6 h : les cultures poussent, les PNJ refont leur journée, etc.
function Clock.newDay()
	G.world.day += 1
	workspace:SetAttribute("Day", G.world.day)
	workspace:SetAttribute("Minutes", G.world.minutes)
	updateLighting()
	for _, sys in G.daySystems do
		local ok, err = pcall(sys.newDay)
		if not ok then
			warn("[WildAcres] nouveau jour : " .. tostring(err))
		end
	end
end

-- Tout le monde dort : on saute directement à 6 h du matin
function Clock.skipToMorning()
	if G.world.minutes < Config.DAY_START + 1440 then
		G.world.minutes = Config.DAY_START + 1440
	end
	G.world.minutes -= 1440
	Clock.newDay()
end

return Clock
