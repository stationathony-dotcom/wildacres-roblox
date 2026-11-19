-- Quêtes FACULTATIVES (idées : « liste quetes.txt »). Rien n'est obligatoire : on les prend si on veut,
-- on les lâche quand on veut, aucune n'est nécessaire pour avancer.
-- Chaque village propose 3 quêtes, renouvelées tous les 2 jours, tirées de la graine de l'île : elles
-- dépendent de son biome, de ses cultures, de la faune PROPRE à l'île (Bestiaire.islandPool) et des
-- autres villages (lettres). Deux îles n'ont donc pas les mêmes quêtes.
-- Sortes : apporter (objets rendus au village), chasser, abattre, miner, pêcher, récolter, fabriquer,
-- semer, vendre, découvrir (nouveaux lieux), lettre (à porter dans un autre village).
-- Récompense : or + XP de la compétence liée (donc des caractéristiques) + parfois un objet + honneur.
-- État : G.world.players[uid].quetes = { act = { [id] = quête }, fait = { [idOffre] = jour } } (monde).
-- OÙ (18/11, à sa demande) : comme dans WoW, on PREND et on REND une quête au TABLEAU DES QUÊTES du
-- village ou auprès de N'IMPORTE QUEL HABITANT de ce village (« Tu as du travail ? »). Les quêtes
-- appartiennent au village, pas à un PNJ : si l'un est assommé, un autre prend le relais. Si le
-- village est déserté (plus aucun habitant debout : tous assommés, partis…), il ne propose plus rien
-- et les quêtes qu'il avait données sont TRANSFÉRÉES : on peut les rendre dans un autre village.
-- Le journal [J] ne montre que les quêtes en cours (pas d'offres à distance).
-- Client : action « quetes » → Fx « quetes » (quêtes en cours + offres si on est au tableau / face à
-- un habitant) ; « quete_prendre », « quete_rendre », « quete_lacher ».

local Quetes = {}
local G, Config

local PER_VILLAGE = 3
local SESSION_S = 300 -- une conversation / un tableau ouvert reste valable 5 min…
local SESSION_D = 18 -- …tant qu'on reste à moins de 18 studs
local PERIOD = 2 -- jours
local NEAR = 110 -- studs autour de la place du village

local SKILL_OF = {
	tuer = "combat", abattre = "bucheronnage", miner = "minage", pecher = "peche", recolter = "agriculture",
	fabriquer = "artisanat", semer = "agriculture", vendre = "commerce", apporter = "commerce", lettre = "commerce", decouvrir = "commerce",
	collecter = "elevage", naviguer = "peche",
	batir = "artisanat", apprivoiser = "dressage", prime = "combat",
}
local ICON = { tuer = "⚔️", abattre = "🪓", miner = "⛏️", pecher = "🎣", recolter = "🌾", semer = "🌱", vendre = "💰", fabriquer = "🛠️", apporter = "📦", lettre = "✉️", decouvrir = "🧭", collecter = "🥛", naviguer = "⛵", batir = "🧱", apprivoiser = "🐾", prime = "⚖️" }
Quetes.VOYAGE_DISTANCE = 150 -- studs ramés d'affilée = une traversée (Barques)

-- ---------------------------------------------------------------- villages de l'île

local villagesCache
local function villages()
	if villagesCache and villagesCache.seed == G.world.seed then
		return villagesCache.list
	end
	local list = {}
	local R = Config.WORLD_RADIUS
	for rx = -R, R do
		for rz = -R, R do
			if G.WG.inWorld(rx, rz) then
				local poi = G.wg:poiOf(rx, rz)
				if poi and poi.kind == "village" then
					table.insert(list, {
						key = rx .. "," .. rz, name = poi.name, biome = poi.biome,
						x = poi.ax * Config.CELL + Config.CELL / 2, z = poi.az * Config.CELL + Config.CELL / 2,
					})
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.key < b.key
	end)
	villagesCache = { seed = G.world.seed, list = list }
	return list
end
Quetes.villages = villages

local function villageByKey(key: string)
	for _, v in villages() do
		if v.key == key then
			return v
		end
	end
	return nil
end

