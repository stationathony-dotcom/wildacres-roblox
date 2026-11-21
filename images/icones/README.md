# Icônes peintes de Wild Acres

Les sept planches transparentes sont associées aux identifiants du jeu dans
[`IconesPeintes.lua`](../../src/StarterPlayer/StarterPlayerScripts/IconesPeintes.lua).
Le sac, la barre rapide, les cases d’équipement et l’atelier utilisent l’illustration lorsqu’elle est disponible et gardent
la miniature 3D ou l’emoji tant que l’identifiant de sa planche est vide.

## À publier par le propriétaire

| Fichier PNG | Entrée Lua | Dimensions du fichier | Contenu |
| --- | --- | --- | --- |
| [Atlas Wild Acres](atlas-wild-acres.png) | `wildAcres` | 1 254 × 1 254 | Menus, outils et ressources du X8 |
| [Atlas structure](atlas-structure-brouillon.png) | `structure` | 1 246 × 1 263 | Charpente, murs, sols et balcons |
| [Atlas construction](atlas-construction-brouillon.png) | `construction` | 1 262 × 1 246 | Ouvertures, harnachement et mobilier |
| [Atlas équipement](atlas-equipement.png) | `equipement` | 1 263 × 1 246 | Armes, protections, accessoires et vêtements |
| [Atlas matières et mobilier](atlas-matieres-mobilier.png) | `matieresMobilier` | 1 254 × 1 254 | Butin, ressources et huit objets à poser |
| [Atlas truffe](atlas-truffe.png) | `truffe` | 512 × 256 | Truffe et omelette aux truffes |
| [Atlas artisanat avancé](atlas-artisanat-avance.png) | `artisanatAvance` | 1 448 × 1 086 | Haches de jet, bois de cœur, caparaçon, cuisine, partition, franchise et caillebotis |

Importer chaque PNG dans Roblox avec son alpha et son cadrage complet. Après approbation,
renseigner l’entrée correspondante avec `asset = "rbxassetid://…"` et la largeur et la hauteur
effectives de l’image publiée dans `taille = Vector2.new(largeur, hauteur)`. Le module adapte
les rectangles si la plateforme redimensionne l’image. Contrôler en Studio / Play les cases aux
coins de chaque planche, puis le rendu dans le sac à petite taille.

## Ordre des cases

Chaque ligne se lit de gauche à droite, de haut en bas. Les variantes `blk_<forme>_<matière>`
partagent l’illustration de leur forme. Le nom de l’objet et l’aperçu de pose indiquent sa matière.

### Atlas Wild Acres

| Ligne | Colonne 1 | Colonne 2 | Colonne 3 | Colonne 4 |
| --- | --- | --- | --- | --- |
| 1 | Sac | Personnage | Compétences | Journal |
| 2 | Carte | Clan | Atelier | Paramètres |
| 3 | Hache | Pioche | Canne à pêche | Harpon |
| 4 | Bois | Pierre | Corde | Blé |

### Atlas structure

| Ligne | Colonne 1 | Colonne 2 | Colonne 3 | Colonne 4 |
| --- | --- | --- | --- | --- |
| 1 | Poteau rond (`poteaurond`) | Demi-poutre (`demipoutre`) | Madrier (`madrier`) | Chevron (`chevron`) |
| 2 | Échalas (`echalas`) | Poteau sculpté (`poteausculpte`) | Colonne carrée (`colonnecarree`) | Mur incliné (`murincline`) |
| 3 | Colombages (`colombages`) | Clayonnage (`clayonnage`) | Treillis (`treillis`) | Niche (`niche`) |
| 4 | Fondation (`fondation`) | Pavage (`pavage`) | Pilotis (`pilotis`) | Balcon (`balcon`) |

### Atlas construction

