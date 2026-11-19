-- Banc Edit : livre du bestiaire (Systemes/Livres), vraies créatures, G simulé.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local Config = require(f.Config)
local Sys = game.ServerScriptService.Systemes
local E = require(Sys.Enemies:Clone())
local B = require(Sys.Bestiaire:Clone())
local kinds = table.clone(E.KINDS)
for id, k in B.KINDS do
	kinds[id] = kinds[id] or k
end
local mod = Sys.Livres:Clone()
local L = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local prof = { col = { creatures = { wolf = true, boar = true, creeping_shadow = true } } }
local sent
local G = {
	Config = Config,
	Interact = { onAction = function() end },
	Joueurs = { get = function() return prof end },
	Enemies = { KINDS = kinds },
	Bestiaire = { DAY = B.DAY, NIGHT = B.NIGHT },
	WG = require(f.RegionPlan),
}
L.init(G)
L.send = function(_, d) sent = d end
local total = 0
for _ in kinds do
	total += 1
end
L.bestiaire({})
check("livre envoyé", sent ~= nil and sent.titre:find("Bestiaire") ~= nil)
check("3 fiches (créatures vaincues seulement)", sent and #sent.lignes == 3)
check(string.format("compte : 3 sur %d", total), sent and sent.sous:find("3 créature") ~= nil and sent.sous:find(tostring(total)) ~= nil)
check("triées par niveau", sent and sent.lignes[1].t:find("niveau 1") ~= nil or sent.lignes[1].t:find("niveau 2") ~= nil)
local all = sent and (sent.lignes[1].t .. sent.lignes[1].x .. sent.lignes[2].x .. sent.lignes[3].x) or ""
check("butin nommé", all:find("Laisse") ~= nil)
check("lieu de vie (ombre rampante la nuit)", all:find("nuit") ~= nil)
check("lieu de vie des créatures d'origine (loup)", not all:find("lieux secrets"))
prof.col.creatures = {}
L.bestiaire({})
check("aucune créature : pages blanches", sent.lignes[1].t:find("blanches") ~= nil)
mod:Destroy()
f:Destroy()
local ls = {}
for _, l in (function() prof.col.creatures = { wolf = true, creeping_shadow = true } L.bestiaire({}) return sent.lignes end)() do
	table.insert(ls, l.t .. " — " .. l.x)
end
return fails .. " échec(s)\n" .. table.concat(out, "\n") .. "\n\n" .. table.concat(ls, "\n")
