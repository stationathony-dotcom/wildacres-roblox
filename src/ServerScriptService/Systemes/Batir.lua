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
	local compose = Config.SHAPE_PARTS and Config.SHAPE_PARTS[b.shape]
	if compose then
		-- pièce composée : une racine invisible (visée, reprise, casse) + ses blocs
		p = Instance.new("Part")
		p.Transparency = 1
		p.CanCollide = false
		local cf = cframeOf(d)
		for _, sp in compose(b.size) do
			local c = Config.makeSubPart(sp)
			c.Name = "Bloc"
			c.Anchored = true
			c.CFrame = cf * sp[2]
			c.Material = b.mat
			c.Color = b.color
			c.TopSurface = Enum.SurfaceType.Smooth
			c.BottomSurface = Enum.SurfaceType.Smooth
			if b.transp then
				c.Transparency = b.transp
			end
			-- sous-pièces d'accent (21/11) : poutres / volets en bois sombre, vitre colorée
			if sp[4] == "dark" then
				c.Material = Enum.Material.Wood
				c.Color = Color3.fromRGB(78, 52, 34)
				c.Transparency = 0
			elseif sp[4] == "glass" then
				c.Material = Enum.Material.Glass
				c.Color = b.shape == "stainedwall" and Color3.fromRGB(150, 70, 160) or Color3.fromRGB(190, 225, 240)
				c.Transparency = 0.4
			end
			c:SetAttribute("Built", d.id)
			c:SetAttribute("Owner", d.o)
			c.Parent = p
		end
	elseif b.shape == "wedge" then
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
	if b.transp and not compose then
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
	-- refus : toast de sorte « refus » (lot X16 : l'interface l'affiche près du fantôme)
	if (pos - root.Position).Magnitude > 26 then
		G.Util.toast(player, "Trop loin : approche-toi pour poser.", "refus")
		return
	end
	if d.y < Config.Y_MIN or d.y > Config.Y_MAX + 60 then
		G.Util.toast(player, "Trop haut ou trop bas.", "refus")
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
		G.Util.toast(player, "On ne bâtit pas au milieu d'un village ou d'une ferme.", "refus")
		return
	end
	if not G.Parcelles.canBuild(player, pos) then
		return
	end
	-- même pièce exactement au même endroit : refusé
	reg.state.built = reg.state.built or {}
	for _, o in reg.state.built do
		if o.b == d.b and math.abs(o.x - d.x) < 0.3 and math.abs(o.y - d.y) < 0.3 and math.abs(o.z - d.z) < 0.3 and (o.r or 0) == d.r then
			G.Util.toast(player, "Il y a déjà la même pièce ici.", "refus")
			return
		end
	end
	-- la pièce se fabrique à l'atelier ; ici on en pose une du sac
	if not G.Joueurs.take(player, b.item, 1) then
		G.Util.toast(player, "Plus de « " .. b.name .. " » dans ton sac : fabrique-en à l'atelier.", "refus")
		return
	end
	table.insert(reg.state.built, d)
	makePart(d, folderOf(reg))
	G.Util.sfx("pose", Vector3.new(d.x, d.y, d.z))
	G.Util.geste(player, "batir")
	-- une pièce reprise revient entière : XP de pose plafonnée (150 pièces/jour = une belle maison)
	G.Joueurs.addSkillXpCapped(player, "artisanat", 1, "pose", 150)
	G.Social.bump(player, "built")
	if G.Quetes and rawget(G.Quetes, "note") then G.Quetes.note(player, "batir", "piece") end
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

-- ----------------------------------------------------------------- Plans de construction (18/11)
-- On copie SES pièces autour de soi en un plan (positions relatives à ses pieds et à son regard),
-- on le repose ailleurs dans l'orientation de son regard, on le donne à un autre joueur. Poser un
-- plan ne fait rien gagner : chaque pièce sort du sac, sinon ses matériaux ; s'il manque quoi que ce
-- soit, RIEN n'est posé (tout ou rien) et le joueur sait ce qui lui manque.
-- Limites techniques (taille de la sauvegarde du perso, pas une règle de jeu) : 10 plans, 500 pièces.
local PLAN_MAX, PLAN_PIECES, PLAN_RADIUS = 10, 500, 16
Batir.PLAN_MAX, Batir.PLAN_PIECES = PLAN_MAX, PLAN_PIECES

