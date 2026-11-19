# Wild Acres — audit du catalogue de fabrication (game design)

19/11/2026. Chiffres tirés des données du jeu (`Config` + `Catalogue`, chargés dans Studio) : 857 objets de base, 731 recettes.
Ce document parle de **règles et d'équilibre**. L'aspect visuel des objets est dans `AUDIT-VISUELS-OBJETS.md`.

## Ce qui ne va pas

### 1. La nourriture ne fait qu'une seule chose
Les 95 aliments ont tous le même effet : rendre de la vie. Il n'y a ni faim ni effet de repas.
Cuisiner ne nourrit même pas mieux : **14 plats soignent moins que leurs ingrédients mangés crus**.

| Plat | Vie du plat | Vie des ingrédients crus |
|---|---|---|
| Ragoût du désert | 55 | 61 |
| Tarte à la citrouille | 60 | 67 |
| Beurre | 12 | 30 |
| Jus de baies | 10 | 32 |
| Bière d'orge | 18 | 32 |

La cuisine ne sert donc qu'à revendre plus cher.

### 2. Fabriquer fait souvent perdre de l'or, parfois en fait trop gagner
Sur 358 recettes dont on connaît tous les prix :
- **50 produisent moins de 80 % de la valeur de leurs ingrédients.** Exemples : paille (3 or pour un blé à 20), huile (14 pour 78), sucre (12 pour 60), barre de fer (30 pour 2 lingots à 90), chaîne (24 pour 90), bière (50 pour 126). Vendre la matière brute rapporte plus que la travailler.
- **L'eau détruit un seau et un gobelet** (24 or d'objets) pour faire 2 eaux à 2 or. C'est un bug de recette : le seau et le gobelet devraient rester.
- À l'inverse, **17 recettes multiplient la valeur par plus de 4** : appâts ×12, figurine en pierre ×7,5 (4 pierres → 60 or, sans établi, artisanat 6), figurine en bois, flûte, luth, outils ×5 à ×6. La figurine en pierre est un moyen trop facile de gagner de l'or.

### 3. Beaucoup de recettes sont des copies
107 recettes ont exactement les mêmes ingrédients qu'une autre. Pour les pièces de construction, c'est normal : une même matière donne plusieurs formes. Mais une trentaine d'objets n'ont aucune identité :
- charnière = hameçon = anneau de fer = ferrure = clous (1 lingot de fer → 3) ;
- assiette = bol = chope = pot ;
- chope en métal = crochet de serrure ;
- pique = faux, épée courte = marteau de forgeron ;
- contrat = diplôme = lettre de recommandation = contrat de recrue ;
- chaise = tabouret = cerceau.

### 4. Les matières ramassées ne servent presque à rien
**216 des 284 matières brutes n'entrent que dans une seule recette.** *Correction après vérification : environ 180 d'entre elles sont des prises de créatures et des âmes de boss, faites exprès pour une seule pièce. Le vrai problème se limite à une trentaine de matières courantes (silex, corne, bois de cerf, menthe, thym, gravier…).*
Ailleurs, deux matières bloquent tout : la **corde** entre dans 95 des 251 pièces d'équipement, le **cuir** dans 81 recettes.

### 5. La progression s'arrête à mi-chemin
- La compétence monte jusqu'à 50, mais **seules 12 recettes demandent artisanat 30 ou plus**. L'équipement le plus rare se débloque en moyenne vers le niveau 22–25. De 30 à 50, on ne débloque rien de nouveau, seulement plus de chances de chef-d'œuvre.
- **358 recettes sur 731 n'ont aucun niveau requis.**
- Les autres métiers ne débloquent presque rien : pêche 2 recettes, commerce 5, élevage 6. Minage et bûcheronnage : 0.
- Les outils s'arrêtent au fer (3 paliers : pierre, cuivre, fer). Pourtant l'acier existe et sert dans 19 recettes : il n'y a ni hache ni pioche en acier. Ça va contre « filons façon WoW, grind = mot d'ordre ».

