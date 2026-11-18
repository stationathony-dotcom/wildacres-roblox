-- Châteaux sur les hauteurs (image cible du 18/11 : le château sur sa colline, vu du village).
-- Le village de départ et 3 villages sur 5 environ ont un château dans une région voisine SANS lieu : posé sur le
-- point le plus haut d'un terrain assez plat, loin des routes et de l'eau, porte tournée vers le
-- village. On le visite (cour ouverte) ; depuis le 18/11 un seigneur y tient audience et deux gardes
-- veillent à la porte (Metiers).
-- Posé par-dessus la génération, avec son propre tirage (les mondes existants ne bougent pas) ;
-- la décision est gardée dans l'état de la région (reg.state.chateau) : une fois posé il reste, et
-- il ne se pose jamais sur ce que les joueurs ont construit. Doit passer AVANT Props : il retire
-- du plan les arbres / rochers qui seraient dans ses murs.

local Chateaux = {}
local G, Config

local HALF = 7 -- demi-côté de l'emprise, en cases (≈ 56 studs de côté)
local NEAR = { { -1, -1 }, { 0, -1 }, { 1, -1 }, { -1, 0 }, { 1, 0 }, { -1, 1 }, { 0, 1 }, { 1, 1 } }

function Chateaux.init(g)
	G = g
	Config = G.Config
end

-- région choisie par le village (vx, vz), ou nil : la voisine libre au plus petit tirage
local function choiceOf(vx: number, vz: number)
	local wg = G.wg
	local seed = G.world.seed
	local start = vx == 1 and vz == 0 -- le village de départ a toujours le sien (vu dès l'arrivée)
	if not start and Random.new(G.WG.hash(seed, "chateau", vx, vz)):NextNumber() > 0.6 then
		return nil
	end
	local best, bestR = nil, math.huge
	for _, d in NEAR do
		local rx, rz = vx + d[1], vz + d[2]
		local dist = math.sqrt(rx * rx + rz * rz)
		if G.WG.inWorld(rx, rz) and dist < Config.WORLD_RADIUS * 0.8 - 1 and not wg:poiOf(rx, rz) and not (rx == 0 and rz == 0) then
			local r = Random.new(G.WG.hash(seed, "chateau-r", vx, vz, rx, rz)):NextNumber()
			if r < bestR then
				best, bestR = { rx, rz }, r
			end
		end
	end
	return best
end

-- village voisin qui a choisi cette région (ou nil)
local function villageFor(rx: number, rz: number)
	local wg = G.wg
	if wg:poiOf(rx, rz) then
		return nil
	end
	for _, d in NEAR do
		local vx, vz = rx + d[1], rz + d[2]
		local poi = wg:poiOf(vx, vz)
		if poi and poi.kind == "village" then
			local c = choiceOf(vx, vz)
			if c and c[1] == rx and c[2] == rz then
				return poi, vx, vz
			end
		end
	end
	return nil
end

-- meilleur emplacement dans la région : le plus haut, plat, sec, loin des routes
local function site(plan)
	local idx = G.WG.idx
	local REGION = Config.REGION
	local best, bestH = nil, -math.huge
	for cz = HALF + 3, REGION - HALF - 4, 3 do
		for cx = HALF + 3, REGION - HALF - 4, 3 do
			local ok, lo, hi, sum, n = true, math.huge, -math.huge, 0, 0
			for dz = -HALF, HALF, 2 do
				for dx = -HALF, HALF, 2 do
					local i = idx(cx + dx, cz + dz)
					if plan.water[i] or (plan.roadD[i] or 99) <= 4 or (plan.inPoi and plan.inPoi[i]) then
						ok = false
						break
					end
					local h = plan.H[i]
					lo, hi, sum, n = math.min(lo, h), math.max(hi, h), sum + h, n + 1
				end
				if not ok then
					break
				end
			end
			if ok and hi - lo <= 14 then
				local mean = sum / n
				if mean > bestH then
					best, bestH = { cx = cx, cz = cz, top = hi }, mean
				end
			end
		end
	end
	return best
end

function Chateaux.onRegionLoad(reg)
	local st = reg.state
	if st.chateau == false then
		return
	end
	local plan = reg.plan
	local CELL = Config.CELL
	local spot = st.chateau
	local village, vx, vz = villageFor(reg.rx, reg.rz)
	if not spot then
		if not village then
			return -- pas de décision enregistrée : rien à retenir, le tirage est le même à chaque fois
		end
		local s = site(plan)
		if s then
			local x = (plan.x0 + s.cx) * CELL + CELL / 2
			local z = (plan.z0 + s.cz) * CELL + CELL / 2
			if G.Villages and G.Villages.freeOfBuilds and not G.Villages.freeOfBuilds(reg, x, z, HALF * CELL + 6) then
				s = nil
			else
				local vc = Vector3.new((village.x0 + village.w / 2) * CELL, 0, (village.z0 + village.d / 2) * CELL)
				local to = vc - Vector3.new(x, 0, z)
				local yaw = math.floor(math.deg(math.atan2(to.X, to.Z)) / 90 + 0.5) * 90 -- porte (+Z) vers le village
				spot = { x = x, z = z, y = s.top, yaw = yaw }
			end
		end
		st.chateau = spot or false
		if not spot then
			return
		end
	end
	-- arbres, rochers… du plan qui tomberaient dans les murs : retirés avant que Props ne les pose
	local r = HALF * CELL + 4
	local kept = {}
	for _, p in plan.props do
		if not (p.x and p.z and math.abs(p.x - spot.x) < r and math.abs(p.z - spot.z) < r) then
			table.insert(kept, p)
		end
	end
	plan.props = kept
	local model = G.Util.clone("Chateau")
	if model then
		model:SetAttribute("Lieu", "Château")
		G.World.place(model, spot.x, spot.y, spot.z, spot.yaw, reg.folder)
		G.Clock.seasonize(model)
		-- habité (Metiers, 18/11) : seigneur dans la cour, gardes à la porte ; l'or de la noblesse
		-- va au trésor du village voisin
		reg.castle = model
		reg.castleVillage = village and { key = vx .. "," .. vz, name = village.name } or nil
	end
end

-- pour les tests : emplacement (ou nil) du château d'une région, sans rien poser
function Chateaux.peek(rx: number, rz: number)
	local v = villageFor(rx, rz)
	if not v then
		return nil
	end
	return site(G.wg:plan(rx, rz)), v.name
end

return Chateaux
