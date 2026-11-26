-- Contours façon planche (lot X29, 26/11) : un trait sombre autour des boss proches, des élites proches et
-- de la créature sous le curseur, comme sur les planches de référence (images/references-26-11/).
-- Roblox n'affiche que 31 Highlight à la fois : on en garde au plus MAX, les plus proches d'abord.
-- Seulement des contours (FillTransparency = 1), rien côté serveur (attributs Boss / Elite posés par Enemies).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local MAX = 16
local BOSS_RANGE, ELITE_RANGE = 140, 60
local SOMBRE = Color3.fromRGB(26, 18, 14)
local VISEE = Color3.fromRGB(255, 214, 120)

local actifs: { [Model]: Highlight } = {}

local function poser(model: Model, couleur: Color3, epais: boolean)
	local h = actifs[model]
	if not h then
		h = Instance.new("Highlight")
		h.Name = "Contour"
		h.FillTransparency = 1
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Adornee = model
		h.Parent = model
		actifs[model] = h
	end
	h.OutlineColor = couleur
	h.OutlineTransparency = epais and 0 or 0.25
end

local function viseeModel(): Model?
	local t = mouse.Target
	while t and t ~= workspace do
		if t:IsA("Model") and t:GetAttribute("EnemyId") then
			return t
		end
		t = t.Parent
	end
	return nil
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then
		return
	end
	acc = 0
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local voulus = {}
	if root then
		local liste = {}
		for _, m in CollectionService:GetTagged("Bete") do
			if m:IsA("Model") and m.Parent and (m:GetAttribute("Boss") or m:GetAttribute("Elite")) then
				local ok, piv = pcall(m.GetPivot, m)
				if ok then
					local d = (piv.Position - root.Position).Magnitude
					if d < (m:GetAttribute("Boss") and BOSS_RANGE or ELITE_RANGE) then
						table.insert(liste, { m = m, d = d })
					end
				end
			end
		end
		table.sort(liste, function(a, b)
			return a.d < b.d
		end)
		for i = 1, math.min(#liste, MAX - 1) do
			voulus[liste[i].m] = SOMBRE
		end
	end
	local v = viseeModel()
	if v then
		voulus[v] = VISEE
	end
	for m, h in actifs do
		if not voulus[m] or not m.Parent then
			h:Destroy()
			actifs[m] = nil
		end
	end
	for m, c in voulus do
		poser(m, c, c == VISEE)
	end
end)
