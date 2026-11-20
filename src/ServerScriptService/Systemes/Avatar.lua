-- Apparence par calques (comme dans Godot) : teint, coiffure et couleur, tenue, couvre-chef.
-- Les PNJ sont habillés depuis leur « look » ; le joueur porte le chapeau de son équipement.

local Avatar = {}
local G
local Design = require(game:GetService("ReplicatedStorage").Shared.GearDesign)

local LOOK_COST = 20 -- le premier choix est gratuit ; ensuite barbier / tailleur payants (l'or sort de l'économie)

function Avatar.init(g)
	G = g
	G.Interact.onAction("set_look", function(player, data)
		Avatar.setLook(player, data)
	end)
end

local function weld(model: Instance, head: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, mat: Enum.Material?, shape: Enum.PartType?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	if shape then
		p.Shape = shape
	end
	p.CFrame = head.CFrame * offset
	p.Parent = model
	local w = Instance.new("WeldConstraint")
	w.Part0 = head
	w.Part1 = p
	w.Parent = p
	return p
end

local V = Vector3.new
local C = CFrame.new

-- Coiffures (tête R15 ≈ 1,16 x 1,18 x 1,16 ; l'avant de la tête regarde vers -Z)
local HAIRS = {
	court = function(m, h, c)
		weld(m, h, "Cheveux", V(1.24, 0.34, 1.24), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.24, 0.7, 0.3), C(0, 0.22, 0.5), c)
	end,
	herisse = function(m, h, c)
		weld(m, h, "Cheveux", V(1.22, 0.3, 1.22), C(0, 0.5, 0.02), c)
		for i = -1, 1 do
			weld(m, h, "Meche", V(0.28, 0.35, 0.28), C(i * 0.36, 0.78, -0.1 + math.abs(i) * 0.15) * CFrame.Angles(0, 0, -i * 0.3), c)
		end
	end,
	chauve = function(m, h, c)
		weld(m, h, "Cheveux", V(0.2, 0.45, 0.7), C(-0.6, 0.05, 0.15), c)
		weld(m, h, "Cheveux", V(0.2, 0.45, 0.7), C(0.6, 0.05, 0.15), c)
	end,
	barbe = function(m, h, c)
		weld(m, h, "Cheveux", V(1.24, 0.32, 1.24), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.24, 0.6, 0.3), C(0, 0.25, 0.5), c)
		weld(m, h, "Barbe", V(0.95, 0.42, 0.22), C(0, -0.42, -0.55), c)
		weld(m, h, "Moustache", V(0.6, 0.12, 0.08), C(0, -0.17, -0.6), c)
	end,
	long = function(m, h, c)
		weld(m, h, "Cheveux", V(1.26, 0.34, 1.26), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.28, 1.7, 0.36), C(0, -0.2, 0.52), c)
		weld(m, h, "Meche", V(0.22, 1.2, 0.5), C(-0.62, -0.05, 0.1), c)
		weld(m, h, "Meche", V(0.22, 1.2, 0.5), C(0.62, -0.05, 0.1), c)
	end,
	chignon = function(m, h, c)
		weld(m, h, "Cheveux", V(1.26, 0.34, 1.26), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.26, 0.8, 0.3), C(0, 0.2, 0.52), c)
		weld(m, h, "Chignon", V(0.6, 0.6, 0.6), C(0, 0.55, 0.72), c)
	end,
	tresses = function(m, h, c)
		weld(m, h, "Cheveux", V(1.26, 0.34, 1.26), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.26, 0.8, 0.3), C(0, 0.2, 0.52), c)
		weld(m, h, "Tresse", V(0.26, 1.5, 0.26), C(-0.5, -0.55, 0.45), c)
		weld(m, h, "Tresse", V(0.26, 1.5, 0.26), C(0.5, -0.55, 0.45), c)
		weld(m, h, "Ruban", V(0.32, 0.16, 0.32), C(-0.5, -1.25, 0.45), Color3.fromRGB(220, 70, 90))
		weld(m, h, "Ruban", V(0.32, 0.16, 0.32), C(0.5, -1.25, 0.45), Color3.fromRGB(220, 70, 90))
	end,
	carre = function(m, h, c)
		weld(m, h, "Cheveux", V(1.28, 0.36, 1.28), C(0, 0.5, 0.02), c)
		weld(m, h, "Cheveux", V(1.3, 1, 0.32), C(0, 0.1, 0.52), c)
		weld(m, h, "Meche", V(0.22, 0.9, 0.9), C(-0.63, 0.1, 0.12), c)
		weld(m, h, "Meche", V(0.22, 0.9, 0.9), C(0.63, 0.1, 0.12), c)
		weld(m, h, "Frange", V(1.2, 0.2, 0.15), C(0, 0.38, -0.6), c)
	end,
}

