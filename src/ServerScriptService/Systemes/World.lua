-- Monde : charge / décharge les régions autour des joueurs (terrain Roblox + modèles),
-- sans figer le serveur (travail étalé sur plusieurs images). L'état de chaque région
-- (récolté, planté, ouvert…) est gardé dans G.world.regions et réappliqué au retour.

local Players = game:GetService("Players")

local World = {}
local G
local Config
local CELL, REGION
local Mat = Enum.Material

World.loaded = {} -- clé -> région chargée
local queue = {} -- régions à charger (clés)
local queued = {}
local busy = false

function World.init(g)
	G = g
	Config = G.Config
	CELL, REGION = Config.CELL, Config.REGION
	local f = workspace:FindFirstChild("Monde") or Instance.new("Folder")
	f.Name = "Monde"
	f.Parent = workspace
	World.folder = f
end

function World.regionState(key: string)
	local regions = G.world.regions
	local rs = regions[key]
	if not rs then
		rs = { removed = {}, props = {}, plots = {}, tilled = {}, chests = {}, animals = {}, myAnimals = {}, horses = {}, enemies = {}, placed = {}, graves = {}, terra = {} }
		regions[key] = rs
	end
	for _, k in { "removed", "props", "plots", "tilled", "chests", "animals", "myAnimals", "horses", "enemies", "placed", "graves", "terra" } do
		rs[k] = rs[k] or {}
	end
	return rs
end

-- ----------------------------------------------------------------- Terrain

local function writeTerrain(plan)
	local idx = G.WG.idx
	local H, mat, water = plan.H, plan.mat, plan.water
	local ny = math.floor((Config.Y_MAX - Config.Y_MIN) / 4)
	local region = Region3.new(
		Vector3.new(plan.x0 * CELL, Config.Y_MIN, plan.z0 * CELL),
		Vector3.new((plan.x0 + REGION) * CELL, Config.Y_MIN + ny * 4, (plan.z0 + REGION) * CELL)
	)
	local mats, occs = table.create(REGION), table.create(REGION)
	for x = 1, REGION do
		local mx, ox = table.create(ny), table.create(ny)
		for y = 1, ny do
			mx[y] = table.create(REGION, Mat.Air)
			ox[y] = table.create(REGION, 0)
		end
		mats[x], occs[x] = mx, ox
	end
	for lz = 0, REGION - 1 do
		for lx = 0, REGION - 1 do
			local i = idx(lx, lz)
			local h = H[i]
			local top = mat[i]
			local wet = water[i]
			local minN = math.min(H[idx(lx + 1, lz)], H[idx(lx - 1, lz)], H[idx(lx, lz + 1)], H[idx(lx, lz - 1)])
			local cliff = (h - minN) > 5
			local mx, ox = mats[lx + 1], occs[lx + 1]
			for k = 1, ny do
				local yb = Config.Y_MIN + (k - 1) * 4
				local yt = yb + 4
				local m, o = Mat.Air, 0
				if yt <= h then
					o = 1
					if yt > h - 4 then
						m = cliff and (top == Mat.Grass or top == Mat.LeafyGrass) and top or top
					elseif cliff and yb >= minN - 4 then
						m = plan.cliff or Mat.Rock
					else
						m = (top == Mat.Sand) and Mat.Sand or Mat.Ground
					end
				elseif yb < h then
					m = top
					o = math.max(0.05, (h - yb) / 4)
				elseif wet and yt <= Config.WATER_Y then
					m = Mat.Water
					o = 1
				end
				mx[k][lz + 1] = m
				ox[k][lz + 1] = o
			end
		end
	end
	workspace.Terrain:WriteVoxels(region, 4, mats, occs)
end

local function clearTerrain(rx: number, rz: number)
	local ny = math.floor((Config.Y_MAX - Config.Y_MIN) / 4)
	local region = Region3.new(
		Vector3.new(rx * REGION * CELL, Config.Y_MIN, rz * REGION * CELL),
		Vector3.new((rx + 1) * REGION * CELL, Config.Y_MIN + ny * 4, (rz + 1) * REGION * CELL)
	)
	workspace.Terrain:FillRegion(region, 4, Mat.Air)
