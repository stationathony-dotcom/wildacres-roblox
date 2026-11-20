-- Déroulé de la partie en multi : arrivée dans le monde (perso global + position dans ce monde),
-- sommeil (perso ; on saute la nuit seulement si TOUT le monde dort), évanouissement, arrestation,
-- nage (endurance et noyade). Le temps du monde ne s'arrête jamais.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Game = {}
local G
local playing = {}
local sleepers = {} -- joueur -> heure de réveil (os.clock)
local dawnAt, dawnDay
local sprinting = {} -- joueur -> true pendant qu'il tient [Maj]
local fallTop = {} -- joueur -> plus haute position Y depuis qu'il a quitté le sol (chute)

function Game.init(g)
	G = g
	-- course : le client dit quand [Maj] est tenu ; le serveur décide de la vitesse (endurance)
	G.Interact.onAction("sprint", function(player, data)
		sprinting[player] = type(data) == "table" and data.on == true or nil
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		sprinting[p] = nil
	end)
	G.Interact.onAction("start", function(player)
		Game.start(player)
	end)
	G.Interact.onAction("newgame", function(player)
		G.Save.wipe(player)
		playing[player] = nil
		player:Kick("Perso remis à zéro : relance le jeu.")
	end)
	G.Interact.onAction("save", function(player)
		if G.Save.save(player) then
			G.Util.toast(player, "Partie sauvegardée.")
		else
			G.Util.toast(player, "Sauvegarde en mémoire seulement (Studio sans accès aux API).")
		end
	end)
	G.Interact.onAction("crouch", function(player, data)
		player:SetAttribute("Crouch", data.on == true)
	end)
	Players.PlayerRemoving:Connect(function(p)
		if playing[p] == true then
			pcall(G.Horses.dismount, p, true)
			pcall(G.Bodies.drop, p, true)
			pcall(G.Economie.cancel, p, "L'autre joueur est parti.") -- avant l'instantané
			G.Save.save(p, true) -- instantané pris tout de suite, écriture ensuite
		end
		playing[p] = nil
		sleepers[p] = nil
		fallTop[p] = nil
	end)
end

function Game.isPlaying(player: Player): boolean
	return playing[player] == true
end

function Game.players()
	local out = {}
	for p, st in playing do
		if st == true and p.Parent then
			table.insert(out, p)
		end
	end
	return out
end

local function vec(t): Vector3?
	if type(t) == "table" and t[1] then
		return Vector3.new(t[1], t[2], t[3])
	end
	return nil
end

-- Point d'apparition du monde (devant la ruine de départ)
function Game.spawnPos(): Vector3
	return G.World.startPos()
end

-- Chez soi : son lit s'il en a un dans ce monde, sinon l'arrivée
function Game.homePos(player: Player?): Vector3
	local rec = player and G.Mondes.playerRecord(player)
	local bed = rec and vec(rec.bed)
	if bed then
		return bed
	end
	-- pas de lit dans ce monde : l'avant-poste de son clan le plus proche, s'il y en a un
	local root = player and G.Util.root(player)
	local ap = player and G.Avantpostes and G.Avantpostes.respawnFor and G.Avantpostes.respawnFor(player, root and root.Position)
	return ap or Game.spawnPos()
end

local function setupCharacter(player: Player, char: Model, spawnPos: Vector3?)
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	hum.BreakJointsOnDeath = false
	player:SetAttribute("SpawnShield", os.clock() + 20) -- pas de « kill à l'arrivée »
	Game.noFall(player, 5) -- l'apparition se fait un peu au-dessus du sol
	G.Joueurs.applyStats(player)
	hum.Health = hum.MaxHealth
	player:SetAttribute("Stamina", G.Config.MAX_STAMINA)
	player:SetAttribute("Riding", false)
	player:SetAttribute("Carrying", false)
	if spawnPos then
		char:PivotTo(CFrame.new(spawnPos + Vector3.new(0, 3, 0)))
	end
	task.defer(function()
		G.Joueurs.sync(player)
		G.Avatar.refresh(player)
	end)
	hum.Died:Connect(function()
		Game.onDeath(player)
	end)
end

