-- Livre (19/11) : fenêtre de lecture générique (bestiaire…) envoyée par Systemes/Livres
-- (événement « Livre » : { titre, sous, lignes = { { t = titre de fiche, x = texte } } }).
-- Fermer : bouton, Échap ou B (manette).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Livre", 60)
if not remote then
	return
end

local INK = Color3.fromRGB(58, 40, 26)
local PAPER = Color3.fromRGB(232, 218, 186)
local DIM = Color3.fromRGB(128, 108, 82)

local gui = Instance.new("ScreenGui")
gui.Name = "Livre"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromScale(0.9, 0.82)
frame.BackgroundColor3 = PAPER
frame.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(600, 600)
limit.Parent = frame
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local border = Instance.new("UIStroke")
border.Color = Color3.fromRGB(110, 60, 40)
border.Thickness = 3
border.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -70, 0, 30)
title.Font = Enum.Font.Fantasy
title.TextSize = 24
title.TextColor3 = INK
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

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
close.BackgroundColor3 = Color3.fromRGB(110, 60, 40)
close.Text = "✕"
close.TextColor3 = PAPER
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.Parent = frame
Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)

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
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = body

local function hide()
	gui.Enabled = false
end
close.Activated:Connect(hide)
require(script.Parent:WaitForChild("WindowNav")).watch(frame, close, hide, gui)

remote.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or type(d.lignes) ~= "table" then
		return
	end
	for _, c in body:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	title.Text = tostring(d.titre or "")
	sub.Text = tostring(d.sous or "")
	for i, l in d.lignes do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, -8, 0, 0)
		t.AutomaticSize = Enum.AutomaticSize.Y
		t.TextWrapped = true
		t.RichText = true
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Font = Enum.Font.Merriweather
		t.TextSize = 15
		t.TextColor3 = INK
		local function esc(s)
			return (tostring(s or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
		end
		t.Text = "<b>" .. esc(l.t) .. "</b>\n" .. esc(l.x)
		t.LayoutOrder = i
		t.Parent = body
	end
	gui.Enabled = true
end)
