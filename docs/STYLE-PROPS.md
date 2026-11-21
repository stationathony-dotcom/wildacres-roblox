# Style des props de Wild Acres

Valdor donne la référence de matière, de couleur et d’échelle. Le bois chaud porte la silhouette, la pierre grise claire marque les appuis, le fer sombre montre l’assemblage et le chaume accroche la lumière. La garance, le bleu teint et l’or se concentrent sur les étoffes, les enseignes et les petites garnitures. [Aventure à Valdor](../Aventure%20%C3%A0%20Valdor%20dans%20Wild%20Acres.png) · [HUD de Valdor](../images/hud-village-16-9.png)

## Dessiner une pièce

1. **Masse.** Donner à chaque prop une silhouette identifiable de loin. Une roue doit laisser voir le jour entre ses rayons. Le pichet se lit à son bec et à son anse. L’abri se lit à son toit et à ses ouvertures.
2. **Structure.** Montrer comment l’objet tient. Poser les planches sur un cadre, les ferrures sur les joints, les toits sur la charpente et les charges sur leurs supports. Faire varier deux ou trois teintes de bois avec des jours fins entre les lames. Utiliser `Wood` pour les montants et les traverses, `WoodPlanks` pour les surfaces assemblées.
3. **Garnitures.** Ajouter les rivets ronds, chevilles, anneaux et gonds là où on les attend. Employer du `Metal` sombre et réserver le laiton aux boutons, enseignes, cadrans et serrures. Tracer les joints de pierre en décalant les assises et en variant les dimensions des moellons en `Slate`, `Cobblestone` ou `Rock`. Finir les murets par un chaperon.

Les fûts ont un ventre et des cercles, les toitures sont épaisses et débordent des murs, les pieds et les consoles emploient des pans coupés. Quelques décalages suffisent à rendre visible l’usage sans fausser un assemblage. Employer `Fabric` pour les plis, les galons et les cordes, `Grass` ou `Fabric` pour les rangs de chaume. Teinter le bois rouge de la grange en garance délavée et l’asseoir sur de la pierre.

## Pose et coût

- Conserver le pivot `Base` au sol, l’orientation de pose, ainsi que la largeur et la profondeur de la structure sur la grille de 4 × 4 studs. Les petits débords de garniture restent au-dessus de l’emprise. La lanterne murale garde son bas à +2,55 studs et le toit de chaume hérité son dessous à +6,925 studs. Les décors enterrés ou posés sur l’eau gardent leur profondeur d’ancrage.
- Les éléments de structure doivent se rejoindre. Une pièce décorative mince reste traversable et sélectionnable par rayon. `Neon` est réservé aux flammes et aux braises qui portent une lumière. Les vitres et les surfaces d’eau utilisent `Glass`.
- Viser 8 à 30 pièces pour un petit meuble et 20 à 60 pour un bâtiment agricole. La limite de travail est 60 pièces, avec une marge possible jusqu’à 120 pour une grange ou une écurie si la forme le demande. Les trois bâtiments agricoles les plus détaillés de cette passe restent à 60 pièces ou moins. Le champ conserve son budget existant de 110 pièces et ses 88 touffes récoltables.
- Les modèles variables gardent leurs repères de jeu. `Flamme` porte l’éclairage nocturne de la lanterne murale. `Tete` et les noms qui commencent par `Tete` tournent avec les affûts. Le panneau de village garde `Planche` et `Devant`. Les lames `Battant` de la porte héritée portent sa collision. Le `TrussPart` invisible reste l’appui d’escalade des deux échelles.

## Les 90 modèles de la vitrine

Identifiants sans le préfixe `Cat_`, dans l’ordre des rangées de la vitrine d’origine.

| Rangée | Modèles repris |
| --- | --- |
| 0 | `arched_window`, `armor_stand`, `arrow_slit`, `baliste`, `banner`, `barn`, `barn_door`, `barrel`, `big_table`, `bookcase`, `brazier`, `bread_oven` |
| 1 | `candelabra`, `candle`, `carpet_big`, `cart`, `castle_door`, `cauldron`, `clan_banner`, `clay_pot`, `clock`, `coat_arms`, `counter`, `crate` |
| 2 | `creature_skull`, `curtain`, `deco_armor`, `deco_shield`, `desk`, `double_bed`, `double_door`, `drawbridge`, `farm_gate`, `fireplace`, `flag`, `granary` |
| 3 | `hay_rack`, `hearth`, `henhouse`, `horse_stable`, `irrigation`, `keepsake_box`, `keg`, `ladder`, `lever`, `merchant_cart`, `painting_wall`, `palisade` |
| 4 | `pedestal`, `pen`, `pigsty`, `pitcher`, `planter`, `portcullis`, `press`, `raft`, `reinforced_chest`, `rope_ladder`, `round_window`, `rowboat` |
| 5 | `sculpture`, `sheepfold`, `shop_sign`, `shutter`, `sled`, `stable`, `stained_glass`, `statue`, `stone_arch`, `stone_fence`, `stool`, `straw_bed` |
| 6 | `tapestry`, `tool_rack`, `tourelle`, `trapdoor`, `travel_chest`, `trophy`, `vase_deco`, `wall_lantern`, `wall_torch`, `wardrobe`, `washtub`, `water_pump` |
| 7 | `water_wheel`, `weathervane`, `wheelbarrow`, `winch`, `wood_arch`, `wood_crane` |

L’étable ouvre sur son auge. L’écurie a deux stalles, une litière par place et une couverture en bardeaux. La bergerie se distingue par ses allèges basses et son chaume. La porcherie réunit un appentis, une auge et une souille. Le poulailler a une rampe à tasseaux et le grenier repose sur des pilotis munis de pierres anti-rongeurs. [Constructeurs du catalogue](../src/ReplicatedStorage/Shared/Catalogue.lua)

