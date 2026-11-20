-- Retour et focus partagés par les fenêtres du joueur.
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local WindowNav = {}
local open = {}

local function usesGamepad()
	return UserInputService:GetLastInputType().Name:match("^Gamepad") ~= nil
end

function WindowNav.isOpen()
	return #open > 0
end

function WindowNav.watch(panel, closeButton, close)
	local entry = { panel = panel, focus = closeButton, close = close }
	closeButton.Text = "×"
	closeButton.Selectable = true
	panel.Active = true
	panel.SelectionGroup = true
	panel.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	panel.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	panel.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	panel.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			entry.previous = GuiService.SelectedObject
			table.insert(open, entry)
			if usesGamepad() then
				GuiService.SelectedObject = closeButton
			end
			return
		end
		local index = table.find(open, entry)
		if not index then return end
		table.remove(open, index)
		if usesGamepad() and index > #open then
			local previous = open[#open]
			GuiService.SelectedObject = previous and previous.focus or entry.previous
		end
	end)
end

function WindowNav.bindMenu(menu, toggle, close)
	ContextActionService:BindActionAtPriority("WildAcresMenu", function(_, state)
		if state == Enum.UserInputState.Begin then toggle() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonSelect)
	ContextActionService:BindActionAtPriority("WildAcresRetour", function(_, state)
		local entry = open[#open]
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
		local entry = open[#open]
		if entry and input.KeyCode == Enum.KeyCode.Escape and not UserInputService:GetFocusedTextBox() then
			entry.close()
		end
	end)
end

return WindowNav
