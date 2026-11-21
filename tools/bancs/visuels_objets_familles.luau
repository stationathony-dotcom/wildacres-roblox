-- Studio Edit (21/11, Claude) : miniatures « top niveau » des familles d'objets qui se ressemblaient toutes.
-- À lancer APRÈS tools/bancs/visuels_objets.luau (Codex) : remplace ces miniatures dans ReplicatedStorage.IconesObjets.
--   graines seed_*       : sachet de toile + la plante qu'elle donne devant (épi, racine, chou, courge, vigne, pousse…)
--   livres               : reliure + coins + fermoir + emblème du métier en relief, épaisseur et teinte propres
--   parchemins           : rouleau / carte / lettre scellée / contrat, sceau de cire et ruban différenciés
--   potions et fioles    : forme du flacon selon l'effet, liquide translucide, bouchon, étiquette
--   teintures            : pot de pigment + tache de couleur
--   âmes de boss ame_*   : orbe à cœur lumineux + un trait du boss (couronne, champignon, glace, ailes…)
--   prises de créatures  : la partie de la bête qui leur donne leur nom (croc, griffe, écaille, plume, corne…)
-- Rend un résumé « famille : n ». Ne touche à rien d'autre que ces modèles.
local RS = game:GetService("ReplicatedStorage")
local copy = RS.Shared:Clone()
copy.Parent = game:GetService("ServerStorage")
local C = require(copy.Config)
copy:Destroy()
local dest = RS:FindFirstChild("IconesObjets")
assert(dest, "IconesObjets introuvable : lancer d'abord visuels_objets")

local rgb, v, cf = Color3.fromRGB, Vector3.new, CFrame.new
local M = Enum.Material
local ANG = CFrame.Angles
local rad = math.rad

-- couleur stable tirée de l'identifiant (variantes d'une même famille)
local function hash(s)
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end
local function shade(c, k)
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end
local function low(s)
	s = string.lower(s or "")
	for a, b in pairs({ ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["à"] = "a", ["â"] = "a", ["î"] = "i", ["ô"] = "o", ["û"] = "u", ["ù"] = "u", ["ç"] = "c", ["œ"] = "oe", ["É"] = "e", ["È"] = "e", ["Ê"] = "e", ["À"] = "a", ["Î"] = "i", ["Ô"] = "o", ["Œ"] = "oe" }) do
		s = string.gsub(s, a, b)
	end
	return s
end
local function has(s, ...)
	for _, w in { ... } do
		if string.find(s, w, 1, true) then
			return true
		end
	end
	return false
end

local count, fam = 0, {}
local function icon(id, family, build)
	local m = Instance.new("Model")
	m.Name = id
	m:SetAttribute("ApercuDroit", true)
	m:SetAttribute("Famille", family)
	local function add(size, at, color, mat, shape, rot, name)
		if typeof(rot) == "CFrame" then
			at = at * rot
		end
		local p
		if shape == "wedge" then
			p = Instance.new("WedgePart")
		elseif shape == "corner" then
			p = Instance.new("CornerWedgePart")
		else
			p = Instance.new("Part")
			if shape == "ball" and (math.abs(size.X - size.Y) > 0.01 or math.abs(size.Y - size.Z) > 0.01) then
				-- boule non uniforme : une Part « Ball » prendrait la plus petite dimension → ellipsoïde par maillage
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = p
			elseif shape == "ball" then
				p.Shape = Enum.PartType.Ball
			elseif shape == "cyl" then
				p.Shape = Enum.PartType.Cylinder
			end
		end
		p.Name = name or "Element"
		p.Size = size
		p.CFrame = at
		p.Color = color
		p.Material = mat or M.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	build(add)
	local old = dest:FindFirstChild(id)
	if old then
		old:Destroy()
	end
	m.Parent = dest
	count += 1
	fam[family] = (fam[family] or 0) + 1
end
local UP = ANG(0, 0, rad(90)) -- cylindre debout

-- ----------------------------------------------------------------- GRAINES : sachet + plante
local function sachet(add, h, tissu)
	-- petit sachet de toile ouvert, à gauche ; la plante se tient à droite, bien visible
	local x = -0.62
	add(v(0.95, 1.05, 0.8), cf(x, 0.52, 0), tissu, M.Fabric)
	add(v(1.02, 0.22, 0.86), cf(x, 1.12, 0) * ANG(0, 0, rad(5)), shade(tissu, 0.85), M.Fabric) -- bord roulé
	add(v(1.06, 0.1, 0.9), cf(x, 0.9, 0), rgb(120, 86, 48), M.Fabric) -- ficelle
	add(v(0.8, 0.08, 0.66), cf(x, 1.2, 0), rgb(176, 136, 82), M.SmoothPlastic) -- graines dans l'ouverture
	for i = 0, 2 do
		local a = i * 2.1 + (h % 5)
		add(v(0.16, 0.1, 0.12), cf(x + 0.5 + math.cos(a) * 0.15, 0.05, 0.45 + math.sin(a) * 0.15) * ANG(0, a, 0.4), rgb(176, 136, 82), M.SmoothPlastic, "ball")
	end
