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
	-- Chêne
	do
		local m = nouveau("Arbre_Chene")
		P(m, "Tronc", Vector3.new(1.8, 8, 1.8), Vector3.new(0, 4, 0), BOIS, Mat.Wood)
		P(m, "Racine", Vector3.new(3, 0.8, 3), Vector3.new(0, 0.4, 0), BOIS_FONCE, Mat.Wood, { collide = false })
		local v1, v2 = rgb(88, 152, 62), rgb(108, 170, 72)
		feuillage(P(m, "Feuillage", Vector3.new(9, 5, 9), Vector3.new(0, 10, 0), v1, Mat.Grass), true)
		feuillage(P(m, "Feuillage", Vector3.new(6.5, 3.5, 6.5), Vector3.new(0.6, 13.6, -0.4), v2, Mat.Grass), true)
		feuillage(P(m, "Feuillage", Vector3.new(4, 3.5, 4), Vector3.new(-4.2, 9.2, 1.5), v2, Mat.Grass), true)
		feuillage(P(m, "Feuillage", Vector3.new(4, 3, 4), Vector3.new(3.8, 8.8, 2.4), v1, Mat.Grass), true)
		feuillage(P(m, "Feuillage", Vector3.new(3.6, 3, 3.6), Vector3.new(1.4, 9, -4.4), v2, Mat.Grass), true)
		fini(m)
	end
	-- Sapin
	do
		local m = nouveau("Arbre_Sapin")
		P(m, "Tronc", Vector3.new(1.4, 5, 1.4), Vector3.new(0, 2.5, 0), BOIS_FONCE, Mat.Wood)
		local v1, v2 = rgb(46, 104, 64), rgb(58, 122, 74)
		local etages = { { 9, 4.4 }, { 7.2, 7 }, { 5.4, 9.6 }, { 3.6, 12 }, { 1.8, 14 } }
		for i, e in etages do
			feuillage(P(m, "Feuillage", Vector3.new(e[1], 2.6, e[1]), Vector3.new(0, e[2], 0), i % 2 == 0 and v2 or v1, Mat.Grass), false)
		end
		fini(m)
	end
	-- Bouleau
	do
		local m = nouveau("Arbre_Bouleau")
		P(m, "Tronc", Vector3.new(1.3, 10, 1.3), Vector3.new(0, 5, 0), rgb(232, 228, 216), Mat.Wood)
		for i, y in { 2.2, 4.6, 6.4, 8.5 } do
			P(m, "Tache", Vector3.new(1.36, 0.3, 0.7), Vector3.new(0, y, (i % 2 == 0) and 0.2 or -0.2), rgb(40, 40, 40), Mat.SmoothPlastic, { collide = false })
		end
		local v1, v2 = rgb(150, 192, 82), rgb(170, 204, 96)
		feuillage(P(m, "Feuillage", Vector3.new(5.5, 7, 5.5), Vector3.new(0, 12, 0), v1, Mat.Grass), true)
		feuillage(P(m, "Feuillage", Vector3.new(3.5, 4, 3.5), Vector3.new(2.6, 10, 1.2), v2, Mat.Grass), true)
		feuillage(P(m, "Feuillage", Vector3.new(3, 3.5, 3), Vector3.new(-2.4, 11, -1.4), v2, Mat.Grass), true)
		fini(m)
	end
	-- Cerisier
	do
		local m = nouveau("Arbre_Cerisier")
		P(m, "Tronc", Vector3.new(1.5, 6, 1.5), Vector3.new(0, 3, 0), rgb(96, 62, 50), Mat.Wood)
		P(m, "Branche", Vector3.new(0.8, 3, 0.8), Vector3.new(1.2, 6.5, 0), rgb(96, 62, 50), Mat.Wood, { rot = CFrame.Angles(0, 0, math.rad(-35)) })
		local r1, r2 = rgb(240, 166, 196), rgb(250, 190, 212)
		feuillage(P(m, "Feuillage", Vector3.new(8, 4, 7), Vector3.new(0.5, 8.6, 0), r1, Mat.Grass), true)
		feuillage(P(m, "Feuillage", Vector3.new(5, 3, 5), Vector3.new(-0.5, 11.2, 0.6), r2, Mat.Grass), true)
		feuillage(P(m, "Feuillage", Vector3.new(3.4, 2.6, 3.4), Vector3.new(3.6, 8, 2), r2, Mat.Grass), true)
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
		local m = nouveau("Arbre_Saule")
		local brun = rgb(128, 104, 78)
		P(m, "Tronc", Vector3.new(1.8, 8, 1.8), Vector3.new(0, 4, 0), brun, Mat.Wood)
		P(m, "Branche", Vector3.new(0.8, 3.4, 0.8), Vector3.new(1.2, 8.4, 0), brun, Mat.Wood, { rot = CFrame.Angles(0, 0, math.rad(-40)) })
		P(m, "Branche", Vector3.new(0.8, 3.4, 0.8), Vector3.new(-1.2, 8.2, 0.4), brun, Mat.Wood, { rot = CFrame.Angles(0, 0, math.rad(40)) })
		local v1, v2 = rgb(110, 156, 76), rgb(136, 176, 92)
		feuillage(P(m, "Feuillage", Vector3.new(10, 5, 10), Vector3.new(0, 10, 0), v1, Mat.Grass, { forme = "Ball" }), false)
		feuillage(P(m, "Feuillage", Vector3.new(7, 4, 7), Vector3.new(0.5, 12, -0.3), v2, Mat.Grass, { forme = "Ball" }), false)
		-- rameaux qui retombent
		for i = 0, 13 do
			local a = i * math.pi * 2 / 14
			local r = 3.6 + (i % 3) * 0.5
			local len = 5 + (i % 4) * 0.8
			local x, z = math.cos(a) * r, math.sin(a) * r
			feuillage(P(m, "Feuillage", Vector3.new(0.9, len, 0.9), Vector3.new(x, 9.5 - len / 2, z), (i % 2 == 0) and v2 or v1, Mat.Grass), false)
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
	fini(m)
