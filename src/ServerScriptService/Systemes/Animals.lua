-- Bêtes de ferme : poules, vaches, moutons. Elles flânent dans leur enclos, donnent œufs, lait
-- et laine (ramasser ceux d'un fermier = vol). On peut en acheter (elles suivent le joueur
-- jusqu'à l'endroit où il les installe) ou en mener une avec un appât.

local Animals = {}
local G, Config
Animals.list = {}

function Animals.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("animal", function(player, prompt)
		Animals.collect(player, prompt:GetAttribute("Animal"))
	end)
	G.Interact.onPrompt("animal_lead", function(player, prompt)
		Animals.lead(player, prompt:GetAttribute("Animal"))
	end)
end

local function find(id: string)
	for _, a in Animals.list do
		if a.id == id then
			return a
		end
	end
	return nil
end

local function refreshPrompt(a)
	local k = Config.ANIMALS[a.kind]
	local ready = a.state.product
	local stolen = a.owner and not G.Util.isPlayerId(a.owner)
	a.prompt.Enabled = ready
	a.prompt.ActionText = Config.PRODUCT_VERB[k.product] .. (stolen and " (vol)" or "")
	if a.sparkle then
		a.sparkle.Enabled = ready
	end
	if a.leadPrompt then
		a.leadPrompt.ActionText = a.leader and "Laisser ici" or (G.Util.isPlayerId(a.owner) and "Mener" or "Appâter (vol)")
	end
end

local function spawn(reg, d, parent)
	local k = Config.ANIMALS[d.kind]
	local model = G.Util.clone(k.model)
	if not model then
		return
	end
	local st = reg.state.animals[d.id]
	if not st then
		st = { product = true, days = 0 }
		reg.state.animals[d.id] = st
	end
	st.kind = d.kind
	if st.gone then
		model:Destroy()
		return
	end
	local x, z = st.x or d.x, st.z or d.z
	local y = G.Util.groundY(x, z)
	local a = {
		id = d.id, kind = d.kind, k = k, reg = reg, model = model, state = st, owner = st.owner or d.owner,
		pos = Vector3.new(x, y, z), yaw = math.random() * 6.28, pen = d.pen, home = Vector3.new(x, y, z), t = 0, goal = nil,
	}
	model:SetAttribute("AnimalId", d.id)
	G.Util.tag(model, "Bete") -- empreintes côté client (Traces.client)
	model:PivotTo(CFrame.new(a.pos) * CFrame.Angles(0, a.yaw, 0))
	model.Parent = parent
	local base = model.PrimaryPart
	local anchor = G.Util.anchor(model, CFrame.new(a.pos + Vector3.new(0, 2.5, 0)), "Invite")
	a.prompt = G.Util.prompt(anchor, "animal", "", k.name, { data = { Animal = d.id }, dist = 8, hold = (a.owner and not G.Util.isPlayerId(a.owner)) and 0.6 or 0 })
	a.leadPrompt = G.Util.prompt(anchor, "animal_lead", "Mener", k.name, { data = { Animal = d.id }, dist = 8, key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonY, hold = 0.3 })
	local sp = Instance.new("Sparkles")
	sp.SparkleColor = Color3.fromRGB(255, 240, 160)
	sp.Parent = base
	a.sparkle = sp
	refreshPrompt(a)
	table.insert(Animals.list, a)
	table.insert(reg.animals, a)
	return a
end

function Animals.onRegionLoad(reg)
	local folder = Instance.new("Folder")
	folder.Name = "Betes"
	folder.Parent = reg.folder
	reg.animalFolder = folder
	reg.animals = {}
	for _, d in reg.plan.animals do
		spawn(reg, d, folder)
	end
	for _, d in reg.state.myAnimals do
		spawn(reg, d, folder)
	end
end

