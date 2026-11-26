# Wild Acres — direction artistique et grille de vérification (25/11)

Demande du propriétaire : « que le jeu ait de l'envergure », « un design abouti, de même pour les menus,
base-toi sur des RPG connus, Minecraft, sandbox… ». Exemples fournis : `Downloads\Gmail(2)` (Eggoria, un RPG
d'épée fait avec Claude, planches de créatures voxel et 7 planches de boss signées @shulckerbox).

**Les planches servent d'inspiration de style. On ne copie aucun dessin.** Chaque créature de Wild Acres garde
son propre nom, sa propre silhouette et ses propres couleurs (règle 9 d'`AGENTS.md`).

## 0. Diagnostic (Play du 25/11, graine 7, PC fixe)

| Ce qu'on voit | Ce que montrent les exemples |
| --- | --- |
| 130 créatures sur 8 formes. Le griffon et la wyverne-boss font 8 pièces chacun et ont la même taille. Le géant de glace est un avatar grossi. | Chaque créature a sa silhouette. Les blocs sont empilés, avec 4 à 6 couleurs et 1 couleur qui brille (yeux, cristaux, fissures). Les boss font 3 à 5 fois la taille d'un avatar. |
| Île plate aux bords carrés, horizon vide, brume bleue qui délave tout | Grandes falaises en terrasses, cascades, sommets qui ferment l'horizon, arbres colorés selon leur essence |
| Boss sans mise en scène | Boss avec repaire, entrée filmée, attaques annoncées et apparition animée des sbires |
| Menus fonctionnels mais plats : panneaux sombres unis | Cadres travaillés, onglets par catégorie, poupée d'équipement, fiche d'objet riche |

Il ne manque pas de systèmes : ~75 systèmes serveur, plus que dans l'exemple « Day #5 ». Il manque **ce qu'on voit**.

## 1. Principes tirés des jeux de référence

### Créatures (chantier A)
- **La silhouette passe avant le détail.** Une créature doit se reconnaître à sa silhouette seule, à la
  distance de jeu, avant même les couleurs ([RocketBrush, shape language](https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent)).
- **La forme dit le comportement.** Une créature lourde et massive se lit comme lente et solide, une créature
  fine et pointue comme rapide et dangereuse ([RMCAD](https://www.rmcad.edu/?p=87816),
  [Game Tyrant](https://gametyrant.com/news/why-great-video-game-monsters-are-recognizable-at-a-glance)).
- **Les rôles se distinguent à l'œil.** Un tank, un tireur et une bête de meute ne doivent pas se ressembler.
- **Casser la silhouette** avec des cornes, des crêtes, des cristaux ou des vides
  ([Creative Bloq, 15 tips](https://www.creativebloq.com/features/15-tips-for-better-creature-design)).
- Application : une **famille par biome**, avec une palette commune et une lueur propre (glace : blanc, bleu
  pâle et lueur cyan ; désert : ocre et or ; braise : basalte noir et fissures orange ; forêt : mousse, écorce
  et fleurs ; grottes : pierre grise et cristaux violets ; marais : olive, vase et lueur vert poison).

### Monde (chantiers B et D)
- **Repères visibles de loin.** Disney appelle « weenie » un repère qui sert de boussole. Un bon repère a
  une forme qui tranche avec son entourage et se place en hauteur. Dans Zelda BotW, les tours et les sanctuaires
  se voient de très loin, grâce à leur forme et à leurs couleurs lumineuses
  ([Game Developer, taxonomie des weenies](https://gamedeveloper.com/design/a-taxonomy-of-weenies-the-landmarks-that-define-i-ghost-of-tsushima-i-),
  [GMTK](https://gmtk.substack.com/p/how-nintendo-solved-zeldas-open-world),
  [UX Collective, sanctuaires](https://uxdesign.cc/shrine-design-in-zelda-breath-of-the-wild-f3b1093469cf)).
  Ces repères respectent la règle 1 : ils montrent des lieux, sans indiquer où aller.
- **Le relief cache et révèle.** Dans BotW, les reliefs en triangle cachent puis dévoilent les lieux
  ([Nintendo Life](https://www.nintendolife.com/news/2017/10/zelda_breath_of_the_wilds_ingenious_design_is_all_about_triangles_apparently)).
  Une île plate montre tout d'un coup et ne garde aucune surprise.

### Boss (chantier C)
- **Annoncer chaque attaque** par un grand geste, une couleur et un son, pour que le joueur ait le temps de
  réagir et d'apprendre ([Game Developer, telegraphing](https://gamedeveloper.com/design/enemy-attacks-and-telegraphing),
  [Wayline](https://www.wayline.io/blog/crafting-legendary-boss-battles)).
- **Des phases vraiment différentes**, pas seulement plus rapides. L'arène peut changer en même temps que le
  boss ([Game Developer, structure des boss](https://www.gamedeveloper.com/design/boss-battle-design-and-structure),
  [molbv, phases](https://molbv.github.io/blog/2025-07-08-boss-phases.html)).
- **La taille de l'arène décide des attaques.** Une grande arène appelle des attaques à distance
  ([UX Collective, Wukong](https://uxdesign.cc/how-to-design-an-early-boss-fight-wandering-wight-boss-in-black-myth-wukong-6ec8408d06e0)).
- Application à Wild Acres : pas de texte à l'écran (règle « pas de messages »). Tout passe par une zone
  marquée au sol, une lueur et un rugissement.

### Menus (chantier E, couloir Codex)
- **Fiche personnage** : la poupée d'équipement entourée de ses emplacements, comme le « paper doll » de WoW,
  issu des RPG papier ([Warcraft Wiki](https://warcraft.wiki.gg/wiki/Character_sheet)).
- **Sac** : une grille d'icônes. On reconnaît l'objet à son icône et sa rareté à la couleur du liseré, sur le
  code de couleurs popularisé par WoW. Le détail n'apparaît qu'au survol
  ([Abratabia, inventory UI](https://www.abratabia.com/game-ui-design/inventory-ui.php)).
- **Ne pas tout montrer.** Trop d'informations peuvent bloquer une décision simple (Jeff Liu, designer
  d'interface chez Blizzard). La refonte Dragonflight visait une interface dégagée et réglable
  ([indieklem](https://indieklem.substack.com/p/12-what-you-can-learn-from-the-ui),
  [Blizzard](https://news.blizzard.com/en-us/article/23837944/get-into-the-grid-of-things-with-the-updated-ui-and-hud)).
- **Façon Minecraft** : sur mobile, l'artisanat passe dans son propre onglet
  ([thèse McMaster](https://macsphere.mcmaster.ca/bitstream/11375/19764/2/Manivanna%202013%20-%20Guidelines%20for%20Visual%20Scale%20Design%20-%20Minecraft%20Analysis.pdf)).
  Gestes déjà connus des joueurs : clic droit = moitié ou un seul, Maj + clic = tout transférer.
  Le tri du sac est la demande qui revient le plus ([étude UX](https://sites.google.com/view/pat-yimtae/personal-ux-project/redesign-minecraft-inventory)).
- **Valheim** : les refontes par la communauté (Auga, SeneaL UI) redessinent toutes les fenêtres
  (sac, coffres, établi, construction, carte) **dans un seul cadre commun**
  ([Auga](https://github.com/RandyKnapp/Auga), [SeneaL UI](https://thunderstore.io/c/valheim/p/seneaL/SeneaL_UI/)).
  Les critiques portent sur un sac pénible à parcourir ([gamepressure](https://gamepressure.com/newsroom/valheim-equipment-and-quick-slot-mod-fixes-inventory-management/z02dfd)).
- Application : **un seul cadre médiéval** (bois sombre, coins en fer, titre sur bandeau), des onglets en
  icônes, la fiche d'objet façon WoW (nom coloré par rareté, type, effet, prix), le tri du sac, et un écran
  d'accueil où la caméra survole l'île en direct.

## 2. Grille de vérification « de A à Z »

**État au 25/11 soir** (Claude) — coché = vérifié par banc et/ou capture en Play sur le PC fixe ; captures dans
`captures/2026-11-25/`. Restent ouverts, avec la raison :
- A6 (animations en marche) et A8 (FPS avec 40 créatures) : à mesurer en Play réel, à plusieurs ;
- B2, B3, B4, B6 : le relief de l'île n'a PAS été changé (tirage publié : sauvegardes et ids de props) ; à la place, l'horizon
  montre le reste de l'île et des massifs au large (B5). Un vrai relief neuf = nouvelle version du générateur (gen 3), pour les
  nouveaux mondes seulement : décision du propriétaire ;
- C6 : butin inchangé dans le code, banc `butin_creatures` vert, mais pas rejoué en Play ;
- D2 (brume selon l'heure) : météo allégée seulement ; D3 (lanternes la nuit) : existait déjà (`Clock.setLamp`), pas recapturé ;
- E1–E6 : couloir Codex (passage écrit dans `docs/LOTS.md`).

Un chantier n'est fini que si **chaque ligne** est vérifiée et notée (date, comment : banc, capture en Play,
mesure). Seul le propriétaire coche « testé en Play ».

### A. Créatures
- [x] A1 Toutes les créatures du bestiaire et toutes celles d'`Enemies` se construisent sans erreur (banc `creatures_voxel`)
- [x] A2 Aucune créature n'a la même liste de pièces qu'une autre : silhouettes distinctes (banc : empreinte par créature)
- [x] A3 Les yeux ou les points lumineux sont en `Neon` et chaque créature a au plus 7 couleurs (banc)
- [x] A4 Les boss mesurent au moins 2,5 fois la hauteur d'un avatar ; les créatures normales restent entre 0,5 et 2 fois (banc)
- [x] A5 Budget de pièces : une créature normale ≤ 90 pièces, une élite ≤ 140, un boss ≤ 260 (banc)
- [ ] A6 Les animations d'`Enemies` marchent toujours : pattes, ailes, queue, tête et parties nommées (Play : capture en marche et en attaque)
- [x] A7 Planche de capture : une rangée par biome, photographiée en Play et rangée dans `images/bestiaire/`
- [ ] A8 Performance : pas de chute de FPS mesurable avec 40 créatures chargées (`/wa perf`)

### B. Relief et horizon
- [x] B1 Le rng de `RegionPlan` n'est pas touché : banc `generation` vert, mêmes ids de props avant et après
- [ ] B2 Chaque île a un sommet visible depuis n'importe quelle plage (capture depuis 4 plages)
- [ ] B3 Les côtes ne sont plus droites : aucun segment de rivage droit de plus de 40 studs (banc)
- [ ] B4 Au moins une cascade de plus de 25 studs par île montagneuse (banc + capture)
- [x] B5 Des silhouettes d'îles lointaines à l'horizon, sans collision et sans coût serveur (capture)
- [ ] B6 Les villages, parcelles, ports et donjons restent accessibles à pied (banc : chemin entre lieux)

### C. Boss
- [x] C1 Chaque boss a un repaire reconnaissable de loin (lueur, forme) : capture depuis 150 studs
- [x] C2 L'entrée en combat se fait sans texte : caméra, rugissement et secousse côté client, à voir en Play
- [x] C3 Chaque attaque spéciale est marquée au sol au moins 0,8 s avant de frapper (banc sur les délais)
- [x] C4 Au moins 2 phases différentes par boss, avec un changement visible (banc + Play)
- [x] C5 Les sbires sortent de terre de façon animée (Play)
- [ ] C6 Butin, trophées et pièces légendaires inchangés (banc `butin_creatures`)

### D. Végétation et ambiance
- [x] D1 Au moins 4 essences d'arbres colorées par biome, et l'abattage marche toujours (règle 6 : `Recoltable`)
- [ ] D2 La brume suit l'heure et la météo, et le ciel n'est plus délavé à midi (captures à 9 h, 13 h, 19 h, 23 h)
- [ ] D3 Les lanternes de village s'allument la nuit (capture à 23 h)
- [x] D4 Pas de repousse automatique (règle « monde fini ») : banc `bosquets`

### E. Menus (couloir Codex, passage écrit dans `docs/LOTS.md`)
- [ ] E1 Toutes les fenêtres partagent le même cadre (bois, fer, bandeau de titre) : capture de chaque fenêtre
- [ ] E2 Fiche d'objet façon WoW dans le sac, la boutique, le coffre et l'hôtel des ventes
- [ ] E3 Tri du sac (par type, rareté, valeur) ; Maj + clic = tout transférer vers le coffre
- [ ] E4 Écran d'accueil où la caméra survole l'île en direct
- [ ] E5 Mobile : chaque fenêtre utilisable au doigt (Device Simulator : téléphone et tablette)
- [ ] E6 Aucune fenêtre ne masque le HUD de façon permanente, et le HUD n'est pas regrossi (règle 11)

## 3. Méthode « niveau planche » (26/11, tirée du concours du mammouth)

Concours du 26/11 (`tools/concours/`, sujet dans `SUJET.md`) : trois mammouths de givre sur le même cahier des charges.
Classement du propriétaire : **Codex Sol > Codex Astra > Claude**. Ce qui a fait gagner `sol_mammouth.luau` :

1. **Sculpter par masses anatomiques qui se chevauchent** (ventre, cage, épaules, garrot, dos, reins, croupe), pas un
   gros bloc avec du décor collé dessus. La silhouette vient du chevauchement.
2. **Positions réglées à la main**, pas de tirage aléatoire ; petites **asymétries voulues** (pattes de tailles proches
   mais différentes, mèches décalées).
3. **Chaque détail en 3 étages de ton** : masse (moyen) + relief (clair) + pointe (sombre), légèrement **inclinés**
   (2 à 7°) pour casser la grille.
4. **Manteau continu puis déchiré** : la matière de surface (givre, mousse, rouille) couvre le sommet d'un seul tenant,
   puis se défait en corniches et retombées sur les flancs.
5. **Pièces nommées** (« Mèche de flanc », « Corniche gelée du pied ») : relecture et retouche faciles.

Défauts relevés chez les perdants : bosse en dalle plate (« toit »), coulures régulières en peigne, mèches toutes de
même taille, cristaux fins et hauts plutôt que trapus.

Toute nouvelle créature ou tout nouveau prop suit ces 5 points, et chaque lot visuel est livré avec une **capture Studio**.
