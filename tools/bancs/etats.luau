-- Banc Edit (21/11, passage Codex X19) : états lisibles des machines (NomEtat, EtatMachine) et des coffres
-- (Verrouille) publiés par Systemes/Machines sur les modèles posés. G simulé.
local M = assert(loadstring(game.ServerScriptService.Systemes.Machines.Source, "Machines"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local wetAt = {}
local placed = {}
local models = {}
local G = {
	Config = { CELL = 4 },
	Interact = { onPrompt = function() end, onAction = function() end },
	Util = { isWater = function(x, z) return wetAt[x .. "," .. z] == true end },
	World = { loaded = { r = { state = { placed = placed }, placedModels = models } } },
}
pcall(M.init, G)
local function put(d)
	table.insert(placed, d)
	local m = Instance.new("Model")
	m:SetAttribute("PlacedId", d.id)
	m.Parent = workspace
	table.insert(models, m)
	M.publish(m, d, { placed = placed })
	return m
end
local four = put({ id = "f", item = "furnace", x = 0, z = 0 })
check("four : NomEtat « Four » et un état", four:GetAttribute("NomEtat") == "Four" and four:GetAttribute("EtatMachine") ~= nil)
local roue = put({ id = "w", item = "water_wheel", x = 40, z = 0 })
check("roue au sec : le dit (" .. tostring(roue:GetAttribute("EtatMachine")) .. ")", string.find(roue:GetAttribute("EtatMachine"), "sec", 1, true) ~= nil)
wetAt["44,0"] = true
M.refresh(placed[2])
check("roue au bord de l'eau, sans moulin", string.find(roue:GetAttribute("EtatMachine"), "sans moulin", 1, true) ~= nil)
local moulin = put({ id = "m", item = "windmill", x = 50, z = 4, mill = { wheat = 6, flour = 0 } })
M.refresh(placed[2])
check("roue + moulin à portée : « entraîne le moulin »", string.find(roue:GetAttribute("EtatMachine"), "entraîne", 1, true) ~= nil)
check("moulin : « 6 blé à moudre »", string.find(moulin:GetAttribute("EtatMachine"), "6 blé", 1, true) ~= nil)
placed[3].mill = { wheat = 0, flour = 4 }
M.refresh(placed[3])
check("moulin : « 4 farine prête »", string.find(moulin:GetAttribute("EtatMachine"), "4 farine", 1, true) ~= nil)
local ruche = put({ id = "h", item = "beehive", x = 0, z = 40, hive = 2 })
check("ruche : miel prêt", ruche:GetAttribute("EtatMachine") == "Miel prêt")
local coffre = put({ id = "c", item = "chest", x = 0, z = 60 })
check("coffre sans serrure : Verrouille = false", coffre:GetAttribute("Verrouille") == false and coffre:GetAttribute("NomEtat") == nil)
placed[5].lock = 2
M.refresh(placed[5])
check("serrure posée : Verrouille = true", coffre:GetAttribute("Verrouille") == true)
for _, m in models do
	m:Destroy()
end
return fails .. " échec(s)\n" .. table.concat(out, "\n")
