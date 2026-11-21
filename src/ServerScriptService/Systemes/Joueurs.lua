-- Données du joueur : sac (inventaire), équipement, statistiques, outils en main,
-- honneur et étoiles. Le client reçoit une copie à chaque changement.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local J = {}
local G
J.profiles = {}
local dirty = {}
local recent = {} -- anti-farm : joueur -> { [compétence] = {xp gagnée, début de la fenêtre} }

function J.init(g)
	G = g
	J.TOOL_LIFE = G.Config.TOOL_LIFE
	Players.PlayerRemoving:Connect(function(p)
		-- l'ordre des écouteurs de PlayerRemoving n'est pas garanti : on laisse le temps à Game
		-- (et aux autres systèmes) de rendre les objets et de prendre l'instantané de sauvegarde
		task.delay(10, function()
			if not p.Parent then
				J.profiles[p] = nil
				recent[p] = nil
			end
		end)
	end)
	G.Interact.onAction("equip", function(player, data)
		J.equip(player, data.id)
	end)
	G.Interact.onAction("unequip", function(player, data)
		J.unequip(player, data.slot)
	end)
	G.Interact.onAction("eat", function(player, data)
		J.eat(player, data.item)
	end)
	G.Interact.onAction("drop_gear", function(player, data)
		J.dropGear(player, data.id)
	end)
	G.Interact.onAction("learn_talent", function(player, data)
		J.learnTalent(player, data.id)
	end)
	G.Interact.onAction("reset_talents", function(player)
		J.resetTalents(player)
	end)
	G.Interact.onAction("settings", function(player, data)
		-- réglages du joueur (client) : seulement des valeurs bornées, rien qui touche au jeu
		local p = J.profiles[player]
		if not p then
			return
		end
		p.settings = {
			vol = math.clamp(tonumber(data.vol) or 0.6, 0, 1),
			music = math.clamp(tonumber(data.music) or 0.5, 0, 1),
			flash = data.flash == true,
			shake = data.shake == true,
			names = data.names ~= false,
			camera = (data.camera == 1 or data.camera == 3) and data.camera or 2,
			sensitivity = (data.sensitivity == 1 or data.sensitivity == 3) and data.sensitivity or 2,
			graphics = (data.graphics == 1 or data.graphics == 3) and data.graphics or 2,
			textSize = (data.textSize == 1 or data.textSize == 3) and data.textSize or 2,
		}
		J.markDirty(player)
	end)
	G.Interact.onAction("hotbar_set", function(player, data)
		J.setHotbar(player, data.slots)
	end)
end

