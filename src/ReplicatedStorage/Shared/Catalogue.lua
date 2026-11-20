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
dice|Jeu de dés|🎲|10|v|bone2|loisirs
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

local COLORS = {
	B = Color3.fromRGB(150, 104, 64), BF = Color3.fromRGB(88, 58, 38), BC = Color3.fromRGB(196, 156, 104),
	P = Color3.fromRGB(128, 128, 134), PC = Color3.fromRGB(176, 172, 162), F = Color3.fromRGB(72, 72, 78),
	O = Color3.fromRGB(226, 182, 64), R = Color3.fromRGB(160, 46, 40), BL = Color3.fromRGB(46, 76, 150),
	V = Color3.fromRGB(70, 120, 60), W = Color3.fromRGB(236, 230, 214), T = Color3.fromRGB(190, 100, 60),
	N = Color3.fromRGB(36, 36, 40), Y = Color3.fromRGB(220, 190, 100), VI = Color3.fromRGB(110, 60, 140),
}
local WOOD, DARK, IRON, STONE, CLOTH = COLORS.B, COLORS.BF, COLORS.F, COLORS.P, COLORS.W
local Mat = Enum.Material

local function P(m: Model, size: Vector3, pos: Vector3, color: Color3, mat: Enum.Material?, shape: string?, rot: CFrame?)
	local p
	if shape == "wedge" then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
		if shape == "ball" then
			p.Shape = Enum.PartType.Ball
		elseif shape == "cyl" then
			p.Shape = Enum.PartType.Cylinder
		end
	end
	p.Size = size
	p.CFrame = CFrame.new(pos) * (rot or CFrame.identity)
	p.Color = color
	p.Material = mat or Mat.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end
local UP = CFrame.Angles(0, 0, math.rad(90)) -- cylindre debout
local function V(x, y, z)
	return Vector3.new(x, y, z)
end
local function light(part: BasePart, range: number)
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 190, 110)
	l.Range = range
	l.Brightness = 1.4
	l.Parent = part
	local f = Instance.new("Fire")
	f.Size = 2
	f.Heat = 4
	f.Parent = part
end
local function legs(m, w, d, h, c)
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		P(m, V(0.3, h, 0.3), V(s[1] * (w / 2 - 0.2), h / 2, s[2] * (d / 2 - 0.2)), c, Mat.Wood)
	end
end

local ARCH = {}
ARCH.caisse = function(m, c)
	P(m, V(2.4, 2.4, 2.4), V(0, 1.2, 0), c, Mat.WoodPlanks)
	P(m, V(2.5, 0.3, 2.5), V(0, 2.3, 0), DARK, Mat.Wood)
end
ARCH.tonneau = function(m, c)
	P(m, V(3, 2.4, 2.4), V(0, 1.5, 0), c, Mat.WoodPlanks, "cyl", UP)
	P(m, V(0.3, 2.55, 2.55), V(0, 0.6, 0), IRON, Mat.Metal, "cyl", UP)
	P(m, V(0.3, 2.55, 2.55), V(0, 2.4, 0), IRON, Mat.Metal, "cyl", UP)
end
ARCH.baril = function(m, c)
	P(m, V(2, 1.6, 1.6), V(0, 1.2, 0), c, Mat.WoodPlanks, "cyl")
	P(m, V(0.3, 0.8, 1.4), V(-0.6, 0.4, 0), DARK, Mat.Wood)
	P(m, V(0.3, 0.8, 1.4), V(0.6, 0.4, 0), DARK, Mat.Wood)
end
ARCH.table = function(m, c)
	P(m, V(3.4, 0.25, 2.2), V(0, 2.6, 0), c, Mat.WoodPlanks)
	legs(m, 3.4, 2.2, 2.5, DARK)
end
ARCH.grandetable = function(m, c)
	P(m, V(7, 0.3, 2.6), V(0, 2.6, 0), c, Mat.WoodPlanks)
	legs(m, 7, 2.6, 2.5, DARK)
	P(m, V(6, 0.25, 0.25), V(0, 0.8, 0), DARK, Mat.Wood)
end
ARCH.tabouret = function(m, c)
	P(m, V(1.2, 1.8, 1.2), V(0, 1.6, 0), c, Mat.WoodPlanks, "cyl", UP)
	legs(m, 1.2, 1.2, 1.5, DARK)
end
ARCH.chaise = function(m, c)
	P(m, V(1.4, 0.2, 1.4), V(0, 1.5, 0), c, Mat.WoodPlanks)
	legs(m, 1.4, 1.4, 1.4, DARK)
	P(m, V(1.4, 1.6, 0.2), V(0, 2.4, -0.6), c, Mat.WoodPlanks)
end
ARCH.lit = function(m, c)
	P(m, V(2.6, 0.8, 5), V(0, 0.6, 0), DARK, Mat.Wood)
	P(m, V(2.4, 0.4, 3.6), V(0, 1.2, 0.5), c, Mat.Fabric)
	P(m, V(2.4, 0.4, 1), V(0, 1.2, -1.8), CLOTH, Mat.Fabric)
	P(m, V(2.6, 1.6, 0.3), V(0, 1.2, -2.5), DARK, Mat.Wood)
end
ARCH.litdouble = function(m, c)
	P(m, V(4.6, 0.8, 5), V(0, 0.6, 0), DARK, Mat.Wood)
	P(m, V(4.4, 0.4, 3.6), V(0, 1.2, 0.5), c, Mat.Fabric)
	P(m, V(1.8, 0.4, 1), V(-1.1, 1.2, -1.8), CLOTH, Mat.Fabric)
	P(m, V(1.8, 0.4, 1), V(1.1, 1.2, -1.8), CLOTH, Mat.Fabric)
	P(m, V(4.6, 2.2, 0.3), V(0, 1.4, -2.5), DARK, Mat.Wood)
