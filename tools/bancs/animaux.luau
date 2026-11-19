-- Banc Edit : capacité des abris (Animals.capacity) et livre des bêtes (Livres.animaux), G simulé.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local Config = require(f.Config)
local A = require(game.ServerScriptService.Systemes.Animals:Clone())
local modL = game.ServerScriptService.Systemes.Livres:Clone()
local L = require(modL)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local rs = { animals = {}, myAnimals = {}, placed = {} }
local toasts = {}
local G = {
	Config = Config, world = { regions = { ["0,0"] = rs }, players = {} },
	Util = { pid = function() return "u1" end, toast = function(_, t) table.insert(toasts, t) end },
	Interact = { onAction = function() end, onPrompt = function() end },
	Enemies = { KINDS = { wolf = { name = "Loup" } } },
	Horses = { describe = function() return { "🐎 Cheval bai ★★ (allure 100 %)" } end },
	Compagnons = { recordsOf = function() return { p1 = { kind = "wolf", trust = 40, hungry = 0, mode = "guard" } } end },
}
G.Animals = A
pcall(A.init, G)
L.init(G)
local sent
L.send = function(_, d) sent = d end
check("sans abri : 8 places", A.capacity("u1") == 8)
table.insert(rs.placed, { item = "henhouse", owner = "u1" })
table.insert(rs.placed, { item = "barn", owner = "u1" })
table.insert(rs.placed, { item = "barn", owner = "u2" })
check("poulailler + grange : 8 + 6 + 12 = 26 (les abris des autres ne comptent pas)", A.capacity("u1") == 26)
for i = 1, 26 do
	local id = "a" .. i
	table.insert(rs.myAnimals, { id = id, kind = i % 2 == 0 and "chicken" or "cow" })
	rs.animals[id] = { owner = "u1", product = i <= 3 }
end
check("26 bêtes : plein", A.canOwnMore({}) == false and toasts[#toasts]:find("abris") ~= nil)
table.insert(rs.placed, { item = "stable", owner = "u1" })
check("une étable de plus : de la place", A.canOwnMore({}) == true)
L.animaux({})
local txt = ""
for _, l in sent.lignes do
	txt ..= l.t .. " " .. l.x .. "\n"
end
check("livre : places affichées (26 / 32)", sent.sous:find("26 / 32") ~= nil)
check("livre : bêtes de ferme regroupées, produits prêts", txt:find("× 13") ~= nil and txt:find("à récolter") ~= nil)
check("livre : compagnon et monture", txt:find("Loup") ~= nil and txt:find("Cheval") ~= nil)
modL:Destroy()
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
