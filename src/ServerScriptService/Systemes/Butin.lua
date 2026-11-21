-- Butin au sol (façon Minecraft / Fortnite) : ce qu'on récolte, mine, creuse ou prend sur une
-- créature TOMBE par terre au lieu d'aller droit dans le sac. On le ramasse :
--   · en cliquant / touchant l'objet, ou via l'invite [E] « Ramasser » ;
--   · avec [Q] (manette : Y) : tout ce qui est à portée d'un coup.
-- Règles :
--   · réservé 30 s à celui qui l'a obtenu (et à son groupe), puis à tout le monde ;
--   · disparaît au bout de 5 min ; au-delà de 400 objets par serveur, les plus vieux partent d'abord ;
--   · les objets identiques tombés au même endroit au même joueur s'empilent (un seul objet « ×n ») ;
--   · rien n'est sauvegardé (temporaire) ; si le propriétaire se déconnecte, son butin devient public.
-- Fonctionnement : `Butin.capture(joueur, position, ignorer, fn, ...)` exécute fn ; pendant ce temps,
-- tout `Joueurs.add` / `Joueurs.addGear` de ce joueur est redirigé au sol (Util.auSol l'enrobe).
-- Pêche, achats, fabrication, courrier, échanges, coffres : restent directs dans le sac.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Butin = {}
local G

local OWN_TIME = 30 -- secondes de réservation
local LIFE = 300 -- secondes avant disparition
local MERGE = 3.5 -- studs : même objet, même joueur → une seule pile
local MAX_DROPS = 400
local PICK_RANGE = 14 -- clic / invite (tolérance réseau)
local QUICK_RANGE = 10 -- touche [Q]
Butin.OWN_TIME, Butin.LIFE, Butin.QUICK_RANGE = OWN_TIME, LIFE, QUICK_RANGE

local QUALITY = {
	Color3.fromRGB(226, 214, 190), -- commun
	Color3.fromRGB(90, 220, 70), -- peu commun
	Color3.fromRGB(40, 130, 230), -- rare
	Color3.fromRGB(170, 70, 240), -- épique
	Color3.fromRGB(255, 150, 30), -- légendaire
}

local folder: Folder
local drops = {} -- id -> { id, item, n, gear, owner, until, t, pos, part }
local count = 0
local nextId = 0
local capture = {} -- joueur -> { pos, ignore }

-- ---------------------------------------------------------------- apparence

local function rarityOf(d): number
	if d.gear then
		return math.clamp((d.gear.rarity or 1) + 1, 1, 5)
	end
	local info = G.Config.ITEMS[d.item]
	return info and info.rarity or 1
end

local function refresh(d)
	local part = d.part
	if not part then
		return
	end
	local info = G.Config.ITEMS[d.item]
	local name = d.gear and d.gear.name or (info and info.name) or d.item
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ObjectText = name .. (d.n > 1 and (" ×" .. d.n) or "")
	end
	local n = part:FindFirstChild("Icone") and part.Icone:FindFirstChild("Nombre")
	if n then
		n.Text = d.n > 1 and ("×" .. d.n) or ""
	end
end

local function spawnPart(d)
	local info = G.Config.ITEMS[d.item]
	local r = rarityOf(d)
	local part = Instance.new("Part")
	part.Name = "Butin"
	part.Size = Vector3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.CastShadow = false
	part.Material = r >= 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic
	part.Color = QUALITY[r]
	part.Transparency = r >= 3 and 0.15 or 0
	part.CFrame = CFrame.new(d.pos)
	part:SetAttribute("ButinId", d.id)
	part:SetAttribute("Base", d.pos)
	part:SetAttribute("Rarete", r)

	local bb = Instance.new("BillboardGui")
	bb.Name = "Icone"
	bb.Size = UDim2.fromScale(2.4, 2.4)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.MaxDistance = 60
	bb.LightInfluence = 0
	bb.Parent = part
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(1, 1)
	icon.TextScaled = true
	icon.Text = d.gear and "⚔️" or (info and info.icon) or "📦"
	icon.Parent = bb
	local num = Instance.new("TextLabel")
	num.Name = "Nombre"
	num.BackgroundTransparency = 1
	num.AnchorPoint = Vector2.new(1, 1)
	num.Position = UDim2.fromScale(1.15, 1.05)
	num.Size = UDim2.fromScale(0.7, 0.42)
	num.Font = Enum.Font.GothamBold
	num.TextScaled = true
	num.TextColor3 = Color3.new(1, 1, 1)
	num.TextStrokeTransparency = 0.2
	num.Text = ""
	num.Parent = bb

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ramasser"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Action", "ramasser")
	prompt.Parent = part

	if r >= 4 then
		local light = Instance.new("PointLight")
		light.Color = QUALITY[r]
		light.Range = 8
		light.Brightness = 1.2
		light.Parent = part
	end
	d.part = part
	refresh(d)
	CollectionService:AddTag(part, "Butin")
	part.Parent = folder
