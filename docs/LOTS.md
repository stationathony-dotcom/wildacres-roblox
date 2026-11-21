# Wild Acres — lots de travail Codex / Claude

Règles de partage : [`AGENTS.md`](../AGENTS.md). Chacun prend **le premier lot libre de sa colonne**,
écrit « en cours — <nom>, <date> », puis le coche avec ses commits. Ordre = priorité (le socle et ce
que le joueur voit en premier passent avant le nouveau contenu).

But : cocher tout l'« AUDIT FINAL » de `Wild_Acres_plan_step_by_step_complet.md` (chaque ligne cochée
ou marquée « volontairement absent »), en respectant les règles d'`AGENTS.md` § 1.

---

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

- [x] **Saisons** — RÉPONSE 20/11 : non → retirées (`Meteo` : un seul tirage, les cultures poussent tous les jours).
- [x] **Froid / chaleur** — RÉPONSE 20/11 : non → retirés ; la boue des marais et l'obscurité des grottes restent
      (il les avait demandées le 19/11) ; talent Survivaliste = ni boue ni obscurité ; couverture = couverture de cheval.
- [x] **Qualité de façon + signature** — RÉPONSE 20/11 : non → retirées ; l'artisan reste noté (caché) pour son renom.
- [x] **Canal d'appel des sanctions** — RÉPONSE 20/11 : « un truc de demandes + un report bug » → `Systemes/Demandes`
      (`/demande`, `/bug`, `/appel`), bannissement maison qui laisse l'accueil pour faire appel.
- [ ] **Icônes peintes** : il faut mettre les images en ligne avec le compte Roblox du propriétaire
      (lot X8 prépare les fichiers, le propriétaire les envoie).

## Passages (demandes entre couloirs)

Format : `- [ ] <qui> → <à qui> · <fichier> · <besoin> · <pourquoi>` ; cocher avec le hash du commit.

- [x] (54069dc) **URGENT** Claude → Codex · `Interface.client.lua` · l'écran d'apparence plante (Play du 21/11 soir, PC fixe) :
      `Interface:2461: attempt to index nil with 'Visible'`. Le gestionnaire `Menu` `data.kind == "look"` (≈ l. 2462 sur disque)
      écrit `lookInfo`, `lookCtx`, `lookDraft`, `charTab`, `bag`, `renderChar`, qui sont des locales du bloc `do` de la fiche
      personnage (l. 1478–1889) : hors du bloc ce sont des globales nil (aussi `lookInfo, lookCtx = nil, nil` du « close »).
      → déclarer `local openLook, closeLook` à côté de `local toggleChar`, les définir dans le bloc, les appeler dans le
      gestionnaire · création de personnage à l'arrivée, barbier et tailleur cassés.
      → corrigé (54069dc) ; vu en Play le 21/11 soir : création, barbier, tailleur et fermeture serveur sans erreur.
- [x] Claude → Codex · `Tools.lua` · brancher le **harpon** comme outil (mis en main, clic) puis (b405756)
      appeler `G.Fishing.harpoon(player)` (FONCTION PRÊTE le 20/11, banc `harpon` ; objet `harpoon` à créer comme outil) · arme/outil de pêche demandé dans
      `A-RETRAVAILLER-EQUIPEMENT-ET-VISUELS.md`.
- [x] Claude → Codex · `Gear.lua` + fiche Personnage · emplacement **main gauche** (bouclier, torche), (a23919e)
      les boucliers quittent les bijoux · Claude branchera ensuite la défense dans `Joueurs.stats` /
      `Combat` (lot C7).
- [x] Claude → Codex · interface · 4 boutons d'ordres d'armée (suivre, tenir, patrouiller, attaquer) quand (b65ef70)
      on a des soldats : `Action:FireServer("armee_ordre", { o = "suivre" | "tenir" | "patrouiller" |
      "attaquer", target = <id de la cible WoW> })` · aujourd'hui seulement par `/armee <ordre>` (lot C9).
- [x] Claude → Codex · interface · formulaire « Écrire à l'équipe » (Paramètres [O] et écran d'accueil) : choix (8a0b67f)
      Demande / Bug / Appel + texte (10 à 300 lettres) → `Action:FireServer("demande", { kind = "demande" | "bug" |
      "appel", text = … })` ; sur l'accueil, si l'attribut joueur `Banni` existe : bouton Jouer grisé + le formulaire
      d'appel bien visible · aujourd'hui seulement par `/demande`, `/bug`, `/appel` (Systemes/Demandes).
