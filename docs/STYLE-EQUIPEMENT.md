# Style de l’équipement de Wild Acres

Le sac et l’avatar montrent la même pièce. Lire d’abord sa silhouette à 36 px, puis l’assemblage et la matière. Les formes, les proportions et la garniture servent à distinguer les pièces d’une famille sur fond sombre et sans leur nom. Les couleurs suivent Valdor, avec du bois chaud, des cuirs mats, des fers sombres et des accents plus clairs sur les attaches. [Style des props](STYLE-PROPS.md) · [Style des objets](STYLE-OBJETS.md) · [Index des planches d’origine](PLANCHES-EQUIPEMENT-ORDRE.md)

## Dessiner par famille

| Famille | Silhouette et détail à garder lisibles |
| --- | --- |
| Épées et dagues | Épée longue élancée, épée courte large, espadon à longue prise. Dague ramassée, sabre à tranchant courbe et garde en demi-panier. Distinguer les quillons, la pointe et la gouttière. |
| Armes d’hast et armes de frappe | Fer dans l’axe de la lance, pique plus longue, fer latéral de la hallebarde, croissant de la faux et du fauchard. La hache étend son taillant sur un côté, le marteau montre sa table et son bec, la masse son noyau à ailettes. |
| Armes de tir et de jet | Courbe et corde pour chaque arc. Arc transversal, fût, crosse et noix pour l’arbalète. Empennage du javelot, poche de la fronde, étui ou porte-haches pour les armes groupées. |
| Coiffes | Heaume haut à fente et ventaille, nasal vertical, casque à crête. Capuche ouverte à drapé, cagoule qui couvre le bas du visage, turban enroulé, béret incliné et toque plissée. Couronne ouverte à fleurons, diadème bas, ramure ou plume dans son attache. |
| Torses | Plaques bombées et nervures, maille longue à motif d’anneaux, brigandine à pans rivetés, gambison matelassé, gilet sans manches, chemise à plis et tunique ceinturée. La robe prolonge ses pans au-dessous de la taille. Les lames de cuirasse, écailles et élytres ont des assemblages distincts. |
| Gants, épaules, jambes et pieds | Manches et doigts articulés du gantelet, doigtier court du gant de pisteur, manchette seule du brassard. Coques d’épaule en recouvrement ou à corne. Jambières sur le tibia, chausses en deux jambes et solerets par lames. |
| Capes | Pèlerine courte, mantelet fendu, cape ample et manteau d’apparat long. Montrer le dos, les plis, le galon et l’empiècement. Le fermoir et le col se rejoignent sur l’avatar. |
| Main gauche | Bouclier rond à ombilic, écu en pointe, pavois haut à renfort axial et carapace bombée. La torche montre le bois, l’étoupe et la flamme. Sa lumière portée conserve sa portée de jeu. |
| Bijoux | Anneau ajouré, chevalière à large chaton, bracelet plus large avec fermoir, collier à chaîne et perles, pendentif à bélière, amulette à monture, médaillon frappé et broche à épingle. |
| Accessoires de métier | Reconnaître le carquois par les flèches, la selle par les quartiers et étriers, la fiole par le bouchon, le filet par sa trame, le trousseau par les pannetons et le panier par son anse. |

## Matières, séries et créatures

- Le bois montre une veine ou un assemblage par planches. Le cuir montre une sangle, une ligature ou une couture. Le fer et l’acier portent des surfaces forgées et des arêtes plus claires. Le bronze, le cuivre, l’argent et l’or structurent la monture ou la garniture. L’os reste ivoire et mat avec une pointe ou un condyle. L’écaille chevauche la suivante. Le verre et le givre se lisent par leurs arêtes, leur volume ou leur sertissage.
- Les séries reprennent les couleurs de `GearDesign` et des motifs qui se lisent dans le relief. Soleil rouge porte un disque rayonnant, Lune d’argent un croissant, Garde du pont un écusson, Ronces vertes des branches et des épines, Veille d’hiver des éclats, Reliquaire d’os et Loup gris des dents. Ambre royal reçoit un cabochon et Diamant boréal une monture à facettes.
- Une pièce commune expose son mécanisme. Sur les rangs suivants, les rivets, les garnitures et les sertis prennent davantage de place. Les lueurs légendaires sont de petits reflets attachés à une pierre. La torche emploie des volumes mats colorés et une lumière sur l’étoupe portée.
- Une prise est installée là où on comprend sa fonction. Les crocs pendent au collier, les griffes jaillissent de la bride d’un gantelet, les écailles se recouvrent sur le torse et les élytres forment des plaques. Une défense ou une corne est cerclée sur la hache, une membrane prolonge la capuche, une plume est prise dans sa ligature et le venin chemine de la garde au tranchant. Par espèce, faire varier la taille, le nombre, l’orientation ou la monture en plus de la teinte.

## Modèle et rendu porté

