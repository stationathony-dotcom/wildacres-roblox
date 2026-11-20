--!strict
-- Construit les modèles du décor dans ServerStorage.Modeles (style « blocs mignons »).
-- À lancer depuis la barre de commande : require(game.ServerStorage.OutilsDev.ConstruireModeles).tout()
-- Chaque modèle a une pièce invisible « Base » posée au sol (pivot = point au sol, façade vers +Z).
-- Une fois construits, les modèles se retouchent librement dans Studio : le jeu les clone tels quels.

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local M = {}

local Mat = Enum.Material
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local BOIS = rgb(122, 84, 52)
local BOIS_FONCE = rgb(84, 56, 36)
local BOIS_CLAIR = rgb(170, 125, 80)
local PIERRE = rgb(128, 128, 134)
local PIERRE_CLAIRE = rgb(160, 158, 150)
local CREPI = rgb(238, 224, 196)
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
		P(m, "Fleur", Vector3.new(0.7, 0.4, 0.7), Vector3.new(0, 6.9, 0), rgb(240, 120, 160), Mat.SmoothPlastic, { collide = false })
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

-- Artisanat : filons de minerai, argile, four, pièces de construction (grille de 4 studs), lit, lanterne
function M.artisanat()
	dossier = dossierModeles()
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
	filon("Filon_Charbon", rgb(34, 32, 36), Mat.Slate)
	filon("Filon_Cuivre", rgb(214, 124, 72), Mat.Metal)
	filon("Filon_Fer", rgb(222, 200, 180), Mat.Metal)
	filon("Filon_Or", rgb(250, 206, 60), Mat.Neon)
	do
		local m = nouveau("Argile")
		local c1, c2 = rgb(176, 108, 78), rgb(150, 92, 66)
		P(m, "Motte", Vector3.new(3.6, 1.2, 3), Vector3.new(0, 0.6, 0), c1, Mat.Mud, { rot = CFrame.Angles(0, 0.3, 0) })
		P(m, "Motte", Vector3.new(2.2, 1.6, 2), Vector3.new(0.9, 1, 0.5), c2, Mat.Mud, { rot = CFrame.Angles(0.15, 0.8, 0) })
		P(m, "Motte", Vector3.new(1.8, 1, 1.8), Vector3.new(-1.4, 0.5, -0.7), c2, Mat.Mud, { rot = CFrame.Angles(0, 0.5, 0.1) })
		fini(m)
	end
	do
		local m = nouveau("Fourneau")
		P(m, "Corps", Vector3.new(3.4, 3.4, 3), Vector3.new(0, 1.7, 0), PIERRE, Mat.Cobblestone)
		P(m, "Bouche", Vector3.new(1.6, 1.2, 0.2), Vector3.new(0, 1.1, 1.45), rgb(30, 22, 18), Mat.SmoothPlastic, { collide = false })
		local feu = P(m, "Braise", Vector3.new(1.3, 0.4, 0.2), Vector3.new(0, 0.7, 1.52), rgb(255, 120, 40), Mat.Neon, { collide = false })
		local light = Instance.new("PointLight")
		light.Range = 10
		light.Brightness = 1.5
		light.Color = rgb(255, 150, 70)
		light.Parent = feu
		P(m, "Cheminee", Vector3.new(1, 2, 1), Vector3.new(0.8, 4.4, -0.6), PIERRE_CLAIRE, Mat.Cobblestone)
		fini(m)
	end
	-- Construction : pivot au sol, au centre de la case ; un mur occupe le bord +Z... posé au bord de la case
	do
		local m = nouveau("Plancher")
		P(m, "Planches", Vector3.new(4, 0.4, 4), Vector3.new(0, 0.2, 0), BOIS_CLAIR, Mat.WoodPlanks)
		fini(m)
	end
	local function mur(nom: string, couleur: Color3, mat: Enum.Material, porte: boolean)
		local m = nouveau(nom)
		if porte then
			P(m, "Montant", Vector3.new(0.7, 7, 0.5), Vector3.new(-1.65, 3.5, 0), couleur, mat)
			P(m, "Montant", Vector3.new(0.7, 7, 0.5), Vector3.new(1.65, 3.5, 0), couleur, mat)
			P(m, "Linteau", Vector3.new(4, 1.4, 0.5), Vector3.new(0, 6.3, 0), couleur, mat)
		else
			P(m, "Mur", Vector3.new(4, 7, 0.5), Vector3.new(0, 3.5, 0), couleur, mat)
		end
		P(m, "Poteau", Vector3.new(0.6, 7.2, 0.6), Vector3.new(-2, 3.6, 0), BOIS_FONCE, Mat.Wood)
		P(m, "Poteau", Vector3.new(0.6, 7.2, 0.6), Vector3.new(2, 3.6, 0), BOIS_FONCE, Mat.Wood)
		fini(m)
	end
	mur("Mur_Planches", BOIS_CLAIR, Mat.WoodPlanks, false)
	mur("Mur_Porte", BOIS_CLAIR, Mat.WoodPlanks, true)
	mur("Mur_Pierre", PIERRE_CLAIRE, Mat.Cobblestone, false)
	mur("Mur_Briques", rgb(176, 92, 70), Mat.Brick, false)
	do
		local m = nouveau("Toit_Chaume")
		P(m, "Chaume", Vector3.new(4.6, 0.7, 4.6), Vector3.new(0, 7.45, 0), rgb(214, 182, 96), Mat.Grass)
		P(m, "Rive", Vector3.new(4.8, 0.25, 4.8), Vector3.new(0, 7.05, 0), BOIS_FONCE, Mat.Wood)
		fini(m)
	end
	do
		local m = nouveau("Lit_Joueur")
		P(m, "Cadre", Vector3.new(2.6, 0.9, 4.8), Vector3.new(0, 0.45, 0), BOIS, Mat.Wood)
		P(m, "Matelas", Vector3.new(2.3, 0.4, 4.4), Vector3.new(0, 1.1, 0), rgb(240, 236, 226), Mat.Fabric)
		P(m, "Couverture", Vector3.new(2.4, 0.3, 2.8), Vector3.new(0, 1.35, 0.8), rgb(180, 60, 60), Mat.Fabric)
		P(m, "Oreiller", Vector3.new(1.6, 0.4, 0.8), Vector3.new(0, 1.45, -1.7), rgb(250, 250, 245), Mat.Fabric)
		P(m, "Tete", Vector3.new(2.6, 1.8, 0.3), Vector3.new(0, 0.9, -2.35), BOIS_FONCE, Mat.Wood)
		fini(m)
	end
	do
		local m = nouveau("Lanterne")
		P(m, "Poteau", Vector3.new(0.35, 5, 0.35), Vector3.new(0, 2.5, 0), BOIS_FONCE, Mat.Wood)
		P(m, "Potence", Vector3.new(0.3, 0.3, 1.4), Vector3.new(0, 4.9, 0.55), BOIS_FONCE, Mat.Wood)
		P(m, "Cage", Vector3.new(0.9, 1, 0.9), Vector3.new(0, 4.2, 1.1), FER, Mat.Metal, { collide = false, transp = 0.2 })
		local l = P(m, "Flamme", Vector3.new(0.5, 0.6, 0.5), Vector3.new(0, 4.2, 1.1), rgb(200, 180, 140), Mat.SmoothPlastic, { collide = false })
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 1.6
		light.Color = rgb(255, 200, 120)
		light.Enabled = false
		light.Parent = l
		CollectionService:AddTag(l, "LumiereNuit")
		fini(m)
	end
end

-- Créatures du monde vivant (ennemis par biome, monstres de nuit, animaux sauvages).
-- Convention des bêtes : pièce « Base » au sol, tout ancré, sans collision, la tête vers -Z.
function M.creatures()
	dossier = dossierModeles()
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
	-- ---------------------------------------------------------------- Bipèdes (squelette, zombie, yéti, golem)
	type Bipede = { peau: Color3, haut: Color3, bas: Color3, echelle: number?, mat: Enum.Material?, brasDevant: boolean?, extra: ((Model, number) -> ())? }
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
			if o.brasDevant then
				Q(m, "Bras", Vector3.new(0.6, 0.6, 2) * e, Vector3.new(sx * 1.3, 3.6, -0.9) * e, o.peau, mat)
			else
				Q(m, "Bras", Vector3.new(0.6, 2, 0.6) * e, Vector3.new(sx * 1.3, 3, 0) * e, o.peau, mat)
			end
		end
		if o.extra then
			o.extra(m, e)
		end
		fini(m)
	end
	bipede("Squelette", {
		peau = rgb(232, 228, 214), haut = rgb(232, 228, 214), bas = rgb(232, 228, 214),
		extra = function(m, e)
			for i = 0, 2 do
				Q(m, "Cote", Vector3.new(2.05, 0.18, 1.05) * e, Vector3.new(0, 2.6 + i * 0.45, 0) * e, rgb(60, 56, 50))
			end
			Q(m, "Arc", Vector3.new(0.2, 2.6, 0.2) * e, Vector3.new(1.6, 3, -0.6) * e, rgb(120, 84, 52), Mat.Wood)
		end,
	})
	bipede("Zombie", { peau = rgb(110, 160, 100), haut = rgb(70, 110, 160), bas = rgb(80, 60, 50), brasDevant = true })
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

