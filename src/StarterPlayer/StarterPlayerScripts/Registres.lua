-- Fenêtres des registres et du menu d'un joueur. Les listes affichées viennent de Menu.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local C = require(script.Parent:WaitForChild("ComposantsInterface"))
local WindowNav = require(script.Parent:WaitForChild("WindowNav"))
local MiseEnPage = require(script.Parent:WaitForChild("MiseEnPage"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Action = remotes:WaitForChild("Action")
local Registres = {}

local GOLD = Color3.fromRGB(239, 199, 116)
local TEXT = Color3.fromRGB(247, 231, 202)
local DIM = Color3.fromRGB(206, 182, 148)
local ROW = Color3.fromRGB(54, 42, 32)
local GREEN = Color3.fromRGB(59, 100, 63)
local RED = Color3.fromRGB(127, 58, 47)
local PAPER = Color3.fromRGB(234, 209, 158)
local INK = Color3.fromRGB(58, 39, 28)

local gui = C.creer("ScreenGui", {
	Name = "Registres", DisplayOrder = 26, ResetOnSpawn = false,
	Parent = player:WaitForChild("PlayerGui"),
})

local function corner(pixels)
	return C.creer("UICorner", { CornerRadius = UDim.new(0, pixels) })
end

local function padding(x, y)
	return C.creer("UIPadding", {
		PaddingTop = UDim.new(0, y), PaddingBottom = UDim.new(0, y),
		PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, x),
	})
end

local function list(gap)
	return C.creer("UIListLayout", {
		Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function append(parent, class, props, children)
	props.Parent = parent
	props.LayoutOrder = #parent:GetChildren()
	return C.creer(class, props, children)
end

local function text(parent, value, size, color, font)
	return append(parent, "TextLabel", {
		Text = value, TextSize = size or 17, TextColor3 = color or TEXT, Font = font or Enum.Font.Gotham,
		BackgroundTransparency = 1, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left,
	})
end

local function button(parent, name, color, callback)
	local b = C.bouton({
		Text = name, TextSize = 16, BackgroundColor3 = color or ROW,
		Size = UDim2.new(1, 0, 0, 43), Selectable = true, Parent = parent,
		LayoutOrder = #parent:GetChildren(),
	}, callback, { corner(6) })
	return b
end

local function card(parent, color)
	return append(parent, "Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = color or ROW, BorderSizePixel = 0,
	}, { corner(5), padding(12, 10), list(6) })
end

local function field(parent, hint, value, height, multiline)
	return append(parent, "TextBox", {
		Text = value or "", PlaceholderText = hint, PlaceholderColor3 = DIM, TextColor3 = TEXT,
		Font = Enum.Font.Gotham, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		BackgroundColor3 = ROW, ClearTextOnFocus = false, Selectable = true,
		MultiLine = multiline == true, TextWrapped = multiline == true,
		Size = UDim2.new(1, 0, 0, height or 43),
	}, { corner(6), padding(10, 6) })
end

local function send(kind, payload)
	Action:FireServer(kind, payload or {})
end

local active, source, pending
local current, view, selectedItem
local drafts = { n = "", prix = "", titre = "", texte = "" }
local inventory = {}
local articleEnCours, commandeEnCours

local panel = C.creer("Frame", {
	Name = "Registre", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(510, 520), BackgroundColor3 = Color3.fromRGB(29, 23, 18),
	Visible = false, Parent = gui,
}, { corner(10) })
local heading = C.titre({
	Size = UDim2.new(1, -70, 0, 40), Position = UDim2.fromOffset(16, 9), Parent = panel,
})
local function close()
	panel.Visible = false
	active, source, pending, current, view = nil, nil, nil, nil, nil
	commandeEnCours = nil
end
local quit = C.bouton({
	Text = "×", BackgroundColor3 = RED, TextSize = 20, Size = UDim2.fromOffset(40, 38),
	Position = UDim2.new(1, -50, 0, 9), Parent = panel,
}, close, { corner(6) })
local body = C.creer("ScrollingFrame", {
	Name = "Contenu", Position = UDim2.fromOffset(14, 55), Size = UDim2.new(1, -28, 1, -69),
	BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 5, ScrollBarImageColor3 = GOLD, Parent = panel,
}, { list(8), padding(7, 2) })
WindowNav.watch(panel, quit, close)
WindowNav.clavier(panel)
MiseEnPage.bind(panel)

local function clear()
	for _, child in body:GetChildren() do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function show(title)
	heading.Text = title
	body.CanvasPosition = Vector2.zero
	panel.Visible = true
end

local function focus(control)
	local selected = GuiService.SelectedObject
	if UserInputService:GetLastInputType().Name:match("^Gamepad") or (selected and selected:IsDescendantOf(panel)) then
		GuiService.SelectedObject = control or quit
	end
end

function Registres.ouvrir(kind, parent)
	source = parent
	pending = kind
	send(kind)
end

local function refresh()
	send(active)
end

local function own(uid)
	return tostring(uid) == tostring(player.UserId)
end

local function itemInfo(id)
	return config.ITEMS[id] or { name = id }
end

local function ids(entries)
	local known = {}
	for _, item in entries or {} do known[item.id] = true end
	return known
end

local render
local function changeView(nextView)
	view = nextView
	body.CanvasPosition = Vector2.zero
	local focused = GuiService.SelectedObject
	local hadFocus = focused and focused:IsDescendantOf(panel)
	render()
	if hadFocus then GuiService.SelectedObject = quit end
end

local function contractForm()
	button(body, "‹ Commandes", nil, function() changeView(nil) end)
	local info = selectedItem and itemInfo(selectedItem)
	button(body, info and ((info.icon or "") .. "  " .. info.name) or "Choisir un objet du sac", nil, function()
		changeView("objets")
	end)
	local qty = field(body, "Quantité demandée", drafts.n)
	local price = field(body, "Prix total en or", drafts.prix)
	qty:GetPropertyChangedSignal("Text"):Connect(function() drafts.n = qty.Text end)
	price:GetPropertyChangedSignal("Text"):Connect(function() drafts.prix = price.Text end)
	local errorText = text(body, "", 14, GOLD)
	button(body, "Publier la commande", GREEN, function()
		if commandeEnCours and os.clock() - commandeEnCours.t < 3 then return end
		local n, prix = tonumber(qty.Text), tonumber(price.Text)
		if not selectedItem or not n or not prix or n < 1 or prix < 1 or n % 1 ~= 0 or prix % 1 ~= 0 then
			errorText.Text = "Choisis un objet, puis saisis deux nombres entiers positifs."
			return
		end
		commandeEnCours = { t = os.clock(), known = ids(current.contrats), item = selectedItem, n = n, prix = prix }
		send("contrat_publier", { item = selectedItem, n = n, prix = prix })
	end)
end

local function contractItems()
	button(body, "‹ Publication", nil, function() changeView("publier") end)
	local ids = {}
	for id, amount in inventory do
		if id ~= "gold" and amount > 0 and config.ITEMS[id] then table.insert(ids, id) end
	end
	table.sort(ids, function(a, b) return itemInfo(a).name < itemInfo(b).name end)
	if #ids == 0 then text(body, "Ton sac ne contient aucun objet à choisir.", 15, DIM) end
	for _, id in ids do
		local info = itemInfo(id)
		button(body, (info.icon or "") .. "  " .. info.name .. "  ×" .. inventory[id], nil, function()
			selectedItem = id
			changeView("publier")
		end)
	end
end

local function contracts()
	if view == "publier" then contractForm() return end
	if view == "objets" then contractItems() return end
	button(body, "Publier", GREEN, function() changeView("publier") end)
	if #(current.contrats or {}) == 0 then text(body, "Aucune commande en cours.", 15, DIM) end
	for _, order in current.contrats or {} do
		local row = card(body)
		text(row, (order.icon or "") .. "  " .. (order.label or order.item) .. " ×" .. order.n, 18, GOLD, Enum.Font.GothamBold)
		text(row, order.name .. "  ·  " .. order.prix .. " or au total  ·  " .. order.reste .. " j restants", 15, DIM)
		local mine = own(order.uid)
		button(row, mine and "Retirer" or "Livrer", mine and RED or GREEN, function()
			send(mine and "contrat_retirer" or "contrat_livrer", { id = order.id })
		end)
	end
end

local function limit(box, max, key)
	local count = text(body, "", 14, DIM)
	local function update()
		local value = box.Text
		local offset = utf8.len(value) and utf8.offset(value, max + 1)
		if offset then value = string.sub(value, 1, offset - 1) end
		drafts[key] = value
		if box.Text ~= value then box.Text = value end
		count.Text = (utf8.len(value) or 0) .. " / " .. max
	end
	box:GetPropertyChangedSignal("Text"):Connect(update)
	update()
end

local function gazetteForm()
	button(body, "‹ Gazette", nil, function() changeView(nil) end)
	limit(field(body, "Titre", drafts.titre), 60, "titre")
	limit(field(body, "Article", drafts.texte, 132, true), 600, "texte")
	text(body, "1 papier et 1 encre", 15, DIM)
	local info = text(body, "", 14, GOLD)
	button(body, "Publier l’article", GREEN, function()
		local function length(value)
			return utf8.len(value:match("^%s*(.-)%s*$")) or 0
		end
		if length(drafts.titre) < 3 or length(drafts.texte) < 3 then
			info.Text = "Saisis un titre et un article d’au moins trois caractères."
			return
		end
		if articleEnCours and os.clock() - articleEnCours.t < 5 then return end
		articleEnCours = { t = os.clock(), known = ids(current.articles), titre = drafts.titre, texte = drafts.texte }
		send("gazette_ecrire", { titre = drafts.titre, texte = drafts.texte })
	end)
end

local function gazette()
	if view == "ecrire" then gazetteForm() return end
	button(body, "Écrire", GREEN, function() changeView("ecrire") end)
	button(body, "Actualiser", nil, refresh)
	if #(current.articles or {}) == 0 then
		text(card(body, PAPER), "Aucun article publié.", 18, INK, Enum.Font.Garamond)
	end
	for _, article in current.articles or {} do
		local page = card(body, PAPER)
		text(page, article.titre, 26, INK, Enum.Font.Garamond)
		text(page, article.auteur .. "  ·  Jour " .. article.jour .. "  ·  " .. (article.village or ""), 17, INK, Enum.Font.Garamond)
		append(page, "Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundColor3 = INK })
		text(page, article.texte, 21, INK, Enum.Font.Garamond)
		if own(article.uid) then
			button(page, "Retirer", RED, function()
				send("gazette_retirer", { id = article.id })
				refresh()
			end)
		end
	end
end

local function records()
	for _, record in current.records or {} do
		local entry = card(body)
		text(entry, record.label, 19, GOLD, Enum.Font.Garamond)
		text(entry, record.name and (record.name .. "  ·  " .. tostring(record.value)) or "À établir", 16, DIM)
	end
	if #(current.records or {}) == 0 then text(body, "Aucun record inscrit.", 15, DIM) end
end

local function oeuvres()
	for _, work in current.oeuvres or {} do
		local entry = card(body)
		text(entry, work.name, 20, GOLD, Enum.Font.GothamBold)
		text(entry, work.voie .. "  ·  " .. work.skill .. " " .. work.level .. "  ·  « " .. work.title .. " »", 15, DIM)
		local ratio = math.clamp(work.have / math.max(1, work.total), 0, 1)
		local track = append(entry, "Frame", { Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = Color3.fromRGB(28, 21, 17), BorderSizePixel = 0 }, { corner(5) })
		C.creer("Frame", { Size = UDim2.fromScale(ratio, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, Parent = track }, { corner(5) })
		text(entry, work.done and "Achevé" or (work.have .. " / " .. work.total .. " matières apportées"), 15, TEXT)
		if not work.done then
			local missing = {}
			for id, needed in work.needs or {} do
				local left = needed - ((work.got or {})[id] or 0)
				if left > 0 then table.insert(missing, itemInfo(id).name .. " ×" .. left) end
			end
			table.sort(missing)
			if #missing > 0 then text(entry, "Il manque " .. table.concat(missing, ", "), 15, DIM) end
			button(entry, "Apporter au village", GREEN, function()
				send("oeuvre", { id = work.id })
				refresh()
			end)
		end
	end
end

local pages = {
	contrats = { "Commandes entre joueurs", contracts },
	gazette = { "Gazette du village", gazette },
	records = { "Registre des records", records },
	oeuvres = { "Chefs-d’œuvre", oeuvres },
}

render = function()
	clear()
	pages[active][2]()
end

local function prompt(title, message, acceptText, accept, color)
	active, current, pending, source, view = nil, nil, nil, nil, nil
	clear()
	if message then text(body, message, 18) end
	local yes = button(body, acceptText, color or GREEN, function()
		close()
		accept()
	end)
	button(body, "Annuler", nil, close)
	show(title)
	focus(yes)
end

function Registres.joueur(other)
	active, current, pending, source, view = nil, nil, nil, nil, nil
	clear()
	local invite = button(body, "Inviter dans le groupe", GREEN, function()
		close()
		send("group_invite", { target = other.UserId })
	end)
	button(body, "Offrir une bague", nil, function()
		close()
		send("mariage_demande", { target = other.UserId })
	end)
	show(other.DisplayName)
	focus(invite)
end

function Registres.divorce(conjoint)
	local message = conjoint and ("Rompre ton mariage avec " .. conjoint.name .. " ?") or "Rompre ton mariage ?"
	prompt("Mariage", message, "Divorcer", function()
		send("divorce")
	end, RED)
end

local invitation = 0
remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then return end
	if data.kind == "mariage_demande" then
		invitation += 1
		local serial = invitation
		prompt("Demande en mariage", data.from .. " t’offre une bague. Accepter ?", "Oui", function()
			send("mariage_oui")
		end)
		task.delay(60, function()
			if invitation == serial and heading.Text == "Demande en mariage" then close() end
		end)
		return
	end
	if not pages[data.kind] or (pending ~= data.kind and active ~= data.kind) then return end
	if source and not source.Visible and not panel.Visible then
		pending, source = nil, nil
		return
	end
	local opening = active ~= data.kind
	local hadFocus = GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(body)
	active, current, pending = data.kind, data, nil
	if opening then view = nil end
	if data.kind == "contrats" and commandeEnCours then
		local commande = commandeEnCours
		commandeEnCours = nil
		for _, item in data.contrats or {} do
			if own(item.uid) and not commande.known[item.id] and item.item == commande.item then
				if tonumber(drafts.n) == commande.n and tonumber(drafts.prix) == commande.prix and selectedItem == commande.item then
					drafts.n, drafts.prix, selectedItem = "", "", nil
				end
				view = nil
				break
			end
		end
	end
	if data.kind == "gazette" and articleEnCours then
		for _, item in data.articles or {} do
			if own(item.uid) and not articleEnCours.known[item.id] then
				if drafts.titre == articleEnCours.titre and drafts.texte == articleEnCours.texte then
					drafts.titre, drafts.texte = "", ""
				end
				articleEnCours = nil
				view = nil
				break
			end
		end
	end
	render()
	if opening then show(pages[data.kind][1]) end
	if opening or hadFocus then focus(body:FindFirstChildWhichIsA("TextButton")) end
end)

remotes:WaitForChild("Inventory").OnClientEvent:Connect(function(data)
	inventory = data.inv or {}
	if active == "gazette" and articleEnCours then refresh() end
end)

-- Le registre est une interaction avec la taverne construite, sans signal au-dessus d'un habitant.
local function addTavernPrompt(model)
	if not model:IsA("Model") or not model:IsDescendantOf(workspace) or model:GetAttribute("HouseId") ~= "v:Taverne" then return end
	local root = model.PrimaryPart
	if not root or root:FindFirstChild("RegistreRecords") then return end
	local anchor = C.creer("Attachment", { Name = "RegistreRecords", Position = Vector3.new(0, 2, 9), Parent = root })
	local p = C.creer("ProximityPrompt", {
		ActionText = "Lire les records", ObjectText = "Registre de la taverne",
		KeyboardKeyCode = Enum.KeyCode.R, GamepadKeyCode = Enum.KeyCode.DPadLeft,
		MaxActivationDistance = 10, RequiresLineOfSight = false, ClickablePrompt = true,
		Parent = anchor,
	})
	p.Triggered:Connect(function() Registres.ouvrir("records") end)
end

workspace.DescendantAdded:Connect(function(instance)
	-- En streaming, la pièce de référence peut arriver après le modèle.
	local model = instance:IsA("BasePart") and instance.Parent or instance
	if model and model:IsA("Model") and model.Name == "Taverne" then
		task.defer(addTavernPrompt, model)
	end
end)
task.defer(function()
	for _, instance in workspace:GetDescendants() do
		if instance.Name == "Taverne" then addTavernPrompt(instance) end
	end
end)

return Registres
