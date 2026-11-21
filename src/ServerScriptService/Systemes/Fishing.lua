-- Pêche : lancer la ligne devant soi dans l'eau, attendre que ça morde (le bouchon plonge),
-- cliquer vite pour ferrer. Poissons selon la saison et la chance.

local Fishing = {}
local G, Config
local lines = {} -- joueur -> {bobber, bite, window, until}

function Fishing.init(g)
	G = g
	Config = G.Config
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		Fishing.stop(p)
	end)
end

function Fishing.stop(player: Player)
	local l = lines[player]
	if l then
		if l.bobber then
			l.bobber:Destroy()
		end
		lines[player] = nil
	end
	player:SetAttribute("Fishing", nil)
end

-- Appât (fabriqué avec des restes pourris) : consommé au lancer, la touche vient plus vite et les
-- poissons rares (poids ≤ 15) mordent davantage
local BAIT_SPEED = 0.65
local BAIT_RARE = 1.5

local function pickFish(player: Player, baited: boolean?, at: Vector3?): number
	local root = G.Util.root(player)
	local where = at or (root and root.Position)
	local biome = where and G.Clock.biomeAt(where) or "prairie"
	local luck = G.Joueurs.stats(player).chance or 0
	local pool, total = {}, 0
	for i, f in Config.FISH do
		local ok = (not f.biomes or table.find(f.biomes, biome) ~= nil) and (f.skill or 0) <= G.Joueurs.skillRaw(player, "peche") -- déblocage : compétence entraînée seulement (règle 4)
		if ok then
			local w = f.weight
			if f.weight <= 15 then
				w = w * (1 + luck * 0.15) * (baited and BAIT_RARE or 1)
			end
			table.insert(pool, { i, w })
			total += w
		end
	end
	local r = math.random() * total
	for _, p in pool do
		r -= p[2]
		if r <= 0 then
			return p[1]
		end
	end
	return 1
end

Fishing.pick = pickFish -- (joueur, appâté, position) -> indice dans Config.FISH (nasses)

function Fishing.use(player: Player)
	local l = lines[player]
	if l then
		local now = os.clock()
		if l.biteAt and now >= l.biteAt and now <= l.biteAt + l.window then
			local i = pickFish(player, l.baited)
			G.Joueurs.add(player, "fish_" .. i, 1)
			G.Util.finds(player, "fish")
			G.Joueurs.addSkillXp(player, "peche", 5 + math.floor(Config.FISH[i].price / 10))
			G.Social.collect(player, "fish", tostring(i))
			G.Social.bump(player, "fished")
			if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "pecher", "fish_" .. i) end
			if G.Activites.note then
				G.Activites.note(player, "peche")
			end
			if Config.FISH[i].weight <= 2 then
				G.Util.toast(player, "Incroyable ! Un " .. Config.FISH[i].name .. " !", "big")
			end
		elseif l.biteAt and now < l.biteAt then
			G.Util.toast(player, "Trop tôt… Le poisson a fui.")
		else
			G.Util.toast(player, "Trop tard… Il a filé.")
		end
		G.Props.swing(player, "rod")
		Fishing.stop(player)
		return
	end
	local root = G.Util.root(player)
	if not root or player:GetAttribute("Swimming") then
		return
	end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z).Unit
	local spot
	for d = 5, 20, 1.5 do
		local p = root.Position + flat * d
		if G.Util.isWater(p.X, p.Z) then
			spot = Vector3.new(p.X, Config.WATER_Y, p.Z) + flat * 2
			break
		end
	end
	if not spot then
		G.Util.toast(player, "Approche-toi de l'eau et vise-la pour lancer la ligne.")
		return
	end
	G.Props.swing(player, "rod")
	local b = Instance.new("Part")
	b.Name = "Bouchon"
	b.Shape = Enum.PartType.Ball
	b.Size = Vector3.one * 0.7
	b.Color = Color3.fromRGB(230, 50, 50)
	b.Anchored = true
	b.CanCollide = false
	b.CanQuery = false
	b.CFrame = CFrame.new(spot + Vector3.new(0, 0.2, 0))
	local top = Instance.new("Part")
	top.Shape = Enum.PartType.Ball
	top.Size = Vector3.one * 0.45
	top.Color = Color3.new(1, 1, 1)
	top.Anchored = true
	top.CanCollide = false
	top.CanQuery = false
	top.CFrame = b.CFrame * CFrame.new(0, 0.35, 0)
	top.Parent = b
	b.Parent = workspace
	-- ligne entre la canne et le bouchon
	local char = player.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	local tip = tool and tool:FindFirstChild("Fil")
	if tip then
		local a0 = Instance.new("Attachment")
		a0.Parent = tip
		local a1 = Instance.new("Attachment")
		a1.Parent = b
		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = 0.06
		beam.Width1 = 0.06
		beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
		beam.CurveSize0 = -2
		beam.Parent = b
		b.Destroying:Connect(function()
			a0:Destroy()
		end)
	end
	local luck = G.Joueurs.stats(player).chance or 0
	local baited = G.Joueurs.take(player, "bait", 1)
	if baited then
		G.Joueurs.sync(player)
	end
	local wait = (2.5 + math.random() * 5) * (G.Meteo and G.Meteo.biteMult and G.Meteo.biteMult() or 1) * (baited and BAIT_SPEED or 1)
	lines[player] = { bobber = b, biteAt = os.clock() + wait, window = 1.2 + luck * 0.08, base = b.CFrame, baited = baited }
	player:SetAttribute("Fishing", true)
