local Fiche = {}

function Fiche.etat(config, recipe, inventory, stations, count)
	local ingredients = {}
	local missing = false
	for id, quantity in recipe.needs do
		local owned = 0
		for _, member in config.ITEM_GROUPS[id] or {id} do
			owned += inventory.inv[member] or 0
		end
		local need = quantity * count
		table.insert(ingredients, { name = config.needInfo(id).name, have = owned, need = need })
		missing = missing or owned < need
	end
	table.sort(ingredients, function(a, b) return a.name < b.name end)
	local station = recipe.station and config.STATIONS[recipe.station]
	local stationOK = not station or stations[recipe.station] == true
	local skillId, level, current, skillOK
	if recipe.skill then
		skillId, level = recipe.skill[1], recipe.skill[2]
		current = config.skillLevel((inventory.skills or {})[skillId] or 0)
		skillOK = current >= level
	else
		skillOK = true
	end
	return {
		ingredients = ingredients, missing = missing, station = station, stationOK = stationOK,
		skill = config.SKILLS[skillId], current = current, level = level, skillOK = skillOK,
		ready = not missing and stationOK and skillOK,
	}
end

return Fiche
