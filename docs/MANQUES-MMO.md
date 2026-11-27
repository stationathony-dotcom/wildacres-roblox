# « Qu'est-ce qu'il manque » — bilan réadapté (26/11)

Source : `Desktop\Pour Wild Acres, je créerais un vér.txt` (2e partie : analyse ChatGPT des manques). Comparé au code réel
de `src/`. Règles d'`AGENTS.md` § 1 appliquées : **pas de saisons ni de climat de survie, pas de niveau de personnage**
(le « contenu après le niveau 50 » devient « contenu de fin de jeu »). Rien n'est mis en place ici : c'est un plan.

## Déjà en place (souvent plus avancé que le document ne le croit)
| Thème du document | Dans le code |
|---|---|
| Donjons, ruines | `Donjons.lua` (grottes et donjons cachés, sans signalement), boss procéduraux (`Enemies`, `Boss.client`) |
| Navigation | `Barques.lua` (2 places), `Ilots.lua` (5 îles au large), pêche (`Fishing`, `Nasses`, `Prises`) |
| Civilisation, politique | `Villes.lua` + charte (/fonder), `Politique.lua` (conseil du village), `Clans.lua` (6 grades), `Reputation` |
| PNJ vivants | `RelationsPnj`, `Ouvriers` (salariés agricoles), `Npcs`, métiers et marchands (`Metiers`) |
| Économie entre joueurs | `Poste.lua` (courrier, y compris hors ligne) + hôtel des ventes (`Ventes`), `Economie` |
| Automatisation | `Machines.lua` (moulin…), `Canaux.lua` (irrigation : à vérifier, le nom est aussi pris par le chat) |
| Monde vivant | `Evenements.lua` (événements locaux), `Meteo` + tempêtes, `Nids`, `Herbes`, `Faune` |
| Vie sociale | `Duels.lua` (défis avec mise), `Minijeux`, concours de dressage, tavernes (`Villages`), musique |
| Collections | bestiaire (`Livres`), `Chroniques` (pages anciennes), journal de découvertes et carte, montures (journal [N]) |
| Technique critique | `Save`, validation serveur (mini-jeux vérifiés), `Admin` + `Protection`, `Demandes` (/demande, rapport de bug) |

## Manques réels (ordre proposé)
1. **Interconnexion des systèmes** (27/11 : un filon rare propre à chaque îlot du large, pioche de fer ; œufs de monture enfin branchés — nids selon le biome, 3 % des coffres de donjon, 3 jours de couvée) (idée centrale du document) : la boucle explorateur → marchand → forgeron → aventurier →
   éleveur → navigateur. Concrètement : minerais rares propres à chaque île, commandes entre joueurs, œufs rares en donjon.
2. **Quêtes dynamiques** (27/11 : 1er pas fait — village en pénurie → sa 1re offre demande l'objet manquant, mieux payée) selon l'état du monde (village sans nourriture → livraison de blé, pont cassé → reconstruction,
   pénurie de fer → commande, animal disparu → recherche, escorte de marchand) + **contrats publiés par les joueurs**.
3. **Donjons poussés** (27/11 : 1er boss maritime — la Baudroie des abysses surgit de l'eau, créatures nageuses `swims`) : plusieurs niveaux de difficulté, énigmes et passages secrets, butin exclusif, raids de groupe,
   boss mondiaux et maritimes (pas de boss saisonniers : règle).
4. **Magie** (27/11 : serveur fait — 5 sorts / 5 écoles en grimoires, `Systemes/Magie` ; touches et effets à faire par Codex) (déjà en tête d'`EQUIPEMENT-MMO.md`) : écoles pyro, cryo, géo, hydro, aéro, druidisme, astrale, spirituelle
   (soutien), runique (enchantements), illusion ; apprise par grimoires, maîtres PNJ et talents. **Attend l'accord du propriétaire.**
5. **Mer complète** : voiliers, navires marchands et d'exploration, construction de bateaux, équipages, épaves, îles
   secrètes, cartes marines, ports, routes commerciales, créatures marines, voyage vers d'autres mondes.
6. **Royaumes et diplomatie** (27/11 : 1er pas — une ville de joueurs a son conseil : maire élu, taxe des étals, trésor, projets ; allégeance entre conseils, tribut de 10 %, royaume au sommet de la chaîne — fenêtre à faire par Codex) : de la ville au royaume, élections, maires et rois, lois locales, impôts, trésorerie,
   alliances, traités, ambassades, frontières (au-dessus de `Villes` et `Politique`).
7. **Écosystème vivant** (27/11 : forêts qui repoussent — souche 12 j, déraciné 24 j, jamais près d'une construction ; sécheresse après 4 jours sans pluie — baies qui ne repoussent plus, poissons qui mordent moins, pluie plus probable) : reproduction et migration des troupeaux, forêts qui repoussent et graines qui se dispersent,
   sécheresses et inondations ponctuelles (météo, pas saisons), floraison, créatures nocturnes, régénération des ressources.
8. **PNJ évolutifs** (27/11 : village qui prospère / fleurit / décline selon l'or échangé au comptoir, −5 % à +10 %, les habitants en parlent) : domicile, horaires, inventaire, besoins ; village qui prospère ou décline selon le commerce des joueurs.
9. **Automatisation étendue** (27/11 : scierie — bois le soir, 3 planches par bûche le lendemain, 4 avec une roue à eau) : engrenages, axes, roue à aube, moulin à vent, poulies, treuils, presses, scierie, meules,
   portes mécaniques, ascenseurs à contrepoids, ateliers semi-automatiques, machines combinables.
10. **Vie sociale** (27/11 : mariages au village avec une bague sertie, +10 % d'expérience côte à côte) : mariages, guildes de métiers, concerts et instruments, courses de chevaux, concours agricoles, foires,
    festivals, jeux de plateau, musées, bibliothèques, journaux de joueurs.
11. **Collections et prestige** (27/11 : records du monde au registre de la taverne, succès secrets, titres de magie) : codex d'équipements, poissons, herbier, fossiles, recettes, reliques ; titres, succès
    secrets, records mondiaux, apparences exclusives, historique des découvertes.
12. **Fin de jeu** par voie (27/11 : 7 chefs-d'œuvre personnels, compétence 40-50, titre unique + pièce légendaire, `Systemes/Oeuvres`) (dirigeant, explorateur, maître artisan, grand marchand, maître éleveur, aventurier, architecte,
    navigateur) : chaque voie doit avoir ses projets ambitieux.
13. **Technique « haute »** à revoir : tutoriel, recherche et filtres de l'inventaire, accessibilité, statistiques de jeu,
    protection contre la duplication (audit), synchronisation entre mondes, optimisation mobile (`PERFORMANCE.md`).

Non retenus : saisons, enneigement saisonnier, boss saisonniers (règle « pas de saisons »).
