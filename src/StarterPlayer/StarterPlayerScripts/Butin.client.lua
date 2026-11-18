-- Butin au sol, côté joueur (le serveur décide de tout : Systemes/Butin) :
--   · les objets tombés tournent et flottent doucement (animation locale, zéro réseau) ;
--   · clic gauche / toucher un objet = le ramasser ; [E] sur l'invite marche aussi ;
--   · [Q] (manette : Y) = ramasser tout ce qui est autour.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if workspace:GetAttribute("Mode") == "accueil" then
	return
end

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")

local ANIM_RANGE = 90
local CLICK_RANGE = 14

-- ---------------------------------------------------------------- animation
local items = {} -- part -> phase
local function track(part: Instance)
	if part:IsA("BasePart") then
		items[part] = math.random() * math.pi * 2
	end
end
for _, p in CollectionService:GetTagged("Butin") do
	track(p)
end
CollectionService:GetInstanceAddedSignal("Butin"):Connect(track)
CollectionService:GetInstanceRemovedSignal("Butin"):Connect(function(p)
	items[p] = nil
end)

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local camPos = cam.CFrame.Position
	local t = os.clock()
	for part, phase in items do
		if not part.Parent then
			items[part] = nil
			continue
		end
		local base = part:GetAttribute("Base")
		if typeof(base) == "Vector3" and (base - camPos).Magnitude < ANIM_RANGE then
			part.CFrame = CFrame.new(base + Vector3.new(0, 0.25 + math.sin(t * 2.2 + phase) * 0.22, 0)) * CFrame.Angles(0.35, t * 1.6 + phase, 0)
		end
	end
end)

-- ---------------------------------------------------------------- ramasser
local function butinUnder(screenPos: Vector2): BasePart?
	local cam = workspace.CurrentCamera
	local folder = workspace:FindFirstChild("ButinAuSol")
	if not cam or not folder then
		return nil
	end
	local ray = cam:ViewportPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 200, params)
	if not hit then
		-- petite tolérance : l'objet le plus proche du rayon (les cubes sont petits)
		local best, bestD = nil, 1.6
		for part in items do
			if part.Parent then
				local v = part.Position - ray.Origin
				local along = v:Dot(ray.Direction)
				if along > 0 then
					local d = (v - ray.Direction * along).Magnitude
					if d < bestD then
						best, bestD = part, d
					end
				end
			end
		end
		return best
	end
	return hit.Instance
end

local function tryPick(screenPos: Vector2): boolean
	local part = butinUnder(screenPos)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not part or not root or (part.Position - root.Position).Magnitude > CLICK_RANGE then
		return false
	end
	local id = part:GetAttribute("ButinId")
	if id then
		Action:FireServer("ramasser", { id = id })
		return true
	end
	return false
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryPick(UserInputService:GetMouseLocation())
	elseif input.UserInputType == Enum.UserInputType.Touch then
		tryPick(Vector2.new(input.Position.X, input.Position.Y))
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonY then
		Action:FireServer("ramasser_tout", {})
	end
end)
