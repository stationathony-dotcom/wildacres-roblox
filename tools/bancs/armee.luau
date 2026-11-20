-- Banc de l'armée v2 (ordres de groupe, 20/11) — mode Edit, G simulé, aucun modèle posé.
-- Armee.order : portée de voix, suivre (rangs), tenir (ligne), patrouiller (carré), attaquer (cible).
-- Compagnons.step : un soldat attaque sa cible puis reprend l'ordre d'avant ; patrouille de coin en coin ;
-- en colonne derrière le maître.
local Armee = assert(loadstring(game.ServerScriptService.Systemes.Armee.Source, "Armee"))()
local Comp = assert(loadstring(game.ServerScriptService.Systemes.Compagnons.Source, "Compagnons"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end

local O = Vector3.new(0, 10, 0)
local root = { Position = O, CFrame = CFrame.lookAt(O, O + Vector3.new(0, 0, -1)) } -- regarde vers -Z
local P = { UserId = 9, DisplayName = "Chef" }
local toasts, moves, hits = {}, {}, {}
local enemies = {}
local function soldier(id, x, z)
	return { petId = id, owner = "u9", pos = Vector3.new(x, 10, z), rec = { kind = "militia", mode = "guard", unit = true, hx = x, hz = z },
		model = { Parent = true }, k = { name = "Milicien", speed = 13, dmg = 14 }, kind = "militia", radius = 1.2, cd = 0, hp = 140, maxHp = 140,
		lastBark = 0, height = 4 }
end
local units = { soldier("a", 5, 0), soldier("b", 10, 0), soldier("c", 0, 20), soldier("loin", 200, 0) }
local G = {
	Config = { UNITS = { militia = { name = "Milicien", wage = 10, fight = true, guard = true } }, TAMING = {}, CELL = 4, REGION = 16 },
	Interact = { onAction = function() end, onPrompt = function() end },
	Util = { root = function() return root end, pid = function() return "u9" end, toast = function(_, t) table.insert(toasts, t) end,
		groundY = function() return 10 end, playerOf = function() return P end, owns = function(_, o) return o == "u9" end, emote = function() end },
	Compagnons = { unitsOf = function() return units end, refreshPrompt = function() end },
	Enemies = {
		list = enemies,
		byId = function(id) for _, e in enemies do if e.id == id and not e.dead then return e end end return nil end,
		move = function(en, goal) moves[en.petId] = goal end, render = function() end,
		hit = function(t) table.insert(hits, t.id) end, KINDS = {},
	},
	Joueurs = { talent = function() return 0 end, has = function() return false end },
	Mondes = { playerRecord = function() return { pets = {} } end },
	Combat = { hurtPlayer = function() end, popup = function() end },
	Game = { players = function() return {} end },
	Parcelles = { at = function() return nil end },
}
Armee.init(G)

-- 1. voix
local ok = Armee.order(P, "suivre")
check("suivre : entendu par les 3 soldats proches, pas par celui à 200 studs",
	ok and units[1].rec.mode == "follow" and units[3].rec.mode == "follow" and units[4].rec.mode == "guard")
check("suivre : places dans la colonne 0, 1, 2 (du plus proche au plus loin)", units[1].slot == 0 and units[2].slot == 1 and units[3].slot == 2)
check("ordre inconnu refusé", not Armee.order(P, "danser"))

-- 2. tenir : en ligne devant soi, 3 studs d'écart
Armee.order(P, "tenir")
local a, b, c = units[1].rec, units[2].rec, units[3].rec
check("tenir : mode garde", a.mode == "guard" and b.mode == "guard" and c.mode == "guard")
check(string.format("tenir : ligne devant (z = %d, x = %d / %d / %d)", a.hz, a.hx, b.hx, c.hx),
	a.hz == -4 and b.hz == -4 and c.hz == -4 and a.hx == -3 and b.hx == 0 and c.hx == 3)

-- 3. patrouiller : carré autour de soi, chacun part d'un coin différent
Armee.order(P, "patrouiller")
check("patrouiller : 4 coins, départs différents", #(a.route or {}) == 4 and a.wp == 1 and b.wp == 2 and c.wp == 3 and a.mode == "patrol")
local corner = a.route[1]
check(string.format("patrouiller : coins à ~25 studs (%d, %d)", corner[1], corner[2]), math.abs(Vector2.new(corner[1], corner[2]).Magnitude - 25.4) < 1.5)

-- 4. attaquer
table.insert(enemies, { id = "derriere", pos = Vector3.new(0, 10, 20), k = { name = "Loup" }, model = { Parent = true }, radius = 1.5 })
table.insert(enemies, { id = "lapin", pos = Vector3.new(0, 10, -10), k = { name = "Lapin", passive = true }, model = { Parent = true } })
table.insert(enemies, { id = "chien", pos = Vector3.new(1, 10, -8), k = { name = "Chien" }, pet = true, model = { Parent = true } })
check("attaquer : rien devant (derrière, passif, compagnon ignorés)", not Armee.order(P, "attaquer"))
table.insert(enemies, { id = "ours", pos = Vector3.new(2, 10, -30), k = { name = "Ours" }, model = { Parent = true }, radius = 2 })
Armee.order(P, "attaquer")
check("attaquer : l'ours devant est choisi", units[1].order and units[1].order.id == "ours" and units[3].order.id == "ours")
Armee.order(P, "attaquer", "derriere")
check("attaquer une cible désignée (clic), même derrière", units[1].order and units[1].order.id == "derriere")

-- 5. comportement (Compagnons.step) : le soldat suit sa cible, la frappe, puis reprend la patrouille
enemies[1].dead, enemies[3].dead = true, true -- plus que l'ours (et le lapin, passif)
Comp.init(G)
local s1 = units[1]
s1.order = { kind = "attack", id = "ours" }
s1.pos = Vector3.new(2, 10, -27) -- au contact
table.insert(Comp.list, s1)
Comp.step(0.1)
check("au contact : il frappe l'ours", hits[1] == "ours")
enemies[4].dead = true
moves = {}
Comp.step(0.1)
check("l'ours tombé : l'ordre d'attaque s'efface", s1.order == nil)
local wp = s1.rec.route[s1.rec.wp]
local goal = moves.a
check("puis il reprend sa patrouille vers son coin", goal ~= nil and math.abs(goal.X - wp[1]) < 0.01 and math.abs(goal.Z - wp[2]) < 0.01)
s1.pos = Vector3.new(wp[1], 10, wp[2])
local before = s1.rec.wp
Comp.step(0.1)
check("arrivé au coin : il vise le suivant", s1.rec.wp == before % 4 + 1)

-- 6. colonne : le soldat 5 (rang 1, colonne 1) se place derrière le maître
s1.rec.mode, s1.rec.route, s1.slot = "follow", nil, 5
s1.pos = Vector3.new(30, 10, 30)
moves = {}
Comp.step(0.1)
local spot = moves.a
check(string.format("colonne : place derrière, rang 2 (%.1f, %.1f)", spot and spot.X or 0, spot and spot.Z or 0),
	spot and math.abs(spot.Z - 8) < 0.01 and math.abs(spot.X - (-1.5)) < 0.01)

-- 7. niveau de détail : un soldat loin de tout joueur, sans combat, pense 1 fois par seconde
local thinks = 0
local move0 = G.Enemies.move
G.Enemies.move = function(...)
	thinks += 1
	return move0(...)
end
s1.rec.mode, s1.slot, s1.order = "follow", 0, nil
s1.lastHurt = nil
s1.pos = Vector3.new(40, 10, 40)
G.Util.playerDist = function() return 500 end
for _ = 1, 10 do
	Comp.step(0.1)
end
check("loin de tout joueur : 1 calcul par seconde au lieu de 10 (" .. thinks .. ")", thinks <= 2)
thinks = 0
G.Util.playerDist = function() return 20 end
for _ = 1, 10 do
	Comp.step(0.1)
end
check("près d'un joueur : chaque pas (" .. thinks .. ")", thinks >= 9)
G.Enemies.move = move0
table.clear(Comp.list)
return fails .. " échec(s)\n" .. table.concat(out, "\n")
