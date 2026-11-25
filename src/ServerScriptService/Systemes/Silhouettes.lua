-- Silhouettes des créatures du bestiaire (chantier A, 25/11, docs/DIRECTION-ARTISTIQUE.md).
-- Sculpture « voxel » par code : blocs à gradins, membres, griffes, dents, yeux qui brillent, cristaux,
-- ailes à plumes ou à membrane. Chaque créature garde sa forme de base (KINDS.form) mais reçoit une
-- silhouette propre (variantes par espèce) et le décor de sa FAMILLE, tirée du biome où elle vit
-- (glace : givre et cristaux ; forêt : mousse et fleurs ; marais : vase ; désert : or ; grottes : améthyste).
-- Palette : couleurs de la créature (look) + une sombre dérivée + os + 1 couleur de famille + 1 lueur.
--
-- Repère : le sol est à y = 0, la créature regarde vers −Z (comme les anciennes formes).
-- Les pièces sont posées ancrées ; Bestiaire.build les soude ensuite sur la pièce « Base ».

local Silhouettes = {}

local Mat = Enum.Material
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad

local BONE = Color3.fromRGB(236, 226, 200)
local BLACK = Color3.new(0, 0, 0)
local METAL = Color3.fromRGB(150, 150, 158)
local WOOD = Color3.fromRGB(92, 64, 42)

-- Familles : accent = couleur de décor (givre, mousse, or…), glow = lueur des yeux et des cristaux
local FAM = {
	neige = { accent = Color3.fromRGB(170, 222, 255), glow = Color3.fromRGB(96, 226, 255), deco = "cristal" },
	desert = { accent = Color3.fromRGB(232, 184, 72), glow = Color3.fromRGB(255, 196, 70), deco = "or" },
	foret = { accent = Color3.fromRGB(98, 152, 62), glow = Color3.fromRGB(186, 255, 96), deco = "mousse" },
	marais = { accent = Color3.fromRGB(112, 132, 52), glow = Color3.fromRGB(150, 255, 70), deco = "vase" },
	grotte = { accent = Color3.fromRGB(168, 120, 232), glow = Color3.fromRGB(196, 128, 255), deco = "amethyste" },
	prairie = { glow = Color3.fromRGB(255, 128, 56) },
	nuit = { accent = Color3.fromRGB(150, 210, 255), glow = Color3.fromRGB(140, 226, 255), deco = "spectre" },
}
Silhouettes.FAM = FAM

-- Options de silhouette propres à une espèce (les données de KINDS ne sont pas touchées)
local SP = {
	ancient_turtle = { carapace = true },
	drakeling = { cornes = true, ailes = true, epines = 5 },
	sand_basilisk = { collerette = true, epines = 6 },
	colossal_boar = { epines = 7 },
	frost_boar = { epines = 5 },
	swamp_boar = { epines = 5 },
	vargor = { epines = 6, cicatrice = true },
	kelpie = { algues = true },
	hyena = { epines = 4 },
	cave_bear = { epines = 3 },
	night_howler = { epines = 4 },
	cyclops = { oeil = true },
	ogre = { epaulieres = "fourrure" },
	minotaur = { epaulieres = "fer" },
	mountain_giant = { epaulieres = "roc" },
	mountain_troll = { epaulieres = "roc" },
	cave_troll = { epaulieres = "roc" },
	ice_giant = { epaulieres = "glace" },
	frost_troll = { epaulieres = "glace" },
	forest_giant = { epaulieres = "mousse" },
	root_troll = { epaulieres = "mousse" },
	mummy = { bandelettes = true },
	corrupted_ent = { couronne_arbre = true },
	bramble_mother = { couronne_arbre = true },
	storm_wraith = { eclairs = true },
	deep_beast = { nageoires = true, taches = true },
	monster_eel = { nageoires = true, taches = true },
	sea_serpent = { nageoires = true },
	river_serpent = { nageoires = true },
	sand_worm = { gueule = true },
	-- humanoïdes : un attribut de métier qui se voit de loin
	bandit = { acc = { "masque" } },
	highwayman = { acc = { "chapeau", "masque" } },
	ruin_looter = { acc = { "sac", "lanterne" } },
	smuggler = { acc = { "sac", "bandouliere" } },
	desert_raider = { acc = { "turban" } },
	mercenary = { acc = { "bouclier" } },
	corrupt_guard = { acc = { "tabard" } },
	renegade_guard = { acc = { "bouclier", "tabard" } },
	deserter = { acc = { "cape_dechiree" } },
	poacher = { acc = { "carquois", "sac" } },
	bounty_hunter = { acc = { "carquois", "bandouliere", "chapeau" } },
	moon_hunter = { acc = { "carquois" } },
	night_stalker = { acc = { "carquois", "masque" } },
	goblin_archer = { acc = { "carquois" } },
	forgotten_knight = { acc = { "cape_dechiree", "bouclier" } },
	cursed_warden = { acc = { "runes" } },
	fallen_monk = { acc = { "lanterne" } },
	marauder = { acc = { "bandouliere" } },
	-- spectres : un trait chacun
	blizzard_spectre = { trait = "givre" },
	drowned_spirit = { trait = "algues" },
	dune_spectre = { trait = "voiles" },
	faceless_walker = { trait = "sansvisage" },
	hostile_siren = { trait = "chevelure" },
	possessed_shade = { trait = "chaines" },
	revenant = { trait = "lanterne" },
	ruin_spirit = { trait = "masque" },
	tree_spirit = { trait = "ramure" },
	wandering_spectre = { trait = "lanterne", voute = true, baton = true },
	bramble_fairy = { fee = true },
	polar_wolf = { fourrure = true },
	granite_warden = { pics = true },
	water_spirit = { trait = "gouttes" },
	woods_spirit = { trait = "ramure", feuilles = true },
	-- paires qui se ressemblaient
	hippogriff = { cheval = true },
	cave_bat = { taille = 0.8 },
	ghost_crow = { fantome = true },
	stray_dog = { collier = true },
	cave_spider = { taille = 1.12 },
	reed_spider = { taille = 0.9 },
	lake_guardian = { cristaux = true },
	earth_colossus = { rochers = true },
	mud_golem = { coulures = true },
	ruin_guardian = { glyphes = true },
	wood_golem = { branches = true },
	light_eater = { gouffre = true },
}
Silhouettes.SP = SP

-- ------------------------------------------------------------------ Outils de sculpture

local function newCtx(m: Model, id: string)
	local h = 0
	for i = 1, #id do
		h = (h * 31 + string.byte(id, i)) % 2147483647
	end
	return { m = m, n = 0, rng = Random.new(h) }
end

local function part(c, size: Vector3, cf: CFrame, color: Color3, mat, kind: string?)
	local p
	if kind == "wedge" then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
		if kind == "ball" then
			p.Shape = Enum.PartType.Ball
		elseif kind == "cyl" then
			p.Shape = Enum.PartType.Cylinder
		end
	end
	p.Size = V(math.max(size.X, 0.05), math.max(size.Y, 0.05), math.max(size.Z, 0.05))
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Mat.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = size.X * size.Y * size.Z > 0.5
	p.Parent = c.m
	c.n += 1
	return p
end

