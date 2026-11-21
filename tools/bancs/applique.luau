-- Banc Edit (21/11, passage Codex X21) : lanterne murale « wall_lantern » — recette et prix (Equilibre),
-- pose contre un mur (Shop.place, couche « applique », potence tournée vers le joueur), lumière de nuit.
-- G simulé ; Config réelle lue sur un CLONE de Shared (cache de require du MCP).
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end
local shared = RS.Shared:Clone()
shared.Parent = nil
local Config = require(shared.Config)
local S = assert(loadstring(game.ServerScriptService.Systemes.Shop.Source, "Shop"))()

local info = Config.ITEMS.wall_lantern
check("objet wall_lantern déclaré, prix " .. tostring(info and info.price), info ~= nil and (info.price or 0) > 0)
check("posé sur le bord d'une case (grid edge, wallMount)", info and info.grid == "edge" and info.wallMount == true and info.place == "Cat_wall_lantern")
local rec
for _, r in Config.RECIPES do
	if r.item == "wall_lantern" then
		rec = r
	end
end
check("recette à l'établi, matières connues", rec ~= nil and rec.station == "bench" and (function()
	for id in rec.needs do
		if not Config.ITEMS[id] then
			return false
		end
	end
	return true
end)())
check("modèle Cat_wall_lantern connu du catalogue", Config.Catalogue.MODELS.Cat_wall_lantern ~= nil)

-- couches : une applique ne gêne pas le mur du même bord
check("couche « applique » distincte du mur", S.slotOf ~= nil)

-- pose : joueur au centre d'une case, regarde vers un bord
local bag = { wall_lantern = 3 }
local sons
local built = {}
local reg = { state = { placed = {} }, placedFolder = Instance.new("Folder") }
local root = { Position = Vector3.new(2, 5, 2), CFrame = CFrame.lookAt(Vector3.new(2, 5, 2), Vector3.new(2, 5, 10)) }
local G = {
	Config = Config,
	Interact = { onAction = function() end, onPrompt = function() end },
	Joueurs = { has = function(_, i) return (bag[i] or 0) > 0 end, take = function(_, i, n) bag[i] -= n return true end, sync = function() end },
	Util = { root = function() return root end, isWater = function() return false end, toast = function() end, newId = function() return "pl" .. (#reg.state.placed + 1) end,
		pid = function() return "u1" end, playerOf = function() return nil end, prompt = function() end, sfx = function(n) sons = (sons or "") .. n .. " " end },
	World = { regionAt = function() return reg end, loaded = { r = reg }, buildDeco = function(d, parent)
		local m = Config.Catalogue.build(d.model)
		if not m then
			return nil
		end
		m:PivotTo(CFrame.new(d.x, 0, d.z) * CFrame.Angles(0, math.rad(d.yaw or 0), 0))
		m.Parent = parent
		table.insert(built, { m = m, d = d })
		return m
	end },
	Parcelles = { canBuild = function() return true end, at = function() return nil end },
	Clock = { seasonize = function() end },
	Machines = {},
}
pcall(S.init, G)
local P = { UserId = 1, DisplayName = "Alix" }
-- mur déjà posé sur le bord +Z de la case (0..4)
table.insert(reg.state.placed, { id = "w", item = "wall", x = 2, z = 4, yaw = 0 })
S.place(P, "wall_lantern")
local d = reg.state.placed[#reg.state.placed]
check("posée malgré le mur du même bord", d.item == "wall_lantern" and bag.wall_lantern == 2)
check("décollée du mur vers le joueur (z = 3,7)", d and math.abs(d.z - 3.7) < 1e-6 and d.x == 2)
local b = built[#built]
local flamme = b and b.m:FindFirstChild("Flamme", true)
local arm = flamme and (flamme.Position - b.m:GetPivot().Position)
check("potence tournée vers le joueur (flamme côté -Z)", arm ~= nil and arm.Z < -0.3)
check("flamme marquée LumiereNuit (allumée la nuit, fuie des ombres)", flamme ~= nil and CS:HasTag(flamme, "LumiereNuit"))
S.place(P, "wall_lantern")
check("une seule applique par face de mur", bag.wall_lantern == 2)
-- l'autre face du même mur : depuis la case de derrière, regard vers -Z
root.Position = Vector3.new(2, 5, 6)
root.CFrame = CFrame.lookAt(root.Position, Vector3.new(2, 5, -10))
S.place(P, "wall_lantern")
d = reg.state.placed[#reg.state.placed]
b = built[#built]
flamme = b and b.m:FindFirstChild("Flamme", true)
arm = flamme and (flamme.Position - b.m:GetPivot().Position)
check("autre face : posée (z = 4,3), potence vers +Z", bag.wall_lantern == 1 and math.abs(d.z - 4.3) < 1e-6 and arm and arm.Z > 0.3)
-- bord en X
root.Position = Vector3.new(2, 5, 2)
root.CFrame = CFrame.lookAt(root.Position, Vector3.new(10, 5, 2))
S.place(P, "wall_lantern")
d = reg.state.placed[#reg.state.placed]
b = built[#built]
flamme = b and b.m:FindFirstChild("Flamme", true)
arm = flamme and (flamme.Position - b.m:GetPivot().Position)
check("bord +X : x = 3,7, potence vers -X", bag.wall_lantern == 0 and math.abs(d.x - 3.7) < 1e-6 and arm and arm.X < -0.3)
check("son « pose » à chaque pose réussie (X24)", sons == "pose pose pose ")

reg.placedFolder:Destroy()
shared:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
