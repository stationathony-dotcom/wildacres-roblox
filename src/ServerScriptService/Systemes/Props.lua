-- Tout ce qui se récolte dans le monde (au clic, maintenu = coups en continu, ou à l'invite [E] :
-- 1 appui = 1 coup ; résistance variable, cf. « résistance et grind ») : arbres (hache → souche), souches,
-- rochers (pioche), branches, cailloux, touffes, fleurs, champignons, buissons à baies
-- (se regarnissent), troncs couchés, coffres (vol si quelqu'un en est propriétaire).
-- Ce qui est récolté disparaît ; les petites choses repoussent au bout de quelques jours.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Props = {}
local G

local FRUIT_DAYS = 3
local KINDS = {
	tree_chene = { model = "Arbre_Chene", tree = true, wood = { 4, 6 } },
	tree_sapin = { model = "Arbre_Sapin", tree = true, wood = { 3, 5 } },
	tree_bouleau = { model = "Arbre_Bouleau", tree = true, wood = { 3, 5 } },
	tree_cerisier = { model = "Arbre_Cerisier", tree = true, wood = { 3, 4 }, fruit = true }, -- fruitier : cueillette tous les 3 jours
	tree_mort = { model = "Arbre_Mort", tree = true, wood = { 2, 3 } },
	tree_saule = { model = "Arbre_Saule", tree = true, wood = { 3, 5 } },
	cactus = { model = "Cactus", verb = "Couper", tool = "axe", hits = 2, gives = { fiber = { 2, 3 } }, respawn = 5 },
	stump = { model = "Souche", verb = "Arracher la souche", tool = "axe", hits = 2, gives = { wood = { 1, 2 } } },
	rock = { model = "Rocher", verb = "Miner", tool = "pickaxe", hits = 3, gives = { stone = { 3, 5 } }, coal = 0.25, respawn = 5 },
	-- filons (palier de pioche minimum : 1 pierre, 2 cuivre, 3 fer)
	ore_coal = { model = "Filon_Charbon", verb = "Miner", tool = "pickaxe", hits = 3, gives = { coal = { 2, 4 }, stone = { 1, 2 } }, respawn = 5 },
	ore_copper = { model = "Filon_Cuivre", verb = "Miner", tool = "pickaxe", skill = 3, hits = 4, gives = { copper_ore = { 2, 3 }, stone = { 1, 2 } }, respawn = 6 },
	ore_iron = { model = "Filon_Fer", verb = "Miner", tool = "pickaxe", tier = 2, skill = 12, hits = 5, gives = { ore = { 2, 3 }, stone = { 1, 2 } }, respawn = 7 },
	ore_gold = { model = "Filon_Or", verb = "Miner", tool = "pickaxe", tier = 3, skill = 25, hits = 6, gives = { gold_ore = { 1, 3 } }, respawn = 9 },
	clay = { model = "Argile", verb = "Creuser l'argile", tool = "shovel", hits = 2, gives = { clay = { 2, 4 } }, respawn = 3 },
	stone = { model = "Caillou", verb = "Ramasser", gives = { stone = { 1, 1 } }, respawn = 4 },
	stick = { model = "Branche", verb = "Ramasser", gives = { wood = { 1, 1 } }, respawn = 4 },
	log = { model = "Tronc_Couche", verb = "Débiter", tool = "axe", hits = 2, gives = { wood = { 3, 4 } } },
	tuft = { model = "Touffe", verb = "Arracher", gives = { fiber = { 1, 2 } }, respawn = 3 },
	flower = { model = "Fleurs", verb = "Cueillir", gives = { flower = { 1, 1 } }, respawn = 5 },
	mushroom = { model = "Champignon", verb = "Cueillir", gives = { mushroom = { 1, 1 } }, respawn = 4 },
	bush = { model = "Buisson", bush = true },
	-- plante sauvage (Systemes/Herbes) : l'objet donné, la compétence requise et la couleur sont
	-- portés par l'exemplaire (p.herb, p.skill, p.color) ; repousse comme un filon
	herb = { model = "Herbe_Sauvage", verb = "Cueillir", herb = true, respawn = 4 },
	chest = { model = "Coffre", chest = true },
}
Props.KINDS = KINDS
local TOOL_NAMES = { axe = "une hache", pickaxe = "une pioche", shovel = "une pelle" }
local TIER_NAMES = { [2] = "de cuivre", [3] = "de fer" }
local TOOL_HINT = { axe = "(atelier : 3 bois + 2 pierres)", pickaxe = "(atelier : 2 bois + 4 pierres)", shovel = "(atelier : 2 bois + 3 pierres)" }
local FLOWER_COLORS = { Color3.fromRGB(240, 220, 80), Color3.fromRGB(240, 120, 160), Color3.fromRGB(150, 120, 230), Color3.fromRGB(250, 250, 250), Color3.fromRGB(240, 110, 60) }
-- Monde fini : ce qu'on coupe ou mine ne revient pas tout seul (on peut nettoyer une zone pour de bon ;
-- pour reboiser, il faudra planter). Seuls les buissons à baies se regarnissent.
local TREE_REGROW = math.huge
local BERRY_REGROW = 2

