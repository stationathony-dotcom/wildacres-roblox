-- Catalogue médiéval (d'après « liste items.txt ») : tous les objets du monde au-delà du noyau de Config.
-- Règle : chaque objet sert à quelque chose. Il se mange, se boit, se pose, se porte, se lit, s'ouvre,
-- entre dans une recette, se vend, ou se collectionne (et se revend cher aux bons villages).
--
-- Une ligne = un objet : "id|Nom|icône|prix|genre|recette|onglet"
--   genre : m            matière (ingrédient)
--           f20          nourriture / boisson (+20 vie)
--           p:arch:coul  objet posé ; arch = forme générée par code (voir ARCH) ou @Modele existant
--           v            objet de valeur / collection (se vend, se troque)
--           u:usage:arg  objet utilisable (livre:compétence, bourse:or, tresor, musique, soin:vie)
--   recette : ingrédients "wood2 stone1", puis >N (quantité), @bench / @furnace, #compétence:niveau
--             "-" = pas de recette : l'objet se trouve (récolte, pêche, chasse, butin, événements)
--   onglet : onglet de l'atelier (Config.CRAFT_TABS) ; par défaut selon le genre.

local K = {}

K.TABS = {
	{ id = "metiers", name = "Métiers" },
	{ id = "alchimie", name = "Alchimie" },
	{ id = "decoration", name = "Décoration" },
	{ id = "ferme", name = "Ferme" },
	{ id = "commerce", name = "Commerce" },
	{ id = "savoir", name = "Savoir" },
	{ id = "loisirs", name = "Loisirs" },
}

-- Nouvelles cultures (graines vendues aux villages des biomes, plantées comme les autres)
K.CROPS = {
	barley = { name = "Orge", icon = "🌾", price = 22, seed_price = 7, biomes = { "prairie", "neige" }, skill = 2, days = 3, color = Color3.fromRGB(214, 190, 110), shape = "wheat" },
	oat = { name = "Avoine", icon = "🌾", price = 20, seed_price = 6, biomes = { "prairie", "foret" }, skill = 1, days = 3, color = Color3.fromRGB(226, 206, 140), shape = "wheat" },
	rye = { name = "Seigle", icon = "🌾", price = 24, seed_price = 8, biomes = { "neige", "foret" }, skill = 3, days = 3, color = Color3.fromRGB(180, 160, 100), shape = "wheat" },
	turnip = { name = "Navet", icon = "🧅", price = 28, seed_price = 9, biomes = { "prairie", "neige" }, skill = 1, days = 3, color = Color3.fromRGB(230, 220, 236), shape = "root" },
	cabbage = { name = "Chou", icon = "🥬", price = 40, seed_price = 13, biomes = { "foret", "neige" }, skill = 4, days = 4, color = Color3.fromRGB(120, 180, 90), shape = "big" },
	onion = { name = "Oignon", icon = "🧅", price = 30, seed_price = 10, biomes = { "desert", "prairie" }, skill = 2, days = 3, color = Color3.fromRGB(200, 140, 80), shape = "root" },
	garlic = { name = "Ail", icon = "🧄", price = 32, seed_price = 10, biomes = { "desert", "marais" }, skill = 3, days = 3, color = Color3.fromRGB(240, 236, 220), shape = "root" },
	pea = { name = "Pois", icon = "🌱", price = 26, seed_price = 8, biomes = { "prairie", "marais" }, skill = 2, days = 3, color = Color3.fromRGB(110, 190, 80), shape = "bush" },
	bean = { name = "Haricots", icon = "🌰", price = 30, seed_price = 9, biomes = { "foret", "marais" }, skill = 3, days = 3, color = Color3.fromRGB(150, 80, 60), shape = "bush" },
	squash = { name = "Courge", icon = "🎃", price = 70, seed_price = 22, biomes = { "marais", "desert" }, skill = 8, days = 5, color = Color3.fromRGB(230, 180, 60), shape = "big" },
	flax = { name = "Lin", icon = "🌿", price = 18, seed_price = 6, biomes = { "prairie", "marais" }, skill = 2, days = 3, color = Color3.fromRGB(120, 150, 220), shape = "wheat" },
	hops = { name = "Houblon", icon = "🌿", price = 34, seed_price = 11, biomes = { "foret", "prairie" }, skill = 6, days = 4, color = Color3.fromRGB(160, 210, 100), shape = "bush" },
	grape = { name = "Raisin", icon = "🍇", price = 55, seed_price = 18, biomes = { "desert", "prairie" }, skill = 10, days = 5, color = Color3.fromRGB(110, 50, 130), shape = "bush" },
	herbs = { name = "Herbes aromatiques", icon = "🌿", price = 16, seed_price = 5, biomes = { "prairie", "foret", "desert", "neige", "marais" }, skill = 0, days = 2, color = Color3.fromRGB(90, 160, 80), shape = "bush" },
}
K.CROP_ORDER = { "barley", "oat", "rye", "turnip", "cabbage", "onion", "garlic", "pea", "bean", "squash", "flax", "hops", "grape", "herbs" }

local LINES = [[
# ---------- Ressources naturelles (trouvailles en récoltant)
oak_log|Rondin de chêne|🌲|6|m|-|
pine_log|Rondin de pin|🌲|5|m|-|
branches|Branches|🌿|1|m|-|
bark|Écorce|🟫|2|m|-|
straw|Paille|🌾|1|m|wheat1 >3|materiaux
reeds|Roseaux|🎋|2|m|-|
flint|Silex|⛰️|4|m|-|
arrow|Flèche|🏹|2|m|wood1 flint1 feather1 >8 @bench|equipement
gravel|Gravier|⛰️|1|m|stone1 >2|materiaux
silver_ore|Minerai d'argent|⚪|30|m|-|
sulfur|Soufre|🟡|12|m|-|
salt|Sel|🧂|8|m|-|
amber|Ambre|🟠|60|v|-|
pearl|Perle|⚪|90|v|-|
tooth|Dent|🦷|6|m|-|
horn|Corne|📯|20|m|-|
scales|Écailles|🐉|16|m|-|
resin|Résine|🟧|8|m|-|
beeswax|Cire d'abeille|🕯️|14|m|honey1 >2|materiaux
antler|Bois de cerf|🦌|24|m|-|
fat|Graisse|🥓|6|m|meat2|materiaux
# ---------- Graines d'arbre (tombent en abattant ; se plantent, l'arbre pousse en 3 jours)
seed_tree_chene|Gland (chêne)|🌰|4|u:planter:tree_chene|-|
seed_tree_sapin|Pomme de pin (sapin)|🌲|4|u:planter:tree_sapin|-|
seed_tree_bouleau|Graine de bouleau|🌱|4|u:planter:tree_bouleau|-|
seed_tree_cerisier|Noyau de cerise|🍒|6|u:planter:tree_cerisier|-|
seed_tree_saule|Bouture de saule|🌿|4|u:planter:tree_saule|-|
# ---------- Forge
silver_ingot|Lingot d'argent|🥈|80|m|silver_ore2 coal1 @furnace|materiaux
steel|Acier|🔩|90|m|iron_ingot2 coal2 @furnace #artisanat:14|materiaux
nails|Clous|📌|3|m|iron_ingot1 >12 @anvil|metiers
copper_nails|Clous de cuivre|📌|2|m|copper_ingot1 >12 @anvil|metiers
peg|Chevilles en bois|🌲|1|m|planks1 >3|metiers
hinge|Charnière|🔩|10|m|iron_ingot1 >3 @anvil|metiers
chain|Chaîne|⛓️|24|m|iron_ingot2 @anvil #artisanat:6|metiers
hook|Hameçon|🎣|6|m|iron_ingot1 >3 @anvil|metiers
iron_ring|Anneau métallique|⭕|5|m|iron_ingot1 >4 @anvil|metiers
fitting|Ferrure|🔩|8|m|iron_ingot1 >3 @anvil|metiers
iron_bar|Barre de fer|🦯|30|m|iron_ingot2 @furnace|metiers
blade|Lame brute|🔪|40|m|steel1 @anvil #artisanat:12|metiers
buckle|Boucle|🔘|6|m|copper_ingot1 >4 @anvil|metiers
rivet|Rivets|🔩|2|m|copper_ingot1 >10 @anvil|metiers
gear_wood|Engrenage en bois|⚙️|12|m|planks4 peg4 @bench #artisanat:5|metiers
gear_iron|Engrenage en fer|⚙️|50|m|iron_ingot2 @anvil #artisanat:10|metiers
pulley|Poulie|⚙️|20|m|gear_wood1 rope2 @bench|metiers
# ---------- Tannerie
raw_hide|Peau brute|🟫|10|m|-|
deer_hide|Peau de cerf|🦌|22|m|-|
wolf_pelt|Peau de loup|🐺|28|m|-|
scraped_hide|Peau raclée|🟫|14|m|raw_hide1 flint1 @tannery|metiers
soft_leather|Cuir souple|🟫|30|m|leather2 fat1 @tannery #artisanat:5|metiers
worked_fur|Fourrure travaillée|🦊|36|m|fur2 salt1 @tannery|metiers
leather_strap|Sangles|🎗️|8|m|leather1 >3 @tannery|metiers
# ---------- Tissage
linen_thread|Fil de lin|🧵|6|m|flax3 >2|metiers
wool_thread|Fil de laine|🧶|20|m|wool1 >3 @loom|metiers
linen|Tissu de lin|🧵|20|m|linen_thread3 @loom|metiers
wool_cloth|Tissu de laine|🧶|50|m|wool_thread3 @loom|metiers
canvas|Toile|⛵|30|m|linen2 rope1 @loom|metiers
braided_rope|Corde tressée|➰|14|m|rope3 @bench|metiers
dyed_cloth|Étoffe teinte|🎨|60|m|cloth1 dye1 @loom|metiers
fine_cloth|Tissu précieux|🎐|160|v|silk3 dye1 gold_ingot1 @loom #artisanat:16|commerce
# ---------- Poterie (au four)
prepared_clay|Argile préparée|🟤|5|m|clay2 sand1|metiers
pot|Pot|🏺|14|m|prepared_clay1 @furnace|metiers
jug|Cruche|🏺|18|m|prepared_clay2 @furnace|metiers
plate|Assiette|🍽️|10|m|prepared_clay1 >2 @furnace|metiers
bowl|Bol|🥣|8|m|prepared_clay1 >2 @furnace|metiers
amphora|Amphore|🏺|40|m|prepared_clay3 @furnace #artisanat:6|metiers
bottle|Bouteille en verre|🍾|12|m|glass1 @furnace|metiers
vial|Fiole vide|🧪|10|m|glass1 >2 @furnace|alchimie
wood_cup|Gobelet en bois|🥤|2|m|planks1 >2|metiers
mug|Chope en terre cuite|🍺|10|m|prepared_clay1 @furnace|metiers
tankard|Chope en métal|🍺|26|m|copper_ingot1 @bench|metiers
wood_plate|Assiette en bois|🍽️|2|m|planks1 >2|metiers
spoon|Cuillère en bois|🥄|1|m|planks1 >3|metiers
ladle|Louche|🥄|8|m|planks1 copper_ingot1 >2 @bench|metiers
table_fork|Fourchette ancienne|🍴|18|v|copper_ingot1 >2 @anvil|metiers
table_knife|Couteau de table|🍴|28|v|iron_ingot1 planks1 >2 @anvil|metiers
gourd|Gourde|🏺|14|u:boire:25|leather1 rope1|metiers
waterskin|Outre en cuir|🏺|18|u:boire:40|leather2 @bench|metiers
paper|Papier|📄|4|m|wood1 >3 @bench|savoir
parchment|Parchemin vierge|📜|8|m|scraped_hide1 >3 @bench|savoir
ink|Encre|🖋️|8|m|coal1 berries2 >3|savoir
quill|Plume d'écriture|🐦|3|m|feather1 >2|savoir
inkwell|Encrier|🖋️|16|m|glass1 ink1 @bench|savoir
wax_seal|Sceau de cire|🔴|10|m|beeswax1 dye1 >3|savoir
dye|Teinture|🎨|10|m|flower2 >2|alchimie
soap|Savon|🧼|12|u:buff:charisme|fat2 salt1 >3|metiers
candle_wax|Bougie (cire)|🕯️|10|m|beeswax1 rope1 >3|metiers
compost|Sac de compost|🌱|8|u:engrais|rotten2 fiber2 >2|ferme
bait|Appâts|🐛|2|m|rotten1 >6|ferme
animal_feed|Nourriture animale|🌾|6|u:nourrir|wheat1 oat1 >3|ferme
hay|Foin|🌾|3|m|straw3 >2|ferme
# ---------- Alchimie et herboristerie (plantes trouvées en cueillant)
chamomile|Camomille|🌼|6|m|-|
mint|Menthe|🌿|6|m|-|
sage|Sauge|🌿|8|m|-|
thyme|Thym|🌿|6|m|-|
lavender|Lavande|💜|9|m|-|
rosemary|Romarin|🌿|8|m|-|
nettle|Ortie|🌿|3|m|-|
st_john|Millepertuis|🌼|12|m|-|
valerian|Valériane|🌸|14|m|-|
mandrake|Mandragore|🌱|120|m|-|
rare_mushroom|Champignon rare|🍄|60|m|-|
night_flower|Fleur nocturne|🌙|70|m|-|
ancient_root|Racine ancienne|🌳|80|m|-|
pollen|Pollen|🟡|6|m|-|
dried_petals|Pétales séchés|🌸|8|m|flower3 >2|alchimie
mineral_powder|Poudre minérale|✨|14|u:engrais|stone3 sulfur1 >2 @furnace|alchimie
extract|Fiole d'extrait|🧪|30|m|vial1 herbs2 @alembic #cuisine:4|alchimie
healing_potion|Potion de soin|❤️|80|f60|vial1 st_john1 chamomile1 honey1 @alembic #cuisine:8|alchimie
vigor_elixir|Élixir de vigueur|💪|160|f90|extract1 mandrake1 @alembic #cuisine:16|alchimie
night_elixir|Élixir nocturne|🌙|200|f80|extract1 night_flower1 wisp_dust1 @alembic #cuisine:20|alchimie
incense|Encens|🪔|20|u:buff:chance|resin1 lavender1 >2|alchimie
sage_tea|Infusion de sauge|🍵|24|f25|sage2 @alembic|alchimie
evening_tea|Tisane du soir|🍵|36|f40|valerian2 chamomile1 @alembic|alchimie
nettle_soup|Soupe d'orties|🥣|30|f30|nettle3 @furnace|cuisine
herbal_salve|Baume d'herboriste|🧴|70|f55|nettle2 sage1 fat1 @alembic #cuisine:6|alchimie
calming_draught|Philtre apaisant|🧪|110|f70|extract1 valerian2 rosemary1 @alembic #cuisine:10|alchimie
perfume|Parfum|🌸|90|v|bottle1 lavender2 rosemary1 #cuisine:6|commerce
# ---------- Ingrédients et cuisine
butter|Beurre|🟨|40|f12|milk2|cuisine
cheese|Fromage|🧀|70|f30|milk3 salt1 @furnace #cuisine:4|cuisine
sugar|Sucre|🍬|12|m|beetroot2 @furnace|cuisine
oil|Huile|🌿|14|m|pea3 @bench|cuisine
apple|Pomme|🍎|10|f8|-|
pear|Poire|🍐|10|f8|-|
plum|Prune|🟣|12|f8|-|
venison|Viande de cerf|🥩|16|f5|-|
boar_meat|Viande de sanglier|🥩|14|f5|-|
rabbit_meat|Viande de lapin|🥩|10|f4|-|
raw_fish|Poisson cru|🐟|8|f5|-|
crab|Crabe|🦀|30|f10|-|
crayfish|Écrevisse|🦞|24|f8|-|
shellfish|Coquillage|🐚|14|f6|-|
salmon|Saumon|🐟|50|f14|-|
whole_bread|Pain complet|🍞|90|f32|wheat2 rye2 @furnace #cuisine:3|cuisine
galette|Galette|🥞|40|f18|oat2 butter1 @furnace|cuisine
roast|Viande rôtie|🍖|60|f36|venison1 herbs1 @furnace #cuisine:2|cuisine
roast_boar|Sanglier rôti|🍖|70|f40|boar_meat1 garlic1 @furnace #cuisine:4|cuisine
smoked_fish|Poisson fumé|🐟|40|f28|raw_fish2 salt1 @furnace|cuisine
apple_pie|Tarte aux pommes|🥧|150|f50|apple3 wheat1 butter1 sugar1 @furnace #cuisine:9|cuisine
meat_pie|Tourte à la viande|🥧|170|f58|meat2 wheat2 onion1 @furnace #cuisine:11|cuisine
cooked_veg|Légumes cuits|🥗|50|f24|turnip1 cabbage1 @furnace|cuisine
porridge|Bouillie|🥣|30|f20|oat2 milk1 @furnace|cuisine
salad|Salade|🥗|40|f18|cabbage1 herbs1 oil1|cuisine
dried_fruit|Fruits séchés|🍇|30|f14|apple1 plum1 grape1 >3|cuisine
jerky|Viande séchée|🥓|30|f16|meat1 salt1 >2|cuisine
rabbit_stew|Civet de lapin|🍲|110|f46|rabbit_meat2 onion1 garlic1 @furnace #cuisine:7|cuisine
fish_soup|Soupe de poisson|🍲|90|f40|crab1 shellfish1 herbs1 @furnace #cuisine:6|cuisine
rations|Rations|🎒|60|f30|jerky1 whole_bread1 dried_fruit1 >2|cuisine
# ---------- Boissons
water|Eau|💧|2|f4|bucket1 wood_cup1 >2|cuisine
apple_juice|Jus de pomme|🧃|24|f12|apple3 wood_cup1|cuisine
berry_juice|Jus de baies|🧃|20|f10|berries4 wood_cup1|cuisine
grape_juice|Jus de raisin|🍷|40|f16|grape2 wood_cup1|cuisine
mint_tea|Infusion de menthe|🍵|20|f12|mint2 mug1 @furnace|cuisine
chamomile_tea|Infusion de camomille|🍵|22|f14|chamomile2 mug1 @furnace|cuisine
thyme_tea|Infusion de thym|🍵|22|f14|thyme2 mug1 @furnace|cuisine
broth|Bouillon|🍲|30|f18|bone2 herbs1 bowl1 @furnace|cuisine
fruit_syrup|Sirop de fruits|🍯|50|f20|berries4 sugar2 bottle1 @furnace #cuisine:5|cuisine
cider|Cidre|🍺|60|f20|apple4 bottle1 @bench #cuisine:6|cuisine
ale|Bière d'orge|🍺|50|f18|barley3 hops1 tankard1 @bench #cuisine:5|cuisine
vinegar|Vinaigre de pomme|🏺|20|m|cider1|cuisine
pickled_onions|Oignons au vinaigre|🧅|60|f35|onion3 vinegar1 salt1|cuisine
nailed_crate|Caisse clouée|📦|40|p:@Caisses|planks4 copper_nails6 @bench|decoration
barque|Barque|⛵|120|u:barque|planks12 rope2 @bench|loisirs
voilier|Voilier|⛵|420|u:voilier|planks20 canvas3 rope4 nails6 @bench #artisanat:14|loisirs
nasse|Nasse|🧺|35|u:nasse|fiber10 rope2 wood2 @bench #peche:2|loisirs
banniere|Bannière de clan|🚩|80|u:banniere|planks4 cloth3 rope1 @bench|commerce
# ---------- Rangement et quotidien (de valeur, troqués, commandés par les villages)
satchel|Sacoche en cuir|👜|40|v|leather3 buckle1 @bench|metiers
canvas_bag|Besace en toile|👜|30|v|canvas1 rope1 @bench|metiers
document_case|Porte-documents|📁|40|v|leather2 paper1 buckle1 @bench|savoir
merchant_bag|Sac de marchand|👜|85|v|canvas2 soft_leather1 buckle2 @bench|commerce
wicker_basket|Panier en osier|🧺|16|v|reeds4|metiers
flour_sack|Sac de farine|🛍️|60|v|flour3 linen1|commerce
seed_sack|Sac de graines|🛍️|40|u:graines|linen1 seed_wheat4|ferme
jewel_box|Boîte à bijoux|🎁|90|v|planks3 gold_ingot1 @bench #artisanat:10|commerce
scroll_case|Étui à parchemins|📜|30|v|leather2 copper_ingot1 @bench|savoir
craft_kit|Trousse d'artisan|🧰|80|u:livre:artisanat|leather2 nails6 hook2 @bench|metiers
comb|Peigne|💈|8|v|bone1 >2|metiers
brush|Brosse|🖌️|8|v|planks1 fur1 >2|metiers
pocket_mirror|Miroir de poche|🔍|40|v|glass1 silver_ingot1 @bench|metiers
towel|Serviette en lin|🧺|20|v|linen1|metiers
blanket|Couverture|🛏️|50|v|wool_cloth1|metiers
pillow|Oreiller|🛏️|24|v|linen1 feather4|metiers
# ---------- Commerce
copper_coin|Pièce de cuivre|🟠|1|v|-|
silver_coin|Pièce d'argent|⚪|10|v|-|
gold_coin|Pièce d'or|🟡|50|v|-|
coin_purse|Bourse|👝|0|u:bourse:60|-|
merchant_purse|Bourse de marchand|👝|0|u:bourse:200|-|
precious_ingot|Lingot précieux|🥇|400|v|gold_ingot2 silver_ingot2 @furnace #artisanat:20|commerce
ruby|Rubis|🔴|250|v|-|
sapphire|Saphir|🔵|250|v|-|
emerald|Émeraude|🟢|280|v|-|
diamond|Diamant|💎|500|v|-|
necklace|Collier|📿|300|v|gold_ingot1 pearl2 @bench #artisanat:14|commerce
ring_gem|Bague sertie|💍|400|v|gold_ingot1 ruby1 @bench #artisanat:18|commerce
bracelet|Bracelet|⭕|180|v|silver_ingot2 @bench #artisanat:10|commerce
brooch|Broche|🔶|220|v|silver_ingot1 amber1 @bench #artisanat:12|commerce
crown|Couronne|👑|1500|v|gold_ingot4 diamond1 ruby1 sapphire1 @bench #artisanat:34|commerce
spice|Épices|🌶️|40|m|-|
spice_sack|Sac d'épices|🛍️|220|v|spice5 linen1|commerce
salt_sack|Sac de sel|🛍️|60|v|salt6 linen1|commerce
cloth_bale|Ballot de tissu|🧶|200|v|cloth5 rope1|commerce
fruit_crate|Caisse de fruits|📦|90|v|apple4 pear2 planks2|commerce
veg_basket|Panier de légumes|🧺|80|v|carrot2 cabbage1 turnip2 wicker_basket1|commerce
packed_goods|Marchandise emballée|📦|160|v|linen2 rope2 planks3 amphora1|commerce
scales_tool|Balance|⚖️|60|v|copper_ingot2 planks2 @bench|commerce
weights|Poids de mesure|⚖️|30|v|iron_ingot1 @furnace|commerce
ledger|Registre commercial|📒|50|u:livre:commerce|paper6 leather1 ink1 @bench|commerce
bill_exchange|Lettre de change|📃|0|u:bourse:150|-|
contract|Contrat de vente|📃|20|v|parchment1 ink1 wax_seal1|commerce
# ---------- Exploration et aventure
backpack|Sac à dos|🎒|80|v|leather4 leather_strap2 @bench #artisanat:6|metiers
map_region|Carte régionale|🗺️|40|v|parchment2 ink1 #commerce:2|savoir
map_world|Carte du monde|🗺️|160|v|map_region3 ink2 #commerce:10|savoir
sea_chart|Carte maritime|🗺️|120|v|parchment3 ink2 #peche:8|savoir
treasure_map|Carte au trésor|🗺️|0|u:carte_tresor|map_fragment4|savoir
old_page|Page ancienne|📜|15|u:page|-|savoir
miner_lamp|Lampe de mineur|🏮|30|v|copper_ingot1 resin2 rope1 @bench|outils
charter|Charte de ville|📜|300|v|planks20 stone20 rope4 ink1 @bench #commerce:10|savoir
map_fragment|Fragment de carte|🧩|20|m|-|
compass|Boussole|🧭|70|v|copper_ingot1 iron_ingot1 glass1 @bench #artisanat:8|savoir
old_compass|Boussole ancienne|🧭|260|v|-|
hourglass|Sablier|⏳|60|v|glass2 sand2 planks1 @bench|savoir
spyglass|Longue-vue|🔭|220|v|glass2 copper_ingot2 leather1 @bench #artisanat:14|savoir
climbing_rope|Corde d'escalade|➰|30|v|braided_rope2 hook1|metiers
rusty_key|Clé rouillée|🗝️|10|v|-|
ancient_key|Clé ancienne|🗝️|120|v|-|
relic|Relique|🏺|300|v|-|
relic_fragment|Fragment de relique|🧩|40|m|-|
ancient_coin|Pièce ancienne|💰|80|v|-|
ancient_jewel|Bijou ancien|💍|240|v|-|
carved_stone|Pierre gravée|⛰️|90|v|-|
artifact|Artefact|🔮|600|v|relic_fragment5 ancient_root1 #artisanat:25|savoir
talisman|Talisman|🧿|0|v|-|
seal|Sceau|🔴|40|v|copper_ingot1 wax_seal1 @bench|savoir
message_bottle|Bouteille à la mer|🍾|0|u:tresor|-|
lost_item|Objet perdu|❔|30|v|-|
traveler_journal|Journal d'un voyageur|📔|0|u:livre:peche|-|
inscription|Fragment d'inscription|⛰️|50|v|-|
# ---------- Savoir et progression (se lisent : expérience dans une compétence, le livre est consommé)
skill_book|Livre de compétence|📕|200|u:livre:combat|paper8 leather2 ink2 @bench #artisanat:8|savoir
manual_farm|Manuel d'agriculture|📗|120|u:livre:agriculture|paper6 leather1 ink1 wheat5 @bench|savoir
manual_cook|Manuel de cuisine|📙|120|u:livre:cuisine|paper6 leather1 ink1 bread2 @bench|savoir
manual_fish|Manuel de pêche|📘|120|u:livre:peche|paper6 leather1 ink1 fish2 @bench|savoir
manual_tame|Manuel de dressage|📒|120|u:livre:dressage|paper6 leather1 ink1 bone3 @bench|savoir
manual_craft|Manuel d'artisanat|📓|140|u:livre:artisanat|paper6 leather1 ink1 iron_ingot1 @bench|savoir
manual_mine|Manuel du mineur|📔|140|u:livre:minage|paper6 leather1 ink1 ore2 @bench|savoir
manual_wood|Manuel du bûcheron|📔|120|u:livre:bucheronnage|paper6 leather1 ink1 oak_log2 @bench|savoir
manual_herd|Manuel d'élevage|📗|120|u:livre:elevage|paper6 leather1 ink1 egg3 @bench|savoir
manual_lock|Carnet du crocheteur|📓|200|u:livre:crochetage|paper6 leather1 ink1 lockpick3 @bench|savoir
recipe_book|Livre de recettes|📖|160|u:recette:cuisine|paper8 leather1 ink2 @bench #cuisine:6|savoir
creature_book|Livre des créatures|📖|180|u:livre:combat|paper8 leather1 ink2 bone4 @bench|savoir
botany_book|Livre de botanique|📖|160|u:livre:agriculture|paper8 leather1 ink2 dried_petals3 @bench|savoir
history_book|Livre d'histoire|📖|100|v|paper8 leather1 ink2 @bench|savoir
rare_book|Livre rare|📚|400|v|-|
unknown_recipe|Recette inconnue|📜|0|u:recette:|-|
craftsman_plan|Plan d'artisan|📐|0|u:recette:artisanat|-|
diploma|Diplôme d'apprentissage|📜|80|v|parchment1 ink1 wax_seal1 #artisanat:20|savoir
recommendation|Lettre de recommandation|✉️|60|v|parchment1 ink1 wax_seal1 #commerce:8|savoir
# ---------- Loisirs et social
dice|Osselets|🦴|10|v|bone2|loisirs
board_game|Jeu de plateau|♟️|40|v|planks3 stone2|loisirs
cards|Jeu de cartes|🃏|30|v|paper6 ink1|loisirs
flute|Flûte|🎶|40|u:musique|reeds3 @bench|loisirs
lute|Luth|🪕|160|u:musique|planks6 rope3 @bench #artisanat:10|loisirs
harp|Harpe|🎼|240|u:musique|planks8 copper_ingot2 rope4 @bench #artisanat:14|loisirs
drum|Tambour|🥁|80|u:musique|planks4 leather2 @bench|loisirs
bell_small|Clochette|🔔|20|u:musique|copper_ingot1|loisirs
horn_call|Corne d'appel|📯|60|u:musique|horn1 copper_ingot1 @bench|loisirs
trumpet|Trompette|🎺|140|u:musique|copper_ingot4 @bench #artisanat:8|loisirs
songbook|Livre de chansons|🎶|60|v|paper6 ink1|loisirs
leather_ball|Ballon en cuir|⚽|20|v|leather2 straw2|loisirs
kite|Cerf-volant|🪁|20|v|linen1 branches4|loisirs
hoop|Cerceau|⭕|6|v|planks2|loisirs
wood_toy|Jouet en bois|🧸|20|v|planks2 dye1|loisirs
rag_doll|Poupée de chiffon|🧸|24|v|linen1 straw2|loisirs
wood_figurine|Figurine en bois|🗿|40|v|oak_log1 #artisanat:4|loisirs
stone_figurine|Figurine en pierre|🗿|60|v|stone4 #artisanat:6|loisirs
fair_ticket|Billet de foire|🎟️|10|v|paper1|loisirs
ribbon|Ruban de compétition|🎀|40|v|dyed_cloth1|loisirs
medal|Médaille de concours|🏅|120|v|silver_ingot1 dyed_cloth1 @bench|loisirs
champion_ribbon|Ruban de champion|🏆|200|v|-|
event_token|Jeton d'événement|💰|30|v|-|
festival_prize|Récompense de festival|🎁|0|u:bourse:120|-|
# ---------- Collection et rares
fossil|Fossile|🦴|120|v|-|
rare_shell|Coquillage rare|🐚|90|v|-|
colored_stone|Pierre colorée|💠|30|v|-|
ruin_piece|Objet d'une ruine|🏺|150|v|-|
old_vase|Vase ancien|🏺|160|v|-|
decorated_ceramic|Céramique décorée|🏺|90|v|amphora1 dye2 @furnace #artisanat:8|commerce
royal_seal|Sceau royal|👑|500|v|-|
painting|Tableau|🖼️|180|v|canvas1 dye4 planks2 #artisanat:12|decoration
ancient_scale|Écaille ancienne|🐉|300|v|-|
rare_horn|Corne de bête rare|📯|260|v|-|
monster_tooth|Dent de monstre|🦷|60|m|-|
claw|Griffe de créature|🐾|50|m|-|
night_feather|Plume nocturne|🐦|90|m|-|
mystery_egg|Œuf mystérieux|🥚|0|u:tresor|-|
glowstone|Pierre lumineuse|✨|120|m|-|
ancient_crystal|Cristal ancien|💎|260|m|-|
mineral_heart|Cœur minéral|💗|500|v|-|
moon_flower|Fleur lunaire|🌙|180|m|-|
glow_mushroom|Champignon phosphorescent|🍄|80|m|-|
petrified_wood|Bois pétrifié|🌲|120|v|-|
fossil_bone|Os fossilisé|🦴|140|v|-|
meteorite|Fragment de météorite|☄️|400|m|-|
royal_fur|Fourrure royale (Vargor)|🐺|700|m|-|
black_scale|Écaille noire (Roi des marais)|🖤|700|m|-|
golden_carapace|Carapace dorée (Scarabée royal)|🐞|800|m|-|
frost_crystal|Cristal de givre (Brumeglace)|❄️|800|m|-|
lost_crown|Couronne oubliée|👑|1500|v|-|
mimic_tongue|Langue de mimique (Coffre-mimique)|👅|800|m|-|
angler_lure|Leurre des abysses (Baudroie)|🏮|800|m|-|
mammoth_tusk|Défense de givre (Mammouth)|🦣|800|m|-|
storm_feather|Plume d'orage (Griffon d'orage)|⚡|800|m|-|
widow_silk|Soie noire (Veuve des cavernes)|🕸️|800|m|-|
croc_king_hide|Cuir de roi-croco (Crocodile des marais)|🐊|800|m|-|
# ---------- Faction et armée
clan_banner|Bannière de clan|🚩|60|p:banniere:R|cloth2 planks2 dye1 @bench|decoration
guard_badge|Insigne de garde|🛡️|60|v|iron_ingot1 dye1 @bench|commerce
sheriff_badge|Insigne de shérif|⭐|200|v|-|
patrol_log|Registre de patrouille|📒|30|v|paper4 ink1|savoir
recruit_contract|Contrat de recrutement|📃|40|v|parchment1 ink1 wax_seal1|savoir
supply_chest|Coffre de ravitaillement|📦|120|v|planks6 rations2 @bench|commerce
provision_bag|Sac de provisions|🎒|90|f40|rations1 linen1|cuisine
# ---------- Mobilier (posé)
big_table|Grande table|🪑|0|p:grandetable:B|planks8 nails4 @bench|mobilier
stool|Tabouret|🪑|0|p:tabouret:B|planks2|mobilier
double_bed|Lit double|🛏️|0|p:litdouble:R|planks8 wool_cloth2 pillow2 @bench #artisanat:6|mobilier
straw_bed|Paillasse|🛏️|0|p:paillasse:Y|straw8 linen1|mobilier
wardrobe|Armoire|🚪|0|p:armoire:BF|planks10 hinge2 @bench #artisanat:4|mobilier
reinforced_chest|Coffre renforcé|📦|0|p:coffre:F|planks6 iron_bar2 @bench #artisanat:8|mobilier
bookcase|Bibliothèque|📚|0|p:biblio:BF|planks10 history_book1 @bench|mobilier
keepsake_box|Coffret|🎁|0|p:coffret:BF|planks2 hinge1 @bench|mobilier
counter|Comptoir|🌲|0|p:comptoir:B|planks10 nails4 @bench|mobilier
desk|Bureau|🖋️|0|p:bureau:BF|planks8 inkwell1 @bench|mobilier
fireplace|Cheminée|🔥|0|p:cheminee:P|stone20 brick10 @bench #artisanat:6|mobilier
hearth|Foyer|🔥|0|p:foyer:P|stone10 coal2|mobilier
bread_oven|Four à pain|🍞|0|p:fourpain:T|brick16 clay6 @bench #artisanat:5|mobilier
cauldron|Chaudron|🍲|0|p:chaudron:N|iron_ingot4 @bench #artisanat:6|mobilier
washtub|Bassine|🛁|0|p:bassine:B|planks4 iron_ring2|mobilier
barrel|Tonneau|🛢️|0|p:tonneau:B|planks6 iron_ring2 @bench|mobilier
keg|Baril|🛢️|0|p:baril:BF|planks4 iron_ring1 @bench|mobilier
tool_rack|Étagère à outils|🧰|0|p:etagere:BF|planks5 hook4|mobilier
armor_stand|Porte-armure|🛡️|0|p:mannequin:F|planks4 iron_bar1 @bench|mobilier
crate|Caisse|📦|0|p:caisse:B|planks4 nails2|mobilier
loom|Métier à tisser|🧵|0|p:metier:B|planks12 rope4 gear_wood2 @bench #artisanat:8|mobilier
press|Presse|🍇|0|p:presse:BF|planks10 iron_bar2 gear_wood2 @bench #artisanat:10|mobilier
# ---------- Décoration (posée)
banner|Bannière|🚩|0|p:banniere:BL|cloth2 planks2|decoration
flag|Drapeau|🏳️|0|p:drapeau:W|linen2 branches3|decoration
coat_arms|Blason|🛡️|0|p:blason:R|planks3 dye2 @bench|decoration
shop_sign|Enseigne de boutique|🚩|0|p:enseigne:B|planks3 chain1 @bench|decoration
statue|Statue|🗿|0|p:statue:PC|stone30 #artisanat:12|decoration
sculpture|Sculpture|🗿|0|p:sculpture:PC|stone15 #artisanat:8|decoration
vase_deco|Vase|🏺|0|p:vase:T|amphora1|decoration
pitcher|Pichet|🏺|0|p:pichet:BL|prepared_clay2 dye1 @furnace|decoration
clay_pot|Pot en terre cuite|🏺|0|p:pot:T|pot1|decoration
planter|Jardinière|🌷|0|p:jardiniere:B|planks4 dirt4 flower3|decoration
wall_torch|Torche murale|🔥|0|p:torche:BF|branches2 resin1 iron_ring1|decoration
brazier|Brasero|🔥|0|p:brasero:F|iron_ingot3 coal2 @bench|decoration
candle|Bougie|🕯️|0|p:bougie:W|candle_wax1|decoration
candelabra|Chandelier|🕯️|0|p:chandelier:O|copper_ingot2 candle_wax3 @bench|decoration
curtain|Rideau|🎭|0|p:rideau:R|cloth2 rope1|decoration
tapestry|Tenture|🎨|0|p:tenture:VI|dyed_cloth3 @bench #artisanat:6|decoration
painting_wall|Peinture murale|🖼️|0|p:tableau:O|painting1|decoration
deco_shield|Bouclier décoratif|🛡️|0|p:blason:BL|planks3 iron_ring1 dye1|decoration
deco_armor|Armure décorative|🛡️|0|p:mannequin:PC|iron_ingot6 @bench #artisanat:10|decoration
trophy|Trophée|🏆|0|p:trophee:O|antler1 planks2|decoration
creature_skull|Crâne de créature|💀|0|p:crane:W|bone6 monster_tooth2|decoration
clock|Horloge mécanique|🕰️|0|p:horloge:BF|planks8 gear_iron3 glass1 @bench #artisanat:16|decoration
weathervane|Girouette|🐓|0|p:girouette:F|iron_bar1 copper_ingot1 @bench|decoration
carpet_big|Grand tapis|🟥|0|p:tapis:R|wool_cloth2 dye1|decoration
# ---------- Ferme et élevage (posés)
stone_fence|Clôture en pierre|🧱|0|p:muret:P|stone4 >2|ferme
palisade|Palissade|🌲|0|p:palissade:B|oak_log3 >2|ferme
farm_gate|Portail de ferme|🚪|0|p:portail:B|planks6 hinge2|ferme
stable|Étable|🐄|0|p:cabane:B|planks30 straw10 nails10 @bench #elevage:4|ferme
horse_stable|Écurie|🐎|0|p:cabane:BF|planks40 straw12 nails12 @bench #elevage:6|ferme
henhouse|Poulailler|🐔|0|p:poulailler:B|planks12 straw6 @bench|ferme
pigsty|Porcherie|🐖|0|p:enclos:BF|planks16 @bench|ferme
sheepfold|Bergerie|🐑|0|p:cabane:BC|planks30 straw10 @bench #elevage:3|ferme
barn|Grange|🏚️|0|p:grange:R|planks50 nails20 hinge4 @bench #artisanat:10|ferme
granary|Grenier|🌾|0|p:grenier:B|planks30 stone10 @bench #artisanat:6|ferme
feeder|Mangeoire|🌾|0|p:mangeoire:B|planks4 hay2|ferme
trough|Abreuvoir|💧|0|p:abreuvoir:B|planks4 bucket1|ferme
hay_rack|Râtelier à foin|🌾|0|p:ratelier:B|planks4 hay4|ferme
well|Puits|🧺|0|p:@Puits:P|stone20 planks4 rope2 bucket_empty1 @bench #artisanat:4|ferme
pen|Enclos|🐑|0|p:enclos:B|fence6|ferme
herd_bell|Clochette de troupeau|🔔|20|u:rappel|copper_ingot1 rope1|ferme
# ---------- Machines et mécanismes (posés)
water_wheel|Roue à eau|⚙️|0|p:roue:B|planks20 gear_wood4 iron_bar2 @bench #artisanat:12|construction
winch|Treuil|➰|0|p:treuil:B|planks6 rope4 pulley1 @bench #artisanat:6|construction
wood_crane|Grue en bois|🏗️|0|p:grue:B|oak_log10 rope6 pulley2 @bench #artisanat:14|construction
lever|Levier|🕹️|0|p:levier:F|iron_bar1 planks1|construction
water_pump|Pompe à eau|⛲|0|p:pompe:F|iron_ingot4 gear_iron1 @bench #artisanat:12|construction
irrigation|Canal d'irrigation|💧|0|p:canal:P|stone6 >2|construction
portcullis|Herse|⛓️|0|p:herse:F|iron_bar6 chain2 @bench #artisanat:14|construction
drawbridge|Pont-levis|🌉|0|p:pontlevis:BF|oak_log8 chain4 pulley2 @bench #artisanat:16|construction
ladder|Échelle en bois|🔝|0|p:echelle:B|planks3 >2|construction
rope_ladder|Échelle de corde|➰|0|p:echelle:Y|rope4|construction
stone_arch|Arche en pierre|🏛️|0|p:arche:PC|stone16 @bench #artisanat:8|construction
wood_arch|Arche en bois|🏛️|0|p:arche:B|planks10 @bench #artisanat:4|construction
pedestal|Socle|🏛️|0|p:socle:PC|stone6|construction
barn_door|Porte de grange|🚪|0|p:porte:R|planks10 hinge2 @bench|construction
double_door|Porte double|🚪|0|p:portedouble:BF|planks12 hinge4 @bench #artisanat:6|construction
castle_door|Porte de château|🏰|0|p:portedouble:F|oak_log10 iron_bar4 hinge4 @bench #artisanat:18|construction
trapdoor|Trappe en bois|🟫|0|p:trappe:B|planks4 hinge2|construction
shutter|Volet|🖼️|0|p:volet:V|planks2 hinge1|construction
round_window|Fenêtre ronde|🖼️|0|p:fenetreronde:B|glass2 planks2 @bench|construction
arched_window|Fenêtre arquée|🖼️|0|p:fenetre:PC|glass3 stone4 @bench #artisanat:5|construction
stained_glass|Vitrail|🖼️|0|p:vitrail:VI|glass4 dye3 @bench #artisanat:14|construction
arrow_slit|Meurtrière|🏰|0|p:meurtriere:P|stone6|construction
cart|Charrette|🛒|0|p:chariot:B|planks12 iron_ring4 @bench #artisanat:6|construction
merchant_cart|Chariot de marchand|🛒|0|p:chariot:R|planks20 canvas2 iron_ring4 @bench #commerce:5|construction
wheelbarrow|Brouette|🛒|0|p:brouette:B|planks4 iron_ring1|construction
sled|Traîneau|🛷|0|p:traineau:B|planks6 iron_bar1|construction
rowboat|Barque|🚣|0|p:barque:B|planks16 nails8 @bench #artisanat:8|construction
raft|Radeau|🛶|0|p:radeau:BC|oak_log6 rope4|construction
anchor|Ancre|⚓|60|v|iron_bar3 chain1 @bench|construction
travel_chest|Coffre de transport|🧳|0|p:coffre:BC|planks6 leather_strap2 @bench|mobilier
]]

