-- Journal de découvertes et carte personnelle (étapes 7 et 18).
-- Chaque région où l'on met les pieds est « découverte » pour ce monde : la carte [M] la dessine
-- (biome, lieu), le reste reste dans le brouillard. Entrer pour la première fois dans une région
-- qui a un lieu (village, ferme, ruine, antre) le note au journal avec un petit fanfare de
-- découverte. Rien n'est révélé à l'avance : la carte, c'est ce qu'on a parcouru.
-- Données : prof.journal = { [idDuMonde] = "rx,rz;rx,rz;…" } (chaîne compacte) + prof.journal.n
-- (nombre de lieux trouvés, toutes îles confondues, pour les titres).

local Journal = {}
local G, Config

local seen = {} -- joueur -> { set de clés du monde courant, dernière région }

local KIND_NAME = { village = "Village", farm = "Ferme", ruin = "Ruine", lair = "Antre" }

local function setOf(player: Player)
	local s = seen[player]
	if s then
		return s
	end
	local prof = G.Joueurs.get(player)
	if not prof or not G.world then
		return nil
	end
	prof.journal = type(prof.journal) == "table" and prof.journal or {}
	local set = {}
	for k in string.gmatch(prof.journal[G.world.id] or "", "[^;]+") do
		set[k] = true
	end
	s = { set = set, last = nil }
	seen[player] = s
	return s
end

local function persist(player: Player, s)
	local prof = G.Joueurs.get(player)
	if not prof then
		return
	end
	local keys = {}
	for k in s.set do
		table.insert(keys, k)
	end
	prof.journal[G.world.id] = table.concat(keys, ";")
end

function Journal.init(g)
	G = g
	Config = G.Config
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		seen[p] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1.5)
			if G.world and G.wg then
				for _, p in G.Game.players() do
					pcall(Journal.check, p)
				end
			end
		end
	end)
end

function Journal.check(player: Player)
	local root = G.Util.root(player)
	local s = root and setOf(player)
	if not s then
		return
	end
	local rx, rz = G.WG.regionOf(math.floor(root.Position.X / Config.CELL), math.floor(root.Position.Z / Config.CELL))
	local key = rx .. "," .. rz
	if key == s.last then
		return
	end
	s.last = key
	if s.set[key] then
		return
	end
	s.set[key] = true
	persist(player, s)
	local poi = G.wg:poiOf(rx, rz)
	if poi then
		local prof = G.Joueurs.get(player)
		prof.journal.n = (prof.journal.n or 0) + 1
		local name = poi.name ~= "" and poi.name or nil
		local label = (G.WG.PLACE_NAMES[poi.kind] or KIND_NAME[poi.kind] or "un lieu"):gsub("{name}", name or "?")
		G.Util.toast(player, "📍 Découverte : " .. label, "big")
		-- récompense permanente (19/11) : chaque lieu trouvé compte pour les succès d'explorateur et
		-- endurcit le voyageur (vitesse et chance, par la pratique)
		G.Social.bump(player, "lieux")
		local dec = G.Joueurs.talent(player, "decouvreur")
		-- expédition (19/11) : découvert avec un membre du groupe à moins de 60 studs = +50 %
		local exp = (G.Social and rawget(G.Social, "groupBonus") and G.Social.groupBonus(player) > 1) and 1.5 or 1
		G.Joueurs.addStatXp(player, "vitesse", math.floor((dec > 0 and 50 or 25) * exp))
		G.Joueurs.addStatXp(player, "chance", math.floor((dec > 0 and 20 or 10) * exp))
		if exp > 1 then
			G.Util.toast(player, "🧭 Découverte en expédition : +50 % d'expérience.")
		end
		if dec > 0 then
			G.Joueurs.add(player, "gold", 20 * dec, true)
		end
		if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "decouvrir", poi.kind) end
		G.Util.sfx("pieces", Vector3.zero, player)
	end
	G.remotes.Fx:FireClient(player, "carte", key)
	-- talent Cartographe : les régions voisines se dessinent aussi sur la carte (sans fanfare)
	local carto = G.Joueurs.talent(player, "cartographe")
	if carto > 0 then
		for dx = -carto, carto do
			for dz = -carto, carto do
				local k2 = (rx + dx) .. "," .. (rz + dz)
				if not s.set[k2] and G.WG.inWorld(rx + dx, rz + dz) then
					s.set[k2] = true
					G.remotes.Fx:FireClient(player, "carte", k2)
				end
			end
		end
		persist(player, s)
	end
	G.Joueurs.markDirty(player)
end

-- ----------------------------------------------------------------- Cartes au trésor
-- Lire une carte : une cache est tirée dans ce monde, sur la terre ferme, loin de l'arrivée ; on
-- reçoit un indice (direction, distance, repère) et une croix sur sa carte [M]. Une seule cache à
-- la fois par joueur et par monde. Avec une boussole dans le sac, l'indice dit la distance exacte.
-- On la déterre avec la pelle (3 coups) : trésor + or. Quatre fragments font une carte (atelier).
local DIRS = { "au nord", "au nord-est", "à l'est", "au sud-est", "au sud", "au sud-ouest", "à l'ouest", "au nord-ouest" }

