-- Contrats entre joueurs (27/11, MANQUES-MMO n° 2 « contrats publiés par les joueurs », n° 1 « commandes
-- entre joueurs »). Tout se passe AU VILLAGE (Quetes.nearVillage), au tableau, jamais à distance :
--   · « contrat_publier » { item, n, prix } : l'or est mis de côté tout de suite (pas de contrat sans fonds) ;
--   · « contrat_livrer » { id } : le livreur donne les objets, reçoit l'or ; les objets partent par la poste
--     au commanditaire (Poste.deliverSystem : même hors ligne, même dans un autre monde) ;
--   · « contrat_retirer » { id } : le commanditaire reprend son or ;
--   · au bout de Contrats.DAYS jours sans livreur, l'or revient par la poste.
-- Pas de plafond (règle 2) : seul l'or limite. État : G.world.extra.contrats = { id -> contrat }.

local HttpService = game:GetService("HttpService")

local Contrats = {}
local G

Contrats.DAYS = 7

local function all()
	G.world.extra = G.world.extra or {}
	G.world.extra.contrats = G.world.extra.contrats or {}
	return G.world.extra.contrats
end

local function here(player: Player)
	return G.Quetes and rawget(G.Quetes, "nearVillage") and G.Quetes.nearVillage(player)
end

function Contrats.publish(player: Player, item: any, n: any, prix: any): (boolean, string)
	local info = type(item) == "string" and G.Config.ITEMS[item]
	n, prix = math.floor(tonumber(n) or 0), math.floor(tonumber(prix) or 0)
	if not info or item == "gold" then
		return false, "Objet inconnu."
	end
	if n < 1 or n > 10000 or prix < 1 or prix > 10000000 then
		return false, "Quantité ou prix invalide."
	end
	local v = here(player)
	if not v then
		return false, "Un contrat se publie au tableau d'un village."
	end
	if not G.Joueurs.take(player, "gold", prix) then
		return false, "Il te faut " .. prix .. " 💰 à mettre de côté."
	end
	local id = "ct" .. HttpService:GenerateGUID(false)
	all()[id] = { id = id, uid = player.UserId, name = player.DisplayName, item = item, n = n, prix = prix, village = v.key, vname = v.name, day = G.world.day }
	G.Economie.record(player, "contrat_publie", n .. " " .. item .. " pour " .. prix)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	return true, "📜 Contrat affiché : " .. n .. " " .. info.name .. " contre " .. prix .. " 💰."
end

function Contrats.deliver(player: Player, id: any): (boolean, string)
	local c = type(id) == "string" and all()[id]
	if not c then
		return false, "Ce contrat n'existe plus."
	end
	if c.uid == player.UserId then
		return false, "C'est ton propre contrat."
	end
	if not here(player) then
		return false, "On livre un contrat au tableau d'un village."
	end
	if G.Joueurs.count(player, c.item) < c.n then
		return false, "Il te faut " .. c.n .. " " .. G.Config.ITEMS[c.item].name .. "."
	end
	all()[id] = nil -- retiré AVANT de payer : impossible de livrer deux fois
	G.Joueurs.take(player, c.item, c.n)
	G.Joueurs.add(player, "gold", c.prix, true)
	G.Poste.deliverSystem(c.uid, { id = "ct_" .. id, from = "Contrat livré par " .. player.DisplayName, items = { [c.item] = c.n } })
	G.Economie.record(player, "contrat_livre", c.n .. " " .. c.item .. " -> " .. c.prix)
	G.Joueurs.addSkillXp(player, "commerce", 3)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	return true, "📜 Contrat rempli : +" .. c.prix .. " 💰. La marchandise part par la poste."
end

function Contrats.withdraw(player: Player, id: any): (boolean, string)
	local c = type(id) == "string" and all()[id]
	if not c or c.uid ~= player.UserId then
		return false, "Ce contrat n'est pas le tien."
	end
	all()[id] = nil
	G.Joueurs.add(player, "gold", c.prix, true)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	return true, "Contrat retiré : " .. c.prix .. " 💰 rendus."
end

function Contrats.list()
	local out = {}
	for _, c in all() do
		local info = G.Config.ITEMS[c.item]
		table.insert(out, { id = c.id, name = c.name, uid = c.uid, item = c.item, label = info and info.name or c.item, icon = info and info.icon,
			n = c.n, prix = c.prix, vname = c.vname, reste = math.max(0, c.day + Contrats.DAYS - G.world.day) })
	end
	table.sort(out, function(a, b)
		return a.prix > b.prix
	end)
	return out
end

function Contrats.newDay()
	for id, c in all() do
		if G.world.day >= c.day + Contrats.DAYS then
			all()[id] = nil
			G.Poste.deliverSystem(c.uid, { id = "ctx_" .. id, from = "Contrat expiré (" .. (G.Config.ITEMS[c.item] and G.Config.ITEMS[c.item].name or c.item) .. ")", gold = c.prix })
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
			if ok then
				G.remotes.Menu:FireClient(player, { kind = "contrats", contrats = Contrats.list() })
			end
		end
	end
	G.Interact.onAction("contrat_publier", act(Contrats.publish, "item", "n", "prix"))
	G.Interact.onAction("contrat_livrer", act(Contrats.deliver, "id"))
	G.Interact.onAction("contrat_retirer", act(Contrats.withdraw, "id"))
	G.Interact.onAction("contrats", function(player)
		if not here(player) then
			G.Util.toast(player, "Les contrats s'affichent au tableau d'un village.")
			return
		end
		G.remotes.Menu:FireClient(player, { kind = "contrats", contrats = Contrats.list() })
	end)
end

return Contrats
