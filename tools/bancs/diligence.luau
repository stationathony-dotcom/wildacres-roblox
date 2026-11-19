-- Banc Edit : diligence du palefrenier (Metiers.coachTrips / choice "dili_…"), G simulé.
local mod = game.ServerScriptService.Systemes.Metiers:Clone()
local M = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local villages = {
	{ key = "0,0", name = "Valdor", x = 0, z = 0 },
	{ key = "2,0", name = "Prèsvert", x = 400, z = 0 },
	{ key = "5,0", name = "Rocneige", x = 1000, z = 0 },
	{ key = "0,9", name = "Inconnu", x = 0, z = 1800 },
}
local journal = "0,0;2,0;5,0"
local prof = { stars = 0 }
local gold = 100
local teleported
local G = {
	Quetes = { villages = function() return villages end },
	Journal = { keysFor = function() return journal end },
	Joueurs = {
		get = function() return prof end,
		take = function(_, _, n) if gold < n then return false end gold -= n return true end,
		sync = function() end,
	},
	remotes = { Fade = { FireClient = function() end } },
	Game = { teleport = function(_, pos) teleported = pos end },
	Util = { groundY = function() return 0 end, toast = function() end },
}
pcall(M.init, G)
local P = { Parent = true }
local e = { root = { Position = Vector3.new(0, 0, 0) }, data = { metier = "stablemaster" } }
local trips = M.coachTrips(P, e)
check("seuls les villages découverts (et pas celui-ci)", #trips == 2)
check("les plus proches d'abord, prix selon la distance", trips[1].name == "Prèsvert" and trips[1].price == 10 + math.floor(400 / 25) and trips[2].price > trips[1].price)
-- voyage
local res = M.choice(P, e, "dili_2,0")
check("voyage payé, départ (fenêtre fermée)", res == false and gold == 100 - trips[1].price)
task.wait(3)
check("arrivée à Prèsvert", teleported ~= nil and math.abs(teleported.X - 406) < 1)
prof.stars = 2
local before = gold
check("recherché : le cocher refuse", type(M.choice(P, e, "dili_2,0")) == "string" and gold == before)
prof.stars = 0
gold = 3
check("pas assez d'or : refus", type(M.choice(P, e, "dili_2,0")) == "string" and gold == 3)
check("village non découvert : refus", type(M.choice(P, e, "dili_0,9")) == "string")
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
