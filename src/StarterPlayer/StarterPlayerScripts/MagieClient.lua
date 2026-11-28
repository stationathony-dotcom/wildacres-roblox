-- Barre des sorts et effets des lancers confirmés par le serveur.
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local C = require(script.Parent:WaitForChild("ComposantsInterface"))
local WindowNav = require(script.Parent:WaitForChild("WindowNav"))
local MiseEnPage = require(script.Parent:WaitForChild("MiseEnPage"))

local Magie = {}
local COLORS = {
	pyro = Color3.fromRGB(255, 129, 43),
	cryo = Color3.fromRGB(157, 222, 255),
	druide = Color3.fromRGB(117, 192, 76),
	aero = Color3.fromRGB(208, 234, 235),
	geo = Color3.fromRGB(158, 155, 151),
}
local GOLD = Color3.fromRGB(239, 199, 116)
local DARK = Color3.fromRGB(46, 35, 29)
local PORTEE_FX = 300
local MAX_FX_DISTANTS = 8
local DUREE_MAX_FX_DISTANT = 1.2

local function effect(name, size, color, cf, life, material)
	local p = C.creer("Part", {
		Name = name, Size = size, Color = color, CFrame = cf,
		Material = material or Enum.Material.Neon, CastShadow = false,
		Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
		Parent = workspace,
	})
	Debris:AddItem(p, life)
	return p
end

local function tween(part, duration, goals)
	TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals):Play()
end

local function jouer(ecole, debut, fin, root)
	local color = COLORS[ecole]
	if not color then return end

	if ecole == "pyro" then
		-- La boule de feu en vol est déjà répliquée par le serveur.
		local ball = effect("Lueur du feu", Vector3.one * 0.68, color, CFrame.new(debut), 0.22)
		ball.Shape = Enum.PartType.Ball
		tween(ball, 0.21, { Size = Vector3.one * 1.65, Transparency = 1 })
		if fin and not root then
			local impact = effect("Éclat de feu", Vector3.one * 0.5, color, CFrame.new(fin), 0.3)
			impact.Shape = Enum.PartType.Ball
			tween(impact, 0.28, { Size = Vector3.one * 1.9, Transparency = 1 })
		end
	elseif ecole == "cryo" then
		local impact = fin or debut
		local distance = (impact - debut).Magnitude
		if distance >= 0.2 then
			local ray = effect("Trait de givre", Vector3.new(0.24, 0.24, distance), color, CFrame.lookAt((debut + impact) / 2, impact), 0.32)
			tween(ray, 0.29, { Transparency = 1, Size = Vector3.new(0.045, 0.045, distance) })
		end
		for i = 1, 7 do
			local angle = i * math.pi * 2 / 7
			local pointe = Vector3.new(math.cos(angle), 0.65, math.sin(angle))
			local crystal = effect("Cristal de givre", Vector3.new(0.17, 0.17, 0.58), color, CFrame.lookAt(impact, impact + pointe), 0.55, Enum.Material.Ice)
			tween(crystal, 0.5, { CFrame = crystal.CFrame + pointe * 1.8, Transparency = 1 })
		end
	elseif ecole == "geo" and not root then
		for i = 1, 6 do
			local angle = i * math.pi / 3
			local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local cf = CFrame.lookAt(debut + radial * 1.3, debut + radial * 2) * CFrame.Angles(0.25, 0, 0)
			local slate = effect("Plaque de schiste", Vector3.new(0.65, 0.9, 0.22), color, cf, DUREE_MAX_FX_DISTANT, Enum.Material.Slate)
			tween(slate, 1.1, { CFrame = cf + ((fin or debut) - debut) + radial * 0.6, Transparency = 1 })
		end
	elseif ecole == "geo" then
		local personnage = root.Parent
		local shell = C.creer("Highlight", {
			Name = "Peau de pierre", Adornee = personnage, FillColor = color, FillTransparency = 0.33,
			OutlineColor = Color3.fromRGB(96, 92, 89), OutlineTransparency = 0.45,
			DepthMode = Enum.HighlightDepthMode.Occluded, Parent = personnage,
		})
		Debris:AddItem(shell, 1.5)
		tween(shell, 1.4, { FillTransparency = 1, OutlineTransparency = 1 })
		for _, name in { "UpperTorso", "LeftUpperArm", "RightUpperArm", "Torso", "Left Arm", "Right Arm" } do
			local limb = personnage:FindFirstChild(name)
			if limb and limb:IsA("BasePart") then
				local slate = effect("Plaque de schiste", limb.Size * 1.04, color, limb.CFrame, 1.2, Enum.Material.Slate)
				slate.Transparency = 0.35
				slate.Anchored = false
				slate.Massless = true
				C.creer("WeldConstraint", { Part0 = limb, Part1 = slate, Parent = slate })
				tween(slate, 1.15, { Transparency = 1 })
			end
		end
	else
		local leaves = ecole == "druide"
		local duration = leaves and 0.82 or 0.57
		local parts = {}
		for i = 1, leaves and 12 or 18 do
			local size = leaves and Vector3.new(0.44, 0.09, 0.23) or Vector3.new(1.25, 0.09, 0.19)
			local tint = leaves and color:Lerp(Color3.fromRGB(204, 219, 124), (i % 3) / 4) or color
			parts[i] = effect(leaves and "Feuille" or "Anneau de vent", size, tint, CFrame.new(debut), duration,
				leaves and Enum.Material.Grass or Enum.Material.ForceField)
		end
		task.spawn(function()
			local start = os.clock()
			while (not root or root.Parent) and os.clock() - start < duration do
				local t = (os.clock() - start) / duration
				local centre = root and root.Position or debut:Lerp(fin or debut, t)
				for i, p in parts do
					local angle = i * math.pi * 2 / #parts + t * (leaves and 5 or 1.3)
					local radius = leaves and (1.3 + 0.9 * t) or (1.5 + 6.5 * t)
					local y = leaves and (-1.5 + 2.8 * t + (i % 4) * 0.32) or -1.0
					p.CFrame = CFrame.new(centre + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius))
						* CFrame.Angles(leaves and angle * 1.4 or 0, -angle - math.pi / 2, leaves and 0.48 or 0)
					p.Transparency = math.clamp(t * 1.3 - 0.3, 0, 1)
				end
				RunService.RenderStepped:Wait()
			end
		end)
	end
