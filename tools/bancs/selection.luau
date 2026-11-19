-- Banc Edit : sélection des semences (Farm.selectionLevel / noteSelection) et carnet (Livres.cultures).
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local Config = require(f.Config)
local modF = game.ServerScriptService.Systemes.Farm:Clone()
local F = require(modF)
local modL = game.ServerScriptService.Systemes.Livres:Clone()
local L = require(modL)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local prof = {}
local toasts = {}
local G = {
	Config = Config,
	Joueurs = { get = function() return prof end },
	Util = { toast = function(_, t) table.insert(toasts, t) end },
	Interact = { onPrompt = function() end, onAction = function() end },
}
G.Farm = F
pcall(F.init, G)
L.init(G)
local sent
L.send = function(_, d) sent = d end
local lv = {}
for _, n in { 0, 9, 10, 39, 40, 90, 160, 250, 9999 } do
	table.insert(lv, F.selectionLevel(n))
end
check("paliers 10 / 40 / 90 / 160 / 250, plafond 5 : " .. table.concat(lv, ","), table.concat(lv, ",") == "0,0,1,1,2,3,4,5,5")
for _ = 1, 40 do
	F.noteSelection({}, "wheat")
end
check("40 récoltes de blé : niveau 2", F.selectionLevel(prof.selection.wheat) == 2)
check("deux passages de niveau annoncés", #toasts == 2 and toasts[2]:find("niveau 2") ~= nil)
L.cultures({})
check("carnet : la culture et son niveau", sent and #sent.lignes == 1 and sent.lignes[1].t:find("sélection 2") ~= nil)
modF:Destroy()
modL:Destroy()
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
