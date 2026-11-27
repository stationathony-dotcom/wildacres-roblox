-- Grottes et donjons. Bac à sable : rien ne les signale, on tombe dessus en explorant.
-- Certaines régions (tirées de la graine du monde) cachent une entrée, de préférence au pied d'une
-- falaise. Derrière : un réseau de galeries creusé dans le Terrain, 120 studs sous la région.
-- La grotte n'existe que tant que quelqu'un s'y trouve (construite à l'entrée, effacée quand elle
-- est vide). Dedans : créatures du biome plus coriaces, un gardien au fond, des filons à miner et
-- un coffre qui se remplit à nouveau tous les quelques jours.
-- Solo / groupe (20/11, étape 18) : les créatures de la grotte gagnent GROUP_HP de vie par joueur en plus
-- présent dans les galeries (jamais moins une fois le groupe arrivé : partir ne les affaiblit pas), et le
-- coffre donne SA part à chacun (une fois par joueur et par remplissage) au lieu du premier arrivé.

local Donjons = {}
local G, Config

local DEPTH = -120 -- sol des galeries
local CEIL = 14 -- hauteur des galeries
local GRID = 52 -- pas entre deux salles
local CHANCE = 0.22 -- part des régions qui ont une grotte
local REFILL_DAYS = 3
local EMPTY_DELAY = 60 -- secondes sans personne avant d'effacer la grotte
Donjons.GROUP_HP = 0.6 -- +60 % de vie des créatures par joueur en plus dans la grotte

local FOES = {
	prairie = { "slime_blue", "wolf", "boar", "goblin" },
	foret = { "spider", "myconid", "wolf", "bear" },
	desert = { "scorpion", "goblin", "scorpion" },
	neige = { "wolf_white", "ice_golem", "wolf_white" },
	marais = { "toad", "croc", "wisp" },
}
local GUARDIAN = { prairie = "boss_slime", foret = "boss_myconid", desert = "boss_goblin", neige = "yeti", marais = "boss_slime" }
local ROCK = { prairie = Enum.Material.Rock, foret = Enum.Material.Slate, desert = Enum.Material.Sandstone, neige = Enum.Material.Glacier, marais = Enum.Material.Basalt }
local VEIN_COLORS = { Color3.fromRGB(196, 120, 70), Color3.fromRGB(200, 200, 210), Color3.fromRGB(236, 196, 70), Color3.fromRGB(150, 210, 255) }

local entrances = {} -- id -> { id, reg, pos, yaw, biome, model }
local active = {} -- id -> grotte construite
local positions = {} -- joueur -> CFrame de retour

function Donjons.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("cave_enter", function(player, prompt)
		Donjons.enter(player, prompt:GetAttribute("Cave"))
	end)
	G.Interact.onPrompt("cave_exit", function(player, prompt)
		Donjons.leave(player, prompt:GetAttribute("Cave"))
	end)
	G.Interact.onPrompt("cave_vein", function(player, prompt)
		Donjons.mine(player, prompt)
	end)
	G.Interact.onPrompt("cave_chest", function(player, prompt)
		Donjons.loot(player, prompt:GetAttribute("Cave"))
	end)
	G.Interact.onPrompt("cave_levier", function(player, prompt)
		Donjons.pull(player, prompt:GetAttribute("Cave"), prompt:GetAttribute("Levier"))
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		positions[p] = nil
	end)
end

-- ----------------------------------------------------------------- Entrées (surface)

