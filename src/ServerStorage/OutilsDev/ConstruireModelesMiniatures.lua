-- Miniatures dont la silhouette porte l’identité de l’objet.
local M = {}
local V, C, rgb = Vector3.new, CFrame.new, Color3.fromRGB
local wood, bronze, steel = rgb(113, 70, 42), rgb(183, 126, 55), rgb(177, 193, 198)

local function folder(parent, name)
	local result = parent:FindFirstChild(name)
	if not result then
		result = Instance.new("Folder")
		result.Name, result.Parent = name, parent
	end
	return result
end

local function model(parent, id, shape)
	local m = Instance.new("Model")
	m.Name = id
	local function part(name, size, pose, color, form, material)
		local p = Instance.new(form == "Wedge" and "WedgePart" or "Part")
		if form and p:IsA("Part") then p.Shape = Enum.PartType[form] end
		p.Name, p.Size, p.CFrame, p.Color = name, size, pose, color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Parent = m
		return p
	end
	shape(part)
	local old = parent:FindFirstChild(id)
	if old then old:Destroy() end
	m.Parent = parent
	return m
end

local function curl(part, radius, thick, y, color, material)
	for i = 0, 9 do
		local a = i * math.pi * 2 / 10
		part("Anneau", V(thick, thick, radius * 0.68), C(math.cos(a) * radius, y, math.sin(a) * radius)
			* CFrame.Angles(0, -a, 0), color, nil, material)
	end
end

