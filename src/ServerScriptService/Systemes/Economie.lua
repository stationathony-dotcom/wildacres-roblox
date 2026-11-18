-- Économie entre joueurs et villages (tout validé par le serveur) :
--  · Échange direct entre deux joueurs proches : chacun propose, les deux confirment, l'échange se
--    fait d'un bloc (rien ne change si l'un n'a plus ce qu'il proposait). Toute modification annule
--    les confirmations.
--  · Commandes des villages : chaque village réclame ce que son biome ne produit pas (renouvelées).
--  · Banque de village : coffre impossible à cambrioler, places à agrandir contre de l'or, 2 or de
--    frais par dépôt (l'or sort de l'économie).
--  · Registre : les mouvements importants sont notés ; un gain d'or anormal est signalé.

local Players = game:GetService("Players")

local Economie = {}
local G, Config

local trades = {} -- joueur -> session partagée
local pending = {} -- joueur invité -> qui l'invite
Economie.ledger = {}
local goldWindow = {} -- joueur -> {or gagné, début}
local inviteAt = setmetatable({}, { __mode = "k" }) -- joueur invité -> os.clock() : une invitation expire au bout de 60 s

function Economie.init(g)
	G = g
	Config = G.Config
	G.Interact.onAction("trade_request", function(player, data)
		Economie.request(player, tonumber(data.target))
	end)
	G.Interact.onAction("trade_accept", function(player)
		Economie.accept(player)
	end)
	G.Interact.onAction("trade_offer", function(player, data)
		Economie.offer(player, data.item, tonumber(data.n) or 1)
	end)
	G.Interact.onAction("trade_ready", function(player)
		Economie.ready(player)
	end)
	G.Interact.onAction("trade_cancel", function(player)
		Economie.cancel(player, "Échange annulé.")
	end)
	G.Interact.onAction("order_deliver", function(player, data)
		Economie.deliver(player, data.id)
	end)
	G.Interact.onAction("bank_upgrade", function(player)
		Economie.bankUpgrade(player)
	end)
	G.Interact.onPrompt("stall", function(player, prompt)
		Economie.openStall(player, prompt:GetAttribute("Placed"))
	end)
	G.Interact.onAction("stall_put", function(player, data)
		Economie.stallPut(player, data.id, data.item, tonumber(data.n) or 0, tonumber(data.price))
	end)
	G.Interact.onAction("stall_take", function(player, data)
		Economie.stallTake(player, data.id, data.item)
	end)
	G.Interact.onAction("stall_buy", function(player, data)
		Economie.stallBuy(player, data.id, data.item, tonumber(data.n) or 1)
	end)
	G.Interact.onAction("stall_collect", function(player, data)
		Economie.stallCollect(player, data.id)
	end)
	Players.PlayerRemoving:Connect(function(p)
		Economie.cancel(p, "L'autre joueur est parti.")
		pending[p] = nil
		goldWindow[p] = nil
		if Economie.bankAt then
			Economie.bankAt[p] = nil
		end
	end)
end

-- ----------------------------------------------------------------- Registre

function Economie.record(player: Player?, kind: string, detail: string)
	table.insert(Economie.ledger, { t = os.time(), who = player and player.UserId or 0, kind = kind, detail = detail })
	if #Economie.ledger > 600 then
		table.remove(Economie.ledger, 1)
	end
end

-- Appelé à chaque gain d'or : repère les gains anormaux (sans sanction automatique)
function Economie.goldGained(player: Player, n: number)
	local w = goldWindow[player]
	local now = os.clock()
	if not w or now - w[2] > 300 then
		w = { 0, now }
		goldWindow[player] = w
	end
	w[1] += n
	if w[1] > 6000 and not w.flagged then
		w.flagged = true
		warn(string.format("[WildAcres] gain d'or inhabituel : %s (%d) +%d en 5 min", player.Name, player.UserId, w[1]))
		Economie.record(player, "alerte", "gain d'or inhabituel : " .. w[1])
	end
