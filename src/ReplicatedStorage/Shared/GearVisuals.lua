-- Géométrie commune à la miniature et aux pièces soudées sur le R15.
-- Les coordonnées d'une pièce sont relatives à son point d'attache.
local Design = require(script.Parent.GearDesign)
local Visuals = {}
local V, C, A = Vector3.new, CFrame.new, CFrame.Angles
local rgb, M = Color3.fromRGB, Enum.Material
local dark, hide, wood = rgb(48, 33, 29), rgb(91, 58, 39), rgb(139, 93, 52)
local ivory, pale, soot = rgb(228, 211, 171), rgb(242, 233, 209), rgb(33, 36, 47)
local turns = 2 * math.pi
local pair = {-1, 1}

-- Les membres droits donnent une miniature d'une pièce de la paire.
-- Le pantalon montre ses deux jambes, reliées par la ceinture.
local sizes = {
	head = V(1.16, 1.18, 1.16), chest = V(1.75, 1.24, 0.90), waist = V(1.50, 0.66, 0.85),
	shoulder = V(0.63, 1.00, 0.65), palm = V(0.45, 0.53, 0.46), forearm = V(0.55, 0.83, 0.60),
	thigh = V(0.73, 1.10, 0.75), shin = V(0.65, 1.06, 0.66), foot = V(0.65, 0.42, 1.00),
}

local function pen(emit, joint, side)
	local d = {}
	function d.part(name, size, pose, color, material, kind)
		emit(joint, side, name, size, pose, color, material, kind)
	end
	function d.box(name, x, y, z, w, h, depth, color, material, tilt)
		d.part(name, V(w, h, depth), C(x, y, z) * A(0, 0, tilt or 0), color, material)
	end
	function d.ball(name, x, y, z, w, h, depth, color, material)
		d.part(name, V(w, h, depth), C(x, y, z), color, material, "ball")
	end
	function d.disc(name, x, y, z, diameter, thickness, color, material, flat)
		d.part(name, V(thickness, diameter, diameter), C(x, y, z) *
			(flat and A(0, 0, math.pi / 2) or A(0, math.pi / 2, 0)), color, material, "cylinder")
	end
	function d.bar(name, from, to, width, depth, color, material)
		local delta = to - from
		local axis = delta.Unit
		local across = V(axis.Y, -axis.X, 0)
		across = across.Magnitude < 0.0001 and Vector3.xAxis or across.Unit
		d.part(name, V(width, depth, delta.Magnitude + width * 0.36),
			CFrame.fromMatrix((from + to) / 2, across, axis:Cross(across), axis), color, material)
	end
	function d.path(name, points, width, depth, color, material)
		for i = 1, #points - 1 do
			d.bar(name, points[i], points[i + 1], width, depth, color, material)
		end
	end
	function d.tip(name, root, tip, width, depth, color, material)
		local along = tip - root
		local normal = V(along.Y, -along.X, 0).Unit
		for _, sign in pair do
			local across = normal * sign * width / 2
			local y, z = across.Unit, -along.Unit
			d.part(name, V(depth, across.Magnitude, along.Magnitude),
				CFrame.fromMatrix(root + (along + across) / 2, y:Cross(z), y, z),
				sign == 1 and color or color:Lerp(pale, 0.18), material, "wedge")
		end
	end
	function d.loop(name, x, y, z, rx, ry, count, width, color, material, flat)
		local points = {}
		for i = 0, count do
			local a = i * turns / count
			local offset = math.sin(a) * ry
			points[i + 1] = V(x + math.cos(a) * rx, y + (flat and 0 or offset), z + (flat and offset or 0))
		end
		d.path(name, points, width, width, color, material)
	end
	return d
end

local function setting(d, x, y, z, width, style, kind)
	local stone = style.accent
	d.box("Serti", x, y, z, width * 1.04, width * 0.91, width * 0.33, style.trim, M.Metal, math.pi / 4)
	if kind == "oval" then
		d.ball("Cabochon", x, y, z - width * 0.18, width * 0.81, width, width * 0.43, stone, M.Glass)
	else
		d.box("Facette", x, y, z - width * 0.20, width * 0.72, width * 0.79, width * 0.36, stone, M.Glass, math.pi / 4)
	end
	if style.rarity >= 4 then
		d.box("Lueur légendaire", x, y + width * 0.12, z - width * 0.38, width * 0.23, width * 0.32, 0.025,
			stone:Lerp(pale, 0.22), M.Neon, math.pi / 4)
	end
end

local function emblem(d, style, x, y, z, width)
	local color, metal = style.trim, M.Metal
	local function point(dx, dy)
		return V(x + width * dx, y + width * dy, z)
	end
	if style.series == "soleil" then
		d.disc("Soleil gravé", x, y, z, width * 0.52, 0.044, color, metal)
		for i = 0, 4 do
			local angle = i * turns / 5
			local u, v = math.cos(angle), math.sin(angle)
			d.bar("Rayon", point(u * 0.19, v * 0.19), point(u * 0.52, v * 0.52), width * 0.11, 0.041, color, metal)
		end
	elseif style.series == "lune" then
		d.path("Croissant ouvragé", {point(0.27, 0.45), point(-0.20, 0.32), point(-0.38, -0.03),
			point(-0.16, -0.39), point(0.30, -0.42)}, width * 0.19, 0.046, color, metal)
	elseif style.series == "ronces" then
		d.path("Rameau", {point(-0.39, -0.34), point(0, 0), point(0.39, 0.34)}, width * 0.18, 0.046, color, metal)
		for _, sign in pair do
			d.bar("Épine", point(sign * 0.18, sign * 0.15), point(sign * 0.14, sign * 0.41), width * 0.14, 0.046, color, metal)
		end
	elseif style.series == "garde" then
		d.tip("Écusson du pont", point(0, 0.17), point(0, -0.47), width * 0.84, 0.052, color, metal)
		d.box("Créneaux", x, y + width * 0.24, z, width * 0.82, width * 0.19, 0.054, color, metal)
	elseif style.series == "nord" then
		for i = -1, 1 do
			d.box("Givre incrusté", x + width * i * 0.28, y - math.abs(i) * width * 0.1, z,
				width * 0.23, width * (i == 0 and 0.75 or 0.42), 0.055, color, metal, i * 0.34)
		end
	elseif style.mark == "fang" then
		for _, sign in pair do
			d.tip("Dent montée", point(sign * 0.24, 0.25), point(sign * 0.08, -0.40), width * 0.29, 0.056, ivory, M.SmoothPlastic)
		end
	elseif style.mark == "gem" or style.rarity >= 4 then
		setting(d, x, y, z, width * 0.78, style, style.series == "ambre" and "oval" or nil)
	else
		for i = -1, 1 do
			d.ball(style.mark == "stitch" and "Point sellier" or "Rivet", x + i * width * 0.29, y + i * width * 0.09,
				z, width * 0.19, width * 0.16, 0.056, color, style.mark == "stitch" and M.Fabric or metal)
		end
	end
end

local function hard(s)
	return s.material == "Bone" and M.SmoothPlastic or M[s.material]
end

local function textile(s)
	if s.cloth:find("leather", 1, true) then return M.Leather end
	return M.Fabric
end

local function bentPoint(d, name, root, dx, dy, width, depth, color, material)
	local elbow = root + V(dx * 0.35, dy * 0.54, 0)
	d.bar(name, root, elbow, width, depth, color, material)
	d.tip(name, elbow, root + V(dx, dy, 0), width * 1.06, depth, color, material)
end

local function grip(d, s, low, high, width)
	d.box("Poignée gainée", 0, (low + high) / 2, 0, width, high - low, width, hide, M.Leather)
	for i = 0, 2 + s.variant % 2 do
		local y = low + (high - low) * (i + 1) / (4 + s.variant % 2)
		d.box("Ligature", 0, y, 0, width * 1.08, width * 0.30, width * 1.06, s.color, M.Fabric, 0.22)
	end
	d.ball("Pommeau", 0, low, 0, width * 1.32, width * 0.74, width * 1.22, s.trim, M.Metal)
end

local blades = {
	sword = {1.89, 0.35, 0.79}, shortsword = {1.17, 0.42, 0.59}, longsword = {2.33, 0.33, 0.89},
	bastard = {2.16, 0.42, 0.92}, greatsword = {2.68, 0.53, 1.16},
	dagger = {0.82, 0.28, 0.47}, saber = {1.73, 0.37, 0.57}, venomblade = {1.84, 0.37, 0.72},
}

local function blade(d, s, spec)
	local length, width, cross = spec[1], spec[2], spec[3]
	length += (s.profile - 3) * 0.064 + (s.cut - 8) * 0.011
	cross += (s.variant - 2) * 0.065
	local color, material = s.metal, hard(s)
	local curved = s.form == "saber" or s.form == "venomblade" or s.trait == "sting"
	local y = 0.09
	grip(d, s, s.form == "greatsword" and -0.82 or s.form == "dagger" and -0.43 or -0.60, y, width * 0.48 + 0.026)
	if s.form == "saber" then
		d.path("Garde en demi-panier", {V(-cross * 0.49, y, 0), V(cross * 0.53, y, 0),
			V(cross * 0.58, -0.29, 0), V(0.04, -0.56, 0)}, 0.095, 0.17, s.trim, M.Metal)
	else
		for _, sign in pair do
			local root, endX = V(0, y, 0), sign * cross / 2
			if s.series == "lune" then
				d.path("Quillon en croissant", {root, V(endX * 0.69, y - 0.076, 0),
					V(endX, y + 0.15, 0)}, 0.105, 0.20, s.trim, M.Metal)
			elseif s.series == "os" then
				bentPoint(d, "Quillon de dent", root, endX, -0.18, 0.17, 0.19, ivory, M.SmoothPlastic)
			elseif s.series == "ronces" then
				d.bar("Quillon de ronce", root, V(endX, y + 0.06, 0), 0.12, 0.21, s.trim, M.Metal)
				d.tip("Épine de garde", V(endX * 0.69, y + 0.04, 0), V(endX, y + 0.24, 0), 0.11, 0.16, s.trim, M.Metal)
			else
				d.bar("Quillon", root, V(endX, y + (s.profile % 3 - 1) * 0.13, 0),
					0.11 + s.variant * 0.015, 0.22, s.trim, M.Metal)
			end
		end
	end
	if curved then
		local reach = (s.form == "saber" and 0.53 or s.trait == "sting" and 0.45 or 0.39) + s.cut * 0.015
		local venom = s.form == "venomblade" and s.accent:Lerp(rgb(111, 160, 83), 0.33)
		local cutting = venom or (s.trait == "sting" and ivory or color)
		local middle = V(reach * 0.20, y + length * 0.39, 0)
		local shoulder = V(reach * 0.70, y + length * 0.78, 0)
		d.path("Tranchant courbe", {V(0, y, 0), middle, shoulder}, width, 0.14, cutting, material)
		d.tip("Pointe recourbée", shoulder, V(reach, y + length, 0), width * 1.05, 0.14, cutting, material)
		if venom then
			d.box("Fiole dans la garde", 0, y, -0.105, 0.19, 0.20, 0.14, venom, M.Glass, math.pi / 4)
			d.path("Canaux du venin", {V(0, y + 0.1, -0.082), middle - V(0, 0, 0.082),
				shoulder - V(0, 0, 0.082)}, 0.07, 0.04, venom:Lerp(pale, 0.48), M.Glass)
			if s.soul then
				d.tip("Croc de la Bête", V(0.03, y - 0.015, 0), V(-0.64, y + 0.31, 0), 0.25, 0.18, ivory, M.SmoothPlastic)
			end
		end
	else
		local edge = length * (0.74 + s.variant * 0.029)
		d.box("Lame", 0, y + edge / 2, 0, width, edge + 0.035, 0.13, color, material)
		d.tip("Pointe de lame", V(0, y + edge, 0), V(0, y + length, 0), width, 0.13, color, material)
		local channel = material == M.Wood and "Veine du bois" or material == M.Glass and "Arête du cristal" or "Gouttière"
		for _, sign in pair do
			d.box(channel, sign * width * (s.variant % 2 == 0 and 0.34 or 0.13),
				y + edge * 0.47, -0.061, width * 0.12, edge * 0.79, 0.033, color:Lerp(pale, 0.39), material)
		end
	end
	if s.series == "soleil" then
		d.disc("Disque de garde", 0, y, -0.055, 0.39, 0.16, s.metal, M.Metal)
		emblem(d, s, 0, y, -0.145, 0.33)
	elseif s.rarity >= 3 or s.mark == "gem" then setting(d, 0, y, -0.12, cross * 0.30, s, s.series == "ambre" and "oval" or nil)
	else d.ball("Rivet de garde", 0, y, -0.104, 0.14, 0.14, 0.076, s.trim, M.Metal) end
	if s.rarity >= 2 then
		for _, sign in pair do
			d.box("Filigrane de ricasso", sign * width * 0.24, y + 0.21, -0.071,
				0.036, 0.29, 0.035, s.trim, M.Metal, sign * 0.24)
		end
	end
end

