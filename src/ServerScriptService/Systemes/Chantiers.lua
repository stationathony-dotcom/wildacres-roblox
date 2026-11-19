-- Chantiers de village (19/11, liste quetes.txt § 31 « plusieurs joueurs contribuent à une construction »,
-- « participer à la rénovation d'un village entier »). Chaque village mène UN chantier commun à la fois ;
-- au tableau des quêtes (Systemes/Quetes), une offre « Chantier » demande d'apporter une part (20 à 40
-- unités de la matière qui manque le plus). L'avancée est commune à tous les joueurs du monde. Chantier
-- terminé = bénéfice durable pour le village, puis le chantier suivant commence.
--   · marche : on vend 5 % plus cher dans ce village (Shop.sellPrice) ;
--   · palissade : les invasions de nuit y arrivent moins nombreuses (Evenements.startInvasion) ;
-- État : G.world.chantiers[clé du village] = { i = n° du chantier, have = { [matière] = n }, done = { [id] = jour } }.

local Chantiers = {}
local G, Config

Chantiers.PROJECTS = {
	{ id = "marche", name = "agrandir le marché", needs = { planks = 300, stone = 200, cloth = 60 }, done = "Le marché est agrandi : on y vend 5 % plus cher." },
	{ id = "palissade", name = "renforcer la palissade", needs = { wood = 400, rope = 80, iron_ingot = 40 }, done = "La palissade est renforcée : les assaillants y seront moins nombreux." },
}

local function state(vkey: string)
	G.world.chantiers = G.world.chantiers or {}
	local s = G.world.chantiers[vkey]
	if not s then
		s = { i = 1, have = {}, done = {} }
		G.world.chantiers[vkey] = s
	end
	return s
end

-- le chantier en cours (nil quand tous sont faits)
local function current(vkey: string)
	local s = state(vkey)
	return Chantiers.PROJECTS[s.i], s
end

function Chantiers.built(vkey: string?, id: string): boolean
	if not vkey or not G.world or not G.world.chantiers then
		return false
	end
	local s = G.world.chantiers[vkey]
	return s ~= nil and s.done[id] ~= nil
end

-- matière qui manque le plus (en proportion)
local function neediest(p, s): (string?, number)
	local best, bestLeft, ratio = nil, 0, -1
	for item, need in p.needs do
		local left = need - (s.have[item] or 0)
		if left > 0 and Config.ITEMS[item] then
			local r = left / need
			if r > ratio then
				best, bestLeft, ratio = item, left, r
			end
		end
	end
	return best, bestLeft
end

-- offre du tableau (appelée par Quetes.offers) : une part à apporter, une fois par période et par joueur
function Chantiers.offer(v, period: number)
	local p, s = current(v.key)
	if not p then
		return nil
	end
	local item, left = neediest(p, s)
	if not item then
		return nil
	end
	local rng = Random.new(G.WG.hash(G.world.seed, "chantier", v.key, period, s.i))
	local n = math.min(left, rng:NextInteger(20, 40))
	local info = Config.ITEMS[item]
	local total, have = 0, 0
	for it, need in p.needs do
		total += need
		have += math.min(need, s.have[it] or 0)
	end
	local gold = math.floor(5 + (info.price or 2) * n * 0.5)
	return {
		id = v.key .. ":" .. period .. ":chantier" .. s.i, v = v.key, vname = v.name,
		kind = "apporter", key = item, need = n, chantier = p.id,
		title = string.format("Chantier : %s (%d %%)", p.name, math.floor(have / total * 100)),
		gold = gold, xp = 10 + math.floor(gold / 4),
	}
end

-- part rendue (appelée par Quetes.turnIn) : la matière rejoint le chantier commun
function Chantiers.contribute(player: Player, q, here)
	if not (q and q.chantier) then
		return
	end
	local p, s = current(q.v)
	if not p or p.id ~= q.chantier then
		return -- chantier déjà terminé entre-temps : la part reste payée
	end
	s.have[q.key] = (s.have[q.key] or 0) + q.need
	G.Reputation.add(player, here, 3) -- le village s'en souvient
	for item, need in p.needs do
		if (s.have[item] or 0) < need then
			return
		end
	end
	-- terminé
	s.done[p.id] = G.world.day
	s.i += 1
	s.have = {}
	local v = here
	for _, other in G.Game.players() do
		local r = G.Util.root(other)
		if r and v and Vector2.new(r.Position.X - v.x, r.Position.Z - v.z).Magnitude < 200 then
			G.Util.toast(other, "🏗️ " .. (v.name or "Le village") .. " : " .. p.done, "big")
		end
	end
end

-- bonus de vente dans un village au marché agrandi (Shop.sellPrice)
function Chantiers.sellMult(vkey: string?): number
	return Chantiers.built(vkey, "marche") and 1.05 or 1
end

-- taille d'une vague d'invasion (Evenements.startInvasion)
function Chantiers.waveMult(vkey: string?): number
	return Chantiers.built(vkey, "palissade") and 0.6 or 1
end

function Chantiers.init(g)
	G = g
	Config = G.Config
end

return Chantiers
