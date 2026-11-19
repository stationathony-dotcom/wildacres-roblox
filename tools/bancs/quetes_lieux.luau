-- Banc des quêtes « à un lieu » (Systemes/QuetesLieux) : génération des 4 sortes, textes, points tirés
-- à la prise, directions (0° = nord = -Z). Mode Edit, sans Play, faux monde (rien n'est posé en jeu).
local QL = assert(loadstring(game.ServerScriptService.Systemes.QuetesLieux.Source))()
local G = {
	world = { seed = 77, players = {} },
	Config = { CELL = 4, ITEMS = { coin_purse = {} } },
	WG = { inWorld = function() return true end, regionOf = function(x, z) return math.floor(x / 64), math.floor(z / 64) end,
		placeLabel = function() return "une vieille maison abandonnée" end, hash = function(...) local h = 0 for _, v in { ... } do h = (h * 31 + #tostring(v)) % 2147483647 end return h end },
	wg = { placesAround = function() return { { kind = "ruin", rx = 2, rz = 1, ax = 140, az = 70 }, { kind = "village", rx = 1, rz = 1, ax = 80, az = 80 } } end },
	Util = { isWater = function() return false end, toast = function() end, root = function() end },
	Interact = { onPrompt = function() end },
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
for _, k in { "retrouver", "visiter", "enqueter", "escorter" } do
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
local f = workspace:FindFirstChild("QuetesLieux")
if f then
	f:Destroy()
end
table.insert(out, 1, string.format("Banc quêtes à un lieu : %d échec(s)", fails))
return table.concat(out, "\n")
