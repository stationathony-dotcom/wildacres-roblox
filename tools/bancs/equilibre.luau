-- Banc d'équilibre (19/11, docs/AUDIT-CRAFT.md) : à relancer après tout ajout d'objets ou d'équipement.
-- Mode Edit, sans Play. Lit une copie fraîche de ReplicatedStorage.Shared (Config + Equilibre appliqués).
-- Contrôle :
--   1. objets sans usage (ni nourriture, outil, pose, usage, équipement, recette menant à un objet utile,
--      ni objet cité par un système : liste USED_BY_CODE à tenir à jour) ;
--   2. recettes qui font perdre de l'or (valeur < 0,8 × ingrédients) ;
--   3. plats qui nourrissent moins que leurs ingrédients crus ;
--   4. pièces sous le plancher de stats de leur rareté ;
--   5. recettes copiées (mêmes ingrédients, même atelier, même quantité), hors construction.
-- Renvoie un texte ; « OK » partout = rien à reprendre.
local tmp = game.ReplicatedStorage.Shared:Clone()
tmp.Parent = game:GetService("ServerStorage")
local C = require(tmp.Config)
local E = require(tmp.Equilibre)
tmp:Destroy()
local I, R = C.ITEMS, C.RECIPES

-- objets utilisés par un système sans drapeau dans les données (Combat, Shop, Froid, Horses, Compagnons…)
local USED_BY_CODE = {
	gold = true, arrow = true, bolt = true, bolt_heavy = true, arrow_iron = true, arrow_barbed = true, javelin = true,
	throwing_knife = true, stone = true, bait = true, plate = true, wood_plate = true, table_fork = true, table_knife = true,
	jug = true, ladle = true, spoon = true, quill = true, scales_tool = true, weights = true, blanket = true,
	glow_mushroom = true, lantern = true, miner_lamp = true, compass = true, old_compass = true, charter = true,
	dog_collar = true, spiked_collar = true, pet_harness = true, saddle_leather = true, saddle_race = true, stirrups = true,
	bracelet = true, brooch = true, necklace = true, backpack = true, map_world = true, parchment = true, lockpick = true,
}
for id in E.TACK or {} do
	USED_BY_CODE[id] = true
end

local out = {}
local function line(ok, title, detail)
	table.insert(out, (ok and "OK    " or "À VOIR ") .. title .. (detail and detail ~= "" and (" — " .. detail) or ""))
end

-- 1. usages
local DIRECT = { "food", "tool", "place", "use", "seed", "weapon", "lock", "drink", "wear", "block", "meal" }
local useful, outputs = {}, {}
for id, i in I do
	local u = USED_BY_CODE[id] == true
	for _, k in DIRECT do
		if i[k] then
			u = true
		end
	end
	useful[id] = u
	outputs[id] = {}
end
for _, r in R do
	for id in r.needs do
		if outputs[id] then
			table.insert(outputs[id], r.gear and true or r.item)
		end
	end
end
for _ = 1, 12 do
	for id, outs in outputs do
		if not useful[id] then
			for _, o in outs do
				if o == true or useful[o] then
					useful[id] = true
					break
				end
			end
		end
	end
end
local junk = {}
for id, u in useful do
	if not u and not string.find(id, "^wall") and id ~= "floor2" and id ~= "stairs" then
		table.insert(junk, id)
	end
end
table.sort(junk)
line(#junk == 0, "objets sans usage : " .. #junk, table.concat(junk, ", "))

-- 2. recettes à perte
local function price(id)
	return I[id] and I[id].price or 0
end
local loss = {}
for _, r in R do
	if r.item and price(r.item) > 0 then
		local cost, ok = 0, true
		for id, n in r.needs do
			if price(id) <= 0 then
				ok = false
			end
			cost += price(id) * n
		end
		for id, n in r.back or {} do
			cost -= price(id) * n
		end
		if ok and cost > 0 and price(r.item) * (r.count or 1) < cost * 0.8 then
			table.insert(loss, r.item)
		end
	end
end
line(#loss <= 1, "recettes à perte : " .. #loss, table.concat(loss, ", "))

-- 3. plats
local worse = {}
for _, r in R do
	local o = r.item and I[r.item]
	if o and o.food then
		local raw = 0
		for id, n in r.needs do
			raw += ((I[id] and I[id].food) or 0) * n
		end
		if raw > 0 and o.food * (r.count or 1) <= raw then
			table.insert(worse, r.item)
		end
	end
end
line(#worse == 0, "plats moins nourrissants que crus : " .. #worse, table.concat(worse, ", "))

-- 4. planchers de stats
local low = {}
for _, r in R do
	local g = r.gear
	if g and g.stats and not g.skills then
		local t = 0
		for _, v in g.stats do
			t += v
		end
		local floor = E.MAIN_SLOTS[g.slot or ""] and E.RARITY_FLOOR[g.rarity or 1] or E.SMALL_FLOOR[g.rarity or 1]
		if floor and t < floor then
			table.insert(low, g.name .. " (" .. t .. "/" .. floor .. ")")
		end
	end
end
line(#low == 0, "pièces sous le plancher : " .. #low, table.concat(low, ", "):sub(1, 600))

-- 5. copies
local sig, dups = {}, {}
for _, r in R do
	local name = r.item or (r.gear and r.gear.name)
	if name and r.cat ~= "construction" and not string.find(name, "^blk_") then
		local a = {}
		for id, n in r.needs do
			table.insert(a, id .. n)
		end
		table.sort(a)
		local k = table.concat(a, " ") .. "@" .. (r.station or "") .. "x" .. (r.count or 1)
		if sig[k] and sig[k] ~= name then
			table.insert(dups, sig[k] .. " = " .. name)
		else
			sig[k] = name
		end
	end
end
line(#dups <= 8, "recettes copiées : " .. #dups, table.concat(dups, " ; "):sub(1, 600))

local n = 0
for _ in I do
	n += 1
end
table.insert(out, 1, string.format("Banc d'équilibre : %d objets, %d recettes, %d corrections d'Equilibre", n, #R, #E.changes))
return table.concat(out, "\n")
