# X40 · Interface de Wild Acres

Référence avant X40 sur disque `65ce255`. Composition du HUD d’après `images/hud-village-16-9.png`, à 1672 × 941. Les planches du 26/11 et le mammouth gagnant ont guidé le traitement du relief. Les feuillets, les joints et les reflets d’émail sont dessinés avec les primitives Roblox. Les icônes du catalogue et les maquettes de Wild Acres restent les sources du jeu.

## Compte statique

Une pièce est une instance GUI ou un modificateur UI, y compris les coins, traits, dégradés et mises en page. Les comptes du HUD incluent les conteneurs de la zone indiquée. Les fenêtres comptent la garniture ajoutée à leur conteneur, indépendamment des boutons ou lignes que remplit le jeu. Les modèles 3D, leurs caméras, les icônes variables de la carte et les éléments CoreGui du chat sont hors compte. Le budget de 60 pièces par élément est tenu pour la garniture. La grille cartographique de 529 cellules et les 72 repères de boussole préexistaient.

| Élément | Pièces avant | Pièces après | 3 détails ajoutés |
| --- | ---: | ---: | --- |
| Carte du joueur, portrait, vie et endurance, or et étoiles | 39 | 54 | Feuillet derrière le portrait ; anneau miel et joint intérieur turquoise ; médaillons de vie et d’endurance chevauchant les jauges vernies. |
| Boussole et nom du lieu | 86 | 92 | Rail en retrait sous les graduations ; cabochon miel arrondi à 45° ; étiquette du lieu à bord brun sur fond crème. |
| Heure et météo | 7 | 11 | Logement de la météo en émail miel ; joint entre le jour et le temps ; surface parchemin à trois étages de ton. |
| Minicarte, hors marqueurs variables | 542 | 546 | Anneau miel verni ; joint brun à la jonction avec la carte ; boutons ronds et pictogramme de boussole. |
| Colonne du HUD, un bouton PC avec raccourci et pictogramme de secours | 8 | 16 | Pastille d’icône bordée et inclinée ; raccourci sur touche crème ; reflet d’émail qui bouge au survol et à la pression. |
| Commande tactile du menu | 3 | 6 | Contour épais arrondi ; surface miel en relief ; reflet animé au toucher. |
| Notification avec détail | 9 | 13 | Récépissé en relief au coin ; sceau émaillé coloré ; encre foncée sur papier à dégradé. |
| Chat Roblox, trois configurations CoreGui | 0 | 0 | Fond papier pour les messages ; barre de saisie crème plus opaque avec texte brun ; onglets miel et survol clair. |
| Barre rapide, case vide puis case vide sélectionnée | 5 / 8 | 8 / 10 | Raccourci dans son cabochon ; alvéole au vernis chaud ; sélection miel avec joint épais et éclat incliné. |
| Sac, case vide puis case occupée avec pictogramme et quantité | 3 / 5 | 4 / 8 | Cinq pastels de rareté ; pli clair incliné dans le coin ; quantité brune en bas à droite. |
| Emplacement d’équipement, sans puis avec pli (aperçu et état de casse exclus) | 3 / 3 | 4 / 6 | Pli d’angle réservé aux objets ; creux discret lorsque l’emplacement est vide ; couleur de rareté rabattue pour les pièces brisées. |
| Infobulle avec première ligne, hors corps et actions | 6 | 11 | Bandeau teinté à l’encre ; papier satiné à bord arrondi ; titre Fredoka et cartouche rembourré. |
| Bouton plein standard | 3 | 6 | Bord chaud arrondi ; reflet posé de biais ; animation interne qui laisse la zone de clic et de sélection fixe. |
| Cadre standard à titre avec coin et trait déjà présents (sac, fiche, atelier, talents, fiche recette, coffre, boutique, échange, étal, carte des mondes, caserne, poste, commandes du village, clan, carte, tableau, journal des quêtes, conseil, paramètres, livre, chroniques, hôtel des ventes) | 27 | 14 | Feuillet intérieur chevauchant l’ombre basse ; bandeau miel avec joint ; retour de papier à −6° qui interrompt le reflet. |
| Journal des montures, garniture du cadre | 24 | 14 | Fond à feuillets ; bandeau pour le titre redimensionnable ; fermeture circulaire reliée au focus manette. |
| Registres, garniture du cadre | 28 | 15 | Joint brun épais ; bandeau miel déroulé ; bord crème en retrait. |
| Sorts, garniture du cadre | 26 | 16 | Cadre arrondi nouvellement posé ; feuillet derrière les emplacements ; bandeau à joint et retour de papier. |
| Charte et formulaire, garniture de chaque modale | 23 | 15 | Décor reporté sur le panneau centré ; feuille claire derrière les champs ; haut en relief miel. |
| Dialogue, extérieur et garniture de la première ligne uniquement | 6 | 11 | Parchemin arrondi dans la zone de lecture ; nom dans un cartouche miel ; filet chaud entre le cartouche et le papier. |
| Gabarit de sélection commun aux boutons et aux champs | 0 | 3 | Anneau turquoise sombre ; coins arrondis ; filet intérieur qui suit la sélection pendant le défilement. |

## Vérifications et captures