## Les 58 modèles stockés

Chaque nom désigne un constructeur indépendant et peut être passé à `propsValdor(nom)`.

| Ensemble | Noms dans `ServerStorage.Modeles` |
| --- | --- |
| Place, chemin et marché | `Boite_Lettres`, `Caisses`, `Cloture`, `Embarcadere`, `Etal`, `Feu_Camp`, `Fontaine`, `Lampadaire`, `Panneau`, `Puits`, `Tableau_Quetes`, `Tonneaux` |
| Ateliers | `Alambic`, `Bac_Tannage`, `Enclume`, `Etabli`, `Fourneau`, `Metier_Tisser` |
| Ferme et mécanismes | `Abreuvoir`, `Arroseur`, `Botte_Foin`, `Champ_Ble`, `Epouvantail`, `Mangeoire`, `Moulin`, `Ruche` |
| Mobilier | `Banc`, `Chaise`, `Coffre`, `Coffre_Joueur`, `Etagere`, `Lanterne`, `Lit_Joueur`, `Pot_Fleurs`, `Table_Bois`, `Tapis` |
| Pièces posables héritées | `Caserne`, `Cloche_Alarme`, `Escalier_Bois`, `Mur_Briques`, `Mur_Fenetre`, `Mur_Pierre`, `Mur_Planches`, `Mur_Porte`, `Plancher`, `Porte`, `Serrure_Entrainement`, `Toit_Chaume` |
| Petit décor de sol | `Branche`, `Buisson`, `Caillou`, `Champignon`, `Fleurs`, `Rocher`, `Sol_Laboure`, `Terre_Retournee`, `Touffe`, `Tronc_Couche` |

Cette passe couvre les objets du catalogue, les décors stockés de village et de sol ainsi que les modèles hérités servant à la pose. Les bâtiments fixes du village comme les maisons et le château, les variantes paramétriques de `Batir`, les biomes et le bestiaire suivent leurs propres constructeurs. [Constructeurs des modèles stockés](../src/ServerStorage/OutilsDev/ConstruireModeles.lua)

## Reconstruction en mode Édition

Avec `python tools/sync.py` en marche, pousser les deux modules de ce lot. La commande vérifie leur syntaxe avant de copier les sources.

```lua
local h = game:GetService("HttpService")
local sources = {
	["ReplicatedStorage.Shared.Catalogue"] = game.ReplicatedStorage.Shared.Catalogue,
	["ServerStorage.OutilsDev.ConstruireModeles"] = game.ServerStorage.OutilsDev.ConstruireModeles,
}
local textes = {}
for chemin, module in sources do
	local source = h:GetAsync("http://127.0.0.1:34873/file?p=" .. h:UrlEncode(chemin))
	assert(loadstring(source, "=" .. chemin))
	textes[module] = source
end
for module, source in textes do module.Source = source end
```

Reconstruire les 58 modèles du tableau par l’entrée dédiée. Pour travailler par modèle, remplacer `"Puits"` par son nom dans le tableau.

```lua
task.spawn(function()
	local s = game.ServerStorage.OutilsDev.ConstruireModeles:Clone()
	print(require(s).propsValdor(), "modèles reconstruits")
	s:Destroy()
end)
```

```lua
local s = game.ServerStorage.OutilsDev.ConstruireModeles:Clone(); require(s).propsValdor("Puits"); s:Destroy()
```

Pour photographier les `Cat_*`, sélectionner dans l’explorateur le conteneur de la vitrine actuelle. Cette commande remplace ses 90 modèles à leurs pivots et attend entre les rangées. Le banc et la pose normale construisent directement les `Cat_*` depuis le catalogue.

```lua
local vitrine = assert(game:GetService("Selection"):Get()[1], "Sélectionner le conteneur de la vitrine")
local shared = game.ReplicatedStorage.Shared
local catalogue = assert(loadstring(shared.Catalogue.Source, "=Catalogue"))()
local config = assert(loadstring(shared.Config.Source, "=Config"))
local charger = require
setfenv(config, setmetatable({
	script = shared.Config,
	require = function(module)
		if module == shared.Catalogue then return catalogue end
		return charger(module)
	end,
}, { __index = getfenv(config) }))
config()

local anciens = {}
for _, m in vitrine:GetDescendants() do
	if m:IsA("Model") and catalogue.MODELS[m.Name] then
		table.insert(anciens, m)
	end
end
assert(#anciens == 90, "La sélection doit contenir les 90 Cat_* de la vitrine")
task.spawn(function()
	for i, ancien in anciens do
		local nouveau = assert(catalogue.build(ancien.Name))
		nouveau:PivotTo(ancien:GetPivot())
		nouveau.Parent = ancien.Parent
		ancien:Destroy()
		if i % 12 == 0 then task.wait() end
	end
end)
```

Lancer le banc en Édition après reconstruction et lire `ServerStorage.BancVisuelsProps`.

```lua
assert(loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34873/banc?f=visuels_props")))()
```

Le contrôle sur disque a exécuté les 148 constructeurs avec des instances simulées. Il vérifie les pivots, les boîtes orientées, les appuis, les budgets, les flammes et les propriétés de sélection des modèles. Le rapport Studio et les photos restent à produire. Une vue de trois quarts depuis la façade montre les ouvertures des abris et les roues des véhicules. Pour la roue à eau, prendre aussi une vue côté axe pour lire les rayons et les aubes. [Banc de vérification](../tools/bancs/visuels_props.luau)

