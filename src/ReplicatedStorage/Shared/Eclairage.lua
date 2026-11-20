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
E.OUTDOOR_DAY = Color3.fromRGB(161, 151, 136)
E.OUTDOOR_NIGHT = Color3.fromRGB(70, 80, 120)
E.AMBIENT_DAY = Color3.fromRGB(86, 79, 72)
E.AMBIENT_NIGHT = Color3.fromRGB(40, 45, 70)
-- densité d'atmosphère par beau temps (Ambiance.client la fait varier avec la météo)
E.DENSITY_CLEAR = 0.27

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
	atm.Density = E.DENSITY_CLEAR
	atm.Offset = 0.25
	atm.Color = Color3.fromRGB(196, 222, 246)
	atm.Decay = Color3.fromRGB(110, 140, 190)
	atm.Glare = 0.35
	atm.Haze = 0.7
	atm.Parent = Lighting
	local cc = Lighting:FindFirstChild("Couleurs") or Instance.new("ColorCorrectionEffect")
	cc.Name = "Couleurs"
	cc.Saturation = 0.16
	cc.Contrast = 0.08
	cc.Brightness = 0.02
	cc.TintColor = Color3.fromRGB(255, 246, 232)
	cc.Parent = Lighting
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.32
	bloom.Size = 28
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	rays.Intensity = 0.06
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