local function bow(d, s)
	local form = s.form
	local cross = form == "crossbow"
	local span = cross and 1.02 or form == "shortbow" and 0.99 or form == "longbow" and 1.58 or 1.35
	span += s.profile * 0.038
	local flare = 0.44 + s.variant * 0.079 + s.cut * 0.008
	local color = s.color:Lerp(wood, 0.33)
	local function spot(x, y)
		return cross and V(y, 0.70 - x, 0) or V(x, y, 0)
	end
	local cord = {}
	for i, sign in pair do
		local root, shoulder = spot(-0.12, sign * 0.13), spot(0.01, sign * span * 0.48)
		local outer = spot(flare * 0.63, sign * span * 0.84)
		local tip = spot(flare * (form == "bow" and 0.73 or 1.12), sign * span)
		d.path("Branche de l’arc", {root, shoulder, outer, tip}, 0.145, 0.19, color, M.Wood)
		d.bar("Renfort de poupée", outer:Lerp(tip, 0.63), tip, 0.18, 0.20, s.trim, hard(s))
		if s.series == "lin" or s.series == "os" then
			d.bar("Ligature de renfort", shoulder:Lerp(outer, 0.29), shoulder:Lerp(outer, 0.52),
				0.196, 0.24, s.trim, s.series == "lin" and M.Fabric or hard(s))
		end
		if s.rarity >= 2 then d.bar("Ventre contrecollé", root - V(0, 0, 0.09), shoulder - V(0, 0, 0.09), 0.09, 0.055, s.trim, hard(s)) end
		cord[i] = tip
	end
	if cross then
		d.box("Fût d’arbalète", 0, -0.10, 0, 0.27, 1.76, 0.32, color, M.Wood)
		d.box("Crosse", 0, -0.95, 0, 0.41, 0.39, 0.36, hide, M.Wood, -0.12)
		d.box("Glissière", 0, 0.25, -0.165, 0.11, 0.94, 0.07, s.trim, M.Metal)
		d.path("Corde sous tension", {cord[1], V(0, -0.39, 0), cord[2]}, 0.053, 0.053, ivory, M.Fabric)
		d.box("Noix d’arbalète", 0, -0.39, -0.13, 0.27, 0.21, 0.10, s.metal, M.Metal)
		if s.rarity >= 3 then setting(d, 0, -0.39, -0.19, 0.19, s) end
	else
		d.box("Poignée d’arc", -0.12, 0, 0, 0.21, 0.43, 0.25, hide, M.Leather)
		d.bar("Corde tendue", cord[1], cord[2], 0.057, 0.057, ivory, M.Fabric)
		if s.trait == "ice" then
			for _, sign in pair do
				bentPoint(d, "Cristal enchâssé", spot(0, sign * span * 0.48), -0.20, sign * 0.35, 0.13, 0.17,
					s.accent:Lerp(pale, 0.36), M.Glass)
			end
		end
		if s.rarity >= 3 then setting(d, -0.12, 0, -0.142, 0.19, s) end
	end
end

local function shaft(d, s, low, high, width)
	d.box("Hampe", 0, (low + high) / 2, 0, width, high - low, width, wood:Lerp(s.color, 0.31), M.Wood)
	d.box("Emmanchement", 0, high - 0.12, 0, width * 1.61, 0.35, width * 1.48, s.trim, hard(s))
	d.box("Talon", 0, low + 0.085, 0, width * 1.35, 0.24, width * 1.3, s.metal, M.Metal)
end

local function pole(d, s)
	local f, material = s.form, hard(s)
	local long = f == "longpike" or f == "halberd"
	local high = (long and 1.38 or 0.95) + s.profile * 0.038
	local low = (long and -1.65 or -1.25) - s.variant * 0.058 - s.cut * 0.012
	local width = f == "javelin" and 0.101 or 0.145
	shaft(d, s, low, high, width)
	d.box("Prise", 0, -0.35, 0, width * 1.23, f == "staff" and 0.49 or 0.34, width * 1.2, hide, M.Leather)
	if f == "staff" then
		d.part("Tête du bâton", V(0.31, 0.43, 0.32), C(0.043, high + 0.17, 0) * A(0, 0, -0.20),
			s.metal, material, "ball")
		for _, sign in pair do
			bentPoint(d, "Fourche ligaturée", V(0, high - 0.12, 0), sign * 0.28, 0.53, 0.14, 0.16, s.color, M.Wood)
		end
	elseif f == "scythe" or f == "reaper" then
		local reach = f == "scythe" and 1.17 or 0.69
		bentPoint(d, "Croissant du fauchard", V(0, high, 0), reach, f == "scythe" and -0.39 or 0.37,
			0.34 + s.variant * 0.03, 0.13, s.metal, material)
		d.box("Attache de la lame", 0.13, high - 0.07, 0, 0.41, 0.20, 0.22, s.trim, M.Metal)
	else
		local tip = high + (f == "longpike" and 0.60 or 0.45) + s.variant * 0.054
		d.tip("Fer de pointe", V(0, high, 0), V(0, tip, 0), f == "javelin" and 0.23 or 0.33 + s.profile * 0.026, 0.14, s.metal, material)
		if f == "halberd" then
			bentPoint(d, "Fer de hache", V(0, high - 0.23, 0), 0.71, 0.28, 0.42, 0.14, s.metal, material)
			bentPoint(d, "Bec arrière", V(0, high - 0.20, 0), -0.38, 0.23, 0.20, 0.13, s.trim, material)
		elseif f == "javelin" then
			for _, sign in pair do
				d.tip("Empennage", V(sign * 0.07, low + 0.26, 0), V(sign * 0.25, low + 0.54, 0), 0.22, 0.085, s.color, M.Fabric)
			end
		end
	end
	if s.rarity >= 3 then setting(d, 0, high - 0.13, -width * 0.76, 0.19, s) end
end

local function weapon(d, s)
	local f = s.form
	if blades[f] then blade(d, s, blades[f]) return end
	if f == "bow" or f == "shortbow" or f == "longbow" or f == "crossbow" then bow(d, s) return end
	if f == "pike" or f == "longpike" or f == "halberd" or f == "javelin" or f == "reaper" or f == "scythe" or f == "staff" then
		pole(d, s) return
	end
	local color, material = s.metal, hard(s)
	local y = 0.68 + s.profile * 0.046 + s.cut * 0.009
	if f == "clawglove" then
		d.box("Dos du gantelet", 0, -0.13, 0, 0.66, 0.78, 0.42, s.color, M.Leather)
		d.box("Bride forgée", 0, y * 0.23, -0.105, 0.68, 0.18, 0.32, s.metal, M.Metal)
		for i = -1, 1 do
			bentPoint(d, "Griffe enchâssée", V(i * 0.21, 0.22, -0.10),
				0.12 + i * 0.12, 0.52 + s.profile * 0.062 - math.abs(i) * 0.14, 0.15, 0.16,
				ivory:Lerp(s.accent, 0.24), M.SmoothPlastic)
		end
		if s.rarity >= 3 then setting(d, 0, -0.16, -0.21, 0.22, s) end
		return
	elseif f == "sling" then
		d.ball("Poche de fronde", 0, -0.59, 0, 0.54, 0.34, 0.20, s.color, M.Leather)
		local stiff = s.name:find("renforcée", 1, true)
		local high = stiff and 0.84 or 0.66
		d.path("Brins de fronde", {V(-0.23, -0.53, 0), V(stiff and -0.54 or -0.39, -0.08, 0), V(-0.24, high - 0.17, 0),
			V(0, high, 0), V(0.25, high - 0.14, 0), V(0.38, -0.07, 0), V(0.24, -0.53, 0)}, 0.076, 0.075, s.trim, M.Fabric)
		if stiff then d.box("Boucle de retenue", 0, high - 0.02, 0, 0.21, 0.16, 0.11, s.color, M.Leather) end
		d.ball("Galet de fronde", 0, -0.50, -0.07, 0.29, 0.22, 0.21, rgb(119, 121, 110), M.Slate)
		return
	elseif f == "throwaxes" then
		d.box("Porte-haches à nouer", 0, -0.28, 0.09, 0.98, 0.29, 0.32, s.color, M.Leather)
		for _, side in pair do
			local x = side * 0.23
			local head = V(x + side * 0.12, 0.54, 0)
			d.bar("Manche court", V(x - side * 0.13, -0.69, 0), head, 0.14, 0.17, wood, M.Wood)
			d.box("Virole de tête", head.X, head.Y - 0.04, 0, 0.19, 0.25, 0.23, s.trim, M.Metal)
			local scout = s.name:find("franc-tireur", 1, true)
			d.tip("Fer de jet", head, head + V(side * (0.33 + s.cut * 0.012), scout and -0.14 or 0.23, 0), 0.44, 0.16, color, material)
		end
		return
	elseif f == "throwing" or f == "bandolier" then
		d.box(f == "bandolier" and "Baudrier de cuir" or "Étui de lancer", 0, 0, 0, 0.75,
			f == "bandolier" and 1.68 or 0.62, 0.25, s.color, M.Leather, -0.40)
		for i = -1, 1 do
			local x, base = i * 0.25, -i * 0.21
			d.box("Poignée de couteau", x, base, -0.12, 0.12, 0.48, 0.14, hide, M.Leather, -0.14)
			d.tip("Lame de jet", V(x + 0.024, base + 0.23, -0.12), V(x + 0.15, base + 0.72, -0.12), 0.22, 0.12, color, material)
		end
		return
	end
	shaft(d, s, f == "sickle" and -0.58 or -1.0, y, 0.17)
	if f == "axe" or f == "sickle" then
		local pruning = s.name:find("^serpe") ~= nil
		local reach = f == "sickle" and (pruning and 0.47 or 0.73) or 0.65 + s.variant * 0.055
		local tipY = f == "sickle" and (pruning and y - 0.69 or y - 0.38) or y + 0.25 + s.profile * 0.042
		if s.trait == "tusk" or s.trait == "horn" then
			bentPoint(d, "Défense cerclée", V(0.03, y - 0.08, 0), reach + 0.18, tipY - y, 0.35, 0.23,
				ivory:Lerp(s.accent, 0.23), M.SmoothPlastic)
			d.box("Joue de douille", 0.19, y - 0.08, 0, 0.37, 0.24, 0.29, s.trim, M.Metal)
		else
			d.bar("Panne de hache", V(0, y - 0.09, 0), V(reach * 0.64, y + 0.015, 0), 0.36, 0.18, color, material)
			d.tip("Taillant", V(reach * 0.67, y + 0.018, 0), V(reach + 0.09, tipY, 0), 0.49, 0.16, color, material)
			if f == "axe" and s.profile % 3 == 0 then
				d.tip("Fer arrière", V(0, y - 0.06, 0), V(-0.52, y + 0.18, 0), 0.38, 0.16, color, material)
			else d.box("Contre-fer", -0.18, y - 0.07, 0, 0.29, 0.24, 0.24, s.trim, M.Metal) end
		end
	elseif f == "claw" then
		d.ball("Articulation de crabe", 0, y, 0, 0.53, 0.49, 0.36, rgb(165, 76, 52), M.Slate)
		for _, sign in pair do
			bentPoint(d, "Mors de pince", V(sign * 0.15, y + 0.12, 0), sign * 0.19, sign == 1 and 0.59 or 0.49,
				0.24, 0.25, rgb(197, 97, 62), M.Slate)
		end
	elseif f == "hammer" then
		d.box("Table de frappe", 0.24, y, 0, 0.75, 0.39 + s.profile * 0.021, 0.45, color, material)
		d.box("Face de frappe", 0.61, y, 0, 0.14, 0.48, 0.51, s.trim, M.Metal)
		d.tip("Bec de marteau", V(-0.06, y, 0), V(-0.61 - s.variant * 0.046, y - 0.12, 0), 0.28, 0.32, color, material)
	elseif s.trait == "bone" then
		local n = f == "club" and 0.83 or 0.57
		local bone = ivory:Lerp(s.accent, 0.26)
		d.box("Fût d’os", 0, y - 0.18, 0, 0.32 + s.variant * 0.03, n, 0.33, bone, M.SmoothPlastic, 0.08)
		for _, sign in pair do
			d.ball("Condyle", sign * (0.15 + s.variant * 0.021), y + n * 0.37, 0, 0.37, 0.47, 0.41, bone, M.SmoothPlastic)
		end
		d.box("Éclisse de renfort", 0, y - 0.14, -0.17, 0.14, n * 0.77, 0.075, s.trim, M.Metal)
	else
		local mace = f == "mace"
		d.ball(mace and "Noyau de la masse" or "Nœud de massue", 0, y + 0.12, 0,
			0.55 + s.variant * 0.044, mace and 0.53 or 0.76, 0.49, color, material)
		for i = 0, s.profile % 3 + 3 do
			local a = i * turns / (s.profile % 3 + 4)
			d.part("Ailette de masse", V(0.26, 0.39 + s.variant * 0.017, 0.115),
				C(math.cos(a) * 0.26, y + 0.12, math.sin(a) * 0.26) * A(0, -a, 0), s.trim, material, "wedge")
		end
	end
	if s.rarity >= 3 then setting(d, 0, y - 0.12, -0.16, 0.24, s) end
end

