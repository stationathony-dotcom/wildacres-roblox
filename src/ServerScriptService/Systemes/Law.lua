-- Justice et réputation (repris du jeu Godot) : honneur, étoiles de recherche, témoins,
-- enquêtes (journal d'observations : vu près de la victime peu avant = suspect), rumeurs.
-- Version adoucie : on assomme ; un PNJ caché (enterré, jeté à l'eau) disparaît pour de bon.

local Law = {}
local G, Config, D
local heat = {} -- joueur -> secondes sans être vu
local lastCrime = {} -- joueur -> {kind -> minute}
local bodies = {} -- PNJ assommés pas encore découverts ni cachés

function Law.init(g)
	G = g
	Config = G.Config
	D = G.Dialogue
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		heat[p] = nil
		lastCrime[p] = nil
	end)
end

local function law()
	local l = G.world.law
	l.missing = l.missing or {}
	l.sightings = l.sightings or {}
	return l
end

function Law.addHonor(player: Player, amount: number)
	local prof = G.Joueurs.get(player)
	prof.honor = math.clamp(prof.honor + amount, -100, 100)
	G.Joueurs.markDirty(player)
end

-- PNJ éveillés qui voient à la fois la scène et le joueur
function Law.witnesses(player: Player, pos: Vector3, exclude)
	local out = {}
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return out
	end
	for _, e in G.Npcs.list do
		if e ~= exclude and e.model.Parent and G.Npcs.canSee(e, pos + Vector3.new(0, 1, 0), player) and G.Npcs.canSee(e, head.Position, player) then
			table.insert(out, e)
		end
	end
	return out
end

-- Un crime vient d'avoir lieu en `pos`. Renvoie vrai s'il y a eu des témoins.
Law.alertUntil = {} -- clé de région -> fin de l'alerte (os.clock)
Law.ALERT_S = 120
function Law.alerted(regKey: string?): boolean
	return regKey ~= nil and (Law.alertUntil[regKey] or 0) > os.clock()
end

function Law.crime(player: Player, kind: string, pos: Vector3, victimId: string?): boolean
	local prof = G.Joueurs.get(player)
	if not prof then
		return false
	end
	local now = G.Clock.now()
	lastCrime[player] = lastCrime[player] or {}
	if now - (lastCrime[player][kind] or -999) < 2 then
		return true
	end
	local victim = victimId and G.Npcs.byId(victimId)
	-- victime = un autre joueur : il est prévenu (sans savoir qui, sauf témoins)
	local victimPlayer = G.Util.playerOf(victimId)
	if victimPlayer and victimPlayer ~= player then
		local what = ({ theft = "On te vole !", breakin = "Quelqu'un entre chez toi !", assault = "On t'attaque !" })[kind]
		if what then
			G.Util.toast(victimPlayer, what, "danger")
		end
	elseif victimPlayer == player then
		return false -- on ne se vole pas soi-même
	end
	local ws = Law.witnesses(player, pos, nil)
	-- la victime d'une agression sait qui l'a frappée
	if kind == "assault" and victim and victim.state ~= "ko" and not table.find(ws, victim) then
		table.insert(ws, victim)
	end
	if kind == "theft" then
		local f = {}
		for _, e in ws do
			if D.persona(e.data.persona).snitch then
				table.insert(f, e)
			end
		end
		ws = f
	end
	-- personne n'a vu… sauf une cloche d'alarme sur la parcelle
	local seenBy = ws[1] and ws[1].data.name or nil
	if #ws == 0 then
		local alarmOwner = G.Protection.alarmAt(pos)
		if alarmOwner and not G.Util.owns(player, alarmOwner) and (kind == "theft" or kind == "breakin" or kind == "assault") then
			G.Protection.ring(alarmOwner, player, pos)
			seenBy = "L'alarme"
		else
			return false
		end
	end
	lastCrime[player][kind] = now
	-- alerte : les commerces de la région ferment un moment (Npcs : « trade » refusé)
	local creg = G.World.regionAt(pos)
	if creg then
		Law.alertUntil[creg.key] = os.clock() + Law.ALERT_S
	end
	local w = Config.CRIMES[kind]
	prof.stars = math.min(Config.MAX_STARS, math.max(prof.stars + w.stars, w.stars))
	prof.bounty = (prof.bounty or 0) + (Config.BOUNTY[kind] or 20)
	prof.stats.maxBounty = math.max(prof.stats.maxBounty or 0, prof.bounty)
	prof.honor = math.clamp(prof.honor - w.honor, -100, 100)
	prof.stats.crimes = (prof.stats.crimes or 0) + 1
	heat[player] = 0
	local root = G.Util.root(player)
	local ppos = root and root.Position or pos
	for _, e in ws do
		G.Npcs.addOp(e, player, -w.opinion)
		e.per.memory["saw_" .. kind] = G.world.day
		e.per.culprits = e.per.culprits or {}
		e.per.culprits[G.Util.pid(player)] = G.world.day -- pour les ragots
		G.Npcs.reactToCrime(e, kind, ppos, player)
	end
	Law.report(player, ws[1], ppos)
	G.Util.toast(player, string.format("%s t'a %s ! Recherché %d/5 · prime %d", seenBy, seenBy == "L'alarme" and "trahi" or "vu", prof.stars, prof.bounty or 0), "danger")
	G.Joueurs.markDirty(player)
	return true
end

-- Les shérifs proches foncent vers la dernière position connue
function Law.report(player: Player, by, pos: Vector3)
	heat[player] = 0
	for _, e in G.Npcs.list do
		if e.data.role == "sheriff" and e.model.Parent and e.state ~= "ko" and e.state ~= "carried" and e.state ~= "inside" then
			if (e.root.Position - pos).Magnitude < 260 and e.state ~= "chase" then
				e.lastSeen = pos
				e.target = player
				G.Npcs.setState(e, "search")
			end
		end
	end
end

function Law.scream(pos: Vector3, from)
	for _, e in G.Npcs.list do
		if e ~= from and e.model.Parent and (e.root.Position - pos).Magnitude < 60 then
			G.Npcs.alert(e, pos)
		end
	end
end

function Law.sawPlayer(player: Player, by)
	local prof = G.Joueurs.get(player)
	if by.data.role == "sheriff" and prof.stars > 0 then
		heat[player] = 0
	end
	local now = G.Clock.now()
	local s = law().sightings
	local last = s[#s]
	local pid = G.Util.pid(player)
	if last and last.by == by.id and last.p == pid and now - last.t < 10 then
		return
	end
	local root = G.Util.root(player)
	if not root then
		return
	end
	table.insert(s, { t = now, x = math.floor(root.Position.X), z = math.floor(root.Position.Z), by = by.id, p = pid })
	while #s > 400 or (#s > 0 and now - s[1].t > 1440) do
		table.remove(s, 1)
	end
end

-- Joueur vu près d'un lieu peu avant : renvoie son identifiant "u<UserId>" (ou nil)
function Law.wasSeenNear(x: number, z: number, t: number, exceptId: string): string?
	for _, s in law().sightings do
		if s.by ~= exceptId and s.p and math.abs(s.t - t) <= Config.SUSPECT_WINDOW then
			local dx, dz = s.x - x, s.z - z
			if dx * dx + dz * dz < Config.SUSPECT_RADIUS * Config.SUSPECT_RADIUS then
				return s.p
			end
		end
	end
	return nil
end

function Law.cleared(player: Player)
	heat[player] = 0
end

-- ----------------------------------------------------------------- Assommés

function Law.bodies()
	local out = {}
	for e in bodies do
		if e.model.Parent and e.state == "ko" then
			table.insert(out, e)
		end
	end
	return out
end

function Law.onKnockOut(player: Player, victim)
	local pos = victim.root.Position
	if Law.crime(player, "ko", pos, nil) then
		victim.per.memory.witnessed = true
		Law.scream(pos, victim)
		return
	end
	bodies[victim] = true
end

function Law.forgetBody(e)
	bodies[e] = nil
end

local function community(reg, pos: Vector3, except)
	local out = {}
	for _, e in G.Npcs.list do
		if e ~= except and e.state ~= "gone" and (e.reg == reg or (e.root.Position - pos).Magnitude < 100) then
			table.insert(out, e)
		end
	end
	return out
end

function Law.bodyFound(body, finder)
	if not bodies[body] then
		return
	end
	bodies[body] = nil
	G.Npcs.react(finder, "body")
	Law.scream(finder.root.Position, finder)
	local pos = body.root.Position
	local suspect = Law.wasSeenNear(pos.X, pos.Z, body.koTime or G.Clock.now(), body.id)
	for _, e in community(body.reg, pos, body) do
		e.per.memory.mourning = G.world.day
		e.per.memory.mourning_told = nil
		e.per.memory.victime = body.data.name
		e.per.memory.victime_f = body.data.female
		if suspect then
			G.Npcs.addOpId(e.per, suspect, -40)
		end
	end
	for _, player in G.Game.players() do
		local prof = G.Joueurs.get(player)
		if suspect then
			prof.stars = math.max(prof.stars, 3)
			prof.honor = math.clamp(prof.honor - 20, -100, 100)
			heat[player] = 0
			Law.report(player, finder, pos)
			G.Util.toast(player, body.data.name .. " a été retrouvé" .. (body.data.female and "e" or "") .. " assommé" .. (body.data.female and "e" or "") .. "… et on t'a vu dans le coin !", "danger")
		else
			G.Util.toast(player, body.data.name .. " a été retrouvé" .. (body.data.female and "e" or "") .. " assommé" .. (body.data.female and "e" or "") .. ". La peur gagne la région.")
		end
		G.Joueurs.markDirty(player)
	end
end

-- Corps caché (enterré ou jeté à l'eau) : plus de preuve, mais il manquera demain
function Law.bodyHidden(body)
	bodies[body] = nil
	local pos = body.root.Position
	table.insert(law().missing, {
		id = body.id, name = body.data.name, female = body.data.female, region = body.reg.key,
		x = math.floor(pos.X), z = math.floor(pos.Z), t = body.koTime or G.Clock.now(),
	})
end

-- ----------------------------------------------------------------- Temps

function Law.step(dt: number)
	for _, player in G.Game.players() do
		local prof = G.Joueurs.get(player)
		if prof and prof.stars > 0 then
			heat[player] = (heat[player] or 0) + dt * (1 + 0.35 * G.Joueurs.talent(player, "cavale"))
			if heat[player] >= Config.STAR_DECAY * 2 then -- les étoiles collent : il faut vraiment se cacher
				heat[player] = 0
				prof.stars -= 1
				G.Joueurs.markDirty(player)
				if prof.stars == 0 then
					prof.bounty = math.floor((prof.bounty or 0) * 0.5) -- la prime ne disparaît pas tout à fait
					G.Util.toast(player, "Plus personne ne te cherche… pour l'instant.")
				end
			end
		end
	end
end

local function spreadGossip()
	for _, e in G.Npcs.list do
		if e.state ~= "gone" then
			-- ragots : chaque fautif vu récemment perd l'estime du voisinage
			local reach = D.persona(e.data.persona).gossip
			for uid, d in e.per.culprits or {} do
				if G.world.day - d <= 1 then
					for _, o in G.Npcs.list do
						if o ~= e and o.reg == e.reg and o.state ~= "gone" then
							G.Npcs.addOpId(o.per, uid, -math.floor(12 * reach))
							o.per.memory.heard = G.world.day
						end
					end
				elseif G.world.day - d > 7 then
					e.per.culprits[uid] = nil
				end
			end
		end
	end
end

function Law.newDay()
	local l = law()
	for _, m in l.missing do
		local suspect = Law.wasSeenNear(m.x, m.z, m.t, m.id)
		for _, e in G.Npcs.list do
			if e.state ~= "gone" and (e.reg.key == m.region or (e.root.Position - Vector3.new(m.x, e.root.Position.Y, m.z)).Magnitude < 160) then
				e.per.memory.missing = G.world.day
				e.per.memory.missing_told = nil
				e.per.memory.victime = m.name
				e.per.memory.victime_f = m.female
				if suspect then
					G.Npcs.addOpId(e.per, suspect, -15)
				end
			end
		end
		for _, player in G.Game.players() do
			local g = D.gender(m.female == true)
			G.Util.toast(player, m.name .. " a disparu." .. (suspect and (" Des gens se souviennent t'avoir vu avec " .. g.lui .. "…") or ""))
			if suspect then
				Law.addHonor(player, -5)
			end
		end
	end
	table.clear(l.missing)
	spreadGossip()
	for _, player in G.Game.players() do
		local prof = G.Joueurs.get(player)
		if prof.honor < 0 then
			prof.honor += 1
		end
		G.Joueurs.markDirty(player)
	end
	table.clear(bodies)
end

return Law