end

local function remove(d)
	if drops[d.id] then
		drops[d.id] = nil
		count -= 1
	end
	if d.part then
		d.part:Destroy()
		d.part = nil
	end
end

-- point au sol près de `pos` (rayon vers le bas, en ignorant butin, personnages et la source)
local function groundSpot(pos: Vector3, ignore: Instance?): Vector3
	local a = math.random() * math.pi * 2
	local r = 1 + math.random() * 1.8
	local spot = pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = { folder }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ex, p.Character)
		end
	end
	if ignore then
		table.insert(ex, ignore)
	end
	params.FilterDescendantsInstances = ex
	params.IgnoreWater = false
	local hit = workspace:Raycast(spot + Vector3.new(0, 4, 0), Vector3.new(0, -40, 0), params)
	if hit then
		return hit.Position + Vector3.new(0, 0.7, 0)
	end
	return spot + Vector3.new(0, 0.7, 0)
end

local function trim()
	while count > MAX_DROPS do
		local oldest
		for _, d in drops do
			if not oldest or d.t < oldest.t then
				oldest = d
			end
		end
		if not oldest then
			return
		end
		remove(oldest)
	end
end

-- ---------------------------------------------------------------- poser

-- Pose un objet (ou un équipement `gear`) par terre. owner = joueur qui l'a obtenu (ou nil : public).
function Butin.drop(owner: Player?, pos: Vector3, item: string, n: number, gear, ignore: Instance?)
	if not folder or typeof(pos) ~= "Vector3" then
		return nil
	end
	n = math.floor(tonumber(n) or 1)
	if n <= 0 or n ~= n or n == math.huge then
		return nil
	end
	local now = os.clock()
	local ownerId = owner and owner.UserId or nil
	if not gear then
		for _, d in drops do
			local dx, dz = d.pos.X - pos.X, d.pos.Z - pos.Z
			if d.item == item and not d.gear and d.owner == ownerId and now - d.t < LIFE - 30 and dx * dx + dz * dz < (MERGE + 3) ^ 2 then
				d.n += n
				refresh(d)
				return d
			end
		end
	end
	nextId += 1
	local d = { id = nextId, item = gear and "gear" or item, n = gear and 1 or n, gear = gear, owner = ownerId, ownerP = owner, reserved = now + OWN_TIME, t = now }
	d.pos = groundSpot(pos, ignore)
	drops[d.id] = d
	count += 1
	spawnPart(d)
	trim()
	return d
end

-- ---------------------------------------------------------------- capture (récolte → au sol)

function Butin.capture(player: Player, pos: Vector3, ignore: Instance?, fn, ...)
	local prev = capture[player]
	capture[player] = { pos = pos, ignore = ignore }
	local res = table.pack(pcall(fn, ...))
	capture[player] = prev
	if not res[1] then
		error(res[2], 0)
	end
	return table.unpack(res, 2, res.n)
end

