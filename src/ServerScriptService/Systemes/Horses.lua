-- Chevaux : sauvages (on les apprivoise avec une carotte), ceux des fermes (achat 250 or, ou vol
-- avec une carotte comme appât), et le cheval du joueur (Monter, Siffler). La robe ne change
-- jamais : le cheval monté est le même modèle, attaché sous le joueur.

local Horses = {}
local G, Config
local live = {} -- id -> entrée
local riding = {} -- joueur -> entrée
local SIT_OFFSET = 1.15 -- hauteur du centre du joueur au-dessus de la selle quand il est assis

function Horses.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("horse", function(player, prompt)
		local h = live[prompt:GetAttribute("Horse")]
		if h then
			Horses.use(player, h, prompt:GetAttribute("Mode"))
		end
	end)
	G.Interact.onAction("dismount", function(player)
		Horses.dismount(player, false)
	end)
	G.Interact.onAction("whistle", function(player)
		Horses.whistle(player)
	end)
	local function promptPos(prompt)
		local a = prompt.Parent
		return a and (a:IsA("Attachment") and a.WorldPosition or (a:IsA("BasePart") and a.Position)) or nil
	end
	G.Interact.onPrompt("ecurie_changer", function(player, prompt)
		local pos = promptPos(prompt)
		if pos then
			Horses.swap(player, pos)
		end
	end)
	G.Interact.onPrompt("ecurie_pouliner", function(player)
		Horses.breed(player)
	end)
	G.Interact.onPrompt("ecurie", function(player, prompt)
		local a = prompt.Parent
		local pos = a and (a:IsA("Attachment") and a.WorldPosition or (a:IsA("BasePart") and a.Position)) or nil
		if pos then
			Horses.fetch(player, pos + Vector3.new(0, 0, 0))
		end
	end)
end

-- espèce d'une monture (Config.MOUNTS) : celle enregistrée, sinon tirée de son identifiant
-- (même résultat à chaque chargement : un âne reste un âne) — 20 % d'ânes, 15 % de mulets
local function speciesOf(d): string
	if type(d.species) == "string" and Config.MOUNTS[d.species] then
		return d.species
	end
	local h = 0
	for i = 1, #tostring(d.id or "") do
		h = (h * 31 + string.byte(tostring(d.id), i)) % 1000003
	end
	local r = Random.new(h):NextNumber()
	return r < 0.2 and "ane" or (r < 0.35 and "mulet" or "cheval")
end
Horses.speciesOf = speciesOf

-- Lignées (19/11) : chaque monture a son ALLURE (0,85 à 1,25 × la vitesse de son espèce), tirée de
-- son identifiant pour les bêtes sauvages ou des fermes, HÉRITÉE des parents pour un poulain.
local function allureOf(d): number
	if type(d.allure) == "number" then
		return d.allure
	end
	local h = 7
	for i = 1, #tostring(d.id or "") do
		h = (h * 131 + string.byte(tostring(d.id), i)) % 2147483647
	end
	local r = Random.new(h)
	return math.floor((0.9 + r:NextNumber() * 0.12 + r:NextNumber() * 0.08) * 100 + 0.5) / 100
end
Horses.allureOf = allureOf
local function stars(a: number): string
	return a >= 1.12 and "★★★★" or a >= 1.04 and "★★★" or a >= 0.96 and "★★" or "★"
end
Horses.stars = stars
-- poulain : pas encore montable pendant FOAL_DAYS jours
Horses.FOAL_DAYS = 2
local function young(d): boolean
	return type(d.born) == "number" and G.world and G.world.day < d.born + Horses.FOAL_DAYS
end

local function label(h): string
	local m = Config.MOUNTS[h.species] or Config.MOUNTS.cheval
	local d = h.data or h
	return m.name .. " " .. string.lower(Config.HORSE_COATS[h.coat] and Config.HORSE_COATS[h.coat].name or "") .. " " .. stars(h.allure or allureOf(d))
		.. (young(d) and " (poulain)" or "")
end