| Ligne | Colonne 1 | Colonne 2 | Colonne 3 | Colonne 4 |
| --- | --- | --- | --- | --- |
| 1 | Gouttière (`gouttiere`) | Lucarne (`lucarne`) | Croisillons (`croisillons`) | Volets (`volets`) |
| 2 | Vitrail (`vitrail`) | Escalier (`escalier`) | Arche (`arche`) | Muret (`demimur`) |
| 3 | Colonne ronde (`colonne`) | Rambarde (`barriere`) | Bride (`bridle`) | Selle de guerre (`saddle_war`) |
| 4 | Grande table (`big_table`) | Banc (`garden_bench`) | Étagère (`shelf`) | Tapis (`rug`) |

### Atlas équipement

Les entrées `equipement:` correspondent à un nom ou à une forme reconnue par la fiche Personnage.

| Ligne | Colonne 1 | Colonne 2 | Colonne 3 | Colonne 4 |
| --- | --- | --- | --- | --- |
| 1 | Épée de fer (`sword_fe`) | Bouclier rond (`equipement:roundshield`) | Casque (`equipement:helmet`) | Cotte de mailles (`equipement:mail`) |
| 2 | Bottes (`equipement:boots`) | Gantelets (`equipement:gauntlets`) | Bague sertie (`ring_gem`) | Torche (`equipement:torch`) |
| 3 | Capuche (`equipement:Capuche`) | Arc (`equipement:bow`) | Armure de cuir (`equipement:leather`) | Marteau (`equipement:hammer`) |
| 4 | Couronne (`crown`) | Cape (`equipement:cape`) | Lance (`equipement:pike`) | Selle de cuir (`saddle_leather`) |

### Atlas matières et mobilier

| Ligne | Colonne 1 | Colonne 2 | Colonne 3 | Colonne 4 |
| --- | --- | --- | --- | --- |
| 1 | Croc de loup (`prise_wolf`) | Écailles (`scales`) | Plume nocturne (`night_feather`) | Cristal de glace (`ice_crystal`) |
| 2 | Griffe (`claw`) | Fourrure (`fur`) | Soie d’araignée (`silk`) | Cristal ancien (`ancient_crystal`) |
| 3 | Lanterne murale (`wall_lantern`) | Coffre (`chest`) | Pot en terre cuite (`clay_pot`) | Bannière (`banner`) |
| 4 | Lit (`bed`) | Tonneau (`barrel`) | Chaise (`chair`) | Brasero (`brazier`) |

### Atlas truffe

| Colonne 1 | Colonne 2 |
| --- | --- |
| Truffe (`truffle`, 🍄) | Omelette aux truffes (`truffle_omelette`, 🍳) |

### Atlas artisanat avancé

| Ligne | Colonne 1 | Colonne 2 | Colonne 3 | Colonne 4 |
| --- | --- | --- | --- | --- |
| 1 | Hache de jet (`throwing_axe`) | Caparaçon (`caparison`) | Partition (`music_sheet`) | Fromage truffé (`truffle_cheese`) |
| 2 | Plateau du maître pêcheur (`fisher_platter`) | Bois de cœur (`heartwood`) | Lettre de franchise (`franchise_letter`) | Caillebotis (`bloc:caillebotis`, géométrie `slats`) |
| 3 | Arc de bois de cœur | Brigandine de bois de cœur | Haches de jet du forestier | Haches de jet du franc-tireur |

La troisième ligne correspond aux quatre noms d’équipement exacts sous le préfixe `equipement:`.
Les caillebotis en bois et en pin partagent la case de forme. Les emojis de secours et les miniatures 3D
restent disponibles pendant la publication. Le pic d’alpha aux jointures de cette planche est de 1/255.

La lanterne murale garde sa case dans l’atlas matières et mobilier. Avant publication, elle affiche la miniature 3D ou l’emoji 🏮.
Les séparations des planches X25 ont été contrôlées sur le canal alpha des PNG. L’aperçu des cinq premières
planches utilise les rectangles du module Lua et réduit chaque case à 36 px. [Contrôle à 36 px](controle-36px.png).

## Création

Les planches ont été créées avec ImageGen et conservées avec leur canal alpha.

