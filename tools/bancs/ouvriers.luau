-- Banc Edit : ouvriers agricoles (Systemes/Ouvriers), G simulé.
local mod = game.ServerScriptService.Systemes.Ouvriers:Clone()
local O = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local bag = { gold = 500 }
local toasts = {}
local refreshed = 0
local P = {}
local tilled = {}
for i = 1, 100 do
	tilled["c" .. i] = { crop = "wheat", stage = 0, watered = false, owner = "u1" }
end
tilled.autre = { crop = "wheat", stage = 0, watered = false, owner = "u2" }
tilled.vide = { stage = 0, watered = false, owner = "u1" } -- bêchée, rien semé
local G = {
	world = { day = 5, extra = {}, regions = { r1 = { tilled = tilled } } },
	Joueurs = {
		take = function(_, i, n) if (bag[i] or 0) < n then return false end bag[i] -= n return true end,
		sync = function() end,
	},
	Util = { pid = function() return "u1" end, playerOf = function(pid) return pid == "u1" and P or nil end, toast = function(_, t) table.insert(toasts, t) end },
	Economie = { record = function() end },
	Farm = { refreshAll = function() refreshed += 1 end },
}
O.init(G)
local function watered(owner)
	local n = 0
	for _, st in tilled do
		if st.owner == owner and st.watered then
			n += 1
		end
	end
	return n
end

check("sans contrat : rien", O.describe(P):find("Aucun") ~= nil)
local txt = O.hire(P, { data = { name = "Jeanne" } })
check("embauche payée d'avance (45 or)", bag.gold == 455 and txt:find("1 ouvrier") ~= nil)
O.newDay()
check("un ouvrier arrose 40 cases semées", watered("u1") == 40)
check("pas les champs des autres", watered("u2") == 0)
check("pas une case sans semis", tilled.vide.watered == false)
check("rendu rafraîchi", refreshed == 1)
for _, st in tilled do
	st.watered = false
end
O.hire(P, { data = { name = "Jeanne" } })
local c = G.world.extra.ouvriers.u1
check("deuxième ouvrier : 2 ouvriers, jours répartis", c.n == 2 and c.til >= 5)
O.newDay()
check("deux ouvriers arrosent 80 cases", watered("u1") == 80)
-- fin de contrat
G.world.day = 30
for _, st in tilled do
	st.watered = false
end
O.newDay()
check("contrat fini : plus d'arrosage, message", watered("u1") == 0 and G.world.extra.ouvriers.u1 == nil and toasts[#toasts]:find("fini") ~= nil)
bag.gold = 10
check("pas assez d'or : refus", O.hire(P, nil):find("pour rien") ~= nil and bag.gold == 10)

mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
