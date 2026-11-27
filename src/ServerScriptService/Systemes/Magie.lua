-- Magie (27/11, MANQUES-MMO n° 4) : sorts appris dans des grimoires (Shared/Equilibre E.SORTS).
--   · Lire un grimoire (objet « cat_grimoire ») apprend le sort pour toujours : prof.sorts[id] = jour.
--   · Action « sort » { id, target? } : endurance + temps de recharge ; puissance = base + 2 × la
--     caractéristique de l'école (pas de niveau, règle 4). Lancer entraîne cette caractéristique.
--   · Effets : degats (projectile), gel (dégâts + ralenti 3 s), soin (soi et alliés proches),
--     repousse (souffle autour de soi), armure (dégâts subis divisés par deux quelques secondes).
-- Le client (Codex) choisit la touche et l'effet visuel ; le serveur décide de tout.

local Debris = game:GetService("Debris")

local Magie = {}
local G
local Eq

Magie.SORTS = {} -- id -> fiche
local last = {} -- player -> { [id] = os.clock() }
Magie.shield = {} -- player -> os.clock() de fin de « Peau de pierre »

local function load()
	local ok, E = true, G.Equilibre -- les bancs passent leur copie (le require de Studio est en cache)
	if not E then
		ok, E = pcall(require, game:GetService("ReplicatedStorage").Shared.Equilibre)
	end
	Eq = ok and E or nil
	for _, sp in (Eq and Eq.SORTS) or {} do
		Magie.SORTS[sp[1]] = { id = sp[1], ecole = sp[2], name = sp[3], icon = sp[4], cout = sp[5], cd = sp[6], portee = sp[7],
			effet = sp[8], base = sp[9], stat = sp[10] }
	end
end

function Magie.knows(player: Player, id: string): boolean
	local prof = G.Joueurs.get(player)
	return prof ~= nil and type(prof.sorts) == "table" and prof.sorts[id] ~= nil
end

-- lire un grimoire (Joueurs.useCatalogue, usage « grimoire ») : vrai si le sort est appris
function Magie.learn(player: Player, id: string): boolean
	local sp = Magie.SORTS[id]
	local prof = G.Joueurs.get(player)
	if not (sp and prof) then
		return false
	end
	prof.sorts = prof.sorts or {}
	if prof.sorts[id] then
		G.Util.toast(player, "Tu connais déjà " .. sp.name .. ".")
		return false
	end
	prof.sorts[id] = G.world.day or 1
	G.Joueurs.markDirty(player)
	local n = 0
	for _ in prof.sorts do
		n += 1
	end
	if G.Social and rawget(G.Social, "bump") then
		G.Social.bump(player, "sorts", n, true) -- titres « Mage itinérant », « Archimage »
	end
	G.Util.toast(player, sp.icon .. " Tu apprends « " .. sp.name .. " » (" .. sp.ecole .. ").", "gain")
	G.Joueurs.sync(player)
	return true
end

local function power(player: Player, sp): number
	local st = G.Joueurs.stats(player) or {}
	return sp.base + 2 * (st[sp.stat] or 0)
end

-- ennemi visé (id envoyé par le client, à portée) sinon le plus proche devant soi
local function targetOf(player: Player, root, sp, targetId: string?)
	local en = targetId and G.Enemies.byId(targetId)
	if en and en.pos and (en.pos - root.Position).Magnitude <= sp.portee then
		return en
	end
	local best, bd = nil, sp.portee
	local look = root.CFrame.LookVector
	for _, e in G.Enemies.list or {} do
		if not e.dead and e.pos then
			local d = e.pos - root.Position
			local m = d.Magnitude
			if m <= bd and (m < 4 or d.Unit:Dot(look) > 0.3) then
				best, bd = e, m
			end
		end
	end
	return best
end