local function hintFor(player: Player, t)
	local root = G.Util.root(player)
	if not root then
		return ""
	end
	local d = Vector3.new(t.x - root.Position.X, 0, t.z - root.Position.Z)
	local ang = math.deg(math.atan2(d.X, -d.Z)) % 360
	local dir = DIRS[(math.floor((ang + 22.5) / 45) % 8) + 1]
	local dist = d.Magnitude
	local exact = G.Joueurs.has(player, "compass") or G.Joueurs.has(player, "old_compass")
	local far = exact and (math.floor(dist / 10) * 10 .. " pas") or (dist < 150 and "tout près" or (dist < 600 and "à quelques collines" or "très loin"))
	return dir .. ", " .. far .. (t.biome and (", en " .. t.biome) or "")
end

function Journal.readTreasureMap(player: Player)
	local prof = G.Joueurs.get(player)
	if not prof or not G.world then
		return
	end
	prof.treasures = type(prof.treasures) == "table" and prof.treasures or {}
	local t = prof.treasures[G.world.id]
	if t then
		local progress = (t.dug or 0) > 0 and (" Coups de pelle : " .. t.dug .. "/3.") or ""
		G.Util.toast(player, "🗺️ Ta carte montre toujours une croix : " .. hintFor(player, t) .. "." .. progress, "big")
		return
	end
	local rng = Random.new()
	local R = Config.WORLD_RADIUS * 0.75
	for _ = 1, 40 do
		local rx, rz = rng:NextInteger(-math.floor(R), math.floor(R)), rng:NextInteger(-math.floor(R), math.floor(R))
		if G.WG.inWorld(rx, rz) then
			local span = Config.CELL * Config.REGION
			local x, z = (rx + rng:NextNumber(0.15, 0.85)) * span, (rz + rng:NextNumber(0.15, 0.85)) * span
			if not G.Util.isWater(x, z) and (Vector3.new(x, 0, z) - G.Game.spawnPos() * Vector3.new(1, 0, 1)).Magnitude > 300 then
				if not G.Joueurs.take(player, "treasure_map", 1) then
					return
				end
				local biome = G.Config.BIOMES[G.wg:regionBiome(rx, rz)]
				t = { x = math.floor(x), z = math.floor(z), biome = biome and biome.name or nil, dug = 0 }
				prof.treasures[G.world.id] = t
				G.Joueurs.markDirty(player)
				G.remotes.Fx:FireClient(player, "tresor", Vector3.new(t.x, 0, t.z))
				G.Util.toast(player, "🗺️ Une croix sur la carte ! La cache est " .. hintFor(player, t) .. ". Prends une pelle.", "big")
				return
			end
		end
	end
	G.Util.toast(player, "La carte est trop effacée pour cette île.")
end

-- Coup de pelle : près de la croix (8 studs) ? 3 coups et le coffre sort de terre
function Journal.digTreasure(player: Player): boolean
	local prof = G.Joueurs.get(player)
	local t = prof and type(prof.treasures) == "table" and G.world and prof.treasures[G.world.id]
	local root = G.Util.root(player)
	if not t or not root or (Vector3.new(t.x, root.Position.Y, t.z) - root.Position).Magnitude > 8 then
		return false
	end
	-- Vérifier aussi la hauteur pour les caves, ponts et survols de la croix.
	if math.abs(root.Position.Y - G.Util.groundY(t.x, t.z)) > 8 then
		return false
	end
	t.dug = (t.dug or 0) + 1
	G.Util.sfx("pelle", root.Position)
	if t.dug < 3 then
		G.Joueurs.markDirty(player)
		G.Util.toast(player, t.dug == 1 and "⛏️ La terre est meuble ici…" or "⛏️ Ça sonne creux !")
		return true
	end
	prof.treasures[G.world.id] = nil
	local list = G.Config.Catalogue.TREASURE
	local hunter = G.Joueurs.talent(player, "chasseur_tresor") > 0 -- talent Explorateur
	for _ = 1, hunter and 4 or 3 do
		local e = list[math.random(1, #list)]
		G.Joueurs.add(player, e[1], math.random(e[2], e[3]))
	end
	G.Joueurs.add(player, "gold", math.floor(math.random(80, 200) * (hunter and 1.5 or 1)))
	G.Util.finds(player, "event")
	G.Util.toast(player, "💰 Un coffre enfoui ! Trésor déterré.", "big")
	G.remotes.Fx:FireClient(player, "tresor", nil)
	G.Joueurs.markDirty(player)
	return true
end

-- Régions découvertes du monde courant (pour la carte, envoyées avec le profil)
function Journal.keysFor(player: Player): string
	local prof = G.Joueurs.get(player)
	return prof and type(prof.journal) == "table" and G.world and prof.journal[G.world.id] or ""
end

return Journal
