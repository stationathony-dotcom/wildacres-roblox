-- Banc Edit : villes fondées par les joueurs (Systemes/Villes), G simulé ; habitants : appel vérifié.
local mod = game.ServerScriptService.Systemes.Villes:Clone()
local V = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local bag = { charter = 1 }
local root = { Position = Vector3.new(1000, 10, 1000) }
local rs = { placed = {} }
local reg = { key = "5,5" }
local spawned = {}
local G = {
	world = { day = 4, extra = {}, regions = { ["5,5"] = rs } },
	Quetes = { villages = function() return { { key = "0,0", name = "Valdor", x = 0, z = 0 } } end },
	Joueurs = {
		count = function(_, i) return bag[i] or 0 end,
		take = function(_, i, n) if (bag[i] or 0) < n then return false end bag[i] -= n return true end,
		sync = function() end,
	},
	Util = { root = function() return root end, isWater = function() return false end, pid = function() return "u1" end, newId = function(p) return p .. "1" end },
	Social = { bump = function() end },
	World = { loaded = { reg }, regionAt = function() return reg end },
	Metiers = { spawnTown = function(r, id, v, beds) table.insert(spawned, #beds) end },
}
V.init(G)
V.filter = function(_, t) return t end
local P = { DisplayName = "Fondateur" }
local ok, msg = V.found(P, "Bois-Joli")
check("ville fondée : " .. msg, ok == true and bag.charter == 0)
local f = game.ReplicatedStorage:FindFirstChild("Villes")
check("publiée au client (nom, position)", f and #f:GetChildren() == 1 and f:GetChildren()[1]:GetAttribute("Name") == "Bois-Joli")
check("position dans la ville reconnue", V.at(Vector3.new(1030, 0, 1010)) ~= nil and V.at(Vector3.new(1200, 0, 1000)) == nil)
bag.charter = 1
local ok2, msg2 = V.found(P, "Autreville")
check("trop près d'une autre ville : refus (" .. msg2 .. ")", ok2 == false and bag.charter == 1)
root.Position = Vector3.new(100, 10, 100)
local ok3 = V.found(P, "Collée")
check("trop près d'un village : refus", ok3 == false)
root.Position = Vector3.new(3000, 10, 3000)
check("nom trop court : refus", (V.found(P, "ab")) == false)
bag.charter = 0
check("sans charte : refus", (V.found(P, "Nouvelleville")) == false)
-- habitants : un par lit dans la ville
table.insert(rs.placed, { id = "b1", item = "bed", x = 1010, z = 1000 })
table.insert(rs.placed, { id = "b2", item = "bed", x = 1020, z = 990 })
table.insert(rs.placed, { id = "b3", item = "bed", x = 1500, z = 1500 }) -- hors de la ville
V.newDay()
check("lits de la ville comptés (2, pas celui du dehors)", spawned[#spawned] == 2)
check("/villes décrit la ville", V.describe()[1]:find("Bois%-Joli") ~= nil)
-- conseil de ville (27/11) : enregistré auprès de Politique avec sa région, borne avec l'invite « conseil »
do
	local reg2 = { key = "5,5", folder = Instance.new("Folder") }
	local pol, prompts = {}, {}
	G.Politique = { register = function(key, name) pol[key] = pol[key] or { name = name } end, get = function(key) return pol[key] end }
	G.Util.clone = function() local m = Instance.new("Model") local p = Instance.new("Part") p.Parent = m m.PrimaryPart = p return m end
	G.Util.groundY = function() return 0 end
	G.Util.prompt = function(anchor, action, text) local pr = Instance.new("ProximityPrompt") pr.Name = action pr.ObjectText = text pr.Parent = anchor table.insert(prompts, pr) return pr end
	G.World.place = function(m, x, y, z, yaw, parent) m:PivotTo(CFrame.new(x, y, z)) m.Parent = parent end
	local id, tv
	for k, t in G.world.extra.villes or {} do id, tv = k, t end
	V.council(reg2, id, tv)
	V.council(reg2, id, tv)
	local p = pol["ville_" .. tostring(id)]
	check("conseil de ville : enregistré, région notée", p ~= nil and p.name == "Bois-Joli" and p.region == "5,5")
	check("conseil de ville : une seule borne, invite « conseil » vers la ville", #prompts == 1 and prompts[1]:GetAttribute("Village") == "ville_" .. tostring(id))
	reg2.folder:Destroy()
end
f:Destroy()
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
