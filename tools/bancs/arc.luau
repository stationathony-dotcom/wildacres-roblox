-- Banc Edit : tir à l'arc (Combat.shoot / attack avec arc équipé), G simulé, vrai raycast.
local mod = game.ServerScriptService.Systemes.Combat:Clone()
local Combat = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local O = Vector3.new(7000, 50, 7000)
-- restes d'un essai précédent interrompu : ils masqueraient les cibles
for _, old in workspace:GetChildren() do
	if old.Name == "BancArc" then
		old:Destroy()
	end
end
local folder = Instance.new("Folder")
folder.Name = "BancArc"
folder.Parent = workspace
local root = Instance.new("Part")
root.Anchored = true
root.CanQuery = false
root.CFrame = CFrame.lookAt(O, O + Vector3.new(0, 0, -1))
root.Parent = folder
local function enemyAt(pos: Vector3, name: string)
	local m = Instance.new("Model")
	m.Name = name
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = Vector3.new(2, 4, 2)
	p.Position = pos
	p.Parent = m
	m.Parent = folder
	return { id = name, pos = pos, model = m, radius = 1.5 }
end
local near = enemyAt(O + Vector3.new(0, 0, -30), "proche")
local far = enemyAt(O + Vector3.new(0, 0, -70), "loin")
local side = enemyAt(O + Vector3.new(30, 0, 0), "cote")

local hits = {}
local bag = { arrow = 0 }
local toasts = {}
local prof = { equipped = { weapon = { name = "Arc court", power = 3 } } }
local P = { Parent = true, Character = Instance.new("Model") } -- un vrai joueur a toujours un Character (filtre du raycast)
function P:GetAttribute()
	return nil
end
local G = {
	Config = { ITEMS = { sword = { weapon = 2 } }, baseOf = function() return nil end },
	Interact = { onAction = function() end, onPrompt = function() end },
	Util = { root = function() return root end, toast = function(_, t) table.insert(toasts, t) end, sfx = function() end },
	Joueurs = {
		get = function() return prof end,
		take = function(_, i, n) if (bag[i] or 0) < n then return false end bag[i] -= n return true end,
		stats = function() return {} end, skill = function() return 0 end, talent = function() return 0 end,
		addSkillXp = function() end,
	},
	Enemies = { list = { near, far, side }, byId = function() return nil end, hit = function(en) table.insert(hits, en.id) end },
	World = { loaded = {} },
	Animals = { list = {} }, Npcs = { list = {} }, Game = { players = function() return {} end }, Compagnons = { list = {} },
	Props = { swing = function() end },
	remotes = { Fx = { FireAllClients = function() end, FireClient = function() end } },
}
pcall(Combat.init, G)

check("un arc court est une arme à distance", Combat.rangedWeapon(P) ~= nil)
Combat.attack(P, nil, nil)
check("sans flèche : rien, message", #hits == 0 and string.find(toasts[#toasts] or "", "flèches") ~= nil)
bag.arrow = 5
task.wait(1)
Combat.attack(P, nil, nil)
task.wait(0.6)
check("flèche consommée", bag.arrow == 4)
check("touche la cible en face à 30 studs", hits[1] == "proche")
-- un mur entre les deux
local wall = Instance.new("Part")
wall.Anchored = true
wall.Size = Vector3.new(10, 10, 1)
wall.Position = O + Vector3.new(0, 0, -15)
wall.Parent = folder
task.wait(1)
local n0 = #hits
Combat.attack(P, nil, nil)
task.wait(0.6)
check("un mur arrête le tir (pas de touche)", #hits == n0 and bag.arrow == 3)
wall:Destroy()
-- cadence
task.wait(1)
Combat.attack(P, nil, nil)
Combat.attack(P, nil, nil)
task.wait(0.6)
check("cadence : un tir toutes les 0,9 s", bag.arrow == 2)
-- épée en main : corps à corps (pas de flèche)
task.wait(1)
Combat.attack(P, "sword", nil)
check("épée en main : pas de tir", bag.arrow == 2)
-- portée
near.model.Parent = nil
task.wait(1)
n0 = #hits
Combat.attack(P, nil, nil)
task.wait(0.8)
check("hors de portée (70 studs) : pas de touche", #hits == n0)
check("la cible de côté n'est pas visée", not table.find(hits, "cote"))

folder:Destroy()
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
