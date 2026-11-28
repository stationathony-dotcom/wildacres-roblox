-- Parchemin, émail et encre des fenêtres et du HUD.
local TweenService = game:GetService("TweenService")
local rgb = Color3.fromRGB
local Theme = {}

Theme.couleurs = table.freeze({
	papier = rgb(255, 241, 207),
	feuillet = rgb(255, 248, 229),
	creux = rgb(232, 211, 175),
	relief = rgb(255, 252, 237),
	joint = rgb(126, 81, 56),
	ombre = rgb(80, 49, 35),
	encre = rgb(59, 37, 26),
	secondaire = rgb(100, 68, 50),
	miel = rgb(255, 201, 112),
	sauge = rgb(190, 222, 159),
	turquoise = rgb(163, 222, 210),
	terreCuite = rgb(244, 174, 146),
	vie = rgb(221, 111, 94),
	endurance = rgb(91, 171, 154),
	focus = rgb(25, 101, 91),
})
Theme.rayons = table.freeze({ fenetre = 22, bandeau = 15, bouton = 13, case = 10, etiquette = 8 })
Theme.traits = table.freeze({ fenetre = 3, bouton = 2, case = 1.5 })
Theme.polices = table.freeze({ titre = Enum.Font.FredokaOne, gras = Enum.Font.FredokaOne, texte = Enum.Font.Nunito })
Theme.raretes = table.freeze({
	table.freeze({ fond = rgb(248, 233, 202), encre = rgb(111, 79, 55) }),
	table.freeze({ fond = rgb(219, 237, 193), encre = rgb(58, 99, 45) }),
	table.freeze({ fond = rgb(202, 232, 245), encre = rgb(38, 84, 119) }),
	table.freeze({ fond = rgb(232, 212, 244), encre = rgb(100, 59, 129) }),
	table.freeze({ fond = rgb(255, 221, 155), encre = rgb(128, 74, 23) }),
})
local C = Theme.couleurs

function Theme.rarete(rang)
	return Theme.raretes[math.clamp(tonumber(rang) or 1, 1, #Theme.raretes)] or Theme.raretes[1]
end

function Theme.encre(couleur: Color3?): Color3
	if not couleur then return C.encre end
	local r, g, b = couleur.R, couleur.G, couleur.B
	local chroma = math.max(r, g, b) - math.min(r, g, b)
	if chroma < 0.14 and math.max(r, g, b) > 0.62 then return C.secondaire end
	local luminance = 0.213 * r + 0.715 * g + 0.072 * b
	if luminance <= 0.37 then return couleur end
	return C.encre:Lerp(couleur, 0.36)
end

-- Conserve la famille de couleur des anciens états de fenêtre.
function Theme.carton(couleur: Color3): Color3
	local r, g, b = couleur.R, couleur.G, couleur.B
	local max = math.max(r, g, b)
	if max > 0.68 and math.min(r, g, b) > 0.52 then return couleur end
	if r > g * 1.52 and r > b * 1.24 and r > 0.44 then return C.terreCuite end
	if r > b * 1.52 and g > b * 1.45 and r > 0.57 then return C.miel end
	if b > r * 1.22 and b > 0.32 then return C.turquoise end
	if g > r * 1.17 and g > b * 1.08 and g > 0.31 then return C.sauge end
	return C.feuillet:Lerp(C.creux, 0.35)
end

function Theme.coin(objet: GuiObject, rayon)
	local coin = objet:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	coin.CornerRadius = typeof(rayon) == "UDim" and rayon or UDim.new(0, rayon)
	coin.Parent = objet
end

function Theme.bord(objet: GuiObject, couleur: Color3, epaisseur: number)
	local trait = objet:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	trait.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trait.Color, trait.Thickness, trait.LineJoinMode = couleur, epaisseur, Enum.LineJoinMode.Round
	trait.Parent = objet
	return trait
end

function Theme.degrade(objet: GuiObject, rotation: number, clair: Color3, milieu: Color3, sombre: Color3)
	local gradient = objet:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, clair),
		ColorSequenceKeypoint.new(0.57, milieu),
		ColorSequenceKeypoint.new(1, sombre),
	})
	gradient.Parent = objet
	return gradient
end

