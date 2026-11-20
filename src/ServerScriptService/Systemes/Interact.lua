-- Répartit les actions du joueur : invites (ProximityPrompt, touche E / appui) et
-- messages du client (frapper, dialogue, menus…) vers les systèmes qui les gèrent.
--
-- Garde-fous communs (étape 1B) — aucun système n'a à les refaire :
--  · données nettoyées : seules les tables plates/peu profondes passent, nombres NaN/infinis retirés
--    (y compris écrits en texte : "nan", "inf", "1e999"), chaînes tronquées ;
--  · anti-répétition par sorte d'action (0,12 s) + budget global par joueur (seau à jetons) ;
--  · anti-réentrée : tant qu'une action d'une sorte n'est pas finie (elle peut attendre un
--    DataStore), une nouvelle demande de la même sorte est ignorée → pas de double achat / retrait ;
--  · interrupteurs d'urgence : une action ou une invite listée dans le DataStore WA_Interrupteurs
--    (clé "off") est coupée sur tous les serveurs en moins d'une minute, sans republier le jeu.

local ProximityPromptService = game:GetService("ProximityPromptService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Interact = {}
local G
local promptHandlers = {}
local actionHandlers = {}
local last = {} -- joueur -> { [sorte] = os.clock() }
local busy = {} -- joueur -> { [sorte] = true } pendant l'exécution
local bucket = {} -- joueur -> { jetons, t }
local strikes = {} -- joueur -> nombre de demandes refusées (journal des abus)

local BUCKET_MAX = 40 -- rafale tolérée
local BUCKET_RATE = 20 -- jetons par seconde
local MAX_STR = 200
local MAX_KEYS = 64

Interact.disabled = {} -- sorte d'action / d'invite -> raison (interrupteurs d'urgence)

-- Copie nettoyée des données envoyées par le client
local function clean(v, depth: number)
	local t = type(v)
	if t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then
			return nil
		end
		return v
	elseif t == "string" then
		-- "nan", "inf", "1e999"… : les systèmes font tonumber(data.x), qui en tirerait un nombre non fini
		-- (prix NaN qui passe les comparaisons, quantité infinie). Une telle chaîne n'est jamais un nom utile.
		local asNum = tonumber(v)
		if asNum and (asNum ~= asNum or asNum == math.huge or asNum == -math.huge) then
			return nil
		end
		return #v > MAX_STR and string.sub(v, 1, MAX_STR) or v
	elseif t == "boolean" then
		return v
	elseif t == "table" then
		if depth >= 3 then
			return nil
		end
		local out, n = {}, 0
		for k, x in v do
			n += 1
			if n > MAX_KEYS then
				break
			end
			local kt = type(k)
			if (kt == "string" and #k <= 64) or (kt == "number" and k == k and k % 1 == 0) then
				out[k] = clean(x, depth + 1)
			end
		end
		return out
	elseif typeof(v) == "Vector3" then
		if v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z or v.Magnitude > 1e6 then
			return nil
		end
		return v
	end
	return nil -- Instances, fonctions, etc. : jamais
end

local function allow(player: Player): boolean
	local now = os.clock()
	local b = bucket[player]
	if not b then
		b = { BUCKET_MAX, now }
		bucket[player] = b
	end
	b[1] = math.min(BUCKET_MAX, b[1] + (now - b[2]) * BUCKET_RATE)
	b[2] = now
	if b[1] < 1 then
		strikes[player] = (strikes[player] or 0) + 1
		if strikes[player] % 200 == 1 and G.Economie and G.Economie.record then
			G.Economie.record(player, "abus", "rafale de requêtes (" .. strikes[player] .. " refusées)")
		end
		return false
	end
	b[1] -= 1
	return true
end

-- Interrupteurs d'urgence partagés entre serveurs
local function watchSwitches()
	if RunService:IsStudio() and not workspace:GetAttribute("StudioDataStore") then
		return
	end
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore("WA_Interrupteurs")
	end)
	if not ok then
		return
	end
	task.spawn(function()
		while true do
			local okGet, v = pcall(function()
				return ds:GetAsync("off")
			end)
			if okGet then
				Interact.disabled = type(v) == "table" and v or {}
			end
			task.wait(55)
		end
	end)
end

-- Coupe / rallume une action sur TOUS les serveurs (outil admin) ; raison = nil pour rallumer
function Interact.setSwitch(kind: string, reason: string?): boolean
	Interact.disabled[kind] = reason
	local ok = pcall(function()
		DataStoreService:GetDataStore("WA_Interrupteurs"):UpdateAsync("off", function(old)
			old = type(old) == "table" and old or {}
			old[kind] = reason
			return old
		end)
	end)
	return ok
end

local function run(player: Player, kind: string, h, ...)
	local b = busy[player]
	if not b then
		b = {}
		busy[player] = b
	end
	if b[kind] then
		return -- la même action est encore en cours (attente d'un DataStore…) : pas de doublon
	end
	b[kind] = true
	local ok, err = pcall(h, player, ...)
	b[kind] = nil
	if not ok then
		warn("[WildAcres] " .. kind .. " : " .. tostring(err))
	end
end

function Interact.init(g)
	G = g
	watchSwitches()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local action = prompt:GetAttribute("Action")
		local h = action and promptHandlers[action]
		if not h or Interact.disabled[action] then
			if h then
				G.Util.toast(player, "Indisponible pour le moment (maintenance).")
			end
			return
		end
		if not G.Game.isPlaying(player) or not G.Util.root(player) or not allow(player) then
			return
		end
		run(player, "invite:" .. action, h, prompt)
	end)
	G.remotes.Action.OnServerEvent:Connect(function(player, kind, data)
		if type(kind) ~= "string" or #kind > 40 then
			return
		end
		local h = actionHandlers[kind]
		if not h then
			return
		end
		if not allow(player) then
			return
		end
		local now = os.clock()
		local l = last[player]
		if not l then
			l = {}
			last[player] = l
		end
		if l[kind] and now - l[kind] < 0.12 then
			return
		end
		l[kind] = now
		if kind ~= "start" and not G.Game.isPlaying(player) then
			return
		end
		if Interact.disabled[kind] then
			G.Util.toast(player, "Indisponible pour le moment (maintenance).")
			return
		end
		run(player, kind, h, type(data) == "table" and clean(data, 0) or {})
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		last[p] = nil
		busy[p] = nil
		bucket[p] = nil
		strikes[p] = nil
	end)
end

function Interact.onPrompt(action: string, fn)
	promptHandlers[action] = fn
end

function Interact.onAction(kind: string, fn)
	actionHandlers[kind] = fn
end

return Interact
