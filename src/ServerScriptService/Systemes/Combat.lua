-- Combat : frapper (poings, gourdin, épée, arme d'équipement) dans un cône devant soi,
-- recul, courte invulnérabilité ; dégâts reçus réduits par la défense.

local Debris = game:GetService("Debris")

local Combat = {}
local G
local cooldown = {}
local invuln = {}

local SAFE_SPAWN_R = 60 -- studs autour de l'arrivée : pas de combat entre joueurs
local KO_GRACE = 600 -- s : protection contre celui qui vient de te mettre K.O.
local koBy = {} -- UserId victime -> { [UserId agresseur] = os.clock() }

function Combat.init(g)
	G = g
	G.Interact.onAction("hit", function(player, data)
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		local id = tool and tool:GetAttribute("ItemId")
		local base = id and G.Config.baseOf(id)
		local target = type(data) == "table" and type(data.target) == "string" and data.target or nil
		if base == "club" or base == "sword" or base == "axe" or base == "pickaxe" then
			Combat.attack(player, id, target)
		else
			Combat.attack(player, nil, target)
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		cooldown[p] = nil
		invuln[p] = nil
	end)
end

function Combat.damageOf(player: Player, itemId: string?): number
	local prof = G.Joueurs.get(player)
	local base = 10
	local info = itemId and G.Config.ITEMS[itemId]
	if info and info.weapon then
		base = info.weapon * 10
	elseif itemId and (G.Config.baseOf(itemId) == "axe" or G.Config.baseOf(itemId) == "pickaxe") then
		base = 10 + 5 * G.Config.tierOf(itemId)
	end
	local w = prof and prof.equipped.weapon
	if w then
		base = math.max(base, (w.power or 1) * 10)
	end
	local force = G.Joueurs.stats(player).force or 0
	local dmg = (base + force * 3) * (1 + 0.01 * G.Joueurs.skill(player, "combat"))
	if math.random() < 0.12 * G.Joueurs.talent(player, "critique") then
		dmg *= 2
	end
	return math.floor(dmg)
end

function Combat.popup(at: Vector3, text: string, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one * 0.2
	p.CFrame = CFrame.new(at)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(80, 36)
	bb.AlwaysOnTop = true
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.2
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.Parent = bb
	bb.Parent = p
	p.Parent = workspace
	task.spawn(function()
		for i = 1, 12 do
			p.CFrame = p.CFrame + Vector3.new(0, 0.12, 0)
			t.TextTransparency = i / 14
			task.wait(0.04)
		end
		p:Destroy()
	end)
end

function Combat.swoosh(player: Player)
	local root = G.Util.root(player)
	if not root then
		return
	end
	G.remotes.Fx:FireAllClients("swing", root.Position + root.CFrame.LookVector * 3)
end

function Combat.attack(player: Player, itemId: string?, targetId: string?)
	local now = os.clock()
	if cooldown[player] and now - cooldown[player] < 0.45 then
		return
	end
	cooldown[player] = now
	local root = G.Util.root(player)
	if not root or player:GetAttribute("Carrying") then
		return
	end
	G.Props.swing(player)
	Combat.swoosh(player)
	local dmg = Combat.damageOf(player, itemId)
	local look = root.CFrame.LookVector
	local best, bd, kind = nil, 7.5, nil
	local function consider(pos: Vector3, target, k: string, reach: number)
		local d = pos - root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		local dist = flat.Magnitude - reach
		if dist < bd and math.abs(d.Y) < 8 and (flat.Magnitude < 3 or look:Dot(flat.Unit) > 0.35) then
			best, bd, kind = target, dist, k
		end
	end
	-- cible choisie (clic façon WoW) : frappée en priorité si elle est à portée, on se tourne vers elle
	local chosen = targetId and G.Enemies.byId(targetId)
	if chosen and chosen.model.Parent then
		local d = chosen.pos - root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude - (chosen.radius or 1.5) < 7.5 and math.abs(d.Y) < 8 then
			best, bd, kind = chosen, -1e9, "enemy"
			if flat.Magnitude > 0.1 then
				root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
			end
		end
	end
	for _, en in G.Enemies.list do
		if not en.dead and en.model.Parent then
			consider(en.pos, en, "enemy", en.radius or 1.5)
		end
	end
	for _, e in G.Npcs.list do
		-- les enfants ne sont jamais des cibles
		if e.model.Parent and e.state ~= "ko" and e.state ~= "carried" and e.state ~= "gone" and not e.data.child then
			consider(e.root.Position, e, "npc", 1)
		end
	end
	for _, a in G.Animals.list or {} do
		if a.model.Parent then
			consider(a.pos, a, "animal", 1.5)
		end
	end
	for _, pet in G.Compagnons.list do
		if not pet.dead and pet.model.Parent and not G.Util.owns(player, pet.owner) then
			consider(pet.pos, pet, "pet", pet.radius or 1.2)
		end
	end
	-- les autres joueurs : légal sur un recherché (chasse aux primes), agression sinon
	for _, other in G.Game.players() do
		local r = other ~= player and G.Util.root(other)
		if r then
			consider(r.Position, other, "player", 1)
		end
	end
	if not best then
		return
	end
	-- l'arme qui touche s'use (comme les outils : elle finit par casser, cf. Joueurs.wearTool)
	if itemId and G.Joueurs.wearTool then
		local base = G.Config.baseOf(itemId)
		if base == "sword" or base == "club" or base == "axe" or base == "pickaxe" then
			G.Joueurs.wearTool(player, base)
		end
	end
	if kind == "enemy" then
		G.Enemies.hit(best, dmg, player)
	elseif kind == "npc" then
		G.Npcs.hit(best, dmg, player)
	elseif kind == "animal" then
		G.Animals.hit(best, player)
	elseif kind == "pet" then
		G.Compagnons.hit(best, dmg, player)
	elseif kind == "player" then
		local victim = best :: Player
		local vprof = G.Joueurs.get(victim)
		local vroot = G.Util.root(victim)
		if not vprof or not vroot then
			return
		end
		if not G.Config.LIBRE.bouclierArrivee then
			-- monde libre : pas de bouclier d'arrivée
		elseif os.clock() < (victim:GetAttribute("SpawnShield") or 0) or os.clock() < (player:GetAttribute("SpawnShield") or 0) then
			G.Util.toast(player, "Protection d'arrivée : pas de combat entre joueurs pendant 20 s.")
			return
		end
		-- zone sûre : l'arrivée du monde (pas d'embuscade sur ceux qui débarquent)
		if G.Config.LIBRE.zoneSureArrivee and (vroot.Position - G.Game.spawnPos()).Magnitude < SAFE_SPAWN_R then
			G.Util.toast(player, "On ne se bat pas sur le lieu d'arrivée.")
			return
		end
		-- anti-acharnement : celui qui t'a mis K.O. ne peut plus te frapper pendant 10 minutes
		local k = koBy[victim.UserId]
		if G.Config.LIBRE.graceApresKO and k and k[player.UserId] and os.clock() - k[player.UserId] < KO_GRACE then
			G.Util.toast(player, victim.DisplayName .. " vient de se relever : laisse-le tranquille un moment.")
			return
		end
		if (vprof.stars or 0) <= 0 then
			G.Law.crime(player, "assault", vroot.Position, G.Util.pid(victim))
		end
		victim:SetAttribute("LastHitBy", player.UserId)
		victim:SetAttribute("LastHitAt", os.clock())
		Combat.hurtPlayer(victim, dmg, root.Position)
		Combat.popup(vroot.Position + Vector3.new(0, 3, 0), tostring(dmg), Color3.fromRGB(255, 120, 100))
	end
end

-- Appelé par Game.onDeath quand un joueur est mis K.O. par un autre
function Combat.noteKO(victim: Player, attackerId: number)
	koBy[victim.UserId] = koBy[victim.UserId] or {}
	koBy[victim.UserId][attackerId] = os.clock()
end

function Combat.hurtPlayer(player: Player, dmg: number, fromPos: Vector3?)
	local now = os.clock()
	if invuln[player] and now - invuln[player] < 0.6 then
		return
	end
	invuln[player] = now
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	local def = G.Joueurs.stats(player).defense or 0
	local real = math.max(1, math.floor(dmg * (1 - math.min(0.6, def * 0.04))))
	hum:TakeDamage(real)
	G.remotes.Fx:FireClient(player, "hurt", fromPos)
end

return Combat
