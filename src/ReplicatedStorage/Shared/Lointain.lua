-- Lointain (chantier B, 25/11, docs/DIRECTION-ARTISTIQUE.md) : ce qu'on voit au-delà des régions chargées.
-- 1. Le reste de l'île en blocs « voxel » allégés, tirés des MÊMES bruits que RegionPlan (plateaux,
--    collines, biomes, forêts, lacs), pour que l'horizon ne soit plus un bord vide.
-- 2. Une couronne de massifs au large, au-delà des îlots, qui ferme l'horizon (repères visibles de loin).
-- Purement visuel : rien n'est ajouté au tirage du monde (aucun appel aux Random de RegionPlan), les
-- massifs ont leur propre graine. Fonctions pures : le client dessine, le banc `lointain` vérifie.

local Config = require(script.Parent.Config)

local L = {}
local CELL, REGION = Config.CELL, Config.REGION
local SPAN = CELL * REGION

-- anneaux de détail : près = blocs de 32 studs, loin = blocs de 80 studs
L.NEAR_STEP, L.NEAR_RADIUS = 32, 900
L.FAR_STEP, L.FAR_RADIUS = 80, 2400
L.SEA_Y = Config.WATER_Y - 0.35
L.SINK = 0.6 -- le lointain reste un peu sous le vrai terrain aux raccords
L.ISLAND = Config.WORLD_RADIUS * SPAN -- rayon de l'île en studs

L.COLORS = {
	prairie = Color3.fromRGB(104, 168, 70),
	foret = Color3.fromRGB(112, 132, 60),
	desert = Color3.fromRGB(220, 194, 138),
	neige = Color3.fromRGB(232, 238, 246),
	marais = Color3.fromRGB(92, 102, 62),
	sable = Color3.fromRGB(214, 196, 150),
	falaise = Color3.fromRGB(120, 112, 104),
	mer = Color3.fromRGB(46, 110, 150),
	lac = Color3.fromRGB(56, 124, 158),
}
-- frondaisons vues de loin : couleur des feuilles du biome (forêt rousse, sapins enneigés…)
L.CANOPY = {
	prairie = Color3.fromRGB(70, 128, 52),
	foret = Color3.fromRGB(196, 112, 44),
	desert = Color3.fromRGB(150, 150, 80),
	neige = Color3.fromRGB(64, 98, 76),
	marais = Color3.fromRGB(78, 100, 52),
}
-- nuancier des bouquets vus de loin (même esprit que Clock.CANOPY) : clé = couleur de base ci-dessus
-- 26/11 (C16) : mêmes teintes que les vrais arbres (Clock.CANOPY), pour que le loin prolonge le près
L.CANOPY_SHADES = {
	prairie = { Color3.fromRGB(86, 150, 58), Color3.fromRGB(112, 172, 64), Color3.fromRGB(64, 124, 50), Color3.fromRGB(150, 178, 66), Color3.fromRGB(96, 160, 86) },
	foret = { Color3.fromRGB(214, 120, 40), Color3.fromRGB(196, 70, 40), Color3.fromRGB(226, 170, 60), Color3.fromRGB(180, 90, 50), Color3.fromRGB(232, 196, 72), Color3.fromRGB(104, 140, 58) },
	desert = { Color3.fromRGB(150, 146, 78), Color3.fromRGB(170, 152, 86), Color3.fromRGB(130, 138, 72) },
	neige = { Color3.fromRGB(64, 98, 76), Color3.fromRGB(150, 178, 172), Color3.fromRGB(52, 84, 66) },
	marais = { Color3.fromRGB(70, 104, 52), Color3.fromRGB(90, 114, 48), Color3.fromRGB(58, 92, 60), Color3.fromRGB(104, 120, 66) },
}
-- part de conifères parmi les arbres vus de loin
L.CONIFERS = { prairie = 0.1, foret = 0.45, desert = 0, neige = 0.85, marais = 0.15 }
L.MATERIALS = {
	prairie = Enum.Material.Grass, foret = Enum.Material.LeafyGrass, desert = Enum.Material.Sand,
	neige = Enum.Material.Snow, marais = Enum.Material.Mud,
}

