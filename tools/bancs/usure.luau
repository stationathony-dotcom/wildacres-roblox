-- Banc de l'usure des outils (Joueurs.wearTool, 18/11) en mode Edit, G simulé :
-- une hache de pierre tient 150 coups puis casse (un exemplaire en moins), l'avertissement tombe à
-- 10 %, l'attribut « Usure_axe » suit (barre sous l'icône), le fer dure plus longtemps, et la
-- 2e hache repart neuve.
local SS = game:GetService("ServerStorage")
local f = Instance.new("Folder")
f.Name = "BancUsure"
f.Parent = SS
local sh = game.ReplicatedStorage.Shared:Clone()
sh.Parent = f
local jm = game.ServerScriptService.Systemes.Joueurs:Clone()
jm.Parent = f
local J = require(jm)
local Config = require(sh.Config)
local res, ok = {}, true
local function check(name, cond)
	table.insert(res, (cond and "ok  " or "ÉCHEC ") .. name)
	ok = ok and cond
end
local toasts = {}
local G = { Config = Config, Util = { toast = function(_, t) table.insert(toasts, t) end } }
pcall(J.init, G)
J.sync = function() end
local PL = Instance.new("Folder") -- tient lieu de joueur (attributs)
PL.Parent = f
J.profiles[PL] = { inv = { axe = 2, pickaxe_fe = 1 }, wear = {}, skills = {}, stats = {} }
for _ = 1, 134 do
	J.wearTool(PL, "axe")
end
check("hache de pierre après 134 coups : intacte", J.profiles[PL].inv.axe == 2)
J.wearTool(PL, "axe")
check("avertissement à 10 % (15 coups)", string.find(toasts[#toasts] or "", "presque usée") ~= nil)
local u = PL:GetAttribute("Usure_axe") or 0
check(string.format("attribut d'usure suivi (%.2f)", u), u > 0.85 and u < 0.95)
for _ = 1, 15 do
	J.wearTool(PL, "axe")
end
check("150 coups : une hache brisée", J.profiles[PL].inv.axe == 1 and string.find(toasts[#toasts] or "", "brisée") ~= nil)
check("la 2e hache repart neuve", (PL:GetAttribute("Usure_axe") or 1) == 0)
for _ = 1, 600 do
	J.wearTool(PL, "pickaxe")
end
check("pioche de fer : tient 600 coups", (J.profiles[PL].inv.pickaxe_fe or 0) == 1)
for _ = 1, 100 do
	J.wearTool(PL, "pickaxe")
end
check("pioche de fer : brisée à 700", (J.profiles[PL].inv.pickaxe_fe or 0) == 0)
J.wearTool(PL, "shovel")
check("sans outil : rien ne se passe", true)
f:Destroy()
return (ok and "OK " or "ÉCHEC ") .. #res .. " vérifications\n" .. table.concat(res, "\n")
