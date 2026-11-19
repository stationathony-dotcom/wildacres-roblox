-- Réglages et tables de données de Wild Acres (portage Roblox du jeu Godot).
-- Tout ce qui se règle (prix, durées, recettes, cultures…) est ici.

local C = {}

-- Monde -----------------------------------------------------------------------
C.CELL = 4 -- studs par case
C.REGION = 48 -- cases par côté de région (192 studs)
C.LOAD_RADIUS = 1 -- régions chargées autour du joueur (3x3)
C.UNLOAD_RADIUS = 2 -- au-delà, la région est déchargée (son état est gardé)
C.WATER_Y = 0 -- surface de l'eau
C.GROUND_Y = 2 -- sol de base
C.LEVEL_H = 12 -- hauteur d'un plateau (falaise infranchissable sans escalier)
C.Y_MIN = -16
C.Y_MAX = 48
C.WORLD_RADIUS = 13 -- île finie : régions au-delà = océan (27 x 27 régions ≈ 5 km de côté)

-- Biomes (remplacent les saisons) : chaque région a son climat, ses arbres, ses cultures.
-- mat = matière du sol, leaves = teinte des feuillages, cliff = roche des falaises.
C.BIOMES = {
	prairie = { name = "Prairie", mat = Enum.Material.Grass, leaves = nil, cliff = Enum.Material.Rock },
	foret = { name = "Forêt rousse", mat = Enum.Material.LeafyGrass, leaves = "automne", cliff = Enum.Material.Rock },
	desert = { name = "Désert", mat = Enum.Material.Sand, leaves = "sec", cliff = Enum.Material.Sandstone },
	neige = { name = "Toundra", mat = Enum.Material.Snow, leaves = "neige", cliff = Enum.Material.Slate },
	marais = { name = "Marais", mat = Enum.Material.Mud, leaves = "marais", cliff = Enum.Material.Rock },
}
C.BIOME_ORDER = { "prairie", "foret", "desert", "neige", "marais" }

-- Multi : mondes persistants (un serveur Roblox réservé par monde)
C.WORLD_CAPACITY = 40 -- au-delà, la liste propose un autre monde (régler aussi « Max Players » à 45 dans Studio)
C.WORLD_FULL_RATIO = 0.8 -- un nouveau monde s'ouvre quand tous sont remplis à 80 %
C.WORLD_NAMES = { "Vallée d'Aube", "Terres de Brume", "Comté des Saules", "Haut-Pays", "Plaine d'Ambre", "Val-Sauvage",
	"Côte des Pins", "Marches de l'Est", "Pays des Lacs", "Combes Rousses", "Grand-Prairie", "Monts Gelés" }

-- Temps ------------------------------------------------------------------------
C.DAY_START = 6 * 60
C.GAME_MIN_PER_SEC = 4 -- une journée de 24 h ≈ 6 min réelles ; le temps ne s'arrête jamais (multi)
C.SLEEP_FROM = 18 -- on peut dormir à partir de 18 h ; si TOUS les joueurs dorment, on saute au matin

-- Joueur -----------------------------------------------------------------------
C.WALK = 16
C.RUN = 24
C.RIDE = 38
C.MAX_STAMINA = 10
C.MAX_HP = 100