- [x] Claude → Codex · `Ambiance.client` · retirer la neige d'hiver (`Season == "hiver"`, l'attribut n'est plus (4bc8fc6)
      posé : rien ne casse, c'est du code mort) et l'écran assombri reste pour « Obscur ».
- [x] Claude → Codex · `Interface.client` / `Gear.lua` · plus de « Façonnée par » ni de qualité sur les (27934fe)
      nouvelles pièces (les champs ne sont plus posés ; les anciennes pièces les gardent).
- [x] Claude → Codex · `ConstruireModeles` (créatures) · 3 formes neuves pour finir `listes ennemi.txt` : (ed00ed3)
      **cavalier** (brigand à cheval), **poisson** (poisson carnassier géant), **serpent marin** (long, crête)
      · Claude ajoutera les créatures au Bestiaire dès que les formes existent (lot C5).

- [x] (ba4b1d5) Codex → Claude · Equilibre.lua · ajouter une recette d’acquisition et un prix au harpon (id harpoon, déjà enregistré comme outil dans Config) · X6 doit être accessible dans une partie normale.

- [x] Claude → Codex · écran d'accueil · liste « Mes amis en jeu » : RemoteFunction `Remotes.Mondes`, (f3457d2)
      `InvokeServer("friends")` rend `{ { name, worldId, worldName } }` ; bouton Rejoindre = `InvokeServer("join",
      worldId)` · étape 13 « rejoindre un ami » (serveur prêt, d5a3c76).
- [x] Claude → Codex · carte (X15, b6bc44d) · **repères gardés par monde** (serveur prêt 21/11, `Systemes/Infos`, banc `infos`) :
      `Remotes.Infos:InvokeServer("reperes")` → `{ { id, x, z, sorte, nom } }` ; poser =
      `Action:FireServer("repere_poser", { x, z, sorte = "village"|"lit"|"parcelle"|"quete"|"perso" })` ;
      retirer = `Action:FireServer("repere_retirer", { id })`. Pas de texte libre (nom donné par le serveur).