-- Trois silhouettes employ\u00e9es par le bestiaire, avec le pivot au niveau du sol ou de l\u2019eau.
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
		part(m, "T\u00eate du cheval", V(1.04, 0.87, 1.42), V(0, 4.12, -2.19), coat, Mat.SmoothPlastic)
		part(m, "Museau", V(0.86, 0.5, 0.68), V(0, 3.89, -2.79), mane, Mat.SmoothPlastic)
		part(m, "Crini\u00e8re", V(0.31, 1.61, 0.53), V(0, 3.54, -1.14), mane, Mat.SmoothPlastic)
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
		part(m, "M\u00e2choire", V(1.42, 0.53, 1.28), V(0, 0.63, -1.75), rgb(57, 131, 127), Mat.SmoothPlastic)
		part(m, "Nageoire dorsale", V(0.18, 1.04, 1.5), V(0, 2.0, 0.1), rgb(34, 80, 94), Mat.SmoothPlastic, { forme = "Wedge" })
		for _, x in { -1, 1 } do
			part(m, "Nageoire pectorale", V(1.06, 0.15, 0.86), V(x, 0.67, 0.25), back, Mat.SmoothPlastic, { forme = "Wedge", rot = CFrame.Angles(0, x * 0.35, 0) })
			part(m, "\u0152il", V(0.16, 0.32, 0.32), V(x * 0.83, 1.37, -1.28), rgb(247, 190, 86), Mat.SmoothPlastic, { forme = "Ball" })
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
			part(m, "Cr\u00eate", V(0.23, extent * 0.43, 0.65), V(x, y + extent * 0.54, z + 0.11), crest, Mat.SmoothPlastic, { forme = "Wedge" })
		end
		part(m, "Cr\u00e2ne", V(1.64, 1.35, 1.75), V(0, 1.63, -2.6), back, Mat.SmoothPlastic)
		part(m, "Mufle", V(1.23, 0.51, 1.15), V(0, 1.30, -3.40), rgb(123, 168, 140), Mat.SmoothPlastic)
		for _, x in { -1, 1 } do
			part(m, "\u0152il", V(0.15, 0.3, 0.33), V(x * 0.81, 1.92, -2.69), rgb(244, 184, 79), Mat.SmoothPlastic, { forme = "Ball" })
			part(m, "Cr\u00eate lat\u00e9rale", V(0.24, 0.69, 0.73), V(x * 0.81, 2.22, -2.33), crest, Mat.SmoothPlastic,
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
	do
		-- porte : se pose sur un bord de case, dans l'ouverture d'un « mur avec porte »
		local m = nouveau("Porte")
		P(m, "Battant", Vector3.new(2.5, 5.5, 0.3), Vector3.new(0, 2.75, 0), BOIS, Mat.WoodPlanks)
		P(m, "Traverse", Vector3.new(2.5, 0.3, 0.36), Vector3.new(0, 1.4, 0), BOIS_FONCE, Mat.Wood, { collide = false })
		P(m, "Traverse", Vector3.new(2.5, 0.3, 0.36), Vector3.new(0, 4.2, 0), BOIS_FONCE, Mat.Wood, { collide = false })
		P(m, "Poignee", Vector3.new(0.2, 0.2, 0.5), Vector3.new(0.9, 2.8, 0), FER, Mat.Metal, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Cloche_Alarme")
		P(m, "Poteau", Vector3.new(0.4, 5.5, 0.4), Vector3.new(0, 2.75, 0), BOIS_FONCE, Mat.Wood)
		P(m, "Potence", Vector3.new(0.3, 0.3, 1.6), Vector3.new(0, 5.4, 0.6), BOIS_FONCE, Mat.Wood, { collide = false })
		P(m, "Cloche", Vector3.new(1.1, 1.2, 1.1), Vector3.new(0, 4.6, 1.2), OR, Mat.Metal, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)), collide = false })
		P(m, "Battant", Vector3.new(0.25, 0.5, 0.25), Vector3.new(0, 3.9, 1.2), FER, Mat.Metal, { collide = false })
		fini(m)
	end
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
	-- pièces de construction et mobilier
	do
		local m = nouveau("Mur_Fenetre")
		P(m, "Bas", Vector3.new(4, 2.6, 0.5), Vector3.new(0, 1.3, 0), BOIS_CLAIR, Mat.WoodPlanks)
		P(m, "Haut", Vector3.new(4, 1.8, 0.5), Vector3.new(0, 6.1, 0), BOIS_CLAIR, Mat.WoodPlanks)
		for _, sx in { -1, 1 } do
			P(m, "Cote", Vector3.new(0.9, 2.6, 0.5), Vector3.new(sx * 1.55, 3.9, 0), BOIS_CLAIR, Mat.WoodPlanks)
			P(m, "Poteau", Vector3.new(0.6, 7.2, 0.6), Vector3.new(sx * 2, 3.6, 0), BOIS_FONCE, Mat.Wood)
		end
		P(m, "Vitre", Vector3.new(2.2, 2.6, 0.1), Vector3.new(0, 3.9, 0), rgb(190, 225, 240), Mat.Glass, { transp = 0.5 })
		P(m, "Croisillon", Vector3.new(0.15, 2.6, 0.2), Vector3.new(0, 3.9, 0), BOIS_FONCE, Mat.Wood, { collide = false })
		fini(m)
	end
	do
		-- escalier : monte d'un étage (7,4 studs) sur une case, marches de 0,9
		local m = nouveau("Escalier_Bois")
		for i = 0, 7 do
			P(m, "Marche", Vector3.new(3.6, 0.9, 0.5), Vector3.new(0, 0.45 + i * 0.92, 1.75 - i * 0.5), BOIS_CLAIR, Mat.WoodPlanks)
		end
		P(m, "Limon", Vector3.new(0.3, 0.6, 5), Vector3.new(-1.85, 3.6, 0), BOIS_FONCE, Mat.Wood, { collide = false, rot = CFrame.Angles(math.rad(58), 0, 0) })
		fini(m)
	end
	do
		local m = nouveau("Table_Bois")
		P(m, "Plateau", Vector3.new(3.4, 0.3, 2.2), Vector3.new(0, 2.6, 0), BOIS_CLAIR, Mat.WoodPlanks)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				P(m, "Pied", Vector3.new(0.3, 2.45, 0.3), Vector3.new(sx * 1.45, 1.22, sz * 0.85), BOIS, Mat.Wood)
			end
		end
		fini(m)
	end
	do
		local m = nouveau("Chaise")
		P(m, "Assise", Vector3.new(1.6, 0.25, 1.6), Vector3.new(0, 1.6, 0), BOIS_CLAIR, Mat.WoodPlanks)
		P(m, "Dossier", Vector3.new(1.6, 1.8, 0.2), Vector3.new(0, 2.6, 0.7), BOIS_CLAIR, Mat.WoodPlanks)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				P(m, "Pied", Vector3.new(0.2, 1.5, 0.2), Vector3.new(sx * 0.65, 0.75, sz * 0.65), BOIS, Mat.Wood)
			end
		end
		fini(m)
	end
	do
		local m = nouveau("Tapis")
		P(m, "Tapis", Vector3.new(3.6, 0.1, 3.6), Vector3.new(0, 0.05, 0), rgb(170, 50, 50), Mat.Fabric, { collide = false })
		P(m, "Motif", Vector3.new(2.4, 0.11, 2.4), Vector3.new(0, 0.06, 0), rgb(230, 190, 90), Mat.Fabric, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Pot_Fleurs")
		P(m, "Pot", Vector3.new(1.2, 1, 1.2), Vector3.new(0, 0.5, 0), rgb(180, 100, 70), Mat.SmoothPlastic)
		P(m, "Terre", Vector3.new(1, 0.1, 1), Vector3.new(0, 1.0, 0), rgb(80, 56, 36), Mat.Ground, { collide = false })
		for i, c in { rgb(240, 120, 160), rgb(250, 220, 80), rgb(150, 120, 230) } do
			P(m, "Fleur", Vector3.new(0.4, 0.4, 0.4), Vector3.new(-0.3 + i * 0.2, 1.5 + (i % 2) * 0.2, (i % 2) * 0.2 - 0.1), c, Mat.SmoothPlastic, { collide = false })
			P(m, "Tige", Vector3.new(0.1, 0.5, 0.1), Vector3.new(-0.3 + i * 0.2, 1.2, (i % 2) * 0.2 - 0.1), rgb(70, 140, 60), Mat.SmoothPlastic, { collide = false })
		end
		fini(m)
	end
	do
		local m = nouveau("Etagere")
		P(m, "Fond", Vector3.new(3, 4.4, 0.2), Vector3.new(0, 2.2, 0.6), BOIS, Mat.WoodPlanks)
		for i = 0, 3 do
			P(m, "Planche", Vector3.new(3, 0.2, 1.2), Vector3.new(0, 0.3 + i * 1.3, 0.1), BOIS_CLAIR, Mat.WoodPlanks)
		end
		for i = 0, 5 do
			P(m, "Livre", Vector3.new(0.3, 0.9, 0.8), Vector3.new(-1.2 + i * 0.45, 2.1, 0.1), ({ rgb(160, 50, 50), rgb(50, 90, 150), rgb(60, 120, 60) })[i % 3 + 1], Mat.SmoothPlastic, { collide = false })
		end
		fini(m)
	end
	do
		local m = nouveau("Banc")
		P(m, "Assise", Vector3.new(4, 0.3, 1.2), Vector3.new(0, 1.5, 0), BOIS_CLAIR, Mat.WoodPlanks)
		for _, sx in { -1, 1 } do
			P(m, "Pied", Vector3.new(0.4, 1.4, 1), Vector3.new(sx * 1.6, 0.7, 0), BOIS, Mat.Wood)
		end
		fini(m)
	end
	-- inventions
	do
		local m = nouveau("Moulin")
		P(m, "Tour", Vector3.new(5, 10, 5), Vector3.new(0, 5, 0), PIERRE_CLAIRE, Mat.Cobblestone)
		P(m, "Toit", Vector3.new(5.6, 2, 5.6), Vector3.new(0, 11, 0), rgb(120, 60, 50), Mat.WoodPlanks)
		P(m, "Axe", Vector3.new(0.6, 0.6, 1.4), Vector3.new(0, 8.5, -3.1), BOIS_FONCE, Mat.Wood)
		for i = 0, 3 do
			local a = i * math.pi / 2 + math.pi / 4
			P(m, "Aile", Vector3.new(1.2, 5.5, 0.15), Vector3.new(math.cos(a) * 2.6, 8.5 + math.sin(a) * 2.6, -3.8), rgb(240, 232, 214), Mat.Fabric,
				{ collide = false, rot = CFrame.Angles(0, 0, a - math.pi / 2) })
		end
		P(m, "Porte", Vector3.new(1.6, 2.6, 0.2), Vector3.new(0, 1.3, -2.55), BOIS, Mat.WoodPlanks, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Arroseur")
		P(m, "Pied", Vector3.new(0.4, 1.6, 0.4), Vector3.new(0, 0.8, 0), FER, Mat.Metal)
		P(m, "Reservoir", Vector3.new(1.4, 1, 1.4), Vector3.new(0, 0.5, 0.9), rgb(120, 90, 60), Mat.Wood)
		P(m, "Tete", Vector3.new(1.2, 0.3, 0.3), Vector3.new(0, 1.7, 0), rgb(200, 130, 70), Mat.Metal, { collide = false })
		P(m, "Buse", Vector3.new(0.3, 0.3, 1.2), Vector3.new(0, 1.7, 0), rgb(200, 130, 70), Mat.Metal, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Ruche")
		P(m, "Socle", Vector3.new(1.8, 0.6, 1.8), Vector3.new(0, 0.3, 0), BOIS, Mat.Wood)
		for i = 0, 3 do
			local w = 1.8 - i * 0.35
			P(m, "Paille", Vector3.new(w, 0.5, w), Vector3.new(0, 0.85 + i * 0.45, 0), rgb(214, 182, 96), Mat.Grass)
		end
		P(m, "Trou", Vector3.new(0.4, 0.3, 0.1), Vector3.new(0, 0.9, -0.85), rgb(40, 30, 20), Mat.SmoothPlastic, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Caserne")
		P(m, "Socle", Vector3.new(12, 1, 10), Vector3.new(0, 0.5, 0), PIERRE, Mat.Cobblestone)
		P(m, "Murs", Vector3.new(11, 6, 9), Vector3.new(0, 4, 0), PIERRE_CLAIRE, Mat.Cobblestone)
		P(m, "Porte", Vector3.new(2.6, 4, 0.3), Vector3.new(0, 3, -4.6), BOIS_FONCE, Mat.WoodPlanks)
		P(m, "Toit", Vector3.new(12, 1, 10), Vector3.new(0, 7.5, 0), rgb(120, 60, 50), Mat.WoodPlanks)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				P(m, "Tour", Vector3.new(2, 9, 2), Vector3.new(sx * 5.5, 4.5, sz * 4.5), PIERRE, Mat.Cobblestone)
			end
		end
		P(m, "Mat", Vector3.new(0.3, 5, 0.3), Vector3.new(0, 10.5, 0), BOIS_FONCE, Mat.Wood)
		P(m, "Drapeau", Vector3.new(0.1, 1.6, 2.4), Vector3.new(0, 12, 1.2), rgb(190, 40, 40), Mat.Fabric, { collide = false })
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
	do
		-- embarcadère : ponton, barque, panneau
		local m = nouveau("Embarcadere")
		P(m, "Ponton", Vector3.new(4, 0.4, 10), Vector3.new(0, 0.6, 0), BOIS_CLAIR, Mat.WoodPlanks)
		for _, sx in { -1, 1 } do
			for _, sz in { -4, 0, 4 } do
				P(m, "Pieu", Vector3.new(0.5, 2, 0.5), Vector3.new(sx * 1.8, 0, sz), BOIS_FONCE, Mat.Wood)
			end
		end
		P(m, "Coque", Vector3.new(2.6, 1.2, 6), Vector3.new(3.6, 0.6, 0), rgb(120, 76, 44), Mat.Wood)
		P(m, "Interieur", Vector3.new(2, 0.3, 5), Vector3.new(3.6, 1.1, 0), rgb(90, 58, 34), Mat.WoodPlanks, { collide = false })
		P(m, "Mat", Vector3.new(0.3, 5, 0.3), Vector3.new(3.6, 3.5, 0), BOIS_FONCE, Mat.Wood)
		P(m, "Voile", Vector3.new(0.1, 3.4, 2.8), Vector3.new(3.6, 4, 0.2), rgb(240, 232, 214), Mat.Fabric, { collide = false })
		P(m, "Panneau", Vector3.new(2.2, 1.2, 0.2), Vector3.new(0, 2.6, -4.6), BOIS, Mat.WoodPlanks)
		P(m, "PiedPanneau", Vector3.new(0.3, 2.2, 0.3), Vector3.new(0, 1.3, -4.6), BOIS_FONCE, Mat.Wood)
		fini(m)
	end
	do
		local m = nouveau("Etal")
		P(m, "Comptoir", Vector3.new(4.4, 2.6, 2), Vector3.new(0, 1.3, 0), BOIS_CLAIR, Mat.WoodPlanks)
		for _, sx in { -1, 1 } do
			P(m, "Montant", Vector3.new(0.3, 5.6, 0.3), Vector3.new(sx * 2.1, 2.8, 0.8), BOIS_FONCE, Mat.Wood)
		end
		for i = 0, 5 do
			P(m, "Auvent", Vector3.new(0.75, 0.2, 2.6), Vector3.new(-1.9 + i * 0.75, 5.6, 0.3), (i % 2 == 0) and rgb(200, 60, 60) or rgb(245, 240, 230), Mat.Fabric, { collide = false, rot = CFrame.Angles(math.rad(-12), 0, 0) })
		end
		P(m, "Caisse", Vector3.new(0.9, 0.6, 0.6), Vector3.new(1.4, 2.9, 0.3), OR, Mat.Metal, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Serrure_Entrainement")
		P(m, "Pied", Vector3.new(1.6, 2.6, 1.2), Vector3.new(0, 1.3, 0), BOIS, Mat.Wood)
		P(m, "Plaque", Vector3.new(1.4, 1.4, 0.2), Vector3.new(0, 2.2, -0.7), FER, Mat.Metal, { collide = false })
		P(m, "Trou", Vector3.new(0.25, 0.5, 0.1), Vector3.new(0, 2.1, -0.82), rgb(20, 20, 20), Mat.SmoothPlastic, { collide = false })
		fini(m)
	end
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

local function sol()
	do
		local m = nouveau("Rocher")
		P(m, "Pierre", Vector3.new(4, 3, 3.4), Vector3.new(0, 1.3, 0), PIERRE, Mat.Slate, { rot = CFrame.Angles(0, math.rad(12), math.rad(6)) })
		P(m, "Pierre", Vector3.new(2.6, 2.2, 2.6), Vector3.new(1.6, 1.2, 1.2), PIERRE_CLAIRE, Mat.Slate, { rot = CFrame.Angles(math.rad(8), math.rad(35), 0) })
		P(m, "Pierre", Vector3.new(1.6, 1.4, 1.6), Vector3.new(-1.8, 0.6, 1.2), PIERRE, Mat.Slate, { rot = CFrame.Angles(0, math.rad(20), math.rad(-10)) })
		P(m, "Mousse", Vector3.new(2.4, 0.3, 1.8), Vector3.new(-0.3, 2.85, -0.2), rgb(96, 140, 70), Mat.Grass, { rot = CFrame.Angles(0, math.rad(12), math.rad(6)), collide = false })
		fini(m)
	end
	do
		local m = nouveau("Caillou")
		P(m, "Pierre", Vector3.new(1.1, 0.6, 0.9), Vector3.new(0, 0.3, 0), PIERRE_CLAIRE, Mat.Slate, { rot = CFrame.Angles(0, math.rad(25), 0), collide = false })
		P(m, "Pierre", Vector3.new(0.6, 0.4, 0.6), Vector3.new(0.7, 0.2, 0.4), PIERRE, Mat.Slate, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Branche")
		P(m, "Bois", Vector3.new(2.6, 0.32, 0.32), Vector3.new(0, 0.16, 0), BOIS, Mat.Wood, { rot = CFrame.Angles(0, math.rad(20), 0), collide = false })
		P(m, "Bois", Vector3.new(1, 0.24, 0.24), Vector3.new(0.4, 0.14, 0.45), BOIS, Mat.Wood, { rot = CFrame.Angles(0, math.rad(-35), 0), collide = false })
		fini(m)
	end
	do
		local m = nouveau("Buisson")
		local v1, v2 = rgb(70, 132, 58), rgb(84, 148, 66)
		P(m, "Feuilles", Vector3.new(3.2, 2.4, 3), Vector3.new(0, 1.2, 0), v1, Mat.Grass)
		P(m, "Feuilles", Vector3.new(2.2, 1.8, 2.2), Vector3.new(0.9, 2.3, 0.3), v2, Mat.Grass, { collide = false })
		P(m, "Feuilles", Vector3.new(1.8, 1.6, 1.8), Vector3.new(-0.9, 2.1, -0.4), v2, Mat.Grass, { collide = false })
		local baies = { Vector3.new(1.62, 1.4, 0.6), Vector3.new(1.62, 0.8, -0.8), Vector3.new(-0.5, 1.7, 1.52), Vector3.new(0.7, 1, 1.52), Vector3.new(-1.62, 1.1, 0.2), Vector3.new(0.3, 2.9, 1.42), Vector3.new(-0.6, 0.9, -1.52) }
		for _, b in baies do
			P(m, "Baie", Vector3.new(0.5, 0.5, 0.5), b, rgb(196, 40, 60), Mat.SmoothPlastic, { collide = false })
		end
		fini(m)
	end
	do
		local m = nouveau("Tronc_Couche")
		P(m, "Bois", Vector3.new(5, 1.7, 1.7), Vector3.new(0, 0.85, 0), BOIS, Mat.Wood, { forme = "Cylinder" })
		P(m, "Coupe", Vector3.new(0.1, 1.5, 1.5), Vector3.new(2.52, 0.85, 0), BOIS_CLAIR, Mat.Wood, { forme = "Cylinder", collide = false })
		P(m, "Coupe", Vector3.new(0.1, 1.5, 1.5), Vector3.new(-2.52, 0.85, 0), BOIS_CLAIR, Mat.Wood, { forme = "Cylinder", collide = false })
		P(m, "Mousse", Vector3.new(2, 0.2, 1), Vector3.new(0.5, 1.7, 0), rgb(96, 140, 70), Mat.Grass, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Fleurs")
		local pos = { Vector3.new(0, 0, 0), Vector3.new(0.7, 0, 0.4), Vector3.new(-0.5, 0, 0.6), Vector3.new(0.2, 0, -0.7) }
		for i, p in pos do
			local h = 0.7 + (i % 2) * 0.3
			P(m, "Tige", Vector3.new(0.12, h, 0.12), p + Vector3.new(0, h / 2, 0), rgb(70, 140, 60), Mat.SmoothPlastic, { collide = false })
			P(m, "Petale", Vector3.new(0.45, 0.3, 0.45), p + Vector3.new(0, h + 0.1, 0), rgb(240, 220, 80), Mat.SmoothPlastic, { collide = false })
		end
		fini(m)
	end
	do
		local m = nouveau("Champignon")
		P(m, "Pied", Vector3.new(0.4, 0.6, 0.4), Vector3.new(0, 0.3, 0), rgb(240, 232, 214), Mat.SmoothPlastic, { collide = false })
		P(m, "Chapeau", Vector3.new(1, 0.45, 1), Vector3.new(0, 0.75, 0), rgb(200, 50, 46), Mat.SmoothPlastic, { collide = false })
		P(m, "Point", Vector3.new(0.2, 0.06, 0.2), Vector3.new(0.2, 1.0, 0.15), rgb(255, 255, 255), Mat.SmoothPlastic, { collide = false })
		P(m, "Point", Vector3.new(0.16, 0.06, 0.16), Vector3.new(-0.22, 1.0, -0.12), rgb(255, 255, 255), Mat.SmoothPlastic, { collide = false })
		P(m, "Pied", Vector3.new(0.3, 0.4, 0.3), Vector3.new(0.6, 0.2, 0.3), rgb(240, 232, 214), Mat.SmoothPlastic, { collide = false })
		P(m, "Chapeau", Vector3.new(0.7, 0.3, 0.7), Vector3.new(0.6, 0.5, 0.3), rgb(200, 50, 46), Mat.SmoothPlastic, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Touffe")
		for i = 1, 5 do
			local a = i * 1.3
			P(m, "Brin", Vector3.new(0.16, 0.9 + (i % 3) * 0.25, 0.16), Vector3.new(math.cos(a) * 0.35, 0.5, math.sin(a) * 0.35), rgb(96, 160, 70), Mat.Grass,
				{ rot = CFrame.Angles(math.cos(a) * 0.3, 0, math.sin(a) * 0.3), collide = false })
		end
		fini(m)
	end
	do
		local m = nouveau("Coffre")
		P(m, "Caisse", Vector3.new(3, 1.8, 2), Vector3.new(0, 0.9, 0), BOIS, Mat.WoodPlanks)
		P(m, "Couvercle", Vector3.new(3.1, 0.7, 2.1), Vector3.new(0, 2.15, 0), BOIS_CLAIR, Mat.WoodPlanks)
		P(m, "Cerclage", Vector3.new(0.3, 2.6, 2.14), Vector3.new(-1.1, 1.25, 0), OR, Mat.Metal, { collide = false })
		P(m, "Cerclage", Vector3.new(0.3, 2.6, 2.14), Vector3.new(1.1, 1.25, 0), OR, Mat.Metal, { collide = false })
		P(m, "Serrure", Vector3.new(0.5, 0.6, 0.15), Vector3.new(0, 1.7, 1.08), OR, Mat.Metal, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Sol_Laboure")
		P(m, "Terre", Vector3.new(3.8, 0.4, 3.8), Vector3.new(0, 0.1, 0), rgb(110, 76, 50), Mat.Ground, { collide = false })
		for i = -1, 1 do
			P(m, "Sillon", Vector3.new(3.6, 0.15, 0.5), Vector3.new(0, 0.33, i * 1.15), rgb(92, 62, 40), Mat.Ground, { collide = false })
		end
		fini(m)
	end
	do
		local m = nouveau("Terre_Retournee") -- tombe discrète / trou rebouché
		P(m, "Terre", Vector3.new(3, 0.5, 5), Vector3.new(0, 0.15, 0), rgb(104, 72, 48), Mat.Ground, { collide = false })
		fini(m)
	end
end

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
	for i = 1, 4 do
		P(m, "Bocal", Vector3.new(0.6, 0.8, 0.6), Vector3.zero, couleurs[i], Mat.SmoothPlastic, { cf = cf * CFrame.new(-1.5 + (i - 1) * 1, 3.05, 0), collide = false })
		P(m, "Bocal", Vector3.new(0.6, 0.7, 0.6), Vector3.zero, couleurs[5 - i], Mat.SmoothPlastic, { cf = cf * CFrame.new(-1.5 + (i - 1) * 1, 4.8, 0), collide = false })
	end
end

local function tapis(m: Model, pos: Vector3, c: Color3)
	P(m, "Tapis", Vector3.new(5, 0.1, 3.4), pos + Vector3.new(0, 0.05, 0), c, Mat.Fabric, { collide = false })
end

local function lampe_interieure(base: BasePart, m: Model, pos: Vector3)
	local l = P(m, "Lanterne", Vector3.new(0.7, 0.9, 0.7), pos, rgb(255, 214, 120), Mat.Neon, { collide = false })
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.4
	light.Color = rgb(255, 200, 130)
	light.Shadows = true
	light.Parent = l
	CollectionService:AddTag(l, "LumiereNuit")
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
			for k = -1, 1 do
				local c = FLEURS[(nFleur + k + 3) % #FLEURS + 1]
				P(m, "Fleur", Vector3.new(0.7, 0.7, 0.7), Vector3.zero, c, Mat.SmoothPlastic,
					{ cf = cf * CFrame.new(k * 0.85, -fh / 2 - 0.2, 0.95), collide = false, forme = "Ball" })
			end
		end
		P(m, "Croisillon", Vector3.new(0.15, fh, 0.3), Vector3.zero, rgb(40, 40, 44), Mat.Metal, { cf = cf * CFrame.new(0, 0, 0.5), collide = false })
		P(m, "Croisillon", Vector3.new(fw, 0.15, 0.3), Vector3.zero, rgb(40, 40, 44), Mat.Metal, { cf = cf * CFrame.new(0, 0, 0.5), collide = false })
		P(m, "Appui", Vector3.new(fw + 0.8, 0.35, 0.7), Vector3.zero, PIERRE, Mat.Cobblestone, { cf = cf * CFrame.new(0, -fh / 2 - 0.2, 0.55), collide = false })
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
		local z = 0.48
		local bas, haut = sansPierre and 0.3 or 2.6, hMur - 0.35
		-- soubassement de pierre
		for _, seg in sansPierre and {} or morceaux(bas / 2) do
			if seg[2] - seg[1] > 0.2 then
				P(m, "Soubassement", Vector3.new(seg[2] - seg[1], bas, 0.35), Vector3.zero, PIERRE, Mat.Cobblestone,
					{ cf = cf * CFrame.new((seg[1] + seg[2]) / 2, bas / 2, z - 0.05) })
			end
		end
		-- sablières (horizontales)
		for _, y in { bas, hMur * 0.58, haut } do
			for _, pc in morceaux(y) do
				if pc[2] - pc[1] > 0.2 then
					P(m, "Colombage", Vector3.new(pc[2] - pc[1], 0.45, 0.3), Vector3.zero, poutre, Mat.Wood,
						{ cf = cf * CFrame.new((pc[1] + pc[2]) / 2, y, z), collide = false })
				end
			end
		end
		-- poteaux et croix de Saint-André dans la moitié haute
		local n = math.max(2, math.floor(long / 3.4))
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
		for i = 0, math.floor(W / 2.6) do
			local x = -W / 2 + 0.5 + i * ((W - 1) / math.floor(W / 2.6))
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
			P(m, "Toit", Vector3.new(larg * 0.45, toit.epais, long * 0.8), Vector3.zero, o.toit, toit.mat, { cf = cf * CFrame.new(-larg * 0.27, 0, long * 0.1) })
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

local function maisons()
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
		lampe_interieure(base, m, Vector3.new(0, 9.4, 0))
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
		lampe_interieure(base, m, Vector3.new(0, 10.4, 0))
		attache(base, "Travail", CFrame.new(0, 1, -5.5))
		-- Enseigne
		local ens = P(m, "Enseigne", Vector3.new(6, 1.6, 0.3), Vector3.new(0, 10.2, 9.35), BOIS_CLAIR, Mat.WoodPlanks, { collide = false })
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
		for i = 0, 6 do
			P(m, "Barreau", Vector3.new(0.3, 9, 0.3), Vector3.new(-10 + i * 1.3, 5.3, -1.5), FER, Mat.Metal)
		end
		for i = 0, 3 do
			P(m, "Barreau", Vector3.new(0.3, 9, 0.3), Vector3.new(-2.2, 5.3, -1.5 - i * 1.6), FER, Mat.Metal)
		end
		P(m, "Barre", Vector3.new(8.6, 0.4, 0.4), Vector3.new(-6.1, 9.6, -1.5), FER, Mat.Metal)
		P(m, "Paillasse", Vector3.new(3, 0.5, 5), Vector3.new(-7.5, 1.15, -5.5), rgb(214, 186, 100), Mat.Grass, { collide = false })
		attache(base, "Cellule", CFrame.new(-5.5, 1, -4.5))
		lit(m, base, Vector3.new(7.5, 1, 4), rgb(120, 90, 60))
		lampe_interieure(base, m, Vector3.new(0, 9.4, 2))
		attache(base, "Travail", CFrame.new(4, 1, -4.4))
		local ens = P(m, "Enseigne", Vector3.new(6, 1.6, 0.3), Vector3.new(-3, 10.2, 9.35), BOIS_CLAIR, Mat.WoodPlanks, { collide = false })
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
	-- Enseigne pendue (planche sous une potence) avec un mot en écriture médiévale
	local function enseigne(m: Model, pos: Vector3, mot: string)
		P(m, "Potence", Vector3.new(0.4, 0.4, 2.6), pos + Vector3.new(0, 1.2, 1.1), BOIS_FONCE, Mat.Wood, { collide = false })
		local ens = P(m, "Enseigne", Vector3.new(4.4, 1.6, 0.25), pos + Vector3.new(0, 0, 2.2), BOIS_CLAIR, Mat.WoodPlanks, { collide = false })
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
				P(m, "Banc", Vector3.new(1, 0.4, 7.6), Vector3.new(x + s * 2.2, 2, 2), BOIS, Mat.WoodPlanks)
			end
			P(m, "Chope", Vector3.new(0.5, 0.7, 0.5), Vector3.new(x, 3.6, 1), rgb(150, 110, 70), Mat.Wood, { collide = false })
		end
		lampe_interieure(base, m, Vector3.new(-4, 10.4, 0))
		lampe_interieure(base, m, Vector3.new(6, 10.4, 2))
		attache(base, "Travail", CFrame.new(-6, 1, -4))
		enseigne(m, Vector3.new(7, 9.4, 10.2), "Taverne")
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
		enseigne(m, Vector3.new(-8, 8, 7.2), "Forge")
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
			local c = P(m, "Cierge", Vector3.new(0.3, 1.2, 0.3), Vector3.new(x, 4.6, -11), rgb(245, 240, 225), Mat.SmoothPlastic, { collide = false })
			local fl = Instance.new("PointLight")
			fl.Color = rgb(255, 200, 120)
			fl.Range = 8
			fl.Parent = c
		end
		attache(base, "Travail", CFrame.new(0, 1, -8))
		fini(m)
	end
	-- Marché : trois étals à auvent rayé, caisses de légumes
	do
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
		P(m, "Lierre", Vector3.new(0.2, 5, 4), Vector3.new(-10.5, 4, 2), rgb(70, 120, 60), Mat.Grass, { collide = false })
		attache(base, "CoffreSpot", CFrame.new(2, 1, -5.5))
		attache(base, "Travail", CFrame.new(0, 1, 0))
		fini(m)
	end
end

-- ---------------------------------------------------------------- Décor de village et de ferme

-- Potence à lanterne (Lampadaire des villages)
local function lampadaire()
	-- potence à lanterne (image cible) : gros poteau équarri, bras et jambe de force, lanterne
	-- de fer à vitres chaudes suspendue par une chaîne ; pied de pierre
	local m = nouveau("Lampadaire")
	P(m, "Pied", Vector3.new(2.2, 1, 2.2), Vector3.new(0, 0.5, 0), PIERRE, Mat.Cobblestone)
	P(m, "Poteau", Vector3.new(1, 11, 1), Vector3.new(0, 6, 0), BOIS, Mat.Wood)
	P(m, "Cap", Vector3.new(1.3, 0.5, 1.3), Vector3.new(0, 11.6, 0), BOIS_FONCE, Mat.Wood, { collide = false })
	P(m, "Bras", Vector3.new(0.8, 0.8, 4.4), Vector3.new(0, 11, 1.9), BOIS, Mat.Wood, { collide = false })
	P(m, "JambeDeForce", Vector3.new(0.5, 0.5, 2.8), Vector3.zero, BOIS_FONCE, Mat.Wood,
		{ cf = CFrame.new(0, 9.8, 1.05) * CFrame.Angles(math.rad(-45), 0, 0), collide = false })
	P(m, "Chaine", Vector3.new(0.15, 1, 0.15), Vector3.new(0, 10.1, 3.6), FER, Mat.Metal, { collide = false })
	P(m, "Chapeau", Vector3.new(1.6, 0.35, 1.6), Vector3.new(0, 9.5, 3.6), FER, Mat.Metal, { collide = false })
	P(m, "Pointe", Vector3.new(0.9, 0.35, 0.9), Vector3.new(0, 9.8, 3.6), FER, Mat.Metal, { collide = false })
	local l = P(m, "Lanterne", Vector3.new(1.1, 1.5, 1.1), Vector3.new(0, 8.5, 3.6), rgb(255, 214, 120), Mat.Neon, { collide = false })
	for _, c in { { -0.6, -0.6 }, { 0.6, -0.6 }, { -0.6, 0.6 }, { 0.6, 0.6 } } do
		P(m, "Montant", Vector3.new(0.18, 1.6, 0.18), Vector3.new(c[1], 8.5, 3.6 + c[2]), FER, Mat.Metal, { collide = false })
	end
	P(m, "Fond", Vector3.new(1.4, 0.25, 1.4), Vector3.new(0, 7.65, 3.6), FER, Mat.Metal, { collide = false })
	local light = Instance.new("PointLight")
	light.Range = 28
	light.Brightness = 1.7
	light.Color = rgb(255, 200, 130)
	light.Shadows = true
	light.Parent = l
	CollectionService:AddTag(l, "LumiereNuit")
	fini(m)
end

local function decor()
	do
		local m = nouveau("Fontaine")
		P(m, "Bassin", Vector3.new(8, 1.6, 8), Vector3.new(0, 0.8, 0), PIERRE_CLAIRE, Mat.Cobblestone)
		P(m, "Eau", Vector3.new(6.8, 0.3, 6.8), Vector3.new(0, 1.5, 0), rgb(86, 160, 214), Mat.Glass, { collide = false, transp = 0.2 })
		P(m, "Colonne", Vector3.new(1.4, 4, 1.4), Vector3.new(0, 3, 0), PIERRE, Mat.Cobblestone)
		P(m, "Vasque", Vector3.new(3.4, 0.8, 3.4), Vector3.new(0, 5.2, 0), PIERRE_CLAIRE, Mat.Cobblestone)
		P(m, "EauHaut", Vector3.new(2.8, 0.2, 2.8), Vector3.new(0, 5.65, 0), rgb(86, 160, 214), Mat.Glass, { collide = false, transp = 0.2 })
		local jet = P(m, "Jet", Vector3.new(0.4, 0.4, 0.4), Vector3.new(0, 6, 0), rgb(200, 230, 255), Mat.SmoothPlastic, { collide = false, transp = 1 })
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(rgb(200, 230, 255))
		pe.Size = NumberSequence.new(0.35, 0.1)
		pe.Transparency = NumberSequence.new(0.2, 0.8)
		pe.Speed = NumberRange.new(5, 7)
		pe.SpreadAngle = Vector2.new(18, 18)
		pe.Acceleration = Vector3.new(0, -24, 0)
		pe.Lifetime = NumberRange.new(0.5, 0.7)
		pe.Rate = 40
		pe.Parent = jet
		fini(m)
	end
	do
		local m = nouveau("Puits")
		P(m, "Margelle", Vector3.new(4.6, 2.4, 4.6), Vector3.new(0, 1.2, 0), PIERRE, Mat.Cobblestone, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)) })
		P(m, "Eau", Vector3.new(0.2, 3.6, 3.6), Vector3.new(0, 2, 0), rgb(40, 80, 120), Mat.Glass, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)), collide = false })
		P(m, "Poteau", Vector3.new(0.5, 6, 0.5), Vector3.new(-2, 3.4, 0), BOIS, Mat.Wood)
		P(m, "Poteau", Vector3.new(0.5, 6, 0.5), Vector3.new(2, 3.4, 0), BOIS, Mat.Wood)
		P(m, "Toit", Vector3.new(5.6, 0.5, 3.2), Vector3.zero, rgb(150, 70, 50), Mat.WoodPlanks, { cf = CFrame.new(0, 6.6, 1) * CFrame.Angles(math.rad(-30), 0, 0) })
		P(m, "Toit", Vector3.new(5.6, 0.5, 3.2), Vector3.zero, rgb(150, 70, 50), Mat.WoodPlanks, { cf = CFrame.new(0, 6.6, -1) * CFrame.Angles(math.rad(30), 0, 0) })
		P(m, "Treuil", Vector3.new(4, 0.5, 0.5), Vector3.new(0, 5, 0), BOIS_FONCE, Mat.Wood, { forme = "Cylinder" })
		P(m, "Seau", Vector3.new(0.9, 0.9, 0.9), Vector3.new(0, 3.6, 0), BOIS_CLAIR, Mat.WoodPlanks, { collide = false })
		fini(m)
	end
	do
		lampadaire()
	end
	do
		local m = nouveau("Panneau")
		P(m, "Poteau", Vector3.new(0.4, 5, 0.4), Vector3.new(-2.4, 2.5, 0), BOIS, Mat.Wood)
		P(m, "Poteau", Vector3.new(0.4, 5, 0.4), Vector3.new(2.4, 2.5, 0), BOIS, Mat.Wood)
		local planche = P(m, "Planche", Vector3.new(5.8, 1.8, 0.3), Vector3.new(0, 3.9, 0), BOIS_CLAIR, Mat.WoodPlanks)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local sg = Instance.new("SurfaceGui")
			sg.Name = "Texte"
			sg.Face = face
			sg.PixelsPerStud = 40
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			local t = Instance.new("TextLabel")
			t.Name = "Nom"
			t.Size = UDim2.fromScale(0.94, 0.86)
			t.Position = UDim2.fromScale(0.03, 0.07)
			t.BackgroundTransparency = 1
			t.Text = "Village"
			t.TextScaled = true
			t.Font = Enum.Font.Fondamento
			t.TextColor3 = rgb(70, 40, 20)
			t.Parent = sg
			sg.Parent = planche
		end
		fini(m)
	end
	do
		local m = nouveau("Tonneaux")
		for i, p in { Vector3.new(0, 0, 0), Vector3.new(2.1, 0, 0.3), Vector3.new(1, 0, 1.9) } do
			P(m, "Tonneau", Vector3.new(2.6, 2, 2), p + Vector3.new(0, 1.3, 0), BOIS, Mat.WoodPlanks, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)) })
			P(m, "Cercle", Vector3.new(0.2, 2.08, 2.08), p + Vector3.new(0, 0.6, 0), FER, Mat.Metal, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)), collide = false })
			P(m, "Cercle", Vector3.new(0.2, 2.08, 2.08), p + Vector3.new(0, 2, 0), FER, Mat.Metal, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)), collide = false })
		end
		fini(m)
	end
	do
		local m = nouveau("Caisses")
		P(m, "Caisse", Vector3.new(2.4, 2.4, 2.4), Vector3.new(0, 1.2, 0), BOIS_CLAIR, Mat.WoodPlanks)
		P(m, "Caisse", Vector3.new(2, 2, 2), Vector3.new(2.3, 1, 0.4), BOIS, Mat.WoodPlanks, { rot = CFrame.Angles(0, 0.3, 0) })
		P(m, "Caisse", Vector3.new(1.8, 1.8, 1.8), Vector3.new(0.4, 3.3, 0.1), BOIS, Mat.WoodPlanks, { rot = CFrame.Angles(0, -0.2, 0) })
		P(m, "Choux", Vector3.new(1.6, 0.6, 1.6), Vector3.new(0, 2.6, 0), rgb(130, 190, 90), Mat.Grass, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Epouvantail")
		P(m, "Poteau", Vector3.new(0.4, 6, 0.4), Vector3.new(0, 3, 0), BOIS, Mat.Wood)
		P(m, "Bras", Vector3.new(4.4, 0.35, 0.35), Vector3.new(0, 4.4, 0), BOIS, Mat.Wood)
		P(m, "Chemise", Vector3.new(2, 2.2, 1), Vector3.new(0, 4, 0), rgb(170, 60, 50), Mat.Fabric, { collide = false })
		P(m, "Manche", Vector3.new(1.4, 0.8, 0.8), Vector3.new(-1.6, 4.4, 0), rgb(170, 60, 50), Mat.Fabric, { collide = false })
		P(m, "Manche", Vector3.new(1.4, 0.8, 0.8), Vector3.new(1.6, 4.4, 0), rgb(170, 60, 50), Mat.Fabric, { collide = false })
		P(m, "Paille", Vector3.new(0.6, 0.6, 0.6), Vector3.new(-2.4, 4.3, 0), rgb(220, 190, 90), Mat.Grass, { collide = false })
		P(m, "Paille", Vector3.new(0.6, 0.6, 0.6), Vector3.new(2.4, 4.3, 0), rgb(220, 190, 90), Mat.Grass, { collide = false })
		P(m, "Tete", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 5.9, 0), rgb(214, 190, 140), Mat.Fabric, { collide = false })
		P(m, "Oeil", Vector3.new(0.25, 0.25, 0.1), Vector3.new(-0.35, 6.1, 0.76), rgb(30, 30, 30), Mat.SmoothPlastic, { collide = false })
		P(m, "Oeil", Vector3.new(0.25, 0.25, 0.1), Vector3.new(0.35, 6.1, 0.76), rgb(30, 30, 30), Mat.SmoothPlastic, { collide = false })
		P(m, "Chapeau", Vector3.new(2.6, 0.2, 2.6), Vector3.new(0, 6.7, 0), rgb(220, 190, 90), Mat.Grass, { collide = false })
		P(m, "Chapeau", Vector3.new(1.5, 0.8, 1.5), Vector3.new(0, 7.1, 0), rgb(220, 190, 90), Mat.Grass, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Botte_Foin")
		P(m, "Foin", Vector3.new(4, 2.4, 2.8), Vector3.new(0, 1.2, 0), rgb(222, 192, 96), Mat.Grass)
		P(m, "Lien", Vector3.new(0.2, 2.5, 2.9), Vector3.new(-1, 1.2, 0), rgb(150, 110, 60), Mat.Fabric, { collide = false })
		P(m, "Lien", Vector3.new(0.2, 2.5, 2.9), Vector3.new(1, 1.2, 0), rgb(150, 110, 60), Mat.Fabric, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Boite_Lettres")
		P(m, "Poteau", Vector3.new(0.4, 3.2, 0.4), Vector3.new(0, 1.6, 0), BOIS, Mat.Wood)
		P(m, "Boite", Vector3.new(1.6, 1.4, 1.2), Vector3.new(0, 3.8, 0), BOIS, Mat.WoodPlanks)
		P(m, "Toit", Vector3.new(2, 0.2, 1.6), Vector3.zero, BOIS_FONCE, Mat.WoodPlanks, { cf = CFrame.new(0, 4.75, 0.3) * CFrame.Angles(math.rad(20), 0, 0) })
		P(m, "Fente", Vector3.new(1, 0.15, 0.1), Vector3.new(0, 4.1, -0.62), rgb(20, 16, 14), Mat.SmoothPlastic, { collide = false })
		P(m, "Sceau", Vector3.new(0.1, 0.5, 0.5), Vector3.new(0, 3.6, -0.62), rgb(150, 30, 30), Mat.SmoothPlastic, { collide = false, forme = "Cylinder", rot = CFrame.Angles(0, math.rad(90), 0) })
		P(m, "Cerclage", Vector3.new(1.7, 0.15, 1.3), Vector3.new(0, 3.3, 0), FER, Mat.Metal, { collide = false })
		fini(m)
	end
	do
		-- Segment de clôture de 4 studs selon X
		local m = nouveau("Cloture")
		P(m, "Poteau", Vector3.new(0.5, 3.2, 0.5), Vector3.new(-2, 1.6, 0), BOIS, Mat.Wood)
		P(m, "Lisse", Vector3.new(4.2, 0.4, 0.25), Vector3.new(0, 2.4, 0), BOIS_CLAIR, Mat.WoodPlanks)
		P(m, "Lisse", Vector3.new(4.2, 0.4, 0.25), Vector3.new(0, 1.2, 0), BOIS_CLAIR, Mat.WoodPlanks)
		fini(m)
	end
	do
		local m = nouveau("Feu_Camp")
		for i = 0, 3 do
			P(m, "Buche", Vector3.new(2.4, 0.5, 0.5), Vector3.new(0, 0.35, 0), BOIS, Mat.Wood, { rot = CFrame.Angles(0, i * math.pi / 4, 0) })
		end
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			P(m, "Pierre", Vector3.new(0.7, 0.5, 0.7), Vector3.new(math.cos(a) * 1.6, 0.25, math.sin(a) * 1.6), PIERRE, Mat.Slate)
		end
		local f = P(m, "Flamme", Vector3.new(0.8, 0.8, 0.8), Vector3.new(0, 0.8, 0), rgb(255, 150, 40), Mat.Neon, { collide = false, transp = 1 })
		local fire = Instance.new("Fire")
		fire.Size = 3
		fire.Heat = 6
		fire.Parent = f
		local light = Instance.new("PointLight")
		light.Range = 20
		light.Brightness = 2
		light.Color = rgb(255, 160, 80)
		light.Parent = f
		fini(m)
	end
	do
		local m = nouveau("Etabli")
		P(m, "Plateau", Vector3.new(4.4, 0.5, 2.4), Vector3.new(0, 3, 0), BOIS_CLAIR, Mat.WoodPlanks)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				P(m, "Pied", Vector3.new(0.5, 2.8, 0.5), Vector3.new(sx * 1.9, 1.4, sz * 0.9), BOIS, Mat.Wood)
			end
		end
		P(m, "Scie", Vector3.new(2, 0.1, 0.6), Vector3.new(-0.6, 3.3, 0.2), rgb(190, 190, 200), Mat.Metal, { collide = false })
		P(m, "Marteau", Vector3.new(0.3, 0.3, 1.4), Vector3.new(1.2, 3.4, -0.2), BOIS, Mat.Wood, { collide = false })
		P(m, "Tete", Vector3.new(0.8, 0.4, 0.4), Vector3.new(1.2, 3.45, -0.8), FER, Mat.Metal, { collide = false })
		fini(m)
	end
	do
		local m = nouveau("Coffre_Joueur")
		P(m, "Caisse", Vector3.new(3, 1.8, 2), Vector3.new(0, 0.9, 0), rgb(150, 100, 60), Mat.WoodPlanks)
		P(m, "Couvercle", Vector3.new(3.1, 0.7, 2.1), Vector3.new(0, 2.15, 0), rgb(180, 130, 80), Mat.WoodPlanks)
		P(m, "Cerclage", Vector3.new(0.3, 2.6, 2.14), Vector3.new(0, 1.25, 0), FER, Mat.Metal, { collide = false })
		fini(m)
	end
end

-- ---------------------------------------------------------------- Village, 2e vague (étape 3C)
-- Auberge (lits à louer = point de réapparition), écurie, tour de guet, pan de palissade.
-- Séparé de maisons() : on peut le relancer seul sans écraser les retouches faites dans Studio.
function M.villages2()
	dossier = dossierModeles()
	local function enseigne2(m: Model, pos: Vector3, mot: string)
		P(m, "Potence", Vector3.new(0.4, 0.4, 2.6), pos + Vector3.new(0, 1.2, 1.1), BOIS_FONCE, Mat.Wood, { collide = false })
		local ens = P(m, "Enseigne", Vector3.new(4.4, 1.6, 0.25), pos + Vector3.new(0, 0, 2.2), BOIS_CLAIR, Mat.WoodPlanks, { collide = false })
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
	-- Auberge : colombages sur deux niveaux d'apparence, salle commune, quatre lits à louer
	do
		local m, base = maison("Auberge", { largeur = 24, profondeur = 18, hauteur = 12, mur = rgb(226, 206, 160), toit = rgb(120, 96, 62), toitMat = "chaume", porteDecal = 0, etage = 8, fleurs = true })
		for i, x in { -8, -3, 3, 8 } do
			lit(m, base, Vector3.new(x, 1, -4.5), ({ rgb(150, 50, 46), rgb(46, 86, 140), rgb(70, 110, 60), rgb(150, 110, 50) })[i], false)
			attache(base, "LitAuberge" .. i, CFrame.new(x, 1, -0.6))
		end
		table_chaises(m, Vector3.new(0, 1, 4))
		lampe_interieure(base, m, Vector3.new(0, 11.4, 0))
		attache(base, "Travail", CFrame.new(-6, 1, 5))
		enseigne2(m, Vector3.new(6, 9.4, 9.2), "Auberge")
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
		enseigne2(m, Vector3.new(7, 7, D / 2), "Écurie")
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
		local feu = P(m, "Brasero", Vector3.new(1.2, 0.8, 1.2), Vector3.new(2.2, Hh + 0.7, -2.2), FER, Mat.Metal)
		local l = Instance.new("PointLight")
		l.Color = rgb(255, 150, 70)
		l.Range = 22
		l.Parent = feu
		fini(m)
	end
	-- Pan de palissade (8 studs) : pieux taillés en pointe, traverse
	do
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
	P(m, "Epi", Vector3.new(0.4, 2.4, 0.4), Vector3.new(0, 32.5, 0), FER, Mat.Metal)
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
		for j = 0, 5 do
			P(ailes, "Latte", Vector3.new(3.8, 0.2, 0.2), Vector3.zero, BOIS, Mat.Wood, { cf = rot * CFrame.new(1.9, 4.6 + j * 2, 0.05), collide = false })
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
		local n = math.max(1, math.floor(d.Magnitude / 3))
		local dir = d.Unit
		for i = 0, n do
			local pos = Vector3.new(x0, y + 1, z0) + dir * (i * d.Magnitude / n)
			P(m, "Merlon", Vector3.new(1.6, 2, ep), Vector3.zero, MUR, Mat.Cobblestone,
				{ cf = CFrame.lookAt(pos, pos + Vector3.new(-dir.Z, 0, dir.X)) })
		end
	end
	local function cone(pos: Vector3, d0: number, h: number, couleur: Color3)
		local n = 7
		for i = 0, n - 1 do
			local d = d0 * (1 - i / n)
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

-- Tableau des quêtes façon WoW : deux poteaux, un auvent, une planche couverte de parchemins
-- cachetés, et un grand « ! » doré au-dessus (repère visible de loin). Invite posée sur « Planche ».
function M.tableauQuetes()
	dossier = dossierModeles()
	local m = nouveau("Tableau_Quetes")
	local PARCH = rgb(236, 220, 176)
	for _, x in { -3.2, 3.2 } do
		P(m, "Poteau", Vector3.new(0.8, 7.6, 0.8), Vector3.new(x, 3.8, 0), BOIS, Mat.Wood)
	end
	P(m, "Planche", Vector3.new(6.2, 3.8, 0.4), Vector3.new(0, 4, 0), BOIS_CLAIR, Mat.WoodPlanks)
	P(m, "Cadre", Vector3.new(6.6, 0.4, 0.6), Vector3.new(0, 6.05, 0), BOIS_FONCE, Mat.Wood)
	P(m, "Cadre", Vector3.new(6.6, 0.4, 0.6), Vector3.new(0, 1.95, 0), BOIS_FONCE, Mat.Wood)
	-- auvent à deux pans
	P(m, "Auvent", Vector3.new(7.8, 0.3, 1.6), Vector3.zero, rgb(110, 70, 48), Mat.WoodPlanks, { cf = CFrame.new(0, 7.9, 0.6) * CFrame.Angles(math.rad(28), 0, 0) })
	P(m, "Auvent", Vector3.new(7.8, 0.3, 1.6), Vector3.zero, rgb(110, 70, 48), Mat.WoodPlanks, { cf = CFrame.new(0, 7.9, -0.6) * CFrame.Angles(math.rad(-28), 0, 0) })
	-- parchemins épinglés (légèrement de travers) et leurs cachets
	local spots = { { -2.1, 4.9, 4 }, { -0.4, 5.1, -6 }, { 1.6, 4.8, 7 }, { -1.5, 3.1, -3 }, { 0.6, 3.2, 5 }, { 2.3, 3.3, -8 } }
	for i, sp in spots do
		local cf = CFrame.new(sp[1], sp[2], 0.24) * CFrame.Angles(0, 0, math.rad(sp[3]))
		P(m, "Parchemin", Vector3.new(1.3, 1.5, 0.06), Vector3.zero, PARCH:Lerp(rgb(214, 196, 150), (i % 3) / 3), Mat.Fabric, { cf = cf, collide = false })
		P(m, "Lignes", Vector3.new(0.9, 0.08, 0.02), Vector3.zero, rgb(120, 100, 80), Mat.SmoothPlastic, { cf = cf * CFrame.new(0, 0.3, 0.04), collide = false })
		P(m, "Lignes", Vector3.new(0.9, 0.08, 0.02), Vector3.zero, rgb(120, 100, 80), Mat.SmoothPlastic, { cf = cf * CFrame.new(0, 0.05, 0.04), collide = false })
		P(m, "Cachet", Vector3.new(0.12, 0.3, 0.3), Vector3.zero, rgb(170, 30, 30), Mat.SmoothPlastic,
			{ cf = cf * CFrame.new(0, -0.45, 0.05) * CFrame.Angles(0, math.rad(90), 0), forme = "Cylinder", collide = false })
	end
	-- grand « ! » doré
	local ex = P(m, "Exclamation", Vector3.new(0.7, 1.8, 0.7), Vector3.new(0, 10.4, 0), OR, Mat.Neon, { collide = false })
	P(m, "Point", Vector3.new(0.75, 0.75, 0.75), Vector3.new(0, 8.9, 0), OR, Mat.Neon, { forme = "Ball", collide = false })
	local light = Instance.new("PointLight")
	light.Range = 10
	light.Brightness = 0.8
	light.Color = rgb(255, 214, 110)
	light.Parent = ex
	P(m, "Caisse", Vector3.new(1.6, 1.2, 1.2), Vector3.new(2.6, 0.6, 1.4), BOIS_CLAIR, Mat.WoodPlanks)
	attache(m.PrimaryPart, "Devant", CFrame.new(0, 0, 4))
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
			P(t, "Ble", Vector3.new(1.9, h, 1.5), Vector3.zero, gold:Lerp(rgb(150, 150, 60), 0.18), Mat.Grass, { cf = CFrame.new(x, 0.4 + h / 2, z) * tilt, collide = false })
			P(t, "Epis", Vector3.new(2.1, 0.9, 1.7), Vector3.zero, gold, Mat.Grass, { cf = CFrame.new(x, 0.4 + h, z) * tilt, collide = false })
		end
	end
	-- clôture : poteaux tous les 4 studs, deux lisses
	local function cote(a: Vector3, b: Vector3)
		local d = b - a
		local n = math.max(1, math.floor(d.Magnitude / 4))
		for i = 0, n do
			P(m, "Piquet", Vector3.new(0.6, 3.2, 0.6), a + d * (i / n) + Vector3.new(0, 1.6, 0), BOIS, Mat.Wood)
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
	P(m, "Botte", Vector3.new(2.4, 1.6, 1.6), Vector3.new(hx + 2, 0.8, hz - 2), rgb(222, 186, 96), Mat.Grass)
	fini(m)
	return m
end

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
function M.stations()
	dossier = dossierModeles()
	do
		local m = nouveau("Enclume")
		P(m, "Billot", Vector3.new(1.8, 1.6, 1.8), Vector3.new(0, 0.8, 0), BOIS_FONCE, Mat.Wood, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)) })
		P(m, "Pied", Vector3.new(1.2, 0.5, 0.9), Vector3.new(0, 1.85, 0), FER, Mat.Metal)
		P(m, "Table", Vector3.new(2.6, 0.6, 1.1), Vector3.new(0, 2.4, 0), FER, Mat.Metal)
		P(m, "Bigorne", Vector3.new(0.9, 0.5, 0.9), Vector3.zero, FER, Mat.Metal, { forme = "Wedge", cf = CFrame.new(1.75, 2.4, 0) * CFrame.Angles(0, math.rad(90), 0) })
		P(m, "Marteau", Vector3.new(0.18, 0.18, 1.4), Vector3.zero, BOIS, Mat.Wood, { collide = false, cf = CFrame.new(-0.6, 2.8, 0.3) * CFrame.Angles(0, math.rad(25), 0) })
		P(m, "Tete", Vector3.new(0.45, 0.35, 0.35), Vector3.zero, FER, Mat.Metal, { collide = false, cf = CFrame.new(-0.3, 2.8, -0.35) * CFrame.Angles(0, math.rad(25), 0) })
		fini(m)
	end
	do
		local m = nouveau("Metier_Tisser")
		for _, x in { -1.5, 1.5 } do
			P(m, "Montant", Vector3.new(0.3, 4, 0.3), Vector3.new(x, 2, -0.8), BOIS, Mat.Wood)
			P(m, "Montant", Vector3.new(0.3, 2.4, 0.3), Vector3.new(x, 1.2, 0.8), BOIS, Mat.Wood)
			P(m, "Longeron", Vector3.new(0.25, 0.25, 1.9), Vector3.new(x, 2.3, 0), BOIS_FONCE, Mat.Wood)
		end
		P(m, "Ensouple", Vector3.new(3.3, 0.35, 0.35), Vector3.new(0, 3.8, -0.8), BOIS_FONCE, Mat.Wood)
		P(m, "Ensouple", Vector3.new(3.3, 0.35, 0.35), Vector3.new(0, 2.3, 0.8), BOIS_FONCE, Mat.Wood)
		P(m, "Fils", Vector3.new(2.8, 0.05, 1.9), Vector3.zero, rgb(236, 226, 200), Mat.Fabric, { collide = false, cf = CFrame.new(0, 3.05, 0) * CFrame.Angles(math.rad(-38), 0, 0) })
		P(m, "Toile", Vector3.new(2.8, 0.06, 0.7), Vector3.new(0, 2.36, 0.45), rgb(170, 60, 50), Mat.Fabric, { collide = false })
		P(m, "Banc", Vector3.new(2, 0.3, 0.8), Vector3.new(0, 1.3, 1.9), BOIS_CLAIR, Mat.WoodPlanks)
		for _, x in { -0.8, 0.8 } do
			P(m, "PiedBanc", Vector3.new(0.25, 1.2, 0.25), Vector3.new(x, 0.6, 1.9), BOIS, Mat.Wood)
		end
		fini(m)
	end
	do
		-- bac de tannage : cuve de planches cerclée, peau tendue sur un cadre, racloir
		local m = nouveau("Bac_Tannage")
		P(m, "Cuve", Vector3.new(2.6, 1.6, 2.6), Vector3.new(-0.9, 0.8, 0), BOIS, Mat.WoodPlanks, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)) })
		P(m, "Eau", Vector3.new(0.1, 2.3, 2.3), Vector3.new(-0.9, 1.55, 0), rgb(110, 84, 50), Mat.SmoothPlastic, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)), collide = false })
		for _, y in { 0.35, 1.25 } do
			P(m, "Cercle", Vector3.new(0.15, 2.7, 2.7), Vector3.new(-0.9, y, 0), FER, Mat.Metal, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)), collide = false })
		end
		for _, z in { -0.9, 0.9 } do
			P(m, "Cadre", Vector3.new(0.25, 3, 0.25), Vector3.new(1.4, 1.5, z), BOIS_FONCE, Mat.Wood)
		end
		P(m, "Traverse", Vector3.new(0.25, 0.25, 2.1), Vector3.new(1.4, 2.9, 0), BOIS_FONCE, Mat.Wood)
		P(m, "Peau", Vector3.new(0.08, 2.2, 1.6), Vector3.new(1.45, 1.75, 0), rgb(176, 128, 84), Mat.Fabric, { collide = false })
		P(m, "Racloir", Vector3.new(0.7, 0.12, 0.25), Vector3.new(-0.9, 1.65, 1.3), FER, Mat.Metal, { collide = false })
		fini(m)
	end
	do
		-- alambic : chaudière de cuivre sur un foyer, col de cygne, serpentin et fiole
		local m = nouveau("Alambic")
		local CUIVRE = rgb(196, 112, 64)
		P(m, "Foyer", Vector3.new(2.2, 1, 2.2), Vector3.new(0, 0.5, 0), PIERRE, Mat.Cobblestone)
		local braise = P(m, "Braise", Vector3.new(1, 0.2, 1), Vector3.new(0, 1.05, 0), rgb(255, 120, 40), Mat.Neon, { collide = false })
		local light = Instance.new("PointLight")
		light.Range = 8
		light.Brightness = 0.8
		light.Color = rgb(255, 150, 80)
		light.Parent = braise
		P(m, "Chaudiere", Vector3.new(1.9, 1.9, 1.9), Vector3.new(0, 2, 0), CUIVRE, Mat.Metal, { forme = "Ball" })
		P(m, "Chapiteau", Vector3.new(0.9, 0.9, 0.9), Vector3.new(0, 3.1, 0), CUIVRE, Mat.Metal, { forme = "Ball" })
		P(m, "Col", Vector3.new(0.22, 0.22, 2.2), Vector3.zero, CUIVRE, Mat.Metal, { collide = false, cf = CFrame.new(0.9, 3.1, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(-20), 0, 0) })
		P(m, "Serpentin", Vector3.new(0.9, 1.2, 0.9), Vector3.new(2, 1.6, 0), CUIVRE:Lerp(rgb(90, 60, 40), 0.3), Mat.Metal, { forme = "Cylinder", rot = CFrame.Angles(0, 0, math.rad(90)) })
		P(m, "Fiole", Vector3.new(0.4, 0.5, 0.4), Vector3.new(2, 0.25, 0.7), rgb(140, 230, 140), Mat.Glass, { collide = false, transp = 0.3 })
		fini(m)
	end
	do
		local m = nouveau("Abreuvoir")
		P(m, "Auge", Vector3.new(3.6, 1, 1.4), Vector3.new(0, 0.9, 0), BOIS, Mat.WoodPlanks)
		P(m, "Eau", Vector3.new(3.3, 0.1, 1.1), Vector3.new(0, 1.42, 0), rgb(70, 140, 180), Mat.Glass, { collide = false, transp = 0.25 })
		for _, x in { -1.5, 1.5 } do
			P(m, "Pied", Vector3.new(0.4, 0.5, 1.2), Vector3.new(x, 0.25, 0), BOIS_FONCE, Mat.Wood)
		end
		fini(m)
	end
	do
		local m = nouveau("Mangeoire")
		for _, x in { -1.4, 1.4 } do
			P(m, "Montant", Vector3.new(0.3, 2.6, 0.3), Vector3.new(x, 1.3, 0), BOIS_FONCE, Mat.Wood)
		end
		P(m, "Ratelier", Vector3.new(3.2, 1.2, 1), Vector3.zero, BOIS, Mat.WoodPlanks, { cf = CFrame.new(0, 1.7, 0) * CFrame.Angles(math.rad(-15), 0, 0) })
		P(m, "Foin", Vector3.new(2.8, 0.7, 0.8), Vector3.new(0, 2.3, 0.1), rgb(214, 182, 96), Mat.Grass, { collide = false })
		fini(m)
	end
	return true
end

-- Potence à lanterne seule (sans refaire tout le décor)
function M.lampadaire()
	dossier = dossierModeles()
	lampadaire()
end

-- Maisons seules (Maison_A/B/C, boutique, shérif, taverne, forge, chapelle, ruine…)
function M.maisons()
	dossier = dossierModeles()
	maisons()
	return #dossier:GetChildren()
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
