-- Catalogue des montures (système façon WoW, 26/11 — demande du propriétaire : « un système de montures
-- poussé comme WoW », « des drops rares sur certaines créatures », « devoir débloquer la compétence »,
-- « un beau bestiaire »). Données partagées : serveur (Systemes/Montures) et journal (Montures.client).
--
-- Chaque monture apprise entre dans la COLLECTION du personnage (globale, tous mondes) ; on l'invoque où
-- l'on veut (temps d'invocation), elle repart quand on descend. Les chevaux posés dans le monde (Horses)
-- restent, eux, de vraies bêtes qu'on peut voler (esprit GTA).
--
-- Sources :
--   « ecurie »     : acheter, apprivoiser ou faire naître un cheval / âne / mulet de cette robe
--   « apprivoiser » : apprivoiser la créature (Compagnons) l'ajoute aussi à la collection
--   « renes »      : RÊNES rares lâchées par la créature (chance), objet à utiliser pour l'apprendre ;
--                    les rênes se vendent et s'échangent (hôtel des ventes) comme tout objet
-- Compétence ÉQUITATION (monte en chevauchant) : vitesse + 0,6 % par niveau ; le VOL demande
-- Ecurie.FLY_SKILL en Équitation. Pas de niveau de personnage (règle 4) : c'est la pratique qui débloque.

local Ecurie = {}

Ecurie.FLY_SKILL = 25 -- Équitation requise pour voler
Ecurie.CAST = 2 -- secondes d'invocation (immobile, sans être frappé)
Ecurie.SKILL_SPEED = 0.006 -- +0,6 % de vitesse par niveau d'Équitation
Ecurie.XP_STUDS = 40 -- 1 point d'Équitation tous les 40 studs parcourus en selle

Ecurie.RARITY = {
	{ name = "Commune", color = Color3.fromRGB(220, 220, 220) },
	{ name = "Peu commune", color = Color3.fromRGB(110, 210, 90) },
	{ name = "Rare", color = Color3.fromRGB(80, 150, 255) },
	{ name = "Épique", color = Color3.fromRGB(185, 100, 255) },
	{ name = "Légendaire", color = Color3.fromRGB(255, 160, 40) },
}