end
local function plante(add, shape, col, crop)
	local x, z = 0.55, 0
	if shape == "wheat" then
		for i = -1, 1 do
			add(v(0.06, 1.5, 0.06), cf(x + i * 0.22, 0.75, z) * ANG(0, 0, rad(i * 8)), rgb(184, 160, 80), M.Grass)
			for k = 0, 3 do
				add(v(0.14, 0.2, 0.12), cf(x + i * 0.22 + i * 0.08 + (k % 2 == 0 and -0.06 or 0.06), 1.35 + k * 0.15, z), col, M.Grass, "ball")
			end
		end
	elseif shape == "root" then
		local long = has(crop, "carrot", "parsnip")
		add(v(long and 1.1 or 0.6, long and 0.42 or 0.62, long and 0.42 or 0.62), cf(x, long and 0.55 or 0.32, z) * (long and ANG(0, 0, rad(-80)) or CFrame.identity), col, M.SmoothPlastic, long and "cyl" or "ball")
		if long then
			add(v(0.3, 0.2, 0.2), cf(x, 0.02, z) * ANG(0, 0, rad(90)), shade(col, 0.9), M.SmoothPlastic, "wedge")
		end
		for i = -1, 1 do
			add(v(0.08, 0.7, 0.24), cf(x + i * 0.12, (long and 1.35 or 0.95), z) * ANG(0, 0, rad(i * 18)), rgb(76, 140, 60), M.Grass)
		end
	elseif shape == "big" then
		local melon = has(crop, "melon")
		add(v(1.05, 0.85, 1.05), cf(x, 0.42, z), col, melon and M.Grass or M.SmoothPlastic, "ball")
		for i = 0, 5 do -- côtes / stries
			local a = i / 6 * math.pi * 2
			add(v(0.08, 0.8, 0.5), cf(x + math.cos(a) * 0.36, 0.43, z + math.sin(a) * 0.36) * ANG(0, -a, 0), shade(col, 0.82), M.SmoothPlastic)
		end
		add(v(0.12, 0.35, 0.12), cf(x, 0.98, z) * ANG(0, 0, rad(12)), rgb(96, 120, 50), M.Wood)
		if has(crop, "cabbage") then
			for i = 0, 3 do
				add(v(0.6, 0.08, 0.5), cf(x, 0.62, z) * ANG(rad(-25), i * rad(90), 0) * cf(0, 0, 0.3), shade(col, 1.12), M.Grass)
			end
		end
	elseif shape == "bush" then
		local grappe = has(crop, "grape", "tomato", "pea", "bean", "hops", "eggplant")
		add(v(0.08, 1.3, 0.08), cf(x, 0.65, z), rgb(80, 120, 50), M.Wood)
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2
			add(v(0.38, 0.06, 0.24), cf(x + math.cos(a) * 0.22, 0.95 + i * 0.08, z + math.sin(a) * 0.22) * ANG(0, -a, rad(15)), rgb(84, 150, 64), M.Grass)
		end
		if grappe then
			local n = has(crop, "grape") and 7 or 3
			for i = 1, n do
				local a = i * 2.4
				add(v(0.24, 0.24, 0.24), cf(x + math.cos(a) * 0.18, 0.55 - (i % 3) * 0.12, z + math.sin(a) * 0.18), col, M.SmoothPlastic, "ball")
			end
		else -- herbes, lin : brins et petites fleurs
			for i = -2, 2 do
				add(v(0.05, 0.9, 0.05), cf(x + i * 0.12, 0.45, z) * ANG(0, 0, rad(i * 10)), rgb(96, 150, 70), M.Grass)
				add(v(0.14, 0.14, 0.14), cf(x + i * 0.2, 0.95, z), col, M.SmoothPlastic, "ball")
			end
		end
	else -- pousse d'arbre (graines d'arbres) : gland / pomme de pin + pousse
		add(v(0.42, 0.5, 0.42), cf(x, 0.25, z), rgb(132, 90, 48), M.Wood, "ball")
		add(v(0.46, 0.18, 0.46), cf(x, 0.48, z), rgb(96, 70, 40), M.Wood, "cyl", UP)
		add(v(0.06, 0.8, 0.06), cf(x, 0.95, z), rgb(90, 120, 50), M.Wood)
		add(v(0.5, 0.06, 0.3), cf(x + 0.18, 1.3, z) * ANG(0, 0, rad(25)), col, M.Grass)
		add(v(0.5, 0.06, 0.3), cf(x - 0.18, 1.2, z) * ANG(0, 0, rad(-25)), col, M.Grass)
	end
end
for id in C.ITEMS do
	if string.sub(id, 1, 5) == "seed_" and id ~= "seed_sack" then
		local crop = string.sub(id, 6)
		local def = C.CROPS[crop]
		local h = hash(id)
		local tissu = ({ rgb(196, 168, 120), rgb(176, 150, 106), rgb(206, 182, 138), rgb(168, 140, 96) })[h % 4 + 1]
		local shape = def and def.shape or "tree"
		local col = def and def.color or ({ chene = rgb(90, 140, 60), sapin = rgb(40, 100, 60), bouleau = rgb(140, 180, 80), cerisier = rgb(230, 150, 170), saule = rgb(120, 170, 90) })[string.match(crop, "tree_(%a+)") or ""] or rgb(90, 140, 60)
		icon(id, "graine", function(add)
			sachet(add, h, tissu)
			plante(add, shape, col, crop)
		end)
	end
end

