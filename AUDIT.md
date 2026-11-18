# Wild Acres — audit (étape 0) et socle de données (étape 1)

Photographie du projet au 17/11/2026, faite en lisant le code (23 000 lignes, 47 scripts) et en
testant dans Studio. Statuts : `absente / commencée / codée / testée Studio / testée en ligne / validée`.
**Rien n'est « testé en ligne »** : le jeu n'a jamais été publié (README, check-list du premier test).

Sauvegardes avant travaux : `..\wildacres_sauvegardes\wildacres_2026-11-17_avant_plan.rbxl` + commit `6ffd5ce`.
Version de test séparée : la place locale `wildacres.rbxl` (Studio, DataStores `*_studio`) ; la
version publique n'existe pas encore → à créer à l'étape 27 (deux places : test / production).

## Architecture (dépendances)

```
Main.server ── charge 39 systèmes (table G), ordre = NAMES ; un système en erreur → bouchon muet
  ├─ Interact   : SEULE entrée client → serveur (RemoteEvent Action + invites). Garde-fous communs.
  ├─ Save       : perso global (DataStore WA_Joueurs, clé p_<UserId>)
  ├─ Mondes     : registre (WA_Registre), état du monde (WA_Mondes m_<id> + secteurs 4×4 régions),
  │               présence (MemoryStore WA_EnLigne), voyage (TeleportService)
  ├─ Poste      : courrier (WA_Courrier m_<UserId>) + hôtel des ventes (dans le monde)
  ├─ Clans      : clans (WA_Clans c_<id>, nom_<nom>) ; coffre commun
  └─ tout le reste lit/écrit G.world (monde) ou G.Joueurs (perso) en mémoire
Remotes : Action (client→serveur), Notify, Inventory, Dialog, Menu, Fade, Fx (serveur→client),
          RemoteFunction Mondes (écran d'accueil). 59 actions + 31 invites, toutes branchées
          (aucun bouton client sans effet serveur ; « newgame » / « save » n'ont pas de bouton).
```

## Inventaire des données (1A)

