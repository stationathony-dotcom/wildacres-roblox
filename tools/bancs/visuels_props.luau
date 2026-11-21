-- Banc de lecture en Édition. Tous les modèles temporaires restent hors du DataModel.
-- Avec tools/sync.py : assert(loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34873/banc?f=visuels_props")))()
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local ATTR = "BancVisuelsProps"
local ECART, SOL = 0.15, 0.10
local EPS = 1e-6
local GRAVITE = { "ERREURS", "À CORRIGER", "À EXAMINER" }

local function vecteur(v)
	return string.format("%.2f × %.2f × %.2f", v.X, v.Y, v.Z)
end

local function plusGrand(v)
	return math.max(v.X, v.Y, v.Z)
end

local function plusPetit(v)
	return math.min(v.X, v.Y, v.Z)
end

local function chargerSource(module, environnement)
	local chunk = assert(loadstring(module.Source, "=" .. module.Name))
	if environnement then
		setfenv(chunk, setmetatable(environnement, { __index = getfenv(chunk) }))
	end
	return chunk()
end

-- Enveloppes orientées, exprimées dans le repère de pose. Un mesh, un coin ou un cylindre
-- peuvent remplir seulement une partie de leur boîte : l'écart des boîtes est alors une borne basse.
local function boite(piece, repere)
	local cf = repere:ToObjectSpace(piece.CFrame)
	local axes = { cf.XVector, cf.YVector, cf.ZVector }
	local h = piece.Size / 2
	local demi = { h.X, h.Y, h.Z }
	local etendue = Vector3.zero
	local alignee = true
	for i, a in axes do
		local absolu = a:Abs()
		etendue += absolu * demi[i]
		alignee = alignee and plusGrand(absolu) >= 1 - EPS
	end
	local centre = cf.Position
	return { cf = cf, axes = axes, h = h, alignee = alignee, bas = centre - etendue, haut = centre + etendue }
end

local function sommets(b)
	if not b.sommets then
		local liste = {}
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					table.insert(liste, b.cf:PointToWorldSpace(Vector3.new(x, y, z) * b.h))
				end
			end
		end
		b.sommets = liste
	end
	return b.sommets
end

local ARETES = {
	{1, 2}, {3, 4}, {5, 6}, {7, 8}, {1, 3}, {2, 4}, {5, 7}, {6, 8}, {1, 5}, {2, 6}, {3, 7}, {4, 8},
}

local function distanceSommet(b, point)
	return (b.cf:PointToObjectSpace(point):Abs() - b.h):Max(Vector3.zero).Magnitude
end

local function rayon(b, axe)
	local proj = b.cf:VectorToObjectSpace(axe):Abs()
	return proj:Dot(b.h)
end

local function separees(a, b)
	local delta = b.cf.Position - a.cf.Position
	local function separe(axe)
		return math.abs(delta:Dot(axe)) > rayon(a, axe) + rayon(b, axe) + EPS
	end
	for _, axe in a.axes do
		if separe(axe) then return true end
	end
	for _, axe in b.axes do
		if separe(axe) then return true end
	end
	for _, axeA in a.axes do
		for _, axeB in b.axes do
			if separe(axeA:Cross(axeB)) then return true end
		end
	end
	return false
end

-- Couples sommet/face et intérieurs d'arêtes. Les extrémités sont déjà couvertes par les sommets.
local function distanceBoites(a, b, meilleur)
	local borne = (a.bas - b.haut):Max(b.bas - a.haut):Max(Vector3.zero).Magnitude
	if borne >= meilleur or (a.alignee and b.alignee) then return borne end
	if borne < EPS and not separees(a, b) then return 0 end
	local sa, sb = sommets(a), sommets(b)
	local distance = meilleur
	for i = 1, 8 do
		distance = math.min(distance, distanceSommet(a, sb[i]), distanceSommet(b, sa[i]))
	end
	if distance <= ECART then return distance end
	for _, ea in ARETES do
		local p, u = sa[ea[1]], sa[ea[2]] - sa[ea[1]]
		for _, eb in ARETES do
			local q, v = sb[eb[1]], sb[eb[2]] - sb[eb[1]]
			local normale = u:Cross(v)
			local carre = normale:Dot(normale)
			if carre <= 1e-16 then continue end
			local delta = q - p
			local t = delta:Cross(v):Dot(normale) / carre
			local s = delta:Cross(u):Dot(normale) / carre
			if t >= 0 and t <= 1 and s >= 0 and s <= 1 then
				distance = math.min(distance, (delta + v * s - u * t).Magnitude)
			end
		end
	end
	return distance
end

local function visible(p)
	if p.Transparency < 1 then return true end
	-- Un support invisible peut porter l'aspect visible d'un panneau ou d'une décalcomanie.
	for _, enfant in p:GetChildren() do
		if enfant:IsA("Decal") and enfant.Transparency < 1 then return true end
		if enfant:IsA("SurfaceGui") and enfant.Enabled then return true end
	end
	return false
end

local function utile(p, pivot, racineConstruction)
	if p == pivot or p == racineConstruction or p.CanCollide or p.CanQuery or p.CanTouch then return true end
	if #CS:GetTags(p) > 0 or next(p:GetAttributes()) then return true end
	for _, enfant in p:GetDescendants() do
		if enfant:IsA("Attachment") or enfant:IsA("Light") or enfant:IsA("ParticleEmitter")
			or enfant:IsA("Fire") or enfant:IsA("Smoke") or enfant:IsA("Sparkles")
			or enfant:IsA("ProximityPrompt") or enfant:IsA("ClickDetector") or enfant:IsA("GuiBase2d") then
			return true
		end
	end
	return false
end

local ANGLAIS = {
	part = true, wedgepart = true, cornerwedgepart = true, meshpart = true, trusspart = true,
	wood = true, plank = true, stone = true, rock = true, wall = true, floor = true, roof = true,
	window = true, door = true, handle = true, frame = true, beam = true, pole = true, post = true,
	-- « front » retiré : c'est aussi un mot français (le front du crâne de créature)
	top = true, bottom = true, back = true, left = true, right = true, wheel = true,
	seat = true, leg = true, leaf = true, leaves = true, flower = true, flame = true, light = true,
	glass = true, cloth = true, banner = true, sign = true, hinge = true, trim = true,
}
local DECOR_FIN = {
	motif = true, galon = true, frange = true, toile = true, rideau = true, tenture = true,
	banniere = true, ["bannière"] = true, drapeau = true, feuille = true, feuillage = true, fleur = true,
	gravure = true, rivet = true, clou = true, tige = true, herbe = true,
}

local function motDeNom(nom, dictionnaire)
	local normal = nom:gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2"):lower()
	for mot in normal:gmatch("[a-zàâäéèêëîïôöùûüç]+") do
		if dictionnaire[mot] then return mot end
	end
	return nil
end

local function enveloppe(racine, repere)
	local bas, haut = Vector3.one * math.huge, -Vector3.one * math.huge
	local geometries, objets = {}, racine:GetDescendants()
	if racine:IsA("BasePart") then table.insert(objets, 1, racine) end
	for _, p in objets do
		if p:IsA("BasePart") and visible(p) then
			local b = boite(p, repere)
			geometries[p] = b
			bas, haut = bas:Min(b.bas), haut:Max(b.haut)
		end
	end
	return bas, haut, geometries, objets
end

-- Cat_* n'a pas de dimensions déclarées. Ces fourchettes portent sur le plus grand axe, en studs.
local GABARITS_CAT = {
	coffret = { 0.5, 2.5 }, bougie = { 0.5, 2 }, pot = { 0.5, 2.5 }, vase = { 0.5, 3 },
	pichet = { 0.5, 2.5 }, lanterne_murale = { 0.5, 2.5 }, crane = { 0.5, 3 },
	cabane = { 6, 12 }, grange = { 8, 17 }, grenier = { 5, 13 }, enclos = { 6, 12 },
	grandetable = { 5, 9 }, roue = { 5, 10 }, table = { 2.5, 5 }, chaise = { 2.5, 4 },
}
-- Écarts voulus. Chaque hauteur reste contrôlée avec la même tolérance que le plan du sol.
local BAS_ATTENDUS = {
	Cat_wall_lantern = 2.55, -- Shop.wallMount : potence contre le mur, pivot au niveau du sol.
	["Modeles/Toit_Chaume"] = 6.925, -- Le toit hérité se pose au-dessus des murs à partir d'un pivot au sol.
	["Modeles/Chateau"] = -17, -- Fondation profonde pour accrocher la pente.
	["Modeles/Puits"] = -1.1, -- Fondation sous la margelle.
	["Modeles/Embarcadere"] = -1, -- Pieux sous la surface de l'eau.
	["Modeles/Champ_Ble"] = -0.2, -- La planche de terre s'encastre dans le terrain.
	["Modeles/Sol_Laboure"] = -0.1, -- Les sillons restent visibles tandis que la terre se fond dans le terrain.
	["Modeles/Filon_Charbon"] = -0.4,
	["Modeles/Filon_Cuivre"] = -0.4,
	["Modeles/Filon_Fer"] = -0.4,
	["Modeles/Filon_Or"] = -0.4,
	["Modeles/Rocher"] = -0.4, -- Les pierres des filons et du rocher émergent de terre.
	["Modeles/Touffe"] = -0.2, -- Racines et pieds des brins dans la terre.
	["Modeles/Roseaux"] = -0.51, -- RegionPlan les place au niveau de l'eau.
}

-- Éléments autonomes, admis seulement si leur pied atteint le sol ou l'eau.
local APPUIS_INDEPENDANTS = {
	Cat_hearth = { Pierre = true }, -- Pierres espacées autour du foyer.
	["Modeles/Champ_Ble"] = { Botte = true }, -- Botte au sol à côté de la clôture.
	["Modeles/Tableau_Quetes"] = { Caisse = true }, -- Caisse posée devant le panneau.
	["Modeles/Roseaux"] = { Tige = true },
	["Modeles/Touffe"] = { Brin = true },
}

-- Le pivot et les 88 pieds récoltables expliquent à eux seuls une grande partie du champ.
-- Les budgets des bâtiments en colombage et du château couvrent la charpente, les pièces
-- jouables et les tours. Ils restent inférieurs aux nombres du rapport du 21/11.
local BUDGETS = {
	Auberge = 238, Boutique = 140, Bureau_Sherif = 67, Champ_Ble = 110,
	Chapelle = 67, Chateau = 193, Maison_A = 217, Maison_B = 215, Maison_C = 134, Taverne = 250,
}

-- `size` décrit le volume de grille. Les volets dépassent de 0,10 sur une seule face et le
-- toit conique est une pile d'anneaux dont la base fait 3,71 de diamètre (anneaux + léger chevauchement).
local function gabaritConstruction(bloc)
	if bloc.shapeId == "volets" then return bloc.size + Vector3.new(0, 0, 0.1) end
	if bloc.shapeId == "toitconique" then
		local diametre = math.max(0.3, bloc.size.X * (1 - 0.5 / 7))
		return Vector3.new(diametre, bloc.size.Y + 0.02, diametre)
	end
	return bloc.size
end

local function echelle(attendu, plage, boiteMesuree, construction)
	if not attendu then
		local max = plusGrand(boiteMesuree)
		return max < plage[1] or max > plage[2], string.format("axe max attendu %.2f–%.2f", plage[1], plage[2])
	end
	local delta = (boiteMesuree - attendu):Abs()
	local marge = (attendu * (construction and 0.08 or 0.15)):Max(Vector3.one * (construction and 0.15 or 0.25))
	return plusGrand(delta - marge) > EPS, "attendu " .. vecteur(attendu)
end

local function relever(racine, fiche, signaler, mesures)
	local modele = racine:IsA("Model") and racine or nil
	local pivot = modele and modele.PrimaryPart
	local pivotReel = racine:GetPivot()
	local repere = pivotReel
	if fiche.construction then
		-- Batir pose une pièce au centre de son volume nominal, y = hauteur / 2 au-dessus du plan.
		repere = CFrame.new()
	elseif not pivot then
		signaler(1, "PrimaryPart absente", "aucune")
	end
	local bas, haut, geometries, objets = enveloppe(racine, repere)
	local presents, neons, lumieres = {}, {}, {}
	local n = 0
	for _, p in objets do
		if p:IsA("Light") then table.insert(lumieres, p) end
		if not p:IsA("BasePart") then continue end
		n += 1
		local b = geometries[p]
		local titre = string.format("%s #%d", p.Name, n)
		local min, max = plusPetit(p.Size), plusGrand(p.Size)
		if min <= 0.001 then
			signaler(1, "pièce de taille nulle ou quasi nulle", titre .. " : " .. vecteur(p.Size))
		elseif max > fiche.limitePiece then
			signaler(2, "pièce géante", titre .. " : " .. vecteur(p.Size) .. " (seuil " .. fiche.limitePiece .. ")")
		end
		if not b then
			if not utile(p, pivot, fiche.construction and racine) then
				signaler(3, "pièce transparente sans fonction apparente", titre .. " : Transparency = 1")
			end
			continue
		end
		table.insert(presents, { boite = b, titre = titre, piece = p })
		if motDeNom(p.Name, ANGLAIS) then
			signaler(3, "nom anglais de pièce visible", titre)
		end
		local h, s, v = p.Color:ToHSV()
		local chaud = h <= 0.17 or h >= 0.94
		local emission = p.Material == Enum.Material.Neon or CS:HasTag(p, "LumiereNuit")
		if (not chaud and s >= 0.74 and v >= 0.83) or (chaud and not emission and s >= 0.85 and v >= 0.94) then
			signaler(3, "couleur vive à revoir", string.format("%s : #%s · T %.0f° S %.0f%% V %.0f%%", titre, p.Color:ToHex(), h * 360, s * 100, v * 100))
		end
		if emission or CS:HasTag(p, "Fenetre") then table.insert(neons, presents[#presents]) end
		-- Une paroi, un vitrage ou une planche de construction mince peut devoir bloquer le passage.
		if p.CanCollide and min <= 0.15 and not fiche.construction
			and (p.Material == Enum.Material.Fabric or motDeNom(p.Name, DECOR_FIN) or CS:HasTag(p, "Feuillage")) then
			signaler(3, "décor fin avec collision", string.format("%s : CanCollide, ép. %.3f", titre, min))
		end
	end
	local budget = fiche.budget or 60
	if n > budget then signaler(3, "modèle coûteux", string.format("%d pièces, seuil %d", n, budget)) end
	if #presents == 0 then
		signaler(1, "aucune géométrie visible", n .. " pièces")
		return
	end
	local taille = haut - bas
	local horsGabarit, attendu = echelle(fiche.attendu, fiche.plage, taille, fiche.construction)
	if horsGabarit then signaler(2, "boîte hors gabarit", vecteur(taille) .. " · " .. attendu) end
	local ecart = bas.Y - (BAS_ATTENDUS[fiche.nom] or 0)
	local basPivot = fiche.construction and bas.Y - pivotReel.Position.Y or bas.Y
	if math.abs(ecart) > SOL + EPS then
		local defaut = ecart > 0 and "flotte au-dessus du plan de pose" or "s’enfonce sous le plan de pose"
		local detail = string.format("bas/pivot %+.2f · écart au plan attendu %+.2f stud", basPivot, ecart)
		signaler(2, defaut, detail)
	end
	table.insert(mesures, string.format("%s · %s (%s) · bas/pivot %+.2f · écart au plan %+.2f · %d pièces",
		fiche.nom, vecteur(taille), attendu, basPivot, ecart, n))

	local proches, comparaisons = {}, 0
	local appuis = APPUIS_INDEPENDANTS[fiche.nom]
	for i, a in presents do
		local minimum = math.huge
		if proches[i] then continue end
		if appuis and appuis[a.piece.Name] and a.boite.bas.Y <= SOL + EPS then continue end
		for j, b in presents do
			if i == j then continue end
			minimum = math.min(minimum, distanceBoites(a.boite, b.boite, minimum))
			comparaisons += 1
			if comparaisons % 512 == 0 then task.wait() end
			if minimum <= ECART + EPS then
				proches[j] = true
				break
			end
		end
		if #presents > 1 and minimum > ECART + EPS then
			signaler(2, "pièce détachée", string.format("%s : %.3f stud de la boîte la plus proche", a.titre, minimum))
		end
	end

	local associes = {}
	for _, l in lumieres do
		local porteur = l.Parent
		if porteur and porteur:IsA("Attachment") then porteur = porteur.Parent end
		local b = porteur and porteur:IsA("BasePart") and (geometries[porteur] or boite(porteur, repere))
		local associe = false
		for i, e in neons do
			if e.piece == porteur or (b and distanceBoites(b, e.boite, 0.35 + EPS) <= 0.35) then
				associes[i], associe = true, true
			end
		end
		-- Un feu de camp possède une flamme en particules portée par une pièce invisible.
		local feu = porteur and porteur:FindFirstChildWhichIsA("Fire")
		if not associe and not (feu and feu.Enabled) then
			signaler(3, "lumière sans Neon visible à proximité", string.format("%s sur %s · portée %.1f", l.Name, porteur and porteur.Name or "?", l.Range))
		end
	end
	for i, e in neons do
		if not associes[i] and e.piece.Material == Enum.Material.Neon and not CS:HasTag(e.piece, "Fenetre") then
			signaler(3, "Neon hors d’un luminaire", e.titre .. " : aucune Light à 0,35 stud")
		end
	end
end

local function references(outils, bac, instances)
	local module = assert(outils and outils:FindFirstChild("ConstruireModeles"), "module ConstruireModeles absent")
	local fabrique = chargerSource(module, {
		game = { GetService = function(_, service)
			if service == "ServerStorage" then return bac end
			assert(service == "CollectionService", service)
			return { AddTag = function() end }
		end },
		Instance = { new = function(classe)
			if #instances % 128 == 0 then task.wait() end
			local instance = Instance.new(classe)
			table.insert(instances, instance)
			return instance
		end },
	})
	fabrique.tout()
	local tailles = {}
	for i, m in bac.Modeles:GetChildren() do
		local bas, haut, visibles = enveloppe(m, m:GetPivot())
		if next(visibles) then tailles[m.Name] = haut - bas end
		if i % 8 == 0 then task.wait() end
	end
	return tailles
end

local function personnages(config, systemes)
	local exclus = { Cheval = true, Biche = true, PNJ_Base = true }
	local function ajouter(registre)
		for _, info in registre or {} do
			if info.model then exclus[info.model] = true end
		end
	end
	ajouter(config.ANIMALS)
	ajouter(config.UNITS)
	for _, nom in { "Enemies", "Bestiaire" } do
		local module = systemes:FindFirstChild(nom)
		if module then ajouter(chargerSource(module).KINDS) end
	end
	return exclus
end

local function auditer(bac, instances)
	local shared = assert(game.ReplicatedStorage:FindFirstChild("Shared")):Clone()
	shared.Parent = bac
	local config = require(shared.Config)
	local systemes = game.ServerScriptService.Systemes
	local exclus = personnages(config, systemes)
	local batir = chargerSource(systemes.Batir)
	batir.init({ Config = config, Interact = { onAction = function() end } })
	local avertissements, ecarts, mesures, ignores = {}, {}, {}, {}
	local ok, tailles = pcall(references, SS:FindFirstChild("OutilsDev"), bac, instances)
	if not ok then
		table.insert(avertissements, "Références de source indisponibles · " .. tostring(tailles))
		tailles = {}
	end

	local total, lisibles = 0, 0
	local function traiter(fiche, construire)
		total += 1
		if total % 8 == 0 then task.wait() end
		local function signaler(gravite, defaut, valeur)
			table.insert(ecarts, { gravite, fiche.nom, defaut, valeur })
		end
		local racine
		local succes, erreur = pcall(function()
			racine = assert(construire(), "aucun modèle produit (constructeur ou Archivable)")
			relever(racine, fiche, signaler, mesures)
			lisibles += 1
		end)
		if racine then racine:Destroy() end
		if not succes then signaler(1, "lecture impossible", tostring(erreur)) end
	end

	local modeles = SS:FindFirstChild("Modeles")
	if modeles then
		local function parcourir(dossier, chemin)
			for _, objet in dossier:GetChildren() do
				local nom = chemin .. objet.Name
				if objet:IsA("Folder") then
					parcourir(objet, nom .. "/")
				elseif objet:IsA("Model") then
					if exclus[objet.Name] or objet.Name:match("^Bete_") or objet.Name:match("^PNJ_")
						or objet.Name:match("^Soldat_") or objet:FindFirstChildWhichIsA("Humanoid", true) then
						table.insert(ignores, nom)
						continue
					end
					local attendu = objet:GetAttribute("TailleAttendue")
					if typeof(attendu) ~= "Vector3" then attendu = tailles[objet.Name] end
					traiter({ nom = nom, attendu = attendu, plage = { 0.10, 64 }, budget = BUDGETS[objet.Name],
						limitePiece = math.max(48, attendu and plusGrand(attendu) * 1.15 or 0) }, function()
						return objet:Clone()
					end)
				end
			end
		end
		parcourir(modeles, "Modeles/")
	else
		table.insert(ecarts, { 1, "Modeles", "dossier absent", "ServerStorage.Modeles introuvable" })
	end
	for nom, spec in config.Catalogue.MODELS do
		traiter({ nom = nom, plage = GABARITS_CAT[spec.arch] or { 0.25, 16 },
			limitePiece = 16 }, function()
			return config.Catalogue.build(nom)
		end)
	end

	local supports = Instance.new("Folder")
	supports.Parent = bac
	local region = { folder = supports, state = {} }
	local formes = {}
	for _, id in config.BLOCK_ORDER do
		local bloc = config.BLOCKS[id]
		formes[bloc.shapeId] = true
		traiter({ nom = "Construction/" .. id, attendu = gabaritConstruction(bloc), construction = true,
			limitePiece = math.max(4, plusGrand(bloc.size) * 1.25) }, function()
			region.state.built = { { id = id, b = id, x = 0, y = bloc.size.Y / 2, z = 0, o = 0 } }
			batir.onRegionLoad(region)
			local piece = supports.Constructions:FindFirstChild("Piece")
			batir.onRegionUnload(region)
			return piece
		end)
		-- Nettoie également les restes si Batir s'est arrêté entre deux créations.
		supports:ClearAllChildren()
	end
	for _, forme in config.BUILD_SHAPES do
		if not formes[forme.id] then
			table.insert(ecarts, { 1, "Construction/" .. forme.id, "forme sans variante", "aucune entrée dans Config.BLOCK_ORDER" })
		end
	end

	table.sort(ecarts, function(a, b)
		for i = 1, 4 do
			if a[i] ~= b[i] then return a[i] < b[i] end
		end
		return false
	end)
	table.sort(mesures)
	table.sort(ignores)
	local verdict = #ecarts == 0 and #avertissements == 0 and "VERT" or "ROUGE"
	local lignes = { string.format("%s · Banc visuel des props · %d/%d inspectés · %d signalements · %d personnages exclus",
		verdict, lisibles, total, #ecarts, #ignores) }
	for _, note in avertissements do table.insert(lignes, note) end
	local section
	for _, entree in ecarts do
		if section ~= entree[1] then
			section = entree[1]
			table.insert(lignes, "\n" .. GRAVITE[section])
		end
		table.insert(lignes, string.format("%s · %s · %s", entree[2], entree[3], entree[4]))
	end
	table.insert(lignes, "\nMESURES (studs, X × Y × Z)\n" .. table.concat(mesures, "\n"))
	table.insert(lignes, "\nPERSONNAGES EXCLUS\n" .. table.concat(ignores, " · "))
	return table.concat(lignes, "\n")
end

if not game:GetService("RunService"):IsEdit() then return "Banc à lancer en mode Édition." end
SS:SetAttribute(ATTR, "Banc en cours…")
task.spawn(function()
	local bac = Instance.new("Folder")
	local instances = {}
	local ok, rapport = xpcall(auditer, debug.traceback, bac, instances)
	-- Ordre inverse : les orphelins sont libérés, puis le dossier et les arbres encore rattachés.
	for i = #instances, 1, -1 do
		local objet = instances[i]
		if not objet.Parent then objet:Destroy() end
	end
	bac:Destroy()
	SS:SetAttribute(ATTR, ok and rapport or ("ROUGE · Échec du banc · " .. tostring(rapport)))
end)
return "Banc lancé · résultat dans ServerStorage." .. ATTR
