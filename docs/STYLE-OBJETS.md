# Style des miniatures de Wild Acres

Une miniature doit se reconnaître sans nom dans une case de 36 px du sac, de la barre rapide ou de l’atelier. La caméra voit la face utile, un côté et le dessus. L’objet occupe la case sans couper ses extrémités.

## Masse, structure et détail

1. **Masse.** Donner à chaque objet son contour utile. Le cadenas montre son anse, le panier son ouverture et le bois son bout de coupe. Deux variantes se distinguent par un contour, un assemblage ou un ornement qui reste visible en petit.
2. **Structure.** Montrer comment l’objet tient et à quoi il sert. Une poignée rejoint ses attaches, les pieds rejoignent le meuble et la garniture repose dans le plat. Limiter les petits éléments à ce qui rend l’objet identifiable.
3. **Détail.** Faire ressortir la croûte, les cernes, un poinçon, un rivet ou une couture. Employer le bois pour le bois, le métal pour les ferrures, le tissu pour les étoffes, le verre pour les contenants et l’ardoise ou la roche pour les matières minérales. Réserver le `Neon` aux parties qui représentent une lueur.

Compter de 6 à 25 pièces pour un objet dessiné à la main. Les pièces de construction suivent la géométrie du bloc que le joueur pose. Les miniatures sont centrées, avec leur dessous ramené au sol. Relier chaque composant à la masse, y compris les garnitures et les effets visibles. Regrouper les éléments qui doivent être lus ensemble, par exemple les branches dans une ligature et les baies dans une coupelle.

## Repères par famille

| Famille | Silhouettes et matières |
| --- | --- |
| Nourriture | Croûte dorée, mie, garniture ou coupe visible. Dans un plat, montrer le liquide et les ingrédients à sa surface. Une éventuelle vapeur fine part du plat. |
| Matières | Minerai sur gangue, lingots biseautés et estampés, rondins écorcés avec leurs cernes, fibres liées ou tissées. |
| Objets de valeur et reliques | Sceau, monture, pierre, métal ou rupture de forme lisible. Les symboles reproduisent l’identité de l’objet. |
| Outils, jouets et instruments | La partie active domine le contour. Les attaches et les matériaux expliquent l’usage, comme les cordes du luth ou les mâchoires d’un crochet. |
| Mobilier et ateliers | Lire la façade et les appuis. Dégager les ouvertures des abris, le vide entre les rayons d’une roue et les jambes d’un meuble. |
| Graines | Sachet et spécimen identifiable de la plante, comme un épi, une carotte ou une grappe. |
| Livres | Reliure, fermoir et emblème du métier ou du contenu en relief. |
| Écrits | Sceau et ruban, contours distincts pour une lettre, une carte, un plan ou un contrat. |
| Potions et fioles | Forme de flacon par effet, liquide translucide, bouchon et étiquette. |
| Teintures | Récipient de pigment et échantillon visible. |
| Âmes de boss | Orbe ou cristal qui reprend un trait du boss, comme sa couronne ou sa carapace. |
| Prises de créatures | Croc, griffe, plume, écaille, corne ou autre partie identifiable de la créature. |

Les sept dernières familles sont produites par [le banc de Claude](../tools/bancs/visuels_objets_familles.luau), à la fin de la génération des objets.

## Relecture des captures d’origine

Les identifiants suivent la grille 8 × 6, de gauche à droite puis de haut en bas. Les planches 04 et 05 servent de référence pour la géométrie de pose des pièces qu’elles couvrent. [Ordre des planches](PLANCHES-OBJETS-ORDRE.md)

