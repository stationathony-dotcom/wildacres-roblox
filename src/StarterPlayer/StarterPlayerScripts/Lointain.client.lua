-- Lointain (chantier B, 25/11) : dessine, sur ce client seulement, le reste de l'île au-delà des régions
-- chargées (blocs voxel allégés tirés des bruits du monde) et une couronne de massifs au large.
-- Aucune collision, aucune ombre, aucun réseau. Les régions réellement chargées (workspace.Monde.R x,z)
-- sont laissées vides ; le lointain se refait en tâche de fond quand on change de région.
-- Écrit par Claude (couloir Codex : script client neuf, à reprendre librement — voir docs/LOTS.md).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local L = require(Shared:WaitForChild("Lointain"))
local okWG, WG = pcall(require, Shared:WaitForChild("WorldGen"))
if not okWG then
	warn("[WildAcres] Lointain : WorldGen illisible", WG)
	return
end

local player = Players.LocalPlayer
local SPAN = Config.CELL * Config.REGION
local BOTTOM = L.SEA_Y - 14
local PER_FRAME = 250

-- appareils tactiles sans clavier : blocs plus gros, horizon un peu plus court
local opts = nil
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	opts = { nearStep = 48, nearRadius = 800, farStep = 120, farRadius = 2000 }
end

