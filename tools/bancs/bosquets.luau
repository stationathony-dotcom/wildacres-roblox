-- Banc des bosquets (Systemes/Bosquets) en mode Edit : sur 3 graines, arbres ajoutés près des
-- villages, identifiants uniques et stables (même tirage si le plan est refait), jamais sur l'eau ni
-- une route, jamais collés à un autre objet, rien dans les régions loin des villages.
local SS = game:GetService("ServerStorage")
local f = game.ReplicatedStorage.Shared:Clone()
f.Name = "SharedBanc" .. math.random(1, 1e6)
f.Parent = SS
local sys = game.ServerScriptService.Systemes.Bosquets:Clone()
sys.Parent = f
local WG = require(f.RegionPlan)
local Config = require(f.Config)
local B = require(sys)
local lines, okAll = {}, true
for _, seed in { 4242, 1, 77777 } do
	local wg = WG.new(seed, WG.CURRENT_GEN)
	B.init({ Config = Config, WG = WG, wg = wg, world = { seed = seed } })
	local regions, added, bad, dup, unstable, far = 0, 0, 0, 0, 0, 0
	local ids = {}
	for rx = -6, 6 do
		for rz = -6, 6 do
			if WG.inWorld(rx, rz) then
				local plan = wg:plan(rx, rz)
				local before = #plan.props
				local n = B.extend(plan, rx, rz)
				if n > 0 then
					regions += 1
					added += n
					for i = before + 1, #plan.props do
						local p = plan.props[i]
						if ids[p.id] then
							dup += 1
						end
						ids[p.id] = true
						local lx, lz = math.floor(p.x / Config.CELL) - plan.x0, math.floor(p.z / Config.CELL) - plan.z0
						local ci = WG.idx(lx, lz)
						if plan.water[ci] or plan.roadD[ci] <= 3 then
							bad += 1
						end
						for j = 1, before do
							local q = plan.props[j]
							if q.x and (Vector2.new(q.x, q.z) - Vector2.new(p.x, p.z)).Magnitude < 5 then
								bad += 1
								break
							end
						end
					end
					-- même tirage sur un plan refait
					local again = WG.new(seed, WG.CURRENT_GEN):plan(rx, rz)
					B.extend(again, rx, rz)
					if #again.props ~= #plan.props or again.props[#again.props].id ~= plan.props[#plan.props].id then
						unstable += 1
					end
				elseif not wg:poiOf(rx, rz) then
					local nearV = false
					for dx = -1, 1 do
						for dz = -1, 1 do
							local poi = wg:poiOf(rx + dx, rz + dz)
							if poi and poi.kind == "village" then
								nearV = true
							end
						end
					end
					if not nearV and plan.bosquets ~= 0 then
						far += 1
					end
				end
			end
		end
		task.wait()
	end
	local ok = added > 0 and bad == 0 and dup == 0 and unstable == 0 and far == 0
	okAll = okAll and ok
	table.insert(lines, string.format("graine %d : %d régions, %d arbres ajoutés ; mal placés %d, doublons %d, instables %d, loin %d", seed, regions, added, bad, dup, unstable, far))
end
f:Destroy()
return (okAll and "OK\n" or "ÉCHEC\n") .. table.concat(lines, "\n")