local function shields(d, s)
	local f, c, t = s.form, s.color, s.trim
	local width = 1.28 + s.variant * 0.075
	if f == "roundshield" then
		d.disc("Cercle du bouclier", 0, 0, 0, width, 0.14, s.metal, M.Metal)
		d.disc("Table de bois", 0, 0, -0.08, width * 0.88, 0.12, c, M.WoodPlanks)
		for i = -1, 1 do
			d.box("Lame de bois", i * width * 0.24, 0, -0.135, width * 0.19, width * (1 - math.abs(i) * 0.17) * 0.8,
				0.036, c:Lerp(wood, 0.19 + (i + 1) * 0.13), M.Wood)
		end
		d.ball("Ombilic bombé", 0, 0, -0.184, 0.40, 0.40, 0.24, t, M.Metal)
	elseif f == "pavise" then
		d.box("Corps du pavois", 0, 0, 0, width, 2.06 + s.profile * 0.053, 0.17, s.metal, M.Metal)
		for i = -1, 1 do
			d.box("Planches du pavois", i * width * 0.30, 0, -0.084, width * 0.29, 1.94 + s.profile * 0.053,
				0.13, c:Lerp(wood, math.abs(i) * 0.32), M.WoodPlanks)
		end
		d.box("Renfort axial", 0, 0, -0.16, 0.19, 1.94, 0.19, t, M.Metal)
	elseif f == "shellshield" then
		d.ball("Carapace bombée", 0, 0, 0, width, 1.63, 0.53, c:Lerp(rgb(91, 114, 56), 0.53), M.Slate)
		for row = -1, 1 do
			for col = -1, 1 do
				local z = -0.22 + (math.abs(row) + math.abs(col)) * 0.032
				d.box("Plaque de carapace", col * width * 0.23, row * 0.42, z, 0.36, 0.35, 0.13,
					s.accent:Lerp(c, (row + col + 2) * 0.13), M.Slate, (row + col) * 0.12 + 0.36)
			end
		end
	else
		d.box("Écu", 0, 0.29, 0, width, 0.89, 0.19, c, M.WoodPlanks)
		d.tip("Pointe d’écu", V(0, -0.14, 0), V(0, -0.94, 0), width, 0.19, c, M.WoodPlanks)
		local ends = {V(-width / 2, 0.71, -0.085), V(width / 2, 0.71, -0.085)}
		for i, sign in pair do
			d.path("Bordure d’écu", {ends[i], V(sign * width / 2, -0.14, -0.085), V(0, -0.94, -0.085)},
				0.095, 0.10, t, M.Metal)
		end
		d.bar("Traverse supérieure", ends[1], ends[2], 0.12, 0.11, t, M.Metal)
		emblem(d, s, 0, 0.26, -0.109, width * 0.66)
	end
	if s.rarity >= 3 and f ~= "shield" then setting(d, 0, 0, f == "roundshield" and -0.287 or -0.25, width * 0.20, s) end
	d.box("Énarme", 0, 0.04, 0.13, width * 0.49, 0.18, 0.20, hide, M.Leather)
end

local function torch(d, s)
	d.box("Bois de torche", 0, -0.25, 0, 0.19, 1.16, 0.19, wood, M.Wood)
	d.disc("Cerclage", 0, 0.25, 0, 0.30, 0.14, s.metal, M.Metal, true)
	d.ball("Étoupe", 0, 0.39, 0, 0.34, 0.34, 0.35, hide, M.Fabric)
	d.tip("Flamme", V(0, 0.43, 0), V(0.08, 0.94, 0), 0.45, 0.26, rgb(247, 129, 48), M.SmoothPlastic)
	d.tip("Flammèche", V(0.02, 0.46, -0.07), V(-0.066, 0.77, -0.08), 0.23, 0.16, rgb(255, 199, 68), M.SmoothPlastic)
end

-- Les cols restent au torse, les manches suivent les bras et les pans longs suivent les cuisses.
local function torsoBody(r, name, color, material, width, depth)
	r.top.box(name, 0, -0.005, 0, width, 1.23, depth, color, material)
	r.waist.box("Doublure de taille", 0, 0.015, 0, 1.54, 0.72, 0.89, color, material)
end

local function torsoBelt(r, name, color, material, y, depth)
	r.waist.box(name, 0, y, 0, 1.67, 0.18, depth, color, material)
	local z = -depth / 2
	r.waist.box("Fermoir", 0, y, z, 0.29, 0.22, 0.092, r.edge, M.Metal)
	if r.rank >= 2 then
		for _, sign in pair do
			r.waist.disc(r.rank >= 3 and "Rivet doré" or "Rivet poli", sign * 0.24, y, z - 0.008,
				0.102, 0.052, r.edge, M.Metal)
		end
	end
	if r.rank >= 3 then
		r.waist.box("Filet de ceinture", 0, y + 0.075, z + 0.015, 1.62, 0.046, 0.065, r.edge, M.Metal)
	end
	if r.rank >= 4 then
		r.waist.box("Incrustation du fermoir", 0, y, z - 0.048, 0.125, 0.125, 0.065, r.accent, M.Glass, math.pi / 4)
	end
end

local function onArms(r, draw)
	if r.covered then return end
	for _, side in pair do draw(pen(r.emit, "shoulder", side), side) end
end

local function onThighs(r, draw)
	for _, side in pair do draw(pen(r.emit, "thigh", side), side) end
end

local function squareCollar(r, name, color, material, height)
	r.top.box(name, 0, 0.58 + height / 4, 0.375, 1.08, height, 0.24, color, material)
	for _, side in pair do
		r.top.box(name, side * 0.49, 0.55 + height / 4, 0.075, 0.19, height, 0.66, color, material)
	end
end

local function clothTorso(r, s)
	local f, color = s.form, r.color
	local thick = f == "gambeson" or s.name == "tenue de garde" or s.name:find("renforc", 1, true)
	local apron = f == "apron"
	local fabric = apron and s.name == "tablier de forgeron" and M.Leather or M.Fabric
	torsoBody(r, thick and "Corps matelassé" or "Toile cousue", color, M.Fabric, thick and 1.84 or 1.78, 0.92)
	if apron then
		local pocket = s.name == "tablier de semeur" and 0.54 or 0.37
		r.top.box("Bavette", 0, -0.13, -0.486, 1.02, 0.86, 0.16, color:Lerp(pale, 0.24), fabric)
		for _, side in pair do
			r.top.box("Bretelle", side * 0.38, 0.30, -0.474, 0.14, 0.48, 0.10, r.edge, fabric, side * -0.14)
		end
		onThighs(r, function(d, side)
			d.box("Jupe du tablier", -side * 0.035, 0.16, -0.41, 0.82, 0.82, 0.21, color:Lerp(pale, 0.24), fabric)
			d.box("Poche de métier", -side * 0.04, 0.10, -0.523, pocket, 0.27, 0.12, color, fabric)
		end)
	else
		for _, side in pair do
			r.top.bar("Revers de toile", V(side * 0.37, 0.55, -0.47), V(side * 0.075, 0.16, -0.49),
				0.13, 0.09, r.edge, M.Fabric)
			for i = 1, thick and 3 or 1 do
				r.top.box(thick and "Côte matelassée" or "Pli de lin", side * (0.02 + i * 0.23), -0.20,
					-0.478, thick and 0.19 or 0.12, 0.73, thick and 0.19 or 0.10,
					color:Lerp(pale, 0.06 + i * 0.055), M.Fabric, side * 0.075)
			end
		end
		if f == "tunic" then
			r.waist.box("Bas de tunique", 0, -0.25, -0.045, 1.62, 0.57, 0.97, color, M.Fabric)
		end
		onArms(r, function(d, side)
			d.box(thick and "Mancheron matelassé" or "Manche souple", -side * 0.036, thick and 0.24 or 0.16, 0,
				thick and 0.78 or 0.68, thick and 0.49 or 0.65, thick and 0.84 or 0.70, color, M.Fabric, -side * 0.08)
			d.box("Ourlet de manche", -side * 0.036, thick and 0.02 or -0.15, 0,
				thick and 0.77 or 0.69, 0.095, thick and 0.86 or 0.72, r.edge, M.Fabric, -side * 0.08)
		end)
	end
	torsoBelt(r, apron and "Lien de tablier" or "Ceinture tissée", hide, fabric, 0.04, 0.98)
end

local function leatherTorso(r, s)
	torsoBody(r, "Gilet en cuir", r.color:Lerp(dark, 0.21), M.Leather, 1.78, 0.93)
	for _, side in pair do
		r.top.box("Quartier de cuir", side * 0.41, -0.06, -0.48, 0.82, 1.06, 0.17, r.color, M.Leather, -side * 0.11)
		r.top.bar("Sangle croisée", V(side * 0.61, 0.49, -0.54), V(-side * 0.34, -0.44, -0.55),
			0.145, 0.11, side == 1 and r.edge or hide, M.Leather)
		r.waist.box("Basque de cuir", side * 0.59, -0.25, -0.12, 0.48, 0.49, 0.78, r.color, M.Leather, side * 0.17)
		if s.series == "loup" or s.series == "os" then
			local bone = s.series == "os"
			r.top.box(bone and "Agrafe d’os" or "Lisière de toison", side * 0.62, 0.46, -0.50,
				bone and 0.20 or 0.35, 0.22, 0.19, bone and ivory or r.color:Lerp(pale, 0.34),
				bone and M.SmoothPlastic or M.Fabric, -side * 0.24)
		end
	end
	if not s.name:find("^gilet") then
		onArms(r, function(d, side)
			d.box("Épaulette de sellerie", -side * 0.06, 0.35, 0, 0.77, 0.31, 0.80, r.color, M.Leather, -side * 0.26)
		end)
	end
	torsoBelt(r, "Baudrier de taille", hide, M.Leather, 0.055, 0.98)
end

local function brigandineTorso(r, s)
	torsoBody(r, "Enveloppe de brigandine", r.color:Lerp(soot, 0.27), M.Leather, 1.81, 0.95)
	local woodLames = s.material == "Wood"
	for _, side in pair do
		r.top.box("Pan riveté", side * 0.44, 0.02, -0.50, 0.84, 1.12, 0.16, r.color, M.Leather, -side * 0.05)
		if woodLames then
			r.top.box("Éclisse de bois de cœur", side * 0.43, 0.02, -0.57, 0.67, 0.97, 0.135,
				s.metal, M.Wood, -side * 0.05)
		end
		for row = 0, 1 do
			for col = 0, 1 do
				if woodLames and row == 1 and col == 0 then continue end
				local x, y = side * (0.25 + col * 0.34), 0.32 - row * 0.59
				if s.series == "os" then
					r.top.part("Cabochon d’os", V(0.14, 0.22, 0.10),
						C(x, y, -0.58) * A(0, 0, side * 0.19), ivory, M.SmoothPlastic, "wedge")
				else
					r.top.disc("Clou de brigandine", x, y, woodLames and -0.638 or -0.58, 0.15, 0.075, r.edge, M.Metal)
				end
			end
		end
		r.waist.box("Tassette rivetée", side * 0.45, -0.25, -0.45, 0.83, 0.52, 0.25, r.color, M.Leather, side * 0.10)
	end
	r.top.box("Fermeture de brigandine", 0, 0.05, -0.502, 0.13, 1.12, 0.15, hide, M.Leather)
	onArms(r, function(d, side)
		d.box("Épaulière carrée rivetée", -side * 0.04, 0.27, 0, 0.84, 0.53, 0.84,
			r.color:Lerp(soot, 0.14), M.Leather, -side * 0.085)
	end)
	torsoBelt(r, "Sangle de brigandine", hide, M.Leather, 0.04, 1.07)
end

local function mailTorso(r, s)
	local metal = s.metal:Lerp(r.color, 0.18)
	torsoBody(r, "Haubert", metal:Lerp(soot, 0.34), M.Metal, 1.79, 0.94)
	r.top.box("Encolure rabattue", 0, 0.49, -0.463, 1.17, 0.20, 0.14, metal, M.Metal)
	for row = 0, 1 do
		local y = 0.21 - row * 0.36
		local damask = s.name == "cotte damassée"
		r.top.box(damask and "Bande d’acier damassé" or "Bande de mailles", 0, y, -0.483, 1.61, 0.34, 0.12,
			damask and metal:Lerp(r.accent, 0.15 + row * 0.21) or metal:Lerp(soot, 0.20), M.Metal)
		local rings = row == 0 and not damask and 3 or 2
		for i = 1, rings do
			local x = (i - (rings + 1) / 2) * 0.47 + (row - 0.5) * 0.10
			local diameter = damask and 0.29 or 0.25
			r.top.disc("Anneau de haubert", x, y, -0.55, diameter, 0.078, metal:Lerp(pale, 0.42), M.Metal)
			r.top.disc("Creux du maillon", x, y, -0.59, diameter * 0.57, 0.023, soot, M.Metal)
		end
	end
	r.waist.box("Jupe du haubert", 0, -0.32, 0, 1.69, 0.80, 0.99, metal:Lerp(soot, 0.30), M.Metal)
	r.waist.box("Ourlet métallique", 0, -0.67, 0, 1.77, 0.13, 1.025, metal, M.Metal)
	onArms(r, function(d, side)
		d.box("Manche tombante de mailles", -side * 0.025, 0.07, 0, 0.75, 0.85, 0.77,
			metal:Lerp(soot, 0.32), M.Metal, -side * 0.07)
	end)
	torsoBelt(r, "Sangle du haubert", hide, M.Leather, 0.07, 1.035)
end

