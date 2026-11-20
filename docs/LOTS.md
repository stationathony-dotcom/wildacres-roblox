# Wild Acres — lots de travail Codex / Claude

Règles de partage : [`AGENTS.md`](../AGENTS.md). Chacun prend **le premier lot libre de sa colonne**,
écrit « en cours — <nom>, <date> », puis le coche avec ses commits. Ordre = priorité (le socle et ce
que le joueur voit en premier passent avant le nouveau contenu).

But : cocher tout l'« AUDIT FINAL » de `Wild_Acres_plan_step_by_step_complet.md` (chaque ligne cochée
ou marquée « volontairement absent »), en respectant les règles d'`AGENTS.md` § 1.

---

## Questions en attente (réponse du propriétaire nécessaire)

Ne pas toucher à ces sujets avant la réponse. Écrire la réponse ici quand elle arrive.

- [ ] **Saisons** : `Meteo.lua` fait encore tourner des saisons (hiver = cultures un jour sur deux)
      alors qu'elles devaient être remplacées par les biomes. Les retirer, ou les garder ?
- [ ] **Froid / chaleur** (`Systemes/Froid`, 19/11) : `AUDIT.md` disait « survie volontairement
      absente ». On garde ?
- [ ] **Qualité de façon** (pièces de meilleure qualité + signature, 19/11) : `AUDIT.md` disait « pas de
      qualité séparée ». On garde ?
- [ ] **Canal d'appel des sanctions** (groupe Roblox, serveur communautaire…) : lequel ?
- [ ] **Icônes peintes** : il faut mettre les images en ligne avec le compte Roblox du propriétaire
      (lot X8 prépare les fichiers, le propriétaire les envoie).

## Passages (demandes entre couloirs)

Format : `- [ ] <qui> → <à qui> · <fichier> · <besoin> · <pourquoi>` ; cocher avec le hash du commit.

- [ ] Claude → Codex · `Tools.lua` · brancher le **harpon** comme outil (mis en main, clic) puis
      appeler `G.Fishing.harpoon(player)` (Claude écrit la fonction) · arme/outil de pêche demandé dans
      `A-RETRAVAILLER-EQUIPEMENT-ET-VISUELS.md`.
- [ ] Claude → Codex · `Gear.lua` + fiche Personnage · emplacement **main gauche** (bouclier, torche),
      les boucliers quittent les bijoux · Claude branchera ensuite la défense dans `Joueurs.stats` /
      `Combat` (lot C7).
- [ ] Claude → Codex · interface · 4 boutons d'ordres d'armée (suivre, tenir, patrouiller, attaquer) quand
      on a des soldats : `Action:FireServer("armee_ordre", { o = "suivre" | "tenir" | "patrouiller" |
      "attaquer", target = <id de la cible WoW> })` · aujourd'hui seulement par `/armee <ordre>` (lot C9).
- [ ] Claude → Codex · `ConstruireModeles` (créatures) · 3 formes neuves pour finir `listes ennemi.txt` :
      **cavalier** (brigand à cheval), **poisson** (poisson carnassier géant), **serpent marin** (long, crête)
      · Claude ajoutera les créatures au Bestiaire dès que les formes existent (lot C5).

---

## Couloir Codex — ce qu'on voit et ce qu'on touche

- [ ] **X1 · Menu commun PC / tactile / manette.** Un seul registre (libellé, icône, action, raccourci)
      pour la colonne de menus, les boutons tactiles et la manette ; Sac, Carte, Journal, Personnage,
      Paramètres accessibles partout sans commande de chat. *Fini quand* : les cinq écrans s'ouvrent et
      se ferment sur les trois modes de commande (`AUDIT-PRODUIT.md`, ordre 1).
- [ ] **X2 · Journal des livraisons juste.** En cours — Codex, 19/11 (non commité : `Quetes.view`
      compte le sac, `Quetes.client`). *Fini quand* : accepter à vide affiche 0/N, le stock partiel /
      complet / retiré met l'état à jour, la remise reste validée par le serveur.
- [ ] **X3 · Fenêtres cohérentes.** Titre, fermeture, retour, état vide, focus manette ; une fenêtre
      ouverte n'envoie pas de coup ni de pose derrière elle ; ordre de retour prévisible.
- [ ] **X4 · Petits écrans et mobile.** Disposition étroite par famille de fenêtres, zones sûres,
      défilement vertical, boutons assez grands, chat / clavier ouverts. Garder les proportions du HUD.
- [ ] **X5 · Emplacement main gauche** (passage ci-dessus) : emplacement, poupée de la fiche, modèle
      porté par l'avatar.
- [ ] **X6 · Harpon** (passage ci-dessus) : modèle, outil en main, animation de lancer.
- [ ] **X7 · Modèles faux.** Corriger la liste « Visuels à retravailler » de
      `A-RETRAVAILLER-EQUIPEMENT-ET-VISUELS.md` et `AUDIT-VISUELS-OBJETS.md` (noyau de cerise, laine,
      couronnes, turban, carreaux, insignes…). *Fini quand* : chaque objet de la liste ressemble à son
      nom sur la planche de `images/catalogue`.
- [ ] **X8 · Icônes peintes.** Préparer les images (barre rapide, sac, menus) dans `images/icones/` +
      une table `id → image` prête à remplir avec les identifiants Roblox ; garder l'emoji en secours
      tant que l'image n'est pas en ligne.
- [ ] **X9 · Pièces de créatures distinctes.** Les « Collier de crocs de … » / « Lame venimeuse de … »
      ont toutes la même forme : une silhouette par famille (crocs, écailles, plumes, glace…).
