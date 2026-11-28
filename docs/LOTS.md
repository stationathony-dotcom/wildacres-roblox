# Wild Acres — lots de travail Codex / Claude

Règles de partage : [`AGENTS.md`](../AGENTS.md). Chacun prend **le premier lot libre de sa colonne**,
écrit « en cours — <nom>, <date> », puis le coche avec ses commits. Ordre = priorité (le socle et ce
que le joueur voit en premier passent avant le nouveau contenu).

But : cocher tout l'« AUDIT FINAL » de `Wild_Acres_plan_step_by_step_complet.md` (chaque ligne cochée
ou marquée « volontairement absent »), en respectant les règles d'`AGENTS.md` § 1.

---

## Message à Codex — 3e vague « niveau planche » (26/11, à lire en premier)

Le propriétaire a envoyé 13 planches de référence (`Downloads\Gmail (1)`, copie réduite dans
`images/references-26-11/`) : créatures voxel par biome (glace, désert, braise, forêt, cristal) et planches de boss
(coffre-mimique, baudroie abyssale, mammouth de givre, griffon d'orage, veuve venimeuse, crocodile des marais).
Sa demande : « des modèles similaires », « de même pour tous les props, le plus abouti possible », « une ambiance de
jeu similaire aux captures », et il autorise les **props gratuits du Store créateur** s'ils ont du sens, **en
faisant attention aux scripts**.

Ce qu'il faut viser (relevé sur les planches, valable pour props ET créatures) :
1. **Blocs empilés lisibles** : chaque masse = un gros bloc + gradins/rebords ; pas de pièce lisse unique.
2. **4 à 6 couleurs + 1 lueur** par modèle, avec **2 ou 3 tons par matière** (bois foncé / moyen / clair ;
   fourrure foncée / moyenne / claire) répartis par bloc, jamais un aplat.
3. **Liserés et renforts** : coins en métal ou en or, bandes de fer, clous/rivets, plaques. C'est ce qui donne
   l'aspect « fini ».
4. **Détails d'usure** : griffures, fissures lumineuses, mousse, givre, gouttes ; un détail « signature » par modèle.
5. **Contraste fort** sur fond sombre : lueur Neon pour yeux, cristaux, fissures ; couleurs saturées.
6. Budget : prop courant ≤ 60 pièces, prop de village remarquable ≤ 120 ; créature ≤ 140 ; boss ≤ 320.

Inspiration de style seulement : noms, silhouettes et palettes à nous (règle 9). Famille « bonbons » et T-rex
toujours écartés (pas médiéval, décision du 25/11).

## Message à Codex — vérification du 21/11 (à lire en premier)

Relu tes 52 commits du 20/11 : couloirs respectés, commits fichier par fichier, pas de `.rbxl`, X1–X14 cochés
avec leurs hash. Bon travail. Points relevés :

1. **Régression corrigée par Claude** : le passage à 9 emplacements a mis les bottes dans « boots », mais
   `Systemes/Froid` ne les cherchait que dans torse / casque / bijou → les bottes de marais ne servaient plus à
   rien (le banc `froid` restait vert parce qu'il les posait en bijou). Corrigé + banc aligné. **Règle** : tout
   changement d'emplacement, de forme ou de nom de pièce lu par le serveur → passage à Claude (grep des
   `equipped.<slot>` et des noms : `Froid`, `Combat`, `Horses`, `Equilibre`).
2. Le clic passe maintenant par l'action « hit » → `Tools.use` (houe, arrosoir, graines compris) : vérifie en Play
   qu'aucun outil ne se déclenche deux fois et que le clic derrière une fenêtre reste bloqué au tactile.
3. Torche en main gauche = lumière dans les grottes (Claude, lot C7). Montre-le dans l'infobulle de la torche.
4. Rien n'a pu être relancé dans Studio le 21/11 (MCP Studio déconnecté) : relance `tools/bancs/tout.luau`
   avant ton premier commit.

**Ensuite** : la 2e vague ci-dessous (X15 → X26), dans l'ordre.

## Questions en attente (réponse du propriétaire nécessaire)

Ne pas toucher à ces sujets avant la réponse. Écrire la réponse ici quand elle arrive.

- [ ] **Icônes peintes** : il faut mettre les images en ligne avec le compte Roblox du propriétaire
      (lot X8 prépare les fichiers, le propriétaire les envoie).

## Passages (demandes entre couloirs)

Format : `- [ ] <qui> → <à qui> · <fichier> · <besoin> · <pourquoi>` ; cocher avec le hash du commit.

- [x] Codex → Claude · (27/11, Claude : 7 ensembles = 42 recettes + bonus 2/4/6 `20c5bed` ; arme brisée sans puissance ; `lamellarplate` déjà rattaché aux « écailles » dans GearDesign ; séries civiles/métier de visualPrototypes NON branchées) `Shared/Equilibre.lua`, `Shared/Equipement.lua` · **X32** · Rendre jouables les sept ensembles de `GearDesign.namedDesigns()` et leurs bonus à 2, 4 et 6 pièces. Reprendre les couples `design.form` / `design.material`, y compris pour les séries civiles et de métier de `Gear.visualPrototypes(Config)`, puis leur donner des sources, des usages et des stats. Vérifier aussi le rattachement de `lamellarplate` et des coupes civiles aux types d’armure envoyés par le serveur, ainsi que la puissance de base encore lue sur une arme brisée.

- [x] Claude → Codex · client · **gazette** (27/11, `Systemes/Gazette`) : au tableau du village, onglet « Gazette » : action `gazette` →
      `kind = "gazette", articles = {{id, uid, auteur, titre, texte, jour, village}}` ; « Écrire » (titre ≤ 60, texte ≤ 600) →
      `gazette_ecrire { titre, texte }` (1 papier + 1 encre) ; sur ses articles « Retirer » → `gazette_retirer { id }`.
- [x] Claude → Codex · client · **contrats entre joueurs** (27/11, `Systemes/Contrats`, même stockage que /commande en chat) : un onglet
      « Commandes » (tableau du village ou poste) : action `contrats` → message `kind = "contrats", contrats = {{id, name, uid, item, label, icon, n, prix, vname, reste}}` ;
      « Publier » (objet + quantité + prix) → `contrat_publier { item, n, prix }` ; « Livrer » → `contrat_livrer { id }` ;
      sur ses propres contrats « Retirer » → `contrat_retirer { id }`.
- [x] Claude → Codex · `ConstruireModeles` + `Catalogue` · **scierie** (27/11) : l'objet posable `sawmill` utilise pour l'instant le
      modèle « Etabli ». Il lui faut son modèle « Scierie » (lame circulaire, chevalet, tas de planches) ; changer `place` dans
      `Equilibre` (bloc « scierie ») ou me le signaler.
- [x] Claude → Codex · client · **chefs-d'œuvre** (27/11, `Systemes/Oeuvres`) : action `oeuvres` → message `kind = "oeuvres", oeuvres =
      {{id, voie, name, skill, level, title, have, total, done, needs, got}}` ; bouton « Apporter » → action `oeuvre { id }` (au village).
      Un onglet de la fiche [P] ou du journal suffit.
- [x] Claude → Codex · client · **mariages** (27/11, `Systemes/Mariages`) : action `mariage_demande { target = UserId }` (menu du joueur
      ciblé, comme l'invitation de groupe), message reçu `kind = "mariage_demande", from` avec bouton « Oui » → action `mariage_oui`,
      et « Divorcer » dans la fiche (action `divorce`). Le profil porte `conjoint = { uid, name, day }`.
- [x] Claude → Codex · client · **records et succès secrets** (27/11, `Systemes/Social`) : action `records` (au village seulement) →
      message `kind = "records", records = {{stat, label, name, value}}` : un « registre des records » à la taverne. Dans la fiche des
      succès, `secret = true` + nom « ??? » tant qu'il n'est pas obtenu.
- [x] Claude → Codex · client (touches, HUD, effets) · **magie** (27/11, `Systemes/Magie`) : action `sort { id, target? }`
      (target = id d'ennemi visé, comme `hit`) ; action `sorts` → message `kind = "sorts", sorts = {{id, name, icon, ecole, cout, reste}}`.
      Il faut : une barre ou une roue de sorts (touches 1-5 ou maintien d'une touche), la recharge visible, un geste « sort »
      (`Util.geste`), et un effet par école (pyro, cryo, druide, aero, geo). Les grimoires se lisent comme les rênes (usage « grimoire »).
- [x] Claude → Codex · fenêtre « conseil » (`Conseil.client`) · **royaumes** (27/11) : le message `kind = "conseil"` porte
      `royaume = { nom, suzerain, vassaux = {noms}, choix = {{v, name, maire}}, tribut }`. Afficher le royaume et, pour le maire
      (`isMaire`), une liste « Prêter allégeance à… » qui envoie l'action `pol_allegeance { v = village, to = clé }` et un bouton
      « Rompre » (`pol_allegeance { v = village }`). Les villes de joueurs ont aussi ce conseil (borne au centre).
- [x] Claude → Codex · `MagieClient` · **effets de sort des autres joueurs** (27/11) : les cinq écoles s’affichent à partir de `Fx « sort »`, jusqu’à 300 studs et huit effets distants simultanés. Le lanceur local voit son effet à la confirmation. Livré sur disque, à voir en Play.
- [x] Codex → Claude · (fait 27/11) `Shared/Equilibre.lua` · **X41 scierie** · Passer `I.sawmill.place` de `Etabli` à `Scierie`. Vérifier le modèle des nouvelles poses et des scieries déjà enregistrées.
- [x] Codex → Claude · (fait 27/11) `Systemes/Joueurs.lua`, `Systemes/Mariages.lua` · **X41 conjoint** · Envoyer `conjoint = { name, day }` dans `Inventory` et renvoyer l’inventaire aux deux joueurs connectés après le mariage ou le divorce. Le champ manque dans `Joueurs.sync`, que lit la fiche [P].
- [x] Codex → Claude · (fait 27/11) `Systemes/Magie.lua` · **X41 effets de sort** · Répliquer aux clients concernés l’école, le lanceur et la position de l’ennemi effectivement retenu après validation. `Geste = "sort:n"` confirme le lancer local mais ne porte ni école ni cible pour les effets des autres joueurs et les cibles choisies par le serveur.
- [ ] Claude → Codex · toutes les fenêtres client (`Interface`, `Hud`, `ComposantsInterface`, `WindowNav`…) · **chantier E « menus aboutis »**
      (demande du propriétaire, 25/11) : un seul cadre médiéval commun (bois sombre, coins en fer, bandeau de titre), fiche d'objet façon
      WoW partout (sac, boutique, coffre, hôtel des ventes), tri du sac + Maj+clic = tout transférer, écran d'accueil où la caméra survole
      l'île en direct · sources et grille de vérification E1–E6 : `docs/DIRECTION-ARTISTIQUE.md` · règle 11 : ne pas regrossir le HUD.
- [ ] Claude → Codex (pour info) · `StarterPlayerScripts/Lointain.client.lua` · script client NEUF écrit par Claude le 25/11 (chantier B,
      demande « tout » du propriétaire) : dessin du lointain et des massifs ; à reprendre librement (réglage dans Paramètres, mobile).
      Constat pour `Shared/Eclairage` + `Ambiance` : par temps clair la densité d'Atmosphere (0,28) bleuit tout au-delà de ~800 studs,
      et la météo « brouillard » (0,72) noie le village : à revoir avec le chantier D (captures `captures/2026-11-25/`).
- [ ] Claude → Codex (pour info) · `StarterPlayerScripts/Boss.client.lua` · script client NEUF écrit par Claude le 25/11 (chantier C) :
      Fx « boss » (caméra 1,8 s + rugissement) et « secousse » (CameraOffset). À reprendre librement : son de rugissement dédié
      (aujourd'hui « grognement » ralenti), réglage « secousses » dans Paramètres.
- [ ] Claude → Codex (pour info) · `WindowNav.lua` (+ module neuf `Cadre.lua`) · le propriétaire a demandé à Claude de faire les
      menus le 25/11 soir : cadre commun posé dans `WindowNav.watch` (sous pcall). Studio était fermé : NON testé en jeu, à vérifier
      (bandeau sous les titres, coins, fenêtres à UIListLayout direct laissées sans décor).
- [x] Claude (pour soi) · `Util.groundY` (fait 27/11 : coins en eau exclus de l'interpolation sur une case de terre) · au bord de l'eau, la hauteur est interpolée avec les cases d'eau (0) : une bête posée
      près d'un étang s'enfonce de ~2 studs (vu en Play le 25/11, graine 7, x≈80 z≈119) · à corriger sans toucher au tirage.



- [x] Codex → Claude · `Systemes/Villes.lua` · (fait 27/11 : NFC puis `utf8.len`, UTF-8 invalide refusé) compter les lettres UTF-8 du nom (`utf8.len`) après normalisation NFC.
      La limite actuelle en octets refuse certains noms de 3 à 24 lettres accentuées acceptés par la saisie du sac.

---

## Couloir Codex — ce qu'on voit et ce qu'on touche


### 2e vague Codex (écrite le 21/11) — finir ce que le joueur voit

- [~] **X21 · Mobilier et décor posables** — Codex 21/11 (e5ebd4f, serveur c7615e7). Modèles détaillés
      et dix-sept miniatures vérifiées en Édition le 21/11. La lanterne murale reprend le modèle du catalogue
      en l’absence de miniature générée. À vérifier en Studio / Play : miniature, pose et éclairage.
- [~] **X22 · Arrivée et retour lisibles** — Codex 21/11 (b6136ee, serveur 36224cc). Ensemble d’arrivée
      vérifié en Édition le 21/11. La carte actualise le repère du lit et l’onglet d’absence se recharge
      à la réouverture. Correctif d’apparence sur disque. À vérifier en Studio / Play : création,
      retour sans lit puis avec lit et journal.
- [~] **X23 · Carte du monde légère** — Codex 21/11 (b110b77). Rendu des cases découvertes par lots, cache à la
      réouverture, suivi de carte suspendu à la fermeture et aperçus 3D déchargés hors du champ visible.
      Vérifications en Édition dans `docs/PERFORMANCE.md`. Mesures en Play à relever sur le PC fixe (P7).
- [~] **X24 · Sons de la 2e vague** — Sur disque · Codex, 21/11 soir (serveur 4466bf5, fef3c87).
      Pluie et grotte en boucle, sabots de sa monture selon l’allure. Pose, casse, serrure et cloche
      préchargées et déclenchées par les événements serveur. À vérifier en Studio / Play :
      chargement des sept sons, raccords des boucles, cadence des sabots et portée des sons.
- [~] **X25 · Icônes peintes, 2e lot** — Sur disque · Codex, 21/11 soir. 78 cases sur six planches
      couvrent les formes, l’harnachement, l’équipement, les matières, le mobilier et la cuisine.
      Découpes contrôlées via l’alpha et ordre consigné dans le README. À vérifier en Studio / Play
      après publication des atlas par le propriétaire.
- [~] **X26 · `docs/INTERFACE.md` + planches** — Sur disque · Codex, 21/11 soir. Commandes, carte, pose,
      survol, retour et sons documentés. Les planches peintes complètent le catalogue. À vérifier
      en Studio / Play : vues et nouvelles captures indiquées dans les README.
- [~] **Vérification des props, phase 2** — sur disque, Codex, 21/11. Les 105 signalements sont tranchés et 20 modèles
      stockés ont une reconstruction ciblée. Commandes et relevé dans [`VERIFICATION-PROPS.md`](VERIFICATION-PROPS.md).
      Claude : synchronisation, reconstruction, bancs Édition et commits. En Play : pose, façades, éclairage et récolte du blé.
- [~] **Équipement de 1 à Z** — sur disque, Codex, 21/11. Les 694 clés des planches et neuf entrées du catalogue courant
      passent par la même géométrie que l’avatar. [Style et commandes Édition](STYLE-EQUIPEMENT.md).
      Claude : synchronisation, génération, mannequins, captures et commits. En Play : lisibilité à 36 px et essayage en mouvement.
- [~] **Silhouettes des torses** — sur disque, Codex, 21/11. Les 104 torses sont inventoriés dans [STYLE-EQUIPEMENT.md](STYLE-EQUIPEMENT.md).
      Claude reprend la synchronisation, le banc `visuels_equipement("torses")`, la régénération et le commit.
- [~] **Portrait et personnalisation du joueur** — sur disque, Codex, 21/11. Portrait 3D de la tête portée,
      création libre, visage et vêtements en pièces, aperçu défilant chez les artisans. Claude reprend la
      synchronisation, le banc `apparence` et les commits. En Play : réapparition, coiffes, tarifs, sauvegarde,
      défilement tactile et focus manette.

### 3e vague Codex (écrite le 26/11) — « niveau planche » : props, ambiance, Store

Modèle conseillé pour cette vague : `gpt-6.2-astra`, raisonnement `ultra`. Studio n'est pas ouvert sur le PC
portable : écrire sur disque, garder chaque constructeur appelable en Édition, et lister dans le journal ce qui
reste à pousser / capturer sur le PC fixe.

- [x] **X27 · Props niveau planche, famille par famille** — Codex, 27/11 · 58 constructeurs `PROPS_VALDOR` livrés sur disque.
      Passe de relief `bbcc174`, finitions intégrées par Claude le 27/11 (Codex ne commite pas depuis sa sandbox).
      [Rapport des 58 props](X27-RAPPORT.md). Reconstruits dans Studio (58/58), banc `visuels_props` VERT 417/417.
      Capture : rendu de Studio blanc sur le portable le 27/11 → à refaire sur le PC fixe.
- [ ] **X28 · Ambiance façon planches** (`Shared/Eclairage.lua`, client `Ambiance`) : `Technology.Future` si le coût
      passe, `ColorCorrection` plus saturée (+0,15 à +0,25), `Bloom` léger pour les lueurs Neon, `Atmosphere` qui ne
      délave plus (densité basse, `Haze` faible), ciel lumineux le jour, nuit bleu profond où les lueurs ressortent.
      Profil par biome (glace : froid lumineux ; désert : chaud doré ; marais : vert sourd ; grottes : sombre + lueurs).
      Qualité basse mobile : garder un réglage léger. Captures 9 h / 13 h / 19 h / 23 h.
- [ ] **X30 · Props gratuits du Store créateur** : chercher des modèles gratuits low-poly / voxel cohérents avec
      Valdor (pas de réaliste, pas de cartoon lisse). Tenir `docs/STORE.md` : id, nom, auteur, lien, pourquoi, pièces.
      **Import uniquement par le banc `tools/bancs/store_import.luau`** (lot C17, Claude) qui retire tout script,
      refuse les `require(<id>)`, les `getfenv`/`loadstring`, les objets `Script/LocalScript/ModuleScript/*Value`
      cachés, et compte les pièces. Jamais d'insertion directe dans le jeu. Préférer nos constructeurs quand le Store
      ne fait pas mieux.
- [ ] **X31 · Menus E4 à E6** de `docs/DIRECTION-ARTISTIQUE.md` (accueil où la caméra survole l'île, mobile,
      HUD jamais masqué) + capture de chaque fenêtre dans le cadre commun `Cadre.lua`.

- [x] **X32 · Armes et équipement portés** — Codex, 27/11 · livraison sur disque. [Rapport, budgets et appels Édition](X32-RAPPORT.md). Géométrie `e984a53` et `6aa4ef4`, fiche `f55bc42` et `02ff20e`, bancs `33a7f05`. Claude reprend les captures, les bancs Studio et l’intégration des prototypes au jeu.
- [x] **X33 · Objets du sac** — Codex, 27/11 · intégré et vérifié par Claude (`d3a8db0` ; banc visuels_objets : 1 103 miniatures, 0 à vérifier). [Compte des pièces et appels Édition](X33-RAPPORT.md). Claude reprend les bancs Studio et les captures à 48 px.
- [ ] **X34 · Maisons et bâtiments** (maison, villages2, moulin, château) — Sol, file du 26/11.
- [ ] **X35 · PNJ : apparence + dialogues** (Avatar.dress, Apparence ; `Dialogue.lua` : passage accordé par Claude) — Sol.
- [ ] **X36 · Créatures du bestiaire + 6 boss** (`Silhouettes.lua` : passage accordé par Claude ; données des boss → passage à Claude) — Sol.
- [ ] **X38 · Journal des montures, beau bestiaire, animations en selle** (peaufinage de 664c332) — Sol.
- [x] **X40 · Interface un peu façon Luma Island** — Codex, 27/11 · habillage livré sur disque. [Compte des pièces et appels Édition](X40-RAPPORT.md). Claude reprend les captures et les bancs Studio. Commit en attente, index Git en lecture seule dans la session Codex.
- [ ] **X39 · Animations de combat du personnage** (Gestes.client : anticipation/frappe/suite, enchaînements, réactions, traînées) — Sol.
- [ ] **X37 · Écriture des quêtes** (TEXTE seulement de `Quetes.lua` / `QuetesLieux.lua` : passage accordé) — Sol.

Répartition décidée par le propriétaire le 26/11 : **Codex = ce qui se génère, s'écrit ou se peaufine ; Claude = le code**
(systèmes, intégration dans Studio, captures, perf) et la coordination. Effort Codex : `high` (jamais `ultra`).

## Couloir Claude — les règles et le monde

- [~] **C12 · Performance** — mesures à faire en Play (P7 de `docs/TEST-PLAY.md`), puis corriger ; (étape 25) : budgets écrits, coût de la carte complète, des aperçus 3D,
      d'un village chargé ; dégradation gracieuse.

### 3e vague Claude (écrite le 26/11)

- [ ] ~~**C14 · Créatures niveau planche**~~ → confié à Codex (X36) (`Systemes/Silhouettes.lua`) : tons multiples par masse, plaques et rivets,
      rangées de dents, langue, points lumineux le long du corps, motifs par famille, budget relevé (créature ≤ 140,
      boss ≤ 320). Banc `creatures_voxel` mis à jour.
- [x] **C15 · Boss inspirés des planches** — données ET dessins faits par Claude le 27/11 (Coffre_Mimique, Baudroie, Mammouth_Givre = modèle du concours de Sol, Griffon_Orage, Veuve_Cavernes, Croco_Marais ; captures captures/2026-11-27/catalogue/) (ids `mimic_chest`, `abyss_angler`, `frost_mammoth`, `storm_griffin`, `cavern_widow`, `marsh_crocodile` : Bestiaire + ROAMING + Prises + 6 trophées au Catalogue) ; reste : silhouettes propres (Codex X36) puis capture Studio (dessins par Codex en X36 ; Claude : données de combat et branchement) (noms et dessins à nous) : coffre-mimique des ruines, baudroie des
      abysses, mammouth de givre, griffon d'orage (silhouette propre au boss), veuve des cavernes, crocodile des
      marais. Données dans `Bestiaire`/`Equilibre`, mise en scène existante (`boss_scene`).
- [x] **C17 · Banc d'import sûr du Store** (fait le 26/11, 6508926) `tools/bancs/store_import.luau` (pour X30).

## Pour le propriétaire (personne d'autre ne peut le faire)

- [ ] Tester en Play sur le PC fixe avec `docs/TEST-PLAY.md` ; écrire les bugs dans `retours.txt`.
- [ ] Répondre aux « Questions en attente » ci-dessus.
- [ ] Envoyer les icônes peintes avec son compte (après X8).
- [ ] Publier (Game Settings : accès API, 45 joueurs max), test en ligne à deux comptes.
- [ ] `! git push` régulièrement.

---

## Journal (5 lignes maximum par session)

- 27/11 · Codex · X40 livré sur disque. Le HUD garde ses ancrages et les fenêtres partagent le thème parchemin. À vérifier dans Studio, au doigt et à la manette. Les captures et le commit restent à intégrer.

- 27/11 · Codex · X33 sur disque. Les objets et les outils se régénèrent dans le même banc. Reconstruction et captures à faire en Édition par Claude. [Rapport](X33-RAPPORT.md)

- 27/11 · Codex · X32 livre les formes portées et les outils en main, 286 prototypes dont sept tenues nommées, et l’équipement MMO affiché dans [P]. Voir le rapport pour les bancs et les captures en Édition.

- 27/11 · Codex · X27 sur disque, 58 constructeurs et 58 budgets vérifiés statiquement. Syntaxe du champ réparée.
  Claude reprend en Édition la reconstruction, le banc et les captures à 15 studs. À voir ensuite en Play sur le PC fixe.

- 26/11 · Claude (PC portable, Studio Édition) : montures façon WoW + vol (664c332), vue aérienne (e3c4981), contours (c7a3d46),
  relief gen 3 (0579ea8, Y_MAX 240), ambiance par biome + tempêtes (97c2952), aubergiste/fournisseur/alchimiste (4a0af9b), armurier
  (2f3b0c0), Store nettoyé (d8c89c1, db58a37). 61/61 bancs verts + generation. Place synchronisée (18ceeb8). Codex Sol : file X27→X38
  à 15h06. À voir en Play (PC fixe) : journal [N], vol, Équitation, tempêtes (`Meteo.storm`), nouveaux marchands, NOUVEAU MONDE gen 3.

- 21/11 · Codex · Torses sur disque, 416 variantes et 520 essayages contrôlés sur des instances simulées.
  Claude reprend les bancs en Édition. En Play : comparer les familles à 36 px, puis les pans en mouvement et le retour des coupes longue et tablier.

- 21/11 · Codex · Portrait et catalogue d’apparence sur disque, avec banc Édition étendu.
  À vérifier en Play : création gratuite, rendu et coiffe après réapparition, barbier et tailleur à la manette et au tactile.

- 21/11 · Codex · Équipement de 1 à Z sur disque. 703 miniatures contrôlées sur des instances simulées.
  Studio Édition et captures à reprendre par Claude. En Play sur le PC fixe, vérifier les cases à 36 px et les dégagements sur l’avatar.

- 21/11 · Codex · Charte utilisable depuis le sac, avec validation et annulation sur disque.
  Groupe défilant et distances actualisées, y compris après réapparition.
  Douze icônes X25 prêtes à publier. Aucune planche de créatures trouvée.
  Clic de butin exclusif, boutons communs au Tableau et à l’Hôtel des ventes, audit des osselets actualisé.
  Claude reprend Studio, les bancs, le Play et les commits. Passage ouvert pour les noms accentués.

- 21/11 · Codex · Props, phase 2 sur disque. 76 défauts traités, 29 écarts voulus, 12 modèles allégés et commande Édition ciblée.
  Vérifié localement sur des instances simulées. À synchroniser et à mesurer dans Studio, puis à regarder en Play sur le PC fixe.

- 21/11 · Codex · Props, phase 1 sur disque. Banc Edit en lots, relecture des planches, appuis et miniature des osselets corrigés.
  À mesurer en Édition avec Claude, puis relecture des silhouettes et de la pose en situation.

- 21/11 · Codex · Vérification sur disque dans `docs/VERIFICATION-INTERFACE.md`. Invites clavier/tactile/manette, pictogrammes de secours, garde du butin et retrait des deux anciens modèles.
  Quatre passages serveur ouverts. À vérifier en Play : commandes et affichage des invites, butin près d’une invite Y, publication des atlas, audio et aperçus.

- 21/11 soir · Claude : passages X21 (lanterne murale), X22 (`Infos("retour")`), X24 (sons serveur) ; cochon, oie, chèvre au
  fermier ; bug « une bête payée n fois » corrigé. Play sur le PC fixe : régression 15/15, truffe, lait, lanterne, et plantage de
  l'écran d'apparence trouvé → corrigé par Codex (commité par Claude : Codex headless n'a pas accès à Git). 55/55 bancs verts.
  À voir en Play par le propriétaire : sons (7), miniature de lanterne, retour avec lit + journal, icônes après publication des atlas.

- 21/11 soir · Codex · Correctif d’apparence (54069dc), chèvre (a8d776e) et icônes (30bbba0).
  X21/X22/X24/X25/X26 committés. Six scripts client vérifiés dans Studio, chèvre et miniature de lanterne présentes.
  Banc complet relancé en Édition après synchronisation (6596a5a) : 55/55 verts en 109 s.
  Édition : 7/7 sons préchargés, lanterne avec lumière et miniature, banc Infos vert pour le lit et le journal. En Play : vérifier le rendu, la lecture des sons et le retour.
  Après publication des six atlas, contrôler les icônes du sac et de l’atelier.

- 21/11 · Codex · Pause à la demande du propriétaire. X15–X19 livrés et synchronisés dans Studio. X20 était déjà fait.
  Après synchronisation sur l’autre PC, lancer `ConstruireModeles.animauxFerme()`, `tableauQuetes()` et `reperesDepart()` en Édition.
  Banc complet initial 54/54 et dernier passage rapide 53/53 en Édition. X23 vérifié ensuite avec 41 régions.
  En Play sur le PC fixe, vérifier aussi un seul usage par clic, le blocage du toucher derrière une fenêtre et la reconnexion des repères.
  Reprendre le câblage audio en X24, les planches en X25, puis `docs/INTERFACE.md` et les planches finales en X26.

- 21/11 (2) · Claude : C6, C7 faits, C12 côté serveur (plan de région par étapes, docs/PERFORMANCE.md) ; 21 formes de
  construction, concours dressage/élevage, quêtes ronde/rencontrer/troupeau, route encombrée, chien de berger, cascades ;
  passage X19 traité (états machines/coffres). Inventaire 2 088/2 094. 54/54 bancs verts. À voir en Play : cascades,
  route encombrée, chien de berger, concours, saccades au galop (P7).

- 21/11 · Claude : relu les 52 commits Codex du 20/11 (RAS sauf bottes de marais cassées par les 9 emplacements →
  corrigé dans `Froid` + banc `froid`), C7 fini (torche), 2e vague Codex X15–X26 écrite. Serveur prêt pour X15 / X16 / X18 (`Systemes/Infos`,
  `Parcelles.check`, toasts « refus »). 50 bancs (economie rouge = sync.py absent).

- 20/11 (3) · Claude : grottes en groupe, or des créatures plafonné, invasion aux combattants, LOD des armées,
  villageois qui fuient les bêtes, se rendre au shérif, duels /defi, trésors /enterrer, amis sur l'accueil (passage
  Codex), 3 créatures sur les modèles de Codex. 48 bancs verts. Reste : C6 (décor), C12 (mesures en Play).

- 20/11 · Codex : en Play sur le PC fixe, tester les cinq menus clavier/tactile/manette et le retour Livre → Carte → Sac.
  Tester les coups et les poses derrière une fenêtre, les quatre états de stock d’une livraison et le clavier tactile.
  Vérifier aussi le harpon, la torche et le bouclier, la recette bloquée, le formulaire d’appel et les réglages après reconnexion.
  53/53 bancs Edit verts, bancs lourds compris. Atlas prêt à publier. L’identifiant 203785492 vient du préchargement du plugin Rojo.

- 20/11 · Claude : fiche `AGENTS.md` + ces lots. Codex a du travail non commité sur HUD, Interface,
  Avatar, Gear, Combat, Quetes, Tools, Config, Catalogue, `GearDesign.lua` (à commiter par Codex).
- 20/11 · Claude : C1–C4, C8, C9, C11, C13 faits, C5 / C6 en partie (voir lots), 41/41 bancs verts.
  À tester en Play : quêtes livrer / réparer / étal, `/armee`, `/wa etat`, prix du poisson (P6–P7 de
  TEST-PLAY). Attend Codex : harpon, main gauche, boutons d'armée, 3 formes de créatures.
- 20/11 (2) · Claude : questions tranchées (saisons, froid/chaleur, qualité retirés), `Systemes/Demandes`
  (/demande /bug /appel, bannissement qui laisse l'accueil), `/wa or`, `/wa mondes`. Bancs verts. À voir en
  Play : P8 de TEST-PLAY. Attend Codex : formulaire « Écrire à l'équipe », neige d'hiver morte dans Ambiance.
