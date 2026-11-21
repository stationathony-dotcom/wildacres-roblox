-- Équipement façon MMORPG : emplacements, raretés, statistiques tirées au hasard.
-- Les stats touchent aussi le côté « GTA » : charisme = prix et opinion, discrétion = vue des PNJ.

local G = {}
local Design = require(script.Parent.GearDesign)

G.SLOTS = { weapon = "Arme", hat = "Casque", armor = "Torse", trinket = "Bijou", gloves = "Gants",
	shoulders = "Épaulières", legs = "Pantalon", cape = "Cape", boots = "Bottes", offhand = "Main gauche" }
G.SLOT_ORDER = { "weapon", "hat", "armor", "shoulders", "gloves", "legs", "cape", "boots", "trinket", "offhand" }
G.SLOT_ICONS = { weapon = "🗡️", hat = "🪖", armor = "🥋", trinket = "💍", gloves = "🧤",
	shoulders = "🛡️", legs = "👖", cape = "🧥", boots = "🥾", offhand = "🛡️" }
G.slotOf = Design.slotOf
G.STATS = {
	force = "Force", defense = "Défense", vie = "Vie", vitesse = "Vitesse",
	chance = "Chance", charisme = "Charisme", discretion = "Discrétion",
}
G.STAT_ORDER = { "force", "defense", "vie", "vitesse", "chance", "charisme", "discretion" }
G.RARITIES = {
	{ name = "Commun", color = Color3.fromRGB(217, 217, 204), points = 2, weight = 60 },
	{ name = "Rare", color = Color3.fromRGB(102, 178, 255), points = 4, weight = 28 },
	{ name = "Épique", color = Color3.fromRGB(191, 115, 255), points = 7, weight = 10 },
	{ name = "Légendaire", color = Color3.fromRGB(255, 178, 51), points = 11, weight = 2 },
}
G.WEAPON_NAMES = { "Épée de bois", "Épée de cuivre", "Épée de fer", "Épée d'acier", "Épée d'argent",
	"Épée d'or", "Lame de rubis", "Lame d'émeraude", "Lame de saphir", "Lame des anciens", "Lame de diamant" }
G.HATS = {
	{ "Chapeau de paille", "paille", "vie" }, { "Béret", "beret", "charisme" }, { "Toque", "toque", "chance" },
	{ "Tricorne", "tricorne", "force" }, { "Chapeau de mage", "mage", "chance" }, { "Bonnet rouge", "bonnet", "charisme" },
	{ "Haut-de-forme vert", "hautdeforme", "chance" }, { "Capuche sylvestre", "capuche", "discretion" },
	{ "Bandeau de pirate", "bandeau", "force" },
}
G.ARMORS = { { "Gilet de cuir", "defense" }, { "Cotte de mailles", "defense" }, { "Tunique d'éclaireur", "vitesse" },
	{ "Cape sombre", "discretion" }, { "Plastron de cuivre", "vie" } }
G.TRINKETS = { { "Anneau de fer", "force" }, { "Trèfle porte-bonheur", "chance" }, { "Amulette dorée", "charisme" },
	{ "Plume de corbeau", "discretion" }, { "Pendentif de jade", "vie" } }

local secondary={weapon="force",hat="vie",armor="vie",trinket="chance",gloves="defense",
	shoulders="defense",legs="discretion",cape="charisme",boots="vitesse"}
local function craftedItem(slot, form, dye)
	local rank=dye.rank
	local name=form[1].." "..dye.suffix
	local favorite=form[3]
	local helper=secondary[slot]
	if helper==favorite then helper=favorite=="vie" and "defense" or "vie" end
	local ranged=form[2]=="bow" or form[2]=="crossbow"
	local power=slot=="weapon" and (rank==4 and 12 or rank*2+2) or nil
	return {slot=slot, name=name, rarity=rank, stats={[favorite]=rank+1,[helper]=math.max(1,rank-1)},
		power=power, ranged=ranged or nil, design={form=form[2],material=dye.key}}
end

