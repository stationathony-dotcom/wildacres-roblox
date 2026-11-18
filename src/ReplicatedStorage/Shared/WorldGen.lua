-- Monde façon Minecraft (repris du jeu Godot), en île finie de WORLD_RADIUS régions pour le multi :
-- le terrain vient d'un bruit continu, le climat (température, humidité) donne le biome, et
-- chaque région de REGION x REGION cases reçoit un contenu tiré de la graine (village, ferme,
-- ruine, antre ou nature sauvage). Tout est déterministe : la même graine redonne le même
-- monde, et une région se replanifie à l'identique quand on y revient.
-- Coordonnées : case (cx, cz) entière ; centre monde = (cx*CELL + CELL/2, cz*CELL + CELL/2).

local Config = require(script.Parent.Config)
local Dialogue = require(script.Parent.Dialogue)

local CELL, REGION = Config.CELL, Config.REGION

local WG = {}
WG.__index = WG

-- Seuils du bruit (calibrés sur un échantillon : ~12 % de lacs, rivières fines,
-- ~30 % de plateaux dont ~8 % de sommets, ~30 % de forêt dense).
WG.T_LAKE = -0.22
WG.T_RIVER = 0.011
WG.T_PLATEAU1 = 0.1
WG.T_PLATEAU2 = 0.27
WG.T_FOREST = 0.1

WG.POI_SIZE = { village = { 26, 22 }, farm = { 18, 16 }, ruin = { 12, 12 }, lair = { 14, 12 } }
WG.VILLAGE_NAMES = { "Bourg-les-Choux", "Val-Fougère", "Pré-Moulu", "Ronce-la-Vieille", "Combe-aux-Merles",
	"Saint-Navet", "Les Trois-Puits", "Haut-Verger", "Mare-aux-Saules", "Bois-Joli", "Clos-Doré", "Roche-Pommier" }
WG.NAMES_F = { "Berthe", "Diane", "Fanny", "Hortense", "Jeanne", "Margot", "Odile", "Rosalie", "Sidonie", "Ursule",
	"Yvette", "Zélie", "Brune", "Philomène", "Lucienne", "Noémie", "Pervenche", "Capucine", "Agathe", "Mathilde",
	"Héloïse", "Albertine", "Clémence", "Germaine", "Irène", "Joséphine", "Léontine", "Marthe", "Suzon", "Violette" }
WG.NAMES_M = { "Albin", "Côme", "Eudes", "Gaspard", "Isidore", "Léon", "Norbert", "Prosper", "Théo", "Victor",
	"Armand", "Clovis", "Mathurin", "Anselme", "Gustave", "Marius", "Octave", "Ernest", "Firmin", "Honoré",
	"Basile", "Célestin", "Désiré", "Fernand", "Hippolyte", "Jules", "Lucien", "Raoul", "Séraphin", "Ulysse" }
WG.BOSSES = {
	{ id = "boss_slime", name = "Roi des Slimes", minion = "slime_blue" },
	{ id = "boss_myconid", name = "Myconide Ancien", minion = "myconid" },
	{ id = "boss_goblin", name = "Chef Gobelin", minion = "goblin" },
}
-- Apparence des PNJ : teints, couleurs de cheveux, de vêtements
WG.SKINS = { Color3.fromRGB(255, 220, 190), Color3.fromRGB(234, 184, 146), Color3.fromRGB(190, 132, 96), Color3.fromRGB(120, 80, 56) }
WG.HAIR_COLORS = { Color3.fromRGB(60, 40, 30), Color3.fromRGB(140, 90, 50), Color3.fromRGB(230, 200, 120), Color3.fromRGB(180, 70, 40), Color3.fromRGB(200, 200, 200), Color3.fromRGB(30, 30, 34) }
WG.SHIRTS = { Color3.fromRGB(200, 70, 60), Color3.fromRGB(70, 120, 190), Color3.fromRGB(90, 150, 80), Color3.fromRGB(230, 190, 80),
	Color3.fromRGB(150, 90, 170), Color3.fromRGB(240, 240, 230), Color3.fromRGB(110, 80, 60), Color3.fromRGB(230, 130, 160) }
