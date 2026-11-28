-- Cadre commun. Les ornaments sont hors du contenu défilant et ignorent les entrées.
local Theme = require(script.Parent:WaitForChild("ThemeInterface"))
local C, R, T = Theme.couleurs, Theme.rayons, Theme.traits
local Cadre = {}
local habilles = setmetatable({}, { __mode = "k" })

local function trouverTitre(frame)
	local titre
	for _, enfant in frame:GetChildren() do
		if enfant:IsA("TextLabel") and enfant.Position.Y.Scale == 0 and enfant.Position.Y.Offset <= 24
			and (enfant.TextScaled or enfant.TextSize >= 18) then
			if not titre or enfant.Position.Y.Offset < titre.Position.Y.Offset then titre = enfant end
		end
	end
	return titre
end

local function encre(objet)
	local derniere
	local function update()
		if objet.TextColor3 == derniere then return end
		derniere = Theme.encre(objet.TextColor3)
		objet.TextColor3 = derniere
	end
	update()
	objet:GetPropertyChangedSignal("TextColor3"):Connect(update)
end

local function habillerContenu(objet)
	if not objet:IsA("GuiObject") or Theme.estPiece(objet) or habilles[objet] then return end
	habilles[objet] = true
	if objet:IsA("GuiButton") or objet:IsA("TextBox") then Theme.selection(objet) end
	if objet:FindFirstChild("VernisX40") then return end
	if objet:IsA("TextLabel") or objet:IsA("TextButton") or objet:IsA("TextBox") then
		local police = Theme.polices
		local gras = objet:IsA("TextButton") or objet.Font == Enum.Font.GothamBold
		objet.Font = objet.TextSize >= 20 and police.titre or gras and police.gras or police.texte
		objet.TextStrokeTransparency = 1
		encre(objet)
	end
	if objet:IsA("ScrollingFrame") then objet.ScrollBarImageColor3 = C.joint end
	if objet.BackgroundTransparency >= 0.5 then return end
	if objet:IsA("GuiButton") then
		local derniere
		local function update()
			if objet.BackgroundColor3 == derniere then return end
			derniere = Theme.carton(objet.BackgroundColor3)
			if objet:FindFirstChild("VernisX40") then
				objet.BackgroundColor3 = derniere
			elseif not objet:FindFirstChildWhichIsA("UIGridStyleLayout") then
				Theme.bouton(objet, derniere, R.bouton)
			end
		end
		update()
		objet:GetPropertyChangedSignal("BackgroundColor3"):Connect(update)
	elseif objet:IsA("TextBox") then
		objet.PlaceholderColor3 = C.secondaire
		Theme.surface(objet, C.feuillet, R.etiquette, T.case)
	elseif objet:IsA("ScrollingFrame") then
		objet.BackgroundColor3 = Theme.carton(objet.BackgroundColor3)
	elseif (objet:IsA("Frame") or objet:IsA("TextLabel")) and objet:FindFirstChildOfClass("UICorner") then
		local taille = objet.Size.Y
		if objet:IsA("TextLabel") or taille.Scale > 0 or taille.Offset >= 20 then
			Theme.surface(objet, Theme.carton(objet.BackgroundColor3), R.bouton, T.case)
		end
	end
end

function Cadre.habiller(frame: GuiObject, options)
	if not frame or not frame:IsA("GuiObject") or frame:GetAttribute("Cadre") then return end
	frame:SetAttribute("Cadre", true)
	options = options or {}

	-- Le titre et les contrôles restent au-dessus des feuillets.
	local titre = options.titre or trouverTitre(frame)
	local z = frame.ZIndex
	local layout = frame:FindFirstChildWhichIsA("UIGridStyleLayout")
	Theme.surface(frame, C.papier, R.fenetre, T.fenetre)
	frame.BackgroundTransparency = 0
	if not layout then
		-- Les anciens écrans utilisent aussi ZIndex = 1 pour leur contenu.
		local function relever(objet)
			if objet:IsA("GuiObject") and not Theme.estPiece(objet) then
				objet.ZIndex = math.max(z + 1, objet.ZIndex)
			end
		end
		for _, objet in frame:GetChildren() do relever(objet) end
		frame.ChildAdded:Connect(relever)
		local ombre = Theme.piece(frame, "OmbreParchemin", UDim2.new(1, -14, 1, -3), UDim2.fromOffset(7, 6), C.ombre, R.fenetre)
		ombre.ZIndex, ombre.BackgroundTransparency = math.max(1, z - 1), 1
		Theme.bord(ombre, C.ombre, 5).Transparency = 0.72
		local papier = Theme.piece(frame, "Feuillet", UDim2.new(1, -12, 1, -13), UDim2.fromOffset(6, 5), C.feuillet, R.bandeau)
		papier.ZIndex = math.max(1, z - 1)
		Theme.degrade(papier, 94, C.relief, C.feuillet, C.creux)
		local hauteur = titre and math.max(28, titre.Size.Y.Offset) + titre.Position.Y.Offset - 5 or 0
		if hauteur > 0 and not options.sansBandeau then
			local bandeau = Theme.piece(frame, "BandeauMiel", UDim2.new(1, -14, 0, hauteur), UDim2.fromOffset(7, 5), C.miel, R.bandeau)
			bandeau.ZIndex = math.max(1, z - 1)
			Theme.degrade(bandeau, 84, C.papier, C.miel, Color3.fromRGB(217, 154, 87))
			local couture = Theme.piece(bandeau, "JointDuBandeau", UDim2.new(1, -25, 0, 2), UDim2.new(0, 8, 1, -3), C.joint, 2)
			couture.BackgroundTransparency = 0.48
			Theme.piece(bandeau, "RetourDuPapier", UDim2.fromOffset(16, 5), UDim2.new(1, -24, 1, -6), C.relief, 3, -6)
		end
	end

	-- Les menus à contenu dynamique et les fenêtres plus anciennes passent par le même cadre.
	for _, objet in frame:GetDescendants() do habillerContenu(objet) end
	if titre then
		titre.Font, titre.TextColor3 = Theme.polices.titre, C.encre
		titre.TextStrokeTransparency = 1
	end
	frame.DescendantAdded:Connect(function(objet)
		if objet:IsA("GuiObject") then
			task.defer(function()
				if objet:IsDescendantOf(frame) then habillerContenu(objet) end
			end)
		end
	end)
end

function Cadre.infobulle(frame: GuiObject)
	Theme.surface(frame, C.feuillet, R.bandeau, T.bouton)
end

return Cadre
