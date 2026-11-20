-- Ajuste les fenêtres à la zone sûre, y compris lorsque le clavier tactile est affiché.
local Input = game:GetService("UserInputService")
local M = {}

function M.dimensions(design, screen, scale, keyboard)
	local width = math.max(1, screen.X - 20) / scale
	local height = math.max(1, screen.Y - keyboard - 18) / scale
	return Vector2.new(math.min(width, design.X), math.min(height, design.Y)), width < design.X
end

function M.bind(panel, scale, adapted)
	local screen = panel:FindFirstAncestorWhichIsA("ScreenGui")
	local design = Vector2.new(panel.Size.X.Offset, panel.Size.Y.Offset)
	local originalPosition, originalAnchor = panel.Position, panel.AnchorPoint
	local keyboard = Input.TouchEnabled
	local function update()
		local pixels = screen.AbsoluteSize
		if pixels.X < 1 or pixels.Y < 1 then return end
		local obscured = keyboard and Input.OnScreenKeyboardVisible and Input.OnScreenKeyboardSize.Y or 0
		local factor = scale and scale.Scale or 1
		local size, narrow = M.dimensions(design, pixels, factor, obscured)
		panel.Size = UDim2.fromOffset(size.X, size.Y)
		if narrow or obscured > 0 or size.Y < design.Y then
			panel.AnchorPoint = Vector2.new(0.5, 0.5)
			panel.Position = UDim2.new(0.5, 0, 0.5, -obscured / factor / 2)
		else
			panel.AnchorPoint, panel.Position = originalAnchor, originalPosition
		end
		if adapted then adapted(narrow or keyboard and pixels.X <= 620) end
	end
	local connections = {screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)}
	if scale then table.insert(connections, scale:GetPropertyChangedSignal("Scale"):Connect(update)) end
	if keyboard then
		table.insert(connections, Input:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(update))
		table.insert(connections, Input:GetPropertyChangedSignal("OnScreenKeyboardSize"):Connect(update))
	end
	panel.Destroying:Connect(function()
		for _, connection in connections do connection:Disconnect() end
	end)
	update()
end

function M.columns(panel, sections, top)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "DispositionVerticale"
	scroll.BackgroundTransparency, scroll.BorderSizePixel = 1, 0
	scroll.Position = UDim2.fromOffset(10, top)
	scroll.Size = UDim2.new(1, -20, 1, -top - 8)
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection, scroll.ScrollBarThickness = Enum.ScrollingDirection.Y, 5
	scroll.ZIndex, scroll.Visible, scroll.Parent = 6, false, panel
	local layout = Instance.new("UIListLayout", scroll)
	layout.SortOrder, layout.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 8)
	for _, section in sections do
		section.position, section.size = section[1].Position, section[1].Size
	end
	return function(narrow)
		if scroll.Visible == narrow then return end
		scroll.Visible = narrow
		for index, section in sections do
			local column = section[1]
			column.LayoutOrder = index
			column.Position = narrow and UDim2.new() or section.position
			column.Size = narrow and UDim2.new(1, -7, 0, section[2]) or section.size
			column.Parent = narrow and scroll or panel
		end
	end
end

return M
