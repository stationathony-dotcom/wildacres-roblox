-- Cadre médiéval commun à toutes les fenêtres (chantier E1, 25/11, docs/DIRECTION-ARTISTIQUE.md) :
-- fond en dégradé de bois sombre, bordure de fer, liseré doré intérieur, bandeau de titre et quatre coins
-- de fer rivetés. Comme les refontes Valheim (Auga, SeneaL UI) : UN cadre pour toutes les fenêtres.
-- Posé par WindowNav.watch (toutes les fenêtres suivies) ; Cadre.habiller(frame) pour les autres.
-- N'ajoute que des enfants décoratifs (non actifs, ZIndex calculé) ; ne touche ni aux tailles ni aux
-- positions, ni au contenu. Rien n'est ajouté dans un cadre qui range ses enfants lui-même (UIListLayout…).
-- Écrit par Claude (couloir Codex : module neuf, à reprendre librement — voir docs/LOTS.md).

local Cadre = {}

local BOIS_HAUT = Color3.fromRGB(62, 45, 33)
local BOIS_BAS = Color3.fromRGB(36, 26, 20)
local FER = Color3.fromRGB(58, 56, 60)
local FER_CLAIR = Color3.fromRGB(128, 124, 120)
local OR = Color3.fromRGB(214, 168, 78)
local BANDEAU = Color3.fromRGB(30, 21, 16)

local function enfant(class: string, props, parent: Instance)
	local o = Instance.new(class)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

local function zMinMax(frame: GuiObject): (number, number)
	local lo, hi = math.huge, frame.ZIndex
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			lo = math.min(lo, c.ZIndex)
			hi = math.max(hi, c.ZIndex)
		end
	end
	if lo == math.huge then
		lo = frame.ZIndex
	end
	return lo, hi
end

-- titre de la fenêtre : premier texte en haut, assez grand
local function trouverTitre(frame: GuiObject): TextLabel?
	local best
	for _, c in frame:GetChildren() do
		if c:IsA("TextLabel") and c.Position.Y.Scale == 0 and c.Position.Y.Offset <= 24 and c.TextSize >= 18 then
			if not best or c.Position.Y.Offset < best.Position.Y.Offset then
				best = c
			end
		end
	end
	return best
end

local function coin(frame: GuiObject, ax: number, ay: number, z: number)
	local c = enfant("Frame", {
		Name = "CadreCoin", Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(ax, ay),
		Position = UDim2.new(ax, ax == 0 and -3 or 3, ay, ay == 0 and -3 or 3),
		BackgroundColor3 = FER, BorderSizePixel = 0, ZIndex = z, Active = false,
	}, frame)
	enfant("UICorner", { CornerRadius = UDim.new(0, 3) }, c)
	enfant("UIStroke", { Color = Color3.fromRGB(20, 18, 20), Thickness = 1.5 }, c)
	local rivet = enfant("Frame", {
		Name = "Rivet", Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = FER_CLAIR, BorderSizePixel = 0, ZIndex = z, Active = false,
	}, c)
	enfant("UICorner", { CornerRadius = UDim.new(1, 0) }, rivet)
end

-- options : { titre = TextLabel?, sansBandeau = bool, sansCoins = bool }
function Cadre.habiller(frame: GuiObject, options)
	if not frame or not frame:IsA("GuiObject") or frame:GetAttribute("Cadre") then
		return
	end
	frame:SetAttribute("Cadre", true)
	options = options or {}
	-- fond : dégradé de bois (seulement si la fenêtre a un fond plein)
	if frame.BackgroundTransparency < 0.5 and not frame:FindFirstChildOfClass("UIGradient") then
		frame.BackgroundColor3 = Color3.new(1, 1, 1)
		enfant("UIGradient", {
			Name = "CadreBois", Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, BOIS_HAUT),
				ColorSequenceKeypoint.new(0.55, BOIS_HAUT:Lerp(BOIS_BAS, 0.5)),
				ColorSequenceKeypoint.new(1, BOIS_BAS),
			}),
		}, frame)
	end
	-- bordure de fer (on garde l'épaisseur voulue par la fenêtre, au moins 2,5)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = enfant("UIStroke", {}, frame)
	end
	stroke.Color = FER
	stroke.Thickness = math.max(stroke.Thickness, 2.5)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	-- une fenêtre qui range ses enfants elle-même : rien de plus (on casserait sa mise en page)
	if frame:FindFirstChildWhichIsA("UIGridStyleLayout") then
		return
	end
	local lo, hi = zMinMax(frame)
	local corner = frame:FindFirstChildOfClass("UICorner")
	local radius = corner and corner.CornerRadius.Offset or 0
	-- liseré doré à l'intérieur
	local liser = enfant("Frame", {
		Name = "CadreLisere", Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromOffset(5, 5),
		BackgroundTransparency = 1, ZIndex = lo, Active = false,
	}, frame)
	enfant("UIStroke", { Color = OR, Thickness = 1, Transparency = 0.45 }, liser)
	if radius > 0 then
		enfant("UICorner", { CornerRadius = UDim.new(0, math.max(radius - 4, 2)) }, liser)
	end
	-- bandeau de titre
	local titre = options.titre or trouverTitre(frame)
	if titre and not options.sansBandeau then
		local h = math.max(titre.AbsoluteSize.Y, titre.Size.Y.Offset, 28) + titre.Position.Y.Offset + 6
		local band = enfant("Frame", {
			Name = "CadreBandeau", Size = UDim2.new(1, -10, 0, h), Position = UDim2.fromOffset(5, 5),
			BackgroundColor3 = BANDEAU, BackgroundTransparency = 0.25, BorderSizePixel = 0,
			ZIndex = math.max(1, titre.ZIndex - 1), Active = false,
		}, frame)
		if radius > 0 then
			enfant("UICorner", { CornerRadius = UDim.new(0, math.max(radius - 4, 2)) }, band)
		end
		enfant("Frame", {
			Name = "Filet", Size = UDim2.new(1, -24, 0, 2), Position = UDim2.new(0, 12, 1, -2),
			BackgroundColor3 = OR, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = band.ZIndex, Active = false,
		}, band)
		if band.ZIndex >= titre.ZIndex then
			titre.ZIndex = band.ZIndex + 1
		end
		titre.TextStrokeColor3 = Color3.fromRGB(20, 12, 6)
		titre.TextStrokeTransparency = 0.4
	end
	-- coins de fer rivetés
	if not options.sansCoins then
		for _, a in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
			coin(frame, a[1], a[2], hi + 1)
		end
	end
end

-- Infobulle : cadre plus léger (fer + liseré doré, sans bandeau ni coins)
function Cadre.infobulle(frame: GuiObject)
	if not frame or frame:GetAttribute("Cadre") then
		return
	end
	frame:SetAttribute("Cadre", true)
	local stroke = frame:FindFirstChildOfClass("UIStroke") or enfant("UIStroke", {}, frame)
	stroke.Color = FER_CLAIR
	stroke.Thickness = math.max(stroke.Thickness, 1.5)
	if not frame:FindFirstChildWhichIsA("UIGridStyleLayout") then
		local lo = zMinMax(frame)
		local liser = enfant("Frame", {
			Name = "CadreLisere", Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3),
			BackgroundTransparency = 1, ZIndex = lo, Active = false,
		}, frame)
		enfant("UIStroke", { Color = OR, Thickness = 1, Transparency = 0.55 }, liser)
	end
end

return Cadre
