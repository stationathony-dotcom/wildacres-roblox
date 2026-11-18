-- Parcelles (côté Minecraft du multi) : un « panneau de propriété » réserve un carré de terrain
-- autour de lui. AUCUNE limite de nombre : on agrandit son domaine tant qu'on peut payer, chaque
-- nouveau terrain coûtant plus cher (100 × n² or). Dedans, les autres ne peuvent ni construire ni
-- bêcher ; démonter ou voler chez quelqu'un est un crime (effraction / vol).
-- Les parcelles vivent dans G.world.players[uid].plots (sauvegardées avec le monde) et sont
-- recopiées dans ReplicatedStorage.Parcelles pour que l'interface affiche « Terrain de … ».

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parcelles = {}
local G, Config
local folder

Parcelles.HALF = 24 -- demi-côté en studs : 48 x 48 studs = 12 x 12 cases

function Parcelles.init(g)
	G = g
	Config = G.Config
	folder = ReplicatedStorage:FindFirstChild("Parcelles") or Instance.new("Folder")
	folder.Name = "Parcelles"
	folder.Parent = ReplicatedStorage
end

-- Toutes les parcelles d'un joueur (ancien format : une seule « plot »)
function Parcelles.plotsOf(rec)
	if rec.plot then
		rec.plots = rec.plots or {}
		table.insert(rec.plots, rec.plot)
		rec.plot = nil
	end
	rec.plots = rec.plots or {}
	return rec.plots
end

-- Recopie pour les clients (nom du propriétaire, centre, demi-côté)
function Parcelles.publish()
	if not G.world then
		return
	end
	folder:ClearAllChildren()
	for uid, rec in G.world.players do
		for i, plot in Parcelles.plotsOf(rec) do
			local c = Instance.new("Configuration")
			c.Name = "u" .. uid .. "_" .. i
			c:SetAttribute("OwnerId", tonumber(uid))
			c:SetAttribute("X", plot.x)
			c:SetAttribute("Z", plot.z)
			c:SetAttribute("Half", Parcelles.HALF)
			c:SetAttribute("Owner", plot.name or "?")
			c.Parent = folder
		end
	end
end

-- Parcelle qui contient une position : identifiant "u<UserId>", parcelle
function Parcelles.at(pos: Vector3): (string?, any)
	if not G.world then
		return nil, nil
	end
	local h = Parcelles.HALF
	for uid, rec in G.world.players do
		for _, p in Parcelles.plotsOf(rec) do
			if math.abs(pos.X - p.x) <= h and math.abs(pos.Z - p.z) <= h then
				return "u" .. uid, p
			end
		end
	end
	return nil, nil
end

-- Peut-on construire / bêcher ici ? (silent = sans message)
function Parcelles.canBuild(player: Player, pos: Vector3, silent: boolean?): boolean
	if Config.LIBRE.batirChezAutrui then
		return true -- monde libre : on bâtit partout ; aux propriétaires de se défendre
	end
	local owner, p = Parcelles.at(pos)
	if not owner or G.Util.owns(player, owner) or G.Util.trusted(player, owner, "batir") then
		return true
	end
	-- territoire de clan : les membres d'un même clan bâtissent ensemble
	local mine = G.Clans.clanOfUid(G.Util.pid(player))
	if mine and p and p.clan == mine then
		return true
	end
	if not silent then
		G.Util.toast(player, "🏡 Terrain de " .. (p.name or "quelqu'un") .. " : tu ne peux pas construire ici.")
	end
	return false
end

-- Lieu (village, ferme…) trop proche ?
local function nearPlace(pos: Vector3): string?
	local CELL, REGION = Config.CELL, Config.REGION
	local cx, cz = math.floor(pos.X / CELL), math.floor(pos.Z / CELL)
	local rx, rz = G.WG.regionOf(cx, cz)
	local margin = Parcelles.HALF / CELL + 4
	for qx = rx - 1, rx + 1 do
		for qz = rz - 1, rz + 1 do
			local poi = G.wg:poiOf(qx, qz)
			if poi and cx > poi.x0 - margin and cx < poi.x0 + poi.w + margin and cz > poi.z0 - margin and cz < poi.z0 + poi.d + margin then
				return G.WG.placeLabel(poi)
			end
		end
	end
	local _ = REGION
	return nil
