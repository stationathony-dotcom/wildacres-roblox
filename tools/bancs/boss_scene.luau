-- Banc de la mise en scène des boss (chantier C, 25/11) — mode Edit.
-- C3 chaque attaque d'un boss est marquée au sol au moins 0,8 s avant de frapper (préparation et onde de choc)
-- C3b la marque est posée sur le sol (rayon terrain) et couvre la zone frappée : cercle de tir ≥ 6, bande de
--     charge ≥ trajet + rayon, onde de choc = SHOCK_RADIUS
-- C4 2e phase visible : toutes les lueurs virent au rouge
-- C1 la colonne de lumière est soudée à la base, ne touche rien, et dépasse de 80 studs au moins
local E = require(game.ServerScriptService.Systemes.Enemies:Clone())
local B = require(game.ServerScriptService.Systemes:Clone().Bestiaire)
local fails = {}
if (E.BOSS_WINDUP or 0) < 0.8 then
	table.insert(fails, "C3 préparation trop courte : " .. tostring(E.BOSS_WINDUP))
end
if (E.SHOCK_WINDUP or 0) < 0.8 then
	table.insert(fails, "C3 onde de choc annoncée trop tard : " .. tostring(E.SHOCK_WINDUP))
end

-- sol d'essai
local ground = Instance.new("Part")
ground.Anchored = true
ground.Size = Vector3.new(200, 2, 200)
ground.Position = Vector3.new(5000, 99, 5000)
ground.Parent = workspace
-- feetY lit le terrain : sans terrain ici, il retombe sous la cible (at.Y - 2,9) → marque à y = 100,12
local function marks()
	local out = {}
	for _, c in workspace:GetChildren() do
		if c.Name == "MarqueBoss" then
			table.insert(out, c)
		end
	end
	return out
end
local function clear()
	for _, c in marks() do
		c:Destroy()
	end
end

local fake = {
	k = { style = "spore", speed = 9 }, phase = 1, radius = 3.4,
	pos = Vector3.new(5000, 102.9, 5000), target = Vector3.new(5010, 102.9, 5000),
}
E.telegraph(fake)
local m = marks()
if #m ~= 1 then
	table.insert(fails, "C3b tir : " .. #m .. " marque(s) au lieu de 1")
elseif m[1].Size.Y < 12 or math.abs(m[1].Position.Y - 100.12) > 0.3 then
	table.insert(fails, string.format("C3b tir : cercle %.1f à y=%.2f", m[1].Size.Y, m[1].Position.Y))
end
clear()
fake.phase = 2
E.telegraph(fake)
if #marks() ~= 2 or not fake.target2 then
	table.insert(fails, "C3b tir double de 2e phase : " .. #marks() .. " marque(s), cible 2 = " .. tostring(fake.target2))
end
clear()
fake.k = { style = "charge", speed = 16 }
fake.phase = 1
fake.target = Vector3.new(5020, 102.9, 5000)
E.telegraph(fake)
m = marks()
local trip = math.min(20, 16 * 3.2 * 0.5) + fake.radius
if #m ~= 1 or m[1].Size.Z < trip - 0.01 then
	table.insert(fails, string.format("C3b charge : bande %.1f < trajet %.1f", m[1] and m[1].Size.Z or -1, trip))
end
clear()

-- 2e phase : lueurs rouges
local model = B.build("Bete_vargor")
model.Parent = workspace
model:PivotTo(CFrame.new(5000, 100, 5000))
local en = { model = model, height = 13, k = {}, pos = Vector3.new(5000, 100, 5000) }
E.beacon(en)
local beam = model:FindFirstChild("Lueur")
if not beam then
	table.insert(fails, "C1 pas de colonne de lumière")
else
	local w = beam:FindFirstChildOfClass("WeldConstraint")
	if not (w and w.Part0 == model.PrimaryPart) or beam.CanCollide or beam.CanQuery or beam.Anchored then
		table.insert(fails, "C1 colonne mal fixée ou solide")
	end
	if beam.Position.Y + beam.Size.X / 2 - model.PrimaryPart.Position.Y < 80 then
		table.insert(fails, "C1 colonne trop basse")
	end
end
E.enrage(en)
for _, p in model:GetDescendants() do
	if p:IsA("BasePart") and p.Material == Enum.Material.Neon and p.Color:ToHex() ~= Color3.fromRGB(255, 56, 36):ToHex() then
		table.insert(fails, "C4 lueur pas rouge : " .. p.Name)
		break
	end
end
model:Destroy()
ground:Destroy()
if #fails == 0 then
	return "boss_scene OK : marques ≥ 0,8 s, tir / tir double / charge marqués, colonne, 2e phase rouge"
end
return "ÉCHEC boss_scene : " .. #fails .. " problème(s)\n" .. table.concat(fails, "\n")
