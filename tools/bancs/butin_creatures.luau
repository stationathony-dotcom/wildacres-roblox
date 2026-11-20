-- Banc du butin des créatures (étape 9, 20/11) — mode Edit. Pour chaque créature hostile (Bestiaire +
-- Enemies) : valeur moyenne du butin (prix catalogue × quantité × chance) + or, rapportée à sa vie.
-- Signale : butin qui n'existe pas, créature sans aucun butin, valeur par point de vie à plus de 3× ou
-- moins d'un tiers de la médiane de son niveau (une bête facile qui rapporte trop = ferme à or).
local sh = game.ReplicatedStorage.Shared:Clone()
sh.Parent = game:GetService("ServerStorage")
local C = require(sh.Config)
sh:Destroy()
local B = require(game.ServerScriptService.Systemes.Bestiaire:Clone())
local okE, E = pcall(require, game.ServerScriptService.Systemes.Enemies:Clone())
local kinds = {}
for id, k in B.KINDS do
	kinds[id] = k
end
if okE and type(E) == "table" and type(E.KINDS) == "table" then
	for id, k in E.KINDS do
		kinds[id] = kinds[id] or k
	end
end
-- comme en jeu (Bestiaire.init) : butin ramené dans la norme de son niveau ; « brut » pour voir l'avant
local before = ... == "brut"
local normalized = before and 0 or B.normalizeLoot(kinds, C)
local function value(k)
	-- or d'une mise à mort : random(5, 15) × niveau × gold, plafonné à 25 + 12 % de la vie (Enemies)
	local v = math.min(10 * (k.level or 1) * (k.gold or 1), 25 + k.hp * 0.12)
	local missing = {}
	for _, l in k.loot or {} do
		local info = C.ITEMS[l[1]]
		if not info then
			table.insert(missing, l[1])
		else
			v += (l[2] + (l[3] or l[2])) / 2 * (l[4] or 1) * (info.price or 0)
		end
	end
	return v, missing
end
local byLevel, rows, problems = {}, {}, {}
for id, k in kinds do
	if not k.passive and not k.boss and (k.hp or 0) > 0 then
		local v, missing = value(k)
		for _, m in missing do
			table.insert(problems, id .. " : butin inconnu « " .. m .. " »")
		end
		if v <= 0 and not k.neutral then
			table.insert(problems, id .. " : aucun butin ni or")
		end
		local lv = k.level or 1
		local r = { id = id, lv = lv, perHp = v / k.hp, v = v }
		table.insert(rows, r)
		byLevel[lv] = byLevel[lv] or {}
		table.insert(byLevel[lv], r.perHp)
	end
end
local med = {}
for lv, list in byLevel do
	table.sort(list)
	med[lv] = list[math.floor(#list / 2) + 1]
end
local high, low = {}, {}
for _, r in rows do
	local m = med[r.lv]
	if m and m > 0 and #byLevel[r.lv] >= 3 then
		if r.perHp > m * 3 then
			table.insert(high, string.format("%s (niv %d, %.0f or)", r.id, r.lv, r.v))
		elseif r.perHp < m / 3 and r.v > 0 then
			table.insert(low, string.format("%s (niv %d, %.0f or)", r.id, r.lv, r.v))
		end
	end
end
table.sort(high)
table.sort(low)
return string.format("%d problème(s) — %d créatures\n%s\nTROP RICHES (> 3× la médiane de leur niveau, par point de vie) : %s\npauvres (< 1/3) : %s",
	#problems, #rows, table.concat(problems, "\n"), table.concat(high, ", "), table.concat(low, ", "))
