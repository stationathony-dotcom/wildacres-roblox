-- Concours de design du 26/11 : « Mammouth de givre », version Claude (voir tools/concours/SUJET.md).
-- Sol à y = 0, regarde vers −Z. Parts seulement, ≤ 320 pièces.
-- v2 : bosse ronde en gradins, manteau de givre en coulures irrégulières, pattes couvertes de mèches,
-- tête en dôme, cristaux trapus en grappes.

return function(parent: Instance, origin: CFrame): Model
	local V = Vector3.new
	local CF = CFrame.new
	local ANG = CFrame.Angles
	local rad = math.rad
	local Mat = Enum.Material
	local rng = Random.new(7)

	local FD = Color3.fromRGB(56, 36, 27) -- fourrure sombre
	local FM = Color3.fromRGB(94, 61, 43) -- fourrure moyenne
	local FL = Color3.fromRGB(134, 96, 70) -- fourrure claire
	local HOOF = Color3.fromRGB(40, 27, 20)
	local TUSK = Color3.fromRGB(238, 226, 198)
	local TUSK2 = Color3.fromRGB(208, 192, 160)
	local FROST = Color3.fromRGB(184, 212, 244)
	local FROST2 = Color3.fromRGB(146, 182, 228)
	local FROST3 = Color3.fromRGB(220, 236, 252)
	local ICE = Color3.fromRGB(140, 214, 250)
	local GLOW = Color3.fromRGB(96, 232, 255)
	local MOUTH = Color3.fromRGB(86, 34, 34)

	local m = Instance.new("Model")
	m.Name = "Mammouth_claude"
	local n = 0

	local function P(size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, shape: string?): BasePart
		local p: BasePart
		if shape == "wedge" then
			p = Instance.new("WedgePart")
		else
			local q = Instance.new("Part")
			if shape == "cyl" then
				q.Shape = Enum.PartType.Cylinder
			end
			p = q
		end
		p.Size = V(math.max(size.X, 0.05), math.max(size.Y, 0.05), math.max(size.Z, 0.05))
		p.CFrame = origin * cf
		p.Color = color
		p.Material = mat or Mat.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
		n += 1
		return p
	end

	local function along(a: Vector3, b: Vector3): CFrame
		local up = math.abs((b - a).Unit.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
		return CFrame.lookAt((a + b) / 2, b, up)
	end

	local function furTone(): Color3
		local r = rng:NextNumber()
		if r < 0.3 then
			return FD
		elseif r < 0.75 then
			return FM
		end
		return FL
	end

	local function frostTone(): Color3
		local r = rng:NextNumber()
		if r < 0.4 then
			return FROST
		elseif r < 0.7 then
			return FROST2
		end
		return FROST3
	end

	-- rangée de blocs jointifs de largeurs variables le long d'une face (bord « déchiqueté »)
	-- face = "x" : face latérale à x = fixed, on avance en z ; face = "z" : face avant/arrière, on avance en x
	local function fringe(face: string, fixed: number, from: number, to: number, top: number, hMin: number, hMax: number, wMin: number, wMax: number, depth: number, tone: () -> Color3)
		local pos = from
		while pos < to - 0.3 do
			local w = math.min(rng:NextNumber(wMin, wMax), to - pos)
			local h = rng:NextNumber(hMin, hMax)
			local c = pos + w / 2
			if face == "x" then
				P(V(depth, h, w + 0.05), CF(fixed, top - h / 2, c), tone())
			else
				P(V(w + 0.05, h, depth), CF(c, top - h / 2, fixed), tone())
			end
			pos += w
		end
	end

	-- cristal : prisme tourné à 45° + pointe lumineuse
	local function crystal(base: Vector3, h: number, w: number, tilt: CFrame)
		local cf = CF(base) * tilt * ANG(0, rad(45), 0)
		P(V(w, h, w), cf * CF(0, h / 2, 0), ICE)
		P(V(w * 0.6, h * 0.32, w * 0.6), cf * CF(0, h + h * 0.08, 0), GLOW, Mat.Neon)
	end

	-- Base (invisible, au sol)
	local base = P(V(2, 0.2, 2), CF(0, 0.1, 0), FD)
	base.Name = "Base"
	base.Transparency = 1

	-- ===== Pattes : seuls les pieds et les ongles dépassent des mèches =====
	for _, lp in { V(-3.2, 0, -3.4), V(3.2, 0, -3.4), V(-3.2, 0, 6.4), V(3.2, 0, 6.4) } do
		local sx = lp.X > 0 and 1 or -1
		P(V(3.4, 5.6, 3.4), CF(lp.X, 3.4, lp.Z), FD)
		P(V(3.9, 1.1, 3.9), CF(lp.X, 0.55, lp.Z), HOOF)
		for _, dx in { -1.1, 0, 1.1 } do
			P(V(0.95, 0.8, 0.5), CF(lp.X + dx, 0.45, lp.Z - 2.0), TUSK)
		end
		local h = rng:NextNumber(2.0, 2.6)
		P(V(3.0, h, 0.5), CF(lp.X, 4.2 - h / 2, lp.Z - 1.85), furTone())
		P(V(0.5, h, 3.0), CF(lp.X + sx * 1.85, 4.0 - h / 2, lp.Z), furTone())
		P(V(3.0, h, 0.5), CF(lp.X, 4.1 - h / 2, lp.Z + 1.85), furTone())
		P(V(0.4, 0.9, 1.6), CF(lp.X + sx * 2.1, 1.8, lp.Z - 0.6), FROST)
	end

	-- ===== Corps et bosse ronde en gradins =====
	P(V(10, 7.5, 15), CF(0, 9.75, 1.5), FM)
	P(V(10, 2.5, 13), CF(0, 14.5, 0), FD)
	P(V(8.4, 2.0, 10.5), CF(0, 16.6, -0.8), FROST2)
	P(V(6.4, 1.4, 7.5), CF(0, 18.2, -1.5), FROST)

	-- calottes de givre sur chaque gradin
	P(V(6.8, 0.5, 7.9), CF(0, 19.0, -1.5), FROST3)
	P(V(8.8, 0.5, 10.9), CF(0, 17.65, -0.8), FROST)
	P(V(10.4, 0.5, 13.4), CF(0, 15.8, 0), FROST)
	-- coulures : flancs des gradins puis haut des flancs du corps
	for _, sx in { -1, 1 } do
		fringe("x", sx * 4.45, -6.0, 4.4, 17.6, 0.6, 1.8, 0.8, 1.8, 0.5, frostTone)
		fringe("x", sx * 5.45, -6.5, 6.5, 15.8, 1.2, 4.2, 0.8, 2.2, 0.5, frostTone)
	end
	fringe("z", 6.75, -5.0, 5.0, 15.8, 0.8, 2.6, 0.9, 2.0, 0.5, frostTone)
	fringe("z", -6.75, -5.0, 5.0, 15.8, 0.8, 1.8, 0.9, 2.0, 0.5, frostTone)
	-- plots (aspect « brique »)
	for _, sp in { V(-2.0, 19.37, -4.2), V(2.0, 19.37, -4.2), V(-2.2, 19.37, -1.0), V(2.2, 19.37, -0.6), V(-1.9, 19.37, 1.6), V(2.0, 19.37, 1.8),
		V(-3.6, 18.02, -5.4), V(3.6, 18.02, -5.2), V(-3.7, 18.02, 1.0), V(3.7, 18.02, 1.4), V(-1.5, 18.02, 3.7), V(1.6, 18.02, 3.8) } do
		P(V(0.25, 0.9, 0.9), CF(sp) * ANG(0, 0, rad(90)), FROST2, nil, "cyl")
	end

	-- fourrure en mèches sur les flancs : 4 rangées décalées, la dernière pend jusqu'aux genoux
	for _, sx in { -1, 1 } do
		for r, top in { 13.2, 10.8, 8.4, 6.0 } do
			local start = -6.0 + (r % 2) * 0.6
			fringe("x", sx * 5.15, start, 9.0, top, 2.6, 3.5, 1.2, 1.9, 0.6, furTone)
		end
	end
	-- arrière
	for _, top in { 13.0, 10.4, 7.8 } do
		fringe("z", 9.15, -4.8, 4.8, top, 2.5, 3.3, 1.2, 1.9, 0.6, furTone)
	end

	-- cristaux du dos : grappes trapues sur la crête + épaules
	local spine = {
		{ z = -4.0, y = 19.2, h = 2.4 }, { z = -1.5, y = 19.2, h = 2.7 }, { z = 1.0, y = 19.2, h = 2.5 },
		{ z = 3.4, y = 17.9, h = 2.4 }, { z = 5.4, y = 16.0, h = 2.0 },
	}
	for _, s in spine do
		crystal(V(rng:NextNumber(-0.3, 0.3), s.y - 0.3, s.z), s.h, 2.1, ANG(rad(rng:NextNumber(-10, 10)), 0, rad(rng:NextNumber(-8, 8))))
		local side = rng:NextNumber() < 0.5 and -1 or 1
		crystal(V(side * 1.2, s.y - 0.3, s.z + 0.5), s.h * 0.7, 1.4, ANG(0, 0, rad(-side * 26)))
	end
	for _, sp in { V(-3.7, 17.6, -3.0), V(3.7, 17.6, -2.6), V(-3.8, 17.6, 1.8), V(3.8, 17.6, 2.2) } do
		local sx = sp.X > 0 and 1 or -1
		crystal(sp, 1.9, 1.5, ANG(0, 0, rad(-sx * 30)))
	end

	-- ===== Tête en dôme =====
	P(V(7.0, 6.4, 5.0), CF(0, 12.6, -8.6), FM)
	P(V(6.0, 2.4, 4.4), CF(0, 16.8, -8.4), FM)
	P(V(6.4, 0.5, 4.8), CF(0, 18.25, -8.4), FROST3)
	fringe("z", -10.85, -2.8, 2.8, 18.1, 0.5, 1.6, 0.7, 1.4, 0.4, frostTone)
	-- arête de trompe sur le front + anneaux
	P(V(2.6, 4.4, 0.8), CF(0, 12.2, -11.45), FD)
	for _, y in { 10.8, 12.0, 13.2 } do
		P(V(2.9, 0.3, 0.9), CF(0, y, -11.55), FL)
	end
	-- yeux lumineux, orbites, sourcils froncés, oreilles, joues, barbe
	for _, sx in { -1, 1 } do
		local tilt = ANG(0, 0, rad(sx * 14))
		P(V(1.7, 1.0, 0.2), CF(sx * 2.0, 13.9, -11.15) * tilt, HOOF)
		P(V(1.2, 0.5, 0.2), CF(sx * 2.0, 13.9, -11.28) * tilt, GLOW, Mat.Neon)
		P(V(2.3, 0.7, 1.0), CF(sx * 1.9, 14.65, -11.35) * tilt, FD)
		P(V(0.6, 2.8, 2.4), CF(sx * 3.9, 13.4, -7.0) * ANG(0, rad(sx * 12), 0), FD)
		for _, z in { -10.4, -8.8, -7.2 } do
			local h = rng:NextNumber(2.8, 4.0)
			P(V(0.55, h, 1.6), CF(sx * 3.75, 15.0 - h / 2, z), furTone())
		end
		for _, dx in { 2.0, 3.0 } do
			local h = rng:NextNumber(2.2, 3.0)
			P(V(1.0, h, 0.5), CF(sx * dx, 12.0 - h / 2, -11.25), furTone())
		end
	end
	P(V(2.2, 0.6, 1.2), CF(0, 9.8, -11.2), MOUTH)

	-- ===== Trompe =====
	local tp = { V(0, 11.2, -11.6), V(0, 9.2, -12.0), V(0, 7.2, -12.2), V(0, 5.2, -12.4), V(0, 3.6, -12.9), V(0, 2.5, -13.9), V(0, 2.4, -15.1), V(0, 3.4, -15.8) }
	local tw = { 2.6, 2.4, 2.2, 1.9, 1.7, 1.5, 1.3 }
	for i = 1, #tp - 1 do
		local a, b = tp[i], tp[i + 1]
		local w = tw[i]
		P(V(w, w * 0.92, (b - a).Magnitude + w * 0.3), along(a, b), i % 2 == 0 and FD or FM)
		P(V(w + 0.22, w * 0.92 + 0.22, 0.3), CFrame.lookAt(a, b, Vector3.yAxis), FL)
	end

	-- ===== Défenses courbes, bout givré =====
	for _, sx in { -1, 1 } do
		local pts = { V(2.4, 10.0, -10.8), V(3.1, 8.5, -12.1), V(3.6, 7.5, -13.7), V(3.8, 7.3, -15.4), V(3.5, 8.1, -16.9), V(2.9, 9.5, -17.8), V(2.2, 11.2, -18.1) }
		local ws = { 1.6, 1.5, 1.4, 1.25, 1.1, 0.9 }
		P(V(2.0, 2.0, 1.0), CF(sx * 2.4, 10.1, -11.2), FD)
		for i = 1, #pts - 1 do
			local a = V(sx * pts[i].X, pts[i].Y, pts[i].Z)
			local b = V(sx * pts[i + 1].X, pts[i + 1].Y, pts[i + 1].Z)
			local w = ws[i]
			local cf = along(a, b)
			P(V(w, w, (b - a).Magnitude + w * 0.35), cf, i % 2 == 0 and TUSK2 or TUSK)
			if i >= 5 then
				P(V(0.7, 1.4, 0.7), cf * CF(sx * (w / 2 + 0.15), 0.2, 0) * ANG(0, 0, rad(-sx * 35)), ICE, Mat.Ice)
				P(V(0.6, 1.1, 0.6), cf * CF(0, w / 2 + 0.3, 0.2) * ANG(rad(20), 0, 0), ICE, Mat.Ice)
			end
		end
		local tip = V(sx * 2.2, 11.2, -18.1)
		P(V(0.55, 0.9, 0.55), CF(tip + V(0, 0.4, 0)) * ANG(0, rad(45), 0), GLOW, Mat.Neon)
	end

	-- ===== Queue =====
	P(V(0.8, 0.8, 2.2), along(V(0, 12.4, 9.2), V(0, 10.6, 10.2)), FM)
	P(V(0.7, 0.7, 1.8), along(V(0, 10.6, 10.2), V(0, 9.2, 10.6)), FM)
	P(V(1.2, 1.6, 1.0), CF(0, 8.6, 10.7), FD)

	-- ===== Glace au sol =====
	for _, g in { V(-6.5, 0, -6), V(6.8, 0, -1.5), V(-6.2, 0, 9.5), V(5.5, 0, 10.5) } do
		crystal(g, rng:NextNumber(1.2, 2.0), 0.9, ANG(rad(rng:NextNumber(-20, 20)), 0, rad(rng:NextNumber(-20, 20))))
	end

	m.PrimaryPart = base
	m:SetAttribute("Pieces", n)
	m.Parent = parent
	return m
end
