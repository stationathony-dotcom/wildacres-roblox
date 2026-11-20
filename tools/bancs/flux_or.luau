-- Banc du flux d'or (Economie : goldGained / goldSpent / fluxSummary, 20/11) — mode Edit, G simulé.
-- Vérifie que chaque gain / dépense est rangé sous le SYSTÈME qui paie, que les échanges entre joueurs
-- ne comptent ni comme création ni comme destruction, et que seuls 7 jours sont gardés.
local E = assert(loadstring(game.ServerScriptService.Systemes.Economie.Source, "Economie"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end
local G = {
	world = { day = 5, extra = {} },
	Interact = { onAction = function() end, onPrompt = function() end },
	Util = { toast = function() end },
}
pcall(E.init, G)
-- Joueurs simulé (même pile qu'en jeu : système → Joueurs.add/take → goldGained/goldSpent)
local J = loadstring([[
	local E = ...
	return {
		add = function(p, n) E.goldGained(p, n) end,
		take = function(p, n) E.goldSpent(p, n) end,
	}
]], "Joueurs")(E)
local function system(name)
	return loadstring([[
		local J = ...
		return function(p, gain, spend)
			if gain > 0 then J.add(p, gain) end
			if spend > 0 then J.take(p, spend) end
		end
	]], name)(J)
end
local P = {}
system("Shop")(P, 120, 300) -- ventes au marchand, achats au marchand
system("Quetes")(P, 200, 0) -- récompense
system("Armee")(P, 0, 50) -- solde
system("Ventes")(P, 500, 500) -- hôtel des ventes : de joueur à joueur
local s = E.fluxSummary(5)
check(string.format("créé = boutique + quêtes (%s)", s and s.gain or "nil"), s and s.gain == 320)
check(string.format("détruit = boutique + solde (%s)", s and s.spend or "nil"), s and s.spend == 350)
check("solde du jour = -30", s and s.net == -30)
check("première source : Quetes", s and s.sources[1] and s.sources[1][1] == "Quetes")
check("premier puits : Shop", s and s.sinks[1] and s.sinks[1][1] == "Shop")
check("hôtel des ventes compté mais hors création", G.world.extra.orFlux["5"].gain.Ventes == 500 and s.gain == 320)
system("Shop")(P, 0 / 0, -5) -- NaN / négatif : ignorés
check("NaN et négatif ignorés", E.fluxSummary(5).gain == 320)
for d = 6, 15 do
	G.world.day = d
	system("Shop")(P, 1, 0)
end
local n = 0
for _ in G.world.extra.orFlux do
	n += 1
end
check("7 jours gardés au plus (" .. n .. ")", n == 7)
return fails .. " échec(s)\n" .. table.concat(out, "\n")
