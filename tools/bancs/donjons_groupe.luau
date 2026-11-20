-- Banc des grottes en groupe (Donjons, 20/11) — mode Edit, G simulé.
-- Vie des créatures selon le nombre de joueurs dans les galeries (jamais à la baisse), cycle du coffre
-- (une part par joueur et par remplissage, reprise de l'ancien format).
local D = assert(loadstring(game.ServerScriptService.Systemes.Donjons.Source, "Donjons"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end
local roots = {}
local players = {}
local G = {
	world = { day = 10 },
	Game = { players = function() return players end },
	Util = { root = function(p) return roots[p] end },
	Interact = { onAction = function() end, onPrompt = function() end },
	Config = { Y_MIN = -200 },
}
pcall(D.init, G)
local function enemy(hp)
	return { hp = hp, maxHp = hp }
end
local cave = { enemies = { enemy(100), enemy(400) }, box = { cf = CFrame.new(0, -120, 0), size = Vector3.new(100, 20, 100) } }
-- présence
local A, B, C = {}, {}, {}
players = { A, B, C }
roots[A] = { Position = Vector3.new(10, -118, 10) }
roots[B] = { Position = Vector3.new(-30, -118, 20) }
roots[C] = { Position = Vector3.new(10, 40, 10) } -- en surface
check("2 joueurs dans les galeries (pas celui de la surface)", #D.playersIn(cave) == 2)
D.scaleFor(cave, 1)
check("seul : vie inchangée", cave.enemies[1].maxHp == 100)
D.scaleFor(cave, 2)
check("à deux : +60 % (160 / 640)", cave.enemies[1].maxHp == 160 and cave.enemies[2].maxHp == 640)
cave.enemies[2].hp = 320 -- à moitié
D.scaleFor(cave, 3)
check(string.format("à trois : 220 au total, la blessure garde sa proportion (%d / %d)", cave.enemies[2].hp, cave.enemies[2].maxHp),
	cave.enemies[1].maxHp == 220 and cave.enemies[2].maxHp == 880 and cave.enemies[2].hp == 440)
D.scaleFor(cave, 1)
check("un joueur repart : la vie ne baisse pas", cave.enemies[1].maxHp == 220)
-- coffre
local rs = {}
local c = D.cycle(rs, "g1")
check("premier passage : nouveau cycle vide", c.day == 10 and next(c.by) == nil)
c.by["1"] = true
G.world.day = 12
check("2 jours plus tard : même cycle, la part de 1 est prise", D.cycle(rs, "g1").by["1"] == true)
G.world.day = 13
check("3 jours plus tard : rempli à nouveau", next(D.cycle(rs, "g1").by) == nil)
local old = { caves = { g2 = 12 } } -- ancien format : pillé le jour 12
check("ancien format repris : cycle commencé le jour 12", D.cycle(old, "g2").day == 12)
return fails .. " échec(s)\n" .. table.concat(out, "\n")
