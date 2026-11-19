-- Banc Edit : création du personnage, barbier, tailleur (Systemes/Avatar), G simulé.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local WG = require(f.WorldGen)
local mod = game.ServerScriptService.Systemes.Avatar:Clone()
local A = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local prof = {}
local gold = 200
local sent, toasts = {}, {}
local root = { Position = Vector3.zero }
local G = {
	WG = WG,
	Interact = { onAction = function() end },
	Joueurs = {
		get = function() return prof end, markDirty = function() end, sync = function() end,
		take = function(_, _, n) if gold < n then return false end gold -= n return true end,
	},
	Util = { toast = function(_, t) table.insert(toasts, t) end, root = function() return root end },
	remotes = { Menu = { FireClient = function(_, _, d) table.insert(sent, d) end } },
}
A.init(G)
A.refresh = function() end
local P = { UserId = 1234, Character = nil }

check("apparence par défaut : villageoise, du choix de départ", A.defaultLook(P).mode == "villageois" and A.STARTER.hair[A.defaultLook(P).hair])
A.setLook(P, { hair = "long" })
check("sans écran ouvert : refus", prof.look == nil)
A.open(P, "creation", nil)
check("écran de création envoyé", sent[#sent].kind == "look" and sent[#sent].ctx == "creation")
A.setLook(P, { ctx = "creation", skin = 2, hair = "barbe", hairColor = 1, shirt = 1, pants = 1 })
check("création : style verrouillé refusé", prof.look == nil)
A.setLook(P, { ctx = "creation", skin = 2, hair = "long", hairColor = 3, shirt = 4, pants = 2 })
check("création : gratuite, parmi le choix de départ", prof.look and prof.look.created and prof.look.hair == "long" and gold == 200)
A.open(P, "creation", nil)
check("création une seule fois", sent[#sent].ctx ~= "creation" or #sent == 1)
-- barbier
local barber = { root = { Position = Vector3.new(5, 0, 0) } }
A.open(P, "barbier", barber)
A.setLook(P, { ctx = "barbier", skin = 4, hair = "barbe", hairColor = 3, shirt = 9, pants = 9 })
check("barbier : nouvelle coupe débloquée (60 + façon 10)", prof.look.hair == "barbe" and gold == 130 and prof.unlocks.hair.barbe)
check("barbier : ne touche ni au teint ni à la tenue", prof.look.skin == 2 and prof.look.shirt == 4)
A.open(P, "barbier", barber)
A.setLook(P, { ctx = "barbier", hair = "long", hairColor = 3 })
A.open(P, "barbier", barber)
A.setLook(P, { ctx = "barbier", hair = "barbe", hairColor = 3 })
check("style déjà débloqué : seulement la façon (2 × 10)", gold == 110 and prof.look.hair == "barbe")
-- tailleur
local tailor = { root = { Position = Vector3.new(5, 0, 0) } }
A.open(P, "tailleur", tailor)
A.setLook(P, { ctx = "tailleur", hair = "chauve", shirt = 7, pants = 2 })
check("tailleur : teinte débloquée (30 + 10), coiffure inchangée", prof.look.shirt == 7 and prof.look.hair == "barbe" and gold == 70)
-- trop loin
A.open(P, "tailleur", tailor)
root.Position = Vector3.new(100, 0, 0)
A.setLook(P, { ctx = "tailleur", shirt = 1, pants = 2 })
check("trop loin de l'artisan : refus", prof.look.shirt == 7 and gold == 70)
root.Position = Vector3.zero
gold = 5
A.open(P, "barbier", barber)
A.setLook(P, { ctx = "barbier", hair = "tresses", hairColor = 3 })
check("pas assez d'or : refus", prof.look.hair == "barbe")
mod:Destroy()
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
