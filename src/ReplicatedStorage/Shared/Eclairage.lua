-- Réglages de lumière et de couleurs du monde (image cible du 18/11 : ciel bleu franc, soleil
-- chaud, couleurs saturées, peu de brume). Un seul endroit : appliqué par Clock (serveur) et par
-- tools/bancs/village_apercu.luau (aperçu en mode Edit), pour que l'aperçu = le jeu.

local E = {}

-- couleurs fixes des matières (une matière = un biome)
E.TERRAIN = {
	[Enum.Material.Grass] = Color3.fromRGB(80, 139, 53), -- prairie, vert franc
	[Enum.Material.LeafyGrass] = Color3.fromRGB(198, 132, 62), -- forêt rousse (tapis de feuilles)
	[Enum.Material.Ground] = Color3.fromRGB(173, 132, 92), -- chemins de terre chauds
	[Enum.Material.Sand] = Color3.fromRGB(228, 206, 146),
	[Enum.Material.Sandstone] = Color3.fromRGB(212, 156, 104), -- désert : pistes et falaises
	[Enum.Material.Snow] = Color3.fromRGB(236, 242, 248),
	[Enum.Material.Slate] = Color3.fromRGB(110, 118, 128),
	[Enum.Material.Mud] = Color3.fromRGB(96, 84, 58), -- marais
	[Enum.Material.Rock] = Color3.fromRGB(132, 126, 118),
	[Enum.Material.Cobblestone] = Color3.fromRGB(166, 150, 126), -- pavés beiges des places
}

-- jour / nuit (Clock interpole)
E.OUTDOOR_DAY = Color3.fromRGB(166, 154, 136)
E.OUTDOOR_NIGHT = Color3.fromRGB(58, 72, 112)
E.AMBIENT_DAY = Color3.fromRGB(86, 79, 72)
E.AMBIENT_NIGHT = Color3.fromRGB(35, 42, 68)
E.DENSITY_CLEAR = 0.15
E.CIEL_CLAIR = {
	color = Color3.fromRGB(188, 217, 245),
	decay = Color3.fromRGB(92, 133, 183),
	haze = 0.17,
}

local CIEL_SOIR = Color3.fromRGB(240, 176, 130)
local HORIZON_SOIR = Color3.fromRGB(151, 103, 143)
local CIEL_NUIT = Color3.fromRGB(101, 135, 198)
local HORIZON_NUIT = Color3.fromRGB(45, 67, 120)

function E.appliquerAtmosphere(atm: Atmosphere, heure: number, couverture: number, densite: number,
	voile: number, ciel: Color3, horizon: Color3)
	local nuit = math.clamp(math.max((7.5 - heure) / 3, (heure - 17.25) / 3), 0, 1)
	nuit = nuit * nuit * (3 - 2 * nuit)
	local distance = math.min(math.abs(heure - 6.5), math.abs(heure - 18.5))
	local crepuscule = math.clamp(1 - distance / 2.5, 0, 1)
	local airClair = 1 - math.clamp(couverture, 0, 1)

	atm.Density = math.min(0.9, densite + crepuscule * 0.018 + nuit * 0.025)
	atm.Offset = 0.19 + nuit * 0.05
	atm.Haze = voile + crepuscule * airClair * 0.27 + nuit * 0.10
	atm.Glare = (0.22 + crepuscule * 0.12) * airClair * (1 - nuit)
	atm.Color = ciel:Lerp(CIEL_SOIR, crepuscule * airClair * 0.45):Lerp(CIEL_NUIT, nuit * 0.43)
	atm.Decay = horizon:Lerp(HORIZON_SOIR, crepuscule * airClair * 0.55):Lerp(HORIZON_NUIT, nuit * 0.52)
end

function E.apply(Lighting: Lighting, terrain: Terrain)
	Lighting.Brightness = 3
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.34
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = E.OUTDOOR_DAY
	Lighting.Ambient = E.AMBIENT_DAY
	Lighting.ShadowSoftness = 0.30
	Lighting.GeographicLatitude = 30
	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	local clair = E.CIEL_CLAIR
	E.appliquerAtmosphere(atm, Lighting.ClockTime, 0.32, E.DENSITY_CLEAR, clair.haze, clair.color, clair.decay)
	atm.Parent = Lighting
	local cc = Lighting:FindFirstChild("Couleurs") or Instance.new("ColorCorrectionEffect")
	cc.Name = "Couleurs"
	cc.Saturation = 0.19
	cc.Contrast = 0.08
	cc.Brightness = 0.02
	cc.TintColor = Color3.fromRGB(255, 250, 241)
	cc.Parent = Lighting
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.25
	bloom.Size = 22
	bloom.Threshold = 1.55
	bloom.Parent = Lighting
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	rays.Intensity = 0.04
	rays.Spread = 0.6
	rays.Parent = Lighting
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky.SunAngularSize = 16
		sky.MoonAngularSize = 9
	end
	terrain.WaterColor = Color3.fromRGB(48, 146, 180)
	terrain.WaterTransparency = 0.5
	terrain.WaterReflectance = 0.35
	terrain.WaterWaveSize = 0.12
	terrain.WaterWaveSpeed = 8
	-- herbe du terrain plus haute (image cible) ; les touffes hautes s'y ajoutent (HerbeHaute.client)
	pcall(function()
		terrain.Decoration = true
		terrain.GrassLength = 0.4 -- 0,6 cachait les petits objets et le butin au sol (vu en capture le 19/11)
	end)
	for m, c in E.TERRAIN do
		terrain:SetMaterialColor(m, c)
	end
end

return E