-- ----------------------------------------------------------------- LIVRES
local EMBLEME = { -- mot de l'identifiant ou du nom → forme en relief sur la couverture
	{ { "recette", "cuisine", "cook" }, "cercle" }, { { "forge", "smith", "artisan", "plan" }, "marteau" },
	{ { "peche", "fish", "sea" }, "poisson" }, { { "herb", "alchim", "potion", "plante", "grimoire" }, "etoile" },
	{ { "combat", "guerre", "patrol", "recruit" }, "epee" }, { { "chanson", "song", "musique" }, "note" },
	{ { "loi", "law", "justice" }, "balance" }, { { "bestiaire", "creature", "monstre" }, "griffe" },
}
local function embleme(add, kind, at, metal)
	if kind == "marteau" then
		add(v(0.06, 0.5, 0.06), at * ANG(0, 0, rad(30)), metal, M.Metal)
		add(v(0.3, 0.14, 0.08), at * cf(0.12, 0.2, 0) * ANG(0, 0, rad(30)), metal, M.Metal)
	elseif kind == "poisson" then
		add(v(0.42, 0.2, 0.06), at, metal, M.Metal, "ball")
		add(v(0.16, 0.2, 0.06), at * cf(0.28, 0, 0) * ANG(0, 0, rad(90)), metal, M.Metal, "wedge")
	elseif kind == "epee" then
		add(v(0.06, 0.6, 0.06), at, metal, M.Metal)
		add(v(0.26, 0.05, 0.06), at * cf(0, -0.15, 0), metal, M.Metal)
	elseif kind == "etoile" then
		for i = 0, 2 do
			add(v(0.42, 0.07, 0.06), at * ANG(0, 0, rad(i * 60)), metal, M.Metal)
		end
	elseif kind == "note" then
		add(v(0.16, 0.12, 0.06), at * cf(-0.05, -0.18, 0), metal, M.Metal, "ball")
		add(v(0.04, 0.4, 0.06), at * cf(0.03, 0.02, 0), metal, M.Metal)
	elseif kind == "balance" then
		add(v(0.04, 0.42, 0.06), at, metal, M.Metal)
		add(v(0.4, 0.04, 0.06), at * cf(0, 0.18, 0), metal, M.Metal)
		add(v(0.12, 0.05, 0.06), at * cf(-0.18, 0.06, 0), metal, M.Metal)
		add(v(0.12, 0.05, 0.06), at * cf(0.18, 0.06, 0), metal, M.Metal)
	elseif kind == "griffe" then
		for i = -1, 1 do
			add(v(0.06, 0.4, 0.06), at * cf(i * 0.1, 0, 0) * ANG(0, 0, rad(i * 12 - 10)), metal, M.Metal)
		end
	else
		add(v(0.32, 0.32, 0.06), at, metal, M.Metal, "cyl", ANG(0, rad(90), 0))
	end
end
local function estLivre(id, info)
	local n = low(info.name)
	return has(info.icon or "", "📓", "📕", "📗", "📘", "📙", "📒", "📔", "📖", "📚") or has(n, "livre", "grimoire", "manuel", "traite", "almanach", "registre", "carnet", "recueil", "journal d")
end
for id, info in C.ITEMS do
	if estLivre(id, info) and not info.place and not info.tool then
		local h = hash(id)
		local n = low(info.name) .. " " .. id
		local reliure = ({ rgb(120, 40, 36), rgb(40, 70, 120), rgb(50, 96, 56), rgb(108, 66, 36), rgb(86, 46, 100), rgb(36, 36, 44) })[h % 6 + 1]
		local metal = (h % 3 == 0) and rgb(214, 172, 70) or rgb(150, 150, 156)
		local ep = 0.32 + (h % 4) * 0.08
		local kind = "cercle"
		for _, e in EMBLEME do
			if has(n, table.unpack(e[1])) then
				kind = e[2]
				break
			end
		end
		icon(id, "livre", function(add)
			local base = cf(0, 1.1, 0) * ANG(rad(-12), rad(18), 0)
			add(v(1.5, 2.0, ep), base, reliure, M.Leather or M.Fabric)
			add(v(1.38, 1.9, ep - 0.08), base * cf(0.07, 0, 0), rgb(236, 224, 196), M.SmoothPlastic) -- tranche des pages
			add(v(0.12, 2.04, ep + 0.04), base * cf(-0.74, 0, 0), shade(reliure, 0.7), M.Leather or M.Fabric) -- dos
			for _, y in { -0.6, 0, 0.6 } do -- nerfs du dos
				add(v(0.14, 0.08, ep + 0.08), base * cf(-0.74, y, 0), shade(reliure, 0.55), M.Leather or M.Fabric)
			end
			for _, cx in { -0.62, 0.62 } do -- coins de métal
				for _, cy in { -0.88, 0.88 } do
					add(v(0.24, 0.24, ep + 0.04), base * cf(cx, cy, 0), metal, M.Metal)
				end
			end
			add(v(0.34, 0.2, ep + 0.1), base * cf(0.72, 0, 0), metal, M.Metal) -- fermoir
			embleme(add, kind, base * cf(0.05, 0.1, -(ep / 2 + 0.04)), metal)
			if h % 2 == 0 then -- signet
				add(v(0.12, 0.5, 0.03), base * cf(0.3, -1.15, 0), rgb(170, 40, 40), M.Fabric)
			end
		end)
	end
end

-- ----------------------------------------------------------------- PARCHEMINS, LETTRES, CARTES, CONTRATS
local function estEcrit(id, info)
	local n = low(info.name)
	return has(info.icon or "", "📜", "📃", "🧾", "🗺️", "✉️") or has(n, "parchemin", "lettre", "contrat", "carte ", "plan ", "acte", "diplome", "avis", "charte", "recommandation", "facture", "edit")