local function bolt(from: Vector3, to: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Name = "Sort"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(1.2, 1.2, 1.2)
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.CFrame = CFrame.new(from)
	p.Parent = workspace
	game:GetService("TweenService"):Create(p, TweenInfo.new(0.25), { CFrame = CFrame.new(to) }):Play()
	Debris:AddItem(p, 0.35)
end

local COLORS = { pyro = Color3.fromRGB(255, 120, 40), cryo = Color3.fromRGB(150, 220, 255), druide = Color3.fromRGB(120, 230, 110),
	aero = Color3.fromRGB(220, 240, 255), geo = Color3.fromRGB(170, 150, 120) }

-- lance un sort ; renvoie (vrai, message) si lancé
function Magie.cast(player: Player, id: string, targetId: string?): (boolean, string?)
	local sp = Magie.SORTS[id]
	local root = G.Util.root(player)
	if not (sp and root) then
		return false, nil
	end
	if not Magie.knows(player, id) then
		return false, "Tu ne connais pas ce sort."
	end
	last[player] = last[player] or {}
	local now = os.clock()
	if (last[player][id] or -1e9) + sp.cd > now then
		return false, nil
	end
	local en
	if sp.effet == "degats" or sp.effet == "gel" then
		en = targetOf(player, root, sp, targetId)
		if not en then
			return false, "Aucune cible à portée."
		end
	end
	if not G.Combat.spendStamina(player, sp.cout) then
		return false, "Trop essoufflé pour lancer " .. sp.name .. "."
	end
	last[player][id] = now
	local pw = power(player, sp)
	local col = COLORS[sp.ecole] or Color3.new(1, 1, 1)
	if en then
		bolt(root.Position + Vector3.new(0, 1.5, 0), en.pos + Vector3.new(0, 2, 0), col)
		G.Enemies.hit(en, pw, player)
		if sp.effet == "gel" then
			en.slowUntil = now + 3
		end
	elseif sp.effet == "soin" then
		for _, q in G.Game.players() do
			local r = G.Util.root(q)
			local hum = q.Character and q.Character:FindFirstChildOfClass("Humanoid")
			if r and hum and hum.Health > 0 and (r.Position - root.Position).Magnitude <= sp.portee then
				hum.Health = math.min(hum.MaxHealth, hum.Health + pw)
			end
		end
	elseif sp.effet == "repousse" then
		for _, e in G.Enemies.list or {} do
			if not e.dead and e.pos then
				local d = e.pos - root.Position
				if d.Magnitude <= sp.portee then
					G.Enemies.hit(e, pw, player)
					local flat = Vector3.new(d.X, 0, d.Z)
					if flat.Magnitude > 0.1 then
						e.pos += flat.Unit * 8
					end
				end
			end
		end
	elseif sp.effet == "armure" then
		Magie.shield[player] = now + pw
	end
	G.Joueurs.addStatXp(player, sp.stat, 4)
	G.Util.geste(player, "sort")
	return true, nil
end

-- dégâts subis pendant « Peau de pierre » (Combat.hurtPlayer) : multiplicateur
function Magie.damageMult(player: Player): number
	local t = Magie.shield[player]
	return (t and os.clock() < t) and 0.5 or 1
end

-- ce que le client affiche : sorts connus, recharge restante
function Magie.list(player: Player)
	local out, now = {}, os.clock()
	for id, sp in Magie.SORTS do
		if Magie.knows(player, id) then
			local l = last[player] and last[player][id]
			table.insert(out, { id = id, name = sp.name, icon = sp.icon, ecole = sp.ecole, cout = sp.cout,
				reste = l and math.max(0, l + sp.cd - now) or 0 })
		end
	end
	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

function Magie.init(g)
	G = g
	load()
	G.Interact.onAction("sort", function(player, data)
		if type(data) ~= "table" or type(data.id) ~= "string" then
			return
		end
		local target = type(data.target) == "string" and data.target or nil
		local ok, msg = Magie.cast(player, data.id, target)
		if not ok and msg then
			G.Util.toast(player, msg)
		end
	end)
	G.Interact.onAction("sorts", function(player)
		G.remotes.Menu:FireClient(player, { kind = "sorts", sorts = Magie.list(player) })
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		last[p] = nil
		Magie.shield[p] = nil
	end)
end

return Magie