-- Équipement fabriqué (porté) : armes, armures, vêtements, harnais, outils de métier portés à la ceinture.
-- Stats : force, defense, vie, vitesse, discretion, chance, charisme ; power = dégâts d'une arme.
K.GEAR = {
	-- armes
	{ "weapon", "Dague", 1, { discretion = 2, vitesse = 1 }, { iron_ingot = 1, leather = 1 }, 4, power = 3, visual = "2" },
	{ "weapon", "Épée courte", 1, { force = 2 }, { iron_ingot = 2, planks = 1 }, 6, power = 4, visual = "3" },
	{ "weapon", "Épée longue", 2, { force = 4 }, { steel = 2, leather = 1 }, 16, power = 6, visual = "5" },
	{ "weapon", "Épée bâtarde", 3, { force = 5, defense = 1 }, { steel = 3, silver_ingot = 1, leather = 1 }, 24, power = 7, visual = "6" },
	{ "weapon", "Hache de combat", 2, { force = 4, vie = 1 }, { steel = 2, oak_log = 1 }, 14, power = 6, visual = "4" },
	{ "weapon", "Masse", 2, { force = 5 }, { iron_bar = 2, planks = 1 }, 12, power = 6, visual = "4" },
	{ "weapon", "Marteau de guerre", 3, { force = 6 }, { steel = 3, oak_log = 1 }, 22, power = 7, visual = "6" },
	{ "weapon", "Lance", 1, { force = 2, vitesse = 1 }, { iron_ingot = 1, pine_log = 1 }, 5, power = 4, visual = "3" },
	{ "weapon", "Pique", 2, { force = 3, defense = 1 }, { steel = 1, pine_log = 2 }, 12, power = 5, visual = "4" },
	{ "weapon", "Hallebarde", 3, { force = 5, defense = 2 }, { steel = 3, oak_log = 2 }, 22, power = 7, visual = "6" },
	{ "weapon", "Arc court", 1, { chance = 2, vitesse = 1 }, { pine_log = 1, linen_thread = 2 }, 4, power = 3, visual = "2" },
	{ "weapon", "Arc long", 2, { chance = 3, force = 2 }, { oak_log = 2, linen_thread = 3, resin = 1 }, 14, power = 5, visual = "4" },
	{ "weapon", "Arbalète", 3, { force = 4, chance = 2 }, { steel = 2, oak_log = 1, gear_iron = 1, braided_rope = 1 }, 22, power = 7, visual = "6" },
	{ "weapon", "Faux", 2, { force = 3, chance = 1 }, { steel = 1, pine_log = 2 }, 10, power = 5, visual = "4" },
	{ "weapon", "Serpe", 1, { vitesse = 2 }, { iron_ingot = 1, planks = 1 }, 3, power = 3, visual = "2" },
	{ "weapon", "Dague au diamant", 4, { discretion = 6, vitesse = 4 }, { steel = 2, diamond = 1, soft_leather = 1 }, 31, power = 9, visual = "11" },
	{ "weapon", "Espadon au diamant", 4, { force = 8, defense = 3 }, { steel = 4, diamond = 2, gold_ingot = 1, leather = 2 }, 36, power = 12, visual = "11" },
	{ "weapon", "Hache de combat au diamant", 4, { force = 7, vie = 4 }, { steel = 3, diamond = 2, oak_log = 1 }, 34, power = 11, visual = "11" },
	{ "weapon", "Masse au diamant", 4, { force = 8, vie = 3 }, { steel = 3, diamond = 2, silver_ingot = 1 }, 35, power = 11, visual = "11" },
	{ "weapon", "Marteau de guerre au diamant", 4, { force = 7, defense = 4 }, { steel = 4, diamond = 2, oak_log = 1 }, 36, power = 12, visual = "11" },
	{ "weapon", "Lance au diamant", 4, { force = 6, vitesse = 5 }, { steel = 2, diamond = 1, pine_log = 2 }, 32, power = 10, visual = "11" },
	{ "weapon", "Hallebarde au diamant", 4, { force = 7, defense = 4 }, { steel = 4, diamond = 2, oak_log = 2 }, 37, power = 12, visual = "11" },
	{ "weapon", "Arc long au diamant", 4, { chance = 7, vitesse = 4 }, { oak_log = 3, linen_thread = 4, diamond = 1, resin = 2 }, 33, power = 10, visual = "11" },
	{ "weapon", "Arbalète au diamant", 4, { force = 7, chance = 4 }, { steel = 3, diamond = 2, gear_iron = 2, braided_rope = 2 }, 37, power = 12, visual = "11" },
	{ "armor", "Plastron serti de diamant", 4, { defense = 9, vie = 4 }, { steel = 5, diamond = 2, leather = 3 }, 38 },
	{ "hat", "Heaume serti de diamant", 4, { defense = 7, vie = 4 }, { steel = 3, diamond = 1, soft_leather = 2 }, 34 },
	{ "offhand", "Bouclier renforcé au diamant", 4, { defense = 8, force = 3 }, { oak_log = 3, steel = 2, diamond = 1 }, 34 },
	{ "trinket", "Anneau serti de diamant", 4, { chance = 7, charisme = 4 }, { gold_ingot = 2, diamond = 1, silver_ingot = 1 }, 36 },
	-- boucliers portés en main gauche
	{ "offhand", "Bouclier rond", 1, { defense = 3 }, { planks = 4, iron_ring = 2 }, 4 },
	{ "offhand", "Bouclier rectangulaire", 2, { defense = 5 }, { planks = 6, fitting = 4, leather = 1 }, 12 },
	{ "offhand", "Bouclier héraldique", 3, { defense = 5, charisme = 3 }, { steel = 2, dye = 2, leather = 1 }, 20 },
	-- vêtements
	{ "armor", "Tunique", 1, { vitesse = 1, charisme = 1 }, { linen = 2 }, 1 },
	{ "armor", "Chemise en lin", 1, { charisme = 1, vie = 1 }, { linen = 2, linen_thread = 1 }, 1 },
	{ "armor", "Robe", 1, { charisme = 3 }, { dyed_cloth = 2 }, 4 },
	{ "armor", "Cape", 1, { discretion = 3 }, { wool_cloth = 2, buckle = 1 }, 4 },
	{ "armor", "Manteau d'hiver", 2, { vie = 3, defense = 1 }, { wool_cloth = 2, worked_fur = 2 }, 8 },
	{ "armor", "Tenue de marchand", 2, { charisme = 4, chance = 1 }, { dyed_cloth = 2, fine_cloth = 1 }, 10 },
	{ "armor", "Tenue de fermier", 1, { vie = 2, vitesse = 1 }, { linen = 2, straw = 2 }, 2 },
	{ "armor", "Tenue de garde", 2, { defense = 4, charisme = 1 }, { wool_cloth = 2, leather = 2, dye = 1 }, 10 },
	{ "armor", "Cotte de mailles", 2, { defense = 6 }, { iron_ring = 30, leather = 1 }, 14 },
	{ "armor", "Armure de plates", 3, { defense = 9, vie = 2 }, { steel = 6, leather_strap = 4, rivet = 20 }, 26 },
	{ "armor", "Armure de chevalier", 4, { defense = 11, vie = 3, charisme = 2 }, { steel = 8, fine_cloth = 1, leather_strap = 4, rivet = 30 }, 34 },
	{ "armor", "Armure en écailles", 3, { defense = 7, vitesse = 2 }, { scales = 12, soft_leather = 2 }, 20 },
	-- couvre-chefs
	{ "hat", "Capuche", 1, { discretion = 2 }, { wool_cloth = 1 }, 2, visual = "capuche" },
	{ "hat", "Chapeau de paille", 1, { vie = 1 }, { straw = 6 }, 0, visual = "paille" },
	{ "hat", "Chapeau de feutre", 1, { charisme = 2 }, { wool_cloth = 1, feather = 1 }, 3, visual = "beret" },
	{ "hat", "Casque", 2, { defense = 3 }, { iron_ingot = 3, leather = 1 }, 10, visual = "bonnet" },
	{ "hat", "Heaume", 3, { defense = 5, vie = 1 }, { steel = 3, leather = 1 }, 22, visual = "bonnet" },
	-- accessoires (breloques)
	{ "trinket", "Ceinture de cuir", 1, { force = 1, vie = 1 }, { leather_strap = 2, buckle = 1 }, 2 },
	{ "trinket", "Bottes de marche", 1, { vitesse = 2 }, { soft_leather = 2 }, 6 },
	{ "trinket", "Gants en cuir", 1, { force = 1, chance = 1 }, { soft_leather = 1 }, 4 },
	{ "trinket", "Gantelets", 2, { force = 2, defense = 2 }, { steel = 1, leather = 1 }, 14 },
	{ "trinket", "Jambières", 2, { defense = 3, vitesse = 1 }, { iron_ingot = 2, leather = 2 }, 10 },
	{ "trinket", "Brassards", 2, { defense = 2, force = 1 }, { iron_ingot = 2, leather_strap = 2 }, 10 },
	{ "trinket", "Talisman ancien", 3, { chance = 5, vie = 2 }, { carved_stone = 1, ancient_jewel = 1 }, 18 },
	{ "trinket", "Pendentif d'ambre", 2, { chance = 3, charisme = 2 }, { amber = 2, silver_ingot = 1 }, 12 },
	{ "trinket", "Fiole de pierre lumineuse", 3, { discretion = 3, chance = 3 }, { glowstone = 2, vial = 1 }, 18 },
	-- pièces légendaires des boss uniques
	{ "armor", "Manteau du Roi des loups", 4, { vitesse = 4, force = 4, vie = 3 }, { royal_fur = 1, soft_leather = 4, gold_ingot = 1 }, 30 },
	{ "armor", "Armure d'écailles noires", 4, { defense = 10, vie = 4 }, { black_scale = 2, steel = 4 }, 32 },
	{ "trinket", "Carapace du Scarabée", 4, { defense = 6, chance = 4 }, { golden_carapace = 1, gold_ingot = 2 }, 32 },
	{ "weapon", "Lame de givre", 4, { force = 7, vitesse = 2 }, { frost_crystal = 1, steel = 3, silver_ingot = 1 }, 34, power = 9, visual = "8" },
	{ "hat", "Couronne du Roi sans couronne", 4, { charisme = 8, chance = 4, vie = 2 }, { lost_crown = 1, ancient_jewel = 1 }, 36, visual = "mage" },
	{ "trinket", "Éclat de météorite", 4, { force = 4, defense = 4, chance = 3 }, { meteorite = 2, gold_ingot = 1 }, 30 },
	-- outils de métier portés (petits bonus du métier)
	{ "trinket", "Marteau de forgeron", 1, { force = 2 }, { iron_ingot = 2, planks = 1 }, 6 },
	{ "trinket", "Faucille", 1, { chance = 2 }, { iron_ingot = 1, planks = 1 }, 3 },
	{ "trinket", "Couteau de chasse", 1, { force = 1, discretion = 1 }, { blade = 1, leather = 1 }, 8 },
	{ "trinket", "Filet de pêche", 1, { chance = 2 }, { rope = 6 }, 2 },
	{ "trinket", "Panier de récolte", 1, { vie = 1, chance = 1 }, { wicker_basket = 1 }, 0 },
	{ "offhand", "Torche", 1, { discretion = -1, vie = 1, chance = 1 }, { branches = 2, resin = 1 }, 0 },
	-- harnais (le cheval suit : portés comme breloque, vitesse)
	{ "trinket", "Selle de voyage", 2, { vitesse = 3, vie = 1 }, { soft_leather = 4, buckle = 2 }, 8 },
	{ "trinket", "Selle de guerre", 3, { vitesse = 2, defense = 3 }, { soft_leather = 4, steel = 1, buckle = 2 }, 18 },
	{ "trinket", "Fers à cheval", 1, { vitesse = 2 }, { iron_ingot = 2, nails = 8 }, 4 },
	{ "trinket", "Sacoche de selle", 1, { chance = 2 }, { leather = 3, buckle = 1 }, 4 },
}

