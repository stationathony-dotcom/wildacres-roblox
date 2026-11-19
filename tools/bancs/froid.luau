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
local statsT, bagT = {}, {}
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
local root = { Position = Vector3.new(12000, 10, 12000) }
local toasts = {}
local G = {
	Clock = { biomeAt = function() return biome end, isNight = function() return night end },
	World = { loaded = { { state = { placed = placed } } } },
	Joueurs = { get = function() return prof end, stats = function() return statsT end, count = function(_, i) return bagT[i] or 0 end },
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
-- chaleur du désert
biome, night = "desert", false
G.Clock.hour = function() return 13 end
check("désert, 13 h, sans ombre ni eau : soif", F.isHot(P, pos) == true)
G.Clock.hour = function() return 9 end
check("désert, 9 h : pas encore chaud", F.isHot(P, pos) == false)
G.Clock.hour = function() return 13 end
attrs.Desaltere = os.clock() + 300
c, why = F.isHot(P, pos)
check("a bu : désaltéré", c == false and why == "désaltéré")
attrs.Desaltere = nil
F.step(3.1)
check("step : attribut Soif posé + message", attrs.Soif == true and toasts[#toasts]:find("chaleur") ~= nil)
-- tenue légère et robustesse
G.Clock.hour = function() return 13 end
prof.equipped.hat = { name = "Turban de lin" }
c, why = F.isHot(P, pos)
check("turban de lin : protège de la chaleur", c == false and why == "tenue légère")
prof.equipped.hat = nil
statsT.vie = 10
c, why = F.isHot(P, pos)
check("Vie 10 : endure la chaleur", c == false and why == "robuste")
statsT.vie = 0
-- sommets : froid la nuit même hors neige
biome, night = "prairie", true
check("sommet (34 studs), la nuit, en prairie : froid", F.isCold(P, Vector3.new(0, 34, 0)) == true)
check("en contrebas (10 studs) : pas froid", F.isCold(P, Vector3.new(0, 10, 0)) == false)
-- grottes
check("grotte sans lumière : obscur", F.isDark(P, Vector3.new(0, -120, 0)) == true)
bagT.miner_lamp = 1
check("lampe de mineur dans le sac : on y voit", F.isDark(P, Vector3.new(0, -120, 0)) == false)
check("à l'air libre : jamais obscur", F.isDark(P, Vector3.new(0, 5, 0)) == false)
-- boue des marais (vrai terrain)
local T = workspace.Terrain
local M = Vector3.new(13000, 0, 13000)
T:FillBlock(CFrame.new(M + Vector3.new(0, -2, 0)), Vector3.new(20, 4, 20), Enum.Material.Mud)
task.wait(0.2)
biome = "marais"
check("boue du marais, sans bottes : on s'enlise", F.isStuck(P, M + Vector3.new(0, 2, 0)) == true)
prof.equipped.trinket = { name = "Bottes de marais" }
c, why = F.isStuck(P, M + Vector3.new(0, 2, 0))
check("bottes de marais : sol tenu", c == false and why == "bottes")
prof.equipped.trinket = nil
statsT.force = 8
c, why = F.isStuck(P, M + Vector3.new(0, 2, 0))
check("Force 8 : se tire de la boue", c == false and why == "fort")
T:FillBlock(CFrame.new(M + Vector3.new(0, -2, 0)), Vector3.new(22, 6, 22), Enum.Material.Air)
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
