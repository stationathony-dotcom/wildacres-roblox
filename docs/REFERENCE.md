# Wild Acres — fiche de référence (générée)

Générée par `tools/bancs/reference.luau` depuis les données du jeu : **ne pas modifier à la main**, relancer le banc.
Contenu : 966 objets, 1211 recettes, 23 cultures, 168 créatures, 11 compétences.

Règles : tout objet est **échangeable** (troc, étal, hôtel des ventes, courrier, coffre) — aucun objet lié au
personnage (décision étape 4B : économie entre joueurs, monde bac à sable). L'équipement porté s'échange une fois retiré.
Rareté = obtention réelle (`Catalogue.assignRarity`) : prix, et pour ce qui ne se fabrique ni ne s'achète, meilleure chance de trouvaille.

## Contrôles

- Objets sans aucune source trouvée : floor2, stairs, wall, wall2, wall2_window, wall_brick, wall_door, wall_stone, wall_window
  (les pièces toutes faites `wall*`, `floor2`, `stairs` sont retirées de l'atelier depuis la construction libre ; gardées pour les anciennes sauvegardes)
- Objets sans usage ni valeur de revente : **aucun**

## Objets

Raretés : commun 670 · peu commun 39 · rare 158 · épique 67 · légendaire 32

### Graines (23)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🌱 Graines (Ail) | `seed_garlic` | commun | 10 | boutique | usage direct |
| 🌱 Graines (Aubergine) | `seed_eggplant` | commun | 16 | boutique | usage direct |
| 🌱 Graines (Avoine) | `seed_oat` | commun | 6 | boutique | usage direct |
| 🌱 Graines (Betterave) | `seed_beetroot` | commun | 10 | boutique | usage direct |
| 🌱 Graines (Blé) | `seed_wheat` | commun | 6 | boutique | 1 recette, usage direct |
| 🌱 Graines (Carotte) | `seed_carrot` | commun | 12 | boutique | usage direct |
| 🌱 Graines (Chou) | `seed_cabbage` | commun | 13 | boutique | usage direct |
| 🌱 Graines (Citrouille) | `seed_pumpkin` | commun | 35 | boutique, butin, boss | usage direct |
| 🌱 Graines (Courge) | `seed_squash` | commun | 22 | boutique | usage direct |
| 🌱 Graines (Haricots) | `seed_bean` | commun | 9 | boutique | usage direct |
| 🌱 Graines (Herbes aromatiques) | `seed_herbs` | commun | 5 | boutique | usage direct |
| 🌱 Graines (Houblon) | `seed_hops` | commun | 11 | boutique | usage direct |
| 🌱 Graines (Lin) | `seed_flax` | commun | 6 | boutique | usage direct |
| 🌱 Graines (Melon) | `seed_melon` | commun | 30 | boutique | usage direct |
| 🌱 Graines (Navet) | `seed_turnip` | commun | 9 | boutique | usage direct |
| 🌱 Graines (Oignon) | `seed_onion` | commun | 10 | boutique | usage direct |
| 🌱 Graines (Orge) | `seed_barley` | commun | 7 | boutique | usage direct |
| 🌱 Graines (Panais) | `seed_parsnip` | commun | 8 | boutique | usage direct |
| 🌱 Graines (Patate) | `seed_potato` | commun | 20 | boutique | usage direct |
| 🌱 Graines (Pois) | `seed_pea` | commun | 8 | boutique | usage direct |
| 🌱 Graines (Raisin) | `seed_grape` | commun | 18 | boutique | usage direct |
| 🌱 Graines (Seigle) | `seed_rye` | commun | 8 | boutique | usage direct |
| 🌱 Graines (Tomate) | `seed_tomato` | commun | 15 | boutique | usage direct |

### Nourriture et boissons (108)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🧄 Ail | `garlic` | commun | 32 | récolte | 2 recettes, usage direct |
| 🐟 Anguille | `fish_6` | commun | 33 | code:Npcs | usage direct |
| 🍆 Aubergine | `eggplant` | commun | 50 | récolte | 1 recette, usage direct |
| 🌾 Avoine | `oat` | commun | 20 | récolte | 3 recettes, usage direct |
| 🍇 Baies | `berries` | commun | 4 | code:Npcs | 3 recettes, usage direct |
| 🍖 Banquet du seigneur | `lord_banquet` | légendaire | 1200 | atelier | usage direct |
| 🧴 Baume d'herboriste | `herbal_salve` | commun | 70 | atelier | usage direct |
| 🍠 Betterave | `beetroot` | commun | 30 | récolte | 2 recettes, usage direct |
| 🟨 Beurre | `butter` | commun | 77 | atelier | 2 recettes, usage direct |
| 🍺 Bière d'orge | `ale` | rare | 183 | établi | 1 recette, usage direct |
| 🌾 Blé | `wheat` | commun | 20 | récolte | 10 recettes, usage direct |
| 🥣 Bouillie | `porridge` | rare | 83 | four | usage direct |
| 🍲 Bouillon | `broth` | commun | 36 | four | usage direct |
| 🐟 Brochet | `fish_5` | commun | 36 | butin | usage direct |
| 🥕 Carotte | `carrot` | commun | 35 | récolte | 3 recettes, usage direct |
| 🐟 Carpe | `fish_2` | commun | 15 | code:Metiers | usage direct |
| 🍄 Champignon | `mushroom` | commun | 12 | boss, butin | 1 recette, usage direct |
| 🥬 Chou | `cabbage` | commun | 40 | récolte | 3 recettes, usage direct |
| 🍺 Cidre | `cider` | commun | 60 | établi | 1 recette, usage direct |
| 🎃 Citrouille | `pumpkin` | rare | 110 | récolte | 1 recette, usage direct |
| 🍲 Civet de lapin | `rabbit_stew` | rare | 110 | four | usage direct |
| 🐚 Coquillage | `shellfish` | commun | 14 | pêche | 1 recette, usage direct |
| 🎃 Courge | `squash` | commun | 70 | récolte | usage direct |
| 🦀 Crabe | `crab` | commun | 30 | pêche | 1 recette, usage direct |
| 💧 Eau | `water` | commun | 3 | atelier | usage direct |
| 🧀 Fromage | `cheese` | rare | 125 | four | 1 recette, usage direct |
| 🧀 Fromage affiné | `aged_cheese` | épique | 284 | atelier | 1 recette, usage direct |
| 🍇 Fruits séchés | `dried_fruit` | commun | 30 | atelier | 1 recette, usage direct |
| 🥞 Galette | `galette` | rare | 129 | four | usage direct |
| 🐟 Gardon | `fish_1` | commun | 9 | butin | usage direct |
| 🍗 Grand festin | `village_feast` | légendaire | 942 | atelier | usage direct |
| ❤️ Grande potion de soin | `grande_potion` | épique | 308 | atelier | usage direct |
| 🍰 Gâteau au miel | `honey_cake` | rare | 180 | four | 1 recette, usage direct |
| 🌰 Haricots | `bean` | commun | 30 | récolte | usage direct |
| 🌿 Herbes aromatiques | `herbs` | commun | 16 | récolte | 5 recettes, usage direct |
| 🌿 Houblon | `hops` | commun | 34 | récolte | 1 recette, usage direct |
| 🍵 Infusion de camomille | `chamomile_tea` | commun | 26 | four | usage direct |
| 🍵 Infusion de menthe | `mint_tea` | commun | 26 | four | usage direct |
| 🍵 Infusion de sauge | `sage_tea` | commun | 24 | atelier | usage direct |
| 🍵 Infusion de thym | `thyme_tea` | commun | 26 | four | usage direct |
| 🧃 Jus de baies | `berry_juice` | commun | 25 | atelier | usage direct |
| 🧃 Jus de pomme | `apple_juice` | commun | 40 | atelier | usage direct |
| 🍷 Jus de raisin | `grape_juice` | rare | 128 | atelier | usage direct |
| 🥛 Lait | `milk` | commun | 35 | élevage | 5 recettes, usage direct |
| 🌿 Lin | `flax` | commun | 18 | récolte | 2 recettes, usage direct |
| 🥗 Légumes cuits | `cooked_veg` | commun | 75 | four | usage direct |
| 🍈 Melon | `melon` | rare | 90 | récolte | usage direct |
| 🍯 Miel | `honey` | commun | 30 | butin | 4 recettes, usage direct |
| 🧅 Navet | `turnip` | commun | 28 | récolte | 2 recettes, usage direct |
| 🧅 Oignon | `onion` | commun | 30 | récolte | 3 recettes, usage direct |
| 🧅 Oignons au vinaigre | `pickled_onions` | rare | 181 | atelier | usage direct |
| 🍳 Omelette | `omelette` | commun | 60 | four | usage direct |
| 🌾 Orge | `barley` | commun | 22 | récolte | 1 recette, usage direct |
| 🍞 Pain | `bread` | commun | 70 | four | 2 recettes, usage direct |
| 🍞 Pain complet | `whole_bread` | rare | 97 | four | 1 recette, usage direct |
| 🥖 Pain de campagne | `country_bread` | rare | 110 | four | usage direct |
| 🥕 Panais | `parsnip` | commun | 25 | récolte | usage direct |
| 🥔 Patate | `potato` | commun | 55 | récolte | 2 recettes, usage direct |
| 🧪 Philtre apaisant | `calming_draught` | rare | 110 | atelier | usage direct |
| 💖 Philtre de charme | `potion_charme` | commun | 73 | atelier | usage direct |
| 🍀 Philtre du trèfle | `potion_trefle` | rare | 80 | atelier | usage direct |
| 🍐 Poire | `pear` | commun | 10 | abattage | 1 recette, usage direct |
| 🌱 Pois | `pea` | commun | 26 | récolte | 1 recette, usage direct |
| 🐟 Poisson cru | `raw_fish` | commun | 8 | pêche | 1 recette, usage direct |
| 🐟 Poisson doré | `fish_7` | rare | 150 | code:Npcs | usage direct |
| 🐟 Poisson fumé | `smoked_fish` | commun | 40 | four | usage direct |
| 🍢 Poisson grillé | `grilled_fish` | commun | 60 | four | usage direct |
| 🐟 Poisson-chat | `fish_4` | commun | 27 | code:Npcs | usage direct |
| 🍎 Pomme | `apple` | commun | 10 | abattage | 5 recettes, usage direct |
| 🌫️ Potion de brume | `potion_brume` | rare | 126 | atelier | usage direct |
| 🍄 Potion de force sauvage | `potion_sauvage` | épique | 260 | atelier | usage direct |
| 🛡️ Potion de peau de pierre | `potion_pierre` | commun | 70 | atelier | usage direct |
| ❤️ Potion de soin | `healing_potion` | rare | 80 | atelier | 1 recette, usage direct |
| 💨 Potion de vent | `potion_vent` | commun | 60 | atelier | usage direct |
| 🧡 Potion du taureau | `potion_taureau` | rare | 84 | atelier | usage direct |
| 🟣 Prune | `plum` | commun | 12 | abattage | 1 recette, usage direct |
| 🍲 Ragoût de gibier | `game_stew` | rare | 120 | four | usage direct |
| 🥘 Ragoût du désert | `stew` | rare | 200 | four | 1 recette, usage direct |
| 🍇 Raisin | `grape` | commun | 55 | récolte | 2 recettes, usage direct |
| 🎒 Rations | `rations` | rare | 87 | atelier, butin | 2 recettes, usage direct |
| 🎒 Sac de provisions | `provision_bag` | rare | 206 | atelier | usage direct |
| 🥗 Salade | `salad` | rare | 157 | atelier | usage direct |
| 🍖 Sanglier rôti | `roast_boar` | commun | 70 | four | usage direct |
| 🐟 Saumon | `salmon` | commun | 50 | pêche | usage direct |
| 🌾 Seigle | `rye` | commun | 24 | récolte | 1 recette, usage direct |
| 🍯 Sirop de fruits | `fruit_syrup` | rare | 176 | four | usage direct |
| 🥣 Soupe d'orties | `nettle_soup` | commun | 30 | four | usage direct |
| 🍲 Soupe de poisson | `fish_soup` | rare | 90 | four | usage direct |
| 🍲 Soupe du potager | `soup` | rare | 140 | four | usage direct |
| 🍖 Steak grillé | `steak` | commun | 30 | four | usage direct |
| 🥧 Tarte aux pommes | `apple_pie` | rare | 213 | four | usage direct |
| 🥧 Tarte à la citrouille | `pie` | épique | 220 | four | 1 recette, usage direct |
| 🍵 Tisane du soir | `evening_tea` | commun | 38 | atelier | usage direct |
| 🍅 Tomate | `tomato` | commun | 45 | récolte | 1 recette, usage direct |
| 🥧 Tourte à la viande | `meat_pie` | rare | 170 | four | 1 recette, usage direct |
| 🐟 Truite | `fish_3` | commun | 24 | butin | usage direct |
| 🥩 Viande crue | `meat` | commun | 8 | butin | 5 recettes, usage direct |
| 🥩 Viande de cerf | `venison` | commun | 16 | chasse, butin | 1 recette, usage direct |
| 🥩 Viande de lapin | `rabbit_meat` | commun | 10 | chasse | 1 recette, usage direct |
| 🥩 Viande de sanglier | `boar_meat` | commun | 14 | chasse, butin | 1 recette, usage direct |
| 🍖 Viande rôtie | `roast` | commun | 60 | four | 1 recette, usage direct |
| 🥓 Viande séchée | `jerky` | commun | 30 | atelier | 1 recette, usage direct |
| 🦞 Écrevisse | `crayfish` | commun | 24 | pêche | usage direct |
| 🌿 Élixir de racine ancienne | `elixir_racine` | épique | 400 | atelier | usage direct |
| 💪 Élixir de vigueur | `vigor_elixir` | rare | 184 | atelier | usage direct |
| 🌙 Élixir lunaire | `elixir_lunaire` | épique | 300 | atelier | usage direct |
| 🌙 Élixir nocturne | `night_elixir` | rare | 200 | atelier | usage direct |
| 🥚 Œuf | `egg` | commun | 15 | élevage | 5 recettes, usage direct |

### Objets de valeur et collection (46)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🟠 Ambre | `amber` | rare | 60 | abattage | 22 recettes, usage direct |
| ⚓ Ancre | `anchor` | épique | 441 | établi | 1 recette, usage direct |
| ⚖️ Balance | `scales_tool` | peu commun | 71 | établi | usage direct |
| 💍 Bijou ancien | `ancient_jewel` | épique | 240 | événement, trésor, butin, boss | 2 recettes, usage direct |
| 🌲 Bois pétrifié | `petrified_wood` | épique | 120 | abattage, butin | 1 recette, usage direct |
| 🧭 Boussole | `compass` | rare | 92 | établi | usage direct |
| 🧭 Boussole ancienne | `old_compass` | épique | 260 | pêche | usage direct |
| ⭕ Bracelet | `bracelet` | rare | 180 | établi | usage direct |
| 🔶 Broche | `brooch` | épique | 220 | établi | usage direct |
| 🗺️ Carte du monde | `map_world` | rare | 160 | atelier | usage direct |
| 📜 Charte de ville | `charter` | épique | 300 | établi | usage direct |
| 🗝️ Clé rouillée | `rusty_key` | rare | 10 | fouille, butin | 1 recette, usage direct |
| 📿 Collier | `necklace` | épique | 330 | établi | usage direct |
| ➰ Corde d'escalade | `climbing_rope` | peu commun | 53 | atelier | 1 recette, usage direct |
| 📯 Corne de bête rare | `rare_horn` | épique | 260 | chasse, butin | 1 recette, usage direct |
| 👑 Couronne oubliée | `lost_crown` | légendaire | 1500 | boss | 2 recettes, usage direct |
| 🍴 Couteau de table | `table_knife` | peu commun | 28 | atelier | usage direct |
| 🛏️ Couverture | `blanket` | rare | 81 | atelier | usage direct |
| 💗 Cœur minéral | `mineral_heart` | épique | 500 | événement, butin | 1 recette, usage direct |
| 💎 Diamant | `diamond` | légendaire | 500 | minage | 38 recettes, usage direct |
| 🍴 Fourchette ancienne | `table_fork` | peu commun | 30 | atelier | usage direct |
| 🏮 Lampe de mineur | `miner_lamp` | peu commun | 57 | établi | usage direct |
| 🥇 Lingot précieux | `precious_ingot` | épique | 400 | four | 1 recette, usage direct |
| 📖 Livre d'histoire | `history_book` | rare | 100 | établi | 1 recette, usage direct |
| 🛏️ Oreiller | `pillow` | rare | 132 | atelier | 1 recette, usage direct |
| 🦴 Os fossilisé | `fossil_bone` | épique | 140 | minage, butin | 1 recette, usage direct |
| 🧺 Panier en osier | `wicker_basket` | commun | 16 | atelier | 2 recettes, usage direct |
| ⚪ Perle | `pearl` | rare | 90 | pêche, trésor, butin, boss | 3 recettes, usage direct |
| 💠 Pierre colorée | `colored_stone` | peu commun | 30 | cueillette, butin | 1 recette, usage direct |
| ⛰️ Pierre gravée | `carved_stone` | épique | 90 | minage, butin | 2 recettes, usage direct |
| 💰 Pièce ancienne | `ancient_coin` | rare | 80 | minage, fouille, trésor, butin | 1 recette, usage direct |
| ⚪ Pièce d'argent | `silver_coin` | commun | 10 | événement, fouille, trésor | 1 recette, usage direct |
| 🟡 Pièce d'or | `gold_coin` | épique | 50 | fouille, trésor | 1 recette, usage direct |
| 🟠 Pièce de cuivre | `copper_coin` | commun | 1 | fouille, butin | 1 recette, usage direct |
| ⚖️ Poids de mesure | `weights` | peu commun | 50 | four | usage direct |
| 📁 Porte-documents | `document_case` | peu commun | 51 | établi | 1 recette, usage direct |
| 🎀 Ruban de compétition | `ribbon` | peu commun | 66 | atelier | 1 recette, usage direct |
| 🔴 Rubis | `ruby` | épique | 250 | minage, trésor, butin | 3 recettes, usage direct |
| ⏳ Sablier | `hourglass` | peu commun | 60 | établi | 1 recette, usage direct |
| 🎒 Sac à dos | `backpack` | rare | 80 | établi | usage direct |
| 🔵 Saphir | `sapphire` | épique | 250 | minage, trésor | 2 recettes, usage direct |
| 🖼️ Tableau | `painting` | épique | 297 | atelier | 1 recette, usage direct |
| 🎐 Tissu précieux | `fine_cloth` | rare | 183 | atelier | 2 recettes, usage direct |
| 🐉 Écaille ancienne | `ancient_scale` | épique | 300 | chasse | 1 recette, usage direct |
| 🟢 Émeraude | `emerald` | épique | 280 | minage, trésor | 1 recette, usage direct |
| 📜 Étui à parchemins | `scroll_case` | peu commun | 30 | établi | 1 recette, usage direct |

### Objets posés et mobilier (120)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 💧 Abreuvoir | `trough` | commun | — | établi, atelier | usage direct |
| ⚗️ Alambic | `alembic` | commun | — | atelier | usage direct |
| 🏹 Arbalète de garde | `tourelle` | épique | 420 | établi, boutique | usage direct |
| 🏛️ Arche en bois | `wood_arch` | commun | — | établi | usage direct |
| 🏛️ Arche en pierre | `stone_arch` | commun | — | établi | usage direct |
| 🚪 Armoire | `wardrobe` | commun | — | établi | usage direct |
| 🛡️ Armure décorative | `deco_armor` | commun | — | établi | usage direct |
| 💦 Arroseur | `sprinkler` | commun | — | établi | usage direct |
| 🦌 Bac de tannage | `tannery` | commun | — | établi | usage direct |
| 🏰 Baliste de rempart | `baliste` | légendaire | 1500 | établi, boutique | usage direct |
| 🪑 Banc | `garden_bench` | commun | — | atelier | usage direct |
| 🚩 Bannière | `banner` | commun | — | atelier | usage direct |
| 🚩 Bannière de clan | `clan_banner` | commun | 71 | établi | usage direct |
| 🛢️ Baril | `keg` | commun | — | établi | usage direct |
| 🚣 Barque | `rowboat` | commun | — | établi | usage direct |
| 🛁 Bassine | `washtub` | commun | — | atelier | usage direct |
| 🐑 Bergerie | `sheepfold` | commun | — | établi | usage direct |
| 📚 Bibliothèque | `bookcase` | commun | — | établi | usage direct |
| 🛡️ Blason | `coat_arms` | commun | — | établi | usage direct |
| 🛡️ Bouclier décoratif | `deco_shield` | commun | — | atelier | usage direct |
| 🕯️ Bougie | `candle` | commun | — | atelier | usage direct |
| 🔥 Brasero | `brazier` | commun | — | établi | usage direct |
| 🛒 Brouette | `wheelbarrow` | commun | — | atelier | usage direct |
| 🖋️ Bureau | `desk` | commun | — | établi | usage direct |
| 📦 Caisse | `crate` | commun | — | atelier | usage direct |
| 📦 Caisse clouée | `nailed_crate` | commun | 40 | établi | usage direct |
| 💧 Canal d'irrigation | `irrigation` | commun | — | atelier | usage direct |
| 🏰 Caserne | `barracks` | commun | — | établi | usage direct |
| 🪑 Chaise | `chair` | commun | — | atelier | usage direct |
| 🕯️ Chandelier | `candelabra` | commun | — | établi | usage direct |
| 🛒 Chariot de marchand | `merchant_cart` | commun | — | établi | usage direct |
| 🛒 Charrette | `cart` | commun | — | établi | usage direct |
| 🍲 Chaudron | `cauldron` | commun | — | établi | usage direct |
| 🔥 Cheminée | `fireplace` | commun | — | établi | usage direct |
| 🔔 Cloche d'alarme | `alarm` | commun | — | établi | usage direct |
| 🌲 Clôture | `fence` | commun | — | atelier | 1 recette, usage direct |
| 🧱 Clôture en pierre | `stone_fence` | commun | — | atelier | usage direct |
| 📦 Coffre | `chest` | commun | — | établi | usage direct |
| 🧳 Coffre de transport | `travel_chest` | commun | — | établi | usage direct |
| 📦 Coffre renforcé | `reinforced_chest` | commun | — | établi | usage direct |
| 🎁 Coffret | `keepsake_box` | commun | — | établi | usage direct |
| 🌲 Comptoir | `counter` | commun | — | établi | usage direct |
| 💀 Crâne de créature | `creature_skull` | commun | — | atelier | usage direct |
| 🏳️ Drapeau | `flag` | commun | — | atelier | usage direct |
| 🐑 Enclos | `pen` | commun | — | atelier | usage direct |
| ⚒️ Enclume | `anvil` | commun | — | établi | usage direct |
| 🚩 Enseigne de boutique | `shop_sign` | commun | — | établi | usage direct |
| 🖼️ Fenêtre arquée | `arched_window` | commun | — | établi | usage direct |
| 🖼️ Fenêtre ronde | `round_window` | commun | — | établi | usage direct |
| 🔥 Feu de camp | `campfire` | commun | — | atelier | usage direct |
| 🏭 Four | `furnace` | commun | — | établi | usage direct |
| 🍞 Four à pain | `bread_oven` | commun | — | établi | usage direct |
| 🔥 Foyer | `hearth` | commun | — | atelier | usage direct |
| 🐓 Girouette | `weathervane` | commun | — | établi | usage direct |
| 🟥 Grand tapis | `carpet_big` | commun | — | atelier | usage direct |
| 🪑 Grande table | `big_table` | commun | — | établi | usage direct |
| 🏚️ Grange | `barn` | commun | — | établi | usage direct |
| 🌾 Grenier | `granary` | commun | — | établi | usage direct |
| 🏗️ Grue en bois | `wood_crane` | commun | — | établi | usage direct |
| ⛓️ Herse | `portcullis` | commun | — | établi | usage direct |
| 🕰️ Horloge mécanique | `clock` | commun | — | établi | usage direct |
| 🌷 Jardinière | `planter` | commun | — | atelier | usage direct |
| 🏮 Lanterne | `lantern` | commun | — | établi | usage direct |
| 🕹️ Levier | `lever` | commun | — | atelier | usage direct |
| 🛏️ Lit | `bed` | commun | — | établi | usage direct |
| 🛏️ Lit double | `double_bed` | commun | — | établi | usage direct |
| 🌾 Mangeoire | `feeder` | commun | — | établi, atelier | usage direct |
| 🎯 Mannequin d'entraînement | `training_dummy` | commun | 71 | établi | usage direct |
| 🏰 Meurtrière | `arrow_slit` | commun | — | atelier | usage direct |
| 🌬️ Moulin | `windmill` | commun | — | établi | usage direct |
| 🧶 Métier à tisser | `loom` | commun | — | établi | usage direct |
| 🛏️ Paillasse | `straw_bed` | commun | — | atelier | usage direct |
| 🌲 Palissade | `palisade` | commun | — | atelier | usage direct |
| 🚩 Panneau de propriété | `claim` | commun | — | atelier | usage direct |
| 🖼️ Peinture murale | `painting_wall` | commun | — | atelier | usage direct |
| 🏺 Pichet | `pitcher` | commun | — | four | usage direct |
| ⛲ Pompe à eau | `water_pump` | commun | — | établi | usage direct |
| 🌉 Pont-levis | `drawbridge` | commun | — | établi | usage direct |
| 🐖 Porcherie | `pigsty` | commun | — | établi | usage direct |
| 🚪 Portail de ferme | `farm_gate` | commun | — | atelier | usage direct |
| 🏰 Porte de château | `castle_door` | commun | — | établi | usage direct |
| 🚪 Porte de grange | `barn_door` | commun | — | établi | usage direct |
| 🚪 Porte double | `double_door` | commun | — | établi | usage direct |
| 🛡️ Porte-armure | `armor_stand` | commun | — | établi | usage direct |
| 🌿 Pot de fleurs | `flowerpot` | commun | — | four | usage direct |
| 🏺 Pot en terre cuite | `clay_pot` | commun | — | atelier | usage direct |
| 🐔 Poulailler | `henhouse` | commun | — | établi | usage direct |
| 🍇 Presse | `press` | commun | — | établi | usage direct |
| 🧺 Puits | `well` | commun | — | établi | usage direct |
| 🛶 Radeau | `raft` | commun | — | atelier | usage direct |
| 🎭 Rideau | `curtain` | commun | — | atelier | usage direct |
| ⚙️ Roue à eau | `water_wheel` | commun | — | établi | usage direct |
| 🐝 Ruche | `beehive` | commun | — | établi | usage direct |
| 🌾 Râtelier à foin | `hay_rack` | commun | — | atelier | usage direct |
| 🗿 Sculpture | `sculpture` | commun | — | atelier | usage direct |
| 🧩 Serrure d'entraînement | `practice_lock` | commun | — | établi | usage direct |
| 🏛️ Socle | `pedestal` | commun | — | établi | usage direct |
| 🗿 Statue | `statue` | commun | — | atelier | usage direct |
| 🪑 Table | `table_wood` | commun | — | atelier | usage direct |
| 🪑 Tabouret | `stool` | commun | — | atelier | usage direct |
| 🟥 Tapis | `rug` | commun | — | atelier | usage direct |
| 🎨 Tenture | `tapestry` | commun | — | établi | usage direct |
| 🛢️ Tonneau | `barrel` | commun | — | établi | usage direct |
| 🔥 Torche murale | `wall_torch` | commun | — | atelier | usage direct |
| 🟫 Trappe en bois | `trapdoor` | commun | — | atelier | usage direct |
| 🛷 Traîneau | `sled` | commun | — | atelier | usage direct |
| ➰ Treuil | `winch` | commun | — | établi | usage direct |
| 🏆 Trophée | `trophy` | commun | — | atelier | usage direct |
| 🏺 Vase | `vase_deco` | commun | — | atelier | usage direct |
| 🖼️ Vitrail | `stained_glass` | commun | — | établi | usage direct |
| 🖼️ Volet | `shutter` | commun | — | atelier | usage direct |
| ➰ Échelle de corde | `rope_ladder` | commun | — | atelier | usage direct |
| 🔝 Échelle en bois | `ladder` | commun | — | atelier | usage direct |
| 🐎 Écurie | `horse_stable` | commun | — | établi | usage direct |
| 🎃 Épouvantail | `scarecrow` | commun | — | établi | usage direct |
| 🐄 Étable | `stable` | commun | — | établi | usage direct |
| 🛠️ Établi | `workbench` | commun | — | atelier | usage direct |
| 📚 Étagère | `shelf` | commun | — | atelier | usage direct |
| 🧰 Étagère à outils | `tool_rack` | commun | — | atelier | usage direct |
| 🏪 Étal de marché | `stall` | commun | — | établi | usage direct |

### Objets utilisables (114)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🔮 Artefact | `artifact` | légendaire | 600 | atelier | usage direct |
| 💍 Bague sertie | `ring_gem` | épique | 408 | établi | usage direct |
| ⚽ Ballon en cuir | `leather_ball` | peu commun | 49 | atelier | usage direct |
| 🧶 Ballot de tissu | `cloth_bale` | rare | 200 | atelier | usage direct |
| 🚩 Bannière de clan | `banniere` | rare | 97 | établi | usage direct |
| ⛵ Barque | `barque` | rare | 120 | établi | usage direct |
| 👜 Besace en toile | `canvas_bag` | épique | 255 | établi | usage direct |
| 🎟️ Billet de foire | `fair_ticket` | commun | 10 | atelier | usage direct |
| 👝 Bourse | `coin_purse` | peu commun | — | chasse, butin | usage direct |
| 👝 Bourse de marchand | `merchant_purse` | commun | — | événement, butin | usage direct |
| 🍾 Bouteille à la mer | `message_bottle` | rare | — | pêche | usage direct |
| 🌿 Bouture de saule | `seed_tree_saule` | commun | 4 | abattage | usage direct |
| 🎁 Boîte à bijoux | `jewel_box` | rare | 139 | établi | usage direct |
| 🖌️ Brosse | `brush` | commun | 11 | atelier | usage direct |
| 📦 Caisse de fruits | `fruit_crate` | rare | 90 | atelier | usage direct |
| 📓 Carnet du crocheteur | `manual_lock` | rare | 200 | établi | usage direct |
| 🗺️ Carte au trésor | `treasure_map` | commun | — | atelier, événement, chasse, butin | usage direct |
| 🗺️ Carte maritime | `sea_chart` | rare | 120 | atelier | usage direct |
| 🗺️ Carte régionale | `map_region` | peu commun | 40 | atelier | 1 recette, usage direct |
| ⭕ Cerceau | `hoop` | commun | 17 | atelier | usage direct |
| 🪁 Cerf-volant | `kite` | rare | 115 | atelier | usage direct |
| 🔔 Clochette | `bell_small` | commun | 33 | atelier | usage direct |
| 🔔 Clochette de troupeau | `herd_bell` | commun | 39 | atelier | usage direct |
| 🗝️ Clé ancienne | `ancient_key` | rare | 120 | trésor | usage direct |
| 📦 Coffre de ravitaillement | `supply_chest` | rare | 205 | établi | usage direct |
| 📃 Contrat de recrutement | `recruit_contract` | peu commun | 40 | atelier | usage direct |
| 📃 Contrat de vente | `contract` | peu commun | 29 | atelier | usage direct |
| 🐚 Coquillage rare | `rare_shell` | rare | 90 | pêche | usage direct |
| 📯 Corne d'appel | `horn_call` | commun | 60 | établi | usage direct |
| 👑 Couronne | `crown` | légendaire | 1629 | établi | usage direct |
| 🏺 Céramique décorée | `decorated_ceramic` | rare | 90 | four | usage direct |
| 📜 Diplôme d'apprentissage | `diploma` | rare | 102 | atelier | usage direct |
| 🪔 Encens | `incense` | commun | 20 | atelier | usage direct |
| 🌱 Engrais d'os | `bonemeal` | commun | 10 | atelier | usage direct |
| 🧲 Fers à cheval | `horseshoes` | rare | 122 | atelier | usage direct |
| 🗿 Figurine en bois | `wood_figurine` | peu commun | 25 | établi | usage direct |
| 🗿 Figurine en pierre | `stone_figurine` | peu commun | 30 | établi | usage direct |
| 🎶 Flûte | `flute` | commun | 40 | établi | usage direct |
| 🦴 Fossile | `fossil` | rare | 120 | minage, fouille | usage direct |
| ⛰️ Fragment d'inscription | `inscription` | épique | 50 | fouille | usage direct |
| 🧩 Fragment de relique | `relic_fragment` | rare | 40 | fouille, butin | 1 recette, usage direct |
| 🌰 Gland (chêne) | `seed_tree_chene` | commun | 4 | abattage | usage direct |
| 🏺 Gourde | `gourd` | commun | 21 | atelier | usage direct |
| 🌱 Graine de bouleau | `seed_tree_bouleau` | commun | 4 | abattage | usage direct |
| 🎼 Harpe | `harp` | épique | 240 | établi | usage direct |
| 🛡️ Insigne de garde | `guard_badge` | peu commun | 61 | établi, butin | usage direct |
| ⭐ Insigne de shérif | `sheriff_badge` | rare | 200 | événement | usage direct |
| 💰 Jeton d'événement | `event_token` | peu commun | 30 | événement | usage direct |
| 🃏 Jeu de cartes | `cards` | peu commun | 36 | atelier | usage direct |
| 🎲 Jeu de dés | `dice` | commun | 10 | atelier | usage direct |
| ♟️ Jeu de plateau | `board_game` | peu commun | 40 | atelier | usage direct |
| 🧸 Jouet en bois | `wood_toy` | peu commun | 20 | atelier | usage direct |
| 📔 Journal d'un voyageur | `traveler_journal` | commun | — | événement | usage direct |
| 📃 Lettre de change | `bill_exchange` | peu commun | — | événement | usage direct |
| ✉️ Lettre de recommandation | `recommendation` | peu commun | 60 | atelier, événement | usage direct |
| 📖 Livre de botanique | `botany_book` | rare | 160 | établi | usage direct |
| 🎶 Livre de chansons | `songbook` | peu commun | 60 | atelier | usage direct |
| 📕 Livre de compétence | `skill_book` | rare | 200 | établi | usage direct |
| 📖 Livre de recettes | `recipe_book` | rare | 160 | établi | usage direct |
| 📖 Livre des créatures | `creature_book` | rare | 180 | établi | usage direct |
| 📚 Livre rare | `rare_book` | épique | 400 | événement, trésor | usage direct |
| 🔭 Longue-vue | `spyglass` | épique | 220 | établi | usage direct |
| 🪕 Luth | `lute` | rare | 160 | établi | usage direct |
| 📗 Manuel d'agriculture | `manual_farm` | rare | 161 | établi | usage direct |
| 📓 Manuel d'artisanat | `manual_craft` | rare | 140 | établi | usage direct |
| 📗 Manuel d'élevage | `manual_herd` | rare | 120 | établi | usage direct |
| 📙 Manuel de cuisine | `manual_cook` | rare | 205 | établi | usage direct |
| 📒 Manuel de dressage | `manual_tame` | rare | 120 | établi | usage direct |
| 📘 Manuel de pêche | `manual_fish` | rare | 120 | établi | usage direct |
| 📔 Manuel du bûcheron | `manual_wood` | rare | 120 | établi | usage direct |
| 📔 Manuel du mineur | `manual_mine` | rare | 140 | établi | usage direct |
| 📦 Marchandise emballée | `packed_goods` | épique | 282 | atelier | usage direct |
| 🔍 Miroir de poche | `pocket_mirror` | rare | 97 | établi | usage direct |
| 🏅 Médaille de concours | `medal` | rare | 154 | établi | usage direct |
| 🧺 Nasse | `nasse` | commun | 35 | établi | usage direct |
| 🌾 Nourriture animale | `animal_feed` | commun | 15 | atelier | usage direct |
| 🍒 Noyau de cerise | `seed_tree_cerisier` | commun | 6 | abattage | usage direct |
| 🏺 Objet d'une ruine | `ruin_piece` | rare | 150 | événement | usage direct |
| ❔ Objet perdu | `lost_item` | peu commun | 30 | événement, cueillette, butin | usage direct |
| 🏺 Outre en cuir | `waterskin` | commun | 31 | établi | usage direct |
| 📜 Page ancienne | `old_page` | commun | 15 | minage, événement, fouille, trésor | 1 recette, usage direct |
| 🧺 Panier de légumes | `veg_basket` | rare | 201 | atelier | usage direct |
| 🌸 Parfum | `perfume` | rare | 90 | atelier | usage direct |
| 💈 Peigne | `comb` | commun | 8 | établi | usage direct |
| 📐 Plan d'artisan | `craftsman_plan` | commun | — | événement | usage direct |
| 🌲 Pomme de pin (sapin) | `seed_tree_sapin` | commun | 4 | abattage | usage direct |
| ✨ Poudre minérale | `mineral_powder` | commun | 14 | four | usage direct |
| 🧸 Poupée de chiffon | `rag_doll` | rare | 128 | atelier | usage direct |
| 📜 Recette inconnue | `unknown_recipe` | commun | — | événement | usage direct |
| 📒 Registre commercial | `ledger` | commun | 51 | établi | usage direct |
| 📒 Registre de patrouille | `patrol_log` | peu commun | 30 | atelier | usage direct |
| 🏺 Relique | `relic` | épique | 300 | événement, trésor | usage direct |
| 🏆 Ruban de champion | `champion_ribbon` | rare | 200 | événement | usage direct |
| 🎁 Récompense de festival | `festival_prize` | commun | — | événement | usage direct |
| 🛍️ Sac d'épices | `spice_sack` | épique | 330 | atelier | usage direct |
| 🌱 Sac de compost | `compost` | commun | 8 | atelier | usage direct |
| 🛍️ Sac de farine | `flour_sack` | rare | 170 | atelier | usage direct |
| 🛍️ Sac de graines | `seed_sack` | rare | 137 | atelier | usage direct |
| 👜 Sac de marchand | `merchant_bag` | épique | 585 | établi | usage direct |
| 🛍️ Sac de sel | `salt_sack` | rare | 163 | atelier | usage direct |
| 👜 Sacoche en cuir | `satchel` | peu commun | 62 | établi | usage direct |
| 🧼 Savon | `soap` | commun | 17 | atelier | usage direct |
| 🔴 Sceau | `seal` | peu commun | 44 | établi | usage direct |
| 👑 Sceau royal | `royal_seal` | épique | 500 | événement, butin, boss | usage direct |
| 💧 Seau d'eau | `bucket` | commun | 22 | code:Machines | 2 recettes, usage direct |
| 🧺 Seau vide | `bucket_empty` | commun | 38 | atelier | 1 recette, usage direct |
| 🧺 Serviette en lin | `towel` | rare | 111 | atelier | usage direct |
| 🧿 Talisman | `talisman` | peu commun | — | événement | usage direct |
| 🥁 Tambour | `drum` | rare | 80 | établi | usage direct |
| 🎺 Trompette | `trumpet` | rare | 140 | établi | usage direct |
| 🧰 Trousse d'artisan | `craft_kit` | rare | 95 | établi | usage direct |
| 🏺 Vase ancien | `old_vase` | rare | 160 | événement, trésor | usage direct |
| ⛵ Voilier | `voilier` | légendaire | 1330 | établi | usage direct |
| 🥚 Œuf mystérieux | `mystery_egg` | épique | — | chasse | usage direct |

### Outils et armes (21)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🚿 Arrosoir | `can` | peu commun | 40 | atelier, boutique | usage direct |
| ⛏ Bêche de terrassier | `spade` | rare | 90 | atelier | usage direct |
| 🎣 Canne à pêche | `rod` | peu commun | 50 | atelier, boutique | usage direct |
| 🏏 Gourdin | `club` | peu commun | 20 | atelier | usage direct |
| 💎 Hache au diamant | `axe_diamond` | légendaire | 1700 | atelier | usage direct |
| 🪓 Hache de cuivre | `axe_cu` | rare | 140 | atelier | usage direct |
| 🪓 Hache de fer | `axe_fe` | épique | 260 | atelier | usage direct |
| 🪓 Hache de pierre | `axe` | peu commun | 60 | atelier, boutique | usage direct |
| 🪓 Hache d’acier | `axe_steel` | épique | 440 | atelier | 1 recette, usage direct |
| 🔱 Harpon de pêche | `harpoon` | rare | 85 | atelier | usage direct |
| ⛏ Houe | `hoe` | peu commun | 40 | atelier, boutique | usage direct |
| 🧺 Pelle | `shovel` | peu commun | 50 | atelier, boutique | usage direct |
| 💎 Pioche au diamant | `pickaxe_diamond` | légendaire | 1850 | atelier | usage direct |
| ⛏️ Pioche de cuivre | `pickaxe_cu` | rare | 140 | atelier | usage direct |
| ⛏️ Pioche de fer | `pickaxe_fe` | épique | 260 | atelier | usage direct |
| ⛏️ Pioche de pierre | `pickaxe` | peu commun | 60 | atelier, boutique | usage direct |
| ⛏️ Pioche d’acier | `pickaxe_steel` | épique | 460 | atelier | 1 recette, usage direct |
| 🗡️ Épée de cuivre | `sword` | rare | 150 | atelier, boutique | usage direct |
| ⚔️ Épée de fer | `sword_fe` | épique | 320 | atelier | usage direct |
| ⚔️ Épée forgée en acier | `sword_steel` | épique | 530 | atelier | 1 recette, usage direct |
| 💎 Épée sertie de diamant | `sword_diamond` | légendaire | 2300 | atelier | usage direct |

### Pièces de construction (169)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🌉 Arche (Bois) | `blk_arche_bois` | commun | 9 | atelier | usage direct |
| 🌉 Arche (Brique) | `blk_arche_brique` | commun | 27 | établi | usage direct |
| 🌉 Arche (Pierre taillée) | `blk_arche_taille` | commun | 27 | établi | usage direct |
| 🌉 Arche (Pierre) | `blk_arche_pierre` | commun | 18 | établi | usage direct |
| ➖ Barrière (Bois) | `blk_barriere_bois` | commun | 3 | atelier | usage direct |
| ➖ Barrière (Fer) | `blk_barriere_fer` | commun | 50 | établi | usage direct |
| ⬛ Bloc (Bois) | `blk_bloc_bois` | commun | 5 | atelier | usage direct |
| ⬛ Bloc (Brique) | `blk_bloc_brique` | commun | 14 | établi | usage direct |
| ⬛ Bloc (Pierre taillée) | `blk_bloc_taille` | commun | 14 | établi | usage direct |
| ⬛ Bloc (Pierre) | `blk_bloc_pierre` | commun | 9 | établi | usage direct |
| ⬛ Bloc (Pisé) | `blk_bloc_pise` | commun | 5 | atelier | usage direct |
| ⬛ Bloc (Rondins) | `blk_bloc_rondin` | commun | 9 | atelier | usage direct |
| ⬛ Bloc (Torchis) | `blk_bloc_torchis` | commun | 9 | atelier | usage direct |
| ⬛ Bloc (Verre) | `blk_bloc_verre` | commun | 18 | établi | usage direct |
| 🏛️ Chapiteau (Bois) | `blk_chapiteau_bois` | commun | 5 | atelier | usage direct |
| 🏛️ Chapiteau (Pierre taillée) | `blk_chapiteau_taille` | commun | 14 | établi | usage direct |
| 🏛️ Chapiteau (Pierre) | `blk_chapiteau_pierre` | commun | 9 | établi | usage direct |
| 🧱 Cloison (Bois) | `blk_mince_bois` | commun | 3 | atelier | usage direct |
| 🧱 Cloison (Torchis) | `blk_mince_torchis` | commun | 5 | atelier | usage direct |
| 🧱 Cloison (Verre) | `blk_mince_verre` | commun | 9 | établi | usage direct |
| 🔺 Coin de toit (Ardoise) | `blk_coin_ardoise` | commun | 9 | établi | usage direct |
| 🔺 Coin de toit (Bardeaux) | `blk_coin_bardeau` | commun | 9 | établi | usage direct |
| 🔺 Coin de toit (Bois) | `blk_coin_bois` | commun | 5 | atelier | usage direct |
| 🔺 Coin de toit (Chaume) | `blk_coin_chaume` | commun | 5 | atelier | usage direct |
| 🔺 Coin de toit (Pierre) | `blk_coin_pierre` | commun | 9 | établi | usage direct |
| 🔺 Coin de toit (Tuiles) | `blk_coin_tuile` | commun | 14 | établi | usage direct |
| 🏛️ Colonne (Brique) | `blk_colonne_brique` | commun | 27 | établi | usage direct |
| 🏛️ Colonne (Pierre taillée) | `blk_colonne_taille` | commun | 27 | établi | usage direct |
| 🏛️ Colonne (Pierre) | `blk_colonne_pierre` | commun | 18 | établi | usage direct |
| 🏰 Créneaux (Bois) | `blk_creneaux_bois` | commun | 7 | atelier | usage direct |
| 🏰 Créneaux (Brique) | `blk_creneaux_brique` | commun | 20 | établi | usage direct |
| 🏰 Créneaux (Pierre taillée) | `blk_creneaux_taille` | commun | 20 | établi | usage direct |
| 🏰 Créneaux (Pierre) | `blk_creneaux_pierre` | commun | 14 | établi | usage direct |
| 🟫 Dalle (Ardoise) | `blk_dalle_ardoise` | commun | 5 | établi | usage direct |
| 🟫 Dalle (Bardeaux) | `blk_dalle_bardeau` | commun | 5 | établi | usage direct |
| 🟫 Dalle (Bois) | `blk_dalle_bois` | commun | 3 | atelier | usage direct |
| 🟫 Dalle (Chaume) | `blk_dalle_chaume` | commun | 3 | atelier | usage direct |
| 🟫 Dalle (Pierre taillée) | `blk_dalle_taille` | commun | 7 | établi | usage direct |
| 🟫 Dalle (Pierre) | `blk_dalle_pierre` | commun | 5 | établi | usage direct |
| 🟫 Dalle (Pisé) | `blk_dalle_pise` | commun | 3 | atelier | usage direct |
| 🟫 Dalle (Tuiles) | `blk_dalle_tuile` | commun | 7 | établi | usage direct |
| 🔵 Dôme (Ardoise) | `blk_dome_ardoise` | commun | 22 | établi | usage direct |
| 🔵 Dôme (Brique) | `blk_dome_brique` | commun | 33 | établi | usage direct |
| 🔵 Dôme (Fer) | `blk_dome_fer` | épique | 248 | établi | usage direct |
| 🔵 Dôme (Pierre taillée) | `blk_dome_taille` | commun | 33 | établi | usage direct |
| 🔵 Dôme (Pierre) | `blk_dome_pierre` | commun | 22 | établi | usage direct |
| 🔵 Dôme (Tuiles) | `blk_dome_tuile` | commun | 33 | établi | usage direct |
| 🔵 Dôme (Verre) | `blk_dome_verre` | commun | 44 | établi | usage direct |
| 🔝 Escalier | `stairs` | commun | — | ? | usage direct |
| 📐 Escalier droit (Bois) | `blk_escalier_bois` | commun | 9 | atelier | usage direct |
| 📐 Escalier droit (Brique) | `blk_escalier_brique` | commun | 27 | établi | usage direct |
| 📐 Escalier droit (Pierre taillée) | `blk_escalier_taille` | commun | 27 | établi | usage direct |
| 📐 Escalier droit (Pierre) | `blk_escalier_pierre` | commun | 18 | établi | usage direct |
| 🌀 Escalier en colimaçon (Bois) | `blk_colimacon_bois` | commun | 18 | atelier | usage direct |
| 🌀 Escalier en colimaçon (Pierre taillée) | `blk_colimacon_taille` | commun | 53 | établi | usage direct |
| 🌀 Escalier en colimaçon (Pierre) | `blk_colimacon_pierre` | commun | 36 | établi | usage direct |
| 🧱 Grand mur (Bois) | `blk_grandmur_bois` | commun | 11 | atelier | usage direct |
| 🧱 Grand mur (Brique) | `blk_grandmur_brique` | commun | 33 | établi | usage direct |
| 🧱 Grand mur (Pierre taillée) | `blk_grandmur_taille` | commun | 33 | établi | usage direct |
| 🧱 Grand mur (Pierre) | `blk_grandmur_pierre` | commun | 22 | établi | usage direct |
| 🧱 Grand mur (Pisé) | `blk_grandmur_pise` | commun | 11 | atelier | usage direct |
| 🧱 Grand mur (Rondins) | `blk_grandmur_rondin` | commun | 22 | atelier | usage direct |
| 🧱 Grand mur (Torchis) | `blk_grandmur_torchis` | commun | 22 | atelier | usage direct |
| 🏛️ Grand poteau (Bois) | `blk_hautpoteau_bois` | commun | 5 | atelier | usage direct |
| 🏛️ Grand poteau (Fer) | `blk_hautpoteau_fer` | rare | 100 | établi | usage direct |
| 🏛️ Grand poteau (Rondins) | `blk_hautpoteau_rondin` | commun | 9 | atelier | usage direct |
| 🟫 Grande dalle (Bois) | `blk_plancher_bois` | commun | 5 | atelier | usage direct |
| 🟫 Grande dalle (Pierre taillée) | `blk_plancher_taille` | commun | 14 | établi | usage direct |
| 🟫 Grande dalle (Pierre) | `blk_plancher_pierre` | commun | 9 | établi | usage direct |
| 🧱 Grande échelle (Bois) | `blk_grandeechelle_bois` | commun | 7 | atelier | usage direct |
| 🧱 Grande échelle (Fer) | `blk_grandeechelle_fer` | rare | 149 | établi | usage direct |
| 🧱 Grande échelle (Rondins) | `blk_grandeechelle_rondin` | commun | 14 | atelier | usage direct |
| 🔲 Grille (Fer) | `blk_grille_fer` | rare | 100 | établi | usage direct |
| 📏 Linteau (Bois) | `blk_linteau_bois` | commun | 3 | atelier | usage direct |
| 📏 Linteau (Fer) | `blk_linteau_fer` | commun | 50 | établi | usage direct |
| 📏 Linteau (Pierre taillée) | `blk_linteau_taille` | commun | 7 | établi | usage direct |
| 📏 Linteau (Pierre) | `blk_linteau_pierre` | commun | 5 | établi | usage direct |
| 📐 Marche (Bois) | `blk_marche_bois` | commun | 3 | atelier | usage direct |
| 📐 Marche (Pierre taillée) | `blk_marche_taille` | commun | 7 | établi | usage direct |
| 📐 Marche (Pierre) | `blk_marche_pierre` | commun | 5 | établi | usage direct |
| 🖼️ Mur avec fenêtre | `wall_window` | commun | — | ? | usage direct |
| 🔳 Mur avec fenêtre (Bois) | `blk_murfenetre_bois` | commun | 7 | atelier | usage direct |
| 🔳 Mur avec fenêtre (Brique) | `blk_murfenetre_brique` | commun | 20 | établi | usage direct |
| 🔳 Mur avec fenêtre (Pierre taillée) | `blk_murfenetre_taille` | commun | 20 | établi | usage direct |
| 🔳 Mur avec fenêtre (Pierre) | `blk_murfenetre_pierre` | commun | 14 | établi | usage direct |
| 🔳 Mur avec fenêtre (Pisé) | `blk_murfenetre_pise` | commun | 7 | atelier | usage direct |
| 🔳 Mur avec fenêtre (Rondins) | `blk_murfenetre_rondin` | commun | 14 | atelier | usage direct |
| 🔳 Mur avec fenêtre (Torchis) | `blk_murfenetre_torchis` | commun | 14 | atelier | usage direct |
| 🚪 Mur avec porte | `wall_door` | commun | — | ? | usage direct |
| 🚪 Mur avec porte (Bois) | `blk_murporte_bois` | commun | 7 | atelier | usage direct |
| 🚪 Mur avec porte (Brique) | `blk_murporte_brique` | commun | 20 | établi | usage direct |
| 🚪 Mur avec porte (Pierre taillée) | `blk_murporte_taille` | commun | 20 | établi | usage direct |
| 🚪 Mur avec porte (Pierre) | `blk_murporte_pierre` | commun | 14 | établi | usage direct |
| 🚪 Mur avec porte (Pisé) | `blk_murporte_pise` | commun | 7 | atelier | usage direct |
| 🚪 Mur avec porte (Rondins) | `blk_murporte_rondin` | commun | 14 | atelier | usage direct |
| 🚪 Mur avec porte (Torchis) | `blk_murporte_torchis` | commun | 14 | atelier | usage direct |
| 🧱 Mur courbe (Bois) | `blk_murcourbe_bois` | commun | 11 | atelier | usage direct |
| 🧱 Mur courbe (Brique) | `blk_murcourbe_brique` | commun | 33 | établi | usage direct |
| 🧱 Mur courbe (Pierre taillée) | `blk_murcourbe_taille` | commun | 33 | établi | usage direct |
| 🧱 Mur courbe (Pierre) | `blk_murcourbe_pierre` | commun | 22 | établi | usage direct |
| 🧱 Mur courbe (Torchis) | `blk_murcourbe_torchis` | commun | 22 | atelier | usage direct |
| 🧱 Mur d'étage | `wall2` | commun | — | ? | usage direct |
| 🖼️ Mur d'étage avec fenêtre | `wall2_window` | commun | — | ? | usage direct |
| 🧱 Mur de briques | `wall_brick` | commun | — | ? | usage direct |
| 🧱 Mur de pierre | `wall_stone` | commun | — | ? | usage direct |
| 🚪 Mur en planches | `wall` | commun | — | ? | usage direct |
| 🏰 Mur à meurtrière (Brique) | `blk_meurtriere_brique` | commun | 20 | établi | usage direct |
| 🏰 Mur à meurtrière (Pierre taillée) | `blk_meurtriere_taille` | commun | 20 | établi | usage direct |
| 🏰 Mur à meurtrière (Pierre) | `blk_meurtriere_pierre` | commun | 14 | établi | usage direct |
| 🧱 Muret (Bois) | `blk_demimur_bois` | commun | 5 | atelier | usage direct |
| 🧱 Muret (Brique) | `blk_demimur_brique` | commun | 14 | établi | usage direct |
| 🧱 Muret (Pierre taillée) | `blk_demimur_taille` | commun | 14 | établi | usage direct |
| 🧱 Muret (Pierre) | `blk_demimur_pierre` | commun | 9 | établi | usage direct |
| 🧱 Muret (Pisé) | `blk_demimur_pise` | commun | 5 | atelier | usage direct |
| 🧱 Muret (Rondins) | `blk_demimur_rondin` | commun | 9 | atelier | usage direct |
| 🧱 Pan de mur (Bois) | `blk_mur_bois` | commun | 7 | atelier | usage direct |
| 🧱 Pan de mur (Brique) | `blk_mur_brique` | commun | 20 | établi | usage direct |
| 🧱 Pan de mur (Pierre taillée) | `blk_mur_taille` | commun | 20 | établi | usage direct |
| 🧱 Pan de mur (Pierre) | `blk_mur_pierre` | commun | 14 | établi | usage direct |
| 🧱 Pan de mur (Pisé) | `blk_mur_pise` | commun | 7 | atelier | usage direct |
| 🧱 Pan de mur (Rondins) | `blk_mur_rondin` | commun | 14 | atelier | usage direct |
| 🧱 Pan de mur (Torchis) | `blk_mur_torchis` | commun | 14 | atelier | usage direct |
| 🧱 Pan de mur (Verre) | `blk_mur_verre` | commun | 27 | établi | usage direct |
| 🔺 Pente de toit (Ardoise) | `blk_pente_ardoise` | commun | 14 | établi | usage direct |
| 🔺 Pente de toit (Bardeaux) | `blk_pente_bardeau` | commun | 14 | établi | usage direct |
| 🔺 Pente de toit (Bois) | `blk_pente_bois` | commun | 7 | atelier | usage direct |
| 🔺 Pente de toit (Chaume) | `blk_pente_chaume` | commun | 7 | atelier | usage direct |
| 🔺 Pente de toit (Pierre) | `blk_pente_pierre` | commun | 14 | établi | usage direct |
| 🔺 Pente de toit (Tuiles) | `blk_pente_tuile` | commun | 20 | établi | usage direct |
| 🔺 Pente raide (Ardoise) | `blk_toitpointu_ardoise` | commun | 9 | établi | usage direct |
| 🔺 Pente raide (Bardeaux) | `blk_toitpointu_bardeau` | commun | 9 | établi | usage direct |
| 🔺 Pente raide (Bois) | `blk_toitpointu_bois` | commun | 5 | atelier | usage direct |
| 🔺 Pente raide (Chaume) | `blk_toitpointu_chaume` | commun | 5 | atelier | usage direct |
| 🔺 Pente raide (Pierre taillée) | `blk_toitpointu_taille` | commun | 14 | établi | usage direct |
| 🔺 Pente raide (Tuiles) | `blk_toitpointu_tuile` | commun | 14 | établi | usage direct |
| 🔺 Pignon (mur triangulaire) (Bois) | `blk_pignon_bois` | commun | 5 | atelier | usage direct |
| 🔺 Pignon (mur triangulaire) (Brique) | `blk_pignon_brique` | commun | 14 | établi | usage direct |
| 🔺 Pignon (mur triangulaire) (Pierre taillée) | `blk_pignon_taille` | commun | 14 | établi | usage direct |
| 🔺 Pignon (mur triangulaire) (Pierre) | `blk_pignon_pierre` | commun | 9 | établi | usage direct |
| 🔺 Pignon (mur triangulaire) (Pisé) | `blk_pignon_pise` | commun | 5 | atelier | usage direct |
| 🔺 Pignon (mur triangulaire) (Torchis) | `blk_pignon_torchis` | commun | 9 | atelier | usage direct |
| 🏛️ Pilier rond (Bois) | `blk_pilier_bois` | commun | 5 | atelier | usage direct |
| 🏛️ Pilier rond (Brique) | `blk_pilier_brique` | commun | 14 | établi | usage direct |
| 🏛️ Pilier rond (Pierre taillée) | `blk_pilier_taille` | commun | 14 | établi | usage direct |
| 🏛️ Pilier rond (Pierre) | `blk_pilier_pierre` | commun | 9 | établi | usage direct |
| 🏛️ Pilier rond (Rondins) | `blk_pilier_rondin` | commun | 9 | atelier | usage direct |
| 🟫 Plancher | `floor` | commun | — | code:Shop | usage direct |
| 🟫 Plancher d'étage | `floor2` | commun | — | ? | usage direct |
| 🚪 Porte en bois | `door` | commun | — | établi | usage direct |
| 🏛️ Poteau (Bois) | `blk_poteau_bois` | commun | 3 | atelier | usage direct |
| 🏛️ Poteau (Fer) | `blk_poteau_fer` | commun | 50 | établi | usage direct |
| 🏛️ Poteau (Rondins) | `blk_poteau_rondin` | commun | 5 | atelier | usage direct |
| 📏 Poutre (Bois) | `blk_poutre_bois` | commun | 3 | atelier | usage direct |
| 📏 Poutre (Fer) | `blk_poutre_fer` | commun | 50 | établi | usage direct |
| 📏 Poutre (Pierre) | `blk_poutre_pierre` | commun | 5 | établi | usage direct |
| 📏 Poutre (Rondins) | `blk_poutre_rondin` | commun | 5 | atelier | usage direct |
| 📐 Rampe / marches (Bois) | `blk_rampe_bois` | commun | 9 | atelier | usage direct |
| 📐 Rampe / marches (Pierre taillée) | `blk_rampe_taille` | commun | 27 | établi | usage direct |
| 📐 Rampe / marches (Pierre) | `blk_rampe_pierre` | commun | 18 | établi | usage direct |
| ⛺ Toit conique (Ardoise) | `blk_toitconique_ardoise` | commun | 22 | établi | usage direct |
| ⛺ Toit conique (Bardeaux) | `blk_toitconique_bardeau` | commun | 22 | établi | usage direct |
| ⛺ Toit conique (Bois) | `blk_toitconique_bois` | commun | 11 | atelier | usage direct |
| ⛺ Toit conique (Chaume) | `blk_toitconique_chaume` | commun | 11 | atelier | usage direct |
| ⛺ Toit conique (Tuiles) | `blk_toitconique_tuile` | commun | 33 | établi | usage direct |
| 🏠 Toit d'étage | `roof2` | commun | — | code:Shop | usage direct |
| 🏠 Toit de chaume | `roof` | commun | — | code:Shop | usage direct |
| 🧱 Échelle (Bois) | `blk_echelle_bois` | commun | 5 | atelier | usage direct |
| 🧱 Échelle (Fer) | `blk_echelle_fer` | rare | 100 | établi | usage direct |
| 🧱 Échelle (Rondins) | `blk_echelle_rondin` | commun | 9 | atelier | usage direct |

### Ressources et matières (365)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🔩 Acier | `steel` | rare | 115 | four, butin | 110 recettes |
| 🔩 Acier damassé | `damascus_steel` | épique | 269 | four | 2 recettes |
| 📌 Aiguille à coudre | `sewing_needle` | commun | 60 | atelier | code:Equilibre |
| 🦇 Aile membraneuse de chauve-souris des cavernes | `prise_cave_bat` | commun | 16 | code:Prises | 1 recette |
| 🦇 Aile membraneuse de chauve-souris géante | `prise_giant_bat` | commun | 21 | code:Prises | 1 recette |
| 🏺 Amphore | `amphora` | commun | 40 | four | 3 recettes |
| ⭕ Anneau métallique | `iron_ring` | commun | 13 | four, butin | 42 recettes |
| 🐛 Appâts | `bait` | commun | 2 | atelier, butin | code:Equilibre |
| 🟤 Argile | `clay` | commun | 4 | butin | 12 recettes |
| 🟤 Argile préparée | `prepared_clay` | commun | 10 | atelier | 7 recettes |
| 🍽️ Assiette | `plate` | commun | 10 | four | code:GearDesign |
| 🍽️ Assiette en bois | `wood_plate` | commun | 2 | établi | code:Joueurs |
| 📜 Avis de recherche de chasseur de primes | `prise_bounty_hunter` | commun | 36 | code:Prises | 1 recette |
| 🦯 Barre de fer | `iron_bar` | rare | 100 | four | 31 recettes |
| 🌲 Bois | `wood` | commun | 2 | butin | 29 recettes |
| 🦌 Bois de cerf | `prise_deer` | commun | 11 | code:Prises | 1 recette |
| 🦌 Bois de cerf | `antler` | commun | 24 | butin | 2 recettes |
| 🦌 Bois de cerf corrompu | `prise_corrupted_stag` | commun | 31 | code:Prises | 1 recette |
| 🦌 Bois de cerf spectral | `prise_spectral_stag` | commun | 31 | code:Prises | 1 recette |
| 🥣 Bol | `bowl` | commun | 8 | four | 1 recette |
| 🐫 Bosse de graisse de chameau | `prise_camel` | commun | 11 | code:Prises | 1 recette |
| 🔘 Boucle | `buckle` | commun | 14 | atelier | 18 recettes |
| 🕯️ Bougie (cire) | `candle_wax` | commun | 10 | atelier | 2 recettes |
| 🍾 Bouteille en verre | `bottle` | commun | 12 | four | 3 recettes |
| 🌿 Branches | `branches` | commun | 1 | abattage | 10 recettes |
| 🧱 Brique | `brick` | commun | 6 | four | 23 recettes |
| 🌼 Camomille | `chamomile` | commun | 6 | cueillette | 3 recettes |
| 🌑 Cape d'ombre de rôdeur obscur | `prise_dark_prowler` | commun | 31 | code:Prises | 1 recette |
| 🐢 Carapace de tortue ancienne | `prise_ancient_turtle` | rare | 96 | code:Prises | 1 recette |
| 🐞 Carapace dorée (Scarabée royal) | `golden_carapace` | légendaire | 800 | boss | 1 recette |
| 🏹 Carquois de chasseur de lune | `prise_moon_hunter` | commun | 36 | code:Prises | 1 recette |
| 🏹 Carquois de chasseur nocturne | `prise_night_stalker` | commun | 31 | code:Prises | 1 recette |
| 📌 Carreaux | `bolt` | commun | 5 | établi, boutique | code:Equilibre |
| 🔱 Carreaux de baliste | `bolt_heavy` | commun | 33 | établi, boutique | code:Equilibre |
| 🧟 Chair pourrie | `rotten` | commun | 1 | butin | 2 recettes |
| 🍄 Champignon phosphorescent | `glow_mushroom` | rare | 80 | cueillette de nuit | code:Froid |
| 🍄 Champignon rare | `rare_mushroom` | peu commun | 60 | cueillette | 1 recette |
| ⚫ Charbon | `coal` | commun | 7 | four, boutique, butin | 13 recettes |
| 🔩 Charnière | `hinge` | commun | 24 | atelier | 9 recettes |
| ⛓️ Chaîne | `chain` | rare | 100 | atelier | 4 recettes |
| 🌲 Chevilles en bois | `peg` | commun | 1 | atelier | 2 recettes |
| 🍺 Chope en métal | `tankard` | commun | 66 | atelier | 1 recette |
| 🍺 Chope en terre cuite | `mug` | commun | 11 | four | 3 recettes |
| 🕯️ Cire d'abeille | `beeswax` | commun | 17 | atelier, butin | 2 recettes |
| 🗡️ Ciseau de tailleur | `chisel` | commun | 60 | atelier | code:Equilibre |
| 📌 Clous | `nails` | commun | 5 | atelier | 13 recettes |
| 📌 Clous de cuivre | `copper_nails` | commun | 3 | atelier | 26 recettes |
| ➰ Collet de braconnier | `prise_poacher` | commun | 21 | code:Prises | 1 recette |
| 🐕 Collier clouté | `spiked_collar` | rare | 90 | atelier | code:Equilibre |
| 📿 Collier de chien | `dog_collar` | commun | 64 | établi | code:Compagnons |
| ➰ Corde | `rope` | commun | 5 | atelier, boutique, butin | 169 recettes |
| ➰ Corde tressée | `braided_rope` | commun | 17 | établi | 25 recettes |
| 📯 Corne | `horn` | commun | 20 | chasse, butin | 3 recettes |
| 🐂 Corne d'homme-taureau | `prise_bull_man` | rare | 111 | code:Prises | 1 recette |
| 🔪 Couteau de lancer | `throwing_knife` | commun | 9 | atelier | code:Equilibre |
| 🐴 Crin de kelpie | `prise_kelpie` | commun | 36 | code:Prises | 1 recette |
| 💎 Cristal ancien | `ancient_crystal` | épique | 260 | minage, butin | 1 recette |
| ❄️ Cristal de givre (Brumeglace) | `frost_crystal` | légendaire | 800 | boss | 2 recettes |
| 🧊 Cristal de glace | `ice_crystal` | commun | 40 | butin, boss | 2 recettes |
| 🦴 Croc d'hyène monstrueuse | `prise_hyena` | commun | 31 | code:Prises | 1 recette |
| 🐺 Croc de Vargor | `prise_vargor` | épique | 276 | code:Prises | 2 recettes |
| 🦴 Croc de chacal | `prise_jackal` | commun | 16 | code:Prises | 1 recette |
| 🦴 Croc de chien errant | `prise_stray_dog` | commun | 11 | code:Prises | 1 recette |
| 🦴 Croc de chien sauvage | `prise_wild_dog` | commun | 16 | code:Prises | 1 recette |
| 🐺 Croc de hurleur nocturne | `prise_night_howler` | commun | 31 | code:Prises | 1 recette |
| 🐺 Croc de loup | `prise_wolf` | commun | 16 | code:Prises | 1 recette |
| 🐺 Croc de loup blanc | `prise_wolf_white` | commun | 26 | code:Prises | 1 recette |
| 🐺 Croc de loup des ombres | `prise_shadow_wolf` | commun | 31 | code:Prises | 1 recette |
| 🐺 Croc de loup noir | `prise_black_wolf` | commun | 26 | code:Prises | 1 recette |
| 🐺 Croc de loup polaire | `prise_polar_wolf` | commun | 26 | code:Prises | 1 recette |
| 🦴 Croc de lynx | `prise_lynx` | commun | 21 | code:Prises | 1 recette |
| 🎣 Crochet | `lockpick` | commun | 15 | établi, atelier, butin | 2 recettes |
| 🗝️ Crochet de cambrioleur | `prise_burglar` | commun | 21 | code:Prises | 1 recette |
| 🏺 Cruche | `jug` | commun | 22 | four | code:Shop |
| 🥄 Cuillère en bois | `spoon` | commun | 1 | atelier | code:Shop |
| 🟫 Cuir | `leather` | commun | 14 | atelier, butin | 161 recettes |
| 🟫 Cuir souple | `soft_leather` | commun | 51 | atelier | 108 recettes |
| 💠 Cœur d'ent corrompu | `prise_corrupted_ent` | rare | 111 | code:Prises | 1 recette |
| 💠 Cœur de colosse de pierre | `prise_stone_golem` | rare | 126 | code:Prises | 1 recette |
| 💠 Cœur de colosse de terre | `prise_earth_colossus` | rare | 126 | code:Prises | 1 recette |
| 💠 Cœur de gardien de granit | `prise_granite_warden` | rare | 126 | code:Prises | 1 recette |
| 💠 Cœur de gardien des ruines | `prise_ruin_guardian` | rare | 111 | code:Prises | 1 recette |
| 💠 Cœur de gardien des tombes | `prise_tomb_warden` | rare | 111 | code:Prises | 1 recette |
| 💠 Cœur de gardien du lac | `prise_lake_guardian` | rare | 111 | code:Prises | 1 recette |
| 💠 Cœur de gardien maudit | `prise_cursed_warden` | rare | 111 | code:Prises | 1 recette |
| 💠 Cœur de golem de bois | `prise_wood_golem` | commun | 36 | code:Prises | 1 recette |
| 💠 Cœur de golem de glace | `prise_ice_golem` | commun | 36 | code:Prises | 1 recette |
| 💠 Cœur de golem de grès | `prise_sandstone_golem` | rare | 111 | code:Prises | 1 recette |
| 💠 Cœur de la Mère des Ronces | `prise_bramble_mother` | épique | 276 | code:Prises | 2 recettes |
| 💠 Cœur du Colosse de Verre | `prise_glass_colossus` | épique | 276 | code:Prises | 2 recettes |
| 💠 Cœur du Gardien des Moissons | `prise_harvest_warden` | rare | 216 | code:Prises | 2 recettes |
| ❄️ Cœur gelé | `frozen_heart` | légendaire | 600 | boss | 1 recette |
| 🦂 Dard de scorpion | `stinger` | commun | 25 | butin | 1 recette |
| 🦂 Dard de scorpion | `prise_scorpion` | commun | 26 | code:Prises | 1 recette |
| 🦷 Dent | `tooth` | commun | 6 | chasse, butin, boss | 1 recette |
| 🦷 Dent de monstre | `monster_tooth` | commun | 60 | chasse, butin | 2 recettes |
| 🐗 Défense de sanglier | `prise_boar` | commun | 16 | code:Prises | 1 recette |
| 🐗 Défense de sanglier colossal | `prise_colossal_boar` | rare | 96 | code:Prises | 1 recette |
| 🐗 Défense de sanglier des marécages | `prise_swamp_boar` | commun | 26 | code:Prises | 1 recette |
| 🐗 Défense de sanglier givré | `prise_frost_boar` | commun | 31 | code:Prises | 1 recette |
| 🖋️ Encre | `ink` | commun | 8 | atelier | 49 recettes |
| 🖋️ Encrier | `inkwell` | commun | 18 | établi | 1 recette |
| ⚙️ Engrenage en bois | `gear_wood` | commun | 14 | établi | 4 recettes |
| ⚙️ Engrenage en fer | `gear_iron` | rare | 149 | atelier | 4 recettes |
| 👻 Essence d'assassin de l'ombre | `prise_assassin` | commun | 36 | code:Prises | 1 recette |
| 👻 Essence d'esprit de l'orage | `prise_storm_wraith` | rare | 111 | code:Prises | 1 recette |
| 👻 Essence d'esprit des arbres | `prise_tree_spirit` | commun | 31 | code:Prises | 1 recette |
| 👻 Essence d'esprit des bois | `prise_woods_spirit` | commun | 31 | code:Prises | 1 recette |
| 👻 Essence d'esprit des eaux | `prise_water_spirit` | commun | 31 | code:Prises | 1 recette |
| 👻 Essence d'esprit des ruines | `prise_ruin_spirit` | commun | 31 | code:Prises | 1 recette |
| 👻 Essence d'esprit noyé | `prise_drowned_spirit` | commun | 26 | code:Prises | 1 recette |
| 👻 Essence d'ombre possédée | `prise_possessed_shade` | commun | 36 | code:Prises | 1 recette |
| 👻 Essence d'ombre rampante | `prise_creeping_shadow` | commun | 31 | code:Prises | 1 recette |
| 👻 Essence d'ombre rôdeuse | `prise_shade` | commun | 21 | code:Prises | 1 recette |
| 👻 Essence de Brumeglace | `prise_brumeglace` | épique | 306 | code:Prises | 2 recettes |
| 👻 Essence de feu follet | `prise_wisp` | commun | 21 | code:Prises | 1 recette |
| 👻 Essence de marcheur sans visage | `prise_faceless_walker` | commun | 36 | code:Prises | 1 recette |
| 👻 Essence de revenant | `prise_revenant` | commun | 26 | code:Prises | 1 recette |
| 👻 Essence de spectre des dunes | `prise_dune_spectre` | commun | 31 | code:Prises | 1 recette |
| 👻 Essence de spectre du blizzard | `prise_blizzard_spectre` | commun | 36 | code:Prises | 1 recette |
| 👻 Essence de spectre errant | `prise_wandering_spectre` | commun | 26 | code:Prises | 1 recette |
| 👻 Essence du Roi sans couronne | `prise_crownless_king` | épique | 306 | code:Prises | 2 recettes |
| 🌾 Farine | `flour` | commun | 18 | code:Equilibre | 2 recettes |
| 🌙 Faucille | `sickle` | commun | 65 | atelier | code:Equilibre |
| 🗡️ Faux de mante religieuse géante | `prise_giant_mantis` | commun | 31 | code:Prises | 1 recette |
| 🧾 Faux sceau de faux marchand | `prise_fake_merchant` | commun | 21 | code:Prises | 1 recette |
| 🔩 Ferrure | `fitting` | commun | 21 | atelier | 1 recette |
| 🌿 Fibre | `fiber` | commun | 1 | butin | 15 recettes |
| 🧶 Fil de laine | `wool_thread` | commun | 22 | atelier | 23 recettes |
| 🧵 Fil de lin | `linen_thread` | commun | 30 | atelier | 40 recettes |
| 🕸️ Filet de pêche | `fishing_net` | rare | 120 | établi | code:Equilibre |
| 🧪 Fiole d'extrait | `extract` | commun | 47 | atelier, butin | 6 recettes |
| 🧪 Fiole vide | `vial` | commun | 10 | atelier, butin | 10 recettes |
| 🌼 Fleur | `flower` | commun | 5 | butin | 6 recettes |
| 🌙 Fleur lunaire | `moon_flower` | rare | 180 | cueillette de nuit | 1 recette |
| 🌙 Fleur nocturne | `night_flower` | commun | 70 | cueillette de nuit, butin | 3 recettes |
| 🎈 Flotteur | `cork_float` | commun | 12 | établi | code:Equilibre |
| 🏹 Flèche | `arrow` | commun | 2 | établi | code:Equilibre |
| 🏹 Flèche barbelée | `arrow_barbed` | commun | 18 | atelier | code:Equilibre |
| 🏹 Flèche à pointe de fer | `arrow_iron` | commun | 8 | atelier | code:Equilibre |
| 🌾 Foin | `hay` | commun | 14 | atelier | 2 recettes |
| 🍴 Fourche à foin | `pitchfork` | commun | 70 | atelier | code:Equilibre |
| 🦊 Fourrure | `fur` | commun | 18 | butin | 33 recettes |
| 🐺 Fourrure royale (Vargor) | `royal_fur` | légendaire | 700 | boss | 1 recette |
| 🦊 Fourrure travaillée | `worked_fur` | commun | 49 | atelier | 1 recette |
| 🧩 Fragment de carte | `map_fragment` | rare | 20 | pêche | 1 recette |
| ☄️ Fragment de météorite | `meteorite` | épique | 400 | événement | 2 recettes |
| ✨ Fragment de roi déchu | `prise_fallen_king` | rare | 141 | code:Prises | 1 recette |
| 🧵 Fuseau | `spindle` | commun | 25 | établi | code:Equilibre |
| 🟢 Gelée d'homme-boue | `prise_mud_man` | commun | 26 | code:Prises | 1 recette |
| 🟢 Gelée de golem de vase | `prise_mud_golem` | rare | 96 | code:Prises | 1 recette |
| 🟢 Gelée de méduse des marais | `prise_freshwater_jellyfish` | commun | 21 | code:Prises | 1 recette |
| 🟢 Gelée de sangsue géante | `prise_leech` | commun | 21 | code:Prises | 1 recette |
| 🟢 Gelée de slime | `prise_slime` | commun | 11 | code:Prises | 1 recette |
| 🟢 Gelée de slime | `slime_gel` | commun | 6 | butin, boss | 2 recettes |
| 🟢 Gelée de slime bleu | `prise_slime_blue` | commun | 16 | code:Prises | 1 recette |
| 🟢 Gelée du Roi des Slimes | `prise_boss_slime` | rare | 186 | code:Prises | 2 recettes |
| 🟢 Gelée du Roi des marais | `prise_marsh_king` | épique | 276 | code:Prises | 2 recettes |
| 🍯 Gelée royale d'essaim d'abeilles sauvages | `prise_bee_swarm` | commun | 16 | code:Prises | 1 recette |
| ❄️ Givre éternel du Dormeur des Glaces | `prise_ice_sleeper` | épique | 306 | code:Prises | 2 recettes |
| 🕸️ Glande à soie d'araignée de givre | `prise_frost_spider` | commun | 31 | code:Prises | 1 recette |
| 🕸️ Glande à soie d'araignée des cavernes | `prise_cave_spider` | commun | 26 | code:Prises | 1 recette |
| 🕸️ Glande à soie d'araignée des roseaux | `prise_reed_spider` | commun | 26 | code:Prises | 1 recette |
| 🕸️ Glande à soie d'araignée du désert | `prise_desert_spider` | commun | 26 | code:Prises | 1 recette |
| 🕸️ Glande à soie d'araignée géante | `prise_spider` | commun | 21 | code:Prises | 1 recette |
| 🕸️ Glande à soie d'araignée sylvestre | `prise_sylvan_spider` | commun | 26 | code:Prises | 1 recette |
| 🐸 Glande à venin de crapaud géant | `prise_toad` | commun | 16 | code:Prises | 1 recette |
| 🥤 Gobelet en bois | `wood_cup` | commun | 6 | atelier | 4 recettes |
| 🌰 Graine ancienne | `ancient_seed` | rare | 150 | boss | 1 recette |
| 🥓 Graisse | `fat` | commun | 18 | atelier, butin | 4 recettes |
| ⛰️ Gravier | `gravel` | commun | 2 | atelier, minage | 1 recette |
| 🐻 Griffe d'ours | `prise_bear` | commun | 31 | code:Prises | 1 recette |
| 🐻 Griffe d'ours blanc | `prise_polar_bear` | commun | 36 | code:Prises | 1 recette |
| 🐻 Griffe d'ours brun | `prise_brown_bear` | commun | 31 | code:Prises | 1 recette |
| 🐻 Griffe d'ours des cavernes | `prise_cave_bear` | rare | 111 | code:Prises | 1 recette |
| 🐾 Griffe de créature | `claw` | commun | 50 | chasse, butin | 1 recette |
| 📜 Grimoire déchiré de moine déchu | `prise_fallen_monk` | commun | 31 | code:Prises | 1 recette |
| 📜 Grimoire déchiré de sorcier des ronces | `prise_bramble_witch` | commun | 31 | code:Prises | 1 recette |
| 📜 Grimoire déchiré de sorcière des marais | `prise_swamp_witch` | commun | 36 | code:Prises | 1 recette |
| 🎣 Hameçon | `hook` | commun | 14 | atelier | 3 recettes |
| 🦮 Harnais de cuir | `pet_harness` | rare | 110 | atelier | code:Equilibre |
| 🌿 Huile | `oil` | rare | 86 | établi | 1 recette |
| 🎖️ Insigne de brigand à cheval | `prise_highway_rider` | commun | 36 | code:Prises | 1 recette |
| 🎖️ Insigne de chef de bande | `prise_bandit_chief` | rare | 111 | code:Prises | 1 recette |
| 🎖️ Insigne de garde corrompu | `prise_corrupt_guard` | commun | 31 | code:Prises | 1 recette |
| 🎖️ Insigne de garde renégat | `prise_renegade_guard` | commun | 31 | code:Prises | 1 recette |
| 🎖️ Insigne de soldat déserteur | `prise_deserter` | commun | 31 | code:Prises | 1 recette |
| 🔱 Javelot | `javelin` | commun | 15 | établi | code:Equilibre |
| 🧶 Laine | `wool` | commun | 60 | élevage | 3 recettes |
| 🐕 Laisse | `leash` | commun | 30 | atelier | code:Equilibre |
| 🔪 Lame brute | `blade` | rare | 127 | atelier | 1 recette |
| 💜 Lavande | `lavender` | commun | 9 | cueillette | 3 recettes |
| 🐴 Licol | `halter` | commun | 50 | atelier | code:Equilibre |
| 🥈 Lingot d'argent | `silver_ingot` | rare | 80 | four | 42 recettes |
| 🥇 Lingot d'or | `gold_ingot` | rare | 120 | four | 64 recettes |
| 🥉 Lingot de cuivre | `copper_ingot` | commun | 30 | four | 164 recettes |
| 🔩 Lingot de fer | `iron_ingot` | commun | 45 | four | 170 recettes |
| 🔒 Loquet en bois | `lock_1` | commun | 20 | atelier | revente |
| 🥄 Louche | `ladle` | commun | 18 | établi | code:Shop |
| 🌱 Mandragore | `mandrake` | rare | 120 | cueillette, butin | 2 recettes |
| 🔨 Marteau d'artisan | `artisan_hammer` | commun | 70 | atelier | code:Equilibre |
| 🎭 Masque de bandit des routes | `prise_bandit` | commun | 21 | code:Prises | 1 recette |
| 🎭 Masque de maraudeur | `prise_marauder` | commun | 26 | code:Prises | 1 recette |
| 🎭 Masque de pillard | `prise_pillager` | commun | 26 | code:Prises | 1 recette |
| 🎭 Masque de pilleur de ruines | `prise_ruin_looter` | commun | 26 | code:Prises | 1 recette |
| 🎭 Masque de voleur de grand chemin | `prise_highwayman` | commun | 21 | code:Prises | 1 recette |
| 🌿 Menthe | `mint` | commun | 6 | cueillette | 2 recettes |
| 🌼 Millepertuis | `st_john` | commun | 12 | cueillette | 2 recettes |
| ⚪ Minerai d'argent | `silver_ore` | commun | 30 | minage | 1 recette |
| 🟡 Minerai d'or | `gold_ore` | commun | 45 | boss | 1 recette |
| 🟠 Minerai de cuivre | `copper_ore` | commun | 10 | butin | 1 recette |
| ⛰️ Minerai de fer | `ore` | commun | 15 | butin | 2 recettes |
| 🥣 Mortier et pilon | `mortar_pestle` | commun | 15 | établi | code:Equilibre |
| 🌑 Noyau d'ombre de dévoreur de lumière | `prise_light_eater` | commun | 36 | code:Prises | 1 recette |
| 💰 Or | `gold` | commun | — | trésor | code:Activites |
| 👂 Oreille pointue de gobelin | `prise_goblin` | commun | 26 | code:Prises | 1 recette |
| 👂 Oreille pointue de gobelin archer | `prise_goblin_archer` | commun | 26 | code:Prises | 1 recette |
| 👂 Oreille pointue de gobelin des bois | `prise_wood_goblin` | commun | 21 | code:Prises | 1 recette |
| 👂 Oreille pointue de gobelin des marais | `prise_swamp_goblin` | commun | 21 | code:Prises | 1 recette |
| 👂 Oreille pointue du Chef Gobelin | `prise_boss_goblin` | épique | 306 | code:Prises | 2 recettes |
| 🌿 Ortie | `nettle` | commun | 3 | cueillette, butin | 3 recettes |
| 🦴 Os | `bone` | commun | 4 | butin | 53 recettes |
| 🦴 Os massif d'ogre | `prise_ogre` | rare | 126 | code:Prises | 1 recette |
| 🦴 Os massif de brochet géant | `prise_giant_pike` | commun | 31 | code:Prises | 1 recette |
| 🦴 Os massif de cyclope | `prise_cyclops` | rare | 126 | code:Prises | 1 recette |
| 🦴 Os massif de géant de glace | `prise_ice_giant` | rare | 141 | code:Prises | 1 recette |
| 🦴 Os massif de géant des forêts | `prise_forest_giant` | rare | 126 | code:Prises | 1 recette |
| 🦴 Os massif de géant des ruines | `prise_ruin_giant` | rare | 141 | code:Prises | 1 recette |
| 🦴 Os massif de minotaure | `prise_minotaur` | rare | 141 | code:Prises | 1 recette |
| 🦴 Os massif de troll des cavernes | `prise_cave_troll` | rare | 126 | code:Prises | 1 recette |
| 🦴 Os massif de troll des glaces | `prise_frost_troll` | rare | 126 | code:Prises | 1 recette |
| 🦴 Os massif de troll des montagnes | `prise_mountain_troll` | rare | 126 | code:Prises | 1 recette |
| 🦴 Os massif de troll des racines | `prise_root_troll` | rare | 111 | code:Prises | 1 recette |
| 🦴 Os massif de yéti | `prise_yeti` | rare | 111 | code:Prises | 1 recette |
| 🦴 Os massif du Géant des montagnes | `prise_mountain_giant` | épique | 306 | code:Prises | 2 recettes |
| 💀 Os maudit de goule | `prise_ghoul` | commun | 26 | code:Prises | 1 recette |
| 💀 Os maudit de momie ancienne | `prise_mummy` | commun | 36 | code:Prises | 1 recette |
| 💀 Os maudit de squelette ancien | `prise_ancient_skeleton` | commun | 31 | code:Prises | 1 recette |
| 💀 Os maudit de squelette errant | `prise_skeleton` | commun | 21 | code:Prises | 1 recette |
| 🌾 Paille | `straw` | commun | 8 | atelier | 13 recettes |
| 🌾 Paille maudite d'épouvantail maudit | `prise_scarecrow` | commun | 21 | code:Prises | 1 recette |
| 📄 Papier | `paper` | commun | 4 | établi | 21 recettes |
| 📜 Parchemin vierge | `parchment` | commun | 8 | établi | 6 recettes |
| 🐇 Patte de lapin | `prise_rabbit` | commun | 11 | code:Prises | 1 recette |
| 🟫 Peau brute | `raw_hide` | commun | 10 | chasse, butin, boss | 2 recettes |
| 🦌 Peau de cerf | `deer_hide` | commun | 22 | chasse, butin | 1 recette |
| 🐺 Peau de loup | `wolf_pelt` | commun | 28 | chasse, boss, butin | 1 recette |
| 🟫 Peau raclée | `scraped_hide` | commun | 16 | atelier | 1 recette |
| 🐍 Peau visqueuse d'anguille monstrueuse | `prise_monster_eel` | commun | 31 | code:Prises | 1 recette |
| ⛰️ Pierre | `stone` | commun | 2 | butin, boss | 88 recettes |
| ✨ Pierre lumineuse | `glowstone` | rare | 120 | minage, butin | 2 recettes |
| 🦀 Pince de crabe géant | `prise_giant_crab` | commun | 31 | code:Prises | 1 recette |
| ⛏️ Piolet | `ice_pick` | rare | 110 | atelier | code:Equilibre |
| 🌲 Planches | `planks` | commun | 2 | atelier, boutique | 207 recettes |
| 🪵 Planches de chêne fines | `fine_planks` | commun | 40 | établi | 1 recette |
| 🐦 Plume | `feather` | commun | 5 | butin, boss | 13 recettes |
| 🐦 Plume d'écriture | `quill` | commun | 3 | atelier | 1 recette |
| 🐦 Plume de flamant | `prise_flamingo` | commun | 11 | code:Prises | 1 recette |
| 🐦 Plume de pingouin | `prise_penguin` | commun | 11 | code:Prises | 1 recette |
| 🐦 Plume nocturne | `night_feather` | rare | 90 | chasse, butin | 1 recette |
| 🐦 Plumes d'aigle des montagnes | `prise_mountain_eagle` | commun | 26 | code:Prises | 1 recette |
| 🐦 Plumes d'aigle géant | `prise_giant_eagle` | commun | 26 | code:Prises | 1 recette |
| 🐦 Plumes d'hippogriffe | `prise_hippogriff` | commun | 36 | code:Prises | 1 recette |
| 🐦 Plumes de chouette spectrale | `prise_spectral_owl` | commun | 26 | code:Prises | 1 recette |
| 🐦 Plumes de corbeau fantôme | `prise_ghost_crow` | commun | 26 | code:Prises | 1 recette |
| 🐦 Plumes de corbeau géant | `prise_giant_crow` | commun | 21 | code:Prises | 1 recette |
| 🐦 Plumes de griffon | `prise_griffin` | rare | 111 | code:Prises | 1 recette |
| 🐦 Plumes de harpie | `prise_harpy` | commun | 31 | code:Prises | 1 recette |
| 🐦 Plumes de rapace des falaises | `prise_cliff_raptor` | commun | 26 | code:Prises | 1 recette |
| 🐟 Poisson | `fish` | commun | 0 | code:Equilibre | 2 recettes |
| 🟡 Pollen | `pollen` | commun | 6 | abattage, cueillette, butin | 1 recette |
| 🏺 Pot | `pot` | commun | 14 | four | 1 recette |
| ⚙️ Poulie | `pulley` | commun | 27 | établi | 3 recettes |
| ✨ Poussière de feu follet | `wisp_dust` | commun | 30 | butin | 2 recettes |
| ✨ Poussière de fée des ronces | `prise_bramble_fairy` | commun | 26 | code:Prises | 1 recette |
| 🌸 Pétales séchés | `dried_petals` | commun | 9 | atelier | 1 recette |
| 🦊 Queue de renard | `prise_fox` | commun | 11 | code:Prises | 1 recette |
| 🦊 Queue de renard enragé | `prise_rabid_fox` | commun | 16 | code:Prises | 1 recette |
| 🦊 Queue de renard spectral | `prise_spectral_fox` | commun | 26 | code:Prises | 1 recette |
| 🌳 Racine ancienne | `ancient_root` | rare | 80 | boss, butin | 3 recettes |
| 🔩 Rivets | `rivet` | commun | 4 | atelier | 2 recettes |
| 🌿 Romarin | `rosemary` | commun | 8 | cueillette | 3 recettes |
| 🌲 Rondin de chêne | `oak_log` | commun | 6 | abattage, butin | 26 recettes |
| 🌲 Rondin de pin | `pine_log` | commun | 5 | abattage | 5 recettes |
| 🎋 Roseaux | `reeds` | commun | 2 | cueillette | 2 recettes |
| 🥖 Rouleau à pâtisserie | `rolling_pin` | commun | 10 | établi | code:Equilibre |
| 🧹 Râteau | `rake` | commun | 20 | établi | code:Equilibre |
| 🟧 Résine | `resin` | commun | 8 | abattage, butin | 34 recettes |
| 🏜️ Sable | `sand` | commun | 1 | butin | 3 recettes |
| 🎗️ Sangles | `leather_strap` | commun | 8 | atelier | 42 recettes |
| 🌿 Sauge | `sage` | commun | 8 | cueillette | 3 recettes |
| 🔴 Sceau de cire | `wax_seal` | commun | 10 | atelier | 5 recettes |
| 🧾 Sceau de contrebande de contrebandier | `prise_smuggler` | commun | 26 | code:Prises | 1 recette |
| 🔧 Scie à main | `hand_saw` | commun | 75 | atelier | code:Equilibre |
| 🧂 Sel | `salt` | commun | 8 | minage, butin | 8 recettes |
| 🏇 Selle de course | `saddle_race` | épique | 320 | atelier | code:Equilibre |
| 🐎 Selle de cuir | `saddle_leather` | rare | 173 | atelier | code:Equilibre |
| 🔒 Serrure de cuivre | `lock_2` | commun | 70 | établi | revente |
| 🔐 Serrure de fer | `lock_3` | rare | 149 | établi | revente |
| 🔐 Serrure à secret (or) | `lock_4` | épique | 364 | établi | revente |
| ⛰️ Silex | `flint` | commun | 4 | minage, fouille | 5 recettes |
| 🕸️ Soie d'araignée | `silk` | commun | 12 | butin | 26 recettes |
| 🟡 Soufre | `sulfur` | commun | 12 | minage | 1 recette |
| 🍄 Spore royale | `royal_spore` | épique | 300 | boss | 1 recette |
| 🍄 Spores de myconide | `prise_myconid` | commun | 21 | code:Prises | 1 recette |
| 🍄 Spores du Myconide Ancien | `prise_boss_myconid` | épique | 246 | code:Prises | 2 recettes |
| 🍄 Spores du Roi Mycélien | `prise_mycelian_king` | épique | 246 | code:Prises | 2 recettes |
| 🍬 Sucre | `sugar` | commun | 66 | four | 2 recettes |
| 🍽️ Tamis | `sieve` | commun | 50 | établi | code:Equilibre |
| 🎨 Teinture | `dye` | commun | 10 | atelier | 15 recettes |
| 🟫 Terre | `dirt` | commun | 1 | butin | 9 recettes |
| 🌿 Thym | `thyme` | commun | 6 | cueillette | 1 recette |
| 🧵 Tissu | `cloth` | commun | 25 | atelier | 78 recettes |
| 🧶 Tissu de laine | `wool_cloth` | commun | 73 | atelier | 37 recettes |
| 🧵 Tissu de lin | `linen` | rare | 100 | atelier | 45 recettes |
| ⛵ Toile | `canvas` | épique | 226 | atelier | 5 recettes |
| 🎐 Toile enchantée | `enchanted_cloth` | épique | 220 | boss | 3 recettes |
| 👳 Turban de pillard du désert | `prise_desert_raider` | commun | 31 | code:Prises | 1 recette |
| 🌸 Valériane | `valerian` | commun | 14 | cueillette | 3 recettes |
| 🐍 Venin de la Bête des profondeurs | `prise_deep_beast` | épique | 306 | code:Prises | 2 recettes |
| 🐍 Venin de serpent des dunes | `prise_dune_snake` | commun | 26 | code:Prises | 1 recette |
| 🐍 Venin de serpent des eaux | `prise_water_snake` | commun | 26 | code:Prises | 1 recette |
| 🐍 Venin de serpent des rivières | `prise_river_serpent` | commun | 26 | code:Prises | 1 recette |
| 🐍 Venin de serpent marin | `prise_sea_serpent` | rare | 111 | code:Prises | 1 recette |
| 🐍 Venin de serpent venimeux | `prise_snake` | commun | 16 | code:Prises | 1 recette |
| 🐍 Venin de ver des sables | `prise_sand_worm` | rare | 96 | code:Prises | 1 recette |
| 🖼️ Verre | `glass` | commun | 8 | four | 39 recettes |
| 🏺 Vinaigre de pomme | `vinegar` | commun | 66 | atelier | 1 recette |
| 🔮 Âme de Brumeglace | `ame_brumeglace` | légendaire | 800 | code:Prises | 1 recette |
| 🔮 Âme de Vargor | `ame_vargor` | légendaire | 760 | code:Prises | 1 recette |
| 🔮 Âme de la Bête des profondeurs | `ame_deep_beast` | légendaire | 800 | code:Prises | 1 recette |
| 🔮 Âme de la Mère des Ronces | `ame_bramble_mother` | légendaire | 760 | code:Prises | 1 recette |
| 🔮 Âme de la Wyverne des neiges | `ame_snow_wyvern` | légendaire | 800 | code:Prises | 1 recette |
| 🔮 Âme du Chef Gobelin | `ame_boss_goblin` | légendaire | 800 | code:Prises | 1 recette |
| 🔮 Âme du Colosse de Verre | `ame_glass_colossus` | légendaire | 760 | code:Prises | 1 recette |
| 🔮 Âme du Dormeur des Glaces | `ame_ice_sleeper` | légendaire | 800 | code:Prises | 1 recette |
| 🔮 Âme du Gardien des Moissons | `ame_harvest_warden` | légendaire | 680 | code:Prises | 1 recette |
| 🔮 Âme du Géant des montagnes | `ame_mountain_giant` | légendaire | 800 | code:Prises | 1 recette |
| 🔮 Âme du Myconide Ancien | `ame_boss_myconid` | légendaire | 720 | code:Prises | 1 recette |
| 🔮 Âme du Roi Mycélien | `ame_mycelian_king` | légendaire | 720 | code:Prises | 1 recette |
| 🔮 Âme du Roi des Slimes | `ame_boss_slime` | légendaire | 640 | code:Prises | 1 recette |
| 🔮 Âme du Roi des marais | `ame_marsh_king` | légendaire | 760 | code:Prises | 1 recette |
| 🔮 Âme du Roi sans couronne | `ame_crownless_king` | légendaire | 800 | code:Prises | 1 recette |
| 🔮 Âme du Scarabée royal | `ame_royal_scarab` | légendaire | 800 | code:Prises | 1 recette |
| 🧜 Écaille chantante de sirène hostile | `prise_hostile_siren` | commun | 36 | code:Prises | 1 recette |
| 🖤 Écaille noire (Roi des marais) | `black_scale` | légendaire | 700 | boss | 1 recette |
| 🐉 Écailles | `scales` | commun | 16 | chasse, butin | 2 recettes |
| 🐊 Écailles de basilic des sables | `prise_sand_basilisk` | commun | 36 | code:Prises | 1 recette |
| 🐊 Écailles de croco | `prise_croc` | commun | 26 | code:Prises | 1 recette |
| 🐉 Écailles de feu de dragonnet | `prise_drakeling` | rare | 96 | code:Prises | 1 recette |
| 🐉 Écailles de la Wyverne des neiges | `prise_snow_wyvern` | épique | 306 | code:Prises | 2 recettes |
| 🐊 Écailles de lézard des tourbières | `prise_bog_lizard` | commun | 21 | code:Prises | 1 recette |
| 🐉 Écailles de wyverne | `prise_wyvern` | rare | 111 | code:Prises | 1 recette |
| 🗿 Éclat de pierre de gargouille animée | `prise_gargoyle` | commun | 36 | code:Prises | 1 recette |
| 💎 Éclat de verre vivant | `glass_shard` | épique | 350 | boss | 1 recette |
| 🟫 Écorce | `bark` | commun | 2 | abattage | 2 recettes |
| 🛡️ Écu brisé de chevalier oublié | `prise_forgotten_knight` | rare | 126 | code:Prises | 1 recette |
| 🛡️ Écu brisé de fantôme de chevalier | `prise_ghost_knight` | rare | 96 | code:Prises | 1 recette |
| 🛡️ Écusson de mercenaire | `prise_mercenary` | commun | 36 | code:Prises | 1 recette |
| 🐞 Élytre de scarabée cuirassé | `prise_beetle` | commun | 31 | code:Prises | 1 recette |
| 🐞 Élytre du Scarabée royal | `prise_royal_scarab` | épique | 306 | code:Prises | 2 recettes |
| 🌶️ Épices | `spice` | commun | 40 | événement | 1 recette |
| 🏷️ Étiquettes de prix | `price_tags` | commun | 22 | établi | code:Equilibre |
| 🎨 Étoffe teinte | `dyed_cloth` | commun | 60 | atelier | 31 recettes |
| 🔗 Étriers | `stirrups` | rare | 117 | atelier | code:Equilibre |

## Trouvailles par source et biome (chance par geste)

### cueillette

| Trouvaille | Chance | Biomes |
|---|---|---|
| 🎋 Roseaux | 20 % | marais |
| 🌿 Ortie | 15 % | tous |
| 🌼 Camomille | 12 % | prairie |
| 🌿 Menthe | 12 % | prairie, marais |
| 🌿 Sauge | 10 % | désert |
| 🟡 Pollen | 10 % | tous |
| 🌿 Thym | 10 % | désert, prairie |
| 🌿 Romarin | 8 % | désert |
| 💜 Lavande | 8 % | prairie |
| 🌼 Millepertuis | 6 % | tous |
| 🌸 Valériane | 5 % | forêt rousse, marais |
| 🍄 Champignon rare | 2 % | forêt rousse, marais |
| 💠 Pierre colorée | 2 % | tous |
| ❔ Objet perdu | 1 % | tous |
| 🌱 Mandragore | 0.8 % | marais, forêt rousse |

### fouille

| Trouvaille | Chance | Biomes |
|---|---|---|
| ⛰️ Silex | 8 % | tous |
| 🟠 Pièce de cuivre | 5 % | tous |
| 📜 Page ancienne | 2 % | tous |
| ⚪ Pièce d'argent | 1.2 % | tous |
| 🗝️ Clé rouillée | 1 % | tous |
| 💰 Pièce ancienne | 1 % | tous |
| 🧩 Fragment de relique | 0.6 % | tous |
| ⛰️ Fragment d'inscription | 0.4 % | tous |
| 🦴 Fossile | 0.4 % | tous |
| 🟡 Pièce d'or | 0.3 % | tous |

### événement

| Trouvaille | Chance | Biomes |
|---|---|---|
| 💰 Jeton d'événement | 50 % | tous |
| 🌶️ Épices | 30 % | tous |
| ❔ Objet perdu | 20 % | tous |
| 👝 Bourse de marchand | 20 % | tous |
| 🎁 Récompense de festival | 10 % | tous |
| ⚪ Pièce d'argent | 10 % | tous |
| 📜 Recette inconnue | 8 % | tous |
| 📐 Plan d'artisan | 8 % | tous |
| 📜 Page ancienne | 8 % | tous |
| 🗺️ Carte au trésor | 5 % | tous |
| ✉️ Lettre de recommandation | 5 % | tous |
| 📔 Journal d'un voyageur | 5 % | tous |
| 📃 Lettre de change | 4 % | tous |
| 🏺 Vase ancien | 3 % | tous |
| 📚 Livre rare | 3 % | tous |
| 🏆 Ruban de champion | 3 % | tous |
| 🏺 Objet d'une ruine | 3 % | tous |
| 💍 Bijou ancien | 2 % | tous |
| 🧿 Talisman | 2 % | tous |
| 🏺 Relique | 2 % | tous |
| ☄️ Fragment de météorite | 2 % | tous |
| ⭐ Insigne de shérif | 1 % | tous |
| 👑 Sceau royal | 1 % | tous |
| 💗 Cœur minéral | 0.5 % | tous |

### pêche

| Trouvaille | Chance | Biomes |
|---|---|---|
| 🐟 Poisson cru | 30 % | tous |
| 🐚 Coquillage | 10 % | tous |
| 🦀 Crabe | 6 % | désert, marais |
| 🦞 Écrevisse | 6 % | marais, prairie |
| 🐟 Saumon | 6 % | toundra, forêt rousse |
| 🍾 Bouteille à la mer | 1 % | tous |
| ⚪ Perle | 1 % | tous |
| 🧩 Fragment de carte | 1 % | tous |
| 🐚 Coquillage rare | 0.8 % | tous |
| 🧭 Boussole ancienne | 0.2 % | tous |

### chasse

| Trouvaille | Chance | Biomes |
|---|---|---|
| 🟫 Peau brute | 35 % | tous |
| 🦷 Dent | 25 % | tous |
| 🥩 Viande de cerf | 15 % | forêt rousse, prairie |
| 🥩 Viande de sanglier | 12 % | forêt rousse, prairie |
| 🥩 Viande de lapin | 12 % | tous |
| 🐾 Griffe de créature | 12 % | tous |
| 🐉 Écailles | 8 % | marais, désert |
| 📯 Corne | 8 % | tous |
| 🐺 Peau de loup | 6 % | toundra, forêt rousse |
| 🦌 Peau de cerf | 6 % | tous |
| 🦷 Dent de monstre | 5 % | tous |
| 👝 Bourse | 4 % | tous |
| 🐦 Plume nocturne | 2 % | tous |
| 🗺️ Carte au trésor | 0.6 % | tous |
| 🥚 Œuf mystérieux | 0.3 % | tous |
| 🐉 Écaille ancienne | 0.2 % | tous |
| 📯 Corne de bête rare | 0.2 % | tous |

### cueillette de nuit

| Trouvaille | Chance | Biomes |
|---|---|---|
| 🌙 Fleur nocturne | 8 % | tous |
| 🍄 Champignon phosphorescent | 5 % | tous |
| 🌙 Fleur lunaire | 3 % | tous |

### minage

| Trouvaille | Chance | Biomes |
|---|---|---|
| ⛰️ Silex | 20 % | tous |
| ⛰️ Gravier | 20 % | tous |
| 🧂 Sel | 10 % | désert |
| ⚪ Minerai d'argent | 8 % | toundra, désert |
| 🟡 Soufre | 6 % | désert, marais |
| ✨ Pierre lumineuse | 1 % | tous |
| 🦴 Fossile | 0.6 % | tous |
| 💰 Pièce ancienne | 0.6 % | tous |
| 🦴 Os fossilisé | 0.5 % | tous |
| 💎 Cristal ancien | 0.4 % | tous |
| ⛰️ Pierre gravée | 0.4 % | tous |
| 📜 Page ancienne | 0.4 % | tous |
| 🟢 Émeraude | 0.3 % | forêt rousse |
| 🔵 Saphir | 0.3 % | toundra |
| 🔴 Rubis | 0.3 % | tous |
| 💎 Diamant | 0.15 % | tous |

### abattage

| Trouvaille | Chance | Biomes |
|---|---|---|
| 🌿 Branches | 30 % | tous |
| 🌲 Rondin de pin | 18 % | toundra, forêt rousse |
| 🌲 Rondin de chêne | 18 % | prairie, forêt rousse |
| 🟫 Écorce | 15 % | tous |
| 🟧 Résine | 8 % | tous |
| 🍎 Pomme | 8 % | prairie |
| 🍐 Poire | 5 % | prairie, forêt rousse |
| 🟣 Prune | 5 % | forêt rousse |
| 🟡 Pollen | 4 % | tous |
| 🟠 Ambre | 0.6 % | tous |
| 🌲 Bois pétrifié | 0.4 % | tous |

## Cultures

| Culture | Biomes | Jours | Compétence | Graine | Vente |
|---|---|---|---|---|---|
| 🥕 Panais | prairie, toundra | 3 | agriculture 0 | 8 or | 25 or |
| 🥕 Carotte | prairie, forêt rousse | 3 | agriculture 0 | 12 or | 35 or |
| 🥔 Patate | prairie, toundra | 4 | agriculture 3 | 20 or | 55 or |
| 🌾 Blé | prairie, désert | 3 | agriculture 0 | 6 or | 20 or |
| 🍅 Tomate | désert, marais | 4 | agriculture 5 | 15 or | 45 or |
| 🍈 Melon | désert | 5 | agriculture 12 | 30 or | 90 or |
| 🍠 Betterave | forêt rousse, toundra | 3 | agriculture 5 | 10 or | 30 or |
| 🍆 Aubergine | marais, forêt rousse | 4 | agriculture 8 | 16 or | 50 or |
| 🎃 Citrouille | forêt rousse | 5 | agriculture 15 | 35 or | 110 or |
| 🌾 Orge | prairie, toundra | 3 | agriculture 2 | 7 or | 22 or |
| 🌾 Avoine | prairie, forêt rousse | 3 | agriculture 1 | 6 or | 20 or |
| 🌾 Seigle | toundra, forêt rousse | 3 | agriculture 3 | 8 or | 24 or |
| 🧅 Navet | prairie, toundra | 3 | agriculture 1 | 9 or | 28 or |
| 🥬 Chou | forêt rousse, toundra | 4 | agriculture 4 | 13 or | 40 or |
| 🧅 Oignon | désert, prairie | 3 | agriculture 2 | 10 or | 30 or |
| 🧄 Ail | désert, marais | 3 | agriculture 3 | 10 or | 32 or |
| 🌱 Pois | prairie, marais | 3 | agriculture 2 | 8 or | 26 or |
| 🌰 Haricots | forêt rousse, marais | 3 | agriculture 3 | 9 or | 30 or |
| 🎃 Courge | marais, désert | 5 | agriculture 8 | 22 or | 70 or |
| 🌿 Lin | prairie, marais | 3 | agriculture 2 | 6 or | 18 or |
| 🌿 Houblon | forêt rousse, prairie | 4 | agriculture 6 | 11 or | 34 or |
| 🍇 Raisin | désert, prairie | 5 | agriculture 10 | 18 or | 55 or |
| 🌿 Herbes aromatiques | prairie, forêt rousse, désert, toundra, marais | 2 | agriculture 0 | 5 or | 16 or |

## Poissons

| Poisson | Poids (fréquence) | Compétence | Prix |
|---|---|---|---|
| Gardon | 40 | pêche 0 | 9 |
| Carpe | 30 | pêche 0 | 15 |
| Truite | 18 | pêche 5 | 24 |
| Poisson-chat | 15 | pêche 8 | 27 |
| Brochet | 12 | pêche 12 | 36 |
| Anguille | 8 | pêche 15 | 33 |
| Poisson doré | 2 | pêche 25 | 150 |

## Bêtes de ferme

| Bête | Prix | Produit | Tous les |
|---|---|---|---|
| Poule | 60 | 🥚 Œuf | 1 |
| Mouton | 160 | 🧶 Laine | 3 |
| Vache | 220 | 🥛 Lait | 1 |

## Dressage (bêtes sauvages)

| Bête | Difficulté | Appât | Produits |
|---|---|---|---|
| ours apprivoisé | 5 | 🍯 Miel | 🍯 Miel, `3` (inconnu) |
| cochon truffier | 3 | 🍄 Champignon | 🍄 Champignon, `2` (inconnu) |
| chameau laitier | 2 | 🌾 Blé | 🥛 Lait, `2` (inconnu) |
| gardien du marais | 4 | 🥩 Viande crue |  |
| cerf | 2 | 🥕 Carotte | 🟫 Cuir, `4` (inconnu) |
| flamant | 2 | 🐟 Poisson | 🐦 Plume, `2` (inconnu) |
| renard sentinelle (aboie) | 3 | 🍇 Baies |  |
| cheval | 3 | 🥕 Carotte |  |
| pingouin | 1 | 🐟 Poisson | 🐦 Plume, `2` (inconnu) |
| lapin | 1 | 🥕 Carotte | 🦊 Fourrure, `3` (inconnu) |
| chien de garde | 4 | 🥩 Viande crue |  |
| chien de garde | 4 | 🥩 Viande crue |  |

## Créatures

Comportement : `neutre` = ne frappe que si on l'attaque ; `meute N` = arrive en groupe ; `lumière` = fuit la lumière ;
laisse de 70 studs puis retour au foyer ; réapparition au bout de 3 jours (boss exclus). Lieu « génération » = posée par le plan de région.

| Créature | id | Niv. | PV | Dégâts | Comportement | Où | Butin | Or |
|---|---|---|---|---|---|---|---|---|
| Chameau | `camel` | 1 | 120 | 0 | flee | génération | 🥩 Viande crue 2–3 (100 %), 🟫 Cuir 1–2 (100 %) | 0 |
| Cerf | `deer` | 1 | 60 | 0 | flee | génération | 🥩 Viande crue 2–3 (100 %), 🟫 Cuir 1–2 (90 %) | 0 |
| Flamant | `flamingo` | 1 | 40 | 0 | flee | génération | 🐦 Plume 2–3 (100 %) | 0 |
| Renard | `fox` | 1 | 40 | 0 | flee | génération | 🦊 Fourrure 1–1 (80 %) | 0 |
| Pingouin | `penguin` | 1 | 40 | 0 | flee | génération | 🐦 Plume 1–2 (100 %), 🥩 Viande crue 1–1 (60 %) | 0 |
| Lapin | `rabbit` | 1 | 20 | 0 | flee | génération | 🥩 Viande crue 1–1 (100 %), 🦊 Fourrure 1–1 (30 %) | 0 |
| Slime | `slime` | 1 | 60 | 10 | hop | génération | 🟢 Gelée de slime 1–2 (70 %), 🌿 Fibre 1–1 (40 %) | 0 |
| Chien errant | `stray_dog` | 1 | 60 | 10 | charge, meute 2 | prairie (jour) | 🦴 Os 1–1 (60 %) | 0 |
| Essaim d'abeilles sauvages | `bee_swarm` | 2 | 40 | 8 | charge, neutre, vole | forêt rousse (jour), prairie (jour) | 🍯 Miel 1–2 (80 %), 🕯️ Cire d'abeille 1–2 (80 %), 🟡 Pollen 1–3 (60 %) | 0 |
| Sanglier | `boar` | 2 | 120 | 16 | charge, neutre | génération | 🥩 Viande crue 2–3 (100 %), 🟫 Cuir 1–2 (80 %) | 0 |
| Chauve-souris des cavernes | `cave_bat` | 2 | 50 | 10 | charge, nuit, vole | grottes forêt rousse | 🦴 Os 1–1 (30 %) | 0 |
| Chacal | `jackal` | 2 | 70 | 12 | charge, meute 3 | désert (jour) | 🟫 Peau brute 1–1 (60 %), 🦷 Dent 1–1 (40 %) | 0 |
| Renard enragé | `rabid_fox` | 2 | 60 | 14 | charge | prairie (jour) | 🦊 Fourrure 1–1 (60 %) | 0 |
| Slime bleu | `slime_blue` | 2 | 100 | 10 | hop | grottes prairie | 🟢 Gelée de slime 1–3 (80 %) | 0 |
| Serpent venimeux | `snake` | 2 | 60 | 16 | charge | prairie (jour) | 🐉 Écailles 1–2 (70 %), 🦷 Dent 1–1 (40 %) | 0 |
| Crapaud géant | `toad` | 2 | 110 | 12 | hop | génération | 🟢 Gelée de slime 1–2 (60 %), 🟫 Cuir 1–1 (40 %) | 0 |
| Chien sauvage | `wild_dog` | 2 | 70 | 12 | charge, meute 3 | prairie (jour) | 🟫 Peau brute 1–1 (60 %), 🦴 Os 1–2 (50 %) | 0 |
| Loup | `wolf` | 2 | 90 | 12 | charge, meute 3 | génération | 🦊 Fourrure 1–1 (70 %), 🥩 Viande crue 1–2 (90 %) | 0 |
| Bandit des routes | `bandit` | 3 | 150 | 18 | charge | prairie (jour) | 🟠 Pièce de cuivre 2–6 (100 %), 👝 Bourse 1–1 (15 %), ➰ Corde 1–1 (30 %), 🎣 Crochet 1–1 (20 %) | 2 |
| Lézard des tourbières | `bog_lizard` | 3 | 120 | 16 | charge | marais (jour) | 🐉 Écailles 1–2 (80 %), 🟫 Cuir 1–1 (40 %) | 0 |
| Cambrioleur | `burglar` | 3 | 120 | 12 | charge | génération | 🎣 Crochet 1–3 (90 %), ➰ Corde 1–2 (50 %) | 3 |
| Faux marchand | `fake_merchant` | 3 | 120 | 16 | charge, neutre | prairie (jour) | 👝 Bourse 1–1 (60 %), 👝 Bourse de marchand 1–1 (10 %) | 3 |
| Méduse des marais | `freshwater_jellyfish` | 3 | 80 | 14 | spore | marais (jour) | 🐟 Gardon 1–1 (30 %) | 1 |
| Chauve-souris géante | `giant_bat` | 3 | 60 | 12 | charge, vole | grottes forêt rousse, grottes marais, grottes désert, grottes toundra, grottes prairie | 🟫 Peau brute 1–1 (50 %), 🦷 Dent 1–1 (40 %) | 0 |
| Corbeau géant | `giant_crow` | 3 | 80 | 14 | charge, nuit, vole | forêt rousse (nuit), prairie (nuit) | 🐦 Plume 2–4 (100 %), 🐦 Plume nocturne 1–1 (15 %) | 0 |
| Voleur de grand chemin | `highwayman` | 3 | 130 | 18 | charge | prairie (jour) | 🟠 Pièce de cuivre 2–5 (100 %), 👝 Bourse 1–1 (30 %), 🎣 Crochet 1–1 (30 %) | 2 |
| Sangsue géante | `leech` | 3 | 90 | 14 | hop | marais (jour), grottes marais | 🟢 Gelée de slime 1–2 (80 %) | 0 |
| Lynx | `lynx` | 3 | 90 | 16 | charge | forêt rousse (jour) | 🦊 Fourrure 1–2 (90 %), 🐾 Griffe de créature 1–1 (40 %) | 0 |
| Myconide | `myconid` | 3 | 140 | 10 | spore | grottes forêt rousse | 🍄 Champignon 1–2 (100 %) | 0 |
| Braconnier | `poacher` | 3 | 120 | 14 | spore | forêt rousse (jour), prairie (jour) | 🦌 Peau de cerf 1–1 (50 %), 🥩 Viande de cerf 1–2 (60 %), 🐛 Appâts 2–4 (50 %) | 0 |
| Épouvantail maudit | `scarecrow` | 3 | 170 | 20 | charge, nuit | génération | 🌿 Fibre 2–4 (100 %), ✨ Poussière de feu follet 1–1 (30 %), 🌱 Graines (Citrouille) 1–2 (25 %) | 0 |
| Ombre rôdeuse | `shade` | 3 | 80 | 14 | charge, nuit, lumière | génération | ✨ Poussière de feu follet 1–2 (80 %), 🦴 Os 1–2 (50 %) | 0 |
| Squelette errant | `skeleton` | 3 | 110 | 16 | charge, nuit | génération | 🦴 Os 2–4 (100 %), 🟠 Pièce de cuivre 1–3 (40 %) | 0 |
| Araignée géante | `spider` | 3 | 150 | 14 | spore | génération | 🕸️ Soie d'araignée 1–3 (100 %) | 0 |
| Gobelin des marais | `swamp_goblin` | 3 | 110 | 13 | charge | marais (jour) | 🟠 Pièce de cuivre 1–3 (100 %), 🦴 Os 1–1 (40 %) | 1 |
| Feu follet | `wisp` | 3 | 70 | 14 | spore | génération | ✨ Poussière de feu follet 1–2 (100 %) | 0 |
| Gobelin des bois | `wood_goblin` | 3 | 100 | 12 | charge | forêt rousse (jour) | 🟠 Pièce de cuivre 1–3 (100 %), 🍄 Champignon 1–2 (50 %) | 1 |
| Loup noir | `black_wolf` | 4 | 140 | 18 | charge, meute 3 | forêt rousse (jour), toundra (jour) | 🐺 Peau de loup 1–1 (80 %), 🥩 Viande crue 1–2 (90 %), 🦷 Dent 1–2 (50 %) | 0 |
| Fée des ronces | `bramble_fairy` | 4 | 80 | 14 | spore, vole | forêt rousse (jour) | 🌼 Fleur 1–2 (80 %) | 1 |
| Araignée des cavernes | `cave_spider` | 4 | 160 | 16 | spore | grottes forêt rousse, grottes prairie | 🕸️ Soie d'araignée 2–3 (100 %), ✨ Pierre lumineuse 1–1 (8 %) | 0 |
| Rapace des falaises | `cliff_raptor` | 4 | 140 | 18 | charge, vole | toundra (jour), prairie (jour) | 🐦 Plume 2–3 (100 %) | 0 |
| Croco | `croc` | 4 | 220 | 22 | charge, neutre | génération | 🟫 Cuir 2–3 (100 %), 🥩 Viande crue 1–2 (80 %) | 0 |
| Araignée du désert | `desert_spider` | 4 | 150 | 16 | spore | désert (jour), grottes désert | 🕸️ Soie d'araignée 1–2 (90 %) | 0 |
| Esprit noyé | `drowned_spirit` | 4 | 120 | 18 | charge, nuit, lumière | marais (nuit), grottes marais | ✨ Poussière de feu follet 1–2 (80 %), ⚪ Perle 1–1 (5 %) | 0 |
| Serpent des dunes | `dune_snake` | 4 | 110 | 20 | charge | désert (jour) | 🐉 Écailles 2–3 (90 %), 🧂 Sel 1–2 (30 %) | 0 |
| Corbeau fantôme | `ghost_crow` | 4 | 90 | 14 | charge, nuit, vole | forêt rousse (nuit), prairie (nuit) | 🐦 Plume 1–3 (100 %) | 0 |
| Goule | `ghoul` | 4 | 150 | 20 | charge, nuit | génération | 🧟 Chair pourrie 2–3 (100 %), 🦴 Os 1–2 (60 %), 🐾 Griffe de créature 1–1 (30 %) | 0 |
| Aigle géant | `giant_eagle` | 4 | 120 | 18 | charge, vole | toundra (jour) | 🐦 Plume 2–4 (100 %) | 0 |
| Gobelin | `goblin` | 4 | 180 | 20 | charge | génération | ⛰️ Minerai de fer 1–1 (30 %), 🟠 Minerai de cuivre 1–2 (40 %) | 2 |
| Gobelin archer | `goblin_archer` | 4 | 120 | 14 | spore | forêt rousse (jour) | 🐦 Plume 1–2 (60 %), 🟠 Minerai de cuivre 1–2 (40 %) | 2 |
| Maraudeur | `marauder` | 4 | 180 | 22 | charge | prairie (jour) | 🥩 Viande crue 1–2 (60 %), 🟫 Peau brute 1–1 (50 %), 🟠 Pièce de cuivre 1–4 (100 %) | 2 |
| Aigle des montagnes | `mountain_eagle` | 4 | 130 | 18 | charge, vole | prairie (jour) | 🐦 Plume 2–4 (100 %) | 0 |
| Homme-boue | `mud_man` | 4 | 220 | 20 | hop | marais (jour), grottes marais | 🟤 Argile 2–4 (100 %), 🟫 Terre 2–3 (100 %), 💰 Pièce ancienne 1–1 (5 %) | 0 |
| Pillard | `pillager` | 4 | 170 | 20 | charge | prairie (jour) | 🟠 Pièce de cuivre 2–6 (100 %), ➰ Corde 1–2 (40 %), 🎒 Rations 1–1 (30 %) | 2 |
| Loup polaire | `polar_wolf` | 4 | 150 | 18 | charge, meute 3 | toundra (jour) | 🐺 Peau de loup 1–1 (80 %), 🥩 Viande crue 1–2 (90 %) | 0 |
| Araignée des roseaux | `reed_spider` | 4 | 130 | 14 | spore | marais (jour) | 🕸️ Soie d'araignée 1–2 (100 %) | 0 |
| Revenant | `revenant` | 4 | 130 | 20 | charge, nuit, lumière | forêt rousse (nuit), toundra (nuit), prairie (nuit) | ✨ Poussière de feu follet 1–2 (80 %), ❔ Objet perdu 1–1 (20 %) | 0 |
| Serpent des rivières | `river_serpent` | 4 | 130 | 18 | charge | marais (jour) | 🟫 Peau brute 1–1 (50 %) | 0 |
| Pilleur de ruines | `ruin_looter` | 4 | 140 | 20 | charge | désert (jour) | 💰 Pièce ancienne 1–2 (40 %), 🧩 Fragment de relique 1–1 (30 %), 🗝️ Clé rouillée 1–1 (30 %) | 2 |
| Scorpion | `scorpion` | 4 | 160 | 18 | charge | génération | 🦂 Dard de scorpion 1–1 (80 %), 🥩 Viande crue 1–1 (30 %) | 0 |
| Contrebandier | `smuggler` | 4 | 140 | 16 | charge | marais (jour), désert (jour) | 🧂 Sel 1–3 (60 %), 👝 Bourse 1–1 (30 %), 👝 Bourse de marchand 1–1 (5 %) | 3 |
| Renard spectral | `spectral_fox` | 4 | 90 | 16 | charge, nuit | toundra (nuit) | 🦊 Fourrure 1–1 (50 %) | 0 |
| Chouette spectrale | `spectral_owl` | 4 | 110 | 16 | charge, nuit, vole | forêt rousse (nuit) | 🐦 Plume 1–3 (100 %) | 0 |
| Sanglier des marécages | `swamp_boar` | 4 | 180 | 20 | charge, neutre | marais (jour) | 🥩 Viande de sanglier 2–3 (100 %), 🟫 Cuir 1–2 (80 %) | 0 |
| Araignée sylvestre | `sylvan_spider` | 4 | 140 | 15 | spore | forêt rousse (jour) | 🕸️ Soie d'araignée 1–3 (100 %) | 0 |
| Spectre errant | `wandering_spectre` | 4 | 130 | 18 | charge, nuit, lumière | prairie (nuit) | 🦴 Os 1–1 (40 %) | 0 |
| Serpent des eaux | `water_snake` | 4 | 120 | 18 | charge | marais (jour) | 🐉 Écailles 2–3 (90 %), ⚪ Perle 1–1 (5 %) | 0 |
| Loup blanc | `wolf_white` | 4 | 130 | 16 | charge, meute 3 | génération | 🦊 Fourrure 1–2 (90 %), 🥩 Viande crue 1–2 (90 %) | 0 |
| Squelette ancien | `ancient_skeleton` | 5 | 200 | 22 | charge, nuit | génération | 🦴 Os 2–4 (100 %), 💰 Pièce ancienne 1–1 (30 %) | 0 |
| Ours | `bear` | 5 | 320 | 28 | charge, neutre | génération | 🦊 Fourrure 2–3 (100 %), 🥩 Viande crue 3–4 (100 %), 🍯 Miel 1–2 (50 %) | 0 |
| Scarabée cuirassé | `beetle` | 5 | 260 | 18 | charge | désert (jour), grottes désert | 🐉 Écailles 1–2 (60 %), 💠 Pierre colorée 1–1 (30 %) | 0 |
| Sorcier des ronces | `bramble_witch` | 5 | 160 | 20 | spore | forêt rousse (jour) | 🌿 Ortie 2–4 (100 %), 🧪 Fiole d'extrait 1–1 (30 %), 🌱 Mandragore 1–1 (8 %) | 3 |
| Ours brun | `brown_bear` | 5 | 360 | 28 | charge, neutre | forêt rousse (jour) | 🦊 Fourrure 2–3 (100 %), 🥩 Viande crue 2–3 (100 %), 🐾 Griffe de créature 1–1 (50 %) | 0 |
| Garde corrompu | `corrupt_guard` | 5 | 230 | 22 | charge, neutre | prairie (jour) | 🛡️ Insigne de garde 1–1 (50 %), 👝 Bourse 1–1 (40 %) | 3 |
| Cerf corrompu | `corrupted_stag` | 5 | 180 | 20 | charge | toundra (jour) | 🦌 Peau de cerf 1–1 (70 %), 🥩 Viande de cerf 1–2 (70 %) | 0 |
| Ombre rampante | `creeping_shadow` | 5 | 160 | 20 | hop, nuit, lumière | forêt rousse (nuit), marais (nuit), désert (nuit), toundra (nuit), prairie (nuit) | 🦴 Os 1–2 (50 %) | 0 |
| Rôdeur obscur | `dark_prowler` | 5 | 170 | 22 | charge, nuit | prairie (nuit) | 🟠 Pièce de cuivre 2–5 (100 %) | 2 |
| Pillard du désert | `desert_raider` | 5 | 180 | 20 | charge | désert (jour) | 💰 Pièce ancienne 1–1 (30 %), 🟠 Pièce de cuivre 2–6 (100 %) | 3 |
| Soldat déserteur | `deserter` | 5 | 220 | 22 | charge | prairie (jour) | ⭕ Anneau métallique 2–5 (60 %), 🎒 Rations 1–1 (40 %), 🛡️ Insigne de garde 1–1 (10 %) | 3 |
| Spectre des dunes | `dune_spectre` | 5 | 140 | 20 | spore, nuit, lumière | désert (nuit) | 💰 Pièce ancienne 1–2 (50 %), ✨ Poussière de feu follet 1–2 (60 %) | 0 |
| Moine déchu | `fallen_monk` | 5 | 170 | 22 | spore, nuit | marais (nuit), prairie (nuit) | 🧩 Fragment de relique 1–1 (40 %), 🟠 Pièce de cuivre 1–4 (100 %) | 2 |
| Sanglier givré | `frost_boar` | 5 | 220 | 22 | charge, neutre | toundra (jour) | 🥩 Viande de sanglier 2–3 (100 %), 🧊 Cristal de glace 1–1 (40 %) | 0 |
| Araignée de givre | `frost_spider` | 5 | 170 | 18 | spore | toundra (jour), grottes toundra | 🕸️ Soie d'araignée 1–3 (100 %), 🧊 Cristal de glace 1–1 (30 %) | 0 |
| Crabe géant | `giant_crab` | 5 | 240 | 22 | charge | marais (jour) | 🐟 Gardon 1–2 (50 %) | 1 |
| Mante religieuse géante | `giant_mantis` | 5 | 210 | 26 | charge | forêt rousse (jour) | 🕸️ Soie d'araignée 1–1 (30 %) | 1 |
| Brochet géant | `giant_pike` | 5 | 170 | 20 | charge | forêt rousse (jour), marais (jour) | 🐟 Brochet 1–2 (80 %), 🟫 Peau brute 1–1 (30 %) | 0 |
| Harpie | `harpy` | 5 | 160 | 20 | charge, vole | forêt rousse (jour) | 🐦 Plume 2–5 (100 %), 🐾 Griffe de créature 1–1 (40 %) | 0 |
| Hyène monstrueuse | `hyena` | 5 | 200 | 22 | charge, meute 2 | désert (jour) | 🟫 Peau brute 1–2 (80 %), 🦷 Dent de monstre 1–1 (30 %) | 0 |
| Anguille monstrueuse | `monster_eel` | 5 | 200 | 24 | charge | marais (jour) | 🐟 Gardon 1–2 (60 %) | 1 |
| Hurleur nocturne | `night_howler` | 5 | 170 | 20 | charge, meute 2, nuit | toundra (nuit), prairie (nuit) | 🐺 Peau de loup 1–1 (60 %) | 0 |
| Chasseur nocturne | `night_stalker` | 5 | 180 | 20 | spore, nuit | forêt rousse (nuit) | 🦌 Peau de cerf 1–1 (50 %) | 2 |
| Garde renégat | `renegade_guard` | 5 | 240 | 22 | charge | forêt rousse (jour) | 🛡️ Insigne de garde 1–1 (30 %), ⭕ Anneau métallique 1–3 (60 %) | 3 |
| Esprit des ruines | `ruin_spirit` | 5 | 150 | 20 | spore, nuit | forêt rousse (nuit), désert (nuit) | 🧩 Fragment de relique 1–1 (50 %) | 2 |
| Loup des ombres | `shadow_wolf` | 5 | 140 | 18 | charge, meute 3, nuit | forêt rousse (nuit), prairie (nuit) | 🐺 Peau de loup 1–1 (60 %) | 0 |
| Cerf spectral | `spectral_stag` | 5 | 160 | 18 | charge, nuit | forêt rousse (nuit) | 🦌 Bois de cerf 1–1 (80 %), ✨ Poussière de feu follet 1–2 (80 %), 🐦 Plume nocturne 1–1 (20 %) | 0 |
| Esprit des arbres | `tree_spirit` | 5 | 140 | 18 | charge, nuit, lumière | forêt rousse (nuit) | 🟧 Résine 1–2 (60 %) | 0 |
| Esprit des eaux | `water_spirit` | 5 | 150 | 18 | charge, nuit | marais (nuit) | 🐟 Gardon 1–1 (40 %) | 1 |
| Esprit des bois | `woods_spirit` | 5 | 140 | 18 | charge, nuit, lumière | forêt rousse (nuit) | 🟧 Résine 1–2 (60 %) | 1 |
| Tortue ancienne | `ancient_turtle` | 6 | 520 | 22 | charge, élite, neutre | marais (jour) | 🦴 Os fossilisé 1–1 (30 %) | 3 |
| Assassin de l'ombre | `assassin` | 6 | 200 | 34 | charge, nuit | forêt rousse (nuit), prairie (nuit) | 👝 Bourse 1–1 (50 %), 🎣 Crochet 1–2 (40 %) | 4 |
| Spectre du blizzard | `blizzard_spectre` | 6 | 160 | 22 | charge, nuit | toundra (nuit) | 🧊 Cristal de glace 1–2 (80 %), ✨ Poussière de feu follet 1–1 (50 %) | 0 |
| Roi des Slimes | `boss_slime` | 6 | 700 | 30 | hop, BOSS | génération | 🟢 Gelée de slime 5–8 (100 %) | 0 |
| Chasseur de primes | `bounty_hunter` | 6 | 200 | 20 | spore | prairie (jour) | ➰ Corde 1–2 (50 %), 🟠 Pièce de cuivre 3–6 (100 %), 🗺️ Carte au trésor 1–1 (5 %) | 4 |
| Sanglier colossal | `colossal_boar` | 6 | 420 | 30 | charge, élite | forêt rousse (jour) | 🥩 Viande crue 3–5 (100 %), 🟫 Peau brute 2–3 (100 %), 🦷 Dent 1–2 (60 %) | 2 |
| Dragonnet | `drakeling` | 6 | 240 | 26 | spore, élite | désert (jour) | 🟫 Peau brute 1–2 (80 %) | 4 |
| Marcheur sans visage | `faceless_walker` | 6 | 180 | 22 | charge, nuit, lumière | forêt rousse (nuit), marais (nuit), désert (nuit), toundra (nuit), prairie (nuit) | 🧩 Fragment de relique 1–1 (30 %) | 0 |
| Gargouille animée | `gargoyle` | 6 | 260 | 24 | charge, vole | génération | ⛰️ Pierre 3–5 (100 %), ⛰️ Pierre gravée 1–1 (10 %) | 3 |
| Fantôme de chevalier | `ghost_knight` | 6 | 320 | 30 | charge, élite, nuit | prairie (nuit) | ✨ Poussière de feu follet 2–3 (100 %), 💍 Bijou ancien 1–1 (10 %), 🗝️ Clé rouillée 1–1 (30 %) | 4 |
| Brigand à cheval | `highway_rider` | 6 | 230 | 22 | charge | désert (jour), prairie (jour) | 🟠 Pièce de cuivre 3–8 (100 %), 🟫 Cuir 1–2 (50 %), 👝 Bourse 1–1 (20 %) | 2 |
| Hippogriffe | `hippogriff` | 6 | 260 | 26 | charge, neutre, vole | forêt rousse (jour) | 🐦 Plume 2–5 (100 %) | 3 |
| Sirène hostile | `hostile_siren` | 6 | 180 | 22 | spore | marais (jour) | 🧩 Fragment de relique 1–1 (30 %) | 3 |
| Golem de glace | `ice_golem` | 6 | 360 | 24 | spore | grottes toundra | 🧊 Cristal de glace 1–3 (100 %), ⛰️ Minerai de fer 1–2 (50 %) | 0 |
| Kelpie | `kelpie` | 6 | 260 | 26 | charge, neutre | marais (jour) | 🟫 Peau brute 1–2 (70 %) | 2 |
| Dévoreur de lumière | `light_eater` | 6 | 260 | 26 | hop, nuit, lumière | désert (nuit) | ⚫ Charbon 2–4 (100 %) | 2 |
| Mercenaire | `mercenary` | 6 | 260 | 24 | charge | prairie (jour) | ⭕ Anneau métallique 2–4 (70 %), 🔩 Acier 1–1 (20 %), 🟠 Pièce de cuivre 3–8 (100 %) | 4 |
| Chasseur de lune | `moon_hunter` | 6 | 190 | 20 | spore, nuit | forêt rousse (nuit) | 🐦 Plume 1–3 (70 %) | 3 |
| Golem de vase | `mud_golem` | 6 | 420 | 26 | charge, élite | marais (jour) | 🟤 Argile 3–6 (100 %) | 2 |
| Momie ancienne | `mummy` | 6 | 220 | 22 | charge, nuit | désert (nuit) | 💰 Pièce ancienne 1–2 (60 %), 🧩 Fragment de relique 1–1 (30 %) | 3 |
| Ours blanc | `polar_bear` | 6 | 420 | 30 | charge, neutre | toundra (jour) | 🦊 Fourrure 3–4 (100 %), 🥓 Graisse 2–3 (100 %), 🥩 Viande crue 3–4 (100 %) | 0 |
| Ombre possédée | `possessed_shade` | 6 | 170 | 24 | charge, nuit, lumière | marais (nuit), toundra (nuit) | 🦴 Os 1–2 (50 %) | 2 |
| Basilic des sables | `sand_basilisk` | 6 | 220 | 24 | spore | désert (jour) | 🟫 Peau brute 1–2 (80 %), 🦷 Dent 1–1 (50 %) | 0 |
| Ver des sables | `sand_worm` | 6 | 320 | 26 | charge, élite | désert (jour) | 🦷 Dent 1–3 (80 %), 🟫 Peau brute 1–2 (60 %) | 2 |
| Sorcière des marais | `swamp_witch` | 6 | 200 | 24 | spore, nuit | marais (nuit) | 🧪 Fiole d'extrait 1–2 (60 %), 🌙 Fleur nocturne 1–1 (30 %), 🧪 Fiole vide 1–2 (60 %) | 4 |
| Golem de bois | `wood_golem` | 6 | 380 | 26 | charge, neutre | forêt rousse (jour) | 🌲 Rondin de chêne 3–5 (100 %), 🌲 Bois pétrifié 1–1 (15 %) | 2 |
| Chef de bande | `bandit_chief` | 7 | 520 | 32 | charge, élite | génération | 👝 Bourse de marchand 1–1 (100 %), 🗺️ Carte au trésor 1–1 (30 %), 🔩 Acier 1–2 (50 %) | 6 |
| Homme-taureau | `bull_man` | 7 | 600 | 36 | charge, élite | prairie (jour) | 🟫 Peau brute 2–3 (100 %) | 4 |
| Ours des cavernes | `cave_bear` | 7 | 480 | 34 | charge, élite, neutre | toundra (rare), grottes forêt rousse, grottes toundra | 🦊 Fourrure 3–4 (100 %), 🐾 Griffe de créature 1–2 (80 %), 🦴 Os fossilisé 1–1 (10 %) | 3 |
| Ent corrompu | `corrupted_ent` | 7 | 520 | 30 | charge, élite, neutre | forêt rousse (jour) | 🌲 Bois 4–8 (100 %), 🟧 Résine 1–3 (80 %) | 3 |
| Gardien maudit | `cursed_warden` | 7 | 300 | 28 | charge, élite, nuit | désert (nuit) | ⭕ Anneau métallique 2–4 (100 %) | 4 |
| Griffon | `griffin` | 7 | 320 | 30 | charge, élite, vole | forêt rousse (jour) | 🐦 Plume 3–6 (100 %), 🐾 Griffe de créature 1–2 (80 %) | 4 |
| Gardien des Moissons | `harvest_warden` | 7 | 1400 | 38 | charge, BOSS | génération | 🌰 Graine ancienne 2–4 (100 %), 🎐 Toile enchantée 1–2 (100 %), 🌱 Graines (Citrouille) 3–6 (100 %) | 6 |
| Gardien du lac | `lake_guardian` | 7 | 520 | 30 | charge, élite | marais (jour) | 🟤 Argile 3–6 (100 %) | 4 |
| Troll des racines | `root_troll` | 7 | 600 | 36 | charge, élite, neutre | forêt rousse (jour) | 🌳 Racine ancienne 1–1 (50 %), 🌲 Rondin de chêne 2–4 (100 %), 🟧 Résine 2–3 (100 %) | 4 |
| Gardien des ruines | `ruin_guardian` | 7 | 520 | 30 | charge, élite, neutre | désert (jour) | 🧩 Fragment de relique 1–2 (80 %), 💰 Pièce ancienne 1–3 (60 %) | 4 |
| Golem de grès | `sandstone_golem` | 7 | 480 | 30 | charge, élite | désert (jour) | 🏜️ Sable 4–8 (100 %), 🔴 Rubis 1–1 (5 %), ⛰️ Pierre gravée 1–1 (15 %) | 4 |
| Serpent marin | `sea_serpent` | 7 | 380 | 28 | charge, élite | marais (jour) | 🐟 Truite 1–3 (70 %), 🧩 Fragment de relique 1–1 (15 %) | 2 |
| Esprit de l'orage | `storm_wraith` | 7 | 420 | 32 | charge, élite | génération | ✨ Pierre lumineuse 1–2 (80 %), 💎 Cristal ancien 1–1 (25 %) | 6 |
| Gardien des tombes | `tomb_warden` | 7 | 480 | 30 | charge, élite, nuit | prairie (nuit) | 💰 Pièce ancienne 1–3 (80 %) | 4 |
| Wyverne | `wyvern` | 7 | 340 | 32 | spore, élite, vole | désert (jour) | 🟫 Peau brute 1–2 (80 %) | 4 |
| Yéti | `yeti` | 7 | 480 | 34 | charge, élite | génération | 🦊 Fourrure 3–5 (100 %), 🧊 Cristal de glace 1–2 (80 %) | 4 |
| Myconide Ancien | `boss_myconid` | 8 | 900 | 40 | spore, BOSS | génération |  | 0 |
| Troll des cavernes | `cave_troll` | 8 | 700 | 38 | charge, élite | grottes désert, grottes prairie | ⛰️ Pierre 4–8 (100 %), ⛰️ Minerai de fer 1–3 (60 %) | 5 |
| Cyclope | `cyclops` | 8 | 850 | 42 | charge, élite | prairie (rare) | 🦷 Dent 2–3 (100 %), 🗺️ Carte au trésor 1–1 (15 %) | 6 |
| Colosse de terre | `earth_colossus` | 8 | 680 | 34 | charge, élite | marais (jour) | 🟤 Argile 4–8 (100 %) | 4 |
| Géant des forêts | `forest_giant` | 8 | 820 | 40 | charge, élite, neutre | forêt rousse (jour) | 🌲 Bois 6–10 (100 %) | 5 |
| Chevalier oublié | `forgotten_knight` | 8 | 360 | 32 | charge, élite, nuit | prairie (nuit) | 🔩 Acier 1–2 (60 %) | 5 |
| Troll des glaces | `frost_troll` | 8 | 650 | 38 | charge, élite | toundra (jour) | 🧊 Cristal de glace 2–3 (100 %), 🦊 Fourrure 2–3 (100 %), 💎 Cristal ancien 1–1 (10 %) | 5 |
| Gardien de granit | `granite_warden` | 8 | 720 | 36 | charge, élite, neutre | toundra (jour) | ⛰️ Pierre 6–10 (100 %) | 5 |
| Troll des montagnes | `mountain_troll` | 8 | 720 | 38 | charge, élite | toundra (jour) | ⛰️ Pierre 4–8 (100 %) | 5 |
| Roi Mycélien | `mycelian_king` | 8 | 1800 | 42 | spore, BOSS | génération | 🍄 Spore royale 1–2 (100 %), 🍄 Champignon 6–10 (100 %) | 7 |
| Ogre | `ogre` | 8 | 800 | 40 | charge, élite, neutre | forêt rousse (rare), marais (rare) | 🥩 Viande crue 4–6 (100 %), 👝 Bourse de marchand 1–1 (40 %), 📯 Corne de bête rare 1–1 (5 %) | 6 |
| Colosse de pierre | `stone_golem` | 8 | 700 | 36 | charge, élite | grottes désert, grottes prairie | ⛰️ Pierre 6–10 (100 %), ⛰️ Pierre gravée 1–1 (30 %), 💗 Cœur minéral 1–1 (3 %) | 5 |
| Mère des Ronces | `bramble_mother` | 9 | 2200 | 46 | spore, BOSS | errant forêt rousse | 🌰 Graine ancienne 2–3 (100 %), 🌳 Racine ancienne 1–2 (100 %) | 8 |
| Roi déchu | `fallen_king` | 9 | 900 | 40 | charge, élite, nuit | désert (nuit), prairie (nuit) | 💍 Bijou ancien 1–1 (50 %), 👑 Sceau royal 1–1 (20 %), 💰 Pièce ancienne 2–5 (100 %) | 10 |
| Colosse de Verre | `glass_colossus` | 9 | 2400 | 50 | charge, BOSS | génération | 💎 Éclat de verre vivant 2–4 (100 %), 🟡 Minerai d'or 4–8 (100 %) | 8 |
| Géant de glace | `ice_giant` | 9 | 900 | 42 | charge, élite | toundra (jour) | 🧊 Cristal de glace 1–3 (80 %), 🦊 Fourrure 2–4 (100 %) | 6 |
| Roi des marais | `marsh_king` | 9 | 2200 | 46 | hop, BOSS | gardien de donjon marais, errant marais | 🖤 Écaille noire (Roi des marais) 1–2 (100 %), ⚪ Perle 1–3 (100 %) | 8 |
| Minotaure | `minotaur` | 9 | 900 | 44 | charge, élite | désert (rare) | 📯 Corne 2–2 (100 %), 📯 Corne de bête rare 1–1 (20 %), 🔩 Acier 1–3 (60 %) | 7 |
| Géant des ruines | `ruin_giant` | 9 | 860 | 40 | charge, élite | prairie (jour) | 🧩 Fragment de relique 1–3 (80 %) | 6 |
| Vargor, le Roi des loups | `vargor` | 9 | 2000 | 48 | charge, BOSS | gardien de donjon forêt rousse, errant forêt rousse | 🐺 Fourrure royale (Vargor) 1–1 (100 %), 🐺 Peau de loup 3–5 (100 %) | 8 |
| Chef Gobelin | `boss_goblin` | 10 | 1200 | 50 | charge, BOSS | génération |  | 0 |
| Brumeglace | `brumeglace` | 10 | 2600 | 52 | spore, BOSS | gardien de donjon toundra, errant toundra | ❄️ Cristal de givre (Brumeglace) 1–1 (100 %), 🧊 Cristal de glace 4–6 (100 %) | 9 |
| Le Roi sans couronne | `crownless_king` | 10 | 2800 | 54 | charge, BOSS | gardien de donjon prairie, errant prairie | 👑 Couronne oubliée 1–1 (100 %), 👑 Sceau royal 1–1 (30 %), 💍 Bijou ancien 1–2 (100 %) | 10 |
| Bête des profondeurs | `deep_beast` | 10 | 2600 | 52 | charge, BOSS | errant marais | 🟫 Peau brute 4–6 (100 %), 🦷 Dent 3–5 (100 %) | 9 |
| Dormeur des Glaces | `ice_sleeper` | 10 | 3000 | 55 | spore, BOSS | génération | ❄️ Cœur gelé 1–1 (100 %), 🧊 Cristal de glace 4–8 (100 %) | 10 |
| Géant des montagnes | `mountain_giant` | 10 | 3000 | 56 | charge, BOSS | errant prairie, toundra | ⛰️ Pierre 10–20 (100 %), 🟡 Minerai d'or 2–4 (100 %) | 10 |
| Scarabée royal | `royal_scarab` | 10 | 2400 | 48 | charge, BOSS | gardien de donjon désert, errant désert | 🐞 Carapace dorée (Scarabée royal) 1–1 (100 %), 🟡 Minerai d'or 3–6 (100 %) | 9 |
| Wyverne des neiges | `snow_wyvern` | 10 | 2400 | 50 | spore, BOSS, vole | errant toundra | 🧊 Cristal de glace 2–4 (100 %), 🐦 Plume 4–8 (100 %) | 9 |

## Compétences : ce qui donne de l'XP

Lu dans le code (`addSkillXp` / `addSkillXpCapped`). Les gestes réversibles sont plafonnés par jour (étape 6A).

### 🌾 Agriculture — Cultures plus difficiles, récoltes doubles (7 sources)

- `Farm:474` — `G.Joueurs.addSkillXp(player, "agriculture", 3 + (Config.CROPS[st.crop].days or 3))`
- `Fauche:87` — `G.Joueurs.addSkillXp(player, "agriculture", 1)`
- `Props:362` — `G.Joueurs.addSkillXp(player, "agriculture", 3)`
- `Props:645` — `G.Joueurs.addSkillXp(player, "agriculture", 2)`
- `Props:746` — `G.Joueurs.addSkillXp(player, "agriculture", 2 + math.floor((p.skill or 0) / 4))`
- `Props:781` — `G.Joueurs.addSkillXp(player, "agriculture", 2)`
- `Terraforme:138` — `G.Joueurs.addSkillXpCapped(player, "agriculture", 1, "terrasse", XP_PER_DAY)`

### 🪓 Bûcheronnage — Bois en plus, arbres abattus plus vite (1 source)

- `Props:532` — `G.Joueurs.addSkillXp(player, "bucheronnage", 6)`

### ⛏️ Minage — Fer au niv. 12, or au niv. 25, minerai en plus (3 sources)

- `Donjons:586` — `G.Joueurs.addSkillXp(player, "minage", 8)`
- `Evenements:448` — `G.Joueurs.addSkillXp(player, "minage", 4)`
- `Props:756` — `G.Joueurs.addSkillXp(player, "minage", 4 + math.floor((k.skill or 0) / 2))`

### 🎣 Pêche — Poissons rares, touches plus fréquentes (4 sources)

- `Fishing:69` — `G.Joueurs.addSkillXp(player, "peche", 5 + math.floor(Config.FISH[i].price / 10))`
- `Fishing:195` — `G.Joueurs.addSkillXp(player, "peche", 2)`
- `Fishing:203` — `G.Joueurs.addSkillXp(player, "peche", 4 + math.floor(Config.FISH[i].price / 10))`
- `Nasses:166` — `G.Joueurs.addSkillXp(player, "peche", 3 * d.n)`

### 🍳 Cuisine — Plats élaborés, plats qui nourrissent plus (0 source)

- pas d'appel direct : l'XP vient de la fabrication (`Shop`, compétence de la recette), voir plus bas

### ⚒️ Artisanat — Outils de fer, serrures, équipement (7 sources)

- `Batir:188` — `G.Joueurs.addSkillXpCapped(player, "artisanat", 1, "pose", 150)`
- `Batir:424` — `G.Joueurs.addSkillXpCapped(player, "artisanat", #todo, "pose", 150)`
- `Demolir:318` — `G.Joueurs.addSkillXp(player, "artisanat", 4)`
- `QuetesLieux:488` — `G.Joueurs.addSkillXp(player, "artisanat", 3)`
- `Shop:689` — `G.Joueurs.addSkillXp(player, "artisanat", G.Chantiers.craftXp(player, 10 + (r.skill and r.skill[2] or 0)))`
- `Shop:695` — `G.Joueurs.addSkillXp(player, "artisanat", G.Chantiers.craftXp(player, 8))`
- `Shop:798` — `G.Joueurs.addSkillXp(player, "artisanat", G.Chantiers.craftXp(player, 3))`

### ⚔️ Combat — +1 % de dégâts par niveau (4 sources)

- `Combat:139` — `G.Joueurs.addSkillXpCapped(player, "combat", 2, "mannequin", 150)`
- `Combat:315` — `G.Joueurs.addSkillXp(player, "combat", 1)`
- `Enemies:827` — `G.Joueurs.addSkillXp(player, "combat", 4 * k.level)`
- `Enemies:856` — `G.Joueurs.addSkillXp(p, "combat", 4 * en.k.level)`

### 🎣 Crochetage — Serrures plus dures, crochets qui cassent moins (2 sources)

- `Protection:199` — `G.Joueurs.addSkillXp(player, "crochetage", (practice and 3 or 9) * tier)`
- `Protection:202` — `G.Joueurs.addSkillXp(player, "crochetage", (practice and 1 or 2) * tier)`

### 🐾 Dressage — Bêtes plus sauvages, mini-jeu plus facile (5 sources)

- `Compagnons:207` — `G.Joueurs.addSkillXp(player, "dressage", 12 * t.diff)`
- `Compagnons:211` — `G.Joueurs.addSkillXp(player, "dressage", 3 * t.diff)`
- `Horses:300` — `G.Joueurs.addSkillXp(player, "dressage", 3 * diff)`
- `Horses:304` — `G.Joueurs.addSkillXp(player, "dressage", 12 * diff)`
- `Horses:580` — `G.Joueurs.addSkillXp(player, "dressage", 20)`

### 🐄 Élevage — Produits des bêtes plus souvent (6 sources)

- `Animals:224` — `G.Joueurs.addSkillXp(player, "elevage", 5)`
- `Compagnons:265` — `G.Joueurs.addSkillXp(player, "elevage", 6)`
- `Compagnons:351` — `G.Joueurs.addSkillXp(owner, "elevage", 15)`
- `Joueurs:751` — `J.addSkillXp(player, "elevage", 2)`
- `Machines:154` — `G.Joueurs.addSkillXp(player, "elevage", 4)`
- `Nids:143` — `G.Joueurs.addSkillXp(player, "elevage", 2)`

### 💰 Commerce — Ventes et commandes mieux payées (+0,5 % / +1 % par niveau) (12 sources)

- `Admin:691` — `G.Joueurs.addSkillXp(player, "commerce", 3)`
- `Chroniques:87` — `G.Joueurs.addSkillXp(player, "commerce", 2) -- le savoir se monnaie`
- `Economie:305` — `G.Joueurs.addSkillXpCapped(p, "commerce", 6, "echange", 5)`
- `Economie:404` — `G.Joueurs.addSkillXp(player, "commerce", 12 + o.n)`
- `Economie:682` — `G.Joueurs.addSkillXp(owner, "commerce", 2 + math.floor(cost / 30))`
- `Joueurs:699` — `J.addSkillXp(player, "commerce", 1)`
- `Joueurs:795` — `J.addSkillXp(player, "commerce", 10 * mult)`
- `Politique:225` — `G.Joueurs.addSkillXp(player, "commerce", 1)`
- `Poste:471` — `G.Joueurs.addSkillXp(player, "commerce", 2)`
- `Shop:521` — `G.Joueurs.addSkillXp(player, "commerce", 1 + math.floor(total / 25))`
- `Ventes:299` — `G.Joueurs.addSkillXp(player, "commerce", 2)`
- `Ventes:325` — `G.Joueurs.addSkillXp(player, "commerce", 2)`

### Compétence choisie à l'exécution

- `Joueurs:364` — `J.addSkillXp(player, skill, amount)`
- `Moissons:154` — `G.Joueurs.addSkillXp(player, src.skill, 1)`
- `Shop:727` — `G.Joueurs.addSkillXp(player, skillName, 3 + math.floor((r.skill and r.skill[2] or 0) / 3))`

## Or : entrées et sorties

Lu dans le code : `add(…, "gold", …)` crée de l'or, `take(…, "gold", …)` en détruit (ou le déplace vers un autre joueur).
Le journal serveur (`Economie`) mesure les flux réels par monde.

### Entrées d'or (20)

- `Activites:182` — `G.Joueurs.add(player, "gold", prize)`
- `Admin:566` — `G.Joueurs.add(o.from, "gold", o.price)`
- `Admin:690` — `G.Joueurs.add(player, "gold", c.price)`
- `Clans:215` — `G.Joueurs.add(player, "gold", FOUND_COST, true)`
- `Economie:400` — `G.Joueurs.add(player, "gold", reward, true)`
- `Economie:640` — `G.Joueurs.add(player, "gold", n, true)`
- `Enemies:761` — `G.Joueurs.add(player, "gold", math.max(1, math.min(gold, math.random(math.floor(cap * 0.6), math.ceil(cap * 1.4)))))`
- `Evenements:472` — `G.Joueurs.add(player, "gold", 40, true)`
- `Evenements:521` — `G.Joueurs.add(p, "gold", 120, true)`
- `Game:382` — `G.Joueurs.add(hunter, "gold", bounty, true)`
- `Ilots:160` — `G.Joueurs.add(player, "gold", math.random(30, 80))`
- `Joueurs:769` — `J.add(player, "gold", n)`
- `Journal:101` — `G.Joueurs.add(player, "gold", 20 * dec, true)`
- `Journal:207` — `G.Joueurs.add(player, "gold", math.floor(math.random(80, 200) * (hunter and 1.5 or 1)))`
- `Mondes:851` — `G.Joueurs.add(p, "gold", t.cost, true)`
- `Poste:293` — `G.Joueurs.add(player, "gold", p.gold, true)`
- `Poste:412` — `G.Joueurs.add(player, "gold", POSTAGE, true)`
- `Quetes:580` — `G.Joueurs.add(player, "gold", q.gold)`
- `Shop:519` — `G.Joueurs.add(player, "gold", total, true)`
- `Shop:1092` — `G.Joueurs.add(player, "gold", d.stall.till, true)`

### Sorties d'or (39)

- `Activites:173` — `if prize > 0 and not G.Joueurs.take(player, "gold", prize) then`
- `Admin:562` — `if o.price > 0 and not G.Joueurs.take(player, "gold", o.price) then`
- `Admin:647` — `if not G.Joueurs.take(player, "gold", price) then`
- `Armee:301` — `if G.Joueurs.take(player, "gold", total) then`
- `Avatar:370` — `if not G.Joueurs.take(player, "gold", cost) then`
- `Clans:209` — `if not G.Joueurs.take(player, "gold", FOUND_COST) then`
- `Economie:514` — `if item ~= "gold" and not G.Joueurs.take(player, "gold", 2) then`
- `Economie:545` — `if not G.Joueurs.take(player, "gold", cost) then`
- `Economie:658` — `if not G.Joueurs.take(player, "gold", cost) then`
- `Game:423` — `G.Joueurs.take(player, "gold", lost)`
- `Game:449` — `G.Joueurs.take(player, "gold", fine)`
- `Horses:261` — `if not G.Joueurs.take(player, "gold", price) then`
- `Horses:457` — `if not G.Joueurs.take(player, "gold", Horses.STABLE_FEE) then`
- `Horses:489` — `if not G.Joueurs.take(player, "gold", Horses.STABLE_FEE) then`
- `Horses:565` — `G.Joueurs.take(player, "gold", c.gold)`
- `Joueurs:91` — `J.take(player, "gold", cost)`
- `Metiers:1150` — `if not G.Joueurs.take(player, "gold", HEAL_COST) then`
- `Metiers:1160` — `if not G.Joueurs.take(player, "gold", BLESS_COST) then`
- `Metiers:1188` — `if not G.Joueurs.take(player, "gold", cost) then`
- `Metiers:1199` — `if not G.Joueurs.take(player, "gold", ALMS_COST) then`
- `Metiers:1233` — `if not G.Joueurs.take(player, "gold", nxt.gold) then`
- `Metiers:1265` — `if not G.Joueurs.take(player, "gold", t.price) then`
- `Mondes:932` — `if not travelling[p] and G.Joueurs.take(p, "gold", cost) then`
- `Ouvriers:28` — `if not G.Joueurs.take(player, "gold", cost) then`
- `Parcelles:141` — `G.Joueurs.take(player, "gold", price)`
- `Politique:218` — `if not G.Joueurs.take(player, "gold", n) then`
- `Poste:400` — `G.Joueurs.take(player, "gold", POSTAGE)`
- `Poste:442` — `G.Joueurs.take(player, "gold", fee)`
- `Poste:462` — `if not G.Joueurs.take(player, "gold", l.price) then`
- `Shop:74` — `if not G.Joueurs.take(player, "gold", rent) then`
- `Shop:459` — `if not G.Joueurs.take(player, "gold", entry.price * n) then`
- `Shop:824` — `if not G.Joueurs.take(player, "gold", total) then`
- `Ventes:220` — `G.Joueurs.take(player, "gold", fee)`
- `Ventes:240` — `G.Joueurs.take(player, "gold", fee)`
- `Ventes:253` — `G.Joueurs.take(player, "gold", fee)`
- `Ventes:290` — `if not G.Joueurs.take(player, "gold", l.price) then`
- `Ventes:319` — `if not G.Joueurs.take(player, "gold", l.price) then`
- `Ventes:371` — `if not G.Joueurs.take(player, "gold", amount) then`
- `Villages:36` — `if not G.Joueurs.take(player, "gold", 12) then`

