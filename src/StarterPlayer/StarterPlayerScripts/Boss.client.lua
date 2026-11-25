-- Mise en scène des boss côté client (chantier C, 25/11) — aucun texte :
--   Fx "boss" (modèle, position) : entrée en scène la première fois qu'on le croise — la caméra se tourne
--     vers lui 1,8 s (de trois quarts, à hauteur de sa tête), rugissement grave, secousse ; puis la caméra
--     revient au joueur. Le serveur fige le boss pendant ce temps (état « roar »).
--   Fx "secousse" (position, force) : tremblement de caméra qui faiblit avec la distance.
-- Écrit par Claude (couloir Codex : script client neuf, à reprendre librement — voir docs/LOTS.md).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local Fx = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Fx")

local ROAR_ID = "rbxassetid://9125471073" -- même son que le grognement des créatures, ralenti et grave
local busy = false

local function roar(volume: number)
	local s = Instance.new("Sound")
	s.SoundId = ROAR_ID
	s.Volume = volume
	s.PlaybackSpeed = 0.55
	s.Parent = SoundService
	s:Play()
	task.delay(3, function()
		s:Destroy()
	end)
	local s2 = s:Clone()
	s2.PlaybackSpeed = 0.42
	s2.Volume = volume * 0.7
	s2.Parent = SoundService
	s2:Play()
	task.delay(3, function()
		s2:Destroy()
	end)
end

-- tremblement : décalage de caméra (Humanoid.CameraOffset), qui retombe à zéro
local shaking = 0
local function shake(force: number, dur: number)
	shaking = math.max(shaking, force)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > dur or not hum.Parent then
			hum.CameraOffset = Vector3.zero
			shaking = 0
			conn:Disconnect()
			return
		end
		local k = shaking * (1 - t / dur)
		hum.CameraOffset = Vector3.new(math.noise(t * 25, 1) * k, math.noise(t * 25, 2) * k, math.noise(t * 25, 3) * k * 0.5)
	end)
end

local function intro(model: Model?, pos: Vector3?)
	if busy or not model or not model.Parent then
		return
	end
	local cam = workspace.CurrentCamera
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (cam and root) then
		return
	end
	busy = true
	local cf, size = model:GetBoundingBox()
	-- ne pas compter la colonne de lumière dans la hauteur du boss
	local lueur = model:FindFirstChild("Lueur")
	local h = size.Y
	if lueur then
		h = math.min(h, (model.PrimaryPart and lueur.Position.Y - model.PrimaryPart.Position.Y - 88) or h)
	end
	local base = model.PrimaryPart and model.PrimaryPart.Position or cf.Position
	local focus = base + Vector3.new(0, h * 0.62, 0)
	-- de trois quarts, entre le joueur et le boss, un peu en contrebas : il paraît plus grand
	local flat = Vector3.new(root.Position.X - base.X, 0, root.Position.Z - base.Z)
	local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, 1)
	local side = Vector3.new(-dir.Z, 0, dir.X)
	-- (assez haut pour passer au-dessus des hautes herbes et des murets, un peu sous la tête du boss)
	local dist = math.max(16, math.min(math.max(size.X, size.Z), 40) * 1.1, h * 1.3)
	local eye = base + dir * dist + side * dist * 0.6 + Vector3.new(0, math.max(7, h * 0.5), 0)
	local oldType = cam.CameraType
	local oldCF = cam.CFrame
	cam.CameraType = Enum.CameraType.Scriptable
	local tw = TweenService:Create(cam, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.lookAt(eye, focus) })
	tw:Play()
	task.delay(0.35, function()
		roar(1.3)
		shake(0.9, 1.2)
	end)
	-- léger travelling vers le boss pendant le rugissement
	task.delay(0.45, function()
		if cam.CameraType == Enum.CameraType.Scriptable then
			TweenService:Create(cam, TweenInfo.new(1.3, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(eye:Lerp(focus, 0.12), focus) }):Play()
		end
	end)
	task.delay(1.8, function()
		local back = TweenService:Create(cam, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { CFrame = oldCF })
		back:Play()
		back.Completed:Wait()
		cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
		busy = false
	end)
end

Fx.OnClientEvent:Connect(function(kind, a, b)
	if kind == "boss" then
		intro(a, b)
	elseif kind == "secousse" then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and typeof(a) == "Vector3" then
			local d = (root.Position - a).Magnitude
			local force = (tonumber(b) or 0.5) * math.clamp(1 - d / 70, 0, 1)
			if force > 0.05 then
				shake(force, 0.6)
			end
		end
	end
end)
