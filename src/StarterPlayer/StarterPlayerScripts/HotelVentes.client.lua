-- Hôtel des ventes (19/11) : fenêtre [F] des boîtes aux lettres, envoyée par Systemes/Ventes
-- (événement « HotelVentes »). Onglets Acheter / Vendre / Mes ventes ; recherche, filtres (objets,
-- équipement, enchères), tri, prix de référence (médiane des dernières ventes du monde).
-- Toutes les règles sont côté serveur : la fenêtre ne fait que demander.
-- Fermer : bouton, Échap ou B (manette).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HotelVentes", 60)
local action = ReplicatedStorage:WaitForChild("Remotes", 60) and ReplicatedStorage.Remotes:WaitForChild("Action", 60)
if not remote or not action then
	return
end
local okGear, Gear = pcall(require, ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Gear"))

local INK = Color3.fromRGB(58, 40, 26)
local PAPER = Color3.fromRGB(232, 218, 186)
local CARD = Color3.fromRGB(244, 233, 207)
local DIM = Color3.fromRGB(128, 108, 82)
local WOOD = Color3.fromRGB(110, 60, 40)
local GOLD = Color3.fromRGB(176, 126, 32)
local GREEN = Color3.fromRGB(70, 120, 60)

local data = nil
local tab = "acheter"
local filter = "tout"
local sortMode = 1
local SORTS = { "Prix ↑", "Prix ↓", "Nom", "Fin proche" }
local search = ""
local sel = nil -- vente : { kind = "item"|"gear", … }
local sellMode = "fixe"
local duree = 2

local function send(kind: string, d)
	action:FireServer(kind, d or {})
end

-- ---------------------------------------------------------------- cadre

local gui = Instance.new("ScreenGui")
gui.Name = "HotelVentes"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 21
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromScale(0.94, 0.86)
frame.BackgroundColor3 = PAPER
frame.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(760, 640)
limit.Parent = frame
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local border = Instance.new("UIStroke")
border.Color = WOOD
border.Thickness = 3
border.Parent = frame

local function label(parent, text, size, color, font)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text = text or ""
	t.TextSize = size or 14
	t.TextColor3 = color or INK
	t.Font = font or Enum.Font.Gotham
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextTruncate = Enum.TextTruncate.AtEnd
	t.Parent = parent
	return t
end

local function button(parent, text, color)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = color or WOOD
	b.Text = text
	b.TextColor3 = PAPER
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local function box(parent, placeholder, text)
	local b = Instance.new("TextBox")
	b.BackgroundColor3 = CARD
	b.PlaceholderText = placeholder or ""
	b.PlaceholderColor3 = DIM
	b.Text = text or ""
	b.TextColor3 = INK
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.ClearTextOnFocus = false
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	local s = Instance.new("UIStroke")
	s.Color = DIM
	s.Thickness = 1
	s.Parent = b
	return b
end

local title = label(frame, "🏷️ Hôtel des ventes", 24, INK, Enum.Font.Fantasy)
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.new(1, -200, 0, 32)
local goldLabel = label(frame, "", 16, GOLD, Enum.Font.GothamBold)
goldLabel.AnchorPoint = Vector2.new(1, 0)
goldLabel.Position = UDim2.new(1, -56, 0, 16)
goldLabel.Size = UDim2.fromOffset(140, 22)
goldLabel.TextXAlignment = Enum.TextXAlignment.Right

local close = button(frame, "X") -- « ✕ » : absent de la police (carré vide en capture)
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -10, 0, 10)
close.Size = UDim2.fromOffset(36, 36)
close.TextSize = 18
close:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)

local tabs = Instance.new("Frame")
tabs.BackgroundTransparency = 1
tabs.Position = UDim2.fromOffset(18, 48)
tabs.Size = UDim2.new(1, -36, 0, 32)
tabs.Parent = frame
local tl = Instance.new("UIListLayout")
tl.FillDirection = Enum.FillDirection.Horizontal
tl.Padding = UDim.new(0, 8)
tl.Parent = tabs

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.fromOffset(18, 88)
content.Size = UDim2.new(1, -36, 1, -100)
content.Parent = frame

