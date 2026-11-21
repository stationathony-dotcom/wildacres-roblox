-- Catalogue du joueur et rendu commun au personnage et à son aperçu.
local Apparence = {}

local function weld(model: Instance, anchor: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, mat: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = anchor.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = anchor
	w.Part1 = p
	w.Parent = p
	p.Parent = model
	return p
end

local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local rgb = Color3.fromRGB

-- Les indices publiés de ces quatre palettes sont figés pour les sauvegardes.
-- Le catalogue des PNJ reste dans WorldGen.
Apparence.SKINS = {
	rgb(255, 220, 190), rgb(234, 184, 146), rgb(190, 132, 96), rgb(120, 80, 56),
	rgb(250, 233, 215), rgb(218, 166, 118), rgb(162, 109, 77), rgb(85, 55, 41),
	rgb(108, 69, 52), rgb(65, 42, 35),
}
Apparence.HAIR_COLORS = {
	rgb(60, 40, 30), rgb(140, 90, 50), rgb(230, 200, 120), rgb(180, 70, 40), rgb(200, 200, 200), rgb(30, 30, 34),
	rgb(237, 233, 218), rgb(28, 36, 54), rgb(112, 112, 118), rgb(151, 57, 41), rgb(216, 119, 66), rgb(189, 157, 105),
}
Apparence.SHIRTS = {
	rgb(200, 70, 60), rgb(70, 120, 190), rgb(90, 150, 80), rgb(230, 190, 80),
	rgb(150, 90, 170), rgb(240, 240, 230), rgb(110, 80, 60), rgb(230, 130, 160),
	rgb(230, 236, 240), rgb(40, 60, 100), rgb(150, 150, 160), rgb(226, 200, 150), rgb(196, 120, 50),
	rgb(40, 140, 140), rgb(80, 100, 60), rgb(60, 80, 70), rgb(120, 110, 70), rgb(200, 90, 40),
	rgb(150, 60, 40), rgb(60, 90, 50), rgb(70, 50, 40), rgb(40, 36, 34), rgb(250, 200, 210),
	rgb(200, 230, 150), rgb(255, 220, 120),
	rgb(112, 42, 58), rgb(110, 138, 158), rgb(173, 110, 102), rgb(65, 91, 110), rgb(106, 96, 127),
}
Apparence.PANTS = {
	rgb(70, 60, 50), rgb(50, 70, 110), rgb(110, 90, 60), rgb(60, 60, 60), rgb(140, 120, 90),
	rgb(220, 224, 230), rgb(190, 160, 110), rgb(70, 80, 60), rgb(40, 36, 34),
	rgb(97, 57, 48), rgb(101, 109, 120), rgb(93, 65, 91), rgb(60, 94, 97), rgb(155, 90, 62),
	rgb(173, 157, 132), rgb(51, 66, 50),
}
Apparence.EYE_COLORS = {
	rgb(28, 24, 22), rgb(139, 88, 46), rgb(73, 136, 175), rgb(101, 137, 82),
	rgb(175, 122, 51), rgb(124, 133, 145),
}

-- L’ordre sert à la fiche. Les clés textuelles sont celles des sauvegardes.
Apparence.FIELDS = {
	{ key = "skin", label = "Teint", colors = Apparence.SKINS,
		names = { "Pêche", "Beige", "Cuivré", "Brun", "Porcelaine", "Doré", "Châtain", "Brun profond", "Acajou", "Ébène" } },
	{ key = "hair", label = "Coiffure", choices = {
		{ "court", "Court" }, { "herisse", "Hérissé" }, { "chauve", "Dégarni" }, { "barbe", "Court plein" },
		{ "long", "Long" }, { "chignon", "Chignon" }, { "tresses", "Deux tresses de dos" }, { "carre", "Carré" },
		{ "rase", "Crâne rasé" }, { "meche", "Mèche de côté" }, { "queue", "Queue de cheval" },
		{ "nattes", "Nattes d’épaule" }, { "couronne", "Couronne de tresses" }, { "long_raie", "Long à raie" },
		{ "demi_queue", "Demi-queue" }, { "bol", "Coupe au bol" }, { "boucles", "Boucles courtes" },
		{ "tresse_longue", "Tresse de dos" }, { "crete", "Crête" },
	} },
	{ key = "hairColor", label = "Teinte des cheveux", colors = Apparence.HAIR_COLORS,
		names = { "Brun", "Châtain", "Blond", "Roux", "Argent", "Noir", "Blanc", "Noir bleuté", "Gris", "Auburn", "Cuivre", "Blond cendré" } },
	{ key = "eyes", label = "Forme des yeux", choices = {
		{ "droits", "Droits" }, { "ronds", "Ronds" }, { "fins", "Fins" }, { "amande", "En amande" },
	} },
	{ key = "eyeColor", label = "Couleur des yeux", colors = Apparence.EYE_COLORS,
		names = { "Très foncé", "Noisette", "Bleu", "Vert", "Ambre", "Gris" } },
	{ key = "brows", label = "Sourcils", choices = {
		{ "naturels", "Naturels" }, { "epais", "Épais" }, { "arques", "Arqués" }, { "plats", "Droits" }, { "fins", "Fins" },
	} },
	{ key = "mouth", label = "Bouche", choices = {
		{ "sourire", "Sourire discret" }, { "neutre", "Neutre" }, { "large", "Sourire large" },
		{ "ferme", "Sérieuse" }, { "coin", "En coin" },
	} },
	{ key = "beard", label = "Barbe", choices = {
		{ "aucune", "Rasée" }, { "carree", "Carrée" }, { "courte", "Courte" }, { "bouc", "Bouc" },
		{ "longue", "Longue" }, { "tressee", "Tressée" },
	} },
	{ key = "mustache", label = "Moustache", choices = {
		{ "aucune", "Rasée" }, { "droite", "Droite" }, { "fine", "Fine" }, { "guidon", "Relevée" }, { "tombante", "Tombante" },
	} },
	{ key = "marks", label = "Marques du visage", choices = {
		{ "aucune", "Aucune" }, { "rousseur", "Taches de rousseur" }, { "joue", "Cicatrice à la joue" },
		{ "arcade", "Cicatrice à l’arcade" }, { "rousseur_joue", "Rousseur et cicatrice" },
	} },
	{ key = "shirt", label = "Couleur de tunique", colors = Apparence.SHIRTS,
		names = { "Rouge", "Bleu", "Vert", "Or", "Mauve", "Écru", "Brun", "Rose vif", "Givre", "Nuit",
			"Gris loup", "Sable", "Ocre", "Turquoise", "Mousse", "Vase", "Roseau", "Rouille", "Brique", "Sapin",
			"Cuir", "Suie", "Rose pâle", "Pomme", "Miel", "Lie-de-vin", "Ardoise claire", "Terre cuite", "Bleu ardoise", "Prune" } },
	{ key = "shirtCut", label = "Coupe de tunique", choices = {
		{ "simple", "Simple" }, { "longue", "Tunique longue" }, { "tablier", "Tablier" },
		{ "ceinture", "Tunique ceinturée" }, { "col", "Col lacé" },
	} },
	{ key = "pants", label = "Couleur des chausses", colors = Apparence.PANTS,
		names = { "Brun", "Bleu", "Cuir", "Gris", "Taupe", "Blanc", "Sable", "Kaki", "Suie",
			"Châtaigne", "Ardoise", "Prune", "Sarcelle", "Rouille", "Lin", "Sapin" } },
	{ key = "pantsCut", label = "Coupe des chausses", choices = {
		{ "simple", "Simples" }, { "guetres", "Guêtres nouées" }, { "revers", "À revers" }, { "renforts", "Avec genouillères" },
	} },
}

local allowed = {}
Apparence.HAIR_LIST = {}
for _, field in Apparence.FIELDS do
	local values = {}
	if field.colors then
		for index in field.colors do values[index] = true end
	else
		for _, choice in field.choices do values[choice[1]] = true end
	end
	allowed[field.key] = values
	if field.key == "hair" then
		for _, choice in field.choices do table.insert(Apparence.HAIR_LIST, choice[1]) end
	end
end

function Apparence.validValue(key, value)
	local kind = type(value)
	return (kind == "string" or kind == "number") and value == value and allowed[key][value] == true
end

-- L’ancienne coupe « barbe » incluait ces deux traits. Une sélection explicite les remplace.
function Apparence.normalize(look)
	look = look or {}
	local result = {}
	for _, field in Apparence.FIELDS do
		local key = field.key
		local default = field.colors and 1 or field.choices[1][1]
		if look.hair == "barbe" then
			if key == "beard" then default = "carree" end
			if key == "mustache" then default = "droite" end
		end
		result[key] = Apparence.validValue(key, look[key]) and look[key] or default
	end
	return result
end

local RUBAN = rgb(132, 64, 49)
local NOIR = rgb(26, 23, 21)
local function calotte(m, h, c, dos)
	weld(m, h, "Calotte", V(1.22, 0.31, 1.23), C(0, 0.50, 0.02), c)
	weld(m, h, "Nuque", V(1.19, dos, 0.29), C(0, 0.48 - dos / 2, 0.51), c)
end

local function natte(m, h, c, x, y, z, segments, lean)
	for index = 0, segments - 1 do
		local side = index % 2 == 0 and -1 or 1
		local width = 0.32 - index * 0.016
		local color = side > 0 and c:Lerp(NOIR, 0.16) or c
		weld(m, h, "Tresse", V(width, 0.31, width), C(x + lean * index + side * 0.036, y - index * 0.20, z)
			* A(0, 0, side * 0.30), color)
	end
	weld(m, h, "Lien", V(0.21, 0.11, 0.23), C(x + lean * (segments - 1), y - segments * 0.20 + 0.08, z), RUBAN)
end

-- Coiffures (tête R15 ≈ 1,16 x 1,18 x 1,16 ; l'avant de la tête regarde vers -Z)
local HAIRS = {
	court = function(m, h, c)
		weld(m, h, "Cheveux", V(1.24, 0.34, 1.24), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.24, 0.7, 0.3), C(0, 0.22, 0.5), c)
	end,
	herisse = function(m, h, c)
		weld(m, h, "Cheveux", V(1.22, 0.3, 1.22), C(0, 0.5, 0.02), c)
		for i = -1, 1 do
			weld(m, h, "Meche", V(0.28, 0.35, 0.28), C(i * 0.36, 0.78, -0.1 + math.abs(i) * 0.15) * CFrame.Angles(0, 0, -i * 0.3), c)
		end
	end,
	chauve = function(m, h, c)
		weld(m, h, "Cheveux", V(0.2, 0.45, 0.7), C(-0.6, 0.05, 0.15), c)
		weld(m, h, "Cheveux", V(0.2, 0.45, 0.7), C(0.6, 0.05, 0.15), c)
	end,
	barbe = function(m, h, c, playerHair)
		weld(m, h, "Cheveux", V(1.24, 0.32, 1.24), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.24, 0.6, 0.3), C(0, 0.25, 0.5), c)
		if not playerHair then
			weld(m, h, "Barbe", V(0.95, 0.42, 0.22), C(0, -0.42, -0.55), c)
			weld(m, h, "Moustache", V(0.6, 0.12, 0.08), C(0, -0.17, -0.6), c)
		end
	end,
	long = function(m, h, c)
		weld(m, h, "Cheveux", V(1.26, 0.34, 1.26), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.28, 1.7, 0.36), C(0, -0.2, 0.52), c)
		weld(m, h, "Meche", V(0.22, 1.2, 0.5), C(-0.62, -0.05, 0.1), c)
		weld(m, h, "Meche", V(0.22, 1.2, 0.5), C(0.62, -0.05, 0.1), c)
	end,
	chignon = function(m, h, c)
		weld(m, h, "Cheveux", V(1.26, 0.34, 1.26), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.26, 0.8, 0.3), C(0, 0.2, 0.52), c)
		weld(m, h, "Chignon", V(0.6, 0.6, 0.6), C(0, 0.55, 0.72), c)
	end,
	tresses = function(m, h, c)
		weld(m, h, "Cheveux", V(1.26, 0.34, 1.26), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.26, 0.8, 0.3), C(0, 0.2, 0.52), c)
		weld(m, h, "Tresse", V(0.26, 1.5, 0.26), C(-0.5, -0.55, 0.45), c)
		weld(m, h, "Tresse", V(0.26, 1.5, 0.26), C(0.5, -0.55, 0.45), c)
		weld(m, h, "Ruban", V(0.32, 0.16, 0.32), C(-0.5, -1.25, 0.45), Color3.fromRGB(220, 70, 90))
		weld(m, h, "Ruban", V(0.32, 0.16, 0.32), C(0.5, -1.25, 0.45), Color3.fromRGB(220, 70, 90))
	end,
	carre = function(m, h, c)
		weld(m, h, "Cheveux", V(1.28, 0.36, 1.28), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.3, 1, 0.32), C(0, 0.1, 0.52), c)
		weld(m, h, "Meche", V(0.22, 0.9, 0.9), C(-0.63, 0.1, 0.12), c)
		weld(m, h, "Meche", V(0.22, 0.9, 0.9), C(0.63, 0.1, 0.12), c)
		weld(m, h, "Frange", V(1.2, 0.2, 0.15), C(0, 0.38, -0.6), c)
	end,
	rase = function() end,
	meche = function(m, h, c)
		calotte(m, h, c, 0.51)
		weld(m, h, "Raie", V(0.40, 0.19, 0.97), C(-0.39, 0.46, -0.04), c:Lerp(NOIR, 0.18))
		weld(m, h, "Meche", V(0.88, 0.24, 0.23), C(0.16, 0.42, -0.58) * A(0, 0, -0.35), c)
		weld(m, h, "Pointe", V(0.24, 0.35, 0.19), C(0.52, 0.24, -0.54) * A(0, 0, 0.31), c)
	end,
	queue = function(m, h, c)
		calotte(m, h, c, 0.74)
		weld(m, h, "Lien", V(0.38, 0.30, 0.27), C(0, 0.28, 0.73), RUBAN)
		weld(m, h, "Queue", V(0.43, 0.72, 0.38), C(0, -0.03, 0.88) * A(-0.39, 0, 0), c)
		weld(m, h, "Pointe", V(0.31, 0.86, 0.29), C(0, -0.74, 1.02) * A(0.17, 0, 0.06), c)
	end,
	nattes = function(m, h, c)
		calotte(m, h, c, 0.74)
		for _, side in { -1, 1 } do
			weld(m, h, "Tempe", V(0.23, 0.86, 0.68), C(side * 0.59, 0.14, 0.11), c)
			natte(m, h, c, side * 0.61, -0.18, -0.34, 6, side * 0.025)
		end
	end,
	couronne = function(m, h, c)
		calotte(m, h, c, 0.68)
		for index = 0, 11 do
			local angle = index * math.pi / 6
			local side = index % 2 == 0 and 1 or -1
			weld(m, h, "CouronneTressee", V(0.39, 0.24, 0.24), C(math.sin(angle) * 0.60, 0.49 + side * 0.045, -math.cos(angle) * 0.60)
				* A(0, -angle, side * 0.33), side > 0 and c or c:Lerp(NOIR, 0.18))
		end
	end,
	long_raie = function(m, h, c)
		calotte(m, h, c, 1.47)
		for _, side in { -1, 1 } do
			weld(m, h, "Raie", V(0.52, 0.18, 0.65), C(side * 0.30, 0.57, -0.30) * A(0, 0, -side * 0.16), c)
			weld(m, h, "Meche", V(0.27, 1.27, 0.52), C(side * 0.61, -0.12, -0.22) * A(0, 0, side * 0.09), c)
			weld(m, h, "Pointe", V(0.22, 0.62, 0.42), C(side * 0.68, -1.00, -0.24) * A(0, 0, -side * 0.15), c)
		end
	end,
	demi_queue = function(m, h, c)
		calotte(m, h, c, 1.15)
		for _, side in { -1, 1 } do
			weld(m, h, "Meche", V(0.21, 0.92, 0.62), C(side * 0.56, 0.13, 0.30) * A(-0.48, 0, 0), c)
		end
		weld(m, h, "Lien", V(0.34, 0.17, 0.23), C(0, 0.38, 0.75), RUBAN)
		weld(m, h, "Queue", V(0.35, 0.87, 0.28), C(0, -0.08, 0.79) * A(-0.16, 0, 0), c)
	end,
	bol = function(m, h, c)
		calotte(m, h, c, 0.67)
		weld(m, h, "Frange", V(1.16, 0.29, 0.19), C(0, 0.35, -0.54), c)
		for _, side in { -1, 1 } do
			weld(m, h, "Tempe", V(0.21, 0.37, 0.97), C(side * 0.53, 0.28, 0.02), c)
		end
	end,
	boucles = function(m, h, c)
		calotte(m, h, c, 0.52)
		for index = 0, 7 do
			local angle = index * math.pi / 4
			local side = index % 2 == 0 and -1 or 1
			weld(m, h, "Boucle", V(0.43, 0.43, 0.41), C(math.sin(angle) * 0.46, 0.61 + side * 0.07, math.cos(angle) * 0.46)
				* A(0.16, angle, side * 0.26), side > 0 and c or c:Lerp(NOIR, 0.16))
		end
	end,
	tresse_longue = function(m, h, c)
		calotte(m, h, c, 0.69)
		natte(m, h, c, 0, 0.18, 0.72, 9, 0.012)
	end,
	crete = function(m, h, c)
		weld(m, h, "Dessus", V(0.68, 0.18, 1.05), C(0, 0.52, 0.01), c)
		for index = 0, 3 do
			local height = 0.62 - 0.11 * index
			weld(m, h, "Crete", V(0.37, height, 0.35), C(0, 0.52 + height / 2, -0.40 + index * 0.27)
				* A(-0.24, 0, 0), c)
		end
	end,
}
Apparence.HAIRS = HAIRS
Apparence.SKIN_PARTS = { "Head", "LeftHand", "RightHand" }
Apparence.SHIRT_PARTS = { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }
Apparence.PANTS_PARTS = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }
Apparence.FEET = { "LeftFoot", "RightFoot" }

