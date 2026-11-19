-- Cultures : bêcher (houe), semer (graines de saison), arroser (arrosoir), récolter.
-- Une culture arrosée gagne un stade par nuit ; hors saison elle flétrit ; l'hiver rien ne pousse.
-- Les champs des fermiers et les plants sauvages suivent les mêmes règles (récolter ceux d'un
-- fermier = vol).

local Debris = game:GetService("Debris")

local Farm = {}
local G
local Config
local CELL

local cells = {} -- "cx,cz" -> {reg, kind="tilled"|"plot", id, model}

function Farm.init(g)
	G = g
	Config = G.Config
	CELL = Config.CELL
	G.Interact.onPrompt("crop", function(player, prompt)
		Farm.harvest(player, prompt:GetAttribute("Cell"))
	end)
end

local function cellKey(cx: number, cz: number): string
	return cx .. "," .. cz
end

-- ----------------------------------------------------------------- Visuels

local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Plant procédural selon la culture et le stade (0 = semis, days = mûr)
local function makePlant(parent: Model, base: CFrame, cropId: string, stage: number, withered: boolean?)
	local crop = Config.CROPS[cropId]
	if not crop then
		return
	end
	local t = math.clamp(stage / crop.days, 0, 1)
	local ripe = stage >= crop.days
	local leaf = withered and Color3.fromRGB(140, 120, 70) or Color3.fromRGB(90, 160, 64)
	local h = 0.4 + 1.4 * t
	if crop.shape == "wheat" then
		for i = -1, 1 do
			for j = -1, 1, 2 do
				local col = ripe and crop.color or leaf
				part(parent, "Tige", Vector3.new(0.18, h * 1.4, 0.18), base * CFrame.new(i * 0.9, h * 0.7 + 0.3, j * 0.7), col)
				if ripe then
					part(parent, "Epi", Vector3.new(0.35, 0.8, 0.35), base * CFrame.new(i * 0.9, h * 1.4 + 0.6, j * 0.7), crop.color:Lerp(Color3.new(1, 1, 1), 0.1))
				end
			end
		end
		return
	end
	part(parent, "Tige", Vector3.new(0.25, h, 0.25), base * CFrame.new(0, h / 2 + 0.3, 0), leaf)
	if stage >= 1 then
		local s = 0.5 + 0.9 * t
		part(parent, "Feuille", Vector3.new(s, 0.15, s * 0.45), base * CFrame.new(s * 0.4, h * 0.6 + 0.3, 0) * CFrame.Angles(0, 0, math.rad(25)), leaf)
		part(parent, "Feuille", Vector3.new(s, 0.15, s * 0.45), base * CFrame.new(-s * 0.4, h * 0.5 + 0.3, 0) * CFrame.Angles(0, 0, math.rad(-25)), leaf)
		part(parent, "Feuille", Vector3.new(s * 0.45, 0.15, s), base * CFrame.new(0, h * 0.7 + 0.3, s * 0.4) * CFrame.Angles(math.rad(-25), 0, 0), leaf)
	end
	if ripe and not withered then
		if crop.shape == "root" then
			part(parent, "Fruit", Vector3.new(0.9, 0.7, 0.9), base * CFrame.new(0, 0.45, 0), crop.color)
		elseif crop.shape == "big" then
			local f = part(parent, "Fruit", Vector3.new(2, 1.6, 2), base * CFrame.new(0.4, 0.9, 0.5), crop.color)
			f.Shape = Enum.PartType.Ball
		else -- bush
			for _, o in { Vector3.new(0.45, h * 0.7, 0.2), Vector3.new(-0.4, h * 0.55, -0.3), Vector3.new(0.1, h * 0.9, -0.45) } do
				part(parent, "Fruit", Vector3.new(0.6, 0.6, 0.6), base * CFrame.new(o + Vector3.new(0, 0.3, 0)), crop.color)
			end
		end
	end
end

-- Ce qui se voit d'une case : si rien n'a changé, inutile de la reconstruire
local function look(entry): string
	local st = entry.state
	return tostring(st.crop) .. "|" .. tostring(st.stage) .. "|" .. tostring(st.watered) .. "|" .. tostring(st.withered)
