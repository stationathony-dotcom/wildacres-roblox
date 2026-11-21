-- Banc Edit (21/11) : concours de dressage et d'élevage du tableau d'affichage (Activites), G simulé.
local mod = game.ServerScriptService.Systemes.Activites:Clone()
local A = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local function fp(uid, name)
	return { UserId = uid, DisplayName = name, root = { Position = Vector3.new(0, 0, 0) } }
end
local org, p2, p3, p4 = fp(1, "Orga"), fp(2, "Dresseuse"), fp(3, "Éleveur"), fp(4, "Badaud")
local byUid = { u1 = org, u2 = p2, u3 = p3, u4 = p4 }
local paid, xp, menu = {}, {}, nil
local gold = { [1] = 500 }
local G = {
	world = { day = 1, minutes = 600, extra = { villages = { ["0,0"] = { cx = 0, cz = 0, name = "Valdor" } } } },
	Quetes = { villages = function() return { { key = "0,0", name = "Valdor", x = 0, z = 0 } } end },
	Interact = { onAction = function() end, onPrompt = function() end },
	Util = { root = function(p) return p.root end, playerOf = function(id) return byUid[id] end, toast = function() end,
		newId = function(p) return p .. tostring(math.random(1, 1e6)) end },
	Joueurs = {
		take = function(p, _, n) if (gold[p.UserId] or 0) < n then return false end gold[p.UserId] -= n return true end,
		add = function(p, _, n) gold[p.UserId] = (gold[p.UserId] or 0) + n end,
		count = function(p) return gold[p.UserId] or 0 end, sync = function() end,
		addSkillXp = function(p, s, n) xp[p.UserId] = s end,
	},
	Economie = { record = function() end }, Mondes = { saveSoon = function() end },
	Poste = { deliverSystem = function(uid, d) paid[uid] = (paid[uid] or 0) + (d.gold or 0) end },
	Admin = { blocks = function() return false end },
	remotes = { Menu = { FireClient = function(_, _, data) menu = data end } },
}
A.init(G)

check("deux sortes neuves : dressage et élevage (comptées par le jeu)", A.KINDS.dressage and A.KINDS.dressage.auto and A.KINDS.elevage and A.KINDS.elevage.auto)
local function run(kind, notes)
	A.create(org, { v = "0,0", kind = kind, delay = 15, dur = 30, prize = 100 })
	local a
	for _, x in G.world.extra.activites do
		if x.kind == kind and x.state ~= "fini" then
			a = x
		end
	end
	a.part["2"] = "Dresseuse"
	a.part["3"] = "Éleveur"
	G.world.minutes += 20
	A.tick()
	for _, n in notes do
		A.note(n[1], kind, n[2])
	end
	G.world.minutes += 40
	A.tick()
	return a
end
paid = {}
local a = run("dressage", { { p2, 1 }, { p2, 1 }, { p3, 1 }, { p4, 5 } })
check("dressage : 2 bêtes apprivoisées contre 1 → Dresseuse gagne la cagnotte", a.state == "fini" and paid[2] == 100 and not paid[3])
check("un non-inscrit ne marque rien", a.scores["4"] == nil)
check("gain de dressage → XP en dressage", xp[2] == "dressage")
paid = {}
a = run("elevage", { { p2, 2 }, { p3, 3 }, { p3, 2 } })
check("élevage : 5 produits ramassés contre 2 → Éleveur gagne", a.state == "fini" and paid[3] == 100 and not paid[2])
check("gain d'élevage → XP en élevage", xp[3] == "elevage")
A.send(org, "0,0")
local names = {}
for _, k in (menu and menu.kinds) or {} do
	names[k[1]] = k[2]
end
check("le tableau envoie la liste des sortes (" .. tostring(names.dressage) .. ", " .. tostring(names.elevage) .. ")", names.dressage ~= nil and names.elevage ~= nil and names.peche ~= nil)
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
