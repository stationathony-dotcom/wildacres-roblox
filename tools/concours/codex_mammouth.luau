-- Mammouth de givre. Les coordonnées sont en studs, le chanfrein tourné vers -Z.
return function(parent, origin)
	local model = Instance.new("Model")
	model.Name = "Mammouth_codex"
	local n = 0

	local v, cf = Vector3.new, CFrame.new
	local rgb, rad = Color3.fromRGB, math.rad
	local ombre, laine, fauve = rgb(58, 39, 43), rgb(107, 67, 57), rgb(158, 109, 80)
	local ivoire = rgb(245, 222, 178)
	local glacier, givre, cyan = rgb(118, 170, 206), rgb(207, 235, 241), rgb(64, 231, 247)
	local mat, lumiere = Enum.Material.SmoothPlastic, Enum.Material.Neon

	local function rotation(x, y, z)
		return CFrame.Angles(rad(x), rad(y), rad(z))
	end

	local function piece(nom, repere, taille, couleur, classe, materiau)
		local p = Instance.new(classe or "Part")
		p.Name = nom
		p.Size = taille
		p.CFrame = origin * repere
		p.Color = couleur
		p.Material = materiau or mat
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Anchored = true
		p.CanCollide = false
		p.Parent = model
		n = n + 1
		return p
	end

	-- Y suit la courbe. Le premier axe reste dans le plan de la section,
	-- même aux deux endroits où la trompe et les défenses se redressent.
	local function entre(a, b)
		local delta = b - a
		local y = delta.Unit
		local z = v(1, 0, 0):Cross(y).Unit
		return CFrame.fromMatrix((a + b) * 0.5, y:Cross(z), y, z), delta.Magnitude
	end

	local base = piece("Base", cf(0, 0.05, 0), v(0.2, 0.1, 0.2), ombre)
	base.Transparency = 1
	base.PivotOffset = cf(0, -0.05, 0)
	model.PrimaryPart = base

	-- Chaque tranche a son propre garrot, sa ligne de ventre et sa pente.
	-- La neige suit uniquement les reliefs tournés vers le ciel.
	-- z, profondeur, demi-largeur, ventre, crête de la laine, pente, longueur de mèche
	local dos = {
		{-4.10, 3.60, 4.22, 7.30, 15.55, -13, 2.30},
		{-1.55, 3.35, 4.80, 7.25, 16.48,  -3, 1.90},
		{ 1.25, 3.45, 4.92, 6.85, 15.85,  12, 1.55},
		{ 4.05, 3.42, 4.72, 6.70, 14.72,  14, 1.95},
		{ 6.50, 2.76, 3.98, 7.15, 13.36,  18, 1.55},
	}
	-- Hauteur, recul, pente, largeur et ton du jarre, puis tombée du névé.
	local pelage = {
		[-1] = {
			{0.16, -0.36, -17, 2.09, fauve, 1.32}, {0.66, 0.27,  3, 2.35, laine, 2.77},
			{1.19, -0.57, -22, 1.74, fauve, 1.67}, {0.13, 0.34, -9, 2.64, fauve, 2.84},
			{0.87,  0.26,  14, 1.40, laine, 1.36},
		},
		[1] = {
			{0.86, 0.13, -21, 1.77, fauve, 2.30}, {0.09, -0.56, -8, 2.72, fauve, 3.15},
			{1.25, 0.17, -16, 2.14, laine, 1.23}, {0.49, -0.36, 10, 1.94, fauve, 2.21},
			{0.08, 0.18,   7, 1.50, laine, 1.86},
		},
	}
	for i = 1, #dos do
		local t = dos[i]
		local z, d, r, bas, haut = t[1], t[2], t[3], t[4], t[5]
		local axe = cf(0, (bas + haut) / 2, z) * rotation(t[6], 0, 0)
		local h = haut - bas
		piece("Ventre", axe * cf(0, -0.42, 0), v(2*r - 1.38, h - 0.62, d), ombre)
		piece("Toison épaisse", axe * cf(0, -0.10, 0), v(2*r, h - 2.15, d + 0.08), laine)
		piece("Dos bombé", axe * cf(0, h/2 - 1.53, 0), v(2*r - 0.96, 2.45, d + 0.12), fauve)
		piece("Névé", axe * cf(0, h/2 - 0.33, 0), v(2*r - 2.20, 1.04, d + 0.17), glacier)
		piece("Neige de crête", axe * cf(0, h/2 + 0.13, -0.03), v(2*r - 3.38, 0.40, d + 0.12), givre)

		for s = -1, 1, 2 do
			local biais = (i % 2 - 0.5) * 0.34 * s
			local flanc = axe * cf(s*(r - 0.12), 0, biais)
			local revers = rotation(0, 0, 180)
			piece("Sous-poil", flanc * cf(-s*0.18, -h/2 + 1.15, 0.18) * revers,
				v(0.99, 2.34, d - 0.15), ombre, "WedgePart")
			piece("Pan de laine", flanc * cf(s*0.13, -0.16, -0.12) * rotation(-8, 0, s*4),
				v(0.83, 3.20, d - 0.13), laine)
			piece("Mèche traînante", flanc * cf(s*0.19, -2.10, 0.10) * revers,
				v(0.76, t[7], d - 0.36), laine, "WedgePart")
			local m = pelage[s][i]
			local meche = flanc * cf(s*0.45, m[1], m[2]) * rotation(m[3], 0, -s*6)
			piece("Pointe de jarre", meche * revers, v(0.61, 2.14 + 0.32*t[7], m[4]), m[5], "WedgePart")
			if i == 2 or i == 4 then
				piece("Pli de la toison", meche * cf(-s*0.18, 1.37, -0.13),
					v(0.88, 0.96, m[4] + 0.20), m[5])
				piece("Mèche dédoublée", meche * cf(-s*0.07, -1.09, m[4]*0.43) * rotation(12, 0, 180),
					v(0.61, 2.02, m[4]*0.54), laine, "WedgePart")
			end

			local tombee = m[6]
			local neige = axe * cf(s*(r - 0.31), h/2 - 0.83, -m[2])
				* rotation(0, 0, -s*49)
			piece("Épaule de neige", neige, v(2.78, 0.71, d - 0.34), glacier)
			piece("Croûte blanche", neige * cf(-s*0.22, 0.34, -0.14),
				v(2.27, 0.23, d - 0.70), givre)
			local coulee = axe * cf(s*(r + 0.55), h/2 - 1.76, -m[2])
			piece("Langue de givre", coulee * cf(0, -tombee*0.34, 0.08) * rotation(m[3]*0.4, 0, 180),
				v(0.51, tombee, d*0.69), glacier, "WedgePart")
			if tombee > 2.2 then
				piece("Neige accrochée", coulee * cf(s*0.09, -0.21, -0.35) * rotation(-9, 0, 180),
					v(0.43, tombee*0.67, d*0.48), givre, "WedgePart")
			end
		end
	end

	-- Les quatre appuis sont décalés comme au début d'un pas.
	local function patte(s, avant)
		local z = avant and (-3.15 - 0.53*s) or (5.05 + 0.56*s)
		local x = s * (avant and 3.12 or 3.02)
		local pied = cf(x + s*0.20, 0, z + (avant and -0.53 or 0.32)) * rotation(0, -s*8, 0)
		local genou = v(x, 4.57, z + (avant and 0.16 or 0.67))
		local hanche = v(x - s*0.18, 8.80, z + (avant and 0.37 or -0.48))
		local talon = pied * v(0, 1.64, 0.05)
		local tibia, lt = entre(talon, genou)
		local cuisse, lc = entre(genou, hanche)
		piece("Cuisse", cuisse, v(3.50, lc + 1.20, 3.85), laine)
		piece("Jarret", tibia, v(2.84, lt + 1.05, 3.04), laine)
		piece("Culotte de poil", cuisse * cf(s*1.26, -1.36, 0.22) * rotation(0, 0, 180),
			v(1.19, 2.70, 3.30), fauve, "WedgePart")
		piece("Paturon", pied * cf(0, 1.82, 0.04), v(3.02, 2.44, 3.36), ombre)
		piece("Coussinet", pied * cf(0, 0.83, 0), v(3.33, 1.66, 3.20), ombre)
		piece("Front du pied", pied * cf(0, 0.68, -0.35), v(2.62, 1.36, 3.27), laine)
		local manchette = pied * cf(0, 2.49, -0.05) * rotation(-6, 0, -s*5)
		piece("Guêtre gelée", manchette, v(3.18, 0.67, 3.45), glacier)
		piece("Neige tassée", manchette * cf(-s*0.12, 0.32, -0.21), v(2.79, 0.27, 3.13), givre)
		piece("Éclat sur la cheville", manchette * cf(s*1.39, -0.57, -0.28) * rotation(0, 0, 180),
			v(0.48, 1.06, 1.70), glacier, "WedgePart")
		piece("Poil sur le paturon", tibia * cf(s*1.31, 0.07, -0.32) * rotation(-13, 0, 180 - s*7),
			v(0.65, 1.88, 1.82), fauve, "WedgePart")
		for doigt = -1, 1 do
			local cote = math.abs(doigt)
			local ongle = pied * cf(doigt*1.11, 0.53 - 0.06*cote, -2.07 + 0.31*cote)
				* rotation(-9, -doigt*22, 0)
			piece("Ongle", ongle, v(0.88, 0.82 - 0.10*cote, 0.69), ivoire)
		end
	end
	for s = -1, 1, 2 do
		patte(s, true)
		patte(s, false)
	end

	local queue = {v(0, 10.35, 7.48), v(-0.20, 8.76, 8.40), v(-0.66, 6.93, 8.76), v(-1.21, 5.77, 8.63)}
	for i = 1, #queue - 1 do
		local a, l = entre(queue[i], queue[i+1])
		piece("Queue", a, v(0.71 - 0.09*i, l + 0.22, 0.71 - 0.09*i), laine)
	end
	piece("Touffe de queue", cf(-1.32, 5.37, 8.67) * rotation(-9, 0, -22), v(1.08, 1.72, 0.98), ombre)
	piece("Pointe de la queue", cf(-1.55, 4.86, 8.69) * rotation(0, 0, 161), v(0.72, 1.15, 1.03), fauve, "WedgePart")

	-- Tête enchâssée dans la collerette. Les yeux sont sur les pans obliques
	-- du masque pour rester visibles de face comme de trois quarts.
	piece("Nuque", cf(0, 12.03, -5.79) * rotation(-13, 0, 0), v(6.48, 5.60, 4.75), ombre)
	piece("Crâne", cf(0, 11.99, -7.19), v(5.77, 4.92, 3.74), laine)
	piece("Mandibule", cf(0, 9.42, -7.52) * rotation(-8, 0, 0), v(4.74, 2.75, 3.39), ombre)
	piece("Front", cf(0, 13.64, -7.54) * rotation(-8, 0, 0), v(5.28, 2.17, 3.45), fauve)
	piece("Neige sur la nuque", cf(0, 14.65, -7.22) * rotation(-12, 0, -3), v(4.98, 0.84, 3.23), glacier)
	piece("Calotte", cf(-0.21, 15.02, -7.23) * rotation(-12, 0, -3), v(4.09, 0.38, 2.96), givre)
	piece("Frange givrée", cf(-0.51, 14.12, -8.93) * rotation(0, -90, 180), v(0.56, 1.08, 1.31), glacier, "WedgePart")
	piece("Neige sur le front", cf(-1.70, 14.46, -9.06) * rotation(-11, 0, 7), v(1.64, 0.68, 0.77), givre)
	piece("Mèche blanche", cf(-1.39, 14.03, -9.26) * rotation(0, 90, 180), v(0.49, 1.13, 1.05), glacier, "WedgePart")
	piece("Chanfrein", cf(0, 11.79, -9.11) * rotation(-10, 0, 0), v(1.74, 2.62, 1.33), laine)
	for s = -1, 1, 2 do
		local oreille = cf(s*3.09, 12.11, -6.56) * rotation(6, -s*18, s*13)
		piece("Oreille", oreille, v(1.90, 3.60, 1.46), ombre)
		piece("Pavillon", oreille * cf(s*0.04, 0.28, -0.26), v(2.24, 2.78, 1.20), laine)
		piece("Pli du pavillon", oreille * cf(s*0.28, 0.46, -0.85) * rotation(0, 0, s*11),
			v(1.21, 1.52, 0.33), fauve)
		piece("Lobe", oreille * cf(s*0.11, -1.55, 0), v(1.48, 1.10, 1.22), laine)
		local joue = cf(s*2.54, 10.34, -8.14) * rotation(-7, -s*24, s*12)
		piece("Favori", joue, v(1.87, 3.17, 2.44), laine)
		piece("Mèche de joue", joue * cf(s*0.21, -1.51, -0.11) * rotation(0, s*90, 180),
			v(1.95, 1.94, 1.41), fauve, "WedgePart")
		piece("Barbe", joue * cf(-s*0.96, -2.06, 0.22) * rotation(0, s*90, 180),
			v(1.72, 2.04, 1.21), ombre, "WedgePart")
		local oeil = cf(s*1.88, 12.26, -9.16) * rotation(0, -s*30, 0) * rotation(0, 0, s*17)
		piece("Orbite", oeil, v(2.22, 1.27, 0.83), ombre)
		piece("Œil boréal", oeil * cf(s*0.07, 0, -0.43), v(1.29, 0.53, 0.16), cyan, "Part", lumiere)
		piece("Éclat du regard", oeil * cf(-s*0.29, 0.09, -0.52), v(0.31, 0.19, 0.08), givre)
		piece("Arcade", oeil * cf(s*0.05, 0.64, -0.18), v(2.38, 0.73, 1.08), laine)
		piece("Ressaut de l'arcade", oeil * cf(s*0.37, 1.02, -0.14), v(1.69, 0.27, 0.97), fauve)
	end

	-- La trompe se plie sous son propre poids puis se retrousse d'un côté.
	local trompe = {
		{v(0, 11.04, -9.23), 2.18}, {v(-0.12, 9.47, -9.97), 2.04},
		{v(-0.31, 7.75, -10.38), 1.81}, {v(-0.37, 6.10, -10.65), 1.59},
		{v(-0.24, 4.81, -11.18), 1.39}, {v(0.16, 4.17, -12.06), 1.18},
		{v(0.72, 4.24, -12.96), 1.03}, {v(1.13, 4.97, -13.47), 0.91},
		{v(1.27, 5.85, -13.50), 0.85},
	}
	for i = 1, #trompe - 1 do
		local a, l = entre(trompe[i][1], trompe[i+1][1])
		local w = trompe[i][2]
		piece("Anneau de trompe", a, v(w, l + 0.32, w*0.91), laine)
		piece("Pli de trompe", a * cf(0, -l*0.26, 0), v(w + 0.09, 0.25, w*0.97), i % 3 == 1 and fauve or ombre)
		if i == #trompe - 1 then
			local bout = a * cf(0, l/2 + 0.16, 0)
			piece("Lèvre de trompe", bout, v(0.96, 0.23, 0.81), fauve)
			for s = -1, 1, 2 do
				piece("Narine", bout * cf(s*0.23, 0.12, 0), v(0.21, 0.06, 0.35), ombre)
			end
		end
	end

	-- Deux grands croissants. Les sections émoussées se resserrent au virage,
	-- où une nervure de glace remonte de l'extrados jusqu'à la pointe.
	local corne = {
		{2.11, 10.62, -8.89, 1.85}, {2.68, 9.23, -9.68, 1.70},
		{3.28, 7.89, -10.70, 1.62}, {4.08, 6.94, -11.99, 1.47},
		{4.89, 6.70, -13.45, 1.35}, {5.56, 7.18, -14.89, 1.16},
		{5.88, 8.24, -15.96, 0.96}, {5.73, 9.54, -16.53, 0.74},
		{5.21, 10.61, -16.64, 0.46}, {4.67, 11.29, -16.46, 0.14},
	}
	for s = -1, 1, 2 do
		local function point(j)
			local p = corne[j]
			return v(s*p[1], p[2], p[3])
		end
		for i = 1, #corne - 1 do
			local a, l = entre(point(i), point(i+1))
			local w = (corne[i][4] + corne[i+1][4])*0.5
			local ton = i >= 8 and givre or ivoire
			piece("Ivoire du croissant", a, v(w*0.78, l + w*0.32, w), ton)
			piece("Pan de défense", a, v(w, l + w*0.28, w*0.72), ton)
			if i == 1 then
				piece("Alvéole", a * cf(0, -l*0.31, 0), v(2.16, 1.16, 2.06), ombre)
				piece("Collet ambré", a * cf(0, l*0.07, 0), v(1.89, 0.37, 1.83), fauve)
			elseif i >= 5 and i <= 8 then
				piece("Givre de défense", a * cf(s*w*0.42, l*0.07, 0),
					v(w*0.29, l + w*0.23, w*(i-2)*0.122), i % 3 == 0 and givre or glacier)
			end
		end
	end

	-- Deux coins adossés ferment une face triangulaire entre l'arête du fût
	-- et la pointe du cristal. Le pied de la hauteur est commun aux deux.
	local function facette(repere, gauche, droite, sommet, couleur, materiau)
		local arete = (droite - gauche).Unit
		local pied = gauche + arete * (sommet - gauche):Dot(arete)
		local montant = sommet - pied
		local y = montant.Unit
		local function moitie(depart)
			local versPied = pied - depart
			local z = versPied.Unit
			local pan = CFrame.fromMatrix((depart + sommet)*0.5, y:Cross(z), y, z)
			piece("Pan de cristal", repere * pan, v(0.06, montant.Magnitude, versPied.Magnitude),
				couleur, "WedgePart", materiau)
		end
		moitie(gauche)
		moitie(droite)
	end

	-- Les grandes lames ont quatre faces et une pointe décentrée. Les petites
	-- sont des éclisses cassées en biseau, encore traversées par le filon.
	local function cristal(x, y, z, w, h, inclinaison, azimut, devers)
		local a = cf(x, y, z) * rotation(inclinaison, azimut, devers)
		local d, fut, pointe = w*0.82, h*0.39, h*0.61
		piece("Pied de cristal", a * cf(0, fut/2, 0), v(w, fut, d), glacier)
		if w >= 1.30 then
			local ag, ad = v(-w/2, fut, -d/2), v(w/2, fut, -d/2)
			local rg, rd = v(-w/2, fut, d/2), v(w/2, fut, d/2)
			local sommet = v(w*0.21, h, d*0.22)
			facette(a, ag, ad, sommet, cyan, lumiere)
			facette(a, ad, rd, sommet, givre, mat)
			facette(a, rd, rg, sommet, glacier, mat)
			facette(a, rg, ag, sommet, glacier, mat)
		else
			piece("Clivage cyan", a * cf(0, fut + pointe/2, -d*0.18),
				v(w, pointe, d*0.64), cyan, "WedgePart", lumiere)
			piece("Pan opalin", a * cf(0, fut + pointe/2, d*0.32) * rotation(0, 180, 0),
				v(w, pointe, d*0.36), givre, "WedgePart")
		end
		piece("Filon", a * cf(-w*0.17, fut*0.53, -d/2),
			v(w*0.39, fut*0.94, 0.09), cyan, "Part", lumiere)
	end
	-- La grande lame et son éclisse jumelle dessinent une brèche au garrot.
	cristal(-0.69, 16.23, -1.82, 1.57, 4.57, 13, -19,  13)
	cristal( 0.77, 16.15, -1.41, 1.30, 3.60, 19,  21, -18)
	cristal(-1.88, 15.64, -2.73, 0.86, 2.20,  4, -29,  28)
	cristal( 0.13, 15.68,  1.62, 1.61, 3.48, 23, -12,  -5)
	cristal( 1.72, 15.20,  2.29, 0.91, 2.27, 27,  32, -22)
	cristal(-0.63, 14.46,  4.45, 1.27, 2.92, 27, -20,   8)
	cristal( 0.29, 13.34,  6.61, 0.96, 2.06, 36,  14,  -7)

	model:SetAttribute("Pieces", n)
	model.Parent = parent
	return model
end
