# Vérification des props de Wild Acres

Phase 1 du 21 novembre 2026. Relecture des planches du catalogue, des captures de contrôle et des deux images de Valdor. Le rendu cible repose sur des silhouettes lisibles, du bois brun et mat, de la pierre, des étoffes sobres et une lueur ambrée concentrée dans les lanternes et les foyers. La capture de jeu montre aussi les proportions des clôtures et des potences à hauteur de personnage. [Image cible](../Aventure%20%C3%A0%20Valdor%20dans%20Wild%20Acres.png) · [HUD de Valdor](../images/hud-village-16-9.png)

Les captures datent de passes différentes. Le relevé indique ce qu’on voit sur chaque planche et précise quand le code actuel ou une planche plus récente confirme une évolution. Une vignette recadrée masque la hauteur de pose. [Audit des objets](AUDIT-VISUELS-OBJETS.md) · [Relecture précédente](RELECTURE-PLANCHES-VISUELLES.md)

## Props posables et décor

| Priorité | Prop | Écart visible | Planche |
| --- | --- | --- | --- |
| Identité | Grande échelle et échelle courte en bois, rondins ou fer | Le volume en treillis triangulé se lit comme un pylône. Les deux échelles de corde et de bois figurées à côté montrent bien les barreaux qu’on cherche. | [Construction 3](../images/catalogue/01-construction-03.png) · [Construction 6](../images/catalogue/01-construction-06.png) |
| Identité | Grille en fer et barrières en bois ou en fer | Panneaux pleins dans l’aperçu. Les montants et les vides de la herse voisine rendent sa fonction immédiatement lisible. | [Construction 1](../images/catalogue/01-construction-01.png) · [Construction 3](../images/catalogue/01-construction-03.png) |
| Identité | Roue à eau | Disque de bois presque plein, avec peu de lecture des pales. `ARCH.roue` construit encore le disque plein. | [Construction 5](../images/catalogue/01-construction-05.png) |
| Identité | Toit de chaume et toit d’étage | La galette de chaume aux rives plates ressemble à un tapis. La couverture et la rive existent dans le modèle, qui place volontairement son toit au-dessus du pivot. | [Mobilier 2](../images/catalogue/02-mobilier-et-decor-02.png) · [Mobilier 3](../images/catalogue/02-mobilier-et-decor-03.png) |
| Identité | Étable, écurie, bergerie | Petits volumes fermés dans les vignettes, de silhouette presque identique. Les ouvertures, litières et signes d’usage restent à montrer. Étable et écurie utilisent toutes deux `ARCH.cabane`. | [Cuisine et ferme 1](../images/catalogue/04-cuisine-et-ferme-01.png) · [Cuisine et ferme 4](../images/catalogue/04-cuisine-et-ferme-04.png) |
| Identité | Torche murale | Tige fine terminée par un carré orange. Il manque l’attache au mur et le volume de la tête. La lanterne murale ajoutée depuis demande sa propre capture. | [Mobilier 3](../images/catalogue/02-mobilier-et-decor-03.png) |
| Identité | Horloge mécanique | Le petit cadran est presque invisible sur le meuble sombre. L’horloge se confond avec l’armoire sur les planches. | [Mobilier 1](../images/catalogue/02-mobilier-et-decor-01.png) · [Mobilier 2](../images/catalogue/02-mobilier-et-decor-02.png) |
| Identité | Métier à tisser | Cadre de bois avec une petite bande claire. La chaîne et le tissu en cours de fabrication se lisent mal. | [Mobilier 2](../images/catalogue/02-mobilier-et-decor-02.png) |
| Identité | Caisse, coffret, coffre et coffre de transport | Les silhouettes rectangulaires se répètent et les signes distinctifs se perdent en petit. La caisse clouée et le coffre renforcé se reconnaissent mieux grâce à leur assemblage et à leur cerclage. | [Mobilier 1](../images/catalogue/02-mobilier-et-decor-01.png) |
| Identité | Nasse, panier en osier, paniers et caisses de denrées | La nasse a le même profil fermé qu’une caisse. Le panier en osier manque d’anse et de motif tressé. Les caisses et le panier de légumes montrent peu leur contenu. | [Savoir et loisirs 2](../images/catalogue/06-savoir-et-loisirs-02.png) · [Matières 3](../images/catalogue/03-matieres-et-outils-03.png) · [Alchimie et commerce 1](../images/catalogue/05-alchimie-et-commerce-01.png) |
| Style | Chaudron | Disque vert très lumineux sur un bol sombre. Le liquide utilise `Neon`, tandis que le foyer a sa propre lumière. Vérifier le liquide en Édition avant de reprendre la couleur. | [Mobilier 1](../images/catalogue/02-mobilier-et-decor-01.png) |
| Style | Drapeau, bannière et bannière de clan | L’étoffe du drapeau lit comme une petite feuille blanche autour d’un poteau presque invisible. Les deux bannières paraissent étroites sur la planche. Il faut revoir l’angle puis la surface d’étoffe affichée. | [Mobilier 1](../images/catalogue/02-mobilier-et-decor-01.png) · [Bannière de clan](../images/catalogue/05-alchimie-et-commerce-01.png) |
| Style | Pot de terre cuite et jardinière | Le pot ressemble à une motte surmontée d’une boule verte. Le code actuel du pot de catalogue dessine un corps, un rebord et de la terre. La jardinière reste une caisse garnie de trois boules. Demander de nouvelles vues en situation. | [Mobilier 2](../images/catalogue/02-mobilier-et-decor-02.png) |
| Construction | Escalier droit, mur courbe, rondins et panneaux de verre | Les marches droites et la courbe sont masquées par l’angle. Les variantes en rondins se lisent comme du bois plein. Le verre ressemble à un panneau opaque. | [Construction 1](../images/catalogue/01-construction-01.png) · [Construction 2](../images/catalogue/01-construction-02.png) · [Construction 4](../images/catalogue/01-construction-04.png) |
| Construction | Échelle de corde, pont-levis et trappe | Les barreaux de corde se lisent, mais les points de fixation et l’épaisseur des ferrures des pièces mobiles se perdent à cette échelle. | [Construction 5](../images/catalogue/01-construction-05.png) · [Construction 6](../images/catalogue/01-construction-06.png) |
| Décor | Clôture, potence à lanterne et blé de Valdor | La capture de jeu rend le blé très cubique et uniforme, avec des masses presque continues. La cible montre des épis et des tiges. Le poteau brun fonctionne dans les deux vues, mais la cage de la lanterne et sa liaison sont beaucoup plus lisibles dans la cible. | [HUD de Valdor](../images/hud-village-16-9.png) · [Image cible](../Aventure%20%C3%A0%20Valdor%20dans%20Wild%20Acres.png) |

