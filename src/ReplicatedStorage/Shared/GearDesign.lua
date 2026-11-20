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
for _, m in ipairs(D.MATERIALS) do
	palettes[m.key] = m
end

function D.lower(name: string): string
	return name:lower():gsub("É","é"):gsub("È","è"):gsub("À","à"):gsub("Â","â"):gsub("Œ","œ")
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

function D.formOf(it): string?
	if it.design then return it.design.form end
	local n = D.lower(it.name or "")
	local s = D.slotOf(it)
	if s=="gloves" then return n:match("^gant de") and "fingerless" or n:match("^gantelet") and "gauntlets" or "gloves" end
	if s=="shoulders" then return n:find("corne",1,true) and "hornshoulder" or "pauldrons" end
	if s=="legs" then return n:match("^jambière") and "greaves" or "pants" end
	if s=="cape" then return "cape" end
	if s=="boots" then return n:find("marais",1,true) and "tallboots" or "boots" end
	if s=="offhand" then
		if n:match("^torche") then return "torch" end
		return n:find("rond", 1, true) and "roundshield" or "shield"
	end
	if s=="weapon" then
		if n:match("^arbalète") then return "crossbow" end
		if n:match("^arc ") then return "bow" end
		if n:match("^hallebarde") then return "halberd" end
		if n:match("^lance") or n:match("^pique") then return "pike" end
		if n:match("^faux") or n:match("^fauchard") then return "scythe" end
		if n:match("^faucille") or n:match("^serpe") then return "sickle" end
		if n:match("^hache") then return "axe" end
		if n:match("^marteau") then return "hammer" end
		if n:match("^gantelet") then return "gauntlet" end
		if n:match("^masse%-pince") then return "claw" end
		if n:match("^masse") or n:match("^massue") or n:match("^gourdin") then return "mace" end
		if n:match("^dague") then return "dagger" end
		if n:match("^sabre") then return "saber" end
		if n:match("^espadon") then return "greatsword" end
	elseif s=="armor" then
		if n:find("écaille",1,true) then return "scale" end
		if n:find("élytre",1,true) then return "beetle" end
		if n:find("maille",1,true) then return "mail" end
		if n:match("^manteau") then return "coat" end
		if n:match("^tunique") or n:match("^tenue") or n:match("^chemise") or n:match("^robe") then return "tunic" end
		if n:match("^brigandine") then return "brigandine" end
		if n:find("cuir",1,true) or n:match("^gilet") then return "leather" end
		return "plate"
	elseif s=="hat" then
		if n:match("^heaume") then return "closedhelm" end
		if n:match("^casque nasal") then return "nasalhelm" end
		if n:match("^casque") then return "helmet" end
		if n:match("^bandeau") then return "headband" end
		if n:match("^béret") then return "beret" end
		if n:match("^toque") then return "toque" end
		if n:match("^tricorne") then return "tricorn" end
		if n:match("^haut%-de%-forme") then return "tophat" end
		if n:find("de mage",1,true) then return "magehat" end
	elseif s=="trinket" then
		if n:match("^faucille") then return "sickle" end
		if n:match("^plume") then return "feather" end
		if n:match("^trèfle") then return "clover" end
		if n:match("^broche") then return "brooch" end
		if n:match("^bracelet") then return "bracelet" end
		if n:match("^médaillon") then return "medallion" end
	end
	return nil
end

function D.style(it)
	if it.design and palettes[it.design.material] then return palettes[it.design.material] end
	local n=D.lower(it.name or "")
	for _, rule in ipairs({
		{"diamant","diamant"},{"givre","nord"},{"glace","nord"},{"neige","nord"},{"hiver","nord"},
		{"loup","loup"},{"fourr","loup"},{"maill","garde"},{"fer","garde"},{"cuivre","forge"},
		{"ronce","ronces"},{"sylvestre","ronces"},{"marais","ronces"},{"soie","lune"},
		{"ambre","ambre"},{"royal","ambre"},{"os","os"},{"lin","lin"},{"cuir","cuir"},
	}) do
		if n:find(rule[1],1,true) then return palettes[rule[2]] end
	end
	return palettes.cuir
end

return D
