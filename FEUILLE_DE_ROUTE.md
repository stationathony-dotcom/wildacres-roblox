# Wild Acres — feuille de route (checklist)

Règle d'or : tout ce que le joueur veut faire est possible, plus ou moins dur. Le serveur décide de tout.
Idées : nos échanges + `Desktop\idee.txt` (autre IA). On coche au fil des commits.

## Principe : bac à sable géant, sans indication

On fait ce qu'on veut, sans tutoriel, sans quête imposée, sans annonce à tout le serveur, sans système
encadré (pas de guerre « déclarée ») : les joueurs font tout organiquement. Les événements se découvrent
sur place (cris au village, sol qui tremble, lueur dans le ciel).

## Principe : pas de plafond arbitraire

On est limité par ses ressources, pas par des chiffres : armée sans effectif max (la solde limite),
compagnons sans max (il faut les nourrir), parcelles illimitées (chaque terrain coûte plus cher),
banque agrandissable sans fin, champs sans limite.

## Phase 1 — Un monde qui tourne (priorité absolue)

- [x] Monde généré, 5 biomes, île finie, lieux, PNJ, ferme, pêche, chevaux
- [x] Multi : accueil, mondes réservés, sauvegardes, perso global, verrou de session
- [x] Artisanat à paliers, four, construction sur grille, coffres, parcelles
- [x] Créatures (21), gibier, butin, niveaux, équipement fabriqué
- [x] Compétences (10, grind), talents (19), mini-jeux serveur, compagnons
- [x] Serrures, crochetage, alarme, cambriolages, journal, étoiles et primes persistantes
- [x] Anti-abus : maison jamais vidée, absents protégés, bouclier d'arrivée, anti-farm d'XP
- [x] Butin au sol façon Minecraft / Fortnite (récolte, minage, fouille, créatures, coffres) : clic, [E], [Q] tout autour ; réservé 30 s, disparaît en 5 min — banc Edit 16/16, testé en Play le 18/11 (posé sur le sol, [Q] ramasse tout)
- [x] HUD façon image cible (portrait, boussole, lieu, météo, minicarte, menu, notifications) — vu en Play le 18/11 (captures : tout en place) ; reste à voir sur mobile ; monde : lumière, châteaux, potences (banc `chateaux` OK)
- [x] Plus de niveau ni de barre d'XP : les caractéristiques montent en pratiquant (banc 13/13)
- [x] Îles différentes générées au hasard : 7 thèmes (biomes, villages, faune signature, danger) — générateur v2
- [x] Quêtes facultatives par village, propres à chaque île (9 sortes, journal [J]) — banc 15/15, à voir en Play
- [x] PNJ aux tenues et chapeaux propres à chaque île (gen 1 inchangée : banc `pnj_looks`)
- [x] Quêtes facultatives (choisies dans `liste quetes.txt`), jamais obligatoires — au tableau des quêtes ou auprès des habitants, transfert si le village est déserté (18/11)
- [x] Monde libre : plus de règle d'arbitre (bâtir chez les autres, PvP partout…) — `Config.LIBRE`
- [x] Tourelles de défense (arbalète, baliste qui tue d'un coup) avec munitions — banc 15/15
- [ ] **TEST en Studio puis en ligne** (check-list du README) — à faire par le joueur
- [x] Journal des transactions côté serveur (or, échanges, ventes) + alerte gain d'or anormal

## Phase 2 — Une vraie économie

- [x] Échange direct entre deux joueurs (double confirmation, validé serveur, invite [Y])
- [x] Commandes des villages (besoins par biome, renouvelées tous les 2 jours, or + honneur)
- [x] Banque de village (coffre sûr, 4 tailles, 2 or par dépôt)
- [x] Étal de joueur (prix libres, vente même absent, caisse, taxe 5 %)
- [x] Hôtel des ventes par monde (prix libre, 2 % de frais, paiement et invendus par courrier)
- [x] Compétence Commerce (ventes, commandes, étal)

## Phase 2 bis — Univers de mondes (idée « système C » de l'autre IA)

- [x] Port de départ sur chaque île + carte maritime des mondes connus (joueurs, biomes, danger, découvreur)
- [x] « Explorer l'inconnu » : crée un nouveau monde (nouvelle graine, nom procédural), le découvreur est retenu et annoncé
- [x] Danger propre à chaque monde (1 à 5 : monstres +25 %/niveau, plus d'équipement)
- [x] Version du générateur notée dans le registre (un monde découvert garde sa graine pour toujours)
- [x] Voyage en groupe (même destination choisie au port dans les 6 s = même bateau)

## Phase 3 — Une société

- [x] Groupes (5, invite [U], surbrillance + distance, +10 % XP ensemble)
- [x] Clans : nom + tag filtrés, 6 grades, coffre commun atomique (UpdateAsync), journal, invite [J], panneau [L], tag dans la liste des joueurs
- [x] Auberge : les lits des joueurs se louent 15 or la nuit (payé par courrier), point de réapparition du locataire
- [x] Courrier entre joueurs (objets / or, même hors ligne ou autre monde, 5 or de port, sans texte libre)
- [x] Titres et collections (poissons, créatures, cultures, minerais, bêtes, mondes) + titre dans la liste des joueurs

## Phase 4 — Un monde vivant

- [x] Événements de monde v1 : foire (+30 %), invasion nocturne d'un village (défenseurs payés), pluie de cristaux, convoi attaqué (sauver = payé, piller = vol), crue (prés noyés, champs arrosés, limon)
- [x] Boss itinérants originaux : Gardien des Moissons, Roi Mycélien, Colosse de Verre, Dormeur des Glaces (trophées → 4 pièces légendaires)
- [x] Grottes et donjons : entrées cachées (22 % des régions, au pied des falaises), galeries creusées sous la région, monstres du biome, gardien unique au fond, filons, coffre qui se remplit tous les 3 jours
- [x] Faune qui vit v1 : prédateurs qui chassent le gibier, troupeaux (cerfs, pingouins, flamants, chameaux) — [x] reproduction (deux bêtes nourries, gardées ensemble : un petit de temps en temps)
- [x] Navigation : barque FAITE (fabriquée, mise à l'eau devant soi, rameur + passager, s'échoue sur la rive, sauvegardée) ; îlots au large FAITS (5 par monde, épave à fouiller chaque semaine, un phare) ; quais FAITS (18/11, villages au bord de l'eau) ; voiliers FAITS (18/11)

## Phase 5 — MMORPG complet

- [x] Armée v1 : caserne sur sa parcelle, milicien / archer / garde, solde quotidienne, désertion, morts définitives
- [x] Territoires de clan v1 : les membres bâtissent sur les parcelles les uns des autres — [x] avant-postes contestables (bannière, vivres, déclin, abattable)
- [x] ~~Guerres de clans annoncées~~ RETIRÉES (volontairement absent) : tout doit être organique, les conflits naissent des joueurs avec les règles normales
- [x] Politique de village (maire élu par les habitants, trésor, taxe du marché, projets publics, registre)
- [x] Terrain modifiable sur ses terres (creuser, remblayer, étangs au seau) — [x] inventions : moulin (farine), arroseur (rempli au seau), ruche (miel, fleurs autour)
- [x] **Construction LIBRE** (aucune maison prédéfinie) : mode [V], 31 pièces (dalles, pans de mur, muret, poutre, poteau, pilier rond, pente, coin, rampe, barrière) en bois / pierre / brique / chaume / verre, posées n'importe où et à n'importe quelle hauteur, aperçu fantôme, [R] tourner, [Z] retourner, [X] reprendre ; on casse les murs des autres à la pioche (effraction)
- [x] Mobilier : table, chaise, tapis, pot de fleurs, étagère, banc ; sable (désert) → verre au four
- [x] Activités créées par les joueurs : tableau d'affichage (concours de pêche/récolte, rassemblements, cagnotte bloquée)

## Catalogue d'objets (`liste items.txt`) — tout est gardé, intégré par lots, chaque objet a un usage

- [x] Lot 1 construction : matériaux rondins, pierre taillée, torchis, pisé, fer ; formes grand mur, cloison, linteau, marche, grand poteau, colonne, pente raide, grille
- [x] Lot 2 toits (tuiles, ardoise, bardeaux) ; portes (grange, double, château), trappe, volet, fenêtres ronde/arquée, vitrail, meurtrière, herse, pont-levis, arches, échelles, socle
- [x] Lot 3 mobilier et déco : 88 objets posés à modèles générés par code (`Shared/Catalogue`, formes ARCH)
- [x] Lot 4 ressources, forge, tannerie, tissage, poterie, écriture + 52 pièces d'équipement (armes, boucliers, vêtements, armures, harnais, outils de métier)
- [x] Lot 5 cuisine, boissons, alchimie/herboristerie (potions et élixirs), 14 nouvelles cultures
- [x] Lot 6 élevage, transport, exploration, collection, social, progression (livres = XP), objets rares ; trouvailles en récoltant/pêchant/chassant/fouillant/événements
- [x] Testé en jeu : usages (livres, bourses, trésors, musique), trouvailles, pose des objets, artisanat

## Demandes du joueur en attente (à faire dans l'ordre)

- [x] **Monde 100 % médiéval** : maisons A/B/C, boutique, poste du shérif vérifiées (colombages, volets, cheminées, chaume/tuiles/ardoise/bardeaux) ; villages avec taverne, forge, chapelle, marché, puits, **auberge, écurie, tour de guet et palissade** (17/11) ; anciennes versions dans ServerStorage.Modeles_Avant_Medieval. À regarder en jeu par le joueur : rendu des nouveaux bâtiments (la capture d'écran MCP ne marche pas en ce moment)
- [x] **Sac façon World of Warcraft** [B] : toutes les ressources en grille de cases, onglets par catégorie, liseré de rareté (commun → légendaire), quantités, infobulle (type, effet, nombre de recettes où l'objet sert, prix), clic droit = utiliser, glisser vers la barre ; stats / compétences / équipement passés dans le panneau Personnage [P]. Pas de limite de cases (règle « pas de plafond arbitraire »)
- [x] **Arbre de talents façon WoW** [K] : 5 voies en colonnes, paliers reliés, rangs (0/3), verrous, infobulles, « Oublier les talents » (25 or × niveau)
- [x] **Barre d'action rapide façon Minecraft** : 9 cases, touches 1-9, outils mis en main, 2e appui = manger / utiliser / poser, glisser-déposer depuis le sac et entre cases, sauvegardée avec le perso (la molette reste au zoom caméra)
- [x] Bestiaire (`listes ennemi.txt`) : 52 créatures (bandits, bêtes, créatures par biome, morts-vivants de nuit, géants, 6 boss uniques avec pièces légendaires), camps de bandits avec butin, modèles générés par code
- [x] Grottes testées en jeu (entrée, galeries, monstres, sortie) ; corrigé au passage : chute à travers le sol après une téléportation (streaming), créatures de passage effacées en plein jour
- [x] Bestiaire, suite possible : PNJ et métiers (liste « catégories qui manquent ») FAITS 18/11 (`Systemes/Metiers`) : boulanger, cuisinier, forgeron, guérisseur, prêtre, palefrenier, enfants, colporteur — stock réel nourri par ce que les joueurs leur vendent — puis seigneur / dame et gardes dans chaque château (trophées, titres de noblesse) ; idée facultative restante : charpentier, tisserand dédiés ; faune passive (oiseaux, moineaux, papillons, lucioles : FAITS — écureuils FAITS 18/11), montures (ânes, mulets : FAITS 18/11), météo (orages, brouillard : FAITS, Ambiance/Meteo), tournois et courses (rassemblements libres au tableau + concours minage / bûcheronnage 18/11)
- [x] Icônes : les emojis récents (Unicode 13+, ex. bois, pierre, pièce d'or) s'affichaient en carrés vides dans Roblox → remplacés partout

## Demandes du joueur (session du 17/11, suite)

- [x] **Construction façon Minecraft** : chaque pièce (pan de mur, dalle, poutre… × matériau) est un objet fabriqué à l'atelier, rangé dans le sac / la barre rapide, posé depuis la main (fantôme, clic = poser, R / Z / X en icônes) ; sa propre pièce reprise revient entière ; la palette [V] a disparu ([V] prend la première pièce de la barre)
- [x] **Atelier = grille de craft 3×3** : on compose son mélange depuis son sac (quantités, pas de forme), le ou les résultats possibles apparaissent, on clique pour fabriquer ; 9 recettes de départ, les autres se découvrent (en essayant, ou avec Recette inconnue / Plan d'artisan / Livre de recettes) ; carnet des recettes connues (clic = remplir la grille)
- [x] **Fiche personnage façon WoW** [P] : poupée d'équipement (chapeau, armure, arme, breloque), équipement du sac en cases, barre d'XP, onglets en icônes (caractéristiques, compétences, collections, titres), infobulles
- [x] **Combat lisible** : plaques façon WoW au-dessus de chaque créature (niveau + nom, rouge hostile / jaune neutre / vert passif, barre de vie), « ❗ » + contour pendant la préparation d'une attaque
- [x] **Icônes plutôt que lettres** : barre de raccourcis, invites, construction, atelier, fiche, et maintenant boutique (grille marchand façon WoW, prix sous la case, clic = 1 / clic droit = 5), coffre et banque et coffre de clan (cases du sac, clic = tout / clic droit = 1), étal, courrier et hôtel des ventes (cases d'objets avec infobulles)
- [x] **Cible façon WoW** : clic sur un monstre / PNJ / joueur = cadre de cible (niveau, nom coloré, barre de vie chiffrée, contour doré) ; [F] frappe la cible en priorité et se tourne vers elle ; Échap = plus de cible
- [x] **Invites contextuelles** : les invites du jeu n'étaient PAS dessinées (style Custom sans rendu) → touche + icône au-dessus de la chose (💬 parler, 🪓 couper, ⛏️ miner, 📦 ouvrir, 🚪, 🛏️…), remplissage pendant le maintien, toucher sur mobile ; la ligne d'aide en lettres devient une rangée touche + icône
- [x] **Tout destructible** : hache / pioche sur une maison de village (36 coups ÷ palier d'outil → décombres + planches et pierre), le décor (puits, fontaine, lampadaire…), l'objet posé d'un autre joueur (détruit, il est prévenu + journal) ; crime « vandalisme » si un témoin voit (étoile, prime 35, honneur, avis) ; les villageois rebâtissent en 4 jours
- [x] **Shérif combattable** : au contact il se bat (il ne passe plus les menottes d'office) ; on va en cellule seulement s'il te met K.O. ; on peut le battre, le semer ou l'assommer (crime grave)
- [x] Corrigé : la salutation des PNJ plantait (avis par joueur lu comme l'ancien avis commun)
- [x] **Ponts à revoir** : le tablier manquait (planches orientées dans le mauvais sens) ; culées et bornes de pierre ajoutées
- [x] **Monde fini** : arbres, rochers, filons, cactus ne repoussent plus tout seuls (on nettoie une zone pour de bon) ; seuls les buissons à baies se regarnissent
- [x] **Reboiser** : abattre un arbre donne souvent sa graine (gland, pomme de pin, graine de bouleau, noyau de cerise, bouture de saule) ; on la plante devant soi (hors villages, pas collée à un arbre ou un rocher) ; pousse 3 jours puis vrai arbre (à couper à son tour)
- [x] Villages : taverne, forge, chapelle, marché ajoutés autour de la place (destructibles, portes fonctionnelles)

## Session du 19/11 (« à ne pas oublier.txt », listes .txt) — fait, testé en bancs Edit, PAS encore en Play

- [x] Herbe haute fauchable (prairie, roseaux, oyats) — `HerbeHaute`, `Fauche`
- [x] Réputation par village (prix, refus de commerce, palier affiché, /reputation) — `Reputation`
- [x] Succès à compteurs (16) + rangs de maîtrise et 11 titres de grand maître — `Social.bump`
- [x] Chroniques des îles : 6 récits en 24 pages anciennes à retrouver (/chroniques) — `Chroniques`
- [x] Écurie multi-montures, allure héritable, poulinage (mulet stérile), /ecurie — `Horses`
- [x] Commerce entre régions : 3 produits recherchés par village (+50 %) — `Shop.wanted`
- [x] Tir à l'arc et arbalète à distance, flèches — `Combat.shoot`
- [x] Ouvriers agricoles à louer (arrosage quotidien) — `Ouvriers`
- [x] Courses entre villages au tableau d'affichage — `Activites` (« course »)
- [x] Livres : bestiaire (/bestiaire) et mes bêtes (/animaux) — `Livres`, `Livre.client`
- [x] 10 formes de construction (escaliers, colimaçon, dôme, toit conique, murs percés, pignon, créneaux, chapiteau)
- [x] Pont-levis et trappe fonctionnels (serrure possible), roue à eau qui alimente le moulin — `Machines`
- [x] Créatures : assassin, roi déchu, méduse des marais, esprit de l'orage ; événements orage et colosse
- [x] Diligence entre villages découverts (palefrenier)
- [x] Plafond de 24 bêtes remplacé par la place des abris construits
- [x] Gestes de loisir : /danse /salut /applaudir /reverence
- [x] Correctifs de la nuit intégrés (sommeil, sauvegarde, relations PNJ, courrier, chasse au trésor)
- [x] Sélection des semences (/cultures), lignées des bêtes de ferme, qualité de façon + signature des pièces
- [x] Lieux découverts → vitesse/chance + succès ; froid (neige la nuit) et chaleur (désert le jour, boire protège)
- [x] Talents de maître à choix exclusifs (palier 4, un sur deux par voie)
- [x] Villes de joueurs : Charte de ville + /fonder <nom>, un habitant PNJ par lit posé (/villes)
- [x] Quêtes bâtir / apprivoiser / prime (16 sortes) — 30 bancs Edit au vert en fin de session
- [x] Zones exigeantes : sommets, désert, boue des marais, grottes sombres + 4 tenues (banc `froid`)
- [x] Création du personnage à l'arrivée (plus de skin Roblox), barbier et tailleur au marché (banc `apparence`)
- [x] Audit du contenu : 0 trou (objets, créatures, recettes, butins, icônes) ; 3 icônes en carré vide corrigées
- [x] `liste quetes.txt` comparée au jeu → `docs/QUETES-COUVERTURE.md` (53/560 titres repris, 16 sortes)
- [ ] Quêtes « à un lieu » : retrouver, visiter, escorter, enquêter (≈150 idées de la liste)
- [ ] **TEST en Play** de tout ce qui précède (PC fixe)
- [ ] Icônes peintes à la place des emojis (il faut mettre des images en ligne avec le compte du joueur)
- Restes des listes, volontairement laissés : jeux de dés (règles Roblox sur les jeux de hasard), tutoriel (principe « sans indication »), guerres/alliances déclarées (retirées le 17/11), saisons (remplacées par les biomes)
