local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Apparence = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Apparence"))
local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))
local Hud = require(script.Parent:WaitForChild("Hud"))

local FicheApparence = {}
FicheApparence.titres = {
	creation = "Crée ton personnage",
	barbier = "Chez le barbier",
	tailleur = "Chez le tailleur",
}

local new = Composants.creer
local COLUMNS = 6
local WORN_LAYERS = { "Chapeau_WA", "Armure_WA", "Equipement_WA", "Cape_WA" }

function FicheApparence.choixActuels(savedLook)
	local look = Apparence.normalize(savedLook)
	local choices = {}
	for _, field in Apparence.FIELDS do
		local value = look[field.key]
		if field.colors then
			table.insert(choices, { label = field.label, name = field.names[value], color = field.colors[value] })
		else
			for _, option in field.choices do
				if option[1] == value then
					table.insert(choices, { label = field.label, name = option[2] })
					break
				end
			end
		end
	end
	return choices
end

local function corner()
	return new("UICorner", { CornerRadius = UDim.new(0, 6) })
end

function FicheApparence.mount(bag, closeButton, palette, scale, send)
	local BOLD = Enum.Font.GothamBold
	local function text(parent, props)
		props.Parent, props.BackgroundTransparency = parent, 1
		props.Font, props.TextColor3 = BOLD, props.TextColor3 or palette.text
		props.ZIndex = 9
		return new("TextLabel", props)
	end
	local function button(parent, props, activate)
		props.Parent, props.Font = parent, BOLD
		props.ZIndex, props.Selectable = 10, true
		props.BackgroundColor3 = props.BackgroundColor3 or palette.panel2
		props.TextColor3 = props.TextColor3 or palette.text
		return Composants.bouton(props, activate, { corner() })
	end
	local panel = new("Frame", {
		Name = "Apparence", Position = UDim2.fromOffset(12, 42), Size = UDim2.new(1, -24, 1, -54),
		Visible = false, BackgroundTransparency = 1, Parent = bag, ZIndex = 7,
	})
	local preview = new("Frame", { BackgroundColor3 = palette.panel, Parent = panel, ZIndex = 8 }, { corner() })
	local body = new("Frame", { BackgroundTransparency = 1, Parent = preview, ZIndex = 9 })
	local head = new("Frame", { BackgroundTransparency = 1, Parent = preview, ZIndex = 9 })
	local controls = new("Frame", { BackgroundColor3 = palette.panel, Parent = panel, ZIndex = 8 }, { corner() })
	local scroll = new("ScrollingFrame", {
		Name = "Choix", Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 1, -60),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = palette.line,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		Parent = controls, ZIndex = 9,
	}, { new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })

	local info, current, draft
	local changedCost = 0
	local hasChanges, rear = false, false
	local character, bodyView, headView, previewCopy
	local refreshRows = {}
	local navRows = {}

	local function drawHead()
		if headView then headView:Destroy() end
		headView = previewCopy and Hud.headViewport(previewCopy, rear)
		if headView then
			headView.Size = UDim2.fromScale(1, 1)
			headView.ZIndex, headView.Parent = 9, head
		end
	end

	local function draw()
		if bodyView then bodyView:Destroy() end
		bodyView, previewCopy = nil, nil
		if panel.Visible and character and draft then
			bodyView, previewCopy = Hud.avatarViewport(character, function(copy)
				for _, node in copy:GetChildren() do
					if table.find(WORN_LAYERS, node.Name) or node:IsA("Accessory") or node:IsA("Clothing") or node:IsA("ShirtGraphic") then
						node:Destroy()
					end
				end
				Apparence.peindre(copy, draft)
			end)
			if bodyView then
				bodyView.Size, bodyView.Position = UDim2.fromScale(1, 1), UDim2.new()
				bodyView.ZIndex, bodyView.Parent = 9, body
			end
		end
		drawHead()
	end

	local rotate
	rotate = button(preview, { Text = "Tête de dos", TextSize = 13, Size = UDim2.fromOffset(90, 36) }, function()
		rear = not rear
		rotate.Text = rear and "Tête de face" or "Tête de dos"
		drawHead()
	end)
	local apply = button(controls, {
		Text = "", BackgroundColor3 = palette.green, TextSize = 16,
		Size = UDim2.new(1, -16, 0, 44), Position = UDim2.new(0, 8, 1, -50),
	}, function()
		if not info or (info.ctx ~= "creation" and not hasChanges) then return end
		local payload = table.clone(draft)
		payload.ctx = info.ctx
		send("set_look", payload)
	end)

	local function layout()
		local narrow = bag.Size.X.Offset < 630
		if narrow then
			preview.Size = UDim2.new(1, 0, 0, 104)
			controls.Position, controls.Size = UDim2.fromOffset(0, 110), UDim2.new(1, 0, 1, -110)
			body.Position, body.Size = UDim2.fromOffset(4, 2), UDim2.new(0.33, 0, 1, -4)
			head.Position, head.Size = UDim2.new(0.34, 0, 0, 2), UDim2.new(0.33, 0, 1, -4)
			rotate.Position = UDim2.new(1, -96, 0.5, -18)
		else
			preview.Size = UDim2.new(0, 278, 1, 0)
			controls.Position, controls.Size = UDim2.fromOffset(286, 0), UDim2.new(1, -286, 1, 0)
			body.Position, body.Size = UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0.62, -4)
			head.Position, head.Size = UDim2.fromScale(0.25, 0.62), UDim2.new(0.5, 0, 0.38, -4)
			rotate.Position = UDim2.new(1, -96, 1, -42)
		end
	end
	bag:GetPropertyChangedSignal("Size"):Connect(layout)
	layout()

	local function price(key, value)
		if current[key] == value then return 0 end
		local owned = info.owned and info.owned[key]
		return owned and not owned[tostring(value)] and (info.prices[key] or 0) or 0
	end
	local function update()
		changedCost, hasChanges = 0, false
		if info.ctx ~= "creation" then
			for _, key in info.keys do
				if draft[key] ~= current[key] then
					hasChanges = true
					changedCost += price(key, draft[key])
				end
			end
			if hasChanges then changedCost += info.fee end
		end
		apply.Text = info.ctx == "creation" and "Commencer" or ("Appliquer (" .. changedCost .. " 💰)")
		apply.TextTransparency = (info.ctx == "creation" or hasChanges) and 0 or 0.25
		for _, refresh in refreshRows do refresh() end
		draw()
	end

	local function focusInScroll(choice)
		choice.SelectionGained:Connect(function()
			local top = choice.AbsolutePosition.Y - scroll.AbsolutePosition.Y
			local bottom = top + choice.AbsoluteSize.Y
			local delta = top < 0 and top or math.max(0, bottom - scroll.AbsoluteWindowSize.Y)
			if delta ~= 0 then
				scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.CanvasPosition.Y + delta / scale.Scale))
			end
		end)
	end

	local function addField(order, field)
		local key = field.key
		local lines = field.colors and math.ceil(#field.colors / COLUMNS) or 1
		local row = new("Frame", {
			Size = UDim2.new(1, 0, 0, 26 + 42 * lines), BackgroundColor3 = palette.panel2,
			LayoutOrder = order, Parent = scroll, ZIndex = 9,
		}, { corner() })
		local title = text(row, {
			Text = field.label, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -12, 0, 24),
		})
		local area = new("Frame", {
			Position = UDim2.fromOffset(5, 24), Size = UDim2.new(1, -10, 1, -26),
			BackgroundTransparency = 1, Parent = row, ZIndex = 9,
		})
		if field.colors then
			new("UIGridLayout", {
				CellSize = UDim2.new(1 / COLUMNS, -4, 0, 38), CellPadding = UDim2.fromOffset(4, 4),
				FillDirectionMaxCells = COLUMNS, SortOrder = Enum.SortOrder.LayoutOrder, Parent = area,
			})
			local swatches, borders = {}, {}
			local nav
			for index, color in field.colors do
				if (index - 1) % COLUMNS == 0 then
					nav = {}
					table.insert(navRows, nav)
				end
				local swatch = button(area, {
					Name = field.names[index], LayoutOrder = index, BackgroundColor3 = color,
					Text = "", TextSize = 12, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0,
				}, function()
					draft[key] = index
					update()
				end)
				swatches[index] = swatch
				borders[index] = new("UIStroke", { Color = palette.gold, Thickness = 2, Enabled = false, Parent = swatch })
				table.insert(nav, swatch)
				focusInScroll(swatch)
			end
			table.insert(refreshRows, function()
				title.Text = field.label .. " · " .. field.names[draft[key]]
				for index, swatch in swatches do
					local chosen = draft[key] == index
					local cost = price(key, index)
					swatch.Text = chosen and "✓" or (cost > 0 and ("🔒" .. cost) or "")
					borders[index].Enabled = chosen
				end
			end)
		else
			local choices = field.choices
			local selected = 1
			for index, option in choices do
				if option[1] == draft[key] then selected = index break end
			end
			local function shift(delta)
				selected = (selected - 1 + delta) % #choices + 1
				draft[key] = choices[selected][1]
				update()
			end
			local prev = button(area, { Text = "‹", TextSize = 24, Size = UDim2.fromOffset(42, 38) }, function() shift(-1) end)
			local nextChoice = button(area, {
				Text = "›", TextSize = 24, Size = UDim2.fromOffset(42, 38), Position = UDim2.new(1, -42, 0, 0),
			}, function() shift(1) end)
			local value = text(area, {
				Text = "", TextSize = 14, TextWrapped = true, Size = UDim2.new(1, -92, 0, 38),
				Position = UDim2.fromOffset(46, 0),
			})
			table.insert(navRows, { prev, nextChoice })
			focusInScroll(prev)
			focusInScroll(nextChoice)
			table.insert(refreshRows, function()
				local cost = price(key, choices[selected][1])
				value.Text = choices[selected][2] .. (cost > 0 and (" · 🔒 " .. cost .. " 💰") or "")
			end)
		end
	end

	local editor = { panel = panel }
	function editor:setCharacter(newCharacter)
		character = newCharacter
		if panel.Visible then draw() end
	end
	function editor:open(data, savedLook)
		info = data
		current = Apparence.normalize(data.look or savedLook)
		draft = table.clone(current)
		rear, rotate.Text = false, "Tête de dos"
		for _, node in scroll:GetChildren() do
			if node:IsA("Frame") then node:Destroy() end
		end
		table.clear(refreshRows)
		table.clear(navRows)
		table.insert(navRows, { rotate })
		scroll.CanvasPosition = Vector2.zero
		for index, field in Apparence.FIELDS do
			if data.ctx == "creation" or table.find(data.keys, field.key) then addField(index, field) end
		end
		table.insert(navRows, { apply })
		for index, row in navRows do
			local up, down = navRows[index - 1], navRows[index + 1]
			for column, choice in row do
				choice.NextSelectionUp = up and up[math.min(column, #up)] or closeButton
				choice.NextSelectionDown = down and down[math.min(column, #down)] or closeButton
				choice.NextSelectionLeft = row[column - 1]
				choice.NextSelectionRight = row[column + 1]
			end
		end
		closeButton.NextSelectionDown, closeButton.NextSelectionUp = rotate, apply
		panel.Visible = true
		update()
	end
	function editor:close()
		panel.Visible = false
		closeButton.NextSelectionDown, closeButton.NextSelectionUp = nil, nil
		info, current, draft = nil, nil, nil
		draw()
	end
	return editor
end

return FicheApparence
