-- Tourelles de défense (monde libre : ce sont les joueurs qui protègent leurs terres, pas des règles).
--   · Arbalète de garde : portée 30, un tir / 3 s, 45 dégâts. Baliste de rempart : portée 42,
--     un tir / 5 s, tue d'un coup. Réglages : Config.TURRETS.
--   · Tirent sur un INTRUS : joueur debout sur une parcelle du propriétaire, qui n'est ni lui, ni de son
--     clan, ni de son groupe, ni autorisé (/autoriser). Personne n'est visé hors de ces terres.
--   · Marchent aussi propriétaire déconnecté (le monde tourne tant qu'il y a quelqu'un dans la région).
--   · Une munition par tir (carreaux, posés par [E] « Garnir ») ; vides, elles se taisent.
--   · Ligne de tir vérifiée (un mur protège) ; elles se cassent à la pioche / hache (Demolir, PV : ITEMS.hp).
--   · Cambrioleurs PNJ quand le propriétaire est loin : une tourelle garnie les fait fuir (repel).

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Tourelles = {}
local G, Config

local STEP = 0.4
local lastShot = {} -- id de l'objet posé -> os.clock()
local warned = {} -- "id:uid" -> os.clock() (journal du propriétaire, pas de spam)

-- liste des joueurs visés (remplaçable par un banc de test)
function Tourelles.players()
	return Players:GetPlayers()
end

local function isTurret(d): number?
	local info = Config.ITEMS[d.item]
	return info and info.turret or nil
end

-- l'intrus peut-il être visé par une tourelle de `owner` ?
local function friendly(player: Player, owner: string): boolean
	if G.Util.owns(player, owner) or G.Util.trusted(player, owner, "batir") or G.Util.trusted(player, owner, "coffres") then
		return true
	end
	local mine = G.Clans and G.Clans.clanOfUid and G.Clans.clanOfUid(G.Util.pid(player))
	if mine and mine == G.Clans.clanOfUid(owner) then
		return true
	end
	local op = G.Util.playerOf(owner)
	local g = op and G.Social.groupOf(player)
	return g ~= nil and g == G.Social.groupOf(op)
end
Tourelles.friendly = friendly

local function modelOf(reg, d): Model?
	for _, m in reg.placedModels or {} do
		local p = m:GetPivot().Position
		if math.abs(p.X - d.x) < 0.2 and math.abs(p.Z - d.z) < 0.2 then
			return m
		end
	end
	return nil
end

local function refreshPrompt(reg, d)
	local m = modelOf(reg, d)
	local pp = m and m.PrimaryPart and m.PrimaryPart:FindFirstChild("Invite_turret_load")
	if pp then
		local info = Config.ITEMS[d.item]
		local op = G.Util.playerOf(d.owner)
		pp.ObjectText = info.name .. (op and (" de " .. op.DisplayName) or "") .. " (" .. (d.ammo or 0) .. " 🎯)"
	end
end

-- trait du carreau (visible de tous) + la tête pivote vers la cible
local function shotFx(m: Model, from: Vector3, to: Vector3, heavy: boolean)
	local head = m:FindFirstChild("Tete", true)
	if head then
		-- pivote toutes les pièces « Tete… » autour de l'axe vertical de la tête
		local hp = head.Position
		local want = Vector3.new(to.X - hp.X, 0, to.Z - hp.Z)
		local cur = Vector3.new(head.CFrame.LookVector.X, 0, head.CFrame.LookVector.Z)
		if want.Magnitude > 0.5 and cur.Magnitude > 0.01 then
			local a = math.atan2(-want.X, -want.Z) - math.atan2(-cur.X, -cur.Z)
			local delta = CFrame.new(hp) * CFrame.Angles(0, a, 0) * CFrame.new(-hp)
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") and string.sub(p.Name, 1, 4) == "Tete" then
					p.CFrame = delta * p.CFrame
				end
			end
		end
	end
	local dist = (to - from).Magnitude
	local bolt = Instance.new("Part")
	bolt.Anchored, bolt.CanCollide, bolt.CanQuery, bolt.CanTouch = true, false, false, false
	bolt.Material = Enum.Material.Neon
	bolt.Color = heavy and Color3.fromRGB(255, 120, 60) or Color3.fromRGB(255, 230, 160)
	bolt.Size = Vector3.new(heavy and 0.35 or 0.18, heavy and 0.35 or 0.18, dist)
	bolt.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -dist / 2)
	bolt.Parent = workspace
	TweenService:Create(bolt, TweenInfo.new(0.35), { Transparency = 1 }):Play()
	Debris:AddItem(bolt, 0.4)
	G.Util.sfx("coup", from)
end

