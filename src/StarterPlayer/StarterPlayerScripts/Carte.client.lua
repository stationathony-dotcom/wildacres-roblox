-- Carte personnelle [M] (étape 18) : l'île en 27 × 27 régions. Seules les régions parcourues sont
-- dessinées (couleur du biome, icône du lieu) ; le reste est un parchemin vierge. Une flèche montre
-- où l'on est et dans quel sens on regarde. Les régions découvertes viennent du serveur (profil
-- « carte », puis Fx « carte » à chaque nouvelle région : la carte se complète en direct).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

if workspace:GetAttribute("Mode") == "accueil" then
	return
end

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local R = Config.WORLD_RADIUS
local N = 2 * R + 1
local CELLPX = 16
local SPAN = Config.CELL * Config.REGION
local BIOME_COLOR = {
	prairie = Color3.fromRGB(122, 170, 84), foret = Color3.fromRGB(176, 110, 52), desert = Color3.fromRGB(222, 196, 128),
	neige = Color3.fromRGB(222, 230, 238), marais = Color3.fromRGB(92, 112, 76),
}
local POI_ICON = { village = "🏘️", farm = "🌾", ruin = "🏚️", lair = "💀" }
local SEA = Color3.fromRGB(70, 110, 140)
local FOG = Color3.fromRGB(196, 178, 140)

local discovered = {}

local gui = Instance.new("ScreenGui")
gui.Name = "Carte"
gui.ResetOnSpawn = false
gui.DisplayOrder = 14
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panneau"
panel.Size = UDim2.fromOffset(N * CELLPX + 28, N * CELLPX + 168)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(60, 46, 30)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(176, 140, 72)
stroke.Thickness = 3
local scale = Instance.new("UIScale", panel)
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Font = Enum.Font.Fondamento
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(240, 220, 170)
title.Size = UDim2.new(1, -60, 0, 34)
title.Position = UDim2.fromOffset(14, 6)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Parent = panel
local close = Instance.new("TextButton")
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(190, 60, 50)
close.Size = UDim2.fromOffset(28, 28)
close.Position = UDim2.new(1, -36, 0, 8)
close.Parent = panel
Instance.new("UICorner", close)

local grid = Instance.new("Frame")
grid.BackgroundColor3 = FOG
grid.Size = UDim2.fromOffset(N * CELLPX, N * CELLPX)
grid.Position = UDim2.fromOffset(14, 50)
grid.Parent = panel
local foot = Instance.new("TextLabel")
foot.BackgroundTransparency = 1
foot.Font = Enum.Font.Gotham
foot.TextSize = 12
foot.TextColor3 = Color3.fromRGB(220, 200, 160)
foot.Size = UDim2.new(1, -28, 0, 16)
foot.Position = UDim2.fromOffset(14, N * CELLPX + 52)
foot.TextXAlignment = Enum.TextXAlignment.Left
foot.Parent = panel

local reperes = require(script.Parent:WaitForChild("ReperesCarte")).new(
	panel, grid, close, Remotes, R, N, SPAN, N * CELLPX + 72
)

local arrow = Instance.new("TextLabel")
arrow.Text = "▲"
arrow.Font = Enum.Font.GothamBold
arrow.TextSize = 16
arrow.TextColor3 = Color3.fromRGB(200, 30, 30)
arrow.TextStrokeTransparency = 0.2
arrow.BackgroundTransparency = 1
arrow.Size = UDim2.fromOffset(16, 16)
arrow.AnchorPoint = Vector2.new(0.5, 0.5)
arrow.ZIndex = 5
arrow.Parent = grid

-- croix de la carte au trésor (position monde) : le serveur l'envoie (profil « tresor », Fx « tresor »)
local cross = Instance.new("TextLabel")
cross.Text = "❌"
cross.TextSize = 14
cross.BackgroundTransparency = 1
cross.Size = UDim2.fromOffset(16, 16)
cross.AnchorPoint = Vector2.new(0.5, 0.5)
cross.ZIndex = 4
cross.Visible = false
cross.Parent = grid
local function setCross(pos)
	if typeof(pos) == "Vector3" then
		cross.Position = UDim2.fromOffset((pos.X / SPAN + R) * CELLPX, (pos.Z / SPAN + R) * CELLPX)
		cross.Visible = true
	else
		cross.Visible = false
	end
end

