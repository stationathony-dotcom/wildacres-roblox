-- Habitants : emploi du temps (maison / travail / place / lit), vue du joueur, mémoire de ce
-- qu'ils ont vu, réactions selon leur caractère (fuite, bagarre, shérif qui poursuit),
-- dialogues (discuter, rumeur, cadeau, commerce). Au-dessus d'eux : émoticônes seulement.

local PathfindingService = game:GetService("PathfindingService")
local ServerStorage = game:GetService("ServerStorage")
local RelationsPnj = require(script.Parent.RelationsPnj)

local Npcs = {}
local G, Config, D
local list = {} -- id -> entrée vivante
Npcs.list = list
local lastBark = 0
local talking = {} -- joueur -> id du PNJ en dialogue

function Npcs.init(g)
	G = g
	Config = G.Config
	D = G.Dialogue
	G.Interact.onPrompt("talk", function(player, prompt)
		Npcs.talk(player, prompt:GetAttribute("Npc"))
	end)
	G.Interact.onAction("dialog", function(player, data)
		Npcs.choice(player, data.choice)
	end)
end

function Npcs.persist(id: string)
	local p = G.world.npcs[id]
	if not p then
		p = { opinion = 0, memory = {} }
		G.world.npcs[id] = p
	end
	p.memory = p.memory or {}
	p.ops = p.ops or {}
	p.opinion = nil -- ancien avis commun (solo) : remplacé par un avis par joueur
	return p
end

-- Avis d'un PNJ sur UN joueur (multi) : per.ops["u<UserId>"] de -100 à 100
function Npcs.op(e, player: Player): number
	return (e.per.ops and e.per.ops[G.Util.pid(player)]) or 0
end

function Npcs.addOpId(per, uid: string, delta: number)
	per.ops = per.ops or {}
	per.ops[uid] = math.clamp((per.ops[uid] or 0) + delta, -100, 100)
end

function Npcs.addOp(e, player: Player, delta: number)
	Npcs.addOpId(e.per, G.Util.pid(player), delta)
end

function Npcs.setOp(e, player: Player, v: number)
	e.per.ops = e.per.ops or {}
	e.per.ops[G.Util.pid(player)] = v
end

function Npcs.remember(id: string, key: string)
	if type(id) ~= "string" or id == "wild" or G.Util.isPlayerId(id) then
		return -- seuls les PNJ ont une mémoire
	end
	local p = Npcs.persist(id)
	p.memory[key] = G.world.day
	p.memory[key .. "_told"] = nil
end

local function hour(): number
	return G.Clock.hour()
end

local function setState(e, s: string)
	e.state = s
	e.stateTime = 0
	e.unseen = 0
	if e.model then
		e.model:SetAttribute("Etat", s)
	end
end
Npcs.setState = setState

function Npcs.react(e, key: string)
	G.Util.emote(e.model, D.emote_for(e.data.persona, key))
end

local function play(e, name: string)
	if e.current == name then
		return
	end
	if e.tracks[e.current or ""] then
		e.tracks[e.current]:Stop(0.2)
	end
	e.current = name
	local t = e.tracks[name]
	if t then
		t:Play(0.2)
	end
end

local function oneShot(e, name: string)
	local t = e.tracks[name]
	if t then
		t:Play(0.1)
	end
end
Npcs.oneShot = oneShot

-- ----------------------------------------------------------------- Lieux de vie

local function houseOf(e)
	local hid = e.data.house
	if not hid then
		return nil
	end
	return e.reg.houses[hid]
end

local function attach(h, name: string): CFrame?
	if not h or not h.model.Parent then
		return nil
	end
	local a = h.model.PrimaryPart:FindFirstChild(name)
	return a and a.WorldCFrame or nil
end

local function homeOutside(e): Vector3
	local cf = attach(houseOf(e), "Entree")
	return cf and cf.Position + Vector3.new(0, 3, 0) or e.spawnPos
end

local function workPos(e): Vector3
	local w = e.data.work
	if w == "house" then
		local cf = attach(houseOf(e), "Travail")
		if cf then
			return cf.Position + Vector3.new(0, 3, 0)
		end
		return homeOutside(e)
	end
	-- 3e valeur : hauteur donnée (poste à l'intérieur d'un bâtiment, au-dessus du terrain)
	return Vector3.new(w[1], (w[3] or G.Util.groundY(w[1], w[2])) + 3, w[2])
end

local function plazaPos(e): Vector3
	local p = e.data.plaza
	return Vector3.new(p[1], G.Util.groundY(p[1], p[2]) + 3, p[2])
end

function Npcs.officeOf(e)
	local h = houseOf(e)
	local cell = attach(h, "Cellule")
	local exit = attach(h, "Entree")
	if not cell or not exit then
		return nil
	end
	return { cell = cell.Position + Vector3.new(0, 1, 0), exit = exit.Position + Vector3.new(0, 1, 0) }
end

