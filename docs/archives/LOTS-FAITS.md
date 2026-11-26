# Lots et passages faits (archive)

Ne pas lire sauf besoin précis : chercher par numéro de lot (grep).

## Archivé le 2026-11-26


### Questions en attente (réponse du propriétaire nécessaire)

- [x] **Saisons** — RÉPONSE 20/11 : non → retirées (`Meteo` : un seul tirage, les cultures poussent tous les jours).
- [x] **Froid / chaleur** — RÉPONSE 20/11 : non → retirés ; la boue des marais et l'obscurité des grottes restent
      (il les avait demandées le 19/11) ; talent Survivaliste = ni boue ni obscurité ; couverture = couverture de cheval.
- [x] **Qualité de façon + signature** — RÉPONSE 20/11 : non → retirées ; l'artisan reste noté (caché) pour son renom.
- [x] **Canal d'appel des sanctions** — RÉPONSE 20/11 : « un truc de demandes + un report bug » → `Systemes/Demandes`
      (`/demande`, `/bug`, `/appel`), bannissement maison qui laisse l'accueil pour faire appel.

### Passages (demandes entre couloirs)

- [x] Claude → Codex (pour info) · `Shared/Eclairage.lua` (densité 0,27 → 0,20, voile 0,7 → 0,35) et `Ambiance.client.lua` (densités
      des météos un cran plus légères, brouillard 0,72 → 0,52) · fait par Claude le 25/11 (chantier D) : petits chiffres seulement.
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
- [x] Claude → Codex · interface du sac · « Utiliser » sur `charter` ouvre la saisie et appelle `ville_fonder` (serveur `69c11f1`).
      Côté client sur disque le 21/11. Synchronisation, bancs et commit par Claude.
- [x] Claude → Codex · icônes (X25) · `throwing_axe`, `caparison`, `music_sheet`, `truffle_cheese`, `fisher_platter`,
      `heartwood`, `franchise_letter`, arc et brigandine de bois de cœur, deux pièces de haches de jet et `blk_caillebotis_*`.
      Atlas et emojis de secours sur disque le 21/11. Aucune planche de créatures trouvée pour les gisants. Commit par Claude, publication par le propriétaire.
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

### Couloir Codex — ce qu'on voit et ce qu'on touche

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
- [x] **Groupes jusqu’à 40 · interface** — Codex, sur disque le 21/11. Liste défilante, distances actualisées et contours
      remis après réapparition. Synchronisation, bancs et commit par Claude. À vérifier en Play au-delà de cinq.
- [x] **Reprise de la vérification d’interface** — Codex, sur disque le 21/11. Un clic/toucher vaut une action de jeu.
      Boutons partagés dans le Tableau et l’Hôtel des ventes. Miniature des osselets déjà reprise (`64b3767`).
      Tableau actualisé dans [`VERIFICATION-INTERFACE.md`](VERIFICATION-INTERFACE.md). Synchronisation et commit par Claude.
- [x] **Vérification des props, phase 1** — Codex, 21/11 (11afc63, 64b3767). Planches et banc Edit, rapport initial de 417 props reçu.

### 3e vague Codex (écrite le 26/11) — « niveau planche » : props, ambiance, Store

- [x] **X29 · Contours façon planche** — FAIT par Claude 26/11 (Contours.client + attributs Boss/Elite dans Enemies). (client) : `Highlight` en contour seul (`FillTransparency = 1`,
      `OutlineColor` sombre) sur les boss proches et la créature ciblée ; **31 Highlight maximum** côté client →
      priorité aux plus proches, retrait au-delà de 120 studs.
- [x] **C19 · Combat par familles d'armes** — FAIT 26/11 (Claude) : profils, types de dégâts et résistances, enchaînements, coup chargé, garde / parade / esquive, armes à distance poussées, maîtrise ; banc `combat_armes` 16/16.

### Couloir Claude — les règles et le monde

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
- [x] **C13 · Administration** — FAIT 20/11 : `/wa etat` (le reste existait : journal, perf, joueur, coupe…) ; (étape 24) : tableau de bord `/wa` (serveurs, mondes, erreurs,
      sauvegardes), lecture des journaux d'économie et de clan.

### 3e vague Claude (écrite le 26/11)

- [x] **C16 · Vue aérienne** — FAIT 26/11 (e3c4981) : vrais arbres au loin, sol couleur terrain, côtes biseautées ; captures `captures/2026-11-26/lointain/`. Reste : le relief plat vient du tirage publié (gen 3 = décision du propriétaire).
- [x] **C18 · Montures façon WoW + volantes** — FAIT 26/11 (664c332) : collection + journal [N], invocation 2 s, rênes rares (13), Équitation (vol au niv. 25), Envol. À voir en Play.
