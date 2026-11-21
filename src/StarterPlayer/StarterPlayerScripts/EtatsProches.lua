local UserInputService = game:GetService("UserInputService")
local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))

local EtatsProches = {}

function EtatsProches.lire(target)
	while target and target ~= workspace do
		if target:IsA("Model") then
			if target.Name == "Culture" then
				local nom = target:GetAttribute("Plante")
				local arrosage = target:GetAttribute("Arrosee") and "Arrosée" or "À arroser"
				if not nom then return target, "Terre labourée", arrosage end
				if target:GetAttribute("Fletrie") then return target, nom, "Flétrie" end
				local jour, jours = target:GetAttribute("Jour"), target:GetAttribute("Jours")
				if type(jour) ~= "number" or type(jours) ~= "number" then return target, nom, arrosage end
				if jour >= jours then return target, nom, "Prête à récolter" end
				return target, nom, "Pousse " .. Composants.quantite(jour, jours) .. " · " .. arrosage
			end
			local machine = target:GetAttribute("EtatMachine")
			if type(machine) == "string" and machine ~= "" then
				return target, target:GetAttribute("NomEtat") or target.Name, machine
			end
			local verrou = target:GetAttribute("Verrouille")
			if type(verrou) == "boolean" then
				return target, target:GetAttribute("NomEtat") or "Coffre", verrou and "Verrouillé" or "Déverrouillé"
			end
		end
		target = target.Parent
	end
	return nil
end

function EtatsProches.survol(gui, uiScale, player, mobile, navigation, shown)
	local label = Composants.creer("TextLabel", {
		Name = "EtatAuSurvol", Visible = false, TextWrapped = true,
		Size = UDim2.fromOffset(220, 42), TextColor3 = Color3.fromRGB(248, 232, 200),
		Font = Enum.Font.GothamBold, TextSize = 13, BackgroundTransparency = 0.08,
		BackgroundColor3 = Color3.fromRGB(38, 29, 22), BorderSizePixel = 0, Parent = gui, ZIndex = 18,
	}, { Composants.creer("UICorner", { CornerRadius = UDim.new(0, 5) }) })
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded
	local function vise()
		local camera = workspace.CurrentCamera
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not camera or not root or navigation.isOpen() then return nil end
		local viewport = camera.ViewportSize
		local center = mobile or UserInputService:GetLastInputType().Name:match("^Gamepad")
		local point = center and viewport / 2 or UserInputService:GetMouseLocation()
		if char ~= excluded then
			excluded = char
			params.FilterDescendantsInstances = { char }
		end
		local ray = camera:ViewportPointToRay(point.X, point.Y)
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 48, params)
		if not hit or (hit.Position - root.Position).Magnitude > 8 then return nil end
		local model, nom, etat = EtatsProches.lire(hit.Instance)
		if not model then return nil end
		local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt and shown[prompt] then return nil end
		return nom .. "\n" .. etat, point, viewport, center
	end

	task.spawn(function()
		while gui.Parent do
			local text, point, viewport, center = vise()
			label.Visible = text ~= nil
			if text then
				label.Text = text
				local scale = math.max(0.01, uiScale.Scale)
				local x = point.X + (center and -110 * scale or 16)
				local y = point.Y + (center and 38 or 12)
				x = math.clamp(x, 4, math.max(4, viewport.X - 220 * scale - 4))
				y = math.clamp(y, 4, math.max(4, viewport.Y - 42 * scale - 4))
				label.Position = UDim2.fromOffset(x / scale, y / scale)
			end
			task.wait(0.12)
		end
	end)
end

return EtatsProches
