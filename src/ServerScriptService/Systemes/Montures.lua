-- Montures façon WoW (26/11) : COLLECTION par personnage, invocation n'importe où, compétence Équitation,
-- rênes rares sur certaines créatures. Catalogue : Shared/Ecurie. Journal : Montures.client.
--
-- Profil : prof.montures = { learned = { [id] = jour appris }, fav = id? }
-- Attribut joueur « Montures » (JSON : ids appris) pour le journal ; « Invocation » = fin du temps d'invocation.
-- Actions client : « monture » { id } (invoquer), « monture_hasard » {}, « monture_favori » { id }.
--
-- Règles du jeu respectées : pas de plafond (on apprend toutes les montures qu'on trouve), grind (rênes rares,
-- Équitation qui monte en chevauchant, vol à Ecurie.FLY_SKILL), pas d'achat en Robux, pas d'annonce au
-- serveur (le journal ne montre qu'un indice vague pour les montures inconnues).

local Montures = {}
local G, Config
local Ecurie = require(game:GetService("ReplicatedStorage").Shared.Ecurie)
local HttpService = game:GetService("HttpService")

local ground = {} -- joueur -> monture au sol invoquée { model, id }
local casting = {} -- joueur -> jeton d'invocation
local lastPos = {} -- joueur -> dernière position en selle (Équitation)
local travelled = {} -- joueur -> studs accumulés

local function prof(player: Player)
	local p = G.Joueurs.get(player)
	if p then
		p.montures = p.montures or { learned = {} }
		p.montures.learned = p.montures.learned or {}
	end
	return p
end

local function publish(player: Player)
	local p = prof(player)
	if not p then
		return
	end
	local ids = {}
	for id in p.montures.learned do
		if Ecurie.BY_ID[id] then
			table.insert(ids, id)
		end
	end
	player:SetAttribute("Montures", HttpService:JSONEncode({ ids = ids, fav = p.montures.fav }))
end

function Montures.init(g)
	G = g
	Config = G.Config
	-- rênes rares : ajoutées APRÈS la normalisation du butin (Bestiaire), pour garder leur chance
	for _, m in Ecurie.LIST do
		if m.drop then
			local k = G.Enemies.KINDS and G.Enemies.KINDS[m.drop[1]]
			if k then
				k.loot = k.loot or {}
				table.insert(k.loot, { Ecurie.itemId(m.id), 1, 1, m.drop[2] })
			end
		end
	end
	G.Interact.onAction("monture", function(player, data)
		Montures.summon(player, type(data) == "table" and data.id)
	end)
	G.Interact.onAction("monture_hasard", function(player)
		Montures.summonRandom(player)
	end)
	G.Interact.onAction("monture_favori", function(player, data)
		local p = prof(player)
		local id = type(data) == "table" and data.id
		if p and type(id) == "string" and p.montures.learned[id] then
			p.montures.fav = (p.montures.fav ~= id) and id or nil
			G.Joueurs.markDirty(player)
			publish(player)
		end
	end)
	-- aperçus 3D du journal (ReplicatedStorage.ApercusMontures), construits une fois au démarrage
	task.defer(function()
		local RS = game:GetService("ReplicatedStorage")
		local dossier = RS:FindFirstChild("ApercusMontures") or Instance.new("Folder")
		dossier.Name = "ApercusMontures"
		for _, m in Ecurie.LIST do
			if not dossier:FindFirstChild(m.id) then
				local ok, model = pcall(Montures.buildModel, m)
				if ok and model then
					model.Name = m.id
					for _, p in model:GetDescendants() do
						if p:IsA("BasePart") then
							p.Anchored = true
						elseif p:IsA("Script") or p:IsA("Sound") or p:IsA("ParticleEmitter") then
							p:Destroy()
						end
					end
					model.Parent = dossier
				end
			end
			task.wait()
		end
		dossier.Parent = RS
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		Montures.dismount(player)
		casting[player], lastPos[player], travelled[player] = nil, nil, nil
	end)
end

function Montures.onJoin(player: Player)
	publish(player)
end

-- ----------------------------------------------------------------- Apprendre

function Montures.learn(player: Player, id: string?, how: string?): boolean
	local m = id and Ecurie.BY_ID[id]
	local p = prof(player)
	if not (m and p) then
		return false
	end
	if p.montures.learned[id] then
		if how == "renes" then
			G.Util.toast(player, m.name .. " est déjà dans ta collection. (Les rênes se revendent bien.)")
		end
		return false
	end
	p.montures.learned[id] = G.world and G.world.day or 0
	G.Joueurs.markDirty(player)
	publish(player)
	local r = Ecurie.RARITY[m.rarity]
	G.Util.toast(player, "🏇 Nouvelle monture : " .. m.name .. " (" .. (r and r.name or "") .. ") — journal des montures [N].", "big")
	if G.Social and rawget(G.Social, "collect") then
		G.Social.collect(player, "montures", id)
	end
	return true
end

function Montures.learnHorse(player: Player, species: string?, coat: number?)
	local id = Ecurie.horseId(species, coat)
	if id then
		Montures.learn(player, id, "ecurie")
	end
end

function Montures.learnKind(player: Player, kind: string)
	local m = Ecurie.BY_KIND[kind]
	if m and m.source == "apprivoiser" then
		Montures.learn(player, m.id, "apprivoiser")
	end
end

function Montures.knows(player: Player, id: string): boolean
	local p = prof(player)
	return p ~= nil and p.montures.learned[id] ~= nil
end

-- ----------------------------------------------------------------- Équitation

function Montures.speedMul(player: Player): number
	return 1 + Ecurie.SKILL_SPEED * G.Joueurs.skillRaw(player, "equitation")
end

function Montures.canFly(player: Player): boolean
	if G.Joueurs.skillRaw(player, "equitation") >= Ecurie.FLY_SKILL then
		return true
	end
	G.Util.toast(player, "Tu ne sais pas encore voler : il faut Équitation " .. Ecurie.FLY_SKILL
		.. " (tu es à " .. G.Joueurs.skillRaw(player, "equitation") .. "). Chevauche pour progresser.")
	return false
end

-- ----------------------------------------------------------------- Modèles

local function buildModel(m): Model?
	local kind, coat, species = nil, nil, nil
	local c, sp = string.match(m.model, "^cheval:(%d+):?(%a*)$")
	if c then
		coat, species = tonumber(c), (sp ~= "" and sp or "cheval")
	else
		kind = string.match(m.model, "^bete:(.+)$")
	end
	local model
	if coat then
		model = G.Util.clone("Cheval")
		if model then
			local scale = (Config.MOUNTS[species] or Config.MOUNTS.cheval).scale
			if scale ~= 1 then
				model:ScaleTo(scale)
			end
			if G.Horses.paint then
				G.Horses.paint(model, coat, 1)
			end
		end
	elseif kind then
		model = G.Util.clone("Bete_" .. kind)
	end
	if model then
		model.Name = "Monture_" .. m.id
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
			elseif p:IsA("ProximityPrompt") or p:IsA("BillboardGui") then
				p:Destroy()
			end
		end
	end
	return model
end
Montures.buildModel = buildModel

-- ----------------------------------------------------------------- Invoquer

local function busy(player: Player): string?
	if player:GetAttribute("Riding") or (G.Envol and G.Envol.isFlying and G.Envol.isFlying(player)) then
		return "Tu es déjà en selle."
	end
	if player:GetAttribute("Carrying") then
		return "Tu portes quelque chose."
	end
	local root = G.Util.root(player)
	if root and G.Util.isWater(root.Position.X, root.Position.Z) and root.Position.Y < (Config.WATER_Y or 0) + 1 then
		return "Pas dans l'eau."
	end
	return nil
end

function Montures.summon(player: Player, id: any)
	if type(id) ~= "string" then
		return
	end
	local m = Ecurie.BY_ID[id]
	if not m or not Montures.knows(player, id) then
		return
	end
	local why = busy(player)
	if why then
		G.Util.toast(player, why)
		return
	end
	if m.type == "vol" and not Montures.canFly(player) then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum and hum.Health > 0) then
		return
	end
	-- temps d'invocation : immobile, sans être frappé (façon WoW)
	local token = {}
	casting[player] = token
	local startPos, startHp = root.Position, hum.Health
	player:SetAttribute("Invocation", workspace:GetServerTimeNow() + Ecurie.CAST)
	G.Util.geste(player, "salut")
	G.Util.sfx("sifflet", root.Position)
	task.delay(Ecurie.CAST, function()
		if casting[player] ~= token then
			return
		end
		casting[player] = nil
		player:SetAttribute("Invocation", nil)
		if not (root.Parent and hum.Parent and hum.Health > 0) then
			return
		end
		if (root.Position - startPos).Magnitude > 2 or hum.Health < startHp then
			G.Util.toast(player, "Invocation interrompue.")
			return
		end
		if busy(player) then
			return
		end
		local model = buildModel(m)
		if not model then
			G.Util.toast(player, "Cette monture n'a pas pu venir.")
			return
		end
		if m.type == "vol" then
			-- vol : même pilotage que les montures apprivoisées (Systemes/Envol)
			local _, size = model:GetBoundingBox()
			model:PivotTo(CFrame.new(root.Position - Vector3.new(0, size.Y * 0.4, 0)) * (root.CFrame - root.Position))
			model.Parent = workspace
			local base = model.PrimaryPart
			if base then
				base.Anchored = true
			end
			G.Envol.mount(player, {
				summoned = true, kind = m.kind, model = model, pos = root.Position - Vector3.new(0, 3, 0),
				owner = G.Util.pid(player), flyer = { speed = m.speed, climb = m.climb or 24, breath = m.breath or 100 },
			})
			if not G.Envol.isFlying(player) then
				model:Destroy()
			end
		else
			Montures.rideGround(player, m, model)
		end
	end)
