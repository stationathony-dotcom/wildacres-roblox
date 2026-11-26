-- Gens de métier des villages (18/11) : boulanger, cuisinier, forgeron, guérisseur, prêtre,
-- palefrenier, enfants qui jouent sur la place, colporteur de passage.
--
-- Posés PAR-DESSUS la génération, avec leur propre graine (« metiers ») : RegionPlan n'est pas
-- touché, les habitants des mondes existants gardent leurs ids. Ils réutilisent tout le moteur des
-- habitants (Npcs) : emploi du temps, vue, témoins, fuite, K.O., avis par joueur, dialogues.
--
-- Chaîne économique (monde fini) : le stock d'un artisan vient de ce que les joueurs lui vendent.
-- Le blé vendu au boulanger devient du pain le lendemain, le minerai vendu au forgeron des
-- ferrures, les plantes vendues au guérisseur des remèdes. Si personne n'apporte rien, l'étal se
-- vide (il reste une petite fournée de base). Rien n'est créé de rien : la valeur produite est
-- celle des matières apportées (au prix du catalogue), et l'artisan revend au prix normal.
--
-- Un artisan tué (corps caché) est remplacé 3 jours plus tard par un nouveau venu.
-- Les enfants ne se battent jamais et on ne peut pas les frapper (règles Roblox) : ils jouent,
-- fuient les recherchés, répètent ce qu'ils voient et connaissent les cachettes du coin.
--
-- Données : G.world.extra.metiers[regKey] = { roles = { [role] = { gen, points, stock, goneDay } },
-- colporteur = { day, stock } } (sauvegardé avec le monde).

local Debris = game:GetService("Debris")

local Metiers = {}
local G, Config, D

