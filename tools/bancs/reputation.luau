-- Banc Edit : réputation par village (Systemes/Reputation), G simulé.
local mod = game.ServerScriptService.Systemes.Reputation:Clone()
local R = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local toasts = {}
local attrs = {}
local P = { UserId = 42, Name = "Testeur" }
function P:SetAttribute(k, v)
	attrs[k] = v
end
local V1 = { key = "0,0", name = "Valdor", x = 0, z = 0 }
local V2 = { key = "3,1", name = "Rocneige", x = 1000, z = 300 }
local G = {
	world = { day = 1, players = {} },
	Config = { CRIMES = { theft = { stars = 1 }, murder = { stars = 4 } } },
	Quetes = { villages = function() return { V1, V2 } end },
	Util = { toast = function(_, msg) table.insert(toasts, msg) end },
}
R.init(G)

check("inconnu au départ", R.get(P, "0,0") == 0)
check("loin de tout : aucun village", R.villageAt(Vector3.new(500, 0, 500)) == nil)
check("près de Valdor", R.villageAt(Vector3.new(30, 0, -40)) == V1)

-- quête rendue
R.add(P, V1, 10)
check("+10 après une quête", R.get(P, "0,0") == 10)
check("publié au client", attrs.Reputation ~= nil and string.find(attrs.Reputation, "Valdor") ~= nil)

-- commerce plafonné par jour
for _ = 1, 10 do
	R.addAt(P, Vector3.new(5, 0, 5), 1, "commerce")
end
check("commerce : +3 par jour au plus", R.get(P, "0,0") == 13)
G.world.day = 2
R.addAt(P, Vector3.new(5, 0, 5), 1, "commerce")
check("commerce : le plafond repart le lendemain", R.get(P, "0,0") == 14)

-- palier annoncé
local n0 = #toasts
R.add(P, V1, 10)
check("palier Apprécié annoncé", #toasts == n0 + 1 and string.find(toasts[#toasts], "Apprécié") ~= nil)
local b, s = R.priceMult(P, Vector3.new(0, 0, 0))
check("Apprécié : achats −3 %, ventes +3 %", b == 0.97 and s == 1.03)
b, s = R.priceMult(P, Vector3.new(1000, 0, 300))
check("autre village : prix normaux", b == 1 and s == 1)

-- crime vu
R.crime(P, "murder", Vector3.new(1000, 0, 300))
check("meurtre vu à Rocneige : −24", R.get(P, "3,1") == -24)
check("Valdor ne l'apprend pas", R.get(P, "0,0") == 24)
R.crime(P, "murder", Vector3.new(1000, 0, 300))
R.crime(P, "murder", Vector3.new(1000, 0, 300))
check("haï à Rocneige", R.tierOf(R.get(P, "3,1"))[2] == "Haï")
check("Rocneige refuse de commercer", R.refuses(P, Vector3.new(1000, 0, 300)) ~= nil)
check("Valdor commerce toujours", R.refuses(P, Vector3.new(0, 0, 0)) == nil)
b = R.priceMult(P, Vector3.new(1000, 0, 300))
check("haï : achats +25 %", b == 1.25)
check("jamais sous −100", (function()
	for _ = 1, 20 do
		R.crime(P, "murder", Vector3.new(1000, 0, 300))
	end
	return R.get(P, "3,1") == -100
end)())

-- la rancune s'efface, l'estime reste
R.newDay()
check("rancune : +1 par jour", R.get(P, "3,1") == -99)
check("estime inchangée", R.get(P, "0,0") == 24)

-- chasse plafonnée
for _ = 1, 10 do
	R.addAt(P, Vector3.new(20, 0, 20), 2, "chasse")
end
check("chasse : +5 par jour au plus", R.get(P, "0,0") == 29)

local lines = R.describe(P)
check("résumé /reputation trié (Valdor d'abord)", #lines == 2 and string.find(lines[1], "Valdor") ~= nil)
check("garde-fou anti-arbitrage = meilleur prix possible", R.BEST_BUY <= R.TIERS[#R.TIERS][4])

mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