local function scaleTorso(r, s)
	local segment = s.form == "lamellarplate"
	local beast = s.torsoFamily ~= "ecailles"
	local material = segment and hard(s) or (s.series == "nord" and M.Glass or M.Slate)
	local color = segment and s.metal:Lerp(r.color, 0.21) or r.color:Lerp(r.accent, 0.26)
	torsoBody(r, segment and "Support lamellaire" or "Peau sous les écailles", r.color:Lerp(soot, 0.40), M.Leather, 1.79, 0.94)
	local collar = segment and "Barre de col" or beast and "Crête d’écailles" or "Encolure dentelée"
	r.top.box(collar, 0, 0.52, -0.364, 1.46, beast and 0.26 or 0.20, 0.31, color, material)
	if segment then
		for row = 0, 3 do
			r.top.box("Lame transversale", 0, 0.35 - row * 0.245, -0.50 - row * 0.013,
				1.76 - row * 0.13, 0.30, 0.23, color:Lerp(pale, row % 2 * 0.21), material)
		end
		for _, side in pair do
			r.top.box("Ligature lamellaire", side * 0.46, 0, -0.607, 0.095, 0.87, 0.105, r.edge, M.Leather, -side * 0.14)
		end
	else
		local step = 0.49 + (beast and (s.variant - 2) * 0.03 or 0)
		for row = 0, 2 do
			local tiles = row == 1 and 2 or 3
			for i = 1, tiles do
				local col = i - (tiles + 1) / 2
				local pose = C(col * step, 0.32 - row * 0.32, -0.52 - row * 0.025)
					* A(-0.26, col * -0.12, col * (beast and 0.16 or 0.08))
				r.top.part("Tuile d’écaille", V(step + 0.025, 0.44, 0.24), pose,
					color:Lerp((row + i) % 2 == 0 and pale or soot, 0.17), material, "wedge")
			end
		end
	end
	onArms(r, function(d, side)
		for row = 0, 1 do
			d.box(segment and "Épaulette à lames" or "Écaille d’épaule", side * (0.02 + row * 0.085), 0.39 - row * 0.20, 0,
				(segment and 0.81 or 0.92) - row * 0.11, 0.28, 0.87, color:Lerp(pale, row * 0.15), material, -side * 0.28)
		end
	end)
	for _, side in pair do
		r.waist.box(segment and "Lame de hanche" or "Écaille de hanche", side * 0.62, -0.26, -0.22, 0.52, 0.52, 0.66,
			color, material, side * 0.19)
	end
	torsoBelt(r, "Sangle des lames", hide, M.Leather, 0.045, 1.03)
end

local function plateTorso(r, s)
	local metal, material = s.metal:Lerp(r.color, 0.15), hard(s)
	local heavy = s.name:find("^armure") or s.name:find("^cuirasse")
	torsoBody(r, "Dossière de cuirasse", metal:Lerp(soot, 0.23), material, 1.84, 1.00)
	squareCollar(r, "Gorgerin", metal:Lerp(r.edge, 0.20), material, heavy and 0.34 or 0.23)
	for _, side in pair do
		r.top.part("Bombe facettée du plastron", V(0.89, 0.97, heavy and 0.35 or 0.28),
			C(side * 0.394, 0.053, -0.52) * A(0, -side * 0.31, -side * 0.13),
			metal:Lerp(pale, side == 1 and 0.12 or 0.025), material)
		r.waist.box("Tassette forgée", side * 0.48, -0.25, -0.45, 0.78, 0.54, 0.28, metal, material, side * 0.16)
	end
	r.top.bar("Arête de forge", V(0, 0.43, -0.68), V(0, -0.45, -0.65), 0.137, 0.14, metal:Lerp(pale, 0.39), material)
	r.waist.box("Lame du ventre", 0, 0.22, -0.41, 1.51, 0.30, 0.32, metal:Lerp(pale, 0.15), material)
	onArms(r, function(d, side)
		d.box("Coque de plates", side * 0.06, 0.39, 0, heavy and 1.05 or 0.91, heavy and 0.53 or 0.43,
			heavy and 1.03 or 0.90, metal, material, -side * 0.29)
		if heavy then
			d.box("Feuillet de spallière", side * 0.18, 0.08, 0, 0.81, 0.28, 0.89, metal:Lerp(r.edge, 0.29), material, -side * 0.33)
		end
	end)
	if s.name == "cuirasse des anciens" then
		r.top.box("Sceau taillé des anciens", 0, 0.13, -0.735, 0.39, 0.39, 0.16, r.edge, M.Slate, math.pi / 4)
	elseif s.series == "soleil" or s.series == "garde" or s.series == "lune" or s.series == "ronces" or s.series == "nord" then
		emblem(r.top, s, 0, 0.13, -0.735, 0.45)
	elseif s.name == "plastron serti de diamant" then
		setting(r.top, 0, 0.13, -0.735, 0.46, s)
	end
	torsoBelt(r, "Ceinturon de cuirasse", hide, M.Leather, 0.042, 1.12)
end

local function robeTorso(r, s)
	local coat, color = s.form == "coat", r.color
	local fur = s.name:find("fourr", 1, true) or s.name:find("loup", 1, true) or s.name:find("hiver", 1, true)
	local ice = s.name:find("givre", 1, true)
	local lining = fur and color:Lerp(pale, 0.43) or r.edge
	torsoBody(r, coat and "Drap de manteau" or "Corps de robe", color, M.Fabric, 1.80, 0.95)
	r.top.box(fur and "Collier de toison" or "Capuchon rabattu", 0, 0.47, 0.43, fur and 1.38 or 1.11,
		fur and 0.48 or 0.43, 0.41, lining, M.Fabric)
	for _, side in pair do
		r.top.bar(fur and "Revers de fourrure" or "Grand revers", V(side * 0.63, 0.51, -0.448),
			V(side * (coat and 0.20 or 0.10), -0.39, -0.48), fur and 0.28 or 0.19, 0.16, lining, M.Fabric)
		if ice then
			r.top.part("Cristal de l’encolure", V(0.31, 0.45, 0.25),
				C(side * 0.70, 0.58, -0.40) * A(0, side * 0.3, -side * 0.38), r.accent, M.Glass, "wedge")
		elseif fur then
			r.top.box("Mèche de toison", side * 0.73, 0.23, -0.46, 0.25, 0.40, 0.19, lining:Lerp(color, 0.28), M.Fabric, side * 0.27)
		end
	end
	r.waist.box("Drapé du bassin", 0, -0.15, 0, 1.70, 0.55, 0.98, color, M.Fabric)
	onThighs(r, function(d, side)
		local length = coat and 0.90 or 1.19
		local y = 0.56 - length / 2
		d.box("Pan long avant", side * 0.04, y, -0.44, coat and 0.77 or 0.88, length, 0.23, color, M.Fabric, side * 0.115)
		d.box("Pan long arrière", side * 0.04, y, 0.42, 0.86, length, 0.26, color:Lerp(dark, 0.18), M.Fabric, side * 0.115)
		d.box("Galon des pans", side * 0.09, y, -0.551, 0.112, length, 0.085, lining, M.Fabric, side * 0.115)
	end)
	onArms(r, function(d, side)
		d.box("Manche ample", -side * 0.02, 0.006, 0, coat and 0.80 or 0.85, 1.02, 0.84, color, M.Fabric, -side * 0.12)
	end)
	torsoBelt(r, coat and "Sangle du manteau" or "Écharpe de taille", color:Lerp(dark, 0.36), M.Fabric, 0.052, 1.05)
end

local function creatureTorso(r, s)
	local f = s.form
	if f == "scale" then
		scaleTorso(r, s)
	elseif f == "coat" then
		robeTorso(r, s)
	elseif f == "tunic" then
		clothTorso(r, s)
		if s.name:find("anguille", 1, true) then
			for _, side in pair do
				r.top.tip("Nageoire d’anguille", V(side * 0.59, 0.29, -0.47),
					V(side * 0.88, -0.44, -0.55), 0.34, 0.17, r.accent, M.Leather)
			end
		else
			for _, side in pair do
				r.top.path("Soie d’araignée", {V(0, -0.42, -0.53), V(side * 0.38, 0.04, -0.53),
					V(side * 0.73, 0.32 + s.profile * 0.025, -0.46)}, 0.072, 0.09, r.accent:Lerp(pale, 0.34), M.Fabric)
			end
		end
	else
		local beetle = f == "beetle"
		local size = 0.46 + s.variant * 0.042 + (s.soul and 0.11 or 0)
		local color = r.color:Lerp(r.accent, 0.24)
		local material = (s.series == "nord" or s.name:find("verre", 1, true)) and M.Glass or M.Slate
		if s.name:find("de bois", 1, true) then material = M.Wood end
		torsoBody(r, beetle and "Chitine dorsale" or "Coque du gardien", color:Lerp(soot, 0.37), material, 1.83, 1.00)
		for _, side in pair do
			r.top.part(beetle and "Élytre jointif" or "Côte du gardien", V(beetle and 0.92 or 0.58, 0.99, 0.32),
				C(side * (beetle and 0.437 or 0.56), 0.06, -0.49) * A(0, -side * 0.25, side * (beetle and 0.11 or 0.37)),
				color:Lerp(pale, side == 1 and 0.22 or 0.08), material)
			r.top.tip(beetle and "Mandibule de chitine" or "Éclat de la prise", V(side * 0.60, 0.36, -0.50),
				V(side * (beetle and 1.04 or 0.87), beetle and 0.86 or 0.68 + s.profile * 0.022, -0.52),
				beetle and 0.42 or 0.32, 0.25, color, material)
			r.waist.box(beetle and "Abdomen de chitine" or "Fragment de taille", side * 0.47, -0.20, -0.40,
				0.80, 0.53, 0.32, color, material, side * 0.16)
		end
		if beetle then
			r.top.box("Suture des élytres", 0, 0.02, -0.566, 0.135, 1.06, 0.17, soot, material)
			if s.soul then setting(r.top, 0, 0.27, -0.65, 0.35, s) end
		else
			r.top.disc("Logement de cœur", 0, 0.09, -0.55, size * 1.43, 0.33, s.metal, M.Metal)
			setting(r.top, 0, 0.09, -0.71, size, s, s.profile % 2 == 0 and "oval" or nil)
		end
		torsoBelt(r, "Attache de la prise", hide, M.Leather, 0.065, 1.08)
	end
end

local function legendaryTorso(r, s)
	-- La monture de reliquaire signe la pièce de dos, sur sa construction d'origine.
	local f = s.form
	if f == "mail" then
		mailTorso(r, s)
	elseif f == "brigandine" then
		brigandineTorso(r, s)
	elseif f == "plate" then
		plateTorso(r, s)
	else
		creatureTorso(r, s)
	end
	for _, side in pair do
		if s.name == "manteau du roi des loups" then
			r.top.part("Croc serti de la toison", V(0.16, 0.31, 0.14),
				C(side * 0.61, 0.38, -0.55) * A(math.pi, 0, side * 0.21), ivory, M.SmoothPlastic, "wedge")
		elseif s.name == "manteau des moissons" then
			r.top.bar("Épi brodé", V(side * 0.20, -0.24, -0.53), V(side * 0.54, 0.41, -0.52),
				0.105, 0.09, r.accent, M.Fabric)
		else
			r.top.bar("Double nervure de reliquaire", V(side * 0.71, 0.50, 0.48),
				V(side * 0.17, -0.34, 0.51), 0.13, 0.13, r.edge, M.Metal)
		end
	end
end

local torsoBuilders = {
	tissu = clothTorso, cuir = leatherTorso, brigandine = brigandineTorso, mailles = mailTorso,
	ecailles = scaleTorso, plates = plateTorso, robes = robeTorso, creatures = creatureTorso, legendaires = legendaryTorso,
}
local rankTints = { nil, rgb(154, 189, 202), rgb(224, 183, 106), rgb(245, 194, 94) }

local function torso(emit, s, options)
	local rank = math.clamp(s.rarity, 1, 4)
	local tint = rankTints[rank]
	local r = {
		emit = emit, top = pen(emit, "chest"), waist = pen(emit, "waist"), covered = options.covered,
		rank = rank, color = tint and s.color:Lerp(tint, rank * 0.045) or s.color,
		edge = tint and s.trim:Lerp(tint, rank * 0.14) or s.trim,
		accent = s.accent,
	}
	torsoBuilders[s.torsoFamily](r, s)
end

local function cloak(d, s)
	local f = s.form
	local length = (f == "mantle" and 1.30 or f == "splitcape" and 1.98 or f == "raincape" and 1.81 or f == "dresscape" and 2.78 or 2.41)
		+ s.profile * 0.039
	local fur = s.cloth == "fur" or f == "dresscape"
	local depth = f == "raincape" and 0.20 or 0.13
	local c, t = s.color, s.trim
	d.box("Col de cape", 0, 0.44, 0.23, 1.70, fur and 0.39 or 0.25, 0.74, fur and c:Lerp(pale, 0.31) or c,
		textile(s))
	if f ~= "splitcape" then
		local midWidth = f == "mantle" and 0.88 or 1.36
		d.box("Drap médian de cape", 0, 0.45 - length * 0.48, 0.537, midWidth, length * 0.97, depth,
			c:Lerp(pale, 0.049), textile(s))
		d.box("Galon médian", 0, 0.47 - length * 0.949, 0.59, midWidth, 0.12, 0.08, t, M.Fabric)
	end
	for _, side in pair do
		local spread = 0.47 + s.variant * 0.023
		local tilt = side * (f == "mantle" and 0.27 or f == "splitcape" and 0.16 or 0.12)
		local y = 0.48 - length * 0.48
		d.part("Pan de cape", V(f == "splitcape" and 0.82 or 1.02, length, depth),
			C(side * spread, y, 0.53) * A(-0.07, side * 0.09, tilt), c:Lerp(pale, side == 1 and 0.09 or 0.025), textile(s))
		local bottom = V(side * spread, y, 0.53) + (A(-0.07, side * 0.09, tilt) * V(0, -length / 2 + 0.05, depth / 2))
		d.box("Galon d’ourlet", bottom.X, bottom.Y, bottom.Z, f == "splitcape" and 0.83 or 1.04, 0.13, 0.070, t, M.Fabric, tilt)
		local pleatX = side * (spread + (s.cut % 3 - 1) * 0.09)
		d.bar("Pli de cape", V(pleatX, 0.39, 0.62), V(bottom.X + side * 0.09, bottom.Y + 0.08, bottom.Z),
			0.15 + s.variant * 0.021, 0.09, c:Lerp(pale, 0.18), textile(s))
	end
	-- Ornement au dos, visible sur la planche et avec la caméra de jeu.
	d.box("Empiècement", 0, 0.13, 0.573, f == "splitcape" and 0.42 or 0.60, 0.43, 0.11, c:Lerp(dark, 0.29), M.Fabric)
	emblem(d, s, 0, 0.13, 0.645, 0.35 + s.variant * 0.02)
	-- La bride et son fermoir avant rejoignent le col.
	d.box("Bride de cape", 0, 0.46, -0.14, 0.47, 0.12, 0.77, c, M.Fabric)
	d.ball("Fermoir", 0, 0.42, -0.52, 0.23, 0.21, 0.115, t, M.Metal)