-- Objets (icônes = émojis, lisibles sur mobile) ------------------------------
C.ITEMS = {
	gold = { name = "Or", icon = "💰" },
	wood = { name = "Bois", icon = "🌲", price = 2 },
	stone = { name = "Pierre", icon = "⛰️", price = 2 },
	fiber = { name = "Fibre", icon = "🌿", price = 1 },
	berries = { name = "Baies", icon = "🍇", price = 4, food = 8 },
	flower = { name = "Fleur", icon = "🌼", price = 5 },
	mushroom = { name = "Champignon", icon = "🍄", price = 12, food = 12 },
	ore = { name = "Minerai de fer", icon = "⛰️", price = 15 },
	copper_ore = { name = "Minerai de cuivre", icon = "🟠", price = 10 },
	gold_ore = { name = "Minerai d'or", icon = "🟡", price = 45 },
	coal = { name = "Charbon", icon = "⚫", price = 6 },
	clay = { name = "Argile", icon = "🟤", price = 4 },
	-- butin des créatures
	meat = { name = "Viande crue", icon = "🥩", price = 8, food = 4 },
	leather = { name = "Cuir", icon = "🟫", price = 14 },
	fur = { name = "Fourrure", icon = "🦊", price = 18 },
	silk = { name = "Soie d'araignée", icon = "🕸️", price = 12 },
	bone = { name = "Os", icon = "🦴", price = 4 },
	feather = { name = "Plume", icon = "🐦", price = 5 },
	stinger = { name = "Dard de scorpion", icon = "🦂", price = 25 },
	ice_crystal = { name = "Cristal de glace", icon = "🧊", price = 40 },
	wisp_dust = { name = "Poussière de feu follet", icon = "✨", price = 30 },
	slime_gel = { name = "Gelée de slime", icon = "🟢", price = 6 },
	rotten = { name = "Chair pourrie", icon = "🧟", price = 1 },
	honey = { name = "Miel", icon = "🍯", price = 30, food = 15 },
	-- trophées des boss itinérants
	ancient_seed = { name = "Graine ancienne", icon = "🌰", price = 150 },
	enchanted_cloth = { name = "Toile enchantée", icon = "🎐", price = 220 },
	royal_spore = { name = "Spore royale", icon = "🍄", price = 300 },
	glass_shard = { name = "Éclat de verre vivant", icon = "💎", price = 350 },
	frozen_heart = { name = "Cœur gelé", icon = "❄️", price = 600 },
	-- matériaux transformés
	planks = { name = "Planches", icon = "🌲", price = 2 },
	rope = { name = "Corde", icon = "➰", price = 5 },
	cloth = { name = "Tissu", icon = "🧵", price = 25 },
	brick = { name = "Brique", icon = "🧱", price = 6 },
	copper_ingot = { name = "Lingot de cuivre", icon = "🥉", price = 30 },
	iron_ingot = { name = "Lingot de fer", icon = "🔩", price = 45 },
	gold_ingot = { name = "Lingot d'or", icon = "🥇", price = 120 },
	-- cuisine (le four)
	bread = { name = "Pain", icon = "🍞", price = 70, food = 25 },
	grilled_fish = { name = "Poisson grillé", icon = "🍢", price = 0, food = 30 },
	omelette = { name = "Omelette", icon = "🍳", price = 60, food = 35 },
	soup = { name = "Soupe du potager", icon = "🍲", price = 140, food = 45 },
	pie = { name = "Tarte à la citrouille", icon = "🥧", price = 220, food = 60 },
	stew = { name = "Ragoût du désert", icon = "🥘", price = 200, food = 55 },
	steak = { name = "Steak grillé", icon = "🍖", price = 30, food = 28 },
	game_stew = { name = "Ragoût de gibier", icon = "🍲", price = 120, food = 50 },
	honey_cake = { name = "Gâteau au miel", icon = "🍰", price = 180, food = 55 },
	bonemeal = { name = "Engrais d'os", icon = "🌱", price = 10, use = "fertilize" },
	egg = { name = "Œuf", icon = "🥚", price = 15, food = 10 },
	milk = { name = "Lait", icon = "🥛", price = 35, food = 15 },
	wool = { name = "Laine", icon = "🧶", price = 60 },
	fish = { name = "Poisson", icon = "🐟", price = 0 }, -- les poissons ont leur propre prix
	-- outils (base = famille, tier = 1 pierre, 2 cuivre, 3 fer ; le meilleur de chaque famille est en main)
	hoe = { name = "Houe", icon = "⛏", tool = true, price = 40 },
	can = { name = "Arrosoir", icon = "🚿", tool = true, price = 40 },
	shovel = { name = "Pelle", icon = "🧺", tool = true, price = 50 },
	axe = { name = "Hache de pierre", icon = "🪓", tool = true, price = 60, base = "axe", tier = 1 },
	axe_cu = { name = "Hache de cuivre", icon = "🪓", tool = true, price = 140, base = "axe", tier = 2 },
	axe_fe = { name = "Hache de fer", icon = "🪓", tool = true, price = 260, base = "axe", tier = 3 },
	pickaxe = { name = "Pioche de pierre", icon = "⛏️", tool = true, price = 60, base = "pickaxe", tier = 1 },
	pickaxe_cu = { name = "Pioche de cuivre", icon = "⛏️", tool = true, price = 140, base = "pickaxe", tier = 2 },
	pickaxe_fe = { name = "Pioche de fer", icon = "⛏️", tool = true, price = 260, base = "pickaxe", tier = 3 },
	rod = { name = "Canne à pêche", icon = "🎣", tool = true, price = 50 },
	spade = { name = "Bêche de terrassier", icon = "⛏", tool = true, price = 90 },
	dirt = { name = "Terre", icon = "🟫", price = 1 },
	sand = { name = "Sable", icon = "🏜️", price = 1 },
	flour = { name = "Farine", icon = "🌾", price = 18 },
	windmill = { name = "Moulin", icon = "🌬️", place = "Moulin", grid = "cell" },
	sprinkler = { name = "Arroseur", icon = "💦", place = "Arroseur", grid = "cell" },
	beehive = { name = "Ruche", icon = "🐝", place = "Ruche", grid = "cell" },
	country_bread = { name = "Pain de campagne", icon = "🥖", price = 110, food = 40 },
	glass = { name = "Verre", icon = "🖼️", price = 8 },
	bucket_empty = { name = "Seau vide", icon = "🧺", price = 20, use = "fill" },
	bucket = { name = "Seau d'eau", icon = "💧", price = 22, use = "pour" },
	club = { name = "Gourdin", icon = "🏏", tool = true, weapon = 2, price = 20, base = "club", tier = 1 },
	sword = { name = "Épée de cuivre", icon = "🗡️", tool = true, weapon = 4, price = 150, base = "sword", tier = 2 },
	sword_fe = { name = "Épée de fer", icon = "⚔️", tool = true, weapon = 6, price = 320, base = "sword", tier = 3 },
	-- objets posés (grid = posé sur la grille de 4 studs ; wall = sur le bord de la case où l'on se tient)
	fence = { name = "Clôture", icon = "🌲", place = "Cloture", grid = "edge" },
	campfire = { name = "Feu de camp", icon = "🔥", place = "Feu_Camp" },
	workbench = { name = "Établi", icon = "🛠️", place = "Etabli", grid = "cell" },
	anvil = { name = "Enclume", icon = "⚒️", place = "Enclume", grid = "cell" },
	loom = { name = "Métier à tisser", icon = "🧶", place = "Metier_Tisser", grid = "cell" },
	tannery = { name = "Bac de tannage", icon = "🦌", place = "Bac_Tannage", grid = "cell" },
	-- élevage (18/11) : une bête près d'un abreuvoir ET d'une mangeoire produit plus souvent
	trough = { name = "Abreuvoir", icon = "💧", place = "Abreuvoir", grid = "cell" },
	feeder = { name = "Mangeoire", icon = "🌾", place = "Mangeoire", grid = "cell" },
	alembic = { name = "Alambic", icon = "⚗️", place = "Alambic", grid = "cell" },
	furnace = { name = "Four", icon = "🏭", place = "Fourneau", grid = "cell" },
	chest = { name = "Coffre", icon = "📦", place = "Coffre_Joueur", grid = "cell" },
	scarecrow = { name = "Épouvantail", icon = "🎃", place = "Epouvantail" },
	floor = { name = "Plancher", icon = "🟫", place = "Plancher", grid = "cell", build = true },
	wall = { name = "Mur en planches", icon = "🚪", place = "Mur_Planches", grid = "edge", build = true },
	wall_door = { name = "Mur avec porte", icon = "🚪", place = "Mur_Porte", grid = "edge", build = true },
	wall_stone = { name = "Mur de pierre", icon = "🧱", place = "Mur_Pierre", grid = "edge", build = true },
	wall_brick = { name = "Mur de briques", icon = "🧱", place = "Mur_Briques", grid = "edge", build = true },
	roof = { name = "Toit de chaume", icon = "🏠", place = "Toit_Chaume", grid = "cell", build = true },
	-- étage (posés 7,4 studs plus haut : sur les murs du rez-de-chaussée)
	floor2 = { name = "Plancher d'étage", icon = "🟫", place = "Plancher", grid = "cell", build = true, dy = 7.4 },
	wall2 = { name = "Mur d'étage", icon = "🧱", place = "Mur_Planches", grid = "edge", build = true, dy = 7.4 },
	wall2_window = { name = "Mur d'étage avec fenêtre", icon = "🖼️", place = "Mur_Fenetre", grid = "edge", build = true, dy = 7.4 },
	roof2 = { name = "Toit d'étage", icon = "🏠", place = "Toit_Chaume", grid = "cell", build = true, dy = 7.4 },
	wall_window = { name = "Mur avec fenêtre", icon = "🖼️", place = "Mur_Fenetre", grid = "edge", build = true },
	stairs = { name = "Escalier", icon = "🔝", place = "Escalier_Bois", grid = "cell", build = true },
	-- mobilier et décoration
	table_wood = { name = "Table", icon = "🪑", place = "Table_Bois", grid = "cell" },
	chair = { name = "Chaise", icon = "🪑", place = "Chaise", grid = "cell" },
	rug = { name = "Tapis", icon = "🟥", place = "Tapis", grid = "cell" },
	flowerpot = { name = "Pot de fleurs", icon = "🌿", place = "Pot_Fleurs", grid = "cell" },
	shelf = { name = "Étagère", icon = "📚", place = "Etagere", grid = "cell" },
	garden_bench = { name = "Banc", icon = "🪑", place = "Banc", grid = "cell" },
	bed = { name = "Lit", icon = "🛏️", place = "Lit_Joueur", grid = "cell" },
	lantern = { name = "Lanterne", icon = "🏮", place = "Lanterne", grid = "cell" },
	claim = { name = "Panneau de propriété", icon = "🚩", place = "Panneau", grid = "cell", claim = true },
	-- protection de la maison (esprit GTA : on PEUT te cambrioler, à toi de te protéger)
	door = { name = "Porte en bois", icon = "🚪", place = "Porte", grid = "edge", build = true, door = true },
	alarm = { name = "Cloche d'alarme", icon = "🔔", place = "Cloche_Alarme", grid = "cell", alarm = true },
	tourelle = { name = "Arbalète de garde", icon = "🏹", price = 420, place = "Cat_tourelle", grid = "cell", turret = 1, hp = 14 },
	baliste = { name = "Baliste de rempart", icon = "🏰", price = 1500, place = "Cat_baliste", grid = "cell", turret = 2, hp = 24 },
	bolt = { name = "Carreaux", icon = "📌", price = 3 },
	bolt_heavy = { name = "Carreaux de baliste", icon = "🔱", price = 30 },
	lock_1 = { name = "Loquet en bois", icon = "🔒", lock = 1, price = 20 },
	lock_2 = { name = "Serrure de cuivre", icon = "🔒", lock = 2, price = 70 },
	lock_3 = { name = "Serrure de fer", icon = "🔐", lock = 3, price = 140 },
	lock_4 = { name = "Serrure à secret (or)", icon = "🔐", lock = 4, price = 320 },
	lockpick = { name = "Crochet", icon = "🎣", price = 15 },
	stall = { name = "Étal de marché", icon = "🏪", place = "Etal", grid = "cell" },
	barracks = { name = "Caserne", icon = "🏰", place = "Caserne", grid = "cell", plotOnly = true },
	practice_lock = { name = "Serrure d'entraînement", icon = "🧩", place = "Serrure_Entrainement", grid = "cell" },
	-- appâts pour apprivoiser
	dog_collar = { name = "Collier de chien", icon = "📿", price = 30 },
}

-- Serrures : un coffre ou une porte verrouillés ne s'ouvrent qu'avec un crochet ET le talent de
-- crochetage suffisant (sans talent : niveau 1 seulement). Plus la serrure est dure, plus le
-- mini-jeu demande de goupilles et plus la zone à viser est petite.
C.LOCKS = {
	[1] = { name = "Loquet en bois", pins = 2, zone = 0.30, speed = 1.0, breakChance = 0.15 },
	[2] = { name = "Serrure de cuivre", pins = 3, zone = 0.22, speed = 1.3, breakChance = 0.25 },
	[3] = { name = "Serrure de fer", pins = 4, zone = 0.16, speed = 1.6, breakChance = 0.35 },
	[4] = { name = "Serrure à secret", pins = 5, zone = 0.11, speed = 2.0, breakChance = 0.45 },
}

-- Apprivoiser : appât à donner (bête affaiblie pour les prédateurs : weak = part de vie max),
-- guard = monte la garde sur ta parcelle, fight = se bat à tes côtés, product = {objet, tous les n jours}
C.TAMING = {
	wolf = { bait = "meat", diff = 4, guard = true, fight = true, weak = 0.35, label = "chien de garde" },
	wolf_white = { bait = "meat", diff = 4, guard = true, fight = true, weak = 0.35, label = "chien de garde" },
	croc = { bait = "meat", diff = 4, guard = true, fight = true, weak = 0.35, label = "gardien du marais" },
	bear = { bait = "honey", diff = 5, guard = true, fight = true, weak = 0.3, product = { "honey", 3 }, label = "ours apprivoisé" },
	boar = { bait = "mushroom", diff = 3, fight = true, product = { "mushroom", 2 }, label = "cochon truffier" },
	fox = { bait = "berries", diff = 3, guard = true, label = "renard sentinelle (aboie)" },
	deer = { bait = "carrot", diff = 2, product = { "leather", 4 }, label = "cerf" },
	rabbit = { bait = "carrot", diff = 1, product = { "fur", 3 }, label = "lapin" },
	penguin = { bait = "fish", diff = 1, product = { "feather", 2 }, label = "pingouin" },
	camel = { bait = "wheat", diff = 2, product = { "milk", 2 }, label = "chameau laitier" },
	flamingo = { bait = "fish", diff = 2, product = { "feather", 2 }, label = "flamant" },
	horse = { bait = "carrot", diff = 3, label = "cheval" }, -- chevaux sauvages (système Horses)
}

-- Compétences qui progressent À FORCE DE PRATIQUE (grind) : niveau = racine(xp / 4), max 50.
-- Elles élargissent la zone à viser dans les mini-jeux et ouvrent l'accès aux serrures / bêtes dures.
C.SKILLS = {
	agriculture = { name = "Agriculture", icon = "🌾", desc = "Cultures plus difficiles, récoltes doubles" },
	bucheronnage = { name = "Bûcheronnage", icon = "🪓", desc = "Bois en plus, arbres abattus plus vite" },
	minage = { name = "Minage", icon = "⛏️", desc = "Fer au niv. 12, or au niv. 25, minerai en plus" },
	peche = { name = "Pêche", icon = "🎣", desc = "Poissons rares, touches plus fréquentes" },
	cuisine = { name = "Cuisine", icon = "🍳", desc = "Plats élaborés, plats qui nourrissent plus" },
	artisanat = { name = "Artisanat", icon = "⚒️", desc = "Outils de fer, serrures, équipement" },
	combat = { name = "Combat", icon = "⚔️", desc = "+1 % de dégâts par niveau" },
	crochetage = { name = "Crochetage", icon = "🎣", desc = "Serrures plus dures, crochets qui cassent moins" },
	dressage = { name = "Dressage", icon = "🐾", desc = "Bêtes plus sauvages, mini-jeu plus facile" },
	elevage = { name = "Élevage", icon = "🐄", desc = "Produits des bêtes plus souvent" },
	commerce = { name = "Commerce", icon = "💰", desc = "Ventes et commandes mieux payées (+0,5 % / +1 % par niveau)" },
}
C.SKILL_ORDER = { "agriculture", "bucheronnage", "minage", "peche", "cuisine", "artisanat", "combat", "crochetage", "dressage", "elevage", "commerce" }
C.SKILL_MAX = 50
-- rangs de maîtrise (19/11) : { niveau minimal, nom } — annoncés au passage, affichés dans la fiche
C.SKILL_RANKS = { { 0, "Novice" }, { 10, "Apprenti" }, { 25, "Compagnon" }, { 40, "Maître" }, { 50, "Grand maître" } }
function C.skillRank(level: number): string
	local name = C.SKILL_RANKS[1][2]
	for _, r in C.SKILL_RANKS do
		if level >= r[1] then
			name = r[2]
		end
	end
	return name
end
function C.skillLevel(xp: number): number
	return math.min(C.SKILL_MAX, math.floor(math.sqrt((xp or 0) / 4)))
end
-- niveau de compétence minimum : serrure de niveau t / bête de difficulté d
C.LOCK_SKILL = { [1] = 0, [2] = 8, [3] = 20, [4] = 35 }
C.TAME_SKILL = { [1] = 0, [2] = 0, [3] = 5, [4] = 12, [5] = 25 }
-- Pas de nombre maximum de compagnons : il faut les nourrir chaque jour (Compagnons.newDay)

-- Armée (caserne) : coût, solde par jour, temps de formation en secondes RÉELLES
C.UNITS = {
	militia = { name = "Milicien", model = "Soldat_Milicien", hp = 140, dmg = 14, speed = 13, guard = true, fight = true,
		cost = { gold = 120, bread = 2 }, wage = 10, train = 60, desc = "Robuste et bon marché." },
	archer = { name = "Archer", model = "Soldat_Archer", hp = 100, dmg = 12, speed = 13, guard = true, fight = true, ranged = true,
		cost = { gold = 180, bread = 2, rope = 2 }, wage = 15, train = 90, desc = "Tire de loin (16 studs)." },
	guard = { name = "Garde", model = "Soldat_Garde", hp = 260, dmg = 18, speed = 11, guard = true, fight = true,
		cost = { gold = 300, steak = 3, iron_ingot = 2 }, wage = 25, train = 150, desc = "Encaisse et tient la porte." },
}
C.UNIT_ORDER = { "militia", "archer", "guard" }
for _, u in C.UNITS do
	u.label = "soldat"
end

-- Primes (persistantes, comme les étoiles) : ce que touche celui qui t'arrête ou te met K.O.
C.BOUNTY = { theft = 25, breakin = 45, assault = 60, ko = 150, vandalism = 35 }

-- Groupes d'ingrédients : « n'importe quel poisson » (remplis plus bas)
C.ITEM_GROUPS = { fish = {} }
C.GROUP_NAMES = { fish = { name = "Poisson (au choix)", icon = "🐟" } }

-- Cultures : biomes = où elles poussent (on les échange entre joueurs des autres biomes).
-- days = jours d'arrosage pour mûrir ; color = couleur du fruit mûr.
C.CROPS = {
	parsnip = { name = "Panais", icon = "🥕", price = 25, seed_price = 8, biomes = { "prairie", "neige" }, skill = 0, days = 3, color = Color3.fromRGB(236, 222, 170), shape = "root" },
	carrot = { name = "Carotte", icon = "🥕", price = 35, seed_price = 12, biomes = { "prairie", "foret" }, skill = 0, days = 3, color = Color3.fromRGB(240, 130, 40), shape = "root" },
	potato = { name = "Patate", icon = "🥔", price = 55, seed_price = 20, biomes = { "prairie", "neige" }, skill = 3, days = 4, color = Color3.fromRGB(196, 150, 96), shape = "root" },
	wheat = { name = "Blé", icon = "🌾", price = 20, seed_price = 6, biomes = { "prairie", "desert" }, skill = 0, days = 3, color = Color3.fromRGB(230, 196, 90), shape = "wheat" },
	tomato = { name = "Tomate", icon = "🍅", price = 45, seed_price = 15, biomes = { "desert", "marais" }, skill = 5, days = 4, color = Color3.fromRGB(220, 50, 40), shape = "bush" },
	melon = { name = "Melon", icon = "🍈", price = 90, seed_price = 30, biomes = { "desert" }, skill = 12, days = 5, color = Color3.fromRGB(150, 200, 90), shape = "big" },
	beetroot = { name = "Betterave", icon = "🍠", price = 30, seed_price = 10, biomes = { "foret", "neige" }, skill = 5, days = 3, color = Color3.fromRGB(150, 30, 70), shape = "root" },
	eggplant = { name = "Aubergine", icon = "🍆", price = 50, seed_price = 16, biomes = { "marais", "foret" }, skill = 8, days = 4, color = Color3.fromRGB(110, 50, 140), shape = "bush" },
	pumpkin = { name = "Citrouille", icon = "🎃", price = 110, seed_price = 35, biomes = { "foret" }, skill = 15, days = 5, color = Color3.fromRGB(240, 140, 30), shape = "big" },
}
C.CROP_ORDER = { "parsnip", "carrot", "potato", "wheat", "tomato", "melon", "beetroot", "eggplant", "pumpkin" }
local Catalogue = require(script.Parent.Catalogue)
Catalogue.applyCrops(C)
-- cultures d'un biome (sauvages, coffres, boutique)
C.BIOME_CROPS = {}
for _, id in C.CROP_ORDER do
	for _, b in C.CROPS[id].biomes do
		C.BIOME_CROPS[b] = C.BIOME_CROPS[b] or {}
		table.insert(C.BIOME_CROPS[b], id)
	end
end
for id, crop in C.CROPS do
	C.ITEMS[id] = { name = crop.name, icon = crop.icon, price = crop.price, food = math.floor(crop.price / 3) }
	C.ITEMS["seed_" .. id] = { name = "Graines (" .. crop.name .. ")", icon = "🌱", price = crop.seed_price, seed = id }
end

-- Animaux de ferme
C.ANIMALS = {
	chicken = { name = "Poule", model = "Poule", product = "egg", every = 1, price = 60, speed = 5 },
	cow = { name = "Vache", model = "Vache", product = "milk", every = 1, price = 220, speed = 3 },
	sheep = { name = "Mouton", model = "Mouton", product = "wool", every = 3, price = 160, speed = 3.5 },
}
C.PRODUCT_VERB = { egg = "Ramasser l'œuf", milk = "Traire", wool = "Tondre" }
C.HORSE_PRICE = 250
-- Montures (18/11) : même modèle « Cheval » à une autre échelle ; vitesse = RIDE × speed.
-- L'âne et le mulet coûtent moins cher et se laissent mieux approcher (apprivoisement plus facile).
C.MOUNTS = {
	cheval = { name = "Cheval", speed = 1, scale = 1, price = 250, tame = 1 },
	mulet = { name = "Mulet", speed = 0.82, scale = 0.9, price = 170, tame = 0.75 },
	ane = { name = "Âne", speed = 0.68, scale = 0.78, price = 110, tame = 0.55 },
}
C.SPRINT_DRAIN = 1.2 -- endurance par seconde de course
C.HORSE_COATS = {
	{ name = "Alezan", body = Color3.fromRGB(150, 82, 40), mane = Color3.fromRGB(236, 190, 90) },
	{ name = "Bai", body = Color3.fromRGB(110, 62, 36), mane = Color3.fromRGB(40, 30, 26) },
	{ name = "Noir", body = Color3.fromRGB(44, 40, 40), mane = Color3.fromRGB(20, 20, 20) },
	{ name = "Blanc", body = Color3.fromRGB(236, 232, 224), mane = Color3.fromRGB(210, 206, 196) },
	{ name = "Gris", body = Color3.fromRGB(150, 150, 154), mane = Color3.fromRGB(70, 70, 74) },
	{ name = "Palomino", body = Color3.fromRGB(226, 182, 110), mane = Color3.fromRGB(250, 240, 210) },
}
C.SADDLES = { Color3.fromRGB(120, 40, 40), Color3.fromRGB(40, 70, 120), Color3.fromRGB(60, 100, 50), Color3.fromRGB(90, 60, 40) }

-- Poissons : prix, biomes (nil = partout), poids de rareté
C.FISH = {
	{ name = "Gardon", price = 15, skill = 0, weight = 40 },
	{ name = "Carpe", price = 25, skill = 0, weight = 30 },
	{ name = "Truite", price = 40, skill = 5, biomes = { "prairie", "neige" }, weight = 18 },
	{ name = "Poisson-chat", price = 45, skill = 8, biomes = { "marais", "desert" }, weight = 15 },
	{ name = "Brochet", price = 60, skill = 12, biomes = { "foret", "neige" }, weight = 12 },
	{ name = "Anguille", price = 55, skill = 15, biomes = { "marais", "prairie" }, weight = 8 },
	{ name = "Poisson doré", price = 250, skill = 25, weight = 2 },
}

for i, f in C.FISH do
	C.ITEMS["fish_" .. i] = { name = f.name, icon = "🐟", price = f.price, food = 12 }
	table.insert(C.ITEM_GROUPS.fish, "fish_" .. i)
end
C.ITEMS.grilled_fish.price = 60

-- Familles d'outils : du meilleur au moins bon
C.TOOL_FAMILIES = {
	axe = { "axe_fe", "axe_cu", "axe" },
	pickaxe = { "pickaxe_fe", "pickaxe_cu", "pickaxe" },
	sword = { "sword_fe", "sword", "club" },
}
function C.baseOf(id: string): string
	local info = C.ITEMS[id]
	return (info and info.base) or id
end
function C.tierOf(id: string): number
	local info = C.ITEMS[id]
	return (info and info.tier) or 1
end

-- Fabrication (façon Minecraft). cat = onglet de l'atelier ; station = il faut être près d'un
-- établi (bench) ou d'un four (furnace) ; count = quantité obtenue. Les filons : charbon et cuivre
-- à la pioche de pierre, fer à la pioche de cuivre, or à la pioche de fer.
C.CRAFT_TABS = {
	{ id = "outils", name = "Outils" },
	{ id = "equipement", name = "Équipement" },
	{ id = "materiaux", name = "Matériaux" },
	{ id = "construction", name = "Construction" },
	{ id = "securite", name = "Sécurité" },
	{ id = "mobilier", name = "Mobilier" },
	{ id = "cuisine", name = "Cuisine" },
}
C.STATIONS = {
	bench = { name = "Établi", icon = "🛠️", model = "Etabli" },
	furnace = { name = "Four", icon = "🏭", model = "Fourneau", public = "Forge" },
	-- 18/11 : vraies stations de métier ; la forge d'un village sert d'enclume et de four à tous
	anvil = { name = "Enclume", art = "d'une", icon = "⚒️", model = "Enclume", public = "Forge" },
	loom = { name = "Métier à tisser", icon = "🧶", model = "Metier_Tisser" },
	tannery = { name = "Bac de tannage", icon = "🦌", model = "Bac_Tannage" },
	alembic = { name = "Alambic", icon = "⚗️", model = "Alambic" },
}
C.RECIPES = {
	-- stations de métier (18/11)
	{ item = "anvil", needs = { stone = 12, copper_ingot = 3 }, station = "bench", cat = "mobilier", skill = { "artisanat", 3 } },
	{ item = "loom", needs = { planks = 10, rope = 2 }, station = "bench", cat = "mobilier" },
	{ item = "tannery", needs = { planks = 8, stone = 4, rope = 1 }, station = "bench", cat = "mobilier" },
	{ item = "trough", needs = { planks = 6, stone = 2 }, station = "bench", cat = "mobilier", skill = { "elevage", 2 } },
	{ item = "feeder", needs = { planks = 6, wheat = 4 }, station = "bench", cat = "mobilier", skill = { "elevage", 2 } },
	{ item = "alembic", needs = { copper_ingot = 4, glass = 2 }, station = "anvil", cat = "mobilier", skill = { "artisanat", 4 } },
	-- outils
	{ item = "club", needs = { wood = 3 }, cat = "outils" },
	{ item = "hoe", needs = { wood = 2, stone = 2 }, cat = "outils" },
	{ item = "can", needs = { wood = 4, stone = 1 }, cat = "outils" },
	{ item = "shovel", needs = { wood = 2, stone = 3 }, cat = "outils" },
	{ item = "axe", needs = { wood = 3, stone = 2 }, cat = "outils" },
	{ item = "pickaxe", needs = { wood = 2, stone = 4 }, cat = "outils" },
	{ item = "rod", needs = { wood = 4, fiber = 3 }, cat = "outils" },
	{ item = "axe_cu", needs = { planks = 2, copper_ingot = 2 }, station = "anvil", cat = "outils", skill = { "artisanat", 3 } },
	{ item = "pickaxe_cu", needs = { planks = 2, copper_ingot = 3 }, station = "anvil", cat = "outils", skill = { "artisanat", 3 } },
	{ item = "sword", needs = { planks = 1, copper_ingot = 3 }, station = "anvil", cat = "outils", skill = { "artisanat", 5 } },
	{ item = "axe_fe", needs = { planks = 2, iron_ingot = 2 }, station = "anvil", cat = "outils", skill = { "artisanat", 12 } },
	{ item = "pickaxe_fe", needs = { planks = 2, iron_ingot = 3 }, station = "anvil", cat = "outils", skill = { "artisanat", 12 } },
	{ item = "sword_fe", needs = { planks = 1, iron_ingot = 3, rope = 1 }, station = "anvil", cat = "outils", skill = { "artisanat", 15 } },
	-- matériaux
	{ item = "planks", needs = { wood = 1 }, count = 2, cat = "materiaux" },
	{ item = "rope", needs = { fiber = 3 }, cat = "materiaux" },
	{ item = "cloth", needs = { wool = 1 }, count = 2, station = "loom", cat = "materiaux" },
	{ item = "cloth", needs = { fiber = 8 }, station = "loom", cat = "materiaux" },
	{ item = "coal", needs = { wood = 3 }, station = "furnace", cat = "materiaux" },
	{ item = "copper_ingot", needs = { copper_ore = 2, coal = 1 }, station = "furnace", cat = "materiaux" },
	{ item = "iron_ingot", needs = { ore = 2, coal = 1 }, station = "furnace", cat = "materiaux" },
	{ item = "gold_ingot", needs = { gold_ore = 2, coal = 1 }, station = "furnace", cat = "materiaux" },
	{ item = "brick", needs = { clay = 2, coal = 1 }, count = 3, station = "furnace", cat = "materiaux" },
	{ item = "glass", needs = { sand = 2, coal = 1 }, count = 2, station = "furnace", cat = "materiaux", skill = { "artisanat", 4 } },
	-- construction
	{ item = "fence", needs = { wood = 2 }, count = 2, cat = "construction" },
	{ item = "claim", needs = { planks = 4, rope = 1 }, cat = "construction" },
	{ item = "spade", needs = { planks = 2, iron_ingot = 1 }, station = "anvil", cat = "outils", skill = { "artisanat", 6 } },
	{ item = "bucket_empty", needs = { planks = 2, copper_ingot = 1 }, station = "anvil", cat = "outils" },
	{ item = "table_wood", needs = { planks = 4 }, cat = "mobilier" },
	{ item = "chair", needs = { planks = 2 }, cat = "mobilier" },
	{ item = "rug", needs = { cloth = 2 }, cat = "mobilier" },
	{ item = "flowerpot", needs = { clay = 2, flower = 2 }, station = "furnace", cat = "mobilier" },
	{ item = "shelf", needs = { planks = 5 }, cat = "mobilier" },
	{ item = "garden_bench", needs = { planks = 3 }, cat = "mobilier" },
	-- inventions
	{ item = "windmill", needs = { planks = 20, stone = 10, cloth = 4 }, station = "bench", cat = "mobilier", skill = { "artisanat", 10 } },
	{ item = "sprinkler", needs = { copper_ingot = 3, planks = 2 }, station = "bench", cat = "mobilier", skill = { "artisanat", 8 } },
	{ item = "beehive", needs = { planks = 6, fiber = 6, flower = 4 }, station = "bench", cat = "mobilier", skill = { "elevage", 3 } },
	{ item = "country_bread", needs = { flour = 2, egg = 1 }, station = "furnace", cat = "cuisine", skill = { "cuisine", 5 } },
	{ item = "door", needs = { planks = 4, copper_ingot = 1 }, station = "bench", cat = "construction", skill = { "artisanat", 3 } },
	-- sécurité
	{ item = "lock_1", needs = { planks = 2, rope = 1 }, cat = "securite" },
	{ item = "lock_2", needs = { copper_ingot = 2 }, station = "bench", cat = "securite", skill = { "artisanat", 5 } },
	{ item = "lock_3", needs = { iron_ingot = 3 }, station = "bench", cat = "securite", skill = { "artisanat", 15 } },
	{ item = "lock_4", needs = { gold_ingot = 2, iron_ingot = 2 }, station = "bench", cat = "securite", skill = { "artisanat", 28 } },
	{ item = "alarm", needs = { copper_ingot = 2, rope = 1, planks = 2 }, station = "bench", cat = "securite", skill = { "artisanat", 8 } },
	{ item = "tourelle", needs = { planks = 8, iron_ingot = 4, rope = 3 }, station = "bench", cat = "securite", skill = { "artisanat", 10 } },
	{ item = "baliste", needs = { steel = 4, planks = 12, rope = 4, iron_ingot = 6 }, station = "bench", cat = "securite", skill = { "artisanat", 22 } },
	{ item = "bolt", needs = { planks = 1, iron_ingot = 1 }, count = 12, station = "bench", cat = "securite", skill = { "artisanat", 6 } },
	{ item = "bolt_heavy", needs = { planks = 2, steel = 1 }, count = 4, station = "bench", cat = "securite", skill = { "artisanat", 18 } },
	{ item = "lockpick", needs = { copper_ingot = 1 }, count = 3, station = "bench", cat = "securite" },
	{ item = "lockpick", needs = { bone = 2, rope = 1 }, count = 2, cat = "securite" },
	{ item = "practice_lock", needs = { planks = 4, copper_ingot = 2 }, station = "bench", cat = "securite", skill = { "artisanat", 4 } },
	{ item = "dog_collar", needs = { leather = 2, copper_ingot = 1 }, station = "bench", cat = "securite", skill = { "artisanat", 3 } },
	-- mobilier
	{ item = "workbench", needs = { wood = 10, stone = 4 }, cat = "mobilier" },
	{ item = "furnace", needs = { stone = 12, coal = 1 }, station = "bench", cat = "mobilier" },
	{ item = "campfire", needs = { wood = 5, stone = 3 }, cat = "mobilier" },
	{ item = "chest", needs = { planks = 8 }, station = "bench", cat = "mobilier" },
	{ item = "stall", needs = { planks = 10, cloth = 2 }, station = "bench", cat = "mobilier", skill = { "commerce", 3 } },
	{ item = "barracks", needs = { stone = 40, planks = 30, iron_ingot = 6 }, station = "bench", cat = "construction", skill = { "artisanat", 15 } },
	{ item = "bed", needs = { planks = 4, cloth = 2 }, station = "bench", cat = "mobilier", skill = { "artisanat", 2 } },
	{ item = "lantern", needs = { copper_ingot = 1, coal = 1, planks = 1 }, station = "bench", cat = "mobilier", skill = { "artisanat", 4 } },
	{ item = "scarecrow", needs = { wood = 4, fiber = 6 }, station = "bench", cat = "mobilier" },
	-- équipement fabriqué (stats fixes ; les pièces rares viennent des coffres et des monstres)
	{ gear = { slot = "armor", name = "Armure de cuir", rarity = 1, stats = { defense = 3, vie = 1 } }, needs = { leather = 6, rope = 2 }, station = "bench", cat = "equipement", skill = { "artisanat", 3 } },
	{ gear = { slot = "hat", name = "Bonnet de fourrure", visual = "bonnet", rarity = 1, stats = { vie = 2, defense = 1 } }, needs = { fur = 3, cloth = 1 }, station = "bench", cat = "equipement", skill = { "artisanat", 3 } },
	{ gear = { slot = "armor", name = "Cape de soie", rarity = 2, stats = { discretion = 4, vitesse = 1 } }, needs = { silk = 6, cloth = 2 }, station = "bench", cat = "equipement", skill = { "artisanat", 8 } },
	{ gear = { slot = "trinket", name = "Amulette d'os", rarity = 1, stats = { force = 2 } }, needs = { bone = 5, rope = 1 }, station = "bench", cat = "equipement", skill = { "artisanat", 4 } },
	{ gear = { slot = "trinket", name = "Anneau d'or", rarity = 2, stats = { chance = 3, charisme = 2 } }, needs = { gold_ingot = 2 }, station = "bench", cat = "equipement", skill = { "artisanat", 18 } },
	{ gear = { slot = "hat", name = "Coiffe à plumes", visual = "capuche", rarity = 2, stats = { charisme = 3, chance = 1 } }, needs = { feather = 6, cloth = 1 }, station = "bench", cat = "equipement", skill = { "artisanat", 6 } },
	{ gear = { slot = "armor", name = "Plastron de fer", rarity = 2, stats = { defense = 6, vie = 2 } }, needs = { iron_ingot = 5, leather = 2 }, station = "anvil", cat = "equipement", skill = { "artisanat", 16 } },
	{ gear = { slot = "weapon", name = "Lame de dard", visual = "4", power = 5, rarity = 2, stats = { force = 3, vitesse = 1 } }, needs = { stinger = 3, iron_ingot = 2, planks = 1 }, station = "anvil", cat = "equipement", skill = { "artisanat", 12 } },
	{ gear = { slot = "trinket", name = "Cœur de givre", rarity = 3, stats = { defense = 3, vie = 3, force = 2 } }, needs = { ice_crystal = 4, gold_ingot = 1 }, station = "bench", cat = "equipement", skill = { "artisanat", 24 } },
	{ gear = { slot = "trinket", name = "Lanterne des feux follets", rarity = 3, stats = { discretion = 4, chance = 3 } }, needs = { wisp_dust = 5, copper_ingot = 2 }, station = "bench", cat = "equipement", skill = { "artisanat", 20 } },
	-- pièces légendaires (trophées des boss itinérants)
	{ gear = { slot = "armor", name = "Manteau des Moissons", rarity = 4, stats = { vie = 5, discretion = 5, chance = 3 } }, needs = { enchanted_cloth = 2, ancient_seed = 2, cloth = 4 }, station = "bench", cat = "equipement", skill = { "artisanat", 30 } },
	{ gear = { slot = "hat", name = "Couronne mycélienne", visual = "mage", rarity = 4, stats = { charisme = 6, chance = 4, vie = 2 } }, needs = { royal_spore = 2, gold_ingot = 2 }, station = "bench", cat = "equipement", skill = { "artisanat", 32 } },
	{ gear = { slot = "weapon", name = "Lame de verre vivant", visual = "8", power = 9, rarity = 4, stats = { force = 7, vitesse = 3 } }, needs = { glass_shard = 3, iron_ingot = 4, gold_ingot = 1 }, station = "anvil", cat = "equipement", skill = { "artisanat", 35 } },
	{ gear = { slot = "trinket", name = "Cœur du Dormeur", rarity = 4, stats = { defense = 6, vie = 6, force = 3 } }, needs = { frozen_heart = 1, ice_crystal = 6, gold_ingot = 2 }, station = "bench", cat = "equipement", skill = { "artisanat", 38 } },
	-- matériaux issus des créatures
	{ item = "cloth", needs = { silk = 3 }, count = 2, station = "loom", cat = "materiaux" },
	{ item = "rope", needs = { slime_gel = 2, fiber = 1 }, count = 2, cat = "materiaux" },
	{ item = "bonemeal", needs = { bone = 1 }, count = 3, cat = "materiaux" },
	-- cuisine (au four)
	{ item = "steak", needs = { meat = 1 }, station = "furnace", cat = "cuisine" },
	{ item = "game_stew", needs = { meat = 2, potato = 1, carrot = 1 }, station = "furnace", cat = "cuisine", skill = { "cuisine", 8 } },
	{ item = "honey_cake", needs = { honey = 1, wheat = 2, egg = 1 }, station = "furnace", cat = "cuisine", skill = { "cuisine", 14 } },
	{ item = "grilled_fish", needs = { fish = 1 }, station = "furnace", cat = "cuisine" },
	{ item = "bread", needs = { wheat = 3 }, station = "furnace", cat = "cuisine" },
	{ item = "omelette", needs = { egg = 2, mushroom = 1 }, station = "furnace", cat = "cuisine", skill = { "cuisine", 3 } },
	{ item = "soup", needs = { carrot = 1, potato = 1, beetroot = 1 }, station = "furnace", cat = "cuisine", skill = { "cuisine", 6 } },
	{ item = "stew", needs = { tomato = 2, eggplant = 1, milk = 1 }, station = "furnace", cat = "cuisine", skill = { "cuisine", 10 } },
	{ item = "pie", needs = { pumpkin = 1, egg = 1, wheat = 1, milk = 1 }, station = "furnace", cat = "cuisine", skill = { "cuisine", 18 } },
}

-- PAS de niveau de personnage ni de barre d'XP : chaque caractéristique (Force, Défense, Vie…)
-- monte en PRATIQUANT les activités qui la travaillent. L'XP d'une compétence nourrit ses
-- caractéristiques selon ces parts ; courir et nager nourrissent la Vitesse (Game).
-- Rang d'une caractéristique = racine(xp / 100) : vite au début, de plus en plus lent, sans plafond.
C.STAT_FROM_SKILL = {
	agriculture = { vie = 0.5, chance = 0.5 },
	bucheronnage = { force = 1 },
	minage = { force = 0.6, defense = 0.4 },
	peche = { chance = 1 },
	cuisine = { vie = 1 },
	artisanat = { defense = 0.6, chance = 0.4 },
	combat = { force = 0.5, defense = 0.5 },
	crochetage = { discretion = 1 },
	dressage = { charisme = 0.5, vitesse = 0.5 },
	elevage = { vie = 0.5, charisme = 0.5 },
	commerce = { charisme = 1 },
}
function C.statLevel(xp: number?): number
	return math.floor(math.sqrt(math.max(0, xp or 0) / 100))
end
function C.statXpFor(level: number): number
	return level * level * 100
end

-- Talents : 1 point tous les 15 rangs de compétence cumulés (toutes compétences), dans 5 voies. Un talent de rang 2+ demande
-- d'avoir déjà investi dans la voie (req = points dans la voie avant de pouvoir le prendre).
C.TALENT_TREES = {
	{ id = "horsloi", name = "Hors-la-loi", icon = "🦹" },
	{ id = "fermier", name = "Fermier", icon = "🌾" },
	{ id = "dresseur", name = "Dresseur", icon = "🐺" },
	{ id = "artisan", name = "Artisan", icon = "⚒️" },
	{ id = "justicier", name = "Justicier", icon = "⭐" },
}
C.TALENTS = {
	-- Hors-la-loi
	{ id = "crochetage", tree = "horsloi", name = "Crochetage", max = 3, req = 0, desc = "Rang 1 : serrures de cuivre. Rang 2 : de fer. Rang 3 : à secret (il faut AUSSI la compétence Crochetage, qui monte en pratiquant)." },
	{ id = "ombre", tree = "horsloi", name = "Ombre", max = 2, req = 1, desc = "Les témoins te voient moins bien (-15 % de vue par rang)." },
	{ id = "cavale", tree = "horsloi", name = "Cavale", max = 2, req = 2, desc = "Tes étoiles retombent plus vite (+35 % par rang)." },
	{ id = "receleur", tree = "horsloi", name = "Receleur", max = 1, req = 3, desc = "Les receleurs t'achètent tout 30 % plus cher." },
	-- Fermier
	{ id = "main_verte", tree = "fermier", name = "Main verte", max = 3, req = 0, desc = "+15 % de chance de récolte double par rang." },
	{ id = "arrosage", tree = "fermier", name = "Grand arrosoir", max = 1, req = 1, desc = "L'arrosoir arrose 3 x 3 cases d'un coup." },
	{ id = "negociant", tree = "fermier", name = "Négociant", max = 2, req = 2, desc = "+10 % sur tes ventes par rang." },
	{ id = "eleveur", tree = "fermier", name = "Éleveur", max = 1, req = 3, desc = "Tes bêtes produisent parfois en double." },
	-- Dresseur
	{ id = "apprivoiseur", tree = "dresseur", name = "Voix douce", max = 2, req = 0, desc = "Les bêtes se calment plus vite dans le mini-jeu (zone plus large, une faute de plus permise)." },
	{ id = "meute", tree = "dresseur", name = "Meute", max = 2, req = 1, desc = "Tes compagnons frappent 40 % plus fort par rang." },
	{ id = "vigilance", tree = "dresseur", name = "Vigilance", max = 1, req = 2, desc = "Tes gardiens repèrent les intrus de plus loin et te préviennent partout." },
	-- Artisan
	{ id = "econome", tree = "artisan", name = "Économe", max = 2, req = 0, desc = "15 % de chance par rang de ne pas consommer les ingrédients." },
	{ id = "mineur", tree = "artisan", name = "Mineur", max = 2, req = 1, desc = "+1 minerai par filon et par rang." },
	{ id = "serrurier", tree = "artisan", name = "Serrurier", max = 1, req = 2, desc = "Tes serrures comptent un niveau de plus contre les cambrioleurs." },
	{ id = "forgeron", tree = "artisan", name = "Maître forgeron", max = 1, req = 3, desc = "L'équipement que tu fabriques a +2 dans sa meilleure stat." },
	-- Justicier
	{ id = "primes", tree = "justicier", name = "Chasseur de primes", max = 2, req = 0, desc = "+40 % sur les primes encaissées par rang." },
	{ id = "menottes", tree = "justicier", name = "Menottes", max = 1, req = 1, desc = "Un recherché que tu mets K.O. part en cellule : tu touches la prime et de l'honneur." },
	{ id = "robuste", tree = "justicier", name = "Robuste", max = 2, req = 1, desc = "+15 vie max par rang." },
	{ id = "critique", tree = "justicier", name = "Coup précis", max = 2, req = 2, desc = "+12 % de chance de coup critique (x2) par rang." },
}
C.TALENT_BY_ID = {}
for _, t in C.TALENTS do
	C.TALENT_BY_ID[t.id] = t
end
function C.talentPoints(totalSkills: number): number
	return math.floor((totalSkills or 0) / 15)
end

-- Construction libre : pièces posées n'importe où (mode construction [V]). Coût direct en matériaux.
-- size = taille (pilier : diamètre, hauteur, diamètre) ; hp = coups de pioche / hache pour la casser.
C.BUILD_MATERIALS = {
	{ id = "bois", name = "Bois", item = "planks", mat = Enum.Material.WoodPlanks, color = Color3.fromRGB(170, 125, 80), hp = 4, mult = 1 },
	{ id = "pierre", name = "Pierre", item = "stone", mat = Enum.Material.Cobblestone, color = Color3.fromRGB(150, 148, 142), hp = 8, mult = 2 },
	{ id = "brique", name = "Brique", item = "brick", mat = Enum.Material.Brick, color = Color3.fromRGB(176, 92, 70), hp = 10, mult = 1 },
	{ id = "chaume", name = "Chaume", item = "fiber", mat = Enum.Material.Grass, color = Color3.fromRGB(214, 182, 96), hp = 3, mult = 2 },
	{ id = "verre", name = "Verre", item = "glass", mat = Enum.Material.Glass, color = Color3.fromRGB(190, 225, 240), hp = 2, mult = 1, transp = 0.45 },
	{ id = "rondin", name = "Rondins", item = "wood", mat = Enum.Material.Wood, color = Color3.fromRGB(120, 84, 52), hp = 6, mult = 2 },
	{ id = "taille", name = "Pierre taillée", item = "stone", mat = Enum.Material.Slate, color = Color3.fromRGB(176, 170, 158), hp = 12, mult = 3 },
	{ id = "torchis", name = "Torchis", item = "clay", mat = Enum.Material.Sand, color = Color3.fromRGB(226, 210, 178), hp = 3, mult = 1 },
	{ id = "pise", name = "Pisé", item = "dirt", mat = Enum.Material.Ground, color = Color3.fromRGB(150, 110, 74), hp = 4, mult = 2 },
	{ id = "tuile", name = "Tuiles", item = "brick", mat = Enum.Material.Brick, color = Color3.fromRGB(186, 84, 52), hp = 8, mult = 1 },
	{ id = "ardoise", name = "Ardoise", item = "stone", mat = Enum.Material.Slate, color = Color3.fromRGB(70, 74, 86), hp = 10, mult = 2 },
	{ id = "bardeau", name = "Bardeaux", item = "planks", mat = Enum.Material.WoodPlanks, color = Color3.fromRGB(110, 76, 48), hp = 5, mult = 2 },
	{ id = "fer", name = "Fer", item = "iron_ingot", mat = Enum.Material.Metal, color = Color3.fromRGB(92, 94, 100), hp = 16, mult = 1 },
}
C.BUILD_SHAPES = {
	{ id = "bloc", name = "Bloc", shape = "block", size = Vector3.new(2, 2, 2), cost = 2, mats = { "bois", "pierre", "brique", "verre", "rondin", "taille", "torchis", "pise" } },
	{ id = "dalle", name = "Dalle", shape = "block", size = Vector3.new(2, 0.5, 2), cost = 1, mats = { "bois", "pierre", "chaume", "taille", "pise", "tuile", "ardoise", "bardeau" } },
	{ id = "plancher", name = "Grande dalle", shape = "block", size = Vector3.new(4, 0.5, 4), cost = 2, mats = { "bois", "pierre", "taille" } },
	{ id = "mur", name = "Pan de mur", shape = "block", size = Vector3.new(4, 4, 0.5), cost = 3, mats = { "bois", "pierre", "brique", "verre", "rondin", "taille", "torchis", "pise" } },
	{ id = "demimur", name = "Muret", shape = "block", size = Vector3.new(4, 2, 0.5), cost = 2, mats = { "bois", "pierre", "brique", "rondin", "taille", "pise" } },
	{ id = "poutre", name = "Poutre", shape = "block", size = Vector3.new(0.6, 0.6, 4), cost = 1, mats = { "bois", "pierre", "rondin", "fer" } },
	{ id = "poteau", name = "Poteau", shape = "block", size = Vector3.new(0.6, 4, 0.6), cost = 1, mats = { "bois", "rondin", "fer" } },
	{ id = "pilier", name = "Pilier rond", shape = "pillar", size = Vector3.new(1.2, 4, 1.2), cost = 2, mats = { "bois", "pierre", "brique", "rondin", "taille" } },
	{ id = "pente", name = "Pente de toit", shape = "wedge", size = Vector3.new(4, 2, 4), cost = 3, mats = { "bois", "pierre", "chaume", "tuile", "ardoise", "bardeau" } },
	{ id = "coin", name = "Coin de toit", shape = "corner", size = Vector3.new(4, 2, 4), cost = 2, mats = { "bois", "pierre", "chaume", "tuile", "ardoise", "bardeau" } },
	{ id = "rampe", name = "Rampe / marches", shape = "wedge", size = Vector3.new(4, 4, 4), cost = 4, mats = { "bois", "pierre", "taille" } },
	{ id = "barriere", name = "Barrière", shape = "block", size = Vector3.new(4, 1.6, 0.3), cost = 1, mats = { "bois", "fer" } },
	{ id = "grandmur", name = "Grand mur", shape = "block", size = Vector3.new(8, 4, 0.5), cost = 5, mats = { "bois", "pierre", "brique", "rondin", "taille", "torchis", "pise" } },
	{ id = "mince", name = "Cloison", shape = "block", size = Vector3.new(4, 4, 0.2), cost = 1, mats = { "bois", "torchis", "verre" } },
	{ id = "linteau", name = "Linteau", shape = "block", size = Vector3.new(4, 0.8, 0.6), cost = 1, mats = { "bois", "pierre", "taille", "fer" } },
	{ id = "marche", name = "Marche", shape = "block", size = Vector3.new(4, 1, 1.4), cost = 1, mats = { "bois", "pierre", "taille" } },
	{ id = "hautpoteau", name = "Grand poteau", shape = "block", size = Vector3.new(0.6, 8, 0.6), cost = 2, mats = { "bois", "rondin", "fer" } },
	{ id = "colonne", name = "Colonne", shape = "pillar", size = Vector3.new(1.6, 8, 1.6), cost = 4, mats = { "pierre", "taille", "brique" } },
	{ id = "toitpointu", name = "Pente raide", shape = "wedge", size = Vector3.new(4, 4, 2), cost = 2, mats = { "bois", "chaume", "taille", "tuile", "ardoise", "bardeau" } },
	{ id = "grille", name = "Grille", shape = "block", size = Vector3.new(4, 4, 0.2), cost = 2, mats = { "fer" } },
	-- 18/11 : échelles grimpables (treillis Roblox : largeur 2, hauteur multiple de 2)
	{ id = "echelle", name = "Échelle", shape = "ladder", size = Vector3.new(2, 4, 2), cost = 2, mats = { "bois", "rondin", "fer" } },
	{ id = "grandeechelle", name = "Grande échelle", shape = "ladder", size = Vector3.new(2, 8, 2), cost = 3, mats = { "bois", "rondin", "fer" } },
	-- 18/11 : pièces composées (plusieurs blocs, une seule pièce à poser / reprendre / casser)
	{ id = "arche", name = "Arche", shape = "arch", size = Vector3.new(4, 4, 0.6), cost = 4, mats = { "pierre", "brique", "taille", "bois" } },
	{ id = "murcourbe", name = "Mur courbe", shape = "curve", size = Vector3.new(4, 4, 4), cost = 5, mats = { "pierre", "brique", "taille", "bois", "torchis" } },
	-- 19/11 (« liste items.txt » : escaliers, dômes, toits ronds, murs percés, créneaux)
	{ id = "escalier", name = "Escalier droit", shape = "stairs", size = Vector3.new(4, 4, 4), cost = 4, mats = { "bois", "pierre", "taille", "brique" } },
	{ id = "colimacon", name = "Escalier en colimaçon", shape = "spiral", size = Vector3.new(4, 8, 4), cost = 8, mats = { "bois", "pierre", "taille" } },
	{ id = "dome", name = "Dôme", shape = "dome", size = Vector3.new(4, 2, 4), cost = 5, mats = { "pierre", "taille", "brique", "ardoise", "tuile", "fer", "verre" } },
	{ id = "toitconique", name = "Toit conique", shape = "cone", size = Vector3.new(4, 4, 4), cost = 5, mats = { "chaume", "ardoise", "tuile", "bardeau", "bois" } },
	{ id = "murfenetre", name = "Mur avec fenêtre", shape = "windowwall", size = Vector3.new(4, 4, 0.5), cost = 3, mats = { "bois", "pierre", "brique", "rondin", "taille", "torchis", "pise" } },
	{ id = "murporte", name = "Mur avec porte", shape = "doorwall", size = Vector3.new(4, 4, 0.5), cost = 3, mats = { "bois", "pierre", "brique", "rondin", "taille", "torchis", "pise" } },
	{ id = "meurtriere", name = "Mur à meurtrière", shape = "slitwall", size = Vector3.new(4, 4, 0.6), cost = 3, mats = { "pierre", "taille", "brique" } },
	{ id = "pignon", name = "Pignon (mur triangulaire)", shape = "gable", size = Vector3.new(4, 2, 0.5), cost = 2, mats = { "bois", "pierre", "brique", "torchis", "pise", "taille" } },
	{ id = "creneaux", name = "Créneaux", shape = "battlement", size = Vector3.new(4, 1.6, 0.8), cost = 3, mats = { "pierre", "taille", "brique", "bois" } },
	{ id = "chapiteau", name = "Chapiteau", shape = "capital", size = Vector3.new(2.2, 1, 2.2), cost = 2, mats = { "pierre", "taille", "bois" } },
}

-- Formes composées : liste de { taille, décalage } dans le repère de la pièce (centre = 0).
-- Partagées par le serveur (Batir) et le fantôme de construction (Interface) : même dessin.
C.SHAPE_PARTS = {
	-- arche : deux montants, neuf claveaux en demi-cercle (ouverture 2,4 × 3,2), deux remplissages
	arch = function(size: Vector3)
		local t = size.Z
		local out = {
			{ Vector3.new(0.8, size.Y, t), CFrame.new(-1.6, 0, 0) },
			{ Vector3.new(0.8, size.Y, t), CFrame.new(1.6, 0, 0) },
		}
		for k = 0, 8 do
			local a = k / 8 * math.pi
			table.insert(out, { Vector3.new(0.8, 0.74, t), CFrame.new(math.cos(a) * 1.6, math.sin(a) * 1.6, 0) * CFrame.Angles(0, 0, a) })
		end
		table.insert(out, { Vector3.new(0.7, 0.5, t), CFrame.new(-0.95, 1.75, 0) })
		table.insert(out, { Vector3.new(0.7, 0.5, t), CFrame.new(0.95, 1.75, 0) })
		return out
	end,
	-- mur courbe : quart de cercle de rayon 3,75 autour du coin (−2, −2), six segments
	curve = function(size: Vector3)
		local out = {}
		local r, n = 3.75, 6
		local seg = r * (math.pi / 2) / n + 0.1
		for k = 0, n - 1 do
			local a = (k + 0.5) / n * math.pi / 2
			local pos = Vector3.new(-2 + math.cos(a) * r, 0, -2 + math.sin(a) * r)
			local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
			table.insert(out, { Vector3.new(0.5, size.Y, seg), CFrame.lookAt(pos, pos + tangent) })
		end
		return out
	end,
}
-- 19/11 : une sous-pièce peut porter une 3e valeur, sa forme Roblox : "cyl" (cylindre, axe X) ou
-- "wedge" (coin). Aide commune : disques empilés (dôme, toit conique), marches, murs percés.
local VERT = CFrame.Angles(0, 0, math.pi / 2) -- un cylindre debout (son axe X devient vertical)
local function disc(y: number, d: number, h: number)
	return { Vector3.new(h, d, d), CFrame.new(0, y, 0) * VERT, "cyl" }
end
-- mur percé : une ouverture (largeur w, hauteur h, bas à y0 depuis le pied du mur)
local function holed(size: Vector3, w: number, h: number, y0: number)
	local W, H, T = size.X, size.Y, size.Z
	local base, side = -H / 2, (W - w) / 2
	local out = {
		{ Vector3.new(side, H, T), CFrame.new(-W / 2 + side / 2, 0, 0) },
		{ Vector3.new(side, H, T), CFrame.new(W / 2 - side / 2, 0, 0) },
	}
	local top = H - y0 - h
	if top > 0.01 then
		table.insert(out, { Vector3.new(w, top, T), CFrame.new(0, base + y0 + h + top / 2, 0) })
	end
	if y0 > 0.01 then
		table.insert(out, { Vector3.new(w, y0, T), CFrame.new(0, base + y0 / 2, 0) })
	end
	return out
end
C.SHAPE_PARTS.stairs = function(size: Vector3)
	local out, n = {}, 4
	local sh, sd = size.Y / n, size.Z / n
	for k = 0, n - 1 do
		-- chaque marche va jusqu'au sol : un escalier plein, sans vide dessous
		local h = sh * (k + 1)
		table.insert(out, { Vector3.new(size.X, h, sd), CFrame.new(0, -size.Y / 2 + h / 2, size.Z / 2 - sd * (k + 0.5)) })
	end
	return out
end
C.SHAPE_PARTS.spiral = function(size: Vector3)
	local out = { { Vector3.new(size.Y, 0.8, 0.8), CFrame.new(0, 0, 0) * VERT, "cyl" } } -- noyau central
	local n = 12
	local r = size.X / 2
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local y = -size.Y / 2 + (k + 0.5) * size.Y / n
		local cf = CFrame.new(0, y, 0) * CFrame.Angles(0, -a, 0) * CFrame.new(r / 2, 0, 0)
		table.insert(out, { Vector3.new(r, 0.3, 1.2), cf })
	end
	return out
end
C.SHAPE_PARTS.dome = function(size: Vector3)
	local out, n = {}, 5
	local R = size.X / 2
	local h = size.Y / n
	for k = 0, n - 1 do
		local y = (k + 0.5) * h
		local d = 2 * math.sqrt(math.max(0.05, R * R - (y / size.Y * R) ^ 2))
		table.insert(out, disc(-size.Y / 2 + y, d, h + 0.02))
	end
	return out
end
C.SHAPE_PARTS.cone = function(size: Vector3)
	local out, n = {}, 7
	local h = size.Y / n
	for k = 0, n - 1 do
		local d = math.max(0.3, size.X * (1 - (k + 0.5) / n))
		table.insert(out, disc(-size.Y / 2 + (k + 0.5) * h, d, h + 0.02))
	end
	return out
end
C.SHAPE_PARTS.windowwall = function(size: Vector3)
	return holed(size, 1.6, 1.4, 1.6)
end
C.SHAPE_PARTS.doorwall = function(size: Vector3)
	return holed(size, 1.8, 3, 0)
end
C.SHAPE_PARTS.slitwall = function(size: Vector3)
	return holed(size, 0.35, 1.6, 1.4)
end
C.SHAPE_PARTS.gable = function(size: Vector3)
	-- deux coins dos à dos : un triangle de la largeur du mur
	local hw = size.X / 2
	return {
		-- le côté haut d'un coin est vers son +Z : on le tourne vers le milieu (la pointe du pignon)
		{ Vector3.new(size.Z, size.Y, hw), CFrame.new(-hw / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), "wedge" },
		{ Vector3.new(size.Z, size.Y, hw), CFrame.new(hw / 2, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), "wedge" },
	}
end
C.SHAPE_PARTS.battlement = function(size: Vector3)
	local baseH = size.Y * 0.45
	local mh = size.Y - baseH
	local out = { { Vector3.new(size.X, baseH, size.Z), CFrame.new(0, -size.Y / 2 + baseH / 2, 0) } }
	for _, x in { -size.X * 0.3, size.X * 0.3 } do
		table.insert(out, { Vector3.new(size.X * 0.3, mh, size.Z), CFrame.new(x, size.Y / 2 - mh / 2, 0) })
	end
	return out
end
C.SHAPE_PARTS.capital = function(size: Vector3)
	return {
		{ Vector3.new(size.X, size.Y * 0.4, size.Z), CFrame.new(0, size.Y * 0.3, 0) },
		{ Vector3.new(size.Y * 0.6, size.X * 0.75, size.Z * 0.75), CFrame.new(0, -size.Y * 0.2, 0) * VERT, "cyl" },
	}
end
-- crée une sous-pièce (serveur et fantôme) : bloc, cylindre ou coin selon sp[3]
function C.makeSubPart(sp)
	local c
	if sp[3] == "wedge" then
		c = Instance.new("WedgePart")
	else
		c = Instance.new("Part")
		if sp[3] == "cyl" then
			c.Shape = Enum.PartType.Cylinder
		end
	end
	c.Size = sp[1]
	return c
end

C.BLOCKS = {}
C.BLOCK_ORDER = {}
for _, m in C.BUILD_MATERIALS do
	for _, sh in C.BUILD_SHAPES do
		if table.find(sh.mats, m.id) then
			local id = sh.id .. "_" .. m.id
			C.BLOCKS[id] = {
				id = id, name = sh.name .. " (" .. m.name .. ")", shape = sh.shape, size = sh.size, mat = m.mat, color = m.color,
				transp = m.transp, hp = m.hp, cost = { [m.item] = sh.cost * m.mult }, material = m.id, shapeId = sh.id,
			}
			table.insert(C.BLOCK_ORDER, id)
		end
	end
end

-- Nom / icône d'un ingrédient (objet ou groupe)
function C.needInfo(id: string)
	return C.ITEMS[id] or C.GROUP_NAMES[id] or { name = id, icon = "❔" }
end

-- Boutique (ce que vend le marchand)
C.SHOP = { "seed_parsnip", "seed_carrot", "seed_potato", "seed_wheat", "seed_tomato", "seed_melon", "seed_beetroot", "seed_eggplant", "seed_pumpkin",
	"hoe", "can", "axe", "pickaxe", "shovel", "rod", "sword", "coal", "planks", "rope", "tourelle", "baliste", "bolt", "bolt_heavy" }

-- Monde LIBRE (choix du joueur, 18/11) -----------------------------------------------
-- Aucune règle d'arbitre : on bâtit, creuse, casse, vole et se bat PARTOUT, chez les autres aussi,
-- même quand ils sont déconnectés. Ce qui protège : ce que les joueurs mettent en place (serrures,
-- chiens de garde, alarme, TOURELLES) et les conséquences du monde (témoins, étoiles, primes).
-- Les anciennes protections d'arbitre restent ici, coupées, pour pouvoir en rallumer une.
C.LIBRE = {
	batirChezAutrui = true, -- poser, bâtir, semer, bêcher sur la parcelle d'un autre
	terrasserPartout = true, -- creuser / remblayer hors de ses terres
	-- reste coupé : une parcelle sur un village + des balistes = un joueur qui tue tout le monde au village
	parcelleProcheVillage = false, -- planter son panneau de propriété dans / contre un village
	videCoffreAutrui = true, -- « tout prendre » dans le coffre d'un autre (c'est un vol)
	etalEtPanneauVolables = true, -- arracher l'étal ou le panneau de propriété d'un autre (vol)
	zoneSureArrivee = false, -- pas de combat près du point d'arrivée
	bouclierArrivee = false, -- 20 s sans combat entre joueurs en arrivant
	graceApresKO = false, -- 10 min sans pouvoir refrapper celui qu'on vient de mettre K.O.
}

