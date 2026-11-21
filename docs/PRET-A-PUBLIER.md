# Wild Acres — prêt à publier ? (vérification A → Z du 21/11/2026, PC fixe)

## Vérifié et vert

| Domaine | Résultat |
|---|---|
| Bancs Edit (57 rapides + 6 lourds : génération, châteaux, secteurs, sauvegardes concurrentes, cascades, perf) | **63 / 63 verts** (`mecanismes` sensible à la charge : vert seul) |
| Scripts | 125 scripts identiques entre `src/` et la place ; 858 `Enum` valides (banc `enums`) ; aucun script désactivé |
| Objets | 1 058 objets, 1 309 recettes : 0 échec (banc `objets`) ; 0 objet sans usage ; 232 objets utilisés en Play sans erreur ; 596 recettes et 328 pièces d'équipement fabriquées en Play |
| Parcours de `TEST-PLAY.md` rejoués en Play | P1 (récolte, abattage, minage, vente), P2 (terrain, construction, coffre, serrure, alarme), P3 (K.O. → réveil chez soi), P9 (vol, reddition) : OK |
| Équipement porté | 9 emplacements équipés par `Joueurs.equip` en Play, rendu sur l'avatar sans erreur |
| Visuels | 417 props (banc `visuels_props` vert), 1 037 miniatures d'objets, 703 d'équipement régénérées |
| Règles d'`AGENTS.md` § 1 | vérifiées dans le code (voir `VERIFICATION-SERVEUR.md`) |
| Textes des joueurs vus par d'autres | filtrés par `TextService` : clans, villes, demandes, plans offerts (corrigé le 21/11) ; chat par `TextChatService` |
| Robux, jeux d'argent | aucun (`MarketplaceService` absent) |
| Console en Play | propre (seul avertissement : un préchargement du plugin Rojo, hors jeu) |

## À faire par le propriétaire (impossible depuis Studio par script)

1. **Publier** la place (File → Publish to Roblox) : aujourd'hui `PlaceId = 0`, donc ni téléportation entre mondes,
   ni sauvegardes en ligne.
2. **Game Settings** :
   - Security → *Enable Studio Access to API Services* (sauvegardes) ;
   - Places → *Max Players* = **45** (actuellement **30** : la propriété est en lecture seule pour les scripts) ;
   - questionnaire d'âge / maturité (violence adoucie : on assomme, crimes, voleurs).
3. **Publier les atlas d'icônes peintes** avec son compte (liste dans `images/icones/README.md`) ; en attendant, emojis
   de secours (gérés par `ComposantsInterface`).
4. **Tests réels** : P4 (accueil → voyage → reconnexion, en ligne seulement), P5 à deux comptes, un téléphone, une
   tablette, une manette, puis un serveur chargé (P7 : `/wa perf`).
5. `! git push`.

## Connu, non bloquant

- Miniatures : 49 des familles de Claude restent signalées par le banc de Codex (11 pièces détachées, 38 sous six
  pièces) ; les torses d'équipement se ressemblent encore (silhouettes par type à pousser plus loin).
- `screen_capture` et les animations Edit s'arrêtent si la fenêtre de Studio est réduite.
