-- Clans (communs à tous les mondes, comme le personnage) : nom + tag filtrés par Roblox, 6 grades,
-- PAS de guerre annoncée ni de règle spéciale : les conflits naissent d'eux-mêmes (raids, vols, primes),
-- avec les règles normales (étoiles, primes) pour tout le monde.
-- coffre commun écrit de façon atomique (UpdateAsync : pas de duplication entre serveurs), journal.
-- Fonder un clan coûte 1000 or. Données : DataStore WA_Clans, clé "c_<id>" ; noms réservés "nom_<nom>".

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Clans = {}
local G, Config
local store = nil
local cache = {} -- id -> {data, t}
local memory = {} -- repli Studio sans DataStore
local invites = {}

Clans.RANKS = { "Recrue", "Membre", "Intendant", "Officier", "Bras droit", "Chef" }
local R = { recrue = 1, membre = 2, intendant = 3, officier = 4, bras = 5, chef = 6 }
local FOUND_COST = 1000


function Clans.init(g)
	G = g
	Config = G.Config
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore("WA_Clans" .. (RunService:IsStudio() and "_studio" or ""))
	end)
	store = ok and ds or nil
	if RunService:IsStudio() and not workspace:GetAttribute("StudioDataStore") then
		store = nil
	end
	G.Interact.onAction("clan_open", function(player)
		Clans.open(player)
	end)
	G.Interact.onAction("clan_create", function(player, data)
		Clans.create(player, data.name, data.tag)
	end)
	G.Interact.onAction("clan_invite", function(player, data)
		Clans.invite(player, tonumber(data.target))
	end)
	G.Interact.onAction("clan_accept", function(player)
		Clans.accept(player)
	end)
	G.Interact.onAction("clan_leave", function(player)
		Clans.leave(player)
	end)
	G.Interact.onAction("clan_rank", function(player, data)
		Clans.setRank(player, tonumber(data.target), tonumber(data.delta))
	end)
	G.Interact.onAction("clan_kick", function(player, data)
		Clans.kick(player, tonumber(data.target))
	end)
	G.Interact.onAction("clan_chest", function(player)
		Clans.sendChest(player)
	end)
	Players.PlayerRemoving:Connect(function(p)
		invites[p] = nil
	end)
end

-- ----------------------------------------------------------------- Stockage

local function decode(v)
	if type(v) == "string" then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, v)
		return ok and t or nil
	end
	return v
end

local function load(id: string, fresh: boolean?)
	if not id then
		return nil
	end
	local c = cache[id]
	if c and not fresh and os.clock() - c.t < 60 then
		return c.data
	end
	local data
	if store then
		local ok, v = pcall(function()
			return store:GetAsync("c_" .. id)
		end)
		data = ok and decode(v) or (c and c.data)
	else
		data = memory[id]
	end
	cache[id] = { data = data, t = os.clock() }
	return data
end

-- Modification atomique (renvoie le nouvel état, ou nil si refusée par fn).
-- Chaque modification porte un identifiant de transaction gardé dans d.tx (50 derniers) : si
-- UpdateAsync renvoie une erreur alors que l'écriture a eu lieu, la relecture le voit et on ne
-- rembourse / ne refuse pas à tort (pas de doublon ni de perte dans le coffre commun).
local function update(id: string, fn: (any) -> any)
	local result
	if store then
		local txid = HttpService:GenerateGUID(false)
		local ok, err = pcall(function()
			store:UpdateAsync("c_" .. id, function(old)
				local d = decode(old)
				if not d then
					return nil
				end
				local new = fn(d)
				if new == nil then
					return nil
				end
				new.tx = new.tx or {}
				table.insert(new.tx, txid)
				while #new.tx > 50 do
					table.remove(new.tx, 1)
				end
				result = new
				return HttpService:JSONEncode(new)
			end)
		end)
		if not ok then
			warn("[WildAcres] clan " .. id .. " : " .. tostring(err))
			result = nil
			task.wait(1)
			local okR, raw = pcall(function()
				return store:GetAsync("c_" .. id)
			end)
			local d = okR and decode(raw)
			if d and table.find(d.tx or {}, txid) then
				result = d -- l'écriture avait bien eu lieu
			end
		end
	else
		local d = memory[id]
		if d then
			result = fn(d)
		end
	end
	if result then
		cache[id] = { data = result, t = os.clock() }
	end
	return result
