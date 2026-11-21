-- Banc Edit (21/11) : route encombrée (Systemes/Evenements) — point sur une route, outil requis, usure,
-- matière + pièces + honneur au dernier coup. G simulé, aucune région réelle.
local E = assert(loadstring(game.ServerScriptService.Systemes.Evenements.Source, "Evenements"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local P = { UserId = 1, Name = "Alix" }
local ROOT = { Position = Vector3.new(100, 0, 100) }
local bag, worn, honor, toasts, prompts = {}, {}, 0, {}, {}
-- une région « 0,0 » de 64 × 64 cases ; route sur la colonne cx = 30
local roadD, water = {}, {}
local function idx(lx, lz) return lz * 64 + lx + 1 end
for lx = 0, 63 do
	for lz = 0, 63 do
		roadD[idx(lx, lz)] = math.abs(lx - 30)
	end
end
local G = {
	Config = { CELL = 4, ITEMS = {} },
	Bestiaire = { ROAMING = {} },
	Interact = { onPrompt = function(k, f) prompts[k] = f end, onAction = function() end },
	Game = { players = function() return { P } end },
	WG = { regionOf = function(cx, cz) return math.floor(cx / 64), math.floor(cz / 64) end, idx = idx },
	World = { loaded = { ["0,0"] = { ready = true, plan = { x0 = 0, z0 = 0, roadD = roadD, water = water, poi = nil } } } },
	Util = { root = function() return ROOT end, groundY = function() return 0 end, isWater = function() return false end,
		toast = function(_, t, k) table.insert(toasts, { t, k }) end, prompt = function() end, sfx = function() end },
	Joueurs = {
		bestTool = function(_, base) return bag[base] and base or nil, 1 end,
		wearTool = function(_, base, n) worn[base] = (worn[base] or 0) + (n or 1) end,
		add = function(_, i, n) bag[i] = (bag[i] or 0) + n end, sync = function() end, addSkillXp = function() end,
	},
	Law = { addHonor = function(_, n) honor += n end },
}
E.init(G)
local pos = E.roadSpot(40, 140)
check("point trouvé sur la route (case 30 ± 1)", pos ~= nil and math.abs(math.floor(pos.X / 4) - 30) < 1)
-- un tronc : à mains nues, refusé ; à la hache, 3 coups
local m = Instance.new("Part")
m.Position = ROOT.Position
m:SetAttribute("Debris", "log")
m:SetAttribute("Hits", 0)
local prompt = Instance.new("ProximityPrompt")
prompt.Parent = m
E.handlers.debris(P, prompt)
check("sans hache : refusé, avec un motif", (m:GetAttribute("Hits") or 0) == 0 and toasts[#toasts][2] == "refus")
bag.axe = 1
E.handlers.debris(P, prompt)
E.handlers.debris(P, prompt)
check("2 coups : pas encore dégagé", m.Parent == nil and m:GetAttribute("Hits") == 2 and (bag.wood or 0) == 0)
m.Parent = workspace
E.handlers.debris(P, prompt)
check("3e coup : bois, pièces, honneur, et le tronc disparaît", (bag.wood or 0) >= 3 and (bag.gold or 0) >= 4 and honor == 1 and m.Parent == nil)
check("la hache s'use à chaque coup (3)", worn.axe == 3)
-- trop loin : rien
local r = Instance.new("Part")
r.Position = ROOT.Position + Vector3.new(40, 0, 0)
r:SetAttribute("Debris", "rock")
local pr = Instance.new("ProximityPrompt")
pr.Parent = r
bag.pickaxe = 1
E.handlers.debris(P, pr)
check("trop loin : rien", (r:GetAttribute("Hits") or 0) == 0)
r:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
