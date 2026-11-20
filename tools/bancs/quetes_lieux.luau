-- Banc des quêtes « à un lieu » (Systemes/QuetesLieux) : génération des 4 sortes, textes, points tirés
-- à la prise, directions (0° = nord = -Z). Mode Edit, sans Play, faux monde (rien n'est posé en jeu).
local QL = assert(loadstring(game.ServerScriptService.Systemes.QuetesLieux.Source))()
local G = {
	world = { seed = 77, players = {} },
	Config = { CELL = 4, ITEMS = { coin_purse = {} } },
	WG = { inWorld = function() return true end, regionOf = function(x, z) return math.floor(x / 64), math.floor(z / 64) end,
		placeLabel = function() return "une vieille maison abandonnée" end, hash = function(...) local h = 0 for _, v in { ... } do h = (h * 31 + #tostring(v)) % 2147483647 end return h end },
	wg = { placesAround = function() return { { kind = "ruin", rx = 2, rz = 1, ax = 140, az = 70 }, { kind = "village", rx = 1, rz = 1, ax = 80, az = 80 } } end,
		plan = function(_, rx, rz)
			-- une maison habitée par village : (village.x + 30, village.z), façade vers l'est (yaw 90)
			local bx = rx == 1 and 330 or 730
			local bz = rx == 1 and 100 or 500
			return { npcs = { { id = "n1", name = "Jehan" } }, houses = { { id = "h1", x = bx, z = bz, yaw = 90, owner = "n1" }, { id = "h2", x = 0, z = 0, yaw = 0 } } }
		end },
	Util = { isWater = function() return false end, toast = function(_, t) LAST_TOAST = t end, root = function() return ROOT end, sfx = function() end,
		owns = function(_, o) return o == "u1" end, groundY = function() return 0 end, prompt = function() end },
	Interact = { onPrompt = function(name, fn) if name == "quete_lieu" then SEARCH = fn end end },
	Joueurs = { count = function(_, i) return BAG[i] or 0 end, take = function(_, i, n) BAG[i] -= n return true end, sync = function() end, addSkillXp = function() end },
	World = { loaded = {} },
	Quetes = { villages = function() return { { key = "1,0", name = "Valdor", x = 300, z = 100 }, { key = "3,2", name = "Brumeval", x = 700, z = 500 } } end },
}
QL.init(G)
local out, fails = {}, 0
local function check(c, msg)
	if not c then
		fails += 1
	end
	table.insert(out, (c and "OK    " or "ÉCHEC ") .. msg)
end
local v = { key = "1,0", name = "Valdor", x = 300, z = 100 }
local seen = {}
for i = 1, 300 do
	local q = { v = "1,0", vname = "Valdor", id = "1,0:5:" .. i }
	if QL.offer(v, Random.new(i), q, function(_, b) return math.floor(b) end, G.Quetes.villages) then
		if not seen[q.kind] then
			seen[q.kind] = q
		end
	end
end
for _, k in { "retrouver", "visiter", "enqueter", "escorter", "livrer", "reparer", "etal" } do
	check(seen[k] ~= nil, "sorte « " .. k .. " » générée")
end
local vis = seen.visiter
if vis then
	QL.onTake({ UserId = 1 }, vis, v)
	check(vis.where and string.find(vis.where, "sud%-est", 1) ~= nil, "direction de la ruine : sud-est (" .. tostring(vis.where) .. ")")
end
local enq = seen.enqueter
if enq then
	QL.onTake({ UserId = 1 }, enq, v)
	check(enq.pts and #enq.pts == 3, "enquête : 3 indices tirés")
	check(string.find(QL.what(enq), "1/3", 1, true) ~= nil, "enquête : texte « 1/3 »")
end
local ret = seen.retrouver
if ret then
	QL.onTake({ UserId = 1 }, ret, v)
	local d = ret.px and Vector2.new(ret.px - v.x, ret.pz - v.z).Magnitude or 0
	check(d >= 50 and d <= 160, string.format("objet perdu entre 50 et 160 studs (%d)", d))
end
check(seen.escorter and seen.escorter.key ~= "1,0", "escorte : vers un AUTRE village")

-- livraison à domicile
local P = { UserId = 1 }
local liv = seen.livrer
if liv then
	QL.onTake(P, liv, v)
	check(liv.key == "3,2" and liv.who == "Jehan", "livraison : chez Jehan, à Brumeval (" .. tostring(liv.who) .. ")")
	check(liv.px and math.abs(liv.px - 736) < 0.01 and math.abs(liv.pz - 500) < 0.01, string.format("livraison : devant la porte (%.1f, %.1f)", liv.px or 0, liv.pz or 0))
	check(string.find(QL.what(liv), "Jehan", 1, true) ~= nil, "livraison : texte « " .. QL.what(liv) .. " »")
end

-- réparation : 3 endroits autour de la maison, 4 planches + 2 clous chacun, refus sans matériaux
local rep = seen.reparer
if rep then
	QL.onTake(P, rep, v)
	local okPts = rep.pts and #rep.pts == 3
	for _, p in rep.pts or {} do
		okPts = okPts and math.abs(Vector2.new(p[1] - 330, p[2] - 100).Magnitude - 6) < 0.01
	end
	check(okPts, "réparation : 3 endroits à 6 studs de la maison")
	G.world.players["1"] = { quetes = { act = { [rep.id] = rep } } }
	G.Quetes.send = function() end
	local prompt = { GetAttribute = function(_, k) return ({ Owner = "1", Quete = rep.id })[k] end }
	BAG = { planks = 5, nails = 1 }
	ROOT = { Position = Vector3.new(rep.pts[1][1], 0, rep.pts[1][2]) }
	SEARCH(P, prompt)
	check((rep.got or 0) == 0 and BAG.planks == 5 and string.find(LAST_TOAST or "", "clous") ~= nil, "réparation : refusée sans assez de clous, rien pris")
	BAG = { planks = 12, nails = 6 }
	for i = 1, 3 do
		ROOT = { Position = Vector3.new(rep.pts[i][1] + 2, 0, rep.pts[i][2]) }
		SEARCH(P, prompt)
	end
	check(rep.got == 3 and BAG.planks == 0 and BAG.nails == 0, "réparation : 3 endroits réparés, 12 planches et 6 clous pris")
	ROOT = { Position = Vector3.new(0, 0, 0) }
	BAG = { planks = 4, nails = 2 }
	SEARCH(P, prompt)
	check(BAG.planks == 4, "réparation finie : plus rien n'est pris")
end

-- étal sur la place
local et = seen.etal
if et then
	QL.onTake(P, et, v)
	local placed = { { item = "stall", owner = "u1", x = 310, z = 110, stall = { items = {} } } }
	G.World.loaded["1,0"] = { state = { placed = placed } }
	check(not QL.stallOnSquare(P, v), "étal vide : pas encore")
	placed[1].stall.items.bread = { 3, 4 }
	check(QL.stallOnSquare(P, v), "étal garni sur la place : réussi")
	placed[1].x = 400
	check(not QL.stallOnSquare(P, v), "étal trop loin de la place : non")
	placed[1].x, placed[1].owner = 310, "u2"
	check(not QL.stallOnSquare(P, v), "étal d'un autre joueur : non")
end
local f = workspace:FindFirstChild("QuetesLieux")
if f then
	f:Destroy()
end
table.insert(out, 1, string.format("Banc quêtes à un lieu : %d échec(s)", fails))
return table.concat(out, "\n")