local live = {} -- id -> {model, data, reg, hits}

function Props.init(g)
	G = g
	G.Interact.onPrompt("prop", function(player, prompt)
		Props.harvest(player, prompt:GetAttribute("Id"), prompt:GetAttribute("Mode"))
	end)
	-- clic sur l'objet, façon Minecraft (mains nues ; avec un outil, c'est Props.toolHit)
	game:GetService("Players").PlayerRemoving:Connect(function(pl)
		lastHit[pl], handHint[pl] = nil, nil
	end)
	G.Interact.onAction("prop_clic", function(player, data)
		if type(data) == "table" and type(data.id) == "string" then
			Props.click(player, data.id)
		end
	end)
end

local function rand(range): number
	return math.random(range[1], range[2])
end

local function chips(pos: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(pos)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(0.35, 0.1)
	e.Speed = NumberRange.new(8, 14)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = Vector3.new(0, -40, 0)
	e.Lifetime = NumberRange.new(0.4, 0.7)
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace
	e:Emit(14)
	Debris:AddItem(p, 1)
end

local function shake(model: Model)
	local pivot = model:GetPivot()
	task.spawn(function()
		for i = 1, 4 do
			if not model.Parent then
				return
			end
			model:PivotTo(pivot * CFrame.Angles(0, 0, math.rad((i % 2 == 0) and 2 or -2)))
			task.wait(0.04)
		end
		if model.Parent then
			model:PivotTo(pivot)
		end
	end)
end

-- Joue l'animation d'outil si l'outil est en main
function Props.swing(player: Player, itemId: string?)
	local char = player.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	if tool and (not itemId or tool:GetAttribute("ItemId") == itemId) then
		local v = Instance.new("StringValue")
		v.Name = "toolanim"
		v.Value = "Slash"
		v.Parent = tool
		Debris:AddItem(v, 0.5)
	end
end

local function setPrompt(entry)
	local model, p = entry.model, entry.data
	local k = KINDS[p.kind]
	for _, old in model:GetDescendants() do
		if old:IsA("ProximityPrompt") then
			old:Destroy()
		end
	end
	local st = entry.reg.state.props[p.id]
	local base = model.PrimaryPart
	local cf = model:GetPivot()
	local function add(text, mode, hold, h)
		local a = G.Util.anchor(model, cf * CFrame.new(0, h or 2, 0), "Invite")
		G.Util.prompt(a, "prop", text, nil, { hold = hold or 0, data = { Id = p.id, Mode = mode }, dist = k and k.tree and 10 or 8 })
	end
	if k.tree then
		if st and st.stump then
			add("Arracher la souche", "stump", 0, 1.5)
		else
			add("Couper", "chop", 0, 3)
			-- arbre fruitier (pérenne) : on cueille sans l'abattre, il se regarnit en 3 jours
			if k.fruit and not (st and st.fruitDay and G.world.day - st.fruitDay < FRUIT_DAYS) then
				local a = G.Util.anchor(model, cf * CFrame.new(0, 1.6, 0), "Invite")
				G.Util.prompt(a, "prop", "Cueillir les fruits", nil, { hold = 0.3, data = { Id = p.id, Mode = "fruit" }, key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonY })
			end
		end
	elseif k.bush then
		local berries = not (st and st.empty)
		if berries then
			add("Cueillir les baies", "berries", 0, 2.4)
		end
		local a = G.Util.anchor(model, cf * CFrame.new(0, 1.2, 0), "Invite")
		G.Util.prompt(a, "prop", "Arracher (pelle)", nil, { hold = 0.8, data = { Id = p.id, Mode = "dig" }, key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonY })
	elseif k.chest then
		if not entry.reg.state.chests[p.id] then
			add(p.owner and "Ouvrir (vol)" or "Ouvrir", "open", p.owner and 0.8 or 0, 2.6)
		end
	else
		add(k.verb, "take", 0, (p.kind == "rock" or p.kind == "log") and 3 or 1.2)
	end
	if base then
		base:SetAttribute("PropId", p.id)
	end
end

local function build(reg, p, parent: Instance)
	local k = KINDS[p.kind]
	if not k then
		return
	end
	local st = reg.state.props[p.id]
	local modelName = k.model
	if k.tree and st and st.stump then
		modelName = "Souche"
	end
	local model = G.Util.clone(modelName)
	if not model then
		return
	end
	if p.scale and not (st and st.stump) then
		model:ScaleTo(p.scale)
	end
	model.Name = p.kind
	local y = G.Util.groundY(p.x, p.z) - 0.2
	G.World.place(model, p.x, y, p.z, p.yaw or 0, parent)
	if p.kind == "flower" then
		local c = FLOWER_COLORS[p.variant or 1] or FLOWER_COLORS[1]
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "Petale" then
				d.Color = c
			end
		end
	elseif k.bush and st and st.empty then
		for _, d in model:GetDescendants() do
			if d.Name == "Baie" then
				d.Transparency = 1
			end
		end
	elseif k.chest and reg.state.chests[p.id] then
		local lid = model:FindFirstChild("Couvercle")
		if lid then
			lid.CFrame = lid.CFrame * CFrame.new(0, 0.6, -0.6) * CFrame.Angles(math.rad(-60), 0, 0)
		end
	end
	G.Clock.seasonize(model)
	-- filons : repérables sur la minicarte selon la compétence de minage (façon WoW)
	if string.sub(p.kind, 1, 4) == "ore_" then
		model:SetAttribute("MinSkill", k.skill or 0)
		G.Util.tag(model, "Filon")
	elseif k.herb then
		-- plante sauvage : couleur de ses fleurs, repérage sur la minicarte (agriculture)
		if typeof(p.color) == "Color3" then
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Fleur" then
					d.Color = p.color
				end
			end
		end
		model:SetAttribute("MinSkill", p.skill or 0)
		model:SetAttribute("Herbe", p.herb)
		G.Util.tag(model, "Herbe")
	end
	local entry = { model = model, data = p, reg = reg, hits = 0 }
	live[p.id] = entry
	reg.props = reg.props or {}
	reg.props[p.id] = entry
	setPrompt(entry)
	return entry
end

local loadPlanted -- plantations d'arbres (défini plus bas)

-- Rien ne repousse tout seul (monde fini : on replante les arbres)… sauf les FILONS, façon WoW :
-- un filon miné revient au même endroit au bout de quelques jours (KINDS[...].respawn).
local function canRespawn(p, removedDay: number): boolean
	local k = KINDS[p.kind]
	if k and (string.sub(p.kind, 1, 4) == "ore_" or k.herb) then
		return G.world.day >= removedDay + (k.respawn or 6)
	end
	return false
end

function Props.onRegionLoad(reg)
	local folder = Instance.new("Folder")
	folder.Name = "Objets"
	folder.Parent = reg.folder
	reg.propFolder = folder
	local st = reg.state
	for _, s in st.props do
		if s.stump and G.world.day >= (s.day or 0) + TREE_REGROW then
			s.stump = nil
		end
		if s.empty and G.world.day >= (s.day or 0) + BERRY_REGROW then
			s.empty = nil
		end
	end
	local n = 0
	for _, p in reg.plan.props do
		local removed = st.removed[p.id]
		if removed and canRespawn(p, removed) then
			st.removed[p.id] = nil
			removed = nil
		end
		if not removed then
			build(reg, p, folder)
			n += 1
			if n % 30 == 0 then
				task.wait()
			end
		end
	end
	loadPlanted(reg)
	-- coffres des ruines (posés dans la maison)
	for _, h in reg.plan.houses do
		if h.chest and reg.houses[h.id] then
			local model = reg.houses[h.id].model
			local spot = model.PrimaryPart:FindFirstChild(h.chest.spot or "")
			if spot then
				local pos = spot.WorldPosition
				h.chest.x, h.chest.z = pos.X, pos.Z
				h.chest.yaw = h.yaw
				local e = build(reg, h.chest, folder)
				if e then
					e.model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(h.yaw), 0))
					setPrompt(e)
				end
			end
		end
	end
