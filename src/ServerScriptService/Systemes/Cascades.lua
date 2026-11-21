-- Cascades (21/11, « listes ennemi.txt » § monde : « Cascades ») : sur environ une région sur quatre qui a
-- une falaise de plateau (deux niveaux qui se touchent, hors route, lieu et eau), une chute d'eau tombe du
-- haut de la falaise dans un petit bassin, avec de la brume. Décor naturel donc ramassable (règle 6) :
-- on y remplit son seau vide ([E] « Remplir le seau »), autant de fois qu'on veut.
--
-- Posé par-dessus la génération avec sa propre graine (« cascade ») : aucun tirage existant ne change,
-- le même monde donne toujours les mêmes cascades. Rien n'est sauvegardé (recalculé au chargement).

local Cascades = {}
local G, Config

Cascades.CHANCE = 0.25
Cascades.MIN_DROP = 5 -- studs de dénivelé au minimum

function Cascades.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("cascade", function(player, prompt)
		Cascades.fill(player, prompt)
	end)
end

-- Cherche une falaise dans le plan : { x, z (pied), top, bottom, dx, dz (vers le bas) } ou nil
function Cascades.site(plan, rng: Random)
	local idx = G.WG.idx
	local CELL, REGION = Config.CELL, Config.REGION
	local found = {}
	for lz = 2, REGION - 3, 2 do
		for lx = 2, REGION - 3, 2 do
			local i = idx(lx, lz)
			if not plan.water[i] and (plan.roadD[i] or 99) > 3 and not (plan.inPoi and plan.inPoi[i]) then
				for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
					local j = idx(lx + d[1], lz + d[2])
					local drop = (plan.H[i] or 0) - (plan.H[j] or 0)
					if not plan.water[j] and (plan.level[i] or 0) > (plan.level[j] or 0) and drop >= Cascades.MIN_DROP
						and (plan.roadD[j] or 99) > 3 and not (plan.inPoi and plan.inPoi[j]) then
						table.insert(found, { lx = lx, lz = lz, dx = d[1], dz = d[2], top = plan.H[i], bottom = plan.H[j] })
					end
				end
			end
		end
	end
	if #found == 0 then
		return nil
	end
	local c = found[rng:NextInteger(1, #found)]
	-- pied de la falaise : au bord de la case basse, côté falaise
	local x = (plan.x0 + c.lx + 0.5 + c.dx * 0.5) * CELL
	local z = (plan.z0 + c.lz + 0.5 + c.dz * 0.5) * CELL
	return { x = x, z = z, top = c.top, bottom = c.bottom, dx = c.dx, dz = c.dz }
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	return p
end

function Cascades.onRegionLoad(reg)
	local p = reg.plan
	if not p or p.poi or (reg.rx == 0 and reg.rz == 0) or not p.level or not p.H then
		return
	end
	local rng = Random.new(G.WG.hash(G.world.seed, "cascade", reg.rx, reg.rz))
	if rng:NextNumber() >= Cascades.CHANCE then
		return
	end
	local s = Cascades.site(p, rng)
	if not s then
		return
	end
	local folder = Instance.new("Model")
	folder.Name = "Cascade"
	local h = s.top - s.bottom
	local look = CFrame.lookAt(Vector3.new(s.x, 0, s.z), Vector3.new(s.x + s.dx, 0, s.z + s.dz)) -- regarde vers le bas
	local base = look - look.Position + Vector3.new(s.x, s.bottom, s.z)
	-- lookAt : l'avant (-Z) regarde vers le bas de la falaise. La nappe tombe contre la falaise, un peu en avant
	local fall = part({ Name = "Chute", Size = Vector3.new(3, h + 0.6, 0.4), Material = Enum.Material.Glass,
		Color = Color3.fromRGB(176, 214, 236), Transparency = 0.35, CFrame = base * CFrame.new(0, h / 2 + 0.3, -0.3) })
	fall.Parent = folder
	-- le bassin au pied
	local pool = part({ Name = "Bassin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 7, 7), Material = Enum.Material.Glass,
		Color = Color3.fromRGB(80, 140, 180), Transparency = 0.25, CFrame = base * CFrame.new(0, 0.15, -3.2) * CFrame.Angles(0, 0, math.rad(90)) })
	pool.Parent = folder
	local rim = part({ Name = "Margelle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 7.8, 7.8), Material = Enum.Material.Slate,
		Color = Color3.fromRGB(110, 108, 100), CFrame = base * CFrame.new(0, 0.05, -3.2) * CFrame.Angles(0, 0, math.rad(90)) })
	rim.Parent = folder
	-- brume au pied de la chute
	local att = Instance.new("Attachment")
	att.Parent = pool
	local mist = Instance.new("ParticleEmitter")
	mist.Rate = 6
	mist.Lifetime = NumberRange.new(1.5, 2.5)
	mist.Speed = NumberRange.new(1, 2)
	mist.SpreadAngle = Vector2.new(60, 60)
	mist.Size = NumberSequence.new(1.2, 2.6)
	mist.Transparency = NumberSequence.new(0.6, 1)
	mist.Color = ColorSequence.new(Color3.fromRGB(235, 245, 255))
	mist.Parent = att
	G.Util.prompt(pool, "cascade", "Remplir le seau", "Cascade", { dist = 9 })
	folder.Parent = reg.folder
	reg.cascade = folder
end

function Cascades.onRegionUnload(reg)
	if reg.cascade then
		reg.cascade:Destroy()
		reg.cascade = nil
	end
end

-- Remplir son seau vide à la cascade (comme au bord d'une rivière, Terraforme.fill)
function Cascades.fill(player: Player, prompt: ProximityPrompt)
	local root = G.Util.root(player)
	local pool = prompt and prompt.Parent
	if not root or not pool or not pool:IsA("BasePart") or (root.Position - pool.Position).Magnitude > 14 then
		return false
	end
	if not G.Joueurs.take(player, "bucket_empty", 1) then
		G.Util.toast(player, "🪣 Il te faut un seau vide pour puiser l'eau de la cascade.", "refus")
		return false
	end
	G.Joueurs.add(player, "bucket", 1, true)
	G.Joueurs.sync(player)
	return true
end

return Cascades
