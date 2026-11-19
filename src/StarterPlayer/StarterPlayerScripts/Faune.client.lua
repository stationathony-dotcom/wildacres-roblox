-- Faune passive (étape 9A) : purement visuelle et locale (chaque client voit sa propre petite
-- faune autour de lui → zéro coût serveur, zéro réseau). Elle réagit au joueur, au biome, à l'heure
-- et à la météo :
--   · moineaux au sol qui picorent puis s'envolent quand on approche (et vont se poser plus loin) ;
--   · oiseaux qui tournent haut dans le ciel (corbeaux au marais, mouettes près de l'eau) ;
--   · papillons le jour (prairie, forêt, marais ; jamais sous la pluie) ;
--   · lucioles la nuit (marais, prairie, forêt) ;
--   · écureuils le jour (forêt, prairie) : trottinent, puis filent vers l'arbre le plus proche et y
--     grimpent quand on approche (18/11) ;
--   · canards sauvages qui nagent sur les eaux calmes le jour.
--   · hérissons et blaireaux nocturnes qui se réfugient quand on les approche.
--   · marmottes actives le jour dans la toundra.
--   · grenouilles qui bondissent dans les marais.
--   · libellules en vol bas sur les eaux du marais.
--   · lièvres en prairie et tortues terrestres au marais.
--   · pigeons qui picorent à proximité des villages.
-- Rien n'est sauvegardé, rien ne se chasse : c'est le décor qui vit.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if workspace:GetAttribute("Mode") == "accueil" then
	return
end

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local folder = Instance.new("Folder")
folder.Name = "FauneLocale"
folder.Parent = workspace

local rng = Random.new()
local WG = nil
local function biomeAt(pos: Vector3): string
	local seed = workspace:GetAttribute("Seed")
	if not seed then
		return "prairie"
	end
	if not WG or WG.seed ~= seed then
		local ok, mod = pcall(require, Shared:WaitForChild("WorldGen"))
		if not ok then
			return "prairie"
		end
		WG = mod.new(seed, workspace:GetAttribute("Gen"))
	end
	local CELL, REGION = Config.CELL, Config.REGION
	local ok, b = pcall(WG.regionBiome, WG, math.floor(pos.X / CELL / REGION), math.floor(pos.Z / CELL / REGION))
	return ok and b or "prairie"
end

local function nearVillage(pos: Vector3): boolean
	if not WG then
		return false
	end
	local x, z = pos.X / Config.CELL, pos.Z / Config.CELL
	local rx, rz = math.floor(x / Config.REGION), math.floor(z / Config.REGION)
	local margin = 24 / Config.CELL
	for dz = -1, 1 do
		for dx = -1, 1 do
			local poi = WG:poiOf(rx + dx, rz + dz)
			if poi and poi.kind == "village"
				and x >= poi.x0 - margin and x <= poi.x0 + poi.w + margin
				and z >= poi.z0 - margin and z <= poi.z0 + poi.d + margin
			then
				return true
			end
		end
	end
	return false
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local function ground(x: number, z: number, fromY: number): (Vector3?, Enum.Material?)
	params.FilterDescendantsInstances = { folder, player.Character }
	local hit = workspace:Raycast(Vector3.new(x, fromY + 60, z), Vector3.new(0, -160, 0), params)
	if hit then
		return hit.Position, hit.Material
	end
	return nil
end

local function hour(): number
	local m = workspace:GetAttribute("Minutes") or 480
	return (m / 60) % 24
end

local function part(size: Vector3, color: Color3, mat: Enum.Material?, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- ---------------------------------------------------------------- Modèles (quelques pièces)
local function makeBird(color: Color3, scale: number): Model
	local m = Instance.new("Model")
	local body = part(Vector3.new(0.35, 0.3, 0.6) * scale, color, nil, m)
	body.Name = "Corps"
	local head = part(Vector3.new(0.25, 0.25, 0.25) * scale, color, nil, m)
	head.Name = "Tete"
	local beak = part(Vector3.new(0.08, 0.08, 0.16) * scale, Color3.fromRGB(230, 170, 60), nil, m)
	beak.Name = "Bec"
	local wl = part(Vector3.new(0.5, 0.05, 0.3) * scale, color:Lerp(Color3.new(0, 0, 0), 0.2), nil, m)
	wl.Name = "AileG"
	local wr = part(Vector3.new(0.5, 0.05, 0.3) * scale, color:Lerp(Color3.new(0, 0, 0), 0.2), nil, m)
	wr.Name = "AileD"
	m.PrimaryPart = body
	m.Parent = folder
	return m
end

local function poseBird(m: Model, cf: CFrame, flap: number, scale: number)
	local P = m.PrimaryPart :: BasePart
	P.CFrame = cf
	m.Tete.CFrame = cf * CFrame.new(0, 0.12 * scale, -0.38 * scale)
	m.Bec.CFrame = cf * CFrame.new(0, 0.1 * scale, -0.55 * scale)
	local a = math.sin(flap) * 0.9
	m.AileG.CFrame = cf * CFrame.new(-0.22 * scale, 0.05 * scale, 0) * CFrame.Angles(0, 0, a) * CFrame.new(-0.22 * scale, 0, 0)
	m.AileD.CFrame = cf * CFrame.new(0.22 * scale, 0.05 * scale, 0) * CFrame.Angles(0, 0, -a) * CFrame.new(0.22 * scale, 0, 0)
end

local function makeDuck(): Model
	local m = makeBird(Color3.fromRGB(133, 118, 97), 1.7)
	m.Name = "Canard sauvage"
	m.Tete.Color = Color3.fromRGB(43, 104, 79)
	m.Bec.Color = Color3.fromRGB(237, 186, 62)
	return m
end

local BURROWERS = {
	herisson = { name = "Hérisson", size = Vector3.new(0.6, 0.5, 0.9), coat = Color3.fromRGB(87, 64, 48), face = Color3.fromRGB(183, 148, 111), speed = 1.4 },
	blaireau = { name = "Blaireau", size = Vector3.new(0.85, 0.7, 1.5), coat = Color3.fromRGB(100, 101, 105), face = Color3.fromRGB(224, 220, 206), speed = 2.2 },
	marmotte = { name = "Marmotte", size = Vector3.new(0.72, 0.64, 1.1), coat = Color3.fromRGB(137, 100, 61), face = Color3.fromRGB(182, 150, 108), speed = 1.8 },
	grenouille = { name = "Grenouille", size = Vector3.new(0.54, 0.32, 0.56), coat = Color3.fromRGB(73, 111, 42), face = Color3.fromRGB(154, 175, 81), speed = 1.2 },
	lievre = { name = "Lièvre", size = Vector3.new(0.58, 0.61, 0.88), coat = Color3.fromRGB(151, 112, 83), face = Color3.fromRGB(176, 145, 119), speed = 2.4 },
	tortue = { name = "Tortue", size = Vector3.new(0.95, 0.5, 1.24), coat = Color3.fromRGB(62, 80, 48), face = Color3.fromRGB(131, 147, 83), speed = 0.65 },
}

local function makeBurrower(kind: string): Model
	local spec = BURROWERS[kind]
	local m = Instance.new("Model")
	m.Name = spec.name
	local body = part(spec.size, spec.coat, Enum.Material.Fabric, m)
	body.Shape = Enum.PartType.Ball
	m.PrimaryPart = body
	local face = part(spec.size * 0.54, spec.face, nil, m)
	face.Shape = Enum.PartType.Ball
	face.Position = Vector3.new(0, kind == "grenouille" and 0.035 or -0.06, -spec.size.Z * 0.46)
	if kind == "tortue" then
		for _, side in { -1, 1 } do
			for _, z in { -0.33, 0.35 } do
				local foot = part(Vector3.new(0.25, 0.15, 0.24), spec.face, nil, m)
				foot.Shape = Enum.PartType.Ball
				foot.Position = Vector3.new(side * 0.43, -0.16, z)
			end
		end
		return m
	end
	local dark = Color3.fromRGB(40, 36, 33)
	if kind == "grenouille" then
		for _, side in { -1, 1 } do
			local eye = part(Vector3.new(0.15, 0.15, 0.13), dark, nil, m)
			eye.Shape = Enum.PartType.Ball
			eye.Position = face.Position + Vector3.new(side * 0.14, 0.1, -0.02)
			local leg = part(Vector3.new(0.2, 0.17, 0.38), spec.face, nil, m)
			leg.Shape = Enum.PartType.Ball
			leg.Position = Vector3.new(side * 0.25, -0.06, 0.1)
		end
		return m
	end
	local nose = part(Vector3.new(0.12, 0.1, 0.12), dark, nil, m)
	nose.Shape = Enum.PartType.Ball
	nose.Position = face.Position - Vector3.new(0, 0, face.Size.Z * 0.48)
	if kind == "blaireau" then
		for _, side in { -1, 1 } do
			local stripe = part(Vector3.new(0.1, 0.18, 0.34), dark, nil, m)
			stripe.Shape = Enum.PartType.Ball
			stripe.Position = face.Position + Vector3.new(side * 0.15, 0.07, 0)
		end
	elseif kind == "herisson" then
		for i = -2, 2 do
			local spine = part(Vector3.new(0.11, 0.16, 0.5), spec.coat:Lerp(spec.face, 0.35), nil, m)
			spine.Position = Vector3.new(i * 0.1, 0.22 - math.abs(i) * 0.026, 0.08)
		end
	elseif kind == "lievre" then
		for _, side in { -1, 1 } do
			local ear = part(Vector3.new(0.12, 0.47, 0.13), spec.coat, nil, m)
			ear.Shape = Enum.PartType.Ball
			ear.CFrame = CFrame.new(face.Position + Vector3.new(side * 0.13, 0.27, 0.09))
				* CFrame.Angles(math.rad(18), 0, side * math.rad(10))
		end
		local tail = part(Vector3.new(0.22, 0.22, 0.24), spec.face, nil, m)
		tail.Shape = Enum.PartType.Ball
		tail.Position = Vector3.new(0, 0.03, 0.43)
	else
		for _, side in { -1, 1 } do
			local ear = part(Vector3.new(0.15, 0.17, 0.11), spec.coat, nil, m)
			ear.Shape = Enum.PartType.Ball
			ear.Position = face.Position + Vector3.new(side * 0.14, 0.15, 0)
		end
		local tail = part(Vector3.new(0.27, 0.2, 0.62), spec.coat, Enum.Material.Fabric, m)
		tail.Shape = Enum.PartType.Ball
		tail.Position = Vector3.new(0, -0.16, 0.57)
	end
	return m
end

local function poseDuck(m: Model, cf: CFrame)
	m.PrimaryPart.CFrame = cf
	m.Tete.CFrame = cf * CFrame.new(0, 0.32, -0.45)
	m.Bec.CFrame = cf * CFrame.new(0, 0.25, -0.72)
	m.AileG.CFrame = cf * CFrame.new(-0.3, 0.04, 0.06) * CFrame.Angles(0, math.pi / 2, 0)
	m.AileD.CFrame = cf * CFrame.new(0.3, 0.04, 0.06) * CFrame.Angles(0, math.pi / 2, 0)
end

local DUCK_RADIUS = 3
local function duckRoute(center: Vector3): boolean
	for step = 0, 7 do
		local a = step * math.pi / 4
		local x = center.X + math.cos(a) * DUCK_RADIUS
		local z = center.Z + math.sin(a) * DUCK_RADIUS
		local hit, material = ground(x, z, center.Y)
		if not hit or material ~= Enum.Material.Water or math.abs(hit.Y - center.Y) > 0.2 then
			return false
		end
	end
	return true
end

local function makeDragonfly(): Model
	local m = Instance.new("Model")
	m.Name = "Libellule"
	local body = part(Vector3.new(0.08, 0.09, 0.75), Color3.fromRGB(56, 160, 150), nil, m)
	body.Shape = Enum.PartType.Ball
	m.PrimaryPart = body
	for _, side in { -1, 1 } do
		for _, offset in { -0.14, 0.05 } do
			local wing = part(Vector3.new(0.42, 0.025, 0.15), Color3.fromRGB(188, 232, 235), nil, m)
			wing.Transparency = 0.3
			wing.CFrame = CFrame.new(side * 0.22, 0.035, offset)
				* CFrame.Angles(0, side * (offset < 0 and 0.22 or -0.22), 0)
		end
	end
	return m
end

local function makeButterfly(color: Color3): Model
	local m = Instance.new("Model")
	local body = part(Vector3.new(0.05, 0.05, 0.25), Color3.fromRGB(40, 30, 20), nil, m)
	body.Name = "Corps"
	part(Vector3.new(0.3, 0.02, 0.28), color, Enum.Material.Neon, m).Name = "AileG"
	part(Vector3.new(0.3, 0.02, 0.28), color, Enum.Material.Neon, m).Name = "AileD"
	m.PrimaryPart = body
	m.Parent = folder
	return m
end

local function makeSquirrel(color: Color3): Model
	local m = Instance.new("Model")
	local body = part(Vector3.new(0.35, 0.35, 0.6), color, nil, m)
	body.Name = "Corps"
	part(Vector3.new(0.28, 0.28, 0.28), color, nil, m).Name = "Tete"
	local tail = part(Vector3.new(0.3, 0.75, 0.3), color:Lerp(Color3.fromRGB(255, 220, 180), 0.15), Enum.Material.Fabric, m)
	tail.Name = "Queue"
	m.PrimaryPart = body
	m.Parent = folder
	return m
end

local function poseSquirrel(m: Model, cf: CFrame, hop: number, climbing: boolean)
	local c = cf * CFrame.new(0, math.abs(math.sin(hop)) * 0.25, 0)
	if climbing then
		c = c * CFrame.Angles(math.rad(80), 0, 0)
	end
	m.PrimaryPart.CFrame = c
	m.Tete.CFrame = c * CFrame.new(0, 0.12, -0.38)
	m.Queue.CFrame = c * CFrame.new(0, 0.38, 0.38) * CFrame.Angles(math.rad(-20), 0, 0)
end

-- arbre le plus proche (modèles « tree_… » posés par Props) dans un rayon donné
local function nearestTree(pos: Vector3, r: number): Vector3?
	local best, bd = nil, r
	local monde = workspace:FindFirstChild("Monde")
	for _, reg in monde and monde:GetChildren() or {} do
		local objs = reg:IsA("Folder") and reg:FindFirstChild("Objets")
		if objs then
			for _, m in objs:GetChildren() do
				if m:IsA("Model") and string.sub(m.Name, 1, 5) == "tree_" then
					local p = m:GetPivot().Position
					local d = (p - pos).Magnitude
					if d < bd then
						best, bd = p, d
					end
				end
			end
		end
	end
	return best
end

-- ---------------------------------------------------------------- Population
local critters = {} -- { kind, model, pos, vel, state, t, ... }
local MAX = {
	sol = 5, pigeon = 3, ciel = 3, papillon = 6, luciole = 14, ecureuil = 3, canard = 2,
	herisson = 2, blaireau = 1, marmotte = 2, grenouille = 3, libellule = 3, lievre = 2, tortue = 2,
}
local counts = {}
for kind in MAX do
	counts[kind] = 0
end

local function remove(i: number)
	local c = critters[i]
	counts[c.kind] -= 1
	c.model:Destroy()
	table.remove(critters, i)
end

local function spawn(kind: string, root: Vector3, biome: string)
	local a = rng:NextNumber(0, math.pi * 2)
	local d = kind == "ciel" and rng:NextNumber(10, 60) or rng:NextNumber(18, 45)
	local x, z = root.X + math.cos(a) * d, root.Z + math.sin(a) * d
	local g, mat = ground(x, z, root.Y)
	local water = kind == "canard" or kind == "libellule"
	if not g or (mat == Enum.Material.Water) ~= water then
		return
	end
	local c = { kind = kind, t = 0, phase = rng:NextNumber(0, 6) }
	if kind == "canard" then
		if not duckRoute(g) then
			return
		end
		c.model = makeDuck()
		c.center = g
	elseif kind == "libellule" then
		c.model = makeDragonfly()
		c.center = g
		c.model:PivotTo(CFrame.new(g + Vector3.new(0, 2, 0)))
		c.model.Parent = folder
	elseif BURROWERS[kind] then
		c.model = makeBurrower(kind)
		c.pos = g + Vector3.new(0, BURROWERS[kind].size.Y / 2, 0)
		c.yaw = rng:NextNumber(0, math.pi * 2)
		c.model:PivotTo(CFrame.new(c.pos) * CFrame.Angles(0, c.yaw, 0))
		c.model.Parent = folder
	elseif kind == "sol" or kind == "pigeon" then
		local pigeon = kind == "pigeon"
		local col = biome == "neige" and Color3.fromRGB(230, 230, 235) or Color3.fromRGB(130, 95, 70)
		if pigeon then
			col = Color3.fromRGB(122, 130, 149)
		end
		c.scale = pigeon and 1.4 or 1
		c.model = makeBird(col, c.scale)
		if pigeon then
			c.model.Name = "Pigeon"
			c.model.Tete.Color = Color3.fromRGB(70, 106, 107)
			c.model.Bec.Color = Color3.fromRGB(74, 67, 70)
		end
		c.pos = g + Vector3.new(0, 0.2, 0)
		c.yaw = rng:NextNumber(0, 6.28)
		c.state = "picore"
	elseif kind == "ciel" then
		local col = biome == "marais" and Color3.fromRGB(25, 25, 30) or Color3.fromRGB(235, 235, 240)
		c.scale = 2.4
		c.model = makeBird(col, c.scale)
		c.center = Vector3.new(x, g.Y + rng:NextNumber(45, 70), z)
		c.radius = rng:NextNumber(18, 40)
		c.speed = rng:NextNumber(0.25, 0.45) * (rng:NextNumber() < 0.5 and 1 or -1)
	elseif kind == "papillon" then
		local cols = { Color3.fromRGB(255, 200, 60), Color3.fromRGB(120, 180, 255), Color3.fromRGB(255, 130, 180), Color3.fromRGB(255, 255, 255) }
		c.model = makeButterfly(cols[rng:NextInteger(1, #cols)])
		c.home = g + Vector3.new(0, 1.2, 0)
		c.pos = c.home
	elseif kind == "ecureuil" then
		local col = biome == "foret" and Color3.fromRGB(190, 92, 40) or Color3.fromRGB(150, 100, 70)
		c.model = makeSquirrel(col)
		c.pos = g + Vector3.new(0, 0.2, 0)
		c.yaw = rng:NextNumber(0, 6.28)
		c.state = "trotte"
		c.ground = g.Y
	else -- luciole
		local p = part(Vector3.new(0.14, 0.14, 0.14), Color3.fromRGB(220, 255, 120), Enum.Material.Neon, folder)
		p.Shape = Enum.PartType.Ball
		c.model = p
		c.home = g + Vector3.new(0, rng:NextNumber(0.8, 3), 0)
		c.pos = c.home
	end
	counts[kind] += 1
	table.insert(critters, c)
end

local spawnT = 0
RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local root = hrp.Position
	local h = hour()
	local day = h >= 6.5 and h < 19.5
	local wet = workspace:GetAttribute("Weather") == "pluie" or workspace:GetAttribute("Weather") == "orage"
	spawnT -= dt
	if spawnT <= 0 then
		spawnT = 1.5
		local biome = biomeAt(root)
		local want = {
			sol = (day and not wet and biome ~= "desert") and MAX.sol or 0,
			pigeon = (day and not wet and nearVillage(root)) and MAX.pigeon or 0,
			ciel = (day and workspace:GetAttribute("Weather") ~= "orage") and MAX.ciel or 1,
			papillon = (day and not wet and (biome == "prairie" or biome == "foret" or biome == "marais")) and MAX.papillon or 0,
			luciole = (not day and not wet and (biome == "marais" or biome == "prairie" or biome == "foret")) and MAX.luciole or 0,
			ecureuil = (day and not wet and (biome == "foret" or biome == "prairie")) and MAX.ecureuil or 0,
			canard = (day and not wet and biome ~= "neige" and biome ~= "desert") and MAX.canard or 0,
			herisson = (not day and not wet and (biome == "prairie" or biome == "foret")) and MAX.herisson or 0,
			blaireau = (not day and not wet and biome == "foret") and MAX.blaireau or 0,
			marmotte = (day and not wet and biome == "neige") and MAX.marmotte or 0,
			grenouille = biome == "marais" and MAX.grenouille or 0,
			libellule = (day and not wet and biome == "marais") and MAX.libellule or 0,
			lievre = (day and not wet and biome == "prairie") and MAX.lievre or 0,
			tortue = (day and biome == "marais") and MAX.tortue or 0,
		}
		-- trop loin, ou hors de saison/heure : on retire en douceur
		for i = #critters, 1, -1 do
			local c = critters[i]
			local p = c.pos or c.center
			if (p - root).Magnitude > 110 or counts[c.kind] > want[c.kind] then
				if c.state == "picore" then
					c.state = "envol"
					c.t = 0
					c.vel = Vector3.new(rng:NextNumber(-1, 1), 1.4, rng:NextNumber(-1, 1)).Unit * 22
				elseif c.state ~= "envol" then
					remove(i)
				end
			end
		end
		for kind, n in want do
			if counts[kind] < n then
				spawn(kind, root, biome)
			end
		end
	end
	local now = os.clock()
	for i = #critters, 1, -1 do
		local c = critters[i]
		c.t += dt
		if c.kind == "sol" or c.kind == "pigeon" then
			if c.state == "picore" then
				-- tout près ? il s'envole (bruit d'ailes visuel : battement rapide)
				if (c.pos - root).Magnitude < 11 then
					c.state = "envol"
					c.t = 0
					local away = (c.pos - root) * Vector3.new(1, 0, 1)
					away = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
					c.vel = (away + Vector3.new(0, 1.1, 0)).Unit * 24
				end
				local peck = math.max(0, math.sin(now * 9 + c.phase)) * 0.35
				if math.random() < dt * 0.6 then
					c.yaw += rng:NextNumber(-1.2, 1.2) -- se retourne de temps en temps
				end
				poseBird(c.model, CFrame.new(c.pos) * CFrame.Angles(0, c.yaw, 0) * CFrame.Angles(-peck, 0, 0), 0, c.scale)
			else
				c.pos += c.vel * dt
				c.vel += Vector3.new(0, 2, 0) * dt
				local look = CFrame.lookAt(c.pos, c.pos + c.vel)
				poseBird(c.model, look, now * 40 + c.phase, c.scale)
				if c.t > 6 or (c.pos - root).Magnitude > 140 then
					remove(i)
				end
			end
		elseif c.kind == "ecureuil" then
			if c.state == "trotte" then
				if (c.pos - root).Magnitude < 12 then
					-- dérangé : file vers l'arbre le plus proche (sinon s'enfuit tout droit)
					c.state = "fuite"
					c.t = 0
					c.tree = nearestTree(c.pos, 30)
					local away = (c.pos - root) * Vector3.new(1, 0, 1)
					c.dir = c.tree and ((c.tree - c.pos) * Vector3.new(1, 0, 1)).Unit or (away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0))
				elseif math.random() < dt * 0.5 then
					c.yaw += rng:NextNumber(-1.5, 1.5)
				end
				local step = math.max(0, math.sin(now * 3 + c.phase)) * 2.5 * dt
				c.pos += Vector3.new(-math.sin(c.yaw), 0, -math.cos(c.yaw)) * step
				poseSquirrel(c.model, CFrame.new(c.pos) * CFrame.Angles(0, c.yaw, 0), now * 10 + c.phase, false)
			elseif c.state == "fuite" then
				c.pos += c.dir * 14 * dt
				local flat = c.tree and ((c.tree - c.pos) * Vector3.new(1, 0, 1)).Magnitude or 99
				if c.tree and flat < 1 then
					c.state = "grimpe"
					c.t = 0
				end
				poseSquirrel(c.model, CFrame.lookAt(c.pos, c.pos + c.dir), now * 18 + c.phase, false)
				if c.t > 5 then
					remove(i)
					continue
				end
			else -- grimpe au tronc puis disparaît dans le feuillage
				c.pos += Vector3.new(0, 6 * dt, 0)
				poseSquirrel(c.model, CFrame.new(c.pos) * CFrame.Angles(0, c.yaw, 0), now * 14, true)
				if c.pos.Y > c.ground + 9 then
					remove(i)
					continue
				end
			end
		elseif BURROWERS[c.kind] then
			local spec = BURROWERS[c.kind]
			local away = (c.pos - root) * Vector3.new(1, 0, 1)
			if c.kind == "tortue" and away.Magnitude < 9 then
				c.model:PivotTo(CFrame.new(c.pos - Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, c.yaw, 0))
				continue
			end
			if not c.flee and away.Magnitude < 9 then
				c.flee = true
				c.t = 0
				if away.Magnitude > 0.01 then
					c.yaw = math.atan2(-away.X, -away.Z)
				end
			end
			if c.flee and c.t > 3 then
				remove(i)
				continue
			end
			c.step = (c.step or 0) + dt
			if c.step >= 0.2 then
				local speed = c.flee and 7 or spec.speed
				local forward = Vector3.new(-math.sin(c.yaw), 0, -math.cos(c.yaw))
				local nextPos = c.pos + forward * speed * math.min(c.step, 0.3)
				local hit, material = ground(nextPos.X, nextPos.Z, c.pos.Y)
				if hit and material ~= Enum.Material.Water and math.abs(hit.Y - c.pos.Y) < 1.5 then
					c.pos = hit + Vector3.new(0, spec.size.Y / 2, 0)
				else
					c.yaw += math.pi
				end
				c.step = 0
			end
			local hops = c.kind == "grenouille" or c.kind == "lievre"
			local height = hops and math.abs(math.sin(c.t * 5 + c.phase)) ^ 3 * 0.32 or 0
			c.model:PivotTo(CFrame.new(c.pos + Vector3.new(0, height, 0)) * CFrame.Angles(0, c.yaw, 0))
		elseif c.kind == "canard" then
			local a = c.t * 0.4 + c.phase
			local offset = Vector3.new(math.cos(a) * DUCK_RADIUS, 0.2 + math.sin(a * 5) * 0.05, math.sin(a) * DUCK_RADIUS)
			c.pos = c.center + offset
			local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
			poseDuck(c.model, CFrame.lookAt(c.pos, c.pos + tangent))
		elseif c.kind == "libellule" then
			local a = c.t * 1.6 + c.phase
			c.pos = c.center + Vector3.new(math.cos(a) * 2, 1.9 + math.sin(a * 3) * 0.35, math.sin(a) * 2)
			local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
			c.model:PivotTo(CFrame.lookAt(c.pos, c.pos + tangent) * CFrame.Angles(0, 0, math.sin(a * 4) * 0.12))
		elseif c.kind == "ciel" then
			local a = now * c.speed + c.phase
			local p = c.center + Vector3.new(math.cos(a) * c.radius, math.sin(a * 0.7) * 3, math.sin(a) * c.radius)
			local tangent = Vector3.new(-math.sin(a), 0, math.cos(a)) * (c.speed > 0 and 1 or -1)
			c.pos = p
			-- vol plané : quelques battements puis on glisse
			local flap = (math.sin(now * 0.8 + c.phase) > 0.3) and now * 18 or 0.35
			poseBird(c.model, CFrame.lookAt(p, p + tangent) * CFrame.Angles(0, 0, (c.speed > 0 and -0.25 or 0.25)), flap, c.scale)
		elseif c.kind == "papillon" then
			local tgt = c.home + Vector3.new(math.sin(now * 0.7 + c.phase) * 3, math.sin(now * 2.3 + c.phase) * 0.6, math.cos(now * 0.53 + c.phase) * 3)
			local prev = c.pos
			c.pos = tgt
			local dir = tgt - prev
			local cf = CFrame.lookAt(tgt, tgt + (dir.Magnitude > 0.001 and dir or Vector3.new(0, 0, -1)))
			local a = math.sin(now * 22 + c.phase) * 1.1
			c.model.Corps.CFrame = cf
			c.model.AileG.CFrame = cf * CFrame.Angles(0, 0, a) * CFrame.new(-0.16, 0, 0)
			c.model.AileD.CFrame = cf * CFrame.Angles(0, 0, -a) * CFrame.new(0.16, 0, 0)
		else -- luciole : dérive lente, clignote
			c.pos = c.home + Vector3.new(math.sin(now * 0.3 + c.phase) * 2.5, math.sin(now * 0.9 + c.phase) * 0.8, math.cos(now * 0.25 + c.phase) * 2.5)
			c.model.CFrame = CFrame.new(c.pos)
			c.model.Transparency = 0.15 + 0.85 * (0.5 + 0.5 * math.sin(now * 2.2 + c.phase * 3)) ^ 3
		end
	end
end)