local function nearVillage(player: Player)
	local root = G.Util.root(player)
	if not root then
		return nil
	end
	local best, bd = nil, NEAR
	for _, v in villages() do
		local d = Vector2.new(root.Position.X - v.x, root.Position.Z - v.z).Magnitude
		if d < bd then
			best, bd = v, d
		end
	end
	return best
end
Quetes.nearVillage = nearVillage

-- ---------------------------------------------------------------- tableaux, habitants, sessions

local boards = {} -- clé village -> pièce du tableau (posée par Villages)
local sessions = {} -- joueur -> { v = clé village, t = os.clock(), part = BasePart?, npc = id? }

function Quetes.registerBoard(vkey: string, part: BasePart)
	boards[vkey] = part
end

-- habitants debout du village (nil si la région n'est pas chargée : personne n'est là pour voir)
local function standing(vkey: string): number?
	if not (G.World.loaded and G.World.loaded[vkey]) then
		return nil
	end
	local Npcs = G.Npcs
	return Npcs and Npcs.standingIn and Npcs.standingIn(vkey) or nil
end
-- village déserté : chargé, et plus un habitant debout
local function deserted(vkey: string): boolean
	local n = standing(vkey)
	return n ~= nil and n == 0
end
Quetes.deserted = deserted

-- la quête peut-elle être rendue ici ? (village d'origine, ou transférée si l'origine est déserte)
local function receivable(q, here): (boolean, boolean)
	if not here then
		return false, false
	end
	local giver = q.kind == "lettre" and q.key or q.v
	if here.key == giver then
		return true, false
	end
	return deserted(giver), true
end

