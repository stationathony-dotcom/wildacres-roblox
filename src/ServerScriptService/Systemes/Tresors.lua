-- Trésors cachés par les joueurs (20/11, étape 19 « chasses au trésor créées par les joueurs ») :
--   /enterrer <objet> <n>  : enterre des objets de son sac là où l'on se tient (on peut compléter sa propre
--                            cache en restant à moins de 4 studs) ;
--   /cartes                : ses caches et les cartes reçues, avec l'indice (« 120 pas au nord-est de Valdor ») ;
--   /carte <n°> <pseudo>   : donne la carte d'une de ses caches à un joueur présent dans ce monde.
-- N'importe qui peut la trouver : 3 coups de pelle au bon endroit (moins de 4 studs) et le contenu est à lui
-- (même sans carte : la chance existe). Rien n'est annoncé ; le poseur est prévenu (journal de protection).
-- État : G.world.extra.caches[id] = { x, z, items = { [objet] = n }, by = "u<UserId>", byName, day, dug = { [uid] = coups } }
--        G.world.players[uid].maps = { [id] = true } (cartes reçues)

local Tresors = {}
local G, Config

Tresors.R = 4 -- studs autour de la cache
Tresors.DIGS = 3
local DIRS = { "au nord", "au nord-est", "à l'est", "au sud-est", "au sud", "au sud-ouest", "à l'ouest", "au nord-ouest" }

local function caches()
	G.world.extra = G.world.extra or {}
	G.world.extra.caches = G.world.extra.caches or {}
	return G.world.extra.caches
end

local function rec(uid)
	local k = tostring(uid)
	G.world.players[k] = G.world.players[k] or {}
	return G.world.players[k]
end

-- « à 120 pas au nord-est de Valdor » (village le plus proche ; 0° = nord = -Z)
function Tresors.hint(x: number, z: number): string
	local Q = G.Quetes and rawget(G.Quetes, "villages")
	local best, bd = nil, math.huge
	for _, v in (Q and Q()) or {} do
		local d = Vector2.new(v.x - x, v.z - z).Magnitude
		if d < bd then
			best, bd = v, d
		end
	end
	if not best then
		return string.format("vers (%d, %d)", math.floor(x), math.floor(z))
	end
	local dx, dz = x - best.x, z - best.z
	local deg = math.deg(math.atan2(dx, -dz)) % 360
	local steps = math.floor(bd / 10 + 0.5) * 10
	return "à " .. steps .. " pas " .. DIRS[math.floor((deg + 22.5) / 45) % 8 + 1] .. " de " .. best.name
end

local function contents(c): string
	local parts = {}
	for item, n in c.items do
		local info = Config.ITEMS[item]
		table.insert(parts, n .. " " .. (info and info.name or item))
	end
	return table.concat(parts, ", ")
end

-- « gold », « or », « planches »… : identifiant, ou nom (sans majuscules ni accents exigés) d'un objet
function Tresors.resolve(word: string): string?
	if Config.ITEMS[word] then
		return word
	end
	local w = string.lower(word)
	if w == "or" then
		return "gold"
	end
	for id, info in Config.ITEMS do
		if string.lower(info.name or "") == w then
			return id
		end
	end
	return nil
end

