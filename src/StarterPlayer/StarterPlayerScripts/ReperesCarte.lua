local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local TYPES = {
	{ id = "village", nom = "Village", symbole = "■", couleur = Color3.fromRGB(151, 213, 255) },
	{ id = "lit", nom = "Lit", symbole = "◆", couleur = Color3.fromRGB(237, 190, 251) },
	{ id = "parcelle", nom = "Parcelle", symbole = "▲", couleur = Color3.fromRGB(183, 224, 145) },
	{ id = "quete", nom = "Quête", symbole = "!", couleur = Color3.fromRGB(255, 225, 144) },
	{ id = "perso", nom = "Perso", symbole = "●", couleur = Color3.fromRGB(255, 180, 156) },
}
local byId = {}
for _, sorte in TYPES do
	byId[sorte.id] = sorte
end

local INK = Color3.fromRGB(250, 236, 208)
local BROWN = Color3.fromRGB(86, 66, 47)
local DARK = Color3.fromRGB(48, 36, 25)
local GOLD = Color3.fromRGB(239, 197, 106)
local PRIORITY = Enum.ContextActionPriority.High.Value
local DIRECTIONS = {
	[Enum.KeyCode.DPadLeft] = Vector2.new(-1, 0),
	[Enum.KeyCode.DPadRight] = Vector2.new(1, 0),
	[Enum.KeyCode.DPadUp] = Vector2.new(0, -1),
	[Enum.KeyCode.DPadDown] = Vector2.new(0, 1),
}

local function bouton(parent, texte, position, taille)
	local button = Instance.new("TextButton")
	button.Text = texte
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = INK
	button.BackgroundColor3 = BROWN
	button.BorderSizePixel = 0
	button.Position = position
	button.Size = taille
	button.Parent = parent
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
	return button
end

local function etiquette(parent, position, taille)
	local label = Instance.new("TextLabel")
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextColor3 = INK
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Position = position
	label.Size = taille
	label.Parent = parent
	return label
end

local function gamepad(input)
	return input.UserInputType.Name:match("^Gamepad") ~= nil
end

local ReperesCarte = {}