end

-- ----------------------------------------------------------------- Constructions

local function place(model: Model, x: number, y: number, z: number, yaw: number, parent: Instance)
	model:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
	model.Parent = parent
	return model
end
World.place = place

local function buildStairs(st, parent: Instance)
	local m = Instance.new("Model")
	m.Name = "Escalier"
	local rise = st.yhigh - st.ylow
	local n = math.max(2, math.ceil(rise / 1.5))
	local run = 16 / n
	local dir = Vector3.new(st.dx, 0, st.dz)
	local line = Vector3.new(st.x, 0, st.z)
	local bottom = st.ylow - 3
	for i = 1, n do
		local top = st.ylow + rise * i / n
		local dist = (n - i + 0.5) * run
		local c = line - dir * dist
		local p = Instance.new("Part")
		p.Name = "Marche"
		p.Anchored = true
		p.Size = Vector3.new(6, top - bottom, run)
		p.CFrame = CFrame.lookAt(Vector3.new(c.X, (top + bottom) / 2, c.Z), Vector3.new(c.X, (top + bottom) / 2, c.Z) + dir)
		p.Material = Mat.WoodPlanks
		p.Color = (i % 2 == 0) and Color3.fromRGB(150, 108, 70) or Color3.fromRGB(136, 96, 62)
		p.TopSurface = Enum.SurfaceType.Smooth
		p.Parent = m
	end
	-- rampes
	for _, s in { -1, 1 } do
		local perp = Vector3.new(-st.dz, 0, st.dx) * s * 3.2
		local a = line - dir * 16 + perp + Vector3.new(0, st.ylow + 3, 0)
		local b = line + perp + Vector3.new(0, st.yhigh + 3, 0)
		local rail = Instance.new("Part")
		rail.Name = "Rampe"
		rail.Anchored = true
		rail.Size = Vector3.new(0.4, 0.4, (b - a).Magnitude)
		rail.CFrame = CFrame.lookAt((a + b) / 2, b)
		rail.Material = Mat.Wood
		rail.Color = Color3.fromRGB(100, 70, 45)
		rail.Parent = m
		for k = 0, 2 do
			local t = k / 2
			local pt = a:Lerp(b, t)
			local post = Instance.new("Part")
			post.Name = "Poteau"
			post.Anchored = true
			post.Size = Vector3.new(0.4, 3, 0.4)
			post.CFrame = CFrame.new(pt - Vector3.new(0, 1.5, 0))
			post.Material = Mat.Wood
			post.Color = Color3.fromRGB(100, 70, 45)
			post.Parent = m
		end
	end
	m.Parent = parent
end