WG.PANTS = { Color3.fromRGB(70, 60, 50), Color3.fromRGB(50, 70, 110), Color3.fromRGB(110, 90, 60), Color3.fromRGB(60, 60, 60), Color3.fromRGB(140, 120, 90) }
-- couleurs ajoutées pour les tenues des îles (gen ≥ 2) : à la SUITE des 8 / 5 d'origine, pour que les
-- PNJ des mondes en gen 1 gardent exactement la même tenue (tirage sur les 8 / 5 premières seulement)
WG.SHIRTS_GEN1, WG.PANTS_GEN1 = #WG.SHIRTS, #WG.PANTS
for _, c in {
	Color3.fromRGB(230, 236, 240), Color3.fromRGB(40, 60, 100), Color3.fromRGB(150, 150, 160), -- 9 blanc givre, 10 bleu nuit, 11 gris loup
	Color3.fromRGB(226, 200, 150), Color3.fromRGB(196, 120, 50), Color3.fromRGB(40, 140, 140), -- 12 sable, 13 ocre, 14 turquoise
	Color3.fromRGB(80, 100, 60), Color3.fromRGB(60, 80, 70), Color3.fromRGB(120, 110, 70), -- 15 mousse, 16 vase, 17 roseau
	Color3.fromRGB(200, 90, 40), Color3.fromRGB(150, 60, 40), Color3.fromRGB(60, 90, 50), -- 18 rouille, 19 brique, 20 sapin
	Color3.fromRGB(70, 50, 40), Color3.fromRGB(40, 36, 34), -- 21 cuir, 22 suie
	Color3.fromRGB(250, 200, 210), Color3.fromRGB(200, 230, 150), Color3.fromRGB(255, 220, 120), -- 23 rose, 24 pomme, 25 miel
} do
	table.insert(WG.SHIRTS, c)
end
for _, c in { Color3.fromRGB(220, 224, 230), Color3.fromRGB(190, 160, 110), Color3.fromRGB(70, 80, 60), Color3.fromRGB(40, 36, 34) } do
	table.insert(WG.PANTS, c) -- 6 blanc, 7 sable, 8 kaki, 9 noir
end

WG.HAIRS_F = { "long", "chignon", "tresses", "carre" }
WG.HAIRS_M = { "court", "court", "herisse", "chauve", "barbe" }
WG.ROLE_HATS = { farmer = { "", "paille", "paille" }, merchant = { "", "beret", "toque" }, sheriff = { "sherif" }, villager = { "", "", "", "", "beret", "paille", "bonnet" } }

-- ----------------------------------------------------------------- Hachage

local function fnv(s: string): number
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (bit32.lshift(h, 24) + h * 403) % 4294967296
	end
	return h
end

function WG.hash(...): number
	local parts = table.pack(...)
	for i = 1, parts.n do
		parts[i] = tostring(parts[i])
	end
	return fnv(table.concat(parts, ":", 1, parts.n))
end

local function key2(x: number, z: number): string
	return x .. "," .. z
end
WG.key2 = key2

function WG.regionOf(cx: number, cz: number): (number, number)
	return math.floor(cx / REGION), math.floor(cz / REGION)
end

function WG.cellOf(pos: Vector3): (number, number)
	return math.floor(pos.X / CELL), math.floor(pos.Z / CELL)
end

function WG.center(cx: number, cz: number): (number, number)
	return cx * CELL + CELL / 2, cz * CELL + CELL / 2
end

-- ----------------------------------------------------------------- Bruit

-- Version du générateur. Un monde garde À VIE la version avec laquelle il a été créé (sinon ses
-- lieux bougeraient sous les constructions des joueurs). Historique :
--   1 : version d'origine (vérifiée par tools/bancs/generation.luau : 0 lieu inondé, 0 maison
--       chevauchante ou dans l'eau, une seule ruine de départ, sur 4 graines)
--   2 : îles à THÈME tiré de la graine (WG.THEMES) : climat décalé, biomes permis (les autres sont
--       remplacés par un voisin), noms de villages propres, faune triée (Bestiaire) ; 18/11/2026
-- Toute évolution qui change le résultat d'une graine DOIT passer par une nouvelle version testée
-- avec `if self.gen >= N` et un tirage aléatoire séparé (ne pas décaler les tirages existants).
WG.CURRENT_GEN = 2