local function clearLayer(model, name)
	local layer = model:FindFirstChild(name)
	if layer then layer:Destroy() end
end

local function newLayer(name)
	local layer = Instance.new("Model")
	layer.Name = name
	return layer
end

-- Largeur, hauteur et inclinaison du contour de l’œil et du sourcil.
local EYES = {
	droits = { 0.13, 0.18, 0 }, ronds = { 0.20, 0.22, 0 },
	fins = { 0.23, 0.09, 0 }, amande = { 0.22, 0.135, 0.24 },
}
local BROWS = {
	naturels = { 0.22, 0.05, -0.12 }, epais = { 0.27, 0.085, -0.14 },
	arques = { 0.16, 0.048, -0.34 }, plats = { 0.23, 0.05, 0 }, fins = { 0.21, 0.03, 0.20 },
}
local MOUTHS = {
	sourire = { { 0.28, 0.05, 0, -0.22 }, { 0.06, 0.05, -0.16, -0.19 }, { 0.06, 0.05, 0.16, -0.19 } },
	neutre = { { 0.24, 0.047, 0, -0.22 } },
	large = { { 0.37, 0.085, 0, -0.22 }, { 0.08, 0.055, -0.20, -0.18, -0.42 }, { 0.08, 0.055, 0.20, -0.18, 0.42 } },
	ferme = { { 0.22, 0.06, 0, -0.20 }, { 0.08, 0.04, -0.14, -0.23, 0.32 }, { 0.08, 0.04, 0.14, -0.23, -0.32 } },
	coin = { { 0.31, 0.05, 0, -0.22, 0.14 }, { 0.08, 0.05, 0.17, -0.17, 0.42 } },
}

