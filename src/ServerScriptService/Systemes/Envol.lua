-- Envol : montures volantes (lot C18, 26/11 ; demande du propriétaire le 25/11 : « montures volantes,
-- griffon, hippogriffe, wyverne apprivoisés »).
--
-- Comment on en a une : comme tout compagnon (Systemes/Compagnons) — on AFFAIBLIT la bête sauvage, puis
-- mini-jeu d'apprivoisement avec son appât et un Dressage élevé. Aucune limite de nombre (règle 2) :
-- on garde autant de montures qu'on peut en nourrir (Compagnons les nourrit chaque matin).
-- Grind (règle 5) : Dressage 25 à 40 selon la bête, et chaque envol coûte un appât (la bête mange pour
-- porter un cavalier). Le vol use son SOUFFLE : à bout de souffle, elle plane vers le sol et se repose.
--
-- Le pilotage est côté client (Envol.client : LinearVelocity + AlignOrientation sur le joueur, qui
-- possède déjà son personnage) ; ici : monter, descendre, souffle, coût, nettoyage.
-- Attributs du joueur lus par le client : Flying, FlySpeed, FlyClimb, FlyBreath (0..1), Exhausted, Riding.

local Envol = {}
local G, Config
local riding = {} -- joueur -> compagnon monté (entrée de Compagnons)

-- vitesse (studs/s), montée (studs/s), souffle (secondes de vol), appât, difficulté, Dressage requis
Envol.FLYERS = {
	hippogriff = { speed = 52, climb = 22, breath = 130, bait = "carrot", diff = 6, skill = 25, weak = 0.35, label = "monture volante" },
	griffin = { speed = 60, climb = 26, breath = 100, bait = "meat", diff = 7, skill = 32, weak = 0.3, label = "monture volante" },
	wyvern = { speed = 66, climb = 30, breath = 80, bait = "meat", diff = 8, skill = 40, weak = 0.25, label = "monture volante" },
}
Envol.REST = 4 -- secondes de souffle rendues par seconde posée au sol
Envol.AIR = 5 -- au-dessus de cette hauteur (studs), on est « en vol » et le souffle s'use

function Envol.isFlyer(kind: string): boolean
	return Envol.FLYERS[kind] ~= nil
end

function Envol.init(g)
	G = g
	Config = G.Config
	-- les bêtes volantes s'apprivoisent comme les autres compagnons (mêmes règles, plus dures)
	for kind, f in Envol.FLYERS do
		Config.TAMING[kind] = Config.TAMING[kind] or { bait = f.bait, diff = f.diff, weak = f.weak, label = f.label }
		Config.TAME_SKILL[f.diff] = Config.TAME_SKILL[f.diff] or f.skill
	end
	G.Interact.onPrompt("pet_fly", function(player, prompt)
		local id = prompt:GetAttribute("Pet")
		local en = id and G.Compagnons.byId and G.Compagnons.byId(id)
		if en then
			Envol.mount(player, en)
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		Envol.dismount(player)
		riding[player] = nil
	end)
end

function Envol.isFlying(player: Player): boolean
	return riding[player] ~= nil
end