| Où | Clé | Contenu |
|---|---|---|
| **Perso (global)** | `WA_Joueurs/p_<uid>` | `Save.FIELDS` : inv, gear, equipped, honor, horse, stats, level, xp, points, attrs, skills, talents, stars, bounty, col, titles, title, hotbar, known (recettes), clan, **banks[monde]**, look, journal, settings, mailClaimed ; + version, seq, lock, saved |
| **Monde (global)** | `WA_Mondes/m_<id>` | seed, gen, danger, name, day, minutes, npcs, law, players[uid] (pos, bed, seen, plots, pets, log, unpaid…), orders, market (HdV), mailQueue, extra ; + lock |
| **Monde (secteurs)** | `WA_Mondes/m_<id>_s_<sx,sz>` | par région : props, placed (objets posés, coffres, étals), built (construction libre), terra, planted, tilled, animals, myAnimals, horses, enemies, camps, chests, wrecked, removed, plots, graves, caves |
| Courrier | `WA_Courrier/m_<uid>` | colis {id, from, gold, items, t} |
| Clans | `WA_Clans/c_<id>` | membres, grades, coffre, journal, tx |
| Registre | `WA_Registre/liste`, `ps_<psid>` | mondes connus {name, seed, code, by, danger} |
| Interrupteurs | `WA_Interrupteurs/off` | action → raison (coupure d'urgence) |
| **Temporaire** (jamais sauvé) | — | cible, combat en cours, échange en cours, invitations, mini-jeux, pêche, voyage en cours, préparation d'attaque, porter un corps |

Budget : perso ≈ quelques Ko (inventaire = table de comptes, pas de cases) ; alerte à 3 Mo, refus
à 4 Mo (le perso n'est alors PAS écrit, l'ancien reste). Monde : écriture toutes les 150 s +
rapprochée (≤ 1 / 10 s) après coffre/étal/HdV ; perso toutes les 90 s.

## Étape 1 — ce qui a été corrigé (bugs trouvés à l'audit)

| Gravité | Bug | Correction |
|---|---|---|
| **Bloquant** | Lecture du perso en échec (DataStore en panne) → `nil` → perso NEUF qui écrasait le vrai à la première sauvegarde | `load` renvoie `"error"` ; le joueur est renvoyé avec un message, rien n'est écrit |
| **Bloquant** | Verrou de 60 s mais sauvegarde toutes les 240 s : le verrou « expirait » en plein jeu → un 2e serveur pouvait charger le perso (duplication entre mondes) | verrou 300 s, rafraîchi toutes les 90 s |
| **Bloquant** | Lecture du monde en échec → monde neuf généré puis **sauvé par-dessus** le vrai | `Mondes.acquire` (6 essais) ; échec = serveur en lecture seule, joueurs renvoyés |
| **Bloquant** | Secteur illisible → marqué prêt → réécrit vide (constructions perdues) | secteur `failed`, jamais réécrit |
| Majeur | Ordre des `PlayerRemoving` non garanti : `Joueurs` pouvait vider le profil AVANT la sauvegarde → départ = jusqu'à 4 min perdues + verrou non levé | profil vidé 10 s après ; instantané pris sans attendre |
| Majeur | `Mondes.saveWorld` : une erreur d'un système laissait `saving = true` → **plus aucune** sauvegarde du monde | `pcall` + drapeau toujours relâché |
| Majeur | Voyage : verrou levé AVANT la téléportation ; si elle échouait, plus aucune sauvegarde possible ; échec asynchrone (`TeleportInitFailed`) ignoré → joueur bloqué sur l'écran noir sans remboursement | verrou gardé (levé au départ réel), `travelFailed` rembourse une fois et rouvre l'écran |
| Majeur | Banque du village dans le monde, sac dans le perso : arrêt brutal entre deux écritures = duplication ou perte | banque **dans le perso** (`banks[monde]`), migration automatique de l'ancienne |
| Majeur | Courrier : boîte tronquée à 100 colis (les plus vieux détruits) ; collecte = vidage puis crédit (panne → perte) ; erreur réseau après écriture → remboursement + livraison (doublon) ; paiement HdV perdu si la poste échoue | colis à identifiant, livraison vérifiée par relecture, collecte « créditer → noter → sauver → vider », file de réessai sauvegardée dans le monde |
| Majeur | `Joueurs.take(p, x, -5)` **donnait** 5 ; NaN/∞ acceptés | quantités entières positives finies seulement (take et add) |
| Majeur | Une action qui attend un DataStore pouvait être relancée en parallèle (double retrait) | anti-réentrée par sorte d'action dans `Interact` |
| Mineur | Coffre de clan : erreur réseau après écriture → remboursement à tort (doublon) | identifiant de transaction relu |
| Mineur | `Poste.send/list` avec 0 objet : `math.clamp(…, 1, 0)` plantait | garde |
| Mineur | Agrandir la banque possible de n'importe où | proximité exigée |
| Esthétique | `rbxassetid://203785492` « Asset type does not match » ×3 au lancement (créé à l'exécution, pas dans les scripts) | à identifier |

Bancs : `tools/bancs/save_concurrence.luau` (2-3 serveurs simulés, pannes, JSON corrompu, écriture
tardive) — **tous verts**. `tools/bancs/pousser.luau` pousse `src/` dans Studio après contrôle de syntaxe.

### Risques restants assumés (documentés, pas cachés)

- Coffres posés, étals, hôtel des ventes : objets dans le monde, or/sac dans le perso → deux
  écritures distinctes. Fenêtre réduite à quelques secondes (`Mondes.saveSoon`) mais pas nulle.
  Supprimer totalement ce risque demanderait un journal de transactions rejoué au démarrage :
  à faire si l'économie en ligne montre des anomalies (le registre `Economie.ledger` les signalera).
- Le registre `Economie.ledger` est en mémoire (600 lignes) : il faut un puits durable (étape 24).
- Interrupteurs d'urgence : branchés, mais il manque l'outil admin en jeu pour les manipuler (étape 24) ;
  en attendant : `G.Interact.setSwitch("stall_buy", "exploit")` depuis la console serveur.

## État des fonctionnalités (étape 0)

| Domaine | Statut | Remarques de l'audit |
|---|---|---|
| Accueil / mondes réservés / registre | codée | jamais testée en ligne ; création simultanée de mondes : `UpdateAsync` sur la liste, OK |
| Sauvegarde perso + verrou | **testée Studio** (bancs) | réécrite à l'étape 1 |
| Sauvegarde monde par secteurs | codée | verrou de monde ajouté |
| Personnage : fiche, équipement, stats, talents, compétences | testée Studio | apparence non personnalisable (étape 2B) |
| Sac WoW, barre rapide, atelier 3×3, recettes | testée Studio | |
| Construction libre, mobilier, catalogue 373 objets | testée Studio | |
| Ferme, élevage, pêche, cuisine, inventions | testée Studio | |
| Créatures (52), boss, donjons, combat, cible | testée Studio | |
| Loi : crimes, témoins, shérif, primes | testée Studio | |
| Échange, commandes, banque, étal, HdV, courrier | codée → **testée Studio** (banque, courrier) | |
| Groupes, clans, auberge, titres | codée | clans jamais testés à plusieurs |
| Armée, territoires de clan | codée | avant-postes absents |
| Événements v1 | codée | |
| Navigation (barque) | **absente** | |
| Politique de village | **absente** | |
| Activités créées par les joueurs | **absente** | |
| Météo, saisons | **absente** (crue seulement) | |
| Faune passive | **absente** | |
| PNJ : routines, métiers | commencée | horaires simples |
| Admin / modération / signalement | **absente** | |
| Paramètres (audio, caméra, effets) | **absente** | |

Systèmes en doublon / archives : `ServerStorage.Modeles_Avant_Medieval` (archive volontaire des anciennes
maisons, à supprimer à la publication). Aucun script orphelin : Studio et `src/` sont identiques.

## Décisions (plan « DÉCISION ») — tranchées ici, contestables

- **Faim / soif / fatigue / température : volontairement ABSENTES** comme jauges qui descendent.
  Raison : le jeu est un bac à sable sans corvée ; une jauge qui baisse en permanence punit le joueur
  occasionnel. La nourriture reste un **bonus** (soin, endurance, buffs de cuisine) — c'est déjà le cas.
- **Combat joueur contre joueur** : existe déjà sous forme de « crime » (assommer = crime, témoins,
  shérif, primes). Pas de zone PvP libre. Zones sûres : arrivée (bouclier 20 s) et villages gardés.
- **Monétisation** : aucune pour l'instant (jeu complet sans achat). À rediscuter avant publication ;
  si un jour : cosmétiques uniquement, jamais d'objet aléatoire payant.
- **Durabilité des outils** : non (n'ajoute pas de choix intéressant ; le coût est dans la fabrication).

## Critères de validation (avant de cocher une étape)

Ceux de la « règle de fin de tâche » du plan. En pratique ici : banc reproductible dans `tools/bancs/`
quand c'est testable sans joueur, sinon pas-à-pas DbgAppel en Play, et la mention « non testé en ligne »
tant que la publication n'a pas eu lieu.

## Idées refusées ou reportées (à ne pas confondre avec des oublis)

- Guerres de clans déclarées : **refusé** (tout organique).
- Jauges de survie : **refusé** (voir décisions).
- Casino / paris : **refusé** (règles Roblox + design).
- Durabilité / usure : **refusé**.
- Ânes, mulets, charrettes : **écartés** tant que le sac n'a pas de limite de poids (règle « pas de
  plafond arbitraire ») : une bête de somme n'aurait aucune utilité réelle. À rouvrir si un jour le
  transport de marchandises lourdes (pierres de taille, bois de charpente) devient une mécanique.

## Étape 4A — catalogue (640 objets, 510 recettes)

Audit automatique (usage = ingrédient, nourriture, outil, posé, bloc, utilisable, graine, arme,
équipement, objet de valeur ; source = recette, boutique, ou référencé par un système).
- **16 objets sans aucun usage** → tous ont maintenant une fonction : savon (+3 charisme 20 min),
  encens (+3 chance 20 min), gourde / outre (boire : endurance, réutilisables), nourriture animale
  (la bête produit un jour plus tôt, 1×/jour), clochette de troupeau (tes bêtes à 120 studs te
  suivent), poudre minérale (engrais), assiette / assiette en bois (+25 % de soin en mangeant),
  louche / cruche / cuillère (25-30 % de portion en plus en cuisine), plume (une recette de plus
  quand on lit), collier de chien (apprivoiser plus facile), vinaigre (→ oignons au vinaigre),
  clous de cuivre (→ caisse clouée). Bonus temporaires sauvegardés (`buffs`).
- **Doublons de nom** : « Collier » (bijou / chien) → « Collier de chien » ; « Crochet » (serrure /
  pêche) → « Hameçon ».
- Sources : les graines (vendues par les villages, ajoutées dynamiquement) et les graines d'arbre
  (abattage) sont de faux positifs du banc. Restent sans source vérifiée : `wall`, `wall2`,
  `wall_*`, `stairs`, `floor2` (anciennes pièces de construction d'avant la construction libre) et
  `gold_coin`, `silver_coin`, `bill_exchange`, `traveler_journal` (trésors) — à confirmer.
- Icônes : rien au-delà d'Unicode 12 (les 13+ s'affichent en carré vide dans Roblox).

## Étape 6 / 12A — arbitrage

- **Faille corrigée** : le prix de rachat d'un marchand montait avec le charisme, les talents,
  la compétence Commerce et la foire, alors que son prix de vente baissait avec le charisme et
  l'honneur → acheter puis revendre au même comptoir rapportait jusqu'à ~3× la mise. Invariant
  posé dans `Shop.sellPrice` : rachat ≤ 80 % du prix de vente du marchand au même joueur.
- Recettes « pompe à or » à partir d'ingrédients vendus en boutique (planches → gobelets,
  assiettes, chevilles, cuillères, cerceau) : prix ou rendement réduits. Les objets à fort ratio
  restants demandent des ressources récoltées ou une compétence (valeur du travail, voulu).
- Aucune recette ne rend plus d'un de ses propres ingrédients qu'elle n'en consomme.

## Étape 17 — météo et saisons (`Systemes/Meteo`, client `Ambiance`)

États : clair, nuageux, pluie, orage, brouillard (1 h 30 à 5 h de jeu), tirés selon la saison
(7 jours chacune). Effets : pluie/orage arrosent toutes les cultures en direct (remplace le tirage
« 18 % de pluie » du matin, annoncé par un toast) ; foudre près des joueurs à découvert (35 dégâts) ;
brouillard = témoins à 50 % de vue, orage 75 %, pluie 85 % ; pluie = touches de pêche 35 % plus
rapides ; hiver = cultures un jour sur deux. Rendu : averse autour de la caméra (neige en
toundra ou en hiver hors désert, rien sous un toit ni au désert), nuages, brume, grisaille,
éclairs avec tonnerre retardé par la distance. Forcer : `DbgAppel:Invoke("Meteo.force", "orage")`.

Sons (étape 22, droits) : pluie = « Rain On Water 1 » (Pro Sound Effects, licence Roblox),
vent = « Wind Ambience » (s_onadow), tonnerre = « WX_Thunder_* » (MSDLF) — audios gratuits du
Creator Store ; les deux derniers sont des envois d'utilisateurs : à remplacer par des sons Pro
Sound Effects avant publication si un doute existe. Écartés : sons « God of War » (droits de tiers).

## Étapes 22 / 24 — administration et protection (`Systemes/Admin`)

- `/bloquer <pseudo>`, `/debloquer`, `/bloques` (tous) : un joueur bloqué ne peut plus proposer
  d'échange, inviter en groupe ou en clan, ni envoyer de courrier (vérifié aussi hors ligne via la
  sauvegarde du destinataire). Le signalement reste celui de Roblox (menu Échap), conforme aux règles.