-- repère du joueur : pieds sur la grille de 0,5, regard arrondi au quart de tour
local function frameOf(root: BasePart): (CFrame, number)
	local look = root.CFrame.LookVector
	local q = math.floor(math.atan2(-look.X, -look.Z) / (math.pi / 2) + 0.5) % 4
	local feet = root.Position - Vector3.new(0, 3, 0)
	local o = Vector3.new(round(feet.X, 0.5), round(feet.Y, 0.5), round(feet.Z, 0.5))
	return CFrame.new(o) * CFrame.Angles(0, math.rad(90 * q), 0), q
end

local function planName(s: any): string?
	if type(s) ~= "string" then
		return nil
	end
	s = string.lower(string.sub(s, 1, 20))
	return string.match(s, "^[%w_%-]+$") and s or nil
end

function Batir.copyPlan(player: Player, name: string, radius: number?): (boolean, string)
	local prof = G.Joueurs.get(player)
	local root = G.Util.root(player)
	name = planName(name)
	if not prof or not root then
		return false, "Impossible pour le moment."
	end
	if not name then
		return false, "Nom de plan : lettres et chiffres seulement (ex. /plan copier maison)."
	end
	prof.plans = prof.plans or {}
	local count = 0
	for _ in prof.plans do
		count += 1
	end
	if not prof.plans[name] and count >= PLAN_MAX then
		return false, "Tu as déjà " .. PLAN_MAX .. " plans : /plan oublier <nom> pour faire de la place."
	end
	radius = math.clamp(tonumber(radius) or 10, 2, PLAN_RADIUS)
	local frame, q = frameOf(root)
	local pieces = {}
	for _, reg in G.World.loaded do
		for _, d in reg.state.built or {} do
			local pos = Vector3.new(d.x, d.y, d.z)
			if G.Util.owns(player, d.o) and (pos - frame.Position).Magnitude <= radius then
				local rel = frame:PointToObjectSpace(pos)
				table.insert(pieces, { b = d.b, x = round(rel.X, 0.5), y = round(rel.Y, 0.5), z = round(rel.Z, 0.5), r = ((d.r or 0) - q) % 4, f = d.f })
				if #pieces > PLAN_PIECES then
					return false, "Trop de pièces pour un seul plan (" .. PLAN_PIECES .. " au plus) : réduis le rayon."
				end
			end
		end
	end
	if #pieces == 0 then
		return false, "Aucune de TES pièces dans un rayon de " .. radius .. " studs."
	end
	prof.plans[name] = { pieces = pieces, by = player.DisplayName, day = G.world.day }
	G.Joueurs.markDirty(player)
	return true, "📐 Plan « " .. name .. " » : " .. #pieces .. " pièces copiées. Pose-le ailleurs avec /plan poser " .. name .. "."
end

