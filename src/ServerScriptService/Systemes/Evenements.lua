-- Événements de monde : ce qui rend un monde persistant vivant d'un jour à l'autre.
-- Bac à sable : RIEN n'est annoncé à tout le serveur. Seuls ceux qui sont dans le coin voient ou
-- entendent quelque chose ; le reste se découvre (ou se raconte entre joueurs).
--  · Foire : un village paie 30 % plus cher pendant un jour.
--  · Invasion : une vague de créatures du biome attaque un village la nuit ; les défenseurs sont payés.
--  · Pluie de cristaux : des cristaux tombent près des joueurs (glace, or, poussière de feu follet).
--  · Boss itinérants (originaux) : Gardien des Moissons, Roi Mycélien, Colosse de Verre, Dormeur des
--    Glaces. Ils apparaissent dans leur biome, rôdent un moment puis disparaissent s'ils ne sont pas
--    vaincus. Butin unique.
--  · Convoi attaqué : chasser les bandits = payé par le marchand ; piller après coup = vol.
--  · Crue : près d'une rivière ou d'un marais, l'eau monte sur les terres basses quelques minutes.
--    Les champs inondés sont arrosés, et le limon les fait pousser d'un cran quand l'eau se retire.
--  · Découverte archéologique (19/11, idee.txt § 6) : la terre s'est affaissée près d'un joueur et
--    laisse voir des tertres ; on les fouille avec une pelle (antiquités, qui s'étudient ou se vendent).
--  · Route encombrée (21/11, « liste quetes.txt » 518) : un arbre ou un éboulis barre une route près d'un
--    joueur. Le dégager demande la bonne main (hache pour le tronc, pioche pour les rochers), use l'outil,
--    rapporte la matière, et les charretiers reconnaissants laissent quelques pièces (honneur +1).

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Evenements = {}
local G, Config
Evenements.fair = nil -- { region = clé, day = jour, name = village }
local lastEventDay = 0
local active = {} -- en cours : { kind, until, ... }
-- boss errants en vie (pour les rumeurs des habitants, Npcs.rumor) : { name, pos }
function Evenements.bossesAlive()
	local out = {}
	for _, a in active do
		if a.kind == "boss" and a.en and not a.en.dead and a.en.pos then
			table.insert(out, { name = a.name, pos = a.en.pos })
		end
	end
	return out
end

Evenements.BOSSES = {
	harvest_warden = { name = "Gardien des Moissons", biome = { "prairie", "foret" }, night = true },
	mycelian_king = { name = "Roi Mycélien", biome = { "foret", "marais" } },
	glass_colossus = { name = "Colosse de Verre", biome = { "desert" } },
	ice_sleeper = { name = "Dormeur des Glaces", biome = { "neige" } },
}

function Evenements.init(g)
	G = g
	Config = G.Config
	for id, b in G.Bestiaire.ROAMING or {} do
		Evenements.BOSSES[id] = b
	end
	G.Interact.onPrompt("crystal", function(player, prompt)
		Evenements.handlers.crystal(player, prompt)
	end)
	G.Interact.onPrompt("convoy", function(player, prompt)
		Evenements.handlers.convoy(player, prompt)
	end)
	G.Interact.onPrompt("debris", function(player, prompt)
		Evenements.handlers.debris(player, prompt)
	end)
	G.Interact.onPrompt("fouille", function(player, prompt)
		Evenements.handlers.dig(player, prompt)
	end)
end

-- Seuls les joueurs à portée remarquent quelque chose
local function nearby(pos: Vector3, radius: number, text: string)
	for _, p in G.Game.players() do
		local r = G.Util.root(p)
		if r and (r.Position - pos).Magnitude < radius then
			G.Util.toast(p, text)
		end
	end
end

-- Un village connu près des joueurs (région chargée)
local function nearbyVillage()
	local list = {}
	for _, reg in G.World.loaded do
		if reg.plan.poi and reg.plan.poi.kind == "village" then
			table.insert(list, reg)
		end
	end
	return #list > 0 and list[math.random(1, #list)] or nil
end

-- Un point au hasard dans une région chargée d'un des biomes voulus, près d'un joueur
local function spotIn(biomes, minD: number, maxD: number, water: boolean?): (Vector3?, any)
	local players = G.Game.players()
	for _ = 1, 20 do
		local p = players[math.random(1, math.max(1, #players))]
		local root = p and G.Util.root(p)
		if root then
			local a = math.random() * math.pi * 2
			local r = math.random(minD, maxD)
			local pos = root.Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local reg = G.World.regionAt(pos)
			local wet = G.Util.isWater(pos.X, pos.Z)
			if reg and reg.ready and wet == (water == true) and (not biomes or table.find(biomes, G.Clock.biomeAt(pos))) then
				return Vector3.new(pos.X, wet and (G.Config.WATER_Y or 0) or G.Util.groundY(pos.X, pos.Z), pos.Z), reg
			end
		end
	end
	return nil, nil
end

-- ----------------------------------------------------------------- Foire

function Evenements.priceBonus(regKey: string): number
	local f = Evenements.fair
	if f and f.region == regKey and f.day == G.world.day then
		return 1.3
	end
	return 1
end

local function startFair()
	local reg = nearbyVillage()
	if not reg then
		return false
	end
	Evenements.fair = { region = reg.key, day = G.world.day, name = reg.plan.poi.name }
	local poi = reg.plan.poi
	nearby(Vector3.new((poi.x0 + poi.w / 2) * Config.CELL, 0, (poi.z0 + poi.d / 2) * Config.CELL), 200, "On entend de la musique et des marchands qui s'interpellent au village…")
	return true
end

-- ----------------------------------------------------------------- Invasion

local function startInvasion()
	local reg = nearbyVillage()
	if not reg then
		return false
	end
	local poi = reg.plan.poi
	local cx, cz = (poi.x0 + poi.w / 2) * Config.CELL, (poi.z0 + poi.d / 2) * Config.CELL
	local foes = ({ prairie = { "wolf", "boar", "slime_blue" }, foret = { "spider", "myconid", "wolf" }, desert = { "scorpion", "goblin" },
		neige = { "wolf_white", "ice_golem" }, marais = { "toad", "croc", "wisp" } })[reg.plan.biome] or { "wolf" }
	local wave = {}
	-- palissade renforcée par un chantier commun (Systemes/Chantiers) : moins d'assaillants
	local count = math.random(6, 10)
	if reg.rx and G.Chantiers and rawget(G.Chantiers, "waveMult") then
		count = math.max(3, math.floor(count * G.Chantiers.waveMult(reg.rx .. "," .. reg.rz)))
	end
	for i = 1, count do
		local a = i / 10 * math.pi * 2
		local pos = Vector3.new(cx + math.cos(a) * 70, 0, cz + math.sin(a) * 70)
		local r = G.World.regionAt(pos) or reg
		local en = G.Enemies.spawn(r, { id = "invasion#" .. i .. "#" .. G.world.day, kind = foes[math.random(1, #foes)], x = pos.X, z = pos.Z }, r.enemyFolder)
		if en then
			en.transient = true
			en.angry = true
			en.home = Vector3.new(cx, en.pos.Y, cz) -- ils marchent sur le village
			en.state = "chase"
			table.insert(wave, en)
		end
	end
	table.insert(active, { kind = "invasion", wave = wave, name = poi.name, untilT = os.clock() + 300, center = Vector3.new(cx, 0, cz), reg = reg })
	nearby(Vector3.new(cx, 0, cz), 260, "Des cris montent du village…")
	return true
end

-- ----------------------------------------------------------------- Pluie de cristaux

local function startCrystals()
	local center = spotIn(nil, 40, 90)
	if not center then
		return false
	end
	local LOOT = { { "ice_crystal", 1, 2 }, { "gold_ore", 1, 2 }, { "wisp_dust", 1, 3 }, { "copper_ore", 2, 4 } }
	for i = 1, 12 do
		local pos = center + Vector3.new(math.random(-25, 25), 0, math.random(-25, 25))
		if not G.Util.isWater(pos.X, pos.Z) then
			local y = G.Util.groundY(pos.X, pos.Z)
			local c = Instance.new("Part")
			c.Name = "Cristal"
			c.Size = Vector3.new(1.2, 2.4, 1.2)
			c.Anchored = true
			c.CanCollide = false
			c.Material = Enum.Material.Neon
			c.Color = Color3.fromRGB(150, 210, 255)
			c.CFrame = CFrame.new(pos.X, y + 1.2, pos.Z) * CFrame.Angles(0, math.random() * 6, math.rad(math.random(-15, 15)))
			c.Parent = workspace
			local l = LOOT[math.random(1, #LOOT)]
			local pr = G.Util.prompt(c, "crystal", "Ramasser", "Cristal tombé du ciel", { dist = 8 })
			local _ = pr
			c:SetAttribute("Item", l[1])
			c:SetAttribute("N", math.random(l[2], l[3]))
			Debris:AddItem(c, 900)
			local _ = i
		end
	end
	nearby(center, 160, "Une lueur traverse le ciel et s'écrase non loin…")
	return true
end

-- ----------------------------------------------------------------- Découverte archéologique

local DIG_LOOT = { { "old_vase", 30 }, { "fossil", 25 }, { "inscription", 25 }, { "relic_fragment", 20 }, { "ancient_coin", 20 },
	{ "ruin_piece", 15 }, { "old_page", 10 }, { "artifact", 4 }, { "relic", 2 } }

local function startDig()
	local center = spotIn(nil, 40, 110)
	if not center then
		return false
	end
	for _ = 1, 6 do
		local pos = center + Vector3.new(math.random(-14, 14), 0, math.random(-14, 14))
		if not G.Util.isWater(pos.X, pos.Z) then
			local y = G.Util.groundY(pos.X, pos.Z)
			local m = Instance.new("Part")
			m.Name = "Tertre"
			m.Shape = Enum.PartType.Cylinder
			m.Size = Vector3.new(0.9, 3.2, 3.2)
			m.Anchored = true
			m.CanCollide = false
			m.Material = Enum.Material.Ground
			m.Color = Color3.fromRGB(122, 96, 66)
			m.CFrame = CFrame.new(pos.X, y + 0.2, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
			m.Parent = workspace
			G.Util.prompt(m, "fouille", "Fouiller", "Terre retournée", { dist = 8, hold = 2.5 })
			Debris:AddItem(m, 1200)
		end
	end
	nearby(center, 140, "Le sol s'est affaissé non loin : on dirait des pierres taillées qui affleurent…")
	return true
end

-- ----------------------------------------------------------------- Route encombrée

-- un point SUR une route (plan.roadD < 1 case), hors village, entre minD et maxD studs d'un joueur :
-- on parcourt les cases des régions chargées (une case sur deux) et on tire parmi les candidates
function Evenements.roadSpot(minD: number, maxD: number): Vector3?
	local CELL = Config.CELL
	local players = G.Game.players()
	local p = players[math.random(1, math.max(1, #players))]
	local root = p and G.Util.root(p)
	if not root then
		return nil
	end
	local px, pz = root.Position.X, root.Position.Z
	local found = {}
	for _, reg in G.World.loaded do
		local plan = reg.ready and reg.plan
		if plan and plan.roadD and not (plan.poi and plan.poi.kind == "village") then
			local size = Config.REGION or 64
			for lx = 0, size - 1, 2 do
				for lz = 0, size - 1, 2 do
					local k = G.WG.idx(lx, lz)
					if (plan.roadD[k] or 99) < 1 and not plan.water[k] then
						local x, z = (plan.x0 + lx + 0.5) * CELL, (plan.z0 + lz + 0.5) * CELL
						local d = math.sqrt((x - px) ^ 2 + (z - pz) ^ 2)
						if d >= minD and d <= maxD then
							table.insert(found, { x, z })
						end
					end
				end
			end
		end
	end
	if #found == 0 then
		return nil
	end
	local c = found[math.random(1, #found)]
	return Vector3.new(c[1], G.Util.groundY(c[1], c[2]), c[2])
end

Evenements.DEBRIS = {
	log = { name = "Tronc en travers de la route", tool = "axe", item = "wood", n = { 3, 5 }, hits = 3 },
	rock = { name = "Éboulis", tool = "pickaxe", item = "stone", n = { 2, 4 }, hits = 2 },
}

local function startRoadblock()
	local pos = Evenements.roadSpot(40, 140)
	if not pos then
		return false
	end
	local fallenTree = math.random() < 0.6
	local yaw = math.random() * math.pi
	local pieces = fallenTree and { { "log", 0 }, { "log", 4 }, { "log", -4 } } or { { "rock", 0 }, { "rock", 3 }, { "rock", -3 } }
	for _, pc in pieces do
		local kind, off = pc[1], pc[2]
		local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0) * CFrame.new(off, 0, 0)
		local m = Instance.new("Part")
		m.Name = "Debris"
		m.Anchored = true
		if kind == "log" then
			m.Shape = Enum.PartType.Cylinder
			m.Size = Vector3.new(4, 2.2, 2.2)
			m.Material = Enum.Material.Wood
			m.Color = Color3.fromRGB(104, 76, 50)
			m.CFrame = cf * CFrame.new(0, 1.1, 0)
		else
			m.Size = Vector3.new(2.6, 2, 2.4)
			m.Material = Enum.Material.Slate
			m.Color = Color3.fromRGB(120, 118, 112)
			m.CFrame = cf * CFrame.new(0, 1, 0) * CFrame.Angles(math.random() * 0.4, math.random() * 3, math.random() * 0.4)
		end
		m:SetAttribute("Debris", kind)
		m:SetAttribute("Hits", 0)
		m.Parent = workspace
		local d = Evenements.DEBRIS[kind]
		G.Util.prompt(m, "debris", "Dégager", d.name, { dist = 8, hold = 1.2 })
		Debris:AddItem(m, 1800)
	end
	nearby(pos, 160, fallenTree and "Un craquement au loin : un arbre s'est abattu en travers de la route…"
		or "Un grondement : des rochers ont dévalé sur la route…")
	return true
end

-- ----------------------------------------------------------------- Convoi attaqué
-- Une charrette marchande renversée, des bandits autour. Libre à chacun : chasser les bandits et
-- être payé par le marchand, ou attendre qu'ils partent et piller les caisses (vol de PNJ = crime).

local CONVOY_LOOT = { { "wheat", 4, 8 }, { "copper_ore", 2, 5 }, { "gold_ore", 1, 2 }, { "wisp_dust", 1, 2 } }

local function startConvoy()
	local center = spotIn({ "prairie", "foret", "desert" }, 60, 110)
	if not center then
		return false
	end
	local reg = G.World.regionAt(center)
	if not reg then
		return false
	end
	local cart = Instance.new("Model")
	cart.Name = "ConvoiAttaque"
	local crates = {}
	for i = 1, 3 do
		local c = Instance.new("Part")
		c.Name = "Caisse"
		c.Size = Vector3.new(2.4, 2, 2.4)
		c.Anchored = true
		c.Material = Enum.Material.WoodPlanks
		c.Color = Color3.fromRGB(133, 94, 58)
		local off = Vector3.new((i - 2) * 3.2, 0, math.random(-1, 1))
		c.CFrame = CFrame.new(center + off + Vector3.new(0, 1, 0)) * CFrame.Angles(0, math.random() * 6, 0)
		local l = CONVOY_LOOT[math.random(1, #CONVOY_LOOT)]
		c:SetAttribute("Item", l[1])
		c:SetAttribute("N", math.random(l[2], l[3]))
		c.Parent = cart
		G.Util.prompt(c, "convoy", "Ouvrir", "Caisse du marchand", { dist = 8 })
		table.insert(crates, c)
	end
	cart.Parent = workspace
	Debris:AddItem(cart, 900)
	local foes = { "goblin", "goblin", "wolf", "boar" }
	local wave = {}
	for i = 1, math.random(3, 5) do
		local a = i / 5 * math.pi * 2
		local pos = center + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9)
		local en = G.Enemies.spawn(reg, { id = "convoi#" .. i .. "#" .. G.world.day, kind = foes[math.random(1, #foes)], x = pos.X, z = pos.Z }, reg.enemyFolder)
		if en then
			en.transient = true
			en.home = center
			table.insert(wave, en)
		end
	end
	table.insert(active, { kind = "convoy", wave = wave, cart = cart, untilT = os.clock() + 420, center = center, freed = false })
	nearby(center, 180, "Un cheval hennit, des caisses craquent : on se bat sur la route…")
	return true
end

local function convoyOf(part: Instance)
	for _, e in active do
		if e.kind == "convoy" and part:IsDescendantOf(e.cart) then
			return e
		end
	end
	return nil
end

-- ----------------------------------------------------------------- Crue

local FLOOD_RADIUS = 90
local FLOOD_RISE = 4.7 -- au-dessus du niveau de l'eau : les prés bas (sol à 3-4) ont les pieds dans l'eau

-- Un point d'eau (rivière, marais, étang) près d'un joueur
local function waterNear(): Vector3?
	local players = G.Game.players()
	for _ = 1, 30 do
		local p = players[math.random(1, math.max(1, #players))]
		local root = p and G.Util.root(p)
		if root then
			local a = math.random() * math.pi * 2
			local r = math.random(10, 70)
			local pos = root.Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local reg = G.World.regionAt(pos)
			if reg and reg.ready and G.Util.isWater(pos.X, pos.Z) and G.Clock.biomeAt(pos) ~= "neige" then
				return Vector3.new(pos.X, Config.WATER_Y, pos.Z)
			end
		end
	end
	return nil
end

local function startFlood()
	local center = waterNear()
	if not center then
		return false
	end
	local level = Config.WATER_Y + FLOOD_RISE
	local sheet = Instance.new("Part")
	sheet.Name = "Crue"
	sheet.Anchored = true
	sheet.CanCollide = false
	sheet.CanQuery = false
	sheet.CanTouch = false
	sheet.CastShadow = false
	sheet.Material = Enum.Material.Glass
	sheet.Color = Color3.fromRGB(96, 140, 150)
	sheet.Transparency = 0.25
	sheet.Reflectance = 0.08
	sheet.Shape = Enum.PartType.Cylinder -- disque couché : la crue s'étale en rond autour du lit
	sheet.Size = Vector3.new(0.4, FLOOD_RADIUS * 2, FLOOD_RADIUS * 2)
	sheet.CFrame = CFrame.new(center.X, Config.WATER_Y - 0.4, center.Z) * CFrame.Angles(0, 0, math.rad(90))
	sheet.Parent = workspace
	local e = { kind = "flood", untilT = math.huge, center = center, sheet = sheet }
	table.insert(active, e)
	nearby(center, 160, "L'eau monte, la rivière sort de son lit…")
	task.spawn(function()
		-- montée (on voit l'eau gagner les berges), plateau, puis décrue
		local up = TweenInfo.new(25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		TweenService:Create(sheet, up, { CFrame = CFrame.new(center.X, level, center.Z) * CFrame.Angles(0, 0, math.rad(90)) }):Play()
		task.wait(25)
		local flooded = G.Farm.flood(center, FLOOD_RADIUS, level)
		task.wait(200)
		local down = TweenInfo.new(40, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		TweenService:Create(sheet, down, { CFrame = CFrame.new(center.X, Config.WATER_Y - 0.6, center.Z) * CFrame.Angles(0, 0, math.rad(90)) }):Play()
		task.wait(40)
		sheet:Destroy()
		G.Farm.silt(flooded)
		-- l'eau laisse des choses derrière elle
		for _, p in G.Game.players() do
			local r = G.Util.root(p)
			if r and (r.Position - center).Magnitude < FLOOD_RADIUS then
				G.Util.finds(p, "fish")
				G.Joueurs.sync(p)
			end
		end
		if #flooded > 0 then
			nearby(center, 160, "L'eau s'est retirée, laissant un limon noir sur les champs.")
		end
		e.untilT = 0
	end)
	return true
end

-- ----------------------------------------------------------------- Boss itinérants

local function startBoss()
	local ids = {}
	for id, b in Evenements.BOSSES do
		if not b.night or G.Clock.isNight() then
			table.insert(ids, id)
		end
	end
	local id = ids[math.random(1, #ids)]
	local b = Evenements.BOSSES[id]
	-- boss maritime (b.mer) : surgit de l'eau près d'un joueur sur la côte ou en barque
	local pos, reg = spotIn(not b.mer and b.biome or nil, b.mer and 30 or 60, b.mer and 90 or 120, b.mer)
	if not pos then
		return false
	end
	local en = G.Enemies.spawn(reg, { id = "boss#" .. id .. "#" .. G.world.day, kind = id, x = pos.X, z = pos.Z }, reg.enemyFolder)
	if not en then
		return false
	end
	en.transient = true
	table.insert(active, { kind = "boss", en = en, name = b.name, untilT = os.clock() + 600 })
	nearby(pos, 180, b.mer and "L'eau bouillonne. Une lueur remonte des profondeurs…" or "Le sol tremble. Quelque chose d'énorme rôde par ici…")
	return true
end

-- Créature attirée par l'orage (19/11) : pendant un orage, un éclair « fait lever » un esprit de
-- l'orage près d'un joueur ; il se dissipe avec la pluie (8 min) s'il n'est pas vaincu.
local function startStorm()
	if not (G.Meteo and G.Meteo.kind and G.Meteo.kind() == "orage") then
		return false
	end
	local pos, reg = spotIn(nil, 50, 90)
	if not pos then
		return false
	end
	local en = G.Enemies.spawn(reg, { id = "orage#" .. G.world.day .. "#" .. math.random(1, 1e6), kind = "storm_wraith", x = pos.X, z = pos.Z }, reg.enemyFolder)
	if not en then
		return false
	end
	en.transient = true
	G.Util.sfx("coup", pos)
	table.insert(active, { kind = "boss", en = en, name = "L'esprit de l'orage", untilT = os.clock() + 480 })
	nearby(pos, 160, "⚡ Un éclair frappe le sol tout près… et quelque chose s'en relève.")
	return true
end

-- Réveil d'un golem (19/11) : un colosse de pierre s'arrache du sol, loin des villages ; il se
-- rendort au bout de 10 min s'il n'est pas abattu (butin de colosse : pierre, minerai, cœur).
local function startGolem()
	local pos, reg = spotIn(nil, 70, 130)
	if not pos or (reg.plan.poi and reg.plan.poi.kind == "village") then
		return false
	end
	local en = G.Enemies.spawn(reg, { id = "golem#" .. G.world.day .. "#" .. math.random(1, 1e6), kind = "stone_golem", x = pos.X, z = pos.Z }, reg.enemyFolder)
	if not en then
		return false
	end
	en.transient = true
	table.insert(active, { kind = "boss", en = en, name = "Le colosse de pierre", untilT = os.clock() + 600 })
	nearby(pos, 200, "Les rochers grondent : un colosse de pierre s'arrache du sol !")
	return true
end

Evenements.handlers = {
	dig = function(player, prompt)
		local mound = prompt.Parent
		if not (mound and mound.Parent) then
			return
		end
		if not (G.Joueurs.has(player, "shovel") or G.Joueurs.has(player, "spade")) then
			G.Util.toast(player, "Il te faudrait une pelle pour fouiller ici.")
			return
		end
		mound:Destroy()
		local total = 0
		for _, l in DIG_LOOT do
			total += l[2]
		end
		local finds = 1 + (math.random() < 0.15 * G.Joueurs.talent(player, "archeologue") and 1 or 0)
		for _ = 1, finds do
			local r = math.random() * total
			for _, l in DIG_LOOT do
				r -= l[2]
				if r <= 0 then
					if G.Config.ITEMS[l[1]] then
						G.Joueurs.add(player, l[1], l[1] == "ancient_coin" and math.random(2, 4) or 1)
					end
					break
				end
			end
		end
		G.Joueurs.addStatXp(player, "chance", 15)
		G.Joueurs.wearTool(player, "shovel", 1)
		G.Joueurs.sync(player)
	end,
	debris = function(player, prompt)
		local m = prompt.Parent
		local kind = m and m:GetAttribute("Debris")
		local d = kind and Evenements.DEBRIS[kind]
		local root = G.Util.root(player)
		if not d or not root or (root.Position - m.Position).Magnitude > 12 then
			return
		end
		-- certaines choses ne se font pas à mains nues (grind) : hache pour le bois, pioche pour la pierre
		local tool = G.Joueurs.bestTool(player, d.tool)
		if not tool then
			G.Util.toast(player, kind == "log" and "🪓 Il faut une hache pour débiter ce tronc." or "⛏️ Il faut une pioche pour casser ces rochers.", "refus")
			return
		end
		G.Joueurs.wearTool(player, d.tool, 1)
		local hits = (m:GetAttribute("Hits") or 0) + 1
		m:SetAttribute("Hits", hits)
		G.Util.sfx("coup", m.Position, player)
		if hits < d.hits then
			return
		end
		G.Joueurs.add(player, d.item, math.random(d.n[1], d.n[2]))
		G.Joueurs.add(player, "gold", math.random(4, 9), true)
		G.Joueurs.addSkillXp(player, d.tool == "axe" and "bucheronnage" or "minage", 4)
		G.Law.addHonor(player, 1)
		G.Joueurs.sync(player)
		m:Destroy()
		G.Util.toast(player, "🛣️ Un charretier qui attendait te lance quelques pièces : « Merci, l'ami ! »")
	end,
	crystal = function(player, prompt)
		local item, n = prompt.Parent:GetAttribute("Item"), prompt.Parent:GetAttribute("N") or 1
		if item then
			G.Joueurs.add(player, item, n)
			G.Joueurs.addSkillXp(player, "minage", 4)
			G.Joueurs.sync(player)
			prompt.Parent:Destroy()
		end
	end,
	convoy = function(player, prompt)
		local crate = prompt.Parent
		local item, n = crate:GetAttribute("Item"), crate:GetAttribute("N") or 1
		if not item then
			return
		end
		local e = convoyOf(crate)
		if e then
			for _, en in e.wave do
				if not en.dead then
					G.Util.toast(player, "Les bandits rôdent encore autour des caisses.")
					return
				end
			end
		end
		G.Joueurs.add(player, item, n)
		G.Util.finds(player, "event")
		-- convoi sauvé : le marchand paie ; pillé après coup : c'est du vol
		if e and e.freed then
			G.Joueurs.add(player, "gold", 40, true)
			G.Law.addHonor(player, 2)
		else
			G.Law.addHonor(player, -3)
		end
		G.Joueurs.sync(player)
		crate:Destroy()
	end,
}

-- ----------------------------------------------------------------- Planification

-- Studio / tests : force un événement ("fair", "invasion", "crystals", "convoy", "flood", "boss")
function Evenements.force(kind: string)
	local f = ({ fair = startFair, invasion = startInvasion, crystals = startCrystals, convoy = startConvoy, flood = startFlood, boss = startBoss,
		orage = startStorm, golem = startGolem, fouilles = startDig, route = startRoadblock })[kind]
	return f and f() or false
end

local acc = 0
function Evenements.step(dt: number)
	acc += dt
	if acc < 20 then
		return
	end
	acc = 0
	-- suivi des événements en cours
	for i = #active, 1, -1 do
		local e = active[i]
		if e.kind == "invasion" then
			local alive = 0
			for _, en in e.wave do
				if not en.dead then
					alive += 1
				end
			end
			if alive == 0 then
				table.remove(active, i)
				-- les villageois remercient ceux qui se sont battus (au moins un coup porté à un assaillant ;
				-- 20/11 : avant, il suffisait d'être à moins de 160 studs, même sans rien faire)
				local fought = {}
				for _, en in e.wave do
					for p in en.hitters or {} do
						fought[p] = true
					end
				end
				for _, p in G.Game.players() do
					local r = G.Util.root(p)
					if r and fought[p] and e.center and (r.Position - e.center).Magnitude < 160 then
						G.Joueurs.add(p, "gold", 120, true)
						G.Util.finds(p, "event")
						G.Law.addHonor(p, 5)
						G.Util.toast(p, "Les villageois de " .. e.name .. " te remercient : +120 💰.")
						G.Joueurs.sync(p)
					end
				end
			elseif os.clock() > e.untilT then
				table.remove(active, i)
				local survivors = alive -- assaillants encore debout à la fin du délai
				for _, en in e.wave do
					if not en.dead then
						en.dead = true
						en.model:Destroy()
					end
				end
				-- personne ne les a repoussés : ils ont saccagé une maison avant de partir (elle restera
				-- en ruine 4 jours, sauf si le maire paie les réparations)
				if e.reg and G.Demolir.ravage and survivors >= 3 then
					G.Demolir.ravage(e.reg)
					if e.center then
						nearby(e.center, 260, "Les assaillants repartent… en laissant une maison en ruine.")
					end
				elseif e.center then
					nearby(e.center, 200, "Les assaillants se sont retirés.")
				end
			end
		elseif e.kind == "convoy" then
			local alive = 0
			for _, en in e.wave do
				if not en.dead then
					alive += 1
				end
			end
			if not e.cart.Parent then
				table.remove(active, i)
			elseif alive == 0 and not e.freed and os.clock() <= e.untilT then
				e.freed = true
				nearby(e.center, 120, "Le marchand se relève : « Merci ! Servez-vous dans les caisses. »")
			elseif os.clock() > e.untilT and alive > 0 then
				-- les bandits filent ; les caisses restent, mais les prendre est du vol
				for _, en in e.wave do
					if not en.dead then
						en.dead = true
						en.model:Destroy()
					end
				end
				e.untilT = math.huge
			end
		elseif e.kind == "flood" then
			if os.clock() > e.untilT then
				table.remove(active, i)
			end
		elseif e.kind == "boss" then
			if e.en.dead then
				table.remove(active, i)
				nearby(e.en.pos, 120, "Le silence retombe. " .. e.name .. " ne bougera plus.")
			elseif os.clock() > e.untilT then
				table.remove(active, i)
				e.en.dead = true
				e.en.model:Destroy()
				local _ = e.name -- reparti sans laisser de trace
			end
		end
	end
	-- un nouvel événement de temps en temps (s'il y a du monde)
	if #G.Game.players() == 0 or #active > 0 then
		return
	end
	local chance = (G.world.day - lastEventDay >= 2) and 0.25 or 0.04
	if math.random() > chance then
		return
	end
	local night = G.Clock.isNight()
	local options = night and { startInvasion, startBoss, startCrystals, startFlood, startGolem } or { startFair, startBoss, startCrystals, startConvoy, startFlood, startGolem, startDig, startRoadblock }
	local f = options[math.random(1, #options)]
	-- un orage gronde : une fois sur deux, c'est lui qui attire quelque chose
	if G.Meteo and G.Meteo.kind and G.Meteo.kind() == "orage" and math.random() < 0.5 then
		f = startStorm
	end
	local ok, res = pcall(f)
	if ok and res then
		lastEventDay = G.world.day
	end
end

return Evenements
