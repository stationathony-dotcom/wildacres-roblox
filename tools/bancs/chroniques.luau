-- Banc Edit : chroniques (Systemes/Chroniques + Shared/Chroniques), G simulé.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS.Shared.Chroniques)
local mod = game.ServerScriptService.Systemes.Chroniques:Clone()
local K = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local prof = { col = {}, stats = {} }
local bag = { old_page = 40 }
local bumps, toasts = {}, {}
local P = {}
local G = {
	Config = { ITEMS = setmetatable({}, { __index = function() return {} end }) },
	Joueurs = {
		get = function() return prof end,
		take = function(_, i, n) if (bag[i] or 0) < n then return false end bag[i] -= n return true end,
		add = function(_, i, n) bag[i] = (bag[i] or 0) + n end,
		addSkillXp = function() end, markDirty = function() end, sync = function() end,
	},
	Social = { bump = function(_, s) bumps[s] = (bumps[s] or 0) + 1 end },
	Util = { toast = function(_, t) table.insert(toasts, t) end },
}
K.init(G)
K.send = function() end
local remote = RS:FindFirstChild("Chronique")
check("événement Chronique publié", remote ~= nil and remote:IsA("RemoteEvent"))

check("aucune page au départ", string.find(K.describe(P)[1], "Aucune page") ~= nil)
local ok1 = K.read(P)
check("une lecture consomme une page", ok1 and bag.old_page == 39)
local n = 0
for _ in prof.col.pages do
	n += 1
end
check("une page connue", n == 1)
for _ = 1, C.TOTAL - 1 do
	K.read(P)
end
n = 0
for _ in prof.col.pages do
	n += 1
end
check("toutes les pages après " .. C.TOTAL .. " lectures (jamais deux fois la même)", n == C.TOTAL)
check("6 chroniques complètes comptées", bumps.chroniques == #C.LIST)
check("une carte au trésor par chronique", bag.treasure_map == #C.LIST)
check("objets anciens donnés", (bag.relic or 0) == 1 and (bag.ancient_jewel or 0) == 1)
local before = bag.old_page
check("tout connu : la page n'est pas consommée", K.read(P) == false and bag.old_page == before)
check("relire un récit connu", K.show(P, 1) == true)
check("relire un récit inexistant : non", K.show(P, 99) == false)
check("résumé : 6 lignes", #K.describe(P) == #C.LIST)
for _, s in C.LIST do
	check("récit « " .. s.titre .. " » : 4 pages, objet " .. s.recompense, #s.pages == 4)
end

mod:Destroy()
remote:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