local STRAW = Color3.fromRGB(226, 196, 104)
local HATS = {
	paille = function(m, h)
		weld(m, h, "Chapeau", V(0.12, 2.3, 2.3), C(0, 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)), STRAW, Enum.Material.Fabric, Enum.PartType.Cylinder)
		weld(m, h, "Chapeau", V(0.7, 1.3, 1.3), C(0, 0.95, 0) * CFrame.Angles(0, 0, math.rad(90)), STRAW, Enum.Material.Fabric, Enum.PartType.Cylinder)
		weld(m, h, "Ruban", V(0.2, 1.34, 1.34), C(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(190, 60, 50), Enum.Material.Fabric, Enum.PartType.Cylinder)
	end,
	beret = function(m, h)
		weld(m, h, "Chapeau", V(1.4, 0.3, 1.4), C(0.1, 0.7, 0.05) * CFrame.Angles(0, 0, math.rad(-8)), Color3.fromRGB(150, 40, 60), Enum.Material.Fabric)
		weld(m, h, "Queue", V(0.12, 0.2, 0.12), C(0.12, 0.92, 0.05), Color3.fromRGB(150, 40, 60))
	end,
	toque = function(m, h)
		weld(m, h, "Chapeau", V(1.25, 0.5, 1.25), C(0, 0.75, 0), Color3.fromRGB(245, 245, 240), Enum.Material.Fabric)
		weld(m, h, "Chapeau", V(1.4, 0.7, 1.4), C(0, 1.3, 0), Color3.fromRGB(250, 250, 248), Enum.Material.Fabric)
	end,
	bonnet = function(m, h)
		weld(m, h, "Chapeau", V(1.3, 0.5, 1.3), C(0, 0.68, 0), Color3.fromRGB(200, 50, 50), Enum.Material.Fabric)
		weld(m, h, "Chapeau", V(0.8, 0.5, 0.8), C(0, 1.1, 0.1), Color3.fromRGB(200, 50, 50), Enum.Material.Fabric)
		weld(m, h, "Pompon", V(0.4, 0.4, 0.4), C(0, 1.45, 0.2), Color3.fromRGB(250, 250, 250), Enum.Material.Fabric, Enum.PartType.Ball)
	end,
	sherif = function(m, h)
		local brown = Color3.fromRGB(110, 74, 44)
		weld(m, h, "Chapeau", V(2.3, 0.14, 1.9), C(0, 0.62, 0), brown, Enum.Material.Fabric)
		weld(m, h, "Bord", V(0.3, 0.3, 1.9), C(-1.05, 0.72, 0), brown, Enum.Material.Fabric)
		weld(m, h, "Bord", V(0.3, 0.3, 1.9), C(1.05, 0.72, 0), brown, Enum.Material.Fabric)
		weld(m, h, "Chapeau", V(1.2, 0.7, 1.2), C(0, 1.0, 0), brown, Enum.Material.Fabric)
		weld(m, h, "Ruban", V(1.24, 0.14, 1.24), C(0, 0.75, 0), Color3.fromRGB(40, 30, 20))
	end,
	tricorne = function(m, h)
		local c = Color3.fromRGB(40, 36, 40)
		weld(m, h, "Chapeau", V(1.9, 0.5, 1.5), C(0, 0.8, 0), c, Enum.Material.Fabric)
		weld(m, h, "Galon", V(1.94, 0.1, 1.54), C(0, 1.0, 0), Color3.fromRGB(230, 190, 70), Enum.Material.Metal)
	end,
	mage = function(m, h)
		local c = Color3.fromRGB(70, 60, 150)
		weld(m, h, "Chapeau", V(2.2, 0.12, 2.2), C(0, 0.62, 0), c, Enum.Material.Fabric)
		weld(m, h, "Chapeau", V(1.1, 0.8, 1.1), C(0, 1.05, 0), c, Enum.Material.Fabric)
		weld(m, h, "Chapeau", V(0.7, 0.7, 0.7), C(0.1, 1.7, 0.05), c, Enum.Material.Fabric)
		weld(m, h, "Pointe", V(0.35, 0.6, 0.35), C(0.25, 2.2, 0.1), c, Enum.Material.Fabric)
		weld(m, h, "Etoile", V(0.25, 0.25, 0.06), C(0, 1.1, -0.57), Color3.fromRGB(250, 220, 90), Enum.Material.Neon)
	end,
	hautdeforme = function(m, h)
		local c = Color3.fromRGB(40, 110, 60)
		weld(m, h, "Chapeau", V(1.8, 0.12, 1.8), C(0, 0.62, 0), c, Enum.Material.Fabric)
		weld(m, h, "Chapeau", V(1.15, 1.2, 1.15), C(0, 1.25, 0), c, Enum.Material.Fabric)
		weld(m, h, "Ruban", V(1.18, 0.2, 1.18), C(0, 0.8, 0), Color3.fromRGB(230, 190, 70))
	end,
	capuche = function(m, h)
		local c = Color3.fromRGB(60, 100, 60)
		weld(m, h, "Capuche", V(1.4, 0.4, 1.4), C(0, 0.6, 0.05), c, Enum.Material.Fabric)
		weld(m, h, "Capuche", V(1.4, 1.2, 0.3), C(0, 0.05, 0.62), c, Enum.Material.Fabric)
		weld(m, h, "Capuche", V(0.2, 1.1, 1.3), C(-0.68, 0.1, 0.05), c, Enum.Material.Fabric)
		weld(m, h, "Capuche", V(0.2, 1.1, 1.3), C(0.68, 0.1, 0.05), c, Enum.Material.Fabric)
	end,
	bandeau = function(m, h)
		weld(m, h, "Bandeau", V(1.2, 0.14, 1.22), C(0, 0.3, 0), Color3.fromRGB(30, 30, 30))
		weld(m, h, "Cache", V(0.32, 0.3, 0.06), C(-0.24, 0.08, -0.6), Color3.fromRGB(30, 30, 30))
	end,
}
Avatar.HATS = HATS

local SKIN_PARTS = { "Head", "LeftHand", "RightHand" }
local SHIRT_PARTS = { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }
local PANTS_PARTS = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }
local FEET = { "LeftFoot", "RightFoot" }

