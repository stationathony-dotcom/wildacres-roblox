-- Tout se casse : maisons des villages, décor (puits, fontaines, étals, lampadaires…), objets posés
-- par les autres joueurs. Hache ou pioche, coup après coup ; à la fin il reste des décombres et
-- quelques matériaux. Bac à sable : c'est permis, mais si quelqu'un te voit c'est du vandalisme
-- (étoiles, prime, honneur, avis des villageois). Les villageois rebâtissent au bout de quelques jours.
-- État : reg.state.wrecked = { ["h:<maison>"] = jour, ["d:<n° décor>"] = jour }

local Demolir = {}
local G, Config

local REBUILD_DAYS = 4
local HP = { house = 36, deco = 6, placed = 8 }
local hits = {} -- clé de cible -> coups reçus
-- 18/11 « tout ramassable » : chaque décor donne ce qui lui ressemble (objet, min, max) ; les décors
-- LÉGERS se cassent aussi à mains nues (bien plus lentement), au clic façon Minecraft
local DROPS = {
	Botte_Foin = { "wheat", 2, 4 }, Tonneaux = { "planks", 2, 4 }, Caisses = { "planks", 2, 3 }, Cloture = { "wood", 1, 2 },
	Panneau = { "planks", 1, 2 }, Boite_Lettres = { "planks", 1, 2 }, Epouvantail = { "fiber", 2, 4 }, Feu_Camp = { "stone", 1, 3 },
	Lampadaire = { "stone", 1, 2 }, Puits = { "stone", 3, 6 }, Fontaine = { "stone", 4, 8 }, Roseaux = { "fiber", 1, 2 },
	Nenuphar = { "fiber", 1, 1 }, Fleurs = { "flower", 1, 2 }, Pot_Fleurs = { "flower", 1, 1 },
}
local SOFT = { Botte_Foin = true, Caisses = true, Epouvantail = true, Roseaux = true, Nenuphar = true, Fleurs = true, Pot_Fleurs = true, Panneau = true, Boite_Lettres = true }
local HAND_POWER = 0.4

function Demolir.init(g)
	G = g
	Config = G.Config
	-- clic sur un décor : on frappe avec la meilleure hache / pioche, sinon à mains nues
	local last = {}
	G.Interact.onAction("deco_clic", function(player, data)
		-- le client envoie le n° du décor visé ; on retrouve le modèle près du joueur
		local idx = type(data) == "table" and data.idx
		local root = G.Util.root(player)
		if idx == nil or not root then
			return
		end
		local m = nil
		for _, reg in G.World.loaded do
			local f = reg.folder and reg.folder:FindFirstChild("Decor")
			for _, c in f and f:GetChildren() or {} do
				if c:IsA("Model") and c:GetAttribute("DecoIdx") == idx and (c:GetPivot().Position - root.Position).Magnitude < 16 then
					m = c
					break
				end
			end
			if m then
				break
			end
		end
		if not m then
			return
		end
		local now = os.clock()
		if now - (last[player] or 0) < 0.3 then
			return
		end
		last[player] = now
		local tool = nil
		for _, t in { "axe", "pickaxe" } do
			local _, tier = G.Joueurs.bestTool(player, t)
			if tier > 0 then
				tool = t
				break
			end
		end
		Demolir.smash(player, tool, m)
	end)
end

local function chips(pos: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(pos)
	p.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(0.6, 0.1)
	e.Speed = NumberRange.new(8, 14)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(0, -40, 0)
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Parent = p
	e:Emit(14)
	game:GetService("Debris"):AddItem(p, 1.5)
end

-- Décombres à la place d'une maison : le socle, des pans de mur bas, des poutres tombées
local function rubble(cf: CFrame, w: number, d: number): Model
	local m = Instance.new("Model")
	m.Name = "Decombres"
	local function P(size, off, color, mat, rot)
		local p = Instance.new("Part")
		p.Size = size
		p.CFrame = cf * CFrame.new(off) * (rot or CFrame.identity)
		p.Color = color
		p.Material = mat
		p.Anchored = true
		p.Parent = m
		return p
	end
	local base = P(Vector3.new(w + 0.6, 0.8, d + 0.6), Vector3.new(0, 0.4, 0), Color3.fromRGB(128, 128, 134), Enum.Material.Cobblestone)
	m.PrimaryPart = base
	local rng = Random.new()
	for _, s in { { 0, -d / 2 + 0.4, w, 0.8 }, { -w / 2 + 0.4, 0, 0.8, d }, { w / 2 - 0.4, 0, 0.8, d } } do
		P(Vector3.new(s[3], rng:NextNumber(1.2, 3.4), s[4]), Vector3.new(s[1], 1.6, s[2]), Color3.fromRGB(150, 146, 136), Enum.Material.Cobblestone)
	end
	for _ = 1, 6 do
		P(Vector3.new(0.8, 0.8, rng:NextNumber(4, 8)), Vector3.new(rng:NextNumber(-w / 3, w / 3), 1.2, rng:NextNumber(-d / 3, d / 3)),
			Color3.fromRGB(70, 50, 34), Enum.Material.Wood, CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)))
	end
	for _ = 1, 8 do
		local s = rng:NextNumber(0.8, 1.8)
		P(Vector3.new(s, s * 0.7, s), Vector3.new(rng:NextNumber(-w / 2, w / 2), 1, rng:NextNumber(-d / 2, d / 2)),
			Color3.fromRGB(140, 136, 128), Enum.Material.Slate, CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0))
	end
	return m
