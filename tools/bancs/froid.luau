-- Banc Edit : froid de la neige la nuit (Systemes/Froid), G simulé, vrai raycast pour le toit.
local mod = game.ServerScriptService.Systemes.Froid:Clone()
local F = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local biome, night = "neige", true
local placed = {}
local prof = { equipped = {} }
local P = { Character = nil }
local attrs = {}
function P:GetAttribute(k)
	return attrs[k]
end
function P:SetAttribute(k, v)
	attrs[k] = v
end
local root = { Position = Vector3.new(12000, 60, 12000) }
local toasts = {}
local G = {
	Clock = { biomeAt = function() return biome end, isNight = function() return night end },
	World = { loaded = { { state = { placed = placed } } } },
	Joueurs = { get = function() return prof end },
	Game = { players = function() return { P } end },
	Util = { root = function() return root end, toast = function(_, t) table.insert(toasts, t) end },
}
F.init(G)
local pos = root.Position
check("neige, nuit, rien : froid", F.isCold(P, pos) == true)
night = false
check("neige le jour : pas froid", F.isCold(P, pos) == false)
night = true
biome = "prairie"
check("prairie la nuit : pas froid", F.isCold(P, pos) == false)
biome = "neige"
table.insert(placed, { item = "campfire", x = pos.X + 5, z = pos.Z })
local c, why = F.isCold(P, pos)
check("feu de camp à 5 studs : réchauffé", c == false and why == "feu")
placed[1].x = pos.X + 40
check("feu trop loin : froid", F.isCold(P, pos) == true)
prof.equipped.armor = { name = "Manteau de fourrure" }
c, why = F.isCold(P, pos)
check("manteau de fourrure : réchauffé", c == false and why == "vêtement chaud")
prof.equipped.armor = { name = "Cotte de mailles" }
local roofPart = Instance.new("Part")
roofPart.Anchored = true
roofPart.Size = Vector3.new(10, 1, 10)
roofPart.Position = pos + Vector3.new(0, 8, 0)
roofPart.Parent = workspace
task.wait()
c, why = F.isCold(P, pos)
check("sous un toit : à l'abri", c == false and why == "abri")
roofPart:Destroy()
task.wait()
-- step : l'attribut et le message
F.step(3.1)
check("step : attribut Froid posé + message", attrs.Froid == true and toasts[#toasts]:find("gèle") ~= nil)
night = false
F.step(3.1)
check("le jour revient : attribut retiré", attrs.Froid == nil and toasts[#toasts]:find("réchauffes") ~= nil)
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
