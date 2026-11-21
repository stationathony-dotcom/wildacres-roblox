-- Les identifiants d'image sont renseignés après publication par le propriétaire.
local M = {}
local atlas = {
	wildAcres = {
		asset = "",
		taille = Vector2.new(1254, 1254),
		x = { 0, 314, 627, 941, 1254 },
		y = { 0, 314, 627, 941, 1254 },
		cellules = {
			"menu:sac", "menu:perso", "menu:talents", "menu:quetes",
			"menu:carte", "menu:clan", "menu:atelier", "menu:parametres",
			"axe", "pickaxe", "rod", "harpoon",
			"wood", "stone", "rope", "wheat",
		},
	},
	structure = {
		asset = "",
		taille = Vector2.new(1246, 1263),
		x = { 0, 314, 625, 935, 1246 },
		y = { 0, 324, 642, 954, 1263 },
		cellules = {
			"bloc:poteaurond", "bloc:demipoutre", "bloc:madrier", "bloc:chevron",
			"bloc:echalas", "bloc:poteausculpte", "bloc:colonnecarree", "bloc:murincline",
			"bloc:colombages", "bloc:clayonnage", "bloc:treillis", "bloc:niche",
			"bloc:fondation", "bloc:pavage", "bloc:pilotis", "bloc:balcon",
		},
	},
	construction = {
		asset = "",
		taille = Vector2.new(1262, 1246),
		x = { 0, 320, 634, 935, 1262 },
		y = { 0, 315, 626, 940, 1246 },
		cellules = {
			"bloc:gouttiere", "bloc:lucarne", "bloc:croisillons", "bloc:volets",
			"bloc:vitrail", "bloc:escalier", "bloc:arche", "bloc:demimur",
			"bloc:colonne", "bloc:barriere", "bridle", "saddle_war",
			"big_table", "garden_bench", "shelf", "rug",
		},
	},
	equipement = {
		asset = "",
		taille = Vector2.new(1263, 1246),
		x = { 0, 316, 623, 945, 1263 },
		y = { 0, 326, 623, 934, 1246 },
		cellules = {
			"sword_fe", "equipement:roundshield", "equipement:helmet", "equipement:mail",
			"equipement:boots", "equipement:gauntlets", "ring_gem", "equipement:torch",
			"equipement:Capuche", "equipement:bow", "equipement:leather", "equipement:hammer",
			"crown", "equipement:cape", "equipement:pike", "saddle_leather",
		},
	},
	matieresMobilier = {
		asset = "",
		taille = Vector2.new(1254, 1254),
		x = { 0, 314, 627, 940, 1254 },
		y = { 0, 314, 627, 920, 1254 },
		cellules = {
			"prise_wolf", "scales", "night_feather", "ice_crystal",
			"claw", "fur", "silk", "ancient_crystal",
			"wall_lantern", "chest", "clay_pot", "banner",
			"bed", "barrel", "chair", "brazier",
		},
	},
	truffe = {
		asset = "",
		taille = Vector2.new(512, 256),
		x = { 0, 256, 512 },
		y = { 0, 256 },
		cellules = { "truffle", "truffle_omelette" },
	},
}

local cellules = {}
local function pixel(source, largeurSource, largeurPubliee)
	return math.floor(source * largeurPubliee / largeurSource + 0.5)
end

for _, planche in atlas do
	local colonnes = #planche.x - 1
	local largeur, hauteur = planche.x[#planche.x], planche.y[#planche.y]
	for i, id in planche.cellules do
		local col, row = (i - 1) % colonnes + 1, math.floor((i - 1) / colonnes) + 1
		local x0 = pixel(planche.x[col], largeur, planche.taille.X)
		local x1 = pixel(planche.x[col + 1], largeur, planche.taille.X)
		local y0 = pixel(planche.y[row], hauteur, planche.taille.Y)
		local y1 = pixel(planche.y[row + 1], hauteur, planche.taille.Y)
		cellules[id] = {
			asset = planche.asset,
			position = Vector2.new(x0, y0),
			taille = Vector2.new(x1 - x0, y1 - y0),
		}
	end
end

function M.image(id, size, dim): ImageLabel?
	local forme = id:match("^blk_([^_]+)_[^_]+$")
	local cellule = cellules[id] or (forme and cellules["bloc:" .. forme])
	if not cellule or cellule.asset == "" then return nil end
	local image = Instance.new("ImageLabel")
	image.Name = "IconePeinte"
	image.BackgroundTransparency = 1
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = size
	image.ScaleType = Enum.ScaleType.Fit
	image.Image = cellule.asset
	image.ImageRectOffset = cellule.position
	image.ImageRectSize = cellule.taille
	if dim then image.ImageTransparency = 0.46 end
	return image
end

function M.add(id, parent, size, z, dim)
	local image = M.image(id, size, dim)
	if not image then return false end
	image.ZIndex, image.Parent = z, parent
	return true
end

return M
