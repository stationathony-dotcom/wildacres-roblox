-- Administration, journal durable et protection des joueurs (étapes 22 et 24).
--
-- Commandes de chat :
--   tous les joueurs :  /bloquer <pseudo>   /debloquer <pseudo>   /bloques
--     Un joueur bloqué ne peut plus te proposer d'échange, t'inviter (groupe, clan) ni t'envoyer
--     de courrier. Le blocage suit le perso (sauvegardé) et marche même si l'autre est hors ligne.
--   administrateurs (créateur du jeu + Config.ADMINS ; tout le monde dans Studio) :
--     /wa aide
--     /wa meteo <clair|nuageux|pluie|orage|brouillard>
--     /wa coupe <action> <raison…>  |  /wa rallume <action>     (interrupteurs d'urgence, tous serveurs)
--     /wa annonce <texte…>          (tous les serveurs, via MessagingService)
--     /wa sauver                    (perso de chacun + monde, tout de suite)
--     /wa ferme <minutes>           (maintenance : annonce, compte à rebours, sauvegarde, renvoi)
--     /wa versions <userId>         (dernières versions de sauvegarde d'un perso)
--     /wa restaurer <userId> <version>  (joueur hors ligne seulement)
--     /wa donner <pseudo> <objet> <n>   (réparation après bug prouvé ; journalisé)
--     /wa journal [n]               (dernières lignes du registre)
-- Toute commande admin est écrite dans le journal durable.
--
-- Journal durable : le registre Economie.ledger (mémoire) est recopié toutes les 60 s dans le
-- DataStore WA_Journal, une clé par monde et par heure ("<monde>_<AAAAMMJJHH>").

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Admin = {}
local G, Config
local journal = nil
local flushed = 0 -- nombre de lignes du registre déjà recopiées
local closing = false

local function isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if player.UserId == game.CreatorId then
		return true
	end
	return table.find(Config.ADMINS or {}, player.UserId) ~= nil
end
Admin.isAdmin = isAdmin

local function say(player: Player, msg: string, kind: string?)
	G.Util.toast(player, msg, kind)
end

local function findPlayer(name: string?): Player?
	if not name then
		return nil
	end
	name = string.lower(name)
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == name or string.lower(p.DisplayName) == name then
			return p
		end
	end
	for _, p in Players:GetPlayers() do
		if string.sub(string.lower(p.Name), 1, #name) == name then
			return p
		end
	end
	return nil
end

-- ----------------------------------------------------------------- Blocage entre joueurs

-- a a-t-il bloqué b ? (b peut être un Player ou un UserId)
function Admin.blocks(a: Player, b): boolean
	local prof = G.Joueurs.get(a)
	local uid = typeof(b) == "Instance" and b.UserId or b
	return prof ~= nil and type(prof.blocked) == "table" and prof.blocked[tostring(uid)] ~= nil
end

local function block(player: Player, name: string?, on: boolean)
	local prof = G.Joueurs.get(player)
	if not prof or not name then
		say(player, on and "/bloquer <pseudo>" or "/debloquer <pseudo>")
		return
	end
	local target = findPlayer(name)
	local uid = target and target.UserId
	if not uid then
		local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, name)
		uid = ok and id or nil
	end
	if not uid or uid == player.UserId then
		say(player, "Joueur introuvable (pseudo Roblox exact).")
		return
	end
	prof.blocked = prof.blocked or {}
	if on then
		prof.blocked[tostring(uid)] = target and target.DisplayName or name
		say(player, "🚫 " .. (target and target.DisplayName or name) .. " est bloqué : plus d'échanges, d'invitations ni de courrier de sa part.")
		G.Economie.cancel(player, nil)
	else
		prof.blocked[tostring(uid)] = nil
		say(player, "✅ " .. name .. " n'est plus bloqué.")
	end
	G.Joueurs.markDirty(player)
end

-- ----------------------------------------------------------------- Journal durable

local function flushJournal()
	local ledger = G.Economie.ledger
	if not journal or not G.world then
		flushed = #ledger
		return
	end
	-- le registre en mémoire est un tampon tournant (600) : on repère les nouvelles lignes par l'heure
	local fresh = {}
	for i = math.max(1, flushed + 1), #ledger do
		table.insert(fresh, ledger[i])
	end
	if #ledger >= 600 then
		flushed = 0
		table.clear(ledger)
	else
		flushed = #ledger
	end
	if #fresh == 0 then
		return
	end
	local k = G.world.id .. "_" .. os.date("!%Y%m%d%H")
	local ok, err = pcall(function()
		journal:UpdateAsync(k, function(old)
			local list = type(old) == "table" and old or {}
			for _, e in fresh do
				table.insert(list, e)
			end
			while #list > 5000 do
				table.remove(list, 1)
			end
			return list
		end)
	end)
	if not ok then
		warn("[WildAcres] journal : " .. tostring(err))
	end
end

-- ----------------------------------------------------------------- Commandes admin

local function closeServer(minutes: number, who: string)
	if closing then
		return
	end
	closing = true
	for left = math.max(0, minutes), 1, -1 do
		for _, p in Players:GetPlayers() do
			say(p, "🔧 Maintenance : le monde ferme dans " .. left .. " min. Ta progression est sauvegardée.", "big")
		end
		task.wait(60)
	end
	G.Mondes.saveWorld()
	for _, p in Players:GetPlayers() do
		G.Save.save(p, true)
		p:Kick("Maintenance en cours (" .. who .. "). Ta progression est sauvegardée : reviens dans quelques minutes.")
	end
end

local ADMIN = {}
ADMIN.aide = function(player)
	say(player, "/wa meteo · coupe · rallume · annonce · sauver · ferme · versions · restaurer · donner · journal · perf · terrain · joueur · avertir · muet · expulser · bannir")
end
ADMIN.meteo = function(player, args)
	say(player, G.Meteo.force(args[1] or "", 180) and ("Météo : " .. args[1]) or "États : clair, nuageux, pluie, orage, brouillard")
end
ADMIN.coupe = function(player, args)
	local kind = args[1]
	if not kind then
		return say(player, "/wa coupe <action> <raison>")
	end
	local reason = table.concat(args, " ", 2)
	G.Interact.setSwitch(kind, reason ~= "" and reason or "maintenance")
	say(player, "⛔ Action « " .. kind .. " » coupée sur tous les serveurs (≤ 1 min).")
end
ADMIN.rallume = function(player, args)
	if not args[1] then
		return say(player, "/wa rallume <action>")
	end
	G.Interact.setSwitch(args[1], nil)
	say(player, "✅ Action « " .. args[1] .. " » rallumée.")
end
ADMIN.annonce = function(player, args)
	local text = table.concat(args, " ")
	if text == "" then
		return
	end
	local ok = pcall(function()
		local filtered = TextChatService and game:GetService("TextService"):FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
		MessagingService:PublishAsync("WA_Annonce", filtered)
	end)
	if not ok then
		for _, p in Players:GetPlayers() do
			say(p, "📢 " .. text, "big")
		end
	end
end
ADMIN.sauver = function(player)
	for _, p in G.Game.players() do
		task.spawn(G.Save.save, p)
	end
	task.spawn(G.Mondes.saveWorld)
	say(player, "💾 Sauvegarde lancée (persos + monde).")
end
ADMIN.ferme = function(player, args)
	task.spawn(closeServer, tonumber(args[1]) or 2, player.Name)
end
ADMIN.versions = function(player, args)
	local uid = tonumber(args[1])
	if not uid then
		return say(player, "/wa versions <userId>")
	end
	local list = G.Save.listVersions(uid, 8)
	local parts = {}
	for _, v in list do
		table.insert(parts, os.date("!%d/%m %H:%M", v.date) .. " = " .. v.version)
	end
	say(player, #parts > 0 and table.concat(parts, " · ") or "Aucune version (ou Studio).")
end
ADMIN.restaurer = function(player, args)
	local uid, ver = tonumber(args[1]), args[2]
	if not uid or not ver then
		return say(player, "/wa restaurer <userId> <version>")
	end
	local ok, why = G.Save.restoreVersion(uid, ver)
	say(player, ok and "✅ Perso restauré." or ("Refusé : " .. tostring(why)))
end
ADMIN.donner = function(player, args)
	local target, item, n = findPlayer(args[1]), args[2], math.floor(tonumber(args[3]) or 1)
	if not target or not item or not Config.ITEMS[item] or n < 1 or n > 100000 then
		return say(player, "/wa donner <pseudo> <objet> <n>")
	end
	G.Joueurs.add(target, item, n, true)
	G.Joueurs.sync(target)
	say(player, "Donné : " .. n .. " " .. item .. " à " .. target.Name)
end
-- ---------------------------------------------------------------- modération graduée (18/11)
-- fiche d'un joueur (sans données privées : pseudo, or, étoiles, prime, clan, avertissements)
ADMIN.joueur = function(player, args)
	local t = findPlayer(args[1])
	local p = t and G.Joueurs.get(t)
	if not p then
		return say(player, "/wa joueur <pseudo>")
	end
	say(player, string.format("👤 %s · or %d · étoiles %d · prime %d · honneur %d · clan %s · avertissements %d",
		t.DisplayName, p.inv.gold or 0, p.stars or 0, p.bounty or 0, p.honor or 0, tostring(p.clan or "-"), p.warnings or 0))
end
-- 1. avertir : message + compteur sauvegardé
ADMIN.avertir = function(player, args)
	local t = findPlayer(args[1])
	local why = table.concat(args, " ", 2)
	local p = t and G.Joueurs.get(t)
	if not p or why == "" then
		return say(player, "/wa avertir <pseudo> <motif>")
	end
	p.warnings = (p.warnings or 0) + 1
	G.Joueurs.markDirty(t)
	G.Economie.record(t, "sanction", "avertissement : " .. why)
	say(t, "⚠️ Avertissement de la modération : " .. why .. " (" .. p.warnings .. ")", "danger")
	say(player, "Averti (" .. p.warnings .. ").")
end
-- 2. muet : plus de messages dans le chat pendant N minutes
local muted = {}
ADMIN.muet = function(player, args)
	local t = findPlayer(args[1])
	local min = math.clamp(math.floor(tonumber(args[2]) or 10), 1, 1440)
	if not t then
		return say(player, "/wa muet <pseudo> <minutes>")
	end
	muted[t.UserId] = os.clock() + min * 60
	local function apply(on: boolean)
		for _, ch in TextChatService:GetDescendants() do
			if ch:IsA("TextSource") and ch.UserId == t.UserId then
				ch.CanSend = on
			end
		end
	end
	apply(false)
	G.Economie.record(t, "sanction", "muet " .. min .. " min")
	say(t, "🔇 Tu ne peux plus écrire dans le chat pendant " .. min .. " min.", "danger")
	say(player, t.DisplayName .. " est muet " .. min .. " min.")
	task.delay(min * 60, function()
		if muted[t.UserId] and os.clock() >= muted[t.UserId] - 1 then
			muted[t.UserId] = nil
			if t.Parent then
				apply(true)
				say(t, "🔈 Tu peux de nouveau écrire.")
			end
		end
	end)
end
-- 3. expulser (sauvegarde d'abord)
ADMIN.expulser = function(player, args)
	local t = findPlayer(args[1])
	local why = table.concat(args, " ", 2)
	if not t then
		return say(player, "/wa expulser <pseudo> <motif>")
	end
	G.Economie.record(t, "sanction", "expulsé : " .. why)
	G.Save.save(t, true)
	t:Kick("Expulsé par la modération : " .. (why ~= "" and why or "comportement"))
	say(player, "Expulsé.")
end
-- 4. bannir N jours (Players:BanAsync, sur toute l'expérience)
ADMIN.bannir = function(player, args)
	local t = findPlayer(args[1])
	local days = math.clamp(math.floor(tonumber(args[2]) or 1), 1, 3650)
	local why = table.concat(args, " ", 3)
	if not t then
		return say(player, "/wa bannir <pseudo> <jours> <motif>")
	end
	G.Economie.record(t, "sanction", "banni " .. days .. " j : " .. why)
	G.Save.save(t, true)
	local ok, err = pcall(function()
		Players:BanAsync({ UserIds = { t.UserId }, ApplyToUniverse = true, Duration = days * 86400,
			DisplayReason = "Banni " .. days .. " jour(s) : " .. (why ~= "" and why or "comportement"), PrivateReason = "par " .. player.UserId .. " : " .. why })
	end)
	if not ok then
		t:Kick("Banni " .. days .. " jour(s) : " .. (why ~= "" and why or "comportement"))
		say(player, "Bannissement Roblox indisponible (" .. tostring(err) .. ") : expulsé à la place.")
	else
		say(player, "Banni " .. days .. " jour(s).")
	end
end
ADMIN.terrain = function(player, args)
	local root = G.Util.root(player)
	if not root then
		return
	end
	local n = G.Terraforme.restore(root.Position, tonumber(args[1]) or 3)
	G.Economie.record(player, "terrain", n .. " cases @" .. math.floor(root.Position.X) .. "," .. math.floor(root.Position.Z))
	say(player, "⛰️ Relief d'origine remis sur " .. n .. " case(s).")
end
ADMIN.perf = function(player)
	local rows = {}
	for name, ms in G.perf or {} do
		table.insert(rows, { name, ms })
	end
	table.sort(rows, function(a, b)
		return a[2] > b[2]
	end)
	local parts, total = {}, 0
	for i, r in rows do
		total += r[2]
		if i <= 6 then
			table.insert(parts, string.format("%s %.2f", r[1], r[2]))
		end
	end
	local nParts = 0
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") then
			nParts += 1
		end
	end
	say(player, string.format("⏱️ boucle %.2f ms/image · %s · %d pièces · %d Ko mémoire Lua", total, table.concat(parts, " · "), nParts,
		math.floor(collectgarbage("count"))))
end
ADMIN.journal = function(player, args)
	local n = math.clamp(tonumber(args[1]) or 5, 1, 15)
	local l = G.Economie.ledger
	for i = math.max(1, #l - n + 1), #l do
		local e = l[i]
		say(player, os.date("!%H:%M", e.t) .. " " .. e.kind .. " · " .. tostring(e.detail))
	end
end

-- ---------------------------------------------------------------- commandes de tous les joueurs (18/11)
local stuckAt = {} -- joueur -> dernière utilisation de /coince
local offers = {} -- joueur qui reçoit -> { from, x, z, t } (cession de terrain en attente)

-- /coince : ne pas bouger 5 s, puis on te remet sur le sol le plus proche (ou à l'arrivée si tu es
-- au milieu de l'eau) ; une fois par minute (pas un téléporteur)
local function unstuck(player: Player)
	local now = os.clock()
	if now - (stuckAt[player] or -999) < 60 then
		return say(player, "Patiente encore un peu avant de réutiliser /coince.")
	end
	local root = G.Util.root(player)
	if not root then
		return
	end
	stuckAt[player] = now
	local start = root.Position
	say(player, "🧭 Ne bouge plus 5 secondes…")
	task.delay(5, function()
		local r = G.Util.root(player)
		if not r or (r.Position - start).Magnitude > 3 then
			return say(player, "Tu as bougé : /coince annulé.")
		end
		local x, z = r.Position.X, r.Position.Z
		local target
		if G.Util.isWater(x, z) then
			target = G.Game.spawnPos()
		else
			target = Vector3.new(x, G.Util.groundY(x, z) + 4, z)
		end
		G.Game.noFall(player, 3)
		player.Character:PivotTo(CFrame.new(target))
		say(player, "🧭 Te voilà dégagé.")
	end)
end

-- /signaler <pseudo> <motif> : noté au journal, prévient les admins présents
local function report(player: Player, args)
	local target = findPlayer(args[1])
	local why = table.concat(args, " ", 2)
	if not target or target == player or why == "" then
		return say(player, "/signaler <pseudo> <motif>  (joueur présent dans ce monde)")
	end
	G.Economie.record(player, "signalement", target.UserId .. " · " .. string.sub(why, 1, 200))
	for _, p in Players:GetPlayers() do
		if isAdmin(p) and p ~= player then
			say(p, "🚩 Signalement : " .. player.DisplayName .. " → " .. target.DisplayName .. " : " .. string.sub(why, 1, 120), "danger")
		end
	end
	say(player, "🚩 Merci, c'est noté. Tu peux aussi /bloquer " .. target.DisplayName .. ".")
end

-- /ceder <pseudo> : propose le terrain où tu te tiens ; l'autre tape /accepter (60 s)
local function cede(player: Player, args)
	local target = findPlayer(args[1])
	local root = G.Util.root(player)
	if not target or target == player or not root then
		return say(player, "/ceder <pseudo>  (debout sur ton terrain, l'autre joueur présent dans ce monde)")
	end
	local owner, plot = G.Parcelles.at(root.Position)
	if owner ~= G.Util.pid(player) or not plot then
		return say(player, "Tiens-toi sur un de tes terrains pour le céder.")
	end
	offers[target] = { from = player, x = plot.x, z = plot.z, t = os.clock() }
	say(player, "📜 Proposé à " .. target.DisplayName .. " (il doit taper /accepter dans la minute).")
	say(target, "📜 " .. player.DisplayName .. " veut te céder un terrain. Tape /accepter pour le prendre.", "big")
end

-- /louer <pseudo> <jours> <prix> : l'autre tape /accepter, paie, et peut bâtir / ouvrir chez toi
-- (accès « batir ») pendant N jours de jeu ; l'accès expire seul (Admin.newDay)
local function rent(player: Player, args)
	local target = findPlayer(args[1])
	local days = math.clamp(math.floor(tonumber(args[2]) or 0), 1, 60)
	local price = math.clamp(math.floor(tonumber(args[3]) or -1), 0, 1000000)
	if not target or target == player or not tonumber(args[2]) or not tonumber(args[3]) then
		return say(player, "/louer <pseudo> <jours> <prix>  (l'autre joueur présent dans ce monde)")
	end
	offers[target] = { from = player, rent = true, days = days, price = price, t = os.clock() }
	say(player, "📜 Location proposée à " .. target.DisplayName .. " : " .. days .. " jour(s) pour " .. price .. " or.")
	say(target, "📜 " .. player.DisplayName .. " te loue ses terres " .. days .. " jour(s) pour " .. price .. " or (bâtir, ouvrir portes et coffres). /accepter pour louer.", "big")
end

local function acceptRent(player: Player, o)
	if o.price > 0 and not G.Joueurs.take(player, "gold", o.price) then
		return say(player, "Il te faut " .. o.price .. " or.")
	end
	if o.price > 0 then
		G.Joueurs.add(o.from, "gold", o.price)
		G.Joueurs.sync(o.from)
	end
	G.Joueurs.sync(player)
	local rec = G.Mondes.playerRecord(o.from)
	if not rec then
		return
	end
	local uid = tostring(player.UserId)
	rec.trust = rec.trust or {}
	rec.trustUntil = rec.trustUntil or {}
	rec.trust[uid] = "batir"
	rec.trustUntil[uid] = G.world.day + o.days
	G.Economie.record(o.from, "location", "à " .. player.UserId .. " pour " .. o.days .. " j (+" .. o.price .. ")")
	say(player, "🔑 Tu loues les terres de " .. o.from.DisplayName .. " pour " .. o.days .. " jour(s).", "gain")
	say(o.from, "🔑 " .. player.DisplayName .. " loue tes terres (" .. o.days .. " j, +" .. o.price .. " or).", "gain")
end

-- chaque matin : les locations arrivées à terme rendent l'accès
function Admin.newDay()
	for uid, rec in (G.world and G.world.players) or {} do
		for who, untilDay in rec.trustUntil or {} do
			if G.world.day >= untilDay then
				rec.trustUntil[who] = nil
				if rec.trust then
					rec.trust[who] = nil
				end
				local owner = Players:GetPlayerByUserId(tonumber(uid) or 0)
				if owner then
					say(owner, "🔑 Une location de tes terres est arrivée à terme.")
				end
			end
		end
	end
end

local function acceptCede(player: Player)
	local o = offers[player]
	offers[player] = nil
	if not o or os.clock() - o.t > 60 or not o.from.Parent then
		return say(player, "Aucune proposition en attente.")
	end
	if o.rent then
		return acceptRent(player, o)
	end
	local fromRec, toRec = G.Mondes.playerRecord(o.from), G.Mondes.playerRecord(player)
	if not fromRec or not toRec then
		return
	end
	local mine = G.Parcelles.plotsOf(fromRec)
	for i, p in mine do
		if p.x == o.x and p.z == o.z then
			table.remove(mine, i)
			p.name, p.since = player.DisplayName, G.world.day
			table.insert(G.Parcelles.plotsOf(toRec), p)
			G.Parcelles.publish()
			G.Economie.record(o.from, "terrain", "cédé à " .. player.UserId .. " (" .. o.x .. "," .. o.z .. ")")
			say(player, "🏡 Ce terrain est maintenant à toi.", "big")
			say(o.from, "🏡 Terrain cédé à " .. player.DisplayName .. ".")
			return
		end
	end
	say(player, "Ce terrain n'est plus disponible.")
end

-- ---------------------------------------------------------------- commandes entre joueurs (18/11)
-- « Je cherche n × objet pour P or » : l'or est BLOQUÉ à la création ; n'importe qui livre, il est payé
-- tout de suite et la marchandise part au commanditaire par courrier (même absent). Annulable :
-- l'or revient par courrier. Données : G.world.extra.commandes (sauvegardées avec le monde).
local function orders()
	G.world.extra = G.world.extra or {}
	G.world.extra.commandes = G.world.extra.commandes or { n = 0, list = {} }
	return G.world.extra.commandes
end

local function orderCreate(player: Player, args)
	local item, n, price = args[1], math.floor(tonumber(args[2]) or 0), math.floor(tonumber(args[3]) or 0)
	local info = item and Config.ITEMS[item]
	if not info or item == "gold" or n < 1 or n > 9999 or price < 1 or price > 1000000 then
		return say(player, "/commande <objet> <quantité> <prix total>  (ex. /commande wood 50 120)")
	end
	if not G.Joueurs.take(player, "gold", price) then
		return say(player, "Il te faut " .. price .. " or (bloqués jusqu'à la livraison).")
	end
	local o = orders()
	o.n += 1
	o.list[tostring(o.n)] = { buyer = player.UserId, name = player.DisplayName, item = item, n = n, price = price, day = G.world.day }
	G.Joueurs.sync(player)
	G.Economie.record(player, "commande", "#" .. o.n .. " " .. n .. " " .. item .. " (-" .. price .. " bloqués)")
	say(player, "📦 Commande n°" .. o.n .. " : " .. n .. " " .. info.name .. " pour " .. price .. " or. Les autres la voient avec /commandes.", "gain")
end

local function orderList(player: Player)
	local lines = {}
	for id, c in orders().list do
		local info = Config.ITEMS[c.item]
		table.insert(lines, "n°" .. id .. " · " .. c.n .. " " .. (info and info.name or c.item) .. " → " .. c.price .. " or (" .. c.name .. ")")
	end
	if #lines == 0 then
		return say(player, "Aucune commande ouverte dans ce monde. (/commande pour en passer une)")
	end
	table.sort(lines)
	for i = 1, math.min(12, #lines) do
		say(player, "📦 " .. lines[i])
	end
	say(player, "Pour livrer : /livrer <n°>")
end

local function orderDeliver(player: Player, args)
	local o = orders()
	local id = tostring(math.floor(tonumber(args[1]) or 0))
	local c = o.list[id]
	if not c then
		return say(player, "/livrer <n°>  (voir /commandes)")
	end
	if c.buyer == player.UserId then
		return say(player, "C'est ta propre commande (/annuler " .. id .. " pour la retirer).")
	end
	if not G.Joueurs.take(player, c.item, c.n) then
		local info = Config.ITEMS[c.item]
		return say(player, "Il te faut " .. c.n .. " " .. (info and info.name or c.item) .. ".")
	end
	o.list[id] = nil -- d'abord retirée : personne d'autre ne peut la livrer
	G.Poste.deliverSystem(c.buyer, { from = player.DisplayName, items = { [c.item] = c.n } })
	G.Joueurs.add(player, "gold", c.price)
	G.Joueurs.addSkillXp(player, "commerce", 3)
	G.Joueurs.sync(player)
	G.Economie.record(player, "livraison", "#" .. id .. " pour " .. c.buyer .. " (+" .. c.price .. ")")
	say(player, "📦 Livré ! +" .. c.price .. " or.", "gain")
	local buyer = Players:GetPlayerByUserId(c.buyer)
	if buyer then
		say(buyer, "📦 Ta commande n°" .. id .. " est livrée par " .. player.DisplayName .. " : récupère-la à une boîte aux lettres.", "gain")
	end
end

local function orderCancel(player: Player, args)
	local o = orders()
	local id = tostring(math.floor(tonumber(args[1]) or 0))
	local c = o.list[id]
	if not c or c.buyer ~= player.UserId then
		return say(player, "/annuler <n°>  (une de tes commandes)")
	end
	o.list[id] = nil
	G.Poste.deliverSystem(c.buyer, { from = "Commande annulée", gold = c.price })
	say(player, "Commande n°" .. id .. " annulée : " .. c.price .. " or te reviennent par courrier.")
end

local function onCommand(player: Player, text: string)
	local words = string.split(text, " ")
	local cmd = string.lower(words[1] or "")
	local args = {}
	for i = 2, #words do
		if words[i] ~= "" then
			table.insert(args, words[i])
		end
	end
	if cmd == "/aide" then
		say(player, "💬 /coince · /signaler <pseudo> <motif> · /bloquer · /debloquer · /bloques")
		say(player, "🔑 /autoriser <pseudo> [coffres|batir] · /retirer · /autorises · /ceder <pseudo> · /louer <pseudo> <jours> <prix> · /accepter")
		say(player, "📦 /commande <objet> <n> <prix> · /commandes · /livrer <n°> · /annuler <n°> · 🧱 /demonter <rayon>")
	elseif cmd == "/demonter" then
		local r = tonumber(args[1])
		if not r then
			return say(player, "/demonter <rayon 1-12>  (reprend TES pièces de construction autour de toi, matériaux rendus)")
		end
		local n = G.Batir.removeAround(player, r)
		say(player, n > 0 and ("🧱 " .. n .. " pièce(s) reprise(s), matériaux rendus.") or "Aucune de tes pièces dans ce rayon.")
	elseif cmd == "/coince" then
		unstuck(player)
	elseif cmd == "/signaler" then
		report(player, args)
	elseif cmd == "/ceder" then
		cede(player, args)
	elseif cmd == "/accepter" then
		acceptCede(player)
	elseif cmd == "/louer" then
		rent(player, args)
	elseif cmd == "/commande" then
		orderCreate(player, args)
	elseif cmd == "/commandes" then
		orderList(player)
	elseif cmd == "/livrer" then
		orderDeliver(player, args)
	elseif cmd == "/annuler" then
		orderCancel(player, args)
	elseif cmd == "/bloquer" then
		block(player, args[1], true)
	elseif cmd == "/debloquer" then
		block(player, args[1], false)
	elseif cmd == "/autoriser" or cmd == "/retirer" then
		local target = findPlayer(args[1])
		local rec = G.Mondes.playerRecord(player)
		if not target or target == player or not rec then
			return say(player, "/autoriser <pseudo> [coffres|batir] · /retirer <pseudo>  (joueur présent dans ce monde)")
		end
		rec.trust = rec.trust or {}
		if cmd == "/retirer" then
			rec.trust[tostring(target.UserId)] = nil
			say(player, "🔒 " .. target.DisplayName .. " n'a plus accès à tes biens dans ce monde.")
			G.Economie.record(player, "acces", "retiré à " .. target.UserId)
		else
			local level = (args[2] == "batir" or args[2] == "bâtir") and "batir" or "coffres"
			rec.trust[tostring(target.UserId)] = level
			say(player, "🔑 " .. target.DisplayName .. " peut " .. (level == "batir" and "ouvrir tes coffres et portes ET construire sur tes parcelles." or "ouvrir tes coffres et tes portes.") .. " (/retirer pour annuler)")
			say(target, "🔑 " .. player.DisplayName .. " te fait confiance : tu peux " .. (level == "batir" and "ouvrir ses coffres et construire chez lui." or "ouvrir ses coffres et ses portes."), "gain")
			G.Economie.record(player, "acces", level .. " donné à " .. target.UserId)
		end
	elseif cmd == "/autorises" then
		local rec = G.Mondes.playerRecord(player)
		local names = {}
		for uid, lvl in (rec and rec.trust) or {} do
			local p = Players:GetPlayerByUserId(tonumber(uid))
			table.insert(names, (p and p.DisplayName or uid) .. " (" .. lvl .. ")")
		end
		say(player, #names > 0 and ("🔑 " .. table.concat(names, ", ")) or "Tu n'as donné d'accès à personne dans ce monde.")
	elseif cmd == "/bloques" then
		local prof = G.Joueurs.get(player)
		local names = {}
		for _, n in (prof and prof.blocked) or {} do
			table.insert(names, n)
		end
		say(player, #names > 0 and ("🚫 " .. table.concat(names, ", ")) or "Tu n'as bloqué personne.")
	elseif cmd == "/wa" then
		if not isAdmin(player) then
			return
		end
		local sub = string.lower(table.remove(args, 1) or "aide")
		local fn = ADMIN[sub]
		if not fn then
			return say(player, "Commande inconnue. /wa aide")
		end
		G.Economie.record(player, "admin", text)
		local ok, err = pcall(fn, player, args)
		if not ok then
			say(player, "Erreur : " .. tostring(err))
		end
	end
end

function Admin.init(g)
	G = g
	Config = G.Config
	if not (RunService:IsStudio() and not workspace:GetAttribute("StudioDataStore")) then
		local ok, ds = pcall(function()
			return DataStoreService:GetDataStore("WA_Journal")
		end)
		journal = ok and ds or nil
	end
	-- commandes de chat (TextChatService)
	local folder = TextChatService:FindFirstChild("CommandesWA") or Instance.new("Folder")
	folder.Name = "CommandesWA"
	folder.Parent = TextChatService
	for _, alias in { "/wa", "/bloquer", "/debloquer", "/bloques", "/autoriser", "/retirer", "/autorises", "/coince", "/signaler", "/ceder", "/accepter", "/louer", "/commande", "/commandes", "/livrer", "/annuler", "/aide", "/demonter" } do
		local c = folder:FindFirstChild(alias) or Instance.new("TextChatCommand")
		c.Name = alias
		c.PrimaryAlias = alias
		c.Parent = folder
		c.Triggered:Connect(function(source, text)
			local p = source and Players:GetPlayerByUserId(source.UserId)
			if p then
				onCommand(p, text)
			end
		end)
	end
	-- annonces inter-serveurs (en tâche de fond : SubscribeAsync peut attendre, l'init ne doit jamais bloquer)
	task.spawn(pcall, function()
		MessagingService:SubscribeAsync("WA_Annonce", function(msg)
			for _, p in Players:GetPlayers() do
				say(p, "📢 " .. tostring(msg.Data), "big")
			end
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(60)
			pcall(flushJournal)
		end
	end)
	game:BindToClose(function()
		pcall(flushJournal)
	end)
end

-- Pour les tests (DbgAppel) : exécuter une ligne de commande comme si un joueur l'avait tapée
function Admin.run(player: Player, text: string)
	onCommand(player, text)
	return true
end

return Admin