local function facialHair(v, head, look, hair, z, hideLegacyBeard, hideLegacyMustache)
	local beard = hideLegacyBeard and "aucune" or look.beard
	if beard == "carree" then
		weld(v, head, "Barbe", V(0.95, 0.42, 0.22), C(0, -0.42, -0.55), hair)
	elseif beard ~= "aucune" then
		local width = (beard == "courte" or beard == "longue") and 0.82 or 0.34
		weld(v, head, "Barbe", V(width, 0.20, 0.19), C(0, -0.45, z + 0.07), hair)
		if beard == "courte" or beard == "longue" then
			for _, side in { -1, 1 } do
				weld(v, head, "Favori", V(0.18, 0.47, 0.18), C(side * 0.42, -0.31, z + 0.09) * A(0, 0, side * 0.20), hair)
			end
		end
		if beard == "longue" or beard == "bouc" then
			local long = beard == "longue"
			weld(v, head, "Pointe", V(long and 0.54 or 0.25, long and 0.54 or 0.27, 0.19),
				C(0, long and -0.76 or -0.57, z + 0.07), hair:Lerp(NOIR, 0.14))
		elseif beard == "tressee" then
			natte(v, head, hair, 0, -0.55, z + 0.03, 3, 0)
		end
	end

	local mustache = hideLegacyMustache and "aucune" or look.mustache
	if mustache == "droite" then
		weld(v, head, "Moustache", V(0.6, 0.12, 0.08), C(0, -0.17, -0.6), hair)
	elseif mustache ~= "aucune" then
		for _, side in { -1, 1 } do
			local angle = ({ fine = -0.18, guidon = 0.30, tombante = -0.54 })[mustache]
			weld(v, head, "Moustache", V(0.32, mustache == "fine" and 0.046 or 0.095, 0.07),
				C(side * 0.16, -0.12, z - 0.025) * A(0, 0, side * angle), hair)
			if mustache == "guidon" then
				weld(v, head, "Pointe", V(0.10, 0.11, 0.07), C(side * 0.32, -0.043, z - 0.02) * A(0, 0, side * 0.25), hair)
			end
		end
	end
