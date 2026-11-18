-- Empreintes (18/11, AUDIT « empreintes / terriers / cris ») : les bêtes et créatures (tag « Bete »)
-- laissent des traces sur les sols meubles — neige, sable, boue, terre, tapis de feuilles — qui
-- s'effacent en ~25 s. De quoi pister le gibier. Purement local et visuel (zéro réseau).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

if workspace:GetAttribute("Mode") == "accueil" then
	return
end

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "Empreintes"
folder.Parent = workspace

local SOFT = {
	[Enum.Material.Snow] = Color3.fromRGB(170, 180, 196),
	[Enum.Material.Sand] = Color3.fromRGB(176, 150, 100),
	[Enum.Material.Sandstone] = Color3.fromRGB(160, 110, 74),
	[Enum.Material.Mud] = Color3.fromRGB(60, 48, 32),
	[Enum.Material.Ground] = Color3.fromRGB(96, 70, 46),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(120, 76, 40),
}
local RANGE = 70
local STEP = 2.2 -- studs entre deux traces
local MAX_PRINTS = 160
local last = setmetatable({}, { __mode = "k" }) -- modèle -> { pos, side }
local prints = {}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include

local function drop(pos: Vector3, yaw: number, side: number, size: number)
	local terrain = workspace.Terrain
	params.FilterDescendantsInstances = { terrain }
	local hit = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -8, 0), params)
	if not hit then
		return
	end
	local color = SOFT[hit.Material]
	if not color then
		return
	end
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size = Vector3.new(0.45 * size, 0.04, 0.6 * size)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = 0.25
	local right = Vector3.new(math.cos(yaw), 0, -math.sin(yaw))
	p.CFrame = CFrame.new(hit.Position + right * side * 0.35 * size + Vector3.new(0, 0.02, 0)) * CFrame.Angles(0, yaw, 0)
	p.Parent = folder
	table.insert(prints, p)
	if #prints > MAX_PRINTS then
		table.remove(prints, 1):Destroy()
	end
	TweenService:Create(p, TweenInfo.new(25, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()
	task.delay(25.5, function()
		local i = table.find(prints, p)
		if i then
			table.remove(prints, i)
		end
		p:Destroy()
	end)
end

while true do
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		for _, m in CollectionService:GetTagged("Bete") do
			if m:IsA("Model") and m.Parent then
				local pos = m:GetPivot().Position
				if (pos - root.Position).Magnitude < RANGE then
					local l = last[m]
					if not l then
						last[m] = { pos = pos, side = 1 }
					elseif (pos - l.pos).Magnitude >= STEP then
						local dir = (pos - l.pos) * Vector3.new(1, 0, 1)
						if dir.Magnitude > 0.01 and (pos - l.pos).Magnitude < 30 then
							local yaw = math.atan2(-dir.X, -dir.Z)
							local _, size = m:GetBoundingBox()
							drop(pos, yaw, l.side, math.clamp(size.Magnitude / 6, 0.6, 2.2))
						end
						l.pos, l.side = pos, -l.side
					end
				end
			end
		end
	end
	task.wait(0.3)
end
