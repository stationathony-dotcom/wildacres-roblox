-- Compagnons : bêtes apprivoisées (mini-jeu vérifié par le serveur, compétence Dressage).
-- Deux ordres : SUIVRE (t'accompagne, se bat à tes côtés si c'est un prédateur) et GARDER (reste
-- à sa place : un gardien grogne contre les intrus de ta parcelle puis les mord, et chasse les
-- cambrioleurs). Les bêtes de ferme apprivoisées produisent (miel, lait, plumes, fourrure…).
-- Enregistrées par monde dans G.world.players[uid].pets[id] = {kind, mode, x, z, hx, hz, days, ready}.

local Players = game:GetService("Players")

local Compagnons = {}
local G, Config
Compagnons.list = {}
local live = {} -- id -> entité
local busy = {} -- joueur -> en cours d'apprivoisement

-- Traits d'un compagnon : bête apprivoisée (TAMING) ou soldat (UNITS)
local function traits(kind: string)
	return G.Config.TAMING[kind] or G.Config.UNITS[kind] or {}
end
Compagnons.traits = traits

function Compagnons.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("tame", function(player, prompt)
		local en = G.Enemies.byId(prompt:GetAttribute("Enemy"))
		if en then
			Compagnons.tame(player, en)
		end
	end)
	G.Interact.onPrompt("pet", function(player, prompt)
		Compagnons.use(player, prompt:GetAttribute("Pet"))
	end)
	Players.PlayerRemoving:Connect(function(p)
		Compagnons.onLeave(p)
		busy[p] = nil
	end)
end

local function folder(): Folder
	local f = workspace:FindFirstChild("Compagnons")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Compagnons"
		f.Parent = workspace
	end
	return f
end

-- enregistrement des bêtes d'un joueur (dans ce monde)
local function petsOf(uid: string)
	local rec = G.world and G.world.players[string.sub(uid, 2)]
	if not rec then
		return nil
	end
	rec.pets = rec.pets or {}
	return rec.pets
end

Compagnons.recordsOf = petsOf -- lu par le livre des animaux (Livres)

-- bêtes seulement (les soldats ont leur propre plafond, voir Armee)
function Compagnons.count(player: Player): number
	local n = 0
	for _, rec in petsOf(G.Util.pid(player)) or {} do
		if not Config.UNITS[rec.kind] then
			n += 1
		end
	end
	return n
end

local function baitCount(player: Player, bait: string): number
	local group = Config.ITEM_GROUPS[bait]
	if not group then
		return G.Joueurs.count(player, bait)
	end
	local n = 0
	for _, it in group do
		n += G.Joueurs.count(player, it)
	end
	return n
end

local function takeBait(player: Player, bait: string)
	local group = Config.ITEM_GROUPS[bait]
	if not group then
		G.Joueurs.take(player, bait, 1)
		return
	end
	for _, it in group do
		if G.Joueurs.count(player, it) > 0 then
			G.Joueurs.take(player, it, 1)
			return
		end
	end
end

-- ----------------------------------------------------------------- Apparition

local function label(kind: string): string
	local t = traits(kind)
	local k = G.Enemies.KINDS[kind]
	return (k and k.name or kind) .. (t and t.label and (" · " .. t.label) or "")
end

local function setPrompt(en)
	if en.prompt then
		en.prompt:Destroy()
	end
	local ownerP = G.Util.playerOf(en.owner)
	local who = ownerP and (" de " .. ownerP.DisplayName) or ""
	local text = en.rec.ready and "Récolter" or (en.rec.mode == "guard" and "Me suivre" or "Garder ici")
	en.prompt = G.Util.prompt(en.model.PrimaryPart, "pet", text, label(en.kind) .. who, { data = { Pet = en.petId }, dist = 9 })
end

local function spawnPet(id: string, rec, uid: string)
	if live[id] then
		return live[id]
	end
	local pos = Vector3.new(rec.x, 0, rec.z)
	local en = G.Enemies.spawnFree(rec.kind, pos, folder())
	if not en then
		return nil
	end
	en.pet = true
	en.petId = id
	en.owner = uid
	en.rec = rec
	en.cd = 0
	en.lastBark = 0
	en.home = Vector3.new(rec.hx or rec.x, G.Util.groundY(rec.hx or rec.x, rec.hz or rec.z), rec.hz or rec.z)
	live[id] = en
	table.insert(Compagnons.list, en)
	setPrompt(en)
	return en
