# Montures — plan réadapté (26/11, « entre WoW pour la collection et ARK pour l'élevage »)

Source : conversation ChatGPT du propriétaire (`Downloads\Découvrez cette conversation.html`), « pas obligé de tout garder,
c'est l'idée ». Règle forte du propriétaire : **une monture volante doit être compliquée à avoir ; même quand on l'a, il
faut vraiment farmer** (Équitation, rareté, souffle).

## Déjà en place
Collection + journal [N] + invocation 2 s ; rênes rares sur créatures et boss ; Équitation (monte en chevauchant) ; vol
(Envol : souffle, plané) ; chevaux élevés avec lignées (allure héritée) ; harnachement du sac (selles, étriers, bride,
fers, caparaçon) ; apprivoisement (Compagnons).

## Fait le 26/11 (données seulement, `Shared/Ecurie.lua`)
- Champs par monture : `req` (Équitation requise), `famille`, `biome` (+15 %), `eau` (nage), `places` (passagers), `alt`
  (altitude maximale), `passif` ; paliers : 1 novice, 10 sauvages, 15 rares/aquatiques, 20 surnaturelles, **30 premières
  volantes, 35-45 volantes rares et légendaires**. Équitation : 1 point / 70 studs.
- 12 montures ajoutées sur des créatures existantes : poney, loup des neiges, lézard des tourbières, kelpie, tortue
  caravanière, renard des brumes, colosse de pierre, serpent marin, chouette spectrale, aigle des montagnes, dragonnet,
  rapace des falaises. Œufs de monture (`Ecurie.OEUFS`) très rares dans les nids.

## À coder plus tard (ordre proposé)
1. Appliquer `req` à l'invocation et au vol ; bonus de biome ; plafond d'altitude ; passifs.
2. Montures aquatiques (nage au lieu de descendre de selle dans l'eau).
3. Passagers (places > 1 : « Monter en passager »).
4. Œufs : trouvés dans les nids → incubation 3 jours → monture apprise (Équitation requise pour la monter).
5. Météo et vol : tempêtes et orages épuisent le souffle ; zones interdites au vol (grottes, donjons).
6. Équipement de monture par emplacement (selle, tête, torse, flancs, pattes, accessoire) avec raretés et ensembles.
7. Élevage génétique étendu à toutes les montures (couleurs, taille, vitesse, traits, mutations rares) → métier d'éleveur.
8. Familles manquantes (pégase, dragon, papillon lunaire, cerf céleste, dragon cristallin, mammouth, bœuf, dromadaire,
   hippocampe, raie…) : modèles par Codex. Objectif indicatif ≈ 170 montures.
9. Courses et concours de montures (les concours de dressage existent), réputation, succès, archéologie.

Non retenus : longévité / mort de vieillesse ; capacité de transport (le sac n'a pas de plafond, règle 2).
