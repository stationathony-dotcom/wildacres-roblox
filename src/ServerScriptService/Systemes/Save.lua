-- Sauvegarde du PERSONNAGE (commune à tous les mondes, façon MMO) : sac, équipement, honneur,
-- cheval, statistiques, banques. L'état d'un monde est sauvegardé à part par Mondes.
--
-- Règles de sûreté (voir AUDIT.md, étape 1) :
--  · Verrou de session { job, t } rafraîchi à chaque sauvegarde. Un verrou est « vivant » tant
--    qu'il a moins de LOCK_TIMEOUT secondes ; la sauvegarde périodique (AUTOSAVE) passe bien avant.
--  · Un perso qu'on n'a PAS réussi à lire n'est JAMAIS écrit : load renvoie "error" et le joueur
--    est renvoyé avec un message, ses données restent intactes dans le DataStore.
--  · Une sauvegarde est sérialisée par joueur (pas deux écritures en même temps), réessayée avec
--    un délai croissant, et toujours faite à partir du DERNIER instantané.
--  · Chaque écriture porte un numéro de séquence (seq) : une réponse en retard d'un ancien serveur
--    ne peut pas écraser une version plus récente.
--  · Les formats sont versionnés ; MIGRATIONS[v] fait passer une sauvegarde de v à v+1.
--  · Restauration : les DataStores gardent 30 jours de versions → Save.listVersions / restoreVersion.
-- Dans Studio sans accès aux API, tout reste en mémoire.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Save = {}
local G
local store = nil
local memory = {} -- repli Studio : userId -> données
local sessions = {} -- userId -> { status, seq, saving, latest, release }
local pendingWrites = 0

local VERSION = 3
Save.VERSION = VERSION
Save.LOCK_TIMEOUT = 300 -- s : au-delà, un verrou est considéré comme abandonné (serveur mort)
Save.AUTOSAVE = 90 -- s : bien sous LOCK_TIMEOUT pour que le verrou reste vivant
local MAX_BYTES = 4000000 -- limite Roblox d'une entrée
local WARN_BYTES = 3000000

-- Champs du profil écrits sur le disque (une seule liste : snapshot ET chargement s'en servent)
Save.FIELDS = {
	"inv", "gear", "equipped", "honor", "horse", "stats", "statXp", "attrs", "skills",
	"talents", "stars", "bounty", "col", "titles", "title", "hotbar", "known", "clan", "banks", "look",
	"journal", "settings", "mailClaimed", "lastWorld", "created", "buffs", "blocked", "treasures",
	"wear", -- 18/11 : usure des outils (facultatif : absent = outils neufs)
	"warnings", -- 18/11 : avertissements de modération (sanctions graduées)
	"plans", -- 18/11 : plans de construction copiés (Batir), facultatif
	"stable", "breedDay", -- 19/11 : montures à l'écurie (Horses.swap / breed), facultatif
	"selection", -- 19/11 : sélection des semences par culture (Farm), facultatif
	"unlocks", -- 19/11 : coiffures et teintes débloquées chez le barbier / tailleur (Avatar)
	"montures", -- 26/11 : collection de montures façon WoW (Systemes/Montures), facultatif
	"sorts", -- 27/11 : sorts appris dans les grimoires (Systemes/Magie), facultatif
	"conjoint", -- 27/11 : époux (Systemes/Mariages), facultatif
	"maitrise", -- 26/11 : maîtrise par famille d'armes (Combat, Shared/Armes), facultatif
}

-- v -> fonction qui transforme une sauvegarde v en v+1 (ne jamais modifier une migration publiée)
local MIGRATIONS = {
	[1] = function(d)
		d.stats = d.stats or { harvested = 0, crimes = 0 }
	end,
	[2] = function(d)
		-- v3 : banques dans le perso (avant : dans chaque monde) ; rien à convertir ici, le monde
		-- rend sa banque au premier passage (Economie.adoptBank)
		d.banks = d.banks or {}
	end,
}

function Save.init(g)
	G = g
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore("WA_Joueurs" .. (RunService:IsStudio() and "_studio" or ""))
	end)
	if ok then
		store = ds
	end
	-- Studio : tout en mémoire, sauf si on coche l'attribut StudioDataStore sur Workspace
	if RunService:IsStudio() and not workspace:GetAttribute("StudioDataStore") then
		store = nil
	end
end

local function key(userId: number): string
	return "p_" .. userId
end

local function decode(v)
	if type(v) == "string" then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, v)
		return ok and t or nil
	end
	return v
end

local function lockAlive(old): boolean
	return old ~= nil and type(old.lock) == "table" and old.lock.job ~= game.JobId
		and os.time() - (tonumber(old.lock.t) or 0) < Save.LOCK_TIMEOUT
end

function Save.migrate(d)
	d.version = tonumber(d.version) or 1
	while d.version < VERSION do
		local m = MIGRATIONS[d.version]
		if m then
			m(d)
		end
		d.version += 1
	end
	return d