end

-- ----------------------------------------------------------------- Échange entre joueurs

local function near(a: Player, b: Player): boolean
	local ra, rb = G.Util.root(a), G.Util.root(b)
	return ra ~= nil and rb ~= nil and (ra.Position - rb.Position).Magnitude < 20
end

local function sendTrade(t)
	for _, side in { t.a, t.b } do
		local me = side == t.a and "a" or "b"
		local other = me == "a" and "b" or "a"
		G.remotes.Menu:FireClient(side, {
			kind = "trade", with = t[other].DisplayName,
			mine = t.offer[me], theirs = t.offer[other],
			readyMine = t.ready[me], readyTheirs = t.ready[other],
		})
	end
end

function Economie.request(player: Player, targetId: number?)
	local target = targetId and Players:GetPlayerByUserId(targetId)
	if not target or target == player or not G.Game.isPlaying(target) then
		return
	end
	if G.Admin.blocks and G.Admin.blocks(target, player) then
		G.Util.toast(player, target.DisplayName .. " ne reçoit pas tes propositions.")
		return
	end
	if trades[player] or trades[target] then
		G.Util.toast(player, "L'un de vous est déjà en train d'échanger.")
		return
	end
	if not near(player, target) then
		G.Util.toast(player, "Approche-toi pour échanger.")
		return
	end
	pending[target] = player
	inviteAt[target] = os.clock()
	G.remotes.Menu:FireClient(target, { kind = "trade_invite", from = player.DisplayName })
	G.Util.toast(player, "Proposition d'échange envoyée à " .. target.DisplayName .. ".")
end

function Economie.accept(player: Player)
	local from = pending[player]
	pending[player] = nil
	if from and os.clock() - (inviteAt[player] or 0) > 60 then
		G.Util.toast(player, "Cette proposition d'échange a expiré.")
		return
	end
	if not from or not from.Parent or trades[from] or trades[player] or not near(player, from) then
		return
	end
	local t = { a = from, b = player, offer = { a = {}, b = {} }, ready = { a = false, b = false } }
	trades[from], trades[player] = t, t
	sendTrade(t)
end

local function sideOf(t, player: Player): string
	return t.a == player and "a" or "b"
end

-- Ajoute (n > 0) ou retire (n < 0) un objet de sa proposition ; "gold" pour l'or
function Economie.offer(player: Player, item: string, n: number)
	local t = trades[player]
	if not t or type(item) ~= "string" or not Config.ITEMS[item] then
		return
	end
	local info = Config.ITEMS[item]
	if info.tool and item ~= "gold" then
		G.Util.toast(player, "Les outils ne s'échangent pas (fabrique-les ou achète-les).")
		return
	end
	local me = sideOf(t, player)
	local cur = t.offer[me][item] or 0
	local want = math.clamp(cur + math.floor(n), 0, G.Joueurs.count(player, item))
	t.offer[me][item] = want > 0 and want or nil
	t.ready.a, t.ready.b = false, false -- toute modification annule les confirmations
	sendTrade(t)
end

function Economie.ready(player: Player)
	local t = trades[player]
	if not t then
		return
	end
	t.ready[sideOf(t, player)] = true
	if not (t.ready.a and t.ready.b) then
		sendTrade(t)
		return
	end
	-- vérification complète AVANT de toucher à quoi que ce soit
	if not near(t.a, t.b) then
		Economie.cancel(player, "Vous êtes trop loin l'un de l'autre.")
		return
	end
	for _, side in { "a", "b" } do
		for item, n in t.offer[side] do
			if G.Joueurs.count(t[side], item) < n then
				Economie.cancel(player, "Il manque des objets : échange annulé.")
				return
			end
		end
	end
	-- échange d'un bloc
	local summary = {}
	for _, side in { "a", "b" } do
		local other = side == "a" and "b" or "a"
		for item, n in t.offer[side] do
			G.Joueurs.take(t[side], item, n)
			G.Joueurs.add(t[other], item, n, true)
			table.insert(summary, t[side].Name .. "→" .. n .. " " .. item)
		end
	end
	Economie.record(t.a, "echange", t.a.Name .. " / " .. t.b.Name .. " : " .. table.concat(summary, ", "))
	trades[t.a], trades[t.b] = nil, nil
	for _, p in { t.a, t.b } do
		G.Joueurs.sync(p)
		G.remotes.Menu:FireClient(p, { kind = "trade_end", ok = true })
		G.Util.toast(p, "🤝 Échange conclu !", "gain")
		-- XP seulement pour un vrai échange (quelque chose a changé de main), 5 par jour
		if #summary > 0 then
			G.Joueurs.addSkillXpCapped(p, "commerce", 6, "echange", 5)
		end
	end
