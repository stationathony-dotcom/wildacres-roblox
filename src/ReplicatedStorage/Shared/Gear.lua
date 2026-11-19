-- Équipement façon MMORPG : emplacements, raretés, statistiques tirées au hasard.
-- Les stats touchent aussi le côté « GTA » : charisme = prix et opinion, discrétion = vue des PNJ.

local G = {}

G.SLOTS = { weapon = "Arme", hat = "Chapeau", armor = "Armure", trinket = "Bijou" }
G.SLOT_ORDER = { "weapon", "hat", "armor", "trinket" }
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
	"Épée d'or", "Lame de rubis", "Lame d'émeraude", "Lame de saphir", "Lame des anciens" }
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
	local s = slot or G.SLOT_ORDER[rng:NextInteger(1, 4)]
	local ri = rarity(rng, level)
	local r = G.RARITIES[ri]
	local item = { slot = s, rarity = ri, stats = {}, visual = "", power = 0, name = "" }
	local favorite = "force"
	if s == "weapon" then
		local tier = math.clamp(level + rng:NextInteger(-1, 1) + ri - 1, 1, 10)
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
	else
		local t = G.TRINKETS[rng:NextInteger(1, #G.TRINKETS)]
		item.name, favorite = t[1], t[2]
	end
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
	local made = (item.quality and (" · " .. item.quality) or "") .. (item.maker and (" · par " .. item.maker) or "")
	-- exigence de caractéristique (Shared/Equilibre)
	local okE, Eq = pcall(function()
		return require(script.Parent.Equilibre)
	end)
	local req = okE and Eq.requirement(item)
	if req then
		made ..= " · requiert " .. (req[4] or G.STATS[req[1]] or req[1]) .. " " .. req[2]
	end
	-- bonus de métier (équipement de métier)
	for k, v in item.skills or {} do
		table.insert(parts, string.format("+%d %s", v, (okE and Eq.SKILL_LABEL[k]) or k))
	end
	return string.format("%s [%s]%s%s  %s", item.name, G.RARITIES[item.rarity].name, extra, made, table.concat(parts, "  "))
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

return G
