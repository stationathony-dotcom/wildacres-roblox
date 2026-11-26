# Ce que le propriétaire doit vérifier (en Play, PC fixe) — mis à jour le 26/11

Tout ce qui suit est **codé, poussé dans Studio et vérifié par bancs ou captures en mode Édition**, mais **jamais joué
en Play** (PC portable). Coche au fur et à mesure ; note les bugs dans `retours.txt` (racine du dépôt) avec la ligne.

## 0. Avant de commencer
- [ ] `git pull` sur le PC fixe, PUIS ouvrir `wildacres.rbxl` (jamais l'inverse : Studio ouvert avant le pull
      réenregistre l'ancienne place par-dessus la nouvelle).
- [ ] Dans Studio, banc complet : servir le dépôt (`python tools/sync.py`) puis `tools/bancs/tout.luau` → 61 bancs verts.
- [ ] Créer un **NOUVEAU monde** (gen 3). Les mondes déjà créés gardent l'ancien relief (gen 2).

## 1. Relief, monde, ambiance
- [ ] Depuis une plage : on voit le **sommet enneigé** au loin (≈ 160 studs).
- [ ] Monter au sommet à pied : routes en cols, terrasses franchissables par les escaliers, alpage puis roche puis neige.
- [ ] Une **cascade haute** (jusqu'à 130 studs) dans une gorge : nappe large, brume au pied, eau qui ruisselle ;
      « Remplir le seau » au bassin.
- [ ] Les villages restent de plain-pied et joignables à pied.
- [ ] Vue aérienne (en vol) : arbres au loin (feuillus + conifères), pas de pavés orange, côtes biseautées.
- [ ] Passer d'un biome à l'autre : la lumière change en fondu (forêt dorée, désert chaud, neige froide, marais vert).
- [ ] Tempêtes : `DbgAppel` « Meteo.storm », « desert », 300 (puis « neige », « marais », « foret ») → sable
      poussé par le vent / blizzard / brume / bourrasques ; on voit encore à 60-100 studs ; vent plus fort.
- [ ] Performance : FPS en survolant le massif ; temps de chargement d'une région de montagne (`/wa perf`).

## 2. Montures façon WoW
- [ ] [N] ou bouton 🏇 : journal des montures (aperçu 3D qui tourne, « ??? » pour les inconnues).
- [ ] Acheter un cheval à une ferme → il entre dans le journal ; « Invoquer » : barre de 2 s, interrompue si on bouge
      ou si on est frappé ; [X] pour descendre → la monture repart.
- [ ] « Au hasard » et Favori ★.
- [ ] Rênes rares : se donner `renes_loup_noir` (admin) → l'utiliser → monture apprise ; déjà connue → rênes rendues.
- [ ] Équitation : monte en chevauchant (1 point / 40 studs) ; message au niveau 25.
- [ ] Vol : Équitation 25 (admin), invoquer « Griffon » ou apprivoiser un hippogriffe affaibli puis « Monter (voler) » ;
      caméra = direction, Espace monte, Ctrl descend, ▲▼ sur mobile ; souffle qui s'use, plané à bout de souffle.
- [ ] Mobile : boutons ▲▼ bien placés, journal utilisable au doigt.

## 3. Marchands et économie
- [ ] Dans un village : **aubergiste, fournisseur, alchimiste, armurier** présents, sans se chevaucher avec les autres.
- [ ] Leur étal se remplit avec ce qu'on leur vend (ex. lingots à l'armurier → pièces d'équipement le lendemain).
- [ ] Armurier : acheter une pièce de base (elle va dans l'équipement), une **pièce unique du jour** (★), réparer.
- [ ] Palefrenier : selle, bride, étriers, fers en vente.
- [ ] Vérifier que la fenêtre de boutique affiche bien les pièces d'équipement (nom, icône, prix) sans erreur.

## 4. Combat et créatures
- [ ] Contours : boss et élites proches cernés de sombre, créature sous le curseur en doré.
- [ ] Rênes rares tombent bien (rares !) sur les créatures listées dans `Shared/Ecurie.lua`.

## 5. Store créateur
- [ ] `ServerStorage.StoreImports` : tentes en toile écrue, charrettes. Dire si on les utilise (camps de bandits, foires).

## 6. Ce que Codex livre (après chaque lot de la file)
Pour chaque lot X27 → X39 (voir `docs/CODEX-A-FAIRE.md`) : regarder la planche avant/après dans `captures/`, puis en Play.

## 7. Toujours en attente (anciens points)
- [ ] `docs/TEST-PLAY.md` P1 à P8 (parcours de référence).
- [ ] Icônes peintes : publier les atlas avec ton compte Roblox.