end

local function log(kind: string, msg: string)
	if G and G.Economie and G.Economie.record then
		G.Economie.record(nil, kind, msg)
	end
	warn("[WildAcres] " .. msg)
end

-- Charge le perso et pose le verrou de ce serveur.
-- Renvoie (données, statut) : statut = "ok" | "new" | "error" | "left" (le joueur est parti).
-- onWait(message) est appelé quand on attend la fin d'une session sur un autre monde.
function Save.load(player: Player, onWait: ((string) -> ())?)
	local uid = player.UserId
	if not store then
		local d = memory[uid]
		sessions[uid] = { status = "ok", seq = d and d.seq or 0 }
		return d, d and "ok" or "new"
	end
	local deadline = os.clock() + Save.LOCK_TIMEOUT + 30
	local errors = 0
	while true do
		local result, locked, isNew = nil, false, false
		local ok, err = pcall(function()
			store:UpdateAsync(key(uid), function(raw)
				local old = decode(raw)
				if raw ~= nil and old == nil then
					error("sauvegarde illisible (JSON)") -- surtout ne pas écraser : on remonte l'erreur
				end
				if lockAlive(old) then
					locked = true
					return nil -- n'écrit rien
				end
				isNew = old == nil or old.inv == nil
				old = old or { version = VERSION, seq = 0 }
				old.lock = { job = game.JobId, t = os.time() }
				result = old
				return HttpService:JSONEncode(old)
			end)
		end)
		if not player.Parent then
			return nil, "left"
		end
		if ok and not locked then
			local data = result and Save.migrate(result) or nil
			sessions[uid] = { status = "ok", seq = data and tonumber(data.seq) or 0 }
			if isNew then
				return nil, "new"
			end
			return data, "ok"
		end
		if not ok then
			errors += 1
			warn("[WildAcres] lecture du perso " .. uid .. " (" .. errors .. ") : " .. tostring(err))
			if errors >= 6 then
				log("save_erreur", "perso " .. uid .. " illisible après 6 essais : " .. tostring(err))
				sessions[uid] = { status = "error" }
				return nil, "error"
			end
			task.wait(math.min(2 ^ errors, 20))
		else
			if os.clock() > deadline then
				-- verrou toujours tenu après LOCK_TIMEOUT : l'autre serveur le rafraîchit encore,
				-- le perso y est donc réellement en jeu → on refuse plutôt que de dupliquer
				sessions[uid] = { status = "error" }
				log("save_verrou", "perso " .. uid .. " toujours verrouillé par un autre serveur")
				return nil, "error"
			end
			if onWait then
				onWait("Ton personnage termine son voyage depuis un autre monde…")
			end
			task.wait(3)
		end
	end
end

