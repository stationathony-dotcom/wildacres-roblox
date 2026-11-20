# Wild Acres Roblox — fiche de travail pour Codex (et Claude)

Ce fichier est lu automatiquement par Codex. Claude le suit aussi. Il dit **qui fait quoi**, **comment
travailler à deux sur le même dépôt sans se marcher dessus**, et **ce que le jeu doit être** une fois
fini. La liste des lots (le travail concret, avec qui le prend) est dans [`docs/LOTS.md`](docs/LOTS.md).

Écrire en français, avec les accents. Messages de commit en français.

---

## 1. Le jeu qu'on doit livrer (ce que veut le propriétaire)

Wild Acres = « craft / GTA / MMORPG » : un **bac à sable géant** façon Minecraft (en moins cubique),
avec la liberté de GTA (on peut voler, cambrioler, être recherché) et la vie d'un MMORPG (villages,
métiers, clans, hôtel des ventes, mondes persistants de ~40 joueurs, perso commun à tous les mondes).

**Règles de conception — non négociables.** Avant d'ajouter quoi que ce soit, vérifier que ça les
respecte. En cas de doute : ne pas le faire, le noter dans `docs/LOTS.md` § « Questions ».

1. **Sans indication.** Pas de tutoriel, pas de quête imposée, pas d'annonce à tout le serveur, pas de
   système encadré (pas de guerre de clans « déclarée »). On découvre sur place (habitants, panneaux,
   bruits, lueurs). Les quêtes sont **facultatives** et données **uniquement** par un habitant ou un
   tableau de village, jamais à distance.
2. **Pas de plafond arbitraire.** On est limité par ses ressources (or, nourriture, solde, place),
   jamais par un nombre maximum (armée, compagnons, parcelles, banque, champs, cases du sac).
3. **Monde libre, sans arbitre.** On peut construire chez les autres, se battre partout, voler. Ne
   **jamais** ajouter de règle qui interdit : ajouter plutôt un **outil** que les joueurs achètent ou
   fabriquent pour se protéger (serrures, alarmes, chiens, tourelles). `Config.LIBRE` garde les
   anciennes protections éteintes. Seule exception : pas de parcelle privée dans un village.
4. **Pas de niveau de personnage.** Les caractéristiques montent en pratiquant (`statXp`). Les
   pièces rares demandent une caractéristique entraînée (`Equilibre.requirement`). Tout déblocage de
   compétence lit `Joueurs.skillRaw` (pas `skill`, qui inclut les bonus portés).
5. **Grind, pas « en un clic ».** Chaque ressource a une résistance, parfois un outil requis, et de la
   variation (filons façon WoW). Certaines choses sont impossibles à mains nues.
6. **Tout est ramassable.** Ce qui est naturel ou décoratif se récolte au clic (mécanisme
   `Systemes/Moissons`, tag `Recoltable`). Un nouveau décor naturel doit s'y brancher.
7. **Rien sans usage.** Tout objet ajouté sert à quelque chose (recette, usage, équipement, vente
   spéciale). Relancer l'audit des usages et `tools/bancs/equilibre.luau` après un ajout.
8. **Construction libre.** Pas de maison toute faite : des pièces (mur, dalle, poutre…) fabriquées
   puis posées depuis la main.
9. **Créatures originales.** Pas de zombies ni de squelettes « classiques » (jugés « plagiat »).
   Violence adoucie : on assomme, on cache le corps.
10. **Volontairement absents** (ne pas les ajouter) : saisons (remplacées par les biomes — un reste
    tourne dans `Meteo.lua`, décision en attente), tutoriel, guerres déclarées, jeux de dés / casino,
    achats en Robux.
11. **Interface = image cible** (`images/hud-village-16-9.png`, `Aventure à Valdor dans Wild Acres.png`) :
    HUD MMO aux proportions de l'image (`Hud.scaleFor`, réf. 1672×941). Ne pas le regrossir.
    Icônes plutôt que lettres.