end

function Economie.cancel(player: Player, msg: string?)
	local t = trades[player]
	if not t then
		return
	end
	trades[t.a], trades[t.b] = nil, nil
	for _, p in { t.a, t.b } do
		if p.Parent then
			G.remotes.Menu:FireClient(p, { kind = "trade_end", ok = false })
			if msg then
				G.Util.toast(p, msg)
			end
		end
	end
end

-- ----------------------------------------------------------------- Commandes des villages

-- Ce qu'un village peut réclamer : ce que son biome ne produit pas, des plats, des matériaux
local function demandPool(biome: string)
	local pool = {}
	local local_ = {}
	for _, c in Config.BIOME_CROPS[biome] or {} do
		local_[c] = true
	end
	for _, id in Config.CROP_ORDER do
		if not local_[id] then
			table.insert(pool, { id, 4, 10 })
		end
	end
	local extra = {
		prairie = { { "copper_ingot", 2, 4 }, { "fur", 2, 4 }, { "ice_crystal", 1, 2 }, { "brick", 6, 12 }, { "honey", 1, 3 } },
		foret = { { "iron_ingot", 2, 4 }, { "leather", 3, 6 }, { "melon", 2, 4 }, { "bread", 2, 4 }, { "clay", 6, 10 } },
		desert = { { "planks", 10, 20 }, { "fish_3", 2, 4 }, { "fur", 2, 4 }, { "milk", 2, 4 }, { "iron_ingot", 2, 3 } },
		neige = { { "bread", 3, 6 }, { "game_stew", 1, 3 }, { "copper_ingot", 2, 4 }, { "cloth", 2, 4 }, { "honey", 1, 3 } },
		marais = { { "planks", 10, 20 }, { "stone", 15, 30 }, { "steak", 3, 6 }, { "iron_ingot", 2, 3 }, { "copper_ingot", 2, 4 } },
	}
	for _, e in extra[biome] or {} do
		table.insert(pool, e)
	end
	return pool
end

