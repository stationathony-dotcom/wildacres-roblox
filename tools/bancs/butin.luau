-- Banc du butin au sol (mode Edit, sans Play) : module Butin avec un G simulé.
-- Vérifie : capture → au sol, empilement, réservation 30 s, groupe, ramassage, [Q], équipement,
-- portée, plafond de 400, expiration, aucun doublon.
local H = game:GetService("HttpService")
local mod = game.ServerScriptService.Systemes.Butin:Clone()
local shared = game.ReplicatedStorage.Shared:Clone()
shared.Parent = game:GetService("ServerStorage")
mod.Parent = shared
local B = require(mod)
local Config = require(shared.Config)

local res, fails = {}, 0
local function check(name, cond)
	table.insert(res, (cond and "OK   " or "ÉCHEC ") .. name)
	if not cond then
		fails += 1
	end
end

-- joueurs simulés : position, sac, groupe
local A = { UserId = 1, Name = "A", pos = Vector3.new(0, 24, 0), bag = {}, gear = {} }
local Bp = { UserId = 2, Name = "B", pos = Vector3.new(0, 24, 0), bag = {}, gear = {} }
local Cp = { UserId = 3, Name = "C", pos = Vector3.new(0, 24, 0), bag = {}, gear = {} }
local groups = { [A] = "g1", [Cp] = "g1" }
local toasts = {}
local prompts, actions = {}, {}
local G = { Config = Config }
G.Interact = {
	onPrompt = function(a, fn) prompts[a] = fn end,
	onAction = function(a, fn) actions[a] = fn end,
}
G.Social = { groupOf = function(p) return groups[p] end }
G.Util = {
	root = function(p) return { Position = p.pos } end,
	toast = function(p, t) table.insert(toasts, p.Name .. ":" .. t) end,
}
G.Joueurs = {
	add = function(p, item, n)
		if B.redirect(p, item, n) then return end
		p.bag[item] = (p.bag[item] or 0) + n
	end,
	addGear = function(p, g)
		if B.redirectGear(p, g) then return end
		table.insert(p.gear, g)
	end,
}
B.init(G)
local folder = workspace:FindFirstChild("ButinAuSol")
-- un sol connu : une dalle sous le point de test
local floor = Instance.new("Part")
floor.Anchored, floor.Size, floor.Position = true, Vector3.new(40, 1, 40), Vector3.new(0, 20, 0)
floor.Parent = workspace

-- 1. capture : tout tombe au sol, rien dans le sac
B.capture(A, Vector3.new(0, 25, 0), nil, function()
	G.Joueurs.add(A, "wood", 3)
	G.Joueurs.add(A, "wood", 2)
	G.Joueurs.add(A, "stone", 1)
	G.Joueurs.addGear(A, { name = "Épée test", rarity = 3, slot = "weapon", stats = {} })
end)
check("rien dans le sac pendant la capture", next(A.bag) == nil and #A.gear == 0)
check("3 objets au sol (bois empilé, pierre, épée)", B.count() == 3)
local wood
for _, d in B.list() do
	if d.item == "wood" then wood = d end
end
check("bois empilé ×5", wood and wood.n == 5)
check("posé sur la dalle (y≈21.2)", wood and math.abs(wood.pos.Y - 21.2) < 0.05)
check("cube créé avec invite et icône", wood and wood.part and wood.part.Parent == folder and wood.part:FindFirstChildOfClass("ProximityPrompt") ~= nil and wood.part.Icone.Nombre.Text == "×5")
check("hors capture : direct dans le sac", (function()
	G.Joueurs.add(A, "fiber", 2)
	return A.bag.fiber == 2 and B.count() == 3
end)())

-- 2. réservation : B (autre groupe) refusé, C (même groupe) accepté
check("B refusé pendant 30 s", B.pick(Bp, wood.id) == false and Bp.bag.wood == nil)
local stone
for _, d in B.list() do
	if d.item == "stone" then stone = d end
end
check("C (groupe de A) peut prendre", B.pick(Cp, stone.id) == true and Cp.bag.stone == 1)
check("pas de double ramassage", B.pick(A, stone.id) == false and A.bag.stone == nil)

-- 3. portée
A.pos = Vector3.new(100, 30, 0)
check("trop loin : refusé", B.pick(A, wood.id) == false)
A.pos = Vector3.new(0, 24, 0)
-- 4. après réservation : B peut prendre
wood.reserved = 0
check("après 30 s : B prend le bois", B.pick(Bp, wood.id) == true and Bp.bag.wood == 5)

-- 5. [Q] : tout autour, via l'action réseau
B.capture(A, Vector3.new(2, 25, 2), nil, function()
	G.Joueurs.add(A, "ore", 2)
	G.Joueurs.add(A, "coal", 1)
end)
actions.ramasser_tout(A, {})
check("[Q] ramasse minerai + charbon + épée", A.bag.ore == 2 and A.bag.coal == 1 and #A.gear == 1 and B.count() == 0)

-- 6. invite [E]
local d = B.drop(A, Vector3.new(0, 25, 0), "rope", 1)
prompts.ramasser(A, d.part:FindFirstChildOfClass("ProximityPrompt"))
check("invite [E] ramasse", A.bag.rope == 1 and B.count() == 0)

-- 7. quantités invalides refusées
check("quantité négative / NaN refusée", B.drop(A, Vector3.zero, "wood", -5) == nil and B.drop(A, Vector3.zero, "wood", 0 / 0) == nil)

-- 8. plafond 400 : les plus vieux partent
for i = 1, 405 do
	B.drop(nil, Vector3.new(i * 10, 25, 0), "wood", 1)
end
check("plafond 400 respecté", B.count() == 400 and #folder:GetChildren() == 400)

-- 9. erreur dans la capture : la capture est bien levée
pcall(B.capture, A, Vector3.zero, nil, function()
	error("boum")
end)
A.bag.wood = nil
G.Joueurs.add(A, "wood", 1)
check("après une erreur, plus de capture", A.bag.wood == 1)

-- ménage
for _, x in B.list() do
	if x.part then x.part:Destroy() end
end
folder:Destroy() -- arrête aussi la boucle d'expiration
floor:Destroy()
shared:Destroy()
return string.format("%d échec(s)\n%s\ntoasts : %s", fails, table.concat(res, "\n"), table.concat(toasts, " | "))