- `/wa …` (créateur + `Config.ADMINS`) : météo, coupe/rallume une action sur tous les serveurs,
  annonce inter-serveurs filtrée, sauvegarde immédiate, fermeture de maintenance avec compte à
  rebours, versions et restauration d'un perso, don d'objets (réparation), lecture du journal.
  Chaque commande admin est journalisée.
- Journal durable : le registre est recopié toutes les 60 s dans `WA_Journal/<monde>_<AAAAMMJJHH>`.
- Piège noté : `MessagingService:SubscribeAsync` peut bloquer dans Studio → toujours en `task.spawn`
  (sinon l'init de Main ne finit pas et `DbgAppel` n'existe jamais).

## Étape 15D — politique de village (`Systemes/Politique`, client `Conseil`)

Invite « Conseil du village » dans la chapelle (sinon marché, sinon taverne). Habitant = parcelle à
moins de 260 studs du centre. Vote permanent, décompte au lever du jour ; maire absent 14 jours =
mairie vacante. Trésor : dons + taxe des étals du village (0-15 %, fixée par le maire ; sans maire
5 % détruits comme avant). Projets réels : foire (+30 % aujourd'hui), réparations immédiates,
ronde de nuit (témoins +50 % de vue, 7 jours). Registre public. Testé en Play : candidature,
vote, don, élection au lever du jour, taxe, projet payé.
Reste (projets plus lourds) : routes, ponts, puits, palissade à construire par projet.

## Étape 16B — barque (`Systemes/Barques`) · Étape 19 — activités des joueurs (`Systemes/Activites`, client `Activites`)

- Barque : objet fabriqué (12 planches, 2 cordes, établi), mise à l'eau devant soi, pilotée par le
  serveur d'après le banc du rameur (propriétaire seulement ; un autre est descendu), place passager,
  inertie, s'échoue sur la rive avec un petit choc, ralentie par l'orage, reprise au sac (invite
  maintenue), sauvegardée dans le monde. Testé en Play (18 studs en 3 s, perso à bord, reprise).
  Reste : ports, îlots, voiliers, cargaison.
- Tableau d'affichage (marché du village) : concours de pêche / de récolte arbitrés par le jeu,
  rassemblement libre jugé par l'organisateur (2 h de jeu, sinon cagnotte rendue). Cagnotte
  bloquée à la création, rendue par courrier ; aucune récompense créée par le jeu ; on s'inscrit
  soi-même ; l'organisateur ne peut pas gagner ; un joueur qui l'a bloqué ne voit pas ses annonces.
  Testé : création (or bloqué), annulation (or rendu par courrier), fin automatique sans
  participant (cagnotte 300 rendue par courrier, 18/11).

## Étape 21 — bruitages

`Util.sfx(nom, position, [joueur])` → client `Ambiance` : son 3D (atténué à 90 studs), hauteur
variée ±8 %, anti-mitraillage, fondu de sortie, préchargé. Branchés : hache, pioche, pelle (récolte),
coup sur une créature, pièces d'or (pour le seul joueur). Tous Pro Sound Effects (licence Roblox).
À compléter : forge, cuisine, portes, animaux, interface, musique.

## Étapes 7 / 18 — journal de découvertes et carte [M] (`Systemes/Journal`, client `Carte`)

Chaque région parcourue est notée par monde (`prof.journal[monde]`, chaîne compacte) ; un lieu
découvert la première fois = toast « 📍 Découverte », son, +10 XP. Carte [M] / bouton 🗺️ : seules
les régions parcourues sont dessinées (biome + icône du lieu), flèche d'orientation, se complète en
direct. Rien n'est révélé d'avance. Reste : repères posés par le joueur, boussole, cartes au trésor.

## Étape 25 — performance (mesure du 17/11, Studio, 1 joueur, monde de test)

Boucle serveur : chaque système est chronométré (moyenne glissante, `/wa perf`) et isolé par
`pcall` (une erreur dans un système ne bloque plus toute la boucle ; un seul avertissement).
Mesure : 60 images/s stables, 1,3 ms de calcul serveur par image (budget : < 8 ms), ~16 000
pièces dans le Workspace autour d'un joueur. Faune et météo sont 100 % client (0 coût serveur).
Non mesuré : serveur plein (45 joueurs), téléphone d'entrée de gamme → à faire avant publication.

## Étape 15B — avant-postes (`Systemes/Avantpostes`)

Bannière de clan (fabriquée) plantée hors villages (220), arrivée (300), routes, eau, autre
avant-poste (150). Réapparition des membres sans lit. Vivres déposés par les membres ; le N-ième
avant-poste du clan en mange N par jour ; sans vivres −3 solidité/jour → il tombe. Abattable par
tout autre joueur (invite [R] maintenue, 12 coups), membres prévenus. Testé : refus près de
l'arrivée, plantation, réapparition, consommation sur 12 jours.

## Étape 10A — routines des PNJ (ajouts)

Les villageois s'abritent chez eux sous l'orage (shérif et marchand restent à leur poste), vont
déjeuner à la taverne de 12 h à 13 h, et un PNJ coincé 10 s loin de son but « trouve un passage »
(replacé sur son but) : plus de PNJ bloqué à vie contre une construction de joueur.

## Étape 11B — permissions de propriété

Niveaux par propriétaire et par monde (`rec.trust`) : propriétaire > clan (bâtir ensemble, déjà là)
> « batir » (construire sur ses parcelles + coffres/portes) > « coffres » (ouvrir portes et coffres
sans crime) > visiteur. Commandes : `/autoriser <pseudo> [coffres|batir]`, `/retirer <pseudo>`,
`/autorises`. Chaque ouverture/prise autorisée est notée au journal du propriétaire (historique).
Reste : location à durée, transfert de propriété, sort des biens d'un inactif.

## Étape 14 — protections entre joueurs

Combat entre joueurs = crime (déjà). Ajouts : zone sûre de 60 studs autour de l'arrivée (aucun
coup), et anti-acharnement : celui qui t'a mis K.O. ne peut plus te frapper pendant 10 minutes.
Déjà présents : bouclier d'arrivée 20 s, absents protégés, maison jamais vidée.

