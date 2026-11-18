-- Herboristerie façon WoW (18/11, après les filons) : des PLANTES SAUVAGES poussent dans la nature,
-- différentes selon le biome ; les rares demandent un bon niveau d'agriculture pour être cueillies
-- (comme les filons demandent le minage). Elles repoussent au même endroit (Props.canRespawn), se
-- repèrent sur la minicarte dès agriculture 5 (tag « Herbe ») et servent aux recettes d'alchimie.
-- Ajoutées au plan AVANT Props (vrais objets « herb »), tirage et identifiants à part (« hb… ») :
-- les mondes existants gardent tout le reste.

local Herbes = {}
local G, Config

-- par biome : { objet, compétence d'agriculture requise, poids, couleur des fleurs }
local POOLS = {
	prairie = { { "chamomile", 0, 5, Color3.fromRGB(250, 245, 200) }, { "mint", 0, 4, Color3.fromRGB(120, 200, 120) }, { "thyme", 0, 3, Color3.fromRGB(200, 160, 220) },
		{ "st_john", 5, 2, Color3.fromRGB(250, 210, 40) }, { "valerian", 10, 1, Color3.fromRGB(250, 190, 210) } },
	foret = { { "sage", 0, 4, Color3.fromRGB(150, 170, 200) }, { "nettle", 0, 5, Color3.fromRGB(90, 150, 70) }, { "rosemary", 3, 3, Color3.fromRGB(160, 170, 240) },
		{ "valerian", 8, 2, Color3.fromRGB(250, 190, 210) }, { "mandrake", 18, 0.6, Color3.fromRGB(150, 90, 170) } },
	desert = { { "thyme", 0, 4, Color3.fromRGB(200, 160, 220) }, { "lavender", 2, 4, Color3.fromRGB(170, 120, 230) }, { "rosemary", 4, 2, Color3.fromRGB(160, 170, 240) } },
	neige = { { "mint", 0, 4, Color3.fromRGB(120, 200, 120) }, { "sage", 3, 3, Color3.fromRGB(150, 170, 200) }, { "ancient_root", 20, 0.5, Color3.fromRGB(170, 120, 80) } },
	marais = { { "nettle", 0, 5, Color3.fromRGB(90, 150, 70) }, { "valerian", 5, 3, Color3.fromRGB(250, 190, 210) }, { "night_flower", 15, 0.7, Color3.fromRGB(110, 120, 250) } },
}
Herbes.POOLS = POOLS

function Herbes.init(g)
	G = g
	Config = G.Config
end

local function pick(rng: Random, pool)
	local total = 0
	for _, h in pool do
		total += h[3]
	end
	local r = rng:NextNumber() * total
	for _, h in pool do
		r -= h[3]
		if r <= 0 then
			return h
		end
	end
	return pool[1]
end

-- ajoute les plantes au plan (une seule fois par plan) ; renvoie leur nombre
function Herbes.extend(plan, rx: number, rz: number): number
	if plan.herbes ~= nil then
		return plan.herbes
	end
	plan.herbes = 0
	local poi = G.wg:poiOf(rx, rz)
	if poi and poi.kind == "village" then
		return 0 -- pas dans les rues
	end
	local pool = POOLS[plan.biome or "prairie"]
	if not pool then
		return 0
	end
	local CELL, REGION = Config.CELL, Config.REGION
	local idx = G.WG.idx
	local taken = {}
	for _, p in plan.props do
		if p.x then
			table.insert(taken, Vector2.new(p.x, p.z))
		end
	end
	local function free(x: number, z: number): boolean
		local v = Vector2.new(x, z)
		for _, q in taken do
			if (q - v).Magnitude < 3 then
				return false
			end
		end
		return true
	end
	local rng = Random.new(G.WG.hash(G.world.seed, "herbes", rx, rz))
	local n = 0
	for i = 1, rng:NextInteger(3, 7) do
		local lx, lz = rng:NextInteger(2, REGION - 3), rng:NextInteger(2, REGION - 3)
		local ci = idx(lx, lz)
		local x = (plan.x0 + lx) * CELL + CELL / 2 + rng:NextNumber(-1, 1)
		local z = (plan.z0 + lz) * CELL + CELL / 2 + rng:NextNumber(-1, 1)
		local h = pick(rng, pool)
		if not plan.water[ci] and (plan.roadD[ci] or 99) > 2 and not (plan.inPoi and plan.inPoi[ci]) and free(x, z) and Config.ITEMS[h[1]] then
			table.insert(taken, Vector2.new(x, z))
			n += 1
			table.insert(plan.props, { id = string.format("hb%d_%d_%d", rx, rz, i), kind = "herb", herb = h[1], skill = h[2], color = h[4], x = x, z = z, yaw = rng:NextNumber(0, 360) })
		end
	end
	plan.herbes = n
	return n
end

function Herbes.onRegionLoad(reg)
	if Herbes.extend(reg.plan, reg.rx, reg.rz) == 0 then
		return
	end
	local V = G.Villages
	if not (V and V.freeOfBuilds) then
		return
	end
	local kept = {}
	for _, p in reg.plan.props do
		if string.sub(p.id, 1, 2) ~= "hb" or V.freeOfBuilds(reg, p.x, p.z, 3) then
			table.insert(kept, p)
		end
	end
	reg.plan.props = kept
end

return Herbes
