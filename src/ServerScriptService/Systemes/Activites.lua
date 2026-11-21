-- Activités créées par les joueurs (étape 19). Au « Tableau d'affichage » du marché de chaque village :
--   · concours de pêche  : gagne qui pêche le plus de poissons pendant le concours (compté par le jeu) ;
--   · concours de récolte : gagne qui récolte le plus (cultures, cueillette) pendant le concours ;
--   · rassemblement libre (course, tournoi, exposition, chasse au trésor…) : l'organisateur désigne le
--     ou les gagnants parmi les inscrits, à la fin.
-- Règles de sûreté :
--   · la cagnotte est PRISE à l'organisateur à la création (bloquée), rendue s'il annule ou si personne
--     ne gagne ; aucune récompense n'est créée par le jeu → aucun farm d'or possible ;
--   · on s'inscrit soi-même (personne ne peut être embarqué de force) ; un joueur qui a bloqué
--     l'organisateur ne voit pas ses annonces ; l'organisateur ne peut pas gagner sa propre cagnotte ;
--   · un seul événement actif par organisateur ; gains versés par courrier (même absent).
-- Données : G.world.extra.activites (sauvegardé avec le monde).

local Activites = {}
local G, Config

local KINDS = {
	peche = { name = "Concours de pêche", icon = "🎣", auto = true },
	recolte = { name = "Concours de récolte", icon = "🌾", auto = true },
	minage = { name = "Concours de minage", icon = "⛏️", auto = true }, -- 18/11 : roches et filons cassés
	bucheronnage = { name = "Concours de bûcheronnage", icon = "🪓", auto = true }, -- arbres abattus
	construction = { name = "Concours de construction", icon = "🏠", auto = false }, -- 18/11 : jugé par l'organisateur (expositions, déco)
	libre = { name = "Rassemblement", icon = "🎪", auto = false },
	-- 19/11 : course (à cheval ou à pied) du tableau jusqu'au village voisin ; le premier arrivé gagne
	course = { name = "Course", icon = "🏇", auto = true, race = true },
	-- 19/11 (« à ne pas oublier » § 5) : plats et potions préparés ; bêtes et monstres vaincus
	cuisine = { name = "Concours de cuisine", icon = "🍲", auto = true },
	chasse = { name = "Concours de chasse", icon = "🏹", auto = true },
	-- 21/11 (« à ne pas oublier » § 5, quêtes 62 / 326 / 464) : bêtes apprivoisées ; produits de l'élevage ramassés
	dressage = { name = "Concours de dressage", icon = "🐴", auto = true },
	elevage = { name = "Concours d'élevage", icon = "🐄", auto = true },
}
-- ordre d'affichage au tableau (envoyé au client avec les annonces : `kinds`)
Activites.ORDER = { "peche", "recolte", "minage", "bucheronnage", "construction", "libre", "course", "cuisine", "chasse", "dressage", "elevage" }
local SKILL_OF = { peche = "peche", recolte = "agriculture", minage = "minage", bucheronnage = "bucheronnage", cuisine = "cuisine",
	chasse = "combat", dressage = "dressage", elevage = "elevage" }
local RACE_MIN = 250 -- studs : l'arrivée est le village le plus proche au-delà de cette distance
local RACE_FINISH = 30 -- studs autour du centre du village d'arrivée
Activites.KINDS = KINDS
local JUDGE_MIN = 120 -- l'organisateur a 2 h de jeu pour désigner le gagnant d'un rassemblement

local function absMin(): number
	return (G.world.day or 1) * 1440 + (G.world.minutes or 0)
end

local function all()
	G.world.extra = G.world.extra or {}
	G.world.extra.activites = G.world.extra.activites or {}
	return G.world.extra.activites
end

local function nearBoard(player: Player, village: string): boolean
	local v = G.world.extra and G.world.extra.villages and G.world.extra.villages[village]
	local r = G.Util.root(player)
	return v ~= nil and r ~= nil and (r.Position - Vector3.new(v.cx, r.Position.Y, v.cz)).Magnitude < 160
end

local function pay(uid: string, gold: number, why: string)
	if gold > 0 then
		G.Poste.deliverSystem(tonumber(uid), { from = why, gold = gold })
	end
end

local function tell(uid: string, msg: string, kind: string?)
	local p = G.Util.playerOf("u" .. uid)
	if p then
		G.Util.toast(p, msg, kind)
	end
end

