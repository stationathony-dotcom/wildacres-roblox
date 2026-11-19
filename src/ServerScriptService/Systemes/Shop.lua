-- Économie et maison : boutique du marchand, bêtes du fermier, receleur (filou), prix selon le
-- caractère, le charisme, l'honneur et l'offre (plus on vend d'un produit dans la journée, moins
-- il rapporte) ; atelier (fabrication façon Minecraft, établi pour les recettes avancées) ;
-- objets posés (clôture, feu de camp, établi…) ; lit de la maison de départ.

local Shop = {}
local G, Config, D
local open = {} -- joueur -> PNJ
local soldToday = {} -- "region:item" -> quantité vendue aujourd'hui

local INN_RENT = 10 -- nuit à l'auberge du village (l'or sort de l'économie)

function Shop.init(g)
	G = g
	Config = G.Config
	D = G.Dialogue
	G.Interact.onAction("buy", function(player, data)
		Shop.buy(player, data.item, tonumber(data.n) or 1)
	end)
	G.Interact.onAction("sell", function(player, data)
		Shop.sell(player, data.item, tonumber(data.n) or 1)
	end)
	G.Interact.onAction("craft_grid", function(player, data)
		Shop.craftGrid(player, data.slots, tonumber(data.pick))
	end)
	G.Interact.onPrompt("forge_reparer", function(player)
		Shop.repairAll(player)
	end)
	G.Interact.onAction("repair", function(player, data)
		if type(data) == "table" and type(data.id) == "string" then
			Shop.repair(player, data.id)
		end
	end)
	G.Interact.onAction("craftmenu", function(player)
		Shop.openCraft(player)
	end)
	G.Interact.onAction("chest_put", function(player, data)
		Shop.chestMove(player, data.id, data.item, tonumber(data.n) or 1, true)
	end)
	G.Interact.onAction("chest_take", function(player, data)
		Shop.chestMove(player, data.id, data.item, tonumber(data.n) or 1, false)
	end)
	G.Interact.onAction("chest_bulk", function(player, data)
		Shop.chestBulk(player, data.id, data.mode)
	end)
	G.Interact.onPrompt("chest", function(player, prompt)
		Shop.openChest(player, prompt:GetAttribute("Placed"))
	end)
	G.Interact.onPrompt("furnace", function(player)
		Shop.openCraft(player, "cuisine")
	end)
	G.Interact.onAction("place", function(player, data)
		Shop.place(player, data.item)
	end)
	G.Interact.onAction("closeshop", function(player)
		open[player] = nil
	end)
	G.Interact.onPrompt("bed", function(player, prompt)
		local p = prompt.Parent
		local pos = (p:IsA("Attachment") and p.WorldPosition or p.Position) + Vector3.new(0, 2, 0)
		-- lit d'un autre joueur : on le loue pour la nuit (l'auberge du propriétaire)
		local d = G.Protection.findPlaced(prompt:GetAttribute("Placed"))
		local inn = prompt:GetAttribute("Inn") == true -- lit de l'auberge du village
		if inn or (d and d.owner and not G.Util.owns(player, d.owner)) then
			-- on vérifie qu'on PEUT dormir avant de faire payer
			local ok, why = G.Game.canSleep(player)
			if not ok then
				if why then
					G.Util.toast(player, why)
				end
				return
			end
			local rent = inn and INN_RENT or (d.rent or 15)
			if not G.Joueurs.take(player, "gold", rent) then
				G.Util.toast(player, "Une nuit ici coûte " .. rent .. " 💰.")
				return
			end
			if not inn then
				local ownerId = tonumber(string.sub(d.owner, 2))
				if ownerId then
					G.Poste.deliverSystem(ownerId, { from = "Auberge (" .. player.DisplayName .. ")", gold = rent })
				end
			end
			G.Util.toast(player, "🛏️ Chambre louée : " .. rent .. " 💰. Tu te réveilleras ici.", "gain")
			G.Joueurs.sync(player)
		end
		G.Game.sleep(player, pos)
	end)
	G.Interact.onPrompt("bench", function(player)
		Shop.openCraft(player)
	end)
	G.Interact.onPrompt("pickup", function(player, prompt)
		Shop.pickup(player, prompt:GetAttribute("Placed"))
	end)
end

-- ----------------------------------------------------------------- Prix

local function demandFactor(regKey: string, item: string): number
	local n = soldToday[regKey .. ":" .. item] or 0
	return math.max(0.5, 0.94 ^ n)
end