end

local function log(d, text: string)
	d.log = d.log or {}
	table.insert(d.log, { t = os.time(), text = text })
	while #d.log > 30 do
		table.remove(d.log, 1)
	end
end

local function rankOf(d, player: Player): number
	return d and d.members[tostring(player.UserId)] or 0
end

function Clans.of(player: Player)
	local p = G.Joueurs.get(player)
	return p and p.clan and load(p.clan) or nil, p and p.clan
end

local function refreshTag(player: Player)
	local d = Clans.of(player)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("Clan")
		if not v then
			v = Instance.new("StringValue")
			v.Name = "Clan"
			v.Parent = ls
		end
		v.Value = d and ("[" .. d.tag .. "]") or ""
	end
end
Clans.refreshTag = refreshTag

local function filter(player: Player, text: string): string?
	local ok, res = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		return RunService:IsStudio() and text or nil
	end
	if string.find(res, "#", 1, true) then
		return nil
	end
	return res
end

-- ----------------------------------------------------------------- Fondation, invitations, grades

function Clans.create(player: Player, name: string, tag: string)
	local p = G.Joueurs.get(player)
	if not p or p.clan then
		return
	end
	if type(name) ~= "string" or type(tag) ~= "string" then
		return
	end
	name = string.sub(string.gsub(name, "^%s+", ""), 1, 24)
	tag = string.upper(string.sub(string.gsub(tag, "[^%w]", ""), 1, 4))
	if #name < 3 or #tag < 2 then
		G.Util.toast(player, "Nom (3 à 24 lettres) et tag (2 à 4 lettres) obligatoires.")
		return
	end
	if not G.Joueurs.has(player, "gold", FOUND_COST) then
		G.Util.toast(player, "Fonder un clan coûte " .. FOUND_COST .. " 💰.")
		return
	end
	local fname, ftag = filter(player, name), filter(player, tag)
	if not fname or not ftag then
		G.Util.toast(player, "Ce nom n'est pas accepté. Essaie autre chose.")
		return
	end
	local id = string.sub(HttpService:GenerateGUID(false), 1, 8)
	-- réserve le nom (un seul clan par nom)
	if store then
		local taken = false
		local ok = pcall(function()
			store:UpdateAsync("nom_" .. string.lower(fname), function(old)
				if old then
					taken = true
					return nil
				end
				return id
			end)
		end)
		if not ok or taken then
			G.Util.toast(player, "Ce nom de clan est déjà pris.")
			return
		end
	end
	local data = {
		name = fname, tag = ftag, created = os.time(), leader = player.UserId,
		members = { [tostring(player.UserId)] = R.chef }, names = { [tostring(player.UserId)] = player.DisplayName },
		chest = {}, log = {},
	}
	log(data, player.DisplayName .. " fonde le clan.")
	if store then
		local ok = pcall(function()
			store:SetAsync("c_" .. id, HttpService:JSONEncode(data))
		end)
		if not ok then
			G.Util.toast(player, "La fondation a échoué, réessaie.")
			return
		end
	else
		memory[id] = data
	end
	G.Joueurs.take(player, "gold", FOUND_COST)
	cache[id] = { data = data, t = os.clock() }
	p.clan = id
	G.Joueurs.markDirty(player)
	refreshTag(player)
	G.Economie.record(player, "clan", "fondation " .. fname)
	G.Util.toast(player, "🛡️ Clan [" .. ftag .. "] " .. fname .. " fondé !", "big")
	Clans.open(player)
end

