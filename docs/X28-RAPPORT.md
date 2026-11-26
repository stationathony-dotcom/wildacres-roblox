# X28 — Éclairage et ambiance

Le voile de beau temps part d’une densité de 0,15 et d’un `Haze` de 0,17 en prairie, contre 0,20 et 0,35 auparavant. Le crépuscule réchauffe le bord du ciel. La nuit, l’horizon et les ombres prennent des tons bleus. Le halo est resserré pour garder les contours des fenêtres et des lanternes lumineuses.

Le désert tire vers l’ocre, la neige vers le bleu clair et le marais vers l’olive. La grotte prend une teinte froide et plus sombre dès la descente, même avec une lampe. Les tempêtes régionales gardent leurs couleurs et leurs particules. Le profil Graphismes « Économie » et le profil standard sur mobile tactile réduisent les particules et coupent les halos et rayons du soleil. Le profil « Détaillé » rétablit les effets.

## Captures Studio en Édition

| Heure | Avant | Après |
| --- | --- | --- |
| 9 h | [Matin](../captures/2026-11-26/X28/avant-9h.jpg) | [Matin](../captures/2026-11-26/X28/apres-9h.jpg) |
| 13 h | [Midi](../captures/2026-11-26/X28/avant-13h.jpg) | [Midi](../captures/2026-11-26/X28/apres-13h.jpg) |
| 19 h | [Crépuscule](../captures/2026-11-26/X28/avant-19h.jpg) | [Crépuscule](../captures/2026-11-26/X28/apres-19h.jpg) |
| 23 h | [Nuit](../captures/2026-11-26/X28/avant-23h.jpg) | [Nuit](../captures/2026-11-26/X28/apres-23h.jpg) |

Les huit captures prennent la même vue de la taverne, du puits et de la place. Elles utilisent le profil clair de la prairie et la bascule des lanternes de `Clock`. `Eclairage.lua` et `Ambiance.client.lua` compilent et sont synchronisés dans Studio. Le profil mobile et les transitions en mouvement restent à vérifier en Play sur le PC fixe et sur téléphone.

La place garde son style d’éclairage `Soft` en Édition. Une mesure sur téléphone reste nécessaire pour décider du passage au style `Realistic` de Roblox. [Éclairage global — Roblox Creator Hub](https://create.roblox.com/docs/environment/lighting)

Pour recalculer les réglages en Édition, appeler `require(game.ReplicatedStorage.Shared.Eclairage).apply(game.Lighting, workspace.Terrain)` après synchronisation.
