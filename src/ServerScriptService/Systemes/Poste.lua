-- La poste et l'hôtel des ventes.
--  · Courrier : envoyer objets et or à n'importe quel joueur (par son pseudo), même hors ligne ou dans
--    un autre monde. Colis stockés dans le DataStore WA_Courrier (clé "m_<UserId>"), écrits par
--    UpdateAsync. 5 or de port (l'or sort de l'économie). Pas de texte libre (pas de modération à faire).
--  · Hôtel des ventes (par monde) : mise en vente à prix libre, 2 % de frais ; l'acheteur paie, le
--    vendeur reçoit l'or par courrier ; invendus rendus par courrier après 7 jours.
-- On récupère son courrier et on accède à l'hôtel des ventes aux boîtes aux lettres des villages.
--
-- Sûreté (étape 1B) : chaque colis a un identifiant unique.
--  · deliver : si l'écriture semble échouer, on relit la boîte pour savoir si le colis y est
--    (une erreur réseau après écriture ne doit ni dupliquer ni perdre) ; un colis « système »
--    (paiement de l'hôtel des ventes, invendu) qui ne passe pas va dans une file du monde,
--    réessayée toutes les minutes et sauvegardée avec le monde.
--  · collect : on CRÉDITE d'abord le perso en notant les identifiants reçus (prof.mailClaimed),
--    on SAUVE le perso, puis on retire ces colis de la boîte. Un colis déjà noté n'est jamais
--    recrédité : l'opération peut être interrompue à n'importe quel moment sans doublon ni perte.
--  · aucune boîte n'est tronquée (avant : au-delà de 100 colis, les plus vieux étaient détruits) ;
--    au-delà de MAX_PARCELS, l'envoi d'un joueur est refusé et remboursé.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Poste = {}
local G, Config
local store = nil
local memory = {}
local POSTAGE = 5
local LISTING_DAYS = 7
local MAX_PARCELS = 400

function Poste.init(g)
	G = g
	Config = G.Config
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore("WA_Courrier" .. (RunService:IsStudio() and "_studio" or ""))
	end)
	store = ok and ds or nil
	if RunService:IsStudio() and not workspace:GetAttribute("StudioDataStore") then
		store = nil
	end
	G.Interact.onPrompt("mail", function(player)
		Poste.open(player)
	end)
	G.Interact.onAction("mail_collect", function(player)
		Poste.collect(player)
	end)
	G.Interact.onAction("mail_send", function(player, data)
		Poste.send(player, data.to, data.item, tonumber(data.n) or 1)
	end)
	G.Interact.onAction("market_list", function(player, data)
		Poste.list(player, data.item, tonumber(data.n) or 1, tonumber(data.price) or 1)
	end)
	G.Interact.onAction("market_buy", function(player, data)
		Poste.buy(player, data.id)
	end)
	-- file des colis système non livrés (sauvegardée avec le monde)
	task.spawn(function()
		while true do
			task.wait(60)
			Poste.flushQueue()
		end
	end)
end

-- Toujours devant la boîte aux lettres ouverte ?
local function atPost(player: Player): boolean
	local at = Poste.at and Poste.at[player]
	local r = G.Util.root(player)
	return at ~= nil and r ~= nil and (r.Position - at).Magnitude < 20
end

local function decode(v)
	if type(v) == "string" then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, v)
		return ok and t or nil
	end
	return v
end

local function readBox(userId: number): (boolean, any)
	if not store then
		return true, memory[userId] or {}
	end
	local ok, v = pcall(function()
		return store:GetAsync("m_" .. userId)
	end)
	if not ok then
		return false, nil
	end
	return true, decode(v) or {}
end

local function hasParcel(list, id: string): boolean
	for _, p in list or {} do
		if p.id == id then
			return true
		end
	end
	return false
end