## Étape 26 — banc de régression

`tools/bancs/regression_play.luau` (Play, contexte serveur) : 13 vérifications (quantités
hostiles, sauvegarde, banque, courrier idempotent, bonus, météo, blocage, avant-poste, invitations)
— **13/13 OK** le 17/11. À relancer après chaque mise à jour importante, avec
`save_concurrence.luau` (Edit) et `generation.luau` (Edit).

## Divers (8A, 8C, 9B, 20)

- Arbres fruitiers : le cerisier (sauvage ou replanté) se cueille sans être abattu (pommes /
  poires en prairie, prunes / poires en forêt), regarni en 3 jours ; compte pour les concours.
- Conservation : **pas de pourriture** (décidé) → séchage/fumage restent des recettes de cuisine
  (fruits séchés, viande séchée) sans mécanique d'avarie (ce serait de la corvée).
- Boss / gardiens : gardien de grotte une fois par jour et par grotte (identifiant daté), coffre
  tous les 3 jours, boss itinérants rares → récompense bornée par le temps de trajet. OK.
- Mobile : l'interface principale a une mise à l'échelle globale (0,62 à 1,25) ; les nouveaux
  panneaux (Conseil, Tableau, Carte, Paramètres) ont leur propre ajustement à l'écran.

## Étape 17 — invasion sans défenseur

Si au moins 3 assaillants sont encore debout au bout des 5 minutes, ils saccagent une maison du
village (`Demolir.ravage`) : ruine 4 jours, ou réparée tout de suite par le projet du maire.
Non testé en temps réel (5 min d'attente) : relu et compilé seulement.

## À faire par le joueur (rien ne peut le faire à sa place)

1. **Ctrl+S dans Studio** : les nouveaux modèles (Auberge, Écurie, Tour_Guet, Palissade) et
   tous les scripts poussés n'existent que dans la session Studio tant que la place n'est pas
   sauvegardée (le MCP ne sauvegarde pas).
2. Regarder en jeu le rendu des nouveaux bâtiments, de la météo, de la faune et de la carte
   (la capture d'écran MCP renvoie une image noire en ce moment : je n'ai pas pu les voir).
3. Publication (étape 27) : test en ligne avec 2 comptes, sons à confirmer (voir étape 17).

## Étape 1A / 11A — secteurs trop gros (constructions illimitées)

Risque : un secteur (4×4 régions) dépassant 4 Mo n'était plus écrit du tout (toutes ses
constructions perdues au redémarrage). Désormais, au-delà de 3,2 Mo il est découpé en une clé par
région (`m_<monde>_r_<rx,rz>`) + un index `{ __split }` écrit en dernier. Banc avec DataStore
simulé : secteur de 4,8 Mo → 3 régions de 1,6 Mo + index, 72 000 pièces rechargées à l'identique.
Limite restante : une SEULE région de plus de 3,9 Mo (≈ 58 000 pièces) n'est pas écrite (alerte).

## Points cochés sans code nouveau (justification)

- Emotes : celles de Roblox (/e) restent actives. Visites : `/autoriser`. Communication : chat
  Roblox filtré, courrier sans texte libre (rien à modérer), annonces admin filtrées.
