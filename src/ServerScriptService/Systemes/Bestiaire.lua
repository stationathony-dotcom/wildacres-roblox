-- Bestiaire médiéval (d'après « listes ennemi.txt ») : bandits et leurs camps, bêtes sauvages,
-- créatures de chaque biome, morts-vivants de la nuit, habitants des grottes, géants et boss uniques.
-- Les modèles sont générés par code (formes : humanoïde, quadrupède, insecte, serpent, volant,
-- golem, spectre, masse). La génération des régions n'est pas touchée : ces créatures sont posées
-- par-dessus, avec leur propre graine (les sauvegardes des mondes existants restent valables).
--
-- Chaque créature a un territoire (biomes), un horaire (jour, nuit), un comportement (neutre =
-- riposte, meute, craint la lumière), une rareté et un butin.

local Bestiaire = {}
local G, Config

local RESPAWN_DAYS = 3
local CAMP_CHANCE = 0.12

-- ----------------------------------------------------------------- Créatures
-- model = forme générée (voir FORMES) ; look = couleurs et options de la forme
local KINDS = {
	-- humains hostiles
	bandit = { name = "Bandit des routes", form = "humain", look = { "R", "BF", weapon = "epee", hood = true }, hp = 150, dmg = 18, speed = 14, level = 3, style = "charge", radius = 1.3,
		loot = { { "copper_coin", 2, 6, 1 }, { "coin_purse", 1, 1, 0.15 }, { "rope", 1, 1, 0.3 }, { "lockpick", 1, 1, 0.2 } }, gold = 2 },
	poacher = { name = "Braconnier", form = "humain", look = { "V", "BF", weapon = "arc", hood = true }, hp = 120, dmg = 14, speed = 13, level = 3, style = "spore", radius = 1.3,
		proj = { color = Color3.fromRGB(120, 90, 60), size = 0.5 }, loot = { { "deer_hide", 1, 1, 0.5 }, { "venison", 1, 2, 0.6 }, { "bait", 2, 4, 0.5 } } },
	deserter = { name = "Soldat déserteur", form = "humain", look = { "P", "F", weapon = "lance", helmet = true }, hp = 220, dmg = 22, speed = 12, level = 5, style = "charge", radius = 1.4,
		loot = { { "iron_ring", 2, 5, 0.6 }, { "rations", 1, 1, 0.4 }, { "guard_badge", 1, 1, 0.1 } }, gold = 3 },
	ruin_looter = { name = "Pilleur de ruines", form = "humain", look = { "Y", "BF", weapon = "dague", hood = true }, hp = 140, dmg = 20, speed = 15, level = 4, style = "charge", radius = 1.3,
		loot = { { "ancient_coin", 1, 2, 0.4 }, { "relic_fragment", 1, 1, 0.3 }, { "rusty_key", 1, 1, 0.3 } }, gold = 2 },
	bandit_chief = { name = "Chef de bande", form = "humain", look = { "N", "R", weapon = "hache", scale = 1.25, cape = "R" }, hp = 520, dmg = 32, speed = 13, level = 7, style = "charge", radius = 1.8, elite = true,
		loot = { { "merchant_purse", 1, 1, 1 }, { "treasure_map", 1, 1, 0.3 }, { "steel", 1, 2, 0.5 } }, gold = 6 },
	-- bêtes sauvages
	black_wolf = { name = "Loup noir", form = "quadrupede", look = { "N", "N", tete = 1.2, oreilles = true, queue = true }, hp = 140, dmg = 18, speed = 16, level = 4, style = "charge", radius = 1.4, pack = 3,
		loot = { { "wolf_pelt", 1, 1, 0.8 }, { "meat", 1, 2, 0.9 }, { "tooth", 1, 2, 0.5 } } },
	lynx = { name = "Lynx", form = "quadrupede", look = { "Y", "BC", tete = 1, oreilles = true, petit = true }, hp = 90, dmg = 16, speed = 17, level = 3, style = "charge", radius = 1.1,
		loot = { { "fur", 1, 2, 0.9 }, { "claw", 1, 1, 0.4 } } },
	wild_dog = { name = "Chien sauvage", form = "quadrupede", look = { "BC", "B", tete = 1, oreilles = true, queue = true, petit = true }, hp = 70, dmg = 12, speed = 15, level = 2, style = "charge", radius = 1.1, pack = 3,
		loot = { { "raw_hide", 1, 1, 0.6 }, { "bone", 1, 2, 0.5 } } },
	cave_bear = { name = "Ours des cavernes", form = "quadrupede", look = { "BF", "N", tete = 2, gros = true, oreilles = true }, hp = 480, dmg = 34, speed = 12, level = 7, style = "charge", radius = 2.4, neutral = true, elite = true,
		loot = { { "fur", 3, 4, 1 }, { "claw", 1, 2, 0.8 }, { "fossil_bone", 1, 1, 0.1 } }, gold = 3 },
	polar_bear = { name = "Ours blanc", form = "quadrupede", look = { "W", "W", tete = 2, gros = true, oreilles = true }, hp = 420, dmg = 30, speed = 12, level = 6, style = "charge", radius = 2.4, neutral = true,
		loot = { { "fur", 3, 4, 1 }, { "fat", 2, 3, 1 }, { "meat", 3, 4, 1 } } },
	jackal = { name = "Chacal", form = "quadrupede", look = { "Y", "BC", tete = 0.9, oreilles = true, queue = true, petit = true }, hp = 70, dmg = 12, speed = 16, level = 2, style = "charge", radius = 1, pack = 3,
		loot = { { "raw_hide", 1, 1, 0.6 }, { "tooth", 1, 1, 0.4 } } },
	hyena = { name = "Hyène monstrueuse", form = "quadrupede", look = { "BC", "BF", tete = 1.3, oreilles = true, queue = true }, hp = 200, dmg = 22, speed = 15, level = 5, style = "charge", radius = 1.5, pack = 2,
		loot = { { "raw_hide", 1, 2, 0.8 }, { "monster_tooth", 1, 1, 0.3 } } },
	frost_boar = { name = "Sanglier givré", form = "quadrupede", look = { "BL", "W", tete = 1.4, defenses = true, gros = true }, hp = 220, dmg = 22, speed = 13, level = 5, style = "charge", radius = 1.7, neutral = true,
		loot = { { "boar_meat", 2, 3, 1 }, { "ice_crystal", 1, 1, 0.4 } } },
	swamp_boar = { name = "Sanglier des marécages", form = "quadrupede", look = { "V", "BF", tete = 1.4, defenses = true, gros = true }, hp = 180, dmg = 20, speed = 13, level = 4, style = "charge", radius = 1.7, neutral = true,
		loot = { { "boar_meat", 2, 3, 1 }, { "leather", 1, 2, 0.8 } } },
	spectral_stag = { name = "Cerf spectral", form = "quadrupede", look = { "W", "W", tete = 1.1, bois = true, spectre = true }, hp = 160, dmg = 18, speed = 18, level = 5, style = "charge", radius = 1.5, night = true,
		loot = { { "antler", 1, 1, 0.8 }, { "wisp_dust", 1, 2, 0.8 }, { "night_feather", 1, 1, 0.2 } } },
	snake = { name = "Serpent venimeux", form = "serpent", look = { "V", "Y" }, hp = 60, dmg = 16, speed = 11, level = 2, style = "charge", radius = 0.9,
		loot = { { "scales", 1, 2, 0.7 }, { "tooth", 1, 1, 0.4 } } },
	dune_snake = { name = "Serpent des dunes", form = "serpent", look = { "Y", "BF", long = true }, hp = 110, dmg = 20, speed = 12, level = 4, style = "charge", radius = 1,
		loot = { { "scales", 2, 3, 0.9 }, { "salt", 1, 2, 0.3 } } },
	water_snake = { name = "Serpent des eaux", form = "serpent", look = { "BL", "V", long = true }, hp = 120, dmg = 18, speed = 13, level = 4, style = "charge", radius = 1,
		loot = { { "scales", 2, 3, 0.9 }, { "pearl", 1, 1, 0.05 } } },
	giant_bat = { name = "Chauve-souris géante", form = "volant", look = { "BF", "N", chauvesouris = true }, hp = 60, dmg = 12, speed = 16, level = 3, style = "charge", radius = 1.2, flies = true,
		loot = { { "raw_hide", 1, 1, 0.5 }, { "tooth", 1, 1, 0.4 } } },
	giant_crow = { name = "Corbeau géant", form = "volant", look = { "N", "N" }, hp = 80, dmg = 14, speed = 15, level = 3, style = "charge", radius = 1.3, flies = true, night = true,
		loot = { { "feather", 2, 4, 1 }, { "night_feather", 1, 1, 0.15 } } },
	bee_swarm = { name = "Essaim d'abeilles sauvages", form = "volant", look = { "Y", "N", essaim = true }, hp = 40, dmg = 8, speed = 13, level = 2, style = "charge", radius = 1.4, flies = true, neutral = true,
		loot = { { "honey", 1, 2, 0.8 }, { "beeswax", 1, 2, 0.8 }, { "pollen", 1, 3, 0.6 } } },
	-- forêt
	goblin_archer = { name = "Gobelin archer", form = "humain", look = { "V", "BF", weapon = "arc", petit = true, peau = "V" }, hp = 120, dmg = 14, speed = 13, level = 4, style = "spore", radius = 1.2,
		proj = { color = Color3.fromRGB(110, 80, 50), size = 0.5 }, loot = { { "feather", 1, 2, 0.6 }, { "copper_ore", 1, 2, 0.4 } }, gold = 2 },
	root_troll = { name = "Troll des racines", form = "humain", look = { "BF", "V", weapon = "massue", scale = 1.7, peau = "V" }, hp = 600, dmg = 36, speed = 9, level = 7, style = "charge", radius = 2.4, elite = true, neutral = true,
		loot = { { "ancient_root", 1, 1, 0.5 }, { "oak_log", 2, 4, 1 }, { "resin", 2, 3, 1 } }, gold = 4 },
	wood_golem = { name = "Golem de bois", form = "golem", look = { "B", "V" }, hp = 380, dmg = 26, speed = 8, level = 6, style = "charge", radius = 2, neutral = true,
		loot = { { "oak_log", 3, 5, 1 }, { "petrified_wood", 1, 1, 0.15 } }, gold = 2 },
	bramble_witch = { name = "Sorcier des ronces", form = "humain", look = { "VI", "V", weapon = "baton", hood = true }, hp = 160, dmg = 20, speed = 11, level = 5, style = "spore", radius = 1.3,
		proj = { color = Color3.fromRGB(120, 200, 90), size = 1.2, poison = true }, loot = { { "nettle", 2, 4, 1 }, { "extract", 1, 1, 0.3 }, { "mandrake", 1, 1, 0.08 } }, gold = 3 },
	-- marais
	leech = { name = "Sangsue géante", form = "masse", look = { "N", "R", long = true }, hp = 90, dmg = 14, speed = 8, level = 3, style = "hop", radius = 1.2,
		loot = { { "slime_gel", 1, 2, 0.8 } } },
	mud_man = { name = "Homme-boue", form = "masse", look = { "BF", "Y", grand = true }, hp = 220, dmg = 20, speed = 8, level = 4, style = "hop", radius = 1.6,
		loot = { { "clay", 2, 4, 1 }, { "dirt", 2, 3, 1 }, { "ancient_coin", 1, 1, 0.05 } } },
	bog_lizard = { name = "Lézard des tourbières", form = "quadrupede", look = { "V", "Y", tete = 1, queue = true, plat = true }, hp = 120, dmg = 16, speed = 12, level = 3, style = "charge", radius = 1.3,
		loot = { { "scales", 1, 2, 0.8 }, { "leather", 1, 1, 0.4 } } },
	swamp_witch = { name = "Sorcière des marais", form = "humain", look = { "N", "V", weapon = "baton", hood = true, peau = "V" }, hp = 200, dmg = 24, speed = 10, level = 6, style = "spore", radius = 1.3, night = true,
		proj = { color = Color3.fromRGB(80, 200, 120), size = 1.4, poison = true }, loot = { { "extract", 1, 2, 0.6 }, { "night_flower", 1, 1, 0.3 }, { "vial", 1, 2, 0.6 } }, gold = 4 },
	drowned_spirit = { name = "Esprit noyé", form = "spectre", look = { "BL", "BL" }, hp = 120, dmg = 18, speed = 12, level = 4, style = "charge", radius = 1.2, night = true, fearsLight = true,
		loot = { { "wisp_dust", 1, 2, 0.8 }, { "pearl", 1, 1, 0.05 } } },
	-- désert
	beetle = { name = "Scarabée cuirassé", form = "insecte", look = { "BL", "N", carapace = true }, hp = 260, dmg = 18, speed = 9, level = 5, style = "charge", radius = 1.6,
		loot = { { "scales", 1, 2, 0.6 }, { "colored_stone", 1, 1, 0.3 } } },
	desert_spider = { name = "Araignée du désert", form = "insecte", look = { "Y", "BF", pattes8 = true }, hp = 150, dmg = 16, speed = 15, level = 4, style = "spore", radius = 1.6,
		proj = { color = Color3.fromRGB(240, 220, 170), size = 0.9, poison = true }, loot = { { "silk", 1, 2, 0.9 } } },
	sandstone_golem = { name = "Golem de grès", form = "golem", look = { "Y", "T" }, hp = 480, dmg = 30, speed = 8, level = 7, style = "charge", radius = 2.2, elite = true,
		loot = { { "sand", 4, 8, 1 }, { "ruby", 1, 1, 0.05 }, { "carved_stone", 1, 1, 0.15 } }, gold = 4 },
	dune_spectre = { name = "Spectre des dunes", form = "spectre", look = { "Y", "O" }, hp = 140, dmg = 20, speed = 13, level = 5, style = "spore", radius = 1.2, night = true, fearsLight = true,
		proj = { color = Color3.fromRGB(240, 200, 120), size = 1 }, loot = { { "ancient_coin", 1, 2, 0.5 }, { "wisp_dust", 1, 2, 0.6 } } },
	-- toundra
	frost_troll = { name = "Troll des glaces", form = "humain", look = { "BL", "W", weapon = "massue", scale = 1.8, peau = "BL" }, hp = 650, dmg = 38, speed = 9, level = 8, style = "charge", radius = 2.4, elite = true,
		loot = { { "ice_crystal", 2, 3, 1 }, { "fur", 2, 3, 1 }, { "ancient_crystal", 1, 1, 0.1 } }, gold = 5 },
	frost_spider = { name = "Araignée de givre", form = "insecte", look = { "W", "BL", pattes8 = true }, hp = 170, dmg = 18, speed = 14, level = 5, style = "spore", radius = 1.6,
		proj = { color = Color3.fromRGB(190, 230, 255), size = 1 }, loot = { { "silk", 1, 3, 1 }, { "ice_crystal", 1, 1, 0.3 } } },
	blizzard_spectre = { name = "Spectre du blizzard", form = "spectre", look = { "W", "BL" }, hp = 160, dmg = 22, speed = 14, level = 6, style = "charge", radius = 1.3, night = true,
		loot = { { "ice_crystal", 1, 2, 0.8 }, { "wisp_dust", 1, 1, 0.5 } } },
	-- morts-vivants (la nuit)
	-- règle 9 (pas de squelettes classiques) : « skeleton » / « ancient_skeleton » sont devenus des GISANTS, statues de
	-- tombeau qui se lèvent la nuit (ids gardés pour les sauvegardes, journaux et butins)
	skeleton = { name = "Gisant errant", form = "humain", look = { "PC", "P", peau = "PC", pierre = true, weapon = "epee" }, hp = 110, dmg = 16, speed = 11, level = 3, style = "charge", radius = 1.2, night = true,
		loot = { { "stone", 2, 4, 1 }, { "copper_coin", 1, 3, 0.4 } } },
	ghoul = { name = "Goule", form = "humain", look = { "V", "N", peau = "V", courbe = true }, hp = 150, dmg = 20, speed = 13, level = 4, style = "charge", radius = 1.3, night = true,
		loot = { { "rotten", 2, 3, 1 }, { "bone", 1, 2, 0.6 }, { "claw", 1, 1, 0.3 } } },
	revenant = { name = "Revenant", form = "spectre", look = { "BL", "W" }, hp = 130, dmg = 20, speed = 14, level = 4, style = "charge", radius = 1.2, night = true, fearsLight = true,
		loot = { { "wisp_dust", 1, 2, 0.8 }, { "lost_item", 1, 1, 0.2 } } },
	ghost_knight = { name = "Fantôme de chevalier", form = "spectre", look = { "PC", "BL", weapon = "epee", helmet = true }, hp = 320, dmg = 30, speed = 12, level = 6, style = "charge", radius = 1.4, night = true, elite = true,
		loot = { { "wisp_dust", 2, 3, 1 }, { "ancient_jewel", 1, 1, 0.1 }, { "rusty_key", 1, 1, 0.3 } }, gold = 4 },
	-- grottes, ruines, géants
	cave_spider = { name = "Araignée des cavernes", form = "insecte", look = { "N", "R", pattes8 = true }, hp = 160, dmg = 16, speed = 14, level = 4, style = "spore", radius = 1.6,
		proj = { color = Color3.fromRGB(230, 230, 230), size = 1, poison = true }, loot = { { "silk", 2, 3, 1 }, { "glowstone", 1, 1, 0.08 } } },
	stone_golem = { name = "Colosse de pierre", form = "golem", look = { "P", "O" }, hp = 700, dmg = 36, speed = 7, level = 8, style = "charge", radius = 2.6, elite = true,
		loot = { { "stone", 6, 10, 1 }, { "carved_stone", 1, 1, 0.3 }, { "mineral_heart", 1, 1, 0.03 } }, gold = 5 },
	gargoyle = { name = "Gargouille animée", form = "volant", look = { "P", "PC", gargouille = true }, hp = 260, dmg = 24, speed = 12, level = 6, style = "charge", radius = 1.6, flies = true,
		loot = { { "stone", 3, 5, 1 }, { "carved_stone", 1, 1, 0.1 } }, gold = 3 },
	ogre = { name = "Ogre", form = "humain", look = { "BC", "BF", weapon = "massue", scale = 1.9, peau = "Y", ventre = true }, hp = 800, dmg = 40, speed = 9, level = 8, style = "charge", radius = 2.6, elite = true, neutral = true,
		loot = { { "meat", 4, 6, 1 }, { "merchant_purse", 1, 1, 0.4 }, { "rare_horn", 1, 1, 0.05 } }, gold = 6 },
	minotaur = { name = "Minotaure", form = "humain", look = { "BF", "R", weapon = "hache", scale = 1.8, cornes = true, peau = "BF" }, hp = 900, dmg = 44, speed = 12, level = 9, style = "charge", radius = 2.4, elite = true,
		loot = { { "horn", 2, 2, 1 }, { "rare_horn", 1, 1, 0.2 }, { "steel", 1, 3, 0.6 } }, gold = 7 },
	-- boss uniques (repaires des grottes et errances)
	vargor = { name = "Vargor, le Roi des loups", form = "quadrupede", look = { "P", "N", tete = 2, gros = true, oreilles = true, queue = true, criniere = "W", scale = 1.6 }, hp = 2000, dmg = 48, speed = 16, level = 9, style = "charge", radius = 3.2, boss = true, minion = "black_wolf",
		loot = { { "royal_fur", 1, 1, 1 }, { "wolf_pelt", 3, 5, 1 } }, gold = 8 },
	brumeglace = { name = "Brumeglace", form = "spectre", look = { "W", "BL", scale = 2.4 }, hp = 2600, dmg = 52, speed = 9, level = 10, style = "spore", radius = 3.6, boss = true, minion = "blizzard_spectre",
		proj = { color = Color3.fromRGB(200, 240, 255), size = 2.6 }, loot = { { "frost_crystal", 1, 1, 1 }, { "ice_crystal", 4, 6, 1 } }, gold = 9 },
	bramble_mother = { name = "Mère des Ronces", form = "golem", look = { "V", "R", scale = 1.8, ronces = true }, hp = 2200, dmg = 46, speed = 7, level = 9, style = "spore", radius = 3.4, boss = true, minion = "wood_golem",
		proj = { color = Color3.fromRGB(120, 200, 80), size = 2.2, poison = true }, loot = { { "ancient_seed", 2, 3, 1 }, { "ancient_root", 1, 2, 1 } }, gold = 8 },
	marsh_king = { name = "Roi des marais", form = "masse", look = { "V", "O", grand = true, scale = 2.2, couronne = true }, hp = 2200, dmg = 46, speed = 8, level = 9, style = "hop", radius = 3.6, boss = true, minion = "mud_man",
		loot = { { "black_scale", 1, 2, 1 }, { "pearl", 1, 3, 1 } }, gold = 8 },
	royal_scarab = { name = "Scarabée royal", form = "insecte", look = { "O", "BL", carapace = true, scale = 2.4 }, hp = 2400, dmg = 48, speed = 9, level = 10, style = "charge", radius = 3.6, boss = true, minion = "beetle",
		loot = { { "golden_carapace", 1, 1, 1 }, { "gold_ore", 3, 6, 1 } }, gold = 9 },
	crownless_king = { name = "Le Roi sans couronne", form = "spectre", look = { "VI", "O", weapon = "epee", scale = 1.6, couronne = true }, hp = 2800, dmg = 54, speed = 11, level = 10, style = "charge", radius = 2.8, boss = true, minion = "ghost_knight",
		loot = { { "lost_crown", 1, 1, 1 }, { "royal_seal", 1, 1, 0.3 }, { "ancient_jewel", 1, 2, 1 } }, gold = 10 },
	-- ---------------------------------------------------------------- 18/11 : suite de « listes ennemi.txt »
	-- (formes existantes, rien de neuf à modéliser)
	highwayman = { name = "Voleur de grand chemin", form = "humain", look = { "N", "BF", weapon = "dague", hood = true }, hp = 130, dmg = 18, speed = 15, level = 3, style = "charge", radius = 1.3,
		loot = { { "copper_coin", 2, 5, 1 }, { "coin_purse", 1, 1, 0.3 }, { "lockpick", 1, 1, 0.3 } }, gold = 2 },
	pillager = { name = "Pillard", form = "humain", look = { "R", "B", weapon = "hache" }, hp = 170, dmg = 20, speed = 13, level = 4, style = "charge", radius = 1.3,
		loot = { { "copper_coin", 2, 6, 1 }, { "rope", 1, 2, 0.4 }, { "rations", 1, 1, 0.3 } }, gold = 2 },
	smuggler = { name = "Contrebandier", form = "humain", look = { "BL", "BF", weapon = "dague", hood = true }, hp = 140, dmg = 16, speed = 14, level = 4, style = "charge", radius = 1.3,
		loot = { { "salt", 1, 3, 0.6 }, { "coin_purse", 1, 1, 0.3 }, { "merchant_purse", 1, 1, 0.05 } }, gold = 3 },
	mercenary = { name = "Mercenaire", form = "humain", look = { "P", "R", weapon = "epee", helmet = true }, hp = 260, dmg = 24, speed = 12, level = 6, style = "charge", radius = 1.4,
		loot = { { "iron_ring", 2, 4, 0.7 }, { "steel", 1, 1, 0.2 }, { "copper_coin", 3, 8, 1 } }, gold = 4 },
	renegade_guard = { name = "Garde renégat", form = "humain", look = { "P", "BL", weapon = "lance", helmet = true }, hp = 240, dmg = 22, speed = 12, level = 5, style = "charge", radius = 1.4,
		loot = { { "guard_badge", 1, 1, 0.3 }, { "iron_ring", 1, 3, 0.6 } }, gold = 3 },
	marauder = { name = "Maraudeur", form = "humain", look = { "BF", "N", weapon = "massue", hood = true }, hp = 180, dmg = 22, speed = 13, level = 4, style = "charge", radius = 1.4,
		loot = { { "meat", 1, 2, 0.6 }, { "raw_hide", 1, 1, 0.5 }, { "copper_coin", 1, 4, 1 } }, gold = 2 },
	fake_merchant = { name = "Faux marchand", form = "humain", look = { "Y", "PC", weapon = "dague" }, hp = 120, dmg = 16, speed = 13, level = 3, style = "charge", radius = 1.3, neutral = true,
		loot = { { "coin_purse", 1, 1, 0.6 }, { "merchant_purse", 1, 1, 0.1 } }, gold = 3 },
	corrupt_guard = { name = "Garde corrompu", form = "humain", look = { "P", "Y", weapon = "epee", helmet = true }, hp = 230, dmg = 22, speed = 12, level = 5, style = "charge", radius = 1.4, neutral = true,
		loot = { { "guard_badge", 1, 1, 0.5 }, { "coin_purse", 1, 1, 0.4 } }, gold = 3 },
	bounty_hunter = { name = "Chasseur de primes", form = "humain", look = { "N", "R", weapon = "arc", hood = true }, hp = 200, dmg = 20, speed = 14, level = 6, style = "spore", radius = 1.3,
		proj = { color = Color3.fromRGB(120, 90, 60), size = 0.5, fast = true }, loot = { { "rope", 1, 2, 0.5 }, { "copper_coin", 3, 6, 1 }, { "treasure_map", 1, 1, 0.05 } }, gold = 4 },
	desert_raider = { name = "Pillard du désert", form = "humain", look = { "Y", "O", weapon = "epee", hood = true }, hp = 180, dmg = 20, speed = 14, level = 5, style = "charge", radius = 1.3,
		loot = { { "ancient_coin", 1, 1, 0.3 }, { "copper_coin", 2, 6, 1 } }, gold = 3 },
	brown_bear = { name = "Ours brun", form = "quadrupede", look = { "B", "BF", tete = 2, gros = true, oreilles = true }, hp = 360, dmg = 28, speed = 12, level = 5, style = "charge", radius = 2.2, neutral = true,
		loot = { { "fur", 2, 3, 1 }, { "meat", 2, 3, 1 }, { "claw", 1, 1, 0.5 } } },
	rabid_fox = { name = "Renard enragé", form = "quadrupede", look = { "R", "W", tete = 0.9, oreilles = true, queue = true, petit = true }, hp = 60, dmg = 14, speed = 17, level = 2, style = "charge", radius = 0.9,
		loot = { { "fur", 1, 1, 0.6 } } },
	stray_dog = { name = "Chien errant", form = "quadrupede", look = { "BC", "BF", tete = 1, oreilles = true, queue = true, petit = true }, hp = 60, dmg = 10, speed = 15, level = 1, style = "charge", radius = 1, pack = 2,
		loot = { { "bone", 1, 1, 0.6 } } },
	polar_wolf = { name = "Loup polaire", form = "quadrupede", look = { "W", "BL", tete = 1.2, oreilles = true, queue = true }, hp = 150, dmg = 18, speed = 16, level = 4, style = "charge", radius = 1.4, pack = 3,
		loot = { { "wolf_pelt", 1, 1, 0.8 }, { "meat", 1, 2, 0.9 } } },
	giant_eagle = { name = "Aigle géant", form = "volant", look = { "BF", "W" }, hp = 120, dmg = 18, speed = 16, level = 4, style = "charge", radius = 1.4, flies = true,
		loot = { { "feather", 2, 4, 1 } } },
	harpy = { name = "Harpie", form = "volant", look = { "BC", "BF" }, hp = 160, dmg = 20, speed = 15, level = 5, style = "charge", radius = 1.4, flies = true,
		loot = { { "feather", 2, 5, 1 }, { "claw", 1, 1, 0.4 } } },
	wood_goblin = { name = "Gobelin des bois", form = "humain", look = { "V", "BF", weapon = "dague", petit = true, peau = "V" }, hp = 100, dmg = 12, speed = 14, level = 3, style = "charge", radius = 1.1,
		loot = { { "copper_coin", 1, 3, 1 }, { "mushroom", 1, 2, 0.5 } }, gold = 1 },
	corrupted_ent = { name = "Ent corrompu", form = "golem", look = { "BF", "VI" }, hp = 520, dmg = 30, speed = 7, level = 7, style = "charge", radius = 2.2, elite = true, neutral = true,
		loot = { { "wood", 4, 8, 1 }, { "resin", 1, 3, 0.8 } }, gold = 3 },
	sylvan_spider = { name = "Araignée sylvestre", form = "insecte", look = { "V", "N", pattes8 = true }, hp = 140, dmg = 15, speed = 14, level = 4, style = "spore", radius = 1.3,
		proj = { color = Color3.fromRGB(240, 240, 240), size = 1, poison = true }, loot = { { "silk", 1, 3, 1 } } },
	colossal_boar = { name = "Sanglier colossal", form = "quadrupede", look = { "BF", "N", tete = 1.6, defenses = true, gros = true, scale = 1.5 }, hp = 420, dmg = 30, speed = 13, level = 6, style = "charge", radius = 2.2, elite = true,
		loot = { { "meat", 3, 5, 1 }, { "raw_hide", 2, 3, 1 }, { "tooth", 1, 2, 0.6 } }, gold = 2 },
	tree_spirit = { name = "Esprit des arbres", form = "spectre", look = { "V", "W" }, hp = 140, dmg = 18, speed = 12, level = 5, style = "charge", radius = 1.2, night = true, fearsLight = true,
		loot = { { "resin", 1, 2, 0.6 } } },
	swamp_goblin = { name = "Gobelin des marais", form = "humain", look = { "BF", "V", weapon = "lance", petit = true, peau = "V" }, hp = 110, dmg = 13, speed = 13, level = 3, style = "charge", radius = 1.1,
		loot = { { "copper_coin", 1, 3, 1 }, { "bone", 1, 1, 0.4 } }, gold = 1 },
	reed_spider = { name = "Araignée des roseaux", form = "insecte", look = { "Y", "V", pattes8 = true }, hp = 130, dmg = 14, speed = 14, level = 4, style = "spore", radius = 1.3,
		proj = { color = Color3.fromRGB(220, 230, 180), size = 1, poison = true }, loot = { { "silk", 1, 2, 1 } } },
	mud_golem = { name = "Golem de vase", form = "golem", look = { "BF", "V" }, hp = 420, dmg = 26, speed = 7, level = 6, style = "charge", radius = 2.1, elite = true,
		loot = { { "clay", 3, 6, 1 } }, gold = 2 },
	sand_worm = { name = "Ver des sables", form = "serpent", look = { "Y", "O", long = true, scale = 1.6 }, hp = 320, dmg = 26, speed = 12, level = 6, style = "charge", radius = 1.6, elite = true,
		loot = { { "tooth", 1, 3, 0.8 }, { "raw_hide", 1, 2, 0.6 } }, gold = 2 },
	ruin_guardian = { name = "Gardien des ruines", form = "golem", look = { "Y", "O" }, hp = 520, dmg = 30, speed = 8, level = 7, style = "charge", radius = 2.2, elite = true, neutral = true,
		loot = { { "relic_fragment", 1, 2, 0.8 }, { "ancient_coin", 1, 3, 0.6 } }, gold = 4 },
	sand_basilisk = { name = "Basilic des sables", form = "quadrupede", look = { "Y", "V", tete = 1, queue = true, plat = true }, hp = 220, dmg = 24, speed = 12, level = 6, style = "spore", radius = 1.6,
		proj = { color = Color3.fromRGB(160, 220, 90), size = 1.2, poison = true }, loot = { { "raw_hide", 1, 2, 0.8 }, { "tooth", 1, 1, 0.5 } } },
	spectral_fox = { name = "Renard spectral", form = "quadrupede", look = { "W", "BL", tete = 0.9, oreilles = true, queue = true, petit = true, spectre = true }, hp = 90, dmg = 16, speed = 18, level = 4, style = "charge", radius = 0.9, night = true,
		loot = { { "fur", 1, 1, 0.5 } } },
	ice_giant = { name = "Géant de glace", form = "humain", look = { "W", "BL", weapon = "massue", scale = 2.2, peau = "BL" }, hp = 900, dmg = 42, speed = 9, level = 9, style = "charge", radius = 2.8, elite = true,
		loot = { { "ice_crystal", 1, 3, 0.8 }, { "fur", 2, 4, 1 } }, gold = 6 },
	corrupted_stag = { name = "Cerf corrompu", form = "quadrupede", look = { "N", "VI", tete = 1.1, bois = true }, hp = 180, dmg = 20, speed = 17, level = 5, style = "charge", radius = 1.4,
		loot = { { "deer_hide", 1, 1, 0.7 }, { "venison", 1, 2, 0.7 } } },
	shadow_wolf = { name = "Loup des ombres", form = "quadrupede", look = { "N", "N", tete = 1.2, oreilles = true, queue = true, spectre = true }, hp = 140, dmg = 18, speed = 17, level = 5, style = "charge", radius = 1.4, pack = 3, night = true,
		loot = { { "wolf_pelt", 1, 1, 0.6 } } },
	faceless_walker = { name = "Marcheur sans visage", form = "spectre", look = { "N", "PC" }, hp = 180, dmg = 22, speed = 11, level = 6, style = "charge", radius = 1.3, night = true, fearsLight = true,
		loot = { { "relic_fragment", 1, 1, 0.3 } } },
	ghost_crow = { name = "Corbeau fantôme", form = "volant", look = { "BL", "BL" }, hp = 90, dmg = 14, speed = 16, level = 4, style = "charge", radius = 1.3, flies = true, night = true,
		loot = { { "feather", 1, 3, 1 } } },
	creeping_shadow = { name = "Ombre rampante", form = "masse", look = { "N", "N", long = true }, hp = 160, dmg = 20, speed = 10, level = 5, style = "hop", radius = 1.4, night = true, fearsLight = true,
		loot = { { "bone", 1, 2, 0.5 } } },
	ancient_skeleton = { name = "Gisant ancien", form = "humain", look = { "P", "F", peau = "P", pierre = true, weapon = "hache" }, hp = 200, dmg = 22, speed = 11, level = 5, style = "charge", radius = 1.3, night = true,
		loot = { { "stone", 2, 4, 1 }, { "ancient_coin", 1, 1, 0.3 } } },
	fallen_monk = { name = "Moine déchu", form = "humain", look = { "BF", "N", weapon = "baton", hood = true }, hp = 170, dmg = 22, speed = 11, level = 5, style = "spore", radius = 1.3, night = true,
		proj = { color = Color3.fromRGB(140, 90, 200), size = 1 }, loot = { { "relic_fragment", 1, 1, 0.4 }, { "copper_coin", 1, 4, 1 } }, gold = 2 },
	mummy = { name = "Momie ancienne", form = "humain", look = { "T", "Y", courbe = true }, hp = 220, dmg = 22, speed = 10, level = 6, style = "charge", radius = 1.3, night = true,
		loot = { { "ancient_coin", 1, 2, 0.6 }, { "relic_fragment", 1, 1, 0.3 } }, gold = 3 },
	cyclops = { name = "Cyclope", form = "humain", look = { "Y", "BF", weapon = "massue", scale = 2, peau = "Y" }, hp = 850, dmg = 42, speed = 9, level = 8, style = "charge", radius = 2.6, elite = true,
		loot = { { "tooth", 2, 3, 1 }, { "treasure_map", 1, 1, 0.15 } }, gold = 6 },
	-- 18/11, 2e fournée de « listes ennemi.txt » (nuit, maudits, volants, eaux, géants)
	dark_prowler = { name = "Rôdeur obscur", form = "humain", look = { "N", "N", weapon = "dague", hood = true }, hp = 170, dmg = 22, speed = 15, level = 5, style = "charge", radius = 1.3, night = true,
		loot = { { "copper_coin", 2, 5, 1 } }, gold = 2 },
	wandering_spectre = { name = "Spectre errant", form = "spectre", look = { "PC", "W" }, hp = 130, dmg = 18, speed = 13, level = 4, style = "charge", radius = 1.2, night = true, fearsLight = true,
		loot = { { "bone", 1, 1, 0.4 } } },
	moon_hunter = { name = "Chasseur de lune", form = "humain", look = { "BL", "N", weapon = "arc", hood = true }, hp = 190, dmg = 20, speed = 14, level = 6, style = "spore", radius = 1.3, night = true, proj = { color = Color3.fromRGB(200, 200, 230), size = 0.8 },
		loot = { { "feather", 1, 3, 0.7 } }, gold = 3 },
	night_howler = { name = "Hurleur nocturne", form = "quadrupede", look = { "N", "P", tete = 1.3, oreilles = true, queue = true }, hp = 170, dmg = 20, speed = 17, level = 5, style = "charge", radius = 1.4, night = true, pack = 2,
		loot = { { "wolf_pelt", 1, 1, 0.6 } } },
	tomb_warden = { name = "Gardien des tombes", form = "golem", look = { "P", "PC" }, hp = 480, dmg = 30, speed = 8, level = 7, style = "charge", radius = 2.2, night = true, elite = true,
		loot = { { "ancient_coin", 1, 3, 0.8 } }, gold = 4 },
	light_eater = { name = "Dévoreur de lumière", form = "masse", look = { "N", "VI", grand = true }, hp = 260, dmg = 26, speed = 9, level = 6, style = "hop", radius = 1.8, night = true, fearsLight = true,
		loot = { { "coal", 2, 4, 1 } }, gold = 2 },
	cursed_warden = { name = "Gardien maudit", form = "humain", look = { "PC", "VI", weapon = "epee", helmet = true }, hp = 300, dmg = 28, speed = 11, level = 7, style = "charge", radius = 1.5, night = true, elite = true,
		loot = { { "iron_ring", 2, 4, 1 } }, gold = 4 },
	ruin_spirit = { name = "Esprit des ruines", form = "spectre", look = { "Y", "PC" }, hp = 150, dmg = 20, speed = 13, level = 5, style = "spore", radius = 1.2, night = true, proj = { color = Color3.fromRGB(200, 200, 230), size = 0.8 },
		loot = { { "relic_fragment", 1, 1, 0.5 } }, gold = 2 },
	possessed_shade = { name = "Ombre possédée", form = "spectre", look = { "N", "R" }, hp = 170, dmg = 24, speed = 14, level = 6, style = "charge", radius = 1.3, night = true, fearsLight = true,
		loot = { { "bone", 1, 2, 0.5 } }, gold = 2 },
	forgotten_knight = { name = "Chevalier oublié", form = "humain", look = { "P", "PC", weapon = "epee", helmet = true }, hp = 360, dmg = 32, speed = 11, level = 8, style = "charge", radius = 1.5, night = true, elite = true,
		loot = { { "steel", 1, 2, 0.6 } }, gold = 5 },
	cave_bat = { name = "Chauve-souris des cavernes", form = "volant", look = { "N", "R", chauvesouris = true }, hp = 50, dmg = 10, speed = 16, level = 2, style = "charge", radius = 1.1, flies = true, night = true,
		loot = { { "bone", 1, 1, 0.3 } } },
	griffin = { name = "Griffon", form = "volant", look = { "O", "BF" }, hp = 320, dmg = 30, speed = 16, level = 7, style = "charge", radius = 1.8, flies = true, elite = true,
		loot = { { "feather", 3, 6, 1 }, { "claw", 1, 2, 0.8 } }, gold = 4 },
	hippogriff = { name = "Hippogriffe", form = "volant", look = { "W", "BC" }, hp = 260, dmg = 26, speed = 16, level = 6, style = "charge", radius = 1.7, flies = true, neutral = true,
		loot = { { "feather", 2, 5, 1 } }, gold = 3 },
	wyvern = { name = "Wyverne", form = "volant", look = { "V", "BF" }, hp = 340, dmg = 32, speed = 15, level = 7, style = "spore", radius = 1.8, flies = true, elite = true, proj = { color = Color3.fromRGB(200, 200, 230), size = 0.8 },
		loot = { { "raw_hide", 1, 2, 0.8 } }, gold = 4 },
	mountain_eagle = { name = "Aigle des montagnes", form = "volant", look = { "BF", "Y" }, hp = 130, dmg = 18, speed = 17, level = 4, style = "charge", radius = 1.4, flies = true,
		loot = { { "feather", 2, 4, 1 } } },
	spectral_owl = { name = "Chouette spectrale", form = "volant", look = { "W", "BL" }, hp = 110, dmg = 16, speed = 15, level = 4, style = "charge", radius = 1.3, flies = true, night = true,
		loot = { { "feather", 1, 3, 1 } } },
	bramble_fairy = { name = "Fée des ronces", form = "volant", look = { "V", "VI", essaim = true }, hp = 80, dmg = 14, speed = 15, level = 4, style = "spore", radius = 1, flies = true, proj = { color = Color3.fromRGB(200, 200, 230), size = 0.8 },
		loot = { { "flower", 1, 2, 0.8 } }, gold = 1 },
	giant_mantis = { name = "Mante religieuse géante", form = "insecte", look = { "V", "Y" }, hp = 210, dmg = 26, speed = 15, level = 5, style = "charge", radius = 1.5,
		loot = { { "silk", 1, 1, 0.3 } }, gold = 1 },
	drakeling = { name = "Dragonnet", form = "quadrupede", look = { "R", "O", tete = 1.1, queue = true, plat = true }, hp = 240, dmg = 26, speed = 14, level = 6, style = "spore", radius = 1.5, elite = true, proj = { color = Color3.fromRGB(200, 200, 230), size = 0.8 },
		loot = { { "raw_hide", 1, 2, 0.8 } }, gold = 4 },
	cliff_raptor = { name = "Rapace des falaises", form = "volant", look = { "P", "BF" }, hp = 140, dmg = 18, speed = 17, level = 4, style = "charge", radius = 1.4, flies = true,
		loot = { { "feather", 2, 3, 1 } } },
	river_serpent = { name = "Serpent des rivières", form = "serpent", look = { "BL", "W", long = true }, hp = 130, dmg = 18, speed = 13, level = 4, style = "charge", radius = 1,
		loot = { { "raw_hide", 1, 1, 0.5 } } },
	monster_eel = { name = "Anguille monstrueuse", form = "serpent", look = { "N", "Y", long = true, scale = 1.3 }, hp = 200, dmg = 24, speed = 14, level = 5, style = "charge", radius = 1.3,
		loot = { { "fish_1", 1, 2, 0.6 } }, gold = 1 },
	ancient_turtle = { name = "Tortue ancienne", form = "quadrupede", look = { "V", "BF", tete = 1, plat = true, gros = true }, hp = 520, dmg = 22, speed = 6, level = 6, style = "charge", radius = 2.2, neutral = true, elite = true,
		loot = { { "fossil_bone", 1, 1, 0.3 } }, gold = 3 },
	giant_crab = { name = "Crabe géant", form = "insecte", look = { "R", "O", carapace = true }, hp = 240, dmg = 22, speed = 9, level = 5, style = "charge", radius = 1.6,
		loot = { { "fish_1", 1, 2, 0.5 } }, gold = 1 },
	hostile_siren = { name = "Sirène hostile", form = "spectre", look = { "BL", "V" }, hp = 180, dmg = 22, speed = 12, level = 6, style = "spore", radius = 1.3, proj = { color = Color3.fromRGB(200, 200, 230), size = 0.8 },
		loot = { { "relic_fragment", 1, 1, 0.3 } }, gold = 3 },
	-- 19/11 (« listes ennemi.txt », reste) : assassin, roi déchu, méduse des marais, esprit de l'orage
	-- (ce dernier n'apparaît que pendant un orage : Evenements « orage »)
	storm_wraith = { name = "Esprit de l'orage", form = "spectre", look = { "BL", "W", scale = 1.3 }, hp = 420, dmg = 32, speed = 16, level = 7, style = "charge", radius = 1.6, elite = true,
		loot = { { "glowstone", 1, 2, 0.8 }, { "ancient_crystal", 1, 1, 0.25 } }, gold = 6 },
	assassin = { name = "Assassin de l'ombre", form = "humain", look = { "N", "N", weapon = "epee", hood = true }, hp = 200, dmg = 34, speed = 17, level = 6, style = "charge", radius = 1.2, night = true,
		loot = { { "coin_purse", 1, 1, 0.5 }, { "lockpick", 1, 2, 0.4 } }, gold = 4 },
	fallen_king = { name = "Roi déchu", form = "spectre", look = { "PC", "BL", weapon = "epee", helmet = true, scale = 1.4 }, hp = 900, dmg = 40, speed = 11, level = 9, style = "charge", radius = 1.8, night = true, elite = true,
		loot = { { "ancient_jewel", 1, 1, 0.5 }, { "royal_seal", 1, 1, 0.2 }, { "ancient_coin", 2, 5, 1 } }, gold = 10 },
	freshwater_jellyfish = { name = "Méduse des marais", form = "masse", look = { "BL", "W" }, hp = 80, dmg = 14, speed = 8, level = 3, style = "spore", radius = 1,
		loot = { { "fish_1", 1, 1, 0.3 } }, gold = 1 },
	water_spirit = { name = "Esprit des eaux", form = "spectre", look = { "BL", "W" }, hp = 150, dmg = 18, speed = 13, level = 5, style = "charge", radius = 1.2, night = true,
		loot = { { "fish_1", 1, 1, 0.4 } }, gold = 1 },
	kelpie = { name = "Kelpie", form = "quadrupede", look = { "N", "BL", tete = 1.2, criniere = "V" }, hp = 260, dmg = 26, speed = 17, level = 6, style = "charge", radius = 1.6, neutral = true,
		loot = { { "raw_hide", 1, 2, 0.7 } }, gold = 2 },
	lake_guardian = { name = "Gardien du lac", form = "golem", look = { "BL", "V" }, hp = 520, dmg = 30, speed = 8, level = 7, style = "charge", radius = 2.2, elite = true,
		loot = { { "clay", 3, 6, 1 } }, gold = 4 },
	forest_giant = { name = "Géant des forêts", form = "humain", look = { "BF", "V", weapon = "massue", scale = 2.2, peau = "BF" }, hp = 820, dmg = 40, speed = 9, level = 8, style = "charge", radius = 2.6, elite = true, neutral = true,
		loot = { { "wood", 6, 10, 1 } }, gold = 5 },
	mountain_troll = { name = "Troll des montagnes", form = "humain", look = { "P", "N", weapon = "massue", scale = 1.9, peau = "P" }, hp = 720, dmg = 38, speed = 9, level = 8, style = "charge", radius = 2.4, elite = true,
		loot = { { "stone", 4, 8, 1 } }, gold = 5 },
	earth_colossus = { name = "Colosse de terre", form = "golem", look = { "BF", "B" }, hp = 680, dmg = 34, speed = 7, level = 8, style = "charge", radius = 2.6, elite = true,
		loot = { { "clay", 4, 8, 1 } }, gold = 4 },
	granite_warden = { name = "Gardien de granit", form = "golem", look = { "P", "W" }, hp = 720, dmg = 36, speed = 7, level = 8, style = "charge", radius = 2.6, elite = true, neutral = true,
		loot = { { "stone", 6, 10, 1 } }, gold = 5 },
	bull_man = { name = "Homme-taureau", form = "humain", look = { "BF", "N", weapon = "hache", scale = 1.6, cornes = true, peau = "BF" }, hp = 600, dmg = 36, speed = 12, level = 7, style = "charge", radius = 2.2, elite = true,
		loot = { { "raw_hide", 2, 3, 1 } }, gold = 4 },
	ruin_giant = { name = "Géant des ruines", form = "humain", look = { "Y", "PC", weapon = "massue", scale = 2.3, peau = "Y" }, hp = 860, dmg = 40, speed = 8, level = 9, style = "charge", radius = 2.8, elite = true,
		loot = { { "relic_fragment", 1, 3, 0.8 } }, gold = 6 },
	night_stalker = { name = "Chasseur nocturne", form = "humain", look = { "V", "N", weapon = "arc", hood = true }, hp = 180, dmg = 20, speed = 14, level = 5, style = "spore", radius = 1.3, night = true, proj = { color = Color3.fromRGB(200, 200, 230), size = 0.8 },
		loot = { { "deer_hide", 1, 1, 0.5 } }, gold = 2 },
	woods_spirit = { name = "Esprit des bois", form = "spectre", look = { "V", "Y" }, hp = 140, dmg = 18, speed = 13, level = 5, style = "charge", radius = 1.2, night = true, fearsLight = true,
		loot = { { "resin", 1, 2, 0.6 } }, gold = 1 },
	-- nouveaux boss itinérants (18/11) : butin rare = leur âme (Shared/Prises) + pièces d'équipement
	snow_wyvern = { name = "Wyverne des neiges", form = "volant", look = { "W", "BL", scale = 2.6 }, hp = 2400, dmg = 50, speed = 15, level = 10, style = "spore", radius = 3.4, boss = true, flies = true, minion = "frost_spider",
		proj = { color = Color3.fromRGB(190, 230, 255), size = 2 }, loot = { { "ice_crystal", 2, 4, 1 }, { "feather", 4, 8, 1 } }, gold = 9 },
	mountain_giant = { name = "Géant des montagnes", form = "humain", look = { "P", "BF", weapon = "massue", scale = 2.8, peau = "P" }, hp = 3000, dmg = 56, speed = 9, level = 10, style = "charge", radius = 3.8, boss = true, minion = "cave_troll",
		loot = { { "stone", 10, 20, 1 }, { "gold_ore", 2, 4, 1 } }, gold = 10 },
	deep_beast = { name = "Bête des profondeurs", form = "serpent", look = { "N", "V", long = true, scale = 2.6 }, hp = 2600, dmg = 52, speed = 12, level = 10, style = "charge", radius = 3.6, boss = true, minion = "water_snake",
		loot = { { "raw_hide", 4, 6, 1 }, { "tooth", 3, 5, 1 } }, gold = 9 },
	cave_troll = { name = "Troll des cavernes", form = "humain", look = { "P", "BF", weapon = "massue", scale = 1.8, peau = "P" }, hp = 700, dmg = 38, speed = 9, level = 8, style = "charge", radius = 2.4, elite = true,
		loot = { { "stone", 4, 8, 1 }, { "ore", 1, 3, 0.6 } }, gold = 5 },
	-- 20/11 : les trois dernières de « listes ennemi.txt », modèles faits par Codex (ServerStorage.Modeles)
	highway_rider = { name = "Brigand à cheval", form = "humain", model = "Cavalier", look = { "R", "BF", weapon = "epee" }, hp = 230, dmg = 22, speed = 21, level = 6,
		style = "charge", radius = 1.8, loot = { { "copper_coin", 3, 8, 1 }, { "leather", 1, 2, 0.5 }, { "coin_purse", 1, 1, 0.2 } }, gold = 2 },
	giant_pike = { name = "Brochet géant", form = "serpent", model = "Poisson_Carnassier", look = { "V", "BL", long = true }, hp = 170, dmg = 20, speed = 12, level = 5,
		style = "charge", radius = 1.4, loot = { { "fish_5", 1, 2, 0.8 }, { "raw_hide", 1, 1, 0.3 } } },
	sea_serpent = { name = "Serpent marin", form = "serpent", model = "Serpent_Marin", look = { "BL", "V", long = true, scale = 1.5 }, hp = 380, dmg = 28, speed = 14, level = 7,
		style = "charge", radius = 1.9, elite = true, loot = { { "fish_3", 1, 3, 0.7 }, { "relic_fragment", 1, 1, 0.15 } }, gold = 2 },
}
Bestiaire.KINDS = KINDS

-- Où vit quoi (en plus des créatures d'origine). Poids : plus il y a d'entrées, plus c'est courant.
local DAY = {
	prairie = { "bandit", "bandit", "wild_dog", "snake", "bee_swarm", "poacher", "deserter", "highwayman", "pillager", "marauder", "fake_merchant", "corrupt_guard", "stray_dog", "rabid_fox", "mercenary", "bounty_hunter", "mountain_eagle", "cliff_raptor", "bull_man", "ruin_giant" , "highway_rider" },
	foret = { "black_wolf", "lynx", "goblin_archer", "goblin_archer", "bramble_witch", "wood_golem", "root_troll", "bee_swarm", "poacher", "wood_goblin", "sylvan_spider", "brown_bear", "colossal_boar", "corrupted_ent", "renegade_guard", "harpy", "griffin", "hippogriff", "bramble_fairy", "giant_mantis", "forest_giant" , "giant_pike" },
	desert = { "jackal", "jackal", "dune_snake", "beetle", "desert_spider", "hyena", "sandstone_golem", "ruin_looter", "desert_raider", "sand_worm", "ruin_guardian", "sand_basilisk", "smuggler", "drakeling", "wyvern" , "highway_rider" },
	neige = { "polar_bear", "frost_boar", "frost_spider", "frost_spider", "frost_troll", "black_wolf", "polar_wolf", "ice_giant", "corrupted_stag", "giant_eagle", "mountain_troll", "granite_warden", "cliff_raptor" },
	marais = { "freshwater_jellyfish", "leech", "leech", "bog_lizard", "swamp_boar", "mud_man", "water_snake", "swamp_goblin", "reed_spider", "mud_golem", "smuggler", "river_serpent", "monster_eel", "ancient_turtle", "giant_crab", "hostile_siren", "kelpie", "lake_guardian", "earth_colossus" , "giant_pike", "sea_serpent" },
}
local NIGHT = {
	prairie = { "assassin", "fallen_king", "creeping_shadow", "creeping_shadow", "faceless_walker", "revenant", "giant_crow", "ghost_knight", "shadow_wolf", "faceless_walker", "ghost_crow", "creeping_shadow", "fallen_monk", "dark_prowler", "wandering_spectre", "night_howler", "tomb_warden", "forgotten_knight" },
	foret = { "assassin", "creeping_shadow", "faceless_walker", "spectral_stag", "giant_crow", "revenant", "tree_spirit", "shadow_wolf", "ruin_spirit", "ghost_crow", "moon_hunter", "night_stalker", "woods_spirit", "spectral_owl" },
	desert = { "fallen_king", "creeping_shadow", "dune_spectre", "dune_spectre", "faceless_walker", "mummy", "ruin_spirit", "creeping_shadow", "ruin_spirit", "cursed_warden", "light_eater" },
	neige = { "blizzard_spectre", "creeping_shadow", "revenant", "spectral_fox", "faceless_walker", "possessed_shade", "night_howler" },
	marais = { "swamp_witch", "drowned_spirit", "drowned_spirit", "faceless_walker", "creeping_shadow", "fallen_monk", "water_spirit", "possessed_shade" },
}
local RARE = { prairie = "cyclops", foret = "ogre", desert = "minotaur", neige = "cave_bear", marais = "ogre" }
Bestiaire.DAY, Bestiaire.NIGHT, Bestiaire.RARE = DAY, NIGHT, RARE -- lus par le banc de référence

-- Faune propre à l'île (générateur ≥ 2) : chaque espèce d'un biome a ~30 % de chances d'être ABSENTE
-- de l'île (au moins 2 espèces restent), et une espèce « signature », tirée parmi les biomes de l'île,
-- y est 3 fois plus fréquente. Deux îles du même biome n'ont donc pas les mêmes créatures.
local islandCache = {}
function Bestiaire.islandPool(seed: number, theme, list, biome: string)
	if not theme or not list then
		return list
	end
	local key = seed .. ":" .. biome .. ":" .. tostring(list)
	if islandCache[key] then
		return islandCache[key]
	end
	local kept, seen = {}, {}
	for _, kind in list do
		if not seen[kind] then
			seen[kind] = (G.WG.hash(seed, "faune", kind) % 100) >= 30
		end
		if seen[kind] then
			table.insert(kept, kind)
		end
	end
	local distinct = {}
	for _, kind in kept do
		distinct[kind] = true
	end
	local n = 0
	for _ in distinct do
		n += 1
	end
	if n < 2 then
		kept = table.clone(list)
	end
	-- signature de l'île : une espèce de jour d'un de ses biomes, pondérée ×3 là où elle vit
	local sig = Bestiaire.signature(seed, theme)
	if sig and table.find(list, sig) then
		for _ = 1, 2 do
			table.insert(kept, sig)
		end
	end
	islandCache[key] = kept
	return kept
end

function Bestiaire.signature(seed: number, theme): string?
	if not theme then
		return nil
	end
	local all = {}
	for b in theme.biomes do
		for _, kind in DAY[b] or {} do
			if not table.find(all, kind) then
				table.insert(all, kind)
			end
		end
	end
	table.sort(all)
	if #all == 0 then
		return nil
	end
	return all[G.WG.hash(seed, "signature") % #all + 1]
end
Bestiaire.CAVE = {
	prairie = { "giant_bat", "cave_spider", "cave_troll", "slime_blue", "stone_golem" },
	foret = { "giant_bat", "cave_spider", "cave_spider", "myconid", "cave_bear", "cave_bat" },
	desert = { "giant_bat", "desert_spider", "beetle", "cave_troll", "stone_golem" },
	neige = { "giant_bat", "frost_spider", "ice_golem", "cave_bear" },
	marais = { "giant_bat", "leech", "mud_man", "drowned_spirit" },
}
Bestiaire.GUARDIAN = { prairie = "crownless_king", foret = "vargor", desert = "royal_scarab", neige = "brumeglace", marais = "marsh_king" }
-- boss itinérants supplémentaires (Evenements)
Bestiaire.ROAMING = {
	vargor = { name = "Vargor, le Roi des loups", biome = { "foret" } },
	bramble_mother = { name = "Mère des Ronces", biome = { "foret" } },
	marsh_king = { name = "Roi des marais", biome = { "marais" } },
	royal_scarab = { name = "Scarabée royal", biome = { "desert" } },
	brumeglace = { name = "Brumeglace", biome = { "neige" } },
	crownless_king = { name = "Le Roi sans couronne", biome = { "prairie" }, night = true },
	snow_wyvern = { name = "Wyverne des neiges", biome = { "neige" } },
	mountain_giant = { name = "Géant des montagnes", biome = { "prairie", "neige" } },
	deep_beast = { name = "Bête des profondeurs", biome = { "marais" } },
}

-- ----------------------------------------------------------------- Modèles

local C = {
	B = Color3.fromRGB(150, 104, 64), BF = Color3.fromRGB(78, 54, 38), BC = Color3.fromRGB(196, 156, 104),
	P = Color3.fromRGB(120, 120, 126), PC = Color3.fromRGB(176, 172, 162), F = Color3.fromRGB(80, 80, 86),
	O = Color3.fromRGB(226, 182, 64), R = Color3.fromRGB(150, 44, 40), BL = Color3.fromRGB(60, 96, 170),
	V = Color3.fromRGB(76, 120, 60), W = Color3.fromRGB(236, 232, 222), T = Color3.fromRGB(190, 100, 60),
	N = Color3.fromRGB(34, 32, 36), Y = Color3.fromRGB(206, 170, 96), VI = Color3.fromRGB(96, 56, 130),
}
local SKIN = Color3.fromRGB(226, 182, 150)
local Mat = Enum.Material

local function P(m, size, pos, color, mat, shape, rot)
	local p
	if shape == "wedge" then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
		if shape == "ball" then
			p.Shape = Enum.PartType.Ball
		elseif shape == "cyl" then
			p.Shape = Enum.PartType.Cylinder
		end
	end
	p.Size = size
	p.CFrame = CFrame.new(pos) * (rot or CFrame.identity)
	p.Color = color
	p.Material = mat or Mat.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end
local function V(x, y, z)
	return Vector3.new(x, y, z)
end
local function eyes(m, x, y, z, color, size)
	local s = size or 0.24
	for _, sx in { -1, 1 } do
		P(m, V(s, s, 0.1), V(sx * x, y, z), color or C.N, color and Mat.Neon or Mat.SmoothPlastic)
	end
end

local function weapon(m, kind, hand: Vector3, s)
	if kind == "epee" then
		P(m, V(0.2 * s, 2.6 * s, 0.4 * s), hand + V(0, 0.9 * s, -0.4 * s), C.PC, Mat.Metal, nil, CFrame.Angles(math.rad(-30), 0, 0))
		P(m, V(0.9 * s, 0.2 * s, 0.25 * s), hand + V(0, -0.1 * s, 0), C.F, Mat.Metal)
	elseif kind == "hache" then
		P(m, V(0.25 * s, 3 * s, 0.25 * s), hand + V(0, 0.6 * s, -0.3 * s), C.BF, Mat.Wood, nil, CFrame.Angles(math.rad(-25), 0, 0))
		P(m, V(0.2 * s, 1.1 * s, 1 * s), hand + V(0, 1.8 * s, -0.95 * s), C.PC, Mat.Metal, nil, CFrame.Angles(math.rad(-25), 0, 0))
	elseif kind == "lance" then
		P(m, V(0.2 * s, 5 * s, 0.2 * s), hand + V(0, 1 * s, 0), C.B, Mat.Wood)
		P(m, V(0.3 * s, 0.8 * s, 0.3 * s), hand + V(0, 3.8 * s, 0), C.PC, Mat.Metal, "wedge")
	elseif kind == "arc" then
		P(m, V(0.15 * s, 3 * s, 0.15 * s), hand + V(0, 0.3 * s, -0.3 * s), C.BF, Mat.Wood)
		P(m, V(0.05, 2.8 * s, 0.05), hand + V(0, 0.3 * s, -0.05 * s), C.W, Mat.Fabric)
	elseif kind == "dague" then
		P(m, V(0.15 * s, 1 * s, 0.3 * s), hand + V(0, 0.5 * s, -0.2 * s), C.PC, Mat.Metal)
	elseif kind == "massue" then
		P(m, V(0.5 * s, 3 * s, 0.5 * s), hand + V(0, 0.8 * s, -0.4 * s), C.BF, Mat.Wood, nil, CFrame.Angles(math.rad(-30), 0, 0))
		P(m, V(1.1 * s, 1.1 * s, 1.1 * s), hand + V(0, 2.2 * s, -1.2 * s), C.B, Mat.Wood, "ball")
	elseif kind == "baton" then
		P(m, V(0.2 * s, 4.4 * s, 0.2 * s), hand + V(0, 1 * s, 0), C.BF, Mat.Wood)
		P(m, V(0.6 * s, 0.6 * s, 0.6 * s), hand + V(0, 3.3 * s, 0), C.V, Mat.Neon, "ball")
	end
end

local FORMES = {}

-- Humanoïde : bandits, soldats, gobelins, trolls, ogres, squelettes…
FORMES.humain = function(m, o)
	local s = (o.scale or 1) * (o.petit and 0.75 or 1)
	local cloth, dark = C[o[1]] or C.R, C[o[2]] or C.BF
	local skin = o.squelette and C.W or (o.peau and C[o.peau] or SKIN)
	local mat = o.squelette and Mat.SmoothPlastic or (o.pierre and Mat.Slate or Mat.Fabric)
	local legH, torso = 2.2 * s, V(2 * s, 2.2 * s, 1.1 * s)
	local lean = o.courbe and CFrame.Angles(math.rad(-18), 0, 0) or CFrame.identity
	for _, sx in { -1, 1 } do
		P(m, V(0.8 * s, legH, 0.85 * s), V(sx * 0.5 * s, legH / 2, 0), o.squelette and skin or dark, mat)
	end
	local ty = legH + torso.Y / 2
	local body = P(m, torso + (o.ventre and V(0.6 * s, 0, 0.8 * s) or V(0, 0, 0)), V(0, ty, 0), o.squelette and skin or cloth, mat, nil, lean)
	if o.squelette then
		for i = 0, 2 do
			P(m, V(torso.X + 0.05, 0.18 * s, torso.Z + 0.05), V(0, ty - 0.6 * s + i * 0.6 * s, 0), C.N, Mat.SmoothPlastic)
		end
	end
	P(m, V(torso.X + 0.1, 0.3 * s, torso.Z + 0.1), V(0, legH + 0.2 * s, 0), C.BF, Mat.Fabric)
	local hand
	for _, sx in { -1, 1 } do
		local arm = P(m, V(0.7 * s, 2.1 * s, 0.75 * s), V(sx * (torso.X / 2 + 0.38 * s), ty - 0.1 * s, -0.1 * s), o.squelette and skin or cloth, mat, nil, CFrame.Angles(math.rad(-12), 0, 0))
		if sx == 1 then
			hand = arm.Position - V(0, 1.1 * s, 0.25 * s)
		end
	end
	local hy = legH + torso.Y + 0.65 * s
	local hz = o.courbe and -0.5 * s or 0
	P(m, V(1.2 * s, 1.25 * s, 1.15 * s), V(0, hy, hz), skin, o.squelette and Mat.SmoothPlastic or Mat.SmoothPlastic)
	eyes(m, 0.28 * s, hy + 0.1 * s, hz - 0.6 * s, (o.squelette or o.peau) and Color3.fromRGB(255, 80, 60) or nil, 0.2 * s)
	if o.hood then
		P(m, V(1.45 * s, 1.1 * s, 1.35 * s), V(0, hy + 0.3 * s, hz + 0.12 * s), dark, Mat.Fabric)
	end
	if o.helmet then
		P(m, V(1.35 * s, 0.9 * s, 1.3 * s), V(0, hy + 0.35 * s, hz), C.F, Mat.Metal)
		P(m, V(0.2 * s, 0.9 * s, 0.1 * s), V(0, hy, hz - 0.65 * s), C.F, Mat.Metal)
	end
	if o.cornes then
		for _, sx in { -1, 1 } do
			P(m, V(0.3 * s, 1.2 * s, 0.3 * s), V(sx * 0.75 * s, hy + 0.7 * s, hz), C.W, Mat.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(-sx * 35)))
		end
	end
	if o.cape then
		P(m, V(torso.X, torso.Y + legH * 0.6, 0.15 * s), V(0, ty - legH * 0.3, torso.Z / 2 + 0.1), C[o.cape], Mat.Fabric)
	end
	if o.weapon and hand then
		weapon(m, o.weapon, hand, s)
	end
	return body
end

-- Quadrupède : loups, ours, lynx, chacals, sangliers, lézards, cerf spectral, Vargor
FORMES.quadrupede = function(m, o)
	local s = (o.scale or 1) * (o.petit and 0.75 or 1) * (o.gros and 1.35 or 1)
	local col, col2 = C[o[1]] or C.B, C[o[2]] or C.BF
	local mat = o.spectre and Mat.Neon or Mat.SmoothPlastic
	local legH = (o.plat and 0.6 or 1.3) * s
	local body = V(1.6 * s, (o.plat and 0.9 or 1.4) * s, 3.4 * s)
	local by = legH + body.Y / 2
	local b = P(m, body, V(0, by, 0), col, mat)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			P(m, V(0.45 * s, legH + 0.2, 0.45 * s), V(sx * (body.X / 2 - 0.25 * s), legH / 2, sz * (body.Z / 2 - 0.4 * s)), col2, mat)
		end
	end
	local ts = (o.tete or 1) * s
	local hy, hz = by + body.Y * 0.35, -(body.Z / 2 + 0.45 * ts)
	P(m, V(1.1 * ts, 1 * ts, 1.1 * ts), V(0, hy, hz), col, mat)
	P(m, V(0.6 * ts, 0.5 * ts, 0.6 * ts), V(0, hy - 0.2 * ts, hz - 0.8 * ts), col2, mat)
	eyes(m, 0.3 * ts, hy + 0.15 * ts, hz - 0.56 * ts, (o.spectre or o.scale) and Color3.fromRGB(255, 200, 80) or nil, 0.2 * ts)
	if o.oreilles then
		for _, sx in { -1, 1 } do
			P(m, V(0.3 * ts, 0.5 * ts, 0.2 * ts), V(sx * 0.35 * ts, hy + 0.7 * ts, hz + 0.1), col2, mat, "wedge")
		end
	end
	if o.queue then
		P(m, V(0.35 * s, 0.35 * s, 1.4 * s), V(0, by + 0.2 * s, body.Z / 2 + 0.6 * s), col, mat, nil, CFrame.Angles(math.rad(25), 0, 0))
	end
	if o.defenses then
		for _, sx in { -1, 1 } do
			P(m, V(0.15 * s, 0.5 * s, 0.15 * s), V(sx * 0.4 * ts, hy - 0.3 * ts, hz - 0.9 * ts), C.W, Mat.SmoothPlastic, nil, CFrame.Angles(math.rad(-30), 0, 0))
		end
	end
	if o.bois then
		for _, sx in { -1, 1 } do
			P(m, V(0.15 * s, 1.6 * s, 0.15 * s), V(sx * 0.4 * ts, hy + 1.1 * ts, hz), C.W, mat, nil, CFrame.Angles(0, 0, math.rad(-sx * 25)))
			P(m, V(0.12 * s, 0.8 * s, 0.12 * s), V(sx * 0.75 * ts, hy + 1.5 * ts, hz - 0.2), C.W, mat, nil, CFrame.Angles(math.rad(-30), 0, math.rad(-sx * 50)))
		end
	end
	if o.criniere then
		P(m, V(body.X + 0.3, body.Y * 0.8, 1.4 * s), V(0, by + 0.2 * s, -body.Z / 2 + 0.6 * s), C[o.criniere], Mat.Fabric)
	end
	if o.spectre then
		b.Transparency = 0.35
		for _, p in m:GetChildren() do
			if p:IsA("BasePart") then
				p.Transparency = math.max(p.Transparency, 0.35)
			end
		end
	end
	return b
end

-- Insectes : scarabées, araignées
FORMES.insecte = function(m, o)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.N, C[o[2]] or C.R
	local shell = P(m, V(2.4 * s, 1.4 * s, 3 * s), V(0, 1.5 * s, 0.4 * s), col, o.carapace and Mat.Metal or Mat.Fabric, "ball")
	if o.carapace then
		shell.Reflectance = 0.15
		P(m, V(0.1 * s, 1.2 * s, 2.8 * s), V(0, 1.9 * s, 0.4 * s), col2, Mat.SmoothPlastic)
	end
	P(m, V(1.4 * s, 1 * s, 1.2 * s), V(0, 1.2 * s, -1.5 * s), col2, Mat.SmoothPlastic)
	eyes(m, 0.3 * s, 1.4 * s, -2.12 * s, Color3.fromRGB(255, 60, 60), 0.2 * s)
	local n = o.pattes8 and 4 or 3
	for i = 1, n do
		local z = -1 + (i - 1) * (2.4 / (n - 1)) * s
		for _, sx in { -1, 1 } do
			P(m, V(1.8 * s, 0.2 * s, 0.2 * s), V(sx * 1.6 * s, 1.1 * s, z), col2, Mat.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(sx * 30)))
			P(m, V(0.2 * s, 1.2 * s, 0.2 * s), V(sx * 2.4 * s, 0.5 * s, z), col2, Mat.SmoothPlastic)
		end
	end
	if o.carapace then
		P(m, V(0.25 * s, 1.2 * s, 0.25 * s), V(0, 1.9 * s, -2.1 * s), col2, Mat.SmoothPlastic, nil, CFrame.Angles(math.rad(-35), 0, 0))
	end
	return shell
end

-- Serpents : anneaux qui ondulent au sol
FORMES.serpent = function(m, o)
	local col, col2 = C[o[1]] or C.V, C[o[2]] or C.Y
	local n = o.long and 9 or 6
	local first
	for i = 0, n - 1 do
		local sz = 0.9 - i * 0.05
		local p = P(m, V(sz, sz, sz), V(math.sin(i * 0.9) * 0.6, sz / 2, i * 0.75), i % 2 == 0 and col or col2, Mat.SmoothPlastic, "ball")
		first = first or p
	end
	P(m, V(0.9, 0.6, 1.1), V(0, 0.45, -0.6), col, Mat.SmoothPlastic)
	eyes(m, 0.25, 0.6, -1.16, Color3.fromRGB(255, 220, 60), 0.14)
	P(m, V(0.08, 0.05, 0.4), V(0, 0.3, -1.3), C.R, Mat.Neon)
	return first
end

-- Volants : chauves-souris, corbeaux, essaims, gargouilles (ils planent à hauteur d'homme)
FORMES.volant = function(m, o)
	local col, col2 = C[o[1]] or C.N, C[o[2]] or C.N
	local y = 3.5
	if o.essaim then
		local core
		for _ = 1, 14 do
			local p = P(m, V(0.35, 0.3, 0.45), V(math.random() * 2.4 - 1.2, y + math.random() * 1.6 - 0.8, math.random() * 2.4 - 1.2), math.random() < 0.5 and col or col2, Mat.SmoothPlastic, "ball")
			core = core or p
		end
		return core
	end
	local gar = o.gargouille
	local body = P(m, V(gar and 1.6 or 1, gar and 1.8 or 1, gar and 2 or 1.4), V(0, y, 0), col, gar and Mat.Slate or Mat.Fabric)
	P(m, V(gar and 1.2 or 0.8, gar and 1.1 or 0.8, gar and 1.1 or 0.8), V(0, y + (gar and 1.2 or 0.6), -0.6), col, gar and Mat.Slate or Mat.Fabric)
	eyes(m, 0.22, y + (gar and 1.3 or 0.7), gar and -1.18 or -1.02, Color3.fromRGB(255, 70, 50), 0.16)
	if not o.chauvesouris and not gar then
		P(m, V(0.25, 0.25, 0.6), V(0, y + 0.5, -1.25), C.Y, Mat.SmoothPlastic, "wedge", CFrame.Angles(0, math.pi, 0))
	end
	for _, sx in { -1, 1 } do
		P(m, V(gar and 3 or 2.6, 0.12, gar and 1.8 or 1.3), V(sx * (gar and 2 or 1.6), y + 0.3, 0.1), col2, gar and Mat.Slate or Mat.Fabric, nil, CFrame.Angles(0, 0, math.rad(sx * 18)))
	end
	if gar then
		for _, sx in { -1, 1 } do
			P(m, V(0.25, 0.8, 0.25), V(sx * 0.4, y + 2, -0.5), col2, Mat.Slate, nil, CFrame.Angles(math.rad(20), 0, 0))
		end
	end
	return body
end

-- Golems : blocs de pierre, de bois, de grès ; la Mère des Ronces
FORMES.golem = function(m, o)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.P, C[o[2]] or C.O
	local mat = (o[1] == "B" or o[1] == "V") and Mat.Wood or (o[1] == "Y" and Mat.Sandstone or Mat.Slate)
	for _, sx in { -1, 1 } do
		P(m, V(1.2 * s, 2.4 * s, 1.2 * s), V(sx * 0.9 * s, 1.2 * s, 0), col, mat)
	end
	local body = P(m, V(3.4 * s, 3 * s, 2 * s), V(0, 3.9 * s, 0), col, mat)
	P(m, V(1.6 * s, 1.4 * s, 1.4 * s), V(0, 6.1 * s, -0.1 * s), col, mat)
	eyes(m, 0.35 * s, 6.2 * s, -0.82 * s, col2, 0.3 * s)
	P(m, V(0.8 * s, 0.8 * s, 0.1), V(0, 4.2 * s, -1.02 * s), col2, Mat.Neon)
	for _, sx in { -1, 1 } do
		P(m, V(1.1 * s, 3.2 * s, 1.1 * s), V(sx * 2.3 * s, 3.4 * s, 0), col, mat)
	end
	if o.ronces then
		for i = 1, 8 do
			local a = i / 8 * math.pi * 2
			P(m, V(0.25 * s, 2.4 * s, 0.25 * s), V(math.cos(a) * 1.6 * s, 5 * s, math.sin(a) * 1.1 * s), C.R, Mat.Wood, nil, CFrame.Angles(math.sin(a) * 0.8, 0, math.cos(a) * 0.8))
		end
	end
	return body
end

-- Spectres : silhouettes translucides qui flottent
FORMES.spectre = function(m, o)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.W, C[o[2]] or C.BL
	local body = P(m, V(2 * s, 3.4 * s, 1.2 * s), V(0, 3.4 * s, 0), col, Mat.Neon, "wedge", CFrame.Angles(0, math.pi, 0))
	P(m, V(2.2 * s, 2.8 * s, 1.3 * s), V(0, 3.6 * s, 0.1), col2, Mat.ForceField)
	P(m, V(1.3 * s, 1.3 * s, 1.3 * s), V(0, 5.8 * s, 0), col, Mat.Neon, "ball")
	eyes(m, 0.3 * s, 5.85 * s, -0.62 * s, C.N, 0.24 * s)
	if o.couronne then
		for i = 0, 4 do
			P(m, V(0.25 * s, 0.6 * s, 0.25 * s), V(math.cos(i * 1.256) * 0.55 * s, 6.6 * s, math.sin(i * 1.256) * 0.55 * s), C.O, Mat.Metal)
		end
	end
	if o.helmet then
		P(m, V(1.4 * s, 1 * s, 1.4 * s), V(0, 6 * s, 0), C.PC, Mat.Metal)
	end
	if o.weapon then
		weapon(m, o.weapon, V(1.2 * s, 3.2 * s, -0.3 * s), s)
	end
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p.Material == Mat.Neon then
			p.Transparency = 0.45
		end
	end
	return body
end

-- Masses : sangsues, hommes-boue, Roi des marais (ils rampent ou bondissent)
FORMES.masse = function(m, o)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.BF, C[o[2]] or C.Y
	local body
	if o.long then
		for i = 0, 4 do
			local p = P(m, V(1.2, 1, 1.2), V(0, 0.5, i * 0.9), col, Mat.SmoothPlastic, "ball")
			body = body or p
		end
		P(m, V(0.9, 0.9, 0.3), V(0, 0.5, -0.6), col2, Mat.SmoothPlastic, "ball")
	else
		body = P(m, V(2.6 * s, 3.4 * s, 2.4 * s), V(0, 1.7 * s, 0), col, Mat.Mud, "ball")
		P(m, V(1.8 * s, 1.6 * s, 1.8 * s), V(0, 3.5 * s, -0.1 * s), col, Mat.Mud, "ball")
		eyes(m, 0.4 * s, 3.7 * s, -0.86 * s, col2, 0.26 * s)
		for _, sx in { -1, 1 } do
			P(m, V(0.7 * s, 2 * s, 0.7 * s), V(sx * 1.5 * s, 1.8 * s, -0.2 * s), col, Mat.Mud, nil, CFrame.Angles(0, 0, math.rad(sx * 20)))
		end
		if o.couronne then
			for i = 0, 4 do
				P(m, V(0.3 * s, 0.6 * s, 0.3 * s), V(math.cos(i * 1.256) * 0.6 * s, 4.5 * s, math.sin(i * 1.256) * 0.6 * s), C.O, Mat.Metal)
			end
		end
	end
	return body
end

function Bestiaire.build(name: string): Model?
	local id = string.match(name, "^Bete_(.+)$")
	local k = id and KINDS[id]
	if not k then
		return nil
	end
	local m = Instance.new("Model")
	m.Name = name
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(1, 0.2, 1)
	base.Transparency = 1
	base.Anchored = true
	base.CanCollide = false
	base.CanQuery = false
	base.CanTouch = false
	base.Parent = m
	m.PrimaryPart = base
	FORMES[k.form](m, k.look or {})
	return m
end

-- ----------------------------------------------------------------- Installation

-- Butin ramené dans la norme de son niveau (étape 9, banc butin_creatures, 20/11) : la valeur moyenne du
-- butin (prix × quantité × chance + or) PAR POINT DE VIE reste entre 1/3 et 3 fois la médiane des créatures
-- du même niveau. Trop riche : chances (et or) réduites ; trop pauvre : un peu d'or en plus. Les boss, les
-- bêtes passives et les niveaux de moins de 3 créatures ne sont pas touchés. Une seule fois par table.
function Bestiaire.normalizeLoot(kinds, C): number
	-- or d'une mise à mort (Enemies) : random(5, 15) × niveau × (gold ou 1), en moyenne 10 × niveau × gold
	local function value(k)
		local v = math.min(10 * (k.level or 1) * (k.gold or 1), 25 + k.hp * 0.12) -- plafond d'Enemies
		for _, l in k.loot or {} do
			local info = C.ITEMS[l[1]]
			v += info and (l[2] + (l[3] or l[2])) / 2 * (l[4] or 1) * (info.price or 0) or 0
		end
		return v
	end
	local byLevel = {}
	for _, k in kinds do
		if not k.passive and not k.boss and (k.hp or 0) > 0 then
			local lv = k.level or 1
			byLevel[lv] = byLevel[lv] or {}
			table.insert(byLevel[lv], value(k) / k.hp)
		end
	end
	local med = {}
	for lv, list in byLevel do
		if #list >= 3 then
			table.sort(list)
			med[lv] = list[math.floor(#list / 2) + 1]
		end
	end
	local changed = 0
	for _, k in kinds do
		local m = med[k.level or 1]
		if m and m > 0 and not k.passive and not k.boss and not k.lootNormalized and (k.hp or 0) > 0 then
			k.lootNormalized = true
			local v = value(k)
			local perHp = v / k.hp
			if perHp > m * 3 then
				local f = m * 3 * k.hp / v
				local loot = {}
				for _, l in k.loot or {} do
					table.insert(loot, { l[1], l[2], l[3], (l[4] or 1) * f })
				end
				k.loot = loot
				k.gold = math.floor((k.gold or 1) * f) -- entier : l'or gagné reste un nombre entier
				changed += 1
			elseif v > 0 and perHp < m / 3 then
				k.gold = (k.gold or 1) + math.ceil((m / 3 * k.hp - v) / (10 * (k.level or 1)))
				changed += 1
			end
		end
	end
	return changed
end

function Bestiaire.init(g)
	G = g
	Config = G.Config
	local E = G.Enemies.KINDS
	for id, k in KINDS do
		k.model = k.model or ("Bete_" .. id) -- un modèle fait à la main (Modeles) l'emporte
		E[id] = k
	end
	Bestiaire.normalizeLoot(E, Config)
	G.Interact.onPrompt("camp_chest", function(player, prompt)
		Bestiaire.lootCamp(player, prompt)
	end)
end

local function spawnKept(reg, d)
	local st = reg.state.enemies
	local dead = st[d.id]
	if dead and G.world.day < dead + RESPAWN_DAYS then
		return nil
	end
	st[d.id] = nil
	return G.Enemies.spawn(reg, d, reg.enemyFolder)
end

-- Un point libre de la région (pas d'eau, pas de village, pas de route)
local function freeSpot(reg, rng)
	local plan = reg.plan
	local R = Config.REGION
	for _ = 1, 40 do
		local lx, lz = rng:NextInteger(3, R - 4), rng:NextInteger(3, R - 4)
		local i = G.WG.idx(lx, lz)
		if not plan.water[i] and plan.roadD[i] > 3 and plan.poiW[i] < 0.01 then
			local x, z = (plan.x0 + lx) * Config.CELL + Config.CELL / 2, (plan.z0 + lz) * Config.CELL + Config.CELL / 2
			return x, z
		end
	end
	return nil, nil
end

-- Camp de bandits : tentes, feu, butin volé, une bande et son chef
local function buildCamp(reg, rng, x: number, z: number)
	local folder = Instance.new("Model")
	folder.Name = "CampBandits"
	local y = G.Util.groundY(x, z)
	local K = G.Config.Catalogue
	local function put(name, dx, dz, yaw)
		local m = K.build(name)
		if m then
			m:PivotTo(CFrame.new(x + dx, G.Util.groundY(x + dx, z + dz), z + dz) * CFrame.Angles(0, math.rad(yaw or 0), 0))
			m.Parent = folder
		end
		return m
	end
	put("Cat_hearth", 0, 0)
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2 + 0.4
		local tx, tz = math.cos(a) * 9, math.sin(a) * 9
		-- tente : deux pans de toile
		local tent = Instance.new("Model")
		local cf = CFrame.new(x + tx, G.Util.groundY(x + tx, z + tz), z + tz) * CFrame.Angles(0, -a + math.pi / 2, 0)
		local col = ({ Color3.fromRGB(150, 120, 90), Color3.fromRGB(120, 60, 50), Color3.fromRGB(96, 100, 80) })[i + 1]
		for _, sd in { -1, 1 } do
			local p = Instance.new("Part")
			p.Size = Vector3.new(4.4, 0.15, 4.6)
			p.CFrame = cf * CFrame.new(sd * 1.5, 1.9, 0) * CFrame.Angles(0, 0, math.rad(sd * -55))
			p.Color = col
			p.Material = Enum.Material.Fabric
			p.Anchored = true
			p.Parent = tent
		end
		tent.Parent = folder
	end
	put("Cat_crate", 4, -3, 20)
	put("Cat_barrel", -4, 3)
	put("Cat_wall_torch", 6, 4)
	local chest = put("Cat_travel_chest", -3, -5, 35)
	folder.Parent = reg.folder
	local id = "camp" .. reg.key
	if chest then
		local part = chest:FindFirstChildWhichIsA("BasePart")
		for _, pp in chest:GetChildren() do
			if pp:IsA("BasePart") and pp.Size.X > 2.5 then
				part = pp
				break
			end
		end
		local looted = reg.state.camps and reg.state.camps[id]
		local pr = G.Util.prompt(part, "camp_chest", "Fouiller", "Butin des bandits", { dist = 9, hold = 0.8, data = { Camp = id, Region = reg.key } })
		pr.Enabled = not (looted and G.world.day < looted + RESPAWN_DAYS)
	end
	-- la bande
	local crew = { "bandit", "bandit", "bandit", rng:NextNumber() < 0.5 and "poacher" or "deserter" }
	for i, kind in crew do
		local a = i / #crew * math.pi * 2
		spawnKept(reg, { id = id .. "#" .. i, kind = kind, x = x + math.cos(a) * 5, z = z + math.sin(a) * 5 })
	end
	spawnKept(reg, { id = id .. "#chef", kind = "bandit_chief", x = x + 1, z = z - 2 })
	local _ = y
end

function Bestiaire.onRegionLoad(reg)
	if not reg.enemyFolder then
		return
	end
	local plan = reg.plan
	local B = plan.biome
	local rng = Random.new(G.WG.hash(G.world.seed, "bestiaire", reg.rx, reg.rz))
	local dist = math.sqrt(reg.rx * reg.rx + reg.rz * reg.rz)
	if dist < 1.5 then
		return -- autour du départ : on laisse respirer les nouveaux venus
	end
	-- créatures de jour du biome (triées selon l'île)
	local pool = Bestiaire.islandPool(G.world.seed, G.wg and G.wg.theme, DAY[B] or DAY.prairie, B)
	for g = 1, rng:NextInteger(1, dist >= 4 and 3 or 2) do
		local x, z = freeSpot(reg, rng)
		if x then
			local kind = pool[rng:NextInteger(1, #pool)]
			local k = KINDS[kind]
			if k.elite and dist < 3 then
				kind = pool[1]
				k = KINDS[kind]
			end
			for n = 1, k.pack and rng:NextInteger(2, k.pack) or 1 do
				spawnKept(reg, { id = "b" .. reg.key .. "#" .. g .. "#" .. n, kind = kind, x = x + (n - 1) * 3, z = z + (n - 1) * 2 })
			end
		end
	end
	-- une créature rare de temps en temps (ogre, minotaure, ours des cavernes)
	if dist >= 3 and rng:NextNumber() < 0.12 then
		local x, z = freeSpot(reg, rng)
		if x then
			spawnKept(reg, { id = "b" .. reg.key .. "#rare", kind = RARE[B] or "ogre", x = x, z = z })
		end
	end
	-- camp de bandits (loin des villages, pas dans la neige)
	if not plan.poi and B ~= "neige" and dist >= 2 and rng:NextNumber() < CAMP_CHANCE then
		local x, z = freeSpot(reg, rng)
		if x then
			buildCamp(reg, rng, x, z)
		end
	end
end

function Bestiaire.lootCamp(player: Player, prompt: ProximityPrompt)
	local id, key = prompt:GetAttribute("Camp"), prompt:GetAttribute("Region")
	local reg = G.World.loaded[key]
	if not reg or not prompt.Enabled then
		return
	end
	-- la bande garde son butin
	for _, en in reg.enemies or {} do
		if not en.dead and string.sub(en.id, 1, #id) == id then
			local root = G.Util.root(player)
			if root and (en.pos - root.Position).Magnitude < 40 then
				G.Util.toast(player, "Les bandits veillent sur leur butin.")
				return
			end
		end
	end
	prompt.Enabled = false
	reg.state.camps = reg.state.camps or {}
	reg.state.camps[id] = G.world.day
	-- marchandises volées sur les routes (on peut les rendre… ou les revendre)
	local loot = { { "gold", 60, 160 }, { "spice", 1, 3 }, { "cloth", 1, 3 }, { "packed_goods", 1, 1 }, { "salt_sack", 1, 1 },
		{ "iron_ingot", 1, 3 }, { "rations", 1, 2 }, { "lockpick", 1, 3 }, { "treasure_map", 1, 1 } }
	for _ = 1, 4 do
		local l = loot[math.random(1, #loot)]
		G.Joueurs.add(player, l[1], math.random(l[2], l[3]))
	end
	G.Law.addHonor(player, 3)
	G.Joueurs.sync(player)
end

-- Nuit : une créature nocturne du biome (appelé par Enemies.nightStep)
function Bestiaire.nightKind(biome: string): string?
	local pool = NIGHT[biome] and Bestiaire.islandPool(G.world.seed, G.wg and G.wg.theme, NIGHT[biome], biome .. "_nuit")
	if not pool or math.random() < 0.45 then
		return nil -- les épouvantails et les ombres d'origine gardent leur place
	end
	return pool[math.random(1, #pool)]
end

return Bestiaire
