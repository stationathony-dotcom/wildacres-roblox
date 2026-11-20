-- Retour et focus partagés par les fenêtres du joueur.
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local WindowNav = {}
local open = {}
local menuReturn

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

local function focusTop()
	local top = topWindow()
	if top and usesGamepad() then
		GuiService.SelectedObject = top.focus
	end
end

function WindowNav.rememberMenu(restore)
	menuReturn = restore
	task.delay(3, function()
		if menuReturn == restore then menuReturn = nil end
	end)
end

function WindowNav.watch(panel, closeButton, close, screen)
	local layer = panel:FindFirstAncestorWhichIsA("ScreenGui")
	local source, property = screen or panel, screen and "Enabled" or "Visible"
	local entry = { panel = panel, focus = closeButton, close = close, layer = layer }
	closeButton.Text = "×"
	closeButton.Selectable = true
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
	ContextActionService:BindActionAtPriority("WildAcresMenu", function(_, state)
		if state == Enum.UserInputState.Begin then toggle() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonSelect)
	ContextActionService:BindActionAtPriority("WildAcresRetour", function(_, state)
		local entry = topWindow()
		local selected = GuiService.SelectedObject
		if not entry and not (selected and selected:IsDescendantOf(menu)) then
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Begin then
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