end

-- Construit (ou reconstruit) la case cultivée
local function render(entry)
	if entry.model then
		entry.model:Destroy()
	end
	entry.look = look(entry)
	local st = entry.state
	local model = G.Util.clone("Sol_Laboure")
	if not model then
		return
	end
	model.Name = "Culture"
	local y = G.Util.groundY(entry.x, entry.z) - 0.1
	G.World.place(model, entry.x, y, entry.z, 0, entry.reg.farmFolder)
	if st.watered then
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				p.Color = p.Color:Lerp(Color3.fromRGB(40, 28, 20), 0.45)
			end
		end
	end
	if st.crop then
		makePlant(model, CFrame.new(entry.x, y + 0.2, entry.z), st.crop, st.stage or 0, st.withered)
		local crop = Config.CROPS[st.crop]
		if (st.stage or 0) >= crop.days and not st.withered then
			local owner = entry.owner
			local npcOwned = owner and owner ~= "wild" and not G.Util.isPlayerId(owner)
			local text = npcOwned and "Voler la récolte" or "Récolter"
			local object = crop.name
			local ownerPlayer = G.Util.playerOf(owner)
			if ownerPlayer then
				object ..= " de " .. ownerPlayer.DisplayName -- récolter celle d'un autre joueur = vol
			end
			local a = G.Util.anchor(model, CFrame.new(entry.x, y + 1.5, entry.z), "Invite")
			G.Util.prompt(a, "crop", text, object, { data = { Cell = entry.key }, dist = 7, hold = npcOwned and 0.6 or 0 })
		elseif st.withered then
			local a = G.Util.anchor(model, CFrame.new(entry.x, y + 1.5, entry.z), "Invite")
			G.Util.prompt(a, "crop", "Arracher (flétri)", crop.name, { data = { Cell = entry.key }, dist = 7 })
		end
	end
	entry.model = model
end

function Farm.onRegionLoad(reg)
	local folder = Instance.new("Folder")
	folder.Name = "Cultures"
	folder.Parent = reg.folder
	reg.farmFolder = folder
	reg.farmKeys = {}
	-- champs des fermiers et plants sauvages
	for _, p in reg.plan.plots do
		local cx, cz = math.floor(p.x / CELL), math.floor(p.z / CELL)
		local key = cellKey(cx, cz)
		local st = reg.state.plots[p.id]
		if not st then
			st = { crop = p.crop, stage = p.stage, watered = false }
			reg.state.plots[p.id] = st
		end
		if not st.gone then
			local entry = { reg = reg, key = key, x = p.x, z = p.z, state = st, owner = p.owner, plotId = p.id }
			cells[key] = entry
			table.insert(reg.farmKeys, key)
			render(entry)
		end
	end
	task.wait()
	-- terre bêchée par le joueur
	for key, st in reg.state.tilled do
		local cx, cz = string.match(key, "(-?%d+),(-?%d+)")
		cx, cz = tonumber(cx), tonumber(cz)
		local x, z = cx * CELL + CELL / 2, cz * CELL + CELL / 2
		local entry = { reg = reg, key = key, x = x, z = z, state = st, owner = st.owner }
		cells[key] = entry
		table.insert(reg.farmKeys, key)
		render(entry)
	end
end

function Farm.onRegionUnload(reg)
	for _, key in reg.farmKeys or {} do
		cells[key] = nil
	end
end

-- Case visée : celle juste devant le joueur
function Farm.targetCell(player: Player): (number?, number?)
	local root = G.Util.root(player)
	if not root then
		return nil, nil
	end
	local look = root.CFrame.LookVector
	local p = root.Position + Vector3.new(look.X, 0, look.Z).Unit * 4.5
	return math.floor(p.X / CELL), math.floor(p.Z / CELL)
end