end

function PROPS_VALDOR.Tonneaux()
	local m = nouveau("Tonneaux")
	for i, p in { Vp(0, 0, 0), Vp(2.02, 0, 0.26), Vp(0.92, 0, 1.82) } do
		local h, diam = 2.62 - (i - 1) * 0.39, 2.05 - (i - 1) * 0.13
		local c = i % 2 == 0 and BOIS_CLAIR or BOIS
		for j, t in { { 0.16, 0.87, 0.32 }, { 0.49, 1, 0.39 }, { 0.83, 0.86, 0.34 } } do
			cylProp(m, "Douelles", diam * t[2], h * t[3], p + Vp(0, h * t[1], 0), teinteProp(c, j), Mat.WoodPlanks)
		end
		cylProp(m, "Fond du fût", diam * 0.76, 0.07, p + Vp(0, h, 0), BOIS_FONCE, Mat.Wood)
		lamesProp(m, "Lame", Vp(diam * 0.59, 0.05, diam * 0.51), p + Vp(0, h + 0.022, 0), 3, "Z", c)
		for _, t in { 0.25, 0.76 } do
			local y = h * t
			cylProp(m, "Cercle", diam * 0.98, 0.125, p + Vp(0, y, 0), FER, Mat.Metal, nil, false)
			for _, x in { -0.31, 0.29 } do rivetProp(m, p + Vp(x, y, diam * 0.46), 0.105) end
		end
		cylProp(m, "Bonde", 0.18, 0.08, p + Vp(0.16, h + 0.048, 0), BOIS_CLAIR, Mat.Wood)
	end
	fini(m)
end