L’enclume, l’alambic de catalogue, le tonneau et l’étal se reconnaissent dans les vignettes. Les nouvelles formes et variantes de matière, les captures voisines de terrain et certains objets du décor de village demandent un relevé dédié. [Planches du mobilier](../images/catalogue/02-mobilier-et-decor-01.png) · [Catalogue et atlas du 21/11](../images/catalogue/README.md)

## Miniatures du sac à contrôler en marge des props

| Miniatures | Observation et état | Planche |
| --- | --- | --- |
| Osselets (`dice`) | Deux dés à points dans la capture, alors que l’objet est devenu un jeu d’adresse en os. Forme d’osselets corrigée sur disque, nouvelle capture à prendre. | [Savoir et loisirs 1, case 25](../images/catalogue/06-savoir-et-loisirs-01.png) |
| Cartes et documents, ruban de compétition | Carte, contrat, billet et lettre montrent les mêmes traits sur un rouleau. Le ruban se lit comme une pile de papier ou de tissu. | [Savoir et loisirs 1](../images/catalogue/06-savoir-et-loisirs-01.png) · [Savoir et loisirs 2](../images/catalogue/06-savoir-et-loisirs-02.png) |
| Appâts, anguille, chou, melon, courge, tartes et tourte | Les appâts semblent être des graines. L’anguille reste courte. Les légumes côtelés et les trois tartes se confondent à petite taille. Le poisson fumé évoque encore une cale de bois sur la capture détaillée. | [Cuisine et ferme 1](../images/catalogue/04-cuisine-et-ferme-01.png) · [Cuisine et ferme 3](../images/catalogue/04-cuisine-et-ferme-03.png) · [Cuisine et ferme 4](../images/catalogue/04-cuisine-et-ferme-04.png) · [Contrôle matières et cuisine](../images/catalogue/10-matieres-et-cuisine.jpg) |
| Graines, fil, cuir souple, crochet et hameçon | Étiquettes de graines proches avec signes très petits. Les deux fils partagent leur bobine et le cuir souple ressemble à une planche. Crochet et hameçon ont le même petit fer coudé. | [Cuisine et ferme 2](../images/catalogue/04-cuisine-et-ferme-02.png) · [Matières 2](../images/catalogue/03-matieres-et-outils-02.png) |
| Bijoux, fioles et herbes | Anneaux de commerce trop proches entre eux, tubes de fioles et bouquets d’herbes répétitifs. | [Alchimie 1](../images/catalogue/05-alchimie-et-commerce-01.png) · [Alchimie 2](../images/catalogue/05-alchimie-et-commerce-02.png) · [Butin 5](../images/catalogue/07-butin-et-reliques-05.png) · [Butin 8](../images/catalogue/07-butin-et-reliques-08.png) |

