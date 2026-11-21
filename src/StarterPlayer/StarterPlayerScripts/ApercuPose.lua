local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))
local ApercuPose = {}

function ApercuPose.caseDevant(root, cell)
	local direction = root.CFrame.LookVector
	local flat = Vector3.new(direction.X, 0, direction.Z)
	flat = flat.Magnitude < 0.1 and Vector3.new(0, 0, -1) or flat.Unit
	local front = root.Position + flat * cell
	return Vector3.new(
		(math.floor(front.X / cell) + 0.5) * cell,
		root.Position.Y,
		(math.floor(front.Z / cell) + 0.5) * cell
	)
end

function ApercuPose.refus(gui, width)
	local anchor = Instance.new("Attachment")
	anchor.Name = "RefusPose"
	anchor.Parent = workspace.Terrain
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = anchor
	billboard.Enabled = false
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.25, 0)
	billboard.Size = UDim2.fromOffset(width, 62)
	billboard.Parent = gui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(67, 36, 31)
	label.BackgroundTransparency = 0.08
	label.TextColor3 = Color3.fromRGB(255, 234, 219)
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.Parent = billboard
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)
	local pad = Instance.new("UIPadding", label)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	gui.Destroying:Connect(function() anchor:Destroy() end)

	local attempt, notice
	return {
		remember = function(position)
			attempt = { position = position, time = os.clock() }
		end,
		show = function(reason)
			if not attempt or os.clock() - attempt.time > 3 then return false end
			local position = attempt.position
			attempt = nil
			local camera = workspace.CurrentCamera
			if not camera then return false end
			local _, visible = camera:WorldToViewportPoint(position + billboard.StudsOffsetWorldSpace)
			if not visible then return false end
			anchor.WorldPosition = position
			label.Text = Composants.avertissement(reason)
			billboard.Enabled = true
			local token = {}
			notice = token
			task.delay(4, function()
				if notice == token and billboard.Parent then
					billboard.Enabled = false
				end
			end)
			return true
		end,
	}
end

return ApercuPose
