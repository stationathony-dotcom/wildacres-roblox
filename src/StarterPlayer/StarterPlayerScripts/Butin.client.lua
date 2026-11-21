-- Butin au sol, côté joueur (le serveur décide de tout : Systemes/Butin) :
--   · les objets tombés tournent et flottent doucement (animation locale, zéro réseau) ;
--   · le clic et le toucher passent par Interface.client ; [E] sur l'invite marche aussi ;
--   · [Q] (manette : Y) = ramasser tout ce qui est autour.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if workspace:GetAttribute("Mode") == "accueil" then
	return
end

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local WindowNav = require(script.Parent:WaitForChild("WindowNav"))

local secondaryPrompts = setmetatable({}, { __mode = "k" })
ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.GamepadKeyCode == Enum.KeyCode.ButtonY then secondaryPrompts[prompt] = true end
end)
ProximityPromptService.PromptHidden:Connect(function(prompt)
	secondaryPrompts[prompt] = nil
end)

local ANIM_RANGE = 90

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
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or WindowNav.isOpen() then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonY then
		if input.KeyCode == Enum.KeyCode.ButtonY then
			for prompt in secondaryPrompts do
				if prompt.Parent and prompt.Enabled then return end
			end
		end
		Action:FireServer("ramasser_tout", {})
	end
end)