function Clans.invite(player: Player, targetId: number?)
	local d, id = Clans.of(player)
	local target = targetId and Players:GetPlayerByUserId(targetId)
	if not d or not target or rankOf(d, player) < R.officier then
		if d then
			G.Util.toast(player, "Il faut être Officier ou plus pour inviter.")
		end
		return
	end
	if G.Admin.blocks and G.Admin.blocks(target, player) then
		G.Util.toast(player, target.DisplayName .. " ne reçoit pas tes propositions.")
		return
	end
	local tp = G.Joueurs.get(target)
	if not tp or tp.clan then
		G.Util.toast(player, target.DisplayName .. " a déjà un clan.")
		return
	end
	invites[target] = { id = id, from = player, t = os.clock() }
	G.remotes.Menu:FireClient(target, { kind = "clan_invite", from = player.DisplayName, clan = d.name, tag = d.tag })
	G.Util.toast(player, "Invitation envoyée à " .. target.DisplayName .. ".")
end

function Clans.accept(player: Player)
	local inv = invites[player]
	invites[player] = nil
	if inv and os.clock() - (inv.t or 0) > 60 then
		G.Util.toast(player, "Cette invitation a expiré.")
		return
	end
	local p = G.Joueurs.get(player)
	if not inv or not p or p.clan then
		return
	end
	local uid = tostring(player.UserId)
	local d = update(inv.id, function(d)
		d.members[uid] = R.recrue
		d.names = d.names or {}
		d.names[uid] = player.DisplayName
		log(d, player.DisplayName .. " rejoint le clan.")
		return d
	end)
	if d then
		p.clan = inv.id
		G.Joueurs.markDirty(player)
		refreshTag(player)
		G.Util.toast(player, "🛡️ Bienvenue dans [" .. d.tag .. "] " .. d.name .. " !", "big")
	end
end

function Clans.leave(player: Player)
	local p = G.Joueurs.get(player)
	if not p or not p.clan then
		return
	end
	local id = p.clan
	local uid = tostring(player.UserId)
	local after = update(id, function(d)
		d.members[uid] = nil
		log(d, player.DisplayName .. " quitte le clan.")
		-- le chef part : le plus gradé prend la tête
		if d.leader == player.UserId then
			local best, br = nil, 0
			for m, r in d.members do
				if r > br then
					best, br = m, r
				end
			end
			if best then
				d.leader = tonumber(best)
				d.members[best] = R.chef
			end
		end
		-- plus personne : le clan est dissous (son nom redevient libre ; le coffre reste archivé)
		if next(d.members) == nil then
			d.dissolved = true
			log(d, "Le clan est dissous.")
		end
		return d
	end)
	if after and after.dissolved and store and after.name then
		pcall(function()
			store:RemoveAsync("nom_" .. string.lower(after.name))
		end)
	end
	p.clan = nil
	G.Joueurs.markDirty(player)
	refreshTag(player)
	G.Util.toast(player, "Tu as quitté ton clan.")
end

function Clans.setRank(player: Player, targetId: number?, delta: number?)
	local d, id = Clans.of(player)
	if not d or not targetId or (delta ~= 1 and delta ~= -1) then
		return
	end
	local me = rankOf(d, player)
	local t = tostring(targetId)
	local cur = d.members[t]
	if not cur or me < R.officier or cur >= me or cur + delta >= me or cur + delta < 1 then
		G.Util.toast(player, "Tu ne peux pas changer ce grade.")
		return
	end
	update(id, function(d2)
		if d2.members[t] then
			d2.members[t] = math.clamp(d2.members[t] + delta, 1, R.bras)
			log(d2, player.DisplayName .. (delta > 0 and " promeut " or " rétrograde ") .. ((d2.names or {})[t] or t) .. " : " .. Clans.RANKS[d2.members[t]])
		end
		return d2
	end)
	Clans.open(player)
end

function Clans.kick(player: Player, targetId: number?)
	local d, id = Clans.of(player)
	if not d or not targetId then
		return
	end
	local t = tostring(targetId)
	local cur = d.members[t]
	if not cur or rankOf(d, player) < R.officier or cur >= rankOf(d, player) then
		return
	end
	update(id, function(d2)
		d2.members[t] = nil
		log(d2, player.DisplayName .. " exclut " .. ((d2.names or {})[t] or t))
		return d2
	end)
	local target = Players:GetPlayerByUserId(targetId)
	local tp = target and G.Joueurs.get(target)
	if tp then
		tp.clan = nil
		refreshTag(target)
		G.Util.toast(target, "Tu as été exclu de ton clan.", "danger")
	end
	Clans.open(player)