end
ARCH.paillasse = function(m, c)
	P(m, V(2.4, 0.5, 4.6), V(0, 0.25, 0), c, Mat.Grass)
	P(m, V(2.2, 0.2, 2.4), V(0, 0.55, 0.8), COLORS.R, Mat.Fabric)
end
ARCH.armoire = function(m, c)
	P(m, V(3.2, 5.4, 1.6), V(0, 2.7, 0), c, Mat.WoodPlanks)
	P(m, V(0.1, 4.6, 0.1), V(0, 2.8, 0.82), IRON, Mat.Metal)
	P(m, V(3.4, 0.3, 1.8), V(0, 5.5, 0), DARK, Mat.Wood)
end
ARCH.etagere = function(m, c)
	for i = 0, 3 do
		P(m, V(3.4, 0.2, 1), V(0, 0.4 + i * 1.3, 0), c, Mat.WoodPlanks)
	end
	P(m, V(0.2, 4.4, 1), V(-1.7, 2.2, 0), DARK, Mat.Wood)
	P(m, V(0.2, 4.4, 1), V(1.7, 2.2, 0), DARK, Mat.Wood)
end
ARCH.coffret = function(m, c)
	P(m, V(1.35, 0.46, 0.85), V(0, 0.23, 0), c, Mat.Wood)
	P(m, V(1.42, 0.14, 0.92), V(0, 0.53, 0), DARK, Mat.Wood)
	P(m, V(0.22, 0.2, 0.06), V(0, 0.38, 0.46), IRON, Mat.Metal)
