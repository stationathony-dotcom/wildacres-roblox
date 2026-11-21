-- Petits outils partagés côté serveur : invites d'action (ProximityPrompt), émoticônes,
-- messages au joueur, clonage de modèles, hauteur du sol.

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local U = {}
local G

function U.init(g)
	G = g
end

-- Invite d'action. `action` est le nom du gestionnaire (cf. Interact), `data` des attributs.
function U.prompt(parent: Instance, action: string, text: string, object: string?, opts)
	local p = Instance.new("ProximityPrompt")
	p.Name = "Invite_" .. action
	p.ActionText = text
	p.ObjectText = object or ""
	p.MaxActivationDistance = (opts and opts.dist) or 9
	p.HoldDuration = (opts and opts.hold) or 0
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = (opts and opts.key) or Enum.KeyCode.E
	p.GamepadKeyCode = (opts and opts.pad) or Enum.KeyCode.ButtonX
	p.Style = Enum.ProximityPromptStyle.Custom
	p.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	p:SetAttribute("Action", action)
	if opts and opts.data then
		for k, v in opts.data do
			p:SetAttribute(k, v)
		end
	end
	if opts and opts.offset then
		p.UIOffset = opts.offset
	end
	p.Parent = parent
	return p
end

-- Point d'ancrage invisible (pour poser des invites à un endroit précis d'un modèle)
function U.anchor(parent: Instance, cf: CFrame, name: string?): Attachment
	local a = Instance.new("Attachment")
	a.Name = name or "Ancre"
	local base = parent:IsA("Model") and (parent :: Model).PrimaryPart or parent
	a.Parent = base
	a.WorldCFrame = cf
	return a
end

function U.clone(name: string): Model?
	local t = ServerStorage.Modeles:FindFirstChild(name)
	if not t then
		local built = G.Config.Catalogue.build(name) or (G.Bestiaire and G.Bestiaire.build and G.Bestiaire.build(name))
		if built then
			return built
		end
		warn("[WildAcres] modèle manquant : " .. name)
		return nil
	end
	return t:Clone()
end

-- Exécute fn(...) en faisant TOMBER AU SOL, près de pos, tout ce que le joueur y gagne (Systemes/Butin).
-- Sans le système Butin (en erreur), tout va dans le sac comme avant.
function U.auSol(player: Player, pos: Vector3?, ignore: Instance?, fn, ...)
	local B = G.Butin
	local cap = B and rawget(B, "capture")
	if cap and typeof(pos) == "Vector3" then
		return cap(player, pos, ignore, fn, ...)
	end
	return fn(...)
end

-- Trouvailles du catalogue (récolte, pêche, chasse, fouille…) : ajoutées au sac du joueur
-- (ou au sol si l'appel est enrobé par U.auSol)
function U.finds(player: Player, source: string, pos: Vector3?)
	local root = U.root(player)
	pos = pos or (root and root.Position)
	local biome = pos and G.Clock.biomeAt(pos) or nil
	local luck = G.Joueurs.stats(player).chance or 0
	local digging = source == "rock" or source == "dig"
	if digging then
		luck += 2 * G.Joueurs.talent(player, "prospecteur") -- talent Explorateur
	end
	local got = G.Config.Catalogue.rollFinds(source, biome, luck)
	if digging and G.Joueurs.talent(player, "archeologue") > 0 and math.random() < 0.03 then
		table.insert(got, { "old_page", 1 })
	end
	if G.Clock.isNight() and source ~= "event" then
		for _, f in G.Config.Catalogue.rollFinds("night", biome, luck) do
			table.insert(got, f)
		end
	end
	for _, f in got do
		G.Joueurs.add(player, f[1], f[2])
	end
	return got
end

-- Bulle d'émoticône au-dessus d'un modèle (jamais de texte : règle du jeu)
function U.emote(model: Model, kind: string, duration: number?)
	local emoji = G.Dialogue.EMOJI[kind]
	if not emoji or not model or not model.Parent then
		return
	end
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	if not head then
		return
	end
	local old = head:FindFirstChild("Emote")
	if old then
		old:Destroy()
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Emote"
	bb.Size = UDim2.fromOffset(46, 46)
	bb.StudsOffsetWorldSpace = Vector3.new(0, model:FindFirstChild("Head") and 2.4 or 5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(255, 250, 235)
	bg.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = bg
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 60, 40)
	stroke.Thickness = 2
	stroke.Parent = bg
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(0.8, 0.8)
	t.Position = UDim2.fromScale(0.1, 0.1)
	t.BackgroundTransparency = 1
	t.Text = emoji
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.Parent = bg
	bg.Parent = bb
	bb.Parent = head
	Debris:AddItem(bb, duration or 2.5)
end

function U.toast(player: Player?, text: string, kind: string?)
	if player then
		G.remotes.Notify:FireClient(player, text, kind or "info")
	else
		G.remotes.Notify:FireAllClients(text, kind or "info")
	end
end

function U.tag(inst: Instance, tag: string)
	CollectionService:AddTag(inst, tag)
end

-- Hauteur du sol (plan de la région, interpolation entre centres de cases)
function U.groundY(x: number, z: number): number
	local wg = G.wg
	local CELL = G.Config.CELL
	local fx, fz = x / CELL - 0.5, z / CELL - 0.5
	local cx, cz = math.floor(fx), math.floor(fz)
	local tx, tz = fx - cx, fz - cz
	local function h(ax, az)
		local rx, rz = G.WG.regionOf(ax, az)
		local plan = wg.planCache[rx .. "," .. rz]
		if not plan then
			plan = wg:plan(rx, rz)
		end
		local i = G.WG.idx(ax - plan.x0, az - plan.z0)
		if plan.water[i] then
			return 0
		end
		local t = G.Terraforme and G.Terraforme.cell and G.Terraforme.cell(ax, az)
		return plan.H[i] + (t and t.d * 4 or 0)
	end
	local a, b, c, d = h(cx, cz), h(cx + 1, cz), h(cx, cz + 1), h(cx + 1, cz + 1)
	return (a * (1 - tx) + b * tx) * (1 - tz) + (c * (1 - tx) + d * tx) * tz
end

-- Vrai si le point est dans l'eau (case d'eau du plan)
function U.isWater(x: number, z: number): boolean
	local cx, cz = math.floor(x / G.Config.CELL), math.floor(z / G.Config.CELL)
	local rx, rz = G.WG.regionOf(cx, cz)
	local plan = G.wg.planCache[rx .. "," .. rz] or G.wg:plan(rx, rz)
	if plan.water[G.WG.idx(cx - plan.x0, cz - plan.z0)] == true then
		return true
	end
	local t = G.Terraforme and G.Terraforme.cell and G.Terraforme.cell(cx, cz)
	return t ~= nil and t.w == true
