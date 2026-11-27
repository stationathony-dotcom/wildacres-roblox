-- Chefs-d'œuvre (27/11, MANQUES-MMO n° 12 : « chaque voie doit avoir ses projets ambitieux »).
-- Données : Shared/Equilibre E.OEUVRES. Un projet PERSONNEL par voie, nourri au fil du temps :
--   · action « oeuvre » { id } au village (pas à distance) : on apporte tout ce qu'on a des matières
--     encore manquantes ; l'avancée reste dans le perso (prof.oeuvres[id] = { have = {...}, done = jour }) ;
--   · il faut la compétence de la voie à son niveau BRUT (Joueurs.skillRaw, règle 4) ;
--   · achevé : titre unique (Social, compteur « oeuvre_<id> ») + pièce légendaire qui rejoint le sac.
--   · action « oeuvres » : l'état de tous les projets (message « oeuvres »).

local Oeuvres = {}
local G

Oeuvres.LIST = {} -- id -> fiche

local function load()
	local E = G.Equilibre
	if not E then
		local ok, mod = pcall(require, game:GetService("ReplicatedStorage").Shared.Equilibre)
		E = ok and mod or nil
	end
	for _, o in (E and E.OEUVRES) or {} do
		Oeuvres.LIST[o[1]] = { id = o[1], voie = o[2], name = o[3], skill = o[4], level = o[5], needs = o[6], title = o[7], piece = o[8] }
	end
end

local function state(player: Player, id: string)
	local prof = G.Joueurs.get(player)
	if not prof then
		return nil
	end
	prof.oeuvres = prof.oeuvres or {}
	prof.oeuvres[id] = prof.oeuvres[id] or { have = {} }
	return prof.oeuvres[id]
end

-- apporter : (vrai, message) ; ce qu'on apporte est pris du sac, jamais plus que ce qui manque
function Oeuvres.contribute(player: Player, id: string): (boolean, string)
	local o = Oeuvres.LIST[id]
	if not o then
		return false, "Projet inconnu."
	end
	if not (G.Quetes and rawget(G.Quetes, "nearVillage") and G.Quetes.nearVillage(player)) then
		return false, "Un chef-d'œuvre se mène depuis un village."
	end
	if G.Joueurs.skillRaw(player, o.skill) < o.level then
		return false, "Il faut " .. o.skill .. " " .. o.level .. " pour entreprendre " .. o.name .. "."
	end
	local st = state(player, id)
	if st.done then
		return false, "Tu as déjà achevé " .. o.name .. "."
	end
	local given, left = 0, 0
	for item, need in o.needs do
		local missing = need - (st.have[item] or 0)
		if missing > 0 then
			local n = math.min(missing, G.Joueurs.count(player, item))
			if n > 0 and G.Joueurs.take(player, item, n) then
				st.have[item] = (st.have[item] or 0) + n
				given += n
				missing -= n
			end
			left += math.max(0, missing)
		end
	end
	G.Joueurs.markDirty(player)
	if left == 0 then
		st.done = G.world.day or 1
		local p = o.piece
		local prof = G.Joueurs.get(player)
		table.insert(prof.gear, { slot = p[1], name = p[2], rarity = 5, stats = table.clone(p[3]), power = p.power or 0, visual = p.visual or "",
			oeuvre = id, id = math.random(1, 2 ^ 30) })
		if G.Social and rawget(G.Social, "bump") then
			G.Social.bump(player, "oeuvres", 1)
			pcall(G.Social.checkTitles, player) -- titre unique de l'œuvre
		end
		G.Joueurs.sync(player)
		return true, "🏛️ Tu achèves " .. o.name .. " ! Titre « " .. o.title .. " » et " .. p[2] .. "."
	end
	if given == 0 then
		return false, "Rien à apporter : il manque encore " .. left .. " matières."
	end
	G.Joueurs.sync(player)
	return true, "Tu apportes " .. given .. " matières à " .. o.name .. " (reste " .. left .. ")."
end

function Oeuvres.status(player: Player)
	local out = {}
	for id, o in Oeuvres.LIST do
		local prof = G.Joueurs.get(player)
		local st = prof and prof.oeuvres and prof.oeuvres[id]
		local have, total = 0, 0
		for item, need in o.needs do
			total += need
			have += math.min(need, st and st.have[item] or 0)
		end
		table.insert(out, { id = id, voie = o.voie, name = o.name, skill = o.skill, level = o.level, title = o.title,
			have = have, total = total, done = st and st.done or nil, needs = o.needs, got = st and st.have or {} })
	end
	table.sort(out, function(a, b)
		return a.voie < b.voie
	end)
	return out
end

-- titre d'une œuvre achevée (Social.titlesOf peut l'ajouter) : { id, name }
function Oeuvres.titles(player: Player)
	local out = {}
	local prof = G.Joueurs.get(player)
	for id, o in Oeuvres.LIST do
		if prof and prof.oeuvres and prof.oeuvres[id] and prof.oeuvres[id].done then
			table.insert(out, { id = "oeuvre_" .. id, name = o.title })
		end
	end
	return out
end

function Oeuvres.init(g)
	G = g
	load()
	G.Interact.onAction("oeuvre", function(player, data)
		local id = type(data) == "table" and data.id
		if type(id) ~= "string" then
			return
		end
		local ok, msg = Oeuvres.contribute(player, id)
		G.Util.toast(player, msg, ok and "gain" or nil)
	end)
	G.Interact.onAction("oeuvres", function(player)
		G.remotes.Menu:FireClient(player, { kind = "oeuvres", oeuvres = Oeuvres.status(player) })
	end)
end

return Oeuvres
