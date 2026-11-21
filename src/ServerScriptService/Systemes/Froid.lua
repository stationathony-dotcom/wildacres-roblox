-- Zones exigeantes (19/11, ses mots : « certains attributs ou tenues pour certaines zones »).
-- Le FROID et la CHALEUR (soif) ont été retirés le 20/11 (décision : pas de survie). Restent :
--   · boue des marais : on s'enlise → bottes, ou Force ≥ STRONG (à cheval : rien) ;
--   · grottes (sous CAVE_Y) : obscurité → une lanterne ou une lampe de mineur dans le sac, ou une torche en main gauche.
-- Effets doux (allure réduite : Game.step lit « Enlise » et « Obscur » ; l'obscurité assombrit l'écran) :
-- ces zones se préparent, elles ne tuent pas. Talent Survivaliste : ni boue ni obscurité.
-- (Le module garde son nom « Froid » pour les appels et les bancs existants.)

local Froid = {}
local G
Froid.CAVE_Y = -80
Froid.STRONG = 8 -- Force qui suffit à se tirer de la boue
local BOOT_WORDS = { "botte", "cuissarde" }
local LIGHT_ITEMS = { "lantern", "miner_lamp", "glow_mushroom" } -- champignon phosphorescent : petite lueur (19/11)
local acc = 0

function Froid.init(g)
	G = g
end

local function wears(player: Player, words): boolean
	local prof = G.Joueurs.get(player)
	-- 20/11 : les bottes ont leur emplacement (« boots ») depuis les 9 emplacements ; les anciens restent lus
	for _, slot in { "boots", "legs", "armor", "hat", "trinket" } do
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
Froid.wears = wears

local function stat(player: Player, k: string): number
	local ok, s = pcall(G.Joueurs.stats, player)
	return ok and s and s[k] or 0
end

local function survivor(player: Player): boolean
	return G.Joueurs.talent ~= nil and G.Joueurs.talent(player, "survivaliste") > 0
end

-- boue des marais : terrain Boue sous les pieds, dans le marais
local ground = RaycastParams.new()
ground.FilterType = Enum.RaycastFilterType.Include
ground.FilterDescendantsInstances = { workspace.Terrain }
function Froid.isStuck(player: Player, pos: Vector3): (boolean, string?)
	if G.Clock.biomeAt(pos) ~= "marais" or player:GetAttribute("Riding") then
		return false, "pas de boue"
	end
	if survivor(player) then
		return false, "survivaliste"
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
	if survivor(player) then
		return false, "survivaliste"
	end
	-- torche tenue en main gauche (emplacement « offhand », lot C7)
	local prof = G.Joueurs.get(player)
	local oh = prof and prof.equipped and prof.equipped.offhand
	if oh and string.find(string.lower(oh.name or ""), "torche", 1, true) then
		return false, "torche"
	end
	for _, it in LIGHT_ITEMS do
		if (G.Joueurs.count(player, it) or 0) > 0 then
			return false, "lumière"
		end
	end
	return true, nil
end

local MSG = {
	Enlise = { "🥾 Tu t'enlises dans la boue : des bottes t'aideraient.", "Tu retrouves un sol ferme." },
	Obscur = { "🌑 Il fait noir : une lanterne, une lampe de mineur ou une torche en main t'éclairerait.", "Tu y vois de nouveau." },
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
			local now = {
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
			-- anciens états (froid / soif, retirés le 20/11) : effacés sans message
			p:SetAttribute("Froid", nil)
			p:SetAttribute("Soif", nil)
		end
	end
end

return Froid