function Batir.placePlan(player: Player, name: string): (boolean, string)
	local prof = G.Joueurs.get(player)
	local root = G.Util.root(player)
	name = planName(name)
	local plan = prof and name and prof.plans and prof.plans[name]
	if not plan or not root then
		return false, "Pas de plan de ce nom (/plan liste)."
	end
	local frame, q = frameOf(root)
	-- 1. tout vérifier avant de rien prendre
	local todo, needPieces = {}, {}
	for _, p in plan.pieces do
		local b = blockOf(p.b)
		if not b then
			return false, "Ce plan contient une pièce qui n'existe plus (" .. tostring(p.b) .. ")."
		end
		local w = frame:PointToWorldSpace(Vector3.new(p.x, p.y, p.z))
		local d = {
			id = G.Util.newId("b"), b = p.b, x = round(w.X, 0.5), y = round(w.Y, 0.5), z = round(w.Z, 0.5),
			r = ((p.r or 0) + q) % 4, f = p.f or nil, o = G.Util.pid(player),
		}
		if d.y < Config.Y_MIN or d.y > Config.Y_MAX + 60 then
			return false, "Ici, le plan dépasserait trop haut ou trop bas."
		end
		local pos = Vector3.new(d.x, d.y, d.z)
		local reg = G.World.regionAt(pos)
		if not reg then
			return false, "Le plan déborde sur une région pas encore chargée : rapproche-toi du centre."
		end
		local cx, cz = math.floor(d.x / Config.CELL), math.floor(d.z / Config.CELL)
		if (reg.plan.poiW[G.WG.idx(cx - reg.plan.x0, cz - reg.plan.z0)] or 0) > 0.3 then
			return false, "On ne bâtit pas au milieu d'un village ou d'une ferme."
		end
		if not G.Parcelles.canBuild(player, pos) then
			return false, "Le plan déborde sur un terrain où tu ne peux pas bâtir."
		end
		local dup = false
		for _, o in reg.state.built or {} do
			if o.b == d.b and math.abs(o.x - d.x) < 0.3 and math.abs(o.y - d.y) < 0.3 and math.abs(o.z - d.z) < 0.3 and (o.r or 0) == d.r then
				dup = true -- déjà là (plan reposé au même endroit) : ni posée ni payée
				break
			end
		end
		if not dup then
			table.insert(todo, { d = d, reg = reg })
			needPieces[p.b] = (needPieces[p.b] or 0) + 1
		end
	end
	if #todo == 0 then
		return false, "Tout ce plan est déjà construit ici."
	end
	-- 2. ce que ça coûte : les pièces du sac d'abord, les matériaux pour le reste
	local takePieces, needMat = {}, {}
	for bid, n in needPieces do
		local b = blockOf(bid)
		local have = math.min(n, G.Joueurs.count(player, b.item))
		takePieces[b.item] = have
		for item, k in b.cost or {} do
			needMat[item] = (needMat[item] or 0) + k * (n - have)
		end
	end
	local missing = {}
	for item, n in needMat do
		local short = n - G.Joueurs.count(player, item)
		if short > 0 then
			local info = Config.ITEMS[item]
			table.insert(missing, short .. " " .. (info and info.name or item))
		end
	end
	if #missing > 0 then
		table.sort(missing)
		return false, "Il te manque : " .. table.concat(missing, ", ", 1, math.min(6, #missing)) .. (#missing > 6 and "…" or "") .. ". Rien n'a été posé."
	end
	-- 3. tout prendre (en cas d'échec improbable, on rend ce qui a été pris)
	local taken = {}
	local function refund()
		for item, n in taken do
			G.Joueurs.add(player, item, n, true)
		end
	end
	for item, n in takePieces do
		if n > 0 then
			if not G.Joueurs.take(player, item, n) then
				refund()
				return false, "Ton sac a changé pendant la pose : réessaie."
			end
			taken[item] = (taken[item] or 0) + n
		end
	end
	for item, n in needMat do
		if n > 0 then
			if not G.Joueurs.take(player, item, n) then
				refund()
				return false, "Ton sac a changé pendant la pose : réessaie."
			end
			taken[item] = (taken[item] or 0) + n
		end
	end
	-- 4. poser (par paquets : une grande maison ne fige pas le serveur)
	for i, t in todo do
		t.reg.state.built = t.reg.state.built or {}
		table.insert(t.reg.state.built, t.d)
		makePart(t.d, folderOf(t.reg))
		if i % 60 == 0 then
			task.wait()
		end
	end
	G.Joueurs.addSkillXpCapped(player, "artisanat", #todo, "pose", 150)
	G.Joueurs.sync(player)
	G.Util.sfx("pose", frame.Position)
	return true, "🏗️ Plan « " .. name .. " » posé : " .. #todo .. " pièces."
end

function Batir.givePlan(player: Player, name: string, target: Player): (boolean, string)
	local prof, tprof = G.Joueurs.get(player), G.Joueurs.get(target)
	name = planName(name)
	local plan = prof and name and prof.plans and prof.plans[name]
	if not plan then
		return false, "Pas de plan de ce nom (/plan liste)."
	end
	if not tprof or target == player then
		return false, "Ce joueur n'est pas là."
	end
	if G.Admin and G.Admin.blocks and G.Admin.blocks(target, player) then
		return false, target.DisplayName .. " ne reçoit rien de toi."
	end
	tprof.plans = tprof.plans or {}
	local count = 0
	for _ in tprof.plans do
		count += 1
	end
	local tname = name
	local k = 2
	while tprof.plans[tname] do
		tname = string.sub(name, 1, 17) .. "_" .. k
		k += 1
	end
	if count >= PLAN_MAX then
		return false, target.DisplayName .. " a déjà " .. PLAN_MAX .. " plans."
	end
	tprof.plans[tname] = { pieces = table.clone(plan.pieces), by = plan.by or player.DisplayName, day = G.world.day }
	G.Joueurs.markDirty(target)
	G.Util.toast(target, "📐 " .. player.DisplayName .. " t'offre son plan « " .. tname .. " » (" .. #plan.pieces .. " pièces) : /plan poser " .. tname, "gain")
	return true, "📐 Plan « " .. name .. " » donné à " .. target.DisplayName .. "."
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
		G.Util.sfx("casse", pos)
		if p then
			p:Destroy()
		end
		parts[best] = nil
		hits[best] = nil
	end
	return true
end

return Batir
