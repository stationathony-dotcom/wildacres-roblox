# Équipement : ce qui manque, et visuels à retravailler

19/11/2026. Relecture de 11 planches de `images/catalogue` (au moins une par famille) et des données d'équipement après `Gear.expandRecipes` : 538 pièces.

## Déjà corrigé (`Shared/Equilibre.lua`, `finish`)

- **Séries générées** (forme × matière) :
  - stats selon la forme : dague = Discrétion et Vitesse, marteau = Force et Défense, solerets = Défense et Vie… ;
  - une touche propre à la matière : Loup gris = Vitesse, Lune d'argent = Discrétion, Ambre royal = Charisme… ;
  - dégâts selon la forme : dague ×0,75, espadon ×1,3 ;
  - budget aligné sur les pièces faites à la main : 9 en rareté 3 et 13 en rareté 4 sur les emplacements principaux, 6 et 8 sur les petits ;
  - « Épée en lin de Valdor » devient « Épée de Valdor ».
- **Exigences de caractéristiques** à la place des niveaux : rareté 3 = stat principale entraînée au niveau 3, rareté 4 = niveau 6, pièce de maître = niveau 9.
- **10 pièces de départ** pour les gants, bottes, pantalons, capes et épaulières. Il n'y en avait presque pas en rareté 1.

## Ce qui manque en équipement

1. **Les petits emplacements sont vides par rapport aux autres.** Il y a 13 à 15 pièces par emplacement pour les gants, épaulières, pantalons, capes et bottes, contre 145 armes et 151 bijoux. Il n'y a que 2 pièces de rareté 4 par petit emplacement. Il faudrait des pièces de zone (marais, désert, neige) et des pièces de créatures pour ces emplacements.
2. **Aucun équipement de métier.** Les stats sont toutes de combat ou sociales. Dans un jeu centré sur l'artisanat, il manque :
   - un tablier de forgeron, qui augmenterait les chances de qualité ;
   - des bottes de pêcheur ;
   - des gants de cueilleur ;
   - un chapeau de fermier.

   Il faut pour ça des bonus de compétence sur les pièces (par exemple `skill = { peche = 2 }`), lus par les systèmes de métier. C'est le plus gros manque.
3. **Pas de bonus d'ensemble.** Les 12 matières des séries forment des panoplies naturelles. Porter 3 pièces de la même matière (Loup gris, Garde du pont…) pourrait donner un petit bonus. Le système de séries s'y prête déjà.
4. **Les boucliers sont rangés comme bijoux.** Ils entrent en concurrence avec les anneaux. Il faudrait un emplacement « main gauche » pour le bouclier ou la torche.
5. **Des pièces de créatures en double.** Il y a 15 « Collier de crocs de [bête] » et 8 « Lame venimeuse de [bête] », avec la même forme et presque les mêmes stats. Deux façons de corriger :
   - les regrouper par famille et par palier (crocs de petite bête, de grande bête, de bête légendaire) ;
   - ou donner à chacune un effet propre (venin, givre, saignement).
6. **Armes absentes** : armes de jet (javelots, haches de jet), harpon de pêche, fronde. Il n'y a qu'un type de munition : il manque des flèches de fer ou barbelées.
7. **Monture et compagnon** : pas de selle ni de caparaçon à équiper. Le collier de chien n'a aucune stat.
8. **Deux systèmes d'arme en parallèle.** Les épées-outils (`sword`, `sword_fe`, `sword_steel`, `sword_diamond` dans `Config`, avec `weapon = dégâts`) coexistent avec l'emplacement Arme de l'équipement. Il faut vérifier lesquels comptent au combat, et n'en garder qu'un.

## Visuels à retravailler (par priorité)

### 1. Modèles faux : l'objet ne ressemble pas à son nom
- **Noyau de cerise** : affiché comme un livre vert.
- **Objet d'une ruine** : affiché comme une fiole bleue.
- **Laine** : affichée comme une planche blanche. Il faut une pelote ou une toison.
- **Couronne** et **Couronne oubliée** : un pain ou un disque orange. Il faut une vraie couronne à pointes.
- **Turban de pillard du désert** : une dalle verte. Il faut un turban enroulé.
- **Carreaux** et **Carreaux de baliste** : des lames de couteau. Ce sont des traits courts à empennage.
- **Insigne de garde** : on dirait une table. **Insignes de shérif et de soldat** : des disques verts. Il faut une étoile ou un écusson.
- **Talisman** : un anneau. Il faut une amulette avec pendentif.
- **Chair pourrie** : un ovale vert sans relief.
- **Oreilles pointues de gobelin** : de grosses fèves colorées. Il faut une oreille pointue.

### 2. Une seule forme pour toute une famille, seule la couleur change
- **Torses** (planche 1/16) : armure d'écailles, de plates, brigandine, cotte de mailles et cuirasse ont la même silhouette en boîte. Il faut une silhouette par type :
  - mailles : longue, avec un motif d'anneaux ;
  - plates : épaulières et plastron bombé ;
  - écailles : motif d'écailles ;
  - brigandine : rivets ;
  - cuir : sangles.
- **Bijoux** : bracelet, broche, collier, bague sertie, anneau, collier de chien et boucle sont le même anneau. Un collier doit avoir sa chaîne, une broche son épingle, une bague sertie sa pierre.
- **Os** : os, os fossilisé et les 6 « os massif de… » sont identiques. Distinguer au moins taille, couleur et cassure.
- **Bois de cerf** (×4), **clés** (ancienne et rouillée), **bourses**, **carquois**, **cordes** (×3) : un seul modèle pour chaque famille.
- **Herbes** : thym, valériane, menthe, millepertuis, ortie, lavande, houblon et lin sont le même bouquet sur un bâton. Il faut au moins une forme de feuille ou une couleur de fleur par plante, car on les cherche par biome.
- **Lames venimeuses** (×8), **lances** et **marteaux** des séries : même silhouette, seule la couleur change. C'est acceptable pour une série, mais il faudrait que la matière se lise (dorure, givre, os).

### 3. Coiffes peu lisibles
- **Capuches** : une boule avec un cadre. On ne lit pas une capuche. Il faut un drapé qui tombe sur les épaules.
- **Casque nasal** : une boule barrée. Il faut le nasal vertical.
- **Bonnet de fourrure**, **bonnet rouge**, **béret** : ils ressemblent à des hamburgers. Il faut aplatir et donner une forme molle.

### 4. Bien en l'état
Le mobilier (planche 2), les sacs de marchandises, les jus, les fioles d'alchimie, les masques, les graines et les âmes de boss forment des familles cohérentes et reconnaissables.

### 5. Planches
Beaucoup de noms sont coupés (« Armure d'écailles de basilic des… »). Il faudrait réduire la police ou passer sur 3 lignes.