function G.expandRecipes(config)
	local counts, known = {}, {}
	local function count(item)
		local key = G.slotOf(item) .. ":" .. item.name
		if not known[key] then
			known[key] = true
			local slot = G.slotOf(item)
			counts[slot] = (counts[slot] or 0) + 1
		end
	end
	for _, r in ipairs(config.RECIPES) do
		if r.gear then
			r.gear.slot = G.slotOf(r.gear)
			count(r.gear)
		end
	end
	for _, n in ipairs(G.WEAPON_NAMES) do count({slot="weapon",name=n}) end
	for _, h in ipairs(G.HATS) do count({slot="hat",name=h[1]}) end
	for _, a in ipairs(G.ARMORS) do count({slot="armor",name=a[1]}) end
	for _, t in ipairs(G.TRINKETS) do count({slot="trinket",name=t[1]}) end
	local totals = {}
	for _, slot in ipairs(G.SLOT_ORDER) do
		local before = counts[slot] or 0
		local target = slot=="weapon" and before or math.max(12,math.ceil(before/2))
		local forms = Design.FORMS[slot]
		if not forms then continue end
		local countMaterials = #Design.MATERIALS
		assert(target <= #forms*countMaterials, slot)
		for i=0,target-1 do
			local dye = Design.MATERIALS[i%countMaterials+1]
			-- Décale les formes entre les séries de matières pour couvrir toutes les familles.
			local form = forms[(i%countMaterials+math.floor(i/countMaterials))%#forms+1]
			local item = craftedItem(slot,form,dye)
			assert(not known[slot..":"..item.name],item.name)
			local soft = slot=="cape" or form[2]=="hood" or form[2]=="tunic" or form[2]=="pants" or form[2]=="mantle"
			local needs = { [dye.cloth]=soft and 2+dye.rank or 1+math.floor(dye.rank/2), [dye.hard]=soft and 1 or 1+dye.rank }
			if dye.gem then needs[dye.gem]=1 end
			-- Les signatures supplémentaires empêchent les recettes d’une même série
			-- de toutes sortir du même mélange et de dépasser les six résultats de l’atelier.
			local signatures={"rope","copper_nails","iron_ring","resin","linen_thread","braided_rope","ink","bone","glass","leather_strap","wool_thread","iron_bar"}
			local signature=signatures[(i%countMaterials+table.find(G.SLOT_ORDER,slot)-1)%#signatures+1]
			needs[signature]=(needs[signature] or 0)+1+math.floor(i/countMaterials)
			local skill = {3,11,21,32}
			table.insert(config.RECIPES, {gear=item, needs=needs, station=soft and "bench" or "anvil",
				cat="equipement", skill={"artisanat",skill[dye.rank]+math.floor(i/countMaterials)}})
		end
		totals[slot] = {before=before,added=target}
	end
	config.EQUIPMENT_EXPANSION = totals
end

function G.migrateEquipment(profile)
	local equipped, bag = profile.equipped, profile.gear
	-- Réserve la place aux véritables occupants d’abord, puis déplace le legacy.
	local moved = {}
	for slot, item in pairs(equipped) do
		local target = G.slotOf(item)
		if target~=slot and G.SLOTS[target] then
			equipped[slot]=nil
			item.slot=target
			moved[#moved+1]=item
		end
	end
	for _, item in ipairs(moved) do
		if equipped[item.slot] then bag[#bag+1]=item else equipped[item.slot]=item end
	end
	for _, item in ipairs(bag) do item.slot=G.slotOf(item) end
end

local function rarity(rng: Random, level: number): number
	local total = 0
	local weights = {}
	for i, r in G.RARITIES do
		local w = r.weight * (1 + (i - 1) * level / 4)
		weights[i] = w
		total += w
	end
	local pick = rng:NextNumber() * total
	for i, w in weights do
		pick -= w
		if pick < 0 then
			return i
		end
	end
	return 1
end

-- Tire un objet. `level` 1-10 : plus il est haut, plus les raretés et paliers montent.
function G.roll(rng: Random, level: number, slot: string?)
	-- La main gauche correspond à des recettes dédiées. Les tirages existants restent stables.
	local s = slot or G.SLOT_ORDER[rng:NextInteger(1, #G.SLOT_ORDER - 1)]
	local ri = rarity(rng, level)
	local r = G.RARITIES[ri]
	local item = { slot = s, rarity = ri, stats = {}, visual = "", power = 0, name = "" }
	local favorite = "force"
	if s == "weapon" then
		local tier = math.clamp(level + rng:NextInteger(-1, 1) + ri - 1, 1, #G.WEAPON_NAMES)
		item.visual = tostring(tier)
		item.power = 1 + tier
		item.name = G.WEAPON_NAMES[tier]
		favorite = "force"
	elseif s == "hat" then
		local h = G.HATS[rng:NextInteger(1, #G.HATS)]
		item.name, item.visual, favorite = h[1], h[2], h[3]
	elseif s == "armor" then
		local a = G.ARMORS[rng:NextInteger(1, #G.ARMORS)]
		item.name, favorite = a[1], a[2]
	elseif s == "offhand" then
		item.name, favorite = "Bouclier rond", "defense"
	elseif s == "trinket" then
		local t = G.TRINKETS[rng:NextInteger(1, #G.TRINKETS)]
		item.name, favorite = t[1], t[2]
	else
		local forms = Design.FORMS[s]
		local index = rng:NextInteger(1,math.clamp(math.floor(level*0.9)+ri-1,2,8))
		local form = forms[(index-1)%#forms+1]
		local dye = Design.MATERIALS[index]
		local preset=craftedItem(s,form,dye)
		item.name,item.design,favorite=preset.name,preset.design,form[3]
	end
	item.slot = G.slotOf(item)
	local points = r.points + math.floor(level / 2)
	item.stats[favorite] = math.floor(points / 2) + 1
	for _ = 1, points - math.floor(points / 2) do
		local k = G.STAT_ORDER[rng:NextInteger(1, #G.STAT_ORDER)]
		item.stats[k] = (item.stats[k] or 0) + 1
	end
	item.id = rng:NextInteger(1, 2 ^ 30)
	return item
end

function G.describe(item): string
	local parts = {}
	for _, k in G.STAT_ORDER do
		if item.stats[k] then
			table.insert(parts, string.format("+%d %s", item.stats[k], G.STATS[k]))
		end
	end
	local extra = item.slot == "weapon" and string.format(" (dégâts %d)", item.power) or ""
	local details = ""
	-- exigence de caractéristique (Shared/Equilibre)
	local okE, Eq = pcall(function()
		return require(script.Parent.Equilibre)
	end)
	local req = okE and Eq.requirement(item)
	if req then
		details ..= " · requiert " .. (req[4] or G.STATS[req[1]] or req[1]) .. " " .. req[2]
	end
	if item.ammo and okE and Eq.AMMO_NAME then
		details ..= " · arme de jet (" .. (Eq.AMMO_NAME[item.ammo] or item.ammo) .. ")"
	end
	if item.effect and okE and Eq.EFFECT_TEXT then
		details ..= " · " .. (Eq.EFFECT_TEXT[item.effect] or item.effect)
	end
	local set = okE and Eq.setText(item)
	if set then
		details ..= " · " .. set
	end
	-- bonus de métier (équipement de métier)
	for k, v in item.skills or {} do
		table.insert(parts, string.format("+%d %s", v, (okE and Eq.SKILL_LABEL[k]) or k))
	end
	return string.format("%s [%s]%s%s  %s", item.name, G.RARITIES[item.rarity].name, extra, details, table.concat(parts, "  "))
end

-- Somme des stats de tout l'équipement porté.
function G.totals(equipped): { [string]: number }
	local t = {}
	for _, k in G.STAT_ORDER do
		t[k] = 0
	end
	for _, item in equipped do
		for k, v in item.stats do
			t[k] = (t[k] or 0) + v
		end
	end
	return t
end

-- Catalogue des maquettes par clé de recherche du HUD. Les raccourcis des
-- planches et les anciennes clés restent utilisables pour les anciennes pièces.
function G.visualEntries(config)
	local entries, byName = {}, {}
	local function add(item)
		local key = G.visualKey(item)
		entries[key] = entries[key] or item
		byName[item.name] = byName[item.name] or entries[key]
		return entries[key]
	end
	for _, recipe in config.RECIPES do
		if recipe.gear then add(recipe.gear) end
	end
	for _, entry in config.Prises.KINDS do
		add(entry.gear)
		if entry.soul then add(entry.soul.gear) end
	end
	for _, name in G.WEAPON_NAMES do add({slot = "weapon", name = name}) end
	for _, group in {{G.HATS, "hat"}, {G.ARMORS, "armor"}, {G.TRINKETS, "trinket"}} do
		for _, entry in group[1] do
			local visual = group[2] == "hat" and entry[2] or nil
			entries[entry[1]] = add({slot = group[2], name = entry[1], visual = visual})
		end
	end
	entries.armor = byName["Plastron de cuivre"]
	entries.hat = byName["Chapeau de paille"]
	entries.trinket = byName["Anneau de fer"]
	local previousSlots = {
		armor = {"Bouclier-carapace de tortue ancienne", "Cape", "Cape de soie", "Épaulières de pierre de gargouille animée"},
		trinket = {"Bottes de marais", "Bottes de marche", "Brassards", "Gantelets", "Gants en cuir", "Jambières",
			"Bouclier héraldique", "Bouclier rectangulaire", "Bouclier renforcé au diamant", "Bouclier rond", "Torche"},
	}
	for slot, names in previousSlots do
		for _, name in names do
			entries[slot .. ":" .. name] = assert(byName[name], name)
		end
	end
	-- Pièces encore présentes dans les planches et les sauvegardes antérieures.
	-- Les recettes et leurs statistiques restent celles de Config.
	local oldNames = {
		trinket = {"Anneau de forge cuivrée", "Collier du Loup gris"},
		weapon = {"Arbalète en lin de Valdor", "Arc recourbé en lin de Valdor", "Dague en lin de Valdor",
			"Hache en lin de Valdor", "Lance en lin de Valdor", "Masse en lin de Valdor", "Épée en lin de Valdor",
			"Masse d'os de squelette ancien", "Masse d'os de squelette errant"},
	}
	for slot, names in oldNames do
		for _, name in names do
			local item = {slot = slot, name = name}
			item.rarity = Design.style(item).rank
			add(item)
		end
	end
	return entries
end

function G.visualKey(item): string
	return G.slotOf(item) .. ":" .. item.name
end

return G