end
for id, info in C.ITEMS do
	if estEcrit(id, info) and not info.place and not info.tool and not estLivre(id, info) then
		local h = hash(id)
		local n = low(info.name) .. " " .. id
		local cire = ({ rgb(170, 30, 30), rgb(30, 70, 150), rgb(40, 120, 60), rgb(180, 140, 40), rgb(110, 40, 120) })[h % 5 + 1]
		local papier = has(n, "vieux", "ancien", "old") and rgb(214, 190, 140) or rgb(238, 224, 190)
		local forme = (has(n, "carte", "map", "plan") and "carte") or (has(n, "lettre", "courrier", "message", "recommandation") and "lettre")
			or (has(n, "contrat", "acte", "charte", "diplome", "facture", "edit") and "contrat") or "rouleau"
		icon(id, "ecrit", function(add)
			if forme == "lettre" then
				add(v(1.8, 0.08, 1.2), cf(0, 0.1, 0) * ANG(0, rad(15), 0), papier, M.SmoothPlastic)
				add(v(1.27, 0.06, 0.9), cf(0, 0.16, -0.1) * ANG(0, rad(15), 0) * ANG(rad(8), rad(45), 0), shade(papier, 0.94), M.SmoothPlastic, "wedge")
				add(v(0.4, 0.1, 0.4), cf(0.05, 0.22, 0.05), cire, M.SmoothPlastic, "cyl", UP)
				add(v(0.22, 0.04, 0.22), cf(0.05, 0.28, 0.05), shade(cire, 0.7), M.SmoothPlastic, "cyl", UP)
			elseif forme == "carte" then
				add(v(2.0, 0.06, 1.5), cf(0, 0.08, 0), papier, M.SmoothPlastic)
				add(v(0.3, 0.3, 1.6), cf(-1.05, 0.15, 0) * ANG(0, 0, 0), shade(papier, 0.88), M.SmoothPlastic, "cyl", ANG(0, rad(90), 0))
				add(v(0.3, 0.3, 1.6), cf(1.05, 0.15, 0), shade(papier, 0.88), M.SmoothPlastic, "cyl", ANG(0, rad(90), 0))
				for i = 0, 3 do -- tracés : rivière, côte, chemin
					add(v(0.6, 0.02, 0.06), cf(-0.5 + i * 0.32, 0.12, -0.3 + (i % 2) * 0.4) * ANG(0, rad(30 * i), 0), rgb(60, 100, 160), M.SmoothPlastic)
				end
				add(v(0.24, 0.02, 0.24), cf(0.5, 0.12, 0.3), rgb(170, 40, 40), M.SmoothPlastic, "cyl", UP) -- croix du trésor
				add(v(0.4, 0.02, 0.08), cf(0.5, 0.13, 0.3) * ANG(0, rad(45), 0), rgb(170, 40, 40), M.SmoothPlastic)
				add(v(0.4, 0.02, 0.08), cf(0.5, 0.13, 0.3) * ANG(0, rad(-45), 0), rgb(170, 40, 40), M.SmoothPlastic)
			elseif forme == "contrat" then
				add(v(1.4, 0.06, 1.9), cf(0, 0.1, 0) * ANG(0, rad(-10), 0), papier, M.SmoothPlastic)
				for i = 0, 4 do -- lignes d'écriture
					add(v(1.0, 0.02, 0.05), cf(-0.05, 0.14, -0.6 + i * 0.25) * ANG(0, rad(-10), 0), rgb(70, 60, 50), M.SmoothPlastic)
				end
				add(v(0.42, 0.12, 0.42), cf(0.45, 0.17, 0.75), cire, M.SmoothPlastic, "cyl", UP) -- sceau pendant
				add(v(0.12, 0.04, 0.5), cf(0.45, 0.13, 0.98), cire, M.Fabric) -- ruban du sceau
			else -- rouleau
				add(v(1.9, 0.62, 0.62), cf(0, 0.32, 0), papier, M.SmoothPlastic, "cyl")
				add(v(0.08, 0.66, 0.66), cf(-0.96, 0.32, 0), shade(papier, 0.85), M.SmoothPlastic, "cyl")
				add(v(0.08, 0.66, 0.66), cf(0.96, 0.32, 0), shade(papier, 0.85), M.SmoothPlastic, "cyl")
				add(v(0.16, 0.66, 0.66), cf(0, 0.32, 0), cire, M.Fabric, "cyl") -- ruban
				add(v(0.32, 0.32, 0.1), cf(0, 0.32, -0.36), shade(cire, 0.85), M.SmoothPlastic, "cyl", ANG(0, rad(90), 0))
			end
		end)
	end
end

-- ----------------------------------------------------------------- POTIONS, FIOLES, ÉLIXIRS
local function estPotion(id, info)
	local n = low(info.name)
	return has(info.icon or "", "🧪", "⚗️") or has(id, "potion", "elixir", "vial", "flask", "tonic") or has(n, "potion", "elixir", "fiole", "philtre", "tonique", "remede", "baume")