end

-- Joueur le plus proche d'une position (et sa distance)
-- Positions des joueurs, recalculées au plus une fois par image (niveau de détail des simulations :
-- monstres, bêtes et PNJ loin de tout joueur pensent moins souvent)
local spotsT, spots = -1, {}
function U.playerSpots(): { Vector3 }
	local now = os.clock()
	if now - spotsT < 0.03 then
		return spots
	end
	spotsT = now
	table.clear(spots)
	for _, pl in game:GetService("Players"):GetPlayers() do
		local ch = pl.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		if root then
			table.insert(spots, root.Position)
		end
	end
	return spots
end

function U.playerDist(pos: Vector3): number
	local bd = math.huge
	for _, p in U.playerSpots() do
		local d = (p - pos).Magnitude
		if d < bd then
			bd = d
		end
	end
	return bd
end

-- Geste du joueur (cueillir, fabriquer, manger, batir, commerce) : tous les clients l'animent
-- (StarterPlayerScripts/Gestes). Un compteur relance le même geste deux fois de suite.
-- Compteur PAR joueur : sa parité alterne les poings (Gestes : gauche, droite, gauche…).
local gesteN = setmetatable({}, { __mode = "k" })
function U.geste(player: Player, kind: string)
	gesteN[player] = (gesteN[player] or 0) + 1
	player:SetAttribute("Geste", kind .. ":" .. gesteN[player])
end

function U.nearestPlayer(pos: Vector3, maxDist: number?): (Player?, number)
	local best, bd = nil, maxDist or math.huge
	for _, pl in game:GetService("Players"):GetPlayers() do
		local ch = pl.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		if root then
			local d = (root.Position - pos).Magnitude
			if d < bd then
				best, bd = pl, d
			end
		end
	end
	return best, bd
end

-- Propriétaires (multi) : "u<UserId>" = un joueur, "n…" = un PNJ, "wild" = personne
function U.pid(player: Player): string
	return "u" .. player.UserId
end

function U.isPlayerId(owner: any): boolean
	return type(owner) == "string" and string.sub(owner, 1, 1) == "u" and tonumber(string.sub(owner, 2)) ~= nil
end

function U.owns(player: Player, owner: any): boolean
	return owner == U.pid(player)
end

-- Confiance accordée par un propriétaire (dans ce monde) : "coffres" (ouvrir portes et coffres sans
-- crime) < "batir" (en plus : construire sur ses parcelles). Réglée par /autoriser (Admin).
local TRUST = { coffres = 1, batir = 2 }
function U.trusted(player: Player, owner: any, level: string): boolean
	if not U.isPlayerId(owner) or not G.world then
		return false
	end
	local rec = G.world.players[string.sub(owner, 2)]
	local t = rec and rec.trust and rec.trust[tostring(player.UserId)]
	return t ~= nil and (TRUST[t] or 0) >= (TRUST[level] or 99)
end

-- Joueur présent dans ce monde pour un identifiant "u<UserId>"
function U.playerOf(owner: any): Player?
	if not U.isPlayerId(owner) then
		return nil
	end
	return game:GetService("Players"):GetPlayerByUserId(tonumber(string.sub(owner, 2)) :: number)
end

function U.root(player: Player): BasePart?
	local ch = player.Character
	return ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Bruitage 3D joué chez les joueurs proches (le client choisit le son : voir Ambiance, SFX)
function U.sfx(name: string, pos: Vector3, only: Player?)
	if only then
		G.remotes.Fx:FireClient(only, "sfx", name, pos)
	else
		G.remotes.Fx:FireAllClients("sfx", name, pos)
	end
end

-- Identifiant unique d'objet du monde (avant : nombre aléatoire → collisions possibles à partir de
-- quelques milliers d'objets ; reprendre l'un pouvait toucher l'autre)
local idCounter = 0
function U.newId(prefix: string): string
	idCounter += 1
	return prefix .. string.sub(game:GetService("HttpService"):GenerateGUID(false), 1, 13) .. idCounter
end

return U
