-- Tableau d'affichage (client) : Menu kind = "activites". Liste des événements du village
-- (inscription, classement en direct), création (type, début, durée, cagnotte), annulation,
-- jugement d'un rassemblement par son organisateur.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))

local GOLD = Color3.fromRGB(232, 186, 60)
local TEXT = Color3.fromRGB(240, 230, 210)
local DIM = Color3.fromRGB(160, 148, 128)
local ROW = Color3.fromRGB(40, 33, 26)
local OFF = Color3.fromRGB(60, 50, 40)
local GREEN = Color3.fromRGB(70, 140, 70)
local RED = Color3.fromRGB(170, 70, 55)

local gui = Instance.new("ScreenGui")
gui.Name = "Tableau"
gui.ResetOnSpawn = false
gui.DisplayOrder = 15
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = p
end
local function label(parent, text, size, ts, color, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = Composants.texteCompatible(text)
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
	local b
	b = Composants.bouton({
		Text = text, TextSize = 13, BackgroundColor3 = color, Size = size, Parent = parent,
	}, function()
		b.Size = size - UDim2.fromOffset(4, 4)
		TweenService:Create(b, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = size }):Play()
		fn()
	end)
	corner(b)
	return b
end

local panel = Instance.new("Frame")
panel.Name = "Panneau"
panel.Size = UDim2.fromOffset(520, 470)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(24, 19, 15)
panel.Visible = false
panel.Parent = gui
corner(panel)
local st = Instance.new("UIStroke")
st.Color = Color3.fromRGB(176, 140, 72)
st.Thickness = 2.5
st.Parent = panel
local scale = Instance.new("UIScale")
scale.Parent = panel
local function fit()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.min(1, (vp.X - 32) / 520, (vp.Y - 40) / 470)
end
Composants.titre({
	Text = "Tableau d'affichage", TextSize = 20, TextColor3 = GOLD,
	Size = UDim2.new(1, -60, 0, 30), Position = UDim2.fromOffset(14, 8), Parent = panel,
})
local function dismiss()
	panel.Visible = false
end
local close = button(panel, "×", UDim2.fromOffset(28, 28), Color3.fromRGB(190, 60, 50), dismiss)
close.Position = UDim2.new(1, -36, 0, 8)
require(script.Parent:WaitForChild("WindowNav")).watch(panel, close, dismiss)

local body = Instance.new("ScrollingFrame")
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 4
body.Size = UDim2.new(1, -20, 1, -50)
body.Position = UDim2.fromOffset(10, 44)
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = body

local order = 0
local function row(h)
	order += 1
	local f = Instance.new("Frame")
	f.BackgroundColor3 = ROW
	f.Size = UDim2.new(1, -6, 0, h)
	f.LayoutOrder = order
	f.Parent = body
	corner(f, 4)
	return f
end
local function section(text)
	order += 1
	label(body, text, UDim2.new(1, -6, 0, 22), 14, GOLD, true).LayoutOrder = order
end

local current
local form = { kind = "peche", delay = 60, dur = 60, prize = 100 }
local KIND_LIST = { { "peche", "🎣 Pêche" }, { "recolte", "🌾 Récolte" }, { "minage", "⛏️ Minage" }, { "bucheronnage", "⚒️ Bûcheronnage" }, { "construction", "🏠 Construction" }, { "libre", "🎪 Rassemblement" }, { "course", "🏇 Course" }, { "cuisine", "🍲 Cuisine" }, { "chasse", "🏹 Chasse" } }

local function act(kind, data)
	data.v = current.village
	Remotes.Action:FireServer(kind, data)
end

local render
local function choices(r, y, values, key, fmt)
	for i, v in values do
		local texte = fmt(v)
		local b = button(r, texte, UDim2.fromOffset(76, 26), OFF, function()
			form[key] = v
			render(current)
		end)
		Composants.etatBouton(b, texte, form[key] == v and "selectionne" or nil, OFF)
		b.Position = UDim2.fromOffset(120 + (i - 1) * 80, y)
	end
end