- [ ] **X10 · Atelier : recherche + fiche de recette unique.** Ingrédients possédés, station,
      compétence et raison du verrouillage sur une seule fiche (`AUDIT-PRODUIT.md`, ordre 5).
- [ ] **X11 · Paramètres.** Caméra, sensibilité, qualité graphique, taille du texte (étape 20).
- [ ] **X12 · Style médiéval uniforme.** Lumière, matériaux, proportions, couleurs saturées et
      chaudes comme l'image cible ; retirer les modèles, sons et icônes temporaires (étape 21).
- [ ] **X13 · Sons manquants.** Outils, forge, portes, animaux, interface, coup reçu, vente,
      découverte ; uniquement des sons autorisés (bibliothèque Roblox sous licence). Trouver l'appel qui
      charge l'asset `203785492` (type incompatible en console).
- [ ] **X14 · `docs/INTERFACE.md` à jour** après X1–X4 (raccourcis, boutons, manette).

## Couloir Claude — les règles et le monde

- [x] **C1 · Banc de régression unique.** FAIT 20/11 (edef686) : 39 bancs, ~2 min, ménage des restes. `tools/bancs/tout.luau` lance tous les bancs Edit et rend un
      résumé (vert / rouge par banc). *Fini quand* : un seul appel suffit avant chaque fin de lot.
- [x] **C2 · Revue sécurité des actions ajoutées les 18-19/11** (Ventes, Chantiers, QuetesLieux,
      Ouvriers, Villes, Ecurie, Fouilles, Concours…) : distance, possession, répétition, double
      paiement, déconnexion au milieu. Un banc qui rejoue les abus. (Plan étape 1B / 26A.) FAIT 20/11 :
      « nan »/« inf » en texte bloqués (3c5295d, banc `securite` 14/14), clan fondé gratuitement en
      dépensant l'or pendant l'attente du DataStore (f2385ef). Ventes, Activites, Chantiers, Villes : RAS.
- [x] **C3 · Fiche de test en Play pour le propriétaire.** `docs/TEST-PLAY.md` : les 4 parcours de
      référence (mains vides → outil → vente ; panneau → parcelle → protection ; découverte → grotte →
      retour ; accueil → voyage → reconnexion) + un parcours à deux joueurs, avec ce qu'il faut
      regarder et où noter les bugs (`retours.txt` à la racine). FAIT 20/11 (6290f5e).
- [x] **C4 · Quêtes manquantes** — FAIT 20/11 (aef971b) : livrer, réparer, étal (banc `quetes_lieux` 23/23) ;
      métiers / justice / navigation / coopération existaient déjà (fabriquer, prime, naviguer, chasse en groupe). (`MISSIONS.md`) : livraison à domicile, réparation effective,
      installation d'étals ; puis métiers, justice, navigation, coopération — toujours facultatives,
      toujours données sur place.
- [x] **C5 · Fin du bestiaire** — 20/11 : il ne manque que 3 créatures qui demandent des formes neuves
      (passage à Codex ci-dessus) ; le reste existe (Enemies + Bestiaire, 165 créatures). (`listes ennemi.txt`) : aquatiques, dragonnets, griffons, PNJ civils
      restants, faune passive restante — avec les formes existantes ; une forme neuve = passage à Codex.
- [ ] **C6 · Fin du catalogue** (`liste items.txt`, ~300 entrées) : rapprocher entrée par entrée de
      `docs/REFERENCE.md` (déjà là sous un autre nom ?), ajouter le reste par lots dans `Equilibre`
      avec un usage ; formes neuves = passage à Codex.
- [ ] **C7 · Harpon côté pêche** (`Fishing.harpoon`) **et main gauche côté stats** (`Joueurs.stats`,
      `Combat`), dès que les deux passages sont faits.
- [ ] **C8 · Équilibrage global** (étape 26B) : banc qui mesure, pour chaque métier, le temps pour
      gagner 100 or et les sources / dépenses d'or ; `docs/EQUILIBRE-ECONOMIE.md` ; corriger ce qui
      rend une activité inutile.
- [x] **C9 · Armée façon Warcraft v2** — FAIT 20/11 (banc `armee` 15/15, voir commit) ; : recrues entraînées à la caserne, ordres (suivre, tenir,
      attaquer, patrouiller), dure et sans triche, limitée par la solde et les vivres seulement.
- [ ] **C11 · Plusieurs serveurs sur un même monde** (étape 25) : vérifier secteurs, verrous,
      registre ; banc de concurrence.
- [ ] **C12 · Performance** (étape 25) : budgets écrits, coût de la carte complète, des aperçus 3D,
      d'un village chargé ; dégradation gracieuse.
- [ ] **C13 · Administration** (étape 24) : tableau de bord `/wa` (serveurs, mondes, erreurs,
      sauvegardes), lecture des journaux d'économie et de clan.

## Pour le propriétaire (personne d'autre ne peut le faire)

- [ ] Tester en Play sur le PC fixe avec `docs/TEST-PLAY.md` ; écrire les bugs dans `retours.txt`.
- [ ] Répondre aux « Questions en attente » ci-dessus.
- [ ] Envoyer les icônes peintes avec son compte (après X8).
- [ ] Publier (Game Settings : accès API, 45 joueurs max), test en ligne à deux comptes.
- [ ] `! git push` régulièrement.

---

## Journal (5 lignes maximum par session)

- 20/11 · Claude : fiche `AGENTS.md` + ces lots. Codex a du travail non commité sur HUD, Interface,
  Avatar, Gear, Combat, Quetes, Tools, Config, Catalogue, `GearDesign.lua` (à commiter par Codex).
