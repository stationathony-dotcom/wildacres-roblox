# Wild Acres — inventaire de l'interface (18/11/2026)

Relevé dans le code (`StarterPlayerScripts`), pour l'étape 20 du plan. Tout est construit en
`ScreenGui` ; le HUD a sa propre échelle (proportions de l'image cible, `Hud.scaleFor`).

## HUD permanent (`Hud.lua`)
| Zone | Contenu |
|---|---|
| Haut-gauche | portrait, nom, écusson d'honneur, barres vie / endurance, or, étoiles et prime |
| Haut-centre | boussole (suit la caméra), nom du lieu |
| Haut-droite | jour / heure / météo, minicarte (lieux, filons et plantes repérés selon la compétence) |
| Gauche | colonne de boutons : Inventaire, Personnage, Compétences, Quêtes, Carte, Clan, Atelier, Paramètres |
| Bas-centre | barre rapide 9 cases (icônes 3D, barre d'usure des outils) |
| Bas-gauche | chat Roblox (onglets Général, Commerce, Clan, Groupe) |
| Bas-droite | notifications empilées |
| Mobile | bouton de course 🏃 |

## Fenêtres (ouvertes par touche, bouton ou invite)
| Fenêtre | Touche / accès | Fichier |
|---|---|---|
| Sac (grille, onglets, tri, infobulles, actions) | B / Tab | Interface |
| Personnage (équipement, caractéristiques, compétences, collections, titres, apparence) | P | Interface |
| Talents | K | Interface |
| Atelier (grille 3×3, carnet de recettes, stations à portée) | C | Interface |
| Clan (membres, grades, coffre, journal) | L | Interface |
| Construction libre (formes × matériaux, fantôme, rotation) | V | Interface |
| Quêtes (offres au tableau / chez un habitant, quêtes en cours) | J | Quetes.client |
| Carte du monde (régions découvertes) | M | Carte.client |
| Paramètres | O | Interface |
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
| Caserne (recrues, solde) | invite | Interface |
| Mini-jeux (apprivoiser, crocheter…) | selon l'action | Interface |

## Autres commandes
- Souris : clic gauche pour attaquer ou utiliser l’outil, clic droit pour sélectionner une cible. Maintenir le clic gauche prolonge la récolte visée.
- Clavier : E interagir, R action secondaire, Q tout ramasser,
  G lâcher ce qu'on porte, X descendre de cheval, H siffler sa monture, Maj courir, 1-9 barre rapide.
- Manette : stick gauche cliqué = courir, gâchette droite = attaquer ou utiliser l’outil, ButtonX / ButtonY = invites.
- Chat : `/aide` liste les commandes des joueurs (`/coince`, `/signaler`, `/ceder`, `/louer`,
  `/commande`, `/livrer`, `/demonter`, `/autoriser`, `/bloquer`…).