local WG = nil
local function wg()
	local seed = workspace:GetAttribute("Seed")
	if seed and (not WG or WG.seed ~= seed) then
		local ok, mod = pcall(require, Shared:WaitForChild("WorldGen"))
		if ok then
			WG = mod.new(seed, workspace:GetAttribute("Gen"))
		end
	end
	return WG
end

local cells = {}
local function render()
	local w = wg()
	if not w then
		return
	end
	local found, places = 0, 0
	for rx = -R, R do
		for rz = -R, R do
			local key = rx .. "," .. rz
			local c = cells[key]
			if not c then
				c = Instance.new("Frame")
				c.BorderSizePixel = 0
				c.Size = UDim2.fromOffset(CELLPX, CELLPX)
				c.Position = UDim2.fromOffset((rx + R) * CELLPX, (rz + R) * CELLPX)
				c.BackgroundTransparency = 1
				c.Parent = grid
				cells[key] = c
			end
			if discovered[key] and not c:GetAttribute("Fait") then
				c:SetAttribute("Fait", true)
				local inWorld = w.inWorld(rx, rz)
				local ok, biome = pcall(w.regionBiome, w, rx, rz)
				c.BackgroundColor3 = inWorld and (BIOME_COLOR[ok and biome or "prairie"] or FOG) or SEA
				c.BackgroundTransparency = 0
				-- apparition : fondu (la carte « se dessine »)
				c.BackgroundTransparency = 1
				TweenService:Create(c, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
				local poi = inWorld and w:poiOf(rx, rz)
				if poi and POI_ICON[poi.kind] then
					local ic = Instance.new("TextLabel")
					ic.BackgroundTransparency = 1
					ic.Text = POI_ICON[poi.kind]
					ic.TextSize = 12
					ic.Size = UDim2.fromScale(1, 1)
					ic.Parent = c
				end
			end
		end
	end
	for key in discovered do
		found += 1
		local rx, rz = string.match(key, "^(-?%d+),(-?%d+)$")
		local poi = rx and w:poiOf(tonumber(rx), tonumber(rz))
		if poi then
			places += 1
		end
	end
	title.Text = "Carte du monde · " .. (workspace:GetAttribute("WorldName") or "l'île")
	foot.Text = string.format("%d régions parcourues · %d lieux découverts", found, places)
end

local function addKeys(str)
	for k in string.gmatch(str or "", "[^;]+") do
		discovered[k] = true
	end
end

Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function(data)
	if type(data) == "table" then
		local t = data.tresor
		setCross(type(t) == "table" and t.x and Vector3.new(t.x, 0, t.z) or nil)
	end
	if type(data) == "table" and type(data.carte) == "string" then
		addKeys(data.carte)
		if panel.Visible then
			render()
		end
	end
end)
Remotes:WaitForChild("Fx").OnClientEvent:Connect(function(kind, key)
	if kind == "tresor" then
		setCross(key)
		return
	end
	if kind == "carte" and type(key) == "string" then
		discovered[key] = true
		if panel.Visible then
			render()
		end
	end
end)

local function toggle()
	if panel.Visible then
		if reperes.cancelPlacement() then
			return
		end
		panel.Visible = false
		return
	end
	local vp = workspace.CurrentCamera.ViewportSize
	local target = math.min(1, (vp.X - 32) / panel.Size.X.Offset, (vp.Y - 40) / panel.Size.Y.Offset)
	render()
	scale.Scale = target * 0.9
	panel.Visible = true
	reperes.refresh()
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target }):Play()
end
close.Activated:Connect(function()
	reperes.cancelPlacement()
	panel.Visible = false
end)
require(script.Parent:WaitForChild("WindowNav")).watch(panel, close, toggle)
local ouvrir = Instance.new("BindableEvent")
ouvrir.Name = "OuvrirCarte"
ouvrir.Event:Connect(toggle)
ouvrir.Parent = player

RunService.RenderStepped:Connect(function(dt)
	if not panel.Visible then
		return
	end
	reperes.step(dt)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local fx = hrp.Position.X / SPAN + R
	local fz = hrp.Position.Z / SPAN + R
	arrow.Position = UDim2.fromOffset(fx * CELLPX, fz * CELLPX)
	local look = workspace.CurrentCamera.CFrame.LookVector
	arrow.Rotation = math.deg(math.atan2(look.X, -look.Z))
end)
