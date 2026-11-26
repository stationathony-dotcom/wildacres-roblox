-- Wild Acres — interface du joueur (PC + mobile).
-- Accueil : liste des mondes. En jeu : barre du haut (monde, jour, heure, biome, or, honneur,
-- étoiles, endurance), messages, fondu, sac + équipement, atelier, boutique, dialogues, boutons tactiles.
-- Le serveur décide de tout ; ici on affiche et on envoie des demandes (Remotes.Action).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Gear = require(Shared:WaitForChild("Gear"))
local ApercuPose = require(script.Parent:WaitForChild("ApercuPose"))
local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ================================================================ Style

local C = {
	panel = Color3.fromRGB(46, 33, 25),
	panel2 = Color3.fromRGB(70, 50, 36),
	line = Color3.fromRGB(150, 110, 70),
	text = Color3.fromRGB(250, 241, 222),
	dim = Color3.fromRGB(200, 184, 160),
	gold = Color3.fromRGB(240, 196, 70),
	green = Color3.fromRGB(110, 180, 90),
	red = Color3.fromRGB(220, 80, 70),
	blue = Color3.fromRGB(90, 150, 220),
}
local TITLE = Enum.Font.FredokaOne
local BODY = Enum.Font.GothamMedium
local BOLD = Enum.Font.GothamBold

local new = Composants.creer

local function corner(r: number?)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 10) })
end

local function stroke(color: Color3?, th: number?)
	return new("UIStroke", { Color = color or C.line, Thickness = th or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function pad(p: number)
	return new("UIPadding", { PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p) })
end

local function label(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or BODY
	props.TextColor3 = props.TextColor3 or C.text
	props.TextSize = props.TextSize or 16
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.TextWrapped = props.TextWrapped ~= false
	return new("TextLabel", props)
end

local function button(text: string, color: Color3?, onClick: () -> ())
	return Composants.bouton({
		Text = text, Font = BOLD, TextSize = 16, TextColor3 = C.text,
		BackgroundColor3 = color or C.panel2, Size = UDim2.new(0, 120, 0, 36),
	}, onClick, { corner(8), stroke(C.line, 1.5) })
end

local gui = new("ScreenGui", { Name = "WildAcres", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
local uiScale = new("UIScale", { Parent = gui })
local Hud = require(script.Parent:WaitForChild("Hud"))
local MiseEnPage = require(script.Parent:WaitForChild("MiseEnPage"))
local IconesPeintes = require(script.Parent:WaitForChild("IconesPeintes"))
local toolIcon: (string, Instance, number, boolean) -> boolean

-- Chat en bas à gauche comme l'image cible (par défaut Roblox le met en haut à gauche, sur le portrait)
pcall(function()
	local TCS = game:GetService("TextChatService")
	local w = TCS:FindFirstChildOfClass("ChatWindowConfiguration")
	if w then
		w.HorizontalAlignment = Enum.HorizontalAlignment.Left
		w.VerticalAlignment = Enum.VerticalAlignment.Bottom
		w.WidthScale = 0.85
		w.HeightScale = 0.7
		w.BackgroundColor3 = Color3.fromRGB(32, 25, 20)
		w.BackgroundTransparency = 0.35
		w.TextColor3 = Color3.fromRGB(248, 242, 228)
		w.TextSize = 15
	end
	local bar = TCS:FindFirstChildOfClass("ChatInputBarConfiguration")
	if bar then
		bar.BackgroundColor3 = Color3.fromRGB(28, 22, 18)
		bar.BackgroundTransparency = 0.25
		bar.PlaceholderColor3 = Color3.fromRGB(196, 188, 170)
	end
	local tabs = TCS:FindFirstChildOfClass("ChannelTabsConfiguration")
	if tabs then
		tabs.Enabled = true
		tabs.BackgroundColor3 = Color3.fromRGB(55, 42, 31)
		tabs.SelectedTabTextColor3 = Color3.fromRGB(246, 200, 70)
	end
end)
local hudScaleUpdate: (() -> ())? = nil -- HUD et barre rapide : échelle de l'image cible
local hotScale: UIScale? = nil
local function rescale()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	gui.ScreenInsets = MOBILE and Enum.ScreenInsets.CoreUISafeInsets or Enum.ScreenInsets.DeviceSafeInsets
	uiScale.Scale = math.clamp(math.min(v.X / 1100, v.Y / 640), MOBILE and 0.9 or 0.62, 1.25)
	if hudScaleUpdate then
		hudScaleUpdate()
	end
	if hotScale then
		-- la barre vit dans « gui » (glisser-déposer avec le sac) : on compense son échelle
		hotScale.Scale = Hud.scaleFor(v) * 1.12 / uiScale.Scale
	end
end
rescale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(rescale)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local function send(kind: string, data)
	Remotes.Action:FireServer(kind, data or {})
end

-- Panneau générique (titre + bouton fermer + zone défilante)
local WindowNav = require(script.Parent:WaitForChild("WindowNav"))
local panels = {}
local function makePanel(name: string, title: string, size: UDim2, onClose: (() -> ())?)
	local f = new("Frame", {
		Name = name, Size = size, Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.panel, BackgroundTransparency = 0.04, Visible = false, Parent = gui, ZIndex = 5,
	}, { corner(14), stroke(C.line, 2.5) })
	local t = Composants.titre({ Text = title, Font = TITLE, TextSize = 24, TextColor3 = C.gold, Size = UDim2.new(1, -60, 0, 40), Position = UDim2.fromOffset(16, 8), Parent = f, ZIndex = 6 })
	local function dismiss()
		f.Visible = false
		if onClose then onClose() end
	end
	local close = button("×", C.red, dismiss)
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -46, 0, 10)
	close.ZIndex = 6
	close.Parent = f
	WindowNav.watch(f, close, dismiss)
	local body = new("ScrollingFrame", {
		Size = UDim2.new(1, -24, 1, -64), Position = UDim2.fromOffset(12, 54), BackgroundTransparency = 1,
		ScrollBarThickness = 6, ScrollBarImageColor3 = C.line, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0, Parent = f, ZIndex = 6,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	MiseEnPage.bind(f, uiScale)
	panels[name] = f
	return f, body, t
end

local function clear(container: Instance)
	for _, c in container:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIGridLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function closeAll()
	for _, p in panels do
		p.Visible = false
	end
end

-- ================================================================ Messages et fondu

local toastBox = new("Frame", {
	Size = UDim2.new(0, 520, 0, 300), Position = UDim2.new(0.5, 0, 0, 108), AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1, Parent = gui, ZIndex = 20,
}, { new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
local toastN = 0
local hudNotify = nil -- en jeu : les gains vont dans les notifications du HUD (bas-droite)
local placementRefusal = ApercuPose.refus(gui, MOBILE and 240 or 300)

local function toast(text: string, kind: string?)
	if kind == "refus" and not WindowNav.isOpen() and placementRefusal.show(text) then
		return
	end
	if hudNotify and (kind == "gain" or kind == "loot") then
		hudNotify(Composants.texteCompatible(text), kind)
		return
	end
	toastN += 1
	local big = kind == "big"
	local urgent = kind == "danger"
	local color = (urgent or kind == "refus") and C.red or (big and C.gold or C.text)
	local t = label({
		Text = urgent and Composants.avertissement(text) or text, TextColor3 = color, TextSize = big and 22 or 16, Font = big and TITLE or BODY,
		TextXAlignment = Enum.TextXAlignment.Center, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 0.25, BackgroundColor3 = C.panel,
		LayoutOrder = urgent and -toastN or toastN, Parent = toastBox, ZIndex = 20,
	})
	corner(8).Parent = t
	pad(8).Parent = t
	local life = urgent and 7 or (big and 5 or 3.5)
	task.delay(life, function()
		if not t.Parent then return end
		local tw = TweenService:Create(t, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 })
		tw:Play()
		tw.Completed:Wait()
		t:Destroy()
	end)
	local kids = {}
	for _, c in toastBox:GetChildren() do
		if c:IsA("TextLabel") and (c.LayoutOrder < 0) == urgent then
			table.insert(kids, c)
		end
	end
	if #kids > (urgent and 3 or 5) then
		table.sort(kids, function(a, b)
			return math.abs(a.LayoutOrder) < math.abs(b.LayoutOrder)
		end)
		kids[1]:Destroy()
	end
end
Remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)

local fade = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Parent = gui, ZIndex = 50, Active = false })
local fadeText = label({ Text = "", Font = TITLE, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), TextTransparency = 1, Parent = fade, ZIndex = 51 })
Remotes:WaitForChild("Fade").OnClientEvent:Connect(function(text: string?, target: number)
	target = target or 1
	if text then
		fadeText.Text = text
	end
	TweenService:Create(fade, TweenInfo.new(0.6), { BackgroundTransparency = target }):Play()
	TweenService:Create(fadeText, TweenInfo.new(0.6), { TextTransparency = (target >= 1) and 1 or 0 }):Play()
end)

-- ================================================================ ACCUEIL (liste des mondes)

local function lobby()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.new(0, 60, 0) * CFrame.Angles(math.rad(-8), 0, 0)
	local blur = new("BlurEffect", { Size = 10, Parent = Lighting })

	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 220, 160), Color3.fromRGB(40, 30, 50)), Transparency = NumberSequence.new(0.6, 0.15), Parent = bg })
	bg.BackgroundTransparency = 0
	label({ Text = "Wild Acres", Font = TITLE, TextSize = 64, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 80), Position = UDim2.fromOffset(0, 30), Parent = bg })
	label({ Text = "Cultive, fabrique, vole… et ne te fais pas prendre.", TextSize = 18, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 104), Parent = bg })

	local box = new("Frame", {
		Size = UDim2.new(0, 560, 0, 380), Position = UDim2.new(0.5, 0, 0, 150), AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = C.panel, BackgroundTransparency = 0.05, Parent = bg,
	}, { corner(14), stroke(C.line, 2.5) })
	label({ Text = "Choisis ton monde", Font = TITLE, TextSize = 24, TextColor3 = C.gold, Size = UDim2.new(1, -32, 0, 36), Position = UDim2.fromOffset(16, 10), Parent = box })
	MiseEnPage.bind(box, uiScale)
	local status = label({ Text = "Recherche des mondes…", TextSize = 14, TextColor3 = C.dim, Size = UDim2.new(1, -32, 0, 20), Position = UDim2.fromOffset(16, 44), Parent = box })
	local list = new("ScrollingFrame", {
		Size = UDim2.new(1, -24, 1, -140), Position = UDim2.fromOffset(12, 70), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = box,
	}, { new("UIListLayout", { Padding = UDim.new(0, 6) }) })
	local busy = false
	local function go(action: string, id: string?)
		if busy or player:GetAttribute("Banni") ~= nil then
			return
		end
		busy = true
		status.Text = "Préparation du voyage…"
		local ok, res = pcall(function()
			return Remotes:WaitForChild("Mondes"):InvokeServer(action, id)
		end)
		if ok and res then
			status.Text = res.msg or ""
			if not res.ok then
				busy = false
			else
				-- la téléportation peut encore échouer plus tard : on débloque au bout de 25 s
				task.delay(25, function()
					if busy and bg.Parent then
						busy = false
						status.Text = "Le voyage n'a pas abouti. Réessaie (ou choisis un autre monde)."
					end
				end)
			end
		else
			status.Text = "Le serveur ne répond pas, réessaie."
			busy = false
		end
	end
	game:GetService("TeleportService").TeleportInitFailed:Connect(function(_, result)
		busy = false
		status.Text = result == Enum.TeleportResult.GameFull and "Ce monde est plein : choisis-en un autre."
			or "Le voyage a échoué. Réessaie dans un instant."
	end)
	local play = button("▶  Jouer", C.green, function()
		go("play")
	end)
	play.Size = UDim2.new(1, -24, 0, 50)
	play.Position = UDim2.new(0, 12, 1, -62)
	play.TextSize = 22
	play.Font = TITLE
	play.Parent = box
	play.Size = UDim2.new(0.5, -16, 0, 50)
	local showSupport = require(script.Parent:WaitForChild("FormulaireEquipe")).mount(gui, Remotes.Action)
	local support = button("Écrire à l’équipe", C.blue, function()
		showSupport(player:GetAttribute("Banni") ~= nil)
	end)
	support.Size = UDim2.new(0.5, -16, 0, 50)
	support.Position = UDim2.new(0.5, 4, 1, -62)
	support.Parent = box
	local function updateBan()
		local banned = player:GetAttribute("Banni") ~= nil
		play.Interactable = not banned
		play.BackgroundColor3 = banned and C.panel2 or C.green
		list.Visible = not banned
		support.Text = banned and "Faire appel" or "Écrire à l’équipe"
		if banned then
			status.Text = "Accès aux mondes suspendu."
			showSupport(true)
		end
	end
	player:GetAttributeChangedSignal("Banni"):Connect(updateBan)
	updateBan()

	local function refresh()
		if player:GetAttribute("Banni") ~= nil then return end
		local ok, worlds = pcall(function()
			return Remotes:WaitForChild("Mondes"):InvokeServer("list")
		end)
		if not ok or type(worlds) ~= "table" then
			status.Text = "Liste indisponible pour l'instant."
			return
		end
		if player:GetAttribute("Banni") ~= nil then return end
		local friendsOK, friends = pcall(function()
			return Remotes.Mondes:InvokeServer("friends")
		end)
		if player:GetAttribute("Banni") ~= nil then return end
		clear(list)
		label({ Text = "Mes amis en jeu", Font = TITLE, TextSize = 18, TextColor3 = C.gold,
			Size = UDim2.new(1, -8, 0, 24), LayoutOrder = -1000, Parent = list })
		if friendsOK and type(friends) == "table" and #friends > 0 then
			for i, friend in friends do
				local row = new("Frame", { Size = UDim2.new(1, -8, 0, 48), BackgroundColor3 = C.panel2, LayoutOrder = i - 999, Parent = list }, { corner(8) })
				label({ Text = friend.name, Font = BOLD, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -138, 0, 22), Position = UDim2.fromOffset(10, 2), Parent = row })
				label({ Text = friend.worldName or friend.worldId, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = C.dim, Size = UDim2.new(1, -138, 0, 18), Position = UDim2.fromOffset(10, 25), Parent = row })
				local join = button("Rejoindre", C.blue, function() go("join", friend.worldId) end)
				join.Size, join.Position, join.Parent = UDim2.fromOffset(112, 36), UDim2.new(1, -118, 0, 6), row
			end
		else
			label({ Text = friendsOK and "Aucun ami dans un monde pour le moment." or "Liste des amis momentanément indisponible.", TextColor3 = C.dim,
				TextSize = 13, Size = UDim2.new(1, -8, 0, 24), LayoutOrder = -999, Parent = list })
		end
		label({ Text = "Mondes ouverts", Font = TITLE, TextSize = 18, TextColor3 = C.gold,
			Size = UDim2.new(1, -8, 0, 24), LayoutOrder = 0, Parent = list })
		local total = 0
		for i, w in worlds do
			total += w.n
			local full = w.n >= w.cap
			local row = new("Frame", { Size = UDim2.new(1, -8, 0, 48), BackgroundColor3 = C.panel2, LayoutOrder = i, Parent = list }, { corner(8) })
			label({ Text = w.name, Font = BOLD, TextSize = 18, Size = UDim2.new(1, -230, 0, 26), Position = UDim2.fromOffset(12, 2), Parent = row })
			-- thème de l'île (glaces, sables, brumes…) : chaque île a ses biomes, ses villages, sa faune
			label({ Text = w.theme and ((w.themeIcon or "") .. " " .. w.theme) or "", TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, -230, 0, 18), Position = UDim2.fromOffset(12, 27), Parent = row })
			local fill = w.n / math.max(1, w.cap)
			label({ Text = string.format("👥 %d / %d", w.n, w.cap), TextSize = 16, TextColor3 = full and C.red or (fill > 0.5 and C.gold or C.green), Size = UDim2.fromOffset(100, 48), Position = UDim2.new(1, -220, 0, 0), Parent = row })
			local b = button(full and "Plein" or "Rejoindre", full and C.panel or C.blue, function()
				if not full then
					go("join", w.id)
				end
			end)
			b.Size = UDim2.fromOffset(110, 36)
			b.Position = UDim2.new(1, -118, 0, 6)
			b.Parent = row
		end
		status.Text = string.format("%d monde(s) ouvert(s), %d joueur(s) en ce moment", #worlds, total)
	end
	task.spawn(function()
		while bg.Parent do
			refresh()
			task.wait(12)
		end
	end)
	-- la caméra tourne doucement au-dessus du vide
	local a = 0
	RunService.RenderStepped:Connect(function(dt)
		a += dt * 0.05
		cam.CFrame = CFrame.new(0, 60, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-8), 0, 0)
	end)
	local _ = blur
end

-- ================================================================ EN JEU