function M.identites(replicatedStorage)
	local icons = folder(replicatedStorage, "IconesObjets")
	model(icons, "seed_tree_cerisier", function(p)
		p("Noyau", V(0.94, 0.56, 0.74), C(), rgb(167, 106, 59), "Ball")
		p("Suture", V(0.64, 0.05, 0.06), C(0, 0.27, 0), rgb(101, 59, 38), "Ball")
	end)
	model(icons, "ruin_piece", function(p)
		p("Fragment", V(1.18, 0.86, 0.23), C() * CFrame.Angles(0, 0, 0.18), rgb(138, 130, 111), "Wedge", Enum.Material.Slate)
		p("Gravure", V(0.58, 0.08, 0.06), C(-0.12, -0.14, -0.13), bronze)
		p("Gravure", V(0.08, 0.49, 0.06), C(0.06, 0, -0.13) * CFrame.Angles(0, 0, -0.37), bronze)
	end)
	model(icons, "wool", function(p)
		for i = 0, 7 do
			local a = i * math.pi / 4
			p("Mèche de laine", V(0.67, 0.67, 0.64), C(math.cos(a) * 0.41, i % 2 * 0.12, math.sin(a) * 0.26),
				i % 2 == 0 and rgb(241, 226, 201) or rgb(219, 199, 171), "Ball", Enum.Material.Fabric)
		end
	end)
	for _, id in {"crown", "lost_crown"} do
		model(icons, id, function(p)
			local gold = id == "lost_crown" and rgb(152, 110, 55) or rgb(232, 181, 71)
			curl(p, 0.58, 0.18, -0.19, gold, Enum.Material.Metal)
			for i = 0, 5 do
				local a = math.pi * i / 3
				local pose = C(math.cos(a) * 0.57, 0.16, math.sin(a) * 0.57) * CFrame.Angles(0, -a, 0)
				p("Fleuron", V(0.16, 0.58 - (id == "lost_crown" and i % 3 * 0.08 or 0), 0.28), pose, gold, "Wedge", Enum.Material.Metal)
				p("Cabochon", V(0.15, 0.15, 0.18), pose * C(0.08, 0.14, 0), rgb(169, 60, 69), "Ball")
			end
		end)
	end
	model(icons, "prise_desert_raider", function(p)
		p("Étoffe", V(1.23, 0.69, 1.08), C(), rgb(186, 141, 89), "Ball", Enum.Material.Fabric)
		for i = -1, 1 do
			p("Pli", V(1.30 - math.abs(i) * 0.12, 0.14, 1.16), C(0, i * 0.16, 0)
				* CFrame.Angles(0, 0, 0.13 + 0.09 * i), rgb(224 - 16 * (i + 1), 184 - 14 * (i + 1), 120 - 10 * (i + 1)), "Ball", Enum.Material.Fabric)
		end
		p("Pan", V(0.34, 0.55, 0.10), C(0.55, -0.26, 0.15) * CFrame.Angles(0, 0, 0.46), rgb(176, 125, 77), nil, Enum.Material.Fabric)
	end)
	for _, id in {"bolt", "bolt_heavy"} do
		model(icons, id, function(p)
			local scale = id == "bolt_heavy" and 1.34 or 1
			for _, n in {-1, 1} do
				local pose = C(n * 0.23, n * 0.09, 0) * CFrame.Angles(0, 0, n * 0.23)
				p("Fût", V(0.11, 1.04, 0.11) * scale, pose, wood)
				p("Pointe", V(0.22, 0.31, 0.17) * scale, pose * C(0, 0.66 * scale, 0), steel, "Wedge", Enum.Material.Metal)
				p("Empennage", V(0.35, 0.28, 0.09) * scale, pose * C(0, -0.4 * scale, 0), rgb(210, 172, 113), "Wedge")
			end
		end)
	end
	for _, id in {"guard_badge", "sheriff_badge", "prise_deserter"} do
		model(icons, id, function(p)
			local color = id == "sheriff_badge" and bronze or steel
			for i = 0, 4 do
				local a = i * 2 * math.pi / 5
				p("Branche de l’étoile", V(0.28, 0.59, 0.13), C(math.sin(a) * -0.27, math.cos(a) * 0.27, 0)
					* CFrame.Angles(0, 0, a), color, "Wedge", Enum.Material.Metal)
			end
			p("Écusson central", V(0.48, 0.48, 0.17), C(0, 0, -0.05), color, "Ball", Enum.Material.Metal)
		end)
	end
	model(icons, "talisman", function(p)
		curl(p, 0.48, 0.075, 0, wood)
		p("Pendentif", V(0.41, 0.62, 0.23), C(0, -0.18, -0.59), bronze, "Ball", Enum.Material.Metal)
		p("Pierre", V(0.27, 0.34, 0.13), C(0, -0.18, -0.72), rgb(66, 137, 140), "Ball")
	end)
	model(icons, "rotten", function(p)
		p("Morceau", V(1.1, 0.44, 0.74), C(), rgb(110, 82, 72), "Wedge")
		p("Coupe", V(0.64, 0.33, 0.47), C(-0.29, 0.08, 0.03) * CFrame.Angles(0, -0.55, 0), rgb(125, 65, 65), "Wedge")
		for i = 0, 3 do
			p("Tache", V(0.15, 0.08, 0.12), C(i * 0.19 - 0.39, 0.14 + 0.036 * i, -0.15), rgb(123, 134, 67), "Ball")
		end
	end)
	for _, id in {"prise_boss_goblin", "prise_goblin", "prise_goblin_archer", "prise_swamp_goblin", "prise_wood_goblin"} do
		model(icons, id, function(p)
			p("Pavillon", V(0.47, 0.67, 0.31), C(-0.15, -0.15, 0), rgb(131, 153, 77), "Ball")
			p("Pointe", V(0.50, 0.78, 0.25), C(0.12, 0.19, 0) * CFrame.Angles(0, 0, -0.48), rgb(144, 163, 88), "Wedge")
			p("Conque", V(0.19, 0.37, 0.10), C(-0.16, -0.02, -0.15) * CFrame.Angles(0, 0, -0.46), rgb(82, 93, 53), "Ball")
		end)
	end
end

local function family(item, material, id)
	local name = string.lower(item.name)
	if name:find("crocs", 1, true) and item.slot == "trinket" then
		return (id:find("white", 1, true) or id:find("frost", 1, true) or id:find("snow", 1, true)) and "glace" or "crocs"
	end
	if name:find("venimeuse", 1, true) then
		if id:find("water", 1, true) then return "venin_eau" end
		if id:find("scorpion", 1, true) then return "venin_dard" end
		return "venin"
	end
	material = material:lower()
	if material:find("givre", 1, true) or material:find("glace", 1, true) or material:find("blizzard", 1, true) then
		return "glace"
	end
	if material:find("plume", 1, true) then return "plumes" end
	if name:find("cailles", 1, true) or name:find("carapace", 1, true) then return "cailles" end
