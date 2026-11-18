-- Terrassement (bac à sable) : sur SES terres (ou celles de son clan), on creuse, on remblaie, on crée
-- des étangs. Chaque case garde son décalage (en couches de 4 studs) dans l'état de la région :
-- reg.state.terra["cx,cz"] = { d = -3..3, w = true si de l'eau y a été versée }.
-- Le relief modifié est réappliqué au chargement (World.writeTerrain) et pris en compte par groundY.

local Terraforme = {}
local G, Config
local Mat = Enum.Material
local LAYER = 4
-- creuser puis remblayer la même case ne coûte rien : l'XP du terrassement est donc plafonnée par
-- jour (sinon une boucle creuse/remblaie monterait l'agriculture à l'infini)
local XP_PER_DAY = 25

function Terraforme.init(g)
	G = g
	Config = G.Config
end

local function key(cx: number, cz: number): string
	return cx .. "," .. cz
end

-- Décalage d'une case (région chargée seulement), en couches
function Terraforme.cell(cx: number, cz: number)
	local rx, rz = G.WG.regionOf(cx, cz)
	local reg = G.World.loaded[rx .. "," .. rz]
	local t = reg and reg.state.terra
	return t and t[key(cx, cz)] or nil
end

-- Hauteur d'origine (plan) d'une case
local function baseHeight(cx: number, cz: number): (number, any)
	local rx, rz = G.WG.regionOf(cx, cz)
	local plan = G.wg.planCache[rx .. "," .. rz] or G.wg:plan(rx, rz)
	local i = G.WG.idx(cx - plan.x0, cz - plan.z0)
	return plan.H[i], plan.mat[i]
end

-- Réécrit les voxels d'une case selon son décalage
local function redraw(cx: number, cz: number, t)
	local terrain = workspace.Terrain
	local h0, top = baseHeight(cx, cz)
	local h = h0 + (t and t.d or 0) * LAYER
	local x, z = cx * Config.CELL + Config.CELL / 2, cz * Config.CELL + Config.CELL / 2
	local size = Config.CELL
	-- colonne vidée puis reconstruite : sous-sol, couche de surface, eau éventuelle
	local yMin, yMax = Config.Y_MIN, Config.Y_MAX
	terrain:FillBlock(CFrame.new(x, (yMin + yMax) / 2, z), Vector3.new(size, yMax - yMin, size), Mat.Air)
	if h - yMin > 0.5 then
		local soilTop = math.max(yMin + 1, h - LAYER)
		terrain:FillBlock(CFrame.new(x, (yMin + soilTop) / 2, z), Vector3.new(size, soilTop - yMin, size), Mat.Ground)
		terrain:FillBlock(CFrame.new(x, (soilTop + h) / 2, z), Vector3.new(size, math.max(0.5, h - soilTop), size), (t and t.d < 0) and Mat.Ground or (top or Mat.Grass))
	end
	if t and t.w and h < h0 then
		terrain:FillBlock(CFrame.new(x, (h + h0 - 0.6) / 2, z), Vector3.new(size, math.max(0.5, h0 - 0.6 - h), size), Mat.Water)
	end
end
Terraforme.redraw = redraw

-- Après l'écriture du terrain d'une région : réapplique ses modifications
function Terraforme.applyRegion(reg)
	for k, t in reg.state.terra or {} do
		local cx, cz = string.match(k, "^(-?%d+),(-?%d+)$")
		if cx then
			redraw(tonumber(cx) :: number, tonumber(cz) :: number, t)
		end
	end
end

local function target(player: Player): (number?, number?, any)
	local root = G.Util.root(player)
	if not root then
		return nil, nil, nil
	end
	local look = root.CFrame.LookVector
	local p = root.Position + Vector3.new(look.X, 0, look.Z).Unit * 5
	local cx, cz = math.floor(p.X / Config.CELL), math.floor(p.Z / Config.CELL)
	local rx, rz = G.WG.regionOf(cx, cz)
	return cx, cz, G.World.loaded[rx .. "," .. rz]
end

local function allowed(player: Player, cx: number, cz: number): boolean
	local x, z = cx * Config.CELL + Config.CELL / 2, cz * Config.CELL + Config.CELL / 2
	local pos = Vector3.new(x, 0, z)
	if Config.LIBRE.terrasserPartout then
		return true -- monde libre : on creuse où l'on veut
	end
	local owner = G.Parcelles.at(pos)
	if not owner then
		G.Util.toast(player, "On ne terrasse que sur ses terres (panneau de propriété), pas sur les terres communes.")
		return false
	end
	return G.Parcelles.canBuild(player, pos)
end

-- Bêche de terrassier : creuser (debout) ou remblayer (accroupi)
function Terraforme.use(player: Player)
	local cx, cz, reg = target(player)
	if not cx or not reg or not allowed(player, cx, cz) then
		return
	end
	reg.state.terra = reg.state.terra or {}
	local k = key(cx, cz)
	local t = reg.state.terra[k] or { d = 0 }
	local raise = player:GetAttribute("Crouch") == true
	if raise then
		if t.d >= 3 then
			G.Util.toast(player, "Plus haut, ça s'effondrerait.")
			return
		end
		if not G.Joueurs.take(player, "dirt", 2) then
			G.Util.toast(player, "Il faut 2 terre pour remblayer (creuse ailleurs pour en avoir).")
			return
		end
		t.d += 1
		t.w = nil
	else
		local h0 = baseHeight(cx, cz)
		if t.d <= -3 or h0 + (t.d - 1) * LAYER <= Config.Y_MIN + 2 then
			G.Util.toast(player, "Tu touches la roche, impossible de creuser plus.")
			return
		end
		t.d -= 1
		local x, z = cx * Config.CELL + Config.CELL / 2, cz * Config.CELL + Config.CELL / 2
		local root = G.Util.root(player)
		-- la terre sort du trou et tombe à côté (ramassage : Systemes/Butin)
		G.Util.auSol(player, Vector3.new(x, root and root.Position.Y or 0, z), nil, function()
			G.Joueurs.add(player, G.Clock.biomeAt(Vector3.new(x, 0, z)) == "desert" and "sand" or "dirt", 2, true)
			if math.random() < 0.12 then
				G.Joueurs.add(player, math.random() < 0.5 and "clay" or "stone", 1, true)
			end
			G.Util.finds(player, "dig", Vector3.new(x, 0, z))
		end)
	end
	reg.state.terra[k] = (t.d ~= 0 or t.w) and t or nil
	G.Props.swing(player, "shovel")
	redraw(cx, cz, reg.state.terra[k])
	G.Joueurs.addSkillXpCapped(player, "agriculture", 1, "terrasse", XP_PER_DAY)
	G.Joueurs.sync(player)
end

-- Seau d'eau : remplit un trou creusé (étang)
function Terraforme.bucket(player: Player)
	local cx, cz, reg = target(player)
	if not cx or not reg or not allowed(player, cx, cz) then
		return
	end
	local k = key(cx, cz)
	local t = reg.state.terra and reg.state.terra[k]
	if not t or t.d >= 0 then
		G.Util.toast(player, "Verse l'eau dans un trou creusé.")
		return
	end
	if t.w then
		return
	end
	if not G.Joueurs.take(player, "bucket", 1) then
		return
	end
	t.w = true
	redraw(cx, cz, t)
	G.Joueurs.add(player, "bucket_empty", 1, true)
	G.Joueurs.sync(player)
end

-- Seau vide : on le remplit face à de l'eau (rivière, lac, étang)
function Terraforme.fill(player: Player)
	local root = G.Util.root(player)
	if not root then
		return
	end
	local look = root.CFrame.LookVector
	local p = root.Position + Vector3.new(look.X, 0, look.Z).Unit * 5
	if not G.Util.isWater(p.X, p.Z) then
		G.Util.toast(player, "Approche-toi de l'eau pour remplir le seau.")
		return
	end
	if G.Joueurs.take(player, "bucket_empty", 1) then
		G.Joueurs.add(player, "bucket", 1, true)
		G.Joueurs.sync(player)
	end
end

-- Restauration (admin, ou propriétaire sur ses terres) : remet le relief d'origine dans un rayon
-- (en cases). Sert après un bug ou un terrassement abusif ; les étangs sont vidés. Renvoie le nombre
-- de cases remises à plat.
function Terraforme.restore(pos: Vector3, radius: number, filter: ((number, number) -> boolean)?): number
	local c0x, c0z = math.floor(pos.X / Config.CELL), math.floor(pos.Z / Config.CELL)
	local r = math.clamp(math.floor(radius), 0, 12)
	local n = 0
	for cx = c0x - r, c0x + r do
		for cz = c0z - r, c0z + r do
			local rx, rz = G.WG.regionOf(cx, cz)
			local reg = G.World.loaded[rx .. "," .. rz]
			local t = reg and reg.state.terra
			local k = key(cx, cz)
			if t and t[k] and (not filter or filter(cx, cz)) then
				t[k] = nil
				redraw(cx, cz, nil)
				n += 1
			end
		end
	end
	return n
end

return Terraforme
