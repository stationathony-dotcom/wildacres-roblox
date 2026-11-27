-- Banc des œufs de monture (27/11, Equilibre + Montures.incubate / hatch) en mode Edit, faux G.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game.ServerStorage
local C = require(f.Config)
local Ec = require(f.Ecurie)
f:Destroy()
local m = game.ServerScriptService.Systemes.Montures:Clone()
m.Parent = game.ServerStorage
local M = require(m)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local n = 0
for _, list in Ec.OEUFS do
	for _, e in list do
		check("objet " .. Ec.oeufId(e[1]) .. " (usage « oeuf »)", C.ITEMS[Ec.oeufId(e[1])] ~= nil and C.ITEMS[Ec.oeufId(e[1])].use == "cat_oeuf")
		n += 1
	end
end
local prof = { montures = { learned = {} } }
local G = { world = { day = 5 }, Config = C, Joueurs = { get = function() return prof end, markDirty = function() end, sync = function() end },
	Util = { toast = function() end, root = function() return nil end }, Game = { players = function() return {} end },
	Interact = { onAction = function() end, onPrompt = function() end }, remotes = { Menu = { FireClient = function() end } },
	Social = { collect = function() end }, Enemies = { KINDS = {} } }
pcall(M.init, G)
local P = { UserId = 1 }
function P:GetAttribute() end
function P:SetAttribute() end
check("œuf mis à couver", M.incubate(P, "dragonnet") == true)
check("pas deux fois le même", M.incubate(P, "dragonnet") == false)
G.world.day = 7
M.hatch(P)
check("2 jours : pas encore éclos", prof.montures.learned.dragonnet == nil)
G.world.day = 8
M.hatch(P)
check("3 jours : le dragonnet rejoint la collection", prof.montures.learned.dragonnet ~= nil)
m:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
