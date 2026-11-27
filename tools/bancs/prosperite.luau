-- Banc de la prospérité des villages (27/11, Shop.prosperity / trade / newDay) en mode Edit, faux G.
local m = game.ServerScriptService.Systemes.Shop:Clone()
m.Parent = game.ServerStorage
local S = require(m)
local G = { world = { extra = {} }, Reputation = { villageAt = function() return { key = "V1" } end },
	Config = require(game.ReplicatedStorage.Shared.Config), Interact = { onAction = function() end, onPrompt = function() end } }
pcall(S.init, G)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local e = { root = { Position = Vector3.zero } }
check("village jamais visité : ordinaire, prix normaux", select(3, S.prosperity("V1")) == 1)
S.trade(e, 100)
check("un petit achat : toujours ordinaire", select(2, S.prosperity("V1")) == "ordinaire")
S.trade(e, 5000)
check("5 100 or échangés : prospère (+5 %)", select(3, S.prosperity("V1")) == 1.05)
S.trade(e, 10000)
check("15 100 or : florissant (+10 %)", select(3, S.prosperity("V1")) == 1.1)
for _ = 1, 40 do
	S.newDay()
end
check("40 jours sans commerce : en déclin (−5 %)", select(3, S.prosperity("V1")) == 0.95)
for _ = 1, 40 do
	S.newDay()
end
check("80 jours : oublié, de nouveau ordinaire", select(2, S.prosperity("V1")) == "ordinaire")
m:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
