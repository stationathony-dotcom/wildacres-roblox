# Props gratuits du Store créateur (lot X30)

Règle du propriétaire (26/11) : « télécharger des props gratuits du Store créateur si ça a du sens, en faisant attention
aux scripts ». Procédure : insertion en **quarantaine** (`ServerStorage.Quarantaine`), audit des scripts (aucun
`require(id)`, `getfenv`, `loadstring`, `HttpService`, `\x..`, `string.char`…), suppression de TOUS les scripts et
relais (RemoteEvent, *Value), puis rangement dans `ServerStorage.StoreImports` (jamais dans le Workspace). Banc
équivalent pour un id : `tools/bancs/store_import.luau`. Rien n'est utilisé en jeu sans l'accord du propriétaire.

| Paquet | Id | Auteur | Contenu | Scripts | Avis |
|---|---|---|---|---|---|
| Asset Pack Medieval | 121230482146932 | AFK Works | 30 maillages : tentes, charrettes, roue, puits, tombes, bannières, barque, lanterne, caisse, clôtures, tas de pierres | 0 | Propre, low-poly lisse. Avis du propriétaire (26/11) : tentes « cirque » → recolorées en toile écrue unie (texture rayée retirée), bannières en cuir ; charrettes « ok ». Capture `captures/2026-11-26/store/tentes-toile.jpg`. |
| Low Poly Prop Pack | 6905386946 | HanzRBX | 32 maillages divers | 0 | Petits objets, style lisse ; tri à faire. |
| Weapon Display | 124985445833504 | cube3D | présentoir d'armes stylisé | 3 (sans code suspect, retirés) | Utile pour forge / armurerie. |

Capture de la vitrine : `captures/2026-11-26/store/vitrine.jpg` (dossier hors git).

Limite : ces maillages sont en **low-poly lisse**, pas en « voxel briques » comme les planches de référence. À mélanger
avec parcimonie (décors de camps), ou à refaire dans nos constructeurs.
