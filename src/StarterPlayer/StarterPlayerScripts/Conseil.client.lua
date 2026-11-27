-- Conseil du village (client) : panneau ouvert par le serveur (Menu kind = "conseil").
-- Maire, trésor, taxe du marché, candidats et soutiens, projets publics, registre public.
-- Séparé d'Interface (limite de 200 locales), même style « parchemin sombre ».

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local GOLD = Color3.fromRGB(232, 186, 60)
local TEXT = Color3.fromRGB(240, 230, 210)
local DIM = Color3.fromRGB(160, 148, 128)
local PANEL = Color3.fromRGB(24, 19, 15)
local ROW = Color3.fromRGB(40, 33, 26)
local GREEN = Color3.fromRGB(70, 140, 70)
local BLUE = Color3.fromRGB(60, 100, 160)

local gui = Instance.new("ScreenGui")
gui.Name = "Conseil"
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
	local b
	b = Composants.bouton({ Text = text, TextSize = 13, BackgroundColor3 = color, Size = size, Parent = parent }, function()
		b.Size = size - UDim2.fromOffset(4, 4)
		TweenService:Create(b, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = size }):Play()
		fn()
	end)
	corner(b)
	return b
end

local panel = Instance.new("Frame")
panel.Name = "Panneau"
panel.Size = UDim2.new(0, 520, 0, 460)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = PANEL
panel.Visible = false
panel.Parent = gui
corner(panel)
local st = Instance.new("UIStroke")
st.Color = Color3.fromRGB(176, 140, 72)
st.Thickness = 2.5
st.Parent = panel
-- tient sur un téléphone : on réduit si l'écran est étroit
local scale = Instance.new("UIScale")
scale.Parent = panel
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.min(1, (vp.X - 32) / 520, (vp.Y - 40) / 460)
end
fit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local title = Composants.titre({
	Text = "", TextSize = 20, TextColor3 = GOLD,
	Size = UDim2.new(1, -60, 0, 30), Position = UDim2.fromOffset(14, 8), Parent = panel,
})
local function dismiss()
	panel.Visible = false
end
local close = button(panel, "×", UDim2.fromOffset(28, 28), Color3.fromRGB(190, 60, 50), dismiss)
close.Position = UDim2.new(1, -36, 0, 8)
local WindowNav = require(script.Parent:WaitForChild("WindowNav"))
WindowNav.watch(panel, close, dismiss)
WindowNav.clavier(panel)

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
	f.Size = UDim2.new(1, -6, 0, h or 34)
	f.LayoutOrder = order
	f.Parent = body
	corner(f, 4)
	return f
end
local function section(text)
	order += 1
	local l = label(body, text, UDim2.new(1, -6, 0, 22), 14, GOLD, true)
	l.LayoutOrder = order
end

local current = nil
local function act(kind, extra)
	local data = { v = current.village }
	for k, x in extra or {} do
		data[k] = x
	end
	Remotes.Action:FireServer(kind, data)
end

