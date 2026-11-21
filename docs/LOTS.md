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
- [ ] Claude → Codex · carte (X15) · **repères gardés par monde** (serveur prêt 21/11, `Systemes/Infos`, banc `infos`) :
      `Remotes.Infos:InvokeServer("reperes")` → `{ { id, x, z, sorte, nom } }` ; poser =
      `Action:FireServer("repere_poser", { x, z, sorte = "village"|"lit"|"parcelle"|"quete"|"perso" })` ;
      retirer = `Action:FireServer("repere_retirer", { id })`. Pas de texte libre (nom donné par le serveur).
- [ ] Claude → Codex · panneau de propriété (X18) · **aperçu avant la pose** (serveur prêt 21/11) :
      `Remotes.Infos:InvokeServer("parcelle", { x, z })` → `{ ok, motif, prix, n, half }` (10 appels/s max :
      ne demander qu'au changement de case). Contour = carré de `2 × half` studs centré sur le point.
- [ ] Claude → Codex · interface (X16) · **toasts de sorte `"refus"`** : Batir (trop loin, trop haut, village,
      même pièce, plus dans le sac) et Parcelles (terrain d'autrui, panneau refusé) les envoient maintenant avec
      `kind = "refus"` → les afficher près du fantôme / du panneau (aujourd'hui : toast normal).
- [ ] Claude → Codex · invite au survol (X19) · **état des cultures en attributs** sur le modèle `Culture`
      (Systemes/Farm, 21/11) : `Plante` (nom), `Jour` / `Jours` (pousse), `Arrosee`, `Fletrie`. Machines et coffres :
      demander les attributs voulus par un passage.

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

- [ ] **X15 · Repères sur la carte** (`AUDIT-PRODUIT.md` ordre 6). Le joueur pose / retire ses repères (village
      connu, lit, parcelle, ville où rendre une quête), légende, minicarte ≠ carte du monde. Repères gardés côté
      client (`Preferences`) ; s'il faut les sauver dans le profil → passage à Claude. *Fini quand* : poser,
      retirer, reconnexion = repères toujours là.
- [ ] **X16 · Motifs de refus et alertes lisibles** (ordre 7). Une pose refusée dit pourquoi (le serveur envoie
      déjà un toast : l'afficher près du fantôme), rotation / valider / annuler visibles en mode [V], gains
      répétés regroupés (« +5 Bois » au lieu de 5 toasts), alerte de combat ou de cambriolage qui reste
      visible pendant une série de récoltes.
- [ ] **X17 · Composants d'interface communs** (ordre 8). Un module (titre, bouton, quantité, avertissement,
      icône) utilisé par toutes les fenêtres ; états disponible / sélectionné / verrouillé avec couleur **et**
      symbole (daltonisme). Remplacer d'abord les emojis ambigus.
- [ ] **X18 · Périmètre de parcelle avant la pose.** Contour de la parcelle 12×12 au sol quand on tient le
      panneau, rouge si chevauchement ou village, coût du terrain suivant affiché. Données : `Parcelles` (lecture
      seule ; besoin d'une fonction serveur → passage à Claude).
- [ ] **X19 · État lisible à proximité** : culture (pousse, arrosée, prête), machine (roue à eau, four), coffre
      verrouillé — en **invite au survol / à [E]** comme « [E] Parler », **jamais de texte permanent au-dessus des
      PNJ ni des objets**.
- [ ] **X20 · Formes de construction × matières** (reste du lot C6) : `liste items.txt` § construction —
      escaliers, arches, demi-murs, colonnes, rambardes, volets, en bois / pierre / brique / chaume. Modèles +
      fantôme `Batir` ; donner la liste à Claude (passage) pour les recettes, prix et usages dans `Equilibre`.
- [ ] **X21 · Mobilier et décor posables** (reste C6) : tables, bancs, étagères, tapis, bannières, pots,
      lanternes murales… Modèles + miniatures ; passage à Claude pour recettes. Règle 7 : rien sans usage.
- [ ] **X22 · Arrivée et retour lisibles** (`AUDIT-PRODUIT` « Arrivée et retour ») : sans tutoriel (règle 1) —
      repères visibles au lieu de départ (panneau de village, lueur de l'atelier, fumée du four), lit et journal
      d'absence faciles à retrouver au retour. Vérifier la création de perso sur petit écran.
- [ ] **X23 · Carte du monde légère** (côté client du lot C12) : la grille se construit au rendu → la construire
      par morceaux / la mettre en cache, limiter les aperçus 3D visibles (`ViewportFrame`) et les `RenderStepped`.
      Noter avant / après dans `docs/PERFORMANCE.md` (mesures en Play sur le PC fixe).
- [ ] **X24 · Sons de la 2e vague** : construction (pose, casse), serrure / crochetage, alarme, cheval, pluie,
      ambiance de grotte ; bibliothèque Roblox sous licence uniquement.
- [ ] **X25 · Icônes peintes, 2e lot** : équipement (9 emplacements × formes), matières de créatures, objets de
      X20 / X21 ; même atlas que d28d1f0, emoji en secours.
- [ ] **X26 · `docs/INTERFACE.md` + planches** à jour après X15–X25.

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
- [~] **C6 · Fin du catalogue** — 20/11 : 532 / 812 entrées déjà là (souvent sous un autre nom) ; ajouté 17 outils de
      métier du sac ; reste surtout de la construction (formes × matières, couloir Codex) et du décor ; (`liste items.txt`, ~300 entrées) : rapprocher entrée par entrée de
      `docs/REFERENCE.md` (déjà là sous un autre nom ?), ajouter le reste par lots dans `Equilibre`
      avec un usage ; formes neuves = passage à Codex.
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
