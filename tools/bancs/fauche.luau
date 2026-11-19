-- Banc Edit : fauche de l'herbe haute (Systemes/Fauche + Shared/HerbeHaute), G simulé.
-- Parcelle de terrain temporaire (herbe / boue / pierre) loin du monde, effacée à la fin.
local RS = game:GetService("ReplicatedStorage")
local HH = require(RS.Shared.HerbeHaute)
local mod = game.ServerScriptService.Systemes.Fauche:Clone()
local F = require(mod)
local T = workspace.Terrain
local O = Vector3.new(6000, 0, 6000)
T:FillBlock(CFrame.new(O + Vector3.new(0, -2, 0)), Vector3.new(60, 4, 60), Enum.Material.Grass)
T:FillBlock(CFrame.new(O + Vector3.new(0, -2, 40)), Vector3.new(60, 4, 20), Enum.Material.Mud)
T:FillBlock(CFrame.new(O + Vector3.new(0, -2, -40)), Vector3.new(60, 4, 20), Enum.Material.Rock)
task.wait(0.2) -- le terrain rempli n'est visible des raycasts qu'à l'image suivante

local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local root = Instance.new("Part")
root.Anchored = true
root.CanQuery = false
root.Parent = workspace
local P = { Name = "Testeur", UserId = 7 }
local inv, xp = {}, 0
local G = {
	world = { day = 5 },
	Config = { ITEMS = { fiber = {}, seed_wheat = {} } },
	Util = { root = function() return root end, auSol = function(_, _, _, fn, ...) return fn(...) end },
	Joueurs = {
		add = function(_, item, n) inv[item] = (inv[item] or 0) + n end,
		addSkillXp = function() xp += 1 end,
	},
}
F.init(G)
local folder = RS:FindFirstChild("Fauche")
check("dossier Fauche publié", folder ~= nil)

-- trouve une case avec touffe sur le sol voulu
local function find(z0: number, z1: number, mat)
	for cx = math.floor((O.X - 25) / 5), math.floor((O.X + 25) / 5) do
		for cz = math.floor((O.Z + z0) / 5), math.floor((O.Z + z1) / 5) do
			local i = HH.at(cx, cz)
			if i and HH.sorteFor(i, mat) then
				return cx, cz, i
			end
		end
	end
end
local function standAt(i, dx)
	root.Position = Vector3.new(i.x + (dx or 0), 3, i.z)
end

local cx, cz, i = find(-25, 25, Enum.Material.Grass)
check("une touffe d'herbe sur la parcelle", cx ~= nil)
standAt(i, 30)
F.harvest(P, HH.id(cx, cz))
check("trop loin : rien", folder:GetAttribute(HH.attr(cx, cz)) == nil)
standAt(i, 2)
F.harvest(P, HH.id(cx, cz))
check("à portée : fauchée et publiée", folder:GetAttribute(HH.attr(cx, cz)) == 5)
local before = (inv.fiber or 0) + (inv.seed_wheat or 0)
task.wait(0.3)
F.harvest(P, HH.id(cx, cz))
check("déjà fauchée : rien de plus", (inv.fiber or 0) + (inv.seed_wheat or 0) == before)

-- case sans touffe (tirage) : refus même à portée
local nx, nz
for x = cx - 6, cx + 6 do
	if not HH.at(x, cz) then
		nx, nz = x, cz
		break
	end
end
if nx then
	root.Position = Vector3.new(nx * 5 + 2.5, 3, nz * 5 + 2.5)
	task.wait(0.3)
	F.harvest(P, HH.id(nx, nz))
	check("case vide : refus", folder:GetAttribute(HH.attr(nx, nz)) == nil)
end

-- sol de pierre : jamais d'herbe
local rx, rz, ri
for x = math.floor((O.X - 25) / 5), math.floor((O.X + 25) / 5) do
	for z = math.floor((O.Z - 48) / 5), math.floor((O.Z - 32) / 5) do
		local t = HH.at(x, z)
		if t and t.r < 0.3 then
			rx, rz, ri = x, z, t
		end
	end
end
if rx then
	standAt(ri, 1)
	task.wait(0.3)
	F.harvest(P, HH.id(rx, rz))
	check("sol de pierre : refus", folder:GetAttribute(HH.attr(rx, rz)) == nil)
end

-- roseaux : toujours de la fibre
local mx, mz, mi = find(32, 48, Enum.Material.Mud)
if mx then
	local f0 = inv.fiber or 0
	standAt(mi, 1)
	task.wait(0.3)
	F.harvest(P, HH.id(mx, mz))
	check("roseaux fauchés : fibre", (inv.fiber or 0) > f0)
end

-- cadence : deux coups trop rapprochés
local ax, az, ai = find(-25, 25, Enum.Material.Grass)
local bx, bz
for x = math.floor((O.X - 25) / 5), math.floor((O.X + 25) / 5) do
	for z = math.floor((O.Z - 25) / 5), math.floor((O.Z + 25) / 5) do
		local t = HH.at(x, z)
		if t and HH.sorteFor(t, Enum.Material.Grass) and not folder:GetAttribute(HH.attr(x, z)) and (x ~= ax or z ~= az) then
			local d = Vector2.new(t.x - ai.x, t.z - ai.z).Magnitude
			if d < 10 then
				bx, bz = x, z
			end
		end
	end
end
if ax and bx and not folder:GetAttribute(HH.attr(ax, az)) then
	standAt(ai, 0)
	task.wait(0.3)
	F.harvest(P, HH.id(ax, az))
	F.harvest(P, HH.id(bx, bz))
	check("cadence : un coup par 0,25 s", folder:GetAttribute(HH.attr(bx, bz)) == nil)
end

-- repousse le lendemain
G.world.day = 6
F.newDay()
check("repousse le lendemain", folder:GetAttribute(HH.attr(cx, cz)) == nil)
check("identifiant invalide ignoré", pcall(F.harvest, P, "fh|abc|1"))

-- nettoyage
T:FillBlock(CFrame.new(O + Vector3.new(0, -2, 0)), Vector3.new(70, 6, 110), Enum.Material.Air)
root:Destroy()
folder:Destroy()
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