-- Appelé par Joueurs.add : true = l'objet est tombé au sol (rien dans le sac)
function Butin.redirect(player: Player, item: string, n: number): boolean
	local c = capture[player]
	if not c then
		return false
	end
	return Butin.drop(player, c.pos, item, n, nil, c.ignore) ~= nil
end

function Butin.redirectGear(player: Player, gear): boolean
	local c = capture[player]
	if not c then
		return false
	end
	return Butin.drop(player, c.pos, "gear", 1, gear, c.ignore) ~= nil
end

-- ---------------------------------------------------------------- ramasser

local function sameGroup(a: Player, b: Player?): boolean
	if not b then
		return false
	end
	local ga = G.Social.groupOf(a)
	return ga ~= nil and ga == G.Social.groupOf(b)
end

local function canTake(player: Player, d): boolean
	if not d.owner or d.owner == player.UserId or os.clock() >= d.reserved then
		return true
	end
	return sameGroup(player, d.ownerP)
end

local function give(player: Player, d)
	remove(d) -- d'abord retirer (jamais deux ramassages du même objet)
	if d.gear then
		G.Joueurs.addGear(player, d.gear)
	else
		G.Joueurs.add(player, d.item, d.n)
	end
end

function Butin.pick(player: Player, id: number): boolean
	local d = drops[tonumber(id) or -1]
	local root = G.Util.root(player)
	if not d or not root or capture[player] then
		return false
	end
	if (root.Position - d.pos).Magnitude > PICK_RANGE then
		G.Util.toast(player, "Trop loin pour le ramasser : approche-toi.")
		return false
	end
	if not canTake(player, d) then
		G.Util.toast(player, "Pas encore : ce butin revient d'abord à celui qui l'a obtenu.")
		return false
	end
	give(player, d)
	if G.Util.sfx then
		G.Util.sfx("ramasser", d.pos) -- on entend ce qu'on ramasse
	end
	return true
end

function Butin.pickAll(player: Player): number
	local root = G.Util.root(player)
	if not root or capture[player] then
		return 0
	end
	local list, blocked = {}, false
	for _, d in drops do
		if (root.Position - d.pos).Magnitude <= QUICK_RANGE then
			if canTake(player, d) then
				table.insert(list, d)
			else
				blocked = true
			end
		end
	end
	for _, d in list do
		give(player, d)
	end
	if #list > 0 then
		if G.Util.sfx then
			G.Util.sfx("ramasser", root.Position) -- un seul bruit pour la brassée
		end
		if G.Util.geste then
			G.Util.geste(player, "cueillir")
		end
	end
	if #list == 0 and blocked then
		G.Util.toast(player, "Pas encore : ce butin revient d'abord à celui qui l'a obtenu.")
	end
	return #list
end

function Butin.count(): number
	return count
end

function Butin.list()
	return drops
end

-- ---------------------------------------------------------------- démarrage

function Butin.init(g)
	G = g
	folder = workspace:FindFirstChild("ButinAuSol") or Instance.new("Folder")
	folder.Name = "ButinAuSol"
	folder.Parent = workspace
	G.Interact.onPrompt("ramasser", function(player, prompt)
		local part = prompt.Parent
		Butin.pick(player, part and part:GetAttribute("ButinId"))
	end)
	G.Interact.onAction("ramasser", function(player, data)
		Butin.pick(player, data.id)
	end)
	G.Interact.onAction("ramasser_tout", function(player)
		Butin.pickAll(player)
	end)
	Players.PlayerRemoving:Connect(function(p)
		capture[p] = nil
		for _, d in drops do
			if d.owner == p.UserId then
				d.reserved = 0 -- son butin devient public
				d.ownerP = nil
			end
		end
	end)
	task.spawn(function()
		while folder.Parent do
			task.wait(5)
			local now = os.clock()
			for _, d in drops do
				if now - d.t > LIFE then
					remove(d)
				end
			end
		end
	end)
end

return Butin
