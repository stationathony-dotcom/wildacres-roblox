-- Miniatures dont la silhouette porte l’identité de l’objet.
local M = {}
local V, C, rgb = Vector3.new, CFrame.new, Color3.fromRGB
local wood, bronze, steel = rgb(113, 70, 42), rgb(183, 126, 55), rgb(177, 193, 198)
local mat = Enum.Material
local rot, pi = CFrame.Angles, math.pi
local cream, dark, green = rgb(241, 214, 164), rgb(61, 42, 32), rgb(102, 147, 65)
local clay, gold = rgb(171, 92, 55), rgb(224, 172, 65)

local formes = {}
local function serie(ids, construire)
	for id in ids:gmatch("%S+") do
		assert(not formes[id], "Miniature en double : " .. id)
		formes[id] = construire
	end
end

local function dessin(model)
	local d = {}
	function d.part(nom, taille, pose, couleur, forme, matiere)
		assert(taille.X > 0 and taille.Y > 0 and taille.Z > 0, model.Name .. " : taille invalide de " .. nom)
		local classe = ({ wedge = "WedgePart", corner = "CornerWedgePart" })[forme] or "Part"
		local p = Instance.new(classe)
		if forme == "ball" or forme == "cylinder" then
			p.Shape = forme == "ball" and Enum.PartType.Ball or Enum.PartType.Cylinder
		end
		p.Name, p.Size, p.CFrame, p.Color = nom, taille, pose, couleur
		p.Material = matiere or mat.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Parent = model
		return p
	end
	function d.box(n, x, y, z, X, Y, Z, c, m, yaw)
		return d.part(n, V(x, y, z), C(X, Y, Z) * rot(0, yaw or 0, 0), c, nil, m)
	end
	function d.ball(n, x, y, z, X, Y, Z, c, m)
		return d.part(n, V(x, y, z), C(X, Y, Z), c, "ball", m)
	end
	function d.disc(n, diametre, hauteur, x, y, z, c, m)
		return d.part(n, V(hauteur, diametre, diametre), C(x, y, z) * rot(0, 0, pi / 2), c, "cylinder", m)
	end
	function d.line(n, a, b, largeur, c, m, profondeur)
		local direction = b - a
		local haut = math.abs(direction.Unit.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis
		return d.part(n, V(largeur, profondeur or largeur, direction.Magnitude + largeur * 0.35),
			CFrame.lookAt((a + b) / 2, b, haut), c, nil, m)
	end
	function d.anneau(n, x, y, z, rx, ry, epaisseur, c, m, segments, horizontal, angle)
		local function point(theta)
			local u, w = math.cos(theta) * rx, math.sin(theta) * ry
			return horizontal and V(x + u, y, z + w) or V(x + u, y + w, z)
		end
		for i = 0, segments - 1 do
			local a = (angle or 0) + i * 2 * pi / segments
			d.line(n, point(a), point(a + 2 * pi / segments), epaisseur, c, m)
		end
	end
	return d
end

function M.objet(id)
	local construire = formes[id]
	if construire then
		local model = Instance.new("Model")
		model.Name = id
		model:SetAttribute("ApercuDroit", true)
		model:SetAttribute("PaletteDediee", true)
		model:SetAttribute("SilhouetteDediee", true)
		construire(dessin(model), id)
		return model
	end
end

-- Les planches 2 et 3 montrent ces pièces de chantier. Les autres blocs sont
-- reconstruits à partir de leur géométrie de pose.
local function construction(d, b)
	local s, c, m = b.size, b.color, b.mat
	local x, y, z = s.X, s.Y, s.Z
	local clair, sombre = c:Lerp(cream, 0.26), c:Lerp(dark, 0.24)
	if b.shape == "ladder" and (b.shapeId == "echelle" or b.shapeId == "grandeechelle") then
		local n = b.shapeId == "echelle" and 4 or 8
		local r = b.material == "rondin"
		for _, signe in { -1, 1 } do
			d.box("Montant d’échelle", x * 0.14, y, z * 0.13, signe * x * 0.35, 0, 0, sombre, m)
		end
		for i = 1, n do
			local h = ((i - 0.5) / n - 0.5) * y
			d.part("Barreau", V(x * 0.79, z * 0.14, z * 0.12), C(0, h, 0), i % 2 == 0 and clair or c,
				r and "cylinder" or nil, m)
		end
		return true
	end
	if b.shapeId == "bloc" or b.shapeId == "dalle" then
		if b.material == "verre" then
			local verre = d.box("Verre pris en feuillure", x, y, z, 0, 0, 0, c, mat.Glass)
			verre.Transparency = b.transp or 0.34
			for _, signe in { -1, 1 } do
				d.box("Arête", x * 0.052, y, z * 0.052, signe * x * 0.47, 0, -z * 0.47, clair, mat.Glass)
				d.box("Arête de verre", x, y * 0.043, z * 0.052, 0, signe * y * 0.48, -z * 0.47, clair, mat.Glass)
			end
		elseif b.material == "bois" or b.material == "rondin" or b.material == "bardeau" then
			local n = b.material == "rondin" and 3 or 5
			for i = 1, n do
				local a = (i - (n + 1) / 2) / n
				d.box("Lame assemblée", x, y, z / n * 1.012, 0, 0, a * z, c:Lerp(i % 2 == 0 and clair or sombre, 0.60), m)
				d.box("Trait du bois", x * 0.75, y * 0.037, z * 0.028, i % 2 * x * 0.06, y * 0.505,
					a * z, i % 2 == 0 and sombre or clair, mat.Wood)
			end
		else
			d.box("Corps de la pièce", x, y, z, 0, 0, 0, sombre, m)
			for ligne = 0, 2 do
				for colonne = 0, 2 do
					local a = (colonne - 1) * x * 0.318
					d.box("Parement", x * 0.303, y * 0.29, z * 0.042, a, (ligne - 1) * y * 0.327,
						-z * 0.492, c:Lerp(clair, (colonne * 2 + ligne) % 4 * 0.25), m)
				end
			end
		end
		return true
	end
	if b.shapeId == "demimur" or b.shapeId == "grandmur" or b.shapeId == "linteau" or b.shapeId == "hautpoteau" then
		d.box("Corps de la pièce", x, y, z, 0, 0, 0, c, m)
		for _, signe in { -1, 1 } do
			d.box("Chant", x * 0.12, y, z * 0.028, signe * x * 0.43, 0, -z * 0.497, sombre, m)
			d.box("Assise", x, y * 0.08, z * 1.024, 0, signe * y * 0.45, 0, clair, m)
		end
		return true
	end
	return false
end

function M.construireBloc(b)
	local model = Instance.new("Model")
	model.Name = b.item
	model:SetAttribute("ApercuDroit", true)
	if construction(dessin(model), b) then return model end
	model:Destroy()
	return nil
end

-- Pains, biscuits et tartes : la base, le bord saillant et la garniture se rejoignent.
local pains = {
	bread = { 1.95, 0.71, 0.82, 4 },
	country_bread = { 1.38, 0.85, 1.24, 3 },
	whole_bread = { 1.65, 0.80, 0.94, 2 },
}
serie("bread country_bread whole_bread", function(d, id)
	local p = pains[id]
	local x, y, z = p[1], p[2], p[3]
	local c = id == "whole_bread" and rgb(153, 88, 45) or rgb(185, 106, 42)
	d.ball("Croûte", x, y, z, 0, y * 0.42, 0, c)
	d.ball("Croûte dorée", x * 0.95, y * 0.51, z * 0.93, 0, y * 0.64, 0, c:Lerp(gold, 0.37))
	d.ball("Dessous fariné", x * 0.79, 0.18, z * 0.84, 0, 0.12, 0, cream:Lerp(c, 0.48))
	for i = 1, p[4] do
		local t = (i - (p[4] + 1) / 2) / p[4]
		d.part("Grigne", V(0.14, 0.063, z * (0.62 - math.abs(t) * 0.4)),
			C(t * x, y * (0.873 - math.abs(t) * 0.36), -0.04) * rot(0, 0.38, 0), cream, "ball")
	end
	if id == "whole_bread" then
		d.ball("Tranche de pain complet", 0.48, 0.56, 0.79, 0.79, 0.29, -0.10, c)
		d.ball("Mie de la tranche", 0.20, 0.47, 0.64, 0.96, 0.30, -0.10, cream:Lerp(c, 0.4))
	end
end)

serie("apple_pie meat_pie pie galette honey_cake omelette", function(d, id)
	local omelette = id == "omelette"
	local hauteur = id == "honey_cake" and 0.49 or id == "meat_pie" and 0.39 or 0.26
	local c = rgb(185, 106, 43)
	if omelette then
		d.disc("Assiette", 1.65, 0.16, 0, 0.08, 0, cream)
		d.ball("Omelette pliée", 1.33, 0.42, 0.95, 0, 0.28, -0.08, gold)
		d.ball("Repli", 1.20, 0.13, 0.48, 0.03, 0.38, -0.36, rgb(246, 192, 72))
		for i = -1, 1 do
			d.ball("Herbes", 0.20, 0.07, 0.12, i * 0.27, 0.46 - math.abs(i) * 0.04, -0.12, green)
		end
		return
	end
	if id == "galette" then
		for i = 0, 2 do
			local x, y = i * 0.095, 0.080 + 0.14 * i
			d.ball("Galette d'avoine", 1.49 - i * 0.12, 0.20, 1.34 - i * 0.08, x, y, -0.05 * i,
				rgb(170 + i * 17, 105 + i * 13, 57 + i * 8))
			d.ball("Bord croustillant", 1.30 - i * 0.09, 0.09, 1.28 - i * 0.08, x, y + 0.05, 0.015 - 0.05 * i,
				rgb(207, 149, 77))
		end
		d.box("Noisette de beurre", 0.35, 0.12, 0.30, 0.18, 0.48, -0.10, cream, nil, 0.44)
		return
	end
	d.disc("Croûte", 1.47, hauteur, 0, hauteur / 2, 0, c)
	d.disc("Bord doré", 1.59, 0.14, 0, hauteur - 0.02, 0, rgb(232, 155, 64))
	d.disc("Garniture", 1.36, 0.11, 0, hauteur + 0.026, 0, id == "pie" and rgb(157, 53, 63) or gold)
	if id == "apple_pie" then
		for i = -1, 1 do
			d.box("Treillis", 0.135, 0.08, 1.09, i * 0.33, hauteur + 0.091, 0, cream)
			d.box("Treillis", 1.09, 0.06, 0.13, 0, hauteur + 0.134, i * 0.32, rgb(232, 156, 69))
		end
	elseif id == "meat_pie" then
		d.ball("Chapeau bombé", 1.38, 0.29, 1.38, 0, hauteur + 0.06, 0, c:Lerp(gold, 0.56))
		for i = -1, 1 do
			d.box("Évent de cuisson", 0.10, 0.06, 0.42, i * 0.24, hauteur + 0.194, 0, dark, nil, 0.55)
		end
	elseif id == "pie" then
		for i = 0, 6 do
			local a = i * 2 * pi / 7
			d.ball("Baie confite", 0.30, 0.19, 0.30, 0.48 * math.cos(a), hauteur + 0.13, 0.48 * math.sin(a),
				rgb(186 + i * 5, 59, 58))
		end
	else
		d.disc("Miel entre les couches", 1.49, 0.09, 0, hauteur * 0.49, 0, gold)
		d.ball("Glaçage", 1.40, 0.18, 1.40, 0, hauteur + 0.08, 0, cream)
		d.ball("Noix centrale", 0.27, 0.17, 0.28, 0, hauteur + 0.20, 0, c)
	end
end)

local plats = {
	broth = { rgb(181, 106, 45), rgb(246, 194, 101), "rond", 3, 1.15 },
	stew = { rgb(125, 63, 36), rgb(201, 130, 59), "cube", 5, 1.46 },
	soup = { rgb(178, 77, 29), rgb(238, 155, 71), "rond", 5, 1.41 },
	nettle_soup = { rgb(68, 108, 49), rgb(141, 170, 80), "feuille", 6, 1.38 },
	fish_soup = { rgb(153, 90, 49), rgb(224, 182, 145), "filet", 4, 1.52 },
	rabbit_stew = { rgb(165, 100, 57), rgb(224, 175, 118), "filet", 5, 1.39 },
	game_stew = { rgb(104, 57, 47), rgb(181, 95, 62), "cube", 6, 1.57 },
	porridge = { rgb(211, 171, 109), rgb(246, 214, 146), "grain", 8, 1.46 },
	salad = { rgb(70, 99, 40), rgb(110, 151, 55), "feuille", 8, 1.61 },
	cooked_veg = { rgb(151, 98, 58), rgb(231, 123, 40), "cube", 6, 1.65 },
}
serie("broth stew soup nettle_soup fish_soup rabbit_stew game_stew porridge salad cooked_veg", function(d, id)
	local p = plats[id]
	local hauteur = id == "cooked_veg" and 0.24 or id == "broth" and 0.66 or 0.48
	local r = p[5]
	d.disc("Pied de l'écuelle", r * 0.62, 0.11, 0, 0.055, 0, wood, mat.Wood)
	d.ball("Écuelle tournée", r, hauteur, r, 0, hauteur * 0.49, 0, wood, mat.Wood)
	d.disc("Lèvre de l'écuelle", r, 0.16, 0, hauteur * 0.87, 0, clay, mat.CeramicTiles)
	d.disc("Fond du plat", r * 0.87, 0.10, 0, hauteur * 0.87 + 0.061, 0, p[1])
	for i = 1, p[4] do
		local a = i * 2 * pi / p[4]
		local x, y, z = math.cos(a) * r * 0.25, hauteur * 0.87 + 0.12, math.sin(a) * r * 0.25
		local c = p[2]:Lerp(i % 2 == 0 and cream or green, i % 3 * 0.14)
		if p[3] == "cube" then
			d.box("Morceau", 0.23, 0.17, 0.20, x, y, z, c, nil, a)
		elseif p[3] == "grain" or p[3] == "rond" then
			d.ball("Garniture", 0.19, 0.14, 0.16, x, y, z, c)
		else
			d.part(p[3] == "filet" and "Filet" or "Feuille", V(0.39, 0.15, 0.22),
				C(x, y, z) * rot(0.15, a, 0.21), c, "ball")
		end
	end
	if id == "salad" or id == "fish_soup" or id == "stew" or id == "rabbit_stew" then
		d.ball(id == "salad" and "Tomate" or "Garniture centrale", 0.36, 0.22, 0.34,
			0, hauteur * 0.87 + 0.15, 0, id == "salad" and rgb(191, 49, 33) or p[2])
	elseif id == "broth" or id == "porridge" then
		local y = hauteur * 0.87
		d.line("Manche de la cuillère", V(0.30, y + 0.06, -0.13), V(0.91, y + 0.18, -0.35), 0.10, wood, mat.Wood)
	end
end)

serie("cheese butter fat soap beeswax candle_wax", function(d, id)
	if id == "cheese" then
		local pose = rot(0, 0, pi / 2)
		d.part("Pointe de fromage", V(0.40, 1.40, 1.59), C(0, 0.22, 0) * pose, rgb(244, 194, 71), "wedge")
		d.part("Croûte", V(0.10, 1.40, 1.59), C(0, 0.02, 0) * pose, gold, "wedge")
		for _, trou in { { 0.42, -0.59 }, { 0.28, -0.16 }, { 0.51, 0.16 }, { 0.34, 0.46 } } do
			d.disc("Alvéole", 0.16, 0.04, trou[1], 0.41, trou[2], rgb(186, 114, 34))
		end
		return
	end
	if id == "beeswax" then
		for i = 0, 5 do
			local a = i * pi / 3
			d.disc("Cellule de cire", 0.48, 0.28, 0.42 * math.cos(a), 0.15, 0.42 * math.sin(a), gold)
			d.disc("Creux", 0.27, 0.04, 0.42 * math.cos(a), 0.29, 0.42 * math.sin(a), rgb(160, 103, 42))
		end
		d.disc("Cellule centrale", 0.55, 0.31, 0, 0.17, 0, rgb(238, 182, 71))
	elseif id == "fat" then
		d.disc("Coupelle de graisse", 1.45, 0.17, 0, 0.085, 0, clay)
		for i = 0, 4 do
			local a = i * pi * 0.4
			d.ball("Graisse", 0.63, 0.45, 0.62, 0.36 * math.cos(a), 0.27, 0.36 * math.sin(a), cream)
		end
	elseif id == "candle_wax" then
		for i = 0, 2 do
			d.disc("Pain de cire", 1.18 - i * 0.23, 0.24, i * 0.08, 0.12 + i * 0.22, 0, cream)
			d.disc("Marque du moule", 0.84 - i * 0.23, 0.035, i * 0.08, 0.23 + i * 0.22, 0, rgb(228, 190, 118))
		end
	else
		local savon = id == "soap"
		local c = savon and rgb(133, 168, 134) or rgb(249, 208, 95)
		d.box(savon and "Pain de savon" or "Pain de beurre", 1.41, 0.43, 0.87, 0, 0.26, 0, c)
		d.box("Face de coupe", 1.31, 0.07, 0.78, 0, 0.49, 0, c:Lerp(cream, 0.37))
		d.box(savon and "Torchon" or "Planche", 1.58, 0.10, 1.02, -0.06, 0.039, 0.04,
			savon and cream or wood, savon and mat.Fabric or mat.WoodPlanks)
		for i = -1, 1 do
			d.box(savon and "Empreinte" or "Trace du couteau", 0.07, 0.036, 0.32,
				i * 0.22, 0.53, -0.08, c:Lerp(dark, 0.2), nil, i * 0.40)
		end
	end
end)

local filons = {
	ore = { rgb(95, 103, 102), rgb(143, 168, 167), 4, 1.52 },
	copper_ore = { rgb(100, 89, 78), rgb(199, 118, 63), 5, 1.42 },
	gold_ore = { rgb(82, 91, 101), rgb(244, 187, 49), 4, 1.48 },
	silver_ore = { rgb(68, 86, 107), rgb(201, 223, 230), 6, 1.66 },
	coal = { rgb(55, 55, 58), rgb(88, 94, 100), 5, 1.15 },
	meteorite = { rgb(58, 55, 65), rgb(207, 93, 60), 3, 1.50 },
	stone = { rgb(103, 104, 95), rgb(166, 158, 134), 3, 1.63 },
	colored_stone = { rgb(107, 88, 97), rgb(154, 124, 161), 5, 1.27 },
	glowstone = { rgb(61, 83, 92), rgb(112, 211, 187), 3, 1.35 },
	clay = { rgb(132, 74, 52), rgb(189, 107, 70), 4, 1.45 },
	flint = { rgb(62, 68, 73), rgb(134, 146, 151), 3, 1.23 },
}
serie("ore copper_ore gold_ore silver_ore coal meteorite stone colored_stone glowstone clay flint", function(d, id)
	local p = filons[id]
	local l = p[4]
	local h = id == "meteorite" and 0.93 or id == "clay" and 0.44 or id == "flint" and 0.41 or 0.72
	local rock = id == "clay" and mat.Ground or mat.Slate
	d.part("Gangue", V(l, h, 0.86), C(0, h / 2, 0) * rot(0, -0.21, -0.05), p[1], nil, rock)
	d.part("Cassure basse", V(0.65, h * 0.68, 0.60), C(l * 0.29, h * 0.30, -0.23) * rot(0, -0.58, 0.16), p[1]:Lerp(p[2], 0.16), "corner", rock)
	d.part("Relief de la gangue", V(l * 0.70, h * 0.43, 0.74), C(-l * 0.15, h * 0.85, 0.03) * rot(0, 0.35, 0.08), p[1]:Lerp(p[2], 0.27), "wedge", rock)
	for i = 0, p[3] - 1 do
		local a = i * 2.39
		local x, y, z = math.cos(a) * l * 0.34, h * (0.75 + i % 2 * 0.20), math.sin(a) * 0.35
		local lumiere = id == "glowstone" and i == 0
		d.part(lumiere and "Lueur du filon" or "Inclusion", V(0.24 + i % 3 * 0.07, 0.23 + i % 2 * 0.16, 0.22),
			C(x, y, z) * rot(0.2 * i, a, i * 0.22), p[2]:Lerp(cream, i % 3 * 0.17),
			i % 2 == 0 and "corner" or "wedge", lumiere and mat.Neon or id:find("_ore") and mat.Metal or rock)
	end
end)

local barres = {
	copper_ingot = { rgb(191, 106, 60), 1.29, 2, 1 },
	iron_ingot = { rgb(131, 151, 164), 1.45, 2, 2 },
	silver_ingot = { rgb(189, 208, 214), 1.30, 3, 3 },
	gold_ingot = { rgb(229, 174, 66), 1.51, 2, 4 },
	precious_ingot = { rgb(178, 112, 161), 1.24, 3, 1 },
	steel = { rgb(99, 126, 147), 1.57, 1, 3 },
	iron_bar = { rgb(83, 105, 119), 1.93, 1, 2 },
}
serie("copper_ingot iron_ingot silver_ingot gold_ingot precious_ingot steel iron_bar", function(d, id)
	local p = barres[id]
	local c, l, nombre = p[1], p[2], p[3]
	local barre = id == "iron_bar"
	local h, z = barre and 0.20 or 0.29, barre and 0.34 or 0.70
	local face = c:Lerp(cream, 0.25)
	for i = 0, nombre - 1 do
		local x, y, yaw = i * 0.10, i * h * 0.94, i * 0.19
		local at = C(x, y, 0) * rot(0, yaw, 0)
		d.part("Corps coulé", V(l * 0.79, h, z), at, c, nil, mat.Metal)
		d.part("Table du lingot", V(l * 0.88, h * 0.36, z * 0.82), at * C(0, h * 0.35, 0), face, nil, mat.Metal)
		for _, s in { -1, 1 } do
			d.part("Chanfrein", V(z, h * 0.94, l * 0.17), at * C(s * l * 0.41, -h * 0.03, 0) * rot(0, s * pi / 2, 0),
				c:Lerp(dark, 0.11), "wedge", mat.Metal)
		end
	end
	local top = C((nombre - 1) * 0.10, ((nombre - 1) * 0.94 + 0.54) * h, 0) * rot(0, (nombre - 1) * 0.19, 0)
	for i = 1, math.max(p[4], 2) do
		d.part("Poinçon de forge", V(0.08, 0.028, 0.21 - i * 0.017),
			top * C((i - (p[4] + 1) / 2) * 0.14, 0, 0) * rot(0, -0.44, 0), c:Lerp(dark, 0.47), nil, mat.Metal)
	end
end)

local gemmes = {
	diamond = { rgb(153, 220, 233), 0.82, 1.23, 4 }, ruby = { rgb(181, 49, 61), 0.84, 0.91, 6 },
	sapphire = { rgb(59, 103, 184), 0.92, 0.73, 5 }, emerald = { rgb(56, 151, 100), 0.98, 0.76, 4 },
	amber = { rgb(214, 130, 38), 0.97, 0.72, 5 }, ancient_crystal = { rgb(112, 161, 161), 0.58, 1.45, 3 },
	ice_crystal = { rgb(115, 182, 213), 0.61, 1.28, 3 }, frost_crystal = { rgb(130, 202, 222), 0.79, 0.99, 5 },
	glass_shard = { rgb(116, 171, 174), 1.00, 0.58, 4 },
}
serie("diamond ruby sapphire emerald amber ancient_crystal ice_crystal frost_crystal glass_shard", function(d, id)
	local p = gemmes[id]
	local c, w, h = p[1], p[2], p[3]
	local tranche = id == "emerald" or id == "glass_shard"
	local brut = id:find("crystal") ~= nil
	local z = id == "glass_shard" and 0.27 or w * 0.75
	local center = C(0, h * 0.55, 0) * rot(0, 0.37, brut and -0.13 or 0)
	d.part("Corps de la pierre", V(w * 0.75, h * 0.58, z * 0.77), center, c, id == "amber" and "ball" or nil, mat.Glass)
	d.part("Table", V(w * 0.63, h * 0.14, z * 0.65), center * C(0, h * 0.31, 0), c:Lerp(cream, 0.43), nil, mat.Glass)
	for i = 0, p[4] - 1 do
		local a = i * 2 * pi / p[4]
		d.part("Facette", V(w * 0.40, h * (brut and 0.69 or 0.51), z * 0.38),
			center * C(math.cos(a) * w * 0.31, -h * 0.07 + i % 2 * h * 0.10, math.sin(a) * z * 0.30)
				* rot(0, -a, (tranche and 0.3 or -0.2) * (i % 2)),
			c:Lerp(i % 2 == 0 and cream or dark, 0.17 + i % 3 * 0.12), i % 2 == 0 and "corner" or "wedge", mat.Glass)
	end
	if brut then
		d.part("Éclat secondaire", V(w * 0.69, h * 0.57, z * 0.72), C(w * 0.43, h * 0.32, z * 0.14) * rot(0, 1.2, -0.51),
			c:Lerp(cream, 0.39), "wedge", mat.Glass)
	end
end)

serie("glass brick prepared_clay", function(d, id)
	local verre = id == "glass"
	local c = verre and rgb(103, 172, 178) or id == "brick" and rgb(169, 77, 51) or clay
	local m = verre and mat.Glass or id == "brick" and mat.Brick or mat.Ground
	for i = 0, 2 do
		local y, x = 0.10 + 0.20 * i, (i % 2 - 0.5) * 0.34
		local p = d.box(verre and "Plaque de verre" or "Brique", 1.33 - i * 0.09, 0.22, 0.80, x, y, 0, c, m, i * 0.14)
		if verre then p.Transparency = 0.28 end
		d.box(verre and "Arête du verre" or "Face lissée", 1.20 - i * 0.09, 0.035, verre and 0.10 or 0.64, x, y + 0.10, -0.08,
			c:Lerp(cream, 0.34), m, i * 0.14)
	end
end)

local boites = {
	craft_kit = { 1.38, 0.46, 0.91, rgb(104, 105, 70), "outil" },
	jewel_box = { 1.20, 0.62, 0.92, rgb(101, 53, 86), "gemme" },
	keepsake_box = { 1.32, 0.59, 0.83, rgb(127, 80, 52), "motif" },
	travel_chest = { 1.55, 0.76, 0.93, rgb(102, 70, 53), "anse" },
	reinforced_chest = { 1.44, 0.86, 0.95, rgb(60, 73, 82), "ferrure" },
	supply_chest = { 1.60, 0.69, 0.96, rgb(87, 105, 74), "sangle" },
	chest = { 1.46, 0.78, 0.94, rgb(124, 76, 43), "coffre" },
	crate = { 1.33, 0.95, 1.06, rgb(145, 97, 54), "caisse" },
	nailed_crate = { 1.39, 1.01, 0.97, rgb(123, 80, 50), "clous" },
	packed_goods = { 1.52, 0.74, 1.00, rgb(158, 112, 66), "corde" },
	lost_item = { 1.13, 0.71, 0.83, rgb(116, 89, 62), "paquet" },
	document_case = { 1.51, 0.44, 0.78, rgb(102, 65, 49), "étui" },
	claim = { 1.21, 0.36, 0.80, rgb(118, 81, 54), "panneau" },
}
serie("craft_kit jewel_box keepsake_box travel_chest reinforced_chest supply_chest chest crate nailed_crate packed_goods lost_item document_case claim", function(d, id)
	local p = boites[id]
	local x, y, z, c, kind = p[1], p[2], p[3], p[4], p[5]
	local bord = c:Lerp(dark, 0.35)
	local e = kind == "étui" and mat.Leather or kind == "paquet" and mat.Fabric or mat.WoodPlanks
	d.box("Caisse", x, y, z, 0, y / 2, 0, c, e)
	d.box("Fond", x * 1.035, 0.13, z * 1.04, 0, 0.065, 0, bord, e)
	d.box("Couvercle", x * 1.04, 0.16, z * 1.04, 0, y + 0.045, 0, c:Lerp(cream, 0.19), e)
	if kind == "caisse" or kind == "clous" then
		for _, side in { -1, 1 } do
			d.box("Tasseau", 0.16, y, 0.13, side * x * 0.43, y * 0.53, -z * 0.49, bord, mat.Wood)
			for i = 1, 3 do
				d.ball("Clou", 0.10, 0.10, 0.06, side * x * 0.43, y * (0.20 + i * 0.18), -z * 0.56, steel, mat.Metal)
			end
		end
		if kind == "clous" then
			d.line("Contreventement", V(-x * 0.43, 0.14, -z * 0.52), V(x * 0.43, y * 0.92, -z * 0.52), 0.15, c:Lerp(cream, 0.25), mat.Wood)
		else
			d.box("Traverse", x, 0.15, 0.12, 0, y * 0.76, -z * 0.51, bord, mat.Wood)
		end
	elseif kind == "panneau" then
		d.box("Piquet", 0.17, y * 2.9, 0.18, -0.46, y * 1.31, 0.12, bord, mat.Wood)
		d.box("Enseigne", 1.06, 0.47, 0.19, -0.09, y * 2.06, 0.11, c, mat.Wood)
		d.box("Marque du terrain", 0.57, 0.23, 0.04, -0.06, y * 2.06, 0, green)
	else
		local sangle = kind == "corde" or kind == "sangle" or kind == "paquet"
		local acier = kind == "ferrure"
		local m = acier and mat.Metal or mat.Leather
		local trim = acier and steel or sangle and cream:Lerp(wood, 0.3) or bronze
		for _, side in { -1, 1 } do
			d.box("Bande", sangle and 0.12 or 0.17, y * 0.86, 0.07, side * x * 0.34, y * 0.52, -z * 0.52, trim, m)
			d.box("Bande du dessus", sangle and 0.12 or 0.17, 0.06, z * 1.06, side * x * 0.34, y + 0.13, 0, trim, m)
		end
		if kind == "anse" or kind == "outil" then
			d.box("Poignée", 0.63, 0.13, 0.16, 0, y + 0.39, 0, bord, mat.Wood)
			for _, s in { -1, 1 } do
				d.box("Attache de poignée", 0.13, 0.28, 0.17, s * 0.28, y + 0.24, 0, bronze, mat.Metal)
			end
		end
		if kind == "gemme" then
			d.box("Monture", 0.39, 0.09, 0.43, 0, y + 0.15, 0, gold, mat.Metal)
			d.part("Cabochon", V(0.29, 0.21, 0.32), C(0, y + 0.25, 0) * rot(0, 0.4, 0), rgb(93, 169, 149), "ball", mat.Glass)
		elseif kind == "motif" then
			d.box("Marqueterie", 0.37, 0.043, 0.37, 0, y + 0.125, 0, cream, mat.Wood, pi / 4)
		end
		d.box(sangle and "Nœud" or "Fermoir", 0.29, 0.25, 0.09, 0, y * 0.70, -z * 0.55, trim, m)
		d.ball("Goupille", 0.10, 0.10, 0.06, 0, y * 0.70, -z * 0.60, dark)
	end
end)

local serrures = {
	lock_2 = { 1.23, 0.77, 0.43, rgb(158, 87, 52), 0.36, 0.31 },
	lock_3 = { 0.92, 0.83, 0.54, rgb(74, 83, 98), 0.31, 0.49 },
	lock_4 = { 1.14, 0.85, 0.50, rgb(171, 127, 59), 0.41, 0.24 },
	practice_lock = { 1.17, 0.77, 0.54, wood, 0.25, 0.26 },
}
serie("lock_1 lock_2 lock_3 lock_4 practice_lock", function(d, id)
	if id == "lock_1" then
		d.box("Plaque du loquet", 1.33, 0.71, 0.19, 0, 0.37, 0, wood, mat.WoodPlanks)
		d.box("Verrou coulissant", 1.52, 0.19, 0.23, 0.12, 0.36, -0.16, bronze, mat.Wood)
		for _, s in { -1, 1 } do
			d.box("Bride", 0.18, 0.38, 0.16, s * 0.39, 0.35, -0.24, dark, mat.Wood)
			d.ball("Cheville", 0.12, 0.12, 0.11, s * 0.39, 0.52, -0.19, cream, mat.Wood)
		end
		d.line("Tirette", V(0.09, 0.34, -0.22), V(0.09, 0.58, -0.38), 0.13, wood, mat.Wood)
		d.ball("Bouton", 0.23, 0.19, 0.20, 0.09, 0.58, -0.38, bronze, mat.Wood)
		return
	end
	local p = serrures[id]
	local x, y, z, c, rx, ry = p[1], p[2], p[3], p[4], p[5], p[6]
	local practice = id == "practice_lock"
	local plate = c:Lerp(cream, 0.27)
	d.box("Boîtier", x * 0.88, y, z, 0, y / 2, 0, c, practice and mat.WoodPlanks or mat.Metal)
	if id == "lock_3" then
		d.ball("Ventre arrondi", x, y * 0.96, z * 1.27, 0, y * 0.46, -0.025, plate, mat.Metal)
	else
		d.box("Plaque", x, y * 0.82, 0.15, 0, y / 2, -z * 0.47, plate, mat.Metal)
	end
	local at = y + 0.12
	if id ~= "lock_2" then
		d.anneau("Anse", 0, at, 0, rx, ry, id == "lock_3" and 0.19 or 0.13, steel, mat.Metal, 8)
	end
	d.box("Pied du boîtier", x * 0.99, 0.12, z * 1.07, 0, 0.06, 0, c:Lerp(dark, 0.22), mat.Metal)
	d.ball("Trou de clé", 0.19, 0.19, 0.08, 0, y * 0.52, -z * 0.63, dark)
	d.box("Entrée de clé", 0.086, 0.16, 0.078, 0, y * 0.41, -z * 0.64, dark)
	for _, side in { -1, 1 } do
		d.ball("Rivet", 0.12, 0.12, 0.08, side * x * 0.31, y * 0.64, -z * 0.60, bronze, mat.Metal)
		if id == "lock_4" or practice then
			d.box("Ferrure latérale", 0.14, y * 0.81, z * 1.03, side * x * 0.41, y * 0.50, 0, steel, mat.Metal)
		end
	end
	if id == "lock_2" then
		d.box("Pêne", 0.42, 0.17, 0.18, x * 0.54, y * 0.57, 0.01, bronze, mat.Metal)
		d.box("Plaque de renfort", x * 0.81, 0.11, 0.10, 0, y * 0.25, -z * 0.58, bronze, mat.Metal)
	elseif id == "lock_3" then
		d.box("Pont blindé", x * 0.84, 0.17, z, 0, y - 0.035, 0, steel, mat.Metal)
	elseif id == "lock_4" then
		d.part("Rosace du secret", V(0.13, 0.54, 0.54), C(0, y * 0.51, -z * 0.61) * rot(0, pi / 2, 0),
			gold, "cylinder", mat.Metal)
		d.ball("Cabochon de la serrure", 0.23, 0.23, 0.10, 0, y * 0.51, -z * 0.83, dark, mat.Metal)
	elseif practice then
		d.box("Pied de l’étau", x * 1.46, 0.19, z * 1.81, 0, -0.02, 0.04, wood, mat.Wood)
		d.box("Semelle vissée", x * 1.14, 0.12, z * 1.39, 0, 0.08, 0.03, bronze, mat.Metal)
		d.line("Tige de l'étau", V(0.39, y * 0.31, 0.07), V(0.78, y * 0.31, 0.07), 0.11, steel, mat.Metal)
		d.ball("Bouton de l'étau", 0.20, 0.22, 0.18, 0.80, y * 0.31, 0.07, gold, mat.Metal)
	end
end)

local sacs = {
	backpack = { 1.0, 1.22, 0.63, rgb(89, 114, 80), "dos" },
	canvas_bag = { 0.94, 1.25, 0.67, rgb(159, 137, 99), "toile" },
	coin_purse = { 0.94, 0.93, 0.63, rgb(142, 76, 52), "bourse" },
	merchant_bag = { 1.23, 0.94, 0.64, rgb(136, 79, 51), "rabat" },
	merchant_purse = { 0.92, 1.06, 0.71, rgb(94, 81, 129), "monnaie" },
	satchel = { 1.32, 0.91, 0.52, rgb(105, 61, 46), "sacoche" },
	provision_bag = { 1.20, 0.97, 0.76, rgb(169, 120, 69), "rouleau" },
	animal_feed = { 1.25, 0.75, 1.03, rgb(165, 130, 81), "grain" },
}
serie("backpack canvas_bag coin_purse merchant_bag merchant_purse satchel provision_bag animal_feed", function(d, id)
	local p = sacs[id]
	local x, y, z, c, kind = p[1], p[2], p[3], p[4], p[5]
	local tissu = kind == "toile" or kind == "grain" or kind == "rouleau"
	local m = tissu and mat.Fabric or mat.Leather
	local trim = c:Lerp(dark, 0.50)
	d.ball("Corps du sac", x, y, z, 0, y * 0.53, 0, c, m)
	d.ball("Fond cousu", x * 0.81, 0.29, z * 0.78, 0, 0.16, 0, trim, m)
	if kind == "bourse" or kind == "monnaie" or kind == "toile" or kind == "grain" then
		d.ball("Col froncé", x * 0.52, 0.35, z * 0.70, -x * 0.10, y * 0.93, 0, c, m)
		d.box("Cordon", x * 0.52, 0.10, z * 0.74, -x * 0.10, y * 0.93, 0, cream, mat.Fabric)
		for side = -1, 1, 2 do
			d.line("Brin du nœud", V(-x * 0.10, y * 0.94, -z * 0.32),
				V(x * 0.19 * side, y * 0.69, -z * 0.49), 0.085, cream, mat.Fabric)
		end
		if kind == "monnaie" or kind == "grain" then
			for i = -1, 1 do
				d.disc(kind == "grain" and "Grain" or "Pièce", kind == "grain" and 0.17 or 0.31, 0.08,
					i * 0.16 - x * 0.1, y * (1.04 + 0.04 * (i % 2)), -0.12, gold, kind == "grain" and mat.SmoothPlastic or mat.Metal)
			end
		end
	else
		d.ball("Rabat", x * 0.89, y * 0.58, z * 0.59, 0, y * 0.70, -z * 0.30, c:Lerp(cream, 0.23), m)
		for _, s in { -1, 1 } do
			d.box(kind == "dos" and "Bretelle" or "Couture de bord", 0.10, y * 0.55, 0.11,
				s * x * 0.25, y * 0.59, kind == "dos" and z * 0.44 or -z * 0.48, trim, mat.Leather)
			d.box("Sangle de rabat", kind == "dos" and 0.16 or 0.12, y * 0.43, 0.09, s * x * 0.19,
				y * 0.57, -z * 0.57, kind == "dos" and cream:Lerp(wood, 0.54) or trim, mat.Leather)
			d.ball("Fermoir", 0.16, 0.16, 0.08, s * x * 0.19, y * 0.39, -z * 0.59, bronze, mat.Metal)
		end
		if kind == "dos" then
			d.box("Poche de devant", 0.73, 0.34, 0.22, 0, 0.36, -0.30, c:Lerp(cream, 0.26), mat.Leather)
			d.box("Rabat de poche", 0.76, 0.095, 0.24, 0, 0.49, -0.31, trim, mat.Leather)
		elseif kind == "rouleau" then
			d.part("Rouleau de provision", V(x * 0.93, 0.31, 0.31), C(0, y * 1.03, 0), cream, "cylinder", mat.Fabric)
		elseif kind == "sacoche" or kind == "rabat" then
			d.line("Bandoulière gauche", V(-x * 0.40, y * 0.65, 0), V(-x * 0.27, y * 1.20, 0), 0.12, trim, mat.Leather)
			d.line("Bandoulière droite", V(x * 0.40, y * 0.65, 0), V(x * 0.28, y * 1.20, 0), 0.12, trim, mat.Leather)
			d.line("Bandoulière", V(-x * 0.27, y * 1.20, 0), V(x * 0.28, y * 1.20, 0), 0.12, trim, mat.Leather)
		end
	end
end)

local pieces = {
	copper_coin = { rgb(179, 99, 61), 1.24, 1, 3 },
	silver_coin = { rgb(166, 194, 204), 1.29, 2, 2 },
	gold_coin = { gold, 1.34, 1, 4 },
	gold = { gold, 1.22, 4, 4 },
	ancient_coin = { rgb(134, 112, 55), 1.41, 1, 5 },
	event_token = { rgb(207, 119, 56), 1.29, 1, 6 },
	medal = { rgb(200, 154, 62), 1.07, 1, 3 },
	festival_prize = { rgb(185, 104, 48), 1.32, 1, 5 },
}
serie("copper_coin silver_coin gold_coin gold ancient_coin event_token medal festival_prize", function(d, id)
	local p = pieces[id]
	local c, dia, n = p[1], p[2], p[3]
	for i = 0, n - 1 do
		d.disc("Tranche frappée", dia, 0.18, i * 0.18, 0.089 + i * 0.162, i * 0.07, c, mat.Metal)
		d.disc("Listel", dia * 0.86, 0.06, i * 0.18, 0.17 + i * 0.162, i * 0.07, c:Lerp(cream, 0.30), mat.Metal)
	end
	local x, y, z = (n - 1) * 0.18, 0.205 + (n - 1) * 0.162, (n - 1) * 0.07
	local mark = c:Lerp(dark, 0.28)
	d.disc("Relief central", dia * 0.36, 0.052, x, y, z, mark, mat.Metal)
	for i = 0, p[4] - 1 do
		local a = i * 2 * pi / p[4]
		d.box("Frappe", 0.075, 0.065, dia * 0.25, x + math.sin(a) * dia * 0.19, y, z + math.cos(a) * dia * 0.19,
			mark, mat.Metal, a)
	end
	if id == "medal" or id == "festival_prize" then
		local ribbon = id == "medal" and rgb(121, 55, 59) or rgb(67, 95, 131)
		d.box("Ruban", 0.61, 0.12, 0.66, x, y - 0.11, z + 0.56, ribbon, mat.Fabric)
		d.box("Galon", 0.10, 0.055, 0.61, x, y - 0.04, z + 0.58, cream, mat.Fabric)
	end
end)

serie("bracelet buckle brooch necklace ring_gem dog_collar ancient_jewel talisman hoop iron_ring", function(d, id)
	local chien, broche, collier = id == "dog_collar", id == "brooch", id == "necklace"
	local gemme = id == "ring_gem" or id == "ancient_jewel" or id == "talisman"
	local anneau = id == "hoop" or id == "iron_ring"
	local boucle = id == "buckle"
	local c = id == "iron_ring" and steel or chien and rgb(119, 65, 48) or anneau and wood or gold
	local m = chien and mat.Leather or id == "hoop" and mat.Wood or mat.Metal
	local rx, ry = collier and 0.70 or broche and 0.35 or 0.49, collier and 0.53 or boucle and 0.34 or 0.48
	d.anneau("Anneau", 0, 0, 0, rx, ry, chien and 0.22 or 0.13, c, m, boucle and 4 or 10, false, boucle and pi / 4 or 0)
	if boucle then
		d.line("Ardillon", V(-0.35, 0, 0), V(0.37, 0, 0), 0.09, steel, mat.Metal)
		d.ball("Rivet d’ardillon", 0.17, 0.17, 0.15, -0.35, 0, 0, bronze, mat.Metal)
	elseif broche then
		d.ball("Camée", 0.71, 0.87, 0.30, 0, 0, 0, rgb(103, 66, 83), mat.Glass)
		d.ball("Motif sculpté", 0.31, 0.43, 0.16, -0.04, 0.05, -0.17, cream)
		d.line("Épingle", V(-0.63, -0.15, 0.11), V(0.38, -0.15, 0.11), 0.09, steel, mat.Metal)
	elseif anneau then
		d.box("Joint", 0.23, 0.17, 0.18, rx, 0, -0.07, c:Lerp(dark, 0.3), m)
	elseif gemme or collier or chien then
		local sign = id == "ring_gem" and 1 or -1
		local stone = chien and bronze or collier and cream or id == "ancient_jewel" and rgb(96, 185, 144) or rgb(136, 79, 146)
		d.ball("Sertissure", 0.40, 0.41, 0.26, 0, sign * (ry + 0.10), -0.05, bronze, mat.Metal)
		d.part(chien and "Médaille" or "Pierre", V(0.28, collier and 0.43 or 0.27, 0.19),
			C(0, sign * (ry + 0.14), -0.17) * rot(0, 0, id == "talisman" and pi / 4 or 0),
			stone, collier and "wedge" or "ball", chien and mat.Metal or mat.Glass)
	else
		for i = 0, 4 do
			local a = pi * (0.18 + i * 0.16)
			d.ball("Cabochon du bracelet", 0.17, 0.17, 0.13, rx * math.cos(a), ry * math.sin(a), -0.09, bronze, mat.Metal)
		end
	end
end)

serie("rope braided_rope climbing_rope linen_thread wool_thread silk", function(d, id)
	local bobine = id:find("thread") or id == "silk"
	local c = id == "silk" and rgb(232, 214, 172) or bobine and rgb(199, 181, 148) or rgb(156, 109, 66)
	if bobine then
		local laine = id == "wool_thread"
		local h = laine and 0.67 or 0.84
		d.disc("Axe", 0.39, h + 0.22, 0, h / 2, 0, wood, mat.Wood)
		d.disc("Fil enroulé", laine and 0.94 or 0.63, h, 0, h / 2, 0, c, mat.Fabric)
		for _, y in { 0, h } do
			d.disc("Flasque de bobine", laine and 0.98 or 0.81, 0.14, 0, y, 0, wood, mat.Wood)
		end
		for i = 1, 4 do
			d.disc("Rang de fil", laine and 0.97 - 0.05 * (i % 2) or 0.66, 0.078, 0, h * i / 5, 0,
				c:Lerp(cream, i % 2 * 0.20), mat.Fabric)
		end
	else
		local t = id == "climbing_rope" and 0.22 or 0.17
		local rz = id == "braided_rope" and 0.34 or 0.52
		for i = 0, 1 do
			d.anneau("Toron", 0, i * t * 0.85, 0, 0.55, rz, t, c:Lerp(cream, i * 0.19), mat.Fabric, 9, true, i * 0.14)
		end
		d.line("Bout libre", V(0.48, 0.09, -0.13), V(0.92, 0.07, -rz), t, c, mat.Fabric)
		if id ~= "rope" then
			d.box("Ligature", 0.20, 0.32, 0.32, 0.52, 0.07, 0.02, cream, mat.Fabric)
		end
	end
end)

local fruits = {
	apple = { 1.31, 1.12, 1.18, rgb(173, 54, 47), "pomme" },
	tomato = { 1.44, 0.87, 1.30, rgb(205, 66, 42), "côtelé" },
	pumpkin = { 1.57, 0.96, 1.45, rgb(212, 99, 35), "côtelé" },
	squash = { 1.03, 1.40, 1.02, rgb(198, 150, 70), "col" },
	pear = { 1.04, 1.39, 0.98, rgb(160, 169, 57), "col" },
	melon = { 1.23, 1.02, 1.47, rgb(83, 130, 64), "rayé" },
	plum = { 0.97, 1.06, 0.87, rgb(103, 65, 127), "suture" },
	beetroot = { 0.98, 0.88, 0.94, rgb(133, 53, 71), "racine" },
	eggplant = { 0.89, 1.34, 0.87, rgb(91, 57, 125), "col" },
	potato = { 1.31, 0.74, 0.92, rgb(165, 119, 75), "yeux" },
	cabbage = { 1.43, 1.04, 1.37, rgb(82, 120, 56), "chou" },
}
serie("apple tomato pumpkin squash pear melon plum beetroot eggplant potato cabbage", function(d, id)
	local p = fruits[id]
	local x, y, z, c, kind = p[1], p[2], p[3], p[4], p[5]
	local center = kind == "col" and y * 0.33 or y * 0.50
	d.ball("Chair", x * 0.9, y * (kind == "col" and 0.64 or 1), z * 0.91, 0, center, 0, c)
	if kind == "côtelé" or kind == "chou" or kind == "pomme" then
		for i = 0, 5 do
			local a = i * pi / 3
			d.part(kind == "chou" and "Feuille d'enveloppe" or "Lobe", V(x * 0.52, y * 0.91, z * 0.56),
				C(math.cos(a) * x * 0.24, y * 0.48, math.sin(a) * z * 0.23) * rot(0, a, kind == "chou" and i * 0.15 or 0),
				c:Lerp(kind == "chou" and green or cream, i % 3 * 0.11), "ball")
		end
	elseif kind == "col" then
		d.ball("Épaule", x * (id == "eggplant" and 0.77 or 0.52), y * 0.62, z * 0.61,
			0.08, y * 0.67, 0, c:Lerp(cream, id == "eggplant" and 0.05 or 0.18))
	elseif kind == "rayé" then
		for i = 0, 5 do
			local a = i * pi / 3
			d.part("Rayure", V(x * 0.94, y * 0.97, z * 0.13), C(0, center, 0) * rot(a, 0, 0),
				c:Lerp(cream, 0.27), "ball")
		end
	elseif kind == "yeux" or kind == "suture" then
		local zf = -z * 0.43
		for i = -2, 2 do
			d.ball(kind == "yeux" and "Œil du tubercule" or "Suture", kind == "yeux" and 0.10 or 0.06,
				0.09, 0.086, kind == "yeux" and i * 0.19 or 0.035, y * (0.51 + i * 0.085), zf + math.abs(i) * 0.030, c:Lerp(dark, 0.35))
		end
	end
	if kind == "chou" or kind == "yeux" then return end
	local top = y * 0.96
	local xTop = kind == "col" and 0.08 or 0
	d.line("Pédoncule", V(xTop, top - 0.08, 0), V(xTop - 0.05, top + 0.17, -0.06), 0.12, wood, mat.Wood)
	local leaves = id == "tomato" and 5 or id == "beetroot" and 4 or kind == "pomme" and 1 or 3
	for i = 1, leaves do
		local a = i * 2 * pi / leaves
		d.part("Feuille", V(0.37, id == "beetroot" and 0.27 or 0.10, 0.19),
			C(xTop + math.cos(a) * 0.15, top + 0.044, math.sin(a) * 0.12) * rot(0, -a, id == "beetroot" and 0.52 or 0.14), green, "ball", mat.Grass)
	end
	if kind == "racine" then
		d.line("Radicelle", V(0, 0.15, 0), V(-0.13, -0.21, 0.10), 0.07, c)
	end
end)

serie("egg mystery_egg ancient_seed bean pea bait", function(d, id)
	local oeuf = id == "egg" or id == "mystery_egg"
	local c = oeuf and cream or id == "pea" and green or id == "bait" and rgb(184, 127, 100) or rgb(164, 114, 59)
	if oeuf then
		local mystere = id == "mystery_egg"
		d.ball("Coquille", 0.96, 1.25, 0.95, 0, 0.61, 0, mystere and rgb(155, 133, 169) or cream)
		d.ball("Pointe de l'œuf", 0.65, 0.77, 0.67, 0, 0.91, 0, mystere and rgb(176, 153, 185) or cream:Lerp(gold, 0.13))
		for i = 0, 3 do
			local a = i * 1.59 + 0.55
			d.ball("Moucheture", 0.14, 0.086, 0.14, math.cos(a) * 0.43, 0.57 + 0.13 * (i % 2),
				math.sin(a) * 0.43, mystere and rgb(91, 72, 113) or rgb(190, 149, 105))
		end
		return
	end
	local sprout = id == "ancient_seed"
	local bag = id == "bait"
	d.ball(sprout and "Graine ancienne" or bag and "Bourriche d’appâts" or "Gousse",
		sprout and 0.95 or 1.47, 0.47, 0.62, 0, 0.23, 0, c:Lerp(dark, 0.14), bag and mat.Fabric or nil)
	for i = -2, 2 do
		d.ball(bag and "Larve" or "Grain", 0.35, bag and 0.19 or 0.31, 0.31, i * (sprout and 0.13 or 0.235),
			0.36 - math.abs(i) * 0.039, -0.14, c:Lerp(cream, id == "pea" and 0.18 or i % 2 * 0.22))
	end
	if sprout then
		d.line("Germe", V(0, 0.39, 0.08), V(0.08, 0.91, 0.08), 0.092, green, mat.Grass)
		d.ball("Cotylédon", 0.39, 0.16, 0.24, 0.20, 0.82, 0.08, green, mat.Grass)
	elseif id == "pea" then
		d.ball("Bord de la cosse", 1.28, 0.20, 0.24, -0.03, 0.31, 0.21, green, mat.Grass)
	end
end)

local poissons = {
	fish_1 = { 1.43, 0.57, rgb(133, 161, 174), "gardon" }, fish_2 = { 1.53, 0.75, rgb(145, 130, 75), "carpe" },
	fish_3 = { 1.71, 0.49, rgb(140, 156, 145), "truite" }, fish_4 = { 1.46, 0.49, rgb(112, 104, 90), "chat" },
	fish_5 = { 1.83, 0.43, rgb(105, 137, 67), "brochet" }, fish_6 = { 1.54, 0.29, rgb(99, 95, 114), "anguille" },
	fish_7 = { 1.29, 0.71, rgb(221, 157, 58), "doré" }, fish = { 1.39, 0.72, rgb(107, 144, 161), "éventail" },
	salmon = { 1.71, 0.61, rgb(186, 126, 111), "saumon" }, grilled_fish = { 1.50, 0.61, rgb(151, 86, 45), "grillé" },
	smoked_fish = { 1.77, 0.40, rgb(136, 103, 63), "fumé" }, raw_fish = { 1.53, 0.56, rgb(209, 111, 98), "filet" },
}
serie("fish fish_1 fish_2 fish_3 fish_4 fish_5 fish_6 fish_7 salmon grilled_fish smoked_fish raw_fish", function(d, id)
	local p = poissons[id]
	local l, h, c, kind = p[1], p[2], p[3], p[4]
	local thick = h * 0.65 + 0.12
	local x = kind == "filet" and 0 or -0.18
	d.part(kind == "filet" and "Filet cru" or "Corps", V(l, h, thick), C(x, h * 0.56, 0) * rot(0, 0.1, 0),
		c, "ball")
	d.ball(kind == "filet" and "Peau du filet" or "Ventre", l * 0.88, h * 0.55, thick * 0.91, x - 0.04, h * 0.36, -0.04,
		c:Lerp(kind == "filet" and dark or cream, 0.34))
	if kind == "filet" then
		for i = -2, 2 do
			d.line("Strie de coupe", V(i * 0.21, h * 0.58, -thick * 0.45),
				V(i * 0.21 + 0.10, h * (0.95 - math.abs(i) * 0.052), -0.05), 0.063, cream)
		end
		return
	end
	local xt, y = l * 0.32, h * 0.55
	local fin = c:Lerp(kind == "doré" and gold or dark, 0.33)
	d.ball("Pédoncule caudal", 0.55, h * 0.62, thick * 0.62, xt, y, 0.025, c)
	if kind == "anguille" then
		d.part("Queue sinueuse", V(0.72, h * 0.75, 0.32), C(xt + 0.39, y, 0.13) * rot(0, -0.35, 0), fin, "ball")
		d.part("Bout effilé", V(0.50, h * 0.54, 0.24), C(xt + 0.89, y, 0.11) * rot(0, 0.44, 0), c, "ball")
	else
		for _, s in { -1, 1 } do
			d.part("Lobe caudal", V(0.50, h * (kind == "éventail" and 0.72 or 0.48), 0.13),
				C(xt + 0.33, y + s * h * 0.19, 0.045) * rot(0, -0.12, s * 0.36), fin, "wedge")
		end
	end
	local front = x - l * 0.31
	d.ball("Œil", 0.14, 0.14, 0.11, front, y + h * 0.14, -thick * 0.37, cream)
	d.ball("Pupille", 0.07, 0.07, 0.068, front - 0.011, y + h * 0.14, -thick * 0.49, dark)
	d.part("Nageoire dorsale", V(l * (kind == "carpe" and 0.49 or 0.30), h * 0.55, 0.11),
		C(x + 0.09, h * 0.98, 0) * rot(0, 0.79, -0.27), fin, "wedge")
	if kind == "chat" or kind == "brochet" then
		for _, s in { -1, 1 } do
			d.line(kind == "chat" and "Barbillon" or "Mâchoire", V(front, y - 0.09, s * thick * 0.20),
				V(front - 0.31, y - 0.14, s * thick * 0.42), kind == "chat" and 0.055 or 0.135, c)
		end
	elseif kind == "grillé" or kind == "fumé" or kind == "truite" then
		for i = -1, 1 do
			d.line(kind == "truite" and "Tache" or "Trace de cuisson", V(i * 0.29 - 0.18, y, -thick * 0.44),
				V(i * 0.29 - 0.26, y + h * 0.24, -thick * 0.40), 0.062, dark)
		end
	end
end)

serie("arrow arrow_barbed arrow_iron bolt bolt_heavy javelin", function(d, id)
	local heavy, bolt = id == "bolt_heavy", id == "bolt" or id == "bolt_heavy"
	local longue = id == "javelin"
	local long = longue and 2.02 or heavy and 1.40 or bolt and 1.12 or 1.64
	local e = heavy and 0.18 or longue and 0.13 or 0.092
	local pose = C(0, 0.05, 0) * rot(0, 0, -0.61)
	local fer = id == "arrow" and rgb(106, 105, 93) or steel
	d.part("Fût", V(e, long, e), pose, wood, nil, mat.Wood)
	d.part("Pointe", V(heavy and 0.46 or 0.28, 0.38, 0.21), pose * C(0, long * 0.56, 0), fer, "wedge", mat.Metal)
	d.part("Douille", V(0.23, 0.16, 0.21), pose * C(0, long * 0.43, 0), bronze, nil, mat.Metal)
	for _, s in { -1, 1 } do
		local couleur = bolt and rgb(130, 69, 54) or cream
		d.part("Empennage", V(0.22, 0.34, 0.075), pose * C(s * 0.10, -long * 0.35, 0) * rot(0, 0, s * 0.31), couleur, "wedge", mat.Fabric)
		if id == "arrow_barbed" or heavy then
			d.part("Barbelure", V(0.15, 0.23, 0.09), pose * C(s * 0.15, long * 0.54, 0) * rot(0, 0, s * 0.55), steel, "wedge", mat.Metal)
		end
	end
	d.part("Encoche", V(e * 1.45, 0.17, e * 1.31), pose * C(0, -long * 0.47, 0), dark, nil, mat.Wood)
end)

local manches = {
	chisel = { 0.86, 0.22, "ciseau" }, artisan_hammer = { 1.12, 0.17, "marteau" },
	ice_pick = { 1.26, 0.16, "piolet" }, hand_saw = { 0.51, 0.26, "scie" },
	pitchfork = { 1.47, 0.14, "fourche" }, rake = { 1.42, 0.15, "râteau" },
	sickle = { 0.72, 0.19, "faucille" }, throwing_axe = { 1.14, 0.20, "hache" },
	throwing_knife = { 0.59, 0.21, "couteau" }, table_knife = { 0.73, 0.19, "couteau" },
	table_fork = { 0.77, 0.16, "fourchette" }, ladle = { 1.07, 0.15, "louche" },
	spoon = { 0.88, 0.15, "cuillère" }, blade = { 0.39, 0.15, "lame" },
	rolling_pin = { 0.20, 0.17, "rouleau" }, sewing_needle = { 0.29, 0.10, "aiguille" },
	spindle = { 1.17, 0.13, "fuseau" }, lockpick = { 0.60, 0.095, "crochet" },
	hook = { 0.59, 0.12, "hameçon" },
}
serie("chisel artisan_hammer ice_pick hand_saw pitchfork rake sickle throwing_axe throwing_knife table_knife table_fork ladle spoon blade rolling_pin sewing_needle spindle lockpick hook", function(d, id)
	local p = manches[id]
	local l, e, k = p[1], p[2], p[3]
	local nu = k == "lame" or k == "aiguille" or k == "hameçon" or k == "crochet"
	local m, color = nu and mat.Metal or mat.Wood, nu and steel or wood
	local at = C() * rot(0, 0, k == "rouleau" and -pi / 2 or -0.48)
	local y = l * 0.49
	d.part("Manche", V(e, l, e), at, color, "ball", m)
	d.part("Talon", V(e * 1.29, 0.16, e * 1.29), at * C(0, -y + 0.055, 0), color:Lerp(dark, 0.25), "ball", m)
	d.part("Virole", V(0.13, e * 1.36, e * 1.36), at * C(0, y - 0.075, 0) * rot(0,0,pi/2), nu and steel or bronze, "cylinder", mat.Metal)
	local function piece(n, x, h, z, dx, dy, dz, a, form, c, material)
		d.part(n, V(x,h,z), at * C(dx,y+dy,dz) * rot(0,0,a or 0), c or steel, form, material or mat.Metal)
	end
	if k == "marteau" or k == "piolet" or k == "hache" then
		piece("Œil de tête", 0.31, 0.32, 0.28, 0, 0.045, 0)
		piece("Tête", 0.60, k == "piolet" and 0.16 or 0.31, 0.28, -0.16, 0.17, 0, -0.12)
		piece(k == "marteau" and "Face de frappe" or "Tranchant", k == "piolet" and 0.73 or 0.43,
			k == "hache" and 0.56 or 0.22, 0.23, 0.31, 0.13, 0, -0.34, k == "marteau" and nil or "wedge")
		piece("Rivet", 0.13, 0.13, 0.10, 0, 0.14, -0.15, 0, "ball", bronze)
	elseif k == "râteau" or k == "fourche" or k == "fourchette" then
		local t = k == "fourchette" and 0.37 or k == "râteau" and 0.85 or 0.63
		piece("Traverse", t, 0.13, 0.13, 0, 0.093, 0)
		for i = 0, (k == "râteau" and 4 or 3) do
			piece("Dent", 0.073, k == "fourche" and 0.47 or 0.27, 0.09,
				(i - (k == "râteau" and 2 or 1.5)) * t * 0.22, k == "fourche" and 0.32 or 0.23, 0)
		end
	elseif k == "louche" or k == "cuillère" then
		local w = k == "louche" and 0.65 or 0.39
		local c = k == "louche" and steel or wood
		piece("Col", 0.19, 0.26, 0.13, 0, 0.055, 0, 0, nil, c, m)
		piece("Cuilleron", w, w * 0.98, 0.23, 0, w * 0.47, 0.015, 0, "ball", c, k == "louche" and mat.Metal or mat.Wood)
		piece("Rebord", w * 0.86, w * 0.75, 0.075, 0, w * 0.48, -0.093, 0, "ball", c:Lerp(cream, 0.3), m)
		piece("Creux", w * 0.63, w * 0.53, 0.05, 0, w * 0.48, -0.127, 0, "ball", c:Lerp(dark, 0.34), m)
	elseif k == "faucille" or k == "hameçon" or k == "crochet" then
		local rayon = k == "faucille" and 0.60 or k == "hameçon" and 0.32 or 0.21
		for i = 0, 5 do
			local a = pi - i * 0.53
			piece(i == 5 and "Pointe" or "Courbe", k == "faucille" and 0.22 or 0.13, rayon * 0.63, 0.12,
				rayon + rayon * math.cos(a), 0.06 + rayon * math.sin(a), 0, a - pi, i == 5 and "wedge" or nil)
		end
	elseif k == "rouleau" or k == "fuseau" then
		local rayon = k == "rouleau" and 0.52 or 0.78
		piece(k == "rouleau" and "Rouleau" or "Fil", k == "rouleau" and 0.48 or 0.62, rayon, 0.48, 0, rayon * 0.37, 0, 0, "ball", wood:Lerp(cream, 0.56), mat.Wood)
		for i = 0, 2 do
			piece("Collerette", 0.11, 0.50 - i * 0.05, 0.50 - i * 0.05, 0, 0.12 + i * rayon * 0.20, 0, pi / 2, "cylinder", i % 2 == 0 and wood or cream, mat.Wood)
		end
		piece("Bout opposé", 0.14, 0.45, 0.14, 0, rayon + 0.02, 0, 0, "ball", wood, mat.Wood)
	else
		local scie = k == "scie"
		local w, h = scie and 0.48 or k == "lame" and 0.36 or k == "aiguille" and 0.095 or 0.24, scie and 1.25 or 0.78
		piece("Lame", w, h, 0.095, 0, h * 0.44, 0)
		piece("Biseau", w * 0.76, 0.22, 0.095, 0, h * 0.95, 0, pi, "wedge")
		piece("Embase", w * 1.2, 0.13, 0.13, 0, 0.11, 0, 0, nil, bronze)
		if scie then
			for i = 0, 5 do
				piece("Dent de scie", 0.13, 0.21, 0.09, w * 0.53, 0.19 + i * 0.16, 0, -1.01, "wedge")
			end
		else
			piece("Fil du tranchant", w * 0.21, h * 0.85, 0.06, -w * 0.38, h * 0.49, -0.05, 0, nil, cream)
		end
	end
end)

serie("chain weights nasse cork_float fishing_net sieve", function(d, id)
	if id == "chain" then
		for i = -1, 1 do
			local x = i * 0.58
			d.anneau("Maillon", x, 0.28 + i % 2 * 0.02, 0, 0.42, 0.26, 0.139,
				steel:Lerp(dark, (i + 1) * 0.16), mat.Metal, 8, i % 2 == 0)
		end
	elseif id == "weights" then
		d.box("Plateau de transport", 1.50, 0.19, 0.91, 0, 0.09, 0, wood, mat.Wood)
		for i = -1, 1 do
			local r, y = 0.28 + (i + 1) * 0.085, 0.24 + (i + 1) * 0.09
			d.disc("Poids", r, y, i * 0.45, 0.17 + y * 0.48, 0, steel, mat.Metal)
			d.disc("Tête poinçonnée", r * 0.60, 0.11, i * 0.45, 0.17 + y, 0, bronze, mat.Metal)
		end
	elseif id == "cork_float" then
		d.line("Tige du flotteur", V(0, -0.43, 0), V(0, 0.98, 0), 0.09, wood, mat.Wood)
		d.ball("Corps de liège", 0.55, 0.85, 0.53, 0, 0.22, 0, bronze, mat.Wood)
		d.ball("Sommet signal", 0.51, 0.42, 0.50, 0, 0.45, 0, rgb(163, 58, 47))
		for _, y in { 0.02, 0.33, 0.68 } do d.disc("Ligature", 0.44, 0.073, 0, y, 0, cream, mat.Fabric) end
	else
		local trap = id == "nasse"
		local dia, z = trap and 0.59 or 0.75, trap and 0.51 or 0.48
		d.anneau("Cadre", 0, 0.18, 0, dia, z, 0.115, wood, mat.Wood, 8, true)
		if trap then d.anneau("Col de la nasse", 0, 0.85, 0, dia * 0.60, z * 0.63, 0.095, bronze, mat.Wood, 8, true) end
		for i = 0, trap and 7 or 4 do
			local a = 2 * pi * i / 8
			if trap then
				d.line("Brin d'osier", V(dia * math.cos(a), 0.19, z * math.sin(a)),
					V(dia * 0.63 * math.cos(a), 0.86, z * 0.63 * math.sin(a)), 0.084, bronze, mat.Wood)
			else
				local x = (i - 2) * 0.24
				local w = z * (0.98 - 0.10 * math.abs(i - 2))
				d.line("Maille", V(x, 0.17, -w), V(x, 0.17, w), 0.055, cream, mat.Fabric)
				d.line("Maille", V(-dia * 0.70, 0.17, x * 0.71), V(dia * 0.70, 0.17, x * 0.71), 0.055, cream, mat.Fabric)
			end
		end
		if id == "fishing_net" then
			d.line("Manche de l'épuisette", V(-0.65, 0.18, 0), V(-1.31, 0.37, 0), 0.14, wood, mat.Wood)
		end
	end
end)

local textiles = {
	blanket = { 1.22, 0.84, rgb(156, 77, 62), "pli" }, canvas = { 1.41, 0.76, cream, "cadre" },
	cloth = { 1.39, 0.90, rgb(111, 135, 97), "pli" }, dyed_cloth = { 1.51, 0.64, rgb(141, 69, 125), "rouleau" },
	enchanted_cloth = { 1.43, 0.76, rgb(85, 163, 163), "runique" }, fine_cloth = { 1.34, 0.85, rgb(156, 114, 156), "brodé" },
	leather = { 1.25, 0.91, rgb(130, 72, 47), "peau" }, soft_leather = { 1.48, 0.79, rgb(173, 114, 69), "peau" },
	leather_strap = { 1.41, 0.69, rgb(113, 65, 46), "sangle" }, linen = { 1.42, 0.69, rgb(196, 183, 147), "rouleau" },
	pillow = { 1.43, 0.98, rgb(223, 198, 157), "oreiller" }, towel = { 1.35, 0.80, rgb(212, 192, 154), "frange" },
	wool_cloth = { 1.03, 0.98, rgb(185, 190, 160), "épais" }, caparison = { 1.50, 1.04, rgb(139, 60, 56), "frange" },
}
serie("blanket canvas cloth dyed_cloth enchanted_cloth fine_cloth leather soft_leather leather_strap linen pillow towel wool_cloth caparison", function(d, id)
	local p = textiles[id]
	local x, z, c, k = p[1], p[2], p[3], p[4]
	local m = (k == "peau" or k == "sangle") and mat.Leather or mat.Fabric
	local e = k == "oreiller" and 0.42 or k == "épais" and 0.24 or 0.11
	local trim = c:Lerp(k == "frange" and wood or cream, 0.38)
	if k == "rouleau" then
		for i = 0, 2 do
			d.part("Rouleau de tissu", V(x - i * 0.09, 0.35, 0.36), C(i * 0.04, 0.20 + i % 2 * 0.23, i * 0.27 - 0.23) * rot(0, i * 0.10, 0), c:Lerp(cream, i * 0.14), "cylinder", m)
			d.part("Extrémité enroulée", V(0.08, 0.23, 0.23), C(-x * 0.48 + i * 0.075, 0.20 + i % 2 * 0.23, i * 0.27 - 0.27), trim, "cylinder", m)
		end
		return
	end
	if k == "oreiller" then
		d.ball("Garnissage", x, e, z, 0, e * 0.46, 0, c, m)
	else
		d.box(k == "cadre" and "Toile tendue" or "Étoffe principale", x, e, z, 0, e * 0.52, 0, c, m)
	end
	for _, s in { -1, 1 } do
		d.box(k == "cadre" and "Châssis" or "Ourlet", x * 0.94, e * 0.36, 0.10,
			0, e * 0.86, s * z * (k == "oreiller" and 0.41 or 0.45), trim, k == "cadre" and mat.Wood or m)
	end
	for i = -1, 1 do
		local fx, fz = i * x * 0.28, -z * 0.36
		if k == "frange" or k == "sangle" then
			d.box(k == "frange" and "Frange" or "Lanière", 0.13, 0.10, 0.28, fx, e * 0.60, fz - 0.10, trim, m, i * 0.19)
		elseif k == "runique" or k == "brodé" then
			d.box(k == "runique" and "Rune tissée" or "Broderie", 0.22, 0.045, 0.22, fx, e * 1.03, 0.03, trim, m, pi / 4)
		elseif k == "peau" then
			d.part("Lobe de cuir", V(0.49, 0.12, 0.36), C(fx, e * 0.63, fz) * rot(0, i * 0.66, 0), trim, "ball", mat.Leather)
		else
			d.ball(k == "oreiller" and "Pli de la taie" or "Pli", x * 0.33, e * 0.76, z * 0.91,
				fx * 0.90, e * (k == "oreiller" and 0.71 or 0.93), 0, c:Lerp(trim, (i + 1) * 0.28), m)
		end
	end
end)

serie("wood fine_planks heartwood bark peg wool", function(d, id)
	if id == "wool" then
		d.ball("Toison", 1.34, 0.68, 1.08, 0, 0.37, 0, rgb(209, 190, 160), mat.Fabric)
		for i = 0, 7 do
			local a = i * pi / 4
			d.ball("Mèche de laine", 0.51, 0.45, 0.51, math.cos(a) * 0.47, 0.38 + i % 2 * 0.23, math.sin(a) * 0.34,
				cream:Lerp(rgb(246, 235, 217), i % 3 * 0.28), mat.Fabric)
		end
	elseif id == "fine_planks" or id == "bark" or id == "peg" then
		for i = 0, 2 do
			local p = C((i % 2 - 0.5) * 0.24, 0.08 + i * 0.13, 0) * rot(0, i * 0.23, 0)
			d.part(id == "peg" and "Cheville" or id == "bark" and "Lame d'écorce" or "Planche rabotée",
				id == "peg" and V(1.20, 0.20, 0.20) or V(1.51 - i * 0.13, 0.16, 0.63), p,
				wood:Lerp(cream, id == "fine_planks" and 0.45 + i * 0.10 or i * 0.10), id == "peg" and "cylinder" or nil, mat.Wood)
			d.part(id == "peg" and "Pointe de cheville" or id == "bark" and "Fissure" or "Veine",
				id == "peg" and V(0.24, 0.18, 0.18) or V(1.07 - i * 0.11, 0.036, 0.072),
				p * (id == "peg" and C(0.61, 0, 0) * rot(0, 0, -pi / 2) or C(0, 0.084, -0.12)),
				id == "fine_planks" and bronze or dark, id == "peg" and "wedge" or nil, mat.Wood)
		end
	else
		for i = 0, id == "heartwood" and 1 or 2 do
			local y = i == 2 and 0.63 or 0.25
			local z = i == 2 and 0.03 or (i - 0.5) * 0.49
			local x = i * 0.08
			local l, dia = 1.36 - i * 0.12, i == 2 and 0.48 or 0.54
			local pose = C(x, y, z) * rot(0, (i - 1) * 0.09, 0)
			d.part("Écorce", V(l, dia, dia), pose, dark:Lerp(wood, 0.25), "cylinder", mat.Wood)
			for s = -1, 1, 2 do
				d.part("Coupe du rondin", V(0.06, dia * 0.86, dia * 0.86), pose * C(s * l * 0.5, 0, 0), cream:Lerp(wood, 0.45), "cylinder", mat.Wood)
				d.part("Cerne", V(0.04, dia * 0.61, dia * 0.61), pose * C(s * (l * 0.5 + 0.035), 0, 0), bronze, "cylinder", mat.Wood)
			end
			d.part("Cœur", V(0.033, dia * 0.30, dia * 0.30), pose * C(l * 0.5 + 0.055, 0, 0), id == "heartwood" and rgb(143, 54, 47) or wood, "cylinder", mat.Wood)
		end
	end
end)

local plantes = {
	wheat = { 1.40, 3, rgb(185, 137, 62), "épi" }, rye = { 1.50, 2, rgb(152, 120, 66), "épi" },
	barley = { 1.30, 3, rgb(165, 137, 67), "barbe" }, oat = { 1.25, 3, rgb(187, 159, 89), "grappe" },
	hay = { 0.90, 5, rgb(168, 147, 69), "paille" }, straw = { 1.16, 4, rgb(205, 169, 84), "paille" },
	reeds = { 1.50, 3, rgb(137, 103, 59), "massette" }, fiber = { 0.89, 5, rgb(171, 151, 96), "fibre" },
	flax = { 1.19, 3, rgb(101, 123, 173), "fleur" }, flower = { 1.37, 1, rgb(164, 73, 95), "fleur" },
	chamomile = { 1.07, 3, cream, "fleur" }, st_john = { 1.14, 2, gold, "fleur" },
	valerian = { 1.38, 3, rgb(213, 164, 174), "bouquet" }, lavender = { 1.31, 3, rgb(128, 94, 159), "bouquet" },
	mint = { 0.92, 2, rgb(72, 153, 91), "feuille" }, nettle = { 1.15, 2, rgb(77, 120, 64), "dentelé" },
	herbs = { 1.05, 4, rgb(119, 152, 70), "feuille" }, hop = { 1.12, 2, rgb(151, 164, 69), "grappe" },
	rosemary = { 1.27, 2, rgb(86, 128, 90), "aiguilles" }, sage = { 0.99, 2, rgb(115, 136, 107), "feuille" },
	thyme = { 0.84, 4, rgb(114, 142, 83), "aiguilles" },
}
serie("wheat rye barley oat hay straw reeds fiber flax flower chamomile st_john valerian lavender mint nettle herbs hops rosemary sage thyme", function(d, id)
	local p = plantes[id == "hops" and "hop" or id]
	local h, count, c, k = p[1], p[2], p[3], p[4]
	local stems = k == "paille" or k == "fibre" or k == "épi" or k == "barbe" or k == "massette"
	local stem = stems and c:Lerp(wood, 0.24) or green:Lerp(dark, 0.32)
	for i = 1, count do
		local a = (i - (count + 1) / 2) * (count > 3 and 0.24 or 0.38)
		local top = V(a + (count == 1 and 0.15 or 0), h * (0.85 + i % 3 * 0.07), 0.06 * (i % 3 - 1))
		local start = V(i % 2 * 0.04, 0, 0)
		d.line("Tige", start, top, stems and 0.073 or 0.065, stem, mat.Grass)
		if id == "lavender" then
			for j = 0, 4 do
				d.ball("Fleuron de l'épi", 0.14 - j * 0.01, 0.19, 0.17, top.X + (j % 2 - 0.5) * 0.05,
					top.Y + j * 0.078 - 0.11, top.Z, c:Lerp(cream, j % 3 * 0.12))
			end
		elseif k == "fleur" or k == "bouquet" then
			local petals = count == 1 and 6 or k == "bouquet" and 4 or 5
			d.ball("Cœur de fleur", 0.17, 0.16, 0.17, top.X, top.Y, top.Z, id == "st_john" and rgb(187, 102, 45) or gold)
			for j = 1, petals do
				local theta = j * 2 * pi / petals
				local radius = id == "chamomile" and 0.16 or count == 1 and 0.16 or 0.10
				d.ball(k == "fleur" and "Pétale" or "Fleuron", id == "chamomile" and 0.23 or count == 1 and 0.24 or 0.17, 0.16, 0.17,
					top.X + math.cos(theta) * radius, top.Y + (id == "valerian" and 0.04 or math.sin(theta) * 0.10),
					top.Z - 0.025 + (id == "valerian" and math.sin(theta) * 0.09 or 0), c:Lerp(cream, j % 2 * 0.18))
			end
		elseif k == "épi" or k == "barbe" or k == "massette" then
			d.ball(k == "massette" and "Massette" or "Épi", 0.19, k == "massette" and 0.37 or 0.42, 0.17,
				top.X, top.Y + 0.09, top.Z, c)
			if k ~= "massette" then
				for j = 0, 3 do
					local s = j % 2 * 2 - 1
					d.part(k == "barbe" and "Barbe" or "Grain", V(0.10, k == "barbe" and 0.32 or 0.18, 0.10),
						C(top.X + s * 0.075, top.Y + 0.025 + j * 0.052, top.Z - 0.056) * rot(0, 0, -s * 0.41),
						c:Lerp(cream, 0.27), "ball")
				end
			end
		elseif k == "grappe" then
			for j = 0, id == "oat" and 2 or 3 do
				local s = j % 2 * 2 - 1
				local b = V(top.X + s * (0.09 + j * 0.04), top.Y - 0.08 - j * 0.105, top.Z)
				d.line("Pédicelle", V(top.X * 0.9, b.Y - 0.011, top.Z * 0.8), b, 0.05, stem, mat.Grass)
				d.ball("Épillet", id == "hops" and 0.23 or 0.14, 0.19, 0.15, b.X, b.Y, b.Z, c)
			end
		else
			for j = 0, 2 do
				local s, y = (i + j) % 2 * 2 - 1, h * (0.28 + j * 0.21)
				local x = top.X * y / top.Y
				d.part("Feuille", V(k == "aiguilles" and 0.10 or 0.22, k == "fibre" and 0.49 or 0.37, 0.11),
					C(x + s * 0.10, y + 0.06, top.Z * 0.60) * rot(0, i * 0.1, -s * 0.72),
					c:Lerp(cream, j * 0.12), k == "dentelé" and "wedge" or "ball", mat.Grass)
			end
		end
	end
	d.box("Ligature", 0.31, 0.12, 0.22, 0, 0.15, 0, cream:Lerp(wood, 0.37), mat.Fabric)
end)

serie("mushroom glow_mushroom rare_mushroom truffle", function(d, id)
	local rare, glow = id == "rare_mushroom", id == "glow_mushroom"
	if id == "truffle" then
		d.ball("Truffe", 1.26, 0.59, 1.06, 0, 0.34, 0, rgb(63, 49, 50))
		for i = 0, 7 do
			local a = i * 2.39
			d.ball("Verrue de la truffe", 0.34, 0.30, 0.28, math.cos(a) * 0.43, 0.34 + i % 2 * 0.16,
				math.sin(a) * 0.38, rgb(70 + i * 4, 53 + i * 3, 54 + i * 3))
		end
		return
	end
	local c = glow and rgb(86, 182, 165) or rare and rgb(139, 78, 159) or rgb(161, 76, 55)
	for i = 1, rare and 2 or 1 do
		local x, h, w = i == 1 and 0 or 0.59, i == 1 and 0.69 or 0.47, i == 1 and 1.18 or 0.69
		d.ball("Pied", w * 0.33, h, w * 0.33, x, h * 0.47, 0, cream)
		d.ball("Lamelles", w * 0.93, 0.17, w * 0.91, x, h * 0.93, 0, c:Lerp(cream, 0.53))
		d.ball("Chapeau", w, glow and 0.50 or 0.37, w * 0.93, x, h * 1.14, 0, c)
		for j = 0, (i == 1 and 3 or 1) do
			local a = j * 2.39
			d.ball(glow and "Lueur du chapeau" or "Moucheture", 0.20, 0.09, 0.17,
				x + math.cos(a) * w * 0.27, h * 1.15 + (glow and 0.20 or 0.14), math.sin(a) * w * 0.25,
				glow and rgb(159, 223, 190) or cream, glow and mat.Neon or nil)
		end
	end
end)

serie("wicker_basket veg_basket fruit_crate rations fisher_platter lord_banquet village_feast", function(d,id)
	local caisse = id == "fruit_crate"
	local festival = id == "village_feast" or id == "lord_banquet" or id == "fisher_platter" or id == "rations"
	local c = caisse and wood or bronze
	local base = festival and 0.14 or 0.48
	d.box(festival and "Plateau" or "Fond", 1.38, 0.16, 1.02, 0, 0.08, 0, c, mat.Wood)
	for _, s in { -1, 1 } do
		d.box("Long pan", 1.48, base, 0.15, 0, base * 0.57, 0.50 * s, c, mat.Wood)
		d.box("Petit pan", 0.15, base, 1.02, 0.67 * s, base * 0.57, 0, wood, mat.Wood)
	end
	if id == "wicker_basket" or id == "veg_basket" then
		d.anneau("Anse d'osier", 0, 0.43, 0, 0.64, 0.70, 0.13, bronze, mat.Wood, 10)
	elseif caisse then
		for i = -1, 1 do
			d.box("Traverse clouée", 0.14, 0.46, 0.09, i * 0.51, 0.25, -0.58, bronze, mat.Wood)
		end
	end
	if id == "wicker_basket" then return end
	for i = 1, festival and 6 or 7 do
		local a = i * 2.39
		local x, y, z = math.cos(a) * 0.44, (festival and 0.27 or 0.47) + i % 2 * 0.05, math.sin(a) * 0.26
		local kind = id == "fisher_platter" and "Poisson" or festival and "Portion" or caisse and "Fruit" or "Légume"
		local c1 = id == "fisher_platter" and steel or id == "rations" and cream or i % 3 == 0 and green or i % 2 == 0 and gold or rgb(179, 65, 51)
		d.part(kind, V(festival and 0.58 or 0.33, 0.31, 0.35), C(x, y, z) * rot(0, a, 0), c1, "ball")
		if id ~= "rations" and (id ~= "veg_basket" or i <= 3) then
			d.ball("Garniture", 0.14, 0.11, 0.15, x, y + 0.14, z, i % 2 == 0 and cream or green)
		end
	end
end)

local recipients = {
	bottle = { 0.73, 1.23, rgb(111, 158, 152), "verre" },
	message_bottle = { 0.78, 1.16, rgb(111, 159, 159), "message" },
	cider = { 0.92, 0.98, rgb(163, 101, 49), "grès" }, honey = { 1.03, 0.73, gold, "miel" },
	milk = { 0.96, 1.12, cream, "lait" }, ink = { 0.74, 0.59, rgb(62, 58, 90), "encre" },
	inkwell = { 0.90, 0.54, rgb(57, 58, 74), "encrier" }, perfume = { 0.65, 0.87, rgb(158, 100, 153), "parfum" },
	gourd = { 0.97, 0.96, rgb(156, 135, 64), "gourde" }, waterskin = { 1.28, 0.92, wood, "outre" },
	pot = { 1.35, 0.82, clay, "pot" }, bowl = { 1.51, 0.54, wood, "bol" },
	plate = { 1.57, 0.23, cream, "plat" }, wood_plate = { 1.46, 0.31, wood, "plat" },
	decorated_ceramic = { 0.95, 1.05, rgb(162, 99, 68), "peint" }, old_vase = { 1.08, 1.14, rgb(112, 141, 130), "ancien" },
	amphora = { 1.03, 1.21, clay, "amphore" }, jug = { 1.19, 1.02, rgb(167, 97, 63), "cruche" },
}
serie("bottle message_bottle cider honey milk ink inkwell perfume gourd waterskin pot bowl plate wood_plate decorated_ceramic old_vase amphora jug", function(d, id)
	local p = recipients[id]
	local w, h, c, k = p[1], p[2], p[3], p[4]
	local verre = k == "verre" or k == "encre" or k == "encrier" or k == "parfum" or k == "message"
	local ouvert = k == "pot" or k == "bol" or k == "plat" or k == "peint" or k == "ancien"
		or k == "encrier" or k == "amphore" or k == "cruche"
	local low = k == "bol" or k == "plat"
	local m = verre and mat.Glass or k == "outre" and mat.Leather or (id == "bowl" or id == "wood_plate") and mat.Wood or mat.CeramicTiles
	local cou = low and w * 0.93 or k == "pot" and w * 0.88 or k == "miel" and w * 0.69 or w * 0.46
	local rimY = h + (low and -0.02 or 0.075)
	local a = d.ball("Panse", w, h * 1.02, k == "outre" and w * 0.58 or w * 0.89, 0, h * 0.49, 0, c, m)
	if verre and (k == "verre" or k == "message") then a.Transparency = 0.32 end
	d.disc("Pied", w * 0.70, 0.15, 0, 0.08, 0, c:Lerp(dark, 0.24), m)
	d.disc("Col", cou, h * 0.32 + 0.05, 0, rimY - 0.1, 0, c, m)
	d.disc("Lèvre", cou * 1.14, 0.12, 0, rimY, 0, c:Lerp(cream, 0.24), m)
	d.disc(ouvert and "Ouverture" or "Bouchon", cou * 0.81, ouvert and 0.035 or 0.16,
		0, rimY + 0.067, 0, ouvert and c:Lerp(dark, 0.53) or wood, ouvert and m or mat.Wood)
	if low then
		d.disc("Fond tourné", cou * 0.59, 0.026, 0, rimY + 0.085, 0, c:Lerp(cream, 0.20), m)
	elseif k == "outre" then
		d.line("Bandoulière", V(-w * 0.43, h * 0.55, 0), V(0, h * 1.14, 0.06), 0.12, cream, mat.Leather)
		d.ball("Couture", w * 0.91, h * 0.65, 0.12, 0, h * 0.50, -w * 0.25, c:Lerp(dark, 0.4), mat.Leather)
	elseif k == "lait" or k == "grès" or k == "gourde" or k == "amphore" or k == "cruche" then
		for _, cote in k == "amphore" and { -1, 1 } or { 1 } do
			for _, s in { 0, 1 } do
				d.box("Attache de l'anse", 0.31, 0.12, 0.16, cote * w * 0.44, h * (0.39 + s * 0.40), 0, c, m)
			end
			d.box("Anse", 0.09, h * 0.46, 0.18, cote * w * 0.57, h * 0.59, 0, c:Lerp(cream, 0.19), m)
		end
		if k == "cruche" then
			d.part("Bec", V(0.27, 0.16, 0.52), C(-0.25, rimY, -0.21) * rot(0,0.72,0), c, "wedge", m)
		end
	else
		d.ball(verre and "Reflet du verre" or "Médaillon", w * 0.38, h * 0.38, w * 0.16, -w * 0.15,
			h * 0.51, -w * 0.39, c:Lerp(cream, 0.47), verre and mat.Glass or m)
		if k == "miel" or k == "message" then
			d.box(k == "miel" and "Étiquette de miel" or "Rouleau dans la bouteille", w * 0.32, h * 0.38, 0.065,
				w * 0.14, h * 0.50, -w * 0.39, cream, mat.Fabric)
		elseif k == "peint" or k == "ancien" then
			d.disc("Frise", w * 0.98, 0.09, 0, h * 0.49, 0, c:Lerp(gold, 0.53), m)
		end
	end
end)

serie("compass old_compass pocket_mirror spyglass", function(d, id)
	local old, mirror = id == "old_compass", id == "pocket_mirror"
	if id == "spyglass" then
		local at = C() * rot(0, 0, -0.65)
		for i = 0, 2 do
			local y, r = i * 0.44 - 0.40, 0.77 - i * 0.17
			d.part("Tube télescopique", V(0.52, r, r), at * C(0, y, 0) * rot(0, 0, pi / 2),
				i % 2 == 0 and bronze or dark, "cylinder", i == 1 and mat.Leather or mat.Metal)
			d.part("Bague de tube", V(0.085, r * 1.07, r * 1.07), at * C(0, y + 0.23, 0) * rot(0, 0, pi / 2), gold, "cylinder", mat.Metal)
		end
		d.part("Lentille", V(0.045, 0.64, 0.64), at * C(0, -0.67, 0) * rot(0,0,pi/2), rgb(112, 154, 180), "cylinder", mat.Glass)
		return
	end
	d.disc("Boîtier", 1.36, 0.22, 0, 0.11, 0, old and wood or bronze, old and mat.Wood or mat.Metal)
	d.disc("Lunette", 1.32, 0.10, 0, 0.235, 0, gold, mat.Metal)
	d.disc(mirror and "Tain" or "Cadran", 1.11, 0.06, 0, 0.292, 0, mirror and rgb(163, 191, 194) or cream, mirror and mat.Glass or nil)
	if mirror then
		d.line("Manche", V(-0.50, 0.14, 0.31), V(-1.08, 0.14, 0.67), 0.17, bronze, mat.Metal)
		d.ball("Pommeau", 0.26, 0.22, 0.26, -1.08, 0.14, 0.67, gold, mat.Metal)
		d.box("Éclat du miroir", 0.14, 0.019, 0.44, 0.15, 0.328, -0.12, rgb(209, 229, 226), mat.Glass, 0.52)
	else
		for i = 0, 3 do
			local a = i * pi / 2
			d.box("Point cardinal", 0.08, 0.04, 0.15, 0.43 * math.sin(a), 0.328, 0.43 * math.cos(a), dark, nil, a)
		end
		local a = old and -0.54 or 0.27
		d.box("Aiguille nord", 0.13, 0.065, 0.37, math.sin(a) * 0.17, 0.342, math.cos(a) * 0.17,
			rgb(145, 48, 51), mat.Metal, a)
		d.box("Aiguille sud", 0.12, 0.063, 0.35, -math.sin(a) * 0.16, 0.342, -math.cos(a) * 0.16, steel, mat.Metal, a)
		if old then
			d.box("Charnière", 0.24, 0.24, 0.30, 0, 0.23, 0.62, bronze, mat.Metal)
			d.part("Couvercle rabattu", V(0.15, 1.17, 1.17), C(0, 0.37, 0.79) * rot(0.6, 0, pi / 2),
				wood, "cylinder", mat.Wood)
		end
	end
end)

serie("guard_badge sheriff_badge royal_seal seal wax_seal champion_ribbon ribbon fair_ticket", function(d, id)
	local wax = id == "seal" or id == "wax_seal" or id == "royal_seal"
	local ruban = id == "champion_ribbon" or id == "ribbon" or id == "fair_ticket"
	local teint = id == "sheriff_badge" and gold or wax and rgb(145, 57, 47) or ruban and rgb(139, 62, 79) or steel
	local m = wax and mat.SmoothPlastic or mat.Metal
	local w = id == "royal_seal" and 1.18 or id == "sheriff_badge" and 1.02 or 0.93
	d.disc("Médaillon", w, 0.20, 0, 0.13, 0, teint, m)
	d.disc("Listel", w * 0.80, 0.09, 0, 0.245, 0, teint:Lerp(cream, 0.25), m)
	local n = id == "sheriff_badge" and 6 or wax and 3 or 5
	for i = 0, n - 1 do
		local a = i * pi * 2 / n
		d.part(wax and "Empreinte" or "Branche d'insigne", V(0.16, 0.10, wax and 0.27 or 0.43),
			C(math.sin(a) * w * 0.40, 0.264, math.cos(a) * w * 0.40) * rot(0, a, 0),
			teint:Lerp(ruban and gold or dark, 0.27), wax and nil or "wedge", m)
	end
	if ruban then
		for _, side in { -1, 1 } do
			d.box("Pan de ruban", 0.30, 0.13, 0.86, side * 0.18, 0.10, 0.49, teint, mat.Fabric, side * 0.21)
		end
	elseif wax then
		d.box(id == "royal_seal" and "Fleuron royal" or "Poinçon", 0.14, 0.05, 0.48, 0, 0.31, 0, teint:Lerp(dark, 0.31))
	elseif id == "guard_badge" then
		d.box("Écu de la garde", 0.37, 0.065, 0.44, 0, 0.316, 0, bronze, mat.Metal, pi / 4)
	end
end)

serie("artifact relic ruin_piece frozen_heart mineral_heart wisp_dust mineral_powder pearl", function(d, id)
	local pale = rgb(170, 173, 156)
	local ton = id == "frozen_heart" and rgb(104, 167, 196) or id == "mineral_heart" and rgb(98, 128, 103)
		or id == "wisp_dust" and rgb(125, 186, 194) or id == "pearl" and rgb(204, 190, 159) or pale
	local powder = id == "wisp_dust" or id == "mineral_powder"
	local stone = id == "ruin_piece" or id == "relic" or id == "mineral_heart"
	local w = id == "artifact" and 1.07 or stone and 1.38 or 1.23
	d.box("Piètement", w, 0.19, w * 0.75, 0, 0.09, 0, stone and pale:Lerp(dark, 0.33) or wood, stone and mat.Slate or mat.Wood, 0.22)
	if powder then
		d.disc("Coupelle", 1.12, 0.18, 0, 0.23, 0, clay, mat.CeramicTiles)
		for i = 0, 6 do
			local a = i * 2.39
			d.ball(id == "wisp_dust" and "Lueur de la poussière" or "Grain", 0.24, 0.19, 0.19,
				math.sin(a) * 0.40, 0.33 + i % 2 * 0.05, math.cos(a) * 0.32,
				ton:Lerp(cream, i % 3 * 0.2), id == "wisp_dust" and i % 2 == 0 and mat.Neon or nil)
		end
	elseif id == "pearl" then
		d.ball("Nacre", 0.91, 0.91, 0.91, 0, 0.60, 0, ton, mat.Glass)
		for i = -1, 1 do
			d.ball("Lobe du coquillage", 0.58, 0.30, 0.76, i * 0.26, 0.24, 0.09, cream)
		end
		d.ball("Reflet", 0.27, 0.22, 0.14, -0.22, 0.78, -0.31, rgb(243, 233, 208), mat.Glass)
	elseif id == "artifact" or id:find("heart") then
		d.ball("Noyau", w * 0.84, 0.85, 0.75, 0, 0.62, 0, ton, id == "mineral_heart" and mat.Slate or mat.Glass)
		for i = 0, 4 do
			local a = 2 * pi * i / 5
			d.part(id == "artifact" and "Griffe de la monture" or "Éclat du noyau",
				V(0.24, 0.69 + i % 2 * 0.17, 0.23), C(math.cos(a) * 0.39, 0.63, math.sin(a) * 0.35) * rot(0, -a, -0.31),
				ton:Lerp(id == "artifact" and gold or cream, 0.37), "wedge", id == "artifact" and mat.Metal or mat.Glass)
		end
	else
		d.part("Fragment taillé", V(w * 0.80, 1.08, 0.49), C(0.05, 0.57, 0) * rot(0, 0.23, 0.14), ton, "wedge", mat.Slate)
		d.part("Cassure latérale", V(0.41, 0.67, 0.49), C(-0.32, 0.55, 0.07) * rot(0, -0.37, -0.41), ton:Lerp(dark, 0.24), "corner", mat.Slate)
		for i = -1, 1 do
			d.box("Entaille", 0.065, 0.37, 0.06, i * 0.18, 0.57 - i * 0.12, -0.24, id == "relic" and bronze or ton:Lerp(dark, 0.39), mat.Slate, -0.21)
		end
	end
end)

serie("ancient_scale black_scale bone horn rare_horn tooth stinger", function(d, id)
	local c = id == "black_scale" and rgb(66, 67, 82) or id == "ancient_scale" and rgb(82, 143, 133)
		or id == "stinger" and rgb(117, 81, 95) or id == "rare_horn" and rgb(183, 129, 72) or cream
	if id:find("_scale") then
		d.ball("Écaille", 1.16, 0.71, 0.32, 0, 0, 0, c, mat.Leather)
		for i = -2, 2 do
			d.part("Nervure de l'écaille", V(0.17, 0.72 - math.abs(i) * 0.08, 0.15), C(i * 0.18, 0.02, -0.13) * rot(0, 0, i * -0.17),
				c:Lerp(cream, (3 - math.abs(i)) * 0.13), "wedge", mat.Leather)
		end
		d.ball("Talon de l'écaille", 0.40, 0.24, 0.19, 0, -0.34, 0, c:Lerp(dark, 0.3))
		return
	end
	local os = id == "bone"
	local scale = id == "tooth" and 0.65 or id == "rare_horn" and 1.17 or 1
	local m = id == "stinger" and mat.Leather or mat.SmoothPlastic
	for i = 0, 5 do
		local r = (os and 0.29 or 0.51 - 0.069 * i) * scale
		d.part(os and "Diaphyse" or "Courbure", V(r, 0.30 * scale, r),
			C((os and 0.01 * i or (id == "tooth" and 0.018 or 0.029) * i * i) * scale, i * 0.20 * scale, 0)
				* rot(0, 0, -i * (os and 0.02 or 0.18)),
			c:Lerp(dark, i % 2 * 0.16), "ball", m)
	end
	if os then
		for i = -1, 1, 2 do
			d.ball("Articulation", 0.26, 0.25, 0.26, i * 0.12, i < 0 and 0 or 1.00, 0, cream)
		end
	else
		d.ball(id == "tooth" and "Racine" or "Base annelée", 0.53 * scale, 0.22, 0.53 * scale, 0, 0.035, 0, c:Lerp(dark, 0.32), m)
		if id == "rare_horn" then
			d.disc("Cerclage de corne", 0.58, 0.13, 0.005, 0.12, 0, gold, mat.Metal)
		end
	end
end)

serie("bridle halter leash pet_harness spiked_collar stirrups saddle_leather saddle_race saddle_war", function(d, id)
	local selle = id:find("saddle") ~= nil
	local iron = id == "saddle_war" or id == "stirrups"
	local c = iron and dark or rgb(134, 74, 48)
	if selle then
		local long = id == "saddle_race" and 1.43 or 1.12
		d.ball("Assise", 0.90, 0.43, long, 0, 0.53, 0, c, mat.Leather)
		for _, s in { -1, 1 } do
			d.part("Quartier", V(0.56, iron and 0.73 or 0.61, long * 0.89),
				C(s * 0.34, 0.37, 0.035) * rot(0,0,-s * 0.41), c:Lerp(cream, 0.13), "ball", mat.Leather)
			d.box("Sangle", 0.15, 0.51, 0.11, s * 0.52, 0.22, -0.04, bronze, mat.Leather)
		end
		d.ball("Pommeau", 0.73, 0.33, 0.31, 0, 0.66, -long * 0.39, iron and steel or wood, iron and mat.Metal or mat.Wood)
		d.ball("Troussequin", 0.68, 0.32, 0.32, 0, 0.65, long * 0.39, iron and steel or wood, iron and mat.Metal or mat.Wood)
		if iron then d.box("Plaque frontale", 0.50, 0.17, 0.10, 0, 0.64, -long * 0.51, steel, mat.Metal) end
	else
		local k = id == "leash" and 0.72 or id == "stirrups" and 0.62 or 0.51
		local z = id == "pet_harness" and 0.28 or 0.08
		d.anneau("Lanière", 0, 0.55, 0, k, id == "stirrups" and 0.44 or 0.52, iron and 0.16 or 0.115,
			iron and steel or c, iron and mat.Metal or mat.Leather, 10)
		if id == "leash" then
			d.line("Longe", V(k * 0.88, 0.28, 0), V(k + 0.48, 0.09, z), 0.12, c, mat.Leather)
			d.anneau("Mousqueton", k + 0.55, 0.12, z, 0.13, 0.19, 0.085, steel, mat.Metal, 7)
		elseif id == "spiked_collar" then
			for i = 0, 5 do
				local a = i * pi / 3
				d.part("Clou", V(0.19, 0.19, 0.14), C((k + 0.03) * math.cos(a), 0.55 + 0.52 * math.sin(a), -0.10) * rot(0,0,a), steel, "wedge", mat.Metal)
			end
		else
			d.box(id == "stirrups" and "Semelle d’étrier" or "Muserolle", k * 1.65, 0.16, 0.19,
				0, id == "stirrups" and 0.23 or 0.39, -z * 0.4, iron and steel or c:Lerp(cream, 0.25), iron and mat.Metal or mat.Leather)
			if id == "bridle" or id == "pet_harness" then
				d.line("Lanière de traverse", V(-k * 0.92, 0.43, 0), V(k * 0.94, 0.58, 0), 0.12, c, mat.Leather)
			end
			d.ball("Boucle", 0.20, 0.20, 0.13, k * 0.87, 0.72, 0, bronze, mat.Metal)
		end
	end
end)

serie("truffle_cheese aged_cheese truffle_omelette damascus_steel dried_petals spice salt mortar_pestle incense", function(d, id)
	if id:find("cheese") then
		local vieux = id == "aged_cheese"
		local c = vieux and rgb(206, 157, 68) or rgb(238, 195, 89)
		d.disc("Croûte du fromage", 1.42, vieux and 0.61 or 0.37, 0, 0.23, 0, c:Lerp(wood, 0.35))
		d.disc("Coupe du fromage", 1.27, 0.12, 0, vieux and 0.56 or 0.44, 0, c)
		for i = 0, 5 do
			local a = i * pi / 3
			d.ball(vieux and "Alvéole" or "Éclat de truffe", 0.074 + i % 2 * 0.07, 0.054, 0.11,
				math.cos(a) * 0.34, vieux and 0.623 or 0.50, math.sin(a) * 0.34, vieux and rgb(166, 109, 41) or dark)
		end
	elseif id == "truffle_omelette" then
		formes.omelette(d, "omelette")
		for i = -2, 2 do
			d.ball("Lamelle de truffe", 0.12, 0.085, 0.17, i * 0.17, 0.40 - 0.02 * math.abs(i), 0.09, dark)
		end
	elseif id == "damascus_steel" then
		formes.steel(d, "steel")
		for i = -2, 2 do
			d.box("Fil damassé", 1.05 - math.abs(i) * 0.09, 0.03, 0.038, 0, 0.162, i * 0.09,
				steel:Lerp(dark, i % 2 * 0.16), mat.Metal, i * 0.11)
		end
	else
		local c = id == "dried_petals" and rgb(147, 83, 113) or id == "spice" and rgb(171, 69, 44) or cream
		local bol = id == "mortar_pestle"
		local t = d.disc("Pied de coupelle", 0.89, 0.19, 0, 0.085, 0, bol and steel or wood, bol and mat.Slate or mat.Wood)
		d.ball("Coupelle", 1.28, bol and 0.52 or 0.32, 1.12, 0, 0.23, 0, t.Color, t.Material)
		d.disc("Lèvre", 1.26, 0.13, 0, bol and 0.46 or 0.34, 0, t.Color:Lerp(cream, 0.30), t.Material)
		d.disc("Contenu", 1.06, 0.06, 0, bol and 0.53 or 0.39, 0, bol and steel:Lerp(dark, 0.3) or c)
		if bol then
			d.part("Pilon", V(0.23, 0.70, 0.22), C(0.18, 0.75, 0.12) * rot(0, 0, -0.30), steel, "ball", mat.Slate)
		end
		for i = -1, 1 do
			if id == "incense" then
				d.line("Bâton d’encens", V(i * 0.16, 0.35, 0), V(i * 0.37, 1.25 - math.abs(i) * 0.09, i * 0.13), 0.073, wood, mat.Wood)
				d.ball("Braise", 0.12, 0.11, 0.09, i * 0.37, 1.25 - math.abs(i) * 0.09, i * 0.13, rgb(219, 123, 65))
			elseif bol then
				d.ball("Mouture", 0.17, 0.06, 0.16, i * 0.16, 0.57, -0.14, bronze)
			else
				d.ball(id == "dried_petals" and "Pétale froissé" or "Grain", 0.29, 0.14, 0.27, i * 0.22, 0.46, i % 2 * 0.10 - 0.10, c:Lerp(wood, (i+1) * 0.15))
			end
		end
	end
end)

serie("banniere kite music_sheet paper price_tags map_fragment", function(d, id)
	if id == "banniere" or id == "kite" then
		local banniere = id == "banniere"
		local c = banniere and rgb(143, 59, 57) or rgb(85, 124, 155)
		local at = C(0, 0.79, 0)
		d.part("Toile", banniere and V(0.83, 0.94, 0.10) or V(0.92, 0.92, 0.09), at * rot(0, 0, banniere and 0 or pi / 4), c, nil, mat.Fabric)
		d.box(banniere and "Hampe" or "Longeron", 0.11, banniere and 1.51 or 1.30, 0.10,
			banniere and -0.40 or 0, banniere and 0.73 or 0.79, 0, wood, mat.Wood)
		d.box("Traverse", 0.96, 0.10, 0.11, 0, banniere and 1.25 or 0.79, 0, wood, mat.Wood)
		d.ball("Pommeau", 0.18, 0.17, 0.17, banniere and -0.40 or 0, 1.49, 0, gold, mat.Metal)
		d.part("Motif", V(0.33, 0.33, 0.07), at * C(0, 0.10, -0.049) * rot(0, 0, pi / 4), gold, nil, mat.Fabric)
		d.line(banniere and "Galon" or "Queue", V(0, 0.43, 0), V(banniere and 0.39 or 0.32, banniere and 0.40 or 0.12, 0), 0.10, cream, mat.Fabric)
	else
		local c = id == "map_fragment" and rgb(191, 160, 110) or cream
		for i = 0, 2 do
			d.box("Feuille", 1.38 - i * 0.09, 0.058, 0.88, i * 0.10, 0.10 + i * 0.032, 0, c:Lerp(wood, i * 0.07), nil, i * 0.18)
		end
		for i = -1, 1 do
			local n = id == "map_fragment" and "Tracé" or id == "music_sheet" and "Portée" or id == "price_tags" and "Numéro" or "Bord du papier"
			d.box(n, id == "paper" and 0.29 or 0.62, 0.037, 0.048, 0.02 + i * 0.11,
				0.21, i * 0.19, id == "paper" and c:Lerp(wood, 0.30) or dark, nil, id == "map_fragment" and i * 0.49 or 0.24)
		end
	end
end)

serie("lost_crown horn_call trumpet drum", function(d, id)
	if id == "lost_crown" then
		d.anneau("Cercle ébréché", 0, 0.22, 0, 0.57, 0.54, 0.16, wood:Lerp(gold, 0.46), mat.Metal, 10, true)
		for i = 0, 4 do
			local a = i * 2 * pi / 5
			d.part("Fleuron brisé", V(0.24, 0.44 + (i % 3) * 0.09, 0.19),
				C(math.cos(a) * 0.55, 0.43, math.sin(a) * 0.51) * rot(0, a, (i - 2) * 0.16), bronze, "wedge", mat.Metal)
		end
		d.ball("Cabochon terni", 0.23, 0.20, 0.16, 0, 0.24, -0.50, rgb(120, 67, 77), mat.Glass)
	elseif id == "drum" then
		d.disc("Fût", 1.07, 0.76, 0, 0.38, 0, wood, mat.Wood)
		for _, y in { 0.08, 0.76 } do d.disc("Peau tendue", 1.13, 0.11, 0, y, 0, cream, mat.Leather) end
		for i = 0, 7 do
			local a = i * pi / 4
			d.line("Tirant", V(0.53 * math.cos(a), 0.11, 0.53 * math.sin(a)),
				V(0.53 * math.cos(a + 0.24), 0.73, 0.53 * math.sin(a + 0.24)), 0.075, bronze, mat.Fabric)
		end
		d.line("Baguette", V(-0.39, 0.842, 0.17), V(0.63, 0.84, -0.24), 0.10, wood, mat.Wood)
	else
		local trompette = id == "trumpet"
		local c, m = trompette and gold or cream, trompette and mat.Metal or mat.SmoothPlastic
		local r = trompette and 0.43 or 0.62
		local path = { V(-0.61, 0.41, 0), V(-0.48, 0.20, 0), V(-0.22, 0.14, 0),
			V(0.12, 0.19, 0), V(0.45, 0.38, 0), V(0.65, 0.51, 0) }
		for i = 1, #path - 1 do
			local a, b = path[i], path[i+1]
			local width = trompette and (0.12 + i * 0.043) or (0.14 + i * 0.061)
			d.line("Tube", a, b, width, c:Lerp(wood, 0.16), m)
		end
		d.part("Pavillon", V(0.24, r, r), C(0.60, 0.48, 0) * rot(0, 0, 0.49), c, "cylinder", m)
		d.part("Ouverture", V(0.068, r * 0.79, r * 0.79), C(0.72, 0.54, 0) * rot(0, 0, 0.49), dark, "cylinder", m)
		d.ball("Embouchure", 0.15, 0.18, 0.15, -0.63, 0.44, 0, bronze, mat.Metal)
		if trompette then
			d.line("Retour du tube", V(-0.45, 0.19, 0.07), V(0.34, 0.28, 0.24), 0.094, c, m)
		end
	end
end)

local function planches(d, x, y, z, h, l, p, n, vertical)
	for i = 1, n do
		local a = (i - (n + 1) / 2) / n
		d.box("Planche", vertical and l / n * 1.009 or l, h, vertical and p or p / n * 1.009,
			x + (vertical and a * l or 0), y, z + (vertical and 0 or a * p), wood:Lerp(cream, i % 3 * 0.11), mat.WoodPlanks)
	end
end

serie("floor floor2 roof roof2 stairs wall wall2 wall_brick wall_stone wall_window wall2_window wall_door door fence", function(d, id)
	local haut = id == "wall2" or id == "wall2_window"
	local fenetre = id:find("window") ~= nil
	local porte = id == "wall_door" or id == "door"
	if id == "floor" or id == "floor2" then
		planches(d, 0, 0.19, 0, 0.13, 1.58, 1.31, 5, false)
		for _, s in { -1, 1 } do d.box("Solive", 0.16, 0.17, 1.30, s * 0.54, 0.076, 0, dark, mat.Wood) end
		if id == "floor2" then d.box("Pièce de rive", 1.61, 0.17, 0.10, 0, 0.17, -0.62, wood, mat.Wood) end
	elseif id == "roof" or id == "roof2" or id == "stairs" then
		local toit = id ~= "stairs"
		local c = toit and rgb(175, 141, 74) or wood
		for i = 1, 5 do
			local y = i * (toit and 0.084 or 0.174)
			d.part(toit and "Rang de chaume" or "Marche", V(1.42, toit and 0.13 or 0.19, 0.30),
				C(0, y, 0.58 - i * 0.22) * rot(toit and -0.32 or 0, 0, 0),
				c:Lerp(cream, i % 3 * 0.13), nil, toit and mat.Fabric or mat.Wood)
		end
		for _, s in { -1, 1 } do
			d.line("Longeron", V(s * 0.49, 0.03, 0.51), V(s * 0.49, toit and 0.37 or 0.82, -0.48), 0.15, dark, mat.Wood)
		end
		if id == "roof2" then d.box("Faîtière", 1.54, 0.13, 0.24, 0, 0.51, -0.53, c, mat.Fabric) end
	elseif id == "wall_stone" or id == "wall_brick" then
		local brique = id == "wall_brick"
		local c = brique and rgb(149, 75, 54) or rgb(122, 125, 116)
		d.box("Mortier", 1.47, 1.14, 0.32, 0, 0.57, 0, c:Lerp(cream, 0.25), mat.Slate)
		for r = 0, 3 do
			for i = -1, 1 do
				d.box(brique and "Brique" or "Moellon", 0.45, 0.239, 0.17, i * 0.48 + (r % 2 - 0.5) * 0.18,
					r * 0.282 + 0.14, -0.19, c:Lerp(cream, (i + r + 1) % 3 * 0.13), brique and mat.Brick or mat.Slate)
			end
		end
	else
		local h = haut and 1.72 or id == "fence" and 1.05 or 1.47
		for _, s in { -1, 1 } do d.box("Montant", 0.15, h, 0.24, s * 0.68, h / 2, 0, dark, mat.Wood) end
		if fenetre or porte then
			local w = fenetre and 0.48 or 0.34
			for _, s in { -1, 1 } do planches(d, s * (0.665 - w / 2), h / 2, 0, h * 0.96, w, 0.17, 2, true) end
			d.box("Linteau", 1.46, 0.16, 0.26, 0, h * 0.92, 0, wood, mat.Wood)
			if fenetre then
				d.box("Appui", 1.03, 0.13, 0.32, 0, h * 0.43, 0, bronze, mat.Wood)
				d.box("Allège", 0.86, h * 0.40, 0.16, 0, h * 0.20, 0, wood, mat.WoodPlanks)
				d.box("Croisillon", 0.08, h * 0.48, 0.13, 0, h * 0.68, 0, wood, mat.Wood)
			elseif id == "door" then
				planches(d, 0, h * 0.44, -0.05, h * 0.84, 0.69, 0.15, 4, true)
				d.ball("Poignée", 0.14, 0.14, 0.13, 0.21, h * 0.47, -0.16, bronze, mat.Metal)
			end
		elseif id == "fence" then
			for i = -1, 1 do d.box("Lisse", 1.50, 0.12, 0.13, 0, 0.21 + (i + 1) * 0.30, 0, wood, mat.Wood) end
			d.box("Renfort", 0.12, 0.67, 0.17, 0, 0.52, 0, bronze, mat.Wood)
		else
			planches(d, 0, h / 2, 0, h * 0.9, 1.37, 0.14, 5, true)
			d.box("Traverse", 1.46, 0.15, 0.15, 0, h * 0.23, -0.084, wood, mat.Wood)
		end
	end
end)

serie("bed chair garden_bench table_wood workbench shelf stall tannery trough loom", function(d, id)
	local chaise = id == "chair"
	local banc = id == "garden_bench"
	local lit = id == "bed"
	local bas = id == "tannery" or id == "trough"
	local meuble = id == "shelf" or id == "loom" or id == "stall"
	local w, p = chaise and 0.77 or lit and 1.07 or 1.52, lit and 1.72 or chaise and 0.72 or 0.91
	local h = (lit or bas or banc) and 0.36 or chaise and 0.55 or 0.69
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local high = (chaise or banc) and sz == 1 or meuble
			local l = high and (id == "stall" and 1.55 or 1.36) or h
			d.box("Pied", 0.15, l, 0.15, sx * w * 0.43, l / 2, sz * p * 0.40, dark, mat.Wood)
		end
	end
	planches(d, 0, h, 0, 0.15, w, p, 4, false)
	if chaise or banc then
		d.box("Dossier", w, 0.22, 0.13, 0, 1.16, p * 0.40, wood, mat.Wood)
		d.box("Traverse du dossier", w, 0.10, 0.13, 0, 0.94, p * 0.40, bronze, mat.Wood)
	elseif lit then
		d.box("Matelas", w * 0.93, 0.22, p * 0.91, 0, 0.52, 0, cream, mat.Fabric)
		d.box("Couverture", w * 0.95, 0.11, p * 0.61, 0, 0.68, -p * 0.15, rgb(152, 59, 56), mat.Fabric)
		d.ball("Oreiller", w * 0.76, 0.16, p * 0.28, 0, 0.68, p * 0.28, cream, mat.Fabric)
		d.box("Chevet", w, 0.47, 0.14, 0, 0.57, p * 0.51, wood, mat.Wood)
	elseif bas then
		for _, s in { -1, 1 } do
			d.box("Paroi", w, 0.31, 0.13, 0, h + 0.19, s * p * 0.48, wood, mat.Wood)
			d.box("Joue", 0.13, 0.31, p, s * w * 0.47, h + 0.19, 0, wood, mat.Wood)
		end
		local eau = id == "trough"
		d.box(eau and "Eau" or "Peau en bain", w * 0.90, 0.06, p * 0.87, 0, h + 0.18, 0,
			eau and rgb(82, 143, 157) or rgb(79, 57, 43), eau and mat.Glass or mat.Leather)
	elseif id == "shelf" then
		for _, y in { 0.31, 1.23 } do d.box("Tablette", w, 0.12, p, 0, y, 0, wood, mat.Wood) end
		d.box("Fond", w, 1.10, 0.11, 0, 0.78, p * 0.44, dark, mat.WoodPlanks)
	elseif id == "loom" then
		d.box("Ensouple haute", w, 0.14, 0.19, 0, 1.29, p * 0.38, wood, mat.Wood)
		d.box("Ensouple basse", w, 0.14, 0.19, 0, 0.60, -p * 0.39, wood, mat.Wood)
		for i = -3, 3 do
			d.line("Chaîne du métier", V(i * 0.17, 1.27, p * 0.35), V(i * 0.17, 0.58, -p * 0.36), 0.06, cream, mat.Fabric)
		end
	elseif id == "stall" then
		for i = -2, 2 do
			d.part("Toile du marché", V(0.34, 0.10, 1.15), C(i * 0.33, 1.57, 0) * rot(-0.12, 0, 0),
				i % 2 == 0 and cream or rgb(155, 63, 53), nil, mat.Fabric)
		end
		d.box("Traverse haute", w, 0.11, 0.15, 0, 1.48, 0.36, wood, mat.Wood)
	elseif id == "workbench" then
		d.box("Embase d'étau", 0.46, 0.11, 0.43, 0.42, h + 0.11, -0.25, steel, mat.Metal)
		for _, s in { -1, 1 } do d.box("Mors de l'étau", 0.13, 0.28, 0.43, 0.42 + s * 0.19, h + 0.25, -0.25, steel, mat.Metal) end
		d.line("Manivelle", V(0.60, h + 0.21, -0.25), V(0.92, h + 0.21, -0.31), 0.083, bronze, mat.Metal)
	else
		d.box("Traverse sous le plateau", w, 0.15, 0.14, 0, h * 0.58, p * 0.40, dark, mat.Wood)
	end
end)

serie("alarm alembic anvil barracks beehive campfire furnace lantern rug scarecrow sprinkler training_dummy well windmill", function(d, id)
	local c = rgb(132, 134, 127)
	local pierre = id == "furnace" or id == "well" or id == "barracks" or id == "windmill"
	d.box("Appui", 1.30, 0.14, 1.00, 0, 0.07, 0, pierre and c or wood, pierre and mat.Slate or mat.Wood)
	if id == "anvil" then
		d.box("Pied de l’enclume", 0.67, 0.14, 0.59, 0, 0.18, 0, steel, mat.Metal)
		d.ball("Taille", 0.44, 0.37, 0.49, 0, 0.34, 0, c, mat.Metal)
		d.box("Table", 0.98, 0.20, 0.56, 0, 0.54, 0, steel, mat.Metal)
		d.part("Bigorne", V(0.52, 0.22, 0.41), C(0.68, 0.52, 0) * rot(0, -pi / 2, 0), steel, "wedge", mat.Metal)
		d.box("Talonnette", 0.32, 0.16, 0.57, -0.53, 0.48, 0, bronze, mat.Metal)
	elseif id == "rug" then
		d.box("Tissu", 1.52, 0.10, 1.04, 0, 0.16, 0, rgb(152, 66, 57), mat.Fabric)
		for _, side in { -1, 1 } do
			d.box("Galon", 1.39, 0.042, 0.12, 0, 0.213, side * 0.30, cream, mat.Fabric)
			for j = -2, 2 do
				d.box("Frange", 0.10, 0.074, 0.25, j * 0.25, 0.15, side * 0.54, cream, mat.Fabric)
			end
		end
		d.box("Motif", 0.27, 0.039, 0.27, 0, 0.213, 0, bronze, mat.Fabric, pi / 4)
	elseif id == "beehive" then
		for i = 0, 4 do
			d.disc("Rang de paille", 1.09 - i * 0.13, 0.17, 0, 0.20 + i * 0.15, 0, gold:Lerp(wood, i % 2 * 0.23), mat.Fabric)
		end
		d.ball("Trou d'envol", 0.25, 0.19, 0.13, 0, 0.30, -0.48, dark)
	elseif id == "scarecrow" or id == "training_dummy" then
		local dummy = id == "training_dummy"
		d.box("Poteau", 0.15, 1.28, 0.18, 0, 0.74, 0, wood, mat.Wood)
		d.box("Traverse", 1.18, 0.15, 0.18, 0, 0.94, 0, wood, mat.Wood)
		d.ball("Buste", 0.60, 0.62, 0.28, 0, 0.74, -0.04, dummy and bronze or rgb(127, 83, 72), mat.Fabric)
		d.ball("Tête de paille", 0.38, 0.41, 0.38, 0, 1.28, -0.04, cream, mat.Fabric)
		d.disc(dummy and "Collet" or "Chapeau", dummy and 0.43 or 0.57, 0.12, 0, 1.43, -0.04, dark, mat.Fabric)
	elseif id == "lantern" or id == "alarm" then
		local cloche = id == "alarm"
		local y = cloche and 0.71 or 0.58
		for _, s in { -1, 1 } do d.box("Montant", 0.13, 1.0, 0.16, s * 0.39, 0.62, 0, steel, mat.Metal) end
		d.box("Traverse", 0.89, 0.14, 0.25, 0, 1.12, 0, steel, mat.Metal)
		d.disc(cloche and "Bord de cloche" or "Cuve", 0.66, 0.15, 0, y - 0.21, 0, gold, mat.Metal)
		d.ball(cloche and "Cloche" or "Verre", 0.62, 0.56, 0.62, 0, y, 0, cloche and bronze or rgb(215, 176, 100), cloche and mat.Metal or mat.Glass)
		d.line("Suspente", V(0, y + 0.21, 0), V(0, 1.14, 0), 0.12, steel, mat.Metal)
	elseif id == "sprinkler" or id == "alembic" then
		local alambic = id == "alembic"
		d.ball(alambic and "Cuve de cuivre" or "Chambre", 0.87, 0.59, 0.79, 0, 0.40, 0, bronze, mat.Metal)
		d.disc("Bride", 0.50, 0.10, 0, 0.65, 0, steel, mat.Metal)
		d.box("Montant", 0.16, 0.40, 0.17, 0, 0.73, 0, bronze, mat.Metal)
		d.line("Tube coudé", V(0, 0.9, 0), V(0.58, 0.91, 0), 0.136, bronze, mat.Metal)
		d.line(alambic and "Serpentin" or "Buse", V(0.57, 0.91, 0), V(0.63, alambic and 0.31 or 0.86, -0.14), 0.103, steel, mat.Metal)
		d.disc(alambic and "Godet" or "Buse", 0.32, 0.19, 0.63, alambic and 0.22 or 0.85, -0.14, bronze, mat.Metal)
	elseif id == "campfire" or id == "well" then
		for i = 0, 7 do
			local a = i * pi / 4
			d.ball("Pierre", 0.38, id == "well" and 0.67 or 0.24, 0.33, math.cos(a) * 0.48, id == "well" and 0.39 or 0.18, math.sin(a) * 0.42, c:Lerp(cream, i % 3 * 0.14), mat.Slate)
		end
		if id == "well" then
			for s = -1, 1, 2 do d.box("Montant du puits", 0.15, 1.11, 0.16, s * 0.53, 0.67, 0, wood, mat.Wood) end
			d.box("Traverse", 1.31, 0.16, 0.18, 0, 1.20, 0, wood, mat.Wood)
			d.line("Corde", V(0, 1.13, 0), V(0, 0.55, 0), 0.09, bronze, mat.Fabric)
			d.disc("Seau", 0.37, 0.29, 0, 0.42, 0, wood, mat.Wood)
		else
			d.box("Bûche", 0.92, 0.16, 0.18, 0, 0.19, 0, wood, mat.Wood, 0.45)
			d.box("Bûche", 0.92, 0.16, 0.18, 0, 0.30, 0, wood, mat.Wood, -0.47)
			for i = -1, 1 do
				d.part("Lueur du foyer", V(0.24, 0.53 - math.abs(i) * 0.17, 0.21), C(i * 0.15, 0.52, 0) * rot(0, 0, -i * 0.35), gold, "wedge", mat.Neon)
			end
		end
	else
		local h = id == "windmill" and 1.27 or 0.91
		d.box("Maçonnerie", 1.04, h, 0.79, 0, h * 0.5 + 0.11, 0, c, mat.Slate)
		d.box("Ouverture", 0.42, 0.43, 0.075, 0, 0.38, -0.41, dark)
		for s = -1, 1, 2 do
			d.part("Couverture", V(1.20, 0.13, 0.56), C(0, h + 0.20, s * 0.20) * rot(s * 0.38, 0, 0), id == "furnace" and c or clay, nil, id == "furnace" and mat.Slate or mat.Wood)
		end
		if id == "windmill" then
			d.ball("Moyeu", 0.22, 0.22, 0.21, 0, h * 0.78, -0.47, bronze, mat.Metal)
			for i = 0, 3 do
				local a = i * pi / 2 + 0.42
				d.part("Aile du moulin", V(0.22, 0.84, 0.10), C(math.sin(a) * -0.46, h * 0.78 + math.cos(a) * 0.46, -0.47) * rot(0, 0, a), cream, nil, mat.Fabric)
			end
		elseif id == "furnace" then
			d.box("Bouche du four", 0.34, 0.13, 0.069, 0, 0.28, -0.455, gold)
			d.box("Cheminée", 0.37, 0.43, 0.34, 0.27, 1.22, 0.13, c, mat.Slate)
		else
			d.box("Mâchicoulis", 1.13, 0.13, 0.11, 0, h * 0.89, -0.43, c:Lerp(cream, 0.3), mat.Slate)
			d.box("Écusson", 0.21, 0.25, 0.053, 0, 0.69, -0.46, rgb(150, 55, 45), mat.Fabric)
		end
	end
end)

serie("carrot parsnip onion garlic turnip pickled_onions grape berries dried_fruit crab crayfish shellfish rare_shell", function(d, id)
	if id == "carrot" or id == "parsnip" then
		local carrot = id == "carrot"
		local c = carrot and rgb(226, 116, 39) or cream
		local h = carrot and 1.25 or 0.99
		for i = 0, 4 do
			local w = (carrot and 0.43 or 0.58) * (1 - i * 0.18)
			d.ball("Racine", w, h * 0.44, w, i * i * 0.009, h * (0.9 - i * 0.18), 0, c:Lerp(wood, i * 0.08))
		end
		for i = -1, 1 do
			d.line("Fane", V(0, h * 0.98, 0), V(i * 0.27, h * 1.29, 0.04 * i), 0.09, green, mat.Grass)
		end
	elseif id == "onion" or id == "garlic" or id == "turnip" or id == "pickled_onions" then
		local ail, bocal = id == "garlic", id == "pickled_onions"
		local c = ail and cream or id == "turnip" and rgb(156, 99, 137) or rgb(189, 132, 71)
		if bocal then
			local jar = d.disc("Bocal de verre", 1.10, 0.73, 0, 0.39, 0, rgb(141, 164, 138), mat.Glass)
			jar.Transparency = 0.32
			d.disc("Couvercle", 1.16, 0.15, 0, 0.775, 0, bronze, mat.Metal)
			d.disc("Saumure", 1.01, 0.04, 0, 0.69, 0, rgb(179, 169, 106), mat.Glass)
		else
			d.ball("Bulbe", id == "turnip" and 1.13 or 0.95, ail and 0.63 or 0.85, 0.91, 0, 0.44, 0, c)
			d.line("Col du bulbe", V(0, 0.62, 0), V(-0.03, 1.03, -0.03), 0.14, id == "turnip" and green or wood)
		end
		for i = 0, 4 do
			local a = i * pi * 0.4
			d.part(ail and "Gousse" or bocal and "Petit oignon" or "Pelure", V(ail and 0.41 or 0.26, ail and 0.70 or bocal and 0.25 or 0.67, 0.34),
				C(math.cos(a) * 0.29, 0.45 - (bocal and 0.20 - i % 2 * 0.22 or 0), math.sin(a) * 0.29) * rot(0, a, -0.21),
				c:Lerp(cream, 0.19 + i % 3 * 0.09), "ball")
		end
	elseif id == "grape" or id == "berries" or id == "dried_fruit" then
		local grape, dried = id == "grape", id == "dried_fruit"
		local c = grape and rgb(107, 67, 133) or dried and rgb(158, 97, 56) or rgb(155, 57, 75)
		if grape then
			d.line("Rafle", V(0, 0.21, 0), V(0.04, 1.18, 0.02), 0.11, wood, mat.Wood)
			d.ball("Feuille de vigne", 0.58, 0.14, 0.41, 0.22, 1.07, 0.01, green, mat.Grass)
		else
			d.disc("Coupelle", 1.13, 0.20, 0, 0.09, 0, wood, mat.Wood)
		end
		for i = 0, 8 do
			local a = i * 2.39
			local y = i % 3
			local r = grape and (0.08 + y * 0.105) or 0.38
			d.ball(grape and "Grain de raisin" or dried and "Fruit ridé" or "Baie", grape and 0.37 or 0.29, dried and 0.16 or 0.31, 0.34,
				math.cos(a) * r, grape and (0.22 + y * 0.28) or (0.22 + y * 0.05), math.sin(a) * r, c:Lerp(cream, i % 3 * 0.15))
		end
	else
		local crabe, ecrevisse = id == "crab", id == "crayfish"
		local c = crabe and rgb(178, 78, 62) or ecrevisse and rgb(164, 67, 48) or id == "rare_shell" and rgb(122, 133, 170) or rgb(192, 153, 126)
		d.ball("Carapace", crabe and 0.99 or 0.69, crabe and 0.42 or 0.35, ecrevisse and 1.19 or 0.97, 0, 0.24, 0, c)
		if crabe or ecrevisse then
			for _, s in { -1, 1 } do
				for i = 0, 2 do
					d.line("Patte", V(s * 0.22, 0.25, -0.26 + i * 0.20), V(s * 0.64, 0.12, -0.13 + i * 0.24), 0.10, c)
				end
				d.line("Bras", V(s * 0.27, 0.27, -0.32), V(s * 0.52, 0.29, -0.58), 0.14, c)
				d.ball("Pince", 0.33, 0.23, 0.37, s * 0.55, 0.30, -0.67, c:Lerp(cream, 0.22))
				d.line("Doigt de la pince", V(s * 0.55, 0.34, -0.74), V(s * 0.65, 0.37, -0.90), 0.10, c)
			end
			if ecrevisse then
				for i = 0, 2 do d.box("Anneau abdominal", 0.53 - i * 0.04, 0.23, 0.24, 0, 0.20, 0.33 + i * 0.17, c:Lerp(cream, 0.22)) end
				d.ball("Éventail caudal", 0.60, 0.15, 0.32, 0, 0.13, 0.87, c)
			end
		else
			local rare = id == "rare_shell"
			for i = 0, 6 do
				local a = (i - 3) * 0.27
				d.line("Côte rayonnante", V(0, 0.29, 0.33), V(math.sin(a) * 0.58, 0.25 + (rare and 0.10 or 0), -0.32),
					0.091, c:Lerp(cream, 0.38))
			end
			d.ball("Charnière", 0.34, 0.22, 0.22, 0, 0.17, 0.44, c)
		end
	end
end)

local boissons = {
	water = { 1.08, 0.66, rgb(110, 170, 182), "verre" }, ale = { 1.01, 0.87, rgb(173, 102, 44), "mousse" },
	chamomile_tea = { 0.84, 0.61, rgb(178, 128, 59), "fleur" }, evening_tea = { 0.92, 0.53, rgb(136, 89, 66), "sombre" },
	mint_tea = { 1.02, 0.46, rgb(114, 125, 58), "feuille" }, thyme_tea = { 0.93, 0.55, rgb(153, 105, 59), "tige" },
	sage_tea = { 0.99, 0.59, rgb(137, 111, 67), "feuille" },
	mug = { 0.89, 0.75, clay, "terre" }, tankard = { 0.83, 0.96, steel, "métal" },
	wood_cup = { 0.85, 0.71, bronze, "bois" }, bucket = { 1.16, 0.87, wood, "seau plein" },
	bucket_empty = { 1.11, 0.96, wood, "seau vide" },
}
serie("water ale chamomile_tea evening_tea mint_tea thyme_tea sage_tea mug tankard wood_cup bucket bucket_empty", function(d, id)
	local p = boissons[id]
	local x, h, c, k = p[1], p[2], p[3], p[4]
	local eau, seau = k == "verre", id:find("^bucket") ~= nil
	local bois = seau or k == "bois" or k == "mousse"
	local mode = eau and mat.Glass or bois and mat.Wood or k == "métal" and mat.Metal or mat.CeramicTiles
	local body = d.disc(seau and "Douelles" or "Corps du gobelet", x, h, 0, h * 0.5, 0,
		bois and wood or k == "métal" and steel or k == "verre" and rgb(143, 184, 181) or clay, mode)
	if eau then body.Transparency = 0.33 end
	d.disc("Pied", x * 1.065, 0.13, 0, 0.12, 0, bois and bronze or body.Color:Lerp(dark, 0.15), mode)
	d.disc("Rebord", x * 1.075, 0.14, 0, h - 0.03, 0, body.Color:Lerp(cream, 0.27), mode)
	local vide = k == "terre" or k == "bois" or k == "métal" or id == "bucket_empty"
	local surface = vide and dark or id == "bucket" and rgb(101, 161, 184) or c
	d.disc(vide and "Intérieur" or "Boisson", x * 0.88, 0.065, 0, h + 0.038, 0, surface, eau and mat.Glass or nil)
	if seau then
		d.disc("Cerclage", x * 1.06, 0.10, 0, h * 0.32, 0, steel, mat.Metal)
		for _, s in { -1, 1 } do
			d.line("Anse", V(s * x * 0.47, h * 0.76, 0), V(s * x * 0.27, h + 0.40, 0), 0.085, steel, mat.Metal)
		end
		d.box("Poignée du seau", x * 0.62, 0.094, 0.11, 0, h + 0.40, 0, bronze, mat.Wood)
	else
		local dx = x * 0.49
		if not eau then
			for _, y in { h * 0.33, h * 0.72 } do d.box("Attache", 0.28, 0.095, 0.13, dx, y, 0, body.Color, mode) end
			d.box("Anse", 0.10, h * 0.48, 0.12, dx + 0.12, h * 0.52, 0, body.Color, mode)
		end
		if k == "mousse" or k == "fleur" or k == "feuille" or k == "tige" then
			for i = -1, 1 do
				d.part(k == "mousse" and "Mousse" or "Garniture", V(0.28, 0.08, 0.20), C(i * 0.18, h + 0.08, i % 2 * -0.047) * rot(0,0.51*i,0),
					k == "mousse" and cream or k == "fleur" and gold or green, "ball")
			end
		elseif eau then
			d.disc("Niveau d'eau", x * 0.79, 0.07, 0, h * 0.70, 0, c, mat.Glass)
			d.box("Reflet", 0.09, h * 0.61, 0.045, 0.13, h * 0.56, -x * 0.48, cream:Lerp(c, 0.63), mat.Glass)
		elseif k == "sombre" then
			d.line("Bout de cuillère", V(0.22, h + 0.03, 0), V(0.69, h + 0.11, -0.02), 0.10, wood, mat.Wood)
		end
	end
end)

serie("ancient_key rusty_key hourglass feeder flowerpot planter", function(d, id)
	if id:find("_key") then
		local old = id == "ancient_key"
		local c = old and bronze or rgb(128, 81, 62)
		local w = old and 0.38 or 0.30
		d.anneau("Anneau de la clé", 0, 0.62, 0, w, old and 0.30 or 0.39, 0.13, c, mat.Metal, old and 6 or 9)
		d.box("Tige", 0.16, 1.0, 0.16, 0, -0.11, 0, c, mat.Metal)
		d.box("Panneton", old and 0.46 or 0.33, 0.18, 0.16, 0.13, -0.53, 0, c, mat.Metal)
		for i = 0, old and 2 or 1 do
			d.box("Dent", 0.08, 0.17, 0.17, i * 0.12 + 0.08, -0.63 + i % 2 * 0.043, 0, c:Lerp(dark, 0.20), mat.Metal)
		end
		d.box("Bague de clé", 0.23, 0.10, 0.20, 0, 0.19, 0, c:Lerp(cream, 0.22), mat.Metal)
	elseif id == "hourglass" then
		for _, y in { 0.13, 1.46 } do d.disc("Plateau", 1.14, 0.14, 0, y, 0, wood, mat.Wood) end
		for i = 0, 2 do
			local a = i * 2 * pi / 3
			d.box("Montant", 0.12, 1.34, 0.12, math.cos(a) * 0.46, 0.79, math.sin(a) * 0.46, bronze, mat.Wood)
		end
		for _, y in { 0.46, 1.11 } do
			local p = d.ball("Ampoule de verre", 0.60, 0.69, 0.60, 0, y, 0, rgb(148, 183, 185), mat.Glass)
			p.Transparency = 0.32
		end
		d.ball("Sable", 0.49, 0.25, 0.49, 0, 0.31, 0, cream)
		d.line("Filet de sable", V(0, 0.35, 0), V(0, 0.93, 0), 0.055, gold)
	elseif id == "feeder" then
		for _, s in { -1, 1 } do
			d.box("Pied", 0.17, 0.59, 0.69, s * 0.63, 0.29, 0, dark, mat.Wood)
			d.box("Bord", 1.42, 0.18, 0.12, 0, 0.35, s * 0.30, bronze, mat.Wood)
		end
		planches(d, 0, 0.27, 0, 0.13, 1.39, 0.63, 4, false)
		d.box("Foin", 1.23, 0.25, 0.55, 0, 0.40, 0, gold, mat.Fabric)
	elseif id == "planter" then
		d.box("Fond de la jardinière", 1.53, 0.14, 0.79, 0, 0.07, 0, wood, mat.WoodPlanks)
		for _, s in { -1, 1 } do
			d.box("Paroi longue", 1.51, 0.36, 0.12, 0, 0.25, s * 0.36, bronze, mat.Wood)
			d.box("Paroi courte", 0.12, 0.36, 0.80, s * 0.70, 0.25, 0, wood, mat.Wood)
		end
		d.box("Terre fraîche", 1.37, 0.26, 0.63, 0, 0.26, 0, dark, mat.Ground)
		for i = -1, 1 do
			local y = 0.84 + (1 - math.abs(i)) * 0.21
			d.line("Tige", V(i * 0.31, 0.36, 0), V(i * 0.44, y, 0), 0.084, green, mat.Grass)
			d.ball("Feuille", 0.34, 0.13, 0.20, i * 0.37 + 0.07, y - 0.19, 0.03, green, mat.Grass)
			d.ball("Fleur", 0.38, 0.23, 0.23, i * 0.44, y, 0, rgb(169 + i * 13, 74, 122))
		end
	else
		d.disc("Pied du pot", 1.01, 0.16, 0, 0.09, 0, clay, mat.CeramicTiles)
		d.ball("Panse du pot", 1.22, 0.69, 1.19, 0, 0.39, 0, clay, mat.CeramicTiles)
		d.disc("Lèvre du pot", 1.24, 0.13, 0, 0.66, 0, clay:Lerp(cream, 0.23), mat.CeramicTiles)
		d.disc("Terre", 1.06, 0.07, 0, 0.73, 0, dark, mat.Ground)
		for i = -1, 1 do
			d.line("Tige", V(i * 0.09, 0.71, 0), V(i * 0.30, 1.15 + (1 - math.abs(i)) * 0.23, 0), 0.078, green, mat.Grass)
			d.ball("Fleur", 0.29, 0.22, 0.23, i * 0.30, 1.15 + (1 - math.abs(i)) * 0.23, 0, rgb(168, 69 + i * 12, 126))
		end
	end
end)

local function folder(parent, name)
	local result = parent:FindFirstChild(name)
	if not result then
		result = Instance.new("Folder")
		result.Name, result.Parent = name, parent
	end
	return result
end

local function piecesVisibles(model)
	local pieces = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.95 then
			table.insert(pieces, p)
		end
	end
	return pieces
end

local function volume(p)
	return p.Size.X * p.Size.Y * p.Size.Z
end

-- Test d'intersection de deux boîtes orientées par les 15 axes séparateurs.
-- Une petite tolérance relative absorbe les jours de menuiserie et les arrondis.
local function boite(p)
	return { axes = { p.CFrame.RightVector, p.CFrame.UpVector, p.CFrame.ZVector },
		c = p.Position, h = p.Size / 2 }
end

local function ecart(a, b)
	local delta, valeur, direction = b.c - a.c, -math.huge, nil
	local function projete(box, axe)
		return math.abs(axe:Dot(box.axes[1])) * box.h.X + math.abs(axe:Dot(box.axes[2])) * box.h.Y
			+ math.abs(axe:Dot(box.axes[3])) * box.h.Z
	end
	local function axeSeparateur(axe)
		if axe.Magnitude < 1e-5 then return end
		axe = axe.Unit
		local signe = delta:Dot(axe)
		local distance = math.abs(signe) - projete(a, axe) - projete(b, axe)
		if distance > valeur then
			valeur, direction = distance, signe < 0 and -axe or axe
		end
	end
	for _, axe in a.axes do axeSeparateur(axe) end
	for _, axe in b.axes do axeSeparateur(axe) end
	for _, axe in a.axes do
		for _, autre in b.axes do
			axeSeparateur(axe:Cross(autre))
		end
	end
	return valeur, direction
end

local function composantes(pieces, tolerance)
	local boites, vues, groupes = {}, {}, {}
	for i, p in pieces do boites[i] = boite(p) end
	for racine in pieces do
		if vues[racine] then continue end
		local groupe = { racine }
		vues[racine] = true
		local position = 1
		while position <= #groupe do
			local i = groupe[position]
			for j in pieces do
				if not vues[j] and ecart(boites[i], boites[j]) <= tolerance then
					vues[j] = true
					table.insert(groupe, j)
				end
			end
			position += 1
		end
		table.insert(groupes, groupe)
	end
	return groupes, boites
end

local function echelle(model)
	local _, size = model:GetBoundingBox()
	return math.max(size.X, size.Y, size.Z)
end

function M.centrer(model)
	-- Sans PrimaryPart, Roblox mesure dans les axes du monde. Le HUD regarde vers -Z.
	model.PrimaryPart = nil
	local cadre, taille = model:GetBoundingBox()
	local delta = V(-cadre.X, taille.Y / 2 - cadre.Y, -cadre.Z)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then p.CFrame += delta end
	end
	model.WorldPivot = C()
end

function M.verifier(model, minimum)
	local pieces, erreurs = piecesVisibles(model), {}
	local total = 0
	for _, p in model:GetDescendants() do
		if not p:IsA("BasePart") then continue end
		total += 1
		local x, y, z = p.Size.X, p.Size.Y, p.Size.Z
		if not (x > 0 and y > 0 and z > 0 and x + y + z < math.huge) then
			table.insert(erreurs, "taille invalide : " .. p.Name)
		end
		if p.Material == mat.Neon then
			local n = string.lower(p.Name)
			if not (n:find("lueur") or n:find("flamme") or n:find("braise")) then
				table.insert(erreurs, "Neon hors lueur : " .. p.Name)
			end
		end
	end
	if #pieces < minimum then table.insert(erreurs, "seulement " .. #pieces .. " pièces visibles") end
	if total > 25 then table.insert(erreurs, total .. " pièces, budget 25") end
	local groupes = composantes(pieces, echelle(model) * 0.022)
	if #groupes > 1 then
		for i = 2, #groupes do
			table.insert(erreurs, "pièce ou groupe détaché : " .. pieces[groupes[i][1]].Name)
		end
	end
	return erreurs, total
end

-- Les dessins anciens et les copies de props peuvent contenir un effet ou une
-- ferrure isolée. On rapproche les groupes par leur plus petit intervalle.
function M.raccorder(model)
	local pieces = piecesVisibles(model)
	if #pieces < 2 then return end
	table.sort(pieces, function(a, b) return volume(a) > volume(b) end)
	local taille = echelle(model)
	local tolerance = taille * 0.019
	for _ = 1, #pieces * 2 do
		local groupes, boites = composantes(pieces, tolerance)
		if #groupes <= 1 then break end
		local meilleur, mouvement, groupe = math.huge, nil, nil
		for k = 2, #groupes do
			for _, i in groupes[1] do
				for _, j in groupes[k] do
					local distance, axe = ecart(boites[i], boites[j])
					if distance < meilleur then
						meilleur, mouvement, groupe = distance, axe, groupes[k]
					end
				end
			end
		end
		if not groupe then break end
		for _, i in groupe do
			pieces[i].CFrame -= mouvement * (meilleur + taille * 0.001)
		end
	end
end

local function importance(p)
	local n = p.Name:lower()
	for _, motif in { "anse", "serrure", "cadran", "rayon", "poign", "bec", "aile", "pale", "rampe", "barreau",
		"pignon", "battant", "fermoir", "vitr", "meule", "flamme", "roue", "mèche", "tige", "essieu" } do
		if n:find(motif, 1, true) then return 1.6 end
	end
	return 1
end

function M.depuisProp(source, id)
	local model = Instance.new("Model")
	model.Name = id
	model:SetAttribute("ApercuDroit", true)
	model:SetAttribute("PaletteDediee", true)
	local pieces = piecesVisibles(source)
	local sourcePivot = source:GetPivot()
	local _, taille = source:GetBoundingBox()
	-- La première pièce est la masse principale. Les suivantes favorisent
	-- les zones encore vides et les garnitures qui expliquent l'usage.
	local places = {}
	while #pieces > 0 and #places < 25 do
		local indice, meilleur = 1, -math.huge
		for i, p in pieces do
			local distance = taille.Magnitude
			for _, voisin in places do
				distance = math.min(distance, (p.Position - voisin.Position).Magnitude)
			end
			local poids = volume(p) ^ 0.54 * importance(p) * (0.6 + distance / math.max(taille.Magnitude, 0.01))
			if poids > meilleur then indice, meilleur = i, poids end
		end
		table.insert(places, table.remove(pieces, indice))
	end
	for _, original in places do
		local p = original:Clone()
		for _, decor in p:GetChildren() do
			if not (decor:IsA("SpecialMesh") or decor:IsA("Decal") or decor:IsA("Texture")
				or decor:IsA("SurfaceAppearance")) then decor:Destroy() end
		end
		p.CFrame = sourcePivot:ToObjectSpace(original.CFrame)
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		if p.Material == mat.Neon then
			if p.Name:lower():find("flamme") or p.Name:lower():find("braise") then
				p.Name = "Lueur " .. p.Name
			else
				p.Material = p.Transparency > 0 and mat.Glass or mat.SmoothPlastic
			end
		end
		p.Parent = model
	end
	-- La caméra du sac est du côté -Z. Les cadrans, serrures et ouvertures
	-- dessinés sur la face opposée dans le monde doivent lui faire face.
	local cadre, limites = model:GetBoundingBox()
	local avant = 0
	for _, p in model:GetChildren() do
		local n = p.Name:lower()
		if n:find("cadran") or n:find("fermoir") or n:find("serrure") or n:find("ouverture")
			or n:find("poignée") or n:find("enseigne") then
			avant += (p.Position.Z - cadre.Z) / math.max(limites.Z, 0.01)
		end
	end
	if avant > 0.15 then
		for _, p in model:GetChildren() do p.CFrame = rot(0, pi, 0) * p.CFrame end
	end
	return model
end

local function model(parent, id, shape)
	local old = parent:FindFirstChild(id)
	if old and parent.Name == "IconesObjets" and (old:GetAttribute("MiniatureObjet") or old:GetAttribute("Famille")) then
		return old
	end
	local m = Instance.new("Model")
	m.Name = id
	local function part(name, size, pose, color, form, material)
		local p = Instance.new(form == "Wedge" and "WedgePart" or "Part")
		if form and p:IsA("Part") then p.Shape = Enum.PartType[form] end
		p.Name, p.Size, p.CFrame, p.Color = name, size, pose, color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Parent = m
		return p
	end
	shape(part)
	if old then old:Destroy() end
	m.Parent = parent
	return m
end

local function curl(part, radius, thick, y, color, material)
	for i = 0, 9 do
		local a = i * math.pi * 2 / 10
		part("Anneau", V(thick, thick, radius * 0.68), C(math.cos(a) * radius, y, math.sin(a) * radius)
			* CFrame.Angles(0, -a, 0), color, nil, material)
	end
end

function M.mobilier(replicatedStorage, modeles, config)
	local icons = folder(replicatedStorage, "IconesObjets")
	for _, id in {
		"table_wood", "big_table", "chair", "garden_bench", "shelf", "tool_rack", "bookcase",
		"rug", "carpet_big", "banner", "clan_banner", "flowerpot", "clay_pot", "planter",
		"lantern", "wall_torch", "wall_lantern",
	} do
		local existante = icons:FindFirstChild(id)
		if existante and existante:GetAttribute("MiniatureObjet") then continue end
		local info = config.ITEMS[id]
		local nom = info and info.place or (id == "wall_lantern" and "Cat_wall_lantern")
		if not nom then continue end
		local source = modeles:FindFirstChild(nom)
		local image = source and source:Clone() or config.Catalogue.build(nom)
		if not image then continue end
		for _, objet in image:GetDescendants() do
			if objet:IsA("BasePart") then
				objet.CanCollide, objet.CanQuery, objet.CanTouch = false, false, false
			elseif objet:IsA("Light") or objet:IsA("Fire") or objet:IsA("ParticleEmitter") or objet:IsA("ProximityPrompt") then
				objet:Destroy()
			end
		end
		local ancienne = icons:FindFirstChild(id)
		if ancienne then ancienne:Destroy() end
		image.Name = id
		image:SetAttribute("PaletteDediee", true)
		image.Parent = icons
	end
end

-- Quatre petits os articulaires, avec deux lobes inégaux et un étranglement central.
function M.formeOsselets(part)
	local os, patine = rgb(225, 209, 173), rgb(196, 174, 133)
	for _, pose in {
		C(-0.34, 0, -0.25) * CFrame.Angles(0, 0.45, 0),
		C(0.29, 0, -0.27) * CFrame.Angles(0.10, -0.36, 0),
		C(-0.26, 0, 0.32) * CFrame.Angles(0, -0.52, 0),
		C(0.36, 0, 0.27) * CFrame.Angles(0, 0.66, -0.10),
	} do
		part("Col de l’os", V(0.24, 0.20, 0.36), pose * C(0, 0.12, 0), patine, "Ball")
		part("Lobe large", V(0.36, 0.27, 0.28), pose * C(-0.035, 0.14, -0.15), os, "Ball")
		part("Lobe court", V(0.29, 0.23, 0.22), pose * C(0.035, 0.12, 0.16), os, "Ball")
	end
end

function M.identites(replicatedStorage)
	local icons = folder(replicatedStorage, "IconesObjets")
	local osselets = model(icons, "dice", M.formeOsselets)
	osselets:SetAttribute("ApercuDroit", true)
	osselets:SetAttribute("PaletteDediee", true)
	model(icons, "seed_tree_cerisier", function(p)
		p("Noyau", V(0.94, 0.56, 0.74), C(), rgb(167, 106, 59), "Ball")
		p("Suture", V(0.64, 0.05, 0.06), C(0, 0.27, 0), rgb(101, 59, 38), "Ball")
	end)
	model(icons, "ruin_piece", function(p)
		p("Fragment", V(1.18, 0.86, 0.23), C() * CFrame.Angles(0, 0, 0.18), rgb(138, 130, 111), "Wedge", Enum.Material.Slate)
		p("Gravure", V(0.58, 0.08, 0.06), C(-0.12, -0.14, -0.13), bronze)
		p("Gravure", V(0.08, 0.49, 0.06), C(0.06, 0, -0.13) * CFrame.Angles(0, 0, -0.37), bronze)
	end)
	model(icons, "wool", function(p)
		for i = 0, 7 do
			local a = i * math.pi / 4
			p("Mèche de laine", V(0.67, 0.67, 0.64), C(math.cos(a) * 0.41, i % 2 * 0.12, math.sin(a) * 0.26),
				i % 2 == 0 and rgb(241, 226, 201) or rgb(219, 199, 171), "Ball", Enum.Material.Fabric)
		end
	end)
	for _, id in {"crown", "lost_crown"} do
		model(icons, id, function(p)
			local gold = id == "lost_crown" and rgb(152, 110, 55) or rgb(232, 181, 71)
			curl(p, 0.58, 0.18, -0.19, gold, Enum.Material.Metal)
			for i = 0, 5 do
				local a = math.pi * i / 3
				local pose = C(math.cos(a) * 0.57, 0.16, math.sin(a) * 0.57) * CFrame.Angles(0, -a, 0)
				p("Fleuron", V(0.16, 0.58 - (id == "lost_crown" and i % 3 * 0.08 or 0), 0.28), pose, gold, "Wedge", Enum.Material.Metal)
				p("Cabochon", V(0.15, 0.15, 0.18), pose * C(0.08, 0.14, 0), rgb(169, 60, 69), "Ball")
			end
		end)
	end
	model(icons, "prise_desert_raider", function(p)
		p("Étoffe", V(1.23, 0.69, 1.08), C(), rgb(186, 141, 89), "Ball", Enum.Material.Fabric)
		for i = -1, 1 do
			p("Pli", V(1.30 - math.abs(i) * 0.12, 0.14, 1.16), C(0, i * 0.16, 0)
				* CFrame.Angles(0, 0, 0.13 + 0.09 * i), rgb(224 - 16 * (i + 1), 184 - 14 * (i + 1), 120 - 10 * (i + 1)), "Ball", Enum.Material.Fabric)
		end
		p("Pan", V(0.34, 0.55, 0.10), C(0.55, -0.26, 0.15) * CFrame.Angles(0, 0, 0.46), rgb(176, 125, 77), nil, Enum.Material.Fabric)
	end)
	for _, id in {"bolt", "bolt_heavy"} do
		model(icons, id, function(p)
			local scale = id == "bolt_heavy" and 1.34 or 1
			for _, n in {-1, 1} do
				local pose = C(n * 0.23, n * 0.09, 0) * CFrame.Angles(0, 0, n * 0.23)
				p("Fût", V(0.11, 1.04, 0.11) * scale, pose, wood)
				p("Pointe", V(0.22, 0.31, 0.17) * scale, pose * C(0, 0.66 * scale, 0), steel, "Wedge", Enum.Material.Metal)
				p("Empennage", V(0.35, 0.28, 0.09) * scale, pose * C(0, -0.4 * scale, 0), rgb(210, 172, 113), "Wedge")
			end
		end)
	end
	for _, id in {"guard_badge", "sheriff_badge", "prise_deserter"} do
		model(icons, id, function(p)
			local color = id == "sheriff_badge" and bronze or steel
			for i = 0, 4 do
				local a = i * 2 * math.pi / 5
				p("Branche de l’étoile", V(0.28, 0.59, 0.13), C(math.sin(a) * -0.27, math.cos(a) * 0.27, 0)
					* CFrame.Angles(0, 0, a), color, "Wedge", Enum.Material.Metal)
			end
			p("Écusson central", V(0.48, 0.48, 0.17), C(0, 0, -0.05), color, "Ball", Enum.Material.Metal)
		end)
	end
	model(icons, "talisman", function(p)
		curl(p, 0.48, 0.075, 0, wood)
		p("Pendentif", V(0.41, 0.62, 0.23), C(0, -0.18, -0.59), bronze, "Ball", Enum.Material.Metal)
		p("Pierre", V(0.27, 0.34, 0.13), C(0, -0.18, -0.72), rgb(66, 137, 140), "Ball")
	end)
	model(icons, "rotten", function(p)
		p("Morceau", V(1.1, 0.44, 0.74), C(), rgb(110, 82, 72), "Wedge")
		p("Coupe", V(0.64, 0.33, 0.47), C(-0.29, 0.08, 0.03) * CFrame.Angles(0, -0.55, 0), rgb(125, 65, 65), "Wedge")
		for i = 0, 3 do
			p("Tache", V(0.15, 0.08, 0.12), C(i * 0.19 - 0.39, 0.14 + 0.036 * i, -0.15), rgb(123, 134, 67), "Ball")
		end
	end)
	for _, id in {"prise_boss_goblin", "prise_goblin", "prise_goblin_archer", "prise_swamp_goblin", "prise_wood_goblin"} do
		model(icons, id, function(p)
			p("Pavillon", V(0.47, 0.67, 0.31), C(-0.15, -0.15, 0), rgb(131, 153, 77), "Ball")
			p("Pointe", V(0.50, 0.78, 0.25), C(0.12, 0.19, 0) * CFrame.Angles(0, 0, -0.48), rgb(144, 163, 88), "Wedge")
			p("Conque", V(0.19, 0.37, 0.10), C(-0.16, -0.02, -0.15) * CFrame.Angles(0, 0, -0.46), rgb(82, 93, 53), "Ball")
		end)
	end
end

local function family(item, material, id)
	local name = string.lower(item.name)
	if name:find("crocs", 1, true) and item.slot == "trinket" then
		return (id:find("white", 1, true) or id:find("frost", 1, true) or id:find("snow", 1, true)) and "glace" or "crocs"
	end
	if name:find("venimeuse", 1, true) then
		if id:find("water", 1, true) then return "venin_eau" end
		if id:find("scorpion", 1, true) then return "venin_dard" end
		return "venin"
	end
	material = material:lower()
	if material:find("givre", 1, true) or material:find("glace", 1, true) or material:find("blizzard", 1, true) then
		return "glace"
	end
	if material:find("plume", 1, true) then return "plumes" end
	if name:find("cailles", 1, true) or name:find("carapace", 1, true) then return "cailles" end
end

local function trophy(part, category, slot, legendary)
	local pale, violet, teal = rgb(217, 201, 164), rgb(109, 73, 126), rgb(64, 150, 147)
	local ice = rgb(115, 201, 225)
	if category == "crocs" or category == "glace" and slot == "trinket" then
		curl(part, 0.62, 0.085, 0, legendary and bronze or wood)
		local frozen = category == "glace"
		for i = -2, 2 do
			local x = i * 0.24
			local length = (frozen and 0.7 or 0.55) - math.abs(i) * 0.091
			part(frozen and "Cristal" or "Croc", V(0.22, length, 0.19), C(x, -length * 0.35, -0.58 + math.abs(x) * 0.33)
				* CFrame.Angles(0, 0, i * 0.15 + math.pi), frozen and ice or pale, "Wedge")
		end
	elseif category:find("^venin") then
		local aqueous, sting = category == "venin_eau", category == "venin_dard"
		local color = aqueous and teal or sting and violet or rgb(101, 156, 76)
		part("Poignée", V(0.18, 0.49, 0.18), C(0, -0.73, 0), wood)
		part("Garde", V(sting and 0.61 or 0.81, 0.14, 0.19), C(0, -0.45, 0), legendary and bronze or steel, nil, Enum.Material.Metal)
		for i = 0, 3 do
			local x = aqueous and math.sin(i * 1.4) * 0.16 or sting and i * i * 0.031 or i * 0.04
			part("Segment de lame", V(0.5 - i * 0.076, 0.39, 0.15), C(x, -0.26 + i * 0.32, 0)
				* CFrame.Angles(0, 0, aqueous and math.cos(i * 1.4) * 0.38 or -i * 0.13), color, "Wedge", Enum.Material.Metal)
			part("Nervure", V(0.05, 0.26, 0.05), C(x, -0.19 + i * 0.32, -0.10), color:Lerp(pale, 0.42))
		end
	elseif category == "plumes" then
		part("Support", V(0.97, 0.38, 0.5), C(0, -0.23, 0), wood, "Ball")
		for i = -2, 2 do
			part("Plume", V(0.24, 1.02 - math.abs(i) * 0.15, 0.12), C(i * 0.177, 0.16, 0)
				* CFrame.Angles(0, 0, -i * 0.27), teal:Lerp(pale, math.abs(i) * 0.15), "Wedge")
		end
	elseif category == "cailles" then
		part("Cuir", V(1.17, 1.27, 0.39), C(), wood, "Ball")
		if slot == "armor" then
			for _, side in {-1, 1} do
				part("Épaule", V(0.45, 0.44, 0.44), C(side * 0.59, 0.43, 0), teal, "Wedge", Enum.Material.Metal)
			end
			part("Ceinture", V(1.08, 0.12, 0.45), C(0, -0.55, -0.08), wood)
		end
		for row = 0, 2 do
			for col = -1, 1 do
				part("Écaille", V(0.36, 0.41, 0.16), C(col * 0.31, 0.39 - row * 0.34, -0.24)
					* CFrame.Angles(0, col * 0.17, math.pi), teal:Lerp(pale, row * 0.11), "Wedge", Enum.Material.Metal)
			end
		end
	else
		for i = -2, 2 do
			part("Glace taillée", V(0.41, 1.12 - math.abs(i) * 0.22, 0.25), C(i * 0.23, 0, 0)
				* CFrame.Angles(0, 0, -i * 0.28), ice:Lerp(pale, math.abs(i) * 0.16), "Wedge", Enum.Material.Glass)
		end
	end
end

function M.piecesDeCreatures(replicatedStorage, prises, gear)
	local icons = folder(replicatedStorage, "IconesEquipement")
	local total = 0
	local function generate(item, material, id, legendary)
		local category = family(item, material, id)
		if not category then return end
		local slot = gear.slotOf(item)
		local icon = model(icons, slot .. ":" .. item.name, function(part) trophy(part, category, slot, legendary) end)
		icon:SetAttribute("ApercuDroit", true)
		icon:SetAttribute("FamilleVisuelle", category)
		total += 1
	end
	for id, entry in prises.KINDS do
		generate(entry.gear, entry.name, id, false)
		if entry.soul then generate(entry.soul.gear, entry.name, id, true) end
	end
	return total
end

return M
