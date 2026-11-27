-- Banc des chefs-d'œuvre (27/11, Systemes/Oeuvres + Equilibre E.OEUVRES) en mode Edit, faux G.
local f = game.ReplicatedStorage.Shared:Clone()
f.Name = "BancOeuvres"
f.Parent = game.ServerStorage
local m = game.ServerScriptService.Systemes.Oeuvres:Clone()
m.Parent = f
local Config = require(f.Config)
local Eq = require(f.Equilibre)
local O = require(m)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
-- toutes les matières existent
local bad = {}
for _, o in Eq.OEUVRES do
	for item in o[6] do
		if not Config.ITEMS[item] then
			table.insert(bad, o[1] .. ":" .. item)
		end
	end
end
check("matières des chefs-d'œuvre connues (" .. table.concat(bad, ", ") .. ")", #bad == 0)
local prof = { gear = {}, stats = {} }
local bag, skill, inVillage = {}, 60, true
local G = {
	world = { day = 30 },
	Equilibre = Eq,
	Joueurs = { get = function() return prof end, markDirty = function() end, sync = function() end,
		skillRaw = function() return skill end, count = function(_, i) return bag[i] or 0 end,
		take = function(_, i, n) if (bag[i] or 0) < n then return false end bag[i] -= n return true end },
	Quetes = { nearVillage = function() return inVillage and { key = "V" } or nil end },
	Social = { bump = function() end, checkTitles = function() end },
	Interact = { onAction = function() end }, Util = { toast = function() end }, remotes = { Menu = { FireClient = function() end } },
}
O.init(G)
local pl = { UserId = 1 }
skill = 10
check("compétence trop basse : refus", not O.contribute(pl, "comptoir"))
skill = 60
inVillage = false
check("hors du village : refus", not O.contribute(pl, "comptoir"))
inVillage = true
check("rien dans le sac : refus", not O.contribute(pl, "comptoir"))
bag = { gold_ingot = 60, silk = 100, planks = 300 }
local ok1 = O.contribute(pl, "comptoir")
check("apport partiel : pris seulement ce qui manque", ok1 and bag.silk == 40 and bag.gold_ingot == 0 and prof.oeuvres.comptoir.done == nil)
bag = { gold_ingot = 40, pearl = 10 }
local ok2 = O.contribute(pl, "comptoir")
check("achevé : pièce légendaire dans le sac", ok2 and prof.oeuvres.comptoir.done == 30 and #prof.gear == 1 and prof.gear[1].rarity == 5)
check("déjà achevé : pas deux fois", not O.contribute(pl, "comptoir"))
check("état des projets (" .. #O.status(pl) .. ")", #O.status(pl) == #Eq.OEUVRES)
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