end

-- ----------------------------------------------------------------- Plantations d'arbres
-- reg.state.planted = { {id, kind, x, z, yaw, day} } : pousse les 3 premiers jours, puis un vrai arbre
local GROW_DAYS = 3
local saplings = {} -- id de plantation -> modèle de la pousse (hors de l'état sauvegardé)

local function sapling(reg, t)
	local m = Instance.new("Model")
	m.Name = "Pousse"
	local y = G.Util.groundY(t.x, t.z)
	local function P(size, off, color, mat, shape)
		local p = Instance.new("Part")
		p.Size = size
		p.CFrame = CFrame.new(t.x, y, t.z) * CFrame.new(off)
		p.Color = color
		p.Material = mat
		p.Anchored = true
		p.CanCollide = false
		if shape then
			p.Shape = shape
		end
		p.Parent = m
		return p
	end
	m.PrimaryPart = P(Vector3.new(1.4, 0.3, 1.4), Vector3.new(0, 0.1, 0), Color3.fromRGB(96, 70, 46), Enum.Material.Ground)
	P(Vector3.new(0.25, 1.6, 0.25), Vector3.new(0, 0.9, 0), Color3.fromRGB(110, 80, 50), Enum.Material.Wood)
	P(Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.9, 0), Color3.fromRGB(96, 168, 70), Enum.Material.Grass, Enum.PartType.Ball)
	m:SetAttribute("Planted", t.id)
	m.Parent = reg.propFolder
	return m
