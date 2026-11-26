# Équipement façon MMO — plan réadapté (26/11)

Source : `Desktop\Pour Wild Acres, je créerais un véritable système d'équipements….txt` (proposition du propriétaire,
« réadapter, l'idée plus ou moins »). Principe gardé : **pas de classe imposée, c'est l'équipement, les compétences et les
talents qui font la spécialisation.** Tout reste soumis aux règles d'`AGENTS.md` § 1.

## Réadaptations aux règles du jeu
| Proposition | Dans Wild Acres |
|---|---|
| Niveau requis | Exigence de **caractéristique entraînée** (`Equilibre.requirement`, déjà en place : pas de niveau de personnage) |
| Résistance au froid / chaleur | **Retirées** (règle 10, tranché le 20/11). Les passifs « givre » deviennent des effets d'arme (givre = ralentit) |
| Capacité de transport | **Pas de plafond** (règle 2) : non retenu |
| Signature du fabricant, qualité de façon, historique, numéro unique | **Retirés le 20/11** (l'artisan reste noté, caché, pour son renom). À rediscuter si le propriétaire le souhaite |
| Agilité / Vitalité / Armure / Commerce | = Vitesse / Vie / Défense / Charisme (caractéristiques existantes) |

## Fait (Claude, 26/11)
- **Familles d'armes** jouables (`Shared/Armes.lua`, banc `combat_armes`) : profils, types de dégâts, résistances, enchaînements,
  coup chargé, garde / parade / esquive, armes à distance distinctes, maîtrise par famille.
- **Affixes procéduraux** (`Shared/Equipement.lua`) : toute pièce neuve peut recevoir un complément (« de vigueur »,
  « de célérité », « du tranchant »…) qui ajoute une caractéristique ; les légendaires en ont deux. Deux joueurs avec le même
  modèle n'ont donc pas les mêmes statistiques.
- **Nouvelles caractéristiques** : Critique (chance de coup double, max 35 %), Hâte (cadence, max 30 %), Maîtrise (+1 % de dégâts / point).
- **Durabilité** : l'arme s'use à chaque coup porté, une pièce d'armure au hasard à chaque coup reçu ; brisée = plus de
  statistiques ; **réparation** chez le forgeron ou l'armurier (prix selon la rareté et l'usure).
- **Types d'armure** (forme du torse) : tissu (vitesse +5 %), cuir (+3 %, défense +5 %), mailles (−2 %, +12 %), plates (−6 %, +22 %).
- **Spécialisation déduite de l'équipement** (attribut `Specialisation`) avec un petit passif : Gardien (bouclier : garde
  −25 % d'endurance), Ombre (dague : dos +20 %), Rôdeur (arc : portée +12 %), Guerrier (armes lourdes +6 %), Dresseur
  (compagnons), Artisan (équipement de métier), Aventurier (polyvalent).
- Déjà là avant : 9 emplacements, panoplies 2/4/6 pièces (`Equilibre.setBonus`), équipement de métier (30 pièces, `skills`),
  exigences de caractéristique, armurier (base + pièces uniques du jour).

## À faire (ordre proposé)
1. **Magie** (Élémentaliste, Protecteur) : bâton, baguette, sceptre, grimoire, orbe ; caractéristiques Intelligence et Esprit ;
   réserve de magie ; sorts élémentaires (feu, givre, foudre) et de soutien (soin, bouclier). Gros chantier : code Claude,
   modèles et effets Codex.
2. **Gemmes et runes sertissables** (emplacements selon la rareté) et **enchantements** chez l'alchimiste (huiles de feu,
   givre, venin sur la lame pour un temps).
3. **Recyclage** chez le forgeron (rendre une partie des matières) ; **transmogrification** chez le tailleur (garder les
   statistiques, prendre l'apparence d'une autre pièce) ; **teintures** d'armure.
4. **Ensembles nommés** du document (Gardien royal, Enfant des bois, Mage des brumes, Maître de forge, Fermier ancestral,
   Marchand royal, Explorateur des océans) en plus des panoplies par matière : bonus 2 / 4 / 6 pièces.
5. **Équipements civils aussi profonds que ceux de combat** (souhait du document) : outils et tenues de métier rares,
   avec passifs (récolte, rendement, commerce).
6. **Volume** (objectif indicatif ≈ 1 000 pièces : 200 armes, 300 armures, 150 vêtements civils, 120 de métier,
   100 bijoux, 80 gemmes et runes, 50 légendaires uniques) : génération par Codex (lots X32 et suivants).