Les captures de contrôle confirment que les viandes, engrenages, coiffes et principales silhouettes d’armes ont déjà reçu une reprise. Les planches de butin et d’équipement montrent surtout des répétitions de séries. Les plastrons de cœur, colliers de crocs, talismans et massues d’os restent suivis dans la relecture des miniatures. [Contrôles 9 à 11](../images/catalogue/README.md) · [Relecture des planches](RELECTURE-PLANCHES-VISUELLES.md)

## Correctifs sur disque

- La traverse de `Cat_big_table` rejoint les pieds. Les têtes et les pieds des lits ainsi que `Cat_vase_deco` touchent le sol. Les volumes de `Cat_sculpture` se rejoignent. La toile du drapeau laisse passer le joueur. Les pièces génériques s’appellent `Élément`.
- La fleur de `Cactus` rejoint son sommet. Celles de `Pot_Fleurs` rejoignent leurs tiges, qui partent du terreau. Les pépites de `Filon_Or` sont en métal doré mat. Pour mettre à jour des modèles retouchés dans Studio, reporter les trois corrections sur les pièces existantes. [Source des modèles](../src/ServerStorage/OutilsDev/ConstruireModeles.lua)
- La forme des osselets est partagée entre la génération des miniatures à l’initialisation et le banc de finitions. En Édition, après synchronisation, `require(game.ServerStorage.OutilsDev.ConstruireModelesMiniatures:Clone()).identites(game.ReplicatedStorage)` actualise l’ensemble des miniatures d’identité. [Source des miniatures](../src/ServerStorage/OutilsDev/ConstruireModelesMiniatures.lua) · [Générateur de planches](../tools/bancs/visuels_finitions.luau)

## Phase 2 · Tri des 105 signalements d’Édition

Le tableau reprend les deux sections du rapport du 21/11. Plusieurs lignes du banc sont regroupées quand elles ont la même cause. Total : **76 défauts**, **29 écarts voulus**. Les nombres d’éléments avant correction viennent du rapport. Les nouveaux nombres sont mesurés sur les constructeurs sur disque. [Rapport d’Édition](RAPPORT-BANC-PROPS.md)

