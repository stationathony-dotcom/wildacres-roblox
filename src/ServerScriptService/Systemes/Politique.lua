-- Politique de village (étape 15D). Organique, sans annonce : tout se passe au « conseil », sur le
-- parvis de la chapelle du village (invite « Conseil du village »).
--
--  · Habitant = a une parcelle à moins de RESIDENT_R studs du centre du village. Seuls les habitants
--    votent et se présentent (sinon n'importe quel passant ferait l'élection).
--  · Vote permanent : chaque habitant soutient un candidat ; au lever du jour, celui qui a le plus de
--    voix (d'habitants venus dans ce monde depuis moins de 14 jours) devient maire s'il dépasse le
--    maire en place. Un maire absent 14 jours perd sa charge (pas de village bloqué par un absent).
--  · Trésor : dons des joueurs + taxe sur les ventes des étals du village (le maire la règle entre 0
--    et 15 % ; sans maire 5 %, et cette taxe-là sort de l'économie comme avant).
--  · Projets payés par le trésor (décidés par le maire), aux effets réels :
--      foire (prix +30 % au village aujourd'hui) · réparations (bâtiments cassés rebâtis tout de
--      suite) · ronde de nuit (témoins du village voient 50 % plus loin pendant 7 jours).
--  · Transparence : registre public des recettes et dépenses. Le maire ne peut rien fermer ni
--    confisquer : les services essentiels ne dépendent pas de lui.
-- Données : G.world.extra.villages[clé de région] (sauvegardé avec le monde).

local Players = game:GetService("Players")

local Politique = {}
local G, Config

local RESIDENT_R = 260
local ABSENT_DAYS = 14
local TAX_MAX = 15
local PROJECTS = {
	foire = { name = "Foire au village", cost = 400, desc = "Les marchands du village paient 30 % de plus aujourd'hui." },
	reparer = { name = "Réparations", cost = 250, desc = "Tout ce qui est cassé au village est rebâti tout de suite." },
	ronde = { name = "Ronde de nuit", cost = 300, desc = "Pendant 7 jours, les habitants voient 50 % plus loin (crimes)." },
}
Politique.PROJECTS = PROJECTS

local function villages()
	G.world.extra = G.world.extra or {}
	G.world.extra.villages = G.world.extra.villages or {}
	return G.world.extra.villages
end

local function V(key: string)
	return villages()[key]
end

local function log(v, text: string)
	v.log = v.log or {}
	table.insert(v.log, { day = G.world.day, text = text })
	while #v.log > 25 do
		table.remove(v.log, 1)
	end
end

-- Appelé par Villages au chargement d'une région de village
function Politique.register(key: string, name: string, center: Vector3)
	local v = V(key)
	if not v then
		v = { name = name, cand = {}, votes = {}, tresor = 0, taxe = 5, log = {}, projets = {} }
		villages()[key] = v
	end
	v.cx, v.cz = math.floor(center.X), math.floor(center.Z)
	v.name = name ~= "" and name or v.name
end

-- données d'un village ou d'une ville de joueurs (Villes.council)
function Politique.get(key: string)
	return V(key)
end

local function centerOf(v): Vector3
	return Vector3.new(v.cx or 0, 0, v.cz or 0)
end

local function isResident(uid: string, v): boolean
	local rec = G.world.players[uid]
	if not rec then
		return false
	end
	for _, p in G.Parcelles.plotsOf(rec) do
		if (Vector3.new(p.x, 0, p.z) - centerOf(v)).Magnitude <= RESIDENT_R then
			return true
		end
	end
	return false
end

local function active(uid: string): boolean
	local rec = G.world.players[uid]
	return rec ~= nil and (rec.seen or 0) >= os.time() - ABSENT_DAYS * 86400
end

-- Village dont on est dans l'enceinte (pour la taxe et la ronde)
function Politique.villageAt(pos: Vector3): (string?, any)
	for key, v in villages() do
		if v.cx and (Vector3.new(pos.X, 0, pos.Z) - centerOf(v)).Magnitude <= 110 then
			return key, v
		end
	end
	return nil, nil
end

-- Taxe d'un étal posé à pos : (taux, village) ; village nil = taxe qui sort de l'économie
function Politique.taxAt(pos: Vector3): (number, string?)
	local key, v = Politique.villageAt(pos)
	if v and v.maire then
		return (v.taxe or 5) / 100, key
	end
	return 0.05, nil
end

function Politique.credit(key: string?, n: number, why: string)
	local v = key and V(key)
	if v and n > 0 then
		v.tresor = (v.tresor or 0) + n
		v.taxes = (v.taxes or 0) + n
	end
	local _ = why
end

function Politique.sightMult(pos: Vector3): number
	local _, v = Politique.villageAt(pos)
	if v and v.projets and (v.projets.ronde or 0) >= G.world.day then
		return 1.5
	end
	return 1
end

local function tally(v)
	local count = {}
	for voter, cand in v.votes do
		if active(voter) and isResident(voter, v) and v.cand[cand] then
			count[cand] = (count[cand] or 0) + 1
		end
	end
	return count
end

local function send(player: Player, key: string)
	local v = V(key)
	if not v then
		return
	end
	local uid = tostring(player.UserId)
	local count = tally(v)
	local cands = {}
	for cuid, name in v.cand do
		table.insert(cands, { uid = cuid, name = name, votes = count[cuid] or 0, mine = v.votes[uid] == cuid })
	end
	table.sort(cands, function(a, b)
		return a.votes > b.votes
	end)
	local projs = {}
	for id, p in PROJECTS do
		table.insert(projs, { id = id, name = p.name, cost = p.cost, desc = p.desc })
	end
	table.sort(projs, function(a, b)
		return a.cost < b.cost
	end)
	G.remotes.Menu:FireClient(player, {
		kind = "conseil", village = key, name = v.name, maire = v.maireName, isMaire = v.maire == uid,
		resident = isResident(uid, v), candidat = v.cand[uid] ~= nil, tresor = v.tresor or 0, taxe = v.maire and v.taxe or 5,
		cands = cands, projets = projs, log = v.log or {}, ronde = v.projets and v.projets.ronde, day = G.world.day,
	})
end

local function near(player: Player, key: string): boolean
	local v = V(key)
	local r = G.Util.root(player)
	return v ~= nil and r ~= nil and (r.Position - Vector3.new(v.cx, r.Position.Y, v.cz)).Magnitude < 140
end

function Politique.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("conseil", function(player, prompt)
		local key = prompt:GetAttribute("Village")
		if type(key) == "string" and V(key) then
			send(player, key)
		end
	end)
	G.Interact.onAction("pol_candidat", function(player, data)
		local key = data.v
		local v = type(key) == "string" and V(key)
		if not v or not near(player, key) then
			return
		end
		local uid = tostring(player.UserId)
		local prof = G.Joueurs.get(player)
		if v.cand[uid] then
			v.cand[uid] = nil
			log(v, player.DisplayName .. " retire sa candidature.")
		elseif not isResident(uid, v) then
			G.Util.toast(player, "Seuls les habitants (une parcelle près du village) peuvent se présenter.")
			return
		elseif (prof.stars or 0) > 0 or (prof.honor or 0) < 0 then
			G.Util.toast(player, "Le village ne veut pas d'un candidat recherché ou malhonnête.")
			return
		else
			v.cand[uid] = player.DisplayName
			log(v, player.DisplayName .. " se présente à la mairie.")
		end
		send(player, key)
	end)
	G.Interact.onAction("pol_vote", function(player, data)
		local key = data.v
		local v = type(key) == "string" and V(key)
		local uid = tostring(player.UserId)
		if not v or not near(player, key) or type(data.c) ~= "string" or not v.cand[data.c] then
			return
		end
		if not isResident(uid, v) then
			G.Util.toast(player, "Seuls les habitants votent (il faut une parcelle près du village).")
			return
		end
		v.votes[uid] = data.c
		G.Util.toast(player, "🗳️ Ton soutien va à " .. v.cand[data.c] .. ". Le décompte se fait au lever du jour.", "gain")
		send(player, key)
	end)
	G.Interact.onAction("pol_don", function(player, data)
		local key = data.v
		local v = type(key) == "string" and V(key)
		local n = math.floor(tonumber(data.n) or 0)
		if not v or not near(player, key) or n < 1 or n > 100000 then
			return
		end
		if not G.Joueurs.take(player, "gold", n) then
			G.Util.toast(player, "Tu n'as pas " .. n .. " 💰.")
			return
		end
		v.tresor = (v.tresor or 0) + n
		log(v, player.DisplayName .. " donne " .. n .. " 💰 au trésor.")
		G.Economie.record(player, "don_village", n .. " -> " .. key)
		G.Joueurs.addSkillXp(player, "commerce", 1)
		G.Law.addHonor(player, math.min(5, math.floor(n / 100)))
		G.Joueurs.sync(player)
		G.Mondes.saveSoon(player)
		send(player, key)
	end)
	G.Interact.onAction("pol_taxe", function(player, data)
		local key = data.v
		local v = type(key) == "string" and V(key)
		if not v or v.maire ~= tostring(player.UserId) or not near(player, key) then
			return
		end
		local t = math.clamp(math.floor(tonumber(data.t) or 5), 0, TAX_MAX)
		if t ~= v.taxe then
			log(v, "Le maire fixe la taxe du marché à " .. t .. " %.")
			v.taxe = t
		end
		send(player, key)
	end)
	G.Interact.onAction("pol_projet", function(player, data)
		local key = data.v
		local v = type(key) == "string" and V(key)
		local p = type(data.id) == "string" and PROJECTS[data.id]
		if not v or not p or v.maire ~= tostring(player.UserId) or not near(player, key) then
			return
		end
		if (v.tresor or 0) < p.cost then
			G.Util.toast(player, "Le trésor n'a que " .. (v.tresor or 0) .. " 💰 (il en faut " .. p.cost .. ").")
			return
		end
		v.tresor -= p.cost
		v.projets = v.projets or {}
		local regKey = v.region or key -- ville de joueurs (Villes.council) : sa région ; village : la clé est la région
		if data.id == "foire" then
			G.Evenements.fair = { region = regKey, day = G.world.day, name = v.name }
		elseif data.id == "reparer" then
			Politique.repairNow(regKey)
		elseif data.id == "ronde" then
			v.projets.ronde = G.world.day + 7
		end
		log(v, "Projet « " .. p.name .. " » payé par le trésor (-" .. p.cost .. " 💰).")
		G.Economie.record(player, "projet_village", data.id .. " " .. key)
		-- tout le village le remarque (sur place, pas d'annonce au serveur)
		for _, q in G.Game.players() do
			local r = G.Util.root(q)
			if r and (r.Position - Vector3.new(v.cx, r.Position.Y, v.cz)).Magnitude < 200 then
				G.Util.toast(q, "🏛️ " .. v.name .. " : " .. p.name .. " !", "big")
			end
		end
		G.Mondes.saveSoon(player)
		send(player, key)
	end)
end

-- Rebâtit tout de suite les bâtiments et le décor cassés du village
function Politique.repairNow(key: string)
	local reg = G.World.loaded[key]
	if not reg or not reg.state.wrecked then
		return
	end
	for k in reg.state.wrecked do
		reg.state.wrecked[k] = -1000
	end
	if G.Demolir.newDay then
		G.Demolir.newDay()
	end
end

-- Décompte au lever du jour
function Politique.newDay()
	for _, v in villages() do
		-- maire absent trop longtemps : charge vacante
		if v.maire and not active(v.maire) then
			log(v, (v.maireName or "Le maire") .. " a disparu depuis trop longtemps : la mairie est vacante.")
			v.maire, v.maireName = nil, nil
		end
		local count = tally(v)
		local best, bestN = nil, 0
		for cand, n in count do
			if n > bestN then
				best, bestN = cand, n
			end
		end
		local cur = v.maire and (count[v.maire] or 0) or -1
		if best and best ~= v.maire and bestN > cur then
			v.maire, v.maireName, v.depuis = best, v.cand[best], G.world.day
			log(v, v.maireName .. " devient maire (" .. bestN .. " voix).")
		end
		-- les votes d'anciens habitants partis ne comptent plus : on les nettoie
		for voter in v.votes do
			if not isResident(voter, v) then
				v.votes[voter] = nil
			end
		end
	end
end

return Politique
