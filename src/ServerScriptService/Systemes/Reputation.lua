-- Réputation par village (19/11, « à ne pas oublier.txt », priorité élevée) : chaque village de l'île
-- se fait SA propre idée de chaque joueur, de −100 (haï) à +100 (héros). Rien d'imposé : elle naît
-- de ce qu'on fait sur place.
--   + rendre une quête au village, chasser les monstres qui rôdent autour, commercer avec ses gens
--     (plafonné chaque jour : on ne « farme » pas sa réputation au comptoir) ;
--   − un crime VU près du village (selon sa gravité ; sans témoin, personne ne sait).
-- Effets : prix des boutiques du village (−10 % pour un héros, +25 % pour un haï), un village qui te
-- hait ne commerce plus avec toi ; un nouveau palier est annoncé ; /reputation résume.
-- Le temps efface lentement la rancune (+1 par jour vers 0 tant qu'on est mal vu), jamais l'estime.
-- État : G.world.players[uid].rep = { [clé du village] = valeur } (par monde, comme les quêtes).

local Reputation = {}
local G

local NEAR = 220 -- studs : au-delà, on n'est « près » d'aucun village
local TRADE_DAY = 3 -- réputation gagnée au plus chaque jour en commerçant, par village
local HUNT_DAY = 5 -- idem en chassant les monstres alentour

-- paliers : { seuil minimal, nom, icône, multiplicateur des prix d'achat, des prix de vente }
local TIERS = {
	{ -100, "Haï", "💢", 1.25, 0.75 },
	{ -59, "Mal vu", "😠", 1.10, 0.90 },
	{ -19, "Inconnu", "🙂", 1, 1 },
	{ 20, "Apprécié", "😊", 0.97, 1.03 },
	{ 50, "Honoré", "🎖️", 0.94, 1.06 },
	{ 85, "Héros", "🏆", 0.90, 1.10 },
}
Reputation.TIERS = TIERS
Reputation.BEST_BUY = 0.90 -- le prix le plus bas possible (garde-fou anti-arbitrage de Shop)

-- publie au client (attribut « Reputation » = JSON { nom du village = valeur }) pour le bandeau du lieu
local function publish(player: Player)
	local r = G.world and G.world.players and G.world.players[tostring(player.UserId)]
	local Q = G.Quetes and rawget(G.Quetes, "villages")
	if not Q then
		return
	end
	local out = {}
	for _, v in Q() do
		local val = r and r.rep and r.rep[v.key]
		if val then
			out[v.name] = val
		end
	end
	player:SetAttribute("Reputation", game:GetService("HttpService"):JSONEncode(out))
end
Reputation.publish = publish

function Reputation.init(g)
	G = g
	game:GetService("Players").PlayerAdded:Connect(function(p)
		task.delay(6, function()
			if p.Parent then
				pcall(publish, p)
			end
		end)
	end)
end

local function tierOf(v: number)
	local t = TIERS[1]
	for _, x in TIERS do
		if v >= x[1] then
			t = x
		end
	end
	return t
end
Reputation.tierOf = tierOf

local function store(player: Player)
	if not (G.world and G.world.players) then
		return nil
	end
	local uid = tostring(player.UserId)
	local r = G.world.players[uid]
	if not r then
		r = {}
		G.world.players[uid] = r
	end
	r.rep = r.rep or {}
	return r
end

-- le village le plus proche (dans NEAR studs) : { key, name, x, z } ou nil
function Reputation.villageAt(pos: Vector3)
	local Q = G.Quetes and rawget(G.Quetes, "villages")
	if not Q then
		return nil
	end
	local best, bd = nil, NEAR
	for _, v in Q() do
		local d = Vector2.new(v.x - pos.X, v.z - pos.Z).Magnitude
		if d < bd then
			best, bd = v, d
		end
	end
	return best
end

function Reputation.get(player: Player, key: string): number
	local r = store(player)
	return r and r.rep[key] or 0
end

-- ajoute delta à la réputation auprès du village v ({ key, name }) ; `kind` = plafond du jour éventuel
function Reputation.add(player: Player, v, delta: number, kind: string?)
	local r = v and store(player)
	if not r or delta == 0 then
		return
	end
	if kind then
		local cap = kind == "commerce" and TRADE_DAY or HUNT_DAY
		r.repDay = (r.repDay and r.repDay.day == G.world.day) and r.repDay or { day = G.world.day }
		local k = kind .. "|" .. v.key
		local used = r.repDay[k] or 0
		delta = math.min(delta, cap - used)
		if delta <= 0 then
			return
		end
		r.repDay[k] = used + delta
	end
	local old = r.rep[v.key] or 0
	local new = math.clamp(old + delta, -100, 100)
	r.rep[v.key] = new ~= 0 and new or nil
	pcall(publish, player)
	local t0, t1 = tierOf(old), tierOf(new)
	if t0 ~= t1 then
		local up = new > old
		G.Util.toast(player, string.format("%s %s : tu es désormais « %s »%s", t1[3], v.name, t1[2],
			up and "" or " (les prix montent)"), up and "big" or "danger")
	end
end

-- où que ce soit : le village proche de pos, s'il y en a un
function Reputation.addAt(player: Player, pos: Vector3, delta: number, kind: string?)
	local v = pos and Reputation.villageAt(pos)
	if v then
		Reputation.add(player, v, delta, kind)
	end
end

-- multiplicateurs de prix (achat, vente) pour ce joueur au comptoir placé en pos
function Reputation.priceMult(player: Player, pos: Vector3): (number, number)
	local v = pos and Reputation.villageAt(pos)
	if not v then
		return 1, 1
	end
	local t = tierOf(Reputation.get(player, v.key))
	return t[4], t[5]
end

-- un village qui te hait ne commerce plus avec toi : renvoie le message, ou nil
function Reputation.refuses(player: Player, pos: Vector3): string?
	local v = pos and Reputation.villageAt(pos)
	if v and Reputation.get(player, v.key) < TIERS[2][1] then
		return "💢 À " .. v.name .. ", plus personne ne veut faire affaire avec toi."
	end
	return nil
end

-- crime vu près d'un village : la gravité suit les étoiles du crime
function Reputation.crime(player: Player, kind: string, pos: Vector3)
	local w = G.Config.CRIMES and G.Config.CRIMES[kind]
	Reputation.addAt(player, pos, -math.max(3, (w and w.stars or 1) * 6))
end

-- résumé pour /reputation
function Reputation.describe(player: Player): { string }
	local r = store(player)
	local lines = {}
	local Q = G.Quetes and rawget(G.Quetes, "villages")
	if not r or not Q then
		return { "Aucune réputation pour l'instant." }
	end
	local list = {}
	for _, v in Q() do
		local val = r.rep[v.key]
		if val then
			table.insert(list, { v = v, val = val })
		end
	end
	table.sort(list, function(a, b)
		return a.val > b.val
	end)
	for i = 1, math.min(#list, 12) do
		local e = list[i]
		local t = tierOf(e.val)
		table.insert(lines, string.format("%s %s : %s (%+d)", t[3], e.v.name, t[2], e.val))
	end
	if #lines == 0 then
		lines[1] = "Aucun village ne te connaît encore : rends des quêtes, chasse, commerce…"
	end
	return lines
end

-- chaque matin : la rancune s'efface d'un point (l'estime, elle, reste)
function Reputation.newDay()
	for _, r in (G.world and G.world.players) or {} do
		if type(r) == "table" and r.rep then
			for key, val in r.rep do
				if val < 0 then
					r.rep[key] = val + 1 < 0 and val + 1 or nil
				end
			end
		end
	end
	for _, p in game:GetService("Players"):GetPlayers() do
		pcall(publish, p)
	end
end

return Reputation
