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
		elseif id == "seed_sack" then
			-- Le banc des graines exclut ce contenant. Garder sa miniature existante.
			local precedente = ancienne and ancienne:FindFirstChild(id)
			if precedente and precedente:IsA("Model") then modele = precedente:Clone() end
		end
		if modele then modele.Parent = dossier end
		if i % 40 == 0 then task.wait() end
	end
	finitions(dossier, miniatures, config)
end

local erreurs, erreursFamilles = {}, {}
local delegues, maximum = 0, 0
local ancienneDeplacee = false
local ok, message = pcall(function()
	preparer()
	if ancienne then
		ancienne.Parent = nil
		ancienneDeplacee = true
	end
	dossier.Parent = RS
	local compteRenduFamilles = familles()
	for i, id in ids do
		local info = config.ITEMS[id]
		local m = dossier:FindFirstChild(id)
		local delegue = id == "seed_sack" or m and m:GetAttribute("Famille") ~= nil
		local liste = delegue and erreursFamilles or erreurs
		if m then
			if delegue then
				delegues += 1
			else
				if not info.block then miniatures.raccorder(m) end
				m:SetAttribute("MiniatureObjet", true)
			end
			miniatures.centrer(m)
			local raisons, total = miniatures.verifier(m, info.block and 1 or 6)
			maximum = math.max(maximum, total)
			if #raisons > 0 then table.insert(liste, id .. " : " .. table.concat(raisons, ", ")) end
		else
			table.insert(liste, id .. " : miniature absente")
		end
		if i % 40 == 0 then task.wait() end
	end
	assert(#erreurs == 0, table.concat(erreurs, "\n"))
	SS:SetAttribute("BancVisuelsObjetsFamilles", #erreursFamilles == 0 and "OK" or table.concat(erreursFamilles, "\n"))
	module.Source = source
	return string.format("%d miniatures · %d dessins repris · %d props · %d pièces de construction · maximum %d pièces\n"
		.. "%d miniatures du lot familles, %d à vérifier\n%s",
		#dossier:GetChildren(), redessines, props, blocs, maximum, delegues, #erreursFamilles, compteRenduFamilles)
end)
if not ok then
	dossier:Destroy()
	if ancienneDeplacee then ancienne.Parent = RS end
	error(message, 0)
end
if ancienne then ancienne:Destroy() end
return message