end
for id, info in C.ITEMS do
	if estPotion(id, info) and not info.place and not info.tool then
		local h = hash(id)
		local n = low(info.name) .. " " .. id
		local liquide = (has(n, "soin", "vie", "heal", "sante") and rgb(210, 40, 50)) or (has(n, "force", "strength") and rgb(220, 110, 30))
			or (has(n, "vitesse", "speed", "endurance") and rgb(60, 200, 90)) or (has(n, "chance", "luck") and rgb(240, 200, 50))
			or (has(n, "discret", "ombre", "nuit", "invis") and rgb(90, 60, 150)) or (has(n, "froid", "glace", "givre") and rgb(140, 210, 240))
			or (has(n, "poison", "venin") and rgb(120, 180, 40)) or ({ rgb(200, 60, 160), rgb(60, 120, 220), rgb(240, 140, 60), rgb(80, 190, 170) })[h % 4 + 1]
		local forme = h % 4
		icon(id, "potion", function(add)
			local verre = rgb(210, 236, 240)
			if forme == 0 then -- flacon rond
				add(v(1.4, 1.4, 1.4), cf(0, 0.75, 0), liquide, M.Glass, "ball").Transparency = 0.15
				add(v(0.42, 0.55, 0.42), cf(0, 1.6, 0), verre, M.Glass, "cyl", UP).Transparency = 0.3
			elseif forme == 1 then -- flacon carré
				add(v(1.0, 1.3, 1.0), cf(0, 0.65, 0), liquide, M.Glass).Transparency = 0.15
				add(v(1.06, 0.12, 1.06), cf(0, 1.32, 0), verre, M.Glass).Transparency = 0.3
				add(v(0.4, 0.4, 0.4), cf(0, 1.55, 0), verre, M.Glass, "cyl", UP).Transparency = 0.3
			elseif forme == 2 then -- fiole longue
				add(v(1.7, 0.6, 0.6), cf(0, 0.95, 0), liquide, M.Glass, "cyl", UP).Transparency = 0.15
				add(v(0.6, 0.6, 0.6), cf(0, 0.12, 0), liquide, M.Glass, "ball").Transparency = 0.15
			else -- gourde plate
				add(v(1.3, 1.3, 0.55), cf(0, 0.72, 0), liquide, M.Glass, "cyl", ANG(0, rad(90), 0)).Transparency = 0.15
				add(v(0.36, 0.45, 0.36), cf(0, 1.55, 0), verre, M.Glass, "cyl", UP).Transparency = 0.3
				add(v(0.08, 1.4, 0.62), cf(0, 0.72, 0), rgb(120, 80, 50), M.Leather or M.Fabric) -- sangle
			end
			local top = forme == 2 and 1.95 or (forme == 1 and 1.85 or 1.95)
			add(v(0.34, 0.3, 0.34), cf(0, top, 0), rgb(150, 100, 60), M.Wood, "cyl", UP) -- bouchon
			add(v(0.4, 0.06, 0.4), cf(0, top - 0.12, 0), rgb(214, 172, 70), M.Metal, "cyl", UP) -- bague
			add(v(0.62, 0.4, 0.04), cf(0, 0.7, forme == 2 and -0.31 or -0.62), rgb(236, 222, 186), M.SmoothPlastic) -- étiquette
			add(v(0.2, 0.2, 0.05), cf(0, 0.72, forme == 2 and -0.34 or -0.65), shade(liquide, 0.7), M.SmoothPlastic, "cyl", ANG(0, rad(90), 0))
		end)
	end
end

-- ----------------------------------------------------------------- TEINTURES
for id, info in C.ITEMS do
	if id == "dye" or (string.find(id, "dye") and not string.find(id, "dyed")) or string.find(low(info.name), "^teinture") then
		local h = hash(id)
		local c = ({ rgb(180, 40, 40), rgb(40, 80, 170), rgb(220, 180, 40), rgb(60, 140, 60), rgb(130, 60, 150) })[h % 5 + 1]
		icon(id, "teinture", function(add)
			add(v(1.2, 0.8, 1.2), cf(0, 0.4, 0), rgb(176, 120, 80), M.Slate, "cyl", UP) -- pot de terre
			add(v(1.3, 0.14, 1.3), cf(0, 0.82, 0), rgb(150, 100, 64), M.Slate, "cyl", UP)
			add(v(1.05, 0.08, 1.05), cf(0, 0.86, 0), c, M.SmoothPlastic, "cyl", UP) -- pigment
			add(v(0.12, 1.2, 0.12), cf(0.25, 1.2, 0) * ANG(0, 0, rad(-25)), rgb(140, 100, 60), M.Wood) -- bâton
			add(v(1.0, 0.04, 0.7), cf(0.9, 0.02, 0.5) * ANG(0, rad(20), 0), c, M.SmoothPlastic, "cyl", UP) -- tache
			add(v(0.5, 0.04, 0.4), cf(-0.8, 0.02, -0.6), c, M.SmoothPlastic, "cyl", UP)
		end)
	end
end

