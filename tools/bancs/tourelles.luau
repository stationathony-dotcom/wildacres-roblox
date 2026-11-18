-- Banc des tourelles et du monde libre (mode Edit, sans Play) : Tourelles avec un G simulé,
-- vrais modèles (Catalogue.build) et de vrais rayons de tir dans le workspace.
-- Vérifie : tir sur intrus SUR la parcelle, jamais sur le propriétaire / son clan / un autorisé,
-- personne visé hors des terres, munitions consommées, vide = muette, cadence, mur = pas de tir,
-- baliste mortelle d'un coup, recharge, cambrioleur PNJ repoussé, règles « monde libre ».
local folder = Instance.new("Folder")
folder.Name = "BancTourelles"
folder.Parent = workspace
local tmp = Instance.new("Folder")
tmp.Parent = game:GetService("ServerStorage")
local sh = game.ReplicatedStorage.Shared:Clone()
sh.Parent = tmp
local tm = game.ServerScriptService.Systemes.Tourelles:Clone()
tm.Parent = tmp
local Config = require(sh.Config)
local T = require(tm)

local res, fails = {}, 0
local function check(name, cond)
	table.insert(res, (cond and "OK   " or "ÉCHEC ") .. name)
	if not cond then
		fails += 1
	end
end

local BASE = Vector3.new(0, 500, 0) -- en l'air, loin du décor
local floor = Instance.new("Part")
floor.Anchored, floor.Size, floor.Position = true, Vector3.new(200, 1, 200), BASE - Vector3.new(0, 0.5, 0)
floor.Parent = folder

local function fakePlayer(uid, name, pos)
	local char = Instance.new("Model")
	char.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored, root.Size, root.Position = true, Vector3.new(2, 2, 1), pos
	root.Parent = char
	Instance.new("Humanoid").Parent = char
	char.PrimaryPart = root
	char.Parent = folder
	return { UserId = uid, Name = name, DisplayName = name, Character = char }
end
local owner = fakePlayer(1, "Proprio", BASE + Vector3.new(60, 3, 0))
local thief = fakePlayer(2, "Voleur", BASE + Vector3.new(10, 3, 0))
local friend = fakePlayer(3, "Ami", BASE + Vector3.new(-8, 3, 0))
local passer = fakePlayer(4, "Passant", BASE + Vector3.new(0, 3, 26)) -- dans la portée, hors parcelle
local list = { owner, thief, friend, passer }

local hits, toasts, logs = {}, {}, {}
local function inPlot(pos)
	return math.abs(pos.X - BASE.X) <= 24 and math.abs(pos.Z - BASE.Z) <= 20
end
local G = {
	Config = Config,
	Util = {
		owns = function(p, o) return "u" .. p.UserId == o end,
		trusted = function(p, o, lvl) return p == friend and o == "u1" and lvl == "batir" end,
		pid = function(p) return "u" .. p.UserId end,
		playerOf = function(o) return o == "u1" and owner or nil end,
		root = function(p) return p.Character.HumanoidRootPart end,
		toast = function(p, t) table.insert(toasts, p.Name .. ":" .. t) end,
		sfx = function() end,
	},
	Clans = { clanOfUid = function() return nil end },
	Social = { groupOf = function() return nil end },
	Parcelles = { at = function(pos) return inPlot(pos) and "u1" or nil end, HALF = 24 },
	Combat = { hurtPlayer = function(p, dmg) table.insert(hits, { p.Name, dmg }) end },
	Protection = { log = function(_, t) table.insert(logs, t) end },
	Joueurs = {},
	Interact = { onPrompt = function() end },
}
T.init(G) -- la boucle de fond ne tire pas tant que G.World est vide ; T.stopped l'arrête à la fin
T.players = function()
	return list
end

-- une baliste au centre de la parcelle
local model = Config.Catalogue.build("Cat_baliste")
model:PivotTo(CFrame.new(BASE))
model.Parent = folder
local d = { id = "t1", item = "baliste", x = BASE.X, z = BASE.Z, owner = "u1", ammo = 2 }
local reg = { state = { placed = { d } }, placedModels = { model } }
G.World = { loaded = { reg } }
G.world = { regions = { r = { placed = { d } } } }

T.step()
check("la baliste tire sur l'intrus (Voleur)", #hits == 1 and hits[1][1] == "Voleur")
check("tir mortel (≥ 100000)", hits[1] and hits[1][2] >= 100000)
check("une munition consommée", d.ammo == 1)
check("ni l'ami autorisé, ni le passant hors parcelle, ni le propriétaire", #hits == 1)
T.step()
check("cadence : pas de 2e tir avant 5 s", #hits == 1)

-- un mur entre la baliste et le voleur
local wall = Instance.new("Part")
wall.Anchored, wall.Size, wall.Position = true, Vector3.new(1, 20, 20), BASE + Vector3.new(5, 5, 0)
wall.Parent = folder
T.step()
local _ = wall
-- on simule l'écoulement de la cadence en relançant après avoir vidé l'horloge interne
task.wait(5.1)
T.step()
check("mur entre les deux : pas de tir", #hits == 1)
wall:Destroy()
T.step()
check("mur retiré : 2e tir", #hits == 2)
check("à court de munitions", d.ammo == 0)
task.wait(5.1)
T.step()
check("vide : elle se tait", #hits == 2)

-- recharge par le propriétaire
local bag = { bolt_heavy = 30 }
G.Joueurs.count = function(_, i) return bag[i] or 0 end
G.Joueurs.take = function(_, i, n) bag[i] -= n return true end
G.Joueurs.sync = function() end
T.load(owner, "t1")
check("recharge plafonnée à 12 carreaux", d.ammo == 12 and bag.bolt_heavy == 18)
T.load(thief, "t1")
check("le voleur ne peut pas la garnir", d.ammo == 12)

-- cambrioleur PNJ simulé : repoussé, une munition
check("cambrioleur PNJ repoussé", T.repel("u1", { x = BASE.X, z = BASE.Z }) == true and d.ammo == 11)

-- règles du monde libre
check("monde libre : bâtir chez autrui", Config.LIBRE.batirChezAutrui == true)
check("monde libre : plus de zone sûre ni de bouclier ni de grâce après K.O.",
	not Config.LIBRE.zoneSureArrivee and not Config.LIBRE.bouclierArrivee and not Config.LIBRE.graceApresKO)
check("tourelle et baliste en boutique", table.find(Config.SHOP, "tourelle") ~= nil and table.find(Config.SHOP, "baliste") ~= nil)

folder:Destroy()
tmp:Destroy()
G.World = nil
T.stopped = true
return string.format("%d échec(s)\n%s", fails, table.concat(res, "\n"))