Documents de fond : `FEUILLE_DE_ROUTE.md` (ce qui est fait), `Wild_Acres_plan_step_by_step_complet.md`
(plan intégral et « audit final » = définition de « complet »), `docs/AUDIT-PRODUIT.md`,
`docs/A-RETRAVAILLER-EQUIPEMENT-ET-VISUELS.md`, `AUDIT.md`, idées brutes : `liste items.txt`,
`liste quetes.txt`, `listes ennemi.txt`, `à ne pas oublier.txt` (des **idées à piocher**, pas des
ordres : chaque idée retenue doit respecter les règles ci-dessus).

---

## 2. Le partage : deux couloirs

On ne se partage pas les tâches au hasard mais par **couloir de fichiers** : chacun est propriétaire
de ses fichiers, l'autre n'y touche pas sans passer par un « passage » (§ 4).

### Codex — « ce qu'on voit et ce qu'on touche »

Interface, commandes (clavier, tactile, manette), fenêtres, HUD, icônes, modèles 3D, apparence,
animations, sons, lisibilité, mobile.

Fichiers dont Codex est propriétaire :
- `src/StarterPlayer/StarterPlayerScripts/*` (tous les scripts client et `Hud.lua`) ;
- `src/ReplicatedStorage/Shared/Gear.lua`, `GearDesign.lua`, `Catalogue.lua`, `Eclairage.lua`,
  `HerbeHaute.lua` ;
- `src/ServerScriptService/Systemes/Avatar.lua`, `Tools.lua` ;
- `src/ServerStorage/OutilsDev/ConstruireModeles*` (tous les modèles 3D) ;
- `images/`, `docs/INTERFACE.md`, `docs/AUDIT-PRODUIT.md`, `docs/AUDIT-VISUELS-OBJETS.md`,
  `docs/RELECTURE-PLANCHES-VISUELLES.md`, bancs `tools/bancs/visuels_*.luau`, `hud_apercu`,
  `village_apercu`, `icones_outils`.

### Claude — « les règles et le monde »

Serveur, données de jeu, équilibre, économie, sauvegardes, sécurité, génération du monde, PNJ,
créatures (données et comportement), quêtes, contenu tiré des listes, bancs de test, documentation
de suivi.

Fichiers dont Claude est propriétaire :
- `src/ServerScriptService/Main.server.lua` et `Systemes/*` **sauf** `Avatar.lua` et `Tools.lua` ;
- `src/ReplicatedStorage/Shared/Equilibre.lua`, `Alchimie.lua`, `Chroniques.lua`, `Dialogue.lua`,
  `Prises.lua`, `RegionPlan.lua`, `WorldGen.lua` ;
- `tools/` (sauf les bancs listés côté Codex), `docs/REFERENCE.md`, `docs/AUDIT-CRAFT.md`,
  `docs/QUETES-COUVERTURE.md`, `docs/PROCEDURES.md`, `FEUILLE_DE_ROUTE.md`.

### Fichiers partagés (les deux y touchent, avec précaution)

`Shared/Config.lua`, `Systemes/Joueurs.lua`, `Systemes/Combat.lua`, `Systemes/Quetes.lua`,
`CHANGELOG.md`, `docs/LOTS.md`, `wildacres.rbxl`.

