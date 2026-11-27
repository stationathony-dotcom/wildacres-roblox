-- Modèles d’outils construits au démarrage, utilisables aussi en mode Edit.
local M = {}
local mat = Enum.Material
local rgb = Color3.fromRGB

local templates = {
	hoe = "Houe", can = "Arrosoir", axe = "Hache", pickaxe = "Pioche", shovel = "Pelle",
	spade = "Pelle", rod = "Canne à pêche", club = "Gourdin", sword = "Épée", harpoon = "harpoon",
}
local surfaces = {
	hoe = {"Col de la houe", "Talonnette", "Fil coudé"},
	can = {"Épaulement de pomme", "Joint de tôle", "Pli de cuivre"},
	axe = {"Joue du fer", "Talon de panne", "Fil de hache"},
	pickaxe = {"Virole de pic", "Dos martelé", "Nervure de pic"},
	shovel = {"Épaulement du godet", "Nervure du godet", "Lèvre de pelle"},
	spade = {"Épaulement de bêche", "Dos de bêche", "Lèvre de bêche"},
	rod = {"Virole de scion", "Ligature de canne", "Filet de bambou"},
	club = {"Nœud de massue", "Fente de massue", "Aubier du gourdin"},
	sword = {"Gradin de lame", "Joint du ricasso", "Fil d’épée"},
	harpoon = {"Renfort de pointe", "Joint de pointe", "Arête de pointe"},
}

local function finish(tool, base, tint)
	if not tool:IsA("Tool") or tool:GetAttribute("FinitionX32") then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then return end
	local count, head, area = 0, nil, 0
	for _, part in tool:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		count += 1
		if part == handle or part.Transparency >= 1 then continue end
		local x, y, z = part.Size.X, part.Size.Y, part.Size.Z
		local face = math.max(x * y, y * z, x * z)
		if part.Name == "Pointe" and base == "harpoon" then face = math.huge end
		if face > area then head, area = part, face end
	end
	if count > 34 then return end
	head = head or handle
	if tint then
		for _, part in tool:GetDescendants() do
			if part:IsA("BasePart") and part ~= handle and part.Material ~= mat.Wood and part.Material ~= mat.WoodPlanks then
				part.Color, part.Material = tint, mat.Metal
			end
		end
	end

	local function accent(name, size, pose, color, material)
		local part = Instance.new("Part")
		part.Name, part.Size, part.CFrame = name, size, pose
		part.Color, part.Material = color, material
		part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, true
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = handle, part, part
		part.Parent = tool
	end

	local h = handle.Size
	local long = math.max(h.X, h.Y, h.Z)
	local axis, hFrame = h, handle.CFrame
	if long == h.X then
		axis, hFrame = Vector3.new(h.Y, h.X, h.Z), hFrame * CFrame.Angles(0, 0, math.pi / 2)
	elseif long == h.Z then
		axis, hFrame = Vector3.new(h.X, h.Z, h.Y), hFrame * CFrame.Angles(math.pi / 2, 0, 0)
	end
	local skin = handle.Color
	accent("Aubier du manche", Vector3.new(axis.X * 0.35, long * 0.66, axis.Z * 0.22),
		hFrame * CFrame.new(axis.X * 0.18, long * 0.02, -axis.Z * 0.48), skin:Lerp(rgb(231, 189, 128), 0.54), mat.Wood)
	accent("Joint du manche", Vector3.new(axis.X * 0.31, long * 0.49, axis.Z * 0.22),
		hFrame * CFrame.new(-axis.X * 0.25, -long * 0.03, axis.Z * 0.47), skin:Lerp(rgb(43, 29, 25), 0.48), mat.Wood)
	accent("Bague inclinée", Vector3.new(axis.X * 1.15, math.min(long * 0.12, 0.17), axis.Z * 1.11),
		hFrame * CFrame.new(0, -long * 0.20, 0) * CFrame.Angles(0, 0, 0.085), rgb(80, 53, 35), mat.Leather)

	local w, l, d = head.Size.X, head.Size.Y, head.Size.Z
	local face = head.CFrame
	if w <= math.min(l, d) then
		w, d, face = d, w, face * CFrame.Angles(0, math.pi / 2, 0)
	elseif l < d then
		l, d, face = d, l, face * CFrame.Angles(math.pi / 2, 0, 0)
	end
	local color, material = head.Color, head.Material
	local names = surfaces[base]
	local depth = math.min(d, 0.13)
	accent(names[1], Vector3.new(w * 0.70, l * 0.25, depth),
		face * CFrame.new(-w * 0.04, -l * 0.20, -d * 0.48) * CFrame.Angles(0, 0, -0.09), color, material)
	accent(names[2], Vector3.new(w * 0.26, l * 0.53, depth),
		face * CFrame.new(w * 0.23, l * 0.06, -d * 0.46) * CFrame.Angles(0, 0, 0.087), color:Lerp(rgb(43, 42, 49), 0.51), material)
	accent(names[3], Vector3.new(w * 0.70, l * 0.13, depth),
		face * CFrame.new(w * 0.08, l * 0.29, -d * 0.49) * CFrame.Angles(0, 0, 0.05), color:Lerp(rgb(244, 238, 215), 0.60), material)
	tool:SetAttribute("FinitionX32", true)
end

function M.equipements(folder, config)
	local baseTools = {}
	for id, name in templates do
		baseTools[id] = folder:FindFirstChild(id) or folder:FindFirstChild(name)
	end
	-- Les variantes utilisent en priorité le modèle déjà présent sous leur identifiant.
	-- Les autres héritent de la prise en main de leur outil de base.
	local variants = {}
	for id, info in config.ITEMS do
		local base = info.base
		local original = base and baseTools[base]
		if original and original:IsA("Tool") and not folder:FindFirstChild(id) then
			local tint = config.TOOL_TINTS[config.tierOf(id)]
			if tint then
				local tool = original:Clone()
				tool.Name = id
				finish(tool, base, tint)
				tool:SetAttribute("PaletteDediee", true)
				tool.Parent = folder
				variants[id] = true
			end
		end
	end
	for id, tool in baseTools do finish(tool, id) end
	for id, info in config.ITEMS do
		if info.base and surfaces[info.base] and not variants[id] then
			local tool = folder:FindFirstChild(id)
			if tool then finish(tool, info.base) end
		end
	end
end

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
