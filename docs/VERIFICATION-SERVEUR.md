# Vérification des documents — couloir Claude (serveur, règles, monde)

21/11/2026 au soir, PC fixe. Chaque document relu et confronté au code, aux bancs Edit (55 verts) et à un Play
(régression 15/15, 25 régions traversées sans erreur de console). Le couloir Codex (interface, visuels) est dans
`docs/VERIFICATION-INTERFACE.md`.

**Bilan : 14 écarts trouvés, 14 corrigés, 3 points laissés en question au propriétaire.**

## Règles d'`AGENTS.md` § 1, vérifiées dans le code

| Règle | État | Preuve / correction |
|---|---|---|
| 1 · Sans indication, pas d'annonce à tout le serveur | **corrigé** | `Game.lua` annonçait chaque arrivée à tout le serveur → amis et clan seulement (f1a5888). `Law.bodyFound` envoyait la nouvelle d'un PNJ assommé à tout le serveur → 300 studs autour (3c260c2). Aucun `Util.toast(nil, …)`. |
| 2 · Pas de plafond arbitraire | OK + question | Bêtes : place des abris (`Animals.capacity`). Restent des limites techniques (repères 200, colis 400, butins au sol 400). **Question** : groupe de 5 (`Social.MAX_GROUP`), décidé avant la règle. |
| 3 · Monde libre | OK | `Config.LIBRE` : tout ouvert sauf parcelle dans un village (exception écrite). |
| 4 · Pas de niveau, déblocages par `skillRaw` | **corrigé** | Poissons rares (`Fishing.lua:39`) et recettes des livres (`Joueurs.lua:867`) lisaient `skill` (bonus d'équipement compris) → `skillRaw` (c338828). Recettes : `needSkill` lit déjà `skillRaw`. |
| 5 · Grind | OK | Résistances, outils requis, paliers pierre → acier (`axe_steel`, `pickaxe_steel`). |
| 6 · Tout est ramassable | **corrigé** | En Play : 72 roseaux et 30 nénuphars par région d'eau sans tag `Recoltable`. `Moissons` lit maintenant le dossier `Decor` (376887a, banc `moissons` 26/26). Caisses, tonneaux, puits, ponts : équipements de village, cassables (`Demolir`), pas du décor naturel. |
| 7 · Rien sans usage | OK | Banc `equilibre` : 0 objet sans usage sur 1 052. |
| 8 · Construction libre | OK | Anciennes pièces toutes faites (`wall*`, `stairs`, `floor2`) sans source, gardées pour les vieilles sauvegardes (`AUDIT.md`). |
| 9 · Créatures originales | **corrigé** | « Squelette errant / ancien » (squelettes classiques à l'épée) → **gisants**, statues de tombeau en pierre (8bc2133). Ids gardés. Les modèles « Squelette » / « Zombie » de `ConstruireModeles` ne sont utilisés nulle part. |
| 10 · Volontairement absents | **corrigé** | « Jeu de dés » → osselets (bc6b7b0). Pas de saisons, de froid, de chaleur, de qualité, de signature, de casino ni de Robux dans le code. |

## Bug trouvé en relisant

- **`Law.bodyFound`** : dès qu'un suspect était vu près d'un PNJ assommé retrouvé, **tous** les joueurs connectés
  prenaient 3 étoiles, −20 d'honneur et un shérif aux trousses. Seul le joueur vu est désormais visé (3c260c2).
- **Achat d'animaux** (plus tôt dans la soirée) : `n` bêtes payées pour une seule reçue (fef3c87).
- **Écran d'apparence** (relevé en Play, couloir Codex) : corrigé par Codex (54069dc).

## Documents

| Document | État | Détail |
|---|---|---|
| `FEUILLE_DE_ROUTE.md` | **corrigé** | Harpon coché (fait le 20/11). Bouclier d'arrivée, qualité de façon, froid / chaleur annotés « retirés » (e625041). |
| `Wild_Acres_plan_step_by_step_complet.md` | **corrigé** | Saisons et effets saisonniers, météo « neige / gel / sécheresse » cochés alors que retirés → annotés (4c07101). |
| `AUDIT.md` | **corrigé** | `Animals.OWN_CAP` et `Terraforme.allowed` n'existent plus → annotés. Toutes les autres références `Module.fonction` des docs existent. |
| `docs/TEST-PLAY.md` | **corrigé** | P6 demandait de tester le froid et la chaleur (retirés) → boue et obscurité (6492186). |
| `docs/INVENTAIRE-MISSIONS.md` | **corrigé** | 32 correspondances fausses du rapprochement automatique (« Sanglier → Sangle », « Gobelin des bois → Gobelet en bois », « Établi → Étable », « Chèvre → Chevron de toit »…). Manquaient vraiment : caillebotis, partition, chèvre, ajoutés (fc132a0, ad75683). |
| `docs/MISSIONS.md` | archivé | Suivi du 19/11 périmé, renvoie à l'inventaire et aux lots. |
| `docs/REFERENCE.md` | régénéré | 1 052 objets, 1 296 recettes. |
| `README.md`, `docs/PROCEDURES.md` | OK | Les 23 sous-commandes `/wa` et `/signaler` existent ; `DevSeed` 4242 lu par `Mondes`. Toutes les commandes `/…` citées dans les docs existent. |
| `docs/AUDIT-CRAFT.md` | OK + reste | Outils en acier, gravier utilisé, 19 recettes d'alambic. **Reste** : aucun palier haut (≥ 30) en pêche, élevage, bûcheronnage, commerce. |
| `docs/EQUILIBRE-ECONOMIE.md` | OK | Alertes du banc (`créatures niveau 7 et 9` TROP, souche / cactus à mains nues faibles) déjà notées. |
| `docs/PERFORMANCE.md` | OK | Mesures Play à faire (P7). |

## Questions au propriétaire — tranchées le 21/11 (« fais ce qui te semble logique »)

- Groupe : limite de 5 retirée (règle 2), borne technique = 40 (capacité d'un monde).
- Paliers hauts : plateau du maître pêcheur (pêche 32), fromage truffé (élevage 35), bois de cœur + arc et brigandine
  (bûcheronnage 35), lettre de franchise (commerce 30, rend de la réputation au village).
- Créatures de niveau 7 et 9 : gain gardé (risque), noté dans `EQUILIBRE-ECONOMIE.md`.

Questions d'origine :

1. **Groupe de 5 joueurs** (`Social.MAX_GROUP`) : on le garde, ou on l'ouvre (règle 2) ?
2. **Paliers hauts des métiers** pêche, élevage, bûcheronnage, commerce : à ajouter (recettes ≥ 30) ?
3. **Créatures de niveau 7 et 9** rapportent 3 à 6 fois la médiane d'or par minute : voulu (risque élevé) ou à baisser ?

## Objets — vérification complète (21/11, suite)

| Contrôle | Résultat |
|---|---|
| Banc `objets` (Edit) : nom, icône affichable, prix, provenance, recettes, doublons | 1 058 objets, 1 309 recettes : **0 échec**. 5 noms en double renommés (Barque d'ornement, Bannière d'avant-poste, Ramure de trophée, Dard de scorpion acéré, Gelée de slime épaisse). Sans provenance, voulu : 9 anciennes pièces `wall*` / `floor2` / `stairs`. |
| Play : chaque objet utilisable donné puis utilisé (`Joueurs.eat`) | **232 / 232 sans erreur**, console propre. |
| Play : chaque recette d'objet aux 6 ateliers (juste assez → fabriqué, un de moins → refus) | **596 fabriquées juste, 84 refus de compétence corrects, 0 échec**. Le banc `recettes` lisait `skill` au lieu de `skillRaw` (faux échec du caparaçon) : corrigé. |
| Play : chaque pièce d'équipement fabricable | **328 fabriquées juste, 0 échec** ; 299 au-delà du niveau du perso de test (non fabriquées pour ne pas toucher sa sauvegarde). |
| Allure des props (Codex, banc `visuels_props`) | 417 props, 105 signalements → `docs/RAPPORT-BANC-PROPS.md`, tri et corrections en cours (phase 2). |

## Parcours de `TEST-PLAY.md` rejoués par script en Play (21/11, PC fixe)

| Parcours | Résultat |
|---|---|
| P1.2 ramasser à la main | OK (caillou cliqué, butin au sol ramassé) |
| P1.4 abattre / miner | OK : bouleau en 7 coups → 3 bûches ; rocher → +3 pierres. Filon de fer : aucun à portée du point de test (non vu). |
| P1.5 vendre / acheter au marchand | OK : 5 rondins vendus 20 or, corde achetée 4 or. Après un vol dans le village, l'autre marchand ferme boutique (voulu). |
| P2.1 panneau de propriété | OK : 1er terrain gratuit, créé. |
| P2.2 construire | OK : 2 murs posés, le même mur au même endroit refusé ; reprise autour de soi → matériaux rendus (voulu). |
| P2.3 coffre, serrure, alarme | OK : coffre posé et verrouillé (`Verrouille`), alarme posée. |
| P3.4 K.O. | OK : réveil chez soi en 10,5 s (à 701 studs du lieu du K.O.), −15 % d'or (200 → 170), sac intact. |
| P9.1 vol devant témoin, reddition | OK : 0 → 1 étoile ; « Je me rends » au shérif → 0 étoile. |
| Reste au propriétaire | Ressenti (lisibilité, sans tutoriel), P4 en ligne, P5 à deux joueurs, mobile, 40 joueurs. |