- Noms de clans : déjà filtrés (TextService). Infos personnelles : seuls pseudo et titre s'affichent.
- Monétisation : **aucune** (décision), donc ni pari, ni avantage payant, ni objet aléatoire payant.
- Talents : « Oublier les talents » existe (25 or × niveau).
- Courrier : 5 or de port, boîte plafonnée à 400 colis pour les envois joueurs (anti-spam), colis
  système jamais refusés, pas de texte. Commerce entre mondes = courrier (or et objets voyagent).
- Recettes : 9 de départ, le reste se découvre (essai, recette, plan, livre), sauvegardées (`known`) ;
  fabrication multiple et coûts affichés dans l'atelier.
- Ressources : monde fini (arbres, rochers, filons ne repoussent pas), buissons et fruitiers se
  regarnissent, reboisement par graines (testé le 17/11 au matin).

## Étape 18 — cartes au trésor (testé en Play le 18/11)

Lire une carte (trouvée, ou 4 fragments à l'atelier) tire une cache réelle sur la terre ferme, à
plus de 300 studs de l'arrivée ; indice (direction, distance vague ou exacte avec une boussole,
biome) + croix ❌ sur la carte [M]. Trois coups de pelle sur place : 3 trésors + 80-200 or + XP.
Une cache à la fois par monde (relire la carte redonne l'indice). Testé : cache au désert,
3 coups, +131 or, carte consommée, croix affichée.

## Étape 16B — îlots (`Systemes/Ilots`, testé le 18/11)

Cinq îlots par monde (graine propre « ilots », positions vérifiées en pleine mer, 11 à 13 régions du
centre), posés au chargement de leur région (terrain sable + herbe, rochers, saule), chacun avec
une épave à fouiller (2 trésors + 30-80 or, 30 % fragment de carte, 8 % carte au trésor ; une fois
tous les 7 jours) ; un îlot porte un phare allumé la nuit. Testé : 5/5 en mer, phare, fouille
unique. Sons : porte et fabrication (établi/forge) ajoutés aussi.

## Étape 3D — terrain modifiable (testé en Play le 18/11)
- Déjà en place, coché : limites (terrassement seulement sur ses terres / celles du clan, `Terraforme.allowed`),
  sauvegarde par secteur (`reg.state.terra`, réappliqué au chargement), reboisement (graines d'arbre → pousse
  3 jours → arbre, `Props.plant`).
- Nouveau : `Terraforme.restore(pos, rayon)` + commande `/wa terrain [rayon≤12]` (inscrite au registre) :
  remet le relief d'origine et vide les étangs.
- Nouveau : filet anti-chute sous le relief (`Game.sinkStep`, 1 contrôle/s) : un joueur > 12 studs sous
  le sol deux contrôles d'affilée (hors grotte de donjon et eau) est remonté à la surface, sans dégâts.
- Banc de régression : 15/15 (ajout « remonté sous le sol », « terrain restauré »).
- Reste [~] : vérifier trous/collisions après streaming sur un vrai client mobile.

## Étape 4B — transferts en masse (testé en Play le 18/11)
- Coffres posés et banque : boutons « 📥 Compléter les piles » (range tout objet du sac déjà présent dans
  le coffre) et « 📤 Tout prendre » (seulement son coffre / un coffre autorisé — pas de vol en masse).
  `Shop.chestBulk` + action `chest_bulk` ; une seule synchro/sauvegarde pour tout le lot.
- Coffre de clan exclu volontairement (chaque mouvement = écriture DataStore partagée).
- Test : 29 bois rangés, 12 pierres laissées (absentes du coffre), « tout prendre » → 30 bois.
- Ateliers/étals : le clic sur une case déplace déjà tout le tas (existant).

## Étape 5 — recettes (banc `tools/bancs/recettes.luau`, Play le 18/11)
- Message de manque complet : « Il manque : 2 🪵 Bois, 1 ⛓️ Lingot de fer » (`Shop.missing`), au lieu du
  seul premier ingrédient sans quantité.
- Banc : pose établi + four, puis pour CHAQUE recette d'objet : juste suffisant → fabriqué, ingrédients
  consommés exactement ; un ingrédient en moins → rien fabriqué, rien consommé, message présent ;
  compétence trop basse → refus. Résultat : 389 OK · 52 refus OK · 74 équipements hors banc · 0 échec.
- « Inventaire plein » : sans objet (sac sans plafond, décision étape 4B).

## Étape 8B — reproduction des bêtes de ferme (testé en Play le 18/11)
- Chaque matin, deux bêtes de même espèce, au même éleveur, même région, NOURRIES LA VEILLE forment un
  couple : 35 % de chances d'un petit à côté d'un parent (même enclos). Bêtes sauvages / des PNJ : non.
- Plafond `Animals.OWN_CAP` = 24 bêtes par éleveur et par monde : bloque l'achat (avant de payer) et les
  naissances. Test : 2 poules nourries → naissances ; au-dessus du plafond → 0 naissance, achat refusé.
- 5 (annulation/déconnexion pendant fabrication) : sans objet, la fabrication est instantanée côté serveur.

## Étape 6A — XP farmable sans coût (testé en Play le 18/11)
- Audit des 40 sources d'XP de compétence. Boucles gratuites trouvées et corrigées :
  · creuser/remblayer la même case (terre rendue) → XP agriculture plafonnée à 25/jour ;
  · poser/reprendre une pièce (rendue entière) → XP artisanat de pose plafonnée à 150/jour ;
  · échange vide entre deux joueurs (+6 commerce chacun) → XP seulement si un objet change de main, 5/jour.
- Outil commun `Joueurs.addSkillXpCapped(joueur, compétence, n, source, plafond)` (compteur par jour du monde).
- Recettes réversibles (A→B→A) : recherche sur les 515 recettes → aucun cycle.
- Le reste coûte du temps ou des ressources finies (monde fini) : pêche, abattage, minage, dressage,
  crochetage (mini-jeu), craft (ingrédients consommés), achat/vente (anti-arbitrage 80 %).

## Étape 8B — bêtes bloquées et don (18/11)
- Bug corrigé : meneur déconnecté / mort → la bête, loin de son enclos, ne faisait plus un pas
  (`inPen` refusait tout). Elle s'installe désormais là où on l'a perdue. Testé : elle flâne de nouveau.
- Seul le meneur peut relâcher la bête qu'il mène (avant : n'importe qui pressait [R]).
- Rappel des bêtes égarées : clochette (existant, 120 studs).
- Don : mener SA bête et la laisser [R] sur la parcelle d'un autre joueur la lui donne (registre
  `don_bete`, plafond de ferme du receveur respecté). [~] à tester à deux joueurs en ligne.

