-- Clic avec un outil en main : répartit vers le bon système.

local Tools = {}
local G

function Tools.init(g)
	G = g
end

function Tools.use(player: Player, tool: Tool)
	if not G.Game.isPlaying(player) then
		return
	end
	local full = tool:GetAttribute("ItemId")
	local id = full and G.Config.baseOf(full) or full
	local seed = tool:GetAttribute("Seed")
	if seed then
		G.Farm.plant(player, seed)
	elseif id == "hoe" then
		G.Farm.till(player)
	elseif id == "can" then
		G.Farm.water(player)
	elseif id == "axe" or id == "pickaxe" then
		if not G.Props.toolHit(player, id) and not G.Batir.smash(player, id) and not G.Demolir.smash(player, id) then
			G.Combat.attack(player, full)
		end
	elseif id == "shovel" then
		if not G.Bodies.shovel(player) and not G.Props.toolHit(player, id) then
			G.Farm.dig(player)
		end
	elseif id == "rod" then
		G.Fishing.use(player)
	elseif id == "spade" then
		G.Terraforme.use(player)
	elseif id == "club" or id == "sword" then
		G.Combat.attack(player, full)
	end
end

return Tools