local function paint(model: Model, coat: number, saddle: number)
	local c = Config.HORSE_COATS[coat] or Config.HORSE_COATS[1]
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "Robe" or p.Name == "Torse" then
				p.Color = c.body
			elseif p.Name == "Criniere" then
				p.Color = c.mane
			elseif p.Name == "Sabot" then
				p.Color = c.body:Lerp(Color3.new(0, 0, 0), 0.55)
			elseif p.Name == "Selle" then
				p.Transparency = saddle > 0 and 0 or 1
				if saddle > 0 then
					p.Color = Config.SADDLES[saddle] or Config.SADDLES[1]
				end
			end
		end
	end
end

local function setPrompts(h)
	for _, p in h.prompts or {} do
		p:Destroy()
	end
	h.prompts = {}
	local anchor = h.model.PrimaryPart
	local function add(text, mode, opts)
		opts = opts or {}
		opts.data = { Horse = h.id, Mode = mode }
		opts.dist = 10
		table.insert(h.prompts, G.Util.prompt(anchor, "horse", text, label(h), opts))
	end
	if G.Util.isPlayerId(h.owner) then
		add("Monter", "mount") -- le cheval d'un autre joueur : monter dessus = le voler
	elseif h.owner then
		add("Acheter (" .. (Config.MOUNTS[h.species] or Config.MOUNTS.cheval).price .. " or)", "buy", { hold = 0.5 })
		add("Voler (carotte)", "steal", { hold = 1, key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonY })
	else
		add("Apprivoiser (carotte)", "tame", { hold = 1 })
	end
end

local function build(reg, d, parent)
	local model = G.Util.clone("Cheval")
	if not model then
		return
	end
	local sp = speciesOf(d)
	local scale = (Config.MOUNTS[sp] or Config.MOUNTS.cheval).scale
	if scale ~= 1 then
		model:ScaleTo(scale)
	end
	paint(model, d.coat, d.saddle or 0)
	local y = G.Util.groundY(d.x, d.z) - 0.1
	model:PivotTo(CFrame.new(d.x, y, d.z) * CFrame.Angles(0, math.rad(d.yaw or math.random(0, 359)), 0))
	model.Parent = parent
	if young(d) then
		model:ScaleTo(model:GetScale() * 0.6) -- poulain
	end
	local h = { id = d.id, data = d, reg = reg, model = model, owner = d.owner, coat = d.coat, saddle = d.saddle or 0, species = sp, allure = allureOf(d) }
	live[d.id] = h
	if reg then
		table.insert(reg.horses, h)
	end
	setPrompts(h)
	return h
end

local function horseFolder(): Folder
	local f = workspace:FindFirstChild("ChevalJoueur")
	if not f then
		f = Instance.new("Folder")
		f.Name = "ChevalJoueur"
		f.Parent = workspace
	end
	return f
end

function Horses.onRegionLoad(reg)
	local folder = Instance.new("Folder")
	folder.Name = "Chevaux"
	folder.Parent = reg.folder
	reg.horses = {}
	for _, d in reg.plan.horses do
		local st = reg.state.horses[d.id]
		if not (st and st.gone) then
			build(reg, d, folder)
		end
	end
	-- le cheval du joueur, s'il a été laissé dans cette région
	for _, player in G.Game.players() do
		local prof = G.Joueurs.get(player)
		local ph = prof and prof.horse
		if ph and not riding[player] and not live[ph.id] and ph.region == reg.key then
			build(nil, { id = ph.id, x = ph.x, z = ph.z, coat = ph.coat, saddle = ph.saddle, species = ph.species, owner = G.Util.pid(player), allure = ph.allure, born = ph.born }, horseFolder())
		end
	end
end

function Horses.onRegionUnload(reg)
	for _, h in reg.horses or {} do
		live[h.id] = nil
	end
	-- le cheval du joueur laissé dans la région déchargée
	for id, h in live do
		if G.Util.isPlayerId(h.owner) and not h.mounted and h.model.Parent then
			local r = G.World.regionAt(h.model:GetPivot().Position)
			if not r or r == reg then
				h.model:Destroy()
				live[id] = nil
			end
		end
	end
end