end

local function trophy(part, category, slot, legendary)
	local pale, violet, teal = rgb(217, 201, 164), rgb(109, 73, 126), rgb(64, 150, 147)
	local ice = rgb(115, 201, 225)
	if category == "crocs" or category == "glace" and slot == "trinket" then
		curl(part, 0.62, 0.085, 0, legendary and bronze or wood)
		local frozen = category == "glace"
		for i = -2, 2 do
			local x = i * 0.24
			local length = (frozen and 0.7 or 0.55) - math.abs(i) * 0.091
			part(frozen and "Cristal" or "Croc", V(0.22, length, 0.19), C(x, -length * 0.35, -0.58 + math.abs(x) * 0.33)
				* CFrame.Angles(0, 0, i * 0.15 + math.pi), frozen and ice or pale, "Wedge")
		end
	elseif category:find("^venin") then
		local aqueous, sting = category == "venin_eau", category == "venin_dard"
		local color = aqueous and teal or sting and violet or rgb(101, 156, 76)
		part("Poignée", V(0.18, 0.49, 0.18), C(0, -0.73, 0), wood)
		part("Garde", V(sting and 0.61 or 0.81, 0.14, 0.19), C(0, -0.45, 0), legendary and bronze or steel, nil, Enum.Material.Metal)
		for i = 0, 3 do
			local x = aqueous and math.sin(i * 1.4) * 0.16 or sting and i * i * 0.031 or i * 0.04
			part("Segment de lame", V(0.5 - i * 0.076, 0.39, 0.15), C(x, -0.26 + i * 0.32, 0)
				* CFrame.Angles(0, 0, aqueous and math.cos(i * 1.4) * 0.38 or -i * 0.13), color, "Wedge", Enum.Material.Metal)
			part("Nervure", V(0.05, 0.26, 0.05), C(x, -0.19 + i * 0.32, -0.10), color:Lerp(pale, 0.42))
		end
	elseif category == "plumes" then
		part("Support", V(0.97, 0.38, 0.5), C(0, -0.23, 0), wood, "Ball")
		for i = -2, 2 do
			part("Plume", V(0.24, 1.02 - math.abs(i) * 0.15, 0.12), C(i * 0.177, 0.16, 0)
				* CFrame.Angles(0, 0, -i * 0.27), teal:Lerp(pale, math.abs(i) * 0.15), "Wedge")
		end
	elseif category == "cailles" then
		part("Cuir", V(1.17, 1.27, 0.39), C(), wood, "Ball")
		for row = 0, 2 do
			for col = -1, 1 do
				part("Écaille", V(0.36, 0.41, 0.16), C(col * 0.31, 0.39 - row * 0.34, -0.24)
					* CFrame.Angles(0, col * 0.17, math.pi), teal:Lerp(pale, row * 0.11), "Wedge", Enum.Material.Metal)
			end
		end
	else
		for i = -2, 2 do
			part("Glace taillée", V(0.41, 1.12 - math.abs(i) * 0.22, 0.25), C(i * 0.23, 0, 0)
				* CFrame.Angles(0, 0, -i * 0.28), ice:Lerp(pale, math.abs(i) * 0.16), "Wedge", Enum.Material.Glass)
		end
	end
end

function M.piecesDeCreatures(replicatedStorage, prises, gear)
	local icons = folder(replicatedStorage, "IconesEquipement")
	local total = 0
	local function generate(item, material, id, legendary)
		local category = family(item, material, id)
		if not category then return end
		local slot = gear.slotOf(item)
		local icon = model(icons, slot .. ":" .. item.name, function(part) trophy(part, category, slot, legendary) end)
		icon:SetAttribute("ApercuDroit", true)
		icon:SetAttribute("FamilleVisuelle", category)
		total += 1
	end
	for id, entry in prises.KINDS do
		generate(entry.gear, entry.name, id, false)
		if entry.soul then generate(entry.soul.gear, entry.name, id, true) end
	end
	return total
end

return M