end

local function despawn(id: string)
	local en = live[id]
	if not en then
		return
	end
	en.rec.x, en.rec.z = math.floor(en.pos.X), math.floor(en.pos.Z)
	live[id] = nil
	local i = table.find(Compagnons.list, en)
	if i then
		table.remove(Compagnons.list, i)
	end
	en.dead = true
	if en.model then
		en.model:Destroy()
	end
end

-- ----------------------------------------------------------------- Apprivoiser (mini-jeu)

function Compagnons.tame(player: Player, en)
	local t = Config.TAMING[en.kind]
	if not t or en.dead or en.pet or busy[player] or en.taming then
		return
	end
	local name = en.k.name
	if t.weak and en.hp > en.maxHp * t.weak then
		G.Util.toast(player, name .. " est trop sauvage : affaiblis-le d'abord (sous " .. math.floor(t.weak * 100) .. " % de vie).")
		return
	end

	if not G.Joueurs.needSkill(player, "dressage", Config.TAME_SKILL[t.diff] or 0, "Apprivoiser : " .. name) then
		return
	end
	if baitCount(player, t.bait) < 1 then
		G.Util.toast(player, "Pour l'amadouer il te faut : " .. Config.needInfo(t.bait).icon .. " " .. Config.needInfo(t.bait).name)
		return
	end
	takeBait(player, t.bait)
	G.Util.geste(player, "offrir") -- on tend l'appât, accroupi, main ouverte
	G.Joueurs.sync(player)
	busy[player] = true
	en.taming = player
	local skill = G.Joueurs.skill(player, "dressage")
	local voix = G.Joueurs.talent(player, "apprivoiseur")
	G.Minijeux.start(player, {
		title = "Apprivoiser : " .. name,
		hint = "Gagne sa confiance : appuie quand le cœur passe dans la zone. (Il faudra le nourrir chaque jour.)",
		pins = 1 + t.diff,
		-- un collier dans le sac rassure la bête : zone plus large
		zone = math.clamp(0.30 - t.diff * 0.035 + skill * 0.004 + voix * 0.03 + (G.Joueurs.has(player, "dog_collar") and 0.05 or 0), 0.08, 0.5),
		speed = 0.55 + t.diff * 0.17,
		misses = 1 + voix,
		timeout = 35,
		near = function()
			local root = G.Util.root(player)
			return root ~= nil and not en.dead and (root.Position - en.pos).Magnitude < 14
		end,
	}, function(ok)
		busy[player] = nil
		en.taming = nil
		if ok and not en.dead then
			G.Joueurs.addSkillXp(player, "dressage", 12 * t.diff)
			Compagnons.adopt(player, en)
		else
			G.Joueurs.addSkillXp(player, "dressage", 3 * t.diff)
			if not en.dead then
				if en.k.passive then
					en.state = "flee"
					en.t = 0
				else
					en.angry = true
					en.state = "chase"
					en.t = 0
				end
			end
			G.Util.toast(player, name .. " prend peur… (appât perdu)")
		end
	end)
end

function Compagnons.adopt(player: Player, en)
	local t = Config.TAMING[en.kind]
	local pos = en.pos
	G.Enemies.removeWild(en)
	local uid = G.Util.pid(player)
	local inPlot = G.Parcelles.at(pos) == uid
	local id = G.Util.newId("pet")
	local rec = {
		kind = en.kind, mode = (inPlot and t.guard) and "guard" or "follow",
		x = math.floor(pos.X), z = math.floor(pos.Z), hx = math.floor(pos.X), hz = math.floor(pos.Z), days = 0,
	}
	petsOf(uid)[id] = rec
	spawnPet(id, rec, uid)
	G.Social.collect(player, "tames", en.kind)
	G.Util.toast(player, "💞 " .. en.k.name .. " t'a adopté ! Approche-toi et donne-lui un ordre (suivre / garder).", "big")
end