-- Échantillon d'une position monde (studs) : { kind = "mer" | "lac" | "terre", h, biome, forest, coast }
function L.sample(wg, x: number, z: number)
	local cx, cz = x / CELL, z / CELL
	local _, hum = wg:climate(cx, cz)
	local c = wg:continent(cx, cz)
	local lakeT = wg.T_LAKE + hum * 0.6
	if c < lakeT then
		local d = math.sqrt(x * x + z * z)
		return { kind = d > L.ISLAND * 0.78 and "mer" or "lac", h = L.SEA_Y }
	end
	local b = wg:biome(cx, cz)
	local coast = c < lakeT + 0.035
	local lv = 0
	local pe = wg:plateau(cx, cz)
	if not coast then
		lv = pe > wg.T_PLATEAU2 and 2 or (pe > wg.T_PLATEAU1 and 1 or 0)
	end
	local hill = math.max(0, wg:hills(cx, cz)) * 7
	local h = coast and 1.2 or (Config.GROUND_Y + lv * Config.LEVEL_H + hill)
	local forest = not coast and b ~= "desert" and wg:forest(cx, cz) > wg.T_FOREST
	return { kind = "terre", h = h, biome = b, forest = forest, coast = coast, level = lv }
end

-- Régions (rx, rz) qu'on ne dessine pas : celles qui sont chargées pour de vrai
local function regionKey(x: number, z: number): string
	return math.floor(x / SPAN) .. "," .. math.floor(z / SPAN)
end
L.regionKey = regionKey

-- Blocs à dessiner autour de (px, pz) ; skip[regionKey] = true pour les régions réelles.
-- Rend une liste de rangées fusionnées : { x0, x1, z, step, top, color, material, canopy? }.
-- Les cases voisines de même hauteur (au demi-stud) et de même couleur sur une ligne sont fusionnées.
function L.layout(wg, px: number, pz: number, skip, opts)
	opts = opts or {}
	local near, nearR = opts.nearStep or L.NEAR_STEP, opts.nearRadius or L.NEAR_RADIUS
	local far, farR = opts.farStep or L.FAR_STEP, opts.farRadius or L.FAR_RADIUS
	local rows = {}
	local function emit(step, gx0, gz, cells)
		-- cells : liste ordonnée en x de { s = sample, x = centre }
		local run
		local prevWater = false
		local function flush(nextWater: boolean?)
			if run then
				run.edgeR = nextWater == true
				table.insert(rows, run)
				run = nil
			end
		end
		for _, cell in cells do
			local s = cell.s
			if not s then
				flush(false)
				prevWater = false
				continue
			end
			local isWater = s.kind ~= "terre"
			local color, mat, top
			if s.kind ~= "terre" then
				color, mat, top = L.COLORS[s.kind], Enum.Material.SmoothPlastic, L.SEA_Y
			else
				color = s.coast and L.COLORS.sable or L.COLORS[s.biome]
				mat = s.coast and Enum.Material.Sand or L.MATERIALS[s.biome]
				top = math.floor((s.h - L.SINK) * 2 + 0.5) / 2
			end
			local canopy = s.kind == "terre" and s.forest and L.CANOPY[s.biome] or nil
			local shades = canopy and L.CANOPY_SHADES[s.biome] or nil
			local same = run and run.top == top and run.color == color and run.canopy == canopy
				and math.abs(run.x1 - (cell.x - step / 2)) < 0.01
			if same then
				run.x1 = cell.x + step / 2
			else
				flush(isWater)
				run = { x0 = cell.x - step / 2, x1 = cell.x + step / 2, z = gz, step = step, top = top, color = color, material = mat,
					canopy = canopy, shades = shades, water = s.kind ~= "terre", edgeL = prevWater,
					conifers = canopy and L.CONIFERS[s.biome] or nil }
			end
			prevWater = isWater
		end
		flush(false)
	end
	local function ring(step, rIn, rOut)
		-- grille alignée sur le pas (stable quand le joueur bouge)
		local gx0 = math.floor((px - rOut) / step) * step
		local gz0 = math.floor((pz - rOut) / step) * step
		local n = math.ceil(2 * rOut / step) + 1
		for j = 0, n do
			local z = gz0 + j * step + step / 2
			local cells = {}
			for i = 0, n do
				local x = gx0 + i * step + step / 2
				local dx, dz = math.abs(x - px), math.abs(z - pz)
				local inside = math.max(dx, dz)
				local s
				if inside <= rOut and (rIn == nil or inside > rIn) and not skip[regionKey(x, z)] then
					s = L.sample(wg, x, z)
				end
				table.insert(cells, { s = s, x = x })
			end
			emit(step, gx0, z, cells)
		end
	end
	ring(near, nil, nearR)
	ring(far, nearR, farR)
	return rows
