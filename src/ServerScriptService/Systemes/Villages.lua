-- Villages plus médiévaux : chaque village reçoit, autour de sa place, une taverne, une forge, une
-- chapelle et un marché (selon la place libre). Posés par-dessus la génération, avec leur propre
-- graine (les sauvegardes des mondes existants restent valables). Ils rejoignent les maisons du
-- village (reg.houses) : portes qui s'ouvrent, et on peut les casser (Demolir) comme le reste.

local Villages = {}
local G, Config

local BUILDINGS = {
	{ model = "Taverne", w = 28, d = 20 },
	{ model = "Forge", w = 18, d = 16 },
	{ model = "Chapelle", w = 16, d = 34 },
	{ model = "Marche_Village", w = 26, d = 6, open = true },
	{ model = "Auberge", w = 24, d = 18 }, -- lits à louer : point de réapparition
	{ model = "Ecurie", w = 22, d = 16, open = true },
	{ model = "Tour_Guet", w = 9, d = 9, open = true, far = true },
	-- ajouté le 18/11 : en dernier, pour ne rien déplacer des villages déjà vus ; évite ce que les
	-- joueurs ont construit (les autres bâtiments existaient avant leurs constructions)
	{ model = "Moulin_Village", w = 16, d = 20, open = true, avoidBuilt = true },
	{ model = "Champ_Ble", w = 26, d = 20, open = true, avoidBuilt = true }, -- 18/11 (image cible), après le moulin
}
local PALISADE_R = 88 -- rayon de l'enceinte (studs) autour du centre du village
local SEG = 8 -- longueur d'un pan de palissade