-- ----------------------------------------------------------------- Ordres et produits

function Compagnons.use(player: Player, id: string)
	local en = type(id) == "string" and live[id]
	if not en then
		return
	end
	if not G.Util.owns(player, en.owner) then
		G.Util.toast(player, "Ce n'est pas ton animal.")
		return
	end
	local rec = en.rec
	local t = traits(en.kind)
	if rec.ready and t and t.product then
		rec.ready = false
		rec.days = 0
		local n = 1
		if math.random() < 0.05 * G.Joueurs.skill(player, "elevage") / 5 + 0.25 * G.Joueurs.talent(player, "eleveur") then
			n = 2
		end
		G.Joueurs.add(player, t.product[1], n)
		G.Joueurs.addSkillXp(player, "elevage", 6)
		G.Joueurs.sync(player)
		setPrompt(en)
		return
	end
	if rec.mode == "guard" then
		rec.mode = "follow"
		G.Util.toast(player, en.k.name .. " te suit.")
	else
		rec.mode = "guard"
		rec.hx, rec.hz = math.floor(en.pos.X), math.floor(en.pos.Z)
		en.home = Vector3.new(rec.hx, en.pos.Y, rec.hz)
		local t2 = traits(en.kind)
		G.Util.toast(player, en.k.name .. (t2 and t2.guard and " monte la garde ici." or " reste ici."))
	end
	setPrompt(en)
end

-- Chaque matin, les bêtes mangent (leur appât) dans le sac de leur maître présent dans le monde.
-- 3 jours le ventre vide : elles retournent à la vie sauvage. Les soldats, eux, touchent leur solde (Armee).
local function feed()
	for _, player in G.Game.players() do
		local uid = G.Util.pid(player)
		local hungry = {}
		for id, rec in petsOf(uid) or {} do
			local t = Config.TAMING[rec.kind]
			if t then
				if baitCount(player, t.bait) > 0 then
					takeBait(player, t.bait)
					rec.hungry = 0
					-- confiance (18/11) : chaque jour nourri la renforce (0 → 100), un jour affamé l'entame
					rec.trust = math.min(100, (rec.trust or 0) + 5)
				else
					rec.hungry = (rec.hungry or 0) + 1
					rec.trust = math.max(0, (rec.trust or 0) - 15)
					if rec.hungry >= 3 then
						petsOf(uid)[id] = nil
						despawn(id)
						G.Util.toast(player, "🐾 Ton " .. string.lower(G.Enemies.KINDS[rec.kind].name) .. " affamé est retourné à la vie sauvage.", "danger")
					else
						table.insert(hungry, G.Enemies.KINDS[rec.kind].name)
					end
				end
			end
		end
		if #hungry > 0 then
			G.Util.toast(player, "🐾 Affamés (prévois leur nourriture) : " .. table.concat(hungry, ", "), "danger")
		end
		G.Joueurs.sync(player)
	end
end

function Compagnons.newDay()
	if not G.world then
		return
	end
	pcall(feed)
	-- reproduction : deux bêtes de même espèce, nourries, gardées à moins de 20 studs l'une de l'autre
	for uid, prec in G.world.players do
		local born = {}
		local list = {}
		for id, rec in prec.pets or {} do
			if Config.TAMING[rec.kind] and rec.mode == "guard" and (rec.hungry or 0) == 0 then
				table.insert(list, { id, rec })
			end
		end
		local used = {}
		for i = 1, #list do
			for j = i + 1, #list do
				local a, b = list[i], list[j]
				if not used[a[1]] and not used[b[1]] and a[2].kind == b[2].kind
					and math.abs((a[2].hx or 0) - (b[2].hx or 0)) < 20 and math.abs((a[2].hz or 0) - (b[2].hz or 0)) < 20 then
					used[a[1]], used[b[1]] = true, true
					if math.random() < 0.15 then
						table.insert(born, { kind = a[2].kind, x = a[2].hx + 3, z = a[2].hz + 3 })
					end
				end
			end
		end
		for _, baby in born do
			local id = G.Util.newId("pet")
			prec.pets[id] = { kind = baby.kind, mode = "guard", x = baby.x, z = baby.z, hx = baby.x, hz = baby.z, days = 0 }
			local owner = G.Util.playerOf("u" .. uid)
			if owner then
				G.Util.toast(owner, "🍼 Un petit " .. string.lower(G.Enemies.KINDS[baby.kind].name) .. " est né dans ton élevage !", "big")
				G.Joueurs.addSkillXp(owner, "elevage", 15)
			end
			if G.World.regionAt(Vector3.new(baby.x, 0, baby.z)) then
				spawnPet(id, prec.pets[id], "u" .. uid)
			end
		end
	end
	for uid, prec in G.world.players do
		for id, rec in prec.pets or {} do
			local t = traits(rec.kind)
			if t and t.product and not rec.ready then
				rec.days = (rec.days or 0) + 1
				if rec.days >= t.product[2] then
					rec.ready = true
					if live[id] then
						setPrompt(live[id])
					end
				end
			end
		end
		local _ = uid
	end