local function makeMine(player: Player, h)
	local prof = G.Joueurs.get(player)
	-- l'ancien cheval part à l'écurie (pas de limite : on garde toutes ses bêtes, cf. Horses.swap)
	if prof.horse and prof.horse.id ~= h.id then
		local old = live[prof.horse.id]
		if old and not old.mounted then
			old.model:Destroy()
			live[prof.horse.id] = nil
		end
		prof.stable = prof.stable or {}
		table.insert(prof.stable, prof.horse)
		G.Util.toast(player, "🐴 Ton ancienne monture rejoint l'écurie (palefrenier : « Changer de monture »).")
	end
	if h.reg then
		h.reg.state.horses[h.id] = { gone = true }
		local i = table.find(h.reg.horses, h)
		if i then
			table.remove(h.reg.horses, i)
		end
	end
	-- volé à un autre joueur : il le perd
	local victim = G.Util.playerOf(h.owner)
	if victim and victim ~= player then
		local vp = G.Joueurs.get(victim)
		if vp and vp.horse and vp.horse.id == h.id then
			vp.horse = nil
			G.Joueurs.markDirty(victim)
		end
	end
	h.reg = nil
	h.owner = G.Util.pid(player)
	h.model.Parent = horseFolder()
	local pos = h.model:GetPivot().Position
	local reg = G.World.regionAt(pos)
	prof.horse = { id = h.id, coat = h.coat, saddle = math.max(1, h.saddle), x = math.floor(pos.X), z = math.floor(pos.Z), region = reg and reg.key or "0,0", world = G.world.id, species = h.species,
		allure = h.allure, born = h.data and h.data.born }
	h.saddle = prof.horse.saddle
	paint(h.model, h.coat, h.saddle)
	setPrompts(h)
	G.Joueurs.markDirty(player)
end

function Horses.use(player: Player, h, mode: string)
	local prof = G.Joueurs.get(player)
	if mode == "mount" then
		if h.owner and not G.Util.owns(player, h.owner) then
			G.Law.crime(player, "theft", h.model:GetPivot().Position, h.owner)
			makeMine(player, h)
		end
		Horses.mount(player, h)
	elseif mode == "buy" then
		local price = (Config.MOUNTS[h.species] or Config.MOUNTS.cheval).price
		if not G.Joueurs.take(player, "gold", price) then
			G.Util.toast(player, "Il te faut " .. price .. " or.")
			return
		end
		local owner = G.Npcs.byId(h.owner)
		if owner then
			G.Npcs.addOp(owner, player, 10)
			G.Npcs.react(owner, "gift")
		end
		makeMine(player, h)
		G.Util.toast(player, "Tu as acheté : " .. label(h) .. " ! Approche-toi et monte dessus.", "big")
	elseif mode == "steal" or mode == "tame" then
		local t = Config.TAMING.horse
		-- un cheval dressé se méfie des inconnus ; l'âne et le mulet se laissent mieux approcher
		local diff = math.max(1, t.diff + (mode == "steal" and 1 or 0) - (h.species == "ane" and 1 or 0))
		local ease = (Config.MOUNTS[h.species] or Config.MOUNTS.cheval).tame
		if not G.Joueurs.needSkill(player, "dressage", Config.TAME_SKILL[diff] or 0, "Ce cheval") then
			return
		end
		if not G.Joueurs.take(player, "carrot", 1) then
			G.Util.toast(player, "Il te faut une carotte pour l'amadouer.")
			return
		end
		local skill = G.Joueurs.skill(player, "dressage")
		local voix = G.Joueurs.talent(player, "apprivoiseur")
		G.Minijeux.start(player, {
			title = mode == "steal" and "Voler le cheval" or "Apprivoiser le cheval",
			hint = "Approche en douceur : appuie quand le cœur passe dans la zone.",
			pins = 1 + diff,
			zone = math.clamp((0.30 - diff * 0.035 + skill * 0.004 + voix * 0.03) / ease, 0.08, 0.5),
			speed = 0.55 + diff * 0.17,
			misses = 1 + voix,
			timeout = 35,
			near = function()
				local r = G.Util.root(player)
				return r ~= nil and h.model.Parent ~= nil and (r.Position - h.model:GetPivot().Position).Magnitude < 14
			end,
		}, function(ok)
			if not ok then
				G.Joueurs.addSkillXp(player, "dressage", 3 * diff)
				G.Util.toast(player, "Le cheval se cabre et s'éloigne… (carotte perdue)")
				return
			end
			G.Joueurs.addSkillXp(player, "dressage", 12 * diff)
			if mode == "steal" then
				G.Law.crime(player, "theft", h.model:GetPivot().Position, h.owner)
				G.Npcs.remember(h.owner, "robbed")
			end
			makeMine(player, h)
			if mode == "tame" and G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "apprivoiser", "bete") end
			G.Util.toast(player, mode == "tame" and "Le cheval croque la carotte… il est à toi !" or "Le cheval te suit volontiers. Il est à toi… en quelque sorte.", "big")
		end)
	end