local function caisseProp(m: Model, p: Vector3, size: number, c: Color3, ouverte: boolean)
	P(m, "Fond", Vp(size, size * 0.13, size), p + Vp(0, size * 0.065, 0), BOIS_FONCE, Mat.WoodPlanks)
	for _, s in { -1, 1 } do
		lamesProp(m, "Bordage", Vp(size, size * 0.84, 0.13), p + Vp(0, size * 0.55, s * (size / 2 - 0.065)), 2, "Y", c)
		lamesProp(m, "Bordage", Vp(0.13, size * 0.84, size - 0.18), p + Vp(s * (size / 2 - 0.065), size * 0.55, 0), 2, "Y", c)
		for _, x in { -0.43, 0.43 } do
			P(m, "Cornière", Vp(0.20, size, 0.20), p + Vp(size * x, size / 2, s * size * 0.43), BOIS_FONCE, Mat.Wood)
		end
	end
	if ouverte then
		P(m, "Fond garni", Vp(size * 0.86, size * 0.10, size * 0.83), p + Vp(0, size * 0.82, 0), BOIS, Mat.Wood)
	else
		lamesProp(m, "Couvercle", Vp(size, size * 0.11, size), p + Vp(0, size * 0.96, 0), 3, "X", c)
		lienProp(m, "Écharpe", p + Vp(-size * 0.42, size * 0.18, size * 0.50),
			p + Vp(size * 0.42, size * 0.86, size * 0.50), 0.17, 0.11, BOIS_FONCE, Mat.Wood, false)
	end
end

function PROPS_VALDOR.Caisses()
	local m = nouveau("Caisses")
	caisseProp(m, Vector3.zero, 2.37, BOIS_CLAIR, false)
	caisseProp(m, Vp(2.03, 0, 0.35), 1.84, BOIS, true)
	caisseProp(m, Vp(0.32, 2.37, -0.1), 1.68, BOIS, false)
	for i = 0, 4 do
		local x, z = 1.58 + i % 3 * 0.47, 0.04 + math.floor(i / 3) * 0.64
		P(m, "Choux", Vp(0.58, 0.56, 0.55), Vp(x, 1.74, z), rgb(106 + i * 3, 133 + i * 3, 68),
			Mat.Grass, { forme = "Ball", collide = false })
	end
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
	fini(m)
end

local function coffreProp(nom: string, c: Color3, colFer: Color3)
	local m = nouveau(nom)
	lamesProp(m, "Caisse", Vp(3, 1.55, 1.99), Vp(0, 0.775, 0), 5, "X", c)
	lamesProp(m, "Couvercle", Vp(3.08, 0.34, 2.08), Vp(0, 1.68, 0), 5, "X", c)
	lamesProp(m, "Bombé", Vp(3.07, 0.33, 1.73), Vp(0, 1.95, 0), 5, "X", BOIS_CLAIR)
	lamesProp(m, "Faîtage", Vp(3.03, 0.18, 1.2), Vp(0, 2.17, 0), 5, "X", c)
	for _, x in { -1.04, 1.04 } do
		for _, z in { -1, 1 } do
			P(m, "Cerclage", Vp(0.23, 1.65, 0.10), Vp(x, 0.89, z), colFer, Mat.Metal, { collide = false })
			lienProp(m, "Cerclage", Vp(x, 1.68, z), Vp(x, 2.27, z * 0.56), 0.22, 0.086, colFer, Mat.Metal, false)
		end
		P(m, "Cerclage", Vp(0.22, 0.087, 1.16), Vp(x, 2.28, 0), colFer, Mat.Metal, { collide = false })
		for _, y in { 0.28, 1.42 } do rivetProp(m, Vp(x, y, 1.06), 0.12, OR) end
	end
	P(m, "Serrure", Vp(0.44, 0.49, 0.14), Vp(0, 1.59, 1.06), OR, Mat.Metal, { collide = false })
	P(m, "Entrée", Vp(0.09, 0.16, 0.05), Vp(0, 1.61, 1.14), FER, Mat.Metal, { collide = false })
	fini(m)
end

function PROPS_VALDOR.Coffre_Joueur()
	coffreProp("Coffre_Joueur", BOIS, FER)
end

