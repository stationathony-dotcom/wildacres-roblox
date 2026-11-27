-- Banc de la gazette des joueurs (27/11, Systemes/Gazette) en mode Edit, faux G.
local m = game.ServerScriptService.Systemes.Gazette:Clone()
m.Parent = game.ServerStorage
local Z = require(m)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local bag = {}
local inVillage = true
local G = {
	world = { day = 4, extra = {} },
	Quetes = { nearVillage = function() return inVillage and { key = "V", name = "Valdor" } or nil end },
	Joueurs = { count = function(_, i) return bag[i] or 0 end, take = function(_, i, n) bag[i] -= n return true end, sync = function() end },
	Social = { bump = function() end }, Mondes = { saveSoon = function() end },
	Interact = { onAction = function() end }, Util = { toast = function() end }, remotes = { Menu = { FireClient = function() end } },
}
Z.init(G)
Z.filter = function(_, t) return t end
local A, B = { UserId = 1, DisplayName = "Alix" }, { UserId = 2, DisplayName = "Bran" }
check("sans papier ni encre : refus", not Z.write(A, "Grande foire", "Venez nombreux à Valdor !"))
bag = { paper = 2, ink = 2 }
inVillage = false
check("hors du village : refus", not Z.write(A, "Grande foire", "Venez nombreux !"))
inVillage = true
check("texte trop court : refus", not Z.write(A, "Hé", "ok"))
check("article publié, papier et encre pris", Z.write(A, "Grande foire", "Venez nombreux à Valdor !") and bag.paper == 1 and bag.ink == 1)
local L = G.world.extra.gazette
check("le plus récent en tête, auteur et village notés", L[1].auteur == "Alix" and L[1].village == "Valdor")
check("pas retirable par un autre", not Z.remove(B, L[1].id))
check("retiré par son auteur", Z.remove(A, L[1].id) and #L == 0)
bag = { paper = 100, ink = 100 }
for i = 1, Z.KEEP + 5 do
	Z.write(A, "Article " .. i, "Texte numéro " .. i)
end
check("seuls les " .. Z.KEEP .. " derniers sont gardés", #L == Z.KEEP and L[1].titre == "Article " .. (Z.KEEP + 5))
m:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
