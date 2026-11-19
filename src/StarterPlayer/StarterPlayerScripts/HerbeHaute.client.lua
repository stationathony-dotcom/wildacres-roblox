-- Herbe haute (19/11, image cible : prairies en herbe drue) : touffes de brins dessinées LOCALEMENT
-- autour du joueur (zéro réseau, zéro coût serveur) aux places tirées par Shared.HerbeHaute, sur le
-- sol qui leur convient (herbe en prairie, roseaux au marais, oyats sur le sable). Elles se fauchent
-- au clic comme le blé (attribut RecolteId → « recolter_clic », validé par Systemes/Fauche) ; une
-- case fauchée par n'importe qui est publiée dans ReplicatedStorage.Fauche et disparaît pour tous,
-- jusqu'à la repousse du lendemain. Rayon réglé par la qualité graphique de Roblox.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if workspace:GetAttribute("Mode") == "accueil" then
	return
end

local player = Players.LocalPlayer
local HH = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HerbeHaute"))
local cutFolder = ReplicatedStorage:WaitForChild("Fauche", 30)

local folder = Instance.new("Folder")
folder.Name = "HerbeHauteLocale"
folder.Parent = workspace

local CELL = HH.CELL
local BLADES = 4
local RAYS_PER_TICK = 90

local function radius(): number
	local ok, q = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	if not ok or not q or q == 0 then
		return 50
	end
	return math.clamp(26 + q * 4, 30, 64)
end

local active = {} -- clé de case -> { parts }
local probe = {} -- clé de case -> { sorte ou false, valable jusqu'à (os.clock) }
local pool = {}
local lastScan, settled = nil, false -- balayage sauté tant qu'on ne bouge pas et que tout est sondé

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = false

local function isCut(cx: number, cz: number): boolean
	return cutFolder ~= nil and cutFolder:GetAttribute(HH.attr(cx, cz)) ~= nil
end

local function blade(): WedgePart
	local p = table.remove(pool)
	if p then
		return p
	end
	p = Instance.new("WedgePart")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true -- le clic de récolte doit la toucher
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function spawnClump(key: string, cx: number, cz: number, info, sorte, groundPos: Vector3)
	local parts = {}
	local id = HH.id(cx, cz)
	local base = CFrame.new(info.x, groundPos.Y - 0.15, info.z) * CFrame.Angles(0, math.rad(info.yaw), 0)
	local n = #sorte.couleurs
	for i = 1, BLADES do
		local f = (i * 0.37 + info.v) % 1
		local h = sorte.h[1] + (sorte.h[2] - sorte.h[1]) * ((info.t + i * 0.23) % 1)
		if i == BLADES then
			h *= 0.7
		end
		local p = blade()
		p.Size = Vector3.new(0.12, h, sorte.larg + f * 0.25)
		p.Color = sorte.couleurs[1 + math.floor(((info.v * 7 + i) % n))]
		local tilt = math.rad(8 + f * 14)
		p.CFrame = base * CFrame.Angles(0, math.rad(i * (180 / BLADES)), 0) * CFrame.new(0, 0, (f - 0.5) * 0.5)
			* CFrame.Angles(tilt * (i % 2 == 0 and 1 or -1), 0, 0) * CFrame.new(0, h / 2, 0)
		p:SetAttribute("RecolteId", id)
		p.Parent = folder
		parts[i] = p
	end
	active[key] = parts
end

local function release(key: string)
	local parts = active[key]
	if not parts then
		return
	end
	active[key] = nil
	for _, p in parts do
		p.Parent = nil
		if #pool < 600 then
			table.insert(pool, p)
		else
			p:Destroy()
		end
	end
end

-- une case fauchée (par n'importe qui) disparaît tout de suite ; repoussée, elle revient au tick suivant
if cutFolder then
	cutFolder.AttributeChanged:Connect(function(name: string)
		local a, b = string.match(name, "^c(%d+)_(%d+)$")
		if a and cutFolder:GetAttribute(name) ~= nil then
			release((tonumber(a) - 500000) .. "," .. (tonumber(b) - 500000))
		else
			settled = false -- repousse : on revient la dessiner
		end
	end)
end

local function tick()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local pos = root.Position
	local R = radius()
	local now = os.clock()
	params.FilterDescendantsInstances = { char, folder, workspace:FindFirstChild("FauneLocale") }
	-- 1) ce qui est trop loin s'en va
	for key, parts in active do
		local p = parts[1]
		local d = Vector2.new(p.Position.X - pos.X, p.Position.Z - pos.Z).Magnitude
		if d > R + 8 then
			release(key)
		end
	end
	for key, pr in probe do
		if now > pr[2] + 30 then
			probe[key] = nil
		end
	end
	if settled and lastScan and (pos - lastScan).Magnitude < 3 then
		return
	end
	lastScan = pos
	-- 2) les cases proches qui ont une touffe
	local c0x, c0z = math.floor(pos.X / CELL), math.floor(pos.Z / CELL)
	local span = math.ceil(R / CELL)
	local rays = 0
	for dz = -span, span do
		for dx = -span, span do
			if (dx * dx + dz * dz) * CELL * CELL <= R * R then
				local cx, cz = c0x + dx, c0z + dz
				local key = cx .. "," .. cz
				if not active[key] then
					local info = HH.at(cx, cz)
					if info and not isCut(cx, cz) then
						local pr = probe[key]
						if pr and now <= pr[2] then
							if pr[1] then
								spawnClump(key, cx, cz, info, pr[1], pr[3]) -- sol déjà sondé : on revient
							end
						elseif rays < RAYS_PER_TICK then
							rays += 1
							local r = workspace:Raycast(Vector3.new(info.x, pos.Y + 60, info.z), Vector3.new(0, -160, 0), params)
							local sorte = false
							if r and r.Instance:IsA("Terrain") then
								sorte = HH.sorteFor(info, r.Material) or false
								if sorte then
									spawnClump(key, cx, cz, info, sorte, r.Position)
								end
							end
							-- terrain pas encore chargé : on réessaie bientôt ; sol refusé : plus tard
							probe[key] = { sorte, now + (r and 20 or 2), r and r.Position }
						end
					end
				end
			end
		end
	end
	settled = rays == 0 -- plus rien à sonder ici : on attend que le joueur bouge
end

while true do
	local ok, err = pcall(tick)
	if not ok then
		warn("[WildAcres] HerbeHaute : " .. tostring(err))
		task.wait(2)
	end
	task.wait(0.4)
end