-- ----------------------------------------------------------------- Thèmes d'île (gen ≥ 2)
-- Chaque île tire son thème de sa graine : on ne retrouve pas les mêmes paysages, villages, créatures
-- (ni plus tard les mêmes quêtes) d'une île à l'autre. t / h = décalage du climat (froid / chaud,
-- sec / humide) ; biomes = ceux qui existent sur l'île ; danger = ajouté au danger du monde.
WG.THEMES = {
	{ id = "tempere", name = "Terres tempérées", icon = "🌼", weight = 3, t = 0, h = 0, danger = 0,
		biomes = { prairie = true, foret = true, marais = true }, shirts = { 1, 2, 3, 4, 5, 6, 7, 8 },
		villages = { "Bourg-les-Choux", "Pré-Moulu", "Saint-Navet", "Les Trois-Puits", "Haut-Verger", "Clos-Doré", "Combe-aux-Merles", "Bois-Joli" } },
	{ id = "glaces", name = "Île des Glaces", icon = "❄️", weight = 2, t = -0.3, h = 0.02, danger = 1,
		biomes = { neige = true, foret = true, prairie = true }, shirts = { 9, 10, 11, 1, 21, 6 }, pants = { 6, 2, 9, 4 },
		hats = { "bonnet", "bonnet", "capuche", "" },
		villages = { "Givre-Haut", "Fjell-aux-Loups", "Blancbourg", "Port-Gelé", "Les Sapinières", "Combe-Froide", "Hiverlune", "Rocneige" } },
	{ id = "sables", name = "Archipel des Sables", icon = "🌵", weight = 2, t = 0.3, h = -0.08, danger = 1,
		biomes = { desert = true, prairie = true, marais = true }, shirts = { 12, 13, 14, 6, 18, 25 }, pants = { 7, 3, 6 },
		hats = { "bandeau", "bandeau", "paille", "" },
		villages = { "Oasis-Rouge", "Dune-Dorée", "Puits-du-Soleil", "Ksar-Ambre", "Palmeraie", "Sel-les-Bains", "Rocsable", "Mirage" } },
	{ id = "brumes", name = "Île des Brumes", icon = "🐸", weight = 2, t = 0.05, h = 0.3, danger = 1,
		biomes = { marais = true, foret = true, prairie = true }, shirts = { 15, 16, 17, 3, 21, 7 }, pants = { 8, 1, 3 },
		hats = { "capuche", "capuche", "paille", "" },
		villages = { "Mare-aux-Saules", "Brumelac", "Vasière", "Saule-Pleureur", "Les Roselières", "Gué-Noir", "Tourbe-Haute", "Brouillasse" } },
	{ id = "rousse", name = "Forêt rousse", icon = "🍂", weight = 2, t = 0.08, h = -0.22, danger = 0,
		biomes = { foret = true, prairie = true, neige = true }, shirts = { 18, 19, 20, 13, 4, 21 }, pants = { 1, 3, 8 },
		hats = { "tricorne", "beret", "", "" },
		villages = { "Val-Fougère", "Ronce-la-Vieille", "Chênaie", "Bois-Roux", "Les Érables", "Feuille-Morte", "Gland-d'Or", "Clairière" } },
	{ id = "sauvage", name = "Terres sauvages", icon = "🐺", weight = 1, t = 0, h = 0, danger = 2,
		biomes = { prairie = true, foret = true, desert = true, neige = true, marais = true }, shirts = { 21, 22, 11, 19, 20, 7 }, pants = { 9, 1, 4 },
		hats = { "capuche", "bandeau", "", "" },
		villages = { "Dernier-Refuge", "Fort-Ronce", "Croc-de-Pierre", "Garde-Loup", "Pic-Sauvage", "Bout-du-Monde", "Mauvais-Pas", "Roche-Pommier" } },
	{ id = "vergers", name = "Île aux Vergers", icon = "🍎", weight = 1.5, t = 0.12, h = -0.06, danger = -1,
		biomes = { prairie = true, desert = true }, shirts = { 23, 24, 25, 6, 8, 2 }, pants = { 7, 2, 5 },
		hats = { "paille", "paille", "beret", "" },
		villages = { "Pommeraie", "Cerisaie", "Bourg-Miel", "Vigne-Haute", "Les Abricotiers", "Douce-Prée", "Coteau-Doré", "Figuier" } },
}
-- biome remplacé quand l'île ne l'a pas : le plus proche d'abord
WG.FALLBACK = {
	neige = { "foret", "prairie", "marais", "desert" }, desert = { "prairie", "marais", "foret", "neige" },
	marais = { "foret", "prairie", "desert", "neige" }, foret = { "prairie", "neige", "marais", "desert" },
	prairie = { "foret", "marais", "desert", "neige" },
}

