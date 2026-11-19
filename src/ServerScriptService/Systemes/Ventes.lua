-- Hôtel des ventes v2 (19/11) : la fenêtre [F] des boîtes aux lettres. Complète Systemes/Poste
-- (qui garde le courrier et les annonces d'objets à prix fixe, G.world.market) :
--  · ÉQUIPEMENT : une pièce du sac (fabriquée, signée…) se vend à prix fixe ou aux enchères ;
--  · ENCHÈRES (objets ou équipement) : prix de départ, durée réelle (2 h, 12 h, 24 h). Chaque offre
--    doit dépasser la précédente d'au moins 5 % ; l'or de l'enchérisseur est mis de côté, celui qui
--    est dépassé est remboursé par courrier. À la fin : l'objet part au gagnant par courrier, l'or au
--    vendeur ; sans offre, l'objet revient au vendeur ;
--  · RECHERCHE / TRI / PRIX DE RÉFÉRENCE : la fenêtre filtre et trie ; le prix de référence d'un objet
--    est le prix médian de ses 12 dernières ventes sur ce monde (G.world.hdvHist).
-- Frais : 2 % du prix (ou du prix de départ) à la mise en vente, comme Poste. Aucune limite de nombre
-- d'annonces (principe « pas de plafond » : les frais suffisent).
-- État : G.world.hdv = { annonce… } (sauvegardé avec le monde), G.world.hdvHist = { [objet] = { prix unitaires } }.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ventes = {}
local G, Config
local remote: RemoteEvent

local FEE = 0.02
local MIN_RAISE = 0.05
local DURATIONS = { 2 * 3600, 12 * 3600, 24 * 3600 }
local FIXED_DAYS = 7 -- annonce d'équipement à prix fixe : rendue après 7 jours de jeu (comme Poste)
local HIST = 12

local function list()
	G.world.hdv = G.world.hdv or {}
	return G.world.hdv
end

local function hist(item: string)
	G.world.hdvHist = G.world.hdvHist or {}
	G.world.hdvHist[item] = G.world.hdvHist[item] or {}
	return G.world.hdvHist[item]
end

local function record(item: string?, unit: number)
	if not item then
		return
	end
	local h = hist(item)
	table.insert(h, math.floor(unit + 0.5))
	while #h > HIST do
		table.remove(h, 1)
	end
end

local function reference(item: string): number?
	local h = G.world.hdvHist and G.world.hdvHist[item]
	if not h or #h == 0 then
		return nil
	end
	local s = table.clone(h)
	table.sort(s)
	return s[math.floor((#s + 1) / 2)]
end

local function atPost(player: Player): boolean
	local at = G.Poste.at and G.Poste.at[player]
	local r = G.Util.root(player)
	return at ~= nil and r ~= nil and (r.Position - at).Magnitude < 20
end

local function sellable(id: string): boolean
	local info = Config.ITEMS[id]
	return info ~= nil and id ~= "gold" and not info.tool
end

local function gearLabel(g): string
	local ok, s = pcall(G.Gear.describe, g)
	return ok and s or (g.name or "?")
end

-- remet l'objet ou la pièce d'une annonce à quelqu'un, par courrier (sûr même s'il est hors ligne)
local function giveBack(uid: number, l, from: string, tag: string)
	local parcel = { id = tag .. "_" .. l.id, from = from }
	if l.gear then
		parcel.gear = { l.gear }
	else
		parcel.items = { [l.item] = l.n }
	end
	G.Poste.deliverSystem(uid, parcel)
end

-- ---------------------------------------------------------------- renom d'artisan
-- Une pièce SIGNÉE (Shop.craft : makerId) achetée par un autre joueur, ici, fait monter le renom de son
-- artisan (par monde : G.world.renom). Paliers : titre affiché à l'hôtel des ventes, et la qualité de
-- façon s'améliore un peu (Shop.craft : Ventes.renownBonus).
Ventes.RENOWN = { { 5, "connu" }, { 15, "réputé" }, { 40, "maître reconnu" }, { 100, "illustre" } }

function Ventes.renown(uid: number?): number
	return uid and G.world and G.world.renom and G.world.renom[tostring(uid)] or 0
end

function Ventes.renownTier(uid: number?): (number, string?)
	local n = Ventes.renown(uid)
	local tier, name = 0, nil
	for i, t in Ventes.RENOWN do
		if n >= t[1] then
			tier, name = i, t[2]
		end
	end
	return tier, name
end

-- bonus de compétence pour la QUALITÉ de façon seulement (3 par palier)
function Ventes.renownBonus(player: Player): number
	return 3 * (Ventes.renownTier(player.UserId))
end

local function addRenown(piece, buyerId: number)
	local maker = type(piece) == "table" and piece.makerId
	if not maker or maker == buyerId or piece.renownCounted then
		return
	end
	-- une pièce ne compte qu'UNE fois dans toute sa vie (sinon deux comptes se la revendraient en boucle)
	piece.renownCounted = true
	G.world.renom = G.world.renom or {}
	local key = tostring(maker)
	local before = Ventes.renownTier(maker)
	G.world.renom[key] = (G.world.renom[key] or 0) + 1
	local after, name = Ventes.renownTier(maker)
	local p = game:GetService("Players"):GetPlayerByUserId(maker)
	if p then
		G.Util.toast(p, "⚒️ Une pièce signée de ta main a trouvé preneur (renom " .. G.world.renom[key] .. ").")
		if after > before then
			G.Util.toast(p, "⚒️ Te voilà artisan " .. tostring(name) .. " : on recherche tes pièces.", "big")
		end
	end
end

local function makerTag(g): string
	local _, name = Ventes.renownTier(type(g) == "table" and g.makerId)
	return name and (" — artisan " .. name) or ""
end

-- ---------------------------------------------------------------- fenêtre

function Ventes.open(player: Player)
	-- même point d'ancrage que la poste (on peut aussi y acheter les annonces de Poste)
	G.Poste.at = G.Poste.at or {}
	local r = G.Util.root(player)
	G.Poste.at[player] = r and r.Position or nil
	Ventes.resolve()
	if rawget(G.Poste, "expire") then
		G.Poste.expire() -- annonces de la poste trop vieilles : rendues avant d'afficher
	end
	local now = os.time()
	local rows = {}
	for _, l in G.world.market or {} do
		local info = Config.ITEMS[l.item] or { name = l.item, icon = "?" }
		table.insert(rows, {
			id = l.id, src = "poste", mode = "fixe", kind = "item", item = l.item, n = l.n, price = l.price,
			name = info.name, icon = info.icon or "", seller = l.sellerName, mine = l.seller == player.UserId, ref = reference(l.item),
		})
	end
	for _, l in list() do
		local row = {
			id = l.id, src = "hdv", mode = l.mode, kind = l.gear and "gear" or "item", n = l.n or 1, price = l.price,
			seller = l.sellerName, mine = l.seller == player.UserId,
			bid = l.bid, bidder = l.bidderName, mineBid = l.bidder == player.UserId, left = l.ends and math.max(0, l.ends - now) or nil,
		}
		if l.gear then
			row.name, row.icon, row.label, row.rarity = l.gear.name or "?", "🛡️", gearLabel(l.gear) .. makerTag(l.gear), l.gear.rarity
		else
			local info = Config.ITEMS[l.item] or { name = l.item, icon = "?" }
			row.item, row.name, row.icon, row.ref = l.item, info.name, info.icon or "", reference(l.item)
		end
		if l.mode == "enchere" then
			row.minBid = l.bid and math.max(l.bid + 1, math.ceil(l.bid * (1 + MIN_RAISE))) or l.price
		end
		table.insert(rows, row)
	end
	-- le sac : ce qu'on peut vendre
	local prof = G.Joueurs.get(player)
	local bag = {}
	for id, n in (prof and prof.inv) or {} do
		if type(n) == "number" and n > 0 and sellable(id) then
			local info = Config.ITEMS[id]
			table.insert(bag, { item = id, n = n, name = info.name, icon = info.icon or "", ref = reference(id), value = info.price })
		end
	end
	table.sort(bag, function(a, b)
		return a.name < b.name
	end)
	local gear = {}
	for i, g in (prof and prof.gear) or {} do
		table.insert(gear, { idx = i, name = g.name or "?", label = gearLabel(g), rarity = g.rarity })
	end
	remote:FireClient(player, {
		rows = rows, bag = bag, gear = gear, gold = G.Joueurs.count(player, "gold"), fee = FEE, raise = MIN_RAISE,
	})
end

-- ---------------------------------------------------------------- vendre

function Ventes.sell(player: Player, data)
	if not atPost(player) or type(data) ~= "table" then
		return
	end
	local prof = G.Joueurs.get(player)
	if not prof then
		return
	end
	local mode = data.mode == "enchere" and "enchere" or "fixe"
	local price = math.clamp(math.floor(tonumber(data.price) or 0), 1, 1000000)
	local fee = math.max(1, math.floor(price * FEE))
	local l = { id = "hv2" .. HttpService:GenerateGUID(false), seller = player.UserId, sellerName = player.DisplayName, mode = mode, price = price, day = G.world.day }
	if mode == "enchere" then
		l.ends = os.time() + (DURATIONS[math.clamp(math.floor(tonumber(data.duree) or 2), 1, #DURATIONS)])
	end
	if data.kind == "gear" then
		local i = math.floor(tonumber(data.idx) or 0)
		local g = prof.gear[i]
		if not g or g.name ~= data.name then
			G.Util.toast(player, "Cette pièce n'est plus dans ton sac.")
			Ventes.open(player)
			return
		end
		if G.Joueurs.count(player, "gold") < fee then
			G.Util.toast(player, "Il faut " .. fee .. " 💰 de frais (2 %).")
			return
		end
		G.Joueurs.take(player, "gold", fee)
		table.remove(prof.gear, i)
		G.Joueurs.markDirty(player)
		l.gear = g
	else
		local item = data.item
		if type(item) ~= "string" or not sellable(item) then
			return
		end
		local have = G.Joueurs.count(player, item)
		local n = math.clamp(math.floor(tonumber(data.n) or 1), 1, math.max(1, have))
		if have < 1 then
			return
		end
		if mode == "fixe" then
			-- prix fixe d'un objet : c'est l'annonce de la poste (même liste qu'avant)
			if G.Joueurs.count(player, "gold") < fee then
				G.Util.toast(player, "Il faut " .. fee .. " 💰 de frais (2 %).")
				return
			end
			G.Joueurs.take(player, "gold", fee)
			G.Joueurs.take(player, item, n)
			G.world.market = G.world.market or {}
			table.insert(G.world.market, { id = "hv" .. HttpService:GenerateGUID(false), seller = player.UserId, sellerName = player.DisplayName, item = item, n = n, price = price, day = G.world.day })
			G.Util.toast(player, "🏷️ En vente : " .. n .. " " .. Config.ITEMS[item].name .. " pour " .. price .. " 💰 (frais " .. fee .. ").", "gain")
			G.Joueurs.sync(player)
			Ventes.open(player)
			return
		end
		if G.Joueurs.count(player, "gold") < fee then
			G.Util.toast(player, "Il faut " .. fee .. " 💰 de frais (2 %).")
			return
		end
		G.Joueurs.take(player, "gold", fee)
		G.Joueurs.take(player, item, n)
		l.item, l.n = item, n
	end
	table.insert(list(), l)
	local what = l.gear and (l.gear.name or "?") or (l.n .. " " .. Config.ITEMS[l.item].name)
	G.Util.toast(player, (mode == "enchere" and "🔨 Aux enchères : " or "🏷️ En vente : ") .. what .. " à partir de " .. price .. " 💰 (frais " .. fee .. ").", "gain")
	G.Economie.record(player, "hdv_vente", what .. " " .. price)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	Ventes.open(player)
end

-- ---------------------------------------------------------------- acheter / enchérir / retirer

local function findHdv(id: string)
	for i, l in list() do
		if l.id == id then
			return l, i
		end
	end
	return nil, nil
end

function Ventes.buy(player: Player, data)
	if not atPost(player) or type(data) ~= "table" or type(data.id) ~= "string" then
		return
	end
	if data.src == "poste" then
		-- annonce de la poste : même règle que Poste.buy, sans rouvrir la fenêtre de la poste
		local m = G.world.market or {}
		for i, l in m do
			if l.id == data.id then
				if l.seller == player.UserId then
					table.remove(m, i)
					G.Joueurs.add(player, l.item, l.n, true)
				else
					if not G.Joueurs.take(player, "gold", l.price) then
						G.Util.toast(player, "Il te faut " .. l.price .. " 💰.")
						return
					end
					table.remove(m, i)
					G.Joueurs.add(player, l.item, l.n, true)
					G.Poste.deliverSystem(l.seller, { id = "pay_" .. l.id, from = "Hôtel des ventes (" .. player.DisplayName .. ")", gold = l.price })
					record(l.item, l.price / math.max(1, l.n))
					G.Economie.record(player, "hdv", l.n .. " " .. l.item .. " -> " .. l.price)
					G.Joueurs.addSkillXp(player, "commerce", 2)
					G.Util.toast(player, "🏷️ Acheté : " .. l.n .. " " .. (Config.ITEMS[l.item] and Config.ITEMS[l.item].name or l.item) .. ".", "gain")
				end
				G.Mondes.saveSoon(player)
				G.Joueurs.sync(player)
				Ventes.open(player)
				return
			end
		end
		G.Util.toast(player, "Cette annonce n'existe plus.")
		Ventes.open(player)
		return
	end
	local l, i = findHdv(data.id)
	if not l or l.mode ~= "fixe" then
		G.Util.toast(player, "Cette annonce n'existe plus.")
		Ventes.open(player)
		return
	end
	if l.seller ~= player.UserId then
		if not G.Joueurs.take(player, "gold", l.price) then
			G.Util.toast(player, "Il te faut " .. l.price .. " 💰.")
			return
		end
		G.Poste.deliverSystem(l.seller, { id = "pay_" .. l.id, from = "Hôtel des ventes (" .. player.DisplayName .. ")", gold = l.price })
		G.Economie.record(player, "hdv", (l.gear and l.gear.name or l.item) .. " -> " .. l.price)
		G.Joueurs.addSkillXp(player, "commerce", 2)
	end
	table.remove(list(), i)
	local prof = G.Joueurs.get(player)
	if l.gear and prof then
		table.insert(prof.gear, l.gear) -- directement dans le sac (pas de butin au sol)
		G.Joueurs.markDirty(player)
		if l.seller ~= player.UserId then
			addRenown(l.gear, player.UserId)
		end
	elseif l.item then
		G.Joueurs.add(player, l.item, l.n, true)
		if l.seller ~= player.UserId then
			record(l.item, l.price / math.max(1, l.n))
		end
	end
	G.Util.toast(player, l.seller == player.UserId and "Annonce retirée." or "🏷️ Acheté : " .. (l.gear and l.gear.name or l.item) .. ".", "gain")
	G.Mondes.saveSoon(player)
	G.Joueurs.sync(player)
	Ventes.open(player)
end

function Ventes.bid(player: Player, data)
	if not atPost(player) or type(data) ~= "table" or type(data.id) ~= "string" then
		return
	end
	local l = findHdv(data.id)
	if not l or l.mode ~= "enchere" or (l.ends and os.time() >= l.ends) then
		G.Util.toast(player, "Cette enchère est terminée.")
		Ventes.open(player)
		return
	end
	if l.seller == player.UserId then
		G.Util.toast(player, "Tu ne peux pas enchérir sur ta propre vente.")
		return
	end
	if l.bidder == player.UserId then
		G.Util.toast(player, "Tu es déjà le meilleur enchérisseur.")
		return
	end
	local min = l.bid and math.max(l.bid + 1, math.ceil(l.bid * (1 + MIN_RAISE))) or l.price
	local amount = math.floor(tonumber(data.amount) or 0)
	if amount < min then
		G.Util.toast(player, "L'offre doit être d'au moins " .. min .. " 💰.")
		return
	end
	if not G.Joueurs.take(player, "gold", amount) then
		G.Util.toast(player, "Il te faut " .. amount .. " 💰.")
		return
	end
	if l.bidder then
		G.Poste.deliverSystem(l.bidder, { id = "rmb_" .. l.id .. "_" .. tostring(l.bid), from = "Hôtel des ventes (offre dépassée)", gold = l.bid })
		local prev = game:GetService("Players"):GetPlayerByUserId(l.bidder)
		if prev then
			G.Util.toast(prev, "🔨 Ton offre est dépassée sur « " .. (l.gear and l.gear.name or Config.ITEMS[l.item].name) .. " » : ton or t'attend au courrier.")
		end
	end
	l.bid, l.bidder, l.bidderName = amount, player.UserId, player.DisplayName
	G.Util.toast(player, "🔨 Offre de " .. amount .. " 💰 enregistrée. L'or est mis de côté.", "gain")
	G.Economie.record(player, "hdv_offre", amount)
	G.Mondes.saveSoon(player)
	G.Joueurs.sync(player)
	Ventes.open(player)
end

-- retirer sa propre annonce (une enchère seulement tant que personne n'a fait d'offre)
function Ventes.cancel(player: Player, data)
	if not atPost(player) or type(data) ~= "table" or type(data.id) ~= "string" then
		return
	end
	local l, i = findHdv(data.id)
	if not l or l.seller ~= player.UserId then
		return
	end
	if l.bidder then
		G.Util.toast(player, "Quelqu'un a déjà enchéri : la vente ira à son terme.")
		return
	end
	table.remove(list(), i)
	local prof = G.Joueurs.get(player)
	if l.gear and prof then
		table.insert(prof.gear, l.gear)
		G.Joueurs.markDirty(player)
	elseif l.item then
		G.Joueurs.add(player, l.item, l.n, true)
	end
	G.Util.toast(player, "Annonce retirée.")
	G.Joueurs.sync(player)
	Ventes.open(player)
end

-- ---------------------------------------------------------------- fins d'enchères, invendus

function Ventes.resolve()
	if not G.world then
		return
	end
	local now = os.time()
	local L = list()
	for i = #L, 1, -1 do
		local l = L[i]
		if l.mode == "enchere" and l.ends and now >= l.ends then
			table.remove(L, i)
			if l.bidder then
				giveBack(l.bidder, l, "Hôtel des ventes (enchère gagnée)", "win")
				if l.gear then
					addRenown(l.gear, l.bidder)
				end
				G.Poste.deliverSystem(l.seller, { id = "pay_" .. l.id, from = "Hôtel des ventes (" .. tostring(l.bidderName) .. ")", gold = l.bid })
				if l.item then
					record(l.item, l.bid / math.max(1, l.n or 1))
				end
			else
				giveBack(l.seller, l, "Hôtel des ventes (enchère sans offre)", "exp")
			end
		elseif l.mode == "fixe" and G.world.day - (l.day or 0) >= FIXED_DAYS then
			table.remove(L, i)
			giveBack(l.seller, l, "Hôtel des ventes (invendu)", "exp")
		end
	end
end

local acc = 0
function Ventes.step(dt: number)
	acc += dt
	if acc >= 30 then
		acc = 0
		Ventes.resolve()
	end
end

function Ventes.init(g)
	G = g
	Config = G.Config
	remote = ReplicatedStorage:FindFirstChild("HotelVentes") or Instance.new("RemoteEvent")
	remote.Name = "HotelVentes"
	remote.Parent = ReplicatedStorage
	G.Interact.onPrompt("hdv", function(player)
		Ventes.open(player)
	end)
	G.Interact.onAction("hdv_ouvrir", function(player)
		if atPost(player) then
			Ventes.open(player)
		end
	end)
	G.Interact.onAction("hdv_vendre", Ventes.sell)
	G.Interact.onAction("hdv_acheter", Ventes.buy)
	G.Interact.onAction("hdv_encherir", Ventes.bid)
	G.Interact.onAction("hdv_retirer", Ventes.cancel)
end

return Ventes