function Tresors.bury(player: Player, item: string?, n: any): (boolean, string)
	local root = G.Util.root(player)
	if not root or type(item) ~= "string" then
		return false, "/enterrer <objet> <nombre>  (objet de ton sac, ex. /enterrer gold 200)"
	end
	item = Tresors.resolve(item) or item
	local info = Config.ITEMS[item]
	n = math.floor(tonumber(n) or 1)
	if not info or info.tool or n < 1 then
		return false, "Objet inconnu ou impossible à enterrer."
	end
	if G.Joueurs.count(player, item) < n then
		return false, "Tu n'as pas " .. n .. " " .. info.name .. "."
	end
	local p = root.Position
	if G.Util.isWater(p.X, p.Z) then
		return false, "On n'enterre rien dans l'eau."
	end
	local uid = G.Util.pid(player)
	-- compléter sa propre cache toute proche, sinon en creuser une nouvelle
	local id, c
	for cid, cc in caches() do
		if cc.by == uid and Vector2.new(cc.x - p.X, cc.z - p.Z).Magnitude < Tresors.R then
			id, c = cid, cc
		end
	end
	if not G.Joueurs.take(player, item, n) then
		return false, "Tu n'as pas " .. n .. " " .. info.name .. "."
	end
	if not c then
		id = G.Util.newId("cache")
		c = { x = math.floor(p.X), z = math.floor(p.Z), items = {}, by = uid, byName = player.DisplayName, day = G.world.day, dug = {} }
		caches()[id] = c
	end
	c.items[item] = (c.items[item] or 0) + n
	G.Joueurs.sync(player)
	G.Economie.record(player, "enterre", n .. " " .. item .. " (" .. id .. ")")
	if G.Mondes and G.Mondes.saveSoon then
		G.Mondes.saveSoon(player)
	end
	return true, "🪙 Enterré : " .. contents(c) .. ". Cache " .. id .. ", " .. Tresors.hint(c.x, c.z) .. " (/carte " .. id .. " <pseudo> pour la donner)."
end

function Tresors.list(player: Player): { string }
	local uid = G.Util.pid(player)
	local maps = rec(player.UserId).maps or {}
	local lines = {}
	for id, c in caches() do
		if c.by == uid then
			table.insert(lines, "🪙 Ta cache " .. id .. " : " .. contents(c) .. " — " .. Tresors.hint(c.x, c.z))
		elseif maps[id] then
			table.insert(lines, "🗺️ Carte de " .. tostring(c.byName) .. " : une croix " .. Tresors.hint(c.x, c.z))
		end
	end
	if #lines == 0 then
		table.insert(lines, "Aucune cache ni carte dans ce monde. (/enterrer <objet> <n>)")
	end
	return lines
end

function Tresors.giveMap(player: Player, id: string?, target: Player?): (boolean, string)
	local c = id and caches()[id]
	if not c or c.by ~= G.Util.pid(player) then
		return false, "/carte <n° de ta cache> <pseudo>  (/cartes pour voir tes caches)"
	end
	if not target or target == player then
		return false, "Ce joueur n'est pas dans ce monde."
	end
	local r = rec(target.UserId)
	r.maps = r.maps or {}
	r.maps[id] = true
	G.Util.toast(target, "🗺️ " .. player.DisplayName .. " te remet une carte : une croix " .. Tresors.hint(c.x, c.z) .. ". (/cartes)", "big")
	return true, "Carte remise à " .. target.DisplayName .. "."
end

-- Coup de pelle (Journal.digTreasure) : vrai si l'on creusait sur une cache de joueur
function Tresors.dig(player: Player): boolean
	local root = G.Util.root(player)
	if not root or not G.world then
		return false
	end
	local p = root.Position
	for id, c in caches() do
		if Vector2.new(c.x - p.X, c.z - p.Z).Magnitude < Tresors.R and math.abs(p.Y - G.Util.groundY(c.x, c.z)) < 8 then
			local uid = tostring(player.UserId)
			c.dug = c.dug or {}
			c.dug[uid] = (c.dug[uid] or 0) + 1
			if c.dug[uid] < Tresors.DIGS then
				G.Util.toast(player, c.dug[uid] == 1 and "⛏️ La terre a été remuée ici…" or "⛏️ Ça sonne creux !")
				return true
			end
			caches()[id] = nil
			for item, n in c.items do
				G.Joueurs.add(player, item, n, true)
			end
			G.Joueurs.sync(player)
			G.Economie.record(player, "deterre", id .. " de " .. tostring(c.by) .. " : " .. contents(c))
			G.Util.toast(player, "💰 Une cache de " .. tostring(c.byName) .. " ! " .. contents(c) .. ".", "big")
			if c.by ~= G.Util.pid(player) and G.Protection and G.Protection.log then
				pcall(G.Protection.log, c.by, "Ta cache " .. id .. " a été déterrée par " .. player.DisplayName .. ".", true)
			end
			for _, m in G.world.players do
				if type(m.maps) == "table" then
					m.maps[id] = nil
				end
			end
			return true
		end
	end
	return false
end

function Tresors.init(g)
	G = g
	Config = G.Config
end

return Tresors
