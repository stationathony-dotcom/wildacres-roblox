-- Apparence par calques (comme dans Godot) : teint, coiffure et couleur, tenue, couvre-chef.
-- Les PNJ sont habillés depuis leur « look ». Le joueur porte ses pièces d’équipement.

local Avatar = {}
local G
local Shared = game:GetService("ReplicatedStorage").Shared
local Design = require(Shared.GearDesign)
local Visuals = require(Shared.GearVisuals)

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
		weld(m, h, "Etoile", V(0.25, 0.25, 0.06), C(0, 1.1, -0.57), Color3.fromRGB(250, 220, 90), Enum.Material.Metal)
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
	if ctx ~= "creation" then
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
		local covered = form == "hood" or form == "cowl" or form == "toque" or form == "chapka"
			or form == "turban" or (form and form:find("helm", 1, true))
		if fn and not covered then
			fn(hairModel, head, WG.HAIR_COLORS[look.hairColor] or WG.HAIR_COLORS[1])
		end
	end
end

local function layer(char, name)
	clearFolder(char, name)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = char
	return model
end

function Avatar.applyArmor(player: Player)
	local char, prof = player.Character, G.Joueurs.get(player)
	if not char then return end
	local worn = prof and prof.equipped
	if worn and worn.armor then
		Visuals.wear(worn.armor, char, layer(char, "Armure_WA"), {covered = worn.shoulders ~= nil})
	else
		clearFolder(char, "Armure_WA")
	end
end

local visibleSlots = {"weapon", "offhand", "shoulders", "gloves", "legs", "boots", "trinket"}

function Avatar.applyExtraGear(player: Player)
	local char, prof = player.Character, G.Joueurs.get(player)
	if not char then return end
	local worn = prof and prof.equipped or {}
	local holder = layer(char, "Equipement_WA")
	for _, slot in visibleSlots do
		local item = worn[slot]
		if item then
			local itemLayer = Instance.new("Model")
			itemLayer.Name = slot
			itemLayer.Parent = holder
			Visuals.wear(item, char, itemLayer, {tallboots = worn.boots and Design.formOf(worn.boots) == "tallboots"})
		end
	end
end

-- Apparence et équipement, à l’apparition et lors d’un changement de pièce.
function Avatar.refresh(player: Player)
	local char = player.Character
	if not char then return end
	Avatar.applyLook(player)
	Avatar.applyArmor(player)
	Avatar.applyExtraGear(player)
	clearFolder(char, "Chapeau_WA")
	local prof = G.Joueurs.get(player)
	local hat = prof and prof.equipped and prof.equipped.hat
	if hat and char:FindFirstChild("Head") then
		Visuals.wear(hat, char, layer(char, "Chapeau_WA"))
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
	if not char then return end
	clearFolder(char, "Cape_WA")
	local prof = G.Joueurs.get(player)
	local cape = prof and prof.equipped and prof.equipped.cape
	if cape then
		Visuals.wear(cape, char, layer(char, "Cape_WA"))
		return
	end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	local rank = prof and prof.stats and prof.stats.noblesse or 0
	local colors = CAPES[math.clamp(rank, 0, #CAPES)]
	if not torso or not colors then return end

	local folder = layer(char, "Cape_WA")
	local w, h, z = torso.Size.X, torso.Size.Y, torso.Size.Z
	local trim = colors.trim or colors.cloth:Lerp(Color3.new(0, 0, 0), 0.3)
	weld(folder, torso, "Cape", V(w * 1.05, h * 2.15, 0.12), C(0, -h * 0.575, z / 2 + 0.13), colors.cloth, Enum.Material.Fabric)
	weld(folder, torso, "Agrafe", V(w * 1.1, 0.28, z * 1.05), C(0, h / 2 - 0.1, 0), trim, Enum.Material.Fabric)
	if colors.trim then
		weld(folder, torso, "Bordure", V(w * 1.06, 0.11, 0.14), C(0, -h * 1.59, z / 2 + 0.13), trim, Enum.Material.Fabric)
	end
end

return Avatar