end

-- ----------------------------------------------------------------- Présence (régions, connexions)

local function inRegion(reg, x: number, z: number): boolean
	local CELL, REGION = Config.CELL, Config.REGION
	return math.floor(x / CELL / REGION) == reg.rx and math.floor(z / CELL / REGION) == reg.rz
end

function Compagnons.onRegionLoad(reg)
	for uidNum, prec in G.world.players do
		for id, rec in prec.pets or {} do
			if rec.mode == "guard" and not live[id] and inRegion(reg, rec.hx or rec.x, rec.hz or rec.z) then
				spawnPet(id, rec, "u" .. uidNum)
			end
		end
	end
end

function Compagnons.onRegionUnload(reg)
	for id, en in live do
		if en.rec.mode == "guard" and inRegion(reg, en.home.X, en.home.Z) then
			despawn(id)
		end
	end
end

function Compagnons.onJoin(player: Player)
	local root = G.Util.root(player)
	local base = root and root.Position or player:GetAttribute("FocusPos")
	if not base then
		return
	end
	local i = 0
	for id, rec in petsOf(G.Util.pid(player)) or {} do
		if rec.mode == "follow" and not live[id] then
			i += 1
			rec.x, rec.z = math.floor(base.X + math.cos(i) * 5), math.floor(base.Z + math.sin(i) * 5)
			spawnPet(id, rec, G.Util.pid(player))
		end
	end
end

function Compagnons.onLeave(player: Player)
	local uid = G.Util.pid(player)
	for id, en in live do
		if en.owner == uid and en.rec.mode == "follow" then
			despawn(id)
		end
	end
end

-- Un compagnon frappé par quelqu'un d'autre (tuer le chien de garde pour cambrioler…)
function Compagnons.hit(en, dmg: number, player: Player)
	if en.dead or G.Util.owns(player, en.owner) then
		return
	end
	en.hp -= dmg
	en.provoker = player
	G.Combat.popup(en.pos + Vector3.new(0, en.height, 0), tostring(dmg), Color3.fromRGB(255, 200, 120))
	if en.hp <= 0 then
		local owner = G.Util.playerOf(en.owner)
		G.Law.crime(player, "assault", en.pos, en.owner)
		G.Protection.log(en.owner, player.DisplayName .. " a tué ton " .. string.lower(en.k.name) .. ".")
		local pets = petsOf(en.owner)
		if pets then
			pets[en.petId] = nil
		end
		despawn(en.petId)
		local _ = owner
	end
end

-- ----------------------------------------------------------------- Comportement

local function nearestHostile(pos: Vector3, range: number)
	local best, bd = nil, range
	for _, e in G.Enemies.list do
		if not e.dead and not e.k.passive and e.model.Parent then
			local d = (e.pos - pos).Magnitude
			if d < bd then
				best, bd = e, d
			end
		end
	end
	return best, bd
end

local function damageOf(en): number
	local owner = G.Util.playerOf(en.owner)
	local bonus = owner and (1 + 0.4 * G.Joueurs.talent(owner, "meute")) or 1
	-- confiance : jusqu'à +30 % de dégâts pour une bête nourrie fidèlement depuis 20 jours
	bonus *= 1 + 0.3 * math.clamp(((en.rec and en.rec.trust) or 0) / 100, 0, 1)
	if en.rec and en.rec.equip then
		bonus *= 1.25 -- soldat équipé (Armee.equip)
	end
	return math.max(4, math.floor((en.k.dmg > 0 and en.k.dmg or 6) * bonus))
