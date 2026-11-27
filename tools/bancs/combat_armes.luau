-- Banc du combat par familles d'armes (26/11, Shared/Armes + Systemes/Combat) — mode Edit, faux G.
-- Vérifie : profils (portée, multi-cibles), résistances par forme, coup dans le dos (dague), enchaînement (3e coup),
-- coup chargé, garde (bouclier / arme), parade + riposte, bris de garde, esquive, tir chargé et portée de l'arc long.
local RS = game:GetService("ReplicatedStorage")
local sh = RS.Shared:Clone()
local sys = game.ServerScriptService.Systemes:Clone()
sh.Parent = game.ServerStorage
sh.Name = "SharedBancCombat"
local Armes = require(sh.Armes)
local Combat = require(sys.Combat)
local fails, n = {}, 0
local function check(ok, msg)
	n += 1
	if not ok then
		table.insert(fails, msg)
	end
end

-- faux joueur
local function fakePlayer(name)
	local attrs = { Stamina = 100 }
	local root = Instance.new("Part")
	root.Anchored = true
	root.CFrame = CFrame.new(0, 1000, 0) -- regarde vers -Z
	root.Size = Vector3.new(2, 2, 1)
	root.Parent = workspace -- le tir vérifie que le personnage existe encore
	local p = { Name = name, DisplayName = name, UserId = math.random(1, 1e8), _attrs = attrs, root = root, Parent = game }
	function p:GetAttribute(k)
		return attrs[k]
	end
	function p:SetAttribute(k, v)
		attrs[k] = v
	end
	return p
end
local P = fakePlayer("Testeur")
local profils = { [P] = { equipped = {}, inv = { arrow = 50 }, maitrise = {} } }
local hits = {} -- journal des coups reçus par les fausses bêtes
local enemies = {}
local function enemy(id, form, pos, faceAway)
	local m = Instance.new("Model")
	local base = Instance.new("Part")
	base.Anchored = true
	base.CFrame = CFrame.lookAt(pos, pos + (faceAway and Vector3.new(0, 0, -1) or Vector3.new(0, 0, 1)))
	base.Parent = m
	m.PrimaryPart = base
	m.Parent = workspace
	local en = { id = id, k = { form = form }, pos = pos, model = m, radius = 1.5, hp = 1000 }
	table.insert(enemies, en)
	return en
end
local hurt = {}
local G = {
	Config = { ITEMS = {}, baseOf = function() return nil end, MAX_STAMINA = 100, LIBRE = {} },
	Util = {
		root = function(pl) return pl.root end, geste = function() end, sfx = function() end, toast = function() end,
		owns = function() return false end,
	},
	remotes = { Fx = { FireAllClients = function() end, FireClient = function() end } },
	Joueurs = {
		get = function(pl) return profils[pl] end, stats = function() return { force = 0, defense = 0 } end,
		skill = function() return 0 end, talent = function() return 0 end, addSkillXp = function() end,
		markDirty = function() end, wearTool = function() end,
		take = function(pl, item, k) local inv = profils[pl].inv if (inv[item] or 0) >= k then inv[item] -= k return true end return false end,
		has = function() return false end,
	},
	Enemies = {
		list = enemies, byId = function(id) for _, e in enemies do if e.id == id then return e end end end,
		hit = function(en, dmg, pl) table.insert(hits, { id = en.id, dmg = dmg }) end,
	},
	Npcs = { list = {} }, Animals = { list = {} }, Compagnons = { list = {} },
	Game = { players = function() return { P } end, spawnPos = function() return Vector3.zero end },
	World = { loaded = {} },
	Interact = { onAction = function() end },
	Law = { crime = function() end },
}
Combat.init(G)
local function reset()
	table.clear(hits)
	for _, e in enemies do e.model:Destroy() end
	table.clear(enemies)
	P._attrs.Stamina = 100
end
local function weapon(name, form)
	profils[P].equipped.weapon = form and { name = name, power = 3, slot = "weapon", form = form } or nil
end
-- GearDesign.formOf lit la pièce ; on force la forme par le nom connu des séries
local okD, Design = pcall(require, RS.Shared.GearDesign) -- le module que Combat utilise vraiment
local realFormOf = okD and Design.formOf
local forced
if okD then
	Design.formOf = function(w) return forced or realFormOf(w) end
end
local function waitCd(s) task.wait(s or 1.5) end -- > Armes.COMBO_FENETRE (1,2 s) : sinon un coup « isolé » finit un enchaînement

