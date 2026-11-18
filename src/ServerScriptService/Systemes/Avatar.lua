-- Apparence par calques (comme dans Godot) : teint, coiffure et couleur, tenue, couvre-chef.
-- Les PNJ sont habillés depuis leur « look » ; le joueur porte le chapeau de son équipement.

local Avatar = {}
local G

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
		mode = data.mode == "villageois" and "villageois" or "roblox",
		skin = idx(data.skin, #WG.SKINS),
		hair = table.find(HAIR_LIST, data.hair) and data.hair or "court",
		hairColor = idx(data.hairColor, #WG.HAIR_COLORS),
		shirt = idx(data.shirt, #WG.SHIRTS),
		pants = idx(data.pants, #WG.PANTS),
	}
end

function Avatar.setLook(player: Player, data)
	local prof = G.Joueurs.get(player)
	if not prof or type(data) ~= "table" then
		return
	end
	local look = validLook(data)
	local paidBefore = prof.look and prof.look.paid
	if paidBefore and not G.Joueurs.take(player, "gold", LOOK_COST) then
		G.Util.toast(player, "Changer d'apparence coûte " .. LOOK_COST .. " 💰 (barbier et tailleur).")
		return
	end
	look.paid = true
	prof.look = look
	G.Joueurs.markDirty(player)
	G.Util.toast(player, paidBefore and ("✂️ Nouvelle apparence (-" .. LOOK_COST .. " 💰).")
		or ("✂️ Apparence choisie. La prochaine coûtera " .. LOOK_COST .. " 💰."), "gain")
	if player.Character then
		-- le corps « villageois » retire les vêtements Roblox : on recharge pour repartir propre
		if look.mode == "roblox" then
			local root = G.Util.root(player)
			player:SetAttribute("RespawnPos", root and root.Position or nil)
			player:LoadCharacter()
		else
			Avatar.refresh(player)
		end
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
	local look = prof.look
	if not look or look.mode ~= "villageois" then
		return
	end
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
		if fn and not (hat and (hat.visual == "capuche" or hat.visual == "toque")) then
			fn(hairModel, head, WG.HAIR_COLORS[look.hairColor] or WG.HAIR_COLORS[1])
		end
	end
end

-- Armure portée : visible sur le corps (cuir, mailles, plastron, cape, tunique…)
local ARMOR_LOOKS = {
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
	if look[1] == "cape" then
		weld(m, torso, "Cape", V(ts.X * 1.05, ts.Y * 2.1, 0.12), C(0, -ts.Y * 0.5, ts.Z / 2 + 0.08), col, mat)
		weld(m, torso, "Col", V(ts.X * 1.1, 0.25, ts.Z * 1.15), C(0, ts.Y / 2, 0), col, mat)
		return
	end
	weld(m, torso, "Plastron", V(ts.X * 1.08, ts.Y * 1.02, ts.Z * 1.12), C(0, 0, 0), col, mat)
	local lower = char:FindFirstChild("LowerTorso") :: BasePart?
	if lower then
		local ls = lower.Size
		weld(m, lower, "Jupe", V(ls.X * 1.12, ls.Y * 1.3, ls.Z * 1.16), C(0, -ls.Y * 0.2, 0), col, mat)
	end
	if look[1] ~= "tunique" and look[1] ~= "robe" then
		for _, side in { "LeftUpperArm", "RightUpperArm" } do
			local arm = char:FindFirstChild(side) :: BasePart?
			if arm then
				weld(m, arm, "Epauliere", V(arm.Size.X * 1.25, arm.Size.Y * 0.45, arm.Size.Z * 1.25), C(0, arm.Size.Y * 0.28, 0), col, mat)
			end
		end
	end
	-- liseré de rareté (lisible de loin)
	local r = G.Gear.RARITIES[armor.rarity or 1]
	if r and (armor.rarity or 1) >= 2 then
		weld(m, torso, "Lisere", V(ts.X * 1.1, 0.12, ts.Z * 1.14), C(0, -ts.Y * 0.45, 0), r.color, Enum.Material.Neon)
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
	local old = char:FindFirstChild("Chapeau_WA")
	if old then
		old:Destroy()
	end
	local prof = G.Joueurs.get(player)
	local hat = prof and prof.equipped.hat
	local head = char:FindFirstChild("Head") :: BasePart?
	if hat and head and HATS[hat.visual] then
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
		HATS[hat.visual](folder, head)
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
end

return Avatar