-- Ajoute un colis dans la boîte d'un joueur (atomique, idempotent).
-- Renvoie true (livré), false (pas livré, sûr) ; « full » en 2e valeur si la boîte est pleine.
-- system = colis du jeu (paiement, invendu) : jamais refusé pour boîte pleine.
function Poste.deliver(userId: number, parcel, system: boolean?): (boolean, string?)
	parcel.t = parcel.t or os.time()
	parcel.id = parcel.id or HttpService:GenerateGUID(false)
	if not store then
		memory[userId] = memory[userId] or {}
		if not hasParcel(memory[userId], parcel.id) then
			table.insert(memory[userId], parcel)
		end
		return true
	end
	local full = false
	local ok = pcall(function()
		store:UpdateAsync("m_" .. userId, function(old)
			local list = decode(old) or {}
			if hasParcel(list, parcel.id) then
				return nil -- déjà livré (essai précédent)
			end
			if #list >= MAX_PARCELS and not system then
				full = true
				return nil
			end
			table.insert(list, parcel)
			return HttpService:JSONEncode(list)
		end)
	end)
	if not ok then
		-- l'écriture a peut-être eu lieu malgré l'erreur : on vérifie avant de conclure
		task.wait(1)
		local okR, list = readBox(userId)
		ok = okR and hasParcel(list, parcel.id)
	end
	if full then
		return false, "full"
	end
	local target = Players:GetPlayerByUserId(userId)
	if ok and target then
		G.Util.toast(target, "📬 Du courrier t'attend à la boîte aux lettres d'un village.")
	end
	return ok
end

-- Colis du jeu qui DOIT arriver : livré tout de suite, sinon mis en file (réessayé, sauvegardé)
function Poste.deliverSystem(userId: number, parcel)
	parcel.id = parcel.id or HttpService:GenerateGUID(false)
	if not Poste.deliver(userId, parcel, true) then
		G.world.mailQueue = G.world.mailQueue or {}
		table.insert(G.world.mailQueue, { uid = userId, parcel = parcel })
		G.Economie.record(nil, "courrier_file", "colis " .. parcel.id .. " pour " .. userId .. " mis en file")
	end
end

function Poste.flushQueue()
	local q = G.world and G.world.mailQueue
	if not q or #q == 0 then
		return
	end
	for i = #q, 1, -1 do
		local e = q[i]
		if Poste.deliver(e.uid, e.parcel, true) then
			table.remove(q, i)
		end
	end
end

local function inbox(player: Player)
	local ok, list = readBox(player.UserId)
	if not ok then
		return {}, false
	end
	-- les colis déjà crédités (retrait de la boîte pas encore confirmé) ne s'affichent plus
	local claimed = (G.Joueurs.get(player) or {}).mailClaimed or {}
	local out = {}
	for _, p in list do
		if not (p.id and claimed[p.id]) then
			table.insert(out, p)
		end
	end
	return out, true
end

-- Hôtel des ventes du monde (dans la sauvegarde du monde)
local function market()
	G.world.market = G.world.market or {}
	return G.world.market
end

-- Invendus trop vieux : rendus à leur vendeur par courrier
local function expire()
	local m = market()
	for i = #m, 1, -1 do
		local l = m[i]
		if G.world.day - (l.day or 0) >= LISTING_DAYS then
			table.remove(m, i)
			Poste.deliverSystem(l.seller, { id = "exp_" .. l.id, from = "Hôtel des ventes", items = { [l.item] = l.n } })
		end
	end
end

function Poste.open(player: Player)
	expire()
	local mail = inbox(player)
	local summary = {}
	for _, p in mail do
		table.insert(summary, { from = p.from, gold = p.gold or 0, items = p.items or {} })
	end
	local rows = {}
	for _, l in market() do
		local info = Config.ITEMS[l.item] or { name = l.item, icon = "?" }
		table.insert(rows, { id = l.id, item = l.item, n = l.n, price = l.price, name = info.name, icon = info.icon, seller = l.sellerName, mine = l.seller == player.UserId })
	end
	table.sort(rows, function(a, b)
		return a.name < b.name
	end)
	Poste.at = Poste.at or {}
	local r = G.Util.root(player)
	Poste.at[player] = r and r.Position or nil
	G.remotes.Menu:FireClient(player, { kind = "post", mail = summary, market = rows, postage = POSTAGE })