local function clear(parent)
	for _, c in parent:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function scroller(parent, pos, size)
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.Position = pos
	s.Size = size
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = DIM
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.CanvasSize = UDim2.new()
	s.BorderSizePixel = 0
	s.Parent = parent
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = s
	return s
end

local function card(parent, h, order)
	local c = Instance.new("Frame")
	c.BackgroundColor3 = CARD
	c.Size = UDim2.new(1, -8, 0, h)
	c.LayoutOrder = order or 0
	c.Parent = parent
	Instance.new("UICorner", c).CornerRadius = UDim.new(0, 6)
	return c
end

local function timeLeft(s: number?): string
	if not s then
		return ""
	end
	if s <= 0 then
		return "terminée"
	end
	local h, m = math.floor(s / 3600), math.floor(s % 3600 / 60)
	return h > 0 and string.format("%d h %02d", h, m) or string.format("%d min", math.max(1, m))
end

local function rarityColor(r: number?): Color3
	if okGear and r and Gear.RARITIES[r] then
		return Gear.RARITIES[r].color
	end
	return INK
end

-- ---------------------------------------------------------------- onglets

local render

local function rowPrice(r): number
	if r.mode == "enchere" then
		return r.bid or r.price
	end
	return r.price
end

local buildList

local function acheter()
	local bar = Instance.new("Frame")
	bar.BackgroundTransparency = 1
	bar.Size = UDim2.new(1, 0, 0, 32)
	bar.Parent = content
	local q = box(bar, "🔍 Chercher un objet…", search)
	q.Size = UDim2.new(0.34, 0, 1, 0)
	q:GetPropertyChangedSignal("Text"):Connect(function()
		search = q.Text
		buildList()
	end)
	local x = 0.36
	for _, f in { { "tout", "Tout" }, { "item", "Objets" }, { "gear", "Équipement" }, { "enchere", "Enchères" } } do
		local b = button(bar, f[2], filter == f[1] and GREEN or WOOD)
		b.Position = UDim2.new(x, 0, 0, 0)
		b.Size = UDim2.new(0.12, -4, 1, 0)
		b.TextSize = 12
		b.Activated:Connect(function()
			filter = f[1]
			render()
		end)
		x += 0.12
	end
	local sb = button(bar, SORTS[sortMode], DIM)
	sb.Position = UDim2.new(0.86, 0, 0, 0)
	sb.Size = UDim2.new(0.14, 0, 1, 0)
	sb.TextSize = 12
	sb.Activated:Connect(function()
		sortMode = sortMode % #SORTS + 1
		render()
	end)
	buildList()
end