- Dans ces fichiers : **petites insertions** seulement, jamais de réorganisation ni de reformatage,
  et commit **tout de suite** après (pour que l'autre parte de la dernière version).
- Les **chiffres d'équilibre** (prix, dégâts, stats, recettes, objets neufs) vont dans
  `Shared/Equilibre.lua` (Claude), pas dans `Catalogue`/`Config`. Un objet neuf = ses données dans
  `Equilibre` (`E.NEW_ITEMS`) + son modèle/forme côté Codex (`Catalogue`, `ConstruireModeles`).
- `CHANGELOG.md` et `docs/LOTS.md` : n'ajouter / modifier **que ses propres lignes**.

---

## 3. Règles Git (on travaille dans le même dossier, sur la branche `mission/wildacres`)

1. `git add` **fichier par fichier**. Jamais `git add -A`, `git add .`, `git commit -a`.
2. Ne jamais commiter, annuler, `stash`, `reset`, `checkout --` ou reformater un fichier modifié par
   l'autre et pas encore commité. Regarder `git status` et `git diff <fichier>` avant de toucher un
   fichier partagé.
3. Si on doit commiter **seulement ses lignes** d'un fichier que l'autre a aussi modifié : appliquer
   ses modifications à `git show HEAD:<fichier>`, puis `git hash-object -w` + `git update-index
   --cacheinfo` (le fichier sur disque garde les deux travaux).
4. Préfixe des commits : `[Codex] …` ou `[Claude] …`, puis une phrase en français qui dit ce que le
   joueur y gagne. Un lot = un ou plusieurs petits commits.
5. `wildacres.rbxl` (binaire) : jamais dans un commit de lot. Un seul commit « Place : synchronise
   avec src » en fin de session, par celui qui termine en dernier, après avoir poussé `src/` dans Studio.
6. Pas de `git push` : c'est le propriétaire qui pousse (`! git push`). Ne jamais réécrire
   l'historique publié. Les vieilles branches sont archivées dans `refs/archive/*`.

## 4. Passages (quand on a besoin d'un fichier de l'autre)

Dans `docs/LOTS.md` § « Passages », écrire une ligne : *qui demande → à qui, fichier, ce qu'il faut,
pourquoi*. L'autre la traite en priorité au début de sa prochaine tâche et la coche avec le hash du
commit. En attendant, continuer un autre lot ; ne pas modifier le fichier de l'autre « pour aller
plus vite ».

## 5. Studio, tests et « fini »

- **Le disque fait foi** (`src/`). On n'écrit jamais un script seulement dans Studio. Pousser vers
  Studio : banc `tools/bancs/pousser.luau` (contrôle de syntaxe + copie). Pour un fichier partagé
  modifié des deux côtés, insérer ses lignes dans la Source actuelle de Studio plutôt que d'écraser.
- **PC portable** (peu de mémoire) : pas de Play, découper les gros `execute_luau`, lancer les gros
  bancs en `task.spawn` avec un attribut de résultat sur `ServerStorage`. Le Play se fait sur le PC
  fixe, par le propriétaire.
- **Bancs** : toute règle serveur nouvelle a son banc Edit dans `tools/bancs/` (faux `G`, lit la
  Source de Studio). Après un ajout d'objet ou d'équipement : `equilibre.luau`. Avant de déclarer un
  lot fini : tous les bancs au vert.
- **Génération du monde** : ne jamais changer un tirage publié ; un ajout se fait « par-dessus » avec
  sa propre graine (`docs/PROCEDURES.md` § 1). **Sauvegardes** : nouveau champ = facultatif dans
  `Save.FIELDS` ; changement de format = migration dans `Save.MIGRATIONS`.
- Piège déjà rencontré : un commentaire inséré au milieu d'une ligne a avalé du code. Insérer les
  commentaires sur leur propre ligne.

**Un lot est « fini »** quand : le code est sur disque et dans Studio, les bancs sont verts, une
ligne est ajoutée au `CHANGELOG.md`, le lot est coché dans `docs/LOTS.md` avec ses commits, et la
case correspondante de `FEUILLE_DE_ROUTE.md` (s'il y en a une) indique « à voir en Play ». Seul le
propriétaire coche « testé en Play ».

## 6. Comment démarrer une session

1. Lire ce fichier puis `docs/LOTS.md` (Passages d'abord, puis Questions : si une réponse est arrivée,
   l'appliquer).
2. `git status` + `git log --oneline -15` pour voir ce que l'autre vient de faire.
3. Prendre le **premier lot libre de sa colonne**, écrire « en cours — <nom>, <date> » dessus.
4. Travailler, commiter petit, cocher. Passer au lot suivant sans attendre de validation, sauf si le
   lot touche une **question en attente**.
5. Fin de session : résumé de 5 lignes maximum en bas de `docs/LOTS.md` § « Journal » (fait, cassé,
   à tester en Play).