end

function Poste.collect(player: Player)
	if not atPost(player) then
		return
	end
	local prof = G.Joueurs.get(player)
	if not prof then
		return
	end
	local got, okRead = inbox(player)
	if not okRead then
		G.Util.toast(player, "La poste est fermée pour l'instant, réessaie.")
		return
	end
	prof.mailClaimed = prof.mailClaimed or {}
	-- 1) créditer + noter (même instant, même sauvegarde)
	local n, ids = 0, {}
	for _, p in got do
		local id = p.id or ("ancien_" .. tostring(p.t) .. "_" .. tostring(p.from) .. "_" .. n)
		p.id = id
		if not prof.mailClaimed[id] then
			prof.mailClaimed[id] = os.time()
			if (tonumber(p.gold) or 0) > 0 then
				G.Joueurs.add(player, "gold", p.gold, true)
			end
			for item, k in p.items or {} do
				if Config.ITEMS[item] then
					G.Joueurs.add(player, item, k, true)
				end
			end
			ids[id] = true
			n += 1
		end
	end
	if n == 0 then
		Poste.open(player)
		return
	end
	G.Util.toast(player, "📬 " .. n .. " colis récupéré(s).", "gain")
	G.Economie.record(player, "courrier", n .. " colis")
	G.Joueurs.sync(player)
	-- 2) sauver le perso ; 3) seulement alors, vider ces colis de la boîte
	local saved = G.Save.save(player)
	if saved then
		Poste.prune(player, ids, got)
	end
	Poste.open(player)
end

-- Retire de la boîte les colis crédités ; oublie les vieux identifiants notés
function Poste.prune(player: Player, ids, got)
	local uid = player.UserId
	local function keep(list)
		local out = {}
		for i, p in list do
			local id = p.id or (got[i] and got[i].id)
			if not (id and ids[id]) then
				table.insert(out, p)
			end
		end
		return out
	end
	if not store then
		memory[uid] = keep(memory[uid] or {})
	else
		pcall(function()
			store:UpdateAsync("m_" .. uid, function(old)
				local list = decode(old) or {}
				return HttpService:JSONEncode(keep(list))
			end)
		end)
	end
	local prof = G.Joueurs.get(player)
	if prof and prof.mailClaimed then
		local limit = os.time() - 30 * 86400
		for id, t in prof.mailClaimed do
			if t < limit then
				prof.mailClaimed[id] = nil
			end
		end
	end
end

