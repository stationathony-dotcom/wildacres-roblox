-- Fauche de l'herbe haute (19/11) : les touffes dessinées par chaque client (HerbeHaute.client,
-- placement partagé Shared.HerbeHaute) se fauchent au CLIC comme le blé (circuit « recolter_clic »
-- de Moissons, identifiants « fh|cx|cz »). Le serveur refait le tirage, vérifie la portée et le sol
-- (raycast sur le terrain), puis publie la case fauchée (attribut du dossier ReplicatedStorage.Fauche)
-- pour que tous les joueurs la voient disparaître. L'herbe repousse le lendemain matin (pas de
-- sauvegarde : c'est de l'herbe). Fauchée à la main : un peu de fibre, parfois une graine de blé.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fauche = {}
local G, HH
local folder
local GAP = 0.25 -- s entre deux coups d'un même joueur
local REGROW = 1 -- jours
local lastHit = {}
local cut = {} -- attribut -> jour de la fauche

function Fauche.init(g)
	G = g
	HH = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HerbeHaute"))
	folder = ReplicatedStorage:FindFirstChild("Fauche") or Instance.new("Folder")
	folder.Name = "Fauche"
	folder.Parent = ReplicatedStorage
	game:GetService("Players").PlayerRemoving:Connect(function(pl)
		lastHit[pl] = nil
	end)
end

local ground = RaycastParams.new()
ground.FilterType = Enum.RaycastFilterType.Include
ground.FilterDescendantsInstances = { workspace.Terrain }

-- sol sous la case : nil si pas de terrain, ou si une construction le couvre
local function soil(x: number, z: number, fromY: number): (Enum.Material?, Vector3?)
	local r = workspace:Raycast(Vector3.new(x, fromY + 40, z), Vector3.new(0, -120, 0), ground)
	if not r then
		return nil
	end
	return r.Material, r.Position
end

function Fauche.harvest(player: Player, id: string)
	local cx, cz = HH.parse(id)
	if not cx then
		return
	end
	local key = HH.attr(cx, cz)
	if cut[key] then
		return
	end
	local info = HH.at(cx, cz)
	local root = G.Util.root(player)
	if not info or not root then
		return
	end
	if Vector2.new(info.x - root.Position.X, info.z - root.Position.Z).Magnitude > HH.REACH then
		return
	end
	local now = os.clock()
	if now - (lastHit[player] or 0) < GAP then
		return
	end
	lastHit[player] = now
	local material, pos = soil(info.x, info.z, root.Position.Y)
	local sorte = material and HH.sorteFor(info, material)
	if not sorte or math.abs(pos.Y - root.Position.Y) > 12 then
		return
	end
	cut[key] = G.world.day
	folder:SetAttribute(key, G.world.day)
	local got = {}
	for item, range in sorte.donne do
		local n = math.random(range[1], range[2])
		if n > 0 and G.Config.ITEMS[item] then
			got[item] = n
		end
	end
	if sorte.bonus and G.Config.ITEMS[sorte.bonus] and math.random() < sorte.bonusP then
		got[sorte.bonus] = (got[sorte.bonus] or 0) + 1
	end
	if next(got) then
		G.Util.auSol(player, pos + Vector3.new(0, 1, 0), nil, function()
			for item, n in got do
				G.Joueurs.add(player, item, n)
			end
		end)
		G.Joueurs.addSkillXp(player, "agriculture", 1)
	end
	local S = G.Social and rawget(G.Social, "bump")
	if S then
		S(player, "fauche")
	end
end

-- chaque matin : l'herbe fauchée la veille a repoussé
function Fauche.newDay()
	for key, d in cut do
		if G.world.day >= d + REGROW then
			cut[key] = nil
			folder:SetAttribute(key, nil)
		end
	end
end

return Fauche