function WG.themeOf(seed: number)
	local r = Random.new(WG.hash(seed, "theme"))
	local total = 0
	for _, t in WG.THEMES do
		total += t.weight
	end
	local pick = r:NextNumber() * total
	for _, t in WG.THEMES do
		pick -= t.weight
		if pick <= 0 then
			return t
		end
	end
	return WG.THEMES[1]
end

function WG.new(seed: number, gen: number?)
	local self = setmetatable({}, WG)
	self.seed = seed
	self.gen = gen or WG.CURRENT_GEN
	local r = Random.new(seed)
	self.o = {}
	for i = 1, 8 do
		self.o[i] = { r:NextNumber(-4000, 4000), r:NextNumber(-4000, 4000) }
	end
	if self.gen >= 2 then
		self.theme = WG.themeOf(seed)
	end
	self.poiCache = {}
	self.roadCache = {}
	self.planCache = {}
	self.planOrder = {}
	return self
end

function WG:fbm(i: number, x: number, z: number, f: number, oct: number): number
	local o = self.o[i]
	local sum, amp, norm = 0, 1, 0
	for k = 1, oct do
		sum += math.noise((x + o[1]) * f, (z + o[2]) * f, i * 1.37 + k * 7.13) * amp
		norm += amp
		amp *= 0.5
		f *= 2
	end
	return sum / norm
end

local EDGE = Config.WORLD_RADIUS * REGION -- rayon de l'île en cases

function WG:continent(cx, cz)
	local c = self:fbm(1, cx, cz, 1 / 110, 3)
	-- bord de l'île : le sol plonge dans l'océan au-delà de 80 % du rayon
	local d = math.sqrt(cx * cx + cz * cz) / EDGE
	if d > 0.8 then
		c -= (d - 0.8) * 3.5
	end
	return c
end

-- Climat : température et humidité lentes ; neutres près du départ (prairie garantie)
function WG:climate(cx, cz): (number, number)
	local t = self:fbm(6, cx, cz, 1 / 300, 2)
	local h = self:fbm(7, cx, cz, 1 / 260, 2)
	local d = math.sqrt(cx * cx + cz * cz) / REGION
	local k = math.clamp((d - 1.5) / 2.5, 0, 1)
	local th = self.theme
	if th then
		return (t + th.t) * k, (h + th.h) * k
	end
	return t * k, h * k
end

-- Seuils calibrés sur 3 graines : ~25 % prairie, 20 % forêt, 18 % désert, 18 % toundra, 18 % marais
WG.T_COLD = -0.15
WG.T_HOT = 0.12
WG.H_WET = 0.19
WG.H_WET_HOT = 0.16
WG.H_FOREST = -0.02

local function rawBiome(t: number, h: number): string
	if t < WG.T_COLD then
		return "neige"
	elseif t > WG.T_HOT then
		return h > WG.H_WET_HOT and "marais" or "desert"
	elseif h > WG.H_WET then
		return "marais"
	elseif h < WG.H_FOREST then
		return "foret"
	end
	return "prairie"
