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
	{ "leather", { raw_hide = 2, bark = 1 }, 1, "tannery" }, { "leather", { deer_hide = 1, bark = 1 }, 1, "tannery" },
	{ "leather", { wolf_pelt = 1 }, 2, "tannery" },
	{ "arrow", { branches = 1, tooth = 1, feather = 1 }, 8, "bench" }, { "arrow", { branches = 1, claw = 1, feather = 1 }, 8, "bench" },
	{ "bait", { pollen = 2 }, 4 }, { "quill", { night_feather = 1 }, 4 },
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
	{ "trinket", "Collier d'os fossile", 2, { force = 3, vie = 2 }, { fossil_bone = 2, rope = 1 }, 14 },
	{ "trinket", "Cor de chasse", 3, { force = 4, vitesse = 4 }, { rare_horn = 1, copper_ingot = 1 }, 20 },
	{ "trinket", "Bague au rubis", 3, { force = 5, vie = 3 }, { ruby = 1, gold_ingot = 1 }, 22 },
	{ "trinket", "Amulette d'émeraude", 3, { chance = 5, vie = 3 }, { emerald = 1, silver_ingot = 1 }, 24 },
	{ "weapon", "Bâton de bois pétrifié", 3, { force = 5, defense = 3 }, { petrified_wood = 2, steel = 1 }, 24, power = 7, visual = "6" },
	{ "hat", "Diadème de saphir", 3, { charisme = 5, chance = 3 }, { sapphire = 1, silver_ingot = 2 }, 26 },
	{ "trinket", "Écu à l'écaille ancienne", 4, { defense = 9, vie = 3 }, { ancient_scale = 2, steel = 2, oak_log = 2 }, 36 },
	{ "trinket", "Cœur minéral serti", 4, { vie = 8, defense = 4 }, { mineral_heart = 1, precious_ingot = 1, ancient_crystal = 1 }, 38 },
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

return E
