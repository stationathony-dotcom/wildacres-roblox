# Audit anti-duplication (27/11, Claude — manque n° 13 de MANQUES-MMO)

| Chemin | Verdict | Pourquoi |
|---|---|---|
| Sauvegarde perso (`Save`) | sûr | verrou de session `{job, t}` + numéro `seq` : un autre serveur ne peut ni charger ni écraser un perso ouvert |
| Hôtel des ventes (`Ventes.sell/buy/cancel/bid`) | sûr sur un serveur | contrôle puis retrait sans pause (aucun `yield`) : deux clics simultanés ne peuvent pas acheter la même annonce |
| Monde ↔ perso (annonce achetée puis arrêt brutal) | fenêtre réduite | `Mondes.saveSoon` : perso + monde réécrits ≤ 3 s après. **Corrigé le 27/11** : une 2e opération pendant la pause de 7 s n'était pas suivie d'une nouvelle écriture du monde |
| Courrier (`Poste.collect`) | sûr | crédit et id de colis noté (`mailClaimed`) dans la même sauvegarde ; ids purgés après 30 j seulement s'ils ont disparu de la boîte |

Reste possible (arrêt brutal du serveur entre l'écriture du perso et celle du monde, ≤ 3 s) : rattrapage via `Economie.record`.