function Theme.surface(objet: GuiObject, fond: Color3, rayon, epaisseur: number, joint: Color3?)
	objet.BackgroundColor3, objet.BorderSizePixel = fond, 0
	Theme.coin(objet, rayon)
	Theme.bord(objet, joint or C.joint, epaisseur)
	local vernis = Theme.degrade(objet, 85, Color3.new(1, 1, 1), rgb(253, 246, 231), rgb(224, 193, 165))
	vernis.Name = "VernisX40"
	return vernis
end

local pieces = setmetatable({}, { __mode = "k" })
function Theme.estPiece(objet)
	return pieces[objet] == true
end

function Theme.piece(parent: GuiObject, nom: string, taille: UDim2, position: UDim2, couleur: Color3, rayon, rotation: number?)
	local piece = Instance.new("Frame")
	piece.Name, piece.Size, piece.Position = nom, taille, position
	piece.BackgroundColor3, piece.BorderSizePixel = couleur, 0
	piece.Active, piece.Selectable, piece.Interactable = false, false, false
	piece.ZIndex, piece.Rotation = parent.ZIndex, rotation or 0
	pieces[piece] = true
	Theme.coin(piece, rayon)
	piece.Parent = parent
	return piece
end

local selection = Instance.new("Frame")
selection.Name = "ContourSelection"
selection.Size, selection.Position = UDim2.new(1, -2, 1, -2), UDim2.fromOffset(1, 1)
selection.BackgroundTransparency, selection.BorderSizePixel, selection.Interactable = 1, 0, false
Theme.coin(selection, Theme.rayons.case)
Theme.bord(selection, C.focus, 3)

function Theme.selection(objet: GuiObject)
	if not objet.SelectionImageObject then objet.SelectionImageObject = selection end
end

local mobiles = setmetatable({}, { __mode = "k" })

-- Le vernis bouge à l'intérieur du bouton. Son rectangle de sélection reste fixe.
function Theme.bouton(bouton: GuiButton, fond: Color3, rayon, joint: Color3?, leger: boolean?)
	local gradient = Theme.surface(bouton, fond, rayon, Theme.traits.bouton, joint)
	bouton.AutoButtonColor = false
	Theme.selection(bouton)
	if mobiles[bouton] then return end
	mobiles[bouton] = true
	local eclat
	if not leger then
		eclat = Theme.piece(bouton, "EclatEmail", UDim2.new(0.31, 0, 0, 3), UDim2.new(0.11, 0, 0, 3), C.relief, 3, -3)
		eclat.BackgroundTransparency = 0.35
	end
	local tween, eclatTween
	local survol, selectionne = false, false
	local function anime(offset, duree, ressort)
		if not bouton.Parent then return end
		if tween then tween:Cancel() end
		local info = TweenInfo.new(duree, ressort and Enum.EasingStyle.Back or Enum.EasingStyle.Quad)
		tween = TweenService:Create(gradient, info, { Offset = Vector2.new(0, offset) })
		tween:Play()
		if eclat then
			if eclatTween then eclatTween:Cancel() end
			eclatTween = TweenService:Create(eclat, info, { Position = UDim2.new(0.11, 0, 0, 3 - offset * 10) })
			eclatTween:Play()
		end
	end
	local function releve()
		anime((survol or selectionne) and 0.15 or 0, 0.17, true)
	end
	bouton.MouseEnter:Connect(function() survol = true; releve() end)
	bouton.MouseLeave:Connect(function() survol = false; releve() end)
	bouton.SelectionGained:Connect(function() selectionne = true; releve() end)
	bouton.SelectionLost:Connect(function() selectionne = false; releve() end)
	bouton.InputBegan:Connect(function(input)
		local typeEntree = input.UserInputType
		if bouton.Interactable and (typeEntree == Enum.UserInputType.Touch or typeEntree == Enum.UserInputType.MouseButton1) then
			anime(-0.2, 0.07, false)
		end
	end)
	bouton.InputEnded:Connect(function(input)
		local typeEntree = input.UserInputType
		if typeEntree == Enum.UserInputType.Touch or typeEntree == Enum.UserInputType.MouseButton1 then releve() end
	end)
	bouton.Activated:Connect(function()
		anime(-0.16, 0.06, false)
		task.delay(0.065, releve)
	end)
end

return Theme
