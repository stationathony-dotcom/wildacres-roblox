-- Plan déterministe d'une région : relief (hauteurs, matières, eau), lieu (village, ferme,
-- ruine, antre), PNJ, objets récoltables, animaux, chevaux, monstres, escaliers et ponts.
-- Ajoute WG:plan(rx, rz) au générateur et renvoie le générateur.

local WG = require(script.Parent.WorldGen)
local Config = require(script.Parent.Config)
local Dialogue = require(script.Parent.Dialogue)

local CELL, REGION = Config.CELL, Config.REGION
local M = 4 -- marge de calcul autour de la région
local W = REGION + 2 * M
local Mat = Enum.Material

local function idx(lx: number, lz: number): number
	return (lz + M) * W + (lx + M) + 1
end
WG.idx = idx
WG.MARGIN = M
WG.GRID_W = W

-- Porte des maisons (décalage en X du modèle) et demi-profondeur : pour tracer l'allée
local DOORS = { Maison_A = 3, Maison_B = -4, Maison_C = 3, Boutique = 0, Bureau_Sherif = 4, Ruine = 2 }
local HALF_DEPTH = { Maison_A = 9, Maison_B = 9, Maison_C = 9, Boutique = 9, Bureau_Sherif = 9, Ruine = 8 }

-- Poids de proximité d'un lieu pour une case (1 dedans et à 4 cases autour, 0 à 10 cases)
local function poiWeight(p, cx: number, cz: number): (number, boolean)
	local dx = math.max(p.x0 - cx, 0, cx - (p.x0 + p.w - 1))
	local dz = math.max(p.z0 - cz, 0, cz - (p.z0 + p.d - 1))
	local dr = math.max(dx, dz)
	local w = dr <= 4 and 1 or math.max(0, 1 - (dr - 4) / 6)
	return w, dr == 0
end

-- Eau à une case quelconque (sans plan) : sert aux ponts qui débordent de la région.
function WG:isWaterAt(cx: number, cz: number): boolean
	if not self:wetRaw(cx, cz) then
		return false
	end
	local rx, rz = WG.regionOf(cx, cz)
	for qx = rx - 1, rx + 1 do
		for qz = rz - 1, rz + 1 do
			local p = self:poiOf(qx, qz)
			if p and poiWeight(p, cx, cz) >= 0.5 then
				return false
			end
		end
	end
	return true
end

-- Arbres par biome (dense = forêt, sparse = arbres isolés)
local TREES = {
	prairie = { dense = { "tree_chene", "tree_chene", "tree_sapin", "tree_sapin", "tree_bouleau", "tree_chene", "tree_mort" },
		sparse = { "tree_chene", "tree_bouleau", "tree_cerisier", "tree_cerisier", "tree_sapin", "tree_mort" } },
	foret = { dense = { "tree_chene", "tree_chene", "tree_bouleau", "tree_bouleau", "tree_sapin", "tree_chene" },
		sparse = { "tree_chene", "tree_bouleau", "tree_mort" } },
	desert = { dense = { "tree_mort" }, sparse = { "tree_mort" } },
	neige = { dense = { "tree_sapin", "tree_sapin", "tree_sapin", "tree_bouleau", "tree_mort" }, sparse = { "tree_sapin", "tree_mort" } },
	marais = { dense = { "tree_saule", "tree_saule", "tree_mort", "tree_chene" }, sparse = { "tree_saule", "tree_mort" } },
}