end
ARCH.biblio = function(m, c)
	ARCH.etagere(m, c)
	local cols = { COLORS.R, COLORS.BL, COLORS.V, COLORS.Y, COLORS.VI }
	for i = 0, 2 do
		for j = 0, 5 do
			P(m, V(0.4, 0.9, 0.8), V(-1.3 + j * 0.5, 0.95 + i * 1.3, 0), cols[(i + j) % #cols + 1], Mat.Fabric)
		end
	end
end
ARCH.comptoir = function(m, c)
	P(m, V(6, 2.8, 1.6), V(0, 1.4, 0), c, Mat.WoodPlanks)
	P(m, V(6.3, 0.3, 1.9), V(0, 2.95, 0), DARK, Mat.Wood)
end
ARCH.bureau = function(m, c)
	ARCH.table(m, c)
	P(m, V(0.5, 0.5, 0.5), V(1, 2.95, 0.4), COLORS.N, Mat.Glass)
	P(m, V(1.2, 0.05, 0.9), V(-0.4, 2.75, 0), CLOTH, Mat.Fabric)
end
-- Tourelles (Systemes/Tourelles) : la partie « Tete » pivote vers la cible
ARCH.tourelle = function(m, c)
	P(m, V(2.6, 0.5, 2.6), V(0, 0.25, 0), STONE, Mat.Cobblestone)
	P(m, V(0.7, 2.4, 0.7), V(0, 1.7, 0), c, Mat.Wood)
	local t = P(m, V(1.2, 0.6, 2.6), V(0, 3.1, 0), DARK, Mat.Wood)
	t.Name = "Tete"
	P(m, V(3, 0.25, 0.3), V(0, 3.3, -0.9), c, Mat.Wood).Name = "Tete_arc"
	P(m, V(0.2, 0.2, 1.6), V(0, 3.5, -0.2), IRON, Mat.Metal).Name = "Tete_carreau"
end
ARCH.baliste = function(m, c)
	P(m, V(4, 0.6, 4), V(0, 0.3, 0), STONE, Mat.Cobblestone)
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		P(m, V(0.5, 2.6, 0.5), V(s[1] * 1.3, 1.9, s[2] * 1.3), c, Mat.Wood)
	end
	P(m, V(3.4, 0.4, 3.4), V(0, 3.3, 0), c, Mat.WoodPlanks)
	local t = P(m, V(1.4, 0.9, 4.2), V(0, 4, 0), DARK, Mat.Wood)
	t.Name = "Tete"
	P(m, V(5, 0.4, 0.5), V(0, 4.3, -1.6), c, Mat.Wood).Name = "Tete_arc"
	P(m, V(0.35, 0.35, 3), V(0, 4.6, -0.6), IRON, Mat.Metal).Name = "Tete_carreau"
	P(m, V(0.6, 0.6, 0.6), V(0, 4.6, -2.2), COLORS.R, Mat.Metal, "ball").Name = "Tete_pointe"
end
K.MODELS.Cat_tourelle = { arch = "tourelle", color = "B" }
K.MODELS.Cat_baliste = { arch = "baliste", color = "BF" }

ARCH.coffre = function(m, c)
	P(m, V(3, 1.6, 2), V(0, 0.8, 0), c, Mat.WoodPlanks)
	P(m, V(3.1, 0.7, 2.1), V(0, 1.95, 0), c, Mat.WoodPlanks)
	P(m, V(0.3, 2.4, 2.15), V(-1, 1.2, 0), IRON, Mat.Metal)
	P(m, V(0.3, 2.4, 2.15), V(1, 1.2, 0), IRON, Mat.Metal)
end
ARCH.cheminee = function(m, c)
	P(m, V(5, 4, 2), V(0, 2, 0), c, Mat.Cobblestone)
	P(m, V(3, 2.4, 1), V(0, 1.2, 0.6), COLORS.N, Mat.Slate)
	P(m, V(2.4, 6, 1.6), V(0, 7, -0.2), c, Mat.Brick)
	local feu = P(m, V(1.6, 0.6, 0.6), V(0, 0.4, 0.6), COLORS.T, Mat.Neon)
	feu.CanCollide = false
	light(feu, 16)
end
ARCH.foyer = function(m, c)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		P(m, V(0.8, 0.6, 0.8), V(math.cos(a) * 1.4, 0.3, math.sin(a) * 1.4), c, Mat.Cobblestone)
	end
	local feu = P(m, V(1, 0.4, 1), V(0, 0.3, 0), COLORS.T, Mat.Neon)
	feu.CanCollide = false
	light(feu, 14)
end
ARCH.fourpain = function(m, c)
	P(m, V(4, 4, 4), V(0, 1.6, 0), c, Mat.Brick, "ball")
	P(m, V(4.4, 1, 4.4), V(0, 0.5, 0), STONE, Mat.Cobblestone)
	P(m, V(1.4, 1.2, 0.4), V(0, 1.4, 1.9), COLORS.N, Mat.Slate)
end
ARCH.chaudron = function(m, c)
	P(m, V(2.6, 2.6, 2.6), V(0, 1.4, 0), c, Mat.Metal, "ball")
	P(m, V(0.4, 2.2, 2.2), V(0, 2.5, 0), COLORS.V, Mat.Neon, "cyl", UP)
	local feu = P(m, V(1.2, 0.3, 1.2), V(0, 0.15, 0), COLORS.T, Mat.Neon)
	feu.CanCollide = false
	light(feu, 10)
end
ARCH.bassine = function(m, c)
	P(m, V(1.2, 3, 3), V(0, 0.6, 0), c, Mat.WoodPlanks, "cyl", UP)
	P(m, V(0.2, 2.6, 2.6), V(0, 1.1, 0), Color3.fromRGB(86, 160, 214), Mat.Glass, "cyl", UP)
end
ARCH.mannequin = function(m, c)
	P(m, V(1.6, 0.3, 1.6), V(0, 0.15, 0), DARK, Mat.Wood)
	P(m, V(0.3, 4, 0.3), V(0, 2, 0), DARK, Mat.Wood)
	P(m, V(2, 2, 1), V(0, 3.4, 0), c, Mat.Metal)
	P(m, V(1, 1, 1), V(0, 4.9, 0), c, Mat.Metal, "ball")
end
ARCH.banniere = function(m, c)
	P(m, V(0.3, 7, 0.3), V(0, 3.5, 0), DARK, Mat.Wood)
	P(m, V(2.4, 0.2, 0.2), V(0, 6.8, 0), DARK, Mat.Wood)
	P(m, V(2.2, 3.6, 0.1), V(0, 4.9, 0.15), c, Mat.Fabric)
	P(m, V(1, 1, 0.12), V(0, 5, 0.22), COLORS.O, Mat.Fabric, "wedge")
end
ARCH.drapeau = function(m, c)
	P(m, V(0.25, 9, 0.25), V(0, 4.5, 0), DARK, Mat.Wood)
	P(m, V(0.1, 2, 3), V(0, 7.8, 1.5), c, Mat.Fabric)
end
ARCH.blason = function(m, c)
	P(m, V(0.3, 3, 2.4), V(0, 2.2, 0), c, Mat.WoodPlanks)
	P(m, V(0.35, 1.4, 0.4), V(0, 2.3, 0), COLORS.O, Mat.Metal)
	P(m, V(0.35, 0.4, 1.4), V(0, 2.5, 0), COLORS.O, Mat.Metal)
	P(m, V(0.3, 1.2, 0.3), V(0, 0.6, 0), DARK, Mat.Wood)
end
ARCH.enseigne = function(m, c)
	P(m, V(0.3, 5, 0.3), V(0, 2.5, 0), DARK, Mat.Wood)
	P(m, V(2.4, 0.2, 0.2), V(1.1, 4.8, 0), DARK, Mat.Wood)
	P(m, V(2, 1.3, 0.15), V(1.3, 3.8, 0), c, Mat.WoodPlanks)
end
ARCH.statue = function(m, c)
	P(m, V(2.4, 1, 2.4), V(0, 0.5, 0), STONE, Mat.Cobblestone)
	P(m, V(1.4, 3, 1), V(0, 2.5, 0), c, Mat.Marble)
	P(m, V(1, 1, 1), V(0, 4.5, 0), c, Mat.Marble, "ball")
	P(m, V(0.4, 1.8, 0.4), V(0.9, 3.4, 0), c, Mat.Marble)
end
ARCH.sculpture = function(m, c)
	P(m, V(1.6, 1, 1.6), V(0, 0.5, 0), STONE, Mat.Cobblestone)
	P(m, V(1.4, 1.4, 1.4), V(0, 1.8, 0), c, Mat.Marble, "ball")
	P(m, V(0.8, 0.8, 0.8), V(0.3, 2.9, 0.2), c, Mat.Marble, "ball")
end
ARCH.vase = function(m, c)
	P(m, V(1.4, 1.6, 1.4), V(0, 0.9, 0), c, Mat.Sand, "ball")
	P(m, V(0.8, 0.7, 0.7), V(0, 1.9, 0), c, Mat.Sand, "cyl", UP)
end
ARCH.pichet = function(m, c)
	P(m, V(1.12, 0.86, 0.86), V(0, 0.56, 0), c, Mat.CeramicTiles, "cyl", UP)
	P(m, V(0.16, 0.56, 0.56), V(0, 1.16, 0), c, Mat.CeramicTiles, "cyl", UP)
	P(m, V(0.52, 0.06, 0.18), V(-0.25, 1.24, 0), c, Mat.CeramicTiles)
	P(m, V(0.4, 0.11, 0.14), V(0.47, 0.98, 0), c, Mat.CeramicTiles)
	P(m, V(0.12, 0.47, 0.14), V(0.63, 0.8, 0), c, Mat.CeramicTiles)
	P(m, V(0.29, 0.11, 0.14), V(0.5, 0.58, 0), c, Mat.CeramicTiles)
end
ARCH.pot = function(m, c)
	P(m, V(1.1, 1.2, 1.2), V(0, 0.55, 0), c, Mat.Sand, "cyl", UP)
	P(m, V(0.8, 0.8, 0.8), V(0, 1.4, 0), COLORS.V, Mat.Grass, "ball")
end
ARCH.jardiniere = function(m, c)
	P(m, V(3.6, 1, 1.2), V(0, 0.5, 0), c, Mat.WoodPlanks)
	for i = -1, 1 do
		P(m, V(0.8, 0.8, 0.8), V(i * 1.1, 1.2, 0), i == 0 and COLORS.R or COLORS.Y, Mat.Grass, "ball")
	end
end
ARCH.torche = function(m, c)
	P(m, V(0.3, 3, 0.3), V(0, 1.5, 0), c, Mat.Wood)
	local f = P(m, V(0.5, 0.5, 0.5), V(0, 3.1, 0), COLORS.T, Mat.Neon)
	f.CanCollide = false
	light(f, 14)
end
ARCH.brasero = function(m, c)
	P(m, V(0.4, 2.6, 0.4), V(0, 1.3, 0), c, Mat.Metal)
	P(m, V(0.6, 2, 2), V(0, 2.8, 0), c, Mat.Metal, "cyl", UP)
	local f = P(m, V(1.4, 0.4, 1.4), V(0, 3.1, 0), COLORS.T, Mat.Neon)
	f.CanCollide = false
	light(f, 20)
end
ARCH.bougie = function(m, c)
	P(m, V(0.8, 0.2, 0.8), V(0, 0.1, 0), COLORS.O, Mat.Metal, "cyl", UP)
	P(m, V(0.9, 0.35, 0.35), V(0, 0.6, 0), c, Mat.SmoothPlastic, "cyl", UP)
	local f = P(m, V(0.15, 0.25, 0.15), V(0, 1.15, 0), COLORS.Y, Mat.Neon)
	f.CanCollide = false
	local l = Instance.new("PointLight")
	l.Range = 8
	l.Color = Color3.fromRGB(255, 200, 120)
	l.Parent = f
end
ARCH.chandelier = function(m, c)
	P(m, V(0.3, 3, 0.3), V(0, 1.5, 0), c, Mat.Metal)
	P(m, V(2.4, 0.2, 0.2), V(0, 3, 0), c, Mat.Metal)
	for _, x in { -1.1, 0, 1.1 } do
		P(m, V(0.25, 0.6, 0.25), V(x, 3.4, 0), CLOTH, Mat.SmoothPlastic)
		local f = P(m, V(0.15, 0.25, 0.15), V(x, 3.85, 0), COLORS.Y, Mat.Neon)
		f.CanCollide = false
	end
	local l = Instance.new("PointLight")
	l.Range = 14
	l.Color = Color3.fromRGB(255, 200, 120)
	l.Parent = m:GetChildren()[#m:GetChildren()]
end
ARCH.tapis = function(m, c)
	P(m, V(5, 0.1, 3.4), V(0, 0.05, 0), c, Mat.Fabric)
	P(m, V(4.2, 0.12, 2.6), V(0, 0.06, 0), COLORS.O, Mat.Fabric)
	P(m, V(3.6, 0.14, 2), V(0, 0.07, 0), c, Mat.Fabric)
end
ARCH.rideau = function(m, c)
	P(m, V(4, 0.2, 0.2), V(0, 5.4, 0), DARK, Mat.Wood)
	P(m, V(1.8, 5, 0.1), V(-1, 2.8, 0.1), c, Mat.Fabric)
	P(m, V(1.8, 5, 0.1), V(1, 2.8, 0.1), c, Mat.Fabric)
end
ARCH.tenture = function(m, c)
	P(m, V(3.6, 0.2, 0.2), V(0, 5.4, 0), COLORS.O, Mat.Metal)
	P(m, V(3.4, 4.4, 0.1), V(0, 3.1, 0.1), c, Mat.Fabric)
	P(m, V(1.4, 1.4, 0.12), V(0, 3.4, 0.17), COLORS.O, Mat.Fabric)
end
ARCH.tableau = function(m, c)
	P(m, V(3, 2.4, 0.2), V(0, 3, 0), c, Mat.Metal)
	P(m, V(2.6, 2, 0.22), V(0, 3, 0.02), Color3.fromRGB(80, 120, 160), Mat.SmoothPlastic)
	P(m, V(2.6, 0.9, 0.24), V(0, 2.45, 0.03), COLORS.V, Mat.SmoothPlastic)
end
ARCH.trophee = function(m, c)
	P(m, V(1.6, 2, 0.3), V(0, 3, 0), DARK, Mat.Wood)
	P(m, V(0.3, 1.6, 0.3), V(-0.5, 4, 0.2), COLORS.BC, Mat.Wood, nil, CFrame.Angles(0, 0, math.rad(25)))
	P(m, V(0.3, 1.6, 0.3), V(0.5, 4, 0.2), COLORS.BC, Mat.Wood, nil, CFrame.Angles(0, 0, math.rad(-25)))
	P(m, V(0.3, 2.2, 0.3), V(0, 1, 0), DARK, Mat.Wood)
end
ARCH.crane = function(m, c)
	P(m, V(1.6, 1.4, 1.8), V(0, 0.7, 0), c, Mat.SmoothPlastic, "ball")
	P(m, V(0.3, 0.3, 0.1), V(-0.35, 0.8, -0.85), COLORS.N, Mat.SmoothPlastic)
	P(m, V(0.3, 0.3, 0.1), V(0.35, 0.8, -0.85), COLORS.N, Mat.SmoothPlastic)
	P(m, V(0.25, 1.2, 0.25), V(-0.7, 1.6, 0), c, Mat.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(30)))
	P(m, V(0.25, 1.2, 0.25), V(0.7, 1.6, 0), c, Mat.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(-30)))
end
ARCH.horloge = function(m, c)
	P(m, V(1.8, 6, 1.2), V(0, 3, 0), c, Mat.WoodPlanks)
	P(m, V(0.2, 1.4, 1.4), V(0, 4.8, 0.55), CLOTH, Mat.SmoothPlastic, "cyl", CFrame.Angles(0, math.rad(90), 0))
	P(m, V(0.1, 0.6, 0.05), V(0, 5, 0.65), COLORS.N, Mat.Metal)
	P(m, V(0.2, 1.6, 0.05), V(0, 2.4, 0.62), COLORS.O, Mat.Metal)
end
ARCH.girouette = function(m, c)
	P(m, V(0.2, 6, 0.2), V(0, 3, 0), c, Mat.Metal)
	P(m, V(2.4, 0.1, 0.1), V(0, 5, 0), c, Mat.Metal)
	P(m, V(0.1, 2.4, 0.1), V(0, 5, 0), c, Mat.Metal, nil, CFrame.Angles(math.rad(90), 0, 0))
	P(m, V(0.1, 1, 1.4), V(0, 6.4, 0), c, Mat.Metal, "wedge")
end
ARCH.muret = function(m, c)
	P(m, V(4, 1.6, 1), V(0, 0.8, 0), c, Mat.Cobblestone)
end
ARCH.palissade = function(m, c)
	for i = -1.5, 1.5, 0.75 do
		P(m, V(0.7, 5, 0.7), V(i, 2.5, 0), c, Mat.Wood, "cyl", UP)
		P(m, V(0.5, 0.5, 0.5), V(i, 5.1, 0), c, Mat.Wood, "ball")
	end
	P(m, V(4, 0.3, 0.3), V(0, 3.6, 0.4), DARK, Mat.Wood)
end
ARCH.portail = function(m, c)
	P(m, V(0.4, 3, 0.4), V(-2, 1.5, 0), DARK, Mat.Wood)
	P(m, V(0.4, 3, 0.4), V(2, 1.5, 0), DARK, Mat.Wood)
	for _, y in { 0.6, 1.4, 2.2 } do
		P(m, V(3.6, 0.3, 0.15), V(0, y, 0), c, Mat.WoodPlanks)
	end
	P(m, V(0.2, 2.2, 0.15), V(0, 1.4, 0), c, Mat.WoodPlanks, nil, CFrame.Angles(0, 0, math.rad(52)))
end
ARCH.cabane = function(m, c)
	P(m, V(8, 0.3, 8), V(0, 0.15, 0), DARK, Mat.WoodPlanks)
	P(m, V(8, 4, 0.4), V(0, 2, -3.8), c, Mat.WoodPlanks)
	P(m, V(0.4, 4, 8), V(-3.8, 2, 0), c, Mat.WoodPlanks)
	P(m, V(0.4, 4, 8), V(3.8, 2, 0), c, Mat.WoodPlanks)
	P(m, V(8, 1.6, 0.4), V(0, 3.2, 3.8), c, Mat.WoodPlanks)
	P(m, V(8.6, 2.4, 4.6), V(0, 5.2, -2.1), COLORS.Y, Mat.Grass, "wedge")
	P(m, V(8.6, 2.4, 4.6), V(0, 5.2, 2.1), COLORS.Y, Mat.Grass, "wedge", CFrame.Angles(0, math.rad(180), 0))
	P(m, V(6, 0.4, 6), V(0, 0.4, 0), COLORS.Y, Mat.Grass)
end
ARCH.grange = function(m, c)
	P(m, V(12, 0.3, 10), V(0, 0.15, 0), DARK, Mat.WoodPlanks)
	P(m, V(12, 6, 0.4), V(0, 3, -4.8), c, Mat.WoodPlanks)
	P(m, V(0.4, 6, 10), V(-5.8, 3, 0), c, Mat.WoodPlanks)
	P(m, V(0.4, 6, 10), V(5.8, 3, 0), c, Mat.WoodPlanks)
	P(m, V(4, 6, 0.4), V(-4, 3, 4.8), c, Mat.WoodPlanks)
	P(m, V(4, 6, 0.4), V(4, 3, 4.8), c, Mat.WoodPlanks)
	P(m, V(4, 1, 0.4), V(0, 5.5, 4.8), c, Mat.WoodPlanks)
	P(m, V(12.6, 3.4, 5.6), V(0, 7.7, -2.6), DARK, Mat.WoodPlanks, "wedge")
	P(m, V(12.6, 3.4, 5.6), V(0, 7.7, 2.6), DARK, Mat.WoodPlanks, "wedge", CFrame.Angles(0, math.rad(180), 0))
end
ARCH.grenier = function(m, c)
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		P(m, V(0.8, 2.4, 0.8), V(s[1] * 2.2, 1.2, s[2] * 2.2), STONE, Mat.Cobblestone)
	end
	P(m, V(5.6, 4, 5.6), V(0, 4.4, 0), c, Mat.WoodPlanks)
	P(m, V(6.2, 2, 3.1), V(0, 7.4, -1.55), COLORS.T, Mat.Brick, "wedge")
	P(m, V(6.2, 2, 3.1), V(0, 7.4, 1.55), COLORS.T, Mat.Brick, "wedge", CFrame.Angles(0, math.rad(180), 0))
end
ARCH.poulailler = function(m, c)
	P(m, V(4, 2.4, 3), V(0, 2, 0), c, Mat.WoodPlanks)
	legs(m, 4, 3, 0.8, DARK)
	P(m, V(4.4, 1.2, 1.7), V(0, 3.8, -0.8), COLORS.R, Mat.WoodPlanks, "wedge")
	P(m, V(4.4, 1.2, 1.7), V(0, 3.8, 0.8), COLORS.R, Mat.WoodPlanks, "wedge", CFrame.Angles(0, math.rad(180), 0))
	P(m, V(0.8, 0.2, 2), V(1.4, 0.6, 2.2), DARK, Mat.Wood, nil, CFrame.Angles(math.rad(-25), 0, 0))
end
ARCH.enclos = function(m, c)
	for _, s in { { 0, -3.8, 8, 0.3 }, { 0, 3.8, 8, 0.3 }, { -3.8, 0, 0.3, 8 }, { 3.8, 0, 0.3, 8 } } do
		P(m, V(s[3], 0.3, s[4]), V(s[1], 1.6, s[2]), c, Mat.WoodPlanks)
		P(m, V(s[3], 0.3, s[4]), V(s[1], 0.8, s[2]), c, Mat.WoodPlanks)
	end
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		P(m, V(0.4, 2.2, 0.4), V(s[1] * 3.8, 1.1, s[2] * 3.8), DARK, Mat.Wood)
	end
end
ARCH.mangeoire = function(m, c)
	P(m, V(3.4, 1, 1.4), V(0, 0.9, 0), c, Mat.WoodPlanks)
	legs(m, 3.4, 1.4, 0.5, DARK)
	P(m, V(3.2, 0.3, 1.2), V(0, 1.4, 0), COLORS.Y, Mat.Grass)
end
ARCH.abreuvoir = function(m, c)
	P(m, V(3.4, 1, 1.4), V(0, 0.5, 0), c, Mat.WoodPlanks)
	P(m, V(3.2, 0.2, 1.2), V(0, 0.95, 0), Color3.fromRGB(86, 160, 214), Mat.Glass)
end
ARCH.ratelier = function(m, c)
	P(m, V(3.4, 0.3, 0.3), V(0, 3, 0), c, Mat.Wood)
	P(m, V(3.4, 0.3, 0.3), V(0, 1.2, 0.6), c, Mat.Wood)
	for x = -1.5, 1.5, 0.5 do
		P(m, V(0.12, 2, 0.12), V(x, 2.1, 0.3), c, Mat.Wood, nil, CFrame.Angles(math.rad(-18), 0, 0))
	end
	P(m, V(3, 1, 0.8), V(0, 2, 0.4), COLORS.Y, Mat.Grass)
	P(m, V(0.3, 3.2, 0.3), V(-1.8, 1.6, 0), DARK, Mat.Wood)
	P(m, V(0.3, 3.2, 0.3), V(1.8, 1.6, 0), DARK, Mat.Wood)
end
ARCH.roue = function(m, c)
	P(m, V(0.8, 7, 7), V(0, 3.6, 0), c, Mat.WoodPlanks, "cyl")
	P(m, V(1.2, 1.2, 1.2), V(0, 3.6, 0), IRON, Mat.Metal, "cyl")
	P(m, V(0.6, 4, 0.6), V(-1, 2, 0), DARK, Mat.Wood)
	P(m, V(0.6, 4, 0.6), V(1, 2, 0), DARK, Mat.Wood)
end
ARCH.treuil = function(m, c)
	P(m, V(0.4, 3, 0.4), V(-1.4, 1.5, 0), DARK, Mat.Wood)
	P(m, V(0.4, 3, 0.4), V(1.4, 1.5, 0), DARK, Mat.Wood)
	P(m, V(2.8, 1, 1), V(0, 2.6, 0), c, Mat.Wood, "cyl")
	P(m, V(2.6, 1.1, 1.1), V(0, 2.6, 0), COLORS.Y, Mat.Fabric, "cyl")
end
ARCH.grue = function(m, c)
	P(m, V(4, 0.6, 4), V(0, 0.3, 0), DARK, Mat.WoodPlanks)
	P(m, V(0.8, 10, 0.8), V(0, 5, 0), c, Mat.Wood)
	P(m, V(0.6, 0.6, 8), V(0, 9.6, 3), c, Mat.Wood)
	P(m, V(0.1, 5, 0.1), V(0, 7, 6.6), COLORS.Y, Mat.Fabric)
	P(m, V(0.8, 0.8, 0.8), V(0, 4.4, 6.6), IRON, Mat.Metal)
end
ARCH.levier = function(m, c)
	P(m, V(1.2, 0.6, 1.2), V(0, 0.3, 0), STONE, Mat.Cobblestone)
	P(m, V(0.2, 2, 0.2), V(0, 1.3, 0), c, Mat.Metal, nil, CFrame.Angles(math.rad(25), 0, 0))
	P(m, V(0.4, 0.4, 0.4), V(0, 2.2, 0.4), COLORS.R, Mat.SmoothPlastic, "ball")
end
ARCH.pompe = function(m, c)
	P(m, V(1.4, 3, 1.4), V(0, 1.5, 0), c, Mat.Metal, "cyl", UP)
	P(m, V(0.2, 0.2, 2), V(0, 2.8, 0.8), c, Mat.Metal)
	P(m, V(0.3, 0.3, 1), V(0, 2, -0.9), c, Mat.Metal)
	P(m, V(2.4, 0.6, 2.4), V(0, 0.3, 0), STONE, Mat.Cobblestone)
end
ARCH.canal = function(m, c)
	P(m, V(4, 1, 0.5), V(0, 0.5, -1), c, Mat.Cobblestone)
	P(m, V(4, 1, 0.5), V(0, 0.5, 1), c, Mat.Cobblestone)
	P(m, V(4, 0.2, 1.6), V(0, 0.3, 0), Color3.fromRGB(86, 160, 214), Mat.Glass)
end
ARCH.herse = function(m, c)
	for x = -1.8, 1.8, 0.6 do
		P(m, V(0.2, 5, 0.2), V(x, 2.6, 0), c, Mat.Metal)
	end
	for y = 1, 4.5, 1.2 do
		P(m, V(4, 0.2, 0.2), V(0, y, 0), c, Mat.Metal)
	end
end
ARCH.pontlevis = function(m, c)
	P(m, V(4, 0.5, 8), V(0, 0.25, 0), c, Mat.WoodPlanks)
	P(m, V(0.3, 0.3, 8), V(-1.9, 0.6, 0), IRON, Mat.Metal)
	P(m, V(0.3, 0.3, 8), V(1.9, 0.6, 0), IRON, Mat.Metal)
end
ARCH.echelle = function(m, c)
	P(m, V(0.25, 8, 0.25), V(-0.7, 4, 0), c, Mat.Wood)
	P(m, V(0.25, 8, 0.25), V(0.7, 4, 0), c, Mat.Wood)
	for y = 0.6, 7.6, 0.8 do
		P(m, V(1.4, 0.15, 0.2), V(0, y, 0), c, Mat.Wood)
	end
	local t = Instance.new("TrussPart")
	t.Size = V(2, 8, 2)
	t.CFrame = CFrame.new(0, 4, 0)
	t.Transparency = 1
	t.Anchored = true
	t.Parent = m
end
ARCH.arche = function(m, c)
	P(m, V(1.2, 6, 1.2), V(-2.4, 3, 0), c, Mat.Cobblestone)
	P(m, V(1.2, 6, 1.2), V(2.4, 3, 0), c, Mat.Cobblestone)
	-- écoinçons : pente vers le bas, pleins contre les piliers, l'ouverture s'arrondit au centre
	P(m, V(1.2, 1.4, 1.8), V(-0.9, 6.4, 0), c, Mat.Cobblestone, "wedge", CFrame.Angles(0, math.rad(-90), 0) * CFrame.Angles(0, 0, math.pi))
	P(m, V(1.2, 1.4, 1.8), V(0.9, 6.4, 0), c, Mat.Cobblestone, "wedge", CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.pi))
	P(m, V(6, 0.8, 1.2), V(0, 7.5, 0), c, Mat.Cobblestone)