function Game.start(player: Player)
	if playing[player] then
		return
	end
	playing[player] = "loading"
	while not (G.Mondes.ready and (G.world or G.Mondes.mode == "accueil" or G.Mondes.broken)) do
		task.wait(0.2)
	end
	if G.Mondes.broken then
		playing[player] = nil
		player:Kick(G.Mondes.broken)
		return
	end
	if G.Mondes.mode == "accueil" then
		playing[player] = nil
		return
	end
	G.remotes.Fade:FireClient(player, "Arrivée à " .. (G.world.name or "…") .. "…", 0)
	local data, status = G.Save.load(player, function(msg)
		G.remotes.Fade:FireClient(player, msg, 0)
	end)
	if status == "left" or not player.Parent then
		playing[player] = nil
		return
	end
	if status == "error" then
		-- surtout ne pas créer un perso vide : il écraserait le vrai à la première sauvegarde
		playing[player] = nil
		player:Kick("Ton personnage n'a pas pu être chargé (service de sauvegarde indisponible). "
			.. "Rien n'est perdu : reviens dans quelques minutes.")
		return
	end
	local prof = G.Joueurs.newProfile()
	if data then
		G.Save.apply(prof, data)
	end
	prof.created = prof.created or os.time()
	if G.Mondes.mode == "monde" then
		prof.lastWorld = G.world.id -- l'accueil y renverra le joueur la prochaine fois
	end
	G.Joueurs.set(player, prof)
	if G.Economie.adoptBank then
		G.Economie.adoptBank(player)
	end
	local rec = G.Mondes.playerRecord(player)
	local firstVisit = rec.seen == nil
	rec.seen = os.time()
	local spawnPos = vec(rec.pos) or Game.homePos(player)
	-- le cheval suit son cavalier d'un monde à l'autre : il attend près de l'arrivée
	if prof.horse and prof.horse.world ~= G.world.id then
		local hx, hz = math.floor(spawnPos.X + 6), math.floor(spawnPos.Z + 4)
		local rx, rz = G.WG.regionOf(math.floor(hx / G.Config.CELL), math.floor(hz / G.Config.CELL))
		prof.horse.x, prof.horse.z, prof.horse.region, prof.horse.world = hx, hz, rx .. "," .. rz, G.world.id
	end
	player:SetAttribute("FocusPos", spawnPos)
	G.World.preload(spawnPos)
	playing[player] = true
	player:SetAttribute("Playing", true)
	player.CharacterAdded:Connect(function(char)
		local pos = player:GetAttribute("RespawnPos")
		player:SetAttribute("RespawnPos", nil)
		setupCharacter(player, char, pos)
	end)
	player:SetAttribute("RespawnPos", spawnPos)
	pcall(function()
		player:RequestStreamAroundAsync(spawnPos, 10) -- streaming : le téléphone reçoit d'abord le sol
	end)
	player:LoadCharacter()
	G.remotes.Fade:FireClient(player, nil, 1)
	task.delay(1.5, function()
		if player.Parent then
			G.Compagnons.onJoin(player)
		end
	end)
	task.delay(6, function()
		if player.Parent then
			G.Protection.showLog(player)
		end
	end)
	G.Social.collect(player, "worlds", G.world.id)
	G.Social.checkTitles(player)
	-- première arrivée (ou ancienne apparence « avatar Roblox ») : écran de création du personnage
	if not (prof.look and prof.look.created) then
		task.delay(3, function()
			if player.Parent then
				G.Avatar.open(player, "creation", nil)
			end
		end)
	end
	task.spawn(function()
		G.Clans.refreshTag(player)
		G.Clans.remember(player)
	end)
	if not data then
		G.Util.toast(player, "Tu arrives les mains vides.", "big")
	elseif (prof.stars or 0) > 0 then
		G.Util.toast(player, "Tu es toujours recherché (" .. prof.stars .. " ★, prime " .. (prof.bounty or 0) .. " 💰). Fais-toi oublier…", "danger")
	elseif firstVisit then
		G.Util.toast(player, "Bienvenue à " .. G.world.name .. " ! Ton sac t'a suivi.", "big")
	else
		G.Util.toast(player, string.format("Bon retour à %s ! Jour %d.", G.world.name, G.world.day), "big")
	end
	for _, other in Game.players() do
		if other ~= player then
			G.Util.toast(other, player.DisplayName .. " arrive dans le monde.")
		end
	end
	G.Save.save(player)
