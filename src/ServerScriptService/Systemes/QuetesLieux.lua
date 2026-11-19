-- Quêtes « à un lieu » (19/11, docs/QUETES-COUVERTURE.md) : les quêtes du tableau étaient toutes
-- « fais N fois X ». Celles-ci demandent d'aller quelque part :
--   retrouver : un objet perdu posé dans le monde, quelque part autour du village (direction + distance) ;
--   visiter   : aller voir un lieu de la carte (ruine, ferme isolée, antre d'une bête) ;
--   enqueter  : trois indices à la suite, chacun mène au suivant ;
--   escorter  : un voyageur te suit jusqu'à un autre village (on rend la quête là-bas).
-- Toujours facultatives, tirées par le générateur de Quetes (même île + même village + même période =
-- même offre). Les points précis sont tirés à la prise de la quête (propres à chaque joueur).
-- Repères : posés seulement quand le joueur approche (moins de 150 studs), visibles de tous mais
-- seul celui qui a la quête peut les fouiller. Le voyageur n'est pas un habitant (pas de routine).
-- État (dans la quête, sauvegardé avec le monde) : px/pz (point), pts = { {x, z}, … } (enquête).

local QuetesLieux = {}
local G, Config

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

QuetesLieux.SHARE = 0.22 -- part des offres du tableau qui sont « à un lieu »
QuetesLieux.ICON = { retrouver = "🔍", visiter = "🗺️", enqueter = "🔎", escorter = "🚶" }
QuetesLieux.SKILL = { retrouver = "commerce", visiter = "commerce", enqueter = "commerce", escorter = "combat" }

local SHOW = 150 -- studs : le repère apparaît
local HIDE = 220 -- studs : il disparaît (on s'est éloigné)
local VISIT_R = 24 -- studs du point d'arrivée d'un lieu
local ARRIVE_R = 30 -- studs de la place du village d'arrivée (escorte)

-- { titre, ce qu'on cherche }
local LOST = {
	{ "Un villageois a perdu ses affaires", "le baluchon d'un villageois" },
	{ "Le vieux pêcheur", "la boîte à hameçons du vieux pêcheur" },
	{ "Une livraison a disparu", "une caisse tombée d'une charrette" },
	{ "Les affaires d'un ancien habitant", "un coffret enterré" },
	{ "Une lettre égarée", "la sacoche d'un messager" },
	{ "Le collectionneur", "une pièce de monnaie ancienne" },
	{ "Le garde distrait", "la bourse d'un garde" },
}
-- { titre, trois indices (le dernier est la fin de l'enquête) }
local CASES = {
	{ "Un coffre a disparu", { "des traces de pas", "un bout de tissu accroché", "le coffre, forcé et abandonné" } },
	{ "Retrouver un objet volé", { "une empreinte de botte", "un sac éventré", "la cachette du voleur" } },
	{ "Des marques mystérieuses", { "une marque gravée sur une pierre", "une seconde marque, plus loin", "une cache sous les racines" } },
	{ "Une lettre mystérieuse", { "un cachet de cire brisé", "un brouillon déchiré", "le refuge de l'auteur" } },
	{ "Les oiseaux ont quitté le bois", { "des plumes éparpillées", "des griffures sur une souche", "la tanière d'une bête" } },
}
local VISIT = {
	ruin = { "La ruine mystérieuse", "Le vieux chemin", "Une histoire oubliée" },
	farm = { "La ferme isolée", "Le fermier voisin" },
	lair = { "Le territoire de la bête", "Repérer l'antre" },
}
local ESCORT = { "Un voyageur à escorter", "Le marchand prudent", "Une pèlerine sur la route", "Le neveu du maire" }
local DIRS = { "au nord", "au nord-est", "à l'est", "au sud-est", "au sud", "au sud-ouest", "à l'ouest", "au nord-ouest" }

local folder: Folder
local markers = {} -- joueur -> { [id quête] = modèle }
local escorts = {} -- joueur -> { [id quête] = { model, hum, root, tracks, walking, arrivedT } }

-- ---------------------------------------------------------------- outils

local function pick(r: Random, list)
	return list[r:NextInteger(1, #list)]
end

-- « au nord-est, à 140 pas » (0° = nord = -Z, comme la boussole du HUD)
local function hint(fx: number, fz: number, tx: number, tz: number): string
	local dx, dz = tx - fx, tz - fz
	local deg = math.deg(math.atan2(dx, -dz)) % 360
	local d = math.floor(math.sqrt(dx * dx + dz * dz) / 10 + 0.5) * 10
	return DIRS[math.floor((deg + 22.5) / 45) % 8 + 1] .. ", à " .. d .. " pas"
end

local function onLand(x: number, z: number): boolean
	local CELL = Config.CELL
	local cx, cz = math.floor(x / CELL), math.floor(z / CELL)
	local rx, rz = G.WG.regionOf(cx, cz)
	if not G.WG.inWorld(rx, rz) then
		return false
	end
	local ok, water = pcall(G.Util.isWater, x, z)
	return ok and not water
end

-- un point sur la terre ferme entre dmin et dmax studs de (x, z)
local function pointNear(r: Random, x: number, z: number, dmin: number, dmax: number): (number, number)
	for _ = 1, 16 do
		local a = r:NextNumber() * math.pi * 2
		local d = r:NextNumber(dmin, dmax)
		local px, pz = x + math.cos(a) * d, z + math.sin(a) * d
		if onLand(px, pz) then
			return px, pz
		end
	end
	return x + r:NextNumber(-12, 12), z + r:NextNumber(-12, 12)
end

local function rootOf(player: Player): BasePart?
	return G.Util.root(player)
end

local function flat(p: Vector3, x: number, z: number): number
	return Vector2.new(p.X - x, p.Z - z).Magnitude
end

local function villageByKey(key: string)
	for _, v in G.Quetes.villages() do
		if v.key == key then
			return v
		end
	end
	return nil
end

-- point courant d'une quête (nil si elle n'en a pas ou si c'est fini)
local function target(q): (number?, number?)
	if (q.got or 0) >= q.need then
		return nil, nil
	end
	if q.kind == "enqueter" then
		local p = q.pts and q.pts[(q.got or 0) + 1]
		if p then
			return p[1], p[2]
		end
		return nil, nil
	end
	return q.px, q.pz
end

local function advance(player: Player, q, text: string?)
	q.got = math.min(q.need, (q.got or 0) + 1)
	if q.got >= q.need then
		G.Util.toast(player, "📜 « " .. q.title .. " » : c'est fait ! Retourne à " .. (q.kind == "escorter" and q.label or q.vname) .. ".", "big")
	elseif text then
		G.Util.toast(player, text, "big")
	end
	G.Quetes.send(player)
end

-- ---------------------------------------------------------------- génération (appelée par Quetes.makeOffer)

-- Remplit q (titre, sorte, or…) et rend true, ou false si rien ne convient ici.
function QuetesLieux.offer(v, r: Random, q, reward, villages): boolean
	local roll = r:NextNumber()
	if roll < 0.32 then
		local l = pick(r, LOST)
		q.kind, q.key, q.need, q.title, q.label = "retrouver", "objet", 1, l[1], l[2]
		q.gold = reward(r, 55)
		return true
	elseif roll < 0.6 then
		local rx, rz = string.match(v.key, "^(-?%d+),(-?%d+)$")
		rx, rz = tonumber(rx), tonumber(rz)
		local places = {}
		for _, p in (rx and G.wg:placesAround(rx, rz, 3)) or {} do
			if VISIT[p.kind] and not p.start and G.WG.inWorld(p.rx, p.rz) then
				table.insert(places, p)
			end
		end
		if #places == 0 then
			return false
		end
		local p = pick(r, places)
		local CELL = Config.CELL
		q.kind, q.key, q.need, q.title = "visiter", p.rx .. "," .. p.rz, 1, pick(r, VISIT[p.kind])
		q.px, q.pz = p.ax * CELL + CELL / 2, p.az * CELL + CELL / 2
		q.label = G.WG.placeLabel(p)
		q.gold = reward(r, 30 + flat(Vector3.new(q.px, 0, q.pz), v.x, v.z) / 5 + (p.kind == "lair" and 60 or 0))
		return true
	elseif roll < 0.82 then
		local c = pick(r, CASES)
		q.kind, q.key, q.need, q.title = "enqueter", "indices", 3, c[1]
		q.clues = c[2]
		q.gold = reward(r, 120)
		return true
	end
	local others = {}
	for _, o in villages() do
		if o.key ~= v.key then
			table.insert(others, o)
		end
	end
	if #others == 0 then
		return false
	end
	-- le plus souvent un village proche (trajet à pied raisonnable)
	table.sort(others, function(a, b)
		return flat(Vector3.new(a.x, 0, a.z), v.x, v.z) < flat(Vector3.new(b.x, 0, b.z), v.x, v.z)
	end)
	local t = others[r:NextInteger(1, math.min(3, #others))]
	local d = flat(Vector3.new(t.x, 0, t.z), v.x, v.z)
	q.kind, q.key, q.need, q.title, q.label = "escorter", t.key, 1, pick(r, ESCORT), t.name
	q.gold = reward(r, 50 + d / 4)
	return true
end

function QuetesLieux.what(q): string?
	if q.kind == "retrouver" then
		if q.px then
			return "Retrouver " .. q.label .. " — " .. (q.where or "autour du village")
		end
		return "Retrouver " .. q.label .. ", quelque part autour de " .. q.vname
	elseif q.kind == "visiter" then
		return "Aller voir " .. q.label .. (q.where and (" — " .. q.where) or "")
	elseif q.kind == "enqueter" then
		local n = (q.got or 0) + 1
		local clue = q.clues and q.clues[math.min(n, 3)] or "un indice"
		if (q.got or 0) >= q.need then
			return "Enquête terminée : " .. (q.clues and q.clues[3] or "l'affaire est réglée")
		end
		return string.format("Enquête (%d/3) : chercher %s%s", n, clue, q.where and (" — " .. q.where) or "")
	elseif q.kind == "escorter" then
		return "Escorter un voyageur jusqu'à " .. (q.label or "?") .. " (il te suit)"
	end
	return nil
end

-- ---------------------------------------------------------------- prise / abandon

function QuetesLieux.onTake(player: Player, q, here)
	if not QuetesLieux.ICON[q.kind] then
		return
	end
	local r = Random.new(G.WG.hash(G.world.seed, "quete-lieu", q.id, player.UserId))
	local v = here or villageByKey(q.v)
	local vx, vz = v and v.x or 0, v and v.z or 0
	if q.kind == "retrouver" then
		q.px, q.pz = pointNear(r, vx, vz, 50, 160)
		q.where = hint(vx, vz, q.px, q.pz) .. " du village"
		G.Util.toast(player, "🔍 Dernière trace : " .. q.where .. ".")
	elseif q.kind == "visiter" then
		q.where = hint(vx, vz, q.px, q.pz) .. " du village"
	elseif q.kind == "enqueter" then
		local x1, z1 = pointNear(r, vx, vz, 40, 90)
		local x2, z2 = pointNear(r, x1, z1, 60, 120)
		local x3, z3 = pointNear(r, x2, z2, 60, 120)
		q.pts = { { x1, z1 }, { x2, z2 }, { x3, z3 } }
		q.where = hint(vx, vz, x1, z1) .. " du village"
		G.Util.toast(player, "🔎 Un habitant a vu quelque chose " .. q.where .. ".")
	elseif q.kind == "escorter" then
		G.Util.toast(player, "🚶 Le voyageur te suivra jusqu'à " .. (q.label or "?") .. ". Ne va pas trop vite.")
	end
end

local function dropMarker(player: Player, id: string)
	local m = markers[player] and markers[player][id]
	if m then
		m:Destroy()
		markers[player][id] = nil
	end
end

local function dropEscort(player: Player, id: string)
	local e = escorts[player] and escorts[player][id]
	if e then
		e.model:Destroy()
		escorts[player][id] = nil
	end
end

-- quête lâchée ou rendue : on range ses repères et son voyageur
function QuetesLieux.clear(player: Player, q)
	if q and q.id then
		dropMarker(player, q.id)
		dropEscort(player, q.id)
	end
end

-- ---------------------------------------------------------------- repères

local LOOK = {
	retrouver = { size = Vector3.new(1.6, 1.1, 1.3), color = Color3.fromRGB(122, 88, 54), mat = Enum.Material.Fabric, text = "Ramasser" },
	enqueter = { size = Vector3.new(1.4, 0.5, 1.4), color = Color3.fromRGB(150, 140, 120), mat = Enum.Material.Slate, text = "Examiner" },
}

local function makeMarker(player: Player, q, x: number, z: number): Model
	local look = LOOK[q.kind]
	local y = G.Util.groundY(x, z)
	local model = Instance.new("Model")
	model.Name = "Indice_" .. player.UserId
	local p = Instance.new("Part")
	p.Name = "Indice"
	p.Size = look.size
	p.Color = look.color
	p.Material = look.mat
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = CFrame.new(x, y + look.size.Y / 2, z) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	p.Parent = model
	-- un léger scintillement : on le remarque en passant, pas de loin
	local att = Instance.new("Attachment")
	att.Parent = p
	local fx = Instance.new("ParticleEmitter")
	fx.Rate = 2
	fx.Lifetime = NumberRange.new(1, 1.6)
	fx.Speed = NumberRange.new(0.4, 0.8)
	fx.Size = NumberSequence.new(0.18, 0)
	fx.LightEmission = 0.6
	fx.Color = ColorSequence.new(Color3.fromRGB(255, 230, 160))
	fx.Parent = att
	model.PrimaryPart = p
	G.Util.prompt(p, "quete_lieu", look.text, q.kind == "enqueter" and "Indice" or q.label, {
		dist = 8, data = { Quete = q.id, Owner = tostring(player.UserId) },
	})
	model.Parent = folder
	return model
end

-- butin de fin d'enquête : un petit objet tiré parmi ceux que le catalogue connaît
local function endLoot(q): string?
	local ok = {}
	for _, id in { "coin_purse", "rare_book", "treasure_map", "lockpick" } do
		if Config.ITEMS[id] then
			table.insert(ok, id)
		end
	end
	return #ok > 0 and ok[math.random(1, #ok)] or nil
end

local function onSearch(player: Player, prompt: ProximityPrompt)
	if prompt:GetAttribute("Owner") ~= tostring(player.UserId) then
		G.Util.toast(player, "Rien qui te concerne ici.")
		return
	end
	local id = prompt:GetAttribute("Quete")
	local st = G.world.players[tostring(player.UserId)]
	local q = st and st.quetes and st.quetes.act[id]
	if not q then
		dropMarker(player, id)
		return
	end
	local tx, tz = target(q)
	local root = rootOf(player)
	if not tx or not root or flat(root.Position, tx, tz) > 14 then
		return
	end
	dropMarker(player, id)
	G.Util.sfx("ramasser", root.Position, player)
	if q.kind == "retrouver" then
		advance(player, q)
	elseif q.kind == "enqueter" then
		local n = (q.got or 0) + 1
		local nxt = q.pts[n + 1]
		if nxt then
			q.where = hint(tx, tz, nxt[1], nxt[2])
			advance(player, q, "🔎 Tu trouves " .. (q.clues and q.clues[n] or "un indice") .. ". La piste continue " .. q.where .. ".")
		else
			G.Util.toast(player, "🔎 Tu trouves " .. (q.clues and q.clues[n] or "le fin mot de l'affaire") .. ".")
			local loot = endLoot(q)
			if loot then
				G.Joueurs.add(player, loot, 1)
				G.Joueurs.sync(player)
			end
			advance(player, q, nil)
		end
	end
end

-- ---------------------------------------------------------------- voyageur (escorte)

local function spawnEscort(player: Player, q, root: BasePart)
	local base = ServerStorage:FindFirstChild("Modeles") and ServerStorage.Modeles:FindFirstChild("PNJ_Base")
	if not base then
		return nil
	end
	local WG = G.WG
	local r = Random.new(G.WG.hash(G.world.seed, "voyageur", q.id))
	local female = r:NextNumber() < 0.5
	local hairs = female and WG.HAIRS_F or WG.HAIRS_M
	local look = {
		skin = r:NextInteger(1, #WG.SKINS), hair = hairs[r:NextInteger(1, #hairs)], hairColor = r:NextInteger(1, #WG.HAIR_COLORS),
		shirt = r:NextInteger(1, WG.SHIRTS_GEN1 or #WG.SHIRTS), pants = r:NextInteger(1, WG.PANTS_GEN1 or #WG.PANTS),
		hat = "", height = 1, width = 1, female = female,
	}
	local pool = female and WG.NAMES_F or WG.NAMES_M
	local name = pool[r:NextInteger(1, #pool)]
	local model = base:Clone()
	model.Name = name
	model:SetAttribute("Nom", name)
	model:SetAttribute("Role", "voyageur")
	pcall(G.Avatar.dress, model, look, "villager")
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CollisionGroup = "PNJ"
		end
	end
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart
	if not hum or not hrp then
		model:Destroy()
		return nil
	end
	hum.WalkSpeed = 20
	hum.UseJumpPower = true
	hum.JumpPower = 42
	local at = root.Position - root.CFrame.LookVector * 5
	model:PivotTo(CFrame.new(at.X, G.Util.groundY(at.X, at.Z) + 3.5, at.Z))
	hrp.Anchored = false
	model.Parent = folder
	pcall(hrp.SetNetworkOwner, hrp, nil)
	local e = { model = model, hum = hum, root = hrp, tracks = {}, name = name }
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local anims = model:FindFirstChild("Anims")
	for _, a in anims and anims:GetChildren() or {} do
		local ok, track = pcall(animator.LoadAnimation, animator, a)
		if ok then
			e.tracks[a.Name] = track
			track.Looped = a.Name == "idle" or a.Name == "walk" or a.Name == "run"
		end
	end
	if e.tracks.idle then
		e.tracks.idle:Play()
	end
	hum.Running:Connect(function(speed)
		local walk = e.tracks.walk
		if not walk then
			return
		end
		if speed > 0.5 and not walk.IsPlaying then
			walk:Play()
		elseif speed <= 0.5 and walk.IsPlaying then
			walk:Stop()
		end
	end)
	return e
end

local function stepEscort(player: Player, q, root: BasePart)
	escorts[player] = escorts[player] or {}
	local e = escorts[player][q.id]
	if e and not e.model.Parent then
		escorts[player][q.id] = nil
		e = nil
	end
	if (q.got or 0) >= q.need then
		if e and not e.arrivedT then
			e.arrivedT = os.clock()
		end
		if e and os.clock() - e.arrivedT > 4 then
			dropEscort(player, q.id)
		end
		return
	end
	if not e then
		e = spawnEscort(player, q, root)
		if not e then
			return
		end
		escorts[player][q.id] = e
	end
	local d = (e.root.Position - root.Position).Magnitude
	if d > 70 then
		-- resté coincé ou semé (monture, barque) : il te rattrape
		local at = root.Position - root.CFrame.LookVector * 5
		e.model:PivotTo(CFrame.new(at.X, G.Util.groundY(at.X, at.Z) + 3.5, at.Z))
	elseif d > 7 then
		e.hum:MoveTo(root.Position - (root.Position - e.root.Position).Unit * 4)
	end
	local t = villageByKey(q.key)
	if t and flat(e.root.Position, t.x, t.z) < ARRIVE_R then
		e.hum:MoveTo(Vector3.new(t.x, e.root.Position.Y, t.z))
		advance(player, q, nil)
		G.Util.toast(player, "🚶 « Merci, me voici à " .. t.name .. " ! » — " .. e.name)
	end
end

-- ---------------------------------------------------------------- boucle

local acc = 0
function QuetesLieux.step(dt: number)
	acc += dt
	if acc < 0.5 then
		return
	end
	acc = 0
	for _, player in Players:GetPlayers() do
		local st = G.world.players[tostring(player.UserId)]
		local act = st and st.quetes and st.quetes.act
		local root = rootOf(player)
		if act and root then
			markers[player] = markers[player] or {}
			for id, q in act do
				if q.kind == "retrouver" or q.kind == "enqueter" then
					local tx, tz = target(q)
					local m = markers[player][id]
					if not tx then
						dropMarker(player, id)
					else
						local d = flat(root.Position, tx, tz)
						if m and (not m.Parent or d > HIDE or flat(m.PrimaryPart.Position, tx, tz) > 1) then
							dropMarker(player, id)
							m = nil
						end
						if not m and d < SHOW then
							markers[player][id] = makeMarker(player, q, tx, tz)
						end
					end
				elseif q.kind == "visiter" then
					if (q.got or 0) < q.need and q.px and flat(root.Position, q.px, q.pz) < VISIT_R then
						advance(player, q, nil)
					end
				elseif q.kind == "escorter" then
					stepEscort(player, q, root)
				end
			end
			-- repères de quêtes qui n'existent plus
			for id in markers[player] do
				if not act[id] then
					dropMarker(player, id)
				end
			end
			for id in escorts[player] or {} do
				if not act[id] then
					dropEscort(player, id)
				end
			end
		end
	end
end

function QuetesLieux.init(g)
	G = g
	Config = G.Config
	folder = Instance.new("Folder")
	folder.Name = "QuetesLieux"
	folder.Parent = workspace
	G.Interact.onPrompt("quete_lieu", onSearch)
	Players.PlayerRemoving:Connect(function(player)
		for _, m in markers[player] or {} do
			m:Destroy()
		end
		for _, e in escorts[player] or {} do
			e.model:Destroy()
		end
		markers[player], escorts[player] = nil, nil
	end)
end

return QuetesLieux