| Prop | Défaut signalé | Vrai / voulu | Correction |
| --- | --- | --- | --- |
| `Cat_arched_window`, `Cat_round_window`, `Cat_stained_glass` | Trois fenêtres suspendues de 1,05 à 1,60 stud (3). | Vrai | `Catalogue.apply` leur attribue `grid = "cell"`. `Shop.place` les centre sur la case et `World.buildDeco` prend la hauteur du terrain. Deux montants portent chaque vitrage à sa hauteur. |
| `Cat_shutter` | Deux battants séparés et suspendus à +1,80 stud (3). | Vrai | Même pose au centre d’une case. Les battants sont reliés par deux traverses et deux montants. |
| `Cat_curtain`, `Cat_tapestry`, `Cat_painting_wall` | Rideau, tenture et tableau suspendus de 0,30 à 1,80 stud. Quatre étoffes minces avec collision (7). | Vrai | Ces objets se posent eux aussi sur une case. Tringles sur montants, tableau sur pieds, étoffes et motifs traversables. |
| `Cat_wall_lantern` | Bas à +2,55 studs (1). | Voulu | `Equilibre` lui attribue `wallMount = true`. `Shop.place` la décale de 0,30 stud vers le joueur, au bord de la case et contre la face du mur. Le banc exige la hauteur prévue de 2,55 studs. |
| `Cat_bread_oven`, `Cat_candle`, `Cat_press`, `Cat_trophy` | Bas sous le pivot de 0,10 à 0,80 stud (4). | Vrai | Dôme remonté, axes des cylindres corrigés pour le bougeoir et le pressoir, pied du trophée au plan du sol. |
| `Cat_palisade` | Bas à +2,15 studs, cinq têtes et une traverse éloignées des pieux (7). | Vrai | Pieux réellement verticaux. Chaque tête recouvre son pieu et la traverse les relie. |
| `Cat_sled` | Patins à +0,20 stud, séparés du plateau de 0,40 stud (3). | Vrai | Patins au sol et quatre jambes jusqu’au plateau. |
| `Cat_water_pump` | Poignée et bec séparés de 0,50 et 0,20 stud (2). | Vrai | Le cylindre vertical monte jusqu’à la poignée et au bec. |
| `Cat_hearth` | Quatre pierres espacées de 0,19 stud (4). | Voulu | Pierres indépendantes en cercle. Le banc reconnaît leur nom et vérifie qu’elles touchent le sol. |
| `Cat_cauldron` | Liquide en `Neon` (1). | Vrai | Liquide vert en verre, foyer émissif avec sa lumière. |
| `Cat_candelabra` | Deux des trois flammes éloignées de l’unique lumière (2). | Voulu | Les trois flammes restent émissives. Chacune porte désormais un tiers de la luminosité d’origine. |
| `Cat_desk`, `Cat_wood_crane` | Document et corde minces avec collision (2). | Vrai | Document et corde traversables. |
| `Alambic` | Serpentin et fiole sans appui (2). | Vrai | Le tuyau rejoint le col, le serpentin repose sur son support et le bec débouche au-dessus de la fiole posée sur le socle. |
| `Bac_Tannage`, `Enclume` | Cuve à −0,50 stud et billot à −0,10 stud (2). | Vrai | Corrigé l’axe vertical des deux cylindres en conservant le niveau de leur surface de travail. |
| `Boutique`, `Maison_C`, `Bureau_Sherif` | Lanternes isolées de 6,027, 5,871 et 3,287 studs (3). | Vrai | Suspentes prises dans les entraits qui rejoignent les deux murs. Les enseignes de la boutique et du shérif rejoignent aussi leur façade. |
| `Auberge`, `Maison_A`, `Maison_B`, `Taverne` | Cinq lanternes à 0,95 stud du plafond (5). | Vrai | Suspentes métalliques fixées au plafond. |
| `Auberge`, `Ecurie`, `Forge`, `Taverne` | Quatre enseignes à 0,20 stud de leur potence (4). | Vrai | Fixation métallique sur chaque enseigne et potences ancrées dans la façade ou le poteau de l’écurie. |
| `Taverne` | Quatre bancs séparés de 0,40 stud du plancher (4). | Vrai | Deux pieds par banc. |
| `Moulin_Village` | Épi séparé du toit de 0,40 stud (1). | Vrai | Épi emboîté dans l’anneau supérieur. |
| `Ruine` | Lierre et pan de toit détachés (2). | Vrai | Lierre ramené sur le mur et chevron en appui sous la couverture. |
| `Champ_Ble`, `Tableau_Quetes` | Botte isolée de 0,625 stud et caisse isolée de 0,40 stud (2). | Voulu | Elles reposent au sol à côté de la clôture et du tableau. Le banc vérifie le pied de chacune. |
| `Champ_Ble`, `Sol_Laboure` | Terre à −0,20 et −0,10 stud (2). | Voulu | Le bas de la terre rejoint le terrain, les sillons restent en surface. |
| `Chateau`, `Puits`, `Embarcadere` | Fondations à −17, −1,10 et −1 stud (3). | Voulu | Socle du château prévu pour une pente. L’embarcadère a des pieux sous le plan d’eau. Le puits garde son ancrage de −1,10 stud avec une fondation distincte, une margelle ronde ouverte, l’eau visible et le seau suspendu au treuil. |
| `Filon_Charbon`, `Filon_Cuivre`, `Filon_Fer`, `Filon_Or`, `Rocher` | Roche ancrée à −0,40 stud (5). | Voulu | Les roches émergent du terrain. Le banc mesure toujours leur profondeur. |
| `Filon_Or` | Six pépites `Neon` (6). | Vrai | Métal mat de phase 1 appliqué par le constructeur ciblé. Le rapport mesurait encore l’ancien modèle stocké. |
| `Roseaux`, `Touffe` | Sept tiges ou brins isolés et deux bases enterrées ou immergées (9). | Voulu | `RegionPlan` pose les roseaux au niveau de l’eau. Les tiges stockées descendent d’environ un demi-stud sous la surface. Les brins de la touffe repartent de la terre. Le banc exige que chaque pied retrouve l’eau ou le sol. |
| `Chapelle`, `Tour_Guet` | Deux cierges et un brasero éclairent sans flamme ni braise visible (3). | Vrai | Flammes sur les cierges et braises dans le brasero. Les lumières ont une source visible. |
| `Feu_Camp` | Lumière portée par une pièce invisible (1). | Voulu | La flamme est rendue par l’effet `Fire`. Le banc reconnaît ce porteur s’il a bien un feu actif. |
| `Auberge`, `Boutique`, `Maison_A`, `Maison_B`, `Maison_C`, `Taverne` | Modèles coûteux (6). | Vrai | Moins de colombages, de solives, de fleurs ou de bocaux selon le modèle. **282 → 238**, **163 → 140**, **263 → 217**, **261 → 215**, **154 → 134**, **297 → 250** respectivement. Les gabarits extérieurs mesurés sont conservés. |
| `Bureau_Sherif`, `Chapelle`, `Forge` | Modèles coûteux (3). | Vrai | Encadrements de pierre simplifiés et un barreau doublé retiré. **75 → 67**, **74 → 67**, **65 → 57**. |
| `Chateau`, `Moulin_Village` | Modèles coûteux (2). | Vrai | Créneaux et anneaux de toits moins nombreux. Trois lattes par aile du moulin, qui garde son animation. **237 → 193** et **70 → 58**. |
| `Champ_Ble` | 201 pièces (1). | Vrai | **110 pièces**, avec une forme d’épis inclinée par touffe et moins de piquets de clôture. Les 88 modèles `Touffe` conservent leur ordre de récolte. |
| Variantes `Construction/*` | Pièces nominales parfois prises pour des alertes lors de la lecture de l’inventaire. | Voulu | Dans ce rapport, elles figurent sous `MESURES`. Le banc compare toujours les trois axes. Il attend la saillie des volets de 0,10 stud et le diamètre mesuré de 3,71 studs pour les anneaux du toit conique. Une dalle de 4 × 0,5 × 4 ou un mur de 4 × 4 × 0,5 à sa cote reste une mesure. |

