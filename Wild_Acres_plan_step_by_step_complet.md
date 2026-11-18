# WILD ACRES — PLAN DE DÉVELOPPEMENT INTÉGRAL, ÉTAPE PAR ÉTAPE

**But :** transformer la feuille de route actuelle en un ordre de travail complet, avec les fonctionnalités, les dépendances, les tests et les conditions de validation. Ce document est un complément structuré à la feuille existante, pas un remplacement du code déjà réalisé.

## Comment utiliser cette feuille

- `[x]` Déjà indiqué comme réalisé dans la feuille de route initiale. Cela reste à retester après intégration.
- `[~]` Partiellement réalisé ou à finir.
- `[ ]` À développer, décider ou valider.
- Coche une tâche uniquement quand elle fonctionne en jeu, que ses données sont sauvegardées, qu'elle est validée côté serveur et qu'elle a passé les tests prévus.
- Une fonctionnalité n'est pas « terminée » simplement parce que son interface existe.
- Les éléments marqués **DÉCISION** demandent de choisir explicitement : les intégrer, les reporter ou les écarter. Ne laisse pas ces points dans l'oubli.

> **Important :** aucun document ne peut garantir mathématiquement qu'aucune idée ne sera jamais oubliée. Cette feuille vise une couverture fonctionnelle très large et ajoute un audit final pour comparer chaque système du jeu à une liste de contrôle. Le mot « illimité » doit rester une règle de conception côté joueur ; techniquement, les données doivent être réparties et optimisées pour respecter les limites de la plateforme.

---

# ORDRE DE DÉVELOPPEMENT

## ÉTAPE 0 — AUDITER CE QUI EXISTE AVANT DE CONTINUER

Ne recommence pas les systèmes déjà construits. Vérifie-les et note précisément leur état réel.

- [x] Faire une copie de sauvegarde du projet avant toute grosse modification.
- [~] Créer une version de test séparée de la version publique.
- [x] Établir la liste de tous les scripts, modules, RemoteEvents, RemoteFunctions, modèles, interfaces et systèmes de données.
- [x] Pour chaque fonctionnalité actuelle, noter : `absente / commencée / codée / testée Studio / testée en ligne / validée`.
- [x] Repérer les systèmes en doublon, anciens scripts, modèles temporaires et interfaces inutilisées.
- [x] Repérer les fonctionnalités qui existent dans l'interface mais n'ont pas encore d'effet réel.
- [x] Repérer les fonctionnalités qui marchent en serveur seul, mais pas avec plusieurs serveurs actifs sur le même monde.
- [x] Identifier les systèmes qui dépendent les uns des autres.
- [x] Créer une liste des bugs connus et les classer : bloquant, majeur, mineur, esthétique.
- [x] Garder une liste séparée des idées refusées ou reportées, pour ne pas les confondre avec les oublis.
- [x] Définir les critères de validation avant de commencer chaque nouvelle étape.

**FAIT → `AUDIT.md`.** **Résultat attendu :** une photographie exacte du projet. Aucun nouveau gros système ne doit être ajouté tant que les pertes de données ou bugs bloquants du socle ne sont pas identifiés.

## ÉTAPE 1 — SOLIDIFIER LES DONNÉES ET L'AUTORITÉ DU SERVEUR

C'est la fondation de tout le MMORPG. Tous les systèmes futurs en dépendront.

### 1A. Découpage et sauvegarde
- [x] Sauvegarde du personnage global et verrouillage de session indiqués comme présents.
- [x] Lister précisément les données globales du personnage : inventaire, monnaie, équipement, apparence, niveau, XP, compétences, talents, titres, collections, réputation, primes, courrier, paramètres.
- [x] Lister précisément les données propres à chaque monde : position, lit/point de réapparition, parcelles, maisons, coffres, cultures, animaux, compagnons, constructions, modifications du terrain, PNJ ou événements persistants si nécessaire.
- [x] Définir ce qui est temporaire : cible, combat en cours, interaction maintenue, session de commerce ouverte, état temporaire d'un événement.
- [x] Versionner chaque format de données.
- [x] Prévoir les migrations de sauvegardes lors des mises à jour.
- [x] Prévoir sauvegarde périodique, à la déconnexion, à l'arrêt du serveur et aux moments critiques.
- [x] Prévoir la gestion des erreurs, nouvelles tentatives avec limites, délais et journalisation.
- [x] Prévoir une procédure de restauration après corruption ou mauvaise migration.
- [x] Répartir les données volumineuses en clés ou partitions déterministes : un inventaire ou une banque qui grandit ne doit pas dépendre d'une seule entrée qui finit par saturer.
- [x] Contrôler la taille des sauvegardes et les budgets de requêtes.

### 1B. Sécurité serveur
- [x] Journal des transactions côté serveur et alerte de gain d'or anormal indiqués comme présents.
- [~] Vérifier que le serveur décide des quantités, prix, dégâts, récompenses, XP, permissions, drops et acquisitions.
- [~] Ne jamais faire confiance à une valeur fournie directement par le client.
- [~] Vérifier côté serveur distance, ligne de vue si nécessaire, propriété, état de l'objet, quantité disponible et coût.
- [x] Protéger les RemoteEvents et RemoteFunctions contre les appels répétés, falsifiés ou trop fréquents.
- [x] Ajouter des identifiants de transaction pour éviter qu'une répétition de demande crée un double achat ou une double récompense.
- [~] Rendre atomiques les échanges, ventes, achats, dépôts, retraits, courriers, coffres communs et transferts.
- [x] Prévoir expiration et récupération des verrous après arrêt brutal d'un serveur.
- [~] Enregistrer les opérations sensibles : créations d'or, destructions d'or, objets rares, échanges, changements de propriété, sanctions et modifications administratives.
- [x] Ajouter une procédure pour désactiver rapidement un système exploité.

### 1C. Tests de panne et de concurrence
- [x] Déconnecter un joueur pendant une sauvegarde.
- [~] Arrêter brutalement le serveur pendant un échange, un dépôt, un achat et un transfert de monde.
- [x] Tester deux serveurs qui essaient de modifier le même coffre ou la même donnée.
- [x] Tester la reconnexion au moment où une session précédente est encore verrouillée.
- [x] Tester une réponse de service qui arrive en retard après une nouvelle opération.
- [~] Vérifier qu'aucune situation ne duplique ni ne détruit silencieusement des objets ou de l'or.

**Condition pour passer à l'étape 2 :** les sauvegardes, les transactions et les verrous sont fiables sous déconnexion, arrêt et concurrence.

## ÉTAPE 2 — TERMINER L'ENTRÉE EN JEU ET LE PERSONNAGE

La feuille actuelle parle de l'accueil et du personnage global, mais plusieurs fonctions fondamentales doivent être explicites.

### 2A. Première connexion et retour
- [x] Accueil et mondes réservés indiqués comme présents.
- [x] Définir le parcours d'un nouveau joueur : arrivée, création/chargement du personnage, choix ou découverte du monde, apparition.
- [x] Définir le parcours d'un joueur qui revient : rechargement du personnage, choix du monde connu ou reprise du dernier monde selon la règle retenue.
- [x] Gérer un personnage absent, une sauvegarde ancienne ou une sauvegarde partiellement récupérable.
- [x] Gérer les erreurs de chargement sans effacer les données.
- [x] Prévoir un bouton ou mécanisme de reconnexion après erreur de téléportation.
- [x] Ajouter une indication de chargement utile, sans écran interminable.

### 2B. Personnage et apparence
- [x] Fiche personnage, équipement, caractéristiques, compétences, collections et titres indiqués comme présents.
- [x] Définir la personnalisation visuelle : cheveux, visage, couleurs, vêtements et apparence autorisée.
- [x] Définir les emplacements d'équipement et les effets de chaque pièce.
- [x] Vérifier que les vêtements et équipements se voient correctement sur le personnage.
- [x] Sauvegarder apparence, équipement et préférences.
- [x] Prévoir un moyen de changer d'apparence en jeu, selon les règles choisies.
- [ ] Vérifier les animations et les proportions avec les équipements.