local function rock(parent, size, cf, color, mat)
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Une gueule de rochers sombre, tournée vers yaw
local function entranceModel(pos: Vector3, yaw: number, biome: string, id: string): Model
	local m = Instance.new("Model")
	m.Name = "Grotte"
	local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw), 0)
	local col = Color3.fromRGB(110, 106, 100)
	if biome == "desert" then
		col = Color3.fromRGB(196, 160, 110)
	elseif biome == "neige" then
		col = Color3.fromRGB(200, 214, 226)
	end
	local mat = Enum.Material.Slate
	rock(m, Vector3.new(4, 9, 6), cf * CFrame.new(-4.2, 4.2, 0) * CFrame.Angles(0, 0, math.rad(-8)), col, mat)
	rock(m, Vector3.new(4, 9, 6), cf * CFrame.new(4.2, 4.2, 0) * CFrame.Angles(0, 0, math.rad(8)), col, mat)
	rock(m, Vector3.new(12, 3.4, 7), cf * CFrame.new(0, 9, -0.4) * CFrame.Angles(math.rad(6), 0, 0), col, mat)
	rock(m, Vector3.new(6, 4, 5), cf * CFrame.new(-6.5, 2, -1.5) * CFrame.Angles(0, math.rad(25), math.rad(12)), col:Lerp(Color3.new(0, 0, 0), 0.15), mat)
	rock(m, Vector3.new(5, 3, 5), cf * CFrame.new(6.5, 1.5, -1) * CFrame.Angles(0, math.rad(-30), math.rad(-10)), col:Lerp(Color3.new(0, 0, 0), 0.1), mat)
	local mouth = rock(m, Vector3.new(5, 7.6, 0.4), cf * CFrame.new(0, 3.8, -1.2), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic)
	mouth.CanCollide = false
	-- un souffle d'air froid qui sort de la gueule : de quoi la remarquer de près
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(200, 200, 210))
	pe.Transparency = NumberSequence.new(0.85, 1)
	pe.Size = NumberSequence.new(1.5, 4)
	pe.Lifetime = NumberRange.new(2, 3)
	pe.Rate = 3
	pe.Speed = NumberRange.new(1, 2)
	pe.EmissionDirection = Enum.NormalId.Front
	pe.Parent = mouth
	local base = rock(m, Vector3.new(1, 0.2, 1), cf, col, mat)
	base.Transparency = 1
	base.CanCollide = false
	m.PrimaryPart = base
	G.Util.prompt(mouth, "cave_enter", "Entrer", "Grotte", { dist = 10, hold = 0.6, data = { Cave = id } })
	return m
end

-- La région a-t-elle une grotte ? Où ? (déterministe : même graine, même grotte)
local function siteOf(reg)
	local plan = reg.plan
	local rng = Random.new(G.WG.hash(G.world.seed, "grotte", reg.rx, reg.rz))
	if rng:NextNumber() > CHANCE or plan.poi then
		return nil
	end
	local idx = G.WG.idx
	local R = Config.REGION
	local best, bestScore
	for _ = 1, 80 do
		local lx, lz = rng:NextInteger(4, R - 5), rng:NextInteger(4, R - 5)
		local i = idx(lx, lz)
		if not plan.water[i] and plan.roadD[i] > 3 and plan.poiW[i] < 0.01 and plan.distW[i] > 2 then
			-- une falaise à 2 cases dans une direction : on s'y adosse
			local h = plan.H[i]
			local score, yaw = 0, rng:NextNumber(0, 360)
			-- yaw : la gueule (face -Z du modèle) tourne le dos à la falaise
			for _, d in { { 0, -2, 180 }, { 2, 0, 90 }, { 0, 2, 0 }, { -2, 0, 270 } } do
				local hh = plan.H[idx(lx + d[1], lz + d[2])]
				if hh and hh - h > 6 and hh - h > score then
					score, yaw = hh - h, d[3]
				end
			end
			local flat = true
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				if math.abs(plan.H[idx(lx + d[1], lz + d[2])] - h) > 1.5 then
					flat = false
				end
			end
			if flat and (not best or score > bestScore) then
				best, bestScore = { lx = lx, lz = lz, yaw = yaw }, score
				if score > 6 then
					break
				end
			end
		end
	end
	if not best then
		return nil
	end
	local cx, cz = plan.x0 + best.lx, plan.z0 + best.lz
	local x, z = cx * Config.CELL + Config.CELL / 2, cz * Config.CELL + Config.CELL / 2
	return { x = x, z = z, yaw = best.yaw }
end

