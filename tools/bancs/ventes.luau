-- Banc de l'hôtel des ventes v2 et du renom d'artisan (Systemes/Ventes). Mode Edit, sans Play :
-- faux joueurs, faux monde, faux courrier ; l'horloge os.time est remplacée pour faire finir les enchères.
local src = game.ServerScriptService.Systemes.Ventes.Source
local now = 1000000
local fn = assert(loadstring(src))
setfenv(fn, setmetatable({ os = setmetatable({ time = function() return now end }, { __index = os }) }, { __index = getfenv() }))
local V = fn()
local mail = {}
local function P(uid, name) return { UserId = uid, DisplayName = name } end
local A, B, Cc = P(1, "Alice"), P(2, "Bob"), P(3, "Chloé")
local profs = {
	[A] = { inv = { gold = 1000, iron_ingot = 10 }, gear = { { slot = "weapon", name = "Épée signée", rarity = 3, stats = { force = 5 }, power = 6, maker = "Alice", makerId = 1 } } },
	[B] = { inv = { gold = 1000 }, gear = {} },
	[Cc] = { inv = { gold = 1000 }, gear = {} },
}
local G = {
	world = { day = 5, players = {} },
	Config = { ITEMS = { gold = {}, iron_ingot = { name = "Lingot de fer", icon = "🧱", price = 45 } } },
	Gear = { describe = function(g) return g.name end },
	Util = { root = function() return { Position = Vector3.zero } end, toast = function() end },
	Poste = { at = { [A] = Vector3.zero, [B] = Vector3.zero, [Cc] = Vector3.zero }, deliverSystem = function(uid, parcel) table.insert(mail, { uid, parcel }) end },
	Joueurs = {
		get = function(p) return profs[p] end,
		count = function(p, id) return profs[p].inv[id] or 0 end,
		take = function(p, id, n) n = n or 1 if (profs[p].inv[id] or 0) < n then return false end profs[p].inv[id] -= n return true end,
		add = function(p, id, n) profs[p].inv[id] = (profs[p].inv[id] or 0) + (n or 1) end,
		markDirty = function() end, sync = function() end, addSkillXp = function() end,
	},
	Economie = { record = function() end }, Mondes = { saveSoon = function() end },
	Interact = { onPrompt = function() end, onAction = function() end },
}
V.init(G)
V.open = function() end
local out, fails = {}, 0
local function check(c, msg)
	if not c then
		fails += 1
	end
	table.insert(out, (c and "OK    " or "ÉCHEC ") .. msg)
end
V.sell(A, { kind = "item", item = "iron_ingot", n = 10, price = 300, mode = "enchere", duree = 1 })
V.sell(A, { kind = "gear", idx = 1, name = "Épée signée", price = 500, mode = "fixe" })
check(#G.world.hdv == 2 and profs[A].inv.iron_ingot == 0 and #profs[A].gear == 0, "mise en vente : objets et pièce retirés du sac")
check(profs[A].inv.gold == 984, "frais de 2 % payés")
local auc, fix = G.world.hdv[1], G.world.hdv[2]
V.bid(B, { id = auc.id, amount = 200 })
check(auc.bid == nil, "offre sous le prix de départ refusée")
V.bid(B, { id = auc.id, amount = 300 })
check(auc.bid == 300 and profs[B].inv.gold == 700, "offre acceptée, or mis de côté")
V.bid(Cc, { id = auc.id, amount = 310 })
check(auc.bid == 300, "surenchère sous +5 % refusée")
V.bid(Cc, { id = auc.id, amount = 320 })
check(auc.bidder == 3 and mail[#mail][1] == 2 and mail[#mail][2].gold == 300, "enchérisseur dépassé remboursé par courrier")
V.cancel(A, { id = auc.id })
check(#G.world.hdv == 2, "pas de retrait d'une enchère qui a une offre")
V.buy(B, { id = fix.id, src = "hdv" })
check(#profs[B].gear == 1 and profs[B].inv.gold == 200, "achat à prix fixe d'une pièce")
check(V.renown(1) == 1, "renom de l'artisan : +1")
now += 2 * 3600 + 1
V.resolve()
local win, pay
for _, m in mail do
	if m[2].id == "win_" .. auc.id then win = m end
	if m[2].id == "pay_" .. auc.id then pay = m end
end
check(win and win[1] == 3 and win[2].items.iron_ingot == 10, "fin d'enchère : objet au gagnant par courrier")
check(pay and pay[1] == 1 and pay[2].gold == 320, "fin d'enchère : or au vendeur")
check(G.world.hdvHist.iron_ingot[1] == 32, "prix de référence enregistré")
-- même pièce revendue en boucle : le renom ne monte qu'une fois
local seller, buyer = B, A
for _ = 1, 4 do
	V.sell(seller, { kind = "gear", idx = 1, name = "Épée signée", price = 50, mode = "fixe" })
	V.buy(buyer, { id = G.world.hdv[#G.world.hdv].id, src = "hdv" })
	seller, buyer = buyer, seller
end
check(V.renown(1) == 1, "revente en boucle : renom inchangé")
local r = game.ReplicatedStorage:FindFirstChild("HotelVentes")
if r then
	r:Destroy()
end
table.insert(out, 1, string.format("Banc ventes : %d échec(s)", fails))
return table.concat(out, "\n")