end

function Horses.mount(player: Player, h)
	if riding[player] or player:GetAttribute("Carrying") then
		return
	end
	if young(h.data or h) then
		G.Util.toast(player, "C'est encore un poulain : il sera assez fort pour te porter dans quelques jours.")
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then
		return
	end
	local assise = h.model.PrimaryPart:FindFirstChild("Assise")
	local seat = assise and (h.model.PrimaryPart.CFrame:PointToObjectSpace(assise.WorldPosition).Y) or 5.2
	riding[player] = h
	h.mounted = true
	for _, p in h.prompts do
		p.Enabled = false
	end
	local hcf = h.model:GetPivot()
	h.oldHip = hum.HipHeight
	local rootHalf = root.Size.Y / 2
	-- le joueur se place sur la selle, le cheval sous lui
	char:PivotTo(CFrame.new(hcf.Position + Vector3.new(0, seat + SIT_OFFSET + 0.3, 0)) * (hcf - hcf.Position))
	for _, p in h.model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.Massless = true
			p.CanCollide = false
			p.CanQuery = false
		end
	end
	local base = h.model.PrimaryPart
	h.model:PivotTo(root.CFrame * CFrame.new(0, -(seat + SIT_OFFSET), 0))
	for _, p in h.model:GetDescendants() do
		if p:IsA("BasePart") and p ~= base then
			local w = Instance.new("WeldConstraint")
			w.Name = "Monture"
			w.Part0 = base
			w.Part1 = p
			w.Parent = p
		end
	end
	local w = Instance.new("WeldConstraint")
	w.Name = "Monture"
	w.Part0 = root
	w.Part1 = base
	w.Parent = base
	h.model.Parent = char
	hum.HipHeight = seat + SIT_OFFSET - rootHalf
	local prof = G.Joueurs.get(player)
	local shod = prof and prof.horse and prof.horse.id == h.id and prof.horse.shod
	-- harnachement dans le sac (Shared/Equilibre) : la meilleure selle, et les étriers
	local tack = 1
	local okE, Eq = pcall(require, game:GetService("ReplicatedStorage").Shared.Equilibre)
	if okE and Eq.TACK then
		for id, m in Eq.TACK do
			if G.Joueurs.has(player, id) and m > tack then
				tack = m
			end
		end
		if G.Joueurs.has(player, "stirrups") then
			tack *= Eq.STIRRUPS or 1
		end
	end
	player:SetAttribute("MountSpeed", (Config.MOUNTS[h.species] or Config.MOUNTS.cheval).speed * (shod and (Config.SHOD_BONUS or 1) or 1) * (h.allure or 1) * (1 + 0.12 * G.Joueurs.talent(player, "cavalier")) * tack) -- allure (Game)
	player:SetAttribute("Riding", true)
end