-- Trouvailles : en récoltant, pêchant ou chassant, on tombe parfois sur autre chose.
-- { objet, chance, biomes (nil = partout) }
K.FINDS = {
	tree = { { "oak_log", 0.18, { "prairie", "foret" } }, { "pine_log", 0.18, { "neige", "foret" } }, { "branches", 0.3 }, { "bark", 0.15 },
		{ "resin", 0.08 }, { "apple", 0.08, { "prairie" } }, { "pear", 0.05, { "prairie", "foret" } }, { "plum", 0.05, { "foret" } },
		{ "pollen", 0.04 }, { "petrified_wood", 0.004 }, { "amber", 0.006 } },
	bush = { { "chamomile", 0.12, { "prairie" } }, { "mint", 0.12, { "prairie", "marais" } }, { "sage", 0.1, { "desert" } },
		{ "thyme", 0.1, { "desert", "prairie" } }, { "lavender", 0.08, { "prairie" } }, { "rosemary", 0.08, { "desert" } },
		{ "nettle", 0.15 }, { "st_john", 0.06 }, { "valerian", 0.05, { "foret", "marais" } }, { "reeds", 0.2, { "marais" } },
		{ "mandrake", 0.008, { "marais", "foret" } }, { "rare_mushroom", 0.02, { "foret", "marais" } }, { "pollen", 0.1 },
		{ "colored_stone", 0.02 }, { "lost_item", 0.01 } },
	rock = { { "flint", 0.2 }, { "gravel", 0.2 }, { "salt", 0.1, { "desert" } }, { "sulfur", 0.06, { "desert", "marais" } },
		{ "silver_ore", 0.08, { "neige", "desert" } }, { "fossil", 0.006 }, { "fossil_bone", 0.005 }, { "ruby", 0.003 },
		{ "sapphire", 0.003, { "neige" } }, { "emerald", 0.003, { "foret" } }, { "diamond", 0.0015 }, { "glowstone", 0.01 },
		{ "ancient_crystal", 0.004 }, { "carved_stone", 0.004 }, { "ancient_coin", 0.006 }, { "old_page", 0.004 } },
	dig = { { "old_page", 0.02 }, { "flint", 0.08 }, { "ancient_coin", 0.01 }, { "rusty_key", 0.01 }, { "relic_fragment", 0.006 }, { "inscription", 0.004 },
		{ "fossil", 0.004 }, { "copper_coin", 0.05 }, { "silver_coin", 0.012 }, { "gold_coin", 0.003 } },
	fish = { { "raw_fish", 0.3 }, { "salmon", 0.06, { "neige", "foret" } }, { "crab", 0.06, { "desert", "marais" } },
		{ "crayfish", 0.06, { "marais", "prairie" } }, { "shellfish", 0.1 }, { "pearl", 0.01 }, { "rare_shell", 0.008 },
		{ "message_bottle", 0.01 }, { "map_fragment", 0.01 }, { "old_compass", 0.002 } },
	hunt = { { "raw_hide", 0.35 }, { "tooth", 0.25 }, { "claw", 0.12 }, { "horn", 0.08 }, { "monster_tooth", 0.05 },
		{ "venison", 0.15, { "foret", "prairie" } }, { "boar_meat", 0.12, { "foret", "prairie" } }, { "rabbit_meat", 0.12 },
		{ "deer_hide", 0.06 }, { "wolf_pelt", 0.06, { "neige", "foret" } }, { "scales", 0.08, { "marais", "desert" } },
		{ "night_feather", 0.02 }, { "coin_purse", 0.04 }, { "treasure_map", 0.006 }, { "mystery_egg", 0.003 },
		{ "ancient_scale", 0.002 }, { "rare_horn", 0.002 } },
	night = { { "night_flower", 0.08 }, { "moon_flower", 0.03 }, { "glow_mushroom", 0.05 } },
	event = { { "old_page", 0.08 }, { "event_token", 0.5 }, { "merchant_purse", 0.2 }, { "spice", 0.3 }, { "treasure_map", 0.05 }, { "recommendation", 0.05 },
		{ "lost_item", 0.2 }, { "craftsman_plan", 0.08 }, { "unknown_recipe", 0.08 }, { "royal_seal", 0.01 }, { "meteorite", 0.02 },
		{ "rare_book", 0.03 }, { "relic", 0.02 }, { "champion_ribbon", 0.03 }, { "festival_prize", 0.1 }, { "sheriff_badge", 0.01 },
		{ "talisman", 0.02 }, { "ancient_jewel", 0.02 }, { "old_vase", 0.03 }, { "ruin_piece", 0.03 }, { "mineral_heart", 0.005 },
		{ "bill_exchange", 0.04 }, { "traveler_journal", 0.05 }, { "silver_coin", 0.1 } },
}

-- Ce qu'un coffre au trésor (carte, bouteille, œuf…) peut rapporter
K.TREASURE = { { "gold", 80, 260 }, { "ancient_coin", 1, 4 }, { "silver_coin", 2, 6 }, { "gold_coin", 1, 3 }, { "ancient_jewel", 1, 1 }, { "relic", 1, 1 }, { "ruby", 1, 1 },
	{ "sapphire", 1, 1 }, { "emerald", 1, 1 }, { "pearl", 1, 3 }, { "old_vase", 1, 1 }, { "ancient_key", 1, 1 }, { "rare_book", 1, 1 }, { "old_page", 1, 2 } }

-- ---------------------------------------------------------------- Lecture du catalogue

local function parseNeeds(s: string)
	if s == "-" or s == "" then
		return nil
	end
	local r = { needs = {}, count = 1 }
	for tok in string.gmatch(s, "%S+") do
		local c = string.sub(tok, 1, 1)
		if c == ">" then
			r.count = tonumber(string.sub(tok, 2)) or 1
		elseif c == "@" then
			r.station = string.sub(tok, 2)
		elseif c == "#" then
			local sk, lv = string.match(tok, "#(%a+):(%d+)")
			r.skill = { sk, tonumber(lv) }
		else
			local id, n = string.match(tok, "^(.-)(%d+)$")
			if id then
				r.needs[id] = tonumber(n)
			end
		end
	end
	return r
end

K.ENTRIES = {}
K.MODELS = {} -- nom du modèle -> { arch, couleur }
for line in string.gmatch(LINES, "[^\n]+") do
	if string.sub(line, 1, 1) ~= "#" then
		local f = string.split(line, "|")
		if #f >= 6 then
			table.insert(K.ENTRIES, { id = f[1], name = f[2], icon = f[3], price = tonumber(f[4]) or 0, kind = f[5], recipe = parseNeeds(f[6]), tab = f[7] ~= "" and f[7] or nil })
		end
	end
end

local DEFAULT_TAB = { m = "materiaux", f = "cuisine", p = "mobilier", v = "commerce", u = "savoir" }

function K.apply(C)
	for _, t in K.TABS do
		table.insert(C.CRAFT_TABS, t)
	end
	for _, e in K.ENTRIES do
		if not C.ITEMS[e.id] then
			local info = { name = e.name, icon = e.icon, price = e.price > 0 and e.price or nil }
			local k = string.sub(e.kind, 1, 1)
			if k == "f" then
				info.food = tonumber(string.sub(e.kind, 2)) or 10
			elseif k == "p" then
				local _, arch, col = table.unpack(string.split(e.kind, ":"))
				local model = string.sub(arch, 1, 1) == "@" and string.sub(arch, 2) or ("Cat_" .. e.id)
				info.place = model
				info.grid = "cell"
				if string.sub(arch, 1, 1) ~= "@" then
					K.MODELS[model] = { arch = arch, color = col or "B" }
				end
			elseif k == "u" then
				local _, use, arg = table.unpack(string.split(e.kind, ":"))
				if use == "engrais" then
					info.use = "fertilize"
				else
					info.use = "cat_" .. use
					info.useArg = arg
				end
			elseif k == "v" then
				info.valuable = true
			end
			C.ITEMS[e.id] = info
		end
		if e.recipe then
			table.insert(C.RECIPES, { item = e.id, needs = e.recipe.needs, count = e.recipe.count > 1 and e.recipe.count or nil,
				station = e.recipe.station, skill = e.recipe.skill, cat = e.tab or DEFAULT_TAB[string.sub(e.kind, 1, 1)] or "materiaux" })
		end
	end
	for _, id in K.CROP_ORDER do
		table.insert(C.SHOP, "seed_" .. id)
	end
	for _, g in K.GEAR do
		local slot, name, rarity, stats, needs, skill = g[1], g[2], g[3], g[4], g[5], g[6]
		local clean = {}
		for id, n in needs do
			if n > 0 then
				clean[id] = n
			end
		end
		table.insert(C.RECIPES, { gear = { slot = slot, name = name, rarity = rarity, stats = stats, power = g.power, visual = g.visual },
			needs = clean, station = "bench", cat = "equipement", skill = skill > 0 and { "artisanat", skill } or nil })
	end
end

-- Cultures : à appeler avant que Config génère objets et graines des cultures
function K.applyCrops(C)
	for _, id in K.CROP_ORDER do
		C.CROPS[id] = K.CROPS[id]
		table.insert(C.CROP_ORDER, id)
	end
end

-- Rareté de chaque objet (1 commun … 5 légendaire), calculée une fois pour toutes les machines :
--  · prix : ≥ 600 légendaire, ≥ 220 épique, ≥ 80 rare ; outils, armes, objets de valeur ≥ 20 : peu commun ;
--  · un objet qu'on ne fabrique ni n'achète prend AU MOINS la rareté de sa meilleure chance de
--    trouvaille (≥ 5 % commun, ≥ 2 % peu commun, ≥ 0,6 % rare, ≥ 0,2 % épique, au-dessous légendaire).
-- La rareté vient donc de l'obtention réelle : un objet courant reste courant (et utile en recettes).
-- L'équipement fabriqué ou tiré garde sa propre rareté (Gear.RARITIES).
function K.assignRarity(C)
	local made, sold, best = {}, {}, {}
	for _, r in C.RECIPES do
		if r.item then
			made[r.item] = true
		end
	end
	for _, id in C.SHOP do
		sold[id] = true
	end
	for _, list in K.FINDS do
		for _, f in list do
			best[f[1]] = math.max(best[f[1]] or 0, f[2])
		end
	end
	for id, info in C.ITEMS do
		local p = info.price or 0
		local r = 1
		if p >= 600 then
			r = 5
		elseif p >= 220 then
			r = 4
		elseif p >= 80 then
			r = 3
		elseif info.tool or info.weapon or (info.valuable and p >= 20) then
			r = 2
		end
		local b = best[id]
		if b and not made[id] and not sold[id] then
			local f = b >= 0.05 and 1 or b >= 0.02 and 2 or b >= 0.006 and 3 or b >= 0.002 and 4 or 5
			r = math.max(r, f)
		end
		info.rarity = r
	end
end

-- Tire les trouvailles d'une source (serveur) : renvoie { {objet, n} }
function K.rollFinds(source: string, biome: string?, luck: number?)
	local out = {}
	local list = K.FINDS[source]
	if not list then
		return out
	end
	local mult = 1 + (luck or 0) * 0.05
	for _, f in list do
		if (not f[3] or (biome and table.find(f[3], biome))) and math.random() < f[2] * mult then
			table.insert(out, { f[1], 1 })
		end
	end
	return out
end

-- ---------------------------------------------------------------- Modèles générés par code

-- Les façades regardent vers +Z. Les garnitures sont traversables, la structure reste solide.
local COLORS = {
	B = Color3.fromRGB(151, 102, 62), BF = Color3.fromRGB(111, 72, 47), BC = Color3.fromRGB(184, 137, 83),
	P = Color3.fromRGB(156, 154, 147), PC = Color3.fromRGB(191, 186, 174), F = Color3.fromRGB(62, 59, 57),
	O = Color3.fromRGB(208, 160, 63), R = Color3.fromRGB(154, 52, 45), BL = Color3.fromRGB(46, 78, 147),
	V = Color3.fromRGB(81, 110, 64), W = Color3.fromRGB(226, 213, 178), T = Color3.fromRGB(171, 95, 59),
	N = Color3.fromRGB(36, 33, 30), Y = Color3.fromRGB(196, 154, 68), VI = Color3.fromRGB(106, 64, 119),
}
local WOOD, DARK, IRON, STONE, CLOTH = COLORS.B, Color3.fromRGB(78, 49, 33), COLORS.F, COLORS.P, COLORS.W
local Mat = Enum.Material
local V = Vector3.new
local UP = CFrame.Angles(0, 0, math.pi / 2)
local FACE = CFrame.Angles(0, math.pi / 2, 0)
local TAU = math.pi * 2
local EAU = Color3.fromRGB(67, 113, 130)
local VITRE = Color3.fromRGB(159, 191, 202)

local function piece(m, nom, taille, position, couleur, mat, forme, rotation, fin)
	local p = Instance.new(forme == "coin" and "WedgePart" or "Part")
	if forme == "boule" then
		p.Shape = Enum.PartType.Ball
	elseif forme == "cylindre" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Name, p.Size = nom, taille
	p.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
	p.Color, p.Material = couleur, mat
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if fin then p.CanCollide, p.CanTouch = false, false end
	p.Parent = m
	return p
end

local function bois(m, nom, taille, pos, c, fin, rot)
	return piece(m, nom, taille, pos, c, Mat.Wood, nil, rot, fin)
end

local function pierre(m, nom, taille, pos, c, mat, rot)
	return piece(m, nom, taille, pos, c, mat or Mat.Slate, nil, rot)
end

local function fer(m, nom, taille, pos, c, rot)
	return piece(m, nom, taille, pos, c or IRON, Mat.Metal, nil, rot, true)
end

local function cyl(m, nom, diam, ep, pos, c, mat, rot, fin)
	return piece(m, nom, V(ep, diam, diam), pos, c, mat, "cylindre", rot or UP, fin)
end

local function boule(m, nom, taille, pos, c, mat)
	return piece(m, nom, taille, pos, c, mat, "boule", nil, true)
end

local function toile(m, nom, taille, pos, c, rot)
	return piece(m, nom, taille, pos, c, Mat.Fabric, nil, rot, true)
end

local function verre(m, nom, taille, pos, c, forme, rot)
	local p = piece(m, nom, taille, pos, c, Mat.Glass, forme, rot, true)
	p.Transparency = 0.28
	return p
end

local function teinte(c, i)
	local t = i % 3
	return t == 0 and c:Lerp(DARK, 0.16) or t == 1 and c or c:Lerp(COLORS.BC, 0.22)
end

-- Poutres définies par leurs extrémités pour ancrer chaque assemblage.
local function lien(m, nom, a, b, largeur, ep, c, mat, fin)
	local delta = b - a
	local up = math.abs(delta.Unit.Y) > 0.98 and V(0, 0, 1) or V(0, 1, 0)
	local cf = CFrame.lookAt((a + b) / 2, b, up)
	return piece(m, nom, V(largeur, ep, (b - a).Magnitude + 0.04), cf.Position, c, mat, nil, cf.Rotation, fin)
end

local function lames(m, nom, taille, pos, n, axe, c)
	local largeur = (axe == "X" and taille.X or axe == "Y" and taille.Y or taille.Z) / n
	for i = 1, n do
		local d = (i - (n + 1) / 2) * largeur
		local ep = largeur - 0.022
		local dims = axe == "X" and V(ep, taille.Y, taille.Z)
			or axe == "Y" and V(taille.X, ep, taille.Z) or V(taille.X, taille.Y, ep)
		local decalage = axe == "X" and V(d, 0, 0) or axe == "Y" and V(0, d, 0) or V(0, 0, d)
		piece(m, nom, dims, pos + decalage, teinte(c, i), Mat.WoodPlanks)
	end
end

local function rivet(m, pos, d, c)
	boule(m, "Rivet", V(d, d, d), pos, c or IRON, Mat.Metal)
end

local function anneau(m, nom, pos, rayon, n, ep, c, mat, plan)
	for i = 0, n - 1 do
		local a, b = i * TAU / n, (i + 1) * TAU / n
		local function point(angle)
			local u, v = math.cos(angle) * rayon, math.sin(angle) * rayon
			return pos + (plan == "XZ" and V(u, 0, v) or plan == "YZ" and V(0, u, v) or V(u, v, 0))
		end
		lien(m, nom, point(a), point(b), ep, ep, c, mat, true)
	end
end

local function flamme(m, pos, hauteur, portee, puissance, feu)
	local p = boule(m, "Flamme", V(hauteur * 0.58, hauteur, hauteur * 0.58), pos,
		Color3.fromRGB(255, 178, 76), Mat.Neon)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 190, 110), portee, puissance
	l.Parent = p
	if feu then
		local f = Instance.new("Fire")
		f.Size, f.Heat = feu, 4
		f.Parent = p
	end
	return p
end

local function pieds(m, w, d, h, ep)
	for _, x in { -w / 2 + ep / 2, w / 2 - ep / 2 } do
		for _, z in { -d / 2 + ep / 2, d / 2 - ep / 2 } do
			bois(m, "Pied", V(ep, h, ep), V(x, h / 2, z), DARK)
		end
	end
end

local function assises(m, y, h, largeur, profondeur, z, c, divisions)
	local x = -largeur / 2
	for i, fraction in divisions do
		local w = largeur * fraction
		pierre(m, "Moellon", V(w - 0.024, h - 0.022, profondeur * (i % 2 == 0 and 0.96 or 1)),
			V(x + w / 2, y + 0.008 * (i % 2), z), c:Lerp(COLORS.PC, (i % 3) * 0.13),
			i % 2 == 0 and Mat.Slate or Mat.Cobblestone)
		x += w
	end
end

local ARCH = {}

ARCH.caisse = function(m, c)
	lames(m, "Fond", V(2.38, 0.19, 2.38), V(0, 0.095, 0), 4, "X", c)
	for _, s in { -1, 1 } do
		for i = 0, 3 do
			local y = 0.42 + i * 0.51
			local couleur = teinte(c:Lerp(COLORS.BC, 0.28), i)
			piece(m, "Bordage", V(2.23, 0.456, 0.17), V(0, y, s * 1.026), couleur, Mat.WoodPlanks)
			piece(m, "Bordage", V(0.17, 0.456, 2.23), V(s * 1.026, y, 0), couleur, Mat.WoodPlanks)
		end
		for _, y in { 0.25, 2.14 } do
			bois(m, "Traverse", V(2.24, 0.19, 0.19), V(0, y, s * 1.132), DARK)
			bois(m, "Traverse", V(0.19, 0.19, 2.24), V(s * 1.132, y, 0), DARK)
		end
		for _, x in { -1.118, 1.118 } do
			bois(m, "Cornière", V(0.236, 2.28, 0.236), V(x, 1.14, s * 1.118), DARK)
			for _, y in { 0.29, 2.10 } do
				rivet(m, V(x, y, s * 1.234), 0.088, COLORS.F)
				rivet(m, V(math.sign(x) * 1.234, y, s * 1.118), 0.088, COLORS.F)
			end
		end
	end

	-- Le second bras du croisillon s'assemble de part et d'autre du premier.
	lien(m, "Écharpe", V(-1.05, 0.27, 1.166), V(1.05, 2.13, 1.166), 0.145, 0.20, DARK, Mat.Wood, true)
	lien(m, "Demi-écharpe", V(-1.05, 2.13, 1.166), V(-0.07, 1.262, 1.166), 0.145, 0.20, DARK, Mat.Wood, true)
	lien(m, "Demi-écharpe", V(0.07, 1.138, 1.166), V(1.05, 0.27, 1.166), 0.145, 0.20, DARK, Mat.Wood, true)

	local couvercle = CFrame.new(0, 2.435, -0.012) * CFrame.Angles(-0.15, 0, 0)
	for i = -2, 2 do
		piece(m, "Lame du couvercle", V(0.47, 0.14, 2.46), couvercle:PointToWorldSpace(V(i * 0.5, 0, 0)),
			teinte(c, i), Mat.WoodPlanks, nil, couvercle.Rotation)
	end
	for _, z in { -0.86, 0.68 } do
		bois(m, "Taquet du couvercle", V(2.26, 0.11, 0.22), couvercle:PointToWorldSpace(V(0, -0.096, z)),
			DARK, true, couvercle.Rotation)
	end