## Étape 7A — champs immenses (banc `Farm.stress`, Studio seulement, 18/11)
- Avant : chaque nouveau jour (et chaque averse via `refreshAll`) détruisait et reconstruisait TOUTES
  les cases d'un bloc (~1,7 ms par case → un champ de 3000 cases = gel de ~5 s du serveur).
- Maintenant : seules les cases dont l'apparence change (culture, stade, arrosée, flétrie) sont
  redessinées, par tranches de 6 ms de calcul par frame (`task.defer`, un seul passage à la fois).
- Mesure, 2997 cases de blé : newDay synchrone 0 ms, redessin étalé sur 6,2 s, 32 967 instances.
  La pire frame (194 ms) en Play Studio inclut le rendu CLIENT (même processus) de 33 k pièces neuves.
- [~] Reste : mesurer sur un vrai serveur en ligne (micro-profiler) ; envisager un modèle de culture
  plus léger (11 instances/case en moyenne) si la mémoire client devient le goulot.

## Étape 8C — appâts de pêche (testé en Play le 18/11)
- L'objet « Appâts » (fabriqué avec des restes pourris, butin de cerf) ne servait à rien. Désormais un
  appât est consommé à chaque lancer s'il y en a dans le sac : touche 35 % plus rapide, poissons rares
  (poids ≤ 15) ×1,5. Infobulle ajoutée. Test : 3→2 appâts, touche à 4,4 s.