function Animals.onRegionUnload(reg)
	for _, a in reg.animals or {} do
		local i = table.find(Animals.list, a)
		if i then
			table.remove(Animals.list, i)
		end
		-- une bête menée hors de sa région reste où elle est
		a.state.x, a.state.z = math.floor(a.pos.X), math.floor(a.pos.Z)
	end
end

-- Plafond d'élevage par éleveur et par monde : de quoi tenir une vraie ferme, pas de quoi noyer le
-- serveur (chaque bête = un modèle animé + une ligne de sauvegarde du secteur).
local BREED_CHANCE = 0.35 -- par couple nourri la veille, chaque matin

function Animals.ownedBy(owner: string): number
	local n = 0
	for _, rs in G.world.regions do
		for _, st in rs.animals or {} do
			if st.owner == owner and not st.gone then
				n += 1
			end
		end
	end
	return n
end

-- Pas de plafond arbitraire (19/11, principe « limité par ses ressources ») : on loge autant de bêtes
-- qu'on a construit d'abris. Sans abri, de quoi démarrer (OWN_BASE) ; chaque abri posé en ajoute.
Animals.OWN_BASE = 8
Animals.SHELTER_ROOM = { henhouse = 6, stable = 6, sheepfold = 6, pigsty = 4, barn = 12 }
function Animals.capacity(owner: string): number
	local n = Animals.OWN_BASE
	for _, rs in G.world.regions do
		for _, d in rs.placed or {} do
			if d.owner == owner and Animals.SHELTER_ROOM[d.item] then
				n += Animals.SHELTER_ROOM[d.item]
			end
		end
	end
	return n
end

function Animals.canOwnMore(player: Player): boolean
	local pid = G.Util.pid(player)
	local cap = Animals.capacity(pid)
	if Animals.ownedBy(pid) >= cap then
		G.Util.toast(player, "Tes abris sont pleins (" .. cap .. " places). Construis un poulailler, une étable, une bergerie ou une grange pour loger plus de bêtes.")
		return false
	end
	return true
end

-- Nouvelle bête à soi dans une région (achat ou naissance)
local function addOwned(reg, kind: string, pos: Vector3, owner: string, pen)
	local d = { id = "m" .. reg.key .. "#" .. math.random(1, 1e9), kind = kind, x = pos.X, z = pos.Z, owner = owner, pen = pen }
	table.insert(reg.state.myAnimals, d)
	reg.state.animals[d.id] = { product = false, days = 0, owner = owner }
	return spawn(reg, d, reg.animalFolder)
end

-- Achat chez un fermier : la bête apparaît à côté du joueur et le suit
function Animals.buy(player: Player, kind: string)
	local root = G.Util.root(player)
	local reg = root and G.World.regionAt(root.Position)
	if not reg then
		return false
	end
	local pos = root.Position + root.CFrame.LookVector * 4
	local a = addOwned(reg, kind, pos, G.Util.pid(player))
	if a then
		a.leader = player
		refreshPrompt(a)
	end
	return true
end

function Animals.collect(player: Player, id: string)
	local a = find(id)
	if not a or not a.state.product then
		return
	end
	local k = a.k
	a.state.product = false
	a.state.days = 0
	local stolen = a.owner and not G.Util.owns(player, a.owner)
	if stolen then
		G.Law.crime(player, "theft", a.pos, a.owner)
		G.Npcs.remember(a.owner, "robbed")
	end
	local n = 1
	if math.random() < 0.05 * (G.Joueurs.stats(player).chance or 0) + 0.25 * G.Joueurs.talent(player, "eleveur") + 0.01 * G.Joueurs.skill(player, "elevage") then
		n = 2
	end
	n += (a.state.abri and 1 or 0) + (a.state.soin and 1 or 0)
	G.Joueurs.add(player, k.product, n)
	if not stolen and G.Quetes and rawget(G.Quetes, "note") then
		G.Quetes.note(player, "collecter", k.product, n)
	end
	G.Joueurs.addSkillXp(player, "elevage", 5)
	refreshPrompt(a)