end

local function growPlanted(reg, t)
	return build(reg, { id = t.id, kind = t.kind, x = t.x, z = t.z, yaw = t.yaw }, reg.propFolder)
end

-- Planter une graine d'arbre devant soi
function Props.plant(player: Player, kind: string): boolean
	local k = type(kind) == "string" and KINDS[kind]
	local root = G.Util.root(player)
	if not k or not k.tree or not root then
		return false
	end
	local CELL = G.Config.CELL
	local pos = root.Position + root.CFrame.LookVector * 4
	local x, z = math.floor(pos.X / CELL) * CELL + CELL / 2, math.floor(pos.Z / CELL) * CELL + CELL / 2
	local reg = G.World.regionAt(Vector3.new(x, 0, z))
	if not reg or not reg.ready or G.Util.isWater(x, z) then
		G.Util.toast(player, "Pas ici.")
		return false
	end
	local i = G.WG.idx(math.floor(x / CELL) - reg.plan.x0, math.floor(z / CELL) - reg.plan.z0)
	if (reg.plan.poiW[i] or 0) > 0.3 or not G.Parcelles.canBuild(player, Vector3.new(x, 0, z)) then
		return false
	end
	for _, e in reg.props or {} do
		local ek = KINDS[e.data.kind]
		local big = ek and (ek.tree or ek.tool) -- arbres, rochers, filons ; les fleurs et l'herbe ne gênent pas
		if big and e.model.Parent and (e.model:GetPivot().Position - Vector3.new(x, e.model:GetPivot().Position.Y, z)).Magnitude < 4 then
			G.Util.toast(player, "Trop serré : il faut de la place pour qu'il pousse.")
			return false
		end
	end
	reg.state.planted = reg.state.planted or {}
	local t = { id = G.Util.newId("t"), kind = kind, x = x, z = z, yaw = math.random(0, 359), day = G.world.day, o = G.Util.pid(player) }
	table.insert(reg.state.planted, t)
	saplings[t.id] = sapling(reg, t)
	G.Joueurs.addSkillXp(player, "agriculture", 3)
	return true
end

loadPlanted = function(reg)
	for _, t in reg.state.planted or {} do
		if reg.state.removed[t.id] then
			continue -- abattu puis arraché : il ne revient pas
		elseif G.world.day >= t.day + GROW_DAYS then
			growPlanted(reg, t)
		else
			saplings[t.id] = sapling(reg, t)
		end
	end
end

local function growStep()
	for _, reg in G.World.loaded do
		for _, t in reg.state.planted or {} do
			local m = saplings[t.id]
			if G.world.day >= t.day + GROW_DAYS and m then
				saplings[t.id] = nil
				if m.Parent then
					m:Destroy()
					growPlanted(reg, t)
				end
			end
		end
	end
end

function Props.onRegionUnload(reg)
	if reg.props then
		for id in reg.props do
			live[id] = nil
		end
	end
end

local function give(player: Player, gives)
	for item, range in gives do
		G.Joueurs.add(player, item, rand(range))
	end
end

local function remove(entry, keepModel: boolean?)
	entry.reg.state.removed[entry.data.id] = G.world.day
	live[entry.data.id] = nil
	if entry.reg.props then
		entry.reg.props[entry.data.id] = nil
	end
	if not keepModel then
		entry.model:Destroy()
	end
end