local function game_()
	-- ---------------------------------------------------------------- HUD façon MMO (module Hud)
	-- portrait + vie/endurance/or, boussole + lieu, jour/heure/météo, minicarte, colonne de boutons,
	-- notifications à droite. Les boutons sont branchés plus bas (menuActions), quand les panneaux existent.
	local menuActions = {}
	local function act(id: string)
		return function()
			local f = menuActions[id]
			if f then
				f()
			end
		end
	end
	local function fireLocal(name: string)
		return function()
			local b = player:FindFirstChild(name)
			if b then
				b:Fire()
			end
		end
	end
	-- HUD dans sa propre ScreenGui, à l'échelle de l'image cible (cf. Hud.scaleFor)
	local hudGui = new("ScreenGui", { Name = "HudMMO", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = gui.DisplayOrder - 1, Parent = player:WaitForChild("PlayerGui") })
	local hudScale = new("UIScale", { Parent = hudGui })
	hudScaleUpdate = function()
		local cam = workspace.CurrentCamera
		hudScale.Scale = Hud.scaleFor(cam and cam.ViewportSize or Vector2.new(1280, 720))
	end
	hudScaleUpdate()
	local menu = {
		{ id = "sac", icon = "🎒", model = "backpack", label = "Sac", key = Enum.KeyCode.B, fn = act("sac") },
		{ id = "perso", icon = "🧍", label = "Personnage", key = Enum.KeyCode.P, fn = act("perso") },
		{ id = "talents", icon = "⭐", model = "skill_book", label = "Compétences", key = Enum.KeyCode.K, fn = act("talents") },
		{ id = "quetes", icon = "📜", model = "parchment", label = "Journal", key = Enum.KeyCode.J, fn = fireLocal("OuvrirQuetes") },
		{ id = "carte", icon = "🗺️", model = "map_world", label = "Carte", key = Enum.KeyCode.M, fn = fireLocal("OuvrirCarte") },
		{ id = "clan", icon = "🛡️", label = "Clan", key = Enum.KeyCode.L, fn = act("clan") },
		{ id = "atelier", icon = "🛠️", model = "workbench", label = "Atelier", key = Enum.KeyCode.C, fn = act("atelier") },
		-- journal des montures façon WoW (Montures.client, 26/11)
		{ id = "montures", icon = "🏇", label = "Montures", key = Enum.KeyCode.N, fn = fireLocal("OuvrirMontures") },
		{ id = "parametres", icon = "⚙️", label = "Paramètres", key = Enum.KeyCode.O, fn = fireLocal("OuvrirParametres") },
	}
	local menuKeys = { [Enum.KeyCode.Tab] = menu[1].fn }
	for _, entry in menu do
		menuKeys[entry.key] = entry.fn
	end
	local hud = Hud.build(hudGui, { compact = MOBILE, menu = menu, onMap = menu[5].fn, gamepad = true })
	local updateFichePortrait
	hudNotify = function(text: string, kind: string?)
		local n, icon, name = string.match(text, "^%+(%d+) (%S+) (.+)$")
		if n then
			if name:match(" %(%d+%)$") then
				hud:notify(icon, "+" .. n .. " " .. name)
			else
				hud:gain(icon, name, tonumber(n))
			end
		elseif kind == "gain" and text:match("^%+%d+ 💰$") then
			hud:gain("💰", "Or", tonumber(text:match("%d+")))
		elseif kind == "loot" then
			hud:notify("⚔️", "Équipement trouvé", (string.gsub(text, "^Équipement trouvé : ", "")), Color3.fromRGB(190, 120, 255))
		else
			hud:notify("✨", text)
		end
	end
	hud:setPlayer(player.DisplayName, "😇")
	Hud.watchAvatar(player, function(character)
		hud:setPortrait(character)
		if updateFichePortrait then updateFichePortrait(character) end
	end)

	local biomeNames = {}
	for id, b in Config.BIOMES do
		biomeNames[id] = b.name
	end
	local BIOME_ICONS = { prairie = "🌼", foret = "🍂", desert = "🌵", neige = "❄️", marais = "🐸" }
	local BIOME_MAP = {
		prairie = Color3.fromRGB(118, 172, 78), foret = Color3.fromRGB(186, 118, 56), desert = Color3.fromRGB(226, 200, 130),
		neige = Color3.fromRGB(226, 234, 240), marais = Color3.fromRGB(88, 112, 72),
	}
	local POI_ICON = { village = "🏘️", farm = "🌾", ruin = "🏚️", lair = "💀" }
	local WEATHER = { clair = "Ensoleillé", nuageux = "Nuageux", pluie = "Pluie", orage = "Orage", brouillard = "Brouillard" }
	local WEATHER_ICON = { clair = "☀️", nuageux = "⛅", pluie = "🌧️", orage = "⛈️", brouillard = "🌫️" }
	local wg = nil
	local function worldGen()
		local seed = workspace:GetAttribute("Seed")
		if not seed then
			return nil
		end
		if not wg or wg.seed ~= seed then
			local ok, WG = pcall(require, Shared:WaitForChild("WorldGen"))
			if not ok then
				return nil
			end
			wg = WG.new(seed, workspace:GetAttribute("Gen"))
		end
		return wg
	end
	local function rootPos(): Vector3?
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		return root and root.Position or nil
	end
	local function biomeHere(): string?
		local w, pos = worldGen(), rootPos()
		if not w or not pos then
			return nil
		end
		return w:biome(math.floor(pos.X / Config.CELL), math.floor(pos.Z / Config.CELL))
	end
	-- nom du lieu : village / ferme / ruine / antre où l'on se trouve, sinon parcelle, sinon biome
	local function placeHere(pos: Vector3, b: string?): (string, string)
		local w = worldGen()
		if w then
			local cx, cz = math.floor(pos.X / Config.CELL), math.floor(pos.Z / Config.CELL)
			local rx, rz = math.floor(cx / Config.REGION), math.floor(cz / Config.REGION)
			local poi = w:poiOf(rx, rz)
			if poi and cx >= poi.x0 - 8 and cx <= poi.x0 + poi.w + 8 and cz >= poi.z0 - 8 and cz <= poi.z0 + poi.d + 8 then
				local name = poi.kind == "village" and poi.name or poi.kind == "farm" and ("Ferme de " .. poi.name)
					or poi.kind == "ruin" and (poi.start and "Les vieilles ruines" or "Ruines") or poi.name
				if poi.kind == "village" then
					-- palier de réputation auprès de ce village (Systemes/Reputation), s'il te connaît
					local ok, rep = pcall(function()
						return game:GetService("HttpService"):JSONDecode(player:GetAttribute("Reputation") or "{}")
					end)
					local val = ok and type(rep) == "table" and rep[poi.name]
					if val then
						local tier = val >= 85 and "Héros" or val >= 50 and "Honoré" or val >= 20 and "Apprécié"
							or val <= -60 and "Haï" or val <= -20 and "Mal vu" or nil
						if tier then
							name = name .. " · " .. tier
						end
					end
				end
				return POI_ICON[poi.kind] or "📍", name
			end
		end
		-- villes fondées par les joueurs (Systemes/Villes)
		local vf = ReplicatedStorage:FindFirstChild("Villes")
		if vf then
			for _, c in vf:GetChildren() do
				local r = c:GetAttribute("R") or 70
				if Vector2.new((c:GetAttribute("X") or 0) - pos.X, (c:GetAttribute("Z") or 0) - pos.Z).Magnitude <= r then
					return "🏰", tostring(c:GetAttribute("Name") or "Ville")
				end
			end
		end
		local pf = ReplicatedStorage:FindFirstChild("Parcelles")
		if pf then
			for _, c in pf:GetChildren() do
				local half = c:GetAttribute("Half") or 24
				if math.abs(pos.X - (c:GetAttribute("X") or 0)) <= half and math.abs(pos.Z - (c:GetAttribute("Z") or 0)) <= half then
					return "🏡", c:GetAttribute("OwnerId") == player.UserId and "Chez toi" or ("Terrain de " .. (c:GetAttribute("Owner") or "?"))
				end
			end
		end
		if b then
			return BIOME_ICONS[b] or "🌍", biomeNames[b] or b
		end
		return "🌍", workspace:GetAttribute("WorldName") or "Wild Acres"
	end
	-- minicarte : biomes et eau autour du joueur (nord en haut), lieux proches en icônes
	local MAP_STEP = 3 -- cases (4 studs) par point
	local lastMapCell = nil
	local function refreshMap(pos: Vector3)
		local w = worldGen()
		if not w then
			return
		end
		local N = hud.mapN
		local cx0, cz0 = math.floor(pos.X / Config.CELL), math.floor(pos.Z / Config.CELL)
		local key = math.floor(cx0 / MAP_STEP) .. "," .. math.floor(cz0 / MAP_STEP)
		if key == lastMapCell then
			return
		end
		lastMapCell = key
		local colors, icons = {}, {}
		for j = 0, N - 1 do
			for i = 0, N - 1 do
				local cx, cz = cx0 + (i - N // 2) * MAP_STEP, cz0 + (j - N // 2) * MAP_STEP
				colors[j * N + i + 1] = w:wetRaw(cx, cz) and Color3.fromRGB(70, 120, 170) or BIOME_MAP[w:biome(cx, cz)]
			end
		end
		local half = N // 2 * MAP_STEP
		local rx0, rz0 = math.floor(cx0 / Config.REGION), math.floor(cz0 / Config.REGION)
		for rz = rz0 - 1, rz0 + 1 do
			for rx = rx0 - 1, rx0 + 1 do
				local poi = w:poiOf(rx, rz)
				if poi then
					local u = ((poi.x0 + poi.w / 2) - cx0 + half) / (2 * half)
					local v = ((poi.z0 + poi.d / 2) - cz0 + half) / (2 * half)
					if u > 0.05 and u < 0.95 and v > 0.05 and v < 0.95 then
						table.insert(icons, { u, v, POI_ICON[poi.kind] or "📍" })
					end
				end
			end
		end
		-- filons repérés (façon « Découverte de gisements » de WoW) : minage 5+ ; chaque filon
		-- demande au moins sa compétence de minage pour apparaître
		local mining = player:GetAttribute("Comp_minage") or 0
		if mining >= 5 then
			local ORE_ICON = { ore_coal = "⚫", ore_copper = "🟠", ore_iron = "⚪", ore_gold = "🟡" }
			local span = 2 * half * Config.CELL
			for _, m in CollectionService:GetTagged("Filon") do
				if m:IsA("Model") and m.Parent and mining >= (m:GetAttribute("MinSkill") or 0) then
					local pp = m:GetPivot().Position
					local u = (pp.X - (cx0 - half) * Config.CELL) / span
					local v = (pp.Z - (cz0 - half) * Config.CELL) / span
					if u > 0.04 and u < 0.96 and v > 0.04 and v < 0.96 then
						table.insert(icons, { u, v, ORE_ICON[m.Name] or "💎" })
					end
				end
			end
		end
		-- plantes sauvages repérées (herboristerie) : agriculture 5+, chacune selon sa difficulté
		local herbal = player:GetAttribute("Comp_agriculture") or 0
		if herbal >= 5 then
			local span = 2 * half * Config.CELL
			for _, m in CollectionService:GetTagged("Herbe") do
				if m:IsA("Model") and m.Parent and herbal >= (m:GetAttribute("MinSkill") or 0) then
					local pp = m:GetPivot().Position
					local u = (pp.X - (cx0 - half) * Config.CELL) / span
					local v = (pp.Z - (cz0 - half) * Config.CELL) / span
					if u > 0.04 and u < 0.96 and v > 0.04 and v < 0.96 then
						table.insert(icons, { u, v, "🌿" })
					end
				end
			end
		end
		hud:setMap(colors, icons)
	end

	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if cam then
			local look = cam.CFrame.LookVector
			hud:setHeading(math.deg(math.atan2(look.X, -look.Z)))
		end
	end)

	local lastBiome = nil
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		local minutes = workspace:GetAttribute("Minutes") or 360
		local h = math.floor(minutes / 60) % 24
		local m = math.floor(minutes % 60)
		local b = biomeHere()
		if b and b ~= lastBiome then
			if lastBiome then
				toast(BIOME_ICONS[b] .. " " .. biomeNames[b], nil)
			end
			lastBiome = b
		end
		local night = h < 6 or h >= 21
		local wk = workspace:GetAttribute("Weather") or "clair"
		local wname, wicon = WEATHER[wk] or wk, WEATHER_ICON[wk] or "☀️"
		if b == "neige" and (wk == "pluie" or wk == "orage") then
			wname, wicon = "Neige", "❄️"
		elseif night and wk == "clair" then
			wname, wicon = "Nuit claire", "🌙"
		end
		hud:setClock(workspace:GetAttribute("Day") or 1, h, m, wicon, wname)
		local pos = rootPos()
		if pos then
			hud:setPlace(placeHere(pos, b))
			refreshMap(pos)
		end
		hud:setGold(player:GetAttribute("Gold") or 0)
		local honor = player:GetAttribute("Honor") or 0
		hud.badge.Text = honor >= 0 and "😇" or "😈"
		hud:setStars(player:GetAttribute("Stars") or 0, Config.MAX_STARS, player:GetAttribute("Bounty"))
		local st, mx = player:GetAttribute("Stamina") or 10, player:GetAttribute("MaxStamina") or Config.MAX_STAMINA
		local stColor = player:GetAttribute("Drowning") and C.red or (player:GetAttribute("Swimming") and Color3.fromRGB(60, 190, 220) or nil)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		hud:setBars(hum and hum.Health or 0, hum and hum.MaxHealth or 100, st, mx, stColor)
	end)

	-- ---------------------------------------------------------------- Sac + équipement
	local inv = { inv = {}, gear = {}, equipped = {}, stats = {} }

	local function itemInfo(id: string)
		local info = Config.ITEMS[id]
		if not info then return { name = id, icon = "❔" } end
		local icone = IconesPeintes.secours(id, info.icon)
		if icone == info.icon then return info end
		local affichage = table.clone(info)
		affichage.icon = icone
		return affichage
	end

	Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function(data)
		inv = data
		inv.inv = inv.inv or {}
		inv.gear = inv.gear or {}
		inv.equipped = inv.equipped or {}
		inv.stats = inv.stats or {}
	end)

	-- ---------------------------------------------------------------- Infobulle (façon WoW)
	local selectionGui = game:GetService("GuiService")
	local QUALITY = {
		Color3.fromRGB(235, 235, 235), -- commun
		Color3.fromRGB(30, 255, 0), -- peu commun (outils, équipement)
		Color3.fromRGB(0, 112, 221), -- rare
		Color3.fromRGB(163, 53, 238), -- épique
		Color3.fromRGB(255, 128, 0), -- légendaire
	}
	local function qualityOf(info): number
		if info.rarity then
			return info.rarity -- calculée par le catalogue (obtention réelle)
		end
		local p = info.price or 0
		if p >= 600 then
			return 5
		elseif p >= 220 then
			return 4
		elseif p >= 80 or info.valuable then
			return 3
		elseif info.tool or info.weapon then
			return 2
		end
		return 1
	end
	-- dans combien de recettes un objet sert (chaque objet a une utilité : on la montre)
	local usedIn = {}
	for _, r in Config.RECIPES do
		for id in r.needs or {} do
			usedIn[id] = (usedIn[id] or 0) + 1
			for _, it in Config.ITEM_GROUPS[id] or {} do
				usedIn[it] = (usedIn[it] or 0) + 1
			end
		end
	end
	local USE_TEXT = { cat_livre = "Lire : expérience en compétence", cat_bourse = "Ouvrir : de l'or à l'intérieur", cat_tresor = "Ouvrir : un trésor ?",
		cat_musique = "Jouer : soigne un peu les joueurs autour", cat_graines = "Ouvrir : graines variées", fertilize = "Engraisse la culture devant soi",
		fill = "Remplir à une source d'eau", pour = "Verser (étang, arroseur)",
		cat_nasse = "Poser dans l'eau devant soi : un poisson chaque matin (deux si appâtée), 3 au plus",
		cat_barque = "Mettre à l'eau devant soi" }

	local tip = new("Frame", {
		Name = "Infobulle", Size = UDim2.fromOffset(250, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(14, 12, 22),
		BackgroundTransparency = 0.04, Visible = false, ZIndex = 80, Parent = gui,
	}, { corner(4), stroke(Color3.fromRGB(140, 140, 160), 1.5), pad(8), new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local tipActions = nil
	local function tipLine(text: string, color: Color3?, size: number?, order: number)
		label({ Text = text, TextSize = size or 13, TextColor3 = color or C.text, Font = (size or 13) > 14 and BOLD or BODY, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = tip, ZIndex = 81 })
	end
	local function hideTip()
		tip.Visible = false
		tipActions = nil
	end
	local function placeTip(source)
		local m = source and (source.AbsolutePosition + source.AbsoluteSize / 2) or UserInputService:GetMouseLocation()
		local s = uiScale.Scale
		local vp = workspace.CurrentCamera.ViewportSize
		local x, y = m.X + 18, m.Y + 6
		if x + tip.AbsoluteSize.X > vp.X then
			x = m.X - tip.AbsoluteSize.X - 12
		end
		if y + tip.AbsoluteSize.Y > vp.Y then
			y = vp.Y - tip.AbsoluteSize.Y - 4
		end
		tip.Position = UDim2.fromOffset(x / s, y / s)
	end
	-- lines = { {texte, couleur?, taille?} } ; actions = { {texte, fonction} } (boutons, infobulle épinglée)
	local function showTip(lines, actions, source)
		local manette = source and UserInputService:GetLastInputType().Name:match("^Gamepad")
		local premiereAction
		clear(tip)
		for i, l in lines do
			tipLine(l[1], l[2], l[3], i)
		end
		tipActions = actions
		if actions and #actions > 0 then
			local row = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 100, Parent = tip, ZIndex = 81 },
				{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
			for _, a in actions do
				local b = button(a[1], a[3] or C.panel2, function()
					if manette and source.Parent then selectionGui.SelectedObject = source end
					hideTip()
					a[2]()
				end)
				b.Size = UDim2.fromOffset(110, 28)
				b.TextSize = 13
				b.ZIndex = 82
				b.Parent = row
				premiereAction = premiereAction or b
			end
		end
		tip.Visible = true
		placeTip(source)
		if manette and premiereAction then selectionGui.SelectedObject = premiereAction end
	end
	local function itemLines(id: string, n: number?)
		local info = itemInfo(id)
		local lines = { { info.icon .. " " .. info.name, QUALITY[qualityOf(info)], 16 } }
		local kind = info.tool and "Outil" or (info.seed and "Graines" or (info.food and "Nourriture" or (info.place and "Objet à poser"
			or (info.valuable and "Objet de valeur" or ((info.use or info.lock) and "Utilisable" or "Ressource")))))
		table.insert(lines, { kind, C.dim, 12 })
		-- état de l'outil (usure, cf. Joueurs.TOOL_LIFE : pierre 150, cuivre 350, fer 700 coups)
		if info.tool then
			local life = Config.TOOL_LIFE[Config.tierOf(id)]
			-- l'usure suivie est celle du MEILLEUR outil de la famille (celui qu'on utilise)
			local base = Config.baseOf and Config.baseOf(id) or id
			local best = nil
			for _, fid in (Config.TOOL_FAMILIES and Config.TOOL_FAMILIES[base]) or {} do
				if (inv.inv[fid] or 0) > 0 and (base == "sword" or Config.baseOf(fid) == base) then
					best = fid
					break
				end
			end
			local u = (best == nil or best == id) and (player:GetAttribute("Usure_" .. base) or 0) or 0
			if u > 0.001 then
				local left = math.max(0, math.floor(life * (1 - u)))
				table.insert(lines, { string.format("Usure : %d %% — encore ~%d coups (réparable à l'établi)", math.floor(u * 100 + 0.5), left), u > 0.85 and Color3.fromRGB(255, 90, 70) or Color3.fromRGB(230, 200, 90) })
			else
				table.insert(lines, { "Neuf : " .. life .. " coups avant de casser", Color3.fromRGB(30, 255, 0) })
			end
		end
		if info.food then
			table.insert(lines, { "Rend " .. info.food .. " points de vie", Color3.fromRGB(30, 255, 0) })
			-- effet de repas / potion (Shared/Equilibre, Shared/Alchimie)
			if info.meal then
				local STAT = { force = "Force", defense = "Défense", vie = "Vie", vitesse = "Vitesse", chance = "Chance", charisme = "Charisme", discretion = "Discrétion" }
				table.insert(lines, { string.format("+%d %s pendant %d min", info.meal[2], STAT[info.meal[1]] or info.meal[1], math.floor(info.meal[3] / 60)), Color3.fromRGB(255, 210, 0) })
			end
		end
		if info.use and USE_TEXT[info.use] then
			table.insert(lines, { USE_TEXT[info.use], Color3.fromRGB(30, 255, 0) })
		end
		if id == "charter" then
			table.insert(lines, { "Sert à fonder une ville à cet endroit.", C.gold })
		end
		if info.lock then
			table.insert(lines, { "Se pose sur une porte ou un coffre (niveau " .. info.lock .. ")", Color3.fromRGB(30, 255, 0) })
		end
		if info.seed then
			local crop = Config.CROPS[info.seed]
			if crop then
				table.insert(lines, { "Pousse en " .. crop.days .. " jours arrosés", Color3.fromRGB(30, 255, 0) })
			end
		end
		if info.place then
			table.insert(lines, { "Se pose dans le monde", Color3.fromRGB(30, 255, 0) })
		end
		if id == "bait" then
			table.insert(lines, { "Pêche : un appât par lancer, ça mord plus vite et les poissons rares viennent plus souvent", Color3.fromRGB(30, 255, 0) })
		end
		if usedIn[id] then
			table.insert(lines, { "Sert dans " .. usedIn[id] .. " recette" .. (usedIn[id] > 1 and "s" or ""), Color3.fromRGB(255, 210, 0) })
		end
		if n then
			table.insert(lines, { "Quantité : " .. n, C.dim, 12 })
		end
		if info.price and info.price > 0 then
			table.insert(lines, { "Prix de vente : " .. info.price .. " 💰", C.text, 12 })
		end
		return lines
	end
	RunService.RenderStepped:Connect(function()
		if tip.Visible and not tipActions then
			placeTip()
		end
	end)

	-- case d'objet (sac, barre rapide) : icône, quantité, liseré de qualité
	-- icône 3D d'un outil (maquette de ReplicatedStorage.IconesOutils dans un ViewportFrame), façon
	-- image cible ; faux si l'objet n'a pas de maquette (on garde alors l'emoji)
	local TOOL_ICON = { hoe = "Houe", can = "Arrosoir", shovel = "Pelle", axe = "Hache", pickaxe = "Pioche", rod = "Canne à pêche", club = "Gourdin", sword = "Épée", spade = "Pelle" }
	local iconFolder = ReplicatedStorage:FindFirstChild("IconesOutils")
	local objFolder = ReplicatedStorage:FindFirstChild("IconesObjets") -- ressources (bois, pierre…)
	function toolIcon(id: string, cell: Instance, zi: number, dim: boolean): boolean
		local info = Config.ITEMS[id]
		if not info then
			return false
		end
		local painted = IconesPeintes.add(id, cell, UDim2.fromScale(0.9, 0.9), zi, dim)
		local tpl = nil
		if not painted then
			local temporaire = false
			if info.tool and iconFolder then
				local name = TOOL_ICON[id] or TOOL_ICON[info.base or ""] or (Config.baseOf and TOOL_ICON[Config.baseOf(id)])
				tpl = iconFolder:FindFirstChild(id) or (name and iconFolder:FindFirstChild(name))
			elseif objFolder then
				tpl = objFolder:FindFirstChild(id)
			end
			if not tpl and id == "wall_lantern" then
				tpl = Config.Catalogue.build(info.place)
				temporaire = tpl ~= nil
			end
			if not tpl then
				return false
			end
			local tier = Config.tierOf and Config.tierOf(id) or 0
			local tint = not tpl:GetAttribute("PaletteDediee") and Config.TOOL_TINTS[tier]
			local vf = Hud.objectViewport(tpl, dim, tint and function(d: BasePart)
				-- outils de cuivre / fer : la partie métallique prend la couleur du palier
				if d.Material == Enum.Material.Metal or d.Material == Enum.Material.Slate or d.Material == Enum.Material.Rock then
					d.Color = tint
				end
			end or nil)
			if temporaire then tpl:Destroy() end
			vf.ZIndex = zi
			vf.Parent = cell
		end
		-- barre d'usure de l'outil (façon Minecraft) : verte → rouge, cachée quand l'outil est neuf
		if info.tool then
			local base = Config.baseOf and Config.baseOf(id) or id
			local u = player:GetAttribute("Usure_" .. base) or 0
			if u > 0.001 then
				local k = math.clamp(1 - u, 0, 1)
				local back = new("Frame", { Size = UDim2.new(0.8, 0, 0, 4), Position = UDim2.new(0.1, 0, 1, -7), BackgroundColor3 = Color3.fromRGB(20, 18, 16), BorderSizePixel = 0, ZIndex = zi + 2, Parent = cell })
				new("Frame", { Size = UDim2.fromScale(k, 1), BackgroundColor3 = Color3.fromRGB(220, 60, 50):Lerp(Color3.fromRGB(90, 210, 80), k), BorderSizePixel = 0, ZIndex = zi + 3, Parent = back })
			end
		end
		return true
	end

	local function slotCell(parent: Instance, size: number, id: string?, n: number?, z: number?, differer: boolean?)
		local info = id and id ~= "" and itemInfo(id) or nil
		local cell = new("TextButton", {
			Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(30, 26, 22), Size = UDim2.fromOffset(size, size), Parent = parent, ZIndex = z or 6,
		}, { corner(4) })
		local st = stroke(info and QUALITY[qualityOf(info)] or Color3.fromRGB(70, 60, 50), info and 1.5 or 1)
		st.Parent = cell
		if info then
			if differer or not toolIcon(id :: string, cell, (z or 6) + 1, n == 0) then
				label({ Name = "IconeSecours", Text = info.icon or "❔", TextSize = math.floor(size * 0.56), TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1),
					TextTransparency = (n == 0) and 0.6 or 0, Parent = cell, ZIndex = (z or 6) + 1 })
			end
			if n and n > 1 then
				label({ Text = tostring(n), Font = BOLD, TextSize = math.max(11, math.floor(size * 0.28)), TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Bottom, TextStrokeTransparency = 0.2, Size = UDim2.new(1, -3, 1, -1), Parent = cell, ZIndex = (z or 6) + 2 })
			end
		end
		return cell
	end

	-- ---------------------------------------------------------------- Barre d'action rapide (façon Minecraft)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	local HOT = 9
	local buildHook = {} -- .fn(blocId ou nil) : branché par la construction plus bas
	local hotSlots = {}
	local hotSaved = false
	local selected = 0
	local famOf = function(id: string): string
		for fam, list in Config.TOOL_FAMILIES do
			if table.find(list, id) then
				return fam
			end
		end
		return Config.baseOf(id)
	end
	local function ownedCount(id: string): number
		if id == "" then
			return 0
		end
		local info = itemInfo(id)
		if info.tool then
			local f = famOf(id)
			local n = 0
			for it, c in inv.inv do
				if c > 0 and Config.ITEMS[it] and Config.ITEMS[it].tool and famOf(it) == f then
					n += c
				end
			end
			return n
		end
		return inv.inv[id] or 0
	end
	-- meilleur objet d'une famille d'outils (pour l'icône de la case)
	local function shownId(id: string): string
		local info = itemInfo(id)
		if info.tool then
			local fam = Config.TOOL_FAMILIES[famOf(id)]
			for _, it in fam or {} do
				if (inv.inv[it] or 0) > 0 then
					return it
				end
			end
		end
		return id
	end
	local function findTool(id: string): Tool?
		local f = famOf(id)
		for _, c in { player:FindFirstChildOfClass("Backpack"), player.Character } do
			if c then
				for _, t in c:GetChildren() do
					local tid = t:IsA("Tool") and t:GetAttribute("ItemId")
					if tid and (tid == id or famOf(tid) == f) then
						return t
					end
				end
			end
		end
		return nil
	end
	local function defaultHotbar()
		local out = {}
		for _, base in { "hoe", "can", "axe", "pickaxe", "rod", "harpoon", "sword", "shovel", "spade" } do
			if #out < HOT and ownedCount(base) > 0 then
				table.insert(out, base)
			end
		end
		for _, crop in Config.CROP_ORDER do
			if #out < HOT and (inv.inv["seed_" .. crop] or 0) > 0 then
				table.insert(out, "seed_" .. crop)
			end
		end
		for i = #out + 1, HOT do
			out[i] = ""
		end
		return out
	end

	local hotbar = new("Frame", {
		Name = "BarreRapide", Size = UDim2.fromOffset(HOT * 72 + 8, 80), Position = UDim2.new(0.5, 0, 1, MOBILE and -96 or -18), AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1, Parent = gui, ZIndex = 4,
	}, { pad(6), new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
	hotScale = new("UIScale", { Parent = hotbar })
	rescale()
	local hotCells = {}
	local renderHotbar

	local function saveHotbar()
		hotSaved = true
		send("hotbar_set", { slots = hotSlots })
	end
	local openCharte
	panels.CharteVille, openCharte = require(script.Parent:WaitForChild("CharteVille")).mount(gui, uiScale, send)
	local function useItem(id: string)
		local info = itemInfo(id)
		if id == "charter" then
			hideTip()
			openCharte()
		elseif info.food or info.use or info.lock then
			send("eat", { item = id })
		elseif info.place then
			if info.claim then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					placementRefusal.remember(ApercuPose.caseDevant(root, Config.CELL))
				end
			end
			send("place", { item = id })
		end
	end
	local function selectSlot(i: number)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end
		local id = hotSlots[i] or ""
		local again = selected == i
		selected = i
		local tool = id ~= "" and findTool(id)
		if tool then
			if again and tool.Parent == char then
				hum:UnequipTools()
				selected = 0
			else
				hum:EquipTool(tool)
			end
		else
			hum:UnequipTools()
			local info = id ~= "" and itemInfo(id) or nil
			if info and info.block then
				-- pièce de construction : en main = fantôme ; 2e appui = on la range
				if again then
					selected = 0
				end
			elseif again and id ~= "" and ownedCount(id) > 0 then
				-- objet sans outil (nourriture, objet à poser…) : 2e appui = l'utiliser
				useItem(id)
			end
		end
		local held = selected > 0 and hotSlots[selected] or ""
		if buildHook.fn then
			buildHook.fn(held ~= "" and itemInfo(held).block or nil)
		end
		renderHotbar()
	end

	-- glisser-déposer (sac -> barre, barre -> barre, barre -> dehors = vider)
	local drag = nil -- { id, from = "bag"|index, start = Vector2, ghost }
	local function slotUnderMouse(): number?
		local m = UserInputService:GetMouseLocation()
		for i, c in hotCells do
			local p, s = c.AbsolutePosition, c.AbsoluteSize
			if m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y then
				return i
			end
		end
		return nil
	end
	local function startDrag(id: string, from)
		drag = { id = id, from = from, start = UserInputService:GetMouseLocation(), ghost = nil }
	end
	UserInputService.InputChanged:Connect(function(input)
		if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
			local m = UserInputService:GetMouseLocation()
			if not drag.ghost and (m - drag.start).Magnitude > 6 then
				hideTip()
				drag.ghost = label({ Text = itemInfo(drag.id).icon, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(44, 44), ZIndex = 90, Parent = gui })
			end
			if drag.ghost then
				local s = uiScale.Scale
				drag.ghost.Position = UDim2.fromOffset(m.X / s - 22, m.Y / s - 22)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if not drag or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local d = drag
		drag = nil
		if not d.ghost then
			return -- simple clic : géré par la case
		end
		d.ghost:Destroy()
		local target = slotUnderMouse()
		if target then
			if type(d.from) == "number" then
				hotSlots[d.from], hotSlots[target] = hotSlots[target], hotSlots[d.from]
			else
				for i = 1, HOT do
					if hotSlots[i] == d.id then
						hotSlots[i] = ""
					end
				end
				hotSlots[target] = d.id
			end
			saveHotbar()
		elseif type(d.from) == "number" then
			hotSlots[d.from] = "" -- sortie de la barre : la case se vide
			saveHotbar()
		end
		renderHotbar()
	end)

	renderHotbar = function()
		for _, child in hotbar:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		hotCells = {}
		for i = 1, HOT do
			local id = hotSlots[i] or ""
			local n = id ~= "" and ownedCount(id) or nil
			local shown = id ~= "" and shownId(id) or nil
			local tool = id ~= "" and itemInfo(id).tool
			local cell = slotCell(hotbar, 69, shown, (not tool) and n or (n == 0 and 0 or nil), 5)
			cell.Name = "Barre" .. i
			cell.LayoutOrder = i
			cell.BackgroundColor3 = i == selected and Color3.fromRGB(46, 57, 72) or Color3.fromRGB(50, 40, 32)
			cell.BackgroundTransparency = 0.08
			cell:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 8)
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(137, 119, 103)), Parent = cell })
			label({ Text = tostring(i), Font = BOLD, TextSize = 14, TextColor3 = C.text, TextStrokeTransparency = 0.3, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(5, 3), Parent = cell, ZIndex = 8 })
			local s = cell:FindFirstChildOfClass("UIStroke")
			if i == selected then
				s.Color = C.gold
				s.Thickness = 3.5
				new("Frame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1, Parent = cell }, { corner(5), stroke(Color3.fromRGB(168, 109, 32), 1.5) })
			else
				if not shown then
					s.Color = C.line
				end
				s.Thickness = math.max(s.Thickness, 2)
			end
			cell.MouseButton1Down:Connect(function()
				if id ~= "" then
					startDrag(id, i)
				end
			end)
			cell.Activated:Connect(function()
				selectSlot(i)
			end)
			cell.MouseEnter:Connect(function()
				if id ~= "" and not drag then
					showTip(itemLines(shown, n))
				end
			end)
			cell.MouseLeave:Connect(function()
				if not tipActions then
					hideTip()
				end
			end)
			hotCells[i] = cell
		end
	end

	-- ---------------------------------------------------------------- Sac (façon World of Warcraft)
	local CATS = {
		{ id = "tout", name = "Tout", icon = "🎒" },
		{ id = "ressources", name = "Ressources", icon = "🌲" },
		{ id = "nourriture", name = "Nourriture", icon = "🍞" },
		{ id = "outils", name = "Outils", icon = "⚒️" },
		{ id = "graines", name = "Graines", icon = "🌱" },
		{ id = "poser", name = "À poser", icon = "🏠" },
		{ id = "construction", name = "Construction", icon = "🧱" },
		{ id = "valeur", name = "Valeur", icon = "💎" },
		{ id = "divers", name = "Utilisables", icon = "📜" },
	}
	local CAT_ORDER = {}
	for i, c in CATS do
		CAT_ORDER[c.id] = i
	end
	local function catOf(info): string
		if info.block then
			return "construction"
		elseif info.tool or info.weapon then
			return "outils"
		elseif info.seed then
			return "graines"
		elseif info.food then
			return "nourriture"
		elseif info.place then
			return "poser"
		elseif info.valuable then
			return "valeur"
		elseif info.use or info.lock then
			return "divers"
		end
		return "ressources"
	end
	local bagCat = "tout"
	local COLS = 10
	local wbag = new("Frame", {
		Name = "SacWoW", Size = UDim2.fromOffset(COLS * 46 + 28, 470), Position = UDim2.new(1, -24, 1, -110), AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Color3.fromRGB(24, 19, 15), BackgroundTransparency = 0.03, Visible = false, Parent = gui, ZIndex = 5,
	}, { corner(6), stroke(Color3.fromRGB(176, 140, 72), 2.5) })
	panels.SacWoW = wbag
	Composants.titre({ Text = "Sac", Font = TITLE, TextSize = 20, TextColor3 = C.gold, Size = UDim2.new(1, -60, 0, 30), Position = UDim2.fromOffset(12, 6), Parent = wbag, ZIndex = 6 })
	local function closeWbag()
		wbag.Visible = false
		hideTip()
	end
	local wclose = button("X", C.red, closeWbag)
	wclose.Size = UDim2.fromOffset(28, 28)
	wclose.Position = UDim2.new(1, -36, 0, 7)
	wclose.ZIndex = 6
	wclose.Parent = wbag
	WindowNav.watch(wbag, wclose, closeWbag)
	local wtabs = new("ScrollingFrame", { Size = UDim2.new(1, -20, 0, 33), Position = UDim2.fromOffset(10, 40), BackgroundTransparency = 1, Parent = wbag, ZIndex = 6,
		BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X },
		{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3) }) })
	local wgrid = new("ScrollingFrame", {
		Size = UDim2.new(1, -20, 1, -118), Position = UDim2.fromOffset(10, 76), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 5, ScrollBarImageColor3 = C.line, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = wbag, ZIndex = 6,
	}, { pad(3), new("UIGridLayout", { CellSize = UDim2.fromOffset(42, 42), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local wfoot = label({ Text = "", Font = BOLD, TextSize = 15, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(1, -24, 0, 24), Position = UDim2.new(0, 12, 1, -34), Parent = wbag, ZIndex = 6 })
	local whelp = label({ Text = "Clic droit : utiliser · glisser vers la barre rapide", TextSize = 11, TextColor3 = C.dim, Size = UDim2.new(0.62, 0, 0, 24), Position = UDim2.new(0, 12, 1, -34), Parent = wbag, ZIndex = 6 })
	local _ = whelp
	-- recherche + tri (une seule locale : le script frôle la limite de 200 locales)
	local bagUi = { search = "", sort = 1, SORTS = { "📂 Catégorie", "🔤 Nom", "🔢 Quantité", "💰 Valeur" } }
	bagUi.apercus = {}
	function bagUi.mettreAJourApercus()
		if bagUi.rafraichissement then return end
		bagUi.rafraichissement = true
		task.defer(function()
			bagUi.rafraichissement = false
			local haut = wgrid.AbsolutePosition.Y
			local bas = haut + wgrid.AbsoluteWindowSize.Y
			local ouvert = wbag.Visible and bas > haut
			for _, entree in bagUi.apercus do
				local case = entree.cell
				local y = case.AbsolutePosition.Y
				local visible = ouvert and y < bas and y + case.AbsoluteSize.Y > haut
				if visible and not entree.icone and not entree.absente then
					toolIcon(entree.id, case, 8, false)
					entree.icone = case:FindFirstChild("IconePeinte") or case:FindFirstChildOfClass("ViewportFrame")
					entree.absente = entree.icone == nil
					case.IconeSecours.Visible = entree.absente
				elseif not visible and entree.icone then
					entree.icone:Destroy()
					entree.icone = nil
					case.IconeSecours.Visible = true
				end
			end
		end)
	end
	wgrid:GetPropertyChangedSignal("CanvasPosition"):Connect(bagUi.mettreAJourApercus)
	wgrid:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(bagUi.mettreAJourApercus)
	wgrid:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(bagUi.mettreAJourApercus)
	wbag:GetPropertyChangedSignal("Visible"):Connect(bagUi.mettreAJourApercus)
	bagUi.box = new("TextBox", {
		Text = "", PlaceholderText = "🔍 Chercher…", ClearTextOnFocus = false, Font = BOLD, TextSize = 13, TextColor3 = C.text,
		PlaceholderColor3 = C.dim, BackgroundColor3 = Color3.fromRGB(40, 33, 26), Size = UDim2.fromOffset(150, 26),
		Position = UDim2.new(1, -312, 0, 8), Parent = wbag, ZIndex = 7,
	}, { corner(4), stroke(Color3.fromRGB(80, 64, 44), 1) })
	bagUi.sortBtn = button(bagUi.SORTS[1], C.panel2, function()
		bagUi.sort = bagUi.sort % #bagUi.SORTS + 1
		bagUi.sortBtn.Text = bagUi.SORTS[bagUi.sort]
		bagUi.render()
	end)
	bagUi.sortBtn.Size = UDim2.fromOffset(110, 26)
	bagUi.sortBtn.Position = UDim2.new(1, -156, 0, 8)
	MiseEnPage.bind(wbag, uiScale, function(narrow)
		bagUi.box.Position = narrow and UDim2.fromOffset(10, 40) or UDim2.new(1, -312, 0, 8)
		bagUi.sortBtn.Position = narrow and UDim2.new(1, -120, 0, 40) or UDim2.new(1, -156, 0, 8)
		bagUi.box.Size = narrow and UDim2.new(1, -141, 0, 34) or UDim2.fromOffset(150, 26)
		bagUi.sortBtn.Size = UDim2.fromOffset(110, narrow and 34 or 26)
		wtabs.Position = UDim2.fromOffset(10, narrow and 79 or 40)
		wgrid.Position = UDim2.fromOffset(10, narrow and 116 or 76)
		wgrid.Size = UDim2.new(1, -20, 1, narrow and -150 or -118)
		whelp.Visible = not narrow
	end)
	bagUi.sortBtn.TextSize = 12
	bagUi.sortBtn.ZIndex = 7
	bagUi.sortBtn.Parent = wbag
	bagUi.box:GetPropertyChangedSignal("Text"):Connect(function()
		bagUi.search = string.lower(bagUi.box.Text)
		if bagUi.render then
			bagUi.render()
		end
	end)

	local function addToHotbar(id: string)
		for i = 1, HOT do
			if hotSlots[i] == id then
				return
			end
		end
		local slot = nil
		for i = 1, HOT do
			if hotSlots[i] == "" then
				slot = i
				break
			end
		end
		slot = slot or math.max(1, selected)
		hotSlots[slot] = id
		saveHotbar()
		renderHotbar()
	end

	local function renderWBag()
		clear(wtabs)
		for _, c in CATS do
			local b = button(c.icon, bagCat == c.id and C.gold or C.panel2, function()
				bagCat = c.id
				renderWBag()
			end)
			b.Size = UDim2.fromOffset(52, 28)
			b.TextSize = 16
			b.ZIndex = 7
			b.Parent = wtabs
			b.MouseEnter:Connect(function()
				showTip({ { c.name, C.text, 14 } })
			end)
			b.MouseLeave:Connect(function()
				if not tipActions then
					hideTip()
				end
			end)
		end
		clear(wgrid)
		table.clear(bagUi.apercus)
		local ids = {}
		for id, n in inv.inv do
			local info = Config.ITEMS[id]
			if id ~= "gold" and n > 0 and info and (bagCat == "tout" or catOf(info) == bagCat)
				and (bagUi.search == "" or string.find(string.lower(info.name), bagUi.search, 1, true)) then
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(a, b)
			local ia, ib = itemInfo(a), itemInfo(b)
			if bagUi.sort == 3 and inv.inv[a] ~= inv.inv[b] then
				return inv.inv[a] > inv.inv[b]
			elseif bagUi.sort == 4 and (ia.price or 0) * inv.inv[a] ~= (ib.price or 0) * inv.inv[b] then
				return (ia.price or 0) * inv.inv[a] > (ib.price or 0) * inv.inv[b]
			elseif bagUi.sort == 1 then
				local ca, cb = CAT_ORDER[catOf(ia)], CAT_ORDER[catOf(ib)]
				if ca ~= cb then
					return ca < cb
				end
			end
			return ia.name < ib.name
		end)
		local total = math.max(#ids + (COLS - #ids % COLS) % COLS, COLS * 8)
		for i = 1, total do
			local id = ids[i]
			local n = id and inv.inv[id] or nil
			local cell = slotCell(wgrid, 42, id, n, 7, true)
			cell.Name = string.format("Case%03d", i)
			cell.LayoutOrder = i
			if id then
				table.insert(bagUi.apercus, { cell = cell, id = id })
				local info = itemInfo(id)
				cell.MouseButton1Down:Connect(function()
					startDrag(id, "bag")
				end)
				cell.MouseButton2Click:Connect(function()
					useItem(id)
				end)
				cell.MouseEnter:Connect(function()
					if not drag and not tipActions then
						showTip(itemLines(id, n))
					end
				end)
				cell.MouseLeave:Connect(function()
					if not tipActions then
						hideTip()
					end
				end)
				cell.Activated:Connect(function()
					-- clic simple (ou toucher sur mobile) : infobulle épinglée avec les actions
					local actions = {}
					local verb = info.food and "Manger" or ((id == "charter" or info.use or info.lock) and "Utiliser" or (info.place and "Poser" or nil))
					if verb then
						table.insert(actions, { verb, function()
							useItem(id)
						end, C.green })
					end
					table.insert(actions, { "→ Barre rapide", function()
						addToHotbar(id)
					end })
					-- outil usé : réparation à l'établi (moitié des matériaux)
					if info.tool and (player:GetAttribute("Usure_" .. (Config.baseOf and Config.baseOf(id) or id)) or 0) > 0 then
						table.insert(actions, { "🔧 Réparer", function()
							send("repair", { id = id })
						end })
					end
					showTip(itemLines(id, n), actions, id == "charter" and cell or nil)
				end)
			end
		end
		local nTypes = 0
		for id, n in inv.inv do
			if id ~= "gold" and n > 0 then
				nTypes += 1
			end
		end
		wfoot.Text = nTypes .. " objets   ·   💰 " .. (inv.inv.gold or 0)
		bagUi.mettreAJourApercus()
	end
	bagUi.render = renderWBag

	local function toggleBag()
		local v = not wbag.Visible
		closeAll()
		hideTip()
		wbag.Visible = v
		if v then
			renderWBag()
		end
	end

	Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function()
		task.defer(function()
			if type(inv.hotbar) == "table" and #inv.hotbar > 0 then
				hotSlots = table.clone(inv.hotbar)
				for i = 1, HOT do
					hotSlots[i] = hotSlots[i] or ""
				end
			elseif not hotSaved then
				hotSlots = defaultHotbar()
			end
			renderHotbar()
			if wbag.Visible then
				renderWBag()
			end
		end)
	end)
	-- le perso réapparaît : plus rien en main
	player.CharacterAdded:Connect(function()
		selected = 0
		task.defer(renderHotbar)
	end)
	hotSlots = defaultHotbar()
	renderHotbar()
	-- usure d'un outil qui change : on redessine la barre (au plus 2 fois / s)
	local wearDirty = false
	player.AttributeChanged:Connect(function(name)
		if string.sub(name, 1, 6) == "Usure_" and not wearDirty then
			wearDirty = true
			task.delay(0.5, function()
				wearDirty = false
				renderHotbar()
			end)
		end
	end)

	-- ---------------------------------------------------------------- Fiche personnage (façon WoW) [P]
	local toggleChar, openLook, closeLook
	do
	-- Gauche : l'équipement porté autour du personnage + l'équipement dans le sac.
	-- Droite : onglets Caractéristiques / Compétences / Collections / Titres.
	local SLOT_ICON = Gear.SLOT_ICONS
	local STAT_ICON = { force = "💪", defense = "🛡️", vie = "❤️", vitesse = "👟", chance = "🍀", charisme = "😊", discretion = "👤" }
	local STAT_HELP = { force = "Dégâts", defense = "Moins de dégâts reçus", vie = "+10 vie max par point", vitesse = "Course, endurance",
		chance = "Butin, pêche, trouvailles", charisme = "Prix, avis des PNJ", discretion = "Moins vu des témoins" }
	STAT_ICON.discretion = "🌑"
	local charTab = "stats"
	local lookInfo = nil -- écran d'apparence ouvert par le serveur (création, barbier, tailleur)
	local FicheApparence = require(script.Parent:WaitForChild("FicheApparence"))
	local bag = new("Frame", {
		Name = "Perso", Size = UDim2.fromOffset(760, 440), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(24, 19, 15), BackgroundTransparency = 0.03, Visible = false, Parent = gui, ZIndex = 5,
	}, { corner(6), stroke(Color3.fromRGB(176, 140, 72), 2.5) })
	panels.Perso = bag
	local charTitle = Composants.titre({ Text = "", Font = TITLE, TextSize = 20, TextColor3 = C.gold, Size = UDim2.new(1, -60, 0, 30), Position = UDim2.fromOffset(14, 6), Parent = bag, ZIndex = 6 })
	local function closeBag()
		bag.Visible = false
		hideTip()
	end
	local pclose = button("X", C.red, closeBag)
	pclose.Size = UDim2.fromOffset(28, 28)
	pclose.Position = UDim2.new(1, -36, 0, 8)
	pclose.ZIndex = 6
	pclose.Parent = bag
	WindowNav.watch(bag, pclose, closeBag)
	local editor = FicheApparence.mount(bag, pclose, C, uiScale, send)
	local left = new("Frame", { Size = UDim2.new(0, 300, 1, -54), Position = UDim2.fromOffset(12, 42), BackgroundColor3 = Color3.fromRGB(32, 26, 20), Parent = bag, ZIndex = 6 },
		{ corner(6), stroke(Color3.fromRGB(80, 64, 44), 1) })
	local right = new("Frame", { Size = UDim2.new(1, -336, 1, -54), Position = UDim2.fromOffset(322, 42), BackgroundColor3 = Color3.fromRGB(32, 26, 20), Parent = bag, ZIndex = 6 },
		{ corner(6), stroke(Color3.fromRGB(80, 64, 44), 1) })
	MiseEnPage.bind(bag, uiScale, MiseEnPage.columns(bag, { {left, 386}, {right, 386} }, 42))
	local tabsRow = new("Frame", { Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, Parent = right, ZIndex = 7 },
		{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }) })
	local content = new("ScrollingFrame", {
		Size = UDim2.new(1, -16, 1, -52), Position = UDim2.fromOffset(8, 46), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.line, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = right, ZIndex = 7,
	}, { new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local portraitSlot
	updateFichePortrait = function(character)
		editor:setCharacter(bag.Visible and character or nil)
		if not bag.Visible or editor.panel.Visible or not portraitSlot then return end
		clear(portraitSlot)
		local portrait = character and Hud.avatarViewport(character)
		if portrait then
			portrait.Size, portrait.Position = UDim2.fromScale(1, 1), UDim2.new()
			portrait.ZIndex, portrait.Parent = 7, portraitSlot
		else
			label({ Text = "🧍", TextSize = 110, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 0.55,
				Size = UDim2.fromScale(1, 1), Parent = portraitSlot, ZIndex = 7 })
		end
	end
	bag:GetPropertyChangedSignal("Visible"):Connect(function()
		if not bag.Visible then
			editor:setCharacter(nil)
			if portraitSlot then clear(portraitSlot) end
		end
	end)

	local function gearLines(it)
		local r = Gear.RARITIES[it.rarity] or Gear.RARITIES[1]
		local lines = { { it.name, r.color, 16 }, { (Gear.SLOTS[it.slot] or it.slot) .. " · " .. r.name, C.dim, 12 } }
		if it.slot == "offhand" and string.find(string.lower(it.name or ""), "torche", 1, true) then
			table.insert(lines, { "Tenue en main gauche, elle éclaire les grottes.", C.gold })
		end
		if it.power and it.power > 0 then
			table.insert(lines, { "⚔️ " .. it.power, C.text, 15 })
		end
		for _, st in Gear.STAT_ORDER do
			local v = it.stats and it.stats[st]
			if v and v ~= 0 then
				table.insert(lines, { (STAT_ICON[st] or "") .. " +" .. v .. " " .. Gear.STATS[st], Color3.fromRGB(30, 255, 0) })
			end
		end
		local worn = inv.equipped[it.slot]
		if worn and worn.id ~= it.id then
			table.insert(lines, { "Par rapport à " .. worn.name, C.dim, 12 })
			if it.slot == "weapon" then
				local delta = (it.power or 0) - (worn.power or 0)
				if delta ~= 0 then
					table.insert(lines, { string.format("%+d dégâts", delta), delta > 0 and C.green or C.red, 12 })
				end
			end
			for _, stat in Gear.STAT_ORDER do
				local delta = ((it.stats or {})[stat] or 0) - ((worn.stats or {})[stat] or 0)
				if delta ~= 0 then
					table.insert(lines, { string.format("%+d %s", delta, Gear.STATS[stat]), delta > 0 and C.green or C.red, 12 })
				end
			end
		end
		return lines
	end
	local function gearCell(parent, size: number, it, slot: string?)
		local r = it and (Gear.RARITIES[it.rarity] or Gear.RARITIES[1])
		local cell = new("TextButton", {
			Text = it and Hud.gearIcon(it) or (SLOT_ICON[slot] or ""), TextSize = math.floor(size * 0.5), Font = BOLD, TextTransparency = it and 0 or 0.75,
			AutoButtonColor = it ~= nil, BackgroundColor3 = Color3.fromRGB(30, 26, 22), Size = UDim2.fromOffset(size, size), Parent = parent, ZIndex = 8,
		}, { corner(4) })
		stroke(r and r.color or Color3.fromRGB(70, 60, 50), r and 2 or 1).Parent = cell
		if it then
			local preview = Hud.gearThumbnail(it)
			if preview then
				cell.Text = ""
				preview.ZIndex, preview.Parent = 9, cell
			end
			cell.MouseEnter:Connect(function()
				if not tipActions then
					showTip(gearLines(it))
				end
			end)
			cell.MouseLeave:Connect(function()
				if not tipActions then
					hideTip()
				end
			end)
		else
			cell.MouseEnter:Connect(function()
				showTip({ { Gear.SLOTS[slot] or slot, C.dim, 14 } })
			end)
			cell.MouseLeave:Connect(hideTip)
		end
		return cell
	end

	local function renderChar()
		if editor.panel.Visible then return end
		local mastery = 0
		for _, xp in inv.skills or {} do
			mastery += Config.skillLevel(xp)
		end
		charTitle.Text = "🧍 " .. player.DisplayName .. "   ·   🎓 " .. mastery
		-- gauche : poupée d'équipement
		clear(left)
		local doll = new("Frame", { Size = UDim2.fromOffset(276, 218), Position = UDim2.new(0.5, -138, 0, 8), BackgroundTransparency = 1, Parent = left, ZIndex = 7 })
		portraitSlot = new("Frame", { Name = "Apercu", BackgroundTransparency = 1, Size = UDim2.fromOffset(163, 174),
			Position = UDim2.fromOffset(56, 1), Parent = doll, ZIndex = 7 })
		updateFichePortrait(player.Character)
		local spots = {
			hat = Vector2.new(6, 0), armor = Vector2.new(6, 52), gloves = Vector2.new(6, 104), legs = Vector2.new(6, 156),
			cape = Vector2.new(230, 0), shoulders = Vector2.new(230, 52), trinket = Vector2.new(230, 104), boots = Vector2.new(230, 156),
			weapon = Vector2.new(91, 169), offhand = Vector2.new(151, 169),
		}
		for _, slot in ipairs(Gear.SLOT_ORDER) do
			local pos = spots[slot]
			local it = inv.equipped[slot]
			local c = gearCell(doll, 40, it, slot)
			c.Name = "Porte_" .. slot
			c.Position = UDim2.fromOffset(pos.X, pos.Y)
			label({ Text = Gear.SLOTS[slot], TextSize = 9, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Center,
				TextWrapped = false, Size = UDim2.fromOffset(54, 11), Position = UDim2.fromOffset(pos.X-7,pos.Y+40), Parent = doll, ZIndex = 8 })
			if it then
				c.Activated:Connect(function()
					showTip(gearLines(it), { { "Retirer", function()
						send("unequip", { slot = slot })
					end } })
				end)
			end
		end
		-- pas de niveau : la maîtrise = somme des rangs de compétence (donne les points de talent)
		label({ Text = "🎓 Maîtrise " .. mastery .. "   ·   ✨ talents : 1 point / 15", TextSize = 12, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(12, 233), Parent = left, ZIndex = 7 })
		-- équipement dans le sac
		label({ Text = "Équipement du sac", Font = BOLD, TextSize = 13, Size = UDim2.fromOffset(170, 20), Position = UDim2.fromOffset(12, 254), Parent = left, ZIndex = 7 })
		local gg = new("ScrollingFrame", {
			Size = UDim2.new(1, -24, 1, -278), Position = UDim2.fromOffset(12, 274), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
			ScrollBarImageColor3 = C.line, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = left, ZIndex = 7,
		}, { new("UIGridLayout", { CellSize = UDim2.fromOffset(44, 44), CellPadding = UDim2.fromOffset(4, 4) }) })
		for _, it in inv.gear do
			local c = gearCell(gg, 44, it)
			c.Activated:Connect(function()
				showTip(gearLines(it), { { "Équiper", function()
					send("equip", { id = it.id })
				end, C.green }, { "Démonter", function()
					if (it.rarity or 1) >= 3 then
						-- épique ou légendaire : on redemande (action irréversible)
						task.defer(function()
							showTip({ { "Démonter " .. it.name .. " ?", C.red, 15 }, { "C'est définitif.", C.dim, 12 } }, { { "Oui, démonter", function()
								send("drop_gear", { id = it.id })
							end, C.red }, { "Annuler", function() end } })
						end)
						return
					end
					send("drop_gear", { id = it.id })
				end, C.red } })
			end)
		end
		-- droite : onglets
		clear(tabsRow)
		for _, t in { { "stats", "💪" }, { "skills", "🎓" }, { "col", "🏺" }, { "titles", "🏅" }, { "look", "✂️" } } do
			local b = button(t[2], charTab == t[1] and C.gold or C.panel2, function()
				charTab = t[1]
				content.CanvasPosition = Vector2.zero
				renderChar()
			end)
			b.Size = UDim2.fromOffset(56, 32)
			b.TextSize = 18
			b.ZIndex = 8
			b.Parent = tabsRow
			b.MouseEnter:Connect(function()
				showTip({ { ({ stats = "Caractéristiques", skills = "Compétences", col = "Collections", titles = "Titres", look = "Apparence" })[t[1]], C.text, 14 } })
			end)
			b.MouseLeave:Connect(hideTip)
		end
		clear(content)
		local function row(order: number, h: number?)
			return new("Frame", { Size = UDim2.new(1, -6, 0, h or 34), BackgroundColor3 = Color3.fromRGB(40, 33, 26), LayoutOrder = order, Parent = content, ZIndex = 8 }, { corner(4) })
		end
		if charTab == "stats" then
			-- chaque caractéristique monte en pratiquant (pas de point à placer) : rang + progression
			local r0 = row(0, 26)
			label({ Text = "Elles montent en pratiquant : survole une ligne pour voir comment.", TextSize = 12, TextColor3 = C.dim,
				Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(8, 0), Parent = r0, ZIndex = 9 })
			for k, st in Gear.STAT_ORDER do
				local r = row(k, 38)
				local xp = (inv.statXp or {})[st] or 0
				local rank = Config.statLevel(xp)
				local cur, nxt = Config.statXpFor(rank), Config.statXpFor(rank + 1)
				local total = inv.stats[st] or 0
				label({ Text = STAT_ICON[st] or "", TextSize = 18, Size = UDim2.fromOffset(30, 38), Position = UDim2.fromOffset(6, 0), Parent = r, ZIndex = 9 })
				label({ Text = Gear.STATS[st], Font = BOLD, TextSize = 14, Size = UDim2.new(1, -150, 0, 20), Position = UDim2.fromOffset(38, 2), Parent = r, ZIndex = 9 })
				label({ Text = tostring(total), Font = BOLD, TextSize = 18, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Right,
					Size = UDim2.fromOffset(50, 38), Position = UDim2.new(1, -58, 0, 0), Parent = r, ZIndex = 9 })
				local back = new("Frame", { Size = UDim2.new(1, -110, 0, 7), Position = UDim2.fromOffset(38, 25), BackgroundColor3 = Color3.fromRGB(20, 16, 12), Parent = r, ZIndex = 9 }, { corner(4) })
				new("Frame", { Size = UDim2.fromScale(math.clamp((xp - cur) / math.max(1, nxt - cur), 0, 1), 1), BackgroundColor3 = Color3.fromRGB(240, 190, 60), Parent = back, ZIndex = 10 }, { corner(4) })
				local from = {}
				for sk, parts in Config.STAT_FROM_SKILL do
					if parts[st] then
						table.insert(from, Config.SKILLS[sk].icon .. " " .. Config.SKILLS[sk].name)
					end
				end
				if st == "vitesse" then
					table.insert(from, 1, "👟 courir et nager")
				end
				table.sort(from)
				r.MouseEnter:Connect(function()
					showTip({ { Gear.STATS[st] .. " — rang " .. rank, C.text, 15 }, { STAT_HELP[st] or "", Color3.fromRGB(255, 210, 0) },
						{ "Se travaille : " .. table.concat(from, ", "), C.dim, 12 },
						{ (total - rank) ~= 0 and ("Équipement : " .. (total - rank >= 0 and "+" or "") .. (total - rank)) or "", C.dim, 12 } })
				end)
				r.MouseLeave:Connect(hideTip)
			end
		elseif charTab == "skills" then
			for k, id in Config.SKILL_ORDER do
				local info = Config.SKILLS[id]
				local xp = (inv.skills or {})[id] or 0
				local lvlS = Config.skillLevel(xp)
				local cur, nxt = 4 * lvlS * lvlS, 4 * (lvlS + 1) * (lvlS + 1)
				local r = row(k, 36)
				label({ Text = info.icon, TextSize = 18, Size = UDim2.fromOffset(30, 36), Position = UDim2.fromOffset(6, 0), Parent = r, ZIndex = 9 })
				label({ Text = info.name .. (Config.skillRank and ("  · " .. Config.skillRank(lvlS)) or ""), Font = BOLD, TextSize = 13, Size = UDim2.new(0.7, 0, 0, 18), Position = UDim2.fromOffset(38, 1), Parent = r, ZIndex = 9 })
				label({ Text = tostring(lvlS), Font = BOLD, TextSize = 16, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(40, 36), Position = UDim2.new(1, -48, 0, 0), Parent = r, ZIndex = 9 })
				local back = new("Frame", { Size = UDim2.new(1, -100, 0, 8), Position = UDim2.fromOffset(38, 22), BackgroundColor3 = Color3.fromRGB(20, 16, 12), Parent = r, ZIndex = 9 }, { corner(4) })
				new("Frame", { Size = UDim2.fromScale(lvlS >= Config.SKILL_MAX and 1 or math.clamp((xp - cur) / math.max(1, nxt - cur), 0, 1), 1), BackgroundColor3 = Color3.fromRGB(30, 200, 0), Parent = back, ZIndex = 10 }, { corner(4) })
			end
		elseif charTab == "col" then
			local c = inv.col or {}
			for k, e in { { "🐟", "Poissons", c.fish, 7 }, { "🌾", "Cultures", c.crops, #Config.CROP_ORDER }, { "⛏️", "Minerais", c.ores, 5 }, { "👾", "Créatures", c.creatures },
				{ "🐾", "Apprivoisées", c.tames }, { "🌿", "Plantes sauvages", c.herbs, 12 }, { "🧭", "Mondes", c.worlds } } do
				local r = row(k)
				label({ Text = e[1], TextSize = 18, Size = UDim2.fromOffset(30, 34), Position = UDim2.fromOffset(6, 0), Parent = r, ZIndex = 9 })
				label({ Text = e[2], Font = BOLD, TextSize = 14, Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(38, 0), Parent = r, ZIndex = 9 })
				label({ Text = tostring(e[3] or 0) .. (e[4] and ("/" .. e[4]) or ""), Font = BOLD, TextSize = 16, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Right,
					Size = UDim2.fromOffset(70, 34), Position = UDim2.new(1, -78, 0, 0), Parent = r, ZIndex = 9 })
				if e[2] == "Créatures" or e[2] == "Apprivoisées" or e[2] == "Cultures" then
					-- ouvre le bestiaire, le livre de ses bêtes ou le carnet des cultures (Systemes/Livres)
					local action = ({ ["Créatures"] = "livre_bestiaire", ["Apprivoisées"] = "livre_animaux", Cultures = "livre_cultures" })[e[2]]
					local open = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = r, ZIndex = 10 })
					open.Activated:Connect(function()
						send(action)
					end)
					label({ Text = "📕", TextSize = 14, Size = UDim2.fromOffset(20, 34), Position = UDim2.new(1, -100, 0, 0), Parent = r, ZIndex = 9 })
				end
			end
		elseif charTab == "look" then
			local r = row(0, 54)
			label({ Text = "Le barbier change les cheveux, les sourcils, la barbe et la moustache. Le tailleur change la tenue.",
				TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.fromOffset(8, 0), Parent = r, ZIndex = 9 })
			for order, choice in FicheApparence.choixActuels(inv.look) do
				local line = row(order, 34)
				if choice.color then
					new("Frame", { BackgroundColor3 = choice.color, Size = UDim2.fromOffset(18, 18),
						Position = UDim2.fromOffset(7, 8), Parent = line, ZIndex = 9 }, { corner(4) })
				end
				label({ Text = choice.label .. " · " .. choice.name, TextSize = 13, Size = UDim2.new(1, -44, 1, 0),
					Position = UDim2.fromOffset(34, 0), Parent = line, ZIndex = 9 })
			end
		else
			for k, t in inv.titles or {} do
				local r = row(k)
				-- succès pas encore atteint : sa progression (ex. « 🔒 Loup de mer  57/200 »)
				local prog = (not t.owned and t.need) and string.format("  %d/%d", t.got or 0, t.need) or ""
				local b = new("TextButton", { Text = (t.owned and (t.on and "✅ " or "") or "🔒 ") .. t.name .. prog, Font = BOLD, TextSize = 13, TextColor3 = t.owned and C.text or C.dim,
					BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = r, ZIndex = 9 })
				if t.on then
					stroke(C.gold, 1.5).Parent = r
				end
				b.Activated:Connect(function()
					if t.owned then
						send("set_title", { id = t.id })
					end
				end)
			end
		end
	end
	openLook = function(data)
		closeAll()
		lookInfo = data
		charTab = "look"
		charTitle.Text = FicheApparence.titres[data.ctx]
		left.Visible, right.Visible = false, false
		editor:setCharacter(player.Character)
		editor:open(data, inv.look)
		bag.Visible = true
	end
	closeLook = function()
		if not lookInfo then return end
		editor:close()
		lookInfo = nil
		left.Visible, right.Visible = true, true
	end
	toggleChar = function()
		local v = not bag.Visible
		closeAll()
		hideTip()
		if lookInfo and lookInfo.ctx == "creation" and not (inv.look and inv.look.created) then
			if v then
				editor:setCharacter(player.Character)
				bag.Visible = true
			end
			return
		end
		closeLook()
		bag.Visible = v
		if v then
			renderChar()
		end
	end
	Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function()
		if bag.Visible then
			task.defer(renderChar)
		end
	end)
	end

	-- ---------------------------------------------------------------- Atelier : grille d'artisanat (façon Minecraft)
	local showCraft, toggleCraft
	do
	-- On compose son mélange (les quantités comptent, pas les positions). Si ça donne quelque chose,
	-- le résultat apparaît. Le carnet ne montre que les recettes déjà découvertes.
	local craftStations = {}
	local grid = {} -- [1..9] = { id, n }
	local craft = new("Frame", {
		Name = "Atelier", Size = UDim2.fromOffset(820, 440), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(24, 19, 15), BackgroundTransparency = 0.03, Visible = false, Parent = gui, ZIndex = 5,
	}, { corner(6), stroke(Color3.fromRGB(176, 140, 72), 2.5) })
	panels.Atelier = craft
	label({ Text = "🛠️", TextSize = 26, Size = UDim2.fromOffset(36, 34), Position = UDim2.fromOffset(12, 6), Parent = craft, ZIndex = 6 })
	local stationIcons = label({ Text = "", TextSize = 22, Size = UDim2.fromOffset(200, 34), Position = UDim2.fromOffset(52, 6), Parent = craft, ZIndex = 6 })
	local function closeCraft()
		craft.Visible = false
		hideTip()
	end
	local cclose = button("X", C.red, closeCraft)
	cclose.Size = UDim2.fromOffset(28, 28)
	cclose.Position = UDim2.new(1, -36, 0, 8)
	cclose.ZIndex = 6
	cclose.Parent = craft
	WindowNav.watch(craft, cclose, closeCraft)

	-- colonnes : sac (gauche), grille + résultat (milieu), carnet (droite)
	local function column(x: number, w: number, icon: string)
		local f = new("Frame", { Size = UDim2.new(0, w, 1, -58), Position = UDim2.fromOffset(x, 46), BackgroundColor3 = Color3.fromRGB(32, 26, 20), Parent = craft, ZIndex = 6 },
			{ corner(6), stroke(Color3.fromRGB(80, 64, 44), 1) })
		label({ Text = icon, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 4), Parent = f, ZIndex = 7 })
		return f
	end
	local colBag = column(12, 300, "Matériaux")
	local colGrid = column(322, 236, "")
	local colBook = column(568, 240, "Recettes")
	MiseEnPage.bind(craft, uiScale, MiseEnPage.columns(craft, { {colBag, 267}, {colGrid, 382}, {colBook, 325} }, 46))
	local bagScroll = new("ScrollingFrame", {
		Size = UDim2.new(1, -12, 1, -36), Position = UDim2.fromOffset(6, 30), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.line, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = colBag, ZIndex = 7,
	}, { pad(3), new("UIGridLayout", { CellSize = UDim2.fromOffset(44, 44), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local bookScroll = new("ScrollingFrame", {
		Size = UDim2.new(1, -12, 1, -68), Position = UDim2.fromOffset(6, 61), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.line, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = colBook, ZIndex = 7,
	}, { pad(3), new("UIGridLayout", { CellSize = UDim2.fromOffset(42, 42), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local bookCount = label({ Text = "", TextSize = 12, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(1, -10, 0, 20), Position = UDim2.fromOffset(0, 6), Parent = colBook, ZIndex = 7 })
	local search = new("TextBox", { Text = "", PlaceholderText = "Chercher une recette", ClearTextOnFocus = false,
		Font = BODY, TextSize = 13, TextColor3 = C.text, PlaceholderColor3 = C.dim, BackgroundColor3 = C.panel,
		Size = UDim2.new(1, -16, 0, 27), Position = UDim2.fromOffset(8, 30), Parent = colBook, ZIndex = 8 },
		{ corner(5), stroke(C.line, 1) })
	local emptyRecipes = label({ Text = "Aucune recette trouvée", Visible = false, TextColor3 = C.dim, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 66), Parent = colBook, ZIndex = 8 })
	local recipeCells = {}
	local function refreshRecipeIcons()
		local top = bookScroll.AbsolutePosition.Y
		local bottom = top + bookScroll.AbsoluteWindowSize.Y
		for _, entry in ipairs(recipeCells) do
			local cell = entry.cell
			local y = cell.AbsolutePosition.Y
			local visible = craft.Visible and bottom > top and y < bottom and y + cell.AbsoluteSize.Y > top
			if visible and not entry.preview then
				if entry.recipe.item then
					toolIcon(entry.recipe.item, cell, 9, not entry.available)
				elseif entry.recipe.gear then
					local vf = Hud.gearThumbnail(entry.recipe.gear, not entry.available)
					if vf then vf.ZIndex, vf.Parent = 9, cell end
				end
				entry.preview = cell:FindFirstChild("IconePeinte") or cell:FindFirstChildOfClass("ViewportFrame")
				if entry.preview then cell.Text = "" end
			elseif not visible and entry.preview then
				-- Retire aussi les éventuels éléments d’usure créés par l’aperçu.
				for _, child in cell:GetChildren() do
					if child:IsA("GuiObject") then child:Destroy() end
				end
				entry.preview = nil
				cell.Text = entry.icon
			end
		end
	end
	bookScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(refreshRecipeIcons)
	bookScroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(refreshRecipeIcons)
	craft:GetPropertyChangedSignal("Visible"):Connect(refreshRecipeIcons)
	local gridFrame = new("Frame", { Size = UDim2.fromOffset(3 * 60 + 8, 3 * 60 + 8), Position = UDim2.new(0.5, 0, 0, 14), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Parent = colGrid, ZIndex = 7 },
		{ new("UIGridLayout", { CellSize = UDim2.fromOffset(56, 56), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	label({ Text = "⬇", TextSize = 26, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 206), Parent = colGrid, ZIndex = 7 })
	local resultHolder = new("Frame", { Size = UDim2.new(1, -16, 0, 120), Position = UDim2.fromOffset(8, 236), BackgroundTransparency = 1, Parent = colGrid, ZIndex = 7 },
		{ new("UIGridLayout", { CellSize = UDim2.fromOffset(56, 56), CellPadding = UDim2.fromOffset(6, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
	local renderCraftGrid
	local clearBtn = button("🧹", C.panel2, function()
		grid = {}
		renderCraftGrid()
	end)
	clearBtn.Size = UDim2.fromOffset(40, 40)
	clearBtn.TextSize = 20
	clearBtn.Position = UDim2.new(1, -48, 0, 200)
	clearBtn.ZIndex = 8
	clearBtn.Parent = colGrid

	local function gridCounts()
		local counts = {}
		for i = 1, 9 do
			local s = grid[i]
			if s and s.n > 0 then
				counts[s.id] = (counts[s.id] or 0) + s.n
			end
		end
		return counts
	end
	local function inGrid(id: string): number
		return gridCounts()[id] or 0
	end
	local function addToGrid(id: string, n: number)
		local free = (inv.inv[id] or 0) - inGrid(id)
		n = math.min(n, free)
		if n <= 0 then
			return
		end
		for i = 1, 9 do
			if grid[i] and grid[i].id == id then
				grid[i].n += n
				renderCraftGrid()
				return
			end
		end
		for i = 1, 9 do
			if not grid[i] then
				grid[i] = { id = id, n = n }
				renderCraftGrid()
				return
			end
		end
	end
	local function knows(key: string): boolean
		return Config.STARTER_RECIPES[key] == true or (inv.known ~= nil and inv.known[key] == true)
	end
	local function recipeInfo(r)
		if r.gear then
			return { name = r.gear.name, icon = Hud.gearIcon(r.gear), gear = r.gear }
		end
		return itemInfo(r.item)
	end
	local fiche = { model = require(script.Parent:WaitForChild("FicheRecette")) }
	fiche.panel, fiche.body, fiche.title = makePanel("FicheRecette", "Recette", UDim2.fromOffset(465, 408))
	local function recipeLines(r, k: number?)
		local info = recipeInfo(r)
		local lines = { { info.icon .. " " .. info.name .. ((r.count or 1) * (k or 1) > 1 and (" ×" .. (r.count or 1) * (k or 1)) or ""),
			info.gear and (Gear.RARITIES[info.gear.rarity] or Gear.RARITIES[1]).color or QUALITY[qualityOf(info)], 16 } }
		if info.gear then
			for _, st in Gear.STAT_ORDER do
				if info.gear.stats[st] then
					table.insert(lines, { "+" .. info.gear.stats[st] .. " " .. Gear.STATS[st], Color3.fromRGB(30, 255, 0) })
				end
			end
		end
		local etat = fiche.model.etat(Config, r, inv, craftStations, k or 1)
		for _, item in etat.ingredients do
			table.insert(lines, { item.name .. " — " .. Composants.quantite(item.have, item.need) .. " en stock", item.have >= item.need and C.text or C.red, 14 })
		end
		if etat.station then
			table.insert(lines, { etat.station.name .. (etat.stationOK and " — à portée" or " — approche-toi de la station"), etat.stationOK and C.green or C.red, 14 })
		else
			table.insert(lines, { "Aucune station nécessaire", C.dim, 14 })
		end
		if etat.level then
			local skill = etat.skill and etat.skill.name or r.skill[1]
			table.insert(lines, { string.format("%s — %d / %d requis", skill, etat.current, etat.level), etat.skillOK and C.green or C.red, 14 })
		end
		if etat.missing then table.insert(lines, { Composants.avertissement("Il manque des ingrédients."), C.red, 14 }) end
		return lines
	end

	function fiche.render()
		local r, batches = fiche.recipe, fiche.batches
		if not r then return end
		clear(fiche.body)
		local lines = recipeLines(r, batches)
		local etat = fiche.model.etat(Config, r, inv, craftStations, batches)
		for index, line in lines do
			label({ Text = line[1], TextColor3 = line[2], TextSize = line[3] or 14, TextWrapped = true,
				Size = UDim2.new(1, -8, 0, 24), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = index, Parent = fiche.body, ZIndex = 7 })
		end
		local action = button(fiche.label, nil, function()
			if fiche.model.etat(Config, r, inv, craftStations, batches).ready then
				fiche.panel.Visible = false
				fiche.action()
			end
		end)
		Composants.etatBouton(action, fiche.label, etat.ready and "disponible" or "verrouille")
		action.Size = UDim2.new(1, -8, 0, 40)
		action.LayoutOrder, action.ZIndex, action.Parent = #lines + 1, 8, fiche.body
	end
	function fiche.open(r, batches, actionLabel, action)
		hideTip()
		fiche.recipe, fiche.batches, fiche.label, fiche.action = r, batches, actionLabel, action
		fiche.body.CanvasPosition = Vector2.zero
		fiche.panel.Visible = true
		fiche.render()
	end

	renderCraftGrid = function()
		clear(gridFrame)
		for i = 1, 9 do
			local s = grid[i]
			local cell = slotCell(gridFrame, 56, s and s.id, s and s.n, 8)
			cell.Name = "Grille" .. i
			cell.LayoutOrder = i
			if s then
				-- clic : -1 · clic droit : vider la case
				cell.Activated:Connect(function()
					s.n -= 1
					if s.n <= 0 then
						grid[i] = nil
					end
					renderCraftGrid()
				end)
				cell.MouseButton2Click:Connect(function()
					grid[i] = nil
					renderCraftGrid()
				end)
			end
		end
		clear(resultHolder)
		local matches = Config.matchGridAll(gridCounts())
		for mi, m in matches do
			if mi > 6 then
				break
			end
			local index, k = m[1], m[2]
			local r = Config.RECIPES[index]
			local info = recipeInfo(r)
			local stationOk = not r.station or craftStations[r.station]
			local out = new("TextButton", { Name = "Resultat" .. mi, Text = info.icon, TextSize = 30, Font = BOLD, AutoButtonColor = stationOk, BackgroundColor3 = Color3.fromRGB(36, 30, 22),
				LayoutOrder = mi, Parent = resultHolder, ZIndex = 8 }, { corner(6) })
			if r.item and toolIcon(r.item, out, 9, not stationOk) then
				out.Text = ""
			elseif r.gear then
				local preview = Hud.gearThumbnail(r.gear, not stationOk)
				if preview then
					out.Text = ""
					preview.ZIndex, preview.Parent = 9, out
				end
			end
			stroke(stationOk and C.gold or C.red, 2.5).Parent = out
			local total = (r.count or 1) * (r.gear and 1 or k)
			if total > 1 then
				label({ Text = tostring(total), Font = BOLD, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Bottom,
					TextStrokeTransparency = 0.2, Size = UDim2.new(1, -4, 1, -2), Parent = out, ZIndex = 12 })
			end
			if r.station and not stationOk then
				label({ Text = Config.STATIONS[r.station].icon, TextSize = 16, Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(-6, -8), Parent = out, ZIndex = 12 })
			end
			out.Activated:Connect(function()
				fiche.open(r, r.gear and 1 or k, "Fabriquer", function()
					local slots = {}
					for i = 1, 9 do
						slots[i] = grid[i] and { id = grid[i].id, n = grid[i].n } or false
					end
					send("craft_grid", { slots = slots, pick = index })
					grid = {}
					hideTip()
					task.defer(renderCraftGrid)
				end)
			end)
			out.MouseEnter:Connect(function()
				showTip(recipeLines(r, r.gear and 1 or k))
			end)
			out.MouseLeave:Connect(hideTip)
		end
		if #matches == 0 then
			local out = new("Frame", { BackgroundColor3 = Color3.fromRGB(30, 26, 22), Parent = resultHolder, ZIndex = 8 }, { corner(6) })
			stroke(Color3.fromRGB(70, 60, 50), 1).Parent = out
			if next(gridCounts()) then
				label({ Text = "❔", TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 0.5, Size = UDim2.fromScale(1, 1), Parent = out, ZIndex = 9 })
			end
		end
	end

	local function renderCraft()
		-- stations à portée (icônes : présente / absente)
		local st = {}
		for id, info in Config.STATIONS do
			table.insert(st, info.icon .. (craftStations[id] and "✅" or "❌"))
		end
		table.sort(st)
		stationIcons.Text = table.concat(st, "  ")
		-- sac : cliquer met 1 dans la grille (clic droit : 10)
		clear(bagScroll)
		local ids = {}
		for id, n in inv.inv do
			if id ~= "gold" and n > 0 and Config.ITEMS[id] then
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(a, b)
			return itemInfo(a).name < itemInfo(b).name
		end)
		for i, id in ids do
			local left = (inv.inv[id] or 0) - inGrid(id)
			local cell = slotCell(bagScroll, 44, id, left, 8)
			cell.Name = string.format("Sac%03d", i)
			cell.LayoutOrder = i
			cell.Activated:Connect(function()
				addToGrid(id, 1)
				renderCraft()
			end)
			cell.MouseButton2Click:Connect(function()
				addToGrid(id, 10)
				renderCraft()
			end)
			cell.MouseEnter:Connect(function()
				showTip(itemLines(id, left))
			end)
			cell.MouseLeave:Connect(hideTip)
		end
		-- carnet : seulement les recettes connues ; clic = remplir la grille
		table.clear(recipeCells)
		clear(bookScroll)
		local known, total, matches = 0, 0, 0
		local query = string.lower(search.Text):match("^%s*(.-)%s*$") or ""
		for i, r in Config.RECIPES do
			total += 1
			local key = Config.recipeKey(r)
			if knows(key) then
				known += 1
				local info = recipeInfo(r)
				if query ~= "" and not string.find(string.lower(info.name), query, 1, true) then
					continue
				end
				matches += 1
				local can = fiche.model.etat(Config, r, inv, craftStations, 1).ready
				local cell = new("TextButton", { Text = info.icon, TextSize = 24, Font = BOLD, AutoButtonColor = true, TextTransparency = can and 0 or 0.55,
					BackgroundColor3 = Color3.fromRGB(30, 26, 22), LayoutOrder = (can and 0 or 10000) + i, Parent = bookScroll, ZIndex = 8 }, { corner(4) })
				recipeCells[#recipeCells + 1] = { cell = cell, recipe = r, available = can, icon = info.icon }
				stroke(can and C.green or Color3.fromRGB(70, 60, 50), 1.5).Parent = cell
				cell.MouseEnter:Connect(function()
					showTip(recipeLines(r))
				end)
				cell.MouseLeave:Connect(hideTip)
				cell.Activated:Connect(function()
					fiche.open(r, 1, "Préparer la grille", function()
						local preparation = fiche.model.grille(Config, r, inv)
						if not preparation or #preparation > 9 then
							toast("Ce mélange ne tient pas dans la grille avec ton stock actuel.", "danger")
							return
						end
						grid = preparation
						renderCraft()
					end)
				end)
			end
		end
		bookCount.Text = known .. "/" .. total
		emptyRecipes.Visible = matches == 0
		renderCraftGrid()
		task.defer(refreshRecipeIcons)
	end
	local searchRevision = 0
	search:GetPropertyChangedSignal("Text"):Connect(function()
		searchRevision += 1
		local revision = searchRevision
		task.delay(0.18, function()
			if revision == searchRevision and craft.Visible then
				bookScroll.CanvasPosition = Vector2.zero
				renderCraft()
			end
		end)
	end)
	showCraft = function(stations)
		closeAll()
		hideTip()
		craftStations = stations or {}
		craft.Visible = true
		renderCraft()
	end
	toggleCraft = function()
		if craft.Visible then
			craft.Visible = false
			hideTip()
		else
			send("craftmenu") -- le serveur répond avec les stations à portée
		end
	end
	Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function()
		if craft.Visible then
			task.defer(renderCraft)
		end
		if fiche.panel.Visible then task.defer(fiche.render) end
	end)
	end

	do
	-- ---------------------------------------------------------------- Coffre de rangement
	local chest, chestBody, chestTitle = makePanel("Coffre", "📦 Coffre", UDim2.fromOffset(640, 480))
	local chestData = nil
	local function renderChest()
		if not chestData then
			return
		end
		clear(chestBody)
		chestTitle.Text = "📦 " .. (chestData.title or "Coffre")
		if not chestData.mine then
			label({ Text = "⚠ Ce n'est pas ton coffre : te servir, c'est voler.", TextColor3 = C.red, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 0, Parent = chestBody })
		end
		if chestData.bank then
			local row = new("Frame", { Size = UDim2.new(1, -8, 0, 40), BackgroundTransparency = 1, LayoutOrder = 1, Parent = chestBody })
			label({ Text = string.format("🏦 Places : %d / %d sortes d'objets · dépôt : 2 💰 · personne ne peut te voler ici", chestData.bank.used, chestData.bank.slots), TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, -170, 1, 0), Parent = row })
			if chestData.bank.upgrade then
				local b = button("Agrandir (" .. chestData.bank.upgrade .. " 💰)", C.gold, function()
					send("bank_upgrade")
				end)
				b.Size = UDim2.fromOffset(160, 34)
				b.Position = UDim2.new(1, -162, 0, 3)
				b.TextColor3 = Color3.fromRGB(40, 30, 20)
				b.Parent = row
			end
		end
		-- transferts en masse (pas pour le coffre de clan) : compléter les piles · tout prendre (le sien)
		if chestData.id ~= "clan" then
			local row = new("Frame", { Size = UDim2.new(1, -8, 0, 36), BackgroundTransparency = 1, LayoutOrder = 2, Parent = chestBody },
				{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
			local bs = button("📥 Compléter les piles", C.panel2, function()
				send("chest_bulk", { id = chestData.id, mode = "stack" })
			end)
			bs.Size = UDim2.fromOffset(190, 32)
			bs.Parent = row
			if chestData.mine then
				local bt = button("📤 Tout prendre", C.panel2, function()
					send("chest_bulk", { id = chestData.id, mode = "take" })
				end)
				bt.Size = UDim2.fromOffset(150, 32)
				bt.Parent = row
			end
		end
		local function list(title: string, items, put: boolean, order: number)
			label({ Text = title, Font = TITLE, TextSize = 18, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = order, Parent = chestBody })
			local grid = new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order + 1, Parent = chestBody },
				{ new("UIGridLayout", { CellSize = UDim2.fromOffset(46, 46), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.Name }) })
			local ids = {}
			for id, n in items do
				if n > 0 and id ~= "gold" then
					table.insert(ids, id)
				end
			end
			table.sort(ids, function(a, b)
				return itemInfo(a).name < itemInfo(b).name
			end)
			for k, id in ids do
				-- case façon sac : icône, nombre, liseré de rareté ; clic = tout le tas, clic droit = un seul
				local cell = slotCell(grid, 46, id, items[id], 7)
				cell.Name = string.format("%03d", k)
				cell.MouseButton2Click:Connect(function()
					send(put and "chest_put" or "chest_take", { id = chestData.id, item = id, n = 1 })
				end)
				cell.MouseEnter:Connect(function()
					local lines = itemLines(id, items[id])
					table.insert(lines, { put and "Clic : tout ranger · clic droit : un seul" or "Clic : tout prendre · clic droit : un seul", C.dim, 11 })
					showTip(lines)
				end)
				cell.MouseLeave:Connect(function()
					if not tipActions then
						hideTip()
					end
				end)
				cell.Activated:Connect(function()
					hideTip()
					send(put and "chest_put" or "chest_take", { id = chestData.id, item = id, n = items[id] })
				end)
			end
			if #ids == 0 then
				label({ Text = "Vide.", TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 20), Parent = grid })
			end
		end
		list("Dans le coffre (clic = prendre)", chestData.items or {}, false, 10)
		list("Ton sac (clic = ranger)", inv.inv, true, 20)
		-- banque : derniers mouvements (dépôts verts, retraits rouges)
		local blog = chestData.bank and chestData.bank.log
		if blog and #blog > 0 then
			label({ Text = "Derniers mouvements", Font = TITLE, TextSize = 16, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 40, Parent = chestBody })
			for k = #blog, 1, -1 do
				local e = blog[k]
				local info = itemInfo(e.i)
				label({ Text = "Jour " .. e.d .. "  " .. (e.s == "+" and "➕ déposé " or "➖ retiré ") .. e.n .. " " .. (info.icon or "") .. " " .. info.name,
					TextSize = 12, TextColor3 = e.s == "+" and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(240, 130, 110),
					Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 41 + (#blog - k), Parent = chestBody })
			end
		end
	end
	Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function()
		if chest.Visible then
			task.defer(renderChest)
		end
	end)

	-- ---------------------------------------------------------------- Boutique
	local shop, shopBody, shopTitle = makePanel("Boutique", "Boutique", UDim2.fromOffset(620, 480), function()
		send("closeshop")
	end)
	local shopTab = "buy"
	local shopData = nil
	local function renderShop()
		if not shopData then
			return
		end
		clear(shopBody)
		shopTitle.Text = "🏪 " .. (shopData.title or "Boutique")
		label({ Text = "« " .. (shopData.greeting or "") .. " »", TextColor3 = C.dim, TextSize = 14, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 0, Parent = shopBody })
		local tabs = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 1, Parent = shopBody })
		local tb = button("Acheter", shopTab == "buy" and C.blue or C.panel2, function()
			shopTab = "buy"
			renderShop()
		end)
		tb.Parent = tabs
		local ts = button("Vendre", shopTab == "sell" and C.blue or C.panel2, function()
			shopTab = "sell"
			renderShop()
		end)
		ts.Position = UDim2.fromOffset(128, 0)
		ts.Parent = tabs
		label({ Text = "💰 " .. tostring(player:GetAttribute("Gold") or shopData.gold or 0), Font = BOLD, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(1, -270, 1, 0), Position = UDim2.fromOffset(260, 0), Parent = tabs })
		local rows = shopTab == "buy" and (shopData.buy or {}) or (shopData.sell or {})
		-- grille d'icônes façon marchand WoW : prix sous chaque case ; clic = 1, clic droit = 5 ;
		-- survol = infobulle complète (le serveur revérifie tout)
		local sgrid = new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 10, Parent = shopBody },
			{ new("UIGridLayout", { CellSize = UDim2.fromOffset(56, 70), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
		for i, e in rows do
			local holder = new("Frame", { BackgroundTransparency = 1, LayoutOrder = i, Parent = sgrid })
			local isAnimal = string.sub(e.item, 1, 7) == "animal:"
			local cell = isAnimal and new("TextButton", { Text = e.icon or "🐾", TextSize = 28, Font = BOLD, BackgroundColor3 = Color3.fromRGB(30, 26, 22),
				Size = UDim2.fromOffset(52, 52), Parent = holder, ZIndex = 7 }, { corner(4), stroke(Color3.fromRGB(176, 140, 72), 1.5) })
				or slotCell(holder, 52, e.item, e.n, 7)
			cell.Name = "Article" .. i
			label({ Text = "💰" .. e.price, Font = BOLD, TextSize = 12, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 53), Parent = holder, ZIndex = 7 })
			local verb = shopTab == "buy" and "buy" or "sell"
			cell.Activated:Connect(function()
				send(verb, { item = e.item, n = 1 })
				-- petit rebond : l'achat se sent
				cell.Size = UDim2.fromOffset(46, 46)
				TweenService:Create(cell, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(52, 52) }):Play()
			end)
			cell.MouseButton2Click:Connect(function()
				send(verb, { item = e.item, n = 5 })
			end)
			cell.MouseEnter:Connect(function()
				local lines = isAnimal and { { e.name, C.text, 15 } } or itemLines(e.item, e.n)
				table.insert(lines, { (shopTab == "buy" and "Prix : " or "Il t'en donne : ") .. e.price .. " 💰", C.gold, 13 })
				table.insert(lines, { shopTab == "buy" and "Clic : acheter 1 · clic droit : 5" or "Clic : vendre 1 · clic droit : 5", C.dim, 11 })
				showTip(lines)
			end)
			cell.MouseLeave:Connect(function()
				if not tipActions then
					hideTip()
				end
			end)
		end
		if #rows == 0 then
			label({ Text = shopTab == "buy" and "Rien à vendre ici pour toi." or "Rien qui l'intéresse dans ton sac.", TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 10, Parent = shopBody })
		end
	end
	Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end
		if data.kind == "craft" then
			showCraft(data.stations, data.tab)
		elseif data.kind == "chest" then
			local wasOpen = chest.Visible
			chestData = data
			if not wasOpen then
				closeAll()
			end
			chest.Visible = true
			renderChest()
		elseif data.kind == "look" then
			openLook(data)
		elseif data.kind == "shop" then
			local wasOpen = shop.Visible
			shopData = data
			if not wasOpen then
				closeAll()
				shopTab = "buy"
			end
			shop.Visible = true
			renderShop()
		elseif data.kind == "close" then
			closeLook()
			closeAll() -- le serveur ferme la fenêtre (trop loin du comptoir, coffre disparu…)
		end
	end)

	-- ---------------------------------------------------------------- Dialogue
	local dlg = new("Frame", {
		Size = UDim2.new(0, 640, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0.5, 0, 1, -16), AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = C.panel, BackgroundTransparency = 0.04, Visible = false, Parent = gui, ZIndex = 8,
	}, { corner(14), stroke(C.line, 2.5), pad(14), new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local dName = label({ Text = "", Font = TITLE, TextSize = 22, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = dlg, ZIndex = 9 })
	local dRole = label({ Text = "", TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 2, Parent = dlg, ZIndex = 9 })
	local dText = label({ Text = "", TextSize = 18, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = dlg, ZIndex = 9 })
	local dOpts = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 4, Parent = dlg, ZIndex = 9 },
		{ new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local dlgToken = 0
	Remotes:WaitForChild("Dialog").OnClientEvent:Connect(function(data)
		dlgToken += 1
		local my = dlgToken
		if not data then
			dlg.Visible = false
			return
		end
		closeAll()
		dName.Text = data.name or ""
		local op = data.opinion
		dRole.Text = (data.role or "") .. (op and ("  ·  " .. (op >= 30 and "💚 t'apprécie" or (op <= -30 and "💢 se méfie de toi" or "😐 neutre"))) or "")
		dText.Text = data.text or ""
		clear(dOpts)
		for i, o in data.options or {} do
			local b = button(o.text, o.id == "bye" and C.panel2 or C.blue, function()
				send("dialog", { choice = o.id })
			end)
			b.Size = UDim2.new(1, 0, 0, 38)
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.LayoutOrder = i
			b.ZIndex = 9
			pad(10).Parent = b
			b.Parent = dOpts
		end
		dlg.Visible = true
		if data.closing then
			task.delay(2.5, function()
				if dlgToken == my then
					dlg.Visible = false
				end
			end)
		end
	end)

	end
	-- ---------------------------------------------------------------- Talents (façon World of Warcraft)
	-- Une colonne par voie ; les paliers se débloquent avec les points déjà dépensés dans la voie.
	local TALENT_ICONS = {
		crochetage = "🔓", ombre = "🌑", cavale = "🏃", receleur = "💰", main_verte = "🌿", arrosage = "💧", negociant = "⚖️", eleveur = "🐄",
		apprivoiseur = "🎶", meute = "🐺", vigilance = "👁️", econome = "🧮", mineur = "⛏️", serrurier = "🔐", forgeron = "🔨",
		primes = "🎯", menottes = "⛓️", robuste = "🛡️", critique = "🗡️",
		fantome = "👻", cavaleur = "💨", terre_riche = "🌾", marchand_ne = "🏷️", alpha = "🐺", cavalier = "🐎",
		prodigue = "✋", veine = "💎", colosse = "🗿", traqueur = "🏹",
		cartographe = "🗺️", prospecteur = "⛏️", archeologue = "📜", survivaliste = "🔥", decouvreur = "🧭", aventurier = "🐴", chasseur_tresor = "💰",
	}
	local nTrees = #Config.TALENT_TREES
	local COLW = 150
	local tal = new("Frame", {
		Name = "Talents", Size = UDim2.fromOffset(nTrees * (COLW + 8) + 24, 560), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), -- 560 : palier 4 (talents de maître)
		BackgroundColor3 = Color3.fromRGB(20, 16, 13), BackgroundTransparency = 0.03, Visible = false, Parent = gui, ZIndex = 5,
	}, { corner(6), stroke(Color3.fromRGB(176, 140, 72), 2.5) })
	panels.Talents = tal
	local talTitle = Composants.titre({ Text = "Talents", Font = TITLE, TextSize = 22, TextColor3 = C.gold, Size = UDim2.new(1, -60, 0, 32), Position = UDim2.fromOffset(14, 6), Parent = tal, ZIndex = 6 })
	local function closeTal()
		tal.Visible = false
		hideTip()
	end
	local tclose = button("X", C.red, closeTal)
	tclose.Size = UDim2.fromOffset(28, 28)
	tclose.Position = UDim2.new(1, -36, 0, 8)
	tclose.ZIndex = 6
	tclose.Parent = tal
	WindowNav.watch(tal, tclose, closeTal)
	local tcols = new("Frame", { Size = UDim2.new(1, -24, 1, -96), Position = UDim2.fromOffset(12, 44), BackgroundTransparency = 1, Parent = tal, ZIndex = 6 },
		{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) })
	local tfoot = new("Frame", { Size = UDim2.new(1, -24, 0, 36), Position = UDim2.new(0, 12, 1, -46), BackgroundTransparency = 1, Parent = tal, ZIndex = 6 })
	local TREE_BG = {
		horsloi = Color3.fromRGB(40, 26, 40), fermier = Color3.fromRGB(32, 40, 24), dresseur = Color3.fromRGB(40, 32, 22),
		artisan = Color3.fromRGB(38, 34, 30), justicier = Color3.fromRGB(26, 32, 44), explorateur = Color3.fromRGB(24, 38, 40),
	}

	local function renderTalents()
		clear(tcols)
		clear(tfoot)
		local free = inv.talentFree or 0
		local ranks = inv.talents or {}
		local total = 0
		for _, r in ranks do
			total += r
		end
		talTitle.Text = "✨ Talents   ·   " .. free .. " point" .. (free > 1 and "s" or "") .. " à dépenser"
		for ti, tree in Config.TALENT_TREES do
			local spent = 0
			local tiers = {}
			for _, t in Config.TALENTS do
				if t.tree == tree.id then
					spent += ranks[t.id] or 0
					tiers[t.req] = tiers[t.req] or {}
					table.insert(tiers[t.req], t)
				end
			end
			local col = new("Frame", { Size = UDim2.new(0, COLW, 1, 0), BackgroundColor3 = TREE_BG[tree.id] or C.panel2, LayoutOrder = ti, Parent = tcols, ZIndex = 6 },
				{ corner(6), stroke(Color3.fromRGB(90, 72, 46), 1.5) })
			label({ Text = tree.icon .. " " .. tree.name, Font = TITLE, TextSize = 16, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 4), Parent = col, ZIndex = 7 })
			label({ Text = spent .. " point" .. (spent > 1 and "s" or "") .. " dépensé" .. (spent > 1 and "s" or ""), TextSize = 12, TextColor3 = C.dim,
				TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 26), Parent = col, ZIndex = 7 })
			local maxTier = 0
			for req in tiers do
				maxTier = math.max(maxTier, req)
			end
			for req = 0, maxTier do
				local list = tiers[req] or {}
				local y = 54 + req * 82
				-- trait du palier précédent vers celui-ci
				if req > 0 then
					new("Frame", { Size = UDim2.fromOffset(4, 26), Position = UDim2.new(0.5, -2, 0, y - 28), BackgroundColor3 = spent >= req and C.gold or Color3.fromRGB(70, 62, 52),
						BorderSizePixel = 0, Parent = col, ZIndex = 6 })
				end
				for k, t in list do
					local rank = ranks[t.id] or 0
					-- choix exclusif (talents de maître) : l'autre talent du même groupe est déjà pris
					local takenOther = nil
					if t.excl then
						for tid, r in ranks do
							local o = Config.TALENT_BY_ID[tid]
							if r > 0 and tid ~= t.id and o and o.excl == t.excl then
								takenOther = o.name
							end
						end
					end
					local locked = spent < t.req or takenOther ~= nil
					local maxed = rank >= t.max
					local can = not locked and not maxed and free > 0
					local x = COLW / 2 + (k - (#list + 1) / 2) * 64 - 26
					local b = new("TextButton", {
						Text = TALENT_ICONS[t.id] or string.sub(t.name, 1, 1), TextSize = 26, Font = BOLD, TextColor3 = C.text, AutoButtonColor = can,
						BackgroundColor3 = locked and Color3.fromRGB(34, 32, 30) or Color3.fromRGB(46, 38, 30), Size = UDim2.fromOffset(52, 52),
						Position = UDim2.fromOffset(x, y), TextTransparency = locked and 0.6 or 0, Parent = col, ZIndex = 7,
					}, { corner(6) })
					stroke(maxed and C.gold or (can and Color3.fromRGB(30, 255, 0) or (rank > 0 and Color3.fromRGB(30, 200, 0) or Color3.fromRGB(90, 84, 76))), maxed and 2.5 or 2).Parent = b
					new("TextLabel", {
						Text = rank .. "/" .. t.max, Font = BOLD, TextSize = 12, TextColor3 = maxed and C.gold or (rank > 0 and Color3.fromRGB(30, 255, 0) or C.text),
						BackgroundColor3 = Color3.fromRGB(10, 8, 6), BackgroundTransparency = 0.1, Size = UDim2.fromOffset(30, 16), Position = UDim2.new(1, -24, 1, -10),
						Parent = b, ZIndex = 8,
					}, { corner(4) })
					b.MouseEnter:Connect(function()
						local lines = { { t.name, C.text, 16 }, { "Rang " .. rank .. "/" .. t.max, C.dim, 12 }, { t.desc, Color3.fromRGB(255, 210, 0) } }
						if takenOther then
							table.insert(lines, { "Exclusif : tu as pris « " .. takenOther .. " »", C.red })
						elseif locked then
							table.insert(lines, { "Demande " .. t.req .. " point(s) dans " .. tree.name, C.red })
						elseif can then
							table.insert(lines, { "Clic : apprendre", Color3.fromRGB(30, 255, 0), 12 })
						end
						showTip(lines)
					end)
					b.MouseLeave:Connect(function()
						if not tipActions then
							hideTip()
						end
					end)
					b.Activated:Connect(function()
						if can then
							send("learn_talent", { id = t.id })
						end
					end)
				end
			end
		end
		label({ Text = "1 point de talent tous les 2 niveaux  ·  " .. total .. " point(s) placé(s)", TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(0.6, 0, 1, 0), Parent = tfoot, ZIndex = 7 })
		if total > 0 then
			local mastery = 0
			for _, xp in inv.skills or {} do
				mastery += Config.skillLevel(xp)
			end
			local cost = math.max(25, 25 * Config.talentPoints(mastery))
			local r = button("Oublier les talents (" .. cost .. " 💰)", C.red, function()
				send("reset_talents")
			end)
			r.Size = UDim2.fromOffset(250, 32)
			r.TextSize = 14
			r.Position = UDim2.new(1, -250, 0, 2)
			r.ZIndex = 7
			r.Parent = tfoot
		end
	end
	local function toggleTalents()
		local v = not tal.Visible
		closeAll()
		hideTip()
		tal.Visible = v
		if v then
			renderTalents()
		end
	end
	Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function()
		if tal.Visible then
			task.defer(renderTalents)
		end
	end)

	-- ---------------------------------------------------------------- Mini-jeu (crochetage, apprivoisement)
	-- Le serveur décide : on affiche le curseur avec la même formule et on envoie seulement « j'appuie ».
	local mg = new("Frame", {
		Size = UDim2.fromOffset(480, 190), Position = UDim2.new(0.5, 0, 1, -24), AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = C.panel, BackgroundTransparency = 0.04, Visible = false, Parent = gui, ZIndex = 30,
	}, { corner(14), stroke(C.gold, 2.5) })
	local mgTitle = label({ Text = "", Font = TITLE, TextSize = 20, TextColor3 = C.gold, Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(12, 8), Parent = mg, ZIndex = 31 })
	local mgHint = label({ Text = "", TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(12, 34), Parent = mg, ZIndex = 31 })
	local bar = new("Frame", { Size = UDim2.new(1, -40, 0, 26), Position = UDim2.fromOffset(20, 70), BackgroundColor3 = C.panel2, Parent = mg, ZIndex = 31 }, { corner(8) })
	local zone = new("Frame", { Size = UDim2.fromScale(0.2, 1), BackgroundColor3 = C.green, BackgroundTransparency = 0.15, Parent = bar, ZIndex = 32 }, { corner(6) })
	local cursor = new("Frame", { Size = UDim2.new(0, 6, 1, 10), Position = UDim2.new(0.5, -3, 0, -5), BackgroundColor3 = C.text, Parent = bar, ZIndex = 33 }, { corner(3) })
	local mgInfo = label({ Text = "", Font = BOLD, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 104), Parent = mg, ZIndex = 31 })
	local mgState = nil
	local press = button(MOBILE and "APPUYER" or "APPUYER  [Espace]", C.gold, function()
		if mgState then
			send("mg_press")
		end
	end)
	press.Size = UDim2.new(0.62, 0, 0, 42)
	press.Position = UDim2.new(0.04, 0, 1, -52)
	press.TextColor3 = Color3.fromRGB(40, 30, 20)
	press.ZIndex = 31
	press.Parent = mg
	local quit = button("Abandonner", C.red, function()
		send("mg_cancel")
	end)
	quit.Size = UDim2.new(0.28, 0, 0, 42)
	quit.Position = UDim2.new(0.68, 0, 1, -52)
	quit.ZIndex = 31
	quit.Parent = mg

	local function mgRefresh()
		if not mgState then
			return
		end
		zone.Size = UDim2.fromScale(mgState.zone, 1)
		zone.Position = UDim2.fromScale(mgState.center - mgState.zone / 2, 0)
		mgInfo.Text = string.format("Réussis : %d / %d      Fautes permises : %d", mgState.done, mgState.pins, math.max(0, mgState.misses - mgState.missed))
	end
	Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" or data.kind ~= "minigame" then
			return
		end
		if data.event == "end" then
			mgState = nil
			mgInfo.Text = data.ok and "✅ Réussi !" or ("❌ " .. (data.msg or "Raté"))
			mgInfo.TextColor3 = data.ok and C.green or C.red
			task.delay(1.2, function()
				if not mgState then
					mg.Visible = false
				end
			end)
			return
		end
		if data.event == "start" then
			closeAll()
			mgTitle.Text = data.title or ""
			mgHint.Text = data.hint or ""
		end
		if data.event == "miss" then
			bar.BackgroundColor3 = C.red
			task.delay(0.2, function()
				bar.BackgroundColor3 = C.panel2
			end)
		end
		mgInfo.TextColor3 = C.text
		mgState = { pins = data.pins, done = data.done, misses = data.misses, missed = data.missed, zone = data.zone, speed = data.speed,
			center = data.center, phase = data.phase, t0 = os.clock() }
		if data.event == "miss" and mgState then
			mgState.t0 = (mgState.t0 or os.clock())
		end
		mg.Visible = true
		mgRefresh()
	end)
	RunService.RenderStepped:Connect(function()
		if mgState then
			local t = os.clock() - mgState.t0
			local pos = 0.5 + 0.5 * math.sin(2 * math.pi * mgState.speed * t + mgState.phase)
			cursor.Position = UDim2.new(pos, -3, 0, -5)
			local inside = math.abs(pos - mgState.center) <= mgState.zone / 2
			cursor.BackgroundColor3 = inside and C.gold or C.text
		end
	end)

	-- ---------------------------------------------------------------- Échange entre joueurs
	local tradeP, tradeBody, tradeTitle = makePanel("Echange", "🤝 Échange", UDim2.fromOffset(680, 500), function()
		send("trade_cancel")
	end)
	local tradeData = nil
	local function itemsLine(t)
		local parts = {}
		for id, n in t or {} do
			local info = itemInfo(id)
			table.insert(parts, (info.icon or "") .. " " .. info.name .. " ×" .. n)
		end
		table.sort(parts)
		return #parts > 0 and table.concat(parts, "   ") or "(rien)"
	end
	local function renderTrade()
		if not tradeData then
			return
		end
		clear(tradeBody)
		tradeTitle.Text = "🤝 Échange avec " .. tradeData.with
		label({ Text = "Il propose " .. (tradeData.readyTheirs and "✅" or "") .. " :", Font = TITLE, TextSize = 17, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1, Parent = tradeBody })
		label({ Text = itemsLine(tradeData.theirs), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = tradeBody })
		label({ Text = "Tu proposes " .. (tradeData.readyMine and "✅" or "") .. " (clic = retirer 1) :", Font = TITLE, TextSize = 17, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 3, Parent = tradeBody })
		local mine = new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 4, Parent = tradeBody },
			{ new("UIGridLayout", { CellSize = UDim2.fromOffset(150, 40), CellPadding = UDim2.fromOffset(6, 6) }) })
		for id, n in tradeData.mine or {} do
			local info = itemInfo(id)
			local b = button((info.icon or "") .. " " .. info.name .. " ×" .. n, C.panel2, function()
				send("trade_offer", { item = id, n = -1 })
			end)
			b.TextSize = 12
			b.Parent = mine
		end
		local actions = new("Frame", { Size = UDim2.new(1, -8, 0, 40), BackgroundTransparency = 1, LayoutOrder = 5, Parent = tradeBody },
			{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
		for _, g in { 10, 100, 1000 } do
			local b = button("+" .. g .. " 💰", C.gold, function()
				send("trade_offer", { item = "gold", n = g })
			end)
			b.Size = UDim2.fromOffset(100, 36)
			b.TextColor3 = Color3.fromRGB(40, 30, 20)
			b.Parent = actions
		end
		local ok = button(tradeData.readyMine and "En attente…" or "✅ J'accepte", C.green, function()
			send("trade_ready")
		end)
		ok.Size = UDim2.fromOffset(150, 36)
		ok.Parent = actions
		label({ Text = "Ton sac (clic = proposer 1, toute modification annule les ✅) :", Font = TITLE, TextSize = 15, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 6, Parent = tradeBody })
		local bagGrid = new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 7, Parent = tradeBody },
			{ new("UIGridLayout", { CellSize = UDim2.fromOffset(150, 40), CellPadding = UDim2.fromOffset(6, 6) }) })
		for id, n in inv.inv do
			local info = itemInfo(id)
			if id ~= "gold" and n > 0 and not info.tool then
				local b = button((info.icon or "") .. " " .. info.name .. " ×" .. n, C.panel2, function()
					send("trade_offer", { item = id, n = 1 })
				end)
				b.TextSize = 12
				b.Parent = bagGrid
			end
		end
	end

	-- invitation
	local invite = new("Frame", { Size = UDim2.fromOffset(420, 110), Position = UDim2.new(0.5, 0, 0, 120), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = C.panel, Visible = false, Parent = gui, ZIndex = 25 }, { corner(12), stroke(C.gold, 2) })
	local inviteText = label({ Text = "", Font = BOLD, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 8), Parent = invite, ZIndex = 26 })
	local yes = button("Accepter", C.green, function()
		invite.Visible = false
		send("trade_accept")
	end)
	yes.Position = UDim2.new(0.5, -130, 1, -48)
	yes.ZIndex = 26
	yes.Parent = invite
	local no = button("Refuser", C.red, function()
		invite.Visible = false
	end)
	no.Position = UDim2.new(0.5, 10, 1, -48)
	no.ZIndex = 26
	no.Parent = invite

	-- ---------------------------------------------------------------- Étal de joueur
	local stallP, stallBody, stallTitle = makePanel("Etal", "🏪 Étal", UDim2.fromOffset(660, 500))
	local stallData = nil
	local function renderStall()
		local d = stallData
		if not d then
			return
		end
		clear(stallBody)
		stallTitle.Text = "🏪 " .. (d.title or "Étal")
		local order = 0
		if d.mine then
			local top = new("Frame", { Size = UDim2.new(1, -8, 0, 40), BackgroundTransparency = 1, LayoutOrder = 0, Parent = stallBody })
			label({ Text = "Caisse : " .. (d.till or 0) .. " 💰  (taxe du marché du village)", Font = BOLD, TextColor3 = C.gold, Size = UDim2.new(1, -150, 1, 0), Parent = top })
			local b = button("Encaisser", C.gold, function()
				send("stall_collect", { id = d.id })
			end)
			b.Position = UDim2.new(1, -128, 0, 2)
			b.TextColor3 = Color3.fromRGB(40, 30, 20)
			b.Parent = top
		end
		for i, r in d.rows or {} do
			order = i
			local row = new("Frame", { Size = UDim2.new(1, -8, 0, 46), BackgroundColor3 = C.panel2, LayoutOrder = 10 + i, Parent = stallBody }, { corner(8) })
			-- case d'objet (icône, quantité, rareté, infobulle) + nom
			local ic = slotCell(row, 40, r.item, r.n, 7)
			ic.Position = UDim2.fromOffset(3, 3)
			ic.MouseEnter:Connect(function()
				showTip(itemLines(r.item, r.n))
			end)
			ic.MouseLeave:Connect(function()
				if not tipActions then
					hideTip()
				end
			end)
			label({ Text = r.name, Font = BOLD, Size = UDim2.new(1, -380, 1, 0), Position = UDim2.fromOffset(50, 0), Parent = row })
			label({ Text = r.price .. " 💰 / u", TextColor3 = C.gold, Size = UDim2.fromOffset(100, 46), Position = UDim2.new(1, -320, 0, 0), Parent = row })
			if d.mine then
				for k, delta in { -5, 5 } do
					local b = button((delta > 0 and "+" or "") .. delta, C.panel, function()
						send("stall_put", { id = d.id, item = r.item, n = 0, price = math.max(1, r.price + delta) })
					end)
					b.Size = UDim2.fromOffset(46, 34)
					b.Position = UDim2.new(1, -218 + (k - 1) * 50, 0, 6)
					b.Parent = row
				end
				local t = button("Retirer", C.red, function()
					send("stall_take", { id = d.id, item = r.item })
				end)
				t.Size = UDim2.fromOffset(100, 34)
				t.Position = UDim2.new(1, -108, 0, 6)
				t.Parent = row
			else
				local b = button("Acheter 1", C.green, function()
					send("stall_buy", { id = d.id, item = r.item, n = 1 })
				end)
				b.Position = UDim2.new(1, -128, 0, 5)
				b.Parent = row
			end
		end
		if d.mine then
			label({ Text = "Ton sac (clic = mettre tout en vente au prix conseillé) :", Font = TITLE, TextSize = 15, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 500, Parent = stallBody })
			local grid = new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 501, Parent = stallBody },
				{ new("UIGridLayout", { CellSize = UDim2.fromOffset(46, 46), CellPadding = UDim2.fromOffset(4, 4) }) })
			for id, n in inv.inv do
				local info = itemInfo(id)
				if id ~= "gold" and n > 0 and not info.tool then
					local b = slotCell(grid, 46, id, n, 7)
					b.Activated:Connect(function()
						hideTip()
						send("stall_put", { id = d.id, item = id, n = n })
					end)
					b.MouseEnter:Connect(function()
						local lines = itemLines(id, n)
						table.insert(lines, { "Clic : tout mettre en vente au prix conseillé", C.dim, 11 })
						showTip(lines)
					end)
					b.MouseLeave:Connect(function()
						if not tipActions then
							hideTip()
						end
					end)
				end
			end
		elseif #(d.rows or {}) == 0 then
			label({ Text = "Rien à vendre pour l'instant.", TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = stallBody })
		end
		local _ = order
	end
	Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) == "table" and data.kind == "stall" then
			if not stallP.Visible then
				closeAll()
			end
			stallData = data
			stallP.Visible = true
			renderStall()
		end
	end)

	-- ---------------------------------------------------------------- Carte maritime (voyage entre mondes)
	local seaP, seaBody = makePanel("Mer", "🧭 Carte des mondes", UDim2.fromOffset(700, 520))
	local BI = { prairie = "🌼", foret = "🍂", desert = "🌵", neige = "❄️", marais = "🐸" }
	Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" or data.kind ~= "seamap" then
			return
		end
		closeAll()
		seaP.Visible = true
		clear(seaBody)
		label({ Text = "Ton perso, ton sac et tes étoiles te suivent. Ta maison et tes coffres restent sur chaque île. Les joueurs proches qui choisissent la même destination embarquent avec toi.", TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 0, Parent = seaBody })
		local unknown = button("🌫️ Explorer l'inconnu (" .. data.costUnknown .. " 💰) : découvre une île jamais vue", C.blue, function()
			send("voyage", { id = "inconnu" })
			seaP.Visible = false
		end)
		unknown.Size = UDim2.new(1, -8, 0, 44)
		unknown.LayoutOrder = 1
		unknown.Parent = seaBody
		for i, w in data.worlds or {} do
			local row = new("Frame", { Size = UDim2.new(1, -8, 0, 58), BackgroundColor3 = w.here and C.panel or C.panel2, LayoutOrder = 10 + i, Parent = seaBody }, { corner(8) })
			local bl = {}
			for _, b in w.biomes or {} do
				table.insert(bl, (BI[b[1]] or "") .. b[2] .. "%")
			end
			label({ Text = w.name .. (w.here and "  (tu es ici)" or ""), Font = BOLD, Size = UDim2.new(1, -170, 0, 24), Position = UDim2.fromOffset(10, 4), Parent = row })
			label({ Text = string.format("👥 %d/%d   ☠️ %s   %s%s", w.n, w.cap, string.rep("★", w.danger or 1), table.concat(bl, " "), w.by and ("   🧭 découvert par " .. w.by) or ""),
				TextSize = 12, TextColor3 = C.dim, Size = UDim2.new(1, -170, 0, 22), Position = UDim2.fromOffset(10, 30), Parent = row })
			if not w.here then
				local full = w.n >= w.cap
				local b = button(full and "Complet" or ("Y aller (" .. data.costKnown .. " 💰)"), full and C.panel or C.green, function()
					if not full then
						send("voyage", { id = w.id })
						seaP.Visible = false
					end
				end)
				b.Size = UDim2.fromOffset(150, 40)
				b.Position = UDim2.new(1, -158, 0, 9)
				b.Parent = row
			end
		end
	end)

	local cibleApi = {}
	-- ---------------------------------------------------------------- Caserne
	local barP, barBody, barTitle = makePanel("Caserne", "🏰 Caserne", UDim2.fromOffset(640, 480))
	Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" or data.kind ~= "barracks" then
			return
		end
		if not barP.Visible then
			closeAll()
		end
		barP.Visible = true
		clear(barBody)
		barTitle.Text = string.format("🏰 Caserne · %d soldat(s) · solde %d 💰/jour", data.count, data.wages)
		label({ Text = "Pas d'effectif maximum : ta limite, c'est la solde payée chaque matin (2 jours impayés = un déserteur). Une recrue après l'autre par caserne. Un soldat mort ne revient pas. Ordres : approche-toi d'un soldat.", TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 0, Parent = barBody })
		if data.count > 0 then
			local orders = new("Frame", { Name = "Ordres", Size = UDim2.new(1, -8, 0, 42), BackgroundTransparency = 1, LayoutOrder = 0, Parent = barBody },
				{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
			for _, order in { { "suivre", "Suivre" }, { "tenir", "Tenir" }, { "patrouiller", "Patrouiller" }, { "attaquer", "Attaquer" } } do
				local command = button(order[2], C.blue, function()
					local target = cibleApi.get()
					local id = order[1] == "attaquer" and target and target:GetAttribute("EnemyId") or nil
					send("armee_ordre", { o = order[1], target = id })
				end)
				command.Size = UDim2.new(0.25, -5, 1, 0)
				command.Parent = orders
			end
		end
		for i, u in data.units or {} do
			local row = new("Frame", { Size = UDim2.new(1, -8, 0, 58), BackgroundColor3 = C.panel2, LayoutOrder = i, Parent = barBody }, { corner(8) })
			label({ Text = u.name .. "  ·  ❤️ " .. u.hp .. "  ⚔️ " .. u.dmg .. "  ·  " .. u.desc, Font = BOLD, TextSize = 14, Size = UDim2.new(1, -150, 0, 24), Position = UDim2.fromOffset(10, 3), Parent = row })
			label({ Text = u.cost .. "   ·   solde " .. u.wage .. " 💰/j   ·   formation " .. math.floor(u.train / 60) .. " min", TextSize = 12, TextColor3 = C.dim, Size = UDim2.new(1, -150, 0, 24), Position = UDim2.fromOffset(10, 28), Parent = row })
			local b = button("Recruter", C.green, function()
				send("recruit", { id = data.id, unit = u.id })
			end)
			b.Position = UDim2.new(1, -128, 0, 11)
			b.Parent = row
		end
		if #(data.queue or {}) > 0 then
			local parts = {}
			for _, q in data.queue do
				table.insert(parts, q.name .. " (" .. math.ceil(q.left / 60) .. " min)")
			end
			label({ Text = "En formation : " .. table.concat(parts, ", "), Font = BOLD, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 50, Parent = barBody })
		end
	end)

	-- ---------------------------------------------------------------- La poste (courrier + hôtel des ventes)
	local postP, postBody = makePanel("Poste", "📬 Poste et hôtel des ventes", UDim2.fromOffset(700, 520))
	local postTab = "mail"
	local postData = nil
	local selItem = nil
	local function renderPost()
		local d = postData
		if not d then
			return
		end
		clear(postBody)
		local tabs = new("Frame", { Size = UDim2.new(1, -8, 0, 38), BackgroundTransparency = 1, LayoutOrder = 0, Parent = postBody }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
		for _, t in { { "mail", "📬 Courrier (" .. #(d.mail or {}) .. ")" }, { "market", "🏷️ Hôtel des ventes" }, { "sell", "Vendre / envoyer" } } do
			local b = button(t[2], postTab == t[1] and C.blue or C.panel2, function()
				postTab = t[1]
				renderPost()
			end)
			b.Size = UDim2.fromOffset(200, 34)
			b.Parent = tabs
		end
		if postTab == "mail" then
			for i, p in d.mail or {} do
				-- un colis = une ligne : expéditeur + cases d'objets (icône, quantité, infobulle) + or
				local row = new("Frame", { Size = UDim2.new(1, -8, 0, 48), BackgroundColor3 = C.panel2, LayoutOrder = i, Parent = postBody }, { corner(8),
					new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center }), pad(4) })
				label({ Text = "📦 " .. p.from, Font = BOLD, TextSize = 13, Size = UDim2.fromOffset(170, 40), Parent = row })
				if (p.gold or 0) > 0 then
					label({ Text = "💰 " .. p.gold, Font = BOLD, TextColor3 = C.gold, Size = UDim2.fromOffset(70, 40), Parent = row })
				end
				for id, n in p.items or {} do
					local c = slotCell(row, 40, id, n, 7)
					c.MouseEnter:Connect(function()
						showTip(itemLines(id, n))
					end)
					c.MouseLeave:Connect(function()
						if not tipActions then
							hideTip()
						end
					end)
				end
			end
			local hasMail = #(d.mail or {}) > 0
			if not hasMail and not d.mailPending then
				label({ Text = "Aucun courrier.", TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = postBody })
			else
				local b = button(hasMail and "Tout récupérer" or "Finaliser la collecte", C.green, function()
					send("mail_collect")
				end)
				b.Size = UDim2.fromOffset(200, 38)
				b.LayoutOrder = 999
				b.Parent = postBody
			end
		elseif postTab == "market" then
			-- recherche + tri par prix unitaire (le moins cher d'abord) : comparer les offres d'un coup d'œil
			local bar = new("Frame", { Size = UDim2.new(1, -8, 0, 34), BackgroundTransparency = 1, LayoutOrder = 0, Parent = postBody })
			local box = new("TextBox", { Text = d.search or "", PlaceholderText = "🔍 Chercher un objet…", ClearTextOnFocus = false, Font = BODY, TextSize = 14,
				TextColor3 = C.text, PlaceholderColor3 = C.dim, BackgroundColor3 = C.panel2, Size = UDim2.new(1, -170, 1, 0), Parent = bar }, { corner(8) })
			box.FocusLost:Connect(function()
				d.search = box.Text
				renderPost()
			end)
			local sortB = button(d.sortDesc and "Prix ↓" or "Prix ↑", C.panel2, function()
				d.sortDesc = not d.sortDesc
				renderPost()
			end)
			sortB.Size = UDim2.fromOffset(160, 34)
			sortB.Position = UDim2.new(1, -160, 0, 0)
			sortB.Parent = bar
			local shown = {}
			local q = string.lower(d.search or "")
			for _, r in d.market or {} do
				if q == "" or string.find(string.lower(r.name), q, 1, true) then
					table.insert(shown, r)
				end
			end
			table.sort(shown, function(a, b)
				local ua, ub = a.price / math.max(1, a.n), b.price / math.max(1, b.n)
				if d.sortDesc then
					return ua > ub
				end
				return ua < ub
			end)
			for i, r in shown do
				local row = new("Frame", { Size = UDim2.new(1, -8, 0, 44), BackgroundColor3 = C.panel2, LayoutOrder = i, Parent = postBody }, { corner(8) })
				local ic = slotCell(row, 38, r.item, r.n, 7)
				ic.Position = UDim2.fromOffset(3, 3)
				ic.MouseEnter:Connect(function()
					showTip(itemLines(r.item, r.n))
				end)
				ic.MouseLeave:Connect(function()
					if not tipActions then
						hideTip()
					end
				end)
				label({ Text = r.name .. "  ·  par " .. r.seller, Font = BOLD, Size = UDim2.new(1, -300, 1, 0), Position = UDim2.fromOffset(48, 0), Parent = row })
				label({ Text = r.price .. " 💰\n" .. string.format("%.1f", r.price / math.max(1, r.n)) .. " / u", TextSize = 12, TextColor3 = C.gold, Font = BOLD,
					Size = UDim2.fromOffset(100, 44), Position = UDim2.new(1, -235, 0, 0), Parent = row })
				local b = button(r.mine and "Reprendre" or "Acheter", r.mine and C.panel or C.green, function()
					send("market_buy", { id = r.id })
				end)
				b.Position = UDim2.new(1, -128, 0, 4)
				b.Parent = row
			end
			if #(d.market or {}) == 0 then
				label({ Text = "Rien en vente dans ce monde pour l'instant.", TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = postBody })
			end
		else
			label({ Text = "1. Choisis un objet de ton sac  2. Quantité et prix  3. Mets en vente (2 % de frais) ou envoie-le à un joueur (" .. d.postage .. " 💰 de port).", TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = postBody })
			local grid = new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = postBody },
				{ new("UIGridLayout", { CellSize = UDim2.fromOffset(46, 46), CellPadding = UDim2.fromOffset(4, 4) }) })
			for id, n in inv.inv do
				local info = itemInfo(id)
				if n > 0 and not info.tool then
					local b = slotCell(grid, 46, id, n, 7)
					if selItem == id then
						stroke(C.gold, 3).Parent = b
					end
					b.Activated:Connect(function()
						selItem = id
						hideTip()
						renderPost()
					end)
					b.MouseEnter:Connect(function()
						showTip(itemLines(id, n))
					end)
					b.MouseLeave:Connect(function()
						if not tipActions then
							hideTip()
						end
					end)
				end
			end
			if selItem then
				local form = new("Frame", { Size = UDim2.new(1, -8, 0, 120), BackgroundTransparency = 1, LayoutOrder = 3, Parent = postBody })
				local qty = new("TextBox", { Text = "1", PlaceholderText = "Quantité", Font = BODY, TextSize = 16, TextColor3 = C.text, BackgroundColor3 = C.panel2, Size = UDim2.fromOffset(110, 34), Position = UDim2.fromOffset(0, 0), Parent = form }, { corner(8) })
				local price = new("TextBox", { Text = tostring(itemInfo(selItem).price or 10), PlaceholderText = "Prix total", Font = BODY, TextSize = 16, TextColor3 = C.text, BackgroundColor3 = C.panel2, Size = UDim2.fromOffset(130, 34), Position = UDim2.fromOffset(120, 0), Parent = form }, { corner(8) })
				local to = new("TextBox", { Text = "", PlaceholderText = "Pseudo du destinataire", Font = BODY, TextSize = 16, TextColor3 = C.text, BackgroundColor3 = C.panel2, Size = UDim2.fromOffset(260, 34), Position = UDim2.fromOffset(0, 44), Parent = form }, { corner(8) })
				local sell = button("🏷️ Mettre en vente", C.gold, function()
					send("market_list", { item = selItem, n = tonumber(qty.Text) or 1, price = tonumber(price.Text) or 1 })
				end)
				sell.Size = UDim2.fromOffset(200, 34)
				sell.Position = UDim2.fromOffset(260, 0)
				sell.TextColor3 = Color3.fromRGB(40, 30, 20)
				sell.Parent = form
				local mail = button("📮 Envoyer", C.blue, function()
					send("mail_send", { to = to.Text, item = selItem, n = tonumber(qty.Text) or 1 })
				end)
				mail.Size = UDim2.fromOffset(200, 34)
				mail.Position = UDim2.fromOffset(270, 44)
				mail.Parent = form
			end
		end
	end
	Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) == "table" and data.kind == "post" then
			if not postP.Visible then
				closeAll()
			end
			postData = data
			postP.Visible = true
			renderPost()
		end
	end)

	-- ---------------------------------------------------------------- Commandes du village
	local ordersP, ordersBody = makePanel("Commandes", "📦 Commandes du village", UDim2.fromOffset(600, 400))
	local function renderOrders(data)
		clear(ordersBody)
		label({ Text = "Le village paie bien ce que son biome ne produit pas. Nouvelles commandes tous les 2 jours.", TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = ordersBody })
		for i, o in data.rows or {} do
			local row = new("Frame", { Size = UDim2.new(1, -8, 0, 50), BackgroundColor3 = C.panel2, LayoutOrder = i, Parent = ordersBody }, { corner(8) })
			label({ Text = (o.icon or "") .. " " .. o.name .. " ×" .. o.n .. "   (tu en as " .. o.have .. ")", Font = BOLD, Size = UDim2.new(1, -250, 1, 0), Position = UDim2.fromOffset(10, 0), Parent = row })
			label({ Text = "💰 " .. o.reward, TextColor3 = C.gold, Font = BOLD, Size = UDim2.fromOffset(90, 50), Position = UDim2.new(1, -235, 0, 0), Parent = row })
			if o.done then
				label({ Text = "✅ Livrée", TextColor3 = C.green, Size = UDim2.fromOffset(120, 50), Position = UDim2.new(1, -128, 0, 0), Parent = row })
			else
				local b = button("Livrer", o.have >= o.n and C.green or C.panel, function()
					send("order_deliver", { id = o.id })
				end)
				b.Position = UDim2.new(1, -128, 0, 7)
				b.Parent = row
			end
		end
	end

	Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end
		if data.kind == "trade_invite" then
			inviteText.Text = "🤝 " .. data.from .. " te propose un échange."
			invite.Visible = true
			task.delay(15, function()
				invite.Visible = false
			end)
		elseif data.kind == "trade" then
			if not tradeP.Visible then
				closeAll()
			end
			tradeData = data
			tradeP.Visible = true
			renderTrade()
		elseif data.kind == "trade_end" then
			tradeData = nil
			tradeP.Visible = false
		elseif data.kind == "orders" then
			closeAll()
			ordersP.Visible = true
			renderOrders(data)
		end
	end)
	Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function()
		if tradeP.Visible then
			task.defer(renderTrade)
		end
	end)

	-- invite « Échanger » au-dessus des AUTRES joueurs (créée côté client : on ne se voit pas soi-même)
	local function tradePrompt(other: Player, char: Model)
		local root = char:WaitForChild("HumanoidRootPart", 10)
		if not root then
			return
		end
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Échanger"
		pp.ObjectText = other.DisplayName
		pp.KeyboardKeyCode = Enum.KeyCode.Y
		pp.GamepadKeyCode = Enum.KeyCode.DPadUp
		pp.HoldDuration = 0.3
		pp.MaxActivationDistance = 10
		pp.RequiresLineOfSight = false
		pp.Parent = root
		pp.Triggered:Connect(function()
			send("trade_request", { target = other.UserId })
		end)
	end
	local function watch(other: Player)
		if other == player then
			return
		end
		other.CharacterAdded:Connect(function(c)
			tradePrompt(other, c)
		end)
		if other.Character then
			task.spawn(tradePrompt, other, other.Character)
		end
	end
	for _, o in Players:GetPlayers() do
		watch(o)
	end
	Players.PlayerAdded:Connect(watch)

	-- ---------------------------------------------------------------- Groupe
	local renderGroup = require(script.Parent:WaitForChild("GroupeHud")).mount(gui, uiScale, C, function()
		send("group_leave")
	end)
	local gInvite = new("Frame", { Size = UDim2.fromOffset(420, 110), Position = UDim2.new(0.5, 0, 0, 240), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = C.panel, Visible = false, Parent = gui, ZIndex = 25 }, { corner(12), stroke(C.green, 2) })
	local gText = label({ Text = "", Font = BOLD, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 8), Parent = gInvite, ZIndex = 26 })
	local gy = button("Rejoindre", C.green, function()
		gInvite.Visible = false
		send("group_accept")
	end)
	gy.Position = UDim2.new(0.5, -130, 1, -48)
	gy.ZIndex = 26
	gy.Parent = gInvite
	local gn = button("Non merci", C.red, function()
		gInvite.Visible = false
	end)
	gn.Position = UDim2.new(0.5, 10, 1, -48)
	gn.ZIndex = 26
	gn.Parent = gInvite
	Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end
		if data.kind == "group" then
			renderGroup(data.members or {})
		elseif data.kind == "group_invite" then
			gText.Text = "👥 " .. data.from .. " t'invite dans son groupe."
			gInvite.Visible = true
			task.delay(15, function()
				gInvite.Visible = false
			end)
		end
	end)
	-- invite « Inviter [U] » au-dessus des autres joueurs
	local function groupPrompt(other: Player, char: Model)
		local root = char:WaitForChild("HumanoidRootPart", 10)
		if not root then
			return
		end
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Inviter dans le groupe"
		pp.ObjectText = other.DisplayName
		pp.KeyboardKeyCode = Enum.KeyCode.U
		pp.GamepadKeyCode = Enum.KeyCode.DPadDown
		pp.HoldDuration = 0.3
		pp.MaxActivationDistance = 10
		pp.RequiresLineOfSight = false
		pp.UIOffset = Vector2.new(0, 60)
		pp.Parent = root
		pp.Triggered:Connect(function()
			send("group_invite", { target = other.UserId })
		end)
	end
	local function watchG(other: Player)
		if other == player then
			return
		end
		other.CharacterAdded:Connect(function(c)
			groupPrompt(other, c)
		end)
		if other.Character then
			task.spawn(groupPrompt, other, other.Character)
		end
	end
	for _, o in Players:GetPlayers() do
		watchG(o)
	end
	Players.PlayerAdded:Connect(watchG)

	-- ---------------------------------------------------------------- Clan
	local clanP, clanBody, clanTitle = makePanel("Clan", "🛡️ Clan", UDim2.fromOffset(640, 500))
	local function renderClan(d)
		clear(clanBody)
		if d.none then
			clanTitle.Text = "🛡️ Fonder un clan"
			label({ Text = "Un clan te suit dans tous les mondes : grades, coffre commun, journal. Fonder coûte " .. d.cost .. " 💰.", TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 0, Parent = clanBody })
			local nameBox = new("TextBox", { PlaceholderText = "Nom du clan (3 à 24 lettres)", Text = "", Font = BODY, TextSize = 16, TextColor3 = C.text, BackgroundColor3 = C.panel2, Size = UDim2.new(1, -8, 0, 36), LayoutOrder = 1, ClearTextOnFocus = false, Parent = clanBody }, { corner(8), pad(6) })
			local tagBox = new("TextBox", { PlaceholderText = "Sigle (2 à 4 lettres, ex. LOUP)", Text = "", Font = BODY, TextSize = 16, TextColor3 = C.text, BackgroundColor3 = C.panel2, Size = UDim2.new(1, -8, 0, 36), LayoutOrder = 2, ClearTextOnFocus = false, Parent = clanBody }, { corner(8), pad(6) })
			local b = button("Fonder le clan (" .. d.cost .. " 💰)", C.gold, function()
				send("clan_create", { name = nameBox.Text, tag = tagBox.Text })
			end)
			b.Size = UDim2.new(1, -8, 0, 40)
			b.TextColor3 = Color3.fromRGB(40, 30, 20)
			b.LayoutOrder = 3
			b.Parent = clanBody
			return
		end
		clanTitle.Text = "🛡️ [" .. d.tag .. "] " .. d.name
		local top = new("Frame", { Size = UDim2.new(1, -8, 0, 40), BackgroundTransparency = 1, LayoutOrder = 0, Parent = clanBody }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
		local chestB = button("📦 Coffre du clan", C.panel2, function()
			send("clan_chest")
		end)
		chestB.Size = UDim2.fromOffset(170, 36)
		chestB.Parent = top
		local leaveB = button("Quitter le clan", C.red, function()
			send("clan_leave")
			clanP.Visible = false
		end)
		leaveB.Size = UDim2.fromOffset(150, 36)
		leaveB.Parent = top
		label({ Text = "À partir du grade d’officier, utilise l’invite au-dessus d’un joueur pour le recruter.", TextSize = 12, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = clanBody })
		for i, m in d.members or {} do
			local row = new("Frame", { Size = UDim2.new(1, -8, 0, 40), BackgroundColor3 = C.panel2, LayoutOrder = 10 + i, Parent = clanBody }, { corner(8) })
			label({ Text = (m.online and "🟢 " or "⚫ ") .. m.name .. "  ·  " .. m.rankName, Font = BOLD, Size = UDim2.new(1, -230, 1, 0), Position = UDim2.fromOffset(10, 0), Parent = row })
			if d.me >= 4 and m.rank < d.me and m.id ~= player.UserId then
				local x = -220
				for _, act in { { "▲", 1 }, { "▼", -1 } } do
					local b = button(act[1], C.panel, function()
						send("clan_rank", { target = m.id, delta = act[2] })
					end)
					b.Size = UDim2.fromOffset(40, 30)
					b.Position = UDim2.new(1, x, 0, 5)
					b.Parent = row
					x += 46
				end
				local k = button("Exclure", C.red, function()
					send("clan_kick", { target = m.id })
				end)
				k.Size = UDim2.fromOffset(110, 30)
				k.Position = UDim2.new(1, -118, 0, 5)
				k.Parent = row
			end
		end
		label({ Text = "Journal", Font = TITLE, TextSize = 16, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 200, Parent = clanBody })
		local lines = {}
		for i = #(d.log or {}), math.max(1, #(d.log or {}) - 12), -1 do
			table.insert(lines, "• " .. d.log[i].text)
		end
		label({ Text = table.concat(lines, "\n"), TextSize = 12, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 201, Parent = clanBody })
	end
	local function toggleClan()
		if clanP.Visible then
			clanP.Visible = false
		else
			send("clan_open")
		end
	end
	local cInvite = new("Frame", { Size = UDim2.fromOffset(440, 110), Position = UDim2.new(0.5, 0, 0, 360), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = C.panel, Visible = false, Parent = gui, ZIndex = 25 }, { corner(12), stroke(C.gold, 2) })
	local cText = label({ Text = "", Font = BOLD, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 8), Parent = cInvite, ZIndex = 26 })
	local cy = button("Rejoindre", C.green, function()
		cInvite.Visible = false
		send("clan_accept")
	end)
	cy.Position = UDim2.new(0.5, -130, 1, -48)
	cy.ZIndex = 26
	cy.Parent = cInvite
	local cn = button("Non", C.red, function()
		cInvite.Visible = false
	end)
	cn.Position = UDim2.new(0.5, 10, 1, -48)
	cn.ZIndex = 26
	cn.Parent = cInvite
	Remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end
		if data.kind == "clan" then
			if not clanP.Visible then
				closeAll()
			end
			clanP.Visible = true
			renderClan(data)
		elseif data.kind == "clan_invite" then
			cText.Text = "🛡️ " .. data.from .. " t'invite dans [" .. data.tag .. "] " .. data.clan .. "."
			cInvite.Visible = true
			task.delay(20, function()
				cInvite.Visible = false
			end)
		end
	end)
	local function clanPrompt(other: Player, char: Model)
		local root = char:WaitForChild("HumanoidRootPart", 10)
		if not root then
			return
		end
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Inviter au clan"
		pp.ObjectText = other.DisplayName
		pp.KeyboardKeyCode = Enum.KeyCode.N
		pp.GamepadKeyCode = Enum.KeyCode.DPadRight
		pp.HoldDuration = 0.5
		pp.MaxActivationDistance = 10
		pp.RequiresLineOfSight = false
		pp.UIOffset = Vector2.new(0, 120)
		pp.Parent = root
		pp.Triggered:Connect(function()
			send("clan_invite", { target = other.UserId })
		end)
	end
	local function watchC(other: Player)
		if other == player then
			return
		end
		other.CharacterAdded:Connect(function(c)
			clanPrompt(other, c)
		end)
		if other.Character then
			task.spawn(clanPrompt, other, other.Character)
		end
	end
	for _, o in Players:GetPlayers() do
		watchC(o)
	end
	Players.PlayerAdded:Connect(watchC)

	-- ---------------------------------------------------------------- Construction (façon Minecraft)
	-- Une pièce fabriquée à l'atelier, prise en main depuis la barre rapide : son fantôme suit la souris
	-- (le centre de l'écran sur mobile) et s'accroche contre la surface visée. Clic = poser,
	-- [R] tourner, [Z] retourner, [X] reprendre une de ses pièces. Le serveur vérifie tout.
	local building = false
	local buildBlock = nil
	local buildRot, buildFlip = 0, false
	local ghost = nil
	local ghostCF = nil
	-- Commandes de construction au-dessus de la barre rapide.
	local buildHint = new("Frame", {
		Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0.5, 0, 1, MOBILE and -168 or -100), AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(26, 20, 16), BackgroundTransparency = 0.2, Visible = false, Parent = gui, ZIndex = 12,
	}, { corner(6), pad(4), new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, MOBILE and 6 or 10), VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local buildCount = nil
	if not MOBILE then
		buildCount = label({ Text = "", Font = BOLD, TextSize = 14, TextColor3 = C.gold, Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, Parent = buildHint, ZIndex = 13 })
		local commands = label({ Text = "", Font = BOLD, TextSize = 13, TextWrapped = false, Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X, Parent = buildHint, ZIndex = 13 })
		local function showCommands(input)
			commands.Text = input.Name:match("^Gamepad")
				and "RT Poser · RB Tourner · LB Retourner · X Reprendre · B Annuler"
				or "Clic Poser · R Tourner · Z Retourner · X Reprendre · V Annuler"
		end
		showCommands(UserInputService:GetLastInputType())
		UserInputService.LastInputTypeChanged:Connect(showCommands)
	else
		buildHint.Size = UDim2.fromOffset(0, 48)
	end

	local function haveBlock(): number
		local b = buildBlock and Config.BLOCKS[buildBlock]
		return b and (inv.inv[b.item] or 0) or 0
	end

	local function makeGhost()
		if ghost then
			ghost:Destroy()
			ghost = nil
		end
		local b = buildBlock and Config.BLOCKS[buildBlock]
		if not b then
			return
		end
		local g
		if b.shape == "wedge" then
			g = Instance.new("WedgePart")
		elseif b.shape == "corner" then
			g = Instance.new("CornerWedgePart")
		else
			g = Instance.new("Part")
			if b.shape == "pillar" then
				g.Shape = Enum.PartType.Cylinder
			end
		end
		g.Size = b.shape == "pillar" and Vector3.new(b.size.Y, b.size.X, b.size.Z) or b.size
		g.Anchored = true
		g.CanCollide = false
		g.CanQuery = false
		g.CanTouch = false
		g.Transparency = 0.45
		g.Material = b.mat or Enum.Material.SmoothPlastic
		g.Name = "Fantome"
		g.Parent = workspace
		local sel = Instance.new("SelectionBox")
		sel.Adornee = g
		sel.LineThickness = 0.04
		sel.Color3 = C.green
		sel.Parent = g
		-- pièce composée (arche, mur courbe) : ses blocs suivent la racine (soudés)
		local compose = Config.SHAPE_PARTS and Config.SHAPE_PARTS[b.shape]
		if compose then
			g.Transparency = 1
			g:SetAttribute("Compose", true)
			for _, sp in compose(b.size) do
				local c = Config.makeSubPart and Config.makeSubPart(sp) or Instance.new("Part")
				c.Size = sp[1]
				c.CFrame = g.CFrame * sp[2]
				c.Anchored = false
				c.Massless = true
				c.CanCollide, c.CanQuery, c.CanTouch = false, false, false
				c.Transparency = 0.45
				c.Material = g.Material
				c.Parent = g
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = g, c
				w.Parent = c
			end
		end
		ghost = g
	end

	-- appelé par la barre rapide quand l'objet en main change
	buildHook.fn = function(blockId: string?)
		building = blockId ~= nil
		buildBlock = blockId
		buildHint.Visible = building
		if building then
			makeGhost()
			if buildCount then
				buildCount.Text = (Config.BLOCKS[blockId].name or "") .. "  " .. Composants.quantite(haveBlock())
			end
		elseif ghost then
			ghost:Destroy()
			ghost = nil
		end
	end

	local function aim(): RaycastResult?
		local cam = workspace.CurrentCamera
		local centered = MOBILE or UserInputService:GetLastInputType().Name:match("^Gamepad")
		local pos = centered and (cam.ViewportSize / 2) or UserInputService:GetMouseLocation()
		local ray = cam:ViewportPointToRay(pos.X, pos.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character, ghost }
		return workspace:Raycast(ray.Origin, ray.Direction * 60, params)
	end

	local function snap(v: number): number
		return math.floor(v * 2 + 0.5) / 2
	end

	local apercuParcelle = require(script.Parent:WaitForChild("ParcelleApercu")).new(gui, Remotes, Config.CELL)
	RunService.RenderStepped:Connect(function()
		local open = WindowNav.isOpen()
		local held = not open and hotSlots[selected]
		local info = held and Config.ITEMS[held]
		local position
		if info and info.claim and ownedCount(held) > 0 then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			position = root and ApercuPose.caseDevant(root, Config.CELL)
		end
		apercuParcelle(position)
		if not building or not ghost or not buildBlock then
			return
		end
		buildHint.Visible = not open
		local hit = not open and aim()
		if not hit then
			ghost.Parent = nil
			ghostCF = nil
			return
		end
		if not ghost.Parent then ghost.Parent = workspace end
		local b = Config.BLOCKS[buildBlock]
		local rot = CFrame.Angles(0, math.rad(90 * buildRot), 0) * (buildFlip and CFrame.Angles(0, 0, math.pi) or CFrame.identity)
		-- demi-épaisseur de la pièce le long de la normale visée : on la colle contre la surface
		local n = hit.Normal
		local sx, sy, sz = rot.RightVector, rot.UpVector, rot.LookVector
		local size = b.size
		local half = math.abs(n:Dot(sx)) * size.X / 2 + math.abs(n:Dot(sy)) * size.Y / 2 + math.abs(n:Dot(sz)) * size.Z / 2
		local p = hit.Position + n * half
		p = Vector3.new(snap(p.X), snap(p.Y), snap(p.Z))
		ghostCF = CFrame.new(p) * rot
		ghost.CFrame = b.shape == "pillar" and ghostCF * CFrame.Angles(0, 0, math.rad(90)) or ghostCF
		local ok = haveBlock() > 0
		ghost.Transparency = ghost:GetAttribute("Compose") and 1 or 0.4
		ghost.Color = ok and b.color or C.red
		for _, c in ghost:GetChildren() do
			if c:IsA("BasePart") then
				c.Color = ghost.Color
			end
		end
		local sel = ghost:FindFirstChildOfClass("SelectionBox")
		if sel then
			sel.Color3 = ok and C.green or C.red
		end
	end)

	local function placeNow()
		if WindowNav.isOpen() or not building or not buildBlock or not ghostCF then
			return
		end
		local p = ghostCF.Position
		placementRefusal.remember(p)
		send("build_place", { b = buildBlock, x = p.X, y = p.Y, z = p.Z, r = buildRot, f = buildFlip })
	end
	local function removeNow()
		if WindowNav.isOpen() or not building then
			return
		end
		local hit = aim()
		local part = hit and hit.Instance
		if part and part:GetAttribute("Built") then
			send("build_remove", { id = part:GetAttribute("Built") })
		end
	end
	Remotes:WaitForChild("Inventory").OnClientEvent:Connect(function()
		task.defer(function()
			if building and buildCount then
				buildCount.Text = (Config.BLOCKS[buildBlock].name or "") .. "  " .. Composants.quantite(haveBlock())
			end
		end)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not building or WindowNav.isOpen() then
			return
		end
		if input.KeyCode == Enum.KeyCode.ButtonR2 then
			placeNow()
		elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonR1 then
			buildRot = (buildRot + 1) % 4
		elseif input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.ButtonL1 then
			buildFlip = not buildFlip
		elseif input.KeyCode == Enum.KeyCode.X or input.KeyCode == Enum.KeyCode.ButtonX then
			removeNow()
		elseif input.KeyCode == Enum.KeyCode.ButtonB then
			selectSlot(0)
		end
	end)
	if MOBILE then
		for _, a in { { "Poser", C.green, placeNow }, { "Tourner", C.panel2, function()
			buildRot = (buildRot + 1) % 4
		end }, { "Inverser", C.panel2, function()
			buildFlip = not buildFlip
		end }, { "Reprendre", C.panel2, removeNow }, { "Annuler", C.red, function()
			selectSlot(0)
		end } } do
			local b = button(a[1], a[2], a[3])
			b.Size = UDim2.fromOffset(58, 40)
			b.TextSize = 12
			b.ZIndex = 13
			b.Parent = buildHint
		end
		local cross = label({ Text = "+", Font = BOLD, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0.5, -15, 0.5, -15), Visible = false, Parent = gui, ZIndex = 12 })
		buildHint:GetPropertyChangedSignal("Visible"):Connect(function()
			cross.Visible = buildHint.Visible
		end)
	end
	local function toggleBuild()
		if WindowNav.isOpen() then return end
		if building then
			selectSlot(0)
			return
		end
		-- [V] : prend en main la première pièce de construction de la barre rapide
		for i = 1, HOT do
			local id = hotSlots[i]
			if id ~= "" and itemInfo(id).block then
				selectSlot(i)
				return
			end
		end
		toast("Aucune pièce de construction dans la barre rapide.", nil)
	end

	-- ---------------------------------------------------------------- Effets
	local hurt = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.red, BackgroundTransparency = 1, Parent = gui, ZIndex = 40 })
	Remotes:WaitForChild("Fx").OnClientEvent:Connect(function(kind: string)
		if kind == "hurt" then
			hurt.BackgroundTransparency = 0.6
			TweenService:Create(hurt, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		elseif kind == "bite" then
			toast("🎣 Ça mord ! Relance vite la canne !", "big")
		elseif kind == "fall" then
			-- chute : voile rouge + secousse de caméra courte, amortie (désactivable : ReduceShake)
			hurt.BackgroundTransparency = 0.45
			TweenService:Create(hurt, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum and not player:GetAttribute("ReduceShake") then
				task.spawn(function()
					for i = 6, 1, -1 do
						local a = i * 0.06
						hum.CameraOffset = Vector3.new((math.random() - 0.5) * a, -a, (math.random() - 0.5) * a)
						task.wait(0.03)
					end
					hum.CameraOffset = Vector3.zero
				end)
			end
		end
	end)

	-- ---------------------------------------------------------------- Cible (façon WoW)
	do
	-- Clic droit sur une créature (ou un PNJ, un joueur) : cadre avec nom, niveau et vie.
	-- Échap ou clic droit dans le vide : plus de cible. Le toucher garde sa sélection directe.
	local target = nil -- Model
	cibleApi.get = function()
		return target
	end
	local MOOD_COLOR = { hostile = Color3.fromRGB(255, 90, 70), neutre = Color3.fromRGB(255, 220, 60), passif = Color3.fromRGB(120, 230, 90) }
	local tframe = new("Frame", {
		Name = "Cible", Size = UDim2.fromOffset(260, 56), Position = UDim2.new(0.5, 0, 0, 112), AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(20, 16, 13), BackgroundTransparency = 0.1, Visible = false, Parent = gui, ZIndex = 4,
	}, { corner(6), stroke(Color3.fromRGB(176, 140, 72), 2) })
	local tLevel = new("TextLabel", { Text = "", Font = BOLD, TextSize = 16, TextColor3 = C.gold, BackgroundColor3 = Color3.fromRGB(40, 30, 20),
		Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(8, 8), Parent = tframe, ZIndex = 5 }, { corner(20), stroke(C.gold, 1.5) })
	local tName = label({ Text = "", Font = BOLD, TextSize = 14, Size = UDim2.new(1, -60, 0, 18), Position = UDim2.fromOffset(56, 6), Parent = tframe, ZIndex = 5 })
	local tBack = new("Frame", { Size = UDim2.new(1, -66, 0, 16), Position = UDim2.fromOffset(56, 28), BackgroundColor3 = Color3.fromRGB(40, 16, 14), Parent = tframe, ZIndex = 5 }, { corner(4) })
	local tFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(60, 200, 60), Parent = tBack, ZIndex = 6 }, { corner(4) })
	local tHp = label({ Text = "", Font = BOLD, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, Size = UDim2.fromScale(1, 1), Parent = tBack, ZIndex = 7 })
	local tSel = Instance.new("Highlight")
	tSel.FillTransparency = 1
	tSel.OutlineColor = C.gold
	tSel.DepthMode = Enum.HighlightDepthMode.Occluded

	local function setTarget(m: Model?)
		target = m
		tframe.Visible = m ~= nil
		tSel.Adornee = m
		tSel.Parent = m and gui or nil
	end
	local function targetOf(inst: Instance?): Model?
		while inst and inst ~= workspace do
			if inst:IsA("Model") and (inst:GetAttribute("EnemyId") or inst:FindFirstChildOfClass("Humanoid")) then
				return inst
			end
			inst = inst.Parent
		end
		return nil
	end
	RunService.RenderStepped:Connect(function()
		if not target then
			return
		end
		if not target.Parent then
			setTarget(nil)
			return
		end
		local hum = target:FindFirstChildOfClass("Humanoid")
		local hp, mx = target:GetAttribute("PV"), target:GetAttribute("PVMax")
		if not hp and hum then
			hp, mx = hum.Health, hum.MaxHealth
		end
		hp, mx = hp or 0, math.max(1, mx or 1)
		local mood = target:GetAttribute("Humeur") or (Players:GetPlayerFromCharacter(target) and "passif" or "neutre")
		-- façon WoW : le métier entre chevrons (« Marthe <Boulangère> »)
		tName.Text = (target:GetAttribute("Nom") or target.Name) .. (target:GetAttribute("Titre") and (" <" .. target:GetAttribute("Titre") .. ">") or "")
		tName.TextColor3 = MOOD_COLOR[mood] or C.text
		-- les créatures ont un niveau (danger) ; les joueurs n'en ont pas
		tLevel.Text = tostring(target:GetAttribute("Niveau") or (Players:GetPlayerFromCharacter(target) and "🧍") or "?")
		tFill.Size = UDim2.fromScale(math.clamp(hp / mx, 0, 1), 1)
		tFill.BackgroundColor3 = hp / mx > 0.5 and Color3.fromRGB(60, 200, 60) or (hp / mx > 0.25 and Color3.fromRGB(230, 190, 40) or Color3.fromRGB(220, 60, 50))
		tHp.Text = math.floor(hp) .. " / " .. math.floor(mx)
		-- trop loin : on lâche la cible
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (target:GetPivot().Position - root.Position).Magnitude > 120 then
			setTarget(nil)
		end
	end)
	local rightStart: Vector2? = nil
	local function selectAt(pos: Vector2)
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local ray = cam:ViewportPointToRay(pos.X, pos.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character }
		local result = workspace:Raycast(ray.Origin, ray.Direction * 150, params)
		setTarget(result and targetOf(result.Instance) or nil)
	end
	cibleApi.selectAt = selectAt
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or building or WindowNav.isOpen() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			rightStart = UserInputService:GetMouseLocation()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			setTarget(nil)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if rightStart and input.UserInputType == Enum.UserInputType.MouseMovement and input.Delta.Magnitude > 2 then
			rightStart = nil
		end
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local start = rightStart
			rightStart = nil
			local pos = UserInputService:GetMouseLocation()
			if start and not processed and not building and not WindowNav.isOpen() and (pos - start).Magnitude <= 5 then
				selectAt(pos)
			end
		end
	end)

	-- ---------------------------------------------------------------- Invites d'action (touche + icône)
	-- Les invites du jeu (ProximityPrompt, style Custom) sont dessinées ici : on comprend à la vue.
	local ACTION_ICON = {
		talk = "💬", crop = "🌾", crystal = "💎", convoy = "📦", chest = "📦", camp_chest = "💰", cave_chest = "💰", cave_enter = "🕳️",
		cave_exit = "⬆️", cave_vein = "⛏️", door = "🚪", mail = "✉️", tame = "🐾", bed = "🛏️", bench = "🛠️", furnace = "🔥", hive = "🍯",
		lockpick = "🔓", mill = "🌾", port = "⛵", practice = "🎯", sprinkler = "💧", stall = "🏪", barracks = "🏰", animal = "🐄",
		animal_lead = "🧵", carry = "🙌", horse = "🐴", pet = "🐾", pickup = "✋",
	}
	ACTION_ICON.animal_lead = "➰"
	local PROP_ICON = { chop = "⚒️", stump = "⚒️", mine = "⛏️", dig = "⛏️", berries = "🍇", open = "📦", pick = "✋" }
	PROP_ICON.berries = "🍇"
	local ProximityPromptService = game:GetService("ProximityPromptService")
	local shown = {}
	local EtatsProches = require(script.Parent:WaitForChild("EtatsProches"))
	EtatsProches.survol(gui, uiScale, player, MOBILE, WindowNav, shown)
	local DIRECTION = { DPadUp = "↑", DPadDown = "↓", DPadLeft = "←", DPadRight = "→" }
	local function keyText(prompt: ProximityPrompt): string
		local input = UserInputService:GetLastInputType()
		if input.Name:match("^Gamepad") then
			local key = prompt.GamepadKeyCode.Name
			return DIRECTION[key] or (key:gsub("^Button", ""))
		elseif input == Enum.UserInputType.Touch or MOBILE then
			return "👆"
		end
		return string.sub(prompt.KeyboardKeyCode.Name, 1, 2)
	end
	UserInputService.LastInputTypeChanged:Connect(function()
		for prompt, entry in shown do
			entry.key.Text = keyText(prompt)
		end
	end)
	ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom or shown[prompt] then
			return
		end
		local action = prompt:GetAttribute("Action")
		local icon = ACTION_ICON[action] or (action == "prop" and PROP_ICON[prompt:GetAttribute("Mode")]) or "✋"
		local bb = new("BillboardGui", { Size = UDim2.fromOffset(150, 46), StudsOffset = Vector3.new(0, 1.2, 0), AlwaysOnTop = true, LightInfluence = 0,
			Adornee = prompt.Parent, Parent = gui, ResetOnSpawn = false })
		local clickable = UserInputService.TouchEnabled
		local box = new(clickable and "TextButton" or "Frame", { Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(20, 16, 13), BackgroundTransparency = 0.15, Parent = bb },
			{ corner(8), stroke(Color3.fromRGB(176, 140, 72), 1.5), pad(4), new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }) })
		if clickable then
			box.Text = ""
			box.Activated:Connect(function()
				if WindowNav.isOpen() then return end
				prompt:InputHoldBegin()
				task.delay(prompt.HoldDuration + 0.05, function()
					prompt:InputHoldEnd()
				end)
			end)
		end
		local key = new("TextLabel", { Text = keyText(prompt), Font = BOLD, TextSize = 16, TextColor3 = Color3.fromRGB(20, 16, 12), BackgroundColor3 = Color3.fromRGB(235, 225, 205),
			Size = UDim2.fromOffset(28, 28), Parent = box }, { corner(6) })
		label({ Text = icon, TextSize = 24, Size = UDim2.fromOffset(30, 30), Parent = box })
		local verb = label({ Text = "", TextSize = 13, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.fromOffset(126, 30), Parent = box })
		-- maintien : la touche se remplit
		local fill = new("Frame", { Size = UDim2.fromScale(1, 0), Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = C.gold,
			BackgroundTransparency = 0.3, Parent = key }, { corner(6) })
		local conns = {}
		table.insert(conns, prompt.PromptButtonHoldBegan:Connect(function()
			TweenService:Create(fill, TweenInfo.new(prompt.HoldDuration), { Size = UDim2.fromScale(1, 1) }):Play()
		end))
		table.insert(conns, prompt.PromptButtonHoldEnded:Connect(function()
			fill.Size = UDim2.fromScale(1, 0)
		end))
		local small = label({ Text = "", TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -4), Parent = bb })
		local model = EtatsProches.lire(prompt.Parent)
		local function majDetail()
			local _, nom, etat = EtatsProches.lire(model)
			local obj = prompt.ObjectText ~= "" and prompt.ObjectText or (nom or "")
			verb.Text = Composants.texteCompatible(prompt.ActionText)
			small.Text = Composants.texteCompatible(etat and (obj ~= "" and (obj .. " · " .. etat) or etat) or obj)
			bb.Size = UDim2.fromOffset(228, etat and 65 or 58)
			box.Position = UDim2.new(0.5, 0, 0, 20)
			small.Position = UDim2.fromOffset(0, 42)
			small.Size = UDim2.new(1, 0, 0, etat and 23 or 16)
		end
		majDetail()
		table.insert(conns, prompt:GetPropertyChangedSignal("ObjectText"):Connect(majDetail))
		table.insert(conns, prompt:GetPropertyChangedSignal("ActionText"):Connect(majDetail))
		if model then table.insert(conns, model.AttributeChanged:Connect(majDetail)) end
		shown[prompt] = { bb = bb, conns = conns, key = key }
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
		local s = shown[prompt]
		if s then
			for _, c in s.conns do
				c:Disconnect()
			end
			s.bb:Destroy()
			shown[prompt] = nil
		end
	end)
	end

	-- ---------------------------------------------------------------- Commandes
	local function ramasserVise(pos: Vector2): boolean
		local cam = workspace.CurrentCamera
		local dossier = workspace:FindFirstChild("ButinAuSol")
		local racine = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not (cam and dossier and racine) then return false end
		local rayon = cam:ViewportPointToRay(pos.X, pos.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { dossier }
		local impact = workspace:Raycast(rayon.Origin, rayon.Direction * 200, params)
		local objet = impact and impact.Instance
		local id = objet and (objet.Position - racine.Position).Magnitude <= 14 and objet:GetAttribute("ButinId")
		if not id then
			-- Tolérance autour du rayon pour les petits objets ramassables à portée.
			local meilleurEcart = 1.6
			for _, part in dossier:GetChildren() do
				local candidat = part:IsA("BasePart") and part:GetAttribute("ButinId")
				if not candidat or (part.Position - racine.Position).Magnitude > 14 then continue end
				local v = part.Position - rayon.Origin
				local profondeur = v:Dot(rayon.Direction)
				local ecart = (v - rayon.Direction * profondeur).Magnitude
				if profondeur > 0 and ecart < meilleurEcart then
					id, meilleurEcart = candidat, ecart
				end
			end
		end
		if not id then return false end
		send("ramasser", { id = id })
		return true
	end

	-- récolte façon Minecraft : un clic sur une touffe « Recoltable » (blé du village…) la cueille
	local function recolteVisee(touch: Vector3?): (string?, string?, Model?, boolean?)
		local cam = workspace.CurrentCamera
		local char = player.Character
		if not cam or not char then
			return nil
		end
		local ray
		if touch then
			ray = cam:ScreenPointToRay(touch.X, touch.Y)
		else
			local at = MOBILE and (cam.ViewportSize / 2) or UserInputService:GetMouseLocation()
			ray = cam:ViewportPointToRay(at.X, at.Y)
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }
		local r = workspace:Raycast(ray.Origin, ray.Direction * 80, params)
		if not r or (r.Position - char:GetPivot().Position).Magnitude >= 14 then
			return nil
		end
		local id = r.Instance:GetAttribute("RecolteId")
		if id then
			return id, nil, r.Instance:FindFirstAncestorOfClass("Model")
		end
		-- objet du monde (arbre, rocher, buisson, caillou…) : on remonte jusqu'à son modèle. Outil en
		-- main ou pas : le serveur choisit la force (et la cadence commune évite le double coup)
		local m = r.Instance:FindFirstAncestorOfClass("Model")
		while m and m ~= workspace do
			local pp = m.PrimaryPart
			local pid = pp and pp:GetAttribute("PropId")
			if pid then
				return nil, pid, m
			end
			-- décor de village (tonneau, foin, puits…) : cassable au clic (Systemes/Demolir)
			if m:GetAttribute("DecoIdx") then
				return nil, nil, m, true
			end
			m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model")
		end
		return nil
	end
	-- barre d'usure au-dessus de ce qu'on frappe (attribut « Usure » 0..1 posé par le serveur)
	local wearBars = {}
	local function showWear(model: Instance?)
		if not model or wearBars[model] then
			if model and wearBars[model] then
				wearBars[model].t = os.clock()
			end
			return
		end
		local adornee = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)) or nil
		if not adornee then
			return
		end
		local _, size = (model :: Model):GetBoundingBox()
		local bb = new("BillboardGui", { Size = UDim2.fromOffset(70, 9), StudsOffsetWorldSpace = Vector3.new(0, math.min(size.Y, 12) * 0.5 + 1.5, 0), AlwaysOnTop = true, Adornee = adornee, Parent = gui })
		local back = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 18, 16), BackgroundTransparency = 0.2, Parent = bb }, { corner(4) })
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(246, 200, 70), Parent = back }, { corner(4) })
		local rec = { bb = bb, t = os.clock() }
		wearBars[model] = rec
		local function upd()
			local u = model:GetAttribute("Usure") or 0
			fill.Size = UDim2.fromScale(math.clamp(u, 0, 1), 1)
			rec.t = os.clock()
		end
		local c = model:GetAttributeChangedSignal("Usure"):Connect(upd)
		upd()
		task.spawn(function()
			while bb.Parent and model.Parent and os.clock() - rec.t < 2.5 do
				task.wait(0.25)
			end
			c:Disconnect()
			bb:Destroy()
			wearBars[model] = nil
		end)
	end
	local function strikeAim(touchPos: Vector3?): boolean
		local rid, pid, m, deco = recolteVisee(touchPos)
		if rid and string.sub(rid, 1, 3) == "fh|" then
			-- herbe haute (partout au sol) : on la fauche ET on donne le coup, pour que le clic
			-- « dans le vide » se voie toujours (geste de l'arme ou du poing, côté serveur)
			send("recolter_clic", { id = rid })
			return false
		elseif rid then
			send("recolter_clic", { id = rid })
		elseif pid then
			send("prop_clic", { id = pid })
		elseif deco and m then
			send("deco_clic", { idx = m:GetAttribute("DecoIdx") })
		else
			return false
		end
		showWear(m)
		return true
	end
	local function hit()
		if building or WindowNav.isOpen() then return end
		local t = cibleApi.get()
		send("hit", { target = t and t:GetAttribute("EnemyId") or nil })
	end
	-- Clic gauche ou toucher : un seul chemin pour le butin, la pose, la récolte ou le coup.
	-- Maintenir répète la récolte.
	-- Le serveur fixe la cadence (un coup / 0,25 s) : cliquer vite ne va pas plus vite.
	local holding = 0
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or WindowNav.isOpen() then
			return
		end
		if input.KeyCode == Enum.KeyCode.ButtonR2 then
			if not building and not strikeAim() then
				hit()
			end
			return
		end
		local touch = input.UserInputType == Enum.UserInputType.Touch
		if input.UserInputType == Enum.UserInputType.MouseButton1 or touch then
			holding += 1
			local me = holding
			local tp = touch and input.Position or nil
			local position = touch and Vector2.new(tp.X, tp.Y) or UserInputService:GetMouseLocation()
			if ramasserVise(position) then return end
			if building then
				if not touch and not MOBILE then placeNow() end
				return
			end
			if touch then cibleApi.selectAt(position) end
			if strikeAim(tp) then
				task.spawn(function()
					task.wait(0.3)
					while holding == me and not building and not WindowNav.isOpen() and (touch or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) do
						if input.UserInputState == Enum.UserInputState.End then
							break
						end
						strikeAim(touch and input.Position or nil)
						task.wait(0.27)
					end
				end)
			elseif not touch or (player.Character and player.Character:FindFirstChildOfClass("Tool")) then
				hit()
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding += 1
		end
	end)
	local crouch = false
	local function toggleCrouch()
		crouch = not crouch
		send("crouch", { on = crouch })
		toast(crouch and "🤫 Accroupi : on te voit moins." or "Debout.", nil)
	end
	-- course : [Maj] tenu (clavier) ou clic du stick gauche (manette, bascule) ; le serveur règle la
	-- vitesse et l'endurance (Game.step)
	local sprintOn = false
	local function setSprint(on: boolean)
		if on ~= sprintOn then
			sprintOn = on
			send("sprint", { on = on })
		end
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.LeftShift and not processed then
			setSprint(true)
		elseif input.KeyCode == Enum.KeyCode.ButtonL3 then
			setSprint(not sprintOn)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			setSprint(false)
		end
	end)
	-- tactile : bouton de course (bascule), au-dessus du bouton de saut
	if MOBILE then
		local runBtn = new("TextButton", { Text = "🏃", TextSize = 26, Font = Enum.Font.GothamBold, Size = UDim2.fromOffset(56, 56),
			Position = UDim2.new(1, -150, 1, -190), BackgroundColor3 = Color3.fromRGB(30, 34, 42), BackgroundTransparency = 0.25,
			TextColor3 = Color3.new(1, 1, 1), Parent = gui, ZIndex = 5 }, { corner(28) })
		runBtn.Activated:Connect(function()
			setSprint(not sprintOn)
			runBtn.BackgroundColor3 = sprintOn and Color3.fromRGB(176, 140, 72) or Color3.fromRGB(30, 34, 42)
		end)
	end
	local function context()
		-- G : lâcher ce qu'on porte / X : descendre de cheval
		if player:GetAttribute("Carrying") then
			send("drop")
		elseif player:GetAttribute("Riding") then
			send("dismount")
		end
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or panels.CharteVille.Visible then
			return
		end
		local k = input.KeyCode
		local HOTKEYS = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5,
			[Enum.KeyCode.Six] = 6, [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9 }
		if HOTKEYS[k] then
			selectSlot(HOTKEYS[k])
		elseif menuKeys[k] and not UserInputService:GetFocusedTextBox() then
			menuKeys[k]()
		elseif k == Enum.KeyCode.V then
			toggleBuild()
		elseif k == Enum.KeyCode.Space and mgState then
			send("mg_press")
		elseif k == Enum.KeyCode.H then
			send("whistle")
		elseif k == Enum.KeyCode.G or (k == Enum.KeyCode.X and not building) then
			context()
		elseif k == Enum.KeyCode.LeftControl then
			toggleCrouch()
		end
	end)

	-- boutons du HUD (colonne de gauche) : branchés maintenant que les panneaux existent
	menuActions.sac, menuActions.perso, menuActions.talents = toggleBag, toggleChar, toggleTalents
	menuActions.clan, menuActions.atelier = toggleClan, toggleCraft

	-- aide clavier (PC) / boutons (mobile)
	if not MOBILE then
		-- aide CONTEXTUELLE (21/11, demande du propriétaire : la rangée fixe de touches était
		-- illisible) : rien n'est affiché tant qu'aucune touche n'est utile ; sinon « touche + mot »
		-- pour ce qui est faisable maintenant. Le clic (action principale) n'a pas besoin d'aide ;
		-- la liste complète des touches est dans Paramètres [O].
		local keys = new("Frame", { Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0.5, 0, 1, -2), AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1, Parent = gui }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), VerticalAlignment = Enum.VerticalAlignment.Center }) })
		local shown = ""
		local function aide(list)
			local sig = table.concat(list, "|")
			if sig == shown then return end
			shown = sig
			for _, c in keys:GetChildren() do
				if c:IsA("GuiObject") then c:Destroy() end
			end
			for i = 1, #list, 2 do
				local f = new("Frame", { Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(24, 19, 15), BackgroundTransparency = 0.25, Parent = keys },
					{ corner(6), new("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 8) }),
						new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }) })
				new("TextLabel", { Text = list[i], Font = BOLD, TextSize = 12, TextColor3 = Color3.fromRGB(20, 16, 12), BackgroundColor3 = Color3.fromRGB(225, 215, 195),
					Size = UDim2.fromOffset(math.max(18, #list[i] * 7 + 8), 18), Parent = f }, { corner(4) })
				label({ Text = list[i + 1], TextSize = 13, Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Parent = f })
			end
		end
		task.spawn(function()
			while gui.Parent do
				local l = {}
				if not building then
					if player:GetAttribute("Riding") then
						table.insert(l, "G") table.insert(l, "Descendre de cheval")
					elseif player:GetAttribute("Carrying") then
						table.insert(l, "G") table.insert(l, "Lâcher")
					end
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					local sol = workspace:FindFirstChild("ButinAuSol")
					if root and sol then
						for _, d in sol:GetChildren() do
							local ok, pos = pcall(function() return d:GetPivot().Position end)
							if ok and (pos - root.Position).Magnitude <= 10 then
								table.insert(l, "Q") table.insert(l, "Tout ramasser")
								break
							end
						end
					end
					if crouch then
						table.insert(l, "Ctrl") table.insert(l, "Se relever")
					end
				end
				aide(l)
				task.wait(0.25)
			end
		end)
	else
		local pad_ = new("Frame", { Size = UDim2.fromOffset(200, 200), Position = UDim2.new(1, -16, 1, -150), AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1, Parent = gui })
		local function round(text: string, x: number, y: number, color: Color3, fn)
			local b = new("TextButton", {
				Text = text, TextSize = 26, Font = BOLD, TextColor3 = C.text, BackgroundColor3 = color, BackgroundTransparency = 0.15,
				Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(x, y), Parent = pad_,
			}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(C.line, 2) })
			b.Activated:Connect(fn)
			return b
		end
		round("👊", 132, 132, C.red, hit)
		round("🤫", 136, 60, C.panel2, toggleCrouch)
		round("🧱", 68, 0, C.panel2, toggleBuild)
		round("🐴", 0, 136, C.panel2, function()
			if player:GetAttribute("Riding") or player:GetAttribute("Carrying") then
				context()
			else
				send("whistle")
			end
		end)
	end
end

-- ================================================================ Démarrage

local mode = workspace:GetAttribute("Mode")
local t0 = os.clock()
while not mode and os.clock() - t0 < 10 do
	task.wait(0.1)
	mode = workspace:GetAttribute("Mode")
end
if mode == "accueil" then
	lobby()
else
	game_()
end
