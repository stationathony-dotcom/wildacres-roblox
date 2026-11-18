-- Empreinte des tenues de PNJ d'une île (pour vérifier qu'un changement ne modifie pas les mondes
-- existants) : loadstring(src)(graine, gen) → texte. Comparer avant / après une modification.
local seed, gen = ...
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local WG = require(f.RegionPlan)
local w = WG.new(seed or 4242, gen or 1)
local out, n = {}, 0
for rx = -6, 6 do
	for rz = -6, 6 do
		local poi = w:poiOf(rx, rz)
		if poi and (poi.kind == "village" or poi.kind == "farm") then
			local ok, p = pcall(w.plan, w, rx, rz)
			if ok and p then
				for _, npc in p.npcs or {} do
					local l = npc.look
					if l then
						n += 1
						table.insert(out, table.concat({ l.skin, l.hair, l.hairColor, l.shirt, l.pants, l.hat, math.floor(l.height * 1000) }, "/"))
					end
				end
			end
		end
	end
end
f:Destroy()
local h = 0
for _, s in out do
	for i = 1, #s do
		h = (h * 31 + string.byte(s, i)) % 2147483647
	end
end
return n .. " PNJ, empreinte " .. h .. " ; ex : " .. tostring(out[1]) .. " | " .. tostring(out[2])