end

function Parcelles.price(player: Player): number
	local n = #Parcelles.plotsOf(G.Mondes.playerRecord(player))
	return 100 * n * n
end

-- Planter son panneau : renvoie true si la parcelle est créée (le 1er terrain est gratuit,
-- les suivants coûtent 100 × n² or : on s'étend autant que ses moyens le permettent)
function Parcelles.create(player: Player, pos: Vector3): boolean
	local rec = G.Mondes.playerRecord(player)
	local mine = Parcelles.plotsOf(rec)
	local h = Parcelles.HALF
	local me = tostring(player.UserId)
	for uid, other in G.world.players do
		for _, p in Parcelles.plotsOf(other) do
			local gap = (uid == me) and h * 2 or h * 2 + 4 -- ses propres terrains peuvent se toucher
			if math.abs(pos.X - p.x) < gap and math.abs(pos.Z - p.z) < gap then
				G.Util.toast(player, uid == me and "Ce panneau chevaucherait un de tes terrains : recule d'au moins 12 cases." or ("Trop près du terrain de " .. (p.name or "quelqu'un") .. "."))
				return false
			end
		end
	end
	local price = Parcelles.price(player)
	if price > 0 and not G.Joueurs.has(player, "gold", price) then
		G.Util.toast(player, "Ton terrain n°" .. (#mine + 1) .. " coûte " .. price .. " 💰 (plus tu possèdes, plus c'est cher).")
		return false
	end
	local place = not Config.LIBRE.parcelleProcheVillage and nearPlace(pos)
	if place then
		G.Util.toast(player, "Trop près de " .. place .. " : installe-toi à l'écart.")
		return false
	end
	if price > 0 then
		G.Joueurs.take(player, "gold", price)
	end
	table.insert(mine, { x = math.floor(pos.X), z = math.floor(pos.Z), name = player.DisplayName, since = G.world.day })
	Parcelles.publish()
	G.Util.toast(player, "🏡 Ce terrain est à toi" .. (#mine > 1 and (" (domaine : " .. #mine .. " terrains)") or "") .. " ! À toi de le défendre : serrures, chiens, tourelles.", "big")
	return true
end

-- Démonter un panneau : le terrain correspondant est libéré
function Parcelles.removeAt(player: Player, x: number, z: number)
	local mine = Parcelles.plotsOf(G.Mondes.playerRecord(player))
	for i, p in mine do
		if math.abs(p.x - x) < 2 and math.abs(p.z - z) < 2 then
			table.remove(mine, i)
			Parcelles.publish()
			G.Util.toast(player, "Tu as libéré ce terrain.")
			return
		end
	end
end

-- Coins de la parcelle (piquets) autour du panneau
function Parcelles.decorate(model: Model, x: number, z: number)
	local h = Parcelles.HALF
	for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local px, pz = x + c[1] * h, z + c[2] * h
		local y = G.Util.groundY(px, pz)
		local stake = Instance.new("Part")
		stake.Name = "Piquet"
		stake.Size = Vector3.new(0.5, 3, 0.5)
		stake.Anchored = true
		stake.CanCollide = false
		stake.Material = Enum.Material.Wood
		stake.Color = Color3.fromRGB(120, 84, 52)
		stake.CFrame = CFrame.new(px, y + 1.5, pz)
		stake.Parent = model
		local flag = Instance.new("Part")
		flag.Name = "Fanion"
		flag.Size = Vector3.new(0.1, 0.7, 1)
		flag.Anchored = true
		flag.CanCollide = false
		flag.Material = Enum.Material.Fabric
		flag.Color = Color3.fromRGB(220, 70, 60)
		flag.CFrame = CFrame.new(px, y + 2.7, pz + 0.55)
		flag.Parent = model
	end
end

return Parcelles
