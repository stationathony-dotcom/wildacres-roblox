-- Banc de la magie (27/11, Systemes/Magie + Equilibre E.SORTS) en mode Edit, faux G :
-- grimoires fabricables, sort appris une fois, refus sans le connaître, endurance, recharge, dégâts / gel / soin / armure.
local f = game.ReplicatedStorage.Shared:Clone()
f.Name = "BancMagie"
f.Parent = game.ServerStorage
local ms = game.ServerScriptService.Systemes.Magie:Clone()
ms.Parent = f
local Config = require(f.Config)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
-- grimoires dans le catalogue
local n = 0
for _, r in Config.RECIPES do
	if r.item and string.sub(r.item, 1, 9) == "grimoire_" then
		n += 1
	end
end
check("grimoires fabricables (" .. n .. ")", n >= 4)
check("grimoire lisible (usage « grimoire »)", Config.ITEMS.grimoire_boule_feu ~= nil and Config.ITEMS.grimoire_boule_feu.use == "cat_grimoire")

local M = require(ms)
-- faux monde
local prof = { stats = {} }
local actions = {}
local hum = Instance.new("Humanoid")
hum.MaxHealth, hum.Health = 100, 40
local player = { Name = "Mage", UserId = 1, Character = { FindFirstChildOfClass = function() return hum end } }
local attrs = { Stamina = 100 }
function player:GetAttribute(k) return attrs[k] end
function player:SetAttribute(k, v) attrs[k] = v end
local root = { Position = Vector3.new(0, 3, 0), CFrame = CFrame.new(0, 3, 0) }
local en = { id = "e1", pos = Vector3.new(0, 3, -10), hp = 200, invuln = 0 }
local hits = {}
local G = {
	world = { day = 2 },
	Equilibre = require(f.Equilibre),
	Joueurs = { get = function() return prof end, markDirty = function() end, sync = function() end,
		stats = function() return { force = 5, chance = 3, vie = 2, vitesse = 1, defense = 4 } end, addStatXp = function() end },
	Util = { toast = function() end, root = function() return root end, geste = function() end },
	Enemies = { list = { en }, byId = function(id) return id == "e1" and en or nil end,
		hit = function(e, d) table.insert(hits, d) e.hp -= d end },
	Combat = { spendStamina = function(_, c) if attrs.Stamina < c then return false end attrs.Stamina -= c return true end },
	Game = { players = function() return { player } end },
	Interact = { onAction = function(k, fn) actions[k] = fn end },
	remotes = { Menu = { FireClient = function() end } },
}
M.init(G)
local ok0, msg0 = M.cast(player, "boule_feu", "e1")
check("sans le grimoire : refusé", not ok0 and msg0 ~= nil)
check("grimoire lu : sort appris", M.learn(player, "boule_feu") == true and prof.sorts.boule_feu ~= nil)
check("grimoire relu : pas appris deux fois", M.learn(player, "boule_feu") == false)
local ok1 = M.cast(player, "boule_feu", "e1")
check("boule de feu : 30 + 2 × Force 5 = 40 dégâts", ok1 and hits[1] == 40 and attrs.Stamina == 75)
check("recharge : relancer tout de suite échoue", not M.cast(player, "boule_feu", "e1"))
M.learn(player, "trait_givre")
check("trait de givre : la cible est ralentie", M.cast(player, "trait_givre", "e1") and en.slowUntil ~= nil and en.slowUntil > os.clock())
M.learn(player, "souffle_vie")
check("souffle de vie : soigne 35 + 2 × Vie 2", M.cast(player, "souffle_vie") and hum.Health == 79)
M.learn(player, "peau_pierre")
attrs.Stamina = 100
check("peau de pierre : dégâts subis × 0,5", M.cast(player, "peau_pierre") and M.damageMult(player) == 0.5)
attrs.Stamina = 5
M.learn(player, "bourrasque")
local okB, msgB = M.cast(player, "bourrasque")
check("sans endurance : refusé", not okB and msgB ~= nil)
check("liste des sorts connus (5)", #M.list(player) == 5)
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