end

local function plume(d, root, dx, dy, width, color)
	local tip = root + V(dx, dy, 0)
	d.tip("Vexille", root:Lerp(tip, 0.23), tip, width, 0.074, color, M.Fabric)
	d.bar("Rachis", root, tip, 0.048, 0.058, color:Lerp(ivory, 0.48), M.Fabric)
end

local function headdress(d, s)
	local f = s.form
	local c, t = s.color, s.trim
	local shift = (s.variant - 2) * 0.025 + (s.cut - 8) * 0.004
	local visor = -0.60
	if f == "closedhelm" or f == "nasalhelm" or f == "helmet" or f == "cresthelm" or f == "minerhelm" then
		local helm, material = s.metal:Lerp(c, 0.27), hard(s)
		if f == "closedhelm" then
			d.box("Timbre fermé", 0, 0.56, 0.04, 1.31, 0.29, 1.31, helm, material)
			d.box("Ventaille", 0, -0.15, -0.53, 1.19, 0.56 + shift, 0.23, helm, material)
			d.box("Traverse au-dessus des yeux", 0, 0.43, -0.57, 1.29, 0.25, 0.28, t, M.Metal)
			d.box("Fente de visée", 0, 0.207, -0.55, 1.14, 0.098, 0.19, soot, M.Metal)
			for _, side in pair do
				d.box("Joue du grand heaume", side * 0.60, 0.11, 0.04, 0.23, 1.06, 1.31, helm, material, side * 0.04)
				for i = 0, 2 do
					d.disc("Évent", side * (0.16 + i * 0.12), -0.18 - i % 2 * 0.09, -0.651, 0.062, 0.03, soot, M.Metal)
				end
			end
			d.box("Nuquière", 0, 0.09, 0.55, 1.23, 0.91, 0.26, helm, material)
			emblem(d, s, 0, -0.20, -0.661, 0.34)
		else
			d.ball("Calotte du casque", 0, 0.48, 0.025, 1.41 + shift, 0.73 + shift, 1.37, helm, material)
			d.disc("Bandeau de front", 0, 0.34, 0, 1.41 + shift, 0.19, t, M.Metal, true)
			for _, side in pair do
				d.box("Garde de joue", side * 0.60, 0.04, 0.081, 0.17, f == "helmet" and 0.51 or 0.41, 0.67,
					helm, material, side * 0.13)
			end
			if f == "cresthelm" then
				d.part("Crête sagittale", V(0.25 + shift, 0.59 + s.profile * 0.026, 0.94), C(0, 0.85, 0.03) * A(-0.17, 0, 0),
					t, M.Metal, "ball")
				d.box("Arêtier de crête", 0, 0.67, -0.025, 0.19, 0.24, 1.22, s.accent, material)
			elseif f == "nasalhelm" then
				d.box("Nasal articulé", 0, 0.135, visor - 0.09, 0.17 + shift, 0.55 + s.profile * 0.031, 0.17, t, M.Metal)
				d.box("Nasal, liseré", 0, -0.04, visor - 0.173, 0.09, 0.23 + s.cut * 0.012, 0.04, helm, material)
			elseif f == "minerhelm" then
				d.box("Support de lampe", 0, 0.40, -0.66, 0.37, 0.36, 0.22, t, M.Metal)
				d.disc("Verre de lampe", 0, 0.40, -0.79, 0.29, 0.10, rgb(245, 199, 97), M.Glass)
			else
				emblem(d, s, 0, 0.40, visor - 0.055, 0.34 + shift)
			end
		end
	elseif f == "hood" or f == "cowl" or f == "mask" then
		local material = textile(s)
		if f == "mask" then
			d.box("Masque de tissu", 0, -0.27, -0.58, 1.22, 0.37 + shift, 0.20, c:Lerp(soot, 0.46), material)
			for _, side in pair do
				d.part("Lien du masque", V(0.13, 0.17, 0.93),
					C(side * 0.56, -0.22, -0.20) * A(side * 0.06, 0, side * 0.14), c, material)
				d.bar("Galon du masque", V(0, -0.10, -0.675), V(side * 0.53, -0.13, -0.66), 0.075, 0.052, t, material)
			end
			d.tip("Pointe du masque", V(0, -0.41, -0.59), V(shift, -0.61 - s.profile * 0.018, -0.59),
				0.69, 0.18, c, material)
		else
			d.ball("Sommet de capuche", 0, 0.56, 0.11, 1.44, 0.60, 1.38, c, material)
			d.box("Nuque drapée", 0, 0, 0.53, 1.26, 1.28, 0.33, c, material)
			d.part("Pointe rabattue", V(0.52, 0.48 + s.profile * 0.045, 0.64),
				C(shift, 0.67, 0.37) * A(0.22, 0, -0.10), c:Lerp(pale, 0.12), material, "wedge")
			for _, side in pair do
				d.box("Drapé de joue", side * 0.55, -0.04, -0.06, 0.26, 1.02, 1.2, c, material, side * 0.12)
				d.path("Galon de l’ouverture", {V(0, 0.52, -0.555), V(side * 0.49, 0.35, -0.56),
					V(side * 0.53, -0.29, -0.62), V(side * (0.77 + shift), -0.68, -0.53)}, 0.105, 0.075, t, material)
				d.tip("Patte de capuche", V(side * 0.52, -0.31, -0.48), V(side * (0.78 + shift), -0.77, -0.48),
					0.33, 0.29, c, material)
				if s.trait == "wing" then
					d.tip("Aile membraneuse", V(side * 0.58, 0.21, 0), V(side * (0.96 + s.profile * 0.065), 0.70, 0),
						0.43, 0.16, c:Lerp(soot, 0.51), M.Leather)
				end
			end
			if f == "cowl" then
				d.box("Masque cousu à la cagoule", 0, -0.28, -0.59, 1.13, 0.35, 0.17, c, material)
			elseif s.rarity >= 3 then d.ball("Agrafe de capuche", 0.55, -0.25, -0.66, 0.25, 0.25, 0.11, t, M.Metal) end
		end
	elseif f == "crown" or f == "diadem" or f == "antlers" or f == "headband" or f == "feathered" then
		local regal = f == "crown" or f == "diadem"
		local color = regal and t or c
		local mat = regal and M.Metal or M.Leather
		local y = f == "headband" and 0.26 or 0.50
		d.loop("Cercle de coiffe", 0, y, 0, 0.66, 0.65, 10, regal and 0.17 or 0.195, color, mat, true)
		if f == "antlers" then
			for _, side in pair do
				local base = V(side * 0.51, y, -0.30)
				local joint = base + V(side * (0.28 + shift), 0.63 + s.profile * 0.035, 0)
				d.bar("Andouiller de ramure", base, joint, 0.20, 0.18, ivory:Lerp(c, 0.31), M.Wood)
				d.tip("Pointe de ramure", joint, joint + V(side * 0.16, 0.47 + shift, 0), 0.19, 0.16, ivory, M.Wood)
				d.bar("Fourche de ramure", base:Lerp(joint, 0.53), joint + V(-side * 0.32, 0.15, 0), 0.15, 0.15, ivory, M.Wood)
			end
		elseif regal then
			local height = f == "diadem" and 0.21 or 0.44 + s.profile * 0.033
			for i = -2, 2 do
				local a = i * 0.59
				local x, z = math.sin(a) * 0.65, -math.cos(a) * 0.60
				d.tip("Fleuron", V(x, y, z), V(x * 1.04, y + height * (1 - math.abs(i) * 0.12), z),
					0.24 + shift, 0.12, color, M.Metal)
			end
			setting(d, 0, y + height * 0.27, -0.685, f == "diadem" and 0.31 or 0.25, s)
		elseif f == "headband" then
			d.box("Cache-œil", -0.25, 0.065, -0.60, 0.37, 0.31, 0.16, soot, M.Leather, -0.16)
			d.ball("Nœud", 0.58, 0.19, 0.30, 0.33, 0.26, 0.28, t, M.Fabric)
			d.box("Pan du bandeau", 0.72, -0.02, 0.29, 0.16, 0.49, 0.088, c, M.Fabric, 0.37)
		else
			local colorFeather = s.accent:Lerp(c, 0.25)
			for i = 0, s.profile % 3 + 1 do
				plume(d, V(-0.46 + i * 0.10, y, -0.47), -0.52 + i * 0.22,
					0.58 + i * 0.16 + shift, 0.24 + s.variant * 0.014, colorFeather:Lerp(pale, i * 0.10))
			end
			d.ball("Agrafe à plumes", -0.42, y, -0.54, 0.29, 0.22, 0.16, t, M.Metal)
		end
	elseif f == "goggles" then
		d.loop("Courroie de lunettes", 0, 0.11, 0, 0.65, 0.63, 10, 0.12, hide, M.Leather, true)
		for _, side in pair do
			d.disc("Monture de loupe", side * 0.31, 0.11, -0.59, 0.52, 0.21, t, M.Metal)
			d.disc("Verre de loupe", side * 0.31, 0.11, -0.711, 0.41, 0.090, rgb(140, 179, 163), M.Glass)
		end
		d.box("Pont de lunettes", 0, 0.13, -0.64, 0.36, 0.13, 0.12, t, M.Metal)
	elseif f == "turban" or f == "bonnet" or f == "chapka" or f == "beret" or f == "toque" then
		if f == "turban" then
			local desert = s.name:find("désert", 1, true)
			d.ball("Drap du turban", 0, 0.47, 0, 1.43, desert and 0.93 or 0.71, 1.39, c, M.Fabric)
			for i = 0, 3 do
				local w = 1.39 - i * 0.066
				d.part("Pli enroulé", V(0.22, w, w), C(0, 0.27 + i * 0.15, 0) * A(0, 0, math.pi / 2 + (i % 2 == 0 and 0.23 or -0.17)),
					c:Lerp(i % 2 == 0 and pale or dark, 0.16 + shift), M.Fabric, "cylinder")
			end
			d.box("Extrémité du turban", 0.47, desert and -0.03 or 0.11, 0.09, 0.28, desert and 0.88 or 0.62,
				0.20, t, M.Fabric, desert and -0.39 or -0.18)
		elseif f == "toque" then
			d.disc("Bandeau de toque", 0, 0.61, 0, 1.27, 0.28, c:Lerp(dark, 0.14), M.Fabric, true)
			d.disc("Fût de toque", 0, 0.95 + shift, 0, 1.21, 0.63, c, M.Fabric, true)
			for i = 0, 4 do
				local a = i * turns / 5
				d.ball("Gonfle de toque", math.cos(a) * 0.31, 1.28 + shift, math.sin(a) * 0.31,
					0.68, 0.51, 0.68, c:Lerp(pale, i * 0.08), M.Fabric)
			end
		elseif f == "beret" then
			d.disc("Tour de béret", 0, 0.55, 0, 1.21, 0.15, c:Lerp(dark, 0.34), M.Fabric, true)
			d.part("Drap incliné du béret", V(1.53, 0.31 + shift, 1.36), C(0.20, 0.70, 0) * A(0, 0, -0.18), c, M.Fabric, "ball")
			d.box("Cabillou", 0.21, 0.86, 0, 0.105, 0.18, 0.10, t, M.Fabric, 0.23)
		else
			d.ball("Calotte souple", 0, 0.54, 0.02, 1.34 + shift, f == "chapka" and 0.72 or 0.88, 1.32, c, M.Fabric)
			d.disc("Revers", 0, 0.39, 0, 1.34 + shift, 0.28, c:Lerp(pale, f == "chapka" and 0.41 or 0.19), M.Fabric, true)
			if f == "chapka" then
				for _, side in pair do
					d.box("Oreillette fourrée", side * 0.57, 0.02, 0.04, 0.38, 0.71, 0.52, c:Lerp(ivory, 0.34), M.Fabric, side * 0.19)
				end
				bentPoint(d, "Queue de renard", V(-0.48, 0.26, 0.44), -0.44, -0.64 - s.profile * 0.044,
					0.32, 0.30, c:Lerp(ivory, 0.25), M.Fabric)
			else
				d.ball("Pompon", 0.21 + shift * 4, 0.93, 0.12, 0.34, 0.37, 0.36, t, M.Fabric)
			end
		end
	else
		local mage, mushroom = f == "magehat", f == "mushroom"
		local brim = f == "tricorn" and 1.82 or f == "hunterhat" and 2.04 or mage and 2.13 or mushroom and (1.66 + s.profile * 0.058)
			or f == "strawhat" and 2.13 or f == "fisherhat" and 1.64 or f == "tophat" and 1.75 or 1.86
		local base = 0.58
		if mushroom then
			d.disc("Lamelles de champignon", 0, base, 0, brim, 0.16, ivory, M.Fabric, true)
			d.ball("Chapeau fongique", 0, base + 0.27, 0, brim, 0.74 + s.variant * 0.063, brim, c:Lerp(s.accent, 0.40), M.Fabric)
			for i = 0, 2 + s.variant do
				local angle = i * 2.40 + s.profile
				d.ball("Spore enchâssée", math.cos(angle) * brim * 0.30, base + 0.47 + (i % 2) * 0.075,
					math.sin(angle) * brim * 0.30, 0.22, 0.16, 0.23, ivory, M.Fabric)
			end
			if s.rarity >= 4 then setting(d, 0, base + 0.11, -brim * 0.47, 0.24, s) end
		else
			d.disc("Bord du chapeau", 0, base, 0, brim + shift, 0.13, c, M.Fabric, true)
			if mage then
				d.ball("Calotte de mage", 0, 0.77, 0.02, 1.26, 0.48, 1.22, c, M.Fabric)
				bentPoint(d, "Pointe de mage", V(0, 0.79, 0.03), 0.45 + shift, 1.32, 0.82, 0.77, c, M.Fabric)
			elseif f == "tricorn" then
				d.ball("Calotte du tricorne", 0, 0.76, 0, 1.23, 0.61, 1.18, c, M.Fabric)
				for i = 0, 2 do
					local a = i * turns / 3
					d.part("Aile relevée", V(1.15, 0.48 + shift, 0.20), A(0, a, 0) * C(0, 0.75, -0.69) * A(-0.39, 0, 0),
						c, M.Fabric, "wedge")
					d.part("Galon du tricorne", V(0.86, 0.086, 0.11), A(0, a, 0) * C(0, 0.81, -0.75), t, M.Fabric)
				end
			else
				local crown = f == "tophat" and 0.91 or f == "fisherhat" and 0.42 or 0.55 + shift
				d.disc("Calotte du chapeau", 0, base + crown / 2, 0, 1.24 + shift, crown, c, M.Fabric, true)
				if f == "fisherhat" then
					for _, side in pair do
						d.box("Bord rabattu", side * 0.69, 0.48, 0, 0.42, 0.12, 1.04, c, M.Fabric, side * -0.42)
					end
				elseif f == "hunterhat" then
					d.box("Bord de traqueur relevé", -0.66, 0.69, -0.25, 0.44, 0.18, 0.96, c, M.Leather, -0.48)
					d.box("Boucle de traqueur", -0.34, 0.78, -0.50, 0.27, 0.24, 0.17, t, M.Metal, 0.28)
				elseif f == "featherhat" then
					plume(d, V(-0.52, 0.67, -0.32), -0.30 - shift, 0.73 + s.profile * 0.069, 0.35, s.accent)
				elseif f == "strawhat" then
					d.disc("Tresse de paille", 0, base + 0.052, 0, brim * 0.91, 0.08, c:Lerp(dark, 0.13), M.Fabric, true)
				end
			end
			d.disc("Ruban du chapeau", 0, base + 0.12, 0, 1.29 + shift, 0.16, t, M.Fabric, true)
			if f ~= "tricorn" then emblem(d, s, 0, base + 0.15, -0.665, 0.28 + shift) end
		end
	end
