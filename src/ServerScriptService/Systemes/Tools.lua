-- Clic avec un outil en main : répartit vers le bon système.

local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Tools = {}
local G

function Tools.init(g)
	G = g
	local models = require(ServerStorage.OutilsDev.ConstruireModelesOutils)
	models.harpon(ServerStorage.Outils)
	models.equipements(ServerStorage.Outils, G.Config)
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local miniatures = require(ServerStorage.OutilsDev.ConstruireModelesMiniatures)
	miniatures.identites(replicatedStorage)
	miniatures.mobilier(replicatedStorage, ServerStorage.Modeles, G.Config)
end

function Tools.use(player: Player, tool: Tool, targetId: string?): boolean
	if not G.Game.isPlaying(player) then
		return false
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
			G.Combat.attack(player, full, targetId)
		end
	elseif id == "shovel" then
		if not G.Bodies.shovel(player) and not G.Props.toolHit(player, id) then
			G.Farm.dig(player)
		end
	elseif id == "rod" then
		G.Fishing.use(player)
	elseif id == "harpoon" then
		if G.Fishing.harpoon(player) then
			G.Props.swing(player, full)
			local grip = tool.Grip
			tool.Grip = grip * CFrame.Angles(math.rad(-28), 0, 0)
			TweenService:Create(tool, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { Grip = grip }):Play()
		end
	elseif id == "spade" then
		G.Terraforme.use(player)
	elseif id == "club" or id == "sword" then
		G.Combat.attack(player, full, targetId)
	else
		return false
	end
	return true
end

return Tools
