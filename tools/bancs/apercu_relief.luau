-- Aperçu du relief (26/11, gen 3) — mode Édition. Écrit le VRAI terrain de quelques régions (même algorithme que
-- World.writeTerrain) pour le regarder et le capturer dans Studio, et chronomètre plan + écriture.
--   loadstring(src)({ graine = 7, gen = 3, rayon = 1 })        -- 3 x 3 régions autour du sommet
--   loadstring(src)({ effacer = true, graine = 7, gen = 3 })   -- efface ce qui a été écrit
-- Ne touche qu'au Terrain des régions visées (vérifier qu'elles sont vides avant : voir docs/PROCEDURES.md).

local args = ... or {}
local f = game.ReplicatedStorage.Shared:Clone()
local WG = require(f.RegionPlan)
local Config = require(f.Config)
local CELL, REGION = Config.CELL, Config.REGION
local w = WG.new(args.graine or 7, args.gen or 3)
local s = w:summit()
local cx, cz = math.floor(s[1] / REGION), math.floor(s[2] / REGION)
local R = args.rayon or 1
local Mat = Enum.Material
local out = {}

local function region3(rx, rz, ny)
	return Region3.new(
		Vector3.new(rx * REGION * CELL, Config.Y_MIN, rz * REGION * CELL),
		Vector3.new((rx + 1) * REGION * CELL, Config.Y_MIN + ny * 4, (rz + 1) * REGION * CELL)
	)
end

if args.effacer then
	local ny = math.floor((Config.Y_MAX - Config.Y_MIN) / 4)
	for rx = cx - R, cx + R do
		for rz = cz - R, cz + R do
			workspace.Terrain:FillRegion(region3(rx, rz, ny), 4, Mat.Air)
		end
	end
	f:Destroy()
	return "effacé"
end

local idx = WG.idx
local tPlan, tWrite, maxH, cliffs = 0, 0, 0, 0
for rx = cx - R, cx + R do
	for rz = cz - R, cz + R do
		local t0 = os.clock()
		local plan = w:plan(rx, rz)
		tPlan += os.clock() - t0
		local H, mat, water = plan.H, plan.mat, plan.water
		local top = Config.WATER_Y
		for _, h in H do
			top = math.max(top, h)
		end
		maxH = math.max(maxH, top)
		local ny = math.min(math.floor((Config.Y_MAX - Config.Y_MIN) / 4), math.ceil((top + 8 - Config.Y_MIN) / 4))
		local mats, occs = table.create(REGION), table.create(REGION)
		for x = 1, REGION do
			local mx, ox = table.create(ny), table.create(ny)
			for y = 1, ny do
				mx[y] = table.create(REGION, Mat.Air)
				ox[y] = table.create(REGION, 0)
			end
			mats[x], occs[x] = mx, ox
		end
		for lz = 0, REGION - 1 do
			for lx = 0, REGION - 1 do
				local i = idx(lx, lz)
				local h = H[i]
				local tm = mat[i]
				local minN = math.min(H[idx(lx + 1, lz)], H[idx(lx - 1, lz)], H[idx(lx, lz + 1)], H[idx(lx, lz - 1)])
				local cliff = (h - minN) > 5
				if cliff then
					cliffs += 1
				end
				local mx, ox = mats[lx + 1], occs[lx + 1]
				for k = 1, ny do
					local yb = Config.Y_MIN + (k - 1) * 4
					local yt = yb + 4
					local m, o = Mat.Air, 0
					if yt <= h then
						o = 1
						if yt > h - 4 then
							m = tm
						elseif cliff and yb >= minN - 4 then
							m = plan.cliff or Mat.Rock
						else
							m = (tm == Mat.Sand) and Mat.Sand or Mat.Ground
						end
					elseif yb < h then
						m = tm
						o = math.max(0.05, (h - yb) / 4)
					elseif water[i] and yt <= Config.WATER_Y then
						m = Mat.Water
						o = 1
					end
					mx[k][lz + 1] = m
					ox[k][lz + 1] = o
				end
			end
		end
		local t1 = os.clock()
		workspace.Terrain:WriteVoxels(region3(rx, rz, ny), 4, mats, occs)
		tWrite += os.clock() - t1
		task.wait()
	end
end
local n = (2 * R + 1) ^ 2
table.insert(out, ("%d régions autour du sommet (%d,%d) : plan %.0f ms/région, écriture %.0f ms/région, hauteur max %.0f, cases de falaise %d")
	:format(n, cx, cz, tPlan / n * 1000, tWrite / n * 1000, maxH, cliffs))
table.insert(out, ("centre en studs : %.0f, %.0f"):format((cx + 0.5) * REGION * CELL, (cz + 0.5) * REGION * CELL))
f:Destroy()
return table.concat(out, "\n")