render = function(d)
	current = d
	order = 0
	for _, c in body:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	section("Au programme")
	if #d.rows == 0 then
		label(row(30), "  Rien d'affiché pour l'instant. Organise quelque chose !", UDim2.new(1, 0, 1, 0), 12, DIM).Position = UDim2.fromOffset(8, 0)
	end
	for _, a in d.rows do
		local when = a.state == "annonce" and ("dans " .. a.startsIn .. " min") or (a.state == "encours" and ("en cours · fin dans " .. a.endsIn .. " min") or "à juger")
		local top = {}
		for i = 1, math.min(3, #a.parts) do
			table.insert(top, a.parts[i].name .. (a.kind ~= "libre" and (" " .. a.parts[i].score) or ""))
		end
		local r = row(a.mine and a.state == "jugement" and 70 + #a.parts * 30 or 70)
		label(r, a.icon .. " " .. a.title .. "  ·  " .. when .. "\n🏆 " .. a.prize .. " 💰  ·  " .. #a.parts .. " inscrit(s)" .. (#top > 0 and ("  ·  " .. table.concat(top, ", ")) or ""),
			UDim2.new(1, -130, 0, 64), 12, TEXT).Position = UDim2.fromOffset(8, 3)
		if a.mine and a.state == "annonce" then
			button(r, "Annuler", UDim2.fromOffset(110, 30), RED, function()
				act("act_annuler", { id = a.id })
			end).Position = UDim2.new(1, -116, 0, 18)
		elseif not a.mine and a.state ~= "jugement" then
			button(r, a.joined and "Me retirer" or "M'inscrire", UDim2.fromOffset(110, 30), a.joined and OFF or GREEN, function()
				act("act_inscrire", { id = a.id })
			end).Position = UDim2.new(1, -116, 0, 18)
		end
		if a.mine and a.state == "jugement" then
			for i, p in a.parts do
				local b = button(r, "🏆 " .. p.name, UDim2.new(1, -16, 0, 26), GREEN, function()
					act("act_juger", { id = a.id, w = p.uid })
				end)
				b.Position = UDim2.fromOffset(8, 66 + (i - 1) * 30)
			end
		end
	end
	section("Organiser")
	local kinds = type(d.kinds) == "table" and d.kinds or KIND_LIST
	local first, selected
	for _, kind in kinds do
		first = first or kind[1]
		if form.kind == kind[1] then selected = kind[1] end
	end
	form.kind = selected or first
	local r1 = row(math.max(36, math.ceil(#kinds / 3) * 30 + 6))
	label(r1, "Type", UDim2.fromOffset(100, 36), 13, TEXT, true).Position = UDim2.fromOffset(8, 0)
	for i, k in kinds do
		local b = button(r1, k[2], UDim2.fromOffset(118, 26), OFF, function()
			form.kind = k[1]
			render(current)
		end)
		Composants.etatBouton(b, k[2], form.kind == k[1] and "selectionne" or nil, OFF)
		b.TextTruncate = Enum.TextTruncate.AtEnd
		b.Position = UDim2.fromOffset(120 + ((i - 1) % 3) * 122, 5 + ((i - 1) // 3) * 30)
	end
	local r2 = row(36)
	label(r2, "Début dans", UDim2.fromOffset(110, 36), 13, TEXT, true).Position = UDim2.fromOffset(8, 0)
	choices(r2, 5, { 15, 60, 120, 240 }, "delay", function(v)
		return v .. " min"
	end)
	local r3 = row(36)
	label(r3, "Durée", UDim2.fromOffset(110, 36), 13, TEXT, true).Position = UDim2.fromOffset(8, 0)
	choices(r3, 5, { 15, 30, 60, 120 }, "dur", function(v)
		return v .. " min"
	end)
	local r4 = row(36)
	label(r4, "Cagnotte", UDim2.fromOffset(110, 36), 13, TEXT, true).Position = UDim2.fromOffset(8, 0)
	choices(r4, 5, { 0, 50, 200, 1000 }, "prize", function(v)
		return v .. " 💰"
	end)
	local r5 = row(52)
	label(r5, "La cagnotte est bloquée tout de suite (tu as " .. d.gold .. " 💰) et rendue si tu annules ou si personne ne gagne.",
		UDim2.new(1, -150, 1, 0), 11, DIM).Position = UDim2.fromOffset(8, 0)
	local submit = button(r5, "Afficher", UDim2.fromOffset(130, 36), GREEN, function()
		if form.kind then
			act("act_creer", { kind = form.kind, delay = form.delay, dur = form.dur, prize = form.prize })
		end
	end)
	if not form.kind then Composants.etatBouton(submit, "Afficher", "verrouille") end
	submit.Position = UDim2.new(1, -136, 0, 8)
end

Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or data.kind ~= "activites" then
		return
	end
	render(data)
	if not panel.Visible then
		fit()
		local target = scale.Scale
		scale.Scale = target * 0.9
		panel.Visible = true
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target }):Play()
	end
end)