end

-- La tête R15 regarde vers -Z. Les pièces fines sont soudées au même membre que la coiffure.
function Apparence.visage(head, look, hideLegacyBeard, hideLegacyMustache)
	local model = head.Parent
	clearLayer(model, "Visage_WA")
	local v = newLayer("Visage_WA")
	local z = -head.Size.Z / 2 - 0.02
	local hair = Apparence.HAIR_COLORS[look.hairColor]
	local iris = Apparence.EYE_COLORS[look.eyeColor]
	local eye, brow = EYES[look.eyes], BROWS[look.brows]
	for _, side in { -1, 1 } do
		local x = side * 0.20
		local angle = A(0, 0, side * eye[3])
		local base = C(x, 0.07, z)
		if look.eyes == "droits" and look.eyeColor == 1 then
			weld(v, head, "Oeil", V(0.13, 0.18, 0.06), base, iris)
			weld(v, head, "Reflet", V(0.05, 0.05, 0.02), C(x + 0.03, 0.12, z - 0.03), rgb(240, 236, 230))
		else
			weld(v, head, "Oeil", V(eye[1], eye[2], 0.05), base * angle, rgb(224, 215, 202))
			weld(v, head, "Iris", V(math.min(0.105, eye[1] * 0.80), eye[2] * 0.85, 0.027), base * C(0, 0, -0.028), iris)
			weld(v, head, "Pupille", V(0.033, eye[2] * 0.52, 0.014), base * C(0, 0, -0.04), NOIR)
			weld(v, head, "Reflet", V(0.026, 0.026, 0.012), base * C(0.023, eye[2] * 0.22, -0.048), rgb(240, 236, 230))
		end
		weld(v, head, "Sourcil", V(brow[1], brow[2], 0.05), C(x, 0.24, z) * A(0, 0, side * brow[3]), hair)
		if look.brows == "arques" then
			weld(v, head, "Sourcil", V(0.12, 0.04, 0.05), C(x - side * 0.102, 0.225, z) * A(0, 0, side * 0.32), hair)
		end
	end
	for _, mouth in MOUTHS[look.mouth] do
		weld(v, head, "Bouche", V(mouth[1], mouth[2], 0.05), C(mouth[3], mouth[4], z) * A(0, 0, mouth[5] or 0), rgb(110, 46, 40))
	end
	if look.mouth == "large" then
		weld(v, head, "Dents", V(0.27, 0.03, 0.02), C(0, -0.207, z - 0.025), rgb(226, 215, 191))
	end
	if look.marks == "rousseur" or look.marks == "rousseur_joue" then
		local freckle = head.Color:Lerp(rgb(101, 53, 36), 0.55)
		for _, side in { -1, 1 } do
			for index, y in { -0.04, -0.085, -0.057 } do
				weld(v, head, "Rousseur", V(0.034, 0.034, 0.014), C(side * (0.145 + index * 0.071), y, z + 0.003), freckle)
			end
		end
	end
	local scar = head.Color:Lerp(rgb(177, 92, 83), 0.50)
	if look.marks == "joue" or look.marks == "rousseur_joue" then
		weld(v, head, "Cicatrice", V(0.033, 0.25, 0.020), C(-0.40, -0.16, z) * A(0, 0, -0.66), scar)
	elseif look.marks == "arcade" then
		weld(v, head, "Cicatrice", V(0.033, 0.24, 0.020), C(0.26, 0.27, z - 0.029) * A(0, 0, 0.39), scar)
	end
	facialHair(v, head, look, hair, z, hideLegacyBeard, hideLegacyMustache)
	v.Parent = model