-- session encore valable (assez près du tableau / de l'habitant, pas trop vieille) ?
local function session(player: Player)
	local s = sessions[player]
	if not s or os.clock() - s.t > SESSION_S then
		sessions[player] = nil
		return nil
	end
	local root = G.Util.root(player)
	local at = nil
	if s.npc then
		local e = G.Npcs.byId and G.Npcs.byId(s.npc)
		local st = e and e.state
		if not e or not e.model.Parent or st == "ko" or st == "carried" or st == "gone" then
			sessions[player] = nil
			return nil
		end
		at = e.root.Position
	elseif s.part and s.part.Parent then
		at = s.part.Position
	end
	if not root or not at or (root.Position - at).Magnitude > SESSION_D then
		sessions[player] = nil
		return nil
	end
	return villageByKey(s.v)
end

-- ---------------------------------------------------------------- génération des offres

local function exists(id: string): boolean
	return G.Config.ITEMS[id] ~= nil
end
local function pick(r: Random, list)
	return list[r:NextInteger(1, #list)]
end
local function pickExisting(r: Random, list)
	local ok = {}
	for _, id in list do
		if exists(id) then
			table.insert(ok, id)
		end
	end
	return #ok > 0 and pick(r, ok) or nil
end

-- demandes « apporter » : { titre, objets possibles, quantité min, max }
local WANTS = {
	{ "Un nouveau départ", { "wood" }, 10, 10 },
	{ "La pierre est précieuse", { "stone" }, 10, 10 },
	{ "Le boulanger est débordé", { "flour", "wheat" }, 8, 16 },
	{ "Le forgeron manque de métal", { "copper_ore", "ore", "copper_ingot", "iron_ingot" }, 5, 12 },
	{ "Le charpentier a besoin d'aide", { "planks", "wood" }, 12, 24 },
	{ "La livraison de tissus", { "cloth", "wool", "linen" }, 3, 8 },
	{ "Un repas pour les voyageurs", { "bread", "grilled_fish", "soup", "omelette" }, 3, 6 },
	{ "Le garde fatigué", { "bread", "apple", "rations" }, 2, 5 },
	{ "La vieille maison", { "stone", "planks", "nails" }, 10, 20 },
	{ "La fête approche", { "flowers", "ribbon", "honey" }, 3, 6 },
	{ "Le vétérinaire", { "herbs", "chamomile", "mint" }, 3, 8 },
	-- idées de la production du 18→19/11, remises en données (tirées comme les autres)
	{ "Le chantier communal", { "brick" }, 8, 16 },
	{ "Le chantier du pont", { "wood", "planks" }, 30, 50 },
	{ "Le fer recherché", { "ore", "iron_ingot" }, 10, 20 },
	{ "La commande du forgeron", { "copper_ingot", "iron_ingot", "nails" }, 5, 10 },
}
local CRAFTS = { "rope", "planks", "bread", "nails", "torch", "bucket_empty", "basket", "fishing_rod", "lantern", "axe", "pickaxe", "bed",
	"steak", "stew", "linen", "wool_cloth", "bottle", "blk_bloc_pierre" }
-- commandes nommées : { titre, quantité min, max } (sinon titre au hasard, 1 à 4)
local CRAFT_SPECS = {
	axe = { "Premiers outils", 1, 1 },
	pickaxe = { "Un outil indispensable", 1, 1 },
	bed = { "Un endroit où dormir", 1, 1 },
	steak = { "Le premier repas", 1, 1 },
	bread = { "Le banquet du village", 10, 20 },
	stew = { "Le plat régional", 1, 2 },
	linen = { "Le tisserand", 2, 4 },
	wool_cloth = { "Le tisserand", 2, 4 },
	bottle = { "Le verrier débutant", 1, 3 },
	blk_bloc_pierre = { "Le maçon", 15, 30 },
}
local KILL_TITLES = { "Une bête rôde près de {v}", "La chasse du village", "Les troupeaux en danger", "Nettoyer les chemins" }

local function sub(s: string, v): string
	return (string.gsub(s, "{v}", v.name))
end

local function reward(r: Random, base: number)
	local danger = G.world.danger or 1
	return math.floor(base * (0.8 + 0.2 * danger) * r:NextNumber(0.9, 1.2))
end

-- une offre déterministe : même île + même village + même période = même quête pour tous
local function makeOffer(v, period: number, i: number)
	local r = Random.new(G.WG.hash(G.world.seed, "quete", v.key, period, i))
	local theme = G.wg and G.wg.theme
	local roll = r:NextNumber()
	local q = { v = v.key, vname = v.name }
	if roll < 0.24 then
		local w = WANTS[r:NextInteger(1, #WANTS)]
		local item = pickExisting(r, w[2])
		local crops = Config.BIOME_CROPS[v.biome]
		if (not item or r:NextNumber() < 0.35) and crops and #crops > 0 then
			item = pick(r, crops)
			w = { "Des légumes frais", {}, 6, 14 }
		end
		if not item then
			item = "wood"
		end
		q.kind, q.key, q.need = "apporter", item, r:NextInteger(w[3], w[4])
		q.title = w[1]
		q.gold = reward(r, 6 + (Config.ITEMS[item].price or 4) * q.need * 0.6)
	elseif roll < 0.44 then
		local pool = G.Bestiaire.islandPool(G.world.seed, theme, G.Bestiaire.DAY[v.biome] or G.Bestiaire.DAY.prairie, v.biome)
		local kind = pick(r, pool)
		local sig = G.Bestiaire.signature(G.world.seed, theme)
		local k = G.Bestiaire.KINDS[kind] or {}
		q.kind, q.key, q.need = "tuer", kind, k.pack and r:NextInteger(3, 6) or r:NextInteger(2, 4)
		q.title = kind == sig and "La terreur de l'île" or sub(pick(r, KILL_TITLES), v)
		q.label = k.name or kind
		q.gold = reward(r, 30 + (k.level or 2) * 18 * q.need)
	elseif roll < 0.54 then
		q.kind, q.key, q.need, q.title = "abattre", "tree", r:NextInteger(6, 14), "Le bois du charpentier"
		q.gold = reward(r, 8 * q.need)
	elseif roll < 0.64 then
		q.kind, q.key, q.need, q.title = "miner", "ore", r:NextInteger(5, 12), pick(r, { "Le minerai de cuivre", "Les profondeurs de la mine", "Le fer recherché" })
		q.gold = reward(r, 12 * q.need)
	elseif roll < 0.66 then
		q.kind, q.key, q.need, q.title = "pecher", "fish", 1, "La première prise"
		q.gold = reward(r, 14)
	elseif roll < 0.72 then
		q.kind, q.key, q.need, q.title = "pecher", "fish", r:NextInteger(3, 8), pick(r, { "Le pêcheur côtier", "Le poisson du vendredi", "La friture du village", "Le repas du pêcheur" })
		q.gold = reward(r, 14 * q.need)
	elseif roll < 0.74 then
		q.kind, q.key, q.need, q.title = "semer", "graine", 5, "La vie à la ferme"
		q.gold = reward(r, 24)
	elseif roll < 0.76 then
		q.kind, q.key, q.need, q.title = "vendre", "boutique", 3, "Un peu de monnaie"
		q.gold = reward(r, 9)
	elseif roll < 0.80 then
		-- plantes sauvages du coin (Systemes/Herbes) : l'herboriste du village, 2 fois sur 5
		local herbs = {}
		local H = rawget(G, "Herbes")
		for _, h in (H and H.POOLS and H.POOLS[v.biome]) or {} do
			if h[2] <= 10 and Config.ITEMS[h[1]] then
				table.insert(herbs, h[1])
			end
		end
		if #herbs > 0 and r:NextNumber() < 0.4 then
			local herb = pick(r, herbs)
			q.kind, q.key, q.need, q.title = "recolter", herb, r:NextInteger(3, 8), pick(r, { "L'herboriste du village", "Les remèdes de la guérisseuse", "Une tisane pour l'ancien" })
			q.gold = reward(r, 14 + (Config.ITEMS[herb].price or 8) * q.need * 1.5)
		else
			local crops = Config.BIOME_CROPS[v.biome] or { "wheat" }
			local crop = pick(r, crops)
			q.kind, q.key, q.need, q.title = "recolter", crop, r:NextInteger(6, 16), pick(r, { "Première récolte", "La grande moisson", "Le champ du boulanger" })
			q.gold = reward(r, 6 * q.need)
		end
	elseif roll < 0.87 then
		local item = pickExisting(r, CRAFTS) or "rope"
		local spec = CRAFT_SPECS[item]
		local n = spec and r:NextInteger(spec[2], spec[3]) or r:NextInteger(1, 4)
		local title = spec and spec[1] or pick(r, { "Apprenti artisan", "La commande surprise", "Le maître artisan" })
		q.kind, q.key, q.need, q.title = "fabriquer", item, n, title
		q.gold = reward(r, 20 + (Config.ITEMS[item].price or 10) * q.need)
	elseif roll < 0.905 then
		-- 19/11 (« liste quetes.txt » : construction, dressage, justice)
		q.kind, q.key, q.need, q.title = "batir", "piece", r:NextInteger(10, 30), pick(r, { "Un abri pour le berger", "La palissade du village", "Le pont du gué", "Un toit pour la fête" })
		q.gold = reward(r, 4 * q.need)
	elseif roll < 0.915 then
		q.kind, q.key, q.need, q.title = "apprivoiser", "bete", 1, pick(r, { "Un compagnon fidèle", "Le dresseur de bêtes", "Une monture pour le messager" })
		q.gold = reward(r, 80)
	elseif roll < 0.92 then
		q.kind, q.key, q.need, q.title = "prime", "recherche", 1, pick(r, { "Justice pour le village", "La tête mise à prix" })
		q.gold = reward(r, 120)
	elseif roll < 0.94 then
		local others = {}
		for _, o in villages() do
			if o.key ~= v.key then
				table.insert(others, o)
			end
		end
		if #others > 0 then
			local t = pick(r, others)
			local d = Vector2.new(t.x - v.x, t.z - v.z).Magnitude
			q.kind, q.key, q.need, q.title = "lettre", t.key, 1, "Une lettre importante"
			q.label = t.name
			q.gold = reward(r, 30 + d / 6)
		else
			q.kind, q.key, q.need, q.title = "decouvrir", "lieu", 3, "À la découverte du monde"
			q.gold = reward(r, 90)
		end
	elseif roll < 0.965 then
		-- produits des bêtes de ferme (Animals.collect) : seulement les siennes, pas celles volées
		local product = pickExisting(r, { "milk", "egg", "wool" }) or "egg"
		local titles = { milk = "La traite du matin", egg = "Les œufs du marché", wool = "La tonte de printemps" }
		q.kind, q.key, q.need, q.title = "collecter", product, r:NextInteger(2, 6), titles[product]
		q.gold = reward(r, 12 + (Config.ITEMS[product].price or 10) * q.need * 0.8)
	elseif roll < 0.98 then
		q.kind, q.key, q.need, q.title = "naviguer", "bateau", r:NextInteger(1, 3), pick(r, { "Le marin débutant", "Le tour de l'île", "Prendre le large" })
		q.gold = reward(r, 40 * q.need)
	else
		q.kind, q.key, q.need, q.title = "decouvrir", "lieu", r:NextInteger(2, 4), pick(r, { "À la découverte du monde", "Un monde immense", "Le cartographe" })
		q.gold = reward(r, 45 * q.need)
	end
	-- parfois un objet en plus (selon l'île : ce que son biome produit)
	if r:NextNumber() < 0.3 then
		local extra = pickExisting(r, { "treasure_map", "manual_farm", "manual_fish", "manual_mine", "coin_purse", "spice", "lockpick", "rare_book" })
		if extra then
			q.item = extra
		end
	end
	q.xp = 10 + math.floor(q.gold / 4)
	q.id = v.key .. ":" .. period .. ":" .. i
	return q
end

-- Commandes du tableau. La rotation est décalée par village et chaque commande
-- possède un identifiant distinct des trois offres historiques.
local VILLAGE_ORDERS = {
	{ title = "Une livraison urgente", item = "bread", count = 5 },
	{ title = "Le puits est vide", item = "bucket", count = 3 },
	{ title = "Le marché du dimanche", item = "stall", count = 1 },
	{ title = "Une maison à réparer", item = "planks", count = 12 },
}

local function villageOrder(v, period: number)
	local seed = G.WG.hash(G.world.seed, "commande_village", v.key)
	local order = VILLAGE_ORDERS[(seed + period) % #VILLAGE_ORDERS + 1]
	local rng = Random.new(G.WG.hash(seed, period))
	local unitPrice = Config.ITEMS[order.item].price or 45
	local gold = reward(rng, 10 + unitPrice * order.count * 0.8)
	return {
		id = v.key .. ":" .. period .. ":commande",
		v = v.key, vname = v.name,
		kind = "apporter", key = order.item, need = order.count,
		title = order.title, gold = gold, xp = 10 + math.floor(gold / 4),
	}
end

function Quetes.offers(v)
	local period = math.floor((G.world.day or 1) / PERIOD)
	local list = {}
	for i = 1, PER_VILLAGE do
		table.insert(list, makeOffer(v, period, i))
	end
	table.insert(list, villageOrder(v, period))
	return list
end

-- ---------------------------------------------------------------- état du joueur

local function rec(player: Player)
	local uid = tostring(player.UserId)
	local r = G.world.players[uid]
	if not r then
		r = {}
		G.world.players[uid] = r
	end
	r.quetes = r.quetes or { act = {}, fait = {} }
	return r.quetes
end

local function what(q): string
	local info = Config.ITEMS[q.key]
	if q.kind == "apporter" then
		return string.format("Apporter %d %s %s à %s", q.need, info and info.icon or "", info and info.name or q.key, q.vname)
	elseif q.kind == "tuer" then
		return string.format("Vaincre %d × %s", q.need, q.label or q.key)
	elseif q.kind == "abattre" then
		return string.format("Abattre %d arbres", q.need)
	elseif q.kind == "miner" then
		return string.format("Miner %d roches ou filons", q.need)
	elseif q.kind == "pecher" then
		if q.need == 1 then
			return "Pêcher un poisson"
		end
		return string.format("Pêcher %d poissons", q.need)
	elseif q.kind == "semer" then
		return string.format("Semer %d graines sur des cases bêchées", q.need)
	elseif q.kind == "collecter" then
		return string.format("Récolter %d %s %s sur tes bêtes de ferme", q.need, info and info.icon or "", info and info.name or q.key)
	elseif q.kind == "batir" then
		return string.format("Poser %d pièces de construction", q.need)
	elseif q.kind == "apprivoiser" then
		return "Apprivoiser une bête (compagnon ou monture)"
	elseif q.kind == "prime" then
		return "Mettre K.O. un recherché et toucher sa prime"
	elseif q.kind == "naviguer" then
		return q.need == 1 and "Faire une traversée en barque (150 studs d'affilée)"
			or string.format("Faire %d traversées en barque (150 studs d'affilée)", q.need)
	elseif q.kind == "vendre" then
		return string.format("Vendre %d objets à un marchand ou à un artisan", q.need)
	elseif q.kind == "recolter" then
		local verb = (Config.CROPS and Config.CROPS[q.key]) and "Récolter" or "Cueillir (plante sauvage)"
		return string.format("%s %d %s %s", verb, q.need, info and info.icon or "", info and info.name or q.key)
	elseif q.kind == "fabriquer" then
		return string.format("Fabriquer %d %s %s", q.need, info and info.icon or "", info and info.name or q.key)
	elseif q.kind == "lettre" then
		return "Porter une lettre au village de " .. (q.label or "?")
	end
	return string.format("Découvrir %d lieux que tu n'as jamais vus", q.need)
end
Quetes.what = what

local function view(q, here)
	local giver = q.kind == "lettre" and q.key or q.v
	return {
		id = q.id, kind = q.kind, icon = ICON[q.kind], title = q.title, what = what(q), need = q.need, got = q.got or 0,
		gold = q.gold, item = q.item, skill = SKILL_OF[q.kind], ready = (q.got or 0) >= q.need or q.kind == "apporter",
		where = q.kind == "lettre" and q.label or q.vname, canTurnIn = (receivable(q, here)), transferred = here ~= nil and here.key ~= giver and deserted(giver),
	}
end

function Quetes.send(player: Player)
	local st = rec(player)
	local here = session(player)
	local data = { actives = {}, village = nil }
	for _, q in st.act do
		table.insert(data.actives, view(q, here))
	end
	table.sort(data.actives, function(a, b)
		return a.id < b.id
	end)
	if here then
		local offers = {}
		local empty = deserted(here.key)
		if not empty then
			for _, q in Quetes.offers(here) do
				if not st.act[q.id] and not st.fait[q.id] then
					table.insert(offers, view(q, nil))
				end
			end
		end
		local s = sessions[player]
		local who = s and s.npc and G.Npcs.byId(s.npc)
		data.village = { name = here.name, offers = offers, deserted = empty, from = who and who.data.name or "Tableau des quêtes" }
	end
	G.remotes.Fx:FireClient(player, "quetes", data)
end

-- ouvre les quêtes du village depuis son tableau
function Quetes.openBoard(player: Player, vkey: string)
	local part = boards[vkey]
	if type(vkey) ~= "string" or not part then
		return
	end
	sessions[player] = { v = vkey, t = os.clock(), part = part }
	Quetes.send(player)
end

-- ouvre les quêtes du village auprès d'un habitant (n'importe lequel : les quêtes sont au village)
function Quetes.openNpc(player: Player, e)
	local vkey = e and e.reg and e.reg.key
	if not vkey or not villageByKey(vkey) then
		return
	end
	sessions[player] = { v = vkey, t = os.clock(), npc = e.id }
	Quetes.send(player)
end

-- un habitant de ce village peut-il parler de quêtes ? (sert au dialogue des PNJ)
function Quetes.isVillage(vkey: string?): boolean
	return vkey ~= nil and villageByKey(vkey) ~= nil
end

function Quetes.take(player: Player, id: string)
	local here = session(player)
	if not here or type(id) ~= "string" then
		return
	end
	local st = rec(player)
	if deserted(here.key) then
		return
	end
	for _, q in Quetes.offers(here) do
		if q.id == id and not st.act[id] and not st.fait[id] then
			q.got = 0
			st.act[id] = q
			if q.kind == "lettre" then
				G.Util.toast(player, "✉️ On te confie une lettre scellée pour " .. (q.label or "?") .. ".")
			end
			G.Util.toast(player, "📜 Quête acceptée : " .. q.title, "big")
			break
		end
	end
	Quetes.send(player)
end

function Quetes.drop(player: Player, id: string)
	local st = rec(player)
	if type(id) == "string" and st.act[id] then
		st.act[id] = nil
		G.Util.toast(player, "Quête abandonnée. Aucune conséquence.")
	end
	Quetes.send(player)
end

function Quetes.turnIn(player: Player, id: string)
	local st = rec(player)
	local q = type(id) == "string" and st.act[id]
	local here = session(player)
	if not q then
		return
	end
	if not here then
		G.Util.toast(player, "Rends ta quête au tableau des quêtes ou à un habitant du village.")
		return
	end
	local ok, transfer = receivable(q, here)
	if not ok then
		G.Util.toast(player, "C'est à " .. (q.kind == "lettre" and q.label or q.vname) .. " qu'on t'attend.")
		return
	end
	if transfer then
		G.Util.toast(player, "📜 Plus personne à " .. (q.kind == "lettre" and q.label or q.vname) .. " : " .. here.name .. " reprend ta quête.")
	end
	if q.kind == "apporter" then
		if not G.Joueurs.has(player, q.key, q.need) then
			G.Util.toast(player, "Il te faut " .. q.need .. " " .. (Config.ITEMS[q.key] and Config.ITEMS[q.key].name or q.key) .. ".")
			return
		end
		G.Joueurs.take(player, q.key, q.need)
	elseif q.kind ~= "lettre" and (q.got or 0) < q.need then
		G.Util.toast(player, "Pas encore : " .. (q.got or 0) .. " / " .. q.need .. ".")
		return
	end
	st.act[id] = nil
	st.fait[id] = G.world.day
	G.Joueurs.add(player, "gold", q.gold)
	-- le village où on la rend t'en sait gré (Systemes/Reputation)
	G.Reputation.add(player, here, math.clamp(3 + math.floor((q.gold or 0) / 40), 3, 10))
	if G.Social and rawget(G.Social, "bump") then G.Social.bump(player, "quests") end
	if q.item then
		G.Joueurs.add(player, q.item, 1)
	end
	G.Joueurs.addSkillXp(player, SKILL_OF[q.kind] or "commerce", q.xp or 10)
	G.Law.addHonor(player, 1)
	if G.Economie and G.Economie.record then
		G.Economie.record(player, "quete", q.title .. " (+" .. q.gold .. ")")
	end
	G.Util.toast(player, "✅ Quête terminée : " .. q.title .. "  (+" .. q.gold .. " or)", "big")
	G.Joueurs.sync(player)
	Quetes.send(player)
end

-- ---------------------------------------------------------------- progression (appelée par les systèmes)

-- Les cultures, objets et espèces ont leurs propres clés. Semis et ventes utilisent
-- les clés fixes « graine » et « boutique ». Les découvertes acceptent tout nouveau lieu.
function Quetes.note(player: Player, kind: string, key: string?, n: number?)
	local st = G.world and G.world.players[tostring(player.UserId)]
	st = st and st.quetes
	if not st then
		return
	end
	for _, q in st.act do
		if q.kind == kind and (q.got or 0) < q.need and (kind == "abattre" or kind == "miner" or kind == "pecher" or kind == "decouvrir" or q.key == key) then
			q.got = math.min(q.need, (q.got or 0) + (n or 1))
			if q.got >= q.need then
				G.Util.toast(player, "📜 « " .. q.title .. " » : c'est fait ! Retourne à " .. q.vname .. ".", "big")
			else
				G.Util.toast(player, string.format("📜 %s : %d / %d", q.title, q.got, q.need))
			end
		end
	end
end

function Quetes.init(g)
	G = g
	Config = G.Config
	G.Interact.onAction("quetes", function(player)
		Quetes.send(player)
	end)
	G.Interact.onPrompt("quetes_tableau", function(player, prompt)
		Quetes.openBoard(player, prompt:GetAttribute("Village"))
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
	G.Interact.onAction("quete_prendre", function(player, data)
		Quetes.take(player, data.id)
	end)
	G.Interact.onAction("quete_rendre", function(player, data)
		Quetes.turnIn(player, data.id)
	end)
	G.Interact.onAction("quete_lacher", function(player, data)
		Quetes.drop(player, data.id)
	end)
end

return Quetes
