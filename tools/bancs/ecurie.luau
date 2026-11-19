-- Banc Edit : écurie et lignées (Systemes/Horses : allure, swap, breed, describe), G simulé.
local mod = game.ServerScriptService.Systemes.Horses:Clone()
local Hs = require(mod)
local Config = require(game.ReplicatedStorage.Shared.Config)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local prof = { stats = {} }
local bag = { gold = 1000, carrot = 20 }
local toasts = {}
local P = {}
local nid = 0
local G = {
	Config = Config,
	world = { day = 10, id = "w1" },
	Interact = { onPrompt = function() end, onAction = function() end },
	Joueurs = {
		get = function() return prof end,
		take = function(_, i, n) if (bag[i] or 0) < n then return false end bag[i] -= n return true end,
		count = function(_, i) return bag[i] or 0 end,
		add = function(_, i, n) bag[i] = (bag[i] or 0) + n end,
		skill = function() return 20 end,
		addSkillXp = function() end, markDirty = function() end, sync = function() end,
	},
	Util = {
		toast = function(_, t) table.insert(toasts, t) end,
		clone = function() return nil end, -- pas de modèle en banc
		pid = function() return "u1" end,
		newId = function(p) nid += 1 return p .. nid end,
	},
	World = { regionAt = function() return { key = "0,0" } end },
}
Hs.init(G)

-- allure : déterministe, dans les bornes
local a1, a2 = Hs.allureOf({ id = "abc" }), Hs.allureOf({ id = "abc" })
check("allure déterministe par identifiant", a1 == a2)
local lo, hi = 9, 0
for i = 1, 500 do
	local a = Hs.allureOf({ id = "h" .. i })
	lo, hi = math.min(lo, a), math.max(hi, a)
end
check(string.format("allures sauvages entre 0,90 et 1,10 (%.2f–%.2f)", lo, hi), lo >= 0.9 and hi <= 1.1)
check("allure enregistrée prioritaire", Hs.allureOf({ id = "x", allure = 1.2 }) == 1.2)

-- espèces des petits
check("cheval × cheval = cheval", Hs.childSpecies("cheval", "cheval") == "cheval")
check("cheval × âne = mulet", Hs.childSpecies("cheval", "ane") == "mulet")
check("mulet stérile", Hs.childSpecies("mulet", "cheval") == nil)

-- poulinage
prof.horse = { id = "A", species = "cheval", coat = 1, allure = 1.10 }
check("sans autre monture : pas de poulain", Hs.breed(P) == false)
prof.stable = { { id = "B", species = "cheval", coat = 2, allure = 1.06 } }
local g0, c0 = bag.gold, bag.carrot
check("poulinage réussi", Hs.breed(P) == true)
local foal = prof.stable[2]
check("poulain à l'écurie", foal ~= nil and foal.born == 10 and foal.species == "cheval")
check(string.format("allure héritée proche des parents (%.2f)", foal and foal.allure or 0), foal and foal.allure >= 1.03 and foal.allure <= 1.16)
check("coût : 40 or, 3 carottes", g0 - bag.gold == 40 and c0 - bag.carrot == 3)
check("repos : pas deux poulinages de suite", Hs.breed(P) == false)
G.world.day = 12
check("après repos : à nouveau possible", Hs.breed(P) == true)

-- changer de monture (rotation)
G.world.day = 12
local before = #prof.stable
check("changer de monture", Hs.swap(P, Vector3.new(10, 0, 10)) == true)
check("l'ancienne rejoint l'écurie (rien de perdu)", #prof.stable == before and prof.horse.id == "B" and prof.stable[#prof.stable].id == "A")
for _ = 1, 3 do
	Hs.swap(P, Vector3.new(10, 0, 10))
end
check("rotation complète : retour à A", prof.horse.id == "A")
check("pension prélevée à chaque échange", bag.gold < g0 - 40)

local lines = Hs.describe(P)
check("/ecurie : une ligne par monture", #lines == 1 + #prof.stable)
check("/ecurie : poulain signalé", string.find(table.concat(lines, "\n"), "poulain") ~= nil)

-- mulet issu cheval × âne
prof.horse = { id = "C", species = "ane", coat = 3, allure = 0.95 }
prof.stable = { { id = "D", species = "cheval", coat = 1, allure = 1.0 } }
prof.breedDay = nil
Hs.breed(P)
check("âne × cheval = mulet", prof.stable[2] and prof.stable[2].species == "mulet")
prof.horse = { id = "M", species = "mulet", coat = 1 }
check("un mulet ne pouline pas", Hs.breed(P) == false)

mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