end

local function garment(model, look, worn)
	clearLayer(model, "Tenue_WA")
	local v = newLayer("Tenue_WA")
	local top, waist = model:FindFirstChild("UpperTorso"), model:FindFirstChild("LowerTorso")
	local shirt, pants = Apparence.SHIRTS[look.shirt], Apparence.PANTS[look.pants]
	local leather, linen = rgb(83, 57, 41), rgb(211, 196, 167)
	local cloth = Enum.Material.Fabric
	local function panel(part, name, width, height, x, y, color, angle)
		if part and part:IsA("BasePart") then
			weld(v, part, name, V(part.Size.X * width, part.Size.Y * height, 0.08),
				C(part.Size.X * x, part.Size.Y * y, -part.Size.Z / 2 - 0.022) * A(0, 0, angle or 0), color, cloth)
		end
	end
	local shirtCut = look.shirtCut
	if not worn.armor and waist and waist:IsA("BasePart") then
		if shirtCut == "tablier" then
			panel(top, "Bavette", 0.50, 0.67, 0, -0.17, linen)
			for _, side in { -1, 1 } do
				panel(top, "Bretelle", 0.066, 0.43, side * 0.19, 0.25, leather, side * 0.13)
			end
			panel(waist, "Tablier", 0.78, 0.85, 0, 0, linen)
		elseif shirtCut == "col" then
			local trim = shirt:Lerp(linen, 0.66)
			for _, side in { -1, 1 } do
				panel(top, "Col", 0.08, 0.37, side * 0.095, 0.27, trim, -side * 0.65)
				panel(top, "Lacet", 0.12, 0.029, 0, 0.20 + side * 0.057, linen, side * 0.30)
			end
		elseif shirtCut == "ceinture" or shirtCut == "longue" then
			local size = waist.Size
			weld(v, waist, "Ceinture", V(size.X * 1.06, 0.14, size.Z * 1.08), C(0, 0.06, 0), leather)
			weld(v, waist, "Boucle", V(0.20, 0.17, 0.075), C(0.17, 0.06, -size.Z * 0.55), rgb(175, 139, 77))
		end
		if shirtCut == "longue" or shirtCut == "tablier" then
			for _, side in { "Left", "Right" } do
				local leg = model:FindFirstChild(side .. "UpperLeg")
				local long = shirtCut == "longue"
				local color = long and shirt or linen
				panel(leg, "Pan", long and 1.05 or 0.86, long and 0.83 or 0.60, 0, long and 0.11 or 0.22, color)
				if long then
					panel(leg, "Ourlet", 1.06, 0.10, 0, -0.29, color:Lerp(linen, 0.37))
				end
			end
		end
	end

	if not worn.legs and look.pantsCut ~= "simple" then
		for _, side in { "Left", "Right" } do
			local leg = model:FindFirstChild(side .. "LowerLeg")
			if look.pantsCut == "renforts" then
				panel(leg, "Genouillere", 0.78, 0.38, 0, 0.34, leather)
				panel(leg, "Couture", 0.60, 0.049, 0, 0.47, linen)
			elseif not worn.tallboots and leg and leg:IsA("BasePart") then
				local gaiter = look.pantsCut == "guetres"
				local size = leg.Size
				local trim = pants:Lerp(gaiter and linen or leather, 0.46)
				weld(v, leg, gaiter and "Guetre" or "Revers", V(size.X * 1.07, size.Y * (gaiter and 0.63 or 0.18), size.Z * 1.08),
					C(0, -size.Y * (gaiter and 0.18 or 0.36), 0), trim, cloth)
				if gaiter then
					for _, angle in { -0.40, 0.40 } do
						panel(leg, "Lien", 0.77, 0.056, 0, -0.13, leather, angle)
					end
				end
			end
		end
	end
	if #v:GetChildren() > 0 then v.Parent = model else v:Destroy() end
