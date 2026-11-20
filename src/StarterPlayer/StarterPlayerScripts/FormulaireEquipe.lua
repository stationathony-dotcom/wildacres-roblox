-- Formulaire commun à l’accueil et aux paramètres. Le serveur filtre et valide l’envoi.
local WindowNav = require(script.Parent:WaitForChild("WindowNav"))

local Formulaire = {}
local GOLD = Color3.fromRGB(239, 199, 116)
local INK = Color3.fromRGB(250, 237, 211)
local DARK = Color3.fromRGB(48, 39, 31)
local BLUE = Color3.fromRGB(54, 91, 123)

function Formulaire.mount(gui, action)
	local cover = Instance.new("Frame")
	cover.Name = "EcrireEquipe"
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Color3.new(0, 0, 0)
	cover.BackgroundTransparency = 0.42
	cover.ZIndex = 16
	cover.Visible = false
	cover.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.94, 0, 0, 284)
	panel.BackgroundColor3 = DARK
	panel.ZIndex = 17
	panel.Parent = cover
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
	Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(450, 284)

	local function text(class, name, size, pos)
		local item = Instance.new(class)
		item.Text = name
		item.Size, item.Position = size, pos
		item.TextColor3 = INK
		item.TextSize = 15
		item.Font = Enum.Font.Gotham
		item.ZIndex = 18
		item.Parent = panel
		return item
	end

	local title = text("TextLabel", "Écrire à l’équipe", UDim2.new(1, -60, 0, 38), UDim2.fromOffset(14, 7))
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3, title.TextSize, title.Font = GOLD, 20, Enum.Font.GothamBold

	local close = text("TextButton", "×", UDim2.fromOffset(34, 34), UDim2.new(1, -46, 0, 8))
	close.BackgroundColor3 = Color3.fromRGB(128, 61, 46)
	local box = text("TextBox", "", UDim2.new(1, -28, 0, 115), UDim2.fromOffset(14, 91))
	box.BackgroundColor3 = Color3.fromRGB(28, 24, 20)
	box.PlaceholderText = "Explique ta demande (10 à 300 caractères)."
	box.TextWrapped, box.MultiLine, box.ClearTextOnFocus = true, true, false
	box.TextXAlignment, box.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
	local padding = Instance.new("UIPadding", box)
	padding.PaddingLeft, padding.PaddingRight, padding.PaddingTop = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8)

	local note = text("TextLabel", "", UDim2.new(1, -28, 0, 26), UDim2.fromOffset(14, 209))
	note.TextSize = 13
	note.TextWrapped = true
	note.BackgroundTransparency = 1
	note.TextXAlignment = Enum.TextXAlignment.Left
	local submit = text("TextButton", "Envoyer", UDim2.new(1, -28, 0, 36), UDim2.fromOffset(14, 237))
	submit.BackgroundColor3 = BLUE

	local selected = "demande"
	local kinds = { { "demande", "Demande" }, { "bug", "Bug" }, { "appel", "Appel" } }
	local tabs = {}
	local function selectKind(kind)
		selected = kind
		for id, tab in tabs do
			tab.BackgroundColor3 = id == kind and BLUE or Color3.fromRGB(72, 58, 44)
		end
	end
	for index, kind in kinds do
		local tab = text("TextButton", kind[2], UDim2.new(1 / 3, -12, 0, 34), UDim2.new((index - 1) / 3, 14 - (index - 1) * 2, 0, 49))
		tabs[kind[1]] = tab
		tab.Activated:Connect(function() selectKind(kind[1]) end)
	end

	local function dismiss()
		box:ReleaseFocus()
		cover.Visible = false
	end
	close.Activated:Connect(dismiss)
	WindowNav.watch(cover, close, dismiss)

	local sentAt = -math.huge
	submit.Activated:Connect(function()
		local message = box.Text:match("^%s*(.-)%s*$") or ""
		if (utf8.len(message) or 0) < 10 then
			note.Text = "Ajoute quelques mots (10 caractères minimum)."
		elseif #message > 300 then
			note.Text = "Le texte est trop long. Raccourcis-le."
		elseif os.clock() - sentAt >= 2 then
			sentAt = os.clock()
			action:FireServer("demande", { kind = selected, text = message })
			note.Text = "Envoi demandé. Le jeu affiche la réponse du serveur."
		end
	end)

	return function(appealOnly)
		for id, tab in tabs do
			tab.Visible = not appealOnly or id == "appel"
		end
		selectKind(appealOnly and "appel" or "demande")
		note.Text = ""
		cover.Visible = true
	end
end

return Formulaire
