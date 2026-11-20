-- Banc Edit : pont-levis et trappe (Machines.lever / applyMech), vrais modèles du catalogue.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local Config = require(f.Config)
local K = Config.Catalogue
local mod = game.ServerScriptService.Systemes.Machines:Clone()
local M = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local folder = Instance.new("Folder")
folder.Name = "BancMeca"
folder.Parent = workspace
local placed, models = {}, {}
local function put(item, x)
	local info = Config.ITEMS[item]
	local m = K.build(info.place)
	m:PivotTo(CFrame.new(8000 + x, 40, 8000))
	m:SetAttribute("PlacedId", item .. "1")
	m.Parent = folder
	table.insert(models, m)
	local d = { id = item .. "1", item = item, x = 8000 + x, z = 8000, owner = "u9" }
	table.insert(placed, d)
	return d, m
end
local reg = { placedModels = models }
local root = { Position = Vector3.new(8000, 40, 8003) }
local accessOk = true
local G = {
	Config = Config,
	Interact = { onPrompt = function() end },
	Protection = {
		findPlaced = function(id) for _, d in placed do if d.id == id then return d, reg end end end,
		access = function(_, _, fn) if accessOk then fn() end end,
	},
	Util = { root = function() return root end, sfx = function() end },
}
M.init(G)
local bridge, bm = put("drawbridge", 0)
local trap, tm = put("trapdoor", 20)
check("modèles du catalogue construits", bm ~= nil and tm ~= nil)
local function topY(m)
	local hi = -math.huge
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p ~= m.PrimaryPart then
			hi = math.max(hi, p.Position.Y + p.Size.Y / 2)
		end
	end
	return hi - 40
end
local y0 = topY(bm)
M.lever({}, bridge.id)
task.wait(3) -- animation de 1,2 s ; marge pour un PC chargé (ratait à 1,5 s)
check(string.format("pont-levis levé : il se dresse (haut %.1f → %.1f)", y0, topY(bm)), bridge.up == true and topY(bm) > y0 + 3) -- centre du tablier vers 4 studs (pointe vers 8)
M.lever({}, bridge.id)
task.wait(3) -- animation de 1,2 s ; marge pour un PC chargé (ratait à 1,5 s)
check(string.format("pont-levis baissé : revenu à plat (%.1f)", topY(bm)), not bridge.up and math.abs(topY(bm) - y0) < 0.05)
-- trappe : s'ouvre (le dessus libère le passage), se referme
local t0 = topY(tm)
root.Position = Vector3.new(8020, 40, 8002)
M.lever({}, trap.id)
task.wait(3) -- animation de 1,2 s ; marge pour un PC chargé (ratait à 1,5 s)
check("trappe ouverte : panneau relevé", trap.up == true and topY(tm) > t0 + 1)
-- l'état est gardé : un modèle neuf (rechargement de région) est remis tel quel
local fresh = K.build(Config.ITEMS.trapdoor.place)
fresh:PivotTo(CFrame.new(8040, 40, 8000))
fresh.Parent = folder
M.applyMech(fresh, trap, false)
local hiF = -math.huge
for _, p in fresh:GetDescendants() do
	if p:IsA("BasePart") and p ~= fresh.PrimaryPart then
		hiF = math.max(hiF, p.Position.Y + p.Size.Y / 2)
	end
end
check("rechargement : trappe toujours ouverte", hiF - 40 > t0 + 1)
-- refus d'accès (serrure ratée) : rien ne bouge
accessOk = false
M.lever({}, trap.id)
check("accès refusé : état inchangé", trap.up == true)
-- trop loin : rien
accessOk = true
root.Position = Vector3.new(9000, 40, 9000)
M.lever({}, trap.id)
check("trop loin : rien", trap.up == true)

folder:Destroy()
mod:Destroy()
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