local function render(d)
	current = d
	order = 0
	for _, c in body:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	title.Text = "🏛️  Conseil — " .. (d.name ~= "" and d.name or "village")
	local r0 = row(48)
	local l0 = label(r0, (d.maire and ("👑 Maire : " .. d.maire) or "👑 Pas de maire pour l'instant")
		.. "\n💰 Trésor : " .. d.tresor .. "   ·   🏷️ Taxe du marché : " .. d.taxe .. " %", UDim2.new(1, -16, 1, 0), 14, TEXT, true)
	l0.Position = UDim2.fromOffset(8, 0)
	local royaume = d.royaume
	if royaume then
		section("Royaume")
		local vassaux = royaume.vassaux or {}
		local names = #vassaux > 0 and table.concat(vassaux, ", ") or "Aucun"
		local detail = (royaume.nom or "Indépendant") .. "\nSuzerain · " .. (royaume.suzerain or "Aucun")
			.. "\nVassaux · " .. names .. "\nTribut · " .. math.floor((royaume.tribut or 0) * 100) .. " % des taxes"
		local r = row(84)
		r.AutomaticSize = Enum.AutomaticSize.Y
		local summary = label(r, detail, UDim2.new(1, -16, 0, 76), 13, TEXT)
		summary.AutomaticSize = Enum.AutomaticSize.Y
		summary.Position = UDim2.fromOffset(8, 0)
		if d.isMaire then
			section("Prêter allégeance à…")
			for _, choix in royaume.choix or {} do
				local choice = row(42)
				local name = choix.name .. (choix.maire and (" · " .. choix.maire) or "")
				button(choice, name, UDim2.new(1, -8, 1, -8), BLUE, function()
					act("pol_allegeance", { to = choix.v })
				end).Position = UDim2.fromOffset(4, 4)
			end
			if #(royaume.choix or {}) == 0 then section("Aucun conseil disponible.") end
			if royaume.suzerain then
				button(row(42), "Rompre l’allégeance", UDim2.new(1, -8, 1, -8), Color3.fromRGB(123, 61, 47), function()
					act("pol_allegeance")
				end).Position = UDim2.fromOffset(4, 4)
			end
		end
	end
	if not d.resident then
		local r = row(40)
		local l = label(r, "Tu n'habites pas ici : pour voter ou te présenter, il faut une parcelle près du village.", UDim2.new(1, -16, 1, 0), 12, DIM)
		l.Position = UDim2.fromOffset(8, 0)
	end

	section("🗳️ Candidats (un soutien par habitant ; décompte au lever du jour)")
	if #d.cands == 0 then
		local r = row(30)
		label(r, "  Personne ne se présente.", UDim2.new(1, 0, 1, 0), 12, DIM).Position = UDim2.fromOffset(8, 0)
	end
	for _, c in d.cands do
		local r = row(36)
		local l = label(r, (c.mine and "✅ " or "") .. c.name .. "  ·  " .. c.votes .. " voix", UDim2.new(1, -120, 1, 0), 13, TEXT, true)
		l.Position = UDim2.fromOffset(8, 0)
		if d.resident and not c.mine then
			local b = button(r, "Soutenir", UDim2.fromOffset(96, 28), BLUE, function()
				act("pol_vote", { c = c.uid })
			end)
			b.Position = UDim2.new(1, -102, 0, 4)
		end
	end
	if d.resident then
		local r = row(38)
		local b = button(r, d.candidat and "Retirer ma candidature" or "Me présenter", UDim2.new(1, -8, 1, -8), d.candidat and Color3.fromRGB(120, 70, 50) or GREEN, function()
			act("pol_candidat")
		end)
		b.Position = UDim2.fromOffset(4, 4)
	end

	section("🎁 Donner au trésor")
	local rd = row(38)
	for i, n in { 10, 50, 100, 500 } do
		local b = button(rd, n .. " 💰", UDim2.fromOffset(110, 28), Color3.fromRGB(150, 110, 40), function()
			act("pol_don", { n = n })
		end)
		b.Position = UDim2.fromOffset(4 + (i - 1) * 118, 5)
	end

	if d.isMaire then
		section("🏷️ Taxe du marché (ventes aux étals du village)")
		local rt = row(38)
		for i, t in { 0, 3, 5, 8, 10, 15 } do
			local b = button(rt, t .. " %", UDim2.fromOffset(72, 28), t == d.taxe and GOLD or Color3.fromRGB(60, 50, 40), function()
				act("pol_taxe", { t = t })
			end)
			b.Position = UDim2.fromOffset(4 + (i - 1) * 80, 5)
		end
	end
	section("🔨 Projets publics" .. (d.isMaire and "" or " (décidés par le maire)"))
	for _, p in d.projets do
		local r = row(48)
		local active = p.id == "ronde" and d.ronde and d.ronde >= d.day
		local l = label(r, p.name .. " — " .. p.cost .. " 💰" .. (active and ("  (en cours, jusqu'au jour " .. d.ronde .. ")") or "") .. "\n" .. p.desc,
			UDim2.new(1, d.isMaire and -120 or -16, 1, 0), 12, TEXT)
		l.Position = UDim2.fromOffset(8, 0)
		if d.isMaire then
			local b = button(r, "Lancer", UDim2.fromOffset(96, 30), d.tresor >= p.cost and GREEN or Color3.fromRGB(70, 60, 50), function()
				act("pol_projet", { id = p.id })
			end)
			b.Position = UDim2.new(1, -102, 0, 9)
		end
	end
	section("📜 Registre public")
	for i = #d.log, math.max(1, #d.log - 11), -1 do
		local e = d.log[i]
		local r = row(26)
		label(r, "Jour " .. e.day .. " · " .. e.text, UDim2.new(1, -16, 1, 0), 12, DIM).Position = UDim2.fromOffset(8, 0)
	end
end

Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or data.kind ~= "conseil" then
		return
	end
	render(data)
	if not panel.Visible then
		-- ouverture : petit « pop » (90 % → taille d'écran)
		fit()
		local target = scale.Scale
		scale.Scale = target * 0.9
		panel.Visible = true
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target }):Play()
	end
end)