-- Commerce entre régions (19/11, « à ne pas oublier » § 10) : chaque village RECHERCHE quelques
-- produits qui ne poussent pas chez lui (cultures et plantes d'autres biomes) et les paie
-- WANTED_MULT fois plus cher. La liste change tous les WANTED_DAYS jours (même pour tout le monde) :
-- de quoi donner envie de voyager avec une charrette pleine. Pas d'arbitrage possible : ce sont des
-- objets qu'aucun PNJ ne vend ici (et le plafond des objets vendus ailleurs reste appliqué).
Shop.WANTED_MULT = 1.5
Shop.WANTED_DAYS = 3
Shop.WANTED_N = 3
local wantedCache = {}
function Shop.wanted(villageKey: string, biome: string)
	local period = math.floor((G.world.day or 1) / Shop.WANTED_DAYS)
	local ck = villageKey .. "|" .. period
	if wantedCache[ck] then
		return wantedCache[ck]
	end
	local here = {}
	for _, id in (Config.BIOME_CROPS[biome] or {}) do
		here[id] = true
	end
	local H = G.Herbes and rawget(G.Herbes, "POOLS")
	for _, h in (H and H[biome]) or {} do
		here[h[1]] = true
	end
	local pool, seen = {}, {}
	for b, crops in Config.BIOME_CROPS do
		if b ~= biome then
			for _, id in crops do
				if not here[id] and not seen[id] and Config.ITEMS[id] then
					seen[id] = true
					table.insert(pool, id)
				end
			end
		end
	end
	for b, herbs in (H or {}) do
		if b ~= biome then
			for _, h in herbs do
				if not here[h[1]] and not seen[h[1]] and Config.ITEMS[h[1]] then
					seen[h[1]] = true
					table.insert(pool, h[1])
				end
			end
		end
	end
	table.sort(pool)
	local rng = Random.new(G.WG.hash(G.world.seed or 0, "demande", villageKey, period))
	local list = {}
	for _ = 1, math.min(Shop.WANTED_N, #pool) do
		table.insert(list, table.remove(pool, rng:NextInteger(1, #pool)))
	end
	local set = {}
	for _, id in list do
		set[id] = true
	end
	wantedCache[ck] = { list = list, set = set }
	return wantedCache[ck]
end

-- PÉNURIES (19/11, « à ne pas oublier » § 4 événements économiques) : par période de SHORTAGE_DAYS
-- jours, un village sur deux environ manque d'une denrée de base et la paie SHORTAGE_MULT fois plus.
-- Aucune annonce : on l'apprend au comptoir (ou par les joueurs). Seulement des objets qu'aucun PNJ ne
-- vend (sinon acheter ailleurs et revendre ici serait une pompe à or).
Shop.SHORTAGE_MULT = 1.8
Shop.SHORTAGE_DAYS = 2
Shop.SHORTAGE_CHANCE = 0.5
Shop.SHORTAGE_POOL = { "wheat", "flour", "planks", "wood", "stone", "iron_ingot", "copper_ingot", "rope", "cloth", "wool", "milk", "egg",
	"grilled_fish", "raw_fish", "meat", "apple", "carrot", "potato", "salt", "leather", "coal", "honey", "herbs", "bread" }
local shortageCache = {}
function Shop.shortage(villageKey: string): string?
	local period = math.floor((G.world.day or 1) / Shop.SHORTAGE_DAYS)
	local ck = villageKey .. "|" .. period
	if shortageCache[ck] ~= nil then
		return shortageCache[ck] or nil
	end
	local rng = Random.new(G.WG.hash(G.world.seed or 0, "penurie", villageKey, period))
	local pick = false
	if rng:NextNumber() < Shop.SHORTAGE_CHANCE then
		local sold = Shop.npcSold()
		local pool = {}
		for _, id in Shop.SHORTAGE_POOL do
			if Config.ITEMS[id] and not sold[id] then
				table.insert(pool, id)
			end
		end
		if #pool > 0 then
			pick = pool[rng:NextInteger(1, #pool)]
		end
	end
	shortageCache[ck] = pick
	return pick or nil
end

local function shortageAt(e): string?
	local R = G.Reputation and rawget(G.Reputation, "villageAt")
	local v = R and e.root and R(e.root.Position)
	return v and Shop.shortage(v.key) or nil
end
Shop.shortageAt = shortageAt

-- ce que le village de ce comptoir recherche (nil si le comptoir n'est pas dans un village)
local function wantedAt(e)
	local R = G.Reputation and rawget(G.Reputation, "villageAt")
	local v = R and e.root and R(e.root.Position)
	if not v then
		return nil
	end
	return Shop.wanted(v.key, v.biome or (G.Clock.biomeAt(e.root.Position) or "prairie"))
end
Shop.wantedAt = wantedAt

function Shop.sellPrice(player: Player, e, item: string): number
	local info = Config.ITEMS[item]
	if not info or not info.price or info.price <= 0 or info.tool then
		return 0
	end
	local charisme = G.Joueurs.stats(player).charisme or 0
	local greed = D.persona(e.data.persona).greed
	local mult = (1 + charisme * 0.02) / greed
	-- balance et poids de mesure dans le sac : on ne se fait pas rouler, +5 % chacun (19/11)
	if G.Joueurs.has(player, "scales_tool") then
		mult *= 1.05
	end
	if G.Joueurs.has(player, "weights") then
		mult *= 1.05
	end
	if e.data.persona == "filou" and e.data.role ~= "merchant" then
		mult *= 0.6 * (1 + 0.3 * G.Joueurs.talent(player, "receleur"))
	end
	mult *= (1 + 0.1 * G.Joueurs.talent(player, "negociant")) * (1 + 0.2 * G.Joueurs.talent(player, "marchand_ne")) * (1 + 0.005 * G.Joueurs.skill(player, "commerce"))
	mult *= G.Evenements.priceBonus(e.reg.key) -- foire au village
	local repMult = G.Reputation and rawget(G.Reputation, "priceMult")
	if repMult and e.root then
		local _, sellM = repMult(player, e.root.Position)
		mult *= sellM -- réputation du village (Systemes/Reputation)
	end
	local price = math.floor(info.price * mult * demandFactor(e.reg.key, item))
	-- invariant anti-arbitrage : un marchand ne rachète jamais plus de 80 % de ce qu'il te vendrait
	-- le même objet (sinon acheter puis revendre au même comptoir créait de l'or à l'infini)
	price = math.min(price, math.floor(Shop.buyPrice(player, e, info.price) * 0.8))
	-- un artisan paie mieux SES matières (boulanger : le grain…), par-dessus le plafond du comptoir
	if e.data.metier then
		price = math.floor(price * G.Metiers.bonus(e, item))
	end
	-- produit d'une autre région recherché par ce village : payé bien plus cher
	local w = wantedAt(e)
	if w and w.set[item] then
		price = math.floor(math.max(price, info.price * 0.8) * Shop.WANTED_MULT)
	end
	-- pénurie dans ce village : la denrée qui manque est payée bien plus cher
	if shortageAt(e) == item then
		price = math.floor(math.max(price, info.price * 0.8) * Shop.SHORTAGE_MULT)
	end
	-- objet qu'un PNJ VEND quelque part : jamais plus de 80 % du prix le plus bas auquel on peut
	-- l'acheter (sinon : acheter chez un PNJ peu gourmand, revendre chez un radin ou un artisan)
	local sm = Shop.npcSold()[item]
	if sm then
		price = math.min(price, math.floor(Shop.buyPrice(player, e, info.price, true) * sm * 0.8))
	end
	return math.max(1, price)
end

-- objets vendus par au moins un PNJ -> multiplicateur de son prix le plus bas (1 ; 1,4 chez le
-- seul colporteur). Construit au premier appel (Metiers est initialisé après Shop).
local npcSoldCache = nil
function Shop.npcSold()
	if npcSoldCache then
		return npcSoldCache
	end
	local t = {}
	for _, item in Config.SHOP do
		t[item] = 1
	end
	for id in Config.CROPS do
		if Config.ITEMS["seed_" .. id] then
			t["seed_" .. id] = 1 -- graines du fermier
		end
	end
	if G.Metiers and G.Metiers.soldItems then
		for item, m in G.Metiers.soldItems() do
			t[item] = math.min(t[item] or math.huge, m)
		end
	end
	npcSoldCache = t
	return t
end

local minGreed = nil
function Shop.minGreed(): number
	if not minGreed then
		minGreed = math.huge
		for _, t in D.TRAITS do
			minGreed = math.min(minGreed, t.greed or 1)
		end
	end
	return minGreed
end

-- `floor` : le prix le plus bas possible pour ce joueur (PNJ le moins gourmand, avis au maximum)
function Shop.buyPrice(player: Player, e, base: number, floor: boolean?): number
	local prof = G.Joueurs.get(player)
	local charisme = G.Joueurs.stats(player).charisme or 0
	local greed = floor and Shop.minGreed() or D.persona(e.data.persona).greed
	local honorMult = prof.honor < 0 and (1 + (-prof.honor) / 200) or (1 - prof.honor / 1000)
	local op = floor and 50 or math.clamp(G.Npcs.op(e, player), -50, 50)
	local opinionMult = 1 - op / 500
	-- réputation du village : `floor` prend la meilleure possible (garde-fou anti-arbitrage)
	local R = G.Reputation and rawget(G.Reputation, "priceMult")
	local repMult = 1
	if floor then
		repMult = G.Reputation and rawget(G.Reputation, "BEST_BUY") or 1
	elseif R and e and e.root then
		repMult = (R(player, e.root.Position))
	end
	return math.max(1, math.floor(base * greed * honorMult * opinionMult * repMult * (1 - math.min(0.3, charisme * 0.02))))
end

local function catalog(player: Player, e)
	local buy = {}
	local wants = nil -- nil = rachète tout ; sinon seulement ces objets (gens de métier)
	local role = e.data.role
	local biome = e.root and G.Clock.biomeAt(e.root.Position) or "prairie"
	if e.data.metier then
		buy, wants = G.Metiers.catalog(player, e)
	elseif role == "merchant" then
		for _, item in Config.SHOP do
			local info = Config.ITEMS[item]
			local crop = info.seed and Config.CROPS[info.seed]
			if not crop or table.find(crop.biomes, biome) then
				table.insert(buy, { item = item, price = Shop.buyPrice(player, e, info.price), name = info.name, icon = info.icon })
			end
		end
	elseif role == "farmer" then
		for _, kind in { "chicken", "sheep", "cow" } do
			local a = Config.ANIMALS[kind]
			table.insert(buy, { item = "animal:" .. kind, price = Shop.buyPrice(player, e, a.price), name = a.name, icon = kind == "chicken" and "🐔" or (kind == "cow" and "🐄" or "🐑") })
		end
		for id, crop in Config.CROPS do
			if table.find(crop.biomes, biome) then
				local info = Config.ITEMS["seed_" .. id]
				table.insert(buy, { item = "seed_" .. id, price = Shop.buyPrice(player, e, info.price), name = info.name, icon = info.icon })
			end
		end
	end
	local prof = G.Joueurs.get(player)
	local sell = {}
	for item, n in prof.inv do
		if item ~= "gold" and n > 0 and (not wants or wants[item]) then
			local price = Shop.sellPrice(player, e, item)
			if price > 0 then
				local info = Config.ITEMS[item]
				table.insert(sell, { item = item, price = price, n = n, name = info.name, icon = info.icon })
			end
		end
	end
	table.sort(sell, function(a, b)
		return a.name < b.name
	end)
	return buy, sell
end

local function refresh(player: Player)
	local e = open[player]
	if not e then
		return
	end
	local buy, sell = catalog(player, e)
	local title = e.data.role == "merchant" and ("Boutique de " .. e.data.name) or (e.data.role == "farmer" and ("Ferme de " .. e.data.name) or (e.data.name .. " (receleur)"))
	local greeting = nil
	if e.data.metier then
		title = G.Metiers.shopTitle(e)
		greeting = G.Metiers.greeting(e, buy) -- étal vide : il dit ce qui lui manque
	end
	local short = shortageAt(e)
	if short and Config.ITEMS[short] then
		local info = Config.ITEMS[short]
		local extra = "On manque de " .. info.icon .. " " .. info.name .. " en ce moment : payé +" .. math.floor((Shop.SHORTAGE_MULT - 1) * 100) .. " %."
		greeting = (greeting and (greeting .. " ") or (D.line(e.data.persona, "trade", { titre = D.title_for(G.Joueurs.get(player).honor) }) .. " ")) .. extra
	end
	local w = wantedAt(e)
	if w and #w.list > 0 and not e.data.metier then
		local names = {}
		for _, id in w.list do
			local info = Config.ITEMS[id]
			table.insert(names, info.icon .. " " .. info.name)
		end
		local extra = "On cherche ici : " .. table.concat(names, ", ") .. " (payés +" .. math.floor((Shop.WANTED_MULT - 1) * 100) .. " %)."
		greeting = (greeting and (greeting .. " ") or (D.line(e.data.persona, "trade", { titre = D.title_for(G.Joueurs.get(player).honor) }) .. " ")) .. extra
	end
	G.remotes.Menu:FireClient(player, { kind = "shop", title = title, buy = buy, sell = sell, gold = G.Joueurs.count(player, "gold"),
		greeting = greeting or D.line(e.data.persona, "trade", { titre = D.title_for(G.Joueurs.get(player).honor) }) })
end

-- on s'est éloigné du comptoir pendant que la fenêtre était ouverte : on le dit, on ferme
function Shop.tooFar(player: Player)
	open[player] = nil
	G.Util.toast(player, "Trop loin du comptoir : rapproche-toi pour commercer.")
	G.remotes.Menu:FireClient(player, { kind = "close" })
end

function Shop.open(player: Player, e)
	local refuses = G.Reputation and rawget(G.Reputation, "refuses")
	local no = refuses and e.root and refuses(player, e.root.Position)
	if no then
		G.Util.toast(player, no, "danger")
		return
	end
	open[player] = e
	refresh(player)
end

local function near(player: Player, e): boolean
	local root = G.Util.root(player)
	return root ~= nil and e.model.Parent ~= nil and (root.Position - e.root.Position).Magnitude < 20
end

function Shop.buy(player: Player, item: string, n: number)
	local e = open[player]
	if not e or type(item) ~= "string" then
		return
	end
	if not near(player, e) then
		return Shop.tooFar(player)
	end
	n = math.clamp(math.floor(n), 1, 20)
	local buy = catalog(player, e)
	local entry
	for _, b in buy do
		if b.item == item then
			entry = b
		end
	end
	if not entry then
		return
	end
	local info = Config.ITEMS[item]
	if info and info.tool then
		n = 1
	end
	-- gens de métier : stock réel (ce que les joueurs leur ont apporté)
	if e.data.metier then
		n = math.min(n, entry.n or 0)
		if n <= 0 then
			G.Util.toast(player, "Plus en stock.")
			return
		end
	end
	if string.sub(item, 1, 7) == "animal:" and not G.Animals.canOwnMore(player) then
		return
	end
	if not G.Joueurs.take(player, "gold", entry.price * n) then
		G.Util.toast(player, "Pas assez d'or.")
		return
	end
	if string.sub(item, 1, 7) == "animal:" then
		local kind = string.sub(item, 8)
		G.Animals.buy(player, kind)
		G.Util.toast(player, Config.ANIMALS[kind].name .. " achetée ! Elle te suit : mène-la où tu veux et appuie [R] pour l'installer.", "big")
	else
		G.Joueurs.add(player, item, n)
	end
	if e.data.metier then
		G.Metiers.bought(e, item, n)
	end
	G.Util.geste(player, "commerce")
	G.Npcs.addOp(e, player, 1)
	G.Joueurs.sync(player)
	refresh(player)
end

function Shop.sell(player: Player, item: string, n: number)
	local e = open[player]
	if not e or type(item) ~= "string" then
		return
	end
	if not near(player, e) then
		return Shop.tooFar(player)
	end
	n = math.clamp(math.floor(n), 1, 999)
	n = math.min(n, G.Joueurs.count(player, item))
	if n <= 0 then
		return
	end
	-- un artisan ne rachète que ce dont il se sert (le client ne décide pas de ce qui est accepté)
	if e.data.metier then
		local _, wants = G.Metiers.catalog(player, e)
		if not (wants and wants[item]) then
			return
		end
	end
	local sold = 0
	local total = 0
	for _ = 1, n do
		local price = Shop.sellPrice(player, e, item)
		if price <= 0 then
			break
		end
		if not G.Joueurs.take(player, item, 1) then
			break
		end
		total += price
		sold += 1
		local k = e.reg.key .. ":" .. item
		soldToday[k] = (soldToday[k] or 0) + 1
	end
	if sold > 0 and e.data.metier then
		G.Metiers.sold(e, item, sold) -- ses matières : elles feront sa fournée de demain
	end
	if total > 0 then
		G.Util.geste(player, "commerce")
		G.Joueurs.add(player, "gold", total, true)
		G.Util.toast(player, "+" .. total .. " 💰", "gain")
		G.Joueurs.addSkillXp(player, "commerce", 1 + math.floor(total / 25))
		if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "vendre", "boutique", sold) end
		G.Social.bump(player, "soldGold", total)
		if total >= 20 and e.root then
			G.Reputation.addAt(player, e.root.Position, 1, "commerce")
		end
		if total >= 200 then
			G.Economie.record(player, "vente", n .. " " .. item .. " → " .. total)
		end
	end
	G.Joueurs.sync(player)
	refresh(player)
end

function Shop.newDay()
	table.clear(soldToday)
end

-- ----------------------------------------------------------------- Atelier

local STATION_RANGE = 16

-- Objet posé le plus proche d'un modèle donné (établi, four…) ; une station « publique » compte aussi
-- dans le bâtiment de village du même rôle (la forge du village : enclume et four pour tous)
local PUBLIC = nil -- modèle de station -> bâtiment de village (construit au premier appel : Config arrive à l'init)
local function nearModel(player: Player, modelName: string): boolean
	local root = G.Util.root(player)
	if not root then
		return false
	end
	if not PUBLIC then
		PUBLIC = {}
		for _, st in Config.STATIONS do
			if st.public then
				PUBLIC[st.model] = st.public
			end
		end
	end
	local pub = PUBLIC[modelName]
	for _, reg in G.World.loaded do
		if pub then
			local h = reg.houses and reg.houses["v:" .. pub]
			if h and h.model and h.model.Parent and (h.model:GetPivot().Position - root.Position).Magnitude < STATION_RANGE + 12 then
				return true
			end
		end
		if reg.placedModels then
			for _, m in reg.placedModels do
				if m.Name == modelName and m.Parent and (m:GetPivot().Position - root.Position).Magnitude < STATION_RANGE then
					return true
				end
			end
		end
	end
	return false
end

function Shop.stations(player: Player)
	local out = {}
	for id, st in Config.STATIONS do
		out[id] = nearModel(player, st.model)
	end
	return out
end

function Shop.openCraft(player: Player, tab: string?)
	G.remotes.Menu:FireClient(player, { kind = "craft", stations = Shop.stations(player), tab = tab })
end

-- Quantité possédée d'un ingrédient (objet ou groupe « n'importe quel poisson »)
local function countOf(player: Player, id: string): number
	local group = Config.ITEM_GROUPS[id]
	if group then
		local n = 0
		for _, it in group do
			n += G.Joueurs.count(player, it)
		end
		return n
	end
	return G.Joueurs.count(player, id)
end

local function takeOf(player: Player, id: string, n: number)
	local group = Config.ITEM_GROUPS[id]
	if not group then
		G.Joueurs.take(player, id, n)
		return
	end
	-- on prend d'abord les moins chers
	local sorted = table.clone(group)
	table.sort(sorted, function(a, b)
		return (Config.ITEMS[a].price or 0) < (Config.ITEMS[b].price or 0)
	end)
	for _, it in sorted do
		local have = G.Joueurs.count(player, it)
		local k = math.min(have, n)
		if k > 0 then
			G.Joueurs.take(player, it, k)
			n -= k
		end
		if n <= 0 then
			return
		end
	end
end

-- Ce qui manque pour une fournée, en clair : « Il manque : 2 🌲 Bois, 1 ⛓️ Fer » (nil si rien ne manque)
local function missing(player: Player, needs): string?
	local parts = {}
	for item, n in needs do
		local have = countOf(player, item)
		if have < n then
			local info = Config.needInfo(item)
			table.insert(parts, (n - have) .. " " .. (info.icon or "") .. " " .. info.name)
		end
	end
	table.sort(parts)
	return #parts > 0 and ("Il manque : " .. table.concat(parts, ", ")) or nil
end
Shop.missing = missing

function Shop.craft(player: Player, index: number?, times: number?)
	local r = index and Config.RECIPES[index]
	if not r then
		return
	end
	if r.skill and not G.Joueurs.needSkill(player, r.skill[1], r.skill[2], "Cette recette") then
		return
	end
	local skillName = r.skill and r.skill[1] or (r.cat == "cuisine" and "cuisine" or "artisanat")
	local function spend(item, n)
		-- talent Économe : parfois, les ingrédients ne partent pas
		if math.random() < 0.15 * G.Joueurs.talent(player, "econome") + 0.25 * G.Joueurs.talent(player, "prodigue") then
			return
		end
		takeOf(player, item, n)
	end
	if r.station and not nearModel(player, Config.STATIONS[r.station].model) then
		local st = Config.STATIONS[r.station]
		G.Util.toast(player, "Il faut être près " .. (st.art or "d'un") .. " " .. string.lower(st.name) .. " " .. st.icon .. (st.public and (" (ou de la " .. string.lower(st.public) .. " d'un village)") or "") .. " pour cette recette.")
		return
	end
	-- équipement fabriqué : une pièce aux stats fixes
	if r.gear then
		local miss = missing(player, r.needs)
		if miss then
			G.Util.toast(player, miss)
			return
		end
		for item, n in r.needs do
			spend(item, n)
		end
		local piece = table.clone(r.gear)
		piece.stats = table.clone(r.gear.stats)
		if G.Joueurs.talent(player, "forgeron") > 0 then
			local best, bv = nil, -1
			for st, v in piece.stats do
				if v > bv then
					best, bv = st, v
				end
			end
			if best then
				piece.stats[best] += 2
			end
		end
		-- qualité de la façon (19/11, « à ne pas oublier » § 7 Artisanat) : la compétence d'artisanat fait
		-- parfois une pièce soignée, excellente ou un chef-d'œuvre (stats en plus, rareté au-dessus),
		-- signée du nom de l'artisan (elle se revend, se donne, se reconnaît)
		local s = (G.Joueurs.skill(player, "artisanat") or 0) + ((G.Ventes and rawget(G.Ventes, "renownBonus")) and G.Ventes.renownBonus(player) or 0)
		local roll = math.random()
		local q = (roll < math.max(0, s - 25) * 0.004 and 3) or (roll < s * 0.006 and 2) or (roll < 0.15 + s * 0.008 and 1) or 0
		if q > 0 then
			local QUAL = { { "soignée", 1 }, { "excellente", 2 }, { "chef-d'œuvre", 4 } }
			piece.quality = QUAL[q][1]
			local best, bv = nil, -1
			for st, v in piece.stats do
				if v > bv then
					best, bv = st, v
				end
			end
			if best then
				piece.stats[best] += QUAL[q][2]
			end
			if q >= 2 then
				piece.rarity = math.min(#G.Gear.RARITIES, (piece.rarity or 1) + 1)
			end
			if q == 3 then
				G.Util.toast(player, "✨ Un chef-d'œuvre ! « " .. piece.name .. " » portera ton nom.", "big")
			end
		end
		piece.maker = player.DisplayName
		piece.makerId = player.UserId -- renom d'artisan (Systemes/Ventes)
		G.Joueurs.addSkillXp(player, "artisanat", 10 + (r.skill and r.skill[2] or 0))
		piece.visual = piece.visual or ""
		piece.power = piece.power or 0
		piece.id = math.random(1, 2 ^ 30)
		piece.crafted = true
		G.Joueurs.addGear(player, piece)
		G.Joueurs.addSkillXp(player, "artisanat", 8)
		G.Joueurs.sync(player)
		return true
	end
	local info = Config.ITEMS[r.item]
	local made = 0
	for _ = 1, math.clamp(math.floor(times or 1), 1, 20) do
		local miss = missing(player, r.needs)
		if miss then
			if made == 0 then
				G.Util.toast(player, miss)
			end
			break
		end
		if info.tool and G.Joueurs.has(player, r.item) then
			G.Util.toast(player, "Tu as déjà : " .. info.name)
			break
		end
		for item, n in r.needs do
			spend(item, n)
		end
		local out = r.count or 1
		-- ustensiles : louche ou cruche dans le sac → 25 % de chances d'une portion de plus (30 % avec la cuillère)
		if info.food and r.cat == "cuisine" and (G.Joueurs.has(player, "ladle") or G.Joueurs.has(player, "jug"))
			and math.random() < (G.Joueurs.has(player, "spoon") and 0.3 or 0.25) then
			out += 1
		end
		G.Joueurs.add(player, r.item, out, true)
		-- récipient rendu (Shared/Equilibre : l'eau rend le seau vide)
		for id, n in r.back or {} do
			G.Joueurs.add(player, id, n, true)
		end
		G.Joueurs.addSkillXp(player, skillName, 3 + math.floor((r.skill and r.skill[2] or 0) / 3))
		made += out
		if info.tool then
			break
		end
	end
	if made > 0 then
		G.Util.toast(player, "Fabriqué : " .. (info.icon or "") .. " " .. info.name .. (made > 1 and (" ×" .. made) or ""), "gain")
		local root = G.Util.root(player)
		if root then
			-- four / forge : coups sur le métal ; établi : coups de bois
			G.Util.sfx(r.station == "furnace" and "forge" or "hache", root.Position)
		end
		local prof = G.Joueurs.get(player)
		G.Social.bump(player, "crafted", made)
		if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "fabriquer", r.item, made * (r.count or 1)) end
	end
	G.Joueurs.sync(player)
	return made > 0
end

-- Grille d'artisanat : le joueur compose un mélange ; s'il correspond à une recette, on fabrique
-- (k fois si le mélange est multiplié) et la recette rejoint son carnet.
-- Réparer un outil usé (façon enclume de Minecraft) : près d'un établi, la MOITIÉ (arrondie au-
-- dessus) des matériaux de sa recette ; l'usure repart à zéro. Petit gain d'artisanat.
function Shop.repair(player: Player, id: string)
	local info = Config.ITEMS[id]
	local prof = G.Joueurs.get(player)
	if not info or not info.tool or not prof or (prof.inv[id] or 0) <= 0 then
		return
	end
	local worn = prof.wear and prof.wear[id] or 0
	if worn <= 0 then
		G.Util.toast(player, info.name .. " est comme neuve.")
		return
	end
	if not nearModel(player, Config.STATIONS.bench.model) then
		G.Util.toast(player, "Il faut être près d'un établi 🛠️ pour réparer.")
		return
	end
	local recipe = nil
	for _, r in Config.RECIPES do
		if r.item == id and r.needs then
			recipe = r
			break
		end
	end
	if not recipe then
		G.Util.toast(player, info.name .. " ne se répare pas.")
		return
	end
	local needs = {}
	for item, n in recipe.needs do
		needs[item] = math.ceil(n / 2)
	end
	local miss = missing(player, needs)
	if miss then
		G.Util.toast(player, miss)
		return
	end
	for item, n in needs do
		takeOf(player, item, n)
	end
	prof.wear[id] = 0
	local base = Config.baseOf(id)
	if G.Joueurs.bestTool(player, base) == id then
		player:SetAttribute("Usure_" .. base, 0)
	end
	G.Joueurs.addSkillXp(player, "artisanat", 3)
	G.Util.toast(player, "🔧 " .. info.name .. " réparée.")
	G.Joueurs.sync(player)
end

-- Forgeron du village (18/11) : répare d'un coup tous les outils usés, contre de l'or (la moitié du
-- prix de l'outil × son usure, +5 or de main-d'œuvre par outil). Alternative payante à Shop.repair.
function Shop.repairAll(player: Player)
	local prof = G.Joueurs.get(player)
	if not prof or not prof.wear then
		return
	end
	local list, total = {}, 0
	for id, w in prof.wear do
		local info = Config.ITEMS[id]
		if w > 0 and info and info.tool and (prof.inv[id] or 0) > 0 then
			local life = (G.Joueurs.TOOL_LIFE and G.Joueurs.TOOL_LIFE[Config.tierOf(id)]) or 150
			local cost = math.ceil((info.price or 40) * 0.5 * math.min(1, w / life)) + 5
			table.insert(list, id)
			total += cost
		end
	end
	if #list == 0 then
		G.Util.toast(player, "⚒️ Le forgeron : « Tes outils sont comme neufs ! »")
		return
	end
	if not G.Joueurs.take(player, "gold", total) then
		G.Util.toast(player, "⚒️ Le forgeron : « Ça fera " .. total .. " or pour tout remettre à neuf. »")
		return
	end
	for _, id in list do
		prof.wear[id] = 0
		local base = Config.baseOf(id)
		if G.Joueurs.bestTool(player, base) == id then
			player:SetAttribute("Usure_" .. base, 0)
		end
	end
	if G.Economie and G.Economie.record then
		G.Economie.record(player, "reparation", #list .. " outils (-" .. total .. ")")
	end
	G.Util.toast(player, "⚒️ Le forgeron remet " .. #list .. " outil(s) à neuf (" .. total .. " or).", "gain")
	G.Joueurs.sync(player)
end

function Shop.craftGrid(player: Player, slots, pick: number?)
	if type(slots) ~= "table" then
		return
	end
	local counts = {}
	for i = 1, 9 do
		local s = slots[i]
		if type(s) == "table" and type(s.id) == "string" and Config.ITEMS[s.id] then
			local n = math.clamp(math.floor(tonumber(s.n) or 0), 0, 999)
			if n > 0 then
				counts[s.id] = (counts[s.id] or 0) + n
			end
		end
	end
	for id, n in counts do
		if countOf(player, id) < n then
			G.Util.toast(player, "Tu n'as pas assez de " .. Config.needInfo(id).name .. ".")
			return
		end
	end
	local matches = Config.matchGridAll(counts)
	local index, k = nil, 0
	for _, m in matches do
		if not pick or m[1] == pick then
			index, k = m[1], m[2]
			break
		end
	end
	local r = index and Config.RECIPES[index]
	if not r then
		G.Util.toast(player, "Rien ne sort de ce mélange.")
		return
	end
	if Shop.craft(player, index, r.gear and 1 or k) then
		G.Joueurs.learnRecipe(player, Config.recipeKey(r))
		G.Util.geste(player, "fabriquer")
	end
end

-- ----------------------------------------------------------------- Objets posés

local function buildPlaced(reg, d)
	local info = Config.ITEMS[d.item]
	if not info or not info.place then
		return
	end
	local model = G.World.buildDeco({ model = info.place, x = d.x, z = d.z, yaw = d.yaw or 0, text = d.text, dy = d.dy }, reg.placedFolder)
	if not model then
		return
	end
	model.Name = info.place
	model:SetAttribute("PlacedId", d.id)
	if info.claim and G.Parcelles then
		G.Parcelles.decorate(model, d.x, d.z)
	end
	reg.placedModels = reg.placedModels or {}
	table.insert(reg.placedModels, model)
	local base = model.PrimaryPart
	local ownerP = G.Util.playerOf(d.owner)
	local whose = ownerP and (" de " .. ownerP.DisplayName) or ""
	if d.item == "campfire" then
		G.Util.prompt(base, "bed", "Dormir près du feu", "Feu de camp", { dist = 9 })
	elseif d.item == "workbench" then
		G.Util.prompt(base, "bench", "Utiliser l'établi", "Établi", { dist = 9 })
	elseif d.item == "furnace" then
		G.Util.prompt(base, "furnace", "Cuire / fondre", "Four", { dist = 9 })
	elseif d.item == "bed" then
		G.Util.prompt(base, "bed", ownerP and "Dormir (location " .. (d.rent or 15) .. " 💰 si ce n'est pas ton lit)" or "Dormir", "Lit" .. whose, { dist = 8, data = { Placed = d.id } })
	elseif d.item == "chest" then
		G.Util.prompt(base, "chest", "Ouvrir", "Coffre" .. whose, { dist = 8, data = { Placed = d.id } })
	elseif d.item == "door" then
		G.Util.prompt(base, "door", "Ouvrir", "Porte" .. whose, { dist = 7, data = { Placed = d.id } })
	elseif d.item == "barracks" then
		G.Util.prompt(base, "barracks", "Caserne", "Caserne" .. whose, { dist = 12, data = { Placed = d.id } })
		G.Util.prompt(base, "barracks_equip", "Équiper l'armée (fer + cuir)", "Caserne" .. whose, { dist = 12, hold = 0.6, key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonY, data = { Placed = d.id } })
	elseif d.item == "windmill" then
		G.Util.prompt(base, "mill", "Moulin (blé / farine)", "Moulin" .. whose, { dist = 10, data = { Placed = d.id } })
	elseif d.item == "sprinkler" then
		G.Util.prompt(base, "sprinkler", "Remplir (seau d'eau)", "Arroseur" .. whose, { dist = 8, data = { Placed = d.id } })
	elseif d.item == "beehive" then
		G.Util.prompt(base, "hive", "Récolter le miel", "Ruche" .. whose, { dist = 8, data = { Placed = d.id } })
	elseif d.item == "stall" then
		G.Util.prompt(base, "stall", "Voir l'étal", "Étal" .. whose, { dist = 8, data = { Placed = d.id } })
	elseif G.Machines.MECHS and G.Machines.MECHS[d.item] then
		local mech = G.Machines.MECHS[d.item]
		G.Util.prompt(base, "mecanisme", d.up and mech.up or mech.down, info.name .. whose, { dist = 10, hold = 0.4, data = { Placed = d.id } })
		if d.up then
			task.defer(G.Machines.applyMech, model, d, false)
		end
	elseif d.item == "practice_lock" then
		G.Util.prompt(base, "practice", "S'entraîner", "Serrure d'entraînement", { dist = 7, data = { Placed = d.id } })
	elseif info.turret then
		G.Util.prompt(base, "turret_load", "Garnir de carreaux", info.name .. whose .. " (" .. (d.ammo or 0) .. " 🎯)", { dist = 8, data = { Placed = d.id } })
	end
	-- ramasser : plus long pour les pièces de construction (on ne démonte pas un mur par erreur)
	G.Util.prompt(base, "pickup", info.build and "Démonter" or "Ramasser", info.name .. whose,
		{ dist = info.build and 6 or 8, hold = info.build and 1.5 or 1, key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonY, data = { Placed = d.id } })
	d.model = nil
	return model
end

function Shop.onRegionLoad(reg)
	local folder = Instance.new("Folder")
	folder.Name = "Pose"
	folder.Parent = reg.folder
	reg.placedFolder = folder
	reg.placedModels = {}
	for _, d in reg.state.placed do
		buildPlaced(reg, d)
	end
	for _, gr in reg.state.graves do
		G.World.buildDeco({ model = "Terre_Retournee", x = gr.x, z = gr.z, yaw = 0 }, folder)
	end
	-- le port : un embarcadère près de l'arrivée de l'île
	if reg.plan.startRuin then
		local r = reg.plan.startRuin
		local dock = G.World.buildDeco({ model = "Embarcadere", x = r.doorX + 14, z = r.doorZ + 6, yaw = 90 }, folder)
		if dock and dock.PrimaryPart then
			G.Util.prompt(dock.PrimaryPart, "port", "Prendre la mer", "Embarcadère · carte des mondes", { dist = 10 })
		end
	end
	-- le lit de la maison de départ
	local ruin = reg.plan.startRuin
	if ruin and reg.houses[ruin.id] then
		local base = reg.houses[ruin.id].model.PrimaryPart
		local bed = base:FindFirstChild("PiedDuLit")
		if bed then
			G.Util.prompt(bed, "bed", "Dormir", "Ton lit de paille", { dist = 9 })
		end
	end
end

-- Couche occupée par un objet posé : deux murs ne vont pas au même bord, deux planchers pas sur la même case…
function Shop.slotOf(item: string, x: number, z: number): string
	local info = Config.ITEMS[item]
	local layer = "objet"
	if item == "door" then
		layer = "porte" -- une porte se pose dans l'ouverture d'un mur avec porte
	elseif info and info.dy then
		layer = (info.grid == "edge" and "bord" or (item == "roof2" and "toit" or "sol")) .. "2" -- étage
	elseif info and info.grid == "edge" then
		layer = "bord"
	elseif item == "floor" then
		layer = "sol"
	elseif item == "roof" then
		layer = "toit"
	elseif not (info and info.grid) then
		return "libre:" .. item .. ":" .. x .. "," .. z
	end
	return layer .. ":" .. math.floor(x * 2 + 0.5) .. "," .. math.floor(z * 2 + 0.5)
end

function Shop.place(player: Player, item: string)
	local info = Config.ITEMS[item]
	if not info or not info.place or not G.Joueurs.has(player, item) then
		return
	end
	local root = G.Util.root(player)
	if not root then
		return
	end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.1 then
		flat = Vector3.new(0, 0, -1)
	end
	flat = flat.Unit
	local CELL = Config.CELL
	local x, z, yaw
	if info.grid == "edge" then
		-- mur / clôture : sur le bord de la case où l'on se tient, du côté où l'on regarde
		local cx, cz = math.floor(root.Position.X / CELL), math.floor(root.Position.Z / CELL)
		local mx, mz = cx * CELL + CELL / 2, cz * CELL + CELL / 2
		if math.abs(flat.X) > math.abs(flat.Z) then
			x, z, yaw = mx + math.sign(flat.X) * CELL / 2, mz, 90
		else
			x, z, yaw = mx, mz + math.sign(flat.Z) * CELL / 2, 0
		end
	elseif info.grid == "cell" then
		-- case devant soi, tourné vers soi (quart de tour)
		local p = root.Position + flat * CELL
		local cx, cz = math.floor(p.X / CELL), math.floor(p.Z / CELL)
		x, z = cx * CELL + CELL / 2, cz * CELL + CELL / 2
		yaw = math.floor((math.deg(math.atan2(-flat.X, -flat.Z)) + 45) / 90) * 90
	else
		local p = root.Position + flat * 5
		x, z = math.floor(p.X * 10) / 10, math.floor(p.Z * 10) / 10
		yaw = math.floor(math.deg(math.atan2(-flat.X, -flat.Z)))
	end
	local pos = Vector3.new(x, root.Position.Y, z)
	if G.Util.isWater(pos.X, pos.Z) then
		G.Util.toast(player, "Pas sur l'eau !")
		return
	end
	local reg = G.World.regionAt(pos)
	if not reg then
		return
	end
	if G.Parcelles and not G.Parcelles.canBuild(player, pos) then
		return
	end
	-- emplacement déjà pris (même couche : bord, sol, toit ou objet)
	local slot = Shop.slotOf(item, x, z)
	for _, other in reg.state.placed do
		if Shop.slotOf(other.item, other.x, other.z) == slot then
			G.Util.toast(player, "Il y a déjà quelque chose ici.")
			return
		end
	end
	if info.plotOnly and G.Parcelles.at(pos) ~= G.Util.pid(player) then
		G.Util.toast(player, "Ça se construit sur TA parcelle (pose d'abord un panneau de propriété).")
		return
	end
	if info.claim and not G.Parcelles.create(player, pos) then
		return
	end
	G.Joueurs.take(player, item, 1)
	local d = { id = G.Util.newId("pl"), item = item, x = x, z = z, yaw = yaw, owner = G.Util.pid(player), dy = info.dy }
	if info.claim then
		d.text = "Terrain de " .. player.DisplayName
	end
	table.insert(reg.state.placed, d)
	buildPlaced(reg, d)
	G.Joueurs.sync(player)
end

function Shop.pickup(player: Player, id: string)
	for _, reg in G.World.loaded do
		for i, d in reg.state.placed do
			if d.id == id then
				local pinfo = Config.ITEMS[d.item]
				if pinfo and pinfo.turret and not G.Util.owns(player, d.owner) then
					G.Util.toast(player, "Fixée au sol et bien trop lourde : il faut la casser (pioche ou hache).")
					return
				end
				if d.item == "stall" and not G.Util.owns(player, d.owner) and not Config.LIBRE.etalEtPanneauVolables then
					G.Util.toast(player, "Cet étal est cloué au sol : seul son propriétaire peut le démonter.")
					return
				end
				if pinfo and pinfo.turret and (d.ammo or 0) > 0 then
					G.Joueurs.add(player, Config.TURRETS[pinfo.turret].ammo, d.ammo, true) -- ses carreaux reviennent
				end
				if d.item == "stall" and d.stall then
					for it, e in d.stall.items do
						G.Joueurs.add(player, it, e[1], true)
					end
					if d.stall.till > 0 then
						G.Joueurs.add(player, "gold", d.stall.till, true)
					end
				end
				if d.item == "claim" then
					if not G.Util.owns(player, d.owner) and not Config.LIBRE.etalEtPanneauVolables then
						G.Util.toast(player, "Ce panneau est planté solidement : seul son propriétaire peut l'enlever.")
						return
					end
					G.Parcelles.removeAt(player, d.x, d.z)
				end
				if d.owner and not G.Util.owns(player, d.owner) then
					if G.Parcelles and not G.Parcelles.canBuild(player, Vector3.new(d.x, 0, d.z), true) then
						G.Law.crime(player, "breakin", Vector3.new(d.x, 0, d.z), d.owner)
					end
					G.Law.crime(player, "theft", Vector3.new(d.x, 0, d.z), d.owner)
				end
				for it, n in d.items or {} do
					G.Joueurs.add(player, it, n, true)
				end
				table.remove(reg.state.placed, i)
				for j, m in reg.placedModels do
					local pos = m:GetPivot().Position
					if math.abs(pos.X - d.x) < 0.2 and math.abs(pos.Z - d.z) < 0.2 then
						m:Destroy()
						table.remove(reg.placedModels, j)
						break
					end
				end
				G.Joueurs.add(player, d.item, 1)
				G.Joueurs.sync(player)
				return
			end
		end
	end
end

-- ----------------------------------------------------------------- Coffres de rangement

local function findPlaced(id: string)
	for _, reg in G.World.loaded do
		for _, d in reg.state.placed do
			if d.id == id then
				return d, reg
			end
		end
	end
	return nil, nil
end

local function sendChest(player: Player, d)
	local ownerP = G.Util.playerOf(d.owner)
	G.remotes.Menu:FireClient(player, {
		kind = "chest", id = d.id, items = d.items or {},
		title = "Coffre" .. (ownerP and (" de " .. ownerP.DisplayName) or ""),
		mine = G.Util.owns(player, d.owner),
	})
end

local unlocked = {} -- joueur -> coffre crocheté (accès le temps de se servir)

function Shop.openChest(player: Player, id: string)
	local d = type(id) == "string" and findPlaced(id)
	if not d or d.item ~= "chest" then
		return
	end
	d.items = d.items or {}
	G.Protection.access(player, d, function()
		unlocked[player] = d.id
		sendChest(player, d)
	end)
end

-- Déposer (put = true) ou prendre dans un coffre ; prendre dans celui d'un autre = vol
function Shop.chestMove(player: Player, id: string, item: string, n: number, put: boolean, quiet: boolean?): boolean?
	if type(id) ~= "string" or type(item) ~= "string" or not Config.ITEMS[item] then
		return
	end
	if id == "bank" then
		G.Economie.bankMove(player, item, n, put)
		return
	end
	if id == "clan" then
		G.Clans.chestMove(player, item, n, put)
		return
	end
	local d = findPlaced(id)
	local root = G.Util.root(player)
	if not d or d.item ~= "chest" or not root then
		if not quiet then
			G.Util.toast(player, "Ce coffre n'est plus là.")
			G.remotes.Menu:FireClient(player, { kind = "close" })
		end
		return
	end
	if (Vector3.new(d.x, root.Position.Y, d.z) - root.Position).Magnitude > 14 then
		if not quiet then
			G.Util.toast(player, "Trop loin du coffre : rapproche-toi.")
			G.remotes.Menu:FireClient(player, { kind = "close" })
		end
		return
	end
	d.items = d.items or {}
	-- un coffre verrouillé d'un autre : seulement après l'avoir crocheté
	if (d.lock or 0) > 0 and not G.Util.owns(player, d.owner) and unlocked[player] ~= d.id and not G.Util.trusted(player, d.owner, "coffres") then
		if not quiet then
			G.Util.toast(player, "🔒 Ce coffre est verrouillé.")
		end
		return
	end
	n = math.clamp(math.floor(n), 1, 999)
	if put then
		n = math.min(n, G.Joueurs.count(player, item))
		if n <= 0 or not G.Joueurs.take(player, item, n) then
			return
		end
		d.items[item] = (d.items[item] or 0) + n
	else
		n = math.min(n, d.items[item] or 0)
		if n <= 0 then
			return
		end
		if d.owner and not G.Util.owns(player, d.owner) then
			if G.Util.trusted(player, d.owner, "coffres") then
				G.Protection.log(d.owner, player.DisplayName .. " a pris " .. n .. " " .. (Config.ITEMS[item].name or item) .. " dans ton coffre (autorisé).", false)
			else
				G.Law.crime(player, "theft", Vector3.new(d.x, root.Position.Y, d.z), d.owner)
			end
		end
		d.items[item] -= n
		if d.items[item] <= 0 then
			d.items[item] = nil
		end
		G.Joueurs.add(player, item, n, true)
	end
	if not quiet then
		G.Joueurs.sync(player)
		G.Mondes.saveSoon(player) -- coffre (monde) et sac (perso) : écrits ensemble, vite
		sendChest(player, d)
	end
	return true
end

-- Transfert en masse : « stack » range dans le coffre tout ce qu'il contient déjà (compléter les
-- piles, façon Minecraft) ; « take » vide le coffre dans le sac — seulement le sien ou un coffre où
-- l'on est autorisé (jamais de vol en masse : on vole objet par objet, et on le paie).
function Shop.chestBulk(player: Player, id: string, mode: string)
	if type(id) ~= "string" or (mode ~= "stack" and mode ~= "take") then
		return
	end
	local items
	if id == "clan" then
		return -- coffre de clan : chaque mouvement est une écriture partagée, on reste objet par objet
	elseif id == "bank" then
		local prof = G.Joueurs.get(player)
		local b = prof and prof.banks and G.world and prof.banks[G.world.id]
		items = b and b.items or nil
	else
		local d = findPlaced(id)
		if not d or d.item ~= "chest" then
			return
		end
		if mode == "take" and d.owner and not G.Util.owns(player, d.owner) and not G.Util.trusted(player, d.owner, "coffres") and not Config.LIBRE.videCoffreAutrui then
			G.Util.toast(player, "Ce coffre n'est pas à toi : on ne le vide pas d'un geste.")
			return
		end
		items = d.items or {}
	end
	if not items then
		return
	end
	local inv = G.Joueurs.get(player).inv
	local moves = {}
	for item, n in (mode == "stack" and inv or items) do
		if item ~= "gold" and n > 0 and (mode == "take" or (items[item] or 0) > 0) then
			table.insert(moves, { item, n })
		end
	end
	local placed = id ~= "bank" and id ~= "clan"
	local count = 0
	for _, m in moves do
		if placed then
			if Shop.chestMove(player, id, m[1], m[2], mode == "stack", true) then
				count += 1
			end
		else
			Shop.chestMove(player, id, m[1], m[2], mode == "stack")
			count += 1
		end
	end
	if placed then
		G.Joueurs.sync(player)
		G.Mondes.saveSoon(player)
		local d = findPlaced(id)
		if d then
			sendChest(player, d)
		end
	end
	if count > 0 then
		G.Util.sfx("coffre", Vector3.zero, player)
	end
	return count
end

return Shop