local function buildBridge(br, parent: Instance)
	local m = Instance.new("Model")
	m.Name = "Pont"
	local a = Vector3.new(br.ax, 0, br.az)
	local b = Vector3.new(br.bx, 0, br.bz)
	local ya = math.max(1, G.Util.groundY(br.ax, br.az))
	local yb = math.max(1, G.Util.groundY(br.bx, br.bz))
	local deck = math.max(ya, yb, 1.6) + 1
	local dir = (b - a).Unit
	local len = (b - a).Magnitude
	local perp = Vector3.new(-dir.Z, 0, dir.X)
	local function part(name, size, cf, color, material, collide)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		p.CanCollide = collide ~= false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local planks = math.floor(len / 1.2)
	for i = 0, planks do
		local pos = a + dir * (i * len / planks)
		local tint = 120 + (i * 37 % 30)
		-- lookAt vers le côté : l'axe Z de la planche est EN TRAVERS du pont (9 studs), X le long (1,15)
		part("Planche", Vector3.new(1.15, 0.5, 9), CFrame.lookAt(Vector3.new(pos.X, deck - 0.25, pos.Z), Vector3.new(pos.X, deck - 0.25, pos.Z) + perp),
			Color3.fromRGB(tint + 20, tint - 15, tint - 50), Mat.WoodPlanks)
	end
	local mid = (a + b) / 2
	for _, s in { -1, 1 } do
		local side = perp * s * 4.3
		part("Poutre", Vector3.new(0.6, 0.6, len), CFrame.lookAt(Vector3.new(mid.X, deck - 0.7, mid.Z) + side, Vector3.new(b.X, deck - 0.7, b.Z) + side), Color3.fromRGB(90, 62, 40), Mat.Wood)
		part("Rambarde", Vector3.new(0.35, 0.35, len), CFrame.lookAt(Vector3.new(mid.X, deck + 2.6, mid.Z) + side, Vector3.new(b.X, deck + 2.6, b.Z) + side), Color3.fromRGB(110, 76, 48), Mat.Wood)
		-- barrière invisible : on ne tombe pas du pont
		part("Garde", Vector3.new(0.4, 6, len), CFrame.lookAt(Vector3.new(mid.X, deck + 3, mid.Z) + side, Vector3.new(b.X, deck + 3, b.Z) + side), Color3.new(1, 1, 1), Mat.SmoothPlastic).Transparency = 1
		local posts = math.max(2, math.floor(len / 5))
		for k = 0, posts do
			local p = a + dir * (k * len / posts) + side
			part("Poteau", Vector3.new(0.5, 3, 0.5), CFrame.new(p.X, deck + 1.3, p.Z), Color3.fromRGB(100, 70, 45), Mat.Wood)
			if k > 0 and k < posts then
				part("Pilier", Vector3.new(0.8, 14, 0.8), CFrame.new(p.X, deck - 7.5, p.Z), Color3.fromRGB(80, 56, 38), Mat.Wood)
			end
		end
	end
	-- culées de pierre aux deux bouts (le pont s'appuie sur la berge)
	for _, e in { { a, ya, -1 }, { b, yb, 1 } } do
		local p, y = e[1], e[2]
		local h = deck - (y - 3)
		part("Culee", Vector3.new(10.4, h, 3), CFrame.lookAt(Vector3.new(p.X, y - 3 + h / 2 - 0.5, p.Z), Vector3.new(p.X, y - 3 + h / 2 - 0.5, p.Z) + dir),
			Color3.fromRGB(132, 128, 120), Mat.Cobblestone)
		for _, s in { -1, 1 } do
			local q = p + perp * s * 4.6
			part("Borne", Vector3.new(1.2, 3.4, 1.2), CFrame.new(q.X, deck + 1.2, q.Z), Color3.fromRGB(150, 146, 138), Mat.Cobblestone)
		end
	end
	-- rampes d'accès aux deux bouts
	for _, e in { { a, ya, -1 }, { b, yb, 1 } } do
		local p, y, s = e[1], e[2], e[3]
		local outward = dir * s
		local rise = deck - y + 0.6
		if rise > 0.2 then
			local w = Instance.new("WedgePart")
			w.Name = "Rampe"
			w.Anchored = true
			w.Size = Vector3.new(9, rise, 4)
			-- le coin monte vers +Z : on oriente +Z vers le pont
			local c = p + outward * 2
			w.CFrame = CFrame.lookAt(Vector3.new(c.X, y - 0.6 + rise / 2, c.Z), Vector3.new(c.X, y - 0.6 + rise / 2, c.Z) + outward)
			w.Color = Color3.fromRGB(130, 92, 60)
			w.Material = Mat.WoodPlanks
			w.Parent = m
		end
	end
	-- lanternes à chaque bout (côté opposé l'un de l'autre), allumées la nuit (Clock.seasonize)
	for _, e in { { a, -1, 1 }, { b, 1, -1 } } do
		local p, s, side = e[1], e[2], e[3]
		local lamp = G.Util.clone("Lampadaire")
		if lamp then
			local q = p + perp * side * 5.6 - dir * s * 1.5
			local y = G.Util.groundY(q.X, q.Z)
			lamp:PivotTo(CFrame.lookAt(Vector3.new(q.X, y, q.Z), Vector3.new(q.X, y, q.Z) + perp * side)) -- le bras (+Z) au-dessus du chemin
			lamp.Parent = m
		end
	end
	m.Parent = parent
	G.Clock.seasonize(m)
end

local function buildDeco(d, parent: Instance)
	local model = G.Util.clone(d.model)
	if not model then
		return
	end
	local y = (d.water and Config.WATER_Y or G.Util.groundY(d.x, d.z) - 0.15) + (d.dy or 0)
	place(model, d.x, y, d.z, d.yaw, parent)
	if d.text then
		for _, l in model:GetDescendants() do
			if l:IsA("TextLabel") then
				l.Text = d.text
			end
		end
	end
	if d.unlit then
		for _, f in model:GetDescendants() do
			if f:IsA("Fire") or f:IsA("PointLight") then
				f.Enabled = false
			end
		end
	end
	G.Clock.seasonize(model)
	-- boîte aux lettres des villages : courrier et hôtel des ventes
	if d.model == "Boite_Lettres" and model.PrimaryPart then
		G.Util.prompt(model.PrimaryPart, "mail", "Courrier / ventes", "Boîte aux lettres", { dist = 9 })
	end
	return model
end
World.buildDeco = buildDeco

-- ----------------------------------------------------------------- Chargement

local function loadRegion(rx: number, rz: number)
	local key = rx .. "," .. rz
	if World.loaded[key] then
		return
	end
	G.Mondes.ensureRegion(rx, rz) -- état sauvegardé de la région (secteur lu au besoin)
	local plan = G.wg:plan(rx, rz)
	task.wait()
	writeTerrain(plan)
	local folder = Instance.new("Folder")
	folder.Name = "R" .. key
	-- aucun script n'écoute Touched : les pièces fixes du décor ne calculent plus leurs contacts
	-- (CanTouch). CanQuery reste vrai : clics, visée, invites et rayons en ont besoin.
	folder.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") and d.Anchored then
			d.CanTouch = false
		end
	end)
	folder.Parent = World.folder
	local reg = { key = key, rx = rx, rz = rz, plan = plan, folder = folder, state = World.regionState(key), houses = {} }
	World.loaded[key] = reg
	G.Terraforme.applyRegion(reg) -- trous, remblais et étangs des joueurs
	task.wait()
	local deco = Instance.new("Folder")
	deco.Name = "Decor"
	deco.Parent = folder
	for i, d in plan.decos do
		local dm = buildDeco(d, deco)
		if dm then
			dm:SetAttribute("DecoIdx", i) -- pour la casse et la reconstruction (Demolir)
		end
		if i % 25 == 0 then
			task.wait()
		end
	end
	for _, st in plan.stairs do
		buildStairs(st, deco)
	end
	for _, br in plan.bridges do
		buildBridge(br, deco)
	end
	task.wait()
	-- maisons
	local hf = Instance.new("Folder")
	hf.Name = "Maisons"
	hf.Parent = folder
	for _, h in plan.houses do
		local model = G.Util.clone(h.model)
		if model then
			model.Name = h.model
			model:SetAttribute("HouseId", h.id)
			place(model, h.x, Config.GROUND_Y, h.z, h.yaw, hf)
			reg.houses[h.id] = { data = h, model = model }
			G.Clock.seasonize(model)
		end
	end
	task.wait()
	-- systèmes (objets, cultures, PNJ, bêtes, monstres, portes…)
	for _, sys in G.regionSystems do
		local ok, err = pcall(sys.onRegionLoad, reg)
		if not ok then
			warn("[WildAcres] chargement " .. key .. " : " .. tostring(err))
		end
		task.wait()
	end
	reg.ready = true