-- Tourelles de défense : tirent sur les intrus qui sont SUR les terres de leur propriétaire (jamais
-- sur lui, son clan, son groupe ni ceux qu'il a autorisés), même quand il est déconnecté. Il faut
-- les garnir de carreaux (une munition par tir) ; à court de munitions, elles se taisent. Elles ne se
-- ramassent pas chez un autre : il faut les casser (pioche, hache), sous leurs tirs.
C.TURRETS = {
	{ range = 30, cooldown = 3, dmg = 45, ammo = "bolt", cap = 40 }, -- arbalète de garde
	{ range = 42, cooldown = 5, dmg = 100000, ammo = "bolt_heavy", cap = 12 }, -- baliste : tue d'un coup
}

-- Justice ------------------------------------------------------------------------
C.MAX_STARS = 5
C.STAR_DECAY = 25 -- secondes sans être vu par un shérif ou un témoin pour perdre 1 étoile
C.SUSPECT_WINDOW = 90 -- minutes de jeu : vu près de la victime peu avant = suspect
C.SUSPECT_RADIUS = 40 -- studs
C.CRIMES = {
	theft = { stars = 1, honor = 5, opinion = 25 },
	breakin = { stars = 1, honor = 8, opinion = 30 },
	assault = { stars = 2, honor = 10, opinion = 50 },
	ko = { stars = 5, honor = 40, opinion = 100 }, -- PNJ assommé (version adoucie du meurtre)
	vandalism = { stars = 1, honor = 6, opinion = 30 }, -- casser une maison, le décor, l'objet d'un autre
}
C.FINE_PER_STAR = 40

-- PNJ ----------------------------------------------------------------------------
C.NPC_WALK = 8
C.NPC_RUN = 18
C.SHERIFF_RUN = 21
C.ADMINS = {} -- UserIds administrateurs en plus du créateur du jeu (commandes /wa)
C.SIGHT = 34 -- studs, de jour
C.NIGHT_SIGHT = 18
C.BARK_COOLDOWN = 30


-- Catalogue médiéval complet (objets, recettes, équipement) : Shared/Catalogue
Catalogue.apply(C)
C.Catalogue = Catalogue
-- Prises de créatures (18/11) : une matière propre à chaque bête + la pièce d'équipement qu'on en
-- tire ; âmes des boss → pièces légendaires (Shared/Prises, butin : Enemies)
C.Prises = require(script.Parent.Prises)
C.Prises.apply(C)

-- Pièces de construction (façon Minecraft) : on les FABRIQUE à l'atelier, elles vont dans le sac,
-- puis on les pose une à une depuis la main (barre rapide). Bois, rondins, chaume, torchis, pisé :
-- à la main ; pierre, brique, verre, fer… : à l'établi.
local SHAPE_ICON = {
	bloc = "⬛", dalle = "🟫", plancher = "🟫", mur = "🧱", demimur = "🧱", grandmur = "🧱", mince = "🧱", poutre = "📏", linteau = "📏",
	poteau = "🏛️", hautpoteau = "🏛️", pilier = "🏛️", colonne = "🏛️", pente = "🔺", coin = "🔺", toitpointu = "🔺", rampe = "📐",
	marche = "📐", barriere = "➖", grille = "🔲", arche = "🌉", murcourbe = "🧱",
	escalier = "📐", colimacon = "🌀", dome = "🔵", toitconique = "⛺", murfenetre = "🔳", murporte = "🚪",
	meurtriere = "🏰", pignon = "🔺", creneaux = "🏰", chapiteau = "🏛️",
}
local HAND_MATS = { bois = true, rondin = true, chaume = true, torchis = true, pise = true }
for _, id in C.BLOCK_ORDER do
	local b = C.BLOCKS[id]
	local item = "blk_" .. id
	b.item = item
	local price = 0
	for it, n in b.cost do
		price += ((C.ITEMS[it] and C.ITEMS[it].price) or 1) * n
	end
	C.ITEMS[item] = { name = b.name, icon = SHAPE_ICON[b.shapeId] or "🧱", price = price, block = id }
	table.insert(C.RECIPES, { item = item, needs = table.clone(b.cost), station = (not HAND_MATS[b.material]) and "bench" or nil, cat = "construction" })
end

-- Artisanat façon Minecraft : on pose des ingrédients dans une grille, ce qui sort dépend du
-- mélange (les quantités comptent, pas les positions). Au départ on ne connaît que quelques recettes ;
-- les autres se découvrent en essayant (ou avec une « Recette inconnue », un « Plan d'artisan »).
C.STARTER_RECIPES = { planks = true, rope = true, club = true, workbench = true, campfire = true, fence = true, blk_bloc_bois = true, blk_dalle_bois = true, blk_mur_bois = true }
function C.recipeKey(r): string
	return r.item or ("gear:" .. r.gear.name)
end
-- counts = { [objet] = quantité } -> toutes les recettes possibles { {i, k} } (même mélange ×k =
-- k fabrications), les correspondances exactes d'abord. Plusieurs résultats : le joueur choisit.
function C.matchGridAll(counts)
	local out = {}
	if next(counts) == nil then
		return out
	end
	for i, r in C.RECIPES do
		local k, ok, used = nil, true, {}
		for need, q in r.needs do
			local have = 0
			local group = C.ITEM_GROUPS[need]
			if group then
				for _, it in group do
					if counts[it] then
						have += counts[it]
						used[it] = true
					end
				end
			else
				have = counts[need] or 0
				used[need] = true
			end
			if have == 0 or have % q ~= 0 then
				ok = false
				break
			end
			local kk = have // q
			if k == nil then
				k = kk
			elseif k ~= kk then
				ok = false
				break
			end
		end
		if ok and k then
			for id in counts do
				if not used[id] then
					ok = false
					break
				end
			end
			if ok then
				table.insert(out, { i, k })
			end
		end
	end
	table.sort(out, function(a, b)
		if a[2] ~= b[2] then
			return a[2] < b[2]
		end
		return a[1] < b[1]
	end)
	return out
end
function C.matchGrid(counts)
	local m = C.matchGridAll(counts)[1]
	if m then
		return m[1], m[2]
	end
	return nil, 0
end

-- 18/11 : fers à cheval (enclume) — ferrer SA monture : +12 % d'allure, pour de bon. Ajoutés EN
-- DERNIER : les indices des recettes existantes ne bougent pas.
C.ITEMS.horseshoes = { name = "Fers à cheval", icon = "🧲", price = 90, use = "cat_ferrer" }
table.insert(C.RECIPES, { item = "horseshoes", needs = { iron_ingot = 2, nails = 4 }, station = "anvil", cat = "outils", skill = { "artisanat", 8 } })
C.SHOD_BONUS = 1.12

-- Rareté de chaque objet (une fois que tous les objets existent)
Catalogue.assignRarity(C)

return C