end

local function hands(emit, s)
	local f, t = s.form, s.trim
	local plate = f == "gauntlets"
	for _, side in pair do
		local d = pen(emit, "palm", side)
		local cuff = pen(emit, "forearm", side)
		local wrist = f == "bracer" and cuff or d
		local y = f == "bracer" and -0.05 or 0.20
		local material, color = plate and hard(s) or textile(s), plate and s.metal or s.color
		wrist.box("Manchette", 0, y, 0, f == "bracer" and 0.62 or 0.55,
			(f == "bracer" and 0.66 or 0.24) + s.variant * 0.023, 0.55, color, material)
		wrist.box("Sangle de poignet", 0, y + 0.08, 0, f == "bracer" and 0.65 or 0.58, 0.095, 0.58, t, M.Leather)
		wrist.box("Fermoir de poignet", side * 0.11, y + 0.08, -0.29, 0.17, 0.14, 0.07, t, M.Metal)
		if f ~= "bracer" then
			d.ball(f == "mittens" and "Moufle de laine" or "Paume", 0, -0.04, 0.014, 0.54, 0.55, 0.51, s.color, textile(s))
			local length = (f == "fingerless" and 0.15 or f == "gloves" and 0.25 or 0.30) + s.cut * 0.004
			if f ~= "mittens" then
				for i = -1, 1 do
					d.box("Doigt du gant", i * 0.139, -0.225 - length * 0.23, -0.015, 0.13, length - math.abs(i) * 0.038,
						0.31, color, material, i * 0.12)
				end
			end
			d.part("Pouce du gant", V(0.19, 0.30 + s.variant * 0.018, 0.28), C(-side * 0.235, -0.095, -0.02)
				* A(0, 0, -side * 0.40), s.color, textile(s), "ball")
			if plate then
				for i = 0, 2 do
					d.box("Plaque de gantelet", 0, 0.12 - i * 0.15, -0.24, 0.48 - i * (0.019 + s.profile * 0.008), 0.125, 0.13,
						color:Lerp(t, i * 0.14), material)
				end
				if s.rarity >= 3 then setting(d, 0, 0.11, -0.313, 0.19, s) end
			elseif s.rarity >= 2 then
				d.bar("Couture de gant", V(-0.16, 0.08, -0.205), V(0.16, -0.155, -0.214), 0.058, 0.060, t, M.Fabric)
			end
		end
	end
end

local function shoulders(emit, s)
	local f = s.form
	local isFur = s.cloth == "fur" and s.name:find("fourrure", 1, true)
	local material = isFur and M.Fabric or (s.trait == "crest" or s.name:find("pierre", 1, true)) and M.Slate or hard(s)
	local c = material == M.Fabric and s.color or s.metal:Lerp(s.color, 0.31)
	for _, side in pair do
		local d = pen(emit, "shoulder", side)
		d.part("Coque d’épaule", V(0.91 + s.variant * 0.039, 0.47 + s.cut * 0.011, 0.89),
			C(side * 0.11, 0.26, 0) * A(0, 0, side * 0.22), c, material, "ball")
		local rows = f == "lamellar" and 4 or isFur and 1 or f == "pauldrons" and 2 or 1
		for i = 0, rows - 1 do
			d.part("Lame d’épaule", V(0.87 - i * 0.075, 0.23, 0.83 - i * 0.057),
				C(side * (0.12 - i * 0.02), 0.13 - i * 0.16, 0) * A(0, 0, side * 0.22),
				c:Lerp(s.trim, (i + s.profile % 2) % 3 * 0.14), material, "ball")
		end
		if f == "hornshoulder" then
			bentPoint(d, "Corne de spallière", V(side * 0.23, 0.31, -0.03), side * (0.35 + s.variant * 0.05),
				0.43 + s.profile * 0.04, 0.26, 0.22, ivory:Lerp(s.accent, 0.35), M.SmoothPlastic)
		elseif s.name:find("pierre", 1, true) then
			d.tip("Éclat de gargouille", V(side * 0.22, 0.31, 0.03), V(side * 0.45, 0.70, 0.04), 0.31, 0.38, c, M.Slate)
		end
		d.ball("Rivet d’épaule", side * 0.13, 0.24, -0.403, 0.22, 0.21, 0.13, s.trim, M.Metal)
		if s.rarity >= 3 then setting(d, side * 0.16, 0.05, -0.385, 0.18, s) end
	end
end

local function legs(emit, s, options)
	local f = s.form
	local soft = f == "pants" or f == "leggings"
	local c, t, material = s.color, s.trim, textile(s)
	if soft then
		local d = pen(emit, "waist")
		d.box("Ceinture de chausses", 0, -0.11, 0, 1.57, 0.32, 0.89, hide, M.Leather)
		d.box("Boucle des chausses", 0, -0.11, -0.45, 0.29, 0.23, 0.11, t, M.Metal)
	end
	for _, side in pair do
		local d = pen(emit, "shin", side)
		if soft then
			local thigh = pen(emit, "thigh", side)
			local w = (f == "leggings" and 0.71 or 0.79) + s.cut * 0.005 + s.profile * 0.002
			thigh.box("Cuisse vêtue", 0, 0.04, 0, w, 1.14, 0.77, c, material)
			thigh.bar("Couture extérieure", V(side * w * 0.45, 0.56, -0.382), V(side * w * 0.37, -0.49, -0.382),
				0.085 + s.variant * 0.012, 0.072, t, M.Fabric)
			local height = options.tallboots and 0.66 or 1.09
			d.box("Bas de chausses", 0, 0.55 - height / 2, 0, w - 0.055, height, 0.71, c, material)
			d.box("Ourlet des chausses", 0, 0.59 - height, 0, w - 0.026, 0.10, 0.74, t, material)
		else
			local pad = f == "kneepads"
			local fur = s.name:find("fourrure", 1, true) ~= nil
			local surface = fur and M.Fabric or pad and M.Leather or hard(s)
			local color = (fur or pad) and c or s.metal
			local length = pad and 0.44 or 1.01 + s.cut * 0.009
			d.box("Doublure de jambières", 0, 0.42 - length / 2, 0.015, 0.72, length, 0.71, color, surface)
			d.ball("Coquille de genou", 0, 0.363, -0.26, 0.71, 0.47 + s.profile * 0.027, 0.40, color:Lerp(t, 0.27), surface)
			if fur then
				d.box("Revers fourré", 0, -0.43, 0, 0.84, 0.28, 0.82, c:Lerp(pale, 0.42), M.Fabric)
			elseif not pad then
				d.tip("Arête de grève", V(0, 0.31, -0.40), V((s.variant - 2) * 0.058, -0.58, -0.36),
					0.61, 0.16, color, surface)
			end
			for i = 0, pad and 0 or 1 do
				d.box("Sangle de genou", 0, 0.13 - i * 0.52, 0, 0.75, 0.13, 0.72, hide, M.Leather)
			end
			if s.rarity >= 3 then setting(d, 0, 0.36, -0.456, 0.22, s) end
		end
	end
end

local function boots(emit, s)
	local f = s.form
	local plate, clog, tall = f == "sabatons", f == "clogs", f == "tallboots"
	local material = plate and hard(s) or clog and M.Wood or textile(s)
	local c = plate and s.metal or clog and wood or s.color
	for _, side in pair do
		local d = pen(emit, "foot", side)
		local shin = pen(emit, "shin", side)
		d.box("Semelle", 0, -0.16, -0.025, 0.72 + s.variant * 0.031, 0.18, 1.11, clog and wood:Lerp(dark, 0.21) or dark,
			clog and M.Wood or M.Leather)
		d.ball("Bout de chaussure", 0, -0.026, -0.22, 0.69 + s.variant * 0.025, 0.51, 0.89 + s.profile * 0.043, c, material)
		d.box("Empeigne", 0, 0.09, 0.10, 0.67, 0.40, 0.72, c, material)
		if plate then
			for i = 0, 3 do
				d.box("Lame de soleret", 0, 0.157 - i * 0.048, -0.14 - i * (0.104 + s.profile * 0.009), 0.69 - i * 0.045,
					0.12, 0.16, c:Lerp(s.trim, i % 2 * 0.27), material)
			end
		else
			d.box("Bride de cou-de-pied", 0, 0.17, -0.052, 0.73, 0.11, 0.42, s.trim, M.Leather, (s.variant - 2) * 0.064)
			d.box("Boucle de chaussure", side * 0.21, 0.20, -0.17, 0.21, 0.12, 0.19, s.trim, M.Metal)
		end
		if not clog then
			local length = tall and 0.78 + s.variant * 0.046 or plate and 0.32 or 0.42
			shin.box("Tige de botte", 0, -0.54 + length / 2, 0, 0.72, length, 0.73, c, material)
			local fur = s.name:find("fourrées", 1, true)
			shin.box("Revers de botte", 0, -0.55 + length, 0, fur and 0.88 or 0.79, fur and 0.29 or 0.14,
				fur and 0.90 or 0.78, fur and s.color:Lerp(ivory, 0.45) or s.trim, fur and M.Fabric or plate and material or M.Leather)
			if tall then
				shin.bar("Sangle de tige", V(-0.28, -0.25, -0.37), V(0.28, 0.06, -0.37), 0.095, 0.060, hide, M.Leather)
			end
			if s.rarity >= 3 then setting(shin, 0, -0.55 + length, -0.388, 0.21, s) end
		end
	end
end

