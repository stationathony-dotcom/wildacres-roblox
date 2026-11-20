-- Banc de la pêche au harpon (Fishing.harpoon, 20/11) — mode Edit, G simulé, tirage forcé.
local F = assert(loadstring(game.ServerScriptService.Systemes.Fishing.Source, "Fishing"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end
local bag, toasts, xp = {}, {}, 0
local waterFrom = 5 -- l'eau commence à 5 studs devant
local root = { Position = Vector3.zero, CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(0, 0, -1)) }
local skill = 0
local G = {
	Config = { WATER_Y = 0, FISH = { { name = "Gardon", price = 9, weight = 40 }, { name = "Brochet", price = 36, weight = 12 } } },
	Util = { root = function() return root end, isWater = function(_, z) return -z >= waterFrom end, toast = function(_, t) table.insert(toasts, t) end,
		finds = function() end },
	Props = { swing = function() end },
	Joueurs = { skillRaw = function() return skill end, skill = function() return skill end, stats = function() return { chance = 0 } end,
		addSkillXp = function(_, _, n) xp += n end, add = function(_, i, n) bag[i] = (bag[i] or 0) + n end },
	Social = { collect = function() end, bump = function() end },
	Clock = { biomeAt = function() return "prairie" end },
	Activites = {},
	Interact = { onAction = function() end, onPrompt = function() end },
}
pcall(F.init, G)
local P = {}
F.roll = function() return 0.99 end -- raté
check("lancer dans l'eau à 5 studs : a lieu", F.harpoon(P) == true)
check("raté : pas de poisson, message", next(bag) == nil and toasts[#toasts]:find("Raté") ~= nil)
check("trop tôt (recharge 2,5 s) : refusé", F.harpoon(P) == false)
task.wait(2.6)
F.roll = function() return 0 end -- touché
check("touché : un poisson dans le sac", F.harpoon(P) == true and (bag.fish_1 or 0) + (bag.fish_2 or 0) == 1)
check("de l'XP de pêche", xp > 0)
task.wait(2.6)
waterFrom = 14
check("eau trop loin (14 studs) : pas de lancer", F.harpoon(P) == false and toasts[#toasts]:find("Vise l'eau") ~= nil)
-- chance de toucher : 25 % sans compétence, plafonnée à 70 %
local H = F.HARPOON
check("chance de base 25 %", math.abs(math.min(H.max, H.base) - 0.25) < 1e-9)
skill = 50
check("compétence 50 : plafond 70 %", math.min(H.max, H.base + skill * H.perSkill) == 0.7)
F.roll = math.random
return fails .. " échec(s)\n" .. table.concat(out, "\n")
