-- Banc de Systemes/Moissons en mode Edit (sans Play) : un champ de blé posé, on récolte au clic,
-- deux coups à la main (un avec une houe), le blé « tombe au sol » (auSol simulé), la touffe disparaît, repousse au bout de 3 jours,
-- refus hors de portée / deux fois / id inconnu.
local SS = game:GetService("ServerStorage")
local f = Instance.new("Folder")
f.Name = "BancMoissons"
f.Parent = SS
local mod = game.ServerScriptService.Systemes.Moissons:Clone()
mod.Parent = f
local M = require(mod)
local res, ok = {}, true
local function check(name, cond)
	table.insert(res, (cond and "ok  " or "ÉCHEC ") .. name)
	ok = ok and cond
end
local got, xp, notes = {}, 0, 0
local rootPos = Vector3.new(0, 3, 0)
local PL = { Name = "Banc", UserId = 1 }
local actions = {}
local G = {
	world = { day = 10 },
	Interact = { onAction = function(k, fn) actions[k] = fn end },
	Util = {
		root = function() return { Position = rootPos } end,
		auSol = function(_, pos, _, fn) check("tombe au sol près de la touffe", typeof(pos) == "Vector3") fn() end,
	},
	Joueurs = {
		add = function(_, item, n) got[item] = (got[item] or 0) + n end,
		addSkillXp = function(_, s, n) if s == "agriculture" then xp += n end end,
	},
	Quetes = { note = function(_, kind, key) if kind == "recolter" and key == "wheat" then notes += 1 end end },
}
M.init(G)
check("action recolter_clic branchée", actions.recolter_clic ~= nil)
local champ = SS.Modeles.Champ_Ble:Clone()
champ:PivotTo(CFrame.new(0, 0, 0))
champ.Parent = f
local reg = { key = "1,0", state = {}, houses = { ["v:Champ_Ble"] = { model = champ } } }
M.onRegionLoad(reg)
local touffes = {}
for _, t in champ:GetChildren() do
	if t.Name == "Touffe" then
		table.insert(touffes, t)
	end
end
check("touffes trouvées (" .. #touffes .. ")", #touffes >= 60)
local t1 = touffes[1]
local p1 = t1:FindFirstChildWhichIsA("BasePart")
local id = p1:GetAttribute("RecolteId")
check("pièces marquées RecolteId", type(id) == "string")
check("tag Recoltable", game:GetService("CollectionService"):HasTag(p1, "Recoltable"))
rootPos = t1:GetPivot().Position + Vector3.new(30, 0, 0)
actions.recolter_clic(PL, { id = id })
check("hors de portée : refusé", (got.wheat or 0) == 0 and p1.Transparency == 0)
rootPos = t1:GetPivot().Position + Vector3.new(4, 0, 0)
task.wait(0.3)
actions.recolter_clic(PL, { id = id })
check("1er coup à la main : pas encore (résistance 2)", (got.wheat or 0) == 0 and p1.Transparency == 0)
actions.recolter_clic(PL, { id = id })
check("2e clic trop rapproché : ignoré (cadence)", (got.wheat or 0) == 0)
task.wait(0.3)
actions.recolter_clic(PL, { id = id })
check("récolte : blé gagné", (got.wheat or 0) >= 1)
check("touffe cachée et plus visable", p1.Transparency == 1 and p1.CanQuery == false)
check("XP agriculture + note de quête", xp == 1 and notes == 1)
local before = got.wheat
actions.recolter_clic(PL, { id = id })
check("deux fois : refusé", got.wheat == before)
actions.recolter_clic(PL, { id = "n'importe quoi" })
check("id inconnu : ignoré", got.wheat == before)
G.world.day = 12
M.newDay()
check("pas repoussée au bout de 2 jours", p1.Transparency == 1)
G.world.day = 13
M.newDay()
check("repoussée au bout de 3 jours", p1.Transparency == 0 and p1.CanQuery == true)
-- avec une houe : un seul coup suffit
G.Joueurs.bestTool = function(_, t) return t == "hoe" and "hoe" or nil, t == "hoe" and 1 or 0 end
local id2 = touffes[2]:FindFirstChildWhichIsA("BasePart"):GetAttribute("RecolteId")
rootPos = touffes[2]:GetPivot().Position
local w0 = got.wheat
task.wait(0.3)
actions.recolter_clic(PL, { id = id2 })
check("avec une houe : un seul coup", got.wheat > w0)
-- rechargement : l'état est gardé
G.world.day = 20
rootPos = t1:GetPivot().Position
task.wait(0.3)
actions.recolter_clic(PL, { id = id })
M.onRegionUnload(reg)
local champ2 = SS.Modeles.Champ_Ble:Clone()
champ2.Parent = f
reg.houses["v:Champ_Ble"].model = champ2
M.onRegionLoad(reg)
local q = champ2:FindFirstChild("Touffe"):FindFirstChildWhichIsA("BasePart")
check("rechargée : toujours récoltée", q.Transparency == 1)
-- décor naturel du plan (règle 6) : roseaux et nénuphars du dossier Decor, le modèle entier = une touffe
local regD = { key = "2,0", state = {}, houses = {}, folder = Instance.new("Folder") }
regD.folder.Parent = f
local decoF = Instance.new("Folder")
decoF.Name = "Decor"
decoF.Parent = regD.folder
local ros = SS.Modeles.Roseaux:Clone()
ros:SetAttribute("DecoIdx", 7)
ros:PivotTo(CFrame.new(100, 0, 0))
ros.Parent = decoF
local nen = SS.Modeles.Nenuphar:Clone()
nen:SetAttribute("DecoIdx", 8)
nen:PivotTo(CFrame.new(104, 0, 0))
nen.Parent = decoF
local esc = Instance.new("Model")
esc.Name = "Escalier"
esc.Parent = decoF
M.onRegionLoad(regD)
local rp = ros:FindFirstChildWhichIsA("BasePart")
local rid = rp:GetAttribute("RecolteId")
check("roseaux : marqués récoltables", rid == "2,0|d|7" and game:GetService("CollectionService"):HasTag(rp, "Recoltable"))
check("escalier du décor : pas récoltable", esc:GetAttribute("RecolteId") == nil)
rootPos = Vector3.new(101, 3, 0)
local r0 = got.reeds or 0
task.wait(0.3)
actions.recolter_clic(PL, { id = rid })
check("roseaux : un clic à la main → roseaux au sol", (got.reeds or 0) > r0 and rp.Transparency == 1)
check("roseaux : état gardé sous la clé du décor", regD.state.moisson["d|7"] == G.world.day)
local fl0 = got.flower or 0
task.wait(0.3)
actions.recolter_clic(PL, { id = nen:FindFirstChildWhichIsA("BasePart"):GetAttribute("RecolteId") })
check("nénuphar : donne une fleur", (got.flower or 0) == fl0 + 1)
f:Destroy()
return (ok and "OK " or "ÉCHEC ") .. #res .. " vérifications\n" .. table.concat(res, "\n")