end

function Montures.summonRandom(player: Player)
	local p = prof(player)
	if not p then
		return
	end
	if p.montures.fav and p.montures.learned[p.montures.fav] then
		Montures.summon(player, p.montures.fav)
		return
	end
	local list = {}
	for id in p.montures.learned do
		local m = Ecurie.BY_ID[id]
		if m and (m.type == "sol" or G.Joueurs.skillRaw(player, "equitation") >= Ecurie.FLY_SKILL) then
			table.insert(list, id)
		end
	end
	if #list == 0 then
		G.Util.toast(player, "Aucune monture dans ta collection. (Écurie, apprivoisement, rênes rares…)")
		return
	end
	Montures.summon(player, list[math.random(1, #list)])
end

-- monture au sol : soudée sous le joueur, vitesse par MountSpeed (Game.step), comme un cheval (Horses.mount)
function Montures.rideGround(player: Player, m, model: Model)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local base = model.PrimaryPart
	if not (root and hum and base) then
		model:Destroy()
		return
	end
	local assise = base:FindFirstChild("Assise")
	local seat
	if assise then
		seat = base.CFrame:PointToObjectSpace(assise.WorldPosition).Y
	else
		local _, size = model:GetBoundingBox()
		seat = size.Y * 0.62
	end
	local SIT = 1.15
	char:PivotTo(root.CFrame + Vector3.new(0, seat + SIT + 0.3, 0))
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.Massless = true
		end
	end
	model:PivotTo(root.CFrame * CFrame.new(0, -(seat + SIT), 0))
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= base and not p:FindFirstChildOfClass("WeldConstraint") then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = base, p
			w.Parent = p
		end
	end
	local w = Instance.new("WeldConstraint")
	w.Name = "MontureCollection"
	w.Part0, w.Part1 = root, base
	w.Parent = base
	model.Parent = char
	ground[player] = { model = model, id = m.id, oldHip = hum.HipHeight }
	hum.HipHeight = seat + SIT - root.Size.Y / 2
	player:SetAttribute("MountSpeed", m.speed * Montures.speedMul(player) * (1 + 0.12 * G.Joueurs.talent(player, "cavalier")))
	player:SetAttribute("Riding", true)
	G.Util.sfx("sabots", root.Position)
end

function Montures.dismount(player: Player)
	casting[player] = nil
	player:SetAttribute("Invocation", nil)
	local r = ground[player]
	if not r then
		return
	end
	ground[player] = nil
	G.Game.noFall(player, 2)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if r.model then
		r.model:Destroy()
	end
	if hum then
		hum.HipHeight = r.oldHip or 2
	end
	player:SetAttribute("Riding", false)
	player:SetAttribute("MountSpeed", nil)
end

-- ----------------------------------------------------------------- Boucle : Équitation, nettoyage

local acc = 0
function Montures.step(dt: number)
	acc += dt
	if acc < 0.5 then
		return
	end
	acc = 0
	for _, player in G.Game.players() do
		local root = G.Util.root(player)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if ground[player] and (not root or not hum or hum.Health <= 0 or not ground[player].model.Parent) then
			Montures.dismount(player)
		end
		if root and player:GetAttribute("Riding") then
			local last = lastPos[player]
			if last then
				local d = (root.Position - last).Magnitude
				if d < 120 then -- pas les téléportations
					travelled[player] = (travelled[player] or 0) + d
					if travelled[player] >= Ecurie.XP_STUDS then
						local n = math.floor(travelled[player] / Ecurie.XP_STUDS)
						travelled[player] -= n * Ecurie.XP_STUDS
						local before = G.Joueurs.skillRaw(player, "equitation")
						G.Joueurs.addSkillXp(player, "equitation", n)
						if before < Ecurie.FLY_SKILL and G.Joueurs.skillRaw(player, "equitation") >= Ecurie.FLY_SKILL then
							G.Util.toast(player, "🪶 Équitation " .. Ecurie.FLY_SKILL .. " : tu sais maintenant mener une monture volante.", "big")
						end
					end
				end
			end
			lastPos[player] = root.Position
		else
			lastPos[player] = nil
		end
	end
end

return Montures
