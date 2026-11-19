# Suivi des missions WildAcres

Branche de travail `mission/wildacres`, créée depuis `d30b9ea`. La racine du projet sert de dossier des missions. Le parcours récursif a trouvé 18 fichiers TXT et six contenus distincts après normalisation des fins de ligne. Les deux copies sous `.production-nocturne` reprennent ces mêmes contenus.

## Suivi par source

| Source | Terminées dans cette session | En cours ou à faire |
| --- | --- | --- |
| `dernier prompt.txt` | Reprise du catalogue de mobilier et de la faune. | Vérifier en Play les lots précédents de créatures, leurs butins et équipements. Poursuivre les aquatiques, les volants, les habitants et les objets manquants. |
| `liste items.txt` | Coffret décoratif fabricable et plaçable. | Comparer les références une à une au catalogue actuel. Poursuivre charpente, murs, fondations, toits, ouvertures, escaliers, ferrures, mobilier, fermes, machines, décorations, ressources, équipements, nourriture, artisanat, montures, exploration, alchimie, commerce et objets sociaux, de progression et de mission. Vérifier la fabrication, l’utilisation et le placement selon chaque objet. |
| `liste quetes.txt` | Commandes tournantes inspirées des entrées 17, 20, 21 et 30. La maison et le marché demandent des fournitures. | Recenser les correspondances exactes des 560 entrées. Reste notamment la livraison à domicile, les réparations effectives et l’installation des étals, ainsi que les quêtes de métiers, de découverte, de justice, de clans, de navigation, d’événements, de coopération et les quêtes secrètes ou scénarisées. |
| `listes ennemi.txt` | Canards sauvages avec nage de surface et retrait la nuit. | Comparer le bestiaire aux listes d’humains, animaux hostiles, créatures par biome, nocturnes, maudits, volants, aquatiques, géants, boss, spécimens d’événement. Compléter les habitants, la faune passive, les professions, lieux, bâtiments, transports, progression, économie, loisirs, politique, événements, météo, multijoueur et interface. |
| `à ne pas oublier.txt` | Les commandes élargissent les missions civiles du tableau. | Auditer l’existant puis traiter la réputation locale, les relations et dialogues PNJ, les contrats et récompenses, la progression, les collections et le journal, la vie médiévale, les propriétés, la politique, les événements, les loisirs, l’économie, la sauvegarde et la récupération, la modération, la performance, le multijoueur et l’accessibilité. |
| `tools/creatures_liste.txt` | Repérée comme référence d’identifiants du bestiaire. | Comparer au bestiaire courant pour relever les identifiants obsolètes et servir de base à la vérification des nouveaux lots. |

## Journal et problèmes

- 19/11. Ajout du pichet en céramique dans les décorations fabricables au four. Vérification Studio Edit de la recette unique et du modèle plaçable réussie. Build Rojo réussi.

- 19/11. Ajout des hérissons et des blaireaux au lot de faune passive. Test Studio Edit réussi sur un terrain simulé pour les apparitions nocturnes, les plafonds, le refus de l’eau, la fuite et le retrait au jour. Build Rojo réussi.

- `530204e` ajoute une commande par période de deux jours à chaque tableau, avec quatre commandes en rotation et des identifiants distincts. Banc Studio Edit réussi sur les sources de travail et sur les sources indexées. Build Rojo réussi.
- `3b6813d` ajoute les canards sauvages à la faune locale. Test Studio Edit réussi avec un sol simulé, un plan d’eau simulé, un plafond de deux canards et un passage à la nuit. Build Rojo réussi.
- L’essai d’ajout d’une étagère a mis en évidence un doublon avec la recette existante. Le changement local a été remplacé par un coffret avec son propre modèle. Test Studio Edit de l’objet, de la recette d’établi et du modèle réussi. Build Rojo réussi.
- Claude CLI a renvoyé `ECONNREFUSED`. Le worktree détaché `C:/Users/User/Documents/wildacres-claude-missions` est resté sans modifications. Le lot de mobilier a été repris localement.
- Le test des recettes en Play, les essais sur terrain réel et le test de charge à 40 joueurs restent à faire. Les essais Studio de cette session ont utilisé des instances temporaires et les builds Rojo ont été écrits dans le dossier temporaire.

## Reprise

Le dépôt contenait déjà des changements locaux sur les systèmes de ferme, métiers, hameaux, quêtes et monde, ainsi que la place Roblox. Les commits de cette session contiennent uniquement les changements de mission. Pour poursuivre, comparer les sources TXT aux identifiants et aux mécanismes du jeu, puis compléter le prochain lot en gardant les changements locaux hors des commits. Le banc `tools/bancs/quetes.luau` vérifie le tableau et les règles de remise en mode Edit.
