-- Météo (étape 17). Un état pour tout le monde, qui change toutes les 1 h 30 à 5 h de jeu :
--   clair · nuageux · pluie · orage · brouillard  (+ vent qui accompagne nuageux / orage)
-- PAS DE SAISONS (décision du 20/11, confirmée : les biomes les remplacent) : un seul tirage pour tout l'an.
-- Rien n'est annoncé (principe du jeu) : on VOIT la pluie, on ENTEND l'orage. Le client dessine
-- (script Ambiance) d'après les attributs du Workspace : Weather, WeatherT (0-1).
--
-- Effets réels :
--  · pluie / orage : arrosent toutes les cultures plantées (même dans les régions sans joueur) ;
--  · orage : la foudre tombe près des joueurs dehors (dégâts si on est dessous, à découvert) ;
--  · brouillard : les témoins voient deux fois moins loin (Meteo.sightMult), la nuit aussi ;
--  · pluie : les poissons mordent plus vite (Meteo.biteMult).
-- L'état est sauvegardé avec le monde (G.world.extra.meteo) : un serveur qui redémarre le reprend.

local Meteo = {}
local G, Config

-- poids du tirage (moyenne des anciennes saisons)
local WEIGHTS = { clair = 4, nuageux = 2.75, pluie = 2.6, orage = 0.95, brouillard = 1.7 }
local WATER_EVERY = 30 -- minutes de jeu entre deux « arrosages » sous la pluie
local STRIKE_MIN, STRIKE_MAX = 25, 70 -- secondes réelles entre deux éclairs
local STRIKE_DAMAGE = 35

local function absMin(): number
	return (G.world.day or 1) * 1440 + (G.world.minutes or 0)
end

local function state()
	G.world.extra = G.world.extra or {}
	local m = G.world.extra.meteo
	if type(m) ~= "table" or not m.kind then
		m = { kind = "clair", untilMin = 0, lastWater = 0 }
		G.world.extra.meteo = m
	end
	return m
end

function Meteo.kind(): string
	return G.world and state().kind or "clair"
end

function Meteo.isWet(): boolean
	local k = Meteo.kind()
	return k == "pluie" or k == "orage"
end

-- Multiplicateur de la vue des témoins (Npcs) : brouillard = moitié, pluie forte = 0,75
function Meteo.sightMult(): number
	local k = Meteo.kind()
	if k == "brouillard" then
		return 0.5
	elseif k == "orage" then
		return 0.75
	elseif k == "pluie" then
		return 0.85
	end
	return 1
end

-- Délai avant que ça morde (Fishing) : la pluie réveille les poissons
function Meteo.biteMult(): number
	return Meteo.isWet() and 0.65 or 1
end

-- Les cultures poussent tous les jours (plus d'hiver)
function Meteo.cropGrows(): boolean
	return true
end

local function publish()
	local m = state()
	workspace:SetAttribute("Weather", m.kind)
	workspace:SetAttribute("Season", nil)
	workspace:SetAttribute("WeatherT", m.intensity or 1)
end

local function roll()
	local m = state()
	local w = WEIGHTS
	local total = 0
	for _, v in w do
		total += v
	end
	-- on évite deux fois le même état de suite (sauf clair) : la météo doit vivre
	local pick, kind = math.random() * total, "clair"
	for k, v in w do
		pick -= v
		if pick <= 0 then
			kind = k
			break
		end
	end
	if kind == m.kind and kind ~= "clair" then
		kind = "clair"
	end
	m.kind = kind
	m.intensity = 0.6 + math.random() * 0.4
	m.untilMin = absMin() + math.random(90, 300)
	publish()
end

function Meteo.init(g)
	G = g
	Config = G.Config
end

-- Appelé par Clock.start (monde chargé) : reprend l'état sauvé, sinon en tire un
function Meteo.start()
	if absMin() >= state().untilMin then
		roll()
	else
		publish()
	end
end

-- Arrose toutes les cultures plantées par les joueurs (régions chargées ou non)
local function waterAll()
	for _, rs in G.world.regions do
		for _, st in rs.tilled or {} do
			if st.crop then
				st.watered = true
			end
		end
	end
	if G.Farm and G.Farm.refreshAll then
		G.Farm.refreshAll()
	end
end

local function underCover(pos: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {}
	for _, p in G.Game.players() do
		if p.Character then
			table.insert(ex, p.Character)
		end
	end
	params.FilterDescendantsInstances = ex
	return workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, 120, 0), params) ~= nil
end

-- Foudre : près d'un joueur pris au hasard, à 15-80 studs (parfois juste à côté de lui)
local nextStrike = 0
local function strike()
	local list = G.Game.players()
	if #list == 0 then
		return
	end
	local p = list[math.random(1, #list)]
	local root = G.Util.root(p)
	if not root then
		return
	end
	local a = math.random() * math.pi * 2
	local d = math.random() < 0.15 and math.random(0, 6) or math.random(15, 80)
	local x, z = root.Position.X + math.cos(a) * d, root.Position.Z + math.sin(a) * d
	local pos = Vector3.new(x, G.Util.groundY(x, z), z)
	G.remotes.Fx:FireAllClients("lightning", pos)
	-- dégâts : seulement à découvert et tout près
	for _, q in list do
		local r = G.Util.root(q)
		local hum = q.Character and q.Character:FindFirstChildOfClass("Humanoid")
		if r and hum and hum.Health > 0 and (r.Position - pos).Magnitude < 7 and not underCover(r.Position)
			and (q:GetAttribute("SpawnShield") or 0) < os.clock() then
			hum:TakeDamage(STRIKE_DAMAGE)
			G.remotes.Fx:FireClient(q, "hurt", pos)
			G.Util.toast(q, "⚡ La foudre est tombée tout près ! Mets-toi à l'abri.", "danger")
		end
	end
end

function Meteo.step(dt: number)
	if not G.world then
		return
	end
	local m = state()
	local now = absMin()
	if now >= m.untilMin then
		roll()
	end
	if Meteo.isWet() and now - (m.lastWater or 0) >= WATER_EVERY then
		m.lastWater = now
		waterAll()
	end
	if m.kind == "orage" then
		local t = os.clock()
		if nextStrike == 0 then
			nextStrike = t + math.random(8, 20)
		elseif t >= nextStrike then
			nextStrike = t + math.random(STRIKE_MIN, STRIKE_MAX)
			strike()
		end
	else
		nextStrike = 0
	end
end

function Meteo.newDay()
	publish()
end

-- Outil de test / admin : forcer un temps (ex. DbgAppel "Meteo.force", "orage")
function Meteo.force(kind: string, minutes: number?)
	if not WEIGHTS[kind] then
		return false
	end
	local m = state()
	m.kind = kind
	m.intensity = 1
	m.untilMin = absMin() + (minutes or 120)
	publish()
	return true
end

return Meteo
