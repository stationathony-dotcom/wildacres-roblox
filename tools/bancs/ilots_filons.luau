-- Banc des filons rares des îlots (27/11, Systemes/Ilots.mine) en mode Edit, faux G.
local m = game.ServerScriptService.Systemes.Ilots:Clone()
m.Parent = game.ServerStorage
local I = require(m)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local bag, tier = {}, 2
local G = { world = { day = 10, extra = {}, seed = 1 }, Config = require(game.ReplicatedStorage.Shared.Config),
	Joueurs = { bestTool = function() return "x", tier end, add = function(_, i, n) bag[i] = (bag[i] or 0) + n end, addSkillXp = function() end, sync = function() end },
	Mondes = { saveSoon = function() end }, Interact = { onPrompt = function() end }, Util = { toast = function() end } }
pcall(I.init, G)
local miss = {}
for _, v in I.VEINS do
	if not G.Config.ITEMS[v[1]] then
		table.insert(miss, v[1])
	end
end
check("5 filons, matières connues", #miss == 0)
check("pioche de cuivre : trop dur", not I.mine({}, "ilot1"))
tier = 3
check("pioche de fer : minée", I.mine({}, "ilot1") and (bag.meteorite or 0) >= 1)
check("aussitôt : épuisé", not I.mine({}, "ilot1"))
G.world.day = 15
check("5 jours après : regarni", I.mine({}, "ilot1"))
m:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
