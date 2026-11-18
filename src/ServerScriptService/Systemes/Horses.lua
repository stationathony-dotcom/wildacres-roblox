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
local function label(h): string
	local m = Config.MOUNTS[h.species] or Config.MOUNTS.cheval
	return m.name .. " " .. string.lower(Config.HORSE_COATS[h.coat] and Config.HORSE_COATS[h.coat].name or "")
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
	local h = { id = d.id, data = d, reg = reg, model = model, owner = d.owner, coat = d.coat, saddle = d.saddle or 0, species = sp }
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
			build(nil, { id = ph.id, x = ph.x, z = ph.z, coat = ph.coat, saddle = ph.saddle, species = ph.species, owner = G.Util.pid(player) }, horseFolder())
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
	-- l'ancien cheval est relâché
	if prof.horse and live[prof.horse.id] and live[prof.horse.id] ~= h then
		local old = live[prof.horse.id]
		old.owner = nil
		setPrompts(old)
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
	prof.horse = { id = h.id, coat = h.coat, saddle = math.max(1, h.saddle), x = math.floor(pos.X), z = math.floor(pos.Z), region = reg and reg.key or "0,0", world = G.world.id, species = h.species }
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
			G.Util.toast(player, mode == "tame" and "Le cheval croque la carotte… il est à toi !" or "Le cheval te suit volontiers. Il est à toi… en quelque sorte.", "big")
		end)
	end
end

function Horses.mount(player: Player, h)
	if riding[player] or player:GetAttribute("Carrying") then
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
	player:SetAttribute("MountSpeed", (Config.MOUNTS[h.species] or Config.MOUNTS.cheval).speed * (shod and (Config.SHOD_BONUS or 1) or 1)) -- allure (Game)
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
		h = build(nil, { id = ph.id, x = at.X, z = at.Z, coat = ph.coat, saddle = ph.saddle, species = ph.species, owner = G.Util.pid(player) }, horseFolder())
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