end

-- Couronne de massifs au large (graine propre) : { x, z, base, height, tiers, snow, yaw }
function L.massifs(seed: number, hashFn)
	local rng = Random.new(hashFn(seed, "massifs"))
	local out = {}
	local n = 16
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2 + rng:NextNumber(-0.12, 0.12)
		local height = rng:NextNumber(650, 1200)
		local base = height * rng:NextNumber(1.5, 2.0)
		-- le pied du massif reste au large : au-delà de l'île et des îlots (≈ 1,04 rayon)
		local d = L.ISLAND * 1.1 + base * 0.5 + rng:NextNumber(120, 600)
		table.insert(out, {
			x = math.cos(a) * d, z = math.sin(a) * d,
			base = base, height = height,
			tiers = rng:NextInteger(7, 9), snow = height > 850, yaw = rng:NextNumber(0, math.pi * 2),
			falls = rng:NextNumber() < 0.35,
		})
	end
	return out
end

-- Gradins d'un massif : { size, cf, color, material } (empilés, de plus en plus étroits)
L.ROCK = Color3.fromRGB(88, 82, 78)
L.ROCK_DARK = Color3.fromRGB(62, 58, 56)
L.SNOW = Color3.fromRGB(240, 244, 250)
L.GRASS_FOOT = Color3.fromRGB(58, 104, 46)
function L.massifBlocks(m)
	local blocks = {}
	local y = L.SEA_Y - 20
	local tierH = (m.height + 20) / m.tiers
	for t = 1, m.tiers do
		local k = 1 - (t - 1) / m.tiers
		local w = m.base * (0.12 + 0.88 * k)
		local d = w * (0.75 + 0.2 * math.sin(t * 1.7 + m.yaw))
		local off = (t % 2 == 0 and 1 or -1) * w * 0.06
		local top = t == m.tiers
		local color = t == 1 and L.GRASS_FOOT or ((m.snow and t >= m.tiers - 1) and L.SNOW or (t % 2 == 0 and L.ROCK or L.ROCK_DARK))
		local mat = color == L.SNOW and Enum.Material.Snow or (t == 1 and Enum.Material.Grass or Enum.Material.Slate)
		local cf = CFrame.new(m.x + off, y + tierH / 2, m.z - off) * CFrame.Angles(0, m.yaw + t * 0.35, 0)
		table.insert(blocks, { size = Vector3.new(w, tierH, d), cf = cf, color = color, material = mat })
		if top then
			table.insert(blocks, { size = Vector3.new(w * 0.45, tierH * 0.8, d * 0.45), cf = cf * CFrame.new(0, tierH * 0.9, 0), color = color, material = mat })
		end
		y += tierH
	end
	if m.falls then
		-- cascade : un rideau clair sur la face tournée vers l'île
		local toIsland = Vector3.new(-m.x, 0, -m.z).Unit
		local face = Vector3.new(m.x, 0, m.z) + toIsland * m.base * 0.42
		local h = m.height * 0.55
		table.insert(blocks, { size = Vector3.new(70, h, 10), cf = CFrame.lookAt(Vector3.new(face.X, L.SEA_Y + h / 2, face.Z), Vector3.new(face.X, L.SEA_Y + h / 2, face.Z) + toIsland),
			color = Color3.fromRGB(210, 236, 255), material = Enum.Material.Glass, transparency = 0.25, falls = true })
	end
	return blocks
end

return L
