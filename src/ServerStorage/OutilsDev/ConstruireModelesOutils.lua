-- Modèles d’outils construits au démarrage, utilisables aussi en mode Edit.
local M = {}

function M.harpon(folder)
	local existing = folder:FindFirstChild("harpoon")
	if existing then return existing end

	local tool = Instance.new("Tool")
	tool.Name = "harpoon"
	tool.ToolTip = "Harpon de pêche"
	tool.Grip = CFrame.Angles(0, 0, math.rad(90))
	tool:SetAttribute("PaletteDediee", true)

	local function piece(class, name, size, pose, color, material)
		local part = Instance.new(class)
		part.Name, part.Size, part.CFrame = name, size, pose
		part.Color, part.Material = color, material
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.Massless = true
		part.Parent = tool
		return part
	end

	local wood = Color3.fromRGB(122, 81, 47)
	local steel = Color3.fromRGB(154, 173, 177)
	local leather = Color3.fromRGB(64, 41, 28)
	local handle = piece("Part", "Handle", Vector3.new(0.15, 0.15, 3.5), CFrame.new(0, 0, -0.45), wood, Enum.Material.Wood)
	local function weld(class, name, size, pose, color, material)
		local part = piece(class, name, size, pose, color, material)
		local joint = Instance.new("WeldConstraint")
		joint.Part0, joint.Part1 = handle, part
		joint.Parent = part
	end
	weld("Part", "Cuir", Vector3.new(0.21, 0.21, 0.68), CFrame.new(), leather, Enum.Material.Leather)
	weld("Part", "Douille", Vector3.new(0.24, 0.22, 0.45), CFrame.new(0, 0, -2), steel, Enum.Material.Metal)
	weld("WedgePart", "Pointe", Vector3.new(0.2, 0.19, 0.74), CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.pi, 0), steel, Enum.Material.Metal)
	for _, side in { -1, 1 } do
		weld("WedgePart", "Barbelure", Vector3.new(0.14, 0.15, 0.43), CFrame.new(side * 0.16, 0, -2.32)
			* CFrame.Angles(0, side * math.rad(26), 0), steel, Enum.Material.Metal)
	end
	tool.Parent = folder
	return tool
end

return M