local function swing(player)
	local char = player.Character
	if char and char:FindFirstChildOfClass("Tool") then
		G.Props.swing(player) -- houe, arrosoir… : le coup de l'outil
	else
		G.Util.geste(player, "cueillir") -- semer, récolter à la main : on se penche
	end
end

local function dust(pos: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(pos)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(0.4, 0.1)
	e.Speed = NumberRange.new(4, 8)
	e.SpreadAngle = Vector2.new(50, 50)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Lifetime = NumberRange.new(0.3, 0.6)
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace
	e:Emit(12)
	Debris:AddItem(p, 1)
end

-- La case est-elle cultivable ? (terre ferme, plate, sans objet ni bâtiment dessus)
local function arable(cx: number, cz: number): (boolean, string?)
	local x, z = cx * CELL + CELL / 2, cz * CELL + CELL / 2
	local rx, rz = G.WG.regionOf(cx, cz)
	local reg = G.World.loaded[rx .. "," .. rz]
	if not reg then
		return false, nil
	end
	local plan = reg.plan
	local i = G.WG.idx(cx - plan.x0, cz - plan.z0)
	if plan.water[i] then
		return false, "On ne laboure pas l'eau."
	end
	local m = plan.mat[i]
	if m == Enum.Material.Cobblestone or m == Enum.Material.Sand then
		return false, "Cette terre ne se laboure pas."
	end
	local y = G.Util.groundY(x, z)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { workspace.Terrain }
	for _, p in game:GetService("Players"):GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local hits = workspace:GetPartBoundsInBox(CFrame.new(x, y + 1.5, z), Vector3.new(3.4, 2.4, 3.4), params)
	for _, h in hits do
		if h.CanCollide or h.Parent and h.Parent.Name ~= "Touffe" then
			return false, "Il y a quelque chose ici."
		end
	end
	return true, nil
end

function Farm.till(player: Player)
	local cx, cz = Farm.targetCell(player)
	if not cx then
		return
	end
	local key = cellKey(cx, cz)
	local entry = cells[key]
	swing(player)
	if entry then
		if not entry.plotId and not entry.state.crop and (not entry.owner or G.Util.owns(player, entry.owner)) then
			-- reboucher (seulement sa propre terre)
			entry.reg.state.tilled[key] = nil
			entry.model:Destroy()
			cells[key] = nil
		end
		return
	end
	local ok, why = arable(cx, cz)
	if not ok then
		if why then
			G.Util.toast(player, why)
		end
		return
	end
	local wx, wz = G.WG.center(cx, cz)
	if not G.Parcelles.canBuild(player, Vector3.new(wx, 0, wz)) then
		return
	end
	local rx, rz = G.WG.regionOf(cx, cz)
	local reg = G.World.loaded[rx .. "," .. rz]
	local st = { stage = 0, watered = false, owner = G.Util.pid(player) }
	reg.state.tilled[key] = st
	local x, z = cx * CELL + CELL / 2, cz * CELL + CELL / 2
	entry = { reg = reg, key = key, x = x, z = z, state = st, owner = st.owner }
	cells[key] = entry
	table.insert(reg.farmKeys, key)
	render(entry)
	dust(Vector3.new(x, G.Util.groundY(x, z) + 0.5, z), Color3.fromRGB(120, 85, 55))
end

function Farm.plant(player: Player, cropId: string)
	local cx, cz = Farm.targetCell(player)
	if not cx then
		return
	end
	local entry = cells[cellKey(cx, cz)]
	local crop = Config.CROPS[cropId]
	if not crop then
		return
	end
	if not entry or entry.plotId then
		G.Util.toast(player, "Bêche d'abord la terre avec la houe (case devant toi).")
		return
	end
	if entry.state.crop then
		G.Util.toast(player, "Quelque chose pousse déjà ici.")
		return
	end
	if (crop.skill or 0) > 0 and not G.Joueurs.needSkill(player, "agriculture", crop.skill, crop.name) then
		return
	end
	local x, z = G.WG.center(cx, cz)
	local biome = G.Clock.biomeAt(Vector3.new(x, 0, z))
	if not table.find(crop.biomes, biome) then
		local names = {}
		for _, b in crop.biomes do
			table.insert(names, Config.BIOMES[b].name)
		end
		G.Util.toast(player, crop.name .. " ne pousse pas ici (" .. Config.BIOMES[biome].name .. ") : essaie " .. table.concat(names, " ou ") .. ".")
		return
	end
	if not G.Joueurs.take(player, "seed_" .. cropId, 1) then
		return
	end
	entry.state.crop = cropId
	entry.state.stage = 0
	entry.state.withered = nil
	render(entry)
	if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "semer", "graine") end
