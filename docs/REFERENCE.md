# Wild Acres — fiche de référence (générée)

Générée par `tools/bancs/reference.luau` depuis les données du jeu : **ne pas modifier à la main**, relancer le banc.
Contenu : 664 objets, 536 recettes, 23 cultures, 83 créatures, 11 compétences.

Règles : tout objet est **échangeable** (troc, étal, hôtel des ventes, courrier, coffre) — aucun objet lié au
personnage (décision étape 4B : économie entre joueurs, monde bac à sable). L'équipement porté s'échange une fois retiré.
Rareté = obtention réelle (`Catalogue.assignRarity`) : prix, et pour ce qui ne se fabrique ni ne s'achète, meilleure chance de trouvaille.

## Contrôles

- Objets sans aucune source trouvée : floor2, stairs, wall, wall2, wall2_window, wall_brick, wall_door, wall_stone, wall_window
  (les pièces toutes faites `wall*`, `floor2`, `stairs` sont retirées de l'atelier depuis la construction libre ; gardées pour les anciennes sauvegardes)
- Objets sans usage ni valeur de revente : **aucun**

## Objets

Raretés : commun 485 · peu commun 46 · rare 86 · épique 37 · légendaire 10

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

### Nourriture et boissons (95)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🧄 Ail | `garlic` | commun | 32 | récolte | 2 recettes, usage direct |
| 🐟 Anguille | `fish_6` | commun | 55 | code:Npcs | usage direct |
| 🍆 Aubergine | `eggplant` | commun | 50 | récolte | 1 recette, usage direct |
| 🌾 Avoine | `oat` | commun | 20 | récolte | 3 recettes, usage direct |
| 🍇 Baies | `berries` | commun | 4 | code:Npcs | 3 recettes, usage direct |
| 🧴 Baume d'herboriste | `herbal_salve` | commun | 70 | atelier | usage direct |
| 🍠 Betterave | `beetroot` | commun | 30 | récolte | 2 recettes, usage direct |
| 🧈 Beurre | `butter` | commun | 40 | atelier | 2 recettes, usage direct |
| 🍺 Bière d'orge | `ale` | commun | 50 | établi | usage direct |
| 🌾 Blé | `wheat` | commun | 20 | récolte | 9 recettes, usage direct |
| 🥣 Bouillie | `porridge` | commun | 30 | four | usage direct |
| 🍲 Bouillon | `broth` | commun | 30 | four | usage direct |
| 🐟 Brochet | `fish_5` | commun | 60 | code:Npcs | usage direct |
| 🥕 Carotte | `carrot` | commun | 35 | récolte | 3 recettes, usage direct |
| 🐟 Carpe | `fish_2` | commun | 25 | code:Npcs | usage direct |
| 🍄 Champignon | `mushroom` | commun | 12 | boss, butin | 1 recette, usage direct |
| 🥬 Chou | `cabbage` | commun | 40 | récolte | 3 recettes, usage direct |
| 🍺 Cidre | `cider` | commun | 60 | établi | 1 recette, usage direct |
| 🎃 Citrouille | `pumpkin` | rare | 110 | récolte | 1 recette, usage direct |
| 🍲 Civet de lapin | `rabbit_stew` | rare | 110 | four | usage direct |
| 🐚 Coquillage | `shellfish` | commun | 14 | pêche | 1 recette, usage direct |
| 🎃 Courge | `squash` | commun | 70 | récolte | usage direct |
| 🦀 Crabe | `crab` | commun | 30 | pêche | 1 recette, usage direct |
| 💧 Eau | `water` | commun | 2 | atelier | usage direct |
| 🧀 Fromage | `cheese` | commun | 70 | four | usage direct |
| 🍇 Fruits séchés | `dried_fruit` | commun | 30 | atelier | 1 recette, usage direct |
| 🥞 Galette | `galette` | commun | 40 | four | usage direct |
| 🐟 Gardon | `fish_1` | commun | 15 | code:Npcs | usage direct |
| 🍰 Gâteau au miel | `honey_cake` | rare | 180 | four | usage direct |
| 🌰 Haricots | `bean` | commun | 30 | récolte | usage direct |
| 🌿 Herbes aromatiques | `herbs` | commun | 16 | récolte | 5 recettes, usage direct |
| 🌿 Houblon | `hops` | commun | 34 | récolte | 1 recette, usage direct |
| 🍵 Infusion de camomille | `chamomile_tea` | commun | 22 | four | usage direct |
| 🍵 Infusion de menthe | `mint_tea` | commun | 20 | four | usage direct |
| 🍵 Infusion de sauge | `sage_tea` | commun | 24 | atelier | usage direct |
| 🍵 Infusion de thym | `thyme_tea` | commun | 22 | four | usage direct |
| 🧃 Jus de baies | `berry_juice` | commun | 20 | atelier | usage direct |
| 🧃 Jus de pomme | `apple_juice` | commun | 24 | atelier | usage direct |
| 🍷 Jus de raisin | `grape_juice` | commun | 40 | atelier | usage direct |
| 🥛 Lait | `milk` | commun | 35 | élevage | 5 recettes, usage direct |
| 🌿 Lin | `flax` | commun | 18 | récolte | 1 recette, usage direct |
| 🥗 Légumes cuits | `cooked_veg` | commun | 50 | four | usage direct |
| 🍈 Melon | `melon` | rare | 90 | récolte | usage direct |
| 🍯 Miel | `honey` | commun | 30 | butin | 3 recettes, usage direct |
| 🧅 Navet | `turnip` | commun | 28 | récolte | 2 recettes, usage direct |
| 🧅 Oignon | `onion` | commun | 30 | récolte | 3 recettes, usage direct |
| 🧅 Oignons au vinaigre | `pickled_onions` | commun | 60 | atelier | usage direct |
| 🍳 Omelette | `omelette` | commun | 60 | four | usage direct |
| 🌾 Orge | `barley` | commun | 22 | récolte | 1 recette, usage direct |
| 🍞 Pain | `bread` | commun | 70 | four | 1 recette, usage direct |
| 🍞 Pain complet | `whole_bread` | rare | 90 | four | 1 recette, usage direct |
| 🥖 Pain de campagne | `country_bread` | rare | 110 | four | usage direct |
| 🥕 Panais | `parsnip` | commun | 25 | récolte | usage direct |
| 🥔 Patate | `potato` | commun | 55 | récolte | 2 recettes, usage direct |
| 🧪 Philtre apaisant | `calming_draught` | rare | 110 | atelier | usage direct |
| 🍐 Poire | `pear` | commun | 10 | abattage | 1 recette, usage direct |
| 🌱 Pois | `pea` | commun | 26 | récolte | 1 recette, usage direct |
| 🐟 Poisson cru | `raw_fish` | commun | 8 | pêche | 1 recette, usage direct |
| 🐟 Poisson doré | `fish_7` | épique | 250 | code:Npcs | usage direct |
| 🐟 Poisson fumé | `smoked_fish` | commun | 40 | four | usage direct |
| 🍢 Poisson grillé | `grilled_fish` | commun | 60 | four | usage direct |
| 🐟 Poisson-chat | `fish_4` | commun | 45 | code:Npcs | usage direct |
| 🍎 Pomme | `apple` | commun | 10 | abattage | 5 recettes, usage direct |
| ❤️ Potion de soin | `healing_potion` | rare | 80 | atelier | usage direct |
| 🟣 Prune | `plum` | commun | 12 | abattage | 1 recette, usage direct |
| 🍲 Ragoût de gibier | `game_stew` | rare | 120 | four | usage direct |
| 🥘 Ragoût du désert | `stew` | rare | 200 | four | usage direct |
| 🍇 Raisin | `grape` | commun | 55 | récolte | 2 recettes, usage direct |
| 🎒 Rations | `rations` | commun | 60 | atelier, butin | 2 recettes, usage direct |
| 🎒 Sac de provisions | `provision_bag` | rare | 90 | atelier | usage direct |
| 🥗 Salade | `salad` | commun | 40 | atelier | usage direct |
| 🍖 Sanglier rôti | `roast_boar` | commun | 70 | four | usage direct |
| 🐟 Saumon | `salmon` | commun | 50 | pêche | usage direct |
| 🌾 Seigle | `rye` | commun | 24 | récolte | 1 recette, usage direct |
| 🍯 Sirop de fruits | `fruit_syrup` | commun | 50 | four | usage direct |
| 🥣 Soupe d'orties | `nettle_soup` | commun | 30 | four | usage direct |
| 🍲 Soupe de poisson | `fish_soup` | rare | 90 | four | usage direct |
| 🍲 Soupe du potager | `soup` | rare | 140 | four | usage direct |
| 🍖 Steak grillé | `steak` | commun | 30 | four | usage direct |
| 🥧 Tarte aux pommes | `apple_pie` | rare | 150 | four | usage direct |
| 🥧 Tarte à la citrouille | `pie` | épique | 220 | four | usage direct |
| 🍵 Tisane du soir | `evening_tea` | commun | 36 | atelier | usage direct |
| 🍅 Tomate | `tomato` | commun | 45 | récolte | 1 recette, usage direct |
| 🥧 Tourte à la viande | `meat_pie` | rare | 170 | four | usage direct |
| 🐟 Truite | `fish_3` | commun | 40 | code:Economie | usage direct |
| 🥩 Viande crue | `meat` | commun | 8 | butin | 5 recettes, usage direct |
| 🥩 Viande de cerf | `venison` | commun | 16 | chasse, butin | 1 recette, usage direct |
| 🥩 Viande de lapin | `rabbit_meat` | commun | 10 | chasse | 1 recette, usage direct |
| 🥩 Viande de sanglier | `boar_meat` | commun | 14 | chasse, butin | 1 recette, usage direct |
| 🍖 Viande rôtie | `roast` | commun | 60 | four | usage direct |
| 🥓 Viande séchée | `jerky` | commun | 30 | atelier | 1 recette, usage direct |
| 🦞 Écrevisse | `crayfish` | commun | 24 | pêche | usage direct |
| 💪 Élixir de vigueur | `vigor_elixir` | rare | 160 | atelier | usage direct |
| 🌙 Élixir nocturne | `night_elixir` | rare | 200 | atelier | usage direct |
| 🥚 Œuf | `egg` | commun | 15 | élevage | 5 recettes, usage direct |

### Objets de valeur et collection (98)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🟠 Ambre | `amber` | rare | 60 | abattage | 2 recettes, usage direct |
| ⚓ Ancre | `anchor` | peu commun | 60 | établi | usage direct |
| 🔮 Artefact | `artifact` | légendaire | 600 | atelier | usage direct |
| 💍 Bague sertie | `ring_gem` | épique | 400 | établi | usage direct |
| ⚖️ Balance | `scales_tool` | peu commun | 60 | établi | usage direct |
| ⚽ Ballon en cuir | `leather_ball` | peu commun | 20 | atelier | usage direct |
| 🧶 Ballot de tissu | `cloth_bale` | rare | 200 | atelier | usage direct |
| 👜 Besace en toile | `canvas_bag` | peu commun | 30 | établi | usage direct |
| 💍 Bijou ancien | `ancient_jewel` | épique | 240 | événement, trésor, butin, boss | 2 recettes, usage direct |
| 🎟️ Billet de foire | `fair_ticket` | commun | 10 | atelier | usage direct |
| 🌲 Bois pétrifié | `petrified_wood` | épique | 120 | abattage, butin | usage direct |
| 🧭 Boussole | `compass` | peu commun | 70 | établi | usage direct |
| 🧭 Boussole ancienne | `old_compass` | épique | 260 | pêche | usage direct |
| 🎁 Boîte à bijoux | `jewel_box` | rare | 90 | établi | usage direct |
| ⭕ Bracelet | `bracelet` | rare | 180 | établi | usage direct |
| 🔶 Broche | `brooch` | épique | 220 | établi | usage direct |
| 🖌️ Brosse | `brush` | commun | 8 | atelier | usage direct |
| 📦 Caisse de fruits | `fruit_crate` | rare | 90 | atelier | usage direct |
| 🗺️ Carte du monde | `map_world` | rare | 160 | atelier | usage direct |
| 🗺️ Carte maritime | `sea_chart` | rare | 120 | atelier | usage direct |
| 🗺️ Carte régionale | `map_region` | peu commun | 40 | atelier | 1 recette, usage direct |
| ⭕ Cerceau | `hoop` | commun | 6 | atelier | usage direct |
| 🪁 Cerf-volant | `kite` | peu commun | 20 | atelier | usage direct |
| 🗝️ Clé ancienne | `ancient_key` | rare | 120 | trésor | usage direct |
| 🗝️ Clé rouillée | `rusty_key` | rare | 10 | fouille, butin | usage direct |
| 📦 Coffre de ravitaillement | `supply_chest` | rare | 120 | établi | usage direct |
| 📿 Collier | `necklace` | épique | 300 | établi | usage direct |
| 📃 Contrat de recrutement | `recruit_contract` | peu commun | 40 | atelier | usage direct |
| 📃 Contrat de vente | `contract` | peu commun | 20 | atelier | usage direct |
| 🐚 Coquillage rare | `rare_shell` | rare | 90 | pêche | usage direct |
| ➰ Corde d'escalade | `climbing_rope` | peu commun | 30 | atelier | usage direct |
| 📯 Corne de bête rare | `rare_horn` | épique | 260 | chasse, butin | usage direct |
| 👑 Couronne | `crown` | légendaire | 1500 | établi | usage direct |
| 👑 Couronne oubliée | `lost_crown` | légendaire | 1500 | boss | 1 recette, usage direct |
| 🛏️ Couverture | `blanket` | peu commun | 50 | atelier | usage direct |
| 🏺 Céramique décorée | `decorated_ceramic` | rare | 90 | four | usage direct |
| 💗 Cœur minéral | `mineral_heart` | épique | 500 | événement, butin | usage direct |
| 💎 Diamant | `diamond` | légendaire | 500 | minage | 1 recette, usage direct |
| 📜 Diplôme d'apprentissage | `diploma` | rare | 80 | atelier | usage direct |
| 🗿 Figurine en bois | `wood_figurine` | peu commun | 40 | atelier | usage direct |
| 🗿 Figurine en pierre | `stone_figurine` | peu commun | 60 | atelier | usage direct |
| 🦴 Fossile | `fossil` | rare | 120 | minage, fouille | usage direct |
| ⛰️ Fragment d'inscription | `inscription` | épique | 50 | fouille | usage direct |
| 🛡️ Insigne de garde | `guard_badge` | peu commun | 60 | établi, butin | usage direct |
| ⭐ Insigne de shérif | `sheriff_badge` | rare | 200 | événement | usage direct |
| 💰 Jeton d'événement | `event_token` | peu commun | 30 | événement | usage direct |
| 🃏 Jeu de cartes | `cards` | peu commun | 30 | atelier | usage direct |
| 🎲 Jeu de dés | `dice` | commun | 10 | atelier | usage direct |
| ♟️ Jeu de plateau | `board_game` | peu commun | 40 | atelier | usage direct |
| 🧸 Jouet en bois | `wood_toy` | peu commun | 20 | atelier | usage direct |
| ✉️ Lettre de recommandation | `recommendation` | peu commun | 60 | atelier, événement | usage direct |
| 🥇 Lingot précieux | `precious_ingot` | épique | 400 | four | usage direct |
| 📖 Livre d'histoire | `history_book` | rare | 100 | établi | 1 recette, usage direct |
| 🎶 Livre de chansons | `songbook` | peu commun | 60 | atelier | usage direct |
| 📚 Livre rare | `rare_book` | épique | 400 | événement, trésor | usage direct |
| 🔭 Longue-vue | `spyglass` | épique | 220 | établi | usage direct |
| 📦 Marchandise emballée | `packed_goods` | rare | 160 | atelier | usage direct |
| 🔍 Miroir de poche | `pocket_mirror` | peu commun | 40 | établi | usage direct |
| 🏅 Médaille de concours | `medal` | rare | 120 | établi | usage direct |
| 🏺 Objet d'une ruine | `ruin_piece` | rare | 150 | événement | usage direct |
| ❔ Objet perdu | `lost_item` | peu commun | 30 | événement, cueillette, butin | usage direct |
| 🛏️ Oreiller | `pillow` | peu commun | 24 | atelier | 1 recette, usage direct |
| 🦴 Os fossilisé | `fossil_bone` | épique | 140 | minage, butin | usage direct |
| 🧺 Panier de légumes | `veg_basket` | rare | 80 | atelier | usage direct |
| 🧺 Panier en osier | `wicker_basket` | commun | 16 | atelier | 2 recettes, usage direct |
| 🌸 Parfum | `perfume` | rare | 90 | atelier | usage direct |
| 💈 Peigne | `comb` | commun | 8 | atelier | usage direct |
| ⚪ Perle | `pearl` | rare | 90 | pêche, trésor, butin, boss | 1 recette, usage direct |
| 💠 Pierre colorée | `colored_stone` | peu commun | 30 | cueillette, butin | usage direct |
| ⛰️ Pierre gravée | `carved_stone` | épique | 90 | minage, butin | 1 recette, usage direct |
| 💰 Pièce ancienne | `ancient_coin` | rare | 80 | minage, fouille, trésor, butin | usage direct |
| ⚪ Pièce d'argent | `silver_coin` | commun | 10 | événement, fouille, trésor | usage direct |
| 🟡 Pièce d'or | `gold_coin` | épique | 50 | fouille, trésor | usage direct |
| 🟠 Pièce de cuivre | `copper_coin` | commun | 1 | fouille, butin | usage direct |
| ⚖️ Poids de mesure | `weights` | peu commun | 30 | four | usage direct |
| 🧸 Poupée de chiffon | `rag_doll` | peu commun | 24 | atelier | usage direct |
| 📒 Registre de patrouille | `patrol_log` | peu commun | 30 | atelier | usage direct |
| 🏺 Relique | `relic` | épique | 300 | événement, trésor | usage direct |
| 🏆 Ruban de champion | `champion_ribbon` | rare | 200 | événement | usage direct |
| 🎀 Ruban de compétition | `ribbon` | peu commun | 40 | atelier | usage direct |
| 🔴 Rubis | `ruby` | épique | 250 | minage, trésor, butin | 2 recettes, usage direct |
| ⏳ Sablier | `hourglass` | peu commun | 60 | établi | usage direct |
| 🛍️ Sac d'épices | `spice_sack` | épique | 220 | atelier | usage direct |
| 🛍️ Sac de farine | `flour_sack` | peu commun | 60 | atelier | usage direct |
| 🛍️ Sac de sel | `salt_sack` | peu commun | 60 | atelier | usage direct |
| 🎒 Sac à dos | `backpack` | rare | 80 | établi | usage direct |
| 👜 Sacoche en cuir | `satchel` | peu commun | 40 | établi | usage direct |
| 🔵 Saphir | `sapphire` | épique | 250 | minage, trésor | 1 recette, usage direct |
| 🔴 Sceau | `seal` | peu commun | 40 | établi | usage direct |
| 👑 Sceau royal | `royal_seal` | épique | 500 | événement, boss | usage direct |
| 🧺 Serviette en lin | `towel` | peu commun | 20 | atelier | usage direct |
| 🖼️ Tableau | `painting` | rare | 180 | atelier | 1 recette, usage direct |
| 🧿 Talisman | `talisman` | peu commun | — | événement | usage direct |
| 🎐 Tissu précieux | `fine_cloth` | rare | 160 | atelier | 2 recettes, usage direct |
| 🏺 Vase ancien | `old_vase` | rare | 160 | événement, trésor | usage direct |
| 🐉 Écaille ancienne | `ancient_scale` | épique | 300 | chasse | usage direct |
| 🟢 Émeraude | `emerald` | épique | 280 | minage, trésor | usage direct |
| 📜 Étui à parchemins | `scroll_case` | peu commun | 30 | établi | usage direct |

### Objets posés et mobilier (117)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 💧 Abreuvoir | `trough` | commun | — | atelier | usage direct |
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
| 🚩 Bannière de clan | `clan_banner` | commun | 60 | établi | usage direct |
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
| 🌾 Mangeoire | `feeder` | commun | — | atelier | usage direct |
| 🏰 Meurtrière | `arrow_slit` | commun | — | atelier | usage direct |
| 🌬️ Moulin | `windmill` | commun | — | établi | usage direct |
| 🧶 Métier à tisser | `loom` | commun | — | établi | usage direct |
| 🛏️ Paillasse | `straw_bed` | commun | — | atelier | usage direct |
| 🌲 Palissade | `palisade` | commun | — | atelier | usage direct |
| 🚩 Panneau de propriété | `claim` | commun | — | atelier | usage direct |
| 🖼️ Peinture murale | `painting_wall` | commun | — | atelier | usage direct |
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
| 🏛️ Socle | `pedestal` | commun | — | atelier | usage direct |
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

### Objets utilisables (53)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🚩 Bannière de clan | `banniere` | rare | 80 | établi | usage direct |
| ⛵ Barque | `barque` | rare | 120 | établi | usage direct |
| 👝 Bourse | `coin_purse` | peu commun | — | chasse, butin | usage direct |
| 👝 Bourse de marchand | `merchant_purse` | commun | — | événement, butin | usage direct |
| 🍾 Bouteille à la mer | `message_bottle` | rare | — | pêche | usage direct |
| 🌿 Bouture de saule | `seed_tree_saule` | commun | 4 | abattage | usage direct |
| 📓 Carnet du crocheteur | `manual_lock` | rare | 200 | établi | usage direct |
| 🗺️ Carte au trésor | `treasure_map` | commun | — | atelier, événement, chasse, butin | usage direct |
| 🔔 Clochette | `bell_small` | commun | 20 | atelier | usage direct |
| 🔔 Clochette de troupeau | `herd_bell` | commun | 20 | atelier | usage direct |
| 📯 Corne d'appel | `horn_call` | commun | 60 | établi | usage direct |
| 🪔 Encens | `incense` | commun | 20 | atelier | usage direct |
| 🌱 Engrais d'os | `bonemeal` | commun | 10 | atelier | usage direct |
| 🎶 Flûte | `flute` | commun | 40 | établi | usage direct |
| 🌰 Gland (chêne) | `seed_tree_chene` | commun | 4 | abattage | usage direct |
| 🏺 Gourde | `gourd` | commun | 14 | atelier | usage direct |
| 🌱 Graine de bouleau | `seed_tree_bouleau` | commun | 4 | abattage | usage direct |
| 🎼 Harpe | `harp` | épique | 240 | établi | usage direct |
| 📔 Journal d'un voyageur | `traveler_journal` | commun | — | événement | usage direct |
| 📃 Lettre de change | `bill_exchange` | peu commun | — | événement | usage direct |
| 📖 Livre de botanique | `botany_book` | rare | 160 | établi | usage direct |
| 📕 Livre de compétence | `skill_book` | rare | 200 | établi | usage direct |
| 📖 Livre de recettes | `recipe_book` | rare | 160 | établi | usage direct |
| 📖 Livre des créatures | `creature_book` | rare | 180 | établi | usage direct |
| 🪕 Luth | `lute` | rare | 160 | établi | usage direct |
| 📗 Manuel d'agriculture | `manual_farm` | rare | 120 | établi | usage direct |
| 📓 Manuel d'artisanat | `manual_craft` | rare | 140 | établi | usage direct |
| 📗 Manuel d'élevage | `manual_herd` | rare | 120 | établi | usage direct |
| 📙 Manuel de cuisine | `manual_cook` | rare | 120 | établi | usage direct |
| 📒 Manuel de dressage | `manual_tame` | rare | 120 | établi | usage direct |
| 📘 Manuel de pêche | `manual_fish` | rare | 120 | établi | usage direct |
| 📔 Manuel du bûcheron | `manual_wood` | rare | 120 | établi | usage direct |
| 📔 Manuel du mineur | `manual_mine` | rare | 140 | établi | usage direct |
| 🧺 Nasse | `nasse` | commun | 35 | établi | usage direct |
| 🌾 Nourriture animale | `animal_feed` | commun | 6 | atelier | usage direct |
| 🍒 Noyau de cerise | `seed_tree_cerisier` | commun | 6 | abattage | usage direct |
| 🏺 Outre en cuir | `waterskin` | commun | 18 | établi | usage direct |
| 📐 Plan d'artisan | `craftsman_plan` | commun | — | événement | usage direct |
| 🌲 Pomme de pin (sapin) | `seed_tree_sapin` | commun | 4 | abattage | usage direct |
| ✨ Poudre minérale | `mineral_powder` | commun | 14 | four | usage direct |
| 📜 Recette inconnue | `unknown_recipe` | commun | — | événement | usage direct |
| 📒 Registre commercial | `ledger` | commun | 50 | établi | usage direct |
| 🎁 Récompense de festival | `festival_prize` | commun | — | événement | usage direct |
| 🌱 Sac de compost | `compost` | commun | 8 | atelier | usage direct |
| 🛍️ Sac de graines | `seed_sack` | commun | 40 | atelier | usage direct |
| 🧼 Savon | `soap` | commun | 12 | atelier | usage direct |
| 💧 Seau d'eau | `bucket` | commun | 22 | code:Machines | 2 recettes, usage direct |
| 🧺 Seau vide | `bucket_empty` | commun | 20 | atelier | 1 recette, usage direct |
| 🥁 Tambour | `drum` | rare | 80 | établi | usage direct |
| 🎺 Trompette | `trumpet` | rare | 140 | établi | usage direct |
| 🧰 Trousse d'artisan | `craft_kit` | rare | 80 | établi | usage direct |
| ⛵ Voilier | `voilier` | épique | 420 | établi | usage direct |
| 🥚 Œuf mystérieux | `mystery_egg` | épique | — | chasse | usage direct |

### Outils et armes (14)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🚿 Arrosoir | `can` | peu commun | 40 | atelier, boutique | usage direct |
| ⛏ Bêche de terrassier | `spade` | rare | 90 | atelier | usage direct |
| 🎣 Canne à pêche | `rod` | peu commun | 50 | atelier, boutique | usage direct |
| 🏏 Gourdin | `club` | peu commun | 20 | atelier | usage direct |
| 🪓 Hache de cuivre | `axe_cu` | rare | 140 | atelier | usage direct |
| 🪓 Hache de fer | `axe_fe` | épique | 260 | atelier | usage direct |
| 🪓 Hache de pierre | `axe` | peu commun | 60 | atelier, boutique | usage direct |
| ⛏ Houe | `hoe` | peu commun | 40 | atelier, boutique | usage direct |
| 🧺 Pelle | `shovel` | peu commun | 50 | atelier, boutique | usage direct |
| ⛏️ Pioche de cuivre | `pickaxe_cu` | rare | 140 | atelier | usage direct |
| ⛏️ Pioche de fer | `pickaxe_fe` | épique | 260 | atelier | usage direct |
| ⛏️ Pioche de pierre | `pickaxe` | peu commun | 60 | atelier, boutique | usage direct |
| 🗡️ Épée de cuivre | `sword` | rare | 150 | atelier, boutique | usage direct |
| ⚔️ Épée de fer | `sword_fe` | épique | 320 | atelier | usage direct |

### Pièces de construction (111)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| ➖ Barrière (Bois) | `blk_barriere_bois` | commun | 2 | atelier | usage direct |
| ➖ Barrière (Fer) | `blk_barriere_fer` | commun | 45 | établi | usage direct |
| ⬛ Bloc (Bois) | `blk_bloc_bois` | commun | 4 | atelier | usage direct |
| ⬛ Bloc (Brique) | `blk_bloc_brique` | commun | 12 | établi | usage direct |
| ⬛ Bloc (Pierre taillée) | `blk_bloc_taille` | commun | 12 | établi | usage direct |
| ⬛ Bloc (Pierre) | `blk_bloc_pierre` | commun | 8 | établi | usage direct |
| ⬛ Bloc (Pisé) | `blk_bloc_pise` | commun | 4 | atelier | usage direct |
| ⬛ Bloc (Rondins) | `blk_bloc_rondin` | commun | 8 | atelier | usage direct |
| ⬛ Bloc (Torchis) | `blk_bloc_torchis` | commun | 8 | atelier | usage direct |
| ⬛ Bloc (Verre) | `blk_bloc_verre` | commun | 16 | établi | usage direct |
| 🧱 Cloison (Bois) | `blk_mince_bois` | commun | 2 | atelier | usage direct |
| 🧱 Cloison (Torchis) | `blk_mince_torchis` | commun | 4 | atelier | usage direct |
| 🧱 Cloison (Verre) | `blk_mince_verre` | commun | 8 | établi | usage direct |
| 🔺 Coin de toit (Ardoise) | `blk_coin_ardoise` | commun | 8 | établi | usage direct |
| 🔺 Coin de toit (Bardeaux) | `blk_coin_bardeau` | commun | 8 | établi | usage direct |
| 🔺 Coin de toit (Bois) | `blk_coin_bois` | commun | 4 | atelier | usage direct |
| 🔺 Coin de toit (Chaume) | `blk_coin_chaume` | commun | 4 | atelier | usage direct |
| 🔺 Coin de toit (Pierre) | `blk_coin_pierre` | commun | 8 | établi | usage direct |
| 🔺 Coin de toit (Tuiles) | `blk_coin_tuile` | commun | 12 | établi | usage direct |
| 🏛️ Colonne (Brique) | `blk_colonne_brique` | commun | 24 | établi | usage direct |
| 🏛️ Colonne (Pierre taillée) | `blk_colonne_taille` | commun | 24 | établi | usage direct |
| 🏛️ Colonne (Pierre) | `blk_colonne_pierre` | commun | 16 | établi | usage direct |
| 🟫 Dalle (Ardoise) | `blk_dalle_ardoise` | commun | 4 | établi | usage direct |
| 🟫 Dalle (Bardeaux) | `blk_dalle_bardeau` | commun | 4 | établi | usage direct |
| 🟫 Dalle (Bois) | `blk_dalle_bois` | commun | 2 | atelier | usage direct |
| 🟫 Dalle (Chaume) | `blk_dalle_chaume` | commun | 2 | atelier | usage direct |
| 🟫 Dalle (Pierre taillée) | `blk_dalle_taille` | commun | 6 | établi | usage direct |
| 🟫 Dalle (Pierre) | `blk_dalle_pierre` | commun | 4 | établi | usage direct |
| 🟫 Dalle (Pisé) | `blk_dalle_pise` | commun | 2 | atelier | usage direct |
| 🟫 Dalle (Tuiles) | `blk_dalle_tuile` | commun | 6 | établi | usage direct |
| 🔝 Escalier | `stairs` | commun | — | ? | usage direct |
| 🧱 Grand mur (Bois) | `blk_grandmur_bois` | commun | 10 | atelier | usage direct |
| 🧱 Grand mur (Brique) | `blk_grandmur_brique` | commun | 30 | établi | usage direct |
| 🧱 Grand mur (Pierre taillée) | `blk_grandmur_taille` | commun | 30 | établi | usage direct |
| 🧱 Grand mur (Pierre) | `blk_grandmur_pierre` | commun | 20 | établi | usage direct |
| 🧱 Grand mur (Pisé) | `blk_grandmur_pise` | commun | 10 | atelier | usage direct |
| 🧱 Grand mur (Rondins) | `blk_grandmur_rondin` | commun | 20 | atelier | usage direct |
| 🧱 Grand mur (Torchis) | `blk_grandmur_torchis` | commun | 20 | atelier | usage direct |
| 🏛️ Grand poteau (Bois) | `blk_hautpoteau_bois` | commun | 4 | atelier | usage direct |
| 🏛️ Grand poteau (Fer) | `blk_hautpoteau_fer` | rare | 90 | établi | usage direct |
| 🏛️ Grand poteau (Rondins) | `blk_hautpoteau_rondin` | commun | 8 | atelier | usage direct |
| 🟫 Grande dalle (Bois) | `blk_plancher_bois` | commun | 4 | atelier | usage direct |
| 🟫 Grande dalle (Pierre taillée) | `blk_plancher_taille` | commun | 12 | établi | usage direct |
| 🟫 Grande dalle (Pierre) | `blk_plancher_pierre` | commun | 8 | établi | usage direct |
| 🧱 Grande échelle (Bois) | `blk_grandeechelle_bois` | commun | 6 | atelier | usage direct |
| 🧱 Grande échelle (Fer) | `blk_grandeechelle_fer` | rare | 135 | établi | usage direct |
| 🧱 Grande échelle (Rondins) | `blk_grandeechelle_rondin` | commun | 12 | atelier | usage direct |
| 🔲 Grille (Fer) | `blk_grille_fer` | rare | 90 | établi | usage direct |
| 📏 Linteau (Bois) | `blk_linteau_bois` | commun | 2 | atelier | usage direct |
| 📏 Linteau (Fer) | `blk_linteau_fer` | commun | 45 | établi | usage direct |
| 📏 Linteau (Pierre taillée) | `blk_linteau_taille` | commun | 6 | établi | usage direct |
| 📏 Linteau (Pierre) | `blk_linteau_pierre` | commun | 4 | établi | usage direct |
| 📐 Marche (Bois) | `blk_marche_bois` | commun | 2 | atelier | usage direct |
| 📐 Marche (Pierre taillée) | `blk_marche_taille` | commun | 6 | établi | usage direct |
| 📐 Marche (Pierre) | `blk_marche_pierre` | commun | 4 | établi | usage direct |
| 🖼️ Mur avec fenêtre | `wall_window` | commun | — | ? | usage direct |
| 🚪 Mur avec porte | `wall_door` | commun | — | ? | usage direct |
| 🧱 Mur d'étage | `wall2` | commun | — | ? | usage direct |
| 🖼️ Mur d'étage avec fenêtre | `wall2_window` | commun | — | ? | usage direct |
| 🧱 Mur de briques | `wall_brick` | commun | — | ? | usage direct |
| 🧱 Mur de pierre | `wall_stone` | commun | — | ? | usage direct |
| 🚪 Mur en planches | `wall` | commun | — | ? | usage direct |
| 🧱 Muret (Bois) | `blk_demimur_bois` | commun | 4 | atelier | usage direct |
| 🧱 Muret (Brique) | `blk_demimur_brique` | commun | 12 | établi | usage direct |
| 🧱 Muret (Pierre taillée) | `blk_demimur_taille` | commun | 12 | établi | usage direct |
| 🧱 Muret (Pierre) | `blk_demimur_pierre` | commun | 8 | établi | usage direct |
| 🧱 Muret (Pisé) | `blk_demimur_pise` | commun | 4 | atelier | usage direct |
| 🧱 Muret (Rondins) | `blk_demimur_rondin` | commun | 8 | atelier | usage direct |
| 🧱 Pan de mur (Bois) | `blk_mur_bois` | commun | 6 | atelier | usage direct |
| 🧱 Pan de mur (Brique) | `blk_mur_brique` | commun | 18 | établi | usage direct |
| 🧱 Pan de mur (Pierre taillée) | `blk_mur_taille` | commun | 18 | établi | usage direct |
| 🧱 Pan de mur (Pierre) | `blk_mur_pierre` | commun | 12 | établi | usage direct |
| 🧱 Pan de mur (Pisé) | `blk_mur_pise` | commun | 6 | atelier | usage direct |
| 🧱 Pan de mur (Rondins) | `blk_mur_rondin` | commun | 12 | atelier | usage direct |
| 🧱 Pan de mur (Torchis) | `blk_mur_torchis` | commun | 12 | atelier | usage direct |
| 🧱 Pan de mur (Verre) | `blk_mur_verre` | commun | 24 | établi | usage direct |
| 🔺 Pente de toit (Ardoise) | `blk_pente_ardoise` | commun | 12 | établi | usage direct |
| 🔺 Pente de toit (Bardeaux) | `blk_pente_bardeau` | commun | 12 | établi | usage direct |
| 🔺 Pente de toit (Bois) | `blk_pente_bois` | commun | 6 | atelier | usage direct |
| 🔺 Pente de toit (Chaume) | `blk_pente_chaume` | commun | 6 | atelier | usage direct |
| 🔺 Pente de toit (Pierre) | `blk_pente_pierre` | commun | 12 | établi | usage direct |
| 🔺 Pente de toit (Tuiles) | `blk_pente_tuile` | commun | 18 | établi | usage direct |
| 🔺 Pente raide (Ardoise) | `blk_toitpointu_ardoise` | commun | 8 | établi | usage direct |
| 🔺 Pente raide (Bardeaux) | `blk_toitpointu_bardeau` | commun | 8 | établi | usage direct |
| 🔺 Pente raide (Bois) | `blk_toitpointu_bois` | commun | 4 | atelier | usage direct |
| 🔺 Pente raide (Chaume) | `blk_toitpointu_chaume` | commun | 4 | atelier | usage direct |
| 🔺 Pente raide (Pierre taillée) | `blk_toitpointu_taille` | commun | 12 | établi | usage direct |
| 🔺 Pente raide (Tuiles) | `blk_toitpointu_tuile` | commun | 12 | établi | usage direct |
| 🏛️ Pilier rond (Bois) | `blk_pilier_bois` | commun | 4 | atelier | usage direct |
| 🏛️ Pilier rond (Brique) | `blk_pilier_brique` | commun | 12 | établi | usage direct |
| 🏛️ Pilier rond (Pierre taillée) | `blk_pilier_taille` | commun | 12 | établi | usage direct |
| 🏛️ Pilier rond (Pierre) | `blk_pilier_pierre` | commun | 8 | établi | usage direct |
| 🏛️ Pilier rond (Rondins) | `blk_pilier_rondin` | commun | 8 | atelier | usage direct |
| 🟫 Plancher | `floor` | commun | — | code:Shop | usage direct |
| 🟫 Plancher d'étage | `floor2` | commun | — | ? | usage direct |
| 🚪 Porte en bois | `door` | commun | — | établi | usage direct |
| 🏛️ Poteau (Bois) | `blk_poteau_bois` | commun | 2 | atelier | usage direct |
| 🏛️ Poteau (Fer) | `blk_poteau_fer` | commun | 45 | établi | usage direct |
| 🏛️ Poteau (Rondins) | `blk_poteau_rondin` | commun | 4 | atelier | usage direct |
| 📏 Poutre (Bois) | `blk_poutre_bois` | commun | 2 | atelier | usage direct |
| 📏 Poutre (Fer) | `blk_poutre_fer` | commun | 45 | établi | usage direct |
| 📏 Poutre (Pierre) | `blk_poutre_pierre` | commun | 4 | établi | usage direct |
| 📏 Poutre (Rondins) | `blk_poutre_rondin` | commun | 4 | atelier | usage direct |
| 📐 Rampe / marches (Bois) | `blk_rampe_bois` | commun | 8 | atelier | usage direct |
| 📐 Rampe / marches (Pierre taillée) | `blk_rampe_taille` | commun | 24 | établi | usage direct |
| 📐 Rampe / marches (Pierre) | `blk_rampe_pierre` | commun | 16 | établi | usage direct |
| 🏠 Toit d'étage | `roof2` | commun | — | code:Shop | usage direct |
| 🏠 Toit de chaume | `roof` | commun | — | code:Shop | usage direct |
| 🧱 Échelle (Bois) | `blk_echelle_bois` | commun | 4 | atelier | usage direct |
| 🧱 Échelle (Fer) | `blk_echelle_fer` | rare | 90 | établi | usage direct |
| 🧱 Échelle (Rondins) | `blk_echelle_rondin` | commun | 8 | atelier | usage direct |

### Ressources et matières (153)

| Objet | id | Rareté | Valeur | Obtention | Usages |
|---|---|---|---|---|---|
| 🔩 Acier | `steel` | rare | 90 | four, butin | 19 recettes |
| 🏺 Amphore | `amphora` | commun | 40 | four | 3 recettes |
| ⭕ Anneau métallique | `iron_ring` | commun | 5 | atelier, butin | 10 recettes |
| 🐛 Appâts | `bait` | commun | 2 | atelier, butin | code:Bestiaire |
| 🟤 Argile | `clay` | commun | 4 | butin | 8 recettes |
| 🟤 Argile préparée | `prepared_clay` | commun | 5 | atelier | 6 recettes |
| 🍽️ Assiette | `plate` | commun | 10 | four | code:Joueurs |
| 🍽️ Assiette en bois | `wood_plate` | commun | 2 | atelier | code:Joueurs |
| 🦯 Barre de fer | `iron_bar` | commun | 30 | four | 11 recettes |
| 🌲 Bois | `wood` | commun | 2 | code:Main | 25 recettes |
| 🦌 Bois de cerf | `antler` | commun | 24 | butin | 1 recette |
| 🥣 Bol | `bowl` | commun | 8 | four | 1 recette |
| 🔘 Boucle | `buckle` | commun | 6 | atelier | 6 recettes |
| 🕯️ Bougie (cire) | `candle_wax` | commun | 10 | atelier | 2 recettes |
| 🍾 Bouteille en verre | `bottle` | commun | 12 | four | 3 recettes |
| 🌿 Branches | `branches` | commun | 1 | abattage | 4 recettes |
| 🧱 Brique | `brick` | commun | 6 | four | 12 recettes |
| 🌼 Camomille | `chamomile` | commun | 6 | cueillette | 3 recettes |
| 🐞 Carapace dorée (Scarabée royal) | `golden_carapace` | légendaire | 800 | boss | 1 recette |
| 📌 Carreaux | `bolt` | commun | 3 | établi, boutique | revente |
| 🔱 Carreaux de baliste | `bolt_heavy` | commun | 30 | établi, boutique | revente |
| 🧟 Chair pourrie | `rotten` | commun | 1 | butin | 2 recettes |
| 🍄 Champignon phosphorescent | `glow_mushroom` | rare | 80 | cueillette de nuit | revente |
| 🍄 Champignon rare | `rare_mushroom` | peu commun | 60 | cueillette | revente |
| ⚫ Charbon | `coal` | commun | 6 | four, boutique | 12 recettes |
| 🔩 Charnière | `hinge` | commun | 10 | atelier | 8 recettes |
| ⛓️ Chaîne | `chain` | commun | 24 | atelier | 4 recettes |
| 🌲 Chevilles en bois | `peg` | commun | 1 | atelier | 1 recette |
| 🍺 Chope en métal | `tankard` | commun | 26 | établi | 1 recette |
| 🍺 Chope en terre cuite | `mug` | commun | 10 | four | 3 recettes |
| 🕯️ Cire d'abeille | `beeswax` | commun | 14 | atelier, butin | 2 recettes |
| 📌 Clous | `nails` | commun | 3 | atelier | 10 recettes |
| 📌 Clous de cuivre | `copper_nails` | commun | 2 | atelier | 1 recette |
| 📿 Collier de chien | `dog_collar` | commun | 30 | établi | code:Compagnons |
| ➰ Corde | `rope` | commun | 5 | atelier, boutique, butin | 34 recettes |
| ➰ Corde tressée | `braided_rope` | commun | 14 | établi | 2 recettes |
| 📯 Corne | `horn` | commun | 20 | chasse, butin | 1 recette |
| 💎 Cristal ancien | `ancient_crystal` | épique | 260 | minage, butin | code:Bestiaire |
| ❄️ Cristal de givre (Brumeglace) | `frost_crystal` | légendaire | 800 | boss | 1 recette |
| 🧊 Cristal de glace | `ice_crystal` | commun | 40 | butin, boss | 2 recettes |
| 🎣 Crochet | `lockpick` | commun | 15 | établi, atelier, butin | 1 recette |
| 🏺 Cruche | `jug` | commun | 18 | four | code:Shop |
| 🥄 Cuillère en bois | `spoon` | commun | 1 | atelier | code:Shop |
| 🟫 Cuir | `leather` | commun | 14 | butin | 42 recettes |
| 🟫 Cuir souple | `soft_leather` | commun | 30 | atelier | 6 recettes |
| ❄️ Cœur gelé | `frozen_heart` | légendaire | 600 | boss | 1 recette |
| 🦂 Dard de scorpion | `stinger` | commun | 25 | butin | 1 recette |
| 🦷 Dent | `tooth` | commun | 6 | chasse, butin | code:Bestiaire |
| 🦷 Dent de monstre | `monster_tooth` | commun | 60 | chasse, butin | 1 recette |
| 🖋️ Encre | `ink` | commun | 8 | atelier | 26 recettes |
| 🖋️ Encrier | `inkwell` | commun | 16 | établi | 1 recette |
| ⚙️ Engrenage en bois | `gear_wood` | commun | 12 | établi | 4 recettes |
| ⚙️ Engrenage en fer | `gear_iron` | commun | 50 | atelier | 3 recettes |
| 🌾 Farine | `flour` | commun | 18 | code:Machines | 2 recettes |
| 🔩 Ferrure | `fitting` | commun | 8 | atelier | 1 recette |
| 🌿 Fibre | `fiber` | commun | 1 | butin | 12 recettes |
| 🧶 Fil de laine | `wool_thread` | commun | 20 | atelier | 1 recette |
| 🧵 Fil de lin | `linen_thread` | commun | 6 | atelier | 4 recettes |
| 🧪 Fiole d'extrait | `extract` | commun | 30 | atelier, butin | 3 recettes |
| 🧪 Fiole vide | `vial` | commun | 10 | four, butin | 3 recettes |
| 🌼 Fleur | `flower` | commun | 5 | code:RegionPlan | 5 recettes |
| 🌙 Fleur lunaire | `moon_flower` | rare | 180 | cueillette de nuit | revente |
| 🌙 Fleur nocturne | `night_flower` | commun | 70 | cueillette de nuit, butin | 1 recette |
| 🌾 Foin | `hay` | commun | 3 | atelier | 2 recettes |
| 🦊 Fourrure | `fur` | commun | 18 | butin | 3 recettes |
| 🐺 Fourrure royale (Vargor) | `royal_fur` | légendaire | 700 | boss | 1 recette |
| 🦊 Fourrure travaillée | `worked_fur` | commun | 36 | atelier | 1 recette |
| 🧩 Fragment de carte | `map_fragment` | rare | 20 | pêche | 1 recette |
| ☄️ Fragment de météorite | `meteorite` | épique | 400 | événement | 1 recette |
| 🧩 Fragment de relique | `relic_fragment` | rare | 40 | fouille, butin | 1 recette |
| 🟢 Gelée de slime | `slime_gel` | commun | 6 | butin, boss | 1 recette |
| 🥤 Gobelet en bois | `wood_cup` | commun | 2 | atelier | 4 recettes |
| 🌰 Graine ancienne | `ancient_seed` | rare | 150 | boss | 1 recette |
| 🧈 Graisse | `fat` | commun | 6 | atelier, butin | 3 recettes |
| ⛰️ Gravier | `gravel` | commun | 1 | atelier, minage | revente |
| 🐾 Griffe de créature | `claw` | commun | 50 | chasse, butin | code:Bestiaire |
| 🎣 Hameçon | `hook` | commun | 6 | atelier | 3 recettes |
| 🌿 Huile | `oil` | commun | 14 | établi | 1 recette |
| 🧶 Laine | `wool` | commun | 60 | élevage | 2 recettes |
| 🔪 Lame brute | `blade` | commun | 40 | atelier | 1 recette |
| 💜 Lavande | `lavender` | commun | 9 | cueillette | 2 recettes |
| 🥈 Lingot d'argent | `silver_ingot` | rare | 80 | four | 8 recettes |
| 🥇 Lingot d'or | `gold_ingot` | rare | 120 | four | 15 recettes |
| 🥉 Lingot de cuivre | `copper_ingot` | commun | 30 | four | 32 recettes |
| 🔩 Lingot de fer | `iron_ingot` | commun | 45 | four | 48 recettes |
| 🔒 Loquet en bois | `lock_1` | commun | 20 | atelier | revente |
| 🥄 Louche | `ladle` | commun | 8 | établi | code:Shop |
| 🌱 Mandragore | `mandrake` | rare | 120 | cueillette, butin | 1 recette |
| 🌿 Menthe | `mint` | commun | 6 | cueillette | 1 recette |
| 🌼 Millepertuis | `st_john` | commun | 12 | cueillette | 1 recette |
| ⚪ Minerai d'argent | `silver_ore` | commun | 30 | minage | 1 recette |
| 🟡 Minerai d'or | `gold_ore` | commun | 45 | boss | 1 recette |
| 🟠 Minerai de cuivre | `copper_ore` | commun | 10 | butin | 1 recette |
| ⛰️ Minerai de fer | `ore` | commun | 15 | butin | 2 recettes |
| 💰 Or | `gold` | commun | — | trésor | code:Activites |
| 🌿 Ortie | `nettle` | commun | 3 | cueillette, butin | 2 recettes |
| 🦴 Os | `bone` | commun | 4 | butin | 9 recettes |
| 🌾 Paille | `straw` | commun | 1 | atelier | 10 recettes |
| 📄 Papier | `paper` | commun | 4 | établi | 19 recettes |
| 📜 Parchemin vierge | `parchment` | commun | 8 | établi | 6 recettes |
| 🟫 Peau brute | `raw_hide` | commun | 10 | chasse, butin | 1 recette |
| 🦌 Peau de cerf | `deer_hide` | commun | 22 | chasse, butin | code:Bestiaire |
| 🐺 Peau de loup | `wolf_pelt` | commun | 28 | chasse, boss, butin | code:Bestiaire |
| 🟫 Peau raclée | `scraped_hide` | commun | 14 | atelier | 1 recette |
| ⛰️ Pierre | `stone` | commun | 2 | butin | 58 recettes |
| ✨ Pierre lumineuse | `glowstone` | rare | 120 | minage, butin | 1 recette |
| 🌲 Planches | `planks` | commun | 2 | atelier, boutique | 139 recettes |
| 🐦 Plume | `feather` | commun | 5 | butin | 4 recettes |
| 🐦 Plume d'écriture | `quill` | commun | 3 | atelier | code:Joueurs |
| 🐦 Plume nocturne | `night_feather` | rare | 90 | chasse, butin | code:Bestiaire |
| 🐟 Poisson | `fish` | commun | 0 | code:Evenements | 2 recettes |
| 🟡 Pollen | `pollen` | commun | 6 | abattage, cueillette, butin | code:Bestiaire |
| 🏺 Pot | `pot` | commun | 14 | four | 1 recette |
| ⚙️ Poulie | `pulley` | commun | 20 | établi | 3 recettes |
| ✨ Poussière de feu follet | `wisp_dust` | commun | 30 | butin | 2 recettes |
| 🌸 Pétales séchés | `dried_petals` | commun | 8 | atelier | 1 recette |
| 🌳 Racine ancienne | `ancient_root` | rare | 80 | butin, boss | 1 recette |
| 🔩 Rivets | `rivet` | commun | 2 | atelier | 2 recettes |
| 🌿 Romarin | `rosemary` | commun | 8 | cueillette | 2 recettes |
| 🌲 Rondin de chêne | `oak_log` | commun | 6 | abattage, butin | 12 recettes |
| 🌲 Rondin de pin | `pine_log` | commun | 5 | abattage | 4 recettes |
| 🎋 Roseaux | `reeds` | commun | 2 | cueillette | 2 recettes |
| 🟧 Résine | `resin` | commun | 8 | abattage, butin | 4 recettes |
| 🏜️ Sable | `sand` | commun | 1 | butin | 3 recettes |
| 🎗️ Sangles | `leather_strap` | commun | 8 | atelier | 6 recettes |
| 🌿 Sauge | `sage` | commun | 8 | cueillette | 2 recettes |
| 🔴 Sceau de cire | `wax_seal` | commun | 10 | atelier | 5 recettes |
| 🧂 Sel | `salt` | commun | 8 | minage, butin | 7 recettes |
| 🔒 Serrure de cuivre | `lock_2` | commun | 70 | établi | revente |
| 🔐 Serrure de fer | `lock_3` | rare | 140 | établi | revente |
| 🔐 Serrure à secret (or) | `lock_4` | épique | 320 | établi | revente |
| ⛰️ Silex | `flint` | commun | 4 | minage, fouille | 1 recette |
| 🕸️ Soie d'araignée | `silk` | commun | 12 | butin | 3 recettes |
| 🟡 Soufre | `sulfur` | commun | 12 | minage | 1 recette |
| 🍄 Spore royale | `royal_spore` | épique | 300 | boss | 1 recette |
| 🍬 Sucre | `sugar` | commun | 12 | four | 2 recettes |
| 🎨 Teinture | `dye` | commun | 10 | atelier | 14 recettes |
| 🟫 Terre | `dirt` | commun | 1 | butin | 6 recettes |
| 🌿 Thym | `thyme` | commun | 6 | cueillette | 1 recette |
| 🧵 Tissu | `cloth` | commun | 25 | atelier | 14 recettes |
| 🧶 Tissu de laine | `wool_cloth` | commun | 50 | atelier | 8 recettes |
| 🧵 Tissu de lin | `linen` | commun | 20 | atelier | 16 recettes |
| ⛵ Toile | `canvas` | commun | 30 | atelier | 4 recettes |
| 🎐 Toile enchantée | `enchanted_cloth` | épique | 220 | boss | 1 recette |
| 🌸 Valériane | `valerian` | commun | 14 | cueillette | 2 recettes |
| 🖼️ Verre | `glass` | commun | 8 | four | 15 recettes |
| 🏺 Vinaigre de pomme | `vinegar` | commun | 20 | atelier | 1 recette |
| 🖤 Écaille noire (Roi des marais) | `black_scale` | légendaire | 700 | boss | 1 recette |
| 🐉 Écailles | `scales` | commun | 16 | chasse, butin | 1 recette |
| 💎 Éclat de verre vivant | `glass_shard` | épique | 350 | boss | 1 recette |
| 🟫 Écorce | `bark` | commun | 2 | abattage | revente |
| 🌶️ Épices | `spice` | commun | 40 | événement | 1 recette |
| 🎨 Étoffe teinte | `dyed_cloth` | commun | 60 | atelier | 5 recettes |

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
| ⚪ Pièce d'argent | 1.2 % | tous |
| 💰 Pièce ancienne | 1 % | tous |
| 🗝️ Clé rouillée | 1 % | tous |
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
| 📐 Plan d'artisan | 8 % | tous |
| 📜 Recette inconnue | 8 % | tous |
| ✉️ Lettre de recommandation | 5 % | tous |
| 🗺️ Carte au trésor | 5 % | tous |
| 📔 Journal d'un voyageur | 5 % | tous |
| 📃 Lettre de change | 4 % | tous |
| 🏺 Vase ancien | 3 % | tous |
| 📚 Livre rare | 3 % | tous |
| 🏺 Objet d'une ruine | 3 % | tous |
| 🏆 Ruban de champion | 3 % | tous |
| 💍 Bijou ancien | 2 % | tous |
| 🏺 Relique | 2 % | tous |
| ☄️ Fragment de météorite | 2 % | tous |
| 🧿 Talisman | 2 % | tous |
| 👑 Sceau royal | 1 % | tous |
| ⭐ Insigne de shérif | 1 % | tous |
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
| 💰 Pièce ancienne | 0.6 % | tous |
| 🦴 Fossile | 0.6 % | tous |
| 🦴 Os fossilisé | 0.5 % | tous |
| 💎 Cristal ancien | 0.4 % | tous |
| ⛰️ Pierre gravée | 0.4 % | tous |
| 🔴 Rubis | 0.3 % | tous |
| 🔵 Saphir | 0.3 % | toundra |
| 🟢 Émeraude | 0.3 % | forêt rousse |
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
| Gardon | 40 | pêche 0 | 15 |
| Carpe | 30 | pêche 0 | 25 |
| Truite | 18 | pêche 5 | 40 |
| Poisson-chat | 15 | pêche 8 | 45 |
| Brochet | 12 | pêche 12 | 60 |
| Anguille | 8 | pêche 15 | 55 |
| Poisson doré | 2 | pêche 25 | 250 |

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
| Essaim d'abeilles sauvages | `bee_swarm` | 2 | 40 | 8 | charge, neutre, vole | forêt rousse (jour), prairie (jour) | 🍯 Miel 1–2 (80 %), 🕯️ Cire d'abeille 1–2 (80 %), 🟡 Pollen 1–3 (60 %) | 0 |
| Sanglier | `boar` | 2 | 120 | 16 | charge, neutre | génération | 🥩 Viande crue 2–3 (100 %), 🟫 Cuir 1–2 (80 %) | 0 |
| Chacal | `jackal` | 2 | 70 | 12 | charge, meute 3 | désert (jour) | 🟫 Peau brute 1–1 (60 %), 🦷 Dent 1–1 (40 %) | 0 |
| Slime bleu | `slime_blue` | 2 | 100 | 10 | hop | grottes prairie | 🟢 Gelée de slime 1–3 (80 %) | 0 |
| Serpent venimeux | `snake` | 2 | 60 | 16 | charge | prairie (jour) | 🐉 Écailles 1–2 (70 %), 🦷 Dent 1–1 (40 %) | 0 |
| Crapaud géant | `toad` | 2 | 110 | 12 | hop | génération | 🟢 Gelée de slime 1–2 (60 %), 🟫 Cuir 1–1 (40 %) | 0 |
| Chien sauvage | `wild_dog` | 2 | 70 | 12 | charge, meute 3 | prairie (jour) | 🟫 Peau brute 1–1 (60 %), 🦴 Os 1–2 (50 %) | 0 |
| Loup | `wolf` | 2 | 90 | 12 | charge, meute 3 | génération | 🦊 Fourrure 1–1 (70 %), 🥩 Viande crue 1–2 (90 %) | 0 |
| Bandit des routes | `bandit` | 3 | 150 | 18 | charge | prairie (jour) | 🟠 Pièce de cuivre 2–6 (100 %), 👝 Bourse 1–1 (15 %), ➰ Corde 1–1 (30 %), 🎣 Crochet 1–1 (20 %) | 2 |
| Lézard des tourbières | `bog_lizard` | 3 | 120 | 16 | charge | marais (jour) | 🐉 Écailles 1–2 (80 %), 🟫 Cuir 1–1 (40 %) | 0 |
| Cambrioleur | `burglar` | 3 | 120 | 12 | charge | génération | 🎣 Crochet 1–3 (90 %), ➰ Corde 1–2 (50 %) | 3 |
| Chauve-souris géante | `giant_bat` | 3 | 60 | 12 | charge, vole | grottes forêt rousse, grottes marais, grottes désert, grottes toundra, grottes prairie | 🟫 Peau brute 1–1 (50 %), 🦷 Dent 1–1 (40 %) | 0 |
| Corbeau géant | `giant_crow` | 3 | 80 | 14 | charge, nuit, vole | forêt rousse (nuit), prairie (nuit) | 🐦 Plume 2–4 (100 %), 🐦 Plume nocturne 1–1 (15 %) | 0 |
| Sangsue géante | `leech` | 3 | 90 | 14 | hop | marais (jour), grottes marais | 🟢 Gelée de slime 1–2 (80 %) | 0 |
| Lynx | `lynx` | 3 | 90 | 16 | charge | forêt rousse (jour) | 🦊 Fourrure 1–2 (90 %), 🐾 Griffe de créature 1–1 (40 %) | 0 |
| Myconide | `myconid` | 3 | 140 | 10 | spore | grottes forêt rousse | 🍄 Champignon 1–2 (100 %) | 0 |
| Braconnier | `poacher` | 3 | 120 | 14 | spore | forêt rousse (jour), prairie (jour) | 🦌 Peau de cerf 1–1 (50 %), 🥩 Viande de cerf 1–2 (60 %), 🐛 Appâts 2–4 (50 %) | 0 |
| Épouvantail maudit | `scarecrow` | 3 | 170 | 20 | charge, nuit | génération | 🌿 Fibre 2–4 (100 %), ✨ Poussière de feu follet 1–1 (30 %), 🌱 Graines (Citrouille) 1–2 (25 %) | 0 |
| Ombre rôdeuse | `shade` | 3 | 80 | 14 | charge, nuit, lumière | génération | ✨ Poussière de feu follet 1–2 (80 %), 🦴 Os 1–2 (50 %) | 0 |
| Squelette errant | `skeleton` | 3 | 110 | 16 | charge, nuit | forêt rousse (nuit), désert (nuit), toundra (nuit), prairie (nuit), grottes désert, grottes prairie | 🦴 Os 2–4 (100 %), 🟠 Pièce de cuivre 1–3 (40 %) | 0 |
| Araignée géante | `spider` | 3 | 150 | 14 | spore | génération | 🕸️ Soie d'araignée 1–3 (100 %) | 0 |
| Feu follet | `wisp` | 3 | 70 | 14 | spore | génération | ✨ Poussière de feu follet 1–2 (100 %) | 0 |
| Loup noir | `black_wolf` | 4 | 140 | 18 | charge, meute 3 | forêt rousse (jour), toundra (jour) | 🐺 Peau de loup 1–1 (80 %), 🥩 Viande crue 1–2 (90 %), 🦷 Dent 1–2 (50 %) | 0 |
| Araignée des cavernes | `cave_spider` | 4 | 160 | 16 | spore | grottes forêt rousse, grottes prairie | 🕸️ Soie d'araignée 2–3 (100 %), ✨ Pierre lumineuse 1–1 (8 %) | 0 |
| Croco | `croc` | 4 | 220 | 22 | charge, neutre | génération | 🟫 Cuir 2–3 (100 %), 🥩 Viande crue 1–2 (80 %) | 0 |
| Araignée du désert | `desert_spider` | 4 | 150 | 16 | spore | désert (jour), grottes désert | 🕸️ Soie d'araignée 1–2 (90 %) | 0 |
| Esprit noyé | `drowned_spirit` | 4 | 120 | 18 | charge, nuit, lumière | marais (nuit), grottes marais | ✨ Poussière de feu follet 1–2 (80 %), ⚪ Perle 1–1 (5 %) | 0 |
| Serpent des dunes | `dune_snake` | 4 | 110 | 20 | charge | désert (jour) | 🐉 Écailles 2–3 (90 %), 🧂 Sel 1–2 (30 %) | 0 |
| Goule | `ghoul` | 4 | 150 | 20 | charge, nuit | forêt rousse (nuit), marais (nuit), désert (nuit), prairie (nuit) | 🧟 Chair pourrie 2–3 (100 %), 🦴 Os 1–2 (60 %), 🐾 Griffe de créature 1–1 (30 %) | 0 |
| Gobelin | `goblin` | 4 | 180 | 20 | charge | génération | ⛰️ Minerai de fer 1–1 (30 %), 🟠 Minerai de cuivre 1–2 (40 %) | 2 |
| Gobelin archer | `goblin_archer` | 4 | 120 | 14 | spore | forêt rousse (jour) | 🐦 Plume 1–2 (60 %), 🟠 Minerai de cuivre 1–2 (40 %) | 2 |
| Homme-boue | `mud_man` | 4 | 220 | 20 | hop | marais (jour), grottes marais | 🟤 Argile 2–4 (100 %), 🟫 Terre 2–3 (100 %), 💰 Pièce ancienne 1–1 (5 %) | 0 |
| Revenant | `revenant` | 4 | 130 | 20 | charge, nuit, lumière | forêt rousse (nuit), toundra (nuit), prairie (nuit) | ✨ Poussière de feu follet 1–2 (80 %), ❔ Objet perdu 1–1 (20 %) | 0 |
| Pilleur de ruines | `ruin_looter` | 4 | 140 | 20 | charge | désert (jour) | 💰 Pièce ancienne 1–2 (40 %), 🧩 Fragment de relique 1–1 (30 %), 🗝️ Clé rouillée 1–1 (30 %) | 2 |
| Scorpion | `scorpion` | 4 | 160 | 18 | charge | génération | 🦂 Dard de scorpion 1–1 (80 %), 🥩 Viande crue 1–1 (30 %) | 0 |
| Sanglier des marécages | `swamp_boar` | 4 | 180 | 20 | charge, neutre | marais (jour) | 🥩 Viande de sanglier 2–3 (100 %), 🟫 Cuir 1–2 (80 %) | 0 |
| Serpent des eaux | `water_snake` | 4 | 120 | 18 | charge | marais (jour) | 🐉 Écailles 2–3 (90 %), ⚪ Perle 1–1 (5 %) | 0 |
| Loup blanc | `wolf_white` | 4 | 130 | 16 | charge, meute 3 | génération | 🦊 Fourrure 1–2 (90 %), 🥩 Viande crue 1–2 (90 %) | 0 |
| Ours | `bear` | 5 | 320 | 28 | charge, neutre | génération | 🦊 Fourrure 2–3 (100 %), 🥩 Viande crue 3–4 (100 %), 🍯 Miel 1–2 (50 %) | 0 |
| Scarabée cuirassé | `beetle` | 5 | 260 | 18 | charge | désert (jour), grottes désert | 🐉 Écailles 1–2 (60 %), 💠 Pierre colorée 1–1 (30 %) | 0 |
| Sorcier des ronces | `bramble_witch` | 5 | 160 | 20 | spore | forêt rousse (jour) | 🌿 Ortie 2–4 (100 %), 🧪 Fiole d'extrait 1–1 (30 %), 🌱 Mandragore 1–1 (8 %) | 3 |
| Soldat déserteur | `deserter` | 5 | 220 | 22 | charge | prairie (jour) | ⭕ Anneau métallique 2–5 (60 %), 🎒 Rations 1–1 (40 %), 🛡️ Insigne de garde 1–1 (10 %) | 3 |
| Spectre des dunes | `dune_spectre` | 5 | 140 | 20 | spore, nuit, lumière | désert (nuit) | 💰 Pièce ancienne 1–2 (50 %), ✨ Poussière de feu follet 1–2 (60 %) | 0 |
| Sanglier givré | `frost_boar` | 5 | 220 | 22 | charge, neutre | toundra (jour) | 🥩 Viande de sanglier 2–3 (100 %), 🧊 Cristal de glace 1–1 (40 %) | 0 |
| Araignée de givre | `frost_spider` | 5 | 170 | 18 | spore | toundra (jour), grottes toundra | 🕸️ Soie d'araignée 1–3 (100 %), 🧊 Cristal de glace 1–1 (30 %) | 0 |
| Hyène monstrueuse | `hyena` | 5 | 200 | 22 | charge, meute 2 | désert (jour) | 🟫 Peau brute 1–2 (80 %), 🦷 Dent de monstre 1–1 (30 %) | 0 |
| Cerf spectral | `spectral_stag` | 5 | 160 | 18 | charge, nuit | forêt rousse (nuit) | 🦌 Bois de cerf 1–1 (80 %), ✨ Poussière de feu follet 1–2 (80 %), 🐦 Plume nocturne 1–1 (20 %) | 0 |
| Spectre du blizzard | `blizzard_spectre` | 6 | 160 | 22 | charge, nuit | toundra (nuit) | 🧊 Cristal de glace 1–2 (80 %), ✨ Poussière de feu follet 1–1 (50 %) | 0 |
| Roi des Slimes | `boss_slime` | 6 | 700 | 30 | hop, BOSS | génération | 🟢 Gelée de slime 5–8 (100 %) | 0 |
| Gargouille animée | `gargoyle` | 6 | 260 | 24 | charge, vole | génération | ⛰️ Pierre 3–5 (100 %), ⛰️ Pierre gravée 1–1 (10 %) | 3 |
| Fantôme de chevalier | `ghost_knight` | 6 | 320 | 30 | charge, élite, nuit | prairie (nuit) | ✨ Poussière de feu follet 2–3 (100 %), 💍 Bijou ancien 1–1 (10 %), 🗝️ Clé rouillée 1–1 (30 %) | 4 |
| Golem de glace | `ice_golem` | 6 | 360 | 24 | spore | grottes toundra | 🧊 Cristal de glace 1–3 (100 %), ⛰️ Minerai de fer 1–2 (50 %) | 0 |
| Ours blanc | `polar_bear` | 6 | 420 | 30 | charge, neutre | toundra (jour) | 🦊 Fourrure 3–4 (100 %), 🧈 Graisse 2–3 (100 %), 🥩 Viande crue 3–4 (100 %) | 0 |
| Sorcière des marais | `swamp_witch` | 6 | 200 | 24 | spore, nuit | marais (nuit) | 🧪 Fiole d'extrait 1–2 (60 %), 🌙 Fleur nocturne 1–1 (30 %), 🧪 Fiole vide 1–2 (60 %) | 4 |
| Golem de bois | `wood_golem` | 6 | 380 | 26 | charge, neutre | forêt rousse (jour) | 🌲 Rondin de chêne 3–5 (100 %), 🌲 Bois pétrifié 1–1 (15 %) | 2 |
| Chef de bande | `bandit_chief` | 7 | 520 | 32 | charge, élite | génération | 👝 Bourse de marchand 1–1 (100 %), 🗺️ Carte au trésor 1–1 (30 %), 🔩 Acier 1–2 (50 %) | 6 |
| Ours des cavernes | `cave_bear` | 7 | 480 | 34 | charge, élite, neutre | toundra (rare), grottes forêt rousse, grottes toundra | 🦊 Fourrure 3–4 (100 %), 🐾 Griffe de créature 1–2 (80 %), 🦴 Os fossilisé 1–1 (10 %) | 3 |
| Gardien des Moissons | `harvest_warden` | 7 | 1400 | 38 | charge, BOSS | génération | 🌰 Graine ancienne 2–4 (100 %), 🎐 Toile enchantée 1–2 (100 %), 🌱 Graines (Citrouille) 3–6 (100 %) | 6 |
| Troll des racines | `root_troll` | 7 | 600 | 36 | charge, élite, neutre | forêt rousse (jour) | 🌳 Racine ancienne 1–1 (50 %), 🌲 Rondin de chêne 2–4 (100 %), 🟧 Résine 2–3 (100 %) | 4 |
| Golem de grès | `sandstone_golem` | 7 | 480 | 30 | charge, élite | désert (jour) | 🏜️ Sable 4–8 (100 %), 🔴 Rubis 1–1 (5 %), ⛰️ Pierre gravée 1–1 (15 %) | 4 |
| Yéti | `yeti` | 7 | 480 | 34 | charge, élite | génération | 🦊 Fourrure 3–5 (100 %), 🧊 Cristal de glace 1–2 (80 %) | 4 |
| Myconide Ancien | `boss_myconid` | 8 | 900 | 40 | spore, BOSS | génération |  | 0 |
| Troll des glaces | `frost_troll` | 8 | 650 | 38 | charge, élite | toundra (jour) | 🧊 Cristal de glace 2–3 (100 %), 🦊 Fourrure 2–3 (100 %), 💎 Cristal ancien 1–1 (10 %) | 5 |
| Roi Mycélien | `mycelian_king` | 8 | 1800 | 42 | spore, BOSS | génération | 🍄 Spore royale 1–2 (100 %), 🍄 Champignon 6–10 (100 %) | 7 |
| Ogre | `ogre` | 8 | 800 | 40 | charge, élite, neutre | forêt rousse (rare), marais (rare), prairie (rare) | 🥩 Viande crue 4–6 (100 %), 👝 Bourse de marchand 1–1 (40 %), 📯 Corne de bête rare 1–1 (5 %) | 6 |
| Colosse de pierre | `stone_golem` | 8 | 700 | 36 | charge, élite | grottes désert, grottes prairie | ⛰️ Pierre 6–10 (100 %), ⛰️ Pierre gravée 1–1 (30 %), 💗 Cœur minéral 1–1 (3 %) | 5 |
| Mère des Ronces | `bramble_mother` | 9 | 2200 | 46 | spore, BOSS | errant forêt rousse | 🌰 Graine ancienne 2–3 (100 %), 🌳 Racine ancienne 1–2 (100 %) | 8 |
| Colosse de Verre | `glass_colossus` | 9 | 2400 | 50 | charge, BOSS | génération | 💎 Éclat de verre vivant 2–4 (100 %), 🟡 Minerai d'or 4–8 (100 %) | 8 |
| Roi des marais | `marsh_king` | 9 | 2200 | 46 | hop, BOSS | gardien de donjon marais, errant marais | 🖤 Écaille noire (Roi des marais) 1–2 (100 %), ⚪ Perle 1–3 (100 %) | 8 |
| Minotaure | `minotaur` | 9 | 900 | 44 | charge, élite | désert (rare) | 📯 Corne 2–2 (100 %), 📯 Corne de bête rare 1–1 (20 %), 🔩 Acier 1–3 (60 %) | 7 |
| Vargor, le Roi des loups | `vargor` | 9 | 2000 | 48 | charge, BOSS | gardien de donjon forêt rousse, errant forêt rousse | 🐺 Fourrure royale (Vargor) 1–1 (100 %), 🐺 Peau de loup 3–5 (100 %) | 8 |
| Chef Gobelin | `boss_goblin` | 10 | 1200 | 50 | charge, BOSS | génération |  | 0 |
| Brumeglace | `brumeglace` | 10 | 2600 | 52 | spore, BOSS | gardien de donjon toundra, errant toundra | ❄️ Cristal de givre (Brumeglace) 1–1 (100 %), 🧊 Cristal de glace 4–6 (100 %) | 9 |
| Le Roi sans couronne | `crownless_king` | 10 | 2800 | 54 | charge, BOSS | gardien de donjon prairie, errant prairie | 👑 Couronne oubliée 1–1 (100 %), 👑 Sceau royal 1–1 (30 %), 💍 Bijou ancien 1–2 (100 %) | 10 |
| Dormeur des Glaces | `ice_sleeper` | 10 | 3000 | 55 | spore, BOSS | génération | ❄️ Cœur gelé 1–1 (100 %), 🧊 Cristal de glace 4–8 (100 %) | 10 |
| Scarabée royal | `royal_scarab` | 10 | 2400 | 48 | charge, BOSS | gardien de donjon désert, errant désert | 🐞 Carapace dorée (Scarabée royal) 1–1 (100 %), 🟡 Minerai d'or 3–6 (100 %) | 9 |

## Compétences : ce qui donne de l'XP

Lu dans le code (`addSkillXp` / `addSkillXpCapped`). Les gestes réversibles sont plafonnés par jour (étape 6A).

### 🌾 Agriculture — Cultures plus difficiles, récoltes doubles (6 sources)

- `Farm:459` — `G.Joueurs.addSkillXp(player, "agriculture", 3 + (Config.CROPS[st.crop].days or 3))`
- `Props:362` — `G.Joueurs.addSkillXp(player, "agriculture", 3)`
- `Props:635` — `G.Joueurs.addSkillXp(player, "agriculture", 2)`
- `Props:736` — `G.Joueurs.addSkillXp(player, "agriculture", 2 + math.floor((p.skill or 0) / 4))`
- `Props:764` — `G.Joueurs.addSkillXp(player, "agriculture", 2)`
- `Terraforme:138` — `G.Joueurs.addSkillXpCapped(player, "agriculture", 1, "terrasse", XP_PER_DAY)`

### 🪓 Bûcheronnage — Bois en plus, arbres abattus plus vite (1 source)

- `Props:532` — `G.Joueurs.addSkillXp(player, "bucheronnage", 6)`

### ⛏️ Minage — Fer au niv. 12, or au niv. 25, minerai en plus (3 sources)

- `Donjons:465` — `G.Joueurs.addSkillXp(player, "minage", 8)`
- `Evenements:337` — `G.Joueurs.addSkillXp(player, "minage", 4)`
- `Props:745` — `G.Joueurs.addSkillXp(player, "minage", 4 + math.floor((k.skill or 0) / 2))`

### 🎣 Pêche — Poissons rares, touches plus fréquentes (2 sources)

- `Fishing:69` — `G.Joueurs.addSkillXp(player, "peche", 5 + math.floor(Config.FISH[i].price / 10))`
- `Nasses:166` — `G.Joueurs.addSkillXp(player, "peche", 3 * d.n)`

### 🍳 Cuisine — Plats élaborés, plats qui nourrissent plus (0 source)

- pas d'appel direct : l'XP vient de la fabrication (`Shop`, compétence de la recette), voir plus bas

### ⚒️ Artisanat — Outils de fer, serrures, équipement (5 sources)

- `Batir:164` — `G.Joueurs.addSkillXpCapped(player, "artisanat", 1, "pose", 150)`
- `Demolir:318` — `G.Joueurs.addSkillXp(player, "artisanat", 4)`
- `Shop:417` — `G.Joueurs.addSkillXp(player, "artisanat", 10 + (r.skill and r.skill[2] or 0))`
- `Shop:423` — `G.Joueurs.addSkillXp(player, "artisanat", 8)`
- `Shop:519` — `G.Joueurs.addSkillXp(player, "artisanat", 3)`

### ⚔️ Combat — +1 % de dégâts par niveau (1 source)

- `Enemies:636` — `G.Joueurs.addSkillXp(player, "combat", 4 * k.level)`

### 🎣 Crochetage — Serrures plus dures, crochets qui cassent moins (2 sources)

- `Protection:198` — `G.Joueurs.addSkillXp(player, "crochetage", (practice and 3 or 9) * tier)`
- `Protection:201` — `G.Joueurs.addSkillXp(player, "crochetage", (practice and 1 or 2) * tier)`

### 🐾 Dressage — Bêtes plus sauvages, mini-jeu plus facile (4 sources)

- `Compagnons:196` — `G.Joueurs.addSkillXp(player, "dressage", 12 * t.diff)`
- `Compagnons:199` — `G.Joueurs.addSkillXp(player, "dressage", 3 * t.diff)`
- `Horses:251` — `G.Joueurs.addSkillXp(player, "dressage", 3 * diff)`
- `Horses:255` — `G.Joueurs.addSkillXp(player, "dressage", 12 * diff)`

### 🐄 Élevage — Produits des bêtes plus souvent (6 sources)

- `Animals:174` — `G.Joueurs.addSkillXp(player, "elevage", 5)`
- `Compagnons:253` — `G.Joueurs.addSkillXp(player, "elevage", 6)`
- `Compagnons:335` — `G.Joueurs.addSkillXp(owner, "elevage", 15)`
- `Joueurs:646` — `J.addSkillXp(player, "elevage", 2)`
- `Machines:85` — `G.Joueurs.addSkillXp(player, "elevage", 4)`
- `Nids:143` — `G.Joueurs.addSkillXp(player, "elevage", 2)`

### 💰 Commerce — Ventes et commandes mieux payées (+0,5 % / +1 % par niveau) (7 sources)

- `Economie:216` — `G.Joueurs.addSkillXpCapped(p, "commerce", 6, "echange", 5)`
- `Economie:315` — `G.Joueurs.addSkillXp(player, "commerce", 12 + o.n)`
- `Economie:593` — `G.Joueurs.addSkillXp(owner, "commerce", 2 + math.floor(cost / 30))`
- `Joueurs:601` — `J.addSkillXp(player, "commerce", 1)`
- `Politique:225` — `G.Joueurs.addSkillXp(player, "commerce", 1)`
- `Poste:418` — `G.Joueurs.addSkillXp(player, "commerce", 2)`
- `Shop:257` — `G.Joueurs.addSkillXp(player, "commerce", 1 + math.floor(total / 25))`

### Compétence choisie à l'exécution

- `Joueurs:329` — `J.addSkillXp(player, skill, amount)`
- `Moissons:146` — `G.Joueurs.addSkillXp(player, src.skill, 1)`
- `Shop:451` — `G.Joueurs.addSkillXp(player, skillName, 3 + math.floor((r.skill and r.skill[2] or 0) / 3))`

## Or : entrées et sorties

Lu dans le code : `add(…, "gold", …)` crée de l'or, `take(…, "gold", …)` en détruit (ou le déplace vers un autre joueur).
Le journal serveur (`Economie`) mesure les flux réels par monde.

### Entrées d'or (15)

- `Economie:311` — `G.Joueurs.add(player, "gold", reward, true)`
- `Economie:551` — `G.Joueurs.add(player, "gold", n, true)`
- `Enemies:615` — `G.Joueurs.add(player, "gold", math.random(5, 15) * k.level * (k.gold or 1))`
- `Evenements:361` — `G.Joueurs.add(player, "gold", 40, true)`
- `Evenements:402` — `G.Joueurs.add(p, "gold", 120, true)`
- `Game:355` — `G.Joueurs.add(hunter, "gold", bounty, true)`
- `Ilots:160` — `G.Joueurs.add(player, "gold", math.random(30, 80))`
- `Joueurs:664` — `J.add(player, "gold", n)`
- `Journal:172` — `G.Joueurs.add(player, "gold", math.random(80, 200))`
- `Mondes:782` — `G.Joueurs.add(p, "gold", t.cost, true)`
- `Poste:248` — `G.Joueurs.add(player, "gold", p.gold, true)`
- `Poste:359` — `G.Joueurs.add(player, "gold", POSTAGE, true)`
- `Quetes:458` — `G.Joueurs.add(player, "gold", q.gold)`
- `Shop:255` — `G.Joueurs.add(player, "gold", total, true)`
- `Shop:762` — `G.Joueurs.add(player, "gold", d.stall.till, true)`

### Sorties d'or (20)

- `Activites:165` — `if prize > 0 and not G.Joueurs.take(player, "gold", prize) then`
- `Armee:139` — `if G.Joueurs.take(player, "gold", total) then`
- `Avatar:258` — `if paidBefore and not G.Joueurs.take(player, "gold", LOOK_COST) then`
- `Clans:251` — `G.Joueurs.take(player, "gold", FOUND_COST)`
- `Economie:425` — `if item ~= "gold" and not G.Joueurs.take(player, "gold", 2) then`
- `Economie:456` — `if not G.Joueurs.take(player, "gold", cost) then`
- `Economie:569` — `if not G.Joueurs.take(player, "gold", cost) then`
- `Game:396` — `G.Joueurs.take(player, "gold", lost)`
- `Game:422` — `G.Joueurs.take(player, "gold", fine)`
- `Horses:212` — `if not G.Joueurs.take(player, "gold", price) then`
- `Horses:384` — `if not G.Joueurs.take(player, "gold", Horses.STABLE_FEE) then`
- `Joueurs:89` — `J.take(player, "gold", cost)`
- `Mondes:863` — `if not travelling[p] and G.Joueurs.take(p, "gold", cost) then`
- `Parcelles:141` — `G.Joueurs.take(player, "gold", price)`
- `Politique:218` — `if not G.Joueurs.take(player, "gold", n) then`
- `Poste:347` — `G.Joueurs.take(player, "gold", POSTAGE)`
- `Poste:389` — `G.Joueurs.take(player, "gold", fee)`
- `Poste:409` — `if not G.Joueurs.take(player, "gold", l.price) then`
- `Shop:71` — `if not G.Joueurs.take(player, "gold", rent) then`
- `Shop:215` — `if not G.Joueurs.take(player, "gold", entry.price * n) then`

