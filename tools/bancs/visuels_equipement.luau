-- Studio Édition. Vérifie chaque miniature et sa géométrie portée avant de publier le dossier.
local mode = ...
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local H = game:GetService("HttpService")
local bridge = "http://127.0.0.1:34873/"
if type(mode) == "number" then
	local planche = assert(loadstring(H:GetAsync(bridge .. "banc?f=planche_miniatures"), "=planche_miniatures"))
	local view = planche("IconesEquipement", mode)
	for _, model in workspace.PlancheMiniatures:GetChildren() do
		if model:IsA("Model") then
			local center = model:GetBoundingBox()
			model:PivotTo(center * CFrame.Angles(0, math.pi, 0) * center:ToObjectSpace(model:GetPivot()))
		end
	end
	view.camera[2] -= 10
	view.camera[3] += 8
	return view
end
local shared = RS.Shared:Clone()
shared.Parent = SS
local function modules()
	return require(shared.Config), require(shared.Gear), require(shared.GearVisuals), require(shared.GearDesign),
		require(shared.Apparence)
end
local loaded, config, gear, visuals, design, looks = pcall(modules)
shared:Destroy()
assert(loaded, config)
local entries = gear.visualEntries(config)
local mannequin = assert(SS.Modeles:FindFirstChild("PNJ_Base"), "Modèle de référence PNJ_Base absent")

local function avatarFor(profiles)
	local source = game:GetService("ServerScriptService").Systemes.Avatar
	local chunk = assert(loadstring(source.Source, "=AvatarEquipementBanc"))
	local dependencies = {
		[RS.Shared.GearDesign] = design, [RS.Shared.GearVisuals] = visuals, [RS.Shared.Apparence] = looks,
	}
	setfenv(chunk, setmetatable({
		script = source,
		require = function(module)
			return dependencies[module] or require(module)
		end,
	}, {__index = getfenv(chunk)}))
	local Avatar = chunk()
	Avatar.init({
		Interact = {onAction = function() end},
		Joueurs = {get = function(player) return profiles[player] end},
		WG = require(RS.Shared.WorldGen),
	})
	return Avatar
end

if mode == "avatar" then
	local profiles = {}
	local Avatar = avatarFor(profiles)
	local looks = {
		{"weapon:Épée longue", "hat:Heaume du Soleil rouge", "armor:Cotte de mailles",
			"offhand:Bouclier héraldique", "boots:Solerets d'acier", "cape:Cape du Soleil rouge"},
		{"weapon:Arbalète de la Garde du pont", "hat:Casque nasal de la Garde du pont", "armor:Brigandine de la Veille d’hiver",
			"offhand:Bouclier rectangulaire", "gloves:Gantelets de la Garde du pont", "legs:Chausses de la Garde du pont"},
		{"weapon:Hache à défense de sanglier colossal", "hat:Couronne de bois de cerf", "armor:Armure d'écailles de croco",
			"shoulders:Épaulières à corne des Ronces vertes", "boots:Bottes de marais", "trinket:Collier de crocs de loup noir"},
		{"weapon:Lame venimeuse légendaire de la Bête des profondeurs", "hat:Capuche d'aile de chauve-souris géante",
			"armor:Plastron d'élytres légendaire du Scarabée royal", "offhand:Torche", "trinket:Bracelet de crin de kelpie"},
		{"weapon:Arc long", "hat:Turban de lin", "armor:Chemise en lin", "cape:Cape de soie",
			"legs:Pantalon en lin de Valdor", "trinket:Broche du Soleil rouge"},
		{"weapon:Dague à dard de scorpion", "hat:Chapeau de mage", "armor:Robe",
			"offhand:Bouclier-carapace de tortue ancienne", "trinket:Talisman d'essence légendaire de Brumeglace"},
	}
	local stage = Instance.new("Folder")
	stage.Name = "PlancheEquipementPorte"
	local center = Vector3.new(-3000, 707, -3000)
	for i, keys in looks do
		local char = mannequin:Clone()
		char.Name = tostring(i) .. " · " .. keys[3]
		local player = {Character = char}
		local equipped = {}
		for _, key in keys do
			local item = assert(entries[key], key)
			equipped[gear.slotOf(item)] = item
		end
		profiles[player] = {
			equipped = equipped, stats = {},
			look = {mode = "villageois", skin = i, shirt = 1, pants = 1, hair = "court", hairColor = 1},
		}
		char:PivotTo(CFrame.new(center + Vector3.new((i - 3.5) * 4.9, 0, 0)))
		Avatar.refresh(player)
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") then part.Anchored = true end
		end
		char.Parent = stage
	end
	local old = workspace:FindFirstChild(stage.Name)
	if old then old:Destroy() end
	stage.Parent = workspace
	workspace.CurrentCamera.CFrame = CFrame.lookAt(center + Vector3.new(0, 4, -29), center)
	return "Six tenues sur PlancheEquipementPorte. Tourner autour pour examiner capes et armes au dos."
