-- L’atlas reste vide jusqu’à sa publication par le propriétaire dans Roblox.
local M = {
	asset = "",
	taille = 1254,
}
local cells = {
	"menu:sac", "menu:perso", "menu:talents", "menu:quetes",
	"menu:carte", "menu:clan", "menu:atelier", "menu:parametres",
	"axe", "pickaxe", "rod", "harpoon",
	"wood", "stone", "rope", "wheat",
}
M.cellules = {}
for i, id in cells do
	M.cellules[id] = Vector2.new((i - 1) % 4, math.floor((i - 1) / 4))
end

function M.add(id, parent, size, z, dim)
	local cell = M.cellules[id]
	if not cell or M.asset == "" then return false end
	local edge = M.taille / 4
	local function pixel(n) return math.floor(n * edge + 0.5) end
	local x, y = pixel(cell.X), pixel(cell.Y)
	local image = Instance.new("ImageLabel")
	image.Name = "IconePeinte"
	image.BackgroundTransparency = 1
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = size
	image.ScaleType = Enum.ScaleType.Fit
	image.ZIndex = z
	image.Image = M.asset
	image.ImageRectOffset = Vector2.new(x, y)
	image.ImageRectSize = Vector2.new(pixel(cell.X + 1) - x, pixel(cell.Y + 1) - y)
	if dim then image.ImageTransparency = 0.46 end
	image.Parent = parent
	return true
end

return M
