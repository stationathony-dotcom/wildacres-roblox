-- Banc Edit : zones exigeantes (Systemes/Froid) — boue des marais et obscurité des grottes, G simulé.
-- Le froid et la chaleur ont été retirés le 20/11 : le banc vérifie aussi qu'ils ne reviennent pas.
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
local statsT, bagT, talents = {}, {}, {}
local prof = { equipped = {} }
local P = { Character = nil }
local attrs = { Froid = true, Soif = true } -- états d'avant le 20/11, à effacer
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
	World = { loaded = {} },
	Joueurs = { get = function() return prof end, stats = function() return statsT end, count = function(_, i) return bagT[i] or 0 end,
		has = function(_, i) return (bagT[i] or 0) > 0 end, talent = function(_, t) return talents[t] or 0 end },
	Game = { players = function() return { P } end },
	Util = { root = function() return root end, toast = function(_, t) table.insert(toasts, t) end },
}
F.init(G)
-- plus de froid ni de chaleur
check("plus de froid : isCold n'existe plus", F.isCold == nil and F.isHot == nil)
F.step(3.1)
check("neige la nuit : aucun état Froid / Soif (anciens effacés)", attrs.Froid == nil and attrs.Soif == nil and #toasts == 0)
-- grottes
check("grotte sans lumière : obscur", F.isDark(P, Vector3.new(0, -120, 0)) == true)
bagT.miner_lamp = 1
check("lampe de mineur dans le sac : on y voit", F.isDark(P, Vector3.new(0, -120, 0)) == false)
bagT.miner_lamp = nil
prof.equipped.offhand = { name = "Torche" }
c, why = F.isDark(P, Vector3.new(0, -120, 0))
check("torche en main gauche : on y voit", c == false and why == "torche")
prof.equipped.offhand = nil
check("à l'air libre : jamais obscur", F.isDark(P, Vector3.new(0, 5, 0)) == false)
talents.survivaliste = 1
local c, why = F.isDark(P, Vector3.new(0, -120, 0))
check("talent Survivaliste : y voit dans le noir", c == false and why == "survivaliste")
talents.survivaliste = nil
-- boue des marais (vrai terrain)
local T = workspace.Terrain
local M = Vector3.new(13000, 0, 13000)
T:FillBlock(CFrame.new(M + Vector3.new(0, -2, 0)), Vector3.new(20, 4, 20), Enum.Material.Mud)
task.wait(0.2)
biome = "marais"
check("boue du marais, sans bottes : on s'enlise", F.isStuck(P, M + Vector3.new(0, 2, 0)) == true)
prof.equipped.boots = { name = "Bottes de marais" }
c, why = F.isStuck(P, M + Vector3.new(0, 2, 0))
check("bottes de marais (emplacement boots) : sol tenu", c == false and why == "bottes")
prof.equipped.boots = nil
statsT.force = 8
c, why = F.isStuck(P, M + Vector3.new(0, 2, 0))
check("Force 8 : se tire de la boue", c == false and why == "fort")
statsT.force = 0
talents.survivaliste = 1
c, why = F.isStuck(P, M + Vector3.new(0, 2, 0))
check("talent Survivaliste : pas d'enlisement", c == false and why == "survivaliste")
T:FillBlock(CFrame.new(M + Vector3.new(0, -2, 0)), Vector3.new(22, 6, 22), Enum.Material.Air)
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