-- Habille un PNJ (mannequin R15 PNJ_Base) selon son look
function Avatar.dress(model: Model, look, role: string)
	local WG = G.WG
	local skin = WG.SKINS[look.skin] or WG.SKINS[1]
	local shirt = WG.SHIRTS[look.shirt] or WG.SHIRTS[1]
	local pants = WG.PANTS[look.pants] or WG.PANTS[1]
	local hairC = WG.HAIR_COLORS[look.hairColor] or WG.HAIR_COLORS[1]
	if role == "sheriff" then
		shirt = Color3.fromRGB(150, 110, 70)
		pants = Color3.fromRGB(60, 60, 70)
	end
	for _, n in SKIN_PARTS do
		local p = model:FindFirstChild(n)
		if p then
			p.Color = skin
		end
	end
	for _, n in SHIRT_PARTS do
		local p = model:FindFirstChild(n)
		if p then
			p.Color = shirt
		end
	end
	-- avant-bras nus pour certains
	if look.shirt % 3 == 0 then
		for _, n in { "LeftLowerArm", "RightLowerArm" } do
			model[n].Color = skin
		end
	end
	for _, n in PANTS_PARTS do
		local p = model:FindFirstChild(n)
		if p then
			p.Color = pants
		end
	end
	for _, n in FEET do
		local p = model:FindFirstChild(n)
		if p then
			p.Color = Color3.fromRGB(70, 50, 36)
		end
	end
	local head = model:FindFirstChild("Head") :: BasePart
	if HAIRS[look.hair] then
		HAIRS[look.hair](model, head, hairC)
	end
	if look.hat and HATS[look.hat] then
		HATS[look.hat](model, head)
	end
	-- tablier pour le marchand, étoile pour le shérif
	local torso = model:FindFirstChild("UpperTorso") :: BasePart
	if role == "merchant" then
		weld(model, torso, "Tablier", V(1.6, 1.9, 0.1), C(0, -0.35, -0.53), Color3.fromRGB(240, 236, 220), Enum.Material.Fabric)
	elseif role == "sheriff" then
		weld(model, torso, "Etoile", V(0.4, 0.4, 0.08), C(-0.45, 0.3, -0.54) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(240, 200, 60), Enum.Material.Metal)
		weld(model, torso, "Etoile", V(0.4, 0.4, 0.08), C(-0.45, 0.3, -0.54), Color3.fromRGB(240, 200, 60), Enum.Material.Metal)
	elseif role == "farmer" then
		weld(model, torso, "Salopette", V(1.5, 1.2, 0.08), C(0, -0.2, -0.53), Color3.fromRGB(70, 100, 150), Enum.Material.Fabric)
		weld(model, torso, "Bretelle", V(0.2, 0.7, 0.08), C(-0.5, 0.55, -0.53), Color3.fromRGB(70, 100, 150), Enum.Material.Fabric)
		weld(model, torso, "Bretelle", V(0.2, 0.7, 0.08), C(0.5, 0.55, -0.53), Color3.fromRGB(70, 100, 150), Enum.Material.Fabric)
	end
	if look.female and look.hair ~= "chauve" then
		-- cils
		for _, x in { -0.24, 0.24 } do
			weld(model, head, "Cil", V(0.24, 0.05, 0.03), C(x, 0.22, -head.Size.Z / 2 - 0.02), Color3.fromRGB(30, 30, 30))
		end
	end
end

-- ----------------------------------------------------------------- Apparence du joueur
-- prof.look = { mode = "roblox" | "villageois", skin, hair, hairColor, shirt, pants, paid }
-- « roblox » : l'avatar du joueur, avec chapeau et armure du jeu par-dessus.
-- « villageois » : corps lisse aux couleurs choisies (palette médiévale des PNJ), sans
-- accessoires ni vêtements modernes : cohérent avec le monde 100 % médiéval.

local HAIR_LIST = { "court", "herisse", "chauve", "barbe", "long", "chignon", "tresses", "carre" }
Avatar.HAIR_LIST = HAIR_LIST
Avatar.LOOK_COST = LOOK_COST

