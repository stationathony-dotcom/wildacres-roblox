-- Bosquets autour des villages (image cible du 18/11 : le village est entouré d'arbres). Dans les
-- régions SANS lieu voisines d'un village, quelques bosquets denses sont ajoutés au plan AVANT que
-- Props ne pose les objets : ce sont de vrais arbres (on les abat, ils comptent comme les autres).
-- Tirage à part (graine, région) et identifiants à part (« bq… ») : les mondes existants gardent
-- tout ce qu'ils avaient, les arbres déjà coupés restent coupés (état par identifiant, cf. Props).
-- Doit passer avant Chateaux (qui retire ce qui tombe dans ses murs) et avant Props.

local Bosquets = {}
local G, Config

local NEAR = { { -1, -1 }, { 0, -1 }, { 1, -1 }, { -1, 0 }, { 1, 0 }, { -1, 1 }, { 0, 1 }, { 1, 1 } }
local POOLS = {
	prairie = { "tree_chene", "tree_chene", "tree_sapin", "tree_sapin", "tree_bouleau", "tree_cerisier" },
	foret = { "tree_chene", "tree_bouleau", "tree_bouleau", "tree_sapin" },
	neige = { "tree_sapin", "tree_sapin", "tree_sapin", "tree_bouleau" },
	marais = { "tree_saule", "tree_saule", "tree_chene" },
	desert = nil, -- pas de bosquet au désert
}
local GAP = 5.5 -- studs mini entre deux arbres

function Bosquets.init(g)
	G = g
	Config = G.Config
end

local function nearVillage(rx: number, rz: number): boolean
	for _, d in NEAR do
		local poi = G.wg:poiOf(rx + d[1], rz + d[2])
		if poi and poi.kind == "village" then
			return true
		end
	end
	return false
end

-- ajoute les bosquets au plan de la région (une seule fois par plan)
function Bosquets.extend(plan, rx: number, rz: number): number
	if plan.bosquets ~= nil then
		return plan.bosquets
	end
	plan.bosquets = 0
	if G.wg:poiOf(rx, rz) or not nearVillage(rx, rz) then
		return 0
	end
	local pool = POOLS[plan.biome or "prairie"]
	if not pool then
		return 0
	end
	local CELL, REGION = Config.CELL, Config.REGION
	local idx = G.WG.idx
	-- grille d'occupation : objets existants, maisons
	local occ = {}
	local function key(x: number, z: number)
		return math.floor(x / GAP) .. "," .. math.floor(z / GAP)
	end
	local function near(x: number, z: number): boolean
		local cx, cz = math.floor(x / GAP), math.floor(z / GAP)
		for dz = -1, 1 do
			for dx = -1, 1 do
				for _, q in occ[(cx + dx) .. "," .. (cz + dz)] or {} do
					if (q - Vector2.new(x, z)).Magnitude < GAP then
						return true
					end
				end
			end
		end
		return false
	end
	local function mark(x: number, z: number)
		local k = key(x, z)
		occ[k] = occ[k] or {}
		table.insert(occ[k], Vector2.new(x, z))
	end
	for _, p in plan.props do
		if p.x and p.z then
			mark(p.x, p.z)
		end
	end
	for _, d in plan.decos or {} do
		if d.x and d.z then
			mark(d.x, d.z)
		end
	end
	local houses = {}
	for _, h in plan.houses or {} do
		if h.x and h.z then
			table.insert(houses, Vector2.new(h.x, h.z))
		end
	end
	local rng = Random.new(G.WG.hash(G.world.seed, "bosquets", rx, rz))
	local x0, z0 = plan.x0 * CELL, plan.z0 * CELL
	local n = 0
	for c = 1, rng:NextInteger(4, 6) do
		local cx = x0 + rng:NextNumber(20, REGION * CELL - 20)
		local cz = z0 + rng:NextNumber(20, REGION * CELL - 20)
		for t = 1, rng:NextInteger(6, 10) do
			local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, 16)
			local x, z = cx + math.cos(a) * r, cz + math.sin(a) * r
			local lx, lz = math.floor(x / CELL) - plan.x0, math.floor(z / CELL) - plan.z0
			local kind = pool[rng:NextInteger(1, #pool)]
			local scale = rng:NextNumber(0.9, 1.35)
			local yaw = rng:NextNumber(0, 360)
			if lx >= 1 and lz >= 1 and lx < REGION - 1 and lz < REGION - 1 then
				local i = idx(lx, lz)
				local okHouse = true
				for _, h in houses do
					if (h - Vector2.new(x, z)).Magnitude < 16 then
						okHouse = false
						break
					end
				end
				if okHouse and not plan.water[i] and (plan.roadD[i] or 99) > 3 and not (plan.inPoi and plan.inPoi[i]) and not near(x, z) then
					mark(x, z)
					n += 1
					table.insert(plan.props, { id = string.format("bq%d_%d_%d_%d", rx, rz, c, t), kind = kind, x = x, z = z, yaw = yaw, scale = scale })
				end
			end
		end
	end
	plan.bosquets = n
	return n
end

function Bosquets.onRegionLoad(reg)
	if Bosquets.extend(reg.plan, reg.rx, reg.rz) == 0 then
		return
	end
	-- jamais dans ce que les joueurs ont construit / posé (mondes déjà joués)
	local V = G.Villages
	if not (V and V.freeOfBuilds) then
		return
	end
	local kept = {}
	for _, p in reg.plan.props do
		if string.sub(p.id, 1, 2) ~= "bq" or V.freeOfBuilds(reg, p.x, p.z, 5) then
			table.insert(kept, p)
		end
	end
	reg.plan.props = kept
end

return Bosquets
