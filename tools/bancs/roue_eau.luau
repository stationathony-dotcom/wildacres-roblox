-- Banc Edit : roue à eau et moulin (Machines.waterPowered / newDay), G simulé.
local mod = game.ServerScriptService.Systemes.Machines:Clone()
local M = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local water = {} -- x -> true
local mill = { item = "windmill", x = 100, z = 100, mill = { wheat = 30, flour = 0 } }
local rs = { placed = { mill } }
local G = {
	Config = { CELL = 4 },
	Interact = { onPrompt = function() end },
	world = { regions = { a = rs } },
	Util = { isWater = function(x, z) return water[math.floor(x) .. "," .. math.floor(z)] == true end },
}
M.init(G)
M.newDay()
check("sans roue : 2 pour 3 (30 blé → 20 farine)", mill.mill.flour == 20)
local wheel = { item = "water_wheel", x = 110, z = 100 }
table.insert(rs.placed, wheel)
mill.mill.wheat, mill.mill.flour = 30, 0
M.newDay()
check("roue loin de l'eau : pas d'effet", mill.mill.flour == 20)
water["114,100"] = true
mill.mill.wheat, mill.mill.flour = 30, 0
M.newDay()
check("roue au bord de l'eau : 1 pour 1 (30 → 30)", mill.mill.flour == 30)
wheel.x = 140
mill.mill.wheat, mill.mill.flour = 30, 0
water["144,100"] = true
M.newDay()
check("roue trop loin du moulin (40 studs) : 2 pour 3", mill.mill.flour == 20)
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