- [x] Nasses / casiers posés dans l'eau (production passive quotidienne) : FAITS (`Systemes/Nasses`, étape 8C).
- 7A conservation des récoltes : décision — pas de pourriture (cohérent avec « pas de faim, pas
  d'usure ») ; le stockage passe par coffres / banque / grenier.
- Nasses (`Systemes/Nasses`, testé le 18/11) : objet « Nasse » (fibre 10, corde 2, bois 2, établi,
  pêche 2). Posée dans l'eau devant soi ; chaque matin +1 poisson (+2 si appâtée), 3 au plus en
  attente ; « Relever » (vol si ce n'est pas la sienne), « Reprendre » [R]. 6 par joueur et par monde,
  8 studs d'écart mini. État dans `world.extra.nasses`. Test : posée, appâtée, +2 poissons, reprise.

## Étape 9 — cochés sans code nouveau (vérifié dans Enemies.lua le 18/11)
- Créatures de nuit : épouvantails / ombres se dissipent à l'aube (`Enemies.nightStep`, bouffée de
  paille ou de fumée), 3 au plus autour d'un joueur, jamais dans villages / parcelles éclairées.
- Réapparition : bêtes et monstres tués reviennent à leur point d'origine après `RESPAWN_DAYS` = 3
  jours (boss exclus). Zones de retour = `en.home`.
- Poursuite : laisse `LEASH` = 70 studs, puis retour au foyer (régénération) — pas de traque infinie.

## Étape 9A — nids (`Systemes/Nids`, testé en Play le 18/11)
- 60 % des régions sauvages (sans village / lieu notable) ont un nid au sol, sur terrain plat et sec.
  Couleurs par biome. « Dénicher » : 1–3 plumes, 50 % un œuf, XP élevage ; regarni après 4 jours
  (état `reg.state.nids`, sauvegardé avec le secteur). Couche à graine propre (mondes existants intacts).
- Test : 2 nids chargés (prairie, forêt), +3 plumes +1 œuf, 2e fouille refusée, regarni à J+4.
- [~] Empreintes : FAITES (18/11, `Traces.client` : bêtes et créatures sur neige, sable, boue, terre, feuilles) ; écureuils qui grimpent aux arbres FAITS ; restent terriers et cris des bêtes.

## Fiche de référence générée (sans Play, 18/11)
- `tools/bancs/reference.luau` (mode Edit) → `docs/REFERENCE.md` : 645 objets (type, rareté, valeur, obtention,
  usages), trouvailles par source et biome, 23 cultures, poissons, bêtes, dressage, 83 créatures (où, horaire,
  comportement, butin, or), sources d'XP des 11 compétences, entrées (14) / sorties (19) d'or avec la ligne de code.
  Lancement : `loadstring(HttpService:GetAsync("http://127.0.0.1:34873/banc?f=reference"))()` (sync.py : `/banc`, `/doc`).
- 4A rareté : `Catalogue.assignRarity` (prix + meilleure chance de trouvaille pour ce qui ne se fabrique ni ne s'achète),
  stockée dans `ITEMS[id].rarity`, utilisée par l'infobulle (couleur) et la confirmation de destruction.
  472 communs · 46 peu communs · 83 rares · 35 épiques · 9 légendaires. Pièce de cuivre « valeur » n'est plus bleue.
- Objets introuvables corrigés : pièce d'argent (fouille, événements, trésors), pièce d'or (fouille 0,3 %, trésors),
  lettre de change et journal d'un voyageur (événements). Restent sans source, volontairement : pièces toutes faites
  `wall*`/`floor2`/`stairs` (retirées de l'atelier par la construction libre, gardées pour les vieilles sauvegardes).
- 4B objets liés : **aucun**, décision : tout s'échange (économie entre joueurs) ; l'équipement porté une fois retiré.
- [~] 5 / 8A / 9B / 7 : la fiche liste les données ; restent à écrire paliers de compétence, besoin en eau / rendement
  des cultures, fréquences d'apparition des créatures d'origine (posées par `RegionPlan`).
- 24 : `CHANGELOG.md` (une version par jour de travail, depuis git).

## Butin au sol (demande du 18/11, `Systemes/Butin` + `Butin.client`, banc Edit `tools/bancs/butin.luau` 16/16)
- Tombe au sol au lieu d'aller dans le sac : abattage, souches, fruits, baies, buissons arrachés, roches/filons,
  coffres ouverts (façon Fortnite), terre creusée, filons de donjon, tout le butin des créatures (or, objets,
  équipement, butin rendu par un cambrioleur), et les trouvailles qui vont avec.
- Restent directs dans le sac : pêche, récolte des cultures (champs immenses = trop d'objets), nids, nasses,
  fabrication, achats, courrier, échanges, coffres/banque, événements.
- Ramasser : clic gauche / toucher l'objet (14 studs), invite [E] « Ramasser » (8 studs), [Q] / manette Y = tout
  dans 10 studs. Aide clavier : [Q] ajouté.
- Règles : réservé 30 s au joueur et à son groupe, puis public (le prendre n'est pas un vol : c'est par terre) ;
  disparaît après 5 min ; au-delà de 400 objets par serveur les plus vieux partent ; mêmes objets du même joueur
  au même endroit = une seule pile « ×n » ; propriétaire déconnecté → public. Non sauvegardé (temporaire).
- Technique : `Util.auSol(joueur, pos, ignorer, fn)` → `Butin.capture` ; pendant fn, `Joueurs.add/addGear` de ce
  joueur posent l'objet au sol (rayon vers le bas, hors personnages/source). Système en erreur → tout va au sac.
  Cube coloré par rareté (néon dès « rare », lumière dès « épique »), icône emoji + « ×n », animation locale.
- [~] À tester en Play (PC fixe) : ressenti, chute sur pentes/eau/grottes, ramassage mobile, perf avec 400 objets.

## HUD façon image cible (18/11, `StarterPlayerScripts/Hud` + Interface ; aperçu Edit `tools/bancs/hud_apercu.luau`)
- Haut-gauche : portrait rond (vignette Roblox), nom, écusson d'honneur 😇/😈, barres Vie / Endurance chiffrées,
  or, étoiles de recherche. Haut-centre : boussole qui suit la caméra + nom du lieu (village, ferme, ruines,
  antre, « Chez toi », sinon biome). Haut-droite : « Jour N - hh:mm » + météo (soleil / nuit / pluie / neige…)
  et minicarte ronde (biomes + eau calculés par WorldGen autour du joueur, lieux en icônes, flèche = regard).
- Gauche (PC) : colonne Inventaire, Personnage, Compétences, Quêtes, Carte, Clan, Atelier, Paramètres.
  Carte et Paramètres ouverts par `OuvrirCarte` / `OuvrirParametres` (BindableEvent sur le joueur).
- Bas-droite : les gains (« +3 🪵 Bois », équipement trouvé) deviennent des cartes de notification.
- Barre rapide : 9 cases séparées de 64 px, numéro en haut à gauche, case active dorée.
- Pas fait : chat à onglets Monde/Groupe/Clan/Commerce (chat Roblox gardé), vraies icônes peintes (emoji pour
  l'instant). [~] À voir en Play : rendu réel, mobile (colonne masquée, petits boutons Carte/⚙️ sous la minicarte).

## Plus de niveau : caractéristiques par la pratique (18/11, banc Edit `tools/bancs/stats.luau` 13/13)
- Retirés : niveau, XP générale, points à placer, barre d'XP, « X passe niveau N », leaderstat Niveau.
- Chaque caractéristique a sa pratique (`statXp`) ; rang = racine(xp/100), sans plafond. L'XP de compétence la
  nourrit (`Config.STAT_FROM_SKILL` : bûcheronnage → Force, combat → Force + Défense, crochetage → Discrétion,
  commerce → Charisme, pêche → Chance, cuisine → Vie…) ; courir / nager → Vitesse (1 xp / 40 studs, pas à cheval).
- Talents : 1 point par 15 rangs de compétence cumulés (« Maîtrise », aussi en leaderstat). Oubli : 25 or × points.
- Anciens points placés convertis en pratique équivalente au chargement. Titre « Vétéran » = 40 rangs de stats.
- Les créatures gardent un niveau (danger, butin) ; le cadre de cible affiche 🧍 pour un joueur.

## Îles différentes tirées au hasard (18/11, générateur v2 — les mondes déjà créés restent en v1)
- `WG.THEMES` : 7 thèmes tirés de la graine : Terres tempérées, Île des Glaces, Archipel des Sables, Île des
  Brumes, Forêt rousse, Terres sauvages, Île aux Vergers. Chacun : climat décalé, biomes permis (un biome absent
  est remplacé par le plus proche, `WG.FALLBACK`), noms de villages propres, danger ajouté au monde.
- Faune propre à chaque île (`Bestiaire.islandPool`) : ~30 % des espèces d'un biome absentes, au moins 2 restent,
  plus une espèce « signature » 3 fois plus fréquente. Deux îles du même thème n'ont pas la même faune.
- Liste des mondes : icône + nom du thème sous le nom de l'île.
- Banc `generation.luau` (désormais `f({graines}, gen)`), une graine par thème : 0 lieu inondé, 0 maison
  chevauchante / dans l'eau / sur un arbre, 1 seule ruine de départ ; ex. Glaces 312/560 régions de toundra,
  Sables 317 de désert, Brumes 307 de marais, Vergers prairie + désert seulement.
- [~] Quêtes propres à chaque île : FAITES (b8a63ff, au tableau / auprès des habitants depuis le 18/11) ; PNJ aux tenues par île : FAITS (c80169e) ; reste : taille d'île variable.

## Quêtes facultatives (18/11, `Systemes/Quetes` + `Quetes.client` [J], banc Edit `tools/bancs/quetes.luau` 15/15)
- Tirées de `liste quetes.txt` (ce qui marche avec les systèmes existants) : apporter (boulanger, forgeron,
  charpentier, tissus, repas, garde, vieille maison, fête, vétérinaire, légumes du biome), chasser (faune PROPRE
  à l'île ; « La terreur de l'île » = son espèce signature), abattre, miner, pêcher, récolter (cultures du biome
  du village), fabriquer, lettre à porter dans un autre village, découvrir des lieux.
- Chaque village propose 3 quêtes, renouvelées tous les 2 jours, identiques pour tous (graine + village +
  période) et différentes d'une île à l'autre. Rien d'obligatoire : prendre / lâcher librement, sans conséquence.
- Récompense : or (selon le danger du monde), XP de la compétence liée (donc caractéristiques), parfois un objet,
  +1 honneur. Rendu au village qui l'a donnée (ou au destinataire de la lettre). Journal Économie « quete ».
- Progression branchée : Enemies (tuer), Props (abattre, miner), Fishing, Farm (récolte légitime seulement),
  Shop (fabriquer, en objets), Journal (nouveau lieu). État dans le monde : `players[uid].quetes`.
- Journal [J] (bouton « Quêtes » du HUD, 📜 sur mobile) : quêtes du village proche + les siennes avec progression.
  L'invitation au clan passe de [J] à [N].
- Pas retenu pour l'instant (demandent des systèmes absents) : escortes, énigmes, concours de dressage, quêtes à
  plusieurs joueurs, longues histoires. [~] À voir en Play.

## Monde libre + tourelles (18/11, `Config.LIBRE`, `Systemes/Tourelles`, banc Edit `tools/bancs/tourelles.luau` 15/15)
- Demande : « monde libre de toutes contraintes gamemaster » ; c'est aux joueurs de se protéger.
- `Config.LIBRE` regroupe les anciennes protections d'arbitre, coupées (rallumables une par une) :
  bâtir / poser / semer / bêcher chez autrui, terrasser partout, vider le coffre d'un autre d'un geste,
  arracher étal ou panneau de propriété ; plus de zone sûre à l'arrivée, de bouclier de 20 s, ni de
  grâce de 10 min après un K.O. Tout cela reste un CRIME (témoins, étoiles, primes) quand c'est le cas.
- Gardé exprès : pas de parcelle privée DANS un village (sinon un joueur + balistes tient tout le village).
- Tourelles (atelier ou boutique du village) : Arbalète de garde (portée 30, 45 dégâts / 3 s, 40 carreaux) et
  Baliste de rempart (portée 42, tue d'un coup / 5 s, 12 carreaux). Tirent sur qui est SUR les terres du
  propriétaire et n'est ni lui, ni son clan, ni son groupe, ni autorisé ; ligne de tir vérifiée (un mur
  protège) ; une munition par tir, vides = muettes ; fonctionnent propriétaire déconnecté ; font fuir les
  cambrioleurs PNJ ; ne se ramassent pas chez un autre : il faut les casser (14 / 24 coups).
- Parade : les vider (attirer les tirs), passer à couvert, les casser, ou venir à plusieurs.

## Tenues des habitants par île (18/11)
- 17 couleurs de chemise et 4 de pantalon AJOUTÉES après celles d'origine ; chaque thème a sa palette et ses
  chapeaux (Glaces : blanc / bleu nuit / fourrure + bonnets ; Sables : sable / ocre / turquoise + bandeaux ;
  Brumes : mousse / vase + capuches ; Forêt rousse : rouille / brique + tricornes ; Vergers : pastels + paille).
- Mondes en gen 1 : mêmes tirages dans le même ordre → mêmes PNJ (banc `tools/bancs/pnj_looks.luau` :
  empreinte 1060902891 avant ET après sur la graine 4242). Les joueurs ont aussi plus de couleurs au miroir.

## Village façon image cible (18/11, ConstruireModeles, vérifié par captures Studio)
- Maisons A et B, taverne, auberge : étage en encorbellement (solives qui dépassent, pans de bois sur l'étage,
  2 fenêtres en façade) ; toutes les maisons : jardinières fleuries sous les fenêtres.
- Fenêtres marquées `Fenetre` : vitre sombre le jour, chaude et lumineuse le soir (Clock.setWindow, 18 h 30–6 h 30).
- Grand moulin de village (`Moulin_Village`, 72 pièces) : tour chaulée, toit de bardeaux, 4 ailes à claire-voie
  qui tournent chez chaque joueur (Ambiance, sans réseau). Ajouté en DERNIER à la liste des bâtiments : les villages
  déjà vus ne bougent pas ; il évite ce que les joueurs ont construit.
- Anciens modèles gardés dans `ServerStorage.Modeles_avant_18nov` (retour arrière possible ; aucune retouche
  manuelle perdue : toutes les pièces d'avant existent encore).
- Rebâtir : `require(OutilsDev.ConstruireModeles).maisons()` / `.villages2()` / `.moulin()` (mode Edit).

## Gens de métier, enfants, colporteur (18/11, `Systemes/Metiers`, testé en Play sur la graine 7)
- Demande : « PNJ et métiers » de `listes ennemi.txt` (boulanger, cuisinier, médecin, prêtre, enfants, voyageurs…).
- Couche serveur à graine propre (`WG.hash(seed, "metiers", rx, rz, rôle, génération)`) : RegionPlan n'est pas
  touché, les habitants existants gardent leurs ids. Les nouveaux PNJ passent par `Npcs.addExtra` (même moteur :
  routine, vue, témoins, fuite, K.O., avis par joueur) ; ids `m:<région>:<rôle>:<génération>`.
- Chaque artisan travaille dans « son » bâtiment de village (absent → pas d'artisan) et dort chez un habitant
  (second occupant). Ils tiennent leur comptoir sous l'orage et ne vont pas déjeuner.
- Économie : stock réel dans `G.world.extra.metiers[région].roles[rôle]` ; la valeur catalogue des matières
  vendues (points) + une petite base devient la fournée du lendemain (tour à tour, du moins cher au plus cher,
  25 max par article). Rien n'est créé : la base est perdue si inutilisée, le reste est reporté. Vérifié :
  10 blé vendus 120 or → le lendemain pain complet + pain de campagne en plus du pain et des galettes.
- Anti-arbitrage élargi (`Shop.npcSold`) : seuls les objets qu'un PNJ VEND sont plafonnés au plus bas prix
  possible ; les ressources brutes gardent l'ancien plafond (sinon −15 % sur toute la revente).
- Enfants : exclus des cibles de combat, `Npcs.hit` sans effet (règles Roblox), personas non courageux ;
  secret = grotte d'une région voisine au plan déjà calculé (`Donjons.siteNear`, rien n'est généré pour ça).
- Tests Play : dialogues et libellés (« Boulanger · Jovial »), étal + vente refusée hors spécialité, réparation
  (−13 or), soin (vie pleine, ralenti levé), prêtre (confession 50 or → +10 honneur puis refus le jour même,
  bénédiction, aumône), chat perdu (« Trop lent ! ») et gagné puis secret, colporteur forcé (`Metiers.forcePeddler`),
  `Clock.newDay` sans erreur, capture : tenues lisibles, enfant à 0,62.
- [~] Pas encore vu : le remplacement d'un artisan tué (3 jours), à plusieurs joueurs, sur mobile.
- Remarque hors sujet : plusieurs villages de la même île portent le même nom (graine 7 : 7 « Clos-Doré ») —
  générateur de noms à revoir (sans changer la consommation de rng de RegionPlan).
- Restent de la liste : nobles / seigneurs (châteaux), artisans dédiés (charpentier, tisserand), éleveur distinct
  du fermier.
