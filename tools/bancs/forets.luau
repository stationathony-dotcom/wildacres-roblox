-- Banc des forêts qui repoussent (27/11, Systemes/Props) en mode Edit :
--   souche → arbre après 12 jours, arbre déraciné → revient après 24 jours,
--   MAIS rien ne repousse à moins de 14 studs d'une construction ou d'un objet posé (accord du propriétaire).
local SS = game:GetService("ServerStorage")
local f = game.ReplicatedStorage.Shared:Clone()
f.Name = "BancForets"
f.Parent = SS
local ps = game.ServerScriptService.Systemes.Props:Clone()
ps.Parent = f
local Config = require(f.Config)
local res, ok = {}, true
local function check(name, cond)
	table.insert(res, (cond and "ok  " or "ÉCHEC ") .. name)
	ok = ok and cond
end
local P = require(ps)
local bag, skill = {}, 0
local PL = { Name = "Banc", UserId = 1 }
local G = {
	world = { day = 1, seed = 1 },
	Config = Config,
	Interact = { onPrompt = function() end, onAction = function() end },
	Util = { geste = function() end,
		clone = function(n) local m = SS.Modeles:FindFirstChild(n) return m and m:Clone() end,
		groundY = function() return 0 end,
		root = function() return { Position = Vector3.new(0, 3, 0), CFrame = CFrame.new(0, 3, 0) } end,
		prompt = function() return Instance.new("ProximityPrompt") end,
		anchor = function(parent) local a = Instance.new("Attachment") a.Parent = parent.PrimaryPart or parent return a end,
		auSol = function(_, _, _, fn, ...) return fn(...) end,
		toast = function() end, finds = function() end, sfx = function() end,
		tag = function(i, t) game:GetService("CollectionService"):AddTag(i, t) end,
	},
	Joueurs = {
		get = function() return { inv = {}, stats = {}, equipped = {} } end,
		bestTool = function() return nil, 0 end,
		skill = function() return skill end,
		add = function(_, i, n) bag[i] = (bag[i] or 0) + n end,
		addSkillXp = function() end,
		needSkill = function(_, _, lvl) return skill >= lvl end,
		talent = function() return 0 end,
	},
	Clock = { seasonize = function() end, biomeAt = function() return "prairie" end },
	Quetes = {}, Social = { collect = function() end, bump = function() end }, Activites = {}, Law = { crime = function() end }, Npcs = { remember = function() end },
	Journal = {},
	World = { loaded = {}, place = function(m, x, y, z, yaw, parent) m:PivotTo(CFrame.new(x, y, z)) m.Parent = parent return m end },
}
P.init(G)
local reg = { key = "0,0", rx = 0, rz = 0, folder = f, houses = {}, state = { props = {}, removed = {}, chests = {}, planted = {}, placed = {}, built = {} } }
reg.plan = { props = {
	{ id = "arA", kind = "tree_chene", x = 0, z = 60 },   -- déraciné, au large : revient
	{ id = "arB", kind = "tree_chene", x = 45, z = 0 },   -- déraciné, près d'un mur : ne revient pas
	{ id = "arC", kind = "tree_sapin", x = 0, z = -60 },  -- souche au large : repousse
	{ id = "arD", kind = "tree_sapin", x = -45, z = 0 },  -- souche près d'un coffre posé : reste souche
}, houses = {} }
reg.state.removed.arA, reg.state.removed.arB = 1, 1
reg.state.props.arC = { stump = true, day = 1 }
reg.state.props.arD = { stump = true, day = 1 }
reg.state.built = { { id = "b1", b = "mur", x = 40, y = 0, z = 0 } }
reg.state.placed = { { id = "p1", item = "chest", x = -40, z = 0 } }
local function load(day)
	G.world.day = day
	reg.props = {}
	for _, c in f:GetChildren() do
		if c:IsA("Folder") and c.Name == "Objets" then c:Destroy() end
	end
	P.onRegionLoad(reg)
end
load(10)
check("jour 10 : souche C encore souche", reg.state.props.arC and reg.state.props.arC.stump == true)
check("jour 10 : arbre A pas encore revenu", reg.props.arA == nil)
load(14)
check("jour 14 : souche C redevenue arbre", not (reg.state.props.arC and reg.state.props.arC.stump))
check("jour 14 : souche D près d'un objet posé : reste souche", reg.state.props.arD and reg.state.props.arD.stump == true)
load(26)
check("jour 26 : arbre A déraciné revenu", reg.props.arA ~= nil and reg.state.removed.arA == nil)
check("jour 26 : arbre B près d'une construction : pas revenu", reg.props.arB == nil and reg.state.removed.arB ~= nil)
f:Destroy()
return (ok and "OK " or "ÉCHEC ") .. #res .. " vérifications\n" .. table.concat(res, "\n")
