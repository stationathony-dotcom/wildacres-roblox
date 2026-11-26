# Codex — tout ce qu'il reste à faire (feuille autonome, 26/11)

À envoyer tel quel à Codex si Claude n'est plus disponible. Codex : lis d'abord `AGENTS.md`, `docs/LOTS.md`,
`docs/DIRECTION-ARTISTIQUE.md` § 3 (méthode « niveau planche » de ton mammouth gagnant, `tools/concours/sol_mammouth.luau`).

## Réglages
- Modèle : `gpt-6.2-sol`, effort **`high`** (jamais `ultra` : il épuise la limite d'usage en 3 lancements).
- Gros lots : un lancement = un lot entier (moins coûteux que plusieurs petits).
- Lancement automatique de toute la file (reprend seul après une limite d'usage) :
  `bash tools/codex/file_sol.sh` (journal : `tools/codex/journal.txt` ; un lot fini = `tools/codex/<lot>.fait`).

## La file (un prompt complet par lot dans `docs/codex-lots/`)

| Ordre | Lot | Contenu | Fichiers principaux |
|---|---|---|---|
| 1 | X27 | Les 58 props au niveau planche (coffres, ateliers, mobilier, village, nature, construction) | `ServerStorage/OutilsDev/ConstruireModeles.lua` |
| 2 | X32 | Armes et équipement portés (constructeurs par forme + accents par matière, rareté lisible) | `Shared/Gear.lua`, `GearDesign.lua`, `Systemes/Avatar.lua`, `Tools.lua` |
| 3 | X33 | Objets du sac (≈ 1 000 miniatures par familles, lisibles à 48 px) | `OutilsDev/ConstruireModelesMiniatures.lua` |
| 4 | X34 | Maisons et bâtiments (colombages, chaume, variantes, château, moulin) | `ConstruireModeles.lua` (maison, villages2…) |
| 5 | X35 | PNJ : tenue PROCÉDURALE par PNJ (aucun marchand identique) + dialogues enrichis | `Systemes/Avatar.lua`, `Shared/Apparence.lua`, `Shared/Dialogue.lua` |
| 6 | X36 | Créatures du bestiaire (168) + 6 boss inspirés des planches | `Systemes/Silhouettes.lua` |
| 7 | X37 | Écriture et peaufinage des quêtes (texte seulement) | `Systemes/Quetes.lua`, `QuetesLieux.lua` |
| 8 | X38 | Habillage du journal des montures, beau bestiaire, animations des montures en selle | `Montures.client.lua`, `Livre.client.lua`, `Livres.lua` |
| 9 | X39 | Animations de combat du personnage (anticipation / frappe / suite, enchaînements, réactions, traînées) | `Gestes.client.lua` |

Lots encore ouverts dans `docs/LOTS.md` sans prompt dédié : **X28** ambiance fine (Eclairage : Future, Bloom ; Claude
a déjà fait les profils par biome et les tempêtes dans `Ambiance.client.lua`), **X30** suite du Store (choisir quoi
utiliser dans `ServerStorage.StoreImports`, voir `docs/STORE.md`), **X31** menus E4–E6.

## Ce qui compte comme « fait » (tous les lots)
1. Méthode § 3 : masses qui se chevauchent, réglages à la main avec petites asymétries, 3 étages de ton, légères
   inclinaisons, matière de surface continue puis déchirée. Au moins 3 détails nouveaux lisibles à distance.
   Interdits : seulement des couleurs, seulement des rivets, faces en aplat.
2. Tout ce que le serveur lit reste inchangé (noms, ids, attributs, attaches, emprises) : grep avant de renommer.
3. Commits petits, `git add` fichier par fichier, préfixe `[Codex]`, en français ; pas de `.rbxl` ; pas de push.
4. Rapport `docs/X<lot>-RAPPORT.md` (avant / après / détails) ; cocher le lot dans `docs/LOTS.md` ; une ligne au
   `CHANGELOG.md`.

## Si Claude n'est plus là : ce que Claude faisait et que tu dois faire
- **Intégrer dans Studio** : `python tools/sync.py` en arrière-plan, puis dans Studio (MCP roblox-studio,
  `execute_luau` en Edit) le banc `tools/bancs/pousser.luau` (remplacer `127.0.0.1` par `localhost` dans l'URL).
- **Reconstruire** les modèles en Édition (`require(game.ServerStorage.OutilsDev.ConstruireModeles).propsValdor()`,
  etc. — les appels exacts sont à la fin de chaque rapport).
- **Capturer** chaque lot dans Studio (`screen_capture`) : avant / après, rangé dans `captures/<date>/<lot>/`, et le
  citer dans le commit. Règle du propriétaire : **tout lot visuel est livré avec une capture Studio**.
- **Bancs** : `tools/bancs/tout.luau` (61 bancs) doit rester vert ; `creatures_voxel` pour X36, `visuels_*` pour les props.
- **Fin de session** : enregistrer la place (`save_place`), commit « Place : synchronise avec src ».
- PC portable : pas de Play, découper les gros `execute_luau`, lancer les bancs lourds en `task.spawn`.

## Règles du jeu à ne jamais casser (extrait d'AGENTS.md § 1)
Sans indication (pas de tutoriel, quêtes seulement sur place) · pas de plafond arbitraire · monde libre (des outils
plutôt que des interdits) · pas de niveau de personnage · grind · tout est ramassable · rien sans usage ·
construction libre · créatures originales (pas de zombies/squelettes) · pas de saisons, survie, casino, Robux ·
HUD aux proportions de l'image cible.