local function send(player: Player, village: string)
	local uid = tostring(player.UserId)
	local rows = {}
	local now = absMin()
	for _, a in all() do
		local visible = a.village == village and (a.state == "annonce" or a.state == "encours" or a.state == "jugement")
		local orgP = G.Util.playerOf("u" .. a.org)
		if visible and not (G.Admin.blocks and G.Admin.blocks(player, tonumber(a.org))) then
			local parts = {}
			for puid, name in a.part do
				table.insert(parts, { uid = puid, name = name, score = a.scores[puid] or 0 })
			end
			table.sort(parts, function(x, y)
				return x.score > y.score
			end)
			table.insert(rows, {
				id = a.id, kind = a.kind, title = a.title, icon = KINDS[a.kind].icon, org = a.orgName, mine = a.org == uid,
				joined = a.part[uid] ~= nil, state = a.state, prize = a.prize, parts = parts,
				startsIn = math.max(0, math.floor(a.startMin - now)), endsIn = math.max(0, math.floor(a.startMin + a.dur - now)),
			})
		end
		local _ = orgP
	end
	local kinds = {}
	for _, k in Activites.ORDER do
		table.insert(kinds, { k, KINDS[k].icon .. " " .. (KINDS[k].name:gsub("^Concours d[e']%s?", ""):gsub("^%l", string.upper)) })
	end
	G.remotes.Menu:FireClient(player, { kind = "activites", village = village, rows = rows, gold = G.Joueurs.count(player, "gold"), kinds = kinds })
end
Activites.send = send

function Activites.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("tableau", function(player, prompt)
		local v = prompt:GetAttribute("Village")
		if type(v) == "string" then
			send(player, v)
		end
	end)
	G.Interact.onAction("act_creer", function(player, data)
		Activites.create(player, data)
	end)
	G.Interact.onAction("act_inscrire", function(player, data)
		local a = type(data.id) == "string" and all()[data.id]
		if not a or not nearBoard(player, a.village) then
			return
		end
		local uid = tostring(player.UserId)
		if a.org == uid then
			G.Util.toast(player, "Tu organises : tu ne peux pas concourir pour ta propre cagnotte.")
		elseif a.part[uid] then
			a.part[uid] = nil
			a.scores[uid] = nil
			G.Util.toast(player, "Tu te retires de « " .. a.title .. " ».")
		elseif a.state == "annonce" or a.state == "encours" then
			a.part[uid] = player.DisplayName
			a.scores[uid] = 0
			G.Util.toast(player, a.state == "encours" and "Inscrit ! C'est déjà commencé : fonce !" or "Inscrit ! Reviens à l'heure.", "gain")
		end
		send(player, a.village)
	end)
	G.Interact.onAction("act_annuler", function(player, data)
		local a = type(data.id) == "string" and all()[data.id]
		if not a or a.org ~= tostring(player.UserId) or a.state ~= "annonce" then
			return
		end
		a.state = "annule"
		pay(a.org, a.prize, "Tableau d'affichage (cagnotte rendue)")
		for puid in a.part do
			tell(puid, "« " .. a.title .. " » est annulé par l'organisateur.")
		end
		G.Economie.record(player, "activite_annulee", a.id)
		G.Mondes.saveSoon(player)
		send(player, a.village)
	end)
	G.Interact.onAction("act_juger", function(player, data)
		local a = type(data.id) == "string" and all()[data.id]
		if not a or a.org ~= tostring(player.UserId) or a.state ~= "jugement" or type(data.w) ~= "string" or not a.part[data.w] then
			return
		end
		Activites.finish(a, { data.w })
		send(player, a.village)
	end)
	task.spawn(function()
		while true do
			task.wait(2)
			if G.world then
				local ok, err = pcall(Activites.tick)
				if not ok then
					warn("[WildAcres] activités : " .. tostring(err))
				end
			end
		end
	end)
end

function Activites.create(player: Player, data)
	local village = data.v
	local k = type(data.kind) == "string" and KINDS[data.kind]
	if type(village) ~= "string" or not k or not nearBoard(player, village) then
		return
	end
	local uid = tostring(player.UserId)
	for _, a in all() do
		if a.org == uid and (a.state == "annonce" or a.state == "encours" or a.state == "jugement") then
			G.Util.toast(player, "Tu organises déjà quelque chose. Termine-le d'abord.")
			return
		end
	end
	local delay = math.clamp(math.floor(tonumber(data.delay) or 60), 15, 480)
	local dur = math.clamp(math.floor(tonumber(data.dur) or 60), 15, 240)
	local prize = math.clamp(math.floor(tonumber(data.prize) or 0), 0, 100000)
	if prize > 0 and not G.Joueurs.take(player, "gold", prize) then
		G.Util.toast(player, "Il te faut " .. prize .. " 💰 pour la cagnotte (elle est bloquée jusqu'à la fin).")
		return
	end
	local dest = nil
	if k.race then
		dest = Activites.raceDestination(village)
		if not dest then
			if prize > 0 then
				G.Joueurs.add(player, "gold", prize)
			end
			G.Util.toast(player, "Aucun autre village assez loin pour une course.")
			return
		end
	end
	local id = G.Util.newId("act")
	all()[id] = {
		id = id, kind = data.kind, title = k.name .. (dest and (" jusqu'à " .. dest.name) or "") .. " de " .. player.DisplayName, org = uid, orgName = player.DisplayName,
		village = village, startMin = absMin() + delay, dur = dur, prize = prize, part = {}, scores = {}, state = "annonce", dest = dest,
	}
	G.Economie.record(player, "activite", k.name .. " cagnotte " .. prize)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	G.Util.toast(player, k.icon .. " Affiché ! Début dans " .. delay .. " min de jeu.", "gain")
	send(player, village)