### 6. L'équipement est déséquilibré
- Passer de la rareté 3 à 4 coûte environ **4 fois plus cher** (≈300 → ≈1 200 or) pour **+1,6 de stat seulement**.
- **Breloques : 89 pièces (35 %)**, alors qu'il n'y a que 2 chapeaux de rareté 3.
- La Force apparaît dans 123 pièces, la Discrétion dans 37 seulement : la voie Hors-la-loi est mal servie.
- Arc court : 3 de stat pour 17 or, au niveau 4. C'est le meilleur rapport du jeu, et de loin.

### 7. Petits trous
- L'alambic n'a que 8 recettes alors que l'Alchimie a son propre onglet.
- Le gravier ne sert à rien : aucune recette, aucun système.

## Fait le 19/11 (`Shared/Equilibre.lua`)

Points 1 à 4 corrigés en partie : effets de repas, prix plancher, 29 recettes copiées, eau, figurines, arcs, métiers requis. Restent : poterie (pot, assiette, bol, chope) et actes écrits (contrat, recommandation), laissés exprès car c'est la même matière en plusieurs formes. Outils en acier et en diamant : faits par Codex le même jour. Rareté 4 trop chère et breloques trop nombreuses : pas encore touchés.

**Suite le 19/11** : plancher de stats par rareté (3 → 8, 4 → 12), Discrétion sur les pièces furtives, 6 pièces de maître (artisanat 40 à 50). **Note pour Codex** : les séries de `GearDesign.lua` (Soleil rouge, Ambre royal…) sont ajoutées après `Equilibre` et ne passent donc pas par ce plancher : 117 pièces de rareté 3 ou 4 y sont en dessous (6 et 8 de stats au total). Soit les relever dans `GearDesign`, soit appeler l'équilibre après elles.

**Objets sans usage (19/11)** : 122 objets sur 928 ne servaient qu'à la revente (ni nourriture, ni outil, ni pose, ni équipement, ni recette menant à quelque chose d'utile, ni système). Tous ont reçu une fonction (`Equilibre` : E.USES, E.WEAR, E.EXTRA, E.ADD, E.JEWELS). Contrôle refait : 0 restant. Règle pour la suite : **tout nouvel objet doit avoir un usage** ; relancer ce contrôle avant d'en ajouter.

## Ce qui mérite d'être ajouté (par ordre de rendement)

1. **Effets de repas.** Chaque plat donne un bonus de quelques minutes, différent selon le plat (ragoût : Force, poisson grillé : Endurance, tarte : Vie, tisane : Chance…). Règle : un plat nourrit toujours plus que ses ingrédients crus. Le moteur existe déjà (`Joueurs.addBuff`). Rendre la cuisine utile serait le plus gros gain.
2. **Réparer les prix et les recettes cassées.** Un objet fabriqué vaut au moins 1,1 fois ses ingrédients. L'eau garde le seau et le gobelet. La figurine passe à l'établi et demande plus de pierre.
3. **Donner une identité aux recettes copiées** en y mettant les matières qui ne servent qu'une fois. Exemple : un hameçon en fer avec une plume, une charnière en fer avec de la graisse. On corrige ainsi les points 3 et 4 en même temps.
4. **En partie fait le 19/11** (festins, fromage affiné, acier damassé, planches fines, équipement de métier). **Paliers hauts (30–50) dans chaque métier.** Outils en acier (palier 4), pièces de maître, et des recettes réservées à chaque métier : fonte de l'acier (minage), planches fines (bûcheronnage), filets (pêche), fromages affinés (élevage).
5. **Commandes de fabrication entre joueurs** (idee.txt : « contrats de fabrication »). Un joueur affiche au tableau « je veux X, je paie Y » avec l'or mis de côté. N'importe quel artisan fabrique et livre. Ça reste organique : pas d'arbitre.
6. **Livre de recettes** (/recettes, « à ne pas oublier.txt ») : recettes connues par atelier, ce qui manque pour chacune.
7. **FAIT le 19/11** (`Ventes` : renom, `/renom`). **Renom d'artisan.** La signature existe déjà. Les pièces signées par un artisan qui a beaucoup vendu se revendent mieux.

Pas proposé ici : la qualité des ingrédients (idee.txt). Elle contredit « pas de qualité séparée » (AUDIT.md), c'est à trancher avant.