-- Barre d'action rapide (9 cases, façon Minecraft) : ce que le joueur y a rangé
J.HOTBAR_SIZE = 9
function J.setHotbar(player: Player, slots)
	local p = J.profiles[player]
	if not p or type(slots) ~= "table" then
		return
	end
	local clean = {}
	for i = 1, J.HOTBAR_SIZE do
		local id = slots[i]
		clean[i] = (type(id) == "string" and #id <= 40 and G.Config.ITEMS[id]) and id or ""
	end
	p.hotbar = clean
	J.markDirty(player)
end

-- Oublier ses talents (payant, comme chez un maître de guilde) : tous les points reviennent
function J.resetTalents(player: Player)
	local p = J.profiles[player]
	if not p or not next(p.talents) then
		return
	end
	local cost = math.max(25, 25 * G.Config.talentPoints(J.totalSkills(p)))
	if (p.inv.gold or 0) < cost then
		G.Util.toast(player, "Il faut " .. cost .. " 💰 pour oublier tes talents.")
		return
	end
	J.take(player, "gold", cost)
	p.talents = {}
	J.applyStats(player)
	G.Util.toast(player, "Talents oubliés (" .. cost .. " 💰). Tes points sont à nouveau libres.", "big")
	J.sync(player)
end

function J.newProfile()
	return {
		inv = { gold = 0 },
		gear = {},
		equipped = {},
		honor = 0,
		stars = 0,
		horse = nil, -- cheval possédé : {coat, saddle}
		stats = { harvested = 0, crimes = 0 },
		statXp = {}, -- pratique par caractéristique : { force = 340, … } (rang = Config.statLevel)
		attrs = {}, -- ancien système (points placés) : converti au chargement, toujours vide
		skills = {}, -- xp par compétence (monte en pratiquant)
		talents = {}, -- rang par talent
		bounty = 0, -- prime sur ta tête (persistante, comme les étoiles)
		col = {}, -- collections
		titles = {}, -- titres débloqués
		title = nil, -- titre affiché
	}
end

function J.get(player: Player)
	return J.profiles[player]
end

function J.set(player: Player, profile)
	profile.inv = profile.inv or { gold = 0 }
	profile.gear = profile.gear or {}
	profile.equipped = profile.equipped or {}
	G.Gear.migrateEquipment(profile)
	profile.honor = profile.honor or 0
	profile.stars = profile.stars or 0 -- les étoiles te suivent (déconnexion, autre monde)
	profile.bounty = profile.bounty or 0
	profile.skills = profile.skills or {}
	profile.talents = profile.talents or {}
	profile.col = profile.col or {}
	profile.titles = profile.titles or {}
	profile.stats = profile.stats or { harvested = 0, crimes = 0 }
	profile.statXp = profile.statXp or {}
	-- anciens points placés à la main (avant le 18/11) : convertis en pratique équivalente
	for k, v in profile.attrs or {} do
		if G.Gear.STATS[k] and tonumber(v) and v > 0 then
			profile.statXp[k] = math.max(profile.statXp[k] or 0, G.Config.statXpFor(v))
		end
	end
	profile.attrs = {}
	profile.level, profile.xp, profile.points = nil, nil, nil
	J.profiles[player] = profile
	-- niveaux de compétence en attributs (client : repérage des filons sur la minicarte…)
	for sk, xp in profile.skills or {} do
		player:SetAttribute("Comp_" .. sk, G.Config.skillLevel(xp))
	end
	profile.wear = profile.wear or {}
	for _, base in J.TOOL_ORDER do
		local id, tier = J.bestTool(player, base)
		player:SetAttribute("Usure_" .. base, id and (profile.wear[id] or 0) / (J.TOOL_LIFE[tier] or J.TOOL_LIFE[1]) or 0)
	end
	J.applyStats(player)
	J.sync(player)
end

function J.count(player: Player, item: string): number
	local p = J.profiles[player]
	return p and (p.inv[item] or 0) or 0
end

function J.has(player: Player, item: string, n: number?): boolean
	return J.count(player, item) >= (n or 1)
end

function J.add(player: Player, item: string, n: number?, silent: boolean?)
	local p = J.profiles[player]
	if not p then
		return
	end
	local amount = math.floor(tonumber(n) or 1)
	if type(item) ~= "string" or amount ~= amount or amount <= 0 or amount == math.huge then
		if amount ~= 0 then
			warn("[WildAcres] J.add refusé : " .. tostring(item) .. " x " .. tostring(n))
		end
		return
	end
	-- récolte / butin de créature : l'objet tombe au sol (Systemes/Butin), on le ramassera
	if G.Butin and rawget(G.Butin, "redirect") and G.Butin.redirect(player, item, amount) then
		return
	end
	if item == "gold" and G.Economie and G.Economie.goldGained then
		G.Economie.goldGained(player, amount)
		G.Util.sfx("pieces", Vector3.zero, player) -- seulement pour lui (son « 2D »)
	end
	local info = G.Config.ITEMS[item]
	if info and info.tool and item ~= "gold" then
		-- un outil ne se possède qu'une fois : le surplus se revend
		if (p.inv[item] or 0) >= 1 then
			p.inv.gold = (p.inv.gold or 0) + math.floor((info.price or 10) / 2) * amount
			if not silent then
				G.Util.toast(player, "Tu as déjà : " .. info.name .. " (revendu " .. math.floor((info.price or 10) / 2) .. " or)")
			end
			J.markDirty(player)
			return
		end
		amount = 1
	end
	p.inv[item] = (p.inv[item] or 0) + amount
	if not silent and info then
		G.Util.toast(player, string.format("+%d %s %s", amount, info.icon or "", info.name), "gain")
	end
	J.markDirty(player)
end

function J.take(player: Player, item: string, n: number?): boolean
	local p = J.profiles[player]
	local amount = tonumber(n) or 1
	-- jamais de quantité négative, fractionnaire ou NaN (sinon « prendre -5 » donnerait 5)
	if not p or type(item) ~= "string" or amount ~= amount or amount < 0 or amount ~= math.floor(amount) or amount == math.huge then
		return false
	end
	if (p.inv[item] or 0) < amount then
		return false
	end
	p.inv[item] -= amount
	if p.inv[item] <= 0 and item ~= "gold" then
		p.inv[item] = nil
	end
	if item == "gold" and G.Economie and G.Economie.goldSpent then
		G.Economie.goldSpent(player, amount) -- flux d'or du monde (/wa or)
	end
	J.markDirty(player)
	return true
end

function J.addGear(player: Player, item)
	local p = J.profiles[player]
	if not p then
		return
	end
	if G.Butin and rawget(G.Butin, "redirectGear") and G.Butin.redirectGear(player, item) then
		return
	end
	table.insert(p.gear, item)
	G.Util.toast(player, "Équipement trouvé : " .. G.Gear.describe(item), "loot")
	J.markDirty(player)
end

-- Caractéristiques = équipement porté + rang gagné en pratiquant (statXp)
function J.stats(player: Player)
	local p = J.profiles[player]
	local t = G.Gear.totals(p and p.equipped or {})
	-- panoplies : plusieurs pièces de la même matière (Shared/Equilibre)
	local okE, Eq = pcall(require, game:GetService("ReplicatedStorage").Shared.Equilibre)
	if okE and p then
		for k, v in (Eq.setBonus(p.equipped)) do
			t[k] = (t[k] or 0) + v
		end
	end
	for k, xp in (p and p.statXp) or {} do
		local lv = G.Config.statLevel(xp)
		if lv > 0 then
			t[k] = (t[k] or 0) + lv
		end
	end
	-- bonus temporaires (savon, encens…) : { [stat] = { v, fin (os.time) } }
	local now = os.time()
	for k, b in (p and p.buffs) or {} do
		if type(b) == "table" and (b[2] or 0) > now then
			t[k] = (t[k] or 0) + (b[1] or 0)
		elseif p then
			p.buffs[k] = nil
		end
	end
	return t
end

-- Bonus temporaire d'une caractéristique (le plus fort l'emporte, la durée se prolonge)
local BUFF_LABEL = { charisme = "Propre et parfumé", chance = "Encens porte-bonheur" }
function J.addBuff(player: Player, stat: string, v: number, seconds: number, label: string?)
	local p = J.profiles[player]
	if not p or not G.Gear.STATS[stat] then
		return false
	end
	p.buffs = p.buffs or {}
	local cur = p.buffs[stat]
	local now = os.time()
	local val = math.max(v, cur and cur[2] > now and cur[1] or 0)
	p.buffs[stat] = { val, math.max(now + seconds, cur and cur[2] or 0) }
	J.applyStats(player)
	J.markDirty(player)
	G.Util.toast(player, "✨ " .. (label or BUFF_LABEL[stat] or G.Gear.STATS[stat]) .. " : +" .. val .. " " .. G.Gear.STATS[stat]
		.. " pendant " .. math.floor(seconds / 60) .. " min.", "gain")
	return true