-- en.summoned (Systemes/Montures) : monture de collection invoquée, sans appât, détruite à la descente
function Envol.mount(player: Player, en)
	if riding[player] or en.ridden or en.dead or not en.model or not en.model.Parent then
		return
	end
	if not G.Util.owns(player, en.owner) then
		G.Util.toast(player, "Ce n'est pas ta monture.")
		return
	end
	if player:GetAttribute("Riding") or player:GetAttribute("Carrying") then
		return
	end
	local f = en.flyer or Envol.FLYERS[en.kind]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (f and root and hum and hum.Health > 0) then
		return
	end
	if (root.Position - en.pos).Magnitude > 14 then
		return
	end
	-- le vol se débloque par la pratique (Équitation), comme dans WoW
	if G.Montures and rawget(G.Montures, "canFly") and not G.Montures.canFly(player) then
		return
	end
	-- la bête mange avant de porter quelqu'un (ressource, pas plafond)
	if not en.summoned and not G.Joueurs.take(player, f.bait, 1) then
		local info = Config.needInfo(f.bait)
		G.Util.toast(player, "Elle a faim : donne-lui " .. info.icon .. " " .. info.name .. " avant de t'envoler.")
		return
	end
	G.Joueurs.sync(player)

	riding[player] = en
	en.ridden = player
	if en.prompt then
		en.prompt.Enabled = false
	end
	if en.flyPrompt then
		en.flyPrompt.Enabled = false
	end
	local base = en.model.PrimaryPart
	local _, size = en.model:GetBoundingBox()
	local seat = math.max(2.5, size.Y * 0.55)
	en.oldHip = hum.HipHeight
	en.seat = seat
	local look = (en.model:GetPivot().LookVector * Vector3.new(1, 0, 1))
	if look.Magnitude < 1e-3 then
		look = Vector3.new(0, 0, -1)
	end
	char:PivotTo(CFrame.lookAt(en.pos + Vector3.new(0, seat + 2.2, 0), en.pos + Vector3.new(0, seat + 2.2, 0) + look.Unit))
	for _, p in en.model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.Massless = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end
	en.model:PivotTo(root.CFrame * CFrame.new(0, -(seat + 2.2) + 0.1, 0))
	local w = Instance.new("WeldConstraint")
	w.Name = "Envol"
	w.Part0 = root
	w.Part1 = base
	w.Parent = base
	en.model.Parent = char
	hum.HipHeight = seat + 2.2 - root.Size.Y / 2

	en.breath = en.breath or f.breath
	local skillMul = G.Montures and rawget(G.Montures, "speedMul") and G.Montures.speedMul(player) or 1
	player:SetAttribute("FlySpeed", f.speed * skillMul * (1 + 0.1 * G.Joueurs.talent(player, "cavalier")))
	player:SetAttribute("FlyClimb", f.climb)
	player:SetAttribute("FlyBreath", en.breath / f.breath)
	player:SetAttribute("Exhausted", en.breath <= 0)
	player:SetAttribute("Riding", true) -- [X] pour descendre, pas de dégâts de chute en selle
	player:SetAttribute("Flying", true)
	G.Util.sfx("sifflet", root.Position)
	G.Joueurs.addSkillXp(player, "dressage", 2)
end

function Envol.dismount(player: Player)
	local en = riding[player]
	if not en then
		return
	end
	riding[player] = nil
	en.ridden = nil
	G.Game.noFall(player, 2)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local pos = root and root.Position or en.pos
	local gy = G.Util.groundY(pos.X, pos.Z)
	if G.Util.isWater(pos.X, pos.Z) then
		gy = math.max(gy, Config.WATER_Y)
	end
	if en.summoned then
		-- monture de collection : elle repart (façon WoW)
		if en.model then
			en.model:Destroy()
		end
		en.model = nil
	end
	if en.model then
		for _, w in en.model:GetDescendants() do
			if w:IsA("WeldConstraint") and w.Name == "Envol" then
				w:Destroy()
			end
		end
		local base = en.model.PrimaryPart
		if base then
			base.Anchored = true -- les autres pièces restent soudées à la Base (Bestiaire.build)
		end
		en.model.Parent = G.Compagnons.folder and G.Compagnons.folder() or workspace
	end
	en.pos = Vector3.new(pos.X, gy, pos.Z)
	if en.rec then
		en.rec.x, en.rec.z = math.floor(pos.X), math.floor(pos.Z)
	end
	if hum then
		hum.HipHeight = en.oldHip or 2
	end
	if root and char and (root.Position.Y - gy) < 8 then
		local right = root.CFrame.RightVector
		char:PivotTo(CFrame.new(pos.X + right.X * 4, gy + 3.5, pos.Z + right.Z * 4) * (root.CFrame - root.CFrame.Position))
	end
	if en.prompt then
		en.prompt.Enabled = true
	end
	if en.flyPrompt then
		en.flyPrompt.Enabled = true
	end
	for _, a in { "Flying", "FlySpeed", "FlyClimb", "FlyBreath", "Exhausted" } do
		player:SetAttribute(a, nil)
	end
	player:SetAttribute("Riding", false)
	if en.model and G.Enemies.render then
		G.Enemies.render(en)
	end
end

local acc = 0
function Envol.step(dt: number)
	acc += dt
	if acc < 0.25 then
		return
	end
	local step = acc
	acc = 0
	for player, en in riding do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (root and hum and hum.Health > 0) or en.dead or not en.model or not en.model.Parent then
			Envol.dismount(player)
			continue
		end
		local f = en.flyer or Envol.FLYERS[en.kind]
		local h = root.Position.Y - G.Util.groundY(root.Position.X, root.Position.Z)
		if h > Envol.AIR then
			en.breath = math.max(0, en.breath - step)
		else
			en.breath = math.min(f.breath, en.breath + Envol.REST * step)
		end
		en.pos = Vector3.new(root.Position.X, root.Position.Y - (en.seat or 3) - 2.2, root.Position.Z)
		player:SetAttribute("FlyBreath", math.floor(en.breath / f.breath * 100) / 100)
		local exhausted = en.breath <= 0 or (player:GetAttribute("Exhausted") and en.breath < f.breath * 0.25)
		player:SetAttribute("Exhausted", exhausted)
	end
end

return Envol
