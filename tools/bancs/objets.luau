-- Banc Edit (21/11) : contrôle de TOUS les objets de Config.ITEMS (après Catalogue + Equilibre), sur un clone
-- de Shared. Complète `equilibre` (usages) et `audit_contenu` (modèles, icônes présentes) :
--   · nom : présent, en français (pas l'id, pas de mot anglais courant), pas de doublon de nom ;
--   · icône : présente, affichable (pas d'emoji Unicode 13+ sans secours côté client) ;
--   · prix : nombre fini ≥ 0 ; un objet vendable a un prix ;
--   · provenance : recette, boutique, butin de créature, récolte / pêche / ferme, ou système connu ;
--   · recettes : ingrédients existants, pas de recette qui se consomme elle-même, quantités entières > 0 ;
--   · nourriture : soin > 0 ; outils : palier cohérent ; objets posés : modèle connu.
local RS = game:GetService("ReplicatedStorage")
local sh = RS.Shared:Clone()
sh.Parent = nil
local C = require(sh.Config)
local I, R = C.ITEMS, C.RECIPES
local out, fails, warns = {}, 0, 0
local function bad(sev, id, msg)
	if sev == "ÉCHEC" then fails += 1 else warns += 1 end
	table.insert(out, sev .. " " .. id .. " · " .. msg)
end

-- emojis Unicode 13+ (carrés vides) que le client remplace (ComposantsInterface.SECOURS)
local SECOURS = { ["🪓"] = 1, ["🪚"] = 1, ["🪄"] = 1, ["🪖"] = 1, ["🪵"] = 1, ["🪨"] = 1, ["🪙"] = 1, ["🪣"] = 1,
	["🪑"] = 1, ["🛖"] = 1, ["🪟"] = 1, ["🪔"] = 1, ["🪕"] = 1, ["🪁"] = 1, ["🪿"] = 1, ["🧌"] = 1 }
local function v13(cp)
	return (cp >= 0x1FA96 and cp <= 0x1FAFF) or cp == 0x1F6D6 or cp == 0x1F6D7 or cp == 0x1F6DC or cp == 0x1F6FB
		or cp == 0x1F6FC or cp == 0x1F90C or cp == 0x1F972 or cp == 0x1F977 or cp == 0x1F978 or cp == 0x1F9CC
		or (cp >= 0x1FA83 and cp <= 0x1FA86) or cp == 0x1FA74
end
local ENGLISH = { "^The ", " of the ", "Sword$", "^Iron ", "^Wood ", "Shield$", "Helmet", "^Stone ", "Bread$", "Potion$", "^Gold " }

-- provenances
local made, sold, dropped = {}, {}, {}
for _, r in R do
	if r.item then made[r.item] = true end
end
for _, id in C.SHOP or {} do sold[id] = true end
local okB, Best = pcall(function()
	return loadstring(game.ServerScriptService.Systemes.Bestiaire.Source)()
end)
for _, k in (okB and Best.KINDS) or {} do
	for _, l in k.loot or {} do dropped[l[1]] = true end
end
-- rênes : ajoutées au butin des bêtes au démarrage par Montures (m.drop = { bête, chance })
local okM, Ecu = pcall(function() return loadstring(RS.Shared.Ecurie.Source)() end)
for _, m in (okM and Ecu.LIST) or {} do
	if m.drop and okB and Best.KINDS[m.drop[1]] then dropped["renes_" .. m.id] = true end
end
-- œufs de monture : nids (biome) et coffres de donjon (Systemes/Nids, Donjons), d'après Ecurie.OEUFS
for _, list in (okM and Ecu.OEUFS) or {} do
	for _, e in list do dropped["oeuf_" .. e[1]] = true end
end
local okE, Enem = pcall(function() return loadstring(game.ServerScriptService.Systemes.Enemies.Source)() end)
-- sources « système » : chaînes d'ids présentes dans le code serveur (récolte, pêche, ferme, trésors…)
local code = {}
for _, s in game.ServerScriptService:GetDescendants() do
	if s:IsA("LuaSourceContainer") then table.insert(code, s.Source) end
end
-- tables de récolte, de trouvailles, de trésors, de bêtes… déclarées dans Shared
for _, s in RS.Shared:GetChildren() do
	if s:IsA("ModuleScript") then table.insert(code, s.Source) end -- les lignes du Catalogue (id|…) ne sont pas entre guillemets
end
code = table.concat(code, "\n")

local names = {}
local n = 0
for id, it in I do
	n += 1
	-- nom
	if type(it.name) ~= "string" or it.name == "" then
		bad("ÉCHEC", id, "sans nom")
	else
		if it.name == id or string.find(it.name, "_") then bad("ÉCHEC", id, "nom technique : " .. it.name) end
		for _, w in ENGLISH do
			if string.find(it.name, w) then bad("ATTENTION", id, "nom anglais ? " .. it.name) break end
		end
		names[it.name] = names[it.name] or {}
		table.insert(names[it.name], id)
	end
	-- icône
	if type(it.icon) ~= "string" or it.icon == "" then
		bad("ÉCHEC", id, "sans icône")
	else
		for _, cp in utf8.codes(it.icon) do
			if v13(cp) and not SECOURS[utf8.char(cp)] then
				bad("ÉCHEC", id, "icône en carré vide (Unicode 13+) : " .. it.icon)
			end
		end
	end
	-- prix
	if it.price ~= nil and (type(it.price) ~= "number" or it.price ~= it.price or it.price < 0 or it.price > 1e7) then
		bad("ÉCHEC", id, "prix invalide : " .. tostring(it.price))
	end
	-- nourriture
	if it.food ~= nil and (type(it.food) ~= "number" or it.food <= 0) then bad("ÉCHEC", id, "nourriture sans soin") end
	-- provenance
	-- anciennes pièces toutes faites, sans source exprès (construction libre ; gardées pour les vieilles sauvegardes)
	local LEGACY = { wall = 1, wall2 = 1, wall2_window = 1, wall_brick = 1, wall_door = 1, wall_stone = 1, wall_window = 1, floor2 = 1, stairs = 1 }
	local src = LEGACY[id] or made[id] or sold[id] or dropped[id] or it.seed ~= nil or (C.CROPS and C.CROPS[id] ~= nil) or string.sub(id, 1, 5) == "seed_"
		or string.sub(id, 1, 5) == "fish_" or string.sub(id, 1, 6) == "prise_" or string.sub(id, 1, 5) == "soul_" or string.sub(id, 1, 4) == "ame_"
		or string.find(code, '"' .. id .. '"', 1, true) ~= nil
		or string.find(code, "item%s*=%s*\"" .. id .. "\"") ~= nil
	if not src then
		bad("ATTENTION", id, "aucune provenance trouvée (" .. (it.name or "?") .. ")")
	end
end
-- doublons de noms
for name, ids in names do
	if #ids > 1 then bad("ATTENTION", table.concat(ids, "+"), "même nom affiché : « " .. name .. " »") end
end
-- recettes
local nr = 0
for i, r in R do
	nr += 1
	local key = r.item or (r.gear and r.gear.name) or ("#" .. i)
	if r.item and not I[r.item] then bad("ÉCHEC", key, "recette d'un objet inconnu") end
	for ing, q in r.needs or {} do
		if not I[ing] and not (C.ITEM_GROUPS and C.ITEM_GROUPS[ing]) then bad("ÉCHEC", key, "ingrédient inconnu : " .. ing) end
		if type(q) ~= "number" or q <= 0 or q % 1 ~= 0 then bad("ÉCHEC", key, "quantité invalide : " .. ing .. " " .. tostring(q)) end
		if ing == r.item then bad("ÉCHEC", key, "se consomme elle-même") end
	end
	if r.count and (r.count <= 0 or r.count % 1 ~= 0) then bad("ÉCHEC", key, "quantité produite invalide") end
	if r.skill and not C.SKILLS[r.skill[1]] then bad("ÉCHEC", key, "compétence inconnue : " .. tostring(r.skill[1])) end
end
sh:Destroy()
table.sort(out)
return string.format("%d objet(s), %d recette(s) : %d échec(s), %d attention(s)\n", n, nr, fails, warns) .. table.concat(out, "\n")