### 2C. Déplacements et état du personnage
- [~] Finaliser marche, course, saut et caméra. _(18/11 : la vitesse n'était appliquée nulle part → marche = BaseSpeed, course [Maj] / stick / bouton 🏃 avec endurance, monture = RIDE × allure ; saut et caméra Roblox par défaut, shift-lock retiré)_
- [x] Définir nage, entrée/sortie de l'eau et comportement dans les rivières/lacs.
- [~] Définir montée/descente des pentes, escaliers, échelles et obstacles. _(escaliers générés aux falaises, rampes / marches et ÉCHELLES grimpables en construction libre (18/11) ; à tester en Play)_
- [x] Définir dégâts de chute et protections éventuelles.
- [x] Définir santé, récupération, soins, repos et états temporaires si ces systèmes sont conservés.
- [x] Définir KO/mort, réapparition, protection à l'arrivée et récupération des objets.
- [x] Définir le rôle des lits, auberges et maisons comme points de réapparition.
- [x] Éviter la perte injuste d'objets lors d'un bug, d'une déconnexion ou d'un transfert raté.
- [ ] Ajouter les états d'animation utiles : porter, récolter, fabriquer, pêcher, monter, nager, interagir.

**DÉCIDÉ (AUDIT.md) : absentes comme jauges ; la nourriture reste un bonus.** **DÉCISION :** définir précisément si faim, soif, fatigue et température sont de vrais systèmes ou s'ils sont volontairement absents. Ne les ajoute pas juste pour faire « survie » si cela transforme le jeu en corvée.

## ÉTAPE 3 — FINALISER LA GÉNÉRATION DU MONDE ET LE STYLE MÉDIÉVAL

### 3A. Structure du monde
- [x] Île finie, cinq biomes, génération, lieux et PNJ indiqués comme présents.
- [x] Vérifier toutes les graines de génération sur plusieurs mondes.
- [x] Vérifier que les villages, routes, fermes, ruines, grottes, camps et donjons ne se chevauchent pas.
- [x] Vérifier qu'aucun point important ne se génère dans un endroit inaccessible.
- [ ] Vérifier les distances entre lieux, les routes et les chemins alternatifs.
- [x] Définir les zones de départ et les apparitions sûres.
- [x] Définir les zones publiques qui ne peuvent pas être privatisées. _(villages : pas de parcelle dedans ni contre — `Config.LIBRE.parcelleProcheVillage = false` ; le reste est libre, cf. principe « monde libre »)_
- [x] Définir les points d'intérêt communs, rares, secrets et uniques. _(communs : fermes, villages, ruines, bosquets ; rares : antres de boss, châteaux, donjons ; secrets : entrées de grottes, trésors de cartes ; uniques : ruine et port de départ, phare des îlots)_
- [x] Prévoir des variantes d'une même zone pour éviter les îles répétitives. _(îles à thème tirées au hasard : 7 thèmes, biomes, villages, faune signature — générateur v2)_

### 3B. Biomes et identité
- [x] Prairie, forêt rousse, désert, toundra et marais indiqués comme présents.
- [ ] Pour chacun des cinq biomes, compléter : flore, ressources, faune passive, prédateurs, créatures fantastiques, cultures, météo, matériaux, architecture, sons, lieux et événements.
- [~] Vérifier que chaque biome propose une raison d'y aller et une spécialité utile. _(cultures, filons, poissons et plantes sauvages propres à chaque biome ; commandes des villages pour ce que leur biome ne produit pas ; à vérifier en jeu)_
- [ ] Vérifier les transitions entre biomes.
- [x] Définir les ressources uniques et les ressources communes. _(communes : bois, pierre, fibres ; régionales : filons, poissons, plantes ; rares : or, mandragore, racine ancienne, fleur nocturne, trophées de boss)_
- [x] Définir les effets de l'épuisement local des ressources. _(monde fini : arbres, rochers, cactus ne reviennent pas (replanter) ; filons et plantes sauvages repoussent lentement)_

### 3C. Style médiéval
- [~] Maisons, échoppes, poste du shérif, boîte du messager, poteaux à lanterne et panneaux médiévaux partiellement refaits.
- [ ] Remplacer les maisons restantes au style moderne ou « quartier chic ».
- [~] Refaire le village de test avec maisons à colombages, torchis, pierre, bois sombre, chaume, tuiles ou ardoise.
- [~] Ajouter et harmoniser puits, place, marché, forge, moulin (grand moulin fait le 18/11), taverne, auberge, grange, écurie, chapelle/sanctuaire et palissade.
- [~] Ajouter hameaux, fermes isolées, tours de guet, ruines, camps, ports et bâtiments abandonnés. _(18/11 : quais des villages côtiers, châteaux sur les hauteurs ; restent hameaux et camps)_
- [~] Revoir les ponts visuellement et fonctionnellement. _(planches, poutres, rambardes, piliers, culées, rampes, garde invisible anti-chute ; lanternes aux deux bouts (18/11) ; à revoir en Play)_
- [ ] Vérifier tailles, hauteurs de portes, passages, meubles et escaliers.
- [ ] Remplacer les modèles temporaires et anciens modèles conservés uniquement comme archive.

### 3D. Terrain modifiable
- [x] Creusement, remblai et étangs sur les terres du joueur indiqués comme présents.
- [x] Définir les limites de modification et les zones protégées.
- [x] Sauvegarder les changements par secteur.
- [~] Vérifier trous, cavités, pentes, collisions et chutes après streaming ou téléportation.
- [x] Ajouter reboisement : graines/pousses, plantation, croissance, conditions et maturité.
- [~] Définir les effets du terrain sur les constructions, cultures, eau et ressources. _(cultures selon le biome et le sol labouré, crues qui arrosent, terrassement et étangs (Terraforme), construction libre sur tout terrain)_
- [x] Définir comment restaurer un terrain devenu impraticable à la suite d'un bug ou d'une action abusive.

## ÉTAPE 4 — TERMINER L'INVENTAIRE, LES OBJETS ET L'ÉQUIPEMENT

### 4A. Base de données du catalogue
- [x] Lots d'objets de construction, mobilier, ressources, équipement, cuisine, élevage, transport, exploration et collection indiqués comme intégrés.
- [x] Faire un inventaire unique de tous les objets présents dans le projet.
- [x] Pour chaque objet, définir : identifiant stable, nom, icône, modèle, catégorie, rareté, source, valeur, propriétés, recette, usages, conditions et caractère échangeable.
- [x] Définir les types d'objets : ressource, outil, consommable, équipement, pièce de construction, meuble, objet de quête/découverte, collection, monnaie, objet déployable.
- [x] Vérifier qu'aucun objet ne reste sans usage sauf s'il est volontairement décoratif ou collectionnable.
- [x] Retirer les doublons et les objets cassés.
- [~] Vérifier toutes les icônes, infobulles, modèles et descriptions.
- [x] Définir les raretés et la façon dont elles influencent l'obtention, sans rendre les objets courants inutiles.

### 4B. Sac, barre et stockage
- [x] Sac en grille, onglets, rareté, quantités, infobulles et barre rapide de neuf cases indiqués comme présents.
- [x] Ajouter tri, recherche et filtres si absents.
- [x] Ajouter transfert multiple et déplacement rapide vers coffres/ateliers/étals.
- [x] Définir empilement, division, fusion, échange, suppression, vente et dépôt.
- [~] Butin au sol (façon Minecraft / Fortnite) : ramassage au clic, invite [E] ou [Q] pour tout autour (`Systemes/Butin`) — à tester en Play.
- [x] Définir les objets liés au personnage, non échangeables, consommables ou posables.
- [x] Ajouter confirmations pour détruire ou vendre un objet rare.
- [ ] Tester sac très volumineux, transferts massifs et inventaire saturé.
- [x] Découper le stockage en pages/partitions techniques si nécessaire pour que le joueur puisse l'agrandir sans plafond arbitraire visible.
- [ ] Vérifier glisser-déposer et utilisation sur écran tactile.

### 4C. Équipement
- [x] Compléter toutes les cases d'équipement définies par le jeu : tête, corps, mains, accessoires, monture et outils si applicables.
- [x] Définir les statistiques et effets de chaque catégorie. _(cf. Gear.STATS : force = dégâts, défense = dégâts reçus, vie = +10 PV/pt, vitesse = course et endurance, chance = butin, charisme = prix et PNJ, discrétion = moins vu)_
- [x] Définir durabilité/usure seulement si cela crée des choix intéressants.
- [x] Définir réparation, remplacement et récupération. _(18/11 : usure → l'outil casse, on en refait un ; réparation à l'établi pour la moitié des matériaux ; décors et maisons rebâtis par les villageois en 4 jours)_
- [x] Vérifier que le changement d'équipement met à jour visuel, statistiques et sauvegarde.

## ÉTAPE 5 — TERMINER LES RESSOURCES, RÉCOLTES ET OUTILS

- [x] Créer la liste des ressources récoltables par biome et par lieu. _(arbres par biome `RegionPlan.TREES`, filons par biome, plantes sauvages `Herbes.POOLS`, cultures `BIOME_CROPS` ; fiche générée `docs/REFERENCE.md`)_
- [x] Définir les nœuds de ressources : arbre, roche, filon, plante, buisson, argile, sable, eau, etc. _(Props.KINDS + plantes sauvages + touffes de blé ; résistance par nœud, cf. Props « résistance et grind »)_ _(18/11 : codé, à tester en Play)_
- [x] Définir outil requis, durée, rendement, qualité éventuelle et état du nœud. _(outil requis ou mains nues, palier minimum, compétence minimum façon WoW ; durée = résistance ±25 % / force (outil × compétence) ; barre d'usure du nœud qui retombe après 8 s)_ _(18/11 : codé, à tester en Play)_
- [x] Définir les ressources épuisables, renouvelables et replantables.
- [x] Compléter bûcheronnage, minage, collecte, agriculture sauvage, cueillette et fouille. _(clic façon Minecraft sur tout, filons qui repoussent et repérés sur la minicarte, herboristerie, champs de blé de village, décors cassables)_ _(18/11 : codé, à tester en Play)_
- [x] Ajouter des trouvailles secondaires et des objets de collection sans surcharger les tables de butin. _(Util.finds / Catalogue.rollFinds par source et biome, chance, nuit ; collections)_
- [x] Vérifier l'absence de réapparition indésirable des arbres, rochers, filons et cactus, conformément à la règle actuelle du monde fini. _(règle changée le 18/11 à sa demande : les FILONS et les PLANTES SAUVAGES repoussent façon WoW ; arbres, rochers, cactus restent finis — banc `resistance`)_
- [x] Tester le reboisement et la repousse choisie des plantes.
- [~] Vérifier que les ressources rares sont accessibles dans plusieurs stratégies ou régions, sans être infinies. _(minerai : filons + butin de créatures ; plantes rares : plusieurs biomes + butin ; repousse lente ; à mesurer en jeu)_
- [~] Vérifier les outils : acquisition, amélioration, utilisation, animation, portée, délai et sauvegarde. _(atelier, paliers pierre/cuivre/fer, cadence 0,25 s, portée 14-16 studs, usure sauvegardée `wear` ; animation = coup « Slash » ; à tester en Play)_

## ÉTAPE 6 — TERMINER L'ARTISANAT ET LES STATIONS DE MÉTIER

- [x] Atelier 3×3, résultats possibles, découverte de recettes et carnet de recettes indiqués comme présents.
- [x] Inventorier toutes les recettes et vérifier ingrédients, quantités, résultat et coût.
- [x] Vérifier qu'aucune recette ne permet de dupliquer ressources ou monnaie.
- [~] Compléter les stations nécessaires : établi, forge, four, moulin, cuisine, métier à tisser, tannière, potier, poste d'herboriste et autres stations réellement utiles. _(établi, four, ENCLUME, MÉTIER À TISSER, BAC DE TANNAGE, ALAMBIC (18/11) ; la forge de chaque village sert d'enclume et de four publics ; moulin à poser ; le four sert de four de potier)_
- [~] Définir les outils requis pour chaque métier. _(bûcheron : hache ; mineur : pioche (palier) ; terrassier : pelle / bêche ; fermier : houe, arrosoir ; pêcheur : canne ; forgeron : enclume ; tisserand : métier à tisser)_
- [x] Définir les recettes connues dès le départ, découvertes par essai, livres, plans, artisans ou progression.
- [x] Ajouter fabrication multiple et affichage des coûts avant fabrication.
- [x] Ajouter messages d'ingrédients manquants et conditions non remplies.
- [x] Prévoir annulation, interruption et déconnexion pendant fabrication.
- [x] Sauvegarder les recettes découvertes de manière fiable.
- [x] Définir les paliers de qualité et de maîtrise s'ils ont une fonction réelle. _(rareté 1-4 de l'équipement, paliers d'outils pierre / cuivre / fer, talent Maître forgeron ; pas de qualité séparée (volontaire))_
- [x] Tester chaque recette avec inventaire juste suffisant, insuffisant et inventaire plein.

### Métiers à vérifier un par un
- [~] Forge et métallurgie. _(lingots et acier au four ; outils, armes, armures, clous, charnières, chaînes, ferrures, engrenages à l'enclume (18/11) ; usure / réparation)_
- [~] Menuiserie et charpenterie. _(planches, chevilles, engrenages et poulies en bois, mobilier, escaliers à l'établi ; pièces de bois / rondins / bardeaux en construction libre)_
- [~] Maçonnerie et taille de pierre. _(pierre, pierre taillée, ardoise en construction libre ; briques et tuiles au four ; colonnes et piliers)_
- [~] Tannage et travail du cuir. _(peau raclée, cuir souple, fourrure travaillée, sangles au bac de tannage (18/11) ; cuir → sacoches, sacs, livres, armure)_
- [~] Tissage, couture et teinture. _(fils, tissus, toile, étoffes teintes au métier à tisser (18/11))_
- [~] Poterie et contenants. _(argile préparée, pots, cruches, assiettes, bols, amphores, bouteilles au four)_
- [~] Cuisine et boulangerie. _(farine au moulin, pain et plats au four, compétence Cuisine, livres de recettes)_
- [~] Herboristerie et alchimie fictive. _(18/11 : plantes sauvages par biome, compétence, repousse ; extraits, potions, élixirs, infusions, baume, philtre à l'ALAMBIC ; chaque plante a maintenant un usage)_
- [~] Travail du verre. _(verre au four (sable + charbon), bouteilles, fioles, vitres, longue-vue)_
- [~] Fabrication de mobilier et décoration. _(tables, chaises, lits, étagères, tapis, pots de fleurs, lanternes, bancs ; catalogue décoratif)_
- [~] Fabrication et entretien des moyens de transport. _(barque, voilier à l'établi ; montures achetées / apprivoisées, pension d'écurie)_
- [~] Fabrication de matériel agricole et d'élevage. _(houe, arrosoir, arroseur, épouvantail, ruche, abreuvoir, mangeoire, clochette de troupeau)_

## ÉTAPE 7 — TERMINER LES COMPÉTENCES, TALENTS ET OBJECTIFS

- [x] Dix compétences, talents, niveaux, collections et titres indiqués comme présents.
- [~] Écrire pour chaque compétence : actions qui donnent de l'XP, progression, paliers, utilité et récompenses.
- [ ] Vérifier que chaque métier/activité progresse à un rythme comparable.
- [x] Vérifier que les gains ne peuvent pas être farmés par une action répétée sans coût.
- [ ] Vérifier qu'aucune compétence ne devient inutile au niveau avancé.
- [ ] Vérifier que les talents apportent de vrais choix, sans choix obligatoire unique.
- [x] Vérifier le coût et la possibilité de réinitialiser les talents.
- [~] Ajouter journal de découvertes, recettes, lieux visités, espèces et ressources connues.
- [~] Compléter titres, collections, hauts faits et récompenses cosmétiques. _(19 titres dont Herboriste, Maître herboriste, Bûcheron, Mineur, Spéléologue, Capitaine (18/11) ; collection des plantes sauvages ; restent récompenses cosmétiques)_
- [x] Ajouter objectifs personnels facultatifs si utiles, sans transformer le bac à sable en suite de quêtes obligatoires.
- [~] Définir des objectifs de long terme : bâtir, maîtriser un métier, découvrir des mondes, collectionner, commercer, développer un clan. _(titres, collections, compétences jusqu'au niveau 50, domaine sans plafond, clans, armée, mondes à découvrir)_
- [ ] Vérifier le parcours d'un joueur occasionnel et d'un nouveau joueur.

## ÉTAPE 8 — TERMINER AGRICULTURE, ÉLEVAGE ET ACTIVITÉS DE VIE

### 8A. Agriculture
- [x] Ferme, cultures et arroseur indiqués comme présents.
- [~] Pour chaque culture : graine, biome/sol, saison, croissance, besoin en eau, rendement et usage.
- [x] Définir préparation du terrain, semis, croissance, récolte et replantation. _(houe → sol labouré, graines, arrosage / arroseurs / pluie, jours de pousse par culture, récolte, graines à racheter ou récupérer)_
- [x] Ajouter gestion des arbres fruitiers et plantes pérennes si prévues.
- [x] Faire interagir la météo avec les cultures.
- [x] Définir stockage et conservation des récoltes.
- [~] Vérifier que les champs immenses ne font pas chuter le serveur.

### 8B. Élevage
- [x] Reproduction d'animaux et certains troupeaux indiqués comme présents.
- [~] Compléter les espèces domestiques, leurs produits et leurs usages. _(poule → œufs, vache → lait, mouton → laine, ruche → miel ; cheval, âne, mulet pour la monte)_
- [~] Définir eau, nourriture, abri, espace, croissance, reproduction et production. _(eau + nourriture : abreuvoir et mangeoire ; reproduction plafonnée par l'espace (anti-surcharge) ; production par espèce (`ANIMALS.every`))_
- [~] Ajouter étables, poulaillers, enclos, pâtures, abreuvoirs et mangeoires nécessaires. _(abreuvoir + mangeoire à poser : production plus rapide (18/11) ; enclos = clôtures et pièces de construction libre ; restent étables / poulaillers tout faits)_
- [x] Ajouter collecte de lait, laine, œufs, miel, plumes et autres produits. _(Traire / Tondre / Ramasser l'œuf, ruches, nids à dénicher pour les plumes)_
- [x] Définir soins, récupération et gestion des animaux bloqués.
- [~] Définir attribution de propriété et transfert d'un animal.
- [x] Ajouter ânes, mulets et autres montures de travail si retenus.
- [x] Empêcher la reproduction incontrôlée qui surcharge monde et sauvegardes.

### 8C. Pêche, cuisine et alimentation
- [x] Pêche, cuisine et boissons indiquées comme présentes.
- [x] Compléter les espèces de poissons et leurs lieux/habitats. _(Config.FISH : prix, compétence, biomes, rareté)_
- [x] Ajouter appâts, filets, pièges/casiers fictifs, paniers et équipements de pêche.
- [x] Ajouter qualité/rareté des prises si cela sert les métiers et collections. _(poids de rareté par espèce, appâts qui font venir les rares, collection des poissons)_
- [x] Définir les recettes, effets, durée et valeur des plats. _(chaque plat : vie rendue, prix, station, compétence de cuisine ; buffs d'objets « u:buff »)_
- [x] Définir conservation, séchage, fumage ou salage si cela apporte un métier intéressant.
- [x] Décider explicitement si la faim/soif existe ; éviter une maintenance permanente pénible.

## ÉTAPE 9 — TERMINER FAUNE, CRÉATURES, COMPAGNONS ET BOSS

### 9A. Faune passive
- [~] Compléter oiseaux, petits mammifères, insectes, reptiles, amphibiens et animaux aquatiques par biome. _(moineaux, rapaces, corbeaux, mouettes, papillons, lucioles, écureuils (18/11), lapins, renards, cerfs, crapauds…)_
- [x] Définir horaires, habitat, sons et réactions.
- [~] Ajouter comportements simples : manger, boire, se reposer, fuir, se cacher, migrer.
- [~] Ajouter traces, empreintes, nids, terriers, plumes, poils et cris. _(empreintes 18/11, nids à dénicher, plumes ; restent terriers, cris)_
- [x] Simuler les animaux éloignés de façon légère pour préserver les performances.

### 9B. Ennemis et créatures neutres
- [x] Bestiaire et boss originaux indiqués comme intégrés.
- [~] Auditer chaque créature : biome, lieu, niveau, rareté, horaire, comportement, butin, fréquence et conditions d'apparition.
- [x] Définir les réactions : passive, méfiante, territoriale, agressive, fuite, défense, poursuite limitée et appel d'alliés. _(Enemies : passif / neutre (s'énerve si on le frappe) / hostile, fuite (plus loin si on court, moins si accroupi), meutes, prédateurs qui chassent les proies, laisse et retour au territoire)_
- [x] Vérifier les créatures nocturnes et leur retour à l'état diurne.
- [x] Vérifier la réapparition et les zones de retour.
- [ ] Vérifier le butin, les taux et les récompenses d'XP.
- [ ] Tester toutes les créatures en solo et en groupe.
- [x] Vérifier que les boss ne peuvent pas être exploités pour obtenir indéfiniment des récompenses rares.

### 9C. Système de combat du joueur
- [x] Ciblage, plaques de créatures, indication de préparation d'attaque et priorité de cible indiqués comme présents.
- [x] Définir les règles du combat contre les créatures : portée, délai, validation serveur, interruption et fin de combat. _(Combat.attack côté serveur, délai 0,45 s, cible la plus proche dans la portée ; préparation visible (windup) des créatures ; fin quand la bête rentre à son territoire)_
- [x] Définir les catégories d'équipement de combat déjà présentes et leurs statistiques en jeu. _(Gear : coiffe, armure, arme, bijou ; stats force, défense, vie, vitesse, chance, charisme, discrétion ; rareté 1-4)_
- [~] Définir les rôles de l'armure, du bouclier, des accessoires et des améliorations. _(armure : défense / vie ; accessoires : chance, charisme, force… ; arme : puissance ; pas de bouclier)_
- [~] Définir les compétences de combat, leurs coûts, délais, conditions et progression. _(compétence Combat (+1 % de dégâts / niveau), talents Coup précis, Robuste, Menottes… ; pas de sorts actifs (volontaire))_
- [ ] Ajouter/valider les animations, effets et sons nécessaires pour que chaque action soit lisible.
- [~] Définir les effets temporaires de jeu éventuels : ralentissement, étourdissement bref, protection ou affaiblissement, sans effets injustes ou permanents. _(poison / toile des araignées et myconides : ralenti 40 % pendant 3 s (18/11) ; buffs d'objets (encens…) ; pas d'étourdissement)_
- [x] Définir l'agressivité des ennemis, leur cible, leur poursuite maximale et leur retour à leur territoire.
- [x] Définir les phases et signaux des boss, les contributions de groupe et le partage des récompenses. _(2 phases (à mi-vie : plus rapide, attaques plus serrées), préparation visible ; butin partagé : chaque participant à ≥ 10 % des dégâts reçoit sa part (18/11))_
- [x] Définir explicitement si le combat entre joueurs existe, dans quelles zones et avec quelles protections ; sinon le marquer volontairement absent.
- [x] Définir les règles de KO, réapparition, récupération et protection après un combat.
- [x] Vérifier que les dégâts, portées, temps de recharge et récompenses sont calculés côté serveur. _(le client n'envoie que « frapper » + la cible visée ; dégâts, portée, délai, butin : serveur)_
- [ ] Tester les combats en solo, en groupe, sur mobile et avec plusieurs combats simultanés.

### 9D. Compagnons et dressage
- [x] Compagnons indiqués comme présents.
- [x] Définir acquisition, dressage, confiance, nourriture, soins, ordres et rappel. _(apprivoisement au mini-jeu (Dressage), nourrir ses bêtes, ordres SUIVRE / GARDER, rappel à la clochette de troupeau, confiance qui monte chaque jour nourri (+30 % de dégâts au maximum) (18/11))_
- [x] Définir comportement en combat et hors combat. _(suit et se bat à tes côtés si prédateur ; en garde : grogne puis mord les intrus, chasse les cambrioleurs ; bêtes de ferme : produisent)_
- [~] Définir équipement, progression et utilité de chaque compagnon. _(utilité par espèce (garde, combat, production), confiance qui monte en les nourrissant ; pas d'équipement de bête)_
- [~] Définir retour, récupération et persistance après déconnexion/changement de monde. _(enregistrés par monde : G.world.players[uid].pets ; restent dans leur monde)_
- [x] Garder le principe d'entretien plutôt qu'un plafond artificiel, tout en protégeant les performances. _(principe « pas de plafond arbitraire » appliqué : limite = nourriture / ressources)_

## ÉTAPE 10 — CRÉER UNE VRAIE VIE DE VILLAGE AVEC LES PNJ

La feuille d'origine indique des PNJ, mais elle ne détaille pas encore leur simulation et leurs métiers.

### 10A. Habitants et routines
- [~] Créer les rôles : fermier, éleveur, forgeron, boulanger, cuisinier, marchand, aubergiste, garde, shérif, messager, artisan, voyageur, dirigeant. _(fermiers, marchands, shérifs, habitants, maire élu ; services : forgeron (réparation), palefrenier (écurie), aubergiste (lits), poste ; aubergiste qui sert un repas chaud (18/11) ; restent boulanger / cuisinier en PNJ dédiés)_
- [~] Définir pour chaque PNJ : domicile, métier, horaires, déplacements, interactions et réactions. _(domicile et lieu de travail générés, horaires jour / nuit, repas à la taverne, abri sous l'orage, réactions aux crimes)_
- [x] Faire travailler, se reposer, manger et circuler les habitants.
- [~] Ajouter réactions aux dangers, intempéries, événements et crimes.
- [~] Ajouter fuite, alerte, refuge et retour à la routine. _(fuite devant un recherché, alerte, retour à la routine après le dialogue ; refuge à la maison la nuit)_
- [x] Prévoir la récupération d'un PNJ coincé ou disparu.
- [ ] Optimiser la simulation loin des joueurs.

### 10B. Dialogues et relations
- [x] Ajouter salutations, informations locales, commerce, rumeurs et demandes facultatives. _(Discuter, « Des nouvelles du coin ? », boutique, commandes, « Tu as du travail pour moi ? » → quêtes du village)_
- [x] Ajouter réputation locale distincte de l'honneur global si nécessaire. _(opinion de chaque habitant envers chaque joueur, `Npcs.op` / per.ops)_
- [x] Faire réagir les PNJ aux services rendus et aux actes observés. _(cadeaux, conversations, achat d'une bête → opinion ; crimes vus (`canSee`) → mémoire « robbed », fuite, alerte)_
- [x] Empêcher les PNJ de connaître des événements qu'ils n'ont pas pu voir/apprendre. _(mémoire seulement par témoignage (canSee) ou par les ragots entre habitants)_
- [~] Prévoir des dialogues courts et des choix utilisables sur mobile. _(dialogues à boutons courts (Discuter, Nouvelles, Travail, Boutique…) ; à tester sur mobile)_

### 10C. Services PNJ
- [~] Marchands avec inventaire, spécialité, prix, horaires et renouvellement. _(boutique, rachat ≤ 80 %, commandes du village selon son biome, horaires (tient boutique le jour))_
- [x] Forgerons/artisans avec services de fabrication ou réparation si prévus. _(forge de village : « Faire réparer mes outils » contre de l'or, enclume et four publics (18/11))_
- [x] Auberges avec lits, repos, réapparition et location.
- [~] Écuries avec stockage, récupération et gestion des montures. _(18/11 : « Faire venir ma monture » à l'écurie d'un village, pension 5 or, même si sa région n'est pas chargée)_ _(18/11 : codé, à tester en Play)_
- [x] Messagers et services de courrier si distincts du courrier joueur. _(Systemes/Poste, boîtes aux lettres des villages ; gains de concours versés par courrier)_
- [x] Services publics : affichage, commandes de village, réparations, projets collectifs. _(tableau d'affichage, tableau des quêtes, commandes du marchand, conseil du village et ses projets, reconstruction par les villageois)_

## ÉTAPE 11 — TERMINER CONSTRUCTION, PARCELLES ET PROPRIÉTÉS

### 11A. Construction libre
- [x] Pièces fabriquées, placées depuis la barre rapide, aperçu fantôme et rotation indiqués comme présents.
- [x] Mobilier de base et pièces de construction déjà intégrés.
- [ ] Auditer toutes les formes, matériaux, toits, portes, fenêtres, escaliers, clôtures et éléments décoratifs.
- [~] Ajouter les formes manquantes retenues : courbes, arches, rampes, rambardes, pièces inclinées et raccords. _(rampes, barrières, pentes, coins, piliers, colonnes, échelles (18/11) ; restent courbes et arches)_
- [ ] Vérifier le placement libre, rotation, retournement et reprise d'une pièce.
- [~] Ajouter sélection multiple, déplacement et récupération en lot si nécessaire. _(récupération en lot : /demonter <rayon>, matériaux rendus (18/11) ; reprendre une pièce rend enfin ses matériaux (bug corrigé) ; restent sélection / déplacement)_
- [ ] Ajouter plan de construction partageable si cela ne supprime pas le coût des matériaux.
- [ ] Vérifier collisions, pièces flottantes involontaires et accès aux portes.
- [ ] Optimiser et tester les grandes maisons très détaillées.
- [x] Vérifier sauvegarde et chargement des constructions complexes.

### 11B. Parcelles, accès et permissions
- [x] Parcelles, coffres et territoires de clan v1 indiqués comme présents.
- [x] Définir propriétaire, copropriétaire, membre du clan, locataire, visiteur et public.
- [~] Séparer permissions : construire, détruire, ouvrir, déplacer, utiliser, gérer animaux, gérer coffres et commercer.
- [x] Ajouter transfert de propriété, location, expiration et restitution. _(cession : /ceder <pseudo> + /accepter ; location : /louer <pseudo> <jours> <prix> + /accepter, accès « bâtir » qui expire seul (18/11) ; démonter le panneau libère le terrain)_
- [x] Définir le sort des biens quand le propriétaire quitte un clan ou reste inactif. _(les terres et biens restent au joueur, même absent longtemps (absents protégés) ; quitter un clan ne retire rien ; il peut céder ou louer : /ceder, /louer)_
- [x] Ajouter un historique des accès et modifications importantes.
- [~] Protéger routes, ports, apparitions, lieux publics et ressources partagées. _(pas de parcelle dans / contre un village ; forge publique, quais publics ; le reste est libre (principe « monde libre »))_
- [~] Empêcher l'enfermement d'un joueur et le blocage abusif des passages. _(/coince : 5 s immobile → remis sur le sol le plus proche, 1 fois / min (18/11) ; monde libre : pas d'interdiction de bâtir)_

### 11C. Destruction, cambriolage et réparation
- [x] Définir précisément quels éléments des villages, propriétés et décors sont destructibles. _(Demolir : maisons des villages, tout le décor, objets posés par les autres ; terrain : Terraforme)_
- [x] Définir outils, temps, bruit, permissions et conséquences. _(maison 36 coups, décor 6, objet posé selon l'objet ; décor léger à mains nues ; vandalisme si un témoin voit)_
- [x] Faire intervenir témoins, gardes, shérifs et réputation locale. _(Law.crime → témoins, étoiles, primes, honneur, mémoire des habitants)_
- [x] Définir butin éventuel et limites pour éviter une destruction rentable sans fin. _(butin selon le décor (foin → blé, puits → pierre…), petits volumes, reconstruction seulement au bout de 4 jours)_
- [~] Ajouter réparation par propriétaire, artisans ou villageois. _(outils : à l'établi ou chez le forgeron ; bâtiments de village : rebâtis par les villageois en 4 jours ; pièces de joueurs : à refaire)_
- [x] Ajouter réparation/reconstruction de bâtiments publics selon ressources et délais. _(les villageois rebâtissent maisons et décor en 4 jours — Demolir.REBUILD_DAYS)_
- [~] Protéger les absents et les nouveaux joueurs. _(maison jamais vidée, tourelles / serrures / chiens qui gardent même hors ligne, banque incambriolable ; les protections d'arbitre sont coupées par principe (Config.LIBRE))_
- [ ] Tester destruction répétée, dégâts autour d'une apparence et griefing.

## ÉTAPE 12 — TERMINER L'ÉCONOMIE ET LE COMMERCE

- [x] Échange direct, commandes de villages, banque, étals, hôtel des ventes et compétence Commerce indiqués comme présents.

### 12A. Monnaie et équilibre
- [x] Lister toutes les sources d'or : ventes PNJ, commandes, événements, butin, récompenses, courrier, etc.
- [x] Lister toutes les sorties d'or : frais, taxes, réparations, services, construction, entretien, améliorations, etc.
- [ ] Mesurer régulièrement création/destruction d'or par monde et par joueur.
- [ ] Mesurer la production et la consommation de chaque ressource importante.
- [x] Définir les dépenses facultatives des joueurs très riches sans leur imposer une connexion quotidienne. _(terrains de plus en plus chers (100 × n²), agrandissement de banque, clans (1000), armée et sa solde, équipement légendaire, voiliers, cagnottes de concours)_
- [ ] Vérifier qu'aucun métier ou événement ne domine économiquement tous les autres.
- [~] Prévoir limites anti-abus sur commandes répétables et récompenses automatiques.

### 12B. Échange et ventes
- [ ] Tester échange direct avec confirmation des deux joueurs, fermeture, annulation et déconnexion.
- [ ] Tester étals hors ligne, caisse, invendus, courrier et remboursement.
- [~] Tester hôtel des ventes, frais, recherche, filtres et expiration.
- [x] Ajouter comparaison et tri des offres si manquants.
- [x] Définir les règles de commerce entre mondes.
- [x] Ajouter contrats de livraison joueur-joueur si cela enrichit le transport. _(/commande <objet> <n> <prix> : or bloqué ; /commandes ; /livrer <n°> : payé tout de suite, marchandise par courrier ; /annuler : or rendu par courrier (18/11))_
- [~] Enregistrer un journal compréhensible des transactions. _(registre des mouvements importants, alerte d'or anormal, journal des coffres de clan et de propriété)_

### 12C. Banque et stockage
- [x] Banque de village et tailles de coffre indiquées comme présentes.
- [x] Vérifier dépôts, retraits, frais, agrandissement et accès.
- [x] Définir permissions des coffres personnels et communs. _(coffre perso : propriétaire + /autoriser coffres|batir ; coffre de clan : dépôt pour tous, retrait Intendant+ ; banque de village : propriétaire seul)_
- [x] Ajouter historique des dépôts/retraits.
- [x] Vérifier que les stockages agrandissables restent techniquement répartis et fiables.
- [ ] Tester les transferts massifs et la panne en cours d'opération.

## ÉTAPE 13 — TERMINER LE MULTIJOUEUR ET LA VIE SOCIALE

- [x] Groupes, clans, courrier entre joueurs, auberge et titres indiqués comme présents.
- [x] Définir invitations, acceptation, refus, expiration et blocage des invitations.
- [x] Définir groupes, chef de groupe, départ, reconnexion et transfert ensemble. _(chef, invitation 60 s, départ / dissolution, retour automatique dans le groupe après une déconnexion de moins de 5 min (18/11), voyage en groupe par la carte des mondes)_
- [ ] Vérifier distance, affichage des membres et permissions du groupe.
- [~] Définir amis, liste de joueurs, rejoindre un ami et confidentialité selon les options Roblox disponibles.
- [x] Définir les moyens de communication disponibles et les réglages de confidentialité.
- [x] Ajouter emotes, salutations et interactions non verbales si prévues.
- [x] Ajouter visite de maisons et boutiques avec permissions.
- [x] Définir courrier, pièces jointes, frais, limites techniques et anti-spam.
- [x] Prévoir signalement, blocage et gestion des interactions nuisibles.
- [x] Vérifier qu'un joueur bloqué ne peut pas contourner facilement les protections via groupes, courrier ou événements.

## ÉTAPE 14 — TERMINER CRIME, JUSTICE ET PROTECTION

- [x] Serrures, crochetage, alarmes, cambriolages, journal, étoiles et primes persistantes indiqués comme présents.
- [x] Définir les règles précises de vol, intrusion, agression fictive et destruction. _(Config.CRIMES : étoiles, honneur, prime, opinion par type ; vandalisme pour la casse)_
- [x] Définir comment un témoin observe un acte : portée, visibilité, bruit et éclairage. _(Npcs.canSee : portée jour / nuit, météo (brouillard), ronde de nuit du village, discrétion du joueur, ligne de vue ; endormis et assommés ne voient rien ; sinon cloche d'alarme)_
- [x] Définir fiabilité du témoignage et réactions des habitants. _(un vol n'est dénoncé que par les caractères « mouchards » ; témoins : opinion en baisse, mémoire de l'acte, ragots, réaction)_
- [~] Ajouter alertes, fuite, appel aux gardes, fermeture des commerces et enquête simplifiée si utile. _(alerte, fuite, shérifs qui foncent sur la dernière position, cloches d'alarme, commerces de la région fermés 2 min après un crime vu (18/11) ; reste une enquête simplifiée)_
- [x] Définir intervention des gardes/shérifs, arrestation et résolution des primes. _(Law.report → recherche / poursuite des shérifs ; talent Menottes : cellule + prime encaissée ; primes persistantes)_
- [x] Définir les règles de protection des biens hors ligne. _(rien ne disparaît hors ligne ; à toi de te protéger : serrures 4 niveaux, chiens de garde, alarme, tourelles à munitions, banque de village)_
- [x] Empêcher les poursuites sans fin, le spawn camping et le ciblage répété.
- [x] Créer des zones sûres ou protections de réapparition adaptées.
- [ ] Tester les conflits entre groupes, joueurs seuls et plusieurs serveurs.
- [ ] Garder des conséquences de jeu compréhensibles, sans rendre impossible le retour au jeu.

## ÉTAPE 15 — TERMINER CLANS, TERRITOIRES, ARMÉES ET POLITIQUE

### 15A. Clans
- [x] Clans avec nom/tag filtrés, grades, coffre commun et journal indiqués comme présents.
- [x] Définir précisément les permissions de chaque grade. _(Recrue / Membre : déposer au coffre ; Intendant : retirer ; Officier : inviter, exclure et promouvoir les grades inférieurs ; Bras droit, Chef ; le chef ne peut pas être exclu)_
- [x] Ajouter départ, exclusion, succession du chef et dissolution. _(le plus gradé succède au chef ; dernier départ = clan dissous, nom libéré — 18/11)_
- [x] Définir le sort des biens et ressources lors d'un départ. _(ses biens personnels le suivent, le coffre commun reste au clan ; archivé s'il est dissous)_
- [x] Ajouter alliances/relations entre clans si réellement nécessaires. _(volontairement absent : alliances et conflits naissent des joueurs (principe « tout organique »))_
- [x] Protéger le coffre commun contre retrait abusif. _(retrait réservé aux Intendants et plus, écriture atomique UpdateAsync, journal de chaque dépôt / retrait)_

### 15B. Territoires et avant-postes
- [x] Construction entre parcelles des membres présente ; avant-postes contestables faits (Systemes/Avantpostes).
- [x] Définir coût, entretien, ravitaillement et bénéfices des avant-postes.
- [x] Définir contestation et changement de contrôle.
- [x] Préserver des espaces et ressources pour les joueurs indépendants.
- [x] Empêcher un clan de bloquer les routes, ports, apparitions et points nécessaires.
- [x] Vérifier qu'une domination territoriale ne peut pas devenir irréversible.

### 15C. Armées
- [x] Caserne, unités, solde, désertion et perte définitive indiquées comme présentes.
- [x] Définir recrutement, équipement, formation, moral, disponibilité et ordres. _(caserne sur sa parcelle, une recrue après l'autre, or + nourriture, ordres suivre / garder, désertion si solde impayée, équipement fer + cuir à la caserne (+25 % dégâts, −20 % reçus) (18/11))_
- [~] Définir déplacement, défense, retour et récupération des unités. _(ordres « me suivre » / « garder ici », défense des terres ; mort définitive)_
- [x] Définir entretien et ravitaillement, sans plafond numérique arbitraire visible. _(solde de toute l'armée chaque matin, 2 jours impayés = un déserteur, mort définitive)_
- [ ] Tester l'impact de grandes armées sur le serveur.
- [x] Définir règles de conflit organique et de défense des joueurs isolés. _(aucune guerre déclarée ; règles normales (étoiles, primes) ; défense : serrures, chiens de garde, alarmes, tourelles à munitions même hors ligne)_

### 15D. Politique de village
- [x] Définir élection du maire, conditions, durée, succession et absence prolongée.
- [x] Définir taxes locales et budget public.
- [~] Ajouter projets : routes, ponts, puits, palissades, marchés, réparations et bâtiments communs.
- [x] Rendre recettes et dépenses visibles aux habitants.
- [x] Empêcher qu'une direction de village bloque les services essentiels.

## ÉTAPE 16 — TERMINER LES MONDES PERSISTANTS, VOYAGES ET TRANSPORTS

- [x] Carte maritime des mondes connus, découverte de mondes, graine et voyage en groupe indiqués comme présents.

### 16A. Registre et persistance des mondes
- [ ] Vérifier identifiant unique, graine, version du générateur, statut et dernière activité de chaque monde.
- [x] Garantir qu'un monde découvert conserve sa graine et ses modifications. _(registre WA_Registre {name, seed, code}, état par secteurs de 4×4 régions)_
- [x] Gérer les créations simultanées de mondes sans doublons involontaires. _(création atomique : UpdateAsync sur le registre, identifiant unique par monde, un serveur réservé par monde)_
- [x] Gérer population, serveurs multiples et regroupement de joueurs. _(un monde = un serveur réservé ; l'accueil compte les présents (MemoryStore), montre les plus peuplés d'abord et ouvre un monde de plus quand tous sont presque pleins)_
- [x] Prévoir réouverture d'un monde dont aucun serveur n'est actuellement actif. _(un monde = un code de serveur réservé : le rejoindre relance un serveur)_
- [x] Prévoir compatibilité des anciens mondes après mise à jour du générateur.
- [x] Tester les modifications persistantes par secteur.

### 16B. Navigation et maritime
- [x] Ajouter barque, bateaux et voiliers avec contrôles simples. _(barque 16, voilier 28 studs/s, Z/S Q/D)_ _(18/11 : codé, à tester en Play)_
- [x] Ajouter ports, quais, plages, mouillages et points d'embarquement. _(port d'arrivée + quai de chaque village côtier, « Prendre la mer »)_ _(18/11 : codé, à tester en Play)_
- [x] Ajouter îlots, récifs, phares, épaves, ruines côtières et secrets.
- [x] Définir capacité de passagers et cargaison.
- [x] Définir équipage, embarquement et débarquement.
- [x] Définir météo maritime et conséquences lisibles. _(orage : bateaux à 70 %, tangage ×3, avertissement au barreur)_ _(18/11 : codé, à tester en Play)_
- [x] Définir perte de connexion, échec de téléportation, serveur plein et récupération du voyage. _(TeleportInitFailed → Mondes.travelFailed (message, on reste sur place) ; mondes pleins écartés ; le perso est sauvegardé avant le départ)_
- [ ] Tester les voyages en groupe et les départs séparés.

### 16C. Transport terrestre
- [~] Finaliser chevaux et équipement de monture. _(18/11 : vitesse à cheval enfin appliquée, selles colorées ; reste harnais / sacoches)_
- [x] Ajouter ânes et mulets si retenus.
- [x] Ajouter selles, harnais, sacoches et matériel de transport. _(selles colorées ; charrettes ; sacoches volontairement absentes : le sac n'a pas de limite)_
- [x] Ajouter charrettes, chariots et wagons si retenus.
- [~] Définir capacité, vitesse, maniabilité, entretien et récupération. _(vitesse et maniabilité : Config.MOUNTS, Barques.KINDS ; récupération : sifflet, écurie ; entretien : non)_
- [x] Prévoir stationnement, écuries, attache et récupération après déconnexion. _(la monture reste où on l'a laissée (sauvegardée), écurie pour la faire venir, barques gardées dans le monde)_ _(18/11 : codé, à tester en Play)_

## ÉTAPE 17 — TERMINER MÉTÉO, SAISONS ET ÉVÉNEMENTS

- [x] Événements v1, boss itinérants, grottes et donjons indiqués comme présents.
- [x] Ajouter météo : pluie, orage, brouillard, vent, neige, gel et sécheresse.
- [x] Définir effets météo sur culture, visibilité, navigation, faune et déplacements.
- [~] Ajouter saisons et changements visuels par biome.
- [x] Définir effets saisonniers sur récoltes, animaux et activités.
- [~] Ajouter ambiance sonore et indices visuels/sonores.
- [~] Compléter événements pacifiques : foires, marchés, migrations, concours, découvertes et cérémonies. _(concours de pêche, récolte, minage, bûcheronnage, rassemblements libres)_
- [x] Compléter événements dangereux : invasions, convois, créatures errantes, phénomènes et boss. _(invasions nocturnes, convois attaqués, 4 boss itinérants originaux, pluie de cristaux, crues)_
- [~] Définir fréquence, durée, conditions, récompenses et conséquences de chaque événement. _(Evenements : foire (1 jour, +30 %), invasion nocturne, boss itinérants, convois, crues, pluie de cristaux ; tirage quotidien)_
- [x] Faire en sorte que les événements soient découverts dans le monde, selon le principe du jeu. _(rien n'est annoncé : seuls ceux qui sont dans le coin voient ou entendent)_
- [ ] Vérifier événements avec serveur vide, peu de joueurs et serveur plein.
- [x] Définir ce qui se passe quand personne ne répond à un événement.
- [ ] Vérifier que les récompenses ne créent pas d'inflation ou de farm.

## ÉTAPE 18 — TERMINER LES DONJONS, SECRETS ET EXPLORATION À PIED

- [x] Grottes et donjons avec entrées cachées, galeries, gardien et coffre indiqués comme présents.
- [~] Compléter lieux secrets : ruines, cryptes fictives, sanctuaires, tours, cavernes, épaves, camps et trésors enfouis.
- [~] Définir l'indice de découverte : carte, rumeur, trace, inscription, bruit ou observation.
- [x] Ajouter cartographie, carte personnelle, boussole, repères et carnet.
- [x] Définir lieux uniques et lieux renouvelables.
- [~] Définir coffres, clés, pièges de jeu non réalistes, énigmes et récompenses.
- [~] Ajouter puzzles d'environnement et mécanismes médiévaux fictifs. _(grottes : coffre ancien scellé tant que les leviers cachés dans les salles (jusqu'à 3) ne sont pas abaissés, à plusieurs possible (18/11))_
- [ ] Équilibrer les donjons pour solo et groupes.
- [~] Prévoir les joueurs qui quittent un donjon, se déconnectent ou reviennent. _(la grotte n'existe que tant que quelqu'un s'y trouve ; coffre regarni tous les quelques jours)_
- [x] Vérifier que les secrets ne deviennent pas tous connus instantanément si la découverte fait partie du plaisir.

## ÉTAPE 19 — TERMINER LES ACTIVITÉS CRÉÉES PAR LES JOUEURS

- [~] Courses de montures et parcours. _(rassemblement libre au tableau ; la vitesse des montures compte enfin depuis le 18/11)_
- [x] Concours de pêche, agriculture, élevage et artisanat. _(+ minage et bûcheronnage le 18/11)_
- [x] Expositions de bâtiments et concours de décoration. _(« Concours de construction » au tableau d'affichage, jugé par l'organisateur (18/11))_
- [~] Chasses au trésor créées par les joueurs.
- [~] Marchés temporaires, foires et ventes publiques.
- [~] Tournois et défis de compétences de jeu, avec règles sûres et non graphiques.
- [x] Outil d'organisation : lieu, heure, règles, inscriptions, équipes et récompenses.
- [x] Permissions d'organisateur et possibilité d'annuler un événement.
- [x] Protection contre les événements utilisés pour piéger ou harceler.
- [x] Tableau d'affichage local et invitation facultative.
- [x] Récompenses équilibrées et non exploitables.

## ÉTAPE 20 — TERMINER L'INTERFACE ET LES COMMANDES SUR TOUTES LES PLATEFORMES

- [x] Inventorier tous les menus et fenêtres : accueil, personnage, sac, barre rapide, talents, compétences, atelier, recette, coffre, banque, boutique, étal, hôtel des ventes, courrier, groupe, clan, territoire, armée, carte, journal, monture, animal, construction et paramètres. _(→ `docs/INTERFACE.md`, 18/11)_
- [x] Remplacer les listes textuelles restantes par une interface cohérente avec icônes là où cela améliore la lecture : boutique, coffre, courrier, étal et clan.
- [~] Ajouter recherche, filtres, tri, pagination et infobulles pour les listes longues. _(infobulles des outils avec usure, 18/11)_
- [ ] Ajouter états vides, chargement, réussite, échec et messages d'erreur compréhensibles.
- [~] Ajouter confirmations pour les achats, destructions, échanges et actions irréversibles. _(confirmation pour détruire / vendre un objet rare, double confirmation des échanges)_
- [ ] Tester clavier/souris, tactile et manette.
- [~] Tester petits écrans, tablettes et différentes résolutions.
- [~] Vérifier que les boutons sont assez grands et ne gênent pas le déplacement.
- [~] Ajouter réglages caméra, sensibilité, audio, qualité graphique et effets visuels.
- [x] Ajouter options de réduction des effets et secousses.
- [~] Ajouter aide contextuelle facultative et rappel des contrôles.
- [ ] Vérifier lisibilité, contraste, taille de texte et navigation entre menus.
- [ ] Préparer traduction/localisation si le jeu prévoit d'autres langues.

## ÉTAPE 21 — AUDIO, ANIMATIONS ET POLISSAGE VISUEL

- [~] Créer sons d'ambiance distincts par biome, météo et moment de la journée.
- [~] Ajouter sons d'outils, récolte, forge, cuisine, portes, animaux, montures, interactions et interface.
- [ ] Ajouter musique réglable et discrète si elle est prévue.
- [ ] Ajouter animations de récolte, fabrication, pêche, cuisine, commerce, dressage, construction et repos.
- [ ] Ajouter animations et réactions pour habitants, animaux et créatures.
- [ ] Uniformiser éclairages, matériaux, proportions, couleurs et style médiéval.
- [~] Vérifier que les effets visuels indiquent clairement danger, rareté, progression et résultat. _(18/11 : barre d'usure des nœuds, barre d'usure des outils, reflets des gisements, liseré de rareté)_
- [x] Vérifier volume, distance et répétition des sons.
- [ ] Retirer modèles, sons, icônes et éléments temporaires.

## ÉTAPE 22 — SÉCURITÉ DES JOUEURS, MODÉRATION ET RÈGLES ROBLOX

- [ ] Vérifier les règles Roblox en vigueur avant publication et à chaque évolution majeure.
- [x] Vérifier noms de clans, mondes, panneaux, enseignes et contenus personnalisés.
- [x] Utiliser les mécanismes de filtrage et de modération adaptés aux communications disponibles. _(chat Roblox (TextChatService, filtré), noms de clans / tags / panneaux filtrés par TextService, courrier sans texte libre)_
- [x] Ajouter signalement, blocage, sanctions graduées et procédure de traitement. _(/signaler, /bloquer ; admins : /wa avertir → muet → expulser → bannir N jours, tout noté au registre (18/11))_
- [~] Prévoir une procédure d'appel ou de correction d'une sanction injustifiée. _(correction : `docs/PROCEDURES.md` §4 ; reste à choisir le canal de contact hors jeu)_
- [x] Protéger les joueurs contre ciblage répété, spam, enfermement et harcèlement.
- [x] Limiter les informations personnelles visibles et ne pas collecter de données inutiles.
- [x] Vérifier que le courrier, les invitations et les événements ne permettent pas de contourner les protections.
- [ ] Vérifier les droits d'utilisation des modèles, images, sons et musiques.
- [x] Prévoir outils d'administration sécurisés et journalisés.
- [x] Définir une procédure de réponse à un exploit, une faille ou un comportement dangereux. _(→ `docs/PROCEDURES.md` §2)_

## ÉTAPE 23 — DÉCIDER ET METTRE EN PLACE LA MONÉTISATION (SI LE JEU EN A UNE)

**DÉCISION :** le jeu peut être complet sans monétisation agressive. Si tu en ajoutes une, elle doit être transparente, conforme aux règles Roblox et ne pas rendre le jeu injuste.

- [x] Décider si le jeu sera gratuit, avec achats facultatifs, ou avec accès payant.
- [x] Définir une ligne claire : cosmétiques, confort raisonnable, accès à des fonctions sociales ou autre modèle choisi.
- [x] Éviter que payer soit nécessaire pour être compétitif ou accéder aux activités centrales.
- [x] Afficher clairement le contenu et le prix avant tout achat. _(sans objet : aucune vente en Robux — décision AUDIT ; à refaire si une monétisation est ajoutée)_
- [x] Tester achat réussi, achat annulé, erreur, remboursement et déconnexion pendant une transaction. _(sans objet : aucune vente en Robux — décision AUDIT ; à refaire si une monétisation est ajoutée)_
- [x] Valider les achats côté serveur et éviter les doubles attributions. _(sans objet : aucune vente en Robux — décision AUDIT ; à refaire si une monétisation est ajoutée)_
- [x] Vérifier les règles Roblox actuelles relatives aux achats, objets aléatoires payants, abonnements et contenus numériques avant d'implémenter ces systèmes. _(sans objet : aucune vente en Robux — décision AUDIT ; à refaire si une monétisation est ajoutée)_
- [x] Ne pas ajouter de système de pari ou de casino.
- [x] Prévoir un journal d'achat et un outil d'assistance en cas de problème. _(sans objet : aucune vente en Robux — décision AUDIT ; à refaire si une monétisation est ajoutée)_

## ÉTAPE 24 — OUTILS D'ADMINISTRATION, SUPPORT ET MAINTENANCE

Ces outils sont souvent oubliés, mais ils sont essentiels pour un jeu persistant.

- [~] Tableau de bord développeur : état des serveurs, joueurs, mondes, erreurs et sauvegardes.
- [x] Outils de recherche d'un joueur et de son état de données sans afficher d'informations privées inutiles. _(/wa joueur <pseudo> : or, étoiles, prime, honneur, clan, avertissements)_
- [x] Outils contrôlés pour corriger un inventaire ou une transaction après preuve d'un bug.
- [x] Outils pour fermer proprement un serveur, annoncer une maintenance et relancer un monde.
- [~] Outils pour examiner les logs d'économie, de commerce, de clan et de modération.
- [x] Outils pour activer/désactiver une fonctionnalité en urgence.
- [~] Système de signalement joueur et suivi des demandes d'aide. _(/signaler <pseudo> <motif> : noté au registre, admins présents prévenus (18/11) ; /bloquer)_
- [x] Procédure de restauration après corruption ou bug de mise à jour.
- [x] Procédure pour déployer une mise à jour sans casser les mondes existants. _(→ `docs/PROCEDURES.md` §1)_
- [x] Journal des changements et des versions.
- [~] Documentation interne des systèmes, dépendances et formats de sauvegarde.

## ÉTAPE 25 — PERFORMANCE ET CAPACITÉ RÉELLE

- [~] Définir budgets de mémoire, réseau, physique, scripts et sauvegardes.
- [ ] Tester sur un téléphone peu puissant, pas seulement sur PC.
- [ ] Tester un serveur complet avec le nombre maximal de joueurs prévu.
- [ ] Tester serveur complet avec maisons complexes, animaux, PNJ, armées, événements et combats simultanés.
- [ ] Tester plusieurs serveurs actifs sur un même monde persistant.
- [ ] Optimiser le streaming des régions et le chargement initial.
- [ ] Limiter les collisions physiques inutiles.
- [ ] Réduire les détails des modèles éloignés si nécessaire.
- [ ] Simuler les PNJ et animaux éloignés de manière moins coûteuse.
- [ ] Limiter les boucles de calcul et les requêtes de sauvegarde excessives.
- [ ] Tester les grandes parcelles et les constructions très détaillées.
- [~] Tester les mondes très modifiés et les registres remplis.
- [~] Surveiller FPS, mémoire, latence, chargement, erreurs et déconnexions.
- [x] Prévoir une dégradation gracieuse plutôt qu'un blocage serveur.

## ÉTAPE 26 — TESTS COMPLETS ET ÉQUILIBRAGE GLOBAL

### 26A. Matrice de tests
- [ ] Tester chaque bouton, menu, objet, recette, activité, PNJ, lieu, créature, interaction et événement.
- [ ] Tester nouveau joueur, joueur expérimenté et joueur qui revient après une longue absence.
- [ ] Tester joueur solo, petit groupe et serveur complet.
- [ ] Tester ordinateur, mobile et manette.
- [ ] Tester déconnexion pendant chaque action importante.
- [ ] Tester transferts entre mondes et échecs de téléportation.
- [ ] Tester données volumineuses, coffres remplis, courrier important et maisons complexes.
- [ ] Tester plusieurs serveurs modifiant le même monde.
- [ ] Tester permissions, propriétés, clan, banque, échanges et ventes.
- [x] Tester exploitation de failles et requêtes répétées.

### 26B. Équilibrage
- [ ] Mesurer temps d'obtention des ressources communes, rares et légendaires.
- [ ] Comparer revenus de chaque métier et activité.
- [ ] Vérifier que combat, agriculture, artisanat, élevage, exploration et commerce peuvent chacun être viables.
- [ ] Vérifier qu'aucune activité ne rend les autres inutiles.
- [ ] Vérifier qu'un nouveau joueur peut gagner sa vie et trouver sa place.
- [ ] Vérifier qu'un joueur occasionnel ne subit pas de retard punitif.
- [ ] Vérifier que les joueurs riches ont des objectifs et dépenses facultatifs sans plafond arbitraire artificiel.
- [ ] Vérifier qu'aucun clan ne peut monopoliser tous les lieux ou bloquer les autres.
- [ ] Vérifier que les objets rares restent rares mais accessibles.
- [ ] Vérifier que les événements ne créent pas trop de monnaie ou de butin.

### 26C. Tests d'expérience
- [ ] Faire tester le jeu à des personnes qui ne connaissent pas son fonctionnement.
- [ ] Observer si elles savent se déplacer, interagir, récolter, fabriquer, stocker et retrouver leur monde.
- [ ] Vérifier qu'elles découvrent les possibilités sans tutoriel imposé.
- [ ] Vérifier qu'elles ne se sentent pas forcées de combattre, rejoindre un clan ou faire du commerce.
- [ ] Relever les incompréhensions, bugs et systèmes inutiles.
- [ ] Corriger les problèmes bloquants avant d'ajouter encore du contenu.

## ÉTAPE 27 — PUBLICATION ET SUIVI APRÈS SORTIE

### Avant publication
- [ ] Créer une version de production séparée de la version de test.
- [ ] Faire une sauvegarde complète avant migration ou lancement.
- [ ] Vérifier description, icône, miniature, captures, contrôles et règles de jeu.
- [ ] Vérifier que tous les modèles et sons sont autorisés.
- [~] Préparer une publication progressive et un retour arrière. _(retour arrière : `docs/PROCEDURES.md` §1.6 ; publication progressive à organiser)_
- [x] Préparer une procédure de maintenance et d'annonce d'interruption. _(/wa annonce, /wa sauver, /wa ferme — `docs/PROCEDURES.md` §1.5)_
- [ ] Vérifier les systèmes d'aide, signalement et modération.

### Après publication
- [ ] Surveiller erreurs, sauvegardes, transferts, transactions et performances.
- [ ] Surveiller inflation, sources d'or, dépenses, prix et volumes d'échange.
- [ ] Surveiller les fonctionnalités utilisées et les fonctionnalités ignorées.
- [ ] Lire les retours joueurs et les classer par gravité.
- [ ] Corriger d'abord les bugs et problèmes d'équilibre.
- [ ] Publier un journal de mises à jour.
- [ ] Ajouter régulièrement du contenu compatible avec l'univers, sans casser les sauvegardes.
- [~] Refaire les tests de régression après chaque mise à jour importante.

---

# AUDIT FINAL — FONCTIONNALITÉS À COUVRIR AVANT DE DIRE « COMPLET »

Utilise cette liste comme vérification anti-oubli. Chaque ligne doit être soit cochée, soit explicitement marquée « volontairement absent ».

## Joueur
- [ ] Connexion, chargement, création/personnalisation, retour en jeu et déconnexion.
- [ ] Déplacements, caméra, nage, interactions, santé/KO/réapparition selon les règles retenues.
- [ ] Inventaire, équipement, barre rapide, statistiques, compétences, talents, titres et collections.
- [ ] Journal de découvertes, carte, repères et paramètres.

## Monde
- [ ] Génération, biomes, lieux, routes, terrain, eau, ressources, jour/nuit et sauvegarde.
- [ ] Villages, fermes, bâtiments publics, ruines, grottes, donjons, secrets et ports.
- [ ] Météo, saisons, faune, événements et conséquences persistantes.
- [ ] Mondes connus, mondes nouveaux, registre, transferts et réouverture après arrêt.

## Activités
- [ ] Récolte, minage, bûcheronnage, cueillette, pêche et chasse fictive.
- [ ] Agriculture, élevage, dressage, montures et compagnons.
- [ ] Cuisine, forge, menuiserie, maçonnerie, tissage, tannage, poterie et autres métiers retenus.
- [ ] Construction, décoration, réparation, propriété et permissions.
- [ ] Exploration, cartographie, trésors, donjons, boss et collections.
- [ ] Commerce, livraison, gestion de boutique et économie.
- [ ] Activités sociales, mini-jeux serveur déjà présents et événements créés par les joueurs.

## Société et multijoueur
- [ ] PNJ, métiers, routines, dialogues, commerce et réputation.
- [ ] Groupes, clans, courrier, invitations et communication conforme aux règles.
- [ ] Propriétés, locations, copropriété, coffres et droits d'accès.
- [ ] Justice, témoins, primes, protection et prévention du harcèlement.
- [ ] Territoires, avant-postes, armées et politique si retenus.

## Technique et exploitation
- [ ] Sauvegarde, migration, restauration, verrouillage et anti-duplication.
- [ ] Autorité serveur, validation des requêtes et journalisation.
- [ ] Performance mobile, capacité serveur, streaming et tests de charge.
- [ ] Interface mobile/PC/manette, accessibilité, audio et options.
- [ ] Modération, signalement, blocage, administration et assistance.
- [ ] Publication, monitoring, maintenance, retour arrière et mises à jour.

---

# ORDRE DE PRIORITÉ RECOMMANDÉ

1. **D'abord :** audit du code, sauvegardes, sécurité serveur, tests de transactions et téléportation.
2. **Ensuite :** personnage, déplacements, apparition, monde médiéval, génération et ressources.
3. **Puis :** inventaire, catalogue, récoltes, artisanat, compétences et activités de vie.
4. **Puis :** animaux, ennemis, boss, PNJ et villages vivants.
5. **Puis :** construction, propriété, destruction, économie et commerce.
6. **Puis :** navigation, mondes, exploration, météo et événements.
7. **Puis :** social, justice, clans, territoires, armées et politique.
8. **Enfin :** activités de joueurs, interface, audio, modération, administration, performance, tests, publication et suivi.

## Règle de fin de tâche

Une fonctionnalité est considérée comme terminée uniquement si :
1. elle fonctionne en jeu ;
2. ses règles sont compréhensibles ;
3. le serveur valide les actions importantes ;
4. les données sont sauvegardées et récupérables ;
5. elle fonctionne en solo et en multijoueur quand cela s'applique ;
6. elle fonctionne sur les appareils ciblés ;
7. elle ne crée pas d'abus économique ou social connu ;
8. elle a été testée après une déconnexion et une reconnexion ;
9. elle ne casse pas les systèmes déjà présents.

**Principe final :** Wild Acres doit permettre au joueur de choisir sa propre vie dans le monde. Le travail de développement consiste à rendre chaque possibilité cohérente, persistante, équilibrée, sécurisée et compatible avec toutes les autres.