-- Statut de la session de ce joueur ("ok" = chargé, on peut l'écrire)
function Save.status(player: Player): string?
	local s = sessions[player.UserId]
	return s and s.status
end

local function copySnapshotValue(value, copies)
	if type(value) ~= "table" then
		return value
	end
	if copies[value] then
		return copies[value]
	end
	local copy = {}
	copies[value] = copy
	for key, entry in pairs(value) do
		copy[key] = copySnapshotValue(entry, copies)
	end
	return copy
end

function Save.snapshot(player: Player)
	local prof = G.Joueurs.get(player)
	if not prof then
		return nil
	end
	local snap = { version = VERSION, saved = os.time() }
	local copies = {}
	for _, f in Save.FIELDS do
		snap[f] = copySnapshotValue(prof[f], copies)
	end
	return snap
end

-- Applique une sauvegarde chargée sur un profil neuf
function Save.apply(prof, data)
	for _, f in Save.FIELDS do
		if data[f] ~= nil then
			prof[f] = data[f]
		end
	end
	if type(prof.hotbar) ~= "table" then
		prof.hotbar = nil
	end
	if type(prof.known) ~= "table" then
		prof.known = {}
	end
	return prof
end

local function write(uid: number, snap, release: boolean): boolean
	local s = sessions[uid]
	snap.seq = (s.seq or 0) + 1
	snap.lock = (not release) and { job = game.JobId, t = os.time() } or nil
	local okEnc, json = pcall(HttpService.JSONEncode, HttpService, snap)
	if not okEnc then
		log("save_erreur", "perso " .. uid .. " non encodable : " .. tostring(json))
		return false
	end
	if #json > MAX_BYTES then
		log("save_erreur", "perso " .. uid .. " trop gros (" .. #json .. " o) : NON écrit")
		return false
	elseif #json > WARN_BYTES then
		log("save_taille", "perso " .. uid .. " volumineux : " .. #json .. " o")
	end
	if not store then
		memory[uid] = HttpService:JSONDecode(json)
		s.seq = snap.seq
		return true
	end
	local stolen = false
	for attempt = 1, 4 do
		local ok, err = pcall(function()
			store:UpdateAsync(key(uid), function(raw)
				local old = decode(raw)
				-- un autre serveur a repris le perso (verrou vivant) ou a écrit plus récent : on n'écrase pas
				if lockAlive(old) or (old and (tonumber(old.seq) or 0) > snap.seq) then
					-- (égal = notre propre essai précédent a abouti malgré l'erreur réseau : on réécrit)
					stolen = true
					return nil
				end
				return json
			end)
		end)
		if ok then
			if stolen then
				log("save_conflit", "perso " .. uid .. " tenu par un autre serveur : écriture abandonnée")
				s.status = "lost"
				return false
			end
			s.seq = snap.seq
			return true
		end
		warn("[WildAcres] sauvegarde " .. uid .. " (" .. attempt .. ") : " .. tostring(err))
		task.wait(attempt * 2)
	end
	log("save_erreur", "perso " .. uid .. " : sauvegarde impossible après 4 essais")
	return false
end

-- Écrit le perso ; release = le joueur quitte ce serveur (on lève le verrou).
-- L'instantané est pris TOUT DE SUITE (sans attendre) : on peut vider le profil juste après.
function Save.save(player: Player, release: boolean?): boolean
	local uid = player.UserId
	local s = sessions[uid]
	if not s or s.status ~= "ok" then
		return false -- jamais chargé correctement : on ne touche pas aux données
	end
	local snap = Save.snapshot(player)
	if not snap then
		return false
	end
	if G.Mondes then
		G.Mondes.rememberPlayer(player)
	end
	s.latest = snap
	s.release = s.release or release == true
	if s.saving then
		-- une écriture est en cours : elle reprendra le dernier instantané en sortant
		while s.saving do
			task.wait(0.1)
		end
		return s.lastOk == true
	end
	s.saving = true
	pendingWrites += 1
	local ok = true
	while s.latest do
		local snapNow, rel = s.latest, s.release
		s.latest = nil
		ok = write(uid, snapNow, rel)
		if rel and ok and not s.latest then
			s.status = "released"
		end
	end
	s.lastOk = ok
	s.saving = false
	pendingWrites -= 1
	if s.status == "released" or s.status == "lost" then
		sessions[uid] = nil
	end
	return ok
end

-- Écritures en cours (BindToClose attend qu'elles soient finies)
function Save.pending(): number
	return pendingWrites
end

-- Lecture SANS verrou d'une sauvegarde (consultation : blocages, dernier monde…). Jamais pour écrire.
function Save.peek(userId: number)
	if not store then
		return memory[userId]
	end
	local ok, v = pcall(function()
		return store:GetAsync(key(userId))
	end)
	return ok and decode(v) or nil
end

-- Recommencer un perso de zéro (garde l'historique des versions côté DataStore)
function Save.wipe(player: Player)
	local uid = player.UserId
	memory[uid] = nil
	sessions[uid] = nil
	if store then
		pcall(function()
			store:UpdateAsync(key(uid), function()
				return HttpService:JSONEncode({ version = VERSION, seq = 0, wiped = os.time() })
			end)
		end)
	end
	log("save_raz", "perso " .. uid .. " remis à zéro par le joueur")
end

-- ----------------------------------------------------------------- Restauration (outils admin)

-- Dernières versions d'un perso (plus récentes d'abord) : { {version, date}, ... }
function Save.listVersions(userId: number, n: number?)
	if not store then
		return {}
	end
	local out = {}
	local ok, pages = pcall(function()
		return store:ListVersionsAsync(key(userId), Enum.SortDirection.Descending, nil, nil, n or 20)
	end)
	if ok and pages then
		for _, v in pages:GetCurrentPage() do
			table.insert(out, { version = v.Version, date = math.floor(v.CreatedTime / 1000), deleted = v.IsDeleted })
		end
	end
	return out
end

-- Remet une ancienne version (le joueur doit être hors ligne : on refuse si un verrou est vivant)
function Save.restoreVersion(userId: number, versionId: string): (boolean, string)
	if not store then
		return false, "pas de DataStore"
	end
	local okGet, raw = pcall(function()
		return store:GetVersionAsync(key(userId), versionId)
	end)
	local data = okGet and decode(raw)
	if not data then
		return false, "version introuvable"
	end
	local refused = false
	local ok, err = pcall(function()
		store:UpdateAsync(key(userId), function(cur)
			local old = decode(cur)
			if lockAlive(old) then
				refused = true
				return nil
			end
			data.lock = nil
			data.seq = (old and tonumber(old.seq) or 0) + 1
			data.restored = { from = versionId, t = os.time() }
			return HttpService:JSONEncode(data)
		end)
	end)
	if not ok then
		return false, tostring(err)
	end
	if refused then
		return false, "joueur en ligne (verrou vivant)"
	end
	log("save_restauration", "perso " .. userId .. " restauré depuis " .. versionId)
	return true, "ok"
end

return Save
