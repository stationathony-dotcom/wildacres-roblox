-- Banc Edit (21/11, lot C12) : coûts serveur mesurables sans Play — génération d'un plan de région (ce que
-- paie le serveur quand un joueur traverse l'île), scans ajoutés par-dessus (cascades), et comptage des
-- bêtes (quête troupeau). Rend des chiffres pour docs/PERFORMANCE.md ; ROUGE si un budget est dépassé.
local SS = game:GetService("ServerStorage")
local f = game.ReplicatedStorage.Shared:Clone()
f.Name = "BancPerf"
f.Parent = SS
local WG = require(f.RegionPlan)
local Config = require(f.Config)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local BUDGET = { plan = 150, planMax = 400, cascade = 8, herd = 2 } -- ms (PC portable : prudents)

-- 1. plans de région (graine neuve : pas de cache)
local w = WG.new(31337, WG.CURRENT_GEN)
local times, n = {}, 0
for rx = -4, 4, 2 do
	for rz = -4, 4, 2 do
		if WG.inWorld(rx, rz) then
			local t0 = os.clock()
			local ok = pcall(w.plan, w, rx, rz)
			local ms = (os.clock() - t0) * 1000
			if ok then
				table.insert(times, ms)
				n += 1
			end
			task.wait()
		end
	end
end
table.sort(times)
local sum = 0
for _, t in times do
	sum += t
end
local avg, med, mx = sum / math.max(1, n), times[math.max(1, n // 2)] or 0, times[n] or 0
check(string.format("plan de région : moyenne %.0f ms, médiane %.0f, max %.0f (%d régions ; budget %d / %d)", avg, med, mx, n, BUDGET.plan, BUDGET.planMax),
	avg <= BUDGET.plan and mx <= BUDGET.planMax)

-- 1 bis. avec les pauses du serveur (WG.pauseHook) : plus long bloc d'un seul tenant
local w2 = WG.new(4711, WG.CURRENT_GEN)
local longest, last = 0, 0
WG.pauseHook = function()
	local now = os.clock()
	longest = math.max(longest, (now - last) * 1000)
	task.wait()
	last = os.clock()
end
for rx = -2, 2, 2 do
	for rz = -2, 2, 2 do
		if WG.inWorld(rx, rz) then
			last = os.clock()
			pcall(w2.plan, w2, rx, rz)
			longest = math.max(longest, (os.clock() - last) * 1000)
		end
	end
end
WG.pauseHook = nil
check(string.format("avec les pauses : plus long bloc sans céder la main %.0f ms (au lieu de ~%.0f ; budget 60)", longest, avg), longest <= 60)

-- 2. scan des cascades sur un plan réel
local C = assert(loadstring(game.ServerScriptService.Systemes.Cascades.Source, "Cascades"))()
C.init({ Config = Config, WG = WG, Interact = { onPrompt = function() end } })
local p = w:plan(2, 2)
local t0 = os.clock()
for _ = 1, 10 do
	C.site(p, Random.new(1))
end
local cms = (os.clock() - t0) * 100
check(string.format("recherche d'une falaise à cascade : %.2f ms par région (budget %d)", cms, BUDGET.cascade), cms <= BUDGET.cascade)

-- 3. comptage des bêtes d'un joueur (quête troupeau, toutes les 3 s) : 40 régions × 30 bêtes
local A = require(game.ServerScriptService.Systemes.Animals:Clone())
local regions = {}
for r = 1, 40 do
	local list = {}
	for i = 1, 30 do
		list[i] = { owner = (i % 3 == 0) and "u1" or "u2" }
	end
	regions["r" .. r] = { animals = list }
end
pcall(A.init, { world = { regions = regions }, Config = Config })
t0 = os.clock()
local cnt = 0
for _ = 1, 20 do
	cnt = A.ownedBy("u1")
end
local hms = (os.clock() - t0) * 1000 / 20
check(string.format("compter ses bêtes (1 200 bêtes au monde) : %.3f ms, trouvé %d (budget %d)", hms, cnt, BUDGET.herd), hms <= BUDGET.herd and cnt == 400)
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