local function ordersOf(reg)
	G.world.orders = G.world.orders or {}
	local key = reg.key
	local list = G.world.orders[key]
	if not list or (list.day or 0) + 2 <= G.world.day then
		local pool = demandPool(reg.plan.biome)
		list = { day = G.world.day, items = {} }
		local rng = Random.new(G.WG.hash(G.world.seed, "commandes", key, G.world.day))
		for i = 1, 3 do
			local e = pool[rng:NextInteger(1, #pool)]
			local n = rng:NextInteger(e[2], e[3])
			local price = (Config.ITEMS[e[1]] and Config.ITEMS[e[1]].price) or 10
			table.insert(list.items, { id = key .. "#" .. G.world.day .. "#" .. i, item = e[1], n = n, reward = math.floor(math.max(price, 6) * n * 1.7) })
		end
		G.world.orders[key] = list
	end
	return list
end

function Economie.openOrders(player: Player, e)
	local list = ordersOf(e.reg)
	local rows = {}
	local bonus = 1 + 0.01 * G.Joueurs.skill(player, "commerce")
	for _, o in list.items do
		local info = Config.ITEMS[o.item] or { name = o.item, icon = "❔" }
		table.insert(rows, { id = o.id, item = o.item, n = o.n, name = info.name, icon = info.icon, reward = math.floor(o.reward * bonus), done = o.done, have = G.Joueurs.count(player, o.item) })
	end
	G.remotes.Menu:FireClient(player, { kind = "orders", title = "Commandes du village", rows = rows })
	Economie.openFor = Economie.openFor or {}
	Economie.openFor[player] = e
end

function Economie.deliver(player: Player, id: string)
	local e = Economie.openFor and Economie.openFor[player]
	local root = G.Util.root(player)
	if not e or type(id) ~= "string" or not root or (e.root.Position - root.Position).Magnitude > 20 then
		return
	end
	local list = ordersOf(e.reg)
	for _, o in list.items do
		if o.id == id and not o.done then
			if G.Joueurs.count(player, o.item) < o.n then
				G.Util.toast(player, "Il te faut " .. o.n .. " " .. Config.ITEMS[o.item].name .. ".")
				return
			end
			G.Joueurs.take(player, o.item, o.n)
			local reward = math.floor(o.reward * (1 + 0.01 * G.Joueurs.skill(player, "commerce")))
			G.Joueurs.add(player, "gold", reward, true)
			o.done = true
			G.Law.addHonor(player, 2)
			G.Npcs.addOp(e, player, 5)
			G.Joueurs.addSkillXp(player, "commerce", 12 + o.n)
			Economie.record(player, "commande", o.n .. " " .. o.item .. " → " .. reward)
			G.Util.toast(player, "📦 Commande livrée : +" .. reward .. " 💰, le village t'en est reconnaissant.", "big")
			G.Joueurs.sync(player)
			Economie.openOrders(player, e)
			return
		end
	end
end

-- ----------------------------------------------------------------- Banque de village

-- 6 sortes d'objets au départ, +6 par agrandissement, sans fin ; le prix grimpe à chaque fois
local function bankSlots(level: number): number
	return 6 * level
end
local function bankCost(level: number): number
	return math.floor(150 * level ^ 1.7)
end

-- La banque d'un monde vit dans le PERSO (prof.banks[idDuMonde]) : un dépôt / retrait ne touche
-- qu'une seule sauvegarde, donc il est atomique (avant : sac dans le perso, banque dans le monde →
-- un arrêt brutal entre les deux écritures dupliquait ou détruisait des objets).
local function bankOf(player: Player)
	local prof = G.Joueurs.get(player)
	if not prof or not G.world then
		return nil
	end
	prof.banks = prof.banks or {}
	local b = prof.banks[G.world.id]
	if not b then
		b = { items = {}, level = 1 }
		prof.banks[G.world.id] = b
	end
	return b
end

-- Migration (format ≤ v2) : la banque rangée dans le monde passe dans le perso, une seule fois
function Economie.adoptBank(player: Player)
	local rec = G.Mondes.playerRecord(player)
	local old = rec and rec.bank
	local b = bankOf(player)
	if not (old and b) then
		return
	end
	for item, n in old.items or {} do
		b.items[item] = (b.items[item] or 0) + n
	end
	b.level = math.max(b.level, old.level or 1)
	rec.bank = nil
	Economie.record(player, "banque", "banque du monde reprise dans le perso")
	-- écrit les deux tout de suite pour réduire la fenêtre de doublon
	task.spawn(G.Save.save, player)
	task.spawn(G.Mondes.saveWorld)
end

-- Historique des mouvements (12 derniers, jour du monde) : le joueur voit ce qui est entré et sorti
local function bankLog(b, sign: string, item: string, n: number)
	b.log = b.log or {}
	table.insert(b.log, { d = G.world.day, s = sign, i = item, n = n })
	while #b.log > 12 do
		table.remove(b.log, 1)
	end
end

local function sendBank(player: Player)
	local b = bankOf(player)
	if not b then
		return
	end
	local used = 0
	for _ in b.items do
		used += 1
	end
	G.remotes.Menu:FireClient(player, {
		kind = "chest", id = "bank", items = b.items, mine = true, title = "Banque du village",
		bank = { slots = bankSlots(b.level), used = used, upgrade = bankCost(b.level), log = b.log },
	})
end

function Economie.openBank(player: Player, e)
	Economie.bankAt = Economie.bankAt or {}
	Economie.bankAt[player] = e
	sendBank(player)
end

function Economie.bankMove(player: Player, item: string, n: number, put: boolean)
	local e = Economie.bankAt and Economie.bankAt[player]
	local root = G.Util.root(player)
	if not e or not root or (e.root.Position - root.Position).Magnitude > 24 or not Config.ITEMS[item] then
		return
	end
	local b = bankOf(player)
	if not b or type(n) ~= "number" or n ~= n then
		return
	end
	n = math.clamp(math.floor(n), 1, 9999)
	if put then
		n = math.min(n, G.Joueurs.count(player, item))
		if n <= 0 then
			return
		end
		local used = 0
		for _ in b.items do
			used += 1
		end
		if not b.items[item] and used >= bankSlots(b.level) then
			G.Util.toast(player, "Ta banque est pleine (" .. bankSlots(b.level) .. " sortes d'objets). Agrandis-la.")
			return
		end
		if item ~= "gold" and not G.Joueurs.take(player, "gold", 2) then
			G.Util.toast(player, "Le dépôt coûte 2 💰.")
			return
		end
		G.Joueurs.take(player, item, n)
		b.items[item] = (b.items[item] or 0) + n
		bankLog(b, "+", item, n)
	else
		n = math.min(n, b.items[item] or 0)
		if n <= 0 then
			return
		end
		b.items[item] -= n
		if b.items[item] <= 0 then
			b.items[item] = nil
		end
		G.Joueurs.add(player, item, n, true)
		bankLog(b, "-", item, n)
	end
	G.Joueurs.sync(player)
	sendBank(player)
end

function Economie.bankUpgrade(player: Player)
	local e = Economie.bankAt and Economie.bankAt[player]
	local root = G.Util.root(player)
	local b = bankOf(player)
	if not b or not e or not root or (e.root.Position - root.Position).Magnitude > 24 then
		return
	end
	local cost = bankCost(b.level)
	if not G.Joueurs.take(player, "gold", cost) then
		G.Util.toast(player, "Il faut " .. cost .. " 💰 pour agrandir ta banque.")
		return
	end
	b.level += 1
	Economie.record(player, "banque", "agrandie niveau " .. b.level .. " (-" .. cost .. ")")
	G.Util.toast(player, "🏦 Banque agrandie : " .. bankSlots(b.level) .. " sortes d'objets.", "gain")
	G.Joueurs.sync(player)
	sendBank(player)
end

-- ----------------------------------------------------------------- Étal de joueur

-- d.stall = { items = { [objet] = {n, prix} }, till = or encaissé en attente }
local function stallOf(id: string)
	local d = G.Protection.findPlaced(id)
	if not d or d.item ~= "stall" then
		return nil
	end
	d.stall = d.stall or { items = {}, till = 0 }
	return d
end

local function sendStall(player: Player, d)
	local ownerP = G.Util.playerOf(d.owner)
	local rows = {}
	for item, e in d.stall.items do
		local info = Config.ITEMS[item] or { name = item, icon = "?" }
		table.insert(rows, { item = item, n = e[1], price = e[2], name = info.name, icon = info.icon })
	end
	table.sort(rows, function(a, b)
		return a.name < b.name
	end)
	G.remotes.Menu:FireClient(player, {
		kind = "stall", id = d.id, rows = rows, mine = G.Util.owns(player, d.owner), till = d.stall.till,
		title = "Étal" .. (ownerP and (" de " .. ownerP.DisplayName) or ""),
	})
end

local function nearStall(player: Player, d): boolean
	local r = G.Util.root(player)
	return r ~= nil and (Vector3.new(d.x, r.Position.Y, d.z) - r.Position).Magnitude < 14
end

function Economie.openStall(player: Player, id: string)
	local d = stallOf(id)
	if d and nearStall(player, d) then
		sendStall(player, d)
	end
end

-- Le propriétaire met en vente (n objets à un prix unitaire) ou change le prix
function Economie.stallPut(player: Player, id: string, item: string, n: number, price: number?)
	local d = stallOf(id)
	local info = Config.ITEMS[item]
	if not d or not info or item == "gold" or info.tool or not G.Util.owns(player, d.owner) or not nearStall(player, d) then
		return
	end
	local e = d.stall.items[item] or { 0, math.max(1, math.floor((info.price or 1) * 1.2)) }
	if price then
		e[2] = math.clamp(math.floor(price), 1, 100000)
	end
	n = math.clamp(math.floor(n or 0), 0, G.Joueurs.count(player, item))
	if n > 0 then
		G.Joueurs.take(player, item, n)
		e[1] += n
	end
		G.Mondes.saveSoon(player)
	d.stall.items[item] = e
	G.Joueurs.sync(player)
	sendStall(player, d)
end

function Economie.stallTake(player: Player, id: string, item: string)
	local d = stallOf(id)
	if not d or not G.Util.owns(player, d.owner) or not nearStall(player, d) then
		return
	end
	local e = d.stall.items[item]
	if e then
		d.stall.items[item] = nil
		G.Joueurs.add(player, item, e[1], true)
		G.Mondes.saveSoon(player)
		G.Joueurs.sync(player)
	end
	sendStall(player, d)
end

function Economie.stallCollect(player: Player, id: string)
	local d = stallOf(id)
	if not d or not G.Util.owns(player, d.owner) or not nearStall(player, d) or d.stall.till <= 0 then
		return
	end
	local n = d.stall.till
	d.stall.till = 0
	G.Joueurs.add(player, "gold", n, true)
	G.Util.toast(player, "Caisse encaissée : +" .. n .. " 💰", "gain")
	G.Mondes.saveSoon(player)
	G.Joueurs.sync(player)
	sendStall(player, d)
end

function Economie.stallBuy(player: Player, id: string, item: string, n: number)
	local d = stallOf(id)
	if not d or G.Util.owns(player, d.owner) or not nearStall(player, d) then
		return
	end
	local e = d.stall.items[item]
	if not e then
		return
	end
	n = math.clamp(math.floor(n or 1), 1, e[1])
	local cost = e[2] * n
	if not G.Joueurs.take(player, "gold", cost) then
		G.Util.toast(player, "Il te faut " .. cost .. " 💰.")
		return
	end
	e[1] -= n
	if e[1] <= 0 then
		d.stall.items[item] = nil
	end
	-- taxe du marché : réglée par le maire du village (va au trésor), sinon 5 % qui sortent de l'économie
	local rate, village = 0.05, nil
	if G.Politique and G.Politique.taxAt then
		rate, village = G.Politique.taxAt(Vector3.new(d.x, 0, d.z))
	end
	local tax = math.floor(cost * rate)
	if village then
		G.Politique.credit(village, tax, "taxe")
	end
	d.stall.till += cost - tax
	G.Joueurs.add(player, item, n, true)
	G.Joueurs.sync(player)
	local info = Config.ITEMS[item]
	G.Protection.log(d.owner, player.DisplayName .. " a acheté " .. n .. " " .. info.name .. " à ton étal (+" .. (cost - tax) .. " 💰 en caisse).", false)
	local owner = G.Util.playerOf(d.owner)
	if owner then
		G.Joueurs.addSkillXp(owner, "commerce", 2 + math.floor(cost / 30))
	end
	Economie.record(player, "etal", n .. " " .. item .. " -> " .. cost .. " (" .. tostring(d.owner) .. ")")
	G.Mondes.saveSoon(player)
	sendStall(player, d)
end

return Economie
