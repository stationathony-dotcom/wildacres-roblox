# Wild Acres — inventaire de l’interface (20/11/2026)

Relevé dans le code (`StarterPlayerScripts`), pour l'étape 20 du plan. Tout est construit en
`ScreenGui` ; le HUD a sa propre échelle (proportions de l'image cible, `Hud.scaleFor`).

## HUD permanent (`Hud.lua`)
| Zone | Contenu |
|---|---|
| Haut-gauche | portrait, nom, écusson d'honneur, barres vie / endurance, or, étoiles et prime |
| Haut-centre | boussole (suit la caméra), nom du lieu |
| Haut-droite | jour / heure / météo, minicarte (lieux, filons et plantes repérés selon la compétence) |
| Gauche | colonne de boutons : Sac, Personnage, Compétences, Journal, Carte, Clan, Atelier, Paramètres |
| Bas-centre | barre rapide 9 cases (icônes 3D, barre d'usure des outils) |
| Bas-gauche | chat Roblox (onglets Général, Commerce, Clan, Groupe) |
| Bas-droite | notifications empilées |
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
| Journal (offres sur place et progression des quêtes actives) | J | Quetes.client |
| Carte du monde (régions découvertes) | M | Carte.client |
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
| Tableau d'affichage (activités, concours) | invite au marché / taverne | Activites.client |
| Conseil du village (élection, projets, budget) | invite à la chapelle | Conseil.client |
| Caserne (recrues, solde et quatre ordres pour les soldats à portée) | invite | Interface |
| Mini-jeux (apprivoiser, crocheter…) | selon l'action | Interface |

## Autres commandes

- Souris : clic gauche pour attaquer ou utiliser l’outil, clic droit pour sélectionner une cible. Maintenir le clic gauche prolonge la récolte visée.
- Clavier : E interagir, R action secondaire, Q tout ramasser,
  G lâcher ce qu'on porte, X descendre de cheval, H siffler sa monture, Maj courir, 1-9 barre rapide.
- Manette : stick gauche cliqué = courir, gâchette droite = attaquer ou utiliser l’outil, X / Y = invites.
- Chat : `/aide` liste les commandes des joueurs (`/coince`, `/signaler`, `/ceder`, `/louer`,
  `/commande`, `/livrer`, `/demonter`, `/autoriser`, `/bloquer`…).

## Audio et contrôles en Play

Les nouveaux sons utilisent les effets gratuits de Pro Sound Effects distribués par le Creator Store.
[Documentation des assets audio Roblox](https://create.roblox.com/docs/audio/assets).

Le plugin Rojo déclare 203785492 comme son de notification. Son module de préchargement rassemble les URI des images et des sons dans la même liste et les passe à ContentProvider:PreloadAsync. Studio envoie alors une requête de texture pour « Pop Close Sound ». Cette déclaration est dans le plugin installé. [Table des assets de Rojo](https://github.com/rojo-rbx/rojo/blob/master/plugin/src/Assets.lua).