local function jewelry(d, s)
	local f, t, c = s.form, s.trim, s.color
	if f == "ring" or f == "signet" or f == "bracelet" then
		local bracelet = f == "bracelet"
		local rx = (bracelet and 0.63 or 0.43) + s.variant * 0.014
		local ry = bracelet and 0.39 or 0.45
		local band = (bracelet and 0.16 or 0.11) + s.profile * 0.009
		local metal = s.metal:Lerp(t, 0.47)
		local woven = bracelet and (s.material == "Bone" or s.cloth:find("leather", 1, true) or s.trait == "hair")
		d.loop(bracelet and "Jonc" or "Anneau", 0, 0, 0, rx, ry, bracelet and 10 or 8, band, woven and c or metal,
			woven and M.Leather or M.Metal)
		local width = (f == "signet" and 0.42 or bracelet and 0.29 or 0.26) + s.variant * 0.021
		if f == "signet" or s.rarity >= 2 or s.mark == "gem" then
			d.box(f == "signet" and "Chaton de chevalière" or "Monture du bijou", 0, ry + 0.017, 0, width * 1.10,
				width * 0.86, 0.24, metal, M.Metal, f == "signet" and 0.043 * s.profile or 0)
			if s.rarity >= 3 or s.mark == "gem" then
				setting(d, 0, ry + 0.033, -0.128, width * 0.83, s, s.profile % 2 == 0 and "oval" or nil)
			else
				d.box("Table ciselée", 0, ry + 0.018, -0.124, width * 0.77, width * 0.63, 0.062, t, M.Metal, 0.27)
			end
		end
		for _, side in pair do
			local x = side * rx * 0.69
			d.box(bracelet and "Plaque de bracelet" or "Épaulement d’anneau", x, ry * 0.71, -band * 0.24,
				bracelet and 0.26 or 0.19, bracelet and 0.23 or 0.14, band * 1.19, t, M.Metal, side * -0.62)
		end
		if bracelet then
			d.box(woven and "Fermoir de tresse" or "Fermoir à charnière", 0, -ry, 0, 0.34, band * 1.38, band * 1.26, c, M.Leather)
			if s.trait == "hair" then
				d.path("Tresse de crin", {V(-rx, 0, -0.07), V(-rx * 0.70, -ry * 0.57, -0.09),
					V(0, -ry, -0.09), V(rx * 0.70, -ry * 0.57, -0.09), V(rx, 0, -0.07)}, 0.12, 0.09, t, M.Fabric)
			end
		end
		return
	elseif f == "brooch" then
		local width = 0.54 + s.variant * 0.066
		d.box("Monture de broche", 0, 0, 0, width, width, 0.18, s.metal, M.Metal, math.pi / 4)
		d.bar("Aiguille de broche", V(-width * 0.93, -0.17, 0.065), V(width * 0.85, 0.22, 0.065), 0.078, 0.13, t, M.Metal)
		d.ball("Charnière de broche", -width * 0.61, -0.12, 0.09, 0.19, 0.16, 0.17, t, M.Metal)
		emblem(d, s, 0, 0, -0.105, width * 0.85)
		return
	end
	local necklace = f == "necklace"
	local clasp = f == "medallion" or f == "amulet" or f == "talisman" or f == "pendant"
	local trophy = necklace and (s.trait == "fangs" or s.trait == "claws" or s.trait == "bone")
	local width = (necklace and 0.78 or 0.62) + s.variant * 0.023
	local depth = (necklace and 0.72 or 0.56) + s.cut * 0.008
	local drop = -0.46 - s.profile * 0.023
	local mount = drop - (clasp and 0.20 or 0.02)
	local chain = s.series == "lin" and M.Fabric or trophy and M.Leather or M.Metal
	for _, side in pair do
		d.path(chain == M.Metal and "Chaîne ciselée" or "Cordon noué", {V(0, depth, 0), V(width * side * 0.73, depth - 0.14, 0),
			V(side * width, 0.17, 0), V(side * width * 0.69, drop + 0.15, 0), V(0, drop, 0)},
			necklace and 0.106 or 0.072, 0.093, chain == M.Leather and hide or t, chain)
	end
	if trophy then
		local teeth = 3 + (s.profile % 2) * 2
		local spacing = width * (teeth == 3 and 0.44 or 0.30)
		for i = 1, teeth do
			local offset = i - (teeth + 1) / 2
			local x = offset * spacing
			local y = drop + math.abs(x) * 0.56
			local root = V(x, y, -0.011)
			local dx, dy = (s.variant - 2 + offset) * 0.048, -0.24 - s.cut * 0.021 + math.abs(offset) * 0.039
			local breadth, color = 0.16 + s.variant * 0.013, ivory:Lerp(s.accent, 0.20)
			if math.abs(offset) == 2 then
				d.tip("Dent d’extrémité", root, root + V(dx, dy, 0), breadth, 0.12, color, M.SmoothPlastic)
			else
				bentPoint(d, s.trait == "fangs" and "Croc suspendu" or "Griffe ligaturée", root, dx, dy, breadth, 0.12,
					color, M.SmoothPlastic)
			end
		end
		if s.rarity >= 4 then setting(d, 0, drop - 0.04, -0.094, 0.19, s) end
	elseif necklace then
		for i = -2, 2 do
			local x = i * width * (0.25 + s.variant * 0.015)
			local y = drop + math.abs(i) * width * 0.16
			d.ball("Perle du collier", x, y, -0.048, 0.20, i == 0 and 0.30 or 0.21, 0.17,
				i % 2 == 0 and s.accent or t, M.Glass)
		end
	elseif clasp then
		d.box("Bélière", 0, drop - 0.067, 0, 0.14, 0.25, 0.13, t, M.Metal)
		local w = (f == "medallion" and 0.61 or f == "amulet" and 0.48 or 0.38) + s.variant * 0.040
		if s.trait == "ear" or s.trait == "dust" then
			d.tip("Prise en pointe", V(0, mount + 0.12, 0), V(w * (0.18 + s.cut * 0.031), mount - 0.42 - s.profile * 0.029, 0), w, 0.21,
				s.accent:Lerp(c, 0.33), M.Leather)
			d.box("Anneau de prise", 0, mount + 0.09, 0, w * 0.72, 0.17, 0.23, t, M.Metal)
			if s.rarity >= 3 then setting(d, 0, mount + 0.016, -0.118, w * 0.45, s) end
		elseif s.trait == "bone" then
			d.box("Bague de ligature", 0, mount + 0.035, 0, w * 0.80, 0.23, 0.24, t, M.Metal)
			bentPoint(d, "Pointe d’os sculptée", V(0, mount + 0.06, 0), w * (0.48 + s.profile * 0.07),
				-w * 1.72, w * 0.69, 0.21, ivory, M.SmoothPlastic)
			if s.rarity >= 3 then setting(d, 0, mount + 0.026, -0.126, w * 0.50, s) end
		elseif f == "medallion" then
			d.disc("Médaillon frappé", 0, mount - w * 0.17, 0, w, 0.18, s.metal, M.Metal)
			emblem(d, s, 0, mount - w * 0.17, -0.115, w * 0.77)
		elseif f == "talisman" or s.trait == "essence" then
			local y = mount - w * 0.20
			if s.profile % 3 == 0 then
				d.disc("Châsse d’essence", 0, y, 0, w * 1.23, 0.23, t, M.Metal)
			elseif s.profile % 3 == 1 then
				d.tip("Châsse en pointe", V(0, mount + 0.05, 0), V(w * 0.11, mount - w * 0.91, 0), w * 1.30, 0.24, t, M.Metal)
			else
				d.box("Châsse ajourée", 0, y, 0, w * 0.90, w * 0.94, 0.22, t, M.Metal, math.pi / 4)
			end
			if s.soul or s.name:find("spectre", 1, true) then
				for _, sign in pair do
					d.tip(s.soul and "Griffe de châsse" or "Pointe spectrale", V(sign * w * 0.20, y + 0.02, 0),
						V(sign * w * (0.69 + s.cut * 0.02), y + w * 0.55, 0), w * 0.32, 0.14, t, M.Metal)
				end
			end
			setting(d, 0, y, -0.129, w * 0.69, s, s.profile % 2 == 0 and "oval" or nil)
		elseif s.trait == "gel" then
			d.disc("Capsule de gelée", 0, mount - w * 0.15, 0, w * 1.14, 0.22, t, M.Metal)
			d.ball("Gelée dans sa capsule", 0, mount - w * 0.15, -0.12, w, w * (0.69 + s.cut * 0.025), 0.26, s.accent, M.Glass)
			for i = -1, 1 do
				d.ball("Bulle de gelée", i * w * 0.21, mount - i * 0.04, -0.23, 0.09, 0.10, 0.058,
					s.accent:Lerp(pale, 0.58), M.Glass)
			end
			if s.soul then
				d.box("Agrafe royale", 0, mount + 0.09, -0.066, w * 0.86, 0.22, 0.25, t, M.Metal, 0.21)
			end
			if s.rarity >= 4 then setting(d, 0, mount - w * 0.45, -0.16, w * 0.38, s) end
		else
			d.box("Cadre du pendentif", 0, mount - w * 0.20, 0, w, w, 0.21, t, M.Metal, math.pi / 4)
			setting(d, 0, mount - w * 0.20, -0.11, w * 0.81, s, s.profile % 2 == 0 and "oval" or nil)
		end
	end
end

local function accessory(d, s)
	local f, c, t = s.form, s.color, s.trim
	if f == "feather" then
		plume(d, V(-0.26, -0.55, 0), 0.62, 1.23, 0.44, c:Lerp(soot, 0.59))
		d.box("Ligature de plume", -0.195, -0.415, 0, 0.16, 0.17, 0.14, t, M.Metal, -0.42)
	elseif f == "clover" then
		local green = rgb(100, 155, 77)
		for _, side in pair do
			d.part("Foliole", V(0.48, 0.58, 0.16), C(side * 0.195, 0.18, 0) * A(0, 0, -side * 0.57), green, M.Fabric, "ball")
		end
		d.ball("Foliole", 0, -0.18, 0, 0.49, 0.43, 0.16, green, M.Fabric)
		d.bar("Tige", V(-0.085, -0.02, 0), V(0.15, -0.53, 0), 0.103, 0.10, green:Lerp(dark, 0.38), M.Fabric)
	elseif f == "paw" then
		d.ball("Patte de lapin", 0, -0.22, 0, 0.54, 0.57, 0.29, c:Lerp(pale, 0.62), M.Fabric)
		for i = -1, 1 do d.ball("Doigt de patte", i * 0.16, -0.43, 0, 0.20, 0.25, 0.26, ivory, M.Fabric) end
		d.box("Virole", 0, 0.095, 0, 0.37, 0.24, 0.34, t, M.Metal)
		d.loop("Annelet", 0, 0.285, 0, 0.15, 0.14, 6, 0.073, t, M.Metal)
	elseif f == "heart" or f == "shard" then
		local gem = s.accent:Lerp(c, 0.22)
		local shard = f == "shard"
		local width = shard and 0.44 or 0.57 + s.variant * 0.052
		d.box("Matrice minérale", 0, -0.13, 0, width, 0.60, 0.57, s.metal, M.Slate, 0.26 + s.cut * 0.014)
		for i = -1, 1 do
			local reach = shard and 0.22 or 0.35 + s.profile * 0.018
			d.tip("Cristal fracturé", V(i * width * 0.27, -0.18, -0.15),
				V(i * reach + 0.08, (shard and 0.85 or 0.60 + s.cut * 0.015) - math.abs(i) * 0.18, -0.15),
				shard and 0.21 or 0.38, 0.27, gem:Lerp(pale, (i + 1) * 0.10), M.Glass)
		end
		if s.name:find("serti", 1, true) then
			d.box("Étrier de sertissage", 0, -0.24, -0.233, width * 1.36, 0.21, 0.25, t, M.Metal, 0.19)
		end
		if s.rarity >= 3 then setting(d, 0, -0.15, -0.31, 0.29, s) end
	elseif f == "vial" or f == "gourd" then
		local glass = f == "vial"
		local lum = s.name:find("lumineuse", 1, true)
		local width = glass and (lum and 0.48 or 0.73) or 0.88
		d.ball(glass and "Fiole" or "Gourde de cuir", 0, -0.16, 0, width, lum and 1.10 or 0.82, 0.49, glass and s.accent or c,
			glass and M.Glass or M.Leather)
		d.box("Col du flacon", 0, 0.27, 0, width * 0.44, 0.37, 0.33, t, glass and M.Glass or M.Leather)
		d.disc("Bouchon", 0, 0.52, 0, width * 0.51, 0.18, wood, M.Wood, true)
		if lum then
			d.tip("Pierre lumineuse en cage", V(0, -0.31, -0.24), V(0, 0.21, -0.24), width * 0.78, 0.09,
				s.accent:Lerp(pale, 0.57), M.Glass)
		else
			d.box(glass and "Étiquette d’antidote" or "Sangle de gourde", 0, -0.15, -0.245, width * 0.64, 0.31, 0.069, ivory, M.Fabric, 0.15)
		end
	elseif f == "lamp" then
		for _, side in pair do
			d.box("Cadre de lanterne", side * 0.36, -0.08, 0, 0.11, 0.92, 0.56, s.metal, M.Metal)
		end
		d.box("Fond de lanterne", 0, -0.52, 0, 0.82, 0.15, 0.63, t, M.Metal)
		d.box("Vitre de lanterne", 0, -0.12, 0, 0.60, 0.72, 0.49, rgb(223, 171, 65), M.Glass)
		d.box("Toit de lanterne", 0, 0.41, 0, 0.80, 0.19, 0.65, t, M.Metal)
		d.loop("Anse de lanterne", 0, 0.62, 0, 0.25, 0.19, 8, 0.073, s.metal, M.Metal)
	elseif f == "horn" or f == "whistle" then
		local small = f == "whistle"
		bentPoint(d, small and "Tube d’os" or "Cor recourbé", V(-0.43, -0.35, 0), 0.91, small and 0.65 or 0.77,
			small and 0.25 or 0.48, 0.31, ivory:Lerp(s.color, 0.21), M.SmoothPlastic)
		d.box("Virole", -0.33, -0.24, 0, small and 0.27 or 0.48, 0.26, 0.34, t, M.Metal, -0.55)
		d.box(small and "Fenêtre du sifflet" or "Bourrelet de pavillon", -0.40, -0.33, -0.13, 0.18, 0.17, 0.13,
			small and soot or t, M.Metal, -0.57)
	elseif f == "keyring" or f == "horseshoe" then
		local key = f == "keyring"
		local r = key and 0.35 or 0.47
		local y = key and 0.38 or 0
		local points = {}
		for i = 0, 8 do
			local a = (key and -math.pi or -0.10) + i * (key and turns or math.pi + 0.20) / 8
			points[i + 1] = V(math.cos(a) * r, y - math.sin(a) * 0.50, 0)
		end
		d.path(key and "Anneau de clés" or "Fer ouvert", points, key and 0.105 or 0.20, 0.19, s.metal, M.Metal)
		for i = -1, 1 do
			local x = i * r * 0.60
			if key then
				d.box("Tige de clé", x, -0.32, 0, 0.095, 0.75, 0.14, t, M.Metal, -i * 0.24)
				d.box("Panneton", i * (r * 0.60 + 0.05) + 0.055, -0.63 + math.abs(i) * 0.07, 0, 0.20, 0.15, 0.14, t, M.Metal)
			else
				d.disc("Étampe", x * 1.34, -0.47 + math.abs(i) * 0.11, -0.108, 0.11, 0.034, soot, M.Metal)
			end
		end
	elseif f == "net" or f == "veil" then
		local net = f == "net"
		d.box("Traverse", 0, 0.59, 0, 1.18, 0.19, 0.21, hide, M.Leather)
		for i = -2, 2 do
			local x = i * 0.21
			d.bar(net and "Maille du filet" or "Pli du voile", V(x, 0.57, 0), V(x * 1.43, -0.66 + math.abs(i) * 0.13, 0),
				net and 0.076 or 0.27, 0.12, net and t or c, M.Fabric)
		end
		for i = 0, 3 do
			d.box(net and "Maille nouée" or "Drap du voile", 0, 0.39 - i * 0.29, 0, 1.04 + i * 0.055, net and 0.074 or 0.30,
				0.092, net and t or c:Lerp(soot, i * 0.08), M.Fabric)
		end
	elseif f == "quiver" then
		local lunar = s.name:find("lune", 1, true)
		d.part("Fourreau de carquois", V(lunar and 0.72 or 0.56, 1.59, 0.47), C(0, -0.13, 0) * A(0, 0, -0.15), c, M.Leather)
		d.box("Gueule cerclée", 0.12, 0.62, 0, 0.72, 0.20, 0.53, t, M.Metal, -0.15)
		for i = -1, 1 do
			d.box("Fût de flèche", 0.145 + i * 0.18, 0.70, 0.03, 0.055, 0.71 - math.abs(i) * 0.12, 0.055, wood, M.Wood, -i * 0.09)
			d.box("Empennage", 0.145 + i * 0.21, 0.948 - math.abs(i) * 0.068, 0.03, 0.19, 0.22, 0.085, t, M.Fabric, -i * 0.15)
		end
		d.box("Bride de carquois", -0.05, -0.27, -0.22, 0.68, 0.16, 0.14, hide, M.Leather, -0.15)
		if lunar then
			d.path("Renfort du croissant", {V(-0.18, 0.41, -0.233), V(-0.26, 0.19, -0.233), V(-0.10, -0.025, -0.233),
				V(0.16, -0.011, -0.233)}, 0.089, 0.061, t, M.Metal)
		end
	elseif f == "belt" or f == "bridle" then
		d.loop("Bande de cuir", 0, 0, 0, 0.69, f == "belt" and 0.35 or 0.55, 10, 0.19, hide, M.Leather)
		d.box("Boucle d’attache", 0, -0.31, -0.05, 0.39, 0.25, 0.20, t, M.Metal)
		d.box("Mortaise", 0, -0.31, -0.158, 0.23, 0.12, 0.046, soot, M.Leather)
		d.box("Ardillon", 0.02, -0.31, -0.18, 0.23, 0.04, 0.031, t, M.Metal)
		if s.name:find("collets", 1, true) then
			d.loop("Collet attaché", 0.33, -0.47, -0.016, 0.19, 0.24, 7, 0.066, t, M.Fabric)
		elseif s.name:find("hachereau", 1, true) then
			d.path("Porte-outil de ceinture", {V(0.20, -0.31, 0), V(0.45, -0.39, 0), V(0.44, -0.67, 0),
				V(0.20, -0.67, 0), V(0.16, -0.34, 0)}, 0.105, 0.13, t, M.Metal)
		end
	elseif f == "basket" or f == "saddle" or f == "satchel" or f == "pouch" then
		local basket, saddle = f == "basket", f == "saddle"
		local width = basket and 1.04 or saddle and 1.21 or f == "pouch" and 0.70 or 0.97
		d.ball(basket and "Vannerie" or saddle and "Assise de selle" or "Sac de cuir", 0, -0.21, 0, width, 0.77, 0.64, c,
			basket and M.Wood or M.Leather)
		d.box(saddle and "Troussequin" or "Rabat", 0, 0.058, -0.23, width * 0.86, 0.30, 0.19, c:Lerp(pale, 0.18),
			basket and M.Wood or M.Leather)
		if saddle then
			local war = s.name:find("guerre", 1, true)
			d.ball("Pommeau de selle", 0, 0.16, -0.12, 0.44, war and 0.53 or 0.29, 0.35, t, M.Leather)
			for _, side in pair do
				d.box("Quartier de selle", side * 0.42, -0.35, 0.04, war and 0.34 or 0.25, 0.70, 0.38, c, M.Leather, side * 0.16)
				d.loop("Étrier", side * 0.42, -0.71, -0.02, war and 0.20 or 0.13, 0.18, 6, 0.065, t, M.Metal)
				if war then d.box("Ferrure du quartier", side * 0.44, -0.43, -0.14, 0.17, 0.32, 0.11, s.metal, M.Metal) end
			end
		else
			d.path("Anse", {V(-width * 0.38, 0, 0), V(-width * 0.29, 0.39, 0), V(0, 0.55, 0), V(width * 0.29, 0.39, 0),
				V(width * 0.38, 0, 0)}, 0.11, 0.12, t, basket and M.Wood or M.Leather)
			for _, side in pair do
				d.box(basket and "Tresse d’osier" or "Boucle de rabat", side * width * 0.26, -0.084, -0.309, 0.17, 0.22, 0.11,
					t, basket and M.Wood or M.Metal)
			end
		end
	else
		jewelry(d, s)
	end