end
ARCH.socle = function(m, c)
	P(m, V(2.4, 0.6, 2.4), V(0, 0.3, 0), c, Mat.Marble)
	P(m, V(1.8, 2, 1.8), V(0, 1.6, 0), c, Mat.Marble)
	P(m, V(2.4, 0.5, 2.4), V(0, 2.85, 0), c, Mat.Marble)
end
ARCH.porte = function(m, c)
	P(m, V(3.6, 6, 0.4), V(0, 3, 0), c, Mat.WoodPlanks)
	P(m, V(3.6, 0.3, 0.45), V(0, 1.5, 0), DARK, Mat.Wood)
	P(m, V(3.6, 0.3, 0.45), V(0, 4.5, 0), DARK, Mat.Wood)
	P(m, V(0.2, 4.5, 0.45), V(0, 3, 0), DARK, Mat.Wood, nil, CFrame.Angles(0, 0, math.rad(37)))
end
ARCH.portedouble = function(m, c)
	P(m, V(2.4, 7, 0.5), V(-1.25, 3.5, 0), c == IRON and DARK or c, Mat.WoodPlanks)
	P(m, V(2.4, 7, 0.5), V(1.25, 3.5, 0), c == IRON and DARK or c, Mat.WoodPlanks)
	for _, y in { 1.5, 3.5, 5.5 } do
		P(m, V(5, 0.3, 0.55), V(0, y, 0), IRON, Mat.Metal)
	end
	P(m, V(0.4, 0.4, 0.6), V(-0.3, 3.2, 0), COLORS.O, Mat.Metal, "ball")
	P(m, V(0.4, 0.4, 0.6), V(0.3, 3.2, 0), COLORS.O, Mat.Metal, "ball")
