-- Journal de quêtes [J] (client). Tout est facultatif : on prend, on lâche, on rend quand on veut.
-- Haut : les quêtes proposées, SEULEMENT quand on est au tableau des quêtes d'un village ou qu'un
-- habitant nous en parle (« Tu as du travail ? ») ; le panneau s'ouvre alors tout seul. Bas : ses
-- quêtes en cours, avec la progression (on les rend au tableau ou à un habitant du village). Le serveur décide de tout (Systemes/Quetes) ; ici on affiche et on demande.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

if workspace:GetAttribute("Mode") == "accueil" then
	return
end

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GOLD = Color3.fromRGB(246, 200, 70)
local TEXT = Color3.fromRGB(245, 238, 222)
local DIM = Color3.fromRGB(180, 170, 150)
local ROW = Color3.fromRGB(40, 42, 50)
local GREEN = Color3.fromRGB(70, 150, 70)
local RED = Color3.fromRGB(170, 70, 55)
local BLUE = Color3.fromRGB(60, 110, 180)

local gui = Instance.new("ScreenGui")
gui.Name = "Quetes"
gui.ResetOnSpawn = false
gui.DisplayOrder = 15
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = p
end
local function label(parent, text, size, ts, color, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextSize = ts or 13
	l.TextColor3 = color or TEXT
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Size = size
	l.Parent = parent
	return l
end
local function button(parent, text, size, color, fn)
	local b = Instance.new("TextButton")
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = color
	b.Size = size
	b.Parent = parent
	corner(b, 6)
	b.Activated:Connect(fn)
	return b
end

local panel = Instance.new("Frame")
panel.Name = "Journal"
panel.Size = UDim2.fromOffset(560, 520)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
panel.Visible = false
panel.Parent = gui
corner(panel, 12)
local st = Instance.new("UIStroke")
st.Color = Color3.fromRGB(176, 140, 72)
st.Thickness = 2.5
st.Parent = panel
local scale = Instance.new("UIScale")
scale.Parent = panel
label(panel, "📜  Quêtes", UDim2.new(1, -60, 0, 32), 22, GOLD, true).Position = UDim2.fromOffset(16, 8)
label(panel, "Toutes facultatives : prends-en, lâche-les, rien n'est obligatoire.", UDim2.new(1, -60, 0, 18), 12, DIM).Position = UDim2.fromOffset(16, 38)
local close = button(panel, "X", UDim2.fromOffset(30, 30), Color3.fromRGB(190, 60, 50), function()
	panel.Visible = false
end)
close.Position = UDim2.new(1, -40, 0, 10)

local body = Instance.new("ScrollingFrame")
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 4
body.Size = UDim2.new(1, -24, 1, -70)
body.Position = UDim2.fromOffset(12, 62)
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = body

local function send(kind, data)
	Remotes.Action:FireServer(kind, data or {})
end

local order = 0
local function header(text)
	order += 1
	local l = label(body, text, UDim2.new(1, -8, 0, 26), 16, GOLD, true)
	l.LayoutOrder = order
end

local function questRow(q, offer: boolean)
	order += 1
	local r = Instance.new("Frame")
	r.Size = UDim2.new(1, -8, 0, 74)
	r.BackgroundColor3 = ROW
	r.LayoutOrder = order
	r.Parent = body
	corner(r, 8)
	label(r, q.icon or "📜", UDim2.fromOffset(40, 74), 26).TextXAlignment = Enum.TextXAlignment.Center
	label(r, q.title, UDim2.new(1, -170, 0, 20), 15, TEXT, true).Position = UDim2.fromOffset(44, 6)
	label(r, q.what, UDim2.new(1, -170, 0, 18), 12, DIM).Position = UDim2.fromOffset(44, 27)
	local rew = "💰 " .. tostring(q.gold)
	if q.item and Config.ITEMS[q.item] then
		rew ..= "   +  " .. Config.ITEMS[q.item].icon .. " " .. Config.ITEMS[q.item].name
	end
	if q.skill and Config.SKILLS[q.skill] then
		rew ..= "   ·  " .. Config.SKILLS[q.skill].icon
	end
	label(r, rew, UDim2.new(1, -170, 0, 18), 12, GOLD).Position = UDim2.fromOffset(44, 48)
	if offer then
		button(r, "Accepter", UDim2.fromOffset(110, 32), GREEN, function()
			send("quete_prendre", { id = q.id })
		end).Position = UDim2.new(1, -118, 0.5, -16)
	else
		if q.kind ~= "apporter" and q.kind ~= "lettre" then
			local back = Instance.new("Frame")
			back.Size = UDim2.fromOffset(110, 8)
			back.Position = UDim2.new(1, -118, 0, 10)
			back.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
			back.Parent = r
			corner(back, 4)
			local fill = Instance.new("Frame")
			fill.Size = UDim2.fromScale(math.clamp(q.got / math.max(1, q.need), 0, 1), 1)
			fill.BackgroundColor3 = q.got >= q.need and GREEN or GOLD
			fill.Parent = back
			corner(fill, 4)
			label(r, q.got .. " / " .. q.need, UDim2.fromOffset(110, 14), 11, DIM).Position = UDim2.new(1, -118, 0, 20)
		else
			label(r, "→ " .. tostring(q.where), UDim2.fromOffset(110, 28), 11, DIM).Position = UDim2.new(1, -118, 0, 6)
		end
		if q.canTurnIn and q.ready then
			button(r, q.transferred and "Rendre ici" or "Rendre", UDim2.fromOffset(52, 26), BLUE, function()
				send("quete_rendre", { id = q.id })
			end).Position = UDim2.new(1, -118, 1, -32)
		elseif not q.canTurnIn and q.ready and q.kind ~= "apporter" then
			label(r, "Retourne à " .. tostring(q.where), UDim2.fromOffset(110, 26), 10, GREEN).Position = UDim2.new(1, -118, 1, -32)
		end
		button(r, "Lâcher", UDim2.fromOffset(52, 26), RED, function()
			send("quete_lacher", { id = q.id })
		end).Position = UDim2.new(1, -60, 1, -32)
	end
end

local function render(data)
	for _, c in body:GetChildren() do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	order = 0
	if data.village then
		header("🏘️  " .. data.village.name .. " · " .. tostring(data.village.from or "Tableau des quêtes"))
		if data.village.deserted then
			order += 1
			label(body, "Le village est déserté : plus personne pour donner du travail. Ses quêtes se rendent ailleurs.", UDim2.new(1, -8, 0, 34), 13, DIM).LayoutOrder = order
		elseif #data.village.offers == 0 then
			order += 1
			label(body, "Rien de plus pour l'instant. Reviens dans quelques jours.", UDim2.new(1, -8, 0, 22), 13, DIM).LayoutOrder = order
		end
		for _, q in data.village.offers do
			questRow(q, true)
		end
	else
		order += 1
		label(body, "Les quêtes se prennent au tableau des quêtes d'un village, ou en demandant du travail à un habitant.", UDim2.new(1, -8, 0, 34), 13, DIM).LayoutOrder = order
	end
	header("📜  Mes quêtes (" .. #data.actives .. ")")
	if #data.actives == 0 then
		order += 1
		label(body, "Aucune en cours. Libre à toi !", UDim2.new(1, -8, 0, 22), 13, DIM).LayoutOrder = order
	end
	for _, q in data.actives do
		questRow(q, false)
	end
end

local showPanel -- défini plus bas
Remotes:WaitForChild("Fx").OnClientEvent:Connect(function(kind, data)
	if kind == "quetes" and type(data) == "table" then
		render(data)
		-- ouvert depuis un tableau ou un habitant : le panneau s'affiche de lui-même
		if data.village and not panel.Visible and showPanel then
			showPanel()
		end
	end
end)

showPanel = function()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.min(1, (vp.X - 32) / 560, (vp.Y - 40) / 520)
	panel.Visible = true
end
local function toggle()
	if panel.Visible then
		panel.Visible = false
		return
	end
	showPanel()
	send("quetes")
end

local ouvrir = Instance.new("BindableEvent")
ouvrir.Name = "OuvrirQuetes"
ouvrir.Event:Connect(toggle)
ouvrir.Parent = player

require(script.Parent:WaitForChild("WindowNav")).watch(panel, close, function()
	panel.Visible = false
end)

-- panneau ouvert : se met à jour (on s'éloigne du tableau / de l'habitant → les offres disparaissent)
task.spawn(function()
	while true do
		task.wait(3)
		if panel.Visible then
			send("quetes")
		end
	end
end)
local _ = TweenService
