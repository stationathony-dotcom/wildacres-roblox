-- Journal des montures façon WoW (26/11 ; serveur : Systemes/Montures, catalogue : Shared/Ecurie).
-- [N] ou le bouton 🏇 du HUD : liste de toutes les montures (inconnues = « ??? » + indice vague), aperçu 3D
-- qui tourne, rareté en couleur, Invoquer / Favori / Au hasard. Barre d'invocation pendant les 2 s.
-- Version fonctionnelle (Claude) ; habillage final : lot Codex (docs/LOTS.md).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local Ecurie = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Ecurie"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WindowNav = require(script.Parent:WaitForChild("WindowNav"))
local Input = game:GetService("UserInputService")

local BOIS = Color3.fromRGB(44, 32, 24)
local BOIS_CLAIR = Color3.fromRGB(70, 52, 38)
local OR = Color3.fromRGB(214, 168, 78)
local TEXTE = Color3.fromRGB(240, 228, 206)
local GRIS = Color3.fromRGB(130, 124, 116)

local function new(class: string, props, children)
	local o = Instance.new(class)
	for k, v in props do
		(o :: any)[k] = v
	end
	for _, c in children or {} do
		c.Parent = o
	end
	return o
end
local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end
local function send(kind: string, data)
	Remotes.Action:FireServer(kind, data or {})
end

local gui = new("ScreenGui", { Name = "JournalMontures", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20,
	Parent = player:WaitForChild("PlayerGui") })
local panel = new("Frame", { Name = "Montures", Size = UDim2.new(0.62, 0, 0.7, 0), Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = BOIS, Visible = false, Parent = gui },
	{ corner(10), new("UISizeConstraint", { MinSize = Vector2.new(520, 340), MaxSize = Vector2.new(980, 640) }),
		new("UIStroke", { Color = OR, Thickness = 2 }) })
local titre = new("TextLabel", { Name = "Titre", Text = "Journal des montures", Font = Enum.Font.Fondamento, TextScaled = true, TextColor3 = OR,
	BackgroundTransparency = 1, Size = UDim2.new(1, -120, 0, 34), Position = UDim2.fromOffset(16, 8), TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })
local compte = new("TextLabel", { Text = "", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = TEXTE, BackgroundTransparency = 1,
	Size = UDim2.fromOffset(160, 24), Position = UDim2.new(1, -220, 0, 14), TextXAlignment = Enum.TextXAlignment.Right, Parent = panel })
local fermer = new("TextButton", { Text = "✕", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = TEXTE, BackgroundColor3 = BOIS_CLAIR,
	Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -44, 0, 10), Parent = panel }, { corner(6) })

local liste = new("ScrollingFrame", { Size = UDim2.new(0.42, -20, 1, -64), Position = UDim2.fromOffset(14, 52), BackgroundColor3 = Color3.fromRGB(30, 22, 17),
	ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = panel },
	{ corner(8), new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }), new("UIPadding", { PaddingTop = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10) }) })

local fiche = new("Frame", { Size = UDim2.new(0.58, -20, 1, -64), Position = UDim2.new(0.42, 6, 0, 52), BackgroundTransparency = 1, Parent = panel })
local vue = new("ViewportFrame", { Size = UDim2.new(1, 0, 0.58, 0), BackgroundColor3 = Color3.fromRGB(58, 74, 92), Ambient = Color3.fromRGB(150, 150, 160),
	LightColor = Color3.fromRGB(255, 244, 225), LightDirection = Vector3.new(-1, -1.2, -0.6), Parent = fiche }, { corner(8),
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(120, 150, 180), Color3.fromRGB(40, 48, 60)), Rotation = 90 }) })
local cam = new("Camera", { FieldOfView = 40, Parent = vue })
vue.CurrentCamera = cam
local nom = new("TextLabel", { Text = "", Font = Enum.Font.Fondamento, TextScaled = true, TextColor3 = TEXTE, BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0.09, 0), Position = UDim2.new(0, 0, 0.6, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = fiche })
local details = new("TextLabel", { Text = "", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = TEXTE, BackgroundTransparency = 1, TextWrapped = true,
	RichText = true, Size = UDim2.new(1, 0, 0.18, 0), Position = UDim2.new(0, 0, 0.69, 0), TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top, Parent = fiche })
local function bouton(texte: string, x: number, w: number)
	return new("TextButton", { Text = texte, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.fromRGB(30, 22, 16), BackgroundColor3 = OR,
		AutoButtonColor = true, Size = UDim2.new(w, -6, 0.1, 0), Position = UDim2.new(x, 0, 0.9, 0), Parent = fiche }, { corner(6) })
end
local bInvoquer = bouton("Invoquer", 0, 0.4)
local bFavori = bouton("☆ Favori", 0.4, 0.3)
local bHasard = bouton("🎲 Au hasard", 0.7, 0.3)

local function adapter()
	local ecran = gui.AbsoluteSize
	if ecran.X < 1 or ecran.Y < 1 then return end
	local etroit = ecran.X < 560
	local zone = panel:FindFirstChildOfClass("UISizeConstraint")
	zone.MinSize = Vector2.new(math.min(520, ecran.X - 20), math.min(340, ecran.Y - 18))
	panel.Size = UDim2.fromScale(etroit and 0.94 or 0.62, etroit and 0.86 or 0.7)
	titre.Size = UDim2.new(1, etroit and -174 or -220, 0, 34)
	compte.Size = UDim2.fromOffset(etroit and 106 or 160, 24)
	compte.Position = UDim2.new(1, etroit and -158 or -220, 0, 14)
	compte.TextSize = etroit and 12 or 15
	for _, b in { bInvoquer, bFavori, bHasard } do
		b.TextScaled = etroit
	end
	if Input.TouchEnabled then
		fermer.Size = UDim2.fromOffset(38, 38)
		fermer.Position = UDim2.new(1, -46, 0, 7)
	end