end
ARCH.trappe = function(m, c)
	P(m, V(3, 0.3, 3), V(0, 0.15, 0), c, Mat.WoodPlanks)
	P(m, V(0.6, 0.1, 0.6), V(0, 0.35, 1), IRON, Mat.Metal)
end
ARCH.volet = function(m, c)
	P(m, V(1.2, 2.4, 0.15), V(-0.7, 3, 0), c, Mat.WoodPlanks)
	P(m, V(1.2, 2.4, 0.15), V(0.7, 3, 0), c, Mat.WoodPlanks)
end
ARCH.fenetre = function(m, c)
	P(m, V(2.4, 3, 0.3), V(0, 3, 0), Color3.fromRGB(190, 225, 240), Mat.Glass)
	P(m, V(2.8, 0.4, 0.5), V(0, 1.4, 0), c, Mat.Cobblestone)
	P(m, V(0.2, 3, 0.35), V(0, 3, 0), DARK, Mat.Wood)
	P(m, V(2.4, 0.2, 0.35), V(0, 3, 0), DARK, Mat.Wood)
	P(m, V(2.4, 0.8, 0.3), V(0, 4.8, 0), c, Mat.Cobblestone, "ball")
end
ARCH.fenetreronde = function(m, c)
	P(m, V(0.3, 2.4, 2.4), V(0, 3, 0), Color3.fromRGB(190, 225, 240), Mat.Glass, "cyl", CFrame.Angles(0, math.rad(90), 0))
	P(m, V(0.2, 2.8, 2.8), V(0, 3, -0.05), c, Mat.Wood, "cyl", CFrame.Angles(0, math.rad(90), 0))