-- 1. poings : un seul ennemi à 4 studs, touché
reset(); weapon(nil); forced = nil
enemy("a", "quadrupede", Vector3.new(0, 1000, -4))
Combat.attack(P, nil, nil)
check(#hits == 1, "poings : la cible proche n'est pas touchée")

-- 2. lance : portée 11 (ennemi à 10 studs touché ; à l'épée non)
reset(); waitCd(); forced = "pike"; weapon("Lance", "pike")
enemy("b", "humain", Vector3.new(0, 1000, -10.5))
Combat.attack(P, nil, nil)
check(#hits == 1, "lance : portée 11 non respectée")
reset(); waitCd(); forced = "sword"; weapon("Épée", "sword")
enemy("b", "humain", Vector3.new(0, 1000, -10.5))
Combat.attack(P, nil, nil)
check(#hits == 0, "épée : touche à 10,5 studs (portée 7,5)")

-- 3. espadon : 3 cibles
reset(); waitCd(); forced = "greatsword"; weapon("Espadon", "greatsword")
for i = 1, 4 do enemy("m" .. i, "humain", Vector3.new(-3 + i * 1.5, 1000, -5)) end
Combat.attack(P, nil, nil)
check(#hits == 3, "espadon : " .. #hits .. " cibles au lieu de 3")

-- 4. résistances : masse sur golem > épée sur golem
reset(); waitCd(); forced = "mace"; weapon("Masse", "mace")
enemy("g", "golem", Vector3.new(0, 1000, -4))
Combat.attack(P, nil, nil)
local mace = hits[1] and hits[1].dmg or 0
reset(); waitCd(); forced = "sword"; weapon("Épée", "sword")
enemy("g", "golem", Vector3.new(0, 1000, -4))
Combat.attack(P, nil, nil)
local sword = hits[1] and hits[1].dmg or 0
check(mace > sword * 1.5, ("résistance golem : masse %d vs épée %d"):format(mace, sword))

-- 5. dague dans le dos
reset(); waitCd(); forced = "dagger"; weapon("Dague", "dagger")
enemy("d", "humain", Vector3.new(0, 1000, -4), true)
Combat.attack(P, nil, nil)
local back = hits[1] and hits[1].dmg or 0
reset(); waitCd()
enemy("d", "humain", Vector3.new(0, 1000, -4), false)
Combat.attack(P, nil, nil)
local front = hits[1] and hits[1].dmg or 0
check(back >= front * 2, ("dague : dos %d vs face %d"):format(back, front))

-- 6. enchaînement : le 3e coup frappe plus fort (pause : l'enchaînement précédent doit être retombé)
reset(); waitCd(2); forced = "sword"; weapon("Épée", "sword")
enemy("c", "humain", Vector3.new(0, 1000, -4))
for _ = 1, 3 do Combat.attack(P, nil, nil); task.wait(0.5) end
check(#hits == 3 and hits[3].dmg > hits[1].dmg, "enchaînement : 3e coup pas plus fort")
check(P:GetAttribute("Combo") == 3, "attribut Combo ≠ 3")

-- 7. coup chargé
reset(); waitCd(2)
enemy("c", "humain", Vector3.new(0, 1000, -4))
Combat.attack(P, nil, nil); local normal = hits[1] and hits[1].dmg or 0
task.wait(0.6)
Combat.attack(P, nil, nil, 1.5); local charged = hits[2] and hits[2].dmg or 0
check(charged > normal * 1.4, ("coup chargé : %d vs %d"):format(charged, normal))

-- 8. garde, parade, bris
-- hurtPlayer a besoin d'un Humanoid : on teste la logique de garde via un faux personnage
local char = Instance.new("Model")
local hum = Instance.new("Humanoid"); hum.Parent = char
P.Character = char
local hp0 = hum.Health
P.root.CFrame = CFrame.new(0, 1000, 0)
Combat.setGuard(P, true)
local en = enemy("x", "humain", Vector3.new(0, 1000, -5))
table.clear(hits)
Combat.hurtPlayer(P, 40, en.pos, { source = en })
check(hum.Health == hp0 and #hits == 1, "parade : dégâts reçus ou pas de riposte")
task.wait(0.7)
Combat.hurtPlayer(P, 40, en.pos, { source = en })
check(hp0 - hum.Health > 0 and hp0 - hum.Health < 40, ("garde à l'arme : %d dégâts sur 40"):format(hp0 - hum.Health))
-- de dos : la garde ne protège pas
Combat.setGuard(P, false); task.wait(0.7); Combat.setGuard(P, true); task.wait(0.4)
local h1 = hum.Health
Combat.hurtPlayer(P, 40, Vector3.new(0, 1000, 5), { source = en })
check(h1 - hum.Health >= 39, "garde : protège aussi dans le dos")
-- bris de garde : plus d'endurance
task.wait(0.7); P._attrs.Stamina = 0
Combat.hurtPlayer(P, 40, en.pos, { source = en })
check(P:GetAttribute("Garde") == nil, "garde pas brisée à 0 endurance")

-- 9. esquive : invulnérable un instant, coûte de l'endurance
Combat.setGuard(P, false)
P._attrs.Stamina = 100
task.wait(0.7)
local h2 = hum.Health
Combat.dodge(P)
Combat.hurtPlayer(P, 30, en.pos, {})
check(hum.Health == h2, "esquive : dégâts reçus pendant la roulade")
check(P:GetAttribute("Stamina") <= 100 - Armes.ESQUIVE_COUT, "esquive : endurance non payée")

-- 10. arc long : portée 72, tir chargé plus fort
reset(); waitCd(1.5); forced = "longbow"; weapon("Arc long", "longbow")
profils[P].equipped.weapon.ranged = true
local far = enemy("f", "humain", Vector3.new(0, 1001, -65))
Combat.attack(P, nil, nil)
task.wait(0.8)
check(#hits == 1, "arc long : cible à 65 studs non touchée")

if okD then Design.formOf = realFormOf end
for _, e in enemies do e.model:Destroy() end
P.root:Destroy(); char:Destroy()
sh:Destroy(); sys:Destroy()
return (#fails == 0 and "0 échec(s)" or (#fails .. " échec(s)")) .. " sur " .. n .. "\n" .. table.concat(fails, "\n")
