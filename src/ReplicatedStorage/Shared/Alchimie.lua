-- Alchimie (19/11, docs/AUDIT-CRAFT.md : l'alambic n'avait que 9 recettes, toutes des soins).
-- Potions à l'alambic : un BONUS plus fort et plus long que les repas (+4 à +5, 20 min ; un repas :
-- +1 à +3, 15 min au plus). Chacune demande les plantes sauvages d'un biome précis (Systemes/Herbes) :
-- il faut voyager pour les réunir. Compétence : cuisine (comme les autres recettes d'alchimie).
-- Appelé par Shared/Equilibre au début de son apply : le prix plancher et la rareté s'appliquent ensuite.
-- { id, nom, icône, prix de base, soin, { stat, bonus, minutes }, ingrédients, niveau de cuisine }

local A = {}

A.POTIONS = {
	{ "potion_taureau", "Potion du taureau", "🧡", 70, 15, { "force", 4, 20 }, { vial = 1, nettle = 2, monster_tooth = 1 }, 12 },
	{ "potion_pierre", "Potion de peau de pierre", "🛡️", 70, 15, { "defense", 4, 20 }, { vial = 1, sage = 2, scales = 2 }, 14 },
	{ "potion_vent", "Potion de vent", "💨", 60, 10, { "vitesse", 4, 20 }, { vial = 1, mint = 2, feather = 2 }, 10 },
	{ "potion_trefle", "Philtre du trèfle", "🍀", 80, 10, { "chance", 5, 20 }, { vial = 1, st_john = 2, lavender = 2 }, 16 },
	{ "potion_charme", "Philtre de charme", "💖", 70, 10, { "charisme", 5, 20 }, { vial = 1, rosemary = 2, honey = 1, flower = 2 }, 12 },
	{ "potion_brume", "Potion de brume", "🌫️", 110, 10, { "discretion", 5, 20 }, { vial = 1, night_flower = 1, valerian = 2, slime_gel = 1 }, 22 },
	{ "grande_potion", "Grande potion de soin", "❤️", 220, 150, { "vie", 4, 10 }, { healing_potion = 2, mandrake = 1 }, 25 },
	{ "elixir_racine", "Élixir de racine ancienne", "🌿", 400, 60, { "vie", 5, 30 }, { extract = 2, ancient_root = 1 }, 32 },
	-- plantes rares qui ne servaient à rien (19/11)
	{ "elixir_lunaire", "Élixir lunaire", "🌙", 300, 20, { "chance", 6, 30 }, { extract = 1, moon_flower = 1, vial = 1 }, 28 },
	{ "potion_sauvage", "Potion de force sauvage", "🍄", 260, 30, { "force", 5, 30 }, { extract = 1, rare_mushroom = 2 }, 26 },
}

function A.apply(C)
	for _, p in A.POTIONS do
		local id, name, icon, price, heal, meal, needs, level = table.unpack(p)
		local ok = true
		for need in needs do
			if not C.ITEMS[need] then
				warn("[Alchimie] matière inconnue : " .. tostring(need))
				ok = false
			end
		end
		if ok and not C.ITEMS[id] then
			C.ITEMS[id] = { name = name, icon = icon, price = price, food = heal, meal = { meal[1], meal[2], meal[3] * 60 } }
			table.insert(C.RECIPES, { item = id, needs = table.clone(needs), station = "alembic", cat = "alchimie", skill = { "cuisine", level } })
		end
	end
end

return A
