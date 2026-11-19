-- Barques (étape 16B). Objet « Barque » fabriqué à l'atelier ; utilisé au bord de l'eau, il se pose
-- sur l'eau devant soi. Deux places : le banc du rameur (propriétaire seulement) et la place du
-- passager (tout le monde). Le serveur fait avancer la barque d'après les touches du rameur
-- (VehicleSeat.Throttle / Steer) : rien de ce que le client envoie ne déplace le bateau sans contrôle.
--   · avance seulement sur l'eau : la barque s'échoue doucement sur la rive (petit choc) ;
--   · l'orage la ralentit, le vent la fait tanguer ;
--   · le propriétaire la reprend (invite maintenue) quand personne n'est dedans ;
--   · sauvegardée avec le monde (G.world.extra.barques), elle reste où on l'a laissée.

local Barques = {}
local G, Config
local Players = game:GetService("Players")

local SPEED = 16 -- studs/s
local TURN = 1.1 -- rad/s
-- 18/11 : le voilier, plus grand, va bien plus vite au large mais vire moins sec
local KINDS = {
	barque = { name = "Barque", speed = SPEED, turn = TURN },
	voilier = { name = "Voilier", speed = 28, turn = 0.75 },
}
local list = {} -- id -> { data, model, seat, pass, speed, yaw }

local function store()
	G.world.extra = G.world.extra or {}
	G.world.extra.barques = G.world.extra.barques or {}
	return G.world.extra.barques
end

local BOIS = Color3.fromRGB(122, 84, 52)
local BOIS_F = Color3.fromRGB(84, 56, 36)

