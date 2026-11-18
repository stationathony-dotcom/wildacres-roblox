# Wild Acres — Roblox

Portage Roblox du jeu Godot `Documents\wildacres` : mêmes principes (ferme + liberté, monde généré
par graine, PNJ vivants, honneur/shérif), rendu 3D Roblox, violence adoucie (on assomme, il faut
cacher le corps).

## Contenu

- `wildacres.rbxl` : la place complète (scripts + modèles 3D de `ServerStorage.Modeles` / `Outils`).
  C'est elle qu'on ouvre dans Studio.
- `src/` : copie texte de tous les scripts (lisible dans git, une ligne = un diff).
  - `ReplicatedStorage/Shared` : Config, Dialogue, Gear, WorldGen (graine → régions), RegionPlan.
  - `ServerScriptService/Main.server.lua` + `Systemes/*` : monde, PNJ, ferme, loi, combat, etc.
  - `ServerStorage/OutilsDev/ConstruireModeles` : reconstruit les modèles 3D (outil de dev).
- `tools/sync.py` : pont Studio ↔ `src/` (Rojo bloqué). `default.project.json` : prêt pour Rojo si besoin.

## Multi (façon MMO + Minecraft)

- **Accueil** (serveurs publics) : liste des mondes avec le nombre de joueurs, bouton Jouer.
  Un nouveau monde s'ouvre tout seul quand tous sont remplis à 80 % (`Config.WORLD_CAPACITY`).
- **Monde** = graine + sauvegarde, sur un serveur Roblox réservé. Île finie de 27 x 27 régions,
  5 biomes (prairie, forêt rousse, désert, toundra, marais), chacun avec ses cultures.
- **Perso** commun à tous les mondes : sac, or, équipement, honneur, cheval (qui suit d'un monde à l'autre).
- Voler un autre joueur (récolte, bête, cheval, objet posé) est un crime, comme voler un PNJ.
- Dans Studio : pas d'accueil, on arrive directement dans le « Monde de test » (graine `DevSeed`
  sur Workspace, 4242 par défaut), sauvegardes en mémoire (attribut `StudioDataStore` pour tester les vraies).

### Check-list premier test (PC fixe)

1. Studio : ouvrir `wildacres.rbxl` → **Play** : on arrive dans le monde de test (interface, sac [B],
   atelier [C], biomes affichés en haut).
2. **File > Publish to Roblox** (crée le jeu). Puis **Game Settings** :
   - Security : *Enable Studio Access to API Services* (sauvegardes) ;
   - Places > la place > *Max Players* = 45.
3. Lancer le jeu publié depuis roblox.com : écran d'accueil → **Jouer** → téléportation dans un monde.
   (La téléportation et la liste des mondes ne marchent PAS dans Studio, seulement en ligne.)
4. Avec un 2e compte ou un ami : vérifier qu'on se voit, qu'on peut se voler une récolte (étoiles),
   et que le sommeil saute la nuit seulement quand les deux dorment.

## Sur un autre PC

```
git clone <url> "wildacres roblox"
```
puis ouvrir `wildacres.rbxl` dans Studio. Si `src/` est plus récent que la place, lancer
`python tools/sync.py` et réimporter les scripts depuis Studio.
