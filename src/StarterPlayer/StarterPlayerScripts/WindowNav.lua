-- Retour et focus partagés par les fenêtres du joueur.
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))
local Theme = require(script.Parent:WaitForChild("ThemeInterface"))

local WindowNav = {}
local open = {}
local menuReturn
local retour

local Cadre = require(script.Parent:WaitForChild("Cadre"))
WindowNav.habiller = Cadre.habiller

local function usesGamepad()
	return UserInputService:GetLastInputType().Name:match("^Gamepad") ~= nil
end

local function topWindow()
	local top
	for _, entry in open do
		if not top or entry.layer.DisplayOrder >= top.layer.DisplayOrder then
			top = entry
		end
	end
	return top
end

function WindowNav.isOpen()
	return #open > 0
end

function WindowNav.isTop(panel)
	local entry = topWindow()
	return entry ~= nil and entry.panel == panel
end

function WindowNav.clavier(panel)
	panel:SetAttribute("NavigationClavier", true)
end

function WindowNav.clavierActif()
	local entry = topWindow()
	return entry ~= nil and entry.panel:GetAttribute("NavigationClavier") == true
end

local function controls(panel)
	local list = {}
	for _, item in panel:GetDescendants() do
		if (item:IsA("TextBox") or Composants.actionBouton(item)) and item.Selectable and item.Interactable then
			local cursor = item
			while cursor ~= panel and cursor.Visible do
				cursor = cursor.Parent
			end
			if cursor == panel then table.insert(list, item) end
		end
	end
	table.sort(list, function(a, b)
		local pa, pb = a.AbsolutePosition, b.AbsolutePosition
		return pa.Y < pb.Y or (pa.Y == pb.Y and pa.X < pb.X)
	end)
	return list
end

local function defilerVers(objet)
	local parent = objet.Parent
	while parent and parent:IsA("GuiObject") do
		if parent:IsA("ScrollingFrame") then
			local position = objet.AbsolutePosition - parent.AbsolutePosition
			local fin = position + objet.AbsoluteSize - parent.AbsoluteWindowSize
			local delta = Vector2.new(
				position.X < 0 and position.X or math.max(0, fin.X),
				position.Y < 0 and position.Y or math.max(0, fin.Y)
			)
			local cible = parent.CanvasPosition + delta
			local direction = parent.ScrollingDirection
			parent.CanvasPosition = Vector2.new(
				direction == Enum.ScrollingDirection.Y and parent.CanvasPosition.X or math.max(0, cible.X),
				direction == Enum.ScrollingDirection.X and parent.CanvasPosition.Y or math.max(0, cible.Y)
			)
		end
		parent = parent.Parent
	end
end

