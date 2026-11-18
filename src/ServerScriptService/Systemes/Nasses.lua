-- Nasses (étape 8C) : un panier d'osier lesté qu'on pose dans l'eau devant soi. Chaque matin il
-- attrape un poisson (deux s'il est appâté), jusqu'à 3 en attente : « Relever » vide la prise,
-- « Reprendre » [R] la remet dans le sac. Relever la nasse d'un autre = vol (sauf autorisé).
-- Peu nombreuses (6 par joueur et par monde) : toutes posées au démarrage, comme les barques.
-- État : G.world.extra.nasses[id] = { o = propriétaire, x, z, n = prises en attente, b = appâtée }

local Nasses = {}
local G, Config
local MAX_CATCH = 3
local PER_PLAYER = 6
local models = {} -- id -> modèle

local function store()
	G.world.extra = G.world.extra or {}
	G.world.extra.nasses = G.world.extra.nasses or {}
	return G.world.extra.nasses
end

local function folder()
	local f = workspace:FindFirstChild("Nasses")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Nasses"
		f.Parent = workspace
	end
	return f
end

local function refresh(id: string)
	local m, d = models[id], store()[id]
	if not m or not d then
		return
	end
	local pr = m:FindFirstChild("Invite_nasse", true)
	if pr then
		pr.ActionText = (d.n or 0) > 0 and ("Relever (" .. d.n .. " 🐟)") or "Vide pour l'instant"
		pr.Enabled = (d.n or 0) > 0
	end
	local fish = m:FindFirstChild("Prise")
	if fish then
		fish.Transparency = (d.n or 0) > 0 and 0 or 1
	end
end

local function spawn(id: string, d)
	local y = Config.WATER_Y
	local m = Instance.new("Model")
	m.Name = "Nasse"
	local function P(name, size, cf, color, mat, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat
		p.Anchored = true
		p.CanCollide = false
		if shape then
			p.Shape = shape
		end
		p.Parent = m
		return p
	end
	local base = CFrame.new(d.x, y, d.z)
	local body = P("Panier", Vector3.new(2.6, 2.2, 2.2), base * CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(150, 116, 66), Enum.Material.Fabric, Enum.PartType.Cylinder)
	m.PrimaryPart = body
	P("Goulot", Vector3.new(0.8, 1.4, 1.4), base * CFrame.new(1.5, -0.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(120, 92, 52), Enum.Material.Fabric, Enum.PartType.Cylinder)
	P("Flotteur", Vector3.new(0.8, 0.8, 0.8), base * CFrame.new(0, 0.35, 0), Color3.fromRGB(196, 64, 48), Enum.Material.Wood, Enum.PartType.Ball)
	P("Corde", Vector3.new(0.12, 1.2, 0.12), base * CFrame.new(0, -0.2, 0), Color3.fromRGB(190, 170, 120), Enum.Material.Fabric)
	P("Prise", Vector3.new(0.9, 0.35, 0.4), base * CFrame.new(0.2, 0.05, 0.6), Color3.fromRGB(150, 170, 190), Enum.Material.SmoothPlastic)
	local owner = G.Util.playerOf(d.o)
	G.Util.prompt(body, "nasse", "Relever", "Nasse" .. (owner and (" de " .. owner.DisplayName) or ""), { data = { Nasse = id }, dist = 10, hold = 0.4 })
	G.Util.prompt(body, "nasse_prendre", "Reprendre", "Nasse", { data = { Nasse = id }, dist = 10, key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonY, hold = 0.6 })
	m.Parent = folder()
	models[id] = m
	refresh(id)
end

function Nasses.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("nasse", function(player, prompt)
		Nasses.lift(player, prompt:GetAttribute("Nasse"))
	end)
	G.Interact.onPrompt("nasse_prendre", function(player, prompt)
		Nasses.pickup(player, prompt:GetAttribute("Nasse"))
	end)
end

function Nasses.start()
	for id, d in store() do
		if not models[id] then
			spawn(id, d)
		end
	end
end

function Nasses.countOf(owner: string): number
	local n = 0
	for _, d in store() do
		if d.o == owner then
			n += 1
		end
	end
	return n
end

-- Utiliser l'objet : poser la nasse dans l'eau devant soi (pas collée à une autre)
function Nasses.place(player: Player): boolean
	local root = G.Util.root(player)
	if not root then
		return false
	end
	local me = G.Util.pid(player)
	if Nasses.countOf(me) >= PER_PLAYER then
		G.Util.toast(player, "Tu as déjà " .. PER_PLAYER .. " nasses posées dans ce monde : reprends-en une avant.")
		return false
	end
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = look.Magnitude > 0.1 and look.Unit or Vector3.new(0, 0, -1)
	for dist = 5, 12, 1.5 do
		local p = root.Position + look * dist
		if G.Util.isWater(p.X, p.Z) and G.Util.isWater(p.X + look.X * 3, p.Z + look.Z * 3) then
			for _, d in store() do
				if (Vector3.new(d.x, 0, d.z) - Vector3.new(p.X, 0, p.Z)).Magnitude < 8 then
					G.Util.toast(player, "Il y a déjà une nasse tout près : les poissons ne suffiraient pas aux deux.")
					return false
				end
			end
			if not G.Joueurs.take(player, "nasse", 1) then
				return false
			end
			local id = G.Util.newId("ns")
			local d = { o = me, x = math.floor(p.X * 10) / 10, z = math.floor(p.Z * 10) / 10, n = 0, b = G.Joueurs.take(player, "bait", 1) or nil }
			store()[id] = d
			spawn(id, d)
			G.Util.sfx("pelle", p)
			G.Joueurs.sync(player)
			G.Mondes.saveSoon(player)
			G.Util.toast(player, "🧺 Nasse posée" .. (d.b and " et appâtée" or "") .. ". Repasse demain relever la prise.", "gain")
			return true
		end
	end
	G.Util.toast(player, "Mets-toi face à l'eau pour y poser la nasse.")
	return false
end

-- Relever : la prise en attente passe dans le sac (vol si ce n'est pas la sienne)
function Nasses.lift(player: Player, id: string?)
	local d = type(id) == "string" and store()[id]
	local root = G.Util.root(player)
	if not d or not root or (Vector3.new(d.x, root.Position.Y, d.z) - root.Position).Magnitude > 14 or (d.n or 0) <= 0 then
		return
	end
	local at = Vector3.new(d.x, Config.WATER_Y, d.z)
	if not G.Util.owns(player, d.o) and not G.Util.trusted(player, d.o, "coffres") then
		G.Law.crime(player, "theft", at, d.o)
	end
	for _ = 1, d.n do
		local i = G.Fishing.pick(player, d.b, at)
		G.Joueurs.add(player, "fish_" .. i, 1, true)
		G.Social.collect(player, "fish", tostring(i))
	end
	G.Joueurs.addSkillXp(player, "peche", 3 * d.n)
	d.n = 0
	-- réappâtée d'office s'il reste des appâts dans le sac du propriétaire qui relève
	if G.Util.owns(player, d.o) and not d.b then
		d.b = G.Joueurs.take(player, "bait", 1) or nil
	end
	refresh(id :: string)
	G.Util.sfx("coffre", at, player)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
end

function Nasses.pickup(player: Player, id: string?)
	local d = type(id) == "string" and store()[id]
	if not d then
		return
	end
	if not G.Util.owns(player, d.o) then
		G.Util.toast(player, "Ce n'est pas ta nasse.")
		return
	end
	if (d.n or 0) > 0 then
		Nasses.lift(player, id)
	end
	if models[id] then
		models[id]:Destroy()
		models[id] = nil
	end
	store()[id] = nil
	G.Joueurs.add(player, "nasse", 1, true)
	if d.b then
		G.Joueurs.add(player, "bait", 1, true)
	end
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	G.Util.toast(player, "🧺 Nasse reprise dans ton sac.", "gain")
end

-- Chaque matin : une prise (deux si appâtée — l'appât est alors mangé), plafonnée
function Nasses.newDay()
	for id, d in store() do
		local add = d.b and 2 or 1
		d.b = nil
		d.n = math.min(MAX_CATCH, (d.n or 0) + add)
		refresh(id)
	end
end

return Nasses
