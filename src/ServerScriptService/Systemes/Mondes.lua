-- Mondes persistants (multi façon MMO + Minecraft).
-- Chaque monde = une graine + une sauvegarde, joué sur un serveur Roblox RÉSERVÉ (un code par monde).
-- Les serveurs publics servent d'ACCUEIL : liste des mondes, nombre de joueurs, bouton Rejoindre.
--
-- Modes :
--   "studio"  : test dans Studio, monde « studio » direct (pas d'accueil, pas de téléportation)
--   "monde"   : serveur réservé (ou serveur privé payant) = un monde
--   "accueil" : serveur public = écran de choix du monde
--
-- Données (DataStore) :
--   WA_Registre : "liste" -> { mondes = { [id] = {name, seed, code, created} } } ; "ps_<PrivateServerId>" -> id
--   WA_Mondes   : "m_<id>" -> état global (graine, jour, heure, PNJ, loi, joueurs) ;
--                 "m_<id>_s_<sx>,<sz>" -> état des régions d'un secteur de 4 x 4 régions
-- En ligne (MemoryStore) : WA_EnLigne : id -> { n = joueurs, name } (expire si le serveur s'arrête)

local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mondes = {}
local G
local Config

Mondes.mode = "studio"
Mondes.id = nil
Mondes.ready = false

local SECTOR = 4 -- régions par côté de secteur
local SUFFIX = RunService:IsStudio() and "_studio" or ""
local registre, store, online
local travelling = {} -- joueur -> { cost, t } : a payé, téléportation en cours
local worldLockLost = false -- un autre serveur a repris ce monde : on n'écrit plus rien
local WORLD_LOCK = 400 -- s ; rafraîchi à chaque sauvegarde du monde (toutes les 150 s)
local sectorState = {} -- sk -> "loading" | "ready"
local sectorJson = {} -- sk -> dernier JSON écrit (évite de réécrire l'identique)
local regionJson = {} -- clé de région -> dernier JSON écrit (secteurs découpés)
local SPLIT_BYTES = 3200000 -- au-delà, un secteur est découpé en une clé par région
local metaJson = nil

local function getStore(name: string)
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore(name .. SUFFIX)
	end)
	return ok and ds or nil
end

-- Appel DataStore avec 3 essais (les quotas sautent parfois)
local function try(fn, ...)
	local lastErr
	for i = 1, 3 do
		local ok, res = pcall(fn, ...)
		if ok then
			return true, res
		end
		lastErr = res
		task.wait(i)
	end
	return false, lastErr
end

local function decode(v)
	if type(v) == "string" then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, v)
		return ok and t or nil
	end
	return v
end

function Mondes.init(g)
	G = g
	Config = G.Config
	registre = getStore("WA_Registre")
	store = getStore("WA_Mondes")
	-- Studio : monde en mémoire, sauf attribut StudioDataStore sur Workspace
	if RunService:IsStudio() and not workspace:GetAttribute("StudioDataStore") then
		registre, store = nil, nil
	end
	local ok, map = pcall(function()
		return MemoryStoreService:GetSortedMap("WA_EnLigne" .. SUFFIX)
	end)
	online = ok and map or nil

	if RunService:IsStudio() then
		Mondes.mode = "studio"
	elseif game.PrivateServerId ~= "" then
		Mondes.mode = "monde"
	else
		Mondes.mode = "accueil"
	end
	workspace:SetAttribute("Mode", Mondes.mode)

	-- Messages de l'écran d'accueil
	local rf = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Mondes")
	if not rf then
		rf = Instance.new("RemoteFunction")
		rf.Name = "Mondes"
		rf.Parent = ReplicatedStorage:WaitForChild("Remotes")
	end
	TeleportService.TeleportInitFailed:Connect(function(p, result, msg)
		warn("[WildAcres] téléportation ratée (" .. tostring(result) .. ") : " .. tostring(msg))
		Mondes.travelFailed(p, "La traversée a échoué")
	end)
	Players.PlayerRemoving:Connect(function(p)
		travelling[p] = nil
	end)
	G.Interact.onAction("seamap", function(player)
		Mondes.openSeaMap(player)
	end)
	G.Interact.onAction("voyage", function(player, data)
		Mondes.travel(player, data.id)
	end)
	G.Interact.onPrompt("port", function(player)
		Mondes.openSeaMap(player)
	end)
	rf.OnServerInvoke = function(player, action, arg)
		if Mondes.mode ~= "accueil" then
			return nil
		end
		if action == "list" then
			return Mondes.list()
		elseif action == "join" then
			return Mondes.join(player, arg)
		elseif action == "play" then
			return Mondes.join(player, Mondes.best(player))
		end
		return nil
	end
end

-- ================================================================ Accueil

local listCache, listTime = nil, 0

local function readRegistry()
	if not registre then
		return { mondes = {} }
	end
	local ok, data = try(function()
		return registre:GetAsync("liste")
	end)
	data = ok and decode(data) or nil
	return data or { mondes = {} }
end

local function onlineCounts(): { [string]: number }
	local out = {}
	if not online then
		return out
	end
	local ok, items = pcall(function()
		return online:GetRangeAsync(Enum.SortDirection.Ascending, 200)
	end)
	if ok and items then
		for _, it in items do
			local v = it.value
			out[it.key] = type(v) == "table" and (v.n or 0) or 0
		end
	end
	return out
end

Mondes.GENERATOR = 2 -- version du générateur (= WorldGen.CURRENT_GEN) : un monde garde à vie sa graine ET sa version

local SYL1 = { "Ver", "Bru", "Kal", "Mor", "Ise", "Ald", "Fen", "Gro", "Lun", "Oss", "Tar", "Vel", "Cor", "Dra", "Eri" }
local SYL2 = { "mo", "ne", "ra", "li", "va", "do", "si", "ka", "ru", "te", "go", "la" }
local SYL3 = { "ral", "nde", "sse", "vin", "mont", "nac", "rie", "lon", "dor", "bre" }
local PREFIX = { "Île de", "Terres de", "Côte de", "Val de", "Archipel de", "Monts de", "Pays de" }

local function worldName(seed: number): string
	local r = Random.new(seed)
	return PREFIX[r:NextInteger(1, #PREFIX)] .. " " .. SYL1[r:NextInteger(1, #SYL1)] .. SYL2[r:NextInteger(1, #SYL2)] .. SYL3[r:NextInteger(1, #SYL3)]
end

-- Résumé d'une île sans la charger : biomes dominants (échantillons du générateur)
local function survey(seed: number)
	local wg = G.WG.new(seed)
	local counts, total = {}, 0
	local R = Config.WORLD_RADIUS * Config.REGION * 0.75
	for i = 0, 63 do
		local a = i * 2.39996
		local d = math.sqrt((i + 0.5) / 64) * R
		local b = wg:biome(math.floor(math.cos(a) * d), math.floor(math.sin(a) * d))
		counts[b] = (counts[b] or 0) + 1
		total += 1
	end
	local list = {}
	for b, n in counts do
		table.insert(list, { b, math.floor(n / total * 100 + 0.5) })
	end
	table.sort(list, function(x, y)
		return x[2] > y[2]
	end)
	return list
end

local function createWorld(discoverer: Player?)
	local id = string.sub(HttpService:GenerateGUID(false), 1, 8)
	local okR, code, psid = pcall(function()
		return TeleportService:ReserveServer(game.PlaceId)
	end)
	if not okR then
		warn("[WildAcres] ReserveServer : " .. tostring(code))
		return nil
	end
	local seed = Random.new():NextInteger(1, 999999999)
	local entry
	try(function()
		registre:SetAsync("ps_" .. psid, id)
	end)
	try(function()
		registre:UpdateAsync("liste", function(old)
			old = decode(old) or { mondes = {} }
			local n = 0
			for _ in old.mondes do
				n += 1
			end
			local name = (not discoverer and n < #Config.WORLD_NAMES) and Config.WORLD_NAMES[n + 1] or worldName(seed)
			-- danger : les mondes découverts par des explorateurs sont souvent plus rudes (et plus riches)
			local dr = Random.new(seed + 7)
			local danger = discoverer and (1 + math.floor((dr:NextNumber() ^ 1.4) * 4.99)) or dr:NextInteger(1, 2)
			-- le thème de l'île (glaces, sables, brumes…) pèse aussi sur son danger
			local theme = G.WG.themeOf(seed)
			danger = math.clamp(danger + (theme.danger or 0), 1, 5)
			entry = { name = name, seed = seed, code = code, created = os.time(), gen = Mondes.GENERATOR,
				by = discoverer and discoverer.DisplayName or nil, danger = danger, biomes = survey(seed),
				theme = theme.name, themeIcon = theme.icon }
			old.mondes[id] = entry
			return HttpService:JSONEncode(old)
		end)
	end)
	listCache = nil
	return id, entry
end

-- Liste pour l'écran d'accueil (ouvre un monde de plus si tous sont presque pleins)
function Mondes.list()
	if listCache and os.clock() - listTime < 15 then
		return listCache
	end
	local reg = readRegistry()
	local counts = onlineCounts()
	local out = {}
	local room = false
	for id, m in reg.mondes do
		local n = counts[id] or 0
		table.insert(out, { id = id, name = m.name, n = n, cap = Config.WORLD_CAPACITY, created = m.created or 0,
			by = m.by, danger = m.danger or 1, biomes = m.biomes, here = id == Mondes.id, theme = m.theme, themeIcon = m.themeIcon })
		if n < Config.WORLD_CAPACITY * Config.WORLD_FULL_RATIO then
			room = true
		end
	end
	if not room then
		local id, entry = createWorld()
		if id and entry then
			table.insert(out, { id = id, name = entry.name, n = 0, cap = Config.WORLD_CAPACITY, created = entry.created })
		end
	end
	-- les plus peuplés (mais pas pleins) d'abord : on joue avec du monde
	table.sort(out, function(a, b)
		local fa, fb = a.n >= a.cap, b.n >= b.cap
		if fa ~= fb then
			return fb
		end
		if a.n ~= b.n then
			return a.n > b.n
		end
		return a.created < b.created
	end)
	listCache, listTime = out, os.clock()
	return out
end

-- « Jouer » : le joueur qui revient retrouve son dernier monde (s'il existe et n'est pas plein),
-- le nouveau joueur va dans le monde ouvert le plus peuplé qui a de la place
function Mondes.best(player: Player?): string?
	local l = Mondes.list()
	if player then
		local last = Mondes.lastWorldOf(player)
		for _, w in l do
			if w.id == last and w.n < w.cap then
				return w.id
			end
		end
		if last and readRegistry().mondes[last] then
			return last -- monde connu sans serveur actif : on le rouvre
		end
	end
	for _, w in l do
		if w.n < w.cap then
			return w.id
		end
	end
	return l[1] and l[1].id
end

-- Lecture SANS verrou du perso (accueil uniquement) pour connaître son dernier monde
function Mondes.lastWorldOf(player: Player): string?
	local ds = getStore("WA_Joueurs")
	if not ds then
		return nil
	end
	local ok, v = pcall(function()
		return ds:GetAsync("p_" .. player.UserId)
	end)
	local d = ok and decode(v)
	return type(d) == "table" and type(d.lastWorld) == "string" and d.lastWorld or nil
end

function Mondes.join(player: Player, id: string?)
	if type(id) ~= "string" then
		return { ok = false, msg = "Monde introuvable." }
	end
	local reg = readRegistry()
	local m = reg.mondes[id]
	if not m then
		return { ok = false, msg = "Monde introuvable." }
	end
	local opts = Instance.new("TeleportOptions")
	opts.ReservedServerAccessCode = m.code
	opts:SetTeleportData({ worldId = id })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, opts)
	end)
	if not ok then
		warn("[WildAcres] téléportation : " .. tostring(err))
		return { ok = false, msg = "Le voyage a échoué, réessaie." }
	end
	return { ok = true, msg = "En route pour " .. m.name .. "…" }
end

-- ================================================================ Monde

local function newWorld(id: string, seed: number, name: string)
	return {
		id = id,
		name = name,
		seed = seed,
		day = 1,
		minutes = Config.DAY_START,
		regions = {},
		npcs = {},
		law = { missing = {}, sightings = {} },
		players = {}, -- [userId] = { pos = {x,y,z}, bed = {x,y,z}, seen = os.time() }
		mailQueue = {},
		extra = {},
	}
end

local function worldIdFromJoin(): string?
	-- secours : l'accueil passe l'id du monde dans les données de téléportation
	for _ = 1, 60 do
		for _, p in Players:GetPlayers() do
			local ok, jd = pcall(function()
				return p:GetJoinData()
			end)
			local td = ok and jd and jd.TeleportData
			if type(td) == "table" and type(td.worldId) == "string" then
				return td.worldId
			end
		end
		task.wait(0.5)
	end
	return nil
end

-- Démarre le monde de ce serveur (appelé une fois par Main)
function Mondes.boot()
	if Mondes.mode == "accueil" then
		Mondes.ready = true
		return
	end
	local id, seed, name
	if Mondes.mode == "studio" then
		id = "studio"
		seed = workspace:GetAttribute("DevSeed") or 4242
		name = "Monde de test"
	elseif game.PrivateServerOwnerId ~= 0 then
		-- serveur privé acheté : monde perso de son propriétaire
		id = "vip_" .. game.PrivateServerId
		seed = G.WG.hash(game.PrivateServerId) % 999999999 + 1
		name = "Monde privé"
	else
		local ok, v = try(function()
			return registre:GetAsync("ps_" .. game.PrivateServerId)
		end)
		id = ok and v or nil
		if not id then
			id = worldIdFromJoin()
		end
		if id then
			local reg = readRegistry()
			local m = reg.mondes[id]
			if m then
				seed, name = m.seed, m.name
				Mondes.danger = m.danger or 1
				Mondes.genOf = tonumber(m.gen) or 1
				Mondes.discoverer = m.by
			end
		end
		id = id or ("ps_" .. game.PrivateServerId)
	end
	Mondes.id = id

	local data = nil
	if store then
		local ok, v = Mondes.acquire(id)
		if ok then
			data = v
		else
			-- NE PAS démarrer un monde neuf : il écraserait le vrai à la première sauvegarde
			warn("[WildAcres] lecture du monde " .. id .. " impossible : " .. tostring(v))
			Mondes.broken = "Ce monde n'a pas pu être chargé (service de sauvegarde indisponible). Rien n'est perdu : réessaie dans quelques minutes."
			worldLockLost = true
			Mondes.ready = true
			for _, p in Players:GetPlayers() do
				p:Kick(Mondes.broken)
			end
			return
		end
	end
	if data and data.seed then
		local w = newWorld(id, data.seed, data.name or name or "Monde")
		w.gen = tonumber(data.gen) or 1 -- monde existant : il garde SA version du générateur
		w.day = data.day or 1
		w.minutes = data.minutes or Config.DAY_START
		w.npcs = data.npcs or {}
		w.law = data.law or w.law
		w.players = data.players or {}
		w.orders = data.orders or {}
		w.market = data.market or {}
		w.mailQueue = data.mailQueue or {}
		w.extra = data.extra or {} -- données de monde des nouveaux systèmes (politique, avant-postes…)
		G.world = w
	else
		seed = seed or Random.new():NextInteger(1, 999999999)
		G.world = newWorld(id, seed, name or "Monde")
	end
	G.world.danger = Mondes.danger or 1
	workspace:SetAttribute("Danger", G.world.danger)
	G.world.gen = G.world.gen or Mondes.genOf or Mondes.GENERATOR
	G.wg = G.WG.new(G.world.seed, G.world.gen)
	workspace:SetAttribute("Gen", G.world.gen) -- le client génère la même carte
	workspace:SetAttribute("Seed", G.world.seed)
	workspace:SetAttribute("WorldName", G.world.name)
	G.Clock.start()
	if G.Parcelles and G.Parcelles.publish then
		G.Parcelles.publish()
	end
	Mondes.ready = true

	-- présence en ligne + sauvegarde régulière
	task.spawn(function()
		while true do
			Mondes.heartbeat()
			task.wait(15)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(150)
			Mondes.saveWorld()
		end
	end)
end

-- Lit l'état global du monde en posant le verrou de ce serveur. Attend (au plus ~45 s) qu'un
-- ancien serveur du même monde finisse sa dernière sauvegarde. Renvoie (ok, données|nil).
function Mondes.acquire(id: string)
	local errors, t0 = 0, os.clock()
	while true do
		local data, locked = nil, false
		local ok, err = pcall(function()
			store:UpdateAsync("m_" .. id, function(raw)
				local old = decode(raw)
				if raw ~= nil and old == nil then
					error("état du monde illisible (JSON)")
				end
				if old and type(old.lock) == "table" and old.lock.job ~= game.JobId
					and os.time() - (tonumber(old.lock.t) or 0) < WORLD_LOCK and os.clock() - t0 < 45 then
					locked = true
					return nil
				end
				if not old then
					return nil -- monde jamais sauvegardé : rien à verrouiller pour l'instant
				end
				old.lock = { job = game.JobId, t = os.time() }
				data = old
				return HttpService:JSONEncode(old)
			end)
		end)
		if ok and not locked then
			return true, data
		end
		if not ok then
			errors += 1
			if errors >= 6 then
				return false, err
			end
			task.wait(math.min(2 ^ errors, 20))
		else
			task.wait(3)
		end
	end
end

-- Sauvegarde rapprochée après une opération qui touche le monde ET un perso (achat à l'hôtel des
-- ventes, étal, coffre) : réduit la fenêtre où un arrêt brutal ferait diverger les deux sauvegardes
-- (au plus une écriture du monde et une par joueur toutes les 10 s : budget DataStore)
local soonWorld = false
local soonPlayer = {}
function Mondes.saveSoon(player: Player?)
	if player and not soonPlayer[player] then
		soonPlayer[player] = true
		task.delay(3, function()
			soonPlayer[player] = nil
			if player.Parent then
				G.Save.save(player)
			end
		end)
	end
	if soonWorld then
		return
	end
	soonWorld = true
	task.delay(3, function()
		Mondes.saveWorld()
		task.wait(7)
		soonWorld = false
	end)
end

function Mondes.heartbeat()
	if not online or Mondes.mode ~= "monde" or not Mondes.id then
		return
	end
	pcall(function()
		online:SetAsync(Mondes.id, { n = #Players:GetPlayers(), name = G.world and G.world.name or "" }, 45)
	end)
end

-- ---------------------------------------------------------------- Secteurs (état des régions)

local function sectorOf(rx: number, rz: number): string
	return (rx // SECTOR) .. "," .. (rz // SECTOR)
end

-- À appeler avant d'utiliser l'état d'une région : charge son secteur si besoin (peut attendre)
function Mondes.ensureRegion(rx: number, rz: number)
	if not store or not Mondes.id then
		return
	end
	local sk = sectorOf(rx, rz)
	local st = sectorState[sk]
	if st == "ready" then
		return
	end
	if st == "loading" then
		while sectorState[sk] == "loading" do
			task.wait()
		end
		return
	end
	sectorState[sk] = "loading"
	local ok, v = try(function()
		return store:GetAsync("m_" .. Mondes.id .. "_s_" .. sk)
	end)
	if ok and v then
		sectorJson[sk] = type(v) == "string" and v or nil
		local t = decode(v)
		if type(t) == "table" and type(t.__split) == "table" then
			-- secteur trop gros, découpé région par région (voir saveWorldInner)
			for _, key in t.__split do
				local okR, vr = try(function()
					return store:GetAsync("m_" .. Mondes.id .. "_r_" .. key)
				end)
				if not okR then
					warn("[WildAcres] région " .. key .. " illisible : " .. tostring(vr))
					sectorState[sk] = "failed"
					return
				end
				local rs = decode(vr)
				if type(rs) == "table" and G.world.regions[key] == nil then
					G.world.regions[key] = rs
					regionJson[key] = type(vr) == "string" and vr or nil
				end
			end
		elseif type(t) == "table" then
			for key, rs in t do
				if G.world.regions[key] == nil then
					G.world.regions[key] = rs
				end
			end
		end
	elseif not ok then
		-- secteur illisible : on joue avec un état neuf mais on ne l'ÉCRIRA JAMAIS (sinon on
		-- écraserait les constructions et récoltes enregistrées)
		warn("[WildAcres] secteur " .. sk .. " illisible : " .. tostring(v))
		sectorState[sk] = "failed"
		return
	end
	sectorState[sk] = "ready"
end

-- ---------------------------------------------------------------- Sauvegarde du monde

local function posOf(player: Player)
	local root = G.Util.root(player)
	if root then
		local p = root.Position
		return { math.floor(p.X), math.floor(p.Y), math.floor(p.Z) }
	end
	return nil
end

-- Note la position d'un joueur dans ce monde (il y reviendra au même endroit)
function Mondes.rememberPlayer(player: Player)
	if not G.world then
		return
	end
	local rec = G.world.players[tostring(player.UserId)] or {}
	rec.pos = posOf(player) or rec.pos
	rec.seen = os.time()
	G.world.players[tostring(player.UserId)] = rec
end

function Mondes.playerRecord(player: Player)
	if not G.world then
		return nil
	end
	local k = tostring(player.UserId)
	G.world.players[k] = G.world.players[k] or {}
	return G.world.players[k]
end

local saving = false
local saveWorldInner
function Mondes.saveWorld(release: boolean?)
	if not G.world or not store or not Mondes.id or saving or worldLockLost then
		return
	end
	saving = true
	-- quoi qu'il arrive (erreur d'un système), on relâche le drapeau : sinon plus jamais de sauvegarde
	local ok, err = pcall(saveWorldInner, release)
	saving = false
	if not ok then
		warn("[WildAcres] sauvegarde du monde : " .. tostring(err))
	end
end

function saveWorldInner(release: boolean?)
	for _, p in Players:GetPlayers() do
		Mondes.rememberPlayer(p)
	end
	-- oublie les joueurs absents depuis 60 jours (sauf parcelle)
	local now = os.time()
	for uid, rec in G.world.players do
		if (rec.seen or 0) < now - 60 * 86400 and not rec.plot and not (rec.plots and #rec.plots > 0) then
			G.world.players[uid] = nil
		end
	end
	G.Npcs.saveAll()
	if G.Compagnons and G.Compagnons.sync then
		G.Compagnons.sync()
	end
	local w = G.world
	local meta = { version = 1, gen = w.gen or Mondes.GENERATOR, danger = w.danger, seed = w.seed, name = w.name, day = w.day, minutes = w.minutes, npcs = w.npcs, law = w.law, players = w.players, orders = w.orders, market = w.market, mailQueue = w.mailQueue, extra = w.extra }
	local okE, json = pcall(HttpService.JSONEncode, HttpService, meta)
	if not okE then
		warn("[WildAcres] état du monde non encodable : " .. tostring(json))
		return
	end
	if #json > 3500000 then
		warn("[WildAcres] sauvegarde du monde trop grosse : " .. #json)
		if #json > 4000000 then
			return
		end
	end
	-- écrit TOUJOURS l'état global (même identique) : c'est lui qui porte et rafraîchit le verrou
	meta.lock = (not release) and { job = game.JobId, t = os.time() } or nil
	local full = HttpService:JSONEncode(meta)
	local stolen = false
	local ok, err = try(function()
		store:UpdateAsync("m_" .. Mondes.id, function(raw)
			local old = decode(raw)
			if old and type(old.lock) == "table" and old.lock.job ~= game.JobId
				and os.time() - (tonumber(old.lock.t) or 0) < WORLD_LOCK then
				stolen = true
				return nil
			end
			return full
		end)
	end)
	if not ok then
		warn("[WildAcres] sauvegarde du monde : " .. tostring(err))
		return
	end
	if stolen then
		worldLockLost = true
		warn("[WildAcres] le monde " .. Mondes.id .. " est tenu par un autre serveur : plus aucune écriture ici")
		return
	end
	metaJson = json
	-- secteurs : regroupe l'état des régions
	local sectors = {}
	for key, rs in w.regions do
		local rx, rz = string.match(key, "^(-?%d+),(-?%d+)$")
		if rx then
			local sk = sectorOf(tonumber(rx) :: number, tonumber(rz) :: number)
			sectors[sk] = sectors[sk] or {}
			sectors[sk][key] = rs
		end
	end
	for sk, t in sectors do
		local okS, js = pcall(HttpService.JSONEncode, HttpService, t)
		-- secteur trop gros (régions très construites : la règle « pas de plafond ») : on le découpe
		-- en une clé par région, puis on écrit un index { __split = clés }. Les régions d'abord,
		-- l'index ensuite : un index ne pointe jamais vers une région absente.
		if okS and #js > SPLIT_BYTES and sectorState[sk] == "ready" then
			local keys, allOk = {}, true
			for key, rs in t do
				local okR, jr = pcall(HttpService.JSONEncode, HttpService, rs)
				if not okR or #jr > 3900000 then
					warn("[WildAcres] région " .. key .. " trop volumineuse pour être sauvegardée : " .. (okR and #jr or "?"))
					allOk = false
				elseif jr ~= regionJson[key] then
					local okW, err = try(function()
						store:SetAsync("m_" .. Mondes.id .. "_r_" .. key, jr)
					end)
					if okW then
						regionJson[key] = jr
					else
						allOk = false
						warn("[WildAcres] région " .. key .. " : " .. tostring(err))
					end
				end
				table.insert(keys, key)
			end
			if allOk then
				local idx = HttpService:JSONEncode({ __split = keys })
				if idx ~= sectorJson[sk] then
					local okI = try(function()
						store:SetAsync("m_" .. Mondes.id .. "_s_" .. sk, idx)
					end)
					if okI then
						sectorJson[sk] = idx
					end
				end
			end
			js = nil
		end
		-- seulement les secteurs relus depuis le DataStore (sinon on écraserait l'ancien état)
		if okS and js and js ~= sectorJson[sk] and sectorState[sk] == "ready" then
			local ok, err = try(function()
				store:SetAsync("m_" .. Mondes.id .. "_s_" .. sk, js)
			end)
			if ok then
				sectorJson[sk] = js
			else
				warn("[WildAcres] secteur " .. sk .. " : " .. tostring(err))
			end
		end
	end
end

-- ================================================================ Voyage (port)

local embark = {} -- joueur -> { dest, t }
local departing = {}

-- Voyage raté (erreur immédiate OU échec signalé plus tard par Roblox) : remboursé une seule fois,
-- l'écran se rouvre, le joueur reste jouable ici (son verrou n'a jamais été levé)
function Mondes.travelFailed(p: Player, why: string)
	local t = travelling[p]
	travelling[p] = nil
	if not t or not p.Parent then
		return
	end
	G.Joueurs.add(p, "gold", t.cost, true)
	G.Joueurs.sync(p)
	G.remotes.Fade:FireClient(p, nil, 1)
	G.Util.toast(p, "⛵ " .. why .. " : traversée remboursée. Réessaie au port.", "danger")
	task.spawn(G.Save.save, p)
end

function Mondes.openSeaMap(player: Player)
	if Mondes.mode == "studio" then
		G.Util.toast(player, "Le voyage entre mondes ne marche que dans le jeu publié (pas dans Studio).")
		return
	end
	listCache = nil
	G.remotes.Menu:FireClient(player, { kind = "seamap", worlds = Mondes.list(), here = Mondes.id, costKnown = 20, costUnknown = 150 })
end

-- Départ : on attend 6 s que les joueurs proches qui ont choisi la même destination embarquent
function Mondes.travel(player: Player, dest: string)
	if Mondes.mode == "studio" or type(dest) ~= "string" or dest == Mondes.id then
		return
	end
	local unknown = dest == "inconnu"
	local cost = unknown and 150 or 20
	if not G.Joueurs.has(player, "gold", cost) then
		G.Util.toast(player, "La traversée coûte " .. cost .. " 💰.")
		return
	end
	embark[player] = { dest = dest, t = os.clock() }
	local key = dest .. "@" .. player.UserId
	-- un départ vers cette destination est déjà en préparation tout près ? on s'y joint
	for k, dep in departing do
		local r1, r2 = G.Util.root(dep.leader), G.Util.root(player)
		if dep.dest == dest and r1 and r2 and (r1.Position - r2.Position).Magnitude < 20 then
			G.Util.toast(player, "Tu embarques avec " .. dep.leader.DisplayName .. ".")
			return
		end
		local _ = k
	end
	departing[key] = { leader = player, dest = dest }
	for _, p in G.Game.players() do
		local r1, r2 = G.Util.root(p), G.Util.root(player)
		if r1 and r2 and (r1.Position - r2.Position).Magnitude < 30 then
			G.Util.toast(p, "⛵ " .. player.DisplayName .. " prend la mer dans 6 s" .. (unknown and " vers l'inconnu" or "") .. ". Choisis la même destination au port pour embarquer.")
		end
	end
	task.delay(6, function()
		departing[key] = nil
		if not player.Parent then
			return
		end
		-- l'équipage : ceux qui ont choisi la même destination, tout près
		local crew = { player }
		local root = G.Util.root(player)
		for p, e in embark do
			if p ~= player and p.Parent and e.dest == dest and os.clock() - e.t < 15 then
				local r = G.Util.root(p)
				if r and root and (r.Position - root.Position).Magnitude < 20 then
					table.insert(crew, p)
				end
			end
		end
		local id, entry = dest, nil
		if unknown then
			id, entry = createWorld(player)
			local lp = G.Joueurs.get(player)
			if lp and id then
				lp.stats.discovered = (lp.stats.discovered or 0) + 1
			end
			if not id then
				G.Util.toast(player, "La mer est mauvaise, réessaie plus tard.")
				return
			end
		else
			entry = readRegistry().mondes[dest]
		end
		if not entry then
			G.Util.toast(player, "Ce monde est introuvable.")
			return
		end
		local paying = {}
		for _, p in crew do
			if not travelling[p] and G.Joueurs.take(p, "gold", cost) then
				table.insert(paying, p)
				embark[p] = nil
				travelling[p] = { cost = cost, t = os.clock() }
				G.remotes.Fade:FireClient(p, "⛵ Traversée vers " .. entry.name .. "…", 0)
				-- on GARDE le verrou : il est levé par PlayerRemoving quand le joueur quitte vraiment ce
				-- serveur (le nouveau monde attend quelques secondes). Si le voyage échoue, rien à reprendre.
				G.Save.save(p)
			end
		end
		if unknown then
			for _, p in paying do
				G.Util.toast(p, "🧭 Une terre inconnue se dessine à l'horizon : " .. entry.name .. ".", "big")
			end
		end
		local opts = Instance.new("TeleportOptions")
		opts.ReservedServerAccessCode = entry.code
		opts:SetTeleportData({ worldId = id })
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, paying, opts)
		end)
		if not ok then
			warn("[WildAcres] voyage : " .. tostring(err))
			for _, p in paying do
				Mondes.travelFailed(p, "Le bateau n'a pas pu partir")
			end
		end
	end)
end

function Mondes.shutdown()
	if Mondes.mode == "accueil" then
		return
	end
	if online and Mondes.id then
		pcall(function()
			online:RemoveAsync(Mondes.id)
		end)
	end
	Mondes.saveWorld(true) -- dernière écriture : on lève le verrou pour le prochain serveur
end

return Mondes
