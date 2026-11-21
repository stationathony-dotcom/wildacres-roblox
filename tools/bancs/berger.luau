-- Banc Edit (21/11) : chien de berger — mener une bête avec un canidé qui suit rassemble ses autres bêtes
-- (Animals.lead + Compagnons.herder). G simulé.
local A = require(game.ServerScriptService.Systemes.Animals:Clone())
local C = require(game.ServerScriptService.Systemes.Compagnons:Clone())
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local P = { UserId = 1, DisplayName = "Alix" }
local pets = {}
local toasts = {}
local function prompt()
	return { Enabled = false, ActionText = "", ObjectText = "" }
end
local G = {
	world = { players = { ["1"] = { pets = pets } }, regions = {} },
	Config = {
		ANIMALS = { cow = { name = "Vache", product = "milk" }, sheep = { name = "Mouton", product = "wool" } },
		PRODUCT_VERB = { milk = "Traire", wool = "Tondre" }, TAMING = {}, UNITS = {}, ITEM_GROUPS = {},
	},
	Util = {
		pid = function(p) return "u" .. p.UserId end, owns = function(p, o) return o == "u" .. p.UserId end,
		isPlayerId = function(o) return type(o) == "string" and string.sub(o, 1, 1) == "u" end,
		toast = function(_, t) table.insert(toasts, t) end,
	},
	Joueurs = { addSkillXp = function() end, has = function() return false end },
	Parcelles = { at = function() return nil end },
}
G.Animals, G.Compagnons = A, C
-- init minimal : on évite les boucles des deux modules (seule la logique de lead / herder est testée)
local okA = pcall(function() A.init(G) end)
local okC = pcall(function() C.init(G) end)
local function beast(id, kind, owner, x)
	local a = { id = id, kind = kind, owner = owner, pos = Vector3.new(x, 0, 0), state = { product = false }, prompt = prompt(), leadPrompt = prompt(),
		k = G.Config.ANIMALS[kind] }
	table.insert(A.list, a)
	return a
end
table.clear(A.list)
local a1 = beast("a1", "cow", "u1", 0)
local a2 = beast("a2", "sheep", "u1", 10)
local a3 = beast("a3", "sheep", "u1", 18)
local far = beast("a4", "cow", "u1", 60)
local other = beast("a5", "sheep", "u2", 5)
-- sans chien : une seule bête suit
A.lead(P, "a1")
check("sans chien : seule la bête menée suit", a1.leader == P and a2.leader == nil)
A.lead(P, "a1")
check("laisser ici : elle s'installe", a1.leader == nil)
-- avec un loup apprivoisé qui suit
pets.p1 = { kind = "wolf", mode = "follow" }
check("loup qui suit = chien de berger", C.herder(P) == true)
pets.p1.mode = "guard"
check("loup de garde (reste à sa place) : non", C.herder(P) == false)
pets.p1.mode = "follow"
A.lead(P, "a1")
check("avec le chien : les 2 bêtes proches à moi suivent aussi", a2.leader == P and a3.leader == P)
check("la bête trop loin (60 studs) reste", far.leader == nil)
check("la bête d'un autre joueur n'est pas embarquée", other.leader == nil)
check("message du troupeau (3 bêtes)", string.find(toasts[#toasts], "3 bêtes", 1, true) ~= nil)
a2.pos = Vector3.new(40, 0, 0)
A.lead(P, "a1")
check("laisser ici : tout le troupeau s'installe", a1.leader == nil and a2.leader == nil and a3.leader == nil)
check("chacune s'installe là où elle est", a2.state.x == 40)
table.insert(out, 1, "(init Animals " .. tostring(okA) .. ", Compagnons " .. tostring(okC) .. ")")
return fails .. " échec(s)\n" .. table.concat(out, "\n")