-- ----------------------------------------------------------------- ÂMES DE BOSS
local TRAIT = {
	{ { "roi", "king", "couronne", "crownless", "lord", "seigneur" }, "couronne" }, { { "myco", "champignon", "mycel" }, "champignon" },
	{ { "slime", "gelee" }, "goutte" }, { { "ronce", "bramble", "epine" }, "epines" }, { { "glace", "givre", "neige", "brume", "ice", "snow" }, "glace" },
	{ { "wyverne", "dragon", "aile" }, "ailes" }, { { "scarabe", "scarab" }, "carapace" }, { { "colosse", "verre", "glass" }, "eclats" },
	{ { "moisson", "harvest" }, "epi" }, { { "geant", "giant", "montagne" }, "roc" }, { { "gobelin", "goblin" }, "oreilles" },
	{ { "bete", "beast", "profondeur", "deep" }, "tentacules" }, { { "vargor", "loup", "wolf" }, "crocs" }, { { "marais", "marsh" }, "roseaux" },
}
for id, info in C.ITEMS do
	if string.sub(id, 1, 4) == "ame_" then
		local n = low(info.name) .. " " .. id
		local h = hash(id)
		local trait = "couronne"
		for _, t in TRAIT do
			if has(n, table.unpack(t[1])) then
				trait = t[2]
				break
			end
		end
		local lueur = ({ rgb(160, 90, 255), rgb(90, 200, 255), rgb(120, 255, 160), rgb(255, 120, 90), rgb(255, 210, 90) })[h % 5 + 1]
		icon(id, "ame", function(add)
			add(v(1.0, 0.25, 1.0), cf(0, 0.12, 0), rgb(60, 56, 64), M.Slate, "cyl", UP) -- socle
			add(v(0.7, 0.3, 0.7), cf(0, 0.38, 0), rgb(80, 74, 86), M.Slate, "cyl", UP)
			local orbe = add(v(1.15, 1.15, 1.15), cf(0, 1.15, 0), lueur, M.Glass, "ball", nil, "Orbe")
			orbe.Transparency = 0.35
			add(v(0.5, 0.5, 0.5), cf(0, 1.15, 0), lueur, M.Neon, "ball", nil, "Lueur") -- cœur lumineux (magie)
			local top = cf(0, 1.75, 0)
			if trait == "couronne" then
				add(v(0.9, 0.18, 0.9), top, rgb(214, 172, 70), M.Metal, "cyl", UP)
				for i = 0, 4 do
					local a = i / 5 * math.pi * 2
					add(v(0.14, 0.3, 0.14), top * cf(math.cos(a) * 0.38, 0.2, math.sin(a) * 0.38), rgb(214, 172, 70), M.Metal, "wedge")
				end
			elseif trait == "champignon" then
				add(v(0.18, 0.4, 0.18), top * cf(0, 0.1, 0), rgb(230, 220, 200), M.SmoothPlastic, "cyl", UP)
				add(v(0.9, 0.45, 0.9), top * cf(0, 0.35, 0), rgb(180, 50, 50), M.SmoothPlastic, "ball")
			elseif trait == "glace" or trait == "eclats" then
				for i = 0, 3 do
					local a = i / 4 * math.pi * 2
					add(v(0.2, 0.6, 0.2), top * cf(math.cos(a) * 0.3, 0.15, math.sin(a) * 0.3) * ANG(math.sin(a) * 0.4, 0, -math.cos(a) * 0.4), trait == "glace" and rgb(200, 240, 255) or rgb(220, 230, 240), M.Glass, "wedge").Transparency = 0.2
				end
			elseif trait == "ailes" then
				for _, s in { -1, 1 } do
					add(v(0.9, 0.06, 0.5), top * cf(s * 0.6, -0.2, 0) * ANG(0, 0, rad(s * 25)), rgb(90, 120, 150), M.SmoothPlastic, "wedge")
				end
			elseif trait == "epines" or trait == "roseaux" or trait == "epi" then
				for i = -1, 1 do
					add(v(0.08, 0.7, 0.08), top * cf(i * 0.25, 0.2, 0) * ANG(0, 0, rad(i * 15)), trait == "epines" and rgb(80, 110, 50) or rgb(190, 170, 90), M.Wood)
				end
			elseif trait == "crocs" or trait == "oreilles" then
				for _, s in { -1, 1 } do
					add(v(0.16, 0.5, 0.16), top * cf(s * 0.3, -0.05, -0.2) * ANG(0, 0, rad(s * 15 + 180)), rgb(236, 230, 210), M.SmoothPlastic, "wedge")
				end
			elseif trait == "tentacules" then
				for i = 0, 3 do
					local a = i / 4 * math.pi * 2
					add(v(0.14, 0.7, 0.14), cf(math.cos(a) * 0.55, 0.8, math.sin(a) * 0.55) * ANG(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5), rgb(90, 50, 110), M.SmoothPlastic, "cyl", UP)
				end
			elseif trait == "carapace" then
				add(v(0.9, 0.35, 0.7), top * cf(0, 0.05, 0), rgb(40, 110, 90), M.Metal, "ball")
			elseif trait == "goutte" then
				add(v(0.5, 0.6, 0.5), top * cf(0, 0.15, 0), rgb(90, 200, 110), M.Glass, "ball").Transparency = 0.25
			else -- roc
				add(v(0.6, 0.45, 0.55), top * cf(0, 0.1, 0) * ANG(0.3, 0.4, 0.2), rgb(120, 116, 110), M.Slate)
			end
		end)
	end
end

-- ----------------------------------------------------------------- PRISES DE CRÉATURES
local PARTIE = {
	{ { "croc", "dent", "fang" }, "croc" }, { { "griffe", "serre", "claw" }, "griffe" }, { { "ecaille", "scale" }, "ecaille" },
	{ { "plume", "feather", "duvet" }, "plume" }, { { "corne", "ramure", "bois de", "horn", "antler" }, "corne" },
	{ { "dard", "aiguillon", "stinger" }, "dard" }, { { "venin", "glande", "poison" }, "venin" }, { { "defense", "tusk" }, "defense" },
	{ { "aile", "elytre", "wing" }, "aile" }, { { "carapace", "coquille", "shell" }, "carapace" }, { { "oeil", "eye" }, "oeil" },
	{ { "gelee", "slime", "mucus" }, "gelee" }, { { "eclat", "cristal", "shard", "givre" }, "cristal" },
	{ { "essence", "poussiere", "ame", "ectoplasme", "brume" }, "essence" }, { { "peau", "cuir", "fourrure", "toison", "pelage", "hide" }, "peau" },
	{ { "os", "crane", "bone" }, "os" }, { { "masque", "insigne", "amulette", "talisman" }, "masque" }, { { "coeur", "heart" }, "coeur" },
	{ { "seve", "ecorce", "ronce", "racine", "spore", "champignon" }, "seve" }, { { "oreille", "ear" }, "oreille" }, { { "queue", "tail" }, "queue" },
	{ { "tentacule", "pince", "patte", "crochet" }, "pince" }, { { "ecu", "ecusson", "bouclier" }, "ecu" }, { { "faux", "lame" }, "lame" },
	{ { "carquois" }, "carquois" }, { { "grimoire", "avis", "sceau" }, "ecrit" }, { { "turban", "cape", "collet" }, "tissu" },
	{ { "fragment", "noyau" }, "cristal" }, { { "bosse" }, "peau" }, { { "paille" }, "crin" }, { { "crin", "criniere", "poil" }, "crin" }, { { "pierre", "roc", "cœur de golem" }, "pierre" },
}
local function prisePalette(n, h)
	if has(n, "glace", "givre", "neige", "blizzard", "polaire") then return rgb(190, 230, 245) end
	if has(n, "feu", "braise", "flamme", "lave") then return rgb(230, 110, 40) end
	if has(n, "ombre", "nuit", "maudit", "spectre") then return rgb(90, 70, 120) end
	if has(n, "venin", "poison", "marais", "slime") then return rgb(110, 170, 60) end
	if has(n, "or", "dore", "royal") then return rgb(220, 180, 60) end
	return ({ rgb(226, 214, 190), rgb(150, 110, 80), rgb(120, 120, 130), rgb(170, 140, 100) })[h % 4 + 1]