end

local function unloadRegion(key: string)
	local reg = World.loaded[key]
	if not reg then
		return
	end
	for _, sys in G.regionSystems do
		if sys.onRegionUnload then
			local ok, err = pcall(sys.onRegionUnload, reg)
			if not ok then
				warn("[WildAcres] déchargement " .. key .. " : " .. tostring(err))
			end
		end
	end
	reg.folder:Destroy()
	clearTerrain(reg.rx, reg.rz)
	World.loaded[key] = nil
end

-- Régions voulues autour des joueurs (les plus proches d'abord)
local function wanted(): { { number } }
	local out = {}
	local seen = {}
	for _, pl in Players:GetPlayers() do
		local root = G.Util.root(pl)
		local pos = root and root.Position or pl:GetAttribute("FocusPos")
		if pos then
			local prx, prz = G.WG.regionOf(math.floor(pos.X / CELL), math.floor(pos.Z / CELL))
			local fx, fz = pos.X / (REGION * CELL) - prx, pos.Z / (REGION * CELL) - prz
			for dx = -Config.LOAD_RADIUS, Config.LOAD_RADIUS do
				for dz = -Config.LOAD_RADIUS, Config.LOAD_RADIUS do
					local k = (prx + dx) .. "," .. (prz + dz)
					if not seen[k] and G.WG.inWorld(prx + dx, prz + dz) then
						seen[k] = true
						-- distance au centre de la région voisine, pour l'ordre
						local d = math.abs(dx + 0.5 - fx) + math.abs(dz + 0.5 - fz)
						table.insert(out, { prx + dx, prz + dz, d })
					end
				end
			end
		end
	end
	table.sort(out, function(a, b)
		return a[3] < b[3]
	end)
	return out
end

function World.update()
	local want = wanted()
	local keep = {}
	for _, w in want do
		local k = w[1] .. "," .. w[2]
		keep[k] = true
		if not World.loaded[k] and not queued[k] then
			queued[k] = true
			table.insert(queue, { w[1], w[2] })
		end
	end
	-- décharge ce qui est loin de tout joueur
	for k, reg in World.loaded do
		if not keep[k] and reg.ready then
			local far = true
			for _, pl in Players:GetPlayers() do
				local root = G.Util.root(pl)
				if root then
					local prx, prz = G.WG.regionOf(math.floor(root.Position.X / CELL), math.floor(root.Position.Z / CELL))
					if math.max(math.abs(prx - reg.rx), math.abs(prz - reg.rz)) < Config.UNLOAD_RADIUS then
						far = false
					end
				end
			end
			if far then
				unloadRegion(k)
			end
		end
	end
	if not busy and #queue > 0 then
		busy = true
		task.spawn(function()
			while #queue > 0 do
				local r = table.remove(queue, 1)
				local k = r[1] .. "," .. r[2]
				local ok, err = pcall(loadRegion, r[1], r[2])
				if not ok then
					warn("[WildAcres] région " .. k .. " : " .. tostring(err))
				end
				queued[k] = nil
				task.wait()
			end
			busy = false
		end)
	end
end

-- Charge tout de suite les régions autour d'un point (avant de faire apparaître le joueur)
function World.preload(pos: Vector3)
	local prx, prz = G.WG.regionOf(math.floor(pos.X / CELL), math.floor(pos.Z / CELL))
	for dx = -Config.LOAD_RADIUS, Config.LOAD_RADIUS do
		for dz = -Config.LOAD_RADIUS, Config.LOAD_RADIUS do
			local k = (prx + dx) .. "," .. (prz + dz)
			if not World.loaded[k] and G.WG.inWorld(prx + dx, prz + dz) then
				queued[k] = true
				local ok, err = pcall(loadRegion, prx + dx, prz + dz)
				if not ok then
					warn("[WildAcres] région " .. k .. " : " .. tostring(err))
				end
				queued[k] = nil
			end
		end
	end
end

function World.unloadAll()
	for k in World.loaded do
		unloadRegion(k)
	end
	workspace.Terrain:Clear()
end

-- Région chargée contenant un point
function World.regionAt(pos: Vector3)
	local rx, rz = G.WG.regionOf(math.floor(pos.X / CELL), math.floor(pos.Z / CELL))
	return World.loaded[rx .. "," .. rz]
end

-- Point d'apparition : devant la ruine de départ
function World.startPos(): Vector3
	local plan = G.wg:plan(0, 0)
	local r = plan.startRuin
	if r then
		return Vector3.new(r.doorX, Config.GROUND_Y + 4, r.doorZ + 4)
	end
	return Vector3.new(96, 30, 96)
end

return World
