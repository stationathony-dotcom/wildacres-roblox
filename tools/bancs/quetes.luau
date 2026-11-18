-- Banc des quêtes facultatives (mode Edit, sans Play) : Quetes avec un G simulé sur une vraie île.
-- Vérifie : villages trouvés, 4 offres par village, offres identiques pour tous et différentes d'une
-- île à l'autre, prise / progression / rendu / abandon, apporter (objets pris), lettre, refus loin
-- du village, pas deux fois la même offre.
local folder = Instance.new("Folder")
folder.Parent = game:GetService("ServerStorage")
local sh = game.ReplicatedStorage.Shared:Clone()
sh.Parent = folder
local function mod(name)
	local m = game.ServerScriptService.Systemes[name]:Clone()
	m.Parent = folder
	return require(m)
end
local Config = require(sh.Config)
local WG = require(sh.RegionPlan)
local B = mod("Bestiaire")
local Q = mod("Quetes")

local res, fails = {}, 0
local function check(name, cond)
	table.insert(res, (cond and "OK   " or "ÉCHEC ") .. name)
	if not cond then
		fails += 1
	end
end

local bag, honor, toasts, sent = {}, 0, {}, nil
local pos = Vector3.zero
local P = { UserId = 5, Name = "Q" }
local G = {
	Config = Config,
	WG = WG,
	Bestiaire = B,
	world = { seed = 13, day = 4, danger = 1, players = {} },
	Util = { root = function() return { Position = pos } end, toast = function(_, t) table.insert(toasts, t) end },
	Joueurs = {
		add = function(_, i, n) bag[i] = (bag[i] or 0) + n end,
		has = function(_, i, n) return (bag[i] or 0) >= (n or 1) end,
		take = function(_, i, n) if (bag[i] or 0) < n then return false end bag[i] -= n return true end,
		addSkillXp = function() end,
		sync = function() end,
	},
	Law = { addHonor = function(_, n) honor += n end },
	remotes = { Fx = { FireClient = function(_, _, kind, data) sent = data end } },
	Interact = { onAction = function() end, onPrompt = function() end },
	World = { loaded = {} },
}
local standing = {} -- clé village -> habitants debout (simulé)
local npcs = {}
G.Npcs = {
	standingIn = function(k) return standing[k] or 0 end,
	byId = function(id) return npcs[id] end,
}
G.wg = WG.new(G.world.seed, 2)
pcall(B.init, G)
Q.init(G)

