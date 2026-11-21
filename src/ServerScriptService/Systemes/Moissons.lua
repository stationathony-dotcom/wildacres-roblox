-- Récolte façon Minecraft (18/11, ses mots : « blé ramassable, tout ramassable minecraft style ») :
-- on CLIQUE sur une touffe (pas d'invite [E]) → elle disparaît, ce qu'elle donne TOMBE AU SOL
-- (Systemes/Butin) et elle repousse quelques jours plus tard. N'importe qui peut récolter : monde
-- libre, aucune règle de propriété (c'est le champ du village).
-- Générique : tout groupe « Touffe » d'un modèle déclaré dans SOURCES devient récoltable (tag
-- CollectionService « Recoltable » + attribut RecolteId sur ses pièces, lu par Interface.client).
-- État : reg.state.moisson[clé] = jour de la récolte (la touffe revient au bout de REGROW jours).

local CollectionService = game:GetService("CollectionService")

local Moissons = {}
local G

-- modèle -> ce que donne une touffe
local SOURCES = {
	-- résistance 2 : deux coups à la main, un seul avec une houe ; la compétence accélère
	Champ_Ble = { item = "wheat", n = { 1, 2 }, bonus = "seed_wheat", bonusP = 0.25, regrow = 3, skill = "agriculture", tough = 2, tool = "hoe" },
}
-- décor naturel du plan (dossier « Decor » de la région, règle 6 : tout est ramassable) : le modèle ENTIER
-- est une touffe ; clé stable = attribut DecoIdx posé par World. Les tirages du plan ne changent pas.
local DECOR = {
	Roseaux = { item = "reeds", n = { 1, 2 }, regrow = 3, skill = "agriculture", tough = 1 },
	Nenuphar = { item = "flower", n = { 1, 1 }, regrow = 4, skill = "agriculture", tough = 1 },
}
Moissons.DECOR = DECOR
local GAP = 0.25 -- s entre deux coups d'un même joueur
local lastHit = {}
local REACH = 14 -- studs entre le joueur et la touffe

local live = {} -- RecolteId -> { parts, reg, key, src, pos }

local function shown(e, on: boolean)
	for _, p in e.parts do
		p.Transparency = on and 0 or 1
		p.CanQuery = on
	end
end

function Moissons.init(g)
	G = g
	game:GetService("Players").PlayerRemoving:Connect(function(pl)
		lastHit[pl] = nil
	end)
	G.Interact.onAction("recolter_clic", function(player, data)
		if type(data) == "table" and type(data.id) == "string" then
			Moissons.harvest(player, data.id)
		end
	end)
end

function Moissons.onRegionLoad(reg)
	local st = reg.state
	st.moisson = st.moisson or {}
	for hid, h in reg.houses do
		local src = h.model and SOURCES[h.model.Name]
		if src then
			local i = 0
			for _, t in h.model:GetChildren() do
				if t:IsA("Model") and t.Name == "Touffe" then
					i += 1
					local key = hid .. "|" .. i
					local id = reg.key .. "|" .. key
					local parts = {}
					for _, p in t:GetDescendants() do
						if p:IsA("BasePart") then
							table.insert(parts, p)
							p:SetAttribute("RecolteId", id)
							CollectionService:AddTag(p, "Recoltable")
						end
					end
					local e = { parts = parts, reg = reg, key = key, src = src, pos = t:GetPivot().Position, model = t, hits = 0 }
					live[id] = e
					local d = st.moisson[key]
					if d and G.world.day >= d + src.regrow then
						st.moisson[key] = nil
						d = nil
					end
					shown(e, d == nil)
				end
			end
		end
	end
	local deco = reg.folder and reg.folder:FindFirstChild("Decor")
	for _, m in deco and deco:GetChildren() or {} do
		local src = DECOR[m.Name]
		local idx = m:GetAttribute("DecoIdx")
		if src and idx and m:IsA("Model") then
			local key = "d|" .. idx
			local id = reg.key .. "|" .. key
			local parts = {}
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then
					table.insert(parts, p)
					p:SetAttribute("RecolteId", id)
					CollectionService:AddTag(p, "Recoltable")
				end
			end
			local e = { parts = parts, reg = reg, key = key, src = src, pos = m:GetPivot().Position, model = m, hits = 0 }
			live[id] = e
			local d = st.moisson[key]
			if d and G.world.day >= d + src.regrow then
				st.moisson[key] = nil
				d = nil
			end
			shown(e, d == nil)
		end
	end
end

function Moissons.onRegionUnload(reg)
	for id, e in live do
		if e.reg == reg then
			live[id] = nil
		end
	end
end

-- chaque matin : ce qui a repoussé réapparaît
function Moissons.newDay()
	for _, e in live do
		local st = e.reg.state.moisson
		local d = st and st[e.key]
		if d and G.world.day >= d + e.src.regrow then
			st[e.key] = nil
			shown(e, true)
		end
	end
end

function Moissons.harvest(player: Player, id: string)
	if string.sub(id, 1, 3) == "fh|" then
		-- herbe haute dessinée par le client (Systemes/Fauche)
		local F = G.Fauche and rawget(G.Fauche, "harvest")
		if F then
			F(player, id)
		end
		return
	end
	local e = live[id]
	if not e or not e.reg.state.moisson or e.reg.state.moisson[e.key] then
		return
	end
	local root = G.Util.root(player)
	if not root or (root.Position - e.pos).Magnitude > REACH then
		return
	end
	local src = e.src
	local now = os.clock()
	if now - (lastHit[player] or 0) < GAP then
		return
	end
	lastHit[player] = now
	-- usure : retombe si on la laisse 8 s ; force = 1 à la main, 2 avec l'outil, + compétence
	if now - (e.last or 0) > 8 then
		e.hits = 0
	end
	e.last = now
	if G.Util.geste then
		G.Util.geste(player, "cueillir") -- on se penche sur la touffe
	end
	local power = 1
	if src.tool and G.Joueurs.bestTool then
		local _, tier = G.Joueurs.bestTool(player, src.tool)
		if (tier or 0) > 0 then
			power = 2
			if G.Joueurs.wearTool then
				G.Joueurs.wearTool(player, src.tool)
			end
		end
	end
	power *= 1 + math.min(60, (G.Joueurs.skill and G.Joueurs.skill(player, src.skill) or 0)) * 0.01
	e.hits += power
	local tough = src.tough or 1
	e.model:SetAttribute("Usure", math.clamp(e.hits / tough, 0, 1))
	if e.hits < tough - 1e-6 then
		return
	end
	e.hits = 0
	e.model:SetAttribute("Usure", 0)
	e.reg.state.moisson[e.key] = G.world.day
	shown(e, false)
	local n = math.random(src.n[1], src.n[2])
	G.Util.auSol(player, e.pos + Vector3.new(0, 1, 0), nil, function()
		G.Joueurs.add(player, src.item, n)
		if src.bonus and math.random() < src.bonusP then
			G.Joueurs.add(player, src.bonus, 1)
		end
	end)
	G.Joueurs.addSkillXp(player, src.skill, 1)
	if G.Quetes and rawget(G.Quetes, "note") then
		G.Quetes.note(player, "recolter", src.item, n)
	end
	if G.Activites and rawget(G.Activites, "note") then
		G.Activites.note(player, "recolte", n)
	end
end

return Moissons
