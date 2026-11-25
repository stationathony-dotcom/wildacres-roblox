-- Banc de la végétation colorée (chantier D, 25/11) — mode Edit.
-- D1 au moins 4 teintes d'arbres feuillus différentes sur 40 arbres, par biome (prairie, forêt, désert, marais, neige)
-- D1b le même arbre garde sa teinte ; un second seasonize ne la fait pas dériver
-- D1c les cerisiers (feuillage rose) restent roses ; le haut d'une frondaison est plus clair que le bas
local CS = game:GetService("CollectionService")
local Clock = require(game.ServerScriptService.Systemes.Clock:Clone())
local fails = {}
local biome = "prairie"
Clock.biomeAt = function()
	return biome
end

local function tree(x, z, color, caduc)
	local m = Instance.new("Model")
	local base = Instance.new("Part")
	base.Size = Vector3.new(1, 6, 1)
	base.CFrame = CFrame.new(x, 3, z)
	base.Parent = m
	m.PrimaryPart = base
	for i, y in { 8, 10.5, 13 } do
		local p = Instance.new("Part")
		p.Size = Vector3.new(6 - i, 2.5, 6 - i)
		p.CFrame = CFrame.new(x, y, z)
		p.Color = color
		p.Parent = m
		CS:AddTag(p, "Feuillage")
		p:SetAttribute("Caduc", caduc)
		p:SetAttribute("CouleurPrintemps", color)
	end
	return m
end
local function lum(c)
	return c.R + c.G + c.B
end
local function topColor(m)
	local best, by = nil, -1e9
	for _, p in m:GetChildren() do
		if CS:HasTag(p, "Feuillage") and p.Position.Y > by then
			best, by = p, p.Position.Y
		end
	end
	return best.Color, best
end

local OAK = Color3.fromRGB(88, 152, 62)
for _, b in { "prairie", "foret", "desert", "marais", "neige" } do
	biome = b
	local seen, n = {}, 0
	for i = 1, 40 do
		local m = tree(i * 37.3, i * -21.9, OAK, true)
		Clock.seasonize(m)
		local c = m:GetChildren()[3].Color -- bloc du milieu
		local key = c:ToHex()
		if not seen[key] then
			seen[key] = true
			n += 1
		end
		if i == 1 then
			local before = topColor(m)
			Clock.seasonize(m)
			local after = topColor(m)
			if before:ToHex() ~= after:ToHex() then
				table.insert(fails, "D1b " .. b .. " : la teinte dérive au 2e appel")
			end
			local again = tree(i * 37.3, i * -21.9, OAK, true)
			Clock.seasonize(again)
			if topColor(again):ToHex() ~= after:ToHex() then
				table.insert(fails, "D1b " .. b .. " : même arbre, autre teinte")
			end
			local lowest
			for _, p in m:GetChildren() do
				if CS:HasTag(p, "Feuillage") and (not lowest or p.Position.Y < lowest.Position.Y) then
					lowest = p
				end
			end
			if lum(after) <= lum(lowest.Color) then
				table.insert(fails, "D1c " .. b .. " : le haut n'est pas plus clair que le bas")
			end
		end
	end
	if n < 4 then
		table.insert(fails, string.format("D1 %s : %d teinte(s) seulement", b, n))
	end
	local cherry = tree(500, 500, Color3.fromRGB(236, 160, 190), true)
	Clock.seasonize(cherry)
	local c = topColor(cherry)
	if not (c.R > c.G) then
		table.insert(fails, "D1c " .. b .. " : le cerisier perd son rose")
	end
end
if #fails == 0 then
	return "vegetation OK : 5 biomes, ≥ 4 teintes chacun, teintes stables, cerisiers roses"
end
return "ÉCHEC vegetation : " .. #fails .. " problème(s)\n" .. table.concat(fails, "\n")
