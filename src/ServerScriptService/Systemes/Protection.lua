-- Protection de la maison, esprit GTA : on PEUT te cambrioler, à toi de te protéger.
--  · Serrures (4 niveaux) sur coffres et portes. Crocheter = un crochet + un mini-jeu vérifié par le
--    serveur + la compétence Crochetage (monte en pratiquant) + le talent pour les serrures dures.
--  · Porte en bois (s'ouvre pour son propriétaire, se crochète sinon), serrure d'entraînement.
--  · Cloche d'alarme : un crime sur la parcelle compte comme vu et prévient tout le monde.
--  · La nuit, des cambrioleurs PNJ visent les coffres des parcelles : en direct si le propriétaire
--    est dans le coin, sinon une simulation (gardiens, alarme et serrures comptent).
--  · Journal d'absence : ce qui s'est passé chez toi, lu à ton retour.

local CollectionService = game:GetService("CollectionService")

local Protection = {}
local G, Config

function Protection.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("door", function(player, prompt)
		Protection.useDoor(player, prompt:GetAttribute("Placed"))
	end)
	G.Interact.onPrompt("practice", function(player, prompt)
		Protection.practice(player, prompt:GetAttribute("Placed"))
	end)
end

-- ----------------------------------------------------------------- Outils

local function findPlaced(id: string)
	if type(id) ~= "string" then
		return nil, nil
	end
	for _, reg in G.World.loaded do
		for _, d in reg.state.placed do
			if d.id == id then
				return d, reg
			end
		end
	end
	return nil, nil
end
Protection.findPlaced = findPlaced

local function recOf(uid: string)
	return G.world and G.world.players[string.sub(uid or "", 2)]
end

-- Journal du propriétaire (minor = juste un message s'il est là, rien d'enregistré)
function Protection.log(uid: string, text: string, minor: boolean?)
	local owner = G.Util.playerOf(uid)
	if owner then
		G.Util.toast(owner, "🏡 " .. text, minor and nil or "danger")
	end
	if minor then
		return
	end
	local rec = recOf(uid)
	if rec and not owner then
		rec.log = rec.log or {}
		table.insert(rec.log, { day = G.world.day, text = text })
		while #rec.log > 25 do
			table.remove(rec.log, 1)
		end
	end
end

function Protection.showLog(player: Player)
	local rec = G.Mondes.playerRecord(player)
	if rec.log and #rec.log > 0 then
		G.Util.toast(player, "📜 Pendant ton absence (" .. #rec.log .. ") :", "big")
		for i, e in rec.log do
			task.delay(1 + i * 1.2, function()
				G.Util.toast(player, "Jour " .. e.day .. " — " .. e.text)
			end)
		end
		rec.log = {}
	end
end

-- Lumière proche (lampadaires, lanternes) : position ou nil
local lights, lightsAt = {}, 0
function Protection.lightNear(pos: Vector3, radius: number): Vector3?
	if os.clock() - lightsAt > 3 then
		lightsAt = os.clock()
		lights = {}
		for _, p in CollectionService:GetTagged("LumiereNuit") do
			if p:IsA("BasePart") and p:IsDescendantOf(workspace) then
				table.insert(lights, p.Position)
			end
		end
	end
	for _, lp in lights do
		local dx, dz = lp.X - pos.X, lp.Z - pos.Z
		if dx * dx + dz * dz < radius * radius then
			return lp
		end
	end
	return nil
end

-- Une cloche d'alarme protège-t-elle cet endroit ? → identifiant du propriétaire
function Protection.alarmAt(pos: Vector3): string?
	local owner = G.Parcelles.at(pos)
	if not owner then
		return nil
	end
	for _, reg in G.World.loaded do
		for _, d in reg.state.placed do
			if d.item == "alarm" and d.owner == owner and G.Parcelles.at(Vector3.new(d.x, 0, d.z)) == owner then
				return owner
			end
		end
	end
	return nil
end

-- L'alarme sonne : tout le voisinage et le propriétaire sont prévenus
function Protection.ring(owner: string, culprit: Player?, pos: Vector3)
	local who = culprit and culprit.DisplayName or "quelqu'un"
	for _, p in G.Game.players() do
		local r = G.Util.root(p)
		if r and (r.Position - pos).Magnitude < 220 and not G.Util.owns(p, owner) then
			G.Util.toast(p, "🔔 Une alarme sonne tout près !", "danger")
		end
	end
	Protection.log(owner, "🔔 Alarme : " .. who .. " s'introduit chez toi !")
end

-- ----------------------------------------------------------------- Serrures

-- Poser une serrure : sur son propre coffre ou sa porte, juste devant soi
function Protection.useLock(player: Player, item: string)
	local info = Config.ITEMS[item]
	local root = G.Util.root(player)
	if not info or not info.lock or not root then
		return
	end
	local best, bd = nil, 9
	for _, reg in G.World.loaded do
		for _, d in reg.state.placed do
			if (d.item == "chest" or d.item == "door" or d.item == "drawbridge" or d.item == "trapdoor") and G.Util.owns(player, d.owner) then
				local dist = (Vector3.new(d.x, root.Position.Y, d.z) - root.Position).Magnitude
				if dist < bd then
					best, bd = d, dist
				end
			end
		end
	end
	if not best then
		G.Util.toast(player, "Approche-toi d'un de TES coffres, portes, pont-levis ou trappes.")
		return
	end
	if (best.lock or 0) >= info.lock then
		G.Util.toast(player, "Il a déjà une serrure aussi solide.")
		return
	end
	if not G.Joueurs.take(player, item, 1) then
		return
	end
	best.lock = info.lock
	best.lockBonus = G.Joueurs.talent(player, "serrurier") -- compte contre les cambrioleurs
	G.Util.toast(player, "🔒 " .. info.name .. " posée (" .. (best.item == "chest" and "coffre" or "porte") .. ").", "gain")
	G.Joueurs.sync(player)
end

local function canPick(player: Player, tier: number): (boolean, string?)
	if G.Joueurs.count(player, "lockpick") < 1 then
		return false, "Verrouillé. Il te faut un crochet 🎣 (atelier, onglet Sécurité)."
	end
	local need = Config.LOCK_SKILL[tier] or 0
	if G.Joueurs.skill(player, "crochetage") < need then
		return false, Config.LOCKS[tier].name .. " : il faut 🎣 Crochetage " .. need .. " (tu es " .. G.Joueurs.skill(player, "crochetage") .. ")."
	end
	if tier >= 2 and G.Joueurs.talent(player, "crochetage") < tier - 1 then
		return false, Config.LOCKS[tier].name .. " : il faut le talent Crochetage rang " .. (tier - 1) .. "."
	end
	return true, nil
end

-- Mini-jeu de crochetage ; practice = sans crime et moins d'expérience
local function pick(player: Player, tier: number, at: Vector3, practice: boolean, onOk: () -> (), onFail: (() -> ())?)
	local L = Config.LOCKS[tier]
	local skill = G.Joueurs.skill(player, "crochetage")
	local rank = G.Joueurs.talent(player, "crochetage")
	G.Minijeux.start(player, {
		title = (practice and "Entraînement : " or "Crochetage : ") .. L.name,
		hint = "Soulève chaque goupille : appuie quand l'aiguille est dans la zone. Le moindre faux pas fait du bruit.",
		pins = L.pins,
		zone = math.clamp(L.zone * (1 + skill / 60) + 0.015 * rank, 0.05, 0.45),
		speed = L.speed * (1 - skill / 150),
		misses = tier <= 2 and 1 or 0,
		timeout = 12 + L.pins * 5,
		near = function()
			local r = G.Util.root(player)
			return r ~= nil and (Vector3.new(at.X, r.Position.Y, at.Z) - r.Position).Magnitude < 9
		end,
	}, function(ok)
		if ok then
			G.Joueurs.addSkillXp(player, "crochetage", (practice and 3 or 9) * tier)
			onOk()
		else
			G.Joueurs.addSkillXp(player, "crochetage", (practice and 1 or 2) * tier)
			if math.random() < L.breakChance * (1 - skill / 80) then
				G.Joueurs.take(player, "lockpick", 1)
				G.Util.toast(player, "Crac ! Ton crochet s'est cassé.")
				G.Joueurs.sync(player)
			end
			if onFail then
				onFail()
			end
		end
	end)
end

-- Accès à un coffre / une porte : le propriétaire passe, les autres crochètent (crime)
function Protection.access(player: Player, d, onOpen: () -> ())
	-- autorisé par le propriétaire (/autoriser) : on ouvre comme chez soi, sans crime, mais c'est noté
	if d.owner and not G.Util.owns(player, d.owner) and G.Util.trusted(player, d.owner, "coffres") then
		G.Protection.log(d.owner, player.DisplayName .. " a ouvert ta " .. (d.item == "chest" and "malle" or "porte") .. " (autorisé).", false)
		onOpen()
		return
	end
	if not d.owner or G.Util.owns(player, d.owner) or (d.lock or 0) == 0 then
		if d.owner and not G.Util.owns(player, d.owner) and (d.item == "door" or d.item == "drawbridge" or d.item == "trapdoor") then
			G.Law.crime(player, "breakin", Vector3.new(d.x, 0, d.z), d.owner)
		end
		onOpen()
		return
	end
	local ok, why = canPick(player, d.lock)
	if not ok then
		G.Util.toast(player, "🔒 " .. (why or "Verrouillé."))
		return
	end
	local pos = Vector3.new(d.x, 0, d.z)
	pick(player, d.lock, pos, false, function()
		G.Law.crime(player, "breakin", pos, d.owner)
		G.Protection.log(d.owner, player.DisplayName .. " a crocheté ta " .. (d.item == "chest" and "serrure de coffre" or "porte") .. ".", true)
		onOpen()
	end, function()
		-- raté : ça fait du bruit
		local owner = Protection.alarmAt(pos)
		if owner then
			Protection.ring(owner, player, pos)
			G.Law.crime(player, "breakin", pos, d.owner)
		end
	end)
end

-- ----------------------------------------------------------------- Portes

local function setDoorOpen(d, reg, open: boolean)
	for _, m in reg.placedModels or {} do
		if m.Name == "Porte" and m.Parent then
			local p = m:GetPivot().Position
			if math.abs(p.X - d.x) < 0.3 and math.abs(p.Z - d.z) < 0.3 then
				for _, part in m:GetDescendants() do
					if part:IsA("BasePart") and part.Name == "Battant" then
						part.CanCollide = not open
						part.Transparency = open and 0.65 or 0
					end
				end
			end
		end
	end
end

function Protection.useDoor(player: Player, id: string)
	local d, reg = findPlaced(id)
	if not d or d.item ~= "door" then
		return
	end
	Protection.access(player, d, function()
		setDoorOpen(d, reg, true)
		task.delay(4, function()
			setDoorOpen(d, reg, false)
		end)
	end)
end

function Protection.practice(player: Player, id: string)
	local d = findPlaced(id)
	if not d then
		return
	end
	-- la serrure la plus dure que tu as le droit d'essayer
	local tier = 1
	for t = 4, 1, -1 do
		if canPick(player, t) then
			tier = t
			break
		end
	end
	local ok, why = canPick(player, tier)
	if not ok then
		G.Util.toast(player, why or "")
		return
	end
	pick(player, tier, Vector3.new(d.x, 0, d.z), true, function()
		G.Util.toast(player, "Clic ! (" .. Config.LOCKS[tier].name .. ")", "gain")
	end, nil)
end

-- ----------------------------------------------------------------- Cambrioleurs

local function chestsOf(uid: string, plot)
	local out = {}
	local h = G.Parcelles.HALF
	for key, rs in G.world.regions do
		for _, d in rs.placed or {} do
			if d.item == "chest" and d.owner == uid and math.abs(d.x - plot.x) <= h and math.abs(d.z - plot.z) <= h then
				table.insert(out, d)
			end
		end
		local _ = key
	end
	return out
end

-- Vole une partie d'un coffre : renvoie {objet = n} et le texte du journal.
-- Règles : on ne vide jamais un coffre (au moins 1 de chaque reste), 3 tas au plus, et moins
-- quand le propriétaire est absent (gentle = true).
local function rob(d, gentle: boolean?)
	local stolen, parts = {}, {}
	local ids = {}
	for item, n in d.items or {} do
		if n > 1 then
			table.insert(ids, item)
		end
	end
	for _ = 1, math.min(gentle and 2 or 3, #ids) do
		local i = math.random(1, #ids)
		local item = table.remove(ids, i)
		local share = gentle and (0.15 + math.random() * 0.15) or (0.3 + math.random() * 0.3)
		local n = math.clamp(math.floor(d.items[item] * share), 1, d.items[item] - 1)
		d.items[item] -= n
		if d.items[item] <= 0 then
			d.items[item] = nil
		end
		stolen[item] = n
		table.insert(parts, n .. " " .. (Config.ITEMS[item] and Config.ITEMS[item].name or item))
	end
	return stolen, table.concat(parts, ", ")
end

local function guardsOf(uid: string, plot): number
	local rec = recOf(uid)
	local n = 0
	for _, pet in (rec and rec.pets) or {} do
		local t = G.Compagnons.traits(pet.kind)
		if pet.mode == "guard" and t and t.guard and math.abs((pet.hx or 0) - plot.x) <= 30 and math.abs((pet.hz or 0) - plot.z) <= 30 then
			n += t.fight and 1 or 0.5
		end
	end
	return n
end

local function burglarSkill(): number
	local r = math.random()
	return r < 0.45 and 1 or (r < 0.8 and 2 or (r < 0.96 and 3 or 4))
end

-- Simulation pour les parcelles sans propriétaire dans le coin (une tentative par nuit au plus)
local raidDay = -1
local function offlineRaids()
	for uidNum, rec in G.world.players do
		local plots = G.Parcelles.plotsOf(rec)
		local plot = #plots > 0 and plots[math.random(1, #plots)] or nil
		local uid = "u" .. uidNum
		local owner = G.Util.playerOf(uid)
		local ownerRoot = owner and G.Util.root(owner)
		local near = ownerRoot and (Vector3.new(plot and plot.x or 0, 0, plot and plot.z or 0) - Vector3.new(ownerRoot.Position.X, 0, ownerRoot.Position.Z)).Magnitude < 160
		-- un absent n'est jamais une cible facile : une tentative tous les 3 jours au plus
		if plot and not near and (G.world.day - (rec.lastRaid or -99)) >= 3 and math.random() < 0.3 then
			rec.lastRaid = G.world.day
			task.spawn(function()
				local rx, rz = G.WG.regionOf(math.floor(plot.x / Config.CELL), math.floor(plot.z / Config.CELL))
				G.Mondes.ensureRegion(rx, rz)
				if G.Tourelles and rawget(G.Tourelles, "repel") and G.Tourelles.repel(uid, plot) then
					return -- une tourelle garnie a tiré : le cambrioleur a fui (noté au journal)
				end
				local guards = guardsOf(uid, plot)
				if guards > 0 and math.random() < math.min(0.9, 0.55 + 0.15 * guards) then
					Protection.log(uid, "Tes gardiens ont fait fuir un cambrioleur cette nuit.")
					return
				end
				local hasAlarm = false
				for _, rs in G.world.regions do
					for _, d in rs.placed or {} do
						if d.item == "alarm" and d.owner == uid then
							hasAlarm = true
						end
					end
				end
				if hasAlarm and math.random() < 0.5 then
					Protection.log(uid, "🔔 Ton alarme a fait fuir un cambrioleur cette nuit.")
					return
				end
				local skill = burglarSkill()
				for _, d in chestsOf(uid, plot) do
					local tier = (d.lock or 0) + (d.lockBonus or 0)
					if d.items and next(d.items) and skill >= tier then
						local _, text = rob(d, true)
						if text == "" then
							continue
						end
						Protection.log(uid, "Un cambrioleur a forcé ton coffre" .. ((d.lock or 0) > 0 and (" (" .. Config.LOCKS[d.lock].name .. ")") or " (sans serrure)") .. " : " .. text .. ".")
						return
					end
				end
				Protection.log(uid, "Un cambrioleur a rôdé chez toi… tes serrures ont tenu.")
			end)
		end
	end
end

-- Cambrioleur en chair et en os, quand le propriétaire est dans le coin
local burglars = {} -- en -> {uid, plot, targets, i, t, state}
local liveDay = {}

local function spawnBurglar(uid: string, plot)
	local chests = chestsOf(uid, plot)
	if #chests == 0 then
		return
	end
	local a = math.random() * math.pi * 2
	local pos = Vector3.new(plot.x + math.cos(a) * 60, 0, plot.z + math.sin(a) * 60)
	local reg = G.World.regionAt(pos)
	if not reg or not reg.ready or G.Util.isWater(pos.X, pos.Z) then
		return
	end
	local en = G.Enemies.spawn(reg, { id = "cambrioleur#" .. math.random(1, 1e9), kind = "burglar", x = pos.X, z = pos.Z }, reg.enemyFolder)
	if not en then
		return
	end
	en.transient = true
	en.loot = {}
	burglars[en] = { uid = uid, plot = plot, targets = chests, i = 1, t = 0, state = "approach", skill = burglarSkill() }
end

function Protection.burglarHit(en, player: Player)
	local b = burglars[en]
	if b then
		b.state = "flee"
		b.t = 0
		G.Util.toast(player, "Le cambrioleur détale !")
	end
end

local function thinkBurglar(en, b, dt: number)
	b.t += dt
	local k = en.k
	-- un joueur trop près, ou un gardien qui gronde : il file
	if b.state ~= "flee" then
		local p, pd = G.Util.nearestPlayer(en.pos, 12)
		if p and pd < 10 then
			b.state = "flee"
			b.t = 0
		end
		for _, pet in G.Compagnons.list do
			local t = G.Compagnons.traits(pet.kind)
			if t and t.guard and pet.owner == b.uid and (pet.pos - en.pos).Magnitude < 16 then
				b.state = "flee"
				b.t = 0
				break
			end
		end
	end
	if b.state == "approach" then
		local d = b.targets[b.i]
		if not d then
			b.state = "flee"
			return
		end
		local target = Vector3.new(d.x, en.pos.Y, d.z)
		if (target - en.pos).Magnitude > 3 then
			G.Enemies.move(en, target, k.speed * 0.7, dt)
			en.hop += dt * 6
		else
			b.state = "picking"
			b.t = 0
			if Protection.alarmAt(target) then
				Protection.ring(b.uid, nil, target)
			end
		end
	elseif b.state == "picking" then
		local d = b.targets[b.i]
		local tier = (d.lock or 0) + (d.lockBonus or 0)
		if b.t > 3 + tier * 3 then
			if b.skill >= tier and d.items and next(d.items) then
				local stolen, text = rob(d, false)
				for item, n in stolen do
					en.loot[item] = (en.loot[item] or 0) + n
				end
				Protection.log(b.uid, "Un cambrioleur a forcé ton coffre : " .. text .. " ! Rattrape-le !")
				b.state = "flee"
			else
				b.i += 1
				b.state = "approach"
			end
			b.t = 0
		end
	elseif b.state == "flee" then
		local away = en.pos - Vector3.new(b.plot.x, en.pos.Y, b.plot.z)
		if away.Magnitude < 1 then
			away = Vector3.new(1, 0, 0)
		end
		G.Enemies.move(en, en.pos + away.Unit * 10, k.speed, dt)
		en.hop += dt * 9
		if b.t > 14 then
			en.dead = true
			en.model:Destroy()
		end
	end
	G.Enemies.render(en)
end

local acc, nightAcc = 0, 0
function Protection.step(dt: number)
	acc += dt
	if acc < 0.1 then
		return
	end
	local step = acc
	acc = 0
	for en, b in burglars do
		if en.dead or not en.model.Parent then
			burglars[en] = nil
		else
			local ok, err = pcall(thinkBurglar, en, b, step)
			if not ok then
				warn("[WildAcres] cambrioleur : " .. tostring(err))
				burglars[en] = nil
			end
		end
	end
	nightAcc += step
	if nightAcc < 15 then
		return
	end
	nightAcc = 0
	local h = G.Clock.hour()
	if not G.Clock.isNight() then
		for en in burglars do
			en.dead = true
			en.model:Destroy()
		end
		table.clear(burglars)
		return
	end
	-- vers 2 h du matin : les tentatives « à distance »
	if h >= 1 and h < 5 and raidDay ~= G.world.day then
		raidDay = G.world.day
		offlineRaids()
	end
	-- cambrioleur en direct près des parcelles dont le propriétaire est dans le coin
	for _, p in G.Game.players() do
		local rec = G.Mondes.playerRecord(p)
		local root = G.Util.root(p)
		local uid = G.Util.pid(p)
		if root and liveDay[uid] ~= G.world.day then
			for _, plot in G.Parcelles.plotsOf(rec) do
				local dist = (Vector3.new(plot.x, root.Position.Y, plot.z) - root.Position).Magnitude
				if dist < 160 and math.random() < 0.12 then
					liveDay[uid] = G.world.day
					spawnBurglar(uid, plot)
					break
				end
			end
		end
	end
end

return Protection
