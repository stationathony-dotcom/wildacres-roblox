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

## Questions au propriétaire

1. **Groupe de 5 joueurs** (`Social.MAX_GROUP`) : on le garde, ou on l'ouvre (règle 2) ?
2. **Paliers hauts des métiers** pêche, élevage, bûcheronnage, commerce : à ajouter (recettes ≥ 30) ?
3. **Créatures de niveau 7 et 9** rapportent 3 à 6 fois la médiane d'or par minute : voulu (risque élevé) ou à baisser ?