function buildList()
	local old = content:FindFirstChild("Liste")
	if old then
		old:Destroy()
	end
	local list = scroller(content, UDim2.fromOffset(0, 40), UDim2.new(1, 0, 1, -40))
	list.Name = "Liste"
	local rows = {}
	local needle = string.lower(search)
	for _, r in data.rows do
		local okF = filter == "tout" or (filter == "enchere" and r.mode == "enchere") or filter == r.kind
		local hay = string.lower((r.name or "") .. " " .. (r.label or ""))
		if okF and (needle == "" or string.find(hay, needle, 1, true)) then
			table.insert(rows, r)
		end
	end
	table.sort(rows, function(a, b)
		if sortMode == 1 then
			return rowPrice(a) / (a.n or 1) < rowPrice(b) / (b.n or 1)
		elseif sortMode == 2 then
			return rowPrice(a) / (a.n or 1) > rowPrice(b) / (b.n or 1)
		elseif sortMode == 3 then
			return (a.name or "") < (b.name or "")
		end
		return (a.left or math.huge) < (b.left or math.huge)
	end)
	if #rows == 0 then
		local t = label(list, "Rien en vente pour l'instant" .. (needle ~= "" and " qui corresponde à ta recherche." or "."), 15, DIM)
		t.Size = UDim2.new(1, 0, 0, 30)
	end
	for i, r in rows do
		local c = card(list, r.kind == "gear" and 70 or 56, i)
		local name = label(c, (r.icon or "") .. " " .. (r.name or "?") .. ((r.n or 1) > 1 and (" ×" .. r.n) or ""), 15, r.kind == "gear" and rarityColor(r.rarity) or INK, Enum.Font.GothamBold)
		name.Position = UDim2.fromOffset(10, 6)
		name.Size = UDim2.new(0.6, -10, 0, 20)
		local info
		if r.mode == "enchere" then
			info = string.format("🔨 %s · %s · reste %s", r.bid and ("offre " .. r.bid .. " 💰 (" .. tostring(r.bidder) .. ")") or ("départ " .. r.price .. " 💰"),
				"min " .. tostring(r.minBid), timeLeft(r.left))
		else
			info = string.format("%d 💰%s", r.price, (r.n or 1) > 1 and string.format(" (%d / u)", math.floor(r.price / r.n + 0.5)) or "")
		end
		if r.ref then
			info ..= " · réf. " .. r.ref .. " / u"
		end
		info ..= " · " .. tostring(r.seller or "?")
		local sub = label(c, info, 12, DIM)
		sub.Position = UDim2.fromOffset(10, 28)
		sub.Size = UDim2.new(0.66, -10, 0, 18)
		if r.label then
			local g = label(c, r.label, 11, DIM)
			g.Position = UDim2.fromOffset(10, 48)
			g.Size = UDim2.new(1, -20, 0, 16)
		end
		if r.mine then
			local b = button(c, "Retirer", DIM)
			b.AnchorPoint = Vector2.new(1, 0)
			b.Position = UDim2.new(1, -8, 0, 8)
			b.Size = UDim2.new(0.2, 0, 0, 30)
			b.Activated:Connect(function()
				if r.src == "poste" or r.mode == "fixe" then
					send("hdv_acheter", { id = r.id, src = r.src })
				else
					send("hdv_retirer", { id = r.id })
				end
			end)
		elseif r.mode == "enchere" then
			local amount = box(c, "offre", tostring(r.minBid or ""))
			amount.AnchorPoint = Vector2.new(1, 0)
			amount.Position = UDim2.new(0.8, -12, 0, 8)
			amount.Size = UDim2.new(0.12, 0, 0, 30)
			local b = button(c, r.mineBid and "En tête" or "Enchérir", r.mineBid and GREEN or GOLD)
			b.AnchorPoint = Vector2.new(1, 0)
			b.Position = UDim2.new(1, -8, 0, 8)
			b.Size = UDim2.new(0.18, 0, 0, 30)
			b.Activated:Connect(function()
				send("hdv_encherir", { id = r.id, amount = tonumber(amount.Text) })
			end)
		else
			local b = button(c, "Acheter", GREEN)
			b.AnchorPoint = Vector2.new(1, 0)
			b.Position = UDim2.new(1, -8, 0, 8)
			b.Size = UDim2.new(0.2, 0, 0, 30)
			b.Activated:Connect(function()
				send("hdv_acheter", { id = r.id, src = r.src })
			end)
		end
	end
end

