-- Ouvriers agricoles (19/11, « à ne pas oublier » : employer des PNJ, salaires) : un fermier de
-- village loue ses bras. Payé d'avance (WAGE or par jour et par ouvrier, DAYS jours par contrat),
-- chaque ouvrier arrose chaque matin jusqu'à CAPACITY cases bêchées et semées de son employeur, où
-- qu'elles soient sur l'île, même s'il n'est pas connecté. Pas de plafond : plus de champs = plus
-- d'ouvriers, c'est l'or qui limite. L'ouvrier ne récolte pas (la récolte reste au joueur).
-- État (monde) : G.world.extra.ouvriers[pid] = { n = ouvriers, til = dernier jour payé, from = village }

local Ouvriers = {}
local G

Ouvriers.WAGE = 15
Ouvriers.DAYS = 3
Ouvriers.CAPACITY = 40

function Ouvriers.init(g)
	G = g
end

local function book()
	G.world.extra = G.world.extra or {}
	G.world.extra.ouvriers = G.world.extra.ouvriers or {}
	return G.world.extra.ouvriers
end

-- embaucher un ouvrier de plus (ou prolonger) auprès du fermier e ; renvoie le texte de réponse
function Ouvriers.hire(player: Player, e): string
	local cost = Ouvriers.WAGE * Ouvriers.DAYS
	if not G.Joueurs.take(player, "gold", cost) then
		return "Mes gars ne travaillent pas pour rien : " .. cost .. " or pour " .. Ouvriers.DAYS .. " jours, payés d'avance."
	end
	local b = book()
	local pid = G.Util.pid(player)
	local c = b[pid]
	local day = G.world.day
	if c and c.til >= day then
		-- un ouvrier de plus : les jours restants de chacun sont rééquilibrés (rien n'est perdu)
		local left = (c.til - day + 1) * c.n + Ouvriers.DAYS
		c.n += 1
		c.til = day - 1 + math.ceil(left / c.n)
	else
		c = { n = 1, til = day + Ouvriers.DAYS - 1, from = e and e.data and e.data.name or "?" }
		b[pid] = c
	end
	G.Economie.record(player, "salaire", "ouvrier agricole (-" .. cost .. ")")
	G.Joueurs.sync(player)
	return string.format("Marché conclu. %d ouvrier(s) arroseront tes champs chaque matin jusqu'au jour %d (%d cases chacun).",
		c.n, c.til, Ouvriers.CAPACITY)
end

-- chaque matin, après la pousse (Farm.newDay) : les ouvriers arrosent
function Ouvriers.newDay()
	local b = book()
	local day = G.world.day
	local todo = {}
	for pid, c in b do
		if c.til < day then
			b[pid] = nil
			local p = G.Util.playerOf(pid)
			if p then
				G.Util.toast(p, "👨‍🌾 Le contrat de tes ouvriers est fini (un fermier de village en loue d'autres).")
			end
		else
			todo[pid] = { left = c.n * Ouvriers.CAPACITY, done = 0 }
		end
	end
	if not next(todo) then
		return
	end
	for _, rs in G.world.regions do
		for _, st in rs.tilled or {} do
			local t = st.crop and not st.watered and st.owner and todo[st.owner]
			if t and t.left > 0 then
				st.watered = true
				t.left -= 1
				t.done += 1
			end
		end
	end
	for pid, t in todo do
		local p = G.Util.playerOf(pid)
		if p and t.done > 0 then
			G.Util.toast(p, "👨‍🌾 Tes ouvriers ont arrosé " .. t.done .. " case(s) ce matin.")
		end
	end
	if G.Farm and rawget(G.Farm, "refreshAll") then
		G.Farm.refreshAll()
	end
end

function Ouvriers.describe(player: Player): string
	local c = book()[G.Util.pid(player)]
	if not c or c.til < G.world.day then
		return "Aucun ouvrier. (Un fermier de village en loue : " .. Ouvriers.WAGE .. " or par jour.)"
	end
	return string.format("👨‍🌾 %d ouvrier(s) jusqu'au jour %d : jusqu'à %d cases arrosées chaque matin.", c.n, c.til, c.n * Ouvriers.CAPACITY)
end

return Ouvriers
