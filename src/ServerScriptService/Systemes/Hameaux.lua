-- Hameaux (18/11) : dans environ une région sauvage sur dix (sans lieu, sans château), deux ou
-- trois maisons à colombages autour d'un puits, un champ de blé, du foin, un épouvantail — et leurs
-- habitants (posés par Metiers, qui passe après Npcs). Des haltes sur la route entre deux villages.
--
-- Posé par-dessus la génération avec sa propre graine (« hameau ») : les mondes existants gardent
-- tout le reste. La décision est gardée dans l'état de la région (reg.state.hameau) : une fois posé
-- il reste à sa place, et il ne se pose jamais sur ce que les joueurs ont construit. Doit passer AVANT
-- Props (il retire les arbres / rochers du plan qui seraient dans ses murs) et avant Doors / Npcs
-- (ses maisons rejoignent reg.houses : portes, serrures, lits, casse comme au village).

local Hameaux = {}
local G, Config

local CHANCE = 0.11
local RADIUS = 38 -- studs dégagés autour du puits
local MODELS = { "Maison_A", "Maison_B", "Maison_C" }

function Hameaux.init(g)
	G = g
	Config = G.Config
end

-- terrain plat, sec, loin des routes et des lieux, sur tout le cercle
local function siteOk(plan, cx: number, cz: number, r: number): boolean
	local idx = G.WG.idx
	local h0
	for dz = -r, r, 2 do
		for dx = -r, r, 2 do
			if dx * dx + dz * dz <= r * r then
				local i = idx(cx + dx, cz + dz)
				if plan.water[i] or (plan.roadD[i] or 99) < 3 or (plan.poiW[i] or 0) > 0.2 then
					return false
				end
				local h = plan.H[i]
				h0 = h0 or h
				if math.abs(h - h0) > 4 then
					return false
				end
			end
		end
	end
	return true
end

local function plan(reg)
	local p = reg.plan
	local rng = Random.new(G.WG.hash(G.world.seed, "hameau", reg.rx, reg.rz))
	if rng:NextNumber() > CHANCE then
		return nil
	end
	local CELL, REGION = Config.CELL, Config.REGION
	local rc = math.ceil(RADIUS / CELL)
	for _ = 1, 60 do
		local cx, cz = rng:NextInteger(rc + 2, REGION - rc - 3), rng:NextInteger(rc + 2, REGION - rc - 3)
		if siteOk(p, cx, cz, rc) then
			local x, z = (p.x0 + cx) * CELL + CELL / 2, (p.z0 + cz) * CELL + CELL / 2
			if G.Villages.freeOfBuilds(reg, x, z, RADIUS + 6) then
				local n = rng:NextInteger(2, 3)
				local a0 = rng:NextNumber(0, math.pi * 2)
				local houses = {}
				for i = 1, n do
					local a = a0 + (i - 1) / n * math.pi * 2
					local hx, hz = x + math.cos(a) * 21, z + math.sin(a) * 21
					local toC = Vector3.new(x - hx, 0, z - hz)
					local yaw = math.floor(math.deg(math.atan2(toC.X, toC.Z)) / 90 + 0.5) * 90 -- façade vers le puits
					table.insert(houses, { model = MODELS[rng:NextInteger(1, #MODELS)], x = hx, z = hz, yaw = yaw })
				end
				-- champ et décor du côté libre (entre deux maisons)
				local af = a0 + math.pi / n
				return {
					x = x, z = z, houses = houses,
					field = { x = x + math.cos(af) * 24, z = z + math.sin(af) * 24, yaw = math.floor(math.deg(af) / 90 + 0.5) * 90 },
					hay = { x = x + math.cos(af + 0.5) * 10, z = z + math.sin(af + 0.5) * 10 },
				}
			end
		end
	end
	return nil
end

local function put(name: string, x: number, z: number, yaw: number, parent: Instance): Model?
	local m = G.Util.clone(name)
	if not m then
		return nil
	end
	m.Name = name
	G.World.place(m, x, G.Util.groundY(x, z), z, yaw, parent)
	G.Clock.seasonize(m)
	return m
end

function Hameaux.onRegionLoad(reg)
	local p = reg.plan
	local st = reg.state
	if p.poi or reg.castle or st.hameau == false or (reg.rx == 0 and reg.rz == 0) then
		return
	end
	local spec = st.hameau
	if not spec then
		spec = plan(reg)
		if not spec then
			return -- rien d'enregistré : le tirage est le même à chaque chargement
		end
		st.hameau = spec
	end
	-- arbres, rochers… du plan qui tomberaient dans le hameau : retirés avant que Props ne les pose
	local kept = {}
	for _, pr in p.props do
		if not (pr.x and pr.z and (Vector3.new(pr.x, 0, pr.z) - Vector3.new(spec.x, 0, spec.z)).Magnitude < RADIUS) then
			table.insert(kept, pr)
		end
	end
	p.props = kept
	local folder = Instance.new("Folder")
	folder.Name = "Hameau"
	folder.Parent = reg.folder
	local ids = {}
	for i, h in spec.houses do
		local m = put(h.model, h.x, h.z, h.yaw, folder)
		if m then
			local id = "h:hameau:" .. reg.key .. ":" .. i
			m:SetAttribute("HouseId", id)
			reg.houses[id] = { data = { id = id, model = h.model, kind = "house", x = h.x, z = h.z, yaw = h.yaw }, model = m }
			table.insert(ids, id)
		end
	end
	put("Puits", spec.x, spec.z, 0, folder)
	local field
	if spec.field then
		local f = spec.field
		local model = put("Champ_Ble", f.x, f.z, f.yaw, folder)
		if model then
			-- Moissons retrouve les champs via reg.houses, comme au village.
			local id = "h:hameau:" .. reg.key .. ":ble"
			reg.houses[id] = { data = { id = id, model = "Champ_Ble", kind = "field", x = f.x, z = f.z, yaw = f.yaw }, model = model }
			-- Poste au bord du champ, du côté du puits.
			field = { f.x + (spec.x - f.x) / 2, f.z + (spec.z - f.z) / 2 }
		end
		put("Epouvantail", spec.field.x + 3, spec.field.z + 2, spec.field.yaw, folder)
	end
	if spec.hay then
		put("Botte_Foin", spec.hay.x, spec.hay.z, 30, folder)
		put("Botte_Foin", spec.hay.x + 2.5, spec.hay.z + 1, 75, folder)
	end
	reg.hamlet = { center = Vector3.new(spec.x, 0, spec.z), houses = ids, field = field }
end

function Hameaux.onRegionUnload(reg)
	reg.hamlet = nil
end

-- (tests) le hameau de cette région, sans rien poser
function Hameaux.peek(rx: number, rz: number)
	local reg = { rx = rx, rz = rz, plan = G.wg:plan(rx, rz), state = {} }
	if reg.plan.poi then
		return nil
	end
	return plan(reg)
end

return Hameaux