end

-- ----------------------------------------------------------------- Caractéristiques (pratique)
-- Pas de niveau de personnage : une caractéristique monte quand on pratique ce qui la travaille.

local STAT_ICON = { force = "💪", defense = "🛡️", vie = "❤️", vitesse = "👟", chance = "🍀", charisme = "🗣️", discretion = "👤" }
J.STAT_ICON = STAT_ICON

function J.addStatXp(player: Player, stat: string, amount: number)
	local p = J.profiles[player]
	if not p or not G.Gear.STATS[stat] or not (amount > 0) or amount == math.huge then
		return
	end
	p.statXp = p.statXp or {}
	local before = G.Config.statLevel(p.statXp[stat])
	p.statXp[stat] = (p.statXp[stat] or 0) + amount
	local after = G.Config.statLevel(p.statXp[stat])
	if after > before then
		J.applyStats(player)
		G.Social.checkTitles(player)
		G.Util.toast(player, string.format("+%d %s %s (%d)", after - before, STAT_ICON[stat] or "✨", G.Gear.STATS[stat], after), "gain")
	end
	J.markDirty(player)
end

-- Somme des rangs de toutes les compétences (donne les points de talent)
function J.totalSkills(p): number
	local n = 0
	for _, xp in (p and p.skills) or {} do
		n += G.Config.skillLevel(xp)
	end
	return n
end

-- ----------------------------------------------------------------- Compétences (pratique)

-- niveau ENTRAÎNÉ (sert aux déblocages : recettes, paliers, classements)
function J.skillRaw(player: Player, skill: string): number
	local p = J.profiles[player]
	return p and G.Config.skillLevel(p.skills[skill] or 0) or 0
end

-- niveau EFFECTIF : entraîné + équipement de métier porté (Shared/Equilibre, plafond +10)
function J.skill(player: Player, skill: string): number
	local p = J.profiles[player]
	if not p then
		return 0
	end
	local bonus = 0
	for _, item in p.equipped or {} do
		local s = type(item) == "table" and item.skills
		if s and s[skill] then
			bonus += s[skill]
		end
	end
	-- outils de métier gardés dans le sac (Shared/Equilibre : BAG_TOOLS, 20/11)
	local okE, Eq = pcall(require, game:GetService("ReplicatedStorage").Shared.Equilibre)
	if okE and Eq.bagToolBonus then
		bonus += Eq.bagToolBonus(p.inv, skill)
	end
	return G.Config.skillLevel(p.skills[skill] or 0) + math.min(10, bonus)
end

-- XP plafonnée par jour et par source : pour les gestes réversibles sans coût (poser/reprendre une
-- pièce, creuser/remblayer, échanges entre amis) qu'une boucle transformerait en XP infinie.
-- Le compteur vit en mémoire (un relog le remet à zéro, mais pas le jour du monde : borne suffisante).
local xpCaps = setmetatable({}, { __mode = "k" }) -- joueur -> { day, [source] = n }
function J.addSkillXpCapped(player: Player, skill: string, amount: number, source: string, cap: number): boolean
	local c = xpCaps[player]
	if not c or c.day ~= G.world.day then
		c = { day = G.world.day }
		xpCaps[player] = c
	end
	if (c[source] or 0) >= cap then
		return false
	end
	c[source] = (c[source] or 0) + 1
	J.addSkillXp(player, skill, amount)
	return true
end

