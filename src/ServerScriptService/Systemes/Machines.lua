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
	G.Interact.onPrompt("well", function(player)
		Machines.well(player)
	end)
	G.Interact.onPrompt("henhouse", function(player, prompt)
		Machines.henhouse(player, prompt:GetAttribute("Placed"))
	end)
	G.Interact.onPrompt("press", function(player, prompt)
		Machines.press(player, prompt:GetAttribute("Placed"))
	end)
	G.Interact.onPrompt("sawmill", function(player, prompt)
		Machines.sawmill(player, prompt:GetAttribute("Placed"))
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
		Machines.refresh(d)
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
	local _, reg = G.Protection.findPlaced(id)
	local rs = reg and reg.state -- état de la région (même table que G.world.regions[clé])
	local wheel = Machines.waterPowered(rs, d)
	G.Util.toast(player, "🌾 " .. n .. " blé au moulin : la farine sera prête demain" .. (wheel and " (roue à eau : tout est moulu, 1 pour 1)." or " (2 pour 3 ; une roue à eau au bord de l'eau, tout près, fait mieux)."))
	G.Joueurs.sync(player)
	Machines.refresh(d)
end

-- Scierie (27/11, MANQUES-MMO n° 9) : du bois le soir, des planches le lendemain — 3 par bûche (2 à l'établi),
-- 4 avec une roue à eau tout près. Même logique que le moulin : rien de gratuit, juste mieux et sans y passer.
function Machines.sawmill(player: Player, id: string)
	local d = G.Protection.findPlaced(id)
	if not mine(player, d) then
		return
	end
	d.saw = d.saw or { wood = 0, planks = 0 }
	if d.saw.planks > 0 then
		G.Joueurs.add(player, "planks", d.saw.planks)
		d.saw.planks = 0
		G.Joueurs.sync(player)
		return
	end
	local n = G.Joueurs.count(player, "wood")
	if n < 1 then
		G.Util.toast(player, "La scierie attend du bois. Elle débite pendant la nuit.")
		return
	end
	G.Joueurs.take(player, "wood", n)
	d.saw.wood += n
	local _, reg = G.Protection.findPlaced(id)
	local wheel = Machines.waterPowered(reg and reg.state, d)
	G.Util.toast(player, "🪚 " .. n .. " bois à la scierie : " .. n * (wheel and 4 or 3) .. " planches demain" .. (wheel and " (roue à eau)." or "."))
	G.Joueurs.sync(player)
end

-- Puits et pompe posés (27/11, sans effet jusqu'ici) : tous les seaux vides du sac sont remplis
function Machines.well(player: Player)
	local n = G.Joueurs.count(player, "bucket_empty")
	if n < 1 then
		G.Util.toast(player, "Il te faut un seau vide pour puiser.")
		return
	end
	G.Joueurs.take(player, "bucket_empty", n)
	G.Joueurs.add(player, "bucket", n, true)
	G.Util.toast(player, "💧 " .. n .. " seau(x) rempli(s).", "gain")
	G.Joueurs.sync(player)
end

-- Poulailler (27/11 ; il servait déjà d'abri aux poules, Animals) : nourrir SES poules au poulailler,
-- 2 blé = 1 œuf de plus le lendemain, jusqu'à 2 par poule à soi à moins de 20 studs (pas de poule, pas d'œuf)
function Machines.henhouse(player: Player, id: string)
	local d = G.Protection.findPlaced(id)
	if not mine(player, d) then
		return
	end
	d.hen = d.hen or { grain = 0, eggs = 0 }
	if d.hen.eggs > 0 then
		G.Joueurs.add(player, "egg", d.hen.eggs)
		d.hen.eggs = 0
		G.Joueurs.sync(player)
		return
	end
	local hens = 0
	for _, a in (G.Animals and G.Animals.list) or {} do
		if a.kind == "chicken" and a.pos and G.Util.owns(player, a.owner)
			and (a.pos - Vector3.new(d.x, a.pos.Y, d.z)).Magnitude < 20 then
			hens += 1
		end
	end
	if hens == 0 then
		G.Util.toast(player, "Aucune de tes poules n'est près du poulailler.")
		return
	end
	local n = math.min(math.floor(G.Joueurs.count(player, "wheat") / 2), hens * 2 - d.hen.grain)
	if n < 1 then
		G.Util.toast(player, "Les poules attendent du grain (2 blé par œuf, 2 œufs par poule et par nuit).")
		return
	end
	G.Joueurs.take(player, "wheat", n * 2)
	d.hen.grain += n
	G.Util.toast(player, "🐔 Grain donné : " .. n .. " œuf(s) demain.")
	G.Joueurs.sync(player)
end

-- Presse (objet « press » du catalogue, sans effet jusqu'ici ; 27/11) : 3 pommes + 1 bouteille le soir = 1 cidre le lendemain (4 pommes à l'établi)
function Machines.press(player: Player, id: string)
	local d = G.Protection.findPlaced(id)
	if not mine(player, d) then
		return
	end
	d.press = d.press or { lots = 0, cider = 0 }
	if d.press.cider > 0 then
		G.Joueurs.add(player, "cider", d.press.cider)
		d.press.cider = 0
		G.Joueurs.sync(player)
		return
	end
	local n = math.min(math.floor(G.Joueurs.count(player, "apple") / 3), G.Joueurs.count(player, "bottle"))
	if n < 1 then
		G.Util.toast(player, "Le pressoir attend des pommes (3) et une bouteille par cidre. Il presse pendant la nuit.")
		return
	end
	G.Joueurs.take(player, "apple", n * 3)
	G.Joueurs.take(player, "bottle", n)
	d.press.lots += n
	G.Util.toast(player, "🍎 " .. n .. " cidre(s) au pressoir : prêts demain.")
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
	Machines.refresh(d)
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
	Machines.refresh(d)
end

-- ----------------------------------------------------------------- états lisibles (passage Codex X19, 21/11)
-- Sur le modèle posé : `NomEtat` (nom affiché) et `EtatMachine` (texte bref), lus par l'interface à
-- proximité (jamais en texte permanent au-dessus de l'objet). Coffres, portes : `Verrouille` (booléen).
local LOCKABLE = { chest = true, door = true, drawbridge = true, trapdoor = true }
Machines.STATE_NAME = { furnace = "Four", water_wheel = "Roue à eau", windmill = "Moulin", sprinkler = "Arroseur", beehive = "Ruche" }

function Machines.stateText(d, rs): string?
	if d.item == "furnace" then
		return "Prêt : cuire et fondre"
	elseif d.item == "water_wheel" then
		local wet = false
		for _, off in { { 0, 0 }, { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 } } do
			if G.Util.isWater(d.x + off[1], d.z + off[2]) then
				wet = true
				break
			end
		end
		if not wet then
			return "Au sec : à poser au bord de l'eau"
		end
		for _, o in (rs and rs.placed) or {} do
			if o.item == "windmill" and math.abs(o.x - d.x) <= Machines.WHEEL_REACH and math.abs(o.z - d.z) <= Machines.WHEEL_REACH then
				return "Tourne : entraîne le moulin"
			end
		end
		return "Tourne, sans moulin à portée"
	elseif d.item == "windmill" then
		local m = d.mill or {}
		if (m.flour or 0) > 0 then
			return (m.flour .. " farine prête")
		elseif (m.wheat or 0) > 0 then
			return (m.wheat .. " blé à moudre (prêt demain)")
		end
		return "Vide : apporte du blé"
	elseif d.item == "sprinkler" then
		return (d.water or 0) > 0 and ((d.water or 0) .. " jour(s) d'eau") or "À sec : verse un seau d'eau"
	elseif d.item == "beehive" then
		return (d.hive or 0) >= 2 and "Miel prêt" or "Les abeilles travaillent"
	end
	return nil
end

-- Publie l'état sur le modèle (appelé au décor, et quand l'état change)
function Machines.publish(model: Instance?, d, rs)
	if not model or not d then
		return
	end
	if Machines.STATE_NAME[d.item] then
		model:SetAttribute("NomEtat", Machines.STATE_NAME[d.item])
		model:SetAttribute("EtatMachine", Machines.stateText(d, rs))
	end
	if LOCKABLE[d.item] then
		model:SetAttribute("Verrouille", (d.lock or 0) > 0)
	end
end

-- Retrouve le modèle d'un objet posé (région chargée) et republie son état
function Machines.refresh(d)
	if not d or not d.id then
		return
	end
	for _, reg in (G.World and G.World.loaded) or {} do
		for _, m in reg.placedModels or {} do
			if m.Parent and m:GetAttribute("PlacedId") == d.id then
				Machines.publish(m, d, reg.state)
				return
			end
		end
	end
end

-- Chaque matin (après la pousse des cultures) : moulins, arroseurs, ruches
-- Roue à eau (19/11) : posée au bord de l'eau (eau à moins de 4 studs), à moins de 16 studs d'un moulin
Machines.WHEEL_REACH = 16
function Machines.waterPowered(rs, mill): boolean
	for _, o in (rs and rs.placed) or {} do
		if o.item == "water_wheel" and math.abs(o.x - mill.x) <= Machines.WHEEL_REACH and math.abs(o.z - mill.z) <= Machines.WHEEL_REACH then
			for _, off in { { 0, 0 }, { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 } } do
				if G.Util.isWater(o.x + off[1], o.z + off[2]) then
					return true
				end
			end
		end
	end
	return false
end

function Machines.newDay()
	if not G.world then
		return
	end
	for _, rs in G.world.regions do
		for _, d in rs.placed or {} do
			if d.item == "windmill" and d.mill and d.mill.wheat > 0 then
				-- une roue à eau au bord de l'eau, tout près : le moulin moud tout (1 pour 1 au lieu de 2 pour 3)
				d.mill.flour += Machines.waterPowered(rs, d) and d.mill.wheat or math.floor(d.mill.wheat * 2 / 3)
				d.mill.wheat = 0
			elseif d.item == "henhouse" and d.hen and d.hen.grain > 0 then
				d.hen.eggs += d.hen.grain
				d.hen.grain = 0
			elseif d.item == "press" and d.press and d.press.lots > 0 then
				d.press.cider += d.press.lots
				d.press.lots = 0
			elseif d.item == "sawmill" and d.saw and d.saw.wood > 0 then
				d.saw.planks += d.saw.wood * (Machines.waterPowered(rs, d) and 4 or 3)
				d.saw.wood = 0
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
	-- états du matin sur les modèles chargés (farine prête, eau consommée, miel)
	for _, reg in (G.World and G.World.loaded) or {} do
		for _, m in reg.placedModels or {} do
			local id = m.Parent and m:GetAttribute("PlacedId")
			if id then
				for _, d in reg.state.placed or {} do
					if d.id == id and Machines.STATE_NAME[d.item] then
						Machines.publish(m, d, reg.state)
						break
					end
				end
			end
		end
	end
end

return Machines