end

-- ----------------------------------------------------------------- Panneau et coffre commun

function Clans.open(player: Player)
	local p = G.Joueurs.get(player)
	if not p then
		return
	end
	local d = p.clan and load(p.clan, true)
	if p.clan and not d then
		p.clan = nil -- clan disparu
	end
	if not d then
		G.remotes.Menu:FireClient(player, { kind = "clan", none = true, cost = FOUND_COST })
		return
	end
	-- encore membre ? (exclu pendant qu'on était ailleurs)
	if not d.members[tostring(player.UserId)] then
		p.clan = nil
		refreshTag(player)
		G.remotes.Menu:FireClient(player, { kind = "clan", none = true, cost = FOUND_COST })
		return
	end
	local members = {}
	for uid, r in d.members do
		table.insert(members, { id = tonumber(uid), name = (d.names or {})[uid] or uid, rank = r, rankName = Clans.RANKS[r], online = Players:GetPlayerByUserId(tonumber(uid)) ~= nil })
	end
	table.sort(members, function(a, b)
		return a.rank > b.rank
	end)
	G.remotes.Menu:FireClient(player, {
		kind = "clan", name = d.name, tag = d.tag, members = members, me = rankOf(d, player), log = d.log, ranks = Clans.RANKS,
	})
end

function Clans.sendChest(player: Player)
	local d, id = Clans.of(player)
	if not d then
		return
	end
	d = load(id, true)
	G.remotes.Menu:FireClient(player, { kind = "chest", id = "clan", items = d.chest or {}, mine = true, title = "Coffre du clan [" .. d.tag .. "]" })
end

-- Dépôt : tout membre ; retrait : Intendant ou plus
function Clans.chestMove(player: Player, item: string, n: number, put: boolean)
	local d, id = Clans.of(player)
	if not d or not Config.ITEMS[item] then
		return
	end
	n = math.clamp(math.floor(n), 1, 9999)
	if put then
		n = math.min(n, G.Joueurs.count(player, item))
		if n <= 0 or not G.Joueurs.take(player, item, n) then
			return
		end
		local res = update(id, function(d2)
			d2.chest = d2.chest or {}
			d2.chest[item] = (d2.chest[item] or 0) + n
			log(d2, player.DisplayName .. " dépose " .. n .. " " .. Config.ITEMS[item].name)
			return d2
		end)
		if not res then
			G.Joueurs.add(player, item, n, true) -- échec : on rend
		end
	else
		if rankOf(d, player) < R.intendant then
			G.Util.toast(player, "Seuls les Intendants et plus peuvent prendre dans le coffre du clan.")
			return
		end
		local got = 0
		local res = update(id, function(d2)
			local have = (d2.chest or {})[item] or 0
			got = math.min(have, n)
			if got <= 0 then
				return nil
			end
			d2.chest[item] = have - got
			if d2.chest[item] <= 0 then
				d2.chest[item] = nil
			end
			log(d2, player.DisplayName .. " prend " .. got .. " " .. Config.ITEMS[item].name)
			return d2
		end)
		if res and got > 0 then -- seulement si l'écriture a réussi (pas de duplication)
			G.Joueurs.add(player, item, got, true)
		end
	end
	G.Joueurs.sync(player)
	Clans.sendChest(player)
end

-- ----------------------------------------------------------------- Clan d'un joueur (même absent)

-- Le clan d'un joueur est recopié dans la fiche du monde quand il y est, pour les absents
function Clans.clanOfUid(uid: string): string?
	local player = G.Util.playerOf(uid)
	local p = player and G.Joueurs.get(player)
	if p then
		return p.clan
	end
	local rec = G.world and G.world.players[string.sub(uid or "", 2)]
	return rec and rec.clan or nil
end

function Clans.remember(player: Player)
	local p = G.Joueurs.get(player)
	local rec = G.Mondes.playerRecord(player)
	rec.clan = p and p.clan or nil
	for _, plot in G.Parcelles.plotsOf(rec) do
		plot.clan = rec.clan
	end
end

return Clans
