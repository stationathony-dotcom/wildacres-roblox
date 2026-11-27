-- Contrats entre joueurs (27/11) : la FENÊTRE des commandes entre joueurs qui existaient déjà en chat
-- (/commande, /commandes, /livrer, /annuler dans Systemes/Admin). MÊME stockage (G.world.extra.commandes =
-- { n, list = { ["n°"] = { buyer, name, item, n, price, day } } }) : un seul système, deux façons de s'en servir.
--   · « contrat_publier » { item, n, prix } : l'or est mis de côté tout de suite ;
--   · « contrat_livrer » { id } : le livreur donne les objets, reçoit l'or ; les objets partent par la poste ;
--   · « contrat_retirer » { id } : l'or revient (par la poste, comme /annuler) ;
--   · nouveau : au bout de Contrats.DAYS jours sans livreur, la commande expire et l'or revient par la poste.
-- Pas de plafond (règle 2) : seul l'or limite.

local Contrats = {}
local G

Contrats.DAYS = 7

local function orders()
	G.world.extra = G.world.extra or {}
	G.world.extra.commandes = G.world.extra.commandes or { n = 0, list = {} }
	return G.world.extra.commandes
end

function Contrats.publish(player: Player, item: any, n: any, prix: any): (boolean, string)
	local info = type(item) == "string" and G.Config.ITEMS[item]
	n, prix = math.floor(tonumber(n) or 0), math.floor(tonumber(prix) or 0)
	if not info or item == "gold" then
		return false, "Objet inconnu."
	end
	if n < 1 or n > 9999 or prix < 1 or prix > 1000000 then
		return false, "Quantité ou prix invalide."
	end
	if not G.Joueurs.take(player, "gold", prix) then
		return false, "Il te faut " .. prix .. " 💰 à mettre de côté."
	end
	local o = orders()
	o.n += 1
	o.list[tostring(o.n)] = { buyer = player.UserId, name = player.DisplayName, item = item, n = n, price = prix, day = G.world.day }
	G.Economie.record(player, "commande", "#" .. o.n .. " " .. n .. " " .. item .. " (-" .. prix .. " bloqués)")
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	return true, "📦 Commande n°" .. o.n .. " : " .. n .. " " .. info.name .. " contre " .. prix .. " 💰."
end

function Contrats.deliver(player: Player, id: any): (boolean, string)
	local o = orders()
	id = tostring(id)
	local c = o.list[id]
	if not c then
		return false, "Cette commande n'existe plus."
	end
	if c.buyer == player.UserId then
		return false, "C'est ta propre commande."
	end
	if G.Joueurs.count(player, c.item) < c.n then
		local info = G.Config.ITEMS[c.item]
		return false, "Il te faut " .. c.n .. " " .. (info and info.name or c.item) .. "."
	end
	o.list[id] = nil -- retirée AVANT de payer : personne d'autre ne peut la livrer
	G.Joueurs.take(player, c.item, c.n)
	G.Joueurs.add(player, "gold", c.price, true)
	G.Poste.deliverSystem(c.buyer, { from = player.DisplayName, items = { [c.item] = c.n } })
	G.Economie.record(player, "livraison", "#" .. id .. " pour " .. c.buyer .. " (+" .. c.price .. ")")
	G.Joueurs.addSkillXp(player, "commerce", 3)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	return true, "📦 Livré ! +" .. c.price .. " 💰. La marchandise part par la poste."
end

function Contrats.withdraw(player: Player, id: any): (boolean, string)
	local o = orders()
	id = tostring(id)
	local c = o.list[id]
	if not c or c.buyer ~= player.UserId then
		return false, "Cette commande n'est pas la tienne."
	end
	o.list[id] = nil
	G.Poste.deliverSystem(c.buyer, { from = "Commande annulée", gold = c.price })
	return true, "Commande n°" .. id .. " annulée : " .. c.price .. " 💰 te reviennent par courrier."
end

function Contrats.list()
	local out = {}
	for id, c in orders().list do
		local info = G.Config.ITEMS[c.item]
		table.insert(out, { id = id, name = c.name, uid = c.buyer, item = c.item, label = info and info.name or c.item, icon = info and info.icon,
			n = c.n, prix = c.price, reste = math.max(0, (c.day or G.world.day) + Contrats.DAYS - G.world.day) })
	end
	table.sort(out, function(a, b)
		return a.prix > b.prix
	end)
	return out
end

function Contrats.newDay()
	local o = orders()
	for id, c in o.list do
		if G.world.day >= (c.day or G.world.day) + Contrats.DAYS then
			o.list[id] = nil
			local info = G.Config.ITEMS[c.item]
			G.Poste.deliverSystem(c.buyer, { from = "Commande expirée (" .. (info and info.name or c.item) .. ")", gold = c.price })
		end
	end
end

function Contrats.init(g)
	G = g
	local function act(fn, a, b, c)
		return function(player, data)
			if type(data) ~= "table" then
				return
			end
			local ok, msg = fn(player, data[a], b and data[b], c and data[c])
			G.Util.toast(player, msg, ok and "gain" or nil)
			G.remotes.Menu:FireClient(player, { kind = "contrats", contrats = Contrats.list() })
		end
	end
	G.Interact.onAction("contrat_publier", act(Contrats.publish, "item", "n", "prix"))
	G.Interact.onAction("contrat_livrer", act(Contrats.deliver, "id"))
	G.Interact.onAction("contrat_retirer", act(Contrats.withdraw, "id"))
	G.Interact.onAction("contrats", function(player)
		G.remotes.Menu:FireClient(player, { kind = "contrats", contrats = Contrats.list() })
	end)
end

return Contrats