function ReperesCarte.new(panel, grid, close, remotes, radius, regions, span, top)
	local action = remotes:WaitForChild("Action")
	local marks, icons, typeButtons = {}, {}, {}
	local selected, placing, placementButton
	local ready, busy = false, false
	local cursor = Vector2.new(0.5, 0.5)
	local stick = Vector2.zero

	local function project(x, z)
		return Vector2.new((x / span + radius) / regions, (z / span + radius) / regions)
	end

	local function setCursor(pos)
		cursor = Vector2.new(math.clamp(pos.X, 0, 0.99999), math.clamp(pos.Y, 0, 0.99999))
	end

	local status = etiquette(panel, UDim2.fromOffset(14, top), UDim2.new(1, -28, 0, 18))
	local prev = bouton(panel, "‹", UDim2.fromOffset(14, top + 62), UDim2.fromOffset(34, 28))
	local nextMark = bouton(panel, "›", UDim2.fromOffset(52, top + 62), UDim2.fromOffset(34, 28))
	local selection = etiquette(panel, UDim2.fromOffset(94, top + 62), UDim2.new(1, -188, 0, 28))
	local remove = bouton(panel, "Retirer", UDim2.new(1, -88, 0, top + 62), UDim2.fromOffset(74, 28))
	local target = bouton(grid, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
	target.BackgroundTransparency = 1
	target.AutoButtonColor = false
	target.ZIndex = 8
	target.Visible = false
	local aim = etiquette(target, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(24, 24))
	aim.AnchorPoint = Vector2.new(0.5, 0.5)
	aim.Text = "⊕"
	aim.TextSize = 23
	aim.TextStrokeTransparency = 0
	aim.TextXAlignment = Enum.TextXAlignment.Center
	aim.ZIndex = 9

	local function selectedMark()
		for index, mark in marks do
			if mark.id == selected then
				return mark, index
			end
		end
		return nil, 0
	end

	local function showSelection()
		local mark, index = selectedMark()
		prev.Interactable = not busy and not placing and #marks > 1
		nextMark.Interactable = prev.Interactable
		remove.Interactable = not busy and not placing and mark ~= nil
		remove.TextColor3 = remove.Interactable and INK or Color3.fromRGB(166, 151, 130)
		selection.Text = mark and string.format("%d/%d · %s", index, #marks, mark.nom)
			or (ready and "Aucun repère" or "")
		for id, icon in icons do
			icon.BackgroundColor3 = id == selected and BROWN or DARK
			icon.SelectionStroke.Enabled = id == selected
		end
	end

	local function showMarks()
		local active = {}
		for _, mark in marks do
			local sorte = byId[mark.sorte] or byId.perso
			local p = project(mark.x, mark.z)
			if p.X >= 0 and p.X < 1 and p.Y >= 0 and p.Y < 1 then
				local icon = icons[mark.id]
				if not icon then
					icon = bouton(grid, sorte.symbole, UDim2.fromScale(p.X, p.Y), UDim2.fromOffset(22, 22))
					icon.AnchorPoint = Vector2.new(0.5, 0.5)
					icon.TextColor3 = sorte.couleur
					icon.ZIndex = 6
					icon.Selectable = false
					local stroke = Instance.new("UIStroke")
					stroke.Name = "SelectionStroke"
					stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					stroke.Color = GOLD
					stroke.Parent = icon
					local id = mark.id
					icon.Activated:Connect(function()
						selected = id
						showSelection()
					end)
					icons[mark.id] = icon
				end
				active[mark.id] = true
			end
		end
		for id, icon in icons do
			if not active[id] then
				icon:Destroy()
				icons[id] = nil
			end
		end
		if not selectedMark() then
			selected = marks[1] and marks[1].id
		end
		showSelection()
	end

	local function refresh(expected)
		if busy then return end
		busy = true
		status.Text = expected and "Enregistrement du repère…" or "Chargement des repères…"
		showSelection()
		task.spawn(function()
			local updated, confirmed
			local infos = remotes:FindFirstChild("Infos") or remotes:WaitForChild("Infos", 3)
			if infos then
				for attempt = 1, 3 do
					if expected or attempt > 1 then task.wait(0.18 * attempt) end
					local ok, result = pcall(infos.InvokeServer, infos, "reperes")
					if ok and type(result) == "table" then
						updated = result
						if not expected or expected(result) then
							confirmed = true
							break
						end
					end
				end
			end
			busy = false
			if updated then
				marks, ready = updated, true
				showMarks()
			else
				showSelection()
			end
			status.Text = confirmed and "Choisir un type pour poser un repère"
				or (expected and "Modification non confirmée" or "Repères indisponibles")
		end)
	end

	local function cycle(delta)
		if busy or placing or #marks < 2 then return end
		local _, index = selectedMark()
		selected = marks[(index - 1 + delta) % #marks + 1].id
		showSelection()
	end
	prev.Activated:Connect(function() cycle(-1) end)
	nextMark.Activated:Connect(function() cycle(1) end)
	remove.Activated:Connect(function()
		if busy or placing or not selected then return end
		local id = selected
		action:FireServer("repere_retirer", { id = id })
		refresh(function(result)
			for _, mark in result do
				if mark.id == id then return false end
			end
			return true
		end)
	end)

	local function cancelPlacement()
		if not placing then return false end
		if GuiService.SelectedObject == target then
			GuiService.SelectedObject = placementButton
		end
		placementButton.BackgroundColor3 = BROWN
		placing, placementButton, stick = nil, nil, Vector2.zero
		target.Visible = false
		ContextActionService:UnbindAction("WildAcresPositionRepere")
		status.Text = "Choisir un type pour poser un repère"
		showSelection()
		return true
	end

	local function placeAt(pos, sorte)
		local x = math.floor((pos.X * regions - radius) * span)
		local z = math.floor((pos.Y * regions - radius) * span)
		local lastId = 0
		for _, mark in marks do
			lastId = math.max(lastId, mark.id)
		end
		action:FireServer("repere_poser", { x = x, z = z, sorte = sorte })
		refresh(function(result)
			for _, mark in result do
				if mark.id > lastId and mark.sorte == sorte and mark.x == x and mark.z == z then
					selected = mark.id
					return true
				end
			end
			return false
		end)
	end

	target.Activated:Connect(function(input)
		if not placing or busy then return end
		local pos = cursor
		if not gamepad(input) then
			local point = Vector2.new(input.Position.X, input.Position.Y)
			pos = (point - grid.AbsolutePosition) / grid.AbsoluteSize
			setCursor(pos)
			pos = cursor
		end
		local sorte = placing.id
		cancelPlacement()
		placeAt(pos, sorte)
	end)

	local function move(_, state, input)
		if not panel.Visible or not placing or GuiService.SelectedObject ~= target then
			return Enum.ContextActionResult.Pass
		end
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			stick = state == Enum.UserInputState.End and Vector2.zero
				or Vector2.new(input.Position.X, -input.Position.Y)
		elseif state == Enum.UserInputState.Begin then
			setCursor(cursor + DIRECTIONS[input.KeyCode] / (regions * 8))
		end
		return Enum.ContextActionResult.Sink
	end

	for index, sorte in TYPES do
		local button = bouton(panel, sorte.symbole .. " " .. sorte.nom,
			UDim2.new((index - 1) / #TYPES, 14 - (index - 1) * 28 / #TYPES, 0, top + 21),
			UDim2.new(1 / #TYPES, -28 / #TYPES - 4, 0, 36))
		typeButtons[index] = button
		button.TextColor3 = sorte.couleur
		button.Activated:Connect(function(input)
			if busy then return end
			if not ready then
				refresh()
				return
			end
			local alreadyPlacing = placing == sorte
			cancelPlacement()
			if alreadyPlacing then return end
			placing, placementButton = sorte, button
			showSelection()
			button.BackgroundColor3 = Color3.fromRGB(107, 78, 43)
			target.Visible = true
			local player = Players.LocalPlayer
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			setCursor(root and project(root.Position.X, root.Position.Z) or Vector2.new(0.5, 0.5))
			local controller = gamepad(input)
			aim.Visible = controller
			status.Text = controller and "Déplacer le curseur · A Poser · B Annuler"
				or ("Poser un repère " .. sorte.nom .. " sur la carte")
			if controller then
				GuiService.SelectedObject = target
				ContextActionService:BindActionAtPriority("WildAcresPositionRepere", move, false, PRIORITY,
					Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown,
					Enum.KeyCode.Thumbstick1)
			end
		end)
	end
	close.NextSelectionDown = typeButtons[5]
	for index, button in typeButtons do
		button.NextSelectionUp = close
		button.NextSelectionLeft = typeButtons[index - 1]
		button.NextSelectionRight = typeButtons[index + 1]
		button.NextSelectionDown = index < 3 and nextMark or remove
	end
	prev.NextSelectionUp = typeButtons[1]
	nextMark.NextSelectionUp = typeButtons[2]
	remove.NextSelectionUp = typeButtons[5]
	showSelection()

	return {
		refresh = refresh,
		cancelPlacement = cancelPlacement,
		step = function(dt)
			if not placing then return end
			if stick.Magnitude > 0.15 then
				setCursor(cursor + stick * math.min(dt, 0.05) * (0.08 + 0.72 * stick.Magnitude ^ 3))
			end
			aim.Position = UDim2.fromScale(cursor.X, cursor.Y)
		end,
	}
end

return ReperesCarte
