-- HUD façon MMO (image cible du 18/11) : uniquement l'affichage, aucune règle de jeu.
--   haut-gauche  : portrait rond, nom, écusson (honneur), barres de vie et d'endurance, or, étoiles ;
--   haut-centre  : boussole (suit la caméra) + nom du lieu ;
--   haut-droite  : cadre jour / heure / météo + minicarte ronde ;
--   gauche       : colonne de gros boutons (Inventaire, Personnage, …) ;
--   bas-droite   : notifications empilées (icône + titre + détail).
-- Construit par Interface.client (en jeu) ou par tools/bancs/hud_apercu.luau (aperçu en mode Edit).
-- Hud.build(parent, opts) → objet avec :setPlayer, :setBars, :setGold, :setStars, :setHeading,
-- :setPlace, :setClock, :setMap, :notify.

local Hud = {}
Hud.__index = Hud

-- Échelle du HUD : mêmes proportions que l'image cible (1672 x 941, HUD dans les coins, centre
-- libre). Le HUD a sa propre ScreenGui : les fenêtres (sac, atelier…) gardent leur échelle.
Hud.REF = Vector2.new(1672, 941)
function Hud.scaleFor(v: Vector2): number
	return math.clamp(math.min(v.X / Hud.REF.X, v.Y / Hud.REF.Y), 0.42, 1.15)
end

local DARK = Color3.fromRGB(27, 22, 18)
local DARK2 = Color3.fromRGB(48, 37, 28)
local EDGE = Color3.fromRGB(183, 149, 101)
local EDGE_DIM = Color3.fromRGB(108, 82, 58)
local TEXT = Color3.fromRGB(248, 242, 228)
local DIM = Color3.fromRGB(196, 188, 170)
local GOLD = Color3.fromRGB(246, 200, 70)
local NAVY = Color3.fromRGB(34, 52, 86)
local TITLE = Enum.Font.GothamBold
local BOLD = Enum.Font.GothamBold
local BODY = Enum.Font.GothamMedium

local function new(class: string, props, children)
	local o = Instance.new(class)
	for k, v in props or {} do
		if k ~= "Parent" then
			(o :: any)[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = o
	end
	if props and props.Parent then
		o.Parent = props.Parent
	end
	return o
end
local function corner(r)
	return new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 8) })
