-- Banc Edit : AUDIT du contenu (craft, équipement, butin, visuels) — ce que le code peut vérifier
-- sans jouer : chaque objet posable a un modèle constructible, chaque créature un modèle, chaque
-- recette des ingrédients qui existent, chaque butin un objet qui existe, chaque pièce
-- d'équipement un visuel connu de son emplacement. Rien ne remplace un coup d'œil en Play.
local f = game.ReplicatedStorage.Shared:Clone()
f.Parent = game:GetService("ServerStorage")
local Config = require(f.Config)
local K = Config.Catalogue
local Sys = game.ServerScriptService.Systemes
local Bm = Sys.Bestiaire:Clone()
local Em = Sys.Enemies:Clone()
Bm.Parent, Em.Parent = f, f
local B, E = require(Bm), require(Em)
local SS = game:GetService("ServerStorage")
local lines, problems = {}, 0
local function report(title, list, total)
	table.insert(lines, string.format("%s : %d / %d%s", title, total - #list, total, #list > 0 and (" — MANQUE : " .. table.concat(list, ", ", 1, math.min(#list, 25)) .. (#list > 25 and " …" or "")) or ""))
	problems += #list
end
local function modelExists(name: string): boolean
	if K.MODELS and K.MODELS[name] then
		return true
	end
	for _, folderName in { "Modeles", "Models", "Modèles" } do
		local fo = SS:FindFirstChild(folderName)
		if fo and fo:FindFirstChild(name, true) then
			return true
		end
	end
	return SS:FindFirstChild(name, true) ~= nil or game.ReplicatedStorage:FindFirstChild(name, true) ~= nil
end
-- 1. objets posables : modèle
local miss, n = {}, 0
for id, info in Config.ITEMS do
	if info.place then
		n += 1
		if not modelExists(info.place) then
			table.insert(miss, id .. "→" .. info.place)
		end
	end
end
report("Objets posables avec un modèle", miss, n)
-- 2. créatures : modèle (Bestiaire construit par code, les autres dans ServerStorage)
miss, n = {}, 0
for id, k in E.KINDS do
	n += 1
	if not modelExists(k.model or "?") then
		table.insert(miss, id .. "→" .. tostring(k.model))
	end
end
for id in B.KINDS do
	n += 1
	local ok, m = pcall(B.build, "Bete_" .. id)
	if not ok or not m then
		table.insert(miss, "Bete_" .. id)
	elseif m then
		m:Destroy()
	end
end
report("Créatures avec un modèle", miss, n)
-- 3. recettes : ingrédients et résultats existants
miss, n = {}, 0
for _, r in Config.RECIPES do
	n += 1
	if r.item and not Config.ITEMS[r.item] then
		table.insert(miss, "résultat " .. r.item)
	end
	for need in r.needs or {} do
		if not Config.ITEMS[need] and not (Config.GROUP_NAMES and Config.GROUP_NAMES[need]) then
			table.insert(miss, tostring(r.item or (r.gear and r.gear.name)) .. "←" .. need)
		end
	end
end
report("Recettes complètes", miss, n)
-- 4. butin des créatures
miss, n = {}, 0
for id, k in E.KINDS do
	for _, l in k.loot or {} do
		n += 1
		if not Config.ITEMS[l[1]] then
			table.insert(miss, id .. ":" .. l[1])
		end
	end
end
for id, k in B.KINDS do
	for _, l in k.loot or {} do
		n += 1
		if not Config.ITEMS[l[1]] then
			table.insert(miss, id .. ":" .. l[1])
		end
	end
end
report("Butins qui existent", miss, n)
-- 5. visuels d'équipement : la valeur « visual » de chaque pièce fabricable est-elle dessinée ?
local avatarSrc = Sys.Avatar.Source
miss, n = {}, 0
for _, r in Config.RECIPES do
	local g = r.gear
	if g and g.visual and g.visual ~= "" then
		n += 1
		local v = tostring(g.visual)
		local drawn = string.find(avatarSrc, '"' .. v .. '"', 1, true) or string.find(avatarSrc, "%f[%w_]" .. v .. "%s*=") or tonumber(v)
		if not drawn then
			table.insert(miss, g.name .. "→" .. v)
		end
	end
end
report("Visuels d'équipement fabricable connus d'Avatar", miss, n)
-- 6. icônes : chaque objet en a une
miss, n = {}, 0
for id, info in Config.ITEMS do
	n += 1
	if not info.icon or info.icon == "" then
		table.insert(miss, id)
	end
end
report("Objets avec une icône", miss, n)
f:Destroy()
return problems .. " problème(s)\n" .. table.concat(lines, "\n")