end

-- Mener une bête (la sienne) ou l'appâter (celle d'un autre : vol)
function Animals.lead(player: Player, id: string)
	local a = find(id)
	if not a then
		return
	end
	if a.leader then
		if a.leader ~= player then
			return
		end
		a.leader = nil
		-- installée là où on la laisse : elle y reste
		a.home = a.pos
		a.pen = nil
		a.state.x, a.state.z = math.floor(a.pos.X), math.floor(a.pos.Z)
		-- laissée sur les terres d'un autre joueur : c'est un cadeau, elle est désormais à lui
		-- (on l'a menée jusque chez lui : le geste vaut consentement ; lui ne paie rien)
		local landOwner = G.Parcelles.at(a.pos)
		if landOwner and landOwner ~= a.owner and G.Util.owns(player, a.owner) then
			if Animals.ownedBy(landOwner) >= Animals.capacity(landOwner) then
				G.Util.toast(player, "Sa ferme est déjà pleine : il ne peut pas recevoir d'autre bête.")
			else
				a.owner = landOwner
				a.state.owner = landOwner
				G.Economie.record(player, "don_bete", a.kind .. " -> " .. landOwner)
				local other = G.Util.playerOf(landOwner)
				G.Util.toast(player, "🎁 Tu laisses " .. string.lower(a.k.name) .. " sur ses terres : elle est à lui désormais.", "gain")
				if other then
					G.Util.toast(other, "🎁 " .. player.DisplayName .. " t'a offert : " .. a.k.name .. " (sur ta parcelle).", "big")
				end
			end
		end
		refreshPrompt(a)
		return
	end
	if not G.Util.owns(player, a.owner) then
		local bait = ({ chicken = "seed_parsnip", cow = "fiber", sheep = "fiber" })[a.kind]
		local baitName = ({ chicken = "des graines", cow = "de la fibre (herbe)", sheep = "de la fibre (herbe)" })[a.kind]
		local has = G.Joueurs.has(player, bait)
		if a.kind == "chicken" and not has then
			for _, crop in Config.CROP_ORDER do
				if G.Joueurs.has(player, "seed_" .. crop) then
					bait = "seed_" .. crop
					has = true
					break
				end
			end
		end
		if not has then
			G.Util.toast(player, "Il te faut un appât : " .. baitName .. ".")
			return
		end
		G.Joueurs.take(player, bait, 1)
		if a.owner then
			G.Law.crime(player, "theft", a.pos, a.owner)
			G.Npcs.remember(a.owner, "robbed")
		end
		-- elle change de propriétaire
		a.owner = G.Util.pid(player)
		a.state.owner = a.owner
	end
	a.leader = player
	G.Util.toast(player, a.k.name .. " te suit. Appuie de nouveau [R] pour l'installer quelque part.")
	refreshPrompt(a)
end

function Animals.hit(a, player: Player)
	-- on ne tue pas les bêtes : elles s'enfuient un peu
	local root = G.Util.root(player)
	if root then
		local away = a.pos - root.Position
		away = Vector3.new(away.X, 0, away.Z)
		if away.Magnitude > 0.1 then
			a.goal = a.pos + away.Unit * 10
			a.t = 0
		end
	end
	if a.owner and not G.Util.owns(player, a.owner) then
		G.Law.crime(player, "theft", a.pos, a.owner)
	end
end

local function inPen(a, p: Vector3): boolean
	local pen = a.pen
	if not pen then
		return (p - a.home).Magnitude < 10
	end
	return p.X > pen[1] and p.X < pen[3] and p.Z > pen[2] and p.Z < pen[4]
end

local acc = 0
function Animals.step(dt: number)
	acc += dt
	if acc < 1 / 20 then
		return
	end
	local step = acc
	acc = 0
	for i = #Animals.list, 1, -1 do
		local a = Animals.list[i]
		if not a.model.Parent then
			table.remove(Animals.list, i)
		else
			-- niveau de détail : une bête loin de tout joueur bouge par grands pas, rarement
			local dtA = step
			if not a.leader then
				local d = G.Util.playerDist(a.pos)
				local iv = d < 120 and 0 or (d < 300 and 0.25 or 1)
				a.lodAcc = (a.lodAcc or 0) + step
				if a.lodAcc < iv then
					continue
				end
				dtA = math.min(a.lodAcc, 1.5)
				a.lodAcc = 0
			end
			a.t += dtA
			local target
			local speed = a.k.speed
			if a.leader then
				local r = G.Util.root(a.leader)
				if not r or not a.leader.Parent then
					-- meneur parti / mort : la bête s'installe là où il l'a laissée (sinon, hors de son
					-- enclos d'origine, elle ne ferait plus un pas : inPen refuserait chaque mouvement)
					a.leader = nil
					a.home = a.pos
					a.pen = nil
					a.state.x, a.state.z = math.floor(a.pos.X), math.floor(a.pos.Z)
					refreshPrompt(a)
				elseif (r.Position - a.pos).Magnitude > 5 then
					target = r.Position
					speed = 14
				end
			else
				if not a.goal or a.t > 5 then
					a.t = 0
					local g = a.home + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
					if inPen(a, g) then
						a.goal = g
					end
				end
				target = a.goal
			end
			if target then
				local d = Vector3.new(target.X - a.pos.X, 0, target.Z - a.pos.Z)
				local moved = false
				if d.Magnitude > 0.5 then
					local np = a.pos + d.Unit * math.min(d.Magnitude, speed * dtA)
					if not G.Util.isWater(np.X, np.Z) and (a.leader or inPen(a, np)) then
						local ny = G.Util.groundY(np.X, np.Z)
						if math.abs(ny - a.pos.Y) < 4 or a.leader then
							a.pos = Vector3.new(np.X, ny, np.Z)
							a.yaw = math.atan2(-d.X, -d.Z)
							moved = true
						end
					else
						a.goal = nil
					end
				end
				-- dandinement seulement en marche ; immobile, on ne renvoie rien sur le réseau
				if moved or a.wasMoving then
					local bob = moved and math.abs(math.sin(os.clock() * 8)) * 0.15 or 0
					a.model:PivotTo(CFrame.new(a.pos + Vector3.new(0, bob, 0)) * CFrame.Angles(0, a.yaw, 0))
				end
				a.wasMoving = moved
			end
		end
	end
end

-- Nourriture animale : la bête la plus proche (à soi) produit un jour plus tôt (une fois par jour)
function Animals.feedNear(player: Player): boolean
	local root = G.Util.root(player)
	if not root then
		return false
	end
	local best, bd = nil, 10
	for _, a in Animals.list do
		local d = (a.pos - root.Position).Magnitude
		if d < bd and a.owner and G.Util.owns(player, a.owner) and a.state.fedDay ~= G.world.day then
			best, bd = a, d
		end
	end
	if not best then
		return false
	end
	best.state.fedDay = G.world.day
	best.state.days = (best.state.days or 0) + 1
	if best.state.days >= best.k.every then
		best.state.product = true
	end
	refreshPrompt(best)
	G.Util.toast(player, "🌾 " .. best.k.name .. " mange de bon cœur (produit plus vite).", "gain")
	return true
end

-- Clochette : toutes ses bêtes à portée d'oreille (120 studs) suivent le joueur
function Animals.gather(player: Player): number
	local root = G.Util.root(player)
	if not root then
		return 0
	end
	local n = 0
	for _, a in Animals.list do
		if a.owner and G.Util.owns(player, a.owner) and not a.leader and (a.pos - root.Position).Magnitude < 120 then
			a.leader = player
			refreshPrompt(a)
			n += 1
		end
	end
	return n
end

-- Reproduction : chaque matin, deux bêtes de même espèce, au même éleveur, dans la même région
-- et NOURRIES LA VEILLE forment un couple ; chaque couple a BREED_CHANCE de donner un petit à côté
-- d'un parent (dans son enclos). Plafond par éleveur : jamais de prolifération (bêtes sauvages et
-- des PNJ ne se reproduisent pas ; régions déchargées non plus).
local function breed()
	local groups = {}
	for _, a in Animals.list do
		local o = a.owner
		if o and G.Util.isPlayerId(o) and not a.state.gone and a.state.fedDay == G.world.day - 1 then
			local key = o .. "|" .. a.kind .. "|" .. a.reg.key
			groups[key] = groups[key] or {}
			table.insert(groups[key], a)
		end
	end
	local born = 0
	for _, list in groups do
		for i = 1, #list - 1, 2 do
			local parent = list[i]
			if math.random() < BREED_CHANCE and Animals.ownedBy(parent.owner) < Animals.capacity(parent.owner) then
				local pos = parent.pos + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
				if addOwned(parent.reg, parent.kind, pos, parent.owner, parent.pen) then
					born += 1
					local pl = G.Util.playerOf(parent.owner)
					if pl then
						G.Util.toast(pl, "🐣 Une naissance à la ferme : un petit " .. string.lower(parent.k.name) .. " !", "gain")
					end
				end
			end
		end
	end
	return born
end
Animals.breed = breed -- pour les tests (DbgAppel)

function Animals.newDay()
	breed()
	for _, rs in G.world.regions do
		for _, st in rs.animals or {} do
			st.days = (st.days or 0) + 1
		end
	end
	-- bien soignées (abreuvoir ET mangeoire à moins de 24 studs) : un jour d'avance chaque matin
	local troughs, feeders = {}, {}
	-- abris (18/11) : une bête près de SON abri produit aussi un jour plus tôt
	local SHELTER = { Cat_henhouse = { chicken = true }, Cat_stable = { cow = true, sheep = true }, Cat_sheepfold = { sheep = true } }
	local shelters = {}
	for _, reg in G.World.loaded do
		for _, m in reg.placedModels or {} do
			if m.Parent and m.Name == "Abreuvoir" then
				table.insert(troughs, m:GetPivot().Position)
			elseif m.Parent and m.Name == "Mangeoire" then
				table.insert(feeders, m:GetPivot().Position)
			elseif m.Parent and SHELTER[m.Name] then
				table.insert(shelters, { pos = m:GetPivot().Position, kinds = SHELTER[m.Name] })
			end
		end
	end
	local function sheltered(a): boolean
		for _, sh in shelters do
			if sh.kinds[a.kind] and (sh.pos - a.pos).Magnitude < 20 then
				return true
			end
		end
		return false
	end
	local function near(list, pos)
		for _, p in list do
			if (p - pos).Magnitude < 24 then
				return true
			end
		end
		return false
	end
	for _, a in Animals.list do
		local cared = a.pos ~= nil and #troughs > 0 and #feeders > 0 and near(troughs, a.pos) and near(feeders, a.pos)
		if cared then
			a.state.days += 1
		end
		-- soins comptés à la récolte : +1 produit à l'abri, +1 bien nourrie pour une bête qui produit
		-- chaque jour (pour elle, « un jour d'avance » ne changeait rien)
		a.state.abri = (a.pos ~= nil and #shelters > 0 and sheltered(a)) or nil
		a.state.soin = (cared and a.k.every <= 1) or nil
		if a.state.days >= a.k.every then
			a.state.product = true
		end
		refreshPrompt(a)
	end
	for _, rs in G.world.regions do
		for _, st in rs.animals or {} do
			-- régions déchargées : le produit est prêt au prochain passage
			local k = st.kind and Config.ANIMALS[st.kind]
			if k and (st.days or 0) >= k.every then
				st.product = true
			end
		end
	end
end

return Animals
