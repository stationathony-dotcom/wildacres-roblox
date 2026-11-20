-- Banc : les villageois fuient une bête hostile (Npcs.threatNear, 20/11) — mode Edit, G simulé.
-- copie posée à côté de l'original (le module lit script.Parent), retirée tout de suite
local copy = game.ServerScriptService.Systemes.Npcs:Clone()
copy.Name = "NpcsBanc"
copy.Parent = game.ServerScriptService.Systemes
local N = require(copy)
copy:Destroy()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end
local list = {}
local G = { Enemies = { list = list }, Interact = { onAction = function() end, onPrompt = function() end } }
pcall(N.init, G) -- l'init complet échoue sans monde : seul G compte ici
local function beast(x, extra)
	local en = { pos = Vector3.new(x, 0, 0), k = { name = "Loup" }, model = { Parent = true } }
	for k, v in extra or {} do
		en[k] = v
	end
	table.insert(list, en)
	return en
end
local e = { root = { Position = Vector3.zero } }
check("rien autour : pas de danger", N.threatNear(e) == nil)
e.threatCheck = 0
local far = beast(40)
check("loup à 40 studs : trop loin", N.threatNear(e) == nil)
e.threatCheck = 0
local near = beast(15)
check("loup à 15 studs : danger", N.threatNear(e) == near)
check("contrôle limité à une fois par seconde", N.threatNear(e) == nil)
e.threatCheck = 0
near.dead = true
check("loup mort : plus de danger", N.threatNear(e) == nil)
e.threatCheck = 0
beast(10, { k = { name = "Lapin", passive = true } })
beast(8, { pet = true })
beast(6, { k = { name = "Kelpie", neutral = true } })
check("bête passive, neutre ou compagnon : pas de fuite", N.threatNear(e) == nil)
local _ = far
return fails .. " échec(s)\n" .. table.concat(out, "\n")
