-- Demandes des joueurs à l'équipe (20/11, décision : « sanction → fais un truc de demandes, aussi un report bug »).
--   /demande <texte> : une question, un problème de compte, une aide ;
--   /bug <texte>     : signaler un bug (le monde, la position, le jour sont joints tout seuls) ;
--   /appel <texte>   : contester une sanction (avertissement, muet, expulsion, bannissement).
-- Aussi par l'action « demande » { kind = "demande" | "bug" | "appel", text } (formulaire de l'interface).
-- Le texte est filtré (TextService) avant d'être gardé : seuls les admins le lisent, mais c'est la règle.
-- Admins : /wa demandes [bug|appel|demande] · /wa repondre <n°> <texte> · /wa clore <n°>.
-- La réponse arrive au joueur tout de suite s'il est là, sinon à sa prochaine connexion (n'importe quel
-- serveur). Rangé dans le DataStore WA_Demandes (clé "file" : les 300 dernières), en mémoire dans Studio.
--
-- BANNISSEMENT (remplace Players:BanAsync, qui empêchait même de faire appel) : WA_Demandes "ban_<uid>".
-- Un banni ne peut entrer dans aucun monde ; sur l'écran d'accueil il reste MUET et peut faire /appel.

local Demandes = {}
local G

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

Demandes.KINDS = { demande = "❓ Demande", bug = "🐞 Bug", appel = "⚖️ Appel" }
Demandes.PER_DAY = 3 -- par joueur et par jour réel (anti-spam de la file des admins)
Demandes.KEEP = 300
local MIN_LEN, MAX_LEN = 10, 300

local store -- DataStore, ou nil (Studio sans accès aux API : mémoire)
local memory = { file = {}, n = 0, bans = {} }
local sentToday = {} -- uid -> { day, n }
local banCache = {} -- uid -> { info, t }

local function useStore(): boolean
	return store ~= nil
end

local function update(key: string, fn)
	if not useStore() then
		if key == "file" then
			local v = fn({ n = memory.n, list = memory.file })
			if v then
				memory.n, memory.file = v.n, v.list
			end
			return v
		end
		local v = fn(memory.bans[key])
		memory.bans[key] = v
		return v
	end
	local out
	local ok, err = pcall(function()
		store:UpdateAsync(key, function(old)
			out = fn(old)
			return out
		end)
	end)
	if not ok then
		warn("[WildAcres] demandes : " .. tostring(err))
		return nil
	end
	return out
end

local function read(key: string)
	if not useStore() then
		if key == "file" then
			return { n = memory.n, list = memory.file }
		end
		return memory.bans[key]
	end
	local ok, v = pcall(store.GetAsync, store, key)
	return ok and v or nil
end

local function filter(player: Player, text: string): string?
	if RunService:IsStudio() then
		return text
	end
	local ok, res = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	return ok and res or nil
end

-- ---------------------------------------------------------------- déposer une demande

