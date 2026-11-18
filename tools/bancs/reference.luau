-- Génère docs/REFERENCE.md à partir des DONNÉES du jeu (pas à la main : relancer après chaque ajout).
-- Mode Edit, sans Play. Prérequis : python tools/sync.py en arrière-plan.
-- Contient : objets (type, rareté, valeur, obtention, usages), trouvailles par source et biome,
-- cultures, pêche, élevage, créatures (où, comportement, butin), sources d'XP de chaque compétence,
-- entrées / sorties d'or, et les contrôles (objet sans source, sans usage).
local H = game:GetService("HttpService")
local tmp = game.ReplicatedStorage.Shared:Clone() -- copie fraîche (le cache de require garde l'ancienne)
tmp.Parent = game:GetService("ServerStorage")
local C = require(tmp.Config)
local K = C.Catalogue
local Bf = game.ServerScriptService.Systemes.Bestiaire:Clone()
local Ef = game.ServerScriptService.Systemes.Enemies:Clone()
Bf.Parent, Ef.Parent = tmp, tmp
local B, E = require(Bf), require(Ef)
tmp:Destroy()

local L = {}
local function w(s)
	table.insert(L, s)
end
local function esc(s)
	return (tostring(s):gsub("|", "/"))
end
local RAR = { "commun", "peu commun", "rare", "épique", "légendaire" }
local BIOME = { prairie = "prairie", foret = "forêt rousse", desert = "désert", neige = "toundra", marais = "marais" }
local function nm(id)
	local i = C.ITEMS[id]
	return i and (i.icon .. " " .. i.name) or ("`" .. id .. "` (inconnu)")
end

-- ---------------------------------------------------------------- sources et usages de chaque objet
local src, uses = {}, {}
local function add(t, id, s)
	t[id] = t[id] or {}
	if not table.find(t[id], s) then
		table.insert(t[id], s)
	end
end
for _, r in C.RECIPES do
	if r.item then
		add(src, r.item, r.station == "furnace" and "four" or r.station == "bench" and "établi" or "atelier")
	end
	for id in r.needs or {} do
		add(uses, id, "recette")
		for _, it in C.ITEM_GROUPS[id] or {} do
			add(uses, it, "recette")
		end
	end
end
for _, id in C.SHOP do
	add(src, id, "boutique")
end
local FINDNAME = { tree = "abattage", bush = "cueillette", rock = "minage", dig = "fouille", fish = "pêche", hunt = "chasse", night = "cueillette de nuit", event = "événement" }
for s, list in K.FINDS do
	for _, f in list do
		add(src, f[1], FINDNAME[s] or s)
	end
end
for _, t in K.TREASURE do
	add(src, t[1], "trésor")
end
for id, crop in C.CROPS do
	add(src, id, "récolte")
	add(src, "seed_" .. id, "boutique")
end
for id, i in C.ITEMS do
	if i.use == "cat_planter" then
		add(src, id, "abattage") -- Props : "seed_" .. type d'arbre
	end
end
for _, f in C.FISH do
	if f.id then
		add(src, f.id, "pêche")
	end
end
for _, a in C.ANIMALS do
	if a.product then
		add(src, a.product, "élevage")
	end
end
local kinds = {}
for id, k in E.KINDS do
	kinds[id] = k
end
for id, k in B.KINDS do
	kinds[id] = k
end
for id, k in kinds do
	for _, l in k.loot or {} do
		add(src, l[1], k.boss and "boss" or "butin")
	end
end
-- tout le reste : chaînes "id" dans le code des scripts
local scripts = {}
for _, root in { game.ServerScriptService, game.ReplicatedStorage, game.StarterPlayer } do
	for _, d in root:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			table.insert(scripts, d)
		end
	end
end
table.sort(scripts, function(a, b)
	return a:GetFullName() < b:GetFullName()
end)
for id, info in C.ITEMS do
	if info.food or info.use or info.place or info.block or info.tool or info.weapon or info.seed or info.valuable then
		add(uses, id, "usage direct")
	end
	if not src[id] or not uses[id] then
		local pat = '"' .. id:gsub("%p", "%%%0") .. '"'
		for _, s in scripts do
			if s.Name ~= "Config" and s.Name ~= "Catalogue" and string.find(s.Source, pat) then
				if not src[id] then
					add(src, id, "code:" .. s.Name)
				end
				if not uses[id] then
					add(uses, id, "code:" .. s.Name)
				end
			end
		end
	end
end

local function kindOf(i)
	if i.block or i.build then
		return "Pièces de construction"
	elseif i.place then
		return "Objets posés et mobilier"
	elseif i.food then
		return "Nourriture et boissons"
	elseif i.tool or i.weapon then
		return "Outils et armes"
	elseif i.seed then
		return "Graines"
	elseif i.use then
		return "Objets utilisables"
	elseif i.valuable then
		return "Objets de valeur et collection"
	end
	return "Ressources et matières"
end

-- ---------------------------------------------------------------- en-tête
local nItems = 0
for _ in C.ITEMS do
	nItems += 1
end
local nK = 0
for _ in kinds do
	nK += 1
end
w("# Wild Acres — fiche de référence (générée)")
w("")
w("Générée par `tools/bancs/reference.luau` depuis les données du jeu : **ne pas modifier à la main**, relancer le banc.")
w(string.format("Contenu : %d objets, %d recettes, %d cultures, %d créatures, %d compétences.", nItems, #C.RECIPES, #C.CROP_ORDER, nK, #C.SKILL_ORDER))
w("")
w("Règles : tout objet est **échangeable** (troc, étal, hôtel des ventes, courrier, coffre) — aucun objet lié au")
w("personnage (décision étape 4B : économie entre joueurs, monde bac à sable). L'équipement porté s'échange une fois retiré.")
w("Rareté = obtention réelle (`Catalogue.assignRarity`) : prix, et pour ce qui ne se fabrique ni ne s'achète, meilleure chance de trouvaille.")
w("")

-- ---------------------------------------------------------------- contrôles
local noSrc, noUse = {}, {}
for id in C.ITEMS do
	if not src[id] then
		table.insert(noSrc, id)
	end
	if not uses[id] and not (C.ITEMS[id].price and C.ITEMS[id].price > 0) then
		table.insert(noUse, id)
	end
end
table.sort(noSrc)
table.sort(noUse)
w("## Contrôles")
w("")
w("- Objets sans aucune source trouvée : " .. (#noSrc == 0 and "**aucun**" or table.concat(noSrc, ", ")))
w("  (les pièces toutes faites `wall*`, `floor2`, `stairs` sont retirées de l'atelier depuis la construction libre ; gardées pour les anciennes sauvegardes)")
w("- Objets sans usage ni valeur de revente : " .. (#noUse == 0 and "**aucun**" or table.concat(noUse, ", ")))
w("")

-- ---------------------------------------------------------------- objets
w("## Objets")
w("")
local groups, gOrder = {}, {}
for id, i in C.ITEMS do
	local g = kindOf(i)
	if not groups[g] then
		groups[g] = {}
		table.insert(gOrder, g)
	end
	table.insert(groups[g], id)
end
table.sort(gOrder)
local RAR_N = { 0, 0, 0, 0, 0 }
for _, i in C.ITEMS do
	RAR_N[i.rarity or 1] += 1
end
w("Raretés : " .. table.concat((function()
	local o = {}
	for r = 1, 5 do
		table.insert(o, RAR[r] .. " " .. RAR_N[r])
	end
	return o
end)(), " · "))
w("")
for _, g in gOrder do
	local ids = groups[g]
	table.sort(ids, function(a, b)
		return C.ITEMS[a].name < C.ITEMS[b].name
	end)
	w("### " .. g .. " (" .. #ids .. ")")
	w("")
	w("| Objet | id | Rareté | Valeur | Obtention | Usages |")
	w("|---|---|---|---|---|---|")
	for _, id in ids do
		local i = C.ITEMS[id]
		local u = uses[id] or {}
		local nRec = 0
		for _, r in C.RECIPES do
			if r.needs and r.needs[id] then
				nRec += 1
			end
		end
		local us = {}
		if nRec > 0 then
			table.insert(us, nRec .. " recette" .. (nRec > 1 and "s" or ""))
		end
		for _, x in u do
			if x ~= "recette" then
				table.insert(us, x)
			end
		end
		w(string.format("| %s | `%s` | %s | %s | %s | %s |", esc(i.icon .. " " .. i.name), id, RAR[i.rarity or 1], i.price and tostring(i.price) or "—",
			esc(table.concat(src[id] or { "?" }, ", ")), esc(#us > 0 and table.concat(us, ", ") or "revente")))
	end
	w("")
end

-- ---------------------------------------------------------------- trouvailles
w("## Trouvailles par source et biome (chance par geste)")
w("")
local fOrder = {}
for s in K.FINDS do
	table.insert(fOrder, s)
end
table.sort(fOrder)
for _, s in fOrder do
	w("### " .. (FINDNAME[s] or s))
	w("")
	w("| Trouvaille | Chance | Biomes |")
	w("|---|---|---|")
	local list = table.clone(K.FINDS[s])
	table.sort(list, function(a, b)
		return a[2] > b[2]
	end)
	for _, f in list do
		local bs = {}
		for _, b in f[3] or {} do
			table.insert(bs, BIOME[b] or b)
		end
		w(string.format("| %s | %s %% | %s |", esc(nm(f[1])), tostring(math.floor(f[2] * 10000 + 0.5) / 100), #bs > 0 and table.concat(bs, ", ") or "tous"))
	end
	w("")
end

-- ---------------------------------------------------------------- cultures
w("## Cultures")
w("")
w("| Culture | Biomes | Jours | Compétence | Graine | Vente |")
w("|---|---|---|---|---|---|")
for _, id in C.CROP_ORDER do
	local c = C.CROPS[id]
	local bs = {}
	for _, b in c.biomes or {} do
		table.insert(bs, BIOME[b] or b)
	end
	w(string.format("| %s %s | %s | %d | agriculture %d | %s or | %s or |", c.icon or "", c.name, table.concat(bs, ", "), c.days or 0, c.skill or 0, tostring(c.seed_price), tostring(c.price)))
end
w("")

-- ---------------------------------------------------------------- pêche, élevage, dressage
w("## Poissons")
w("")
w("| Poisson | Poids (fréquence) | Compétence | Prix |")
w("|---|---|---|---|")
for _, f in C.FISH do
	w(string.format("| %s | %s | pêche %s | %s |", esc(f.name), tostring(f.weight), tostring(f.skill), tostring(f.price)))
end
w("")
w("## Bêtes de ferme")
w("")
w("| Bête | Prix | Produit | Tous les |")
w("|---|---|---|---|")
for id, a in C.ANIMALS do
	w(string.format("| %s | %s | %s | %s |", a.name, tostring(a.price), a.product and nm(a.product) or "—", tostring(a.every)))
end
w("")
w("## Dressage (bêtes sauvages)")
w("")
w("| Bête | Difficulté | Appât | Produits |")
w("|---|---|---|---|")
local tOrder = {}
for id in C.TAMING do
	table.insert(tOrder, id)
end
table.sort(tOrder)
for _, id in tOrder do
	local t = C.TAMING[id]
	local pr = {}
	for k, v in t.product or {} do
		table.insert(pr, type(k) == "number" and nm(v) or nm(k))
	end
	w(string.format("| %s | %s | %s | %s |", esc(t.label or id), tostring(t.diff), t.bait and nm(t.bait) or "—", esc(table.concat(pr, ", "))))
end
w("")

-- ---------------------------------------------------------------- créatures
local where = {}
local function at(id, s)
	where[id] = where[id] or {}
	if not table.find(where[id], s) then
		table.insert(where[id], s)
	end
end
for b, l in B.DAY or {} do
	for _, id in l do
		at(id, (BIOME[b] or b) .. " (jour)")
	end
end
for b, l in B.NIGHT or {} do
	for _, id in l do
		at(id, (BIOME[b] or b) .. " (nuit)")
	end
end
for b, id in B.RARE or {} do
	at(id, (BIOME[b] or b) .. " (rare)")
end
for b, l in B.CAVE or {} do
	for _, id in l do
		at(id, "grottes " .. (BIOME[b] or b))
	end
end
for b, id in B.GUARDIAN or {} do
	at(id, "gardien de donjon " .. (BIOME[b] or b))
end
for id, r in B.ROAMING or {} do
	local bs = {}
	for _, b in r.biome or {} do
		table.insert(bs, BIOME[b] or b)
	end
	at(id, "errant " .. table.concat(bs, ", "))
end
w("## Créatures")
w("")
w("Comportement : `neutre` = ne frappe que si on l'attaque ; `meute N` = arrive en groupe ; `lumière` = fuit la lumière ;")
w("laisse de 70 studs puis retour au foyer ; réapparition au bout de 3 jours (boss exclus). Lieu « génération » = posée par le plan de région.")
w("")
w("| Créature | id | Niv. | PV | Dégâts | Comportement | Où | Butin | Or |")
w("|---|---|---|---|---|---|---|---|---|")
local kOrder = {}
for id, k in kinds do
	if not k.unit then
		table.insert(kOrder, id)
	end
end
table.sort(kOrder, function(a, b)
	local ka, kb = kinds[a], kinds[b]
	if (ka.level or 0) ~= (kb.level or 0) then
		return (ka.level or 0) < (kb.level or 0)
	end
	return a < b
end)
for _, id in kOrder do
	local k = kinds[id]
	local beh = { k.style or "?" }
	if k.boss then
		table.insert(beh, "BOSS")
	elseif k.elite then
		table.insert(beh, "élite")
	end
	if k.neutral then
		table.insert(beh, "neutre")
	end
	if k.pack then
		table.insert(beh, "meute " .. k.pack)
	end
	if k.night then
		table.insert(beh, "nuit")
	end
	if k.fearsLight then
		table.insert(beh, "lumière")
	end
	if k.flies then
		table.insert(beh, "vole")
	end
	local loot = {}
	for _, l in k.loot or {} do
		table.insert(loot, string.format("%s %s–%s (%d %%)", nm(l[1]), l[2], l[3], math.floor((l[4] or 1) * 100 + 0.5)))
	end
	w(string.format("| %s | `%s` | %s | %s | %s | %s | %s | %s | %s |", esc(k.name), id, tostring(k.level or "?"), tostring(k.hp), tostring(k.dmg),
		table.concat(beh, ", "), esc(table.concat(where[id] or { "génération" }, ", ")), esc(table.concat(loot, ", ")), tostring(k.gold or 0)))
end
w("")

-- ---------------------------------------------------------------- XP des compétences et or (lecture du code)
local function scan(patterns)
	local out = {}
	for _, s in scripts do
		local n = 0
		for line in string.gmatch(s.Source .. "\n", "(.-)\n") do
			n += 1
			for _, p in patterns do
				local cap = string.match(line, p)
				if cap then
					table.insert(out, { file = s.Name, line = n, cap = cap, text = (line:gsub("^%s+", "")) })
					break
				end
			end
		end
	end
	return out
end
w("## Compétences : ce qui donne de l'XP")
w("")
w("Lu dans le code (`addSkillXp` / `addSkillXpCapped`). Les gestes réversibles sont plafonnés par jour (étape 6A).")
w("")
local xp = scan({ 'addSkillXpCapped%([^,]+,%s*"(%a+)"', 'addSkillXp%([^,]+,%s*"(%a+)"' })
local bySkill = {}
for _, x in xp do
	bySkill[x.cap] = bySkill[x.cap] or {}
	table.insert(bySkill[x.cap], x)
end
for _, sk in C.SKILL_ORDER do
	local s = C.SKILLS[sk]
	local l = bySkill[sk] or {}
	w(string.format("### %s %s — %s (%d source%s)", s.icon or "", s.name, esc(s.desc or ""), #l, #l > 1 and "s" or ""))
	w("")
	for _, x in l do
		w(string.format("- `%s:%d` — `%s`", x.file, x.line, esc(x.text)))
	end
	if #l == 0 then
		w("- pas d'appel direct : l'XP vient de la fabrication (`Shop`, compétence de la recette), voir plus bas")
	end
	w("")
end
local dyn = scan({ "addSkillXp%w*%([^,]+,%s*([%a_][%w_%.]*)%s*," })
if #dyn > 0 then
	w("### Compétence choisie à l'exécution")
	w("")
	for _, x in dyn do
		w(string.format("- `%s:%d` — `%s`", x.file, x.line, esc(x.text)))
	end
	w("")
end

w("## Or : entrées et sorties")
w("")
w("Lu dans le code : `add(…, \"gold\", …)` crée de l'or, `take(…, \"gold\", …)` en détruit (ou le déplace vers un autre joueur).")
w("Le journal serveur (`Economie`) mesure les flux réels par monde.")
w("")
local gin = scan({ '%.add%([^,]+,%s*"gold"' })
local gout = scan({ '%.take%([^,]+,%s*"gold"' })
local function list(t, title)
	w("### " .. title .. " (" .. #t .. ")")
	w("")
	local by = {}
	local order = {}
	for _, x in t do
		if not by[x.file] then
			by[x.file] = {}
			table.insert(order, x.file)
		end
		table.insert(by[x.file], x)
	end
	for _, f in order do
		for _, x in by[f] do
			w(string.format("- `%s:%d` — `%s`", f, x.line, esc(x.text)))
		end
	end
	w("")
end
list(gin, "Entrées d'or")
list(gout, "Sorties d'or")

local text = table.concat(L, "\n") .. "\n"
H:PostAsync("http://127.0.0.1:34873/doc?f=REFERENCE.md", text, Enum.HttpContentType.TextPlain)
return string.format("REFERENCE.md : %d lignes, %d Ko ; sans source : %s ; sans usage : %s ; xp %d, or +%d -%d", #L, #text // 1024,
	table.concat(noSrc, " "), table.concat(noUse, " "), #xp, #gin, #gout)