function PROPS_VALDOR.Coffre()
	coffreProp("Coffre", BOIS, rgb(163, 116, 50))
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
	for i = 0, 6 do
		P(m, "Dent de scie", Vp(0.13, 0.061, 0.14), Vp(-1.39 + i * 0.22, 3.27, 0.39), PIERRE_CLAIRE, Mat.Metal,
			{ forme = "Wedge", collide = false })
	end
	lienProp(m, "Marteau", Vp(1.08, 3.29, 0.50), Vp(1.33, 3.36, -0.55), 0.17, 0.17, BOIS, Mat.Wood, false)
	P(m, "Tete", Vp(0.72, 0.32, 0.36), Vp(1.33, 3.39, -0.54), FER, Mat.Metal, { collide = false })
	fini(m)
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
	for _, y in { 0.40, 1.32 } do cercleProp(m, "Cercle", Vp(-0.87, y, 0), 1.27, 10, 0.12, FER, Mat.Metal) end
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
	if eau then
		P(m, "Eau", Vp(longueur - 0.23, 0.06, 1.0), Vp(0, niveau + 0.22, 0), EAU_PROP, Mat.Glass, { collide = false, transp = 0.23 })
	else
		for i = 0, 4 do
			P(m, "Foin", Vp(0.69, 0.58 + i % 3 * 0.10, 0.91), Vp((i - 2) * 0.55, niveau + 0.45, i % 2 * 0.09),
				teinteProp(CHAUME, i), Mat.Grass, { forme = "Ball", collide = false })
		end
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
	fini(m)
end

function PROPS_VALDOR.Banc()
	local m = nouveau("Banc")
	cadreTable(m, 3.98, 1.18, 1.38)
	lamesProp(m, "Assise", Vp(3.99, 0.28, 1.19), Vp(0, 1.49, 0), 3, "Z", BOIS_CLAIR)
	P(m, "Traverse", Vp(3.71, 0.18, 0.23), Vp(0, 0.54, 0), BOIS_FONCE, Mat.Wood)
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
		for j = 0, 2 do
			local a = j * PASSE / 3
			P(m, "Fleur", Vp(0.23, 0.18, 0.22), h + Vp(math.cos(a) * 0.1, 0, math.sin(a) * 0.1),
				c, Mat.Fabric, { forme = "Ball", collide = false })
		end
	end
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
	fini(m)
end

function PROPS_VALDOR.Plancher()
	local m = nouveau("Plancher")
	lamesProp(m, "Planches", Vp(4, 0.4, 4), Vp(0, 0.2, 0), 7, "X", BOIS_CLAIR)
	for _, z in { -1.7, 1.7 } do
		P(m, "Solive", Vp(4, 0.16, 0.23), Vp(0, 0.08, z), BOIS_FONCE, Mat.Wood)
		for x = -1.55, 1.55, 0.62 do rivetProp(m, Vp(x, 0.404, z), 0.077) end
	end
	fini(m)
end

local function murBoise(nom: string, porte: boolean, fenetre: boolean)
	local m = nouveau(nom)
	for _, x in { -2, 2 } do
		P(m, "Poteau", Vp(0.6, 7.2, 0.6), Vp(x, 3.6, 0), BOIS_FONCE, Mat.Wood)
		for _, y in { 0.43, 6.75 } do
			P(m, "Bride", Vp(0.63, 0.19, 0.63), Vp(x, y, 0), FER, Mat.Metal, { collide = false })
			rivetProp(m, Vp(x, y, 0.325), 0.124)
		end
	end
	if porte then
		lamesProp(m, "Linteau", Vp(3.97, 1.4, 0.49), Vp(0, 6.3, 0), 7, "X", BOIS_CLAIR)
		for _, x in { -1.65, 1.65 } do
			lamesProp(m, "Montant", Vp(0.7, 5.62, 0.49), Vp(x, 2.81, 0), 2, "X", BOIS)
		end
	elseif fenetre then
		lamesProp(m, "Bas", Vp(3.99, 2.6, 0.49), Vp(0, 1.3, 0), 8, "X", BOIS_CLAIR)
		lamesProp(m, "Haut", Vp(3.99, 1.8, 0.49), Vp(0, 6.1, 0), 8, "X", BOIS_CLAIR)
		for _, x in { -1.55, 1.55 } do lamesProp(m, "Cote", Vp(0.9, 2.61, 0.49), Vp(x, 3.9, 0), 2, "X", BOIS) end
		P(m, "Vitre", Vp(2.2, 2.62, 0.11), Vp(0, 3.9, 0), rgb(156, 190, 207), Mat.Glass, { transp = 0.46 })
		P(m, "Croisillon", Vp(2.26, 0.14, 0.30), Vp(0, 3.90, 0), BOIS_FONCE, Mat.Wood)
		P(m, "Croisillon", Vp(0.14, 2.62, 0.30), Vp(0, 3.90, 0), BOIS_FONCE, Mat.Wood)
		for _, y in { 2.57, 5.20 } do P(m, "Cadre", Vp(2.35, 0.21, 0.64), Vp(0, y, 0), BOIS_FONCE, Mat.Wood) end
	else
		lamesProp(m, "Mur", Vp(3.99, 7, 0.5), Vp(0, 3.5, 0), 8, "X", BOIS_CLAIR)
	end
	for _, y in { porte and 5.66 or 0.23, 6.89 } do
		P(m, "Traverse", Vp(4.01, 0.21, 0.58), Vp(0, y, 0), BOIS_FONCE, Mat.Wood)
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
	for i = 0, rangs - 1 do
		local joint = i % 2 == 0 and { 1.05, 1.67, 1.28 } or { 0.78, 1.22, 0.87, 1.13 }
		local x = -2
		for j, w in joint do
			P(m, "Moellon", Vp(w - 0.026, h, 0.48 + (j + i) % 3 * 0.014), Vp(x + w / 2, h * (i + 0.5), 0),
				c:Lerp(PIERRE, (i + j) % 3 * 0.12), mat)
			x += w
		end
	end
	P(m, "Arase", Vp(4.03, 0.17, 0.58), Vp(0, 6.97, 0), c, mat)
	fini(m)