-- Outil de la famille demandée, au palier minimum ; renvoie le palier (0 = refusé)
-- ---------------------------------------------------------------- résistance et grind (18/11)
-- Ses mots : « pas en un clic », « plus ou moins de difficulté, ça pour tout », « certaines choses
-- pas possibles à mains nues », « variabilité, grind = mot d'ordre, inspiration Minecraft, filons
-- façon WoW ». Chaque objet a une RÉSISTANCE (variable d'un exemplaire à l'autre, et selon la
-- taille des arbres) ; chaque coup retire la FORCE de frappe : outil (pierre < cuivre < fer) ×
-- compétence. À mains nues : arbres, souches, troncs, cueillette (lentement pour le bois) ; roche,
-- filons, argile et cactus exigent l'outil (filons : palier d'outil + compétence minimum, façon WoW).
local TOUGH = {
	tree_chene = 10, tree_sapin = 8, tree_bouleau = 6, tree_cerisier = 7, tree_mort = 4, tree_saule = 9,
	stump = 5, log = 5, cactus = 3,
	rock = 7, ore_coal = 9, ore_copper = 12, ore_iron = 15, ore_gold = 18, clay = 4,
	stone = 1, stick = 1, tuft = 1.5, flower = 1, mushroom = 1, herb = 1.5,
}
local MODE_TOUGH = { stump = 5, berries = 2, dig = 4 }
local POWER = { [1] = 1, [2] = 1.6, [3] = 2.3 } -- pierre, cuivre, fer
local HANDS = 0.35 -- bois à mains nues : très lent (« taper un arbre » de Minecraft)
local HAND_OK = { axe = true } -- outils qu'on peut remplacer par ses poings (bois seulement)
local HIT_GAP = 0.25 -- s entre deux coups d'un même joueur (clic maintenu ou pas, même cadence)
local SKILL_OF_TOOL = { axe = "bucheronnage", pickaxe = "minage", shovel = "agriculture" }
local lastHit = {}
local handHint = {}

-- résistance de cet objet pour ce geste (variation ±25 % propre à l'exemplaire)
local function toughness(entry, mode: string): number
	local p = entry.data
	local base = MODE_TOUGH[mode] or TOUGH[p.kind] or 2
	if mode == "chop" then
		base *= math.max(0.6, p.scale or 1)
	end
	if base > 1.5 then
		local h = 0
		for i = 1, #p.id do
			h = (h * 31 + string.byte(p.id, i)) % 100003
		end
		base *= 0.75 + Random.new(h):NextNumber() * 0.5
	end
	return base
end

-- un coup : ajoute la force, publie l'usure (barre côté client) ; vrai quand l'objet cède
local function strike(entry, mode: string, power: number): boolean
	-- autre geste, ou laissé tranquille 8 s : l'usure retombe (comme Minecraft)
	if entry.hitMode ~= mode or os.clock() - (entry.lastStrike or 0) > 8 then
		entry.hitMode, entry.hits = mode, 0
	end
	entry.lastStrike = os.clock()
	entry.hits += power
	local hp = toughness(entry, mode)
	local done = entry.hits >= hp - 1e-6
	if entry.model.Parent then
		entry.model:SetAttribute("Usure", done and 1 or math.clamp(entry.hits / hp, 0, 1))
	end
	return done
end

local needTool
-- force de frappe du joueur avec cet outil (0 = impossible ; le message est déjà donné)
local function powerOf(player: Player, tool: string, minTier: number?): number
	local _, tier = G.Joueurs.bestTool(player, tool)
	if tier >= (minTier or 1) then
		if G.Joueurs.wearTool then
			G.Joueurs.wearTool(player, tool) -- chaque coup use l'outil (il finit par casser)
		end
		local skill = G.Joueurs.skill(player, SKILL_OF_TOOL[tool] or "") or 0
		return (POWER[tier] or 1) * (1 + math.min(60, skill) * 0.01)
	end
	if tier == 0 and HAND_OK[tool] and not minTier then
		if not handHint[player] then
			handHint[player] = true
			G.Util.toast(player, "À mains nues, ça va être long… une hache irait bien plus vite.")
		end
		return HANDS
	end
	needTool(player, tool, minTier)
	return 0
end

-- cadence : un coup tous les HIT_GAP au plus (sinon cliquer vite battrait le clic maintenu)
local function tooSoon(player: Player): boolean
	local now = os.clock()
	if now - (lastHit[player] or 0) < HIT_GAP then
		return true
	end
	lastHit[player] = now
	return false
end

function needTool(player: Player, tool: string, minTier: number?): number
	local _, tier = G.Joueurs.bestTool(player, tool)
	if tier >= (minTier or 1) then
		return math.max(1, tier)
	end
	if tier > 0 then
		G.Util.toast(player, "Trop dur pour ton outil : il faut " .. TOOL_NAMES[tool] .. " " .. (TIER_NAMES[minTier or 1] or "") .. " au moins.")
	else
		G.Util.toast(player, "Il te faut " .. TOOL_NAMES[tool] .. " " .. (TOOL_HINT[tool] or ""))
	end
	return 0
end

-- Arbre abattu : il tombe, devient souche, le bois est donné
local function fell(player: Player, entry)
	local model = entry.model
	local p = entry.data
	local k = KINDS[p.kind]
	local st = entry.reg.state.props[p.id] or {}
	st.stump = true
	st.day = G.world.day
	entry.reg.state.props[p.id] = st
	give(player, { wood = k.wood })
	if math.random() < 0.02 * G.Joueurs.skill(player, "bucheronnage") then
		G.Joueurs.add(player, "wood", 2)
	end
	G.Joueurs.addSkillXp(player, "bucheronnage", 6)
	local fp = G.Joueurs.get(player)
	if fp then
		fp.stats.felled = (fp.stats.felled or 0) + 1
		if fp.stats.felled % 25 == 0 then
			G.Social.checkTitles(player)
		end
	end
	if G.Activites and rawget(G.Activites, "note") then
		G.Activites.note(player, "bucheronnage") -- concours de bûcheronnage
	end
	if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "abattre", "tree") end
	G.Util.finds(player, "tree", model:GetPivot().Position)
	-- de quoi replanter : le monde ne repousse pas tout seul
	local seed = "seed_" .. p.kind
	if G.Config.ITEMS[seed] and math.random() < 0.7 then
		G.Joueurs.add(player, seed, math.random(1, 2))
	end
	if math.random() < 0.25 then
		G.Joueurs.add(player, "fiber", 1)
	end
	-- chute
	local root = G.Util.root(player)
	local away = root and (model:GetPivot().Position - root.Position) or Vector3.new(1, 0, 0)
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 0.1 then
		away = Vector3.new(1, 0, 0)
	end
	local axis = Vector3.new(0, 1, 0):Cross(away.Unit)
	for _, d in model:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			d:Destroy()
		end
	end
	local pivot = model:GetPivot()
	local parent = model.Parent
	task.spawn(function()
		for i = 1, 12 do
			if not model.Parent then
				break
			end
			model:PivotTo(CFrame.fromAxisAngle(axis, math.rad(i * 7.5)) * (pivot - pivot.Position) + pivot.Position)
			task.wait(0.03)
		end
		chips(pivot.Position + away.Unit * 6 + Vector3.new(0, 1, 0), Color3.fromRGB(120, 90, 60))
		task.wait(0.3)
		model:Destroy()
		if entry.reg.folder.Parent then
			entry.hits = 0
			local e = build(entry.reg, p, parent)
			if e then
				entry.model = e.model
			end
		end
	end)