local function vendre()
	local left = scroller(content, UDim2.fromOffset(0, 0), UDim2.new(0.5, -8, 1, 0))
	local order = 0
	local function head(text)
		order += 1
		local t = label(left, text, 14, WOOD, Enum.Font.GothamBold)
		t.Size = UDim2.new(1, 0, 0, 22)
		t.LayoutOrder = order
	end
	head("Équipement du sac (" .. #data.gear .. ")")
	for _, g in data.gear do
		order += 1
		local c = card(left, 40, order)
		local b = Instance.new("TextButton")
		b.BackgroundTransparency = 1
		b.Size = UDim2.fromScale(1, 1)
		b.Text = ""
		b.Parent = c
		local t = label(c, "🛡️ " .. g.name, 14, rarityColor(g.rarity), Enum.Font.GothamBold)
		t.Position = UDim2.fromOffset(8, 2)
		t.Size = UDim2.new(1, -16, 0, 18)
		local s = label(c, g.label, 11, DIM)
		s.Position = UDim2.fromOffset(8, 20)
		s.Size = UDim2.new(1, -16, 0, 16)
		if sel and sel.kind == "gear" and sel.idx == g.idx then
			c.BackgroundColor3 = Color3.fromRGB(214, 228, 196)
		end
		b.Activated:Connect(function()
			sel = { kind = "gear", idx = g.idx, name = g.name, label = g.label }
			render()
		end)
	end
	head("Objets du sac (" .. #data.bag .. ")")
	for _, it in data.bag do
		order += 1
		local c = card(left, 34, order)
		local b = Instance.new("TextButton")
		b.BackgroundTransparency = 1
		b.Size = UDim2.fromScale(1, 1)
		b.Text = ""
		b.Parent = c
		local t = label(c, it.icon .. " " .. it.name .. " ×" .. it.n .. (it.ref and ("  · réf. " .. it.ref .. " / u") or ""), 13)
		t.Position = UDim2.fromOffset(8, 0)
		t.Size = UDim2.new(1, -16, 1, 0)
		if sel and sel.kind == "item" and sel.item == it.item then
			c.BackgroundColor3 = Color3.fromRGB(214, 228, 196)
		end
		b.Activated:Connect(function()
			sel = { kind = "item", item = it.item, name = it.name, icon = it.icon, n = it.n, ref = it.ref, value = it.value }
			render()
		end)
	end
	-- panneau de mise en vente
	local p = Instance.new("Frame")
	p.BackgroundColor3 = CARD
	p.Position = UDim2.new(0.5, 8, 0, 0)
	p.Size = UDim2.new(0.5, -8, 1, 0)
	p.Parent = content
	Instance.new("UICorner", p).CornerRadius = UDim.new(0, 8)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop = UDim.new(0, 12), UDim.new(0, 12), UDim.new(0, 10)
	pad.Parent = p
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = p
	if not sel then
		local t = label(p, "Choisis à gauche ce que tu veux vendre.", 14, DIM)
		t.Size = UDim2.new(1, 0, 0, 40)
		t.TextWrapped = true
		return
	end
	local t = label(p, sel.kind == "gear" and ("🛡️ " .. sel.name) or (sel.icon .. " " .. sel.name), 16, INK, Enum.Font.GothamBold)
	t.Size = UDim2.new(1, 0, 0, 22)
	t.LayoutOrder = 1
	local hint = label(p, sel.kind == "gear" and sel.label or ((sel.ref and ("Prix de référence : " .. sel.ref .. " 💰 / u") or "Pas encore de vente de référence") .. (sel.value and (" · valeur marchande " .. sel.value .. " 💰") or "")), 12, DIM)
	hint.Size = UDim2.new(1, 0, 0, 32)
	hint.TextWrapped = true
	hint.LayoutOrder = 2
	local qty
	if sel.kind == "item" then
		qty = box(p, "quantité (max " .. sel.n .. ")", tostring(sel.n))
		qty.Size = UDim2.new(1, 0, 0, 32)
		qty.LayoutOrder = 3
	end
	local modes = Instance.new("Frame")
	modes.BackgroundTransparency = 1
	modes.Size = UDim2.new(1, 0, 0, 32)
	modes.LayoutOrder = 4
	modes.Parent = p
	for i, m in { { "fixe", "Prix fixe" }, { "enchere", "Enchère" } } do
		local b = button(modes, m[2], sellMode == m[1] and GREEN or WOOD)
		b.Position = UDim2.new((i - 1) * 0.5, i == 1 and 0 or 4, 0, 0)
		b.Size = UDim2.new(0.5, -4, 1, 0)
		b.Activated:Connect(function()
			sellMode = m[1]
			render()
		end)
	end
	if sellMode == "enchere" then
		local d = Instance.new("Frame")
		d.BackgroundTransparency = 1
		d.Size = UDim2.new(1, 0, 0, 30)
		d.LayoutOrder = 5
		d.Parent = p
		for i, txt in { "2 h", "12 h", "24 h" } do
			local b = button(d, txt, duree == i and GREEN or DIM)
			b.Position = UDim2.new((i - 1) / 3, 2, 0, 0)
			b.Size = UDim2.new(1 / 3, -4, 1, 0)
			b.TextSize = 12
			b.Activated:Connect(function()
				duree = i
				render()
			end)
		end
	end
	local price = box(p, sellMode == "enchere" and "prix de départ (tout le lot)" or "prix (tout le lot)", "")
	price.Size = UDim2.new(1, 0, 0, 32)
	price.LayoutOrder = 6
	local fee = label(p, "Frais : 2 % du prix, payés à la mise en vente.", 12, DIM)
	fee.Size = UDim2.new(1, 0, 0, 18)
	fee.LayoutOrder = 7
	price:GetPropertyChangedSignal("Text"):Connect(function()
		local v = tonumber(price.Text)
		fee.Text = v and ("Frais : " .. math.max(1, math.floor(v * data.fee)) .. " 💰 (2 %)") or "Frais : 2 % du prix, payés à la mise en vente."
	end)
	local go = button(p, sellMode == "enchere" and "🔨 Mettre aux enchères" or "🏷️ Mettre en vente", GREEN)
	go.Size = UDim2.new(1, 0, 0, 38)
	go.LayoutOrder = 8
	go.Activated:Connect(function()
		local v = tonumber(price.Text)
		if not v or v < 1 then
			fee.Text = "Indique un prix."
			return
		end
		send("hdv_vendre", {
			kind = sel.kind, item = sel.item, idx = sel.idx, name = sel.name, n = qty and tonumber(qty.Text) or 1,
			price = v, mode = sellMode, duree = duree,
		})
		sel = nil
	end)
end

local function mesVentes()
	local list = scroller(content, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1))
	local n = 0
	for _, r in data.rows do
		if r.mine or r.mineBid then
			n += 1
			local c = card(list, 50, n)
			local t = label(c, (r.icon or "") .. " " .. (r.name or "?") .. ((r.n or 1) > 1 and (" ×" .. r.n) or ""), 14, INK, Enum.Font.GothamBold)
			t.Position = UDim2.fromOffset(10, 4)
			t.Size = UDim2.new(0.7, 0, 0, 20)
			local s
			if r.mineBid then
				s = "Tu es en tête : " .. r.bid .. " 💰 · reste " .. timeLeft(r.left)
			elseif r.mode == "enchere" then
				s = (r.bid and ("Offre " .. r.bid .. " 💰 de " .. tostring(r.bidder)) or ("Pas d'offre (départ " .. r.price .. " 💰)")) .. " · reste " .. timeLeft(r.left)
			else
				s = "Prix fixe " .. r.price .. " 💰"
			end
			local sl = label(c, s, 12, DIM)
			sl.Position = UDim2.fromOffset(10, 26)
			sl.Size = UDim2.new(0.75, 0, 0, 18)
			if r.mine and not r.bid then
				local b = button(c, "Retirer", DIM)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -8, 0.5, 0)
				b.Size = UDim2.new(0.2, 0, 0, 30)
				b.Activated:Connect(function()
					if r.src == "poste" or r.mode == "fixe" then
						send("hdv_acheter", { id = r.id, src = r.src })
					else
						send("hdv_retirer", { id = r.id })
					end
				end)
			end
		end
	end
	if n == 0 then
		local t = label(list, "Tu n'as rien en vente et aucune enchère en cours.", 14, DIM)
		t.Size = UDim2.new(1, 0, 0, 30)
	end
	local note = label(list, "L'or des ventes et les objets gagnés arrivent au courrier (boîte aux lettres, [E]).", 12, DIM)
	note.Size = UDim2.new(1, 0, 0, 24)
	note.LayoutOrder = 9999
end

function render()
	if not data then
		return
	end
	goldLabel.Text = tostring(data.gold or 0) .. " 💰"
	clear(tabs)
	for _, t in { { "acheter", "Acheter" }, { "vendre", "Vendre" }, { "mes", "Mes ventes" } } do
		local b = button(tabs, t[2], tab == t[1] and GREEN or WOOD)
		b.Size = UDim2.fromOffset(120, 32)
		b.Activated:Connect(function()
			tab = t[1]
			render()
		end)
	end
	clear(content)
	if tab == "acheter" then
		acheter()
	elseif tab == "vendre" then
		vendre()
	else
		mesVentes()
	end
end

local function hide()
	gui.Enabled = false
end
close.Activated:Connect(hide)
UserInputService.InputBegan:Connect(function(input)
	if gui.Enabled and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then
		hide()
	end
end)

remote.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or type(d.rows) ~= "table" then
		return
	end
	data = d
	gui.Enabled = true
	render()
end)