`GearDesign` choisit la forme et la finition à partir de la pièce, de sa série et de sa prise dans `Prises`. `GearVisuals` construit la géométrie autour de points d’attache communs. Le modèle de la miniature utilise la posture de référence R15. Le rendu porté soude chaque volume au membre qu’il suit. Pour les gants, les épaulières, les jambières à plaques et les bottes, la miniature montre une des deux pièces pour qu’elle occupe la case. Les chausses montrent les deux jambes reliées à la ceinture.

L’arc, l’arbalète et l’arme longue se portent au dos, les autres à la ceinture, et le gantelet griffu sur la main droite. Le bouclier est attaché à l’avant-bras gauche, la torche à la main gauche. L’anneau se porte sur un doigt, le bracelet au poignet et la broche près de l’épaule. La cape équipée donne sa couleur au dos. La cape de noblesse paraît lorsque cet emplacement est libre.

Le HUD cadre les huit coins de la boîte du modèle dans une vue de trois quarts. La petite arme bénéficie d’une diagonale. Une pièce tirée dans une autre rareté est reconstruite avec son rang courant. Les clés des 694 entrées de l’index d’origine sont conservées, y compris les anciennes clés d’emplacement et de nom. Le catalogue courant ajoute neuf entrées à cet index.

Budgets de **25** pièces par miniature et **30** par pièce portée, paire comprise. Les pièces visibles de la miniature se rejoignent. Les pièces portées sont soudées, sans masse ni collision. Le banc refuse une composante détachée, un dépassement de budget et tout `Neon` hors lueur légendaire discrète. Les emplacements, `visual`, les recettes et les statistiques restent ceux du jeu.

Sur disque, les 703 clés et 2 664 variantes de rareté ont été contrôlées avec des instances simulées. Le catalogue monte à 24 pièces en miniature et à 28 pièces portées. L’essayage simulé couvre les dix emplacements, la lumière de la torche, le déséquipement et la cape de noblesse.

## Génération et contrôle en mode Édition

Démarrer `python tools/sync.py`. Synchroniser ces six modules depuis le disque avec la commande suivante. Elle vérifie que toutes les sources compilent avant d’écrire dans Studio.

```lua
local h = game:GetService("HttpService")
local paths = {
	"ReplicatedStorage.Shared.GearDesign",
	"ReplicatedStorage.Shared.Gear",
	"ReplicatedStorage.Shared.GearVisuals",
	"ServerScriptService.Systemes.Avatar",
	"ServerScriptService.Systemes.Tools",
	"StarterPlayer.StarterPlayerScripts.Hud",
}
local sources = {}
for _, path in paths do
	local source = h:GetAsync("http://127.0.0.1:34873/file?p=" .. h:UrlEncode(path))
	assert(loadstring(source, "=" .. path))
	sources[path] = source
end
for _, path in paths do
	local parent = game
	local names = string.split(path, ".")
	for i = 1, #names - 1 do parent = assert(parent:FindFirstChild(names[i]), path) end
	local name = names[#names]
	local module = parent:FindFirstChild(name) or Instance.new("ModuleScript")
	module.Name, module.Source, module.Parent = name, sources[path], parent
end
```

Lancer la régénération. L’attribut `ServerStorage.BancVisuelsEquipement` donne le résultat. Le dossier précédent reste disponible jusqu’à la fin de la validation.

```lua
task.spawn(function() local s = game:GetService("ServerStorage"); s:SetAttribute("BancVisuelsEquipement", "en cours"); local ok, r = pcall(function() return assert(loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34873/banc?f=visuels_equipement")))() end); s:SetAttribute("BancVisuelsEquipement", ok and r or "ÉCHEC\n" .. tostring(r)); if ok then print(r) else warn(r) end end)
```

Poser six mannequins équipés par `Avatar.refresh`. Tourner autour pour voir les fixations au dos, le tombé des capes et les attaches de bouclier. Supprimer `Workspace.PlancheEquipementPorte` après les captures.

```lua
task.spawn(function() print(assert(loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34873/banc?f=visuels_equipement")))("avatar")) end)
```

Rephotographier avec les faces visibles. Remplacer `1` par le numéro de page. Le banc retourne l’index trié actualisé. Supprimer `Workspace.PlancheMiniatures` après les captures.

```lua
local view = assert(loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34873/banc?f=visuels_equipement")))(1); workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(table.unpack(view.camera)), Vector3.new(table.unpack(view.look))); print(view.noms)
```

Sur le PC fixe, vérifier les pièces à 36 px dans le sac, la fiche et l’atelier avec plusieurs fonds et sans légende. Sur le R15, regarder les transitions de marche, les manches sous les épaulières, les bottes sur les chausses, la torche dans une grotte et les dégagements de l’arc, de la cape et du bouclier. [Code partagé](../src/ReplicatedStorage/Shared/GearVisuals.lua) · [Banc](../tools/bancs/visuels_equipement.luau)