end

function Farm.water(player: Player)
	local cx, cz = Farm.targetCell(player)
	if not cx then
		return
	end
	swing(player)
	local any = false
	local area = { { 0, 0 } }
	if G.Joueurs.talent(player, "arrosage") > 0 then
		area = { { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, -1 }, { 1, -1 }, { -1, 1 } }
	end
	for _, d in area do
		local entry = cells[cellKey(cx + d[1], cz + d[2])]
		if entry and not entry.state.watered then
			entry.state.watered = true
			render(entry)
			any = true
		end
	end
	local x, z = cx * CELL + CELL / 2, cz * CELL + CELL / 2
	dust(Vector3.new(x, G.Util.groundY(x, z) + 1, z), Color3.fromRGB(110, 170, 230))
	if not any and not cells[cellKey(cx, cz)] then
		G.Util.toast(player, "Arrose une case bêchée (devant toi).")
	end
end

-- Crue : les champs bêchés sous le niveau de l'eau sont arrosés ; au retrait, le limon les fait
-- pousser d'un cran. Renvoie les cases touchées (pour le limon).
function Farm.flood(center: Vector3, radius: number, level: number)
	local hit = {}
	for _, entry in cells do
		local x, z = entry.x, entry.z
		if x and (Vector3.new(x, 0, z) - Vector3.new(center.X, 0, center.Z)).Magnitude < radius and G.Util.groundY(x, z) < level then
			if entry.state and not entry.state.watered then
				entry.state.watered = true
				render(entry)
			end
			table.insert(hit, entry)
		end
	end
	return hit
end

function Farm.silt(entries)
	for _, entry in entries do
		local st = entry.state
		local crop = st and st.crop and Config.CROPS[st.crop]
		if crop and not st.withered and (st.stage or 0) < crop.days and cells[entry.key] == entry then
			st.stage = (st.stage or 0) + 1
			render(entry)
		end
	end
end

-- Engrais (os, compost…) : la culture devant soi pousse d'un cran tout de suite
function Farm.fertilize(player: Player, item: string?)
	local cx, cz = Farm.targetCell(player)
	local entry = cx and cells[cellKey(cx, cz)]
	local st = entry and entry.state
	if not st or not st.crop or st.withered then
		G.Util.toast(player, "Place-toi face à une culture pour l'engraisser.")
		return
	end
	local crop = Config.CROPS[st.crop]
	if (st.stage or 0) >= crop.days then
		G.Util.toast(player, "Elle est déjà mûre !")
		return
	end
	if not G.Joueurs.take(player, item or "bonemeal", 1) then
		return
	end
	st.stage = (st.stage or 0) + 1
	render(entry)
	local x, z = cx * CELL + CELL / 2, cz * CELL + CELL / 2
	dust(Vector3.new(x, G.Util.groundY(x, z) + 1, z), Color3.fromRGB(150, 230, 120))
	G.Joueurs.sync(player)
end