## Reconstruction et banc en Édition

Après synchronisation de `src`, exécuter la reconstruction ciblée. Elle régénère ces 20 modèles stockés : `Alambic`, `Auberge`, `Bac_Tannage`, `Boutique`, `Bureau_Sherif`, `Champ_Ble`, `Chapelle`, `Chateau`, `Ecurie`, `Enclume`, `Filon_Or`, `Forge`, `Maison_A`, `Maison_B`, `Maison_C`, `Moulin_Village`, `Puits`, `Ruine`, `Taverne`, `Tour_Guet`. Reporter au besoin les retouches manuelles faites dans Studio sur ces modèles. Les `Cat_*` concernés sont générés par le catalogue à la pose et au chargement de la région.

```lua
local source = game:GetService("ServerStorage").OutilsDev.ConstruireModeles:Clone(); require(source).propsPhase2(); source:Destroy()
```

Avec `python tools/sync.py` déjà lancé et les sources synchronisées, exécuter en Édition cette ligne Luau.

```lua
assert(loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34873/banc?f=visuels_props")))()
```

Lire ensuite l’attribut texte `ServerStorage.BancVisuelsProps`. `VERT` signifie zéro signalement et aucune erreur de lecture des références. Le rapport donne ensuite le nombre d’objets inspectés, les signalements par gravité et l’inventaire des mesures. Les modèles stockés sont clonés, les `Cat_*` sont générés par le catalogue et chaque variante forme × matière passe par `Batir` avec une région temporaire. Le banc garde ses références et ses clones hors du DataModel. [Banc](../tools/bancs/visuels_props.luau)