- Sur disque, analyse syntaxique Luau des dix scripts et bancs modifiés, comparaison des ancrages et tailles de référence, contrôle des appels serveur de l’interface et `git diff --check`. Le banc Édition `visuels_x40` vérifie les comptes du HUD, l’ordre de pose des couches, les bornes de rareté et les dimensions réservées sur téléphone.
- Claude reprend les captures avant/après et le banc Édition. Avant, utiliser une copie de la place avec les sources de `65ce255`. Après, appliquer le lot à la même copie. Garder le cadrage, la résolution, l’état du personnage et les données d’exemple identiques. Pour le HUD, capturer à 1672 × 941 avec le chat et les neuf cases visibles. L’aperçu Édition montre le HUD avec des données d’exemple, et le chat se capture en Play. Déposer les paires sous `captures/2026-11-27/x40-avant/` et `captures/2026-11-27/x40-apres/` avec les mêmes noms.
- Capturer une image par écran ou variante, à ouvrir en jeu sur le PC fixe.

| À capturer avant et après | Entrée |
| --- | --- |
| Sac, infobulle avec actions, fiche, apparence, atelier, fiche recette, talents | B, P, onglet Apparence, C, choisir une recette, puis K. |
| Carte, carte des mondes, clan, journal des montures, paramètres, formulaire | M, traversée au port, L, N, O, puis « Écrire à l’équipe ». |
| Journal des quêtes, tableau du village, dialogue, charte | J, tableau de village, habitant, puis utiliser une charte depuis le sac. |
| Coffre, boutique, échange, étal, caserne | Ouvrir un coffre, marchander, lancer un échange, accéder à un étal, visiter la caserne. |
| Poste, courrier, hôtel des ventes, vente, commandes locales et entre joueurs | Ouvrir la poste et ses onglets, l’hôtel des ventes [F] à la boîte aux lettres, puis les deux listes de commandes depuis le tableau ou la poste. |
| Conseil, registre des records, gazette, chefs-d’œuvre, menu joueur, sorts | Conseil de ville, taverne, tableau du village, onglet de la fiche, interaction avec un joueur, puis I. |
| Livre et chroniques des îles | Lire un volume du bestiaire et une page ancienne. |

Au doigt, essayer le menu, le défilement des talents dans les deux axes, un coffre, le clavier du formulaire, la sélection et les trois actions d’un objet du sac. Vérifier portrait et paysage, dont 390 × 844. À la manette, ouvrir le menu avec Select, valider avec A, parcourir une liste plus longue que sa fenêtre, ouvrir une infobulle d’objet et revenir avec B. B doit fermer l’infobulle puis la fenêtre et rendre le focus au menu. Vérifier également la saisie et la fermeture du journal des montures.

## Reconstruction dans Studio en Édition

Démarrer `python tools/sync.py` depuis la racine. Coller ce bloc dans la barre de commande d’une copie Studio. Il contrôle la syntaxe de toutes les sources X40 avant d’en appliquer une.

```lua
local H = game:GetService("HttpService")
local dossier = game:GetService("StarterPlayer").StarterPlayerScripts
local modules = { "ThemeInterface", "Cadre", "ComposantsInterface", "Hud", "MiseEnPage", "WindowNav" }
local clients = { "Interface", "Montures" }
local sources = {}
for classe, noms in { ModuleScript = modules, LocalScript = clients } do
	for _, nom in noms do
		local chemin = "StarterPlayer.StarterPlayerScripts." .. nom
		local source = H:GetAsync("http://127.0.0.1:34873/file?p=" .. H:UrlEncode(chemin))
		local chunk, erreur = loadstring(source, "@" .. chemin)
		assert(chunk, erreur)
		local existant = dossier:FindFirstChild(nom)
		assert(not existant or existant.ClassName == classe, chemin)
		table.insert(sources, { nom, classe, source, existant })
	end
end
for _, entree in sources do
	local nom, classe, source, existant = table.unpack(entree)
	local cible = existant or Instance.new(classe)
	cible.Name, cible.Source, cible.Parent = nom, source, dossier
end
print("X40 · " .. #sources .. " scripts synchronisés")
```

Lancer l’aperçu et le banc dédié.

```lua
local H = game:GetService("HttpService")
local url = "http://127.0.0.1:34873/banc?f="
print(assert(loadstring(H:GetAsync(url .. "hud_apercu")))())
print(assert(loadstring(H:GetAsync(url .. "visuels_x40")))())
```

Lancer ensuite la suite complète et relire son résultat quand elle a terminé.

```lua
local H = game:GetService("HttpService")
print(assert(loadstring(H:GetAsync("http://127.0.0.1:34873/banc?f=tout")))("lourds"))
```

```lua
print(game:GetService("ServerStorage"):GetAttribute("BancTout"))
local apercu = game:GetService("StarterGui"):FindFirstChild("ApercuHud")
if apercu then apercu:Destroy() end
```

## Livraison

X40 est livré sur disque. L’écriture de `.git/index.lock` est refusée par la sandbox. Les commits et les captures restent à intégrer avec les bancs Studio. Le transfert ciblé ci-dessus couvre les huit scripts du lot, y compris le branchement du journal des montures. La carte des fichiers est actualisée pour X40. La fiche cochée reste dans `docs/LOTS.md` pour le passage en Studio.
