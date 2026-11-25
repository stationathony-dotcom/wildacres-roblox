-- Banc du lointain (chantier B, 25/11) — mode Edit. Graine 7, générateur 2.
-- B5 budget : au plus 3 500 rangées (blocs) autour du point de départ, au plus 4 500 n'importe où sur l'île
-- B6 aucune rangée dans une région chargée (3 x 3 autour du joueur)
-- B7 déterministe : deux calculs donnent les mêmes rangées
-- B8 massifs au large : tous au-delà des îlots (12,9 régions + 120 studs), hauts de 600 studs au moins
-- B9 fidèle au monde : sur 300 cases de terre tirées au sort, le palier (plateau) du lointain = celui du
--    vrai plan dans ≥ 85 % des cas, et la mer/le lac du lointain tombe sur de l'eau du plan dans ≥ 85 %
local sh = game.ReplicatedStorage.Shared:Clone()
sh.Parent = game:GetService("ServerStorage")
local Config = require(sh.Config)
local WG = require(sh.RegionPlan)
local L = require(sh.Lointain)
local fails = {}
local wg = WG.new(7, 2)
local SPAN = Config.CELL * Config.REGION

local function skipAround(x, z)
	local s = {}
	local rx, rz = math.floor(x / SPAN), math.floor(z / SPAN)
	for dx = -1, 1 do
		for dz = -1, 1 do
			s[(rx + dx) .. "," .. (rz + dz)] = true
		end
	end
	return s
end

local worst = 0
for _, p in { { 100, 100 }, { 1200, -800 }, { -1800, 400 }, { 0, 2300 } } do
	local skip = skipAround(p[1], p[2])
	local rows = L.layout(wg, p[1], p[2], skip)
	worst = math.max(worst, #rows)
	for _, r in rows do
		for x = r.x0 + r.step / 2, r.x1 - r.step / 2 + 0.01, r.step do
			if skip[L.regionKey(x, r.z)] then
				table.insert(fails, string.format("B6 rangée dans une région chargée (%d,%d)", x, r.z))
				break
			end
		end
		if #fails > 5 then
			break
		end
	end
	if p[1] == 100 and #rows > 3500 then
		table.insert(fails, "B5 départ : " .. #rows .. " rangées")
	end
	task.wait()
end
if worst > 4500 then
	table.insert(fails, "B5 pire cas : " .. worst .. " rangées")
end

local a = L.layout(wg, 333, -222, {})
local b = L.layout(wg, 333, -222, {})
if #a ~= #b then
	table.insert(fails, "B7 pas déterministe")
else
	for i = 1, #a do
		if a[i].top ~= b[i].top or a[i].x0 ~= b[i].x0 then
			table.insert(fails, "B7 rangée " .. i .. " diffère")
			break
		end
	end
end

local isletMax = 12.9 * SPAN + 120
for i, m in L.massifs(7, WG.hash) do
	local d = math.sqrt(m.x * m.x + m.z * m.z) - m.base * 0.5
	if d < isletMax then
		table.insert(fails, string.format("B8 massif %d trop près (%.0f < %.0f)", i, d, isletMax))
	end
	if m.height < 600 then
		table.insert(fails, "B8 massif " .. i .. " trop bas")
	end
end

-- fidélité : on compare au vrai plan de région (RegionPlan) sur des cases tirées au sort
local rng = Random.new(42)
local land, landOk, wet, wetOk = 0, 0, 0, 0
local tries = 0
while (land < 300 or wet < 60) and tries < 2500 do
	tries += 1
	local cx = rng:NextInteger(-560, 560)
	local cz = rng:NextInteger(-560, 560)
	local rx, rz = WG.regionOf(cx, cz)
	if WG.inWorld(rx, rz) then
		local plan = wg.planCache[rx .. "," .. rz] or wg:plan(rx, rz)
		local i = WG.idx(cx - plan.x0, cz - plan.z0)
		local s = L.sample(wg, (cx + 0.5) * Config.CELL, (cz + 0.5) * Config.CELL)
		if plan.water[i] then
			if s.kind ~= "terre" then
				wetOk += 1
			end
			wet += 1
		elseif plan.distW[i] > 3 and plan.roadD[i] > 6 and not plan.inPoi[i] then
			land += 1
			if s.kind == "terre" and (s.level or 0) == (plan.level[i] or 0) then
				landOk += 1
			end
		end
	end
	if tries % 40 == 0 then
		task.wait()
	end
end
local landRate = land > 0 and landOk / land or 0
local wetRate = wet > 0 and wetOk / wet or 0
if landRate < 0.85 then
	table.insert(fails, string.format("B9 paliers fidèles %.0f %% (%d/%d)", landRate * 100, landOk, land))
end
if wetRate < 0.85 then
	table.insert(fails, string.format("B9 eau fidèle %.0f %% (%d/%d)", wetRate * 100, wetOk, wet))
end
sh:Destroy()
local summary = string.format("pire cas %d rangées ; paliers %.0f %%, eau %.0f %%", worst, landRate * 100, wetRate * 100)
if #fails == 0 then
	return "lointain OK : " .. summary
end
return "ÉCHEC lointain : " .. #fails .. " problème(s) — " .. summary .. "\n" .. table.concat(fails, "\n")