function Farm.dig(player: Player)
	local cx, cz = Farm.targetCell(player)
	if not cx then
		return
	end
	swing(player)
	local x, z = cx * CELL + CELL / 2, cz * CELL + CELL / 2
	dust(Vector3.new(x, G.Util.groundY(x, z) + 0.5, z), Color3.fromRGB(120, 85, 55))
	if math.random() < 0.12 then
		local finds = { "stone", "stone", "fiber", "ore" }
		G.Joueurs.add(player, finds[math.random(1, #finds)], 1)
	end
end

function Farm.harvest(player: Player, key: string)
	local entry = cells[key]
	if not entry or not entry.state.crop then
		return
	end
	local root = G.Util.root(player)
	if not root or (root.Position - Vector3.new(entry.x, root.Position.Y, entry.z)).Magnitude > 12 then
		return
	end
	local st = entry.state
	local crop = Config.CROPS[st.crop]
	if st.withered then
		st.crop = nil
		st.withered = nil
		st.stage = 0
		if entry.plotId then
			st.gone = true
			entry.model:Destroy()
			cells[key] = nil
		else
			render(entry)
		end
		return
	end
	if (st.stage or 0) < crop.days then
		return
	end
	local owner = entry.owner
	if owner and owner ~= "wild" and not G.Util.owns(player, owner) then
		G.Law.crime(player, "theft", Vector3.new(entry.x, root.Position.Y, entry.z), owner)
		G.Npcs.remember(owner, "robbed")
	end
	local n = 1
	local luck = G.Joueurs.stats(player).chance or 0
	local mine = owner == nil or G.Util.owns(player, owner) or owner == "wild"
	local prof = G.Joueurs.get(player)
	local sel = mine and Farm.selectionLevel(prof and prof.selection and prof.selection[st.crop]) or 0
	if math.random() < 0.1 + luck * 0.03 + 0.15 * G.Joueurs.talent(player, "main_verte") + 0.25 * G.Joueurs.talent(player, "terre_riche") + 0.01 * G.Joueurs.skill(player, "agriculture") + 0.06 * sel then
		n = 2
		if sel >= 3 and math.random() < 0.05 * sel then
			n = 3
		end
	end
	G.Joueurs.add(player, st.crop, n)
	if owner == nil or G.Util.owns(player, owner) or owner == "wild" then
		G.Joueurs.addSkillXp(player, "agriculture", 3 + (Config.CROPS[st.crop].days or 3))
		G.Social.collect(player, "crops", st.crop)
		Farm.noteSelection(player, st.crop)
		if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "recolter", st.crop, n) end
		if G.Activites.note then
			G.Activites.note(player, "recolte", n) -- concours de récolte (pas pour un vol)
		end
	end
	if math.random() < 0.3 then
		G.Joueurs.add(player, "seed_" .. st.crop, 1)
	end
	if entry.plotId then
		-- le fermier ressaisira : la case repart de zéro
		st.stage = 0
		st.harvestedDay = G.world.day
		if owner == "wild" then
			st.gone = true
			entry.model:Destroy()
			cells[key] = nil
			return
		end
	else
		st.crop = nil
		st.stage = 0
	end
	render(entry)
end

-- Sélection des semences (19/11, « à ne pas oublier » § 7 : variétés et amélioration des cultures) :
-- chaque culture qu'on récolte soi-même (pas un vol) gagne en sélection : niveau = √(récoltes / 10),
-- jusqu'à 5 (10, 40, 90, 160, 250 récoltes). Chaque niveau : +6 % de récoltes doubles ; dès le
-- niveau 3, des récoltes triples. Gardé par culture dans le profil (prof.selection).
Farm.SEL_MAX = 5
function Farm.selectionLevel(count: number): number
	return math.min(Farm.SEL_MAX, math.floor(math.sqrt((count or 0) / 10)))
end
function Farm.noteSelection(player: Player, cropId: string)
	local prof = G.Joueurs.get(player)
	if not prof then
		return 0
	end
	prof.selection = prof.selection or {}
	local before = Farm.selectionLevel(prof.selection[cropId])
	prof.selection[cropId] = (prof.selection[cropId] or 0) + 1
	local after = Farm.selectionLevel(prof.selection[cropId])
	if after > before then
		local crop = Config.CROPS[cropId]
		G.Util.toast(player, string.format("🌾 Tes %s sont plus beaux : sélection niveau %d (+%d %% de récoltes doubles%s).",
			string.lower(crop and crop.name or cropId), after, after * 6, after >= 3 and ", parfois triples" or ""), "gain")
	end
	return after
end

-- Nuit : les cultures arrosées poussent (toutes les régions, même déchargées)
-- Redessine les cultures des régions chargées (après une averse : sol mouillé)
-- Redessine les cases dont l'apparence a changé, par tranches de BUDGET secondes de calcul par frame
-- (une case ≈ 1,5 ms : un champ de 3000 cases étalé sur ~1 s au lieu d'une frame de 4 s). Un seul
-- passage à la fois ; un appel pendant un passage en relance un autre à la fin.
local BUDGET = 0.006
local refreshing, again = false, false
function Farm.refreshAll()
	if refreshing then
		again = true
		return
	end
	refreshing = true
	task.defer(function()
		repeat
			again = false
			local todo = {}
			for _, entry in cells do
				if entry.look ~= look(entry) then
					table.insert(todo, entry)
				end
			end
			local t0 = os.clock()
			for _, entry in todo do
				if entry.reg.folder.Parent and cells[entry.key] == entry then
					render(entry)
				end
				if os.clock() - t0 > BUDGET then
					task.wait()
					t0 = os.clock()
				end
			end
		until not again
		refreshing = false
	end)
end

function Farm.newDay()
	-- la pluie arrose désormais en direct (Meteo) ; l'hiver, on ne pousse qu'un jour sur deux
	local grows = not G.Meteo or not G.Meteo.cropGrows or G.Meteo.cropGrows()
	for _, rs in G.world.regions do
		for _, st in rs.tilled or {} do
			if st.crop then
				local crop = Config.CROPS[st.crop]
				if st.watered and grows and st.stage < crop.days then
					st.stage += 1
				end
			end
			-- s'il pleut au lever du jour, la terre reste mouillée
			st.watered = G.Meteo and G.Meteo.isWet and G.Meteo.isWet() or false
		end
		for _, st in rs.plots or {} do
			-- les fermiers arrosent leurs champs
			if st.crop and not st.gone then
				local crop = Config.CROPS[st.crop]
				if st.stage < crop.days then
					st.stage += 1
				end
			end
		end
	end
	Farm.refreshAll()
end

-- Banc de charge (Studio seulement) : n cases bêchées + semées autour d'un point, puis mesure du
-- passage d'un jour. Renvoie { n, msNewDay, msFrameMax, parts } puis efface tout.
function Farm.stress(center: Vector3, n: number)
	if not game:GetService("RunService"):IsStudio() then
		return nil
	end
	local reg = G.World.regionAt(center)
	if not reg then
		return nil
	end
	local side = math.ceil(math.sqrt(n))
	local c0x, c0z = math.floor(center.X / CELL) - side // 2, math.floor(center.Z / CELL) - side // 2
	local made = {}
	for i = 0, n - 1 do
		local cx, cz = c0x + i % side, c0z + i // side
		local key = cellKey(cx, cz)
		if not cells[key] then
			local st = { crop = "wheat", stage = 0, watered = true, owner = "stress" }
			reg.state.tilled[key] = st
			local entry = { reg = reg, key = key, x = cx * CELL + CELL / 2, z = cz * CELL + CELL / 2, state = st, owner = "stress" }
			cells[key] = entry
			render(entry)
			table.insert(made, entry)
		end
		if i % 300 == 0 then
			task.wait()
		end
	end
	local worst = 0
	local conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
		worst = math.max(worst, dt)
	end)
	local t0 = os.clock()
	Farm.newDay()
	local tDay = os.clock() - t0
	local t1 = os.clock()
	task.wait()
	while refreshing do
		task.wait()
	end
	task.wait(0.2)
	conn:Disconnect()
	local parts = 0
	for _, e in made do
		if e.model then
			parts += #e.model:GetDescendants()
		end
	end
	for _, e in made do
		if e.model then
			e.model:Destroy()
		end
		cells[e.key] = nil
		reg.state.tilled[e.key] = nil
	end
	return { n = #made, msNewDay = math.floor(tDay * 1000), msFrameMax = math.floor(worst * 1000), parts = parts, msSpread = math.floor((os.clock() - t1) * 1000) }
end

return Farm