function Horses.dismount(player: Player, silent: boolean)
	G.Game.noFall(player, 2) -- descendre de cheval n'est pas une chute
	local h = riding[player]
	if not h then
		return
	end
	riding[player] = nil
	h.mounted = false
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	for _, w in h.model:GetDescendants() do
		if w:IsA("WeldConstraint") and w.Name == "Monture" then
			w:Destroy()
		end
	end
	local pos = root and root.Position or h.model:GetPivot().Position
	local look = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
	local yaw = math.atan2(-look.X, -look.Z)
	local y = G.Util.groundY(pos.X, pos.Z)
	if G.Util.isWater(pos.X, pos.Z) then
		y = G.Config.WATER_Y
	end
	h.model.Parent = horseFolder()
	for _, p in h.model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanQuery = true
		end
	end
	h.model:PivotTo(CFrame.new(pos.X, y - 0.1, pos.Z) * CFrame.Angles(0, yaw, 0))
	if hum then
		hum.HipHeight = h.oldHip or 2
	end
	if root and char then
		local right = root.CFrame.RightVector
		char:PivotTo(CFrame.new(pos.X + right.X * 4, y + 3.5, pos.Z + right.Z * 4) * CFrame.Angles(0, yaw, 0))
	end
	player:SetAttribute("Riding", false)
	player:SetAttribute("MountSpeed", nil)
	for _, p in h.prompts do
		p.Enabled = true
	end
	local prof = G.Joueurs.get(player)
	if prof and prof.horse then
		local reg = G.World.regionAt(Vector3.new(pos.X, 0, pos.Z))
		prof.horse.x, prof.horse.z = math.floor(pos.X), math.floor(pos.Z)
		prof.horse.region = reg and reg.key or prof.horse.region
	end
end

-- Écurie (18/11) : on y fait venir sa monture, où qu'elle soit sur l'île (même si sa région n'est pas
-- chargée) ; contre une petite pension, l'écurie la ramène.
Horses.STABLE_FEE = 5
function Horses.fetch(player: Player, at: Vector3)
	local prof = G.Joueurs.get(player)
	if not prof or not prof.horse or riding[player] then
		if prof and not prof.horse then
			G.Util.toast(player, "Tu n'as pas de monture. (Les fermes en vendent.)")
		end
		return
	end
	if prof.horse.world and G.world.id and prof.horse.world ~= G.world.id then
		G.Util.toast(player, "Ta monture est restée dans un autre monde.")
		return
	end
	if not G.Joueurs.take(player, "gold", Horses.STABLE_FEE) then
		G.Util.toast(player, "La pension de l'écurie coûte " .. Horses.STABLE_FEE .. " or.")
		return
	end
	local ph = prof.horse
	local h = live[ph.id]
	if not h then
		h = build(nil, { id = ph.id, x = at.X, z = at.Z, coat = ph.coat, saddle = ph.saddle, species = ph.species, owner = G.Util.pid(player), allure = ph.allure, born = ph.born }, horseFolder())
	end
	if not h then
		return
	end
	h.model:PivotTo(CFrame.new(at.X, G.Util.groundY(at.X, at.Z) - 0.1, at.Z))
	ph.x, ph.z = math.floor(at.X), math.floor(at.Z)
	local reg = G.World.regionAt(at)
	ph.region = reg and reg.key or ph.region
	G.Joueurs.markDirty(player)
	G.Util.toast(player, "🐴 Le palefrenier t'amène ta monture (" .. Horses.STABLE_FEE .. " or).")
end

-- Changer de monture à l'écurie : la monture du moment y reste, la suivante (dans l'ordre d'arrivée)
-- sort et attend à côté. Même pension que pour la faire venir.
function Horses.swap(player: Player, at: Vector3): boolean
	local prof = G.Joueurs.get(player)
	if not prof or riding[player] then
		return false
	end
	prof.stable = prof.stable or {}
	if #prof.stable == 0 then
		G.Util.toast(player, "Tu n'as pas d'autre monture à l'écurie.")
		return false
	end
	if not G.Joueurs.take(player, "gold", Horses.STABLE_FEE) then
		G.Util.toast(player, "La pension de l'écurie coûte " .. Horses.STABLE_FEE .. " or.")
		return false
	end
	local nxt = table.remove(prof.stable, 1)
	if prof.horse then
		local old = live[prof.horse.id]
		if old then
			old.model:Destroy()
			live[prof.horse.id] = nil
		end
		table.insert(prof.stable, prof.horse)
	end
	nxt.world = G.world.id
	nxt.x, nxt.z = math.floor(at.X), math.floor(at.Z)
	local reg = G.World.regionAt(at)
	nxt.region = reg and reg.key or nxt.region
	prof.horse = nxt
	local h = build(nil, { id = nxt.id, x = at.X, z = at.Z, coat = nxt.coat, saddle = nxt.saddle, species = nxt.species, owner = G.Util.pid(player), allure = nxt.allure, born = nxt.born }, horseFolder())
	G.Joueurs.markDirty(player)
	G.Util.toast(player, "🐴 Le palefrenier sort " .. (h and label(h) or "ta monture") .. " (" .. Horses.STABLE_FEE .. " or).")
	return true
