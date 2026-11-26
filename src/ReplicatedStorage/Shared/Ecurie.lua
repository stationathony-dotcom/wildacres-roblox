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

Ecurie.FLY_SKILL = 30 -- Équitation minimale pour voler (les montures volantes peuvent demander plus : champ req)
-- 26/11 (plan « montures, entre WoW et ARK », docs/MONTURES-PLAN.md) : chaque monture a un palier d'ÉQUITATION
-- requis (req), une famille, un biome de prédilection (+15 % de vitesse), et selon le cas : nage (eau), places
-- (passagers), altitude maximale en vol (alt), passif décrit. Paliers : 1 novice, 5 confirmé, 10 bêtes sauvages,
-- 15 rares et aquatiques, 20 surnaturelles, 25 premières volantes, 35 volantes rares, 45 légendaires.
Ecurie.BIOME_BONUS = 1.15
Ecurie.INCUBATION = 3 -- jours de jeu pour qu'un œuf de monture éclose
-- 26/11 (propriétaire : « la monture volante doit être compliquée à avoir, il faut vraiment farmer ») :
-- vol à Équitation 30 minimum, volantes rares 35-45, œufs volants très rares, Équitation lente à monter
Ecurie.CAST = 2 -- secondes d'invocation (immobile, sans être frappé)
Ecurie.SKILL_SPEED = 0.006 -- +0,6 % de vitesse par niveau d'Équitation
Ecurie.XP_STUDS = 70 -- 1 point d'Équitation tous les 70 studs en selle (le vol se mérite)

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
	{ id = "cheval_alezan", req = 1, famille = "terrestre", biome = "prairie", name = "Cheval alezan", type = "sol", model = "cheval:1", speed = 1.0, rarity = 1, source = "ecurie", hint = "Les fermes en vendent, la prairie en garde de sauvages." },
	{ id = "cheval_bai", req = 1, famille = "terrestre", biome = "prairie", name = "Cheval bai", type = "sol", model = "cheval:2", speed = 1.0, rarity = 1, source = "ecurie", hint = "Les fermes en vendent, la prairie en garde de sauvages." },
	{ id = "cheval_noir", req = 1, famille = "terrestre", biome = "foret", name = "Cheval noir", type = "sol", model = "cheval:3", speed = 1.0, rarity = 2, source = "ecurie", hint = "Une robe sombre, plus rare au pré." },
	{ id = "cheval_blanc", req = 1, famille = "terrestre", biome = "neige", name = "Cheval blanc", type = "sol", model = "cheval:4", speed = 1.0, rarity = 2, source = "ecurie", hint = "Une robe claire, plus rare au pré." },
	{ id = "cheval_gris", req = 1, famille = "terrestre", biome = "prairie", name = "Cheval gris", type = "sol", model = "cheval:5", speed = 1.0, rarity = 1, source = "ecurie", hint = "Les fermes en vendent, la prairie en garde de sauvages." },
	{ id = "cheval_palomino", req = 1, famille = "terrestre", biome = "desert", name = "Cheval palomino", type = "sol", model = "cheval:6", speed = 1.0, rarity = 2, source = "ecurie", hint = "Une robe dorée qu'on croise rarement." },
	{ id = "ane", req = 1, famille = "utilitaire", places = 1, name = "Âne", type = "sol", model = "cheval:5:ane", speed = 0.68, rarity = 1, source = "ecurie", hint = "Têtu, mais il porte." },
	{ id = "mulet", req = 1, famille = "utilitaire", places = 2, passif = "porte un passager", name = "Mulet", type = "sol", model = "cheval:2:mulet", speed = 0.82, rarity = 1, source = "ecurie", hint = "Né d'un âne et d'une jument." },

	{ id = "loup_noir", req = 10, famille = "terrestre", biome = "foret", name = "Loup noir de monte", type = "sol", model = "bete:black_wolf", speed = 1.06, rarity = 3, source = "renes", drop = { "black_wolf", 0.01 }, hint = "Une meute noire rôde dans les forêts et les neiges." },
	{ id = "ours_blanc", req = 10, famille = "terrestre", biome = "neige", places = 2, passif = "porte un passager", name = "Ours blanc de bât", type = "sol", model = "bete:polar_bear", speed = 0.98, rarity = 3, source = "renes", drop = { "polar_bear", 0.012 }, hint = "Les glaces ont leur colosse placide." },
	{ id = "ours_cavernes", req = 10, famille = "terrestre", places = 2, passif = "porte un passager", name = "Ours des cavernes", type = "sol", model = "bete:cave_bear", speed = 1.0, rarity = 3, source = "renes", drop = { "cave_bear", 0.012 }, hint = "Ce qui dort au fond des grottes." },
	{ id = "sanglier_colossal", req = 15, famille = "terrestre", biome = "foret", name = "Sanglier colossal", type = "sol", model = "bete:colossal_boar", speed = 1.08, rarity = 4, source = "renes", drop = { "colossal_boar", 0.03 }, hint = "Un sanglier grand comme une charrette." },
	{ id = "basilic", req = 20, famille = "terrestre", biome = "desert", name = "Basilic des sables", type = "sol", model = "bete:sand_basilisk", speed = 1.1, rarity = 4, source = "renes", drop = { "sand_basilisk", 0.02 }, hint = "Il file sur le sable plus vite qu'un cheval." },
	{ id = "cerf_spectral", req = 20, famille = "surnaturelle", passif = "plus rapide la nuit", name = "Cerf spectral", type = "sol", model = "bete:spectral_stag", speed = 1.14, rarity = 4, source = "renes", drop = { "spectral_stag", 0.015 }, hint = "On ne le voit que la nuit." },
	{ id = "loup_vargor", req = 30, famille = "terrestre", biome = "foret", name = "Loup de Vargor", type = "sol", model = "bete:vargor", speed = 1.18, rarity = 5, source = "renes", drop = { "vargor", 0.06 }, hint = "Le roi des loups ne se laisse pas monter… de son vivant." },
	{ id = "scarabee_royal", req = 30, famille = "terrestre", biome = "desert", places = 2, passif = "porte un passager", name = "Scarabée royal", type = "sol", model = "bete:royal_scarab", speed = 1.12, rarity = 5, source = "renes", drop = { "royal_scarab", 0.06 }, hint = "Sous les dunes, une carapace d'or." },

	{ id = "aigle_geant", req = 30, famille = "volante", alt = 260, biome = "neige", name = "Aigle géant", type = "vol", model = "bete:giant_eagle", speed = 46, climb = 24, breath = 150, rarity = 3, source = "renes", drop = { "giant_eagle", 0.01 }, hint = "Il plane au-dessus des cimes enneigées." },
	{ id = "hippogriffe", req = 30, famille = "volante", alt = 240, biome = "foret", name = "Hippogriffe", type = "vol", model = "bete:hippogriff", speed = 52, climb = 22, breath = 130, rarity = 3, source = "apprivoiser", drop = { "hippogriff", 0.015 }, hint = "Mi-cheval, mi-aigle, farouche mais pas méchant." },
	{ id = "griffon", req = 35, famille = "volante", alt = 300, biome = "foret", name = "Griffon", type = "vol", model = "bete:griffin", speed = 60, climb = 26, breath = 100, rarity = 4, source = "apprivoiser", drop = { "griffin", 0.01 }, hint = "Le seigneur des forêts hautes." },
	{ id = "wyverne", req = 40, famille = "volante", alt = 320, biome = "desert", name = "Wyverne", type = "vol", model = "bete:wyvern", speed = 66, climb = 30, breath = 80, rarity = 4, source = "apprivoiser", drop = { "wyvern", 0.01 }, hint = "Elle niche au-dessus des déserts." },
	{ id = "wyverne_neiges", req = 45, famille = "volante", alt = 400, biome = "neige", passif = "brave le blizzard", name = "Wyverne des neiges", type = "vol", model = "bete:snow_wyvern", speed = 72, climb = 32, breath = 110, rarity = 5, source = "renes", drop = { "snow_wyvern", 0.05 }, hint = "La reine du blizzard garde ses rênes jusqu'à son dernier souffle." },

	-- 26/11 : terrestres, aquatiques, surnaturelles, utilitaires, volantes (sur des créatures déjà au bestiaire)
	{ id = "poney", req = 1, famille = "terrestre", biome = "prairie", name = "Poney", type = "sol", model = "cheval:6", scale = 0.78, speed = 0.9, rarity = 1, source = "ecurie", hint = "Petit, têtu, increvable." },
	{ id = "loup_polaire", req = 15, famille = "terrestre", biome = "neige", name = "Loup des neiges éternelles", type = "sol", model = "bete:polar_wolf", speed = 1.1, rarity = 3, source = "renes", drop = { "polar_wolf", 0.012 }, passif = "ne s'enlise jamais", hint = "Une meute blanche court sur la toundra." },
	{ id = "lezard_marais", req = 15, famille = "aquatique", biome = "marais", eau = true, name = "Lézard des tourbières", type = "sol", model = "bete:bog_lizard", speed = 0.95, rarity = 3, source = "renes", drop = { "bog_lizard", 0.015 }, passif = "nage", hint = "Il glisse aussi bien dans la vase que dans l'eau." },
	{ id = "kelpie", req = 15, famille = "aquatique", eau = true, name = "Kelpie", type = "sol", model = "bete:kelpie", speed = 1.05, rarity = 3, source = "renes", drop = { "kelpie", 0.02 }, passif = "nage vite", hint = "Un cheval d'eau qui hante les lacs." },
	{ id = "tortue_ancienne", req = 20, famille = "utilitaire", eau = true, places = 3, name = "Tortue caravanière", type = "sol", model = "bete:ancient_turtle", speed = 0.62, rarity = 4, source = "renes", drop = { "ancient_turtle", 0.04 }, passif = "nage, porte deux passagers", hint = "Lente, immense, et elle n'a peur de rien." },
	{ id = "renard_brumes", req = 20, famille = "surnaturelle", name = "Renard des brumes", type = "sol", model = "bete:spectral_fox", speed = 1.15, rarity = 4, source = "renes", drop = { "spectral_fox", 0.015 }, passif = "plus rapide la nuit", hint = "Il n'apparaît que dans la brume." },
	{ id = "golem_pierre", req = 30, famille = "surnaturelle", places = 2, name = "Colosse de pierre", type = "sol", model = "bete:stone_golem", speed = 0.85, rarity = 4, source = "renes", drop = { "stone_golem", 0.02 }, passif = "porte un passager", hint = "Un tas de rochers qui a décidé de marcher." },
	{ id = "serpent_marin", req = 35, famille = "aquatique", eau = true, places = 2, name = "Serpent marin", type = "sol", model = "bete:sea_serpent", speed = 1.25, rarity = 5, source = "renes", drop = { "sea_serpent", 0.04 }, passif = "nage très vite", hint = "Les marins en parlent à voix basse." },
	{ id = "hibou_geant", req = 30, famille = "volante", alt = 220, name = "Chouette spectrale", type = "vol", model = "bete:spectral_owl", speed = 48, climb = 22, breath = 140, rarity = 3, source = "renes", drop = { "spectral_owl", 0.012 }, passif = "souffle illimité la nuit", hint = "Elle chasse sans un bruit, la nuit." },
	{ id = "aigle_montagnes", req = 30, famille = "volante", alt = 300, biome = "neige", name = "Aigle des montagnes", type = "vol", model = "bete:mountain_eagle", speed = 54, climb = 28, breath = 120, rarity = 3, source = "oeuf", hint = "Il niche au sommet des falaises." },
	{ id = "dragonnet", req = 40, famille = "volante", alt = 300, biome = "desert", name = "Dragonnet", type = "vol", model = "bete:drakeling", speed = 58, climb = 26, breath = 110, rarity = 4, source = "oeuf", hint = "Un œuf tiède dans un nid du désert…" },
	{ id = "rapace_falaises", req = 30, famille = "volante", alt = 260, name = "Rapace des falaises", type = "vol", model = "bete:cliff_raptor", speed = 56, climb = 30, breath = 100, rarity = 3, source = "renes", drop = { "cliff_raptor", 0.012 }, hint = "Il plonge des falaises sur sa proie." },
}

-- Œufs de monture (trouvés dans les nids sauvages : exploration, pas tirage) : biome du nid → monture, chance
Ecurie.OEUFS = {
	neige = { { "aigle_montagnes", 0.006 }, { "griffon", 0.002 } },
	foret = { { "hippogriffe", 0.004 }, { "griffon", 0.002 } },
	desert = { { "dragonnet", 0.003 } },
	prairie = { { "hippogriffe", 0.002 } },
}
function Ecurie.oeufId(id: string): string
	return "oeuf_" .. id
end

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
