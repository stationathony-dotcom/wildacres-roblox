--!strict
-- Construit les modèles du décor dans ServerStorage.Modeles.
-- En Édition, préférer les fonctions ciblées pour conserver les autres modèles retouchés.
-- Chaque modèle a une pièce invisible « Base » posée au sol (pivot = point au sol, façade vers +Z).
-- Une fois construits, les modèles se retouchent librement dans Studio : le jeu les clone tels quels.

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local M = {}

local Mat = Enum.Material
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local BOIS = rgb(122, 79, 46)
local BOIS_FONCE = rgb(78, 50, 34)
local BOIS_CLAIR = rgb(170, 125, 80)
local PIERRE = rgb(128, 125, 117)
local PIERRE_CLAIRE = rgb(169, 158, 139)
local CREPI = rgb(240, 224, 190)
local FER = rgb(70, 70, 76)
local OR = rgb(232, 186, 60)

local dossier: Folder

local function dossierModeles(): Folder
	local f = ServerStorage:FindFirstChild("Modeles")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Modeles"
		f.Parent = ServerStorage
	end
	return f :: Folder
end

local function nouveau(nom: string): Model
	local old = dossier:FindFirstChild(nom)
	if old then
		old:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = nom
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(1, 0.2, 1)
	base.CFrame = CFrame.new(0, 0, 0)
	base.Transparency = 1
	base.Anchored = true
	base.CanCollide = false
	base.CanQuery = false
	base.CanTouch = false
	base.Parent = m
	m.PrimaryPart = base
	return m
end

type Opts = {
	forme: string?, -- "Ball", "Cylinder", "Wedge"
	rot: CFrame?,
	collide: boolean?,
	transp: number?,
	cf: CFrame?, -- CFrame complet (remplace pos/rot)
}

local function P(m: Instance, nom: string, taille: Vector3, pos: Vector3, couleur: Color3, mat: Enum.Material?, o: Opts?): BasePart
	local opts: Opts = o or {}
	local p: BasePart
	if opts.forme == "Wedge" then
		p = Instance.new("WedgePart")
	else
		local part = Instance.new("Part")
		if opts.forme == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif opts.forme == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		p = part
	end
	p.Name = nom
	p.Size = taille
	p.CFrame = opts.cf or (CFrame.new(pos) * (opts.rot or CFrame.identity))
	p.Color = couleur
	p.Material = mat or Mat.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = opts.collide ~= false
	if opts.transp then
		p.Transparency = opts.transp
	end
	p.Parent = m
	return p
end

local function fini(m: Model)
	m.Parent = dossier
end

local function fumee(parent: BasePart, taille: number, opacite: number)
	local nuage = parent:FindFirstChildOfClass("Smoke") or Instance.new("Smoke")
	nuage.Size, nuage.Opacity, nuage.RiseVelocity = taille, opacite, 5.2
	nuage.Color = rgb(224, 215, 200)
	nuage.Parent = parent
end

local function reperesFeu(m: Model)
	local sortie = m:FindFirstChild(m.Name == "Forge" and "Sortie" or "Cheminee")
	if sortie and sortie:IsA("BasePart") then
		local forge = m.Name == "Forge"
		fumee(sortie, forge and 5.5 or 2.6, forge and 0.24 or 0.17)
	end
	local foyer = m:FindFirstChild("Braise")
	local lueur = foyer and foyer:FindFirstChildOfClass("PointLight")
	if lueur and lueur:IsA("PointLight") then
		lueur.Range = m.Name == "Forge" and 24 or 12
	end
end

function M.reperesDepart()
	local modeles = dossierModeles()
	for _, nom in { "Forge", "Fourneau" } do
		local modele = modeles:FindFirstChild(nom)
		if modele and modele:IsA("Model") then reperesFeu(modele) end
	end
end

local function feuillage(p: BasePart, caduc: boolean)
	CollectionService:AddTag(p, "Feuillage")
	p:SetAttribute("Caduc", caduc)
	p:SetAttribute("CouleurPrintemps", p.Color)
	p.CanCollide = false
end

local function attache(parent: BasePart, nom: string, cf: CFrame)
	local a = Instance.new("Attachment")
	a.Name = nom
	a.WorldCFrame = cf
	a.Parent = parent
	return a
end

-- ---------------------------------------------------------------- Arbres

local function arbres()
	-- 27/11, Claude (le propriétaire trouvait les arbres trop simples : 2-3 blocs) : tronc en gradins d'écorce,
	-- racines, branches qui portent les masses de feuillage, houppiers en plusieurs blocs à 3 tons qui se chevauchent.
	-- Noms gardés : « Tronc » (collision), « Feuillage » (tag, caduc), « Racine », « Branche ».
	local function tronc(m: Model, h: number, larg: number, c: Color3, cSombre: Color3)
		P(m, "Tronc", Vector3.new(larg, h, larg), Vector3.new(0, h / 2, 0), c, Mat.Wood)
		for i, y in { h * 0.25, h * 0.55, h * 0.8 } do
			P(m, "Ecorce", Vector3.new(larg + 0.12, 0.35, larg * 0.6), Vector3.new(0, y, (i % 2 == 0) and 0.2 or -0.2), cSombre, Mat.Wood,
				{ collide = false, rot = CFrame.Angles(0, i * 0.9, 0) })
		end
		for i = 0, 3 do
			local a = i * math.pi / 2 + 0.4
			P(m, "Racine", Vector3.new(larg * 0.55, 0.6, 1.4), Vector3.new(math.cos(a) * larg * 0.7, 0.3, math.sin(a) * larg * 0.7), cSombre, Mat.Wood,
				{ collide = false, rot = CFrame.Angles(0, -a, math.rad(-12)) })
		end
	end
	local function masse(m: Model, taille: Vector3, pos: Vector3, c: Color3, caduc: boolean, rot: number?)
		feuillage(P(m, "Feuillage", taille, pos, c, Mat.Grass, { rot = CFrame.Angles(0, rot or 0, 0) }), caduc)
	end
	-- Chêne : large, trapu, trois branches maîtresses
	do
		local m = nouveau("Arbre_Chene")
		tronc(m, 8, 1.8, BOIS, BOIS_FONCE)
		for i, b in { { 1, 0.3, -40 }, { -1, -0.4, 38 }, { 0.2, 1, -30 } } do
			P(m, "Branche", Vector3.new(0.8, 3.6, 0.8), Vector3.new(b[1] * 1.4, 7.4, b[2] * 1.2), BOIS, Mat.Wood,
				{ collide = false, rot = CFrame.Angles(math.rad(b[2] * 30), 0, math.rad(b[3])) })
		end
		local v1, v2, v3 = rgb(70, 132, 52), rgb(92, 156, 64), rgb(122, 182, 80)
		masse(m, Vector3.new(9, 3.6, 8.5), Vector3.new(0, 10, 0), v1, true)
		masse(m, Vector3.new(7.5, 2.8, 7), Vector3.new(0.3, 12.6, -0.2), v2, true, 0.3)
		masse(m, Vector3.new(4.6, 2.2, 4.4), Vector3.new(-0.4, 14.4, 0.4), v3, true, 0.7)
		masse(m, Vector3.new(4.2, 3.2, 4.2), Vector3.new(-4.3, 9.4, 1.2), v2, true, 0.2)
		masse(m, Vector3.new(4, 3, 4), Vector3.new(4.1, 9.2, 1.8), v1, true, -0.3)
		masse(m, Vector3.new(3.8, 2.8, 3.8), Vector3.new(1.2, 9.6, -4.4), v2, true, 0.5)
		masse(m, Vector3.new(2.4, 1.2, 2.4), Vector3.new(3, 11.6, 1.4), v3, true)
		masse(m, Vector3.new(2.2, 1.1, 2.2), Vector3.new(-3.4, 11.2, -1), v3, true)
		fini(m)
	end
	-- Sapin : étages en gradins, pointes qui retombent, cime claire
	do
		local m = nouveau("Arbre_Sapin")
		tronc(m, 5, 1.3, BOIS_FONCE, rgb(54, 38, 28))
		local v1, v2, v3 = rgb(36, 88, 56), rgb(48, 108, 66), rgb(70, 134, 82)
		local etages = { { 9, 4.4 }, { 7.4, 6.8 }, { 5.8, 9.2 }, { 4.2, 11.4 }, { 2.6, 13.4 } }
		for i, e in etages do
			masse(m, Vector3.new(e[1], 2.2, e[1]), Vector3.new(0, e[2], 0), i % 2 == 0 and v2 or v1, false, i * 0.4)
			masse(m, Vector3.new(e[1] * 0.75, 0.6, e[1] * 0.75), Vector3.new(0, e[2] + 1.3, 0), v3, false, i * 0.4 + 0.4)
			-- pointes de branches qui débordent sous l'étage
			for k = 0, 3 do
				local a = k * math.pi / 2 + i * 0.4
				masse(m, Vector3.new(1.1, 0.8, 1.6), Vector3.new(math.cos(a) * e[1] * 0.48, e[2] - 1.1, math.sin(a) * e[1] * 0.48), v1, false, -a)
			end
		end
		masse(m, Vector3.new(1, 1.6, 1), Vector3.new(0, 15.2, 0), v3, false)
		fini(m)
	end
	-- Bouleau : tronc blanc fin à lenticelles, houppier aéré et léger
	do
		local m = nouveau("Arbre_Bouleau")
		P(m, "Tronc", Vector3.new(1.2, 10, 1.2), Vector3.new(0, 5, 0), rgb(236, 232, 220), Mat.Wood)
		for i, y in { 1.6, 3.1, 4.6, 6.2, 7.6, 9 } do
			P(m, "Tache", Vector3.new(1.26, 0.22, 0.6), Vector3.new((i % 2 == 0) and 0.15 or -0.15, y, (i % 3 == 0) and 0.25 or -0.2), rgb(46, 44, 42), Mat.SmoothPlastic, { collide = false })
		end
		P(m, "Racine", Vector3.new(1.8, 0.6, 1.8), Vector3.new(0, 0.3, 0), rgb(200, 192, 176), Mat.Wood, { collide = false })
		P(m, "Branche", Vector3.new(0.4, 2.6, 0.4), Vector3.new(0.9, 9.4, 0), rgb(220, 214, 200), Mat.Wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(-35)) })
		P(m, "Branche", Vector3.new(0.4, 2.2, 0.4), Vector3.new(-0.8, 10.2, 0.4), rgb(220, 214, 200), Mat.Wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(35)) })
		local v1, v2, v3 = rgb(138, 182, 74), rgb(162, 200, 92), rgb(196, 220, 112)
		masse(m, Vector3.new(4.8, 5, 4.8), Vector3.new(0, 12.2, 0), v1, true)
		masse(m, Vector3.new(3.4, 3.4, 3.4), Vector3.new(0.4, 14.6, -0.3), v2, true, 0.5)
		masse(m, Vector3.new(3.2, 3.2, 3.2), Vector3.new(2.4, 10.8, 1), v2, true, 0.2)
		masse(m, Vector3.new(3, 3, 3), Vector3.new(-2.3, 11.6, -1.2), v2, true, -0.2)
		masse(m, Vector3.new(1.8, 1.6, 1.8), Vector3.new(1.6, 13.4, 1.6), v3, true)
		masse(m, Vector3.new(1.6, 1.4, 1.6), Vector3.new(-1.6, 14, 0.8), v3, true)
		fini(m)
	end
	-- Cerisier : tronc tors sombre, deux branches, nuage rose en couches, pétales clairs
	do
		local m = nouveau("Arbre_Cerisier")
		tronc(m, 6, 1.4, rgb(96, 62, 50), rgb(70, 44, 36))
		P(m, "Branche", Vector3.new(0.7, 3, 0.7), Vector3.new(1.3, 6.6, 0), rgb(96, 62, 50), Mat.Wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(-38)) })
		P(m, "Branche", Vector3.new(0.6, 2.6, 0.6), Vector3.new(-1.1, 6.8, 0.5), rgb(96, 62, 50), Mat.Wood, { collide = false, rot = CFrame.Angles(math.rad(10), 0, math.rad(36)) })
		local r1, r2, r3 = rgb(226, 140, 178), rgb(242, 170, 198), rgb(252, 210, 226)
		masse(m, Vector3.new(8, 3, 7), Vector3.new(0.4, 8.6, 0), r1, true)
		masse(m, Vector3.new(6.2, 2.4, 5.6), Vector3.new(-0.2, 10.6, 0.4), r2, true, 0.3)
		masse(m, Vector3.new(3.8, 1.6, 3.4), Vector3.new(0.2, 12.2, 0.2), r3, true, 0.6)
		masse(m, Vector3.new(3.4, 2.4, 3.4), Vector3.new(3.8, 8.2, 1.8), r2, true)
		masse(m, Vector3.new(3, 2.2, 3), Vector3.new(-3.6, 8.6, -1.4), r1, true)
		for i = 0, 4 do
			local a = i * 1.3
			masse(m, Vector3.new(0.7, 0.2, 0.7), Vector3.new(math.cos(a) * 3.4, 7.05, math.sin(a) * 3), r3, true, a)
		end
		fini(m)
	end
	-- Arbre mort
	do
		local m = nouveau("Arbre_Mort")
		local c = rgb(110, 96, 84)
		P(m, "Tronc", Vector3.new(1.4, 7, 1.4), Vector3.new(0, 3.5, 0), c, Mat.Wood)
		P(m, "Branche", Vector3.new(0.6, 3.6, 0.6), Vector3.new(1.3, 7, 0), c, Mat.Wood, { rot = CFrame.Angles(0, 0, math.rad(-40)) })
		P(m, "Branche", Vector3.new(0.5, 3, 0.5), Vector3.new(-1.1, 6, 0.4), c, Mat.Wood, { rot = CFrame.Angles(0, 0, math.rad(45)) })
		P(m, "Branche", Vector3.new(0.4, 2.4, 0.4), Vector3.new(0.2, 7.6, -1), c, Mat.Wood, { rot = CFrame.Angles(math.rad(-35), 0, 0) })
		fini(m)
	end
	-- Souche
	do
		local m = nouveau("Souche")
		P(m, "Tronc", Vector3.new(1.9, 1.2, 1.9), Vector3.new(0, 0.6, 0), BOIS, Mat.Wood)
		P(m, "Coupe", Vector3.new(1.6, 0.1, 1.6), Vector3.new(0, 1.25, 0), BOIS_CLAIR, Mat.Wood, { collide = false })
		fini(m)
	end
end

-- reconstruire seulement les arbres (27/11)
function M.arbres()
	dossier = dossierModeles()
	for _, n in { "Arbre_Chene", "Arbre_Sapin", "Arbre_Bouleau", "Arbre_Cerisier", "Arbre_Mort", "Souche" } do
		local old = dossier:FindFirstChild(n)
		if old then
			old:Destroy()
		end
	end
	arbres()
end

-- Biomes : cactus (désert), saule (marais)
function M.biomes()
	dossier = dossierModeles()
	for _, n in { "Cactus", "Arbre_Saule" } do
		local old = dossier:FindFirstChild(n)
		if old then
			old:Destroy()
		end
	end
	do
		local m = nouveau("Cactus")
		local v, v2 = rgb(70, 132, 74), rgb(92, 152, 88)
		P(m, "Tige", Vector3.new(1.6, 6, 1.6), Vector3.new(0, 3, 0), v, Mat.Grass)
		P(m, "Sommet", Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, 6, 0), v2, Mat.Grass, { forme = "Ball" })
		P(m, "BrasG", Vector3.new(1.8, 1, 1), Vector3.new(-1.5, 3, 0), v, Mat.Grass)
		P(m, "BrasG2", Vector3.new(1, 2.4, 1), Vector3.new(-2.2, 4.1, 0), v, Mat.Grass)
		P(m, "BrasD", Vector3.new(1.6, 1, 1), Vector3.new(1.4, 2.2, 0), v, Mat.Grass)
		P(m, "BrasD2", Vector3.new(1, 1.8, 1), Vector3.new(2, 3, 0), v2, Mat.Grass)
		P(m, "Fleur", Vector3.new(0.7, 0.4, 0.7), Vector3.new(0, 6.77, 0), rgb(240, 120, 160), Mat.SmoothPlastic, { collide = false })
		fini(m)
	end
	do
		-- 27/11, Claude : masses de feuillage en blocs (plus de sphères), rameaux tombants fins sur 2 tons, racines
		local m = nouveau("Arbre_Saule")
		local brun, brunF = rgb(128, 104, 78), rgb(92, 74, 56)
		P(m, "Tronc", Vector3.new(1.8, 8, 1.8), Vector3.new(0, 4, 0), brun, Mat.Wood)
		for i = 0, 3 do
			local a = i * math.pi / 2 + 0.3
			P(m, "Racine", Vector3.new(1, 0.6, 1.6), Vector3.new(math.cos(a) * 1.2, 0.48, math.sin(a) * 1.2), brunF, Mat.Wood,
				{ collide = false, rot = CFrame.Angles(0, -a, math.rad(-14)) })
		end
		P(m, "Branche", Vector3.new(0.8, 3.4, 0.8), Vector3.new(1.2, 8.4, 0), brun, Mat.Wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(-40)) })
		P(m, "Branche", Vector3.new(0.8, 3.4, 0.8), Vector3.new(-1.2, 8.2, 0.4), brun, Mat.Wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(40)) })
		local v1, v2, v3 = rgb(96, 146, 66), rgb(122, 168, 82), rgb(156, 194, 104)
		feuillage(P(m, "Feuillage", Vector3.new(9.5, 2.6, 9.5), Vector3.new(0, 10.2, 0), v1, Mat.Grass), false)
		feuillage(P(m, "Feuillage", Vector3.new(7, 2, 7), Vector3.new(0.4, 12, -0.3), v2, Mat.Grass, { rot = CFrame.Angles(0, 0.4, 0) }), false)
		feuillage(P(m, "Feuillage", Vector3.new(4, 1.4, 4), Vector3.new(-0.2, 13.4, 0.2), v3, Mat.Grass, { rot = CFrame.Angles(0, 0.8, 0) }), false)
		-- rameaux qui retombent (fins, deux tons, longueurs variées)
		for i = 0, 15 do
			local a = i * math.pi * 2 / 16
			local r = 3.9 + (i % 3) * 0.35
			local len = 4.6 + (i % 4) * 0.9
			local x, z = math.cos(a) * r, math.sin(a) * r
			feuillage(P(m, "Feuillage", Vector3.new(0.6, len, 0.6), Vector3.new(x, 9.2 - len / 2, z), (i % 2 == 0) and v2 or v1, Mat.Grass), false)
		end
		fini(m)
	end
end

local function filon(nom: string, couleur: Color3, mat: Enum.Material)
	local m = nouveau(nom)
	P(m, "Pierre", Vector3.new(4, 3, 3.4), Vector3.new(0, 1.3, 0), PIERRE, Mat.Slate, { rot = CFrame.Angles(0, math.rad(12), math.rad(6)) })
	P(m, "Pierre", Vector3.new(2.6, 2.2, 2.6), Vector3.new(1.6, 1.2, 1.2), rgb(110, 108, 112), Mat.Slate, { rot = CFrame.Angles(math.rad(8), math.rad(35), 0) })
	local pts = { { 0.8, 2.6, 1.2 }, { -1.2, 1.8, 1.5 }, { 1.9, 1.6, 2.3 }, { -0.4, 0.9, 1.75 }, { 1.2, 2.3, -1.1 }, { -1.6, 2.2, -0.6 } }
	for i, q in pts do
		P(m, "Pepite", Vector3.new(1.1, 0.9, 1), Vector3.new(q[1], q[2], q[3]), couleur, mat, { rot = CFrame.Angles(i, i * 0.7, 0), collide = false })
	end
	fini(m)
end

function M.filonOr()
	dossier = dossierModeles()
	filon("Filon_Or", rgb(226, 179, 67), Mat.Metal)
end

-- Artisanat : filons de minerai, argile, four, pièces de construction (grille de 4 studs), lit, lanterne
-- ---------------------------------------------------------------- Props de Valdor

local Vp = Vector3.new
local VERTICALE = CFrame.Angles(0, 0, math.pi / 2)
local FACE_PROP = CFrame.Angles(0, math.pi / 2, 0)
local PASSE = math.pi * 2
local CHAUME = rgb(200, 158, 74)
local LIN = rgb(223, 211, 179)
local GARANCE = rgb(151, 58, 47)
local EAU_PROP = rgb(66, 114, 131)
local CALCAIRE = rgb(181, 173, 157)

local function teinteProp(c: Color3, i: number): Color3
	return c:Lerp(i % 2 == 0 and BOIS_FONCE or BOIS_CLAIR, (i % 3) * 0.10)
end

local function lienProp(m: Model, nom: string, a: Vector3, b: Vector3, w: number, h: number,
	c: Color3, mat: Enum.Material, collide: boolean?)
	local delta = b - a
	local up = math.abs(delta.Unit.Y) > 0.98 and Vp(0, 0, 1) or Vp(0, 1, 0)
	P(m, nom, Vp(w, h, delta.Magnitude + 0.035), Vector3.zero, c, mat,
		{ cf = CFrame.lookAt((a + b) / 2, b, up), collide = collide })
end

local function cylProp(m: Model, nom: string, diam: number, ep: number, pos: Vector3, c: Color3,
	mat: Enum.Material, rot: CFrame?, collide: boolean?): BasePart
	return P(m, nom, Vp(ep, diam, diam), pos, c, mat, { forme = "Cylinder", rot = rot or VERTICALE, collide = collide })
end

local function rivetProp(m: Model, pos: Vector3, d: number, c: Color3?)
	P(m, "Rivet", Vp(d, d, d), pos, c or FER, Mat.Metal, { forme = "Ball", collide = false })
end

local function lamesProp(m: Model, nom: string, taille: Vector3, pos: Vector3, n: number, axe: string, c: Color3)
	local largeur = (axe == "X" and taille.X or axe == "Y" and taille.Y or taille.Z) / n
	for i = 1, n do
		local d, ep = (i - (n + 1) / 2) * largeur, largeur - 0.02
		local dims = axe == "X" and Vp(ep, taille.Y, taille.Z)
			or axe == "Y" and Vp(taille.X, ep, taille.Z) or Vp(taille.X, taille.Y, ep)
		local decalage = axe == "X" and Vp(d, 0, 0) or axe == "Y" and Vp(0, d, 0) or Vp(0, 0, d)
		P(m, nom, dims, pos + decalage, teinteProp(c, i), Mat.WoodPlanks)
	end
end

local function cercleProp(m: Model, nom: string, centre: Vector3, r: number, n: number, ep: number,
	c: Color3, mat: Enum.Material, vertical: boolean?)
	for i = 0, n - 1 do
		local a, b = i * PASSE / n, (i + 1) * PASSE / n
		local function point(angle: number): Vector3
			local u, v = math.cos(angle) * r, math.sin(angle) * r
			return centre + (vertical and Vp(u, v, 0) or Vp(u, 0, v))
		end
		lienProp(m, nom, point(a), point(b), ep, ep, c, mat, false)
	end
end

local function pierreRonde(m: Model, nom: string, centre: Vector3, r: number, n: number, h: number,
	ep: number, phase: number, claire: boolean?)
	for i = 0, n - 1 do
		local a = i * PASSE / n + phase
		local w = 2 * (r + ep * 0.25) * math.tan(math.pi / n)
		P(m, nom, Vp(w, h - i % 3 * 0.025, ep),
			centre + Vp(math.sin(a) * r, i % 3 * 0.0125, math.cos(a) * r),
			(claire and CALCAIRE or PIERRE):Lerp(PIERRE_CLAIRE, i % 3 * 0.20),
			i % 2 == 0 and Mat.Slate or Mat.Cobblestone, { rot = CFrame.Angles(0, a, 0) })
	end
end

local function toitureProp(m: Model, w: number, d: number, y: number, montee: number, z: number, chaume: boolean)
	local demi = d / 2 - 0.1
	local pente = math.atan(montee / demi)
	local longueur = math.sqrt(demi ^ 2 + montee ^ 2)
	for _, s in { -1, 1 } do
		for i = 1, 4 do
			local t = (i - 0.5) / 4
			local couleur = chaume and CHAUME or rgb(133, 79, 56)
			P(m, chaume and "Chaume" or "Bardeaux", Vp(w, chaume and 0.33 or 0.21, longueur / 4 + 0.08),
				Vp(0, y + montee * (1 - t), z + s * demi * t), teinteProp(couleur, i),
				chaume and Mat.Grass or Mat.WoodPlanks, { rot = CFrame.Angles(s * pente, 0, 0) })
		end
	end
	P(m, "Faîtage", Vp(w, 0.19, 0.26), Vp(0, y + montee - 0.02, z), BOIS_FONCE, Mat.Wood)
end

local function lumiereProp(m: Model, nom: string, pos: Vector3, taille: Vector3, portee: number, intensite: number,
	nuit: boolean?): BasePart
	local f = P(m, nom, taille, pos, rgb(255, 177, 72), Mat.Neon, { forme = "Ball", collide = false })
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color = portee, intensite, rgb(255, 194, 117)
	l.Shadows = true
	l.Parent = f
	if nuit then CollectionService:AddTag(f, "LumiereNuit") end
	return f
end

-- Le relief décoratif laisse le volume porteur et les rayons d'interaction libres.
local function reliefProp(m: Model, nom: string, taille: Vector3, pos: Vector3, c: Color3,
	mat: Enum.Material, rx: number?, ry: number?, rz: number?, forme: string?)
	local p = P(m, nom, taille, pos, c, mat,
		{ collide = false, rot = CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0)), forme = forme })
	p.CanTouch = false
	p.CanQuery = false
	return p
end

local LAITON = rgb(177, 111, 39)
local OR_PALE = rgb(250, 203, 105)
local FER_CLAIR = rgb(114, 122, 130)
local FER_SOMBRE = rgb(41, 42, 49)
local MOUSSE = rgb(84, 107, 57)
local MOUSSE_CLAIRE = rgb(123, 147, 77)
local MOUSSE_SOMBRE = rgb(53, 70, 41)

local function detailProp(m: Model, nom: string, taille: Vector3, pos: Vector3, couleur: Color3,
	mat: Enum.Material, angles: Vector3?, forme: string?): BasePart
	local rot = angles and CFrame.Angles(math.rad(angles.X), math.rad(angles.Y), math.rad(angles.Z))
	local p = P(m, nom, taille, pos, couleur, mat, { rot = rot, forme = forme, collide = false })
	p.CanQuery = false
	p.CanTouch = false
	return p
end

local function lanterneProp(m: Model, nom: string, position: Vector3, echelle: number, range: number, luminosite: number)
	local function p(x: number, y: number, z: number): Vector3
		return position + Vp(x, y, z) * echelle
	end
	P(m, "Fond", Vp(0.92, 0.14, 0.92) * echelle, p(0, -0.54, 0), FER, Mat.Metal, { collide = false })
	P(m, "Chapeau", Vp(0.97, 0.18, 0.97) * echelle, p(0, 0.55, 0), FER, Mat.Metal, { collide = false })
	P(m, "Couronnement", Vp(0.58, 0.13, 0.58) * echelle, p(0, 0.69, 0), FER, Mat.Metal, { collide = false })
	P(m, "Verre", Vp(0.72, 1.05, 0.72) * echelle, position, rgb(231, 166, 92), Mat.Glass,
		{ collide = false, transp = 0.36 })
	for _, x in { -0.375, 0.375 } do
		for _, z in { -0.375, 0.375 } do
			P(m, "Montant", Vp(0.083, 1.11, 0.083) * echelle, p(x, 0, z), FER, Mat.Metal, { collide = false })
		end
	end
	reliefProp(m, "Liseré de cuivre", Vp(0.92, 0.09, 0.91) * echelle, p(0, 0.47, 0), LAITON, Mat.Metal)
	reliefProp(m, "Pointe du capot", Vp(0.38, 0.24, 0.34) * echelle, p(0.022, 0.80, 0), FER_CLAIR, Mat.Metal, 4, -4)
	reliefProp(m, "Bord du fond poli", Vp(0.81, 0.09, 0.81) * echelle, p(0, -0.47, 0), LAITON, Mat.Metal)
	for _, z in { -0.382, 0.382 } do
		reliefProp(m, "Traverse de cage", Vp(0.75, 0.075, 0.055) * echelle, p(0, -0.13, z), FER, Mat.Metal)
		reliefProp(m, "Goutte de patine", Vp(0.24, 0.12, 0.041) * echelle, p(z * 0.37, 0.53, z * 1.25),
			rgb(92, 121, 106), Mat.Metal, 0, 0, z * 15)
	end
	return lumiereProp(m, nom, p(0, -0.18, 0), Vp(0.26, 0.55, 0.26) * echelle, range, luminosite, true)
end

local PROPS_VALDOR: { [string]: () -> () } = {}

function PROPS_VALDOR.Lampadaire()
	local m = nouveau("Lampadaire")
	P(m, "Pied", Vp(2.18, 0.36, 2.17), Vp(0, 0.18, 0), PIERRE, Mat.Cobblestone)
	for i = 1, 4 do
		local x, z = i % 2 == 0 and -0.54 or 0.54, i < 3 and -0.52 or 0.52
		P(m, "Moellon", Vp(1.09, 0.45, 1.04), Vp(x, 0.55, z), i % 2 == 0 and PIERRE or CALCAIRE, Mat.Slate)
	end
	P(m, "Chaperon", Vp(2.01, 0.24, 2.04), Vp(0, 0.88, 0), CALCAIRE, Mat.Slate)
	P(m, "Poteau", Vp(0.98, 10.98, 0.99), Vp(0, 6.38, 0), BOIS, Mat.Wood)
	P(m, "Cap", Vp(1.27, 0.27, 1.26), Vp(0, 11.72, 0), BOIS_FONCE, Mat.Wood)
	P(m, "Bras", Vp(0.8, 0.74, 4.38), Vp(0, 10.98, 1.9), BOIS, Mat.Wood)
	lienProp(m, "JambeDeForce", Vp(0, 8.92, 0.38), Vp(0, 10.76, 2.59), 0.48, 0.52, BOIS_FONCE, Mat.Wood)
	for _, y in { 9.11, 10.98 } do
		P(m, "Ferrure", Vp(1.05, 0.29, 1.02), Vp(0, y, 0.06), FER, Mat.Metal, { collide = false })
		for _, x in { -0.52, 0.52 } do rivetProp(m, Vp(x, y, 0.52), 0.15) end
	end
	for i = 0, 2 do
		cercleProp(m, "Chaine", Vp(0, 10.49 - i * 0.30, 3.60), 0.215, 6, 0.11, FER, Mat.Metal, true)
	end
	lanterneProp(m, "Lanterne", Vp(0, 8.5, 3.60), 1.54, 28, 1.7)
	for i, x in { -0.72, -0.24, 0.27, 0.56 } do
		reliefProp(m, "Croûte de mousse sur le socle", Vp(0.44, 0.14 + i * 0.021, 0.31),
			Vp(x, 0.79 - i * 0.08, 0.93), i % 2 == 0 and MOUSSE or MOUSSE_CLAIRE, Mat.Grass, -5, 0, i * 3 - 8)
	end
	reliefProp(m, "Face claire du fût", Vp(0.71, 5.66, 0.105), Vp(0.04, 5.24, 0.46), BOIS_CLAIR, Mat.Wood, 0, 0, 2)
	reliefProp(m, "Veine arrachée", Vp(0.17, 1.17, 0.075), Vp(0.29, 5.09, 0.52), BOIS_FONCE, Mat.Wood, 0, 0, -5)
	reliefProp(m, "Couronnement du mât", Vp(1.12, 0.25, 1.1), Vp(0, 11.92, 0), FER, Mat.Metal, 3)
	reliefProp(m, "Chant de la potence", Vp(0.09, 0.16, 3.79), Vp(-0.39, 11.24, 2.03), BOIS_CLAIR, Mat.Wood, 3)
	reliefProp(m, "Étrier de suspension", Vp(0.54, 0.26, 0.38), Vp(0, 10.64, 3.59), FER_CLAIR, Mat.Metal, 5)
	fini(m)
end

function PROPS_VALDOR.Lanterne()
	local m = nouveau("Lanterne")
	P(m, "Semelle", Vp(0.62, 0.26, 0.59), Vp(0, 0.13, 0), PIERRE, Mat.Slate)
	P(m, "Poteau", Vp(0.34, 4.76, 0.33), Vp(0, 2.62, 0), BOIS, Mat.Wood)
	P(m, "Potence", Vp(0.32, 0.24, 1.38), Vp(0, 4.87, 0.54), BOIS_FONCE, Mat.Wood)
	lienProp(m, "Jambe de force", Vp(0, 4.16, 0.08), Vp(0, 4.82, 0.86), 0.14, 0.15, BOIS, Mat.Wood, false)
	cercleProp(m, "Bélière", Vp(0, 4.61, 1.1), 0.17, 6, 0.075, FER, Mat.Metal, true)
	local l = lanterneProp(m, "Flamme", Vp(0, 4.05, 1.1), 0.85, 22, 1.6)
	local light = l:FindFirstChildOfClass("PointLight")
	if light then light.Enabled = false end
	reliefProp(m, "Sabot du potelet", Vp(0.49, 0.38, 0.47), Vp(0, 0.42, 0), FER, Mat.Metal, 0, 3)
	reliefProp(m, "Plaque de bois fendu", Vp(0.28, 1.35, 0.089), Vp(-0.02, 2.97, 0.15), BOIS_CLAIR, Mat.Wood, 0, 0, -4)
	reliefProp(m, "Mousse au pied", Vp(0.26, 0.11, 0.21), Vp(0.13, 0.24, 0.19), MOUSSE, Mat.Grass, 0, 6, -5)
	detailProp(m, "Biseau du montant", Vp(0.14, 2.70, 0.064), Vp(-0.072, 2.12, 0.156), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -2))
	detailProp(m, "Éclat au pied", Vp(0.09, 0.60, 0.072), Vp(0.037, 0.50, 0.17), BOIS_FONCE, Mat.Wood, Vp(0, 0, 5), "Wedge")
	detailProp(m, "Crochet relevé de la potence", Vp(0.23, 0.23, 0.26), Vp(0.004, 4.99, 0.96), rgb(146,108,67), Mat.Metal, Vp(-5, 0, 5))
	detailProp(m, "Sabot oxydé du montant", Vp(0.39, 0.28, 0.38), Vp(0, 0.37, 0), rgb(101,84,62), Mat.Metal, Vp(0, 6, 0))
	fini(m)
end

function PROPS_VALDOR.Puits()
	local m = nouveau("Puits")
	cylProp(m, "Fondation", 4.62, 1.48, Vp(0, -0.36, 0), PIERRE, Mat.Cobblestone)
	pierreRonde(m, "Assise", Vp(0, 0.63, 0), 1.98, 12, 0.59, 0.62, 0)
	pierreRonde(m, "Margelle", Vp(0, 1.15, 0), 1.99, 12, 0.49, 0.72, math.pi / 12, true)
	local eau = cylProp(m, "Eau", 3.7, 0.08, Vp(0, 0.83, 0), EAU_PROP, Mat.Glass, nil, false)
	eau.Transparency = 0.22
	for _, x in { -2.04, 2.04 } do
		P(m, "Poteau", Vp(0.49, 6.18, 0.5), Vp(x, 3.52, 0), BOIS, Mat.Wood)
		P(m, "Sabot", Vp(0.6, 0.32, 0.61), Vp(x, 1.36, 0), FER, Mat.Metal, { collide = false })
		P(m, "Poinçon", Vp(0.34, 1.18, 0.34), Vp(x, 7.08, 0), BOIS_FONCE, Mat.Wood)
		for _, z in { -1.03, 1.03 } do
			lienProp(m, "Chevron", Vp(x, 6.22, z * 2.29), Vp(x, 7.62, 0), 0.24, 0.23, BOIS_FONCE, Mat.Wood)
		end
	end
	P(m, "Entrait", Vp(4.62, 0.24, 0.26), Vp(0, 6.49, 0), BOIS_FONCE, Mat.Wood)
	toitureProp(m, 5.58, 5.01, 6.2, 1.38, 0, true)
	cylProp(m, "Treuil", 0.46, 4.17, Vp(0, 5, 0), BOIS_FONCE, Mat.Wood, CFrame.identity)
	cylProp(m, "Bobine", 0.66, 0.68, Vp(0, 5, 0), LIN, Mat.Fabric, CFrame.identity, false)
	lienProp(m, "Manivelle", Vp(2.22, 5, 0), Vp(2.27, 4.61, 0.28), 0.14, 0.13, FER, Mat.Metal, false)
	cylProp(m, "Poignée", 0.17, 0.37, Vp(2.31, 4.61, 0.28), BOIS, Mat.Wood, CFrame.identity, false)
	cylProp(m, "Seau", 0.8, 0.61, Vp(0, 3.63, 0), BOIS_CLAIR, Mat.WoodPlanks, nil, false)
	for _, y in { 3.42, 3.86 } do cylProp(m, "Cercle", 0.84, 0.08, Vp(0, y, 0), FER, Mat.Metal, nil, false) end
	P(m, "Corde", Vp(0.08, 1.03, 0.08), Vp(0, 4.27, 0.27), LIN, Mat.Fabric, { collide = false })
	lienProp(m, "Anse", Vp(0, 3.83, -0.32), Vp(0, 4.01, 0.27), 0.071, 0.073, FER, Mat.Metal, false)
	-- Un seul versant usé évoque le ruissellement. La margelle garde son diamètre.
	for i, x in { -2.11, -1.62, -0.95, -0.30, 0.49, 1.21, 1.83 } do
		reliefProp(m, "Corniche de paille relevée", Vp(0.78 + i % 3 * 0.07, 0.21, 0.65),
			Vp(x, 6.48 + i % 3 * 0.05, 1.96 - i % 2 * 0.09), i % 3 == 0 and BOIS or OR_PALE, Mat.Grass, 29, 0, i % 3 * 5 - 5)
		reliefProp(m, "Chaume effiloché de l’égout", Vp(0.37 + i % 3 * 0.06, 0.14, 0.27),
			Vp(x + i % 2 * 0.077, 6.20 + i % 3 * 0.025, 2.32), i % 2 == 0 and CHAUME or BOIS, Mat.Grass, 28, 0, i % 3 * 4 - 4)
	end
	for i, a in { -0.61, -0.30, 0.06, 0.33, 0.58 } do
		reliefProp(m, "Dalle de margelle humide", Vp(0.79, 0.13, 0.44),
			Vp(math.sin(a) * 2.05, 1.342 - i % 3 * 0.05, math.cos(a) * 2.05),
			i % 3 == 0 and MOUSSE_SOMBRE or i % 2 == 0 and MOUSSE_CLAIRE or MOUSSE,
			Mat.Grass, -6, math.deg(a), i * 2 - 6)
	end
	for _, x in { -2.04, 2.04 } do
		reliefProp(m, "Coussinet du treuil", Vp(0.51, 0.44, 0.52), Vp(x, 5, 0), FER, Mat.Metal)
		lienProp(m, "Console du treuil", Vp(x, 4.62, 0.23), Vp(x * 0.73, 5.18, 0.2),
			0.19, 0.20, BOIS_CLAIR, Mat.Wood, false)
	end
	cylProp(m, "Creux du seau", 0.63, 0.035, Vp(0, 3.945, 0), BOIS_FONCE, Mat.Wood, nil, false)

	for i, x in { -1.88, -1.07, -0.19, 0.69, 1.54 } do
		local z = math.sqrt(2.08 ^ 2 - x ^ 2)
		detailProp(m, "Mousse sur la margelle", Vp(0.73 + i % 2 * 0.17, 0.12, 0.43), Vp(x, 1.395, z),
			rgb(89 + i * 7, 113 + i * 4, 62), Mat.Grass, Vp(3, math.deg(math.asin(x / 2.08)), i - 4))
		if i ~= 4 then
			detailProp(m, "Pointe de mousse", Vp(0.32, 0.32 + i * 0.044, 0.16), Vp(x + 0.075, 1.25, z + 0.16),
				rgb(67, 96 + i * 5, 64), Mat.Grass, Vp(4, math.deg(math.asin(x / 2.08)), i * 3 - 8), "Wedge")
		end
	end
	for i, x in { -2.08, -1.37, -0.48, 0.39, 1.28, 2.13 } do
		local z = 2.39 - i % 3 * 0.055
		detailProp(m, "Paille rompue à l’égout", Vp(0.67, 0.27, 0.55), Vp(x, 6.29 - i % 2 * 0.071, z),
			({ CHAUME, rgb(177, 131, 63), rgb(220, 182, 100) })[i % 3 + 1], Mat.Grass, Vp(27 + i % 3 * 3, i - 4, 4), "Wedge")
	end
	for _, x in { -2.04, 2.04 } do
		lienProp(m, "Jambe de force de l’auvent", Vp(x, 5.21, 0.16), Vp(x * 0.67, 6.43, 0.20), 0.23, 0.23, BOIS_CLAIR, Mat.Wood, false)
		detailProp(m, "Épaulement d’about", Vp(0.36, 0.49, 0.15), Vp(x, 5.21, 0.25), FER, Mat.Metal, Vp(0, 0, x * 3))
		detailProp(m, "Biseau du fût mouillé", Vp(0.17, 1.14, 0.13), Vp(x - 0.13, 1.99, 0.24), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -4))
	end
	detailProp(m, "Écho du reflet sous le seau", Vp(1.32, 0.026, 0.17), Vp(-0.41, 0.887, 0.50), rgb(134,185,191), Mat.Glass, Vp(0, 13, 0))
	detailProp(m, "Reflet brisé en rive", Vp(0.77, 0.022, 0.13), Vp(0.72, 0.885, 0.72), rgb(107,161,167), Mat.Glass, Vp(0, -18, 0))
	fini(m)
end

function PROPS_VALDOR.Fontaine()
	local m = nouveau("Fontaine")
	cylProp(m, "Bassin", 7.58, 0.32, Vp(0, 0.16, 0), PIERRE, Mat.Cobblestone)
	pierreRonde(m, "Assise", Vp(0, 0.57, 0), 3.53, 12, 0.56, 0.7, 0)
	pierreRonde(m, "Margelle", Vp(0, 1.10, 0), 3.54, 12, 0.5, 0.86, math.pi / 12, true)
	cylProp(m, "Eau", 6.69, 0.12, Vp(0, 0.94, 0), EAU_PROP, Mat.Glass, nil, false).Transparency = 0.24
	cylProp(m, "Socle", 2.03, 1.18, Vp(0, 0.63, 0), CALCAIRE, Mat.Cobblestone)
	cylProp(m, "Colonne", 1.37, 3.42, Vp(0, 2.8, 0), PIERRE, Mat.Slate)
	for _, y in { 1.28, 3.81, 4.42 } do
		cylProp(m, "Bague", y == 4.42 and 1.96 or 1.62, 0.20, Vp(0, y, 0), CALCAIRE, Mat.Slate)
	end
	cylProp(m, "Vasque", 2.48, 0.48, Vp(0, 4.7, 0), PIERRE_CLAIRE, Mat.Slate)
	cylProp(m, "Vasque", 3.19, 0.36, Vp(0, 5.02, 0), CALCAIRE, Mat.Slate)
	pierreRonde(m, "Bord de vasque", Vp(0, 5.30, 0), 1.51, 10, 0.26, 0.24, 0, true)
	cylProp(m, "EauHaut", 2.83, 0.09, Vp(0, 5.26, 0), EAU_PROP, Mat.Glass, nil, false).Transparency = 0.24
	cylProp(m, "Bec", 0.48, 0.46, Vp(0, 5.44, 0), CALCAIRE, Mat.Slate)
	local jet = P(m, "Jet", Vp(0.30, 0.12, 0.30), Vp(0, 5.72, 0), EAU_PROP, Mat.Glass,
		{ collide = false, transp = 0.32 })
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(rgb(199, 220, 225))
	pe.Size = NumberSequence.new(0.28, 0.09)
	pe.Transparency = NumberSequence.new(0.25, 0.86)
	pe.Speed, pe.Lifetime, pe.Rate = NumberRange.new(5, 7), NumberRange.new(0.5, 0.7), 35
	pe.SpreadAngle, pe.Acceleration = Vector2.new(17, 17), Vp(0, -24, 0)
	pe.Parent = jet
	local eauClaire = rgb(151, 212, 216)
	for i, a in { -1.38, -0.97, -0.52, -0.14, 0.25, 0.62, 1.17, 2.17, 2.62, 3.36 } do
		local x, z = math.sin(a), math.cos(a)
		reliefProp(m, "Calcaire blanchi par l’eau", Vp(0.97 + i % 3 * 0.14, 0.21, 0.17),
			Vp(x * 3.90, 1.19 - i % 3 * 0.06, z * 3.90),
			i % 3 == 0 and MOUSSE_SOMBRE or i % 2 == 0 and PIERRE_CLAIRE or rgb(201, 190, 167), Mat.Slate,
			-4, math.deg(a), i % 3 * 5 - 5)
		reliefProp(m, "Ride brisée du bassin", Vp(0.92 + i % 3 * 0.19, 0.028, 0.13),
			Vp(x * (2.75 + i % 3 * 0.13), 1.014, z * (2.75 + i % 3 * 0.13)),
			i % 2 == 0 and eauClaire or rgb(106, 167, 177), Mat.Glass, 0, math.deg(a), 0, "Ball")
	end
	for i, a in { -1.67, -0.85, -0.09, 0.78, 1.59, 2.37, 3.10 } do
		local x, z = math.sin(a), math.cos(a)
		reliefProp(m, "Nervure de la colonne", Vp(0.24, 2.21 + i % 3 * 0.18, 0.12), Vp(x * 0.68, 2.54, z * 0.68),
			i % 2 == 0 and CALCAIRE or FER_CLAIR, Mat.Slate, -3, math.deg(a), i % 3 * 4 - 4)
	end
	reliefProp(m, "Bouche de cuivre verdie", Vp(0.36, 0.28, 0.26), Vp(0, 5.54, 0.19), rgb(97, 130, 106), Mat.Metal, 7)

	for i, position in { Vp(-1.52, 1.352, 3.15), Vp(-0.85, 1.36, 3.46), Vp(-0.16, 1.35, 3.57),
		Vp(0.61, 1.354, 3.50), Vp(1.22, 1.35, 3.26) } do
		detailProp(m, "Manteau de mousse humide", Vp(0.78, 0.095, 0.46), position,
			rgb(101 + i * 5, 125 + i * 2, 78), Mat.Grass, Vp(3, math.deg(math.atan2(position.X, position.Z)), i - 4))
		detailProp(m, "Lamelle de mousse sur joint", Vp(0.29, 0.27 + i % 3 * 0.067, 0.13), position + Vp(0.12, -0.13, 0.29),
			rgb(73, 106 + i * 3, 79), Mat.Grass, Vp(4, 0, 6 - i * 3), "Wedge")
	end
	for i, a in { 0.10, 1.65, 3.28, 4.82 } do
		local dir = Vp(math.sin(a), 0, math.cos(a))
		local col = rgb(137 + i * 12, 187 + i * 6, 190 + i * 7)
		local impact = dir * (1.71 + i * 0.043)
		lienProp(m, "Filet tombant de la vasque", dir * 1.60 + Vp(0, 5.32, 0), impact + Vp(0, 1.02, 0),
			0.095 + i * 0.023, 0.11, col, Mat.Glass, false)
		detailProp(m, "Éclaboussure au bassin", Vp(0.56, 0.066, 0.37), impact + Vp(0, 1.026, 0), col, Mat.Glass, Vp(0, 17 * i, 0), "Ball")
		detailProp(m, "Écume en retrait du jet", Vp(0.33 + i * 0.033, 0.046, 0.13), impact + dir * 0.19 + Vp(0, 1.047, 0),
			eauClaire, Mat.Glass, Vp(0, math.deg(a) - 4, 0), "Ball")
	end
	detailProp(m, "Ressaut de chapiteau chanfrené", Vp(1.50, 0.30, 1.50), Vp(0, 4.05, 0), PIERRE_CLAIRE, Mat.Slate, Vp(0, 13, 0))
	detailProp(m, "Pointe lapidaire", Vp(0.34, 0.34, 0.14), Vp(0, 2.79, 0.682), CALCAIRE, Mat.Slate, Vp(0, 0, 45))
	detailProp(m, "Filet de calcaire", Vp(0.13, 1.25, 0.07), Vp(0.24, 2.50, 0.64), rgb(205,194,166), Mat.Slate, Vp(0, 0, -5))
	fini(m)
end

function PROPS_VALDOR.Panneau()
	local m = nouveau("Panneau")
	for _, x in { -2.40, 2.4 } do
		P(m, "Sabot", Vp(0.55, 0.23, 0.56), Vp(x, 0.115, 0), PIERRE, Mat.Slate)
		P(m, "Poteau", Vp(0.39, 4.65, 0.4), Vp(x, 2.55, 0), BOIS, Mat.Wood)
		P(m, "Tête taillée", Vp(0.46, 0.25, 0.43), Vp(x, 4.87, 0), BOIS_FONCE, Mat.Wood, { forme = "Wedge" })
		for _, y in { 3.22, 4.55 } do rivetProp(m, Vp(x, y, 0.216), 0.14) end
	end
	lamesProp(m, "Bardage", Vp(5.76, 1.71, 0.27), Vp(0, 3.9, 0), 4, "Y", BOIS_CLAIR)
	local planche = P(m, "Planche", Vp(5.24, 1.24, 0.34), Vp(0, 3.9, 0), rgb(186, 142, 93), Mat.WoodPlanks)
	for _, y in { 3.1, 4.71 } do
		P(m, "Traverse", Vp(5.8, 0.17, 0.38), Vp(0, y, 0), BOIS_FONCE, Mat.Wood)
	end
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local sg = Instance.new("SurfaceGui")
		sg.Name, sg.Face, sg.PixelsPerStud = "Texte", face, 40
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		local t = Instance.new("TextLabel")
		t.Name, t.Size, t.Position = "Nom", UDim2.fromScale(0.94, 0.86), UDim2.fromScale(0.03, 0.07)
		t.BackgroundTransparency, t.Text, t.TextScaled = 1, "Village", true
		t.Font, t.TextColor3 = Enum.Font.Fondamento, rgb(65, 38, 24)
		t.Parent, sg.Parent = sg, planche
	end
	for _, x in { -2.47, 2.47 } do
		for _, z in { -0.185, 0.185 } do
			reliefProp(m, "Éclisse de cadre", Vp(0.39, 1.53, 0.083), Vp(x, 3.91, z), BOIS_FONCE, Mat.Wood, 0, 0, x * 2)
			reliefProp(m, "Coin biseauté du cadre", Vp(0.48, 0.27, 0.11), Vp(x, 4.58, z), LAITON, Mat.Metal, 0, 0, x * 2)
		end
	end
	for i, profil in { { -1.57, 3.20, 1.18 }, { 0.09, 3.19, 1.32 }, { 1.54, 3.17, 0.85 } } do
		reliefProp(m, "Bord écaillé du panneau", Vp(profil[3], 0.089, 0.09), Vp(profil[1], profil[2], 0.17),
			i == 2 and LIN or BOIS_CLAIR, Mat.Wood, 0, 0, i * 4 - 8)
	end
	reliefProp(m, "Frise haute du panneau", Vp(4.31, 0.105, 0.11), Vp(0.04, 4.67, 0.153), BOIS_CLAIR, Mat.Wood, 0, 0, 2)
	detailProp(m, "Traverse à chant miel", Vp(5.30, 0.11, 0.12), Vp(-0.03, 4.75, 0.167), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 1))
	detailProp(m, "Éclat de traverse", Vp(0.64, 0.09, 0.13), Vp(1.45, 4.74, 0.198), BOIS, Mat.Wood, Vp(0, 2, 4), "Wedge")
	detailProp(m, "Longeron d’enseigne", Vp(4.68, 0.12, 0.15), Vp(-0.04, 3.12, 0.18), BOIS, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Jambe de force gauche", Vp(0.19, 0.78, 0.17), Vp(-2.15, 2.83, 0.09), BOIS_CLAIR, Mat.Wood, Vp(3, 0, -38))
	detailProp(m, "Jambe de force droite", Vp(0.19, 0.77, 0.17), Vp(2.14, 2.79, -0.075), BOIS, Mat.Wood, Vp(-4, 0, 37))
	detailProp(m, "Fer d’angle", Vp(0.36, 0.34, 0.10), Vp(-2.48, 4.56, 0.205), FER, Mat.Metal, Vp(0, 0, -5))
	detailProp(m, "Arête du fer d’angle", Vp(0.16, 0.17, 0.066), Vp(-2.52, 4.62, 0.248), rgb(118,132,128), Mat.Metal, Vp(0, 0, -5))
	detailProp(m, "Coin supérieur doré", Vp(0.29, 0.28, 0.11), Vp(2.44, 4.56, 0.21), rgb(161,120,62), Mat.Metal, Vp(0, 0, 6))
	fini(m)
end

function PROPS_VALDOR.Tonneaux()
	local m = nouveau("Tonneaux")
	for i, p in { Vp(0, 0, 0), Vp(2.02, 0, 0.26), Vp(0.92, 0, 1.82) } do
		local h, diam = 2.62 - (i - 1) * 0.39, 2.05 - (i - 1) * 0.13
		local c = i % 2 == 0 and rgb(151, 106, 63) or rgb(111, 65, 42)
		for j, t in { { 0.16, 0.87, 0.32 }, { 0.49, 1, 0.39 }, { 0.83, 0.86, 0.34 } } do
			cylProp(m, "Douelles", diam * t[2], h * t[3], p + Vp(0, h * t[1], 0), ({ BOIS_FONCE, c, BOIS_CLAIR })[j], Mat.WoodPlanks)
		end
		cylProp(m, "Fond du fût", diam * 0.76, 0.07, p + Vp(0, h, 0), BOIS_FONCE, Mat.Wood)
		lamesProp(m, "Lame", Vp(diam * 0.59, 0.05, diam * 0.51), p + Vp(0, h + 0.022, 0), 3, "Z", c)
		for _, t in { 0.25, 0.76 } do
			local y = h * t
			cylProp(m, "Cercle", diam * 0.98, 0.125, p + Vp(0, y, 0), FER, Mat.Metal, nil, false)
			rivetProp(m, p + Vp(t < 0.5 and -0.31 or 0.29, y, diam * 0.46), 0.105, FER_CLAIR)
		end
		cylProp(m, "Bonde", 0.18, 0.08, p + Vp(0.16, h + 0.048, 0), BOIS_CLAIR, Mat.Wood)
		-- Les douelles visibles chevauchent le ventre porteur et se perdent sous les cercles.
		for j, profil in { { -1.12, 0.46, 0.62 }, { -0.64, 0.44, 0.77 }, { -0.18, 0.47, 0.83 },
			{ 0.32, 0.48, 0.76 }, { 0.84, 0.43, 0.68 } } do
			local a, w, hauteur = profil[1] + (i - 2) * 0.09, profil[2], profil[3]
			local rayon = diam * 0.457
			reliefProp(m, "Douelle saillante", Vp(diam * w * 0.56, h * hauteur, 0.095),
				p + Vp(math.sin(a) * rayon, h * (0.51 + (j % 3 - 1) * 0.023), math.cos(a) * rayon),
				({ BOIS_FONCE, c, BOIS_CLAIR })[(i + j) % 3 + 1], Mat.Wood, (j % 3 - 1) * 4, math.deg(a))
		end
		reliefProp(m, "Agrafe rouille du cercle", Vp(0.37, 0.21, 0.09),
			p + Vp(-0.12 + i * 0.09, h * 0.76, diam * 0.48), LAITON, Mat.Metal, 0, -5, -4)
		reliefProp(m, "Bois poli autour de la bonde", Vp(0.42, 0.035, 0.20),
			p + Vp(0.15, h + 0.058, 0.04), LIN, Mat.Wood, 0, i * 4 - 9)
		if i ~= 3 then
			detailProp(m, "Tranche usée du fond", Vp(diam * 0.38, 0.04, 0.12), p + Vp(-0.08, h + 0.05, diam * 0.17), BOIS_CLAIR, Mat.Wood, Vp(0, 5, 0))
		end
	end
	fini(m)
end

local function caisseProp(m: Model, p: Vector3, size: number, c: Color3, ouverte: boolean)
	P(m, "Fond", Vp(size, size * 0.13, size), p + Vp(0, size * 0.065, 0), BOIS_FONCE, Mat.WoodPlanks)
	for _, s in { -1, 1 } do
		lamesProp(m, "Bordage", Vp(size, size * 0.84, 0.13), p + Vp(0, size * 0.55, s * (size / 2 - 0.065)), 2, "Y", c)
		lamesProp(m, "Bordage", Vp(0.13, size * 0.84, size - 0.18), p + Vp(s * (size / 2 - 0.065), size * 0.55, 0), 2, "Y", c)
		for _, x in { -0.43, 0.43 } do
			P(m, "Cornière", Vp(0.25, size, 0.25), p + Vp(size * x, size / 2, s * size * 0.43), s == 1 and FER or BOIS_FONCE, s == 1 and Mat.Metal or Mat.Wood)
		end
	end
	-- Le bois frotté se prolonge sur deux arêtes et s'arrête sur une éclisse plus sombre.
	reliefProp(m, "Cadre de rive clair", Vp(size * 0.97, size * 0.10, 0.095),
		p + Vp(0, size * 0.90, size * 0.477), BOIS_CLAIR, Mat.Wood, -3, 0, 2)
	if not ouverte then
		reliefProp(m, "Patin de caisse sombre", Vp(size * 0.92, size * 0.12, 0.10),
			p + Vp(0, size * 0.16, size * 0.478), BOIS_FONCE, Mat.Wood, 0, 0, -2)
	end
	reliefProp(m, "Poignée creuse", Vp(size * 0.25, size * 0.10, 0.067),
		p + Vp(size * 0.08, size * 0.76, size * 0.488), FER_SOMBRE, Mat.Wood)
	if ouverte then
		P(m, "Fond garni", Vp(size * 0.86, size * 0.10, size * 0.83), p + Vp(0, size * 0.82, 0), BOIS, Mat.Wood)
	else
		lamesProp(m, "Couvercle", Vp(size, size * 0.11, size), p + Vp(0, size * 0.96, 0), 2, "X", c)
		lienProp(m, "Écharpe", p + Vp(-size * 0.42, size * 0.18, size * 0.50),
			p + Vp(size * 0.42, size * 0.86, size * 0.50), 0.17, 0.11, BOIS_FONCE, Mat.Wood, false)
	end
end

function PROPS_VALDOR.Caisses()
	local m = nouveau("Caisses")
	caisseProp(m, Vector3.zero, 2.37, BOIS_CLAIR, false)
	caisseProp(m, Vp(2.03, 0, 0.35), 1.84, BOIS, true)
	caisseProp(m, Vp(0.32, 2.37, -0.1), 1.68, BOIS, false)
	for i = 0, 3 do
		local x, z = 1.58 + i % 3 * 0.47, 0.04 + math.floor(i / 3) * 0.64
		P(m, "Choux", Vp(0.67, 0.61, 0.65), Vp(x, 1.74 + i * 0.07, z + i * 0.10), rgb(106 + i * 3, 133 + i * 3, 68),
			Mat.Grass, { forme = "Ball", collide = false })
	end
	reliefProp(m, "Feuille claire froissée", Vp(0.55, 0.19, 0.47), Vp(1.68, 2.02, 0.23),
		MOUSSE_CLAIRE, Mat.Grass, -7, 26, 5, "Ball")
	fini(m)
end

function PROPS_VALDOR.Epouvantail()
	local m = nouveau("Epouvantail")
	P(m, "Poteau", Vp(0.41, 6, 0.39), Vp(0, 3, 0), BOIS_FONCE, Mat.Wood)
	lienProp(m, "Bras", Vp(-2.38, 4.49, 0), Vp(2.34, 4.14, -0.04), 0.30, 0.31, BOIS, Mat.Wood)
	P(m, "Chemise", Vp(1.97, 2.13, 1.06), Vp(0, 4.06, 0.02), GARANCE, Mat.Fabric,
		{ rot = CFrame.Angles(0, 0, -0.05), collide = false })
	for _, s in { -1, 1 } do
		P(m, "Manche", Vp(1.43, 0.67, 0.68), Vp(s * 1.57, 4.36 - s * 0.11, 0.04), GARANCE, Mat.Fabric,
			{ rot = CFrame.Angles(0, 0, -0.075), collide = false })
		for i = 0, 2 do
			lienProp(m, "Paille", Vp(s * 2.12, 4.35 - s * 0.11, 0), Vp(s * (2.60 - i * 0.067), 4.17 - s * 0.10 + i * 0.16, i * 0.085),
				0.085, 0.085, CHAUME, Mat.Grass, false)
		end
	end
	P(m, "Ceinture", Vp(1.99, 0.17, 1.10), Vp(0, 3.41, 0.02), BOIS_FONCE, Mat.Fabric, { collide = false })
	P(m, "Rapiéçage", Vp(0.53, 0.52, 0.08), Vp(-0.45, 3.88, 0.55), LIN, Mat.Fabric, { collide = false })
	P(m, "Cou", Vp(0.59, 0.43, 0.58), Vp(0.04, 5.19, 0), LIN, Mat.Fabric, { collide = false })
	P(m, "Tete", Vp(1.43, 1.46, 1.33), Vp(0.10, 5.90, 0), LIN, Mat.Fabric, { forme = "Ball", collide = false })
	for _, x in { -0.23, 0.42 } do rivetProp(m, Vp(x, 6.03, 0.58), 0.19, BOIS_FONCE) end
	cylProp(m, "Chapeau", 2.53, 0.2, Vp(0.1, 6.57, 0), CHAUME, Mat.Grass,
		CFrame.Angles(0, 0, math.pi / 2 - 0.13), false)
	cylProp(m, "Calotte", 1.32, 0.60, Vp(0.13, 6.91, 0), CHAUME, Mat.Grass, nil, false)
	cylProp(m, "Galon", 1.35, 0.13, Vp(0.13, 6.74, 0), BOIS_FONCE, Mat.Fabric, nil, false)
	reliefProp(m, "Écharpe de toile", Vp(1.28, 0.29, 0.77), Vp(0.08, 5.17, 0.16), rgb(60, 109, 105), Mat.Fabric, 0, -5, -6)
	for i, p in { Vp(-0.43, 4.87, 0.55), Vp(-0.63, 4.55, 0.56), Vp(-0.72, 4.31, 0.58) } do
		reliefProp(m, "Pan effiloché de l’écharpe", Vp(0.37, 0.38 - i * 0.041, 0.13), p,
			i == 3 and rgb(48, 81, 82) or rgb(84, 136, 125), Mat.Fabric, 2, 0, -18 + 4 * i)
	end
	reliefProp(m, "Boucle de corde", Vp(0.37, 0.24, 0.18), Vp(0.15, 3.42, 0.59), LAITON, Mat.Metal, 0, 0, 6)
	for i, x in { -0.78, -0.32, 0.20, 0.67 } do
		reliefProp(m, "Éclat de paille du chapeau", Vp(0.37 + i * 0.041, 0.12, 0.30), Vp(x, 6.54 + i * 0.036, 0.86 - math.abs(x) * 0.2),
			i % 2 == 0 and BOIS or OR_PALE, Mat.Grass, -5, i * 6 - 12, 6)
	end
	reliefProp(m, "Bouton de toile sombre", Vp(0.19, 0.21, 0.10), Vp(0.19, 4.36, 0.55), BOIS_FONCE, Mat.Fabric, 0, 0, 7)
	detailProp(m, "Bandeau du col", Vp(1.31, 0.30, 0.17), Vp(0.02, 4.91, 0.49), rgb(197,89,65), Mat.Fabric, Vp(0, 0, -6))
	detailProp(m, "Revers de col", Vp(0.43, 0.38, 0.16), Vp(-0.07, 4.73, 0.51), rgb(106,49,46), Mat.Fabric, Vp(0, 0, 18), "Wedge")
	detailProp(m, "Écharpe courte", Vp(0.69, 0.28, 0.78), Vp(0.11, 5.28, 0.022), rgb(52,93,104), Mat.Fabric, Vp(4, -4, -7))
	detailProp(m, "Pan d’écharpe effiloché", Vp(0.43, 0.96, 0.14), Vp(0.57, 4.94, 0.40), rgb(58,106,112), Mat.Fabric, Vp(-4, 6, 29), "Wedge")
	detailProp(m, "Ourlet rapiécé", Vp(0.67, 0.24, 0.13), Vp(0.38, 3.19, 0.52), rgb(114,52,47), Mat.Fabric, Vp(0, 0, 5))
	detailProp(m, "Rapiéçage de coude", Vp(0.49, 0.37, 0.089), Vp(-1.70, 4.47, 0.373), rgb(178,119,78), Mat.Fabric, Vp(0, 0, -8))
	detailProp(m, "Paille sous la veste", Vp(0.56, 0.56, 0.32), Vp(-0.49, 3.01, 0.15), CHAUME, Mat.Grass, Vp(5, 6, -12), "Wedge")
	detailProp(m, "Bord cassé du chapeau", Vp(0.75, 0.16, 0.47), Vp(-0.55, 6.58, 0.83), rgb(222,180,96), Mat.Grass, Vp(7, 9, -7), "Wedge")
	detailProp(m, "Pan de galon", Vp(0.25, 0.31, 0.37), Vp(0.70, 6.65, 0.05), BOIS_FONCE, Mat.Grass, Vp(-5, 0, 13))
	fini(m)
end


function PROPS_VALDOR.Botte_Foin()
	local m = nouveau("Botte_Foin")
	P(m, "Cœur de botte", Vp(3.77, 1.97, 2.52), Vp(0, 0.985, 0), CHAUME, Mat.Grass)
	for i = 0, 4 do
		local y = 0.69 + i * 0.355
		local t = i % 3
		P(m, "Gerbe", Vp(3.92 - t * 0.12, 0.51, 2.75 - t * 0.13), Vp(i % 2 * 0.071, y, 0.04 * t),
			CHAUME:Lerp(i % 2 == 0 and BOIS_CLAIR or BOIS, t * 0.12), Mat.Grass,
			{ rot = CFrame.Angles(0, (t - 1) * 0.018, 0) })
	end
	for _, x in { -0.94, 0.89 } do
		local a, b, c, d = Vp(x, 0.12, -1.31), Vp(x, 2.26, -1.29), Vp(x, 2.35, 1.25), Vp(x, 0.19, 1.32)
		lienProp(m, "Lien", a, b, 0.075, 0.093, BOIS_FONCE, Mat.Fabric, false)
		lienProp(m, "Lien", b, c, 0.075, 0.093, BOIS_FONCE, Mat.Fabric, false)
		lienProp(m, "Lien", c, d, 0.075, 0.093, BOIS_FONCE, Mat.Fabric, false)
		rivetProp(m, Vp(x, 2.34, 0.4), 0.14, BOIS_CLAIR)
	end
	for i, profil in { { -1.34, 2.30, 0.97 }, { -0.61, 2.33, 1.04 }, { 0.27, 2.35, 1.10 }, { 0.92, 2.31, 1.06 } } do
		reliefProp(m, "Nappe claire de foin", Vp(0.90 + i * 0.06, 0.21, 0.59), Vp(profil[1], profil[2], profil[3]),
			i == 2 and CHAUME or OR_PALE, Mat.Grass, -5, 0, i * 3 - 6)
		lienProp(m, "Mèche de foin rabattue", Vp(profil[1], profil[2], 1.25), Vp(profil[1] + 0.24 - i * 0.07, 1.94 - i * 0.072, 1.32),
			0.20, 0.12, i % 2 == 0 and BOIS or CHAUME, Mat.Grass, false)
	end
	reliefProp(m, "Nœud de ficelle", Vp(0.27, 0.19, 0.23), Vp(0.88, 2.36, 0.41), LIN, Mat.Fabric, 4, -7, 4)
	detailProp(m, "Crête de paille rabattue", Vp(2.84, 0.16, 0.62), Vp(-0.29, 2.33, 0.38), rgb(230,184,95), Mat.Grass, Vp(2, 4, -2))
	detailProp(m, "Paille effilochée à gauche", Vp(0.91, 0.27, 0.45), Vp(-1.41, 2.14, 0.74), rgb(208,162,78), Mat.Grass, Vp(7, -6, -5), "Wedge")
	detailProp(m, "Tresse du flanc", Vp(1.44, 0.25, 0.16), Vp(0.48, 1.83, 1.32), rgb(226,176,84), Mat.Grass, Vp(0, 0, 5))
	detailProp(m, "Paille ancienne au cœur", Vp(0.72, 0.20, 0.18), Vp(0.66, 1.53, 1.32), rgb(146,108,54), Mat.Grass, Vp(0, 0, -6), "Wedge")
	detailProp(m, "Pointe libre de la gerbe", Vp(0.65, 0.23, 0.30), Vp(-1.42, 1.71, 1.22), rgb(236,185,90), Mat.Grass, Vp(5, -6, 6), "Wedge")
	detailProp(m, "Nœud de corde saillant", Vp(0.34, 0.19, 0.25), Vp(-0.92, 2.34, 0.60), BOIS_FONCE, Mat.Fabric, Vp(-4, 18, -5))
	detailProp(m, "Brin de corde libre", Vp(0.56, 0.072, 0.095), Vp(-0.78, 2.40, 0.72), LIN, Mat.Fabric, Vp(0, -34, -4))
	fini(m)
end

function PROPS_VALDOR.Boite_Lettres()
	local m = nouveau("Boite_Lettres")
	P(m, "Semelle", Vp(0.68, 0.24, 0.65), Vp(0, 0.12, 0), PIERRE, Mat.Cobblestone)
	P(m, "Poteau", Vp(0.39, 3.03, 0.41), Vp(0, 1.74, 0), BOIS, Mat.Wood)
	lamesProp(m, "Boite", Vp(1.58, 1.41, 1.17), Vp(0, 3.83, 0), 5, "X", BOIS)
	P(m, "Battant", Vp(1.38, 1.29, 0.08), Vp(0, 3.83, -0.60), BOIS_CLAIR, Mat.Wood)
	P(m, "Fente", Vp(1.02, 0.13, 0.067), Vp(0, 4.08, -0.65), rgb(37, 32, 31), Mat.Metal, { collide = false })
	cylProp(m, "Sceau", 0.40, 0.075, Vp(0, 3.63, -0.66), GARANCE, Mat.CeramicTiles, FACE_PROP, false)
	for _, y in { 3.33, 4.26 } do
		P(m, "Ferrure", Vp(1.53, 0.11, 0.08), Vp(0, y, -0.65), FER, Mat.Metal, { collide = false })
		for _, x in { -0.61, 0.61 } do rivetProp(m, Vp(x, y, -0.69), 0.08) end
	end
	toitureProp(m, 1.96, 1.64, 4.52, 0.36, 0, false)
	reliefProp(m, "Bec de la fente", Vp(1.20, 0.17, 0.16), Vp(0, 4.18, -0.63), FER_CLAIR, Mat.Metal, -7)
	reliefProp(m, "Lettre pliée dans la fente", Vp(0.65, 0.10, 0.17), Vp(-0.11, 4.055, -0.67), LIN, Mat.Fabric, 6, 0, -5)
	reliefProp(m, "Écusson du sceau", Vp(0.48, 0.49, 0.14), Vp(0, 3.63, -0.612), LAITON, Mat.Metal, 0, 0, 45)
	reliefProp(m, "Court volet de levée", Vp(0.16, 0.49, 0.31), Vp(0.79, 4.08, 0.16), GARANCE, Mat.Metal, 0, -5, -5)
	reliefProp(m, "Pied du volet", Vp(0.17, 0.39, 0.14), Vp(0.75, 3.79, 0.17), FER_SOMBRE, Mat.Metal, 6, 0, -7)
	lienProp(m, "Console de la boîte", Vp(0.1, 2.66, -0.08), Vp(0.53, 3.18, -0.48), 0.16, 0.16, BOIS_CLAIR, Mat.Wood, false)
	for i, x in { -0.64, -0.33, 0.13, 0.55, 0.74 } do
		reliefProp(m, "Écaille de bardeau clair", Vp(0.34, 0.088, 0.25), Vp(x, 4.64 + i % 3 * 0.039, 0.65 - i % 2 * 0.07),
			i % 3 == 0 and BOIS_FONCE or BOIS_CLAIR, Mat.Wood, 22, 0, i % 3 * 5 - 5)
	end
	detailProp(m, "Plaque sous la fente", Vp(1.16, 0.34, 0.055), Vp(0, 4.075, -0.654), rgb(125,81,46), Mat.Metal, Vp(0, 0, -3))
	detailProp(m, "Auvent de fente en laiton", Vp(1.21, 0.10, 0.16), Vp(0.004, 4.205, -0.696), rgb(205,149,72), Mat.Metal, Vp(-5, 0, 0))
	detailProp(m, "Mât du fanion de levée", Vp(0.102, 0.62, 0.13), Vp(0.82, 4.02, -0.24), FER, Mat.Metal, Vp(0, 0, -6))
	detailProp(m, "Fanion de levée patiné", Vp(0.11, 0.30, 0.40), Vp(0.85, 4.27, -0.22), GARANCE, Mat.Metal, Vp(5, 0, -5), "Wedge")
	detailProp(m, "Bouton du fanion", Vp(0.13, 0.17, 0.16), Vp(0.82, 3.76, -0.25), rgb(199,148,70), Mat.Metal)
	detailProp(m, "Bois nu de la boîte", Vp(0.49, 0.12, 0.059), Vp(-0.31, 3.63, -0.636), BOIS, Mat.Wood, Vp(0, 0, -6))
	detailProp(m, "Aubier dans le fil", Vp(0.34, 0.065, 0.048), Vp(-0.37, 3.66, -0.673), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -6))
	detailProp(m, "Sous-toit usé", Vp(1.57, 0.14, 0.14), Vp(0, 4.47, -0.66), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 3))
	detailProp(m, "Larme sombre au bardeau", Vp(0.22, 0.23, 0.14), Vp(-0.49, 4.47, -0.68), BOIS_FONCE, Mat.Wood, Vp(-4, 0, -7), "Wedge")
	detailProp(m, "Jambe de force du caisson", Vp(0.28, 0.64, 0.25), Vp(0.13, 3.12, -0.22), BOIS_FONCE, Mat.Wood, Vp(-30, 0, -8))
	detailProp(m, "Empreinte de cire", Vp(0.19, 0.18, 0.045), Vp(0, 3.63, -0.711), rgb(195,82,64), Mat.CeramicTiles, Vp(0, 0, 39))
	fini(m)
end

function PROPS_VALDOR.Cloture()
	local m = nouveau("Cloture")
	P(m, "Sabot", Vp(0.51, 0.24, 0.51), Vp(-2, 0.12, 0), PIERRE, Mat.Slate)
	P(m, "Poteau", Vp(0.50, 2.82, 0.49), Vp(-2, 1.65, 0), BOIS, Mat.Wood)
	P(m, "Tête taillée", Vp(0.49, 0.23, 0.49), Vp(-2, 3.075, 0), BOIS_FONCE, Mat.Wood, { forme = "Wedge" })
	for i, y in { 1.11, 2.24 } do
		local a, b = Vp(-2.04, y, 0), Vp(2.08, y + (i == 1 and -0.05 or 0.09), 0)
		lienProp(m, "Lisse", a, b, 0.27, 0.31, teinteProp(BOIS_CLAIR, i), Mat.WoodPlanks)
		rivetProp(m, Vp(-1.99, y, 0.258), 0.11)
		P(m, "Tenon", Vp(0.32, 0.20, 0.29), Vp(-2.10, y, 0), BOIS_FONCE, Mat.Wood)
	end
	reliefProp(m, "Coiffe biseautée du piquet", Vp(0.51, 0.14, 0.51), Vp(-2, 3.15, 0), BOIS_CLAIR, Mat.Wood, 3, 0, -5)
	for i, y in { 1.11, 2.24 } do
		reliefProp(m, "Bande de bois fendu", Vp(2.62 + i * 0.18, 0.11, 0.079), Vp(0.13 - i * 0.24, y + 0.04, 0.108),
			i == 1 and BOIS or BOIS_CLAIR, Mat.Wood, 0, 0, i * 3 - 4)
		reliefProp(m, "Cheville traversante", Vp(0.19, 0.24, 0.16), Vp(-2.06, y, -0.19), LAITON, Mat.Metal, 0, 0, i * 5 - 3)
	end
	reliefProp(m, "Mousse de pied déchirée", Vp(0.39, 0.29, 0.14), Vp(-1.96, 0.29, 0.22), MOUSSE, Mat.Grass, -5, 0, 7)
	detailProp(m, "Oblique de réparation", Vp(0.19, 1.60, 0.16), Vp(0.70, 1.68, 0.10), BOIS, Mat.Wood, Vp(0, 0, -43))
	detailProp(m, "Tranche de lisse fendue", Vp(1.47, 0.10, 0.13), Vp(-0.37, 2.30, 0.11), BOIS_FONCE, Mat.Wood, Vp(0, 0, 3))
	detailProp(m, "Aubier au bord de la fente", Vp(0.81, 0.071, 0.095), Vp(-0.25, 2.35, 0.15), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 4))
	detailProp(m, "Épaulement du sabot", Vp(0.49, 0.14, 0.48), Vp(-2, 0.255, 0), BOIS_FONCE, Mat.Wood, Vp(0, 5, 0))
	detailProp(m, "Fiche de réparation", Vp(0.17, 0.32, 0.09), Vp(0.35, 1.23, 0.20), FER, Mat.Metal, Vp(0, 0, 5))
	fini(m)
end

function PROPS_VALDOR.Feu_Camp()
	local m = nouveau("Feu_Camp")
	cylProp(m, "Cendres", 3.12, 0.12, Vp(0, 0.06, 0), rgb(65, 57, 49), Mat.Slate)
	pierreRonde(m, "Pierre", Vp(0, 0.25, 0), 1.57, 10, 0.5, 0.68, 0.14)
	for i = 0, 3 do
		local a = i * math.pi / 4 + 0.12
		local d = i % 2 == 0 and 0.36 or 0.29
		cylProp(m, "Buche", d, 2.1 - i * 0.19, Vp(0, 0.22 + i * 0.09, 0), BOIS_FONCE, Mat.Wood,
			CFrame.Angles(0, a, 0))
	end
	local f = lumiereProp(m, "Flamme", Vp(0, 0.64, 0.02), Vp(0.36, 0.46, 0.41), 20, 2)
	local fire = Instance.new("Fire")
	fire.Size, fire.Heat, fire.Parent = 3, 6, f
	for i, p in { Vp(-0.49, 0.34, 0.41), Vp(-0.09, 0.41, -0.16), Vp(0.47, 0.32, 0.35), Vp(0.30, 0.42, -0.49) } do
		reliefProp(m, "Braise fendue", Vp(0.37, 0.13, 0.25), p, rgb(255, 104 + i * 13, 41), Mat.Neon,
			5, i * 23, i * 4 - 8, "Wedge")
	end
	for i, a in { -0.45, 0.11, 0.91, 2.02 } do
		reliefProp(m, "Arête brisée de la pierre de feu", Vp(0.71, 0.23, 0.46),
			Vp(math.sin(a) * 1.51, 0.53 - i % 3 * 0.033, math.cos(a) * 1.51),
			i % 2 == 0 and CALCAIRE or FER_SOMBRE, Mat.Slate, 5, math.deg(a), i * 4 - 9, "Wedge")
	end
	reliefProp(m, "Cœur de charbon mat", Vp(0.93, 0.12, 0.73), Vp(0.10, 0.21, 0.09), FER_SOMBRE, Mat.Slate, 0, -7)
	detailProp(m, "Lit de tisons", Vp(1.24, 0.08, 0.92), Vp(0.07, 0.26, 0.06), rgb(236,79,33), Mat.Neon, Vp(0, -9, 0), "Ball")
	detailProp(m, "Pointe d’un tison", Vp(0.38, 0.16, 0.35), Vp(0.51, 0.34, 0.28), rgb(255,146,48), Mat.Neon, Vp(5, 3, -7), "Wedge")
	detailProp(m, "Charbon fendu vif", Vp(0.47, 0.084, 0.12), Vp(-0.52, 0.35, -0.14), rgb(255,99,46), Mat.Neon, Vp(0, 15, 0))
	detailProp(m, "Couronne noircie", Vp(1.17, 0.12, 0.31), Vp(-0.08, 0.44, 1.17), rgb(62,54,48), Mat.Slate, Vp(0, -5, -4))
	detailProp(m, "Suie en langue", Vp(0.31, 0.21, 0.22), Vp(0.33, 0.47, 1.35), rgb(79,67,61), Mat.Slate, Vp(4, 3, 7), "Wedge")
	detailProp(m, "Éclat de pierre blanche", Vp(0.67, 0.15, 0.36), Vp(-0.80, 0.49, 1.19), CALCAIRE, Mat.Slate, Vp(5, 21, -6), "Wedge")
	detailProp(m, "Moellon brûlé rompu", Vp(0.61, 0.22, 0.36), Vp(1.21, 0.37, 1.00), rgb(113,98,85), Mat.Slate, Vp(4, -17, -4))
	detailProp(m, "Cendre claire sur une bûche", Vp(0.76, 0.10, 0.19), Vp(0.21, 0.55, -0.12), rgb(156,137,113), Mat.Wood, Vp(0, 52, 5))
	fini(m)
end

local function coffreProp(nom: string, c: Color3, colFer: Color3)
	local m = nouveau(nom)
	local sombre, miel = rgb(69, 41, 31), rgb(174, 108, 64)
	local bronze, laiton = rgb(151, 91, 36), rgb(236, 176, 71)
	local acier = colFer:Lerp(rgb(121, 132, 140), 0.55)
	-- Props anime cette pièce. Les lattes et ferrures mobiles suivent son CFrame.
	local couvercle = P(m, "Couvercle", Vp(3.08, 0.34, 2.08), Vp(0, 1.68, 0), c, Mat.Wood, { transp = 1 })
	local function mobile(p: BasePart)
		p.Anchored = false
		local joint = Instance.new("WeldConstraint")
		joint.Part0, joint.Part1, joint.Parent = couvercle, p, p
	end
	P(m, "Fond", Vp(3, 0.24, 1.99), Vp(0, 0.12, 0), sombre, Mat.Wood)
	for _, s in { -1, 1 } do
		for i, ton in { sombre, c, miel } do
			local y = 0.23 + (i - 0.5) * 0.44
			P(m, "Bordage de façade", Vp(2.98, 0.45, 0.23), Vp(0, y, s * 0.88), ton, Mat.WoodPlanks)
			P(m, "Bordage de joue", Vp(0.24, 0.45, 1.61), Vp(s * 1.37, y + s * 0.012, -0.015), ton, Mat.WoodPlanks)
		end
		detailProp(m, "Traverse de fer entre les sabots", Vp(2.61, 0.17, 0.095),
			Vp(s * 0.026, 0.25, s * 1.002), colFer, Mat.Metal, Vp(0, 0, s * 2))
		mobile(detailProp(m, "Joue de voûte", Vp(0.17, 0.32, 1.82), Vp(s * 1.44, 1.84, 0), sombre, Mat.Wood))
		mobile(detailProp(m, "Rebord du couvercle", Vp(3.06, 0.13, 0.12), Vp(0, 1.68, s * 0.975), colFer, Mat.Metal))
	end
	local voute = {
		{ z = -0.82, y = 1.81, profondeur = 0.44, angle = 23, ton = sombre },
		{ z = -0.43, y = 2.01, profondeur = 0.52, angle = 21, ton = c },
		{ z = 0.015, y = 2.12, profondeur = 0.56, angle = 2, ton = miel },
		{ z = 0.45, y = 2.01, profondeur = 0.51, angle = -22, ton = c },
		{ z = 0.83, y = 1.81, profondeur = 0.42, angle = -26, ton = miel },
	}
	for _, latte in voute do
		mobile(detailProp(m, "Latte de voûte", Vp(3.04, 0.24, latte.profondeur), Vp(0, latte.y, latte.z),
			latte.ton, Mat.WoodPlanks, Vp(latte.angle, 0, 0)))
	end
	for _, x in { -1.04, 1.04 } do
		for _, z in { -1, 1 } do
			detailProp(m, "Cerclage", Vp(0.24, 1.46, 0.10), Vp(x, 0.80, z), colFer, Mat.Metal)
			local a, b = Vp(x, 1.74, z * 0.98), Vp(x, 2.235, z * 0.52)
			local bande = P(m, "Cerclage de voûte", Vp(0.23, 0.092, (b - a).Magnitude), Vector3.zero, colFer, Mat.Metal,
				{ cf = CFrame.lookAt((a + b) / 2, b), collide = false })
			bande.CanQuery, bande.CanTouch = false, false
			mobile(bande)
			detailProp(m, "Sabot de bronze", Vp(0.37, 0.30, 0.17), Vp(x * 1.27, 0.24, z * 0.981), bronze, Mat.Metal, Vp(0, 0, 3 * z))
			detailProp(m, "Gradin de laiton", Vp(0.23, 0.17, 0.062), Vp(x * 1.29, 0.29, z * 1.065), laiton, Mat.Metal)
			mobile(detailProp(m, "Coin doré en gradin", Vp(0.31, 0.22, 0.17), Vp(x * 1.31, 1.76, z * 0.971), laiton, Mat.Metal, Vp(4 * z, 0, 0)))
		end
		mobile(detailProp(m, "Bande sommitale", Vp(0.23, 0.092, 1.05), Vp(x, 2.268, 0), colFer, Mat.Metal))
		for _, y in { 0.32, 1.39 } do rivetProp(m, Vp(x, y, 1.061), 0.135, acier) end
	end
	detailProp(m, "Serrure", Vp(0.59, 0.58, 0.14), Vp(0, 1.45, 1.06), bronze, Mat.Metal)
	detailProp(m, "Plaque de laiton", Vp(0.46, 0.49, 0.075), Vp(0, 1.47, 1.12), laiton, Mat.Metal, Vp(0, 0, -3))
	detailProp(m, "Entrée", Vp(0.14, 0.24, 0.024), Vp(0, 1.45, 1.163), sombre, Mat.Metal)
	detailProp(m, "Reflet au fond de la serrure", Vp(0.09, 0.095, 0.018), Vp(0, 1.51, 1.176), rgb(255, 191, 74), Mat.Neon)
	for i, x in { -0.54, 0.52 } do
		local y = i == 2 and 0.57 or 0.80
		detailProp(m, "Griffure creuse", Vp(0.30 - i * 0.025, 0.067, 0.022), Vp(x, y, 1.007), sombre, Mat.Wood, Vp(0, 0, 28 + i * 5))
		detailProp(m, "Bois mis à nu", Vp(0.22 - i * 0.022, 0.035, 0.018), Vp(x + 0.02, y - 0.033, 1.022), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 28 + i * 5))
	end
	fini(m)
end

function PROPS_VALDOR.Coffre_Joueur()
	coffreProp("Coffre_Joueur", BOIS, FER)
end

function PROPS_VALDOR.Coffre()
	coffreProp("Coffre", rgb(133, 76, 42), FER_SOMBRE)
end

function PROPS_VALDOR.Etabli()
	local m = nouveau("Etabli")
	lamesProp(m, "Plateau", Vp(4.38, 0.38, 2.38), Vp(0, 3.05, 0), 5, "Z", BOIS_CLAIR)
	for _, x in { -1.88, 1.88 } do
		for _, z in { -0.88, 0.88 } do
			P(m, "Pied", Vp(0.42, 2.92, 0.43), Vp(x, 1.46, z), BOIS, Mat.Wood)
			rivetProp(m, Vp(x, 2.65, z + math.sign(z) * 0.21), 0.14)
		end
		P(m, "Entretoise", Vp(0.31, 0.29, 1.94), Vp(x, 0.68, 0), BOIS_FONCE, Mat.Wood)
	end
	for _, z in { -0.89, 0.89 } do
		P(m, "Traverse", Vp(4.1, 0.35, 0.22), Vp(0, 2.73, z), BOIS_FONCE, Mat.Wood)
	end
	P(m, "Entretoise", Vp(3.83, 0.24, 0.28), Vp(0, 0.68, 0), BOIS_FONCE, Mat.Wood)
	P(m, "Scie", Vp(1.65, 0.061, 0.46), Vp(-0.69, 3.27, 0.11), PIERRE_CLAIRE, Mat.Metal, { collide = false })
	P(m, "Poignée de scie", Vp(0.47, 0.18, 0.51), Vp(-1.63, 3.31, 0.12), BOIS_FONCE, Mat.Wood, { collide = false })
	detailProp(m, "Dos bleui de la scie", Vp(1.48, 0.05, 0.17), Vp(-0.73, 3.303, -0.068), FER, Mat.Metal, Vp(0, -2, 0))
	detailProp(m, "Paume polie de la poignée", Vp(0.32, 0.08, 0.34), Vp(-1.69, 3.406, 0.15), BOIS_CLAIR, Mat.Wood, Vp(0, -6, -4), "Wedge")
	for i = 0, 6 do
		P(m, "Dent de scie", Vp(0.13, 0.061, 0.14), Vp(-1.39 + i * 0.22, 3.27, 0.39), PIERRE_CLAIRE, Mat.Metal,
			{ forme = "Wedge", collide = false })
	end
	lienProp(m, "Marteau", Vp(1.08, 3.29, 0.50), Vp(1.33, 3.36, -0.55), 0.17, 0.17, BOIS, Mat.Wood, false)
	P(m, "Tete", Vp(0.72, 0.32, 0.36), Vp(1.33, 3.39, -0.54), FER, Mat.Metal, { collide = false })
	-- L'étau chevauche la rive et sa vis descend devant la traverse.
	reliefProp(m, "Selle de l’étau", Vp(0.56, 0.24, 0.84), Vp(-1.42, 3.23, 0.72), FER_SOMBRE, Mat.Metal)
	reliefProp(m, "Mors fixe", Vp(0.56, 0.31, 0.21), Vp(-1.42, 3.42, 0.58), FER, Mat.Metal)
	reliefProp(m, "Mors mobile poli", Vp(0.58, 0.31, 0.18), Vp(-1.42, 3.41, 1.015), FER_CLAIR, Mat.Metal, -4)
	cylProp(m, "Noix de la vis", 0.25, 0.23, Vp(-1.42, 3.15, 1.075), LAITON, Mat.Metal, FACE_PROP, false)
	lienProp(m, "Levier de l’étau", Vp(-1.65, 2.90, 1.15), Vp(-1.22, 3.37, 1.15), 0.10, 0.10, FER_CLAIR, Mat.Metal, false)
	reliefProp(m, "Tablette basse", Vp(2.99, 0.16, 0.78), Vp(0.13, 0.88, 0.28), BOIS, Mat.WoodPlanks)
	reliefProp(m, "Rive de tablette entaillée", Vp(2.35, 0.14, 0.16), Vp(0.29, 0.86, 0.67), BOIS_CLAIR, Mat.Wood, 0, 0, 3)
	for i, x in { 0.23, 0.58, 0.82 } do
		reliefProp(m, "Copeau relevé", Vp(0.29 - i * 0.022, 0.10, 0.18), Vp(x, 3.29, -0.49 - i * 0.10),
			i == 2 and BOIS or LIN, Mat.Wood, 8, i * 19, 5, "Wedge")
	end
	for i, x in { -0.64, -0.19, 0.33 } do
		reliefProp(m, "Entaille de la rive", Vp(0.13 + 0.06 * i, 0.09, 0.051), Vp(x, 3.12 - 0.03 * i, 1.182),
			BOIS_FONCE, Mat.Wood, 0, 0, -7 * i)
	end
	detailProp(m, "Mordache fixe", Vp(0.51, 0.50, 0.22), Vp(1.50, 2.93, 1.02), BOIS_FONCE, Mat.Wood, Vp(0, 0, -3))
	detailProp(m, "Mordache mobile", Vp(0.57, 0.46, 0.22), Vp(1.50, 2.93, 1.19), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -3))
	detailProp(m, "Alèse éclatée", Vp(1.27, 0.13, 0.15), Vp(-0.54, 3.17, 1.09), rgb(192,132,83), Mat.Wood, Vp(0, 0, 4))
	detailProp(m, "Entaille dans l’alèse", Vp(0.47, 0.11, 0.043), Vp(-0.79, 3.17, 1.169), BOIS_FONCE, Mat.Wood, Vp(0, 0, -8))
	detailProp(m, "Chute de bois", Vp(0.68, 0.12, 0.36), Vp(0.14, 3.30, -0.67), BOIS, Mat.Wood, Vp(0, 14, 0))
	detailProp(m, "Éclat de dosse", Vp(0.49, 0.09, 0.23), Vp(0.24, 3.38, -0.65), BOIS_CLAIR, Mat.Wood, Vp(-4, 24, 0), "Wedge")
	detailProp(m, "Coin de tenon", Vp(0.38, 0.18, 0.20), Vp(-1.7, 2.53, 0.95), BOIS_CLAIR, Mat.Wood, Vp(0, 6, 3))
	detailProp(m, "Tiroir à outils", Vp(1.21, 0.37, 0.24), Vp(-0.2, 2.60, 0.99), BOIS, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Lèvre du tiroir", Vp(1.24, 0.09, 0.13), Vp(-0.2, 2.43, 1.048), BOIS_FONCE, Mat.Wood)
	detailProp(m, "Vis d’étau", Vp(0.19, 0.20, 0.20), Vp(1.50, 2.89, 1.29), FER, Mat.Metal)
	detailProp(m, "Manivelle d’étau", Vp(0.105, 0.66, 0.10), Vp(1.54, 2.69, 1.31), rgb(142,151,148), Mat.Metal, Vp(0, 0, 16))
	detailProp(m, "Tirette encastrée", Vp(0.37, 0.09, 0.09), Vp(-0.2, 2.64, 1.112), FER, Mat.Metal)
	fini(m)
end

function PROPS_VALDOR.Scierie()
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local catalogue = require(shared:WaitForChild("Catalogue"))
	local modele = assert(catalogue.build("Scierie"), "Modèle Scierie absent du catalogue")
	local ancien = dossier:FindFirstChild("Scierie")
	if ancien then ancien:Destroy() end
	fini(modele)
end

function PROPS_VALDOR.Enclume()
	local m = nouveau("Enclume")
	cylProp(m, "Billot", 1.77, 1.58, Vp(0, 0.79, 0), BOIS, Mat.Wood)
	cylProp(m, "Coupe", 1.68, 0.09, Vp(0, 1.58, 0), BOIS_CLAIR, Mat.Wood)
	for _, y in { 0.25, 1.26 } do
		cylProp(m, "Cerclage", 1.82, 0.13, Vp(0, y, 0), FER, Mat.Metal, nil, false)
		for _, x in { -0.48, 0.44 } do rivetProp(m, Vp(x, y, 0.79), 0.11) end
	end
	P(m, "Pied", Vp(1.48, 0.29, 1.04), Vp(0, 1.72, 0), FER, Mat.Metal)
	P(m, "Taille", Vp(0.96, 0.53, 0.73), Vp(-0.05, 2.01, 0), FER, Mat.Metal)
	P(m, "Table", Vp(2.49, 0.32, 1.08), Vp(0, 2.34, 0), FER, Mat.Metal)
	P(m, "Face", Vp(2.26, 0.074, 0.97), Vp(-0.07, 2.51, 0), rgb(108, 104, 97), Mat.Metal, { collide = false })
	P(m, "Bigorne", Vp(0.86, 0.38, 1.03), Vp(1.60, 2.35, 0), FER, Mat.Metal, { forme = "Wedge", rot = CFrame.Angles(0, -math.pi / 2, 0) })
	lienProp(m, "Marteau", Vp(-0.82, 2.60, 0.37), Vp(-0.50, 2.69, -0.32), 0.17, 0.16, BOIS, Mat.Wood, false)
	P(m, "Tete", Vp(0.47, 0.29, 0.30), Vp(-0.5, 2.70, -0.31), FER, Mat.Metal, { collide = false })
	reliefProp(m, "Embase évasée", Vp(1.66, 0.15, 1.18), Vp(-0.06, 1.67, 0), FER_SOMBRE, Mat.Metal, 0, -3)
	reliefProp(m, "Épaulement forgé", Vp(1.62, 0.24, 0.93), Vp(-0.14, 2.17, 0), FER, Mat.Metal, 0, 3, 4)
	reliefProp(m, "Biseau de frappe", Vp(1.87, 0.098, 0.16), Vp(0.13, 2.46, 0.51), FER_CLAIR, Mat.Metal, 0, 0, -2)
	reliefProp(m, "Trou carré du talon", Vp(0.29, 0.025, 0.27), Vp(-0.93, 2.557, -0.24), FER_SOMBRE, Mat.Metal, 0, -5)
	for i, x in { -0.48, -0.13, 0.33 } do
		reliefProp(m, "Écorce détachée du billot", Vp(0.30, 0.89 - 0.12 * i, 0.13), Vp(x, 0.79, 0.72 + (i == 2 and 0.12 or 0)),
			i == 2 and BOIS_CLAIR or BOIS_FONCE, Mat.Wood, -4, (i - 2) * 24, i * 3)
	end
	reliefProp(m, "Fente du bois de bout", Vp(0.54, 0.025, 0.08), Vp(-0.42, 1.632, 0.54), BOIS_FONCE, Mat.Wood, 0, -26)
	detailProp(m, "Arête polie", Vp(1.75, 0.095, 0.095), Vp(0.24, 2.43, 0.54), rgb(154,164,165), Mat.Metal, Vp(0, 0, -2))
	detailProp(m, "Talon étagé", Vp(0.46, 0.20, 0.99), Vp(-1.08, 2.46, 0), rgb(105,117,123), Mat.Metal)
	detailProp(m, "Carré de l’enclume", Vp(0.25, 0.022, 0.24), Vp(-1.03, 2.573, 0.14), rgb(40,42,47), Mat.Metal, Vp(0, 5, 0))
	detailProp(m, "Biseau de la bigorne", Vp(0.64, 0.084, 0.52), Vp(1.56, 2.53, 0), rgb(141,145,145), Mat.Metal, Vp(0, 0, -10), "Wedge")
	detailProp(m, "Calamine jouant sous l’arête", Vp(0.53, 0.13, 0.043), Vp(0.54, 2.28, 0.55), rgb(48,51,61), Mat.Metal, Vp(0, 0, 5))
	detailProp(m, "Écorce relevée", Vp(0.31, 0.77, 0.17), Vp(-0.29, 0.82, 0.79), BOIS_FONCE, Mat.Wood, Vp(0, -12, -5))
	detailProp(m, "Veine de billot", Vp(0.17, 0.72, 0.12), Vp(0.43, 0.83, 0.744), BOIS_CLAIR, Mat.Wood, Vp(0, 15, 5))
	detailProp(m, "Fente ouverte du billot", Vp(0.12, 0.41, 0.065), Vp(-0.16, 1.04, 0.87), BOIS_FONCE, Mat.Wood, Vp(0, 0, -11))
	fini(m)
end

function PROPS_VALDOR.Fourneau()
	local m = nouveau("Fourneau")
	P(m, "Sole", Vp(3.4, 0.31, 2.98), Vp(0, 0.155, 0), PIERRE, Mat.Cobblestone)
	P(m, "Corps", Vp(3.28, 3.03, 1.28), Vp(0, 1.76, -0.7), CALCAIRE, Mat.Cobblestone)
	for i = 0, 4 do
		for _, s in { -1, 1 } do
			local w = 0.73 + i % 3 * 0.074
			P(m, "Jambage", Vp(w, 0.49, 2.70 - i % 2 * 0.07), Vp(s * (1.64 - w / 2), 0.50 + i * 0.49, 0.085),
				i % 2 == 0 and CALCAIRE or PIERRE, Mat.Slate)
		end
	end
	P(m, "Bouche", Vp(1.54, 1.2, 0.21), Vp(0, 1.02, -0.02), rgb(48, 40, 36), Mat.Slate)
	for i = 0, 6 do
		local a = i * math.pi / 6
		P(m, "Claveau", Vp(0.34, 0.38, 0.39), Vp(math.cos(a) * 0.81, 1.04 + math.sin(a) * 0.64, 1.24),
			teinteProp(rgb(150, 97, 72), i), Mat.Brick, { rot = CFrame.Angles(0, 0, a - math.pi / 2) })
	end
	P(m, "Linteau", Vp(3.24, 0.41, 2.69), Vp(0, 2.53, 0), PIERRE, Mat.Cobblestone)
	P(m, "Corniche", Vp(3.4, 0.25, 2.97), Vp(0, 2.86, 0), CALCAIRE, Mat.Slate)
	P(m, "Dessus", Vp(2.8, 0.48, 2.32), Vp(0, 3.14, -0.13), PIERRE, Mat.Cobblestone)
	for i = 0, 3 do
		P(m, "Moellon", Vp(1.04 - i * 0.042, 0.47, 1.06 - i % 2 * 0.058), Vp(0.69, 3.59 + i * 0.46, -0.56),
			i % 2 == 0 and CALCAIRE or PIERRE, Mat.Slate)
	end
	P(m, "Cheminee", Vp(1.15, 0.22, 1.13), Vp(0.69, 5.31, -0.56), PIERRE, Mat.Cobblestone)
	P(m, "Cendres", Vp(1.34, 0.23, 1.33), Vp(0, 0.41, 0.66), FER, Mat.Slate, { collide = false })
	lumiereProp(m, "Braise", Vp(0, 0.64, 1.06), Vp(1.03, 0.37, 0.51), 12, 1.5)
	reperesFeu(m)
	local suie = rgb(54, 46, 44)
	local brique = rgb(184, 101, 67)
	for i, profil in { { -1.23, 1.17, -7 }, { 1.20, 1.27, 5 }, { -0.64, 1.87, -4 }, { 0.39, 1.88, 4 } } do
		local x, y, angle = profil[1], profil[2], profil[3]
		reliefProp(m, "Pierre noircie du foyer", Vp(0.46 + 0.08 * i, 0.28, 0.11), Vp(x, y, 1.425), suie, Mat.Slate, 0, 0, angle)
	end
	for i, profil in { { -1.04, 0.56, 0.67 }, { -0.45, 0.43, 0.59 }, { 0.09, 0.49, 0.53 }, { 0.66, 0.42, 0.67 }, { 1.22, 0.59, 0.45 } } do
		reliefProp(m, "Seuil de briques cassées", Vp(profil[3], 0.20, 0.43), Vp(profil[1], profil[2], 1.23),
			i % 2 == 0 and brique or rgb(121, 65, 48), Mat.Brick, i * 2 - 6, 0, i * 3 - 8)
	end
	for i, y in { 3.63, 4.08, 4.48, 4.86 } do
		reliefProp(m, "Joue de cheminée décalée", Vp(0.78 - i * 0.067, 0.27, 0.10),
			Vp(0.63 + i * 0.035, y, -0.039), i == 4 and suie or CALCAIRE, Mat.Slate, 0, 0, i * 3 - 7)
	end
	reliefProp(m, "Gueule noire de la cheminée", Vp(0.79, 0.033, 0.76), Vp(0.69, 5.423, -0.56), suie, Mat.Slate)
	reliefProp(m, "Fissure de braise", Vp(0.65, 0.079, 0.027), Vp(0.07, 0.54, 1.38), rgb(255, 112, 44), Mat.Neon, 0, 0, -6)
	detailProp(m, "Clef d’arc taillée", Vp(0.43, 0.48, 0.38), Vp(0.024, 1.78, 1.26), rgb(201,126,83), Mat.Brick, Vp(0, 0, -4), "Wedge")
	detailProp(m, "Brique réfractaire", Vp(0.46, 0.24, 0.17), Vp(-0.62, 0.54, 1.32), rgb(137,70,48), Mat.Brick, Vp(0, 0, 3))
	detailProp(m, "Scorie de seuil", Vp(0.40, 0.14, 0.33), Vp(0.36, 0.39, 1.21), rgb(61,42,36), Mat.Brick, Vp(4, 7, -7))
	detailProp(m, "Soubassement ébréché", Vp(0.73, 0.17, 0.51), Vp(-1.25, 0.27, 1.14), rgb(166,113,82), Mat.Brick, Vp(0, 4, 6), "Wedge")
	detailProp(m, "Joint noirci", Vp(0.86, 0.25, 0.14), Vp(0.16, 1.98, 1.20), rgb(62,54,49), Mat.Brick, Vp(0, 0, -5))
	detailProp(m, "Langue de suie", Vp(0.36, 0.46, 0.12), Vp(0.40, 2.13, 1.18), rgb(85,69,61), Mat.Brick, Vp(0, 0, 10), "Wedge")
	detailProp(m, "Ressaut du conduit", Vp(1.04, 0.16, 1.06), Vp(0.67, 4.49, -0.56), rgb(112,83,70), Mat.Brick, Vp(0, -3, 2))
	detailProp(m, "Dépôt de suie sous chapeau", Vp(0.47, 0.37, 0.12), Vp(0.82, 5.02, -0.045), rgb(65,58,55), Mat.Brick, Vp(0, 0, 6))
	detailProp(m, "Gueule du registre", Vp(0.69, 0.44, 0.16), Vp(0.12, 2.53, 1.32), FER, Mat.Metal, Vp(0, 0, 2))
	detailProp(m, "Poignée du registre", Vp(0.29, 0.12, 0.16), Vp(0.18, 2.57, 1.42), rgb(146,117,87), Mat.Metal, Vp(0, 0, 6))
	detailProp(m, "Veine de braise dans la scorie", Vp(0.34, 0.077, 0.095), Vp(0.39, 0.463, 1.35), rgb(255,113,42), Mat.Neon, Vp(0, 0, -5))
	detailProp(m, "Éclat dans la scorie", Vp(0.17, 0.11, 0.12), Vp(-0.24, 0.51, 1.27), rgb(255,166,58), Mat.Neon, Vp(5, 0, -6))
	detailProp(m, "Tison au fond du foyer", Vp(0.26, 0.16, 0.18), Vp(-0.35, 0.73, 1.05), rgb(255,102,29), Mat.Neon, Vp(0, 5, 6))
	fini(m)
end

function PROPS_VALDOR.Metier_Tisser()
	local m = nouveau("Metier_Tisser")
	for _, x in { -1.48, 1.48 } do
		P(m, "Patin", Vp(0.33, 0.24, 3.18), Vp(x, 0.12, 0.38), BOIS_FONCE, Mat.Wood)
		P(m, "Montant", Vp(0.29, 3.82, 0.28), Vp(x, 2.05, -0.79), BOIS, Mat.Wood)
		P(m, "Montant", Vp(0.29, 2.25, 0.27), Vp(x, 1.27, 0.78), BOIS, Mat.Wood)
		P(m, "Longeron", Vp(0.23, 0.29, 1.89), Vp(x, 2.23, 0), BOIS_FONCE, Mat.Wood)
		lienProp(m, "Écharpe", Vp(x, 0.21, 0.70), Vp(x, 2.29, -0.73), 0.17, 0.17, BOIS_FONCE, Mat.Wood, false)
	end
	local haut, bas = Vp(0, 3.73, -0.79), Vp(0, 2.24, 0.78)
	for _, a in { haut, bas } do cylProp(m, "Ensouple", 0.38, 3.32, a, BOIS_FONCE, Mat.Wood, CFrame.identity) end
	for i = -6, 6 do
		local dx = Vp(i * 0.195, 0.13, 0)
		lienProp(m, "Fil de chaîne", haut + dx, bas + dx, 0.037, 0.042, LIN, Mat.Fabric, false)
	end
	local rot = CFrame.Angles(math.atan(1.49 / 1.57), 0, 0)
	P(m, "Toile", Vp(2.61, 0.085, 1.19), Vp(0, 2.75, 0.40), GARANCE, Mat.Fabric, { collide = false, rot = rot })
	P(m, "Galon", Vp(2.61, 0.09, 0.13), Vp(0, 2.54, 0.62), OR, Mat.Fabric, { collide = false, rot = rot })
	P(m, "Navette", Vp(0.83, 0.16, 0.16), Vp(0.38, 2.84, 0.4), BOIS_CLAIR, Mat.Wood, { collide = false })
	for _, x in { -1.06, 1.06 } do
		P(m, "PiedBanc", Vp(0.24, 1.18, 0.29), Vp(x, 0.59, 1.75), BOIS, Mat.Wood)
	end
	P(m, "Banc", Vp(2.42, 0.21, 0.81), Vp(0, 1.23, 1.78), BOIS_CLAIR, Mat.WoodPlanks)
	P(m, "Entretoise", Vp(2.17, 0.16, 0.18), Vp(0, 0.62, 1.76), BOIS_FONCE, Mat.Wood)
	for i, x in { -1.51, 1.44 } do
		local signe = math.sign(x)
		cylProp(m, "Joue du rouleau", 0.52, 0.17, haut + Vp(x, 0, 0), BOIS_CLAIR, Mat.Wood, CFrame.identity, false)
		cylProp(m, "Bobine de trame", 0.44, 0.48, bas + Vp(x, 0, 0), i == 1 and GARANCE or LIN, Mat.Fabric, CFrame.identity, false)
		cylProp(m, "Collerette de bobine", 0.49, 0.07, bas + Vp(x - signe * 0.19, 0, 0), BOIS_CLAIR, Mat.Wood, CFrame.identity, false)
		lienProp(m, "Bord tissé clair", Vp(x - signe * 0.28, 3.21, -0.10), Vp(x - signe * 0.28, 2.45, 0.82),
			0.095, 0.06, LIN, Mat.Fabric, false)
	end
	for i, x in { -0.82, -0.31, 0.25, 0.79 } do
		reliefProp(m, "Motif en losange tissé", Vp(0.27, 0.065, 0.29), Vp(x, 2.76 + i * 0.01, 0.45),
			i % 2 == 0 and OR_PALE or rgb(202, 112, 71), Mat.Fabric, 45, 0, 43)
		lienProp(m, "Trame libre", Vp(x, 2.50, 0.68), Vp(x + 0.06, 2.37 - i * 0.018, 0.90),
			0.080, 0.047, i == 2 and OR or LIN, Mat.Fabric, false)
	end
	detailProp(m, "Galon indigo pris dans la chaîne", Vp(2.54, 0.105, 0.18), Vp(0.01, 2.86, 0.34), rgb(51,83,104), Mat.Fabric, Vp(43, 0, 2))
	detailProp(m, "Crête de toile tissée", Vp(2.49, 0.11, 0.16), Vp(-0.01, 2.73, 0.48), rgb(190,77,61), Mat.Fabric, Vp(43, 0, -3))
	detailProp(m, "Lisière écrue", Vp(2.42, 0.12, 0.15), Vp(0.04, 2.64, 0.58), LIN, Mat.Fabric, Vp(43, 0, 3))
	detailProp(m, "Repli d’étoffe", Vp(1.34, 0.29, 0.15), Vp(0.32, 2.16, 0.96), GARANCE, Mat.Fabric, Vp(-6, 0, -4))
	detailProp(m, "Ourlet déchiré", Vp(0.48, 0.19, 0.12), Vp(0.68, 2.02, 0.99), rgb(104,41,42), Mat.Fabric, Vp(4, 0, -7), "Wedge")
	detailProp(m, "Bobine de garance", Vp(0.37, 0.24, 0.30), Vp(-0.76, 1.46, 1.75), GARANCE, Mat.Fabric, Vp(2, 6, 0))
	detailProp(m, "Bobine de lin", Vp(0.33, 0.19, 0.26), Vp(-0.48, 1.43, 1.89), LIN, Mat.Fabric, Vp(0, 18, -4))
	detailProp(m, "Pédale", Vp(1.14, 0.14, 0.58), Vp(0.29, 0.28, 0.88), BOIS_CLAIR, Mat.Wood, Vp(-13, -4, 2))
	detailProp(m, "Palonnier", Vp(0.17, 1.26, 0.19), Vp(0.82, 0.88, 0.53), BOIS, Mat.Wood, Vp(-11, 0, 5))
	detailProp(m, "Clavette d’ensouple", Vp(0.18, 0.56, 0.15), Vp(1.55, 3.75, -0.78), BOIS_CLAIR, Mat.Wood, Vp(5, 0, -6))
	detailProp(m, "Butée basse", Vp(0.45, 0.34, 0.52), Vp(1.42, 0.24, 1.68), BOIS, Mat.Wood)
	fini(m)
end

function PROPS_VALDOR.Bac_Tannage()
	local m = nouveau("Bac_Tannage")
	P(m, "Semelle", Vp(3.82, 0.22, 0.36), Vp(-0.18, 0.11, 0), BOIS_FONCE, Mat.Wood)
	cylProp(m, "Cuve", 2.34, 0.46, Vp(-0.87, 0.24, 0), BOIS_FONCE, Mat.Wood)
	for i = 0, 11 do
		local a = i * PASSE / 12
		P(m, "Douelle", Vp(0.65, 1.31, 0.15), Vp(-0.87 + math.sin(a) * 1.19, 0.84, math.cos(a) * 1.19),
			teinteProp(BOIS, i), Mat.WoodPlanks, { rot = CFrame.Angles(0, a, 0) })
	end
	for _, y in { 0.40, 1.32 } do cercleProp(m, "Cercle", Vp(-0.87, y, 0), 1.27, 9, 0.12, FER, Mat.Metal) end
	cylProp(m, "Eau", 2.32, 0.094, Vp(-0.87, 1.24, 0), rgb(110, 78, 44), Mat.Glass, nil, false).Transparency = 0.21
	for _, z in { -0.88, 0.88 } do
		P(m, "Cadre", Vp(0.29, 2.94, 0.28), Vp(1.40, 1.57, z), BOIS_FONCE, Mat.Wood)
		P(m, "Pied", Vp(0.36, 0.25, 0.4), Vp(1.4, 0.125, z), BOIS, Mat.Wood)
		for _, y in { 1.12, 2.52 } do
			lienProp(m, "Ligature", Vp(1.45, y, z), Vp(1.45, y - 0.1, z * 0.68), 0.065, 0.065, LIN, Mat.Fabric, false)
		end
	end
	for _, y in { 0.44, 2.95 } do P(m, "Traverse", Vp(0.23, 0.21, 2.08), Vp(1.4, y, 0), BOIS, Mat.Wood) end
	for i = 0, 2 do
		P(m, "Peau", Vp(0.1, 2.27 - i % 2 * 0.1, 0.51), Vp(1.45, 1.60, (i - 1) * 0.45),
			rgb(174 - i * 7, 121 - i * 4, 78), Mat.Fabric, { collide = false })
	end
	P(m, "Racloir", Vp(0.78, 0.11, 0.25), Vp(-0.82, 1.51, 1.18), FER, Mat.Metal, { collide = false })
	P(m, "Poignée", Vp(0.25, 0.17, 0.19), Vp(-1.30, 1.52, 1.18), BOIS_CLAIR, Mat.Wood, { collide = false })
	reliefProp(m, "Échine du cuir", Vp(0.28, 0.22, 1.50), Vp(1.43, 2.85, -0.025), rgb(203, 153, 99), Mat.Fabric, 4)
	for i, profil in { { -0.48, 0.65, 0.45 }, { -0.08, 0.50, 0.36 }, { 0.36, 0.76, 0.52 } } do
		reliefProp(m, "Retombée du cuir tanné", Vp(0.17, profil[3], 0.45), Vp(1.53, profil[2], profil[1]),
			i == 2 and rgb(117, 68, 44) or rgb(191, 128, 79), Mat.Fabric, i * 4 - 9, 0, 4)
	end
	for i, p in { Vp(-1.53, 1.305, 0.39), Vp(-1.15, 1.307, 0.64), Vp(-0.42, 1.307, 0.57) } do
		reliefProp(m, "Écume du bain", Vp(0.32 + i * 0.067, 0.028, 0.13), p, rgb(173, 137, 82), Mat.Glass, 0, -24 + i * 11, 0, "Ball")
	end
	for _, p in { Vp(-1.23, 0.43, 1.22), Vp(-0.72, 1.33, 1.24) } do
		reliefProp(m, "Agrafe oxydée", Vp(0.34, 0.18, 0.11), p, LAITON, Mat.Metal, -5, 0, 5)
	end
	detailProp(m, "Douelle humide", Vp(0.35, 0.55, 0.08), Vp(-1.16, 0.88, 1.19), BOIS_FONCE, Mat.Wood, Vp(0, -9, 5))
	detailProp(m, "Cale du baquet", Vp(0.52, 0.26, 0.54), Vp(-1.39, 0.21, 0.87), BOIS_CLAIR, Mat.Wood, Vp(0, -7, 3), "Wedge")
	fini(m)
end

function PROPS_VALDOR.Alambic()
	local m = nouveau("Alambic")
	local cuivre = rgb(173, 104, 62)
	P(m, "Socle", Vp(3.66, 0.30, 2.15), Vp(0.71, 0.15, 0), BOIS_FONCE, Mat.Wood)
	pierreRonde(m, "Foyer", Vp(0, 0.59, 0), 0.83, 7, 0.68, 0.48, 0.15)
	lumiereProp(m, "Braise", Vp(0, 0.88, 0), Vp(0.97, 0.24, 0.97), 8, 0.8)
	P(m, "Chaudiere", Vp(1.85, 1.63, 1.85), Vp(0, 1.73, 0), cuivre, Mat.Metal, { forme = "Ball" })
	cylProp(m, "Cerclage", 1.72, 0.11, Vp(0, 1.99, 0), rgb(115, 69, 48), Mat.Metal, nil, false)
	cylProp(m, "Chapiteau", 0.89, 0.24, Vp(0, 2.45, 0), cuivre, Mat.Metal)
	P(m, "Chapiteau", Vp(0.73, 0.58, 0.73), Vp(0, 2.72, 0), cuivre, Mat.Metal, { forme = "Ball" })
	local a, b, c, d = Vp(0.18, 2.85, 0), Vp(0.65, 3.28, 0), Vp(1.45, 3.43, 0), Vp(1.91, 3.12, 0)
	lienProp(m, "Col", a, b, 0.20, 0.20, cuivre, Mat.Metal, false)
	lienProp(m, "Col", b, c, 0.19, 0.19, cuivre, Mat.Metal, false)
	lienProp(m, "Col", c, d, 0.19, 0.19, cuivre, Mat.Metal, false)
	lienProp(m, "Tuyau", d, Vp(1.91, 1.86, 0), 0.17, 0.18, cuivre, Mat.Metal, false)
	cylProp(m, "Support", 0.91, 1.51, Vp(1.91, 1.02, 0), BOIS, Mat.Wood)
	for i = 0, 5 do
		cylProp(m, "Serpentin", 0.96, 0.085, Vp(1.91, 1.10 + i * 0.14, 0), cuivre, Mat.Metal, nil, false)
	end
	lienProp(m, "Bec", Vp(1.91, 1.17, 0.35), Vp(1.91, 1.02, 0.72), 0.16, 0.16, cuivre, Mat.Metal, false)
	P(m, "Fiole", Vp(0.47, 0.54, 0.47), Vp(1.91, 0.59, 0.71), rgb(131, 166, 131), Mat.Glass,
		{ forme = "Ball", collide = false, transp = 0.28 })
	cylProp(m, "Col de fiole", 0.24, 0.18, Vp(1.91, 0.9, 0.71), rgb(131, 166, 131), Mat.Glass, nil, false)
	local vert = rgb(90, 127, 107)
	local clair = rgb(215, 149, 89)
	cylProp(m, "Pied de chaudière", 1.22, 0.27, Vp(0, 1.01, 0), rgb(105, 61, 46), Mat.Metal, nil, false)
	cylProp(m, "Bague haute du chapiteau", 0.82, 0.075, Vp(0, 2.55, 0), clair, Mat.Metal, nil, false)
	for i, p in { a, b, c, d } do
		reliefProp(m, "Manchon de cuivre réparé", Vp(0.28, 0.26, 0.29), p, i == 3 and vert or clair, Mat.Metal, 0, 0, i * 3 - 8)
	end
	for i, p in { Vp(-0.48, 1.99, 0.65), Vp(-0.25, 1.93, 0.82), Vp(0.05, 1.82, 0.915),
		Vp(-0.35, 1.66, 0.83), Vp(-0.61, 1.82, 0.65) } do
		reliefProp(m, "Vert-de-gris écaillé", Vp(0.37 - i * 0.026, 0.25, 0.085), p,
			i % 2 == 0 and rgb(132, 158, 123) or vert, Mat.Metal, i * 3 - 9, 15 - i * 9, 5, "Ball")
	end
	cylProp(m, "Liqueur de la fiole", 0.37, 0.15, Vp(1.91, 0.55, 0.71), rgb(116, 160, 64), Mat.Glass, nil, false)
	reliefProp(m, "Bouchon de liège", Vp(0.23, 0.14, 0.23), Vp(1.91, 1.04, 0.71), BOIS_CLAIR, Mat.Wood, 5, 0, -5)
	detailProp(m, "Bague haute de chaudière", Vp(0.96, 0.18, 0.98), Vp(0, 2.42, 0.02), rgb(121,68,46), Mat.Metal, Vp(4, 0, 1))
	detailProp(m, "Brasure de chaudière", Vp(1.12, 0.16, 0.15), Vp(-0.09, 1.94, 0.84), rgb(212,136,76), Mat.Metal, Vp(0, 0, -3))
	detailProp(m, "Vert-de-gris sur la brasure", Vp(0.58, 0.20, 0.15), Vp(0.24, 1.93, 0.85), rgb(67,133,110), Mat.Metal, Vp(0, -8, -4))
	detailProp(m, "Coulée de vert-de-gris", Vp(0.30, 0.45, 0.10), Vp(0.41, 1.74, 0.81), rgb(74,114,94), Mat.Metal, Vp(4, -11, -7), "Wedge")
	detailProp(m, "Perle cuivrée", Vp(0.43, 0.24, 0.11), Vp(-0.39, 1.82, 0.81), rgb(220,144,83), Mat.Metal, Vp(0, -9, 6))
	detailProp(m, "Raccord carré", Vp(0.33, 0.31, 0.33), Vp(0.65, 3.25, 0), rgb(226,153,86), Mat.Metal, Vp(0, 0, 26))
	detailProp(m, "Fourreau de coude", Vp(0.31, 0.42, 0.34), Vp(1.86, 3.12, 0), rgb(118,74,55), Mat.Metal, Vp(0, 5, -5))
	detailProp(m, "Robinet coudé", Vp(0.14, 0.26, 0.31), Vp(1.90, 0.96, 0.59), rgb(224,149,77), Mat.Metal, Vp(20, 0, 0))
	detailProp(m, "Ailette du robinet", Vp(0.41, 0.11, 0.16), Vp(1.91, 1.18, 0.58), rgb(89,133,107), Mat.Metal, Vp(0, 14, -5))
	detailProp(m, "Patte de serpentin", Vp(0.16, 0.51, 0.17), Vp(2.23, 1.40, 0.28), rgb(108,65,44), Mat.Metal, Vp(4, 0, -4))
	detailProp(m, "Cale fumée", Vp(0.60, 0.19, 0.52), Vp(-0.69, 0.31, 0.75), BOIS, Mat.Wood, Vp(0, 3, 0), "Wedge")
	detailProp(m, "Rehausse du collecteur", Vp(0.72, 0.16, 0.53), Vp(1.94, 0.34, 0.68), BOIS_CLAIR, Mat.Wood, Vp(0, -4, 0))
	detailProp(m, "Distillat dans la fiole", Vp(0.32, 0.23, 0.31), Vp(1.91, 0.48, 0.71), rgb(204,153,63), Mat.Glass, nil, "Ball")
	fini(m)
end

local function augeProp(nom: string, eau: boolean)
	local m = nouveau(nom)
	local niveau, longueur = eau and 0.86 or 1.75, eau and 3.57 or 3.18
	for _, x in { -longueur * 0.4, longueur * 0.4 } do
		P(m, "Patin", Vp(0.35, 0.27, 1.22), Vp(x, 0.135, 0), BOIS_FONCE, Mat.Wood)
		P(m, "Montant", Vp(0.26, niveau, 0.31), Vp(x, niveau / 2, 0), BOIS, Mat.Wood)
	end
	lamesProp(m, "Fond", Vp(longueur, 0.25, 0.88), Vp(0, niveau - 0.1, 0), 3, "Z", BOIS)
	for _, z in { -1, 1 } do
		P(m, "Paroi", Vp(longueur, 0.53, 0.18), Vp(0, niveau + 0.16, z * 0.51), BOIS, Mat.WoodPlanks,
			{ rot = CFrame.Angles(z * 0.25, 0, 0) })
		P(m, "Rebord", Vp(longueur, 0.13, 0.17), Vp(0, niveau + 0.41, z * 0.57), BOIS_FONCE, Mat.Wood)
		for _, x in { -longueur * 0.42, longueur * 0.42 } do rivetProp(m, Vp(x, niveau + 0.25, z * 0.61), 0.11) end
	end
	for _, x in { -longueur * 0.478, longueur * 0.478 } do
		P(m, "Joue", Vp(0.16, 0.49, 1.19), Vp(x, niveau + 0.14, 0), BOIS_CLAIR, Mat.Wood)
	end
	for _, z in { -1, 1 } do
		reliefProp(m, "Lèvre éclaircie par les sabots", Vp(longueur * 0.77, 0.10, 0.14),
			Vp(z * 0.17, niveau + 0.41, z * 0.55), BOIS_CLAIR, Mat.Wood, z * 5)
		for i, x in { -longueur * 0.37, longueur * 0.34 } do
			reliefProp(m, "Bride de l’auge", Vp(0.23, 0.52, 0.09), Vp(x, niveau + 0.15, z * 0.552),
				i == 2 and FER or FER_SOMBRE, Mat.Metal, z * 14, 0, (i - 1.5) * 8)
		end
		reliefProp(m, "Jambe oblique de l’auge", Vp(0.21, niveau * 0.66, 0.20),
			Vp(z * longueur * 0.32, niveau * 0.45, z * 0.13), BOIS_CLAIR, Mat.Wood, z * 6, 0, z * 10)
	end
	if eau then
		P(m, "Eau", Vp(longueur - 0.23, 0.06, 1.0), Vp(0, niveau + 0.22, 0), EAU_PROP, Mat.Glass, { collide = false, transp = 0.23 })
	else
		for i = 0, 4 do
			P(m, "Foin", Vp(0.69, 0.58 + i % 3 * 0.10, 0.91), Vp((i - 2) * 0.55, niveau + 0.45, i % 2 * 0.09),
				teinteProp(CHAUME, i), Mat.Grass, { forme = "Ball", collide = false })
		end
	end
	for i, x in { -0.77, -0.16, 0.48 } do
		if eau then
			reliefProp(m, "Ride claire de l’eau", Vp(0.38 + i * 0.07, 0.022, 0.085),
				Vp(x, niveau + 0.263, i * 0.17 - 0.36), rgb(128, 177, 174), Mat.Glass, 0, i * 5 - 11)
		else
			lienProp(m, "Paille débordante", Vp(x, niveau + 0.66, 0.28), Vp(x - 0.23 + i * 0.07, niveau + 0.40, 0.58),
				0.12, 0.075, i == 2 and OR_PALE or CHAUME, Mat.Grass, false)
		end
	end
	detailProp(m, "Traverse d’auge à tenons", Vp(longueur * 0.81, 0.18, 0.23), Vp(0, niveau * 0.48, 0), BOIS_FONCE, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Arête de rive polie", Vp(longueur * 0.92, 0.084, 0.09), Vp(0, niveau + 0.432, 0.58), BOIS_CLAIR, Mat.Wood)
	detailProp(m, "Joue éraflée", Vp(longueur * 0.29, 0.15, 0.08), Vp(-longueur * 0.23, niveau + 0.17, 0.582), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -4))
	detailProp(m, "Coup de gouge", Vp(longueur * 0.19, 0.087, 0.067), Vp(longueur * 0.22, niveau + 0.08, 0.566), BOIS_FONCE, Mat.Wood, Vp(0, 0, 6))
	detailProp(m, "Cale trapue", Vp(0.38, 0.33, 0.39), Vp(longueur * 0.34, niveau * 0.75, 0.33), BOIS, Mat.Wood, Vp(-6, 0, 7), "Wedge")
	detailProp(m, "Étrier forgé gauche", Vp(0.19, 0.42, 0.11), Vp(-longueur * 0.39, niveau + 0.14, 0.602), FER, Mat.Metal, Vp(-4, 0, -6))
	detailProp(m, "Étrier forgé droit", Vp(0.19, 0.39, 0.11), Vp(longueur * 0.39, niveau + 0.16, 0.597), FER, Mat.Metal, Vp(4, 0, 4))
	if eau then
		detailProp(m, "Reflet large", Vp(longueur * 0.62, 0.025, 0.15), Vp(-0.11, niveau + 0.264, 0.18), rgb(142,191,193), Mat.Glass, Vp(0, 4, 0))
		detailProp(m, "Reflet rompu", Vp(0.52, 0.03, 0.11), Vp(0.55, niveau + 0.27, 0.30), rgb(178,215,202), Mat.Glass, Vp(0, -7, 0))
		detailProp(m, "Reflet de rive", Vp(0.51, 0.022, 0.19), Vp(-1.11, niveau + 0.263, -0.30), rgb(86,151,154), Mat.Glass, Vp(0, -4, 0))
	else
		detailProp(m, "Paille fraîche débordante", Vp(0.84, 0.27, 0.75), Vp(-0.87, niveau + 0.70, 0.13), rgb(231,183,94), Mat.Grass, Vp(6, -7, -6), "Wedge")
		detailProp(m, "Paille retroussée", Vp(0.64, 0.23, 0.35), Vp(0.42, niveau + 0.64, 0.36), rgb(217,166,70), Mat.Grass, Vp(7, 9, 3), "Wedge")
		detailProp(m, "Paille pincée au rebord", Vp(0.39, 0.19, 0.24), Vp(0.86, niveau + 0.53, 0.50), rgb(145,98,45), Mat.Grass, Vp(-6, -6, -7), "Wedge")
	end
	fini(m)
end

function PROPS_VALDOR.Abreuvoir() augeProp("Abreuvoir", true) end
function PROPS_VALDOR.Mangeoire() augeProp("Mangeoire", false) end


function PROPS_VALDOR.Lit_Joueur()
	local m = nouveau("Lit_Joueur")
	for _, x in { -1.16, 1.16 } do
		for _, z in { -2.29, 2.16 } do
			local h = z < 0 and 1.79 or 0.85
			P(m, "Pied", Vp(0.27, h, 0.31), Vp(x, h / 2, z), BOIS_FONCE, Mat.Wood)
			rivetProp(m, Vp(x, 0.67, z + 0.15), 0.12)
		end
		P(m, "Longeron", Vp(0.21, 0.32, 4.58), Vp(x, 0.59, -0.03), BOIS, Mat.Wood)
	end
	lamesProp(m, "Sommier", Vp(2.58, 0.26, 4.75), Vp(0, 0.77, -0.02), 6, "Z", BOIS)
	lamesProp(m, "Tete", Vp(2.57, 1.02, 0.22), Vp(0, 1.24, -2.30), 5, "X", BOIS)
	P(m, "Traverse", Vp(2.58, 0.19, 0.28), Vp(0, 1.73, -2.3), BOIS_FONCE, Mat.Wood)
	P(m, "Traverse", Vp(2.57, 0.25, 0.26), Vp(0, 0.72, 2.18), BOIS_FONCE, Mat.Wood)
	P(m, "Matelas", Vp(2.31, 0.37, 4.38), Vp(0, 1.08, -0.02), LIN, Mat.Fabric)
	P(m, "Couverture", Vp(2.39, 0.23, 2.75), Vp(0, 1.30, 0.75), GARANCE, Mat.Fabric, { collide = false })
	P(m, "Galon", Vp(2.39, 0.06, 0.15), Vp(0, 1.428, -0.58), OR, Mat.Fabric, { collide = false })
	P(m, "Oreiller", Vp(1.56, 0.38, 0.83), Vp(-0.08, 1.45, -1.61), LIN, Mat.Fabric,
		{ forme = "Ball", collide = false })
	local bordeaux = rgb(101, 41, 42)
	for i, x in { -0.87, -0.34, 0.21, 0.81 } do
		reliefProp(m, "Pli épais du dessus-de-lit", Vp(0.52 + i * 0.026, 0.10, 2.59 - i * 0.063),
			Vp(x, 1.411 + i % 2 * 0.024, 0.76), i % 2 == 0 and GARANCE or rgb(177, 71, 52), Mat.Fabric,
			i * 2 - 5, 2, i * 3 - 7)
		reliefProp(m, "Retombée de couverture", Vp(0.54 + i * 0.04, 0.42 - i * 0.044, 0.15),
			Vp(x, 1.18 + i * 0.018, 2.09), i == 3 and bordeaux or GARANCE, Mat.Fabric, -5, 0, i * 3 - 7)
	end
	reliefProp(m, "Ourlet de lin écru", Vp(2.28, 0.105, 0.26), Vp(-0.02, 1.45, -0.47), LIN, Mat.Fabric, 0, 0, 2)
	reliefProp(m, "Bord roulé", Vp(0.19, 0.15, 2.55), Vp(1.12, 1.40, 0.75), bordeaux, Mat.Fabric, 0, -2, 5)
	for _, x in { -1.16, 1.16 } do
		reliefProp(m, "Pommeau sculpté", Vp(0.33, 0.29, 0.31), Vp(x, 1.77, -2.29), BOIS_CLAIR, Mat.Wood, -5, 0, 5)
	end
	reliefProp(m, "Tête de lit sculptée", Vp(1.68, 0.29, 0.24), Vp(0.025, 1.75, -2.27), BOIS, Mat.Wood, 0, 0, 2)
	reliefProp(m, "Fleur de tête de lit", Vp(0.27, 0.29, 0.08), Vp(0.025, 1.66, -2.11), BOIS_CLAIR, Mat.Wood, 0, 0, 45)
	detailProp(m, "Vallon du couvre-lit", Vp(2.23, 0.10, 1.68), Vp(0, 1.44, 0.49), rgb(171,63,52), Mat.Fabric, Vp(0, 2, 0))
	detailProp(m, "Revers indigo", Vp(2.33, 0.14, 0.48), Vp(-0.01, 1.44, -0.40), rgb(57,84,101), Mat.Fabric, Vp(0, -3, -2))
	detailProp(m, "Liseré écru du revers", Vp(2.13, 0.045, 0.12), Vp(0.047, 1.53, -0.43), LIN, Mat.Fabric, Vp(0, -3, 0))
	detailProp(m, "Pli de couverture", Vp(0.54, 0.27, 0.66), Vp(1.11, 1.24, 0.93), GARANCE, Mat.Fabric, Vp(3, -5, 6), "Wedge")
	detailProp(m, "Pli à contre-jour", Vp(0.39, 0.15, 0.59), Vp(1.12, 1.20, 1.40), rgb(104,47,45), Mat.Fabric, Vp(-3, 7, -5), "Wedge")
	detailProp(m, "Pièce reprise de lin", Vp(0.37, 0.026, 0.43), Vp(0.57, 1.499, 0.79), rgb(215,168,121), Mat.Fabric, Vp(0, -14, 0))
	detailProp(m, "Dos d’oreiller", Vp(1.63, 0.41, 0.81), Vp(-0.08, 1.40, -1.59), rgb(170,157,128), Mat.Fabric, Vp(0, 6, 0), "Ball")
	detailProp(m, "Couture d’oreiller", Vp(1.20, 0.04, 0.10), Vp(-0.12, 1.515, -1.25), rgb(157,125,100), Mat.Fabric, Vp(0, -3, 0))
	detailProp(m, "Corniche de chevet", Vp(2.56, 0.13, 0.28), Vp(0, 1.843, -2.30), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -2))
	detailProp(m, "Panneau sculpté du chevet", Vp(1.60, 0.38, 0.13), Vp(-0.03, 1.47, -2.18), BOIS_FONCE, Mat.Wood, Vp(0, 0, 3))
	detailProp(m, "Pointe sculptée", Vp(0.35, 0.35, 0.09), Vp(-0.05, 1.50, -2.10), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 45))
	detailProp(m, "Parement du pied de lit", Vp(2.36, 0.24, 0.12), Vp(-0.021, 0.74, 2.28), BOIS, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Chant lustré du pied de lit", Vp(1.71, 0.09, 0.095), Vp(0.19, 0.823, 2.32), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -3))
	detailProp(m, "Rebord ébréché", Vp(0.46, 0.13, 0.08), Vp(-0.69, 0.74, 2.32), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 7), "Wedge")
	fini(m)
end

function PROPS_VALDOR.Porte()
	local m = nouveau("Porte")
	lamesProp(m, "Battant", Vp(2.5, 5.5, 0.3), Vp(0, 2.75, 0), 5, "X", BOIS)
	for _, y in { 0.71, 4.62 } do
		P(m, "Traverse", Vp(2.49, 0.23, 0.16), Vp(0, y, -0.11), BOIS_FONCE, Mat.Wood, { collide = false })
		P(m, "Pentures", Vp(0.93, 0.19, 0.06), Vp(-0.77, y, 0.173), FER, Mat.Metal, { collide = false })
		for _, x in { -1.1, -0.53 } do rivetProp(m, Vp(x, y, 0.211), 0.09) end
	end
	lienProp(m, "Écharpe", Vp(-1.02, 0.71, -0.18), Vp(1.05, 4.62, -0.18), 0.20, 0.12, BOIS_FONCE, Mat.Wood, false)
	P(m, "Platine", Vp(0.32, 0.48, 0.10), Vp(0.88, 2.75, 0.17), FER, Mat.Metal, { collide = false })
	cercleProp(m, "Poignee", Vp(0.88, 2.76, 0.24), 0.14, 6, 0.05, FER, Mat.Metal, true)
	for i, y in { 0.71, 4.62 } do
		reliefProp(m, "Penture en pointe", Vp(0.47, 0.22, 0.084), Vp(-0.18, y, 0.172), FER, Mat.Metal, 0, 0, i * 5 - 8, "Wedge")
		reliefProp(m, "Gond de fer", Vp(0.19, 0.48, 0.20), Vp(-1.13, y, 0.162), FER_SOMBRE, Mat.Metal)
		reliefProp(m, "Arête polie de penture", Vp(0.67, 0.065, 0.069), Vp(-0.75, y + 0.073, 0.22), FER_CLAIR, Mat.Metal)
	end
	reliefProp(m, "Bas de porte érodé", Vp(2.34, 0.23, 0.084), Vp(0, 0.36, 0.145), BOIS_FONCE, Mat.Wood, 0, 0, 2)
	for i, p in { Vp(-0.64, 1.30, 0.156), Vp(0.13, 0.75, 0.156), Vp(0.51, 1.04, 0.156) } do
		reliefProp(m, "Veine éclatée du battant", Vp(0.13, 0.78 - i * 0.15, 0.056), p,
			i == 2 and BOIS_CLAIR or BOIS_FONCE, Mat.Wood, 0, 0, 5 - i * 4)
	end
	reliefProp(m, "Bord de platine en laiton", Vp(0.31, 0.11, 0.10), Vp(0.88, 3.01, 0.182), LAITON, Mat.Metal, 0, 0, -4)

	for i, y in { 0.71, 4.62 } do
		detailProp(m, "Queue de penture étirée", Vp(1.19, 0.145, 0.065), Vp(-0.54, y, 0.194), FER, Mat.Metal, Vp(0, 0, i == 1 and 5 or -4))
		detailProp(m, "Lèvre de penture polie", Vp(0.64, 0.057, 0.059), Vp(-0.79, y + 0.057, 0.23), rgb(129, 139, 141), Mat.Metal, Vp(0, 0, i == 1 and 5 or -4))
	end
	detailProp(m, "Succession d’aubier du battant", Vp(0.23, 3.70, 0.061), Vp(-0.30, 2.68, 0.157), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -2))
	detailProp(m, "Éclat d’aubier rompu", Vp(0.16, 0.74, 0.065), Vp(-0.34, 0.90, 0.167), BOIS, Mat.Wood, Vp(0, 0, 6), "Wedge")
	detailProp(m, "Pied noirci", Vp(2.36, 0.28, 0.088), Vp(0, 0.24, 0.139), BOIS_FONCE, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Humidité dans le joint", Vp(0.36, 0.52, 0.068), Vp(0.42, 0.35, 0.157), rgb(105,78,53), Mat.Wood, Vp(0, 0, -5), "Wedge")
	detailProp(m, "Pointe de platine en laiton", Vp(0.21, 0.18, 0.08), Vp(0.88, 2.92, 0.226), rgb(191,145,67), Mat.Metal, Vp(0, 0, 43))
	fini(m)
end

function PROPS_VALDOR.Cloche_Alarme()
	local m = nouveau("Cloche_Alarme")
	P(m, "Socle", Vp(0.70, 0.33, 0.72), Vp(0, 0.165, 0), PIERRE, Mat.Slate)
	P(m, "Poteau", Vp(0.39, 5.31, 0.4), Vp(0, 2.85, 0), BOIS, Mat.Wood)
	P(m, "Potence", Vp(0.33, 0.28, 1.58), Vp(0, 5.37, 0.59), BOIS_FONCE, Mat.Wood)
	lienProp(m, "Jambe de force", Vp(0, 4.46, 0.12), Vp(0, 5.27, 0.82), 0.18, 0.18, BOIS, Mat.Wood, false)
	cylProp(m, "Bélière", 0.25, 0.27, Vp(0, 5.17, 1.21), FER, Mat.Metal, nil, false)
	local bronze = rgb(161, 113, 54)
	for i, profil in { { 4.20, 1.1, 0.17 }, { 4.36, 0.86, 0.23 }, { 4.61, 0.73, 0.31 }, { 4.90, 0.62, 0.29 } } do
		cylProp(m, "Cloche", profil[2], profil[3], Vp(0, profil[1], 1.21), teinteProp(bronze, i), Mat.Metal, nil, false)
	end
	cylProp(m, "Bord", 1.12, 0.08, Vp(0, 4.14, 1.21), OR, Mat.Metal, nil, false)
	cylProp(m, "Battant", 0.10, 0.42, Vp(0, 4.19, 1.21), FER, Mat.Metal, nil, false)
	P(m, "Pommeau", Vp(0.2, 0.22, 0.21), Vp(0, 3.99, 1.21), FER, Mat.Metal, { forme = "Ball", collide = false })
	rivetProp(m, Vp(0, 5.37, 0.23), 0.13)
	cylProp(m, "Bague d’épaule en bronze poli", 0.80, 0.088, Vp(0, 4.57, 1.21), OR_PALE, Mat.Metal, nil, false)
	cylProp(m, "Lèvre sombre de la cloche", 1.09, 0.069, Vp(0, 4.075, 1.21), FER_SOMBRE, Mat.Metal, nil, false)
	reliefProp(m, "Étrier ouvragé de potence", Vp(0.41, 0.31, 0.45), Vp(0, 5.41, 1.22), FER, Mat.Metal, 0, -5, 5)
	lienProp(m, "Corde de sonnerie haute", Vp(0, 4, 1.2), Vp(-0.09, 3.26, 1.13), 0.09, 0.09, LIN, Mat.Fabric, false)
	lienProp(m, "Corde de sonnerie basse", Vp(-0.09, 3.26, 1.13), Vp(0.035, 2.51, 1.13), 0.09, 0.09, LIN, Mat.Fabric, false)
	reliefProp(m, "Nœud de la corde", Vp(0.19, 0.21, 0.18), Vp(0.035, 2.51, 1.13), BOIS_CLAIR, Mat.Fabric, 7, 0, 7, "Ball")
	for i, p in { Vp(-0.22, 4.39, 1.56), Vp(0.02, 4.32, 1.62), Vp(0.17, 4.26, 1.65) } do
		reliefProp(m, "Bronze grignoté de patine", Vp(0.27 - i * 0.055, 0.13, 0.052), p,
			rgb(94, 126, 102), Mat.Metal, -5, i * 13 - 25, 5)
	end
	detailProp(m, "Cordon de bronze clair", Vp(0.83, 0.13, 0.19), Vp(0, 4.38, 1.61), rgb(206,147,71), Mat.Metal, Vp(0, 0, -3))
	detailProp(m, "Patine d’épaule de cloche", Vp(0.31, 0.36, 0.12), Vp(0.16, 4.45, 1.59), rgb(91,109,78), Mat.Metal, Vp(0, 17, 6), "Wedge")
	detailProp(m, "Triangle gravé", Vp(0.27, 0.25, 0.10), Vp(-0.04, 4.58, 1.56), rgb(111,71,47), Mat.Metal, Vp(0, -5, 4), "Wedge")
	detailProp(m, "Corde de tirage", Vp(0.127, 2.01, 0.118), Vp(0.055, 3.01, 1.23), LIN, Mat.Fabric, Vp(0, 0, -3))
	detailProp(m, "Nœud au bout de la corde", Vp(0.22, 0.29, 0.18), Vp(-0.007, 2.00, 1.23), CHAUME, Mat.Fabric, Vp(4, 0, -6), "Ball")
	detailProp(m, "Chapeau de potence", Vp(0.39, 0.15, 0.35), Vp(0, 5.54, 1.05), BOIS_CLAIR, Mat.Wood, Vp(3, 0, -4))
	fini(m)
end

local function cadreTable(m: Model, w: number, d: number, h: number)
	for _, x in { -w / 2 + 0.22, w / 2 - 0.22 } do
		for _, z in { -d / 2 + 0.2, d / 2 - 0.2 } do
			P(m, "Pied", Vp(0.27, h, 0.27), Vp(x, h / 2, z), BOIS_FONCE, Mat.Wood)
		end
		P(m, "Entretoise", Vp(0.23, 0.19, d - 0.20), Vp(x, h * 0.39, 0), BOIS, Mat.Wood)
	end
	for _, z in { -d / 2 + 0.21, d / 2 - 0.21 } do
		P(m, "Ceinture", Vp(w - 0.22, 0.23, 0.17), Vp(0, h - 0.06, z), BOIS_FONCE, Mat.Wood)
	end
end

function PROPS_VALDOR.Table_Bois()
	local m = nouveau("Table_Bois")
	cadreTable(m, 3.38, 2.19, 2.46)
	lamesProp(m, "Plateau", Vp(3.39, 0.29, 2.19), Vp(0, 2.59, 0), 5, "Z", BOIS_CLAIR)
	for _, x in { -1.48, 1.48 } do
		rivetProp(m, Vp(x, 2.40, 0.99), 0.093)
	end
	for i, x in { -1.47, 1.47 } do
		for _, z in { -0.88, 0.89 } do
			reliefProp(m, "Sabot de pied", Vp(0.35, 0.29, 0.35), Vp(x, 0.16, z), BOIS, Mat.Wood, 0, 5 - i * 3, 3)
			lienProp(m, "Console oblique", Vp(x, 1.97, z), Vp(x * 0.68, 2.43, z), 0.18, 0.15, BOIS_CLAIR, Mat.Wood, false)
		end
	end
	reliefProp(m, "Rive claire rabotée", Vp(2.84, 0.105, 0.10), Vp(-0.08, 2.57, 1.047), BOIS_CLAIR, Mat.Wood, 0, 0, 2)
	reliefProp(m, "Veine ouverte du plateau", Vp(1.11, 0.022, 0.084), Vp(-0.44, 2.743, 0.72), BOIS_FONCE, Mat.Wood, 0, -6)
	reliefProp(m, "Incrustation en papillon", Vp(0.25, 0.028, 0.25), Vp(-0.30, 2.753, 0.72), LIN, Mat.Wood, 0, 42)
	detailProp(m, "Face de ceinture évidée", Vp(2.81, 0.14, 0.13), Vp(0.04, 2.43, -0.99), BOIS, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Liston d’alèse", Vp(2.98, 0.12, 0.08), Vp(-0.03, 2.65, 1.052), BOIS, Mat.Wood, Vp(0, 0, -2))
	detailProp(m, "Éclat d’alèse", Vp(0.69, 0.07, 0.076), Vp(0.62, 2.68, 1.052), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 4))
	detailProp(m, "Branche de contreventement", Vp(0.28, 0.78, 0.23), Vp(-1.26, 1.99, 0.78), BOIS, Mat.Wood, Vp(5, 4, -26))
	detailProp(m, "Traverse à mi-bois", Vp(2.90, 0.22, 0.26), Vp(0.042, 0.92, -0.03), BOIS_FONCE, Mat.Wood, Vp(0, 0, -2))
	detailProp(m, "Lit sombre de l’éclisse", Vp(0.57, 0.027, 0.24), Vp(-0.96, 2.743, -0.23), BOIS_FONCE, Mat.Wood, Vp(0, -5, 0))
	detailProp(m, "Aile gauche de l’éclisse", Vp(0.29, 0.036, 0.35), Vp(-1.13, 2.746, -0.25), LIN, Mat.Wood, Vp(0, -7, 0))
	detailProp(m, "Aile droite de l’éclisse", Vp(0.24, 0.037, 0.31), Vp(-0.78, 2.746, -0.21), BOIS_CLAIR, Mat.Wood, Vp(0, 6, 0))
	detailProp(m, "Tache de patine", Vp(0.91, 0.020, 0.19), Vp(0.38, 2.743, 0.36), rgb(185,139,81), Mat.Wood, Vp(0, 5, 0))
	fini(m)
end

function PROPS_VALDOR.Chaise()
	local m = nouveau("Chaise")
	cadreTable(m, 1.58, 1.58, 1.49)
	lamesProp(m, "Assise", Vp(1.59, 0.23, 1.58), Vp(0, 1.59, 0), 4, "X", BOIS_CLAIR)
	for _, x in { -0.59, 0.59 } do
		P(m, "Montant", Vp(0.23, 1.91, 0.23), Vp(x, 2.51, 0.64), BOIS_FONCE, Mat.Wood)
	end
	for _, y in { 2.17, 2.74, 3.27 } do
		P(m, "Dossier", Vp(1.50, 0.22, 0.21), Vp(0, y, 0.64), BOIS, Mat.Wood)
	end
	local assise = rgb(71, 114, 109)
	reliefProp(m, "Coussin de toile", Vp(1.39, 0.20, 1.28), Vp(-0.022, 1.74, -0.055), assise, Mat.Fabric, 0, -4, 2)
	reliefProp(m, "Rabat usé du coussin", Vp(1.11, 0.14, 0.15), Vp(0.065, 1.74, -0.64), LIN, Mat.Fabric, 0, 3, -3)
	reliefProp(m, "Pli du coussin", Vp(0.44, 0.048, 0.66), Vp(-0.27, 1.85, -0.18), rgb(105, 150, 136), Mat.Fabric, 0, -7)
	for _, x in { -0.59, 0.59 } do
		reliefProp(m, "Toupie de dossier", Vp(0.26, 0.28, 0.25), Vp(x, 3.45, 0.64), BOIS_CLAIR, Mat.Wood, 4, 0, x * 9)
		lienProp(m, "Équerre sous l’assise", Vp(x, 1.04, 0.52), Vp(x * 0.52, 1.44, 0.52),
			0.16, 0.17, BOIS, Mat.Wood, false)
	end
	reliefProp(m, "Crête entaillée du dossier", Vp(1.24, 0.12, 0.20), Vp(-0.035, 3.30, 0.59), BOIS_CLAIR, Mat.Wood, 0, 0, -4)
	detailProp(m, "Traverse arc-boutée", Vp(1.25, 0.21, 0.22), Vp(0, 0.58, -0.56), BOIS, Mat.Wood, Vp(0, 0, -3))
	detailProp(m, "Biseau de dossier", Vp(1.39, 0.13, 0.21), Vp(-0.017, 3.39, 0.628), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Mortaise du dossier", Vp(0.68, 0.12, 0.095), Vp(-0.04, 2.74, 0.52), BOIS_FONCE, Mat.Wood, Vp(0, 0, -4))
	detailProp(m, "Pointe du dossier", Vp(0.28, 0.28, 0.10), Vp(-0.04, 2.75, 0.50), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 43))
	detailProp(m, "Reprise sur le barreau", Vp(0.32, 0.11, 0.09), Vp(0.34, 2.19, 0.52), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -5))
	detailProp(m, "Galette d’assise", Vp(1.24, 0.23, 1.16), Vp(0, 1.79, -0.04), rgb(73,112,104), Mat.Fabric, Vp(0, -4, 0), "Ball")
	detailProp(m, "Passepoil tendu", Vp(1.05, 0.09, 0.23), Vp(-0.01, 1.78, -0.54), rgb(185,161,104), Mat.Fabric, Vp(0, -4, 0))
	detailProp(m, "Rapiéçage de l’assise", Vp(0.26, 0.05, 0.29), Vp(-0.29, 1.892, -0.16), rgb(127,154,118), Mat.Fabric, Vp(0, 11, 3))
	fini(m)
end

function PROPS_VALDOR.Banc()
	local m = nouveau("Banc")
	cadreTable(m, 3.98, 1.18, 1.38)
	lamesProp(m, "Assise", Vp(3.99, 0.28, 1.19), Vp(0, 1.49, 0), 3, "Z", BOIS_CLAIR)
	P(m, "Traverse", Vp(3.71, 0.18, 0.23), Vp(0, 0.54, 0), BOIS_FONCE, Mat.Wood)
	for i, x in { -1.75, 1.73 } do
		reliefProp(m, "Contrefort du banc", Vp(0.28, 1.16, 0.31), Vp(x, 0.74, 0.18), BOIS,
			Mat.Wood, i * 6 - 8, 0, x * 4)
		reliefProp(m, "Clavette traversante", Vp(0.33, 0.20, 0.25), Vp(x, 0.55, 0.21), BOIS_CLAIR, Mat.Wood, 0, 0, i * 7 - 9)
	end
	reliefProp(m, "Rive de l’assise polie", Vp(2.84, 0.09, 0.10), Vp(0.24, 1.54, -0.55), LIN, Mat.Wood, 0, 0, 2)
	reliefProp(m, "Éclisse sombre du siège", Vp(0.82, 0.025, 0.09), Vp(-1.16, 1.642, 0.31), BOIS_FONCE, Mat.Wood, 0, 6)
	reliefProp(m, "Réparation en bois clair", Vp(0.30, 0.032, 0.24), Vp(-1.1, 1.651, 0.30), BOIS_CLAIR, Mat.Wood, 0, 43)
	detailProp(m, "Semelle de pied", Vp(0.36, 0.16, 0.26), Vp(-1.75, 0.10, 0.43), BOIS, Mat.Wood, Vp(0, 4, -5))
	detailProp(m, "Jambe de force gauche", Vp(0.24, 0.69, 0.29), Vp(-1.48, 0.99, 0.34), BOIS, Mat.Wood, Vp(4, 0, -33))
	detailProp(m, "Jambe de force droite", Vp(0.24, 0.69, 0.29), Vp(1.47, 0.97, 0.36), BOIS, Mat.Wood, Vp(-3, 0, 36))
	detailProp(m, "Tenon exposé", Vp(0.27, 0.16, 0.20), Vp(-1.61, 0.56, 0.49), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 5))
	detailProp(m, "Arête d’assise satinée", Vp(3.56, 0.083, 0.08), Vp(0.04, 1.59, 0.55), rgb(193,144,86), Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Fente dans le chant", Vp(0.63, 0.066, 0.05), Vp(0.89, 1.46, 0.571), BOIS_FONCE, Mat.Wood, Vp(0, 0, -5))
	detailProp(m, "Éclat de chant", Vp(0.54, 0.079, 0.05), Vp(-0.65, 1.56, 0.575), BOIS, Mat.Wood, Vp(0, 0, 6))
	fini(m)
end

function PROPS_VALDOR.Tapis()
	local m = nouveau("Tapis")
	P(m, "Trame", Vp(3.56, 0.08, 3.44), Vp(0, 0.04, 0), GARANCE, Mat.Fabric, { collide = false })
	for _, z in { -1.53, 1.53 } do
		P(m, "Galon", Vp(3.42, 0.028, 0.14), Vp(0, 0.08, z), OR, Mat.Fabric, { collide = false })
		for i = -3, 3 do
			P(m, "Frange", Vp(0.09, 0.033, 0.18), Vp(i * 0.48, 0.048, z * 1.12), LIN, Mat.Fabric, { collide = false })
		end
	end
	for _, x in { -1.62, 1.62 } do
		P(m, "Galon", Vp(0.13, 0.028, 3.10), Vp(x, 0.08, 0), OR, Mat.Fabric, { collide = false })
	end
	for _, profil in { { 1.31, 0.092, OR }, { 0.91, 0.108, GARANCE }, { 0.48, 0.122, LIN } } do
		P(m, "Médaillon", Vp(profil[1], 0.024, profil[1]), Vp(0, profil[2], 0), profil[3], Mat.Fabric,
			{ rot = CFrame.Angles(0, math.pi / 4, 0), collide = false })
	end
	local bordeaux = rgb(103, 43, 45)
	for _, z in { -0.96, 0.94 } do
		reliefProp(m, "Champ tissé en gradin", Vp(2.72, 0.026, 0.60), Vp(0, 0.088, z), bordeaux, Mat.Fabric, 0, z * 3)
		for i, x in { -0.88, 0.09, 0.96 } do
			reliefProp(m, "Losange en laine", Vp(0.41, 0.029, 0.41), Vp(x, 0.112, z), i == 2 and LIN or OR_PALE,
				Mat.Fabric, 0, 41 + i * 2)
		end
	end
	for _, x in { -1.25, 1.27 } do
		reliefProp(m, "Contregalon interrompu", Vp(0.12, 0.031, 0.78), Vp(x, 0.113, 0.10), OR, Mat.Fabric, 0, x * 3)
	end
	reliefProp(m, "Coin replié", Vp(0.38, 0.08, 0.40), Vp(1.53, 0.081, -1.47), LIN, Mat.Fabric, -5, 8, -6, "Wedge")
	reliefProp(m, "Usure du coin", Vp(0.32, 0.034, 0.28), Vp(1.32, 0.102, -1.39), rgb(190, 111, 73), Mat.Fabric, 0, 6)
	detailProp(m, "Champ indigo", Vp(2.89, 0.022, 2.69), Vp(0, 0.071, 0), rgb(53,72,89), Mat.Fabric)
	detailProp(m, "Fil tiré sur la rive", Vp(0.34, 0.026, 0.22), Vp(1.52, 0.09, 1.31), rgb(207,165,105), Mat.Fabric, Vp(0, 17, 3), "Wedge")
	detailProp(m, "Trame usée", Vp(0.46, 0.027, 0.21), Vp(1.26, 0.087, 1.32), rgb(106,78,68), Mat.Fabric, Vp(0, -8, -2))
	detailProp(m, "Extrémité rabattue", Vp(0.29, 0.032, 0.53), Vp(-1.63, 0.066, -1.37), rgb(111,53,53), Mat.Fabric, Vp(0, 3, -6), "Wedge")
	for _, x in { -0.99, 0.99 } do
		for _, z in { -0.92, 0.92 } do
			detailProp(m, "Losange d’angle", Vp(0.43, 0.026, 0.43), Vp(x, 0.096, z), OR, Mat.Fabric, Vp(0, 45, 0))
			detailProp(m, "Œil écru du losange", Vp(0.21, 0.025, 0.21), Vp(x + 0.018, 0.116, z), LIN, Mat.Fabric, Vp(0, 44, 0))
		end
	end
	fini(m)
end

function PROPS_VALDOR.Pot_Fleurs()
	local m = nouveau("Pot_Fleurs")
	local terreCuite = rgb(174, 94, 57)
	for i, profil in { { 0.075, 0.92, 0.15 }, { 0.25, 1.02, 0.23 }, { 0.51, 1.09, 0.31 }, { 0.79, 1.15, 0.27 } } do
		cylProp(m, "Pot", profil[2], profil[3], Vp(0, profil[1], 0), teinteProp(terreCuite, i), Mat.CeramicTiles)
	end
	cercleProp(m, "Rebord", Vp(0, 0.92, 0), 0.53, 9, 0.15, terreCuite, Mat.CeramicTiles)
	cylProp(m, "Terre", 1.02, 0.09, Vp(0, 0.88, 0), BOIS_FONCE, Mat.Ground, nil, false)
	for i, c in { GARANCE, CHAUME, rgb(139, 102, 149) } do
		local x, z = (i - 2) * 0.25, i % 2 * 0.30 - 0.16
		local h = Vp(x * 1.46, 1.48 + i % 2 * 0.18, z)
		lienProp(m, "Tige", Vp(x, 0.87, z), h, 0.074, 0.073, rgb(79, 117, 65), Mat.Grass, false)
		P(m, "Feuille", Vp(0.33, 0.12, 0.17), Vp(x - 0.09, 1.15, z), rgb(93, 125, 65), Mat.Grass,
			{ forme = "Ball", collide = false })
		detailProp(m, "Cœur de fleur", Vp(0.21, 0.11, 0.21), h + Vp(0, 0.1, 0), OR, Mat.Fabric)
		for j = 0, 2 do
			local a = j * PASSE / 3
			P(m, "Fleur", Vp(0.23, 0.18, 0.22), h + Vp(math.cos(a) * 0.1, 0, math.sin(a) * 0.1),
				c, Mat.Fabric, { forme = "Ball", collide = false })
		end
	end
	cylProp(m, "Filet d’émail sombre", 1.11, 0.10, Vp(0, 0.57, 0), rgb(98, 57, 51), Mat.CeramicTiles, nil, false)
	cylProp(m, "Collerette émaillée claire", 1.16, 0.092, Vp(0, 0.70, 0), rgb(205, 150, 95), Mat.CeramicTiles, nil, false)
	for i, p in { Vp(-0.24, 0.62, 0.51), Vp(0.12, 0.50, 0.54), Vp(0.38, 0.65, 0.39), Vp(0.27, 0.77, 0.461) } do
		reliefProp(m, "Émail écaillé", Vp(0.20, 0.25 - i * 0.034, 0.049), p,
			i % 2 == 0 and terreCuite or LIN, Mat.CeramicTiles, -5, (i - 2) * 23, 15 + i * 5)
	end
	for i, p in { Vp(-0.365, 1.639, 0.14), Vp(0, 1.48, -0.16), Vp(0.365, 1.640, 0.14) } do
		reliefProp(m, "Cœur de fleur en relief", Vp(0.19, 0.19, 0.21), p + Vp(0, 0.081, 0.04),
			i == 2 and LAITON or OR_PALE, Mat.Fabric, 6, 0, i * 4, "Ball")
		lienProp(m, "Feuille retournée", p - Vp(0, 0.33, 0), p - Vp(i * 0.13 - 0.25, 0.16, 0.20),
			0.16, 0.07, MOUSSE_CLAIRE, Mat.Grass, false)
	end
	detailProp(m, "Émail bleu effacé", Vp(0.77, 0.20, 0.19), Vp(-0.05, 0.60, 0.474), rgb(64,122,127), Mat.CeramicTiles, Vp(0, -3, -4))
	detailProp(m, "Dent d’émail bleu", Vp(0.25, 0.23, 0.12), Vp(0.17, 0.51, 0.505), rgb(61,99,111), Mat.CeramicTiles, Vp(0, 10, 7), "Wedge")
	detailProp(m, "Aile d’émail bleu", Vp(0.30, 0.12, 0.11), Vp(-0.35, 0.55, 0.402), rgb(86,145,142), Mat.CeramicTiles, Vp(0, -27, 5))
	detailProp(m, "Lèvre ébréchée", Vp(0.31, 0.085, 0.15), Vp(0.25, 0.975, 0.48), rgb(205,130,82), Mat.CeramicTiles, Vp(-4, -21, -4), "Wedge")
	detailProp(m, "Bout de soucoupe polie", Vp(0.54, 0.08, 0.11), Vp(-0.09, 0.13, 0.42), rgb(211,145,90), Mat.CeramicTiles, Vp(4, 7, 3))
	detailProp(m, "Joint de soucoupe sombre", Vp(0.59, 0.058, 0.11), Vp(-0.06, 0.075, 0.43), rgb(107,58,48), Mat.CeramicTiles, Vp(4, 4, 2))
	detailProp(m, "Feuille retombante", Vp(0.40, 0.15, 0.22), Vp(-0.34, 1.04, 0.25), rgb(82,120,73), Mat.Grass, Vp(6, 13, -27), "Wedge")
	detailProp(m, "Feuille jeune", Vp(0.30, 0.13, 0.24), Vp(0.31, 1.18, 0.17), rgb(141,159,79), Mat.Grass, Vp(-7, 17, 28), "Wedge")
	detailProp(m, "Bourgeon replié", Vp(0.19, 0.28, 0.18), Vp(0.12, 1.31, 0.39), GARANCE, Mat.Grass, Vp(12, -5, -14), "Ball")
	fini(m)
end

function PROPS_VALDOR.Etagere()
	local m = nouveau("Etagere")
	for _, x in { -1.39, 1.39 } do
		P(m, "Montant", Vp(0.22, 4.39, 0.24), Vp(x, 2.195, 0.49), BOIS_FONCE, Mat.Wood)
		P(m, "Montant", Vp(0.22, 4.39, 0.24), Vp(x, 2.195, -0.39), BOIS, Mat.Wood)
	end
	for i = 0, 3 do
		lamesProp(m, "Rayon", Vp(3.0, 0.18, 1.19), Vp(0, 0.3 + i * 1.27, 0.08), 3, "Z", BOIS_CLAIR)
	end
	P(m, "Fond", Vp(2.74, 4.13, 0.19), Vp(0, 2.20, 0.59), BOIS, Mat.WoodPlanks)
	P(m, "Corniche", Vp(3.04, 0.21, 1.23), Vp(0, 4.31, 0.08), BOIS_FONCE, Mat.Wood)
	local cols = { GARANCE, rgb(56, 86, 145), rgb(86, 113, 59) }
	for i = 0, 7 do
		local h = 0.54 + i % 3 * 0.13
		P(m, "Livre", Vp(0.29, h, 0.68), Vp(-1.19 + i * 0.32, 1.66 + h / 2, 0.04), cols[i % 3 + 1],
			Mat.Fabric, { collide = false })
	end
	reliefProp(m, "Fronton à gradins", Vp(2.47, 0.33, 0.31), Vp(0, 4.34, -0.41), BOIS, Mat.Wood, 0, 0, 2)
	reliefProp(m, "Rive claire du fronton", Vp(2.77, 0.12, 0.29), Vp(0, 4.44, -0.43), BOIS_CLAIR, Mat.Wood)
	for i, y in { 0.31, 1.57, 2.84, 4.10 } do
		reliefProp(m, "Chant de rayon contrasté", Vp(2.75 - i * 0.04, 0.13, 0.12), Vp(i * 0.026, y, -0.50),
			i % 2 == 0 and BOIS or BOIS_CLAIR, Mat.Wood, 0, 0, i * 2 - 4)
	end
	for i, x in { -1.18, -0.53, 0.11, 0.75 } do
		reliefProp(m, "Coiffe de reliure", Vp(0.28, 0.115, 0.062), Vp(x, 2.07 + i % 2 * 0.09, -0.31),
			i % 2 == 0 and LIN or OR, Mat.Fabric, 0, 0, i * 3 - 7)
	end
	reliefProp(m, "Registre couché", Vp(0.98, 0.17, 0.71), Vp(0.71, 3.029, -0.05), GARANCE, Mat.Fabric, 0, 7)
	reliefProp(m, "Tranche du registre", Vp(0.87, 0.11, 0.062), Vp(0.68, 3.035, -0.39), LIN, Mat.Fabric, 0, 7)
	detailProp(m, "Corniche à ressaut", Vp(2.88, 0.12, 0.93), Vp(0.01, 4.445, 0.06), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -2))
	detailProp(m, "Socle mouluré", Vp(2.84, 0.16, 0.18), Vp(0, 0.24, -0.50), BOIS, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Bois nu du socle", Vp(0.76, 0.09, 0.10), Vp(0.53, 0.21, -0.571), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -5))
	detailProp(m, "Rive de rayon patinée", Vp(2.75, 0.12, 0.10), Vp(0, 2.86, -0.49), BOIS_FONCE, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Serre-livres taillé", Vp(0.28, 0.51, 0.71), Vp(1.10, 1.80, 0.026), BOIS_CLAIR, Mat.Wood, Vp(0, 4, 0), "Wedge")
	detailProp(m, "Codex couché", Vp(1.14, 0.21, 0.75), Vp(-0.58, 2.96, -0.02), rgb(53,86,101), Mat.Fabric, Vp(0, 7, -2))
	detailProp(m, "Tranche du codex", Vp(0.98, 0.14, 0.08), Vp(-0.54, 2.96, -0.391), LIN, Mat.Fabric, Vp(0, 7, -2))
	detailProp(m, "Livre incliné", Vp(0.31, 0.77, 0.70), Vp(0.64, 3.33, -0.03), GARANCE, Mat.Fabric, Vp(0, 5, -14))
	detailProp(m, "Tranche dorée", Vp(0.22, 0.62, 0.08), Vp(0.64, 3.36, -0.39), OR, Mat.Fabric, Vp(0, 5, -14))
	detailProp(m, "Boîte à lettres pliées", Vp(0.61, 0.33, 0.61), Vp(0.77, 0.54, 0.02), rgb(83,117,107), Mat.Fabric, Vp(0, -7, -2))
	detailProp(m, "Feuillets de correspondance", Vp(0.53, 0.10, 0.39), Vp(0.79, 0.75, 0.03), LIN, Mat.Fabric, Vp(0, -12, 2))
	fini(m)
end

function PROPS_VALDOR.Etal()
	local m = nouveau("Etal")
	lamesProp(m, "Comptoir", Vp(4.36, 2.33, 1.96), Vp(0, 1.165, 0), 7, "X", BOIS)
	lamesProp(m, "Plateau", Vp(4.45, 0.31, 2.02), Vp(0, 2.45, 0), 4, "Z", BOIS_CLAIR)
	for _, x in { -2.08, 2.08 } do
		P(m, "Montant", Vp(0.28, 5.54, 0.29), Vp(x, 2.77, 0.80), BOIS_FONCE, Mat.Wood)
		lienProp(m, "Jambe de force", Vp(x, 4.76, 0.79), Vp(x, 5.33, -0.87), 0.16, 0.16, BOIS, Mat.Wood, false)
	end
	P(m, "Entrait", Vp(4.42, 0.21, 0.22), Vp(0, 5.51, 0.79), BOIS_FONCE, Mat.Wood)
	P(m, "Tringle", Vp(4.42, 0.17, 0.19), Vp(0, 5.18, -0.92), BOIS_FONCE, Mat.Wood)
	for i = 0, 5 do
		local x, c = (i - 2.5) * 0.747, i % 2 == 0 and GARANCE or LIN
		P(m, "Auvent", Vp(0.75, 0.14, 2.55), Vp(x, 5.46, 0.27), c, Mat.Fabric,
			{ rot = CFrame.Angles(-0.19, 0, 0), collide = false })
		P(m, "Lambrequin", Vp(0.74, 0.27 + i % 2 * 0.043, 0.088), Vp(x, 5.12, -0.98), c, Mat.Fabric, { collide = false })
	end
	P(m, "Caisse", Vp(0.85, 0.29, 0.62), Vp(1.39, 2.73, 0.24), BOIS_FONCE, Mat.Wood)
	for i = 0, 2 do
		P(m, "Pommes", Vp(0.27, 0.29, 0.29), Vp(1.17 + i * 0.22, 2.99, 0.25 + i % 2 * 0.13), GARANCE,
			Mat.Grass, { forme = "Ball", collide = false })
	end
	local rougeFonce = rgb(105, 48, 45)
	for i = 0, 5 do
		local x = (i - 2.5) * 0.747
		local c = i % 2 == 0 and rougeFonce or LIN
		reliefProp(m, "Ourlet d’auvent soulevé", Vp(0.74, 0.087, 0.15), Vp(x, 5.08 - i % 3 * 0.041, -1.01),
			i % 2 == 0 and rgb(198, 83, 58) or rgb(183, 160, 131), Mat.Fabric, -6, 0, i % 3 * 4 - 4)
		reliefProp(m, "Pli du lé", Vp(0.14 + i % 3 * 0.065, 0.085, 1.18), Vp(x + 0.17, 5.47 + i % 2 * 0.032, -0.18),
			c, Mat.Fabric, -11, i % 3 * 4 - 4)
	end
	for _, z in { -0.95, 0.95 } do
		reliefProp(m, "Tablier de comptoir", Vp(4.18, 0.32, 0.13), Vp(0, 1.98, z), BOIS_FONCE, Mat.Wood, 0, 0, 2)
		reliefProp(m, "Traverse claire du comptoir", Vp(4.24, 0.19, 0.13), Vp(0, 0.30, z), BOIS_CLAIR, Mat.Wood, 0, 0, -2)
	end
	reliefProp(m, "Panier de marché tressé", Vp(1.09, 0.36, 0.67), Vp(-1.25, 2.76, -0.24), BOIS, Mat.Wood, 0, -7, 0, "Ball")
	reliefProp(m, "Nappe de comptoir", Vp(1.63, 0.07, 1.18), Vp(-1.28, 2.62, -0.36), GARANCE, Mat.Fabric, 0, -3)
	for i, x in { -1.73, -1.42, -1.08, -0.82 } do
		reliefProp(m, "Pain doré", Vp(0.36, 0.22 + i % 2 * 0.07, 0.52), Vp(x, 2.92, -0.25 + i % 3 * 0.12),
			i % 2 == 0 and CHAUME or OR_PALE, Mat.Sand, -5, i * 13 - 29, 0, "Ball")
	end

	for i = 0, 5 do
		local x = (i - 2.5) * 0.747
		local c = i % 2 == 0 and rgb(187, 83, 67) or rgb(235, 221, 181)
		detailProp(m, "Pli d’auvent éclairé", Vp(0.20, 0.054, 2.31 - i % 3 * 0.14), Vp(x + 0.13, 5.55, 0.23), c, Mat.Fabric, Vp(-11, i % 3 - 2, 0))
		detailProp(m, "Pointe de toile usée", Vp(0.39 + i % 2 * 0.12, 0.15, 0.11), Vp(x - 0.11, 4.99 - i % 3 * 0.057, -0.97),
			i % 2 == 0 and rgb(114, 49, 49) or rgb(178, 151, 121), Mat.Fabric, Vp(0, 0, (i - 3) * 2), "Wedge")
	end
	detailProp(m, "Caisse inclinée d’épices", Vp(0.94, 0.36, 0.66), Vp(-1.16, 2.75, -0.21), BOIS_FONCE, Mat.Wood, Vp(0, 12, -5))
	detailProp(m, "Lèvre de caisse inclinée", Vp(0.86, 0.098, 0.14), Vp(-1.16, 2.95, -0.47), BOIS_CLAIR, Mat.Wood, Vp(0, 12, -5))
	detailProp(m, "Façade de comptoir ferrée", Vp(4.11, 0.17, 0.11), Vp(0, 2.23, 0.973), BOIS_FONCE, Mat.Wood, Vp(0, 0, 2))
	detailProp(m, "Bois mis à nu du comptoir", Vp(0.69, 0.13, 0.11), Vp(0.59, 2.22, 1.020), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -6), "Wedge")
	detailProp(m, "Sac ocre de comptoir", Vp(0.57, 0.50, 0.49), Vp(-1.15, 3.03, -0.18), CHAUME, Mat.Fabric, Vp(3, -7, 6), "Ball")
	detailProp(m, "Sac de lin à la corde", Vp(0.52, 0.43, 0.54), Vp(-0.67, 2.98, -0.10), LIN, Mat.Fabric, Vp(-4, 7, -5), "Ball")
	detailProp(m, "Revers du sac ocre", Vp(0.30, 0.13, 0.37), Vp(-1.14, 3.27, -0.17), BOIS, Mat.Fabric, Vp(-2, 5, 7))
	detailProp(m, "Torchon retombé", Vp(0.64, 0.48, 0.13), Vp(0.64, 2.52, 1.016), rgb(58,104,111), Mat.Fabric, Vp(0, 0, 5))
	detailProp(m, "Rayure écrue du torchon", Vp(0.14, 0.41, 0.07), Vp(0.53, 2.54, 1.087), LIN, Mat.Fabric, Vp(0, 0, 5))
	fini(m)
end

function PROPS_VALDOR.Serrure_Entrainement()
	local m = nouveau("Serrure_Entrainement")
	P(m, "Semelle", Vp(1.60, 0.25, 1.19), Vp(0, 0.125, 0), PIERRE, Mat.Cobblestone)
	lamesProp(m, "Pied", Vp(1.48, 2.36, 1.08), Vp(0, 1.39, 0), 4, "X", BOIS)
	for _, y in { 0.49, 2.42 } do P(m, "Traverse", Vp(1.52, 0.24, 1.15), Vp(0, y, 0), BOIS_FONCE, Mat.Wood) end
	P(m, "Plaque", Vp(1.31, 1.12, 0.13), Vp(0, 2.04, -0.59), FER, Mat.Metal, { collide = false })
	for _, x in { -0.49, 0.49 } do
		for _, y in { 1.66, 2.42 } do rivetProp(m, Vp(x, y, -0.669), 0.13, OR) end
	end
	cylProp(m, "Rosace", 0.52, 0.085, Vp(0, 2.02, -0.664), OR, Mat.Metal, FACE_PROP, false)
	P(m, "Trou", Vp(0.115, 0.27, 0.038), Vp(0, 2.02, -0.714), rgb(38, 35, 31), Mat.Metal, { collide = false })
	reliefProp(m, "Contreplaque de serrure", Vp(1.42, 1.22, 0.10), Vp(0, 2.04, -0.566), FER_SOMBRE, Mat.Metal)
	cylProp(m, "Gorge de l’entrée", 0.25, 0.057, Vp(0, 2.075, -0.734), FER_SOMBRE, Mat.Metal, FACE_PROP, false)
	reliefProp(m, "Épaulement de l’entrée", Vp(0.63, 0.12, 0.10), Vp(0, 1.79, -0.67), LAITON, Mat.Metal, 0, 0, -4)
	for i, p in { Vp(-0.49, 1.38, -0.552), Vp(0.31, 1.61, -0.657), Vp(0.47, 1.56, -0.652) } do
		reliefProp(m, "Trace d’exercice", Vp(0.36 - i * 0.052, 0.062, 0.038), p,
			i % 2 == 0 and FER_CLAIR or BOIS_CLAIR, Mat.Metal, 0, 0, 25 + i * 6)
	end
	reliefProp(m, "Cale usée sur le socle", Vp(0.48, 0.16, 0.33), Vp(-0.43, 0.30, -0.40), BOIS_CLAIR, Mat.Wood, -5, 7, 4)
	detailProp(m, "Glissière du pêne", Vp(0.45, 0.29, 0.16), Vp(0.42, 1.73, -0.68), rgb(116,122,113), Mat.Metal, Vp(0, 0, -4))
	detailProp(m, "Pêne en saillie", Vp(0.46, 0.13, 0.17), Vp(0.44, 1.76, -0.775), rgb(196,139,65), Mat.Metal, Vp(0, 0, -4))
	detailProp(m, "Coin de la rosace écaillé", Vp(0.22, 0.13, 0.08), Vp(-0.22, 2.17, -0.746), rgb(241,178,71), Mat.Metal, Vp(0, 0, 28))
	detailProp(m, "Arrêt de lime sur la plaque", Vp(0.47, 0.073, 0.044), Vp(-0.34, 1.82, -0.678), rgb(173,142,108), Mat.Metal, Vp(0, 0, -19))
	detailProp(m, "Long éclat sous la plaque", Vp(0.19, 0.57, 0.075), Vp(-0.49, 1.20, -0.553), BOIS_CLAIR, Mat.Wood, Vp(0, 0, 5), "Wedge")
	detailProp(m, "Biseau noirci du sabot", Vp(0.81, 0.13, 0.13), Vp(-0.23, 0.37, -0.527), BOIS_FONCE, Mat.Wood, Vp(0, 0, 3))
	fini(m)
end


function PROPS_VALDOR.Moulin()
	local m = nouveau("Moulin")
	cylProp(m, "Soubassement", 5.0, 0.44, Vp(0, 0.22, 0), PIERRE, Mat.Cobblestone)
	for i = 0, 7 do
		cylProp(m, "Assise", 4.98 - i * 0.118, 1.23, Vp(0, 0.91 + i * 1.21, 0),
			i % 3 == 0 and PIERRE_CLAIRE or CALCAIRE, i % 2 == 0 and Mat.Cobblestone or Mat.Slate)
	end
	for i = 0, 5 do
		cylProp(m, "Bardeaux", 5.59 - i * 0.92, 0.41, Vp(0, 10.07 + 0.34 * i, 0),
			teinteProp(rgb(118, 76, 56), i), Mat.WoodPlanks)
	end
	P(m, "Porte", Vp(1.53, 2.57, 0.24), Vp(0, 1.33, -2.37), BOIS, Mat.WoodPlanks)
	for _, x in { -0.86, 0.86 } do
		P(m, "Jambage", Vp(0.24, 2.82, 0.28), Vp(x, 1.41, -2.29), PIERRE, Mat.Slate)
	end
	P(m, "Linteau", Vp(1.93, 0.19, 0.36), Vp(0, 2.74, -2.27), PIERRE_CLAIRE, Mat.Slate)
	P(m, "Axe", Vp(0.52, 0.52, 1.83), Vp(0, 8.5, -2.93), BOIS_FONCE, Mat.Wood)
	local centre = Vp(0, 8.5, -3.77)
	cylProp(m, "Moyeu", 0.71, 0.32, centre, FER, Mat.Metal, FACE_PROP, false)
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		local dir, cote = Vp(math.cos(a), math.sin(a), 0), Vp(-math.sin(a), math.cos(a), 0)
		lienProp(m, "Aile", centre, centre + dir * 5.14, 0.21, 0.23, BOIS_FONCE, Mat.Wood, false)
		lienProp(m, "Longeron", centre + dir * 1.56 + cote * 0.92, centre + dir * 4.92 + cote * 0.92,
			0.13, 0.14, BOIS, Mat.Wood, false)
		for _, dist in { 1.56, 3.25, 4.92 } do
			lienProp(m, "Traverse d’aile", centre + dir * dist, centre + dir * dist + cote * 0.99,
				0.13, 0.14, BOIS, Mat.Wood, false)
		end
		P(m, "Voile", Vp(3.42, 0.89, 0.055), centre + dir * 3.23 + cote * 0.47 + Vp(0, 0, -0.073),
			LIN, Mat.Fabric, { rot = CFrame.Angles(0, 0, a), collide = false })
	end
	for i, profil in { { -0.69, 2.2, 2.16 }, { -0.37, 3.78, 2.24 }, { 0.19, 5.08, 2.20 }, { 0.76, 6.24, 2.10 },
		{ 1.53, 2.9, 2.26 }, { 2.74, 4.08, 2.28 }, { 3.57, 6.55, 2.10 }, { 4.08, 7.78, 2.03 } } do
		local a, y, r = profil[1], profil[2], profil[3]
		local p = Vp(math.sin(a) * r, y, math.cos(a) * r)
		reliefProp(m, "Moellon saillant du fût", Vp(1.15 + i % 3 * 0.15, 0.39, 0.16), p,
			i % 3 == 0 and PIERRE or PIERRE_CLAIRE, Mat.Slate, -3, math.deg(a), i % 3 * 4 - 4)
		reliefProp(m, "Joint arraché", Vp(0.68 + i % 3 * 0.14, 0.12, 0.073), p + Vp(0, -0.22, 0),
			i % 2 == 0 and MOUSSE or FER_SOMBRE, Mat.Slate, 2, math.deg(a), i % 3 * 4 - 4)
	end
	cylProp(m, "Chapeau sombre du sommet", 0.71, 0.22, Vp(0, 11.93, 0), BOIS_FONCE, Mat.Wood, nil, false)
	cylProp(m, "Frette polie du moyeu", 0.58, 0.21, centre - Vp(0, 0, 0.20), LAITON, Mat.Metal, FACE_PROP, false)
	for i = 0, 3 do
		local angle = i * math.pi / 2 + math.pi / 4
		local dir, cote = Vp(math.cos(angle), math.sin(angle), 0), Vp(-math.sin(angle), math.cos(angle), 0)
		local p = centre + dir * (3.9 + i % 2 * 0.18) + cote * 0.47 - Vp(0, 0, 0.104)
		reliefProp(m, "Reprise de toile des ailes", Vp(0.49 + i * 0.047, 0.78, 0.068), p,
			i % 2 == 0 and rgb(179, 148, 106) or rgb(243, 224, 178), Mat.Fabric, 0, 0, math.deg(angle) + i * 3 - 6)
		reliefProp(m, "Bout d’aile ferré", Vp(0.42, 0.28, 0.24), centre + dir * 4.92,
			FER_CLAIR, Mat.Metal, 0, 0, math.deg(angle) - 3)
	end

	for i, a in { 0.31, 0.91, 1.58, 2.26, 3.90, 4.53, 5.56 } do
		local p = Vp(math.sin(a), 0, math.cos(a))
		detailProp(m, "Appareil saillant de la tour", Vp(0.94, 0.47, 0.23), p * (2.36 - i % 3 * 0.07) + Vp(0, 2.89 + i % 3 * 1.13, 0),
			({ PIERRE, PIERRE_CLAIRE, CALCAIRE })[i % 3 + 1], Mat.Slate, Vp(0, math.deg(a), i * 2 - 8))
		detailProp(m, "Joint creux sous la pierre", Vp(0.75, 0.11, 0.17), p * (2.42 - i % 3 * 0.07) + Vp(0, 2.69 + i % 3 * 1.13, 0),
			rgb(103, 102, 93), Mat.Cobblestone, Vp(0, math.deg(a), i * 2 - 8))
	end
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		local dir, cote = Vp(math.cos(a), math.sin(a), 0), Vp(-math.sin(a), math.cos(a), 0)
		local ct = centre + dir * (4.74 + i % 2 * 0.07) + cote * 0.45 + Vp(0, 0, -0.12)
		detailProp(m, "Ourlet de voile déchiré", Vp(0.56, 0.82 - i % 3 * 0.09, 0.065), ct,
			i % 2 == 0 and rgb(167, 144, 106) or rgb(222, 194, 154), Mat.Fabric,
			Vp(0, 0, math.deg(a) + i * 3 - 5), "Wedge")
		detailProp(m, "Rapport de toile", Vp(0.75, 0.35, 0.045), centre + dir * (2.58 + i * 0.24) + cote * 0.59 + Vp(0, 0, -0.115),
			i % 2 == 0 and rgb(174, 71, 57) or rgb(190, 169, 128), Mat.Fabric, Vp(0, 0, math.deg(a) + 4))
	end
	detailProp(m, "Joue de moyeu en bronze", Vp(0.42, 0.44, 0.16), Vp(0, 8.5, -3.956), rgb(188,129,66), Mat.Metal, Vp(0, 0, 43))
	detailProp(m, "Mousse tournée vers le sol", Vp(1.05, 0.22, 0.56), Vp(0.78, 0.49, 2.19), rgb(99,126,72), Mat.Grass, Vp(3, 15, -4))
	detailProp(m, "Pointe de mousse sur l’assise", Vp(0.46, 0.41, 0.33), Vp(1.22, 0.60, 2.02), rgb(73,101,65), Mat.Grass, Vp(0, 23, 4), "Wedge")
	fini(m)
end

function PROPS_VALDOR.Arroseur()
	local m = nouveau("Arroseur")
	P(m, "Semelle", Vp(1.24, 0.18, 1.87), Vp(0, 0.09, 0.48), PIERRE, Mat.Slate)
	cylProp(m, "Pied", 0.47, 0.29, Vp(0, 0.24, 0), FER, Mat.Metal)
	cylProp(m, "Tige", 0.24, 1.24, Vp(0, 0.99, 0), FER, Mat.Metal)
	for i, profil in { { 0.31, 0.98, 0.29 }, { 0.54, 1.21, 0.31 }, { 0.80, 0.99, 0.26 } } do
		cylProp(m, "Reservoir", profil[2], profil[3], Vp(0, profil[1], 0.9), teinteProp(BOIS, i), Mat.WoodPlanks)
	end
	for _, y in { 0.37, 0.72 } do cylProp(m, "Cercle", 1.17, 0.09, Vp(0, y, 0.9), FER, Mat.Metal, nil, false) end
	local cuivre = rgb(156, 106, 62)
	lienProp(m, "Conduite", Vp(0, 0.85, 0.89), Vp(0, 1.23, 0.0), 0.12, 0.12, cuivre, Mat.Metal, false)
	cylProp(m, "Tete", 0.37, 0.25, Vp(0, 1.64, 0), cuivre, Mat.Metal)
	for i = 0, 2 do
		local a = i * PASSE / 3
		local b = Vp(math.cos(a) * 0.52, 1.71, math.sin(a) * 0.52)
		lienProp(m, "Buse", Vp(0, 1.64, 0), b, 0.11, 0.11, cuivre, Mat.Metal, false)
		rivetProp(m, b, 0.15, FER)
	end
	local vert = rgb(85, 130, 104)
	cylProp(m, "Trappe du réservoir", 0.46, 0.12, Vp(-0.13, 0.965, 0.93), LAITON, Mat.Metal, nil, false)
	cylProp(m, "Couronne de vanne", 0.51, 0.10, Vp(0, 1.80, 0), cuivre, Mat.Metal, nil, false)
	cylProp(m, "Creux de la vanne", 0.35, 0.035, Vp(0, 1.865, 0), FER_SOMBRE, Mat.Metal, nil, false)
	for i, p in { Vp(-0.32, 0.65, 1.41), Vp(0.05, 0.54, 1.50), Vp(0.36, 0.68, 1.34) } do
		reliefProp(m, "Traînée humide du réservoir", Vp(0.23, 0.32 - i * 0.022, 0.095), p,
			i % 2 == 0 and vert or BOIS_FONCE, Mat.Wood, -6, i * 29 - 55, i * 4 - 9)
	end
	for _, p in { Vp(0.48, 0.20, 0.79), Vp(-0.36, 0.19, 1.01), Vp(-0.42, 0.18, 0.66) } do
		reliefProp(m, "Mousse sur la semelle humide", Vp(0.28, 0.10, 0.31), p, MOUSSE_CLAIRE, Mat.Grass, 6, -7, 5)
	end
	detailProp(m, "Collecteur cuivré", Vp(0.36, 0.22, 0.35), Vp(0, 1.39, 0), rgb(209,143,75), Mat.Metal, Vp(0, 0, 4))
	detailProp(m, "Levier de pression", Vp(0.12, 0.36, 0.43), Vp(0.084, 0.93, 0.83), rgb(191,130,63), Mat.Metal, Vp(24, 0, -7))
	detailProp(m, "Cache du manomètre", Vp(0.42, 0.32, 0.14), Vp(0, 1.18, 0.414), FER, Mat.Metal, Vp(0, 0, 7))
	detailProp(m, "Face du manomètre", Vp(0.32, 0.22, 0.07), Vp(0, 1.18, 0.497), LIN, Mat.Metal, Vp(0, 0, 7))
	detailProp(m, "Aiguille du manomètre", Vp(0.04, 0.135, 0.028), Vp(0.018, 1.19, 0.539), GARANCE, Mat.Metal, Vp(0, 0, -29))
	detailProp(m, "Galon de vert-de-gris", Vp(0.18, 0.31, 0.10), Vp(0.085, 1.00, 0.605), rgb(80,128,109), Mat.Metal, Vp(10, 0, 6), "Wedge")
	detailProp(m, "Goutte dans la buse", Vp(0.11, 0.14, 0.11), Vp(0.43, 1.62, 0.052), rgb(117,180,187), Mat.Metal, nil, "Ball")
	detailProp(m, "Douelle polie du réservoir", Vp(0.29, 0.41, 0.10), Vp(-0.08, 0.56, 1.47), BOIS_CLAIR, Mat.Wood, Vp(0, 4, -4))
	fini(m)
end

function PROPS_VALDOR.Ruche()
	local m = nouveau("Ruche")
	P(m, "Socle", Vp(1.76, 0.24, 1.74), Vp(0, 0.12, 0), BOIS, Mat.WoodPlanks)
	for i, profil in { { 0.38, 1.49, 0.29 }, { 0.60, 1.76, 0.26 }, { 0.84, 1.81, 0.26 },
		{ 1.07, 1.72, 0.25 }, { 1.29, 1.53, 0.24 }, { 1.5, 1.32, 0.23 }, { 1.69, 1.07, 0.23 },
		{ 1.88, 0.76, 0.2 }, { 2.02, 0.43, 0.14 } } do
		cylProp(m, "Paille", profil[2], profil[3], Vp(0, profil[1], 0), teinteProp(CHAUME, i), Mat.Grass)
	end
	P(m, "Planche d’envol", Vp(0.64, 0.12, 0.34), Vp(0, 0.71, -0.86), BOIS, Mat.Wood)
	P(m, "Trou", Vp(0.36, 0.19, 0.11), Vp(0, 0.83, -0.90), BOIS_FONCE, Mat.Wood, { collide = false })
	reliefProp(m, "Seuil ombré de l’entrée", Vp(0.73, 0.19, 0.33), Vp(0, 0.66, -0.82), BOIS_FONCE, Mat.Wood, 2)
	reliefProp(m, "Encadrement de cire", Vp(0.51, 0.31, 0.095), Vp(0, 0.84, -0.889), LAITON, Mat.Grass, 0, 0, 4)
	for i, p in { Vp(-0.30, 1.82, -0.41), Vp(0.04, 1.86, -0.48), Vp(0.38, 1.73, -0.39), Vp(0.49, 1.48, -0.48) } do
		reliefProp(m, "Tresse de paille défaite", Vp(0.38, 0.19, 0.23), p,
			i % 2 == 0 and OR_PALE or CHAUME, Mat.Grass, -5, i * 9 - 24, i * 4 - 8)
	end
	for i, p in { Vp(0.22, 0.73, -0.88), Vp(0.31, 0.65, -0.91), Vp(0.39, 0.59, -0.87) } do
		reliefProp(m, "Filet de cire ambrée", Vp(0.14 + i * 0.02, 0.13, 0.11), p,
			i == 3 and LAITON or OR, Mat.Glass, 3, 0, -7, "Ball")
	end
	detailProp(m, "Crête de paille blonde", Vp(0.71, 0.115, 0.65), Vp(-0.04, 1.97, 0.073), rgb(236,191,100), Mat.Grass, Vp(4, -7, -3))
	detailProp(m, "Paille déchirée", Vp(0.49, 0.19, 0.28), Vp(-0.44, 1.26, -0.49), rgb(225,178,84), Mat.Grass, Vp(-5, 10, -8), "Wedge")
	detailProp(m, "Anneau ombré de paille", Vp(0.81, 0.10, 0.14), Vp(0.034, 1.0, -0.813), rgb(132,93,49), Mat.Grass, Vp(0, 7, 4))
	detailProp(m, "Linteau d’entrée", Vp(0.56, 0.13, 0.18), Vp(0.014, 0.945, -0.873), BOIS_CLAIR, Mat.Wood, Vp(0, 0, -4))
	detailProp(m, "Lèvre d’envol satinée", Vp(0.54, 0.072, 0.13), Vp(0.014, 0.768, -0.959), BOIS_FONCE, Mat.Wood, Vp(0, 0, 3))
	detailProp(m, "Goutte d’ambre", Vp(0.135, 0.23, 0.11), Vp(0.225, 0.713, -0.964), rgb(234,159,59), Mat.Glass, Vp(0, 0, 6), "Ball")
	fini(m)
end

function PROPS_VALDOR.Caserne()
	local m = nouveau("Caserne")
	P(m, "Socle", Vp(12, 0.88, 10), Vp(0, 0.44, 0), PIERRE, Mat.Cobblestone)
	for i = 0, 4 do
		P(m, "Murs", Vp(11.02, 1.28, 9.02), Vp(0, 1.52 + i * 1.21, 0),
			i % 2 == 0 and CALCAIRE or PIERRE_CLAIRE, i % 2 == 0 and Mat.Cobblestone or Mat.Slate)
	end
	lamesProp(m, "Porte", Vp(2.58, 4.04, 0.18), Vp(0, 2.97, -4.58), 5, "X", BOIS_FONCE)
	for _, y in { 1.99, 4.12 } do P(m, "Pentures", Vp(2.57, 0.22, 0.07), Vp(0, y, -4.69), FER, Mat.Metal, { collide = false }) end
	for _, x in { -1.40, 1.40 } do
		P(m, "Jambage", Vp(0.33, 4.40, 0.41), Vp(x, 2.99, -4.53), PIERRE, Mat.Slate)
	end
	P(m, "Linteau", Vp(3.22, 0.36, 0.47), Vp(0, 5.13, -4.54), PIERRE, Mat.Slate)
	toitureProp(m, 11.94, 9.88, 7.04, 1.23, 0, false)
	for _, x in { -5.48, 5.48 } do
		for _, z in { -4.48, 4.48 } do
			P(m, "Tour", Vp(1.86, 8.18, 1.86), Vp(x, 4.09, z), PIERRE, Mat.Cobblestone)
			P(m, "Corniche", Vp(2.02, 0.28, 2.02), Vp(x, 8.10, z), CALCAIRE, Mat.Slate)
			for _, i in { -1, 1 } do
				for _, j in { -1, 1 } do
					P(m, "Créneau", Vp(0.52, 0.74, 0.52), Vp(x + i * 0.70, 8.56, z + j * 0.70), PIERRE_CLAIRE, Mat.Cobblestone)
				end
			end
		end
	end
	P(m, "Mat", Vp(0.22, 4.54, 0.24), Vp(0, 10.27, 0), BOIS_FONCE, Mat.Wood)
	for i = 0, 3 do
		local h = 1.39 - i * 0.17
		P(m, "Drapeau", Vp(0.13, h, 0.59), Vp(i % 2 * 0.045, 12.33 - h / 2, 0.32 + i * 0.54),
			i % 2 == 0 and GARANCE or GARANCE:Lerp(BOIS_FONCE, 0.11), Mat.Fabric, { collide = false })
	end
	for _, x in { -5.48, 5.48 } do
		for _, z in { -4.48, 4.48 } do
			local f = math.sign(z)
			for i, y in { 1.24, 3.77, 6.14 } do
				reliefProp(m, "Chaîne d’angle de tour", Vp(0.72 - i * 0.071, 0.43, 0.20),
					Vp(x + (i % 2 - 0.5) * 0.37, y, z + f * 0.89), i == 1 and PIERRE or PIERRE_CLAIRE, Mat.Slate, 0, 0, (i - 2) * 3)
			end
			reliefProp(m, "Meurtrière profonde", Vp(0.24, 0.94, 0.081), Vp(x, 5.28, z + f * 0.936), FER_SOMBRE, Mat.Slate)
			reliefProp(m, "Appui de meurtrière", Vp(0.56, 0.16, 0.24), Vp(x, 4.79, z + f * 0.93), CALCAIRE, Mat.Slate, -5)
		end
	end
	for i, x in { -3.89, -3.01, -2.19, 2.12, 2.91, 3.78 } do
		reliefProp(m, "Mousse fragmentée des fondations", Vp(0.94, 0.31 - i % 3 * 0.06, 0.28),
			Vp(x, 0.89 + i % 3 * 0.12, -4.52), i % 2 == 0 and MOUSSE or MOUSSE_CLAIRE, Mat.Grass, 0, 0, i % 3 * 5 - 5)
	end
	reliefProp(m, "Écu de la garnison", Vp(1.30, 1.18, 0.25), Vp(0, 5.85, -4.50), FER_SOMBRE, Mat.Metal, 0, 0, 3)
	reliefProp(m, "Plaque de l’écu", Vp(1.12, 0.99, 0.17), Vp(0, 5.86, -4.65), GARANCE, Mat.Metal, 0, 0, 3)
	reliefProp(m, "Losange doré de l’écu", Vp(0.49, 0.49, 0.093), Vp(0, 5.86, -4.76), OR_PALE, Mat.Metal, 0, 0, 45)
	for _, x in { -1.22, 1.21 } do
		reliefProp(m, "Traverse ferrée du portail", Vp(0.24, 3.68, 0.07), Vp(x, 2.98, -4.68), FER_CLAIR, Mat.Metal, 0, 0, x * 2)
	end

	for i, x in { -4.41, -3.38, -2.49, 2.26, 3.12, 4.37 } do
		local y = 1.36 + (i % 3) * 1.13
		detailProp(m, "Pierre d’appareil de façade", Vp(0.99 + i % 3 * 0.20, 0.47, 0.29), Vp(x, y, -4.52),
			({ PIERRE, PIERRE_CLAIRE, CALCAIRE })[i % 3 + 1], Mat.Slate, Vp(0, 0, i - 4))
		detailProp(m, "Joint en retrait sous le moellon", Vp(0.82 + i % 3 * 0.17, 0.13, 0.19), Vp(x + 0.14, y - 0.25, -4.54),
			rgb(108, 100, 91), Mat.Cobblestone, Vp(0, 0, i - 4))
	end
	for _, x in { -4.74, 4.74 } do
		detailProp(m, "Contrefort en glacis", Vp(0.67, 1.31, 0.68), Vp(x, 1.36, -4.65), PIERRE, Mat.Slate, Vp(0, 0, x > 0 and 3 or -3), "Wedge")
		detailProp(m, "Lèvre claire du glacis", Vp(0.54, 0.38, 0.51), Vp(x, 1.57, -4.70), CALCAIRE, Mat.Slate, Vp(0, 0, x > 0 and 3 or -3), "Wedge")
		detailProp(m, "Mousse au glacis", Vp(0.39, 0.26, 0.36), Vp(x - 0.12, 0.98, -4.85), rgb(97, 128, 75), Mat.Grass, Vp(5, 5, -4), "Wedge")
	end
	for _, x in { -2.76, 2.76 } do
		detailProp(m, "Embrasure d’archère", Vp(0.59, 1.82, 0.16), Vp(x, 4.61, -4.53), rgb(63, 58, 55), Mat.Slate, Vp(0, 0, 2))
		detailProp(m, "Linteau de l’archère", Vp(0.78, 0.22, 0.22), Vp(x, 5.54, -4.53), PIERRE_CLAIRE, Mat.Slate, Vp(0, 0, -3))
		detailProp(m, "Tablette sous l’archère", Vp(0.76, 0.22, 0.24), Vp(x, 3.64, -4.59), PIERRE, Mat.Slate, Vp(0, 0, 3))
	end
	detailProp(m, "Bannière coupée au-dessus de la porte", Vp(1.14, 1.39, 0.11), Vp(0, 6.26, -4.59), GARANCE, Mat.Fabric, Vp(0, 0, -3))
	detailProp(m, "Pointe de bannière", Vp(0.57, 0.46, 0.103), Vp(0.22, 5.49, -4.615), rgb(101,44,47), Mat.Fabric, Vp(0, 0, 5), "Wedge")
	detailProp(m, "Écu brodé", Vp(0.33, 0.33, 0.041), Vp(-0.03, 6.44, -4.655), OR, Mat.Fabric, Vp(0, 0, 43))
	fini(m)
end

function PROPS_VALDOR.Embarcadere()
	local m = nouveau("Embarcadere")
	lamesProp(m, "Ponton", Vp(3.98, 0.33, 9.98), Vp(0, 0.63, 0), 12, "Z", BOIS_CLAIR)
	for _, x in { -1.80, 1.80 } do
		P(m, "Longeron", Vp(0.29, 0.33, 9.92), Vp(x, 0.41, 0), BOIS_FONCE, Mat.Wood)
		for _, z in { -4, 0, 4 } do
			P(m, "Pieu", Vp(0.48, 2.03, 0.47), Vp(x, 0.015, z), BOIS, Mat.Wood)
			cylProp(m, "Cercle", 0.61, 0.16, Vp(x, 0.84, z), FER, Mat.Metal, nil, false)
		end
	end
	P(m, "Quille", Vp(1.14, 0.31, 5.66), Vp(3.45, 0.155, 0), BOIS_FONCE, Mat.Wood)
	for _, x in { 2.39, 4.51 } do
		lamesProp(m, "Virure", Vp(0.29, 0.82, 4.15), Vp(x, 0.65, 0), 3, "Y", BOIS)
		for _, s in { -1, 1 } do
			lienProp(m, "Étrave", Vp(x, 0.68, s * 2.02), Vp(3.45, 0.68, s * 2.97), 0.25, 0.81, BOIS, Mat.Wood)
		end
	end
	for _, z in { -1.51, 0, 1.51 } do
		P(m, "Banc", Vp(2.37, 0.18, 0.26), Vp(3.45, 0.99, z), BOIS_CLAIR, Mat.Wood)
	end
	P(m, "Mat", Vp(0.23, 4.92, 0.23), Vp(3.45, 3.46, 0), BOIS_FONCE, Mat.Wood)
	lienProp(m, "Vergue", Vp(3.45, 5.5, -1.35), Vp(3.45, 5.11, 1.41), 0.12, 0.13, BOIS, Mat.Wood, false)
	for i = 0, 4 do
		local z = (i - 2) * 0.51
		P(m, "Voile", Vp(0.13, 2.75 - i * 0.11, 0.52), Vp(3.49 + math.sin(i) * 0.07, 4.0 + i * 0.021, z), LIN, Mat.Fabric, { collide = false })
	end
	lienProp(m, "Amarre", Vp(1.8, 0.91, -4), Vp(3.45, 0.91, -2.82), 0.073, 0.073, LIN, Mat.Fabric, false)
	P(m, "PiedPanneau", Vp(0.27, 2.08, 0.29), Vp(0, 1.66, -4.58), BOIS_FONCE, Mat.Wood)
	lamesProp(m, "Panneau", Vp(2.22, 1.02, 0.18), Vp(0, 2.60, -4.58), 3, "Y", BOIS)
	for _, x in { -1.80, 1.80 } do
		for i, z in { -4, 0, 4 } do
			reliefProp(m, "Tête usée du pieu", Vp(0.47, 0.17, 0.48), Vp(x, 1.041, z), BOIS_CLAIR, Mat.Wood, 3, 0, i * 4 - 9)
			reliefProp(m, "Algue de la ligne d’eau", Vp(0.35, 0.54, 0.10), Vp(x + 0.04, 0.22 - i * 0.06, z + 0.212),
				i == 2 and MOUSSE_SOMBRE or MOUSSE, Mat.Grass, -5, 0, i * 4 - 6)
		end
	end
	for i, z in { -2.29, -1.31, -0.39, 0.62, 1.54, 2.15 } do
		reliefProp(m, "Préceinte de la barque", Vp(0.14, 0.19, 1.03 - i % 3 * 0.10), Vp(4.57 - math.abs(z) * 0.026, 0.89, z),
			i % 2 == 0 and BOIS_CLAIR or BOIS_FONCE, Mat.Wood, i % 3 * 4 - 4, 0, 5)
	end
	for i, z in { -0.84, -0.32, 0.22, 0.75 } do
		reliefProp(m, "Couture de la voile reprise", Vp(0.14, 0.57, 0.51), Vp(3.56, 3.48 + i % 2 * 0.061, z),
			i % 2 == 0 and GARANCE or rgb(171, 128, 95), Mat.Fabric, i * 3 - 8, 0, 5)
	end
	for i, z in { -3.66, -3.35, -3.20 } do
		cylProp(m, "Bobine d’amarre", 0.55 - i * 0.058, 0.11, Vp(1.39 - i * 0.034, 0.84 + i * 0.07, z),
			i == 2 and BOIS_CLAIR or LIN, Mat.Fabric, nil, false)
	end

	for _, x in { -1.8, 1.8 } do
		for i, z in { -4, 0, 4 } do
			detailProp(m, "Tête de pieu taillée", Vp(0.49, 0.19, 0.47), Vp(x, 1.02, z), BOIS_CLAIR, Mat.Wood, Vp(0, i * 5, 5 - i * 3), "Wedge")
			detailProp(m, "Dépôt de rive sur pieu", Vp(0.29, 0.47, 0.086), Vp(x, 0.38, z + 0.22), rgb(80, 106 + i * 5, 76), Mat.Grass, Vp(0, 0, i * 4 - 7), "Wedge")
		end
	end
	for i, z in { -1.51, 0, 1.51 } do
		detailProp(m, "Plaque de renfort du bordé", Vp(0.09, 0.19, 0.76), Vp(2.23, 0.74, z + 0.13), FER, Mat.Metal, Vp(-5, 0, i * 3))
		detailProp(m, "Joue d’étoupe du bordé", Vp(0.08, 0.13, 0.81), Vp(4.65, 0.94, z - 0.08), BOIS_CLAIR, Mat.Wood, Vp(i * 2 - 5, 0, -3))
	end
	detailProp(m, "Bordé relevé du canot", Vp(0.18, 0.18, 3.94), Vp(4.5, 1.05, 0.04), BOIS_FONCE, Mat.Wood, Vp(-2, 0, 0))
	detailProp(m, "Bordé clair du canot", Vp(0.17, 0.14, 3.94), Vp(2.39, 1.08, -0.01), BOIS_CLAIR, Mat.Wood, Vp(2, 0, 0))
	detailProp(m, "Patin de proue", Vp(0.29, 0.41, 0.29), Vp(3.44, 1.12, -2.70), BOIS, Mat.Wood, Vp(-19, 0, 4), "Wedge")
	detailProp(m, "Raccommodage d’indigo", Vp(0.07, 0.67, 0.53), Vp(3.63, 3.47, 0.73), rgb(68,106,114), Mat.Fabric, Vp(-7, 6, 2))
	detailProp(m, "Couture du raccommodage", Vp(0.08, 0.12, 0.46), Vp(3.67, 3.79, 0.77), LIN, Mat.Fabric, Vp(-7, 6, 2))
	detailProp(m, "Pointe de voile libre", Vp(0.12, 0.28, 0.53), Vp(3.52, 2.73, -0.61), rgb(178,151,116), Mat.Fabric, Vp(4, 7, 0), "Wedge")
	detailProp(m, "Glène d’amarre sur le ponton", Vp(0.63, 0.14, 0.58), Vp(1.44, 0.87, -3.61), LIN, Mat.Fabric, Vp(0, 7, 0), "Ball")
	detailProp(m, "Brin libre de l’amarre", Vp(0.14, 0.085, 0.55), Vp(1.51, 0.83, -3.34), CHAUME, Mat.Fabric, Vp(0, 22, 0))
	fini(m)
end

function PROPS_VALDOR.Plancher()
	local m = nouveau("Plancher")
	local largeurs = { 0.47, 0.64, 0.52, 0.73, 0.49, 0.56, 0.59 }
	local tons = { rgb(98, 63, 40), BOIS, BOIS_CLAIR, rgb(143, 100, 61) }
	local bord = -2
	for i, w in largeurs do
		P(m, "Planches", Vp(w - 0.018, 0.4, 4), Vp(bord + w / 2, 0.2, 0), tons[(i - 1) % #tons + 1], Mat.WoodPlanks)
		bord += w
	end
	for _, z in { -1.7, 1.7 } do
		P(m, "Solive", Vp(4, 0.16, 0.23), Vp(0, 0.08, z), BOIS_FONCE, Mat.Wood)
		reliefProp(m, "Solive à chant clair", Vp(3.96, 0.12, 0.19), Vp(0, 0.11, z), BOIS_CLAIR, Mat.Wood)
	end
	reliefProp(m, "Fond sombre des joints", Vp(4, 0.21, 4), Vp(0, 0.17, 0), BOIS_FONCE, Mat.Wood)
	for i, p in { Vp(-1.64, 0.403, 0.93), Vp(-1.14, 0.404, 0.45), Vp(0.21, 0.403, -0.94) } do
		reliefProp(m, "Bord poli par les pas", Vp(0.20 + i * 0.02, 0.025, 1.46 - i * 0.24), p,
			i == 2 and BOIS_CLAIR or rgb(161, 111, 70), Mat.WoodPlanks, 0, i * 3 - 7)
	end
	detailProp(m, "Liseré de rive au sud", Vp(3.92, 0.07, 0.16), Vp(0, 0.38, 1.909), BOIS_FONCE, Mat.Wood)
	detailProp(m, "Liseré de rive au nord", Vp(3.92, 0.07, 0.16), Vp(0, 0.38, -1.909), BOIS_FONCE, Mat.Wood)
	detailProp(m, "About de rive éclairci", Vp(1.68, 0.04, 0.13), Vp(0.78, 0.414, 1.918), BOIS_CLAIR, Mat.Wood, Vp(0, 2, 0))
	detailProp(m, "About de rive sombre", Vp(1.56, 0.035, 0.12), Vp(-0.89, 0.415, -1.914), BOIS, Mat.Wood, Vp(0, -2, 0))
	detailProp(m, "Bois de passage à gauche", Vp(0.31, 0.025, 1.07), Vp(-0.37, 0.398, -0.45), rgb(196,147,91), Mat.Wood, Vp(0, 2, 0), "Wedge")
	detailProp(m, "Bois de passage au centre", Vp(0.36, 0.025, 1.42), Vp(0.04, 0.403, 0.03), rgb(192,141,83), Mat.Wood, Vp(0, -2, 0))
	detailProp(m, "Bois de passage à droite", Vp(0.32, 0.025, 0.79), Vp(0.42, 0.398, 0.36), rgb(172,118,69), Mat.Wood, Vp(0, 3, 0), "Wedge")
	fini(m)
end

local function murBoise(nom: string, porte: boolean, fenetre: boolean)
	local m = nouveau(nom)
	for _, x in { -2, 2 } do
		P(m, "Poteau", Vp(0.6, 7.2, 0.6), Vp(x, 3.6, 0), BOIS_FONCE, Mat.Wood)
		for _, y in { 0.43, 6.75 } do
			P(m, "Bride", Vp(0.63, 0.19, 0.63), Vp(x, y, 0), FER, Mat.Metal, { collide = false })
		end
	end
	if porte then
		lamesProp(m, "Linteau", Vp(3.97, 1.4, 0.49), Vp(0, 6.3, 0), 7, "X", BOIS_CLAIR)
		for _, x in { -1.65, 1.65 } do
			lamesProp(m, "Montant", Vp(0.7, 5.62, 0.49), Vp(x, 2.81, 0), 1, "X", BOIS)
		end
		for _, x in { -1.43, 1.43 } do
			reliefProp(m, "Chant de jambage raboté", Vp(0.23, 5.32, 0.11), Vp(x, 2.78, 0.235),
				BOIS_CLAIR, Mat.Wood, 0, 0, math.sign(x) * 2)
			reliefProp(m, "Sabot sombre du jambage", Vp(0.49, 0.56, 0.11), Vp(x, 0.37, 0.235),
				BOIS_FONCE, Mat.Wood, 0, 0, -math.sign(x) * 2)
		end
		reliefProp(m, "Lit clair du linteau", Vp(2.78, 0.17, 0.16), Vp(0, 5.80, 0.234), BOIS_CLAIR, Mat.Wood, 0, 0, 2)
		reliefProp(m, "Entaille basse du linteau", Vp(0.74, 0.11, 0.09), Vp(-0.93, 5.77, 0.272), BOIS_FONCE, Mat.Wood, 0, 0, -4)
	elseif fenetre then
		lamesProp(m, "Bas", Vp(3.99, 2.6, 0.49), Vp(0, 1.3, 0), 5, "X", BOIS_CLAIR)
		lamesProp(m, "Haut", Vp(3.99, 1.8, 0.49), Vp(0, 6.1, 0), 5, "X", BOIS)
		for _, x in { -1.55, 1.55 } do lamesProp(m, "Cote", Vp(0.9, 2.61, 0.49), Vp(x, 3.9, 0), 1, "X", BOIS) end
		P(m, "Vitre", Vp(2.2, 2.62, 0.11), Vp(0, 3.9, 0), rgb(156, 190, 207), Mat.Glass, { transp = 0.46 })
		P(m, "Croisillon", Vp(2.26, 0.14, 0.30), Vp(0, 3.90, 0), BOIS_FONCE, Mat.Wood)
		P(m, "Croisillon", Vp(0.14, 2.62, 0.30), Vp(0, 3.90, 0), BOIS_FONCE, Mat.Wood)
		for _, y in { 2.57, 5.20 } do
			P(m, "Cadre", Vp(2.35, 0.21, 0.64), Vp(0, y, 0), y < 3 and BOIS_CLAIR or BOIS_FONCE, Mat.Wood)
		end
		for _, x in { -1.15, 1.15 } do
			reliefProp(m, "Joue de l’encadrement", Vp(0.17, 2.48, 0.49), Vp(x, 3.89, 0.037),
				BOIS, Mat.Wood, 0, 0, math.sign(x) * 2)
		end
	else
		lamesProp(m, "Mur", Vp(3.99, 7, 0.5), Vp(0, 3.5, 0), 5, "X", BOIS_CLAIR)
		reliefProp(m, "Fond sombre du bardage", Vp(3.99, 6.96, 0.32), Vp(0, 3.50, 0), BOIS_FONCE, Mat.Wood)
		for i, x in { -1.70, -1.18, -0.22, 0.69, 1.66 } do
			reliefProp(m, "Bardage éclairci à la rive", Vp(0.29 + i % 2 * 0.065, 2.68 - i % 3 * 0.48, 0.072),
				Vp(x, 5.19 - i % 3 * 0.36, 0.231), i % 2 == 0 and BOIS or BOIS_CLAIR, Mat.WoodPlanks, 0, 0, i % 3 * 3 - 3)
		end
		for i, x in { -1.29, -0.22, 1.04 } do
			reliefProp(m, "Lèvre sombre du bardage usé", Vp(0.93 - i * 0.115, 0.22, 0.092), Vp(x, 0.46 + i * 0.071, 0.228),
				i == 2 and BOIS or BOIS_FONCE, Mat.WoodPlanks, 0, 0, i * 3 - 7)
		end
		for i, x in { -1.51, -0.81, 0.67 } do
			detailProp(m, "Chant des planches au revers", Vp(0.22 + i * 0.035, 3.22 - i * 0.45, 0.085),
				Vp(x, 3.58 - i * 0.19, -0.234), i == 2 and BOIS_FONCE or BOIS_CLAIR,
				Mat.WoodPlanks, Vp(0, 0, i * 3 - 7))
		end
	end
	for _, y in { porte and 5.66 or 0.23, 6.89 } do
		P(m, "Traverse", Vp(4.01, 0.21, 0.58), Vp(0, y, 0), BOIS_FONCE, Mat.Wood)
	end
	for _, z in { -0.254, 0.254 } do
		detailProp(m, "Faîte raboté", Vp(3.99, 0.12, 0.096), Vp(0, 6.94, z), BOIS_CLAIR, Mat.Wood)
		if not fenetre then
			detailProp(m, "Liseré dans l’ombre", Vp(3.99, 0.105, 0.096), Vp(0, porte and 5.59 or 0.35, z), BOIS_FONCE, Mat.Wood)
		end
	end
	if porte then
		for i, x in { -1.38, 1.38 } do
			detailProp(m, "Jambe du linteau", Vp(0.18, 0.61, 0.11), Vp(x * 0.96, 5.46, 0.249), BOIS, Mat.Wood, Vp(0, 0, i == 1 and -21 or 21))
		end
	end
	fini(m)
end

function PROPS_VALDOR.Mur_Planches() murBoise("Mur_Planches", false, false) end
function PROPS_VALDOR.Mur_Porte() murBoise("Mur_Porte", true, false) end
function PROPS_VALDOR.Mur_Fenetre() murBoise("Mur_Fenetre", false, true) end

local function murMaconne(nom: string, c: Color3, mat: Enum.Material, rangs: number)
	local m = nouveau(nom)
	for _, x in { -2, 2 } do
		P(m, "Poteau", Vp(0.6, 7.2, 0.6), Vp(x, 3.6, 0), BOIS_FONCE, Mat.Wood)
	end
	local h = 7 / rangs
	local clair, sombre = c:Lerp(PIERRE_CLAIRE, 0.31), c:Lerp(rgb(74, 64, 62), 0.48)
	local jointSombre = c:Lerp(rgb(55, 49, 48), 0.64)
	local tons = { c:Lerp(jointSombre, 0.33), c, c:Lerp(rgb(227, 211, 188), 0.39) }
	reliefProp(m, "Lit de mortier sombre", Vp(4, 6.95, 0.40), Vp(0, 3.51, 0), jointSombre, mat)
	for i = 0, rangs - 1 do
		local trois = i % 2 == 0 and { 1.05, 1.67, 1.28 } or { 1.45, 1.38, 1.17 }
		local joint = rangs == 6 and i % 2 == 1 and { 0.78, 1.22, 0.87, 1.13 } or trois
		local x = -2
		for j, w in joint do
			P(m, "Moellon", Vp(w - 0.042, h - 0.035, 0.46 + (j + i) % 3 * 0.024), Vp(x + w / 2, h * (i + 0.5), 0),
				tons[(2 * i + j) % #tons + 1], mat, { rot = CFrame.Angles(0, 0, math.rad((j + i) % 3 - 1)) })
			x += w
		end
	end
	P(m, "Arase", Vp(4.03, 0.17, 0.58), Vp(0, 6.97, 0), c, mat)
	reliefProp(m, "Chaperon éclairci", Vp(3.86, 0.14, 0.53), Vp(0, 7.037, 0), tons[3], mat, 0, 0, 1)
	detailProp(m, "Solin inférieur", Vp(3.98, 0.18, 0.59), Vp(0, 0.12, 0), sombre, mat)
	if rangs == 6 then
		for i, p in { Vp(-1.15, 0.88, 0.247), Vp(-0.68, 0.78, 0.247) } do
			detailProp(m, "Front de calcaire fracturé", Vp(0.63 - i * 0.07, 0.16, 0.087), p, clair, mat, Vp(0, 0, 7 - i * 4), "Wedge")
		end
	end
	fini(m)
end

function PROPS_VALDOR.Mur_Pierre() murMaconne("Mur_Pierre", CALCAIRE, Mat.Slate, 6) end
function PROPS_VALDOR.Mur_Briques() murMaconne("Mur_Briques", rgb(153, 87, 65), Mat.Brick, 7) end

function PROPS_VALDOR.Toit_Chaume()
	local m = nouveau("Toit_Chaume")
	-- Le dessous conserve sa cote pour s'emboîter sur les anciens murs.
	P(m, "Rive", Vp(4.79, 0.25, 4.79), Vp(0, 7.05, 0), BOIS_FONCE, Mat.Wood)
	for _, z in { -1.75, 1.75 } do
		P(m, "Chevron", Vp(4.71, 0.19, 0.30), Vp(0, 7.22, z), BOIS, Mat.Wood)
	end
	toitureProp(m, 4.71, 4.71, 7.27, 1.14, 0, true)
	for i, x in { -1.78, -0.82, 0.31, 1.39 } do
		for _, z in { -1, 1 } do
			reliefProp(m, "Gerbe d’égout rabattue", Vp(1.19 - i % 3 * 0.082, 0.19, 0.54),
				Vp(x, 7.478 + i % 3 * 0.045, z * (1.90 - i % 2 * 0.08)),
				i % 3 == 0 and CHAUME or OR_PALE, Mat.Grass, z * 27, 0, i % 3 * 4 - 4)
		end
	end
	reliefProp(m, "Dos clair du faîtage", Vp(4.51, 0.21, 0.32), Vp(0, 8.46, 0.02), BOIS_CLAIR, Mat.Wood, 0, 0, 1)
	for i, x in { -1.47, 0.06, 1.56 } do
		reliefProp(m, "Pointe sombre de gerbe", Vp(0.72 - i * 0.062, 0.10, 0.40), Vp(x, 7.44, 2.06),
			BOIS, Mat.Grass, 26, 0, i * 3 - 6)
	end

	local tons = { rgb(146, 110, 52), CHAUME, rgb(223, 180, 90) }
	for i, x in { -1.88, -0.60, 0.63, 1.82 } do
		detailProp(m, "Gerbe coupée de rive", Vp(0.72 + i % 2 * 0.17, 0.19, 0.57), Vp(x, 7.388 - i % 3 * 0.04, 2.04),
			tons[i % 3 + 1], Mat.Grass, Vp(27, i % 3 * 3 - 4, i - 4), "Wedge")
	end
	detailProp(m, "Coiffe de paille du faîtage", Vp(4.65, 0.13, 0.36), Vp(0, 8.469, 0), tons[3], Mat.Grass)
	fini(m)
end

function PROPS_VALDOR.Escalier_Bois()
	local m = nouveau("Escalier_Bois")
	for i = 0, 7 do
		local y, z = 0.44 + i * 0.92, 1.75 - i * 0.50
		P(m, "Marche", Vp(3.59, 0.88, 0.50), Vp(0, y, z),
			({ BOIS, BOIS_CLAIR, rgb(148, 102, 63) })[i % 3 + 1], Mat.WoodPlanks)
		reliefProp(m, "Bord de marche poli", Vp(2.98 + i % 3 * 0.13, 0.038, 0.23),
			Vp((i % 3 - 1) * 0.10, y + 0.442, z + 0.083), i % 3 == 0 and BOIS or BOIS_CLAIR, Mat.Wood, 0, i % 3 - 1)
		P(m, "Nez", Vp(3.61, 0.13, 0.11), Vp(0, y + 0.36, z + 0.18), BOIS_FONCE, Mat.Wood)
	end
	for _, x in { -1.71, 1.71 } do
		lienProp(m, "Limon", Vp(x, 0.33, 1.76), Vp(x, 6.77, -1.77), 0.23, 0.32, BOIS_FONCE, Mat.Wood, false)
	end
	for _, x in { -1.72, 1.72 } do
		lienProp(m, "Chant éclairci du limon", Vp(x, 0.32, 1.62), Vp(x, 6.77, -1.70), 0.13, 0.20, BOIS, Mat.Wood, false)
	end
	fini(m)
end

-- Petit décor de sol. Les noms et le pivot continuent d'identifier les ressources au chargement.
function PROPS_VALDOR.Rocher()
	local m = nouveau("Rocher")
	P(m, "Pierre", Vp(4.04, 2.9, 3.57), Vp(0, 1.05, 0), PIERRE, Mat.Slate,
		{ forme = "Ball", rot = CFrame.Angles(0, 0.12, 0) })
	for i, taille in { Vp(2.71, 1.42, 2.14), Vp(1.52, 1.25, 1.86), Vp(2.03, 0.83, 2.0) } do
		local p = ({ Vp(1.26, 1.0, 0.68), Vp(-1.54, 0.51, -0.63), Vp(0.20, 1.76, 0.48) })[i]
		P(m, "Éclat", taille, p, i == 2 and CALCAIRE or PIERRE_CLAIRE, i == 1 and Mat.Rock or Mat.Slate,
			{ forme = i == 3 and "Wedge" or "Ball", rot = CFrame.Angles(0.04, i * 0.71, 0.1) })
	end
	for _, p in { Vp(-0.42, 2.46, -0.15), Vp(0.27, 2.44, 0.18), Vp(0.96, 1.78, 0.84) } do
		P(m, "Mousse", Vp(0.83, 0.16, 0.77), p, rgb(95, 118, 70), Mat.Grass, { forme = "Ball", collide = false })
	end
	reliefProp(m, "Strate de quartz", Vp(1.92, 0.21, 0.49), Vp(0.85, 1.58, 1.57), rgb(197, 177, 150), Mat.Slate, -5, 6, 6, "Wedge")
	reliefProp(m, "Revers cassé de la strate", Vp(1.17, 0.27, 0.39), Vp(0.77, 1.35, 1.63), FER_SOMBRE, Mat.Slate, 6, -5, 4)
	reliefProp(m, "Corniche moussue", Vp(1.51, 0.21, 0.76), Vp(0.43, 2.40, 0.28), MOUSSE, Mat.Grass, 5, -7, 4)
	reliefProp(m, "Langue claire de la corniche", Vp(0.67, 0.16, 0.50), Vp(0.91, 2.29, 0.53), MOUSSE_CLAIRE, Mat.Grass, 18, -6, 4)
	reliefProp(m, "Retombée de mousse", Vp(0.43, 0.37, 0.25), Vp(1.05, 2.11, 0.67), MOUSSE_SOMBRE, Mat.Grass, -6, 4, -6)
	reliefProp(m, "Épaulement ardoise", Vp(0.93, 0.51, 0.84), Vp(-0.84, 0.69, 1.29), rgb(99, 100, 101), Mat.Rock, -6, 32, -7, "Wedge")
	detailProp(m, "Assise arrachée", Vp(2.44, 0.57, 1.89), Vp(-0.24, 0.39, 0.70), rgb(94,96,95), Mat.Slate, Vp(-4, 14, 5), "Wedge")
	detailProp(m, "Strate d’ardoise", Vp(2.39, 0.35, 1.37), Vp(0.02, 0.98, 0.87), rgb(111,118,121), Mat.Slate, Vp(-4, 12, -5))
	detailProp(m, "Strate claire brisée", Vp(1.82, 0.24, 1.2), Vp(0.64, 1.37, 1.02), CALCAIRE, Mat.Slate, Vp(-5, -8, 4), "Wedge")
	detailProp(m, "Cassure ouverte", Vp(0.43, 0.32, 0.82), Vp(-0.68, 1.64, 1.11), rgb(73,83,86), Mat.Slate, Vp(-5, 29, -6))
	detailProp(m, "Corniche de mousse", Vp(1.58, 0.21, 0.76), Vp(-0.09, 2.25, 0.55), rgb(107,130,75), Mat.Grass, Vp(8, -6, -4))
	detailProp(m, "Mousse rompue", Vp(0.45, 0.47, 0.20), Vp(-0.40, 2.052, 0.83), rgb(74,101,65), Mat.Grass, Vp(0, 5, -9), "Wedge")
	detailProp(m, "Pointe de lichen sur la cassure", Vp(0.44, 0.12, 0.27), Vp(0.68, 2.19, 0.73), rgb(142,151,86), Mat.Grass, Vp(7, 4, 5), "Wedge")
	fini(m)
end

function PROPS_VALDOR.Caillou()
	local m = nouveau("Caillou")
	P(m, "Pierre", Vp(1.16, 0.59, 0.88), Vp(0, 0.295, 0), PIERRE, Mat.Rock,
		{ forme = "Ball", rot = CFrame.Angles(0, 0.38, 0), collide = false })
	P(m, "Éclat", Vp(0.67, 0.26, 0.59), Vp(0.28, 0.38, 0.17), CALCAIRE, Mat.Slate,
		{ forme = "Wedge", rot = CFrame.Angles(0, -0.68, 0), collide = false })
	P(m, "Éclat", Vp(0.57, 0.29, 0.46), Vp(0.63, 0.15, 0.19), PIERRE_CLAIRE, Mat.Slate,
		{ forme = "Ball", collide = false })
	reliefProp(m, "Cassure d’ardoise", Vp(0.48, 0.23, 0.33), Vp(-0.33, 0.22, 0.20), FER_CLAIR, Mat.Slate, -6, 22, 4, "Wedge")
	reliefProp(m, "Fente sous la cassure", Vp(0.42, 0.095, 0.12), Vp(-0.30, 0.23, 0.32), FER_SOMBRE, Mat.Slate, 0, -8, 6)
	reliefProp(m, "Lichen du sommet", Vp(0.46, 0.092, 0.31), Vp(-0.14, 0.535, -0.015), MOUSSE_CLAIRE, Mat.Grass, -6, 8, 4, "Ball")
	reliefProp(m, "Lichen en lisière", Vp(0.25, 0.072, 0.29), Vp(-0.28, 0.467, 0.085), MOUSSE_SOMBRE, Mat.Grass, -7, 4, -5, "Ball")
	detailProp(m, "Ressaut sombre", Vp(0.71, 0.16, 0.53), Vp(0.16, 0.21, 0.19), rgb(79,88,88), Mat.Slate, Vp(0, 17, 5), "Wedge")
	detailProp(m, "Nerf de quartz", Vp(0.57, 0.104, 0.29), Vp(0.07, 0.41, 0.26), rgb(211,187,155), Mat.Slate, Vp(6, -17, -6), "Wedge")
	detailProp(m, "Tranche d’ardoise", Vp(0.41, 0.16, 0.30), Vp(0.46, 0.21, 0.28), rgb(116,124,129), Mat.Slate, Vp(5, 7, 5), "Wedge")
	detailProp(m, "Lichen jaunâtre", Vp(0.33, 0.07, 0.30), Vp(-0.13, 0.552, 0.10), rgb(133,142,80), Mat.Grass, Vp(4, -7, -5), "Ball")
	detailProp(m, "Pointe de lichen", Vp(0.18, 0.15, 0.16), Vp(-0.24, 0.475, 0.19), rgb(101,115,77), Mat.Grass, Vp(6, 6, 7), "Wedge")
	fini(m)
end

function PROPS_VALDOR.Branche()
	local m = nouveau("Branche")
	lienProp(m, "Bois", Vp(-1.36, 0.165, -0.25), Vp(0.39, 0.215, 0.03), 0.27, 0.25, BOIS_FONCE, Mat.Wood, false)
	lienProp(m, "Fourche", Vp(0.15, 0.21, 0.02), Vp(1.14, 0.19, -0.31), 0.19, 0.18, BOIS, Mat.Wood, false)
	lienProp(m, "Fourche", Vp(0.15, 0.21, 0.02), Vp(0.72, 0.16, 0.68), 0.14, 0.15, BOIS, Mat.Wood, false)
	lienProp(m, "Brindille", Vp(0.44, 0.19, 0.31), Vp(0.19, 0.13, 0.67), 0.089, 0.083, BOIS, Mat.Wood, false)
	lienProp(m, "Écorce fendue", Vp(-1.31, 0.20, -0.25), Vp(-0.93, 0.31, -0.19), 0.085, 0.023, BOIS_CLAIR, Mat.Wood, false)
	lienProp(m, "Lanière d’écorce", Vp(-1.27, 0.27, -0.18), Vp(-0.37, 0.31, -0.045), 0.16, 0.09, BOIS, Mat.Wood, false)
	lienProp(m, "Écharde claire", Vp(-0.94, 0.29, -0.13), Vp(-1.35, 0.40, -0.26), 0.103, 0.065, LIN, Mat.Wood, false)
	reliefProp(m, "Nœud d’écorce brun", Vp(0.29, 0.16, 0.22), Vp(0.18, 0.265, 0.10), BOIS, Mat.Wood, 5, 22, 5, "Ball")
	reliefProp(m, "Liège moussu", Vp(0.41, 0.088, 0.22), Vp(-0.18, 0.31, -0.056), MOUSSE, Mat.Grass, 4, -7, -5)
	reliefProp(m, "Lamelle de mousse décollée", Vp(0.23, 0.085, 0.19), Vp(-0.06, 0.32, 0.037), MOUSSE_CLAIRE, Mat.Grass, -6, -5, 5, "Wedge")
	detailProp(m, "Écorce en long lambeau", Vp(1.07, 0.105, 0.17), Vp(-0.54, 0.295, -0.10), BOIS, Mat.Wood, Vp(3, -9, 4))
	detailProp(m, "Lame d’aubier au bout cassé", Vp(0.33, 0.13, 0.17), Vp(1.0, 0.23, -0.267), BOIS_CLAIR, Mat.Wood, Vp(3, 16, -7), "Wedge")
	detailProp(m, "Écorce plissée de la fourche", Vp(0.47, 0.096, 0.14), Vp(0.43, 0.225, 0.351), BOIS_FONCE, Mat.Wood, Vp(4, -49, -4))
	detailProp(m, "Mousse sur l’écorce", Vp(0.57, 0.081, 0.18), Vp(-0.40, 0.347, -0.07), rgb(105,127,76), Mat.Grass, Vp(0, -9, 5))
	detailProp(m, "Pointe de mousse contre la fente", Vp(0.23, 0.084, 0.13), Vp(-0.18, 0.304, 0.012), rgb(70,96,68), Mat.Grass, Vp(5, -14, 4), "Wedge")
	fini(m)
end

function PROPS_VALDOR.Buisson()
	local m = nouveau("Buisson")
	P(m, "Feuilles", Vp(3.15, 2.44, 2.9), Vp(0, 1.22, 0), rgb(78, 116, 64), Mat.Grass, { forme = "Ball" })
	for i, p in { Vp(-1.02, 1.28, -0.12), Vp(0.92, 1.62, 0.03), Vp(-0.25, 2.1, -0.48),
		Vp(0.4, 1.10, 0.87), Vp(-0.5, 1.74, 0.64), Vp(0.47, 2.19, -0.32) } do
		P(m, "Feuilles", Vp(1.34, 1.38 + i % 2 * 0.23, 1.31), p, rgb(76 + i * 4, 112 + i * 3, 61 + i % 3 * 5),
			Mat.Grass, { forme = "Ball", collide = false })
	end
	for i, p in { Vp(-1.27, 1.44, 0.62), Vp(-0.64, 2.0, 1.09), Vp(0.51, 1.39, 1.46),
		Vp(1.38, 1.58, 0.74), Vp(0.34, 2.50, 0.16), Vp(1.04, 1.75, -0.68) } do
		for j = 0, 1 do
			P(m, "Baie", Vp(0.23, 0.24, 0.22), p + Vp(j * 0.14, -j * 0.13, 0.06),
				rgb(148 + j * 17, 51 + i % 3 * 6, 56), Mat.Grass, { forme = "Ball", collide = false })
		end
	end
	for i, profil in { { -0.76, 2.36, 0.15, 0.97 }, { -0.18, 2.62, 0.02, 0.98 }, { 0.55, 2.60, -0.17, 0.96 },
		{ 1.06, 2.11, 0.47, 0.82 }, { 0.66, 1.70, 1.10, 0.64 }, { -0.72, 1.87, 0.97, 0.66 } } do
		reliefProp(m, "Nappe feuillue en surplomb", Vp(profil[4], 0.30 + i % 2 * 0.08, 0.87),
			Vp(profil[1], profil[2], profil[3]), i % 3 == 0 and MOUSSE or MOUSSE_CLAIRE, Mat.Grass,
			i % 3 * 5 - 6, i * 13, i % 3 * 6 - 6, "Wedge")
	end
	for i, p in { Vp(-0.89, 1.26, 0.91), Vp(0.36, 1.30, 1.31), Vp(0.93, 1.45, 1.02) } do
		reliefProp(m, "Pointe sombre de ramure", Vp(0.61, 0.27 + i * 0.04, 0.46), p, MOUSSE_SOMBRE, Mat.Grass,
			-5, i * 19, i * 4 - 9, "Wedge")
	end
	lienProp(m, "Rameau sous les baies", Vp(0.04, 0.42, 0.55), Vp(0.62, 1.38, 1.48), 0.15, 0.13, BOIS, Mat.Wood, false)
	detailProp(m, "Manteau de jeunes feuilles", Vp(1.58, 0.55, 1.44), Vp(-0.10, 2.21, 0.31), rgb(124,158,77), Mat.Grass, Vp(7, -9, -6))
	detailProp(m, "Cime en balai à gauche", Vp(0.80, 0.51, 0.87), Vp(-0.71, 2.10, 0.49), rgb(112,154,71), Mat.Grass, Vp(6, 13, -6), "Wedge")
	detailProp(m, "Cime en balai à droite", Vp(0.89, 0.49, 0.81), Vp(0.53, 2.31, 0.22), rgb(151,171,86), Mat.Grass, Vp(-5, -7, 4), "Wedge")
	detailProp(m, "Lobe retombant", Vp(0.42, 0.89, 0.57), Vp(-0.90, 1.54, 0.82), rgb(63,107,69), Mat.Grass, Vp(-4, 31, 23), "Wedge")
	detailProp(m, "Lobe de la rive ajourée", Vp(0.58, 0.57, 0.61), Vp(0.73, 1.59, 1.06), rgb(108,142,74), Mat.Grass, Vp(5, -17, -7), "Wedge")
	detailProp(m, "Fente sombre du feuillage", Vp(0.52, 0.68, 0.58), Vp(-0.28, 1.20, 1.07), rgb(55,91,63), Mat.Grass, Vp(-7, -4, 6), "Wedge")
	detailProp(m, "Souche brune sous la ramure", Vp(0.42, 1.07, 0.44), Vp(-0.05, 0.51, 0.15), BOIS_FONCE, Mat.Wood, Vp(8, 7, -6))
	detailProp(m, "Bifurcation sous le feuillage", Vp(0.16, 0.67, 0.18), Vp(0.12, 0.88, 0.23), BOIS, Mat.Wood, Vp(-12, 0, -21))
	detailProp(m, "Éclat du rameau en façade", Vp(0.15, 0.48, 0.14), Vp(0.34, 1.10, 0.67), BOIS_CLAIR, Mat.Wood, Vp(-21, 0, -22))
	fini(m)
end

function PROPS_VALDOR.Tronc_Couche()
	local m = nouveau("Tronc_Couche")
	cylProp(m, "Bois", 1.68, 4.45, Vp(-0.04, 0.84, 0), BOIS_FONCE, Mat.Wood, CFrame.identity)
	for _, x in { -2.31, 2.24 } do
		for i = 1, 3 do
			cylProp(m, "Cerne", 1.50 - i * 0.32, 0.065, Vp(x + math.sign(x) * i * 0.035, 0.84 + i * 0.015, 0.02 * i),
				i % 2 == 0 and BOIS or BOIS_CLAIR, Mat.Wood, CFrame.identity, false)
		end
	end
	lienProp(m, "Nœud", Vp(-0.87, 1.23, 0.31), Vp(-0.51, 1.91, 0.73), 0.41, 0.32, BOIS_FONCE, Mat.Wood, false)
	for i = 0, 3 do
		P(m, "Mousse", Vp(0.83, 0.19, 0.67), Vp(-0.73 + i * 0.55, 1.63 - i % 2 * 0.045, i % 2 * 0.17),
			rgb(84 + i * 4, 117, 64), Mat.Grass, { forme = "Ball", collide = false })
	end
	for i, profil in { { -1.53, 1.63, 0.18 }, { -0.87, 1.70, 0.25 }, { -0.19, 1.75, 0.16 },
		{ 0.59, 1.64, 0.28 }, { 1.21, 1.60, 0.26 } } do
		reliefProp(m, "Croûte de mousse du tronc", Vp(0.88, 0.16, 0.63), Vp(profil[1], profil[2], profil[3]),
			i % 2 == 0 and MOUSSE or MOUSSE_CLAIRE, Mat.Grass, -5, i * 3 - 7, i % 3 * 4 - 4)
	end
	reliefProp(m, "Retombée sombre de mousse", Vp(0.55, 0.39, 0.26), Vp(0.58, 1.46, 0.62), MOUSSE_SOMBRE, Mat.Grass, -5, 0, -7)
	reliefProp(m, "Plaque d’écorce descellée", Vp(1.78, 0.31, 0.18), Vp(-0.88, 1.05, 0.78), BOIS, Mat.Wood, -5, -3, 4)
	reliefProp(m, "Fente dans le bois de bout", Vp(0.047, 0.50, 0.16), Vp(2.33, 1.11, 0.17), FER_SOMBRE, Mat.Wood, -28, 0, 4)
	detailProp(m, "Pan d’écorce décollé", Vp(2.18, 0.21, 0.56), Vp(-0.70, 1.46, 0.56), BOIS, Mat.Wood, Vp(-7, -4, -3))
	detailProp(m, "Veine de bois à nu", Vp(1.82, 0.13, 0.27), Vp(-0.61, 1.32, 0.70), rgb(177,125,80), Mat.Wood, Vp(-5, 1, -4))
	detailProp(m, "Lèvre sombre de la cassure", Vp(1.12, 0.14, 0.19), Vp(-0.20, 1.25, 0.76), BOIS_FONCE, Mat.Wood, Vp(3, -3, 5), "Wedge")
	detailProp(m, "Fourche courte du vieux nœud", Vp(0.42, 0.79, 0.33), Vp(-0.89, 1.61, 0.55), BOIS, Mat.Wood, Vp(21, 5, -18), "Wedge")
	detailProp(m, "Centre du nœud érodé", Vp(0.32, 0.32, 0.24), Vp(-0.93, 1.83, 0.62), BOIS_CLAIR, Mat.Wood, Vp(7, 13, 11), "Wedge")
	detailProp(m, "Pont de mousse sur l’écorce", Vp(1.82, 0.13, 0.53), Vp(0.39, 1.64, 0.21), rgb(115,137,77), Mat.Grass, Vp(4, 4, 0))
	detailProp(m, "Mousse en lobe rompu", Vp(0.48, 0.30, 0.30), Vp(0.74, 1.53, 0.39), rgb(70,106,70), Mat.Grass, Vp(-4, 4, 7), "Wedge")
	fini(m)
end

function PROPS_VALDOR.Fleurs()
	local m = nouveau("Fleurs")
	for i, p in { Vp(0, 0, 0), Vp(0.33, 0, 0.17), Vp(-0.37, 0, 0.19), Vp(0.11, 0, -0.33) } do
		local h = p + Vp(p.X * 0.9, 0.67 + i % 3 * 0.159, p.Z * 0.93)
		lienProp(m, "Tige", p * 0.33 + Vp(0, 0.03, 0), h, 0.065, 0.061, rgb(86, 119, 65), Mat.Grass, false)
		lienProp(m, "Feuille", (p + h) / 2, (p + h) / 2 + Vp(i % 2 == 0 and -0.2 or 0.21, 0.19, 0.05),
			0.11, 0.065, rgb(104, 134, 73), Mat.Grass, false)
		reliefProp(m, "Calice sombre", Vp(0.21, 0.16, 0.22), h - Vp(0, 0.019, 0), MOUSSE_SOMBRE, Mat.Grass, 6, 0, -5, "Ball")
		lienProp(m, "Revers clair d’une feuille", h * 0.64 + p * 0.36, h * 0.64 + p * 0.36 + Vp(0.19, 0.11, -0.13),
			0.15, 0.056, MOUSSE_CLAIRE, Mat.Grass, false)
		for j, decalage in { Vp(-0.13, 0.102, 0.044), Vp(0.084, 0.11, -0.13) } do
			reliefProp(m, "Pétale recourbé", Vp(0.23 - j * 0.025, 0.098, 0.17), h + decalage,
				i % 2 == 0 and rgb(251, 234, 206) or rgb(218, 137, 116), Mat.Fabric, 6, i * 17, j * 9 - 13, "Ball")
		end
		for j = 0, 3 do
			local a = j * PASSE / 4
			P(m, "Petale", Vp(0.179, 0.12, 0.17), h + Vp(math.cos(a) * 0.11, 0.04, math.sin(a) * 0.11),
				i % 2 == 0 and LIN or CHAUME, Mat.Fabric, { forme = "Ball", collide = false })
		end
		detailProp(m, "Calice ombré", Vp(0.31, 0.10, 0.30), h + Vp(0, 0.014, 0), rgb(78, 112, 65), Mat.Grass, Vp(5, i * 5, -5), "Ball")
		detailProp(m, "Pointe de pétale repliée", Vp(0.19, 0.093, 0.20), h + Vp(0.08, 0.104, -0.055),
			i % 2 == 0 and rgb(238, 221, 183) or rgb(234, 190, 103), Mat.Fabric, Vp(6, 9 * i, i - 5), "Wedge")
		cylProp(m, "Cœur", 0.15, 0.079, h + Vp(0, 0.048, 0), OR, Mat.Fabric, nil, false)
	end
	detailProp(m, "Rosette de feuilles", Vp(0.81, 0.15, 0.75), Vp(0, 0.16, 0.03), rgb(83,121,69), Mat.Grass, Vp(3, 4, -4), "Ball")
	detailProp(m, "Feuille de rosette claire", Vp(0.38, 0.087, 0.27), Vp(-0.32, 0.219, 0.16), rgb(128,156,77), Mat.Grass, Vp(-5, 26, -5), "Wedge")
	detailProp(m, "Feuille de rosette ombrée", Vp(0.45, 0.11, 0.25), Vp(0.32, 0.18, 0.13), rgb(69,104,63), Mat.Grass, Vp(5, -26, 6), "Wedge")
	detailProp(m, "Pointe de rosette en retour", Vp(0.28, 0.11, 0.39), Vp(0.09, 0.26, -0.34), rgb(106,146,75), Mat.Grass, Vp(-7, 11, 6), "Wedge")
	fini(m)
end

function PROPS_VALDOR.Champignon()
	local m = nouveau("Champignon")
	for i, p in { Vp(0, 0, 0), Vp(0.51, 0, 0.21), Vp(-0.33, 0, -0.38) } do
		local h, d = 0.84 - i * 0.163, 0.98 - i * 0.196
		cylProp(m, "Pied", d * 0.31, h, p + Vp(0, h / 2, 0), LIN, Mat.Sand, nil, false)
		cylProp(m, "Lamelles", d, 0.08, p + Vp(0, h - 0.065, 0), rgb(186, 157, 117), Mat.Sand, nil, false)
		P(m, "Chapeau", Vp(d, d * 0.47, d * 0.94), p + Vp(0, h + 0.044, 0), GARANCE, Mat.Sand,
			{ forme = "Ball", collide = false })
		reliefProp(m, "Lèvre sombre du chapeau", Vp(d * 0.61, d * 0.22, d * 0.38), p + Vp(d * 0.13, h - 0.018, d * 0.30),
			rgb(102, 43, 43), Mat.Sand, -5, i * 12 - 25, 5, "Ball")
		reliefProp(m, "Peau relevée du chapeau", Vp(d * 0.34, d * 0.12, d * 0.25), p + Vp(-d * 0.24, h + d * 0.19, d * 0.13),
			rgb(203, 106, 71), Mat.Sand, 6, -18, i * 5 - 9, "Ball")
		reliefProp(m, "Collerette froissée", Vp(d * 0.45, d * 0.16, d * 0.40), p + Vp(0.026, h * 0.69, 0.037),
			rgb(234, 213, 162), Mat.Sand, -7, 0, 5, "Ball")
		detailProp(m, "Lèvre rouge brisée", Vp(d * 0.77, d * 0.16, d * 0.23), p + Vp(-0.012, h + 0.01, d * 0.33),
			rgb(107, 51, 51), Mat.Sand, Vp(3, -8 * i, 7 - i * 2), "Wedge")
		detailProp(m, "Crête éclairée du chapeau", Vp(d * 0.57, d * 0.18, d * 0.49), p + Vp(-d * 0.1, h + d * 0.22, -d * 0.1),
			rgb(193, 82, 62), Mat.Sand, Vp(-3, 11 * i, -7), "Ball")
		for j = -1, 1 do
			P(m, "Moucheture", Vp(d * 0.13, 0.036, d * 0.113), p + Vp(d * j * 0.22, h + d * 0.25, d * (j % 2) * 0.09),
				LIN, Mat.Sand, { forme = "Ball", collide = false })
		end
	end
	detailProp(m, "Mousse à la naissance des pieds", Vp(0.68, 0.13, 0.52), Vp(0.045, 0.07, 0.074), rgb(103,130,76), Mat.Grass, Vp(5, -4, 4), "Ball")
	detailProp(m, "Pointe vert frais", Vp(0.35, 0.122, 0.29), Vp(-0.13, 0.10, 0.21), rgb(136,145,83), Mat.Grass, Vp(5, -9, -6), "Wedge")
	detailProp(m, "Motte sombre sous les pieds", Vp(0.39, 0.102, 0.28), Vp(0.28, 0.056, 0.27), rgb(84,103,66), Mat.Grass, Vp(4, 17, -5), "Ball")
	fini(m)
end

function PROPS_VALDOR.Touffe()
	local m = nouveau("Touffe")
	for i = 1, 7 do
		local a = i * 2.4
		local r = i % 3 * 0.13
		local tige = Vp(math.cos(a), 0, math.sin(a))
		lienProp(m, "Brin", tige * r + Vp(0, -0.18, 0), tige * (r + 0.14) + Vp(0, 0.52 + i % 4 * 0.18, 0),
			0.105, 0.067, rgb(84 + i * 3, 123 + i * 3, 68), Mat.Grass, false)
	end
	reliefProp(m, "Cœur sombre gainé", Vp(0.37, 0.40, 0.32), Vp(-0.01, 0.13, -0.02), MOUSSE_SOMBRE, Mat.Grass, 5, -6, -4, "Wedge")
	lienProp(m, "Feuille pliée claire", Vp(-0.16, 0.19, -0.04), Vp(-0.40, 0.61, 0.16), 0.16, 0.075, MOUSSE_CLAIRE, Mat.Grass, false)
	lienProp(m, "Brin de paille couché", Vp(0.14, 0.29, -0.02), Vp(0.36, 0.18, -0.27), 0.13, 0.073, CHAUME, Mat.Grass, false)
	reliefProp(m, "Languette de feuille froissée", Vp(0.19, 0.26, 0.12), Vp(-0.35, 0.60, 0.14), MOUSSE, Mat.Grass, 7, 10, 25, "Wedge")
	detailProp(m, "Éventail de feuilles sur le pied", Vp(0.61, 0.18, 0.59), Vp(-0.009, 0.13, 0.02), rgb(69,104,64), Mat.Grass, Vp(-4, 5, 3), "Ball")
	detailProp(m, "Lame jeune en avant", Vp(0.17, 0.58, 0.095), Vp(-0.18, 0.47, 0.26), rgb(137,165,82), Mat.Grass, Vp(-7, 14, 17), "Wedge")
	detailProp(m, "Lame pincée en arrière", Vp(0.14, 0.56, 0.088), Vp(0.20, 0.55, -0.19), rgb(75,111,64), Mat.Grass, Vp(7, 25, -17), "Wedge")
	detailProp(m, "Pointe déchirée en retour", Vp(0.19, 0.24, 0.068), Vp(-0.25, 0.71, 0.29), rgb(162,168,86), Mat.Grass, Vp(7, 14, 23), "Wedge")
	detailProp(m, "Pointe sèche sous l’éventail", Vp(0.11, 0.27, 0.085), Vp(0.14, 0.23, 0.25), rgb(145,127,69), Mat.Grass, Vp(-7, -19, -24), "Wedge")
	fini(m)
end

function PROPS_VALDOR.Sol_Laboure()
	local m = nouveau("Sol_Laboure")
	P(m, "Terre", Vp(3.8, 0.4, 3.8), Vp(0, 0.1, 0), rgb(109, 77, 53), Mat.Ground, { collide = false })
	for i = -1, 1 do
		for j = -1, 1 do
			P(m, "Sillon", Vp(1.22, 0.19 + (i + j) % 3 * 0.044, 0.47), Vp(j * 1.19, 0.35, i * 1.10 + (i + j) % 2 * 0.061),
				rgb(95 + j * 4, 62 + j * 2, 43), Mat.Ground, { forme = "Ball", collide = false })
		end
	end
	for i, profil in { { -1.06, 0.44, -1.12 }, { 0.16, 0.46, -1.02 }, { 0.96, 0.44, -0.97 }, { -0.61, 0.40, 0.05 },
		{ 0.22, 0.42, 0.06 }, { -0.97, 0.43, 1.16 }, { 0.81, 0.43, 1.13 } } do
		reliefProp(m, "Crête de sillon émiettée", Vp(0.75 - i % 3 * 0.089, 0.13, 0.31), Vp(profil[1], profil[2], profil[3]),
			i % 3 == 0 and BOIS_FONCE or rgb(140, 101, 65), Mat.Ground, 5, i % 3 * 6 - 6, i % 3 * 5 - 5, "Ball")
	end
	reliefProp(m, "Caillou retourné par la charrue", Vp(0.34, 0.16, 0.28), Vp(1.52, 0.37, -1.37), PIERRE_CLAIRE, Mat.Slate, 6, -19, 5, "Wedge")
	lienProp(m, "Radicelle rompue", Vp(-1.0, 0.36, 0.95), Vp(-0.53, 0.39, 0.56), 0.10, 0.062, BOIS_CLAIR, Mat.Wood, false)
	detailProp(m, "Crête de sillon fraîche", Vp(2.06, 0.12, 0.39), Vp(-0.21, 0.443, 1.10), rgb(143,98,66), Mat.Ground, Vp(0, 3, -3), "Ball")
	detailProp(m, "Tranchée de terre mouillée", Vp(2.94, 0.075, 0.39), Vp(-0.14, 0.33, 0.56), rgb(71,55,43), Mat.Ground, Vp(-3, 2, 0))
	detailProp(m, "Tête de sillon rompue", Vp(0.56, 0.16, 0.38), Vp(0.93, 0.40, 1.19), rgb(121,85,58), Mat.Ground, Vp(6, 13, -6), "Wedge")
	detailProp(m, "Motte claire du soc", Vp(0.44, 0.18, 0.43), Vp(1.21, 0.422, -1.07), rgb(145,101,72), Mat.Ground, Vp(5, -15, 6), "Wedge")
	detailProp(m, "Motte retournée sombre", Vp(0.32, 0.12, 0.42), Vp(1.45, 0.36, -1.11), rgb(81,61,47), Mat.Ground, Vp(4, -19, -5), "Ball")
	fini(m)
end

function PROPS_VALDOR.Terre_Retournee()
	local m = nouveau("Terre_Retournee")
	P(m, "Terre", Vp(2.89, 0.39, 4.80), Vp(0, 0.19, 0), rgb(104, 73, 51), Mat.Ground,
		{ forme = "Ball", collide = false })
	for i = -2, 2 do
		P(m, "Motte", Vp(1.33, 0.18 + i % 2 * 0.05, 1.46), Vp(i % 2 * 0.18 - 0.08, 0.29, i * 0.76),
			rgb(110 + i * 3, 73 + i * 2, 51), Mat.Ground, { forme = "Ball", collide = false })
	end
	reliefProp(m, "Lèvre de terre fraîche", Vp(0.89, 0.21, 1.37), Vp(-0.38, 0.34, 0.45), rgb(142, 99, 63), Mat.Ground, 4, -6, -4, "Ball")
	reliefProp(m, "Cassure sous la lèvre", Vp(0.64, 0.16, 0.98), Vp(-0.46, 0.32, 0.70), BOIS_FONCE, Mat.Ground, 7, 5, 6, "Wedge")
	reliefProp(m, "Motte fendue claire", Vp(0.57, 0.24, 0.74), Vp(0.41, 0.36, -0.64), rgb(137, 99, 70), Mat.Ground, -5, 22, -6, "Wedge")
	reliefProp(m, "Moitié sombre de la motte", Vp(0.44, 0.19, 0.55), Vp(0.55, 0.32, -0.41), BOIS_FONCE, Mat.Ground, -5, 5, 5, "Ball")
	lienProp(m, "Racine blanchie à nu", Vp(-0.30, 0.45, 0.37), Vp(0.24, 0.32, 0.76), 0.09, 0.078, BOIS_CLAIR, Mat.Wood, false)
	detailProp(m, "Crête fraîche du labour", Vp(1.15, 0.16, 1.64), Vp(-0.07, 0.393, -0.54), rgb(146,97,65), Mat.Ground, Vp(-3, -8, 4), "Ball")
	detailProp(m, "Marche noircie en travers", Vp(1.30, 0.11, 0.24), Vp(0.02, 0.315, 0.59), rgb(72,53,41), Mat.Ground, Vp(5, -6, -5))
	detailProp(m, "Revers de la motte", Vp(0.83, 0.18, 0.56), Vp(-0.34, 0.373, 0.28), rgb(132,89,61), Mat.Ground, Vp(6, 17, 7), "Wedge")
	detailProp(m, "Pointe craquelée", Vp(0.51, 0.19, 0.48), Vp(0.35, 0.35, 1.12), rgb(149,103,71), Mat.Ground, Vp(-5, -12, -7), "Wedge")
	detailProp(m, "Éclat remonté de la terre", Vp(0.40, 0.15, 0.34), Vp(0.49, 0.30, -0.87), rgb(149,130,105), Mat.Slate, Vp(4, 6, -5), "Wedge")
	fini(m)
end

-- Tableau de village : deux poteaux, un auvent et une planche couverte de parchemins.
-- L'invite se fixe à « Planche ».
local function construireTableauQuetes(): Model
	local m = nouveau("Tableau_Quetes")
	local PARCH = rgb(236, 220, 176)
	for _, x in { -3.2, 3.2 } do
		P(m, "Socle", Vp(0.98, 0.44, 0.96), Vp(x, 0.22, 0), PIERRE, Mat.Cobblestone)
		P(m, "Poteau", Vp(0.76, 7.25, 0.76), Vp(x, 4.02, 0), BOIS, Mat.Wood)
		rivetProp(m, Vp(x, 5.98, 0.39), 0.15)
	end
	P(m, "Planche", Vp(6.2, 3.8, 0.29), Vp(0, 4, 0), BOIS_CLAIR, Mat.WoodPlanks)
	lamesProp(m, "Bardage", Vp(6.2, 3.86, 0.09), Vp(0, 4, 0.153), 5, "X", BOIS_CLAIR)
	P(m, "Cadre", Vector3.new(6.6, 0.4, 0.6), Vector3.new(0, 6.05, 0), BOIS_FONCE, Mat.Wood)
	P(m, "Cadre", Vector3.new(6.6, 0.4, 0.6), Vector3.new(0, 1.95, 0), BOIS_FONCE, Mat.Wood)
	toitureProp(m, 7.78, 2.52, 7.52, 0.77, 0, false)
	P(m, "Entrait", Vp(7.11, 0.29, 0.28), Vp(0, 7.57, 0), BOIS_FONCE, Mat.Wood)
	for _, x in { -3.2, 3.2 } do
		P(m, "Poinçon", Vp(0.24, 0.73, 0.25), Vp(x, 7.94, 0), BOIS_FONCE, Mat.Wood)
		for _, z in { -1.16, 1.16 } do
			lienProp(m, "Chevron", Vp(x, 7.51, z), Vp(x, 8.28, 0), 0.18, 0.17, BOIS, Mat.Wood)
		end
	end
	-- parchemins épinglés (légèrement de travers) et leurs cachets
	local spots = { { -2.1, 4.9, 4 }, { -0.4, 5.1, -6 }, { 1.6, 4.8, 7 }, { -1.5, 3.1, -3 }, { 1.69, 3.2, -8 } }
	for i, sp in spots do
		local cf = CFrame.new(sp[1], sp[2], 0.24) * CFrame.Angles(0, 0, math.rad(sp[3]))
		P(m, "Parchemin", Vector3.new(1.3, 1.5, 0.06), Vector3.zero, PARCH:Lerp(rgb(214, 196, 150), (i % 3) / 3), Mat.Fabric, { cf = cf, collide = false })
		P(m, "Lignes", Vector3.new(0.9, 0.08, 0.02), Vector3.zero, rgb(120, 100, 80), Mat.Fabric, { cf = cf * CFrame.new(0, 0.3, 0.04), collide = false })
		P(m, "Lignes", Vector3.new(0.9, 0.08, 0.02), Vector3.zero, rgb(120, 100, 80), Mat.Fabric, { cf = cf * CFrame.new(0, 0.05, 0.04), collide = false })
		P(m, "Cachet", Vector3.new(0.12, 0.3, 0.3), Vector3.zero, GARANCE, Mat.CeramicTiles,
			{ cf = cf * CFrame.new(0, -0.45, 0.05) * CFrame.Angles(0, math.rad(90), 0), forme = "Cylinder", collide = false })
	end
	local enseigneVillage = P(m, "Enseigne", Vector3.new(6.0, 0.88, 0.36), Vector3.new(0, 6.84, 0),
		BOIS_FONCE, Mat.WoodPlanks, { collide = false })
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local surface = Instance.new("SurfaceGui")
		surface.Face, surface.LightInfluence, surface.MaxDistance = face, 0.45, 95
		surface.CanvasSize = Vector2.new(480, 72)
		surface.Parent = enseigneVillage
		local nom = Instance.new("TextLabel")
		nom.BackgroundTransparency, nom.TextScaled = 1, true
		nom.Size, nom.Position = UDim2.fromScale(0.94, 0.77), UDim2.fromScale(0.03, 0.115)
		nom.Font, nom.TextColor3, nom.Text = Enum.Font.Fondamento, PARCH, "Place du village"
		nom.Parent = surface
	end
	P(m, "Caisse", Vp(1.6, 1.15, 1.2), Vp(2.6, 0.575, 1.045), BOIS_CLAIR, Mat.WoodPlanks)
	lamesProp(m, "Couvercle", Vp(1.57, 0.12, 1.20), Vp(2.6, 1.17, 1.045), 3, "X", BOIS)
	for _, x in { 1.94, 3.25 } do
		P(m, "Cornière", Vp(0.19, 1.15, 0.15), Vp(x, 0.585, 1.605), BOIS_FONCE, Mat.Wood)
		rivetProp(m, Vp(x, 1.05, 1.685), 0.11)
	end
	attache(m.PrimaryPart, "Devant", CFrame.new(0, 0, 4))
	for i, x in { -3.15, -2.42, -1.55, -0.71, 0.11, 1.03, 1.85, 2.59, 3.29 } do
		reliefProp(m, "Bardeau fendu de l’auvent", Vp(0.87, 0.09, 0.35), Vp(x, 7.69 + i % 3 * 0.035, 1.04 - i % 2 * 0.07),
			({ BOIS_FONCE, BOIS, BOIS_CLAIR })[i % 3 + 1], Mat.Wood, 34, 0, i % 3 * 4 - 4)
	end
	for i, sp in spots do
		reliefProp(m, "Revers du parchemin roulé", Vp(1.18, 0.145, 0.14),
			Vp(sp[1], sp[2] - 0.64, 0.30), LIN, Mat.Fabric, 0, 0, sp[3])
		reliefProp(m, "Coin déchiré du parchemin", Vp(0.29, 0.29, 0.085),
			Vp(sp[1] - 0.47, sp[2] + 0.57, 0.28), i % 2 == 0 and PARCH or rgb(184, 153, 112), Mat.Fabric, -5, 0, sp[3] - 6, "Wedge")
	end
	for _, x in { -3.1, 3.1 } do
		reliefProp(m, "Virole du poteau", Vp(0.82, 0.23, 0.78), Vp(x, 0.93, 0), FER, Mat.Metal)
		reliefProp(m, "Aile du cadre ouvragé", Vp(0.31, 3.43, 0.16), Vp(x, 4.08, 0.24), BOIS_FONCE, Mat.Wood, 0, 0, x)
		lienProp(m, "Console de l’auvent", Vp(x, 5.99, 0.08), Vp(x, 7.55, 0.91), 0.23, 0.22, BOIS_CLAIR, Mat.Wood, false)
	end
	reliefProp(m, "Liseré d’enseigne", Vp(5.81, 0.095, 0.38), Vp(0.025, 7.26, 0), LAITON, Mat.Metal, 0, 0, 1)

	for i, x in { -3.27, -2.39, -1.39, -0.43, 0.62, 1.53, 2.55, 3.32 } do
		local z = 1.14 + (i % 3 - 1) * 0.04
		detailProp(m, "Languette de bardeau", Vp(0.88, 0.18, 0.49), Vp(x, 7.58 + i % 2 * 0.038, z),
			({ BOIS_FONCE, rgb(151, 87, 63), rgb(184, 115, 76) })[i % 3 + 1], Mat.Wood, Vp(31, i - 5, i % 3 - 2))
	end
	for _, x in { -3.17, 3.17 } do
		lienProp(m, "Crosse de l’auvent", Vp(x, 6.53, 0.20), Vp(x * 0.70, 7.55, 0.22), 0.25, 0.27, BOIS, Mat.Wood, false)
		detailProp(m, "Bouclier d’angle forgé", Vp(0.46, 0.49, 0.12), Vp(x, 6.66, 0.397), FER, Mat.Metal, Vp(0, 0, 5))
		detailProp(m, "Épaulement de pierre", Vp(0.85, 0.17, 0.84), Vp(x, 0.42, 0.02), CALCAIRE, Mat.Slate, Vp(0, 4, 2))
		detailProp(m, "Mousse de pied", Vp(0.50, 0.15, 0.43), Vp(x + 0.13, 0.42, 0.275), rgb(98, 122, 74), Mat.Grass, Vp(3, -7, 5))
	end
	for i, x in { -2.1, -0.4, 1.6, -1.5, 1.69 } do
		local haut = (i <= 3 and 5.0 or 3.18) - i % 3 * 0.11
		detailProp(m, "Bord de parchemin déchiré", Vp(0.27, 0.47, 0.065), Vp(x + 0.55, haut - 0.48, 0.275),
			i % 2 == 0 and PARCH or rgb(200, 169, 123), Mat.Fabric, Vp(0, 0, i * 3 - 8), "Wedge")
		detailProp(m, "Punaise de parchemin", Vp(0.13, 0.13, 0.094), Vp(x - 0.25, haut + 0.63, 0.27),
			OR, Mat.Metal, Vp(0, 0, i * 7))
	end
	fini(m)
	return m
end

function PROPS_VALDOR.Tableau_Quetes() construireTableauQuetes() end

function M.tableauQuetes()
	dossier = dossierModeles()
	return construireTableauQuetes()
end

local NOMS_SOL = {
	"Rocher", "Caillou", "Branche", "Buisson", "Tronc_Couche", "Fleurs", "Champignon",
	"Touffe", "Coffre", "Sol_Laboure", "Terre_Retournee",
}

local NOMS_ARTISANAT = {
	"Fourneau", "Plancher", "Mur_Planches", "Mur_Porte", "Mur_Pierre", "Mur_Briques", "Toit_Chaume", "Lit_Joueur", "Lanterne",
}
local NOMS_SECURITE = {
	"Porte", "Cloche_Alarme", "Mur_Fenetre", "Escalier_Bois", "Table_Bois", "Chaise", "Tapis", "Pot_Fleurs",
	"Etagere", "Banc", "Moulin", "Arroseur", "Ruche", "Caserne", "Embarcadere", "Etal", "Serrure_Entrainement",
}
local NOMS_DECOR = {
	"Fontaine", "Puits", "Lampadaire", "Panneau", "Tonneaux", "Caisses", "Epouvantail", "Botte_Foin", "Boite_Lettres",
	"Cloture", "Feu_Camp", "Etabli", "Coffre_Joueur",
}
local NOMS_STATIONS = { "Enclume", "Metier_Tisser", "Bac_Tannage", "Alambic", "Abreuvoir", "Mangeoire", "Scierie" }

local function reconstruireProps(noms: {string})
	dossier = dossierModeles()
	for _, nom in noms do PROPS_VALDOR[nom]() end
end

-- Édition : un nom cible uniquement ce modèle. Sans nom, reconstruire le lot.
function M.propsValdor(nom: string?): number
	if nom then
		local construire = assert(PROPS_VALDOR[nom], "Prop de Valdor inconnu : " .. nom)
		dossier = dossierModeles()
		construire()
		return 1
	end
	dossier = dossierModeles()
	local n = 0
	for _, construire in PROPS_VALDOR do
		construire()
		n += 1
	end
	return n
end

function M.puits() M.propsValdor("Puits") end

local function decor() reconstruireProps(NOMS_DECOR) end



-- Fin des props de Valdor.

function M.artisanat()
	dossier = dossierModeles()
	filon("Filon_Charbon", rgb(34, 32, 36), Mat.Slate)
	filon("Filon_Cuivre", rgb(214, 124, 72), Mat.Metal)
	filon("Filon_Fer", rgb(222, 200, 180), Mat.Metal)
	M.filonOr()
	do
		local m = nouveau("Argile")
		local c1, c2 = rgb(176, 108, 78), rgb(150, 92, 66)
		P(m, "Motte", Vector3.new(3.6, 1.2, 3), Vector3.new(0, 0.6, 0), c1, Mat.Mud, { rot = CFrame.Angles(0, 0.3, 0) })
		P(m, "Motte", Vector3.new(2.2, 1.6, 2), Vector3.new(0.9, 1, 0.5), c2, Mat.Mud, { rot = CFrame.Angles(0.15, 0.8, 0) })
		P(m, "Motte", Vector3.new(1.8, 1, 1.8), Vector3.new(-1.4, 0.5, -0.7), c2, Mat.Mud, { rot = CFrame.Angles(0, 0.5, 0.1) })
		fini(m)
	end
	reconstruireProps(NOMS_ARTISANAT)
end

function M.animauxFerme()
	dossier = dossierModeles()
	local function forme(m: Model, nom: string, taille: Vector3, pos: Vector3, couleur: Color3, options: Opts?)
		local o: Opts = options or {}
		o.collide = false
		return P(m, nom, taille, pos, couleur, Mat.SmoothPlastic, o)
	end
	local function yeux(m: Model, x: number, y: number, z: number)
		for _, cote in { -1, 1 } do
			forme(m, "Œil", Vector3.new(0.17, 0.16, 0.1), Vector3.new(cote * x, y, z), rgb(39, 27, 26))
		end
	end

	-- Cochon (27/11, Claude : l'ancien corps en sphère laissait les pattes flotter sous sa courbe) : blocs
	-- empilés, pattes ENFONCÉES dans le ventre, 3 tons de rose, groin et oreilles lisibles, queue en tire-bouchon.
	local cochon = nouveau("Cochon")
	local rose, roseClair, roseSombre = rgb(222, 152, 140), rgb(242, 186, 174), rgb(186, 116, 108)
	local groin, sabot = rgb(246, 176, 168), rgb(92, 60, 54)
	forme(cochon, "Corps", Vector3.new(2.1, 1.5, 3), Vector3.new(0, 1.5, 0.2), rose)
	forme(cochon, "Dos", Vector3.new(1.7, 0.3, 2.6), Vector3.new(0, 2.35, 0.25), roseSombre)
	forme(cochon, "Ventre", Vector3.new(1.8, 0.3, 2.4), Vector3.new(0, 0.82, 0.2), roseClair)
	forme(cochon, "Croupe", Vector3.new(1.9, 1.3, 0.4), Vector3.new(0, 1.55, 1.75), roseSombre)
	forme(cochon, "Tache", Vector3.new(0.05, 0.6, 0.8), Vector3.new(1.06, 1.7, 0.6), roseSombre)
	forme(cochon, "Tête", Vector3.new(1.5, 1.3, 1.2), Vector3.new(0, 1.7, -1.65), rose)
	forme(cochon, "Front", Vector3.new(1.3, 0.3, 1), Vector3.new(0, 2.42, -1.6), roseSombre)
	forme(cochon, "Joues", Vector3.new(1.6, 0.5, 0.9), Vector3.new(0, 1.25, -1.7), roseClair)
	forme(cochon, "Groin", Vector3.new(0.9, 0.62, 0.45), Vector3.new(0, 1.55, -2.42), groin)
	yeux(cochon, 0.42, 1.98, -2.27)
	for _, cote in { -1, 1 } do
		forme(cochon, "Narine", Vector3.new(0.16, 0.2, 0.06), Vector3.new(cote * 0.2, 1.58, -2.66), sabot)
		forme(cochon, "Oreille", Vector3.new(0.5, 0.18, 0.55), Vector3.new(cote * 0.55, 2.45, -1.95), roseSombre,
			{ rot = CFrame.Angles(math.rad(25), 0, cote * math.rad(-20)) })
		for _, z in { -0.85, 1.15 } do
			-- la patte monte dans le corps (haut à 1,25 > bas du ventre 0,75) : jamais de vide
			forme(cochon, "Patte", Vector3.new(0.5, 1.05, 0.5), Vector3.new(cote * 0.62, 0.72, z), rose)
			forme(cochon, "Sabot", Vector3.new(0.54, 0.24, 0.56), Vector3.new(cote * 0.62, 0.12, z - 0.02), sabot)
		end
	end
	local function pointQueue(a: number): Vector3
		return Vector3.new(math.cos(a) * 0.2, 1.95 + math.sin(a) * 0.2, 1.98 + a * 0.05)
	end
	for i = 0, 7 do
		local a, b = pointQueue(i * math.pi / 4), pointQueue((i + 1) * math.pi / 4)
		forme(cochon, "Queue", Vector3.new(0.14, 0.14, (b - a).Magnitude + 0.04), Vector3.zero, roseSombre,
			{ cf = CFrame.lookAt((a + b) / 2, b) })
	end
	fini(cochon)

	-- Oie (27/11, Claude : l'ancienne n'était qu'une pile de sphères) : blocs, cou en trois segments qui se
	-- chevauchent, ailes repliées en 2 tons, bec et pattes orange, palmes au sol.
	local oie = nouveau("Oie")
	local blanc, plume, gris, orange = rgb(246, 242, 228), rgb(222, 216, 200), rgb(176, 172, 160), rgb(232, 146, 60)
	forme(oie, "Corps", Vector3.new(1.4, 1.15, 2.4), Vector3.new(0, 1.2, 0.25), blanc)
	forme(oie, "Poitrail", Vector3.new(1.2, 0.95, 0.5), Vector3.new(0, 1.3, -1.0), blanc)
	forme(oie, "Ventre", Vector3.new(1.2, 0.25, 2), Vector3.new(0, 0.66, 0.3), plume)
	forme(oie, "Queue", Vector3.new(0.9, 0.4, 0.7), Vector3.new(0, 1.55, 1.65), plume, { rot = CFrame.Angles(math.rad(-20), 0, 0) })
	forme(oie, "Queue", Vector3.new(0.6, 0.3, 0.35), Vector3.new(0, 1.78, 1.98), gris, { rot = CFrame.Angles(math.rad(-30), 0, 0) })
	forme(oie, "Cou bas", Vector3.new(0.55, 0.8, 0.55), Vector3.new(0, 1.95, -1.05), blanc, { rot = CFrame.Angles(math.rad(-15), 0, 0) })
	forme(oie, "Cou", Vector3.new(0.45, 0.8, 0.45), Vector3.new(0, 2.55, -1.18), blanc)
	forme(oie, "Tête", Vector3.new(0.6, 0.55, 0.75), Vector3.new(0, 3.05, -1.3), blanc)
	forme(oie, "Bec", Vector3.new(0.36, 0.2, 0.55), Vector3.new(0, 2.95, -1.88), orange)
	forme(oie, "Bec bas", Vector3.new(0.3, 0.1, 0.4), Vector3.new(0, 2.82, -1.8), rgb(200, 120, 50))
	yeux(oie, 0.31, 3.12, -1.45)
	for _, cote in { -1, 1 } do
		forme(oie, "Aile", Vector3.new(0.2, 0.8, 1.8), Vector3.new(cote * 0.75, 1.3, 0.35), plume)
		forme(oie, "Remige", Vector3.new(0.18, 0.4, 0.9), Vector3.new(cote * 0.77, 1.15, 1.05), gris)
		forme(oie, "Patte", Vector3.new(0.14, 0.7, 0.14), Vector3.new(cote * 0.32, 0.4, 0.2), orange)
		forme(oie, "Palme", Vector3.new(0.45, 0.1, 0.55), Vector3.new(cote * 0.32, 0.05, 0.0), orange)
	end
	fini(oie)
	return cochon, oie
end

-- Chèvre seule, pour compléter les modèles de ferme en Édition.
function M.chevre(): Model
	dossier = dossierModeles()
	local m = nouveau("Chevre")
	local pelage, masque = rgb(232, 220, 190), rgb(178, 145, 105)
	local corne, sabot = rgb(129, 113, 94), rgb(73, 59, 50)
	-- 27/11, Claude : l'ancienne chèvre n'était faite que de sphères (pattes comprises : « des boules ») ; blocs
	-- empilés comme la vache et le mouton, pattes enfoncées dans le corps, toison en mèches, cornes conservées.
	local clair, ombre = rgb(244, 236, 212), rgb(204, 190, 160)
	local function bloc(nom: string, taille: Vector3, pos: Vector3, couleur: Color3, rot: CFrame?)
		P(m, nom, taille, pos, couleur, Mat.SmoothPlastic, { rot = rot, collide = false })
	end
	bloc("Corps", Vector3.new(1.5, 1.3, 2.6), Vector3.new(0, 1.95, 0.25), pelage)
	bloc("Dos", Vector3.new(1.2, 0.25, 2.3), Vector3.new(0, 2.7, 0.25), clair)
	bloc("Ventre", Vector3.new(1.3, 0.25, 2.1), Vector3.new(0, 1.28, 0.25), ombre)
	for i, z in { -0.6, 0.2, 1 } do
		bloc("Meche", Vector3.new(1.62, 0.35, 0.5), Vector3.new(0, 1.45 + (i % 2) * 0.1, z), ombre)
	end
	bloc("Cou", Vector3.new(0.7, 1.1, 0.7), Vector3.new(0, 2.55, -1.05), pelage, CFrame.Angles(math.rad(-25), 0, 0))
	bloc("Tête", Vector3.new(0.85, 0.85, 1.0), Vector3.new(0, 3.05, -1.55), pelage)
	bloc("Museau", Vector3.new(0.65, 0.5, 0.55), Vector3.new(0, 2.8, -2.2), masque)
	bloc("Truffe", Vector3.new(0.34, 0.14, 0.08), Vector3.new(0, 2.92, -2.48), sabot)
	bloc("Barbiche", Vector3.new(0.3, 0.6, 0.25), Vector3.new(0, 2.35, -2.25), masque)
	bloc("Queue", Vector3.new(0.3, 0.55, 0.3), Vector3.new(0, 2.6, 1.6), clair, CFrame.Angles(math.rad(35), 0, 0))
	for _, cote in { -1, 1 } do
		bloc("Oreille", Vector3.new(0.6, 0.16, 0.3), Vector3.new(cote * 0.62, 3.1, -1.4), masque, CFrame.Angles(0, 0, -cote * math.rad(25)))
		bloc("Œil", Vector3.new(0.06, 0.16, 0.18), Vector3.new(cote * 0.43, 3.15, -1.85), sabot)
		for _, z in { -0.75, 1.15 } do
			-- haut de patte à 1,55 > bas du ventre 1,3 : la patte entre dans le corps
			bloc("Patte", Vector3.new(0.34, 1.35, 0.36), Vector3.new(cote * 0.5, 0.88, z), pelage)
			bloc("Genou", Vector3.new(0.38, 0.2, 0.4), Vector3.new(cote * 0.5, 0.6, z), ombre)
			P(m, "Sabot", Vector3.new(0.38, 0.22, 0.42), Vector3.new(cote * 0.5, 0.11, z), sabot, Mat.SmoothPlastic, { collide = false })
		end
		local courbe = {
			Vector3.new(cote * 0.28, 3.4, -1.6),
			Vector3.new(cote * 0.34, 3.75, -1.48),
			Vector3.new(cote * 0.4, 4.0, -1.25),
			Vector3.new(cote * 0.44, 4.12, -0.98),
		}
		for i, diametre in { 0.25, 0.19, 0.12 } do
			local a, b = courbe[i], courbe[i + 1]
			P(m, "Corne", Vector3.new((b - a).Magnitude + 0.05, diametre, diametre), Vector3.zero, corne, Mat.SmoothPlastic,
				{ forme = "Cylinder", cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), collide = false })
		end
	end
	fini(m)
	return m
end

-- Slimes (27/11, Claude : ils n'avaient pas de constructeur sur disque, seulement deux cubes dans la place) :
-- corps translucide à arêtes adoucies, noyau sombre visible, yeux et bouche, reflet, gouttes au sol.
function M.slimes()
	dossier = dossierModeles()
	for nom, c in { Slime = { rgb(110, 210, 90), rgb(60, 140, 50) }, Slime_Bleu = { rgb(90, 170, 240), rgb(40, 90, 170) } } do
		local old = dossier:FindFirstChild(nom)
		if old then
			old:Destroy()
		end
		local m = nouveau(nom)
		local function S(n: string, t: Vector3, pos: Vector3, col: Color3, mat: Enum.Material, tr: number?)
			local q = P(m, n, t, pos, col, mat, { collide = false })
			q.Transparency = tr or 0
			return q
		end
		S("Corps", Vector3.new(2.4, 1.9, 2.4), Vector3.new(0, 1.05, 0), c[1], Mat.Glass, 0.25)
		S("Dôme", Vector3.new(1.9, 0.5, 1.9), Vector3.new(0, 2.15, 0), c[1], Mat.Glass, 0.25)
		S("Bourrelet", Vector3.new(2.7, 0.4, 2.7), Vector3.new(0, 0.25, 0), c[1], Mat.Glass, 0.3)
		S("Coeur", Vector3.new(1, 0.9, 1), Vector3.new(0.15, 1, 0.3), c[2], Mat.SmoothPlastic, 0.1)
		S("Reflet", Vector3.new(0.5, 0.25, 0.05), Vector3.new(-0.6, 1.7, -1.22), Color3.new(1, 1, 1), Mat.Neon, 0.2)
		for _, sx in { -1, 1 } do
			S("Oeil", Vector3.new(0.34, 0.42, 0.06), Vector3.new(sx * 0.45, 1.35, -1.22), rgb(20, 24, 20), Mat.SmoothPlastic)
			S("Pupille", Vector3.new(0.12, 0.12, 0.04), Vector3.new(sx * 0.4, 1.45, -1.26), Color3.new(1, 1, 1), Mat.Neon)
		end
		S("Bouche", Vector3.new(0.6, 0.12, 0.05), Vector3.new(0, 0.95, -1.22), rgb(20, 24, 20), Mat.SmoothPlastic)
		for i = 0, 2 do
			local a = i * 2.1
			S("Goutte", Vector3.new(0.35, 0.18, 0.35), Vector3.new(math.cos(a) * 1.5, 0.09, math.sin(a) * 1.5), c[1], Mat.Glass, 0.25)
		end
		fini(m)
	end
end

-- Bêtes qui n'existaient que dans la place (27/11, Claude) : myconides, yéti, ours — mêmes dimensions qu'avant,
-- mêmes noms de pièces (Corps, Chapeau, Tete, Oeil…), blocs à 3 tons, visage lisible.
function M.betesFaitesMain()
	dossier = dossierModeles()
	local function neuf(nom: string): Model
		local old = dossier:FindFirstChild(nom)
		if old then
			old:Destroy()
		end
		return nouveau(nom)
	end
	local function B(m: Model, n: string, t: Vector3, pos: Vector3, c: Color3, mat: Enum.Material?, rot: CFrame?)
		return P(m, n, t, pos, c, mat or Mat.SmoothPlastic, { collide = false, rot = rot })
	end
	-- Myconide (k = échelle : 1 = petit, 2,2 = ancien, couvert de mousse)
	local function myconide(nom: string, k: number, ancien: boolean)
		local m = neuf(nom)
		local cap1, cap2, cap3 = rgb(196, 70, 60), rgb(160, 52, 46), rgb(236, 226, 210)
		local pied, ombre = rgb(232, 220, 196), rgb(196, 180, 150)
		local function b(n, t, pos, c, mat, rot) return B(m, n, t * k, pos * k, c, mat, rot) end
		b("Corps", Vector3.new(1.6, 2, 1.4), Vector3.new(0, 1.55, 0), pied)
		b("Ventre", Vector3.new(1.3, 1.2, 0.1), Vector3.new(0, 1.4, -0.72), ombre)
		b("Chapeau", Vector3.new(3.4, 0.9, 3.4), Vector3.new(0, 3.05, 0), cap1)
		b("Chapeau", Vector3.new(2.6, 0.6, 2.6), Vector3.new(0, 3.75, 0), cap2)
		b("Lamelles", Vector3.new(3.0, 0.15, 3.0), Vector3.new(0, 2.55, 0), ombre)
		for i, pos in { { 1, 3.62, 0.9 }, { -1.1, 3.6, -0.6 }, { 0.3, 4.08, -0.5 }, { -0.5, 3.6, 1.2 } } do
			b("Point", Vector3.new(0.5, 0.12, 0.5), Vector3.new(pos[1], pos[2], pos[3]), cap3)
		end
		for _, sx in { -1, 1 } do
			b("Oeil", Vector3.new(0.28, 0.38, 0.08), Vector3.new(sx * 0.38, 2.05, -0.72), rgb(24, 20, 20))
			b("Pied", Vector3.new(0.55, 0.6, 0.7), Vector3.new(sx * 0.45, 0.3, 0), ombre)
			b("Bras", Vector3.new(0.35, 1.0, 0.35), Vector3.new(sx * 0.98, 1.6, 0), pied, nil, CFrame.Angles(0, 0, sx * 0.35))
		end
		b("Bouche", Vector3.new(0.5, 0.1, 0.08), Vector3.new(0, 1.65, -0.72), rgb(90, 50, 40))
		if ancien then
			for i = 0, 3 do
				local a = i * 1.6
				b("Mousse", Vector3.new(0.9, 0.2, 0.7), Vector3.new(math.cos(a) * 1.3, 3.55 + (i % 2) * 0.1, math.sin(a) * 1.3), rgb(86, 130, 60), Mat.Grass)
			end
			b("Barbe", Vector3.new(1.0, 0.7, 0.1), Vector3.new(0, 1.15, -0.76), rgb(110, 150, 80), Mat.Grass)
		end
		fini(m)
	end
	myconide("Myconide", 1, false)
	myconide("Myconide_Ancien", 2.2, true)
	-- Yéti : grand, fourrure en mèches sur 3 tons, face bleu-gris, cornes, griffes
	do
		local m = neuf("Yeti")
		local f1, f2, f3, face = rgb(236, 240, 246), rgb(206, 214, 226), rgb(170, 182, 200), rgb(120, 150, 178)
		B(m, "Corps", Vector3.new(3.4, 3.4, 2.1), Vector3.new(0, 5, 0), f1)
		B(m, "Ventre", Vector3.new(2.4, 2.2, 0.1), Vector3.new(0, 4.8, -1.06), f2)
		for i = 0, 3 do
			B(m, "Meche", Vector3.new(3.6, 0.4, 2.2), Vector3.new(0, 3.5 + i * 0.85, 0.05), i % 2 == 0 and f2 or f3)
		end
		B(m, "Tete", Vector3.new(2.2, 1.9, 1.9), Vector3.new(0, 7.6, -0.1), f1)
		B(m, "Visage", Vector3.new(1.5, 1.1, 0.12), Vector3.new(0, 7.45, -1.06), face)
		for _, sx in { -1, 1 } do
			B(m, "Oeil", Vector3.new(0.3, 0.22, 0.06), Vector3.new(sx * 0.38, 7.7, -1.13), rgb(20, 24, 40))
			B(m, "Corne", Vector3.new(0.3, 0.9, 0.3), Vector3.new(sx * 0.95, 8.7, 0), f3, nil, CFrame.Angles(0, 0, -sx * 0.45))
			B(m, "Bras", Vector3.new(1.0, 3.2, 1.0), Vector3.new(sx * 2.15, 4.9, 0), f2)
			B(m, "Poing", Vector3.new(1.15, 0.9, 1.15), Vector3.new(sx * 2.2, 3.0, 0), f3)
			for g = -1, 1 do
				B(m, "Griffe", Vector3.new(0.15, 0.35, 0.15), Vector3.new(sx * 2.2 + g * 0.3, 2.45, -0.4), rgb(60, 60, 70))
			end
			B(m, "Jambe", Vector3.new(1.2, 3.3, 1.2), Vector3.new(sx * 0.85, 1.65, 0), f2)
			B(m, "Pied", Vector3.new(1.4, 0.4, 1.7), Vector3.new(sx * 0.85, 0.2, -0.2), f3)
		end
		B(m, "Bouche", Vector3.new(0.8, 0.15, 0.06), Vector3.new(0, 7.15, -1.13), rgb(40, 30, 50))
		fini(m)
	end
	-- Mouton : toison en touffes sur 3 tons, tête et pattes sombres, toupet
	do
		local m = neuf("Mouton")
		local l1, l2, l3, noir = rgb(244, 240, 228), rgb(222, 216, 200), rgb(196, 188, 170), rgb(46, 40, 38)
		B(m, "Laine", Vector3.new(2.6, 2.1, 3.6), Vector3.new(0, 2.45, 0.3), l1)
		for i, z in { -1.0, 0.1, 1.2 } do
			B(m, "Laine", Vector3.new(2.8, 0.5, 0.9), Vector3.new(0, 3.55, z), i % 2 == 0 and l2 or l1)
			for _, sx in { -1, 1 } do
				B(m, "Laine", Vector3.new(0.25, 1.4, 0.9), Vector3.new(sx * 1.38, 2.5, z), l3)
			end
		end
		B(m, "Laine", Vector3.new(2.2, 0.4, 3.0), Vector3.new(0, 1.35, 0.3), l3)
		B(m, "Tete", Vector3.new(1.1, 1.2, 1.2), Vector3.new(0, 3.0, -1.95), noir)
		B(m, "Toupet", Vector3.new(1.2, 0.5, 0.9), Vector3.new(0, 3.75, -1.85), l2)
		for _, sx in { -1, 1 } do
			B(m, "Oeil", Vector3.new(0.18, 0.16, 0.06), Vector3.new(sx * 0.3, 3.2, -2.56), rgb(230, 220, 160))
			B(m, "Oreille", Vector3.new(0.6, 0.18, 0.3), Vector3.new(sx * 0.75, 3.25, -1.9), noir, nil, CFrame.Angles(0, 0, -sx * 0.3))
			for _, z in { -0.8, 1.3 } do
				B(m, "Patte", Vector3.new(0.4, 1.5, 0.4), Vector3.new(sx * 0.7, 0.85, z), noir)
			end
		end
		fini(m)
	end
	-- Vache : robe blanche à taches noires, mufle rose, cornes, pis, queue à touffe
	do
		local m = neuf("Vache")
		local blanc, noir, rose, corne = rgb(244, 242, 236), rgb(40, 36, 34), rgb(232, 170, 160), rgb(232, 222, 196)
		B(m, "Corps", Vector3.new(2.9, 2.5, 5.0), Vector3.new(0, 3.35, 0.5), blanc)
		B(m, "Echine", Vector3.new(2.5, 0.35, 4.6), Vector3.new(0, 4.75, 0.5), rgb(226, 222, 214))
		for i, t in { { 1.46, 3.5, -0.6, 1.4, 1.2 }, { -1.46, 3.2, 1.2, 1.6, 1.4 }, { 0, 4.62, 1.8, 1.2, 0.1 }, { 1.46, 2.9, 1.9, 1.0, 1.0 } } do
			B(m, "Tache", Vector3.new(t[5] == 0.1 and 1.6 or 0.06, t[5] == 0.1 and 0.06 or t[5], t[4]), Vector3.new(t[1], t[2], t[3]), noir)
		end
		B(m, "Pis", Vector3.new(1.0, 0.5, 0.9), Vector3.new(0, 1.85, 1.6), rose)
		B(m, "Tete", Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, 4.1, -2.65), blanc)
		B(m, "Tache", Vector3.new(0.9, 0.9, 0.06), Vector3.new(0.3, 4.4, -3.46), noir)
		B(m, "Museau", Vector3.new(1.4, 0.8, 0.5), Vector3.new(0, 3.55, -3.55), rose)
		B(m, "Queue", Vector3.new(0.2, 1.6, 0.2), Vector3.new(0, 3.6, 3.05), blanc)
		B(m, "Queue", Vector3.new(0.4, 0.5, 0.4), Vector3.new(0, 2.65, 3.1), noir)
		for _, sx in { -1, 1 } do
			B(m, "Oeil", Vector3.new(0.18, 0.22, 0.06), Vector3.new(sx * 0.45, 4.45, -3.47), rgb(20, 18, 18))
			B(m, "Corne", Vector3.new(0.6, 0.2, 0.2), Vector3.new(sx * 1.0, 5.0, -2.6), corne, nil, CFrame.Angles(0, 0, sx * 0.5))
			B(m, "Oreille", Vector3.new(0.55, 0.3, 0.2), Vector3.new(sx * 1.0, 4.55, -2.3), noir)
			for _, z in { -1.4, 2.3 } do
				B(m, "Patte", Vector3.new(0.6, 2.2, 0.6), Vector3.new(sx * 0.95, 1.3, z), blanc)
				B(m, "Sabot", Vector3.new(0.66, 0.3, 0.7), Vector3.new(sx * 0.95, 0.15, z), noir)
			end
		end
		fini(m)
	end
	-- Loups : collerette de fourrure, oreilles pointues, queue touffue, 3 tons
	for nom, c in { Loup = { rgb(120, 120, 128), rgb(90, 90, 98), rgb(176, 172, 166) }, Loup_Blanc = { rgb(232, 234, 238), rgb(196, 200, 210), rgb(250, 250, 250) } } do
		local m = neuf(nom)
		B(m, "Corps", Vector3.new(1.4, 1.4, 3.6), Vector3.new(0, 2.0, 0.4), c[1])
		B(m, "Echine", Vector3.new(1.0, 0.3, 3.2), Vector3.new(0, 2.8, 0.4), c[2])
		B(m, "Ventre", Vector3.new(1.2, 0.25, 2.6), Vector3.new(0, 1.28, 0.4), c[3])
		B(m, "Collerette", Vector3.new(1.6, 1.6, 0.8), Vector3.new(0, 2.25, -1.3), c[3])
		B(m, "Tete", Vector3.new(1.1, 1.0, 1.1), Vector3.new(0, 2.85, -2.0), c[1])
		B(m, "Museau", Vector3.new(0.6, 0.5, 0.8), Vector3.new(0, 2.6, -2.85), c[3])
		B(m, "Truffe", Vector3.new(0.25, 0.2, 0.1), Vector3.new(0, 2.8, -3.27), rgb(24, 22, 22))
		B(m, "Queue", Vector3.new(0.5, 0.5, 1.8), Vector3.new(0, 2.3, 2.9), c[2], nil, CFrame.Angles(math.rad(25), 0, 0))
		B(m, "Queue", Vector3.new(0.4, 0.4, 0.5), Vector3.new(0, 1.85, 3.8), c[3])
		for _, sx in { -1, 1 } do
			B(m, "Oeil", Vector3.new(0.14, 0.12, 0.06), Vector3.new(sx * 0.3, 3.05, -2.56), rgb(230, 190, 60), Mat.Neon)
			B(m, "Oreille", Vector3.new(0.25, 0.5, 0.2), Vector3.new(sx * 0.35, 3.55, -1.9), c[2])
			for _, z in { -0.8, 1.6 } do
				B(m, "Patte", Vector3.new(0.35, 1.5, 0.4), Vector3.new(sx * 0.45, 0.8, z), c[2])
			end
		end
		fini(m)
	end
	-- Ours : masses du garrot et de la croupe, fourrure en 3 tons, museau clair, griffes
	do
		local m = neuf("Ours")
		local b1, b2, b3, mus = rgb(110, 72, 44), rgb(86, 56, 34), rgb(140, 96, 60), rgb(196, 160, 120)
		B(m, "Corps", Vector3.new(2.6, 2.2, 4.6), Vector3.new(0, 2.6, 0.3), b1)
		B(m, "Garrot", Vector3.new(2.7, 0.7, 1.6), Vector3.new(0, 3.75, -1.0), b2)
		B(m, "Croupe", Vector3.new(2.5, 0.5, 1.6), Vector3.new(0, 3.75, 1.6), b3)
		B(m, "Ventre", Vector3.new(2.2, 0.3, 3.8), Vector3.new(0, 1.45, 0.3), b3)
		for _, sx in { -1, 1 } do
			for _, z in { -1.4, 1.8 } do
				B(m, "Patte", Vector3.new(0.85, 1.7, 0.95), Vector3.new(sx * 0.85, 0.95, z), b2)
				for g = -1, 1 do
					B(m, "Griffe", Vector3.new(0.14, 0.12, 0.3), Vector3.new(sx * 0.85 + g * 0.24, 0.06, z - 0.55), rgb(230, 222, 200))
				end
			end
			B(m, "Oreille", Vector3.new(0.45, 0.45, 0.25), Vector3.new(sx * 0.6, 4.15, -2.2), b2)
			B(m, "Oeil", Vector3.new(0.18, 0.18, 0.06), Vector3.new(sx * 0.4, 3.55, -2.88), rgb(18, 14, 12))
		end
		B(m, "Tete", Vector3.new(1.8, 1.6, 1.5), Vector3.new(0, 3.35, -2.1), b1)
		B(m, "Museau", Vector3.new(1.0, 0.8, 0.8), Vector3.new(0, 3.0, -3.0), mus)
		B(m, "Truffe", Vector3.new(0.4, 0.3, 0.12), Vector3.new(0, 3.25, -3.42), rgb(30, 22, 20))
		B(m, "Queue", Vector3.new(0.5, 0.5, 0.4), Vector3.new(0, 3.2, 2.75), b3)
		fini(m)
	end
end

-- Créatures du monde vivant (ennemis par biome, monstres de nuit, animaux sauvages).
-- Convention des bêtes : pièce « Base » au sol, tout ancré, sans collision, la tête vers -Z.
function M.creatures()
	dossier = dossierModeles()
	M.animauxFerme()
	M.chevre()
	M.slimes()
	M.betesFaitesMain()
	local function Q(m: Instance, nom: string, taille: Vector3, pos: Vector3, couleur: Color3, mat: Enum.Material?, o: Opts?): BasePart
		local opts: Opts = o or {}
		opts.collide = false
		return P(m, nom, taille, pos, couleur, mat or Mat.SmoothPlastic, opts)
	end
	local function yeux(m: Model, x: number, y: number, z: number, couleur: Color3?, taille: number?)
		local t = taille or 0.26
		for _, sx in { -1, 1 } do
			Q(m, "Oeil", Vector3.new(t, t, 0.1), Vector3.new(sx * x, y, z), couleur or rgb(20, 20, 24), couleur and Mat.Neon or Mat.SmoothPlastic)
		end
	end
	type Bete = {
		corps: Vector3, couleur: Color3, pattes: number, tete: Vector3, couleurTete: Color3?, couleurPattes: Color3?,
		patte: number?, mat: Enum.Material?, extra: ((Model, any) -> ())?, yeux: Color3?,
	}
	local function quadrupede(nom: string, o: Bete)
		local m = nouveau(nom)
		local bw, bh, bl = o.corps.X, o.corps.Y, o.corps.Z
		local legH = o.pattes
		local by = legH + bh / 2
		local mat = o.mat or Mat.SmoothPlastic
		Q(m, "Corps", o.corps, Vector3.new(0, by, 0), o.couleur, mat)
		local pw = o.patte or 0.6
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Q(m, "Patte", Vector3.new(pw, legH + 0.2, pw), Vector3.new(sx * (bw / 2 - pw / 2 - 0.05), legH / 2, sz * (bl / 2 - pw / 2 - 0.2)), o.couleurPattes or o.couleur, mat)
			end
		end
		local ts = o.tete
		local hy = by + bh * 0.3
		local hz = -(bl / 2 + ts.Z / 2 - 0.25)
		Q(m, "Tete", ts, Vector3.new(0, hy, hz), o.couleurTete or o.couleur, mat)
		yeux(m, ts.X * 0.28, hy + ts.Y * 0.15, hz - ts.Z / 2 - 0.03, o.yeux)
		if o.extra then
			o.extra(m, { by = by, hy = hy, hz = hz, bl = bl, bw = bw, bh = bh, ts = ts, legH = legH })
		end
		fini(m)
	end
	local function queue(m: Model, c, couleur: Color3, taille: Vector3, angle: number)
		Q(m, "Queue", taille, Vector3.new(0, c.by + c.bh * 0.25, c.bl / 2 + taille.Z / 2 - 0.2), couleur, Mat.SmoothPlastic, { rot = CFrame.Angles(math.rad(angle), 0, 0) })
	end
	local function oreilles(m: Model, c, couleur: Color3, taille: Vector3)
		for _, sx in { -1, 1 } do
			Q(m, "Oreille", taille, Vector3.new(sx * c.ts.X * 0.3, c.hy + c.ts.Y / 2 + taille.Y / 2 - 0.05, c.hz + 0.15), couleur)
		end
	end
	local function museau(m: Model, c, couleur: Color3, taille: Vector3)
		Q(m, "Museau", taille, Vector3.new(0, c.hy - c.ts.Y * 0.2, c.hz - c.ts.Z / 2 - taille.Z / 2 + 0.05), couleur)
		Q(m, "Truffe", Vector3.new(0.3, 0.25, 0.1), Vector3.new(0, c.hy - c.ts.Y * 0.2 + taille.Y * 0.3, c.hz - c.ts.Z / 2 - taille.Z - 0.02), rgb(30, 26, 26))
	end

	-- ---------------------------------------------------------------- Loups
	for _, v in { { "Loup", rgb(120, 118, 124), rgb(170, 168, 172) }, { "Loup_Blanc", rgb(232, 234, 238), rgb(250, 250, 252) } } do
		quadrupede(v[1], {
			corps = Vector3.new(1.6, 1.5, 3.6), couleur = v[2], pattes = 1.4, tete = Vector3.new(1.3, 1.2, 1.3), patte = 0.5,
			extra = function(m, c)
				museau(m, c, v[3], Vector3.new(0.7, 0.6, 0.8))
				oreilles(m, c, v[2], Vector3.new(0.35, 0.6, 0.25))
				queue(m, c, v[2], Vector3.new(0.45, 0.45, 1.6), 25)
				Q(m, "Ventre", Vector3.new(1.4, 0.3, 2.8), Vector3.new(0, c.legH + 0.1, 0), v[3])
			end,
		})
	end
	-- ---------------------------------------------------------------- Sanglier
	quadrupede("Sanglier", {
		corps = Vector3.new(2.2, 1.8, 3.4), couleur = rgb(96, 70, 52), pattes = 0.9, tete = Vector3.new(1.6, 1.4, 1.4), patte = 0.6,
		extra = function(m, c)
			Q(m, "Groin", Vector3.new(0.8, 0.6, 0.3), Vector3.new(0, c.hy - 0.3, c.hz - c.ts.Z / 2 - 0.12), rgb(200, 140, 130))
			for _, sx in { -1, 1 } do
				Q(m, "Defense", Vector3.new(0.18, 0.5, 0.18), Vector3.new(sx * 0.5, c.hy - 0.2, c.hz - c.ts.Z / 2 - 0.1), rgb(240, 236, 220), Mat.SmoothPlastic, { rot = CFrame.Angles(math.rad(-30), 0, 0) })
			end
			Q(m, "Criniere", Vector3.new(0.4, 0.5, 2.6), Vector3.new(0, c.by + c.bh / 2 + 0.15, 0), rgb(60, 44, 34))
			oreilles(m, c, rgb(80, 58, 44), Vector3.new(0.3, 0.45, 0.2))
		end,
	})
	-- ---------------------------------------------------------------- Ours
	-- Ours : construit par M.betesFaitesMain (27/11)
	-- ---------------------------------------------------------------- Araignée géante
	do
		local m = nouveau("Araignee")
		local noir, rouge = rgb(42, 32, 38), rgb(230, 40, 40)
		Q(m, "Abdomen", Vector3.new(2.6, 2, 2.8), Vector3.new(0, 1.9, 1.2), noir, Mat.Fabric)
		Q(m, "Motif", Vector3.new(1, 0.1, 1.2), Vector3.new(0, 2.92, 1.2), rouge, Mat.SmoothPlastic)
		Q(m, "Tete", Vector3.new(1.5, 1.2, 1.4), Vector3.new(0, 1.5, -0.8), noir, Mat.Fabric)
		yeux(m, 0.3, 1.75, -1.53, rouge, 0.22)
		yeux(m, 0.55, 1.55, -1.53, rouge, 0.16)
		for i = 0, 3 do
			for _, sx in { -1, 1 } do
				local z = -0.9 + i * 0.75
				Q(m, "Patte", Vector3.new(2.2, 0.25, 0.25), Vector3.new(sx * 1.6, 1.6, z), noir, Mat.Fabric, { rot = CFrame.Angles(0, math.rad(sx * (i - 1.5) * 12), math.rad(sx * -25)) })
				Q(m, "Patte", Vector3.new(0.25, 1.7, 0.25), Vector3.new(sx * 2.6, 0.75, z), noir, Mat.Fabric)
			end
		end
		fini(m)
	end
	-- ---------------------------------------------------------------- Scorpion
	do
		local m = nouveau("Scorpion")
		local c1, c2 = rgb(196, 140, 70), rgb(150, 100, 50)
		Q(m, "Corps", Vector3.new(1.8, 0.8, 2.8), Vector3.new(0, 0.8, 0), c1)
		Q(m, "Tete", Vector3.new(1.4, 0.7, 0.9), Vector3.new(0, 0.85, -1.7), c2)
		yeux(m, 0.3, 1.1, -2.17, rgb(20, 20, 20), 0.2)
		for _, sx in { -1, 1 } do
			Q(m, "Bras", Vector3.new(0.35, 0.35, 1.4), Vector3.new(sx * 1.1, 0.8, -2.2), c2, Mat.SmoothPlastic, { rot = CFrame.Angles(0, math.rad(sx * -25), 0) })
			Q(m, "Pince", Vector3.new(0.7, 0.45, 0.8), Vector3.new(sx * 1.4, 0.8, -3.1), c1)
			for i = 0, 2 do
				Q(m, "Patte", Vector3.new(1.2, 0.2, 0.2), Vector3.new(sx * 1.3, 0.45, -0.6 + i * 0.7), c2, Mat.SmoothPlastic, { rot = CFrame.Angles(0, 0, math.rad(sx * -30)) })
			end
		end
		local segs = { { 0, 1.1, 1.7, 30 }, { 0, 1.8, 2.2, 60 }, { 0, 2.7, 2.2, 100 }, { 0, 3.3, 1.7, 150 } }
		for _, sgm in segs do
			Q(m, "Queue", Vector3.new(0.6, 0.6, 0.8), Vector3.new(sgm[1], sgm[2], sgm[3]), c1, Mat.SmoothPlastic, { rot = CFrame.Angles(math.rad(sgm[4]), 0, 0) })
		end
		Q(m, "Dard", Vector3.new(0.3, 0.3, 0.7), Vector3.new(0, 3.3, 1.1), rgb(60, 30, 30), Mat.SmoothPlastic, { rot = CFrame.Angles(math.rad(200), 0, 0) })
		fini(m)
	end
	-- ---------------------------------------------------------------- Bipèdes (yéti, golem)
	type Bipede = { peau: Color3, haut: Color3, bas: Color3, echelle: number?, mat: Enum.Material?, extra: ((Model, number) -> ())? }
	local function bipede(nom: string, o: Bipede)
		local m = nouveau(nom)
		local e = o.echelle or 1
		local mat = o.mat or Mat.SmoothPlastic
		for _, sx in { -1, 1 } do
			Q(m, "Jambe", Vector3.new(0.7, 2, 0.7) * e, Vector3.new(sx * 0.45, 1, 0) * e, o.bas, mat)
		end
		Q(m, "Corps", Vector3.new(2, 2, 1) * e, Vector3.new(0, 3, 0) * e, o.haut, mat)
		Q(m, "Tete", Vector3.new(1.3, 1.3, 1.3) * e, Vector3.new(0, 4.65, 0) * e, o.peau, mat)
		yeux(m, 0.3 * e, 4.75 * e, -0.67 * e, nil, 0.22 * e)
		for _, sx in { -1, 1 } do
			Q(m, "Bras", Vector3.new(0.6, 2, 0.6) * e, Vector3.new(sx * 1.3, 3, 0) * e, o.peau, mat)
		end
		if o.extra then
			o.extra(m, e)
		end
		fini(m)
	end
	bipede("Yeti", {
		peau = rgb(242, 244, 248), haut = rgb(240, 242, 246), bas = rgb(230, 232, 238), echelle = 1.7, mat = Mat.Fabric,
		extra = function(m, e)
			Q(m, "Visage", Vector3.new(0.9, 0.8, 0.1) * e, Vector3.new(0, 4.55, -0.66) * e, rgb(120, 140, 170))
		end,
	})
	bipede("Golem_Glace", {
		peau = rgb(170, 214, 240), haut = rgb(150, 200, 236), bas = rgb(140, 190, 230), echelle = 1.5, mat = Mat.Ice,
		extra = function(m, e)
			for i = 1, 3 do
				Q(m, "Cristal", Vector3.new(0.5, 1.4, 0.5) * e, Vector3.new(-0.6 + i * 0.4, 4.1 + (i % 2) * 0.4, 0.3) * e, rgb(210, 240, 255), Mat.Neon, { rot = CFrame.Angles(0, 0, math.rad(-20 + i * 15)) })
			end
		end,
	})
	-- ---------------------------------------------------------------- Marais
	quadrupede("Crapaud", {
		corps = Vector3.new(2.6, 1.4, 2.4), couleur = rgb(96, 136, 64), pattes = 0.4, tete = Vector3.new(2, 0.9, 0.8), patte = 0.7,
		extra = function(m, c)
			for _, sx in { -1, 1 } do
				Q(m, "GrosOeil", Vector3.new(0.6, 0.6, 0.6), Vector3.new(sx * 0.6, c.by + c.bh / 2 + 0.2, -0.9), rgb(230, 210, 80), Mat.SmoothPlastic, { forme = "Ball" })
				Q(m, "Cuisse", Vector3.new(0.8, 0.9, 1.4), Vector3.new(sx * 1.4, 0.6, 0.6), rgb(80, 116, 52))
			end
			Q(m, "Ventre", Vector3.new(2.2, 0.2, 2), Vector3.new(0, c.legH + 0.05, 0), rgb(220, 210, 150))
		end,
	})
	do
		-- 27/11, Claude : flamme spectrale (avant : deux sphères) — langues de flamme effilées en 3 tons, visage, halo
		local m = nouveau("Feu_Follet")
		local c1, c2, c3 = rgb(120, 200, 255), rgb(170, 230, 255), rgb(235, 250, 255)
		local coeur = Q(m, "Coeur", Vector3.new(1.3, 1.2, 1.3), Vector3.new(0, 2.6, 0), c2, Mat.Neon, { transp = 0.1 })
		Q(m, "Flamme", Vector3.new(1.0, 1.0, 1.0), Vector3.new(0, 3.5, 0), c2, Mat.Neon, { transp = 0.15, rot = CFrame.Angles(0, 0.4, 0) })
		Q(m, "Flamme", Vector3.new(0.6, 0.9, 0.6), Vector3.new(0.1, 4.3, 0), c3, Mat.Neon, { transp = 0.1, rot = CFrame.Angles(0, 0.8, 0.15) })
		Q(m, "Flamme", Vector3.new(0.3, 0.6, 0.3), Vector3.new(0.18, 4.95, 0), c3, Mat.Neon, { transp = 0.05 })
		for _, sx in { -1, 1 } do
			Q(m, "Flamme", Vector3.new(0.4, 0.8, 0.4), Vector3.new(sx * 0.6, 3.4, 0.1), c1, Mat.Neon, { transp = 0.25, rot = CFrame.Angles(0, 0, sx * -0.4) })
			Q(m, "Oeil", Vector3.new(0.2, 0.28, 0.06), Vector3.new(sx * 0.26, 2.75, -0.66), rgb(20, 40, 70), Mat.SmoothPlastic)
		end
		Q(m, "Queue", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0, 1.8, 0.1), c1, Mat.Neon, { transp = 0.3 })
		Q(m, "Queue", Vector3.new(0.35, 0.5, 0.35), Vector3.new(0, 1.3, 0.2), c1, Mat.Neon, { transp = 0.45 })
		Q(m, "Halo", Vector3.new(2.6, 2.6, 2.6), Vector3.new(0, 3, 0), c1, Mat.Neon, { forme = "Ball", transp = 0.82 })
		local l = Instance.new("PointLight")
		l.Range = 14
		l.Brightness = 2
		l.Color = rgb(140, 220, 255)
		l.Parent = coeur
		fini(m)
	end
	quadrupede("Croco", {
		corps = Vector3.new(1.8, 0.9, 4.6), couleur = rgb(70, 100, 60), pattes = 0.5, tete = Vector3.new(1.4, 0.8, 1.2), patte = 0.6,
		extra = function(m, c)
			Q(m, "Machoire", Vector3.new(1.1, 0.5, 2), Vector3.new(0, c.hy - 0.25, c.hz - 1.5), rgb(80, 112, 66))
			Q(m, "Dents", Vector3.new(1.0, 0.12, 1.8), Vector3.new(0, c.hy - 0.02, c.hz - 1.5), rgb(240, 236, 220))
			Q(m, "Queue", Vector3.new(1.0, 0.6, 3.4), Vector3.new(0, c.by - 0.1, c.bl / 2 + 1.5), rgb(70, 100, 60))
			for i = 0, 4 do
				Q(m, "Ecaille", Vector3.new(0.3, 0.3, 0.4), Vector3.new(0, c.by + c.bh / 2 + 0.1, -1.6 + i * 0.8), rgb(56, 84, 48))
			end
		end,
	})
	-- ---------------------------------------------------------------- Animaux sauvages (chassables)
	quadrupede("Cerf", {
		corps = Vector3.new(1.6, 1.6, 3.4), couleur = rgb(160, 110, 70), pattes = 2.2, tete = Vector3.new(1, 1, 1.3), patte = 0.4,
		extra = function(m, c)
			Q(m, "Cou", Vector3.new(0.7, 1.4, 0.7), Vector3.new(0, c.hy - 0.3, c.hz + 0.4), rgb(160, 110, 70), Mat.SmoothPlastic, { rot = CFrame.Angles(math.rad(-25), 0, 0) })
			for _, sx in { -1, 1 } do
				Q(m, "Bois", Vector3.new(0.18, 1.4, 0.18), Vector3.new(sx * 0.35, c.hy + 1.1, c.hz + 0.2), rgb(220, 200, 160), Mat.SmoothPlastic, { rot = CFrame.Angles(0, 0, math.rad(sx * -20)) })
				Q(m, "Bois", Vector3.new(0.15, 0.7, 0.15), Vector3.new(sx * 0.6, c.hy + 1.4, c.hz - 0.1), rgb(220, 200, 160), Mat.SmoothPlastic, { rot = CFrame.Angles(math.rad(-30), 0, math.rad(sx * -40)) })
			end
			queue(m, c, rgb(240, 236, 226), Vector3.new(0.35, 0.4, 0.4), 30)
		end,
	})
	quadrupede("Lapin", {
		corps = Vector3.new(0.9, 0.8, 1.2), couleur = rgb(200, 186, 170), pattes = 0.25, tete = Vector3.new(0.7, 0.65, 0.65), patte = 0.25,
		extra = function(m, c)
			for _, sx in { -1, 1 } do
				Q(m, "Oreille", Vector3.new(0.18, 0.8, 0.12), Vector3.new(sx * 0.16, c.hy + 0.7, c.hz + 0.1), rgb(200, 186, 170))
			end
			Q(m, "Pompon", Vector3.new(0.35, 0.35, 0.35), Vector3.new(0, c.by + 0.1, c.bl / 2 + 0.05), rgb(250, 250, 250), Mat.SmoothPlastic, { forme = "Ball" })
		end,
	})
	quadrupede("Renard", {
		corps = Vector3.new(1, 1, 2.2), couleur = rgb(222, 120, 48), pattes = 0.8, tete = Vector3.new(0.9, 0.85, 0.9), patte = 0.3, couleurPattes = rgb(50, 36, 30),
		extra = function(m, c)
			museau(m, c, rgb(250, 244, 236), Vector3.new(0.45, 0.4, 0.6))
			oreilles(m, c, rgb(222, 120, 48), Vector3.new(0.25, 0.5, 0.18))
			queue(m, c, rgb(222, 120, 48), Vector3.new(0.6, 0.6, 1.5), 15)
			Q(m, "BoutQueue", Vector3.new(0.5, 0.5, 0.4), Vector3.new(0, c.by + c.bh * 0.25 + 0.35, c.bl / 2 + 1.5), rgb(250, 248, 244))
		end,
	})
	do
		local m = nouveau("Pingouin")
		Q(m, "Corps", Vector3.new(1.3, 1.9, 1.1), Vector3.new(0, 1.25, 0), rgb(30, 30, 36))
		Q(m, "Ventre", Vector3.new(1.0, 1.5, 0.1), Vector3.new(0, 1.15, -0.56), rgb(246, 246, 246))
		Q(m, "Tete", Vector3.new(1, 0.9, 0.9), Vector3.new(0, 2.6, 0), rgb(30, 30, 36))
		Q(m, "Bec", Vector3.new(0.3, 0.2, 0.4), Vector3.new(0, 2.5, -0.6), rgb(240, 160, 40))
		yeux(m, 0.22, 2.75, -0.46, nil, 0.16)
		for _, sx in { -1, 1 } do
			Q(m, "Aile", Vector3.new(0.18, 1.2, 0.6), Vector3.new(sx * 0.72, 1.4, 0), rgb(30, 30, 36), Mat.SmoothPlastic, { rot = CFrame.Angles(0, 0, math.rad(sx * 12)) })
			Q(m, "Pied", Vector3.new(0.4, 0.2, 0.5), Vector3.new(sx * 0.3, 0.1, -0.2), rgb(240, 160, 40))
		end
		fini(m)
	end
	quadrupede("Chameau", {
		corps = Vector3.new(1.8, 1.8, 3.6), couleur = rgb(210, 170, 110), pattes = 2.4, tete = Vector3.new(0.9, 0.9, 1.4), patte = 0.45,
		extra = function(m, c)
			Q(m, "Bosse", Vector3.new(1.4, 1.2, 1.4), Vector3.new(0, c.by + c.bh / 2 + 0.4, 0.3), rgb(196, 156, 100))
			Q(m, "Cou", Vector3.new(0.7, 1.8, 0.7), Vector3.new(0, c.hy - 0.2, c.hz + 0.55), rgb(210, 170, 110), Mat.SmoothPlastic, { rot = CFrame.Angles(math.rad(-30), 0, 0) })
		end,
	})
	do
		local m = nouveau("Flamant")
		local rose = rgb(244, 140, 170)
		Q(m, "Corps", Vector3.new(1, 1, 1.8), Vector3.new(0, 3.3, 0.2), rose)
		Q(m, "Cou", Vector3.new(0.3, 1.8, 0.3), Vector3.new(0, 4.4, -0.6), rose)
		Q(m, "Tete", Vector3.new(0.5, 0.5, 0.6), Vector3.new(0, 5.3, -0.75), rose)
		Q(m, "Bec", Vector3.new(0.2, 0.3, 0.5), Vector3.new(0, 5.15, -1.2), rgb(40, 36, 36))
		yeux(m, 0.16, 5.4, -1.06, nil, 0.12)
		for _, sx in { -1, 1 } do
			Q(m, "Patte", Vector3.new(0.12, 2.8, 0.12), Vector3.new(sx * 0.2, 1.4, 0.2), rgb(230, 120, 140))
		end
		fini(m)
	end
end

-- Sécurité de la maison et créatures de la nuit (originales)

-- Trois silhouettes employées par le bestiaire, avec le pivot au niveau du sol ou de l’eau.
function M.formesBestiaire()
	dossier = dossierModeles()
	local V = Vector3.new
	local function part(model, name, size, position, color, material, options)
		local opts: Opts = options or {}
		opts.collide = false
		return P(model, name, size, position, color, material, opts)
	end
	do
		local m = nouveau("Cavalier")
		local coat, mane = rgb(111, 72, 48), rgb(55, 36, 28)
		part(m, "Corps du cheval", V(2.1, 2, 3.5), V(0, 2.45, 0), coat, Mat.SmoothPlastic)
		for _, x in { -0.7, 0.7 } do
			for _, z in { -1.17, 1.14 } do
				part(m, "Jambe", V(0.52, 1.68, 0.5), V(x, 1.03, z), coat, Mat.SmoothPlastic)
				part(m, "Sabot", V(0.62, 0.37, 0.6), V(x, 0.25, z - 0.1), mane, Mat.Slate)
			end
		end
		part(m, "Encolure", V(1.1, 1.9, 1.1), V(0, 3.3, -1.6), coat, Mat.SmoothPlastic, { rot = CFrame.Angles(-0.28, 0, 0) })
		part(m, "Tête du cheval", V(1.04, 0.87, 1.42), V(0, 4.12, -2.19), coat, Mat.SmoothPlastic)
		part(m, "Museau", V(0.86, 0.5, 0.68), V(0, 3.89, -2.79), mane, Mat.SmoothPlastic)
		part(m, "Crinière", V(0.31, 1.61, 0.53), V(0, 3.54, -1.14), mane, Mat.SmoothPlastic)
		part(m, "Queue", V(0.4, 1.6, 0.43), V(0, 1.86, 1.96), mane, Mat.SmoothPlastic, { rot = CFrame.Angles(-0.28, 0, 0) })
		part(m, "Selle", V(2.24, 0.22, 1.52), V(0, 3.47, 0.48), mane, Mat.Leather)
		for _, x in { -0.9, 0.9 } do
			part(m, "Botte", V(0.45, 1.2, 0.46), V(x, 2.91, 0.48), mane, Mat.Leather, { rot = CFrame.Angles(0, 0, x * -0.15) })
		end
		part(m, "Manteau du cavalier", V(1.44, 1.42, 0.77), V(0, 4.23, 0.32), rgb(122, 40, 41), Mat.Fabric)
		part(m, "Capuche", V(0.85, 0.96, 0.86), V(0, 5.28, 0.22), rgb(57, 46, 47), Mat.Fabric)
		part(m, "Visage", V(0.48, 0.39, 0.07), V(0, 5.22, -0.25), rgb(184, 133, 97), Mat.SmoothPlastic)
		fini(m)
	end
	do
		local m = nouveau("Poisson_Carnassier")
		local back, belly = rgb(40, 107, 112), rgb(141, 176, 158)
		part(m, "Dos", V(1.72, 1.63, 3.45), V(0, 1, 0.1), back, Mat.SmoothPlastic)
		part(m, "Ventre", V(1.38, 0.53, 3.19), V(0, 0.41, 0.15), belly, Mat.SmoothPlastic)
		part(m, "Mâchoire", V(1.42, 0.53, 1.28), V(0, 0.63, -1.75), rgb(57, 131, 127), Mat.SmoothPlastic)
		part(m, "Nageoire dorsale", V(0.18, 1.04, 1.5), V(0, 2.0, 0.1), rgb(34, 80, 94), Mat.SmoothPlastic, { forme = "Wedge" })
		for _, x in { -1, 1 } do
			part(m, "Nageoire pectorale", V(1.06, 0.15, 0.86), V(x, 0.67, 0.25), back, Mat.SmoothPlastic, { forme = "Wedge", rot = CFrame.Angles(0, x * 0.35, 0) })
			part(m, "Œil", V(0.16, 0.32, 0.32), V(x * 0.83, 1.37, -1.28), rgb(247, 190, 86), Mat.SmoothPlastic, { forme = "Ball" })
			part(m, "Lobe de queue", V(0.24, 0.81, 1.34), V(0, 1.0 + x * 0.37, 2.22), back, Mat.SmoothPlastic,
				{ forme = "Wedge", rot = CFrame.Angles(0, math.pi, x < 0 and math.pi or 0) })
			for i = 1, 3 do
				part(m, "Dent", V(0.18, 0.23, 0.16), V(x * (0.21 + 0.16 * i), 0.97, -2.1), rgb(229, 221, 186), Mat.SmoothPlastic, { forme = "Wedge" })
			end
		end
		fini(m)
	end
	do
		local m = nouveau("Serpent_Marin")
		local back, crest = rgb(41, 96, 100), rgb(58, 176, 160)
		for i = 0, 8 do
			local extent = 1.72 - i * 0.14
			local x, y, z = math.sin(i * 0.66) * 0.77, 0.66 + (extent - 0.6) * 0.5, -1.75 + i * 0.9
			part(m, "Anneau", V(extent, extent * 0.84, 1.19), V(x, y, z), back, Mat.SmoothPlastic, { rot = CFrame.Angles(0, math.cos(i * 0.66) * 0.45, 0) })
			part(m, "Crête", V(0.23, extent * 0.43, 0.65), V(x, y + extent * 0.54, z + 0.11), crest, Mat.SmoothPlastic, { forme = "Wedge" })
			-- 27/11, Claude : ventre clair et nageoires (le serpent se lisait comme une simple chenille)
			part(m, "Ventre", V(extent * 0.7, 0.12, 1.0), V(x, y - extent * 0.42, z), rgb(196, 220, 190), Mat.SmoothPlastic)
			if i == 1 or i == 4 then
				for _, sx in { -1, 1 } do
					part(m, "Nageoire", V(0.12, extent * 0.5, 1.1), V(x + sx * extent * 0.55, y - 0.1, z + 0.2), crest, Mat.SmoothPlastic,
						{ rot = CFrame.Angles(0, 0, sx * -0.9) })
				end
			end
		end
		part(m, "Crâne", V(1.64, 1.35, 1.75), V(0, 1.63, -2.6), back, Mat.SmoothPlastic)
		part(m, "Mufle", V(1.23, 0.51, 1.15), V(0, 1.30, -3.40), rgb(123, 168, 140), Mat.SmoothPlastic)
		part(m, "Machoire", V(1.1, 0.3, 1.0), V(0, 0.95, -3.3), rgb(30, 70, 76), Mat.SmoothPlastic)
		for i = -1, 1 do
			part(m, "Dent", V(0.14, 0.22, 0.14), V(i * 0.35, 1.12, -3.85), rgb(236, 230, 210), Mat.SmoothPlastic)
		end
		for _, x in { -1, 1 } do
			part(m, "Œil", V(0.15, 0.3, 0.33), V(x * 0.81, 1.92, -2.69), rgb(244, 184, 79), Mat.SmoothPlastic, { forme = "Ball" })
			part(m, "Crête latérale", V(0.24, 0.69, 0.73), V(x * 0.81, 2.22, -2.33), crest, Mat.SmoothPlastic,
				{ forme = "Wedge", rot = CFrame.Angles(0, 0, x * -0.46) })
		end
		fini(m)
	end
end

function M.securite()
	dossier = dossierModeles()
	local function Q(m: Instance, nom: string, taille: Vector3, pos: Vector3, couleur: Color3, mat: Enum.Material?, o: Opts?): BasePart
		local opts: Opts = o or {}
		opts.collide = false
		return P(m, nom, taille, pos, couleur, mat or Mat.SmoothPlastic, opts)
	end
	reconstruireProps(NOMS_SECURITE)
	-- boss itinérants : grandes silhouettes reconnaissables
	do
		local m = nouveau("Gardien_Moissons")
		P(m, "Pieu", Vector3.new(1.2, 12, 1.2), Vector3.new(0, 6, 0), BOIS_FONCE, Mat.Wood, { collide = false })
		P(m, "Traverse", Vector3.new(10, 1, 1), Vector3.new(0, 9, 0), BOIS_FONCE, Mat.Wood, { collide = false })
		P(m, "Manteau", Vector3.new(5.5, 6, 2.6), Vector3.new(0, 7.6, 0), rgb(110, 50, 40), Mat.Fabric, { collide = false })
		for _, sx in { -1, 1 } do
			P(m, "Gerbe", Vector3.new(1.6, 2.4, 1.6), Vector3.new(sx * 5.2, 8.6, 0), rgb(226, 196, 100), Mat.Grass, { collide = false })
			P(m, "Faux", Vector3.new(0.3, 0.3, 4), Vector3.new(sx * 5.4, 9.9, -1.4), rgb(180, 180, 190), Mat.Metal, { collide = false }) -- posée sur la gerbe (27/11)
		end
		P(m, "Tete", Vector3.new(3.6, 3.2, 3.6), Vector3.new(0, 12.3, 0), rgb(220, 120, 30), Mat.SmoothPlastic, { collide = false })
		P(m, "Chapeau", Vector3.new(6, 0.4, 6), Vector3.new(0, 14.1, 0), rgb(60, 44, 30), Mat.Fabric, { collide = false })
		P(m, "Calotte", Vector3.new(3, 2.4, 3), Vector3.new(0, 15.4, 0), rgb(60, 44, 30), Mat.Fabric, { collide = false })
		for _, sx in { -1, 1 } do
			P(m, "Oeil", Vector3.new(0.8, 0.7, 0.2), Vector3.new(sx * 0.8, 12.6, -1.85), rgb(255, 230, 90), Mat.Neon, { collide = false })
		end
		fini(m)
	end
	do
		local m = nouveau("Roi_Mycelien")
		P(m, "Pied", Vector3.new(9, 4, 4), Vector3.new(0, 4.5, 0), rgb(236, 226, 206), Mat.SmoothPlastic, { collide = false, forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)) })
		P(m, "Chapeau", Vector3.new(2.5, 14, 14), Vector3.new(0, 10, 0), rgb(150, 60, 170), Mat.SmoothPlastic, { collide = false, forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)) })
		P(m, "Dome", Vector3.new(9, 9, 9), Vector3.new(0, 11, 0), rgb(170, 70, 190), Mat.SmoothPlastic, { collide = false, forme = "Ball" })
		for i = 0, 7 do
			local a = i * math.pi / 4
			P(m, "Point", Vector3.new(1.2, 0.6, 1.2), Vector3.new(math.cos(a) * 5.5, 11.4, math.sin(a) * 5.5), rgb(240, 230, 250), Mat.Neon, { collide = false })
		end
		for _, sx in { -1, 1 } do
			P(m, "Oeil", Vector3.new(0.7, 0.9, 0.2), Vector3.new(sx * 0.9, 6.5, -2.05), rgb(30, 10, 40), Mat.SmoothPlastic, { collide = false })
			P(m, "Bras", Vector3.new(0.8, 5, 0.8), Vector3.new(sx * 3, 5, -0.5), rgb(220, 210, 190), Mat.SmoothPlastic, { collide = false, rot = CFrame.Angles(0, 0, math.rad(sx * 30)) })
		end
		fini(m)
	end
	do
		local m = nouveau("Colosse_Verre")
		local verre, coeur = rgb(170, 220, 230), rgb(255, 200, 90)
		for _, sx in { -1, 1 } do
			P(m, "Jambe", Vector3.new(2.6, 6, 2.6), Vector3.new(sx * 2, 3, 0), verre, Mat.Glass, { collide = false, transp = 0.25 })
			P(m, "Bras", Vector3.new(2.2, 7, 2.2), Vector3.new(sx * 5, 9, 0), verre, Mat.Glass, { collide = false, transp = 0.25, rot = CFrame.Angles(0, 0, math.rad(sx * 12)) })
		end
		P(m, "Torse", Vector3.new(7.5, 7, 4.5), Vector3.new(0, 9.5, 0), verre, Mat.Glass, { collide = false, transp = 0.2 })
		P(m, "Coeur", Vector3.new(2, 2, 2), Vector3.new(0, 9.5, 0), coeur, Mat.Neon, { collide = false, forme = "Ball" })
		P(m, "Tete", Vector3.new(3.4, 3, 3.4), Vector3.new(0, 14.5, 0), verre, Mat.Glass, { collide = false, transp = 0.2 })
		for _, sx in { -1, 1 } do
			P(m, "Oeil", Vector3.new(0.6, 0.4, 0.2), Vector3.new(sx * 0.8, 14.7, -1.75), coeur, Mat.Neon, { collide = false })
		end
		fini(m)
	end
	do
		local m = nouveau("Dormeur_Glaces")
		local glace, fourrure = rgb(200, 230, 245), rgb(230, 236, 242)
		P(m, "Corps", Vector3.new(8, 6, 12), Vector3.new(0, 5, 0), fourrure, Mat.Fabric, { collide = false })
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				P(m, "Patte", Vector3.new(2.2, 3, 2.2), Vector3.new(sx * 3, 1.5, sz * 4), fourrure, Mat.Fabric, { collide = false })
			end
		end
		P(m, "Tete", Vector3.new(5, 4.5, 4.5), Vector3.new(0, 7, -7.5), fourrure, Mat.Fabric, { collide = false })
		for i = 0, 5 do
			P(m, "Pic", Vector3.new(1, 3 + (i % 2), 1), Vector3.new(0, 9 + (i % 2) * 0.5, -3 + i * 1.6), glace, Mat.Ice, { collide = false, rot = CFrame.Angles(math.rad(-15), 0, 0) })
		end
		for _, sx in { -1, 1 } do
			P(m, "Oeil", Vector3.new(0.8, 0.5, 0.2), Vector3.new(sx * 1.2, 7.6, -9.8), rgb(120, 200, 255), Mat.Neon, { collide = false })
			P(m, "Corne", Vector3.new(0.6, 3, 0.6), Vector3.new(sx * 1.8, 10, -7.5), glace, Mat.Ice, { collide = false, rot = CFrame.Angles(0, 0, math.rad(sx * -25)) })
		end
		fini(m)
	end
	local function soldat(nom: string, tunique: Color3, casque: Color3, extra: (Model) -> ())
		local m = nouveau(nom)
		local peau = rgb(226, 186, 150)
		for _, sx in { -1, 1 } do
			P(m, "Jambe", Vector3.new(0.7, 2, 0.7), Vector3.new(sx * 0.45, 1, 0), rgb(70, 60, 50), Mat.SmoothPlastic, { collide = false })
			P(m, "Bras", Vector3.new(0.6, 2, 0.6), Vector3.new(sx * 1.3, 3, 0), tunique, Mat.Fabric, { collide = false })
		end
		P(m, "Corps", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), tunique, Mat.Fabric, { collide = false })
		P(m, "Ceinture", Vector3.new(2.05, 0.3, 1.05), Vector3.new(0, 2.2, 0), rgb(80, 56, 36), Mat.SmoothPlastic, { collide = false })
		P(m, "Tete", Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 4.65, 0), peau, Mat.SmoothPlastic, { collide = false })
		P(m, "Casque", Vector3.new(1.4, 0.7, 1.4), Vector3.new(0, 5.25, 0), casque, Mat.Metal, { collide = false })
		for _, sx in { -1, 1 } do
			P(m, "Oeil", Vector3.new(0.2, 0.2, 0.1), Vector3.new(sx * 0.3, 4.75, -0.67), rgb(20, 20, 24), Mat.SmoothPlastic, { collide = false })
		end
		extra(m)
		fini(m)
	end
	soldat("Soldat_Milicien", rgb(140, 100, 60), rgb(120, 110, 100), function(m)
		P(m, "Gourdin", Vector3.new(0.4, 2.4, 0.4), Vector3.new(1.4, 3, -0.8), BOIS, Mat.Wood, { collide = false, rot = CFrame.Angles(math.rad(-30), 0, 0) })
	end)
	soldat("Soldat_Archer", rgb(70, 120, 70), rgb(90, 70, 50), function(m)
		P(m, "Arc", Vector3.new(0.2, 3, 0.2), Vector3.new(-1.5, 3, -0.6), BOIS, Mat.Wood, { collide = false })
		P(m, "Carquois", Vector3.new(0.6, 1.6, 0.6), Vector3.new(0.5, 3.4, 0.7), rgb(110, 70, 40), Mat.SmoothPlastic, { collide = false })
	end)
	soldat("Soldat_Garde", rgb(150, 150, 160), rgb(180, 180, 190), function(m)
		P(m, "Bouclier", Vector3.new(0.3, 2.2, 1.8), Vector3.new(-1.6, 3, -0.4), rgb(160, 40, 40), Mat.Metal, { collide = false })
		P(m, "Lance", Vector3.new(0.25, 5, 0.25), Vector3.new(1.5, 3.4, -0.3), BOIS_FONCE, Mat.Wood, { collide = false })
	end)
	-- Cambrioleur : bipède masqué en noir avec un sac
	do
		local m = nouveau("Cambrioleur")
		local noir, peau = rgb(36, 34, 40), rgb(220, 180, 150)
		for _, sx in { -1, 1 } do
			Q(m, "Jambe", Vector3.new(0.7, 2, 0.7), Vector3.new(sx * 0.45, 1, 0), noir)
			Q(m, "Bras", Vector3.new(0.6, 2, 0.6), Vector3.new(sx * 1.3, 3, 0), noir)
		end
		Q(m, "Corps", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), rgb(50, 50, 60), Mat.Fabric)
		Q(m, "Tete", Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 4.65, 0), peau)
		Q(m, "Cagoule", Vector3.new(1.36, 0.9, 1.36), Vector3.new(0, 4.95, 0), noir, Mat.Fabric)
		Q(m, "Masque", Vector3.new(1.38, 0.35, 0.2), Vector3.new(0, 4.65, -0.6), noir, Mat.Fabric)
		for _, sx in { -1, 1 } do
			Q(m, "Oeil", Vector3.new(0.22, 0.18, 0.1), Vector3.new(sx * 0.3, 4.65, -0.72), rgb(250, 250, 250), Mat.Neon)
		end
		Q(m, "Sac", Vector3.new(1.4, 1.6, 1), Vector3.new(0, 3.4, 0.95), rgb(150, 120, 80), Mat.Fabric)
		fini(m)
	end
	-- Épouvantail maudit : croix de bois, chapeau, citrouille aux yeux luisants
	do
		local m = nouveau("Epouvantail_Maudit")
		Q(m, "Pieu", Vector3.new(0.5, 5, 0.5), Vector3.new(0, 2.5, 0), BOIS_FONCE, Mat.Wood)
		Q(m, "Traverse", Vector3.new(4, 0.4, 0.4), Vector3.new(0, 3.9, 0), BOIS_FONCE, Mat.Wood)
		Q(m, "Chemise", Vector3.new(2.2, 2, 1), Vector3.new(0, 3.3, 0), rgb(120, 60, 60), Mat.Fabric)
		for _, sx in { -1, 1 } do
			Q(m, "Paille", Vector3.new(0.6, 0.7, 0.6), Vector3.new(sx * 2.1, 3.7, 0), rgb(220, 190, 100), Mat.Grass)
		end
		Q(m, "Tete", Vector3.new(1.6, 1.4, 1.6), Vector3.new(0, 5, 0), rgb(220, 120, 30))
		Q(m, "Chapeau", Vector3.new(2.4, 0.2, 2.4), Vector3.new(0, 5.8, 0), rgb(70, 50, 36), Mat.Fabric)
		Q(m, "Calotte", Vector3.new(1.3, 0.9, 1.3), Vector3.new(0, 6.3, 0), rgb(70, 50, 36), Mat.Fabric)
		for _, sx in { -1, 1 } do
			Q(m, "Oeil", Vector3.new(0.35, 0.3, 0.1), Vector3.new(sx * 0.35, 5.15, -0.82), rgb(255, 230, 90), Mat.Neon)
		end
		Q(m, "Bouche", Vector3.new(0.9, 0.2, 0.1), Vector3.new(0, 4.7, -0.82), rgb(255, 200, 60), Mat.Neon)
		fini(m)
	end
	-- Ombre rôdeuse : silhouette translucide, longs bras, yeux pâles
	do
		local m = nouveau("Ombre")
		local c = rgb(30, 24, 44)
		Q(m, "Corps", Vector3.new(1.6, 3.4, 1), Vector3.new(0, 2.6, 0), c, Mat.SmoothPlastic, { transp = 0.35 })
		Q(m, "Tete", Vector3.new(1.2, 1.3, 1.1), Vector3.new(0, 4.8, 0), c, Mat.SmoothPlastic, { transp = 0.3 })
		for _, sx in { -1, 1 } do
			Q(m, "Bras", Vector3.new(0.4, 3.2, 0.4), Vector3.new(sx * 1.05, 2.6, -0.3), c, Mat.SmoothPlastic, { transp = 0.4, rot = CFrame.Angles(math.rad(-15), 0, 0) })
			Q(m, "Oeil", Vector3.new(0.22, 0.12, 0.1), Vector3.new(sx * 0.28, 4.9, -0.57), rgb(200, 230, 255), Mat.Neon)
		end
		Q(m, "Traine", Vector3.new(1.8, 0.8, 1.4), Vector3.new(0, 0.5, 0.2), c, Mat.SmoothPlastic, { transp = 0.6 })
		fini(m)
	end
end

-- ---------------------------------------------------------------- Petits objets du sol

local function sol() reconstruireProps(NOMS_SOL) end

-- ---------------------------------------------------------------- Mobilier

local function lit(m: Model, base: BasePart, pos: Vector3, couverture: Color3, paille: boolean?)
	local cadre = P(m, "Lit", Vector3.new(3.2, 1.2, 6), pos + Vector3.new(0, 0.6, 0), BOIS_FONCE, Mat.WoodPlanks)
	if paille then
		P(m, "Matelas", Vector3.new(3, 0.5, 5.6), pos + Vector3.new(0, 1.45, 0), rgb(214, 186, 100), Mat.Grass, { collide = false })
	else
		P(m, "Matelas", Vector3.new(3, 0.5, 5.6), pos + Vector3.new(0, 1.45, 0), rgb(245, 245, 240), Mat.Fabric, { collide = false })
		P(m, "Couverture", Vector3.new(3.1, 0.55, 3.6), pos + Vector3.new(0, 1.5, 1), couverture, Mat.Fabric, { collide = false })
		P(m, "Oreiller", Vector3.new(2, 0.5, 1.1), pos + Vector3.new(0, 1.9, -2.1), rgb(255, 255, 255), Mat.Fabric, { collide = false })
		P(m, "Tete", Vector3.new(3.2, 2.2, 0.4), pos + Vector3.new(0, 1.1, -3), BOIS_FONCE, Mat.WoodPlanks)
	end
	-- Point de couchage : corps allongé, tête vers l'oreiller (-Z).
	attache(base, "Couchage", CFrame.new(pos + Vector3.new(0, 2.6, -0.2)) * CFrame.Angles(math.rad(90), 0, 0))
	attache(base, "PiedDuLit", CFrame.new(pos + Vector3.new(2.6, 0.2, 1.5)))
	return cadre
end

local function table_chaises(m: Model, pos: Vector3)
	P(m, "Table", Vector3.new(3.4, 0.3, 2.4), pos + Vector3.new(0, 2.6, 0), BOIS_CLAIR, Mat.WoodPlanks)
	P(m, "PiedTable", Vector3.new(0.9, 2.5, 0.9), pos + Vector3.new(0, 1.25, 0), BOIS, Mat.Wood)
	P(m, "Chaise", Vector3.new(1.4, 0.3, 1.4), pos + Vector3.new(0, 1.5, 2), BOIS, Mat.WoodPlanks)
	P(m, "PiedChaise", Vector3.new(0.4, 1.4, 0.4), pos + Vector3.new(0, 0.7, 2), BOIS_FONCE, Mat.Wood)
	P(m, "Dossier", Vector3.new(1.4, 1.6, 0.25), pos + Vector3.new(0, 2.4, 2.6), BOIS, Mat.WoodPlanks)
	P(m, "Pichet", Vector3.new(0.5, 0.7, 0.5), pos + Vector3.new(0.8, 3.1, -0.3), rgb(110, 150, 200), Mat.SmoothPlastic, { collide = false })
end

local function etagere(m: Model, pos: Vector3, rot: number)
	local cf = CFrame.new(pos) * CFrame.Angles(0, rot, 0)
	P(m, "Etagere", Vector3.new(4, 0.25, 1.2), Vector3.zero, BOIS, Mat.WoodPlanks, { cf = cf * CFrame.new(0, 2.5, 0) })
	P(m, "Etagere", Vector3.new(4, 0.25, 1.2), Vector3.zero, BOIS, Mat.WoodPlanks, { cf = cf * CFrame.new(0, 4.3, 0) })
	P(m, "Montant", Vector3.new(0.25, 5, 1.2), Vector3.zero, BOIS_FONCE, Mat.Wood, { cf = cf * CFrame.new(-1.9, 2.5, 0) })
	P(m, "Montant", Vector3.new(0.25, 5, 1.2), Vector3.zero, BOIS_FONCE, Mat.Wood, { cf = cf * CFrame.new(1.9, 2.5, 0) })
	local couleurs = { rgb(200, 80, 60), rgb(230, 180, 60), rgb(90, 150, 80), rgb(120, 100, 180) }
	for i, x in { -1.35, 1.2 } do
		P(m, "Bocal", Vector3.new(0.65, 0.8, 0.6), Vector3.zero, couleurs[i], Mat.SmoothPlastic, { cf = cf * CFrame.new(x, 3.02, 0), collide = false })
		P(m, "Bocal", Vector3.new(0.65, 0.7, 0.6), Vector3.zero, couleurs[i + 2], Mat.SmoothPlastic, { cf = cf * CFrame.new(-x, 4.75, 0), collide = false })
	end
end

local function tapis(m: Model, pos: Vector3, c: Color3)
	P(m, "Tapis", Vector3.new(5, 0.1, 3.4), pos + Vector3.new(0, 0.05, 0), c, Mat.Fabric, { collide = false })
end

local function lampe_interieure(m: Model, pos: Vector3, plafond: number)
	local hauteur = plafond - pos.Y - 0.4
	P(m, "Suspente", Vector3.new(0.14, hauteur + 0.08, 0.14), pos + Vector3.new(0, 0.4 + hauteur / 2, 0),
		FER, Mat.Metal, { collide = false })
	local l = P(m, "Lanterne", Vector3.new(0.7, 0.9, 0.7), pos, rgb(255, 214, 120), Mat.Neon, { collide = false })
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.4
	light.Color = rgb(255, 200, 130)
	light.Shadows = true
	light.Parent = l
	CollectionService:AddTag(l, "LumiereNuit")
end

-- Sous un toit ouvert, une ferme rejoint les deux murs. Dans une maison à étage la suspente
-- se prend directement dans le plafond.
local function ferme_lanterne(m: Model, largeur: number, hauteur: number, z: number)
	P(m, "Entrait", Vector3.new(largeur, 0.4, 0.4), Vector3.new(0, hauteur + 0.18, z), BOIS_FONCE, Mat.Wood)
end

local function enseigne_suspendue(m: Model, pos: Vector3, mot: string)
	P(m, "Potence", Vector3.new(0.4, 0.4, 2.8), pos + Vector3.new(0, 1.2, 1), BOIS_FONCE, Mat.Wood, { collide = false })
	local ens = P(m, "Enseigne", Vector3.new(4.4, 1.6, 0.25), pos + Vector3.new(0, 0, 2.1), BOIS_CLAIR, Mat.WoodPlanks, { collide = false })
	P(m, "Suspente", Vector3.new(0.18, 0.45, 0.18), pos + Vector3.new(0, 0.92, 2.1), FER, Mat.Metal, { collide = false })
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.PixelsPerStud = 40
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = mot
		t.TextScaled = true
		t.Font = Enum.Font.Fondamento
		t.TextColor3 = rgb(60, 36, 18)
		t.Parent = sg
		sg.Parent = ens
	end
end

-- ---------------------------------------------------------------- Maisons

-- Maisons médiévales : soubassement de pierre, torchis entre des colombages de bois sombre
-- (poteaux, sablières, croix de Saint-André), toits pentus en chaume, tuiles anciennes, bardeaux
-- ou ardoise, petites fenêtres à volets, cheminée de pierre, porte de planches cloutée.
type MaisonOpts = {
	largeur: number, profondeur: number, hauteur: number,
	mur: Color3, toit: Color3, poutre: Color3?, toitMat: string?, pierre: boolean?,
	ruine: boolean?, porteDecal: number?,
	etage: number?, -- hauteur d'un étage en encorbellement (débord devant et derrière)
	fleurs: boolean?, -- jardinières fleuries sous les fenêtres
}

local FLEURS = { rgb(220, 60, 70), rgb(250, 200, 60), rgb(240, 130, 180), rgb(150, 90, 200), rgb(255, 255, 255) }
local JET = 1 -- débord de l'étage (encorbellement)

local TOITS = {
	chaume = { mat = Mat.Grass, epais = 1.3 },
	tuiles = { mat = Mat.ClayRoofTiles, epais = 0.7 },
	ardoise = { mat = Mat.RoofShingles, epais = 0.7 },
	bardeaux = { mat = Mat.WoodPlanks, epais = 0.7 },
}

-- Façade (porte) vers +Z. Retourne le modèle et la pièce Base.
local function maison(nom: string, o: MaisonOpts): (Model, BasePart)
	local m = nouveau(nom)
	local base = m.PrimaryPart :: BasePart
	local W, D, H = o.largeur, o.profondeur, o.hauteur
	local e = 0.8 -- épaisseur des murs
	local socle = 0.8
	local poutre = o.poutre or rgb(62, 44, 30)
	local ruine = o.ruine == true
	local pierre = ruine or o.pierre == true
	local murMat = pierre and Mat.Cobblestone or Mat.Plaster
	local murCouleur = o.mur
	local toit = TOITS[o.toitMat or "chaume"] or TOITS.chaume
	-- Socle de pierre + plancher
	P(m, "Socle", Vector3.new(W + 0.6, socle, D + 0.6), Vector3.new(0, socle / 2, 0), PIERRE, Mat.Cobblestone)
	P(m, "Plancher", Vector3.new(W - 2 * e, 0.2, D - 2 * e), Vector3.new(0, socle + 0.1, 0), ruine and rgb(120, 104, 84) or rgb(120, 88, 58), Mat.WoodPlanks)
	local y0 = socle
	local porteX = o.porteDecal or 0
	P(m, "Marche", Vector3.new(4.4, 0.5, 1.6), Vector3.new(porteX, 0.25, D / 2 + 1.1), PIERRE, Mat.Cobblestone)
	local hMur = H
	local function mur(nomMur: string, taille: Vector3, pos: Vector3)
		P(m, nomMur, taille, pos, murCouleur, murMat)
	end
	if ruine then
		mur("Mur", Vector3.new(W, hMur * 0.7, e), Vector3.new(0, y0 + hMur * 0.35, -D / 2 + e / 2))
		mur("Mur", Vector3.new(W * 0.4, hMur * 0.35, e), Vector3.new(W * 0.3, y0 + hMur * 0.7 + hMur * 0.175, -D / 2 + e / 2))
		mur("Mur", Vector3.new(e, hMur, D), Vector3.new(-W / 2 + e / 2, y0 + hMur / 2, 0))
		mur("Mur", Vector3.new(e, hMur * 0.45, D * 0.6), Vector3.new(W / 2 - e / 2, y0 + hMur * 0.225, -D * 0.2))
		mur("Mur", Vector3.new(e, hMur * 0.25, D * 0.4), Vector3.new(W / 2 - e / 2, y0 + hMur * 0.125, D * 0.3))
	else
		mur("Mur", Vector3.new(W, hMur, e), Vector3.new(0, y0 + hMur / 2, -D / 2 + e / 2))
		mur("Mur", Vector3.new(e, hMur, D - 2 * e), Vector3.new(-W / 2 + e / 2, y0 + hMur / 2, 0))
		mur("Mur", Vector3.new(e, hMur, D - 2 * e), Vector3.new(W / 2 - e / 2, y0 + hMur / 2, 0))
	end
	-- Façade
	local pw, ph = 4, 7
	local gauche = (porteX - pw / 2) - (-W / 2)
	local droite = W / 2 - (porteX + pw / 2)
	mur("Mur", Vector3.new(gauche, ruine and hMur * 0.6 or hMur, e), Vector3.new(-W / 2 + gauche / 2, y0 + (ruine and hMur * 0.3 or hMur / 2), D / 2 - e / 2))
	mur("Mur", Vector3.new(droite, hMur, e), Vector3.new(W / 2 - droite / 2, y0 + hMur / 2, D / 2 - e / 2))
	if not ruine then
		mur("Linteau", Vector3.new(pw, hMur - ph, e), Vector3.new(porteX, y0 + ph + (hMur - ph) / 2, D / 2 - e / 2))
	end

	-- Fenêtres : petites, vitres plombées sombres, volets ouverts
	local yF = y0 + 4.8
	local fw, fh = 2.4, 2.6
	local nFleur = 0
	local function fenetre(cf: CFrame, sansFleur: boolean?)
		local vitre = P(m, "Vitre", Vector3.new(fw, fh, 0.2), Vector3.zero, rgb(52, 62, 70), Mat.Glass, { cf = cf * CFrame.new(0, 0, 0.42), collide = false, transp = 0.2 })
		CollectionService:AddTag(vitre, "Fenetre") -- chaude et lumineuse la nuit (Clock)
		if o.fleurs and not ruine and not sansFleur then
			nFleur += 1
			P(m, "Jardiniere", Vector3.new(fw + 0.4, 0.6, 0.8), Vector3.zero, rgb(110, 76, 48), Mat.WoodPlanks,
				{ cf = cf * CFrame.new(0, -fh / 2 - 0.75, 0.95), collide = false })
			P(m, "Feuillage", Vector3.new(fw + 0.2, 0.35, 0.6), Vector3.zero, rgb(70, 130, 60), Mat.Grass,
				{ cf = cf * CFrame.new(0, -fh / 2 - 0.4, 0.95), collide = false })
			for _, k in { -1, 1 } do
				local c = FLEURS[(nFleur + k + 3) % #FLEURS + 1]
				P(m, "Fleur", Vector3.new(0.7, 0.7, 0.7), Vector3.zero, c, Mat.SmoothPlastic,
					{ cf = cf * CFrame.new(k * 0.85, -fh / 2 - 0.2, 0.95), collide = false, forme = "Ball" })
			end
		end
		P(m, "Croisillon", Vector3.new(0.15, fh, 0.3), Vector3.zero, rgb(40, 40, 44), Mat.Metal, { cf = cf * CFrame.new(0, 0, 0.5), collide = false })
		P(m, "Croisillon", Vector3.new(fw, 0.15, 0.3), Vector3.zero, rgb(40, 40, 44), Mat.Metal, { cf = cf * CFrame.new(0, 0, 0.5), collide = false })
		P(m, "Appui", Vector3.new(fw + 0.8, 0.35, 0.7), Vector3.zero, PIERRE, Mat.Cobblestone, { cf = cf * CFrame.new(0, -fh / 2 - 0.2, 0.55), collide = false })
		if pierre then return end
		P(m, "Cadre", Vector3.new(fw + 0.6, 0.4, 0.5), Vector3.zero, poutre, Mat.Wood, { cf = cf * CFrame.new(0, fh / 2 + 0.2, 0.5), collide = false })
		for _, sx in { -1, 1 } do
			P(m, "Volet", Vector3.new(fw / 2 + 0.1, fh + 0.2, 0.18), Vector3.zero, rgb(78, 58, 40), Mat.WoodPlanks,
				{ cf = cf * CFrame.new(sx * (fw * 0.75 + 0.15), 0, 0.55), collide = false })
		end
	end
	local fx = porteX >= 0 and -W / 4 - 0.5 or W / 4 + 0.5
	if not ruine then
		fenetre(CFrame.new(fx, yF, D / 2 - e / 2))
		fenetre(CFrame.new(W / 2 - e / 2, yF, 0) * CFrame.Angles(0, math.rad(90), 0))
		fenetre(CFrame.new(-W / 2 + e / 2, yF, 0) * CFrame.Angles(0, math.rad(-90), 0))
	end

	-- Colombages d'un mur : cf au pied du mur, côté dehors (X le long du mur, Z vers l'extérieur).
	-- trous = { {x0, x1, y0, y1} } : porte et fenêtres à laisser libres.
	local function colombage(cf: CFrame, long: number, trous, hh: number?, sansPierre: boolean?)
		local hMur = hh or hMur
		local function libre(xa: number, xb: number, ya: number, yb: number): boolean
			for _, t in trous do
				if xb > t[1] and xa < t[2] and yb > t[3] and ya < t[4] then
					return false
				end
			end
			return true
		end
		-- morceaux d'une ligne horizontale à hauteur y, coupée par les trous
		local function morceaux(y: number)
			local list, x = {}, -long / 2
			local tri = table.clone(trous)
			table.sort(tri, function(a, b)
				return a[1] < b[1]
			end)
			for _, t in tri do
				if y > t[3] and y < t[4] then
					table.insert(list, { x, t[1] })
					x = t[2]
				end
			end
			table.insert(list, { x, long / 2 })
			return list
		end
		local z = 0.14
		local bas, haut = sansPierre and 0.3 or 2.6, hMur - 0.35
		-- soubassement de pierre
		for _, seg in sansPierre and {} or morceaux(bas / 2) do
			if seg[2] - seg[1] > 0.2 then
				P(m, "Soubassement", Vector3.new(seg[2] - seg[1], bas, 0.35), Vector3.zero, PIERRE, Mat.Cobblestone,
					{ cf = cf * CFrame.new((seg[1] + seg[2]) / 2, bas / 2, z - 0.05) })
			end
		end
		-- sablières (horizontales)
		for _, y in { bas, haut } do
			for _, pc in morceaux(y) do
				if pc[2] - pc[1] > 0.2 then
					P(m, "Colombage", Vector3.new(pc[2] - pc[1], 0.45, 0.3), Vector3.zero, poutre, Mat.Wood,
						{ cf = cf * CFrame.new((pc[1] + pc[2]) / 2, y, z), collide = false })
				end
			end
		end
		-- poteaux et croix de Saint-André dans la moitié haute
		local n = math.max(2, math.floor(long / 4.8))
		local pas = long / n
		for i = 0, n do
			local x = math.clamp(-long / 2 + i * pas, -long / 2 + 0.25, long / 2 - 0.25)
			if libre(x - 0.25, x + 0.25, bas, haut) then
				P(m, "Colombage", Vector3.new(0.45, haut - bas, 0.3), Vector3.zero, poutre, Mat.Wood, { cf = cf * CFrame.new(x, (bas + haut) / 2, z), collide = false })
			end
			if i < n and i % 2 == 0 then
				local xa, xb = -long / 2 + i * pas, -long / 2 + (i + 1) * pas
				local y1, y2 = hMur * 0.58, haut
				if libre(xa, xb, y1, y2) then
					local cx, cy = (xa + xb) / 2, (y1 + y2) / 2
					local diag = math.sqrt(pas * pas + (y2 - y1) ^ 2)
					local ang = math.atan2(y2 - y1, pas)
					P(m, "Colombage", Vector3.new(diag, 0.35, 0.28), Vector3.zero, poutre, Mat.Wood, { cf = cf * CFrame.new(cx, cy, z) * CFrame.Angles(0, 0, ang), collide = false })
					P(m, "Colombage", Vector3.new(diag, 0.35, 0.28), Vector3.zero, poutre, Mat.Wood, { cf = cf * CFrame.new(cx, cy, z) * CFrame.Angles(0, 0, -ang), collide = false })
				end
			end
		end
	end
	local fen = { fw / 2 + 1.1, yF - y0 - fh / 2 - 0.6, yF - y0 + fh / 2 + 0.6 }
	if not pierre then
		colombage(CFrame.new(0, y0, D / 2), W, {
			{ porteX - pw / 2 - 0.4, porteX + pw / 2 + 0.4, -1, ph + 0.5 },
			{ fx - fen[1], fx + fen[1], fen[2], fen[3] },
		})
		colombage(CFrame.new(0, y0, -D / 2) * CFrame.Angles(0, math.pi, 0), W, {})
		colombage(CFrame.new(W / 2, y0, 0) * CFrame.Angles(0, math.rad(90), 0), D, { { -fen[1], fen[1], fen[2], fen[3] } })
		colombage(CFrame.new(-W / 2, y0, 0) * CFrame.Angles(0, math.rad(-90), 0), D, { { -fen[1], fen[1], fen[2], fen[3] } })
	end
	if not ruine then
		-- poteaux d'angle (chaînes d'angle en pierre pour les maisons de pierre) et encadrement de porte
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				P(m, "Poutre", Vector3.new(1, hMur, 1), Vector3.new(sx * (W / 2 - 0.4), y0 + hMur / 2, sz * (D / 2 - 0.4)),
					pierre and PIERRE_CLAIRE or poutre, pierre and Mat.Cobblestone or Mat.Wood)
			end
		end
		P(m, "Poutre", Vector3.new(0.6, 7.4, 1.1), Vector3.new(porteX - pw / 2 - 0.3, y0 + 3.7, D / 2 - 0.4), poutre, Mat.Wood)
		P(m, "Poutre", Vector3.new(0.6, 7.4, 1.1), Vector3.new(porteX + pw / 2 + 0.3, y0 + 3.7, D / 2 - 0.4), poutre, Mat.Wood)
		P(m, "Poutre", Vector3.new(pw + 1.2, 0.8, 1.1), Vector3.new(porteX, y0 + 7.3, D / 2 - 0.4), poutre, Mat.Wood)
	end

	-- Étage en encorbellement (façon maison à pans de bois) : déborde de JET devant et derrière
	local Dt = D -- profondeur sous le toit
	local yT = y0 + hMur
	if o.etage and not ruine then
		local E2 = o.etage
		local y1 = y0 + hMur
		Dt = D + 2 * JET
		P(m, "Plafond", Vector3.new(W - 2 * e, 0.3, D - 2 * e), Vector3.new(0, y1 + 0.15, 0), rgb(110, 80, 52), Mat.WoodPlanks)
		-- solives qui dépassent (on voit l'encorbellement)
		local intervalles = math.floor(W / 4.4)
		for i = 0, intervalles do
			local x = -W / 2 + 0.5 + i * ((W - 1) / intervalles)
			for _, sz in { -1, 1 } do
				P(m, "Solive", Vector3.new(0.5, 0.5, JET + 0.6), Vector3.new(x, y1 + 0.1, sz * (D / 2 + JET / 2 - 0.2)), poutre, Mat.Wood, { collide = false })
			end
		end
		P(m, "Sabliere", Vector3.new(W + 0.4, 0.6, Dt + 0.2), Vector3.new(0, y1 + 0.55, 0), poutre, Mat.Wood)
		local yb = y1 + 0.85
		mur("Mur", Vector3.new(W, E2, e), Vector3.new(0, yb + E2 / 2, Dt / 2 - e / 2))
		mur("Mur", Vector3.new(W, E2, e), Vector3.new(0, yb + E2 / 2, -Dt / 2 + e / 2))
		mur("Mur", Vector3.new(e, E2, Dt - 2 * e), Vector3.new(-W / 2 + e / 2, yb + E2 / 2, 0))
		mur("Mur", Vector3.new(e, E2, Dt - 2 * e), Vector3.new(W / 2 - e / 2, yb + E2 / 2, 0))
		local yF2 = yb + E2 * 0.5
		fenetre(CFrame.new(-W / 4, yF2, Dt / 2 - e / 2))
		fenetre(CFrame.new(W / 4, yF2, Dt / 2 - e / 2))
		fenetre(CFrame.new(0, yF2, -Dt / 2 + e / 2) * CFrame.Angles(0, math.pi, 0), true)
		local f2 = { fw / 2 + 1.1, yF2 - yb - fh / 2 - 0.6, yF2 - yb + fh / 2 + 0.6 }
		if not pierre then
			colombage(CFrame.new(0, yb, Dt / 2), W, { { -W / 4 - f2[1], -W / 4 + f2[1], f2[2], f2[3] }, { W / 4 - f2[1], W / 4 + f2[1], f2[2], f2[3] } }, E2, true)
			colombage(CFrame.new(0, yb, -Dt / 2) * CFrame.Angles(0, math.pi, 0), W, { { -f2[1], f2[1], f2[2], f2[3] } }, E2, true)
			colombage(CFrame.new(W / 2, yb, 0) * CFrame.Angles(0, math.rad(90), 0), Dt, {}, E2, true)
			colombage(CFrame.new(-W / 2, yb, 0) * CFrame.Angles(0, math.rad(-90), 0), Dt, {}, E2, true)
		end
		yT = yb + E2
	end

	-- Toit pentu à deux pans (faîte selon X) + pignons
	local R = Dt * 0.58
	local deb = 1.6 -- débord
	local function pan(sens: number, partiel: boolean)
		local haut = Vector3.new(0, yT + R, 0)
		local bas = Vector3.new(0, yT - 0.6, sens * (Dt / 2 + 0.3))
		local dir = (bas - haut).Unit
		local long = (bas - haut).Magnitude + deb
		local milieu = haut + dir * (long / 2)
		local cf = CFrame.lookAt(milieu, milieu + dir) * CFrame.new(0, toit.epais / 2, 0)
		local larg = W + 2 * deb
		if partiel then
			local panRestant = cf * CFrame.new(-larg * 0.27, 0, long * 0.1)
			P(m, "Toit", Vector3.new(larg * 0.45, toit.epais, long * 0.8), Vector3.zero, o.toit, toit.mat, { cf = panRestant })
			-- Le chevron, au-dessus du long mur intact, s'encastre dans la couverture et la maçonnerie.
			P(m, "Chevron", Vector3.new(0.55, 1.6, long * 0.8), Vector3.zero, poutre, Mat.Wood,
				{ cf = cf * CFrame.new(-W / 2 + e / 2, -toit.epais / 2 - 0.55, long * 0.1) })
		else
			P(m, "Toit", Vector3.new(larg, toit.epais, long), Vector3.zero, o.toit, toit.mat, { cf = cf })
			if (o.toitMat or "chaume") == "chaume" then
				-- bord du chaume épais
				P(m, "Chaume", Vector3.new(larg + 0.2, toit.epais * 1.5, 1.2), Vector3.zero, o.toit:Lerp(Color3.new(0, 0, 0), 0.12), Mat.Grass,
					{ cf = cf * CFrame.new(0, -0.1, long / 2 - 0.5), collide = false })
			end
		end
	end
	if ruine then
		pan(-1, true)
	else
		pan(1, false)
		pan(-1, false)
		local chaume = (o.toitMat or "chaume") == "chaume"
		P(m, "Faite", Vector3.new(W + 2 * deb + 0.2, 0.9, 1), Vector3.new(0, yT + R + 0.6, 0), chaume and o.toit:Lerp(Color3.new(0, 0, 0), 0.2) or poutre, chaume and Mat.Grass or Mat.Wood)
		for _, sx in { -1, 1 } do
			local x = sx * (W / 2 - e / 2)
			P(m, "Pignon", Vector3.new(e, R, Dt / 2), Vector3.zero, murCouleur, murMat,
				{ forme = "Wedge", cf = CFrame.new(x, yT + R / 2, Dt / 4) * CFrame.Angles(0, math.rad(180), 0) })
			P(m, "Pignon", Vector3.new(e, R, Dt / 2), Vector3.zero, murCouleur, murMat,
				{ forme = "Wedge", cf = CFrame.new(x, yT + R / 2, -Dt / 4) })
			if not pierre then
				-- poinçon et entrait du pignon
				P(m, "Colombage", Vector3.new(0.3, R - 0.6, 0.45), Vector3.new(sx * (W / 2 + 0.02), yT + (R - 0.6) / 2, 0), poutre, Mat.Wood, { collide = false })
				P(m, "Colombage", Vector3.new(0.3, 0.45, Dt - 1), Vector3.new(sx * (W / 2 + 0.02), yT + 0.2, 0), poutre, Mat.Wood, { collide = false })
			end
		end
		-- Cheminée de pierre
		P(m, "Cheminee", Vector3.new(2, R + 3, 2), Vector3.new(W / 2 - 3, yT + (R + 3) / 2, -D / 4), PIERRE, Mat.Cobblestone)
		P(m, "Cheminee", Vector3.new(2.4, 0.5, 2.4), Vector3.new(W / 2 - 3, yT + R + 3, -D / 4), PIERRE_CLAIRE, Mat.Cobblestone)
		local fumee = P(m, "Sortie", Vector3.new(1.2, 0.2, 1.2), Vector3.new(W / 2 - 3, yT + R + 3.3, -D / 4), rgb(40, 30, 30), Mat.SmoothPlastic, { collide = false })
		local smoke = Instance.new("Smoke")
		smoke.Size = 2
		smoke.RiseVelocity = 3
		smoke.Opacity = 0.12
		smoke.Color = rgb(220, 220, 220)
		smoke.Parent = fumee
	end
	-- Porte de planches cloutée (battant sur charnière, gérée par le jeu)
	if not ruine then
		local porte = Instance.new("Model")
		porte.Name = "Porte"
		local battant = P(porte, "Battant", Vector3.new(pw - 0.2, ph - 0.1, 0.4), Vector3.new(porteX, y0 + ph / 2, D / 2 - e / 2), rgb(92, 64, 42), Mat.WoodPlanks)
		P(porte, "Poignee", Vector3.new(0.12, 0.6, 0.6), Vector3.new(porteX + pw / 2 - 0.6, y0 + 3.5, D / 2 - e / 2 + 0.3), FER, Mat.Metal, { collide = false, forme = "Cylinder" })
		for _, y in { 1.2, 3.6, 5.9 } do
			P(porte, "Ferrure", Vector3.new(pw - 0.6, 0.3, 0.1), Vector3.new(porteX, y0 + y, D / 2 - e / 2 + 0.22), FER, Mat.Metal, { collide = false })
		end
		porte.PrimaryPart = battant
		attache(battant, "Charniere", CFrame.new(porteX - pw / 2 + 0.1, y0 + ph / 2, D / 2 - e / 2))
		porte.Parent = m
	end
	-- Repères
	attache(base, "Entree", CFrame.new(porteX, 0, D / 2 + 3.5))
	attache(base, "Seuil", CFrame.new(porteX, y0, D / 2 - 2.2))
	attache(base, "Dedans", CFrame.new(0, y0, 0))
	base:SetAttribute("Largeur", W)
	base:SetAttribute("Profondeur", D)
	return m, base
end

local function maisons(sansMarche: boolean?)
	local palettes = {
		{ nom = "Maison_A", mur = rgb(222, 206, 172), toit = rgb(190, 160, 92), toitMat = "chaume" },
		{ nom = "Maison_B", mur = rgb(206, 178, 132), toit = rgb(172, 98, 66), toitMat = "tuiles" },
		{ nom = "Maison_C", mur = rgb(204, 198, 182), toit = rgb(104, 104, 110), toitMat = "ardoise" },
	}
	for i, pal in palettes do
		local m, base = maison(pal.nom, { largeur = 22, profondeur = 18, hauteur = 10, mur = pal.mur, toit = pal.toit, toitMat = pal.toitMat, porteDecal = i == 2 and -4 or 3,
			etage = i ~= 3 and 7 or nil, fleurs = true })
		lit(m, base, Vector3.new(-6.5, 1, -4.4), i == 1 and rgb(190, 60, 60) or (i == 2 and rgb(70, 110, 180) or rgb(90, 150, 80)))
		table_chaises(m, Vector3.new(4.5, 1, -3))
		etagere(m, Vector3.new(8.4, 1, 2), math.rad(-90))
		tapis(m, Vector3.new(0, 1, 2), rgb(170, 60, 50))
		if i == 3 then ferme_lanterne(m, 22, 10.55, 0) end
		lampe_interieure(m, Vector3.new(0, 9.4, 0), i == 3 and 10.55 or 10.8)
		attache(base, "Travail", CFrame.new(2, 1, 1))
		fini(m)
	end
	-- Boutique : comptoir + étagères
	do
		local m, base = maison("Boutique", { largeur = 24, profondeur = 18, hauteur = 11, mur = rgb(216, 190, 146), toit = rgb(118, 84, 56), toitMat = "bardeaux", porteDecal = 0 })
		P(m, "Comptoir", Vector3.new(12, 3, 2), Vector3.new(0, 2.3, -3), BOIS, Mat.WoodPlanks)
		P(m, "Plateau", Vector3.new(12.4, 0.3, 2.4), Vector3.new(0, 3.95, -3), BOIS_CLAIR, Mat.WoodPlanks)
		P(m, "Balance", Vector3.new(1, 0.6, 1), Vector3.new(3, 4.4, -3), OR, Mat.Metal, { collide = false })
		etagere(m, Vector3.new(-6, 1, -7.6), 0)
		etagere(m, Vector3.new(6, 1, -7.6), 0)
		etagere(m, Vector3.new(-10.4, 1, 1), math.rad(90))
		lit(m, base, Vector3.new(8.5, 1, 3.5), rgb(150, 60, 110))
		ferme_lanterne(m, 24, 11.55, 0)
		lampe_interieure(m, Vector3.new(0, 10.4, 0), 11.55)
		attache(base, "Travail", CFrame.new(0, 1, -5.5))
		-- Enseigne
		local ens = P(m, "Enseigne", Vector3.new(6, 1.6, 0.3), Vector3.new(0, 10.2, 9.12), BOIS_CLAIR, Mat.WoodPlanks, { collide = false })
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.PixelsPerStud = 40
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "Échoppe"
		t.TextScaled = true
		t.Font = Enum.Font.Fondamento
		t.TextColor3 = rgb(70, 40, 20)
		t.Parent = sg
		sg.Parent = ens
		-- l'enseigne regarde vers +Z : la face « Front » d'une pièce regarde vers -Z, on la retourne
		ens.CFrame = ens.CFrame * CFrame.Angles(0, math.rad(180), 0)
		fini(m)
	end
	-- Bureau du shérif : bureau + cellule à barreaux
	do
		local m, base = maison("Bureau_Sherif", { largeur = 22, profondeur = 18, hauteur = 10, mur = rgb(150, 146, 138), toit = rgb(96, 96, 102), toitMat = "ardoise", pierre = true, porteDecal = 4 })
		P(m, "Bureau", Vector3.new(5, 2.6, 2.4), Vector3.new(4, 2.1, -2), BOIS_FONCE, Mat.WoodPlanks)
		P(m, "Etoile", Vector3.new(1.6, 1.6, 0.2), Vector3.new(4, 7, -8.1), OR, Mat.Metal, { collide = false, rot = CFrame.Angles(0, 0, math.rad(45)) })
		-- Cellule dans le coin arrière gauche
		for i = 0, 5 do
			P(m, "Barreau", Vector3.new(0.3, 9, 0.3), Vector3.new(-10 + i * 1.3, 5.3, -1.5), FER, Mat.Metal)
		end
		for i = 0, 3 do
			P(m, "Barreau", Vector3.new(0.3, 9, 0.3), Vector3.new(-2.2, 5.3, -1.5 - i * 1.6), FER, Mat.Metal)
		end
		P(m, "Barre", Vector3.new(8.6, 0.4, 0.4), Vector3.new(-6.1, 9.6, -1.5), FER, Mat.Metal)
		P(m, "Paillasse", Vector3.new(3, 0.5, 5), Vector3.new(-7.5, 1.15, -5.5), rgb(214, 186, 100), Mat.Grass, { collide = false })
		attache(base, "Cellule", CFrame.new(-5.5, 1, -4.5))
		lit(m, base, Vector3.new(7.5, 1, 4), rgb(120, 90, 60))
		ferme_lanterne(m, 22, 10.55, 2)
		lampe_interieure(m, Vector3.new(0, 9.4, 2), 10.55)
		attache(base, "Travail", CFrame.new(4, 1, -4.4))
		local ens = P(m, "Enseigne", Vector3.new(6, 1.6, 0.3), Vector3.new(-3, 10.2, 9.12), BOIS_CLAIR, Mat.WoodPlanks, { collide = false })
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.PixelsPerStud = 40
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "Shérif"
		t.TextScaled = true
		t.Font = Enum.Font.Fondamento
		t.TextColor3 = rgb(70, 40, 20)
		t.Parent = sg
		sg.Parent = ens
		ens.CFrame = ens.CFrame * CFrame.Angles(0, math.rad(180), 0)
		fini(m)
	end
	local function tonneau(m: Model, pos: Vector3)
		P(m, "Tonneau", Vector3.new(2.4, 2, 2), pos + Vector3.new(0, 1.2, 0), BOIS, Mat.WoodPlanks, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)) })
		P(m, "Cercle", Vector3.new(0.2, 2.08, 2.08), pos + Vector3.new(0, 0.6, 0), FER, Mat.Metal, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)), collide = false })
		P(m, "Cercle", Vector3.new(0.2, 2.08, 2.08), pos + Vector3.new(0, 1.8, 0), FER, Mat.Metal, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)), collide = false })
	end
	-- Taverne : grande salle, comptoir, tonneaux, longues tables
	do
		local m, base = maison("Taverne", { largeur = 28, profondeur = 20, hauteur = 11, mur = rgb(214, 190, 146), toit = rgb(166, 94, 62), toitMat = "tuiles", porteDecal = 0, etage = 8, fleurs = true })
		P(m, "Comptoir", Vector3.new(10, 3, 1.8), Vector3.new(-6, 2.3, -6), BOIS_FONCE, Mat.WoodPlanks)
		P(m, "Plateau", Vector3.new(10.4, 0.3, 2.2), Vector3.new(-6, 3.95, -6), BOIS_CLAIR, Mat.WoodPlanks)
		for i = 0, 3 do
			tonneau(m, Vector3.new(-12 + i * 2.6, 0.8, -8.2))
		end
		for _, x in { -2, 6 } do
			P(m, "Table", Vector3.new(3, 0.3, 8), Vector3.new(x, 3.1, 2), BOIS_CLAIR, Mat.WoodPlanks)
			P(m, "PiedTable", Vector3.new(2.6, 2.2, 0.5), Vector3.new(x, 1.9, 2), BOIS, Mat.Wood)
			for _, s in { -1, 1 } do
				local bx = x + s * 2.2
				P(m, "Banc", Vector3.new(1, 0.4, 7.6), Vector3.new(bx, 2, 2), BOIS, Mat.WoodPlanks)
				for _, z in { -0.9, 4.9 } do
					P(m, "PiedBanc", Vector3.new(0.7, 0.9, 0.48), Vector3.new(bx, 1.36, z), BOIS_FONCE, Mat.Wood)
				end
			end
			P(m, "Chope", Vector3.new(0.5, 0.7, 0.5), Vector3.new(x, 3.6, 1), rgb(150, 110, 70), Mat.Wood, { collide = false })
		end
		lampe_interieure(m, Vector3.new(-4, 10.4, 0), 11.8)
		lampe_interieure(m, Vector3.new(6, 10.4, 2), 11.8)
		attache(base, "Travail", CFrame.new(-6, 1, -4))
		enseigne_suspendue(m, Vector3.new(7, 9.4, 10.2), "Taverne")
		tonneau(m, Vector3.new(-9, 0, 12))
		tonneau(m, Vector3.new(-11.4, 0, 12.6))
		fini(m)
	end
	-- Forge : bâtisse de pierre, foyer rougeoyant dehors, enclume, baquet
	do
		local m, base = maison("Forge", { largeur = 18, profondeur = 14, hauteur = 9, mur = rgb(140, 136, 128), toit = rgb(92, 92, 98), toitMat = "ardoise", pierre = true, porteDecal = -4 })
		-- foyer
		P(m, "Foyer", Vector3.new(4, 3, 3.4), Vector3.new(5, 1.5, 9.4), PIERRE, Mat.Cobblestone)
		local braise = P(m, "Braise", Vector3.new(3, 0.4, 2.4), Vector3.new(5, 3.1, 9.4), rgb(255, 110, 40), Mat.Neon, { collide = false })
		local fire = Instance.new("Fire")
		fire.Size = 3
		fire.Heat = 6
		fire.Parent = braise
		local light = Instance.new("PointLight")
		light.Color = rgb(255, 140, 70)
		light.Range = 18
		light.Brightness = 2
		light.Parent = braise
		P(m, "Hotte", Vector3.new(4.4, 4, 3.6), Vector3.new(5, 6.4, 9.4), PIERRE_CLAIRE, Mat.Cobblestone, { forme = "Wedge", rot = CFrame.Angles(0, math.rad(180), 0) })
		-- enclume sur son billot
		P(m, "Billot", Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, 0.8, 11.5), BOIS_FONCE, Mat.Wood, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)) })
		P(m, "Enclume", Vector3.new(2.2, 0.8, 1), Vector3.new(0, 2, 11.5), FER, Mat.Metal)
		P(m, "Corne", Vector3.new(0.8, 0.6, 0.8), Vector3.new(-1.4, 2.1, 11.5), FER, Mat.Metal, { forme = "Wedge", rot = CFrame.Angles(0, math.rad(90), 0) })
		tonneau(m, Vector3.new(-2.6, 0, 12))
		P(m, "Eau", Vector3.new(0.1, 1.8, 1.8), Vector3.new(-2.6, 2.25, 12), rgb(60, 90, 110), Mat.Glass, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)), collide = false })
		attache(base, "Travail", CFrame.new(0, 1, 9.5))
		enseigne_suspendue(m, Vector3.new(-7, 8, 7.2), "Forge")
		reperesFeu(m)
		fini(m)
	end
	-- Chapelle : pierre, nef haute, clocher carré avec sa cloche
	do
		local m, base = maison("Chapelle", { largeur = 16, profondeur = 26, hauteur = 13, mur = rgb(170, 164, 152), toit = rgb(86, 86, 94), toitMat = "ardoise", pierre = true, porteDecal = 0 })
		-- clocher sur la façade
		P(m, "Clocher", Vector3.new(6, 26, 6), Vector3.new(0, 13.8, 14.4), PIERRE_CLAIRE, Mat.Cobblestone)
		P(m, "Abat-son", Vector3.new(6.2, 3, 4), Vector3.new(0, 22, 14.4), rgb(40, 36, 34), Mat.Slate)
		P(m, "Cloche", Vector3.new(2.2, 2.2, 2.2), Vector3.new(0, 21.6, 14.4), rgb(176, 140, 60), Mat.Metal, { forme = "Ball", collide = false })
		for _, r in { 0, 90, 180, 270 } do
			P(m, "Fleche", Vector3.new(6.4, 7, 3.2), Vector3.zero, rgb(80, 80, 88), Mat.RoofShingles,
				{ forme = "Wedge", cf = CFrame.new(0, 30.3, 14.4) * CFrame.Angles(0, math.rad(r), 0) * CFrame.new(0, 0, -1.6) })
		end
		-- bancs et autel
		for z = -8, 4, 3 do
			for _, x in { -4, 4 } do
				P(m, "Banc", Vector3.new(5, 1.2, 1), Vector3.new(x, 1.4, z), BOIS, Mat.WoodPlanks)
			end
		end
		P(m, "Autel", Vector3.new(5, 3, 2.4), Vector3.new(0, 2.3, -11), PIERRE_CLAIRE, Mat.Marble)
		P(m, "Nappe", Vector3.new(5.2, 0.2, 2.6), Vector3.new(0, 3.9, -11), rgb(236, 228, 210), Mat.Fabric, { collide = false })
		for _, x in { -1.8, 1.8 } do
			P(m, "Cierge", Vector3.new(0.3, 1.2, 0.3), Vector3.new(x, 4.6, -11), rgb(245, 240, 225), Mat.SmoothPlastic, { collide = false })
			local c = P(m, "Flamme", Vector3.new(0.14, 0.22, 0.14), Vector3.new(x, 5.28, -11), rgb(241, 193, 99), Mat.Neon, { collide = false })
			local fl = Instance.new("PointLight")
			fl.Color = rgb(255, 200, 120)
			fl.Range = 8
			fl.Parent = c
		end
		attache(base, "Travail", CFrame.new(0, 1, -8))
		fini(m)
	end
	-- Marché : trois étals à auvent rayé, caisses de légumes
	if not sansMarche then
		local m = nouveau("Marche_Village")
		local toiles = { rgb(170, 50, 44), rgb(46, 86, 150), rgb(70, 120, 60) }
		for i, x in { -7, 0, 7 } do
			P(m, "Comptoir", Vector3.new(5, 2.6, 2.2), Vector3.new(x, 1.3, 0), BOIS, Mat.WoodPlanks)
			for _, s in { -1, 1 } do
				P(m, "Montant", Vector3.new(0.35, 5.6, 0.35), Vector3.new(x + s * 2.3, 2.8, -1.2), BOIS_FONCE, Mat.Wood)
			end
			P(m, "Auvent", Vector3.new(5.6, 0.2, 3.6), Vector3.zero, toiles[i], Mat.Fabric, { cf = CFrame.new(x, 5.4, 0) * CFrame.Angles(math.rad(-14), 0, 0), collide = false })
			local fruits = { rgb(220, 60, 50), rgb(240, 150, 40), rgb(120, 190, 80) }
			for k = -1, 1 do
				P(m, "Panier", Vector3.new(1.2, 0.5, 1.2), Vector3.new(x + k * 1.5, 2.85, 0.2), BOIS_CLAIR, Mat.WoodPlanks, { collide = false })
				P(m, "Fruits", Vector3.new(1, 0.5, 1), Vector3.new(x + k * 1.5, 3.2, 0.2), fruits[(k + i) % 3 + 1], Mat.SmoothPlastic, { forme = "Ball", collide = false })
			end
		end
		P(m, "Caisse", Vector3.new(2, 2, 2), Vector3.new(11, 1, 1), BOIS_CLAIR, Mat.WoodPlanks)
		P(m, "Caisse", Vector3.new(1.6, 1.6, 1.6), Vector3.new(11.2, 2.8, 1.1), BOIS, Mat.WoodPlanks, { rot = CFrame.Angles(0, 0.4, 0) })
		fini(m)
	end
	-- Ruine (maison de départ du joueur)
	do
		local m, base = maison("Ruine", { largeur = 20, profondeur = 16, hauteur = 9, mur = rgb(150, 146, 136), toit = rgb(110, 84, 60), ruine = true, porteDecal = 2 })
		lit(m, base, Vector3.new(-6, 1, -3.5), rgb(0, 0, 0), true)
		P(m, "Gravats", Vector3.new(2, 1, 1.6), Vector3.new(7, 1.3, 4), PIERRE, Mat.Cobblestone, { rot = CFrame.Angles(0, 0.4, 0.2) })
		P(m, "Gravats", Vector3.new(1.4, 0.8, 1.2), Vector3.new(5.6, 1.2, 5.2), PIERRE_CLAIRE, Mat.Cobblestone, { rot = CFrame.Angles(0.3, 0.8, 0) })
		P(m, "Lierre", Vector3.new(0.2, 5, 4), Vector3.new(-10.04, 4, 2), rgb(70, 120, 60), Mat.Grass, { collide = false })
		attache(base, "CoffreSpot", CFrame.new(2, 1, -5.5))
		attache(base, "Travail", CFrame.new(0, 1, 0))
		fini(m)
	end
end

-- ---------------------------------------------------------------- Décor de village et de ferme

-- Potence à lanterne (Lampadaire des villages)
-- ---------------------------------------------------------------- Village, 2e vague (étape 3C)
-- Auberge (lits à louer = point de réapparition), écurie, tour de guet, pan de palissade.
-- Séparé de maisons() : on peut le relancer seul sans écraser les retouches faites dans Studio.
function M.villages2(sansPalissade: boolean?)
	dossier = dossierModeles()
	-- Auberge : colombages sur deux niveaux d'apparence, salle commune, quatre lits à louer
	do
		local m, base = maison("Auberge", { largeur = 24, profondeur = 18, hauteur = 12, mur = rgb(226, 206, 160), toit = rgb(120, 96, 62), toitMat = "chaume", porteDecal = 0, etage = 8, fleurs = true })
		for i, x in { -8, -3, 3, 8 } do
			lit(m, base, Vector3.new(x, 1, -4.5), ({ rgb(150, 50, 46), rgb(46, 86, 140), rgb(70, 110, 60), rgb(150, 110, 50) })[i], false)
			attache(base, "LitAuberge" .. i, CFrame.new(x, 1, -0.6))
		end
		table_chaises(m, Vector3.new(0, 1, 4))
		lampe_interieure(m, Vector3.new(0, 11.4, 0), 12.8)
		attache(base, "Travail", CFrame.new(-6, 1, 5))
		enseigne_suspendue(m, Vector3.new(6, 9.4, 9.2), "Auberge")
		fini(m)
	end
	-- Écurie : charpente ouverte sur la façade, stalles, foin, abreuvoir
	do
		local m = nouveau("Ecurie")
		local W, D, H = 22, 12, 8
		P(m, "Sol", Vector3.new(W, 0.6, D), Vector3.new(0, 0.3, 0), rgb(150, 120, 80), Mat.WoodPlanks)
		for _, x in { -W / 2 + 0.4, -W / 2 + 7.6, W / 2 - 7.6, W / 2 - 0.4 } do
			for _, z in { -D / 2 + 0.4, D / 2 - 0.4 } do
				P(m, "Poteau", Vector3.new(0.8, H, 0.8), Vector3.new(x, H / 2 + 0.6, z), BOIS_FONCE, Mat.Wood)
			end
		end
		P(m, "Fond", Vector3.new(W, H, 0.6), Vector3.new(0, H / 2 + 0.6, -D / 2 + 0.3), BOIS, Mat.WoodPlanks)
		for _, s in { -1, 1 } do
			P(m, "Cote", Vector3.new(0.6, H, D), Vector3.new(s * (W / 2 - 0.3), H / 2 + 0.6, 0), BOIS, Mat.WoodPlanks)
			P(m, "Pan", Vector3.new(W + 2, 0.7, D / 2 + 2.2), Vector3.zero, rgb(110, 90, 58), Mat.Grass,
				{ cf = CFrame.new(0, H + 2.3, s * (D / 4 + 0.4)) * CFrame.Angles(math.rad(s * 30), 0, 0) })
		end
		P(m, "Faitage", Vector3.new(W + 2.2, 0.6, 0.6), Vector3.new(0, H + 3.9, 0), BOIS_FONCE, Mat.Wood)
		for _, x in { -3.6, 3.6 } do
			P(m, "Stalle", Vector3.new(0.4, 3.4, D - 4), Vector3.new(x, 2.3, -1.2), BOIS_CLAIR, Mat.WoodPlanks)
		end
		for _, x in { -7.2, 0, 7.2 } do
			P(m, "Foin", Vector3.new(3.2, 1.2, 2.2), Vector3.new(x, 1.2, -D / 2 + 1.8), rgb(214, 186, 100), Mat.Grass)
			P(m, "Mangeoire", Vector3.new(3, 1, 1.2), Vector3.new(x, 2.6, -D / 2 + 1), BOIS_FONCE, Mat.WoodPlanks)
		end
		P(m, "Abreuvoir", Vector3.new(4, 1.4, 1.6), Vector3.new(-6, 0.7, D / 2 + 2), BOIS, Mat.WoodPlanks)
		P(m, "Eau", Vector3.new(3.6, 0.2, 1.2), Vector3.new(-6, 1.35, D / 2 + 2), rgb(70, 120, 150), Mat.Glass, { collide = false, transp = 0.25 })
		attache(m.PrimaryPart, "Travail", CFrame.new(0, 1, 2))
		enseigne_suspendue(m, Vector3.new(W / 2 - 7.6, 7, D / 2), "Écurie")
		fini(m)
	end
	-- Tour de guet : quatre piliers, plate-forme, garde-corps, toit pointu, échelle
	do
		local m = nouveau("Tour_Guet")
		local Hh = 16
		for _, x in { -2.6, 2.6 } do
			for _, z in { -2.6, 2.6 } do
				P(m, "Pilier", Vector3.new(1, Hh + 4, 1), Vector3.new(x, (Hh + 4) / 2, z), BOIS_FONCE, Mat.Wood)
			end
			P(m, "Croisillon", Vector3.new(0.4, 0.4, 7.6), Vector3.zero, BOIS, Mat.Wood, { cf = CFrame.new(x, Hh / 2, 0) * CFrame.Angles(math.rad(62), 0, 0) })
		end
		P(m, "Plateforme", Vector3.new(7.4, 0.6, 7.4), Vector3.new(0, Hh, 0), BOIS, Mat.WoodPlanks)
		for _, r in { 0, 90, 180, 270 } do
			P(m, "GardeCorps", Vector3.new(7.4, 2, 0.4), Vector3.zero, BOIS_CLAIR, Mat.WoodPlanks, { cf = CFrame.Angles(0, math.rad(r), 0) * CFrame.new(0, Hh + 1.3, 3.5) })
			P(m, "Toit", Vector3.new(8.4, 4, 4.2), Vector3.zero, rgb(110, 90, 58), Mat.Grass,
				{ forme = "Wedge", cf = CFrame.new(0, Hh + 6, 0) * CFrame.Angles(0, math.rad(r), 0) * CFrame.new(0, 0, -2.1) })
		end
		for y = 1, Hh - 1, 1.4 do
			P(m, "Barreau", Vector3.new(1.8, 0.25, 0.25), Vector3.new(0, y, 3.4), BOIS_CLAIR, Mat.Wood, { collide = false })
		end
		for _, x in { -0.9, 0.9 } do
			P(m, "Montant", Vector3.new(0.3, Hh, 0.3), Vector3.new(x, Hh / 2, 3.4), BOIS, Mat.Wood)
		end
		P(m, "Brasero", Vector3.new(1.2, 0.8, 1.2), Vector3.new(2.2, Hh + 0.7, -2.2), FER, Mat.Metal)
		local feu = P(m, "Braise", Vector3.new(0.92, 0.18, 0.92), Vector3.new(2.2, Hh + 1.15, -2.2), rgb(255, 154, 75), Mat.Neon, { collide = false })
		local l = Instance.new("PointLight")
		l.Color = rgb(255, 150, 70)
		l.Range = 22
		l.Parent = feu
		fini(m)
	end
	-- Pan de palissade (8 studs) : pieux taillés en pointe, traverse
	if not sansPalissade then
		local m = nouveau("Palissade")
		for i = 0, 4 do -- 5 pieux de 1,6 : léger (une palissade de village en compte des dizaines)
			local x = -3.2 + i * 1.6
			local h = 7 + ((i * 37) % 5) * 0.3
			P(m, "Pieu", Vector3.new(h, 1.5, 1.5), Vector3.zero, BOIS, Mat.Wood, { forme = "Cylinder", cf = CFrame.new(x, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)) })
			P(m, "Pointe", Vector3.new(1.5, 1.2, 1.5), Vector3.zero, BOIS_CLAIR, Mat.Wood, { forme = "Wedge", cf = CFrame.new(x, h + 0.6, 0) })
		end
		P(m, "Traverse", Vector3.new(8, 0.5, 0.5), Vector3.new(0, 4.5, -0.6), BOIS_FONCE, Mat.Wood)
		fini(m)
	end
	return #dossier:GetChildren()
end

-- Grand moulin de village : tour de pierre, toit de bardeaux, 4 ailes à claire-voie. Les ailes sont
-- un modèle « Ailes » (pièce centrale « Moyeu ») marqué AilesMoulin : elles tournent chez chaque
-- joueur (Ambiance.client), sans réseau. Façade (porte) vers +Z, ailes à l'arrière-haut vers -Z.
function M.moulin()
	dossier = dossierModeles()
	local m = nouveau("Moulin_Village")
	local UPC = CFrame.Angles(0, 0, math.rad(90)) -- cylindre debout
	local CREME = rgb(236, 222, 190)
	P(m, "Socle", Vector3.new(2, 15, 15), Vector3.new(0, 1, 0), PIERRE, Mat.Cobblestone, { forme = "Cylinder", rot = UPC })
	P(m, "Tour", Vector3.new(12, 13, 13), Vector3.new(0, 8, 0), CREME, Mat.Plaster, { forme = "Cylinder", rot = UPC })
	P(m, "Tour", Vector3.new(10, 11, 11), Vector3.new(0, 19, 0), CREME, Mat.Plaster, { forme = "Cylinder", rot = UPC })
	for _, y in { 2.2, 14, 24 } do
		P(m, "Cerclage", Vector3.new(0.6, y < 10 and 13.3 or 11.3, y < 10 and 13.3 or 11.3), Vector3.new(0, y, 0), BOIS_FONCE, Mat.Wood, { forme = "Cylinder", rot = UPC, collide = false })
	end
	-- toit : cône de bardeaux (anneaux qui rétrécissent)
	for i = 0, 5 do
		local d = 12.6 - i * 2
		P(m, "Toit", Vector3.new(1.2, d, d), Vector3.new(0, 24.8 + i * 1.1, 0), rgb(110, 70, 48), Mat.WoodPlanks, { forme = "Cylinder", rot = UPC })
	end
	P(m, "Epi", Vector3.new(0.4, 2.4, 0.4), Vector3.new(0, 32.05, 0), FER, Mat.Metal)
	-- porte et fenêtres (vitres allumées le soir)
	P(m, "Porte", Vector3.new(3.4, 6, 0.6), Vector3.new(0, 4.6, 6.3), rgb(92, 64, 42), Mat.WoodPlanks)
	P(m, "Linteau", Vector3.new(4.4, 0.7, 0.8), Vector3.new(0, 7.8, 6.3), BOIS_FONCE, Mat.Wood)
	P(m, "Marche", Vector3.new(4.6, 0.5, 2), Vector3.new(0, 0.25, 7.6), PIERRE, Mat.Cobblestone)
	for _, w in { { 0, 11.5, 6.6, 0 }, { 6.6, 9, 0, 90 }, { -6.6, 9, 0, -90 }, { 0, 20, 5.6, 0 } } do
		local cf = CFrame.new(w[1], w[2], w[3]) * CFrame.Angles(0, math.rad(w[4]), 0)
		local v = P(m, "Vitre", Vector3.new(1.8, 2.2, 0.3), Vector3.zero, rgb(52, 62, 70), Mat.Glass, { cf = cf, collide = false, transp = 0.2 })
		CollectionService:AddTag(v, "Fenetre")
		P(m, "Cadre", Vector3.new(2.3, 0.3, 0.5), Vector3.zero, BOIS_FONCE, Mat.Wood, { cf = cf * CFrame.new(0, 1.2, 0), collide = false })
		P(m, "Cadre", Vector3.new(2.3, 0.3, 0.5), Vector3.zero, BOIS_FONCE, Mat.Wood, { cf = cf * CFrame.new(0, -1.2, 0), collide = false })
	end
	-- sacs de farine au pied
	for i, x in { -3.2, -2, 3 } do
		P(m, "Sac", Vector3.new(1.4, 1.6, 1.1), Vector3.new(x, 0.8, 7.4 + (i % 2) * 0.6), rgb(226, 214, 186), Mat.Fabric)
	end
	-- arbre et ailes, à l'arrière en hauteur
	local hub = Vector3.new(0, 22.5, -6.4)
	P(m, "Arbre", Vector3.new(4, 1.2, 1.2), hub + Vector3.new(0, 0, 2), BOIS_FONCE, Mat.Wood, { forme = "Cylinder", rot = CFrame.Angles(0, math.rad(90), 0), collide = false })
	local ailes = Instance.new("Model")
	ailes.Name = "Ailes"
	local moyeu = P(ailes, "Moyeu", Vector3.new(1.6, 1.6, 1.6), hub, BOIS_FONCE, Mat.Wood, { forme = "Ball", collide = false })
	ailes.PrimaryPart = moyeu
	for k = 0, 3 do
		local rot = CFrame.new(hub) * CFrame.Angles(0, 0, math.rad(k * 90 + 20))
		P(ailes, "Bras", Vector3.new(0.5, 15, 0.5), Vector3.zero, BOIS, Mat.Wood, { cf = rot * CFrame.new(0, 7.8, 0), collide = false })
		P(ailes, "Toile", Vector3.new(3.4, 10, 0.12), Vector3.zero, rgb(240, 232, 214), Mat.Fabric, { cf = rot * CFrame.new(1.9, 9.4, -0.1), collide = false })
		for _, y in { 4.6, 9.6, 14.6 } do
			P(ailes, "Latte", Vector3.new(3.8, 0.2, 0.2), Vector3.zero, BOIS, Mat.Wood, { cf = rot * CFrame.new(1.9, y, 0.05), collide = false })
		end
		P(ailes, "Longeron", Vector3.new(0.2, 10.4, 0.2), Vector3.zero, BOIS, Mat.Wood, { cf = rot * CFrame.new(3.7, 9.4, 0.05), collide = false })
	end
	CollectionService:AddTag(ailes, "AilesMoulin")
	ailes.Parent = m
	attache(m.PrimaryPart, "Entree", CFrame.new(0, 0, 10))
	fini(m)
	return m
end

-- Château fort sur colline (image cible) : enceinte crénelée, 4 tours rondes à toits coniques
-- d'ardoise, châtelet à 2 tourelles et bannières, donjon carré + grande tour centrale. Socle de
-- pierre profond (posé sur une pente, il ne flotte pas). Cour ouverte : on y entre par la porte (+Z).
function M.chateau()
	dossier = dossierModeles()
	local m = nouveau("Chateau")
	local UPC = CFrame.Angles(0, 0, math.rad(90))
	local MUR = rgb(150, 146, 138)
	local MUR2 = rgb(170, 166, 156)
	local ARDOISE = rgb(64, 76, 104)
	local ROUGE = rgb(168, 40, 40)
	local function merlons(x0: number, z0: number, x1: number, z1: number, y: number, ep: number)
		local d = Vector3.new(x1 - x0, 0, z1 - z0)
		local n = math.max(1, math.floor(d.Magnitude / 4.2))
		local dir = d.Unit
		for i = 0, n do
			local pos = Vector3.new(x0, y + 1, z0) + dir * (i * d.Magnitude / n)
			P(m, "Merlon", Vector3.new(1.9, 2, ep), Vector3.zero, MUR, Mat.Cobblestone,
				{ cf = CFrame.lookAt(pos, pos + Vector3.new(-dir.Z, 0, dir.X)) })
		end
	end
	local function cone(pos: Vector3, d0: number, h: number, couleur: Color3)
		local n = h < 6 and 4 or 5
		for i = 0, n - 1 do
			local d = d0 * (1 - i / (n - 1) * (6 / 7))
			P(m, "Toit", Vector3.new(h / n + 0.05, d, d), pos + Vector3.new(0, i * h / n + h / n / 2, 0), couleur, Mat.Slate, { forme = "Cylinder", rot = UPC })
		end
		P(m, "Epi", Vector3.new(0.3, 3, 0.3), pos + Vector3.new(0, h + 1.5, 0), FER, Mat.Metal, { collide = false })
		P(m, "Fanion", Vector3.new(0.1, 1, 1.8), pos + Vector3.new(0, h + 2.4, 0.95), ROUGE, Mat.Fabric, { collide = false })
	end
	local function fenetre(cf: CFrame)
		local v = P(m, "Vitre", Vector3.new(1.2, 2.6, 0.3), Vector3.zero, rgb(52, 62, 70), Mat.Glass, { cf = cf, collide = false, transp = 0.2 })
		CollectionService:AddTag(v, "Fenetre")
		P(m, "Arc", Vector3.new(1.6, 0.5, 0.5), Vector3.zero, MUR2, Mat.Cobblestone, { cf = cf * CFrame.new(0, 1.5, 0), collide = false })
	end
	-- socle profond
	P(m, "Socle", Vector3.new(50, 18, 50), Vector3.new(0, -8, 0), PIERRE, Mat.Cobblestone)
	P(m, "Cour", Vector3.new(38, 0.4, 38), Vector3.new(0, 1.2, 0), rgb(150, 130, 104), Mat.Cobblestone)
	-- courtines (porte de 8 studs au sud)
	local H = 14
	P(m, "Mur", Vector3.new(40, H, 3), Vector3.new(0, 1 + H / 2, -20), MUR, Mat.Cobblestone)
	P(m, "Mur", Vector3.new(3, H, 40), Vector3.new(-20, 1 + H / 2, 0), MUR, Mat.Cobblestone)
	P(m, "Mur", Vector3.new(3, H, 40), Vector3.new(20, 1 + H / 2, 0), MUR, Mat.Cobblestone)
	P(m, "Mur", Vector3.new(16, H, 3), Vector3.new(-12, 1 + H / 2, 20), MUR, Mat.Cobblestone)
	P(m, "Mur", Vector3.new(16, H, 3), Vector3.new(12, 1 + H / 2, 20), MUR, Mat.Cobblestone)
	P(m, "Linteau", Vector3.new(8, 4, 3), Vector3.new(0, 1 + H - 2, 20), MUR, Mat.Cobblestone)
	merlons(-18, -20, 18, -20, 1 + H, 3.2)
	merlons(-20, -18, -20, 18, 1 + H, 3.2)
	merlons(20, -18, 20, 18, 1 + H, 3.2)
	merlons(-18, 20, 18, 20, 1 + H, 3.2)
	-- herse relevée
	for x = -3, 3, 1.5 do
		P(m, "Herse", Vector3.new(0.3, 3, 0.3), Vector3.new(x, 1 + H - 5.5, 21.2), FER, Mat.Metal, { collide = false })
	end
	P(m, "HerseTraverse", Vector3.new(7.6, 0.3, 0.3), Vector3.new(0, 1 + H - 6.8, 21.2), FER, Mat.Metal, { collide = false })
	-- châtelet : 2 tourelles carrées et bannières
	for _, sx in { -1, 1 } do
		local x = sx * 7
		P(m, "Tourelle", Vector3.new(6, 20, 6), Vector3.new(x, 11, 21), MUR2, Mat.Cobblestone)
		merlons(x - 2.6, 24, x + 2.6, 24, 21, 1.2)
		merlons(x - 2.6, 18, x + 2.6, 18, 21, 1.2)
		merlons(x - 3, 18.4, x - 3, 23.6, 21, 1.2)
		merlons(x + 3, 18.4, x + 3, 23.6, 21, 1.2)
		P(m, "Banniere", Vector3.new(3, 7, 0.2), Vector3.new(x, 13, 24.15), ROUGE, Mat.Fabric, { collide = false })
		P(m, "Blason", Vector3.new(1.6, 1.6, 0.25), Vector3.zero, OR, Mat.SmoothPlastic, { collide = false, cf = CFrame.new(x, 14, 24.3) * CFrame.Angles(0, 0, math.rad(45)) })
		fenetre(CFrame.new(x, 17, 24.1))
	end
	-- tours d'angle rondes
	for _, c in { { -20, -20 }, { 20, -20 }, { -20, 20 }, { 20, 20 } } do
		local pos = Vector3.new(c[1], 0, c[2])
		P(m, "Tour", Vector3.new(24, 11, 11), pos + Vector3.new(0, 13, 0), MUR2, Mat.Cobblestone, { forme = "Cylinder", rot = UPC })
		P(m, "Corniche", Vector3.new(1.4, 12.6, 12.6), pos + Vector3.new(0, 25.3, 0), MUR, Mat.Cobblestone, { forme = "Cylinder", rot = UPC })
		cone(pos + Vector3.new(0, 26, 0), 13, 11, ARDOISE)
		local out = Vector3.new(c[1], 0, c[2]).Unit
		local at = pos + Vector3.new(0, 18, 0) + out * 5.4
		fenetre(CFrame.lookAt(at, at + out))
	end
	-- donjon carré au fond de la cour, crénelé, 4 échauguettes
	P(m, "Donjon", Vector3.new(18, 26, 16), Vector3.new(0, 14, -9), MUR2, Mat.Cobblestone)
	merlons(-9, -1, 9, -1, 27, 1.4)
	merlons(-9, -17, 9, -17, 27, 1.4)
	merlons(-9, -16, -9, -2, 27, 1.4)
	merlons(9, -16, 9, -2, 27, 1.4)
	for _, c in { { -9, -1 }, { 9, -1 }, { -9, -17 }, { 9, -17 } } do
		local pos = Vector3.new(c[1], 0, c[2])
		P(m, "Echauguette", Vector3.new(6, 4, 4), pos + Vector3.new(0, 27, 0), MUR, Mat.Cobblestone, { forme = "Cylinder", rot = UPC })
		cone(pos + Vector3.new(0, 30, 0), 4.6, 5, ARDOISE)
	end
	for _, x in { -5, 0, 5 } do
		fenetre(CFrame.new(x, 20, -0.9))
		fenetre(CFrame.new(x, 13, -0.9))
	end
	P(m, "PorteDonjon", Vector3.new(4, 6.5, 0.6), Vector3.new(0, 4.6, -0.8), rgb(92, 64, 42), Mat.WoodPlanks)
	P(m, "Perron", Vector3.new(7, 1, 3), Vector3.new(0, 1.9, 0.7), PIERRE, Mat.Cobblestone)
	-- grande tour centrale (la silhouette qu'on voit de loin)
	P(m, "GrandeTour", Vector3.new(16, 9, 9), Vector3.new(0, 35, -9), MUR2, Mat.Cobblestone, { forme = "Cylinder", rot = UPC })
	P(m, "Corniche", Vector3.new(1.2, 10.4, 10.4), Vector3.new(0, 43.4, -9), MUR, Mat.Cobblestone, { forme = "Cylinder", rot = UPC })
	cone(Vector3.new(0, 44, -9), 10.8, 12, ARDOISE)
	fenetre(CFrame.new(0, 38, -4.4))
	attache(m.PrimaryPart, "Entree", CFrame.new(0, 2, 30))
	fini(m)
	return m
end

-- Champ de blé doré de village (décor, image cible) : terre labourée, blé dense en rangs, clôture
-- de rondins sur trois côtés, ouverte devant (+Z). Chaque touffe se récolte au clic (Moissons).
function M.champBle()
	dossier = dossierModeles()
	local m = nouveau("Champ_Ble")
	local W, D = 22, 16
	P(m, "Terre", Vector3.new(W, 0.6, D), Vector3.new(0, 0.1, 0), rgb(112, 80, 52), Mat.Ground)
	local ecarts = { -0.07, 0.13, -0.11, 0.17, 0.02, -0.15, 0.09, 0.15, -0.06, 0.12, -0.08 }
	local hauteurs = { 3.24, 3.66, 3.35, 3.55, 3.47, 3.75, 3.29, 3.6, 3.14, 3.5, 3.38 }
	local tons = { rgb(172, 125, 52), rgb(211, 159, 66), rgb(232, 190, 87) }
	local angles = { -5, 2, 4, -6, 3, 7, -4, 6 }
	for iz = 0, 7 do
		local rang = -D / 2 + 1.2 + iz * ((D - 2.4) / 7)
		for ix = 0, 10 do
			local x = -W / 2 + 1.2 + ix * ((W - 2.4) / 10) + ecarts[(ix + iz * 3) % #ecarts + 1]
			local z = rang
			local h = hauteurs[(ix * 3 + iz * 4) % #hauteurs + 1]
			local gold = tons[(ix + iz * 2) % 3 + 1]
			local tilt = CFrame.Angles(math.rad(angles[(ix + iz * 3) % #angles + 1]), 0, math.rad(angles[(ix * 2 + iz) % #angles + 1]))
			-- une « Touffe » = un bloc récoltable au clic (Systemes/Moissons)
			local t = Instance.new("Model")
			t.Name = "Touffe"
			t.Parent = m
			local hauteur = h + 0.42
			local largeur = 1.33 + (ix + iz) % 3 * 0.13
			local azimut = CFrame.Angles(0, ((ix * 5 + iz * 7) % 13) * math.pi / 7, 0)
			P(t, "Epis", Vp(largeur, hauteur, 0.86 + ix % 2 * 0.19), Vector3.zero, gold, Mat.Grass,
				{ cf = CFrame.new(x, 0.36 + hauteur / 2, z) * tilt * azimut, collide = false, forme = "Wedge" })
			if (ix + iz) % 2 == 0 then
				local d = ({ -0.15, 0.05, 0.17, -0.04 })[(ix + 2 * iz) % 4 + 1]
				reliefProp(t, "Épi mûr au revers clair", Vp(largeur * 0.64, 0.73, 0.25),
					Vp(x + d, 0.36 + hauteur * 0.76, z - 0.17), iz % 3 == 0 and CHAUME or OR_PALE, Mat.Grass,
					6, (ix % 3 - 1) * 7, (iz % 3 - 1) * 6, "Wedge")
			end
		end
	end
	-- Trois côtés bordés de deux lisses, avec les mêmes piquets que le champ d'origine.
	local function cote(a: Vector3, b: Vector3)
		local d = b - a
		local n = math.max(1, math.floor(d.Magnitude / 5.4))
		for i = 0, n do
			local hPiquet = 3.18 + i % 3 * 0.046
			P(m, "Piquet", Vp(0.59, hPiquet, 0.59), a + d * (i / n) + Vp(0, hPiquet / 2, 0),
				teinteProp(BOIS, i), Mat.Wood)
		end
		for _, y in { 1.2, 2.4 } do
			local mid = (a + b) / 2 + Vector3.new(0, y, 0)
			P(m, "Lisse", Vector3.new(0.35, 0.35, d.Magnitude), Vector3.zero, BOIS_CLAIR, Mat.Wood, { cf = CFrame.lookAt(mid, mid + d) })
		end
	end
	local hx, hz = W / 2 + 0.6, D / 2 + 0.6
	cote(Vector3.new(-hx, 0, -hz), Vector3.new(hx, 0, -hz))
	cote(Vector3.new(-hx, 0, -hz), Vector3.new(-hx, 0, hz))
	cote(Vector3.new(hx, 0, -hz), Vector3.new(hx, 0, hz))
	P(m, "Botte", Vp(2.4, 1.6, 1.6), Vp(hx + 2, 0.8, hz - 2), CHAUME, Mat.Grass,
		{ forme = "Ball", rot = CFrame.Angles(0, 0.09, 0) })
	reliefProp(m, "Ornière sombre du passage", Vp(17.39, 0.064, 0.43), Vp(0.19, 0.425, -1.44), BOIS_FONCE, Mat.Ground, 0, -1)
	reliefProp(m, "Crête claire émiettée du passage", Vp(16.98, 0.068, 0.37), Vp(-0.18, 0.426, 1.15), rgb(143, 101, 66), Mat.Ground, 0, 2)
	for _, x in { hx + 1.52, hx + 2.38 } do
		reliefProp(m, "Lien sombre de la botte", Vp(0.095, 1.05, 1.49), Vp(x, 0.96, hz - 2),
			BOIS_FONCE, Mat.Fabric, 0, 4, 4)
	end
	reliefProp(m, "Nappe de paille sur la botte", Vp(1.79, 0.25, 0.81), Vp(hx + 2.02, 1.55, hz - 1.94),
		OR_PALE, Mat.Grass, -7, 4, 5, "Ball")
	detailProp(m, "Paille qui retombe", Vp(0.61, 0.46, 0.20), Vp(hx + 1.80, 0.94, hz - 1.40), rgb(162, 111, 49), Mat.Grass, Vp(4, 11, 6), "Wedge")
	fini(m)
	return m
end

function PROPS_VALDOR.Champ_Ble() M.champBle() end

-- Plante sauvage (herboristerie, Systemes/Herbes) : touffe de feuilles et petites fleurs « Fleur »
-- recolorées selon la plante (camomille blanche, millepertuis jaune, mandragore violette…)
function M.herbe()
	dossier = dossierModeles()
	local m = nouveau("Herbe_Sauvage")
	local rng = Random.new(7)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local h = rng:NextNumber(0.7, 1.3)
		local cf = CFrame.new(math.cos(a) * 0.35, h / 2, math.sin(a) * 0.35) * CFrame.Angles(math.rad(rng:NextNumber(-18, 18)), a, math.rad(rng:NextNumber(-18, 18)))
		P(m, "Feuille", Vector3.new(0.35, h, 0.12), Vector3.zero, rgb(76, 140, 62):Lerp(rgb(110, 170, 80), rng:NextNumber()), Mat.Grass, { cf = cf, collide = false })
	end
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2 + 0.4
		local r = rng:NextNumber(0.1, 0.45)
		local y = rng:NextNumber(1, 1.45)
		P(m, "Tige", Vector3.new(0.08, y, 0.08), Vector3.new(math.cos(a) * r, y / 2, math.sin(a) * r), rgb(70, 130, 60), Mat.SmoothPlastic, { collide = false })
		P(m, "Fleur", Vector3.new(0.32, 0.22, 0.32), Vector3.new(math.cos(a) * r, y + 0.08, math.sin(a) * r), rgb(250, 245, 200), Mat.SmoothPlastic, { collide = false })
	end
	fini(m)
	return m
end

-- Stations de métier (18/11) : enclume (forge) et métier à tisser
local function stations(corrigeesSeulement: boolean?)
	reconstruireProps(corrigeesSeulement and { "Enclume", "Bac_Tannage", "Alambic" } or NOMS_STATIONS)
	return true
end

function M.stations() return stations() end

function M.lampadaire() M.propsValdor("Lampadaire") end

-- Maisons seules (Maison_A/B/C, boutique, shérif, taverne, forge, chapelle, ruine…)
function M.maisons()
	dossier = dossierModeles()
	maisons()
	return #dossier:GetChildren()
end

-- Mise à jour Édition ciblée. Les autres modèles et les gabarits des personnages restent en place.
function M.propsPhase2()
	dossier = dossierModeles()
	maisons(true)
	M.villages2(true)
	stations(true)
	M.filonOr()
	M.puits()
	M.moulin()
	M.chateau()
	M.champBle()
end

function M.tout()
	dossier = dossierModeles()
	arbres()
	M.biomes()
	M.artisanat()
	M.creatures()
	M.formesBestiaire()
	M.securite()
	dossier = dossierModeles()
	sol()
	maisons()
	decor()
	M.villages2()
	M.moulin()
	M.chateau()
	M.tableauQuetes()
	M.champBle()
	M.herbe()
	M.stations()
	return #dossier:GetChildren()
end

-- Mammouth de givre (boss, 27/11) : le dessin GAGNANT du concours du 26/11 (Codex Sol, tools/concours/sol_mammouth.luau),
-- repris tel quel ; 320 pièces (budget boss), tête vers -Z, « Base » au sol. Branché sur Bestiaire.frost_mammoth (model).
local function mammouthSol(parent: Instance, origin: CFrame): Model
    local model = Instance.new("Model")
    model.Name = "Mammouth_Givre"

    local sombre = Color3.fromRGB(56, 37, 39)
    local brun = Color3.fromRGB(94, 62, 55)
    local fauve = Color3.fromRGB(132, 90, 73)
    local os = Color3.fromRGB(190, 164, 128)
    local ivoire = Color3.fromRGB(240, 237, 218)
    local givre = Color3.fromRGB(143, 191, 226)
    local cyan = Color3.fromRGB(54, 225, 255)
    local neon = Enum.Material.Neon
    local rad = math.rad
    local n = 0

    local function bloc(nom, x, y, z, largeur, hauteur, profondeur, couleur, repere, matiere)
        local part = Instance.new("Part")
        part.Name = nom
        part.Size = Vector3.new(largeur, hauteur, profondeur)
        part.CFrame = origin * (repere or CFrame.new()) * CFrame.new(x, y, z)
        part.Color = couleur
        part.Material = matiere or Enum.Material.SmoothPlastic
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Anchored = true
        part.CanCollide = false
        part.Parent = model
        n = n + 1
        return part
    end

    local function axe(depart, arrivee)
        local delta = arrivee - depart
        return CFrame.lookAt(depart:Lerp(arrivee, 0.5), arrivee), delta.Magnitude
    end

    local base = bloc("Base", 0, 0.1, 0, 1, 0.2, 1, sombre)
    base.Transparency = 1
    base.CastShadow = false
    base.PivotOffset = CFrame.new(0, -0.1, 0)
    model.PrimaryPart = base

    -- La bosse culmine au garrot. Les gradins se resserrent vers la croupe.
    bloc("Ventre", 0, 8.75, 0.96, 8.6, 5.8, 14.6, sombre)
    bloc("Cage thoracique", 0, 10.8, 0, 10.6, 4.4, 14.6, brun)
    bloc("Épaules", 0, 12.1, -3.5, 11.3, 5.8, 7.9, brun)
    bloc("Garrot inférieur", 0, 14.7, -3.2, 9.8, 3.6, 8, brun)
    bloc("Garrot supérieur", 0, 16.0, -3.0, 7.7, 3, 6.5, fauve)
    bloc("Dos", 0, 15.05, 1.70, 8.8, 2.9, 6.2, fauve)
    bloc("Reins", 0, 12.0, 4.1, 10.4, 4.3, 7.6, brun)
    bloc("Croupe haute", 0, 13.9, 5.5, 8.8, 2.6, 5.0, brun)
    bloc("Croupe basse", 0, 11.75, 8.13, 8.4, 3.9, 2.5, brun)
    bloc("Arrière-train", 0, 9.3, 8.05, 7.8, 4.8, 2.85, sombre)

    local cotes = {-1, 1}
    local pattes = {
        {-1, -5.55, 1.00}, {1, -5.12, 1.03},
        {-1, 6.10, 0.91}, {1, 6.66, 0.94},
    }
    for i, patte in ipairs(pattes) do
        local cote, z, taille = patte[1], patte[2], patte[3]
        local x = cote * (3.87 + 0.23 * taille)
        bloc("Pied", x, 0.65, z, 3.24 * taille, 1.30, 3.52 * taille, sombre)
        bloc("Paturon", x - cote * 0.12, 1.61, z + 0.12, 2.94 * taille, 1.38, 3.12 * taille, brun)
        bloc("Jambe", x - cote * 0.26, 3.22, z + 0.18, 2.73 * taille, 2.45, 2.98 * taille, brun)
        bloc("Haut de patte", x - cote * 0.37, 5.86, z + 0.23, 3.56 * taille, 4.56, 4.15 * taille, sombre)
        bloc("Toison du genou", x + cote * 0.79, 4.66, z - 0.71, 1.58 * taille, 2.51, 2.36 * taille, brun)
        bloc("Pointe de toison", x + cote * 0.96, 3.55, z - 0.82, 0.91 * taille, 1.21, 1.18 * taille, fauve)

        for orteil = -1, 1 do
            local central = orteil == 0
            bloc("Ongle", x + 0.88 * taille * orteil, 0.42, z - (central and 1.71 or 1.59) * taille,
                (central and 0.78 or 0.67) * taille, 0.84, 0.63 * taille, central and ivoire or os)
        end

        bloc("Corniche gelée du pied", x, 2.44, z - 1.24 * taille, 2.63 * taille, 0.54, 0.68 * taille, givre)
        bloc("Retombée de givre du pied", x + cote * 0.85, 2.10, z - 1.46 * taille,
            0.68 * taille, 0.72, 0.42 * taille, givre)
        bloc("Neige sur le paturon", x - cote * 0.43, 2.69, z - 1.47 * taille,
            1.14 * taille, 0.34, 0.38 * taille, ivoire)
        if i <= 2 then
            bloc("Givre du côté du pied", x + cote * 1.27 * taille, 2.28, z - 0.70 * taille,
                0.46, 0.68, 1.34 * taille, givre)
        end
    end

    -- Grandes mèches de couverture. Les pointes décalées cassent la ligne du ventre.
    -- Z, écart à l'axe, haut de mèche, longueur, profondeur.
    local flancs = {
        {-6.10, 4.76, 14.38, 5.38, 2.17}, {-4.29, 5.58, 14.00, 6.46, 2.35},
        {-2.44, 5.61, 13.96, 5.66, 2.45}, {-0.52, 5.47, 13.3, 5.42, 2.51},
        {1.50, 5.15, 12.95, 5.12, 2.45}, {3.51, 5.15, 12.87, 4.78, 2.50},
        {5.53, 5.14, 12.61, 5.40, 2.46}, {7.50, 4.69, 12.05, 4.98, 2.37},
    }
    for _, cote in ipairs(cotes) do
        for i, meche in ipairs(flancs) do
            local z, x, haut, longueur, epaisseur = table.unpack(meche)
            local decalage = (i % 3 - 1) * 0.31 * cote
            local repere = CFrame.new(cote * x, haut, z + decalage)
                * CFrame.Angles(rad(-7 + 2 * ((i + cote) % 4)), 0, rad(cote * (i % 3 - 1) * 3))
            bloc("Mèche de flanc", 0, -longueur / 2, 0,
                1.65, longueur, epaisseur, i % 3 == 0 and sombre or brun, repere)
            if i % 2 == 1 then
                bloc("Relief de la mèche", cote * 0.73, -longueur * 0.37, -0.30,
                    0.56, longueur * 0.53, epaisseur * 0.62, i % 3 == 2 and brun or fauve, repere)
            end
            bloc("Pointe de la mèche", cote * 0.28, -longueur + 0.02, 0.48,
                1.14, 1.26 + (i % 3) * 0.23, epaisseur * 0.46, i % 3 == 0 and brun or sombre, repere)
        end
        bloc("Mèche arrière", cote * 2.26, 10.1, 9.35, 2.08, 4.10, 0.93, brun)
        bloc("Pointe arrière", cote * 2.46, 8.12, 9.49, 1.12, 1.83, 0.71, sombre)
    end

    local queue = CFrame.new(0, 9.0, 9.29) * CFrame.Angles(rad(-19), 0, rad(12))
    bloc("Racine de la queue", 0, 0.24, 0, 1.54, 1.78, 1.16, brun, queue)
    bloc("Queue", 0, -0.98, 0.13, 1.07, 1.55, 1.04, brun, queue)
    bloc("Touffe de la queue", 0, -1.89, 0.18, 1.53, 1.20, 1.19, sombre, queue)

    -- La neige forme un manteau continu au sommet, puis se déchire sur les flancs.
    -- Z, altitude du manteau, largeur, profondeur, écart de corniche, chute du bord.
    local manteau = {
        {-5.60, 17.29, 7.01, 2.56, 4.35, 3.43}, {-3.24, 17.66, 8.06, 2.61, 4.73, 3.55},
        {-0.78, 17.51, 7.82, 2.59, 4.52, 3.1}, {1.62, 16.76, 7.66, 2.68, 4.48, 3.3},
        {3.99, 16.58, 7.62, 2.43, 4.42, 3.57}, {6.10, 15.30, 7.22, 2.48, 4.32, 3.18},
        {7.98, 14.52, 6.61, 2.24, 3.99, 3.39},
    }
    for i, rangee in ipairs(manteau) do
        local z, y, largeur, profondeur, x, chute = table.unpack(rangee)
        local decalage = (i % 3 - 1) * 0.28
        bloc("Plaque de givre dorsal", decalage, y, z, largeur, 1.06, profondeur, givre)
        bloc("Neige tassée", decalage * 3, y + 0.58, z - 0.10,
            largeur * 0.76, 0.32, profondeur * 0.69, ivoire)
        for _, cote in ipairs(cotes) do
            local pli = x + cote * decalage * 0.33
            local zPli = z + cote * decalage
            local retombee = chute + cote * decalage
            bloc("Corniche latérale", cote * pli, y - 0.73, zPli, 2.36, 1.19, profondeur * 0.92, givre)
            if (2 * i + cote) % 4 == 1 then
                bloc("Ourlet de neige", cote * (pli + 0.27), y - 0.13, zPli - profondeur * 0.12,
                    1.43, 0.3, profondeur * 0.61, ivoire)
            end
            bloc("Langue de glace", cote * (pli + 0.57), y - retombee * 0.51, zPli - 0.24,
                1.07, retombee * 0.66, profondeur * 0.61, givre)
            bloc("Pointe de glace", cote * (pli + 0.69), y - retombee * 0.87, zPli - 0.49,
                0.62, retombee * 0.41, profondeur * 0.28, i % 3 == 0 and ivoire or givre)
        end
    end
    bloc("Givre de croupe", 0, 13.36, 9.25, 6.60, 1.44, 0.93, givre)
    bloc("Frange de croupe", -0.86, 12.43, 9.51, 1.44, 1.67, 0.73, givre)
    bloc("Frange claire de croupe", 1.2, 12.94, 9.61, 1.1, 1.06, 0.46, ivoire)

    -- La crête se brise par paliers. Un filon oblique affleure sur la face des prismes.
    local function cristal(x, y, z, largeur, hauteur, profondeur, inclinaison, lacet, roulis)
        local repere = CFrame.new(x, y, z) * CFrame.Angles(rad(inclinaison), rad(lacet), rad(roulis))
        if hauteur >= 2.18 then
            bloc("Pied du cristal", 0, 0.18, 0, largeur * 1.28, 0.57, profondeur * 1.2, givre, repere)
        end
        bloc("Prisme de glace", 0, hauteur * 0.40, 0,
            largeur, hauteur * 0.82, profondeur, givre, repere)
        local arete = repere * CFrame.new(-largeur * 0.08, hauteur * 0.79, profondeur * 0.07)
            * CFrame.Angles(rad(13), 0, rad(roulis < 0 and -24 or 28))
        bloc("Prisme haut", 0, 0, 0, largeur * 0.72, hauteur * 0.47, profondeur * 0.84, givre, arete)
        bloc("Sommet du cristal", largeur * 0.09, hauteur * 0.15, -profondeur * 0.20,
            largeur * 0.32, hauteur * 0.28, profondeur * 0.48, ivoire, arete)
        local filon = repere * CFrame.new(largeur * 0.04, hauteur * 0.48, -profondeur * 0.5)
            * CFrame.Angles(0, 0, rad(roulis < 0 and 14 or -17))
        bloc("Filon cyan", 0, 0, 0, largeur * 0.31, hauteur * 0.62, 0.15, cyan, filon, neon)
        if hauteur >= 2.18 then
            local tranche = repere * CFrame.new(largeur * 0.5, hauteur * 0.38, -profondeur * 0.06)
                * CFrame.Angles(rad(16), 0, 0)
            bloc("Retour du filon", 0, 0, 0, 0.14, hauteur * 0.50, profondeur * 0.25, cyan, tranche, neon)
        end
    end

    cristal(-0.65, 17.55, -4.95, 1.57, 2.19, 1.43, 13, -19, 9)
    cristal(0.38, 17.95, -2.64, 2.19, 3.14, 1.67, 18, 17, -10)
    cristal(-0.72, 17.81, -0.20, 1.66, 2.38, 1.41, 22, -16, 12)
    cristal(0.30, 16.99, 2.16, 1.98, 2.81, 1.60, 20, 15, -10)
    cristal(-0.42, 16.89, 4.30, 1.42, 2.18, 1.30, 24, -11, 10)
    cristal(0.52, 15.55, 6.22, 1.36, 1.87, 1.13, 24, 18, -11)
    cristal(-0.11, 14.80, 8.06, 1.08, 1.34, 0.98, 24, -13, 8)
    cristal(-2.26, 17.71, -2.9, 1.16, 1.45, 1.02, 9, -15, 24)
    cristal(2.10, 17.02, 1.34, 1.14, 1.60, 0.94, 16, 22, -24)

    bloc("Crâne", 0, 12.25, -8.34, 7.18, 6.20, 5.42, brun)
    bloc("Front", 0, 13.94, -9.08, 6.10, 2.65, 4.13, fauve)
    bloc("Mâchoire", 0, 10.15, -9.43, 5.34, 3.05, 3.88, sombre)
    bloc("Bavoir", 0, 8.48, -7.98, 5.68, 3.88, 3.42, sombre)
    bloc("Pointe du bavoir", 0.18, 6.73, -8.16, 2.1, 2.18, 2.42, brun)
    bloc("Racine de la trompe", 0, 11.63, -11.28, 2.73, 1.46, 1.59, fauve)
    bloc("Nœud des sourcils", 0, 12.89, -11.22, 1.82, 1.10, 1.26, brun)

    for _, cote in ipairs(cotes) do
        local tempe = CFrame.new(cote * 2.49, 12.36, -11.07) * CFrame.Angles(0, rad(-27 * cote), 0)
        local regard = tempe * CFrame.Angles(0, 0, rad(15 * cote))
        bloc("Orbite", 0, 0, 0, 2.09, 1.21, 0.70, sombre, regard)
        bloc("Œil", 0, -0.07, -0.40, 1.43, 0.45, 0.21, cyan, regard, neon)
        bloc("Reflet de l’œil", -0.28 * cote, 0.03, -0.50, 0.63, 0.31, 0.13, cyan, regard, neon)
        bloc("Arcade", 0.05 * cote, 0.62, -0.13, 2.25, 0.68, 1.02, fauve, regard)
        bloc("Arcade extérieure", 0.83 * cote, 0.93, 0.19, 0.98, 0.62, 1.03, brun, regard)
        bloc("Mèche sous le givre du front", cote * 0.44, 1.69, 0.50, 0.89, 1.66, 0.51, brun, regard)

        local oreille = CFrame.new(cote * 3.96, 11.92, -8.78) * CFrame.Angles(rad(-9), rad(-29 * cote), rad(-10 * cote))
        bloc("Oreille laineuse", 0, 0, 0, 2.23, 3.35, 1.18, brun, oreille)
        bloc("Creux de l’oreille", 0.07 * cote, 0.02, -0.56, 1.42, 1.92, 0.32, sombre, oreille)
        bloc("Repli de l’oreille", 0.52 * cote, 0.33, -0.73, 0.53, 2.29, 0.41, fauve, oreille)
        bloc("Pointe de l’oreille", 0.21 * cote, -1.70, 0.13, 1.38, 0.96, 0.91, brun, oreille)

        bloc("Joue", cote * 3.07, 10.78, -10.59, 1.83, 2.16, 1.76, fauve)
        bloc("Favori", cote * 3.61, 9.64, -9.98, 1.54, 2.73, 1.75, brun)
        bloc("Pointe du favori", cote * 3.45, 8.37, -10.20, 0.94, 1.4, 1.02, sombre)
        bloc("Mèche de la tempe", cote * 3.31, 13.82, -9.76, 1.55, 1.92, 1.61, brun)
        bloc("Bord gelé de la tempe", cote * 3.28, 14.61, -9.83, 1.37, 1.48, 1.46, givre)
    end

    bloc("Coiffe de givre", 0, 15.37, -9.02, 6.17, 0.87, 3.59, givre)
    bloc("Neige du front", -0.20, 15.88, -8.78, 4.87, 0.39, 2.59, ivoire)
    bloc("Frange du front", -0.47, 15.32, -10.73, 3.72, 0.71, 1.07, givre)
    bloc("Coulée du front", -0.43, 14.77, -11.05, 1.03, 1.05, 0.66, givre)
    bloc("Bord clair de la coulée", -0.81, 15.20, -11.26, 0.52, 0.54, 0.31, ivoire)
    bloc("Éclat du front", 1.61, 15.39, -10.83, 0.90, 0.48, 0.81, ivoire)

    -- Trompe basse en S, avec des plis sur la face extérieure de la courbe.
    local trompe = {
        Vector3.new(0, 11.92, -11.25), Vector3.new(0, 10.67, -12.25),
        Vector3.new(-0.10, 9.10, -12.77), Vector3.new(-0.18, 7.50, -12.88),
        Vector3.new(-0.43, 6.00, -13.08), Vector3.new(-0.60, 4.78, -13.65),
        Vector3.new(-0.45, 4.19, -14.60), Vector3.new(-0.12, 4.30, -15.43),
        Vector3.new(0.30, 4.87, -16.06), Vector3.new(0.61, 5.59, -16.28),
    }
    for i = 1, #trompe - 1 do
        local repere, longueur = axe(trompe[i], trompe[i + 1])
        local largeur = 2.62 - (i - 1) * 0.175
        local hauteur = 1.99 - (i - 1) * 0.129
        bloc("Segment de trompe", 0, 0, 0, largeur, hauteur, longueur + 0.42, brun, repere)
        if i < 8 then
            bloc("Pli de trompe", 0, hauteur * 0.45, 0.03,
                largeur * 0.85, 0.36, longueur * 0.69, i % 3 == 0 and brun or fauve, repere)
        end
    end
    local bout = trompe[#trompe]
    local mufle = CFrame.lookAt(bout, bout + (bout - trompe[#trompe - 1]))
    bloc("Bout de la trompe", 0, 0, -0.13, 1.36, 1.07, 0.47, fauve, mufle)
    for _, cote in ipairs(cotes) do
        bloc("Narine", cote * 0.30, 0.025, -0.37, 0.31, 0.38, 0.08, sombre, mufle)
    end

    -- Les défenses plongent, s'écartent, puis reviennent vers l'axe en remontant.
    local courbe = {
        {2.49, 10.81, -10.82}, {3.12, 9.87, -12.07}, {3.78, 8.48, -13.12},
        {4.63, 7.27, -14.17}, {5.66, 6.86, -15.25}, {6.58, 7.22, -16.14},
        {6.98, 8.15, -16.98}, {6.90, 9.25, -17.68}, {6.43, 10.24, -18.02},
        {5.98, 10.85, -18.08},
    }
    local sections = {1.81, 1.67, 1.53, 1.39, 1.23, 1.06, 0.84, 0.59, 0.31}
    for _, cote in ipairs(cotes) do
        local points = {}
        for i, point in ipairs(courbe) do
            local progression = (i - 1) / (#courbe - 1)
            points[i] = Vector3.new(cote * (point[1] + cote * 0.13 * progression),
                point[2] + cote * 0.33 * progression, point[3] - cote * 0.28 * progression)
        end
        for i, section in ipairs(sections) do
            local repere, longueur = axe(points[i], points[i + 1])
            local teinte = i < 6 and os or (i == 6 and ivoire or givre)
            bloc("Segment de défense", 0, 0, 0, section, section * 0.90, longueur + 0.39, teinte, repere)
            if i < 6 then
                bloc("Ivoire de la défense", -cote * section * 0.07, section * 0.27, -0.01,
                    section * 0.90, section * 0.48, longueur + 0.14, ivoire, repere)
            elseif i > 6 and i < 9 then
                bloc("Arête givrée de la défense", -cote * section * 0.07, section * 0.30, -0.05,
                    section * 0.66, section * 0.36, longueur + 0.16, ivoire, repere)
            end
            if i == 6 then
                bloc("Givre en selle", 0.13 * cote, 0.34, 0.08, 1.20, 0.75, longueur * 0.92, givre, repere)
                bloc("Givre pendant", 0.59 * cote, -0.26, 0.12, 0.46, 0.85, 0.70, givre, repere)
            elseif i == 7 then
                local eclat = repere * CFrame.new(cote * 0.29, 0.17, 0.23) * CFrame.Angles(0, rad(20 * cote), 0)
                bloc("Éclat sur la défense", 0, 0, 0, 0.63, 0.71, 1.45, givre, eclat)
            end
        end
    end

    model:SetAttribute("Pieces", n)
    model.Parent = parent
    return model
end

function M.mammouthGivre(): Model
	dossier = dossierModeles()
	local old = dossier:FindFirstChild("Mammouth_Givre")
	if old then
		old:Destroy()
	end
	return mammouthSol(dossier, CFrame.new())
end

-- Coffre-mimique (boss des ruines, 27/11, Claude) : coffre ferré à 3 tons de bois, couvercle entrouvert, deux rangées
-- de dents, langue pendante, yeux luisants dans l'ombre du couvercle, pattes griffues, serrure dorée qui « respire ».
function M.coffreMimique(): Model
	dossier = dossierModeles()
	local old = dossier:FindFirstChild("Coffre_Mimique")
	if old then
		old:Destroy()
	end
	local m = nouveau("Coffre_Mimique")
	local b1, b2, b3 = rgb(120, 74, 42), rgb(92, 56, 32), rgb(156, 104, 62)
	local fer, or1, dent = rgb(70, 72, 80), rgb(226, 178, 64), rgb(240, 232, 210)
	local function Bx(n: string, t: Vector3, pos: Vector3, c: Color3, mat: Enum.Material?, rot: CFrame?)
		return P(m, n, t, pos, c, mat or Mat.Wood, { collide = false, rot = rot })
	end
	-- caisse
	Bx("Caisse", Vector3.new(6, 3.2, 4), Vector3.new(0, 2.6, 0), b1)
	for i, y in { 1.4, 2.6, 3.8 } do
		Bx("Planche", Vector3.new(6.05, 0.12, 4.05), Vector3.new(0, y, 0), i % 2 == 0 and b2 or b3)
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Bx("Coin ferré", Vector3.new(0.5, 3.3, 0.5), Vector3.new(sx * 2.85, 2.6, sz * 1.85), fer, Mat.Metal)
		end
		Bx("Bande de fer", Vector3.new(0.35, 3.3, 4.1), Vector3.new(sx * 1.6, 2.6, 0), fer, Mat.Metal)
	end
	-- couvercle entrouvert (bascule vers l'arrière autour de la charnière)
	local lid = CFrame.new(0, 4.2, 2) * CFrame.Angles(math.rad(34), 0, 0)
	local function L(n: string, t: Vector3, off: Vector3, c: Color3, mat: Enum.Material?)
		return P(m, n, t, Vector3.zero, c, mat or Mat.Wood, { collide = false, cf = lid * CFrame.new(off) })
	end
	L("Couvercle", Vector3.new(6.1, 1.0, 4.1), Vector3.new(0, 0.5, -2.05), b1)
	L("Voûte", Vector3.new(5.6, 0.6, 3.6), Vector3.new(0, 1.2, -2.05), b3)
	for _, sx in { -1, 1 } do
		L("Bande de fer", Vector3.new(0.35, 1.3, 4.2), Vector3.new(sx * 1.6, 0.7, -2.05), fer, Mat.Metal)
	end
	for i = -3, 3 do
		L("Dent", Vector3.new(0.45, 0.7, 0.4), Vector3.new(i * 0.8, -0.3, -3.95), dent, Mat.SmoothPlastic)
	end
	for _, sx in { -1, 1 } do
		L("Oeil", Vector3.new(0.6, 0.45, 0.1), Vector3.new(sx * 1.3, 0.2, -4.13), rgb(255, 210, 60), Mat.Neon)
		L("Pupille", Vector3.new(0.18, 0.4, 0.06), Vector3.new(sx * 1.3, 0.2, -4.19), rgb(30, 10, 10), Mat.SmoothPlastic)
	end
	-- gueule : intérieur sombre, dents du bas, langue qui pend
	Bx("Gueule", Vector3.new(5.4, 0.3, 3.4), Vector3.new(0, 4.1, 0), rgb(60, 14, 20), Mat.SmoothPlastic)
	for i = -3, 3 do
		Bx("Dent", Vector3.new(0.42, 0.65, 0.38), Vector3.new(i * 0.8, 4.5, -1.8), dent, Mat.SmoothPlastic)
	end
	Bx("Langue", Vector3.new(1.4, 0.3, 2.6), Vector3.new(0.3, 4.15, -2.6), rgb(200, 70, 90), Mat.SmoothPlastic, CFrame.Angles(math.rad(-35), 0, 0))
	Bx("Langue", Vector3.new(1.1, 0.25, 1.2), Vector3.new(0.3, 3.2, -3.4), rgb(214, 86, 104), Mat.SmoothPlastic, CFrame.Angles(math.rad(-70), 0, 0))
	-- serrure
	Bx("Serrure", Vector3.new(1.0, 1.1, 0.25), Vector3.new(0, 3.3, -2.1), or1, Mat.Metal)
	Bx("Trou", Vector3.new(0.2, 0.45, 0.06), Vector3.new(0, 3.3, -2.24), rgb(20, 14, 10), Mat.SmoothPlastic)
	-- pattes griffues
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Bx("Patte", Vector3.new(0.7, 1.2, 0.7), Vector3.new(sx * 2.4, 0.6, sz * 1.4), b2)
			for g = -1, 1 do
				Bx("Griffe", Vector3.new(0.15, 0.2, 0.45), Vector3.new(sx * 2.4 + g * 0.22, 0.1, sz * 1.4 - 0.55), dent, Mat.SmoothPlastic)
			end
		end
	end
	-- pièces d'or qui débordent
	for i = 0, 5 do
		Bx("Piece", Vector3.new(0.5, 0.1, 0.5), Vector3.new(-2 + i * 0.8, 4.3 + (i % 2) * 0.1, 0.6 + (i % 3) * 0.3), or1, Mat.Metal)
	end
	fini(m)
	m:ScaleTo(1.6) -- taille de boss (les modèles faits main ne sont pas agrandis par Bestiaire)
	return m
end

-- Crocodile des marais (boss, 27/11, Claude) : long corps bas en écailles à 3 tons, rangées de bosses dorsales,
-- gueule entrouverte à dents irrégulières, yeux jaunes sur le dessus du crâne, queue en segments, ventre clair, mousse.
function M.crocoMarais(): Model
	dossier = dossierModeles()
	local old = dossier:FindFirstChild("Croco_Marais")
	if old then
		old:Destroy()
	end
	local m = nouveau("Croco_Marais")
	local v1, v2, v3, ventre = rgb(66, 92, 52), rgb(48, 70, 40), rgb(96, 124, 70), rgb(196, 190, 140)
	local dent, oeil, mousse = rgb(236, 228, 200), rgb(255, 214, 60), rgb(90, 140, 60)
	local function Bx(n: string, t: Vector3, pos: Vector3, c: Color3, mat: Enum.Material?, rot: CFrame?)
		return P(m, n, t, pos, c, mat or Mat.SmoothPlastic, { collide = false, rot = rot })
	end
	-- corps
	Bx("Corps", Vector3.new(3.2, 1.6, 6), Vector3.new(0, 1.5, 0), v1)
	Bx("Ventre", Vector3.new(2.8, 0.3, 5.6), Vector3.new(0, 0.75, 0), ventre)
	for i = -2, 2 do
		for _, sx in { -0.7, 0.7 } do
			Bx("Bosse", Vector3.new(0.45, 0.4, 0.6), Vector3.new(sx, 2.45, i * 1.1), (i % 2 == 0) and v2 or v3)
		end
	end
	Bx("Mousse", Vector3.new(1.2, 0.15, 1.6), Vector3.new(0.6, 2.35, -0.8), mousse, Mat.Grass)
	-- tête et gueule
	Bx("Crane", Vector3.new(2.4, 1.2, 1.8), Vector3.new(0, 1.6, -3.8), v1)
	Bx("Museau", Vector3.new(1.8, 0.6, 3.0), Vector3.new(0, 1.65, -6.0), v2, nil, CFrame.Angles(math.rad(-8), 0, 0))
	Bx("Machoire", Vector3.new(1.7, 0.45, 3.0), Vector3.new(0, 0.95, -5.9), v3, nil, CFrame.Angles(math.rad(6), 0, 0))
	Bx("Gueule", Vector3.new(1.5, 0.2, 2.6), Vector3.new(0, 1.3, -5.8), rgb(150, 60, 60))
	for i = 0, 4 do
		for _, sx in { -1, 1 } do
			Bx("Dent", Vector3.new(0.14, 0.3 + (i % 2) * 0.1, 0.14), Vector3.new(sx * 0.78, 1.32, -4.8 - i * 0.55), dent)
		end
	end
	for _, sx in { -1, 1 } do
		Bx("Orbite", Vector3.new(0.6, 0.5, 0.6), Vector3.new(sx * 0.75, 2.35, -3.6), v2)
		Bx("Oeil", Vector3.new(0.35, 0.3, 0.08), Vector3.new(sx * 0.75, 2.4, -3.93), oeil, Mat.Neon)
		Bx("Narine", Vector3.new(0.18, 0.12, 0.18), Vector3.new(sx * 0.3, 2.0, -7.35), rgb(30, 40, 26))
		-- pattes écartées, griffues
		for _, z in { -1.8, 1.8 } do
			Bx("Patte", Vector3.new(1.0, 0.9, 0.9), Vector3.new(sx * 1.9, 0.6, z), v2)
			for g = -1, 1 do
				Bx("Griffe", Vector3.new(0.12, 0.15, 0.35), Vector3.new(sx * 2.15 + g * 0.22, 0.08, z - 0.55), dent)
			end
		end
	end
	-- queue en segments qui s'amincissent
	for i = 0, 5 do
		local w = 2.6 - i * 0.38
		Bx("Queue", Vector3.new(w, 1.2 - i * 0.14, 1.3), Vector3.new(math.sin(i * 0.5) * 0.4, 1.4 - i * 0.12, 3.6 + i * 1.15), (i % 2 == 0) and v1 or v2)
		Bx("Bosse", Vector3.new(0.3, 0.35, 0.5), Vector3.new(math.sin(i * 0.5) * 0.4, 2.0 - i * 0.18, 3.6 + i * 1.15), v3)
	end
	fini(m)
	m:ScaleTo(1.7) -- taille de boss (les modèles faits main ne sont pas agrandis par Bestiaire)
	return m
end

-- Veuve des cavernes (boss, 27/11, Claude) : abdomen noir à sablier rouge, céphalothorax, 8 pattes à deux segments
-- (cuisse qui monte, tibia qui redescend au sol), crochets, grappe d'yeux rouges luisants, poils et fils de soie.
function M.veuveCavernes(): Model
	dossier = dossierModeles()
	local old = dossier:FindFirstChild("Veuve_Cavernes")
	if old then
		old:Destroy()
	end
	local m = nouveau("Veuve_Cavernes")
	local n1, n2, n3, rouge, soie = rgb(28, 24, 30), rgb(46, 40, 50), rgb(70, 62, 76), rgb(200, 30, 40), rgb(226, 226, 236)
	local function Bx(n: string, t: Vector3, pos: Vector3, c: Color3, mat: Enum.Material?, cf: CFrame?)
		if cf then
			return P(m, n, t, Vector3.zero, c, mat or Mat.SmoothPlastic, { collide = false, cf = cf })
		end
		return P(m, n, t, pos, c, mat or Mat.SmoothPlastic, { collide = false })
	end
	local function barre(n: string, a: Vector3, b: Vector3, e: number, c: Color3)
		return Bx(n, Vector3.new(e, e, (b - a).Magnitude + e * 0.6), Vector3.zero, c, nil, CFrame.lookAt((a + b) / 2, b))
	end
	-- abdomen et sablier
	Bx("Abdomen", Vector3.new(3.4, 2.8, 3.8), Vector3.new(0, 2.6, 2.4), n1)
	Bx("Abdomen", Vector3.new(2.8, 0.6, 3.2), Vector3.new(0, 4.2, 2.4), n2)
	Bx("Sablier", Vector3.new(0.9, 0.06, 0.6), Vector3.new(0, 4.52, 2.0), rouge, Mat.Neon)
	Bx("Sablier", Vector3.new(0.9, 0.06, 0.6), Vector3.new(0, 4.52, 2.9), rouge, Mat.Neon)
	Bx("Sablier", Vector3.new(0.35, 0.06, 0.4), Vector3.new(0, 4.52, 2.45), rouge, Mat.Neon)
	for i = -1, 1 do
		Bx("Poil", Vector3.new(0.1, 0.5, 0.1), Vector3.new(i * 1.0, 4.7, 3.6), n3)
	end
	-- céphalothorax, tête, crochets, yeux
	Bx("Thorax", Vector3.new(2.4, 1.6, 2.2), Vector3.new(0, 2.2, -0.4), n2)
	Bx("Tete", Vector3.new(1.6, 1.1, 1.0), Vector3.new(0, 2.3, -1.9), n1)
	for _, sx in { -1, 1 } do
		barre("Crochet", Vector3.new(sx * 0.35, 1.9, -2.3), Vector3.new(sx * 0.25, 1.1, -2.6), 0.22, rouge)
	end
	for k, e in { { -0.45, 2.6 }, { 0.45, 2.6 }, { -0.2, 2.85 }, { 0.2, 2.85 }, { -0.62, 2.35 }, { 0.62, 2.35 } } do
		Bx("Oeil", Vector3.new(k <= 2 and 0.28 or 0.18, k <= 2 and 0.28 or 0.18, 0.08), Vector3.new(e[1], e[2], -2.42), rgb(255, 50, 50), Mat.Neon)
	end
	-- pattes : hanche sur le thorax, genou haut, pied au sol
	for _, sx in { -1, 1 } do
		for j, z in { -1.3, -0.6, 0.1, 0.8 } do
			local hanche = Vector3.new(sx * 1.1, 2.3, z - 0.4)
			local genou = Vector3.new(sx * (2.6 + j * 0.15), 3.8 - math.abs(j - 2.5) * 0.15, z + (j - 2.5) * 0.7)
			local pied = Vector3.new(sx * (4.0 + j * 0.2), 0.15, z + (j - 2.5) * 1.3)
			barre("Cuisse", hanche, genou, 0.32, n2)
			barre("Tibia", genou, pied, 0.24, n1)
			Bx("Genou", Vector3.new(0.4, 0.4, 0.4), genou, n3)
		end
	end
	-- fils de soie qui pendent de l'abdomen
	barre("Soie", Vector3.new(0, 1.3, 4.1), Vector3.new(0.3, 0.05, 4.9), 0.06, soie)
	barre("Soie", Vector3.new(0.4, 1.4, 4.2), Vector3.new(1.2, 0.05, 4.6), 0.05, soie)
	fini(m)
	m:ScaleTo(2.0) -- taille de boss
	return m
end

-- Baudroie des abysses (boss maritime, 27/11, Claude) : grosse tête-gueule, rangées de longues dents, leurre lumineux
-- au bout d'une tige, petits yeux pâles, nageoires et queue, peau sombre en 3 tons avec points luminescents.
function M.baudroie(): Model
	dossier = dossierModeles()
	local old = dossier:FindFirstChild("Baudroie")
	if old then
		old:Destroy()
	end
	local m = nouveau("Baudroie")
	local p1, p2, p3, dent = rgb(34, 38, 52), rgb(52, 58, 76), rgb(74, 84, 104), rgb(232, 236, 230)
	local lueur = rgb(120, 255, 220)
	local function Bx(n: string, t: Vector3, pos: Vector3, c: Color3, mat: Enum.Material?, cf: CFrame?)
		if cf then
			return P(m, n, t, Vector3.zero, c, mat or Mat.SmoothPlastic, { collide = false, cf = cf })
		end
		return P(m, n, t, pos, c, mat or Mat.SmoothPlastic, { collide = false })
	end
	local function barre(n: string, a: Vector3, b: Vector3, e: number, c: Color3, mat: Enum.Material?)
		return Bx(n, Vector3.new(e, e, (b - a).Magnitude + e * 0.5), Vector3.zero, c, mat, CFrame.lookAt((a + b) / 2, b))
	end
	-- corps-tête massif
	Bx("Corps", Vector3.new(4.4, 3.6, 4.2), Vector3.new(0, 2.6, 0.4), p1)
	Bx("Dos", Vector3.new(3.8, 0.6, 3.6), Vector3.new(0, 4.6, 0.6), p2)
	Bx("Ventre", Vector3.new(3.8, 0.4, 3.8), Vector3.new(0, 0.7, 0.4), p3)
	-- gueule : mâchoire inférieure en avant, gosier rouge sombre, dents longues
	Bx("Machoire", Vector3.new(4.6, 1.0, 1.6), Vector3.new(0, 1.2, -2.2), p2)
	Bx("Gosier", Vector3.new(3.6, 1.4, 0.3), Vector3.new(0, 2.4, -1.7), rgb(80, 20, 30))
	for k = -4, 4 do
		local h = 0.7 + (k % 2) * 0.35
		Bx("Dent", Vector3.new(0.2, h, 0.2), Vector3.new(k * 0.48, 1.7 + h / 2, -2.85), dent)
		if k < 4 then
			Bx("Dent", Vector3.new(0.18, h * 0.8, 0.18), Vector3.new(k * 0.48 + 0.24, 3.6 - h * 0.4, -1.88), dent)
		end
	end
	-- leurre
	local base, coude, bout = Vector3.new(0, 4.9, -0.6), Vector3.new(0, 7.0, -1.6), Vector3.new(0, 6.6, -3.4)
	barre("Tige", base, coude, 0.2, p3)
	barre("Tige", coude, bout, 0.16, p3)
	local leurre = Bx("Leurre", Vector3.new(0.8, 0.8, 0.8), bout, lueur, Mat.Neon)
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color = 16, 2.5, lueur
	l.Parent = leurre
	-- yeux, points luminescents
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.4, 0.4, 0.1), Vector3.new(sx * 1.3, 4.0, -1.7), rgb(220, 240, 230), Mat.Neon)
		Bx("Nageoire", Vector3.new(0.2, 1.6, 2.0), Vector3.new(sx * 2.4, 2.0, 0.8), p3, nil, CFrame.new(sx * 2.4, 2.0, 0.8) * CFrame.Angles(0, 0, sx * -0.6))
		for k = 0, 2 do
			Bx("Point", Vector3.new(0.06, 0.2, 0.2), Vector3.new(sx * 2.21, 2.2 + k * 0.6, 1.4 - k * 0.6), lueur, Mat.Neon)
		end
	end
	-- queue et nageoire caudale
	Bx("Queue", Vector3.new(2.4, 2.2, 1.6), Vector3.new(0, 2.6, 3.2), p1)
	Bx("Queue", Vector3.new(1.4, 1.4, 1.2), Vector3.new(0, 2.7, 4.5), p2)
	Bx("Caudale", Vector3.new(0.2, 3.0, 1.6), Vector3.new(0, 2.8, 5.6), p3)
	Bx("Dorsale", Vector3.new(0.2, 1.2, 2.0), Vector3.new(0, 5.4, 1.6), p3)
	fini(m)
	m:ScaleTo(1.8) -- taille de boss
	return m
end

-- Griffon d'orage (boss volant, 27/11, Claude) : avant d'aigle (tête, bec crochu, collerette de plumes, serres),
-- arrière de lion fauve, grandes ailes déployées en 3 rangs de plumes, liserés d'éclairs bleus, queue à touffe.
function M.griffonOrage(): Model
	dossier = dossierModeles()
	local old = dossier:FindFirstChild("Griffon_Orage")
	if old then
		old:Destroy()
	end
	local m = nouveau("Griffon_Orage")
	local plume1, plume2, plume3 = rgb(70, 86, 120), rgb(98, 116, 156), rgb(196, 206, 226)
	local fauve, fauve2, bec, eclair = rgb(186, 146, 92), rgb(150, 112, 70), rgb(236, 196, 70), rgb(120, 200, 255)
	local function Bx(n: string, t: Vector3, pos: Vector3, c: Color3, mat: Enum.Material?, rot: CFrame?)
		return P(m, n, t, pos, c, mat or Mat.SmoothPlastic, { collide = false, rot = rot })
	end
	-- corps : poitrail d'aigle, arrière de lion
	Bx("Poitrail", Vector3.new(2.4, 2.4, 2.2), Vector3.new(0, 3.2, -1.0), plume2)
	Bx("Collerette", Vector3.new(2.8, 0.8, 1.2), Vector3.new(0, 4.2, -1.5), plume3)
	Bx("Corps", Vector3.new(2.2, 2.0, 3.2), Vector3.new(0, 3.0, 1.4), fauve)
	Bx("Ventre", Vector3.new(1.9, 0.3, 4.6), Vector3.new(0, 1.9, 0.4), fauve2)
	-- tête
	Bx("Tete", Vector3.new(1.6, 1.5, 1.6), Vector3.new(0, 5.0, -2.2), plume3)
	Bx("Crete", Vector3.new(0.4, 0.7, 1.2), Vector3.new(0, 6.0, -2.0), plume1)
	Bx("Bec", Vector3.new(0.7, 0.6, 1.1), Vector3.new(0, 4.8, -3.4), bec)
	Bx("Bec", Vector3.new(0.5, 0.45, 0.4), Vector3.new(0, 4.45, -3.85), rgb(200, 160, 50))
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.08, 0.3, 0.35), Vector3.new(sx * 0.81, 5.15, -2.6), eclair, Mat.Neon)
		-- serres à l'avant, pattes de lion à l'arrière
		Bx("Patte", Vector3.new(0.5, 2.1, 0.5), Vector3.new(sx * 0.7, 1.25, -1.2), bec)
		for g = -1, 1 do
			Bx("Serre", Vector3.new(0.12, 0.15, 0.45), Vector3.new(sx * 0.7 + g * 0.18, 0.27, -1.55), rgb(40, 40, 46))
		end
		Bx("Patte", Vector3.new(0.7, 1.8, 0.8), Vector3.new(sx * 0.7, 1.4, 2.2), fauve2)
		Bx("Pied", Vector3.new(0.8, 0.4, 1.0), Vector3.new(sx * 0.7, 0.4, 2.1), fauve)
		-- aile : bras de l'aile puis 3 rangs de rémiges qui s'allongent vers la pointe
		Bx("Aile", Vector3.new(4.0, 0.4, 1.6), Vector3.new(sx * 3.1, 4.6, 0.2), plume1, nil, CFrame.Angles(0, 0, sx * 0.25))
		for k = 0, 4 do
			local x = sx * (1.8 + k * 1.05)
			local y = 4.4 + k * 0.28
			Bx("Remige", Vector3.new(0.9, 0.25, 2.4 + k * 0.35), Vector3.new(x, y - 0.25, 1.4 + k * 0.15), k % 2 == 0 and plume2 or plume1)
			Bx("Remige", Vector3.new(0.85, 0.2, 1.2), Vector3.new(x, y - 0.05, 0.4), plume3)
		end
		Bx("Eclair", Vector3.new(4.6, 0.1, 0.16), Vector3.new(sx * 3.9, 5.2, 2.9), eclair, Mat.Neon, CFrame.Angles(0, 0, sx * 0.22))
	end
	-- queue de lion à touffe chargée d'orage
	Bx("Queue", Vector3.new(0.3, 0.3, 2.6), Vector3.new(0, 3.4, 4.1), fauve2, nil, CFrame.Angles(math.rad(-20), 0, 0))
	Bx("Touffe", Vector3.new(0.7, 0.7, 0.9), Vector3.new(0, 3.9, 5.4), plume1)
	Bx("Etincelle", Vector3.new(0.25, 0.25, 0.25), Vector3.new(0, 4.4, 5.6), eclair, Mat.Neon)
	fini(m)
	m:ScaleTo(1.8) -- taille de boss
	return m
end

-- Vargor, le Roi des loups (boss, 27/11, Claude) : loup noir massif, crinière blanche en mèches sur 3 rangs,
-- couronne d'os, yeux de braise, cicatrice, crocs, échine hérissée, queue en panache.
function M.vargor(): Model
	dossier = dossierModeles()
	local old = dossier:FindFirstChild("Vargor")
	if old then
		old:Destroy()
	end
	local m = nouveau("Vargor")
	local n1, n2, n3 = rgb(30, 28, 34), rgb(48, 46, 54), rgb(72, 70, 80)
	local b1, b2, os, braise = rgb(236, 234, 228), rgb(196, 192, 186), rgb(226, 214, 184), rgb(255, 120, 40)
	local function Bx(n: string, t: Vector3, pos: Vector3, c: Color3, mat: Enum.Material?, rot: CFrame?)
		return P(m, n, t, pos, c, mat or Mat.SmoothPlastic, { collide = false, rot = rot })
	end
	Bx("Corps", Vector3.new(2.6, 2.4, 5.0), Vector3.new(0, 3.2, 0.6), n1)
	Bx("Echine", Vector3.new(2.0, 0.4, 4.4), Vector3.new(0, 4.55, 0.8), n2)
	for k = 0, 5 do
		Bx("Pique", Vector3.new(0.3, 0.6 - k * 0.05, 0.4), Vector3.new(0, 4.85, -0.8 + k * 0.7), n3)
	end
	Bx("Ventre", Vector3.new(2.2, 0.3, 4.2), Vector3.new(0, 1.95, 0.6), n3)
	-- crinière en 3 rangs autour du cou
	for r = 0, 2 do
		Bx("Criniere", Vector3.new(3.4 - r * 0.4, 1.0, 1.0), Vector3.new(0, 3.2 + r * 0.8, -1.6 + r * 0.3), r % 2 == 0 and b1 or b2)
	end
	-- tête
	Bx("Tete", Vector3.new(1.8, 1.6, 1.8), Vector3.new(0, 4.4, -2.7), n1)
	Bx("Museau", Vector3.new(1.0, 0.8, 1.4), Vector3.new(0, 4.0, -4.0), n2)
	Bx("Truffe", Vector3.new(0.4, 0.3, 0.12), Vector3.new(0, 4.3, -4.76), rgb(12, 10, 12))
	Bx("Machoire", Vector3.new(0.9, 0.3, 1.2), Vector3.new(0, 3.45, -3.9), n3)
	Bx("Cicatrice", Vector3.new(0.08, 0.9, 0.12), Vector3.new(0.5, 4.6, -3.62), rgb(150, 60, 60), nil, CFrame.Angles(0, 0, 0.4))
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.3, 0.18, 0.08), Vector3.new(sx * 0.48, 4.75, -3.62), braise, Mat.Neon)
		Bx("Oreille", Vector3.new(0.4, 0.8, 0.3), Vector3.new(sx * 0.6, 5.5, -2.6), n2)
		Bx("Croc", Vector3.new(0.14, 0.4, 0.14), Vector3.new(sx * 0.35, 3.55, -4.55), os)
		-- couronne d'os : pointes autour du front
		Bx("Couronne", Vector3.new(0.25, 0.9, 0.25), Vector3.new(sx * 0.62, 5.45, -2.3), os, nil, CFrame.Angles(0, 0, -sx * 0.3))
		Bx("Couronne", Vector3.new(0.22, 0.7, 0.22), Vector3.new(sx * 0.35, 5.45, -3.0), os)
		for _, z in { -1.2, 2.4 } do
			Bx("Patte", Vector3.new(0.75, 2.4, 0.8), Vector3.new(sx * 0.85, 1.25, z), n2)
			Bx("Pied", Vector3.new(0.9, 0.35, 1.1), Vector3.new(sx * 0.85, 0.18, z - 0.15), n1)
			for g = -1, 1 do
				Bx("Griffe", Vector3.new(0.12, 0.12, 0.3), Vector3.new(sx * 0.85 + g * 0.26, 0.08, z - 0.8), os)
			end
		end
	end
	Bx("Couronne", Vector3.new(0.26, 1.0, 0.26), Vector3.new(0, 5.55, -2.6), os)
	-- queue en panache
	Bx("Queue", Vector3.new(0.7, 0.7, 2.2), Vector3.new(0, 3.9, 4.0), n2, nil, CFrame.Angles(math.rad(25), 0, 0))
	Bx("Queue", Vector3.new(0.9, 0.9, 1.0), Vector3.new(0, 3.3, 5.1), b2)
	fini(m)
	m:ScaleTo(1.8) -- taille de boss
	return m
end

-- Quatre boss de plus (27/11, Claude) : outils communs
local function bossBuilder(nom: string)
	dossier = dossierModeles()
	local old = dossier:FindFirstChild(nom)
	if old then
		old:Destroy()
	end
	local m = nouveau(nom)
	local function Bx(n: string, t: Vector3, pos: Vector3, c: Color3, mat: Enum.Material?, rot: CFrame?)
		return P(m, n, t, pos, c, mat or Mat.SmoothPlastic, { collide = false, rot = rot })
	end
	local function barre(n: string, a: Vector3, b: Vector3, e: number, c: Color3, mat: Enum.Material?)
		return P(m, n, Vector3.new(e, e, (b - a).Magnitude + e * 0.5), Vector3.zero, c, mat or Mat.SmoothPlastic,
			{ collide = false, cf = CFrame.lookAt((a + b) / 2, b) })
	end
	return m, Bx, barre
end

-- Hydre des tourbières : corps trapu couvert de mousse, trois cous qui se dressent, trois têtes à crocs et yeux jaunes
function M.hydre(): Model
	local m, Bx, barre = bossBuilder("Hydre_Tourbieres")
	local v1, v2, v3, ventre, mousse = rgb(58, 90, 60), rgb(42, 66, 46), rgb(86, 122, 78), rgb(176, 180, 120), rgb(96, 140, 60)
	Bx("Corps", Vector3.new(4, 2.6, 5), Vector3.new(0, 2.0, 0.6), v1)
	Bx("Dos", Vector3.new(3.4, 0.5, 4.4), Vector3.new(0, 3.5, 0.6), v2)
	Bx("Ventre", Vector3.new(3.4, 0.3, 4.4), Vector3.new(0, 0.75, 0.6), ventre)
	for k = 0, 3 do
		Bx("Mousse", Vector3.new(1.2, 0.2, 0.9), Vector3.new(-1.2 + k * 0.8, 3.8, -0.6 + (k % 2) * 1.6), mousse, Mat.Grass)
	end
	for _, sx in { -1, 1 } do
		for _, z in { -0.9, 2.2 } do
			Bx("Patte", Vector3.new(1.0, 1.4, 1.0), Vector3.new(sx * 1.9, 0.7, z), v2)
		end
	end
	Bx("Queue", Vector3.new(1.6, 1.2, 2.4), Vector3.new(0, 1.6, 4.1), v1)
	Bx("Queue", Vector3.new(0.9, 0.8, 1.8), Vector3.new(0, 1.3, 6.0), v2)
	for k, d in { { -1.4, -0.3 }, { 0, 0 }, { 1.4, 0.3 } } do
		local base = Vector3.new(d[1] * 0.8, 3.0, -1.4)
		local mid = Vector3.new(d[1] * 1.3, 5.0 + (k == 2 and 0.8 or 0), -2.4)
		local tete = Vector3.new(d[1] * 1.5, 6.4 + (k == 2 and 1.0 or 0), -3.4)
		barre("Cou", base, mid, 0.9, v1)
		barre("Cou", mid, tete, 0.8, v3)
		Bx("Tete", Vector3.new(1.3, 1.0, 1.6), tete, v1, nil, CFrame.Angles(0, d[2], 0))
		local avant = tete + Vector3.new(math.sin(d[2]) * -1.1, -0.15, -1.0)
		Bx("Museau", Vector3.new(1.0, 0.6, 1.0), avant, v2, nil, CFrame.Angles(0, d[2], 0))
		for _, sx in { -1, 1 } do
			Bx("Oeil", Vector3.new(0.22, 0.18, 0.1), tete + Vector3.new(sx * 0.45, 0.3, -0.8), rgb(255, 214, 60), Mat.Neon)
			Bx("Croc", Vector3.new(0.12, 0.35, 0.12), avant + Vector3.new(sx * 0.3, -0.4, -0.35), rgb(236, 230, 210))
		end
		Bx("Crete", Vector3.new(0.2, 0.6, 1.0), tete + Vector3.new(0, 0.75, 0.2), v3)
	end
	fini(m)
	m:ScaleTo(1.7)
	return m
end

-- Taureau d'airain : taureau de bronze massif, plaques rivetées, cornes dorées, anneau au mufle, yeux de forge
function M.taureauAirain(): Model
	local m, Bx = bossBuilder("Taureau_Airain")
	local b1, b2, b3, or1, braise = rgb(176, 112, 56), rgb(138, 84, 40), rgb(206, 146, 80), rgb(236, 190, 70), rgb(255, 130, 40)
	Bx("Corps", Vector3.new(3.4, 3.0, 5.4), Vector3.new(0, 3.4, 0.6), b1, Mat.Metal)
	Bx("Bosse", Vector3.new(3.0, 1.0, 2.0), Vector3.new(0, 5.3, -0.8), b2, Mat.Metal)
	for k = 0, 3 do
		Bx("Plaque", Vector3.new(3.5, 0.15, 0.8), Vector3.new(0, 4.9, -0.2 + k * 1.2), b3, Mat.Metal)
		for _, sx in { -1, 1 } do
			Bx("Rivet", Vector3.new(0.15, 0.15, 0.15), Vector3.new(sx * 1.75, 4.2, -0.2 + k * 1.2), or1, Mat.Metal)
		end
	end
	Bx("Tete", Vector3.new(2.0, 1.9, 1.8), Vector3.new(0, 3.9, -2.9), b1, Mat.Metal)
	Bx("Mufle", Vector3.new(1.6, 1.0, 0.8), Vector3.new(0, 3.3, -4.0), b2, Mat.Metal)
	Bx("Anneau", Vector3.new(0.7, 0.7, 0.12), Vector3.new(0, 2.8, -4.45), or1, Mat.Metal)
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.3, 0.22, 0.08), Vector3.new(sx * 0.6, 4.3, -3.82), braise, Mat.Neon)
		Bx("Naseau", Vector3.new(0.25, 0.25, 0.08), Vector3.new(sx * 0.4, 3.4, -4.42), rgb(40, 20, 10))
		Bx("Corne", Vector3.new(1.4, 0.35, 0.35), Vector3.new(sx * 1.55, 4.7, -2.8), or1, Mat.Metal, CFrame.Angles(0, 0, sx * 0.3))
		Bx("Corne", Vector3.new(0.3, 0.8, 0.3), Vector3.new(sx * 2.2, 5.2, -2.8), or1, Mat.Metal)
		for _, z in { -1.4, 2.6 } do
			Bx("Patte", Vector3.new(0.9, 2.2, 1.0), Vector3.new(sx * 1.05, 1.1, z), b2, Mat.Metal)
			Bx("Sabot", Vector3.new(1.0, 0.4, 1.1), Vector3.new(sx * 1.05, 0.2, z), rgb(60, 50, 44), Mat.Metal)
		end
	end
	Bx("Queue", Vector3.new(0.3, 2.0, 0.3), Vector3.new(0, 3.6, 3.4), b2, Mat.Metal, CFrame.Angles(math.rad(20), 0, 0))
	Bx("Queue", Vector3.new(0.5, 0.6, 0.5), Vector3.new(0, 2.6, 3.7), or1, Mat.Metal)
	fini(m)
	m:ScaleTo(1.7)
	return m
end

-- Salamandre de braise : lézard trapu noir de suie, fissures de lave Neon, crête de flammes, queue incandescente
function M.salamandre(): Model
	local m, Bx = bossBuilder("Salamandre_Braise")
	local s1, s2, lave, lave2 = rgb(40, 32, 30), rgb(66, 50, 44), rgb(255, 120, 30), rgb(255, 200, 70)
	Bx("Corps", Vector3.new(2.6, 1.6, 5.0), Vector3.new(0, 1.6, 0.4), s1)
	Bx("Ventre", Vector3.new(2.2, 0.25, 4.4), Vector3.new(0, 0.85, 0.4), s2)
	for k = 0, 4 do
		Bx("Fissure", Vector3.new(2.62, 0.12, 0.18), Vector3.new(0, 1.8 + (k % 2) * 0.2, -1.4 + k * 0.9), lave, Mat.Neon)
		Bx("Flamme", Vector3.new(0.35, 0.8 - (k % 2) * 0.2, 0.5), Vector3.new(0, 2.6, -1.6 + k * 0.9), k % 2 == 0 and lave or lave2, Mat.Neon)
	end
	Bx("Tete", Vector3.new(1.8, 1.0, 1.8), Vector3.new(0, 1.8, -2.8), s1)
	Bx("Museau", Vector3.new(1.4, 0.6, 1.0), Vector3.new(0, 1.6, -4.0), s2)
	local gueule = Bx("Gueule", Vector3.new(1.2, 0.12, 0.9), Vector3.new(0, 1.25, -3.9), lave, Mat.Neon)
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.3, 0.25, 0.08), Vector3.new(sx * 0.6, 2.1, -3.72), lave2, Mat.Neon)
		for _, z in { -1.3, 1.9 } do
			Bx("Patte", Vector3.new(1.4, 0.7, 0.8), Vector3.new(sx * 1.5, 1.0, z), s2)
			Bx("Pied", Vector3.new(0.8, 0.75, 1.0), Vector3.new(sx * 2.1, 0.375, z - 0.1), s1)
			Bx("Fissure", Vector3.new(0.12, 0.3, 0.6), Vector3.new(sx * 2.2, 1.0, z), lave, Mat.Neon)
		end
	end
	for k = 0, 4 do
		local w = 1.6 - k * 0.28
		Bx("Queue", Vector3.new(w, w * 0.7, 1.2), Vector3.new(math.sin(k * 0.6) * 0.5, 1.3 - k * 0.12, 3.5 + k * 1.05), k >= 3 and lave or s1, k >= 3 and Mat.Neon or nil)
	end
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color = 14, 1.6, lave
	l.Parent = gueule
	fini(m)
	m:ScaleTo(1.8)
	return m
end

-- Cerf-Roi des brumes : grand cerf blanc spectral, ramure immense à pointes lumineuses, collier de brume, sabots d'argent
function M.cerfRoi(): Model
	local m, Bx, barre = bossBuilder("Cerf_Roi")
	local w1, w2, w3, lueur, argent = rgb(232, 236, 244), rgb(198, 206, 222), rgb(160, 174, 200), rgb(140, 210, 255), rgb(210, 214, 224)
	Bx("Corps", Vector3.new(2.2, 2.2, 4.4), Vector3.new(0, 4.2, 0.6), w1)
	Bx("Dos", Vector3.new(1.8, 0.3, 4.0), Vector3.new(0, 5.4, 0.6), w2)
	Bx("Collier", Vector3.new(2.6, 1.4, 1.2), Vector3.new(0, 4.6, -1.5), w3)
	local brume = Bx("Brume", Vector3.new(3.0, 0.6, 1.6), Vector3.new(0, 3.8, -1.4), lueur, Mat.Neon)
	brume.Transparency = 0.5
	Bx("Cou", Vector3.new(1.1, 2.0, 1.1), Vector3.new(0, 5.6, -2.2), w1, nil, CFrame.Angles(math.rad(-20), 0, 0))
	Bx("Tete", Vector3.new(1.2, 1.1, 1.8), Vector3.new(0, 6.8, -2.9), w1)
	Bx("Museau", Vector3.new(0.8, 0.6, 0.8), Vector3.new(0, 6.5, -4.0), w2)
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.08, 0.22, 0.3), Vector3.new(sx * 0.61, 7.0, -3.4), lueur, Mat.Neon)
		Bx("Oreille", Vector3.new(0.6, 0.25, 0.3), Vector3.new(sx * 0.8, 7.3, -2.5), w2)
		local a = Vector3.new(sx * 0.4, 7.4, -2.7)
		local b = Vector3.new(sx * 1.4, 9.0, -2.4)
		local c = Vector3.new(sx * 2.2, 10.4, -2.0)
		barre("Bois", a, b, 0.28, argent)
		barre("Bois", b, c, 0.24, argent)
		for _, t in { { b, Vector3.new(sx * 1.6, 9.9, -3.2) }, { c, Vector3.new(sx * 2.0, 11.4, -2.8) }, { c, Vector3.new(sx * 3.0, 11.0, -1.6) } } do
			barre("Andouiller", t[1], t[2], 0.18, argent)
			Bx("Pointe", Vector3.new(0.3, 0.3, 0.3), t[2], lueur, Mat.Neon)
		end
		for _, z in { -1.0, 2.2 } do
			Bx("Patte", Vector3.new(0.5, 3.2, 0.5), Vector3.new(sx * 0.7, 1.7, z), w2)
			Bx("Sabot", Vector3.new(0.6, 0.3, 0.7), Vector3.new(sx * 0.7, 0.15, z), argent, Mat.Metal)
		end
	end
	Bx("Queue", Vector3.new(0.5, 0.7, 0.4), Vector3.new(0, 5.0, 2.95), w3)
	fini(m)
	m:ScaleTo(1.6)
	return m
end

-- Kraken des fjords (boss maritime) : tête-manteau violacée, gros yeux, bec, 8 tentacules qui ondulent en segments
function M.kraken(): Model
	local m, Bx, barre = bossBuilder("Kraken_Fjords")
	local k1, k2, k3, ventouse = rgb(110, 60, 120), rgb(80, 40, 92), rgb(150, 96, 160), rgb(230, 190, 210)
	Bx("Manteau", Vector3.new(4, 4.6, 4), Vector3.new(0, 4.6, 0.6), k1)
	Bx("Sommet", Vector3.new(3.2, 1.4, 3.2), Vector3.new(0, 7.5, 0.8), k2)
	Bx("Taches", Vector3.new(4.05, 0.4, 1.2), Vector3.new(0, 5.6, 0.2), k3)
	Bx("Corps", Vector3.new(3.4, 1.6, 3.4), Vector3.new(0, 2.1, 0.2), k1)
	Bx("Bec", Vector3.new(0.8, 0.6, 0.6), Vector3.new(0, 1.8, -1.8), rgb(40, 30, 30))
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(1.0, 1.0, 0.2), Vector3.new(sx * 1.0, 3.6, -1.42), rgb(250, 220, 90), Mat.Neon)
		Bx("Pupille", Vector3.new(0.3, 0.7, 0.1), Vector3.new(sx * 1.0, 3.6, -1.55), rgb(20, 14, 20))
	end
	for t = 0, 7 do
		local a = t * math.pi / 4 + 0.2
		local prev = Vector3.new(math.cos(a) * 1.4, 1.6, math.sin(a) * 1.4 + 0.2)
		for k = 1, 4 do
			local r = 1.4 + k * 1.3
			local nxt = Vector3.new(math.cos(a + k * 0.25) * r, 0.5 + math.max(0, k - 2) * 0.6 * (t % 2), math.sin(a + k * 0.25) * r + 0.2)
			barre("Tentacule", prev, nxt, 0.75 - k * 0.12, (k % 2 == 0) and k2 or k1)
			if k <= 2 then
				Bx("Ventouse", Vector3.new(0.25, 0.1, 0.25), (prev + nxt) / 2 - Vector3.new(0, 0.32 - k * 0.05, 0), ventouse)
			end
			prev = nxt
		end
	end
	fini(m)
	m:ScaleTo(1.6)
	return m
end

-- Reine des lucioles (boss volant, forêt, nuit) : grand insecte doré, abdomen lumineux, quatre ailes translucides,
-- antennes plumeuses, couronne de lumière
function M.reineLucioles(): Model
	local m, Bx, barre = bossBuilder("Reine_Lucioles")
	local c1, c2, lueur, aile = rgb(70, 54, 30), rgb(110, 86, 44), rgb(255, 236, 120), rgb(220, 240, 255)
	Bx("Thorax", Vector3.new(1.6, 1.4, 1.8), Vector3.new(0, 3.4, -0.4), c2)
	Bx("Abdomen", Vector3.new(1.8, 1.6, 2.6), Vector3.new(0, 3.1, 1.6), c1)
	local ventre = Bx("Lanterne", Vector3.new(1.6, 1.3, 1.4), Vector3.new(0, 2.9, 2.6), lueur, Mat.Neon)
	Bx("Tete", Vector3.new(1.2, 1.0, 1.0), Vector3.new(0, 3.7, -1.7), c2)
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.4, 0.5, 0.4), Vector3.new(sx * 0.55, 3.8, -2.0), rgb(60, 200, 160), Mat.Neon)
		barre("Antenne", Vector3.new(sx * 0.3, 4.1, -2.0), Vector3.new(sx * 1.0, 5.6, -3.0), 0.12, c1)
		Bx("Plume", Vector3.new(0.5, 0.2, 0.7), Vector3.new(sx * 1.0, 5.6, -3.0), lueur, Mat.Neon)
		for k = 0, 1 do
			local w = Bx("Aile", Vector3.new(3.6 - k * 0.8, 0.1, 1.6 - k * 0.3), Vector3.new(sx * (2.4 - k * 0.3), 4.4 - k * 0.5, -0.6 + k * 1.2), aile, Mat.Glass,
				CFrame.Angles(0, 0, sx * (0.35 - k * 0.2)))
			w.Transparency = 0.45
		end
		for j, z in { -0.8, -0.3, 0.2 } do
			barre("Patte", Vector3.new(sx * 0.7, 2.9, z), Vector3.new(sx * 1.4, 1.4, z - 0.2 + j * 0.1), 0.14, c1)
			barre("Patte", Vector3.new(sx * 1.4, 1.4, z - 0.2 + j * 0.1), Vector3.new(sx * 1.6, 0.1, z), 0.12, c1)
		end
	end
	for k = 0, 4 do
		local a = k * math.pi * 2 / 5
		Bx("Couronne", Vector3.new(0.18, 0.5, 0.18), Vector3.new(math.cos(a) * 0.45, 4.45, -1.7 + math.sin(a) * 0.4), lueur, Mat.Neon)
	end
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color = 18, 2, lueur
	l.Parent = ventre
	fini(m)
	m:ScaleTo(1.9)
	return m
end

-- Golem de rouille (boss des ruines de prairie) : vieille machine de garde en fer rouillé, plaques boulonnées, cœur
-- de vapeur lumineux, poings-masses, mousse et lierre qui ont poussé dessus
function M.golemRouille(): Model
	local m, Bx = bossBuilder("Golem_Rouille")
	local r1, r2, r3, fer, coeur, lierre = rgb(150, 80, 50), rgb(116, 60, 40), rgb(176, 110, 70), rgb(90, 92, 100), rgb(120, 230, 255), rgb(80, 130, 60)
	Bx("Torse", Vector3.new(4.4, 3.6, 2.8), Vector3.new(0, 6.4, 0), r1, Mat.CorrodedMetal)
	Bx("Ventre", Vector3.new(3.4, 1.4, 2.4), Vector3.new(0, 4.0, 0), r2, Mat.CorrodedMetal)
	local c = Bx("Coeur", Vector3.new(1.2, 1.2, 0.3), Vector3.new(0, 6.4, -1.45), coeur, Mat.Neon)
	Bx("Grille", Vector3.new(1.6, 0.15, 0.2), Vector3.new(0, 6.4, -1.6), fer, Mat.Metal)
	Bx("Tete", Vector3.new(2.0, 1.6, 1.8), Vector3.new(0, 9.0, -0.2), r3, Mat.CorrodedMetal)
	Bx("Visiere", Vector3.new(1.6, 0.3, 0.1), Vector3.new(0, 9.1, -1.12), coeur, Mat.Neon)
	for _, sx in { -1, 1 } do
		Bx("Epaule", Vector3.new(1.8, 1.4, 2.0), Vector3.new(sx * 2.9, 7.6, 0), r2, Mat.CorrodedMetal)
		Bx("Bras", Vector3.new(1.2, 3.0, 1.2), Vector3.new(sx * 3.1, 5.4, 0), r1, Mat.CorrodedMetal)
		Bx("Poing", Vector3.new(2.0, 1.8, 2.0), Vector3.new(sx * 3.2, 3.1, 0), fer, Mat.Metal)
		Bx("Jambe", Vector3.new(1.5, 3.4, 1.6), Vector3.new(sx * 1.2, 1.7, 0), r2, Mat.CorrodedMetal)
		Bx("Pied", Vector3.new(1.9, 0.5, 2.4), Vector3.new(sx * 1.2, 0.25, -0.3), fer, Mat.Metal)
		for k = -1, 1 do
			Bx("Boulon", Vector3.new(0.25, 0.25, 0.15), Vector3.new(sx * 1.6, 6.4 + k * 1.0, -1.45), fer, Mat.Metal)
		end
	end
	Bx("Lierre", Vector3.new(0.6, 2.4, 0.2), Vector3.new(1.3, 6.0, 1.45), lierre, Mat.Grass)
	Bx("Mousse", Vector3.new(1.6, 0.3, 1.2), Vector3.new(-2.9, 8.4, 0.2), lierre, Mat.Grass)
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color = 12, 1.5, coeur
	l.Parent = c
	fini(m)
	m:ScaleTo(1.4)
	return m
end

-- Wyverne des neiges (redessinée) : blanche et bleu glacier, ailes membraneuses à 3 doigts, cornes, crête de glace
function M.wyverneNeiges(): Model
	local m, Bx, barre = bossBuilder("Wyverne_Neiges")
	local w1, w2, glace, memb = rgb(232, 240, 248), rgb(186, 204, 226), rgb(150, 220, 255), rgb(170, 200, 236)
	Bx("Corps", Vector3.new(2.4, 2.2, 4.4), Vector3.new(0, 3.6, 0.4), w1)
	Bx("Ventre", Vector3.new(2.0, 0.3, 3.8), Vector3.new(0, 2.5, 0.4), w2)
	for k = 0, 4 do
		Bx("Crete", Vector3.new(0.3, 0.8 - k * 0.08, 0.5), Vector3.new(0, 4.65 + (0.8 - k * 0.08) / 2, -1.2 + k * 0.9), glace, Mat.Ice)
	end
	barre("Cou", Vector3.new(0, 4.2, -1.6), Vector3.new(0, 5.8, -3.0), 1.1, w1)
	Bx("Tete", Vector3.new(1.4, 1.1, 1.8), Vector3.new(0, 6.1, -3.6), w1)
	Bx("Machoire", Vector3.new(1.1, 0.4, 1.4), Vector3.new(0, 5.5, -3.9), w2)
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.08, 0.22, 0.35), Vector3.new(sx * 0.71, 6.3, -3.9), glace, Mat.Neon)
		barre("Corne", Vector3.new(sx * 0.45, 6.6, -3.2), Vector3.new(sx * 0.8, 7.4, -2.4), 0.22, glace, Mat.Ice)
		-- aile : os de bras et trois doigts, membrane en panneaux
		local epaule, coude = Vector3.new(sx * 1.2, 4.4, -0.4), Vector3.new(sx * 4.0, 6.0, 0.2)
		barre("Bras", epaule, coude, 0.35, w2)
		for k, d in { { 7.2, 6.6, -0.2 }, { 7.0, 4.6, 1.2 }, { 5.6, 3.6, 2.2 } } do
			local bout = Vector3.new(sx * d[1], d[2], d[3])
			barre("Doigt", coude, bout, 0.2, w2)
			local mid = (coude + bout) / 2
			local mb = Bx("Membrane", Vector3.new(0.1, 1.6 - k * 0.2, (bout - coude).Magnitude * 0.8), Vector3.zero, memb, nil)
			mb.CFrame = CFrame.lookAt(mid + Vector3.new(0, -0.7, 0.6), bout + Vector3.new(0, -0.7, 0.6))
			mb.Transparency = 0.2
		end
		Bx("Patte", Vector3.new(0.7, 2.0, 0.8), Vector3.new(sx * 0.8, 1.6, 1.4), w2)
		Bx("Pied", Vector3.new(0.9, 0.4, 1.2), Vector3.new(sx * 0.8, 0.4, 1.2), glace, Mat.Ice)
	end
	for k = 0, 4 do
		Bx("Queue", Vector3.new(1.4 - k * 0.22, 1.2 - k * 0.18, 1.3), Vector3.new(0, 3.4 - k * 0.2, 3.1 + k * 1.15), k % 2 == 0 and w1 or w2)
	end
	Bx("Pointe", Vector3.new(0.6, 0.5, 0.9), Vector3.new(0, 2.4, 8.4), glace, Mat.Ice)
	fini(m)
	m:ScaleTo(1.8)
	return m
end

-- Tortue-Île (boss des marais, nageuse) : carapace en dalles à 3 tons portant un îlot (terre, herbe, petit arbre,
-- rochers), tête ridée aux yeux vieux, pattes-nageoires
function M.tortueIle(): Model
	local m, Bx = bossBuilder("Tortue_Ile")
	local c1, c2, c3, peau, terre, herbe = rgb(86, 98, 70), rgb(64, 76, 52), rgb(112, 124, 88), rgb(120, 136, 100), rgb(110, 84, 58), rgb(96, 150, 66)
	Bx("Carapace", Vector3.new(6, 2.4, 7), Vector3.new(0, 2.6, 0.4), c1)
	Bx("Bord", Vector3.new(6.6, 0.5, 7.6), Vector3.new(0, 1.5, 0.4), c2)
	for x = -1, 1 do
		for z = -1, 1 do
			Bx("Dalle", Vector3.new(1.7, 0.3, 2.0), Vector3.new(x * 1.9, 3.85, 0.4 + z * 2.2), (x + z) % 2 == 0 and c3 or c2)
		end
	end
	Bx("Terre", Vector3.new(4.4, 0.6, 5.0), Vector3.new(0, 4.3, 0.4), terre)
	Bx("Herbe", Vector3.new(4.0, 0.3, 4.6), Vector3.new(0, 4.75, 0.4), herbe, Mat.Grass)
	Bx("Tronc", Vector3.new(0.6, 2.4, 0.6), Vector3.new(0.8, 6.1, 1.0), rgb(100, 72, 48), Mat.Wood)
	Bx("Feuillage", Vector3.new(2.6, 1.6, 2.6), Vector3.new(0.8, 7.8, 1.0), rgb(80, 140, 60), Mat.Grass)
	Bx("Feuillage", Vector3.new(1.6, 1.0, 1.6), Vector3.new(0.9, 9.0, 0.8), rgb(110, 170, 80), Mat.Grass)
	Bx("Rocher", Vector3.new(1.2, 0.9, 1.0), Vector3.new(-1.3, 5.3, -0.8), rgb(130, 128, 120), Mat.Slate)
	Bx("Rocher", Vector3.new(0.7, 0.6, 0.8), Vector3.new(-1.6, 5.2, 1.6), rgb(150, 146, 138), Mat.Slate)
	Bx("Cou", Vector3.new(1.6, 1.4, 1.8), Vector3.new(0, 2.3, -3.6), peau)
	Bx("Tete", Vector3.new(2.0, 1.6, 2.0), Vector3.new(0, 2.6, -5.0), peau)
	Bx("Bec", Vector3.new(1.4, 0.6, 0.6), Vector3.new(0, 2.1, -6.1), c2)
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.1, 0.3, 0.4), Vector3.new(sx * 1.01, 3.0, -5.4), rgb(230, 200, 90), Mat.Neon)
		Bx("Ride", Vector3.new(0.05, 0.15, 0.9), Vector3.new(sx * 1.02, 2.5, -4.8), c2)
		for _, z in { -2.4, 2.8 } do
			Bx("Nageoire", Vector3.new(2.2, 0.6, 1.6), Vector3.new(sx * 3.6, 1.0, z), peau, nil, CFrame.Angles(0, sx * 0.3, sx * -0.2))
		end
	end
	Bx("Queue", Vector3.new(0.9, 0.7, 1.4), Vector3.new(0, 1.6, 4.6), peau)
	fini(m)
	m:ScaleTo(1.6)
	return m
end

-- Roc des falaises (boss volant) : rapace géant brun et crème, ailes déployées en 3 rangs de rémiges, bec crochu doré,
-- serres noires, plumes de tête en aigrette
function M.rocFalaises(): Model
	local m, Bx = bossBuilder("Roc_Falaises")
	local b1, b2, b3, creme, or1 = rgb(110, 74, 46), rgb(84, 56, 34), rgb(146, 102, 64), rgb(232, 220, 190), rgb(236, 186, 60)
	Bx("Corps", Vector3.new(2.4, 2.6, 3.6), Vector3.new(0, 3.6, 0.3), b1)
	Bx("Poitrail", Vector3.new(2.0, 2.0, 0.6), Vector3.new(0, 3.6, -1.6), creme)
	Bx("Tete", Vector3.new(1.4, 1.4, 1.5), Vector3.new(0, 5.3, -1.4), creme)
	Bx("Bec", Vector3.new(0.6, 0.6, 1.0), Vector3.new(0, 5.1, -2.5), or1)
	Bx("Bec", Vector3.new(0.4, 0.5, 0.3), Vector3.new(0, 4.8, -2.95), rgb(200, 150, 40))
	for k = 0, 2 do
		Bx("Aigrette", Vector3.new(0.2, 0.8 - k * 0.15, 0.3), Vector3.new(0, 6.3 - k * 0.05, -1.1 + k * 0.4), b2, nil, CFrame.Angles(math.rad(-25), 0, 0))
	end
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.08, 0.25, 0.3), Vector3.new(sx * 0.71, 5.5, -1.8), rgb(255, 200, 40), Mat.Neon)
		Bx("Epaule", Vector3.new(1.6, 0.6, 1.6), Vector3.new(sx * 1.8, 4.6, 0), b2)
		for r = 0, 2 do
			for k = 0, 4 do
				local x = sx * (2.4 + k * 1.1)
				Bx("Remige", Vector3.new(1.0, 0.25, 2.2 - r * 0.5 + k * 0.15), Vector3.new(x, 4.7 + k * 0.15 - r * 0.15, 0.3 + r * 0.7), r == 0 and b3 or (r == 1 and b1 or b2))
			end
		end
		Bx("Patte", Vector3.new(0.5, 1.6, 0.5), Vector3.new(sx * 0.6, 1.6, 0.6), or1)
		Bx("Serres", Vector3.new(0.8, 0.4, 1.0), Vector3.new(sx * 0.6, 0.6, 0.3), rgb(30, 28, 30))
	end
	Bx("Queue", Vector3.new(1.8, 0.3, 2.2), Vector3.new(0, 3.4, 3.0), b2)
	Bx("Queue", Vector3.new(1.4, 0.25, 1.0), Vector3.new(0, 3.3, 4.4), creme)
	fini(m)
	m:ScaleTo(1.7)
	return m
end

-- Bête des profondeurs (boss des marais, redessinée) : long serpent de vase cuirassé, plaques dorsales en écailles,
-- tête dressée à deux mâchoires et crocs, barbillons lumineux, anneaux qui s'amincissent vers la queue
function M.beteProfondeurs(): Model
	local m, Bx, barre = bossBuilder("Serpent_Profondeurs")
	local v1, v2, v3, ventre, lueur = rgb(46, 60, 44), rgb(34, 44, 34), rgb(70, 90, 62), rgb(160, 160, 110), rgb(150, 255, 170)
	local prev = Vector3.new(0, 1.4, 6)
	for k = 0, 9 do
		local z = 6 - k * 1.1
		local x = math.sin(k * 0.7) * 1.4
		local y = 1.2 + math.max(0, k - 6) * 0.9
		local p = Vector3.new(x, y, z)
		local e = 0.9 + math.min(k, 6) * 0.12
		barre("Anneau", prev, p, e * 1.4, (k % 2 == 0) and v1 or v2)
		Bx("Plaque", Vector3.new(e * 0.8, 0.3, 0.8), p + Vector3.new(0, e * 0.72, 0), v3)
		Bx("Ventre", Vector3.new(e * 1.1, 0.2, 0.9), p - Vector3.new(0, e * 0.66, 0), ventre)
		prev = p
	end
	-- tête au bout du cou dressé
	local tete = prev + Vector3.new(0, 0.9, -1.0)
	Bx("Crane", Vector3.new(2.2, 1.4, 2.4), tete, v1)
	Bx("Machoire", Vector3.new(1.8, 0.6, 2.0), tete + Vector3.new(0, -1.0, -0.6), v2)
	Bx("Gueule", Vector3.new(1.6, 0.4, 1.6), tete + Vector3.new(0, -0.55, -0.7), rgb(110, 30, 40))
	for i = -2, 2 do
		Bx("Croc", Vector3.new(0.16, 0.4, 0.16), tete + Vector3.new(i * 0.35, -0.5, -1.55), rgb(236, 230, 210))
	end
	for _, sx in { -1, 1 } do
		Bx("Oeil", Vector3.new(0.35, 0.25, 0.1), tete + Vector3.new(sx * 0.7, 0.35, -1.22), lueur, Mat.Neon)
		barre("Barbillon", tete + Vector3.new(sx * 0.8, -0.6, -1.0), tete + Vector3.new(sx * 1.6, -1.6, -1.8), 0.12, v3)
		Bx("Lueur", Vector3.new(0.25, 0.25, 0.25), tete + Vector3.new(sx * 1.6, -1.6, -1.8), lueur, Mat.Neon)
		Bx("Crete", Vector3.new(0.2, 0.9, 1.0), tete + Vector3.new(sx * 0.6, 1.0, 0.4), v3, nil, CFrame.Angles(0, 0, sx * -0.3))
	end
	fini(m)
	m:ScaleTo(1.6)
	return m
end

return M