function J.addSkillXp(player: Player, skill: string, amount: number)
	local p = J.profiles[player]
	local info = G.Config.SKILLS[skill]
	if not p or not info or amount <= 0 then
		return
	end
	-- anti-farm : au-delà de 400 xp en 5 min dans la même compétence, gains divisés par 4
	recent[player] = recent[player] or {}
	local r = recent[player][skill]
	local now = os.clock()
	if not r or now - r[2] > 300 then
		r = { 0, now }
		recent[player][skill] = r
	end
	r[1] += amount
	if r[1] > 400 then
		amount = math.max(1, math.floor(amount / 4))
	end
	local before = G.Config.skillLevel(p.skills[skill] or 0)
	p.skills[skill] = (p.skills[skill] or 0) + amount
	local after = G.Config.skillLevel(p.skills[skill])
	player:SetAttribute("Comp_" .. skill, after) -- lu par le client (repérage des filons…)
	if after > before then
		local rank = G.Config.skillRank(after)
		if G.Util.sfx then
			G.Util.sfx("niveau", Vector3.zero, player) -- petite fanfare, pour lui seul
		end
		if rank ~= G.Config.skillRank(before) then
			G.Util.toast(player, info.icon .. " " .. info.name .. " niveau " .. after .. " : te voilà " .. string.lower(rank) .. " !", "big")
		else
			G.Util.toast(player, info.icon .. " " .. info.name .. " niveau " .. after .. " !", "gain")
		end
		G.Social.checkTitles(player) -- titres de maîtrise (Social)
		local freeBefore = G.Config.talentPoints(J.totalSkills(p) - (after - before))
		if G.Config.talentPoints(J.totalSkills(p)) > freeBefore then
			G.Util.toast(player, "✨ Un point de talent à placer ([K]).", "big")
		end
	end
	-- la pratique travaille les caractéristiques liées à cette compétence
	for stat, part in G.Config.STAT_FROM_SKILL[skill] or {} do
		J.addStatXp(player, stat, amount * part)
	end
end