-- Repas de taverne : 12 or, toute la vie rendue (une fois par minute au plus)
local lastMeal = setmetatable({}, { __mode = "k" })
function Villages.meal(player: Player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	if os.clock() - (lastMeal[player] or -999) < 60 then
		return G.Util.toast(player, "🍲 L'aubergiste : « Tu sors de table, voyons ! »")
	end
	if not G.Joueurs.take(player, "gold", 12) then
		return G.Util.toast(player, "🍲 L'aubergiste : « Un repas chaud, c'est 12 or. »")
	end
	lastMeal[player] = os.clock()
	hum.Health = hum.MaxHealth
	G.Joueurs.sync(player)
	G.Util.toast(player, "🍲 Ragoût fumant et pain frais : te voilà requinqué.", "gain")
end

function Villages.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("taverne_repas", function(player)
		Villages.meal(player)
	end)
end

local function clearSpot(reg, x: number, z: number, w: number, d: number, taken): boolean
	local plan = reg.plan
	local CELL = Config.CELL
	local r = math.max(w, d) / 2 + 3
	-- pas sur l'eau, pas sur une route, terrain plat
	local h0
	for dx = -w / 2, w / 2, CELL do
		for dz = -d / 2, d / 2, CELL do
			local px, pz = x + dx, z + dz
			local cx, cz = math.floor(px / CELL), math.floor(pz / CELL)
			local lx, lz = cx - plan.x0, cz - plan.z0
			if lx < 1 or lz < 1 or lx > Config.REGION - 2 or lz > Config.REGION - 2 then
				return false
			end
			local i = G.WG.idx(lx, lz)
			if plan.water[i] or plan.roadD[i] < 2.2 then
				return false
			end
			local h = plan.H[i]
			h0 = h0 or h
			if math.abs(h - h0) > 1.5 then
				return false
			end
		end
	end
	-- loin des maisons, du décor et des autres bâtiments posés
	for _, hh in plan.houses do
		if (Vector3.new(hh.x, 0, hh.z) - Vector3.new(x, 0, z)).Magnitude < r + 12 then
			return false
		end
	end
	for _, dd in plan.decos do
		if (Vector3.new(dd.x, 0, dd.z) - Vector3.new(x, 0, z)).Magnitude < r then
			return false
		end
	end
	for _, t in taken do
		if (t.pos - Vector3.new(x, 0, z)).Magnitude < r + t.r + 4 then
			return false
		end
	end
	return true
end

-- rien de construit / posé par les joueurs dans ce rayon ?
function Villages.freeOfBuilds(reg, x: number, z: number, r: number): boolean
	for _, list in { reg.state.built or {}, reg.state.placed or {} } do
		for _, d in list do
			if d.x and d.z and (Vector3.new(d.x, 0, d.z) - Vector3.new(x, 0, z)).Magnitude < r then
				return false
			end
		end
	end
	return true
end

function Villages.onRegionLoad(reg)
	local plan = reg.plan
	local poi = plan.poi
	if not poi or poi.kind ~= "village" then
		return
	end
	local CELL = Config.CELL
	local center = Vector3.new((poi.x0 + poi.w / 2) * CELL, 0, (poi.z0 + poi.d / 2) * CELL)
	local rng = Random.new(G.WG.hash(G.world.seed, "villages", reg.rx, reg.rz))
	local hf = reg.folder:FindFirstChild("Maisons") or reg.folder
	local taken = {}
	for _, b in BUILDINGS do
		for _ = 1, 40 do
			local a = rng:NextNumber(0, math.pi * 2)
			local dist = b.far and rng:NextNumber(66, 78) or rng:NextNumber(26, 70)
			local x, z = center.X + math.cos(a) * dist, center.Z + math.sin(a) * dist
			x, z = math.floor(x / CELL) * CELL + CELL / 2, math.floor(z / CELL) * CELL + CELL / 2
			if clearSpot(reg, x, z, b.w, b.d, taken) and (not b.avoidBuilt or Villages.freeOfBuilds(reg, x, z, math.max(b.w, b.d) / 2 + 4)) then
				local toC = center - Vector3.new(x, 0, z)
				local yaw = math.deg(math.atan2(toC.X, toC.Z)) -- la façade (+Z) regarde la place
				yaw = math.floor(yaw / 90 + 0.5) * 90
				local id = "v:" .. b.model
				local model = G.Util.clone(b.model)
				if model then
					model.Name = b.model
					model:SetAttribute("HouseId", id)
					G.World.place(model, x, G.Util.groundY(x, z), z, yaw, hf)
					G.Clock.seasonize(model)
					reg.houses[id] = { data = { id = id, model = b.model, x = x, z = z, yaw = yaw }, model = model }
					table.insert(taken, { pos = Vector3.new(x, 0, z), r = math.max(b.w, b.d) / 2 })
					if b.model == "Auberge" then
						for _, a in model:GetDescendants() do
							if a:IsA("Attachment") and string.match(a.Name, "^LitAuberge") then
								local pr = G.Util.prompt(a, "bed", "Dormir", "Auberge (10 💰)")
								pr:SetAttribute("Inn", true)
							end
						end
					end
				end
				break
			end
		end
	end
	Villages.palisade(reg, center, taken)
	-- taverne : l'aubergiste sert un repas chaud (rend toute la vie) — 18/11
	local tav = reg.houses["v:Taverne"]
	if tav and tav.model and tav.model.PrimaryPart then
		local a = G.Util.anchor(tav.model, tav.model.PrimaryPart.CFrame * CFrame.new(0, 2, 10), "Aubergiste")
		G.Util.prompt(a, "taverne_repas", "Repas chaud (12 or)", "Taverne · " .. (poi.name or ""), { dist = 12, key = Enum.KeyCode.F })
	end
	-- forge : le forgeron répare les outils contre de l'or (Shop.repairAll)
	local forge = reg.houses["v:Forge"]
	if forge and forge.model and forge.model.PrimaryPart then
		local a = G.Util.anchor(forge.model, forge.model.PrimaryPart.CFrame * CFrame.new(0, 2, 9), "Forgeron")
		G.Util.prompt(a, "forge_reparer", "Faire réparer mes outils", "Forgeron · " .. (poi.name or ""), { dist = 12, key = Enum.KeyCode.F })
	end
	-- écurie : on y fait venir sa monture (Horses.fetch)
	local stable = reg.houses["v:Ecurie"]
	if stable and stable.model and stable.model.PrimaryPart then
		local base = stable.model.PrimaryPart
		local a = G.Util.anchor(stable.model, base.CFrame * CFrame.new(0, 2, 10), "Palefrenier")
		G.Util.prompt(a, "ecurie", "Faire venir ma monture", "Écurie · pension " .. (type(G.Horses.STABLE_FEE) == "number" and G.Horses.STABLE_FEE or 5) .. " or", { dist = 12 })
	end
	Villages.questBoard(reg, center, taken, poi.name or "", hf)
	Villages.dock(reg, center, poi.name or "", hf)
	-- tableau d'affichage (activités des joueurs) : au marché, sinon à la taverne
	for _, name in { "Marche_Village", "Taverne", "Auberge" } do
		local h = reg.houses["v:" .. name]
		if h and h.model and h.model.PrimaryPart then
			local pr = G.Util.prompt(h.model.PrimaryPart, "tableau", "Tableau d'affichage", poi.name or "", { dist = 14 })
			pr:SetAttribute("Village", reg.key)
			break
		end
	end
	-- conseil du village : sur le parvis de la chapelle (sinon au marché, sinon à la taverne)
	if G.Politique and G.Politique.register then
		G.Politique.register(reg.key, poi.name or "", center)
		for _, name in { "Chapelle", "Marche_Village", "Taverne" } do
			local h = reg.houses["v:" .. name]
			if h and h.model then
				local at = h.model:FindFirstChild("Travail", true)
				local anchor = at and at.Parent and at or h.model.PrimaryPart
				if anchor then
					local pr = G.Util.prompt(anchor, "conseil", "Conseil du village", poi.name or "", { dist = 12 })
					pr:SetAttribute("Village", reg.key)
				end
				break
			end
		end
	end
end

-- Tableau des quêtes façon WoW, près de la place (tirage à part : rien d'autre ne bouge). Faute
-- de place libre, l'invite va sur le marché / la taverne.
function Villages.questBoard(reg, center: Vector3, taken, name: string, hf: Instance)
	if not (G.Quetes and G.Quetes.registerBoard) then
		return
	end
	local CELL = Config.CELL
	local rng = Random.new(G.WG.hash(G.world.seed, "tableau-quetes", reg.rx, reg.rz))
	local part = nil
	for _ = 1, 40 do
		local a = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(10, 24)
		local x, z = center.X + math.cos(a) * dist, center.Z + math.sin(a) * dist
		x, z = math.floor(x / CELL) * CELL + CELL / 2, math.floor(z / CELL) * CELL + CELL / 2
		if clearSpot(reg, x, z, 6, 4, taken) and Villages.freeOfBuilds(reg, x, z, 5) then
			local model = G.Util.clone("Tableau_Quetes")
			if model then
				local toC = center - Vector3.new(x, 0, z)
				local yaw = math.floor(math.deg(math.atan2(toC.X, toC.Z)) / 90 + 0.5) * 90
				G.World.place(model, x, G.Util.groundY(x, z), z, yaw, hf)
				table.insert(taken, { pos = Vector3.new(x, 0, z), r = 3 })
				part = model:FindFirstChild("Planche") or model.PrimaryPart
			end
			break
		end
	end
	if not part then
		for _, n in { "Marche_Village", "Taverne", "Auberge" } do
			local h = reg.houses["v:" .. n]
			if h and h.model and h.model.PrimaryPart then
				part = h.model.PrimaryPart
				break
			end
		end
	end
	if part then
		local pr = G.Util.prompt(part, "quetes_tableau", "Quêtes", name, { dist = 12, key = part.Name == "Planche" and Enum.KeyCode.E or Enum.KeyCode.F })
		pr:SetAttribute("Village", reg.key)
		G.Quetes.registerBoard(reg.key, part)
	end
end

-- Quai (18/11) : village au bord de l'eau → un embarcadère sur la rive la plus proche, d'où l'on
-- « prend la mer » comme au port d'arrivée. On cherche l'eau en étoile autour de la place.
function Villages.dock(reg, center: Vector3, name: string, hf: Instance)
	local best = nil
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local prev = nil
		for r = 20, 96, 4 do
			local p = center + dir * r
			if G.Util.isWater(p.X, p.Z) then
				if prev and (not best or r < best.r) then
					best = { r = r, at = prev, dir = dir }
				end
				break
			end
			prev = p
		end
	end
	if not best or not Villages.freeOfBuilds(reg, best.at.X, best.at.Z, 8) then
		return
	end
	local at = best.at + best.dir * 3
	local yaw = math.deg(math.atan2(best.dir.X, best.dir.Z)) -- le ponton (+Z) avance sur l'eau
	local dock = G.World.buildDeco({ model = "Embarcadere", x = at.X, z = at.Z, yaw = yaw, water = true }, hf)
	if dock and dock.PrimaryPart then
		G.Util.prompt(dock.PrimaryPart, "port", "Prendre la mer", "Quai de " .. name .. " · carte des mondes", { dist = 10 })
	end
end

-- Enceinte de pieux autour du village : ouverte sur les routes (portes), jamais dans l'eau, sur
-- une pente trop raide, sur une maison ou hors de la région (la région voisine fera sa part).
function Villages.palisade(reg, center: Vector3, taken)
	local plan = reg.plan
	local CELL = Config.CELL
	local folder = Instance.new("Folder")
	folder.Name = "Palissade"
	local n = math.floor(2 * math.pi * PALISADE_R / SEG)
	local placed = 0
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * 2 * math.pi
		local x, z = center.X + math.cos(a) * PALISADE_R, center.Z + math.sin(a) * PALISADE_R
		local cx, cz = math.floor(x / CELL), math.floor(z / CELL)
		local lx, lz = cx - plan.x0, cz - plan.z0
		local ok = lx >= 0 and lz >= 0 and lx < Config.REGION and lz < Config.REGION
		if ok then
			local k = G.WG.idx(lx, lz)
			ok = not plan.water[k] and plan.roadD[k] >= 3.2
		end
		if ok then
			for _, t in taken do
				if (t.pos - Vector3.new(x, 0, z)).Magnitude < t.r + 4 then
					ok = false
					break
				end
			end
		end
		if ok then
			for _, hh in plan.houses do
				if (Vector3.new(hh.x, 0, hh.z) - Vector3.new(x, 0, z)).Magnitude < 16 then
					ok = false
					break
				end
			end
		end
		if ok then
			local y1 = G.Util.groundY(x - math.sin(a) * SEG / 2, z + math.cos(a) * SEG / 2)
			local y2 = G.Util.groundY(x + math.sin(a) * SEG / 2, z - math.cos(a) * SEG / 2)
			if math.abs(y1 - y2) < 4 then
				local seg = G.Util.clone("Palissade")
				if seg then
					-- le pan suit la tangente du cercle ; on l'enfonce un peu pour épouser la pente
					seg:PivotTo(CFrame.new(x, math.min(y1, y2) - 0.3, z) * CFrame.Angles(0, -a + math.pi / 2, 0))
					seg.Parent = folder
					placed += 1
				end
			end
		end
	end
	if placed > 0 then
		folder.Parent = reg.folder
	end
	return placed
end

return Villages
