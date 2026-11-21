local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))

local GroupeHud = {}
local HAUTEUR_LIGNE = 20
local INTERVALLE = 0.25

function GroupeHud.mount(gui, scale, palette, quitter)
	local creer = Composants.creer
	local joueur = Players.LocalPlayer
	local cadre = creer("Frame", {
		Name = "Groupe", Size = UDim2.fromOffset(208, 0), Position = UDim2.fromOffset(14, 90),
		BackgroundColor3 = palette.panel, BackgroundTransparency = 0.25, Visible = false, Parent = gui,
	}, { creer("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	Composants.titre({
		Text = "👥 Groupe (+10 % XP ensemble)", TextSize = 13, TextColor3 = palette.gold,
		Size = UDim2.new(1, -12, 0, 18), Position = UDim2.fromOffset(6, 4), Parent = cadre,
	})
	local liste = creer("ScrollingFrame", {
		Name = "Membres", Size = UDim2.new(1, -12, 0, 0), Position = UDim2.fromOffset(6, 24),
		BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4, ScrollBarImageColor3 = palette.line, VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		Parent = cadre,
	}, { creer("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
	Composants.bouton({
		Text = "Quitter le groupe", TextSize = 12, BackgroundColor3 = palette.red,
		Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0, 6, 1, -32), Parent = cadre,
	}, quitter, { creer("UICorner", { CornerRadius = UDim.new(0, 8) }) })

	local membres = {}
	local nombre = 0
	local function dimensionner()
		local plafond = math.clamp(gui.AbsoluteSize.Y * 0.26 / scale.Scale, HAUTEUR_LIGNE, 180)
		local hauteur = math.min(nombre * HAUTEUR_LIGNE, plafond)
		liste.Size = UDim2.new(1, -12, 0, hauteur)
		cadre.Size = UDim2.fromOffset(208, 60 + hauteur)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(dimensionner)
	scale:GetPropertyChangedSignal("Scale"):Connect(dimensionner)

	local function actualiser()
		local origine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart")
		for id, membre in membres do
			local autre = Players:GetPlayerByUserId(id)
			local personnage = autre and autre.Character
			local racine = personnage and personnage:FindFirstChild("HumanoidRootPart")
			local nom = autre and autre.DisplayName or "Membre indisponible"
			local distance = origine and racine and (racine.Position - origine.Position).Magnitude
		local texteDistance = distance and string.format("%d m", math.floor(distance)) or "—"
		if membre.nom.Text ~= nom then membre.nom.Text = nom end
		if membre.distance.Text ~= texteDistance then membre.distance.Text = texteDistance end
		if membre.surlignage and (not personnage or membre.surlignage.Parent ~= personnage) then
				membre.surlignage:Destroy()
				membre.surlignage = nil
			end
			if personnage and personnage.Parent and not membre.surlignage then
				membre.surlignage = creer("Highlight", {
					Name = "MembreGroupe", FillTransparency = 1, OutlineColor = palette.green,
					DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Parent = personnage,
				})
			end
		end
	end
	local temps = 0
	RunService.Heartbeat:Connect(function(dt)
		if nombre == 0 then return end
		temps += dt
		if temps < INTERVALLE then return end
		temps = 0
		actualiser()
	end)

	return function(ids)
		local presents = {}
		nombre = 0
		for ordre, id in ids do
			if id == joueur.UserId or presents[id] then continue end
			presents[id] = true
			nombre += 1
			local membre = membres[id]
			if not membre then
			local ligne = creer("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, HAUTEUR_LIGNE), Parent = liste,
			})
			local nom = creer("TextLabel", {
				Text = "", BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
				TextColor3 = palette.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				Size = UDim2.new(1, -59, 1, 0), Parent = ligne,
			})
			local distance = creer("TextLabel", {
				Text = "", BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
				TextColor3 = palette.dim, TextXAlignment = Enum.TextXAlignment.Right,
				Size = UDim2.fromOffset(55, HAUTEUR_LIGNE), Position = UDim2.new(1, -55, 0, 0), Parent = ligne,
			})
			membre = { ligne = ligne, nom = nom, distance = distance }
				membres[id] = membre
			end
			membre.ligne.LayoutOrder = ordre
		end
		for id, membre in membres do
			if presents[id] then continue end
			membre.ligne:Destroy()
			if membre.surlignage then membre.surlignage:Destroy() end
			membres[id] = nil
		end
		cadre.Visible = #ids > 0
		if not cadre.Visible then liste.CanvasPosition = Vector2.zero end
		dimensionner()
		actualiser()
	end
end

return GroupeHud
