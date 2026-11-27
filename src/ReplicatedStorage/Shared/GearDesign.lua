-- Familles visuelles et matériaux communs au catalogue, à l’avatar et aux aperçus.
local D = {}
local rgb = Color3.fromRGB

-- Les matériaux souples et rigides se combinent selon la pièce. Les couleurs
-- désignent d’abord une matière ou une finition, indépendamment de la rareté.
D.MATERIALS = {
	{ key="lin", suffix="en lin de Valdor", cloth="linen", hard="copper_ingot", rank=1, color=rgb(181,158,107), trim=rgb(111,72,48), mark="stitch" },
	{ key="cuir", suffix="de cuir huilé", cloth="leather", hard="copper_ingot", rank=1, color=rgb(132,80,49), trim=rgb(224,170,97), mark="rivets" },
	{ key="forge", suffix="de forge cuivrée", cloth="soft_leather", hard="copper_ingot", rank=2, color=rgb(174,100,61), trim=rgb(241,180,118), mark="rivets" },
	{ key="loup", suffix="du Loup gris", cloth="fur", hard="iron_ingot", rank=2, color=rgb(100,112,122), trim=rgb(215,210,180), mark="fang" },
	{ key="garde", suffix="de la Garde du pont", cloth="cloth", hard="iron_ingot", rank=2, color=rgb(86,119,155), trim=rgb(216,185,104), mark="crest" },
	{ key="ronces", suffix="des Ronces vertes", cloth="soft_leather", hard="iron_ingot", rank=2, color=rgb(80,118,66), trim=rgb(168,204,110), mark="leaf" },
	{ key="soleil", suffix="du Soleil rouge", cloth="dyed_cloth", hard="steel", rank=3, color=rgb(133,67,52), trim=rgb(236,172,80), mark="sun" },
	{ key="nord", suffix="de la Veille d’hiver", cloth="wool_cloth", hard="steel", rank=3, color=rgb(105,144,159), trim=rgb(208,228,236), mark="frost" },
	{ key="os", suffix="du Reliquaire d’os", cloth="leather", hard="bone", rank=3, color=rgb(152,123,88), trim=rgb(232,221,177), mark="fang" },
	{ key="lune", suffix="de la Lune d’argent", cloth="silk", hard="silver_ingot", rank=3, color=rgb(77,70,112), trim=rgb(197,208,226), mark="moon" },
	{ key="ambre", suffix="de l’Ambre royal", cloth="soft_leather", hard="gold_ingot", gem="amber", rank=4, color=rgb(128,84,52), trim=rgb(235,163,63), mark="gem" },
	{ key="diamant", suffix="au diamant boréal", cloth="soft_leather", hard="steel", gem="diamond", rank=4, color=rgb(92,137,160), trim=rgb(142,221,231), mark="gem" },
}

D.FORMS = {
	weapon = {
		{"Épée", "sword", "force"}, {"Dague", "dagger", "discretion"}, {"Hache", "axe", "force"}, {"Masse", "mace", "force"},
		{"Lance", "pike", "vitesse"}, {"Arc recourbé", "bow", "chance"}, {"Arbalète", "crossbow", "force"}, {"Marteau", "hammer", "defense"},
		{"Espadon", "greatsword", "force"}, {"Hallebarde", "halberd", "defense"}, {"Fauchard", "scythe", "vitesse"}, {"Sabre", "saber", "discretion"},
	},
	hat = {
		{"Casque", "helmet", "defense"}, {"Heaume", "closedhelm", "vie"}, {"Capuche", "hood", "discretion"},
		{"Casque à crête", "cresthelm", "force"}, {"Coiffe", "feathered", "charisme"}, {"Casque nasal", "nasalhelm", "defense"},
	},
	armor = {
		{"Plastron", "plate", "defense"}, {"Tunique", "tunic", "vitesse"}, {"Brigandine", "brigandine", "vie"},
		{"Cotte de mailles", "mail", "defense"}, {"Gilet", "leather", "discretion"}, {"Cuirasse segmentée", "scale", "force"},
	},
	gloves = {
		{"Gants", "gloves", "vitesse"}, {"Gantelets", "gauntlets", "force"}, {"Gants de pisteur", "fingerless", "discretion"},
	},
	shoulders = {
		{"Épaulières", "pauldrons", "defense"}, {"Spallières", "lamellar", "vie"}, {"Épaulières à corne", "hornshoulder", "force"},
	},
	legs = {
		{"Pantalon", "pants", "vitesse"}, {"Chausses", "leggings", "discretion"}, {"Jambières", "greaves", "defense"},
	},
	cape = {
		{"Cape", "cape", "discretion"}, {"Pèlerine", "mantle", "vie"}, {"Mantelet", "splitcape", "charisme"},
	},
	boots = {
		{"Bottes", "boots", "vitesse"}, {"Bottes de marche", "tallboots", "vie"}, {"Solerets", "sabatons", "defense"},
	},
	trinket = {
		{"Anneau", "ring", "chance"}, {"Collier", "necklace", "charisme"}, {"Broche", "brooch", "charisme"},
		{"Pendentif", "pendant", "vie"}, {"Bracelet", "bracelet", "force"}, {"Médaillon", "medallion", "chance"},
	},
}

