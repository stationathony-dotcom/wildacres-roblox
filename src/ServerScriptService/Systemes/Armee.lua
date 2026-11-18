-- Armée façon Warcraft, volontairement dure mais SANS plafond arbitraire : on est limité par ses
-- ressources. Une caserne sur SA parcelle forme une recrue après l'autre (plus de casernes = plus vite),
-- chaque recrue coûte de l'or et de la nourriture, la solde de toute l'armée est due chaque matin
-- (2 jours impayés = un déserteur) et un soldat mort ne revient pas. Ordres : « me suivre » / « garder ici ».

local Armee = {}
local G, Config

function Armee.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("barracks", function(player, prompt)
		Armee.open(player, prompt:GetAttribute("Placed"))
	end)
	G.Interact.onAction("recruit", function(player, data)
		Armee.recruit(player, data.id, data.unit)
	end)
	G.Interact.onPrompt("barracks_equip", function(player, prompt)
		Armee.equip(player, prompt:GetAttribute("Placed"))
	end)
end

-- soldats actuels + en formation
local function strength(player: Player, d): (number, number)
	local n = 0
	local rec = G.Mondes.playerRecord(player)
	for _, pet in rec.pets or {} do
		if Config.UNITS[pet.kind] then
			n += 1
		end
	end
	local queued = 0
	for _, q in (d and d.queue) or {} do
		queued += 1
		local _ = q
	end
	return n, queued
end

local function wages(player: Player): number
	local total = 0
	local rec = G.Mondes.playerRecord(player)
	for _, pet in rec.pets or {} do
		local u = Config.UNITS[pet.kind]
		if u then
			total += u.wage
		end
	end
	return total
end

local function send(player: Player, d)
	local n, queued = strength(player, d)
	local queue = {}
	for _, q in d.queue or {} do
		table.insert(queue, { name = Config.UNITS[q.unit].name, left = math.max(0, q.ready - os.time()) })
	end
	local units = {}
	for _, id in Config.UNIT_ORDER do
		local u = Config.UNITS[id]
		local cost = {}
		for item, k in u.cost do
			table.insert(cost, (Config.ITEMS[item] and Config.ITEMS[item].icon or "") .. " " .. k)
		end
		table.insert(units, { id = id, name = u.name, desc = u.desc, cost = table.concat(cost, "  "), wage = u.wage, train = u.train, hp = u.hp, dmg = u.dmg })
	end
	G.remotes.Menu:FireClient(player, {
		kind = "barracks", id = d.id, units = units, queue = queue, count = n, queued = queued, wages = wages(player),
	})
end

-- Recrues formées : elles sortent de la caserne (même si le propriétaire était absent)
local function deliver(d, reg)
	if not d.queue or #d.queue == 0 then
		return
	end
	local now = os.time()
	local keep = {}
	for _, q in d.queue do
		if q.ready <= now then
			G.Compagnons.enlist(d.owner, q.unit, Vector3.new(d.x + math.random(-4, 4), 0, d.z + 6))
		else
			table.insert(keep, q)
		end
	end
	d.queue = keep
	local _ = reg
end

function Armee.open(player: Player, id: string)
	local d, reg = G.Protection.findPlaced(id)
	if not d or d.item ~= "barracks" then
		return
	end
	if not G.Util.owns(player, d.owner) then
		G.Util.toast(player, "Ce n'est pas ta caserne.")
		return
	end
	deliver(d, reg)
	send(player, d)
end

-- Équiper l'armée (18/11) : 1 lingot de fer + 1 cuir par soldat pas encore équipé → +25 % de
-- dégâts, −20 % de dégâts reçus (Compagnons) ; à la caserne, autant de soldats qu'on peut payer
function Armee.equip(player: Player, id: string?)
	local d = id and G.Protection.findPlaced(id)
	if not d or d.item ~= "barracks" or not G.Util.owns(player, d.owner) then
		return
	end
	local rec = G.Mondes.playerRecord(player)
	local n, done = 0, 0
	for _, pet in (rec and rec.pets) or {} do
		if Config.UNITS[pet.kind] and not pet.equip then
			n += 1
			if G.Joueurs.count(player, "iron_ingot") >= 1 and G.Joueurs.count(player, "leather") >= 1 then
				G.Joueurs.take(player, "iron_ingot", 1)
				G.Joueurs.take(player, "leather", 1)
				pet.equip = true
				done += 1
			end
		end
	end
	if n == 0 then
		G.Util.toast(player, "⚔️ Tous tes soldats sont déjà équipés.")
	elseif done == 0 then
		G.Util.toast(player, "⚔️ Il faut 1 lingot de fer et 1 cuir par soldat.")
	else
		G.Util.toast(player, "⚔️ " .. done .. " soldat(s) équipé(s) de fer et de cuir" .. (done < n and (" (" .. (n - done) .. " attendent encore)") or "") .. ".", "gain")
		G.Joueurs.sync(player)
	end
end

function Armee.recruit(player: Player, id: string, unit: string)
	local d, reg = G.Protection.findPlaced(id)
	local u = type(unit) == "string" and Config.UNITS[unit]
	if not d or d.item ~= "barracks" or not u or not G.Util.owns(player, d.owner) then
		return
	end
	local root = G.Util.root(player)
	if not root or (Vector3.new(d.x, root.Position.Y, d.z) - root.Position).Magnitude > 20 then
		return
	end
	for item, k in u.cost do
		if G.Joueurs.count(player, item) < k then
			G.Util.toast(player, "Il manque : " .. Config.needInfo(item).name .. " (" .. k .. ").")
			return
		end
	end
	for item, k in u.cost do
		G.Joueurs.take(player, item, k)
	end
	d.queue = d.queue or {}
	-- une recrue après l'autre : elle commence quand la précédente a fini
	local start = os.time()
	for _, q in d.queue do
		start = math.max(start, q.ready)
	end
	table.insert(d.queue, { unit = unit, ready = start + u.train })
	G.Util.toast(player, "⚔️ " .. u.name .. " en formation (prête dans " .. math.ceil((start + u.train - os.time()) / 60) .. " min).", "gain")
	G.Economie.record(player, "armee", "recrue " .. unit)
	G.Joueurs.sync(player)
	send(player, d)
	local _ = reg
end

-- Chaque matin : la solde (un soldat impayé deux jours de suite déserte)
function Armee.newDay()
	for _, player in G.Game.players() do
		local total = wages(player)
		if total > 0 then
			local rec = G.Mondes.playerRecord(player)
			if G.Joueurs.take(player, "gold", total) then
				rec.unpaid = 0
				G.Util.toast(player, "⚔️ Solde de l'armée : -" .. total .. " 💰")
			else
				rec.unpaid = (rec.unpaid or 0) + 1
				if rec.unpaid >= 2 then
					rec.unpaid = 0
					local deserter = G.Compagnons.dismissOne(player)
					G.Util.toast(player, "💸 Solde impayée : " .. (deserter or "un soldat") .. " déserte !", "danger")
				else
					G.Util.toast(player, "💸 Pas assez d'or pour la solde (" .. total .. ") : demain, un soldat désertera.", "danger")
				end
			end
			G.Joueurs.sync(player)
		end
	end
end

-- Les casernes chargées libèrent les recrues formées
local acc = 0
function Armee.step(dt: number)
	acc += dt
	if acc < 5 then
		return
	end
	acc = 0
	for _, reg in G.World.loaded do
		for _, d in reg.state.placed do
			if d.item == "barracks" and d.queue and #d.queue > 0 then
				deliver(d, reg)
			end
		end
	end
end

return Armee
