-- Chroniques (19/11) : parchemin qui affiche les pages connues d'un récit (Systemes/Chroniques).
-- Ouvert à la lecture d'une page ancienne ou par /chroniques <n> ; la page tout juste trouvée est
-- surlignée, les pages manquantes restent « … page perdue … ». Fermer : bouton, Échap ou B (manette).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Chronique", 60)
if not remote then
	return
end

local INK = Color3.fromRGB(62, 44, 28)
local PAPER = Color3.fromRGB(236, 220, 182)
local DIM = Color3.fromRGB(140, 118, 88)

local gui = Instance.new("ScreenGui")
gui.Name = "Chroniques"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.new(0.9, 0, 0.8, 0)
frame.BackgroundColor3 = PAPER
frame.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(540, 560)
limit.Parent = frame
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame
local border = Instance.new("UIStroke")
border.Color = Color3.fromRGB(120, 86, 50)
border.Thickness = 3
border.Parent = frame

local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))
local title = Composants.titre({
	Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -70, 0, 30),
	Font = Enum.Font.Fantasy, TextSize = 24, TextColor3 = INK, Parent = frame,
})

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.Position = UDim2.fromOffset(18, 42)
sub.Size = UDim2.new(1, -36, 0, 18)
sub.Font = Enum.Font.Gotham
sub.TextSize = 13
sub.TextColor3 = DIM
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = frame

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -10, 0, 10)
close.Size = UDim2.fromOffset(36, 36)
close.BackgroundColor3 = Color3.fromRGB(120, 86, 50)
close.Text = "✕"
close.TextColor3 = PAPER
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.Parent = frame
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(1, 0)
cc.Parent = close

local body = Instance.new("ScrollingFrame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(18, 70)
body.Size = UDim2.new(1, -36, 1, -84)
body.ScrollBarThickness = 6
body.ScrollBarImageColor3 = DIM
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.CanvasSize = UDim2.new()
body.BorderSizePixel = 0
body.Parent = frame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 12)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = body

local function hide()
	gui.Enabled = false
end
close.Activated:Connect(hide)
require(script.Parent:WaitForChild("WindowNav")).watch(frame, close, hide, gui)

remote.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or type(d.pages) ~= "table" then
		return
	end
	for _, c in body:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	title.Text = "📜 " .. tostring(d.titre or "")
	sub.Text = string.format("%d page(s) sur %d", d.connues or 0, d.total or #d.pages)
	for _, p in d.pages do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = p.n == d.nouvelle and 0.6 or 1
		t.BackgroundColor3 = Color3.fromRGB(250, 214, 120)
		t.Size = UDim2.new(1, -8, 0, 0)
		t.AutomaticSize = Enum.AutomaticSize.Y
		t.TextWrapped = true
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Font = p.texte and Enum.Font.Merriweather or Enum.Font.Gotham
		t.TextSize = 16
		t.TextColor3 = p.texte and INK or DIM
		t.Text = p.texte and (p.n .. ". " .. p.texte) or (p.n .. ". … page perdue …")
		t.LayoutOrder = p.n
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 4)
		pad.PaddingBottom = UDim.new(0, 4)
		pad.PaddingLeft = UDim.new(0, 6)
		pad.PaddingRight = UDim.new(0, 6)
		pad.Parent = t
		t.Parent = body
	end
	gui.Enabled = true
end)