end

function PROPS_VALDOR.Mur_Pierre() murMaconne("Mur_Pierre", CALCAIRE, Mat.Slate, 7) end
function PROPS_VALDOR.Mur_Briques() murMaconne("Mur_Briques", rgb(153, 87, 65), Mat.Brick, 10) end

function PROPS_VALDOR.Toit_Chaume()
	local m = nouveau("Toit_Chaume")
	-- Le dessous conserve sa cote pour s'emboîter sur les anciens murs.
	P(m, "Rive", Vp(4.79, 0.25, 4.79), Vp(0, 7.05, 0), BOIS_FONCE, Mat.Wood)
	for _, z in { -1.75, 1.75 } do
		P(m, "Chevron", Vp(4.71, 0.19, 0.30), Vp(0, 7.22, z), BOIS, Mat.Wood)
	end
	toitureProp(m, 4.71, 4.71, 7.27, 1.14, 0, true)
	fini(m)
end

function PROPS_VALDOR.Escalier_Bois()
	local m = nouveau("Escalier_Bois")
	for i = 0, 7 do
		local y, z = 0.44 + i * 0.92, 1.75 - i * 0.50
		P(m, "Marche", Vp(3.59, 0.88, 0.50), Vp(0, y, z), teinteProp(BOIS_CLAIR, i), Mat.WoodPlanks)
		P(m, "Nez", Vp(3.61, 0.13, 0.11), Vp(0, y + 0.36, z + 0.18), BOIS_FONCE, Mat.Wood)
	end
	for _, x in { -1.71, 1.71 } do
		lienProp(m, "Limon", Vp(x, 0.33, 1.76), Vp(x, 6.77, -1.77), 0.23, 0.32, BOIS_FONCE, Mat.Wood, false)
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
	fini(m)
end

function PROPS_VALDOR.Branche()
	local m = nouveau("Branche")
	lienProp(m, "Bois", Vp(-1.36, 0.165, -0.25), Vp(0.39, 0.215, 0.03), 0.27, 0.25, BOIS_FONCE, Mat.Wood, false)
	lienProp(m, "Fourche", Vp(0.15, 0.21, 0.02), Vp(1.14, 0.19, -0.31), 0.19, 0.18, BOIS, Mat.Wood, false)
	lienProp(m, "Fourche", Vp(0.15, 0.21, 0.02), Vp(0.72, 0.16, 0.68), 0.14, 0.15, BOIS, Mat.Wood, false)
	lienProp(m, "Brindille", Vp(0.44, 0.19, 0.31), Vp(0.19, 0.13, 0.67), 0.089, 0.083, BOIS, Mat.Wood, false)
	lienProp(m, "Écorce fendue", Vp(-1.31, 0.20, -0.25), Vp(-0.93, 0.31, -0.19), 0.085, 0.023, BOIS_CLAIR, Mat.Wood, false)
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
	fini(m)
