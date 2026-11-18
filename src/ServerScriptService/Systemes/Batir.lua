-- Construction libre (bac à sable, façon Minecraft mais pas que des cubes) : on pose des pièces
-- (dalles, pans de mur, poutres, piliers, pentes, coins, vitres, barrières…) n'importe où et à
-- n'importe quelle hauteur, en les accrochant aux surfaces. Aucune maison prédéfinie.
--  · Chaque pièce se fabrique à l'atelier (objet blk_…) puis se pose depuis la main.
--  · Interdit sur la parcelle d'un autre (sauf même clan) et dans les villages.
--  · Le propriétaire reprend ses pièces (elles reviennent dans le sac) ; un autre peut les CASSER à la pioche ou à
--    la hache (long : bois 4 coups, pierre 8, brique 10) — sur une parcelle, c'est une effraction.
-- État : reg.state.built = { {id, b, x, y, z, r, f, o} } (b = pièce, r = rotation en quarts, f = retournée)

local Batir = {}
local G, Config
local hits = {} -- id de pièce -> coups reçus
local parts = {} -- id -> Part

function Batir.init(g)
	G = g
	Config = G.Config
	G.Interact.onAction("build_place", function(player, data)
		Batir.place(player, data)
	end)
	G.Interact.onAction("build_remove", function(player, data)
		Batir.remove(player, data.id)
	end)
end

local function blockOf(id: string)
	return Config.BLOCKS[id]
end

local function cframeOf(d)
	local cf = CFrame.new(d.x, d.y, d.z) * CFrame.Angles(0, math.rad(90 * (d.r or 0)), 0)
	if d.f then
		cf *= CFrame.Angles(0, 0, math.pi)
	end
	return cf
end

local function makePart(d, parent: Instance)
	local b = blockOf(d.b)
	if not b then
		return nil
	end
	local p
	if b.shape == "wedge" then
		p = Instance.new("WedgePart")
	elseif b.shape == "corner" then
		p = Instance.new("CornerWedgePart")
	elseif b.shape == "ladder" then
		p = Instance.new("TrussPart") -- grimpable nativement
		p.Style = Enum.Style.AlternatingSupports
	else
		p = Instance.new("Part")
		if b.shape == "pillar" then
			p.Shape = Enum.PartType.Cylinder
		end
	end
	local size = b.size
	if b.shape == "pillar" then
		size = Vector3.new(size.Y, size.X, size.Z) -- un cylindre est couché sur X : on le redresse
	end
	p.Size = size
	local cf = cframeOf(d)
	if b.shape == "pillar" then
		cf *= CFrame.Angles(0, 0, math.rad(90))
	end
	p.CFrame = cf
	p.Anchored = true
	p.Material = b.mat
	p.Color = b.color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if b.transp then
		p.Transparency = b.transp
	end
	p.Name = "Piece"
	p:SetAttribute("Built", d.id)
	p:SetAttribute("Owner", d.o)
	p.Parent = parent
	parts[d.id] = p
	return p
end

local function folderOf(reg)
	local f = reg.folder:FindFirstChild("Constructions")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Constructions"
		f.Parent = reg.folder
	end
	return f
end

function Batir.onRegionLoad(reg)
	reg.state.built = reg.state.built or {}
	local f = folderOf(reg)
	for i, d in reg.state.built do
		makePart(d, f)
		if i % 200 == 0 then
			task.wait()
		end
	end
end

function Batir.onRegionUnload(reg)
	for _, d in reg.state.built or {} do
		parts[d.id] = nil
		hits[d.id] = nil
	end
end

local function round(v: number, step: number): number
	return math.floor(v / step + 0.5) * step
end

