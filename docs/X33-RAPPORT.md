# X33 — Miniatures des objets du sac

La grille de lecture est celle du concours du mammouth. Les grandes masses se recouvrent, la patine passe du joint sombre à un relief clair, puis le bord se rompt sur un côté. Le reflet est lié à la matière de l’objet. Les ajouts sont faits sur les miniatures du sac et leurs sources de génération en Édition. [Méthode « niveau planche »](DIRECTION-ARTISTIQUE.md#3-méthode-niveau-planche-2611-tirée-du-concours-du-mammouth) · [Règles de style](STYLE-OBJETS.md)

## Compte statique des pièces

Le compte inclut chaque `BasePart`. Les couples de valeurs d’une même ligne suivent l’ordre des exemples. Les plages couvrent les variantes générées. Un zéro indique l’absence de dessin dans le générateur précédent.

| Élément | Pièces avant | Pièces après | 3 détails ajoutés |
| --- | --- | --- | --- |
| Ressources brutes • rondin, laine, fibre | 18 / 9 / 21 | 21 / 12 / 24 | Fente d’écorce ou ourlet sombre, lame d’aubier ou relief de fibre clair, extrémité déchirée. |
| Roches et minerais • pierre, fer brut, cuivre brut, roche lumineuse | 6 / 7 / 8 / 6 | 9 / 10 / 11 / 9 | Joint de gangue, crête claire inclinée, cassure en biseau sur un seul bord. |
| Lingots • fer, or, acier | 10 / 12 / 7 | 13 / 15 / 10 | Repli de coulée sombre, filet laminé clair, ébarbure décentrée. |
| Pains et pâtisseries • pain, tourte, gâteau au miel | 7 / 7 / 6 | 10 / 10 / 9 | Fente de cuisson, lèvre dorée, croûte fendue en surplomb. |
| Plats • soupe, ragoût, poisson grillé | 9 / 10 / 11 | 12 / 13 / 14 | Sillon sur le bouillon ou le poisson, relief clair sur la garniture ou l’arête, herbe ou éclat sur le côté. |
| Flacons de potion, d’élixir et de remède | 6–7 | 12–13 | Pied et épaulement du moule, ménisque clair et reflet du verre, étiquette gaufrée à coin relevé avec signe du remède. |
| Bouteilles, jarres et teintures • bouteille, message en bouteille, encrier, teinture | 6 / 7 / 6 / 6 | 9 / 10 / 9 / 9 | Joint sombre du contenant, étiquette claire ou croûte de pigment, coin relevé ou écaillé. |
| Graines et sachets | 12–23 | 15–23 | Gueule froncée sur un corps incliné, rabat clair, bord de toile relevé. Les graines de céréales conservent trois épis après suppression d’un grain répété sur chacun. |
| Sac de graines `seed_sack` | 0 | 9 | Soufflet irrégulier, bouche froncée avec lien de chanvre, écusson à graine brodée. |
| Plantes • blé, lin, menthe, camomille | 19 / 22 / 9 / 22 | 22 / 22 / 12 / 22 | Repli sombre du limbe, nervure éclairée, pointe en coin. Le lin et la camomille reprennent le budget des pétales répétés. |
| Prises de créatures `prise_*` | 5–10 | 8–13 | Sillon sombre sur la prise, crête claire, éclat ébréché. Le croc, la plume et la carapace conservent chacun leur contour. |
| Âmes de boss `ame_*` | 5–10 | 8–13 | Ombre interne de l’orbe, croissant clair de verre, saillie du reflet au bord de la sphère. |
| Trophées de boss errants • langue, leurre, défense, plume, soie, peau | 0 / 0 / 0 / 0 / 0 / 0 | 6 / 8 / 7 / 7 / 8 / 9 | Masse repliée ou en plaques, reflet contrasté, signe du boss. Le leurre porte une lueur captive et la défense une corniche de givre. |
| Outils du sac • scie à main, ciseau, faucille, filet | 12 / 7 / 9 / 19 | 15 / 10 / 12 / 22 | Joint sombre du renfort, dos poli, biseau de la pièce active. |
| Chaîne, nasse et engrenages | 24 / 24 / 25 | 24 / 25 / 25 | Joint du renfort, dos poli, biseau. Les maillons, le col d’osier et la couronne gardent leurs silhouettes avec moins de segments. |
| Outils équipés • dossier `IconesOutils` | 4–16 dans la sauvegarde de référence | Jusqu’à 25, dont 3 pièces de finition | Appui sombre, bande polie et bord biseauté sur la tête de l’outil. La bêche a une lame plus étroite dans le sac. |
| Parchemins, lettres, cartes et contrats | 4–10 | 7–13 | Pli sombre du vélin, revers clair, déchirure qui déborde du bord. |
| Livres, manuels et grimoires | 12–15 | 18–21 | Cartouche sombre et galon en relief, coin de couverture usé, tranche de pages et fermoir décentrés. |
| Bijoux • bague, collier, talisman | 12 / 12 / 12 | 15 / 15 / 15 | Creux de la gravure, filet du métal clair, pointe de filet interrompue sur un bord. |
| Gemmes • diamant, rubis, émeraude, cristal ancien | 6 / 8 / 6 / 6 | 9 / 11 / 9 / 9 | Facette profonde, facette miroir claire, éclat prismatique incliné. |
| Matériaux de construction • 952 variantes fabriquées | 1–13 | 4–16 | Joint de parement, chant clair et éclat oblique. La taille et la forme de pose viennent de la configuration du bloc. |
| Objets de quête • artefact, fragment de ruine, sceau royal, couronne perdue | 7 / 6 / 6 / 16 | 10 / 9 / 9 / 19 | Creux de l’empreinte, contour en relief, pointe brisée du sceau ou de la monture. |
| Montures • œufs et rênes | 0 / 0 | 9 / 15 | Coquille avec calotte et mouchetures en relief. Rênes avec patte, chape métallique et mors. |
| Mobilier et décors copiés • 85 miniatures du catalogue | 8–25 | 11–25 | Joint sombre, chant dégagé et éclat du chant sur la face utile. La copie retient au plus 22 pièces de la source. |
| Scierie | 0 dessin propre | 12 | Chevalets asymétriques, lame circulaire à moyeu sombre et dents claires, planche à déligner inclinée. |

## Vérification locale

La syntaxe des quatre sources Luau modifiées a été contrôlée. Les instances simulées ont couvert les 1 805 objets du sac, dont 952 formes de construction et 85 copies de décors du catalogue. Après raccordement, les contrôles de centrage, de taille, de connexité et de budget ont relevé zéro écart. Le banc Édition doit encore contrôler les copies des outils du fichier de place et les deux dossiers reconstruits. Claude fera la lecture des silhouettes et des reflets à 48 px sur les captures.

## Reconstruction dans Studio en mode Édition

Depuis la racine du dépôt, lancer le pont dans un terminal.

```powershell
python tools/sync.py
```

Synchroniser les sources depuis la barre de commande de Studio, puis attendre la fin.

```lua
local H = game:GetService("HttpService")
print(assert(loadstring(H:GetAsync("http://127.0.0.1:34873/banc?f=pousser")))())
```

Reconstruire le sac et les outils. Attendre le résultat de `BancVisuelsObjets` dans `ServerStorage`. L’attribut `BancVisuelsObjetsFamilles` doit afficher `OK`.

```lua
task.spawn(function()
	local H = game:GetService("HttpService")
	local SS = game:GetService("ServerStorage")
	SS:SetAttribute("BancVisuelsObjets", "en cours")
	local ok, rapport = pcall(function()
		return assert(loadstring(H:GetAsync("http://127.0.0.1:34873/banc?f=visuels_objets")))()
	end)
	SS:SetAttribute("BancVisuelsObjets", ok and rapport or "ÉCHEC\n" .. tostring(rapport))
	if ok then print(rapport) else warn(rapport) end
end)
```

Afficher la première planche. Changer le numéro de planche pour la suite et employer `"IconesOutils"` pour les outils. La relecture à 48 px se fait avec l’angle et le cadrage du sac.

```lua
local H = game:GetService("HttpService")
local planche = assert(loadstring(H:GetAsync("http://127.0.0.1:34873/banc?f=planche_miniatures")))
local p = planche("IconesObjets", 1)
local cible = Vector3.new(table.unpack(p.look))
workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(p.camera[1], p.camera[2], 2 * cible.Z - p.camera[3]), cible)
print(p.noms)
```
