-- Banc des trésors cachés par les joueurs (Systemes/Tresors, 20/11) — mode Edit, G simulé.
local T = assert(loadstring(game.ServerScriptService.Systemes.Tresors.Source, "Tresors"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end
local bag, pos, toasts = {}, {}, {}
local function mk(id, name)
	local p = { UserId = id, DisplayName = name, Name = name }
	bag[p], pos[p] = { gold = 500, planks = 10 }, Vector3.new(300, 5, 100)
	return p
end
local A, B = mk(1, "Alix"), mk(2, "Bastien")
local G = {
	world = { day = 4, players = {}, extra = {} },
	Config = { ITEMS = { gold = { name = "Or" }, planks = { name = "Planches" }, axe = { name = "Hache", tool = true } } },
	Util = { root = function(p) return { Position = pos[p] } end, pid = function(p) return "u" .. p.UserId end, isWater = function() return false end,
		newId = function() return "c" .. math.random(1000, 9999) end, toast = function(p, t) table.insert(toasts, { p, t }) end, groundY = function() return 5 end },
	Joueurs = { count = function(p, i) return bag[p][i] or 0 end, take = function(p, i, n) if (bag[p][i] or 0) < n then return false end bag[p][i] -= n return true end,
		add = function(p, i, n) bag[p][i] = (bag[p][i] or 0) + n end, sync = function() end },
	Economie = { record = function() end },
	Quetes = { villages = function() return { { key = "1,0", name = "Valdor", x = 300, z = 220 } } end },
}
T.init(G)
check("objet inconnu ou outil : refusé", not T.bury(A, "axe", 1) and not T.bury(A, "licorne", 1))
check("plus que ce qu'on a : refusé", not T.bury(A, "gold", 9999))
local ok, msg = T.bury(A, "or", 200)
check("enterrer 200 or (nom « or » compris)", ok and bag[A].gold == 300)
check("indice : à 120 pas au nord de Valdor (" .. tostring(msg) .. ")", msg:find("120 pas au nord de Valdor") ~= nil)
T.bury(A, "planks", 5)
local n = 0
for _ in G.world.extra.caches do
	n += 1
end
check("compléter sa cache au même endroit : toujours une seule cache", n == 1)
local id = next(G.world.extra.caches)
check("donner la carte à Bastien", T.giveMap(A, id, B) and G.world.players["2"].maps[id] == true)
check("Bastien voit la croix dans /cartes", T.list(B)[1]:find("Carte de Alix") ~= nil)
check("donner la carte d'une cache qui n'est pas à soi : refusé", not T.giveMap(B, id, A))
-- creuser
pos[B] = Vector3.new(320, 5, 100)
check("trop loin de la croix : rien", T.dig(B) == false)
pos[B] = Vector3.new(302, 5, 101)
T.dig(B)
T.dig(B)
check("2 coups : pas encore", G.world.extra.caches[id] ~= nil and bag[B].gold == 500)
check("3e coup : Bastien prend 200 or et 5 planches", T.dig(B) == true and bag[B].gold == 700 and bag[B].planks == 15)
check("la cache et la carte disparaissent", G.world.extra.caches[id] == nil and G.world.players["2"].maps[id] == nil)
return fails .. " échec(s)\n" .. table.concat(out, "\n")