end

local function harvest(player: Player, id: string, mode: string)
	local entry = live[id]
	if not entry or not entry.model.Parent then
		return
	end
	local p = entry.data
	local k = KINDS[p.kind]
	local pos = entry.model:GetPivot().Position
	local root = G.Util.root(player)
	if not root or (root.Position - pos).Magnitude > 16 then
		return
	end
	local prof = G.Joueurs.get(player)
	local hitting = mode == "chop" or mode == "stump" or mode == "berries" or mode == "dig" or mode == "take"
	if hitting and tooSoon(player) then
		return
	end
	if mode == "berries" or mode == "take" then
		G.Util.geste(player, "cueillir") -- à la main : on se penche, la main fouille
	end
	if mode == "chop" then
		local pw = powerOf(player, "axe")
		if pw == 0 then
			return
		end
		Props.swing(player, "axe")
		chips(pos + Vector3.new(0, 2.5, 0), Color3.fromRGB(150, 110, 70))
		shake(entry.model)
		if strike(entry, "chop", pw) then
			fell(player, entry)
		end
	elseif mode == "stump" then
		local pw = powerOf(player, "axe")
		if pw == 0 then
			return
		end
		Props.swing(player, "axe")
		chips(pos + Vector3.new(0, 1, 0), Color3.fromRGB(150, 110, 70))
		if strike(entry, "stump", pw) then
			give(player, { wood = { 1, 2 } })
			entry.reg.state.props[p.id] = nil
			remove(entry)
		end
	elseif mode == "fruit" then
		local st = entry.reg.state.props[p.id] or {}
		if not k.fruit or (st.fruitDay and G.world.day - st.fruitDay < FRUIT_DAYS) then
			return
		end
		st.fruitDay = G.world.day
		entry.reg.state.props[p.id] = st
		-- le fruit dépend du pays : pommes en prairie, prunes et poires en forêt, cerises… en pommes ailleurs
		local biome = G.Clock.biomeAt(pos)
		local pool = biome == "foret" and { "plum", "pear" } or { "apple", "apple", "pear" }
		local item = pool[math.random(1, #pool)]
		local n = math.random(2, 4) + (math.random() < 0.01 * G.Joueurs.skill(player, "agriculture") and 1 or 0)
		G.Joueurs.add(player, item, n)
		G.Joueurs.addSkillXp(player, "agriculture", 2)
		if G.Activites.note then
			G.Activites.note(player, "recolte", n)
		end
		shake(entry.model)
		setPrompt(entry)
	elseif mode == "berries" then
		local st = entry.reg.state.props[p.id] or {}
		if st.empty then
			return
		end
		shake(entry.model)
		if not strike(entry, "berries", 1 + G.Joueurs.skill(player, "agriculture") * 0.01) then
			return
		end
		entry.hits = 0
		st.empty = true
		st.day = G.world.day
		entry.reg.state.props[p.id] = st
		G.Joueurs.add(player, "berries", math.random(2, 4))
		for _, d in entry.model:GetDescendants() do
			if d.Name == "Baie" then
				d.Transparency = 1
			end
		end
		setPrompt(entry)
	elseif mode == "dig" then
		local pw = powerOf(player, "shovel")
		if pw == 0 then
			return
		end
		Props.swing(player, "shovel")
		chips(pos + Vector3.new(0, 0.6, 0), Color3.fromRGB(110, 80, 50))
		if not strike(entry, "dig", pw) then
			return
		end
		local st = entry.reg.state.props[p.id]
		if not (st and st.empty) then
			G.Joueurs.add(player, "berries", math.random(1, 3))
		end
		G.Joueurs.add(player, "fiber", math.random(2, 3))
		G.Util.finds(player, "bush", pos)
		chips(pos + Vector3.new(0, 1, 0), Color3.fromRGB(80, 140, 60))
		remove(entry)
	elseif mode == "open" then
		if entry.reg.state.chests[p.id] then
			return
		end
		entry.reg.state.chests[p.id] = true
		if p.owner then
			G.Law.crime(player, "theft", pos, p.owner)
			G.Npcs.remember(p.owner, "robbed")
		end
		local loot = p.loot or {}
		local any = false
		for item, n in loot do
			if item == "gear" then
				local level = math.clamp(math.floor(math.sqrt(entry.reg.rx ^ 2 + entry.reg.rz ^ 2)) + 1, 1, 10)
				G.Joueurs.addGear(player, G.Gear.roll(Random.new(), level))
			else
				G.Joueurs.add(player, item, n)
			end
			any = true
		end
		if not any then
			G.Util.toast(player, "Le coffre est vide.")
		end
		local lid = entry.model:FindFirstChild("Couvercle")
		if lid then
			TweenService:Create(lid, TweenInfo.new(0.4), { CFrame = lid.CFrame * CFrame.new(0, 0.6, -0.6) * CFrame.Angles(math.rad(-60), 0, 0) }):Play()
		end
		setPrompt(entry)
	else -- take
		local pw = 1 -- cueillette à la main
		if k.herb and (p.skill or 0) > 0 and not G.Joueurs.needSkill(player, "agriculture", p.skill, "Cette plante") then
			return
		end
		if k.tool then
			if k.skill and not G.Joueurs.needSkill(player, "minage", k.skill, "Ce filon") then
				return
			end
			-- roche, filons, argile, cactus : jamais à mains nues
			local _, tier = G.Joueurs.bestTool(player, k.tool)
			if tier == 0 and k.tool ~= "axe" or (k.tool == "axe" and p.kind == "cactus" and tier == 0) then
				needTool(player, k.tool, k.tier)
				return
			end
			pw = powerOf(player, k.tool, k.tier)
			if pw == 0 then
				return
			end
			Props.swing(player, k.tool)
			chips(pos + Vector3.new(0, 1.5, 0), (k.tool == "pickaxe") and Color3.fromRGB(140, 140, 140) or Color3.fromRGB(150, 110, 70))
		end
		shake(entry.model)
		if not strike(entry, "take", pw) then
			return
		end
		if k.herb then
			local n = math.random(1, 2) + (math.random() < 0.02 * G.Joueurs.skill(player, "agriculture") and 1 or 0)
			G.Joueurs.add(player, p.herb, n)
			G.Joueurs.addSkillXp(player, "agriculture", 2 + math.floor((p.skill or 0) / 4))
			if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "recolter", p.herb, n) end
			G.Social.collect(player, "herbs", p.herb) -- collection des plantes sauvages
		end
		give(player, k.gives or {})
		if k.coal and math.random() < k.coal then
			G.Joueurs.add(player, "coal", 1)
		end
		if k.tool == "pickaxe" then
			G.Util.finds(player, "rock")
			G.Joueurs.addSkillXp(player, "minage", 4 + math.floor((k.skill or 0) / 2))
			if G.Activites and rawget(G.Activites, "note") then
				G.Activites.note(player, "minage") -- concours de minage
			end
			if prof then
				prof.stats.mined = (prof.stats.mined or 0) + 1
				if prof.stats.mined % 25 == 0 then
					G.Social.checkTitles(player)
				end
			end
			if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "miner", p.kind) end
			G.Social.collect(player, "ores", p.kind)
			-- talent Mineur + compétence : minerai en plus
			local bonus = G.Joueurs.talent(player, "mineur")
			if math.random() < 0.02 * G.Joueurs.skill(player, "minage") then
				bonus += 1
			end
			if bonus > 0 and p.kind ~= "rock" then
				for item in k.gives do
					if item ~= "stone" then
						G.Joueurs.add(player, item, bonus)
					end
				end
			end
		elseif k.tool == "shovel" then
			G.Joueurs.addSkillXp(player, "agriculture", 2)
		end
		remove(entry)
	end
	if prof then
		G.Social.bump(player, "harvested")
		if G.Activites.note then
			G.Activites.note(player, "recolte")
		end
	end
