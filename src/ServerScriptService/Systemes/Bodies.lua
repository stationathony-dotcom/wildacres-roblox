-- PNJ assommés : les porter sur l'épaule, les poser, les cacher (jetés à l'eau ou enterrés à
-- la pelle). Être vu en portant quelqu'un = crime grave.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Bodies = {}
local G
local carried = {} -- joueur -> entrée PNJ
local registered = {} -- entrée PNJ -> invite

function Bodies.init(g)
	G = g
	G.Interact.onPrompt("carry", function(player, prompt)
		local e = G.Npcs.byId(prompt:GetAttribute("Npc"))
		if e then
			Bodies.carry(player, e)
		end
	end)
	G.Interact.onAction("drop", function(player)
		Bodies.drop(player, false)
	end)
end

function Bodies.register(e)
	if registered[e] then
		return
	end
	local p = G.Util.prompt(e.root, "carry", "Porter", e.data.name .. " (assommé)", { data = { Npc = e.id }, dist = 8, hold = 0.4 })
	registered[e] = p
	if e.prompt then
		e.prompt.Enabled = false
	end
end

function Bodies.forget(e)
	local p = registered[e]
	if p then
		p:Destroy()
	end
	registered[e] = nil
	for pl, c in carried do
		if c == e then
			carried[pl] = nil
			pl:SetAttribute("Carrying", false)
		end
	end
	G.Law.forgetBody(e)
end

function Bodies.carriedModels()
	local out = {}
	for _, e in carried do
		table.insert(out, e.model)
	end
	return out
end

function Bodies.carry(player: Player, e)
	if carried[player] or e.state ~= "ko" or player:GetAttribute("Riding") then
		return
	end
	local root = G.Util.root(player)
	if not root then
		return
	end
	carried[player] = e
	G.Npcs.setState(e, "carried")
	local p = registered[e]
	if p then
		p.Enabled = false
	end
	for _, d in e.model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Massless = true
			d.CanCollide = false
		end
	end
	e.root.Anchored = false
	e.model:PivotTo(root.CFrame * CFrame.new(0, 2.3, 0.2) * CFrame.Angles(0, 0, math.rad(90)))
	local w = Instance.new("WeldConstraint")
	w.Name = "Portage"
	w.Part0 = root
	w.Part1 = e.root
	w.Parent = e.root
	e.hum.PlatformStand = true
	player:SetAttribute("Carrying", true)
	G.Util.toast(player, "Tu portes " .. e.data.name .. ". Jette-l" .. (e.data.female and "a" or "e") .. " à l'eau ou enterre-l" .. (e.data.female and "a" or "e") .. " (pelle). [G] pour poser.")
end

local function vanish(e, how: string)
	G.Law.bodyHidden(e)
	e.per.gone = true
	G.Npcs.setState(e, "gone")
	Bodies.forget(e)
	local model = e.model
	if how == "water" then
		task.spawn(function()
			for i = 1, 20 do
				if not model.Parent then
					break
				end
				model:PivotTo(model:GetPivot() * CFrame.new(0, 0, -0.4))
				task.wait(0.05)
			end
			model:Destroy()
		end)
	else
		model:Destroy()
	end
end

function Bodies.drop(player: Player, silent: boolean)
	local e = carried[player]
	if not e then
		return
	end
	carried[player] = nil
	player:SetAttribute("Carrying", false)
	local w = e.root:FindFirstChild("Portage")
	if w then
		w:Destroy()
	end
	if not e.model.Parent then
		return
	end
	local root = G.Util.root(player)
	local pos = root and (root.Position + root.CFrame.LookVector * 4) or e.root.Position
	local water = G.Util.isWater(pos.X, pos.Z)
	local y = water and G.Config.WATER_Y or G.Util.groundY(pos.X, pos.Z)
	e.root.Anchored = true
	e.model:PivotTo(CFrame.new(pos.X, y + 0.6, pos.Z) * CFrame.Angles(math.rad(-90), math.random() * 6, 0))
	if water and not silent then
		G.Util.toast(player, "Le courant emporte " .. e.data.name .. " au loin… Plus aucune trace.")
		vanish(e, "water")
		return
	end
	G.Npcs.setState(e, "ko")
	local p = registered[e]
	if p then
		p.Enabled = true
	end
	G.Law.onKnockOut(player, e) -- de nouveau un corps à découvrir (ou déjà vu)
end

-- Pelle : enterrer le corps porté ou celui à terre juste devant. Vrai si ça a servi.
function Bodies.shovel(player: Player): boolean
	local root = G.Util.root(player)
	if not root then
		return false
	end
	local e = carried[player]
	if e then
		Bodies.drop(player, true)
		if e.state == "gone" then
			return true
		end
	else
		for body in registered do
			if body.state == "ko" and body.model.Parent and (body.root.Position - root.Position).Magnitude < 7 then
				e = body
				break
			end
		end
	end
	if not e or e.state ~= "ko" then
		return false
	end
	local pos = e.root.Position
	if G.Util.isWater(pos.X, pos.Z) then
		return false
	end
	G.Props.swing(player, "shovel")
	-- quelqu'un regarde ?
	G.Law.crime(player, "ko", pos, nil)
	local y = G.Util.groundY(pos.X, pos.Z)
	local reg = G.World.regionAt(pos)
	if reg then
		table.insert(reg.state.graves, { x = math.floor(pos.X), z = math.floor(pos.Z) })
		G.World.buildDeco({ model = "Terre_Retournee", x = pos.X, z = pos.Z, yaw = math.random(0, 359) }, reg.folder)
	end
	G.Util.toast(player, "Tu creuses, tu rebouches… Il ne reste qu'un peu de terre retournée.")
	vanish(e, "buried")
	return true
end

function Bodies.isCarrying(player: Player): boolean
	return carried[player] ~= nil
end

return Bodies