local function validLook(data)
	local WG = G.WG
	local function idx(v, max)
		v = tonumber(v)
		return (v and v == math.floor(v) and v >= 1 and v <= max) and v or 1
	end
	return {
		mode = "villageois", -- 19/11 (sa demande) : plus de skin Roblox, tout le monde a une allure du monde
		skin = idx(data.skin, #WG.SKINS),
		hair = table.find(HAIR_LIST, data.hair) and data.hair or "court",
		hairColor = idx(data.hairColor, #WG.HAIR_COLORS),
		shirt = idx(data.shirt, #WG.SHIRTS),
		pants = idx(data.pants, #WG.PANTS),
	}
end

-- Création et établissements (19/11, ses mots : « personnaliser son perso en arrivant, avec des
-- attributs qui collent à ce monde, pas garder son skin Roblox » ; « modifier par la suite en
-- débloquant des trucs type coupe de cheveux » ; « coiffeur et établissements dans le genre »).
--   · à la PREMIÈRE arrivée : écran de création, gratuit, parmi le choix de départ (STARTER) ;
--   · ensuite : le BARBIER (coiffure, couleur de cheveux) et le TAILLEUR (tunique, chausses), au marché
--     des villages. Un style hors du choix de départ se DÉBLOQUE une fois pour toutes (prix UNLOCK),
--     puis on en change contre une petite façon (FEE). Le teint ne change pas après la création.
-- prof.unlocks = { hair = { [nom] = true }, hairColor = { ["5"] = true }, shirt = {…}, pants = {…} }
Avatar.STARTER = {
	hair = { court = true, long = true, chauve = true, chignon = true },
	hairColor = { [1] = true, [2] = true, [3] = true, [4] = true },
	shirt = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
	pants = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
}
Avatar.UNLOCK = { hair = 60, hairColor = 40, shirt = 30, pants = 30 }
Avatar.FEE = 10
Avatar.SHOPS = { barbier = { "hair", "hairColor" }, tailleur = { "shirt", "pants" } }
local session = setmetatable({}, { __mode = "k" }) -- joueur -> { ctx, e, t }

local function owned(prof, key: string, value): boolean
	if Avatar.STARTER[key][value] then
		return true
	end
	local u = prof.unlocks and prof.unlocks[key]
	return u ~= nil and u[tostring(value)] == true
end
Avatar.owned = owned

-- apparence par défaut (avant la création) : tirée de l'identifiant, dans le choix de départ
function Avatar.defaultLook(player: Player)
	local r = Random.new(player.UserId)
	local hairs = { "court", "long", "chauve", "chignon" }
	return { mode = "villageois", skin = r:NextInteger(1, #G.WG.SKINS), hair = hairs[r:NextInteger(1, #hairs)], hairColor = r:NextInteger(1, 4),
		shirt = r:NextInteger(1, 5), pants = r:NextInteger(1, 5) }
end

-- ce que le client doit savoir pour l'écran (possédé, prix)
local function shopInfo(prof, ctx: string)
	local WG = G.WG
	local own = { hair = {}, hairColor = {}, shirt = {}, pants = {} }
	for _, h in HAIR_LIST do
		own.hair[h] = owned(prof, "hair", h)
	end
	for key, list in { hairColor = WG.HAIR_COLORS, shirt = WG.SHIRTS, pants = WG.PANTS } do
		for i in list do
			own[key][i] = owned(prof, key, i)
		end
	end
	return { kind = "look", ctx = ctx, owned = own, prices = Avatar.UNLOCK, fee = Avatar.FEE, look = prof.look }
end

-- ouvre l'écran d'apparence (création à l'arrivée, ou chez un barbier / tailleur e)
function Avatar.open(player: Player, ctx: string, e)
	local prof = G.Joueurs.get(player)
	if not prof then
		return
	end
	if ctx == "creation" and prof.look and prof.look.created then
		return
	end
	session[player] = { ctx = ctx, e = e, t = os.clock() }
	G.remotes.Menu:FireClient(player, shopInfo(prof, ctx))
end

function Avatar.setLook(player: Player, data)
	local prof = G.Joueurs.get(player)
	if not prof or type(data) ~= "table" then
		return
	end
	local s = session[player]
	local ctx = s and s.ctx
	if not s or os.clock() - s.t > 600 or (data.ctx and data.ctx ~= ctx) then
		G.Util.toast(player, "Ton apparence se change chez le barbier ou le tailleur, au marché des villages.")
		return
	end
	if s.e then
		local root = G.Util.root(player)
		if not root or not s.e.root or (root.Position - s.e.root.Position).Magnitude > 20 then
			G.Util.toast(player, "Rapproche-toi de l'artisan.")
			return
		end
	end
	local want = validLook(data)
	local cur = prof.look and prof.look.created and prof.look or nil
	local look
	local cost, newUnlocks = 0, {}
	if ctx == "creation" then
		if cur then
			return
		end
		for key in Avatar.STARTER do
			if not owned(prof, key, want[key]) then
				G.Util.toast(player, "Ce style se débloque plus tard, chez le barbier ou le tailleur.")
				return
			end
		end
		look = want
	else
		local keys = Avatar.SHOPS[ctx]
		if not keys or not cur then
			return
		end
		look = table.clone(cur)
		local changed = false
		for _, key in keys do
			if want[key] ~= cur[key] then
				changed = true
				look[key] = want[key]
				if not owned(prof, key, want[key]) then
					cost += Avatar.UNLOCK[key]
					table.insert(newUnlocks, { key, want[key] })
				end
			end
		end
		if not changed then
			return
		end
		cost += Avatar.FEE
		if not G.Joueurs.take(player, "gold", cost) then
			G.Util.toast(player, "Il te faut " .. cost .. " 💰 pour ça.")
			return
		end
		prof.unlocks = prof.unlocks or {}
		for _, u in newUnlocks do
			prof.unlocks[u[1]] = prof.unlocks[u[1]] or {}
			prof.unlocks[u[1]][tostring(u[2])] = true
		end
	end
	look.mode = "villageois"
	look.created = true
	look.paid = true
	prof.look = look
	session[player] = nil
	G.Joueurs.markDirty(player)
	G.Joueurs.sync(player)
	if ctx == "creation" then
		G.Util.toast(player, "✨ Bienvenue dans Wild Acres ! Le barbier et le tailleur des villages débloquent d'autres styles.", "big")
	else
		G.Util.toast(player, string.format("✂️ C'est fait (-%d 💰)%s.", cost, #newUnlocks > 0 and (", " .. #newUnlocks .. " style(s) débloqué(s) pour toujours") or ""), "gain")
	end
	G.remotes.Menu:FireClient(player, { kind = "close" })
	if player.Character then
		Avatar.refresh(player)
	end
end

local function clearFolder(char: Model, name: string)
	local old = char:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

-- Corps « villageois » : vêtements Roblox et accessoires retirés, couleurs de la palette
function Avatar.applyLook(player: Player)
	local char = player.Character
	local prof = G.Joueurs.get(player)
	if not char or not prof then
		return
	end
	clearFolder(char, "Coiffure_WA")
	-- jamais le skin Roblox : sans apparence choisie (ou l'ancien mode « avatar »), celle par défaut
	if not prof.look or prof.look.mode ~= "villageois" then
		prof.look = Avatar.defaultLook(player)
		G.Joueurs.markDirty(player)
	end
	local look = prof.look
	for _, c in char:GetChildren() do
		if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") or c:IsA("Accessory") then
			c:Destroy()
		end
	end
	local WG = G.WG
	local function paint(names, color)
		for _, n in names do
			local p = char:FindFirstChild(n)
			if p and p:IsA("BasePart") then
				p.Color = color
				if p:IsA("MeshPart") then
					pcall(function()
						p.TextureID = ""
					end)
				end
			end
		end
	end
	paint(SKIN_PARTS, WG.SKINS[look.skin] or WG.SKINS[1])
	paint(SHIRT_PARTS, WG.SHIRTS[look.shirt] or WG.SHIRTS[1])
	paint(PANTS_PARTS, WG.PANTS[look.pants] or WG.PANTS[1])
	paint(FEET, Color3.fromRGB(70, 50, 36))
	local head = char:FindFirstChild("Head") :: BasePart?
	if head then
		local hairModel = Instance.new("Model")
		hairModel.Name = "Coiffure_WA"
		hairModel.Parent = char
		-- pas de cheveux sous une capuche ou une toque (ils traverseraient)
		local hat = prof.equipped and prof.equipped.hat
		local fn = HAIRS[look.hair]
		local form = hat and Design.formOf(hat)
		if fn and not (hat and (hat.visual == "capuche" or hat.visual == "toque" or form == "hood" or (form and form:find("helm",1,true)))) then
			fn(hairModel, head, WG.HAIR_COLORS[look.hairColor] or WG.HAIR_COLORS[1])
		end
	end
end

-- Armure portée : visible sur le corps (cuir, mailles, plastron, cape, tunique…)
local ARMOR_LOOKS = {
	{ "diamant", Color3.fromRGB(101, 145, 165), Enum.Material.Metal },
	{ "cuir", Color3.fromRGB(120, 78, 44), Enum.Material.Leather },
	{ "maille", Color3.fromRGB(150, 155, 160), Enum.Material.DiamondPlate },
	{ "cuivre", Color3.fromRGB(184, 115, 60), Enum.Material.Metal },
	{ "plastron", Color3.fromRGB(170, 170, 178), Enum.Material.Metal },
	{ "plaque", Color3.fromRGB(170, 170, 178), Enum.Material.Metal },
	{ "cape", Color3.fromRGB(40, 36, 48), Enum.Material.Fabric },
	{ "tunique", Color3.fromRGB(70, 110, 60), Enum.Material.Fabric },
	{ "robe", Color3.fromRGB(80, 60, 120), Enum.Material.Fabric },
}

function Avatar.applyArmor(player: Player)
	local char = player.Character
	local prof = G.Joueurs.get(player)
	if not char then
		return
	end
	clearFolder(char, "Armure_WA")
	local armor = prof and prof.equipped and prof.equipped.armor
	local torso = char:FindFirstChild("UpperTorso") :: BasePart?
	if not armor or not torso then
		return
	end
	local name = string.lower(armor.name or "")
	local look = ARMOR_LOOKS[1]
	for _, l in ARMOR_LOOKS do
		if string.find(name, l[1], 1, true) then
			look = l
			break
		end
	end
	local m = Instance.new("Model")
	m.Name = "Armure_WA"
	m.Parent = char
	local col, mat = look[2], look[3]
	local ts = torso.Size
	local style = Design.style(armor)
	local form = Design.formOf(armor)
	if armor.design or form=="scale" or form=="beetle" then
		col = style.color
		mat = (form=="tunic" or form=="coat") and Enum.Material.Fabric
			or (form=="leather" or form=="brigandine") and Enum.Material.Leather
			or form=="mail" and Enum.Material.DiamondPlate or Enum.Material.Metal
	end
	local trim = armor.design and style.trim or col:Lerp(Color3.fromRGB(239, 209, 156), 0.36)
	local bronze = Color3.fromRGB(177, 130, 70)
	if look[1] == "cape" then
		weld(m, torso, "Cape", V(ts.X * 1.05, ts.Y * 2.1, 0.12), C(0, -ts.Y * 0.5, ts.Z / 2 + 0.08), col, mat)
		weld(m, torso, "Col", V(ts.X * 1.1, 0.25, ts.Z * 1.15), C(0, ts.Y / 2, 0), col, mat)
		for _, side in ipairs({ -1, 1 }) do
			weld(m, torso, "Ourlet de cape", V(ts.X * 0.055, ts.Y * 1.97, 0.035),
				C(side * ts.X * 0.49, -ts.Y * 0.47, ts.Z / 2 + 0.149), trim, mat)
		end
		weld(m, torso, "Agrafe", V(0.17, 0.17, 0.10), C(0, ts.Y * 0.32, -ts.Z / 2 - 0.07), bronze, Enum.Material.Metal, Enum.PartType.Ball)
		return
	end
	weld(m, torso, "Plastron", V(ts.X * 1.08, ts.Y * 1.02, ts.Z * 1.12), C(0, 0, 0), col, mat)
	local front = -ts.Z * 0.57
	if form=="scale" or form=="mail" then
		for row=0,2 do
			for column=-1,1 do
				local x=(column*0.24+(row%2)*0.047)*ts.X
				local y=(0.31-row*0.23)*ts.Y
				weld(m,torso,form=="mail" and "Mailles en rang" or "Écaille",
					V(ts.X*0.22,ts.Y*0.165,0.062),C(x,y,front-0.024)*CFrame.Angles(0,0,column*0.08),trim:Lerp(col,(row+column+1)%2*0.43),mat)
			end
		end
	elseif form=="plate" or form=="beetle" then
		for s=-1,1,2 do
			weld(m,torso,form=="beetle" and "Élytre" or "Plaque de torse",V(ts.X*0.43,ts.Y*0.62,0.11),
				C(s*ts.X*0.23,ts.Y*0.14,front-0.038)*CFrame.Angles(0,-s*0.11,s*0.07),col:Lerp(trim,0.28),mat)
		end
	end
	local cloth = mat == Enum.Material.Fabric
	local fastening = cloth and Enum.Material.Fabric or Enum.Material.Leather
	for _, side in ipairs({ -1, 1 }) do
		weld(m, torso, cloth and "Galon" or "Sangle", V(ts.X * 0.08, ts.Y * 0.82, 0.043),
			C(side * ts.X * 0.30, 0.02, front - 0.025) * CFrame.Angles(0, 0, side * 0.13), trim, fastening)
		if not cloth then
			for _, y in ipairs({-0.21, 0.22}) do
				weld(m, torso, "Rivet", V(0.086, 0.086, 0.054), C(side * ts.X * 0.30, y * ts.Y, front - 0.06),
					bronze, Enum.Material.Metal, Enum.PartType.Ball)
			end
		end
	end
	weld(m, torso, "Ceinture", V(ts.X * 1.10, ts.Y * 0.135, ts.Z * 1.15),
		C(0, -ts.Y * 0.36, 0), Color3.fromRGB(68, 43, 30), Enum.Material.Leather)
	weld(m, torso, "Boucle", V(ts.X * 0.19, ts.Y * 0.14, 0.08),
		C(0, -ts.Y * 0.36, front - 0.04), bronze, Enum.Material.Metal)
	if look[1] == "diamant" then
		weld(m, torso, "Sertissage", V(ts.X * 0.25, ts.X * 0.25, 0.13),
			C(0, ts.Y * 0.14, front - 0.053) * CFrame.Angles(0, 0, math.pi / 4), bronze, Enum.Material.Metal)
		weld(m, torso, "Diamant", V(ts.X * 0.17, ts.X * 0.17, 0.16),
			C(0, ts.Y * 0.14, front - 0.116) * CFrame.Angles(0, 0, math.pi / 4), Color3.fromRGB(131, 225, 234), Enum.Material.Glass)
	end
	local lower = char:FindFirstChild("LowerTorso") :: BasePart?
	if lower then
		local ls = lower.Size
		weld(m, lower, "Jupe", V(ls.X * 1.12, ls.Y * 1.3, ls.Z * 1.16), C(0, -ls.Y * 0.2, 0), col, mat)
	end
	if not prof.equipped.shoulders and look[1] ~= "tunique" and look[1] ~= "robe" and form~="tunic" then
		for _, side in { "LeftUpperArm", "RightUpperArm" } do
			local arm = char:FindFirstChild(side) :: BasePart?
			if arm then
				weld(m, arm, "Epauliere", V(arm.Size.X * 1.26, arm.Size.Y * 0.47, arm.Size.Z * 1.25), C(0, arm.Size.Y * 0.28, 0), col, mat)
				weld(m, arm, "Bord d’épaule", V(arm.Size.X * 1.27, arm.Size.Y * 0.075, arm.Size.Z * 1.27),
					C(0, arm.Size.Y * 0.095, 0), trim, mat)
			end
		end
	end
	-- liseré de rareté (lisible de loin)
	local r = G.Gear.RARITIES[armor.rarity or 1]
	if r and (armor.rarity or 1) >= 2 then
		weld(m, torso, "Lisere", V(ts.X * 1.1, 0.06, ts.Z * 1.14), C(0, -ts.Y * 0.45, 0), r.color:Lerp(bronze, 0.40), mat)
	end
end

local function wearable(char, item, left, right, build)
	if not item then return end
	local style,form = Design.style(item),Design.formOf(item)
	for _, side in ipairs({{left,-1},{right,1}}) do
		local part=char:FindFirstChild(side[1])
		if part and part:IsA("BasePart") then build(part,style,form,side[2]) end
	end
end

function Avatar.applyExtraGear(player: Player)
	local char=player.Character
	local prof=G.Joueurs.get(player)
	if not char or not prof then return end
	clearFolder(char,"Equipement_WA")
	local holder=Instance.new("Model")
	holder.Name="Equipement_WA"
	holder.Parent=char
	local worn=prof.equipped or {}
	local hand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
	if worn.offhand and hand and hand:IsA("BasePart") then
		local form = Design.formOf(worn.offhand)
		local style = Design.style(worn.offhand)
		local metal = Enum.Material.Metal
		if form == "torch" then
			weld(holder, hand, "Manche de torche", V(0.17, 1.1, 0.17), C(0, 0.25, -0.27), style.color, Enum.Material.Wood)
			local flame = weld(holder, hand, "Braise", V(0.23, 0.26, 0.23), C(0, 0.88, -0.27), Color3.fromRGB(255, 144, 48), Enum.Material.Neon, Enum.PartType.Ball)
			local glow = Instance.new("PointLight")
			glow.Color, glow.Brightness, glow.Range = Color3.fromRGB(255, 174, 82), 1.3, 13
			glow.Parent = flame
		else
			local shape = form == "roundshield" and Enum.PartType.Cylinder or Enum.PartType.Block
			local pose = C(-0.36, 0.28, 0) * CFrame.Angles(0, 0, math.rad(12))
			local height = form == "roundshield" and 1.4 or 1.8
			weld(holder, hand, "Bouclier", V(0.14, height, 1.35), pose, style.trim, metal, shape)
			weld(holder, hand, "Face du bouclier", V(0.16, height - 0.16, 1.19), pose, style.color, Enum.Material.WoodPlanks, shape)
			weld(holder, hand, "Ombilic", V(0.25, 0.33, 0.33), pose * C(-0.12, 0, 0), style.trim, metal, Enum.PartType.Ball)
		end
	end
	wearable(char,worn.gloves,"LeftHand","RightHand",function(p,s,form)
		local z=p.Size
		local material=form=="gauntlets" and Enum.Material.Metal or Enum.Material.Leather
		weld(holder,p,"Gant",V(z.X*1.14,z.Y*(form=="fingerless" and 0.61 or 1.06),z.Z*1.17),C(0,form=="fingerless" and z.Y*0.19 or 0,0),s.color,material)
		weld(holder,p,"Manchette",V(z.X*1.20,z.Y*0.26,z.Z*1.22),C(0,z.Y*0.37,0),s.trim,material)
	end)
	wearable(char,worn.shoulders,"LeftUpperArm","RightUpperArm",function(p,s,form,sign)
		local z=p.Size
		weld(holder,p,"Épaulière",V(z.X*1.41,z.Y*0.43,z.Z*1.37),C(sign*z.X*0.09,z.Y*0.30,0)*CFrame.Angles(0,0,sign*0.13),s.color,Enum.Material.Metal)
		for i=0,form=="lamellar" and 2 or 1 do
			weld(holder,p,"Lame d’épaule",V(z.X*(1.37-i*0.06),z.Y*0.07,z.Z*1.38),C(0,z.Y*(0.22-i*0.13),0),s.trim,Enum.Material.Metal)
		end
		if form=="hornshoulder" then
			weld(holder,p,"Corne",V(z.X*0.23,z.Y*0.34,z.Z*0.25),C(sign*z.X*0.52,z.Y*0.55,0)*CFrame.Angles(0,0,-sign*0.32),s.trim,Enum.Material.SmoothPlastic)
		end
	end)
	local pants=worn.legs
	if pants then
		local form=Design.formOf(pants)
		local pair=form=="greaves" and {"LeftLowerLeg","RightLowerLeg"} or {"LeftUpperLeg","RightUpperLeg"}
		wearable(char,pants,pair[1],pair[2],function(p,s,kind)
			local z=p.Size
			local material=kind=="greaves" and Enum.Material.Metal or Enum.Material.Fabric
			weld(holder,p,kind=="greaves" and "Jambière" or "Jambe de pantalon",V(z.X*1.08,z.Y*0.97,z.Z*1.10),C(),s.color,material)
			weld(holder,p,"Galon",V(z.X*0.08,z.Y*0.82,0.047),C(z.X*0.25,0,-z.Z*0.57),s.trim,material)
		end)
		if form~="greaves" then
			wearable(char,pants,"LeftLowerLeg","RightLowerLeg",function(p,s)
				local z=p.Size
				weld(holder,p,"Bas de pantalon",V(z.X*1.08,z.Y*0.96,z.Z*1.10),C(),s.color,Enum.Material.Fabric)
			end)
		end
	end
	wearable(char,worn.boots,"LeftFoot","RightFoot",function(p,s,form)
		local z=p.Size
		local material=form=="sabatons" and Enum.Material.Metal or Enum.Material.Leather
		weld(holder,p,"Botte",V(z.X*1.11,z.Y*1.26,z.Z*1.13),C(0,z.Y*0.06,-z.Z*0.021),s.color,material)
		weld(holder,p,"Semelle",V(z.X*1.12,z.Y*0.19,z.Z*1.14),C(0,-z.Y*0.44,0),s.trim,Enum.Material.Leather)
	end)
	if worn.boots and Design.formOf(worn.boots)=="tallboots" then
		wearable(char,worn.boots,"LeftLowerLeg","RightLowerLeg",function(p,s)
			local z=p.Size
			weld(holder,p,"Tige de botte",V(z.X*1.15,z.Y*0.41,z.Z*1.16),C(0,-z.Y*0.30,0),s.color,Enum.Material.Leather)
			weld(holder,p,"Revers",V(z.X*1.17,z.Y*0.07,z.Z*1.18),C(0,-z.Y*0.09,0),s.trim,Enum.Material.Leather)
		end)
	end
	local jewel,torso=worn.trinket,char:FindFirstChild("UpperTorso")
	local jewelForm=jewel and Design.formOf(jewel)
	if jewel and torso and torso:IsA("BasePart") then
		local n=Design.lower(jewel.name)
		local s=Design.style(jewel)
		if jewelForm=="ring" or jewelForm=="bracelet" or n:match("^anneau") or n:match("^bague") then
			local hand=char:FindFirstChild("RightHand")
			if hand and hand:IsA("BasePart") then
				local z=hand.Size
				weld(holder,hand,"Bijou",V(z.X*0.27,z.Y*0.18,0.09),C(z.X*0.23,-z.Y*0.22,-z.Z*0.56),s.trim,Enum.Material.Metal)
			end
		elseif jewelForm=="necklace" or jewelForm=="pendant" or jewelForm=="medallion" or jewelForm=="brooch"
			or n:match("^amulette") or n:match("^collier") or n:match("^pendentif") or n:match("^talisman") then
			local z=torso.Size
			local x=jewelForm=="brooch" and z.X*0.29 or 0
			local front=-z.Z*0.63
			if jewelForm~="brooch" then
				for sign=-1,1,2 do
					weld(holder,torso,"Chaînette",V(0.05,z.Y*0.33,0.05),C(sign*z.X*0.13,z.Y*0.30,front)*CFrame.Angles(0,0,-sign*0.50),s.trim,Enum.Material.Metal)
				end
			end
			weld(holder,torso,"Serti",V(z.X*0.19,z.Y*0.22,0.12),C(x,z.Y*0.14,front)*CFrame.Angles(0,0,math.pi/4),s.trim,Enum.Material.Metal)
			weld(holder,torso,"Pierre",V(z.X*0.13,z.Y*0.15,0.13),C(x,z.Y*0.14,front-0.064)*CFrame.Angles(0,0,math.pi/4),s.color,Enum.Material.Glass)
		end
	end
	local weapon=worn.weapon
	local hip=char:FindFirstChild("LowerTorso") or torso
	local folder=game:GetService("ReplicatedStorage"):FindFirstChild("IconesEquipement")
	local preview=weapon and folder and folder:FindFirstChild("weapon:"..weapon.name)
	if preview and hip and hip:IsA("BasePart") then
		local display=preview:Clone()
		display.Name="Arme à la ceinture"
		local _,size=display:GetBoundingBox()
		local scale=math.min(1,hip.Size.Y*1.7 / math.max(size.X,size.Y,size.Z))
		display:ScaleTo(scale)
		local bounds=display:GetBoundingBox()
		local target=hip.CFrame*C(-hip.Size.X*0.68,-hip.Size.Y*0.34,hip.Size.Z*0.26)*CFrame.Angles(0,0,-0.38)
		display:PivotTo(target * bounds:ToObjectSpace(display:GetPivot()))
		for _,piece in display:GetDescendants() do
			if piece:IsA("BasePart") then
				piece.Massless,piece.Anchored,piece.CanCollide,piece.CanQuery,piece.CanTouch=true,false,false,false,false
				local mount=Instance.new("WeldConstraint")
				mount.Part0,mount.Part1,mount.Parent=hip,piece,piece
			end
		end
		display.Parent=holder
	end
end

local function fittedHelmet(folder,head,hat)
	local form=Design.formOf(hat)
	local s=Design.style(hat)
	local z=head.Size
	local fabric=form=="hood"
	local material=fabric and Enum.Material.Fabric or Enum.Material.Metal
	weld(folder,head,"Calotte",V(z.X*1.13,z.Y*0.66,z.Z*1.15),C(0,z.Y*0.27,0),s.color,material,Enum.PartType.Ball)
	for sign=-1,1,2 do
		weld(folder,head,"Joue",V(z.X*0.17,z.Y*0.79,z.Z*0.64),C(sign*z.X*0.48,-z.Y*0.02,-z.Z*0.10),s.color,material)
	end
	if form=="closedhelm" then
		weld(folder,head,"Visière",V(z.X*0.91,z.Y*0.29,0.13),C(0,-z.Y*0.18,-z.Z*0.57),s.trim,Enum.Material.Metal)
	elseif form=="nasalhelm" then
		weld(folder,head,"Nasal",V(z.X*0.11,z.Y*0.50,0.12),C(0,-z.Y*0.04,-z.Z*0.62),s.trim,Enum.Material.Metal)
	elseif form=="cresthelm" then
		weld(folder,head,"Crête",V(z.X*0.13,z.Y*0.39,z.Z*0.76),C(0,z.Y*0.68,0),s.trim,Enum.Material.Metal)
	end
end

-- Apparence + armure + chapeau d'équipement (appelé à l'apparition et à chaque changement d'équipement)
function Avatar.refresh(player: Player)
	local char = player.Character
	if not char then
		return
	end
	Avatar.applyLook(player)
	Avatar.applyArmor(player)
	Avatar.applyExtraGear(player)
	local old = char:FindFirstChild("Chapeau_WA")
	if old then
		old:Destroy()
	end
	local prof = G.Joueurs.get(player)
	local hat = prof and prof.equipped.hat
	local form=hat and Design.formOf(hat)
	local fitted=hat and (form=="hood" or (form and form:find("helm",1,true)))
	local head = char:FindFirstChild("Head") :: BasePart?
	if hat and head and (fitted or HATS[hat.visual] or hat.design) then
		local folder = Instance.new("Model")
		folder.Name = "Chapeau_WA"
		folder.Parent = char
		-- on cache les accessoires de tête Roblox pour que le chapeau se voie
		for _, a in char:GetChildren() do
			if a:IsA("Accessory") and (a.AccessoryType == Enum.AccessoryType.Hat) then
				local h = a:FindFirstChild("Handle")
				if h then
					h.Transparency = 1
				end
			end
		end
		if fitted then
			fittedHelmet(folder,head,hat)
		else
			(HATS[hat.visual] or HATS.paille)(folder, head)
		end
	else
		for _, a in char:GetChildren() do
			if a:IsA("Accessory") and (a.AccessoryType == Enum.AccessoryType.Hat) then
				local h = a:FindFirstChild("Handle")
				if h then
					h.Transparency = 0
				end
			end
		end
	end
	Avatar.applyCape(player)
end

-- Cape de noblesse (18/11) : récompense visible des titres accordés par un seigneur (Metiers).
-- Écuyer : cape brune ; Chevalier : bleue à bordure d'argent ; Baron : pourpre brodée d'or.
local CAPES = {
	{ cloth = Color3.fromRGB(110, 76, 46) },
	{ cloth = Color3.fromRGB(40, 64, 130), trim = Color3.fromRGB(200, 205, 215) },
	{ cloth = Color3.fromRGB(96, 30, 92), trim = Color3.fromRGB(226, 186, 70) },
}
function Avatar.applyCape(player: Player)
	local char = player.Character
	local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
	if not torso then
		return
	end
	local old = char:FindFirstChild("Cape_WA")
	if old then
		old:Destroy()
	end
	local prof = G.Joueurs.get(player)
	local rank = prof and prof.stats and prof.stats.noblesse or 0
	local c = CAPES[math.clamp(rank, 0, #CAPES)]
	local cape = prof and prof.equipped and prof.equipped.cape
	local style = cape and Design.style(cape)
	local form = cape and Design.formOf(cape)
	if style then c = {cloth=style.color,trim=(c and c.trim) or style.trim} end
	if not c then
		return
	end
	local folder = Instance.new("Model")
	folder.Name = "Cape_WA"
	folder.Parent = char
	local h = torso.Size.Y
	local length=form=="mantle" and 1.25 or 2.15
	local z=torso.Size.Z/2+0.13
	if form=="splitcape" then
		for sign=-1,1,2 do
			weld(folder,torso,"Pan de mantelet",V(torso.Size.X*0.48,h*1.76,0.11),C(sign*torso.Size.X*0.26,-h*0.51,z),c.cloth,Enum.Material.Fabric)
		end
	else
		weld(folder, torso, "Cape", V(torso.Size.X * 1.05, h * length, 0.12), C(0, -h * (length/2-0.50), z), c.cloth, Enum.Material.Fabric)
	end
	weld(folder, torso, "Agrafe", V(torso.Size.X * 1.1, 0.28, torso.Size.Z * 1.05), C(0, h / 2 - 0.1, 0), c.trim or c.cloth:Lerp(Color3.new(0, 0, 0), 0.3), Enum.Material.Fabric)
	if c.trim then
		weld(folder, torso, "Bordure", V(torso.Size.X * 1.06, 0.11, 0.14), C(0, -h * ((form=="splitcape" and 1.39 or length-0.50)-0.06), z), c.trim, Enum.Material.Fabric)
	end
end

return Avatar