end


-- Ce qu'on récolte tombe au sol, près de la ressource (ramassage : Systemes/Butin)
function Props.harvest(player: Player, id: string, mode: string)
	local entry = live[id]
	if not entry or not entry.model.Parent then
		return
	end
	return G.Util.auSol(player, entry.model:GetPivot().Position, entry.model, harvest, player, id, mode)
end

-- Coup d'outil (hache / pioche) : vise l'objet le plus proche devant le joueur
function Props.toolHit(player: Player, itemId: string): boolean
	-- pelle sur la croix d'une carte au trésor : on déterre (prioritaire sur le reste)
	if itemId == "shovel" and G.Journal.digTreasure and G.Journal.digTreasure(player) then
		return true
	end
	local root = G.Util.root(player)
	if not root then
		return false
	end
	local best, bd = nil, 9
	for id, entry in live do
		if entry.model.Parent then
			local pos = entry.model:GetPivot().Position
			local d = Vector3.new(pos.X - root.Position.X, 0, pos.Z - root.Position.Z)
			local dist = d.Magnitude
			if dist < bd and (dist < 2 or root.CFrame.LookVector:Dot(d.Unit) > 0.3) then
				local k = KINDS[entry.data.kind]
				local st = entry.reg.state.props[id]
				local ok = (itemId == "axe" and (k.tree or entry.data.kind == "stump" or entry.data.kind == "log" or entry.data.kind == "cactus"))
					or (itemId == "pickaxe" and k.tool == "pickaxe")
					or (itemId == "shovel" and (k.bush or entry.data.kind == "clay"))
				if ok then
					best, bd = { id, entry, st }, dist
				end
			end
		end
	end
	if not best then
		return false
	end
	local id, entry, st = best[1], best[2], best[3]
	local k = KINDS[entry.data.kind]
	G.Util.sfx(itemId == "pickaxe" and "pioche" or (itemId == "shovel" and "pelle" or "hache"), entry.model:GetPivot().Position)
	if itemId == "shovel" and k.bush then
		Props.harvest(player, id, "dig")
	elseif k.tree then
		Props.harvest(player, id, (st and st.stump) and "stump" or "chop")
	else
		Props.harvest(player, id, "take")
	end
	return true