- [x] Claude → Codex · panneau de propriété (X18, 3b60243) · **aperçu avant la pose** (serveur prêt 21/11) :
      `Remotes.Infos:InvokeServer("parcelle", { x, z })` → `{ ok, motif, prix, n, half }` (10 appels/s max :
      ne demander qu'au changement de case). Contour = carré de `2 × half` studs centré sur le point.
- [x] Claude → Codex · interface (X16, a1e4209) · **toasts de sorte `"refus"`** : Batir (trop loin, trop haut, village,
      même pièce, plus dans le sac) et Parcelles (terrain d'autrui, panneau refusé) les envoient maintenant avec
      `kind = "refus"` → les afficher près du fantôme / du panneau (aujourd'hui : toast normal).
- [x] Claude → Codex · invite au survol (X19, 3ae534f) · **état des cultures en attributs** sur le modèle `Culture`
      (Systemes/Farm, 21/11) : `Plante` (nom), `Jour` / `Jours` (pousse), `Arrosee`, `Fletrie`. Machines et coffres :
      demander les attributs voulus par un passage.
- [x] (0767a79) Codex → Claude · X19 · `Systemes/Machines`, `Shop` et `Protection` · publier sur les modèles de four et
      roue à eau `EtatMachine` (texte bref actualisé selon l’état) et `NomEtat` (nom affiché). Pour les coffres,
      publier `Verrouille` (booléen actualisé à la pose de la serrure). L’interface lit ces attributs à proximité.
- [x] Claude → Codex · `Activites.client` (864b1e0) · le tableau d'affichage envoie maintenant `data.kinds` = `{ { id, libellé } }`
      (21/11 : + « Concours de dressage » et « Concours d'élevage », comptés par le jeu, banc `concours`) → remplacer
      `KIND_LIST` codée en dur par `data.kinds` quand il est présent.
- [x] Claude → Codex · `ConstruireModeles` (e5ebd4f) · **cochon** et **oie** de ferme (dernières entrées de `liste items.txt`) :
      modèles « Cochon » et « Oie » comme « Poule » / « Vache » · Claude ajoutera `C.ANIMALS` (produits : truffes ?
      plumes / œufs d'oie) dès que les modèles existent. → FAIT par Claude (cba99ea) : `pig` (truffes) et `goose`
      (plumes) dans `Equilibre.FARM_ANIMALS`, achetés au fermier ; omelette aux truffes.
- [x] (c7615e7) Codex → Claude · X21 · `Equilibre.lua` et pose `Shop` · lanterne murale `wall_lantern`, modèle
      `Cat_wall_lantern` prêt (e5ebd4f), éclairage intégré. Ajouter recette, valeur et pose de bord, avec
      la potence côté joueur. Les miniatures reprennent le modèle dès que l’objet est disponible.
      → Serveur : `grid = "edge"`, `wallMount = true`, couche « applique » (même bord qu'un mur, une par face),
      posée à 0,3 du bord côté joueur, yaw = potence vers lui (banc `applique`). Fantôme client : même décalage.
- [x] (36224cc) Codex → Claude · X22 · `Systemes/Infos`, `Game` et `Protection` · `Infos:InvokeServer("retour")`
      doit fournir `{ lit = { x, z }?, absence = { { day, text } } }` pour le monde courant. Le lit vient
      de `rec.bed` et les entrées doivent rester consultables pendant la session après les toasts de retour.
- [x] (4466bf5, fef3c87) Codex → Claude · X24 · `Systemes/Batir` et `Shop` · émettre `G.Util.sfx("pose", pos)` après une pose
      réussie (pièce, plan, mobilier, remplacer « pelle » pour le plan) et `G.Util.sfx("casse", pos)` quand
      `Batir.smash` détruit la pièce · les clients voisins jouent le son à l’endroit de l’action.
- [x] (4466bf5) Codex → Claude · X24 · `Systemes/Protection` · émettre `G.Util.sfx("serrure", pos)` après une pose
      de serrure réussie et `G.Util.sfx("cloche", pos)` dans `Protection.ring` à la position de la cloche
      · réutiliser le canal Fx localisé pour les joueurs à portée.
- [x] Claude → Codex · icônes (X25, sur disque) · 21 nouvelles pièces de construction (`blk_<forme>_<matière>`, formes :
      poteaurond, demipoutre, madrier, chevron, echalas, poteausculpte, colonnecarree, murincline, colombages, clayonnage,
      treillis, niche, fondation, pavage, pilotis, balcon, gouttiere, lucarne, croisillons, volets, vitrail) + bride
      (`bridle`) et selle de guerre (`saddle_war`).
- [ ] Claude → Codex · interface du sac · « Utiliser » la Charte de ville (`charter`) : demander un nom (3 à 24 lettres)
      puis `Action:FireServer("ville_fonder", { nom = … })` ; la réponse arrive en toast (69c11f1).
- [ ] Claude → Codex · icônes (X25) · `throwing_axe` (⚔️), `caparison`, `music_sheet` (🎼), pièces `blk_caillebotis_*`,
      gisants (ex-squelettes : statues de tombeau en pierre, `Bestiaire` look `pierre = true`) dans les planches.
- [x] (30bbba0) Claude → Codex · icônes (X25) · `truffle`, `truffle_omelette`, `wall_lantern` (21/11 soir) ; cochon 🐖 / oie 🦆 au
      fermier en emoji (icône peinte bienvenue). Correspondances commitées. Atlas de la truffe à publier (propriétaire).
- [x] (a8d776e) Claude → Codex · `ConstruireModeles` · modèle **« Chevre »** (chèvre de ferme, comme « Mouton ») : la chèvre est
      déjà déclarée (`Equilibre.FARM_ANIMALS.goat`, ad75683) et apparaît chez le fermier dès que le modèle existe.
      Construit dans Studio (`ConstruireModeles.chevre()`) ; vu en Play : achetée, visible, traite = lait.
- [x] Claude · passages X24 (sons pose / casse / serrure / cloche) traités côté serveur (4466bf5, fef3c87) — Codex :
      coche tes deux lignes X24 ci-dessus.
- [x] (5ddb042, gardé : exception écrite dans AGENTS § 1) Codex → Claude · `Systemes/Admin.lua`, `Systemes/Util.lua` · mettre `/wa annonce` et les notifications à tous en conformité avec la règle 1, et faire trancher le statut du compte à rebours de maintenance · les clients affichent aujourd’hui les diffusions de `WA_Annonce` et le repli local peut envoyer le texte avant filtrage.
- [x] (69c11f1 : action `ville_fonder` { nom }) Codex → Claude · `Systemes/Villes.lua`, `Systemes/Joueurs.lua` · brancher l’usage de la charte dans le sac sur la même validation que `/fonder` si cette entrée est retenue pour le parcours · l’audit produit demande un accès à la fondation depuis la charte.
- [x] (917479c : caparaçon = +6 défense en selle ; compagnon : collier clouté et harnais existaient) Codex → Claude · `Systemes/Horses.lua`, `Systemes/Compagnons.lua` et `Shared/Equilibre.lua` · statuer sur le caparaçon et l’équipement de compagnon répertoriés comme manquants · les selles, étriers et la bride sont branchés, le collier sert à apprivoiser et le document d’équipement demande encore un effet porté.
- [x] (917479c : `throwing_axe` + 2 pièces qui la lancent) Codex → Claude · `Shared/Equilibre.lua`, `Systemes/Combat.lua` · confirmer le sort des haches de jet citées dans le document d’équipement · fronde, couteaux, javelots et flèches améliorées ont un chemin de jeu, la hache de jet n’en a pas.

---

## Couloir Codex — ce qu'on voit et ce qu'on touche

- [x] **X1 · Menu commun PC / tactile / manette.** FAIT 20/11 (b996876). Un seul registre (libellé, icône, action, raccourci)
      pour la colonne de menus, les boutons tactiles et la manette ; Sac, Carte, Journal, Personnage,
      Paramètres accessibles partout sans commande de chat. *Fini quand* : les cinq écrans s'ouvrent et
      se ferment sur les trois modes de commande (`AUDIT-PRODUIT.md`, ordre 1).
- [x] **X2 · Journal des livraisons juste.** FAIT 20/11 (9a82c27). *Fini quand* : accepter à vide affiche 0/N, le stock partiel /
      complet / retiré met l'état à jour, la remise reste validée par le serveur.
- [x] **X3 · Fenêtres cohérentes.** FAIT 20/11 (894842c, e1bdc6f). Titre, fermeture, retour, état vide, focus manette ; une fenêtre
      ouverte n'envoie pas de coup ni de pose derrière elle ; ordre de retour prévisible.
- [x] **X4 · Petits écrans et mobile.** FAIT 20/11 (5ffb22d, 752e439) · à voir en Play avec le clavier tactile. Disposition étroite par famille de fenêtres, zones sûres,
      défilement vertical, boutons assez grands, chat / clavier ouverts. Garder les proportions du HUD.
- [x] **X5 · Emplacement main gauche.** FAIT 20/11 (a23919e). Bouclier et torche visibles sur la poupée et portés par l’avatar.
- [x] **X6 · Harpon** (passage ci-dessus) : modèle, outil en main, animation de lancer. Modèle, prise en main et lancer faits (b405756) · recette ajoutée côté équilibre, lancer à voir en Play.
- [x] **X7 · Modèles faux.** FAIT 20/11 (28b395e, c46bcff, 7130dcb, 3cef209). Corriger la liste « Visuels à retravailler » de
      `A-RETRAVAILLER-EQUIPEMENT-ET-VISUELS.md` et `AUDIT-VISUELS-OBJETS.md` (noyau de cerise, laine,
      couronnes, turban, carreaux, insignes…). *Fini quand* : chaque objet de la liste ressemble à son
      nom sur la planche de `images/catalogue`. Modèles prioritaires et familles revus sur les planches 09 à 11. Vérifier leurs aperçus en Play.
- [x] **X8 · Icônes peintes.** FAIT 20/11 (d28d1f0) · publication au propriétaire. Préparer les images (barre rapide, sac, menus) dans `images/icones/` +
      une table `id → image` prête à remplir avec les identifiants Roblox ; garder l'emoji en secours
      tant que l'image n'est pas en ligne.
- [x] **X9 · Pièces de créatures distinctes.** FAIT 20/11 (19bed72, 597afba). Les « Collier de crocs de … » / « Lame venimeuse de … »
      ont toutes la même forme : une silhouette par famille (crocs, écailles, plumes, glace…).
- [x] **X10 · Atelier : recherche + fiche de recette unique.** FAIT 20/11 (9f9d802, 2bd382f). Ingrédients possédés, station,
      compétence et raison du verrouillage sur une seule fiche (`AUDIT-PRODUIT.md`, ordre 5).
- [x] **X11 · Paramètres.** FAIT 20/11 (17761a9). Caméra, sensibilité, qualité graphique, taille du texte (étape 20).
- [x] **X12 · Style médiéval uniforme.** FAIT 20/11 (fb36497, 3cef209). Lumière, matériaux, proportions, couleurs saturées et
      chaudes comme l'image cible ; retirer les modèles, sons et icônes temporaires (étape 21). Palette appliquée et capturée en Edit, relecture en jeu à faire.
- [x] **X13 · Sons manquants.** FAIT 20/11 (dd27096, 266139e). Outils, forge, portes, animaux, interface, coup reçu, vente,
      découverte ; uniquement des sons autorisés (bibliothèque Roblox sous licence). Trouver l'appel qui
      charge l'asset `203785492` (type incompatible en console). Effets ajoutés (dd27096). Rojo précharge son son de notification avec les URI d’images. Six effets du jeu préchargés en Edit.
- [x] **X14 · `docs/INTERFACE.md` à jour** FAIT 20/11 (b9c85af). après X1–X4 (raccourcis, boutons, manette).

### 2e vague Codex (écrite le 21/11) — finir ce que le joueur voit

- [x] **X15 · Repères sur la carte** — FAIT 21/11 (b6bc44d). Cinq types dans la légende de la carte du monde,
      pose et retrait, sauvegarde par monde via `Infos`. Bancs Édition 54/54. À voir en Play : pose, retrait,
      reconnexion et commandes à la manette / au tactile.
- [x] **X16 · Motifs de refus et alertes lisibles** — FAIT 21/11 (a1e4209). Refus près de la pose, commandes
      de construction selon l’entrée, gains cumulés, danger prioritaire. Vérifié en Édition : ancrage du refus
      et cumul de deux gains. À voir en Play : contrôles et alertes pendant les récoltes.
- [x] **X17 · Composants d'interface communs** — FAIT 21/11 (2f5e84d). Titres, boutons, quantités,
      avertissements et pictogrammes partagés. Sélection et verrouillage visibles par symbole et par couleur.
      Les trois états ont été vérifiés en Édition. À voir en Play : lisibilité et navigation des fenêtres.
- [x] **X18 · Périmètre de parcelle avant la pose** — FAIT 21/11 (3b60243). Contour au sol et prix de la case
      visée. Vérifié en Édition : coût, refus, une demande par case et rejet des réponses périmées.
      À voir en Play : alignement du contour sur des pentes et à la pose du panneau.
- [x] **X19 · État lisible à proximité** — FAIT 21/11 (3ae534f, 0767a79, e833e38). Cultures, machines et serrures
      au survol ou dans l’invite. Publication serveur et lecture client vérifiées en Édition sur four,
      roue à eau, coffre et porte. À voir en Play : visée et lisibilité sur petit écran.
- [x] **X20 · Formes de construction × matières** — FAIT PAR CLAUDE le 21/11 (bb861c5) : c'étaient des données
      (`Config.BUILD_SHAPES`, formes composées `SHAPE_PARTS`, rendues par Batir et le fantôme existant). Reste pour Codex :
      leurs icônes (X25).
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
- [~] **X25 · Icônes peintes, 2e lot** — Sur disque · Codex, 21/11 soir. 66 cases sur cinq planches
      couvrent les formes, l’harnachement, l’équipement, les matières, le mobilier et les deux objets de cuisine.
      Découpes contrôlées via l’alpha et ordre consigné dans le README. À vérifier en Studio / Play
      après publication des atlas par le propriétaire.
- [~] **X26 · `docs/INTERFACE.md` + planches** — Sur disque · Codex, 21/11 soir. Commandes, carte, pose,
      survol, retour et sons documentés. Les planches peintes complètent le catalogue. À vérifier
      en Studio / Play : vues et nouvelles captures indiquées dans les README.

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
- [x] **C5 · Fin du bestiaire** — 20/11 : complet, 168 créatures (les 3 dernières sur les modèles de Codex). (`listes ennemi.txt`) : aquatiques, dragonnets, griffons, PNJ civils
      restants, faune passive restante — avec les formes existantes ; une forme neuve = passage à Codex.
- [x] **C6 · Fin du catalogue** — FAIT 21/11 : `tools/rapprocher.py` coche `docs/INVENTAIRE-MISSIONS.md` (objets,
      créatures, quêtes, idées : 2 087 / 2 094) avec le nom en jeu ou la règle qui écarte ; ajouts : 21 formes de
      construction + 4 matières (bb861c5), bride / selle de guerre, concours de dressage / élevage, quêtes ronde /
      rencontrer / troupeau, route encombrée, chien de berger, cascades. Restent : cochon, oie (passage Codex) et
      les mesures en Play (C12).
- [x] **C7 · Harpon côté pêche et main gauche côté stats** — FAIT : harpon (ba4b1d5) ; la défense du bouclier passe
      déjà par `Gear.totals` (tous les emplacements) ; 21/11 : torche en main gauche = lumière des grottes, bottes
      lues dans le nouvel emplacement « boots » (régression des 9 emplacements, `Systemes/Froid`).
- [x] **C8 · Équilibrage global** — FAIT 20/11 : banc `economie` + `docs/EQUILIBRE-ECONOMIE.md` (médiane 43 or/min) ;
      pêche ×0,6 à la revente ; à confirmer en Play (les hypothèses de temps sont en tête du banc). (étape 26B) : banc qui mesure, pour chaque métier, le temps pour
      gagner 100 or et les sources / dépenses d'or ; `docs/EQUILIBRE-ECONOMIE.md` ; corriger ce qui
      rend une activité inutile.
- [x] **C9 · Armée façon Warcraft v2** — FAIT 20/11 (banc `armee` 15/15, voir commit) ; : recrues entraînées à la caserne, ordres (suivre, tenir,
      attaquer, patrouiller), dure et sans triche, limitée par la solde et les vivres seulement.
- [x] **C11 · Plusieurs serveurs sur un même monde** — vérifié 20/11 par lecture : un code réservé par monde,
      verrou de serveur sur l'état global (400 s, rafraîchi à chaque sauvegarde), le nouveau serveur attend
      45 s (> 30 s de fermeture) avant de reprendre, l'ancien cesse alors toute écriture ; secteurs écrits
      après l'état global. Test réel : P4 de `docs/TEST-PLAY.md`. (étape 25) : vérifier secteurs, verrous,
      registre ; banc de concurrence.
- [~] **C12 · Performance** — mesures à faire en Play (P7 de `docs/TEST-PLAY.md`), puis corriger ; (étape 25) : budgets écrits, coût de la carte complète, des aperçus 3D,
      d'un village chargé ; dégradation gracieuse.
- [x] **C13 · Administration** — FAIT 20/11 : `/wa etat` (le reste existait : journal, perf, joueur, coupe…) ; (étape 24) : tableau de bord `/wa` (serveurs, mondes, erreurs,
      sauvegardes), lecture des journaux d'économie et de clan.

## Pour le propriétaire (personne d'autre ne peut le faire)

- [ ] Tester en Play sur le PC fixe avec `docs/TEST-PLAY.md` ; écrire les bugs dans `retours.txt`.
- [ ] Répondre aux « Questions en attente » ci-dessus.
- [ ] Envoyer les icônes peintes avec son compte (après X8).
- [ ] Publier (Game Settings : accès API, 45 joueurs max), test en ligne à deux comptes.
- [ ] `! git push` régulièrement.

---

## Journal (5 lignes maximum par session)

- 21/11 · Codex · Vérification sur disque dans `docs/VERIFICATION-INTERFACE.md`. Invites clavier/tactile/manette, pictogrammes de secours, garde du butin et retrait des deux anciens modèles.
  Quatre passages serveur ouverts. À vérifier en Play : commandes et affichage des invites, butin près d’une invite Y, publication des atlas, audio et aperçus.

- 21/11 soir · Claude : passages X21 (lanterne murale), X22 (`Infos("retour")`), X24 (sons serveur) ; cochon, oie, chèvre au
  fermier ; bug « une bête payée n fois » corrigé. Play sur le PC fixe : régression 15/15, truffe, lait, lanterne, et plantage de
  l'écran d'apparence trouvé → corrigé par Codex (commité par Claude : Codex headless n'a pas accès à Git). 55/55 bancs verts.
  À voir en Play par le propriétaire : sons (7), miniature de lanterne, retour avec lit + journal, icônes après publication des atlas.

- 21/11 soir · Codex · Correctif d’apparence (54069dc), chèvre (a8d776e) et icônes (30bbba0).
  X21/X22/X24/X25/X26 committés. Six scripts client vérifiés dans Studio, chèvre et miniature de lanterne présentes.
  Banc complet relancé en Édition après synchronisation (6596a5a) : 55/55 verts en 109 s.
  À vérifier en Play : les sept sons, la miniature de lanterne et le retour avec lit et journal.
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