-- Pose d'une pièce : le client propose, le serveur vérifie tout
function Batir.place(player: Player, data)
	local b = type(data.b) == "string" and blockOf(data.b)
	local root = G.Util.root(player)
	if not b or not root or type(data.x) ~= "number" or type(data.y) ~= "number" or type(data.z) ~= "number" then
		return
	end
	local d = {
		id = G.Util.newId("b"), b = data.b,
		x = round(data.x, 0.5), y = round(data.y, 0.5), z = round(data.z, 0.5),
		r = math.clamp(math.floor(tonumber(data.r) or 0), 0, 3), f = data.f == true or nil, o = G.Util.pid(player),
	}
	local pos = Vector3.new(d.x, d.y, d.z)
	if (pos - root.Position).Magnitude > 26 then
		return
	end
	if d.y < Config.Y_MIN or d.y > Config.Y_MAX + 60 then
		G.Util.toast(player, "Trop haut ou trop bas.")
		return
	end
	local reg = G.World.regionAt(pos)
	if not reg then
		return
	end
	-- pas dans les villages ni chez les autres
	local cx, cz = math.floor(d.x / Config.CELL), math.floor(d.z / Config.CELL)
	local i = G.WG.idx(cx - reg.plan.x0, cz - reg.plan.z0)
	if (reg.plan.poiW[i] or 0) > 0.3 then
		G.Util.toast(player, "On ne bâtit pas au milieu d'un village ou d'une ferme.")
		return
	end
	if not G.Parcelles.canBuild(player, pos) then
		return
	end
	-- même pièce exactement au même endroit : refusé
	reg.state.built = reg.state.built or {}
	for _, o in reg.state.built do
		if o.b == d.b and math.abs(o.x - d.x) < 0.3 and math.abs(o.y - d.y) < 0.3 and math.abs(o.z - d.z) < 0.3 and (o.r or 0) == d.r then
			return
		end
	end
	-- la pièce se fabrique à l'atelier ; ici on en pose une du sac
	if not G.Joueurs.take(player, b.item, 1) then
		G.Util.toast(player, "Plus de « " .. b.name .. " » dans ton sac : fabrique-en à l'atelier.")
		return
	end
	table.insert(reg.state.built, d)
	makePart(d, folderOf(reg))
	-- une pièce reprise revient entière : XP de pose plafonnée (150 pièces/jour = une belle maison)
	G.Joueurs.addSkillXpCapped(player, "artisanat", 1, "pose", 150)
	G.Joueurs.sync(player)
end

local function find(id: string)
	for _, reg in G.World.loaded do
		for i, d in reg.state.built or {} do
			if d.id == id then
				return d, reg, i
			end
		end
	end
	return nil, nil, nil
end

-- Reprendre sa pièce (moitié des matériaux rendue)
function Batir.remove(player: Player, id: string)
	local d, reg, i = find(id)
	local root = G.Util.root(player)
	if not d or not root or (Vector3.new(d.x, d.y, d.z) - root.Position).Magnitude > 26 then
		return
	end
	if not G.Util.owns(player, d.o) then
		G.Util.toast(player, "Ce n'est pas à toi. (Pour passer, il faudra casser : pioche ou hache.)")
		return
	end
	table.remove(reg.state.built, i)
	if parts[id] then
		parts[id]:Destroy()
		parts[id] = nil
	end
	-- sa propre pièce rend ses matériaux (18/11 : avant, rien ne revenait — `b.item` n'existe pas)
	local b = blockOf(d.b)
	for item, n in (b and b.cost) or {} do
		G.Joueurs.add(player, item, n, true)
	end
	G.Joueurs.sync(player)
end

-- Démonter en lot (18/11) : toutes SES pièces dans un rayon autour de soi (12 studs au plus)
function Batir.removeAround(player: Player, radius: number): number
	local root = G.Util.root(player)
	if not root then
		return 0
	end
	radius = math.clamp(radius, 1, 12)
	local ids = {}
	for _, reg in G.World.loaded do
		for _, d in reg.state.built or {} do
			if G.Util.owns(player, d.o) and (Vector3.new(d.x, d.y, d.z) - root.Position).Magnitude <= radius then
				table.insert(ids, d.id)
			end
		end
	end
	for _, id in ids do
		Batir.remove(player, id)
	end
	return #ids
end

-- Casser la pièce d'un autre (cambriolage, démolition) : coups de pioche / hache
function Batir.smash(player: Player, tool: string): boolean
	local root = G.Util.root(player)
	if not root then
		return false
	end
	local best, bd = nil, 7
	for id, p in parts do
		if p.Parent then
			local dist = (p.Position - root.Position).Magnitude - math.max(p.Size.X, p.Size.Z) / 2
			if dist < bd and root.CFrame.LookVector:Dot((p.Position - root.Position).Unit) > 0.2 then
				best, bd = id, dist
			end
		end
	end
	if not best then
		return false
	end
	local d, reg, i = find(best)
	if not d then
		return false
	end
	if G.Util.owns(player, d.o) then
		return false -- chez soi : on reprend en mode construction
	end
	local b = blockOf(d.b)
	local _, tier = G.Joueurs.bestTool(player, tool)
	hits[best] = (hits[best] or 0) + math.max(1, tier)
	G.Props.swing(player, tool)
	local p = parts[best]
	if p then
		G.Combat.popup(p.Position, (hits[best]) .. "/" .. (b and b.hp or 4), Color3.fromRGB(230, 200, 150))
	end
	if hits[best] >= (b and b.hp or 4) then
		local pos = Vector3.new(d.x, d.y, d.z)
		if G.Parcelles.at(pos) == d.o then
			G.Law.crime(player, "breakin", pos, d.o)
			G.Protection.log(d.o, player.DisplayName .. " a cassé un mur de ta maison.", false)
		end
		table.remove(reg.state.built, i)
		if p then
			p:Destroy()
		end
		parts[best] = nil
		hits[best] = nil
	end
	return true
end

return Batir