-- repère au milieu de a→b, qui regarde vers b (sans dégénérer à la verticale)
local function along(a: Vector3, b: Vector3): CFrame
	local d = b - a
	if d.Magnitude < 1e-3 then
		return CF((a + b) / 2)
	end
	local up = math.abs(d.Unit.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
	return CFrame.lookAt((a + b) / 2, b, up)
end

-- bloc « voxel » : un cube et deux gradins plus étroits dessus et dessous (arrondi en marches)
local function chunk(c, size: Vector3, cf: CFrame, color: Color3, mat, cap: Color3?, under: Color3?)
	local main = part(c, V(size.X, size.Y * 0.62, size.Z), cf, color, mat)
	part(c, V(size.X * 0.8, size.Y * 0.2, size.Z * 0.82), cf * CF(0, size.Y * 0.41, 0), cap or color, mat)
	part(c, V(size.X * 0.82, size.Y * 0.2, size.Z * 0.8), cf * CF(0, -size.Y * 0.41, 0), under or color, mat)
	return main
end

local function limb(c, a: Vector3, b: Vector3, w: number, d: number?, color: Color3, mat)
	local len = (b - a).Magnitude
	return part(c, V(w, d or w, len + math.min(w, d or w) * 0.35), along(a, b), color, mat)
end

-- chaîne de segments (queues, cous, corps de serpent) ; under = bande du ventre
local function chain(c, pts, widths, colors, mat, under: Color3?)
	local first
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local w = widths[i] or widths[#widths]
		local cf = along(a, b)
		local len = (b - a).Magnitude + w * 0.3
		local seg = part(c, V(w, w * 0.86, len), cf, colors[(i - 1) % #colors + 1], mat)
		first = first or seg
		if under then
			part(c, V(w * 0.72, w * 0.16, len * 0.9), cf * CF(0, -w * 0.4, 0), under, mat)
		end
	end
	return first
end

local function eyes(c, cf: CFrame, dx: number, size: number, glow: Color3, brow: Color3?)
	for _, sx in { -1, 1 } do
		part(c, V(size, size * 0.8, 0.1), cf * CF(sx * dx, 0, 0), glow, Mat.Neon)
		if brow then
			part(c, V(size * 1.5, size * 0.36, 0.18), cf * CF(sx * dx, size * 0.56, -0.03) * ANG(0, 0, rad(sx * 16)), brow, Mat.SmoothPlastic)
		end
	end
end

-- rangée de dents carrées qui pendent sous cf (largeur totale w)
local function teeth(c, cf: CFrame, w: number, n: number, len: number, color: Color3?)
	for i = 1, n do
		local x = (i - (n + 1) / 2) * w / n
		part(c, V(w / n * 0.5, len, w / n * 0.5), cf * CF(x, -len / 2, 0), color or BONE)
	end
end

local function claws(c, foot: Vector3, n: number, s: number, color: Color3?)
	for i = 1, n do
		local x = (i - (n + 1) / 2) * 0.24 * s
		part(c, V(0.13 * s, 0.13 * s, 0.34 * s), CF(foot + V(x, 0.06 * s, -0.36 * s)) * ANG(rad(-28), 0, 0), color or BONE)
	end
end

-- cristal : prisme tourné de 45°, pointe, cœur lumineux
local function crystal(c, base: Vector3, h: number, w: number, tilt: CFrame, color: Color3, glow: Color3?)
	local cf = CF(base) * tilt * CF(0, h / 2, 0) * ANG(0, rad(45), 0)
	local p = part(c, V(w, h, w), cf, color, Mat.Glass)
	p.Transparency = 0.2
	local tip = part(c, V(w * 0.55, h * 0.4, w * 0.55), cf * CF(0, h * 0.68, 0), color, Mat.Glass)
	tip.Transparency = 0.2
	if glow then
		local g = part(c, V(w * 0.34, h * 0.75, w * 0.34), cf, glow, Mat.Neon)
		g.Transparency = 0.15
	end
end

-- aile à plumes : rangées de lames, les plus longues dehors et derrière (rémiges)
local function featherWing(c, root: CFrame, side: number, span: number, chord: number, cols, rows: number?)
	rows = rows or 3
	for r = 1, rows do
		local n = 2 + r
		local reach = span * (0.6 + 0.4 * r / rows)
		for i = 1, n do
			local t = (i - 0.5) / n
			local len = reach / n * 1.3
			local depth = chord * (0.5 + 0.25 * r / rows) * (1 + t * 0.4)
			local x = side * (0.25 + t * reach)
			local z = (r - 1) * chord * 0.3 + t * chord * 0.12
			part(c, V(len, 0.24, depth), root * CF(x, -(r - 1) * 0.09 - t * 0.12, z) * ANG(rad(-6 * r), 0, 0), cols[(r - 1) % #cols + 1], Mat.SmoothPlastic)
		end
	end
end

-- aile à membrane : bras, coude, trois doigts, panneaux de peau entre les doigts
local function membraneWing(c, root: CFrame, side: number, span: number, chord: number, bone: Color3, skin: Color3, mat, w: number)
	local elbow = (root * CF(side * span * 0.42, span * 0.2, -chord * 0.1)).Position
	local tips = {
		(root * CF(side * span, span * 0.28, -chord * 0.25)).Position,
		(root * CF(side * span * 0.86, -span * 0.02, chord * 0.45)).Position,
		(root * CF(side * span * 0.55, -span * 0.12, chord * 0.95)).Position,
	}
	local body = (root * CF(side * 0.15, -0.1, chord * 0.9)).Position
	limb(c, root.Position, elbow, w, nil, bone, mat)
	for _, tp in tips do
		limb(c, elbow, tp, w * 0.55, nil, bone, mat)
	end
	for i = 1, #tips do
		local a = tips[i]
		local b = tips[i + 1] or body
		local mid = (a + b) / 2
		local look = (mid - elbow)
		local len = look.Magnitude
		look = look.Unit
		local right = (a - b)
		right = (right - look * right:Dot(look))
		if right.Magnitude < 1e-3 then
			continue
		end
		right = right.Unit
		local back = -look
		local up = back:Cross(right)
		local pos = (elbow + mid) / 2
		local membrane = part(c, V((a - b).Magnitude * 0.95, 0.08, len * 1.02), CFrame.fromMatrix(pos, right, up, back), skin, mat)
		membrane.CastShadow = true
	end
end

-- ------------------------------------------------------------------ Décor de famille

-- le long de la colonne vertébrale (a → b), n éléments, w = largeur du dos
local function backDeco(c, f, a: Vector3, b: Vector3, w: number, s: number, n: number)
	if not f.deco then
		return
	end
	for i = 1, n do
		local t = (i - 0.5) / n
		local p = a:Lerp(b, t)
		local side = (i % 2 == 0) and 1 or -1
		if f.deco == "cristal" or f.deco == "amethyste" then
			local h = (0.8 + 0.45 * math.abs(math.sin(i * 2.3))) * s
			crystal(c, p, h, 0.34 * s, ANG(rad(c.rng:NextNumber(-18, 12)), 0, rad(side * c.rng:NextNumber(8, 24))), f.accent, f.glow)
		elseif f.deco == "mousse" then
			part(c, V(w * 0.7, 0.22 * s, (b - a).Magnitude / n * 0.9), CF(p + V(0, 0.08 * s, 0)), f.accent, Mat.Grass)
			if i % 2 == 1 then
				part(c, V(0.5 * s, 0.12 * s, 0.32 * s), CF(p + V(side * w * 0.3, 0.3 * s, 0)) * ANG(0, rad(30 * side), rad(side * 25)), f.accent, Mat.Grass)
			end
			if i == math.ceil(n / 2) then
				part(c, V(0.3 * s, 0.24 * s, 0.3 * s), CF(p + V(-side * w * 0.2, 0.3 * s, 0)), f.glow, Mat.Neon)
			end
		elseif f.deco == "vase" then
			part(c, V(w * 0.74, 0.2 * s, (b - a).Magnitude / n * 0.95), CF(p + V(0, 0.06 * s, 0)), f.accent, Mat.Mud)
			local len = (0.5 + 0.4 * math.abs(math.sin(i * 1.7))) * s
			part(c, V(0.18 * s, len, 0.18 * s), CF(p + V(side * w * 0.48, -len / 2, 0)), f.accent, Mat.Mud)
		elseif f.deco == "or" then
			local plate = part(c, V(w * 0.36, 0.2 * s, 0.4 * s), CF(p + V(0, 0.1 * s, 0)) * ANG(0, rad(45), 0), f.accent, Mat.Metal)
			plate.Reflectance = 0.1
		end
	end
end

-- épines de dos (crête) : cales sombres, plus hautes au milieu
local function spines(c, a: Vector3, b: Vector3, n: number, h: number, color: Color3, mat)
	for i = 1, n do
		local t = (i - 0.5) / n
		local hh = h * (0.6 + 0.4 * math.sin(t * math.pi))
		part(c, V(h * 0.22, hh, h * 0.5), CF(a:Lerp(b, t) + V(0, hh / 2, 0)), color, mat, "wedge")
	end
end

local function darken(col: Color3, k: number): Color3
	return col:Lerp(BLACK, k)
end

-- ------------------------------------------------------------------ Formes

local F = {}

-- Quadrupèdes : loups, ours, sangliers, lézards, cerfs, tortue, dragonnet, Vargor…
function F.quadrupede(c, o, f, k, sp, C)
	local s = (o.scale or 1) * (o.petit and 0.75 or 1) * (o.gros and 1.35 or 1)
	local col, col2 = C[o[1]] or C.B, C[o[2]] or C.BF
	local dark = darken(col, 0.4)
	local mat = o.spectre and Mat.Neon or Mat.SmoothPlastic
	local cap = (f.deco == "cristal" or f.deco == "mousse" or f.deco == "vase") and f.accent or col
	local plat, bulk = o.plat, o.gros and 1.15 or 1
	local predator = (k.dmg or 0) >= 16 and not o.bois
	local legH = (plat and 0.75 or 1.4) * s
	local L = (plat and 3.7 or 3.4) * s
	local W = 1.5 * s * bulk
	local H = (plat and 1.0 or 1.45) * s
	local by = legH + H / 2
	-- poitrail (haut et large) puis arrière-train
	local chest = chunk(c, V(W * 1.08, H * 1.12, L * 0.56), CF(0, by + H * 0.06, -L * 0.2), col, mat, cap, col2)
	chunk(c, V(W * 0.94, H * 0.96, L * 0.52), CF(0, by, L * 0.24), col, mat, cap, col2)
	-- pattes : cuisse, jambe, pied ; écartées pour les lézards
	for _, sz in { -1, 1 } do
		for _, sx in { -1, 1 } do
			local hip = V(sx * (W * 0.5 - 0.2 * s), by - H * 0.18, sz < 0 and -L * 0.33 or L * 0.34)
			local knee, foot
			if plat then
				knee = hip + V(sx * 0.6 * s, -legH * 0.25, 0)
				foot = V(hip.X + sx * 0.75 * s, 0.16 * s, hip.Z - 0.1 * s)
			else
				knee = hip + V(0, -legH * 0.55, (sz < 0 and 0.14 or -0.2) * s)
				foot = V(hip.X, 0.16 * s, hip.Z - 0.04 * s)
			end
			limb(c, hip, knee, 0.58 * s * bulk, nil, col, mat)
			limb(c, knee, foot, 0.44 * s * bulk, nil, col, mat)
			part(c, V(0.6 * s * bulk, 0.3 * s, 0.72 * s), CF(foot.X, 0.15 * s, foot.Z - 0.08 * s), dark, mat)
			if predator and sz < 0 then
				claws(c, V(foot.X, 0, foot.Z - 0.1 * s), 2, s)
			end
		end
	end
	-- carapace (tortue) : dôme à gradins, plaques
	if sp.carapace then
		local shellDark = darken(col2, 0.3)
		chunk(c, V(W * 1.5, H * 1.25, L * 1.12), CF(0, by + H * 0.55, 0), col2, Mat.Slate, f.accent or col2, shellDark)
		for i = -1, 1 do
			part(c, V(W * 0.42, 0.22 * s, L * 0.28), CF(i * W * 0.42, by + H * 1.2, i * 0.2 * s) * ANG(0, rad(45), 0), shellDark, Mat.Slate)
		end
	end
	-- cou et tête (plafonnée : une « grosse tête » de données ne doit pas dépasser le poitrail)
	local ts = math.min(o.tete or 1, 1.35) * s
	local headCap = f.deco == "cristal" and f.accent or col
	local neckA = V(0, by + H * 0.3, -L * 0.42)
	local hc = V(0, by + H * 0.55 + (plat and -0.35 * s or 0.25 * s), -L * 0.5 - 0.75 * ts)
	limb(c, neckA, hc + V(0, -0.1 * ts, 0.35 * ts), 0.78 * ts, 0.85 * ts, col, mat)
	local head = CF(hc)
	chunk(c, V(1.15 * ts, 1.0 * ts, 1.1 * ts), head, col, mat, headCap)
	part(c, V(0.74 * ts, 0.5 * ts, 0.78 * ts), head * CF(0, -0.18 * ts, -0.84 * ts), col2, mat)
	part(c, V(0.32 * ts, 0.2 * ts, 0.12 * ts), head * CF(0, -0.02 * ts, -1.24 * ts), dark, mat)
	part(c, V(0.64 * ts, 0.18 * ts, 0.66 * ts), head * CF(0, -0.52 * ts, -0.72 * ts) * ANG(rad(predator and 12 or 4), 0, 0), dark, mat)
	if predator then
		teeth(c, head * CF(0, -0.4 * ts, -1.05 * ts), 0.56 * ts, 4, 0.18 * ts)
	end
	eyes(c, head * CF(0, 0.14 * ts, -0.57 * ts), 0.3 * ts, 0.2 * ts, f.glow, predator and dark or nil)
	if o.oreilles and sp.collier then
		for _, sx in { -1, 1 } do
			part(c, V(0.2 * ts, 0.55 * ts, 0.4 * ts), head * CF(sx * 0.62 * ts, 0.1 * ts, 0.1 * ts) * ANG(0, 0, rad(sx * 15)), col2, mat)
		end
		part(c, V(0.95 * ts, 0.18 * ts, 0.95 * ts), CF(neckA:Lerp(hc, 0.55)), BONE, Mat.Fabric)
	elseif o.oreilles then
		for _, sx in { -1, 1 } do
			part(c, V(0.3 * ts, 0.52 * ts, 0.3 * ts), head * CF(sx * 0.36 * ts, 0.7 * ts, 0.14 * ts) * ANG(0, 0, rad(-sx * 12)), col2, mat, "wedge")
		end
	end
	if sp.cornes or o.cornes then
		for _, sx in { -1, 1 } do
			local a = (head * CF(sx * 0.35 * ts, 0.45 * ts, 0.2 * ts)).Position
			limb(c, a, a + V(sx * 0.25 * ts, 0.55 * ts, 0.45 * ts), 0.2 * ts, nil, BONE, mat)
		end
	end
	if o.defenses then
		local big = (o.scale or 1) > 1.2 and 1.4 or 1
		for _, sx in { -1, 1 } do
			local a = (head * CF(sx * 0.32 * ts, -0.38 * ts, -1.05 * ts)).Position
			local b = a + V(sx * 0.12 * ts, 0.32 * ts * big, -0.26 * ts * big)
			limb(c, a, b, 0.16 * ts * big, nil, BONE, mat)
			limb(c, b, b + V(sx * 0.04, 0.3 * ts * big, 0.08 * ts), 0.12 * ts * big, nil, BONE, mat)
		end
	end
	if o.bois then
		local antler = o.spectre and f.glow or BONE
		for _, sx in { -1, 1 } do
			local a = (head * CF(sx * 0.32 * ts, 0.5 * ts, 0.1 * ts)).Position
			local b = a + V(sx * 0.45 * ts, 1.1 * ts, 0.25 * ts)
			local tip = b + V(sx * 0.35 * ts, 0.8 * ts, 0.15 * ts)
			limb(c, a, b, 0.17 * ts, nil, antler, mat)
			limb(c, b, tip, 0.13 * ts, nil, antler, mat)
			limb(c, b, b + V(sx * 0.05, 0.6 * ts, -0.4 * ts), 0.11 * ts, nil, antler, mat)
			limb(c, a:Lerp(b, 0.5), a:Lerp(b, 0.5) + V(sx * 0.1, 0.45 * ts, -0.35 * ts), 0.1 * ts, nil, antler, mat)
		end
	end
	if o.criniere then
		local mane = C[o.criniere] or BONE
		for i = 0, 2 do
			local p = neckA:Lerp(hc, 0.15 + i * 0.3)
			chunk(c, V(0.95 * ts, 0.55 * ts, 0.7 * ts), CF(p + V(0, 0.55 * ts - i * 0.05 * ts, 0.1 * ts)) * ANG(rad(-20), 0, 0), mane, Mat.Fabric)
		end
		if sp.algues then
			for i = 1, 3 do
				local p = neckA:Lerp(hc, i / 4)
				part(c, V(0.14 * s, 0.9 * s, 0.14 * s), CF(p + V((i % 2 == 0 and 0.4 or -0.4) * ts, -0.1 * s, 0)), mane, Mat.Fabric)
			end
		end
	end
	if sp.fourrure then
		chunk(c, V(W * 1.3, H * 0.85, 0.9 * s), CF(neckA + V(0, 0.05 * s, 0.1 * s)) * ANG(rad(-25), 0, 0), col, Mat.Fabric, col2)
	end
	if sp.collerette then
		for i = -2, 2 do
			part(c, V(0.16 * ts, 0.75 * ts, 0.4 * ts), head * CF(i * 0.3 * ts, 0.3 * ts, 0.55 * ts) * ANG(rad(25), 0, rad(-i * 22)), col2, mat, "wedge")
		end
	end
	if sp.cicatrice then
		part(c, V(0.08 * ts, 0.7 * ts, 0.12 * ts), head * CF(-0.3 * ts, 0.15 * ts, -0.57 * ts) * ANG(0, 0, rad(30)), f.glow, Mat.Neon)
	end
	-- queue
	local tz = L * 0.5
	if plat then
		chain(c, { V(0, by, tz), V(0, by - 0.1 * s, tz + 1.0 * s), V(0, 0.45 * s, tz + 2.0 * s), V(0, 0.3 * s, tz + 2.9 * s) }, { 0.7 * s, 0.5 * s, 0.32 * s }, { col }, mat, col2)
	elseif o.queue then
		chain(c, { V(0, by + 0.25 * s, tz), V(0, by + 0.55 * s, tz + 0.7 * s), V(0, by + 0.35 * s, tz + 1.4 * s) }, { 0.4 * s, 0.32 * s }, { col, col2 }, mat)
	else
		part(c, V(0.3 * s, 0.3 * s, 0.4 * s), CF(0, by + 0.2 * s, tz + 0.15 * s), col, mat)
	end
	if sp.ailes then
		for _, sx in { -1, 1 } do
			membraneWing(c, CF(sx * W * 0.4, by + H * 0.5, -L * 0.15) * ANG(0, 0, rad(sx * 25)), sx, 2.2 * s, 1.4 * s, dark, col2, mat, 0.18 * s)
		end
	end
	-- crête et décor de famille sur le dos
	local spineA, spineB = V(0, by + H * 0.62, -L * 0.42), V(0, by + H * 0.5, L * 0.45)
	if sp.epines then
		spines(c, spineA, spineB, sp.epines, 0.75 * s, f.deco == "cristal" and f.accent or dark, mat)
	end
	if not sp.carapace then
		backDeco(c, f, spineA, spineB, W, s, f.deco == "or" and 3 or 4)
	else
		backDeco(c, f, spineA + V(0, H * 0.7, 0), spineB + V(0, H * 0.7, 0), W, s, 3)
	end
	if o.spectre then
		for _, p in c.m:GetChildren() do
			if p:IsA("BasePart") and p.Material ~= Mat.Neon then
				p.Transparency = math.max(p.Transparency, 0.3)
			elseif p:IsA("BasePart") then
				p.Transparency = math.max(p.Transparency, 0.25)
			end
		end
	end
	return chest
end

-- arme en main (repère de la main droite, s = échelle)
local function weapon(c, kind: string, hand: Vector3, s: number, glow: Color3, WOOD: Color3)
	local up = ANG(rad(-30), 0, 0)
	if kind == "epee" then
		part(c, V(0.24 * s, 2.7 * s, 0.42 * s), CF(hand + V(0, 1.0 * s, -0.45 * s)) * up, METAL, Mat.Metal)
		part(c, V(1.0 * s, 0.22 * s, 0.28 * s), CF(hand + V(0, -0.1 * s, 0)) * up, WOOD, Mat.Metal)
		part(c, V(0.2 * s, 0.55 * s, 0.2 * s), CF(hand + V(0, -0.45 * s, 0.2 * s)) * up, WOOD, Mat.Wood)
	elseif kind == "hache" then
		part(c, V(0.26 * s, 3.1 * s, 0.26 * s), CF(hand + V(0, 0.6 * s, -0.3 * s)) * ANG(rad(-25), 0, 0), WOOD, Mat.Wood)
		part(c, V(0.2 * s, 1.2 * s, 1.1 * s), CF(hand + V(0, 1.85 * s, -0.98 * s)) * ANG(rad(-25), 0, 0), METAL, Mat.Metal)
		part(c, V(0.16 * s, 0.5 * s, 0.4 * s), CF(hand + V(0, 1.85 * s, -0.25 * s)) * ANG(rad(-25), 0, 0), METAL, Mat.Metal)
	elseif kind == "lance" then
		part(c, V(0.2 * s, 5.2 * s, 0.2 * s), CF(hand + V(0, 1 * s, 0)), WOOD, Mat.Wood)
		part(c, V(0.34 * s, 0.9 * s, 0.34 * s), CF(hand + V(0, 4 * s, 0)) * ANG(0, rad(45), 0), METAL, Mat.Metal)
	elseif kind == "arc" then
		part(c, V(0.16 * s, 1.6 * s, 0.16 * s), CF(hand + V(0, 1.0 * s, -0.3 * s)) * ANG(rad(-18), 0, 0), WOOD, Mat.Wood)
		part(c, V(0.16 * s, 1.6 * s, 0.16 * s), CF(hand + V(0, -0.4 * s, -0.3 * s)) * ANG(rad(18), 0, 0), WOOD, Mat.Wood)
		part(c, V(0.05, 2.9 * s, 0.05), CF(hand + V(0, 0.3 * s, -0.02 * s)), BONE, Mat.Fabric)
	elseif kind == "dague" then
		part(c, V(0.16 * s, 1.1 * s, 0.32 * s), CF(hand + V(0, 0.55 * s, -0.2 * s)), METAL, Mat.Metal)
		part(c, V(0.5 * s, 0.14 * s, 0.2 * s), CF(hand + V(0, 0, -0.2 * s)), WOOD, Mat.Wood)
	elseif kind == "massue" then
		part(c, V(0.5 * s, 3 * s, 0.5 * s), CF(hand + V(0, 0.8 * s, -0.4 * s)) * ANG(rad(-30), 0, 0), WOOD, Mat.Wood)
		chunk(c, V(1.2 * s, 1.3 * s, 1.2 * s), CF(hand + V(0, 2.2 * s, -1.2 * s)) * ANG(rad(-30), 0, 0), WOOD, Mat.Wood)
		for i = 1, 3 do
			part(c, V(0.18 * s, 0.42 * s, 0.18 * s), CF(hand + V((i - 2) * 0.4 * s, 2.85 * s, -1.6 * s)) * ANG(rad(-60), 0, 0), METAL, Mat.Metal)
		end
	elseif kind == "baton" then
		part(c, V(0.22 * s, 4.6 * s, 0.22 * s), CF(hand + V(0, 1 * s, 0)), WOOD, Mat.Wood)
		part(c, V(0.6 * s, 0.6 * s, 0.6 * s), CF(hand + V(0, 3.45 * s, 0)) * ANG(rad(45), rad(45), 0), glow, Mat.Neon)
		for _, sx in { -1, 1 } do
			part(c, V(0.14 * s, 0.7 * s, 0.14 * s), CF(hand + V(sx * 0.32 * s, 3.4 * s, 0)) * ANG(0, 0, rad(-sx * 20)), WOOD, Mat.Wood)
		end
	end
end

-- Humanoïdes : bandits, gardes, gobelins, trolls, géants, gisants, momies…
function F.humain(c, o, f, k, sp, C, SKIN)
	local s = (o.scale or 1) * (o.petit and 0.75 or 1)
	local cloth, cloth2 = C[o[1]] or C.R, C[o[2]] or C.BF
	local skin = o.peau and (C[o.peau] or SKIN) or SKIN
	local mat = o.pierre and Mat.Slate or Mat.Fabric
	local boot = darken(cloth2, 0.45)
	local giant = (o.scale or 1) >= 1.6
	local monster = giant or o.peau or o.pierre or k.night
	local glow = f.glow
	local legH = 2.2 * s
	-- jambes : cuisse, jambe, botte
	for _, sx in { -1, 1 } do
		local x = sx * 0.5 * s
		part(c, V(0.82 * s, 1.15 * s, 0.86 * s), CF(x, legH - 0.58 * s, 0), cloth2, mat)
		part(c, V(0.76 * s, 0.85 * s, 0.8 * s), CF(x, 0.82 * s, 0), cloth2, mat)
		part(c, V(0.86 * s, 0.46 * s, 1.02 * s), CF(x, 0.23 * s, -0.08 * s), boot, Mat.SmoothPlastic)
	end
	local lean = o.courbe and ANG(rad(-18), 0, 0) or CFrame.identity
	local TX, TY, TZ = 2 * s, 2.2 * s, 1.1 * s
	local ty = legH + TY / 2
	local torsoCF = CF(0, ty, 0) * lean
	local body = chunk(c, V(TX + (o.ventre and 0.6 * s or 0), TY, TZ + (o.ventre and 0.8 * s or 0)), torsoCF, cloth, mat, nil, cloth2)
	-- ceinture et boucle
	part(c, V(TX + 0.08 * s, 0.32 * s, TZ + 0.1 * s + (o.ventre and 0.8 * s or 0)), CF(0, legH + 0.22 * s, 0), boot, Mat.SmoothPlastic)
	part(c, V(0.34 * s, 0.26 * s, 0.06 * s), CF(0, legH + 0.22 * s, -(TZ + (o.ventre and 0.8 * s or 0)) / 2 - 0.08 * s), METAL, Mat.Metal)
	if sp.bandelettes then
		for i = 0, 3 do
			part(c, V(TX + 0.06 * s, 0.14 * s, TZ + 0.06 * s), torsoCF * CF(0, -0.8 * s + i * 0.5 * s, 0) * ANG(0, 0, rad(i % 2 == 0 and 8 or -8)), BONE, Mat.Fabric)
		end
	end
	-- épaulières : fer (armés), fourrure, roc, glace, mousse
	local shoulderKind = sp.epaulieres or (o.helmet and "fer") or nil
	local hand
	for _, sx in { -1, 1 } do
		local sh = (torsoCF * CF(sx * (TX / 2 + 0.38 * s), TY * 0.32, 0)).Position
		local el = sh + V(sx * 0.08 * s, -1.05 * s, -0.12 * s)
		local wr = el + V(0, -0.95 * s, -0.3 * s)
		limb(c, sh, el, 0.72 * s, 0.76 * s, cloth, mat)
		limb(c, el, wr, 0.64 * s, 0.68 * s, monster and skin or cloth, mat)
		part(c, V(0.6 * s, 0.52 * s, 0.62 * s), CF(wr + V(0, -0.2 * s, 0)), skin, Mat.SmoothPlastic)
		if sx == 1 then
			hand = wr + V(0, -0.2 * s, 0)
		end
		if shoulderKind == "fer" then
			chunk(c, V(0.95 * s, 0.55 * s, 1.0 * s), CF(sh + V(sx * 0.08 * s, 0.32 * s, 0)), METAL, Mat.Metal)
		elseif shoulderKind == "fourrure" then
			chunk(c, V(1.0 * s, 0.6 * s, 1.1 * s), CF(sh + V(0, 0.3 * s, 0)), BONE, Mat.Fabric)
		elseif shoulderKind == "roc" then
			chunk(c, V(1.15 * s, 0.85 * s, 1.15 * s), CF(sh + V(sx * 0.1 * s, 0.4 * s, 0)) * ANG(0, rad(20), rad(sx * 10)), C.P or METAL, Mat.Slate)
		elseif shoulderKind == "glace" then
			crystal(c, sh + V(0, 0.25 * s, 0), 1.1 * s, 0.4 * s, ANG(0, 0, rad(-sx * 25)), f.accent or Color3.fromRGB(170, 222, 255), glow)
			crystal(c, sh + V(-sx * 0.3 * s, 0.25 * s, 0.3 * s), 0.8 * s, 0.32 * s, ANG(rad(15), 0, rad(-sx * 10)), f.accent or Color3.fromRGB(170, 222, 255), nil)
		elseif shoulderKind == "mousse" then
			part(c, V(1.0 * s, 0.3 * s, 1.0 * s), CF(sh + V(0, 0.4 * s, 0)), f.accent or C.V, Mat.Grass)
			part(c, V(0.5 * s, 0.14 * s, 0.34 * s), CF(sh + V(sx * 0.2 * s, 0.62 * s, 0)) * ANG(0, rad(30), rad(sx * 30)), f.accent or C.V, Mat.Grass)
		end
	end
	-- tête
	local hy = legH + TY + 0.66 * s
	local hz = o.courbe and -0.5 * s or 0
	local head = CF(0, hy, hz)
	chunk(c, V(1.2 * s, 1.28 * s, 1.16 * s), head, skin, Mat.SmoothPlastic)
	if sp.oeil then
		part(c, V(0.62 * s, 0.5 * s, 0.1 * s), head * CF(0, 0.12 * s, -0.6 * s), glow, Mat.Neon)
		part(c, V(0.95 * s, 0.22 * s, 0.2 * s), head * CF(0, 0.48 * s, -0.58 * s), boot, Mat.SmoothPlastic)
	else
		eyes(c, head * CF(0, 0.12 * s, -0.6 * s), 0.28 * s, 0.2 * s, monster and glow or boot, monster and boot or nil)
	end
	if giant or o.peau then
		part(c, V(0.9 * s, 0.2 * s, 0.4 * s), head * CF(0, -0.42 * s, -0.48 * s), boot, Mat.SmoothPlastic)
		for _, sx in { -1, 1 } do
			part(c, V(0.16 * s, 0.3 * s, 0.16 * s), head * CF(sx * 0.3 * s, -0.28 * s, -0.66 * s), BONE, Mat.SmoothPlastic)
		end
	end
	if o.hood then
		chunk(c, V(1.48 * s, 1.18 * s, 1.38 * s), head * CF(0, 0.26 * s, 0.12 * s), cloth2, Mat.Fabric)
		part(c, V(1.0 * s, 0.7 * s, 0.1 * s), head * CF(0, 0.05 * s, -0.62 * s), boot, Mat.Fabric)
		eyes(c, head * CF(0, 0.12 * s, -0.69 * s), 0.25 * s, 0.17 * s, monster and glow or BONE)
	end
	if o.helmet then
		chunk(c, V(1.38 * s, 0.95 * s, 1.32 * s), head * CF(0, 0.36 * s, 0), METAL, Mat.Metal)
		part(c, V(0.2 * s, 0.95 * s, 0.12 * s), head * CF(0, 0, -0.67 * s), METAL, Mat.Metal)
		part(c, V(0.2 * s, 0.6 * s, 1.0 * s), head * CF(0, 1.0 * s, 0.1 * s), cloth, Mat.Fabric)
	end
	if o.cornes then
		for _, sx in { -1, 1 } do
			local a = (head * CF(sx * 0.6 * s, 0.4 * s, 0)).Position
			local b = a + V(sx * 0.6 * s, 0.25 * s, -0.1 * s)
			limb(c, a, b, 0.32 * s, nil, BONE, Mat.SmoothPlastic)
			limb(c, b, b + V(sx * 0.15 * s, 0.6 * s, -0.25 * s), 0.22 * s, nil, BONE, Mat.SmoothPlastic)
		end
	end
	if o.cape then
		local capeCol = C[o.cape] or cloth
		part(c, V(TX * 1.05, TY + legH * 0.6, 0.16 * s), torsoCF * CF(0, -legH * 0.3, TZ / 2 + 0.1 * s) * ANG(rad(6), 0, 0), capeCol, Mat.Fabric)
		part(c, V(TX * 1.15, 0.3 * s, 0.5 * s), torsoCF * CF(0, TY / 2, TZ / 2), boot, Mat.Fabric)
	end
	if giant and (f.deco == "cristal" or f.deco == "amethyste") and shoulderKind ~= "glace" then
		backDeco(c, f, (torsoCF * CF(0, TY * 0.45, TZ * 0.45)).Position, (torsoCF * CF(0, -TY * 0.1, TZ * 0.5)).Position, TX, s, 3)
	end
	-- attributs de métier (palette de la créature : tissu, cuir, métal, os, lueur)
	local back = torsoCF * CF(0, 0, TZ / 2 + 0.05 * s)
	for _, a in sp.acc or {} do
		if a == "masque" then
			part(c, V(1.24 * s, 0.42 * s, 1.2 * s), head * CF(0, -0.28 * s, -0.02 * s), cloth2, Mat.Fabric)
		elseif a == "chapeau" then
			part(c, V(2.1 * s, 0.14 * s, 2.0 * s), head * CF(0, 0.7 * s, 0), boot, Mat.Fabric)
			chunk(c, V(1.15 * s, 0.6 * s, 1.1 * s), head * CF(0, 1.0 * s, 0), boot, Mat.Fabric)
		elseif a == "turban" then
			chunk(c, V(1.4 * s, 0.7 * s, 1.35 * s), head * CF(0, 0.58 * s, 0.02 * s), cloth2, Mat.Fabric)
			part(c, V(0.4 * s, 1.2 * s, 0.14 * s), head * CF(0.25 * s, -0.4 * s, 0.62 * s) * ANG(rad(12), 0, 0), cloth2, Mat.Fabric)
		elseif a == "sac" then
			chunk(c, V(1.3 * s, 1.4 * s, 0.7 * s), back * CF(0, 0.1 * s, 0.35 * s), boot, Mat.Fabric)
			part(c, V(1.0 * s, 0.24 * s, 0.3 * s), back * CF(0, 0.85 * s, 0.45 * s), cloth2, Mat.Fabric)
		elseif a == "carquois" then
			local q = back * CF(0.45 * s, 0.2 * s, 0.3 * s) * ANG(0, 0, rad(-22))
			part(c, V(0.5 * s, 1.6 * s, 0.5 * s), q, boot, Mat.Fabric)
			for i = -1, 1 do
				part(c, V(0.08 * s, 0.5 * s, 0.08 * s), q * CF(i * 0.12 * s, 1.0 * s, 0), BONE, Mat.SmoothPlastic)
			end
		elseif a == "bandouliere" then
			part(c, V(0.3 * s, TY * 1.25, TZ + 0.14 * s), torsoCF * ANG(0, 0, rad(38)), boot, Mat.Fabric)
			for i = -1, 1 do
				part(c, V(0.22 * s, 0.22 * s, 0.1 * s), torsoCF * ANG(0, 0, rad(38)) * CF(0, i * 0.5 * s, -(TZ / 2 + 0.1 * s)), METAL, Mat.Metal)
			end
		elseif a == "bouclier" then
			local sh = back * CF(-0.2 * s, 0.1 * s, 0.2 * s) * ANG(0, 0, rad(10))
			part(c, V(1.5 * s, 1.8 * s, 0.22 * s), sh, cloth, Mat.Wood)
			part(c, V(1.6 * s, 0.22 * s, 0.26 * s), sh * CF(0, 0.3 * s, 0), METAL, Mat.Metal)
			part(c, V(0.42 * s, 0.42 * s, 0.3 * s), sh * CF(0, -0.1 * s, 0.06 * s), METAL, Mat.Metal)
		elseif a == "tabard" then
			part(c, V(1.1 * s, TY * 0.95 + 0.9 * s, 0.12 * s), torsoCF * CF(0, -0.45 * s, -(TZ / 2 + 0.07 * s)), cloth2, Mat.Fabric)
			part(c, V(0.5 * s, 0.5 * s, 0.06 * s), torsoCF * CF(0, 0.3 * s, -(TZ / 2 + 0.14 * s)) * ANG(0, 0, rad(45)), METAL, Mat.Metal)
		elseif a == "cape_dechiree" then
			for i = -1, 1 do
				local len = (TY + legH * (0.35 + 0.2 * ((i + 1) % 2)))
				part(c, V(TX * 0.34, len, 0.14 * s), torsoCF * CF(i * TX * 0.33, TY / 2 - len / 2, TZ / 2 + 0.12 * s), cloth2, Mat.Fabric)
			end
		elseif a == "lanterne" then
			local l = torsoCF * CF(-TX / 2 - 0.15 * s, -TY / 2 + 0.1 * s, -0.2 * s)
			part(c, V(0.45 * s, 0.55 * s, 0.45 * s), l, METAL, Mat.Metal)
			part(c, V(0.3 * s, 0.36 * s, 0.3 * s), l, glow, Mat.Neon)
		elseif a == "runes" then
			for i = -1, 1 do
				part(c, V(0.16 * s, 0.6 * s, 0.06 * s), torsoCF * CF(i * 0.5 * s, 0.1 * s, -(TZ / 2 + 0.06 * s)) * ANG(0, 0, rad(i * 20)), glow, Mat.Neon)
			end
		end
	end
	if o.weapon and hand then
		weapon(c, o.weapon, hand, s, glow, boot)
	end
	return body
end

-- Insectes et carapaces : araignées, scarabées, crabe, mante
function F.insecte(c, o, f, k, sp, C, _, id)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.N, C[o[2]] or C.R
	local dark = darken(col, 0.45)
	local glow = f.glow
	if o.pattes8 then
		-- araignée : abdomen à motif, céphalothorax, 8 pattes coudées, crochets, grappe d'yeux
		local abd = chunk(c, V(2.5 * s, 1.9 * s, 2.7 * s), CF(0, 1.75 * s, 1.35 * s), col, Mat.SmoothPlastic, nil, dark)
		for i = 0, 2 do
			part(c, V((1.4 - i * 0.35) * s, 0.14 * s, 0.32 * s), CF(0, 2.78 * s, 0.75 * s + i * 0.55 * s) * ANG(0, rad(45), 0), col2, Mat.SmoothPlastic)
		end
		chunk(c, V(1.65 * s, 1.15 * s, 1.55 * s), CF(0, 1.35 * s, -0.65 * s), col, Mat.SmoothPlastic, nil, dark)
		local face = CF(0, 1.45 * s, -1.45 * s)
		eyes(c, face, 0.26 * s, 0.24 * s, glow)
		eyes(c, face * CF(0, 0.3 * s, 0.02 * s), 0.48 * s, 0.13 * s, glow)
		for _, sx in { -1, 1 } do
			limb(c, (face * CF(sx * 0.25 * s, -0.35 * s, 0)).Position, (face * CF(sx * 0.18 * s, -0.95 * s, -0.25 * s)).Position, 0.18 * s, nil, BONE, Mat.SmoothPlastic)
		end
		for i = 1, 4 do
			local z = (-1.25 + (i - 1) * 0.55) * s
			for _, sx in { -1, 1 } do
				local hip = V(sx * 0.7 * s, 1.3 * s, z)
				local knee = V(sx * 2.0 * s, 2.5 * s, z * 1.25)
				local foot = V(sx * 3.1 * s, 0.05, z * 1.6)
				limb(c, hip, knee, 0.24 * s, nil, col, Mat.SmoothPlastic)
				limb(c, knee, foot, 0.2 * s, nil, col, Mat.SmoothPlastic)
				part(c, V(0.32 * s, 0.32 * s, 0.32 * s), CF(knee), col2, Mat.SmoothPlastic)
			end
		end
		backDeco(c, f, V(0, 2.75 * s, 0.6 * s), V(0, 2.5 * s, 2.3 * s), 2.2 * s, s, 3)
		return abd
	elseif id == "giant_crab" then
		local shell = chunk(c, V(3.3 * s, 1.3 * s, 2.4 * s), CF(0, 1.6 * s, 0), col, Mat.SmoothPlastic, darken(col, 0.15), col2)
		for i = -1, 1 do
			part(c, V(0.3 * s, 0.25 * s, 0.3 * s), CF(i * 0.9 * s, 2.32 * s, -0.3 * s) * ANG(0, rad(45), 0), col2, Mat.SmoothPlastic)
		end
		for _, sx in { -1, 1 } do
			local stalkA = V(sx * 0.45 * s, 2.1 * s, -1.0 * s)
			limb(c, stalkA, stalkA + V(0, 0.6 * s, -0.1 * s), 0.14 * s, nil, col, Mat.SmoothPlastic)
			part(c, V(0.24 * s, 0.24 * s, 0.24 * s), CF(stalkA + V(0, 0.7 * s, -0.12 * s)), glow, Mat.Neon)
			-- pince : bras, avant-bras, deux mâchoires
			local sh = V(sx * 1.4 * s, 1.5 * s, -1.0 * s)
			local el = sh + V(sx * 0.7 * s, 0.1 * s, -0.8 * s)
			limb(c, sh, el, 0.42 * s, nil, col, Mat.SmoothPlastic)
			local claw = CF(el + V(0, 0.1 * s, -0.7 * s))
			chunk(c, V(0.95 * s, 0.8 * s, 1.0 * s), claw, col, Mat.SmoothPlastic, nil, col2)
			part(c, V(0.32 * s, 0.32 * s, 0.9 * s), claw * CF(0, 0.3 * s, -0.8 * s) * ANG(rad(-12), 0, 0), col2, Mat.SmoothPlastic)
			part(c, V(0.3 * s, 0.26 * s, 0.75 * s), claw * CF(0, -0.18 * s, -0.72 * s) * ANG(rad(14), 0, 0), col2, Mat.SmoothPlastic)
			for i = 1, 3 do
				local z = (-0.4 + i * 0.55) * s
				local hip = V(sx * 1.4 * s, 1.3 * s, z)
				local knee = V(sx * 2.4 * s, 1.6 * s, z + 0.2 * s)
				limb(c, hip, knee, 0.24 * s, nil, col, Mat.SmoothPlastic)
				limb(c, knee, V(sx * 2.9 * s, 0.05, z + 0.4 * s), 0.18 * s, nil, col2, Mat.SmoothPlastic)
			end
		end
		return shell
	elseif id == "giant_mantis" then
		local thorax = limb(c, V(0, 1.6 * s, 0.6 * s), V(0, 3.4 * s, -0.4 * s), 0.6 * s, nil, col, Mat.SmoothPlastic)
		limb(c, V(0, 1.6 * s, 0.6 * s), V(0, 1.25 * s, 2.6 * s), 1.0 * s, 0.85 * s, col, Mat.SmoothPlastic)
		for _, sx in { -1, 1 } do
			part(c, V(0.7 * s, 0.1 * s, 2.0 * s), CF(sx * 0.32 * s, 1.85 * s, 1.6 * s) * ANG(rad(6), rad(sx * 6), 0), col2, Mat.Glass).Transparency = 0.3
		end
		local head = CF(0, 3.75 * s, -0.6 * s)
		part(c, V(1.0 * s, 0.7 * s, 0.6 * s), head, col, Mat.SmoothPlastic, "wedge")
		eyes(c, head * CF(0, 0.12 * s, -0.31 * s), 0.38 * s, 0.26 * s, glow)
		for _, sx in { -1, 1 } do
			local sh = V(sx * 0.34 * s, 3.0 * s, -0.5 * s)
			local el = sh + V(sx * 0.2 * s, 0.6 * s, -0.9 * s)
			limb(c, sh, el, 0.26 * s, nil, col, Mat.SmoothPlastic)
			limb(c, el, el + V(0, -1.2 * s, -0.2 * s), 0.22 * s, 0.45 * s, col2, Mat.SmoothPlastic)
			teeth(c, CF(el + V(0, -0.2 * s, -0.36 * s)), 0.2 * s, 3, 0.25 * s, BONE)
			for i = 1, 2 do
				local hip = V(sx * 0.3 * s, 1.5 * s, (0.2 + i * 0.6) * s)
				local knee = V(sx * 1.4 * s, 2.0 * s, (0.2 + i * 0.7) * s)
				limb(c, hip, knee, 0.16 * s, nil, col, Mat.SmoothPlastic)
				limb(c, knee, V(sx * 1.9 * s, 0.05, (0.3 + i * 0.8) * s), 0.13 * s, nil, col, Mat.SmoothPlastic)
			end
		end
		return thorax
	end
	-- scarabées (royal ou cuirassé) : élytres, corne, 6 pattes, antennes
	local royal = (o.scale or 1) >= 2
	local shellMat = o.carapace and Mat.Metal or Mat.SmoothPlastic
	local shell = chunk(c, V(2.6 * s, 1.5 * s, 3.0 * s), CF(0, 1.65 * s, 0.4 * s), col, shellMat, nil, dark)
	shell.Reflectance = 0.12
	part(c, V(0.12 * s, 1.0 * s, 2.9 * s), CF(0, 2.0 * s, 0.4 * s), col2, Mat.SmoothPlastic)
	chunk(c, V(1.6 * s, 1.0 * s, 1.0 * s), CF(0, 1.5 * s, -1.4 * s), dark, shellMat)
	local head = CF(0, 1.35 * s, -2.05 * s)
	part(c, V(1.1 * s, 0.7 * s, 0.6 * s), head, dark, Mat.SmoothPlastic)
	eyes(c, head * CF(0, 0.1 * s, -0.31 * s), 0.38 * s, 0.18 * s, glow)
	local hornCol = royal and (f.accent or C.O) or col2
	limb(c, (head * CF(0, 0.2 * s, -0.2 * s)).Position, (head * CF(0, 1.1 * s, -0.9 * s)).Position, 0.3 * s, nil, hornCol, royal and Mat.Metal or Mat.SmoothPlastic)
	limb(c, (head * CF(0, 1.1 * s, -0.9 * s)).Position, (head * CF(0, 1.5 * s, -0.5 * s)).Position, 0.2 * s, nil, hornCol, royal and Mat.Metal or Mat.SmoothPlastic)
	for _, sx in { -1, 1 } do
		limb(c, (head * CF(sx * 0.3 * s, 0.3 * s, -0.25 * s)).Position, (head * CF(sx * 0.7 * s, 0.9 * s, -0.7 * s)).Position, 0.08 * s, nil, dark, Mat.SmoothPlastic)
		for i = 1, 3 do
			local z = (-1.0 + (i - 1) * 1.0) * s
			local hip = V(sx * 1.1 * s, 1.1 * s, z)
			local knee = V(sx * 2.1 * s, 1.5 * s, z * 1.1)
			limb(c, hip, knee, 0.24 * s, nil, dark, Mat.SmoothPlastic)
			limb(c, knee, V(sx * 2.6 * s, 0.05, z * 1.2), 0.2 * s, nil, dark, Mat.SmoothPlastic)
		end
	end
	if royal then
		part(c, V(0.6 * s, 0.6 * s, 0.6 * s), CF(0, 2.45 * s, 0.4 * s) * ANG(rad(45), 0, rad(45)), glow, Mat.Neon)
	end
	backDeco(c, f, V(0, 2.4 * s, -0.4 * s), V(0, 2.3 * s, 1.5 * s), 2.2 * s, s, royal and 4 or 3)
	return shell
end

-- Serpents, vers, anguilles : corps en S, tête levée, crocs
function F.serpent(c, o, f, k, sp, C, _, id)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.V, C[o[2]] or C.Y
	local dark = darken(col, 0.4)
	local n = o.long and 10 or 7
	local pts, widths = {}, {}
	local r0 = 0.95 * s
	for i = 0, n do
		local t = i / n
		local w = r0 * (1 - t * 0.62)
		local lift = i <= 1 and (1 - i) * 1.1 * s or 0
		table.insert(pts, V(math.sin(i * 0.8) * 0.95 * s, w / 2 + lift, i * 0.85 * s))
		table.insert(widths, w)
	end
	local body = chain(c, pts, widths, { col, col }, Mat.SmoothPlastic, col2)
	if sp.nageoires then
		for i = 2, n - 1, 2 do
			local p = pts[i]
			part(c, V(0.12 * s, widths[i] * 0.9, 0.7 * s), CF(p + V(0, widths[i] * 0.75, 0)), col2, Mat.SmoothPlastic, "wedge")
		end
	end
	if sp.taches then
		for i = 2, n - 1 do
			local p = pts[i]
			for _, sx in { -1, 1 } do
				if i % 2 == 0 then
					part(c, V(0.08, widths[i] * 0.2, widths[i] * 0.2), CF(p + V(sx * widths[i] * 0.5, widths[i] * 0.1, 0)), f.glow, Mat.Neon)
				end
			end
		end
	end
	local hp = pts[1] + V(0, 0.15 * s, -0.75 * s)
	local head = CF(hp)
	if sp.gueule then
		-- ver des sables : gueule ronde garnie de dents, sans yeux
		chunk(c, V(1.6 * s, 1.6 * s, 1.0 * s), head, col, Mat.SmoothPlastic)
		part(c, V(1.0 * s, 1.0 * s, 0.1 * s), head * CF(0, 0, -0.52 * s), darken(col2, 0.55), Mat.SmoothPlastic)
		part(c, V(0.5 * s, 0.5 * s, 0.12 * s), head * CF(0, 0, -0.5 * s), f.glow, Mat.Neon)
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			part(c, V(0.16 * s, 0.42 * s, 0.16 * s), head * CF(math.cos(a) * 0.55 * s, math.sin(a) * 0.55 * s, -0.56 * s) * ANG(0, 0, a + math.pi / 2) * ANG(rad(-60), 0, 0), BONE, Mat.SmoothPlastic)
		end
		for i = 2, n, 2 do
			part(c, V(widths[i] * 1.05, 0.14 * s, 0.2 * s), CF(pts[i] + V(0, widths[i] * 0.1, 0)), col2, Mat.SmoothPlastic)
		end
	else
		chunk(c, V(1.15 * s, 0.75 * s, 1.4 * s), head, col, Mat.SmoothPlastic, nil, col2)
		part(c, V(1.0 * s, 0.24 * s, 1.1 * s), head * CF(0, -0.48 * s, -0.25 * s) * ANG(rad(18), 0, 0), dark, Mat.SmoothPlastic)
		for _, sx in { -1, 1 } do
			part(c, V(0.12 * s, 0.38 * s, 0.12 * s), head * CF(sx * 0.3 * s, -0.42 * s, -0.62 * s), BONE, Mat.SmoothPlastic)
		end
		eyes(c, head * CF(0, 0.2 * s, -0.71 * s), 0.34 * s, 0.17 * s, f.glow, dark)
		if s >= 1.5 then
			for _, sx in { -1, 1 } do
				local a = (head * CF(sx * 0.4 * s, 0.35 * s, 0.4 * s)).Position
				limb(c, a, a + V(sx * 0.2 * s, 0.35 * s, 0.6 * s), 0.18 * s, nil, BONE, Mat.SmoothPlastic)
			end
		end
	end
	backDeco(c, f, pts[2] + V(0, widths[2] * 0.45, 0), pts[math.max(3, n - 2)] + V(0, widths[n - 2] * 0.45, 0), r0, s * 0.8, f.deco == "or" and 3 or 4)
	return body
end

-- Volants : oiseaux, chauves-souris, gargouilles, griffons, wyvernes, essaims
function F.volant(c, o, f, k, sp, C, _, id)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.N, C[o[2]] or C.N
	local dark = darken(col, 0.4)
	local glow = f.glow
	if o.essaim then
		local core
		for i = 1, (sp.fee and 9 or 14) do
			local p = V(c.rng:NextNumber(-1.3, 1.3), 3.5 + c.rng:NextNumber(-0.8, 0.8), c.rng:NextNumber(-1.3, 1.3))
			local b = part(c, sp.fee and V(0.26, 0.4, 0.26) or V(0.34, 0.3, 0.44), CF(p), i % 2 == 0 and col or col2, Mat.SmoothPlastic)
			core = core or b
			if sp.fee then
				for _, sx in { -1, 1 } do
					local w = part(c, V(0.42, 0.05, 0.3), CF(p + V(sx * 0.3, 0.15, 0)) * ANG(0, 0, rad(sx * 30)), glow, Mat.Neon)
					w.Transparency = 0.35
				end
				continue
			end
			core = core or b
			if i % 3 == 0 then
				local wing = part(c, V(0.5, 0.04, 0.26), CF(p + V(0, 0.18, 0)) * ANG(0, 0, rad(20)), BONE, Mat.Glass)
				wing.Transparency = 0.4
			end
			if i % 4 == 0 then
				part(c, V(0.16, 0.16, 0.16), CF(p + V(0.25, 0.1, 0)), glow, Mat.Neon)
			end
		end
		return core
	end
	local dragon = id == "wyvern" or id == "snow_wyvern"
	local griffon = id == "griffin" or id == "hippogriff"
	if dragon or griffon then
		-- corps porté haut ; pattes pendantes ; cou, tête, ailes immenses, longue queue
		local y = 4.6 * s
		local L, W, H = 3.4 * s, 1.6 * s, 1.5 * s
		local cap = f.deco == "cristal" and f.accent or col
		local body = chunk(c, V(W, H, L), CF(0, y, 0), col, Mat.SmoothPlastic, cap, col2)
		chunk(c, V(W * 1.1, H * 1.05, L * 0.45), CF(0, y + 0.1 * s, -L * 0.35), griffon and BONE or col, Mat.SmoothPlastic, cap, col2)
		for _, sz in { -1, 1 } do
			for _, sx in { -1, 1 } do
				if dragon and sz < 0 then
					continue
				end
				local hip = V(sx * W * 0.4, y - H * 0.3, sz * L * 0.32)
				local knee = hip + V(sx * 0.1 * s, -1.0 * s, 0.35 * s)
				local foot = knee + V(0, -0.8 * s, -0.25 * s)
				local legCol = (griffon and sz < 0) and (C.O or col2) or ((sp.cheval and sz > 0) and col2 or col)
				local horse = sp.cheval and sz > 0
				limb(c, hip, knee, (horse and 0.62 or 0.5) * s, nil, legCol, Mat.SmoothPlastic)
				limb(c, knee, foot, (horse and 0.44 or 0.36) * s, nil, legCol, Mat.SmoothPlastic)
				if horse then
					part(c, V(0.5 * s, 0.3 * s, 0.55 * s), CF(foot), dark, Mat.SmoothPlastic)
				else
					claws(c, foot, 3, s * 0.9, dark)
				end
			end
		end
		local neckA = V(0, y + H * 0.3, -L * 0.5)
		local hc = neckA + V(0, (dragon and 1.6 or 0.9) * s, -(dragon and 1.2 or 0.7) * s)
		if dragon then
			chain(c, { neckA, neckA + V(0, 0.8 * s, -0.5 * s), hc + V(0, -0.2 * s, 0.4 * s) }, { 0.9 * s, 0.72 * s }, { col }, Mat.SmoothPlastic, col2)
		end
		local head = CF(hc)
		chunk(c, V(1.2 * s, 1.05 * s, 1.3 * s), head, griffon and BONE or col, Mat.SmoothPlastic, cap)
		eyes(c, head * CF(0, 0.15 * s, -0.66 * s), 0.34 * s, 0.22 * s, glow, dark)
		if griffon then
			-- bec crochu doré
			part(c, V(0.6 * s, 0.5 * s, 0.7 * s), head * CF(0, -0.05 * s, -0.95 * s), C.O or col2, Mat.SmoothPlastic)
			part(c, V(0.4 * s, 0.45 * s, 0.3 * s), head * CF(0, -0.32 * s, -1.25 * s), C.O or col2, Mat.SmoothPlastic)
			for i = -1, 1 do
				part(c, V(0.3 * s, 0.6 * s, 0.2 * s), head * CF(i * 0.35 * s, 0.6 * s, 0.35 * s) * ANG(rad(-35), 0, rad(-i * 18)), BONE, Mat.SmoothPlastic, "wedge")
			end
		else
			part(c, V(0.85 * s, 0.5 * s, 1.0 * s), head * CF(0, -0.2 * s, -1.05 * s), col, Mat.SmoothPlastic)
			part(c, V(0.8 * s, 0.22 * s, 0.95 * s), head * CF(0, -0.58 * s, -0.95 * s) * ANG(rad(14), 0, 0), dark, Mat.SmoothPlastic)
			teeth(c, head * CF(0, -0.45 * s, -1.4 * s), 0.7 * s, 5, 0.2 * s)
			for _, sx in { -1, 1 } do
				local a = (head * CF(sx * 0.4 * s, 0.45 * s, 0.3 * s)).Position
				local b = a + V(sx * 0.3 * s, 0.6 * s, 0.7 * s)
				limb(c, a, b, 0.26 * s, nil, BONE, Mat.SmoothPlastic)
				limb(c, b, b + V(sx * 0.05, 0.1 * s, 0.5 * s), 0.16 * s, nil, BONE, Mat.SmoothPlastic)
			end
		end
		for _, sx in { -1, 1 } do
			local root = CF(sx * W * 0.45, y + H * 0.4, -L * 0.1) * ANG(0, 0, rad(sx * 30))
			if griffon then
				featherWing(c, root, sx, 4.2 * s, 2.4 * s, { BONE, col, dark }, 3)
			else
				membraneWing(c, root, sx, 4.6 * s, 2.6 * s, dark, col2, Mat.SmoothPlastic, 0.3 * s)
			end
		end
		local tz = L * 0.5
		local tail = { V(0, y, tz), V(0, y - 0.3 * s, tz + 1.3 * s), V(0, y - 0.9 * s, tz + 2.5 * s), V(0, y - 1.3 * s, tz + 3.6 * s) }
		chain(c, tail, { 0.8 * s, 0.6 * s, 0.4 * s }, { col }, Mat.SmoothPlastic, col2)
		if sp.cheval then
			for i = -1, 1 do
				part(c, V(0.22 * s, 1.6 * s, 0.22 * s), CF(tail[2] + V(i * 0.18 * s, -0.7 * s, 0.1 * s)) * ANG(rad(-15), 0, rad(i * 8)), dark, Mat.Fabric)
			end
		elseif griffon then
			chunk(c, V(0.7 * s, 0.7 * s, 0.7 * s), CF(tail[4]), dark, Mat.Fabric)
		else
			part(c, V(0.9 * s, 0.14 * s, 0.9 * s), CF(tail[4]) * ANG(0, rad(45), 0), dark, Mat.SmoothPlastic)
			spines(c, V(0, y + H * 0.55, -L * 0.4), tail[3] + V(0, 0.3 * s, 0), 6, 0.7 * s, f.deco == "cristal" and f.accent or dark, Mat.SmoothPlastic)
		end
		backDeco(c, f, V(0, y + H * 0.55, -L * 0.3), V(0, y + H * 0.5, L * 0.4), W, s, 4)
		return body
	end
	local bat = o.chauvesouris
	local gar = o.gargouille
	local owl = id == "spectral_owl"
	local y = 3.5
	local mat = gar and Mat.Slate or Mat.SmoothPlastic
	local bs = gar and 1.3 or 1
	local body = chunk(c, V(1.15 * bs, 1.3 * bs, 1.5 * bs), CF(0, y, 0) * ANG(rad(-15), 0, 0), col, mat, nil, owl and BONE or col2)
	local head = CF(0, y + 0.95 * bs, -0.55 * bs)
	chunk(c, V((owl and 1.2 or 0.95) * bs, 0.9 * bs, 0.9 * bs), head, col, mat)
	if owl then
		part(c, V(1.0, 0.75, 0.1), head * CF(0, 0, -0.46), BONE, Mat.SmoothPlastic)
		eyes(c, head * CF(0, 0.05, -0.52), 0.25, 0.28, glow, dark)
		for _, sx in { -1, 1 } do
			part(c, V(0.22, 0.45, 0.22), head * CF(sx * 0.42, 0.6, 0) * ANG(0, 0, rad(-sx * 18)), col2, mat, "wedge")
		end
		part(c, V(0.18, 0.22, 0.2), head * CF(0, -0.18, -0.58), C.O or BONE, Mat.SmoothPlastic)
	else
		eyes(c, head * CF(0, 0.1 * bs, -0.46 * bs), 0.22 * bs, 0.16 * bs, glow, dark)
	end
	if bat then
		for _, sx in { -1, 1 } do
			part(c, V(0.3, 0.7, 0.3), head * CF(sx * 0.32, 0.65, 0.05) * ANG(0, 0, rad(-sx * 14)), col2, mat, "wedge")
		end
		teeth(c, head * CF(0, -0.35, -0.47), 0.3, 2, 0.16)
	elseif gar then
		for _, sx in { -1, 1 } do
			local a = (head * CF(sx * 0.35 * bs, 0.4 * bs, 0.1)).Position
			limb(c, a, a + V(sx * 0.25, 0.7, 0.35), 0.22, nil, col2, mat)
		end
		teeth(c, head * CF(0, -0.38 * bs, -0.47 * bs), 0.6, 3, 0.18)
	elseif not owl then
		part(c, V(0.32, 0.3, 0.55), head * CF(0, -0.1, -0.68), C.O or BONE, Mat.SmoothPlastic, "wedge", ANG(0, math.pi, 0))
		part(c, V(0.2, 0.18, 0.25), head * CF(0, -0.28, -0.85), dark, Mat.SmoothPlastic)
		if id == "harpy" or id == "cliff_raptor" then
			for i = 1, 3 do
				part(c, V(0.14, 0.5, 0.36), head * CF(0, 0.45 + i * 0.05, 0.1 + i * 0.18) * ANG(rad(-40), 0, 0), col2, mat, "wedge")
			end
		end
	end
	for _, sx in { -1, 1 } do
		local root = CF(sx * 0.5 * bs, y + 0.35 * bs, -0.1) * ANG(0, 0, rad(sx * (bat and 14 or 28)))
		if bat or gar then
			membraneWing(c, root, sx, (gar and 2.8 or 2.4), (gar and 1.8 or 1.4), dark, col2, mat, 0.16 * bs)
		else
			featherWing(c, root, sx, 2.6, 1.4, { col, col2, dark }, 3)
		end
		limb(c, V(sx * 0.3, y - 0.6 * bs, 0.2), V(sx * 0.32, y - 1.25 * bs, 0.05), 0.16 * bs, nil, C.O or dark, Mat.SmoothPlastic)
		part(c, V(0.3 * bs, 0.1, 0.36 * bs), CF(sx * 0.32, y - 1.32 * bs, -0.05), dark, Mat.SmoothPlastic)
	end
	if not bat then
		for i = -1, 1 do
			part(c, V(0.32, 0.12, 0.9 * bs), CF(i * 0.3, y - 0.3 * bs, 1.1 * bs) * ANG(rad(-12), rad(i * 18), 0), i == 0 and col2 or dark, mat)
		end
	end
	if gar then
		chain(c, { V(0, y - 0.4, 0.8), V(0, y - 1.0, 1.6), V(0, y - 1.2, 2.4) }, { 0.28, 0.2 }, { col }, mat)
	end
	backDeco(c, f, V(0, y + 0.65 * bs, -0.3), V(0, y + 0.5 * bs, 0.5), 1.0 * bs, 0.7, 2)
	if sp.fantome then
		for i = 1, 3 do
			part(c, V(0.22, 0.22, 0.22), CF(c.rng:NextNumber(-0.3, 0.3), y - 0.2 + i * 0.1, 1.0 + i * 0.55), glow, Mat.Neon).Transparency = 0.2 + i * 0.15
		end
	end
	if (k.night and f.deco == "spectre") or sp.fantome then
		for _, p in c.m:GetChildren() do
			if p:IsA("BasePart") and p.Material ~= Mat.Neon then
				p.Transparency = math.max(p.Transparency, 0.3)
			end
		end
	end
	return body
end

-- feuillage d'un ent : violet s'il est corrompu, sinon la mousse de sa famille
local function leafColor(o, C, f): Color3
	if o[2] == "VI" then
		return C.VI
	end
	return f.accent or C.V or Color3.fromRGB(80, 140, 60)
end

-- Golems : pierre, bois, grès, vase ; ents ; la Mère des Ronces
function F.golem(c, o, f, k, sp, C)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.P, C[o[2]] or C.O
	local woody = o[1] == "B" or o[1] == "V" or (o[1] == "BF" and sp.couronne_arbre)
	local mat = woody and Mat.Wood or (o[1] == "Y" and Mat.Sandstone or (o[1] == "BF" and Mat.Mud or Mat.Slate))
	local dark = darken(col, 0.35)
	local glow = f.glow
	local cap = (f.deco == "mousse" or f.deco == "vase" or f.deco == "cristal") and f.accent or nil
	-- jambes trapues
	for _, sx in { -1, 1 } do
		chunk(c, V(1.35 * s, 2.3 * s, 1.35 * s), CF(sx * 0.95 * s, 1.2 * s, 0.1 * s), col, mat)
		part(c, V(1.55 * s, 0.4 * s, 1.75 * s), CF(sx * 0.95 * s, 0.2 * s, -0.1 * s), dark, mat)
	end
	chunk(c, V(2.6 * s, 1.0 * s, 1.6 * s), CF(0, 2.6 * s, 0.1 * s), dark, mat)
	-- torse voûté, cœur lumineux encadré
	local torso = CF(0, 4.15 * s, 0) * ANG(rad(-10), 0, 0)
	local body = chunk(c, V(3.5 * s, 2.9 * s, 2.15 * s), torso, col, mat, cap, dark)
	local coreCol = o[2] and C[o[2]] or glow
	part(c, V(0.82 * s, 0.82 * s, 0.12), torso * CF(0, 0.15 * s, -1.1 * s) * ANG(0, 0, rad(45)), glow, Mat.Neon)
	for i = 0, 3 do
		local a = i * math.pi / 2
		part(c, V(0.3 * s, 0.3 * s, 0.14), torso * CF(math.cos(a) * 0.72 * s, 0.15 * s + math.sin(a) * 0.72 * s, -1.09 * s), coreCol, mat == Mat.Wood and Mat.Wood or Mat.Metal)
	end
	-- épaules en blocs, bras de gorille, poings énormes
	for _, sx in { -1, 1 } do
		local sh = (torso * CF(sx * 2.05 * s, 0.85 * s, 0)).Position
		chunk(c, V(1.6 * s, 1.35 * s, 1.6 * s), CF(sh) * ANG(0, rad(sx * 12), rad(sx * 8)), col, mat, cap, dark)
		local el = sh + V(sx * 0.25 * s, -1.6 * s, -0.2 * s)
		limb(c, sh, el, 1.0 * s, nil, col, mat)
		local wr = el + V(0, -1.3 * s, -0.4 * s)
		limb(c, el, wr, 1.15 * s, nil, col, mat)
		chunk(c, V(1.45 * s, 1.35 * s, 1.45 * s), CF(wr + V(0, -0.45 * s, 0)), dark, mat)
	end
	-- tête enfoncée entre les épaules, arcade, yeux
	local head = torso * CF(0, 1.95 * s, -0.4 * s)
	chunk(c, V(1.45 * s, 1.1 * s, 1.3 * s), head, col, mat, cap)
	part(c, V(1.55 * s, 0.3 * s, 0.4 * s), head * CF(0, 0.22 * s, -0.55 * s), dark, mat)
	eyes(c, head * CF(0, -0.05 * s, -0.67 * s), 0.34 * s, 0.26 * s, glow)
	if sp.couronne_arbre then
		local leaf = leafColor(o, C, f)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			local p = (torso * CF(math.cos(a) * 1.2 * s, 2.6 * s + (i % 2) * 0.4 * s, math.sin(a) * 0.8 * s)).Position
			limb(c, (torso * CF(math.cos(a) * 0.6 * s, 1.5 * s, math.sin(a) * 0.4 * s)).Position, p, 0.32 * s, nil, WOOD, Mat.Wood)
			chunk(c, V(1.3 * s, 0.95 * s, 1.3 * s), CF(p + V(0, 0.4 * s, 0)), leaf, Mat.Grass)
		end
		if (o.scale or 1) > 1.5 then
			for i = 0, 7 do
				local a = i / 8 * math.pi * 2
				part(c, V(0.24 * s, 1.4 * s, 0.24 * s), torso * CF(math.cos(a) * 1.7 * s, 0.4 * s, math.sin(a) * 1.1 * s) * ANG(math.sin(a) * 0.7, 0, math.cos(a) * 0.7), C.R or WOOD, Mat.Wood, "wedge")
			end
			for i = 0, 2 do
				part(c, V(0.4 * s, 0.3 * s, 0.4 * s), CF((torso * CF((i - 1) * 1.0 * s, 1.5 * s, -0.95 * s)).Position), glow, Mat.Neon)
			end
		end
	end
	if sp.cristaux then
		for i = -1, 1 do
			crystal(c, (torso * CF(i * 0.9 * s, 1.3 * s, 0.6 * s)).Position, (1.1 + (1 - math.abs(i)) * 0.6) * s, 0.42 * s, ANG(rad(20), 0, rad(-i * 20)), col, glow)
		end
	elseif sp.rochers then
		for i = -1, 1 do
			chunk(c, V(1.0 * s, 0.9 * s, 1.0 * s), torso * CF(i * 1.0 * s, 1.55 * s, 0.7 * s) * ANG(rad(15), rad(i * 25), 0), dark, mat)
		end
	elseif sp.coulures then
		for i = 1, 6 do
			local len = (0.7 + 0.4 * (i % 3)) * s
			part(c, V(0.28 * s, len, 0.28 * s), torso * CF((i - 3.5) * 0.5 * s, -1.3 * s - len / 2, -0.9 * s), col2, Mat.Mud)
		end
	elseif sp.glyphes then
		for i = 0, 2 do
			part(c, V(3.55 * s, 0.16 * s, 2.2 * s), torso * CF(0, -0.9 * s + i * 0.7 * s, 0), glow, Mat.Neon)
		end
	elseif sp.pics then
		for _, sx in { -1, 1 } do
			for i = 0, 1 do
				part(c, V(0.4 * s, 1.1 * s, 0.6 * s), torso * CF(sx * (1.8 + i * 0.5) * s, 1.8 * s, (i - 0.5) * 0.5 * s) * ANG(0, 0, rad(-sx * 25)), dark, mat, "wedge")
			end
		end
	elseif sp.branches then
		for _, sx in { -1, 1 } do
			local a = (torso * CF(sx * 1.9 * s, 1.4 * s, 0.2 * s)).Position
			local b = a + V(sx * 0.5 * s, 1.2 * s, 0.2 * s)
			limb(c, a, b, 0.24 * s, nil, WOOD, Mat.Wood)
			part(c, V(0.8 * s, 0.6 * s, 0.8 * s), CF(b + V(0, 0.3 * s, 0)), f.accent or col2, Mat.Grass)
		end
	end
	backDeco(c, f, (torso * CF(-0.6 * s, 1.5 * s, 0.5 * s)).Position, (torso * CF(0.6 * s, 1.4 * s, 0.6 * s)).Position, 2.6 * s, s, 3)
	return body
end

-- Spectres : robe en étages, capuche vide, mains lumineuses, aura
function F.spectre(c, o, f, k, sp, C)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.W, C[o[2]] or C.BL
	local glow = (k.night or f.deco == "spectre") and FAM.nuit.glow or f.glow
	local robe = chunk(c, V(2.3 * s, 1.3 * s, 1.5 * s), CF(0, 1.9 * s, 0), col, Mat.Fabric)
	chunk(c, V(1.95 * s, 1.4 * s, 1.3 * s), CF(0, 3.1 * s, 0), col, Mat.Fabric)
	chunk(c, V(2.3 * s, 1.0 * s, 1.35 * s), CF(0, 4.15 * s, 0), col, Mat.Fabric)
	-- bas de robe en lambeaux
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local len = (0.45 + 0.55 * math.abs(math.sin(i * 1.9))) * s
		part(c, V(0.3 * s, len, 0.3 * s), CF(math.cos(a) * 1.0 * s, 1.3 * s - len / 2, math.sin(a) * 0.62 * s), col, Mat.Fabric)
	end
	local trait = sp.trait
	local tall = trait == "sansvisage" and 1.25 or 1
	local head = CF(0, 5.25 * s * tall, sp.voute and -0.6 * s or 0) * (sp.voute and ANG(rad(-25), 0, 0) or CFrame.identity)
	chunk(c, V(1.5 * s, 1.5 * s * tall, 1.5 * s), head, col, Mat.Fabric)
	if trait == "sansvisage" then
		-- un visage lisse et pâle, rien d'autre
		part(c, V(1.0 * s, 1.15 * s, 0.12), head * CF(0, -0.05 * s, -0.72 * s), BONE, Mat.SmoothPlastic)
		limb(c, V(0, 4.6 * s, 0), V(0, 5.0 * s * tall, 0), 0.8 * s, nil, col, Mat.Fabric)
	elseif trait == "masque" then
		part(c, V(1.05 * s, 1.1 * s, 0.14), head * CF(0, -0.05 * s, -0.73 * s), BONE, Mat.SmoothPlastic)
		eyes(c, head * CF(0, 0.1 * s, -0.81 * s), 0.25 * s, 0.2 * s, glow)
		part(c, V(0.12 * s, 0.5 * s, 0.06), head * CF(0.25 * s, 0.35 * s, -0.81 * s), BLACK, Mat.SmoothPlastic)
	else
		part(c, V(1.05 * s, 1.0 * s, 0.12), head * CF(0, -0.05 * s, -0.72 * s), BLACK, Mat.SmoothPlastic)
		eyes(c, head * CF(0, 0.08 * s, -0.79 * s), 0.25 * s, 0.2 * s, glow)
	end
	if trait == "ramure" then
		for _, sx in { -1, 1 } do
			local a = (head * CF(sx * 0.45 * s, 0.6 * s, 0.1 * s)).Position
			local b = a + V(sx * 0.6 * s, 1.0 * s, 0.2 * s)
			limb(c, a, b, 0.16 * s, nil, WOOD, Mat.Wood)
			limb(c, b, b + V(sx * 0.4 * s, 0.6 * s, -0.1 * s), 0.12 * s, nil, WOOD, Mat.Wood)
			limb(c, b, b + V(-sx * 0.05, 0.6 * s, -0.4 * s), 0.1 * s, nil, WOOD, Mat.Wood)
			if sp.feuilles then
				part(c, V(0.6 * s, 0.4 * s, 0.6 * s), CF(b + V(sx * 0.4 * s, 0.7 * s, -0.1 * s)), col2, Mat.Grass)
			end
		end
	elseif trait == "givre" then
		for i = -1, 1 do
			crystal(c, (head * CF(i * 0.45 * s, 0.6 * s, 0)).Position, (0.7 + (1 - math.abs(i)) * 0.4) * s, 0.24 * s, ANG(0, 0, rad(-i * 18)), col2, glow)
		end
	elseif trait == "chevelure" then
		for i = -2, 2 do
			part(c, V(0.28 * s, 2.6 * s, 0.2 * s), head * CF(i * 0.3 * s, -0.9 * s, 0.6 * s) * ANG(rad(8), 0, rad(i * 5)), col2, Mat.Fabric)
		end
	elseif trait == "chaines" then
		for _, sx in { -1, 1 } do
			for i = 0, 3 do
				part(c, V(0.3 * s, 0.14 * s, 0.3 * s), CF(sx * (1.35 * s - i * 0.12 * s), 3.9 * s - i * 0.45 * s, 0.2 * s) * ANG(0, rad(i * 90), rad(sx * 30)), METAL, Mat.Metal)
			end
		end
	elseif trait == "voiles" then
		for i = 0, 2 do
			part(c, V(2.4 * s, 0.24 * s, 1.55 * s), CF(0, 2.6 * s + i * 0.75 * s, 0) * ANG(0, 0, rad(i % 2 == 0 and 9 or -9)), col2, Mat.Fabric)
		end
	elseif trait == "algues" or trait == "gouttes" then
		for i = 1, 5 do
			local a = i / 5 * math.pi * 2
			local len = (trait == "algues" and 1.6 or 0.6) * s
			local p = part(c, V(0.16 * s, len, 0.16 * s), CF(math.cos(a) * 1.0 * s, 4.2 * s - len / 2, math.sin(a) * 0.7 * s), trait == "algues" and col2 or glow, trait == "algues" and Mat.Fabric or Mat.Neon)
			p.Transparency = trait == "gouttes" and 0.3 or 0
		end
	elseif trait == "lanterne" then
		local l = CF(-1.6 * s, 2.8 * s, -1.0 * s)
		limb(c, V(-1.5 * s, 3.4 * s, -0.9 * s), V(-1.6 * s, 3.05 * s, -1.0 * s), 0.08 * s, nil, METAL, Mat.Metal)
		part(c, V(0.55 * s, 0.7 * s, 0.55 * s), l, METAL, Mat.Metal)
		part(c, V(0.38 * s, 0.48 * s, 0.38 * s), l, glow, Mat.Neon)
	end
	for _, sx in { -1, 1 } do
		local sh = V(sx * 1.15 * s, 4.35 * s, 0)
		local wr = sh + V(sx * 0.4 * s, -1.0 * s, -1.0 * s)
		limb(c, sh, wr, 0.6 * s, nil, col, Mat.Fabric)
		local hand = part(c, V(0.5 * s, 0.5 * s, 0.6 * s), CF(wr + V(0, -0.1 * s, -0.25 * s)), glow, Mat.Neon)
		hand.Transparency = 0.2
		for i = -1, 1 do
			part(c, V(0.1 * s, 0.1 * s, 0.4 * s), CF(wr + V(i * 0.15 * s, -0.2 * s, -0.6 * s)) * ANG(rad(-25), 0, 0), glow, Mat.Neon).Transparency = 0.2
		end
	end
	if sp.baton then
		part(c, V(0.2 * s, 5.6 * s, 0.2 * s), CF(1.7 * s, 2.6 * s, -1.0 * s) * ANG(rad(-6), 0, 0), WOOD, Mat.Wood)
		part(c, V(0.5 * s, 0.25 * s, 0.25 * s), CF(1.7 * s, 5.3 * s, -1.25 * s), WOOD, Mat.Wood)
	end
	local aura = part(c, V(2.6 * s, 4.2 * s, 1.8 * s), CF(0, 3.3 * s, 0.1 * s), col2, Mat.ForceField)
	aura.CastShadow = false
	if sp.eclairs then
		for i = 1, 3 do
			local p = V((i - 2) * 0.9 * s, 3 * s, 0.75 * s)
			part(c, V(0.12 * s, 0.9 * s, 0.1), CF(p) * ANG(0, 0, rad(25)), glow, Mat.Neon)
			part(c, V(0.12 * s, 0.9 * s, 0.1), CF(p + V(0.2 * s, -0.75 * s, 0)) * ANG(0, 0, rad(-25)), glow, Mat.Neon)
		end
	end
	if o.couronne then
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			part(c, V(0.26 * s, 0.6 * s, 0.26 * s), head * CF(math.cos(a) * 0.6 * s, 0.95 * s, math.sin(a) * 0.6 * s), C.O or METAL, Mat.Metal)
		end
		part(c, V(1.4 * s, 0.2 * s, 1.4 * s), head * CF(0, 0.7 * s, 0), C.O or METAL, Mat.Metal)
	end
	if o.helmet then
		chunk(c, V(1.62 * s, 1.0 * s, 1.62 * s), head * CF(0, 0.3 * s, 0), METAL, Mat.Metal)
	end
	if o.weapon then
		weapon(c, o.weapon, V(1.55 * s, 3.2 * s, -1.2 * s), s, glow, darken(col, 0.5))
	end
	for _, p in c.m:GetChildren() do
		if p:IsA("BasePart") and p.Material == Mat.Fabric then
			p.Transparency = 0.25
		end
	end
	return robe
end

-- Masses : sangsues, ombres rampantes, méduses, hommes-boue, Roi des marais
function F.masse(c, o, f, k, sp, C, _, id)
	local s = o.scale or 1
	local col, col2 = C[o[1]] or C.BF, C[o[2]] or C.Y
	local glow = f.glow
	if o.long then
		local pts, widths = {}, {}
		for i = 0, 6 do
			table.insert(pts, V(math.sin(i * 0.7) * 0.4, 0.55, i * 0.75))
			table.insert(widths, 1.2 - i * 0.1)
		end
		local body = chain(c, pts, widths, { col, darken(col, 0.25) }, Mat.SmoothPlastic, col2)
		local mouth = CF(pts[1] + V(0, 0, -0.55))
		eyes(c, CF(pts[1] + V(0, 0.42, -0.45)), 0.3, 0.14, glow)
		part(c, V(0.95, 0.95, 0.2), mouth, darken(col2, 0.5), Mat.SmoothPlastic)
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			part(c, V(0.12, 0.3, 0.12), mouth * CF(math.cos(a) * 0.32, math.sin(a) * 0.32, -0.12) * ANG(rad(-70), 0, 0), BONE, Mat.SmoothPlastic)
		end
		if k.night then
			for i = 2, 6, 2 do
				part(c, V(0.2, 0.2, 0.2), CF(pts[i] + V(0, 0.55, 0)), glow, Mat.Neon)
			end
			for _, p in c.m:GetChildren() do
				if p:IsA("BasePart") and p.Material ~= Mat.Neon then
					p.Transparency = 0.3
				end
			end
		end
		return body
	end
	if id == "freshwater_jellyfish" then
		local bell = chunk(c, V(2.0, 1.2, 2.0), CF(0, 2.6, 0), col, Mat.Glass, BONE)
		bell.Transparency = 0.3
		part(c, V(1.2, 0.5, 1.2), CF(0, 2.2, 0), glow, Mat.Neon).Transparency = 0.25
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			local len = 1.3 + (i % 2) * 0.5
			part(c, V(0.14, len, 0.14), CF(math.cos(a) * 0.65, 1.95 - len / 2, math.sin(a) * 0.65), col2, Mat.Neon).Transparency = 0.35
		end
		eyes(c, CF(0, 2.65, -1.02), 0.32, 0.16, glow)
		return bell
	end
	-- tas qui se dresse : trois étages, bras de boue, coulures
	local mud = (o[1] == "BF" or o[1] == "V") and Mat.Mud or Mat.SmoothPlastic
	local body = chunk(c, V(2.8 * s, 1.6 * s, 2.6 * s), CF(0, 0.85 * s, 0), col, mud, f.accent, darken(col, 0.3))
	chunk(c, V(2.2 * s, 1.5 * s, 2.0 * s), CF(0, 2.25 * s, 0), col, mud, f.accent)
	local head = CF(0, 3.5 * s, -0.15 * s)
	chunk(c, V(1.7 * s, 1.3 * s, 1.6 * s), head, col, mud, f.accent)
	eyes(c, head * CF(0, 0.1 * s, -0.81 * s), 0.38 * s, 0.26 * s, glow, darken(col, 0.3))
	if sp.gouffre then
		part(c, V(1.3 * s, 1.0 * s, 0.1 * s), CF(0, 2.2 * s, -1.02 * s), BLACK, Mat.SmoothPlastic)
		teeth(c, CF(0, 2.7 * s, -1.06 * s), 1.2 * s, 5, 0.35 * s)
		for i = 1, 5 do
			local a = i / 5 * math.pi * 2
			part(c, V(0.3 * s, 0.9 * s, 0.3 * s), CF(math.cos(a) * 0.8 * s, 4.3 * s, math.sin(a) * 0.7 * s) * ANG(math.sin(a) * 0.5, 0, math.cos(a) * 0.5), col2, Mat.SmoothPlastic, "wedge")
		end
	else
		part(c, V(0.9 * s, 0.25 * s, 0.1 * s), head * CF(0, -0.35 * s, -0.81 * s), darken(col2, 0.5), Mat.SmoothPlastic)
	end
	for _, sx in { -1, 1 } do
		local sh = V(sx * 1.05 * s, 2.6 * s, -0.1 * s)
		local el = sh + V(sx * 0.6 * s, -0.7 * s, -0.4 * s)
		limb(c, sh, el, 0.75 * s, nil, col, mud)
		limb(c, el, el + V(sx * 0.1 * s, -0.95 * s, -0.2 * s), 0.65 * s, nil, col, mud)
	end
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2 + 0.4
		local len = (0.5 + 0.3 * (i % 2)) * s
		part(c, V(0.3 * s, len, 0.3 * s), CF(math.cos(a) * 1.0 * s, 3.0 * s - len / 2, math.sin(a) * 0.95 * s), f.accent or col2, mud)
	end
	if o.couronne then
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			part(c, V(0.3 * s, 0.65 * s, 0.3 * s), head * CF(math.cos(a) * 0.62 * s, 0.95 * s, math.sin(a) * 0.62 * s), C.O or METAL, Mat.Metal)
		end
		part(c, V(1.5 * s, 0.22 * s, 1.5 * s), head * CF(0, 0.7 * s, 0), C.O or METAL, Mat.Metal)
		for _, sx in { -1, 1 } do
			part(c, V(1.0 * s, 0.1 * s, 1.0 * s), CF(sx * 1.2 * s, 1.7 * s, 0.5 * s) * ANG(0, rad(30), rad(sx * 12)), f.accent or C.V, Mat.Grass)
		end
	end
	return body
end

-- ------------------------------------------------------------------ Entrée

-- Construit la silhouette de `id` dans `m` (qui contient déjà « Base »). Retourne la pièce du corps et
-- le nombre de pièces posées. fam = nom de famille (FAM) ; C = palette du bestiaire.
function Silhouettes.build(m: Model, id: string, k, fam: string, C, SKIN: Color3)
	local f = FAM[fam] or FAM.prairie
	local o = k.look or {}
	local c = newCtx(m, id)
	local builder = F[k.form]
	if not builder then
		return nil, 0
	end
	local sp = SP[id] or {}
	if sp.taille then
		o = table.clone(o)
		o.scale = (o.scale or 1) * sp.taille
	end
	local body = builder(c, o, f, k, sp, C, SKIN, id)
	-- les petits volants sont sculptés à taille fixe : la taille d'espèce s'applique au modèle entier
	if sp.taille and k.form == "volant" and body then
		m:ScaleTo(sp.taille)
	end
	return body, c.n
end

Silhouettes.FORMS = F

return Silhouettes
