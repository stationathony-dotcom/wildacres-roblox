local Input = game:GetService("UserInputService")
local P = {}

P.choices = {
	camera = {"Proche", "Classique", "Large"},
	sensitivity = {"Douce", "Normale", "Vive"},
	graphics = {"Économie", "Standard", "Détaillé"},
	textSize = {"Compact", "Standard", "Grand"},
}
function P.option(value)
	return (value == 1 or value == 3) and value or 2
end

function P.mount(player)
	local gui = player:WaitForChild("PlayerGui")
	local base = setmetatable({}, { __mode = "k" })
	local fonts, fov, sensitivity = {0.9, 1, 1.16}, {58, 70, 82}, {0.66, 1, 1.38}
	local currentFov, scale = 70, 1
	local function camera()
		local current = workspace.CurrentCamera
		if current and workspace:GetAttribute("Mode") ~= "accueil" then current.FieldOfView = currentFov end
	end
	local function text(object)
		if not (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) or object.TextScaled then return end
		local window = object:FindFirstAncestorWhichIsA("ScreenGui")
		if not window or window.Name == "HudMMO" then return end
		base[object] = base[object] or object.TextSize
		object.TextSize = math.max(9, math.round(base[object] * scale))
	end
	gui.DescendantAdded:Connect(text)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(camera)
	return function(settings)
		currentFov = fov[P.option(settings.camera)]
		camera()
		Input.MouseDeltaSensitivity = sensitivity[P.option(settings.sensitivity)]
		player:SetAttribute("GraphicsProfile", P.option(settings.graphics))
		local nextScale = fonts[P.option(settings.textSize)]
		if nextScale ~= scale then
			scale = nextScale
			for _, object in gui:GetDescendants() do text(object) end
		end
	end
end

return P