local function newPart(parent, size: Vector3, cf: CFrame, color: Color3, mat, transparency: number?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local root = Instance.new("Folder")
root.Name = "Lointain"
root.Parent = workspace

-- ------------------------------------------------------------------ couronne de massifs (une fois)
local function buildMassifs(seed: number)
	local f = Instance.new("Folder")
	f.Name = "Massifs"
	for _, m in L.massifs(seed, WG.hash) do
		for _, b in L.massifBlocks(m) do
			newPart(f, b.size, b.cf, b.color, b.material, b.transparency)
		end
	end
	-- la mer jusqu'à l'horizon : quatre bandes autour de la zone dessinée (jamais sous un vrai lac)
	f.Parent = root
	return f
end

local seaFolder
local function buildSea(cx: number, cz: number, r: number)
	if seaFolder then
		seaFolder:Destroy()
	end
	seaFolder = Instance.new("Folder")
	seaFolder.Name = "Mer"
	local far = 12000
	local y = L.SEA_Y - 0.5
	local c = L.COLORS.mer
	local m = Enum.Material.SmoothPlastic
	newPart(seaFolder, Vector3.new(2 * far, 1, far - r), CFrame.new(cx, y, cz - r - (far - r) / 2), c, m)
	newPart(seaFolder, Vector3.new(2 * far, 1, far - r), CFrame.new(cx, y, cz + r + (far - r) / 2), c, m)
	newPart(seaFolder, Vector3.new(far - r, 1, 2 * r), CFrame.new(cx - r - (far - r) / 2, y, cz), c, m)
	newPart(seaFolder, Vector3.new(far - r, 1, 2 * r), CFrame.new(cx + r + (far - r) / 2, y, cz), c, m)
	seaFolder.Parent = root
end

-- ------------------------------------------------------------------ île lointaine
local current, building, dirty = nil, false, true
local lastEvent = 0

local function loadedRegions(): { [string]: boolean }
	local skip = {}
	local monde = workspace:FindFirstChild("Monde")
	if monde then
		for _, r in monde:GetChildren() do
			local x, z = string.match(r.Name, "^R(%-?%d+),(%-?%d+)$")
			if x then
				skip[x .. "," .. z] = true
			end
		end
	end
	return skip
end

-- couleur du vrai terrain pour un matériau (Eclairage règle les couleurs) : raccord invisible (C16, 26/11)
local terrainColor = {}
local function groundColor(r): Color3
	local m = r.material
	if m and m ~= Enum.Material.SmoothPlastic then
		local c = terrainColor[m]
		if not c then
			local ok, col = pcall(function()
				return workspace.Terrain:GetMaterialColor(m)
			end)
			c = ok and col or r.color
			terrainColor[m] = c
		end
		return c
	end
	return r.color
end

local TRUNK = Color3.fromRGB(92, 64, 44)
local CONIFER = { Color3.fromRGB(52, 92, 58), Color3.fromRGB(62, 104, 62), Color3.fromRGB(44, 80, 54) }

-- un arbre vu de loin (C16, 26/11 : « de vrais arbres, troncs + houppiers, au lieu de pavés ») :
-- feuillu = houppier en 2 étages décalés ; conifère = 2 gradins étroits ; tronc seulement de près
local function tree(parent, x: number, y: number, z: number, size: number, tint: Color3, conifer: boolean, trunk: boolean, rng): number
	local n = 0
	local rot = CFrame.Angles(0, rng:NextNumber(0, math.pi / 2), 0)
	local h = size * rng:NextNumber(0.9, 1.25)
	if trunk then
		newPart(parent, Vector3.new(size * 0.14, h * 0.45, size * 0.14), CFrame.new(x, y + h * 0.22, z) * rot, TRUNK, Enum.Material.Wood)
		n += 1
	end
	if conifer then
		local c = CONIFER[rng:NextInteger(1, #CONIFER)]
		newPart(parent, Vector3.new(size * 0.62, h * 0.55, size * 0.62), CFrame.new(x, y + h * 0.5, z) * rot, c, Enum.Material.Grass)
		newPart(parent, Vector3.new(size * 0.34, h * 0.5, size * 0.34), CFrame.new(x, y + h * 0.95, z) * rot * CFrame.Angles(0, math.pi / 4, 0), c:Lerp(Color3.new(1, 1, 1), 0.06), Enum.Material.Grass)
	else
		local w = size * rng:NextNumber(0.8, 1.05)
		newPart(parent, Vector3.new(w, h * 0.42, w * 0.9), CFrame.new(x, y + h * 0.55, z) * rot, tint, Enum.Material.Grass)
		newPart(parent, Vector3.new(w * 0.62, h * 0.32, w * 0.62), CFrame.new(x + w * 0.08, y + h * 0.86, z - w * 0.06) * rot * CFrame.Angles(0, math.pi / 4, 0),
			tint:Lerp(Color3.new(1, 1, 0.85), 0.12), Enum.Material.Grass)
	end
	return n + 2
end

local function rebuild(wg, px: number, pz: number)
	building = true
	dirty = false
	local rows = L.layout(wg, px, pz, loadedRegions(), opts)
	local f = Instance.new("Folder")
	f.Name = "Ile"
	local made = 0
	local chunk = Instance.new("Folder")
	chunk.Parent = f
	local rng = Random.new(math.floor(px) * 7 + math.floor(pz))
	for _, r in rows do
		local w = r.x1 - r.x0
		local cx = (r.x0 + r.x1) / 2
		if r.water then
			newPart(chunk, Vector3.new(w, 1, r.step), CFrame.new(cx, r.top - 0.5, r.z), r.color, r.material)
		else
			local h = math.max(1, r.top - BOTTOM)
			local col = groundColor(r)
			local mat = r.material
			if r.canopy or r.material == Enum.Material.LeafyGrass then
				-- de loin, une forêt se lit surtout par ses frondaisons : sol (tapis roux) fondu vers le vert sombre
				col = col:Lerp(Color3.fromRGB(84, 104, 50), r.canopy and 0.55 or 0.4)
				mat = Enum.Material.Grass
			end
			newPart(chunk, Vector3.new(w, h, r.step), CFrame.new(cx, BOTTOM + h / 2, r.z), col, mat)
			-- bords biseautés vers la mer (les côtes ne sont plus en escalier carré)
			local above = r.top - L.SEA_Y
			if above > 0.5 and r.step <= 48 then
				local bw = math.min(r.step * 0.7, above * 3 + 6)
				for _, side in { -1, 1 } do
					-- seulement là où la mer touche la rangée (pas contre une région chargée ni dans les terres)
					if (side < 0 and not r.edgeL) or (side > 0 and not r.edgeR) then
						continue
					end
					local ex = side < 0 and r.x0 or r.x1
					local wedge = Instance.new("WedgePart")
					wedge.Anchored, wedge.CanCollide, wedge.CanQuery, wedge.CanTouch, wedge.CastShadow = true, false, false, false, false
					wedge.Size = Vector3.new(r.step, above, bw)
					wedge.CFrame = CFrame.new(ex + side * bw / 2, L.SEA_Y + above / 2, r.z) * CFrame.Angles(0, side > 0 and -math.pi / 2 or math.pi / 2, 0)
					wedge.Color = col:Lerp(L.COLORS.sable, 0.5)
					wedge.Material = Enum.Material.Sand
					wedge.Parent = chunk
					made += 1
				end
			end
			if r.canopy then
				local dist = math.sqrt((cx - px) ^ 2 + (r.z - pz) ^ 2)
				local near = r.step <= 48
				local spacing = near and r.step * 0.75 or r.step * 1.1
				local n = math.clamp(math.floor(w / spacing + 0.5), 1, near and 40 or 14)
				local size = near and rng:NextNumber(14, 19) or rng:NextNumber(22, 30)
				for i = 0, n - 1 do
					local x = r.x0 + (i + 0.5) * (w / n) + rng:NextNumber(-spacing * 0.3, spacing * 0.3)
					local z = r.z + rng:NextNumber(-r.step * 0.3, r.step * 0.3)
					local tint = r.shades and r.shades[rng:NextInteger(1, #r.shades)] or r.canopy
					local conifer = r.conifers and rng:NextNumber() < r.conifers
					made += tree(chunk, x, r.top, z, size * rng:NextNumber(0.85, 1.15), tint, conifer, near and dist < 520, rng)
					if made % PER_FRAME == 0 then
						chunk = Instance.new("Folder")
						chunk.Parent = f
						task.wait()
					end
				end
			end
		end
		made += 1
		if made % PER_FRAME == 0 then
			chunk = Instance.new("Folder")
			chunk.Parent = f
			task.wait()
		end
	end
	-- on montre le nouveau lointain d'un coup, puis on jette l'ancien
	f.Parent = root
	if current then
		current:Destroy()
	end
	current = f
	buildSea(px, pz, (opts and opts.farRadius or L.FAR_RADIUS) + (opts and opts.farStep or L.FAR_STEP))
	building = false
end

local function start()
	local seed = workspace:GetAttribute("Seed")
	while not seed do
		workspace:GetAttributeChangedSignal("Seed"):Wait()
		seed = workspace:GetAttribute("Seed")
	end
	local wg = WG.new(seed, workspace:GetAttribute("Gen"))
	buildMassifs(seed)
	local function watch(monde)
		monde.ChildAdded:Connect(function()
			dirty, lastEvent = true, os.clock()
		end)
		monde.ChildRemoved:Connect(function()
			dirty, lastEvent = true, os.clock()
		end)
	end
	local monde = workspace:FindFirstChild("Monde")
	if monde then
		watch(monde)
	end
	workspace.ChildAdded:Connect(function(c)
		if c.Name == "Monde" then
			watch(c)
			dirty, lastEvent = true, os.clock()
		end
	end)
	local lastKey = nil
	while true do
		task.wait(1)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and not building then
			local p = hrp.Position
			local key = math.floor(p.X / SPAN) .. "," .. math.floor(p.Z / SPAN)
			if key ~= lastKey then
				lastKey = key
				dirty, lastEvent = true, os.clock()
			end
			-- on attend que les régions aient fini d'arriver (1,5 s sans changement) avant de redessiner
			if dirty and os.clock() - lastEvent > 1.5 then
				local okB, err = pcall(rebuild, wg, p.X, p.Z)
				if not okB then
					warn("[WildAcres] Lointain :", err)
					building = false
				end
			end
		end
	end
end

task.spawn(start)