-- Niveau de compétence suffisant ? (sinon message)
function J.needSkill(player: Player, skill: string, level: number, what: string?): boolean
	-- déblocage : niveau entraîné seulement (l'équipement aide à faire, pas à débloquer)
	if J.skillRaw(player, skill) >= level then
		return true
	end
	local info = G.Config.SKILLS[skill]
	G.Util.toast(player, (what or "Ça") .. " demande " .. info.icon .. " " .. info.name .. " " .. level .. " (tu es " .. J.skillRaw(player, skill) .. ").")
	return false
end

-- ----------------------------------------------------------------- Talents

function J.talent(player: Player, id: string): number
	local p = J.profiles[player]
	return p and (p.talents[id] or 0) or 0
end

function J.talentFree(player: Player): number
	local p = J.profiles[player]
	if not p then
		return 0
	end
	local spent = 0
	for _, r in p.talents do
		spent += r
	end
	return G.Config.talentPoints(J.totalSkills(p)) - spent
end

function J.learnTalent(player: Player, id: string)
	local p = J.profiles[player]
	local t = type(id) == "string" and G.Config.TALENT_BY_ID[id]
	if not p or not t then
		return
	end
	if J.talentFree(player) <= 0 then
		G.Util.toast(player, "Pas de point de talent libre (1 tous les 2 niveaux).")
		return
	end
	if (p.talents[id] or 0) >= t.max then
		return
	end
	local inTree = 0
	for tid, r in p.talents do
		local o = G.Config.TALENT_BY_ID[tid]
		if o and o.tree == t.tree then
			inTree += r
		end
	end
	if inTree < t.req then
		G.Util.toast(player, "Il faut d'abord " .. t.req .. " point(s) dans cette voie.")
		return
	end
	-- choix exclusif : un seul talent de maître par voie
	if t.excl then
		for tid, r in p.talents do
			local o = G.Config.TALENT_BY_ID[tid]
			if r > 0 and tid ~= id and o and o.excl == t.excl then
				G.Util.toast(player, "Choix exclusif : tu as déjà pris « " .. o.name .. " » (oublie tes talents pour changer).")
				return
			end
		end
	end
	p.talents[id] = (p.talents[id] or 0) + 1
	G.Util.toast(player, "Talent appris : " .. t.name .. " (rang " .. p.talents[id] .. ")", "big")
	J.applyStats(player)
	J.markDirty(player)
end

-- ----------------------------------------------------------------- Avis de recherche

-- Étoiles et prime au-dessus de la tête d'un joueur recherché (les chasseurs de primes le repèrent)
function J.refreshWanted(player: Player)
	local p = J.profiles[player]
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not p or not head then
		return
	end
	local bb = head:FindFirstChild("AvisRecherche")
	if (p.stars or 0) <= 0 then
		if bb then
			bb:Destroy()
		end
		return
	end
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = "AvisRecherche"
		bb.Size = UDim2.fromOffset(150, 40)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 160
		local t = Instance.new("TextLabel")
		t.Name = "T"
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.FredokaOne
		t.TextColor3 = Color3.fromRGB(255, 210, 70)
		t.TextStrokeTransparency = 0.2
		t.Parent = bb
		bb.Parent = head
	end
	bb.T.Text = string.rep("★", p.stars) .. "  " .. (p.bounty or 0) .. "💰"
end

-- Facteur de vue des PNJ (discrétion) : 1 = normal, moins = plus discret
function J.sightFactor(player: Player): number
	local s = J.stats(player)
	local f = 1 - math.min(0.6, (s.discretion or 0) * 0.05)
	f *= 1 - 0.15 * J.talent(player, "ombre")
	f *= 1 - 0.25 * J.talent(player, "fantome")
	if player:GetAttribute("Crouch") then
		f *= 0.6
	end
	return f
end

function J.applyStats(player: Player)
	local s = J.stats(player)
	player:SetAttribute("BaseSpeed", G.Config.WALK + (s.vitesse or 0) * 0.6)
	player:SetAttribute("Defense", s.defense or 0)
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum then
		local ratio = hum.Health / math.max(1, hum.MaxHealth)
		hum.MaxHealth = G.Config.MAX_HP + (s.vie or 0) * 10 + 15 * J.talent(player, "robuste") + 40 * J.talent(player, "colosse")
		hum.Health = hum.MaxHealth * ratio
	end
end

function J.equip(player: Player, id: number)
	local p = J.profiles[player]
	if not p then
		return
	end
	for i, item in p.gear do
		if item.id == id then
			local slot = G.Gear.slotOf(item)
			if not G.Gear.SLOTS[slot] then
				return
			end
			-- exigence de caractéristique (Shared/Equilibre) : la stat principale ENTRAÎNÉE (sans équipement)
			local okE, Eq = pcall(require, game:GetService("ReplicatedStorage").Shared.Equilibre)
			local req = okE and Eq.requirement(item)
			if req then
				local lv = req[3] == "skill" and J.skillRaw(player, req[1]) or G.Config.statLevel((p.statXp or {})[req[1]])
				if lv < req[2] then
					G.Util.toast(player, "Il faut " .. (req[4] or G.Gear.STATS[req[1]] or req[1]) .. " " .. req[2] .. " pour porter " .. item.name .. " (tu es à " .. lv .. ").")
					return
				end
			end
			item.slot = slot
			table.remove(p.gear, i)
			local old = p.equipped[item.slot]
			if old then
				table.insert(p.gear, old)
			end
			p.equipped[item.slot] = item
			J.applyStats(player)
			G.Avatar.refresh(player)
			J.markDirty(player)
			G.Util.toast(player, "Équipé : " .. item.name)
			-- panoplie complétée ? (Shared/Equilibre)
			local okS, EqS = pcall(require, game:GetService("ReplicatedStorage").Shared.Equilibre)
			if okS then
				local _, active = EqS.setBonus(p.equipped)
				for _, line in active do
					G.Util.toast(player, "🛡️ Panoplie " .. line, "gain")
				end
			end
			return
		end
	end
end

function J.unequip(player: Player, slot: string)
	local p = J.profiles[player]
	if not p or not p.equipped[slot] then
		return
	end
	table.insert(p.gear, p.equipped[slot])
	p.equipped[slot] = nil
	J.applyStats(player)
	G.Avatar.refresh(player)
	J.markDirty(player)
end

function J.dropGear(player: Player, id: number)
	local p = J.profiles[player]
	if not p then
		return
	end
	for i, item in p.gear do
		if item.id == id then
			table.remove(p.gear, i)
			-- revendu au poids : un peu d'or selon la rareté
			local gold = 10 * item.rarity * item.rarity
			p.inv.gold += gold
			G.Util.toast(player, item.name .. " démonté : +" .. gold .. " or")
			J.markDirty(player)
			return
		end
	end
end

function J.eat(player: Player, item: string)
	local info = G.Config.ITEMS[item]
	if info and info.use == "fertilize" then
		G.Farm.fertilize(player, item)
		return
	end
	if info and info.use == "fill" then
		G.Terraforme.fill(player)
		return
	end
	if info and info.use == "pour" then
		G.Terraforme.bucket(player)
		return
	end
	if info and info.lock then
		G.Protection.useLock(player, item)
		return
	end
	if info and info.use and string.sub(info.use, 1, 4) == "cat_" then
		J.useCatalogue(player, item, info)
		return
	end
	if not info or not info.food then
		return
	end
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	if J.take(player, item, 1) then
		-- manger dans une assiette, c'est mieux : +25 % de soin
		local heal = info.food
		if J.has(player, "plate") or J.has(player, "wood_plate") then
			heal = math.floor(heal * 1.25)
		end
		-- couverts (19/11) : fourchette et couteau dans le sac, +10 % chacun
		if J.has(player, "table_fork") then
			heal = math.floor(heal * 1.1)
		end
		if J.has(player, "table_knife") then
			heal = math.floor(heal * 1.1)
		end
		hum.Health = math.min(hum.MaxHealth, hum.Health + heal)
		G.Util.geste(player, "manger")
		G.Util.toast(player, "Miam ! " .. info.icon .. " (+" .. heal .. " vie)")
		-- effet de repas (Shared/Equilibre) : un plat cuisiné donne un bonus de quelques minutes
		if info.meal then
			J.addBuff(player, info.meal[1], info.meal[2], info.meal[3], info.name)
		end
		-- festin (Shared/Equilibre) : l'effet profite aussi aux joueurs autour (25 studs)
		if info.meal and info.feast then
			local me = G.Util.root(player)
			for _, other in G.Game.players() do
				local r = other ~= player and G.Util.root(other)
				if me and r and (r.Position - me.Position).Magnitude < 25 then
					J.addBuff(other, info.meal[1], info.meal[2], info.meal[3], info.name .. " (partagé par " .. player.DisplayName .. ")")
				end
			end
		end
	end
end

-- Objets utilisables du catalogue : livres (expérience), bourses (or), trésors, instruments, sacs
local lastTune = {}
function J.useCatalogue(player: Player, item: string, info)
	local use, arg = string.sub(info.use, 5), info.useArg
	if use == "musique" then
		-- un air joué : on ne le consomme pas ; les joueurs autour reprennent un peu de vie
		local now = os.clock()
		if lastTune[player] and now - lastTune[player] < 20 then
			return
		end
		lastTune[player] = now
		local root = G.Util.root(player)
		for _, p in G.Game.players() do
			local r = G.Util.root(p)
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if root and r and hum and hum.Health > 0 and (r.Position - root.Position).Magnitude < 40 then
				hum.Health = math.min(hum.MaxHealth, hum.Health + 10)
				G.Util.toast(p, "♪ " .. player.DisplayName .. " joue " .. info.icon)
			end
		end
		J.addSkillXp(player, "commerce", 1)
		return
	end
	if use == "boire" then
		-- gourde / outre : réutilisable (on la remplit aux rivières), rend de l'endurance
		local now = os.clock()
		-- l'outre (useArg 40) se reprend plus vite que la gourde (25)
		local cooldown = (tonumber(arg) or 25) >= 40 and 15 or 25
		if lastTune[player] and now - lastTune[player] < cooldown then
			G.Util.toast(player, "Tu viens de boire.")
			return
		end
		lastTune[player] = now
		local maxSt = player:GetAttribute("MaxStamina") or G.Config.MAX_STAMINA
		player:SetAttribute("Stamina", math.min(maxSt, (player:GetAttribute("Stamina") or 0) + (tonumber(arg) or 25)))
		player:SetAttribute("Desaltere", os.clock() + 300) -- la chaleur du désert ne pèse plus 5 min (Froid)
		G.Util.toast(player, info.icon .. " Une bonne gorgée : endurance retrouvée.")
		return
	elseif use == "nourrir" then
		if not G.Animals.feedNear(player) then
			G.Util.toast(player, "Approche-toi d'une de tes bêtes pour la nourrir.")
			return
		end
	elseif use == "page" then
		G.Chroniques.read(player) -- consomme la page seulement si elle apprend quelque chose
		return
	elseif use == "carte_tresor" then
		G.Journal.readTreasureMap(player) -- consomme la carte seulement si une cache est tracée
		return
	elseif use == "banniere" then
		G.Avantpostes.plant(player)
		return
	elseif use == "barque" or use == "voilier" then
		G.Barques.launch(player, use) -- retire l'objet du sac seulement si le bateau est posé
		return
	elseif use == "nasse" then
		G.Nasses.place(player) -- retire l'objet du sac seulement si la nasse est posée
		return
	elseif use == "ferrer" then
		G.Horses.shoe(player, item) -- retire les fers du sac seulement si la monture est ferrée
		return
	elseif use == "rappel" then
		local n = G.Animals.gather(player)
		local c = (G.Compagnons and rawget(G.Compagnons, "recall")) and G.Compagnons.recall(player) or 0
		G.Util.toast(player, (n + c) > 0 and ("🔔 Ding ding… " .. n .. " bête(s) te suivent" .. (c > 0 and (", " .. c .. " compagnon(s) accourent") or "") .. ".")
			or "🔔 Aucune de tes bêtes ne t'entend par ici.")
		return
	end
	if not J.take(player, item, 1) then
		return
	end
	if use == "nourrir" then
		J.addSkillXp(player, "elevage", 2)
	elseif use == "buff" then
		J.addBuff(player, arg or "charisme", 3, 20 * 60)
	elseif use == "planter" then
		if not G.Props.plant(player, arg) then
			J.add(player, item, 1, true) -- pas planté : la graine revient
		end
	elseif use == "recette" then
		local found = J.revealRecipes(player, arg ~= "" and arg or nil, info.useArg and 1 or 1)
		if not found then
			J.add(player, item, 1, true) -- tout est déjà connu : on garde le parchemin
			G.Util.toast(player, "Tu connais déjà tout ce qu'il enseigne.")
		end
	elseif use == "livre" then
		J.addSkillXp(player, arg or "artisanat", 60)
		G.Util.toast(player, info.icon .. " Tu étudies " .. info.name .. ".")
	elseif use == "bourse" then
		local n = math.random(math.floor((tonumber(arg) or 50) / 3), tonumber(arg) or 50)
		J.add(player, "gold", n)
	elseif use == "tresor" then
		local list = G.Config.Catalogue.TREASURE
		for _ = 1, math.random(2, 3) do
			local t = list[math.random(1, #list)]
			J.add(player, t[1], math.random(t[2], t[3]))
		end
		G.Util.toast(player, info.icon .. " Trouvé !")
	elseif use == "porter" then
		-- objet qui se porte (Shared/Equilibre E.WEAR) : devient une pièce d'équipement du sac
		local w = info.wearAs
		local p = J.profiles[player]
		if w and p then
			table.insert(p.gear, { slot = w[1], name = info.name, rarity = w[2], stats = table.clone(w[3]), power = 0, visual = "", id = math.random(1, 2 ^ 30) })
			G.Util.toast(player, info.icon .. " " .. info.name .. " rejoint ton équipement : à porter depuis la fiche [P].", "gain")
			J.markDirty(player)
		end
	elseif use == "etudier" then
		-- antiquité étudiée : entrée de collection, la Chance (connaissance du monde) progresse
		if G.Social and rawget(G.Social, "collect") then
			G.Social.collect(player, "trouvailles", item)
		end
		-- au musée d'un village (Systemes/Chantiers), l'étude rapporte deux fois plus
		local here = G.Quetes and rawget(G.Quetes, "nearVillage") and G.Quetes.nearVillage(player)
		local mult = (here and G.Chantiers and rawget(G.Chantiers, "built") and G.Chantiers.built(here.key, "musee")) and 2 or 1
		J.addStatXp(player, "chance", 40 * mult)
		J.addSkillXp(player, "commerce", 10 * mult)
		G.Util.toast(player, info.icon .. " Tu étudies " .. info.name .. " : ta connaissance du monde grandit.", "gain")
	elseif use == "deballer" then
		for part in string.gmatch(arg or "", "[^,]+") do
			local id, n = string.match(part, "^(.-):(%d+)$")
			if id and G.Config.ITEMS[id] then
				J.add(player, id, tonumber(n), true)
			end
		end
		G.Util.toast(player, info.icon .. " " .. info.name .. " déballé.", "gain")
	elseif use == "rendre" then
		-- à rapporter : le village où l'on se trouve t'en sait gré (Systemes/Reputation)
		local v = G.Quetes and rawget(G.Quetes, "nearVillage") and G.Quetes.nearVillage(player)
		if not v then
			J.add(player, item, 1, true)
			G.Util.toast(player, "Rapporte-le dans un village : on saura quoi en faire.")
		else
			G.Reputation.add(player, v, tonumber(arg) or 5)
			G.Util.toast(player, info.icon .. " " .. v.name .. " t'en est reconnaissant.", "gain")
		end
	elseif use == "graines" then
		local crops = G.Config.CROP_ORDER
		for _ = 1, 3 do
			J.add(player, "seed_" .. crops[math.random(1, #crops)], math.random(2, 4))
		end
	end
	J.sync(player)
end

-- ----------------------------------------------------------------- Carnet de recettes
-- On ne connaît au départ que quelques recettes ; les autres se découvrent en essayant des mélanges
-- dans la grille de l'atelier, ou en lisant une recette / un plan.

function J.knows(player: Player, key: string): boolean
	local p = J.profiles[player]
	return G.Config.STARTER_RECIPES[key] == true or (p ~= nil and p.known ~= nil and p.known[key] == true)
end

function J.learnRecipe(player: Player, key: string, silent: boolean?): boolean
	local p = J.profiles[player]
	if not p or J.knows(player, key) then
		return false
	end
	p.known = p.known or {}
	p.known[key] = true
	if not silent then
		local name = key
		local info = G.Config.ITEMS[key]
		if info then
			name = (info.icon or "") .. " " .. info.name
		elseif string.sub(key, 1, 5) == "gear:" then
			name = "🛡️ " .. string.sub(key, 6)
		end
		G.Util.toast(player, "📜 Recette découverte : " .. name, "gain")
	end
	J.markDirty(player)
	return true
end

-- Une recette encore inconnue (de l'onglet voulu si cat), à la portée du joueur
function J.revealRecipes(player: Player, cat: string?, n: number): boolean
	if J.has(player, "quill") then
		n += 1 -- avec une plume, on recopie une recette de plus
	end
	local pool = {}
	for _, r in G.Config.RECIPES do
		local key = G.Config.recipeKey(r)
		if not J.knows(player, key) and (not cat or r.cat == cat) then
			local lvl = r.skill and J.skillRaw(player, r.skill[1]) or 0 -- règle 4 : niveau entraîné
			if not r.skill or lvl + 6 >= r.skill[2] then
				table.insert(pool, key)
			end
		end
	end
	if #pool == 0 then
		return false
	end
	for _ = 1, n do
		if #pool == 0 then
			break
		end
		local key = table.remove(pool, math.random(1, #pool))
		J.learnRecipe(player, key)
	end
	return true
end

-- ----------------------------------------------------------------- Outils en main

local TOOL_TEMPLATE = { hoe = "Houe", can = "Arrosoir", shovel = "Pelle", axe = "Hache", pickaxe = "Pioche", rod = "Canne à pêche", club = "Gourdin", sword = "Épée", spade = "Pelle" }
-- barre d'outils : une case par famille (le meilleur outil possédé de la famille)
J.TOOL_ORDER = { "hoe", "can", "axe", "pickaxe", "shovel", "rod", "harpoon", "sword", "spade" }

-- Meilleur outil possédé d'une famille : id, palier (nil si aucun)
-- Usure des outils (18/11, Minecraft + grind) : chaque coup donné avec un outil l'use ; à bout, il
-- casse (un exemplaire en moins) et il faut en refaire un. Pierre < cuivre < fer.
function J.wearTool(player: Player, base: string, amount: number?)
	local p = J.profiles[player]
	local id, tier = J.bestTool(player, base)
	if not p or not id then
		return
	end
	p.wear = p.wear or {}
	local life = J.TOOL_LIFE[tier] or J.TOOL_LIFE[1]
	p.wear[id] = (p.wear[id] or 0) + (amount or 1)
	local left = life - p.wear[id]
	local info = G.Config.ITEMS[id]
	local name = info and info.name or id
	if left <= 0 then
		p.wear[id] = 0
		J.take(player, id, 1)
		G.Util.toast(player, "💥 " .. name .. " : brisée ! Il faut en refaire une (atelier).", "big")
		local root = G.Util.root and G.Util.root(player)
		if root and G.Util.sfx then
			G.Util.sfx("casse", root.Position)
		end
		J.sync(player)
	elseif left == math.floor(life * 0.1) then
		G.Util.toast(player, "⚠️ " .. name .. " presque usée (" .. left .. " coups).")
	end
	-- pour la barre d'usure sous l'icône (barre rapide)
	local after = J.bestTool(player, base)
	player:SetAttribute("Usure_" .. base, after and ((p.wear[after] or 0) / (J.TOOL_LIFE[G.Config.tierOf(after)] or life)) or 0)
end

function J.bestTool(player: Player, base: string): (string?, number)
	local p = J.profiles[player]
	if not p then
		return nil, 0
	end
	local fam = G.Config.TOOL_FAMILIES[base]
	if fam then
		for _, id in fam do
			if (p.inv[id] or 0) > 0 then
				if base == "sword" or G.Config.baseOf(id) == base then
					return id, G.Config.tierOf(id)
				end
			end
		end
		return nil, 0
	end
	if (p.inv[base] or 0) > 0 then
		return base, 1
	end
	return nil, 0
end

local function toolsOf(player: Player)
	local out = {}
	for _, c in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		if c then
			for _, t in c:GetChildren() do
				if t:IsA("Tool") and t:GetAttribute("ItemId") then
					out[t:GetAttribute("ItemId")] = t
				end
			end
		end
	end
	return out
end

function J.refreshTools(player: Player)
	local p = J.profiles[player]
	local bp = player:FindFirstChildOfClass("Backpack")
	if not p or not bp or not player.Character then
		return
	end
	local have = toolsOf(player)
	local want = {}
	local order = {}
	for _, base in J.TOOL_ORDER do
		local id = J.bestTool(player, base)
		if id then
			want[id] = true
			table.insert(order, id)
		end
	end
	for _, crop in G.Config.CROP_ORDER do
		local id = "seed_" .. crop
		if (p.inv[id] or 0) > 0 then
			want[id] = true
		end
	end
	-- retirer ce qui n'est plus possédé
	for id, t in have do
		if not want[id] then
			t:Destroy()
			have[id] = nil
		end
	end
	-- ajouter ce qui manque (dans l'ordre de la barre)
	for _, crop in G.Config.CROP_ORDER do
		table.insert(order, "seed_" .. crop)
	end
	for _, id in order do
		if want[id] and not have[id] then
			local seed = G.Config.ITEMS[id] and G.Config.ITEMS[id].seed
			local tpl = ServerStorage.Outils:FindFirstChild(id)
				or ServerStorage.Outils:FindFirstChild(seed and "Graines" or (TOOL_TEMPLATE[id] or TOOL_TEMPLATE[G.Config.baseOf(id)]))
			if tpl then
				local t = tpl:Clone()
				t:SetAttribute("ItemId", id)
				t.ManualActivationOnly = true
				if not seed then
					local info = G.Config.ITEMS[id]
					t.Name = info and info.name or t.Name
					local tint = not t:GetAttribute("PaletteDediee") and G.Config.TOOL_TINTS[G.Config.tierOf(id)]
					if tint and info and info.base then
						for _, d in t:GetDescendants() do
							if d:IsA("BasePart") and d.Material ~= Enum.Material.Wood and d.Material ~= Enum.Material.WoodPlanks and d.Name ~= "Handle" then
								d.Color = tint
								d.Material = Enum.Material.Metal
							end
						end
					end
				end
				if seed then
					t:SetAttribute("Seed", seed)
				end
				t.Activated:Connect(function()
					G.Tools.use(player, t)
				end)
				t.Parent = bp
				have[id] = t
			end
		end
	end
	-- noms des sachets de graines avec le nombre
	for id, t in have do
		local info = G.Config.ITEMS[id]
		if info and info.seed then
			t.Name = G.Config.CROPS[info.seed].name .. " ×" .. (p.inv[id] or 0)
		end
	end
end

-- ----------------------------------------------------------------- Envoi au client

function J.markDirty(player: Player)
	dirty[player] = true
end

function J.sync(player: Player)
	local p = J.profiles[player]
	if not p then
		return
	end
	dirty[player] = nil
	J.refreshTools(player)
	player:SetAttribute("Gold", p.inv.gold or 0)
	player:SetAttribute("Honor", p.honor)
	player:SetAttribute("Stars", p.stars)
	player:SetAttribute("Bounty", p.bounty or 0)
	J.refreshWanted(player)
	G.remotes.Inventory:FireClient(player, {
		skills = p.skills,
		talents = p.talents,
		titles = G.Social.titlesOf(player),
		col = { fish = G.Social.count(p, "fish"), creatures = G.Social.count(p, "creatures"), crops = G.Social.count(p, "crops"),
			ores = G.Social.count(p, "ores"), tames = G.Social.count(p, "tames"), worlds = G.Social.count(p, "worlds"),
			herbs = G.Social.count(p, "herbs") },
		talentFree = J.talentFree(player),
		bounty = p.bounty or 0,
		inv = p.inv,
		gear = p.gear,
		equipped = p.equipped,
		stats = J.stats(player),
		statXp = p.statXp or {},
		horse = p.horse and true or false,
		hotbar = p.hotbar,
		known = p.known or {},
		look = p.look,
		settings = p.settings,
		carte = G.Journal and G.Journal.keysFor and G.Journal.keysFor(player) or nil,
		tresor = p.treasures and G.world and p.treasures[G.world.id] or nil,
	})
end

function J.flush()
	for player in dirty do
		J.sync(player)
	end
end

return J
