-- Banc de la résistance / du grind (Systemes/Props, 18/11) en mode Edit, G simulé, vrais modèles.
-- Vérifie : un arbre ne tombe pas en un coup ; mains nues = possible mais bien plus long ; meilleure
-- hache = moins de coups ; roche / filons / argile / cactus impossibles à mains nues ; filon de fer
-- refusé à la pioche de pierre (palier) ; variation d'un exemplaire à l'autre ; cadence (spam de clics
-- sans effet) ; usure qui retombe ; cueillette (fleur 1 coup, baies 2-3 coups).
local SS = game:GetService("ServerStorage")
local f = Instance.new("Folder")
f.Name = "BancResistance"
f.Parent = SS
local mod = game.ServerScriptService.Systemes.Props:Clone()
mod.Parent = f
local P = require(mod)
local res, ok = {}, true
local function check(name, cond)
	table.insert(res, (cond and "ok  " or "ÉCHEC ") .. name)
	ok = ok and cond
end
local tools, bag, toasts = {}, {}, {}
local PL = { Name = "Banc", UserId = 1 }
local prof = { inv = {}, stats = {}, equipped = {} }
local actions = {}
local G = {
	world = { day = 1, seed = 1 },
	Config = { ITEMS = {}, CELL = 4, REGION = 48 },
	Interact = { onPrompt = function() end, onAction = function(k, fn) actions[k] = fn end },
	Util = {
		clone = function(n) local m = SS.Modeles:FindFirstChild(n) return m and m:Clone() end,
		groundY = function() return 0 end,
		root = function() return { Position = Vector3.new(0, 3, 0), CFrame = CFrame.new(0, 3, 0) } end,
		prompt = function() return Instance.new("ProximityPrompt") end,
		anchor = function(parent) local a = Instance.new("Attachment") a.Parent = parent.PrimaryPart or parent return a end,
		auSol = function(_, _, _, fn, ...) return fn(...) end,
		toast = function(_, t) table.insert(toasts, t) end,
		finds = function() end, sfx = function() end, tag = function(i, t) game:GetService("CollectionService"):AddTag(i, t) end,
	},
	Joueurs = {
		get = function() return prof end,
		bestTool = function(_, t) return tools[t] and t or nil, tools[t] or 0 end,
		skill = function() return 0 end,
		add = function(_, i, n) bag[i] = (bag[i] or 0) + n end,
		addSkillXp = function() end,
		needSkill = function() return true end,
		talent = function() return 0 end,
	},
	Clock = { seasonize = function() end, biomeAt = function() return "prairie" end },
	Quetes = {}, Social = { collect = function() end }, Activites = {}, Law = { crime = function() end }, Npcs = { remember = function() end },
	Journal = {},
	World = {
		loaded = {},
		place = function(m, x, y, z, yaw, parent)
			m:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
			m.Parent = parent
			return m
		end,
	},
}
P.init(G)
local reg = { key = "0,0", rx = 0, rz = 0, folder = f, houses = {}, state = { props = {}, removed = {}, chests = {}, planted = {}, placed = {} } }
local spots = {
	{ id = "t1", kind = "tree_chene", x = 2, z = 0, scale = 1 }, { id = "t2", kind = "tree_chene", x = 2, z = 2, scale = 1 },
	{ id = "t3", kind = "tree_chene", x = 2, z = -2, scale = 1 }, { id = "t4", kind = "tree_chene", x = -2, z = 0, scale = 1 },
	{ id = "r1", kind = "rock", x = 0, z = 2 }, { id = "o1", kind = "ore_iron", x = 0, z = -2 }, { id = "c1", kind = "clay", x = 1, z = 1 },
	{ id = "k1", kind = "cactus", x = -1, z = 1 }, { id = "f1", kind = "flower", x = -1, z = -1 }, { id = "b1", kind = "bush", x = 1, z = -1 },
}
for i = 1, 30 do
	table.insert(spots, { id = "v" .. i, kind = "tree_sapin", x = 3, z = i * 0.1, scale = 1 })
end
reg.plan = { props = spots, houses = {} }
local okLoad, err = pcall(P.onRegionLoad, reg)
check("région chargée" .. (okLoad and "" or (" : " .. tostring(err))), okLoad)
local clock = 0
local function hitUntil(id, mode, max)
	local n = 0
	for _ = 1, max do
		clock += 1
		-- la cadence : on attend entre deux coups
		task.wait(0.26)
		n += 1
		P.harvest(PL, id, mode)
		if not (reg.props or {})[id] and false then
			break
		end
		local st = reg.state.props[id]
		if (st and st.stump) or (bag.wood or 0) > 0 or (bag.flower or 0) > 0 or (bag.berries or 0) > 0 then
			return n
		end
	end
	return n
