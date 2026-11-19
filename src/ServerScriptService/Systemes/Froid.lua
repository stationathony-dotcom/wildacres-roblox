-- Froid (19/11, « listes ennemi.txt » § 11 : températures) : dans la neige, la nuit, on a froid
-- sauf si l'on se réchauffe. Une source de chaleur suffit :
--   · un feu tout près (feu de camp, cheminée, braséro, torche murale posés, à moins de WARM_R studs) ;
--   · un toit au-dessus de la tête (on est à l'abri dans une maison) ;
--   · un vêtement chaud porté (fourrure, laine, peau, manteau, pelisse, cape : selon le nom de la pièce).
-- Avoir froid : on marche et on court moins vite (Game.step lit l'attribut « Froid ») et l'endurance
-- revient deux fois moins vite. Rien de mortel : c'est une difficulté du biome, pas une punition.
-- Chaleur (même module) : dans le désert, en plein jour (HEAT_FROM h à HEAT_TO h), sans toit ni
-- ombre au-dessus de la tête, on a soif — mêmes effets — sauf si l'on a bu (gourde, outre) depuis
-- moins de DRINK_S secondes (attribut « Desaltere » posé par Joueurs).

-- Zones exigeantes (19/11, ses mots : « certains attributs ou tenues pour certaines zones ») :
--   · neige la nuit et SOMMETS (au-dessus de PEAK_Y) : froid → tenue chaude, feu, abri, ou Vie ≥ TOUGH ;
--   · désert en plein jour : chaleur → tenue légère (paille, lin, turban, voile), boire, ombre, ou Vie ≥ TOUGH ;
--   · boue des marais : on s'enlise → bottes, ou Force ≥ STRONG (à cheval : rien) ;
--   · grottes (sous CAVE_Y) : obscurité → une lanterne ou une lampe de mineur dans le sac.
-- Effets doux (allure réduite, endurance plus lente, l'obscurité assombrit l'écran) : ces zones se
-- préparent, elles ne tuent pas. Talent Survivaliste : ni froid ni chaleur.

local Froid = {}
local G
Froid.PEAK_Y = 30 -- studs (le sol des crêtes monte à ~29 : on est debout dessus)
Froid.CAVE_Y = -80
Froid.TOUGH = 10 -- Vie (caractéristique) qui suffit à endurer froid et chaleur
Froid.STRONG = 8 -- Force qui suffit à se tirer de la boue
local LIGHT_WORDS = { "paille", "lin", "turban", "voile" }
local BOOT_WORDS = { "botte", "cuissarde" }
local LIGHT_ITEMS = { "lantern", "miner_lamp" }

Froid.WARM_R = 14
local FIRES = { campfire = true, fireplace = true, brazier = true, wall_torch = true }
local WARM_WORDS = { "fourrure", "laine", "peau", "manteau", "pelisse", "cape", "polaire" }
local acc = 0
local roof = RaycastParams.new()
roof.FilterType = Enum.RaycastFilterType.Exclude

function Froid.init(g)
	G = g
end

local function wears(player: Player, words): boolean
	local prof = G.Joueurs.get(player)
	for _, slot in { "armor", "hat", "trinket" } do
		local it = prof and prof.equipped and prof.equipped[slot]
		local name = it and string.lower(it.name or "") or ""
		for _, w in words do
			if string.find(name, w, 1, true) then
				return true
			end
		end
	end
	return false
end
local function warmGear(player: Player): boolean
	return wears(player, WARM_WORDS)
end
local function stat(player: Player, k: string): number
	local ok, s = pcall(G.Joueurs.stats, player)
	return ok and s and s[k] or 0
end
Froid.wears = wears

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
	if G.Joueurs.talent and G.Joueurs.talent(player, "survivaliste") > 0 then
		return false, "survivaliste"
	end
	local night = G.Clock.isNight()
	local biome = G.Clock.biomeAt(pos)
	local peak = pos.Y >= Froid.PEAK_Y and (night or biome == "neige")
	if not peak and (biome ~= "neige" or not night) then
		return false, "pas de froid ici"
	end
	if stat(player, "vie") >= Froid.TOUGH then
		return false, "robuste"
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

Froid.HEAT_FROM, Froid.HEAT_TO = 11, 17
Froid.DRINK_S = 300
function Froid.isHot(player: Player, pos: Vector3): (boolean, string?)
	if G.Joueurs.talent and G.Joueurs.talent(player, "survivaliste") > 0 then
		return false, "survivaliste"
	end
	if G.Clock.biomeAt(pos) ~= "desert" or G.Clock.isNight() then
		return false, "pas de chaleur ici"
	end
	local h = G.Clock.hour and G.Clock.hour() or 12
	if h < Froid.HEAT_FROM or h >= Froid.HEAT_TO then
		return false, "heure fraîche"
	end
	if (player:GetAttribute("Desaltere") or 0) > os.clock() then
		return false, "désaltéré"
	end
	if wears(player, LIGHT_WORDS) then
		return false, "tenue légère"
	end
	if stat(player, "vie") >= Froid.TOUGH then
		return false, "robuste"
	end
	if underRoof(player, pos) then
		return false, "ombre"
	end
	return true, nil
end

-- boue des marais : terrain Boue sous les pieds, dans le marais
local ground = RaycastParams.new()
ground.FilterType = Enum.RaycastFilterType.Include
ground.FilterDescendantsInstances = { workspace.Terrain }
function Froid.isStuck(player: Player, pos: Vector3): (boolean, string?)
	if G.Clock.biomeAt(pos) ~= "marais" or player:GetAttribute("Riding") then
		return false, "pas de boue"
	end
	local r = workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, -8, 0), ground)
	if not r or r.Material ~= Enum.Material.Mud then
		return false, "sol ferme"
	end
	if wears(player, BOOT_WORDS) then
		return false, "bottes"
	end
	if stat(player, "force") >= Froid.STRONG then
		return false, "fort"
	end
	return true, nil
