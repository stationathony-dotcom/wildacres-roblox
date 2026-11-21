-- Carte personnelle [M] (étape 18) : l'île en 27 × 27 régions. Seules les régions parcourues sont
-- dessinées (couleur du biome, icône du lieu) ; le reste est un parchemin vierge. Une flèche montre
-- où l'on est et dans quel sens on regarde. Les régions découvertes viennent du serveur (profil
-- « carte », puis Fx « carte » à chaque nouvelle région : la carte se complète en direct).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))
local Retour = require(script.Parent:WaitForChild("Retour"))

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
local pending = {}
local regionsVisitees, lieuxVisites = 0, 0
local enRendu = false

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
local title = Composants.titre({
	Font = Enum.Font.Fondamento, TextSize = 24, TextColor3 = Color3.fromRGB(240, 220, 170),
	Size = UDim2.new(1, -60, 0, 34), Position = UDim2.fromOffset(14, 6), Parent = panel,
})
local close = Composants.bouton({
	Text = Composants.PICTOGRAMMES.fermer, TextColor3 = Color3.new(1, 1, 1),
	BackgroundColor3 = Color3.fromRGB(190, 60, 50), Size = UDim2.fromOffset(28, 28),
	Position = UDim2.new(1, -36, 0, 8), Parent = panel,
})
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

local lit = Composants.creer("TextLabel", {
	Name = "MonLit", Text = "◆ Mon lit", Font = Enum.Font.GothamBold, TextSize = 12,
	TextColor3 = Color3.fromRGB(237, 190, 251), BackgroundColor3 = Color3.fromRGB(48, 36, 25),
	Size = UDim2.fromOffset(62, 18), AnchorPoint = Vector2.new(0.5, 0.55),
	Visible = false, ZIndex = 7, Parent = grid,
}, { Composants.creer("UICorner", { CornerRadius = UDim.new(0, 4) }) })
local demandeLit = 0
local function actualiserLit()
	demandeLit += 1
	local demande = demandeLit
	lit.Visible = false
	task.spawn(function()
		local retour = Retour.lire(Remotes)
		if demande ~= demandeLit then return end
		local pos = retour and retour.lit
		if type(pos) ~= "table" or type(pos.x) ~= "number" or type(pos.z) ~= "number" then return end
		local u, v = (pos.x / SPAN + R) / N, (pos.z / SPAN + R) / N
		if u >= 0 and u < 1 and v >= 0 and v < 1 then
			lit.Position = UDim2.fromScale(u, v)
			lit.Visible = true
		end
	end)
end

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

local function majResume()
	title.Text = "Carte du monde · " .. (workspace:GetAttribute("WorldName") or "l'île")
	foot.Text = string.format("%d régions parcourues · %d lieux découverts", regionsVisitees, lieuxVisites)
end

local function dessinerRegion(w, region)
	local rx, rz = region.x, region.z
	local c = Instance.new("Frame")
	c.BorderSizePixel = 0
	c.Size = UDim2.fromOffset(CELLPX, CELLPX)
	c.Position = UDim2.fromOffset((rx + R) * CELLPX, (rz + R) * CELLPX)
	local inWorld = w.inWorld(rx, rz)
	local ok, biome = pcall(w.regionBiome, w, rx, rz)
	c.BackgroundColor3 = inWorld and (BIOME_COLOR[ok and biome or "prairie"] or FOG) or SEA
	c.BackgroundTransparency = region.fondu and 1 or 0
	c.Parent = grid
	if region.fondu then
		TweenService:Create(c, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
	end
	local poiOk, poi
	if inWorld then poiOk, poi = pcall(w.poiOf, w, rx, rz) end
	if poiOk and poi then
		lieuxVisites += 1
		if POI_ICON[poi.kind] then
			Composants.creer("TextLabel", {
				BackgroundTransparency = 1, Text = POI_ICON[poi.kind], TextSize = 12,
				Size = UDim2.fromScale(1, 1), Parent = c,
			})
		end
	end
end

local function render()
	majResume()
	if enRendu or not next(pending) then return end
	local w = wg()
	if not w then return end
	enRendu = true
	task.spawn(function()
		while panel.Visible and next(pending) do
			local lot = 0
			local fin = os.clock() + 0.004
			for key, region in pending do
				pending[key] = nil
				dessinerRegion(w, region)
				lot += 1
				if lot == 24 or os.clock() >= fin then break end
			end
			majResume()
			if next(pending) then task.wait() end
		end
		enRendu = false
	end)
end

local function ajouterRegion(key, fondu)
	if discovered[key] then return false end
	local x, z = string.match(key, "^(-?%d+),(-?%d+)$")
	local rx, rz = tonumber(x), tonumber(z)
	if not rx or not rz then return false end
	discovered[key] = true
	regionsVisitees += 1
	if math.abs(rx) <= R and math.abs(rz) <= R then
		pending[key] = { x = rx, z = rz, fondu = fondu }
	end
	return true
end

local function addKeys(str)
	local changed = false
	for k in string.gmatch(str or "", "[^;]+") do
		if ajouterRegion(k, false) then changed = true end
	end
	return changed
end

Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function(data)
	if type(data) == "table" then
		local t = data.tresor
		setCross(type(t) == "table" and t.x and Vector3.new(t.x, 0, t.z) or nil)
	end
	if type(data) == "table" and type(data.carte) == "string" then
		if addKeys(data.carte) and panel.Visible then
			render()
		end
	end
end)
Remotes:WaitForChild("Fx").OnClientEvent:Connect(function(kind, key)
	if kind == "tresor" then
		setCross(key)
		return
	end
	if kind == "carte" and type(key) == "string" and ajouterRegion(key, panel.Visible) and panel.Visible then
		render()
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
	scale.Scale = target * 0.9
	panel.Visible = true
	render()
	reperes.refresh()
	actualiserLit()
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

local function suivreJoueur(dt)
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
end

local suivi
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		suivi = RunService.RenderStepped:Connect(suivreJoueur)
	elseif suivi then
		suivi:Disconnect()
		suivi = nil
	end
end)
workspace:GetAttributeChangedSignal("Seed"):Connect(function()
	if panel.Visible then render() end
end)