end

function WG:biome(cx: number, cz: number): string
	local b = rawBiome(self:climate(cx, cz))
	local th = self.theme
	if th and not th.biomes[b] then
		for _, alt in WG.FALLBACK[b] do
			if th.biomes[alt] then
				return alt
			end
		end
	end
	return b
end

-- Biome d'une région (son centre) : village, boutique, cultures sauvages
function WG:regionBiome(rx: number, rz: number): string
	return self:biome(rx * REGION + REGION // 2, rz * REGION + REGION // 2)
end

-- Eau brute (avant les lieux) : moins de lacs au sec, plus au marais
function WG:wetRaw(cx: number, cz: number): boolean
	local _, h = self:climate(cx, cz)
	return self:continent(cx, cz) < WG.T_LAKE + h * 0.6 or self:river(cx, cz) < WG.T_RIVER
end

-- Hors de l'île (pour ne pas charger l'océan inutilement)
function WG.inWorld(rx: number, rz: number): boolean
	return math.sqrt((rx + 0.5) ^ 2 + (rz + 0.5) ^ 2) <= Config.WORLD_RADIUS + 0.5
end
function WG:river(cx, cz)
	return math.abs(self:fbm(2, cx, cz, 1 / 170, 2))
end
function WG:plateau(cx, cz)
	return self:fbm(3, cx, cz, 1 / 70, 3)
end
function WG:hills(cx, cz)
	return self:fbm(4, cx, cz, 1 / 24, 2)
end
function WG:forest(cx, cz)
	return self:fbm(5, cx, cz, 1 / 45, 2)
end

-- ----------------------------------------------------------------- Lieux