local function keyboard(_, state, input)
	local entry = topWindow()
	if not entry or not entry.panel:GetAttribute("NavigationClavier") then return Enum.ContextActionResult.Pass end
	local panel = entry.panel
	local focused = UserInputService:GetFocusedTextBox()
	if focused and not focused:IsDescendantOf(panel) then return Enum.ContextActionResult.Pass end
	local tab = input.KeyCode == Enum.KeyCode.Tab
	local selected = GuiService.SelectedObject
	if not tab and (focused or not selected or not selected:IsDescendantOf(panel)) then
		return Enum.ContextActionResult.Pass
	end
	if state == Enum.UserInputState.Begin then
		if tab then
			local items = controls(panel)
			local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			local index = table.find(items, focused or selected) or (shift and 1 or 0)
			if #items > 0 then
				if focused then focused:ReleaseFocus() end
				local nextItem = items[(index - 1 + (shift and -1 or 1)) % #items + 1]
				GuiService.SelectedObject = nextItem
				defilerVers(nextItem)
			end
		elseif selected:IsA("TextBox") then
			selected:CaptureFocus()
		elseif selected.Interactable then
			local action = Composants.actionBouton(selected)
			if action then action() end
		end
	end
	return Enum.ContextActionResult.Sink
end

local function manetteTexte(_, state)
	local entry = topWindow()
	local selected = GuiService.SelectedObject
	if not entry or not WindowNav.clavierActif() or not selected or not selected:IsA("TextBox")
		or not selected:IsDescendantOf(entry.panel) or UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end
	if state == Enum.UserInputState.Begin then selected:CaptureFocus() end
	return Enum.ContextActionResult.Sink
end

local function focusTop()
	local top = topWindow()
	if top and usesGamepad() then
		local courant = GuiService.SelectedObject
		if not courant or not courant:IsDescendantOf(top.panel) then
			GuiService.SelectedObject = top.focus
		end
	end
end

function WindowNav.rememberMenu(restore)
	menuReturn = restore
	task.delay(3, function()
		if menuReturn == restore then menuReturn = nil end
	end)
end

function WindowNav.intercepterRetour(action)
	retour = action
end

function WindowNav.watch(panel, closeButton, close, screen, initialFocus)
	local layer = panel:FindFirstAncestorWhichIsA("ScreenGui")
	local source, property = screen or panel, screen and "Enabled" or "Visible"
	local entry = { panel = panel, focus = initialFocus or closeButton, close = close, layer = layer }
	-- Les fenêtres modales ont un fond plein écran et un panneau centré.
	local carte = panel:IsA("GuiButton") and closeButton.Parent ~= panel and closeButton.Parent or panel
	Cadre.habiller(carte)
	closeButton.Text = Composants.PICTOGRAMMES.fermer
	closeButton.Selectable = true
	closeButton.TextColor3, closeButton.Font = Theme.couleurs.encre, Theme.polices.titre
	local rayon = UDim.new(0.5, 0)
	Theme.bouton(closeButton, Theme.couleurs.terreCuite, rayon)
	panel.Active = true
	panel.SelectionGroup = true
	panel.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	panel.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	panel.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	panel.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	local function sync()
		local index = table.find(open, entry)
		if source[property] then
			if index then return end
			entry.previous, entry.restoreMenu = GuiService.SelectedObject, menuReturn
			menuReturn = nil
			table.insert(open, entry)
			local player = Players.LocalPlayer
			local sound = player and player:FindFirstChild("SonInterface")
			if sound and sound:IsA("BindableEvent") then sound:Fire() end
			focusTop()
		elseif index then
			local wasTop = topWindow() == entry
			table.remove(open, index)
			if wasTop and usesGamepad() then
				local parentWindow = topWindow()
				local prior = entry.previous
				if parentWindow and prior and prior:IsDescendantOf(parentWindow.panel) then
					GuiService.SelectedObject = prior
				elseif parentWindow then
					focusTop()
				elseif entry.restoreMenu then
					entry.restoreMenu()
				else
					GuiService.SelectedObject = prior and prior.Parent and prior or nil
				end
			end
		end
	end
	source:GetPropertyChangedSignal(property):Connect(sync)
	source.Destroying:Connect(function()
		local index = table.find(open, entry)
		if index then
			table.remove(open, index)
			focusTop()
		end
	end)
	sync()
end

function WindowNav.bindMenu(menu, toggle, close)
	UserInputService.LastInputTypeChanged:Connect(focusTop)
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		local selected = GuiService.SelectedObject
		local entry = topWindow()
		if usesGamepad() and selected and entry and selected:IsDescendantOf(entry.panel) then
			defilerVers(selected)
		end
	end)
	ContextActionService:BindActionAtPriority("WildAcresNavigationClavier", keyboard, false,
		Enum.ContextActionPriority.High.Value, Enum.KeyCode.Tab, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter)
	ContextActionService:BindActionAtPriority("WildAcresSaisieManette", manetteTexte, false,
		Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonA)
	ContextActionService:BindActionAtPriority("WildAcresMenu", function(_, state)
		if state == Enum.UserInputState.Begin then toggle() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonSelect)
	ContextActionService:BindActionAtPriority("WildAcresRetour", function(_, state)
		local entry = topWindow()
		local selected = GuiService.SelectedObject
		local focused = UserInputService:GetFocusedTextBox()
		if entry and focused and focused:IsDescendantOf(entry.panel) then
			return Enum.ContextActionResult.Pass
		end
		if not entry and not (selected and selected:IsDescendantOf(menu)) then
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Begin then
			local intercepter = retour
			retour = nil
			if intercepter and intercepter() then return Enum.ContextActionResult.Sink end
			if entry then entry.close() else close() end
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonB)
	UserInputService.InputBegan:Connect(function(input)
		local entry = topWindow()
		if entry and input.KeyCode == Enum.KeyCode.Escape and not UserInputService:GetFocusedTextBox() then
			entry.close()
		end
	end)
end

return WindowNav