end

-- Téléporte un joueur (en descendant de cheval et en lâchant ce qu'il porte)
function Game.teleport(player: Player, pos: Vector3)
	G.Horses.dismount(player, true)
	G.Bodies.drop(player, true)
	player:SetAttribute("FocusPos", pos)
	G.World.preload(pos)
	pcall(function()
		player:RequestStreamAroundAsync(pos, 5)
	end)
	local char = player.Character
	Game.noFall(player, 4)
	if char then
		char:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
		-- le client simule son perso : figé le temps de recevoir le terrain (streaming),
		-- sinon il tombe à travers un sol qu'il n'a pas encore
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			root.Anchored = true
			task.delay(1.2, function()
				if root.Parent then
					root.Anchored = false
				end
			end)
		end
	end
end

-- Sommeil : chacun dort de son côté (soins, lit = point de réapparition) ;
-- si TOUS les joueurs du monde dorment en même temps, on saute au matin.
function Game.isSleeping(player: Player): boolean
	return sleepers[player] ~= nil
end

local function wake(player: Player, msg: string?)
	if not sleepers[player] then
		return
	end
	sleepers[player] = nil
	player:SetAttribute("Sleeping", nil)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = G.Config.WALK
	end
	G.remotes.Fade:FireClient(player, nil, 1)
	if msg then
		G.Util.toast(player, msg)
	end
end

-- Peut-on dormir maintenant ? (vérifié AVANT de faire payer une chambre)
local function sleepHours(): boolean
	local h = G.Clock.hour()
	return h < 6 or h >= G.Config.SLEEP_FROM
end

function Game.canSleep(player: Player): (boolean, string?)
	if not sleepHours() then
		return false, "Tu n'as pas sommeil. On dort à partir de " .. G.Config.SLEEP_FROM .. " h."
	end
	local prof = G.Joueurs.get(player)
	if prof and (prof.stars or 0) > 0 then
		return false, "Impossible de dormir avec le shérif aux trousses !"
	end
	if sleepers[player] then
		return false, nil
	end
	return true, nil
end

function Game.sleep(player: Player, bedPos: Vector3)
	local ok, why = Game.canSleep(player)
	if not ok then
		if why then
			G.Util.toast(player, why)
		end
		return
	end
	local rec = G.Mondes.playerRecord(player)
	rec.bed = { math.floor(bedPos.X), math.floor(bedPos.Y), math.floor(bedPos.Z) }
	sleepers[player] = os.clock() + 8
	player:SetAttribute("Sleeping", true)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = hum.MaxHealth
		hum.WalkSpeed = 0
	end
	player:SetAttribute("Stamina", player:GetAttribute("MaxStamina") or G.Config.MAX_STAMINA)
	G.remotes.Fade:FireClient(player, "Tu t'endors… (la nuit passe si tout le monde dort)", 0)
end

-- Le passage au matin exige deux secondes de sommeil collectif pendant la même nuit.
local function sleepStep()
	local now = os.clock()
	for p, t in sleepers do
		if now >= t then
			wake(p, "Tu te sens reposé. Ce lit est désormais ton point de réapparition.")
		end
	end
	if not next(sleepers) or not sleepHours() then
		dawnAt = nil
		return
	end
	local players = Game.players()
	if #players == 0 then
		dawnAt = nil
		return
	end
	for _, p in players do
		if not sleepers[p] then
			dawnAt = nil
			return
		end
	end
	if not dawnAt or dawnDay ~= G.world.day then
		dawnAt, dawnDay = now + 2, G.world.day
		return
	end
	if now < dawnAt then
		return
	end
	dawnAt = nil
	for _, p in players do
		wake(p, nil)
	end
	G.Clock.skipToMorning()
	for _, p in players do
		if p.Parent then
			G.Util.toast(p, string.format("Tout le monde a dormi : jour %d.", G.world.day), "big")
			task.spawn(G.Save.save, p)
		end
	end
end

function Game.onDeath(player: Player)
	local prof = G.Joueurs.get(player)
	if not prof then
		return
	end
	-- mis K.O. par un joueur ? chasse aux primes
	local hunterId = player:GetAttribute("LastHitBy")
	local hitAt = player:GetAttribute("LastHitAt") or 0
	local hunter = hunterId and game:GetService("Players"):GetPlayerByUserId(hunterId)
	-- fin d'un duel (Systemes/Duels) : ni prime ni « acharnement », c'était consenti
	local duel = G.Duels and rawget(G.Duels, "onKO") and G.Duels.onKO(player, hunter)
	if not duel and hunterId and os.clock() - hitAt < 10 and G.Combat.noteKO then
		G.Combat.noteKO(player, hunterId)
	end
	if not duel and hunter and os.clock() - hitAt < 10 and (prof.stars or 0) > 0 then
		local bounty = math.floor((prof.bounty or 0) * (1 + 0.4 * G.Joueurs.talent(hunter, "primes") + 0.6 * G.Joueurs.talent(hunter, "traqueur")))
		local hp = G.Joueurs.get(hunter)
		if hp then
			hp.stats.bounties = (hp.stats.bounties or 0) + 1
			G.Social.checkTitles(hunter)
			if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(hunter, "prime", "recherche") end
		end
		if bounty > 0 then
			G.Joueurs.add(hunter, "gold", bounty, true)
			G.Util.toast(hunter, "🎯 Prime encaissée : +" .. bounty .. " 💰 (" .. player.DisplayName .. ")", "big")
			G.Joueurs.sync(hunter)
		end
		if G.Joueurs.talent(hunter, "menottes") > 0 then
			G.Law.addHonor(hunter, 6)
			player:SetAttribute("LastHitBy", nil)
			task.delay(3.2, function()
				if player.Parent then
					prof.stars = math.max(prof.stars, 1)
					Game.arrest(player, nil)
				end
			end)
		end
		prof.bounty = 0
		prof.stars = 0
		G.Joueurs.markDirty(player)
	end
	player:SetAttribute("LastHitBy", nil)
	wake(player, nil)
	G.Horses.dismount(player, true)
	G.Bodies.drop(player, true)
	-- mis K.O. par un shérif alors qu'on est recherché : on se réveille en cellule
	local sherHit = player:GetAttribute("SheriffHit")
	local sheriff = player:GetAttribute("SheriffId") and G.Npcs.byId(player:GetAttribute("SheriffId"))
	player:SetAttribute("SheriffHit", nil)
	player:SetAttribute("SheriffId", nil)
	if sherHit and os.clock() - sherHit < 10 and (prof.stars or 0) > 0 then
		G.remotes.Fade:FireClient(player, "Le shérif t'a eu…", 0)
		task.wait(3)
		if not player.Parent then
			return
		end
		player:LoadCharacter()
		task.wait(0.5)
		Game.arrest(player, sheriff)
		G.remotes.Fade:FireClient(player, nil, 1)
		return
	end
	local lost = math.floor((prof.inv.gold or 0) * 0.15)
	if lost > 0 then
		G.Joueurs.take(player, "gold", lost)
	end
	G.remotes.Fade:FireClient(player, "Tu t'évanouis…", 0)
	task.wait(3)
	if not player.Parent then
		return
	end
	local home = Game.homePos(player)
	player:SetAttribute("FocusPos", home)
	G.World.preload(home)
	player:SetAttribute("RespawnPos", home)
	player:LoadCharacter()
	G.remotes.Fade:FireClient(player, nil, 1)
	G.Util.toast(player, "Tu te réveilles chez toi, courbatu." .. (lost > 0 and (" Il te manque " .. lost .. " or.") or ""))
end

-- Le shérif t'attrape : amende, un moment en cellule, étoiles effacées.
-- surrender = on s'est rendu de soi-même : amende moitié, moins d'honneur perdu, cellule plus courte.
local JAIL_TIME = 45
function Game.arrest(player: Player, sheriff, surrender: boolean?)
	local prof = G.Joueurs.get(player)
	if not prof or prof.stars <= 0 or player:GetAttribute("Jailed") then
		return
	end
	wake(player, nil)
	local fine = math.min(prof.inv.gold or 0, math.floor(G.Config.FINE_PER_STAR * prof.stars * (surrender and 0.5 or 1)))
	if fine > 0 then
		G.Joueurs.take(player, "gold", fine)
	end
	prof.stars = 0
	prof.bounty = 0
	prof.honor = math.clamp(prof.honor - (surrender and 2 or 5), -100, 100)
	G.Joueurs.markDirty(player)
	G.Law.cleared(player)
	local office = sheriff and G.Npcs.officeOf(sheriff)
	local cell = office and office.cell or Game.homePos(player)
	local exit = office and office.exit or Game.homePos(player)
	G.Util.toast(player, surrender and ("« Tu as bien fait de venir. Une nuit au frais et c'est réglé. » Amende : " .. fine .. " or.")
		or ("« Je te tiens. Direction la cellule. » Amende : " .. fine .. " or."), "big")
	if surrender then
		G.Economie.record(player, "reddition", fine .. " or")
	end
	Game.teleport(player, cell)
	player:SetAttribute("Jailed", true)
	task.delay(surrender and JAIL_TIME / 2 or JAIL_TIME, function()
		if player.Parent then
			player:SetAttribute("Jailed", nil)
			Game.teleport(player, exit)
			G.Util.toast(player, "« Tu peux sortir. Et que je ne t'y reprenne pas. »")
		end
	end)
end

-- Chute : au-delà de FALL_SAFE studs de chute libre, dégâts croissants (jamais en tombant dans
-- l'eau, à cheval, ou juste après une téléportation). La défense ne protège pas d'une chute.
local FALL_SAFE = 20
local FALL_DMG = 2.5 -- par stud au-delà du seuil

function Game.noFall(player: Player, seconds: number?)
	player:SetAttribute("NoFallUntil", os.clock() + (seconds or 3))
	fallTop[player] = nil
end

-- distance parcourue (caractéristique Vitesse) : mémoire seulement
local lastPos = setmetatable({}, { __mode = "k" })
local runAcc = setmetatable({}, { __mode = "k" })

local function fallStep(p: Player, hum: Humanoid, pos: Vector3, inWater: boolean)
	if (p:GetAttribute("NoFallUntil") or 0) > os.clock() or p:GetAttribute("Riding") or inWater then
		fallTop[p] = nil
		return
	end
	if hum.FloorMaterial == Enum.Material.Air then
		fallTop[p] = math.max(fallTop[p] or pos.Y, pos.Y)
		return
	end
	local top = fallTop[p]
	fallTop[p] = nil
	local d = top and (top - pos.Y) or 0
	if d > FALL_SAFE then
		local dmg = math.floor((d - FALL_SAFE) * FALL_DMG)
		hum:TakeDamage(dmg)
		G.remotes.Fx:FireClient(p, "fall")
		if hum.Health > 0 and dmg >= 15 then
			G.Util.toast(p, "Aïe ! Mauvaise réception (-" .. dmg .. ").", "danger")
		end
	end
end

-- Filet de sécurité : un joueur passé SOUS le relief (streaming en retard, terrain redessiné sous ses
-- pieds, téléportation ratée) est remonté à la surface. Deux contrôles d'affilée (1 s d'écart) pour
-- ne pas réagir à un glitch d'une frame ; jamais dans une grotte de donjon ni dans l'eau.
local SINK_MARGIN = 12
local sunk = setmetatable({}, { __mode = "k" }) -- joueur -> nb de contrôles sous le sol
local sinkAcc = 0
local function sinkStep(p: Player, root: BasePart, pos: Vector3, inWater: boolean)
	if inWater or (G.Donjons and G.Donjons.inCave(pos)) then
		sunk[p] = nil
		return
	end
	local gy = G.Util.groundY(pos.X, pos.Z)
	if pos.Y < gy - SINK_MARGIN or pos.Y < G.Config.Y_MIN - 8 and pos.Y > -100 then
		sunk[p] = (sunk[p] or 0) + 1
		if sunk[p] >= 2 then
			sunk[p] = nil
			Game.noFall(p, 4)
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = CFrame.new(pos.X, math.max(gy, G.Config.WATER_Y) + 5, pos.Z)
			G.Economie.record(p, "remonte", math.floor(pos.X) .. "," .. math.floor(pos.Y) .. "," .. math.floor(pos.Z))
		end
	else
		sunk[p] = nil
	end
end
Game.sinkStep = sinkStep -- pour les tests (DbgAppel)

-- Nage : endurance qui baisse dans l'eau, noyade quand elle est vide
local swimAcc = 0
function Game.step(dt: number)
	sleepStep()
	swimAcc += dt
	if swimAcc < 0.25 then
		return
	end
	local step = swimAcc
	swimAcc = 0
	sinkAcc += step
	local doSink = sinkAcc >= 1
	if doSink then
		sinkAcc = 0
	end
	for _, p in Game.players() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local pos = root.Position
			-- Vitesse : se travaille en courant et en nageant (1 xp tous les 40 studs, pas à cheval ;
			-- un saut de plus de 60 studs = téléportation, ignoré)
			local last = lastPos[p]
			lastPos[p] = pos
			if last and not p:GetAttribute("Riding") then
				local d = Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude
				if d > 0.5 and d < 60 then
					runAcc[p] = (runAcc[p] or 0) + d
					if runAcc[p] >= 40 then
						G.Joueurs.addStatXp(p, "vitesse", math.floor(runAcc[p] / 40))
						runAcc[p] %= 40
					end
				end
			end
			local inWater = pos.Y < G.Config.WATER_Y + 1.2 and G.Util.isWater(pos.X, pos.Z)
			local st = p:GetAttribute("Stamina") or G.Config.MAX_STAMINA
			local maxSt = G.Config.MAX_STAMINA + (G.Joueurs.stats(p).vitesse or 0)
			if inWater then
				if p:GetAttribute("Riding") then
					G.Horses.dismount(p, false)
					G.Util.toast(p, "Le cheval refuse d'aller dans l'eau.")
				end
				st = math.max(0, st - step)
				if st <= 0 then
					hum:TakeDamage(10 * step)
					if not p:GetAttribute("Drowning") then
						G.Util.toast(p, "Tu te noies ! Regagne la rive !", "danger")
					end
					p:SetAttribute("Drowning", true)
				end
			else
				-- vitesse (18/11 : rien ne la réglait) : à cheval = RIDE × allure de la monture ;
				-- en courant = RUN + caractéristique vitesse, tant qu'il reste de l'endurance ;
				-- sinon la marche (BaseSpeed, posée par Joueurs.applyStats)
				local base = p:GetAttribute("BaseSpeed") or G.Config.WALK
				local moving = last and Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude > 0.5
				local riding = p:GetAttribute("Riding")
				local running = sprinting[p] and not riding and moving and st > 0.05
				if running then
					st = math.max(0, st - step * G.Config.SPRINT_DRAIN)
				else
					st = math.min(maxSt, st + step * 2)
				end
				if not sleepers[p] then
					local target = base
					if riding then
						target = G.Config.RIDE * (p:GetAttribute("MountSpeed") or 1)
					elseif running then
						target = G.Config.RUN + (base - G.Config.WALK)
					end
					if (p:GetAttribute("SlowUntil") or 0) > os.clock() then
						target *= 0.6 -- poison / toile (Enemies)
					end
					if p:GetAttribute("Pave") and not riding then
						target *= G.Chantiers and G.Chantiers.PAVED_SPEED or 1.1 -- grand-rue pavée (Chantiers « route »)
					end
					if p:GetAttribute("Enlise") then
						target *= 0.8 -- boue des marais (Froid.isStuck)
					end
					if p:GetAttribute("Obscur") and not riding then
						target *= 0.85 -- à tâtons dans le noir (Froid.isDark)
					end
					if math.abs(hum.WalkSpeed - target) > 0.05 and hum.WalkSpeed > 0 then
						hum.WalkSpeed = target
					end
				end
				p:SetAttribute("Running", running or nil)
				p:SetAttribute("Drowning", nil)
			end
			p:SetAttribute("Swimming", inWater)
			fallStep(p, hum, pos, inWater)
			if doSink then
				sinkStep(p, root, pos, inWater)
			end
			p:SetAttribute("Stamina", st)
			p:SetAttribute("MaxStamina", maxSt)
		end
	end
end

return Game