function WG:poiOf(rx: number, rz: number)
	local k = key2(rx, rz)
	local c = self.poiCache[k]
	if c ~= nil then
		return c or nil
	end
	local rg = Random.new(WG.hash(self.seed, "poi", rx, rz))
	local roll = rg:NextNumber()
	local dist = math.sqrt(rx * rx + rz * rz)
	local kind = nil
	if dist > Config.WORLD_RADIUS * 0.8 - 1 then
		kind = nil -- côte et océan : pas de lieu
	elseif rx == 0 and rz == 0 then
		kind = "ruin" -- la ruine de départ
	elseif rx == 1 and rz == 0 then
		kind = "village"
	elseif rx == -1 and rz == 1 then
		kind = "farm"
	elseif roll < 0.12 then
		kind = "village"
	elseif roll < 0.32 then
		kind = "farm"
	elseif roll < 0.42 then
		kind = "ruin"
	elseif roll < 0.5 and dist > 2.5 then
		kind = "lair"
	end
	if not kind then
		self.poiCache[k] = false
		return nil
	end
	local size = WG.POI_SIZE[kind]
	local ox = rg:NextInteger(5, REGION - size[1] - 5)
	local oz = rg:NextInteger(5, REGION - size[2] - 5)
	if rx == 0 and rz == 0 then
		ox, oz = 18, 18
	end
	local poi = {
		kind = kind, rx = rx, rz = rz, biome = self:regionBiome(rx, rz),
		x0 = rx * REGION + ox, z0 = rz * REGION + oz, w = size[1], d = size[2],
		start = (rx == 0 and rz == 0),
	}
	-- Point d'arrivée des routes (place, devant la maison…)
	if kind == "village" then
		poi.ax, poi.az = poi.x0 + 13, poi.z0 + 11
	elseif kind == "farm" then
		poi.ax, poi.az = poi.x0 + 5, poi.z0 + 7
	elseif kind == "ruin" then
		poi.ax, poi.az = poi.x0 + 6, poi.z0 + 9
	else
		poi.ax, poi.az = poi.x0 + 7, poi.z0 + 6
	end
	-- Nom du lieu (sert aux rumeurs et aux panneaux)
	local pr = Random.new(WG.hash(self.seed, "place", rx, rz))
	if kind == "village" then
		local names = self.theme and self.theme.villages or WG.VILLAGE_NAMES
		poi.name = names[pr:NextInteger(1, #names)]
	elseif kind == "farm" then
		local female = pr:NextNumber() < 0.5
		local pool = female and WG.NAMES_F or WG.NAMES_M
		poi.name = pool[pr:NextInteger(1, #pool)]
		poi.female = female
	elseif kind == "lair" then
		local b = WG.BOSSES[pr:NextInteger(1, #WG.BOSSES)]
		poi.name = b.name
		poi.boss = b.id
		poi.minion = b.minion
	else
		poi.name = ""
	end
	self.poiCache[k] = poi
	return poi
end

WG.PLACE_NAMES = {
	ruin = "une vieille maison abandonnée", farm = "la ferme de {name}", village = "le village de {name}", lair = "l'antre du {name}",
}
function WG.placeLabel(poi): string
	return Dialogue.format(WG.PLACE_NAMES[poi.kind], { name = poi.name })
end

-- ----------------------------------------------------------------- Routes

local DIRS = { { 1, 0 }, { 0, 1 }, { 1, 1 }, { -1, 1 } }

-- Route entre deux régions voisines (échantillons tous les 0,5 case), ou false.
function WG:road(ax: number, az: number, bx: number, bz: number)
	local k = ax .. "," .. az .. ">" .. bx .. "," .. bz
	local c = self.roadCache[k]
	if c ~= nil then
		return c
	end
	local A, B = self:poiOf(ax, az), self:poiOf(bx, bz)
	local result = false
	if A and B then
		local diag = ax ~= bx and az ~= bz
		-- En diagonale seulement si aucun des deux voisins communs n'a de lieu (sinon on passe par lui)
		if not diag or (not self:poiOf(ax, bz) and not self:poiOf(bx, az)) then
			local rg = Random.new(WG.hash(self.seed, "route", k))
			local x0, z0, x2, z2 = A.ax + 0.5, A.az + 0.5, B.ax + 0.5, B.az + 0.5
			local dx, dz = x2 - x0, z2 - z0
			local len = math.sqrt(dx * dx + dz * dz)
			local off = rg:NextNumber(-9, 9)
			local x1, z1 = (x0 + x2) / 2 - dz / len * off, (z0 + z2) / 2 + dx / len * off
			local n = math.ceil(len * 2.2)
			local samples = table.create(n + 1)
			for i = 0, n do
				local t = i / n
				local u = 1 - t
				samples[i + 1] = { u * u * x0 + 2 * u * t * x1 + t * t * x2, u * u * z0 + 2 * u * t * z1 + t * t * z2 }
			end
			result = { key = k, samples = samples, minx = math.min(x0, x1, x2), maxx = math.max(x0, x1, x2), minz = math.min(z0, z1, z2), maxz = math.max(z0, z1, z2) }
		end
	end
	self.roadCache[k] = result
	return result
end

-- Routes pouvant toucher la région (une extrémité dans le 3x3 autour d'elle)
function WG:roadsNear(rx: number, rz: number)
	local out, seen = {}, {}
	for qx = rx - 1, rx + 1 do
		for qz = rz - 1, rz + 1 do
			for _, d in DIRS do
				for _, s in { 1, -1 } do
					local ax, az, bx, bz = qx, qz, qx + d[1] * s, qz + d[2] * s
					if s == -1 then
						ax, az, bx, bz = bx, bz, qx, qz
					end
					local r = self:road(ax, az, bx, bz)
					if r and not seen[r.key] then
						seen[r.key] = true
						table.insert(out, r)
					end
				end
			end
		end
	end
	return out
end

-- Liste des lieux voisins (pour les rumeurs) : {poi, distance}
function WG:placesAround(rx: number, rz: number, radius: number)
	local out = {}
	for x = rx - radius, rx + radius do
		for z = rz - radius, rz + radius do
			if x ~= rx or z ~= rz then
				local p = self:poiOf(x, z)
				if p then
					table.insert(out, p)
				end
			end
		end
	end
	return out
end

return WG