end

local function arrow(from: Vector3, to: Vector3)
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.2, 0.2, 2)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Color = Color3.fromRGB(120, 84, 52)
	p.CFrame = CFrame.lookAt(from, to)
	p.Parent = workspace
	game:GetService("TweenService"):Create(p, TweenInfo.new(0.25), { CFrame = CFrame.lookAt(to, to + (to - from).Unit) }):Play()
	game:GetService("Debris"):AddItem(p, 0.3)
end

local function bite(en, target, isPlayer: boolean)
	if en.cd > 0 then
		return
	end
	en.cd = traits(en.kind).ranged and 1.4 or 1.1
	if traits(en.kind).ranged then
		local tpos = isPlayer and G.Util.root(target) and G.Util.root(target).Position or target.pos
		if tpos then
			arrow(en.pos + Vector3.new(0, 3, 0), tpos + Vector3.new(0, 2, 0))
		end
	end
	local owner = G.Util.playerOf(en.owner)
	if isPlayer then
		G.Combat.hurtPlayer(target, math.floor(damageOf(en) * 0.6), en.pos)
	elseif owner then
		G.Enemies.hit(target, damageOf(en), owner)
	else
		target.hp -= damageOf(en)
	end
end

local function think(en, dt: number)
	en.cd -= dt
	local t = traits(en.kind)
	local speed = en.k.speed
	-- repos : la vie revient doucement hors combat
	if en.hp < en.maxHp and os.clock() - (en.lastHurt or 0) > 6 then
		en.hp = math.min(en.maxHp, en.hp + en.maxHp * 0.02 * dt)
	end
	local reach = t.ranged and 16 or nil
	local owner = G.Util.playerOf(en.owner)
	local oroot = owner and G.Util.root(owner)
	if en.rec.mode == "follow" then
		if not oroot then
			return
		end
		local target = t.fight and nearestHostile(oroot.Position, 18)
		if target then
			local d = (target.pos - en.pos).Magnitude
			if d > (reach or (en.radius + (target.radius or 1.5) + 1.2)) then
				G.Enemies.move(en, target.pos, speed * 1.1, dt)
			else
				bite(en, target, false)
			end
		else
			local d = (oroot.Position - en.pos).Magnitude
			if d > 70 then
				en.pos = oroot.Position + Vector3.new(4, 0, 4)
			elseif d > 6 then
				G.Enemies.move(en, oroot.Position, speed * (d > 20 and 1.4 or 1), dt)
			end
		end
	else
		-- garde : intrus de la parcelle, monstres et cambrioleurs près de la maison
		local range = (owner and G.Joueurs.talent(owner, "vigilance") > 0) and 34 or 24
		local intruder = nil
		if t.guard then
			for _, p in G.Game.players() do
				local r = G.Util.root(p)
				if r and not G.Util.owns(p, en.owner) and (r.Position - en.home).Magnitude < range and G.Parcelles.at(r.Position) == en.owner then
					intruder = p
					break
				end
			end
		end
		local hostile = t.guard and nearestHostile(en.home, 22)
		if intruder or hostile then
			local now = os.clock()
			if now - en.lastBark > 6 then
				en.lastBark = now
				en.barkAt = now
				G.Util.emote(en.model, "angry")
				if intruder then
					G.Util.toast(intruder, "🐺 Un gardien grogne : tu es sur le terrain de quelqu'un !", "danger")
					G.Protection.log(en.owner, "Ton " .. string.lower(en.k.name) .. " a grogné contre " .. intruder.DisplayName .. ".", true)
				end
			end
			-- il mord seulement après avoir prévenu (3 s), et ne s'éloigne pas trop de la maison
			if t.fight and now - (en.barkAt or now) > 3 then
				local tpos = intruder and G.Util.root(intruder).Position or hostile.pos
				if (tpos - en.home).Magnitude < 34 then
					if (tpos - en.pos).Magnitude > (reach or (en.radius + 2.2)) then
						G.Enemies.move(en, tpos, speed * 1.15, dt)
					else
						bite(en, intruder or hostile, intruder ~= nil)
					end
				end
			end
		else
			if (en.pos - en.home).Magnitude > 3 or not en.goal or en.t > 6 then
				en.t = 0
				en.goal = en.home + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
			end
			en.t = (en.t or 0) + dt
			G.Enemies.move(en, en.goal, speed * 0.3, dt)
		end
	end
	en.hop = (en.hop or 0) + dt * 6