end

-- Corps R15 du joueur ou copie de la fiche. Les options portées masquent les couches qui se chevauchent.
function Apparence.peindre(model, savedLook, worn)
	local look = Apparence.normalize(savedLook)
	worn = worn or {}
	local function paint(names, color)
		for _, n in names do
			local p = model:FindFirstChild(n)
			if p and p:IsA("BasePart") then
				p.Color = color
				if p:IsA("MeshPart") then
					pcall(function()
						p.TextureID = ""
					end)
				end
			end
		end
	end
	paint(Apparence.SKIN_PARTS, Apparence.SKINS[look.skin])
	paint(Apparence.SHIRT_PARTS, Apparence.SHIRTS[look.shirt])
	paint(Apparence.PANTS_PARTS, Apparence.PANTS[look.pants])
	paint(Apparence.FEET, rgb(70, 50, 36))
	local head = model:FindFirstChild("Head")
	clearLayer(model, "Coiffure_WA")
	if head and head:IsA("BasePart") then
		for _, part in head:GetChildren() do
			if part:IsA("Decal") and part.Name:lower() == "face" then part:Destroy() end
		end
		local legacyCovered = worn.covered and savedLook and savedLook.hair == "barbe"
		Apparence.visage(head, look, legacyCovered and savedLook.beard == nil, legacyCovered and savedLook.mustache == nil)
		local hairModel = newLayer("Coiffure_WA")
		if not worn.covered then
			HAIRS[look.hair](hairModel, head, Apparence.HAIR_COLORS[look.hairColor], true)
		end
		hairModel.Parent = model
	end
	garment(model, look, worn)
end

return Apparence
