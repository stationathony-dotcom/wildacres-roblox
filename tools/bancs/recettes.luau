-- Banc des recettes (étape 5) — mode Play, contexte SERVEUR, un joueur dans la partie. ~10 s.
-- Le banc pose un établi et un four sur une parcelle neuve, puis pour chaque recette d'objet :
--   1. ingrédients JUSTE suffisants → l'objet est fabriqué, les ingrédients consommés exactement ;
--   2. un ingrédient retiré → rien n'est fabriqué, rien n'est consommé, le message liste le manque.
-- Recettes à compétence trop haute pour le perso de test : on vérifie seulement le REFUS (on ne monte
-- pas les compétences : ce serait écrit dans la vraie sauvegarde du compte). Équipement : hors banc.
-- Le seuil lu est skillRaw (règle 4 : l'équipement ne débloque pas une recette).
-- Résultat : nombre de recettes OK, et chaque échec en clair.
local D = game.ServerStorage:WaitForChild("DbgAppel", 20)
task.wait(6)
local p = game.Players:GetPlayers()[1]
assert(p, "pas de joueur")
local Config = require(game.ReplicatedStorage.Shared.Config)
local function call(path, ...)
	return select(2, D:Invoke(path, ...))
end
local function count(id)
	local group = Config.ITEM_GROUPS[id]
	if group then
		local n = 0
		for _, it in group do
			n += call("Joueurs.count", p, it)
		end
		return n
	end
	return call("Joueurs.count", p, id)
end
local function concrete(id)
	local group = Config.ITEM_GROUPS[id]
	return group and group[1] or id
end
-- vide un ingrédient (groupe compris) du sac
local function clear(id)
	local group = Config.ITEM_GROUPS[id] or { id }
	for _, it in group do
		local n = call("Joueurs.count", p, it)
		if n > 0 then
			call("Joueurs.take", p, it, n)
		end
	end
end

-- stations : établi et four posés devant le joueur, sur sa parcelle
local hrp = p.Character.HumanoidRootPart
call("Joueurs.add", p, "gold", 5000)
local base = hrp.Position + Vector3.new(-170, 0, -120)
D:Invoke("Game.teleport", p, Vector3.new(base.X, call("Util.groundY", base.X, base.Z) + 4, base.Z))
task.wait(2)
call("Parcelles.create", p, hrp.Position)
for k, it in { "workbench", "furnace" } do
	call("Joueurs.add", p, it, 1)
	hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, k * math.pi * 0.6, 0)
	D:Invoke("Shop.place", p, it)
end
task.wait(0.5)
local st = call("Shop.stations", p)
assert(st.bench and st.furnace, "stations non posées")

local ok, gated, skipped, fails = 0, 0, 0, {}
for i, r in Config.RECIPES do
	if r.gear or not r.item then
		skipped += 1
		continue
	end
	if r.skill and call("Joueurs.skillRaw", p, r.skill[1]) < r.skill[2] then
		-- refus attendu, rien de consommé
		for item, n in r.needs do
			call("Joueurs.add", p, concrete(item), n)
		end
		local b = call("Joueurs.count", p, r.item)
		D:Invoke("Shop.craft", p, i, 1)
		if call("Joueurs.count", p, r.item) ~= b then
			table.insert(fails, "#" .. i .. " " .. r.item .. " : fabriqué malgré la compétence")
		else
			gated += 1
		end
		for item in r.needs do
			clear(item)
		end
		continue
	end
	local info = Config.ITEMS[r.item]
	-- outil déjà possédé : on le retire (« tu as déjà »)
	if info.tool then
		clear(r.item)
	end
	-- 1. juste suffisant
	for item in r.needs do
		clear(item)
	end
	for item, n in r.needs do
		call("Joueurs.add", p, concrete(item), n)
	end
	local before = call("Joueurs.count", p, r.item)
	D:Invoke("Shop.craft", p, i, 1)
	local made = call("Joueurs.count", p, r.item) - before
	local left = 0
	for item in r.needs do
		if item ~= r.item then
			left += count(item)
		end
	end
	local good1 = made >= (r.count or 1) and left == 0
	-- 2. insuffisant : un ingrédient en moins
	local first = next(r.needs)
	for item, n in r.needs do
		call("Joueurs.add", p, concrete(item), item == first and n - 1 or n)
	end
	if info.tool then
		clear(r.item)
	end
	local before2 = call("Joueurs.count", p, r.item)
	D:Invoke("Shop.craft", p, i, 1)
	local made2 = call("Joueurs.count", p, r.item) - before2
	local miss = call("Shop.missing", p, r.needs)
	local good2 = made2 == 0 and type(miss) == "string" and count(first) == r.needs[first] - 1
	for item in r.needs do
		clear(item)
	end
	if good1 and good2 then
		ok += 1
	else
		table.insert(fails, string.format("#%d %s : juste=%s (fait %d, reste %d) · manque=%s (fait %d, msg %s)",
			i, r.item, tostring(good1), made, left, tostring(good2), made2, tostring(miss)))
	end
	if i % 10 == 0 then
		task.wait()
	end
end
return string.format("recettes OK : %d · refus compétence OK : %d · équipement hors banc : %d · échecs : %d\n%s", ok, gated, skipped, #fails, table.concat(fails, "\n"))