local function shuffle(rng: Random, t)
	for i = #t, 2, -1 do
		local j = rng:NextInteger(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

-- créatures et faune par biome (partagées : lues aussi par le bestiaire, Systemes/Livres)
local BIOME_FOES = {
	prairie = { "slime", "slime_blue", "wolf", "boar", "boar" },
	foret = { "myconid", "spider", "spider", "wolf", "bear", "boar" },
	desert = { "goblin", "scorpion", "scorpion", "goblin", "slime_blue" },
	neige = { "wolf_white", "wolf_white", "ice_golem", "yeti", "slime_blue" },
	marais = { "toad", "toad", "wisp", "croc", "myconid" },
}
local BIOME_FAUNA = {
	prairie = { "rabbit", "rabbit", "deer", "fox" },
	foret = { "deer", "deer", "fox", "rabbit" },
	desert = { "camel", "rabbit" },
	neige = { "penguin", "penguin", "fox" },
	marais = { "flamingo", "flamingo", "rabbit" },
}
WG.BIOME_FOES, WG.BIOME_FAUNA = BIOME_FOES, BIOME_FAUNA

-- Pauses du calcul de plan (21/11, lot C12 : ~120 ms d'un bloc sur le PC portable = une saccade du serveur
-- à chaque région traversée). Le serveur (World.init) y met `task.wait` quand c'est possible ; sinon rien.
-- Les pauses ne changent AUCUN tirage : le plan obtenu est identique.
WG.pauseHook = nil
local function pause()
	local h = WG.pauseHook
	if h then
		h()
	end
end

function WG:plan(rx: number, rz: number)
	local pkey = rx .. "," .. rz
	local cached = self.planCache[pkey]
	if cached then
		return cached
	end
	local x0, z0 = rx * REGION, rz * REGION
	local N = W * W

	-- Lieux autour
	local pois = {}
	for qx = rx - 1, rx + 1 do
		for qz = rz - 1, rz + 1 do
			local p = self:poiOf(qx, qz)
			if p then
				table.insert(pois, p)
			end
		end
	end
	local poi = self:poiOf(rx, rz)

	pause()
	-- Distance aux routes
	local roadD = table.create(N, 99)
	local roads = self:roadsNear(rx, rz)
	local exMinX, exMaxX = x0 - M - 6, x0 + REGION + M + 6
	local exMinZ, exMaxZ = z0 - M - 6, z0 + REGION + M + 6
	for _, r in roads do
		if r.maxx + 12 >= exMinX and r.minx - 12 <= exMaxX and r.maxz + 12 >= exMinZ and r.minz - 12 <= exMaxZ then
			for _, s in r.samples do
				local sx, sz = s[1], s[2]
				if sx >= exMinX and sx <= exMaxX and sz >= exMinZ and sz <= exMaxZ then
					local bx, bz = math.floor(sx) - x0, math.floor(sz) - z0
					for dz = -6, 6 do
						local lz = bz + dz
						if lz >= -M and lz < REGION + M then
							for dx = -6, 6 do
								local lx = bx + dx
								if lx >= -M and lx < REGION + M then
									local ddx = (lx + x0 + 0.5) - sx
									local ddz = (lz + z0 + 0.5) - sz
									local d = math.sqrt(ddx * ddx + ddz * ddz)
									local i = idx(lx, lz)
									if d < roadD[i] then
										roadD[i] = d
									end
								end
							end
						end
					end
				end
			end
		end
	end

	pause()
	-- Poids des lieux, eau brute
	local poiW = table.create(N, 0)
	local inPoi = table.create(N, false)
	local water = table.create(N, false)
	for lz = -M, REGION + M - 1 do
		for lx = -M, REGION + M - 1 do
			local cx, cz = x0 + lx, z0 + lz
			local i = idx(lx, lz)
			local best = 0
			for _, p in pois do
				local w, inside = poiWeight(p, cx, cz)
				if w > best then
					best = w
				end
				if inside then
					inPoi[i] = p
				end
			end
			poiW[i] = best
			if best < 0.5 then
				water[i] = self:wetRaw(cx, cz)
			end
		end
		if lz % 14 == 0 then
			pause()
		end
	end
	pause()

	-- Distances eau / terre (jusqu'à 3 cases), sur la région + 1 case
	local distW = table.create(N, 9)
	local distL = table.create(N, 9)
	for lz = -1, REGION do
		for lx = -1, REGION do
			local i = idx(lx, lz)
			local wet = water[i]
			local found = 9
			for r = 1, 3 do
				for dz = -r, r do
					for dx = -r, r do
						if math.max(math.abs(dx), math.abs(dz)) == r then
							if water[idx(lx + dx, lz + dz)] ~= wet then
								found = r
								break
							end
						end
					end
					if found < 9 then
						break
					end
				end
				if found < 9 then
					break
				end
			end
			if wet then
				distL[i] = found
			else
				distW[i] = found
			end
		end
		if lz % 12 == 0 then
			pause()
		end
	end

	pause()
	-- Niveaux, hauteurs, matières
	local level = table.create(N, 0)
	local H = table.create(N, Config.GROUND_Y)
	local mat = table.create(N, Mat.Grass)
	local forestV = table.create(N, 0)
	local bio = table.create(N, "prairie")
	for lz = -1, REGION do
		for lx = -1, REGION do
			local cx, cz = x0 + lx, z0 + lz
			local i = idx(lx, lz)
			local b = self:biome(cx, cz)
			bio[i] = b
			local rd = roadD[i]
			local roadW = rd <= 2.5 and 1 or math.max(0, 1 - (rd - 2.5) / 3.5)
			local down = math.max(poiW[i], roadW)
			if water[i] then
				local dl = distL[i]
				H[i] = dl == 1 and -4 or (dl == 2 and -8 or -12)
				mat[i] = dl == 1 and Mat.Sand or Mat.Ground
			else
				-- relief : WG:relief (gen ≤ 2 = ancien calcul à l'identique ; gen 3 = terrasses et sommet)
				local lv, hill = self:relief(cx, cz, down)
				if distW[i] <= 2 then
					lv = 0
				end
				level[i] = lv
				local h = Config.GROUND_Y + lv * Config.LEVEL_H + hill
				local dw = distW[i]
				local f = self:forest(cx, cz)
				forestV[i] = f
				local shore = (b == "marais") and Mat.Mud or (b == "neige" and Mat.Snow or Mat.Sand)
				if dw == 1 then
					h = 1
					mat[i] = shore
				elseif dw == 2 then
					h = math.min(h, 1.6)
					mat[i] = shore
				elseif rd <= 1.6 and not inPoi[i] then
					mat[i] = (b == "desert") and Mat.Sandstone or Mat.Ground
				elseif b == "marais" then
					mat[i] = (dw <= 4 or f > WG.T_FOREST) and Mat.Mud or Mat.Grass
				else
					mat[i] = Config.BIOMES[b].mat
				end
				-- gen 3 : en altitude, neige au-dessus de 125 ; entre 80 et 125, alpage (herbe) sur les replats et
				-- roche sur les pentes (bruit de collines fort) — pas une dalle de roche uniforme
				if self.gen >= 3 and not inPoi[i] and rd > 1.6 then
					if h > 125 then
						mat[i] = Mat.Snow
					elseif h > 80 then
						local steep = math.abs(self:hills(cx, cz)) > 0.28
						mat[i] = steep and Mat.Rock or (h > 110 and Mat.Slate or Mat.Grass)
					end
				end
				H[i] = h
			end
		end
		-- relief gen 3 (terrasses, massifs, alpage) : ~40–80 ms d'un bloc sur le portable → pause par rangées
		if lz % 8 == 0 then
			pause()
		end
	end
	pause()

	local plan = {
		rx = rx, rz = rz, key = pkey, x0 = x0, z0 = z0,
		poi = (poi and poi.rx == rx and poi.rz == rz) and poi or nil,
		H = H, mat = mat, water = water, level = level, roadD = roadD, poiW = poiW, inPoi = inPoi, distW = distW, distL = distL,
		bio = bio, biome = self:regionBiome(rx, rz),
		houses = {}, npcs = {}, props = {}, decos = {}, plots = {}, animals = {}, horses = {}, enemies = {},
		stairs = {}, bridges = {}, signs = {},
	}
	plan.cliff = Config.BIOMES[plan.biome].cliff
	local biomeCrops = Config.BIOME_CROPS[plan.biome] or Config.BIOME_CROPS.prairie
	local rng = Random.new(WG.hash(self.seed, "plan", rx, rz))
	local used = {}
	local counter = 0
	local function newId(prefix: string): string
		counter += 1
		return prefix .. pkey .. "#" .. counter
	end
	local function pick(t)
		return t[rng:NextInteger(1, #t)]
	end
	local function world(cx: number, cz: number): (number, number)
		return cx * CELL + CELL / 2, cz * CELL + CELL / 2
	end
	local function setMat(cx: number, cz: number, m: Enum.Material)
		local lx, lz = cx - x0, cz - z0
		if lx >= -1 and lx <= REGION and lz >= -1 and lz <= REGION then
			mat[idx(lx, lz)] = m
		end
	end
	local function isUsed(lx, lz)
		return used[lx .. "," .. lz] == true
	end
	local function markUsed(lx, lz)
		used[lx .. "," .. lz] = true
	end
	local function flatOk(lx, lz)
		local lv = level[idx(lx, lz)]
		return level[idx(lx + 1, lz)] == lv and level[idx(lx - 1, lz)] == lv and level[idx(lx, lz + 1)] == lv and level[idx(lx, lz - 1)] == lv
	end
	-- Case libre pour le décor sauvage
	local function free(lx: number, lz: number, allowPoi: boolean?): boolean
		if lx < 1 or lz < 1 or lx > REGION - 2 or lz > REGION - 2 then
			return false
		end
		local i = idx(lx, lz)
		if water[i] or isUsed(lx, lz) or roadD[i] <= 2.6 or distW[i] <= 1 then
			return false
		end
		if not allowPoi and poiW[i] > 0.01 then
			return false
		end
		return flatOk(lx, lz)
	end
	local function randomFree(): (number?, number?)
		for _ = 1, 60 do
			local lx, lz = rng:NextInteger(1, REGION - 2), rng:NextInteger(1, REGION - 2)
			if free(lx, lz) then
				return lx, lz
			end
		end
		return nil, nil
	end
	local function addProp(kind: string, lx: number, lz: number, extra)
		local x, z = world(x0 + lx, z0 + lz)
		local p = { id = newId("p"), kind = kind, x = x + rng:NextNumber(-0.8, 0.8), z = z + rng:NextNumber(-0.8, 0.8), yaw = rng:NextNumber(0, 360), owner = nil }
		if extra then
			for k, v in extra do
				p[k] = v
			end
		end
		table.insert(plan.props, p)
		markUsed(lx, lz)
		return p
	end
	local function loot(ruin: boolean)
		local l = { gold = rng:NextInteger(5, 30) * (ruin and 2 or 1) }
		l["seed_" .. pick(biomeCrops)] = rng:NextInteger(2, 5)
		if rng:NextNumber() < (ruin and 0.5 or 0.25) then
			l[pick({ "hoe", "can", "club", "shovel", "axe", "pickaxe" })] = 1
		end
		if ruin and rng:NextNumber() < 0.15 then
			l.sword = 1
		end
		if ruin and rng:NextNumber() < 0.35 then
			l.gear = true -- un objet d'équipement tiré à l'ouverture
		end
		return l
	end

	-- PNJ ---------------------------------------------------------------
	local looksTaken = {}
	local function npcLook(id: string, role: string, forcedFemale: boolean?)
		local lr = Random.new(WG.hash(self.seed, "apparence", id))
		local female = lr:NextNumber() < 0.5
		if forcedFemale ~= nil then
			female = forcedFemale
		end
		local look
		-- tenues : celles de l'île (gen >= 2) ; en gen 1, les 8 chemises / 5 pantalons d'origine.
		-- Même ordre de tirages qu'avant : les PNJ des mondes existants ne changent pas.
		local th = self.theme
		local shirts, pants = th and th.shirts, th and th.pants
		for _ = 1, 12 do
			local hats = WG.ROLE_HATS[role] or { "" }
			if th and th.hats and (role == "villager" or role == "farmer") then
				hats = th.hats
			end
			local hairs = female and WG.HAIRS_F or WG.HAIRS_M
			local skin = lr:NextInteger(1, #WG.SKINS)
			local hair = hairs[lr:NextInteger(1, #hairs)]
			local hairColor = lr:NextInteger(1, #WG.HAIR_COLORS)
			local si = lr:NextInteger(1, shirts and #shirts or WG.SHIRTS_GEN1)
			local pi = lr:NextInteger(1, pants and #pants or WG.PANTS_GEN1)
			local hat = hats[lr:NextInteger(1, #hats)]
			look = {
				skin = skin, hair = hair, hairColor = hairColor, shirt = shirts and shirts[si] or si,
				pants = pants and pants[pi] or pi, hat = hat,
				height = lr:NextNumber(0.92, 1.08), width = lr:NextNumber(0.9, 1.15),
			}
			local sig = table.concat({ look.skin, look.hair, look.hairColor, look.shirt, look.pants, look.hat }, "/")
			if not looksTaken[sig] then
				looksTaken[sig] = true
				break
			end
		end
		look.female = female
		return look, female
	end
	local function addNpc(role: string, house, work: { number }, plazaPos: { number }, village: string?, name: string?, female: boolean?)
		local persona = role == "sheriff" and "sherif" or Dialogue.TRAIT_LIST[rng:NextInteger(1, #Dialogue.TRAIT_LIST)]
		local roll = rng:NextInteger(1, 1000)
		local id = newId("n")
		local look, fem = npcLook(id, role, female)
		if not name then
			local pool = fem and WG.NAMES_F or WG.NAMES_M
			name = pool[(roll % #pool) + 1]
		end
		local n = {
			id = id, name = name, female = fem, role = role, persona = persona, look = look,
			house = house and house.id or nil, work = work, plaza = plazaPos, village = village,
		}
		table.insert(plan.npcs, n)
		if house then
			house.owner = id
		end
		return n
	end
	local function addHouse(model: string, kind: string, lx: number, lz: number, yaw: number, village: string?)
		local o = plan.poi
		local x, z = (o.x0 + lx) * CELL + CELL / 2, (o.z0 + lz) * CELL + CELL / 2
		local h = { id = newId("h"), model = model, kind = kind, x = x, z = z, yaw = yaw, village = village }
		table.insert(plan.houses, h)
		-- allée de terre devant la porte
		local r = math.rad(yaw)
		local fx, fz = math.sin(r), math.cos(r) -- avant du modèle (+Z) tourné
		local rx_, rz_ = math.cos(r), -math.sin(r) -- axe X du modèle tourné
		local door = DOORS[model] or 0
		local hd = HALF_DEPTH[model] or 9
		h.doorX = x + rx_ * door + fx * (hd + 3)
		h.doorZ = z + rz_ * door + fz * (hd + 3)
		for s = hd + 1, hd + 9, 2 do
			local px, pz = x + rx_ * door + fx * s, z + rz_ * door + fz * s
			setMat(math.floor(px / CELL), math.floor(pz / CELL), Mat.Ground)
		end
		return h
	end
	local function addDeco(model: string, x: number, z: number, yaw: number, extra)
		local d = { model = model, x = x, z = z, yaw = yaw }
		if extra then
			for k, v in extra do
				d[k] = v
			end
		end
		table.insert(plan.decos, d)
		return d
	end
	local function fenceRect(xa: number, za: number, xb: number, zb: number, gapSide: string)
		-- segments de 4 studs le long du périmètre ; une ouverture au milieu du côté gapSide
		local nx = math.floor((xb - xa) / 4 + 0.5)
		local nz = math.floor((zb - za) / 4 + 0.5)
		for i = 0, nx - 1 do
			local x = xa + 2 + i * 4
			if not (gapSide == "north" and i == math.floor(nx / 2)) then
				addDeco("Cloture", x, za, 0)
			end
			if not (gapSide == "south" and i == math.floor(nx / 2)) then
				addDeco("Cloture", x, zb, 0)
			end
		end
		for i = 0, nz - 1 do
			local z = za + 2 + i * 4
			addDeco("Cloture", xa, z, 90)
			addDeco("Cloture", xb, z, 90)
		end
	end

	pause()
	-- Lieu de la région -------------------------------------------------
	local o = plan.poi
	if o then
		local ox, oz = o.x0, o.z0
		local function W2(lx, lz)
			return (ox + lx) * CELL + CELL / 2, (oz + lz) * CELL + CELL / 2
		end
		for lz = 0, o.d - 1 do
			for lx = 0, o.w - 1 do
				markUsed(ox + lx - x0, oz + lz - z0)
			end
		end
		if o.kind == "village" then
			local vid = pkey
			plan.villageName = o.name
			for lz = 0, o.d - 1 do
				for lx = 0, o.w - 1 do
					local street = (lz >= 10 and lz <= 12) or (lx >= 12 and lx <= 14 and lz >= 12)
					local plaza = lx >= 8 and lx <= 18 and lz >= 8 and lz <= 14
					if plaza then
						setMat(ox + lx, oz + lz, Mat.Cobblestone)
					elseif street then
						setMat(ox + lx, oz + lz, Mat.Ground)
					end
				end
			end
			local px, pz = W2(13, 11)
			local plazaPos = { px, pz }
			local homes = {
				addHouse(pick({ "Maison_A", "Maison_B", "Maison_C" }), "home", 5, 5, 0, vid),
				addHouse(pick({ "Maison_A", "Maison_B", "Maison_C" }), "home", 21, 5, 0, vid),
				addHouse(pick({ "Maison_A", "Maison_B", "Maison_C" }), "home", 5, 17, 180, vid),
			}
			local shop = addHouse("Boutique", "shop", 13, 4.5, 0, vid)
			local office = addHouse("Bureau_Sherif", "sheriff", 21, 17, 180, vid)
			addDeco("Fontaine", px, pz, 0)
			for _, c in { { 9, 8.5 }, { 17, 8.5 }, { 9, 13.5 }, { 17, 13.5 } } do
				local x, z = W2(c[1], c[2])
				addDeco("Lampadaire", x, z, c[2] < 11 and 0 or 180)
			end
			local sx, sz = W2(0.5, 9)
			addDeco("Panneau", sx, sz, 90, { text = o.name })
			local ex, ez = W2(25, 13.5)
			addDeco("Panneau", ex, ez, -90, { text = o.name })
			local bx, bz = W2(17.5, 6)
			addDeco("Tonneaux", bx, bz, 20)
			local cx_, cz_ = W2(9, 6.5)
			addDeco("Caisses", cx_, cz_, -10)
			local wx, wz = W2(9.5, 18)
			addDeco("Puits", wx, wz, 0)
			for i = 1, 3 do
				local wpx, wpz = W2(13 + rng:NextInteger(-4, 4), 11 + rng:NextInteger(-2, 2))
				addNpc("villager", homes[i], { wpx, wpz }, plazaPos, vid)
			end
			addNpc("sheriff", office, plazaPos, plazaPos, vid)
			addNpc("merchant", shop, "house", plazaPos, vid)
			-- un 2e habitant parfois dans une maison (couple), sans lit propre : dort sur place
			if rng:NextNumber() < 0.5 then
				local wpx, wpz = W2(13 + rng:NextInteger(-4, 4), 11 + rng:NextInteger(-2, 2))
				local extra = addNpc("villager", nil, { wpx, wpz }, plazaPos, vid)
				extra.house = homes[rng:NextInteger(1, 3)].id
			end
			table.insert(plan.signs, { kind = "village", name = o.name, x = px, z = pz })
		elseif o.kind == "farm" then
			local house = addHouse(pick({ "Maison_A", "Maison_C" }), "home", 5, 4, 0, nil)
			-- champ
			local fxa, fza = (ox + 2) * CELL, (oz + 8) * CELL
			local fxb, fzb = (ox + 10) * CELL, (oz + 12) * CELL
			local crop = pick(biomeCrops)
			local fcx, fcz = (fxa + fxb) / 2, (fza + fzb) / 2
			local farmer = addNpc("farmer", house, { fcx, fcz }, { house.doorX, house.doorZ }, nil, o.name, o.female)
			for lz = 8, 11 do
				for lx = 2, 9 do
					local x, z = W2(lx, lz)
					setMat(ox + lx, oz + lz, Mat.Ground)
					table.insert(plan.plots, { id = newId("c"), x = x, z = z, crop = crop, stage = rng:NextInteger(1, Config.CROPS[crop].days), owner = farmer.id })
				end
			end
			fenceRect(fxa - 1, fza - 1, fxb + 1, fzb + 1, "north")
			-- enclos des bêtes
			local pxa, pza = (ox + 12) * CELL, (oz + 8) * CELL
			local pxb, pzb = (ox + 17) * CELL, (oz + 14) * CELL
			fenceRect(pxa, pza, pxb, pzb, "north")
			local beast = pick({ "chicken", "chicken", "cow", "sheep" })
			for i = 1, rng:NextInteger(2, 3) do
				table.insert(plan.animals, { id = newId("a"), kind = beast, x = pxa + 4 + i * 4, z = pza + 10, owner = farmer.id,
					pen = { pxa + 2, pza + 2, pxb - 2, pzb - 2 } })
			end
			local sx, sz = W2(6, 13)
			addDeco("Epouvantail", sx, sz, 0)
			local hx, hz = W2(12, 4)
			addDeco("Botte_Foin", hx, hz, 15)
			addDeco("Botte_Foin", hx + 1, hz + 3.2, -10)
			local mx, mz = W2(9.5, 7)
			addDeco("Boite_Lettres", mx, mz, 0)
			local nx, nz = W2(1, 7.5)
			addDeco("Panneau", nx, nz, 90, { text = "Ferme de " .. o.name })
			local kx, kz = W2(10, 3)
			table.insert(plan.props, { id = newId("p"), kind = "chest", x = kx, z = kz, yaw = 0, owner = farmer.id, loot = loot(false) })
			local hx2, hz2 = W2(15, 4)
			local hr = Random.new(WG.hash(self.seed, "cheval", pkey))
			table.insert(plan.horses, { id = newId("ch"), x = hx2, z = hz2, owner = farmer.id, coat = hr:NextInteger(1, #Config.HORSE_COATS), saddle = hr:NextInteger(1, #Config.SADDLES) })
		elseif o.kind == "ruin" then
			local ruin = addHouse("Ruine", "ruin", 6, 5, 0, nil)
			local l = loot(true)
			if o.start then
				l.seed_parsnip = (l.seed_parsnip or 0) + 4
				plan.startRuin = ruin
				local fx_, fz_ = W2(9, 9.5)
				addDeco("Feu_Camp", fx_, fz_, 0, { unlit = true })
			end
			ruin.chest = { id = newId("p"), kind = "chest", owner = nil, loot = l, spot = "CoffreSpot" }
		else -- antre
			local cx, cz = W2(7, 6)
			table.insert(plan.enemies, { id = newId("e"), kind = o.boss, x = cx, z = cz, boss = true })
			for _ = 1, 3 do
				table.insert(plan.enemies, { id = newId("e"), kind = o.minion, x = cx + rng:NextNumber(-12, 12), z = cz + rng:NextNumber(-10, 10) })
			end
			for i = 0, 7 do
				local a = i / 8 * math.pi * 2
				table.insert(plan.props, { id = newId("p"), kind = "rock", x = cx + math.cos(a) * 22, z = cz + math.sin(a) * 18, yaw = rng:NextNumber(0, 360) })
			end
			for lz = 0, o.d - 1 do
				for lx = 0, o.w - 1 do
					if rng:NextNumber() < 0.6 then
						setMat(ox + lx, oz + lz, Mat.Ground)
					end
				end
			end
			local sx, sz = W2(-1, 6)
			addDeco("Panneau", sx, sz, 90, { text = "⚠ Antre du " .. o.name })
		end
	end

	pause()
	-- Escaliers sur les falaises (jusqu'à 3 par région) --------------------
	do
		local cands = {}
		local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
		for lz = 4, REGION - 5 do
			for lx = 4, REGION - 5 do
				local i = idx(lx, lz)
				if not water[i] and roadD[i] > 3 then
					local L = level[i]
					for _, d in dirs do
						local ux, uz = lx + d[1], lz + d[2]
						if level[idx(ux, uz)] == L + 1 and level[idx(ux + d[1], uz + d[2])] == L + 1 then
							local ok = true
							local px, pz = d[2], d[1] -- perpendiculaire
							for s = 0, 3 do
								for q = -1, 1 do
									local ax, az = lx - d[1] * s + px * q, lz - d[2] * s + pz * q
									local j = idx(ax, az)
									if water[j] or level[j] ~= L or isUsed(ax, az) then
										ok = false
									end
								end
							end
							for q = -1, 1 do
								if level[idx(ux + px * q, uz + pz * q)] ~= L + 1 then
									ok = false
								end
							end
							if ok then
								table.insert(cands, { lx, lz, d[1], d[2] })
							end
						end
					end
				end
			end
		end
		shuffle(rng, cands)
		local placed = {}
		for _, c in cands do
			if #placed >= 3 then
				break
			end
			local far = true
			for _, p in placed do
				if math.abs(p[1] - c[1]) + math.abs(p[2] - c[2]) < 14 then
					far = false
				end
			end
			if far then
				table.insert(placed, c)
				local lx, lz, dx, dz = c[1], c[2], c[3], c[4]
				local cx, cz = world(x0 + lx, z0 + lz)
				local ylow = H[idx(lx, lz)]
				local yhigh = math.max(H[idx(lx + dx, lz + dz)], H[idx(lx + 2 * dx, lz + 2 * dz)])
				table.insert(plan.stairs, { x = cx + dx * CELL / 2, z = cz + dz * CELL / 2, dx = dx, dz = dz, ylow = ylow, yhigh = yhigh })
				for s = 0, 3 do
					for q = -1, 1 do
						markUsed(lx - dx * s + dz * q, lz - dz * s + dx * q)
					end
				end
			end
		end
	end

	-- Ponts : parcours d'eau des routes dont le milieu tombe dans la région --
	for _, r in roads do
		local samples = r.samples
		local i = 1
		while i <= #samples do
			local s = samples[i]
			if self:isWaterAt(math.floor(s[1]), math.floor(s[2])) then
				local j = i
				while j < #samples and self:isWaterAt(math.floor(samples[j + 1][1]), math.floor(samples[j + 1][2])) do
					j += 1
				end
				local a = samples[math.max(1, i - 2)]
				local b = samples[math.min(#samples, j + 2)]
				local mx, mz = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
				if math.floor(mx / REGION) == rx and math.floor(mz / REGION) == rz then
					table.insert(plan.bridges, { id = r.key .. "@" .. i, ax = a[1] * CELL, az = a[2] * CELL, bx = b[1] * CELL, bz = b[2] * CELL })
				end
				i = j + 1
			else
				i += 1
			end
		end
	end

	pause()
	-- Nature sauvage ------------------------------------------------------
	local dist = math.sqrt(rx * rx + rz * rz)
	-- cultures sauvages mûres (libres)
	for _ = 1, rng:NextInteger(1, 3) do
		local lx, lz = randomFree()
		if lx then
			local crop = pick(biomeCrops)
			for _ = 1, rng:NextInteger(2, 4) do
				local ax, az = lx + rng:NextInteger(-2, 2), lz + rng:NextInteger(-2, 2)
				if free(ax, az) then
					markUsed(ax, az)
					local x, z = world(x0 + ax, z0 + az)
					table.insert(plan.plots, { id = newId("c"), x = x, z = z, crop = crop, stage = Config.CROPS[crop].days, owner = "wild" })
				end
			end
		end
	end
	if rng:NextNumber() < 0.3 then
		local lx, lz = randomFree()
		if lx then
			markUsed(lx, lz)
			local x, z = world(x0 + lx, z0 + lz)
			table.insert(plan.horses, { id = newId("ch"), x = x, z = z, owner = nil, coat = rng:NextInteger(1, #Config.HORSE_COATS), saddle = 0 })
		end
	end
	local B = plan.biome
	local counts = { bush = 10, stick = 14, stone = 10, rock = 7, log = 4, tuft = 18, cactus = 0 }
	if B == "desert" then
		counts = { bush = 2, stick = 6, stone = 16, rock = 12, log = 1, tuft = 6, cactus = 14 }
	elseif B == "neige" then
		counts = { bush = 5, stick = 12, stone = 12, rock = 10, log = 6, tuft = 6, cactus = 0 }
	elseif B == "marais" then
		counts = { bush = 8, stick = 16, stone = 4, rock = 3, log = 8, tuft = 24, cactus = 0 }
	end
	for _, kind in { "bush", "stick", "stone", "rock", "log", "tuft", "cactus" } do
		local n = counts[kind]
		for _ = 1, rng:NextInteger(math.floor(n / 2), n) do
			local lx, lz = randomFree()
			if lx then
				addProp(kind, lx, lz)
			end
		end
	end
	-- filons et argile selon le biome (on échange ce qu'on n'a pas chez soi)
	-- (listes ordonnées : l'ordre des tirages doit rester identique d'un démarrage à l'autre)
	local DEPOSITS = {
		prairie = { { "ore_coal", 2 }, { "ore_copper", 1 } },
		foret = { { "ore_coal", 3 }, { "ore_copper", 1 } },
		desert = { { "ore_copper", 4 }, { "ore_gold", 1 }, { "ore_coal", 1 } },
		neige = { { "ore_iron", 3 }, { "ore_coal", 2 } },
		marais = { { "clay", 5 }, { "ore_coal", 1 } },
	}
	for _, dep in DEPOSITS[B] or {} do
		local kind, n = dep[1], dep[2]
		local extra = (dist >= 4 and kind ~= "clay") and 1 or 0 -- plus riche loin du départ
		for _ = 1, rng:NextInteger(math.max(0, n - 1), n + extra) do
			local lx, lz = randomFree()
			if lx then
				addProp(kind, lx, lz)
			end
		end
	end
	-- créatures : monstres selon le biome (plus coriaces loin du départ), meutes de loups
	local PACK = { wolf = true, wolf_white = true }
	if dist >= 1 then
		local pool = dist < 2 and { "slime", "boar" } or (dist < 3 and { "slime", "slime_blue", "boar", "wolf" } or BIOME_FOES[B])
		for _ = 1, rng:NextInteger(1, dist >= 4 and 4 or 3) do
			local lx, lz = randomFree()
			if lx then
				local kind = pick(pool)
				if kind == "yeti" and rng:NextNumber() < 0.6 then
					kind = "wolf_white" -- le yéti reste rare
				end
				local n = PACK[kind] and rng:NextInteger(2, 3) or 1
				local x, z = world(x0 + lx, z0 + lz)
				for k = 1, n do
					table.insert(plan.enemies, { id = newId("e"), kind = kind, x = x + (k - 1) * 3, z = z + (k - 1) * 2 })
				end
			end
		end
	end
	-- faune sauvage (se chasse : viande, cuir, fourrure, plumes)
	local HERD = { deer = { 2, 4 }, penguin = { 3, 5 }, flamingo = { 3, 5 }, camel = { 1, 3 } }
	for _ = 1, rng:NextInteger(2, 4) do
		local lx, lz = randomFree()
		if lx then
			local x, z = world(x0 + lx, z0 + lz)
			local kind = pick(BIOME_FAUNA[B] or BIOME_FAUNA.prairie)
			local h = HERD[kind]
			for k = 1, h and rng:NextInteger(h[1], h[2]) or 1 do
				table.insert(plan.enemies, { id = newId("e"), kind = kind, x = x + (k - 1) * 3, z = z + ((k % 2) * 2) })
			end
		end
	end
	-- parterres de fleurs
	for _ = 1, (B == "prairie" and 10 or (B == "desert" and 1 or 4)) do
		local lx, lz = randomFree()
		if lx then
			local color = rng:NextInteger(1, 5)
			for _ = 1, rng:NextInteger(3, 6) do
				local ax, az = lx + rng:NextInteger(-2, 2), lz + rng:NextInteger(-2, 2)
				if free(ax, az) then
					addProp("flower", ax, az, { variant = color })
				end
			end
		end
	end
	-- forêt : un arbre possible par bloc de 2x2 cases
	for bz = 0, REGION - 2, 2 do
		for bx = 0, REGION - 2, 2 do
			local lx, lz = bx + rng:NextInteger(0, 1), bz + rng:NextInteger(0, 1)
			local roll = rng:NextNumber()
			if free(lx, lz) then
				local f = forestV[idx(lx, lz)]
				local cb = bio[idx(lx, lz)]
				local dense = f > (cb == "foret" and WG.T_FOREST - 0.12 or WG.T_FOREST)
				local sparse = (cb == "desert") and 0.004 or 0.035
				if roll < (dense and (cb == "desert" and 0.03 or 0.42) or sparse) then
					local pool = TREES[cb] or TREES.prairie
					pool = dense and pool.dense or pool.sparse
					local kind = pick(pool)
					if not dense and rng:NextNumber() < 0.12 then
						kind = "stump"
					end
					addProp(kind, lx, lz, { scale = rng:NextNumber(0.85, 1.2) })
				elseif dense and roll < 0.5 then
					addProp("mushroom", lx, lz)
				end
			end
		end
	end
	-- décor de l'eau : nénuphars au large, roseaux le long des berges
	for lz = 1, REGION - 2 do
		for lx = 1, REGION - 2 do
			local i = idx(lx, lz)
			if water[i] and roadD[i] > 3 then
				local roll = rng:NextNumber()
				local x, z = world(x0 + lx, z0 + lz)
				if distL[i] == 1 and roll < 0.12 then
					addDeco("Roseaux", x + rng:NextNumber(-1, 1), z + rng:NextNumber(-1, 1), rng:NextNumber(0, 360), { water = true })
				elseif distL[i] >= 2 and roll < 0.035 then
					addDeco("Nenuphar", x, z, rng:NextNumber(0, 360), { water = true })
				end
			end
		end
	end

	self.planCache[pkey] = plan
	table.insert(self.planOrder, pkey)
	if #self.planOrder > 60 then
		local old = table.remove(self.planOrder, 1)
		self.planCache[old] = nil
	end
	return plan
end

return WG
