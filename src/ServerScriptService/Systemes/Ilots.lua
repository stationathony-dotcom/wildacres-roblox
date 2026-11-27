-- Îlots au large (étape 16B / 18). Cinq petites îles semées en mer autour de l'île principale,
-- uniquement accessibles en barque (ou à la nage pour les téméraires). Sur chacune : du sable, un peu
-- d'herbe, des rochers, et une ÉPAVE à fouiller (elle se regarnit tous les 7 jours) ; l'une d'elles
-- porte un PHARE dont la lumière se voit de la côte la nuit — un repère et une invitation.
-- Posées par-dessus la génération, avec leur propre graine (n'altère pas les mondes existants) :
-- même tirage pour une même graine de monde. État (dernière fouille) dans G.world.extra.ilots.

local Ilots = {}
local G, Config

local LOOT_DAYS = 7
-- filon rare propre à chaque îlot (27/11, MANQUES-MMO n° 1 « minerais rares propres à chaque île ») :
-- une raison de prendre la mer et de commercer ; pioche de fer au moins, se regarnit en VEIN_DAYS jours
Ilots.VEINS = { ilot1 = { "meteorite", 1, 2 }, ilot2 = { "ancient_crystal", 1, 3 }, ilot3 = { "pearl", 2, 4 }, ilot4 = { "amber", 2, 4 }, ilot5 = { "mineral_heart", 1, 1 } }
local VEIN_DAYS = 5
local VEIN_TIER = 3
local list = nil -- { { id, x, z, phare } }

local function islets()
	if list then
		return list
	end
	list = {}
	local rng = Random.new(G.WG.hash(G.world.seed, "ilots"))
	local span = Config.CELL * Config.REGION
	local n = 5
	for i = 1, n do
		-- plusieurs essais : il faut tomber en pleine mer (la côte varie d'une graine à l'autre)
		for _ = 1, 12 do
			local a = (i - 1) / n * math.pi * 2 + rng:NextNumber(-0.45, 0.45)
			local d = rng:NextNumber(11.2, 12.9) * span
			local x, z = math.cos(a) * d, math.sin(a) * d
			local r = rng:NextNumber(14, 20)
			if G.Util.isWater(x, z) and G.Util.isWater(x + r, z) and G.Util.isWater(x - r, z) and G.Util.isWater(x, z + r) and G.Util.isWater(x, z - r) then
				table.insert(list, { id = "ilot" .. i, x = x, z = z, r = r })
				break
			end
		end
	end
	if #list > 0 then
		list[rng:NextInteger(1, #list)].phare = true
	end
	return list
end

local function state(id: string)
	G.world.extra = G.world.extra or {}
	G.world.extra.ilots = G.world.extra.ilots or {}
	G.world.extra.ilots[id] = G.world.extra.ilots[id] or {}
	return G.world.extra.ilots[id]
end

local function part(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Anchored = true
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function buildWreck(folder, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "Epave"
	local wood = Color3.fromRGB(96, 70, 48)
	local hull = part(m, "Coque", Vector3.new(6, 2.4, 16), cf * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(18)), wood, Enum.Material.WoodPlanks)
	m.PrimaryPart = hull
	part(m, "Bordage", Vector3.new(0.5, 2.4, 14), cf * CFrame.new(-3, 1.6, 0) * CFrame.Angles(0, 0, math.rad(30)), wood, Enum.Material.WoodPlanks)
	part(m, "Mat", Vector3.new(0.6, 9, 0.6), cf * CFrame.new(1, 3, -2) * CFrame.Angles(math.rad(25), 0, math.rad(40)), Color3.fromRGB(80, 56, 36), Enum.Material.Wood)
	part(m, "Voile", Vector3.new(0.1, 4, 3.6), cf * CFrame.new(2.6, 4.2, -2) * CFrame.Angles(math.rad(25), 0, math.rad(40)), Color3.fromRGB(210, 200, 170), Enum.Material.Fabric).CanCollide = false
	local chest = part(m, "Malle", Vector3.new(2.4, 1.6, 1.6), cf * CFrame.new(-1, 1.6, 3), Color3.fromRGB(110, 76, 44), Enum.Material.Wood)
	part(m, "Cerclage", Vector3.new(2.5, 0.2, 1.7), cf * CFrame.new(-1, 2.1, 3), Color3.fromRGB(70, 70, 76), Enum.Material.Metal).CanCollide = false
	m.Parent = folder
	return m, chest
end

local function buildLighthouse(folder, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "Phare"
	local stone = Color3.fromRGB(220, 214, 200)
	part(m, "Socle", Vector3.new(8, 3, 8), cf * CFrame.new(0, 1.5, 0), Color3.fromRGB(128, 128, 134), Enum.Material.Cobblestone)
	for i = 0, 5 do
		part(m, "Tour", Vector3.new(3.4, 5, 5.2 - i * 0.25), cf * CFrame.new(0, 5.5 + i * 5, 0) * CFrame.Angles(0, 0, math.rad(90)),
			i % 2 == 0 and stone or Color3.fromRGB(170, 50, 44), Enum.Material.Brick, Enum.PartType.Cylinder).Size = Vector3.new(5, 5.2 - i * 0.25, 5.2 - i * 0.25)
	end
	local lamp = part(m, "Lanterne", Vector3.new(3, 3, 3), cf * CFrame.new(0, 34.5, 0), Color3.fromRGB(255, 230, 150), Enum.Material.Neon, Enum.PartType.Ball)
	part(m, "Toit", Vector3.new(4.4, 3, 4.4), cf * CFrame.new(0, 37.5, 0), Color3.fromRGB(60, 60, 66), Enum.Material.Slate)
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 4
	light.Color = Color3.fromRGB(255, 220, 140)
	light.Parent = lamp
	game:GetService("CollectionService"):AddTag(lamp, "LumiereNuit") -- s'allume la nuit (Clock)
	m.Parent = folder
	G.Clock.setLamp(lamp, G.Clock.isNight())
end

function Ilots.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("filon_ilot", function(player, prompt)
		local ok, msg = Ilots.mine(player, prompt:GetAttribute("Ilot"))
		if msg ~= "" then
			G.Util.toast(player, msg, ok and "gain" or nil)
		end
	end)
	G.Interact.onPrompt("epave", function(player, prompt)
		Ilots.search(player, prompt:GetAttribute("Ilot"))
	end)
end

function Ilots.onRegionLoad(reg)
	local span = Config.CELL * Config.REGION
	for _, il in islets() do
		if math.floor(il.x / span) == reg.rx and math.floor(il.z / span) == reg.rz then
			-- seulement en pleine mer (sinon la côte l'a avalé : on ne pose rien)
			if G.Util.isWater(il.x, il.z) then
				local base = Config.WATER_Y
				local t = workspace.Terrain
				t:FillCylinder(CFrame.new(il.x, base - 5, il.z), 9, il.r, Enum.Material.Sand)
				t:FillCylinder(CFrame.new(il.x, base + 0.5, il.z), 3, il.r * 0.65, Enum.Material.Grass)
				local folder = Instance.new("Folder")
				folder.Name = "Ilot"
				folder.Parent = reg.folder
				local top = base + 2
				for k = 1, 3 do
					local a = k * 2.1
					local rock = G.Util.clone("Rocher")
					if rock then
						rock:PivotTo(CFrame.new(il.x + math.cos(a) * il.r * 0.7, top - 0.5, il.z + math.sin(a) * il.r * 0.7) * CFrame.Angles(0, a, 0))
						rock.Parent = folder
					end
				end
				local tree = G.Util.clone("Arbre_Saule")
				if tree then
					tree:PivotTo(CFrame.new(il.x - il.r * 0.3, top, il.z + il.r * 0.2))
					tree.Parent = folder
				end
				local _, chest = buildWreck(folder, CFrame.new(il.x + il.r * 0.35, top - 0.6, il.z - il.r * 0.25) * CFrame.Angles(0, 0.7, 0))
				local pr = G.Util.prompt(chest, "epave", "Fouiller l'épave", "Épave", { hold = 1.2, dist = 9 })
				pr:SetAttribute("Ilot", il.id)
				if il.phare then
					buildLighthouse(folder, CFrame.new(il.x - il.r * 0.1, top - 1, il.z - il.r * 0.45))
				end
				local vein = Ilots.VEINS[il.id]
				local info = vein and Config.ITEMS[vein[1]]
				local filon = info and G.Util.clone("Filon_Or")
				if filon then
					filon.Name = "Filon_Ilot"
					filon:PivotTo(CFrame.new(il.x + il.r * 0.1, top - 0.6, il.z + il.r * 0.5))
					filon.Parent = folder
					local anchor = filon.PrimaryPart or filon:FindFirstChildWhichIsA("BasePart", true)
					if anchor then
						local p2 = G.Util.prompt(anchor, "filon_ilot", "Miner", info.name, { hold = 1.5, dist = 9 })
						p2:SetAttribute("Ilot", il.id)
					end
				end
			end
		end
	end
end

function Ilots.mine(player: Player, id: string?): (boolean, string)
	local vein = type(id) == "string" and Ilots.VEINS[id]
	if not vein then
		return false, ""
	end
	local _, tier = G.Joueurs.bestTool(player, "pickaxe")
	if (tier or 0) < VEIN_TIER then
		return false, "Cette roche est trop dure : il faut une pioche de fer au moins."
	end
	local st = state(id)
	if st.vein and G.world.day - st.vein < VEIN_DAYS then
		return false, "Le filon est épuisé pour l'instant (" .. (VEIN_DAYS - (G.world.day - st.vein)) .. " jour(s))."
	end
	st.vein = G.world.day
	local n = math.random(vein[2], vein[3])
	G.Joueurs.add(player, vein[1], n)
	G.Joueurs.addSkillXp(player, "minage", 6)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	local info = Config.ITEMS[vein[1]]
	return true, "⛏️ " .. n .. " " .. (info and info.name or vein[1]) .. " : on n'en trouve qu'ici."
end

function Ilots.search(player: Player, id: string?)
	if type(id) ~= "string" then
		return
	end
	local st = state(id)
	if st.day and G.world.day - st.day < LOOT_DAYS then
		G.Util.toast(player, "L'épave a déjà été fouillée. La mer y rejettera d'autres choses dans " .. (LOOT_DAYS - (G.world.day - st.day)) .. " jour(s).")
		return
	end
	st.day = G.world.day
	local list2 = G.Config.Catalogue.TREASURE
	for _ = 1, 2 do
		local e = list2[math.random(1, #list2)]
		G.Joueurs.add(player, e[1], math.random(e[2], e[3]))
	end
	G.Joueurs.add(player, "gold", math.random(30, 80))
	if math.random() < 0.3 then
		G.Joueurs.add(player, "map_fragment", 1)
	end
	if math.random() < 0.08 then
		G.Joueurs.add(player, "treasure_map", 1)
	end
	G.Util.sfx("pieces", Vector3.zero, player)
	G.Util.toast(player, "⚓ Tu fouilles l'épave… et trouves de quoi payer la traversée !", "big")
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
end

-- Pour les tests : positions des îlots
function Ilots.positions()
	local out = {}
	for _, il in islets() do
		table.insert(out, { id = il.id, x = math.floor(il.x), z = math.floor(il.z), phare = il.phare, water = G.Util.isWater(il.x, il.z) })
	end
	return out
end

return Ilots
