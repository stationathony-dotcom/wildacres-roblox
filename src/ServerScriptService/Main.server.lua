-- Wild Acres — point d'entrée serveur. Branche les systèmes entre eux (table G) et fait
-- tourner la boucle de jeu. Chaque système vit dans ServerScriptService.Systemes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

Players.CharacterAutoLoads = false

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Systemes = script.Parent:WaitForChild("Systemes")

local G = {
	Config = require(Shared.Config),
	Dialogue = require(Shared.Dialogue),
	Gear = require(Shared.Gear),
	WG = require(Shared.RegionPlan),
	remotes = {},
	world = nil,
	wg = nil,
	paused = false,
}

-- Messages client <-> serveur
local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
for _, name in { "Action", "Notify", "Inventory", "Dialog", "Menu", "Fade", "Fx" } do
	local r = remotes:FindFirstChild(name) or Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	G.remotes[name] = r
end

-- Groupes de collision : les portes laissent passer les PNJ, pas les joueurs
local function group(name: string)
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end
group("Portes")
group("PNJ")
PhysicsService:CollisionGroupSetCollidable("Portes", "PNJ", false)
PhysicsService:CollisionGroupSetCollidable("PNJ", "PNJ", false)

-- Chargement des systèmes (un système absent est remplacé par un bouchon silencieux)
local NAMES = { "Util", "Interact", "Clock", "World", "Joueurs", "Save", "Mondes", "Game", "Avatar", "Tools", "Props", "Farm",
	"Doors", "Npcs", "Law", "Animals", "Horses", "Enemies", "Combat", "Fishing", "Shop", "Bodies", "Parcelles",
	"Minijeux", "Compagnons", "Protection", "Economie", "Social", "Armee", "Evenements", "Clans", "Poste", "Terraforme", "Batir", "Machines", "Donjons", "Bestiaire", "Demolir", "Villages", "Meteo", "Admin", "Politique", "Barques", "Activites", "Journal", "Avantpostes", "Ilots", "Nasses", "Nids", "Butin", "Quetes", "QuetesLieux", "Ventes", "Chantiers", "Tourelles", "Chateaux", "Moissons", "Bosquets", "Canaux", "Herbes", "Metiers", "Hameaux", "Fauche", "Reputation", "Chroniques", "Ouvriers", "Livres", "Froid", "Villes", "Demandes", "Duels", "Tresors", "Infos", "Cascades", "Envol", "Montures" }
local stub = setmetatable({}, { __index = function()
	return function() end
end })
for _, name in NAMES do
	local m = Systemes:FindFirstChild(name)
	if m then
		local ok, mod = pcall(require, m)
		if ok then
			G[name] = mod
		else
			warn("[WildAcres] système " .. name .. " en erreur : " .. tostring(mod))
			G[name] = stub
		end
	else
		G[name] = stub
	end
end
for _, name in NAMES do
	local sys = G[name]
	if sys ~= stub and sys.init then
		local ok, err = pcall(sys.init, G)
		if not ok then
			warn("[WildAcres] init " .. name .. " : " .. tostring(err))
		end
	end
end

-- Systèmes appelés au chargement d'une région et au changement de jour
G.regionSystems = {}
for _, name in { "Bosquets", "Herbes", "Chateaux", "Hameaux", "Props", "Farm", "Villages", "Moissons", "Doors", "Npcs", "Metiers", "Villes", "Animals", "Horses", "Enemies", "Bestiaire", "Shop", "Compagnons", "Batir", "Donjons", "Demolir", "Ilots", "Nids", "Chantiers" } do
	if G[name] ~= stub and G[name].onRegionLoad then
		table.insert(G.regionSystems, G[name])
	end
end
G.daySystems = {}
for _, name in { "Farm", "Props", "Npcs", "Metiers", "Law", "Animals", "Enemies", "Shop", "Horses", "Compagnons", "Armee", "Machines", "Demolir", "Meteo", "Politique", "Avantpostes", "Nasses", "Nids", "Moissons", "Fauche", "Reputation", "Ouvriers", "Villes", "Admin" } do
	if G[name] ~= stub and G[name].newDay then
		table.insert(G.daySystems, G[name])
	end
end