end
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(adapter)
adapter()

-- barre d'invocation
local barre = new("Frame", { Size = UDim2.fromOffset(260, 14), Position = UDim2.new(0.5, 0, 0.78, 0), AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(20, 16, 12), Visible = false, Parent = gui }, { corner(7), new("UIStroke", { Color = OR, Thickness = 1.5 }) })
local remplissage = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = OR, Parent = barre }, { corner(7) })

local etat = { ids = {}, fav = nil }
local choisi: string? = nil
local apercu: Model? = nil
local angle = 0

local function lireEtat()
	local raw = player:GetAttribute("Montures")
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw or "{}")
	end)
	etat.ids, etat.fav = {}, nil
	if ok and type(data) == "table" then
		for _, id in data.ids or {} do
			etat.ids[id] = true
		end
		etat.fav = data.fav
	end
end

local function montrer(id: string)
	choisi = id
	local m = Ecurie.BY_ID[id]
	local connue = etat.ids[id] == true
	local r = Ecurie.RARITY[m.rarity]
	if apercu then
		apercu:Destroy()
		apercu = nil
	end
	local dossier = ReplicatedStorage:FindFirstChild("ApercusMontures")
	local source = dossier and dossier:FindFirstChild(id)
	if source then
		apercu = source:Clone()
		if not connue then
			for _, p in apercu:GetDescendants() do
				if p:IsA("BasePart") then
					p.Color = Color3.fromRGB(18, 18, 22)
					p.Material = Enum.Material.SmoothPlastic
				end
			end
		end
		apercu.Parent = vue
	end
	nom.Text = connue and m.name or "???"
	nom.TextColor3 = connue and r.color or GRIS
	local vit = m.type == "vol" and (m.speed .. " studs/s en vol") or (math.floor(m.speed * 100) .. " % d'un cheval")
	details.Text = (connue and ("<b>" .. r.name .. "</b> · " .. (m.type == "vol" and "Volante" or "Terrestre") .. " · " .. vit .. "\n") or "")
		.. "<i>" .. m.hint .. "</i>"
		.. (m.type == "vol" and ("\nVol : Équitation " .. Ecurie.FLY_SKILL .. " requise.") or "")
	bInvoquer.Visible = connue
	bFavori.Visible = connue
	bFavori.Text = etat.fav == id and "★ Favori" or "☆ Favori"
end

local function remplir()
	lireEtat()
	for _, c in liste:GetChildren() do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local n, total = 0, 0
	local tri = table.clone(Ecurie.LIST)
	table.sort(tri, function(a, b)
		local ka, kb = etat.ids[a.id] and 0 or 1, etat.ids[b.id] and 0 or 1
		if ka ~= kb then
			return ka < kb
		end
		if a.type ~= b.type then
			return a.type == "sol"
		end
		return a.order < b.order
	end)
	for i, m in tri do
		total += 1
		local connue = etat.ids[m.id] == true
		if connue then
			n += 1
		end
		local r = Ecurie.RARITY[m.rarity]
		local b = new("TextButton", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, Input.TouchEnabled and 42 or 30), BackgroundColor3 = BOIS_CLAIR, AutoButtonColor = true,
			Text = "  " .. (m.type == "vol" and "🪶 " or "🐎 ") .. (connue and m.name or "???") .. (etat.fav == m.id and "  ★" or ""),
			Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = connue and r.color or GRIS, Parent = liste }, { corner(5) })
		b.Activated:Connect(function()
			montrer(m.id)
		end)
	end
	compte.Text = n .. " / " .. total .. " montures"
	montrer(choisi or tri[1].id)
end

local function basculer()
	panel.Visible = not panel.Visible
	if panel.Visible then
		remplir()
	end
end

fermer.Activated:Connect(function()
	panel.Visible = false
end)
bInvoquer.Activated:Connect(function()
	if choisi then
		send("monture", { id = choisi })
		panel.Visible = false
	end
end)
bFavori.Activated:Connect(function()
	if choisi then
		send("monture_favori", { id = choisi })
	end
end)
bHasard.Activated:Connect(function()
	send("monture_hasard")
	panel.Visible = false
end)
player:GetAttributeChangedSignal("Montures"):Connect(function()
	if panel.Visible then
		remplir()
	end
end)

local ouvrir = Instance.new("BindableEvent")
ouvrir.Name = "OuvrirMontures"
ouvrir.Event:Connect(basculer)
ouvrir.Parent = player
WindowNav.watch(panel, fermer, function()
	panel.Visible = false
end)

RunService.RenderStepped:Connect(function(dt)
	-- aperçu qui tourne
	if panel.Visible and apercu then
		angle += dt * 0.6
		local cf, size = apercu:GetBoundingBox()
		local d = math.max(size.X, size.Y, size.Z) * 1.7
		cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(math.sin(angle) * d, size.Y * 0.35, math.cos(angle) * d), cf.Position)
	end
	-- barre d'invocation
	local fin = player:GetAttribute("Invocation")
	if fin then
		local reste = fin - workspace:GetServerTimeNow()
		barre.Visible = reste > 0
		remplissage.Size = UDim2.fromScale(math.clamp(1 - reste / Ecurie.CAST, 0, 1), 1)
	else
		barre.Visible = false
	end
end)