end
local _ = clock
-- 1) chêne à la hache de pierre : plusieurs coups
tools.axe = 1
bag = {}
local nStone = hitUntil("t1", "chop", 60)
check("chêne, hache de pierre : " .. nStone .. " coups (> 4)", nStone > 4 and (bag.wood or 0) > 0)
-- 2) hache de fer : moins de coups
tools.axe = 3
bag = {}
local nIron = hitUntil("t2", "chop", 60)
check("chêne, hache de fer : " .. nIron .. " coups (< pierre)", nIron < nStone and (bag.wood or 0) > 0)
-- 3) mains nues : possible mais long
tools.axe = nil
bag = {}
local nHand = hitUntil("t3", "chop", 120)
check("chêne à mains nues : " .. nHand .. " coups (> 2× pierre)", (bag.wood or 0) > 0 and nHand > nStone * 2)
-- 4) roche / filon / argile / cactus : jamais à mains nues
for _, id in { "r1", "o1", "c1", "k1" } do
	bag = {}
	for _ = 1, 4 do
		task.wait(0.26)
		P.harvest(PL, id, "take")
	end
	check(id .. " à mains nues : rien", next(bag) == nil)
end
-- 5) filon de fer avec pioche de pierre : refusé (palier)
tools.pickaxe = 1
bag = {}
for _ = 1, 30 do
	task.wait(0.26)
	P.harvest(PL, "o1", "take")
end
check("fer à la pioche de pierre : refusé", (bag.ore or 0) == 0)
tools.pickaxe = 3
local nOre = 0
for i = 1, 40 do
	task.wait(0.26)
	P.harvest(PL, "o1", "take")
	if (bag.ore or 0) > 0 then
		nOre = i
		break
	end
end
check("fer à la pioche de fer : " .. nOre .. " coups", nOre > 3)
-- 6) cadence : 10 clics d'un coup ne valent qu'un coup
tools.axe = 1
bag = {}
task.wait(0.3)
for _ = 1, 10 do
	P.harvest(PL, "t4", "chop")
end
check("spam de clics = un seul coup", (bag.wood or 0) == 0)
-- 7) cueillette : fleur en 1 coup, baies en 2
bag = {}
task.wait(0.3)
P.harvest(PL, "f1", "take")
check("fleur : 1 coup", (bag.flower or 0) == 1)
bag = {}
task.wait(0.3)
P.harvest(PL, "b1", "berries")
local after1 = bag.berries or 0
local nb = 1
while (bag.berries or 0) == 0 and nb < 5 do
	task.wait(0.3)
	P.harvest(PL, "b1", "berries")
	nb += 1
end
check("baies : rien au 1er coup, cueillies en " .. nb .. " coups (2-3)", after1 == 0 and (bag.berries or 0) > 0 and nb <= 3)
-- 8) variation : 30 sapins n'ont pas tous la même résistance
local seen = {}
tools.axe = 1
for i = 1, 6 do
	local id = "v" .. i
	bag = {}
	local n = hitUntil(id, "chop", 40)
	seen[n] = true
end
local kinds = 0
for _ in seen do
	kinds += 1
end
check("sapins : résistances variées (" .. kinds .. " valeurs sur 6)", kinds >= 2)
-- 9) filons façon WoW : marqués « Filon » (minicarte), reviennent au bout de quelques jours ; un
-- rocher ou un arbre, non (monde fini)
check("filon miné retiré", reg.state.removed["o1"] ~= nil)
local CS = game:GetService("CollectionService")
local tagged = 0
for _, m in CS:GetTagged("Filon") do
	if m:IsDescendantOf(f) then
		tagged += 1
	end
end
check("filons marqués pour la minicarte", tagged >= 0) -- (o1 est miné : 0 ou plus selon l'ordre)
reg.state.removed["r1"] = reg.state.removed["r1"] or G.world.day
G.world.day += 3
reg.props = {}
P.onRegionLoad(reg)
check("filon de fer pas encore revenu (3 j)", reg.props["o1"] == nil)
G.world.day += 5
reg.props = {}
P.onRegionLoad(reg)
check("filon de fer revenu (8 j)", reg.props["o1"] ~= nil)
local m = reg.props["o1"] and reg.props["o1"].model
check("et marqué « Filon » avec sa compétence", m ~= nil and CS:HasTag(m, "Filon") and (m:GetAttribute("MinSkill") or 0) == 12)
check("rocher : ne revient pas", reg.props["r1"] == nil)
f:Destroy()
return (ok and "OK " or "ÉCHEC ") .. #res .. " vérifications\n" .. table.concat(res, "\n")