local palettes = {}
local prises = require(script.Parent.Prises)
local trophies = {}
for _, m in ipairs(D.MATERIALS) do
	palettes[m.key] = m
end
for id, entry in prises.KINDS do
	local source = { id = id, name = entry.name }
	trophies[entry.gear.name] = source
	if entry.soul then trophies[entry.soul.gear.name] = source end
end

function D.lower(name: string): string
	return name:lower():gsub("É","é"):gsub("È","è"):gsub("À","à"):gsub("Â","â"):gsub("Œ","œ")
end

-- Les affixes d'une instance changent son libellé et ses stats. Le dessin reste celui de la série.
function D.baseName(item): string
	local name = item.name or ""
	local affix = item.affixes and item.affixes[1]
	if type(affix) == "string" and affix ~= "" then
		local ending = " " .. affix
		if name:sub(-#ending) == ending then return name:sub(1, -#ending - 1) end
	end
	return name
end

function D.slotOf(it): string
	local slot = it.slot
	if slot ~= "armor" and slot ~= "trinket" then
		return slot
	end
	local n = D.lower(it.name or "")
	if n:match("^bouclier") or n:match("^torche") then return "offhand" end
	if n:match("^cape") or n:match("^pèlerine") or n:match("^mantelet") then return "cape" end
	if n:match("^botte") or n:match("^soleret") then return "boots" end
	if n:match("^gant") or n:match("^brassard") then return "gloves" end
	if n:match("^épaulière") or n:match("^spallière") then return "shoulders" end
	if n:match("^pantalon") or n:match("^chausse") or n:match("^jambière") then return "legs" end
	return slot
end

local function starts(name, prefix)
	return name:sub(1, #prefix) == prefix
end

local formsBySlot = {
	weapon = {
		{"arbalète", "crossbow"}, {"arc court", "shortbow"}, {"arc long", "longbow"}, {"arc", "bow"},
		{"pique", "longpike"}, {"lance", "pike"}, {"javelot", "javelin"}, {"hallebarde", "halberd"},
		{"fauchard", "reaper"}, {"faux", "scythe"}, {"faucille", "sickle"}, {"serpe", "sickle"},
		{"haches de jet", "throwaxes"}, {"hache", "axe"}, {"marteau", "hammer"},
		{"gantelet", "clawglove"}, {"masse-pince", "claw"},
		{"massue", "club"}, {"gourdin", "club"}, {"masse", "mace"}, {"dague", "dagger"},
		{"sabre", "saber"}, {"espadon", "greatsword"}, {"épée bâtarde", "bastard"},
		{"épée courte", "shortsword"}, {"épée longue", "longsword"}, {"lame de dard", "dagger"},
		{"lame venimeuse", "venomblade"}, {"bâton", "staff"}, {"fronde", "sling"},
		{"couteaux", "throwing"}, {"baudrier", "bandolier"},
	},
	hat = {
		{"heaume", "closedhelm"}, {"casque nasal", "nasalhelm"}, {"casque à crête", "cresthelm"},
		{"casque de mineur", "minerhelm"}, {"casque", "helmet"}, {"capuche", "hood"},
		{"cagoule", "cowl"}, {"bandeau", "headband"}, {"béret", "beret"}, {"toque", "toque"},
		{"tricorne", "tricorn"}, {"haut-de-forme", "tophat"}, {"chapeau de mage", "magehat"},
		{"chapeau-champignon", "mushroom"}, {"chapeau à plume", "featherhat"}, {"coiffe", "feathered"},
		{"chapeau de paille", "strawhat"}, {"chapeau de pêcheur", "fisherhat"},
		{"chapeau de traqueur", "hunterhat"}, {"chapka", "chapka"}, {"bonnet", "bonnet"},
		{"couronne de bois", "antlers"}, {"couronne", "crown"}, {"diadème", "diadem"}, {"turban", "turban"},
		{"masque", "mask"}, {"lunettes", "goggles"},
	},
	armor = {
		{"plastron de cœur", "heartplate"}, {"plastron d'élytre", "beetle"},
		{"armure d'écaille", "scale"}, {"armure en écaille", "scale"}, {"cuirasse segmentée", "lamellarplate"},
		{"cotte de maille", "mail"}, {"brigandine", "brigandine"}, {"gambison", "gambeson"},
		{"cotte damassée", "mail"}, {"gilet", "leather"}, {"armure de cuir", "leather"},
		{"manteau", "coat"}, {"robe", "robe"}, {"tablier", "apron"},
		{"tunique", "tunic"}, {"tenue", "tunic"}, {"chemise", "shirt"}, {"blouse", "shirt"}, {"vareuse", "shirt"},
	},
	gloves = {{"gantelet", "gauntlets"}, {"brassard", "bracer"}, {"mitaine", "mittens"},
		{"gants de crocheteur", "fingerless"}, {"gants de pisteur", "fingerless"}},
	shoulders = {{"épaulières à corne", "hornshoulder"}, {"spallière", "lamellar"}},
	legs = {{"jambière", "greaves"}, {"genouillère", "kneepads"}, {"chausse", "leggings"}},
	boots = {{"soleret", "sabatons"}, {"sabot", "clogs"}, {"bottes de marche", "tallboots"}, {"bottes de marais", "tallboots"}},
	cape = {{"mantelet", "splitcape"}, {"pèlerine", "mantle"}, {"ciré", "raincape"}, {"manteau", "dresscape"}},
	offhand = {{"torche", "torch"}, {"bouclier rond", "roundshield"}, {"bouclier rectangulaire", "pavise"},
		{"bouclier-carapace", "shellshield"}},
	trinket = {
		{"écu", "shield"}, {"carapace", "shellshield"}, {"anneau", "ring"}, {"bague", "signet"},
		{"chevalière", "signet"}, {"bracelet", "bracelet"}, {"broche", "brooch"},
		{"collier", "necklace"}, {"chaîne", "necklace"}, {"médaillon", "medallion"},
		{"amulette", "amulet"}, {"talisman", "talisman"}, {"plume", "feather"}, {"trèfle", "clover"},
		{"cœur", "heart"}, {"pierre-cœur", "heart"}, {"éclat", "shard"}, {"fiole", "vial"},
		{"fers à cheval", "horseshoe"}, {"faucille", "sickle"}, {"couteau", "dagger"},
		{"marteau", "hammer"}, {"bâton", "staff"}, {"ceinture", "belt"}, {"trousseau", "keyring"},
		{"cor de", "horn"}, {"sifflet", "whistle"}, {"carquois", "quiver"}, {"filet", "net"},
		{"gourde", "gourd"}, {"panier", "basket"}, {"sacoche", "satchel"}, {"bourse", "pouch"},
		{"selle", "saddle"}, {"bride", "bridle"}, {"lanterne", "lamp"}, {"voile", "veil"},
		{"porte-bonheur", "paw"},
	},
}
local defaults = {weapon = "sword", hat = "brim", armor = "plate", gloves = "gloves", shoulders = "pauldrons",
	legs = "pants", boots = "boots", cape = "cape", offhand = "shield", trinket = "pendant"}
local oldHats = {paille = "strawhat", bonnet = "bonnet", capuche = "hood", toque = "toque", mage = "magehat",
	beret = "beret", tricorne = "tricorn", hautdeforme = "tophat", bandeau = "headband", sherif = "brim"}

function D.formOf(it): string?
	local name, slot = D.lower(it.name or ""), D.slotOf(it)
	if it.design and it.design.form then
		if it.design.form == "scale" then return "lamellarplate" end
		if it.design.form == "scythe" and starts(name, "fauchard") then return "reaper" end
		return it.design.form
	end
	for _, pair in formsBySlot[slot] or {} do
		if starts(name, pair[1]) then return pair[2] end
	end
	if slot == "hat" and not starts(name, "chapeau") and oldHats[it.visual] then return oldHats[it.visual] end
	return defaults[slot]
end

local finishes = {
	{"diamant", "diamant"}, {"forg", "forge"}, {"givre", "nord"}, {"glace", "nord"}, {"neige", "nord"},
	{"hiver", "nord"}, {"polaire", "nord"}, {"loup", "loup"}, {"fourr", "loup"}, {"ours blanc", "nord"},
	{"cuivre", "forge"}, {"bronze", "forge"}, {"ronce", "ronces"}, {"sylvestre", "ronces"}, {"marais", "ronces"},
	{"émeraude", "ronces"}, {"jade", "ronces"}, {"soie", "lune"}, {"saphir", "lune"},
	{"argent", "lune"}, {"rubis", "soleil"}, {"ambre", "ambre"}, {"doré", "ambre"}, {"d'or", "ambre"},
	{"d'os", "os"}, {"lin", "lin"}, {"paille", "lin"}, {"toile", "lin"}, {"cuir", "cuir"},
	{"mailles", "garde"}, {"de fer", "garde"}, {"acier", "nord"},
}
local baseStyle = {
	weapon = "garde", armor = "garde", offhand = "garde", shoulders = "garde",
	hat = "cuir", cape = "lune", gloves = "cuir", boots = "cuir", legs = "lin", trinket = "ambre",
}

function D.style(it)
	if it.design and palettes[it.design.material] then return palettes[it.design.material] end
	local name = D.lower(D.baseName(it))
	for _, palette in D.MATERIALS do
		if name:sub(-#palette.suffix) == D.lower(palette.suffix) then return palette end
	end
	for _, rule in finishes do
		if name:find(rule[1], 1, true) then return palettes[rule[2]] end
	end
	return palettes[baseStyle[D.slotOf(it)]] or palettes.cuir
end

local hardColors = {
	copper_ingot = rgb(184, 109, 66), iron_ingot = rgb(131, 148, 151), steel = rgb(168, 186, 200),
	bone = rgb(220, 202, 160), silver_ingot = rgb(206, 219, 231), gold_ingot = rgb(203, 147, 61),
}

-- Modèles de préproduction. Le catalogue jouable et ses recettes continuent
-- de venir de Config, Prises et Equilibre.
local collections = {
	{ "Gardien royal", "du Gardien royal", "royal", "dyed_cloth", "steel", 4, rgb(41, 59, 94), rgb(242, 189, 82), "crest",
		{{"hat","Heaume","closedhelm"},{"armor","Cuirasse","plate"},{"shoulders","Spallières","lamellar"},
			{"legs","Grèves","greaves"},{"boots","Solerets","sabatons"},{"offhand","Écu","shield"}} },
	{ "Enfant des bois", "de l’Enfant des bois", "sylvestre", "soft_leather", "bone", 3, rgb(65, 95, 52), rgb(168, 202, 99), "leaf",
		{{"hat","Ramure","antlers"},{"armor","Gilet","leather"},{"shoulders","Épaules à ramure","hornshoulder"},
			{"gloves","Mitaines","fingerless"},{"cape","Mantelet","splitcape"},{"weapon","Arc long","longbow"}} },
	{ "Mage des brumes", "du Mage des brumes", "brumes", "silk", "silver_ingot", 4, rgb(80, 66, 121), rgb(171, 213, 238), "moon",
		{{"hat","Chapeau","magehat"},{"armor","Robe","robe"},{"gloves","Brassards","bracer"},
			{"cape","Cape","dresscape"},{"weapon","Bâton","staff"},{"trinket","Talisman","talisman"}} },
	{ "Maître de forge", "du Maître de forge", "maitre_forge", "soft_leather", "copper_ingot", 3, rgb(107, 64, 47), rgb(225, 149, 78), "rivets",
		{{"hat","Casque à visière","minerhelm"},{"armor","Tablier","apron"},{"gloves","Gantelets","gauntlets"},
			{"boots","Bottes hautes","tallboots"},{"trinket","Ceinture","belt"},{"weapon","Marteau","hammer"}} },
	{ "Fermier ancestral", "du Fermier ancestral", "fermier", "linen", "copper_ingot", 3, rgb(128, 111, 61), rgb(240, 211, 130), "stitch",
		{{"hat","Chapeau de paille","strawhat"},{"armor","Tablier","apron"},{"legs","Chausses","leggings"},
			{"boots","Sabots","clogs"},{"weapon","Faucille","sickle"},{"trinket","Panier","basket"}} },
	{ "Marchand royal", "du Marchand royal", "marchand", "silk", "gold_ingot", 3, rgb(132, 44, 54), rgb(234, 176, 88), "sun",
		{{"hat","Haut-de-forme","tophat"},{"armor","Manteau","coat"},{"cape","Pèlerine","mantle"},
			{"gloves","Gants","gloves"},{"trinket","Chevalière","signet"},{"legs","Pantalon","pants"}} },
	{ "Explorateur des océans", "de l’Explorateur des océans", "oceans", "leather", "silver_ingot", 3, rgb(42, 93, 104), rgb(124, 214, 206), "crest",
		{{"hat","Tricorne","tricorn"},{"armor","Manteau","coat"},{"cape","Cape de pluie","raincape"},
			{"boots","Bottes","tallboots"},{"trinket","Fiole","vial"},{"weapon","Javelot","javelin"}} },
}

function D.namedDesigns()
	local designs = {}
	for _, group in collections do
		local title, suffix, material, rank = group[1], group[2], group[3], group[6]
		for _, model in group[10] do
			table.insert(designs, {slot = model[1], name = model[2] .. " " .. suffix,
				rarity = rank, design = {form = model[3], material = material}, collection = title})
		end
	end
	return designs
end

for _, group in collections do
	local key, cloth, hard, rank, color, trim, mark = table.unpack(group, 3, 9)
	palettes[key] = {key = key, cloth = cloth, hard = hard, rank = rank, color = color, trim = trim, mark = mark}
end

local formsBySeries = {
	{ id = "armes", target = 200, slots = {
		{"weapon",{{"Épée courte","shortsword"},{"Épée longue","longsword"},{"Lame bâtarde","bastard"},{"Javelot","javelin"},
			{"Arc court","shortbow"},{"Arc long","longbow"},{"Pique","longpike"},{"Fronde","sling"},{"Bâton","staff"},
			{"Massue","club"},{"Haches de jet","throwaxes"},{"Couteaux de jet","throwing"}}},
	}},
	{ id = "armures", target = 300, slots = {
		{"offhand",{{"Rondache","roundshield"},{"Écu","shield"},{"Pavois","pavise"}}},
		{"armor",D.FORMS.armor}, {"shoulders",D.FORMS.shoulders}, {"gloves",{{"Brassards","bracer"},{"Gantelets","gauntlets"}}},
		{"legs",{{"Grèves","greaves"},{"Genouillères","kneepads"}}}, {"boots",{{"Solerets","sabatons"}}},
		{"hat",{{"Heaume","closedhelm"},{"Casque nasal","nasalhelm"},{"Casque à crête","cresthelm"}}},
	}},
	{ id = "civil", target = 150, slots = {
		{"hat",{{"Béret","beret"},{"Toque","toque"},{"Chapeau à plume","featherhat"},{"Haut-de-forme","tophat"},{"Tricorne","tricorn"},
			{"Turban","turban"},{"Chapka","chapka"},{"Bonnet","bonnet"}}},
		{"armor",{{"Chemise","shirt"},{"Robe","robe"},{"Manteau","coat"}}},
		{"cape",{{"Cape de pluie","raincape"},{"Cape d’apparat","dresscape"},{"Pèlerine","mantle"}}},
		{"legs",{{"Pantalon","pants"},{"Chausses","leggings"}}}, {"boots",{{"Sabots","clogs"},{"Bottes de marche","tallboots"}}},
		{"gloves",{{"Moufles","mittens"}}},
	}},
	{ id = "metier", target = 120, slots = {
		{"hat",{{"Casque de mineur","minerhelm"},{"Chapeau de pêcheur","fisherhat"},{"Chapeau de traqueur","hunterhat"},{"Chapeau de paille","strawhat"}}},
		{"armor",{{"Tablier","apron"},{"Manteau de travail","coat"}}},
		{"trinket",{{"Marteau","hammer"},{"Serpe","sickle"},{"Panier","basket"},{"Gourde","gourd"},{"Lampe","lamp"},
			{"Sacoche","satchel"},{"Bourse","pouch"},{"Ceinture","belt"},{"Filet","net"},{"Bridon","bridle"}}},
	}},
	{ id = "accessoires", target = 100, slots = {
		{"trinket",{{"Chevalière","signet"},{"Talisman","talisman"},{"Amulette","amulet"},{"Broche","brooch"},
			{"Médaillon","medallion"},{"Bracelet","bracelet"},{"Pendentif","pendant"},{"Collier","necklace"},
			{"Carquois","quiver"},{"Corne","horn"},{"Sifflet","whistle"}}},
	}},
}

function D.seriesDesigns(totals, existing)
	local designs = {}
	local used = table.clone(existing)
	for _, group in formsBySeries do
		local left = math.max(0, group.target - (totals[group.id] or 0))
		local forms = {}
		for _, slotForms in group.slots do
			for _, form in slotForms[2] do
				table.insert(forms, {slotForms[1], form[1], form[2]})
			end
		end
		for pass = 1, #D.MATERIALS do
			for i, form in forms do
				if left == 0 then break end
				local dye = D.MATERIALS[(pass + i * 5 - 2) % #D.MATERIALS + 1]
				local name, slot = form[2] .. " " .. dye.suffix, form[1]
				local key = slot .. ":" .. name
				if not used[key] then
					used[key] = true
					left -= 1
					table.insert(designs, {slot = slot, name = name, rarity = dye.rank,
						design = {form = form[3], material = dye.key}, series = group.id})
				end
			end
			if left == 0 then break end
		end
	end
	return designs
end
local namedColors = {
	{"rubis", rgb(185, 53, 63)}, {"saphir", rgb(72, 129, 199)}, {"émeraude", rgb(64, 169, 118)},
	{"diama", rgb(143, 219, 239)}, {"jade", rgb(79, 170, 132)}, {"ambre", rgb(238, 160, 55)},
}
local anatomy = {
	{"venin", "venom"}, {"dard", "sting"}, {"griffe", "claws"}, {"croc", "fangs"}, {"défense", "tusk"},
	{"pince", "pincer"}, {"écaille", "scales"}, {"élytre", "elytra"}, {"carapace", "shell"},
	{"corne", "horn"}, {"ramure", "antlers"}, {"bois de cerf", "antlers"}, {"plume", "feather"},
	{"aile membraneuse", "wing"}, {"queue de renard", "tail"}, {"soie", "silk"}, {"givre", "ice"},
	{"cristal de glace", "ice"}, {"cœur", "core"}, {"gelée", "gel"}, {"essence", "essence"},
	{"spore", "spores"}, {"oreille", "ear"}, {"d'os", "bone"}, {"os ", "bone"},
	{"patte", "paw"}, {"poussière", "dust"}, {"crin", "hair"}, {"insigne", "badge"},
	{"écu", "crest"}, {"chair", "hide"}, {"peau", "hide"}, {"tentacule", "tentacle"},
}
local faunaColors = {
	{{"spectral", "fantôme", "ombre", "nocturne"}, rgb(104, 106, 167)},
	{{"glace", "neige", "givre", "polaire", "blanc", "brumeglace", "blizzard"}, rgb(138, 205, 219)},
	{{"sable", "désert", "grès", "dune", "chacal"}, rgb(194, 150, 85)},
	{{"lac", "marin", "rivière", "eaux", "profond", "anguille", "bleu"}, rgb(63, 154, 168)},
	{{"marais", "vase", "tourbière", "croco", "ronce", "racine", "serpent"}, rgb(95, 139, 84)},
	{{"flamant", "dragonnet", "royal", "renard", "feu"}, rgb(192, 101, 71)},
	{{"noir", "corbeau", "caverne"}, rgb(78, 83, 114)},
}

local function firstMatch(name, rules)
	for _, rule in rules do
		if name:find(rule[1], 1, true) then return rule[2] end
	end
	return nil
end

local torsoFamilies = {
	tunic = "tissu", shirt = "tissu", apron = "tissu", gambeson = "tissu",
	leather = "cuir", brigandine = "brigandine", mail = "mailles",
	scale = "ecailles", lamellarplate = "ecailles", plate = "plates",
	robe = "robes", coat = "robes", beetle = "creatures", heartplate = "creatures",
}

local signedTorsos = {
	["cuirasse des anciens"] = true, ["plastron serti de diamant"] = true,
	["cotte damassée"] = true, ["brigandine de bois de cœur"] = true,
	["manteau des moissons"] = true, ["manteau du roi des loups"] = true,
	["armure d'écailles noires"] = true,
}

local function torsoFamily(name, form, trophy)
	if signedTorsos[name] or name:find("légendaire", 1, true) then return "legendaires" end
	if trophy and (form == "scale" or form == "tunic" or form == "coat") then return "creatures" end
	return torsoFamilies[form] or "plates"
end

function D.appearance(item)
	local baseName = D.baseName(item)
	local name = D.lower(baseName)
	local form, style, slot = D.formOf(item), D.style(item), D.slotOf(item)
	local trophy = trophies[baseName]
	local source = trophy and D.lower(trophy.name) or name
	local trait = firstMatch(source, anatomy)
	local hash = 0
	for i = 1, #name do hash = (hash * 131 + name:byte(i)) % 2147483647 end
	local accent = firstMatch(name, namedColors) or style.trim
	local hide = style.color
	if trophy then
		for _, group in faunaColors do
			local found = false
			for _, word in group[1] do
				if name:find(word, 1, true) then found = true break end
			end
			if found then
				accent, hide = group[2], hide:Lerp(group[2], 0.56)
				break
			end
		end
	end
	local material = style.hard == "bone" and "Bone" or "Metal"
	local metal = hardColors[style.hard]
	if firstMatch(name, {{"de bois", true}, {"bois pétrifié", true}}) and not trophy then
		metal, material = rgb(151, 104, 56), "Wood"
	elseif (trait == "ice" and (form == "sword" or form == "staff")) or name:find("verre vivant", 1, true) then
		metal, material = rgb(125, 190, 203), "Glass"
	elseif name:find("d'acier", 1, true) or name:find("au diamant boréal", 1, true) then
		metal = hardColors.steel
	elseif name:find("de fer", 1, true) and style.key == "garde" then
		metal = rgb(106, 115, 127)
	end
	if form == "magehat" then hide = rgb(84, 65, 126) end
	if form == "bonnet" and name:find("rouge", 1, true) then hide = rgb(161, 48, 56) end
	if form == "tophat" and name:find("vert", 1, true) then hide = rgb(59, 108, 70) end
	if form == "toque" then hide = rgb(231, 217, 185) end
	if form == "strawhat" then hide = rgb(207, 174, 93) end
	if form == "tricorn" or form == "headband" then hide = hide:Lerp(rgb(36, 27, 37), 0.64) end
	local family
	if slot == "armor" then
		family = torsoFamily(name, form, trophy)
		if name == "cotte damassée" then
			metal, accent = rgb(92, 103, 123), rgb(202, 213, 227)
		elseif name == "armure d'écailles noires" then
			hide, accent = rgb(39, 41, 47), rgb(142, 84, 76)
		elseif name == "cuirasse des anciens" or name:find("^armure de plates") or name:find("^armure de chevalier") then
			metal = hardColors.steel
		elseif name == "manteau des moissons" then
			hide, accent = rgb(117, 82, 53), rgb(230, 185, 94)
		elseif name == "tunique" or name == "tenue de fermier" then
			hide = palettes.lin.color
		elseif name == "robe" then
			hide = palettes.lune.color
		end
	end
	return {
		form = form, slot = slot, torsoFamily = family, color = hide, trim = style.trim, accent = accent, metal = metal,
		material = material, hard = style.hard, cloth = style.cloth, series = style.key, mark = style.mark, trait = trait, name = name,
		soul = name:find("légendaire", 1, true) ~= nil,
		rarity = item.rarity or (name:find("légendaire", 1, true) and 4 or 1),
		variant = hash % 5, profile = math.floor(hash / 5) % 7, cut = math.floor(hash / 35) % 17,
	}
end

return D
