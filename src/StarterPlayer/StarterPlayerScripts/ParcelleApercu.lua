local Composants = require(script.Parent:WaitForChild("ComposantsInterface"))

local ParcelleApercu = {}
local NEUTRE = Color3.fromRGB(220, 190, 117)
local ACCEPTE = Color3.fromRGB(125, 225, 112)
local REFUSE = Color3.fromRGB(244, 99, 82)
local SEGMENTS = 6
local INTERVALLE = 0.14

local function memeCase(a, b)
	return a and b and a.X == b.X and a.Z == b.Z
end

function ParcelleApercu.new(gui, remotes, cell)
	local contour = Instance.new("Folder")
	contour.Name = "ApercuParcelle"
	local segments = {}
	local terrain = RaycastParams.new()
	terrain.FilterType = Enum.RaycastFilterType.Include
	terrain.FilterDescendantsInstances = { workspace.Terrain }
	local label = Composants.creer("TextLabel", {
		Name = "PrixParcelle", Text = "", Visible = false,
		Size = UDim2.fromOffset(310, 32), AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0.68, 0), AnchorPoint = Vector2.new(0.5, 0),
		TextColor3 = NEUTRE, TextSize = 15, TextWrapped = true, Font = Enum.Font.GothamBold,
		BackgroundColor3 = Color3.fromRGB(44, 33, 25), BackgroundTransparency = 0.08,
		BorderSizePixel = 0, Parent = gui, ZIndex = 12,
	}, { Composants.creer("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Composants.creer("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
			PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
	gui.Destroying:Connect(function() contour:Destroy() end)

	local function sol(position)
		local origin = position + Vector3.new(0, 96, 0)
		local hit = workspace:Raycast(origin, Vector3.new(0, -224, 0), terrain)
		local y = hit and hit.Position.Y or (position.Y - 2.5)
		return Vector3.new(position.X, y + 0.22, position.Z)
	end

	local function recolorer(couleur)
		for _, part in segments do part.Color = couleur end
		label.TextColor3 = couleur
	end

	local function tracer(centre, half)
		local coins = {
			Vector3.new(-half, 0, -half), Vector3.new(half, 0, -half),
			Vector3.new(half, 0, half), Vector3.new(-half, 0, half),
		}
		for cote, coin in coins do
			local debut = centre + coin
			local fin = centre + coins[cote % #coins + 1]
			local avant = sol(debut)
			for i = 1, SEGMENTS do
				local apres = sol(debut:Lerp(fin, i / SEGMENTS))
				local index = (cote - 1) * SEGMENTS + i
				local part = segments[index]
				if not part then
					part = Instance.new("Part")
					part.Name = "Contour"
					part.Anchored, part.CastShadow = true, false
					part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
					part.Material = Enum.Material.Neon
					part.Parent = contour
					segments[index] = part
				end
				part.Size = Vector3.new(0.19, 0.19, (apres - avant).Magnitude + 0.2)
				part.CFrame = CFrame.lookAt((avant + apres) / 2, apres)
				avant = apres
			end
		end
	end

	local cible, demandee
	local half = cell * 6
	local enCours = false
	local prochainAppel = 0
	return function(position)
		if not position then
			if cible then
				cible, demandee = nil, nil
				contour.Parent = nil
				label.Visible = false
			end
			return
		end
		if not memeCase(position, cible) then
			cible, demandee = position, nil
			tracer(cible, half)
			recolorer(NEUTRE)
			label.Text = "Vérification du terrain…"
			label.Visible = true
			contour.Parent = workspace
		end
		local maintenant = os.clock()
		if enCours or memeCase(demandee, cible) or maintenant < prochainAppel then return end
		local point = cible
		demandee, enCours = point, true
		prochainAppel = maintenant + INTERVALLE
		task.spawn(function()
			local infos = remotes:FindFirstChild("Infos") or remotes:WaitForChild("Infos", 2)
			local success, result
			if infos then
				success, result = pcall(infos.InvokeServer, infos, "parcelle", { x = point.X, z = point.Z })
			end
			enCours = false
			if not memeCase(point, cible) then return end
			demandee = point
			if not success or type(result) ~= "table" or type(result.ok) ~= "boolean" or type(result.prix) ~= "number" then
				label.Text = "Conditions de pose indisponibles"
				return
			end
			if type(result.half) == "number" and result.half > 0 and result.half ~= half then
				half = result.half
				tracer(cible, half)
			end
			local prix = result.prix == 0 and "gratuit" or tostring(result.prix) .. " or"
			local texte = string.format("Terrain %d · %s", (result.n or 0) + 1, prix)
			if not result.ok then
				texte ..= "\n" .. Composants.avertissement(result.motif or "Pose refusée ici")
			end
			label.Text = texte
			recolorer(result.ok and ACCEPTE or REFUSE)
		end)
	end
end

return ParcelleApercu