| Planche | Observation et réponse dans les miniatures |
| --- | --- |
| 01 | Les premières âmes se répètent en éclats. Le sac à dos `backpack` et le jus `apple_juice` ont besoin de repères d’usage. Le premier gagne un rabat et une poche sanglés, le second garde son motif de pomme. L’artefact `artifact` reçoit une monture à griffes. |
| 02 | Le bloc de verre, les rondins et les briques se lisent surtout comme des cubes de couleur. Les arêtes du verre, les lames assemblées et le parement donnent différents reliefs. L’arc et la spirale gardent leur géométrie de pose. |
| 03 | Plusieurs échelles ressemblent à des cages. La miniature montre deux montants et quatre ou huit barreaux. Les dalles, poteaux et linteaux reçoivent des chants, assises ou veinures. |
| 06 | La plupart des contenants se reconnaissent déjà. Le coffre `chest` prend un fermoir et des bandes, le panier et la bourse se distinguent par leur anse ou leur cordon. Les légumes cuits montrent leur garniture. |
| 07 | La trousse `craft_kit` manque de prise et la tourte `meat_pie` ressemble à une tarte. La trousse porte une poignée, la tourte un couvercle bombé avec évents. La toile enchantée reçoit des motifs tissés. |
| 08 | Les petits volumes colorés en haut correspondent aux poissons `fish` et `fish_1` à `fish_7`, d’après l’index. La teinture `dye` est en planche 07. Les poissons prennent des corps, nageoires et queues propres. Les bols montrent leur garniture, les minerais leur gangue et les lingots leur poinçon. |
| 09 | L’encrier `inkwell` et le coffret `jewel_box` ressemblent à des boîtes. Rebord et creux pour le premier, fermoir et monture de pierre pour le second. La gelée, les gemmes et les métaux ont des matières distinctes. |
| 10 | Cadenas et livres se confondent. Le loquet montre sa traverse de bois, la serrure de cuivre un pêne, le fer une anse haute et la serrure à secret une rosace. La sacoche et la bourse ont des contours différents. |
| 11 | Les encadrements du parc et de la palissade passent au premier plan. Les rondins montrent leur coupe. Le miroir, la boussole et l’assiette se distinguent par le manche, l’aiguille ou le creux. |
| 12 | Fioles et prises se répètent. La serrure d’entraînement montre son socle et son étau. Le pot `pot` garde un corps large à lèvre marquée. |
| 13 | La planche est dédiée aux prises `prise_*`. Les bâtons, éclats et os trop proches se vérifient sur les nouvelles silhouettes du banc de Claude. |
| 14 | Les prises ont des orbites, épines et segments de profil proche. Vérifier sur les nouvelles planches la distinction entre crocs, dards et cornes. |
| 15 | Les prises occupent les premières rangées. Le rouleau de provisions, les coutures du sac et la garniture de la ration donnent des repères supplémentaires aux derniers objets. |
| 16 | Un ruban et plusieurs sceaux se lisent comme des disques. Les pans du ruban et l’empreinte du sceau les distinguent. La relique prend une taille de pierre fracturée. |
| 17 | Les sachets de graines se répètent sur plusieurs rangées. L’étagère, les lingots et la soupe qui suivent gagnent une structure ou une garniture distincte. |
| 18 | Les aliments ronds et le mobilier perdent leurs petits signes d’usage. Les marches, le cadre de table et les marques de cuisson donnent des repères propres aux objets. |
| 19 | Plusieurs ouvertures se lisent comme des panneaux, les outils courts comme des tiges. Les poignées et huisseries marquent la façade. Le moulin garde ses ailes et le puits son seau suspendu. |

## Régénérer depuis le disque

Avec `python tools/sync.py` en marche, lancer cette ligne dans la barre de commande de Studio en mode Édition.

```lua
task.spawn(function() local s = game:GetService("ServerStorage"); s:SetAttribute("BancVisuelsObjets", "en cours"); local ok, r = pcall(function() return assert(loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34873/banc?f=visuels_objets")))() end); s:SetAttribute("BancVisuelsObjets", ok and r or "ÉCHEC\n" .. tostring(r)); if ok then print(r) else warn(r) end end)
```

Le banc charge le module sur disque, construit les modèles par identifiant, applique les finitions puis exécute le banc des familles. Les outils équipés utilisent leur dossier `IconesOutils`. Les anciennes miniatures du sac sont restaurées si un modèle du périmètre principal échoue. Le rapport compte les pièces visibles et totales, contrôle les tailles, vérifie les contacts avec des boîtes orientées et repère le `Neon` sans nom de lueur, flamme ou braise.

`ServerStorage.BancVisuelsObjets` donne le résultat. `ServerStorage.BancVisuelsObjetsFamilles` liste les écarts du lot de Claude, dont le cas éventuel de `seed_sack`. Le banc des graines exclut expressément cet identifiant. La génération conserve son modèle précédent quand il existe.

Pour la relecture photo, reprendre le nouvel ordre renvoyé par le banc des planches. La façade des miniatures du sac est du côté `-Z`. Regarder aussi une sélection sans noms à 36 px avec l’angle du HUD, notamment les serrures, sacs, plats, outils et herbes. [Banc de planches](../tools/bancs/planche_miniatures.luau) · [Cadrage du HUD](../src/StarterPlayer/StarterPlayerScripts/Hud.lua)