- Le gabarit des constructions vient de `BUILD_SHAPES`. Le banc compare les trois axes et vérifie le bas visible par rapport au plan sous le pivot centré. Pour les modèles stockés, le gabarit vient de `TailleAttendue` si cet attribut existe, puis de la géométrie régénérée par la source dans un dossier isolé. Les autres modèles stockés et les `Cat_*` sont comparés à une plage indicative du plus grand axe.
- Un écart de plus de 0,10 stud au bas prévu remonte. Le toit de chaume hérité et la lanterne murale gardent chacun une hauteur attendue. Les lumières nocturnes et les fenêtres de village gardent leur marquage pour `Clock`. Les budgets de pièces des bâtiments complexes et du champ correspondent aux modèles allégés.
- L’écart de 0,15 stud est mesuré entre boîtes orientées. Les objets ronds, en coin et les maillages peuvent présenter un vide supplémentaire. Sur les planches, vérifier aussi les éléments posés à même le terrain et les assemblages séparés qui ont leur propre support. Les heuristiques de couleur, de nom de pièce, de collision et de transparence servent à choisir les modèles à regarder en premier.
- Les nouveaux objets muraux, les décors générés directement dans le monde et les modèles sans capture récente restent à regarder en situation. Vérifier en particulier la pose des échalas, gouttières, lucarnes, volets et caillebotis dont les anciennes planches ne montrent pas les modèles actuels.

Le contrôle local sur 161 modèles simulés a confirmé les 20 cibles de reconstruction, les appuis des éléments réparés et les 88 touffes du champ. Claude doit encore synchroniser les scripts, reconstruire les modèles stockés, relancer ce banc et `tools/bancs/tout.luau` en Édition, puis commiter. En Play sur le PC fixe, regarder les façades, les éléments suspendus, la pose des fenêtres, le blé récoltable et le rendu nocturne. Les captures de phase 1 à reprendre couvrent notamment les échelles, toits, roues, bâtiments d’élevage et les osselets à la taille d’une case du sac.
