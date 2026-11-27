-- Nids (étape 9A : traces de la faune). Dans la nature (régions sans village ni lieu notable), un
-- nid d'oiseau posé au sol entre les herbes : « Dénicher » donne des plumes, parfois un œuf, et le
-- nid se regarnit au bout de NEST_DAYS jours. Les plumes servent (plume d'écriture, coiffe à plumes),
-- les œufs aussi (cuisine) : une petite raison de plus de flâner hors des sentiers.
-- Couche posée par-dessus la génération, avec sa propre graine (n'altère pas les mondes existants).
-- État : reg.state.nids[id] = jour de la dernière visite.

local Nids = {}
local G, Config
local NEST_DAYS = 4
local CHANCE = 0.6 -- probabilité qu'une région sauvage ait un nid

-- Couleurs d'œufs et de brindilles selon le biome (un nid de neige n'a pas l'air d'un nid du désert)
local LOOK = {
	prairie = { twig = Color3.fromRGB(150, 120, 80), egg = Color3.fromRGB(190, 214, 230) },
	foret = { twig = Color3.fromRGB(110, 84, 56), egg = Color3.fromRGB(226, 218, 196) },
	neige = { twig = Color3.fromRGB(170, 160, 150), egg = Color3.fromRGB(240, 240, 245) },
	desert = { twig = Color3.fromRGB(196, 170, 120), egg = Color3.fromRGB(214, 190, 150) },
	marais = { twig = Color3.fromRGB(96, 96, 60), egg = Color3.fromRGB(170, 196, 150) },
}

function Nids.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("nid", function(player, prompt)
		Nids.search(player, prompt:GetAttribute("Nid"))
	end)
end

local function build(parent, pos: Vector3, biome: string, full: boolean)
	local look = LOOK[biome] or LOOK.prairie
	local m = Instance.new("Model")
	m.Name = "Nid"
	local function P(size, cf, color, mat, shape)
		local p = Instance.new("Part")
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		if shape then
			p.Shape = shape
		end
		p.Parent = m
		return p
	end
	local base = CFrame.new(pos)
	m.PrimaryPart = P(Vector3.new(0.5, 2.2, 2.2), base * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), look.twig, Enum.Material.Grass, Enum.PartType.Cylinder)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		P(Vector3.new(0.18, 0.18, 1.3), base * CFrame.Angles(0, a, 0) * CFrame.new(0.9, 0.45, 0) * CFrame.Angles(math.rad(20), 0, 0), look.twig:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Wood)
	end
	if full then
		for k = 0, 2 do
			local a = k * 2.1
			local egg = P(Vector3.new(0.45, 0.6, 0.45), base * CFrame.new(math.cos(a) * 0.35, 0.65, math.sin(a) * 0.35), look.egg, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			egg.Name = "Oeuf"
		end
		local f = P(Vector3.new(0.08, 0.9, 0.3), base * CFrame.new(0.5, 0.8, -0.3) * CFrame.Angles(0, 0, math.rad(35)), Color3.fromRGB(230, 230, 230), Enum.Material.SmoothPlastic)
		f.Name = "Plume"
	end
	m.Parent = parent
	return m
end

local function render(reg, n)
	if n.model then
		n.model:Destroy()
	end
	local last = reg.state.nids and reg.state.nids[n.id]
	local full = not last or G.world.day - last >= NEST_DAYS
	n.model = build(reg.nidFolder, n.pos, n.biome, full)
	if full then
		local pr = G.Util.prompt(n.model.PrimaryPart, "nid", "Dénicher", "Nid", { hold = 0.5, dist = 7 })
		pr:SetAttribute("Nid", n.id)
	end
end

function Nids.onRegionLoad(reg)
	reg.nids = {}
	if reg.plan.poi then
		return -- villages, ruines, donjons… : pas de nid au milieu
	end
	local rng = Random.new(G.WG.hash(G.world.seed, "nids", reg.rx, reg.rz))
	if rng:NextNumber() > CHANCE then
		return
	end
	local span = Config.CELL * Config.REGION
	for _ = 1, 10 do
		local x = reg.rx * span + rng:NextNumber(16, span - 16)
		local z = reg.rz * span + rng:NextNumber(16, span - 16)
		if not G.Util.isWater(x, z) and not G.Util.isWater(x + 6, z) and not G.Util.isWater(x, z + 6) then
			local y = G.Util.groundY(x, z)
			local slope = math.abs(G.Util.groundY(x + 3, z) - y) + math.abs(G.Util.groundY(x, z + 3) - y)
			if slope < 2.5 and y > Config.WATER_Y + 1 then
				local folder = Instance.new("Folder")
				folder.Name = "Nids"
				folder.Parent = reg.folder
				reg.nidFolder = folder
				local n = { id = "nid" .. reg.rx .. "_" .. reg.rz, pos = Vector3.new(x, y, z), biome = G.Clock.biomeAt(Vector3.new(x, 0, z)) }
				table.insert(reg.nids, n)
				render(reg, n)
				return
			end
		end
	end
end

local function find(id: string)
	for _, reg in G.World.loaded do
		for _, n in reg.nids or {} do
			if n.id == id then
				return n, reg
			end
		end
	end
	return nil, nil
end

function Nids.search(player: Player, id: string?)
	local n, reg = nil, nil
	if type(id) == "string" then
		n, reg = find(id)
	end
	local root = G.Util.root(player)
	if not n or not root or (n.pos - root.Position).Magnitude > 12 then
		return
	end
	reg.state.nids = reg.state.nids or {}
	local last = reg.state.nids[n.id]
	if last and G.world.day - last < NEST_DAYS then
		return
	end
	reg.state.nids[n.id] = G.world.day
	local feathers = math.random(1, 3)
	G.Joueurs.add(player, "feather", feathers, true)
	local egg = math.random() < 0.5
	if egg then
		G.Joueurs.add(player, "egg", 1, true)
	end
	-- œuf de monture (Shared/Ecurie.OEUFS, 27/11) : rare, selon le biome du nid
	local okEc, Ecurie = pcall(require, game:GetService("ReplicatedStorage").Shared.Ecurie)
	local biome = G.Clock and rawget(G.Clock, "biomeAt") and G.Clock.biomeAt(n.pos)
	for _, e in (okEc and biome and Ecurie.OEUFS[biome]) or {} do
		local id = Ecurie.oeufId(e[1])
		if G.Config.ITEMS[id] and math.random() < e[2] * 5 then
			G.Joueurs.add(player, id, 1, true)
			G.Util.toast(player, "✨ Au fond du nid, un œuf qui n'est pas d'ici… " .. G.Config.ITEMS[id].name .. " !", "big")
			break
		end
	end
	G.Joueurs.addSkillXp(player, "elevage", 2)
	G.Util.sfx("coffre", n.pos, player)
	G.Util.toast(player, "🥚 Tu déniches " .. feathers .. " plume" .. (feathers > 1 and "s" or "") .. (egg and " et un œuf" or "") .. ". L'oiseau reviendra pondre.", "gain")
	render(reg, n)
	G.Joueurs.sync(player)
end

-- Chaque matin, les nids regarnis réapparaissent pleins
function Nids.newDay()
	for _, reg in G.World.loaded do
		for _, n in reg.nids or {} do
			local last = reg.state.nids and reg.state.nids[n.id]
			if last and G.world.day - last == NEST_DAYS then
				render(reg, n)
			end
		end
	end
end

-- Pour les tests : nids des régions chargées
function Nids.list()
	local out = {}
	for _, reg in G.World.loaded do
		for _, n in reg.nids or {} do
			table.insert(out, { id = n.id, x = math.floor(n.pos.X), y = math.floor(n.pos.Y), z = math.floor(n.pos.Z), biome = n.biome })
		end
	end
	return out
end

return Nids
