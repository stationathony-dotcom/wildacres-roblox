-- Pilotage des montures volantes (lot C18, 26/11 ; serveur : Systemes/Envol).
-- Le joueur possède physiquement son personnage : on le pilote ici avec un LinearVelocity et un
-- AlignOrientation tant que l'attribut « Flying » est vrai.
--   Avancer : touches de déplacement (ou joystick), dans la direction de la caméra (on monte en
--   regardant vers le haut, comme dans WoW).  Monter : Espace / bouton A.  Descendre : Ctrl gauche / bouton B.
--   À bout de souffle (« Exhausted ») : la bête plane doucement vers le sol.
--   [X] : descendre de selle (Interface.client envoie « dismount » tant que « Riding » est vrai).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local vertical = 0 -- -1, 0, 1
local up, down = false, false
local lv: LinearVelocity?, ao: AlignOrientation?, att: Attachment?
local conn: RBXScriptConnection?
local vel = Vector3.zero

local function setVertical()
	vertical = (up and 1 or 0) - (down and 1 or 0)
end

local function bindKeys()
	ContextActionService:BindAction("EnvolMonter", function(_, state)
		up = state == Enum.UserInputState.Begin
		setVertical()
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	ContextActionService:BindAction("EnvolDescendre", function(_, state)
		down = state == Enum.UserInputState.Begin
		setVertical()
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle("EnvolMonter", "▲")
	ContextActionService:SetTitle("EnvolDescendre", "▼")
	ContextActionService:SetPosition("EnvolMonter", UDim2.new(1, -95, 1, -250))
	ContextActionService:SetPosition("EnvolDescendre", UDim2.new(1, -95, 1, -180))
end

local function stop()
	if conn then
		conn:Disconnect()
		conn = nil
	end
	ContextActionService:UnbindAction("EnvolMonter")
	ContextActionService:UnbindAction("EnvolDescendre")
	up, down, vertical = false, false, 0
	for _, x in { lv, ao, att } do
		if x then
			x:Destroy()
		end
	end
	lv, ao, att = nil, nil, nil
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function start()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum) then
		return
	end
	stop()
	hum.PlatformStand = true
	att = Instance.new("Attachment")
	att.Name = "EnvolAttache"
	att.Parent = root
	lv = Instance.new("LinearVelocity")
	lv.Name = "EnvolVitesse"
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = 1e7
	lv.VectorVelocity = Vector3.zero
	lv.Parent = root
	ao = Instance.new("AlignOrientation")
	ao.Name = "EnvolCap"
	ao.Attachment0 = att
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.MaxTorque = 1e7
	ao.Responsiveness = 14
	ao.CFrame = root.CFrame - root.Position
	ao.Parent = root
	vel = Vector3.zero
	bindKeys()

	conn = RunService.RenderStepped:Connect(function(dt)
		if not (lv and ao and root.Parent) then
			return
		end
		local speed = player:GetAttribute("FlySpeed") or 50
		local climb = player:GetAttribute("FlyClimb") or 22
		local exhausted = player:GetAttribute("Exhausted") == true
		local move = hum.MoveDirection -- déjà relatif à la caméra (à plat)
		local camLook = camera.CFrame.LookVector
		local target = Vector3.zero
		if move.Magnitude > 0.05 then
			-- on vole vers où l'on regarde : la pente de la caméra donne la montée
			local flat = Vector3.new(camLook.X, 0, camLook.Z)
			local pitch = flat.Magnitude > 1e-3 and math.clamp(camLook.Y, -0.7, 0.7) or 0
			local forwardAmount = flat.Magnitude > 1e-3 and move:Dot(flat.Unit) or 0
			target = move * speed + Vector3.new(0, pitch * speed * math.max(forwardAmount, 0), 0)
		end
		target += Vector3.new(0, vertical * climb, 0)
		if exhausted then
			target = Vector3.new(target.X * 0.45, -10, target.Z * 0.45) -- elle plane vers le sol
		end
		vel = vel:Lerp(target, math.clamp(dt * 3, 0, 1)) -- inertie : on ne tourne pas sur place
		lv.VectorVelocity = vel
		local flatVel = Vector3.new(vel.X, 0, vel.Z)
		local face = flatVel.Magnitude > 2 and flatVel.Unit or Vector3.new(camLook.X, 0, camLook.Z)
		if face.Magnitude > 1e-3 then
			local tilt = math.clamp(vel.Y / math.max(speed, 1), -0.5, 0.5) * 0.6
			ao.CFrame = CFrame.lookAt(Vector3.zero, face.Unit) * CFrame.Angles(tilt, 0, 0)
		end
	end)
end

local function refresh()
	if player:GetAttribute("Flying") then
		start()
	else
		stop()
	end
end

player:GetAttributeChangedSignal("Flying"):Connect(refresh)
player.CharacterAdded:Connect(function()
	stop()
end)
refresh()
