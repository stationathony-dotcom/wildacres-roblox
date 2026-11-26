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
- [ ] Chaque famille d'arme se joue différemment (`Shared/Armes.lua`) : dague rapide et terrible dans le dos, espadon lent
      qui touche 3 ennemis, lance à 11 studs (et charge à cheval), masse qui écrase les golems, sabre qui fait saigner.
- [ ] Enchaînement : 3 coups rapides → le 3e frappe plus fort.
- [ ] Coup chargé : maintenir le clic puis relâcher (≥ 0,5 s) → second coup plus fort ; à l'arc = tir bandé plus loin.
- [ ] [Z] maintenu = garde (bouclier : presque tout bloqué ; sans bouclier : moitié) ; lever la garde au dernier moment =
      « Paré ! » + riposte ; endurance vide = garde brisée. Ne protège que de face.
- [ ] [Alt] = roulade d'esquive (invulnérable un instant, coûte de l'endurance). Manette : L2 garde, L1 esquive ;
      mobile : boutons 🛡 et 💨.
- [ ] Arcs : arc court rapide, arc long 72 studs (bonus de loin), arbalète lente qui perce l'armure, fronde, armes de jet ;
      tir pleinement bandé sur un humanoïde : parfois « En pleine tête ! ».
- [ ] Maîtrise par famille : message tous les 5 niveaux (+0,5 % de dégâts par niveau).
- [ ] Rênes rares tombent bien (rares !) sur les créatures listées dans `Shared/Ecurie.lua`.

## 4 bis. Équipement façon MMO (docs/EQUIPEMENT-MMO.md)
- [ ] Une pièce ramassée ou achetée peut avoir un complément de nom (« … de célérité ») et une caractéristique en plus.
- [ ] Fiche de la pièce : « durabilité x/y » ; frapper et encaisser l'usent ; brisée = « BRISÉE », stats perdues ;
      « Réparer » chez le forgeron ou l'armurier remet tout à neuf (prix selon l'usure).
- [ ] Torse en plates : plus lent mais plus solide ; en tissu : plus rapide.
- [ ] Spécialisation affichée (attribut `Specialisation`) : bouclier → Gardien, dague → Ombre, arc → Rôdeur, arme lourde → Guerrier.
- [ ] Les nouvelles caractéristiques Critique, Hâte, Maîtrise apparaissent dans la fiche [P] (à habiller par Codex si besoin).

## 5. Store créateur
- [ ] `ServerStorage.StoreImports` : tentes en toile écrue, charrettes. Dire si on les utilise (camps de bandits, foires).

## 6. Ce que Codex livre (après chaque lot de la file)
Pour chaque lot X27 → X39 (voir `docs/CODEX-A-FAIRE.md`) : regarder la planche avant/après dans `captures/`, puis en Play.

## 7. Toujours en attente (anciens points)
- [ ] `docs/TEST-PLAY.md` P1 à P8 (parcours de référence).
- [ ] Icônes peintes : publier les atlas avec ton compte Roblox.
