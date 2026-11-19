-- Banc Edit : course du tableau d'affichage (Activites, kind « course »), G simulé.
local mod = game.ServerScriptService.Systemes.Activites:Clone()
local A = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local function fakePlayer(uid, name, pos)
	local root = { Position = pos }
	local p = { UserId = uid, DisplayName = name, root = root }
	return p
end
local org = fakePlayer(1, "Orga", Vector3.new(0, 0, 0))
local p2 = fakePlayer(2, "Rapide", Vector3.new(10, 0, 0))
local p3 = fakePlayer(3, "Absent", Vector3.new(900, 0, 900))
local byUid = { u1 = org, u2 = p2, u3 = p3 }
local paid, toasts = {}, {}
local gold = { [1] = 500 }
local G = {
	world = { day = 1, minutes = 600, extra = { villages = { ["0,0"] = { cx = 0, cz = 0, name = "Valdor" } } } },
	Quetes = { villages = function()
		return { { key = "0,0", name = "Valdor", x = 0, z = 0 }, { key = "1,0", name = "Prèsvert", x = 180, z = 0 }, { key = "3,0", name = "Rocneige", x = 400, z = 0 } }
	end },
	Interact = { onAction = function() end, onPrompt = function() end },
	Util = {
		root = function(p) return p.root end, playerOf = function(id) return byUid[id] end,
		toast = function(_, t) table.insert(toasts, t) end, newId = function(p) return p .. "1" end,
	},
	Joueurs = {
		take = function(p, _, n) if (gold[p.UserId] or 0) < n then return false end gold[p.UserId] -= n return true end,
		add = function(p, _, n) gold[p.UserId] = (gold[p.UserId] or 0) + n end,
		count = function(p) return gold[p.UserId] or 0 end, sync = function() end, addSkillXp = function() end,
	},
	Economie = { record = function() end },
	Mondes = { saveSoon = function() end },
	Poste = { deliverSystem = function(uid, d) paid[uid] = (paid[uid] or 0) + (d.gold or 0) end },
	Admin = { blocks = function() return false end },
	remotes = { Menu = { FireClient = function() end } },
}
A.init(G) -- lance aussi la boucle de fond (inoffensive ici)

local dest = A.raceDestination("0,0")
check("arrivée = village le plus proche au-delà de 250 studs", dest and dest.name == "Rocneige")
A.create(org, { v = "0,0", kind = "course", delay = 15, dur = 60, prize = 200 })
local a
for _, x in G.world.extra.activites do
	a = x
end
check("course affichée vers Rocneige, cagnotte bloquée", a and a.dest and a.dest.name == "Rocneige" and gold[1] == 300)
a.part["2"] = "Rapide"
a.part["3"] = "Absent"
G.world.minutes += 20 -- le départ
A.tick()
A.tick()
check("départ : course en cours", a.state == "encours")
check("absent au départ : hors course", a.dq["3"] == true and not a.dq["2"])
p3.root.Position = Vector3.new(400, 0, 0) -- il triche : il attendait à l'arrivée
A.tick()
check("le tricheur arrivé d'avance ne gagne pas", a.state == "encours")
p2.root.Position = Vector3.new(395, 0, 10)
A.tick()
check("premier arrivé : gagne la cagnotte", a.state == "fini" and paid[2] == 200)

-- course sans arrivant : cagnotte rendue
G.Util.newId = function(p) return p .. "2" end
A.create(org, { v = "0,0", kind = "course", delay = 15, dur = 15, prize = 100 })
local b = G.world.extra.activites.act2
G.world.minutes += 20
A.tick()
A.tick()
G.world.minutes += 20
A.tick()
check("personne n'arrive : cagnotte rendue à l'organisateur", b.state == "fini" and paid[1] == 100)

G.world = nil -- la boucle de fond lancée par init se met en veille
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
