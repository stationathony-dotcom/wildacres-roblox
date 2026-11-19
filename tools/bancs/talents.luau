-- Banc Edit : talents de maître exclusifs (Joueurs.learnTalent), G simulé.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local Config = require(f.Config)
local mod = game.ServerScriptService.Systemes.Joueurs:Clone()
local J = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local toasts = {}
local G = { Config = Config, Util = { toast = function(_, t) table.insert(toasts, t) end } }
pcall(J.init, G)
J.init = J.init
local P = {}
J.profiles = J.profiles or {}
J.profiles[P] = { talents = { crochetage = 3, ombre = 1 }, skills = {} }
J.talentFree = function() return 5 end
J.applyStats = function() end
J.markDirty = function() end
-- 4 points dans la voie : le palier 4 s'ouvre
J.learnTalent(P, "fantome")
check("palier 4 ouvert : Fantôme appris", J.profiles[P].talents.fantome == 1)
J.learnTalent(P, "cavaleur")
check("Cavaleur refusé (exclusif avec Fantôme)", (J.profiles[P].talents.cavaleur or 0) == 0 and toasts[#toasts]:find("exclusif") ~= nil)
J.profiles[P].talents = { main_verte = 1 }
J.learnTalent(P, "terre_riche")
check("pas assez de points dans la voie : refus", (J.profiles[P].talents.terre_riche or 0) == 0)
local n, groups = 0, {}
for _, t in Config.TALENTS do
	if t.excl then
		n += 1
		groups[t.excl] = (groups[t.excl] or 0) + 1
	end
end
local pairs2 = true
for _, c in groups do
	if c ~= 2 then
		pairs2 = false
	end
end
check("12 talents de maître, deux par voie (6 voies)", n == 12 and pairs2)
mod:Destroy()
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