Pour les planches équipement et matières, le prompt demandait une grille de quatre rangées de
quatre objets médiévaux peints en trois-quarts, dans l’ordre des tableaux ci-dessus, avec des marges
transparentes, une lumière ambrée et des silhouettes lisibles à 36 px, sans cadre ni texte.
Le cristal ancien est représenté par une gemme violette facettée.

Pour la planche truffe, les prompts ImageGen demandaient deux icônes peintes en trois-quarts sur fond transparent,
lisibles à 36 px sous une lumière ambrée. La première montre une truffe noire entière et une moitié veinée. La seconde
montre une omelette dorée pliée, garnie de lamelles de truffe sur une assiette de terre cuite.

Pour l’atlas artisanat avancé, ImageGen intégré a reçu la grille de trois rangées ci-dessus et la description
de douze icônes médiévales peintes à la main, en trois-quarts, éclairées à l’ambre, aux silhouettes lisibles à 36 px.
La composition demande des marges transparentes, sans titres ni cadres. Les deux paires de haches se distinguent
par la largeur des fers et l’enroulement de cuir. Les rectangles suivent les séparations transparentes du PNG.

<details>
<summary>Prompt ImageGen de l’atlas artisanat avancé</summary>

> Use case: stylized-concept. Make a single transparent PNG sprite atlas for Wild Acres, an original medieval crafting RPG. Exactly twelve separated hand-painted inventory icons in a strictly regular four-column by three-row landscape grid (canvas ratio 4:3, equal square cells). Object centers at 12.5%, 37.5%, 62.5%, 87.5% width and 16.67%, 50%, 83.33% height. Keep each icon within the central 70% of its cell in both axes with ample fully transparent gutters for cropping. Row 1 left to right: a single modest iron throwing hatchet with short wooden haft; a folded burgundy and gold caparison (medieval padded horse cloth armor with straps); an opened cream parchment sheet with musical notes; a wedge of pale cheese with distinct black truffle flecks and dark rind. Row 2: a large glazed ceramic fish platter with one cooked whole fish and two small green garnishes; a pair of heartwood billets with deep dark reddish cores and oak bark; a tightly rolled cream parchment grant with red wax seal and gold cord; a wooden walkway tile made of five parallel spaced flat slats over two low crossbattens, with daylight gaps clearly visible. Row 3: a heartwood longbow with deep reddish brown wood, pale bowstring and green binding; a sleeveless heartwood brigandine chest garment made with small overlapping reddish wood plates riveted onto dark leather; two crossed forester throwing axes with rustic oak handles and broad iron heads; two crossed skirmisher throwing axes with slender steel heads, forward points and dark leather-wrapped handles. Warm amber lighting, clean bold silhouettes readable at 36 px, saturated earthy colors, hand-painted material definition, consistent three-quarter view. No cell outlines, no backgrounds, no labels, no letters, no digits, no framing or watermarks, no cast shadows outside the objects. Preserve transparent alpha throughout gutters.

</details>

### Prompt de l’atlas Wild Acres

> Use case: stylized-concept. Create a square 4×4 icon atlas for Wild Acres, an original colorful medieval crafting game. Exactly sixteen separated objects on a transparent backdrop with a strictly regular equal-cell grid, centered at 12.5%, 37.5%, 62.5%, 87.5% on both axes. Each object occupies about 64% of its square and never touches its cell edges. Left to right, top to bottom: row 1 backpack, character chestpiece, open skill book, rolled quest parchment; row 2 folded map, heraldic shield with blank golden pattern, carpenter's workbench, bronze gear; row 3 stone axe, pickaxe, fishing rod, narrow fishing harpoon; row 4 bundle of logs, gray rock, braided rope coil, wheat sheaf. Hand-painted stylized medieval inventory art, warm amber light, bold distinct silhouettes, bright materials and earthy colors, three-quarter view with the same aspect for each object. Clear at a 36 pixel size. All objects completely isolated, true transparent alpha throughout the gutters, no panels, no borders, no frames, no cast shadows outside symbols, no text, no lettering, no numbers, no watermark. Precise atlas cell alignment is essential.
