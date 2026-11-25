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
			newPart(chunk, Vector3.new(w, h, r.step), CFrame.new(cx, BOTTOM + h / 2, r.z), r.color, r.material)
			if r.canopy then
				-- frondaisons : un bouquet par case près du joueur, une haie au loin
				local n = math.max(1, math.floor(w / r.step + 0.5))
				if r.step <= 48 and n <= 24 then
					for i = 0, n - 1 do
						local th = rng:NextNumber(9, 16)
						local tint = r.shades and r.shades[rng:NextInteger(1, #r.shades)] or r.canopy
						newPart(chunk, Vector3.new(r.step * 0.8, th, r.step * 0.8), CFrame.new(r.x0 + (i + 0.5) * r.step + rng:NextNumber(-3, 3), r.top + 4 + th / 2, r.z + rng:NextNumber(-3, 3)), tint, Enum.Material.Grass)
						made += 1
					end
				else
					-- au loin : une haie par rangée, coupée en deux teintes pour casser l'aplat
					local tint = r.shades and r.shades[rng:NextInteger(1, #r.shades)] or r.canopy
					local tint2 = r.shades and r.shades[rng:NextInteger(1, #r.shades)] or r.canopy
					newPart(chunk, Vector3.new(w * 0.47, 12, r.step * 0.8), CFrame.new(cx - w * 0.24, r.top + 10, r.z), tint, Enum.Material.Grass)
					newPart(chunk, Vector3.new(w * 0.47, 15, r.step * 0.7), CFrame.new(cx + w * 0.24, r.top + 11.5, r.z), tint2, Enum.Material.Grass)
					made += 1
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