end

local acc = 0
function Compagnons.step(dt: number)
	acc += dt
	if acc < 1 / 15 then
		return
	end
	local step = acc
	acc = 0
	for i = #Compagnons.list, 1, -1 do
		local en = Compagnons.list[i]
		if en.dead or not en.model.Parent then
			table.remove(Compagnons.list, i)
		else
			local ok, err = pcall(think, en, step)
			if not ok then
				warn("[WildAcres] compagnon : " .. tostring(err))
			end
			G.Enemies.render(en)
		end
	end
end

-- Rappel (clochette) : les compagnons qui te SUIVENT et se sont égarés (> 30 studs) reviennent près
-- de toi ; ceux en garde restent à leur poste. Renvoie le nombre de bêtes revenues.
function Compagnons.recall(player: Player): number
	local root = G.Util.root(player)
	if not root then
		return 0
	end
	local n = 0
	for _, en in Compagnons.list do
		if not en.dead and en.model.Parent and G.Util.owns(player, en.owner) and en.rec and en.rec.mode ~= "guard" then
			if (en.pos - root.Position).Magnitude > 30 then
				local a = math.random() * math.pi * 2
				local x, z = root.Position.X + math.cos(a) * 4, root.Position.Z + math.sin(a) * 4
				en.pos = Vector3.new(x, G.Util.groundY(x, z), z)
				n += 1
			end
		end
	end
	return n
end

-- Blessé par un monstre : un compagnon ou un soldat peut mourir pour de bon
function Compagnons.hurt(en, dmg: number)
	if en.dead then
		return
	end
	if en.rec and en.rec.equip then
		dmg = math.max(1, math.floor(dmg * 0.8)) -- armure de cuir et de fer
	end
	en.hp -= dmg
	en.lastHurt = os.clock()
	G.Combat.popup(en.pos + Vector3.new(0, en.height, 0), tostring(dmg), Color3.fromRGB(255, 110, 90))
	if en.hp <= 0 then
		G.Protection.log(en.owner, "Ton " .. string.lower(en.k.name) .. " est tombé au combat.")
		local pets = petsOf(en.owner)
		if pets then
			pets[en.petId] = nil
		end
		despawn(en.petId)
	end
end

-- Une recrue sort de la caserne
function Compagnons.enlist(uid: string, unit: string, pos: Vector3)
	local pets = petsOf(uid)
	if not pets then
		return
	end
	local id = G.Util.newId("sol")
	local rec = { kind = unit, mode = "guard", x = math.floor(pos.X), z = math.floor(pos.Z), hx = math.floor(pos.X), hz = math.floor(pos.Z), days = 0, unit = true }
	pets[id] = rec
	if G.World.regionAt(pos) then
		spawnPet(id, rec, uid)
	end
	local owner = G.Util.playerOf(uid)
	if owner then
		G.Util.toast(owner, "⚔️ " .. Config.UNITS[unit].name .. " est prêt et monte la garde à la caserne.", "big")
	end
end

-- Désertion : un soldat s'en va (renvoie son nom)
function Compagnons.dismissOne(player: Player): string?
	local uid = G.Util.pid(player)
	for id, rec in petsOf(uid) or {} do
		if Config.UNITS[rec.kind] then
			petsOf(uid)[id] = nil
			despawn(id)
			return Config.UNITS[rec.kind].name
		end
	end
	return nil
end

-- Positions à jour avant une sauvegarde
function Compagnons.sync()
	for _, en in live do
		en.rec.x, en.rec.z = math.floor(en.pos.X), math.floor(en.pos.Z)
	end
end

return Compagnons