local vs = Q.villages()
check("villages de l'île trouvés (" .. #vs .. ")", #vs >= 5)
for _, vv in vs do
	Q.registerBoard(vv.key, { Position = Vector3.new(vv.x, 0, vv.z), Parent = workspace })
end
-- au tableau du village vv (on s'y place et on l'ouvre)
local function at(vv)
	pos = Vector3.new(vv.x, 0, vv.z)
	Q.openBoard(P, vv.key)
end
local v = vs[1]
local offers = Q.offers(v)
check("4 offres au village " .. v.name, #offers == 4)
local again = Q.offers(v)
check("mêmes offres pour tout le monde (déterministe)", again[1].id == offers[1].id and again[1].title == offers[1].title and again[1].need == offers[1].need)
local orders = {}
local startDay = G.world.day
for rotation = 0, 3 do
	G.world.day = startDay + 2 * rotation
	local order = Q.offers(v)[4]
	local same = Q.offers(v)[4]
	check("commande stable, distincte et réalisable (" .. order.title .. ")",
		order.id == same.id and order.gold == same.gold and order.id:match(":commande$")
			and order.kind == "apporter" and Config.ITEMS[order.key] ~= nil and order.need > 0 and not orders[order.key])
	orders[order.key] = true
end
G.world.day = startDay

-- variété : sur tous les villages, plusieurs sortes de quêtes
local kinds, n = {}, 0
for _, vv in vs do
	for _, q in Q.offers(vv) do
		if not kinds[q.kind] then
			kinds[q.kind] = true
			n += 1
		end
	end
end
check("au moins 6 sortes de quêtes sur l'île (" .. n .. ")", n >= 6)

-- autre île (autre thème) : quêtes différentes
local G2seed = 25
local saved = G.world.seed
G.world.seed, G.wg = G2seed, WG.new(G2seed, 2)
local vs2 = Q.villages()
local other = Q.offers(vs2[1])
G.world.seed, G.wg = saved, WG.new(saved, 2)
Q.villages()
check("une autre île a d'autres villages / quêtes", vs2[1].name ~= v.name or other[1].title ~= offers[1].title)

-- loin de tout village : rien à prendre
pos = Vector3.new(99999, 0, 99999)
Q.take(P, offers[1].id)
local r0 = G.world.players["5"]
check("loin du village : refus", r0 == nil or next(r0.quetes.act) == nil)

-- au village : prendre une quête de chasse (on cherche une offre « tuer » sur l'île)
local hunt, hv
for _, vv in vs do
	for _, q in Q.offers(vv) do
		if q.kind == "tuer" and not hunt then
			hunt, hv = q, vv
		end
	end
end
if hunt then
	pos = Vector3.new(hv.x, 0, hv.z)
	Q.take(P, hunt.id)
	check("au village sans tableau ni habitant : rien à prendre", G.world.players["5"] == nil or G.world.players["5"].quetes.act[hunt.id] == nil)
	at(hv)
	check("tableau ouvert : le client voit les offres", sent and sent.village and #sent.village.offers >= 1)
	Q.take(P, hunt.id)
	local st = G.world.players["5"].quetes
	check("quête de chasse prise (" .. hunt.title .. ")", st.act[hunt.id] ~= nil)
	Q.note(P, "tuer", "pas_la_bonne_bete")
	check("une autre bête ne compte pas", st.act[hunt.id].got == 0)
	for _ = 1, hunt.need do
		Q.note(P, "tuer", hunt.key)
	end
	check("progression jusqu'au bout", st.act[hunt.id].got == hunt.need)
	local g0 = bag.gold or 0
	pos = Vector3.new(hv.x + 40, 0, hv.z)
	Q.turnIn(P, hunt.id)
	check("loin du tableau : pas rendue", st.act[hunt.id] ~= nil)
	at(hv)
	Q.turnIn(P, hunt.id)
	check("rendue : or + honneur", (bag.gold or 0) - g0 == hunt.gold and honor == 1 and st.act[hunt.id] == nil)
	Q.take(P, hunt.id)
	check("même offre pas reprise deux fois", st.act[hunt.id] == nil)
else
	check("une offre de chasse existe", false)
end

-- apporter : les objets sont pris au rendu
local bring, bv
for _, vv in vs do
	for _, q in Q.offers(vv) do
		if q.kind == "apporter" and not bring then
			bring, bv = q, vv
		end
	end
end
if bring then
	-- auprès d'un habitant (pas le tableau)
	pos = Vector3.new(bv.x, 0, bv.z)
	npcs.n1 = { id = "n1", reg = { key = bv.key }, state = "routine", model = { Parent = workspace }, root = { Position = pos + Vector3.new(3, 0, 0) }, data = { name = "Berthe" } }
	Q.openNpc(P, npcs.n1)
	check("un habitant donne les quêtes du village", sent and sent.village and sent.village.from == "Berthe")
	Q.take(P, bring.id)
	Q.turnIn(P, bring.id)
	local st = G.world.players["5"].quetes
	check("apporter sans les objets : refus", st.act[bring.id] ~= nil)
	bag[bring.key] = bring.need + 2
	npcs.n1.state = "ko"
	Q.turnIn(P, bring.id)
	check("habitant assommé : plus de conversation", st.act[bring.id] ~= nil)
	npcs.n2 = { id = "n2", reg = { key = bv.key }, state = "routine", model = { Parent = workspace }, root = { Position = pos }, data = { name = "Gaspard" } }
	Q.openNpc(P, npcs.n2)
	Q.turnIn(P, bring.id)
	check("apporter : objets pris (" .. bring.need .. " " .. bring.key .. ")", bag[bring.key] == 2 and st.act[bring.id] == nil)
end

-- village déserté : plus d'offres, et ses quêtes se rendent dans un autre village (transfert)
do
	local a, b = vs[1], vs[2]
	at(a)
	local st = G.world.players["5"].quetes
	local offer = nil
	for _, q in Q.offers(a) do
		if q.kind ~= "lettre" and q.kind ~= "apporter" and not st.act[q.id] and not st.fait[q.id] then
			offer = offer or q
		end
	end
	if offer then
		Q.take(P, offer.id)
		st.act[offer.id].got = offer.need
		G.World.loaded[a.key] = true
		standing[a.key] = 0
		at(a)
		check("village déserté : plus d'offres", sent.village.deserted == true and #sent.village.offers == 0)
		G.World.loaded[b.key] = true
		standing[b.key] = 3
		at(b)
		Q.turnIn(P, offer.id)
		check("quête du village déserté rendue ailleurs (transfert)", st.act[offer.id] == nil)
		standing[a.key] = nil
		G.World.loaded[a.key] = nil
	else
		check("une offre à transférer existe", false)
	end
end

-- abandon libre
local any = Q.offers(vs[#vs])
at(vs[#vs])
Q.take(P, any[1].id)
Q.drop(P, any[1].id)
check("abandon sans conséquence", G.world.players["5"].quetes.act[any[1].id] == nil)
check("le client reçoit la liste", sent ~= nil and sent.actives ~= nil)

folder:Destroy()
return string.format("%d échec(s) — île %d (%s)\n%s", fails, G.world.seed, G.wg.theme.id, table.concat(res, "\n"))
