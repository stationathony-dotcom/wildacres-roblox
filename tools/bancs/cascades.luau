-- Banc Edit (21/11) : cascades (Systemes/Cascades) — vraie génération sur 2 graines : combien de régions en
-- ont, le site est bien une falaise (dénivelé ≥ 5, hors eau / route / lieu), même tirage à chaque fois ;
-- puis le remplissage du seau (seau vide pris, seau plein rendu, refus sans seau).
local SS = game:GetService("ServerStorage")
local f = game.ReplicatedStorage.Shared:Clone()
f.Name = "BancCascades"
f.Parent = SS
local WG = require(f.RegionPlan)
local Config = require(f.Config)
local C = assert(loadstring(game.ServerScriptService.Systemes.Cascades.Source, "Cascades"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local bag, toasts = { bucket_empty = 0 }, {}
local G = {
	Config = Config, WG = WG, world = { seed = 4242 },
	Interact = { onPrompt = function() end },
	Util = { root = function() return { Position = Vector3.new(0, 0, 0) } end, toast = function(_, t, k) table.insert(toasts, k) end, prompt = function() end },
	Joueurs = { take = function(_, i, n) if (bag[i] or 0) < n then return false end bag[i] -= n return true end,
		add = function(_, i, n) bag[i] = (bag[i] or 0) + n end, sync = function() end },
}
C.init(G)
local total, withCliff, bad = 0, 0, 0
for _, seed in { 4242, 77777 } do
	local w = WG.new(seed, WG.CURRENT_GEN)
	local R = Config.WORLD_RADIUS
	for rx = -R, R, 2 do
		for rz = -R, R, 2 do
			if WG.inWorld(rx, rz) then
				local ok, p = pcall(w.plan, w, rx, rz)
				if ok and p and not p.poi then
					total += 1
					local s1 = C.site(p, Random.new(WG.hash(seed, "cascade", rx, rz)))
					local s2 = C.site(p, Random.new(WG.hash(seed, "cascade", rx, rz)))
					if s1 then
						withCliff += 1
						if s1.top - s1.bottom < C.MIN_DROP or s1.x ~= s2.x or s1.z ~= s2.z then
							bad += 1
						end
					end
				end
			end
			task.wait()
		end
	end
end
check(string.format("régions sauvages avec une falaise possible : %d / %d", withCliff, total), withCliff > 0)
check("sites valides (dénivelé ≥ 5) et même tirage à chaque fois", bad == 0)
-- seau
local pool = Instance.new("Part")
pool.Position = Vector3.new(3, 0, 0)
local pr = Instance.new("ProximityPrompt")
pr.Parent = pool
check("sans seau vide : refusé avec motif", C.fill({ UserId = 1 }, pr) == false and toasts[#toasts] == "refus")
bag.bucket_empty = 2
check("avec un seau vide : seau plein", C.fill({ UserId = 1 }, pr) == true and bag.bucket == 1 and bag.bucket_empty == 1)
pool.Position = Vector3.new(40, 0, 0)
check("trop loin : rien", C.fill({ UserId = 1 }, pr) == false and bag.bucket_empty == 1)
pool:Destroy()
f:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