end
for id, info in C.ITEMS do
	if string.sub(id, 1, 6) == "prise_" then
		local n = low(info.name)
		local h = hash(id)
		local partie = "os"
		for _, t in PARTIE do
			if has(n, table.unpack(t[1])) then
				partie = t[2]
				break
			end
		end
		local c = prisePalette(n, h)
		icon(id, "prise", function(add)
			-- petit socle de cuir façon « trophée de chasse » : la pièce posée dessus
			add(v(0.9, 0.06, 0.6), cf(0.2, 0.0, 0.3), rgb(90, 60, 38), M.Fabric) -- petit carré de cuir sous la prise
			local o = cf(0, 0.15, 0)
			if partie == "croc" or partie == "defense" then
				local big = partie == "defense"
				for i = (big and 0 or -1), (big and 0 or 1) do
					local s = big and 1.6 or (i == 0 and 1.0 or 0.75)
					local at = o * cf(i * 0.34, s * 0.45, 0) * ANG(0, 0, rad(big and -30 or i * 12))
					add(v(0.3 * s, s, 0.3 * s), at, rgb(240, 234, 214), M.SmoothPlastic, "ball") -- corps du croc
					add(v(0.16 * s, 0.4 * s, 0.16 * s), at * cf(0, s * 0.55, 0), rgb(250, 246, 232), M.SmoothPlastic, "ball") -- pointe
				end
				add(v(0.9, 0.12, 0.12), o * cf(0, 0.05, -0.2), rgb(90, 60, 40), M.Fabric) -- lien de cuir
			elseif partie == "griffe" then
				for i = -1, 1 do
					add(v(0.18, 0.9, 0.3), o * cf(i * 0.32, 0.45, 0) * ANG(rad(-30), 0, rad(i * 8)), shade(c, 0.6), M.SmoothPlastic, "wedge")
				end
				add(v(1.0, 0.3, 0.5), o * cf(0, 0.12, 0.3), c, M.Fabric)
			elseif partie == "ecaille" or partie == "carapace" then
				for i = 0, (partie == "ecaille" and 4 or 0) do
					add(v(0.62, 0.1, 0.62), o * cf(-0.3 + (i % 3) * 0.3, 0.06 + math.floor(i / 3) * 0.06, -0.2 + math.floor(i / 3) * 0.35) * ANG(rad(-10), rad(45), 0), c, M.SmoothPlastic, partie == "ecaille" and "corner" or nil)
				end
				if partie == "carapace" then
					add(v(1.3, 0.6, 1.0), o * cf(0, 0.3, 0), c, M.SmoothPlastic, "ball")
					add(v(0.08, 0.62, 1.02), o * cf(0, 0.32, 0), shade(c, 0.6), M.SmoothPlastic)
				end
			elseif partie == "plume" or partie == "aile" then
				local tilt = o * cf(0, 0.45, 0) * ANG(0, rad(30), rad(-35))
				add(v(0.06, 1.9, 0.06), tilt, rgb(236, 230, 214), M.SmoothPlastic) -- rachis
				if partie == "aile" then
					add(v(0.12, 1.4, 1.0), tilt * cf(0, 0.2, 0.4), c, M.Fabric, "wedge")
				else
					add(v(0.06, 1.5, 0.55), tilt * cf(0, 0.15, 0), c, M.Fabric, "ball") -- vexille en ellipse
					add(v(0.05, 0.5, 0.3), tilt * cf(0, -0.7, 0.05), shade(c, 1.15), M.Fabric, "ball") -- duvet
				end
			elseif partie == "corne" then
				for k = 0, 3 do
					add(v(0.32 - k * 0.06, 0.4, 0.32 - k * 0.06), o * cf(k * 0.14, 0.2 + k * 0.32, 0) * ANG(0, 0, rad(-10 - k * 12)), shade(c, 1 - k * 0.08), M.SmoothPlastic, "cyl", UP)
				end
			elseif partie == "dard" then
				add(v(0.3, 1.2, 0.3), o * cf(0, 0.25, 0) * ANG(rad(-70), 0, 0), shade(c, 0.5), M.SmoothPlastic, "wedge")
				add(v(0.36, 0.36, 0.36), o * cf(0, 0.25, 0.5), rgb(120, 180, 40), M.Glass, "ball")
			elseif partie == "venin" or partie == "gelee" or partie == "coeur" then
				local col = partie == "venin" and rgb(120, 190, 40) or (partie == "coeur" and rgb(170, 30, 50) or c)
				add(v(0.9, 0.8, 0.9), o * cf(0, 0.42, 0), col, partie == "coeur" and M.SmoothPlastic or M.Glass, "ball").Transparency = partie == "coeur" and 0 or 0.2
				add(v(0.3, 0.3, 0.3), o * cf(0.4, 0.2, 0.3), col, M.Glass, "ball")
			elseif partie == "oeil" then
				add(v(0.9, 0.9, 0.9), o * cf(0, 0.45, 0), rgb(240, 236, 220), M.SmoothPlastic, "ball")
				add(v(0.5, 0.5, 0.2), o * cf(0, 0.45, -0.38), c, M.SmoothPlastic, "cyl", ANG(0, rad(90), 0))
				add(v(0.24, 0.24, 0.1), o * cf(0, 0.45, -0.46), rgb(20, 20, 24), M.SmoothPlastic, "cyl", ANG(0, rad(90), 0))
			elseif partie == "cristal" or partie == "pierre" then
				for i = 0, 2 do
					add(v(0.34, 0.9 - i * 0.2, 0.34), o * cf(-0.25 + i * 0.25, 0.4, (i % 2) * 0.2) * ANG(0, i, rad(-12 + i * 12)), c, partie == "cristal" and M.Glass or M.Slate, "wedge")
				end
			elseif partie == "essence" then
				add(v(0.5, 0.8, 0.5), o * cf(0, 0.4, 0), rgb(236, 224, 196), M.Glass, "cyl", UP).Transparency = 0.3
				add(v(0.38, 0.5, 0.38), o * cf(0, 0.35, 0), c, M.Neon, "ball") -- volute captive (magie)
				add(v(0.4, 0.14, 0.4), o * cf(0, 0.86, 0), rgb(150, 100, 60), M.Wood, "cyl", UP)
			elseif partie == "peau" or partie == "crin" then
				add(v(1.4, 0.14, 1.0), o * cf(0, 0.1, 0) * ANG(0, rad(10), 0), c, M.Fabric)
				add(v(1.4, 0.3, 0.3), o * cf(0, 0.2, 0.45), shade(c, 0.85), M.Fabric, "cyl") -- roulée
				add(v(1.5, 0.08, 0.08), o * cf(0, 0.36, 0.45), rgb(90, 60, 40), M.Fabric)
			elseif partie == "masque" then
				local face = o * cf(0, 0.65, 0) * ANG(rad(-20), 0, 0)
				add(v(1.0, 1.25, 0.3), face, c, M.Wood, "ball") -- visage ovale
				for _, s in { -1, 1 } do
					add(v(0.26, 0.16, 0.1), face * cf(s * 0.22, 0.15, -0.14), rgb(20, 20, 24), M.SmoothPlastic, "ball") -- yeux
				end
				add(v(0.12, 0.3, 0.1), face * cf(0, -0.05, -0.15), shade(c, 0.75), M.Wood) -- nez
				add(v(0.7, 0.14, 0.12), face * cf(0, 0.48, -0.1), rgb(200, 160, 60), M.Metal) -- bandeau orné
			elseif partie == "seve" then
				add(v(0.2, 1.1, 0.2), o * cf(0, 0.2, 0) * ANG(rad(-80), rad(20), 0), rgb(110, 80, 50), M.Wood)
				add(v(0.5, 0.4, 0.5), o * cf(0.3, 0.3, 0), c, M.Glass, "ball").Transparency = 0.2
			elseif partie == "oreille" or partie == "queue" or partie == "pince" then
				add(v(0.5, 1.1, 0.14), o * cf(0, 0.4, 0) * ANG(rad(-60), 0, rad(15)), c, M.Fabric, "wedge")
				add(v(0.3, 0.6, 0.14), o * cf(0.3, 0.3, 0.2) * ANG(rad(-60), 0, rad(-25)), shade(c, 0.8), M.Fabric, "wedge")
			elseif partie == "ecu" then
				add(v(1.0, 1.2, 0.14), o * cf(0, 0.65, 0) * ANG(rad(-15), 0, 0), c, M.Metal)
				add(v(1.0, 0.5, 0.14), o * cf(0, 0.0, 0.14) * ANG(rad(-15), 0, rad(180)), c, M.Metal, "wedge")
				add(v(0.16, 1.1, 0.18), o * cf(0, 0.55, -0.02) * ANG(rad(-15), 0, 0), shade(c, 0.6), M.Metal)
			elseif partie == "lame" then
				add(v(0.12, 1.0, 0.4), o * cf(0, 0.5, 0) * ANG(rad(-40), 0, 0), rgb(200, 205, 210), M.Metal, "wedge")
				add(v(0.14, 0.7, 0.14), o * cf(0, 0.3, 0.5) * ANG(rad(-40), 0, 0), rgb(110, 80, 50), M.Wood)
			elseif partie == "carquois" then
				add(v(1.3, 0.5, 0.5), o * cf(0, 0.3, 0) * ANG(0, rad(20), rad(20)), rgb(120, 76, 44), M.Fabric, "cyl")
				for i = -1, 1 do
					add(v(0.5, 0.06, 0.2), o * cf(0.75, 0.6 + i * 0.1, i * 0.12) * ANG(0, rad(20), rad(20)), c, M.Fabric, "wedge")
				end
			elseif partie == "ecrit" then
				add(v(1.4, 0.4, 0.4), o * cf(0, 0.22, 0), rgb(226, 210, 176), M.SmoothPlastic, "cyl")
				add(v(0.3, 0.3, 0.1), o * cf(0, 0.22, -0.24), c, M.SmoothPlastic, "cyl", ANG(0, rad(90), 0))
			elseif partie == "tissu" then
				add(v(1.3, 0.12, 1.0), o * cf(0, 0.08, 0) * ANG(0, rad(15), 0), c, M.Fabric)
				add(v(0.9, 0.4, 0.4), o * cf(0, 0.3, 0.2), shade(c, 0.85), M.Fabric, "cyl")
			else -- os
				local axe = o * cf(0, 0.22, 0) * ANG(0, rad(30), rad(8))
				add(v(1.5, 0.26, 0.26), axe, rgb(236, 230, 214), M.SmoothPlastic, "cyl")
				for _, s in { -1, 1 } do
					add(v(0.36, 0.36, 0.36), axe * cf(s * 0.78, 0, 0.12), rgb(236, 230, 214), M.SmoothPlastic, "ball")
					add(v(0.36, 0.36, 0.36), axe * cf(s * 0.78, 0, -0.12), rgb(226, 220, 204), M.SmoothPlastic, "ball")
				end
			end
			-- étiquette nouée : la couleur rappelle la créature
			add(v(0.3, 0.04, 0.2), cf(0.6, 0.15, 0.45), shade(c, 0.9), M.Fabric)
		end)
	end
end

local l = {}
for k, n in fam do
	table.insert(l, k .. " : " .. n)
end
table.sort(l)
return count .. " miniatures refaites — " .. table.concat(l, " · ")
