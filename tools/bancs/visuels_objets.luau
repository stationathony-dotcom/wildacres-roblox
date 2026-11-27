-- Studio Édition, avec tools/sync.py. Régénère ReplicatedStorage.IconesObjets.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local http = game:GetService("HttpService")
local pont = "http://127.0.0.1:34873/"
local module = SS.OutilsDev.ConstruireModelesMiniatures
local source = http:GetAsync(pont .. "file?p=ServerStorage.OutilsDev.ConstruireModelesMiniatures")
local miniatures = assert(loadstring(source, "=ConstruireModelesMiniatures"))()
local finitions = assert(loadstring(http:GetAsync(pont .. "banc?f=visuels_finitions"), "=visuels_finitions"))
local familles = assert(loadstring(http:GetAsync(pont .. "banc?f=visuels_objets_familles"), "=visuels_objets_familles"))

local copie = RS.Shared:Clone()
copie.Parent = SS
local okConfig, config = pcall(require, copie.Config)
copie:Destroy()
assert(okConfig, config)

local dossier = Instance.new("Folder")
dossier.Name = "IconesObjets"
local ancienne = RS:FindFirstChild(dossier.Name)
local modeles = SS:FindFirstChild("Modeles")
local materiau = Enum.Material
local dossierOutils = Instance.new("Folder")
dossierOutils.Name = "IconesOutils"
local anciensOutils = RS:FindFirstChild(dossierOutils.Name)

local function bloc(b)
	local modele = miniatures.construireBloc(b)
	if modele then return modele end
	modele = Instance.new("Model")
	modele.Name = b.item
	modele:SetAttribute("ApercuDroit", true)
	local function ajouter(p, taille, pose, accent)
		p.Name, p.Size, p.CFrame = "Pièce de construction", taille, pose
		p.Color, p.Material, p.Transparency = b.color, b.mat, b.transp or 0
		if accent == "dark" then
			p.Color, p.Material, p.Transparency = Color3.fromRGB(78, 52, 34), materiau.Wood, 0
		elseif accent == "glass" then
			p.Color = b.shape == "stainedwall" and Color3.fromRGB(150, 70, 160) or Color3.fromRGB(190, 225, 240)
			p.Material, p.Transparency = materiau.Glass, 0.4
		end
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = modele
	end
	local compose = config.SHAPE_PARTS[b.shape]
	if compose then
		for _, spec in compose(b.size) do
			ajouter(config.makeSubPart(spec), spec[1], spec[2], spec[4])
		end
	else
		local classe = ({ wedge = "WedgePart", corner = "CornerWedgePart", ladder = "TrussPart" })[b.shape] or "Part"
		local p = Instance.new(classe)
		if b.shape == "pillar" then
			p.Shape = Enum.PartType.Cylinder
			ajouter(p, Vector3.new(b.size.Y, b.size.X, b.size.Z), CFrame.Angles(0, 0, math.pi / 2))
		else
			ajouter(p, b.size, CFrame.new())
		end
	end
	miniatures.rehausser(modele, "chantier", nil, { dessus = b.size.Y < b.size.X * 0.40 })
	return modele
end

local ids = {}
for id, info in config.ITEMS do
	if not info.tool then table.insert(ids, id) end
end
table.sort(ids)

local redessines, props, blocs = 0, 0, 0
local function preparer()
	for i, id in ids do
		local info = config.ITEMS[id]
		local modele = miniatures.objet(id)
		if modele then
			redessines += 1
		elseif info.block then
			modele = bloc(assert(config.BLOCKS[info.block], id))
			blocs += 1
		elseif type(info.place) == "string" then
			local stock = modeles and modeles:FindFirstChild(info.place)
			local genere = not stock and config.Catalogue.build(info.place)
			if stock or genere then
				modele = miniatures.depuisProp(stock or genere, id)
				if genere then genere:Destroy() end
				props += 1
			end
		end
		if modele then modele.Parent = dossier end
		if i % 40 == 0 then task.wait() end
	end
	finitions(dossier, miniatures, config)
end

local function preparerOutils(erreurs)
	local fabricant = require(SS.OutilsDev.ConstruireModelesOutils)
	local sources = SS.Outils:Clone()
	local ok, raison = pcall(function()
		fabricant.harpon(sources)
		fabricant.equipements(sources, config)
		local function ajouter(id, outil, teinte)
			local m = miniatures.depuisProp(outil, id, teinte)
			miniatures.raccorder(m)
			miniatures.centrer(m)
			local problemes = miniatures.verifier(m, 4)
			for _, probleme in problemes do table.insert(erreurs, id .. " : " .. probleme) end
			m.Parent = dossierOutils
		end
		for _, outil in sources:GetChildren() do
			if outil:IsA("Tool") then ajouter(outil.Name, outil) end
		end
		local aliases = {
			hoe = "Houe", can = "Arrosoir", shovel = "Pelle", axe = "Hache", pickaxe = "Pioche",
			rod = "Canne à pêche", club = "Gourdin", sword = "Épée", spade = "Pelle",
		}
		for id, info in config.ITEMS do
			if not info.tool or dossierOutils:FindFirstChild(id) then continue end
			local nom = aliases[info.base or id]
			local outil = nom and sources:FindFirstChild(nom)
			if outil then
				ajouter(id, outil, config.TOOL_TINTS[config.tierOf(id)])
			else
				table.insert(erreurs, id .. " : outil source absent")
			end
		end
	end)
	sources:Destroy()
	assert(ok, raison)
end

local erreurs, erreursFamilles = {}, {}
local delegues, maximum = 0, 0
local ok, message = pcall(function()
	preparer()
	preparerOutils(erreurs)
	local compteRenduFamilles = familles(miniatures, dossier)
	for i, id in ids do
		local info = config.ITEMS[id]
		local m = dossier:FindFirstChild(id)
		local delegue = m and m:GetAttribute("Famille") ~= nil
		local liste = delegue and erreursFamilles or erreurs
		if m then
			if delegue then
				delegues += 1
			else
				m:SetAttribute("MiniatureObjet", true)
			end
			if not info.block then miniatures.raccorder(m) end
			miniatures.centrer(m)
			local raisons, total = miniatures.verifier(m, info.block and 1 or 6)
			maximum = math.max(maximum, total)
			if #raisons > 0 then table.insert(liste, id .. " : " .. table.concat(raisons, ", ")) end
		else
			table.insert(liste, id .. " : miniature absente")
		end
		if i % 40 == 0 then task.wait() end
	end
	SS:SetAttribute("BancVisuelsObjetsFamilles", #erreursFamilles == 0 and "OK" or table.concat(erreursFamilles, "\n"))
	for _, erreur in erreursFamilles do table.insert(erreurs, erreur) end
	assert(#erreurs == 0, table.concat(erreurs, "\n"))
	module.Source = source
	return string.format("%d miniatures · %d outils · %d dessins repris · %d props · %d pièces de construction · maximum %d pièces\n"
		.. "%d miniatures du lot familles, %d à vérifier\n%s",
		#dossier:GetChildren(), #dossierOutils:GetChildren(), redessines, props, blocs, maximum, delegues, #erreursFamilles, compteRenduFamilles)
end)
if not ok then
	dossier:Destroy()
	dossierOutils:Destroy()
	error(message, 0)
end
if ancienne then ancienne:Destroy() end
dossier.Parent = RS
if anciensOutils then anciensOutils:Destroy() end
dossierOutils.Parent = RS
return message
