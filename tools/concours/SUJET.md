# Concours de design de créature — 26/11

Demande du propriétaire : Claude et Codex conçoivent chacun **une** créature, sur le même sujet ; les deux sont
construites côte à côte dans Studio et capturées sous le même angle ; le propriétaire choisit le meilleur design.

## Sujet

**Mammouth de givre** — boss de la toundra (biome neige). Référence de style : `images/references-26-11/planche-02.jpg`
(et l'esprit général des autres planches). Inspiration de style seulement : pas de copie pièce à pièce du dessin.

Ce qu'on attend (relevé sur les planches) :
- silhouette reconnaissable de loin : dos massif en bosse, tête basse, trompe, deux grandes défenses courbes ;
- « voxel » : masses en blocs empilés, gradins, mèches de fourrure en blocs qui pendent ;
- 4 à 6 couleurs + 1 lueur : fourrure brun foncé / moyen / clair, os des défenses, givre bleu pâle, cristaux de glace
  et yeux en lueur cyan (`Enum.Material.Neon`) ;
- détails « signature » : cristaux de glace sur le dos, givre sur les défenses et les pattes, ongles des pieds ;
- 2 tons au moins par matière, jamais un aplat.

## Contraintes techniques (identiques pour les deux)

- Fichier : `tools/concours/<auteur>_mammouth.luau` (`claude_`, `codex_` = gpt-6.2-astra, `sol_` = gpt-6.2-sol).
- Le fichier est un chunk Luau qui **retourne une fonction** `function(parent: Instance, origin: CFrame): Model`.
- Uniquement des `Part` / `WedgePart` / `CornerWedgePart` (formes Block, Ball, Cylinder) ; pas de MeshPart, pas de
  texture, pas d'asset externe, pas de script, pas de `require`, pas de service autre que ce qui est global (`Instance`,
  `Vector3`, `CFrame`, `Color3`, `Enum`, `math`, `Random`).
- Toutes les pièces `Anchored = true`, `CanCollide = false`. Une pièce nommée `Base` au sol.
- Repère : sol à y = 0 dans `origin`, la créature regarde vers −Z de `origin`.
- Taille : 16 à 22 studs de haut (un avatar fait ~5 studs).
- Budget : **320 pièces au maximum**.
- Le modèle s'appelle `Mammouth_<auteur>` et a `PrimaryPart = Base`.