-- Grotte d'une région dont le plan est déjà calculé (sinon nil : on ne génère rien pour une rumeur).
-- Sert aux enfants des villages, qui connaissent les cachettes du coin.
function Donjons.siteNear(rx: number, rz: number)
	local plan = G.wg and G.wg.planCache[rx .. "," .. rz]
	if not plan then
		return nil
	end
	return siteOf({ plan = plan, rx = rx, rz = rz })
end

function Donjons.onRegionLoad(reg)
	local site = siteOf(reg)
	if not site then
		return
	end
	local id = "grotte" .. reg.key
	-- rien de posé dessus (les props du plan restent où ils sont : on s'écarte si besoin)
	local pos = Vector3.new(site.x, G.Util.groundY(site.x, site.z), site.z)
	local model = entranceModel(pos, site.yaw, reg.plan.biome, id)
	model.Parent = reg.folder
	entrances[id] = { id = id, reg = reg, pos = pos, yaw = site.yaw, biome = reg.plan.biome, model = model }
end

function Donjons.onRegionUnload(reg)
	local id = "grotte" .. reg.key
	local e = entrances[id]
	if e then
		entrances[id] = nil
	end
end

-- ----------------------------------------------------------------- Galeries (sous terre)

-- Plan de la grotte : une marche aléatoire de salles reliées par des boyaux
local function layout(e)
	local rng = Random.new(G.WG.hash(G.world.seed, "galeries", e.id))
	local n = rng:NextInteger(4, 7)
	local cells, used = { { 0, 0 } }, { ["0,0"] = true }
	local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	while #cells < n do
		local last = cells[#cells]
		local ok = false
		for _ = 1, 8 do
			local d = dirs[rng:NextInteger(1, 4)]
			local c = { last[1] + d[1], last[2] + d[2] }
			if not used[c[1] .. "," .. c[2]] then
				used[c[1] .. "," .. c[2]] = true
				table.insert(cells, c)
				ok = true
				break
			end
		end
		if not ok then
			break
		end
	end
	local rooms = {}
	local look = CFrame.Angles(0, math.rad(e.yaw), 0)
	for i, c in cells do
		local size = (i == #cells) and 40 or rng:NextInteger(24, 34)
		local off = look:VectorToWorldSpace(Vector3.new(c[1] * GRID, 0, c[2] * GRID))
		local center = Vector3.new(e.pos.X + off.X, DEPTH, e.pos.Z + off.Z)
		table.insert(rooms, { center = center, w = size, d = size + rng:NextInteger(-6, 6) })
	end
	return rooms, rng
end

-- Les zones praticables (salles + boyaux), en rectangles alignés sur les axes du monde
local function rectsOf(rooms)
	local rects = {}
	for i, r in rooms do
		table.insert(rects, { x0 = r.center.X - r.w / 2, x1 = r.center.X + r.w / 2, z0 = r.center.Z - r.d / 2, z1 = r.center.Z + r.d / 2 })
		local nx = rooms[i + 1]
		if nx then
			local a, b = r.center, nx.center
			table.insert(rects, { x0 = math.min(a.X, b.X) - 4, x1 = math.max(a.X, b.X) + 4, z0 = math.min(a.Z, b.Z) - 4, z1 = math.max(a.Z, b.Z) + 4 })
		end
	end
	return rects
end

function Donjons.floorAt(x: number, z: number, y: number): number?
	for _, cave in active do
		if math.abs(y - DEPTH) < 30 then
			for _, r in cave.rects do
				if x > r.x0 + 1.5 and x < r.x1 - 1.5 and z > r.z0 + 1.5 and z < r.z1 - 1.5 then
					return DEPTH
				end
			end
		end
	end
	return nil
end

-- Dans le volume d'une grotte construite (galeries comprises, parois incluses)
function Donjons.inCave(pos: Vector3): boolean
	for _, cave in active do
		local c, sz = cave.box.cf.Position, cave.box.size
		if math.abs(pos.X - c.X) < sz.X / 2 and math.abs(pos.Z - c.Z) < sz.Z / 2 and math.abs(pos.Y - c.Y) < sz.Y / 2 + 4 then
			return true
		end
	end
	return false
end

local function torch(parent, pos: Vector3)
	local m = G.Config.Catalogue.build("Cat_wall_torch")
	if m then
		m:PivotTo(CFrame.new(pos))
		m.Parent = parent
	end
end

local function build(e)
	local rooms, rng = layout(e)
	local rects = rectsOf(rooms)
	local folder = Instance.new("Folder")
	folder.Name = "Grotte_" .. e.id
	folder.Parent = workspace
	local T = workspace.Terrain
	local mat = ROCK[e.biome] or Enum.Material.Rock
	-- masse rocheuse englobante, puis on creuse
	local mn, mx = Vector3.new(math.huge, 0, math.huge), Vector3.new(-math.huge, 0, -math.huge)
	for _, r in rects do
		mn = Vector3.new(math.min(mn.X, r.x0), 0, math.min(mn.Z, r.z0))
		mx = Vector3.new(math.max(mx.X, r.x1), 0, math.max(mx.Z, r.z1))
	end
	local pad = 12
	local box = { cf = CFrame.new((mn.X + mx.X) / 2, DEPTH + CEIL / 2, (mn.Z + mx.Z) / 2), size = Vector3.new(mx.X - mn.X + pad * 2, CEIL + 16, mx.Z - mn.Z + pad * 2) }
	T:FillBlock(box.cf, box.size, mat)
	task.wait()
	for _, r in rects do
		local c = CFrame.new((r.x0 + r.x1) / 2, DEPTH + CEIL / 2, (r.z0 + r.z1) / 2)
		T:FillBlock(c, Vector3.new(r.x1 - r.x0, CEIL, r.z1 - r.z0), Enum.Material.Air)
	end
	-- voûtes irrégulières et sol de terre battue
	for _, r in rooms do
		for _ = 1, 3 do
			local p = r.center + Vector3.new(rng:NextNumber(-r.w / 3, r.w / 3), CEIL - 2, rng:NextNumber(-r.d / 3, r.d / 3))
			T:FillBall(p, rng:NextNumber(5, 8), Enum.Material.Air)
		end
		T:FillBlock(CFrame.new(r.center.X, DEPTH - 2, r.center.Z), Vector3.new(r.w, 4, r.d), Enum.Material.Ground)
	end
	task.wait()
	local cave = { id = e.id, e = e, rooms = rooms, rects = rects, box = box, folder = folder, enemies = {}, lastSeen = os.clock() }
	active[e.id] = cave
	-- éclairage : torches dans les salles, lueurs bleutées dans les boyaux
	for i, r in rooms do
		torch(folder, r.center + Vector3.new(r.w / 2 - 2, 0, 0))
		torch(folder, r.center + Vector3.new(-r.w / 2 + 2, 0, 0))
		if i == 1 then
			torch(folder, r.center + Vector3.new(0, 0, r.d / 2 - 2))
		end
	end
	-- sortie : une corde qui remonte vers la lumière
	local first = rooms[1].center
	local rope = rock(folder, Vector3.new(0.4, CEIL, 0.4), CFrame.new(first + Vector3.new(0, CEIL / 2, 0)), Color3.fromRGB(196, 170, 110), Enum.Material.Fabric)
	rope.CanCollide = false
	local beam = rock(folder, Vector3.new(4, 0.2, 4), CFrame.new(first + Vector3.new(0, CEIL - 0.5, 0)), Color3.fromRGB(255, 244, 210), Enum.Material.Neon)
	beam.CanCollide = false
	local l = Instance.new("SpotLight")
	l.Face = Enum.NormalId.Bottom
	l.Range = 20
	l.Brightness = 3
	l.Angle = 60
	l.Parent = beam
	G.Util.prompt(rope, "cave_exit", "Remonter", "Corde", { dist = 8, hold = 0.4, data = { Cave = e.id } })
	-- créatures : les salles du milieu, et un gardien au fond
	local reg = e.reg
	local foes = G.Bestiaire.CAVE[e.biome] or FOES[e.biome] or FOES.prairie
	for i = 2, #rooms do
		local r = rooms[i]
		local last = i == #rooms
		local n = last and 2 or rng:NextInteger(2, 4)
		for k = 1, n do
			local p = r.center + Vector3.new(rng:NextNumber(-r.w / 3, r.w / 3), 0, rng:NextNumber(-r.d / 3, r.d / 3))
			local en = G.Enemies.spawn(reg, { id = e.id .. "#" .. i .. "#" .. k .. "#" .. G.world.day .. "#" .. rng:NextInteger(1, 1e6),
				kind = foes[rng:NextInteger(1, #foes)], x = p.X, z = p.Z, y = DEPTH }, folder)
			if en then
				en.transient = true
				table.insert(cave.enemies, en)
			end
		end
		if last then
			local en = G.Enemies.spawn(reg, { id = e.id .. "#gardien#" .. G.world.day, kind = G.Bestiaire.GUARDIAN[e.biome] or GUARDIAN[e.biome] or "boss_slime", x = r.center.X, z = r.center.Z, y = DEPTH }, folder)
			if en then
				en.transient = true
				table.insert(cave.enemies, en)
			end
		end
	end
	-- filons sur les parois
	for i = 2, #rooms do
		if rng:NextNumber() < 0.75 then
			local r = rooms[i]
			local side = rng:NextInteger(1, 4)
			local off = ({ Vector3.new(r.w / 2 - 1, 0, 0), Vector3.new(-r.w / 2 + 1, 0, 0), Vector3.new(0, 0, r.d / 2 - 1), Vector3.new(0, 0, -r.d / 2 + 1) })[side]
			local vein = rock(folder, Vector3.new(2.6, 2.6, 2.6), CFrame.new(r.center + off + Vector3.new(rng:NextNumber(-4, 4) * (side > 2 and 1 or 0), 2.2, rng:NextNumber(-4, 4) * (side <= 2 and 1 or 0)))
				* CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0), VEIN_COLORS[rng:NextInteger(1, #VEIN_COLORS)], Enum.Material.CrackedLava)
			vein.Name = "Filon"
			local glow = Instance.new("PointLight")
			glow.Color = vein.Color
			glow.Range = 10
			glow.Brightness = 0.8
			glow.Parent = vein
			vein:SetAttribute("Coups", 3)
			G.Util.prompt(vein, "cave_vein", "Miner", "Filon", { dist = 9, hold = 0.8 })
		end
	end
	-- coffre au fond
	local rs = e.reg.state
	rs.caves = rs.caves or {}
	local cycle = Donjons.cycle(rs, e.id)
	local deep = rooms[#rooms].center
	local chest = G.Config.Catalogue.build("Cat_reinforced_chest")
	if chest then
		chest:PivotTo(CFrame.new(deep + Vector3.new(0, 0, rooms[#rooms].d / 2 - 4)) * CFrame.Angles(0, math.pi, 0))
		chest.Parent = folder
		local full = cycle ~= nil
		local p = chest:FindFirstChildWhichIsA("BasePart", true)
		for _, part in chest:GetDescendants() do
			if part:IsA("BasePart") and part.Size.X > 2.5 and part.Size.Y > 1 then
				p = part
				break
			end
		end
		cave.chestPrompt = G.Util.prompt(p, "cave_chest", full and "Ouvrir" or "Vide", "Coffre ancien", { dist = 9, hold = 0.6, data = { Cave = e.id } })
		cave.full = full
		-- énigme (18/11) : le coffre est scellé tant que les leviers cachés dans les salles ne sont pas
		-- tous abaissés (il en faut jusqu'à 3 ; on peut s'y mettre à plusieurs)
		local need = math.min(3, #rooms - 2)
		cave.levers = { need = math.max(0, need), pulled = {} }
		for k = 1, cave.levers.need do
			local r = rooms[k + 1]
			local side = rng:NextInteger(0, 1) == 0 and -1 or 1
			local at = r.center + Vector3.new(side * (r.w / 2 - 1.2), 0, rng:NextNumber(-r.d / 4, r.d / 4))
			local lever = Instance.new("Model")
			lever.Name = "Levier"
			local socle = rock(lever, Vector3.new(1.4, 2.2, 1.4), CFrame.new(at + Vector3.new(0, 1.1, 0)), Color3.fromRGB(96, 92, 88), Enum.Material.Cobblestone)
			local arm = Instance.new("Part")
			arm.Name = "Manche"
			arm.Anchored, arm.CanCollide = true, false
			arm.Size = Vector3.new(0.3, 1.8, 0.3)
			arm.Color = Color3.fromRGB(70, 70, 76)
			arm.Material = Enum.Material.Metal
			arm.CFrame = CFrame.new(at + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(35 * side))
			arm.Parent = lever
			lever.PrimaryPart = socle
			lever.Parent = folder
			local pr = G.Util.prompt(socle, "cave_levier", "Abaisser le levier", "Mécanisme ancien", { dist = 8, hold = 0.5, data = { Cave = e.id, Levier = k } })
			cave.levers[k] = { prompt = pr, arm = arm, side = side }
		end
		cave.chestPrompt.Enabled = full and cave.levers.need == 0
		if full and cave.levers.need > 0 then
			cave.chestPrompt.ActionText = "Scellé"
		end
	end
	return cave
end

-- Remplissage du coffre : { day = début, by = { [uid] = true } } (rs.caveLoot) ; un nouveau cycle commence
-- REFILL_DAYS jours après le précédent. Ancien format (rs.caves[id] = jour du pillage) : repris comme début.
function Donjons.cycle(rs, id: string)
	rs.caveLoot = rs.caveLoot or {}
	local c = rs.caveLoot[id]
	if not c and rs.caves and rs.caves[id] then
		c = { day = rs.caves[id], by = {} }
		rs.caveLoot[id] = c
	end
	if not c or G.world.day >= c.day + REFILL_DAYS then
		c = { day = G.world.day, by = {} }
		rs.caveLoot[id] = c
	end
	return c
end

-- joueurs dans les galeries de cette grotte
local function playersIn(cave): { Player }
	local list = {}
	local c = cave.box.cf.Position
	for _, p in G.Game.players() do
		local r = G.Util.root(p)
		if r and r.Position.Y < DEPTH + 40 and r.Position.Y > DEPTH - 40
			and math.abs(r.Position.X - c.X) < cave.box.size.X / 2 + 10 and math.abs(r.Position.Z - c.Z) < cave.box.size.Z / 2 + 10 then
			table.insert(list, p)
		end
	end
	return list
end
Donjons.playersIn = playersIn

-- le groupe grossit : les créatures encore debout prennent de la vie (proportionnellement)
function Donjons.scaleFor(cave, n: number)
	local before = cave.party or 1
	if n <= before then
		return
	end
	local factor = (1 + Donjons.GROUP_HP * (n - 1)) / (1 + Donjons.GROUP_HP * (before - 1))
	cave.party = n
	for _, en in cave.enemies do
		if not en.dead then
			en.maxHp = math.floor(en.maxHp * factor)
			en.hp = math.floor(en.hp * factor)
			if en.model and en.model.Parent then
				en.model:SetAttribute("PVMax", en.maxHp)
				en.model:SetAttribute("PV", en.hp)
			end
		end
	end
end

-- Abaisser un levier de la grotte ; tous abaissés → le coffre ancien se déverrouille
function Donjons.pull(player: Player, id: string?, k: number?)
	local cave = id and active[id]
	local lv = cave and cave.levers and k and cave.levers[k]
	if not lv or cave.levers.pulled[k] then
		return
	end
	cave.levers.pulled[k] = true
	lv.prompt.Enabled = false
	lv.arm.CFrame = lv.arm.CFrame * CFrame.Angles(0, 0, math.rad(-70 * lv.side))
	local n = 0
	for _ in cave.levers.pulled do
		n += 1
	end
	if n >= cave.levers.need then
		if cave.chestPrompt and cave.full then
			cave.chestPrompt.Enabled = true
			cave.chestPrompt.ActionText = "Ouvrir"
		end
		G.Util.toast(player, "⚙️ Un lourd mécanisme se déverrouille au fond de la grotte…", "big")
	else
		G.Util.toast(player, string.format("⚙️ Un mécanisme grince au loin… (%d / %d)", n, cave.levers.need))
	end
end

local function destroy(cave)
	active[cave.id] = nil
	for _, en in cave.enemies do
		if not en.dead then
			en.dead = true
			if en.model then
				en.model:Destroy()
			end
		end
	end
	cave.folder:Destroy()
	workspace.Terrain:FillBlock(cave.box.cf, cave.box.size + Vector3.new(4, 8, 4), Enum.Material.Air)
end

-- ----------------------------------------------------------------- Entrer, sortir, miner, piller

-- Téléportation sûre : le perso reste figé le temps que le client reçoive le terrain et les
-- galeries (streaming) ; sinon il passe à travers un sol qu'il n'a pas encore.
local function safeTeleport(player: Player, pos: Vector3)
	local root = G.Util.root(player)
	if not root then
		return
	end
	-- en surface : on se pose SUR le sol réel (un perso qui apparaît les pieds dans le terrain
	-- passe au travers)
	if pos.Y > Config.Y_MIN then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { workspace.Terrain }
		local hit = workspace:Raycast(Vector3.new(pos.X, Config.Y_MAX + 40, pos.Z), Vector3.new(0, -(Config.Y_MAX + 40 - Config.Y_MIN), 0), params)
		if hit then
			pos = Vector3.new(pos.X, hit.Position.Y + 0.5, pos.Z)
		end
	end
	G.remotes.Fade:FireClient(player, nil, 0)
	task.wait(0.6)
	root.Anchored = true
	G.Game.teleport(player, pos)
	task.wait(1.4)
	if root.Parent then
		root.Anchored = false
	end
	G.remotes.Fade:FireClient(player, nil, 1)
end

function Donjons.enter(player: Player, id: string)
	local e = entrances[id]
	local root = G.Util.root(player)
	if not e or not root then
		return
	end
	local cave = active[id] or build(e)
	cave.lastSeen = os.clock()
	-- retour : devant la gueule de la grotte
	positions[player] = CFrame.new(e.pos + CFrame.Angles(0, math.rad(e.yaw), 0):VectorToWorldSpace(Vector3.new(0, 3, -8)))
	safeTeleport(player, cave.rooms[1].center + Vector3.new(3, 0, 3))
end

function Donjons.leave(player: Player, id: string)
	local root = G.Util.root(player)
	if not root then
		return
	end
	local e = entrances[id]
	local back = positions[player] or (e and CFrame.new(e.pos + Vector3.new(0, 3, 0)))
	positions[player] = nil
	if back then
		safeTeleport(player, back.Position - Vector3.new(0, 3, 0))
	end
end

function Donjons.mine(player: Player, prompt: ProximityPrompt)
	local vein = prompt.Parent
	local tool, tier = G.Joueurs.bestTool(player, "pickaxe")
	if not tool then
		G.Util.toast(player, "Il faut une pioche.")
		return
	end
	local loot = { { "copper_ore", 2, 3 }, { "coal", 1, 3 } }
	if tier >= 2 then
		table.insert(loot, { "ore", 2, 3 })
		table.insert(loot, { "silver_ore", 1, 2 })
	end
	if tier >= 3 then
		table.insert(loot, { "gold_ore", 1, 2 })
	end
	local l = loot[math.random(1, #loot)]
	G.Util.auSol(player, vein.Position, vein, function()
		G.Joueurs.add(player, l[1], math.random(l[2], l[3]))
		G.Util.finds(player, "rock", vein.Position)
	end)
	G.Joueurs.addSkillXp(player, "minage", 8)
	local left = (vein:GetAttribute("Coups") or 1) - 1
	vein:SetAttribute("Coups", left)
	if left <= 0 then
		vein:Destroy()
	end
	G.Joueurs.sync(player)
end

function Donjons.loot(player: Player, id: string)
	local cave = active[id]
	if not cave or not cave.chestPrompt or not cave.chestPrompt.Enabled then
		return
	end
	-- le gardien veille sur son coffre
	for _, en in cave.enemies do
		if not en.dead and (en.k.boss or en.k.elite) then
			G.Util.toast(player, "Le gardien de la grotte rôde encore.")
			return
		end
	end
	-- chacun sa part, une fois par remplissage
	local rs0 = cave.e.reg.state
	local cycle = Donjons.cycle(rs0, id)
	local uid = tostring(player.UserId)
	if cycle.by[uid] then
		G.Util.toast(player, "Tu as déjà pris ta part de ce coffre. Il se remplira de nouveau dans quelques jours.")
		return
	end
	cycle.by[uid] = true
	local lp = G.Joueurs.get(player)
	if lp then
		lp.stats.caves = (lp.stats.caves or 0) + 1
		G.Social.checkTitles(player)
	end
	local list = G.Config.Catalogue.TREASURE
	for _ = 1, 3 do
		local t = list[math.random(1, #list)]
		G.Joueurs.add(player, t[1], math.random(t[2], t[3]))
	end
	G.Joueurs.add(player, "relic_fragment", math.random(1, 2))
	-- œuf de monture rare au fond du coffre (27/11, MANQUES-MMO n° 1 « œufs rares en donjon »)
	if math.random() < 0.03 then
		local okEc, Ecurie = pcall(require, game:GetService("ReplicatedStorage").Shared.Ecurie)
		local pool = {}
		for _, list in (okEc and Ecurie.OEUFS) or {} do
			for _, e in list do
				if G.Config.ITEMS[Ecurie.oeufId(e[1])] then
					table.insert(pool, Ecurie.oeufId(e[1]))
				end
			end
		end
		if #pool > 0 then
			local id = pool[math.random(1, #pool)]
			G.Joueurs.add(player, id, 1, true)
			G.Util.toast(player, "🥚 Dans un recoin du coffre, un œuf encore tiède : " .. G.Config.ITEMS[id].name .. " !", "big")
		end
	end
	local danger = (G.world.danger or 1)
	G.Joueurs.addGear(player, G.Gear.roll(Random.new(), math.min(10, 4 + danger)))
	G.Joueurs.sync(player)
end

-- ----------------------------------------------------------------- Boucle

local acc = 0
function Donjons.step(dt: number)
	acc += dt
	if acc < 5 then
		return
	end
	acc = 0
	for id, cave in active do
		local inside = playersIn(cave)
		local anyone = #inside > 0
		Donjons.scaleFor(cave, #inside)
		if anyone then
			cave.lastSeen = os.clock()
		elseif os.clock() - cave.lastSeen > EMPTY_DELAY then
			destroy(cave)
		end
	end
	-- filet de sécurité : un joueur sous le monde hors d'une galerie (chute, streaming en retard)
	-- remonte devant sa grotte, ou à son point de réapparition
	for _, p in G.Game.players() do
		local r = G.Util.root(p)
		local pos = r and r.Position
		if pos and pos.Y < Config.Y_MIN - 10 and not Donjons.inCave(pos) then
			local back = positions[p]
			local spawn = p:GetAttribute("RespawnPos")
			local target = back and (back.Position - Vector3.new(0, 3, 0)) or (typeof(spawn) == "Vector3" and spawn) or nil
			if target then
				positions[p] = nil
				task.spawn(safeTeleport, p, target)
			end
		end
	end
end

-- Studio / tests
function Donjons.list()
	local out = {}
	for id, e in entrances do
		table.insert(out, { id = id, x = e.pos.X, y = e.pos.Y, z = e.pos.Z, biome = e.biome })
	end
	return out
end

return Donjons
