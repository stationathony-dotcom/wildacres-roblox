-- Avant-postes de clan (étape 15B). Un membre d'un clan plante une « Bannière de clan » en pleine
-- nature : c'est un avant-poste.
--   · Avantage : point de réapparition pour les membres du clan qui n'ont pas de lit dans ce monde.
--   · Entretien : il consomme chaque jour des vivres (n'importe quelle nourriture) déposés par les
--     membres ; le N-ième avant-poste d'un clan en consomme N (pas de plafond, mais ça coûte).
--     Sans vivres, il perd de sa solidité chaque jour jusqu'à tomber : une domination ne peut pas
--     devenir définitive si personne ne l'entretient.
--   · Contestation : n'importe qui d'autre peut l'abattre (invite maintenue, 12 coups) ; les membres
--     du clan en ligne sont prévenus quand leur bannière est attaquée. Pas de guerre déclarée.
--   · Interdit à moins de 220 studs d'un village, 300 de l'arrivée, sur une route ou dans l'eau
--     (lieux publics et passages toujours libres).
-- Données : G.world.extra.avantpostes (sauvegardé avec le monde).

local Avantpostes = {}
local G, Config

local HP_MAX = 12
local FOOD_STOCK_MAX = 60
local list = {} -- id -> { data, model, prompts }

local function all()
	G.world.extra = G.world.extra or {}
	G.world.extra.avantpostes = G.world.extra.avantpostes or {}
	return G.world.extra.avantpostes
end

-- Clan du joueur (sans attendre) ; wantTag = aller chercher le tag (peut lire le DataStore des clans)
local function clanOf(player: Player, wantTag: boolean?)
	local prof = G.Joueurs.get(player)
	if not prof or not prof.clan then
		return nil, nil
	end
	if not wantTag then
		return prof.clan, nil
	end
	local d = G.Clans.of and G.Clans.of(player)
	return prof.clan, d and d.tag or "?"
end

local function build(d): Model
	local m = Instance.new("Model")
	m.Name = "AvantPoste"
	local function p(name, size, cf, color, mat)
		local x = Instance.new("Part")
		x.Name = name
		x.Size = size
		x.CFrame = cf
		x.Color = color
		x.Material = mat
		x.Anchored = true
		x.Parent = m
		return x
	end
	local base = CFrame.new(d.x, d.y, d.z)
	local mat = p("Mat", Vector3.new(0.6, 14, 0.6), base * CFrame.new(0, 7, 0), Color3.fromRGB(84, 56, 36), Enum.Material.Wood)
	m.PrimaryPart = mat
	p("Traverse", Vector3.new(5, 0.4, 0.4), base * CFrame.new(2.3, 13.3, 0), Color3.fromRGB(84, 56, 36), Enum.Material.Wood)
	local cloth = p("Etendard", Vector3.new(4.4, 6, 0.15), base * CFrame.new(2.4, 10.1, 0), Color3.fromRGB(150, 40, 40), Enum.Material.Fabric)
	cloth.CanCollide = false
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "[" .. (d.tag or "?") .. "]"
		t.TextScaled = true
		t.Font = Enum.Font.Fondamento
		t.TextColor3 = Color3.fromRGB(240, 210, 120)
		t.Parent = sg
		sg.Parent = cloth
	end
	p("Pierres", Vector3.new(3, 1, 3), base * CFrame.new(0, 0.4, 0), Color3.fromRGB(128, 128, 134), Enum.Material.Cobblestone)
	p("Caisse", Vector3.new(2, 2, 2), base * CFrame.new(-2.2, 1, 1.2), Color3.fromRGB(170, 125, 80), Enum.Material.WoodPlanks)
	local folder = workspace:FindFirstChild("AvantPostes") or Instance.new("Folder")
	folder.Name = "AvantPostes"
	folder.Parent = workspace
	m.Parent = folder
	return m
end

local function refresh(e)
	local d = e.data
	e.model.Etendard.Transparency = 0.6 * (1 - d.hp / HP_MAX) -- étendard délavé quand il s'abîme
	e.feed.ObjectText = "[" .. d.tag .. "] vivres " .. d.food .. " · solidité " .. d.hp .. "/" .. HP_MAX
	e.hit.ObjectText = e.feed.ObjectText
end

local function spawnOne(id: string, d)
	local m = build(d)
	m:SetAttribute("AvantPoste", id)
	local e = { id = id, data = d, model = m }
	e.feed = G.Util.prompt(m.PrimaryPart, "ap_ravitailler", "Ravitailler (5 vivres)", "", { dist = 10 })
	e.feed:SetAttribute("AP", id)
	e.hit = G.Util.prompt(m.PrimaryPart, "ap_abattre", "Abattre la bannière", "", { dist = 10, hold = 1.2, key = Enum.KeyCode.R })
	e.hit:SetAttribute("AP", id)
	list[id] = e
	refresh(e)
end

local function remove(id: string)
	local e = list[id]
	if e then
		e.model:Destroy()
		list[id] = nil
	end
	all()[id] = nil
end

function Avantpostes.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("ap_ravitailler", function(player, prompt)
		Avantpostes.feed(player, prompt:GetAttribute("AP"))
	end)
	G.Interact.onPrompt("ap_abattre", function(player, prompt)
		Avantpostes.hit(player, prompt:GetAttribute("AP"))
	end)
end

function Avantpostes.start()
	for id, d in all() do
		if not list[id] then
			spawnOne(id, d)
		end
	end
end

-- Utiliser l'objet « Bannière de clan »
function Avantpostes.plant(player: Player): boolean
	local clan, tag = clanOf(player, true)
	local root = G.Util.root(player)
	if not clan or not root then
		G.Util.toast(player, "Il faut faire partie d'un clan pour planter sa bannière.")
		return false
	end
	local pos = root.Position + root.CFrame.LookVector * 4
	local CELL = Config.CELL
	local cx, cz = math.floor(pos.X / CELL), math.floor(pos.Z / CELL)
	local rx, rz = G.WG.regionOf(cx, cz)
	local reg = G.World.loaded[rx .. "," .. rz]
	if not reg or G.Util.isWater(pos.X, pos.Z) then
		G.Util.toast(player, "Pas ici.")
		return false
	end
	local plan = reg.plan
	local k = G.WG.idx(cx - plan.x0, cz - plan.z0)
	if plan.roadD[k] and plan.roadD[k] < 4 then
		G.Util.toast(player, "Les routes restent libres : plante ta bannière à l'écart.")
		return false
	end
	if (pos - G.Game.spawnPos()).Magnitude < 300 then
		G.Util.toast(player, "Trop près de l'arrivée : c'est un lieu public.")
		return false
	end
	for _, v in (G.world.extra and G.world.extra.villages) or {} do
		if v.cx and (Vector3.new(v.cx, pos.Y, v.cz) - pos).Magnitude < 220 then
			G.Util.toast(player, "Trop près d'un village : les villages n'appartiennent à aucun clan.")
			return false
		end
	end
	for _, d in all() do
		if (Vector3.new(d.x, pos.Y, d.z) - pos).Magnitude < 150 then
			G.Util.toast(player, "Un autre avant-poste est trop près.")
			return false
		end
	end
	if not G.Joueurs.take(player, "banniere", 1) then
		return false
	end
	local id = G.Util.newId("ap")
	local d = { clan = clan, tag = tag, x = pos.X, y = G.Util.groundY(pos.X, pos.Z), z = pos.Z, hp = HP_MAX, food = 10, day = G.world.day, by = player.DisplayName }
	all()[id] = d
	spawnOne(id, d)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	G.Economie.record(player, "avant_poste", id .. " [" .. tag .. "]")
	G.Util.toast(player, "🚩 Avant-poste [" .. tag .. "] planté ! Les membres du clan y réapparaissent. Pense aux vivres.", "big")
	return true
end

function Avantpostes.feed(player: Player, id: string?)
	local e = id and list[id]
	if not e then
		return
	end
	local clan = clanOf(player)
	if clan ~= e.data.clan then
		G.Util.toast(player, "Ce n'est pas la bannière de ton clan.")
		return
	end
	local prof = G.Joueurs.get(player)
	local given = 0
	for item, n in prof.inv do
		local info = Config.ITEMS[item]
		if info and info.food and n > 0 and given < 5 then
			local k = math.min(n, 5 - given, FOOD_STOCK_MAX - e.data.food)
			if k > 0 and G.Joueurs.take(player, item, k) then
				given += k
				e.data.food += k
			end
		end
	end
	if given == 0 then
		G.Util.toast(player, e.data.food >= FOOD_STOCK_MAX and "Les réserves sont pleines." or "Il te faut de la nourriture dans ton sac.")
		return
	end
	e.data.hp = math.min(HP_MAX, e.data.hp + 2)
	refresh(e)
	G.Joueurs.sync(player)
	G.Util.toast(player, "🍞 +" .. given .. " vivres pour l'avant-poste.", "gain")
end

function Avantpostes.hit(player: Player, id: string?)
	local e = id and list[id]
	if not e then
		return
	end
	if clanOf(player) == e.data.clan then
		G.Util.toast(player, "C'est la bannière de ton clan !")
		return
	end
	e.data.hp -= 1
	G.Util.sfx("hache", e.model.PrimaryPart.Position)
	-- les membres du clan en ligne l'apprennent (c'est leur bannière : ils « le sentent »)
	if not e.warnedAt or os.clock() - e.warnedAt > 60 then
		e.warnedAt = os.clock()
		for _, p in G.Game.players() do
			if clanOf(p) == e.data.clan then
				G.Util.toast(p, "⚔️ La bannière [" .. e.data.tag .. "] est attaquée !", "danger")
			end
		end
	end
	if e.data.hp <= 0 then
		G.Economie.record(player, "avant_poste_abattu", id .. " [" .. e.data.tag .. "]")
		G.Util.toast(player, "🚩 Bannière [" .. e.data.tag .. "] abattue.", "big")
		remove(id)
		G.Mondes.saveSoon(player)
		return
	end
	refresh(e)
end

-- Entretien quotidien : vivres consommés, déclin sans vivres
function Avantpostes.newDay()
	local byClan = {}
	for id, d in all() do
		byClan[d.clan] = byClan[d.clan] or {}
		table.insert(byClan[d.clan], id)
	end
	for _, ids in byClan do
		table.sort(ids)
		for rank, id in ids do
			local d = all()[id]
			if d.food >= rank then
				d.food -= rank
			else
				d.food = 0
				d.hp -= 3
			end
			if d.hp <= 0 then
				remove(id)
			elseif list[id] then
				refresh(list[id])
			end
		end
	end
end

-- Réapparition : l'avant-poste de son clan le plus proche de pos (nil s'il n'y en a pas)
function Avantpostes.respawnFor(player: Player, pos: Vector3?): Vector3?
	local clan = clanOf(player)
	if not clan then
		return nil
	end
	local best, bd = nil, math.huge
	for _, d in all() do
		if d.clan == clan then
			local p = Vector3.new(d.x + 4, d.y, d.z + 4)
			local dist = pos and (p - pos).Magnitude or 0
			if dist < bd then
				best, bd = p, dist
			end
		end
	end
	return best
end

return Avantpostes