-- Renvoie (ok, message pour le joueur)
function Demandes.submit(player: Player, kind: any, text: any): (boolean, string)
	if type(kind) ~= "string" or not Demandes.KINDS[kind] then
		return false, "Sorte de demande inconnue (demande, bug, appel)."
	end
	text = type(text) == "string" and string.gsub(string.gsub(text, "^%s+", ""), "%s+$", "") or ""
	if #text < MIN_LEN then
		return false, "Explique en quelques mots (au moins " .. MIN_LEN .. " lettres)."
	end
	text = string.sub(text, 1, MAX_LEN)
	local uid = player.UserId
	local today = os.date("!%Y-%m-%d")
	local s = sentToday[uid]
	if not s or s.day ~= today then
		s = { day = today, n = 0 }
		sentToday[uid] = s
	end
	if s.n >= Demandes.PER_DAY then
		return false, "Tu as déjà envoyé " .. Demandes.PER_DAY .. " demandes aujourd'hui : l'équipe les lit, patience."
	end
	local clean = filter(player, text)
	if not clean then
		return false, "Le message n'a pas pu être vérifié, réessaie dans un moment."
	end
	-- contexte joint tout seul (utile surtout pour un bug)
	local ctx = {}
	local root = G.Util and G.Util.root and G.Util.root(player)
	if root then
		local p = root.Position
		table.insert(ctx, string.format("pos %d,%d,%d", math.floor(p.X), math.floor(p.Y), math.floor(p.Z)))
		local okB, biome = pcall(function()
			return G.Clock.biomeAt(p)
		end)
		if okB and biome then
			table.insert(ctx, biome)
		end
	end
	if G.Mondes then
		table.insert(ctx, "monde " .. tostring(G.Mondes.id or G.Mondes.mode))
	end
	if G.world then
		table.insert(ctx, "jour " .. tostring(G.world.day))
	end
	table.insert(ctx, "serveur " .. string.sub(game.JobId, 1, 8))
	local entry
	local res = update("file", function(old)
		old = type(old) == "table" and old or { n = 0, list = {} }
		old.n = (old.n or 0) + 1
		entry = { id = old.n, uid = uid, name = player.Name, kind = kind, text = clean, t = os.time(), ctx = table.concat(ctx, " · "),
			state = "ouverte" }
		table.insert(old.list, entry)
		while #old.list > Demandes.KEEP do
			table.remove(old.list, 1)
		end
		return old
	end)
	if not res then
		return false, "La demande n'a pas pu être enregistrée, réessaie dans un moment."
	end
	s.n += 1
	if G.Economie and G.Economie.record then
		G.Economie.record(player, "demande", kind .. " n°" .. entry.id)
	end
	-- admins présents prévenus
	for _, p in Players:GetPlayers() do
		if p ~= player and G.Admin and G.Admin.isAdmin and G.Admin.isAdmin(p) then
			G.Util.toast(p, Demandes.KINDS[kind] .. " n°" .. entry.id .. " de " .. player.Name .. " : " .. string.sub(clean, 1, 80))
		end
	end
	return true, Demandes.KINDS[kind] .. " n°" .. entry.id .. " reçue. La réponse t'arrivera ici, même si tu changes de monde."
end

-- ---------------------------------------------------------------- côté admins

function Demandes.list(kind: string?, all: boolean?): { any }
	local f = read("file")
	local out = {}
	for i = #((f and f.list) or {}), 1, -1 do
		local e = f.list[i]
		if (all or e.state == "ouverte") and (not kind or e.kind == kind) then
			table.insert(out, e)
		end
	end
	return out
end

local function deliver(e)
	local p = Players:GetPlayerByUserId(e.uid)
	if p and e.reply and not e.notified then
		G.Util.toast(p, "📨 Réponse à ta " .. string.lower(Demandes.KINDS[e.kind] or "demande") .. " n°" .. e.id .. " : " .. e.reply, "big")
		return true
	end
	return false
end

function Demandes.reply(admin: Player, id: number, text: string, close: boolean?): (boolean, string)
	local done
	update("file", function(old)
		old = type(old) == "table" and old or { n = 0, list = {} }
		for _, e in old.list do
			if e.id == id then
				if text and text ~= "" then
					e.reply = string.sub(text, 1, MAX_LEN)
					e.by = admin.Name
					e.notified = nil
				end
				e.state = "traitée"
				done = table.clone(e)
			end
		end
		return old
	end)
	if not done then
		return false, "Demande n°" .. tostring(id) .. " introuvable."
	end
	if done.reply and deliver(done) then
		update("file", function(old)
			for _, e in (old and old.list) or {} do
				if e.id == id then
					e.notified = true
				end
			end
			return old
		end)
	end
	if G.Economie and G.Economie.record then
		G.Economie.record(admin, "demande_reponse", "n°" .. id)
	end
	return true, "Demande n°" .. id .. (done.reply and " : réponse envoyée." or " close.")
end