end

-- arrivée d'une course partie du tableau de ce village : le village le plus proche au-delà de RACE_MIN
function Activites.raceDestination(village: string)
	local v = G.world.extra and G.world.extra.villages and G.world.extra.villages[village]
	local Q = G.Quetes and rawget(G.Quetes, "villages")
	if not v or not Q then
		return nil
	end
	local best, bd = nil, math.huge
	for _, o in Q() do
		local d = Vector2.new(o.x - v.cx, o.z - v.cz).Magnitude
		if o.key ~= village and d >= RACE_MIN and d < bd then
			best, bd = o, d
		end
	end
	return best and { name = best.name, x = best.x, z = best.z, dist = math.floor(bd) } or nil
end

-- course en cours : départ (ceux qui ne sont pas au tableau sont hors course), puis premier arrivé
local function raceStep(a)
	if not a.started then
		a.started = true
		a.dq = {}
		for puid in a.part do
			local p = G.Util.playerOf("u" .. puid)
			if not p or not nearBoard(p, a.village) then
				a.dq[puid] = true
				tell(puid, "🏇 « " .. a.title .. " » part sans toi : il fallait être au tableau au départ.")
			else
				tell(puid, string.format("🏇 Partez ! Arrivée : %s, à %d studs. Le premier arrivé gagne.", a.dest.name, a.dest.dist), "big")
			end
		end
		return
	end
	for puid in a.part do
		local p = not a.dq[puid] and G.Util.playerOf("u" .. puid)
		local r = p and G.Util.root(p)
		if r and Vector2.new(r.Position.X - a.dest.x, r.Position.Z - a.dest.z).Magnitude <= RACE_FINISH then
			a.scores[puid] = 1
			Activites.finish(a, { puid })
			return
		end
	end
end
Activites.raceStep = raceStep

-- Compteurs des concours : appelé par la pêche et les récoltes
function Activites.note(player: Player, kind: string, n: number?)
	local uid = tostring(player.UserId)
	for _, a in all() do
		if a.state == "encours" and a.kind == kind and a.part[uid] then
			a.scores[uid] = (a.scores[uid] or 0) + (n or 1)
		end
	end
end

-- Partage de la cagnotte entre les gagnants (reste : à l'organisateur)
function Activites.finish(a, winners)
	a.state = "fini"
	if #winners == 0 or a.prize <= 0 then
		pay(a.org, a.prize, "Tableau d'affichage (cagnotte rendue)")
		for puid in a.part do
			tell(puid, "« " .. a.title .. " » est terminé.")
		end
		return
	end
	local share = math.floor(a.prize / #winners)
	pay(a.org, a.prize - share * #winners, "Tableau d'affichage (reste de la cagnotte)")
	local names = {}
	for _, w in winners do
		pay(w, share, a.title .. " (gagné !)")
		table.insert(names, a.part[w] or "?")
		local p = G.Util.playerOf("u" .. w)
		if p then
			G.Joueurs.addSkillXp(p, SKILL_OF[a.kind] or "commerce", 15)
		end
	end
	local msg = "🏆 « " .. a.title .. " » : " .. table.concat(names, ", ") .. " gagne" .. (#names > 1 and "nt" or "") .. " " .. share .. " 💰 (par courrier)."
	for puid in a.part do
		tell(puid, msg, "big")
	end
	tell(a.org, msg, "big")
	G.Economie.record(nil, "activite_finie", a.id .. " -> " .. table.concat(winners, ","))
end

function Activites.tick()
	local now = absMin()
	for id, a in all() do
		if a.state == "annonce" and now >= a.startMin then
			a.state = "encours"
			for puid in a.part do
				tell(puid, KINDS[a.kind].icon .. " « " .. a.title .. " » commence ! (" .. a.dur .. " min de jeu)", "big")
			end
		elseif a.state == "encours" and KINDS[a.kind].race and now < a.startMin + a.dur then
			raceStep(a)
		elseif a.state == "encours" and now >= a.startMin + a.dur then
			if KINDS[a.kind].auto then
				local best, winners = 0, {}
				for puid, s in a.scores do
					if a.part[puid] and s > best then
						best, winners = s, { puid }
					elseif a.part[puid] and s == best and s > 0 then
						table.insert(winners, puid)
					end
				end
				Activites.finish(a, best > 0 and winners or {})
			else
				a.state = "jugement"
				tell(a.org, "🎪 « " .. a.title .. " » est fini : désigne le gagnant au tableau d'affichage (2 h de jeu).", "big")
			end
		elseif a.state == "jugement" and now >= a.startMin + a.dur + JUDGE_MIN then
			Activites.finish(a, {}) -- pas de jugement : la cagnotte revient à l'organisateur
		elseif (a.state == "fini" or a.state == "annule") and now >= a.startMin + a.dur + 1440 * 3 then
			all()[id] = nil -- ménage au bout de 3 jours
		end
	end
end

return Activites