end

-- grottes : sans lumière dans le sac, on y voit mal
function Froid.isDark(player: Player, pos: Vector3): (boolean, string?)
	if pos.Y > Froid.CAVE_Y then
		return false, "à l'air libre"
	end
	for _, it in LIGHT_ITEMS do
		if (G.Joueurs.count(player, it) or 0) > 0 then
			return false, "lumière"
		end
	end
	return true, nil
end

local MSG = {
	Froid = { "🥶 Il gèle : sans feu, abri ni vêtement chaud, tu avances moins vite.", "Tu te réchauffes." },
	Soif = { "🥵 Quelle chaleur : sans ombre, eau ni tenue légère (paille, lin), tu avances moins vite.", "Tu reprends ton souffle." },
	Enlise = { "🥾 Tu t'enlises dans la boue : des bottes t'aideraient.", "Tu retrouves un sol ferme." },
	Obscur = { "🌑 Il fait noir : une lanterne ou une lampe de mineur dans le sac t'éclairerait.", "Tu y vois de nouveau." },
}

function Froid.step(dt: number)
	acc += dt
	if acc < 3 then
		return
	end
	acc = 0
	for _, p in G.Game.players() do
		local root = G.Util.root(p)
		if root then
			local pos = root.Position
			local cold = Froid.isCold(p, pos)
			local now = {
				Froid = cold,
				Soif = (not cold) and Froid.isHot(p, pos),
				Enlise = Froid.isStuck(p, pos),
				Obscur = Froid.isDark(p, pos),
			}
			for k, v in now do
				local was = p:GetAttribute(k) == true
				if v ~= was then
					G.Util.toast(p, v and MSG[k][1] or MSG[k][2], v and "danger" or nil)
				end
				p:SetAttribute(k, v or nil)
			end
		end
	end
end

return Froid
