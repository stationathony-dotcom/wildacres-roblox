-- Banc des royaumes (27/11, Systemes/Politique) en mode Edit, faux G :
-- allégeance d'un conseil à un autre, tribut sur les taxes, nom du royaume, refus des boucles et des non-maires.
local mod = game.ServerScriptService.Systemes.Politique:Clone()
mod.Parent = game.ServerStorage
local P = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local actions, sent = {}, nil
local root = { Position = Vector3.new(0, 5, 0) }
local G = {
	world = { day = 3, extra = {}, players = {} },
	Config = {},
	Interact = { onPrompt = function() end, onAction = function(n, fn) actions[n] = fn end },
	Util = { root = function() return root end, toast = function() end },
	remotes = { Menu = { FireClient = function(_, _, d) sent = d end } },
	Mondes = { saveSoon = function() end },
	Parcelles = { plotsOf = function() return {} end },
	Joueurs = { get = function() return {} end },
	Economie = { record = function() end },
	Game = { players = function() return {} end },
}
P.init(G)
P.register("A", "Valdor", Vector3.new(0, 0, 0))
P.register("B", "Brumeval", Vector3.new(0, 0, 0))
P.register("C", "Rocneige", Vector3.new(0, 0, 0))
local VA, VB, VC = P.get("A"), P.get("B"), P.get("C")
VA.maire, VA.maireName = "1", "Alix"
VB.maire, VB.maireName = "2", "Bran"
VC.maire, VC.maireName = "3", "Cyr"
local p1, p2, p3 = { UserId = 1 }, { UserId = 2 }, { UserId = 3 }

actions.pol_allegeance(p2, { v = "A", to = "B" })
check("un non-maire ne peut pas engager le conseil", VA.suzerain == nil)
actions.pol_allegeance(p1, { v = "A", to = "B" })
check("Valdor prête allégeance à Brumeval", VA.suzerain == "B")
actions.pol_allegeance(p2, { v = "B", to = "C" })
check("Brumeval prête allégeance à Rocneige", VB.suzerain == "C")
check("royaume de Valdor = Rocneige (sommet de la chaîne)", P.realmOf("A") == "C")
actions.pol_allegeance(p3, { v = "C", to = "A" })
check("boucle refusée (Rocneige ne peut pas dépendre de Valdor)", VC.suzerain == nil)
local b0, a0 = VB.tresor or 0, VA.tresor or 0
P.credit("A", 100, "taxe")
check("tribut : 10 % des taxes de Valdor à Brumeval", (VB.tresor or 0) - b0 == 10 and (VA.tresor or 0) - a0 == 90)
VB.maire = nil
local b1 = VB.tresor
P.credit("A", 100, "taxe")
check("suzerain sans maire : pas de tribut", VB.tresor == b1)
VB.maire = "2"
actions.pol_allegeance(p1, { v = "A" })
check("allégeance rompue", VA.suzerain == nil and P.realmOf("A") == nil)
check("le conseil montre le royaume", sent and sent.royaume and type(sent.royaume.choix) == "table")
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