function Poste.send(player: Player, toName: string, item: string, n: number)
	if not atPost(player) or type(toName) ~= "string" or #toName < 3 or type(item) ~= "string" or not Config.ITEMS[item] then
		return
	end
	local info = Config.ITEMS[item]
	if info.tool and item ~= "gold" then
		G.Util.toast(player, "Les outils ne s'envoient pas.")
		return
	end
	local ok, uid = pcall(function()
		return Players:GetUserIdFromNameAsync(toName)
	end)
	if not ok or not uid or uid == player.UserId then
		G.Util.toast(player, "Destinataire introuvable (pseudo Roblox exact).")
		return
	end
	-- le destinataire t'a bloqué (en ligne ici, ou d'après sa sauvegarde) : refusé, rien n'est pris
	local online = Players:GetPlayerByUserId(uid)
	local blocked
	if online then
		blocked = G.Admin.blocks(online, player)
	else
		local saved = G.Save.peek(uid)
		blocked = saved and type(saved.blocked) == "table" and saved.blocked[tostring(player.UserId)] ~= nil
	end
	if blocked then
		G.Util.toast(player, "Ce joueur ne reçoit pas ton courrier.")
		return
	end
	local have = G.Joueurs.count(player, item)
	if have < 1 then
		return
	end
	n = math.clamp(math.floor(n), 1, have)
	local needGold = POSTAGE + (item == "gold" and n or 0)
	if G.Joueurs.count(player, "gold") < needGold or (item ~= "gold" and G.Joueurs.count(player, item) < n) or n < 1 then
		G.Util.toast(player, "Il te faut l'envoi + " .. POSTAGE .. " 💰 de port.")
		return
	end
	G.Joueurs.take(player, "gold", POSTAGE)
	G.Joueurs.take(player, item, n)
	local parcel = { from = player.DisplayName }
	if item == "gold" then
		parcel.gold = n
	else
		parcel.items = { [item] = n }
	end
	local delivered, why = Poste.deliver(uid, parcel)
	if not delivered then
		-- pas livré (vérifié par relecture) : on rend tout, port compris
		G.Joueurs.add(player, item, n, true)
		G.Joueurs.add(player, "gold", POSTAGE, true)
		G.Util.toast(player, why == "full" and "La boîte de ce joueur est pleine : envoi rendu." or "L'envoi a échoué, objets rendus.")
	else
		G.Util.toast(player, "📮 Envoyé à " .. toName .. ".", "gain")
		G.Economie.record(player, "envoi", n .. " " .. item .. " -> " .. uid)
	end
	G.Joueurs.sync(player)
end

-- ----------------------------------------------------------------- Hôtel des ventes

function Poste.list(player: Player, item: string, n: number, price: number)
	if not atPost(player) or type(item) ~= "string" or not Config.ITEMS[item] or item == "gold" then
		return
	end
	local info = Config.ITEMS[item]
	if info.tool then
		return
	end
	local have = G.Joueurs.count(player, item)
	if have < 1 then
		return
	end
	n = math.clamp(math.floor(n), 1, have)
	price = math.clamp(math.floor(price), 1, 1000000)
	local fee = math.max(1, math.floor(price * 0.02)) -- price = prix du lot entier
	if n < 1 or G.Joueurs.count(player, "gold") < fee then
		G.Util.toast(player, "Mise en vente : il faut l'objet et " .. fee .. " 💰 de frais (2 %).")
		return
	end
	G.Joueurs.take(player, "gold", fee)
	G.Joueurs.take(player, item, n)
	table.insert(market(), { id = "hv" .. HttpService:GenerateGUID(false), seller = player.UserId, sellerName = player.DisplayName, item = item, n = n, price = price, day = G.world.day })
	G.Util.toast(player, "🏷️ En vente : " .. n .. " " .. info.name .. " pour " .. price .. " 💰 (frais " .. fee .. ").", "gain")
	G.Joueurs.sync(player)
	Poste.open(player)
end

function Poste.buy(player: Player, id: string)
	if not atPost(player) or type(id) ~= "string" then
		return
	end
	local m = market()
	for i, l in m do
		if l.id == id then
			if l.seller == player.UserId then
				-- reprendre sa propre annonce
				table.remove(m, i)
				G.Joueurs.add(player, l.item, l.n, true)
			else
				if not G.Joueurs.take(player, "gold", l.price) then
					G.Util.toast(player, "Il te faut " .. l.price .. " 💰.")
					return
				end
				table.remove(m, i)
				G.Joueurs.add(player, l.item, l.n, true)
				Poste.deliverSystem(l.seller, { id = "pay_" .. l.id, from = "Hôtel des ventes (" .. player.DisplayName .. ")", gold = l.price })
				G.Economie.record(player, "hdv", l.n .. " " .. l.item .. " -> " .. l.price)
				G.Mondes.saveSoon(player)
				G.Joueurs.addSkillXp(player, "commerce", 2)
			end
			G.Joueurs.sync(player)
			Poste.open(player)
			return
		end
	end
	G.Util.toast(player, "Cette annonce n'existe plus.")
	Poste.open(player)
end

return Poste