end

function Magie.mount(player, gui, scale, remotes, targetOf, canCast)
	local panel = C.creer("Frame", {
		Name = "BarreDesSorts", Size = UDim2.fromOffset(535, 163), Position = UDim2.fromScale(0.5, 0.65),
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(29, 23, 18),
		ZIndex = 20, Visible = false, Parent = gui,
	})
	local function close()
		panel.Visible = false
	end
	local quit = C.bouton({
		Text = "×", TextSize = 20, BackgroundColor3 = Color3.fromRGB(119, 52, 41),
		Size = UDim2.fromOffset(39, 35), Position = UDim2.new(1, -48, 0, 7), ZIndex = 21, Parent = panel,
	}, close)
	C.titre({
		Text = "Sorts", Size = UDim2.new(1, -70, 0, 37), Position = UDim2.fromOffset(15, 5),
		ZIndex = 21, Parent = panel,
	})
	local row = C.creer("Frame", {
		Position = UDim2.fromOffset(14, 44), Size = UDim2.new(1, -28, 0, 75),
		BackgroundTransparency = 1, ZIndex = 21, Parent = panel,
	})
	C.creer("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row,
	})
	local function caption(value, size, pos, parent, ts)
		return C.creer("TextLabel", {
			Text = value, TextSize = ts, TextColor3 = GOLD, Font = Enum.Font.GothamBold, TextWrapped = true,
			BackgroundTransparency = 1, Size = size, Position = pos, ZIndex = 22, Parent = parent,
		})
	end
	local help = caption("", UDim2.new(1, -28, 0, 31), UDim2.fromOffset(14, 122), panel, 13)
	WindowNav.watch(panel, quit, close)
	WindowNav.clavier(panel)
	MiseEnPage.bind(panel, scale)

	local Action = remotes:WaitForChild("Action")
	local spells, buttons = {}, {}
	local waiting, queued, cast
	local stale = true
	local function request()
		waiting = os.clock()
		Action:FireServer("sorts", {})
	end

	local function disponible()
		return canCast() and (not WindowNav.isOpen() or WindowNav.isTop(panel))
	end

	local function lancer(index)
		if not disponible() or UserInputService:GetFocusedTextBox() then return end
		local sp = spells[index]
		if not sp or sp.ready > os.clock() or (cast and os.clock() - cast.time < 1) then return end
		local model = targetOf()
		local id = model and model.Parent and model:GetAttribute("EnemyId") or nil
		local aimed = id and model:GetPivot().Position + Vector3.new(0, 2, 0) or nil
		cast = { ecole = sp.ecole, vise = aimed, time = os.clock() }
		Action:FireServer("sort", { id = sp.id, target = id })
	end

	local function refreshDisplay()
		for index, b in buttons do
			local sp = spells[index]
			local reste = math.max(0, math.ceil(sp.ready - os.clock()))
			b.status.Text = reste > 0 and (reste .. " s") or (sp.cout .. " end.")
			b.button.BackgroundColor3 = reste > 0 and Color3.fromRGB(52, 48, 48) or DARK
		end
		if #spells == 0 then
			help.Text = waiting and "Lecture des sorts…" or "Aucun sort connu."
		elseif UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
			help.Text = "Touche un sort pour le lancer."
		elseif UserInputService:GetLastInputType().Name:match("^Gamepad") then
			help.Text = "Choisir puis A pour lancer"
		else
			help.Text = "Maj droite + 1–5"
		end
	end

	local function render()
		local chosen
		for index, b in buttons do
			if GuiService.SelectedObject == b.button then chosen = index end
			b.button:Destroy()
		end
		table.clear(buttons)
		for index, sp in spells do
			local b = C.bouton({
				Text = "", Size = UDim2.new(0.2, -4, 1, 0), LayoutOrder = index,
				BackgroundColor3 = DARK, Selectable = true, Parent = row, ZIndex = 21,
			}, function() lancer(index) end, { C.creer("UICorner", { CornerRadius = UDim.new(0, 6) }) })
			local title = caption((sp.icon or "") .. " " .. sp.name, UDim2.new(1, -6, 0, 47), UDim2.fromOffset(3, 1), b, 14)
			title.TextColor3 = COLORS[sp.ecole] or GOLD
			local status = caption("", UDim2.new(1, -6, 0, 22), UDim2.fromOffset(3, 48), b, 13)
			buttons[index] = { button = b, status = status }
		end
		if chosen and panel.Visible then GuiService.SelectedObject = buttons[chosen] and buttons[chosen].button or quit end
		refreshDisplay()
	end

	remotes:WaitForChild("Menu").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" or data.kind ~= "sorts" then return end
		spells = data.sorts or {}
		waiting = nil
		stale = false
		local now = os.clock()
		for _, sp in spells do sp.ready = now + (sp.reste or 0) end
		render()
		local shortcut = queued
		queued = nil
		if shortcut and now - shortcut.time < 2 then lancer(shortcut.index) end
	end)

	local fxDistants = 0
	remotes:WaitForChild("Fx").OnClientEvent:Connect(function(kind, data)
		if kind ~= "sort" or type(data) ~= "table" or data.lanceur == player.UserId then return end
		if fxDistants >= MAX_FX_DISTANTS or not COLORS[data.ecole] or typeof(data.de) ~= "Vector3" then return end
		local fin = data.vers
		if fin ~= nil and typeof(fin) ~= "Vector3" then return end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local position = root.Position
		if (data.de - position).Magnitude > PORTEE_FX or (fin and (fin - position).Magnitude > PORTEE_FX) then return end

		fxDistants += 1
		task.delay(DUREE_MAX_FX_DISTANT, function() fxDistants -= 1 end)
		jouer(data.ecole, data.de, fin)
	end)

	player:GetAttributeChangedSignal("Geste"):Connect(function()
		local gesture = player:GetAttribute("Geste")
		if type(gesture) ~= "string" or not gesture:match("^sort:") then return end
		local accepted = cast
		cast = nil
		local personnage = player.Character
		local root = personnage and personnage:FindFirstChild("HumanoidRootPart")
		if root and accepted and os.clock() - accepted.time < 2 then
			local hand = personnage:FindFirstChild("RightHand") or root
			local direction = root.CFrame.LookVector
			local debut = hand.Position + direction * 0.6
			jouer(accepted.ecole, debut, accepted.vise or (debut + direction * 14), root)
		end
		stale = true
		request()
	end)

	task.spawn(function()
		while gui.Parent do
			task.wait(0.2)
			if waiting and os.clock() - waiting > 2 then waiting = nil end
			if panel.Visible then refreshDisplay() end
		end
	end)

	return {
		toggle = function()
			if panel.Visible then close() return end
			request()
			panel.Visible = true
			refreshDisplay()
		end,
		raccourci = function(index)
			if not disponible() then return end
			if not stale then
				lancer(index)
			else
				queued = { index = index, time = os.clock() }
				if not waiting then request() end
			end
		end,
		inventaire = function()
			stale = true
			if panel.Visible and not waiting then request() end
		end,
	}
end

return Magie
