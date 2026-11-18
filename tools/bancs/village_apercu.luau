-- Aperçu d'un village en mode Edit (sans Play) : maquette à la manière de l'image cible
-- (chemin, maisons, moulin, champs de blé, tableau des quêtes, lanterne, PNJ, arbres, château sur colline),
-- avec les VRAIS modèles de ServerStorage.Modeles. Sert à juger modèles + lumière par capture.
-- Relancer = remplace la maquette. Pour l'enlever : loadstring(src)("effacer")
local MODE = ...
local TER = workspace.Terrain
local old = workspace:FindFirstChild("ApercuVillage")
if old then
	old:Destroy()
end
local ZONE = Region3.new(Vector3.new(-160, -20, -260), Vector3.new(160, 60, 40)):ExpandToGrid(4)
TER:FillRegion(ZONE, 4, Enum.Material.Air)
if MODE == "effacer" then
	return "maquette effacée"
end

-- même lumière que le jeu (Shared.Eclairage, cloné pour contourner le cache de require)
local sh = game.ReplicatedStorage.Shared.Eclairage:Clone()
sh.Parent = game:GetService("ServerStorage")
require(sh).apply(game:GetService("Lighting"), TER)
sh:Destroy()
game:GetService("Lighting").ClockTime = 14.6
local clouds = TER:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover, clouds.Density = 0.32, 0.6
clouds.Parent = TER

local M = game:GetService("ServerStorage").Modeles
local root = Instance.new("Model")
root.Name = "ApercuVillage"

-- sol : herbe, chemin de terre, colline du château
TER:FillBlock(CFrame.new(0, -4, -110), Vector3.new(320, 8, 300), Enum.Material.Grass)
TER:FillBlock(CFrame.new(0, -0.6, -60), Vector3.new(14, 1.4, 160), Enum.Material.Ground)
TER:FillBlock(CFrame.new(-34, -0.6, -40) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(10, 1.4, 50), Enum.Material.Ground)
TER:FillBall(Vector3.new(-10, -40, -250), 90, Enum.Material.Grass)
TER:FillBlock(CFrame.new(40, -0.4, -150), Vector3.new(60, 2, 20), Enum.Material.Water)

local function place(name: string, x: number, z: number, rotY: number?, y: number?, scale: number?)
	local src = M:FindFirstChild(name)
	if not src then
		return nil
	end
	local m = src:Clone()
	if scale and m:IsA("Model") then
		m:ScaleTo(scale)
	end
	local cf, size = m:GetBoundingBox()
	local pivot = m:GetPivot()
	local bottom = cf.Position.Y - size.Y / 2
	local off = pivot.Position - Vector3.new(cf.Position.X, bottom, cf.Position.Z)
	m:PivotTo(CFrame.new(x, y or 0, z) * CFrame.Angles(0, math.rad(rotY or 0), 0) * CFrame.new(off) * (pivot - pivot.Position))
	m.Parent = root
	return m
end

-- rangée gauche de maisons (façades vers le chemin)
place("Maison_A", -34, -18, 90)
place("Maison_B", -36, -50, 90)
place("Taverne", -38, -88, 90)
place("Maison_C", -34, -124, 90)
place("Auberge", 36, -110, -90)
-- champs de blé à droite (vrai modèle Champ_Ble), tableau des quêtes au bord du chemin
place("Champ_Ble", 30, -18, -90)
place("Champ_Ble", 30, -44, -90)
place("Tableau_Quetes", -11, -60, 90)
place("Moulin_Village", 46, -66, -90)
place("Lampadaire", 9, -14)
place("Lanterne", -9, -34)
place("PNJ_Base", 14, -16, -100)
place("Epouvantail", 30, -30, -90)
place("Tonneaux", -20, -30, 0)
place("Caisses", -20, -64, 0)
place("Puits", -14, -104)
place("Etal", 18, -100, -90)
place("Marche_Village", 12, -132, 0)
-- arbres et buissons autour
local trees = { "Arbre_Sapin", "Arbre_Chene", "Arbre_Sapin", "Arbre_Bouleau", "Arbre_Sapin" }
local rnd = Random.new(7)
for i = 1, 46 do
	local x = rnd:NextNumber(-150, 150)
	local z = rnd:NextNumber(-230, -10)
	if math.abs(x) > 62 or z < -160 then
		place(trees[rnd:NextInteger(1, #trees)], x, z, rnd:NextNumber(0, 360), 0, rnd:NextNumber(1.1, 1.7))
	end
end
for i = 1, 22 do
	local x = rnd:NextNumber(-60, 60)
	local z = rnd:NextNumber(-150, -6)
	if math.abs(x) > 10 and not (x > 12 and x < 48 and z > -46) then
		place(rnd:NextNumber() < 0.5 and "Buisson" or "Fleurs", x, z, rnd:NextNumber(0, 360))
	end
end
-- château sur la colline
place("Chateau", -10, -250, 0, 45)

-- joueur (silhouette) au milieu du chemin
local pj = place("PNJ_Base", 0, 4, 180)
if pj then
	pj.Name = "Joueur_Apercu"
end
root.Parent = workspace
return "maquette prête"
