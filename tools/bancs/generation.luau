-- Banc de la génération (étape 3A) — execute_luau en mode Edit (~40 s).
-- Clone Shared pour contourner le cache de require du MCP, génère TOUTES les régions de l'île
-- pour plusieurs graines et compte les défauts. Attendu (gen 1, 17/11/2026) : houseOverlap 0,
-- houseWater 0, propInHouse 0, flooded 0, starts 1, err nil pour chaque graine.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
f.Name = "SharedBanc" .. math.random(1, 1e6)
local WG = require(f.RegionPlan)
local Config = require(f.Config)
local CELL, REGION = Config.CELL, Config.REGION
local res = {}
-- arguments facultatifs : loadstring(src)({ graines }, gen) ; par défaut 4 graines, version courante
local SEEDS, GEN = ...
for _, seed in SEEDS or { 4242, 1, 77777, 123456789 } do
	local w = WG.new(seed, GEN or WG.CURRENT_GEN)
	local st = { regions = 0, houses = 0, houseOverlap = 0, houseWater = 0, propInHouse = 0, flooded = 0, starts = 0, kinds = {}, biomes = {} }
	local R = Config.WORLD_RADIUS + 1
	for rx = -R, R do
		for rz = -R, R do
			if WG.inWorld(rx, rz) then
				local ok, p = pcall(w.plan, w, rx, rz)
				if ok and p then
					st.regions += 1
					st.biomes[p.biome] = (st.biomes[p.biome] or 0) + 1
					local poi = w:poiOf(rx, rz)
					if poi then
						st.kinds[poi.kind] = (st.kinds[poi.kind] or 0) + 1
						if poi.start then
							st.starts += 1
						end
						local wet, n = 0, 0
						for x = poi.x0 - rx * REGION, poi.x0 - rx * REGION + poi.w - 1 do
							for z = poi.z0 - rz * REGION, poi.z0 - rz * REGION + poi.d - 1 do
								n += 1
								if p.water[WG.idx(x, z)] then
									wet += 1
								end
							end
						end
						if wet / n > 0.2 then
							st.flooded += 1
						end
					end
					for i, h in p.houses do
						st.houses += 1
						local lx, lz = math.floor(h.x / CELL) - rx * REGION, math.floor(h.z / CELL) - rz * REGION
						if lx >= -4 and lx < REGION + 4 and lz >= -4 and lz < REGION + 4 and p.water[WG.idx(lx, lz)] then
							st.houseWater += 1
						end
						for j = i + 1, #p.houses do
							local o = p.houses[j]
							if math.abs(o.x - h.x) < 20 and math.abs(o.z - h.z) < 20 then
								st.houseOverlap += 1
							end
						end
						for _, pr in p.props do
							if (pr.kind == "tree" or pr.kind == "rock" or pr.kind == "cactus" or pr.kind == "ore")
								and math.abs(pr.x - h.x) < 9 and math.abs(pr.z - h.z) < 9 then
								st.propInHouse += 1
							end
						end
					end
				else
					st.err = (st.err or 0) + 1
					st.lastErr = tostring(p)
				end
			end
		end
		task.wait()
	end
	st.theme = w.theme and w.theme.id or "gen1"
	res[tostring(seed)] = st
end
f:Destroy()
return game:GetService("HttpService"):JSONEncode(res)