end

local function fut(m, c, cadre, diam, haut)
	local function cent(y, x, z)
		return cadre:PointToWorldSpace(V(x or 0, y, z or 0))
	end
	local orientation = cadre.Rotation * UP
	local profil = { { 0.015, 0.391 }, { 0.265, 0.445 }, { 0.735, 0.445 }, { 0.985, 0.391 } }
	local ep, n = diam * 0.09, 12
	cyl(m, "Âme du fût", diam * 0.82, haut, cent(haut / 2), DARK, Mat.Wood, orientation)
	for i = 0, n - 1 do
		local angle = i * TAU / n
		local radial = CFrame.Angles(0, angle, 0)
		local couleur = teinte(c, i)
		for j = 1, #profil - 1 do
			local a, b = profil[j], profil[j + 1]
			local rayon = (a[2] + b[2]) * diam / 2
			local dy, dr = (b[1] - a[1]) * haut, (b[2] - a[2]) * diam
			local milieu = radial:VectorToWorldSpace(V(0, (a[1] + b[1]) * haut / 2, rayon))
			piece(m, "Douelle", V(2 * rayon * math.tan(math.pi / n) - 0.019, math.sqrt(dy * dy + dr * dr) + 0.018, ep),
				cadre:PointToWorldSpace(milieu), couleur, Mat.WoodPlanks, nil,
				cadre.Rotation * radial * CFrame.Angles(math.atan2(dr, dy), 0, 0), true)
		end
	end
	for _, y in { 0.26, 0.74 } do
		cyl(m, "Cercle de fer", diam * 0.984, haut * 0.084, cent(haut * y), IRON, Mat.Metal, orientation, true)
		for _, a in { TAU / 12, TAU * 7 / 12 } do
			rivet(m, cent(haut * y, math.sin(a) * diam * 0.492, math.cos(a) * diam * 0.492), diam * 0.046, COLORS.P)
		end
	end
	cyl(m, "Fond du fût", diam * 0.78, haut * 0.027, cent(haut + 0.005), DARK, Mat.Wood, orientation, true)
	for i = -1, 1 do
		bois(m, "Lame du fond", V(diam * (0.73 - 0.14 * math.abs(i)), 0.053, diam * 0.220),
			cent(haut + 0.022, 0, diam * i * 0.226), teinte(c, i), true, cadre.Rotation)
	end
	cyl(m, "Bonde", diam * 0.14, haut * 0.047, cent(haut + 0.058, diam * 0.12), COLORS.BC,
		Mat.Wood, orientation, true)
end

ARCH.tonneau = function(m, c)
	fut(m, c, CFrame.identity, 2.43, 2.88)
end

ARCH.baril = function(m, c)
	fut(m, c, CFrame.new(-1, 1.02, 0) * CFrame.Angles(0, 0, -math.pi / 2), 1.57, 1.91)
	for _, x in { -0.63, 0.61 } do
		bois(m, "Semelle", V(0.28, 0.24, 1.48), V(x, 0.12, 0), DARK)
		for _, z in { -0.48, 0.48 } do
			piece(m, "Berceau", V(0.28, 0.51, 0.51), V(x, 0.435, z), c:Lerp(COLORS.BC, 0.35), Mat.Wood, "coin",
				z < 0 and CFrame.Angles(0, math.pi, 0) or nil)
		end
	end
	cyl(m, "Rosace du robinet", 0.31, 0.06, V(0.958, 0.77, 0), IRON, Mat.Metal, CFrame.identity, true)
	cyl(m, "Robinet", 0.17, 0.21, V(1.035, 0.77, 0), COLORS.O, Mat.Metal, CFrame.identity, true)
	cyl(m, "Bec du robinet", 0.141, 0.16, V(1.08, 0.693, 0), COLORS.O, Mat.Metal, nil, true)
	fer(m, "Poignée du robinet", V(0.1, 0.12, 0.34), V(1.035, 0.858, 0), COLORS.O)
end

local function tableMenuisee(m, c, w, d, nb)
	lames(m, "Plateau", V(w, 0.28, d), V(0, 2.61, 0), nb, "Z", c)
	pieds(m, w - 0.18, d - 0.16, 2.49, 0.32)
	for _, z in { -d / 2 + 0.25, d / 2 - 0.25 } do
		bois(m, "Ceinture", V(w - 0.2, 0.29, 0.18), V(0, 2.37, z), DARK)
		for _, x in { -w / 2 + 0.26, w / 2 - 0.26 } do
			rivet(m, V(x, 2.37, z + math.sign(z) * 0.105), 0.075)
		end
	end
	for _, x in { -w / 2 + 0.25, w / 2 - 0.25 } do
		bois(m, "Entretoise", V(0.23, 0.25, d - 0.2), V(x, 0.78, 0), DARK)
	end
	bois(m, "Traverse", V(w - 0.25, 0.21, 0.24), V(0, 0.78, 0), c)
end

ARCH.table = function(m, c) tableMenuisee(m, c, 3.4, 2.2, 4) end
ARCH.grandetable = function(m, c) tableMenuisee(m, c, 7, 2.6, 5) end

ARCH.tabouret = function(m, c)
	cyl(m, "Assise", 1.75, 0.23, V(0, 1.555, 0), c:Lerp(COLORS.BC, 0.37), Mat.WoodPlanks)
	cyl(m, "Chant", 1.78, 0.13, V(0, 1.467, 0), DARK, Mat.Wood)
	local entretoises = {}
	for i = 0, 2 do
		local a = i * TAU / 3 + 0.29
		local x, z = math.cos(a), math.sin(a)
		local y = 0.50 + i * 0.056
		local rayon = 0.67 + (0.49 - 0.67) * ((y - 0.15) / (1.46 - 0.15))
		table.insert(entretoises, V(x * rayon, y, z * rayon))
		lien(m, "Pied évasé", V(x * 0.67, 0.15, z * 0.67), V(x * 0.49, 1.46, z * 0.49),
			0.25, 0.25, c, Mat.Wood)
		cyl(m, "Bout de pied", 0.25, 0.18, V(x * 0.67, 0.09, z * 0.67), c, Mat.Wood)
		cyl(m, "Cheville", 0.141, 0.022, V(x * 0.49, 1.672, z * 0.49), DARK, Mat.Wood, nil, true)
	end
	for i, p in entretoises do
		lien(m, "Entretoise", p, entretoises[i % 3 + 1], 0.15, 0.13, DARK, Mat.Wood, true)
	end
end

ARCH.chaise = function(m, c)
	pieds(m, 1.4, 1.4, 1.45, 0.24)
	lames(m, "Assise", V(1.4, 0.2, 1.4), V(0, 1.52, 0), 4, "X", c)
	for _, x in { -0.57, 0.57 } do
		bois(m, "Montant", V(0.22, 1.65, 0.23), V(x, 2.34, -0.56), DARK)
	end
	for _, y in { 1.03, 2.02, 2.55, 3.02 } do
		bois(m, "Traverse", V(1.35, 0.18, 0.19), V(0, y, -0.57), c)
	end
end

local function lit(m, c, w, haut, oreillers)
	pieds(m, w, 5, 0.8, 0.28)
	lames(m, "Sommier", V(w, 0.26, 4.95), V(0, 0.7, 0), 7, "Z", DARK)
	for _, z in { -2.36, 2.36 } do
		local h = z < 0 and haut or 1.04
		lames(m, "Dossier", V(w - 0.2, h - 0.26, 0.23), V(0, h / 2 + 0.13, z), 5, "X", WOOD)
		bois(m, "Linteau", V(w, 0.18, 0.3), V(0, h - 0.08, z), DARK)
		for _, x in { -w / 2 + 0.15, w / 2 - 0.15 } do
			bois(m, "Potelet", V(0.27, h, 0.29), V(x, h / 2, z), DARK)
			boule(m, "Pommeau", V(0.27, 0.25, 0.27), V(x, h, z), COLORS.BC, Mat.Wood)
		end
	end
	toile(m, "Matelas", V(w - 0.22, 0.3, 4.44), V(0, 0.94, 0), CLOTH)
	toile(m, "Couverture", V(w - 0.16, 0.25, 3.35), V(0, 1.13, 0.55), c)
	toile(m, "Revers", V(w - 0.16, 0.09, 0.23), V(0, 1.25, -1.08), COLORS.O)
	for i = 1, oreillers do
		boule(m, "Oreiller", V(w / oreillers - 0.38, 0.33, 1.03),
			V((i - (oreillers + 1) / 2) * w / oreillers, 1.13, -1.71), CLOTH, Mat.Fabric)
	end
end

ARCH.lit = function(m, c) lit(m, c, 2.6, 1.88, 1) end
ARCH.litdouble = function(m, c) lit(m, c, 4.6, 2.37, 2) end

ARCH.paillasse = function(m, c)
	toile(m, "Couture du matelas", V(2.28, 0.18, 4.50), V(0, 0.09, 0), c:Lerp(DARK, 0.35))
	toile(m, "Toile de la paillasse", V(2.26, 0.28, 4.36), V(0, 0.24, 0), c:Lerp(CLOTH, 0.44))
	for _, x in { -1.10, 1.10 } do
		boule(m, "Bourrelet de paille", V(0.32, 0.34, 4.36), V(x, 0.21, 0), c, Mat.Grass)
	end
	for i = -2, 2 do
		lien(m, "Brins de paille", V(i * 0.36, 0.15, -2.15), V(i * 0.40 + 0.06, 0.12 + i % 2 * 0.07, -2.26),
			0.095, 0.086, teinte(c, i), Mat.Grass, true)
	end
	toile(m, "Couverture de laine", V(2.24, 0.13, 2.52), V(0.01, 0.414, 0.88), COLORS.R:Lerp(DARK, 0.14))
	toile(m, "Rabattement", V(2.25, 0.27, 0.16), V(0.01, 0.33, 2.11), COLORS.R:Lerp(DARK, 0.14))
	toile(m, "Revers", V(2.26, 0.13, 0.34), V(0.01, 0.46, -0.27), COLORS.R)
	toile(m, "Galon", V(2.24, 0.022, 0.12), V(0.01, 0.527, -0.23), COLORS.O)
	cyl(m, "Traversin de lin", 0.57, 1.62, V(-0.04, 0.527, -1.57), CLOTH, Mat.Fabric, CFrame.identity, true)
	for _, x in { -0.80, 0.72 } do
		cyl(m, "Couture du traversin", 0.575, 0.052, V(x, 0.527, -1.57), CLOTH:Lerp(DARK, 0.23),
			Mat.Fabric, CFrame.identity, true)
	end
end

ARCH.armoire = function(m, c)
	pieds(m, 3.15, 1.52, 0.54, 0.32)
	for _, x in { -1.48, 1.48 } do
		lames(m, "Joue", V(0.19, 4.72, 1.52), V(x, 2.8, -0.01), 4, "Z", c)
	end
	lames(m, "Dos", V(2.92, 4.72, 0.17), V(0, 2.8, -0.67), 6, "X", c)
	for _, y in { 0.52, 5.16, 5.41, 5.56 } do
		bois(m, "Corniche", V(3.22 + (y == 5.56 and 0.18 or 0), 0.21, 1.76), V(0, y, 0), DARK)
	end
	for _, s in { -1, 1 } do
		lames(m, "Battant", V(1.43, 4.48, 0.18), V(s * 0.74, 2.84, 0.67), 3, "X", c:Lerp(WOOD, 0.35))
		for _, x in { 0.13, 1.35 } do bois(m, "Montant", V(0.16, 4.55, 0.1), V(s * x, 2.83, 0.77), DARK, true) end
		for _, y in { 0.72, 2.8, 4.96 } do bois(m, "Traverse", V(1.32, 0.19, 0.1), V(s * 0.74, y, 0.77), DARK, true) end
		for _, y in { 1.22, 4.48 } do
			fer(m, "Pentures", V(0.54, 0.17, 0.07), V(s * 1.2, y, 0.85))
			rivet(m, V(s * 1.08, y, 0.89), 0.11, COLORS.O)
		end
		boule(m, "Bouton", V(0.21, 0.21, 0.19), V(s * 0.31, 2.85, 0.82), COLORS.O, Mat.Metal)
	end
end

