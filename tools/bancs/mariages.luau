-- Banc des mariages (27/11, Systemes/Mariages) en mode Edit, faux G.
local m = game.ServerScriptService.Systemes.Mariages:Clone()
m.Parent = game.ServerStorage
local M = require(m)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local profs, bags, pos = {}, {}, {}
local function P(id, name)
	local p = { UserId = id, DisplayName = name, Parent = game }
	profs[p] = { stats = {} }
	bags[p] = {}
	pos[p] = Vector3.new(id * 3, 0, 0)
	return p
end
local A, B, C = P(1, "Alix"), P(2, "Bran"), P(3, "Cyr")
local byId = { [1] = A, [2] = B, [3] = C }
local inVillage = true
local bumps = {}
local G = {
	world = { day = 9 },
	playerById = function(uid) return byId[uid] end,
	Joueurs = { get = function(p) return profs[p] end, markDirty = function() end, sync = function() end,
		count = function(p, i) return bags[p][i] or 0 end,
		take = function(p, i, n) if (bags[p][i] or 0) < n then return false end bags[p][i] -= n return true end,
		add = function(p, i, n) bags[p][i] = (bags[p][i] or 0) + n end },
	Util = { root = function(p) return { Position = pos[p] } end, toast = function() end },
	Quetes = { nearVillage = function() return inVillage and { key = "V" } or nil end },
	remotes = { Menu = { FireClient = function() end } },
	Social = { bump = function(p, s) bumps[p.DisplayName .. s] = true end },
	Game = { players = function() return { A, B, C } end },
	Interact = { onAction = function() end },
}
M.init(G)
check("sans bague : refus", not M.ask(A, 2))
bags[A].ring_gem = 1
inVillage = false
check("hors du village : refus", not M.ask(A, 2))
inVillage = true
check("demande faite au village, bague en main", M.ask(A, 2))
check("un autre ne peut pas répondre à sa place", not M.accept(C))
check("Bran dit oui", M.accept(B))
check("mariés des deux côtés, bague donnée", profs[A].conjoint.uid == "2" and profs[B].conjoint.uid == "1" and bags[B].ring_gem == 1 and bags[A].ring_gem == 0)
check("titre « Uni pour la vie » compté", bumps.Alixmaries and bumps.Branmaries)
check("côte à côte : +10 % d'expérience", M.bonus(A) == 1.1)
pos[B] = Vector3.new(500, 0, 0)
check("loin l'un de l'autre : pas de bonus", M.bonus(A) == 1)
bags[C].ring_gem = 1
pos[C] = pos[A] + Vector3.new(2, 0, 0)
check("déjà marié : on ne peut pas redemander", not M.ask(C, 1))
check("divorce : rompu des deux côtés", M.divorce(A) and profs[A].conjoint == nil and profs[B].conjoint == nil)
m:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