local function part(m: Model, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.WoodPlanks
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end

-- Modèle (origine = centre de la coque au niveau de l'eau, avant vers -Z)
local function build(kind: string?): (Model, VehicleSeat, Seat)
	local m = Instance.new("Model")
	m.Name = kind == "voilier" and "Voilier" or "Barque"
	local base = part(m, "Base", Vector3.new(4.6, 0.4, 11), CFrame.new(0, -0.2, 0), BOIS)
	m.PrimaryPart = base
	for _, s in { -1, 1 } do
		part(m, "Bord", Vector3.new(0.4, 1.4, 10.4), CFrame.new(s * 2.3, 0.5, 0.2), BOIS_F)
		part(m, "Proue", Vector3.new(0.4, 1.4, 3.2), CFrame.new(s * 1.15, 0.5, -6.3) * CFrame.Angles(0, s * math.rad(-38), 0), BOIS_F)
	end
	part(m, "Poupe", Vector3.new(4.6, 1.4, 0.4), CFrame.new(0, 0.5, 5.4), BOIS_F)
	part(m, "Etrave", Vector3.new(0.5, 1.8, 0.5), CFrame.new(0, 0.7, -7.5), BOIS_F, Enum.Material.Wood)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "Rameur"
	seat.Size = Vector3.new(3.8, 0.4, 1.4)
	seat.CFrame = CFrame.new(0, 0.6, 0.5)
	seat.Color = BOIS
	seat.Material = Enum.Material.WoodPlanks
	seat.Anchored = true
	seat.MaxSpeed = 0 -- on pilote nous-mêmes
	seat.Torque = 0
	seat.HeadsUpDisplay = false
	seat.Parent = m
	local pass = Instance.new("Seat")
	pass.Name = "Passager"
	pass.Size = Vector3.new(3.8, 0.4, 1.4)
	pass.CFrame = CFrame.new(0, 0.6, 4)
	pass.Color = BOIS
	pass.Material = Enum.Material.WoodPlanks
	pass.Anchored = true
	pass.Parent = m
	if kind == "voilier" then
		-- mât, vergue, grande voile et foc ; une quille pour l'allure
		part(m, "Mat", Vector3.new(0.45, 11, 0.45), CFrame.new(0, 5.6, -1.6), BOIS_F, Enum.Material.Wood)
		part(m, "Vergue", Vector3.new(0.3, 0.3, 5.4), CFrame.new(0, 2.2, 0.9), BOIS_F, Enum.Material.Wood)
		local voile = part(m, "Voile", Vector3.new(0.12, 8, 5), CFrame.new(0.1, 6.3, 0.9), Color3.fromRGB(240, 232, 214), Enum.Material.Fabric)
		voile.CanCollide = false
		local foc = Instance.new("WedgePart")
		foc.Name = "Foc"
		foc.Size = Vector3.new(0.1, 7, 4)
		foc.CFrame = CFrame.new(0, 5, -4.4) * CFrame.Angles(0, math.rad(180), 0)
		foc.Color = Color3.fromRGB(230, 220, 200)
		foc.Material = Enum.Material.Fabric
		foc.Anchored, foc.CanCollide = true, false
		foc.Parent = m
		part(m, "Quille", Vector3.new(0.4, 1, 8), CFrame.new(0, -0.8, 0), BOIS_F)
		part(m, "Fanion", Vector3.new(0.08, 0.7, 1.4), CFrame.new(0, 11.4, -1), Color3.fromRGB(168, 40, 40), Enum.Material.Fabric).CanCollide = false
	else
		for _, s in { -1, 1 } do
			part(m, "Rame", Vector3.new(0.25, 0.25, 6), CFrame.new(s * 2.9, 0.9, 0.5) * CFrame.Angles(0, s * 0.5, 0) * CFrame.Angles(-0.25, 0, 0), BOIS_F, Enum.Material.Wood)
		end
	end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.CFrame = p.CFrame -- (positions relatives à l'origine)
		end
	end
	return m, seat, pass
end

local function waterY(): number
	return Config.WATER_Y + 0.15
end

local function place(b)
	local bob = math.sin(os.clock() * 1.6 + b.phase) * 0.12
	local roll = math.sin(os.clock() * 1.1 + b.phase) * 0.03 * (G.Meteo and G.Meteo.kind() == "orage" and 3 or 1)
	local cf = CFrame.new(b.data.x, waterY() + bob, b.data.z) * CFrame.Angles(0, b.yaw, 0) * CFrame.Angles(0, 0, roll)
	b.model:PivotTo(cf)
end

local function spawnBoat(id: string, d)
	local m, seat, pass = build(d.kind)
	m:SetAttribute("BarqueId", id)
	local b = { id = id, data = d, model = m, seat = seat, pass = pass, speed = 0, yaw = d.yaw or 0, phase = math.random() * 6 }
	local kname = (KINDS[d.kind or "barque"] or KINDS.barque).name
	local pr = G.Util.prompt(m.PrimaryPart, "barque_prendre", "Reprendre (" .. string.lower(kname) .. ")", kname, { hold = 1, dist = 10 })
	pr:SetAttribute("Barque", id)
	-- rameur : seulement le propriétaire (sinon c'est un vol de bateau : on le fait descendre)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = seat.Occupant
		local p = hum and Players:GetPlayerFromCharacter(hum.Parent)
		if p and not G.Util.owns(p, d.owner) then
			task.defer(function()
				hum.Sit = false
				hum.Jump = true
			end)
			G.Util.toast(p, "Ce n'est pas ta barque : assieds-toi à la place du passager.")
		end
	end)
	m.Parent = workspace:FindFirstChild("Barques") or (function()
		local f = Instance.new("Folder")
		f.Name = "Barques"
		f.Parent = workspace
		return f
	end)()
	list[id] = b
	place(b)
	return b
end

function Barques.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("barque_prendre", function(player, prompt)
		Barques.pickup(player, prompt:GetAttribute("Barque"))
	end)
end

-- Toutes les barques du monde (il y en a peu) sont posées au démarrage
function Barques.start()
	for id, d in store() do
		if not list[id] then
			spawnBoat(id, d)
		end
	end
end

-- Utiliser l'objet « barque » : la poser sur l'eau devant soi
function Barques.launch(player: Player, kind: string?): boolean
	kind = KINDS[kind or ""] and kind or "barque"
	local root = G.Util.root(player)
	if not root then
		return false
	end
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = look.Magnitude > 0.1 and look.Unit or Vector3.new(0, 0, -1)
	for d = 6, 14, 2 do
		local p = root.Position + look * d
		if G.Util.isWater(p.X, p.Z) and G.Util.isWater(p.X + look.X * 6, p.Z + look.Z * 6) then
			if not G.Joueurs.take(player, kind, 1) then
				return false
			end
			local id = G.Util.newId("bq")
			local data = { owner = G.Util.pid(player), x = p.X, z = p.Z, yaw = math.atan2(-look.X, -look.Z), kind = kind }
			store()[id] = data
			spawnBoat(id, data)
			if kind == "voilier" then
				local vp = G.Joueurs.get(player)
				if vp and not vp.stats.voilier then
					vp.stats.voilier = true
					G.Social.checkTitles(player)
				end
			end
			G.Joueurs.sync(player)
			G.Mondes.saveSoon(player)
			G.Util.toast(player, "⛵ " .. KINDS[kind].name .. " à l'eau ! Assieds-toi à la barre (Z/S pour avancer, Q/D pour tourner).", "gain")
			return true
		end
	end
	G.Util.toast(player, "Mets-toi face à l'eau, tout au bord, pour mettre la barque à l'eau.")
	return false
end

function Barques.pickup(player: Player, id: string?)
	local b = id and list[id]
	if not b then
		return
	end
	if not G.Util.owns(player, b.data.owner) then
		G.Util.toast(player, "Ce n'est pas ta barque.")
		return
	end
	if b.seat.Occupant or b.pass.Occupant then
		G.Util.toast(player, "Quelqu'un est assis dedans.")
		return
	end
	b.model:Destroy()
	list[id] = nil
	store()[id] = nil
	G.Joueurs.add(player, b.data.kind or "barque", 1, true)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	G.Util.toast(player, "⛵ Barque reprise dans ton sac.", "gain")
end

local acc = 0
function Barques.step(dt: number)
	acc += dt
	if acc < 1 / 30 then
		return
	end
	local step = acc
	acc = 0
	for _, b in list do
		local throttle, steer = 0, 0
		local hum = b.seat.Occupant
		if hum ~= b.rameur then
			b.rameur = hum
			b.depart = hum and Vector2.new(b.data.x, b.data.z)
		end
		if hum then
			throttle, steer = b.seat.ThrottleFloat, b.seat.SteerFloat
		end
		local spec = KINDS[b.data.kind or "barque"] or KINDS.barque
		local storm = G.Meteo and G.Meteo.kind() == "orage"
		local max = spec.speed * (storm and 0.7 or 1)
		-- météo maritime lisible : on prévient le barreur quand la mer se lève (une fois par orage)
		if hum and storm and not b.stormWarned then
			b.stormWarned = true
			local p = Players:GetPlayerFromCharacter(hum.Parent)
			if p then
				G.Util.toast(p, "🌊 La mer se lève : le bateau tangue et avance moins vite. Mieux vaut regagner la côte.", "danger")
			end
		elseif not storm then
			b.stormWarned = nil
		end
		-- inertie : on accélère et on freine progressivement (la barque glisse)
		b.speed += (throttle * max - b.speed) * math.min(1, step * (throttle ~= 0 and 1.2 or 0.6))
		if math.abs(b.speed) > 0.2 or steer ~= 0 then
			b.yaw -= steer * spec.turn * step * (0.4 + 0.6 * math.min(1, math.abs(b.speed) / spec.speed))
			local dir = Vector3.new(-math.sin(b.yaw), 0, -math.cos(b.yaw))
			local nx, nz = b.data.x + dir.X * b.speed * step, b.data.z + dir.Z * b.speed * step
			-- la proue (5 studs devant) doit rester dans l'eau : sinon on s'échoue
			local px, pz = nx + dir.X * 5 * math.sign(b.speed), nz + dir.Z * 5 * math.sign(b.speed)
			if G.Util.isWater(px, pz) then
				b.data.x, b.data.z = nx, nz
				local voyage = G.Quetes and rawget(G.Quetes, "VOYAGE_DISTANCE")
				if hum and voyage and b.depart then
					local position = Vector2.new(nx, nz)
					if (position - b.depart).Magnitude >= voyage then
						b.depart = position
						local player = Players:GetPlayerFromCharacter(hum.Parent)
						if player and G.Util.owns(player, b.data.owner) then
							G.Quetes.note(player, "naviguer", "bateau")
							G.Social.bump(player, "voyages")
						end
					end
				end
			else
				if math.abs(b.speed) > 6 and hum then
					local p = Players:GetPlayerFromCharacter(hum.Parent)
					if p then
						G.remotes.Fx:FireClient(p, "fall") -- petit choc contre la rive
					end
				end
				b.speed = 0
			end
			b.data.yaw = b.yaw
		end
		place(b)
	end
end

return Barques