-- id, nom, type (« sol » / « vol »), modèle (« cheval:<robe> » ou « bete:<kind> »), vitesse (× allure de
-- base ; vol : studs/s), rareté 1-5, source, créature qui lâche les rênes (et chance), indice (journal)
Ecurie.LIST = {
	{ id = "cheval_alezan", name = "Cheval alezan", type = "sol", model = "cheval:1", speed = 1.0, rarity = 1, source = "ecurie", hint = "Les fermes en vendent, la prairie en garde de sauvages." },
	{ id = "cheval_bai", name = "Cheval bai", type = "sol", model = "cheval:2", speed = 1.0, rarity = 1, source = "ecurie", hint = "Les fermes en vendent, la prairie en garde de sauvages." },
	{ id = "cheval_noir", name = "Cheval noir", type = "sol", model = "cheval:3", speed = 1.0, rarity = 2, source = "ecurie", hint = "Une robe sombre, plus rare au pré." },
	{ id = "cheval_blanc", name = "Cheval blanc", type = "sol", model = "cheval:4", speed = 1.0, rarity = 2, source = "ecurie", hint = "Une robe claire, plus rare au pré." },
	{ id = "cheval_gris", name = "Cheval gris", type = "sol", model = "cheval:5", speed = 1.0, rarity = 1, source = "ecurie", hint = "Les fermes en vendent, la prairie en garde de sauvages." },
	{ id = "cheval_palomino", name = "Cheval palomino", type = "sol", model = "cheval:6", speed = 1.0, rarity = 2, source = "ecurie", hint = "Une robe dorée qu'on croise rarement." },
	{ id = "ane", name = "Âne", type = "sol", model = "cheval:5:ane", speed = 0.68, rarity = 1, source = "ecurie", hint = "Têtu, mais il porte." },
	{ id = "mulet", name = "Mulet", type = "sol", model = "cheval:2:mulet", speed = 0.82, rarity = 1, source = "ecurie", hint = "Né d'un âne et d'une jument." },

	{ id = "loup_noir", name = "Loup noir de monte", type = "sol", model = "bete:black_wolf", speed = 1.06, rarity = 3, source = "renes", drop = { "black_wolf", 0.01 }, hint = "Une meute noire rôde dans les forêts et les neiges." },
	{ id = "ours_blanc", name = "Ours blanc de bât", type = "sol", model = "bete:polar_bear", speed = 0.98, rarity = 3, source = "renes", drop = { "polar_bear", 0.012 }, hint = "Les glaces ont leur colosse placide." },
	{ id = "ours_cavernes", name = "Ours des cavernes", type = "sol", model = "bete:cave_bear", speed = 1.0, rarity = 3, source = "renes", drop = { "cave_bear", 0.012 }, hint = "Ce qui dort au fond des grottes." },
	{ id = "sanglier_colossal", name = "Sanglier colossal", type = "sol", model = "bete:colossal_boar", speed = 1.08, rarity = 4, source = "renes", drop = { "colossal_boar", 0.03 }, hint = "Un sanglier grand comme une charrette." },
	{ id = "basilic", name = "Basilic des sables", type = "sol", model = "bete:sand_basilisk", speed = 1.1, rarity = 4, source = "renes", drop = { "sand_basilisk", 0.02 }, hint = "Il file sur le sable plus vite qu'un cheval." },
	{ id = "cerf_spectral", name = "Cerf spectral", type = "sol", model = "bete:spectral_stag", speed = 1.14, rarity = 4, source = "renes", drop = { "spectral_stag", 0.015 }, hint = "On ne le voit que la nuit." },
	{ id = "loup_vargor", name = "Loup de Vargor", type = "sol", model = "bete:vargor", speed = 1.18, rarity = 5, source = "renes", drop = { "vargor", 0.06 }, hint = "Le roi des loups ne se laisse pas monter… de son vivant." },
	{ id = "scarabee_royal", name = "Scarabée royal", type = "sol", model = "bete:royal_scarab", speed = 1.12, rarity = 5, source = "renes", drop = { "royal_scarab", 0.06 }, hint = "Sous les dunes, une carapace d'or." },

	{ id = "aigle_geant", name = "Aigle géant", type = "vol", model = "bete:giant_eagle", speed = 46, climb = 24, breath = 150, rarity = 3, source = "renes", drop = { "giant_eagle", 0.01 }, hint = "Il plane au-dessus des cimes enneigées." },
	{ id = "hippogriffe", name = "Hippogriffe", type = "vol", model = "bete:hippogriff", speed = 52, climb = 22, breath = 130, rarity = 3, source = "apprivoiser", drop = { "hippogriff", 0.015 }, hint = "Mi-cheval, mi-aigle, farouche mais pas méchant." },
	{ id = "griffon", name = "Griffon", type = "vol", model = "bete:griffin", speed = 60, climb = 26, breath = 100, rarity = 4, source = "apprivoiser", drop = { "griffin", 0.01 }, hint = "Le seigneur des forêts hautes." },
	{ id = "wyverne", name = "Wyverne", type = "vol", model = "bete:wyvern", speed = 66, climb = 30, breath = 80, rarity = 4, source = "apprivoiser", drop = { "wyvern", 0.01 }, hint = "Elle niche au-dessus des déserts." },
	{ id = "wyverne_neiges", name = "Wyverne des neiges", type = "vol", model = "bete:snow_wyvern", speed = 72, climb = 32, breath = 110, rarity = 5, source = "renes", drop = { "snow_wyvern", 0.05 }, hint = "La reine du blizzard garde ses rênes jusqu'à son dernier souffle." },
}

Ecurie.BY_ID = {}
Ecurie.BY_KIND = {} -- créature → monture (apprivoiser)
for i, m in Ecurie.LIST do
	m.order = i
	Ecurie.BY_ID[m.id] = m
	local kind = string.match(m.model, "^bete:(.+)$")
	if kind then
		m.kind = kind
		Ecurie.BY_KIND[kind] = m
	end
end

-- robe de cheval → monture « ecurie » (Horses : achat, apprivoisement, poulain)
function Ecurie.horseId(species: string?, coat: number?): string?
	if species == "ane" or species == "mulet" then
		return species
	end
	local names = { "alezan", "bai", "noir", "blanc", "gris", "palomino" }
	local n = names[coat or 1]
	return n and ("cheval_" .. n) or nil
end

function Ecurie.itemId(id: string): string
	return "renes_" .. id
end

-- prix de revente des rênes (or) selon la rareté : un drop rare vaut de l'or à l'hôtel des ventes
function Ecurie.itemPrice(m): number
	return ({ 40, 90, 260, 620, 1500 })[m.rarity] or 100
end

return Ecurie
