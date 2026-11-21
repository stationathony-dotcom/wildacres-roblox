-- Apparence du joueur (21/11) : coiffures, parties du corps à teindre et visage, partagés entre le serveur
-- (Systemes/Avatar.applyLook) et l'interface (aperçu de la fiche personnage pendant le choix d'apparence).
local Apparence = {}

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
Apparence.HAIRS = HAIRS
Apparence.SKIN_PARTS = { "Head", "LeftHand", "RightHand" }
Apparence.SHIRT_PARTS = { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }
Apparence.PANTS_PARTS = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }
Apparence.FEET = { "LeftFoot", "RightFoot" }

-- Visage : la tête dynamique porte son visage dans sa texture ; on l'efface pour retirer le skin Roblox,
-- donc on redessine un visage en petites pièces soudées (yeux, sourcils, bouche) — visible partout, même dans
-- l'aperçu de la fiche, et dans le style en blocs du jeu. La tête R15 regarde vers -Z (avant ≈ z = -0,58).
function Apparence.visage(head, cheveux: Color3?)
	if not head or not head:IsA("BasePart") then
		return
	end
	local model = head.Parent
	if not model then
		return
	end
	local old = model:FindFirstChild("Visage_WA")
	if old then
		old:Destroy()
	end
	local v = Instance.new("Model")
	v.Name = "Visage_WA"
	v.Parent = model
	local z = -head.Size.Z / 2 - 0.02
	local oeil = Color3.fromRGB(28, 24, 22)
	for _, s in { -1, 1 } do
		weld(v, head, "Oeil", V(0.13, 0.18, 0.06), C(s * 0.2, 0.07, z), oeil)
		weld(v, head, "Reflet", V(0.05, 0.05, 0.02), C(s * 0.2 + 0.03, 0.12, z - 0.03), Color3.fromRGB(240, 236, 230))
		weld(v, head, "Sourcil", V(0.22, 0.05, 0.05), C(s * 0.2, 0.24, z) * CFrame.Angles(0, 0, s * -0.12), cheveux or Color3.fromRGB(60, 40, 28))
	end
	weld(v, head, "Bouche", V(0.28, 0.05, 0.05), C(0, -0.22, z), Color3.fromRGB(110, 46, 40))
	weld(v, head, "Bouche", V(0.06, 0.05, 0.05), C(-0.16, -0.19, z), Color3.fromRGB(110, 46, 40))
	weld(v, head, "Bouche", V(0.06, 0.05, 0.05), C(0.16, -0.19, z), Color3.fromRGB(110, 46, 40))
end

-- Teint, tunique, chausses, pieds, visage et coiffure d'un modèle R15 (personnage ou sa copie d'aperçu).
-- `couvert` = un couvre-chef cache les cheveux.
function Apparence.peindre(model, look, WG, couvert)
	local function paint(names, color)
		for _, n in names do
			local p = model:FindFirstChild(n)
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
	paint(Apparence.SKIN_PARTS, WG.SKINS[look.skin] or WG.SKINS[1])
	paint(Apparence.SHIRT_PARTS, WG.SHIRTS[look.shirt] or WG.SHIRTS[1])
	paint(Apparence.PANTS_PARTS, WG.PANTS[look.pants] or WG.PANTS[1])
	paint(Apparence.FEET, Color3.fromRGB(70, 50, 36))
	local head = model:FindFirstChild("Head")
	Apparence.visage(head, WG.HAIR_COLORS[look.hairColor] or WG.HAIR_COLORS[1])
	local old = model:FindFirstChild("Coiffure_WA")
	if old then
		old:Destroy()
	end
	if head and head:IsA("BasePart") then
		local hairModel = Instance.new("Model")
		hairModel.Name = "Coiffure_WA"
		hairModel.Parent = model
		local fn = HAIRS[look.hair]
		if fn and not couvert then
			fn(hairModel, head, WG.HAIR_COLORS[look.hairColor] or WG.HAIR_COLORS[1])
		end
	end
end

return Apparence
