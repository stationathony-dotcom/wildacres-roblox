-- Banc Edit : formes composées de construction (Config.SHAPE_PARTS + makeSubPart).
-- Chaque forme est bâtie loin du monde : elle doit tenir dans sa taille déclarée (± 0,15) et la remplir.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local Config = require(f.Config)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local folder = Instance.new("Model")
folder.Name = "BancFormes"
folder.Parent = workspace
local x = 0
local n = 0
for _, sh in Config.BUILD_SHAPES do
	local compose = Config.SHAPE_PARTS[sh.shape]
	if compose then
		n += 1
		local m = Instance.new("Model")
		m.Name = sh.id
		local base = CFrame.new(9000 + x, 50, 9000)
		x += 12
		local parts = compose(sh.size)
		for _, sp in parts do
			local c = Config.makeSubPart(sp)
			c.Anchored = true
			c.CFrame = base * sp[2]
			c.Parent = m
		end
		m.Parent = folder
		-- boîte englobante dans le repère du monde (coins de chaque pièce)
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, c in m:GetChildren() do
			local h = c.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local w = c.CFrame:PointToWorldSpace(Vector3.new(sx * h.X, sy * h.Y, sz * h.Z))
						lo, hi = lo:Min(w), hi:Max(w)
					end
				end
			end
		end
		local size = hi - lo
		local cf = CFrame.new((lo + hi) / 2)
		local d = (cf.Position - base.Position)
		-- le coin (WedgePart) : sa pente monte vers +Z ; pour le pignon on vérifie que le haut est au milieu
		if sh.shape == "gable" then
			task.wait() -- les pièces tout juste posées ne sont visibles des raycasts qu'à l'image suivante
			local top = workspace:Raycast(base.Position + Vector3.new(0.3, 10, 0), Vector3.new(0, -20, 0))
			local edge = workspace:Raycast(base.Position + Vector3.new(sh.size.X / 2 - 0.2, 10, 0), Vector3.new(0, -20, 0))
			check(string.format("pignon : pointe au milieu (milieu %.1f, bord %.1f)", top and top.Position.Y - base.Position.Y or -99, edge and edge.Position.Y - base.Position.Y or -99),
				top and edge and top.Position.Y > edge.Position.Y + 1)
		end
		local fits = size.X <= sh.size.X + 0.3 and size.Y <= sh.size.Y + 0.3 and size.Z <= sh.size.Z + 0.3
		local fills = size.X >= sh.size.X * 0.7 and size.Y >= sh.size.Y * 0.7
		check(string.format("%s : %d pièces, boîte %.1f×%.1f×%.1f (déclarée %g×%g×%g), centre décalé de %.2f", sh.name, #parts, size.X, size.Y, size.Z,
			sh.size.X, sh.size.Y, sh.size.Z, d.Magnitude), fits and fills and d.Magnitude < 0.6)
	end
end
-- les objets fabriqués existent pour chaque matériau
local made = 0
for _, id in Config.BLOCK_ORDER do
	if string.find(id, "^colimacon_") or string.find(id, "^dome_") or string.find(id, "^creneaux_") then
		made += 1
		assert(Config.ITEMS["blk_" .. id], id)
	end
end
check("objets « blk_ » générés pour les nouvelles formes (" .. made .. ")", made >= 10)
folder:Destroy()
f:Destroy()
return fails .. " échec(s) sur " .. n .. " formes\n" .. table.concat(out, "\n")