-- à la connexion : les réponses arrivées pendant l'absence
local function onJoin(player: Player)
	local f = read("file")
	local mine = {}
	for _, e in (f and f.list) or {} do
		if e.uid == player.UserId and e.reply and not e.notified then
			table.insert(mine, e.id)
			deliver(e)
		end
	end
	if #mine > 0 then
		update("file", function(old)
			for _, e in (old and old.list) or {} do
				if table.find(mine, e.id) then
					e.notified = true
				end
			end
			return old
		end)
	end
end

-- ---------------------------------------------------------------- bannissement (sans fermer la porte de l'appel)

function Demandes.banInfo(uid: number)
	local c = banCache[uid]
	local info
	if c and os.clock() - c.t < 60 then
		info = c.info
	else
		info = read("ban_" .. uid)
		banCache[uid] = { info = info, t = os.clock() }
	end
	-- terminé : plus banni (même si l'info vient du cache)
	if type(info) ~= "table" or (info["until"] or 0) <= os.time() then
		return nil
	end
	return info
end

function Demandes.isBanned(player: Player): boolean
	return Demandes.banInfo(player.UserId) ~= nil
end

function Demandes.ban(uid: number, days: number, why: string, by: string)
	local info = { ["until"] = os.time() + days * 86400, why = why, by = by, t = os.time() }
	update("ban_" .. uid, function()
		return info
	end)
	banCache[uid] = { info = info, t = os.clock() }
	return info
end

function Demandes.unban(uid: number)
	update("ban_" .. uid, function()
		return nil
	end)
	banCache[uid] = nil
end

local function banText(info): string
	local left = math.max(1, math.ceil(((info["until"] or 0) - os.time()) / 86400))
	return "Banni encore " .. left .. " jour(s) : " .. tostring(info.why ~= "" and info.why or "comportement")
end
Demandes.banText = banText

-- sur l'accueil, les messages d'un banni ne sont remis à personne (ses commandes, dont /appel, marchent)
local silenced = {} -- uid -> true
local function hookChat()
	task.spawn(function()
		local chans = TextChatService:WaitForChild("TextChannels", 30)
		local general = chans and chans:WaitForChild("RBXGeneral", 30)
		if general and general:IsA("TextChannel") then
			general.ShouldDeliverCallback = function(message)
				local src = message.TextSource
				return not (src and silenced[src.UserId])
			end
		end
	end)
end

-- arrivée d'un joueur : un banni ne joue pas ; sur l'accueil il peut seulement faire appel
local function checkBan(player: Player)
	local info = Demandes.banInfo(player.UserId)
	if not info then
		return
	end
	if G.Mondes and G.Mondes.mode == "accueil" then
		player:SetAttribute("Banni", info["until"])
		silenced[player.UserId] = true
		task.delay(3, function()
			if player.Parent then
				G.Util.toast(player, "⛔ " .. banText(info) .. ". Pour contester : /appel <ton explication>.", "danger")
			end
		end)
	else
		player:Kick(banText(info) .. ". Pour contester, rejoins l'écran d'accueil du jeu et tape /appel <ton explication>.")
	end
end

function Demandes.init(g)
	G = g
	if not (RunService:IsStudio() and not workspace:GetAttribute("StudioDataStore")) then
		local ok, ds = pcall(function()
			return DataStoreService:GetDataStore("WA_Demandes")
		end)
		store = ok and ds or nil
	end
	G.Interact.onAction("demande", function(player, data)
		local ok, msg = Demandes.submit(player, data.kind, data.text)
		G.Util.toast(player, msg, ok and "gain" or "danger")
	end)
	local function joined(p: Player)
		task.spawn(checkBan, p)
		task.delay(8, function()
			if p.Parent then
				onJoin(p)
			end
		end)
	end
	Players.PlayerAdded:Connect(joined)
	for _, p in Players:GetPlayers() do
		joined(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		banCache[p.UserId] = nil
		silenced[p.UserId] = nil
	end)
	if G.Mondes and G.Mondes.mode == "accueil" then
		hookChat()
	end
end

return Demandes