end

local verify = assert(loadstring(H:GetAsync(bridge .. "file?p=ServerStorage.OutilsDev.ConstruireModelesMiniatures"),
	"=ConstruireModelesMiniatures"))().verifier
local folder = Instance.new("Folder")
folder.Name = "IconesEquipement"
local trial = mannequin:Clone()
local worn = Instance.new("Model")
worn.Parent = trial

local function checkNeon(model, rank, iconSize)
	local lights = 0
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Material == Enum.Material.Neon then
			lights += 1
			if rank < 4 or p.Name ~= "Lueur légendaire" or math.max(p.Size.X, p.Size.Y, p.Size.Z) > iconSize * 0.16 then
				return "Neon hors lueur légendaire discrète"
			end
		end
	end
	if lights > 2 then return "plus de deux lueurs pour une pièce portée" end
	return nil
end

local function footprint(model, key)
	local names = {}
	for _, p in model:GetDescendants() do
		if not p:IsA("BasePart") then continue end
		assert(p.Name:find("%S") and p.Name ~= p.ClassName, key .. " : pièce sans nom")
		for _, n in {p.CFrame:GetComponents()} do
			assert(math.abs(n) < math.huge, key .. " : CFrame invalide pour " .. p.Name)
		end
		table.insert(names, p.Name)
	end
	table.sort(names)
	return table.concat(names, "|"), #names
end

local function checkWorn(item, miniatureSize, expected, label)
	local count = visuals.wear(item, trial, worn)
	local message
	if count < expected or count > 30 then
		message = string.format("%d pièces portées, attendu de %d à 30", count, expected)
	else
		for _, p in worn:GetChildren() do
			local weld = p:FindFirstChildWhichIsA("WeldConstraint")
			if p.Anchored or p.CanCollide or p.CanQuery or p.CanTouch or not p.Massless
				or not weld or not weld.Part0 or weld.Part1 ~= p or weld.Part0.Parent ~= trial then
				message = "pièce portée sans attache valide : " .. p.Name
				break
			end
		end
	end
	message = message or checkNeon(worn, item.rarity or 1, miniatureSize)
	local signature = label and footprint(worn, label)
	worn:ClearAllChildren()
	return count, message, signature
end