end
local function stroke(c, t)
	return new("UIStroke", { Color = c or EDGE, Thickness = t or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function text(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or BODY
	props.TextColor3 = props.TextColor3 or TEXT
	props.TextSize = props.TextSize or 16
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return new("TextLabel", props)
end
local function grad(top: Color3, bottom: Color3)
	return new("UIGradient", { Rotation = 90, Color = ColorSequence.new(top, bottom) })
end

-- Icône 3D d'un objet (maquette clonée dans un ViewportFrame), façon icône peinte : l'objet est vu
-- de face (le long de son côté le plus mince), son grand axe en diagonale. tint(part) facultatif.
function Hud.objectViewport(tpl: Model, dim: boolean?, tint: ((BasePart) -> ())?): ViewportFrame
	local vf = Instance.new("ViewportFrame")
	vf.BackgroundTransparency = 1
	vf.Size = UDim2.fromScale(0.92, 0.92)
	vf.Position = UDim2.fromScale(0.5, 0.5)
	vf.AnchorPoint = Vector2.new(0.5, 0.5)
	vf.Ambient = Color3.fromRGB(215, 205, 195)
	vf.LightColor = Color3.fromRGB(255, 244, 226)
	vf.LightDirection = Vector3.new(-1, -1.5, -0.6)
	vf.ImageTransparency = dim and 0.6 or 0
	local m = tpl:Clone()
	if tint then
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				tint(d)
			end
		end
	end
	m.Parent = vf
	local cf, size = m:GetBoundingBox()
	if tpl:GetAttribute("EquipementCommun") then
		local camera = Instance.new("Camera")
		camera.FieldOfView = 30
		local aim = Vector3.new(0.28, 0.20, -1).Unit
		local up = tpl:GetAttribute("ApercuArme") and Vector3.new(-0.38, 1, 0) or Vector3.yAxis
		local frame = CFrame.lookAt(cf.Position + aim, cf.Position, up)
		local cone = math.tan(math.rad(15)) * 0.91
		local distance = 0.1
		local signs = {-1, 1}
		for _, x in signs do
			for _, y in signs do
				for _, z in signs do
					local corner = cf:VectorToWorldSpace(Vector3.new(x, y, z) * size / 2)
					local rel = frame:VectorToObjectSpace(corner)
					distance = math.max(distance, rel.Z + math.max(math.abs(rel.X), math.abs(rel.Y)) / cone)
				end
			end
		end
		camera.CFrame = CFrame.lookAt(cf.Position + aim * distance, cf.Position, up)
		camera.Parent = vf
		vf.CurrentCamera = camera
		return vf
	end
	if tpl:GetAttribute("ApercuDroit") then
		local camera = Instance.new("Camera")
		camera.FieldOfView = 30
		local direction = Vector3.new(0.78, 0.56, -1).Unit
		local distance = size.Magnitude * 0.52 / math.tan(math.rad(15))
		camera.CFrame = CFrame.lookAt(cf.Position + direction * distance, cf.Position)
		camera.Parent = vf
		vf.CurrentCamera = camera
		return vf
	end
	local axes = { { cf.RightVector, size.X }, { cf.UpVector, size.Y }, { cf.LookVector, size.Z } }
	table.sort(axes, function(a, b)
		return a[2] > b[2]
	end)
	local long, mid, thin = axes[1][1], axes[2][1], axes[3][1]
	local up = (long + mid).Unit -- grand axe à 45° à l'écran
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local dist = math.max(axes[1][2] * 0.78, axes[2][2]) * 0.5 / math.tan(math.rad(15)) + axes[3][2]
	-- léger 3/4 (on voit un peu le dessus et le côté : plus de relief qu'une vue à plat)
	local back = (thin + up * 0.3 + up:Cross(thin) * 0.25).Unit
	cam.CFrame = CFrame.lookAt(cf.Position + back * dist, cf.Position, up)
	cam.Parent = vf
	vf.CurrentCamera = cam
	return vf
end

local FORM_ICONS = { bow = "🏹", shortbow = "🏹", longbow = "🏹", crossbow = "🏹", pike = "🔱", longpike = "🔱",
	halberd = "🔱", javelin = "🔱",
	staff = "✨", scythe = "🌾", reaper = "🌾", sickle = "🌾", dagger = "🗡️", axe = "⚒️",
	hammer = "🔨", mace = "🔨", shield = "🛡️", roundshield = "🛡️", pavise = "🛡️", shellshield = "🛡️", torch = "🔥" }

function Hud.gearIcon(it)
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local gear = require(shared:WaitForChild("Gear"))
	local design = require(shared:WaitForChild("GearDesign"))
	local icons = require(script.Parent:WaitForChild("IconesPeintes"))
	return icons.secours("equipement:" .. (it.name or ""), FORM_ICONS[design.formOf(it)] or gear.SLOT_ICONS[gear.slotOf(it)] or "✨")
end

function Hud.gearThumbnail(it, dim: boolean?): GuiObject?
	local rs = game:GetService("ReplicatedStorage")
	local equipment = rs:FindFirstChild("IconesEquipement")
	local shared = rs:WaitForChild("Shared")
	local gear = require(shared:WaitForChild("Gear"))
	if not it.name or not gear.SLOTS[gear.slotOf(it)] then return nil end
	local template = equipment and equipment:FindFirstChild(gear.visualKey(it))
	if template and template:IsA("Model") and template:GetAttribute("EquipementCommun")
		and template:GetAttribute("RangVisuel") == (it.rarity or 1) then
		return Hud.objectViewport(template, dim)
	end
	-- Pièce de butin, ancienne sauvegarde ou place dont la planche n'a pas
	-- encore été reconstruite. La vignette reprend la rareté de l'objet porté.
	local visuals = require(shared:WaitForChild("GearVisuals"))
	local model = visuals.preview(it)
	local viewport = Hud.objectViewport(model, dim)
	model:Destroy()
	return viewport
end

-- Les mêmes couches sont observées par la carte et la fiche. Les événements des descendants
-- gèrent aussi une couche qui arrive en plusieurs paquets ou une coiffe retirée.
local headLayers = { "Visage_WA", "Coiffure_WA", "Chapeau_WA" }
local avatarLayers = { "Tenue_WA", "Armure_WA", "Equipement_WA", "Cape_WA" }

function Hud.watchAvatar(player: Player, changed)
	local current
	local connections = {}
	local headConnections = {}
	local function disconnect(list)
		for _, connection in list do connection:Disconnect() end
		table.clear(list)
	end
	local queued = false
	local function refresh()
		if queued then return end
		queued = true
		task.defer(function()
			queued = false
			changed(current)
		end)
	end
	local function follow(character)
		disconnect(connections)
		disconnect(headConnections)
		current = character
		if character then
			local function watchHead()
				disconnect(headConnections)
				local head = character:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					for _, property in head:IsA("MeshPart") and { "Color", "Size", "TextureID" } or { "Color", "Size" } do
						table.insert(headConnections, head:GetPropertyChangedSignal(property):Connect(refresh))
					end
				end
			end
			local function relevant(node)
				if not (node:IsA("BasePart") or node:IsA("Model")) then return end
				while node and node.Parent ~= character do node = node.Parent end
				if node and (node.Name == "Head" or node.Name == "HumanoidRootPart"
					or table.find(headLayers, node.Name) or table.find(avatarLayers, node.Name)) then
					refresh()
				end
			end
			table.insert(connections, character.DescendantAdded:Connect(relevant))
			table.insert(connections, character.DescendantRemoving:Connect(relevant))
			table.insert(connections, character.ChildAdded:Connect(function(child)
				if child.Name == "Head" then watchHead() end
			end))
			watchHead()
		end
		refresh()
	end
	player.CharacterAdded:Connect(follow)
	player.CharacterRemoving:Connect(function(character)
		if current == character then follow(nil) end
	end)
	follow(player.Character)
end

function Hud.headViewport(character: Model, rear: boolean?): ViewportFrame?
	local head = character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart") and character:FindFirstChild("Visage_WA")) then return nil end
	local vf = new("ViewportFrame", {
		BackgroundTransparency = 1, Ambient = Color3.fromRGB(208, 198, 185), LightColor = TEXT,
		LightDirection = Vector3.new(-0.5, -1, 0.8),
	})
	local world = new("WorldModel", { Parent = vf })
	local model = new("Model", { Parent = world })
	local function copyPart(part)
		local archivable = part.Archivable
		part.Archivable = true
		local copy = part:Clone()
		part.Archivable = archivable
		for _, child in copy:GetChildren() do
			if not child:IsA("DataModelMesh") and not child:IsA("SurfaceAppearance") then child:Destroy() end
		end
		copy.Anchored, copy.LocalTransparencyModifier = true, 0
		copy.CFrame = head.CFrame:ToObjectSpace(part.CFrame)
		copy.Parent = model
	end
	copyPart(head)
	for _, name in headLayers do
		local layer = character:FindFirstChild(name)
		if not layer then continue end
		for _, part in layer:GetDescendants() do
			if part:IsA("BasePart") and part.Transparency < 1 then copyPart(part) end
		end
	end
	local camera = new("Camera", { FieldOfView = 28, Parent = vf })
	local bounds, size = model:GetBoundingBox()
	local at = Vector3.new(0, bounds.Y * 0.80, 0)
	local direction = (rear and Vector3.new(0.55, 0.12, 1) or Vector3.new(0.15, 0.06, -1)).Unit
	local distance = math.max(size.X, size.Y) * 2.56 + size.Z * 0.5
	camera.CFrame = CFrame.lookAt(at + direction * distance, at)
	vf.CurrentCamera = camera
	return vf
end

function Hud.avatarViewport(character: Model, prepare: ((Model) -> ())?): (ViewportFrame?, Model?)
	local old = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = old
	if not copy then
		return nil
	end
	for _, node in copy:GetDescendants() do
		if node:IsA("LuaSourceContainer") or node:IsA("Tool") or node:IsA("BillboardGui")
			or node:IsA("ParticleEmitter") or node:IsA("Sound") or node:IsA("Highlight") then
			node:Destroy()
		elseif node:IsA("BasePart") then
			node.LocalTransparencyModifier = 0
		end
	end
	local pivot = copy:FindFirstChild("HumanoidRootPart")
	if not (pivot and pivot:IsA("BasePart")) then
		copy:Destroy()
		return nil
	end
	local vf = new("ViewportFrame", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(0.72, 0.92), Position = UDim2.fromScale(0.14, 0.04),
		Ambient = Color3.fromRGB(197, 183, 163), LightColor = TEXT, LightDirection = Vector3.new(-1, -1, 1),
	})
	local world = new("WorldModel", { Parent = vf })
	copy:PivotTo(CFrame.new())
	if prepare then prepare(copy) end
	copy.Parent = world
	local at, size = copy:GetBoundingBox()
	local camera = new("Camera", { FieldOfView = 28, Parent = vf })
	local offset = pivot.CFrame:VectorToWorldSpace(Vector3.new(0.20, 0.07, -1)).Unit
	camera.CFrame = CFrame.lookAt(at.Position + offset * (math.max(size.Y, size.X) * 2.25), at.Position)
	vf.CurrentCamera = camera
	return vf, copy
end

-- ---------------------------------------------------------------- carte du joueur (haut-gauche)
local function bar(parent, y: number, color: Color3, icon: string)
	local row = new("Frame", { Size = UDim2.fromOffset(250, 24), Position = UDim2.fromOffset(150, y), BackgroundTransparency = 1, Parent = parent })
	local back = new("Frame", { Size = UDim2.new(1, -14, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundColor3 = Color3.fromRGB(18, 16, 20), BackgroundTransparency = 0.15, Parent = row },
		{ corner(5), stroke(EDGE_DIM, 1.5) })
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, Parent = back }, { corner(5), grad(color:Lerp(Color3.new(1, 1, 1), 0.25), color:Lerp(Color3.new(0, 0, 0), 0.25)) })
	local val = text({ Text = "", Font = BOLD, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.35, Size = UDim2.fromScale(1, 1), Parent = back, ZIndex = 3 })
	text({ Text = icon, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(0, -1), Parent = row, ZIndex = 4 })
	return { fill = fill, val = val, color = color }
end

-- ---------------------------------------------------------------- construction
function Hud.build(parent: Instance, opts)
	opts = opts or {}
	local self = setmetatable({}, Hud)
	local root = new("Frame", { Name = "HudMMO", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = parent })
	self.root = root

	-- carte du joueur
	local card = new("Frame", { Name = "Joueur", Size = UDim2.fromOffset(420, 150), Position = UDim2.fromOffset(20, 31), BackgroundTransparency = 1, Parent = root })
	new("Frame", { Size = UDim2.fromOffset(300, 108), Position = UDim2.fromOffset(110, 14), BackgroundColor3 = DARK, BackgroundTransparency = 0.3, Parent = card },
		{ corner(10), new("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
	local ring = new("Frame", { Size = UDim2.fromOffset(128, 128), Position = UDim2.fromOffset(0, 4), BackgroundColor3 = Color3.fromRGB(70, 56, 40), Parent = card, ZIndex = 2 },
		{ corner(UDim.new(0.5, 0)), stroke(EDGE, 4) })
	self.portrait = new("Frame", { Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.fromRGB(54, 69, 80), Parent = ring, ZIndex = 3 },
		{ corner(UDim.new(0.5, 0)) })
	local badge = new("Frame", { Size = UDim2.fromOffset(46, 52), Position = UDim2.fromOffset(92, 92), BackgroundColor3 = NAVY, Parent = card, ZIndex = 5 },
		{ corner(UDim.new(0.3, 0)), stroke(GOLD, 2.5), grad(Color3.fromRGB(60, 84, 130), Color3.fromRGB(26, 36, 62)) })
	self.badge = text({ Text = "😇", TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = badge, ZIndex = 6 })
	self.name = text({ Text = "Joueur", Font = TITLE, TextSize = 24, TextStrokeTransparency = 0.5, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.fromOffset(260, 30), Position = UDim2.fromOffset(150, 14), Parent = card, ZIndex = 3 })
	self.hp = bar(card, 48, Color3.fromRGB(206, 44, 44), "❤️")
	self.st = bar(card, 78, Color3.fromRGB(44, 120, 220), "⚡")
	local goldPill = new("Frame", { Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.fromOffset(164, 110), BackgroundColor3 = DARK, BackgroundTransparency = 0.2, Parent = card },
		{ corner(13), stroke(EDGE_DIM, 1.5), new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }) })
	self.gold = text({ Text = "💰 0", Font = BOLD, TextSize = 16, TextColor3 = GOLD, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), Parent = goldPill })
	self.stars = text({ Text = "", TextSize = 20, TextColor3 = GOLD, TextStrokeTransparency = 0.4, Size = UDim2.fromOffset(240, 26), Position = UDim2.fromOffset(290, 110), Parent = card })

	-- boussole + lieu (haut-centre)
	local comp = new("Frame", { Name = "Boussole", Size = UDim2.fromOffset(448, 36), Position = UDim2.new(0.5, 0, 0, 27), AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = NAVY, BackgroundTransparency = 0.12, ClipsDescendants = true, Visible = not opts.compact, Parent = root },
		{ corner(6), stroke(EDGE, 2.5), grad(Color3.fromRGB(56, 78, 120), Color3.fromRGB(24, 34, 58)) })
	local strip = new("Frame", { Size = UDim2.fromOffset(0, 40), BackgroundTransparency = 1, Parent = comp })
	self.strip = strip
	self.PX_PER_DEG = 2.6
	local marks = { [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SO", [270] = "O", [315] = "NO" }
	for rep = -1, 1 do
		for deg = 0, 345, 15 do
			local x = (deg + rep * 360) * self.PX_PER_DEG
			local m = marks[deg]
			if m then
				text({ Text = m, Font = m == "N" and TITLE or BOLD, TextSize = m == "N" and 22 or (#m == 1 and 19 or 14), TextColor3 = m == "N" and GOLD or TEXT,
					TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(x - 20, 0), Parent = strip })
			else
				new("Frame", { Size = UDim2.fromOffset(2, 8), Position = UDim2.fromOffset(x - 1, 16), BackgroundColor3 = DIM, BorderSizePixel = 0, Parent = strip })
			end
		end
	end
	new("Frame", { Size = UDim2.fromOffset(34, 34), Position = UDim2.new(0.5, 0, 0, 45), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundColor3 = NAVY, Visible = not opts.compact, Parent = root, ZIndex = 3 }, { stroke(EDGE, 2.5) })
	self.heading = text({ Text = "N", Font = BOLD, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(46, 36), Position = UDim2.new(0.5, 0, 0, 45), AnchorPoint = Vector2.new(0.5, 0.5), Visible = not opts.compact, Parent = root, ZIndex = 4 })
	local place = new("Frame", { Name = "Lieu", Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0.5, 0, 0, 73), AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = DARK, BackgroundTransparency = 0.35, Parent = root },
		{ corner(8), new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 18) }),
			new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }) })
	self.placeIcon = text({ Text = "🏠", TextSize = 22, Size = UDim2.fromOffset(28, 34), LayoutOrder = 1, Parent = place })
	self.placeName = text({ Text = "", Font = TITLE, TextSize = 22, TextStrokeTransparency = 0.5, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 34), LayoutOrder = 2, Parent = place })

	-- horloge / météo + minicarte (haut-droite)
	local clock = new("Frame", { Name = "Horloge", Size = UDim2.fromOffset(240, 66), Position = opts.compact and UDim2.new(1, -12, 0, 220) or UDim2.new(1, -220, 0, 27), AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = NAVY, BackgroundTransparency = 0.15, Parent = root }, { corner(10), stroke(EDGE, 2), grad(Color3.fromRGB(56, 78, 120), Color3.fromRGB(24, 34, 58)) })
	self.sky = text({ Text = "☀️", TextSize = 36, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(56, 66), Parent = clock })
	self.day = text({ Text = "", Font = TITLE, TextSize = 21, Size = UDim2.new(1, -62, 0, 30), Position = UDim2.fromOffset(58, 6), Parent = clock })
	self.weather = text({ Text = "", TextSize = 14, TextColor3 = DIM, Size = UDim2.new(1, -62, 0, 22), Position = UDim2.fromOffset(58, 36), Parent = clock })

	local MAP = 190
	local mapRing = new("Frame", { Name = "Minicarte", Size = UDim2.fromOffset(MAP + 12, MAP + 12), Position = UDim2.new(1, -12, 0, 10), AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(70, 56, 40), Parent = root }, { corner(UDim.new(0.5, 0)), stroke(EDGE, 4) })
	local mapGroup = new("CanvasGroup", { Size = UDim2.fromOffset(MAP, MAP), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.fromRGB(70, 110, 140), Parent = mapRing },
		{ corner(UDim.new(0.5, 0)) })
	self.mapN = opts.mapCells or 23
	self.mapCells = {}
	local cs = MAP / self.mapN
	for j = 0, self.mapN - 1 do
		for i = 0, self.mapN - 1 do
			local f = new("Frame", { Size = UDim2.fromOffset(math.ceil(cs) + 1, math.ceil(cs) + 1), Position = UDim2.fromOffset(math.floor(i * cs), math.floor(j * cs)),
				BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(110, 160, 80), Parent = mapGroup })
			self.mapCells[j * self.mapN + i + 1] = f
		end
	end
	self.mapIcons = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = mapGroup, ZIndex = 3 })
	self.arrow = text({ Text = "▲", Font = BOLD, TextSize = 22, TextColor3 = Color3.fromRGB(80, 200, 255), TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(24, 24), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Parent = mapGroup, ZIndex = 5 })
	local function roundBtn(t: string, pos: UDim2, fn)
		local b = new("TextButton", { Text = t, Font = TITLE, TextSize = 20, TextColor3 = TEXT, BackgroundColor3 = Color3.fromRGB(30, 30, 34), Size = UDim2.fromOffset(34, 34),
			Position = pos, AnchorPoint = Vector2.new(0.5, 0.5), Parent = mapRing, ZIndex = 6 }, { corner(UDim.new(0.5, 0)), stroke(EDGE, 2) })
		if fn then
			b.Activated:Connect(fn)
		end
		return b
	end
	roundBtn("M", UDim2.new(0.86, 0, 0.88, 0), opts.onMap)
	self.zoomBtn = roundBtn("+", UDim2.new(0.88, 0, 0.1, 0), opts.onZoom)

	-- colonne de boutons (gauche)
	local touchLayer
	if opts.compact then
		touchLayer = new("ScreenGui", { Name = "MenuTactile", ResetOnSpawn = false, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
			DisplayOrder = parent.DisplayOrder, Parent = parent.Parent })
	end
	local menu = new(opts.compact and "ScrollingFrame" or "Frame", { Name = "Menu",
		Size = opts.compact and UDim2.new(0, 206, 0.78, -52) or UDim2.fromOffset(216, 0),
		AutomaticSize = opts.compact and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(opts.compact and 12 or 16, opts.compact and 116 or 252),
		BackgroundTransparency = 1, Visible = not opts.compact, Parent = touchLayer or root },
		{ new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	if opts.compact then
		menu.CanvasSize = UDim2.new()
		menu.AutomaticCanvasSize, menu.ScrollingDirection = Enum.AutomaticSize.Y, Enum.ScrollingDirection.Y
		menu.BorderSizePixel, menu.ScrollBarThickness = 0, 4
	end
	self.menu = menu
	local GuiService = game:GetService("GuiService")
	local nav = opts.gamepad and require(script.Parent:WaitForChild("WindowNav"))
	local menuToggle
	local firstButton
	local lastButton
	local function closeMenu()
		if opts.compact then
			menu.Visible = false
			menuToggle.Text = "☰  Menu"
		end
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(menu) then
			GuiService.SelectedObject = nil
		end
	end
	if opts.compact then
		menuToggle = new("TextButton", { Name = "OuvrirMenu", Text = "☰  Menu", Font = BOLD, TextSize = 18, TextColor3 = TEXT, BackgroundColor3 = DARK, Size = UDim2.fromOffset(132, 44), Position = UDim2.fromOffset(12, 66), Parent = touchLayer }, { corner(9), stroke(EDGE, 2) })
		menuToggle.Activated:Connect(function()
			if menu.Visible then
				closeMenu()
			else
				menu.Visible = true
				menuToggle.Text = "×  Fermer"
			end
		end)
	end
	for i, m in opts.menu or {} do
		local b = new("TextButton", { Name = m.id or m.label, Text = "", AutoButtonColor = true, BackgroundColor3 = DARK2, BackgroundTransparency = 0.10, Size = opts.compact and UDim2.new(1, -6, 0, 44) or UDim2.fromOffset(216, 52), LayoutOrder = i, Parent = menu },
			{ corner(10), stroke(EDGE, 1.5), grad(Color3.fromRGB(76, 58, 42), Color3.fromRGB(28, 23, 19)) })
		b.Selectable = true
		firstButton = firstButton or b
		if lastButton then
			lastButton.NextSelectionDown = b
			b.NextSelectionUp = lastButton
		end
		lastButton = b
		local icons = game:GetService("ReplicatedStorage"):FindFirstChild("IconesObjets")
		local model = m.model and icons and icons:FindFirstChild(m.model)
		local painted = m.id and require(script.Parent:WaitForChild("IconesPeintes"))
		local holder = new("Frame", { Size = opts.compact and UDim2.fromOffset(44, 42) or UDim2.fromOffset(56, 49), Position = UDim2.fromOffset(5, 1), BackgroundTransparency = 1, Parent = b })
		local hasPainted = painted and painted.add("menu:" .. m.id, holder, UDim2.fromScale(0.9, 0.9), 2, false)
		if not hasPainted and model and model:IsA("Model") then
			Hud.objectViewport(model).Parent = holder
		elseif not hasPainted then
			text({ Text = m.icon, TextSize = opts.compact and 25 or 35, TextXAlignment = Enum.TextXAlignment.Center, Size = opts.compact and UDim2.fromOffset(54, 44) or UDim2.fromOffset(65, 52), Parent = b })
		end
		text({ Text = m.label, Font = BOLD, TextSize = opts.compact and 17 or 18, TextStrokeTransparency = 0.6, Size = UDim2.new(1, opts.compact and -70 or -96, 1, 0), Position = UDim2.fromOffset(68, 0), Parent = b })
		if m.key and not opts.compact then
			text({ Text = typeof(m.key) == "EnumItem" and m.key.Name or m.key, Font = BOLD, TextSize = 13, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(28, 50), Position = UDim2.new(1, -32, 0, 0), Parent = b })
		end
		if m.fn then
			b.Activated:Connect(function()
				if nav and GuiService.SelectedObject == b then
					nav.rememberMenu(function()
						menu.Visible = true
						if menuToggle then menuToggle.Text = "×  Fermer" end
						GuiService.SelectedObject = b
					end)
				end
				closeMenu()
				m.fn()
			end)
		end
	end

	if firstButton then
		firstButton.NextSelectionUp = lastButton
		lastButton.NextSelectionDown = firstButton
	end
	if firstButton and nav then
		nav.bindMenu(menu, function()
			local selected = GuiService.SelectedObject
			if selected and selected:IsDescendantOf(menu) then
				closeMenu()
			elseif not nav.isOpen() then
				menu.Visible = true
				if menuToggle then
					menuToggle.Text = "×  Fermer"
				end
				GuiService.SelectedObject = firstButton
			end
		end, closeMenu)
	end

	-- notifications (bas-droite)
	self.notes = new("Frame", { Name = "Notifications", Size = UDim2.fromOffset(300, 400), Position = UDim2.new(1, -14, 1, -110), AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1, Parent = root },
		{ new("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }) })
	self.noteN = 0
	self.gainNotes = {}
	return self
end

-- ---------------------------------------------------------------- mises à jour
function Hud:setPlayer(name: string, badge: string?)
	self.name.Text = name
	if badge then
		self.badge.Text = badge
	end
end

function Hud:setPortrait(character: Model?)
	if self.portraitView then self.portraitView:Destroy() end
	local view = character and Hud.headViewport(character)
	self.portraitView = view
	if view then
		view.Size, view.ZIndex = UDim2.fromScale(1, 1), self.portrait.ZIndex
		corner(UDim.new(0.5, 0)).Parent = view
		view.Parent = self.portrait
	end
end

local function setBar(b, v: number, mx: number, color: Color3?)
	local k = math.clamp(v / math.max(1, mx), 0, 1)
	b.fill.Size = UDim2.fromScale(k, 1)
	b.fill.Visible = k > 0.001
	b.val.Text = string.format("%d / %d", math.floor(v + 0.5), math.floor(mx + 0.5))
	if color then
		b.fill.BackgroundColor3 = color
	end
end
function Hud:setBars(hp: number, hpMax: number, st: number, stMax: number, stColor: Color3?)
	setBar(self.hp, hp, hpMax)
	setBar(self.st, st, stMax, stColor or self.st.color)
end

local function thousands(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (out:gsub("^ ", ""))
end
function Hud:setGold(n: number)
	self.gold.Text = "💰 " .. thousands(n)
end
function Hud:setStars(stars: number, max: number, bounty: number?)
	self.stars.Text = stars > 0 and (string.rep("★", stars) .. string.rep("☆", max - stars) .. (bounty and ("  " .. thousands(bounty)) or "")) or ""
end

-- cap de la caméra en degrés (0 = nord, 90 = est)
local DIRECTIONS = { "N", "NE", "E", "SE", "S", "SO", "O", "NO" }

function Hud:setHeading(deg: number)
	self.strip.Position = UDim2.new(0.5, -(deg % 360) * self.PX_PER_DEG, 0, -2)
	self.heading.Text = DIRECTIONS[math.floor((deg + 22.5) / 45) % #DIRECTIONS + 1]
	self.arrow.Rotation = deg
end

function Hud:setPlace(icon: string, name: string)
	self.placeIcon.Text = icon
	self.placeName.Text = name
	self.placeName.Parent.Visible = name ~= ""
end

function Hud:setClock(day: number, h: number, m: number, skyIcon: string, weather: string)
	self.day.Text = string.format("Jour %d - %02d:%02d", day, h, m)
	self.sky.Text = skyIcon
	self.weather.Text = "Météo : " .. weather
end

-- colors : tableau n×n de Color3 (ligne par ligne, nord en haut) ; icons : { {x, y, icône} } en 0..1
function Hud:setMap(colors, icons)
	for i, f in self.mapCells do
		local c = colors[i]
		if c then
			f.BackgroundColor3 = c
		end
	end
	for _, c in self.mapIcons:GetChildren() do
		c:Destroy()
	end
	for _, ic in icons or {} do
		text({ Text = ic[3], TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(22, 22), Position = UDim2.fromScale(ic[1], ic[2]),
			AnchorPoint = Vector2.new(0.5, 0.5), Parent = self.mapIcons, ZIndex = 4 })
	end
end

-- notification à droite : icône ronde, titre (couleur), détail ; disparaît seule
function Hud:notify(icon: string, title: string, sub: string?, color: Color3?, life: number?)
	self.noteN += 1
	local card = new("Frame", { Size = UDim2.fromOffset(280, sub and 64 or 46), BackgroundColor3 = DARK, BackgroundTransparency = 0.12, LayoutOrder = self.noteN, Parent = self.notes },
		{ corner(10), stroke(EDGE_DIM, 2) })
	local disc = new("Frame", { Size = UDim2.fromOffset(42, 42), Position = UDim2.new(0, 10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Color3.fromRGB(20, 22, 28), Parent = card },
		{ corner(UDim.new(0.5, 0)), stroke(color or GOLD, 2) })
	text({ Text = icon, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = disc })
	local heading = text({ Text = title, Font = BOLD, TextSize = 18, TextColor3 = color or GOLD, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -70, 0, 24),
		Position = UDim2.fromOffset(62, sub and 8 or 11), Parent = card })
	if sub then
		text({ Text = sub, TextSize = 14, TextColor3 = DIM, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -70, 0, 20), Position = UDim2.fromOffset(62, 34), Parent = card })
	end
	local kids = {}
	for _, c in self.notes:GetChildren() do
		if c:IsA("Frame") then
			table.insert(kids, c)
		end
	end
	if #kids > 4 then
		table.sort(kids, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		kids[1]:Destroy()
	end
	local duration = life or 4.5
	local expires = os.clock() + duration
	local function expire()
		if not card.Parent then return end
		local remaining = expires - os.clock()
		if remaining > 0 then
			task.delay(remaining, expire)
		else
			card:Destroy()
		end
	end
	task.delay(duration, expire)
	return card, function(updatedTitle)
		heading.Text = updatedTitle
		expires = os.clock() + duration
	end
end

function Hud:gain(icon: string, name: string, amount: number)
	local key = icon .. " " .. name
	local entry = self.gainNotes[key]
	if entry and entry.card.Parent then
		entry.amount += amount
		entry.update(string.format("+%d %s", entry.amount, name))
		return
	end
	local card, update = self:notify(icon, string.format("+%d %s", amount, name))
	entry = { amount = amount, card = card, update = update }
	self.gainNotes[key] = entry
	card.Destroying:Connect(function()
		if self.gainNotes[key] == entry then
			self.gainNotes[key] = nil
		end
	end)
end

return Hud
