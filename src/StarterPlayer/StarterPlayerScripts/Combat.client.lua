-- Garde et esquive (26/11, Shared/Armes ; serveur : Systemes/Combat).
--   [Z] maintenu / L2 / bouton 🛡 (mobile) : garde — bouclier porté = presque tout bloqué, sinon on pare avec l'arme ;
--   lever la garde au dernier moment = PARADE (riposte). Le serveur décide du coût et des bris de garde.
--   [Alt] / L1 / bouton 💨 : esquive — roulade dans la direction du déplacement (en arrière à l'arrêt).
-- En mode construction, Z / L1 restent à la construction (attribut ModeBatir posé par Interface).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Armes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Armes"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local function send(kind: string, data)
	Remotes.Action:FireServer(kind, data or {})
end

local function busy(): boolean
	if player:GetAttribute("ModeBatir") then
		return true
	end
	local ok, WindowNav = pcall(function()
		return require(script.Parent:WaitForChild("WindowNav", 2))
	end)
	return ok and WindowNav and WindowNav.isOpen and WindowNav.isOpen() or false
end

local guarding = false
local function setGuard(on: boolean)
	if on == guarding then
		return
	end
	guarding = on
	send("garde", { on = on })
end

local lastDodge = 0
local function dodge()
	if busy() or player:GetAttribute("Riding") then
		return
	end
	local now = os.clock()
	if now - lastDodge < Armes.ESQUIVE_CD or (player:GetAttribute("Stamina") or 0) < Armes.ESQUIVE_COUT then
		return
	end
	lastDodge = now
	send("esquive")
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if root and hum then
		local dir = hum.MoveDirection.Magnitude > 0.1 and hum.MoveDirection.Unit or -root.CFrame.LookVector * Vector3.new(1, 0, 1)
		if dir.Magnitude > 0.1 then
			root.AssemblyLinearVelocity = dir.Unit * 48 + Vector3.new(0, 8, 0)
		end
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.ButtonL2 then
		if not busy() then
			setGuard(true)
		end
	elseif input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.ButtonL1 then
		dodge()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.ButtonL2 then
		setGuard(false)
	end
end)
player.CharacterAdded:Connect(function()
	guarding = false
end)

-- mobile : deux boutons ronds au-dessus des autres
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	local gui = Instance.new("ScreenGui")
	gui.Name = "CombatMobile"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local function button(text: string, pos: UDim2)
		local b = Instance.new("TextButton")
		b.Text = text
		b.TextSize = 26
		b.Font = Enum.Font.GothamBold
		b.Size = UDim2.fromOffset(56, 56)
		b.Position = pos
		b.BackgroundColor3 = Color3.fromRGB(30, 34, 42)
		b.BackgroundTransparency = 0.25
		b.TextColor3 = Color3.new(1, 1, 1)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = b
		b.Parent = gui
		return b
	end
	local g = button("🛡", UDim2.new(1, -215, 1, -190))
	g.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			setGuard(true)
		end
	end)
	g.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			setGuard(false)
		end
	end)
	button("💨", UDim2.new(1, -215, 1, -255)).Activated:Connect(dodge)
end
