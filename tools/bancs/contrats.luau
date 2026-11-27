-- Banc des contrats entre joueurs (27/11, Systemes/Contrats) en mode Edit, faux G.
local m = game.ServerScriptService.Systemes.Contrats:Clone()
m.Parent = game.ServerStorage
local K = require(m)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local bags = {}
local mail = {}
local inVillage = true
local function P(id, name)
	bags[id] = { gold = 0 }
	return { UserId = id, DisplayName = name }
end
local A, B = P(1, "Alix"), P(2, "Bran")
local G = {
	world = { day = 3, extra = {} },
	Config = require(game.ReplicatedStorage.Shared.Config),
	Quetes = { nearVillage = function() return inVillage and { key = "V", name = "Valdor" } or nil end },
	Joueurs = { count = function(p, i) return bags[p.UserId][i] or 0 end,
		take = function(p, i, n) local b = bags[p.UserId] if (b[i] or 0) < (n or 1) then return false end b[i] -= (n or 1) return true end,
		add = function(p, i, n) local b = bags[p.UserId] b[i] = (b[i] or 0) + n end, sync = function() end, addSkillXp = function() end },
	Poste = { deliverSystem = function(uid, parcel) table.insert(mail, { uid = uid, parcel = parcel }) end },
	Economie = { record = function() end }, Mondes = { saveSoon = function() end },
	Util = { toast = function() end }, remotes = { Menu = { FireClient = function() end } }, Interact = { onAction = function() end },
}
K.init(G)
check("sans or : refus", not K.publish(A, "iron_ingot", 10, 100))
bags[1].gold = 150
check("objet inconnu : refus", not K.publish(A, "pas_un_objet", 10, 100))
check("contrat publié, or mis de côté", K.publish(A, "iron_ingot", 10, 100) and bags[1].gold == 50)
local id = K.list()[1].id
check("son propre contrat : pas livrable", not K.deliver(A, id))
bags[2].iron_ingot = 4
check("pas assez d'objets : refus", not K.deliver(B, id))
bags[2].iron_ingot = 12
check("livré : Bran payé, 2 lingots restants", K.deliver(B, id) and bags[2].gold == 100 and bags[2].iron_ingot == 2)
check("marchandise envoyée par la poste à Alix", #mail == 1 and mail[1].uid == 1 and mail[1].parcel.items.iron_ingot == 10)
check("impossible de livrer deux fois", not K.deliver(B, id))
K.publish(A, "wood", 5, 20)
local id2 = K.list()[1].id
check("retiré : or rendu par la poste", K.withdraw(A, id2) and mail[#mail].parcel.gold == 20)
check("stockage partagé avec /commandes (G.world.extra.commandes)", G.world.extra.commandes ~= nil)
K.publish(A, "stone", 5, 30)
G.world.day = 3 + K.DAYS
K.newDay()
check("expiré : or rendu par la poste", #K.list() == 0 and mail[#mail].parcel.gold == 30)
m:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
