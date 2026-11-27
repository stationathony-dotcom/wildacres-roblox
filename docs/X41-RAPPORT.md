# X41 — Fenêtres des systèmes du 27/11

## Livré

| Accès dans le jeu | Affichage et actions |
| --- | --- |
| Sorts [I] ou menu du HUD | `sorts`, puis `sort { id, target }`. Cinq emplacements, recharge en secondes, Maj droite + 1–5 au clavier et sélection des sorts au doigt ou à la manette. Geste de lancer et cinq effets locaux déclenchés après confirmation. |
| Conseil du village | Royaume, suzerain, vassaux et part des taxes. Pour le maire, `pol_allegeance { v, to }` pour prêter allégeance et `pol_allegeance { v }` pour la rompre. |
| Poste, onglet Commandes | `contrats`, `contrat_publier { item, n, prix }` depuis le sac, `contrat_livrer { id }` et `contrat_retirer { id }` sur ses commandes. |
| Tableau des quêtes, onglet Gazette | `gazette`, `gazette_ecrire { titre, texte }` et `gazette_retirer { id }`. Articles sur papier, rédaction limitée à 60 et 600 caractères. |
| Entrée de la taverne | `records` ouvre le registre. Dans les titres de la fiche [P], un succès secret affiche « ??? » sans progression jusqu’à son obtention. |
| Joueur à portée [U] et fiche [P] | `mariage_demande { target }`, réponse `mariage_oui` et confirmation de `divorce`. La fiche lit le nom du conjoint et le jour du mariage dans `Inventory.conjoint` dès que le serveur les transmet. |
| Fiche [P], onglet Chefs-d’œuvre | `oeuvres` ouvre les projets, avec barre d’avancement et quantités manquantes. `oeuvre { id }` apporte des matières au village. |

`Registres.lua` et `MagieClient.lua` portent les nouvelles fenêtres et la barre. `Interface.client.lua`, `Quetes.client.lua`, `Conseil.client.lua` et `Gestes.client.lua` les relient aux accès existants. `ComposantsInterface.lua` et `WindowNav.lua` gèrent les commandes des fenêtres avec le cadre commun. `Catalogue.lua` et `ConstruireModeles.lua` partagent la géométrie de la scierie. [Comparatif en édition, établi à gauche et scierie à droite](../images/x41-scierie-avant-apres.jpg).

## Vérification et suites

- Dix sources compilées et synchronisées dans Studio en édition. Six bancs serveur (`magie`, `royaumes`, `contrats`, `gazette`, `mariages`, `oeuvres`) et `equilibre` au vert. Modèle `Scierie` construit et vérifié en 48 pièces.
- Vérification en édition des messages, des actions, de la navigation clavier et du focus manette avec des entrées simulées. La souris, le tactile et la manette utilisent les mêmes boutons `Activated`. Restent les essais physiques au clavier, à la souris, au doigt et à la manette en Play sur le PC fixe, ainsi que les captures des fenêtres.
- Trois passages attendent Claude dans [LOTS.md](LOTS.md#passages-demandes-entre-couloirs) pour le modèle des scieries posées, les données du conjoint et les effets des sorts des autres joueurs ou dirigés vers une cible choisie par le serveur.
- Le changement de `ConstruireModeles.lua` figure déjà dans le commit parallèle de Claude `737c059`. Les autres modifications X41 sont sur le disque et les scripts du lot sont chargés dans la session Studio ouverte.