local function rayonnage(m, c, livres)
	for _, x in { -1.62, 1.62 } do
		bois(m, "Montant", V(0.27, 4.36, 1), V(x, 2.18, 0), DARK)
		bois(m, "Sabot", V(0.35, 0.23, 1.04), V(x, 0.12, 0), WOOD)
	end
	for i = 0, 3 do
		bois(m, "Rayon", V(3.45, 0.19, 1), V(0, 0.4 + i * 1.28, 0), teinte(c, i))
		bois(m, "Chant", V(3.49, 0.12, 0.1), V(0, 0.41 + i * 1.28, 0.48), COLORS.BC, true)
	end
	bois(m, "Corniche", V(3.56, 0.19, 1.06), V(0, 4.34, 0), DARK)
	bois(m, "Dos", V(3.18, 3.84, 0.15), V(0, 2.31, -0.46), c)
	if livres then
		local reliures = { COLORS.R, COLORS.BL, COLORS.V, COLORS.T, COLORS.VI }
		for i = 0, 2 do
			for j = 0, 4 do
				local h = 0.52 + ((i * 5 + j * 7) % 9) * 0.053
				local x, y = -1.34 + j * 0.52 + i * 0.09, 0.49 + i * 1.28 + h / 2
				toile(m, "Reliure", V(0.31 + j % 3 * 0.06, h, 0.63), V(x, y, 0.01), reliures[(i + j) % #reliures + 1])
				toile(m, "Dorure", V(0.23, 0.05, 0.029), V(x, y - h * 0.26, 0.329), COLORS.O)
			end
		end
	else
		for _, x in { -1.2, -0.3, 0.65, 1.19 } do
			fer(m, "Crochet", V(0.1, 0.32, 0.15), V(x, 3.66, 0.06))
			fer(m, "Retour", V(0.1, 0.10, 0.28), V(x, 3.52, 0.14))
		end
		bois(m, "Tringle", V(3.2, 0.23, 0.22), V(0, 3.78, 0), DARK)
	end
end

ARCH.etagere = function(m, c) rayonnage(m, c, false) end
ARCH.biblio = function(m, c) rayonnage(m, c, true) end

ARCH.coffret = function(m, c)
	lames(m, "Corps", V(1.35, 0.46, 0.85), V(0, 0.23, 0), 3, "Y", c)
	lames(m, "Couvercle", V(1.42, 0.16, 0.92), V(0, 0.53, 0), 3, "X", COLORS.BC)
	for _, x in { -0.55, 0.55 } do
		fer(m, "Gond", V(0.18, 0.28, 0.09), V(x, 0.48, -0.42))
		rivet(m, V(x, 0.59, 0.34), 0.075, COLORS.O)
	end
	fer(m, "Serrure", V(0.27, 0.23, 0.065), V(0, 0.41, 0.45), COLORS.O)
	fer(m, "Entrée", V(0.055, 0.1, 0.025), V(0, 0.41, 0.49))
end

ARCH.comptoir = function(m, c)
	pieds(m, 6, 1.61, 2.84, 0.28)
	lames(m, "Façade", V(5.86, 2.48, 0.22), V(0, 1.42, 0.66), 11, "X", c)
	for _, x in { -2.93, 2.93 } do
		lames(m, "Panneau latéral", V(0.23, 2.5, 1.4), V(x, 1.43, 0), 4, "Z", c)
	end
	lames(m, "Plateau", V(6.3, 0.31, 1.9), V(0, 2.94, 0), 5, "Z", DARK)
	for _, y in { 0.28, 2.61 } do bois(m, "Cadre", V(6.08, 0.23, 0.19), V(0, y, 0.75), DARK) end
	for _, x in { -2.79, -0.96, 1.01, 2.79 } do
		bois(m, "Montant", V(0.18, 2.4, 0.17), V(x, 1.46, 0.77), DARK)
		for _, y in { 0.41, 2.51 } do rivet(m, V(x, y, 0.85), 0.11) end
	end
end

ARCH.bureau = function(m, c)
	tableMenuisee(m, c, 3.4, 2.2, 4)
	bois(m, "Tiroir", V(1.35, 0.28, 0.65), V(0.75, 2.4, 0.66), c)
	anneau(m, "Tirant", V(0.75, 2.36, 1.0), 0.11, 6, 0.035, COLORS.O, Mat.Metal, "XY")
	cyl(m, "Encrier", 0.33, 0.24, V(1.07, 2.86, -0.23), COLORS.N, Mat.Glass, nil, true)
	cyl(m, "Bague de l’encrier", 0.26, 0.08, V(1.07, 3.01, -0.23), COLORS.O, Mat.Metal, nil, true)
	toile(m, "Vélin", V(1.13, 0.045, 0.82), V(-0.36, 2.77, 0.12), CLOTH, CFrame.Angles(0, 0.13, 0))
	bois(m, "Plume", V(0.064, 0.045, 0.64), V(-0.51, 2.81, 0.05), DARK, true, CFrame.Angles(0, -0.85, 0))
end

ARCH.coffre = function(m, c)
	local renforce = m.Name == "Cat_reinforced_chest"
	local planche = renforce and COLORS.BF or c
	lames(m, "Caisse", V(3, 1.5, 2), V(0, 0.75, 0), 5, "X", planche)
	lames(m, "Couvercle", V(3.1, 0.27, 2.08), V(0, 1.6, 0), 5, "X", planche)
	lames(m, "Bombé", V(3.08, 0.3, 1.78), V(0, 1.83, 0), 5, "X", c == IRON and WOOD or planche)
	lames(m, "Faîtage", V(3, 0.19, 1.18), V(0, 2.04, 0), 5, "X", planche)
	for _, x in { -0.98, 0.98 } do
		local mat, couleur = renforce and Mat.Metal or Mat.Fabric, renforce and IRON or DARK
		for _, z in { -1, 1 } do
			piece(m, "Sangle", V(0.24, 1.66, 0.09), V(x, 0.9, z), couleur, mat, nil, nil, true)
			lien(m, "Retour", V(x, 1.68, z), V(x, 2.13, z * 0.54), 0.24, 0.09, couleur, mat, true)
		end
		piece(m, "Sangle", V(0.24, 0.08, 1.18), V(x, 2.15, 0), couleur, mat, nil, nil, true)
		for _, y in { 0.3, 1.42 } do rivet(m, V(x, y, 1.063), 0.12, renforce and COLORS.P or COLORS.O) end
	end
	fer(m, "Serrure", V(0.45, 0.41, 0.11), V(0, 1.55, 1.04), COLORS.O)
	fer(m, "Entrée", V(0.09, 0.19, 0.05), V(0, 1.57, 1.12))
end


-- Le nom Tete et le préfixe Tete sont lus par Systemes/Tourelles pour la rotation.
local function affut(m, c, grand)
	local w, niveau = grand and 4 or 2.6, grand and 3.36 or 2.74
	pierre(m, "Dalle", V(w, 0.28, w), V(0, 0.14, 0), STONE, Mat.Cobblestone)
	for _, x in { -1, 1 } do
		local pied = V(x * w * 0.33, 0.29, 0)
		bois(m, "Semelle", V(0.39, 0.24, w * 0.85), pied, DARK)
		for _, z in { -1, 1 } do
			lien(m, "Contrefiche", V(pied.X, 0.36, z * w * 0.34), V(x * 0.24, niveau - 0.16, z * 0.24),
				0.32, 0.32, c, Mat.Wood)
		end
	end
	bois(m, "Fût", V(0.63, niveau, 0.63), V(0, niveau / 2 + 0.1, 0), DARK)
	cyl(m, "Couronne", grand and 1.28 or 0.94, 0.22, V(0, niveau, 0), IRON, Mat.Metal)
	local y, rayon, longueur = niveau + (grand and 0.64 or 0.37), grand and 2.46 or 1.46, grand and 4.1 or 2.45
	bois(m, "Tete", V(grand and 1.28 or 0.96, grand and 0.92 or 0.58, longueur), V(0, y, 0), DARK)
	for _, x in { -1, 1 } do
		local coude = V(x * rayon * 0.62, y + 0.22, -longueur * 0.34)
		local pointe = V(x * rayon, y + 0.31, -longueur * 0.15)
		lien(m, "Tete_branche", V(0, y + 0.18, -longueur * 0.43), coude, 0.24, 0.26, c, Mat.Wood, true)
		lien(m, "Tete_branche", coude, pointe, 0.19, 0.21, c, Mat.Wood, true)
		lien(m, "Tete_corde", pointe, V(0, y + 0.31, longueur * 0.33), 0.046, 0.046, CLOTH, Mat.Fabric, true)
	end
	fer(m, "Tete_glissiere", V(0.37, 0.11, longueur * 0.91), V(0, y + (grand and 0.47 or 0.30), 0))
	fer(m, "Tete_carreau", V(0.13, 0.13, longueur * 0.72), V(0, y + (grand and 0.56 or 0.39), -longueur * 0.14))
	boule(m, "Tete_pointe", V(0.27, 0.26, 0.32), V(0, y + (grand and 0.56 or 0.39), -longueur * 0.51), IRON, Mat.Metal)
end

ARCH.tourelle = function(m, c) affut(m, c, false) end
ARCH.baliste = function(m, c) affut(m, c, true) end
K.MODELS.Cat_tourelle = { arch = "tourelle", color = "B" }
K.MODELS.Cat_baliste = { arch = "baliste", color = "BF" }

local function buches(m, centre, largeur)
	for i = 0, 2 do
		local a = i * math.pi / 3 + 0.21
		local v = V(math.cos(a), 0, math.sin(a)) * largeur / 2
		lien(m, "Bûche", centre - v, centre + v, 0.26, 0.26, teinte(DARK, i), Mat.Wood, false)
	end
end

ARCH.cheminee = function(m, c)
	pierre(m, "Âtre", V(4.95, 0.25, 2.02), V(0, 0.125, 0), c, Mat.Cobblestone)
	pierre(m, "Fond noirci", V(4.25, 3.42, 0.45), V(0, 1.92, -0.73), COLORS.F, Mat.Slate)
	for _, x in { -1.91, 1.91 } do
		for i = 0, 4 do
			pierre(m, "Jambage", V(0.91 + i % 2 * 0.12, 0.62, 1.79), V(x, 0.49 + i * 0.61, 0.04),
				c:Lerp(COLORS.PC, i % 3 * 0.21), Mat.Cobblestone)
		end
	end
	pierre(m, "Linteau", V(4.65, 0.55, 1.83), V(0, 3.38, 0.02), COLORS.PC)
	pierre(m, "Corniche", V(4.99, 0.24, 2), V(0, 3.73, 0), COLORS.PC)
	for i = 0, 8 do
		local joints = i % 2 == 0 and { 0.29, 0.43, 0.28 } or { 0.46, 0.54 }
		assises(m, 4.13 + i * 0.68, 0.69, 2.39, 1.55, -0.2, c, joints)
	end
	pierre(m, "Couronnement", V(2.73, 0.26, 1.8), V(0, 9.77, -0.2), COLORS.PC)
	buches(m, V(0, 0.36, 0.31), 1.62)
	flamme(m, V(0, 0.73, 0.31), 0.78, 16, 1.4, 2)
end

ARCH.foyer = function(m, c)
	cyl(m, "Cendres", 2.61, 0.11, V(0, 0.057, 0), COLORS.N, Mat.Slate)
	for i = 0, 8 do
		local a = i * TAU / 9
		pierre(m, "Pierre", V(0.68, 0.44 + i % 3 * 0.08, 0.81), V(math.cos(a) * 1.38,
			(0.44 + i % 3 * 0.08) / 2, math.sin(a) * 1.38), c:Lerp(COLORS.PC, i % 4 * 0.12),
			i % 2 == 0 and Mat.Rock or Mat.Slate, CFrame.Angles(0, -a + 0.14, 0))
	end
	buches(m, V(0, 0.17, 0.03), 1.61)
	flamme(m, V(0, 0.52, 0.02), 0.68, 14, 1.4, 2)
end

ARCH.fourpain = function(m, c)
	local argile = c:Lerp(Color3.fromRGB(178, 143, 100), 0.67)
	local chamotte = argile:Lerp(COLORS.PC, 0.26)
	for i = 0, 1 do
		assises(m, 0.246 + i * 0.49, 0.51, 4.27, 4.22, 0, STONE, i == 0 and { 0.25, 0.43, 0.32 } or { 0.43, 0.31, 0.26 })
	end
	pierre(m, "Sole", V(4.39, 0.22, 4.36), V(0, 1.07, 0), COLORS.PC)
	-- La moitié basse de l'ellipsoïde est noyée dans le socle.
	piece(m, "Dôme d’argile", V(3.99, 2.70, 3.92), V(0, 1.38, -0.17), argile, Mat.Slate, "boule")
	for _, x in { -0.79, 0.79 } do
		pierre(m, "Jambage", V(0.39, 0.57, 0.85), V(x, 1.445, 1.69), chamotte, Mat.Brick)
	end
	pierre(m, "Fond noirci", V(1.31, 0.59, 0.12), V(0, 1.46, 1.79), COLORS.N)
	boule(m, "Voûte noircie", V(1.37, 1.22, 0.21), V(0, 1.71, 1.78), COLORS.N, Mat.Slate)
	for i = 0, 8 do
		local a = i * math.pi / 8
		local noirci = i >= 2 and i <= 6 and 0.12 or 0
		pierre(m, "Claveau", V(0.342, 0.31, 0.82),
			V(math.cos(a) * 0.78, 1.71 + math.sin(a) * 0.725, 1.71 + (i == 4 and 0.026 or 0)),
			chamotte:Lerp(DARK, noirci + i % 3 * 0.079), Mat.Brick, CFrame.Angles(0, 0, a - math.pi / 2))
	end
	pierre(m, "Seuil enfumé", V(1.56, 0.09, 0.64), V(0, 1.209, 1.82), argile:Lerp(DARK, 0.47))
	local braises = boule(m, "Braises", V(0.69, 0.105, 0.26), V(0, 1.277, 1.849), Color3.fromRGB(207, 100, 43), Mat.Neon)
	local lueur = Instance.new("PointLight")
	lueur.Color, lueur.Range, lueur.Brightness = Color3.fromRGB(255, 166, 93), 4.5, 0.48
	lueur.Parent = braises

	cyl(m, "Évent", 0.58, 1.04, V(0.64, 3.01, -0.69), chamotte, Mat.Brick)
	cyl(m, "Bord de l’évent", 0.73, 0.16, V(0.64, 3.52, -0.69), chamotte, Mat.Brick)
	cyl(m, "Trou de fumée", 0.47, 0.023, V(0.64, 3.604, -0.69), COLORS.N, Mat.Slate, nil, true)

	bois(m, "Pale de la pelle", V(0.44, 0.56, 0.095), V(1.61, 0.35, 2.08), COLORS.BC, true, CFrame.Angles(0, 0, 0.36))
	lien(m, "Manche de la pelle", V(1.57, 0.46, 2.13), V(0.93, 2.02, 2.071), 0.105, 0.112, WOOD, Mat.Wood, true)
end

ARCH.chaudron = function(m, c)
	for i = 0, 2 do
		local a = (i + 0.4) * TAU / 3
		local x, z = math.cos(a), math.sin(a)
		lien(m, "Pied de fonte", V(x * 0.83, 0.14, z * 0.83), V(x * 0.66, 0.67, z * 0.66), 0.25, 0.25, IRON, Mat.Metal, false)
		cyl(m, "Patin", 0.26, 0.15, V(x * 0.83, 0.075, z * 0.83), IRON, Mat.Metal)
	end
	piece(m, "Panse", V(2.47, 1.88, 2.47), V(0, 1.36, 0), c:Lerp(IRON, 0.32), Mat.Metal, "boule")
	cyl(m, "Col", 2.11, 0.38, V(0, 2.22, 0), IRON, Mat.Metal)
	anneau(m, "Lèvre", V(0, 2.43, 0), 1.02, 10, 0.16, IRON, Mat.Metal, "XZ")
	verre(m, "Décoction", V(0.055, 1.99, 1.99), V(0, 2.42, 0), Color3.fromRGB(81, 97, 61), "cylindre", UP)
	for _, x in { -1.10, 1.10 } do
		anneau(m, "Anse", V(x, 1.94, 0), 0.22, 6, 0.085, IRON, Mat.Metal, "YZ")
		fer(m, "Oreille", V(0.32, 0.17, 0.15), V(x, 2.06, 0))
	end
	buches(m, V(0, 0.14, 0), 1.02)
	flamme(m, V(0, 0.35, 0), 0.46, 10, 1.4, 1.2)
end

ARCH.bassine = function(m, c)
	cyl(m, "Fond", 2.56, 0.28, V(0, 0.14, 0), DARK, Mat.WoodPlanks)
	for i = 0, 13 do
		local a = i * TAU / 14
		local rot = CFrame.Angles(0, a, 0) * CFrame.Angles(0.12, 0, 0)
		piece(m, "Douelle", V(0.64, 0.95, 0.16), V(math.sin(a) * 1.35, 0.69, math.cos(a) * 1.35),
			teinte(c, i), Mat.WoodPlanks, nil, rot)
	end
	for _, y in { 0.34, 0.99 } do
		anneau(m, "Cercle", V(0, y, 0), y < 0.5 and 1.35 or 1.45, 10, 0.13, IRON, Mat.Metal, "XZ")
	end
	verre(m, "Eau", V(0.12, 2.64, 2.64), V(0, 0.88, 0), EAU, "cylindre", UP)
end

ARCH.mannequin = function(m, c)
	local armure = m.Name == "Cat_deco_armor"
	lames(m, "Socle", V(1.59, 0.22, 1.59), V(0, 0.11, 0), 3, "X", WOOD)
	pierre(m, "Semelle", V(0.79, 0.2, 0.79), V(0, 0.26, 0), STONE)
	bois(m, "Montant", V(0.26, 4.08, 0.26), V(0, 2.25, 0), DARK)
	bois(m, "Épaules", V(1.83, 0.24, 0.28), V(0, 3.92, 0), WOOD)
	for _, x in { -0.62, 0.62 } do rivet(m, V(x, 3.93, 0.16), 0.105) end
	if armure then
		boule(m, "Cuirasse", V(1.64, 1.59, 0.81), V(0, 3.42, 0), c, Mat.Metal)
		for _, x in { -0.85, 0.85 } do
			boule(m, "Spallière", V(0.52, 0.47, 0.64), V(x * 0.94, 3.9, 0.01), c:Lerp(IRON, 0.29), Mat.Metal)
		end
		for i = 0, 2 do fer(m, "Lame de braconnière", V(1.04 + i * 0.13, 0.18, 0.45), V(0, 2.64 + i * 0.15, 0.18)) end
		boule(m, "Heaume", V(0.86, 1.0, 0.9), V(0, 4.77, 0), c, Mat.Metal)
		fer(m, "Visière", V(0.64, 0.16, 0.13), V(0, 4.76, 0.42))
	else
		toile(m, "Gambison", V(1.28, 1.49, 0.48), V(0, 3.39, 0), COLORS.BL)
		toile(m, "Ceinture", V(1.29, 0.15, 0.52), V(0, 2.94, 0), DARK)
		fer(m, "Boucle", V(0.23, 0.2, 0.08), V(0.15, 2.94, 0.26), COLORS.O)
		boule(m, "Pommeau", V(0.63, 0.65, 0.62), V(0, 4.5, 0), COLORS.BC, Mat.Wood)
	end
end

ARCH.banniere = function(m, c)
	local clan = m.Name == "Cat_clan_banner"
	pierre(m, "Pied", V(0.72, 0.27, 0.72), V(0, 0.135, 0), STONE)
	bois(m, "Hampe", V(0.29, 6.82, 0.3), V(0, 3.55, 0), DARK)
	bois(m, "Tringle", V(2.31, 0.17, 0.19), V(0, 6.73, 0), WOOD)
	for _, x in { -1.15, 1.15 } do
		boule(m, "Pommeau", V(0.23, 0.23, 0.23), V(x, 6.74, 0), COLORS.O, Mat.Metal)
	end
	for i = -2, 2 do
		local x, h = i * 0.435, clan and 3.65 - math.abs(i) * 0.24 or 3.25 + math.abs(i) * 0.17
		toile(m, "Lé", V(0.443, h, 0.10), V(x, 6.73 - h / 2, 0.11 + i % 2 * 0.026), c:Lerp(DARK, i % 2 * 0.11))
		toile(m, "Frange", V(0.431, 0.12, 0.105), V(x, 6.75 - h, 0.11 + i % 2 * 0.026), COLORS.O)
		if math.abs(i) == 2 then
			toile(m, "Galon", V(0.065, h, 0.027), V(x, 6.73 - h / 2, 0.177), COLORS.O)
		end
	end
	toile(m, "Motif", V(0.83, 0.83, 0.055), V(0, 5.19, 0.186), COLORS.O, CFrame.Angles(0, 0, math.pi / 4))
	if clan then
		toile(m, "Motif", V(0.35, 0.35, 0.035), V(0, 5.19, 0.226), c, CFrame.Angles(0, 0, math.pi / 4))
	end
end

ARCH.drapeau = function(m, c)
	pierre(m, "Pied", V(0.55, 0.24, 0.55), V(0, 0.12, 0), STONE)
	bois(m, "Hampe", V(0.25, 8.64, 0.25), V(0, 4.43, 0), DARK)
	boule(m, "Pommeau", V(0.28, 0.28, 0.28), V(0, 8.86, 0), COLORS.O, Mat.Metal)
	for i = 0, 5 do
		local z, h = 0.37 + i * 0.45, 1.79 - i * 0.12
		local x = math.sin(i * 0.8) * 0.12
		toile(m, "Drapeau", V(0.13, h, 0.47), V(x, 8.68 - h / 2 - i * 0.07, z), c:Lerp(COLORS.Y, i % 2 * 0.24))
		toile(m, "Galon", V(0.135, 0.14, 0.46), V(x, 8.45 - i * 0.07, z), COLORS.R)
	end
end

ARCH.blason = function(m, c)
	local bouclier = m.Name == "Cat_deco_shield"
	pierre(m, "Pied", V(0.6, 0.25, 0.73), V(0, 0.125, 0), STONE)
	bois(m, "Montant", V(0.28, 2.64, 0.28), V(0, 1.46, -0.19), DARK)
	for i = -2, 2 do
		local h = 2.75 - math.abs(i) * 0.39
		bois(m, "Ais", V(0.46, h, 0.23), V(i * 0.45, 3.61 - h / 2, 0), c)
		fer(m, "Bordure", V(0.46, 0.13, 0.28), V(i * 0.45, 3.58, 0), COLORS.O)
		rivet(m, V(i * 0.45, 3.53 - (bouclier and 0.16 or 0), 0.156), 0.10, IRON)
	end
	if bouclier then
		boule(m, "Umbo", V(0.69, 0.7, 0.32), V(0, 2.48, 0.19), IRON, Mat.Metal)
		anneau(m, "Guilloche", V(0, 2.48, 0.18), 0.48, 8, 0.055, COLORS.O, Mat.Metal, "XY")
	else
		fer(m, "Armoiries", V(0.25, 1.27, 0.071), V(0, 2.52, 0.145), COLORS.O)
		fer(m, "Armoiries", V(1.07, 0.26, 0.071), V(0, 2.68, 0.145), COLORS.O)
	end
	-- Le plan de pose historique présente les armoiries sur le côté de la case.
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p ~= m.PrimaryPart then p.CFrame = FACE * p.CFrame end
	end
end

ARCH.enseigne = function(m, c)
	pierre(m, "Pied", V(0.71, 0.38, 0.69), V(0, 0.19, 0), STONE)
	bois(m, "Potence", V(0.33, 4.74, 0.37), V(0, 2.61, 0), DARK)
	bois(m, "Bras", V(2.39, 0.24, 0.27), V(1.02, 4.8, 0), c)
	lien(m, "Jambe de force", V(0.1, 3.95, 0), V(0.86, 4.73, 0), 0.19, 0.19, DARK, Mat.Wood, false)
	for _, x in { 0.66, 1.78 } do
		anneau(m, "Maillon", V(x, 4.46, 0), 0.25, 6, 0.062, IRON, Mat.Metal, "XY")
	end
	lames(m, "Panneau", V(1.91, 1.12, 0.21), V(1.22, 3.69, 0), 3, "Y", COLORS.BC)
	for _, y in { 3.18, 4.22 } do bois(m, "Traverse", V(2.02, 0.15, 0.24), V(1.22, y, 0), DARK) end
	for _, x in { 0.44, 2.01 } do rivet(m, V(x, 3.69, 0.13), 0.11) end
	fer(m, "Losange", V(0.50, 0.50, 0.072), V(1.22, 3.69, 0.14), COLORS.O, CFrame.Angles(0, 0, math.pi / 4))
end

local function socle(m, w, h, c)
	pierre(m, "Plinthe", V(w, h * 0.23, w), V(0, h * 0.115, 0), STONE, Mat.Cobblestone)
	pierre(m, "Congé", V(w * 0.91, h * 0.12, w * 0.91), V(0, h * 0.28, 0), COLORS.PC)
	pierre(m, "Dé", V(w * 0.76, h * 0.54, w * 0.76), V(0, h * 0.58, 0), c)
	pierre(m, "Corniche", V(w * 0.92, h * 0.12, w * 0.92), V(0, h * 0.88, 0), COLORS.PC)
	pierre(m, "Tablette", V(w * 0.98, h * 0.085, w * 0.98), V(0, h * 0.956, 0), c)
end

ARCH.socle = function(m, c)
	socle(m, 2.4, 3.1, c)
	for _, x in { -0.65, 0.65 } do
		pierre(m, "Pilastre", V(0.2, 1.53, 0.18), V(x, 1.84, 0.9), STONE)
	end
	pierre(m, "Cartouche", V(0.72, 0.43, 0.11), V(0, 2.03, 0.93), COLORS.PC)
end

ARCH.statue = function(m, c)
	socle(m, 2.4, 0.96, c)
	local patine = c:Lerp(STONE, 0.6)
	for _, x in { -0.24, 0.24 } do
		pierre(m, "Soleret", V(0.43, 0.23, 0.71), V(x, 1.066, 0.115), patine)
		lien(m, "Jambe", V(x, 1.12, -0.02), V(x * 1.07, 2.45, -0.02), 0.41, 0.44, c, Mat.Slate, false)
		pierre(m, "Genouillère", V(0.41, 0.28, 0.21), V(x, 1.84, 0.22), patine, Mat.Rock)
	end
	pierre(m, "Tassettes", V(0.94, 0.41, 0.62), V(0, 2.34, -0.04), patine)
	pierre(m, "Torse", V(0.92, 1.08, 0.62), V(0, 2.89, -0.04), c)
	boule(m, "Relief de la cuirasse", V(1.27, 1.09, 0.49), V(0, 2.98, 0.16), c, Mat.Slate)
	pierre(m, "Ceinture sculptée", V(0.99, 0.17, 0.73), V(0, 2.483, -0.03), patine)
	piece(m, "Cape", V(1.24, 2.26, 0.55), V(0, 2.22, -0.415), patine, Mat.Slate, "coin")
	for _, x in { -0.39, 0, 0.39 } do
		lien(m, "Pli de cape", V(x * 1.25, 1.18, -0.61), V(x, 3.28, -0.44), 0.15, 0.17, c, Mat.Slate, true)
	end
	for _, s in { -1, 1 } do
		local epaule = V(s * 0.59, 3.27, -0.03)
		local coude = V(s * 0.71, 2.73 + s * 0.08, 0.23)
		local main = V(s * 0.09, 2.66 + s * 0.085, 0.633)
		boule(m, "Épaulière", V(0.54, 0.39, 0.67), epaule, patine, Mat.Slate)
		lien(m, "Bras", epaule, coude, 0.35, 0.35, c, Mat.Slate, true)
		lien(m, "Avant-bras", coude, main, 0.31, 0.29, c, Mat.Slate, true)
		boule(m, "Gantelet", V(0.31, 0.24, 0.27), main, patine, Mat.Slate)
	end
	cyl(m, "Gorgerin", 0.54, 0.26, V(0, 3.49, -0.05), patine, Mat.Slate)
	cyl(m, "Heaume", 0.77, 0.61, V(0, 3.93, -0.05), c, Mat.Slate)
	boule(m, "Calotte du heaume", V(0.77, 0.40, 0.77), V(0, 4.25, -0.05), c, Mat.Slate)
	pierre(m, "Fente de visière", V(0.49, 0.097, 0.125), V(0, 4.015, 0.29), STONE:Lerp(COLORS.F, 0.28))
	pierre(m, "Arête du heaume", V(0.093, 0.49, 0.14), V(0, 3.968, 0.344), patine, Mat.Slate)
	pierre(m, "Poignée d’épée", V(0.18, 0.48, 0.17), V(0, 2.681, 0.63), patine)
	pierre(m, "Garde de l’épée", V(0.73, 0.12, 0.22), V(0, 2.429, 0.63), c)
	pierre(m, "Lame de l’épée", V(0.23, 1.26, 0.14), V(0, 1.755, 0.63), c)
	pierre(m, "Pointe d’épée", V(0.16, 0.16, 0.14), V(0, 1.121, 0.63), c, Mat.Slate,
		CFrame.Angles(0, 0, math.pi / 4))
end

ARCH.sculpture = function(m, c)
	socle(m, 1.6, 0.83, c)
	local patine = STONE:Lerp(c, 0.45)
	piece(m, "Roc sculpté", V(1.39, 0.53, 1.47), V(0, 1.02, 0), STONE, Mat.Rock, "boule")
	piece(m, "Poitrail", V(0.90, 1.13, 1.29), V(0, 1.73, 0.025), c, Mat.Slate, "boule", CFrame.Angles(0.44, 0, 0))
	boule(m, "Gorge", V(0.64, 0.67, 0.68), V(0, 2.17, 0.23), c, Mat.Slate)
	boule(m, "Tête du faucon", V(0.57, 0.50, 0.65), V(0, 2.476, 0.29), c, Mat.Slate)
	piece(m, "Bec du faucon", V(0.32, 0.24, 0.34), V(0, 2.408, 0.602), patine, Mat.Slate, "boule")
	piece(m, "Crochet du bec", V(0.21, 0.26, 0.22), V(0, 2.30, 0.675), patine, Mat.Slate, "coin",
		CFrame.Angles(math.pi, 0, 0), true)
	for _, s in { -1, 1 } do
		boule(m, "Œil sculpté", V(0.108, 0.103, 0.128), V(s * 0.257, 2.501, 0.425), STONE, Mat.Slate)
		lien(m, "Sourcil sculpté", V(s * 0.253, 2.551, 0.31), V(s * 0.226, 2.545, 0.502),
			0.093, 0.078, c, Mat.Slate, true)
		piece(m, "Aile repliée", V(0.29, 0.63, 1.09), V(s * 0.357, 1.813, -0.126), patine, Mat.Slate, "boule",
			CFrame.Angles(-0.33, s * 0.14, 0), true)
		for i = 0, 2 do
			lien(m, "Rémige sculptée", V(s * (0.415 - i * 0.032), 1.89 - i * 0.095, 0.08),
				V(s * (0.395 - i * 0.07), 1.62 - i * 0.089, -0.59 + i * 0.04), 0.127, 0.14,
				i % 2 == 0 and c or patine, Mat.Slate, true)
		end
		lien(m, "Serre", V(s * 0.21, 1.44, 0.25), V(s * 0.29, 1.19, 0.39), 0.16, 0.16, patine, Mat.Slate, true)
		for i = -1, 1 do
			lien(m, "Griffe", V(s * 0.29, 1.20, 0.35), V(s * 0.29 + i * 0.103, 1.14, 0.55),
				0.072, 0.08, c, Mat.Slate, true)
		end
	end
	piece(m, "Queue du faucon", V(0.53, 0.24, 0.75), V(0, 1.43, -0.54), c, Mat.Slate, "coin",
		CFrame.Angles(0.48, math.pi, 0), true)
end

local function ceramique(m, c, profil)
	for i, tranche in profil do
		cyl(m, "Terre tournée", tranche[2], tranche[3], V(0, tranche[1], 0), teinte(c, i), Mat.CeramicTiles)
	end
end

ARCH.vase = function(m, c)
	ceramique(m, c, { { 0.07, 0.83, 0.14 }, { 0.29, 1.11, 0.35 }, { 0.64, 1.38, 0.40 },
		{ 1.0, 1.30, 0.35 }, { 1.31, 0.99, 0.31 }, { 1.59, 0.65, 0.3 }, { 1.84, 0.55, 0.25 } })
	for _, y in { 0.64, 0.78 } do cyl(m, "Engobe", 1.41, 0.054, V(0, y, 0), COLORS.BL, Mat.CeramicTiles, nil, true) end
	cyl(m, "Col évasé", 0.74, 0.13, V(0, 1.99, 0), c, Mat.CeramicTiles)
	cyl(m, "Intérieur", 0.53, 0.017, V(0, 2.064, 0), DARK, Mat.CeramicTiles, nil, true)
	for _, x in { -0.59, 0.59 } do
		anneau(m, "Anse", V(x, 1.34, 0), 0.25, 6, 0.09, c, Mat.CeramicTiles, "XY")
	end
end

ARCH.pichet = function(m, c)
	ceramique(m, c, { { 0.055, 0.66, 0.11 }, { 0.24, 0.78, 0.28 }, { 0.52, 0.87, 0.31 },
		{ 0.78, 0.78, 0.23 }, { 0.99, 0.53, 0.22 }, { 1.16, 0.58, 0.14 } })
	cyl(m, "Intérieur", 0.45, 0.019, V(0, 1.235, 0), DARK, Mat.CeramicTiles, nil, true)
	piece(m, "Bec", V(0.27, 0.093, 0.24), V(-0.32, 1.19, 0), c, Mat.CeramicTiles, "coin", FACE, true)
	anneau(m, "Anse", V(0.41, 0.85, 0), 0.24, 7, 0.095, c, Mat.CeramicTiles, "XY")
	cyl(m, "Engobe", 0.88, 0.045, V(0, 0.49, 0), CLOTH, Mat.CeramicTiles, nil, true)
end

ARCH.pot = function(m, c)
	ceramique(m, c, { { 0.06, 0.81, 0.12 }, { 0.23, 0.89, 0.24 }, { 0.47, 1.0, 0.26 }, { 0.7, 1.1, 0.24 } })
	anneau(m, "Rebord", V(0, 0.86, 0), 0.54, 10, 0.14, c, Mat.CeramicTiles, "XZ")
	cyl(m, "Terreau", 1.02, 0.078, V(0, 0.79, 0), DARK, Mat.Ground, nil, true)
	for _, y in { 0.27, 0.55 } do
		cyl(m, "Sillon", y < 0.4 and 0.91 or 1.02, 0.041, V(0, y, 0), c:Lerp(DARK, 0.25), Mat.CeramicTiles, nil, true)
	end
end

ARCH.jardiniere = function(m, c)
	lames(m, "Fond", V(3.56, 0.22, 1.14), V(0, 0.11, 0), 5, "X", c)
	for _, z in { -0.55, 0.55 } do
		lames(m, "Bordage", V(3.59, 0.74, 0.13), V(0, 0.52, z), 3, "Y", c)
	end
	for _, x in { -1.72, 1.72 } do
		bois(m, "Joue", V(0.16, 0.8, 1.19), V(x, 0.48, 0), DARK)
		for _, z in { -0.56, 0.56 } do bois(m, "Cornière", V(0.2, 0.9, 0.17), V(x, 0.46, z), DARK) end
	end
	piece(m, "Terreau", V(3.25, 0.27, 1.01), V(0, 0.7, 0), DARK, Mat.Ground)
	for i = 0, 4 do
		local x, h, z = (i - 2) * 0.64, 0.47 + i % 3 * 0.12, 0.17 - i % 2 * 0.34
		local fleur = V(x + 0.10, 0.82 + h, z)
		lien(m, "Tige", V(x, 0.81, z), fleur, 0.063, 0.063, COLORS.V, Mat.Grass, true)
		boule(m, "Feuille", V(0.39, 0.15, 0.18), V(x - 0.08, 0.92 + h * 0.35, z), COLORS.V, Mat.Grass)
		boule(m, "Fleur", V(0.36, 0.24, 0.33), fleur, i % 2 == 0 and COLORS.R or COLORS.O, Mat.Grass)
	end
end


ARCH.torche = function(m, c)
	pierre(m, "Semelle", V(0.49, 0.23, 0.51), V(0, 0.115, -0.14), STONE)
	bois(m, "Support", V(0.28, 2.49, 0.27), V(0, 1.37, -0.19), c)
	fer(m, "Platine", V(0.34, 0.76, 0.11), V(0, 2.19, -0.064))
	for _, y in { 1.89, 2.49 } do rivet(m, V(0, y, 0.008), 0.09, COLORS.P) end
	lien(m, "Manche", V(0, 1.85, -0.03), V(0, 2.87, 0.30), 0.17, 0.17, WOOD, Mat.Wood, true)
	cyl(m, "Ligature", 0.29, 0.21, V(0, 2.77, 0.28), DARK, Mat.Fabric, UP * CFrame.Angles(0, 0.27, 0), true)
	cyl(m, "Corbeille", 0.44, 0.21, V(0, 2.9, 0.3), IRON, Mat.Metal, nil, true)
	flamme(m, V(0, 3.18, 0.3), 0.60, 14, 1.4, 1.65)
end

ARCH.lanterne_murale = function(m, c)
	fer(m, "Platine", V(0.36, 0.83, 0.12), V(0, 3.28, 0), c)
	fer(m, "Potence", V(0.14, 0.14, 0.76), V(0, 3.65, 0.38), c)
	lien(m, "Jambe de force", V(0, 3.27, 0.04), V(0, 3.65, 0.45), 0.08, 0.09, c, Mat.Metal, true)
	for _, y in { 3.0, 3.55 } do rivet(m, V(0, y, 0.068), 0.095, COLORS.P) end
	anneau(m, "Bélière", V(0, 3.52, 0.73), 0.125, 6, 0.068, c, Mat.Metal, "YZ")
	fer(m, "Chapeau", V(0.65, 0.12, 0.64), V(0, 3.34, 0.75), c)
	fer(m, "Sommet", V(0.4, 0.10, 0.41), V(0, 3.44, 0.75), c)
	fer(m, "Fond", V(0.62, 0.12, 0.62), V(0, 2.61, 0.75), c)
	verre(m, "Verre ambré", V(0.53, 0.66, 0.53), V(0, 2.98, 0.75), Color3.fromRGB(235, 167, 85))
	for _, x in { -0.27, 0.27 } do
		for _, z in { 0.49, 1.01 } do fer(m, "Montant", V(0.076, 0.76, 0.077), V(x, 2.98, z), c) end
	end
	flamme(m, V(0, 2.85, 0.75), 0.32, 14, 0.92)
end
K.MODELS.Cat_wall_lantern = { arch = "lanterne_murale", color = "F" }

ARCH.brasero = function(m, c)
	for i = 0, 2 do
		local a = i * TAU / 3
		local x, z = math.cos(a), math.sin(a)
		cyl(m, "Pied", 0.29, 0.17, V(x * 0.56, 0.085, z * 0.56), c, Mat.Metal)
		lien(m, "Jambe", V(x * 0.56, 0.12, z * 0.56), V(x * 0.33, 2.52, z * 0.33), 0.19, 0.19, c, Mat.Metal, false)
	end
	cyl(m, "Couronne", 0.97, 0.16, V(0, 1.37, 0), IRON, Mat.Metal)
	cyl(m, "Fond", 1.13, 0.19, V(0, 2.46, 0), c, Mat.Metal)
	for i = 0, 7 do
		local a = i * TAU / 8
		local x, z = math.cos(a), math.sin(a)
		lien(m, "Nervure", V(x * 0.49, 2.47, z * 0.49), V(x * 0.93, 2.96, z * 0.93), 0.15, 0.15, c, Mat.Metal, true)
		rivet(m, V(x * 0.94, 2.96, z * 0.94), 0.16, COLORS.P)
	end
	anneau(m, "Cercle", V(0, 2.96, 0), 0.92, 8, 0.14, IRON, Mat.Metal, "XZ")
	buches(m, V(0, 2.64, 0), 1.12)
	flamme(m, V(0, 2.94, 0), 0.82, 20, 1.4, 2)
end

local function cire(m, pos, h, d, c, portee, intensite)
	cyl(m, "Godet", d * 1.64, 0.11, pos, COLORS.O, Mat.Metal)
	cyl(m, "Cire", d, h, pos + V(0, h / 2 + 0.045, 0), c, Mat.Marble)
	boule(m, "Coulure", V(d * 0.32, h * 0.57, d * 0.27), pos + V(d * 0.31, h * 0.61, d * 0.35), c, Mat.Marble)
	bois(m, "Mèche", V(0.05, 0.17, 0.055), pos + V(0, h + 0.09, 0), DARK, true)
	flamme(m, pos + V(0, h + 0.21, 0), 0.22, portee, intensite)
end

ARCH.bougie = function(m, c)
	cyl(m, "Pied", 0.74, 0.12, V(0, 0.06, 0), IRON, Mat.Metal)
	cyl(m, "Coupelle", 0.8, 0.09, V(0, 0.16, 0), COLORS.O, Mat.Metal)
	anneau(m, "Anse", V(0.44, 0.20, 0), 0.13, 6, 0.045, COLORS.O, Mat.Metal, "XZ")
	cire(m, V(0, 0.23, 0), 0.75, 0.33, c, 8, 1)
end

ARCH.chandelier = function(m, c)
	cyl(m, "Pied", 1.04, 0.18, V(0, 0.09, 0), IRON, Mat.Metal)
	cyl(m, "Embase", 0.73, 0.17, V(0, 0.24, 0), c, Mat.Metal)
	cyl(m, "Fût", 0.22, 2.79, V(0, 1.68, 0), c, Mat.Metal)
	for _, y in { 0.49, 1.78, 2.55 } do cyl(m, "Bague", 0.38, 0.17, V(0, y, 0), c, Mat.Metal) end
	for _, x in { -1.07, 1.07 } do
		lien(m, "Ramure", V(0, 2.49, 0), V(x * 0.76, 2.65, 0), 0.15, 0.14, c, Mat.Metal, true)
		lien(m, "Ramure", V(x * 0.76, 2.65, 0), V(x, 3.10, 0), 0.14, 0.14, c, Mat.Metal, true)
	end
	for i, x in { -1.07, 0, 1.07 } do
		cire(m, V(x, 3.1, 0), 0.40 + 0.057 * i, 0.25, CLOTH, 14, 1 / 3)
	end
end

ARCH.tapis = function(m, c)
	toile(m, "Trame", V(5, 0.085, 3.24), V(0, 0.0425, 0), c)
	for _, z in { -1.44, 1.44 } do
		toile(m, "Galon", V(4.84, 0.03, 0.18), V(0, 0.085, z), COLORS.O)
	end
	for _, x in { -2.36, 2.36 } do
		toile(m, "Galon", V(0.15, 0.03, 2.86), V(x, 0.085, 0), COLORS.O)
		for i = -3, 3 do
			toile(m, "Frange", V(0.27, 0.036, 0.082), V(x * 1.047, 0.045, i * 0.42 + i % 2 * 0.015), CLOTH)
		end
	end
	for i = -1, 1 do
		local h = i == 0 and 0.87 or 0.55
		local rot = CFrame.Angles(0, math.pi / 4, 0)
		toile(m, "Médaillon", V(h, 0.025, h), V(i * 1.30, 0.095, 0), COLORS.O, rot)
		toile(m, "Écoinçon", V(h * 0.53, 0.025, h * 0.53), V(i * 1.30, 0.112, 0), CLOTH, rot)
	end
end

local function montant(m, x, h, z)
	bois(m, "Montant", V(0.21, h, 0.24), V(x, h / 2, z), DARK)
	bois(m, "Sabot", V(0.31, 0.24, 0.44), V(x, 0.12, z), WOOD)
end

ARCH.rideau = function(m, c)
	bois(m, "Tringle", V(3.96, 0.16, 0.18), V(0, 5.38, 0), DARK)
	for _, s in { -1, 1 } do
		montant(m, s * 1.83, 5.47, 0)
		for i = 0, 5 do
			local x = s * (0.21 + i * 0.285)
			local z = 0.093 + i % 2 * 0.09
			toile(m, "Pli", V(0.30, 4.97 + i % 3 * 0.035, 0.13), V(x, 2.88, z), c:Lerp(DARK, i % 2 * 0.16))
			fer(m, "Œillet", V(0.10, 0.21, 0.17), V(x, 5.34, z * 0.56), COLORS.O)
		end
		toile(m, "Galon", V(1.73, 0.13, 0.14), V(s * 0.92, 0.52, 0.157), COLORS.O)
	end
end

ARCH.tenture = function(m, c)
	fer(m, "Tringle", V(3.57, 0.15, 0.18), V(0, 5.37, 0), COLORS.O)
	for _, s in { -1, 1 } do
		montant(m, s * 1.64, 5.45, 0)
		toile(m, "Galon", V(0.13, 4.41, 0.05), V(s * 1.49, 3.15, 0.175), COLORS.O)
	end
	for i = -3, 3 do
		local z = 0.099 + i % 2 * 0.022
		toile(m, "Lé", V(0.46, 4.36, 0.12), V(i * 0.45, 3.16, z), c:Lerp(DARK, i % 2 * 0.13))
		toile(m, "Frange", V(0.43, 0.15 + i % 3 * 0.02, 0.11), V(i * 0.45, 0.95, z), COLORS.O)
	end
	for _, y in { 1.2, 5.1 } do toile(m, "Galon", V(3.12, 0.15, 0.045), V(0, y, 0.171), COLORS.O) end
	toile(m, "Médaillon", V(1.20, 1.20, 0.06), V(0, 3.25, 0.17), COLORS.O, CFrame.Angles(0, 0, math.pi / 4))
	toile(m, "Arbre brodé", V(0.16, 0.79, 0.05), V(0, 3.25, 0.215), DARK)
	for _, s in { -1, 1 } do
		toile(m, "Branche brodée", V(0.14, 0.53, 0.05), V(s * 0.17, 3.33, 0.217), DARK, CFrame.Angles(0, 0, -s * 0.62))
	end
end

ARCH.tableau = function(m, c)
	for _, s in { -1, 1 } do
		montant(m, s * 1.22, 3.34, -0.17)
		bois(m, "Patin", V(0.32, 0.18, 0.83), V(s * 1.22, 0.09, -0.21), DARK)
	end
	toile(m, "Toile", V(2.7, 2.13, 0.13), V(0, 2.99, 0), Color3.fromRGB(95, 141, 159))
	for _, x in { -1.42, 1.42 } do bois(m, "Cadre", V(0.17, 2.39, 0.26), V(x, 2.99, 0), DARK) end
	for _, y in { 1.87, 4.11 } do bois(m, "Cadre", V(2.98, 0.18, 0.26), V(0, y, 0), DARK) end
	toile(m, "Plaine", V(2.69, 0.65, 0.07), V(0, 2.23, 0.082), COLORS.V)
	for i = 0, 3 do
		piece(m, "Colline peinte", V(0.67, 0.43 + i % 3 * 0.19, 0.065), V(-0.99 + i * 0.65, 2.64, 0.082),
			i % 2 == 0 and COLORS.V or Color3.fromRGB(94, 112, 91), Mat.Fabric, "coin",
			FACE * CFrame.Angles(0, i % 2 * math.pi, 0), true)
	end
	cyl(m, "Soleil peint", 0.43, 0.055, V(0.67, 3.59, 0.086), c, Mat.Fabric, FACE, true)
end

ARCH.trophee = function(m, c)
	pierre(m, "Pied", V(0.6, 0.25, 0.6), V(0, 0.125, 0), STONE)
	bois(m, "Montant", V(0.26, 2.9, 0.28), V(0, 1.68, -0.08), DARK)
	for i = -1, 1 do
		local h = i == 0 and 1.91 or 1.66
		bois(m, "Écu", V(0.54, h, 0.2), V(i * 0.53, 3.94 - h / 2, 0), teinte(WOOD, i))
		rivet(m, V(i * 0.52, 3.83, 0.13), 0.092, c)
	end
	boule(m, "Merrain", V(0.74, 0.51, 0.32), V(0, 3.48, 0.17), COLORS.BC, Mat.Wood)
	for _, s in { -1, 1 } do
		local a, b, d = V(s * 0.21, 3.53, 0.21), V(s * 0.67, 4.08, 0.18), V(s * 0.86, 4.77 - s * 0.09, 0.15)
		lien(m, "Bois", a, b, 0.18, 0.15, CLOTH, Mat.Sand, true)
		lien(m, "Bois", b, d, 0.13, 0.12, CLOTH, Mat.Sand, true)
		lien(m, "Andouiller", b, V(s * 0.41, 4.51 + s * 0.1, 0.23), 0.1, 0.091, CLOTH, Mat.Sand, true)
	end
end

ARCH.crane = function(m, c)
	pierre(m, "Socle", V(1.31, 0.16, 1.45), V(0, 0.08, 0), STONE)
	boule(m, "Front", V(1.43, 0.99, 1.48), V(0, 0.69, -0.11), c, Mat.Sand)
	boule(m, "Museau", V(0.97, 0.52, 1.19), V(0, 0.45, 0.37), c, Mat.Sand)
	for _, x in { -0.47, 0.47 } do
		boule(m, "Orbite", V(0.33, 0.36, 0.25), V(x, 0.71, 0.45), DARK, Mat.Slate)
		lien(m, "Arcade", V(x * 0.77, 0.94, 0.5), V(x * 1.38, 0.79, 0.39), 0.13, 0.16, c, Mat.Sand, true)
		lien(m, "Corne", V(x, 0.93, -0.44), V(x * 1.47, 1.52, -0.48), 0.25, 0.24, COLORS.BC, Mat.Sand, true)
		lien(m, "Pointe", V(x * 1.47, 1.48, -0.48), V(x * 1.27, 2.10 + x * 0.13, -0.48),
			0.13, 0.14, c, Mat.Sand, true)
		lien(m, "Dent", V(x * 0.69, 0.52, 0.79), V(x * 0.61, 0.22, 0.85), 0.12, 0.10, c, Mat.Sand, true)
	end
end

ARCH.horloge = function(m, c)
	bois(m, "Plinthe", V(1.8, 0.27, 1.17), V(0, 0.135, 0), DARK)
	bois(m, "Dos", V(1.48, 5.62, 0.21), V(0, 2.92, -0.4), c)
	for _, x in { -0.69, 0.69 } do
		bois(m, "Joue", V(0.19, 5.48, 1), V(x, 2.92, 0), c)
		bois(m, "Montant mouluré", V(0.13, 4.25, 0.12), V(x, 2.62, 0.5), WOOD, true)
	end
	for _, y in { 0.36, 3.82, 5.63 } do bois(m, "Traverse", V(1.65, 0.21, 1.09), V(0, y, 0), DARK) end
	bois(m, "Tambour", V(1.54, 1.67, 0.78), V(0, 4.75, 0.06), c)
	cyl(m, "Lunette", 1.46, 0.14, V(0, 4.78, 0.48), COLORS.O, Mat.Metal, FACE, true)
	cyl(m, "Cadran", 1.25, 0.105, V(0, 4.78, 0.55), CLOTH, Mat.Marble, FACE, true)
	for i = 0, 11 do
		local a = i * TAU / 12
		fer(m, "Index", V(0.04, i % 3 == 0 and 0.15 or 0.083, 0.023),
			V(math.sin(a) * 0.51, 4.78 + math.cos(a) * 0.51, 0.61), IRON, CFrame.Angles(0, 0, -a))
	end
	for _, a in { -0.53, 1.03 } do
		local centre = V(0, 4.78, 0.625)
		lien(m, "Aiguille", centre, centre + V(math.sin(a) * 0.38, math.cos(a) * 0.38, 0), 0.049, 0.047, IRON, Mat.Metal, true)
	end
	fer(m, "Pendule", V(0.074, 1.43, 0.09), V(0, 2.71, 0.23), COLORS.O)
	cyl(m, "Poids", 0.55, 0.10, V(0, 2.06, 0.24), COLORS.O, Mat.Metal, FACE, true)
	verre(m, "Vitrine", V(1.25, 2.25, 0.08), V(0, 2.61, 0.48), VITRE).Transparency = 0.58
	bois(m, "Corniche", V(1.79, 0.24, 1.15), V(0, 5.78, 0), DARK)
	bois(m, "Couronnement", V(1.38, 0.19, 0.93), V(0, 5.97, 0), WOOD)
end

ARCH.girouette = function(m, c)
	pierre(m, "Pied", V(0.57, 0.24, 0.57), V(0, 0.12, 0), STONE)
	cyl(m, "Tige", 0.18, 5.95, V(0, 3.12, 0), c, Mat.Metal)
	for _, a in { 0, math.pi / 2 } do
		fer(m, "Rose des vents", V(2.36, 0.096, 0.1), V(0, 5.07, 0), c, CFrame.Angles(0, a, 0))
	end
	for _, pos in { V(-1.12, 5.07, 0), V(1.12, 5.07, 0), V(0, 5.07, -1.12), V(0, 5.07, 1.12) } do
		rivet(m, pos, 0.19, COLORS.O)
	end
	boule(m, "Pivot", V(0.35, 0.37, 0.35), V(0, 5.98, 0), COLORS.O, Mat.Metal)
	fer(m, "Flèche", V(0.1, 0.11, 1.96), V(0, 6.13, 0.1), c)
	piece(m, "Empennage", V(0.11, 0.52, 0.68), V(0, 6.26, -0.58), c, Mat.Metal, "coin", nil, true)
	boule(m, "Corps de coq", V(0.14, 0.49, 0.68), V(0, 6.45, 0.03), c, Mat.Metal)
	boule(m, "Tête de coq", V(0.15, 0.34, 0.36), V(0, 6.65, 0.28), COLORS.O, Mat.Metal)
	piece(m, "Bec", V(0.12, 0.13, 0.25), V(0, 6.65, 0.5), c, Mat.Metal, "coin", nil, true)
end


ARCH.muret = function(m, c)
	for i, joints in { { 0.23, 0.29, 0.20, 0.28 }, { 0.34, 0.21, 0.25, 0.20 }, { 0.18, 0.25, 0.29, 0.28 } } do
		assises(m, 0.27 + (i - 1) * 0.43, 0.55, 3.98, 0.85 - (i - 1) * 0.055, (i - 2) * 0.023, c, joints)
	end
	assises(m, 1.47, 0.26, 4, 1, 0, COLORS.PC, { 0.27, 0.26, 0.22, 0.25 })
end

ARCH.palissade = function(m, c)
	for i = 0, 4 do
		local x, y = (i - 2) * 0.744, 4.7 + i % 3 * 0.16
		cyl(m, "Pieu", 0.71, y, V(x, y / 2, 0), teinte(c, i), Mat.Wood)
		piece(m, "Tête taillée", V(0.58, 0.48, 0.63), V(x, y + 0.07, 0.01), teinte(c, i), Mat.Wood, "coin",
			CFrame.Angles(0, i % 2 * math.pi, 0))
		for _, h in { 1.09, 3.60 } do rivet(m, V(x, h, 0.432), 0.12) end
	end
	for _, y in { 1.09, 3.60 } do bois(m, "Lisse", V(3.98, 0.29, 0.24), V(0, y, 0.34), DARK) end
end

ARCH.portail = function(m, c)
	for _, x in { -1.99, 1.99 } do
		pierre(m, "Sabot", V(0.42, 0.28, 0.45), V(x, 0.14, 0), STONE)
		bois(m, "Poteau", V(0.38, 2.88, 0.4), V(x, 1.61, 0), DARK)
		piece(m, "Couronne", V(0.39, 0.32, 0.4), V(x, 2.9, 0), c, Mat.Wood, "coin")
	end
	for _, y in { 0.63, 1.39, 2.18 } do
		bois(m, "Lisse", V(3.59, 0.24, 0.19), V(0, y, 0), c)
		for _, x in { -1.69, 1.69 } do rivet(m, V(x, y, 0.13), 0.105) end
	end
	for _, x in { -1.69, 1.69 } do bois(m, "Montant", V(0.22, 2.04, 0.21), V(x, 1.39, 0), DARK) end
	lien(m, "Écharpe", V(-1.63, 0.60, 0.1), V(1.63, 2.22, 0.1), 0.2, 0.18, DARK, Mat.Wood, false)
	for _, y in { 0.65, 2.16 } do fer(m, "Gond", V(0.43, 0.22, 0.14), V(-1.82, y, 0.14)) end
	fer(m, "Loquet", V(0.48, 0.12, 0.15), V(1.81, 1.42, 0.15))
end

-- Cinq rangs de couverture chevauchants par versant, raccordés à la panne faîtière.
local function couverture(m, w, d, gouttiere, montee, c, chaume, centre)
	local pos = centre or Vector3.zero
	local demi = d / 2 - 0.114
	local inclinaison = math.atan(montee / demi)
	local longueur = math.sqrt(demi ^ 2 + montee ^ 2)
	local ep = chaume and 0.34 or 0.23
	for _, s in { -1, 1 } do
		for i = 1, 5 do
			local t = (i - 0.5) / 5
			local cRang = c:Lerp(i % 2 == 0 and COLORS.BC or DARK, i % 2 == 0 and 0.16 or 0.12)
			piece(m, chaume and "Rang de chaume" or "Rang de bardeaux",
				V(w - (i % 3) * 0.018, ep, longueur / 5 + 0.08),
				pos + V(0, gouttiere + montee * (1 - t), s * demi * t), cRang,
				chaume and Mat.Grass or Mat.WoodPlanks, nil, CFrame.Angles(s * inclinaison, 0, 0))
		end
		bois(m, "Sablière", V(w - 0.27, 0.21, 0.31),
			pos + V(0, gouttiere - 0.02, s * (demi - 0.25)), DARK)
	end
	bois(m, "Faîtage", V(w, 0.24, 0.31), pos + V(0, gouttiere + montee - 0.03, 0), DARK)
end

local function charpente(m, w, d, h, hSocle, c, nbPoteaux, coffre)
	local x, z = w / 2 - 0.23, d / 2 - 0.23
	for _, s in { -1, 1 } do
		for i = 0, nbPoteaux - 1 do
			local zz = -z + 2 * z * i / (nbPoteaux - 1)
			pierre(m, "Dé de pierre", V(0.46, hSocle, 0.48), V(s * x, hSocle / 2, zz), STONE, Mat.Cobblestone)
			bois(m, "Poteau", V(0.35, h - hSocle + 0.16, 0.37), V(s * x, (h + hSocle) / 2, zz), DARK)
		end
		bois(m, "Sablière", V(0.34, 0.28, d), V(s * x, h - 0.1, 0), DARK)
		lames(m, "Bardage", V(0.22, h - hSocle - 0.24, d - 0.41),
			V(s * x, (h + hSocle - 0.21) / 2, 0), coffre and 4 or 5, "Y", c)
	end
	lames(m, "Dos", V(w - 0.43, h - hSocle + 0.13, 0.23), V(0, (h + hSocle) / 2, -z),
		coffre and 5 or 6, "X", c)
	for _, zz in { -z, z } do
		bois(m, "Entrait", V(w - 0.06, 0.28, 0.33), V(0, h - 0.11, zz), DARK)
	end
end

local function auge(m, c, abreuvoir, centre, taille)
	local s = taille or 1
	local at = centre or Vector3.zero
	local function p(x, y, z) return at + V(x, y, z) * s end
	local function v(x, y, z) return V(x, y, z) * s end
	for _, x in { -1.38, 1.38 } do bois(m, "Patin", v(0.28, 0.4, 1.22), p(x, 0.2, 0), DARK) end
	lames(m, "Fond", v(3.31, 0.23, 1.15), p(0, 0.46, 0), 3, "Z", c)
	for _, z in { -0.53, 0.53 } do
		bois(m, "Paroi", v(3.38, 0.63, 0.18), p(0, 0.74, z), c, false, CFrame.Angles(z * 0.44, 0, 0))
		bois(m, "Rebord", v(3.42, 0.14, 0.19), p(0, 1.02, z * 1.13), DARK)
	end
	for _, x in { -1.61, 1.61 } do
		bois(m, "Joue", v(0.17, 0.55, 1.23), p(x, 0.73, 0), WOOD)
		rivet(m, p(x, 0.84, 0.62), 0.10 * s)
	end
	if abreuvoir then
		verre(m, "Eau", v(3.08, 0.065, 1.01), p(0, 0.82, 0), EAU)
	else
		for i = 1, 5 do
			boule(m, "Foin", v(0.76, 0.33 + i % 3 * 0.07, 0.8),
				p((i - 3) * 0.53, 0.86, i % 2 * 0.10), COLORS.Y:Lerp(COLORS.BC, i % 3 * 0.16), Mat.Grass)
		end
	end
end

ARCH.cabane = function(m, c)
	local cheval, mouton = m.Name == "Cat_horse_stable", m.Name == "Cat_sheepfold"
	local h = cheval and 4.47 or mouton and 3.75 or 4.03
	lames(m, "Plancher", V(7.97, 0.29, 7.97), V(0, 0.145, 0), 3, "X", DARK)
	charpente(m, 8, 8, h, 0.54, c, 2, true)
	for _, x in { -3.65, 3.65 } do
		pierre(m, "Soubassement", V(0.56, 0.57, 7.52), V(x, 0.29, 0), STONE, Mat.Cobblestone)
	end
	pierre(m, "Soubassement", V(7.56, 0.57, 0.58), V(0, 0.29, -3.62), STONE, Mat.Cobblestone)
	couverture(m, 8.58, 8.83, h, cheval and 2.16 or mouton and 1.83 or 2.16,
		cheval and Color3.fromRGB(123, 79, 55) or COLORS.Y, not cheval)
	if cheval then
		bois(m, "Montant central", V(0.38, h, 0.42), V(0, h / 2, 3.7), DARK)
		for _, y in { 0.57, 1.16, 1.76 } do
			bois(m, "Séparation des stalles", V(0.25, 0.26, 6.68), V(0, y, 0.39), WOOD)
		end
		for _, x in { -2.01, 2.01 } do
			piece(m, "Litière", V(2.9, 0.19, 5.06), V(x, 0.35, -0.62), COLORS.Y, Mat.Grass, nil, nil, true)
		end
		anneau(m, "Anneau d’attache", V(0.16, 2.0, 3.88), 0.16, 6, 0.053, IRON, Mat.Metal, "XY")
	else
		for _, s in { -1, 1 } do
			local x = s * (mouton and 2.67 or 2.9)
			lames(m, "Allège", V(mouton and 2.57 or 1.74, mouton and 1.83 or 1.35, 0.26),
				V(x, mouton and 1.15 or 0.91, 3.68), 3, "Y", c)
			lien(m, "Jambe de force", V(s * 3.77, h - 1.08, 3.69), V(s * 2.42, h - 0.12, 3.69),
				0.22, 0.26, DARK, Mat.Wood, false)
		end
		piece(m, "Litière", V(6.05, 0.23, mouton and 5.53 or 4.3), V(0, 0.38, -0.54), COLORS.Y, Mat.Grass, nil, nil, true)
		if mouton then
			bois(m, "Bat-flanc", V(2.61, 0.29, 0.23), V(-2.55, 2.13, 3.68), DARK)
			bois(m, "Bat-flanc", V(2.61, 0.29, 0.23), V(2.55, 2.13, 3.68), DARK)
		else
			bois(m, "Mangeoire", V(3.2, 0.37, 0.95), V(0, 0.49, -3.03), DARK)
			bois(m, "Rebord", V(3.22, 0.22, 0.16), V(0, 0.68, -2.57), c)
			boule(m, "Foin", V(2.83, 0.28, 0.73), V(0, 0.65, -3.03), COLORS.Y, Mat.Grass)
		end
	end
end

ARCH.grange = function(m)
	local c = Color3.fromRGB(127, 75, 59)
	lames(m, "Plancher", V(11.98, 0.25, 9.98), V(0, 0.125, 0), 3, "X", DARK)
	charpente(m, 12, 10, 6, 0.68, c, 2, true)
	assises(m, 0.34, 0.696, 11.91, 0.57, -4.71, STONE, { 0.45, 0.55 })
	for _, s in { -1, 1 } do
		pierre(m, "Soubassement", V(0.53, 0.68, 9.75), V(s * 5.73, 0.34, 0), STONE, Mat.Cobblestone)
		lames(m, "Bardage de façade", V(3.94, 5.33, 0.25), V(s * 3.95, 3.29, 4.75), 3, "X", c)
		bois(m, "Jambage", V(0.34, 6.03, 0.36), V(s * 2.01, 3.015, 4.72), DARK)
		lien(m, "Écharpe", V(s * 2.13, 1.24, 4.84), V(s * 5.52, 4.91, 4.84), 0.27, 0.23, DARK, Mat.Wood, true)
	end
	bois(m, "Linteau", V(4.31, 0.31, 0.48), V(0, 5.07, 4.72), DARK)
	lames(m, "Panneau du fenil", V(4.18, 0.91, 0.29), V(0, 5.57, 4.72), 2, "X", c)
	fer(m, "Grille du fenil", V(0.81, 0.42, 0.09), V(0, 5.63, 4.9))
	couverture(m, 12.58, 10.82, 6.06, 3.21, COLORS.Y, true)
end

ARCH.grenier = function(m, c)
	for _, x in { -2.14, 2.14 } do
		for _, z in { -2.14, 2.14 } do
			pierre(m, "Plinthe", V(0.73, 0.25, 0.73), V(x, 0.125, z), STONE, Mat.Cobblestone)
			pierre(m, "Pilotis", V(0.58, 2.05, 0.56), V(x, 1.23, z), COLORS.PC, Mat.Cobblestone)
			cyl(m, "Pierre anti-rongeurs", 0.95, 0.22, V(x, 2.33, z), STONE, Mat.Slate)
		end
	end
	lames(m, "Plancher", V(5.56, 0.24, 5.53), V(0, 2.49, 0), 4, "X", DARK)
	for _, z in { -2.66, 2.66 } do
		lames(m, "Bardage", V(5.56, 3.75, 0.22), V(0, 4.45, z), 4, "X", c)
		bois(m, "Entrait", V(5.6, 0.29, 0.30), V(0, 6.3, z), DARK)
	end
	for _, x in { -2.68, 2.68 } do
		lames(m, "Bardage", V(0.23, 3.8, 5.3), V(x, 4.45, 0), 4, "Y", c)
		for _, z in { -2.57, 2.57 } do bois(m, "Colombage", V(0.22, 3.72, 0.27), V(x, 4.46, z), DARK) end
	end
	for _, x in { -0.47, 0.47 } do
		lien(m, "Échelle", V(x, 0.15, 2.89), V(x, 2.76, 2.72), 0.13, 0.14, DARK, Mat.Wood, false)
	end
	for i = 0, 3 do
		bois(m, "Échelon", V(1.01, 0.11, 0.13), V(0, 0.39 + i * 0.56, 2.89 - i * 0.041), WOOD)
	end
	bois(m, "Portillon", V(1.08, 1.7, 0.16), V(0, 3.45, 2.79), DARK)
	fer(m, "Pentures", V(0.72, 0.14, 0.08), V(0, 3.74, 2.89))
	couverture(m, 6.18, 6.18, 6.41, 1.91, Color3.fromRGB(147, 87, 59), false)
end

ARCH.poulailler = function(m, c)
	pieds(m, 3.8, 2.85, 0.82, 0.24)
	lames(m, "Plancher", V(3.98, 0.22, 2.97), V(0, 0.86, 0), 4, "X", DARK)
	for _, x in { -1.88, 1.88 } do lames(m, "Bardage", V(0.23, 2.29, 2.77), V(x, 2.1, 0), 4, "Y", c) end
	lames(m, "Dos", V(3.97, 2.29, 0.22), V(0, 2.11, -1.36), 5, "X", c)
	lames(m, "Façade", V(2.91, 2.27, 0.22), V(-0.53, 2.1, 1.35), 5, "X", c)
	bois(m, "Linteau", V(3.9, 0.43, 0.29), V(0, 2.96, 1.35), DARK)
	bois(m, "Montant", V(0.19, 2.13, 0.23), V(1.84, 2.0, 1.37), DARK)
	lien(m, "Rampe", V(1.34, 0.13, 3.05), V(1.34, 0.99, 1.40), 0.76, 0.16, c, Mat.WoodPlanks, false)
	for i = 0, 4 do
		bois(m, "Tasseau", V(0.75, 0.095, 0.10), V(1.34, 0.30 + i * 0.16, 2.87 - i * 0.31), DARK)
	end
	toile(m, "Litière", V(1.06, 0.12, 1.7), V(1.21, 1.02, 0.38), COLORS.Y)
	couverture(m, 4.38, 3.38, 3.22, 1.09, COLORS.Y, true)
end

ARCH.enclos = function(m, c)
	local porc = m.Name == "Cat_pigsty"
	for _, x in { -3.78, 3.78 } do
		for _, z in { -3.78, 3.78 } do
			bois(m, "Poteau", V(0.42, 2.18, 0.42), V(x, 1.09, z), DARK)
			piece(m, "Tête", V(0.42, 0.23, 0.42), V(x, 2.12, z), c, Mat.Wood, "coin")
		end
		for _, y in { 0.78, 1.59 } do
			bois(m, "Lisse", V(0.23, 0.24, 7.88), V(x, y + x / 100, 0), c)
		end
	end
	for _, y in { 0.78, 1.59 } do
		bois(m, "Lisse", V(7.9, 0.24, 0.25), V(0, y, -3.78), c)
		for _, x in { -2.67, 2.67 } do
			bois(m, "Lisse", V(2.59, 0.24, 0.25), V(x, y, 3.78), c)
			rivet(m, V(x / 2, y, 3.93), 0.1)
		end
	end
	for _, x in { -1.43, 1.43 } do bois(m, "Potelet", V(0.33, 1.94, 0.33), V(x, 0.97, 3.78), DARK) end
	if porc then
		piece(m, "Souille", V(3.39, 0.09, 2.43), V(0.9, 0.045, -0.36), Color3.fromRGB(104, 76, 56), Mat.Ground, "boule", nil, true)
		for _, x in { -3.4, 0.12 } do
			bois(m, "Poteau d’abri", V(0.35, 2.34, 0.37), V(x, 1.17, -1.43), DARK)
			bois(m, "Lisse de toit", V(0.27, 0.24, 2.32), V(x, 2.19, -2.51), DARK)
		end
		for i = 0, 3 do
			piece(m, "Chaume", V(4.07, 0.22, 0.73), V(-1.66, 2.54 - i * 0.11, -3.4 + i * 0.62),
				COLORS.Y:Lerp(DARK, i * 0.055), Mat.Grass, nil, CFrame.Angles(0.18, 0, 0))
		end
		auge(m, c, false, V(1.99, 0, -3.24), 0.65)
	else
		bois(m, "Barre amovible", V(2.84, 0.19, 0.14), V(0, 1.43, 3.82), COLORS.BC)
		for _, x in { -1.34, 1.34 } do fer(m, "Verrou", V(0.27, 0.3, 0.20), V(x, 1.43, 3.91)) end
	end
end

ARCH.mangeoire = function(m, c) auge(m, c, false) end
ARCH.abreuvoir = function(m, c) auge(m, c, true) end

ARCH.ratelier = function(m, c)
	for _, x in { -1.71, 1.71 } do
		bois(m, "Patin", V(0.33, 0.2, 1.11), V(x, 0.1, 0.18), DARK)
		bois(m, "Montant", V(0.26, 3.14, 0.28), V(x, 1.59, -0.18), DARK)
		lien(m, "Jambe de force", V(x, 0.15, 0.53), V(x, 1.19, 0.57), 0.16, 0.16, DARK, Mat.Wood, false)
	end
	for _, z in { -0.18, 0.6 } do bois(m, "Traverse", V(3.59, 0.23, 0.23), V(0, z < 0 and 2.91 or 1.27, z), c) end
	for x = -1.48, 1.49, 0.42 do
		lien(m, "Barreau", V(x, 1.27, 0.61), V(x, 2.92, -0.14), 0.12, 0.12, c, Mat.Wood, false)
	end
	bois(m, "Fond", V(3.44, 0.19, 0.69), V(0, 1.28, 0.39), DARK)
	for i = 0, 4 do
		boule(m, "Touffe de foin", V(0.79, 1.02 + i % 3 * 0.16, 0.68), V((i - 2) * 0.58, 1.85, 0.36),
			COLORS.Y:Lerp(COLORS.BC, i % 3 * 0.17), Mat.Grass)
	end
end


local function rayons(m, centre, rayon, largeur, jantes, pales, c)
	local function point(a, r, x)
		return centre + V(x, r * math.cos(a), r * math.sin(a))
	end
	for _, x in jantes do
		for i = 0, pales - 1 do
			local a, b = i * TAU / pales, (i + 1) * TAU / pales
			lien(m, "Jante", point(a, rayon, x), point(b, rayon, x), largeur, largeur, teinte(c, i), Mat.Wood, true)
		end
	end
	if #jantes == 1 then
		for i = 0, 1 do
			local a = i * TAU / 6
			lien(m, "Rayon", point(a, -rayon, 0), point(a, rayon, 0), largeur * 0.9, largeur * 0.78, c, Mat.Wood, true)
		end
	else
		for i = 0, 7 do
			local a = i * TAU / 8
			lien(m, "Rayon", point(a, 0.05, 0), point(a, rayon, 0), largeur * 0.76, largeur * 0.67, c, Mat.Wood, true)
		end
		cyl(m, "Moyeu", largeur * 2.5, largeur * 2.62, centre, IRON, Mat.Metal, CFrame.identity, true)
	end
end

ARCH.roue = function(m, c)
	local centre = V(0, 3.51, 0)
	rayons(m, centre, 3.27, 0.34, { -0.31, 0.31 }, 12, c)
	for i = 0, 11 do
		local a = (i + 0.5) * TAU / 12
		bois(m, "Aube", V(1.02, 0.48, 0.2), centre + V(0, math.cos(a) * 3.19, math.sin(a) * 3.19),
			teinte(c, i + 1), true, CFrame.Angles(a, 0, 0))
	end
	for _, x in { -0.98, 0.98 } do
		pierre(m, "Dé de pierre", V(0.65, 0.42, 1.08), V(x, 0.21, 0), STONE, Mat.Cobblestone)
		bois(m, "Poteau", V(0.49, 3.39, 0.55), V(x, 2.00, 0), DARK)
		fer(m, "Palier", V(0.5, 0.22, 0.59), V(x, 3.53, 0))
		for _, z in { -1.0, 1.0 } do
			lien(m, "Contrefiche", V(x, 0.22, z), V(x, 2.21, 0.04 * z), 0.29, 0.30, WOOD, Mat.Wood, false)
		end
	end
	cyl(m, "Essieu", 0.35, 2.59, centre, DARK, Mat.Wood, CFrame.identity)
end

ARCH.treuil = function(m, c)
	for _, x in { -1.3, 1.3 } do
		bois(m, "Patin", V(0.42, 0.24, 1.08), V(x, 0.12, 0), DARK)
		bois(m, "Support", V(0.36, 2.89, 0.42), V(x, 1.58, 0), c)
		for _, z in { -0.39, 0.39 } do
			lien(m, "Contrefiche", V(x, 0.21, z), V(x, 1.48, 0), 0.17, 0.17, DARK, Mat.Wood, false)
		end
	end
	bois(m, "Traverse", V(2.94, 0.23, 0.25), V(0, 0.35, 0), DARK)
	cyl(m, "Axe", 0.41, 3.0, V(0, 2.53, 0), IRON, Mat.Metal, CFrame.identity)
	for _, x in { -1.09, 1.09 } do cyl(m, "Joue", 1.01, 0.16, V(x, 2.53, 0), c, Mat.Wood, CFrame.identity) end
	for i = -5, 5 do
		cyl(m, "Tour de corde", 0.88 + i % 3 * 0.025, 0.19, V(i * 0.191, 2.53, 0), CLOTH:Lerp(DARK, 0.21), Mat.Fabric,
			CFrame.identity, true)
	end
	lien(m, "Manivelle", V(1.46, 2.53, 0), V(1.49, 2.11, 0.26), 0.16, 0.14, IRON, Mat.Metal, true)
	cyl(m, "Poignée", 0.16, 0.25, V(1.47, 2.1, 0.29), c, Mat.Wood, CFrame.identity, true)
end

ARCH.grue = function(m, c)
	lames(m, "Plateforme", V(3.96, 0.45, 3.96), V(0, 0.225, 0), 5, "X", DARK)
	bois(m, "Mât", V(0.79, 9.53, 0.76), V(0, 5.17, 0), c)
	bois(m, "Flèche", V(0.61, 0.51, 7.95), V(0, 9.57, 3), c)
	for _, x in { -1.46, 1.46 } do
		lien(m, "Contrefiche", V(x, 0.45, 0.28), V(0, 2.98, 0), 0.23, 0.23, DARK, Mat.Wood, false)
	end
	lien(m, "Jambe de force", V(0, 6.45, 0.24), V(0, 9.38, 4.03), 0.35, 0.35, DARK, Mat.Wood, false)
	for _, y in { 1.02, 6.75, 9.54 } do fer(m, "Bride", V(0.86, 0.22, 0.82), V(0, y, 0)) end
	cyl(m, "Poulie", 0.74, 0.59, V(0, 9.47, 6.51), DARK, Mat.Wood, CFrame.identity)
	cyl(m, "Treuil", 0.85, 1.06, V(0, 1.41, 0.48), DARK, Mat.Wood, CFrame.identity)
	lien(m, "Corde", V(0, 1.42, 0.85), V(0, 9.62, 0.39), 0.10, 0.10, CLOTH, Mat.Fabric, true)
	lien(m, "Corde", V(0, 9.79, 0.23), V(0, 9.79, 6.53), 0.10, 0.10, CLOTH, Mat.Fabric, true)
	lien(m, "Corde", V(0, 9.54, 6.68), V(0, 4.69, 6.68), 0.10, 0.10, CLOTH, Mat.Fabric, true)
	for i = 0, 4 do
		local a, b = i * math.pi / 4, (i + 1) * math.pi / 4
		local function crochet(angle) return V(0, 4.66 - math.sin(angle) * 0.40, 6.93 - math.cos(angle) * 0.25) end
		lien(m, "Crochet", crochet(a), crochet(b), 0.14, 0.15, IRON, Mat.Metal, true)
	end
end

ARCH.levier = function(m, c)
	pierre(m, "Socle", V(1.20, 0.3, 1.2), V(0, 0.15, 0), STONE, Mat.Cobblestone)
	pierre(m, "Dé", V(0.91, 0.28, 0.91), V(0, 0.40, 0), COLORS.PC)
	fer(m, "Platine", V(0.81, 0.12, 0.60), V(0, 0.54, 0))
	for _, x in { -0.26, 0.26 } do
		fer(m, "Palier", V(0.16, 0.39, 0.48), V(x, 0.73, 0))
		rivet(m, V(x, 0.92, 0.15), 0.12, COLORS.O)
	end
	cyl(m, "Axe", 0.25, 0.7, V(0, 0.77, 0), IRON, Mat.Metal, CFrame.identity, true)
	lien(m, "Levier", V(0, 0.77, 0), V(0, 2.16, 0.51), 0.13, 0.14, c, Mat.Metal, true)
	boule(m, "Pommeau", V(0.35, 0.34, 0.34), V(0, 2.19, 0.53), COLORS.R, Mat.Wood)
end

ARCH.pompe = function(m, c)
	assises(m, 0.193, 0.41, 2.38, 2.36, 0, STONE, { 0.27, 0.42, 0.31 })
	pierre(m, "Couronnement", V(2.3, 0.20, 2.27), V(0, 0.465, 0), COLORS.PC)
	pierre(m, "Fond d’auge", V(1.43, 0.20, 1.41), V(0, 0.637, -0.74), STONE, Mat.Cobblestone)
	for _, x in { -0.60, 0.60 } do
		pierre(m, "Joue de l’auge", V(0.23, 0.36, 1.42), V(x, 0.84, -0.74), COLORS.PC)
	end
	for _, z in { -1.34, -0.14 } do
		pierre(m, "Rebord de l’auge", V(1.09, 0.37, 0.23), V(0, 0.845, z), STONE:Lerp(COLORS.PC, 0.57))
	end
	verre(m, "Eau de l’auge", V(1.01, 0.06, 1.01), V(0, 0.812, -0.74), EAU)

	local zFut = 0.38
	cyl(m, "Sabot de fonte", 1.06, 0.22, V(0, 0.67, zFut), IRON, Mat.Metal)
	cyl(m, "Fût en bois", 0.85, 1.64, V(0, 1.56, zFut), DARK, Mat.Wood)
	for i = 0, 9 do
		local a = i * TAU / 10
		bois(m, "Douelle", V(0.27, 1.60, 0.158), V(math.sin(a) * 0.404, 1.56, zFut + math.cos(a) * 0.404),
			teinte(WOOD, i), true, CFrame.Angles(0, a, 0))
	end
	for _, y in { 0.84, 1.39, 2.26 } do
		cyl(m, "Collier de fer", 1.006, 0.13, V(0, y, zFut), c, Mat.Metal, nil, true)
		rivet(m, V(0.502, y, zFut), 0.105, COLORS.P)
	end
	cyl(m, "Chapeau de fonte", 0.96, 0.21, V(0, 2.45, zFut), c, Mat.Metal)

	local depart, col, bout = V(0, 1.94, 0.0), V(0, 1.94, -1.19), V(0, 1.66, -1.271)
	cyl(m, "Bride du bec", 0.46, 0.20, V(0, 1.94, -0.084), c, Mat.Metal, FACE, true)
	cyl(m, "Bec verseur", 0.28, 1.21, (depart + col) / 2, c, Mat.Metal, FACE, true)
	lien(m, "Coude du bec", col, bout, 0.249, 0.24, c, Mat.Metal, true)
	cyl(m, "Lèvre du bec", 0.32, 0.103, bout, IRON, Mat.Metal, nil, true)
	cyl(m, "Ouverture du bec", 0.224, 0.023, bout - V(0, 0.054, 0), COLORS.N, Mat.Metal, nil, true)

	local axe = V(0, 2.755, zFut)
	fer(m, "Fourche d’articulation", V(0.34, 0.38, 0.31), V(0, 2.64, zFut))
	cyl(m, "Axe de fer", 0.22, 0.51, axe, COLORS.P, Mat.Metal, CFrame.identity, true)
	local tete, manche = V(0, 2.60, -0.03), V(0, 3.02, 1.51)
	lien(m, "Balancier", tete, axe, 0.18, 0.22, IRON, Mat.Metal, true)
	lien(m, "Balancier en bois", axe, manche, 0.21, 0.22, WOOD, Mat.Wood, true)
	lien(m, "Poignée", manche, V(0, 3.071, 1.75), 0.24, 0.235, COLORS.BC, Mat.Wood, true)
	lien(m, "Tige de piston", V(0, 2.33, 0.023), tete, 0.136, 0.14, c, Mat.Metal, true)
end

ARCH.canal = function(m, c)
	pierre(m, "Radier", V(4, 0.2, 2.45), V(0, 0.1, 0), c, Mat.Cobblestone)
	for _, z in { -0.97, 0.97 } do
		assises(m, 0.33, 0.43, 4, 0.51, z, c, { 0.26, 0.18, 0.30, 0.26 })
		assises(m, 0.72, 0.44, 4, 0.47, z, COLORS.PC, { 0.31, 0.26, 0.22, 0.21 })
	end
	verre(m, "Eau", V(3.98, 0.07, 1.59), V(0, 0.42, 0), EAU)
	for _, x in { -0.97, 0.78 } do verre(m, "Remous", V(0.41, 0.026, 0.039), V(x, 0.456, 0.28), VITRE) end
end

ARCH.herse = function(m, c)
	for i = -3, 3 do
		local x = i * 0.60
		piece(m, "Barreau", V(0.19, 4.75, 0.19), V(x, 2.73, 0), c, Mat.Metal)
		piece(m, "Dent", V(0.22, 0.39, 0.2), V(x, 0.195, 0), IRON, Mat.Metal, "coin", CFrame.Angles(0, 0, math.pi))
		for _, y in { 1.12, 3.16, 4.51 } do rivet(m, V(x, y, 0.14), 0.105, COLORS.P) end
	end
	for _, y in { 1.12, 3.16, 4.51 } do
		piece(m, "Longeron", V(3.98, 0.21, 0.18), V(0, y, 0.05), c, Mat.Metal)
	end
end

ARCH.pontlevis = function(m, c)
	lames(m, "Tablier", V(4.02, 0.38, 7.97), V(0, 0.19, 0), 12, "Z", c)
	for _, x in { -1.87, 1.87 } do
		bois(m, "Longeron", V(0.33, 0.21, 7.99), V(x, 0.41, 0), DARK)
		for _, z in { -3.44, -1.77, 1.67, 3.50 } do rivet(m, V(x, 0.56, z), 0.12) end
		anneau(m, "Anneau de chaîne", V(x, 0.55, 3.61), 0.16, 6, 0.071, IRON, Mat.Metal, "YZ")
	end
	for _, z in { -3.86, 3.86 } do fer(m, "Sabot", V(4.09, 0.17, 0.24), V(0, 0.24, z)) end
end

ARCH.echelle = function(m, c)
	local corde = m.Name == "Cat_rope_ladder"
	local mat, ep = corde and Mat.Fabric or Mat.Wood, corde and 0.13 or 0.235
	for _, x in { -0.695, 0.695 } do
		if corde then
			for i = 0, 7 do
				local a = V(x + math.sin(i) * 0.048, i * 0.99 + 0.08, math.sin(i * 0.72) * 0.035)
				local b = V(x + math.sin(i + 1) * 0.048, (i + 1) * 0.99 + 0.08, math.sin((i + 1) * 0.72) * 0.035)
				lien(m, "Corde", a, b, ep, ep, c, mat, true)
			end
			for _, y in { 0.07, 7.83 } do
				boule(m, "Nœud", V(0.22, 0.14, 0.19), V(x, y, 0), c, mat)
			end
		else
			bois(m, "Montant", V(ep, 8, 0.24), V(x, 4, 0), DARK)
			for _, y in { 0.16, 7.79 } do fer(m, "Sabot", V(0.247, 0.28, 0.25), V(x, y, 0)) end
		end
	end
	for i = 0, 9 do
		local y = 0.6 + i * 0.76
		bois(m, "Échelon", V(1.54, 0.14, 0.18), V(0, y, 0.016), corde and WOOD or teinte(c, i))
		if not corde or i % 2 == 0 then
			for _, x in { -0.69, 0.69 } do
				if corde then
					boule(m, "Ligature", V(0.21, 0.20, 0.18), V(x, y, 0.048), c, mat)
				else
					rivet(m, V(x, y, 0.119), 0.079)
				end
			end
		end
	end
	local t = Instance.new("TrussPart")
	t.Name = "Appui d’escalade"
	t.Size, t.CFrame = V(2, 8, 2), CFrame.new(0, 4, 0)
	t.Transparency, t.Anchored = 1, true
	t.Parent = m
end

ARCH.arche = function(m, c)
	local enBois = m.Name == "Cat_wood_arch"
	if enBois then
		for _, x in { -2.41, 2.41 } do
			pierre(m, "Dé de pierre", V(1.17, 0.62, 1.18), V(x, 0.31, 0), STONE, Mat.Cobblestone)
			bois(m, "Poteau", V(0.75, 6.29, 0.86), V(x, 3.67, 0), c)
			lien(m, "Aisselier", V(x, 4.94, 0), V(x * 0.31, 6.88, 0), 0.54, 0.56, DARK, Mat.Wood, false)
			fer(m, "Bride", V(0.8, 0.23, 0.89), V(x, 1.02, 0))
			rivet(m, V(x, 5.48, 0.47), 0.16)
		end
		lames(m, "Linteau", V(5.96, 0.77, 1.08), V(0, 7.04, 0), 3, "Y", c)
		bois(m, "Chapeau", V(5.99, 0.29, 1.19), V(0, 7.56, 0), DARK)
	else
		for _, x in { -2.42, 2.42 } do
			pierre(m, "Plinthe", V(1.15, 0.43, 1.19), V(x, 0.215, 0), STONE, Mat.Cobblestone)
			for i = 0, 6 do
				pierre(m, "Jambage", V(0.99 + i % 3 * 0.055, 0.77, 1.12), V(x, 0.78 + i * 0.754, 0), c:Lerp(STONE, i % 3 * 0.22))
			end
		end
		for i = 0, 10 do
			local a = i * math.pi / 10
			pierre(m, i == 5 and "Clé" or "Claveau", V(0.80, i == 5 and 0.93 or 0.82, 1.15),
				V(2.42 * math.cos(a), 5.51 + 2.01 * math.sin(a), 0), c:Lerp(STONE, i % 3 * 0.19),
				Mat.Slate, CFrame.Angles(0, 0, a - math.pi / 2))
		end
	end
end

ARCH.porte = function(m)
	local c = Color3.fromRGB(132, 61, 52)
	lames(m, "Ais", V(3.59, 6, 0.34), V(0, 3, 0), 7, "X", c)
	for _, y in { 0.35, 1.1, 4.93, 5.71 } do
		bois(m, "Traverse", V(3.59, 0.23, 0.19), V(0, y, 0.13), DARK)
	end
	lien(m, "Écharpe", V(-1.49, 1.10, 0.16), V(1.49, 4.93, 0.16), 0.29, 0.17, DARK, Mat.Wood, true)
	for _, y in { 1.1, 4.93 } do
		fer(m, "Pentures", V(1.01, 0.17, 0.07), V(-1.22, y, 0.225))
		for _, x in { -1.61, -0.96 } do rivet(m, V(x, y, 0.265), 0.11) end
	end
	fer(m, "Platine", V(0.25, 0.46, 0.08), V(1.22, 2.96, 0.18))
	anneau(m, "Anneau", V(1.22, 2.9, 0.215), 0.13, 6, 0.048, IRON, Mat.Metal, "XY")
end

ARCH.portedouble = function(m, c)
	local forte = m.Name == "Cat_castle_door"
	local planche = forte and DARK or c
	for _, s in { -1, 1 } do
		lames(m, "Ais du battant", V(2.42, 7, 0.47), V(s * 1.249, 3.5, 0), forte and 4 or 5, "X", planche)
		for _, x in { 0.20, 2.34 } do bois(m, "Montant", V(0.18, 7, 0.18), V(s * x, 3.5, -0.18), DARK) end
		for _, y in { 0.81, 3.57, 6.20 } do
			local mat, col = forte and Mat.Metal or Mat.Wood, forte and IRON or DARK
			piece(m, "Traverse", V(2.42, forte and 0.36 or 0.23, 0.16), V(s * 1.25, y, 0.225), col, mat, nil, nil, true)
			fer(m, "Gond", V(0.36, 0.23, 0.15), V(s * 2.29, y, 0.25))
			for _, x in { 0.36, 1.28, 2.20 } do rivet(m, V(s * x, y, 0.31), forte and 0.15 or 0.105) end
		end
		fer(m, "Platine", V(0.26, 0.49, 0.12), V(s * 0.32, 3.11, 0.23))
		anneau(m, "Anneau", V(s * 0.32, 3.05, 0.287), 0.15, 6, 0.053, COLORS.O, Mat.Metal, "XY")
	end
end

ARCH.trappe = function(m, c)
	lames(m, "Ais", V(2.98, 0.23, 2.98), V(0, 0.115, 0), 6, "X", c)
	for _, z in { -1.23, 1.23 } do bois(m, "Traverse", V(2.98, 0.13, 0.29), V(0, 0.245, z), DARK) end
	for _, x in { -0.94, 0.94 } do
		fer(m, "Pentures", V(0.31, 0.071, 0.73), V(x, 0.29, -1.10))
		cyl(m, "Gond", 0.19, 0.41, V(x, 0.258, -1.41), IRON, Mat.Metal, CFrame.identity, true)
		rivet(m, V(x, 0.333, -0.92), 0.09)
	end
	fer(m, "Platine", V(0.46, 0.075, 0.38), V(0, 0.24, 0.86))
	anneau(m, "Anneau de tirage", V(0, 0.326, 0.89), 0.16, 6, 0.052, IRON, Mat.Metal, "XZ")
end

ARCH.volet = function(m, c)
	for _, s in { -1, 1 } do
		montant(m, s * 1.31, 4.31, 0)
		lames(m, "Ais", V(1.18, 2.33, 0.15), V(s * 0.69, 3.0, 0.014), 4, "X", c)
		for _, y in { 2.16, 3.86 } do
			bois(m, "Traverse", V(1.18, 0.16, 0.15), V(s * 0.69, y, 0.093), DARK)
			fer(m, "Pentures", V(0.45, 0.14, 0.08), V(s * 1.12, y, 0.172))
		end
		rivet(m, V(s * 0.28, 3.0, 0.12), 0.12, COLORS.O)
	end
	for _, y in { 1.82, 4.20 } do bois(m, "Cadre", V(2.94, 0.22, 0.27), V(0, y, 0), DARK) end
end

local function batiFenetre(m, w, appui, naissance, z, c)
	for _, s in { -1, 1 } do
		montant(m, s * (w / 2 - 0.15), naissance + 0.21, z)
		pierre(m, "Piédroit", V(0.24, naissance - appui, 0.32),
			V(s * (w / 2 - 0.14), (naissance + appui) / 2, z), c)
	end
	pierre(m, "Appui", V(w, 0.25, 0.46), V(0, appui, z), c)
end

local function arcFenetre(m, largeur, y, hauteur, c)
	for i = 0, 8 do
		local a = i * math.pi / 8
		pierre(m, i == 4 and "Clé" or "Claveau", V(0.32, 0.34, 0.32),
			V(math.cos(a) * largeur / 2, y + math.sin(a) * hauteur, 0), c:Lerp(STONE, i % 3 * 0.18),
			Mat.Slate, CFrame.Angles(0, 0, a - math.pi / 2))
	end
end

ARCH.fenetre = function(m, c)
	batiFenetre(m, 2.78, 1.49, 3.90, 0, c)
	local v = verre(m, "Vitrage", V(2.30, 2.45, 0.13), V(0, 2.76, 0), VITRE)
	v.CanCollide, v.CanQuery = true, true
	for i = -2, 2 do
		local h = 0.70 * math.sqrt(1 - (i / 3) ^ 2)
		verre(m, "Verre taillé", V(0.46, h + 0.04, 0.13), V(i * 0.46, 3.89 + h / 2, 0), VITRE)
	end
	arcFenetre(m, 2.45, 3.89, 0.88, c)
	bois(m, "Croisillon", V(0.115, 2.97, 0.16), V(0, 3.09, 0), DARK)
	bois(m, "Traverse", V(2.29, 0.13, 0.16), V(0, 2.77, 0), DARK)
end

ARCH.fenetreronde = function(m, c)
	for _, s in { -1, 1 } do
		montant(m, s * 0.89, 2.12, 0)
		lien(m, "Console", V(s * 0.89, 1.95, 0), V(s * 0.57, 2.08, 0), 0.17, 0.22, DARK, Mat.Wood, false)
	end
	anneau(m, "Bâti", V(0, 3.0, 0), 1.28, 12, 0.22, c, Mat.Wood, "XY")
	anneau(m, "Parclose", V(0, 3.0, 0.115), 1.20, 12, 0.075, DARK, Mat.Wood, "XY")
	local v = verre(m, "Verre", V(0.14, 2.43, 2.43), V(0, 3, 0), VITRE, "cylindre", FACE)
	v.CanCollide, v.CanQuery = true, true
	for _, a in { 0, math.pi / 2 } do
		bois(m, "Croisillon", V(2.44, 0.12, 0.19), V(0, 3, 0), DARK, true, CFrame.Angles(0, 0, a))
	end
	boule(m, "Rosette", V(0.32, 0.32, 0.22), V(0, 3, 0), COLORS.O, Mat.Metal)
end

ARCH.vitrail = function(m, c)
	batiFenetre(m, 2.58, 1.23, 4.08, 0, STONE)
	local cols = { COLORS.BL, c, COLORS.R, COLORS.O, COLORS.V }
	for i = -2, 2 do
		for j = 0, 4 do
			local verreCouleur = cols[(math.abs(i) + j) % #cols + 1]
			if i == 0 and j % 2 == 0 then verreCouleur = COLORS.O end
			verre(m, "Verre teinté", V(0.45, 0.55, 0.125), V(i * 0.447, 1.63 + j * 0.55, 0), verreCouleur)
		end
	end
	for i = -1, 1 do
		verre(m, "Verre du tympan", V(0.58, 0.49 - math.abs(i) * 0.10, 0.13), V(i * 0.57, 4.3, 0), i == 0 and COLORS.O or COLORS.BL)
	end
	arcFenetre(m, 2.30, 4.08, 0.72, COLORS.PC)
	for i = -2, 1 do fer(m, "Plomb", V(0.045, 2.79, 0.145), V((i + 0.5) * 0.447, 2.73, 0)) end
	for j = 0, 4 do fer(m, "Plomb", V(2.25, 0.045, 0.145), V(0, 1.355 + j * 0.55, 0)) end
	local doublure = verre(m, "Doublure", V(2.30, 2.85, 0.07), V(0, 2.74, -0.08), VITRE)
	doublure.Transparency, doublure.CanCollide, doublure.CanQuery = 0.92, true, true
end

ARCH.meurtriere = function(m, c)
	for _, s in { -1, 1 } do
		for i = 0, 5 do
			local w = 1.54 + i % 2 * 0.04
			pierre(m, "Jambage", V(w, 0.668, 0.92 - i % 3 * 0.047), V(s * (1.99 - w / 2), 0.334 + i * 0.66, 0),
				c:Lerp(COLORS.PC, i % 3 * 0.24), i % 2 == 0 and Mat.Slate or Mat.Cobblestone)
		end
	end
	pierre(m, "Appui", V(0.9, 1.17, 0.99), V(0, 0.585, 0), STONE, Mat.Cobblestone)
	pierre(m, "Linteau", V(0.91, 1.32, 0.98), V(0, 3.32, 0), COLORS.PC)
	for _, s in { -1, 1 } do
		piece(m, "Ébrasement", V(0.88, 1.56, 0.19), V(s * 0.48, 1.95, 0.1), c, Mat.Slate, "coin",
			CFrame.Angles(0, s * math.pi / 2, 0))
	end
end


ARCH.chariot = function(m, c)
	local marchand = m.Name == "Cat_merchant_cart"
	local planche = marchand and COLORS.BF or c
	lames(m, "Plancher", V(3.39, 0.30, 4.98), V(0, 1.61, 0), 3, "X", planche)
	for _, x in { -1.54, 1.54 } do
		lames(m, "Ridelle", V(0.22, 1.13, 4.96), V(x, 2.22, 0), 2, "Y", planche)
		bois(m, "Main courante", V(0.28, 0.18, 4.99), V(x, 2.83, 0), DARK)
	end
	lames(m, "Ridelle arrière", V(3.34, 1.16, 0.25), V(0, 2.24, -2.37), 2, "Y", planche)
	for _, z in { -1.59, 1.59 } do
		cyl(m, "Essieu", 0.29, 3.91, V(0, 1.097, z), DARK, Mat.Wood, CFrame.identity)
		bois(m, "Traverse d’essieu", V(3.31, 0.31, 0.34), V(0, 1.34, z), DARK)
		for _, x in { -1.89, 1.89 } do
			rayons(m, V(x, 1.097, z), 1.01, 0.17, { 0 }, 6, DARK)
		end
	end
	for _, x in { -0.59, 0.59 } do
		lien(m, "Brancard", V(x, 1.41, 1.43), V(x * 1.33, 1.29, 5.47), 0.22, 0.23, DARK, Mat.Wood, false)
	end
	if marchand then
		for _, x in { -1.4, 1.4 } do
			for _, z in { -1.86, 1.86 } do
				bois(m, "Arceau", V(0.17, 2.07, 0.17), V(x, 3.73, z), DARK)
			end
		end
		for i = -1, 1 do
			local x = i * 0.97
			toile(m, "Auvent rayé", V(1.02, 0.16, 3.94), V(x, 4.75 - math.abs(x) * 0.17, 0),
				i % 2 == 0 and COLORS.R or CLOTH, CFrame.Angles(0, 0, -x * 0.25))
		end
		for _, z in { -1.86, 1.86 } do
			bois(m, "Traverse d’auvent", V(2.84, 0.21, 0.18), V(0, 4.57, z), DARK)
		end
	else
		for _, x in { -1.51, 1.51 } do
			for _, z in { -2.3, 2.27 } do fer(m, "Cornière", V(0.28, 0.91, 0.22), V(x, 2.25, z)) end
		end
	end
end

ARCH.brouette = function(m, c)
	lames(m, "Fond", V(1.74, 0.19, 2.36), V(0, 0.97, 0), 4, "Z", c)
	for _, x in { -0.78, 0.78 } do
		bois(m, "Bord", V(0.21, 0.66, 2.37), V(x, 1.27, 0), c, false, CFrame.Angles(0, 0, -x * 0.27))
		lien(m, "Poignée", V(x * 0.82, 0.97, 0.91), V(x * 0.95, 1.16, -2.78), 0.19, 0.20, DARK, Mat.Wood, false)
		lien(m, "Fourche", V(x * 0.82, 0.97, 0.86), V(x * 0.31, 0.59, 1.41), 0.19, 0.22, DARK, Mat.Wood, false)
		cyl(m, "Sabot", 0.25, 0.17, V(x * 0.76, 0.085, -0.72), IRON, Mat.Metal)
		lien(m, "Béquille", V(x * 0.76, 0.13, -0.72), V(x * 0.87, 1.02, -0.47), 0.14, 0.17, DARK, Mat.Wood, false)
	end
	lames(m, "Joue", V(1.66, 0.59, 0.19), V(0, 1.23, 1.12), 3, "Y", c)
	bois(m, "Chant", V(1.79, 0.13, 0.2), V(0, 1.56, 1.13), DARK)
	rayons(m, V(0, 0.6, 1.39), 0.52, 0.15, { 0 }, 6, DARK)
	cyl(m, "Essieu", 0.19, 0.66, V(0, 0.60, 1.39), IRON, Mat.Metal, CFrame.identity)
end

ARCH.traineau = function(m, c)
	lames(m, "Plancher", V(2.39, 0.29, 3.92), V(0, 0.95, 0), 5, "Z", c)
	for _, x in { -1, 1 } do
		bois(m, "Patin", V(0.24, 0.24, 4.28), V(x, 0.12, 0.15), DARK)
		fer(m, "Semelle", V(0.225, 0.063, 4.20), V(x, 0.032, 0.15))
		lien(m, "Relevé", V(x, 0.12, 2.10), V(x, 0.61, 2.52), 0.22, 0.23, DARK, Mat.Wood, false)
		bois(m, "Longeron", V(0.25, 0.26, 3.88), V(x, 0.78, 0), DARK)
		for _, z in { -1.29, 1.3 } do
			lien(m, "Jambe", V(x, 0.18, z), V(x, 0.84, z * 0.80), 0.22, 0.22, c, Mat.Wood, false)
			rivet(m, V(x, 1.11, z), 0.12)
		end
	end
	lames(m, "Ridelle", V(2.36, 1.12, 0.24), V(0, 1.52, -1.85), 4, "X", c)
	bois(m, "Main courante", V(2.38, 0.16, 0.26), V(0, 2.02, -1.85), DARK)
end

ARCH.barque = function(m, c)
	local stations = { { -3.48, 0.69 }, { -2.74, 1.10 }, { -1.25, 1.44 },
		{ 1.33, 1.42 }, { 3.38, 0.87 }, { 5.39, 0.07 } }
	for i = 1, #stations - 1 do
		local z1, w1, z2, w2 = stations[i][1], stations[i][2], stations[i + 1][1], stations[i + 1][2]
		for _, s in { -1, 1 } do
			for bord = 0, 2 do
				local marge = 0.59 + bord * 0.183
				local y = 0.24 + bord * 0.35
				lien(m, "Virure", V(s * w1 * marge, y, z1), V(s * w2 * marge, y, z2),
					0.14, 0.43, teinte(c, bord + i), Mat.WoodPlanks, false)
			end
		end
	end
	lames(m, "Fond", V(1.78, 0.22, 6.31), V(0, 0.11, -0.04), 4, "X", DARK)
	bois(m, "Étrave", V(0.16, 1.15, 0.19), V(0, 0.60, 5.39), DARK)
	bois(m, "Tableau", V(1.33, 1.0, 0.2), V(0, 0.55, -3.45), c)
	for _, z in { -2.04, -0.09, 1.91 } do
		bois(m, "Banc", V(z < -1 and 2.32 or 2.65, 0.20, 0.47), V(0, 1.09, z), COLORS.BC)
	end
	lien(m, "Aviron", V(-0.99, 1.27, -2.14), V(0.6, 1.18, 1.3), 0.135, 0.12, DARK, Mat.Wood, true)
	bois(m, "Pale", V(0.35, 0.14, 0.82), V(0.68, 1.17, 1.54), c, true, CFrame.Angles(0, 0.42, 0))
end

ARCH.radeau = function(m, c)
	for i = -2, 2 do
		local d = 0.72 + math.abs(i) * 0.011
		cyl(m, "Rondin", d, 4.90 + i % 3 * 0.048, V(i * 0.784, d / 2, i % 2 * 0.037),
			teinte(c, i), Mat.Wood, FACE)
	end
	for _, z in { -1.58, 1.55 } do
		bois(m, "Traverse", V(3.94, 0.24, 0.27), V(0, 0.7, z), DARK)
		for i = -2, 2 do
			toile(m, "Ligature", V(0.23, 0.16, 0.42), V(i * 0.784, 0.77, z), CLOTH,
				CFrame.Angles(0, i % 2 == 0 and 0.16 or -0.16, 0))
		end
	end
end

ARCH.metier = function(m, c)
	for _, x in { -1.67, 1.67 } do
		bois(m, "Patin", V(0.42, 0.25, 2.96), V(x, 0.125, 0), DARK)
		bois(m, "Montant", V(0.29, 4.66, 0.32), V(x, 2.45, -1.06), c)
		bois(m, "Pied avant", V(0.31, 2.42, 0.3), V(x, 1.32, 1.05), c)
		bois(m, "Longeron", V(0.23, 0.28, 2.30), V(x, 2.36, 0), DARK)
		lien(m, "Écharpe", V(x, 0.36, 1.06), V(x, 2.37, -0.97), 0.16, 0.17, DARK, Mat.Wood, true)
	end
	local haut, bas = V(0, 4.65, -1.05), V(0, 2.35, 1.04)
	for _, centre in { haut, bas } do cyl(m, "Ensouple", 0.37, 3.62, centre, DARK, Mat.Wood, CFrame.identity) end
	for i = -7, 7 do
		local dx = V(i * 0.187, 0.10, 0)
		lien(m, "Fil de chaîne", haut + dx, bas + dx, 0.039, 0.045, CLOTH, Mat.Fabric, true)
	end
	local rot = CFrame.Angles(math.atan((haut.Y - bas.Y) / (bas.Z - haut.Z)), 0, 0)
	toile(m, "Étoffe en cours", V(2.71, 0.10, 1.65), V(0, 3.02, 0.56), COLORS.R, rot)
	toile(m, "Rayure", V(2.72, 0.11, 0.15), V(0, 2.80, 0.77), COLORS.O, rot)
	bois(m, "Navette", V(0.85, 0.12, 0.18), V(0.41, 3.09, 0.61), COLORS.BC, true, CFrame.Angles(0, 0.25, 0))
	fer(m, "Manivelle", V(0.16, 0.48, 0.14), V(1.86, 2.22, 1.04))
end

ARCH.presse = function(m, c)
	for _, x in { -1.59, 1.59 } do
		bois(m, "Patin", V(0.44, 0.22, 2.83), V(x, 0.11, 0), DARK)
		bois(m, "Montant", V(0.46, 3.93, 0.48), V(x, 2.12, 0), DARK)
		for _, y in { 0.45, 3.83 } do rivet(m, V(x, y, 0.27), 0.16) end
	end
	bois(m, "Traverse", V(3.64, 0.48, 0.56), V(0, 4.03, 0), c)
	cyl(m, "Maie", 2.96, 0.22, V(0, 0.17, 0), DARK, Mat.Wood)
	for i = 0, 11 do
		local a = i * TAU / 12
		bois(m, "Douelle", V(0.61, 1.04, 0.17), V(math.sin(a) * 1.23, 0.77, math.cos(a) * 1.23),
			teinte(c, i), false, CFrame.Angles(0, a, 0))
	end
	for _, y in { 0.42, 1.13 } do anneau(m, "Cercle", V(0, y, 0), 1.31, 9, 0.12, IRON, Mat.Metal, "XZ") end
	cyl(m, "Plateau", 2.42, 0.23, V(0, 1.29, 0), c, Mat.Wood)
	cyl(m, "Vis", 0.31, 3.39, V(0, 3.03, 0), IRON, Mat.Metal)
	for i = 0, 6 do cyl(m, "Filet", 0.42, 0.075, V(0, 1.74 + i * 0.31, 0), IRON, Mat.Metal, nil, true) end
	fer(m, "Levier", V(2.47, 0.15, 0.16), V(0, 4.54, 0))
	for _, x in { -1.18, 1.18 } do boule(m, "Pommeau", V(0.21, 0.23, 0.22), V(x, 4.54, 0), WOOD, Mat.Wood) end
end


-- Construit le modèle d'un objet du catalogue (nil si inconnu). Le pied du modèle est en y = 0.
function K.build(name: string): Model?
	local spec = K.MODELS[name]
	if not spec then
		return nil
	end
	local fn = ARCH[spec.arch]
	if not fn then
		warn("[Catalogue] forme inconnue : " .. tostring(spec.arch))
		return nil
	end
	local m = Instance.new("Model")
	m.Name = name
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(1, 0.2, 1)
	base.CFrame = CFrame.new()
	base.Transparency = 1
	base.Anchored = true
	base.CanCollide = false
	base.CanQuery = false
	base.CanTouch = false
	base.Parent = m
	m.PrimaryPart = base
	local ok, erreur = pcall(fn, m, COLORS[spec.color] or WOOD)
	if not ok then
		m:Destroy()
		error(erreur, 0)
	end
	return m
end

return K
