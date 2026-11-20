-- Banc des chantiers de village (Systemes/Chantiers). Mode Edit, sans Play, faux monde.
local Ch = assert(loadstring(game.ServerScriptService.Systemes.Chantiers.Source))()
local G = {
	world = { day = 3, seed = 7 },
	Config = { CELL = 4, ITEMS = { planks = { price = 4 }, stone = { price = 2 }, cloth = { price = 25 }, wood = { price = 2 }, rope = { price = 5 },
		iron_ingot = { price = 45 }, lantern = { price = 30 }, glass = { price = 12 }, clay = { price = 4 } } },
	WG = { hash = function(...) return 42 end },
	Reputation = { add = function() end, villageAt = function() return nil end },
	Game = { players = function() return {} end },
	Util = { root = function() end, toast = function() end },
	World = { loaded = {} },
}
Ch.init(G)
local out, fails = {}, 0
local function check(c, msg)
	if not c then
		fails += 1
	end
	table.insert(out, (c and "OK    " or "ÉCHEC ") .. msg)
end
local v = { key = "1,0", name = "Valdor", x = 0, z = 0 }
local o = Ch.offer(v, 1)
check(o and o.kind == "apporter" and o.chantier == "marche" and o.need >= 20 and o.need <= 40, "offre : une part de 20 à 40 du premier chantier")
local parts = 0
while not Ch.built("1,0", "marche") and parts < 200 do
	Ch.contribute({}, Ch.offer(v, parts), v)
	parts += 1
end
check(Ch.built("1,0", "marche") and Ch.sellMult("1,0") == 1.05, "marché terminé : +5 % à la vente (" .. parts .. " parts)")
check(Ch.offer(v, 500).chantier == "palissade", "chantier suivant : palissade")
while not Ch.built("1,0", "palissade") and parts < 400 do
	Ch.contribute({}, Ch.offer(v, parts), v)
	parts += 1
end
check(Ch.waveMult("1,0") == 0.6, "palissade terminée : vagues ×0,6")
check(Ch.sellMult("2,2") == 1, "autre village : pas de bonus")
local stale = { kind = "apporter", chantier = "marche", v = "1,0", key = "planks", need = 30 }
Ch.contribute({}, stale, v)
check(true, "part d'un chantier déjà fini : ignorée sans erreur")
-- atelier commun et grand-rue pavée (20/11) : bonus seulement dans le village concerné
G.world.chantiers["1,0"].done.atelier = 1
G.world.chantiers["1,0"].done.route = 1
local here = true
G.Reputation.villageAt = function() return here and v or nil end
G.Util.root = function() return { Position = Vector3.zero } end
local P = { attrs = {} }
function P:GetAttribute(k) return self.attrs[k] end
function P:SetAttribute(k, x) self.attrs[k] = x end
G.Game.players = function() return { P } end
check(Ch.craftXp(P, 10) == 12, "atelier commun : +20 % d'XP d'artisanat ici (" .. Ch.craftXp(P, 10) .. ")")
Ch.step(2.1)
check(P.attrs.Pave == true, "grand-rue pavée : attribut Pave dans le village")
here = false
check(Ch.craftXp(P, 10) == 10, "hors du village : XP normale")
Ch.step(2.1)
check(P.attrs.Pave == nil, "hors du village : plus de Pave")
table.insert(out, 1, string.format("Banc chantiers : %d échec(s)", fails))
return table.concat(out, "\n")