_G.WildAcres = G -- accès depuis la barre de commande / les tests

-- Studio seulement : point d'appel des tests (le MCP tourne dans un autre contexte Lua, sans _G
-- partagé). ServerStorage.DbgAppel:Invoke("Joueurs.add", joueur, "wood", 3) appelle G.Joueurs.add.
if RunService:IsStudio() then
	local ServerStorage = game:GetService("ServerStorage")
	local dbg = ServerStorage:FindFirstChild("DbgAppel") or Instance.new("BindableFunction")
	dbg.Name = "DbgAppel"
	dbg.Parent = ServerStorage
	dbg.OnInvoke = function(path: string, ...)
		local sys, fn = string.match(path, "^(%w+)%.(%w+)$")
		local m = sys and G[sys]
		if not (m and type(m[fn]) == "function") then
			return false, "fonction inconnue : " .. tostring(path)
		end
		-- copie sans cycles (les entrées du jeu pointent vers leur région, leur modèle…)
		local function copy(v, depth, seen)
			if type(v) ~= "table" then
				return v
			end
			if seen[v] or depth > 3 then
				return "<table>"
			end
			seen[v] = true
			local t = {}
			for k, x in v do
				if type(k) == "string" or type(k) == "number" then
					t[k] = copy(x, depth + 1, seen)
				end
			end
			seen[v] = nil
			return t
		end
		local r = table.pack(pcall(m[fn], ...))
		for i = 1, r.n do
			r[i] = copy(r[i], 0, {})
		end
		return table.unpack(r, 1, r.n)
	end
end

-- Boucle de jeu
local worldAcc, flushAcc, saveAcc = 0, 0, 0
local STEPPED = { "Clock", "Game", "Npcs", "Metiers", "Animals", "Enemies", "Law", "Horses", "Fishing", "Doors", "Compagnons", "Protection", "Armee", "Evenements", "Donjons", "Meteo", "Barques", "Froid", "QuetesLieux", "Ventes", "Chantiers", "Duels", "Envol", "Montures" }
local perf, errored = {}, {}
G.perf = perf
RunService.Heartbeat:Connect(function(dt)
	if not G.world or not G.Mondes.ready then
		return
	end
	-- chaque système est chronométré (moyenne glissante en ms, lue par /wa perf) et isolé : une
	-- erreur dans un système ne bloque plus toute la boucle de jeu
	for _, name in STEPPED do
		local t0 = os.clock()
		local ok, err = pcall(G[name].step, dt)
		local ms = (os.clock() - t0) * 1000
		perf[name] = (perf[name] or ms) * 0.98 + ms * 0.02
		if not ok and not errored[name] then
			errored[name] = true -- on prévient une fois (pas de flot d'avertissements à 60 Hz)
			warn("[WildAcres] " .. name .. ".step : " .. tostring(err))
		end
	end
	worldAcc += dt
	if worldAcc > 0.5 then
		worldAcc = 0
		G.World.update()
	end
	flushAcc += dt
	if flushAcc > 0.15 then
		flushAcc = 0
		G.Joueurs.flush()
	end
	saveAcc += dt
	if saveAcc > G.Save.AUTOSAVE then
		saveAcc = 0
		for _, p in G.Game.players() do
			task.spawn(G.Save.save, p, false)
		end
	end
end)

-- Démarrage du monde de ce serveur (ou de l'accueil), puis arrivée des joueurs
task.spawn(function()
	local ok, err = pcall(G.Mondes.boot)
	if not ok then
		warn("[WildAcres] démarrage du monde : " .. tostring(err))
	end
end)
if G.Mondes.mode ~= "accueil" then
	Players.PlayerAdded:Connect(function(p)
		G.Game.start(p)
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(G.Game.start, p)
	end
end

game:BindToClose(function()
	local jobs = 0
	for _, p in G.Game.players() do
		jobs += 1
		task.spawn(function()
			G.Save.save(p, true)
			jobs -= 1
		end)
	end
	G.Mondes.shutdown()
	local t = os.clock()
	-- attend aussi les écritures lancées par PlayerRemoving (le serveur expulse tout le monde)
	while (jobs > 0 or G.Save.pending() > 0) and os.clock() - t < 25 do
		task.wait(0.2)
	end
end)