end

-- Clic direct sur un objet (18/11, « tout ramassable minecraft style ») : même effet que son
-- invite principale. Les coffres restent à l'invite (ouvrir celui d'un autre est un vol : pas par
-- mégarde d'un clic).
function Props.click(player: Player, id: string)
	local entry = live[id]
	if not entry or not entry.model.Parent then
		return
	end
	local k = KINDS[entry.data.kind]
	if not k or k.chest then
		return
	end
	local st = entry.reg.state.props[id]
	local mode
	if k.tree then
		mode = (st and st.stump) and "stump" or "chop"
	elseif k.bush then
		mode = (st and st.empty) and "dig" or "berries"
	else
		mode = "take"
	end
	Props.harvest(player, id, mode)
end

function Props.newDay()
	for _, reg in G.World.loaded do
		local st = reg.state
		-- souches qui repoussent, buissons qui se regarnissent
		for id, s in st.props do
			local entry = reg.props and reg.props[id]
			if s.stump and G.world.day >= (s.day or 0) + TREE_REGROW then
				st.props[id] = nil
				if entry then
					local parent = entry.model.Parent
					entry.model:Destroy()
					build(reg, entry.data, parent)
				end
			elseif s.empty and G.world.day >= (s.day or 0) + BERRY_REGROW then
				s.empty = nil
				if entry then
					for _, d in entry.model:GetDescendants() do
						if d.Name == "Baie" then
							d.Transparency = 0
						end
					end
					setPrompt(entry)
				end
			elseif s.fruitDay and entry and G.world.day - s.fruitDay == FRUIT_DAYS then
				setPrompt(entry) -- l'arbre fruitier s'est regarni : l'invite « Cueillir » revient
			end
		end
		-- petites choses qui repoussent
		for _, p in reg.plan.props do
			local removed = st.removed[p.id]
			if removed and canRespawn(p, removed) then
				st.removed[p.id] = nil
				build(reg, p, reg.propFolder)
			end
		end
	end
	-- régions non chargées : on applique au prochain chargement (cf. onRegionLoad)
	growStep()
end

function Props.get(id: string)
	return live[id]
end

return Props
