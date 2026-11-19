-- Créatures du monde : monstres par biome (bondissent, crachent, chargent, tirent), monstres de NUIT
-- (zombies, squelettes : ils brûlent à l'aube), bêtes NEUTRES (ripostent si on les frappe) et animaux
-- SAUVAGES (fuient, se chassent pour la viande et le cuir), trois boss dans leurs antres (2 phases).
-- Chaque attaque est annoncée (pose) pour pouvoir esquiver. Plus on s'éloigne du départ, plus c'est dur.
-- loot = { {objet, min, max, chance} } ; xp = expérience gagnée.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Enemies = {}
local G
Enemies.list = {}

local KINDS = {
	slime = { name = "Slime", model = "Slime", hp = 60, dmg = 10, speed = 9, level = 1, style = "hop", radius = 1.5,
		loot = { { "slime_gel", 1, 2, 0.7 }, { "fiber", 1, 1, 0.4 } } },
	slime_blue = { name = "Slime bleu", model = "Slime_Bleu", hp = 100, dmg = 10, speed = 10, level = 2, style = "hop", radius = 1.6,
		loot = { { "slime_gel", 1, 3, 0.8 } } },
	myconid = { name = "Myconide", model = "Myconide", hp = 140, dmg = 10, speed = 9, level = 3, style = "spore", radius = 1.4,
		loot = { { "mushroom", 1, 2, 1 } } },
	goblin = { name = "Gobelin", model = "Gobelin", hp = 180, dmg = 20, speed = 13, level = 4, style = "charge", radius = 1.4,
		loot = { { "ore", 1, 1, 0.3 }, { "copper_ore", 1, 2, 0.4 } }, gold = 2 },
	-- prairie / forêt
	wolf = { name = "Loup", model = "Loup", hp = 90, dmg = 12, speed = 15, level = 2, style = "charge", radius = 1.4, pack = 3,
		loot = { { "fur", 1, 1, 0.7 }, { "meat", 1, 2, 0.9 } } },
	boar = { name = "Sanglier", model = "Sanglier", hp = 120, dmg = 16, speed = 13, level = 2, style = "charge", radius = 1.6, neutral = true,
		loot = { { "meat", 2, 3, 1 }, { "leather", 1, 2, 0.8 } } },
	bear = { name = "Ours", model = "Ours", hp = 320, dmg = 28, speed = 12, level = 5, style = "charge", radius = 2.2, neutral = true,
		loot = { { "fur", 2, 3, 1 }, { "meat", 3, 4, 1 }, { "honey", 1, 2, 0.5 } } },
	spider = { name = "Araignée géante", model = "Araignee", hp = 150, dmg = 14, speed = 14, level = 3, style = "spore", radius = 1.8,
		proj = { color = Color3.fromRGB(240, 240, 240), size = 1, poison = true }, loot = { { "silk", 1, 3, 1 } } },
	-- désert
	scorpion = { name = "Scorpion", model = "Scorpion", hp = 160, dmg = 18, speed = 12, level = 4, style = "charge", radius = 1.6,
		loot = { { "stinger", 1, 1, 0.8 }, { "meat", 1, 1, 0.3 } } },
	-- toundra
	wolf_white = { name = "Loup blanc", model = "Loup_Blanc", hp = 130, dmg = 16, speed = 16, level = 4, style = "charge", radius = 1.4, pack = 3,
		loot = { { "fur", 1, 2, 0.9 }, { "meat", 1, 2, 0.9 } } },
	yeti = { name = "Yéti", model = "Yeti", hp = 480, dmg = 34, speed = 12, level = 7, style = "charge", radius = 2.6, elite = true,
		loot = { { "fur", 3, 5, 1 }, { "ice_crystal", 1, 2, 0.8 } }, gold = 4 },
	ice_golem = { name = "Golem de glace", model = "Golem_Glace", hp = 360, dmg = 24, speed = 9, level = 6, style = "spore", radius = 2.2,
		proj = { color = Color3.fromRGB(170, 230, 255), size = 1.6 }, loot = { { "ice_crystal", 1, 3, 1 }, { "ore", 1, 2, 0.5 } } },
	-- marais
	toad = { name = "Crapaud géant", model = "Crapaud", hp = 110, dmg = 12, speed = 10, level = 2, style = "hop", radius = 1.6,
		loot = { { "slime_gel", 1, 2, 0.6 }, { "leather", 1, 1, 0.4 } } },
	wisp = { name = "Feu follet", model = "Feu_Follet", hp = 70, dmg = 14, speed = 11, level = 3, style = "spore", radius = 1.2,
		proj = { color = Color3.fromRGB(140, 220, 255), size = 0.9 }, loot = { { "wisp_dust", 1, 2, 1 } } },
	croc = { name = "Croco", model = "Croco", hp = 220, dmg = 22, speed = 11, level = 4, style = "charge", radius = 2, neutral = true,
		loot = { { "leather", 2, 3, 1 }, { "meat", 1, 2, 0.8 } } },
	-- nuit (hors des villages et des parcelles éclairées ; se dissipent à l'aube)
	scarecrow = { name = "Épouvantail maudit", model = "Epouvantail_Maudit", hp = 170, dmg = 20, speed = 7, level = 3, style = "charge", radius = 1.6, night = true,
		loot = { { "fiber", 2, 4, 1 }, { "wisp_dust", 1, 1, 0.3 }, { "seed_pumpkin", 1, 2, 0.25 } } },
	shade = { name = "Ombre rôdeuse", model = "Ombre", hp = 80, dmg = 14, speed = 15, level = 3, style = "charge", radius = 1.3, night = true, fearsLight = true,
		loot = { { "wisp_dust", 1, 2, 0.8 }, { "bone", 1, 2, 0.5 } } },
	-- cambrioleur (la nuit, vise les coffres des parcelles ; piloté par Protection)
	burglar = { name = "Cambrioleur", model = "Cambrioleur", hp = 120, dmg = 12, speed = 14, level = 3, style = "charge", radius = 1.4, custom = true,
		loot = { { "lockpick", 1, 3, 0.9 }, { "rope", 1, 2, 0.5 } }, gold = 3 },
	-- animaux sauvages : fuient, se chassent
	deer = { name = "Cerf", model = "Cerf", hp = 60, dmg = 0, speed = 16, level = 1, style = "flee", radius = 1.4, passive = true,
		loot = { { "meat", 2, 3, 1 }, { "leather", 1, 2, 0.9 } } },
	rabbit = { name = "Lapin", model = "Lapin", hp = 20, dmg = 0, speed = 15, level = 1, style = "flee", radius = 0.6, passive = true, burrow = true,
		loot = { { "meat", 1, 1, 1 }, { "fur", 1, 1, 0.3 } } },
	fox = { name = "Renard", model = "Renard", hp = 40, dmg = 0, speed = 15, level = 1, style = "flee", radius = 0.8, passive = true, burrow = true,
		loot = { { "fur", 1, 1, 0.8 } } },
	penguin = { name = "Pingouin", model = "Pingouin", hp = 40, dmg = 0, speed = 7, level = 1, style = "flee", radius = 0.8, passive = true,
		loot = { { "feather", 1, 2, 1 }, { "meat", 1, 1, 0.6 } } },
	camel = { name = "Chameau", model = "Chameau", hp = 120, dmg = 0, speed = 11, level = 1, style = "flee", radius = 1.6, passive = true,
		loot = { { "meat", 2, 3, 1 }, { "leather", 1, 2, 1 } } },
	flamingo = { name = "Flamant", model = "Flamant", hp = 40, dmg = 0, speed = 10, level = 1, style = "flee", radius = 0.8, passive = true,
		loot = { { "feather", 2, 3, 1 } } },
	-- boss itinérants (événements de monde)
	harvest_warden = { name = "Gardien des Moissons", model = "Gardien_Moissons", hp = 1400, dmg = 38, speed = 9, level = 7, style = "charge", boss = true, radius = 3, minion = "scarecrow",
		loot = { { "ancient_seed", 2, 4, 1 }, { "enchanted_cloth", 1, 2, 1 }, { "seed_pumpkin", 3, 6, 1 } }, gold = 6 },
	mycelian_king = { name = "Roi Mycélien", model = "Roi_Mycelien", hp = 1800, dmg = 42, speed = 8, level = 8, style = "spore", boss = true, radius = 3.4, minion = "myconid",
		proj = { color = Color3.fromRGB(200, 140, 230), size = 2.4 }, loot = { { "royal_spore", 1, 2, 1 }, { "mushroom", 6, 10, 1 } }, gold = 7 },
	glass_colossus = { name = "Colosse de Verre", model = "Colosse_Verre", hp = 2400, dmg = 50, speed = 8, level = 9, style = "charge", boss = true, radius = 3.6, minion = "scorpion",
		loot = { { "glass_shard", 2, 4, 1 }, { "gold_ore", 4, 8, 1 } }, gold = 8 },
	ice_sleeper = { name = "Dormeur des Glaces", model = "Dormeur_Glaces", hp = 3000, dmg = 55, speed = 7, level = 10, style = "spore", boss = true, radius = 4, minion = "wolf_white",
		proj = { color = Color3.fromRGB(170, 230, 255), size = 3 }, loot = { { "frozen_heart", 1, 1, 1 }, { "ice_crystal", 4, 8, 1 } }, gold = 10 },
	boss_slime = { loot = { { "slime_gel", 5, 8, 1 } }, name = "Roi des Slimes", model = "Roi_Slimes", hp = 700, dmg = 30, speed = 8, level = 6, style = "hop", boss = true, radius = 3.6, minion = "slime_blue" },
	boss_myconid = { name = "Myconide Ancien", model = "Myconide_Ancien", hp = 900, dmg = 40, speed = 9, level = 8, style = "spore", boss = true, radius = 3, minion = "myconid" },
	boss_goblin = { name = "Chef Gobelin", model = "Chef_Gobelin", hp = 1200, dmg = 50, speed = 14, level = 10, style = "charge", boss = true, radius = 2.4, minion = "goblin" },
}
Enemies.KINDS = KINDS

-- Variante visuelle du cerf. L'espèce et l'identifiant d'origine restent
-- communs au troupeau pour la sauvegarde, les prédateurs et les quêtes.
local DOE = table.clone(KINDS.deer)
DOE.name = "Biche"
-- qui chasse qui (faune vivante)
local PREDATORS = {
	wolf = { rabbit = true, deer = true, fox = true },
	wolf_white = { penguin = true, fox = true, rabbit = true },
	bear = { deer = true, rabbit = true },
	croc = { flamingo = true, rabbit = true },
	scorpion = { rabbit = true },
}
local AGGRO = 34
local LEASH = 70
local LOD_NEAR, LOD_FAR = 160, 350 -- au-delà, la créature pense moins souvent (personne ne la voit de près)
local RESPAWN_DAYS = 3

function Enemies.init(g)
	G = g
	-- les soldats utilisent le même moteur que les créatures (déplacement, rendu, barre de vie)
	for id, u in G.Config.UNITS do
		KINDS[id] = { name = u.name, model = u.model, hp = u.hp, dmg = u.dmg, speed = u.speed, level = 3, style = "charge", radius = 1.3, unit = true }
	end
end

local function puff(pos: Vector3, color: Color3, n: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(pos)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(0.8, 0.1)
	e.Speed = NumberRange.new(6, 12)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace
	e:Emit(n)
	Debris:AddItem(p, 1.2)
end

local function healthBar(en)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Vie"
	bb.Size = UDim2.fromOffset(en.boss and 160 or 60, en.boss and 14 or 8)
	bb.StudsOffsetWorldSpace = Vector3.new(0, en.height + 1.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 90
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	bg.BorderSizePixel = 0
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0.5, 0)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = en.boss and Color3.fromRGB(230, 80, 60) or Color3.fromRGB(120, 210, 90)
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5, 0)
	fill.Parent = bg
	bg.Parent = bb
	local k = en.k
	local mood = k.passive and "passif" or ((k.neutral and not en.angry) and "neutre" or "hostile")
	local nameColor = ({ hostile = Color3.fromRGB(255, 90, 70), neutre = Color3.fromRGB(255, 220, 60), passif = Color3.fromRGB(120, 230, 90) })[mood]
	local nm = Instance.new("TextLabel")
	nm.Name = "Nom"
	nm.BackgroundTransparency = 1
	nm.Size = UDim2.new(1, 60, 0, 16)
	nm.Position = UDim2.new(0.5, 0, 0, -18)
	nm.AnchorPoint = Vector2.new(0.5, 0)
	nm.Font = Enum.Font.GothamBold
	nm.TextSize = 13
	nm.TextColor3 = nameColor
	nm.TextStrokeTransparency = 0.3
	nm.Text = k.level .. "  " .. (k.name or "")
	nm.Parent = bg
	bb.Size = UDim2.fromOffset(en.boss and 160 or 80, en.boss and 14 or 8)
	bb.ClipsDescendants = false
	bb.MaxDistance = en.boss and 120 or 45
	bb.Enabled = not k.passive
	bb.Parent = en.model.PrimaryPart
	en.bar = bb
	-- infos lues par le cadre de cible du client
	en.model:SetAttribute("Nom", k.name)
	en.model:SetAttribute("Niveau", k.level)
	en.model:SetAttribute("PV", en.hp)
	en.model:SetAttribute("PVMax", en.maxHp)
	en.model:SetAttribute("Humeur", mood)
end

-- Terrier d'un lapin / renard : butte de terre et trou sombre près de son gîte (décor seul, sans
-- collision). Position tirée de l'id de la bête : la même à chaque chargement.
function Enemies.burrow(en, parent: Instance): Vector3?
	local r = Random.new(G.WG.hash(G.world and G.world.seed or 0, "terrier", en.id))
	local a = r:NextNumber(0, math.pi * 2)
	local x, z = en.home.X + math.cos(a) * r:NextNumber(4, 9), en.home.Z + math.sin(a) * r:NextNumber(4, 9)
	if G.Util.isWater(x, z) then
		return nil
	end
	local y = G.Util.groundY(x, z)
	local m = Instance.new("Model")
	m.Name = "Terrier"
	local function part(size, cf, color, mat, shape)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat
		if shape then
			-- maillage : une butte ovale / un trou rond qui suivent la taille de la pièce (une Part
			-- « Ball » reste une sphère parfaite, une « Cylinder » un tube régulier)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = shape == Enum.PartType.Ball and Enum.MeshType.Sphere or Enum.MeshType.Cylinder
			mesh.Parent = p
		end
		p.Parent = m
		return p
	end
	local yaw = r:NextNumber(0, 360)
	local base = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
	-- assez haut pour dépasser de l'herbe du terrain (sinon invisible)
	part(Vector3.new(4.6, 2.2, 4), base * CFrame.new(0, 0.4, 0.5), Color3.fromRGB(112, 84, 56), Enum.Material.Ground, Enum.PartType.Ball)
	part(Vector3.new(4.2, 1.2, 3.2), base * CFrame.new(0, 1.1, 0.7), Color3.fromRGB(96, 72, 48), Enum.Material.Ground, Enum.PartType.Ball)
	part(Vector3.new(0.3, 1.7, 1.7), base * CFrame.new(0, 0.75, -1.5) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(22, 16, 11), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	for i = 1, 3 do
		part(Vector3.one * r:NextNumber(0.35, 0.6), base * CFrame.new(r:NextNumber(-1.8, 1.8), 0.25, r:NextNumber(-2.6, -1.8)), Color3.fromRGB(120, 110, 100), Enum.Material.Slate)
	end
	m:PivotTo(m:GetPivot())
	m.Parent = parent
	return Vector3.new(x, y, z) + base.LookVector * 1.5 -- l'entrée du trou (−Z local = LookVector)
end

local function spawn(reg, d, parent)
	local k = KINDS[d.kind]
	if not k then
		return
	end
	local model = G.Util.clone(k.model)
	if not model then
		return
	end
	if d.kind == "deer" and G.WG.hash(G.world and G.world.seed or 0, "biche", d.id) % 2 == 0 then
		k = DOE
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and part.Name == "Bois" then
				part:Destroy()
			end
		end
	end
	local dist = reg and math.sqrt(reg.rx * reg.rx + reg.rz * reg.rz) or 0
	local mult = (1 + math.max(0, dist - 2) * 0.12) * (1 + ((G.world and G.world.danger or 1) - 1) * 0.25)
	local y = d.y or G.Util.groundY(d.x, d.z) -- d.y : sol imposé (grottes)
	local _, size = model:GetBoundingBox()
	local en = {
		id = d.id, data = d, kind = d.kind, k = k, reg = reg, model = model,
		hp = math.floor(k.hp * mult), maxHp = math.floor(k.hp * mult), dmg = math.floor(k.dmg * mult),
		pos = Vector3.new(d.x, y, d.z), home = Vector3.new(d.x, y, d.z), yaw = math.random() * 6.28,
		state = "idle", t = 0, goal = nil, boss = k.boss, radius = k.radius, height = size.Y,
		phase = 1, invuln = 0, hop = 0, minionsDone = false,
	}
	model.Name = k.name
	model:SetAttribute("EnemyId", d.id)
	G.Util.tag(model, "Bete") -- empreintes côté client (Traces.client)
	model:PivotTo(CFrame.new(en.pos) * CFrame.Angles(0, en.yaw, 0))
	model.Parent = parent
	healthBar(en)
	if k.burrow and parent then
		en.burrow = Enemies.burrow(en, parent)
	end
	if d.free then
		return en -- compagnon : géré par Compagnons, pas par l'IA sauvage
	end
	table.insert(Enemies.list, en)
	if reg then
		table.insert(reg.enemies, en)
	end
	-- apprivoisement (mini-jeu) pour les bêtes qui s'y prêtent
	local tame = G.Config.TAMING[d.kind]
	if tame and not k.boss then
		en.tamePrompt = G.Util.prompt(model.PrimaryPart, "tame", "Apprivoiser (" .. G.Config.needInfo(tame.bait).icon .. ")", k.name,
			{ data = { Enemy = d.id }, dist = 9, hold = 0.6, key = Enum.KeyCode.T, pad = Enum.KeyCode.ButtonX })
		en.tamePrompt.Enabled = not tame.weak
	end
	return en
end
Enemies.spawn = spawn

function Enemies.spawnFree(kind: string, pos: Vector3, parent: Instance)
	return spawn(nil, { id = "free#" .. math.random(1, 1e9), kind = kind, x = pos.X, z = pos.Z, free = true }, parent)
end

function Enemies.byId(id: string)
	for _, en in Enemies.list do
		if en.id == id and not en.dead then
			return en
		end
	end
	return nil
end

-- Une bête sauvage apprivoisée quitte le monde sauvage (elle repoussera dans quelques jours)
function Enemies.removeWild(en)
	en.dead = true
	if en.reg and not en.transient then
		en.reg.state.enemies[en.id] = G.world.day
	end
	if en.model then
		en.model:Destroy()
	end
end

function Enemies.onRegionLoad(reg)
	local folder = Instance.new("Folder")
	folder.Name = "Monstres"
	folder.Parent = reg.folder
	reg.enemyFolder = folder
	reg.enemies = {}
	for _, d in reg.plan.enemies do
		local dead = reg.state.enemies[d.id]
		local k = KINDS[d.kind]
		if dead and k and not k.boss and G.world.day >= dead + RESPAWN_DAYS then
			reg.state.enemies[d.id] = nil
			dead = nil
		end
		if not dead then
			spawn(reg, d, folder)
		end
	end
end

function Enemies.onRegionUnload(reg)
	for _, en in reg.enemies or {} do
		en.dead = true
		local i = table.find(Enemies.list, en)
		if i then
			table.remove(Enemies.list, i)
		end
	end
end

local function nearestPlayer(en): (Player?, number)
	return G.Util.nearestPlayer(en.pos, AGGRO * 1.6)
end

-- Hauteur du sol pour une créature : sous terre (grottes), c'est le sol de la galerie, ou nil
-- contre une paroi ; en surface, le relief.
local function floorFor(en, x: number, z: number): number?
	if en.pos.Y < -40 then
		return G.Donjons.floorAt(x, z, en.pos.Y)
	end
	if G.Util.isWater(x, z) then
		return nil
	end
	return G.Util.groundY(x, z)
end
Enemies.floorFor = floorFor

local function moveToward(en, target: Vector3, speed: number, dt: number)
	local d = Vector3.new(target.X - en.pos.X, 0, target.Z - en.pos.Z)
	if d.Magnitude < 0.2 then
		return
	end
	local step = math.min(d.Magnitude, speed * dt)
	local np = en.pos + d.Unit * step
	local ny = floorFor(en, np.X, np.Z)
	if not ny then
		return
	end
	-- pas de falaise à escalader
	if math.abs(ny - en.pos.Y) > 4 then
		return
	end
	en.pos = Vector3.new(np.X, ny, np.Z)
	en.yaw = math.atan2(-d.X, -d.Z)
end

local function render(en)
	if not en.model or not en.model.Parent then
		return
	end
	local lift = 0
	if en.k.style == "hop" then
		lift = math.abs(math.sin(en.hop)) * (en.boss and 3 or 1.5)
	end
	local shake = CFrame.identity
	if en.state == "windup" then
		-- pose d'annonce : il tremble et brille
		shake = CFrame.Angles(0, 0, math.sin(en.t * 40) * 0.12)
		if en.model.PrimaryPart and not en.model.PrimaryPart:FindFirstChild("Alerte") then
			local a = Instance.new("BillboardGui")
			a.Name = "Alerte"
			a.Size = UDim2.fromOffset(40, 40)
			a.StudsOffsetWorldSpace = Vector3.new(0, en.height + 3, 0)
			a.AlwaysOnTop = true
			a.MaxDistance = 60
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.fromScale(1, 1)
			t.Text = "❗"
			t.TextScaled = true
			t.Parent = a
			a.Parent = en.model.PrimaryPart
		end
		if not en.model:FindFirstChild("Annonce") then
			local h = Instance.new("Highlight")
			h.Name = "Annonce"
			h.FillColor = Color3.fromRGB(255, 240, 150)
			h.FillTransparency = 0.5
			h.OutlineColor = Color3.fromRGB(255, 200, 60)
			h.Parent = en.model
		end
	else
		local h = en.model:FindFirstChild("Annonce")
		if h then
			h:Destroy()
		end
		local a = en.model.PrimaryPart and en.model.PrimaryPart:FindFirstChild("Alerte")
		if a then
			a:Destroy()
		end
	end
	-- rien n'a bougé : pas de PivotTo (chaque déplacement de modèle part sur le réseau vers tous)
	local windup = en.state == "windup"
	if not windup and not en.lastWindup and en.lastLift == lift and en.lastYaw == en.yaw and en.lastPos and (en.pos - en.lastPos).Magnitude < 0.02 then
		return
	end
	en.lastPos, en.lastYaw, en.lastLift, en.lastWindup = en.pos, en.yaw, lift, windup
	en.model:PivotTo(CFrame.new(en.pos + Vector3.new(0, lift, 0)) * CFrame.Angles(0, en.yaw, 0) * shake)
end

Enemies.move = moveToward
Enemies.render = render

local function flash(en)
	local h = Instance.new("Highlight")
	h.FillColor = Color3.fromRGB(255, 80, 60)
	h.FillTransparency = 0.3
	h.OutlineTransparency = 1
	h.Parent = en.model
	Debris:AddItem(h, 0.18)
end

local function spore(en, target: Vector3)
	local pj = en.k.proj or {}
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * (en.boss and 2.2 or (pj.size or 1.2))
	p.Color = pj.color or Color3.fromRGB(190, 120, 220)
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	local from = en.pos + Vector3.new(0, en.height * 0.6, 0)
	p.CFrame = CFrame.new(from)
	p.Parent = workspace
	local tw = TweenService:Create(p, TweenInfo.new(pj.fast and 0.5 or 0.9, Enum.EasingStyle.Linear), { CFrame = CFrame.new(target + Vector3.new(0, 1, 0)) })
	tw:Play()
	tw.Completed:Connect(function()
		puff(p.Position, p.Color, 16)
		for _, pl in G.Game.players() do
			local r = G.Util.root(pl)
			if r and (r.Position - p.Position).Magnitude < (en.boss and 6 or 4) then
				G.Combat.hurtPlayer(pl, en.dmg, p.Position)
				-- poison / toile : ralenti 3 s (effet bref et lisible, jamais permanent)
				if pj.poison then
					if (pl:GetAttribute("SlowUntil") or 0) < os.clock() then
						G.Util.toast(pl, "🕸️ Empoisonné : tu ralentis…", "danger")
					end
					pl:SetAttribute("SlowUntil", os.clock() + 3)
				end
			end
		end
		p:Destroy()
	end)
end

-- Animal sauvage : broute, s'enfuit quand on approche ou qu'on le frappe
local function thinkPassive(en, dt: number)
	local k = en.k
	if en.state == "hidden" then
		-- au fond du terrier : il ressort quand plus personne n'est près de l'entrée (8 s au moins)
		local b = en.burrow
		local _, near = G.Util.nearestPlayer(b or en.pos, 14)
		if not b or (en.t > 8 and near >= 14) then
			en.state = "idle"
			en.t = 0
			en.pos = b or en.home
			render(en)
		end
		return
	end
	local player, pd = G.Util.nearestPlayer(en.pos, 40)
	local proot = player and G.Util.root(player)
	local scared = proot and (pd < (player:GetAttribute("Crouch") and 7 or 15) or en.state == "hurt" or en.state == "flee")
	if scared and proot then
		if en.state ~= "flee" then
			en.state = "flee"
			en.t = 0
		end
		local away = en.pos - proot.Position
		away = Vector3.new(away.X, 0, away.Z)
		if away.Magnitude < 0.1 then
			away = Vector3.new(1, 0, 0)
		end
		local b = en.burrow
		if b and (b - en.pos).Magnitude < 30 then
			-- il file vers son terrier et s'y cache (jusqu'à ce que le calme revienne)
			moveToward(en, b, k.speed * 1.1, dt)
			if (Vector3.new(b.X - en.pos.X, 0, b.Z - en.pos.Z)).Magnitude < 1.2 then
				en.state = "hidden"
				en.t = 0
				en.pos = b - Vector3.new(0, 4, 0)
				puff(b + Vector3.new(0, 0.5, 0), Color3.fromRGB(120, 90, 60), 6)
				render(en)
				return
			end
		else
			moveToward(en, en.pos + away.Unit * 8, k.speed, dt)
		end
		en.hop += dt * 10
		if en.t > 4 and pd > 20 then
			en.state = "idle"
			en.t = 0
		end
	else
		en.state = "idle"
		if not en.goal or en.t > 5 then
			en.t = 0
			en.goal = en.home + Vector3.new(math.random(-14, 14), 0, math.random(-14, 14))
		end
		moveToward(en, en.goal, k.speed * 0.25, dt)
	end
	if en.bar then
		en.bar.Enabled = not en.k.passive or en.hp < en.maxHp
		local pv = math.max(0, en.hp)
		if en.barPv ~= pv then -- (barre et attribut renvoyés seulement s'ils changent)
			en.barPv = pv
			en.bar.Frame.Fill.Size = UDim2.fromScale(pv / en.maxHp, 1)
			en.model:SetAttribute("PV", pv)
		end
	end
	render(en)
end

local function think(en, dt: number)
	en.t += dt
	en.invuln -= dt
	local k = en.k
	if k.passive then
		thinkPassive(en, dt)
		return
	end
	if k.custom then
		return -- piloté par Protection (cambrioleur)
	end
	-- les ombres fuient la lumière (lanternes, feux)
	if k.fearsLight and G.Protection and G.Protection.lightNear(en.pos, 16) then
		local away = en.pos - (G.Protection.lightNear(en.pos, 16) :: Vector3)
		away = Vector3.new(away.X, 0, away.Z)
		if away.Magnitude > 0.1 then
			moveToward(en, en.pos + away.Unit * 6, k.speed, dt)
		end
		render(en)
		return
	end
	local speed = k.speed * (en.phase == 2 and 1.3 or 1)
	local player, pd = nearestPlayer(en)
	local proot = player and G.Util.root(player)
	local far = (en.pos - en.home).Magnitude > LEASH
	if en.state == "hurt" then
		if en.t > 0.25 then
			en.state = "chase"
			en.t = 0
		end
	elseif en.state == "hunt" then
		-- un prédateur poursuit sa proie (cerf, lapin…)
		local prey = en.prey
		if not prey or prey.dead or prey.state == "hidden" or (prey.pos - en.pos).Magnitude > 50 or far then -- (réfugié au terrier : perdu)
			en.prey = nil
			en.state = "idle"
			en.t = 0
		else
			moveToward(en, prey.pos, speed * 1.05, dt)
			en.hop += dt * 8
			if (prey.pos - en.pos).Magnitude < en.radius + prey.radius + 0.8 then
				prey.dead = true
				if prey.reg then
					prey.reg.state.enemies[prey.id] = G.world.day -- reviendra dans quelques jours
				end
				puff(prey.pos + Vector3.new(0, prey.height / 2, 0), Color3.fromRGB(150, 110, 90), 14)
				prey.model:Destroy()
				en.prey = nil
				en.state = "idle"
				en.t = 0
			end
		end
	elseif en.state == "idle" then
		-- un prédateur affamé repère le gibier
		if PREDATORS[en.kind] and not en.pet and en.t > 2 and math.random() < 0.02 then
			for _, other in Enemies.list do
				if other.k.passive and not other.dead and PREDATORS[en.kind][other.kind] and (other.pos - en.pos).Magnitude < 30 then
					en.prey = other
					en.state = "hunt"
					en.t = 0
					break
				end
			end
		end
		if proot and pd < AGGRO and not far and (not k.neutral or en.angry) then
			en.state = "chase"
			en.t = 0
		else
			if not en.goal or en.t > 4 then
				en.t = 0
				en.goal = en.home + Vector3.new(math.random(-12, 12), 0, math.random(-12, 12))
			end
			moveToward(en, en.goal, speed * 0.4, dt)
			en.hop += dt * 5
		end
	elseif en.state == "chase" then
		if not proot or pd > AGGRO * 1.5 or far then
			en.state = "return"
			en.t = 0
		else
			local range = k.style == "spore" and 22 or (k.style == "charge" and 14 or 4 + en.radius)
			if pd < range and en.t > 0.4 then
				en.state = "windup"
				en.t = 0
				en.target = proot.Position
			elseif k.style ~= "spore" or pd > 14 then
				moveToward(en, proot.Position, speed, dt)
				en.hop += dt * 7
			end
		end
	elseif en.state == "windup" then
		-- pose d'annonce : le joueur peut s'écarter
		if proot then
			en.target = proot.Position
			local d = proot.Position - en.pos
			en.yaw = math.atan2(-d.X, -d.Z)
		end
		if en.t > (k.style == "charge" and 0.6 or 0.5) then
			en.state = "attack"
			en.t = 0
			if k.style == "spore" and en.target then
				spore(en, en.target)
				if en.boss and en.phase == 2 then
					spore(en, en.target + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
				end
			end
		end
	elseif en.state == "attack" then
		local dur = k.style == "charge" and 0.5 or 0.35
		if k.style ~= "spore" and en.target then
			moveToward(en, en.target, speed * (k.style == "charge" and 3.2 or 2.2), dt)
			en.hop += dt * 10
			for _, pl in G.Game.players() do
				local r = G.Util.root(pl)
				if r and (r.Position - en.pos).Magnitude < en.radius + 2.5 then
					G.Combat.hurtPlayer(pl, en.dmg, en.pos)
				end
			end
			for _, pet in G.Compagnons.list do
				if not pet.dead and (pet.pos - en.pos).Magnitude < en.radius + 2.5 then
					G.Compagnons.hurt(pet, math.floor(en.dmg * 0.5))
				end
			end
		end
		if en.t > dur then
			en.state = "recover"
			en.t = 0
		end
	elseif en.state == "recover" then
		if en.t > (en.phase == 2 and 0.4 or 0.7) then
			en.state = "chase"
			en.t = 0
		end
	elseif en.state == "return" then
		moveToward(en, en.home, speed, dt)
		en.hop += dt * 6
		en.hp = math.min(en.maxHp, en.hp + en.maxHp * 0.1 * dt)
		if (en.pos - en.home).Magnitude < 3 then
			en.state = "idle"
			en.t = 0
		end
	end
	if en.bar then
		en.bar.Enabled = not en.k.passive or en.hp < en.maxHp
		local pv = math.max(0, en.hp)
		if en.barPv ~= pv then -- (barre et attribut renvoyés seulement s'ils changent)
			en.barPv = pv
			en.bar.Frame.Fill.Size = UDim2.fromScale(pv / en.maxHp, 1)
			en.model:SetAttribute("PV", pv)
		end
	end
	render(en)
end

local acc = 0
function Enemies.step(dt: number)
	Enemies.nightStep(dt)
	acc += dt
	if acc < 1 / 30 then
		return
	end
	local step = acc
	acc = 0
	for i = #Enemies.list, 1, -1 do
		local en = Enemies.list[i]
		if en.dead or not en.model.Parent then
			table.remove(Enemies.list, i)
		else
			-- niveau de détail : près d'un joueur (ou en plein combat, ou boss) à 30 Hz ; plus loin,
			-- 6 Hz puis 1 Hz avec un pas de temps cumulé (même trajet, moins de calculs et de réseau)
			local interval = 0
			local st = en.state
			if not (en.boss or en.pet or st == "chase" or st == "windup" or st == "hurt" or st == "flee") then
				local d = G.Util.playerDist(en.pos)
				interval = d < LOD_NEAR and 0 or (d < LOD_FAR and 1 / 6 or 1)
			end
			en.lodAcc = (en.lodAcc or 0) + step
			if en.lodAcc >= interval then
				local dt2 = math.min(en.lodAcc, 1.5)
				en.lodAcc = 0
				local ok, err = pcall(think, en, dt2)
				if not ok then
					warn("[WildAcres] monstre : " .. tostring(err))
					en.dead = true
				end
			end
		end
	end
end

local function dieInner(en, player: Player)
	en.dead = true
	if not en.transient then
		en.reg.state.enemies[en.id] = G.world.day
	end
	puff(en.pos + Vector3.new(0, en.height / 2, 0), Color3.fromRGB(200, 200, 200), en.boss and 60 or 20)
	en.model:Destroy()
	local k = en.k
	local luck = G.Joueurs.stats(player).chance or 0
	if not k.passive then
		G.Joueurs.add(player, "gold", math.random(5, 15) * k.level * (k.gold or 1))
	end
	local rng = Random.new()
	for _, l in k.loot or {} do
		if rng:NextNumber() < l[4] + luck * 0.02 then
			G.Joueurs.add(player, l[1], rng:NextInteger(l[2], l[3]))
		end
	end
	G.Util.finds(player, "hunt", en.pos)
	-- prise propre à la créature (matière de fabrication) ; âme rare des boss (pièce légendaire)
	local pr = G.Config.Prises and G.Config.Prises.KINDS[en.kind]
	if pr then
		local chance = en.boss and 1 or (k.elite and 0.7 or 0.35)
		if rng:NextNumber() < chance + luck * 0.01 then
			G.Joueurs.add(player, pr.mat, en.boss and rng:NextInteger(2, 3) or 1)
		end
		if pr.soul and en.boss and rng:NextNumber() < 0.5 + luck * 0.02 then
			G.Joueurs.add(player, pr.soul.id, 1)
			G.Util.toast(player, "🔮 " .. pr.soul.name .. " ! (pièce légendaire à l'enclume)", "big")
		end
	end
	G.Social.collect(player, "creatures", en.kind)
	if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "tuer", en.kind) end
	if not k.passive and en.pos then
		-- un monstre de moins autour du village : ses gens s'en souviennent
		G.Reputation.addAt(player, en.pos, (en.boss and 5) or (k.elite and 2) or 1, "chasse")
	end
	if en.boss then
		for _ = 1, 2 do
			G.Joueurs.addGear(player, G.Gear.roll(rng, math.min(10, k.level + 1)))
		end
		G.Joueurs.add(player, "ore", 3)
		G.Law.addHonor(player, 10)
		G.Util.toast(player, k.name .. " est vaincu ! Les villages alentour respirent.", "big")
	elseif not k.passive and rng:NextNumber() < (k.elite and 0.5 or 0.1) + luck * 0.02 + ((G.world.danger or 1) - 1) * 0.03 then
		G.Joueurs.addGear(player, G.Gear.roll(rng, math.min(10, k.level + (k.elite and 1 or 0))))
	end
	G.Joueurs.addSkillXp(player, "combat", 4 * k.level)
	-- un cambrioleur rend ce qu'il a volé
	for item, n in en.loot or {} do
		G.Joueurs.add(player, item, n)
	end
	if en.loot and next(en.loot) then
		G.Util.toast(player, "Tu récupères le butin du cambrioleur !", "big")
	end
end

-- Le butin d'une créature tombe à terre là où elle meurt (ramassage : Systemes/Butin)
local function die(en, player: Player)
	G.Util.auSol(player, en.pos, en.model, dieInner, en, player)
	-- boss : chaque autre participant (≥ 10 % des dégâts, encore présent) reçoit sa propre part
	-- (pièce d'équipement + minerai + honneur), dans son sac — personne ne repart les mains vides
	if en.boss and en.hitters then
		local total = 0
		for _, d in en.hitters do
			total += d
		end
		local rng = Random.new()
		for p, d in en.hitters do
			if p ~= player and p.Parent and total > 0 and d / total >= 0.1 then
				G.Joueurs.addGear(p, G.Gear.roll(rng, math.min(10, en.k.level + 1)))
				G.Joueurs.add(p, "ore", 2)
				local pr = G.Config.Prises and G.Config.Prises.KINDS[en.kind]
				if pr then
					G.Joueurs.add(p, pr.mat, 1)
				end
				G.Joueurs.addSkillXp(p, "combat", 4 * en.k.level)
				G.Law.addHonor(p, 5)
				G.Joueurs.sync(p)
				G.Util.toast(p, en.k.name .. " est vaincu : ta part du butin t'attend dans ton sac.", "big")
			end
		end
	end
end

function Enemies.hit(en, dmg: number, player: Player)
	if en.dead or en.invuln > 0 then
		return
	end
	en.invuln = 0.25
	en.angry = true
	-- qui a participé (partage du butin des boss en groupe)
	if player then
		en.hitters = en.hitters or {}
		en.hitters[player] = (en.hitters[player] or 0) + dmg
	end
	en.hp -= dmg
	if en.pos then
		G.Util.sfx("coup", en.pos + Vector3.new(0, 2, 0))
	end
	en.model:SetAttribute("PV", math.max(0, en.hp))
	if en.model:GetAttribute("Humeur") == "neutre" then
		en.model:SetAttribute("Humeur", "hostile")
		local nm = en.bar and en.bar:FindFirstChild("Nom", true)
		if nm then
			nm.TextColor3 = Color3.fromRGB(255, 90, 70)
		end
	end
	local tame = G.Config.TAMING[en.kind]
	if en.tamePrompt and tame and tame.weak then
		en.tamePrompt.Enabled = en.hp > 0 and en.hp <= en.maxHp * tame.weak
	end
	if en.k.custom and G.Protection then
		G.Protection.burglarHit(en, player)
	end
	flash(en)
	G.Combat.popup(en.pos + Vector3.new(0, en.height, 0), tostring(dmg), Color3.fromRGB(255, 230, 120))
	if en.hp <= 0 then
		die(en, player)
		return
	end
	-- recul
	local root = G.Util.root(player)
	if root and not en.boss and not en.k.passive then
		local away = en.pos - root.Position
		away = Vector3.new(away.X, 0, away.Z)
		if away.Magnitude > 0.1 then
			local np = en.pos + away.Unit * 5
			local ny = floorFor(en, np.X, np.Z)
			if ny then
				en.pos = Vector3.new(np.X, ny, np.Z)
			end
		end
		en.state = "hurt"
		en.t = 0
	elseif en.state == "idle" then
		en.state = "chase"
		en.t = 0
	end
	-- boss : 2e phase à la moitié de sa vie
	if en.boss and en.phase == 1 and en.hp < en.maxHp / 2 then
		en.phase = 2
		G.Util.toast(player, en.k.name .. " devient furieux !", "danger")
		if not en.minionsDone then
			en.minionsDone = true
			for i = 1, 2 do
				spawn(en.reg, { id = en.id .. "+" .. i .. "_" .. G.world.day, kind = en.k.minion, x = en.pos.X + math.random(-6, 6), z = en.pos.Z + math.random(-6, 6),
					y = en.pos.Y < -40 and en.pos.Y or nil }, en.model.Parent or en.reg.enemyFolder)
			end
		end
	end
end

-- ----------------------------------------------------------------- Nuit

-- La nuit, des épouvantails maudits (champs) et des ombres rôdeuses sortent autour des joueurs,
-- jamais dans les villages, les parcelles ni près d'une lumière. À l'aube ils se dissipent.
local nightAcc = 0
local nightN = 0
local NIGHT_MAX = 3

local function inSafePlace(pos: Vector3): boolean
	local reg = G.World.regionAt(pos)
	if not reg then
		return true
	end
	local cx, cz = G.WG.cellOf(pos)
	local i = G.WG.idx(cx - reg.plan.x0, cz - reg.plan.z0)
	if (reg.plan.poiW[i] or 0) > 0.2 then
		return true
	end
	return G.Parcelles.at(pos) ~= nil
end

function Enemies.nightStep(dt: number)
	nightAcc += dt
	if nightAcc < 5 then
		return
	end
	nightAcc = 0
	local night = G.Clock.isNight()
	if not night then
		-- l'aube : les épouvantails s'effondrent en paille, les ombres se dissipent
		for _, en in Enemies.list do
			if en.night and not en.dead then
				local color = en.kind == "scarecrow" and Color3.fromRGB(220, 190, 110) or Color3.fromRGB(60, 50, 80)
				puff(en.pos + Vector3.new(0, en.height / 2, 0), color, 24)
				en.dead = true
				en.model:Destroy()
			end
		end
		return
	end
	for _, player in G.Game.players() do
		local root = G.Util.root(player)
		if root then
			local near = 0
			for _, en in Enemies.list do
				if en.night and not en.dead and (en.pos - root.Position).Magnitude < 70 then
					near += 1
				end
			end
			if near < NIGHT_MAX and math.random() < 0.6 then
				local a = math.random() * math.pi * 2
				local r = math.random(30, 46)
				local pos = root.Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				local reg = G.World.regionAt(pos)
				if reg and reg.ready and not G.Util.isWater(pos.X, pos.Z) and not inSafePlace(pos) and not G.Protection.lightNear(pos, 20) then
					local b = G.Clock.biomeAt(pos)
					local kind = G.Bestiaire.nightKind(b) or ((b == "prairie" or b == "foret") and (math.random() < 0.55 and "scarecrow" or "shade") or "shade")
					nightN += 1
					local en = spawn(reg, { id = "nuit#" .. nightN, kind = kind, x = pos.X, z = pos.Z }, reg.enemyFolder)
					if en then
						en.transient = true
						en.night = true -- s'effondre à l'aube (les autres créatures de passage, non)
						en.state = "chase"
					end
				end
			end
		end
	end
end

return Enemies
