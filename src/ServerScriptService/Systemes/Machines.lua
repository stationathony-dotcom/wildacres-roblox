-- Inventions (bac à sable) : des machines qui aident sans rien produire gratuitement.
--  · Moulin : on y met du blé, le lendemain il rend de la farine (2 pour 3).
--  · Arroseur : rempli au seau d'eau (3 jours par seau), il arrose chaque matin les cultures autour (3 x 3 cases).
--  · Ruche : du miel tous les 2 jours, plus vite s'il y a des fleurs (pots, parterres) autour.
-- L'état vit dans l'objet posé (d.mill, d.water, d.hive) et tourne même quand la région est déchargée.
--  · Mécanismes (19/11) : le PONT-LEVIS se lève et s'abaisse, la TRAPPE s'ouvre (on tombe dedans) ;
--    l'état (d.up) est gardé, et on peut y poser une serrure comme sur une porte (Protection.access).

local Machines = {}
local G, Config

function Machines.init(g)
	G = g
	Config = G.Config
	G.Interact.onPrompt("mill", function(player, prompt)
		Machines.mill(player, prompt:GetAttribute("Placed"))
	end)
	G.Interact.onPrompt("sprinkler", function(player, prompt)
		Machines.sprinkler(player, prompt:GetAttribute("Placed"))
	end)
	G.Interact.onPrompt("hive", function(player, prompt)
		Machines.hive(player, prompt:GetAttribute("Placed"))
	end)
	G.Interact.onPrompt("mecanisme", function(player, prompt)
		Machines.lever(player, prompt:GetAttribute("Placed"))
	end)
end

-- ----------------------------------------------------------------- Mécanismes
-- pièce mobile autour d'une charnière : { charnière dans le repère du modèle, angle « levé » }
Machines.MECHS = {
	drawbridge = { hinge = CFrame.new(0, 0.25, -4), angle = math.rad(-82), up = "Baisser le pont-levis", down = "Lever le pont-levis" },
	trapdoor = { hinge = CFrame.new(0, 0.15, -1.5), angle = math.rad(-95), up = "Fermer la trappe", down = "Ouvrir la trappe" },
}
local rest = setmetatable({}, { __mode = "k" }) -- pièce -> CFrame au repos (rabattu), dans le repère du modèle

local function modelOf(d, reg)
	for _, m in (reg and reg.placedModels) or {} do
		if m.Parent and m:GetAttribute("PlacedId") == d.id then
			return m
		end
	end
	return nil
end

-- place la pièce mobile (animée ou non) selon d.up
function Machines.applyMech(model: Model, d, animate: boolean?)
	local mech = Machines.MECHS[d.item]
	if not mech or not model then
		return
	end
	local pivot = model:GetPivot()
	local hinge = pivot * mech.hinge
	local rot = d.up and CFrame.Angles(mech.angle, 0, 0) or CFrame.identity
	local TS = game:GetService("TweenService")
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= model.PrimaryPart then -- la base invisible (pivot) ne bouge pas
			rest[p] = rest[p] or pivot:ToObjectSpace(p.CFrame)
			local target = hinge * rot * hinge:ToObjectSpace(pivot * rest[p])
			if animate then
				TS:Create(p, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { CFrame = target }):Play()
			else
				p.CFrame = target
			end
		end
	end
	for _, pr in model:GetDescendants() do
		if pr:IsA("ProximityPrompt") and pr:GetAttribute("Action") == "mecanisme" then
			pr.ActionText = d.up and mech.up or mech.down
		end
	end
end

function Machines.lever(player: Player, id: string)
	local d, reg = G.Protection.findPlaced(id)
	if not d or not Machines.MECHS[d.item] then
		return
	end
	local root = G.Util.root(player)
	if not root or (Vector3.new(d.x, root.Position.Y, d.z) - root.Position).Magnitude > 14 then
		return
	end
	G.Protection.access(player, d, function()
		d.up = not d.up or nil
		Machines.applyMech(modelOf(d, reg), d, true)
		G.Util.sfx("porte", Vector3.new(d.x, root.Position.Y, d.z))
	end)