end
ARCH.vitrail = function(m, c)
	local cols = { COLORS.R, COLORS.BL, COLORS.Y, COLORS.V, c }
	for i = 0, 2 do
		for j = 0, 3 do
			local p = P(m, V(0.8, 0.9, 0.15), V(-0.8 + i * 0.8, 1.8 + j * 0.9, 0), cols[(i + j) % #cols + 1], Mat.Glass)
			p.Transparency = 0.25
		end
	end
	P(m, V(2.6, 0.3, 0.3), V(0, 1.2, 0), STONE, Mat.Cobblestone)
end
ARCH.meurtriere = function(m, c)
	P(m, V(1.6, 4, 1), V(-1.2, 2, 0), c, Mat.Cobblestone)
	P(m, V(1.6, 4, 1), V(1.2, 2, 0), c, Mat.Cobblestone)
	P(m, V(0.8, 1.2, 1), V(0, 0.6, 0), c, Mat.Cobblestone)
	P(m, V(0.8, 1.4, 1), V(0, 3.3, 0), c, Mat.Cobblestone)
end
local function roue(m, pos, d)
	P(m, V(0.3, d, d), pos, DARK, Mat.Wood, "cyl")
end
ARCH.chariot = function(m, c)
	P(m, V(3.4, 0.4, 5), V(0, 1.6, 0), c, Mat.WoodPlanks)
	P(m, V(0.3, 1.2, 5), V(-1.6, 2.4, 0), c, Mat.WoodPlanks)
	P(m, V(0.3, 1.2, 5), V(1.6, 2.4, 0), c, Mat.WoodPlanks)
	P(m, V(3.4, 1.2, 0.3), V(0, 2.4, -2.4), c, Mat.WoodPlanks)
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		roue(m, V(s[1] * 1.9, 1.1, s[2] * 1.6), 2.2)
	end
	P(m, V(0.25, 0.25, 3), V(-0.6, 1.4, 3.8), DARK, Mat.Wood)
	P(m, V(0.25, 0.25, 3), V(0.6, 1.4, 3.8), DARK, Mat.Wood)
end
ARCH.brouette = function(m, c)
	P(m, V(1.8, 0.8, 2.4), V(0, 1.2, 0), c, Mat.WoodPlanks)
	roue(m, V(0, 0.6, 1.4), 1.2)
	P(m, V(0.2, 0.2, 2), V(-0.7, 1.1, -1.8), DARK, Mat.Wood)
	P(m, V(0.2, 0.2, 2), V(0.7, 1.1, -1.8), DARK, Mat.Wood)
end
ARCH.traineau = function(m, c)
	P(m, V(2.4, 0.4, 4), V(0, 1, 0), c, Mat.WoodPlanks)
	P(m, V(0.2, 0.2, 4.6), V(-1, 0.3, 0.2), IRON, Mat.Metal)
	P(m, V(0.2, 0.2, 4.6), V(1, 0.3, 0.2), IRON, Mat.Metal)
	P(m, V(2.4, 1.2, 0.3), V(0, 1.6, -1.9), c, Mat.WoodPlanks)
end
ARCH.barque = function(m, c)
	P(m, V(3, 1.2, 7), V(0, 0.6, 0), c, Mat.WoodPlanks)
	P(m, V(3, 1.2, 2), V(0, 0.6, 4.5), c, Mat.WoodPlanks, "wedge", CFrame.Angles(0, math.rad(180), 0))
	P(m, V(2.6, 0.2, 6.6), V(0, 1.1, 0), DARK, Mat.WoodPlanks)
	P(m, V(3, 0.2, 0.6), V(0, 1.3, 0), c, Mat.Wood)
end
ARCH.radeau = function(m, c)
	for x = -1.6, 1.6, 0.8 do
		P(m, V(5, 0.7, 0.7), V(x, 0.35, 0), c, Mat.Wood, "cyl", CFrame.Angles(0, math.rad(90), 0))
	end
	P(m, V(4, 0.2, 0.3), V(0, 0.8, -1.6), COLORS.Y, Mat.Fabric)
	P(m, V(4, 0.2, 0.3), V(0, 0.8, 1.6), COLORS.Y, Mat.Fabric)
end
ARCH.metier = function(m, c)
	P(m, V(4, 0.3, 3), V(0, 2.4, 0), c, Mat.WoodPlanks)
	legs(m, 4, 3, 2.3, DARK)
	P(m, V(0.3, 2.6, 0.3), V(-1.8, 3.6, -1.2), DARK, Mat.Wood)
	P(m, V(0.3, 2.6, 0.3), V(1.8, 3.6, -1.2), DARK, Mat.Wood)
	P(m, V(3.6, 0.3, 0.3), V(0, 4.8, -1.2), DARK, Mat.Wood)
	P(m, V(3.2, 2, 0.05), V(0, 3.7, -1.2), CLOTH, Mat.Fabric)
end
ARCH.presse = function(m, c)
	P(m, V(3, 1.4, 3), V(0, 0.7, 0), c, Mat.WoodPlanks, "cyl", UP)
	P(m, V(0.5, 4, 0.5), V(-1.6, 2, 0), DARK, Mat.Wood)
	P(m, V(0.5, 4, 0.5), V(1.6, 2, 0), DARK, Mat.Wood)
	P(m, V(3.6, 0.6, 0.6), V(0, 4, 0), DARK, Mat.Wood)
	P(m, V(0.4, 2.4, 0.4), V(0, 2.8, 0), IRON, Mat.Metal)
	P(m, V(2.6, 0.2, 0.2), V(0, 4.5, 0), IRON, Mat.Metal)
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
	fn(m, COLORS[spec.color] or WOOD)
	return m
end

return K
