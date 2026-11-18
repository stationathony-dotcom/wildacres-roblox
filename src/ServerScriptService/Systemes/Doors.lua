-- Portes des maisons : ouvrir / fermer, fermées à clé la nuit quand l'habitant dort chez lui
-- (crocheter = effraction si quelqu'un le voit). Les PNJ passent les portes (groupe de collision).

local TweenService = game:GetService("TweenService")

local Doors = {}
local G
local doors = {} -- houseId -> entry

function Doors.init(g)
	G = g
	G.Interact.onPrompt("door", function(player, prompt)
		local d = doors[prompt:GetAttribute("House")]
		if d then
			Doors.toggle(d, player)
		end
	end)
	G.Interact.onPrompt("lockpick", function(player, prompt)
		local d = doors[prompt:GetAttribute("House")]
		if d then
			Doors.lockpick(d, player)
		end
	end)
end

local function setOpen(d, open: boolean, instant: boolean?)
	if d.open == open then
		return
	end
	d.open = open
	for part, closed in d.closed do
		local target = open and (d.swing * closed) or closed
		if instant then
			part.CFrame = target
		else
			TweenService:Create(part, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { CFrame = target }):Play()
		end
		part.CanCollide = not open and part.Name == "Battant"
	end
	if d.prompt then
		d.prompt.ActionText = open and "Fermer" or "Ouvrir"
	end
end

function Doors.isLocked(d): boolean
	if d.picked == G.world.day then
		return false
	end
	local h = G.Clock.hour()
	local kind = d.house.data.kind
	if kind == "shop" and (h >= 19 or h < 7) then
		return true
	end
	return G.Npcs.ownerAsleepAt(d.house.data.id)
end

local function refreshPrompts(d)
	local locked = Doors.isLocked(d) and not d.open
	d.prompt.Enabled = not locked
	d.lockPrompt.Enabled = locked
end

function Doors.onRegionLoad(reg)
	for id, h in reg.houses do
		local porte = h.model:FindFirstChild("Porte")
		if porte then
			local battant = porte:FindFirstChild("Battant")
			local hinge = battant and battant:FindFirstChild("Charniere")
			if battant and hinge then
				local d = { house = h, model = porte, closed = {}, open = false, reg = reg }
				local hc = hinge.WorldCFrame
				d.swing = hc * CFrame.Angles(0, math.rad(95), 0) * hc:Inverse()
				for _, p in porte:GetDescendants() do
					if p:IsA("BasePart") then
						d.closed[p] = p.CFrame
						p.CollisionGroup = "Portes"
					end
				end
				local mod = Instance.new("PathfindingModifier")
				mod.PassThrough = true
				mod.Parent = battant
				local outside = battant.CFrame * CFrame.new(0, 0, 0)
				d.prompt = G.Util.prompt(battant, "door", "Ouvrir", nil, { data = { House = id }, dist = 8 })
				d.lockPrompt = G.Util.prompt(battant, "lockpick", "Crocheter", "Fermé à clé", { data = { House = id }, dist = 8, hold = 1.5 })
				d.lockPrompt.Enabled = false
				doors[id] = d
				h.door = d
				refreshPrompts(d)
			end
		end
	end
end

function Doors.onRegionUnload(reg)
	for id in reg.houses do
		doors[id] = nil
	end
end

function Doors.toggle(d, player: Player)
	if not d.open and Doors.isLocked(d) then
		G.Util.toast(player, "C'est fermé à clé.")
		return
	end
	setOpen(d, not d.open)
	local root = G.Util.root(player)
	if root then
		G.Util.sfx("porte", root.Position)
	end
	d.byPlayer = d.open
	d.openedAt = os.clock()
	refreshPrompts(d)
end

function Doors.lockpick(d, player: Player)
	if not Doors.isLocked(d) then
		return
	end
	d.picked = G.world.day
	setOpen(d, true)
	d.byPlayer = true
	d.openedAt = os.clock()
	refreshPrompts(d)
	local pos = d.model:GetPivot().Position
	G.Law.crime(player, "breakin", pos, nil)
	G.Util.toast(player, "Clic… La serrure cède.")
end

-- Un PNJ passe : la porte s'ouvre un instant
function Doors.npcPass(houseId: string)
	local d = doors[houseId]
	if not d then
		return
	end
	d.npcAt = os.clock()
	if not d.open then
		setOpen(d, true)
		d.byPlayer = false
		d.openedAt = os.clock()
		refreshPrompts(d)
	end
end

function Doors.get(houseId: string)
	return doors[houseId]
end

-- Referme les portes ouvertes par les PNJ ; met à jour les serrures
local acc = 0
function Doors.step(dt: number)
	acc += dt
	if acc < 1 then
		return
	end
	acc = 0
	local now = os.clock()
	for _, d in doors do
		if d.open and not d.byPlayer and now - (d.npcAt or 0) > 3 then
			setOpen(d, false)
		end
		if d.prompt then
			refreshPrompts(d)
		end
	end
end

return Doors
