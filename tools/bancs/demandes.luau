-- Banc Edit : commerce entre régions (Shop.wanted / sellPrice), G simulé.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local Config = require(f.Config)
local WG = require(f.WorldGen)
local D = require(f.Dialogue)
local mod = game.ServerScriptService.Systemes.Shop:Clone()
local Shop = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local village = { key = "2,3", name = "Valdor", biome = "prairie" }
local G = {
	Config = Config, WG = WG, Dialogue = D,
	world = { day = 9, seed = 13 },
	Interact = { onAction = function() end, onPrompt = function() end },
	Herbes = { POOLS = { prairie = { { "chamomile" } }, desert = { { "lavender" } }, marais = { { "nettle" } } } },
	Reputation = { villageAt = function() return village end, priceMult = function() return 1, 1 end },
	Clock = { biomeAt = function() return "prairie" end },
	Joueurs = {
		get = function() return { honor = 0, inv = {} } end,
		stats = function() return {} end, talent = function() return 0 end, skill = function() return 0 end,
		has = function() return false end,
	},
	Evenements = { priceBonus = function() return 1 end },
	Npcs = { op = function() return 0 end },
	Metiers = { soldItems = function() return {} end },
}
pcall(Shop.init, G)

local w = Shop.wanted("2,3", "prairie")
check("3 produits recherchés", #w.list == 3)
local own = false
for _, id in w.list do
	local crop = Config.CROPS[id]
	if (crop and table.find(crop.biomes, "prairie")) or id == "chamomile" then
		own = true
	end
end
check("jamais un produit du biome du village", not own)
check("même liste pour tout le monde (déterministe)", table.concat(Shop.wanted("2,3", "prairie").list, ",") == table.concat(w.list, ","))
local changed = false
for d = 12, 40, 3 do
	G.world.day = d
	if table.concat(Shop.wanted("2,3", "prairie").list, ",") ~= table.concat(w.list, ",") then
		changed = true
	end
end
check("la demande change avec les jours", changed)
G.world.day = 9
check("un autre village demande autre chose", table.concat(Shop.wanted("5,1", "prairie").list, ",") ~= table.concat(w.list, ","))

-- prix : un produit recherché se vend plus cher qu'un produit ordinaire de même valeur
local e = { data = { persona = "jovial", role = "merchant" }, reg = { key = "2,3" }, root = { Position = Vector3.zero } }
local wantedItem = w.list[1]
local P = {}
local pw = Shop.sellPrice(P, e, wantedItem)
Shop.WANTED_MULT = 1
local pn = Shop.sellPrice(P, e, wantedItem)
Shop.WANTED_MULT = 1.5
check(string.format("recherché payé plus cher (%d contre %d sans demande)", pw, pn), pw > pn)

mod:Destroy()
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