end

local function wreckHouse(reg, id: string)
	local h = reg.houses[id]
	if not h or not h.model or h.wrecked then
		return
	end
	local base = h.model.PrimaryPart
	local w, d = base and base:GetAttribute("Largeur") or 20, base and base:GetAttribute("Profondeur") or 16
	local cf = h.model:GetPivot()
	local parent = h.model.Parent
	h.model:Destroy()
	local r = rubble(cf, w, d)
	r:SetAttribute("HouseId", id)
	r.Parent = parent
	h.model = r
	h.wrecked = true
end

-- Un bâtiment du village ravagé par un événement (invasion non repoussée) : en ruine, rebâti par les
-- villageois au bout de REBUILD_DAYS (ou tout de suite si le maire paie les réparations)
function Demolir.ravage(reg): string?
	local ids = {}
	for id, h in reg.houses do
		if h.model and not h.wrecked then
			table.insert(ids, id)
		end
	end
	if #ids == 0 then
		return nil
	end
	local id = ids[math.random(1, #ids)]
	wreckHouse(reg, id)
	reg.state.wrecked = reg.state.wrecked or {}
	reg.state.wrecked["h:" .. id] = G.world.day
	return id
end

local function wreckDeco(reg, idx: number)
	local f = reg.folder and reg.folder:FindFirstChild("Decor")
	for _, m in f and f:GetChildren() or {} do
		if m:GetAttribute("DecoIdx") == idx then
			m:Destroy()
		end
	end
end

-- Au chargement d'une région : ce qui est encore en ruine le reste ; le reste a été rebâti
function Demolir.onRegionLoad(reg)
	local w = reg.state.wrecked
	if not w then
		return
	end
	for key, day in w do
		if G.world.day >= day + REBUILD_DAYS then
			w[key] = nil
		else
			local kind, id = string.match(key, "^(%a):(.+)$")
			if kind == "h" then
				wreckHouse(reg, id)
			elseif kind == "d" then
				wreckDeco(reg, tonumber(id))
			end
		end
	end
end

-- Les villageois rebâtissent ce qui a été cassé depuis assez longtemps
function Demolir.newDay()
	for _, reg in G.World.loaded do
		local w = reg.state.wrecked
		for key, day in w or {} do
			if G.world.day >= day + REBUILD_DAYS then
				w[key] = nil
				local kind, id = string.match(key, "^(%a):(.+)$")
				if kind == "h" then
					local h = reg.houses[id]
					if h and h.wrecked then
						local model = G.Util.clone(h.data.model)
						if model then
							model.Name = h.data.model
							model:SetAttribute("HouseId", id)
							local parent = h.model.Parent
							h.model:Destroy()
							G.World.place(model, h.data.x, Config.GROUND_Y, h.data.z, h.data.yaw, parent)
							h.model = model
							h.wrecked = nil
						end
					end
				elseif kind == "d" then
					local d = reg.plan.decos[tonumber(id)]
					local f = reg.folder and reg.folder:FindFirstChild("Decor")
					if d and f then
						local m = G.World.buildDeco(d, f)
						if m then
							m:SetAttribute("DecoIdx", tonumber(id))
						end
					end
				end
			end
		end
	end
end

-- Distance d'un joueur au bord de la boîte englobante d'un modèle
local function edgeDist(model: Model, pos: Vector3): number
	local cf, size = model:GetBoundingBox()
	local l = cf:PointToObjectSpace(pos)
	local dx = math.max(math.abs(l.X) - size.X / 2, 0)
	local dz = math.max(math.abs(l.Z) - size.Z / 2, 0)
	return math.sqrt(dx * dx + dz * dz)
end

-- Coup de hache / pioche dans le vide d'un arbre : y a-t-il quelque chose à casser devant ?
-- only : ne viser QUE ce modèle (clic sur un décor) ; tool nil = mains nues
function Demolir.smash(player: Player, tool: string?, only: Model?): boolean
	local root = G.Util.root(player)
	if not root then
		return false
	end
	local best, bd, kind, reg0, key, data = nil, only and 14 or 5, nil, nil, nil, nil
	local function consider(model: Model, k: string, reg, kk: string, extra)
		if not model or not model.Parent or (only and model ~= only) then
			return
		end
		local dist = edgeDist(model, root.Position)
		local dir = model:GetPivot().Position - root.Position
		local flat = Vector3.new(dir.X, 0, dir.Z)
		if dist < bd and (dist < 1.5 or flat.Magnitude < 0.1 or root.CFrame.LookVector:Dot(flat.Unit) > -0.2) then
			best, bd, kind, reg0, key, data = model, dist, k, reg, kk, extra
		end
	end
	for _, reg in G.World.loaded do
		for id, h in reg.houses or {} do
			if not h.wrecked then
				consider(h.model, "house", reg, "h:" .. id, id)
			end
		end
		local f = reg.folder and reg.folder:FindFirstChild("Decor")
		for _, m in f and f:GetChildren() or {} do
			local idx = m:GetAttribute("DecoIdx")
			if idx and m:IsA("Model") then
				consider(m, "deco", reg, "d:" .. idx, idx)
			end
		end
		for _, d in reg.state.placed or {} do
			if d.owner and not G.Util.owns(player, d.owner) then
				for _, m in reg.placedModels or {} do
					local p = m:GetPivot().Position
					if math.abs(p.X - d.x) < 0.2 and math.abs(p.Z - d.z) < 0.2 then
						consider(m, "placed", reg, "p:" .. d.id, d)
					end
				end
			end
		end
	end
	if not best then
		return false
	end
	if only and kind ~= "deco" then
		return false -- au clic : seulement le décor (maisons et objets posés : coup d'outil)
	end
	local tier = 0
	if tool then
		_, tier = G.Joueurs.bestTool(player, tool)
	end
	local power = math.max(1, tier)
	if tier == 0 then
		if kind == "deco" and SOFT[best.Name] then
			power = HAND_POWER
		elseif not tool then
			G.Util.toast(player, "Trop solide à mains nues : il faut une hache ou une pioche.")
			return true
		end
	end
	if tool and tier > 0 and G.Joueurs.wearTool then
		G.Joueurs.wearTool(player, tool)
	end
	G.Props.swing(player, tool)
	local pos = best:GetPivot().Position
	local hitPos = root.Position + (pos - root.Position).Unit * math.min((pos - root.Position).Magnitude, 4) + Vector3.new(0, 2, 0)
	chips(hitPos, kind == "house" and Color3.fromRGB(200, 186, 150) or Color3.fromRGB(150, 110, 70))
	-- vandalisme : si quelqu'un voit, c'est un crime (contre le propriétaire pour un objet posé)
	G.Law.crime(player, "vandalism", pos, kind == "placed" and data.owner or nil)
	hits[key] = (hits[key] or 0) + power
	local hp = (kind == "placed" and Config.ITEMS[data.item] and Config.ITEMS[data.item].hp) or HP[kind]
	G.Combat.popup(hitPos, math.floor(hits[key] + 0.5) .. "/" .. hp, Color3.fromRGB(230, 200, 150))
	best:SetAttribute("Usure", math.clamp(hits[key] / hp, 0, 1)) -- barre d'usure côté client
	if hits[key] < hp then
		return true
	end
	hits[key] = nil
	if kind == "house" then
		wreckHouse(reg0, data)
		reg0.state.wrecked = reg0.state.wrecked or {}
		reg0.state.wrecked[key] = G.world.day
		G.Joueurs.add(player, "planks", math.random(6, 12), true)
		G.Joueurs.add(player, "stone", math.random(4, 9), true)
		G.Joueurs.addSkillXp(player, "artisanat", 4)
	elseif kind == "deco" then
		local drop = DROPS[best.Name]
		best:Destroy()
		reg0.state.wrecked = reg0.state.wrecked or {}
		reg0.state.wrecked[key] = G.world.day
		if drop and Config.ITEMS[drop[1]] then
			G.Joueurs.add(player, drop[1], math.random(drop[2], drop[3]), true)
		else
			G.Joueurs.add(player, math.random() < 0.5 and "planks" or "stone", math.random(1, 3), true)
		end
	elseif kind == "placed" then
		-- l'objet est détruit (pas volé) ; son contenu tombe par terre… dans le sac du casseur
		for i, d in reg0.state.placed do
			if d == data then
				table.remove(reg0.state.placed, i)
				break
			end
		end
		for j, m in reg0.placedModels do
			if m == best then
				table.remove(reg0.placedModels, j)
				break
			end
		end
		for it, n in data.items or {} do
			G.Joueurs.add(player, it, n, true)
		end
		best:Destroy()
		local owner = G.Util.playerOf(data.owner)
		if owner then
			G.Util.toast(owner, "Quelqu'un a cassé ton " .. string.lower((Config.ITEMS[data.item] or { name = "objet" }).name) .. ".", "danger")
		end
		if G.Protection and G.Protection.log then
			G.Protection.log(data.owner, player.DisplayName .. " a cassé " .. ((Config.ITEMS[data.item] or { name = "un objet" }).name) .. ".", false)
		end
	end
	G.Joueurs.sync(player)
	return true
end

return Demolir
