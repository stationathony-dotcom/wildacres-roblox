-- Froid (19/11, « listes ennemi.txt » § 11 : températures) : dans la neige, la nuit, on a froid
-- sauf si l'on se réchauffe. Une source de chaleur suffit :
--   · un feu tout près (feu de camp, cheminée, braséro, torche murale posés, à moins de WARM_R studs) ;
--   · un toit au-dessus de la tête (on est à l'abri dans une maison) ;
--   · un vêtement chaud porté (fourrure, laine, peau, manteau, pelisse, cape : selon le nom de la pièce).
-- Avoir froid : on marche et on court moins vite (Game.step lit l'attribut « Froid ») et l'endurance
-- revient deux fois moins vite. Rien de mortel : c'est une difficulté du biome, pas une punition.

local Froid = {}
local G

Froid.WARM_R = 14
local FIRES = { campfire = true, fireplace = true, brazier = true, wall_torch = true }
local WARM_WORDS = { "fourrure", "laine", "peau", "manteau", "pelisse", "cape", "polaire" }
local acc = 0
local roof = RaycastParams.new()
roof.FilterType = Enum.RaycastFilterType.Exclude

function Froid.init(g)
	G = g
end

local function warmGear(player: Player): boolean
	local prof = G.Joueurs.get(player)
	for _, slot in { "armor", "hat", "trinket" } do
		local it = prof and prof.equipped and prof.equipped[slot]
		local name = it and string.lower(it.name or "") or ""
		for _, w in WARM_WORDS do
			if string.find(name, w, 1, true) then
				return true
			end
		end
	end
	return false
end

local function nearFire(pos: Vector3): boolean
	for _, reg in G.World.loaded do
		for _, d in reg.state.placed or {} do
			if FIRES[d.item] and math.abs(d.x - pos.X) < Froid.WARM_R and math.abs(d.z - pos.Z) < Froid.WARM_R then
				return true
			end
		end
	end
	return false
end

local function underRoof(player: Player, pos: Vector3): boolean
	roof.FilterDescendantsInstances = { player.Character }
	local r = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, 14, 0), roof)
	return r ~= nil and r.Instance ~= workspace.Terrain
end

-- a-t-il froid à cette position ? (renvoie aussi la raison de la chaleur, pour les tests)
function Froid.isCold(player: Player, pos: Vector3): (boolean, string?)
	if G.Clock.biomeAt(pos) ~= "neige" or not G.Clock.isNight() then
		return false, "pas de froid ici"
	end
	if nearFire(pos) then
		return false, "feu"
	end
	if warmGear(player) then
		return false, "vêtement chaud"
	end
	if underRoof(player, pos) then
		return false, "abri"
	end
	return true, nil
end

function Froid.step(dt: number)
	acc += dt
	if acc < 3 then
		return
	end
	acc = 0
	for _, p in G.Game.players() do
		local root = G.Util.root(p)
		if root then
			local cold = Froid.isCold(p, root.Position)
			local was = p:GetAttribute("Froid") == true
			if cold ~= was then
				p:SetAttribute("Froid", cold or nil)
				G.Util.toast(p, cold and "🥶 Il gèle : sans feu, abri ni vêtement chaud, tu avances moins vite." or "Tu te réchauffes.", cold and "danger" or nil)
			end
		end
	end
end

return Froid
