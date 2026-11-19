-- Équilibre de la fabrication (19/11, docs/AUDIT-CRAFT.md). Appliqué à la fin de Config, juste avant
-- Catalogue.assignRarity (la rareté suit donc les prix corrigés). Fichier à part pour ne pas mélanger
-- les règles d'équilibre aux données des objets (Catalogue / Config) : ici, on CORRIGE.
--   1. Recettes copiées : une trentaine d'objets avaient exactement les mêmes ingrédients qu'un autre.
--      Chacun reçoit sa matière propre (souvent une matière qui ne servait qu'une fois : silex, corne…).
--   2. Paliers des métiers : quelques recettes demandent désormais le métier qui va avec (minage pour
--      l'acier, pêche pour l'hameçon, élevage pour le fromage, bûcheronnage pour le bois dur).
--   3. Prix plancher : un objet fabriqué vaut au moins 1,1 × ses ingrédients (avant, 50 recettes
--      faisaient perdre de l'or : paille, huile, sucre, barre de fer, bière…).
--   4. Cuisine : un plat nourrit toujours plus que ses ingrédients crus, et donne un EFFET DE REPAS
--      (bonus d'une caractéristique quelques minutes) selon ce qu'il contient. Les aliments crus n'en
--      donnent pas : c'est ce qui rend la cuisine utile.
-- Toute matière inconnue dans une correction la fait ignorer (avertissement), jamais d'objet cassé.

local E = {}

-- 1. nouvelles recettes : item -> { needs = …, count = …, station = …, back = …, price = … } (champs
--    remplacés) ; from = matière : ne corrige que la recette de l'objet qui en contient (objets à plusieurs recettes)
E.RECIPES = {
	-- petites pièces de fer (toutes « 1 lingot de fer » avant)
	hinge = { needs = { iron_ingot = 1, fat = 1 }, count = 3 },
	hook = { needs = { iron_ingot = 1, flint = 1 }, count = 4 },
	iron_ring = { needs = { iron_ingot = 1 }, count = 4, station = "furnace" },
	fitting = { needs = { iron_ingot = 1, nails = 2 }, count = 3 },
	-- cuivre
	buckle = { needs = { copper_ingot = 1, horn = 1 }, count = 4 },
	table_fork = { needs = { copper_ingot = 1, antler = 1 }, count = 2 },
	tankard = { needs = { copper_ingot = 2 }, station = "anvil" },
	-- bois
	wood_cup = { needs = { planks = 1, resin = 1 }, count = 2 },
	wood_plate = { needs = { planks = 1 }, count = 2, station = "bench" },
	spoon = { needs = { branches = 1 }, count = 3 },
	hoop = { needs = { planks = 1, iron_ring = 1 } },
	stool = { needs = { planks = 1, peg = 2 } },
	ladder = { needs = { planks = 2, branches = 2 }, count = 2 },
	comb = { needs = { bone = 1 }, count = 2, station = "bench" },
	-- pierre (la figurine rapportait 60 or pour 4 pierres, sans établi)
	stone_figurine = { needs = { stone = 6, flint = 1 }, station = "bench", price = 30 },
	wood_figurine = { needs = { oak_log = 2 }, station = "bench", price = 25 },
	irrigation = { needs = { stone = 4, gravel = 4 }, count = 2 },
	pedestal = { needs = { stone = 6 }, station = "bench" },
	arrow_slit = { needs = { stone = 6, iron_ring = 1 } },
	-- verre, tissu, métal
	vial = { needs = { glass = 1 }, count = 2, station = "alembic" },
	cloth = { needs = { wool = 2 }, count = 4, from = "wool" }, -- seulement la recette à la laine (lin, soie : à part)
	gear_iron = { needs = { iron_ingot = 3 }, station = "anvil" },
	barn_door = { needs = { hinge = 3, planks = 8, nails = 4 } },
	scroll_case = { needs = { leather = 1, planks = 1, copper_nails = 2 } },
	-- écrits
	songbook = { needs = { ink = 1, paper = 6, quill = 1 } },
	history_book = { needs = { ink = 2, paper = 6, old_page = 1, leather = 1 } },
	diploma = { needs = { ink = 1, parchment = 1, wax_seal = 1, ribbon = 1 } },
	-- corde à la gelée : 13 or d'ingrédients pour 2 cordes à 5 or → 3 cordes
	rope = { needs = { slime_gel = 2, fiber = 1 }, count = 3, from = "slime_gel" },
	-- l'eau rend le seau (avant : seau ET gobelet perdus pour 2 eaux)
	water = { needs = { bucket = 1, wood_cup = 1 }, count = 2, back = { bucket_empty = 1 } },
}

-- équipement : nom de la pièce -> ingrédients remplacés (needs) ou ajoutés (add)
E.GEAR = {
	["Marteau de forgeron"] = { needs = { iron_ingot = 3, oak_log = 1 } },
	["Faucille"] = { needs = { iron_ingot = 1, planks = 1, flint = 1 } },
	["Faux"] = { needs = { steel = 1, pine_log = 1, leather_strap = 1 } },
	["Sacoche de selle"] = { needs = { buckle = 2, leather = 3, rope = 1 } },
	-- les arcs étaient de loin les pièces les moins chères du jeu pour leurs stats
	["Arc court"] = { add = { rope = 1, leather = 1 } },
	["Arc long"] = { add = { leather = 1, linen_thread = 2 } },
	["Turban de lin"] = { add = { linen_thread = 1 } }, -- même recette que la Tunique
}

-- 5. équipement : une rareté doit valoir son prix (avant : rareté 4 ≈ 4 × le coût de la 3 pour +1,6
--    de stat). Minimum de stats totales par rareté ; la stat principale reçoit la différence.
E.RARITY_FLOOR = { [3] = 8, [4] = 12 }
-- la Discrétion (voie Hors-la-loi) n'était que sur 37 pièces : les pièces furtives par nature en gagnent
E.STEALTHY = { "Capuche", "Cape", "Masque", "Dague", "Gants", "Bottes souples", "Manteau sombre", "Cagoule" }
-- 6. pièces de maître (artisanat 40 à 50 : avant, plus rien à débloquer après 37). Matières rares qui
--    ne servaient presque pas. { emplacement, nom, rareté, stats, ingrédients, niveau, power, visual }
E.MASTER = {
	{ "trinket", "Pierre-cœur lumineuse", 4, { vie = 7, chance = 5, defense = 3 }, { glowstone = 2, ancient_root = 1, silver_ingot = 2 }, 40 },
	{ "weapon", "Lame du météore", 4, { force = 9, chance = 4, vitesse = 3 }, { steel = 4, meteorite = 2, gold_ingot = 1, leather = 2 }, 42, power = 13, visual = "10" },
	{ "armor", "Cuirasse des anciens", 4, { defense = 11, vie = 5 }, { steel = 6, carved_stone = 2, enchanted_cloth = 1 }, 44 },
	{ "hat", "Couronne retrouvée", 4, { charisme = 9, chance = 5, vie = 2 }, { lost_crown = 1, gold_ingot = 2, pearl = 2 }, 46 },
	{ "trinket", "Voile de l'ombre", 4, { discretion = 10, vitesse = 5 }, { enchanted_cloth = 2, night_flower = 3, soft_leather = 2 }, 48 },
	{ "weapon", "Arc de givre", 4, { chance = 8, vitesse = 6, force = 2 }, { frost_crystal = 1, oak_log = 3, linen_thread = 4, diamond = 1 }, 50, power = 12, visual = "11" },
}

-- 2. métier requis : item -> { compétence, niveau } (seulement si la recette n'en demande pas déjà)
E.GATES = {
	steel = { "minage", 15 },
	silver_ingot = { "minage", 12 },
	gold_ingot = { "minage", 20 },
	hook = { "peche", 4 },
	bait = { "peche", 1 },
	cheese = { "elevage", 8 },
	butter = { "elevage", 4 },
	wool_thread = { "elevage", 3 },
}
E.HARDWOOD = { oak_log = true, pine_log = true } -- recette sans palier qui en contient : bûcheronnage
E.HARDWOOD_LEVEL = 6

-- 4. effets de repas : mots des ingrédients -> caractéristique
E.MEAL_STATS = {
	{ "discretion", { "night" } }, -- en premier : à égalité, la fleur nocturne donne la discrétion
	{ "force", { "meat", "steak", "venison", "boar", "rabbit", "bacon", "sausage", "game" } }, -- pas « ham » : il attraperait « chamomile »
	{ "vitesse", { "fish", "crab", "shellfish", "eel", "trout", "salmon" } },
	{ "charisme", { "honey", "sugar", "cake", "syrup", "jam", "pie" } },
	{ "chance", { "herb", "mint", "thyme", "chamomile", "st_john", "mandrake", "spice", "mushroom", "flower" } },
	{ "defense", { "ale", "cider", "wine", "mead", "hops", "barley", "rye" } },
	{ "vie", { "carrot", "cabbage", "tomato", "pumpkin", "potato", "apple", "berr", "pear", "plum", "grape", "bean", "pea", "onion", "garlic", "wheat", "flour", "bread", "milk", "cheese", "butter" } },
}

-- 7. RIEN SANS USAGE (19/11, à sa demande : « pas de trucs juste là pour faire du chiffre ») : 122 objets
--    ne servaient qu'à la revente. Chacun reçoit une fonction (usage, recette, équipement ou système).
--    Usages gérés par Joueurs.useCatalogue : buff (bonus 20 min), livre (XP de métier), etudier
--    (collection « trouvailles » + Chance), rendre (réputation du village où l'on est), deballer
--    (rend son contenu), tresor, bourse, porter (devient une pièce d'équipement).
E.USES = {
	-- jeux, jouets, soins du corps : un petit bonus (consommé : on joue, on s'en sert)
	board_game = { "buff", "chance" }, cards = { "buff", "chance" }, dice = { "buff", "chance" }, fair_ticket = { "buff", "chance" },
	stone_figurine = { "buff", "chance" }, wood_figurine = { "buff", "chance" },
	kite = { "buff", "vitesse" }, leather_ball = { "buff", "vitesse" }, hoop = { "buff", "vitesse" },
	rag_doll = { "buff", "charisme" }, wood_toy = { "buff", "charisme" }, perfume = { "buff", "charisme" }, comb = { "buff", "charisme" },
	pocket_mirror = { "buff", "charisme" }, brush = { "buff", "charisme" }, towel = { "buff", "vie" },
	-- écrits : on apprend
	songbook = { "livre", "commerce" }, diploma = { "livre", "artisanat" }, contract = { "livre", "commerce" },
	recruit_contract = { "livre", "combat" }, patrol_log = { "livre", "combat" }, sea_chart = { "livre", "peche" },
	-- antiquités : on les étudie (collection, Chance) — la voie Explorateur s'en nourrit
	old_vase = { "etudier" }, fossil = { "etudier" }, inscription = { "etudier" }, ruin_piece = { "etudier" }, artifact = { "etudier" },
	rare_shell = { "etudier" }, relic = { "etudier" }, decorated_ceramic = { "etudier" }, royal_seal = { "etudier" },
	map_region = { "etudier" }, relic_fragment = { "etudier" },
	-- à rapporter au village : réputation
	recommendation = { "rendre", "15" }, lost_item = { "rendre", "6" }, guard_badge = { "rendre", "8" },
	-- marchandises emballées : se transportent et se revendent groupées, se déballent
	flour_sack = { "deballer", "flour:3" }, spice_sack = { "deballer", "spice:5" }, salt_sack = { "deballer", "salt:6" },
	cloth_bale = { "deballer", "cloth:5" }, fruit_crate = { "deballer", "apple:4,pear:2" },
	veg_basket = { "deballer", "carrot:2,cabbage:1,turnip:2" }, supply_chest = { "deballer", "rations:2,planks:6" },
	jewel_box = { "tresor" }, ancient_key = { "tresor" }, packed_goods = { "tresor" }, event_token = { "bourse", "40" },
	rare_book = { "recette", "" }, -- un livre rare apprend une recette encore inconnue
}
-- objets qui se PORTENT (deviennent une pièce d'équipement) : { emplacement, rareté, stats }
E.WEAR = {
	crown = { "hat", 4, { charisme = 8, chance = 3 } }, ring_gem = { "trinket", 3, { charisme = 5, chance = 3 } },
	medal = { "trinket", 2, { charisme = 3, force = 1 } }, champion_ribbon = { "trinket", 2, { charisme = 3, vitesse = 1 } },
	sheriff_badge = { "trinket", 3, { defense = 3, charisme = 4 } }, talisman = { "trinket", 3, { chance = 6 } },
	spyglass = { "trinket", 2, { chance = 3, vitesse = 1 } }, merchant_bag = { "trinket", 3, { charisme = 5, chance = 2 } },
	canvas_bag = { "trinket", 2, { vitesse = 2, chance = 1 } }, satchel = { "trinket", 1, { vitesse = 2 } }, seal = { "trinket", 2, { charisme = 3 } },
}
-- recettes en plus (matières de créatures, pièces, clés) : { objet, ingrédients, quantité, atelier }
E.EXTRA = {
	{ "leather", { raw_hide = 2, bark = 1 }, 2, "tannery" }, { "leather", { deer_hide = 1, bark = 1 }, 2, "tannery" },
	{ "leather", { wolf_pelt = 1 }, 2, "tannery" },
	{ "arrow", { branches = 1, tooth = 1, feather = 1 }, 8, "bench" },
	{ "bait", { pollen = 2 }, 6 },
	{ "copper_ingot", { copper_coin = 10 }, 1, "furnace" }, { "silver_ingot", { silver_coin = 5 }, 1, "furnace" },
	{ "gold_ingot", { gold_coin = 3 }, 1, "furnace" }, { "precious_ingot", { ancient_coin = 3 }, 1, "furnace" },
	{ "lockpick", { rusty_key = 1 }, 2, "anvil" },
}
-- ingrédients ajoutés à des recettes existantes (objet devenu pièce d'un ensemble)
E.ADD = {
	clock = { hourglass = 1 }, voilier = { anchor = 1 }, well = { climbing_rope = 1 }, bookcase = { scroll_case = 1 }, desk = { document_case = 1 },
}
-- pierres, cœurs, fossiles : bijoux et armes (même format que E.MASTER)
E.JEWELS = {
	{ "trinket", "Talisman de pierres colorées", 2, { chance = 3, charisme = 2 }, { colored_stone = 3, leather_strap = 1 }, 12 },
	{ "trinket", "Collier de griffes", 2, { force = 3, vitesse = 2 }, { claw = 3, rope = 1 }, 12 }, -- la griffe vaut 50 or : mieux qu'en flèches
	{ "trinket", "Collier d'os fossile", 2, { force = 3, vie = 2 }, { fossil_bone = 2, rope = 1 }, 14 },
	{ "trinket", "Cor de chasse", 3, { force = 4, vitesse = 4 }, { rare_horn = 1, copper_ingot = 1 }, 20 },
	{ "trinket", "Bague au rubis", 3, { force = 5, vie = 3 }, { ruby = 1, gold_ingot = 1, silver_ingot = 1 }, 22 },
	{ "trinket", "Amulette d'émeraude", 3, { chance = 5, vie = 3 }, { emerald = 1, silver_ingot = 1 }, 24 },
	{ "weapon", "Bâton de bois pétrifié", 3, { force = 5, defense = 3 }, { petrified_wood = 2, steel = 1 }, 24, power = 7, visual = "6" },
	{ "hat", "Diadème de saphir", 3, { charisme = 5, chance = 3 }, { sapphire = 1, silver_ingot = 2 }, 26 },
	{ "trinket", "Écu à l'écaille ancienne", 4, { defense = 9, vie = 3 }, { ancient_scale = 2, steel = 2, oak_log = 2 }, 36 },
	{ "trinket", "Cœur minéral serti", 4, { vie = 8, defense = 4 }, { mineral_heart = 1, precious_ingot = 1, ancient_crystal = 1 }, 38 },
}

-- 14. ARMES DE JET ET MONTURE (19/11) : objets neufs { id, nom, icône, prix, recette, quantité, atelier, niveau }
--     Munitions des armes de jet (Combat.shoot lit piece.ammo) ; harnachement : dans le sac, il augmente
--     l'allure de la monture (Horses.mount : E.TACK).
E.NEW_ITEMS = {
	{ "javelin", "Javelot", "🔱", 6, { planks = 1, iron_ingot = 1, feather = 1 }, 4, "bench", 6 },
	{ "throwing_knife", "Couteau de lancer", "🔪", 5, { iron_ingot = 1 }, 6, "anvil", 8 },
	{ "saddle_leather", "Selle de cuir", "🐎", 120, { leather = 4, buckle = 2, wool_cloth = 1 }, 1, "tannery", 6 },
	{ "saddle_race", "Selle de course", "🏇", 320, { soft_leather = 3, silver_ingot = 1, buckle = 2 }, 1, "tannery", 18 },
	{ "stirrups", "Étriers", "🔗", 80, { iron_ingot = 2, leather_strap = 2 }, 1, "anvil", 8 },
	-- flèches meilleures (Combat.shoot : AMMO_DMG), tirées en premier
	{ "arrow_iron", "Flèche à pointe de fer", "🏹", 4, { branches = 1, iron_ingot = 1, feather = 1 }, 8, "anvil", 10 },
	{ "arrow_barbed", "Flèche barbelée", "🏹", 7, { branches = 1, steel = 1, feather = 2 }, 8, "anvil", 20 },
	-- équipement de compagnon, dans le sac du maître (Compagnons : damageOf / hurt)
	{ "spiked_collar", "Collier clouté", "🐕", 90, { leather = 2, copper_nails = 6, buckle = 1 }, 1, "tannery", 8 },
	{ "pet_harness", "Harnais de cuir", "🦮", 110, { leather = 3, leather_strap = 2, iron_ring = 2 }, 1, "tannery", 10 },
}
E.TACK = { saddle_race = 1.15, saddle_leather = 1.08 } -- la meilleure selle compte ; étriers en plus
E.STIRRUPS = 1.05
-- armes de jet (emplacement Arme, tir à distance) : { nom, rareté, stats, dégâts, munition, ingrédients, niveau }
E.RANGED_GEAR = {
	{ "Fronde", 1, { chance = 2, vitesse = 1 }, 3, "stone", { leather = 1, rope = 1 }, 0 },
	{ "Fronde de berger renforcée", 2, { chance = 3, vitesse = 2 }, 5, "stone", { soft_leather = 1, linen_thread = 2 }, 8 },
	{ "Couteaux de lancer", 2, { discretion = 3, vitesse = 3 }, 5, "throwing_knife", { leather_strap = 2, iron_ingot = 1 }, 10 },
	{ "Javelots de chasse", 2, { force = 3, vitesse = 3 }, 6, "javelin", { oak_log = 1, leather = 1 }, 10 },
	{ "Javelots de guerre", 3, { force = 6, vitesse = 3 }, 8, "javelin", { steel = 1, oak_log = 1, leather = 1 }, 20 },
	{ "Baudrier du lanceur de couteaux", 3, { discretion = 6, vitesse = 3 }, 7, "throwing_knife", { soft_leather = 2, steel = 1 }, 22 },
}
E.AMMO_NAME = { stone = "Pierre", javelin = "Javelot", throwing_knife = "Couteau de lancer", arrow = "Flèche" }
-- dégâts selon la munition tirée
E.AMMO_DMG = { arrow = 1, bolt = 1.1, bolt_heavy = 1.3, arrow_iron = 1.25, arrow_barbed = 1.4, javelin = 1.2, stone = 0.8, throwing_knife = 1 }
E.BOW_AMMO = { "arrow_barbed", "arrow_iron", "arrow", "bolt", "bolt_heavy" } -- arcs et arbalètes : la meilleure d'abord

-- 15. HAUTS NIVEAUX DES MÉTIERS (19/11, AUDIT-CRAFT § 5 : au-delà de 20, les autres métiers ne
--     débloquaient rien). Plats : { id, nom, icône, prix, soin, { stat, bonus, minutes }, ingrédients,
--     atelier, compétence, niveau, festin } — un FESTIN partage son effet avec les joueurs à 25 studs.
E.NEW_FOODS = {
	{ "aged_cheese", "Fromage affiné", "🧀", 160, 60, { "vie", 3, 15 }, { cheese = 2, salt = 1 }, nil, "elevage", 20 },
	{ "village_feast", "Grand festin", "🍗", 600, 80, { "vie", 3, 20 }, { roast = 1, bread = 3, pie = 1, ale = 2 }, nil, "cuisine", 30, true },
	{ "lord_banquet", "Banquet du seigneur", "🍖", 1200, 100, { "force", 3, 25 }, { meat_pie = 2, honey_cake = 1, stew = 1, aged_cheese = 1 }, nil, "cuisine", 40, true },
}
-- matières de haut niveau : { id, nom, icône, prix, ingrédients, quantité, atelier, compétence, niveau }
E.HIGH_MATERIALS = {
	{ "damascus_steel", "Acier damassé", "🔩", 260, { steel = 2, coal = 2 }, 1, "furnace", "minage", 30 },
	{ "fine_planks", "Planches de chêne fines", "🪵", 40, { oak_log = 2 }, 3, "bench", "bucheronnage", 25 },
}
-- pièces qui les utilisent (même format que E.MASTER)
E.HIGH_GEAR = {
	{ "weapon", "Lame damassée", 4, { force = 8, vitesse = 3, chance = 2 }, { damascus_steel = 2, leather = 1, gold_ingot = 1 }, 36, power = 13, visual = "10" },
	{ "armor", "Cotte damassée", 4, { defense = 10, vie = 3 }, { damascus_steel = 3, soft_leather = 2 }, 38 },
	{ "weapon", "Arc long de maître", 4, { chance = 8, vitesse = 4, force = 1 }, { fine_planks = 3, linen_thread = 4, resin = 2 }, 34, power = 11, visual = "11" },
}

-- effets fixés à la main quand le nom du plat dit autre chose que ses ingrédients
E.MEALS = { vigor_elixir = { "force", 3 } }

E.changes = {} -- journal des corrections (lu par le banc tools/bancs/equilibre.luau)

local function note(s: string)
	table.insert(E.changes, s)
end

local function known(C, needs): boolean
	for id in needs do
		if not C.ITEMS[id] then
			warn("[Equilibre] matière inconnue : " .. tostring(id))
			return false
		end
	end
	return true
end

local function mealStat(needs): string
	local score = {}
	for id, n in needs do
		for _, row in E.MEAL_STATS do
			for _, word in row[2] do
				if string.find(id, word, 1, true) then
					score[row[1]] = (score[row[1]] or 0) + n
					break
				end
			end
		end
	end
	local best, bv = "vie", 0
	for _, row in E.MEAL_STATS do
		local v = score[row[1]] or 0
		if v > bv then
			best, bv = row[1], v
		end
	end
	return best
end

function E.apply(C)
	-- potions de l'alambic (Shared/Alchimie) : ajoutées d'abord, pour passer par le prix plancher
	local okA, Alchimie = pcall(require, script.Parent.Alchimie)
	if okA then
		Alchimie.apply(C)
	end
	local I, R = C.ITEMS, C.RECIPES
	-- 1. recettes copiées
	for _, r in R do
		local fix = r.item and E.RECIPES[r.item]
		if fix and fix.from and not r.needs[fix.from] then
			fix = nil
		end
		if fix and known(C, fix.needs) and (not fix.back or known(C, fix.back)) then
			r.needs = table.clone(fix.needs)
			if fix.count then
				r.count = fix.count > 1 and fix.count or nil
			end
			if fix.station then
				r.station = fix.station
			end
			r.back = fix.back
			if fix.price and C.ITEMS[r.item] then
				C.ITEMS[r.item].price = fix.price
			end
			note("recette " .. r.item)
		end
		local g = r.gear and E.GEAR[r.gear.name]
		if g then
			local add = g.add or {}
			if (not g.needs or known(C, g.needs)) and known(C, add) then
				if g.needs then
					r.needs = table.clone(g.needs)
				end
				for id, n in add do
					r.needs[id] = (r.needs[id] or 0) + n
				end
				note("équipement " .. r.gear.name)
			end
		end
	end
	-- 5. équipement : plancher de stats par rareté, discrétion des pièces furtives
	for _, r in R do
		local g = r.gear
		if g and g.stats then
			local total, best, bv = 0, nil, -1
			for st, v in g.stats do
				total += v
				if v > bv then
					best, bv = st, v
				end
			end
			local floor = E.RARITY_FLOOR[g.rarity or 1]
			if floor and best and total < floor then
				g.stats[best] += floor - total
				note("stats " .. g.name .. " " .. total .. "→" .. floor)
			end
			if not g.stats.discretion then
				for _, word in E.STEALTHY do
					if string.find(g.name, word, 1, true) then
						g.stats.discretion = 1 + (g.rarity or 1)
						note("discrétion " .. g.name)
						break
					end
				end
			end
		end
	end
	-- 6. pièces de maître
	for _, m in E.MASTER do
		local exists = false
		for _, r in R do
			if r.gear and r.gear.name == m[2] then
				exists = true
				break
			end
		end
		if not exists and known(C, m[5]) then
			table.insert(R, { gear = { slot = m[1], name = m[2], rarity = m[3], stats = table.clone(m[4]), power = m.power, visual = m.visual },
				needs = table.clone(m[5]), station = "bench", cat = "equipement", skill = { "artisanat", m[6] } })
			note("maître " .. m[2])
		end
	end
	-- 15. hauts niveaux des métiers
	for _, x in E.HIGH_MATERIALS do
		local id, name, icon, price, needs, count, station, skill, level = table.unpack(x)
		if not I[id] and known(C, needs) then
			I[id] = { name = name, icon = icon, price = price }
			table.insert(R, { item = id, needs = table.clone(needs), count = count > 1 and count or nil, station = station, cat = "materiaux", skill = { skill, level } })
			note("matière " .. id)
		end
	end
	for _, x in E.NEW_FOODS do
		local id, name, icon, price, heal, meal, needs, station, skill, level, feast = table.unpack(x)
		if not I[id] and known(C, needs) then
			I[id] = { name = name, icon = icon, price = price, food = heal, meal = { meal[1], meal[2], meal[3] * 60 }, feast = feast or nil }
			table.insert(R, { item = id, needs = table.clone(needs), station = station, cat = "cuisine", skill = { skill, level } })
			note("plat " .. id)
		end
	end
	for _, m in E.HIGH_GEAR do
		if known(C, m[5]) then
			table.insert(R, { gear = { slot = m[1], name = m[2], rarity = m[3], stats = table.clone(m[4]), power = m.power, visual = m.visual },
				needs = table.clone(m[5]), station = "anvil", cat = "equipement", skill = { "artisanat", m[6] } })
			note("haut niveau " .. m[2])
		end
	end
	-- 14. objets neufs (munitions, harnachement)
	for _, x in E.NEW_ITEMS do
		local id, name, icon, price, needs, count, station, level = table.unpack(x)
		if not I[id] and known(C, needs) then
			I[id] = { name = name, icon = icon, price = price }
			table.insert(R, { item = id, needs = table.clone(needs), count = count > 1 and count or nil, station = station, cat = "outils", skill = level > 0 and { "artisanat", level } or nil })
			note("nouvel objet " .. id)
		end
	end
	for _, x in E.RANGED_GEAR do
		local name, rarity, stats, power, ammo, needs, level = table.unpack(x)
		if I[ammo] and known(C, needs) then
			table.insert(R, { gear = { slot = "weapon", name = name, rarity = rarity, stats = table.clone(stats), power = power, visual = "2", ranged = true, ammo = ammo },
				needs = table.clone(needs), station = "bench", cat = "equipement", skill = level > 0 and { "artisanat", level } or nil })
			note("arme de jet " .. name)
		end
	end
	-- 7. rien sans usage
	for id, u in E.USES do
		local info = I[id]
		if info and not info.use then
			info.use, info.useArg = "cat_" .. u[1], u[2]
			note("usage " .. id .. " " .. u[1])
		end
	end
	for id, w in E.WEAR do
		local info = I[id]
		if info and not info.use then
			info.use, info.wearAs = "cat_porter", { w[1], w[2], w[3] }
			note("se porte " .. id)
		end
	end
	for _, x in E.EXTRA do
		if I[x[1]] and known(C, x[2]) then
			table.insert(R, { item = x[1], needs = table.clone(x[2]), count = (x[3] or 1) > 1 and x[3] or nil, station = x[4], cat = "materiaux" })
			note("recette en plus " .. x[1])
		end
	end
	for _, r in R do
		local add = r.item and E.ADD[r.item]
		if add and known(C, add) then
			for id, n in add do
				r.needs[id] = (r.needs[id] or 0) + n
			end
			note("ingrédient ajouté " .. r.item)
		end
	end
	for _, m in E.JEWELS do
		if known(C, m[5]) then
			table.insert(R, { gear = { slot = m[1], name = m[2], rarity = m[3], stats = table.clone(m[4]), power = m.power, visual = m.visual },
				needs = table.clone(m[5]), station = "bench", cat = "equipement", skill = { "artisanat", m[6] } })
			note("bijou " .. m[2])
		end
	end
	-- 2. métiers
	for _, r in R do
		if r.item and not r.skill then
			local gate = E.GATES[r.item]
			if gate then
				r.skill = { gate[1], gate[2] }
				note("palier " .. r.item .. " " .. gate[1] .. " " .. gate[2])
			elseif r.cat ~= "construction" then
				for id in r.needs do
					if E.HARDWOOD[id] then
						r.skill = { "bucheronnage", E.HARDWOOD_LEVEL }
						note("palier " .. r.item .. " bucheronnage")
						break
					end
				end
			end
		end
	end
	-- 3. prix plancher (plusieurs passes : une matière revalorisée revalorise ce qu'on en tire)
	for _ = 1, 8 do
		local moved = false
		local cheapest = {}
		for _, r in R do
			local out = r.item and I[r.item]
			if out and out.price and out.price > 0 then
				local cost, ok = 0, true
				for id, n in r.needs do
					local p = I[id] and I[id].price
					if not p or p <= 0 then
						ok = false
						break
					end
					cost += p * n
				end
				for id, n in r.back or {} do
					cost -= (I[id] and I[id].price or 0) * n
				end
				if ok then
					local per = math.max(0, cost) / (r.count or 1)
					if not cheapest[r.item] or per < cheapest[r.item] then
						cheapest[r.item] = per
					end
				end
			end
		end
		for id, per in cheapest do
			local floor = math.ceil(per * 1.1)
			if I[id].price < floor then
				I[id].price = floor
				moved = true
			end
		end
		if not moved then
			break
		end
	end
	-- 4. cuisine : plus nourrissant que cru, et un effet de repas
	for _, r in R do
		local out = r.item and I[r.item]
		if out and out.food then
			local raw = 0
			for id, n in r.needs do
				raw += ((I[id] and I[id].food) or 0) * n
			end
			local per = raw / (r.count or 1)
			if per > 0 and out.food < per * 1.2 then
				out.food = math.ceil(per * 1.2)
				note("nourriture " .. r.item .. " " .. out.food)
			end
			if not out.meal then
				local fixed = E.MEALS[r.item]
				local stat = fixed and fixed[1] or mealStat(r.needs)
				local v = fixed and fixed[2] or math.clamp(1 + math.floor(out.food / 30), 1, 3)
				local minutes = math.clamp(5 + math.floor(out.food / 6), 5, 15)
				out.meal = { stat, v, minutes * 60 }
			end
		end
	end
end

-- ================================================================= après la génération d'équipement
-- 8. EXIGENCES (19/11, ses mots : niveaux pour porter l'équipement ? → non, des CARACTÉRISTIQUES) :
--    pas de niveau de personnage ; une pièce de rareté 3+ demande d'avoir ENTRAÎNÉ sa stat principale
--    (niveau tiré de statXp, sans les bonus d'équipement). Une pièce déjà portée le reste.
E.REQ = { [3] = 3, [4] = 6 }
E.REQ_MASTER = 9 -- pièces de maître (artisanat 40+)

function E.requirement(piece): { any }?
	if type(piece) ~= "table" or type(piece.stats) ~= "table" then
		return nil
	end
	if piece.req then
		return piece.req
	end
	local lv = E.REQ[piece.rarity or 1]
	if not lv then
		return nil
	end
	local best, bv = nil, -1
	for st, v in piece.stats do
		if v > bv or (v == bv and st < (best or "")) then
			best, bv = st, v
		end
	end
	return best and { best, lv } or nil
end

-- 9. séries générées (Gear.expandRecipes : forme × matière) — stats qui ont du sens.
--    Poids par forme (stat principale, stat d'appoint), touche de la matière, dégâts par forme.
E.FORM_STATS = {
	sword = { force = 1, defense = 0.5 }, dagger = { discretion = 1, vitesse = 0.6 }, axe = { force = 1, vie = 0.4 },
	mace = { force = 1, defense = 0.5 }, pike = { vitesse = 0.8, force = 0.7 }, bow = { chance = 1, vitesse = 0.5 },
	crossbow = { force = 0.8, chance = 0.7 }, hammer = { force = 1, defense = 0.6 }, greatsword = { force = 1.2, vie = 0.3 },
	halberd = { defense = 0.8, force = 0.8 }, scythe = { force = 0.9, vitesse = 0.7 }, saber = { vitesse = 1, force = 0.6 },
	helmet = { defense = 1, vie = 0.5 }, closedhelm = { defense = 1, vie = 0.7 }, hood = { discretion = 1, vitesse = 0.4 },
	cresthelm = { force = 1, defense = 0.6 }, feathered = { charisme = 1, chance = 0.5 }, nasalhelm = { defense = 1, force = 0.4 },
	plate = { defense = 1, vie = 0.6 }, tunic = { vitesse = 1, discretion = 0.4 }, brigandine = { vie = 1, defense = 0.6 },
	mail = { defense = 1, vie = 0.4 }, leather = { discretion = 1, vitesse = 0.5 }, scale = { force = 0.8, defense = 0.8 },
	gloves = { vitesse = 1, chance = 0.4 }, gauntlets = { force = 1, defense = 0.6 }, fingerless = { discretion = 1, vitesse = 0.6 },
	pauldrons = { defense = 1, force = 0.4 }, lamellar = { vie = 1, defense = 0.5 }, hornshoulder = { force = 1, vie = 0.4 },
	pants = { vitesse = 1, vie = 0.4 }, leggings = { discretion = 1, vitesse = 0.5 }, greaves = { defense = 1, vie = 0.5 },
	cape = { discretion = 1, vitesse = 0.4 }, mantle = { vie = 1, charisme = 0.4 }, splitcape = { charisme = 1, chance = 0.4 },
	boots = { vitesse = 1, chance = 0.3 }, tallboots = { vie = 1, vitesse = 0.5 }, sabatons = { defense = 1, vie = 0.5 },
	ring = { chance = 1, force = 0.3 }, necklace = { charisme = 1, vie = 0.4 }, brooch = { charisme = 1, chance = 0.4 },
	pendant = { vie = 1, chance = 0.4 }, bracelet = { force = 1, vitesse = 0.4 }, medallion = { chance = 1, charisme = 0.4 },
}
E.MATERIAL_STAT = {
	lin = "vie", cuir = "vitesse", forge = "force", loup = "vitesse", garde = "defense", ronces = "vie",
	soleil = "force", nord = "vie", os = "force", lune = "discretion", ambre = "charisme", diamant = "chance",
}
E.WEAPON_DAMAGE = {
	dagger = 0.75, sword = 1, axe = 1.1, mace = 1.1, pike = 1, bow = 0.9, crossbow = 1.15,
	hammer = 1.2, greatsword = 1.3, halberd = 1.2, scythe = 1.15, saber = 0.95,
}
-- budget de stats par rareté : emplacements principaux / petits emplacements (gants, épaulières…)
E.BUDGET = { main = { 4, 6, 9, 13 }, small = { 2, 4, 6, 8 } }
E.MAIN_SLOTS = { weapon = true, hat = true, armor = true, trinket = true }
E.SMALL_FLOOR = { [3] = 6, [4] = 8 }

local function spread(weights, total, accent)
	-- une touche de matière (1 ou 2 points), le reste réparti selon les poids, arrondi au plus juste
	local stats = {}
	local left = total
	if accent then
		local a = total >= 9 and 2 or 1
		stats[accent] = a
		left -= a
	end
	local sum = 0
	for _, w in weights do
		sum += w
	end
	local keys = {}
	for k in weights do
		table.insert(keys, k)
	end
	table.sort(keys, function(x, y)
		return weights[x] > weights[y]
	end)
	local given = 0
	for i, k in keys do
		local v = i == #keys and (left - given) or math.floor(left * weights[k] / sum + 0.5)
		v = math.max(0, v)
		given += v
		if v > 0 then
			stats[k] = (stats[k] or 0) + v
		end
	end
	return stats
end

-- 10. pièces de départ des nouveaux emplacements (presque rien en rareté 1 : un débutant ne pouvait
--     pas s'équiper). { emplacement, nom, stats, ingrédients } — « laine » dans le nom : tient chaud (Froid).
E.STARTER_GEAR = {
	{ "gloves", "Gants de paysan", { vitesse = 1, vie = 1 }, { cloth = 1, fiber = 2 } },
	{ "gloves", "Mitaines de laine", { vie = 2 }, { wool_cloth = 1, wool_thread = 1 } },
	{ "boots", "Sabots de bois", { vie = 1, defense = 1 }, { planks = 2, leather_strap = 1 } },
	{ "boots", "Bottes de toile", { vitesse = 2 }, { cloth = 2, leather = 1 } },
	{ "legs", "Chausses de toile", { vitesse = 1, discretion = 1 }, { cloth = 2 } },
	{ "legs", "Pantalon de laine", { vie = 2 }, { wool_cloth = 2 } },
	{ "cape", "Cape de laine", { vie = 1, discretion = 1 }, { wool_cloth = 3, buckle = 1 } },
	{ "cape", "Pèlerine de toile", { charisme = 1, vie = 1 }, { cloth = 2, rope = 1 } },
	{ "shoulders", "Épaulières de cuir", { defense = 2 }, { leather = 2, rope = 1 } },
	{ "shoulders", "Spallières de bois", { defense = 1, vie = 1 }, { planks = 3, leather_strap = 1 } },
}

-- 11. ÉQUIPEMENT DE MÉTIER (19/11) : des niveaux de compétence tant qu'on porte la pièce (Joueurs.skill,
--     plafond +10 par compétence). Ils jouent sur les EFFETS (rendements, qualité, prises…), jamais sur
--     les déblocages (recettes, paliers : niveau entraîné seul, Joueurs.needSkill). Le 3e palier demande
--     la compétence entraînée au niveau 20.
E.SKILL_LABEL = {
	agriculture = "Agriculture", bucheronnage = "Bûcheronnage", minage = "Minage", peche = "Pêche", cuisine = "Cuisine",
	artisanat = "Artisanat", combat = "Combat", crochetage = "Crochetage", dressage = "Dressage", elevage = "Élevage", commerce = "Commerce",
}
E.TRADE_REQ = 20
-- { emplacement, nom, rareté, stats, { compétence = bonus }, ingrédients, niveau d'artisanat }
E.TRADE_GEAR = {
	{ "hat", "Chapeau de paille du fermier", 1, { vie = 1 }, { agriculture = 1 }, { straw = 4, rope = 1 }, 0 },
	{ "gloves", "Gants de jardinier", 2, { vie = 1, chance = 1 }, { agriculture = 2 }, { leather = 1, cloth = 1 }, 6 },
	{ "armor", "Tablier de semeur", 3, { vie = 2, chance = 2 }, { agriculture = 4 }, { linen = 3, leather_strap = 1, flax = 2 }, 16 },
	{ "gloves", "Gants de bûcheron", 1, { force = 1 }, { bucheronnage = 1 }, { leather = 1, fiber = 2 }, 0 },
	{ "armor", "Vareuse de bûcheron", 2, { force = 1, vie = 1 }, { bucheronnage = 2 }, { wool_cloth = 2, leather_strap = 1 }, 6 },
	{ "trinket", "Ceinture du hachereau", 3, { force = 3, vie = 1 }, { bucheronnage = 4 }, { soft_leather = 2, steel = 1, oak_log = 1 }, 16 },
	{ "hat", "Casque de mineur", 1, { defense = 1 }, { minage = 1 }, { copper_ingot = 1, leather = 1 }, 0 },
	{ "legs", "Genouillères de mineur", 2, { defense = 1, vie = 1 }, { minage = 2 }, { leather = 2, iron_ring = 2 }, 6 },
	{ "gloves", "Gantelets de prospecteur", 3, { force = 2, defense = 2 }, { minage = 4 }, { steel = 1, soft_leather = 1, iron_ingot = 2 }, 16 },
	{ "hat", "Chapeau de pêcheur", 1, { chance = 1 }, { peche = 1 }, { straw = 3, linen_thread = 1 }, 0 },
	{ "boots", "Bottes de pêcheur", 2, { vie = 1, vitesse = 1 }, { peche = 2 }, { leather = 2, resin = 2 }, 6 },
	{ "cape", "Ciré du capitaine", 3, { vie = 2, chance = 2 }, { peche = 4 }, { linen = 3, resin = 3, buckle = 1 }, 16 },
	{ "hat", "Toque de cuisinier", 1, { charisme = 1 }, { cuisine = 1 }, { linen = 1, linen_thread = 2 }, 0 },
	{ "armor", "Tablier de cuisinier", 2, { vie = 1, charisme = 1 }, { cuisine = 2 }, { linen = 2, cloth = 1 }, 6 },
	{ "trinket", "Médaillon du grand chef", 3, { charisme = 3, vie = 1 }, { cuisine = 4 }, { gold_ingot = 1, silver_ingot = 1 }, 16 },
	{ "armor", "Tablier de forgeron", 1, { defense = 1 }, { artisanat = 1 }, { leather = 2, leather_strap = 1 }, 0 },
	{ "gloves", "Gants d'artisan", 2, { force = 1, chance = 1 }, { artisanat = 2 }, { soft_leather = 1, linen_thread = 1 }, 8 },
	{ "hat", "Lunettes de maître artisan", 3, { chance = 3, charisme = 1 }, { artisanat = 4 }, { glass = 2, gold_ingot = 1, leather_strap = 1 }, 20 },
	{ "gloves", "Gants de crocheteur", 1, { discretion = 1 }, { crochetage = 1 }, { soft_leather = 1, copper_nails = 2 }, 0 },
	{ "hat", "Cagoule de monte-en-l'air", 2, { discretion = 2, vitesse = 1 }, { crochetage = 2 }, { wool_cloth = 1, dyed_cloth = 1 }, 6 },
	{ "trinket", "Bague du passe-partout", 3, { discretion = 3, chance = 1 }, { crochetage = 4 }, { silver_ingot = 1, lockpick = 3 }, 16 },
	{ "gloves", "Gants de dresseur", 1, { vie = 1 }, { dressage = 1 }, { leather = 1, rope = 1, bone = 1 }, 0 },
	{ "trinket", "Sifflet en os", 2, { charisme = 1, vitesse = 1 }, { dressage = 2 }, { bone = 2, feather = 1 }, 6 },
	{ "cape", "Cape du maître des bêtes", 3, { vie = 2, charisme = 2 }, { dressage = 4 }, { fur = 2, horn = 1, buckle = 1 }, 16 },
	{ "armor", "Blouse de berger", 1, { vie = 1 }, { elevage = 1 }, { cloth = 2, wool = 1 }, 0 },
	{ "trinket", "Bâton de berger", 2, { vie = 1, vitesse = 1 }, { elevage = 2 }, { oak_log = 1, rope = 1 }, 6 },
	{ "boots", "Bottes de vacher", 3, { vie = 2, vitesse = 2 }, { elevage = 4 }, { soft_leather = 2, iron_ring = 2, wool_cloth = 1 }, 16 },
	{ "trinket", "Bourse de colporteur", 1, { charisme = 1 }, { commerce = 1 }, { leather = 1, linen_thread = 1 }, 0 },
	{ "hat", "Chapeau de colporteur", 2, { charisme = 2, chance = 1 }, { commerce = 2 }, { wool_cloth = 1, feather = 2 }, 6 },
	{ "trinket", "Chaîne de maître marchand", 3, { charisme = 4 }, { commerce = 4 }, { gold_ingot = 2, silver_ingot = 1 }, 20 },
}

-- 12. PANOPLIES (19/11) : les 12 matières des séries forment des ensembles. Porter plusieurs pièces
--     de la même matière donne un bonus dans la stat de cette matière (E.MATERIAL_STAT).
E.SET_STEPS = { { 2, 1 }, { 4, 3 }, { 6, 6 } } -- { pièces portées, bonus }
E.STAT_LABEL = { force = "Force", defense = "Défense", vie = "Vie", vitesse = "Vitesse", chance = "Chance", charisme = "Charisme", discretion = "Discrétion" }
E.SET_NAME = {
	lin = "Valdor", cuir = "Cuir huilé", forge = "Forge cuivrée", loup = "Loup gris", garde = "Garde du pont", ronces = "Ronces vertes",
	soleil = "Soleil rouge", nord = "Veille d'hiver", os = "Reliquaire d'os", lune = "Lune d'argent", ambre = "Ambre royal", diamant = "Diamant boréal",
}

-- bonus des panoplies portées : { [stat] = bonus }, et la liste lisible des panoplies actives
function E.setBonus(equipped)
	local count = {}
	for _, item in equipped or {} do
		local m = type(item) == "table" and item.design and item.design.material
		if m and E.MATERIAL_STAT[m] then
			count[m] = (count[m] or 0) + 1
		end
	end
	local bonus, active = {}, {}
	for m, n in count do
		local v = 0
		for _, step in E.SET_STEPS do
			if n >= step[1] then
				v = step[2]
			end
		end
		if v > 0 then
			local st = E.MATERIAL_STAT[m]
			bonus[st] = (bonus[st] or 0) + v
			table.insert(active, string.format("%s (%d pièces) +%d %s", E.SET_NAME[m] or m, n, v, E.STAT_LABEL[st] or st))
		end
	end
	return bonus, active
end

-- texte de la panoplie d'une pièce (description)
function E.setText(item): string?
	local m = type(item) == "table" and item.design and item.design.material
	if not (m and E.MATERIAL_STAT[m]) then
		return nil
	end
	local parts = {}
	for _, step in E.SET_STEPS do
		table.insert(parts, step[1] .. " : +" .. step[2])
	end
	return "panoplie " .. (E.SET_NAME[m] or m) .. " (" .. table.concat(parts, ", ") .. " " .. (E.STAT_LABEL[E.MATERIAL_STAT[m]] or E.MATERIAL_STAT[m]) .. ")"
end

-- 13. PIÈCES DE CRÉATURES (Shared/Prises) : stats selon la FAMILLE de la matière (avant : tirées au
--     hasard, ex. « talisman d'essence d'assassin » en Force + Charisme). Total gardé. Les bêtes du
--     froid donnent des pièces qui tiennent chaud (Systemes/Froid lit piece.warm).
-- { mots de la matière (minuscules), poids }
E.CREATURE_FAMILY = {
	{ { "poussière", "pollen", "gelée royale" }, { chance = 1, vie = 0.4 } }, -- avant « gelée »
	{ { "bois de cerf" }, { force = 0.8, vitesse = 0.8 } },
	{ { "givre", "glace" }, { vie = 1, defense = 0.6 } },
	{ { "éclat de pierre" }, { defense = 1, vie = 0.6 } },
	{ { "paille maudite" }, { discretion = 1, chance = 0.5 } },
	{ { "fragment de roi" }, { charisme = 1, force = 0.5 } },
	{ { "venin", "dard", "glande à venin" }, { force = 0.8, discretion = 0.7 } },
	{ { "essence", "ombre", "spectre", "follet", "revenant", "noyau" }, { discretion = 1, chance = 0.5 } },
	{ { "écaille", "carapace", "élytre", "pince", "peau" }, { defense = 1, vie = 0.6 } },
	{ { "plume", "aile" }, { vitesse = 1, chance = 0.5 } },
	{ { "gelée", "spore", "cœur", "sève" }, { vie = 1, defense = 0.5 } },
	{ { "os massif" }, { force = 1, vie = 0.6 } },
	{ { "os maudit", "os " }, { force = 0.8, defense = 0.7 } },
	{ { "croc", "griffe", "défense", "corne", "faux de mante" }, { force = 1, vitesse = 0.6 } },
	{ { "queue", "patte" }, { chance = 1, vitesse = 0.5 } },
	{ { "crin" }, { vitesse = 1, charisme = 0.4 } },
	{ { "oreille" }, { chance = 0.8, force = 0.6 } },
	{ { "masque", "crochet", "collet", "cape d'ombre" }, { discretion = 1, chance = 0.5 } },
	{ { "insigne", "écusson", "écu brisé", "sceau" }, { charisme = 1, defense = 0.5 } },
	{ { "grimoire", "avis de recherche" }, { chance = 1, charisme = 0.4 } },
	{ { "carquois" }, { chance = 1, vitesse = 0.5 } },
	{ { "turban", "bosse" }, { vie = 1, vitesse = 0.4 } },
	{ { "soie" }, { discretion = 0.8, vitesse = 0.7 } },
}
E.COLD_WORDS = { "polaire", "blizzard", "glace", "givre", "yéti", "neige", "hiver", "blanc" }
-- effet au toucher des ARMES de créatures (Systemes/Combat) : { mots de la matière, effet }
E.WEAPON_EFFECT = {
	{ { "venin", "dard", "glande à venin" }, "venin" },
	{ { "feu", "dragonnet", "braise", "flamme" }, "feu" },
	{ { "givre", "glace", "polaire", "blizzard", "yéti", "neige" }, "givre" },
}
E.EFFECT_TEXT = { venin = "empoisonne (3 piqûres)", feu = "brûle (2 brûlures)", givre = "ralentit l'ennemi" }

local function lower(s: string): string
	return (string.lower((string.gsub(string.gsub(string.gsub(s, "É", "é"), "È", "è"), "Œ", "œ"))))
end

local function creatureWeights(matName: string)
	local n = lower(matName)
	for _, f in E.CREATURE_FAMILY do
		for _, w in f[1] do
			if string.find(n, w, 1, true) then
				return f[2]
			end
		end
	end
	return nil
end

-- 16. PETITS EMPLACEMENTS (19/11) : il n'y avait que 13 à 15 pièces par emplacement, presque rien en
--     rareté 2 à 4. { emplacement, nom, rareté, stats, ingrédients, niveau d'artisanat }
--     « fourrure » dans le nom : tient chaud (Froid) ; « Bottes » : on ne s'enlise pas dans la boue.
E.SMALL_GEAR = {
	{ "gloves", "Gants fourrés", 2, { vie = 3, defense = 1 }, { fur = 2, leather = 1 }, 10 },
	{ "gloves", "Gants de soie de l'archer", 3, { chance = 4, vitesse = 2 }, { silk = 2, soft_leather = 1 }, 20 },
	{ "gloves", "Gantelets de forge", 3, { force = 4, defense = 2 }, { steel = 1, iron_ring = 2, leather = 1 }, 22 },
	{ "gloves", "Gantelets dorés du capitaine", 4, { force = 4, charisme = 4 }, { gold_ingot = 2, steel = 1, soft_leather = 1 }, 32 },
	{ "shoulders", "Épaulières de fourrure", 2, { vie = 3, defense = 1 }, { fur = 2, leather_strap = 1 }, 10 },
	{ "shoulders", "Épaulières de mailles", 3, { defense = 4, vie = 2 }, { iron_ring = 6, leather = 1 }, 20 },
	{ "shoulders", "Spallières d'acier", 3, { defense = 5, force = 1 }, { steel = 2, leather_strap = 1 }, 22 },
	{ "shoulders", "Épaulières d'apparat", 4, { charisme = 5, defense = 3 }, { gold_ingot = 1, silver_ingot = 1, dyed_cloth = 2 }, 32 },
	{ "legs", "Chausses de cuir souple", 2, { discretion = 3, vitesse = 1 }, { soft_leather = 2, linen_thread = 1 }, 10 },
	{ "legs", "Jambières de fourrure", 3, { vie = 4, defense = 2 }, { fur = 3, leather = 1 }, 20 },
	{ "legs", "Jambières d'acier", 3, { defense = 5, vie = 1 }, { steel = 2, leather_strap = 2 }, 22 },
	{ "legs", "Chausses de soie du rôdeur", 4, { discretion = 5, vitesse = 3 }, { silk = 3, dyed_cloth = 1 }, 32 },
	{ "cape", "Cape de fourrure", 2, { vie = 3, discretion = 1 }, { fur = 2, buckle = 1 }, 10 },
	{ "cape", "Cape teinte du voyageur", 3, { vitesse = 3, charisme = 3 }, { dyed_cloth = 3, buckle = 1 }, 20 },
	{ "cape", "Cape de soie nocturne", 3, { discretion = 5, chance = 1 }, { silk = 3, buckle = 1, night_feather = 1 }, 22 }, -- plume nocturne (90 or)
	{ "cape", "Manteau d'apparat", 4, { charisme = 6, vie = 2 }, { dyed_cloth = 3, gold_ingot = 1, pearl = 1 }, 32 },
	{ "boots", "Bottes fourrées", 2, { vie = 3, vitesse = 1 }, { fur = 2, leather = 2 }, 10 },
	{ "boots", "Bottes de marais", 2, { vie = 2, vitesse = 2 }, { leather = 2, resin = 2 }, 10 },
	{ "boots", "Bottes de coureur", 3, { vitesse = 5, chance = 1 }, { soft_leather = 2, linen_thread = 2 }, 20 },
	{ "boots", "Solerets d'acier", 3, { defense = 5, vie = 1 }, { steel = 2, leather = 1, iron_ring = 1 }, 22 },
	{ "boots", "Bottes de cavalier émérite", 4, { vitesse = 5, charisme = 3 }, { soft_leather = 3, silver_ingot = 1, buckle = 2 }, 32 },
}

function E.finish(C)
	local okG, Gear = pcall(require, script.Parent.Gear)
	local SLOTS = okG and Gear.SLOTS or {}
	local R = C.RECIPES
	-- pièces de départ (seulement si l'emplacement existe dans ce jeu)
	local have = {}
	for _, r in R do
		if r.gear then
			have[r.gear.name] = true
		end
	end
	for _, g in E.STARTER_GEAR do
		if SLOTS[g[1]] and not have[g[2]] and known(C, g[4]) then
			table.insert(R, { gear = { slot = g[1], name = g[2], rarity = 1, stats = table.clone(g[3]), power = 0, visual = "" },
				needs = table.clone(g[4]), station = "bench", cat = "equipement" })
			note("départ " .. g[2])
		end
	end
	for _, g in E.SMALL_GEAR do
		if SLOTS[g[1]] and not have[g[2]] and known(C, g[5]) then
			table.insert(R, { gear = { slot = g[1], name = g[2], rarity = g[3], stats = table.clone(g[4]), power = 0, visual = "" },
				needs = table.clone(g[5]), station = "bench", cat = "equipement", skill = { "artisanat", g[6] } })
			have[g[2]] = true
			note("petit emplacement " .. g[2])
		end
	end
	for _, t in E.TRADE_GEAR do
		if SLOTS[t[1]] and not have[t[2]] and known(C, t[6]) then
			local skill = next(t[5])
			local g = { slot = t[1], name = t[2], rarity = t[3], stats = table.clone(t[4]), skills = table.clone(t[5]), power = 0, visual = "" }
			if t[3] >= 3 then
				g.req = { skill, E.TRADE_REQ, "skill", E.SKILL_LABEL[skill] }
			end
			table.insert(R, { gear = g, needs = table.clone(t[6]), station = "bench", cat = "equipement", skill = t[7] > 0 and { "artisanat", t[7] } or nil })
			note("métier " .. t[2])
		end
	end
	-- pièces de créatures : stats de leur famille, chaleur des bêtes du froid
	for _, r in R do
		local g = r.gear
		if g and g.stats and not g.design then
			local mat
			for id in r.needs do
				if string.sub(id, 1, 6) == "prise_" or string.sub(id, 1, 4) == "ame_" then
					mat = C.ITEMS[id]
					break
				end
			end
			local weights = mat and creatureWeights(mat.name or "")
			if weights then
				local total = 0
				for _, v in g.stats do
					total += v
				end
				g.stats = spread(weights, total, nil)
				note("créature " .. g.name)
			end
			if mat and g.slot == "weapon" then
				local n = lower(mat.name or "")
				for _, fx in E.WEAPON_EFFECT do
					for _, w in fx[1] do
						if not g.effect and string.find(n, w, 1, true) then
							g.effect = fx[2]
						end
					end
				end
			end
			if mat then
				local n = lower(mat.name or "")
				for _, w in E.COLD_WORDS do
					if string.find(n, w, 1, true) then
						g.warm = true
						break
					end
				end
			end
		end
	end
	for _, r in R do
		local g = r.gear
		if g and g.stats and not g.skills then
			local small = not E.MAIN_SLOTS[g.slot or ""]
			-- séries générées : stats et dégâts selon la forme et la matière
			local d = g.design
			local weights = d and E.FORM_STATS[d.form]
			if weights then
				local budget = (small and E.BUDGET.small or E.BUDGET.main)[g.rarity or 1] or 4
				g.stats = spread(weights, budget, E.MATERIAL_STAT[d.material])
				if g.slot == "weapon" and g.power then
					g.power = math.max(2, math.floor(g.power * (E.WEAPON_DAMAGE[d.form] or 1) + 0.5))
					g.name = string.gsub(g.name, " en lin de Valdor$", " de Valdor")
				end
				note("série " .. g.name)
			elseif small then
				-- petits emplacements faits main : plancher plus bas
				local total, best, bv = 0, nil, -1
				for st, v in g.stats do
					total += v
					if v > bv then
						best, bv = st, v
					end
				end
				local floor = E.SMALL_FLOOR[g.rarity or 1]
				if floor and best and total < floor then
					g.stats[best] += floor - total
				end
			end
			-- exigence de caractéristique
			if (g.rarity or 1) >= 3 then
				local req = E.requirement({ stats = g.stats, rarity = g.rarity })
				if req and r.skill and r.skill[2] >= 40 then
					req[2] = E.REQ_MASTER
				end
				g.req = req
			end
		end
	end
end

return E