end

local function mine(player: Player, d): boolean
	if d and d.owner and not G.Util.owns(player, d.owner) then
		G.Util.toast(player, "Ce n'est pas à toi.")
		return false
	end
	return d ~= nil
end

function Machines.mill(player: Player, id: string)
	local d = G.Protection.findPlaced(id)
	if not mine(player, d) then
		return
	end
	d.mill = d.mill or { wheat = 0, flour = 0 }
	if d.mill.flour > 0 then
		G.Joueurs.add(player, "flour", d.mill.flour)
		d.mill.flour = 0
		G.Joueurs.sync(player)
		return
	end
	local n = G.Joueurs.count(player, "wheat")
	if n < 3 then
		G.Util.toast(player, "Le moulin attend du blé (3 au moins). Il moud pendant la nuit.")
		return
	end
	n -= n % 3
	G.Joueurs.take(player, "wheat", n)
	d.mill.wheat += n
	G.Util.toast(player, "🌾 " .. n .. " blé au moulin : la farine sera prête demain.")
	G.Joueurs.sync(player)
end

function Machines.sprinkler(player: Player, id: string)
	local d = G.Protection.findPlaced(id)
	if not mine(player, d) then
		return
	end
	if not G.Joueurs.take(player, "bucket", 1) then
		G.Util.toast(player, "Verse-y un seau d'eau (" .. (d.water or 0) .. " jour(s) d'eau en réserve).")
		return
	end
	d.water = (d.water or 0) + 3
	G.Joueurs.add(player, "bucket_empty", 1, true)
	G.Util.toast(player, "💧 Arroseur rempli : " .. d.water .. " jour(s) d'eau.")
	G.Joueurs.sync(player)
end

function Machines.hive(player: Player, id: string)
	local d = G.Protection.findPlaced(id)
	if not d then
		return
	end
	if (d.hive or 0) < 2 then
		G.Util.toast(player, "Les abeilles travaillent… (fleurs autour = miel plus vite)")
		return
	end
	if d.owner and not G.Util.owns(player, d.owner) then
		G.Law.crime(player, "theft", Vector3.new(d.x, 0, d.z), d.owner)
	end
	d.hive = 0
	G.Joueurs.add(player, "honey", math.random(1, 2))
	G.Joueurs.addSkillXp(player, "elevage", 4)
	G.Joueurs.sync(player)
end

-- Chaque matin (après la pousse des cultures) : moulins, arroseurs, ruches
function Machines.newDay()
	if not G.world then
		return
	end
	for _, rs in G.world.regions do
		for _, d in rs.placed or {} do
			if d.item == "windmill" and d.mill and d.mill.wheat > 0 then
				d.mill.flour += math.floor(d.mill.wheat * 2 / 3)
				d.mill.wheat = 0
			elseif d.item == "sprinkler" and (d.water or 0) > 0 then
				d.water -= 1
				local cx, cz = math.floor(d.x / Config.CELL), math.floor(d.z / Config.CELL)
				for dx = -1, 1 do
					for dz = -1, 1 do
						local rx, rz = G.WG.regionOf(cx + dx, cz + dz)
						local rs2 = G.world.regions[rx .. "," .. rz]
						local st = rs2 and rs2.tilled and rs2.tilled[(cx + dx) .. "," .. (cz + dz)]
						if st then
							st.watered = true
						end
					end
				end
			elseif d.item == "beehive" then
				-- des fleurs autour (pots posés) accélèrent la ruche
				local flowers = 0
				for _, o in rs.placed do
					if o.item == "flowerpot" and math.abs(o.x - d.x) < 16 and math.abs(o.z - d.z) < 16 then
						flowers += 1
					end
				end
				d.hive = (d.hive or 0) + 1 + math.min(2, flowers) * 0.5
			end
		end
	end
end

return Machines