local function wantsOutside(e): boolean
	local h = hour()
	-- sous l'orage, les villageois s'abritent chez eux (le shérif et le marchand tiennent leur poste)
	local role = e.data.role
	-- (les gens de métier tiennent aussi leur comptoir sous l'orage)
	if G.Meteo and G.Meteo.kind and G.Meteo.kind() == "orage" and role ~= "sheriff" and role ~= "merchant" and not e.data.shopkeeper then
		return false
	end
	local hours = e.data.hours
	if hours then
		return h >= hours[1] and h < hours[2]
	end
	return h >= 6 and h < (role == "sheriff" and 23 or 21)
end

-- Midi : ceux qui ne tiennent pas boutique vont manger à la taverne du village (s'il y en a une)
local function lunchPos(e): Vector3?
	local reg = e.reg
	local h = reg and reg.houses and reg.houses["v:Taverne"]
	if not h or not h.model or h.wrecked then
		return nil
	end
	local a = h.model:FindFirstChild("Travail", true)
	return a and a:IsA("Attachment") and a.WorldPosition + Vector3.new(0, 3, 0) or nil
end

local function asleep(e): boolean
	local h = hour()
	return e.state == "inside" and (h >= 22 or h < 6) and not e.woken
end
Npcs.asleep = asleep

function Npcs.ownerAsleepAt(houseId: string): boolean
	for _, e in list do
		if e.data.house == houseId and e.state == "inside" and asleep(e) then
			return true
		end
	end
	return false
end

-- ----------------------------------------------------------------- Déplacement

local function flatDist(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function moveTo(e, target: Vector3, speed: number): boolean
	local hum, root = e.hum, e.root
	hum.WalkSpeed = speed
	local pos = root.Position
	if flatDist(pos, target) < 2.6 then
		hum:MoveTo(pos)
		e.path = nil
		return true
	end
	e.pathAge += 0.25
	local far = flatDist(pos, target) > 14
	if far and not e.computing and (not e.pathGoal or flatDist(e.pathGoal, target) > 6 or e.pathAge > 5 or not e.path) then
		e.computing = true
		e.pathGoal = target
		e.pathAge = 0
		task.spawn(function()
			local ok = pcall(function()
				e.pathObj:ComputeAsync(pos, target)
			end)
			if ok and e.pathObj.Status == Enum.PathStatus.Success then
				e.path = e.pathObj:GetWaypoints()
				e.pathI = 2
			else
				e.path = nil
			end
			e.computing = false
		end)
	end
	local nextPos = target
	if far and e.path then
		local wp = e.path[e.pathI]
		while wp and flatDist(wp.Position, pos) < 3 do
			e.pathI += 1
			wp = e.path[e.pathI]
		end
		if wp then
			nextPos = wp.Position
			if wp.Action == Enum.PathWaypointAction.Jump then
				hum.Jump = true
			end
		end
	end
	-- coincé : petit saut et détour
	if e.lastPos and (e.lastPos - pos).Magnitude < 0.3 then
		e.stuck += 0.25
		if e.stuck > 1.5 then
			hum.Jump = true
			e.stuck = 0
			e.path = nil
			e.pathGoal = nil
			local side = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit * 6
			nextPos = pos + side
		end
	else
		e.stuck = 0
	end
	e.lastPos = pos
	hum:MoveTo(nextPos)
	-- portes sur le chemin
	for hid, h in e.reg.houses do
		if h.door and (h.door.model:GetPivot().Position - pos).Magnitude < 7 then
			G.Doors.npcPass(hid)
		end
	end
	return false
end

local function face(e, at: Vector3)
	local pos = e.root.Position
	local d = Vector3.new(at.X - pos.X, 0, at.Z - pos.Z)
	if d.Magnitude > 0.1 then
		e.root.CFrame = CFrame.lookAt(pos, pos + d)
	end
end

-- ----------------------------------------------------------------- Lit

local function lieDown(e)
	local h = houseOf(e)
	local bed = attach(h, "Couchage")
	if not bed or e.data.second then
		return
	end
	local base = h.model.PrimaryPart.CFrame
	local cf = CFrame.fromMatrix(bed.Position, -base.RightVector, base.LookVector, Vector3.new(0, -1, 0))
	e.root.Anchored = true
	e.model:PivotTo(cf)
	e.lying = true
	play(e, "idle")
end

local function getUp(e)
	if not e.lying then
		return
	end
	e.lying = false
	local foot = attach(houseOf(e), "PiedDuLit")
	local pos = foot and foot.Position + Vector3.new(0, 3, 0) or e.root.Position + Vector3.new(3, 2, 0)
	e.model:PivotTo(CFrame.new(pos))
	e.root.Anchored = false
end
Npcs.getUp = getUp

local function enterHome(e)
	setState(e, "inside")
	lieDown(e)
end

local function goOut(e)
	getUp(e)
	setState(e, "routine")
end

-- ----------------------------------------------------------------- Perception

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function sightRange(e, player: Player?): number
	local h = hour()
	local base = ((h >= 21 or h < 6) and Config.NIGHT_SIGHT or Config.SIGHT) * (G.Meteo and G.Meteo.sightMult and G.Meteo.sightMult() or 1)
	-- ronde de nuit payée par le village : les habitants ont l'œil
	local ronde = (e.root and G.Politique and G.Politique.sightMult) and G.Politique.sightMult(e.root.Position) or 1
	return base * ronde * (player and G.Joueurs.sightFactor(player) or 1)
end

function Npcs.canSee(e, pos: Vector3, player: Player?): boolean
	if not e.model.Parent or e.state == "ko" or e.state == "carried" or asleep(e) then
		return false
	end
	local head = e.model:FindFirstChild("Head")
	local from = head and head.Position or e.root.Position
	local d = (pos - from).Magnitude
	if d > sightRange(e, player) then
		return false
	end
	local exclude = { e.model }
	for _, p in game:GetService("Players"):GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	if G.Bodies.carriedModels then
		for _, m in G.Bodies.carriedModels() do
			table.insert(exclude, m)
		end
	end
	rayParams.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(from, pos - from, rayParams)
	if hit and hit.Instance and hit.Instance.CanCollide and (hit.Position - from).Magnitude < d - 1.5 then
		local m = hit.Instance:FindFirstAncestorOfClass("Model")
		if not (m and m:GetAttribute("NpcId")) then
			return false
		end
	end
	return true
end

local function seePlayer(e, player: Player): boolean
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return false
	end
	return Npcs.canSee(e, head.Position, player)
end

local function perceiveHome(e)
	if asleep(e) then
		if math.random() < 0.02 then
			G.Util.emote(e.model, "sleepy", 1.5)
		end
		return
	end
	for _, player in G.Game.players() do
		if seePlayer(e, player) then
			local prof = G.Joueurs.get(player)
			if e.data.role == "sheriff" and prof.stars > 0 then
				getUp(e)
				e.target = player
				e.lastSeen = G.Util.root(player).Position
				setState(e, "chase")
				Npcs.react(e, "chase")
				return
			end
			-- quelqu'un chez moi !
			local root = G.Util.root(player)
			local h = houseOf(e)
			local inside = h and root and (root.Position - h.model:GetPivot().Position).Magnitude < 11
			if inside and e.trespassDay ~= G.world.day and e.data.role ~= "merchant" then
				e.trespassDay = G.world.day
				Npcs.addOp(e, player, -15)
				e.per.memory.trespass = G.world.day
				Npcs.react(e, "trespass")
			end
		end
	end
end

local function perceive(e)
	if e.state == "inside" then
		perceiveHome(e)
		return
	end
	if e.state == "ko" or e.state == "carried" then
		return
	end
	local law = G.Law
	-- corps à terre
	for _, body in law.bodies() do
		if body ~= e and body.model.Parent and body.state == "ko" and Npcs.canSee(e, body.root.Position) then
			law.bodyFound(body, e)
		end
	end
	-- une bête hostile approche : on fuit (sauf le shérif et les gardes)
	if e.state == "routine" and e.data.role ~= "sheriff" and e.data.role ~= "guard" then
		local beast = Npcs.threatNear(e)
		if beast then
			e.target = nil
			e.threatPos = beast.pos
			setState(e, "flee")
			Npcs.react(e, "flee")
			return
		end
	end
	local seen = false
	for _, player in G.Game.players() do
		if seePlayer(e, player) then
			seen = true
			local prof = G.Joueurs.get(player)
			local root = G.Util.root(player)
			law.sawPlayer(player, e)
			if player:GetAttribute("Carrying") then
				law.crime(player, "ko", root.Position, nil)
			end
			if e.data.role == "sheriff" then
				if prof.stars > 0 then
					e.lastSeen = root.Position
					e.target = player
					if e.state ~= "chase" then
						setState(e, "chase")
						Npcs.react(e, "chase")
					end
				end
			elseif e.state ~= "flee" and e.state ~= "fight" then
				if prof.stars >= 2 or Npcs.op(e, player) <= -60 then
					e.target = player
					setState(e, "flee")
					Npcs.react(e, prof.stars >= 2 and "wanted" or "flee")
					law.report(player, e, root.Position)
				elseif e.state == "routine" and e.barkCd <= 0 and (root.Position - e.root.Position).Magnitude < 12 and os.clock() - lastBark > 4 then
					e.barkCd = Config.BARK_COOLDOWN
					lastBark = os.clock()
					face(e, root.Position)
					Npcs.react(e, D.greeting_key(e.per, prof.honor, prof.stars, false, Npcs.op(e, player)))
				end
			end
		end
	end
	if seen then
		e.unseen = 0
	else
		e.unseen += 0.25
	end
end

-- ----------------------------------------------------------------- Comportements

local function routine(e)
	if not wantsOutside(e) then
		local h = houseOf(e)
		if not h then
			-- pas de maison (ou détruite) : reste où il est
			e.hum:MoveTo(e.root.Position)
			return
		end
		local outside = homeOutside(e)
		local seuil = attach(h, "Seuil")
		local foot = attach(h, e.data.second and "Dedans" or "PiedDuLit")
		if not e.goingIn then
			if moveTo(e, outside, Config.NPC_WALK * 1.3) then
				e.goingIn = 1
			end
			return
		end
		if e.goingIn == 1 then
			G.Doors.npcPass(e.data.house)
			if not seuil or moveTo(e, seuil.Position + Vector3.new(0, 3, 0), Config.NPC_WALK) then
				e.goingIn = 2
			end
			return
		end
		if not foot or moveTo(e, foot.Position + Vector3.new(0, 3, 0), Config.NPC_WALK) then
			e.goingIn = nil
			enterHome(e)
		end
		return
	end
	e.goingIn = nil
	local h = hour()
	local spot = homeOutside(e)
	local radius = 10
	local lunch = (h >= 12 and h < 13) and e.data.role ~= "merchant" and e.data.role ~= "sheriff" and not e.data.shopkeeper and lunchPos(e)
	if lunch then
		spot = lunch
		radius = 6
	elseif h >= 8 and h < 18 then
		spot = workPos(e)
		local role = e.data.role
		radius = e.data.radius or (role == "sheriff" and 30 or (role == "merchant" and 1 or 14))
	elseif h >= 18 then
		spot = plazaPos(e)
		radius = 16
	end
	e.goalTimer -= 0.25
	-- PNJ coincé (bloqué contre un mur, une construction de joueur…) : au bout de 10 s sans
	-- avancer alors qu'il a un but lointain, il « trouve un passage » (téléporté sur son but)
	local here = e.root.Position
	if e.stuckFrom and (here - e.stuckFrom).Magnitude < 1.5 and flatDist(here, spot) > radius + 12 then
		e.stuckT = (e.stuckT or 0) + 0.25
		if e.stuckT > 10 then
			e.stuckT = 0
			e.model:PivotTo(CFrame.new(spot + Vector3.new(0, 1, 0)))
			e.path = nil
		end
	else
		e.stuckFrom, e.stuckT = here, 0
	end
	if flatDist(e.root.Position, spot) > radius + 12 then
		moveTo(e, spot, Config.NPC_WALK * 1.3)
		return
	end
	if e.goalTimer <= 0 or not e.goal then
		-- les enfants ne tiennent pas en place : nouveau but plus souvent
		e.goalTimer = e.data.restless and math.random(8, 22) / 10 or math.random(20, 60) / 10
		local off = Vector3.new(math.random(-radius * 10, radius * 10) / 10, 0, math.random(-radius * 10, radius * 10) / 10)
		local g = spot + off
		if G.Util.isWater(g.X, g.Z) then
			g = spot
		end
		e.goal = Vector3.new(g.X, spot.Y, g.Z)
	end
	moveTo(e, e.goal, e.data.walk or Config.NPC_WALK)
end

local function flee(e)
	-- on fuit un joueur (e.target) ou une bête (e.threatPos, Npcs.threatNear)
	local root = e.target and G.Util.root(e.target)
	local from = root and root.Position or e.threatPos
	if not from then
		setState(e, "routine")
		return
	end
	local away = e.root.Position - from
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 0.1 then
		away = Vector3.new(1, 0, 0)
	end
	local goal = e.root.Position + away.Unit * 16
	if G.Util.isWater(goal.X, goal.Z) then
		goal = e.root.Position + Vector3.new(-away.Z, 0, away.X).Unit * 16
	end
	moveTo(e, goal, e.data.run or Config.NPC_RUN)
	if e.stateTime > 6 and (away.Magnitude > Config.SIGHT or (not root and e.stateTime > 10)) then
		e.threatPos = nil
		setState(e, "routine")
	end
end

-- Une bête hostile tout près (20/11, étape 10 « réactions aux dangers ») : un villageois s'enfuit en criant,
-- puis reprend sa routine. Pas les gardes ni le shérif (ils tiennent leur poste). Contrôlé une fois par
-- seconde au plus par villageois.
Npcs.THREAT_R = 22
function Npcs.threatNear(e)
	local now = os.clock()
	if (e.threatCheck or 0) > now then
		return nil
	end
	e.threatCheck = now + 1
	local best, bd = nil, Npcs.THREAT_R
	for _, en in G.Enemies.list do
		if not en.dead and not en.pet and not en.k.passive and not en.k.neutral and en.model.Parent then
			local d = (en.pos - e.root.Position).Magnitude
			if d < bd then
				best, bd = en, d
			end
		end
	end
	return best
end

local function fight(e)
	local player = e.target
	local root = player and G.Util.root(player)
	if not root then
		setState(e, "routine")
		return
	end
	if e.hp <= e.maxHp * 0.15 then
		setState(e, "flee")
		return
	end
	local d = (root.Position - e.root.Position).Magnitude
	if d > Config.SIGHT * 1.3 or e.stateTime > 15 then
		local prof = G.Joueurs.get(player)
		-- le shérif ne lâche pas un recherché : il reprend la poursuite
		setState(e, (e.data.role == "sheriff" and prof and prof.stars > 0) and "chase" or "routine")
		return
	end
	if d > 4.5 then
		moveTo(e, root.Position, Config.NPC_RUN * 0.9)
	else
		e.hum:MoveTo(e.root.Position)
		face(e, root.Position)
		if e.hitCd <= 0 then
			e.hitCd = 1.2
			oneShot(e, "slash")
			if e.data.role == "sheriff" then
				-- s'il te met K.O., c'est la cellule (voir Game.onDeath)
				player:SetAttribute("SheriffHit", os.clock())
				player:SetAttribute("SheriffId", e.data.id)
			end
			G.Combat.hurtPlayer(player, e.data.role == "sheriff" and 12 or 8, e.root.Position)
		end
	end
end

local function chase(e)
	local player = e.target
	local prof = player and G.Joueurs.get(player)
	local root = player and G.Util.root(player)
	if not prof or prof.stars == 0 or not root then
		setState(e, "routine")
		return
	end
	local speed = Config.SHERIFF_RUN * (prof.stars >= 3 and 1.15 or 1)
	moveTo(e, e.lastSeen or root.Position, speed)
	-- au contact : il ne passe pas les menottes d'office, il se bat (on peut résister, l'assommer, fuir)
	if (root.Position - e.root.Position).Magnitude < 5 and not player:GetAttribute("Riding") then
		setState(e, "fight")
		Npcs.react(e, "chase")
		return
	end
	if e.unseen > 6 then
		setState(e, "search")
		Npcs.react(e, "search")
	end
end

local function think(e)
	perceive(e)
	local s = e.state
	if s == "inside" then
		if wantsOutside(e) then
			goOut(e)
		end
	elseif s == "routine" then
		routine(e)
	elseif s == "talk" then
		e.hum:MoveTo(e.root.Position)
		if e.stateTime > 8 then
			setState(e, "routine")
		end
	elseif s == "flee" then
		flee(e)
	elseif s == "fight" then
		fight(e)
	elseif s == "chase" then
		chase(e)
	elseif s == "search" or s == "alert" then
		if not e.lastSeen or moveTo(e, e.lastSeen, Config.NPC_WALK * 1.6) or e.stateTime > 10 then
			if s == "search" then
				Npcs.react(e, "search")
			end
			setState(e, "routine")
		end
	end
end

function Npcs.step(dt: number)
	for _, e in list do
		if e.model.Parent and e.state ~= "gone" then
			e.stateTime += dt
			e.barkCd -= dt
			e.hitCd -= dt
			e.think -= dt
			if e.think <= 0 then
				-- loin de tout joueur (rien à voir, personne pour le voir), il pense 4 fois moins souvent ;
				-- en alerte, en fuite, au combat : toujours à plein régime
				local s = e.state
				local calm = s == "routine" or s == "inside" or s == "talk"
				e.think = (calm and G.Util.playerDist(e.root.Position) > 300) and 1 or 0.25
				local ok, err = pcall(think, e)
				if not ok then
					warn("[WildAcres] PNJ " .. e.data.name .. " : " .. tostring(err))
					e.think = 2
				end
			end
		end
	end
end

-- ----------------------------------------------------------------- Réactions

function Npcs.reactToCrime(e, kind: string, at: Vector3, player: Player)
	if e.state == "ko" or e.state == "carried" or e.state == "gone" then
		return
	end
	getUp(e)
	e.lastSeen = at
	e.target = player
	face(e, at)
	if e.data.role == "sheriff" then
		setState(e, "chase")
		Npcs.react(e, "chase")
		return
	end
	Npcs.react(e, "saw_" .. kind)
	if kind == "theft" then
		return
	end
	-- un enfant ne se bat jamais : il court prévenir
	setState(e, (D.persona(e.data.persona).brave and not e.data.child) and "fight" or "flee")
end

function Npcs.alert(e, at: Vector3)
	if e.state == "inside" or e.state == "flee" or e.state == "fight" or e.state == "chase" or e.state == "ko" or e.state == "carried" then
		return
	end
	e.lastSeen = at
	setState(e, "alert")
	Npcs.react(e, "curious")
end

-- Coup reçu (du joueur). Renvoie vrai si le PNJ est assommé.
function Npcs.hit(e, dmg: number, player: Player): boolean
	if e.state == "ko" or e.state == "carried" or e.state == "gone" then
		return false
	end
	-- les enfants ne peuvent pas être frappés (règles Roblox) : ils détalent, rien de plus
	if e.data.child then
		e.target = player
		setState(e, "flee")
		Npcs.react(e, "flee")
		return false
	end
	local root = G.Util.root(player)
	local from = root and root.Position or e.root.Position
	getUp(e)
	-- attaque sournoise : par derrière et sans qu'il se batte
	local toPlayer = Vector3.new(from.X - e.root.Position.X, 0, from.Z - e.root.Position.Z)
	if toPlayer.Magnitude > 0.1 and e.root.CFrame.LookVector:Dot(toPlayer.Unit) < -0.3 and e.state ~= "fight" then
		dmg *= 2
	end
	e.hp -= dmg
	Npcs.setOp(e, player, -100)
	e.per.memory.assaulted = G.world.day
	if e.hp <= 0 then
		Npcs.knockOut(e, player)
		return true
	end
	face(e, from)
	Npcs.react(e, "hurt")
	G.Law.crime(player, "assault", from, e.data.id)
	G.Law.scream(e.root.Position, e)
	e.target = player
	if e.data.role == "sheriff" then
		e.lastSeen = from
		setState(e, "chase")
	elseif D.persona(e.data.persona).brave and e.hp > e.maxHp * 0.2 then
		setState(e, "fight")
	else
		setState(e, "flee")
	end
	return false
end

function Npcs.knockOut(e, player: Player?)
	setState(e, "ko")
	e.hp = 0
	e.per.ko = true
	e.koTime = G.Clock.now()
	e.hum:MoveTo(e.root.Position)
	play(e, "idle")
	-- couché au sol
	local pos = e.root.Position
	local y = G.Util.groundY(pos.X, pos.Z)
	e.root.Anchored = true
	e.model:PivotTo(CFrame.new(pos.X, math.max(y, pos.Y - 2.5) + 0.6, pos.Z) * CFrame.Angles(math.rad(-90), math.random() * 6, 0))
	G.Util.emote(e.model, "ko", 9999)
	G.Bodies.register(e)
	if player then
		G.Law.onKnockOut(player, e)
	end
end

-- Retour à la vie normale (le lendemain)
function Npcs.recover(e)
	e.per.ko = nil
	e.hp = e.maxHp
	local head = e.model:FindFirstChild("Head")
	local emote = head and head:FindFirstChild("Emote")
	if emote then
		emote:Destroy()
	end
	e.model:PivotTo(CFrame.new(homeOutside(e)))
	e.root.Anchored = false
	setState(e, "routine")
end

-- ----------------------------------------------------------------- Apparition

local function spawn(reg, n, per)
	local model = ServerStorage.Modeles.PNJ_Base:Clone()
	model.Name = n.name
	model:SetAttribute("NpcId", n.id)
	model:SetAttribute("Role", n.role) -- lu par le cadre de cible (et les tests)
	model:SetAttribute("Nom", n.name)
	G.Avatar.dress(model, n.look, n.role)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CollisionGroup = "PNJ"
		end
	end
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	hum.WalkSpeed = Config.NPC_WALK
	hum.UseJumpPower = true
	hum.JumpPower = 40
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local e = {
		id = n.id, data = n, per = per, reg = reg, model = model, hum = hum, root = root,
		state = "routine", stateTime = 0, think = math.random() * 0.25, goal = nil, goalTimer = 0,
		unseen = 0, barkCd = math.random(0, 10), hitCd = 0, pathAge = 0, stuck = 0, tracks = {},
		maxHp = n.maxHp or (n.role == "sheriff" and 160 or 80),
	}
	e.hp = e.maxHp
	e.pathObj = PathfindingService:CreatePath({
		AgentRadius = 1.6, AgentHeight = 5.2, AgentCanJump = true, WaypointSpacing = 6,
		Costs = { Water = math.huge },
	})
	-- position de départ
	local h = n.house and reg.houses[n.house]
	local entree = h and h.model.PrimaryPart:FindFirstChild("Entree")
	e.spawnPos = entree and (entree.WorldPosition + Vector3.new(math.random(-2, 2), 3, 1)) or workPos(e)
	model:PivotTo(CFrame.new(e.spawnPos))
	model.Parent = reg.npcFolder
	root:SetNetworkOwner(nil)
	-- animations
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	for _, a in model.Anims:GetChildren() do
		local ok, track = pcall(animator.LoadAnimation, animator, a)
		if ok then
			e.tracks[a.Name] = track
			if a.Name == "idle" or a.Name == "walk" or a.Name == "run" then
				track.Looped = true
			end
		end
	end
	hum.Running:Connect(function(speed)
		if e.lying or e.state == "ko" or e.state == "carried" then
			return
		end
		if speed > 12 then
			play(e, "run")
		elseif speed > 0.5 then
			play(e, "walk")
		else
			play(e, "idle")
		end
	end)
	play(e, "idle")
	-- invite de dialogue
	local head = model:FindFirstChild("Head")
	local p = G.Util.prompt(root, "talk", "Parler", n.name, { data = { Npc = n.id }, dist = 9 })
	e.prompt = p
	list[n.id] = e
	table.insert(reg.npcs, e)
	-- la nuit, il est déjà couché
	if not wantsOutside(e) and h then
		setState(e, "inside")
		if n.second then
			local dedans = h.model.PrimaryPart:FindFirstChild("Dedans")
			if dedans then
				model:PivotTo(CFrame.new(dedans.WorldPosition + Vector3.new(2, 3, 2)))
			end
		else
			lieDown(e)
		end
	end
	return e
end

function Npcs.onRegionLoad(reg)
	local folder = Instance.new("Folder")
	folder.Name = "Habitants"
	folder.Parent = reg.folder
	reg.npcFolder = folder
	reg.npcs = {}
	-- le 2e habitant d'une maison n'a pas de lit à lui
	local owners = {}
	for _, n in reg.plan.npcs do
		if n.house then
			if owners[n.house] then
				n.second = true
			end
			owners[n.house] = true
		end
	end
	for _, n in reg.plan.npcs do
		local per = Npcs.persist(n.id)
		if per.ko and not per.gone then
			per.ko = nil -- il s'est relevé pendant que la région était loin
		end
		if not per.gone then
			local ok, err = pcall(spawn, reg, n, per)
			if not ok then
				warn("[WildAcres] PNJ " .. n.name .. " : " .. tostring(err))
			end
			task.wait()
		end
	end
end

function Npcs.onRegionUnload(reg)
	for _, e in reg.npcs or {} do
		G.Bodies.forget(e)
		list[e.id] = nil
	end
end

-- PNJ ajouté par une couche à graine propre (Metiers : gens de métier, enfants, colporteur).
-- Même moteur que les habitants du plan ; `n` a la même forme qu'une entrée de reg.plan.npcs.
function Npcs.addExtra(reg, n)
	if list[n.id] or not reg.npcFolder then
		return list[n.id]
	end
	local per = Npcs.persist(n.id)
	if per.ko and not per.gone then
		per.ko = nil
	end
	if per.gone then
		return nil
	end
	local ok, e = pcall(spawn, reg, n, per)
	if not ok then
		warn("[WildAcres] PNJ " .. tostring(n.name) .. " : " .. tostring(e))
		return nil
	end
	return e
end

-- Retire un PNJ vivant (le colporteur qui reprend la route)
function Npcs.remove(e)
	G.Bodies.forget(e)
	list[e.id] = nil
	for p, id in talking do
		if id == e.id then
			talking[p] = nil
			G.remotes.Dialog:FireClient(p, nil)
		end
	end
	local npcs = e.reg and e.reg.npcs
	local i = npcs and table.find(npcs, e)
	if i then
		table.remove(npcs, i)
	end
	if e.model then
		e.model:Destroy()
	end
end

-- habitants debout d'une région (quêtes : un village sans personne debout est « déserté »)
function Npcs.standingIn(regKey: string): number
	local n = 0
	for _, e in list do
		local st = e.state
		if e.reg and e.reg.key == regKey and e.model.Parent and st ~= "ko" and st ~= "carried" and st ~= "gone" then
			n += 1
		end
	end
	return n
end

function Npcs.byId(id: string)
	return list[id]
end

function Npcs.byModel(model: Instance)
	local m = model:FindFirstAncestorOfClass("Model")
	while m do
		local id = m:GetAttribute("NpcId")
		if id then
			return list[id]
		end
		m = m:FindFirstAncestorOfClass("Model")
	end
	return nil
end

function Npcs.saveAll()
	-- l'état durable (opinion, mémoire, disparu…) vit déjà dans G.world.npcs
end

function Npcs.newDay()
	for id, per in G.world.npcs do
		if not per.gone then
			for uid, v in per.ops or {} do
				if v < 0 and v > -60 then
					per.ops[uid] = math.min(v + 3, 0)
				end
			end
		end
	end
	for _, e in list do
		if e.state == "ko" then
			Npcs.recover(e)
		elseif e.state ~= "gone" and e.state ~= "carried" then
			e.hp = e.maxHp
			e.woken = false
			if e.state ~= "inside" then
				setState(e, "routine")
			end
		end
	end
end

-- ----------------------------------------------------------------- Dialogue

local function textVars(e, player: Player, extra)
	local prof = G.Joueurs.get(player)
	local vars = { titre = D.title_for(prof.honor), nom = e.data.name, victime = e.per.memory.victime or "quelqu'un" }
	for k, v in D.gender(e.per.memory.victime_f == true) do
		vars[k] = v
	end
	if extra then
		for k, v in extra do
			vars[k] = v
		end
	end
	return vars
end

local GIFTABLE = { "flower", "berries", "mushroom", "egg", "milk", "wool", "fish_1", "fish_2", "fish_3", "fish_4", "fish_5", "fish_6", "fish_7", "parsnip", "carrot", "potato", "wheat", "tomato", "melon", "beetroot", "eggplant", "pumpkin" }

local function options(e, player: Player)
	if e.data.child then
		return G.Metiers.childOptions(e, player)
	end
	local prof = G.Joueurs.get(player)
	local opts = { { id = "chat", text = "Discuter" }, { id = "rumor", text = "Des nouvelles du coin ?" } }
	if RelationsPnj.disponible(e.per, G.world.day, G.Util.pid(player), "cadeau") then
		for _, item in GIFTABLE do
			if (prof.inv[item] or 0) > 0 then
				table.insert(opts, { id = "gift", text = "Offrir un cadeau…" })
				break
			end
		end
	end
	local role = e.data.role
	if role == "merchant" or role == "farmer" or e.data.persona == "filou" then
		table.insert(opts, { id = "trade", text = role == "merchant" and "Voir la boutique" or (role == "farmer" and "Acheter des bêtes / vendre" or "Revendre (sans questions)") })
	end
	-- (le colporteur est de passage : il n'a pas de travail du village à donner)
	if e.data.metier ~= "peddler" and G.Quetes and G.Quetes.isVillage and G.Quetes.isVillage(e.reg and e.reg.key) then
		table.insert(opts, 2, { id = "quetes", text = "📜 Tu as du travail pour moi ?" })
	end
	if role == "farmer" and G.Ouvriers and rawget(G.Ouvriers, "hire") then
		table.insert(opts, { id = "ouvrier", text = "👨‍🌾 Louer un ouvrier (" .. G.Ouvriers.WAGE .. " or / jour, " .. G.Ouvriers.DAYS .. " jours)" })
	end
	if role == "merchant" then
		table.insert(opts, { id = "orders", text = "Les commandes du village" })
		table.insert(opts, { id = "bank", text = "La banque (coffre sûr)" })
	end
	table.insert(opts, { id = "bye", text = "Au revoir" })
	if e.data.metier then
		G.Metiers.addOptions(e, player, opts) -- comptoir et services du métier, avant « Au revoir »
	end
	return opts
end

local function send(player: Player, e, text: string, opts)
	local label = (e.data.role == "sheriff" and "Shérif" or (e.data.role == "merchant" and "Marchand" or (e.data.role == "farmer" and "Fermier" or "Habitant")))
	if e.data.female then
		label = ({ Habitant = "Habitante", Marchand = "Marchande", Fermier = "Fermière" })[label] or label
	end
	if e.data.metier then
		label = G.Metiers.label(e)
	end
	G.remotes.Dialog:FireClient(player, {
		npc = e.id, name = e.data.name, role = label .. " · " .. D.persona(e.data.persona).label,
		opinion = Npcs.op(e, player), text = text, options = opts,
	})
end

function Npcs.talk(player: Player, id: string)
	local e = list[id]
	if not e or not e.model.Parent then
		return
	end
	local s = e.state
	if s == "ko" or s == "carried" or s == "gone" or s == "fight" or s == "chase" then
		return
	end
	local prof = G.Joueurs.get(player)
	if asleep(e) then
		e.woken = true
		getUp(e)
		G.Util.emote(e.model, "alert")
		Npcs.addOp(e, player, -5)
	end
	if prof.stars > 0 and e.data.role ~= "sheriff" then
		send(player, e, D.line(e.data.persona, "wanted", textVars(e, player)), { { id = "bye", text = "…" } })
		e.target = player
		setState(e, "flee")
		Npcs.react(e, "wanted")
		return
	end
	if e.state ~= "inside" then
		setState(e, "talk")
	end
	local root = G.Util.root(player)
	if root then
		face(e, root.Position)
	end
	if RelationsPnj.enregistrer(e.per, G.world.day, G.Util.pid(player), "salutation") then
		Npcs.addOp(e, player, 1)
	end
	talking[player] = id
	if not asleep(e) and not e.lying then
		oneShot(e, "wave") -- il salue de la main
	end
	local key = D.greeting_key(e.per, prof.honor, prof.stars, true, Npcs.op(e, player))
	Npcs.react(e, key)
	-- les enfants (et le colporteur de passage) ont leurs propres mots
	local text = (e.data.metier and G.Metiers.greet(e, player)) or D.line(e.data.persona, key, textVars(e, player))
	send(player, e, text, options(e, player))
end

local function rumor(e, player: Player): string
	local reg = e.reg
	-- rumeur de marché (19/11) : une pénurie dans un des villages les plus proches (Shop.shortage)
	local Q = G.Quetes and rawget(G.Quetes, "villages")
	local S = G.Shop and rawget(G.Shop, "shortage")
	if Q and S and e.root and math.random() < 0.4 then
		local pos = e.root.Position
		local near = {}
		for _, v in Q() do
			table.insert(near, { v = v, d = Vector2.new(v.x - pos.X, v.z - pos.Z).Magnitude })
		end
		table.sort(near, function(a, b)
			return a.d < b.d
		end)
		local hits = {}
		for i = 1, math.min(4, #near) do
			local short = S(near[i].v.key)
			local info = short and Config.ITEMS[short]
			if info then
				table.insert(hits, { v = near[i].v, info = info, here = near[i].d < 110 })
			end
		end
		if #hits > 0 then
			local h = hits[math.random(1, #hits)]
			if h.here then
				return "Ici, on manque de " .. h.info.icon .. " " .. h.info.name .. " ces jours-ci. Qui en apporte fera une bonne affaire."
			end
			return "On raconte qu'à " .. h.v.name .. ", ils manquent de " .. h.info.icon .. " " .. h.info.name .. " : ils paient cher pour en avoir."
		end
	end
	local places = G.wg:placesAround(reg.rx, reg.rz, 3)
	if #places == 0 then
		return "Il n'y a rien à des lieues à la ronde."
	end
	local poi = places[math.random(1, #places)]
	local ax, az = poi.ax * Config.CELL, poi.az * Config.CELL
	local pos = e.root.Position
	local dir = D.direction_word(ax - pos.X, az - pos.Z)
	return D.line(e.data.persona, "rumor", textVars(e, player, { lieu = G.WG.placeLabel(poi), dir = dir }))
end

function Npcs.choice(player: Player, choice: string)
	local id = talking[player]
	local e = id and list[id]
	if not e or type(choice) ~= "string" then
		return
	end
	local prof = G.Joueurs.get(player)
	if e.state == "talk" then
		e.stateTime = 0
	end
	if choice == "chat" then
		local key = (e.per.memory.heard and math.random() < 0.5) and "gossip" or "chat"
		if RelationsPnj.enregistrer(e.per, G.world.day, G.Util.pid(player), "discussion") then
			Npcs.addOp(e, player, 2)
		end
		Npcs.react(e, key)
		if key == "gossip" or math.random() < 0.3 then
			oneShot(e, "laugh")
		end
		send(player, e, D.line(e.data.persona, key, textVars(e, player)), options(e, player))
	elseif choice == "rumor" then
		oneShot(e, "point") -- il montre la direction du doigt
		send(player, e, rumor(e, player), options(e, player))
	elseif choice == "gift" then
		if not RelationsPnj.disponible(e.per, G.world.day, G.Util.pid(player), "cadeau") then
			return
		end
		local opts = {}
		for _, item in GIFTABLE do
			if (prof.inv[item] or 0) > 0 then
				local info = Config.ITEMS[item]
				table.insert(opts, { id = "give:" .. item, text = info.icon .. " " .. info.name })
				if #opts >= 6 then
					break
				end
			end
		end
		table.insert(opts, { id = "back", text = "Non, rien" })
		send(player, e, "(Que veux-tu offrir à " .. e.data.name .. " ?)", opts)
	elseif string.sub(choice, 1, 5) == "give:" then
		local item = string.sub(choice, 6)
		local day, uid = G.world.day, G.Util.pid(player)
		if not RelationsPnj.disponible(e.per, day, uid, "cadeau")
			or not table.find(GIFTABLE, item) or not G.Joueurs.take(player, item, 1) then
			return
		end
		RelationsPnj.enregistrer(e.per, day, uid, "cadeau")
		local info = Config.ITEMS[item]
		local gain = (info.price or 10) >= 50 and 15 or 10
		local charisme = G.Joueurs.stats(player).charisme or 0
		Npcs.addOp(e, player, gain + charisme)
		Npcs.react(e, "gift")
		oneShot(e, "cheer") -- ravi du cadeau
		send(player, e, D.line(e.data.persona, "gift", textVars(e, player)), options(e, player))
	elseif choice == "back" then
		send(player, e, "…", options(e, player))
	elseif string.sub(choice, 1, 2) == "m:" and e.data.metier then
		-- services des gens de métier (Metiers.choice) : un texte = le dialogue continue, false = fermé
		local res = G.Metiers.choice(player, e, string.sub(choice, 3))
		if type(res) == "string" then
			send(player, e, res, options(e, player))
		elseif res == false then
			G.remotes.Dialog:FireClient(player, nil)
			talking[player] = nil
			if e.state == "talk" then
				setState(e, "routine")
			end
		end
	elseif choice == "quetes" then
		G.remotes.Dialog:FireClient(player, nil)
		talking[player] = nil
		if e.state == "talk" then
			e.stateTime = 0
		end
		G.Quetes.openNpc(player, e)
	elseif choice == "ouvrier" and e.data.role == "farmer" and G.Ouvriers and rawget(G.Ouvriers, "hire") then
		send(player, e, G.Ouvriers.hire(player, e), options(e, player))
	elseif choice == "orders" or choice == "bank" then
		G.remotes.Dialog:FireClient(player, nil)
		talking[player] = nil
		if choice == "orders" then
			G.Economie.openOrders(player, e)
		else
			G.Economie.openBank(player, e)
		end
	elseif choice == "trade" then
		-- un crime vient d'être vu dans le coin : on ferme boutique un moment
		if G.Law.alerted and G.Law.alerted(e.reg and e.reg.key) then
			send(player, e, "On ferme ! Il y a un voleur dans le coin… Reviens plus tard.", { { id = "bye", text = "D'accord" } })
			return
		end
		local score = Npcs.op(e, player) + prof.honor / 2
		if score <= -30 then
			Npcs.react(e, "refuse")
			send(player, e, D.line(e.data.persona, "refuse", textVars(e, player)), { { id = "bye", text = "Tant pis" } })
			return
		end
		G.remotes.Dialog:FireClient(player, nil)
		talking[player] = nil
		G.Shop.open(player, e)
	else -- bye
		Npcs.react(e, "bye")
		G.remotes.Dialog:FireClient(player, { npc = e.id, name = e.data.name, text = D.line(e.data.persona, "bye", textVars(e, player)), options = {}, closing = true })
		talking[player] = nil
		if e.state == "talk" then
			setState(e, "routine")
		end
	end
end

return Npcs