local REPLACE_DAYS = 3 -- un artisan disparu est remplacé au bout de 3 jours
local STOCK_CAP = 25 -- au-delà, l'artisan ne produit plus cet article (son étal est plein)
local SPECIALTY = 1.15 -- un artisan paie mieux SES matières que le marchand
local PEDDLER_CHANCE = 0.3 -- chance qu'un village reçoive le colporteur un jour donné
local PEDDLER_PREMIUM = 1.4 -- marchandises venues de loin : plus chères
local PEDDLER_BUY = 1.25 -- il paie bien les produits du coin (qu'il revendra ailleurs)
local HEAL_COST, BLESS_COST, ALMS_COST = 8, 15, 20

-- Définition des métiers. `at` : bâtiments du village où il travaille (le premier présent) ;
-- `spot` : point d'attache « Travail » du bâtiment, sinon devant la façade (`front` studs).
local ROLES = {
	baker = {
		label = "Boulanger", labelF = "Boulangère", at = { "Marche_Village", "Taverne" }, front = 6, hat = "toque", garb = "tablier",
		shop = "Boulangerie", trade = "🍞 Voir le pain du jour", baseValue = 160,
		inputs = { "wheat", "flour", "rye", "barley", "oat", "egg", "milk", "butter", "honey" },
		products = { "bread", "galette", "whole_bread", "country_bread", "honey_cake" },
		intro = "Du pain chaud tous les matins… si on m'apporte du grain !",
	},
	cook = {
		label = "Cuisinier", labelF = "Cuisinière", at = { "Taverne" }, front = 9, hat = "toque", garb = "tablier",
		shop = "Cuisine de la taverne", trade = "🍲 Voir les plats", baseValue = 180, services = { "repas" },
		inputs = { "meat", "boar_meat", "venison", "rabbit_meat", "raw_fish", "fish_1", "fish_2", "fish_3", "salmon", "carrot", "potato", "onion", "cabbage", "turnip", "bean", "pea", "beetroot", "parsnip", "tomato", "mushroom", "egg", "herbs" },
		products = { "omelette", "cooked_veg", "roast", "fish_soup", "rabbit_stew", "game_stew", "meat_pie" },
		intro = "Rapporte-moi de la viande, du poisson ou des légumes : j'en fais des merveilles.",
	},
	blacksmith = {
		label = "Forgeron", labelF = "Forgeronne", at = { "Forge" }, front = 9, garb = "cuir", maxHp = 120,
		shop = "Forge", trade = "⚒️ Voir la ferronnerie", baseValue = 120, services = { "reparer" }, hammer = true,
		inputs = { "ore", "copper_ore", "silver_ore", "coal", "copper_ingot", "iron_ingot" },
		products = { "nails", "copper_nails", "hinge", "fitting", "chain", "copper_ingot", "iron_ingot", "steel" },
		intro = "Du minerai et du charbon, voilà ce qu'il me faut. Le reste, c'est le marteau.",
	},
	healer = {
		label = "Guérisseur", labelF = "Guérisseuse", at = { "Chapelle", "Auberge", "Taverne" }, front = 7, hat = "capuche", garb = "echarpe",
		shop = "Herboristerie", trade = "🌿 Voir les remèdes", baseValue = 90, services = { "soigner" },
		inputs = { "chamomile", "mint", "thyme", "sage", "nettle", "rosemary", "lavender", "valerian", "herbs", "night_flower", "ancient_root", "honey" },
		products = { "mint_tea", "chamomile_tea", "sage_tea", "herbal_salve", "healing_potion", "calming_draught", "vigor_elixir" },
		intro = "Chaque plante a sa vertu. Apporte-m'en, j'en tirerai des remèdes.",
	},
	priest = {
		label = "Prêtre", labelF = "Prêtresse", at = { "Chapelle" }, front = 8, garb = "robe", persona = "pieux",
		services = { "benir", "confesser", "aumone" },
		intro = "Que la paix soit sur toi, voyageur.",
	},
	stablemaster = {
		label = "Palefrenier", labelF = "Palefrenière", at = { "Ecurie" }, front = 6, hat = "paille", garb = "gilet",
		shop = "Écurie", trade = "🐴 Foin et harnais", baseValue = 60, services = { "monture", "changer", "pouliner", "diligence" },
		inputs = { "hay", "oat", "wheat", "carrot", "apple", "leather", "iron_ingot", "buckle", "iron_ring" },
		-- 26/11 (montures façon WoW) : aussi vendeur de harnachement
		products = { "hay", "animal_feed", "leather_strap", "bridle", "horseshoes", "stirrups", "saddle_leather" },
		intro = "Une bête bien nourrie te le rendra au centuple.",
	},
}
-- 19/11 : établissements d'apparence (Avatar) au marché — barbier à gauche, tailleur à droite
ROLES.barber = {
	label = "Barbier", labelF = "Barbière", at = { "Marche_Village", "Taverne", "Auberge" }, front = 6, side = -7, garb = "tablier",
	services = { "coiffure" }, intro = "Un coup de ciseaux ? J'ai des coupes que tu n'as jamais vues.",
}
ROLES.tailor = {
	label = "Tailleur", labelF = "Couturière", at = { "Marche_Village", "Auberge", "Taverne" }, front = 6, side = 7, garb = "echarpe",
	services = { "couture" }, intro = "Des teintes pour chaque saison, cousues main.",
}
-- 26/11 (« des marchands d'un peu tout, façon WoW ») : aubergiste, fournisseur, alchimiste. Même règle que les
-- autres : leur étal se remplit avec ce que les joueurs leur apportent (plus une petite fournée de base).
ROLES.innkeeper = {
	label = "Aubergiste", labelF = "Aubergiste", at = { "Auberge", "Taverne" }, front = 7, side = 6, hat = "toque", garb = "tablier",
	shop = "Auberge", trade = "🍺 Boire et manger", baseValue = 150,
	inputs = { "wheat", "barley", "apple", "milk", "meat", "honey", "potato", "carrot", "onion", "cabbage" },
	products = { "apple_juice", "cider", "jerky", "nettle_soup", "rations", "cheese", "stew", "ale" },
	intro = "Une chope, un bol de soupe, une paillasse… et les nouvelles du coin en prime.",
}
ROLES.outfitter = {
	label = "Fournisseur", labelF = "Fournisseuse", at = { "Marche_Village", "Auberge" }, front = 6, side = -14, hat = "paille", garb = "gilet",
	shop = "Bazar", trade = "🎒 Fournitures de voyage", baseValue = 110,
	inputs = { "feather", "planks", "iron_ingot", "fiber", "leather", "cloth" },
	products = { "bait", "arrow", "rope", "bolt", "arrow_iron", "candle_wax", "map_region", "braided_rope", "oil", "compass", "provision_bag", "canvas_bag" },
	intro = "Flèches, cordes, cartes et sacs : tout ce qu'il faut avant de prendre la route.",
}
ROLES.alchemist = {
	label = "Alchimiste", labelF = "Alchimiste", at = { "Auberge", "Marche_Village", "Chapelle" }, front = 7, side = 13, hat = "capuche", garb = "robe",
	shop = "Officine", trade = "⚗️ Voir les fioles", baseValue = 80,
	inputs = { "night_flower", "ancient_root", "mushroom", "honey", "valerian", "lavender", "sage", "nettle", "slime_gel", "ice_crystal" },
	products = { "potion_vent", "potion_pierre", "potion_charme", "potion_taureau", "potion_brume", "night_elixir" },
	intro = "Une fiole pour chaque besoin… à condition d'avoir les ingrédients.",
}
local ORDER = { "baker", "cook", "blacksmith", "healer", "priest", "stablemaster", "barber", "tailor", "innkeeper", "outfitter", "alchemist" }
Metiers.ROLES = ROLES

local PEDDLER = { label = "Colporteur", labelF = "Colporteuse", trade = "🎒 Voir sa marchandise", hat = "capuche", garb = "hotte" }
-- raretés du colporteur (prix fixés ici : ces objets n'ont pas de prix de catalogue)
local PEDDLER_RARE = { unknown_recipe = 120, craftsman_plan = 220, recipe_book = 160, manual_cook = 120, manual_farm = 120, manual_herd = 120, manual_fish = 120 }

-- Château (Chateaux.lua) : un seigneur dans la cour, deux gardes à la porte
local LORD = { label = "Seigneur", labelF = "Dame", trade = "🏆 Vendre des trophées de chasse", garb = "noble", bonus = 1.2 }
local GUARD = { label = "Garde du château", labelF = "Garde du château", garb = "garde" }
-- Titres de noblesse : dépense facultative des joueurs riches (or au trésor du village), sans plafond
-- de richesse mais avec une réputation à tenir. Les titres eux-mêmes vivent dans Social.TITLES.
local NOBILITY = {
	{ id = "ecuyer", name = "Écuyer", honor = 20, gold = 500 },
	{ id = "chevalier", name = "Chevalier", honor = 40, gold = 2500 },
	{ id = "baron", name = "Baron", honor = 60, gold = 10000 },
}
Metiers.NOBILITY = NOBILITY
local function isTrophy(item: string): boolean
	return string.sub(item, 1, 6) == "prise_" or string.sub(item, 1, 4) == "ame_"
end

local ADULT_PERSONAS ={ "bourru", "jovial", "anxieux", "commere", "radin", "pieux" }
local CHILD_PERSONAS = { "jovial", "anxieux", "commere" }

local CHILD_LINES = {
	"On joue à chat ? Tu ne m'attraperas jamais !",
	"Maman dit qu'il ne faut pas parler aux inconnus… mais t'as l'air sympa.",
	"Quand je serai grand{e}, je serai forgeron. Ou dragon.",
	"Tu as vu le moulin ? Ses ailes tournent même la nuit !",
	"J'ai trouvé une plume toute bleue ce matin !",
	"Le shérif, il a jamais attrapé personne. Enfin, presque.",
}

-- ----------------------------------------------------------------- Données

local function root()
	G.world.extra = G.world.extra or {}
	G.world.extra.metiers = G.world.extra.metiers or {}
	return G.world.extra.metiers
end

local function village(key: string)
	local all = root()
	local v = all[key]
	if not v then
		v = { roles = {} }
		all[key] = v
	end
	v.roles = v.roles or {}
	return v
end

local function roleState(key: string, role: string)
	local v = village(key)
	local st = v.roles[role]
	if not st then
		st = { gen = 1, points = 0, stock = {} }
		v.roles[role] = st
		-- première visite : une fournée de base dès aujourd'hui (pas un étal vide)
		Metiers.produce(role, st)
	end
	st.stock = st.stock or {}
	return st
end

local function priceOf(item: string): number
	local info = Config.ITEMS[item]
	return (info and info.price) or PEDDLER_RARE[item] or 0
end

-- Fournée du jour : la valeur des matières apportées (+ une petite base) devient des articles.
-- Tour à tour, du moins cher au plus cher, tant qu'il reste de quoi en faire un.
function Metiers.produce(role: string, st)
	local def = ROLES[role]
	if not def or not def.products then
		return
	end
	local base = def.baseValue or 0
	local budget = (st.points or 0) + base
	local progress = true
	while progress do
		progress = false
		for _, it in def.products do
			local p = priceOf(it)
			if p > 0 and budget >= p and (st.stock[it] or 0) < STOCK_CAP then
				st.stock[it] = (st.stock[it] or 0) + 1
				budget -= p
				progress = true
			end
		end
	end
	-- la base non utilisée est perdue ; ce que les joueurs ont apporté reste pour demain
	st.points = math.max(0, budget - base)
end

-- ----------------------------------------------------------------- Apparence

local function weld(model: Model, part: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, mat: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.Fabric
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = part.CFrame * offset
	p.Parent = model
	local w = Instance.new("WeldConstraint")
	w.Part0 = part
	w.Part1 = p
	w.Parent = p
	return p
end

local function paint(model: Model, names, color: Color3)
	for _, n in names do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			p.Color = color
		end
	end
end

local GARB = {
	tablier = function(m, torso)
		weld(m, torso, "Tablier", Vector3.new(1.6, 1.9, 0.1), CFrame.new(0, -0.35, -0.53), Color3.fromRGB(240, 236, 220))
	end,
	cuir = function(m, torso)
		weld(m, torso, "Tablier", Vector3.new(1.7, 2.2, 0.12), CFrame.new(0, -0.45, -0.54), Color3.fromRGB(86, 58, 36), Enum.Material.Leather)
		weld(m, torso, "Lanière", Vector3.new(0.18, 0.8, 0.1), CFrame.new(-0.5, 0.6, -0.54), Color3.fromRGB(60, 40, 26), Enum.Material.Leather)
		weld(m, torso, "Lanière", Vector3.new(0.18, 0.8, 0.1), CFrame.new(0.5, 0.6, -0.54), Color3.fromRGB(60, 40, 26), Enum.Material.Leather)
		local skin = m:FindFirstChild("Head") and m.Head.Color
		if skin then
			paint(m, { "LeftLowerArm", "RightLowerArm" }, skin)
		end
	end,
	echarpe = function(m, torso)
		weld(m, torso, "Echarpe", Vector3.new(0.3, 2.3, 1.12), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(35)), Color3.fromRGB(90, 140, 80))
		weld(m, torso, "Bourse", Vector3.new(0.5, 0.5, 0.3), CFrame.new(0.6, -0.8, -0.5), Color3.fromRGB(130, 100, 60), Enum.Material.Leather)
	end,
	robe = function(m, torso)
		local robe = Color3.fromRGB(58, 48, 62)
		paint(m, { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }, robe)
		local low = m:FindFirstChild("LowerTorso")
		if low then
			weld(m, low, "Robe", Vector3.new(2.05, 2.5, 1.15), CFrame.new(0, -1.35, 0), robe)
		end
		weld(m, torso, "Col", Vector3.new(1.2, 0.2, 1.06), CFrame.new(0, 0.85, 0), Color3.fromRGB(235, 230, 215))
		weld(m, torso, "Etole", Vector3.new(0.3, 2, 0.08), CFrame.new(-0.35, -0.1, -0.53), Color3.fromRGB(200, 170, 80))
		weld(m, torso, "Etole", Vector3.new(0.3, 2, 0.08), CFrame.new(0.35, -0.1, -0.53), Color3.fromRGB(200, 170, 80))
	end,
	gilet = function(m, torso)
		weld(m, torso, "Gilet", Vector3.new(0.5, 1.7, 1.08), CFrame.new(-0.62, 0, 0), Color3.fromRGB(110, 76, 46), Enum.Material.Leather)
		weld(m, torso, "Gilet", Vector3.new(0.5, 1.7, 1.08), CFrame.new(0.62, 0, 0), Color3.fromRGB(110, 76, 46), Enum.Material.Leather)
	end,
	noble = function(m, torso)
		local red, gold = Color3.fromRGB(130, 30, 40), Color3.fromRGB(220, 180, 70)
		weld(m, torso, "Cape", Vector3.new(2.1, 3.4, 0.12), CFrame.new(0, -0.6, 0.6), red)
		weld(m, torso, "Fourrure", Vector3.new(2.2, 0.4, 1.3), CFrame.new(0, 0.85, 0.05), Color3.fromRGB(240, 236, 228))
		local head = m:FindFirstChild("Head")
		if head then
			weld(m, head, "Couronne", Vector3.new(1.3, 0.3, 1.3), CFrame.new(0, 0.62, 0), gold, Enum.Material.Metal)
			for i = 0, 3 do
				weld(m, head, "Fleuron", Vector3.new(0.22, 0.3, 0.22), CFrame.Angles(0, math.rad(i * 90), 0) * CFrame.new(0, 0.88, -0.58), gold, Enum.Material.Metal)
			end
		end
		weld(m, torso, "Chaine", Vector3.new(0.9, 0.12, 0.1), CFrame.new(0, 0.3, -0.54), gold, Enum.Material.Metal)
	end,
	garde = function(m, torso)
		local steel = Color3.fromRGB(150, 155, 165)
		weld(m, torso, "Tabard", Vector3.new(1.3, 2.4, 1.1), CFrame.new(0, -0.4, 0), Color3.fromRGB(40, 60, 120))
		weld(m, torso, "Blason", Vector3.new(0.6, 0.7, 0.08), CFrame.new(0, 0.1, -0.58), Color3.fromRGB(220, 180, 70))
		paint(m, { "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }, steel)
		local head = m:FindFirstChild("Head")
		if head then
			weld(m, head, "Casque", Vector3.new(1.35, 0.7, 1.35), CFrame.new(0, 0.5, 0), steel, Enum.Material.Metal)
			weld(m, head, "Nasal", Vector3.new(0.14, 0.6, 0.1), CFrame.new(0, 0.1, -0.66), steel, Enum.Material.Metal)
		end
		weld(m, torso, "Lance", Vector3.new(0.18, 8, 0.18), CFrame.new(1.4, 1, -0.6), Color3.fromRGB(110, 80, 50), Enum.Material.Wood)
		weld(m, torso, "Fer", Vector3.new(0.3, 0.8, 0.12), CFrame.new(1.4, 5.3, -0.6), steel, Enum.Material.Metal)
	end,
	hotte = function(m, torso)
		local wood = Color3.fromRGB(120, 86, 52)
		weld(m, torso, "Hotte", Vector3.new(1.7, 2.2, 1.1), CFrame.new(0, 0.25, 1.05), wood, Enum.Material.WoodPlanks)
		weld(m, torso, "Ballot", Vector3.new(1.5, 0.7, 1.0), CFrame.new(0, 1.65, 1.05), Color3.fromRGB(170, 140, 100))
		weld(m, torso, "Sangle", Vector3.new(0.18, 1.9, 0.1), CFrame.new(-0.5, 0.1, -0.54), Color3.fromRGB(70, 50, 30), Enum.Material.Leather)
		weld(m, torso, "Sangle", Vector3.new(0.18, 1.9, 0.1), CFrame.new(0.5, 0.1, -0.54), Color3.fromRGB(70, 50, 30), Enum.Material.Leather)
	end,
}

local function makeLook(rng: Random, female: boolean, hat: string?)
	local WG = G.WG
	local th = G.wg and G.wg.theme
	local shirts, pants = th and th.shirts, th and th.pants
	local hairs = female and WG.HAIRS_F or WG.HAIRS_M
	local si = rng:NextInteger(1, shirts and #shirts or WG.SHIRTS_GEN1)
	local pi = rng:NextInteger(1, pants and #pants or WG.PANTS_GEN1)
	return {
		skin = rng:NextInteger(1, #WG.SKINS), hair = hairs[rng:NextInteger(1, #hairs)], hairColor = rng:NextInteger(1, #WG.HAIR_COLORS),
		shirt = shirts and shirts[si] or si, pants = pants and pants[pi] or pi, hat = hat or "",
		height = rng:NextNumber(0.94, 1.06), width = rng:NextNumber(0.92, 1.12), female = female,
	}
end

local function dress(e, garb: string?, child: boolean?)
	local m = e.model
	local torso = m:FindFirstChild("UpperTorso")
	if garb and GARB[garb] and torso then
		GARB[garb](m, torso)
	end
	if child then
		pcall(function()
			m:ScaleTo(0.62)
		end)
	end
	m:SetAttribute("Titre", Metiers.label(e))
end

-- ----------------------------------------------------------------- Lieux

local function centerOf(reg): Vector3
	local poi = reg.plan.poi
	local CELL = Config.CELL
	return Vector3.new((poi.x0 + poi.w / 2) * CELL, 0, (poi.z0 + poi.d / 2) * CELL)
end

local function building(reg, names)
	for _, n in names do
		local h = reg.houses and reg.houses["v:" .. n]
		if h and h.model and h.model.Parent and h.model.PrimaryPart then
			return h, n
		end
	end
	return nil
end

-- Poste de travail : l'attache « Travail » du bâtiment, sinon devant sa façade
local function workSpot(h, front: number, side: number?): { number }
	local pp = h.model.PrimaryPart
	local a = pp:FindFirstChild("Travail")
	if a and a:IsA("Attachment") and not side then
		local p = a.WorldPosition
		return { p.X, p.Z, p.Y }
	end
	local p = (pp.CFrame * CFrame.new(side or 0, 0, front)).Position
	return { p.X, p.Z }
end

-- maisons d'habitation du village (pour dormir la nuit, en second occupant)
local function homes(reg)
	local out = {}
	for _, hh in reg.plan.houses do
		if reg.houses[hh.id] and string.sub(hh.model or "", 1, 6) == "Maison" then
			table.insert(out, hh.id)
		end
	end
	table.sort(out)
	return out
end

local function takenNames(reg)
	local t = {}
	for _, n in reg.plan.npcs do
		t[n.name] = true
	end
	return t
end

local function pickName(rng: Random, female: boolean, taken)
	local pool = female and G.WG.NAMES_F or G.WG.NAMES_M
	local name = pool[rng:NextInteger(1, #pool)]
	for _ = 1, 12 do
		if not taken[name] then
			break
		end
		name = pool[rng:NextInteger(1, #pool)]
	end
	taken[name] = true
	return name
end

-- ----------------------------------------------------------------- Apparition

-- id du titulaire actuel d'un poste (ou nil : poste vacant). Tué et caché : la place reste vide
-- REPLACE_DAYS jours, puis quelqu'un d'autre la reprend (nouvelle génération, nouveau nom).
function Metiers.currentId(reg, role: string)
	local st = roleState(reg.key, role)
	local id = "m:" .. reg.key .. ":" .. role .. ":" .. st.gen
	local per = G.world.npcs[id]
	if per and per.gone then
		st.goneDay = st.goneDay or G.world.day
		if G.world.day - st.goneDay < REPLACE_DAYS then
			return nil, st
		end
		st.gen += 1
		st.goneDay = nil
		id = "m:" .. reg.key .. ":" .. role .. ":" .. st.gen
	end
	return id, st
end

-- Hameau (Hameaux.lua) : un habitant par maison, propriétaire de son lit (porte fermée la nuit).
-- Fermiers de leur champ le jour, au puits le soir. Remplacés comme les autres s'ils disparaissent.
function Metiers.spawnHamlet(reg)
	local hm = reg.hamlet
	reg.metiers = reg.metiers or {}
	local taken = {}
	for i, hid in hm.houses do
		local role = "hameau" .. i
		local cur = reg.metiers[role]
		local id = not (cur and cur.model.Parent and cur.state ~= "gone") and Metiers.currentId(reg, role)
		if id then
			local rng = Random.new(G.WG.hash(G.world.seed, "hameau-pnj", reg.rx, reg.rz, id))
			local female = rng:NextNumber() < 0.5
			local n = {
				id = id, name = pickName(rng, female, taken), female = female, role = i == 1 and "farmer" or "villager",
				persona = ADULT_PERSONAS[rng:NextInteger(1, #ADULT_PERSONAS)], look = makeLook(rng, female, i == 1 and "paille" or nil),
				house = hid, work = (i == 1 and hm.field) or "house", plaza = { hm.center.X, hm.center.Z },
			}
			local e = G.Npcs.addExtra(reg, n)
			if e then
				reg.metiers[role] = e
			end
		end
	end
end

-- Ville de joueurs (Systemes/Villes) : un habitant par lit posé ; il travaille près de « son » lit et
-- flâne au centre de la ville. Remplacé comme les autres s'il disparaît.
function Metiers.spawnTown(reg, townId: string, v, beds)
	reg.metiers = reg.metiers or {}
	local taken = {}
	for i, bed in beds do
		local role = "ville_" .. townId .. "_" .. i
		local cur = reg.metiers[role]
		local id = not (cur and cur.model.Parent and cur.state ~= "gone") and Metiers.currentId(reg, role)
		if id then
			local rng = Random.new(G.WG.hash(G.world.seed, "ville-pnj", townId, id))
			local female = rng:NextNumber() < 0.5
			local n = {
				id = id, name = pickName(rng, female, taken), female = female, role = "villager",
				persona = ADULT_PERSONAS[rng:NextInteger(1, #ADULT_PERSONAS)], look = makeLook(rng, female, nil),
				work = { bed.x + rng:NextNumber(-3, 3), bed.z + rng:NextNumber(-3, 3) }, plaza = { v.x, v.z },
			}
			local e = G.Npcs.addExtra(reg, n)
			if e then
				reg.metiers[role] = e
				local founder = G.Util.playerOf(v.founder)
				if founder and not cur then
					G.Util.toast(founder, "🏰 " .. n.name .. " s'installe à " .. v.name .. ".", "gain")
				end
			end
		end
	end
end

-- Le château : seigneur (ou dame) dans la cour, deux gardes de faction à la porte, jour et nuit
local function spawnCastle(reg)
	local model = reg.castle
	if not model or not model.Parent then
		return
	end
	local cour = model:FindFirstChild("Cour")
	local base = model.PrimaryPart
	local entree = base and base:FindFirstChild("Entree")
	local taken = {}
	local posts = {}
	if cour and cour:IsA("BasePart") then
		local p = cour.Position
		table.insert(posts, { role = "lord", work = { p.X, p.Z, p.Y + cour.Size.Y / 2 } })
	end
	if entree then
		local cf = entree.WorldCFrame
		for i, side in { -1, 1 } do
			local p = (cf * CFrame.new(side * 4.5, 0, 2)).Position
			table.insert(posts, { role = "guard" .. i, work = { p.X, p.Z, p.Y } })
		end
	end
	for _, post in posts do
		local cur = reg.metiers[post.role]
		local id = not (cur and cur.model.Parent and cur.state ~= "gone") and Metiers.currentId(reg, post.role)
		local isLord = post.role == "lord"
		if id then
			local rng = Random.new(G.WG.hash(G.world.seed, "chateau-pnj", reg.rx, reg.rz, id))
			local female = rng:NextNumber() < (isLord and 0.5 or 0.3)
			local n = {
				id = id, name = pickName(rng, female, taken), female = female, role = isLord and "lord" or "guard",
				metier = isLord and "lord" or "guard", persona = isLord and ({ "bourru", "radin", "pieux", "jovial" })[rng:NextInteger(1, 4)] or "bourru",
				look = makeLook(rng, female, nil), work = post.work, plaza = post.work, village = reg.castleVillage and reg.castleVillage.name,
				shopkeeper = true, radius = isLord and 6 or 1, maxHp = isLord and 100 or 150,
				hours = not isLord and { 0, 24 } or nil, -- les gardes ne dorment pas
			}
			local e = G.Npcs.addExtra(reg, n)
			if e then
				dress(e, isLord and LORD.garb or GUARD.garb)
				reg.metiers[post.role] = e
			end
		end
	end
end

local function spawnRole(reg, role: string, houses, taken)
	local def = ROLES[role]
	local h = building(reg, def.at)
	if not h then
		return nil -- pas de forge dans ce village : pas de forgeron
	end
	local id, st = Metiers.currentId(reg, role)
	if not id then
		return nil
	end
	local rng = Random.new(G.WG.hash(G.world.seed, "metiers", reg.rx, reg.rz, role, st.gen))
	local female = rng:NextNumber() < 0.5
	local center = centerOf(reg)
	local n = {
		id = id, name = pickName(rng, female, taken), female = female, role = role, metier = role,
		persona = def.persona or ADULT_PERSONAS[rng:NextInteger(1, #ADULT_PERSONAS)],
		look = makeLook(rng, female, def.hat), work = workSpot(h, def.front or 8, def.side), plaza = { center.X, center.Z },
		village = reg.plan.poi.name, house = #houses > 0 and houses[rng:NextInteger(1, #houses)] or nil, second = true,
		shopkeeper = def.products ~= nil, radius = 3, maxHp = def.maxHp,
	}
	local e = G.Npcs.addExtra(reg, n)
	if e then
		dress(e, def.garb)
		reg.metiers[role] = e
	end
	return e
end

local function spawnKids(reg, houses, taken)
	local n = math.clamp(#houses // 3, 1, 3)
	local center = centerOf(reg)
	for i = 1, n do
		local rng = Random.new(G.WG.hash(G.world.seed, "metiers-enfants", reg.rx, reg.rz, i))
		local female = rng:NextNumber() < 0.5
		local d = {
			id = "m:" .. reg.key .. ":enfant" .. i, name = pickName(rng, female, taken), female = female, role = "child", metier = "child",
			child = true, persona = CHILD_PERSONAS[rng:NextInteger(1, #CHILD_PERSONAS)], look = makeLook(rng, female, nil),
			work = { center.X + rng:NextNumber(-6, 6), center.Z + rng:NextNumber(-6, 6) }, plaza = { center.X, center.Z },
			village = reg.plan.poi.name, house = #houses > 0 and houses[rng:NextInteger(1, #houses)] or nil, second = true,
			radius = 16, walk = 11, run = 14, restless = true, hours = { 7, 20 }, maxHp = 40,
		}
		local e = G.Npcs.addExtra(reg, d)
		if e then
			dress(e, nil, true)
			table.insert(reg.metierKids, e)
		end
	end
end

-- Le colporteur passe-t-il dans ce village aujourd'hui ? (même réponse pour tous les serveurs)
local function peddlerToday(reg): boolean
	local rng = Random.new(G.WG.hash(G.world.seed, "colporteur", G.world.day, reg.rx, reg.rz))
	return rng:NextNumber() < PEDDLER_CHANCE
end

-- Marchandise du jour : graines et plantes d'AUTRES biomes que celui du village, plus une rareté
local function peddlerStock(reg)
	local v = village(reg.key)
	local p = v.colporteur
	if p and p.day == G.world.day then
		return p
	end
	local rng = Random.new(G.WG.hash(G.world.seed, "colporteur-stock", G.world.day, reg.rx, reg.rz))
	local biome = reg.plan.biome or "prairie"
	local pool = {}
	for id, crop in Config.CROPS do
		if not table.find(crop.biomes, biome) and Config.ITEMS["seed_" .. id] then
			table.insert(pool, "seed_" .. id)
		end
	end
	local herbs = G.Herbes and G.Herbes.POOLS
	if herbs then
		for b, list in herbs do
			if b ~= biome then
				for _, hb in list do
					if Config.ITEMS[hb[1]] and not table.find(pool, hb[1]) then
						table.insert(pool, hb[1])
					end
				end
			end
		end
	end
	table.sort(pool)
	local stock, order = {}, {}
	for _ = 1, math.min(6, #pool) do
		local it = table.remove(pool, rng:NextInteger(1, #pool))
		stock[it] = rng:NextInteger(2, 5)
		table.insert(order, it)
	end
	local rares = {}
	for it in PEDDLER_RARE do
		if Config.ITEMS[it] then
			table.insert(rares, it)
		end
	end
	table.sort(rares)
	if #rares > 0 then
		local it = rares[rng:NextInteger(1, #rares)]
		stock[it] = 1
		table.insert(order, it)
	end
	p = { day = G.world.day, stock = stock, order = order }
	v.colporteur = p
	return p
end

local function spawnPeddler(reg, forced: boolean?)
	if reg.metierPeddler or not (forced or peddlerToday(reg)) then
		return
	end
	local h = G.Clock.hour()
	if h < 8 or h >= 19 then
		return
	end
	local rng = Random.new(G.WG.hash(G.world.seed, "colporteur-pnj", G.world.day, reg.rx, reg.rz))
	local female = rng:NextNumber() < 0.4
	local center = centerOf(reg)
	local off = Vector3.new(rng:NextNumber(-10, 10), 0, rng:NextNumber(-10, 10))
	local n = {
		id = "m:" .. reg.key .. ":colporteur:" .. G.world.day, name = pickName(rng, female, takenNames(reg)), female = female,
		role = "peddler", metier = "peddler", persona = ADULT_PERSONAS[rng:NextInteger(1, #ADULT_PERSONAS)],
		look = makeLook(rng, female, PEDDLER.hat), work = { center.X + off.X, center.Z + off.Z }, plaza = { center.X, center.Z },
		village = reg.plan.poi.name, shopkeeper = true, radius = 4, hours = { 8, 19 },
	}
	local e = G.Npcs.addExtra(reg, n)
	if e then
		dress(e, PEDDLER.garb)
		reg.metierPeddler = e
		peddlerStock(reg)
	end
end

function Metiers.onRegionLoad(reg)
	if not G.Npcs.addExtra then
		return
	end
	if reg.castle then
		reg.metiers = {}
		local ok, err = pcall(spawnCastle, reg)
		if not ok then
			warn("[WildAcres] Metiers château : " .. tostring(err))
		end
		return
	end
	if reg.hamlet then
		local ok, err = pcall(Metiers.spawnHamlet, reg)
		if not ok then
			warn("[WildAcres] Metiers hameau : " .. tostring(err))
		end
		return
	end
	local poi = reg.plan.poi
	if not poi or poi.kind ~= "village" then
		return
	end
	reg.metiers = {}
	reg.metierKids = {}
	local houses = homes(reg)
	local taken = takenNames(reg)
	for _, role in ORDER do
		local ok, err = pcall(spawnRole, reg, role, houses, taken)
		if not ok then
			warn("[WildAcres] Metiers " .. role .. " : " .. tostring(err))
		end
		task.wait()
	end
	local ok, err = pcall(spawnKids, reg, houses, taken)
	if not ok then
		warn("[WildAcres] Metiers enfants : " .. tostring(err))
	end
	pcall(spawnPeddler, reg)
end

-- tests / admin : fait venir le colporteur aujourd'hui dans ce village (s'il est chargé, de jour)
function Metiers.forcePeddler(regKey: string): boolean
	for _, reg in G.World.loaded do
		if reg.key == regKey and reg.metiers then
			spawnPeddler(reg, true)
			return reg.metierPeddler ~= nil
		end
	end
	return false
end

function Metiers.onRegionUnload(reg)
	reg.metiers, reg.metierKids, reg.metierPeddler = nil, nil, nil
end

-- Villages : le comptoir (taverne, forge, écurie) est tenu par une personne, plus par une invite
-- posée sur le bâtiment
local HANDLED = { Taverne = true, Forge = true, Ecurie = true }
function Metiers.handles(model: string): boolean
	return HANDLED[model] == true
end

function Metiers.init(g)
	G = g
	Config = G.Config
	D = G.Dialogue
	-- objets inconnus du catalogue : retirés (et signalés) plutôt que de planter une boutique
	for role, def in ROLES do
		for _, key in { "inputs", "products" } do
			local list = def[key]
			if list then
				for i = #list, 1, -1 do
					if not Config.ITEMS[list[i]] then
						warn("[WildAcres] Metiers." .. role .. " : objet inconnu « " .. list[i] .. " »")
						table.remove(list, i)
					end
				end
				def[key .. "Set"] = {}
				for _, it in list do
					def[key .. "Set"][it] = true
				end
			end
		end
	end
end

-- ----------------------------------------------------------------- Boutique (appelé par Shop)

function Metiers.label(e): string
	local role = e.data.metier
	if role == "child" then
		return e.data.female and "Fillette" or "Garçon"
	end
	local def = ROLES[role] or (role == "peddler" and PEDDLER) or (role == "lord" and LORD) or (role == "guard" and GUARD)
	if not def then
		return "Habitant"
	end
	return e.data.female and def.labelF or def.label
end

function Metiers.hasShop(e): boolean
	local role = e.data.metier
	return role == "peddler" or role == "lord" or (ROLES[role] ~= nil and ROLES[role].products ~= nil)
end

function Metiers.shopTitle(e): string
	local role = e.data.metier
	if role == "lord" then
		return "Trophées pour " .. (e.data.female and "Dame " or "Sire ") .. e.data.name
	end
	if role == "peddler" then
		return "Hotte de " .. e.data.name .. " (" .. string.lower(Metiers.label(e)) .. ")"
	end
	local def = ROLES[role]
	return (def and def.shop or "Échoppe") .. " de " .. e.data.name
end

local function localCrops(e)
	local biome = e.root and G.Clock.biomeAt(e.root.Position) or "prairie"
	local set = {}
	for id, crop in Config.CROPS do
		if table.find(crop.biomes, biome) and Config.ITEMS[id] then
			set[id] = true
		end
	end
	return set
end

-- articles à vendre (avec leur stock) + ce que ce PNJ accepte de racheter
function Metiers.catalog(player: Player, e)
	local role = e.data.metier
	local buy, wants = {}, {}
	if role == "lord" then
		-- il ne vend rien ; il paie les trophées de créatures (prises, âmes de boss)
		for item in G.Joueurs.get(player).inv do
			if isTrophy(item) then
				wants[item] = true
			end
		end
		return buy, wants
	end
	if role == "peddler" then
		local p = peddlerStock(e.reg)
		for _, it in p.order do
			local n = p.stock[it] or 0
			local info = Config.ITEMS[it]
			if n > 0 and info then
				table.insert(buy, { item = it, n = n, name = info.name, icon = info.icon,
					price = math.max(1, math.floor(G.Shop.buyPrice(player, e, priceOf(it)) * PEDDLER_PREMIUM)) })
			end
		end
		return buy, localCrops(e)
	end
	local def = ROLES[role]
	if not def or not def.products then
		return buy, {}
	end
	local st = roleState(e.reg.key, role)
	for _, it in def.products do
		local n = st.stock[it] or 0
		local info = Config.ITEMS[it]
		if n > 0 and info then
			table.insert(buy, { item = it, n = n, name = info.name, icon = info.icon, price = G.Shop.buyPrice(player, e, info.price) })
		end
	end
	return buy, def.inputsSet or wants
end

-- objets que les gens de métier VENDENT -> multiplicateur de leur prix le plus bas (anti-arbitrage
-- de Shop.sellPrice) : produits des artisans au prix normal, plantes d'ailleurs chez le colporteur
function Metiers.soldItems()
	local t = {}
	for _, def in ROLES do
		for _, it in def.products or {} do
			t[it] = 1
		end
	end
	for _, list in (G.Herbes and G.Herbes.POOLS) or {} do
		for _, hb in list do
			if Config.ITEMS[hb[1]] then
				t[hb[1]] = math.min(t[hb[1]] or math.huge, PEDDLER_PREMIUM)
			end
		end
	end
	return t
end

-- multiplicateur de rachat d'un objet par ce PNJ (sa spécialité)
function Metiers.bonus(e, item: string): number
	local role = e.data.metier
	if role == "lord" then
		return isTrophy(item) and LORD.bonus or 1
	end
	if role == "peddler" then
		return localCrops(e)[item] and PEDDLER_BUY or 1
	end
	local def = ROLES[role]
	return (def and def.inputsSet and def.inputsSet[item]) and SPECIALTY or 1
end

function Metiers.bought(e, item: string, n: number)
	local role = e.data.metier
	local stock
	if role == "peddler" then
		stock = peddlerStock(e.reg).stock
	elseif ROLES[role] then
		stock = roleState(e.reg.key, role).stock
	end
	if stock then
		stock[item] = math.max(0, (stock[item] or 0) - n)
	end
end

-- matières vendues à l'artisan : elles deviendront sa fournée de demain
function Metiers.sold(e, item: string, n: number)
	local def = ROLES[e.data.metier]
	if def and def.inputsSet and def.inputsSet[item] then
		local st = roleState(e.reg.key, e.data.metier)
		st.points = (st.points or 0) + priceOf(item) * n
	end
end

function Metiers.greeting(e, buy): string?
	if #buy > 0 then
		return nil
	end
	local role = e.data.metier
	if role == "lord" then
		return "Je ne vends rien. Mais je paie bien les trophées des bêtes qui menacent mes terres."
	elseif role == "baker" then
		return "Plus une miette ! Apporte-moi du grain, je cuirai demain."
	elseif role == "cook" then
		return "Marmite vide… Rapporte-moi de quoi cuisiner."
	elseif role == "blacksmith" then
		return "Le feu est froid faute de minerai. Apporte-m'en."
	elseif role == "healer" then
		return "Mes fioles sont vides. Il me faudrait des plantes."
	elseif role == "peddler" then
		return "Tout est parti ! Je repasserai un de ces jours."
	end
	return "Rien pour le moment. Repasse demain."
end

-- ----------------------------------------------------------------- Dialogue (appelé par Npcs)

local function usedToday(e, player: Player, what: string): boolean
	e.per.daily = e.per.daily or {}
	return e.per.daily[G.Util.pid(player) .. ":" .. what] == G.world.day
end

local function markToday(e, player: Player, what: string)
	e.per.daily = e.per.daily or {}
	e.per.daily[G.Util.pid(player) .. ":" .. what] = G.world.day
end

local function sparkle(player: Player, color: Color3)
	local r = G.Util.root(player)
	if not r then
		return
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(color)
	pe.LightEmission = 0.8
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new(0.1, 1)
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, 4, 0)
	pe.Rate = 0
	pe.Parent = r
	pe:Emit(28)
	Debris:AddItem(pe, 2)
end

-- « de Baron », « d'Écuyer »
local function deTitre(name: string): string
	local first = string.sub(name, 1, 1)
	local vowel = string.find("AEIOUaeiou", first, 1, true) ~= nil or string.sub(name, 1, 2) == "É"
	return (vowel and "d'" or "de ") .. name
end

-- prochain titre de noblesse du joueur (nil : déjà baron)
function Metiers.nextRank(player: Player)
	local prof = G.Joueurs.get(player)
	local rank = (prof and prof.stats and prof.stats.noblesse) or 0
	return NOBILITY[rank + 1], rank
end

-- Diligence (19/11, « listes ennemi.txt » § transports) : le palefrenier mène en voiture vers un
-- village DÉJÀ découvert (journal), contre COACH_BASE + distance / COACH_STUDS or. Les 4 plus proches
-- sont proposés. La monture reste à l'écurie de départ (l'écurie d'arrivée la fait venir).
Metiers.COACH_BASE = 10
Metiers.COACH_STUDS = 25
function Metiers.coachTrips(player: Player, e)
	local Q = G.Quetes and rawget(G.Quetes, "villages")
	if not Q or not e.root then
		return {}
	end
	local known = {}
	for k in string.gmatch(G.Journal.keysFor(player) or "", "[^;]+") do
		known[k] = true
	end
	local here = e.root.Position
	local list = {}
	for _, v in Q() do
		local d = Vector2.new(v.x - here.X, v.z - here.Z).Magnitude
		if known[v.key] and d > 150 then
			local price = Metiers.COACH_BASE + math.floor(d / Metiers.COACH_STUDS)
			if G.Joueurs.talent and G.Joueurs.talent(player, "aventurier") > 0 then
				price = math.ceil(price / 2) -- talent Explorateur
			end
			table.insert(list, { key = v.key, name = v.name, x = v.x, z = v.z, price = price })
		end
	end
	table.sort(list, function(a, b)
		return a.price < b.price
	end)
	while #list > 4 do
		table.remove(list)
	end
	return list
end

-- options en plus des habituelles (avant « Au revoir »)
function Metiers.addOptions(e, player: Player, opts)
	local role = e.data.metier
	local def = ROLES[role]
	local add = {}
	if Metiers.hasShop(e) then
		table.insert(add, { id = "trade", text = (def and def.trade) or (role == "lord" and LORD.trade) or PEDDLER.trade })
	end
	if role == "lord" then
		local nxt = Metiers.nextRank(player)
		if nxt then
			local pending = e.knight and e.knight[player]
			if pending and os.clock() - pending < 30 then
				table.insert(add, { id = "m:adouber_ok", text = "✅ Je prête serment (" .. nxt.gold .. " or)" })
			else
				table.insert(add, { id = "m:adouber", text = "⚔️ Demander le titre " .. deTitre(nxt.name) })
			end
		end
	end
	for _, s in (def and def.services) or {} do
		if s == "repas" then
			table.insert(add, { id = "m:repas", text = "🍲 Un repas chaud (12 or)" })
		elseif s == "reparer" then
			table.insert(add, { id = "m:reparer", text = "🔨 Réparer tous mes outils" })
		elseif s == "soigner" then
			table.insert(add, { id = "m:soigner", text = "💚 Me soigner (" .. HEAL_COST .. " or)" })
		elseif s == "benir" then
			table.insert(add, { id = "m:benir", text = "✨ Recevoir une bénédiction (" .. BLESS_COST .. " or)" })
		elseif s == "confesser" then
			table.insert(add, { id = "m:confesser", text = "🕯️ Me confesser" })
		elseif s == "aumone" then
			table.insert(add, { id = "m:aumone", text = "🙏 Faire l'aumône (" .. ALMS_COST .. " or)" })
		elseif s == "monture" then
			table.insert(add, { id = "m:monture", text = "🐴 Faire venir ma monture" })
		elseif s == "changer" then
			table.insert(add, { id = "m:changer", text = "🔁 Changer de monture (écurie)" })
		elseif s == "pouliner" then
			table.insert(add, { id = "m:pouliner", text = "🐣 Faire pouliner (3 carottes, 40 or)" })
		elseif s == "coiffure" then
			table.insert(add, { id = "m:coiffure", text = "✂️ Changer de coiffure" })
		elseif s == "couture" then
			table.insert(add, { id = "m:couture", text = "🧵 Changer de tenue" })
		elseif s == "diligence" then
			-- la diligence : vers les villages déjà découverts, les plus proches d'abord
			for _, t in Metiers.coachTrips(player, e) do
				table.insert(add, { id = "m:dili_" .. t.key, text = string.format("🐴 Diligence pour %s (%d or)", t.name, t.price) })
			end
		end
	end
	if def and def.inputs then
		table.insert(add, { id = "m:besoins", text = "❓ De quoi as-tu besoin ?" })
	end
	-- avant « Au revoir » (la dernière)
	local at = #opts
	if opts[at] and opts[at].id == "bye" then
		for i, o in add do
			table.insert(opts, at + i - 1, o)
		end
	else
		for _, o in add do
			table.insert(opts, o)
		end
	end
	return opts
end

function Metiers.childOptions(e, player: Player)
	local opts = { { id = "m:bavarder", text = "Salut, petit" .. (e.data.female and "e" or "") .. " !" } }
	if not usedToday(e, player, "secret") then
		table.insert(opts, { id = "m:secret", text = "🤫 Tu connais un secret ?" })
	end
	if not usedToday(e, player, "chat") then
		table.insert(opts, { id = "m:jouer", text = "🏃 On joue à chat ?" })
	end
	table.insert(opts, { id = "bye", text = "Au revoir" })
	return opts
end

local PEDDLER_LINES = {
	"Approche, approche ! Des marchandises de tout le pays, à peine arrivées !",
	"Je ne reste qu'aujourd'hui : demain, je serai sur une autre route.",
	"Des graines d'ailleurs, des plantes rares… et je rachète bien ce qui pousse ici.",
}

local LORD_LINES = {
	"Approche, {titre}. Les nouvelles des terres m'intéressent toujours.",
	"Ces bêtes qui rôdent autour du village… Rapporte-m'en les trophées, je paierai.",
	"Un vassal fidèle vaut plus qu'une tour de pierre. Le serais-tu ?",
}

local function childLine(e): string
	return D.format(CHILD_LINES[math.random(1, #CHILD_LINES)], { e = e.data.female and "e" or "" })
end

function Metiers.greet(e, player: Player): string?
	if e.data.child then
		return childLine(e)
	elseif e.data.metier == "peddler" then
		return PEDDLER_LINES[math.random(1, #PEDDLER_LINES)]
	elseif e.data.metier == "lord" then
		return D.format(LORD_LINES[math.random(1, #LORD_LINES)], { titre = D.title_for(G.Joueurs.get(player).honor) })
	end
	return nil
end

-- ce qu'un enfant sait du coin : une grotte cachée près d'ici, sinon un lieu à visiter
local function secretFor(e): string
	local reg = e.reg
	local pos = e.root.Position
	local best, bestD
	if G.Donjons and G.Donjons.siteNear then
		for dx = -2, 2 do
			for dz = -2, 2 do
				local s = G.Donjons.siteNear(reg.rx + dx, reg.rz + dz)
				if s then
					local d = (Vector3.new(s.x, 0, s.z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
					if not bestD or d < bestD then
						best, bestD = s, d
					end
				end
			end
		end
	end
	if best then
		local dir = D.direction_word(best.x - pos.X, best.z - pos.Z)
		local far = bestD < 250 and "pas loin" or (bestD < 600 and "un peu loin" or "très loin")
		return "Chut… Il y a une grotte cachée au pied d'une falaise, " .. dir .. ", " .. far .. " d'ici. Ça souffle froid quand on s'approche ! Mais faut pas y aller sans arme, y a des monstres."
	end
	local places = G.wg:placesAround(reg.rx, reg.rz, 3)
	for _, poi in places do
		if poi.kind ~= "village" then
			local dir = D.direction_word(poi.ax * Config.CELL - pos.X, poi.az * Config.CELL - pos.Z)
			return "Les grands disent qu'il y a " .. G.WG.placeLabel(poi) .. " " .. dir .. ". Moi, j'ai jamais osé y aller."
		end
	end
	return "Je connais tous les recoins du village… mais rien de vraiment secret, promis."
end

-- Choix « m:… » du dialogue. Renvoie un texte (le dialogue reste ouvert) ou false (fermé).
function Metiers.choice(player: Player, e, what: string): (string | boolean)?
	local prof = G.Joueurs.get(player)
	local role = e.data.metier
	local def = ROLES[role]
	local function has(service)
		return def and def.services and table.find(def.services, service) ~= nil
	end
	if what == "bavarder" and e.data.child then
		return childLine(e)
	elseif what == "secret" and e.data.child then
		if usedToday(e, player, "secret") then
			return "J'ai déjà tout dit ! Reviens demain."
		end
		-- un enfant ne se confie qu'à quelqu'un de gentil (avis), ou qui a gagné à chat
		if G.Npcs.op(e, player) < 5 and not (e.per.daily or {})[G.Util.pid(player) .. ":caught"] then
			G.Util.emote(e.model, "sly", 2)
			return "Un secret ? Attrape-moi d'abord ! (Joue à chat avec moi.)"
		end
		markToday(e, player, "secret")
		G.Util.emote(e.model, "happy", 2)
		return secretFor(e)
	elseif what == "jouer" and e.data.child then
		if usedToday(e, player, "chat") then
			return "Je suis tout essoufflé… Demain !"
		end
		markToday(e, player, "chat")
		e.tag = { player = player, untilT = os.clock() + 20 }
		e.target = player
		G.Npcs.setState(e, "flee")
		G.Util.emote(e.model, "happy", 2)
		G.Util.toast(player, "🏃 Attrape " .. e.data.name .. " en moins de 20 secondes !")
		return false
	elseif what == "besoins" and def and def.inputs then
		local names = {}
		for i, it in def.inputs do
			if i > 8 then
				break
			end
			local info = Config.ITEMS[it]
			table.insert(names, info.icon .. " " .. info.name)
		end
		return (def.intro or "") .. "\nJe rachète bien : " .. table.concat(names, ", ") .. "."
	elseif what == "repas" and has("repas") then
		if G.Villages.meal(player) then
			G.Util.emote(e.model, "happy", 2)
			return "Bon appétit ! Ça tient au corps, hein ?"
		end
		return false
	elseif what == "reparer" and has("reparer") then
		G.Shop.repairAll(player)
		G.Npcs.oneShot(e, "slash")
		G.Util.sfx("forge", e.root.Position)
		return false
	elseif what == "soigner" and has("soigner") then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return false
		end
		local slowed = (player:GetAttribute("SlowUntil") or 0) > os.clock()
		if hum.Health >= hum.MaxHealth and not slowed then
			return "Tu te portes comme un charme. Garde ton or."
		end
		if not G.Joueurs.take(player, "gold", HEAL_COST) then
			return "Les remèdes ont un prix : " .. HEAL_COST .. " or."
		end
		hum.Health = hum.MaxHealth
		player:SetAttribute("SlowUntil", 0)
		G.Joueurs.sync(player)
		sparkle(player, Color3.fromRGB(120, 230, 120))
		G.Economie.record(player, "soin", "-" .. HEAL_COST)
		return "Voilà. Un cataplasme, une infusion… Te voilà sur pied."
	elseif what == "benir" and has("benir") then
		if not G.Joueurs.take(player, "gold", BLESS_COST) then
			return "Une offrande de " .. BLESS_COST .. " or pour la chapelle, mon enfant."
		end
		G.Politique.credit(e.reg.key, BLESS_COST, "chapelle")
		G.Joueurs.addBuff(player, "chance", 2, 15 * 60, "Bénédiction")
		G.Joueurs.sync(player)
		sparkle(player, Color3.fromRGB(255, 230, 140))
		G.Util.emote(e.model, "smile", 2)
		return "Que la chance guide tes pas. (L'offrande ira au trésor du village.)"
	elseif what == "confesser" and has("confesser") then
		if prof.stars > 0 then
			return "Ta prime, c'est au shérif qu'il faut la régler. Moi, je ne m'occupe que des âmes."
		end
		if prof.honor >= 0 then
			return "Ta conscience est tranquille. Va en paix."
		end
		if usedToday(e, player, "confesser") then
			return "Une confession par jour suffit. Reviens demain."
		end
		local pts = math.min(-prof.honor, 10)
		local cost = pts * 5
		if G.Joueurs.count(player, "gold") < cost then
			pts = math.floor(G.Joueurs.count(player, "gold") / 5)
			cost = pts * 5
		end
		if pts <= 0 then
			return "La pénitence, c'est 5 or par faute. Reviens quand tu pourras."
		end
		if not G.Joueurs.take(player, "gold", cost) then
			return false
		end
		markToday(e, player, "confesser")
		G.Law.addHonor(player, pts)
		G.Politique.credit(e.reg.key, cost, "chapelle")
		G.Economie.record(player, "confession", "+" .. pts .. " honneur (-" .. cost .. ")")
		G.Joueurs.sync(player)
		sparkle(player, Color3.fromRGB(230, 230, 255))
		return "Tes fautes sont pardonnées… en partie. (+" .. pts .. " honneur, " .. cost .. " or au trésor du village.)"
	elseif what == "aumone" and has("aumone") then
		if not G.Joueurs.take(player, "gold", ALMS_COST) then
			return "Ton cœur est généreux, mais ta bourse est vide."
		end
		G.Politique.credit(e.reg.key, ALMS_COST, "aumone")
		G.Npcs.addOp(e, player, 3)
		local txt = "Merci. Ces " .. ALMS_COST .. " or iront au trésor du village."
		if not usedToday(e, player, "aumone") and prof.honor < 25 then
			G.Law.addHonor(player, 1)
			txt ..= " (+1 honneur)"
		end
		markToday(e, player, "aumone")
		G.Joueurs.sync(player)
		G.Util.emote(e.model, "heart", 2)
		return txt
	elseif (what == "adouber" or what == "adouber_ok") and role == "lord" then
		local nxt, rank = Metiers.nextRank(player)
		e.knight = e.knight or setmetatable({}, { __mode = "k" })
		if not nxt then
			return "Tu es déjà baron" .. (prof.honor >= 0 and "" or ", même si ta réputation en souffre") .. ". Je n'ai rien de plus à t'offrir."
		end
		if prof.stars > 0 then
			e.knight[player] = nil
			return "Un recherché, anobli ? Règle d'abord tes comptes avec le shérif."
		end
		if prof.honor < nxt.honor then
			e.knight[player] = nil
			return "Pour être " .. nxt.name .. ", il faut une réputation sans tache (honneur " .. nxt.honor .. ", tu en as " .. prof.honor .. ")."
		end
		if what == "adouber" or not e.knight[player] or os.clock() - e.knight[player] > 30 then
			-- action coûteuse et définitive : on demande confirmation
			e.knight[player] = os.clock()
			return "Le titre " .. deTitre(nxt.name) .. " se paie " .. nxt.gold .. " or, versés au trésor du village. Tu prêtes serment ?"
		end
		e.knight[player] = nil
		if not G.Joueurs.take(player, "gold", nxt.gold) then
			return "Il te manque de l'or : " .. nxt.gold .. " or pour le titre " .. deTitre(nxt.name) .. "."
		end
		prof.stats.noblesse = rank + 1
		G.Joueurs.markDirty(player)
		local vk = e.reg.castleVillage and e.reg.castleVillage.key
		G.Politique.credit(vk, nxt.gold, "noblesse")
		G.Economie.record(player, "noblesse", nxt.name .. " (-" .. nxt.gold .. ")")
		G.Social.checkTitles(player)
		G.Joueurs.sync(player)
		G.Avatar.applyCape(player) -- la cape de son rang, tout de suite
		sparkle(player, Color3.fromRGB(255, 215, 90))
		G.Util.sfx("pieces", e.root.Position)
		G.Npcs.addOp(e, player, 10)
		return "Relève-toi, " .. nxt.name .. " " .. player.DisplayName .. ". Porte ce titre — et cette cape — avec honneur."
	elseif what == "monture" and has("monture") then
		local at = e.root.Position + e.root.CFrame.LookVector * 6
		G.Horses.fetch(player, at)
		return false
	elseif what == "coiffure" and has("coiffure") then
		G.Avatar.open(player, "barbier", e)
		return false
	elseif what == "couture" and has("couture") then
		G.Avatar.open(player, "tailleur", e)
		return false
	elseif string.sub(what, 1, 5) == "dili_" and has("diligence") then
		local key = string.sub(what, 6)
		for _, t in Metiers.coachTrips(player, e) do
			if t.key == key then
				if (G.Joueurs.get(player).stars or 0) > 0 then
					return "Avec ta tête sur les avis de recherche ? Le cocher ne veut pas d'ennuis."
				end
				if not G.Joueurs.take(player, "gold", t.price) then
					return "La place coûte " .. t.price .. " or."
				end
				G.Joueurs.sync(player)
				G.remotes.Fade:FireClient(player, "🐴 En route pour " .. t.name .. "…", 0) -- écran noir
				task.delay(1.2, function()
					if player.Parent then
						G.Game.teleport(player, Vector3.new(t.x + 6, G.Util.groundY(t.x + 6, t.z + 6), t.z + 6))
						task.wait(1.4)
						G.remotes.Fade:FireClient(player, nil, 1)
						G.Util.toast(player, "🐴 Bienvenue à " .. t.name .. ".", "big")
					end
				end)
				return false
			end
		end
		return "Je ne connais pas la route de ce village."
	elseif what == "changer" and has("changer") then
		G.Horses.swap(player, e.root.Position + e.root.CFrame.LookVector * 6)
		return false
	elseif what == "pouliner" and has("pouliner") then
		G.Horses.breed(player)
		return false
	end
	return nil
end

-- ----------------------------------------------------------------- Boucle

-- le colporteur s'en va : son entrée de PNJ (une par jour et par village) ne reste pas dans la sauvegarde
local function peddlerLeaves(reg)
	local ped = reg.metierPeddler
	if not ped or ped.state == "carried" then
		return
	end
	reg.metierPeddler = nil
	G.Npcs.remove(ped)
	G.world.npcs[ped.id] = nil
end

local acc = 0
local function nearPlayer(pos: Vector3, r: number): boolean
	for _, p in G.Game.players() do
		local root = G.Util.root(p)
		if root and (root.Position - pos).Magnitude < r then
			return true
		end
	end
	return false
end

local function tagStep(e)
	local t = e.tag
	local r = t and G.Util.root(t.player)
	if not t or not r or not t.player.Parent then
		e.tag = nil
		return
	end
	if (r.Position - e.root.Position).Magnitude < 4.5 then
		e.tag = nil
		e.per.daily = e.per.daily or {}
		e.per.daily[G.Util.pid(t.player) .. ":caught"] = G.world.day
		G.Npcs.addOp(e, t.player, 6)
		G.Npcs.setState(e, "routine")
		G.Util.emote(e.model, "love", 2.5)
		G.Npcs.oneShot(e, "laugh")
		G.Util.toast(t.player, "🎉 Touché ! " .. e.data.name .. " rit aux éclats. (Demande-lui un secret…)", "gain")
	elseif os.clock() > t.untilT then
		e.tag = nil
		G.Npcs.setState(e, "routine")
		G.Util.emote(e.model, "sly", 2.5)
		G.Util.toast(t.player, "😜 " .. e.data.name .. " : « Trop lent ! »")
	elseif e.state ~= "flee" then
		-- la fuite s'arrête toute seule quand on est loin : on la relance tant que le jeu dure
		e.target = t.player
		G.Npcs.setState(e, "flee")
	end
end

function Metiers.step(dt: number)
	acc += dt
	if acc < 0.25 then
		return
	end
	acc = 0
	local hour = G.Clock.hour()
	for _, reg in G.World.loaded do
		if reg.metiers then
			-- le forgeron bat le fer : un coup de marteau toutes les 2-3 s quand quelqu'un est près
			local smith = reg.metiers.blacksmith
			if smith and smith.model.Parent and smith.state == "routine" and hour >= 8 and hour < 18 then
				smith.hammerT = (smith.hammerT or 0) - 0.25
				if smith.hammerT <= 0 then
					smith.hammerT = 2 + math.random() * 1.2
					if nearPlayer(smith.root.Position, 70) and smith.hum.MoveDirection.Magnitude < 0.1 then
						G.Npcs.oneShot(smith, "slash")
						G.Util.sfx("forge", smith.root.Position)
					end
				end
			end
			for _, kid in reg.metierKids or {} do
				if kid.tag then
					tagStep(kid)
				elseif kid.state == "routine" and math.random() < 0.004 and nearPlayer(kid.root.Position, 50) then
					G.Util.emote(kid.model, "happy", 1.5)
				end
			end
			-- le colporteur remballe le soir ; un autre jour, il passera ailleurs
			local ped = not reg.castle and reg.metierPeddler
			-- (assommé ou porté : on ne le fait pas disparaître sous les yeux de qui s'en occupe)
			local busy = ped and (ped.state == "ko" or ped.state == "carried")
			if ped and not busy and (hour >= 19 or hour < 8 or ped.state == "gone") then
				peddlerLeaves(reg)
			elseif reg.metierKids and not ped and hour >= 8 and hour < 19 and math.random() < 0.01 then -- (villages seulement)
				pcall(spawnPeddler, reg)
			end
		end
	end
end

function Metiers.newDay()
	for _, v in root() do
		for role, st in v.roles or {} do
			pcall(Metiers.produce, role, st)
		end
	end
	for id, per in G.world.npcs do
		if per.daily and string.sub(id, 1, 2) == "m:" then
			for k, d in per.daily do
				if d ~= G.world.day then
					per.daily[k] = nil
				end
			end
		end
	end
	-- remplaçants des artisans disparus, dans les villages chargés
	for _, reg in G.World.loaded do
		if reg.metiers and reg.hamlet then
			pcall(Metiers.spawnHamlet, reg)
		elseif reg.metiers and reg.castle then
			-- château : le seigneur et les gardes manquants (spawnCastle ignore les postes tenus)
			local missing = false
			for _, role in { "lord", "guard1", "guard2" } do
				local cur = reg.metiers[role]
				if cur and (cur.state == "gone" or not cur.model.Parent) then
					reg.metiers[role] = nil
					missing = true
				elseif not cur then
					missing = true
				end
			end
			if missing then
				pcall(spawnCastle, reg)
			end
		elseif reg.metiers then
			local houses, taken = homes(reg), takenNames(reg)
			for _, role in ORDER do
				local cur = reg.metiers[role]
				if not cur or cur.state == "gone" or not cur.model.Parent then
					reg.metiers[role] = nil
					pcall(spawnRole, reg, role, houses, taken)
				end
			end
			peddlerLeaves(reg)
		end
	end
end

return Metiers
