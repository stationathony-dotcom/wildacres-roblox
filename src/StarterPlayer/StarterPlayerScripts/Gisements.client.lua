-- Reflets des gisements (façon WoW) : un scintillement discret sur les filons (tag « Filon ») et
-- les plantes sauvages (tag « Herbe ») que TA compétence permet de récolter (attributs Comp_minage /
-- Comp_agriculture posés par le serveur, MinSkill sur le modèle). Purement local et visuel.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

if workspace:GetAttribute("Mode") == "accueil" then
	return
end

local player = Players.LocalPlayer
local SKILL = { Filon = "Comp_minage", Herbe = "Comp_agriculture" }
local COLOR = { Filon = Color3.fromRGB(255, 236, 170), Herbe = Color3.fromRGB(200, 255, 170) }
local RANGE = 90 -- studs

local function sparkle(model: Model, tag: string, on: boolean)
	local pp = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not pp then
		return
	end
	local e = pp:FindFirstChild("Reflet")
	if on and not e then
		local p = Instance.new("ParticleEmitter")
		p.Name = "Reflet"
		p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		p.Color = ColorSequence.new(COLOR[tag])
		p.LightEmission = 1
		p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 0) })
		p.Transparency = NumberSequence.new(0.2)
		p.Lifetime = NumberRange.new(0.8, 1.4)
		p.Rate = tag == "Filon" and 3 or 2
		p.Speed = NumberRange.new(0.3, 0.8)
		p.SpreadAngle = Vector2.new(180, 180)
		p.Parent = pp
	elseif not on and e then
		e:Destroy()
	end
end

while true do
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	for tag, attr in SKILL do
		local lvl = player:GetAttribute(attr) or 0
		for _, m in CollectionService:GetTagged(tag) do
			if m:IsA("Model") and m.Parent then
				local near = root and (m:GetPivot().Position - root.Position).Magnitude < RANGE
				sparkle(m, tag, near and lvl >= (m:GetAttribute("MinSkill") or 0) or false)
			end
		end
	end
	task.wait(2)
end