end

-- Pêche au HARPON (20/11, « liste items.txt » + A-RETRAVAILLER) : pas d'attente ni de bouchon, on lance
-- dans l'eau devant soi (3 à 10 studs) ; touché ou raté selon la compétence de pêche (entraînée) et la
-- Chance ; vise plutôt les gros poissons. Un lancer toutes les HARPOON.cooldown s. Appelé par Tools.use
-- quand le harpon est en main (Codex). Renvoie true si un lancer a eu lieu.
Fishing.HARPOON = { cooldown = 2.5, base = 0.25, perSkill = 0.015, perLuck = 0.01, max = 0.7, near = 3, far = 10 }
Fishing.roll = math.random -- remplaçable par les bancs
local lastThrow = setmetatable({}, { __mode = "k" }) -- joueur -> dernier lancer
function Fishing.harpoon(player: Player): boolean
	local H = Fishing.HARPOON
	local root = G.Util.root(player)
	if not root then
		return false
	end
	local now = os.clock()
	if lastThrow[player] and now - lastThrow[player] < H.cooldown then
		return false
	end
	local flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if flat.Magnitude < 0.1 then
		return false
	end
	flat = flat.Unit
	local spot
	for d = H.near, H.far do
		local p = root.Position + flat * d
		if G.Util.isWater(p.X, p.Z) then
			spot = Vector3.new(p.X, Config.WATER_Y, p.Z)
			break
		end
	end
	if not spot then
		G.Util.toast(player, "🔱 Vise l'eau, de près : le harpon ne porte pas loin.")
		return false
	end
	lastThrow[player] = now -- le geste du lancer est joué par Tools (harpon en main)
	local skill = G.Joueurs.skillRaw and G.Joueurs.skillRaw(player, "peche") or 0
	local luck = G.Joueurs.stats(player).chance or 0
	local chance = math.min(H.max, H.base + skill * H.perSkill + luck * H.perLuck)
	G.Joueurs.addSkillXp(player, "peche", 2)
	if Fishing.roll() >= chance then
		G.Util.toast(player, "🔱 Raté… l'eau se trouble.")
		return true
	end
	local i = pickFish(player, true, spot) -- les gros poissons ressortent plus (comme avec un appât)
	G.Joueurs.add(player, "fish_" .. i, 1)
	G.Util.finds(player, "fish")
	G.Joueurs.addSkillXp(player, "peche", 4 + math.floor(Config.FISH[i].price / 10))
	G.Social.collect(player, "fish", tostring(i))
	G.Social.bump(player, "fished")
	if G.Quetes and rawget(G.Quetes, "note") then
		G.Quetes.note(player, "pecher", "fish_" .. i)
	end
	if G.Activites.note then
		G.Activites.note(player, "peche")
	end
	return true
end

function Fishing.step(dt: number)
	local now = os.clock()
	for player, l in lines do
		local root = G.Util.root(player)
		if not root or not player.Parent or (root.Position - l.base.Position).Magnitude > 30 then
			Fishing.stop(player)
		elseif l.bobber then
			if now >= l.biteAt and now <= l.biteAt + l.window then
				if not l.told then
					l.told = true
					G.remotes.Fx:FireClient(player, "bite")
				end
				l.bobber.CFrame = l.base * CFrame.new(0, -0.5 + math.sin(now * 30) * 0.15, 0)
			elseif now > l.biteAt + l.window then
				if not l.missed then
					l.missed = true
					-- nouvelle touche plus tard
					l.biteAt = now + 2 + math.random() * 4
					l.told = false
					l.missed = false
				end
				l.bobber.CFrame = l.base
			else
				l.bobber.CFrame = l.base * CFrame.new(0, math.sin(now * 3) * 0.08, 0)
			end
		end
	end
end

return Fishing
