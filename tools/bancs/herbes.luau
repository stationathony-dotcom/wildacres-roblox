-- Banc de l'herboristerie (Systemes/Herbes + Props « herb ») en mode Edit :
--   1. génération sur 3 graines : plantes ajoutées hors villages, ids uniques, jamais dans l'eau ;
--   2. Props : la plante prend sa couleur, se cueille (2 coups selon la résistance), donne son
--      objet, la plante rare refuse sans compétence, repousse au bout de 4 jours, marquée « Herbe ».
local SS = game:GetService("ServerStorage")
local f = game.ReplicatedStorage.Shared:Clone()
f.Name = "BancHerbes"
f.Parent = SS
local hs = game.ServerScriptService.Systemes.Herbes:Clone()
hs.Parent = f
local ps = game.ServerScriptService.Systemes.Props:Clone()
ps.Parent = f
local WG = require(f.RegionPlan)
local Config = require(f.Config)
local H = require(hs)
local res, ok = {}, true
local function check(name, cond)
	table.insert(res, (cond and "ok  " or "ÉCHEC ") .. name)
	ok = ok and cond
end
-- 1) génération
for _, seed in { 4242, 1, 77777 } do
	local wg = WG.new(seed, WG.CURRENT_GEN)
	H.init({ Config = Config, WG = WG, wg = wg, world = { seed = seed } })
	local n, bad, ids, kinds = 0, 0, {}, {}
	for rx = -4, 4 do
		for rz = -4, 4 do
			if WG.inWorld(rx, rz) then
				local plan = wg:plan(rx, rz)
				local before = #plan.props
				H.extend(plan, rx, rz)
				for i = before + 1, #plan.props do
					local p = plan.props[i]
					n += 1
					kinds[p.herb] = true
					local lx, lz = math.floor(p.x / Config.CELL) - plan.x0, math.floor(p.z / Config.CELL) - plan.z0
					if ids[p.id] or plan.water[WG.idx(lx, lz)] or not Config.ITEMS[p.herb] then
						bad += 1
					end
					ids[p.id] = true
				end
			end
		end
		task.wait()
	end
	local k = 0
	for _ in kinds do
		k += 1
	end
	check(string.format("graine %d : %d plantes, %d sortes, %d mal placées", seed, n, k, bad), n > 50 and k >= 4 and bad == 0)
end
-- 2) cueillette avec Props (G simulé)
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
local reg = { key = "0,0", rx = 0, rz = 0, folder = f, houses = {}, state = { props = {}, removed = {}, chests = {}, planted = {}, placed = {} } }
reg.plan = { props = {
	{ id = "hbA", kind = "herb", herb = "chamomile", skill = 0, color = Color3.fromRGB(250, 245, 200), x = 1, z = 0 },
	{ id = "hbB", kind = "herb", herb = "mandrake", skill = 18, color = Color3.fromRGB(150, 90, 170), x = -1, z = 0 },
}, houses = {} }
P.onRegionLoad(reg)
local m = reg.props.hbB and reg.props.hbB.model
local fl = m and m:FindFirstChild("Fleur")
check("plante posée, fleurs à sa couleur", fl ~= nil and fl.Color == Color3.fromRGB(150, 90, 170))
check("marquée « Herbe » avec sa compétence", m ~= nil and game:GetService("CollectionService"):HasTag(m, "Herbe") and m:GetAttribute("MinSkill") == 18)
local hits = 0
while not bag.chamomile and hits < 5 do
	task.wait(0.3)
	P.harvest(PL, "hbA", "take")
	hits += 1
end
check("camomille cueillie en " .. hits .. " coup(s)", (bag.chamomile or 0) >= 1 and hits <= 3)
for _ = 1, 4 do
	task.wait(0.3)
	P.harvest(PL, "hbB", "take")
end
check("mandragore sans compétence : refusée", bag.mandrake == nil)
skill = 20
local t = 0
while not bag.mandrake and t < 5 do
	task.wait(0.3)
	P.harvest(PL, "hbB", "take")
	t += 1
end
check("mandragore avec agriculture 20 : cueillie", (bag.mandrake or 0) >= 1)
G.world.day = 3
reg.props = {}
P.onRegionLoad(reg)
check("pas repoussée au bout de 2 jours", reg.props.hbA == nil)
G.world.day = 6
reg.props = {}
P.onRegionLoad(reg)
check("repoussée au bout de 5 jours", reg.props.hbA ~= nil)
f:Destroy()
return (ok and "OK " or "ÉCHEC ") .. #res .. " vérifications\n" .. table.concat(res, "\n")