end

function PROPS_VALDOR.Fleurs()
	local m = nouveau("Fleurs")
	for i, p in { Vp(0, 0, 0), Vp(0.33, 0, 0.17), Vp(-0.37, 0, 0.19), Vp(0.11, 0, -0.33) } do
		local h = p + Vp(p.X * 0.9, 0.67 + i % 3 * 0.159, p.Z * 0.93)
		lienProp(m, "Tige", p * 0.33 + Vp(0, 0.03, 0), h, 0.065, 0.061, rgb(86, 119, 65), Mat.Grass, false)
		lienProp(m, "Feuille", (p + h) / 2, (p + h) / 2 + Vp(i % 2 == 0 and -0.2 or 0.21, 0.19, 0.05),
			0.11, 0.065, rgb(104, 134, 73), Mat.Grass, false)
		for j = 0, 3 do
			local a = j * PASSE / 4
			P(m, "Petale", Vp(0.179, 0.12, 0.17), h + Vp(math.cos(a) * 0.11, 0.04, math.sin(a) * 0.11),
				i % 2 == 0 and LIN or CHAUME, Mat.Fabric, { forme = "Ball", collide = false })
		end
		cylProp(m, "Cœur", 0.15, 0.079, h + Vp(0, 0.048, 0), OR, Mat.Fabric, nil, false)
	end
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
		for j = -1, 1 do
			P(m, "Moucheture", Vp(d * 0.13, 0.036, d * 0.113), p + Vp(d * j * 0.22, h + d * 0.25, d * (j % 2) * 0.09),
				LIN, Mat.Sand, { forme = "Ball", collide = false })
		end
	end
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
local NOMS_STATIONS = { "Enclume", "Metier_Tisser", "Bac_Tannage", "Alambic", "Abreuvoir", "Mangeoire" }

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

	local cochon = nouveau("Cochon")
	local rose, groin, sabot = rgb(218, 150, 138), rgb(241, 180, 170), rgb(99, 63, 58)
	forme(cochon, "Corps", Vector3.new(2.2, 1.7, 3.2), Vector3.new(0, 1.55, 0.2), rose, { forme = "Ball" })
	forme(cochon, "Tête", Vector3.new(1.55, 1.32, 1.45), Vector3.new(0, 1.6, -1.35), rose, { forme = "Ball" })
	forme(cochon, "Groin", Vector3.new(0.38, 0.66, 0.94), Vector3.new(0, 1.36, -2.02), groin,
		{ forme = "Cylinder", rot = CFrame.Angles(0, math.pi / 2, 0) })
	yeux(cochon, 0.42, 1.77, -1.91)
	for _, cote in { -1, 1 } do
		forme(cochon, "Narine", Vector3.new(0.12, 0.15, 0.08), Vector3.new(cote * 0.21, 1.38, -2.22), sabot)
		forme(cochon, "Oreille", Vector3.new(0.4, 0.58, 0.3), Vector3.new(cote * 0.56, 2.22, -1.32), groin,
			{ forme = "Wedge", rot = CFrame.Angles(0, 0, -cote * math.rad(24)) })
		for _, z in { -0.78, 1.03 } do
			forme(cochon, "Patte", Vector3.new(0.41, 1.04, 0.44), Vector3.new(cote * 0.62, 0.67, z), rose)
			forme(cochon, "Sabot", Vector3.new(0.43, 0.25, 0.5), Vector3.new(cote * 0.62, 0.13, z), sabot)
		end
	end
	local function pointQueue(a: number): Vector3
		return Vector3.new(math.cos(a) * 0.22, 1.92 + math.sin(a) * 0.23, 1.62 + a * 0.055)
	end
	for i = 0, 7 do
		local a, b = pointQueue(i * math.pi / 4), pointQueue((i + 1) * math.pi / 4)
		forme(cochon, "Queue", Vector3.new(0.12, 0.12, (b - a).Magnitude + 0.035), Vector3.zero, rose,
			{ cf = CFrame.lookAt((a + b) / 2, b) })
	end
	fini(cochon)

	local oie = nouveau("Oie")
	local blanc, plume, orange = rgb(244, 238, 220), rgb(216, 212, 199), rgb(224, 143, 67)
	forme(oie, "Corps", Vector3.new(1.45, 1.3, 2.65), Vector3.new(0, 1.1, 0.28), blanc, { forme = "Ball" })
	forme(oie, "Cou bas", Vector3.new(0.59, 1.38, 0.64), Vector3.new(0, 1.88, -0.66), blanc,
		{ forme = "Ball", rot = CFrame.Angles(math.rad(-32), 0, 0) })
	forme(oie, "Cou", Vector3.new(0.47, 1.27, 0.51), Vector3.new(0, 2.38, -0.98), blanc, { forme = "Ball" })
	forme(oie, "Tête", Vector3.new(0.76, 0.69, 0.78), Vector3.new(0, 2.94, -1.05), blanc, { forme = "Ball" })
	forme(oie, "Bec", Vector3.new(0.52, 0.24, 0.74), Vector3.new(0, 2.81, -1.57), orange,
		{ forme = "Wedge", rot = CFrame.Angles(0, math.pi, 0) })
	forme(oie, "Queue", Vector3.new(0.85, 0.34, 1.03), Vector3.new(0, 1.35, 1.5), plume,
		{ forme = "Wedge", rot = CFrame.Angles(math.rad(8), 0, 0) })
	yeux(oie, 0.25, 3.03, -1.36)
	for _, cote in { -1, 1 } do
		forme(oie, "Aile", Vector3.new(0.36, 0.78, 1.88), Vector3.new(cote * 0.58, 1.21, 0.43), plume,
			{ forme = "Ball", rot = CFrame.Angles(math.rad(-14), 0, 0) })
		forme(oie, "Patte", Vector3.new(0.13, 0.69, 0.16), Vector3.new(cote * 0.31, 0.43, 0.12), orange)
		forme(oie, "Palme", Vector3.new(0.42, 0.16, 0.62), Vector3.new(cote * 0.31, 0.08, -0.09), orange,
			{ forme = "Wedge", rot = CFrame.Angles(0, cote * math.rad(10), 0) })
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
	local function volume(nom: string, taille: Vector3, pos: Vector3, couleur: Color3, rot: CFrame?)
		P(m, nom, taille, pos, couleur, Mat.SmoothPlastic, { forme = "Ball", rot = rot, collide = false })
	end
	volume("Corps", Vector3.new(1.64, 1.52, 3), Vector3.new(0, 1.84, 0.23), pelage)
	volume("Cou", Vector3.new(0.8, 1.4, 0.9), Vector3.new(0, 2.2, -0.99), pelage, CFrame.Angles(math.rad(-32), 0, 0))
	volume("Tête", Vector3.new(0.91, 0.97, 1.08), Vector3.new(0, 2.66, -1.45), pelage)
	volume("Museau", Vector3.new(0.67, 0.48, 0.6), Vector3.new(0, 2.38, -1.91), masque)
	volume("Truffe", Vector3.new(0.32, 0.15, 0.12), Vector3.new(0, 2.45, -2.19), sabot)
	volume("Barbiche", Vector3.new(0.27, 0.61, 0.25), Vector3.new(0, 1.99, -1.98), masque, CFrame.Angles(math.rad(-15), 0, 0))
	volume("Queue", Vector3.new(0.34, 0.73, 0.36), Vector3.new(0, 2.39, 1.63), pelage, CFrame.Angles(math.rad(35), 0, 0))
	for _, cote in { -1, 1 } do
		volume("Oreille", Vector3.new(0.65, 0.2, 0.33), Vector3.new(cote * 0.56, 2.76, -1.29), masque,
			CFrame.Angles(0, -cote * math.rad(13), -cote * math.rad(18)))
		volume("Œil", Vector3.new(0.11, 0.14, 0.18), Vector3.new(cote * 0.37, 2.73, -1.72), sabot)
		for _, z in { -0.72, 1.12 } do
			volume("Patte", Vector3.new(0.35, 1.38, 0.39), Vector3.new(cote * 0.49, 0.82, z), pelage)
			P(m, "Sabot", Vector3.new(0.33, 0.25, 0.42), Vector3.new(cote * 0.49, 0.125, z), sabot, Mat.SmoothPlastic, { collide = false })
		end
		local courbe = {
			Vector3.new(cote * 0.26, 2.99, -1.5),
			Vector3.new(cote * 0.32, 3.37, -1.4),
			Vector3.new(cote * 0.39, 3.64, -1.18),
			Vector3.new(cote * 0.43, 3.8, -0.93),
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

-- Créatures du monde vivant (ennemis par biome, monstres de nuit, animaux sauvages).
-- Convention des bêtes : pièce « Base » au sol, tout ancré, sans collision, la tête vers -Z.
function M.creatures()
	dossier = dossierModeles()
	M.animauxFerme()
	M.chevre()
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
	quadrupede("Ours", {
		corps = Vector3.new(3, 2.6, 4.4), couleur = rgb(100, 68, 44), pattes = 1.6, tete = Vector3.new(2, 1.8, 1.8), patte = 1,
		extra = function(m, c)
			museau(m, c, rgb(170, 130, 96), Vector3.new(1, 0.8, 0.7))
			for _, sx in { -1, 1 } do
				Q(m, "Oreille", Vector3.new(0.6, 0.6, 0.3), Vector3.new(sx * 0.7, c.hy + 1.05, c.hz + 0.2), rgb(80, 54, 36), Mat.SmoothPlastic, { forme = "Cylinder", rot = CFrame.Angles(0, math.rad(90), 0) })
			end
			queue(m, c, rgb(80, 54, 36), Vector3.new(0.5, 0.5, 0.5), 0)
		end,
	})
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
		local m = nouveau("Feu_Follet")
		local coeur = Q(m, "Coeur", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 3, 0), rgb(150, 230, 255), Mat.Neon, { forme = "Ball", transp = 0.15 })
		Q(m, "Halo", Vector3.new(2.4, 2.4, 2.4), Vector3.new(0, 3, 0), rgb(120, 200, 255), Mat.Neon, { forme = "Ball", transp = 0.7 })
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
		end
		part(m, "Crâne", V(1.64, 1.35, 1.75), V(0, 1.63, -2.6), back, Mat.SmoothPlastic)
		part(m, "Mufle", V(1.23, 0.51, 1.15), V(0, 1.30, -3.40), rgb(123, 168, 140), Mat.SmoothPlastic)
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
			P(m, "Faux", Vector3.new(0.3, 0.3, 4), Vector3.new(sx * 5.4, 10.6, -1.4), rgb(180, 180, 190), Mat.Metal, { collide = false })
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
	local rng = Random.new(18)
	for iz = 0, 7 do
		for ix = 0, 10 do
			local x = -W / 2 + 1.2 + ix * ((W - 2.4) / 10) + rng:NextNumber(-0.2, 0.2)
			local z = -D / 2 + 1.2 + iz * ((D - 2.4) / 7)
			local h = rng:NextNumber(3, 3.8)
			local gold = rgb(214, 168, 62):Lerp(rgb(238, 204, 108), rng:NextNumber())
			local tilt = CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), 0, math.rad(rng:NextNumber(-6, 6)))
			-- une « Touffe » = un bloc récoltable au clic (Systemes/Moissons)
			local t = Instance.new("Model")
			t.Name = "Touffe"
			t.Parent = m
			local hauteur = h + 0.42
			local largeur = 1.33 + (ix + iz) % 3 * 0.13
			local azimut = CFrame.Angles(0, ((ix * 5 + iz * 7) % 13) * math.pi / 7, 0)
			P(t, "Epis", Vp(largeur, hauteur, 0.86 + ix % 2 * 0.19), Vector3.zero, gold, Mat.Grass,
				{ cf = CFrame.new(x, 0.36 + hauteur / 2, z) * tilt * azimut, collide = false, forme = "Wedge" })
		end
	end
	-- clôture : poteaux tous les 4 studs, deux lisses
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

return M
