# Wild Acres — inventaire de l’interface (21/11/2026)

Relevé dans le code (`StarterPlayerScripts`), pour l'étape 20 du plan. Tout est construit en
`ScreenGui` ; le HUD a sa propre échelle (proportions de l'image cible, `Hud.scaleFor`).

## HUD permanent (`Hud.lua`)
| Zone | Contenu |
|---|---|
| Haut-gauche | portrait, nom, écusson d'honneur, barres vie / endurance, or, étoiles et prime |
| Haut-centre | boussole (suit la caméra), nom du lieu |
| Haut-droite | jour / heure / météo, minicarte (lieux, filons et plantes repérés selon la compétence) |
| Gauche | colonne de boutons : Sac, Personnage, Compétences, Journal, Carte, Clan, Atelier, Paramètres |
| Bas-centre | barre rapide 9 cases, icônes peintes si publiées, miniatures 3D ou pictogrammes, usure des outils |
| Bas-gauche | chat Roblox (onglets Général, Commerce, Clan, Groupe) |
| Bas-droite | notifications, gains identiques regroupés et alertes de danger prioritaires |
| Mobile | bouton Menu, barre rapide et actions tactiles autour du pouce |

## Navigation

| Commande | Ouvrir | Revenir |
|---|---|---|
| Clavier et souris | Cliquer dans la colonne ou utiliser le raccourci du tableau | Reprendre le raccourci, cliquer sur × ou appuyer sur Échap |
| Tactile | Appuyer sur Menu, puis sur la destination | Appuyer sur × |
| Manette | Appuyer sur Affichage / Select, choisir avec la croix directionnelle et valider avec A | Appuyer sur B pour revenir de la fenêtre au premier plan |

Sur téléphone, le sac fait défiler ses catégories horizontalement. La fiche Personnage et l’atelier empilent leurs sections. Les fenêtres qui contiennent une saisie remontent au-dessus du clavier virtuel.

## Fenêtres
| Fenêtre | Touche / accès | Fichier |
|---|---|---|
| Sac (grille, onglets, tri, infobulles, actions) | B / Tab | Interface |
| Personnage (équipement, caractéristiques, compétences, collections, titres, apparence) | P | Interface |
| Compétences et talents | K | Interface |
| Atelier (grille 3×3, recherche et fiche de recette avec stock, station et compétence) | C | Interface |
| Clan (membres, grades, coffre, journal) | L | Interface |
| Construction libre (formes × matériaux, fantôme, rotation) | V | Interface |
| Journal (offres sur place, quêtes actives et journal d’absence) | J | Quetes.client |
| Carte du monde (régions découvertes, repères et lit) | M | Carte.client |
| Paramètres (sons, flashs, secousses, caméra, souris, graphismes, texte et formulaire d’équipe) | O | Ambiance.client |
| Dialogue PNJ (choix courts) | invite « Parler » | Interface |
| Boutique du marchand, rachat | dialogue → « Voir la boutique » | Interface (`shop`) |
| Commandes du village | dialogue marchand | Interface (`orders`) |
| Banque de village | dialogue marchand | Interface |
| Coffre (le sien, d'un autre : vol) | invite | Interface (`chest`) |
| Étal de vente | invite | Interface (`stall`) |
| Poste : courrier + hôtel des ventes | boîte aux lettres | Interface (`post`) |
| Échange direct entre joueurs | invitation | Interface (`trade`) |
| Groupe | liste des joueurs → inviter | Interface (`group`) |
| Tableau d’affichage (activités, concours de dressage et d’élevage) | invite au marché / taverne | Activites.client |
| Conseil du village (élection, projets, budget) | invite à la chapelle | Conseil.client |
| Caserne (recrues, solde et quatre ordres pour les soldats à portée) | invite | Interface |
| Mini-jeux (apprivoiser, crocheter…) | selon l'action | Interface |

## Carte, arrivée et retour

La minicarte indique les environs. La carte du monde [M] affiche les régions découvertes et cinq types de repères personnels. Choisir un type dans la légende, puis un point sur la carte. À la manette, déplacer le curseur avec le stick gauche et valider avec A. La liste permet de sélectionner et de retirer un repère. Ces repères suivent le monde où ils ont été posés.

À l’arrivée, l’enseigne, la lueur de la forge et la fumée du four servent de repères sur place. Les rangées de couleurs de la création du personnage défilent sur petit écran. À la reconnexion, la carte affiche « Mon lit » quand le monde fournit sa position. Dans le journal [J], « Journal d’absence » permet de relire les événements du monde courant après les notifications de retour.

La carte met en cache les cases déjà dessinées et actualise sa position lorsqu’elle est ouverte. Le sac charge les miniatures visibles au défilement.

## Construction et objets à portée

Les pièces affichent un fantôme avant la pose. Le mode construction indique les commandes de pose, de rotation, de retournement et de reprise selon l’entrée active. Les refus de pose apparaissent près du fantôme ou du panneau. Tenir le panneau de propriété affiche le périmètre et le prix de la case visée.

| Entrée | Poser | Tourner | Retourner | Reprendre | Annuler |
| --- | --- | --- | --- | --- | --- |
| Clavier et souris | Clic | R | Z | X | V |
| Tactile | Poser | Tourner | Inverser | Reprendre | Annuler |
| Manette | RT | RB | LB | X | B |

Près d’une culture, l’invite indique son état de pousse et son arrosage. Le survol des machines et des coffres indique leur état à portée. L’infobulle de la torche indique qu’elle éclaire les grottes lorsqu’elle est équipée en main gauche.

Les miniatures du mobilier reprennent les modèles posés, dont la lanterne murale. Les planches peintes couvrent les menus, les formes de construction, la bride, la selle de guerre et une sélection d’équipements, de matières et de meubles. La liste des fichiers à publier et leurs correspondances figurent dans le dossier des icônes. [Planches d’icônes](../images/icones/README.md) · [Catalogue des miniatures 3D](../images/catalogue/README.md).

## Autres commandes

- Souris : clic gauche pour attaquer ou utiliser l’outil, clic droit pour sélectionner une cible. Maintenir le clic gauche prolonge la récolte visée.
- Clavier : E interagir, R action secondaire, Q tout ramasser,
  G lâcher ce qu'on porte, X descendre de cheval, H siffler sa monture, Maj courir, 1-9 barre rapide.
- Manette : stick gauche cliqué = courir, gâchette droite = attaquer ou utiliser l’outil, X / Y = invites.
- Chat : `/aide` liste les commandes des joueurs (`/coince`, `/signaler`, `/ceder`, `/louer`,
  `/commande`, `/livrer`, `/demonter`, `/autoriser`, `/bloquer`…).

## Audio et contrôles en Play

Les candidats audio de la deuxième vague sont issus de la bibliothèque Pro Sound Effects du Creator Store. Le réglage « Ambiance et bruitages » contrôle la pluie, le vent, le tonnerre, la grotte et les effets ponctuels. Les sabots suivent le déplacement au sol de la monture du joueur. Les sons de pose, de casse, de serrure et de cloche se jouent à la position transmise par le serveur.
[Documentation des assets audio Roblox](https://create.roblox.com/docs/audio/assets).

Le plugin Rojo déclare 203785492 comme son de notification. Son module de préchargement rassemble les URI des images et des sons dans la même liste et les passe à ContentProvider:PreloadAsync. Studio envoie alors une requête de texture pour « Pop Close Sound ». Cette déclaration est dans le plugin installé. [Table des assets de Rojo](https://github.com/rojo-rbx/rojo/blob/master/plugin/src/Assets.lua).

## Captures et validation

À vérifier en Studio / Play. Poser puis retirer un repère après reconnexion. Rouvrir la carte pour
contrôler le lit et consulter le journal après les notifications de retour. Essayer un refus de pose,
la parcelle sur une pente et les états au survol. Vérifier la miniature de lanterne, les icônes après
publication, les sept sons et les mesures de carte et du sac. [Parcours en Play](TEST-PLAY.md).

Les captures de référence permettent de comparer les proportions du HUD, la lisibilité et les
silhouettes. [HUD au village](../images/hud-village-16-9.png) · [Planches du catalogue](../images/catalogue/README.md).