local function lineClear(from: Vector3, to: Vector3, ignore): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(from, to - from, params)
	return hit == nil
end

local function fire(reg, d, tier: number)
	local spec = Config.TURRETS[tier]
	local now = os.clock()
	if (d.ammo or 0) <= 0 or now - (lastShot[d.id] or 0) < spec.cooldown then
		return
	end
	local m = modelOf(reg, d)
	if not m then
		return
	end
	local head = m:FindFirstChild("Tete", true)
	local from = head and head.Position or (m:GetPivot().Position + Vector3.new(0, 3, 0))
	local best, bd = nil, spec.range
	for _, p in Tourelles.players() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local dist = (root.Position - from).Magnitude
			if dist < bd and G.Parcelles.at(root.Position) == d.owner and not friendly(p, d.owner)
				and lineClear(from, root.Position, { m, char }) then
				best, bd = p, dist
			end
		end
	end
	if not best then
		return
	end
	lastShot[d.id] = now
	d.ammo -= 1
	local root = G.Util.root(best)
	shotFx(m, from, root.Position, tier >= 2)
	G.Combat.hurtPlayer(best, spec.dmg, from)
	local op = G.Util.playerOf(d.owner)
	G.Util.toast(best, "🎯 " .. Config.ITEMS[d.item].name .. (op and (" de " .. op.DisplayName) or "") .. " : tu es sur ses terres !", "danger")
	local key = d.id .. ":" .. best.UserId
	if now - (warned[key] or 0) > 60 then
		warned[key] = now
		if G.Protection and G.Protection.log then
			G.Protection.log(d.owner, "🎯 Ta " .. string.lower(Config.ITEMS[d.item].name) .. " a tiré sur " .. best.DisplayName .. ".", false)
		end
	end
	refreshPrompt(reg, d)
end

function Tourelles.step()
	for _, reg in G.World.loaded do
		for _, d in reg.state and reg.state.placed or {} do
			local tier = isTurret(d)
			if tier then
				fire(reg, d, tier)
			end
		end
	end
end

-- [E] « Garnir de carreaux » : le propriétaire (ou un allié) charge depuis son sac
function Tourelles.load(player: Player, id: string)
	for _, reg in G.World.loaded do
		for _, d in reg.state.placed or {} do
			if d.id == id then
				local tier = isTurret(d)
				if not tier then
					return
				end
				if not friendly(player, d.owner) then
					G.Util.toast(player, "Ce n'est pas ta tourelle.")
					return
				end
				local spec = Config.TURRETS[tier]
				local room = spec.cap - (d.ammo or 0)
				local have = G.Joueurs.count(player, spec.ammo)
				local n = math.min(room, have)
				if n <= 0 then
					G.Util.toast(player, room <= 0 and "Elle est pleine." or ("Il te faut des " .. string.lower(Config.ITEMS[spec.ammo].name) .. " (atelier, ou boutique du village)."))
					return
				end
				G.Joueurs.take(player, spec.ammo, n)
				d.ammo = (d.ammo or 0) + n
				G.Util.toast(player, "🎯 +" .. n .. " " .. string.lower(Config.ITEMS[spec.ammo].name) .. " (" .. d.ammo .. " / " .. spec.cap .. ").")
				refreshPrompt(reg, d)
				G.Joueurs.sync(player)
				if G.Mondes and G.Mondes.saveSoon then
					G.Mondes.saveSoon(player)
				end
				return
			end
		end
	end
end

-- Cambrioleur PNJ simulé (propriétaire loin) : une tourelle garnie sur la parcelle le fait fuir
function Tourelles.repel(uid: string, plot): boolean
	local h = G.Parcelles.HALF
	for _, rs in G.world.regions do
		for _, d in rs.placed or {} do
			if isTurret(d) and d.owner == uid and (d.ammo or 0) > 0 and math.abs(d.x - plot.x) <= h + 6 and math.abs(d.z - plot.z) <= h + 6 then
				d.ammo -= 1
				if G.Protection and G.Protection.log then
					G.Protection.log(uid, "🎯 Ta tourelle a fait fuir un cambrioleur cette nuit.")
				end
				return true
			end
		end
	end
	return false
end

function Tourelles.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("turret_load", function(player, prompt)
		Tourelles.load(player, prompt:GetAttribute("Placed"))
	end)
	task.spawn(function()
		while not Tourelles.stopped do -- `stopped` : pour les bancs de test
			task.wait(STEP)
			if G.world and G.World and G.World.loaded then
				local ok, err = pcall(Tourelles.step)
				if not ok then
					warn("[WildAcres] tourelles : " .. tostring(err))
				end
			end
		end
	end)
end

return Tourelles