end

local armorBuilders = {armor = torso, shoulders = shoulders, gloves = hands, legs = legs, boots = boots}
local shieldForms = {shield = true, roundshield = true, pavise = true, shellshield = true}
local weaponForms = {staff = true, hammer = true, sickle = true, dagger = true}

local function construct(s, emit, options)
	local slot, f = s.slot, s.form
	if armorBuilders[slot] then
		armorBuilders[slot](emit, s, options)
	elseif slot == "hat" then
		headdress(pen(emit, "head"), s)
	elseif slot == "cape" then
		cloak(pen(emit, "cape"), s)
	elseif shieldForms[f] then
		shields(pen(emit, slot == "offhand" and "shield" or "backBadge"), s)
	elseif f == "torch" then
		torch(pen(emit, "torch"), s)
	elseif slot == "weapon" or weaponForms[f] then
		local anchor = slot == "trinket" and "beltTool" or options.weaponJoint
		weapon(pen(emit, anchor), s)
	else
		accessory(pen(emit, options.jewelJoint), s)
	end
end

local weaponsBack = {bow = true, shortbow = true, longbow = true, crossbow = true, pike = true, longpike = true,
	staff = true, halberd = true, reaper = true, scythe = true, javelin = true, greatsword = true}
local pocketForms = {vial = true, gourd = true, lamp = true, horn = true, whistle = true, net = true, keyring = true,
	horseshoe = true, basket = true, saddle = true, satchel = true, pouch = true, veil = true, bridle = true}

local function joints(s, options)
	options.weaponJoint = weaponsBack[s.form] and "weaponBack" or "weaponHip"
	if s.form == "clawglove" then options.weaponJoint = "clawHand" end
	local f = s.form
	options.jewelJoint = pocketForms[f] and "beltTool" or "jewel"
	if f == "ring" or f == "signet" then options.jewelJoint = "finger" end
	if f == "bracelet" then options.jewelJoint = "wrist" end
	if f == "brooch" or f == "feather" or f == "clover" then options.jewelJoint = "pin" end
	if f == "quiver" then options.jewelJoint = "quiver" end
	if f == "belt" then options.jewelJoint = "belt" end
	return options
end

local function part(name, size, pose, color, material, kind)
	local piece = Instance.new(kind == "wedge" and "WedgePart" or "Part")
	piece.Name, piece.Size, piece.CFrame, piece.Color = name, size, pose, color
	piece.Material = material
	if kind == "ball" then piece.Shape = Enum.PartType.Ball end
	if kind == "cylinder" then piece.Shape = Enum.PartType.Cylinder end
	piece.TopSurface, piece.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	piece.CanCollide, piece.CanQuery, piece.CanTouch = false, false, false
	return piece
end

-- Les jonctions de la miniature sont composées dans la posture de référence.
local function previewFrame(joint, side, slot)
	if joint == "cape" then return A(0, math.pi, 0) end
	if joint == "waist" and slot == "armor" then return C(0, -0.87, 0) end
	if joint == "shoulder" and slot == "armor" then return C(side * 1.03, 0.07, 0) end
	if joint == "thigh" and slot == "armor" then return C(side * 0.42, -1.659, 0) end
	if slot == "legs" and (joint == "thigh" or joint == "shin") then
		return C(side * 0.42, joint == "thigh" and -0.789 or -1.87, 0)
	end
	if joint == "shin" and slot == "boots" then return C(0, 0.76, 0.09) end
	return C()
end

local function previewPair(s)
	return s.slot == "armor" or (s.slot == "legs" and (s.form == "pants" or s.form == "leggings"))
end

function Visuals.preview(item)
	local s = Design.appearance(item)
	local options = joints(s, {})
	local model = Instance.new("Model")
	model.Name = s.slot .. ":" .. item.name
	model:SetAttribute("FamilleVisuelle", s.form)
	if s.torsoFamily then model:SetAttribute("FamilleTorse", s.torsoFamily) end
	model:SetAttribute("EquipementCommun", true)
	model:SetAttribute("RangVisuel", s.rarity)
	model:SetAttribute("ApercuDroit", true)
	model:SetAttribute("ApercuArme", s.slot == "weapon" and not weaponsBack[s.form])
	local showPair = previewPair(s)
	construct(s, function(joint, side, name, size, pose, color, material, kind)
		if side == -1 and not showPair then return end
		local p = part(name, size, previewFrame(joint, side, s.slot) * pose, color, material, kind)
		p.Anchored, p.Parent = true, model
	end, options)
	return model
end

local jointNames = {
	head = "Head", chest = "UpperTorso", waist = "LowerTorso", shoulder = "UpperArm", palm = "Hand",
	forearm = "LowerArm", thigh = "UpperLeg", shin = "LowerLeg", foot = "Foot",
}
local anchors = {
	cape = {"UpperTorso", C(), 1}, shield = {"LeftLowerArm", C(-0.49, -0.11, -0.14) * A(0, math.rad(57), -0.18), 0.86},
	torch = {"LeftHand", C(0, 0.13, -0.25), 0.84}, clawHand = {"RightHand", C(0, 0.06, -0.24) * A(0, 0, math.pi), 0.67},
	weaponHip = {"LowerTorso", C(-0.91, -0.16, 0.25) * A(0, 0.13, math.pi - 0.32), 0.67},
	weaponBack = {"UpperTorso", C(0.06, 0.04, 0.69) * A(0, math.pi, -0.60), 0.69},
	beltTool = {"LowerTorso", C(0.78, -0.18, -0.18) * A(0, -0.35, -0.15), 0.45},
	backBadge = {"UpperTorso", C(-0.46, -0.20, 0.71) * A(0, math.pi, 0.19), 0.42},
	belt = {"LowerTorso", C(0, -0.11, -0.45), 0.60},
	finger = {"RightHand", C(0.15, -0.18, -0.24) * A(0, 0, -0.22), 0.23},
	wrist = {"RightHand", C(0, 0.17, 0) * A(-math.pi / 2, 0, 0), 0.51},
	pin = {"UpperTorso", C(0.51, 0.31, -0.61), 0.42}, jewel = {"UpperTorso", C(0, 0.20, -0.62), 0.45},
	quiver = {"UpperTorso", C(0.53, 0.11, 0.61) * A(0, math.pi, 0.22), 0.71},
}

local function bodyPart(char, name)
	local target = char:FindFirstChild(name)
	if not target and (name == "UpperTorso" or name == "LowerTorso") then target = char:FindFirstChild("Torso") end
	return target and target:IsA("BasePart") and target or nil
end

local function resize(pose, size, factor)
	return C(pose.Position * factor) * pose.Rotation, size * factor
end

function Visuals.wear(item, char, holder, options)
	local s = Design.appearance(item)
	options = joints(s, options or {})
	local count = 0
	construct(s, function(joint, side, name, size, pose, color, material, kind)
		local custom = anchors[joint]
		local limb = jointNames[joint]
		local body = bodyPart(char, custom and custom[1] or side and (side == -1 and "Left" or "Right") .. limb or limb)
		if not body then return end
		if custom then
			local standard = custom[1]:find("Torso", 1, true) and sizes[custom[1] == "LowerTorso" and "waist" or "chest"]
				or custom[1]:find("Hand", 1, true) and sizes.palm or sizes.forearm
			local scale = body.Size / standard
			local offset = C(custom[2].Position * scale) * custom[2].Rotation
			local factor = joint == "cape" and scale or V(1, 1, 1) * custom[3] * math.min(scale.X, scale.Y, scale.Z)
			pose, size = resize(pose, size, factor)
			pose = offset * pose
		else
			pose, size = resize(pose, size, body.Size / sizes[joint])
		end
		local p = part(name, size, body.CFrame * pose, color, material, kind)
		p.Massless = true
		p.Parent = holder
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = body, p, p
		if s.form == "torch" and name == "Étoupe" then
			local glow = Instance.new("PointLight")
			glow.Color, glow.Brightness, glow.Range = rgb(255, 174, 82), 1.3, 13
			glow.Parent = p
		end
		count += 1
	end, options)
	return count
end

return Visuals
