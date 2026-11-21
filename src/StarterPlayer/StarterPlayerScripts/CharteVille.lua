local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))
local MiseEnPage = require(script.Parent:WaitForChild("MiseEnPage"))
local WindowNav = require(script.Parent:WaitForChild("WindowNav"))

local CharteVille = {}
local BRUN = Color3.fromRGB(46, 33, 25)
local ENCRE = Color3.fromRGB(250, 241, 222)
local ROUGE = Color3.fromRGB(236, 140, 124)

local function arrondi()
	return Composants.creer("UICorner", { CornerRadius = UDim.new(0, 8) })
end

local function nomValide(nom)
	local longueur = utf8.len(nom)
	if not longueur or longueur < 3 or longueur > 24 then return false end
	for _, lettre in utf8.codes(nom) do
		local latine = (lettre >= 65 and lettre <= 90) or (lettre >= 97 and lettre <= 122)
		local accentuee = lettre >= 192 and lettre <= 591 and lettre ~= 215 and lettre ~= 247
		if not (latine or accentuee) then return false end
	end
	return true
end

function CharteVille.mount(gui, scale, envoyer)
	local creer = Composants.creer
	local cover = creer("TextButton", {
		Name = "CharteVille", Size = UDim2.fromScale(1, 1), Text = "", Selectable = false,
		AutoButtonColor = false, BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.58,
		ZIndex = 18, Visible = false, Parent = gui,
	})
	local panel = creer("Frame", {
		Size = UDim2.fromOffset(350, 166), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = BRUN, ZIndex = 19, Parent = cover,
	}, { arrondi() })
	MiseEnPage.bind(panel, scale)
	Composants.titre({
		Text = "Fonder une ville", Size = UDim2.new(1, -60, 0, 32), Position = UDim2.fromOffset(12, 6), Parent = panel,
	})
	local body = creer("ScrollingFrame", {
		Size = UDim2.new(1, -24, 1, -47), Position = UDim2.fromOffset(12, 41),
		CanvasSize = UDim2.fromOffset(0, 113), ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = panel,
	})
	local box = creer("TextBox", {
		Text = "", PlaceholderText = "Nom de la ville (3 à 24 lettres)", ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium, TextSize = 16, TextColor3 = ENCRE, Selectable = true,
		BackgroundColor3 = Color3.fromRGB(28, 22, 18), Size = UDim2.new(1, -5, 0, 36), Parent = body,
	}, { arrondi() })
	local note = creer("TextLabel", {
		Text = "", TextWrapped = true, TextColor3 = ROUGE, Font = Enum.Font.Gotham, TextSize = 12,
		BackgroundTransparency = 1, Size = UDim2.new(1, -5, 0, 31), Position = UDim2.fromOffset(0, 38), Parent = body,
	})
	local function fermer()
		cover.Visible = false
	end
	local function valider()
		if not cover.Visible then return end
		local nom = utf8.nfcnormalize(box.Text:match("^%s*(.-)%s*$") or "")
		if not nomValide(nom) then
			note.Text = Composants.avertissement("Saisis un nom de 3 à 24 lettres.")
			return
		end
		fermer()
		envoyer("ville_fonder", { nom = nom })
	end
	local close = Composants.bouton({
		Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -38, 0, 7),
		TextSize = 18, BackgroundColor3 = Color3.fromRGB(128, 61, 46), Parent = panel,
	}, fermer, { arrondi() })
	local annuler = Composants.bouton({
		Text = "Annuler", TextSize = 15, Size = UDim2.new(0.5, -6, 0, 36), Position = UDim2.fromOffset(0, 73),
		BackgroundColor3 = Color3.fromRGB(83, 60, 45), Parent = body,
	}, fermer, { arrondi() })
	local fonder = Composants.bouton({
		Text = "Fonder", TextSize = 15, Size = UDim2.new(0.5, -6, 0, 36), Position = UDim2.new(0.5, 1, 0, 73),
		BackgroundColor3 = Color3.fromRGB(62, 113, 61), Parent = body,
	}, valider, { arrondi() })
	box.NextSelectionDown, box.NextSelectionUp = fonder, close
	close.NextSelectionDown = box
	fonder.NextSelectionUp, fonder.NextSelectionLeft = box, annuler
	annuler.NextSelectionUp, annuler.NextSelectionRight = box, fonder
	WindowNav.watch(cover, close, fermer, nil, box)
	cover:GetPropertyChangedSignal("Visible"):Connect(function()
		if not cover.Visible then box:ReleaseFocus() end
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function() note.Text = "" end)
	box.FocusLost:Connect(function(enter, input)
		if enter then valider() end
		if input and input.KeyCode == Enum.KeyCode.Escape then fermer() end
	end)
	box.ReturnPressedFromOnScreenKeyboard:Connect(valider)
	return cover, function()
		if cover.Visible then return end
		box.Text, note.Text = "", ""
		body.CanvasPosition = Vector2.zero
		cover.Visible = true
	end
end

return CharteVille