if mode == "torses" then
	local cuts
	for _, field in looks.FIELDS do
		if field.key == "shirtCut" then cuts = field.choices break end
	end
	assert(cuts and #cuts >= 5, "Catalogue de coupes incomplet")
	local profile = {equipped = {}, stats = {}, look = {mode = "villageois", shirt = 4, pantsCut = "simple"}}
	local player = {Character = trial}
	local Avatar = avatarFor({[player] = profile})
	local families, signatures, cutsTested = {}, {}, 0
	local count, variants, maxIcon, maxWorn = 0, 0, 0, 0
	local ok, failure = pcall(function()
		for key, item in entries do
			if gear.slotOf(item) ~= "armor" or key ~= gear.visualKey(item) then continue end
			count += 1
			local byRank = {}
			for rank = 1, #gear.RARITIES do
				local variant = table.clone(item)
				variant.rarity = rank
				local icon = visuals.preview(variant)
				local label = key .. " · rang " .. rank
				local family = assert(icon:GetAttribute("FamilleTorse"), label)
				local signature, iconParts = footprint(icon, label)
				local _, size = icon:GetBoundingBox()
				local width = math.max(size.X, size.Y, size.Z)
				local issues = verify(icon, 2)
				local neon = checkNeon(icon, rank, width)
				icon:Destroy()
				assert(#issues == 0, label .. " : " .. table.concat(issues, ", "))
				assert(not neon, label .. " : " .. tostring(neon))
				assert(not signatures[signature] or signatures[signature] == family, label .. " : empreinte commune à deux familles")
				families[family], signatures[signature] = true, family
				byRank[rank] = signature
				if rank > 1 then assert(signature ~= byRank[rank - 1], label .. " : rang sans détail ajouté") end
				local wornParts, issue, wornSignature = checkWorn(variant, width, iconParts, label)
				assert(not issue, label .. " : " .. tostring(issue))
				assert(wornSignature == signature, label .. " : dessin porté différent de la miniature")
				maxIcon, maxWorn = math.max(maxIcon, iconParts), math.max(maxWorn, wornParts)
				variants += 1
			end
			for _, choice in cuts do
				local cut = choice[1]
				profile.look.shirtCut = cut
				profile.equipped.armor = item
				Avatar.refresh(player)
				local armor = assert(trial:FindFirstChild("Armure_WA"), key)
				local wornSignature = footprint(armor, key .. " · " .. cut)
				assert(wornSignature == byRank[design.appearance(item).rarity], key .. " : dessin porté différent")
				assert(not trial:FindFirstChild("Tenue_WA"), key .. " : la coupe " .. cut .. " traverse le torse")
				assert(trial.UpperTorso.Color == looks.SHIRTS[4], key .. " : couleur de sous-tunique perdue")
				profile.equipped.armor = nil
				Avatar.refresh(player)
				local garment = trial:FindFirstChild("Tenue_WA")
				assert(not trial:FindFirstChild("Armure_WA") and (garment ~= nil) == (cut ~= "simple")
					and profile.look.shirtCut == cut, key .. " : la coupe " .. cut .. " ne revient pas")
				cutsTested += 1
			end
			if count % 5 == 0 then task.wait() end
		end
		for _, family in {"tissu", "cuir", "brigandine", "mailles", "ecailles", "plates", "robes", "creatures", "legendaires"} do
			assert(families[family], "Famille absente : " .. family)
		end
		assert(count > 0, "Catalogue des torses vide")
	end)
	trial:Destroy()
	folder:Destroy()
	assert(ok, failure)
	return string.format("%d torses, %d variantes, %d essayages · maximum %d pièces en miniature et %d pièces portées",
		count, variants, cutsTested, maxIcon, maxWorn)
end

local count, maxIcon, maxWorn, issues = 0, 0, 0, {}
local validated = {}
local ok, failure = pcall(function()
	for key, item in entries do
		local icon = visuals.preview(item)
		icon.Name = key
		icon.Parent = folder
		local problems, parts = verify(icon, 2)
		local _, size = icon:GetBoundingBox()
		local width = math.max(size.X, size.Y, size.Z)
		local neon = checkNeon(icon, icon:GetAttribute("RangVisuel"), width)
		if neon then table.insert(problems, neon) end
		if not validated[item] then
			local wornParts, issue = checkWorn(item, width, parts)
			if issue then table.insert(problems, issue) end
			maxWorn = math.max(maxWorn, wornParts)
			validated[item] = true
		end
		if #problems > 0 then table.insert(issues, key .. " · " .. table.concat(problems, ", ")) end
		maxIcon = math.max(maxIcon, parts)
		count += 1
		if count % 40 == 0 then task.wait() end
	end
	assert(count >= 694, string.format("Catalogue incomplet : %d / 694", count))
	table.sort(issues)
	assert(#issues == 0, string.format("%d modèles en échec\n%s", #issues, table.concat(issues, "\n")))
end)
trial:Destroy()
if not ok then
	folder:Destroy()
	error(failure, 0)
end
local old = RS:FindFirstChild(folder.Name)
if old then old.Parent = nil end
folder.Parent = RS
if old then old:Destroy() end
return string.format("%d miniatures validées · maximum %d pièces en miniature et %d pièces portées", count, maxIcon, maxWorn)
