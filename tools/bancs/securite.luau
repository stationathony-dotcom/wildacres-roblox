-- Banc de sécurité des actions client → serveur (lot C2, 20/11) — mode Edit, G simulé.
-- Rejoue des abus contre Systemes/Interact (le routeur commun de toutes les actions) :
--   nombres non finis (en nombre ou écrits en texte), tables trop profondes / trop grosses, objets
--   Roblox glissés dans les données, rafales, double clic, action inconnue, action coupée en urgence.
local Interact = assert(loadstring(game.ServerScriptService.Systemes.Interact.Source, "Interact"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end

local handler
local P = { UserId = 77, Name = "Tricheur", DisplayName = "Tricheur" }
local toasts = {}
local G = {
	remotes = { Action = { OnServerEvent = { Connect = function(_, fn) handler = fn end } } },
	Game = { isPlaying = function() return true end },
	Util = { root = function() return {} end, toast = function(_, t) table.insert(toasts, t) end },
	Economie = { record = function() end },
}
Interact.init(G)

local got, calls = nil, 0
Interact.onAction("vendre", function(_, data)
	got = data
	calls += 1
end)
local function send(kind, data)
	got = nil
	handler(P, kind, data)
	task.wait(0.13) -- au-delà de l'anti-répétition (0,12 s)
	return got
end

-- 1. nombres
local d = send("vendre", { price = 0 / 0, n = math.huge, m = -math.huge, ok = 12 })
check("NaN / ±inf en nombre retirés, 12 gardé", d and d.price == nil and d.n == nil and d.m == nil and d.ok == 12)
d = send("vendre", { price = "nan", n = "inf", m = "-Infinity", big = "1e999", item = "wood", num = "15" })
check("« nan », « inf », « 1e999 » écrits en texte retirés", d and d.price == nil and d.n == nil and d.m == nil and d.big == nil)
check("texte ordinaire et nombre en texte gardés", d and d.item == "wood" and d.num == "15")
check("tonumber du reste ne donne jamais un non-fini", (function()
	for _, v in d do
		local x = tonumber(v)
		if x and (x ~= x or math.abs(x) == math.huge) then
			return false
		end
	end
	return true
end)())

-- 2. formes de données
d = send("vendre", { a = { b = { c = { e = 1 } } } })
check("table trop profonde coupée (3 niveaux max)", d and d.a and d.a.b and d.a.b.c == nil)
local big = {}
for i = 1, 500 do
	big[i] = i
end
d = send("vendre", big)
local n = 0
for _ in d or {} do
	n += 1
end
check("table géante limitée à 64 clés", n <= 64)
d = send("vendre", { inst = workspace, f = print, v = Vector3.new(0 / 0, 0, 0), w = Vector3.new(1, 2, 3) })
check("objet Roblox, fonction, Vector3 NaN retirés ; Vector3 sain gardé", d and d.inst == nil and d.f == nil and d.v == nil and d.w == Vector3.new(1, 2, 3))
d = send("vendre", { name = string.rep("x", 5000) })
check("chaîne tronquée à 200 caractères", d and #d.name == 200)
d = send("vendre", "pas une table")
check("données qui ne sont pas une table → table vide", type(d) == "table" and next(d) == nil)

-- 3. sortes d'action
calls = 0
handler(P, "inconnue", {})
handler(P, string.rep("a", 41), {})
handler(P, 42, {})
check("action inconnue / nom trop long / pas une chaîne : ignorées", calls == 0)

-- 4. double clic et rafale
calls = 0
handler(P, "vendre", {})
handler(P, "vendre", {})
check("double clic (< 0,12 s) : une seule exécution", calls == 1)
task.wait(0.2)
calls = 0
local kinds = {}
for i = 1, 60 do
	kinds[i] = "k" .. i
	Interact.onAction(kinds[i], function()
		calls += 1
	end)
end
for i = 1, 60 do
	handler(P, kinds[i], {})
end
check("rafale de 60 actions différentes : le seau à jetons en refuse (" .. calls .. " passées)", calls < 60 and calls >= 30)

-- 5. réentrée : une action encore en cours (attente DataStore) ne se double pas
task.wait(2.5) -- le seau se remplit
local running = 0
Interact.onAction("retirer", function()
	running += 1
	task.wait(0.5)
end)
-- (un vrai RemoteEvent lance chaque appel dans son propre fil : task.spawn)
task.spawn(handler, P, "retirer", {})
task.wait(0.15)
task.spawn(handler, P, "retirer", {})
check("retrait pendant un retrait en cours : ignoré", running == 1)
task.wait(0.6)

-- 6. interrupteur d'urgence
calls = 0
Interact.disabled.vendre = "test"
toasts = {}
send("vendre", {})
check("action coupée en urgence : refusée avec un message", calls == 0 and string.find(toasts[1] or "", "maintenance") ~= nil)
Interact.disabled.vendre = nil

return fails .. " échec(s)\n" .. table.concat(out, "\n")