end

-- Poulinage : la monture du moment + une monture adulte de l'écurie. Cheval × cheval = cheval,
-- âne × âne = âne, cheval × âne = mulet ; le mulet est stérile. Le poulain hérite de la moyenne des
-- allures (± un peu), de la robe d'un parent ; il grandit FOAL_DAYS jours avant d'être monté.
Horses.BREED_COST = { gold = 40, carrot = 3 }
Horses.BREED_EVERY = 2 -- jours entre deux poulinages
local function child(a: string, b: string): string?
	if a == "mulet" or b == "mulet" then
		return nil
	end
	if a == b then
		return a
	end
	return "mulet"
end
Horses.childSpecies = child
function Horses.breed(player: Player): boolean
	local prof = G.Joueurs.get(player)
	local ph = prof and prof.horse
	if not ph then
		G.Util.toast(player, "Il te faut une monture.")
		return false
	end
	if young(ph) then
		G.Util.toast(player, "Ta monture est encore un poulain.")
		return false
	end
	local spA = ph.species or "cheval"
	if spA == "mulet" then
		G.Util.toast(player, "Un mulet ne peut pas avoir de petit.")
		return false
	end
	local mate
	for _, d in prof.stable or {} do
		if not young(d) and child(spA, d.species or "cheval") then
			mate = d
			break
		end
	end
	if not mate then
		G.Util.toast(player, "Il faut une autre monture adulte à l'écurie (pas un mulet).")
		return false
	end
	if prof.breedDay and G.world.day < prof.breedDay + Horses.BREED_EVERY then
		G.Util.toast(player, "Tes bêtes ont besoin de repos : reviens dans quelques jours.")
		return false
	end
	local c = Horses.BREED_COST
	if (G.Joueurs.count(player, "carrot") or 0) < c.carrot or (G.Joueurs.count(player, "gold") or 0) < c.gold then
		G.Util.toast(player, "Le poulinage demande " .. c.carrot .. " carottes et " .. c.gold .. " or (soins du palefrenier).")
		return false
	end
	G.Joueurs.take(player, "carrot", c.carrot)
	G.Joueurs.take(player, "gold", c.gold)
	local rng = Random.new()
	local a = (allureOf(ph) + allureOf(mate)) / 2 + (rng:NextNumber() - 0.5) * 0.08
	-- le savoir-faire du dresseur compte un peu (sélection des meilleurs)
	a += math.min(0.03, (G.Joueurs.skill(player, "dressage") or 0) * 0.0005)
	a = math.clamp(math.floor(a * 100 + 0.5) / 100, 0.85, 1.25)
	local foal = {
		id = G.Util.newId("pl"),
		coat = rng:NextNumber() < 0.1 and rng:NextInteger(1, #Config.HORSE_COATS) or (rng:NextNumber() < 0.5 and ph.coat or mate.coat),
		saddle = 1, species = child(spA, mate.species or "cheval"), allure = a, born = G.world.day, world = G.world.id,
		parents = { ph.id, mate.id },
	}
	prof.stable = prof.stable or {}
	table.insert(prof.stable, foal)
	prof.breedDay = G.world.day
	G.Joueurs.addSkillXp(player, "dressage", 20)
	G.Joueurs.markDirty(player)
	G.Joueurs.sync(player)
	local m = Config.MOUNTS[foal.species] or Config.MOUNTS.cheval
	G.Util.toast(player, string.format("🐣 Un poulain est né à l'écurie : %s, allure %s. Il grandit %d jours.", string.lower(m.name), stars(a), Horses.FOAL_DAYS), "big")
	return true
end

-- /ecurie : la monture du moment puis celles de l'écurie
function Horses.describe(player: Player): { string }
	local prof = G.Joueurs.get(player)
	local lines = {}
	local function line(d, tag)
		local m = Config.MOUNTS[d.species] or Config.MOUNTS.cheval
		local coat = Config.HORSE_COATS[d.coat] and Config.HORSE_COATS[d.coat].name or ""
		table.insert(lines, string.format("%s %s %s %s (allure %d %%)%s%s", tag, m.name, string.lower(coat), stars(allureOf(d)),
			math.floor(allureOf(d) * 100 + 0.5), young(d) and " · poulain" or "", d.shod and " · ferré" or ""))
	end
	if prof and prof.horse then
		line(prof.horse, "🐎")
	end
	for i, d in (prof and prof.stable) or {} do
		line(d, i .. ".")
	end
	if #lines == 0 then
		lines[1] = "Aucune monture. (Les fermes en vendent ; les chevaux sauvages s'apprivoisent.)"
	end
	return lines
end

-- Ferrer sa monture (fers à cheval forgés à l'enclume) : il faut être à côté d'elle (ou dessus).
-- Une fois ferrée, elle le reste ; +12 % d'allure (Config.SHOD_BONUS).
function Horses.shoe(player: Player, item: string): boolean
	local prof = G.Joueurs.get(player)
	local ph = prof and prof.horse
	if not ph then
		G.Util.toast(player, "Tu n'as pas de monture à ferrer.")
		return false
	end
	if ph.shod then
		G.Util.toast(player, "Ta monture est déjà ferrée.")
		return false
	end
	local h = live[ph.id]
	local root = G.Util.root(player)
	local close = riding[player] ~= nil or (h and root and (h.model:GetPivot().Position - root.Position).Magnitude < 10)
	if not close then
		G.Util.toast(player, "Approche-toi de ta monture pour la ferrer.")
		return false
	end
	if not G.Joueurs.take(player, item, 1) then
		return false
	end
	ph.shod = true
	G.Joueurs.markDirty(player)
	G.Joueurs.sync(player)
	if riding[player] then
		player:SetAttribute("MountSpeed", (player:GetAttribute("MountSpeed") or 1) * (Config.SHOD_BONUS or 1))
	end
	local pos = h and h.model:GetPivot().Position or root.Position
	G.Util.sfx("forge", pos)
	G.Util.geste(player, "fabriquer")
	G.Util.toast(player, "🧲 Ta monture est ferrée : elle galope plus vite (+" .. math.floor(((Config.SHOD_BONUS or 1) - 1) * 100 + 0.5) .. " %).", "gain")
	return true
end

-- Siffler : le cheval du joueur accourt (s'il n'est pas trop loin)
function Horses.whistle(player: Player)
	local prof = G.Joueurs.get(player)
	local root = G.Util.root(player)
	if not prof or not prof.horse or not root or riding[player] then
		return
	end
	local h = live[prof.horse.id]
	if not h then
		G.Util.toast(player, "Ton cheval est trop loin pour t'entendre.")
		return
	end
	local pos = root.Position - root.CFrame.LookVector * 5
	if G.Util.isWater(pos.X, pos.Z) then
		pos = root.Position
	end
	h.model:PivotTo(CFrame.new(pos.X, G.Util.groundY(pos.X, pos.Z) - 0.1, pos.Z) * (root.CFrame - root.Position))
	prof.horse.x, prof.horse.z = math.floor(pos.X), math.floor(pos.Z)
	local reg = G.World.regionAt(pos)
	prof.horse.region = reg and reg.key or prof.horse.region
	G.Util.toast(player, "Ton cheval accourt !")
end

function Horses.step(dt: number)
	-- rien de continu pour l'instant (les chevaux sauvages broutent sur place)
end

function Horses.newDay() end

function Horses.isRiding(player: Player): boolean
	return riding[player] ~= nil
end

return Horses
