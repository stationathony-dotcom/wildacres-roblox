-- Combat : frapper (poings, gourdin, épée, arme d'équipement) dans un cône devant soi,
-- recul, courte invulnérabilité ; dégâts reçus réduits par la défense.

local Debris = game:GetService("Debris")

local Combat = {}
local G
local cooldown = {}
local invuln = {}

local Armes = require(game:GetService("ReplicatedStorage").Shared.Armes)
local Equip = require(game:GetService("ReplicatedStorage").Shared.Equipement)

-- hâte (caractéristique) : cadence plus rapide, plafonnée
local function hate(player: Player): number
	local st = G.Joueurs.stats(player)
	return 1 - math.min(Equip.HATE_MAX, (st.hate or 0) * Equip.HATE_PAR_POINT)
end

-- usure d'une pièce portée (Shared/Equipement) ; brisée = plus de statistiques jusqu'à réparation
local function user(player: Player, slot: string?)
	local prof = G.Joueurs.get(player)
	local eq = prof and prof.equipped
	if not eq then
		return
	end
	if not slot then
		local slots = {}
		for k, piece in eq do
			if k ~= "weapon" and type(piece) == "table" and piece.duraMax then
				table.insert(slots, k)
			end
		end
		if #slots == 0 then
			return
		end
		slot = slots[math.random(1, #slots)]
	end
	local piece = eq[slot]
	if type(piece) ~= "table" or not piece.duraMax or (piece.dura or 0) <= 0 then
		return
	end
	piece.dura = (piece.dura or piece.duraMax) - 1
	if piece.dura <= 0 then
		G.Util.toast(player, "💔 " .. (piece.name or "Une pièce") .. " est brisée : fais-la réparer chez le forgeron ou l'armurier.", "danger")
		G.Joueurs.applyStats(player)
	end
	G.Joueurs.markDirty(player)
end
Combat.user = user
-- 26/11 (combat façon action-RPG) : enchaînements, garde / parade, esquive
local comboN, lastSwing = {}, {}
local garde, gardeStart, gardeBrisee = {}, {}, {}
local dodgeUntil, dodgeLast = {}, {}

local SAFE_SPAWN_R = 60 -- studs autour de l'arrivée : pas de combat entre joueurs
local KO_GRACE = 600 -- s : protection contre celui qui vient de te mettre K.O.
local koBy = {} -- UserId victime -> { [UserId agresseur] = os.clock() }

function Combat.init(g)
	G = g
	G.Interact.onAction("hit", function(player, data)
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		local target = type(data) == "table" and type(data.target) == "string" and data.target or nil
		local charge = type(data) == "table" and tonumber(data.charge) or nil
		if charge and (charge ~= charge or charge < 0) then
			charge = nil -- « nan » refusé
		end
		if not (tool and G.Tools.use(player, tool, target)) then
			Combat.attack(player, nil, target, charge and math.min(charge, Armes.CHARGE_MAX) or nil)
		end
	end)
	-- garde ([Z] maintenu) : le serveur décide de tout (coût, bris de garde, parade)
	G.Interact.onAction("garde", function(player, data)
		Combat.setGuard(player, type(data) == "table" and data.on == true)
	end)
	-- esquive ([Alt]) : invulnérabilité brève payée en endurance ; le client fait la roulade
	G.Interact.onAction("esquive", function(player)
		Combat.dodge(player)
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		cooldown[p] = nil
		invuln[p] = nil
		comboN[p], lastSwing[p], garde[p], gardeStart[p], gardeBrisee[p], dodgeUntil[p], dodgeLast[p] = nil, nil, nil, nil, nil, nil, nil
	end)
end

function Combat.damageOf(player: Player, itemId: string?): number
	local prof = G.Joueurs.get(player)
	local base = 10
	local info = itemId and G.Config.ITEMS[itemId]
	if info and info.weapon then
		base = info.weapon * 10
	elseif itemId and (G.Config.baseOf(itemId) == "axe" or G.Config.baseOf(itemId) == "pickaxe") then
		base = 10 + 5 * G.Config.tierOf(itemId)
	end
	local w = prof and prof.equipped.weapon
	if w and not (w.duraMax and type(w.dura) == "number" and w.dura <= 0) then -- arme brisée : plus de puissance jusqu'à réparation
		base = math.max(base, (w.power or 1) * 10)
	end
	local st = G.Joueurs.stats(player)
	local force = st.force or 0
	local dmg = (base + force * 3) * (1 + 0.01 * G.Joueurs.skill(player, "combat"))
		* (1 + (st.maitrise or 0) * Equip.MAITRISE_PAR_POINT) -- maîtrise d'équipement (affixes)
	-- critique : talent + caractéristique Critique (Shared/Equipement, plafonnée)
	local crit = 0.12 * G.Joueurs.talent(player, "critique") + math.min(Equip.CRIT_MAX, (st.critique or 0) * Equip.CRIT_PAR_POINT)
	if math.random() < crit then
		dmg *= 2
	end
	-- Guerrier (spécialisation) : armes lourdes +6 %
	if player:GetAttribute("Specialisation") == "guerrier" then
		dmg *= Equip.SPEC_PASSIF.guerrier
	end
	return math.floor(dmg)
end

-- ----------------------------------------------------------------- Profils d'armes (Shared/Armes)
local function formeArme(player: Player)
	local prof = G.Joueurs.get(player)
	local w = prof and prof.equipped and prof.equipped.weapon
	if not w then
		return nil, nil
	end
	local okD, Design = pcall(require, game:GetService("ReplicatedStorage").Shared.GearDesign)
	return w, okD and Design.formOf(w) or nil
end

-- clé de profil (corps à corps) : outil tenu (épée, gourdin, hache, pioche), sinon l'arme portée, sinon poings
function Combat.profil(player: Player, itemId: string?): (string, any)
	local base = itemId and G.Config.baseOf and G.Config.baseOf(itemId)
	if base and Armes.DE_OUTIL[base] then
		return Armes.DE_OUTIL[base], Armes.profil(Armes.DE_OUTIL[base])
	end
	local w, form = formeArme(player)
	if not w then
		return "poing", Armes.profil("poing")
	end
	local k = Armes.DE_FORME[form or ""] or "epee"
	return k, Armes.profil(k)
end

function Combat.profilDistance(player: Player): (string, any)
	local _, form = formeArme(player)
	local k = Armes.DE_FORME_DIST[form or ""] or "arc"
	return k, Armes.DISTANCE[k]
end

-- endurance (attribut Stamina, relu par Game.step) : vrai si on avait de quoi payer
local function spend(player: Player, n: number): boolean
	local st = player:GetAttribute("Stamina") or G.Config.MAX_STAMINA or 100
	if st < n then
		player:SetAttribute("Stamina", 0)
		return false
	end
	player:SetAttribute("Stamina", st - n)
	return true
end
Combat.spendStamina = spend

-- maîtrise par famille : +0,5 % par niveau (Shared/Armes) ; chaque coup qui porte l'entraîne
local function maitrise(player: Player, cle: string): number
	local prof = G.Joueurs.get(player)
	local xp = prof and prof.maitrise and prof.maitrise[cle] or 0
	return 1 + Armes.maitriseNiveau(xp) * Armes.MAITRISE_PAR_NIVEAU
end
local function entrainer(player: Player, cle: string)
	local prof = G.Joueurs.get(player)
	if not prof then
		return
	end
	prof.maitrise = prof.maitrise or {}
	local before = Armes.maitriseNiveau(prof.maitrise[cle])
	prof.maitrise[cle] = (prof.maitrise[cle] or 0) + 1
	local after = Armes.maitriseNiveau(prof.maitrise[cle])
	if after > before and after % 5 == 0 then
		local nom = (Armes.PROFILS[cle] or Armes.DISTANCE[cle] or {}).nom or cle
		G.Util.toast(player, "⚔️ Maîtrise : " .. nom .. " niveau " .. after .. " (+" .. math.floor(after * Armes.MAITRISE_PAR_NIVEAU * 100 + 0.5) .. " % de dégâts).", "gain")
	end
	player:SetAttribute("Maitrise_" .. cle, after)
	G.Joueurs.markDirty(player)
end

local function hasShield(player: Player): boolean
	local prof = G.Joueurs.get(player)
	local o = prof and prof.equipped and prof.equipped.offhand
	local n = o and string.lower(o.name or "") or ""
	return o ~= nil and (string.find(n, "bouclier") ~= nil or string.find(n, "pavois") ~= nil or string.find(n, "écu") ~= nil)
end
Combat.hasShield = hasShield

function Combat.setGuard(player: Player, on: boolean)
	local now = os.clock()
	if on and (gardeBrisee[player] or 0) > now then
		on = false
	end
	if on and not garde[player] then
		gardeStart[player] = now
	end
	garde[player] = on or nil
	player:SetAttribute("Garde", on and (hasShield(player) and "bouclier" or "arme") or nil)
end

function Combat.dodge(player: Player)
	local now = os.clock()
	if (dodgeLast[player] or 0) + Armes.ESQUIVE_CD > now or player:GetAttribute("Riding") or player:GetAttribute("Carrying") then
		return
	end
	if not spend(player, Armes.ESQUIVE_COUT) then
		return
	end
	dodgeLast[player] = now
	dodgeUntil[player] = now + Armes.ESQUIVE_INVULN
	G.Util.geste(player, "esquive")
end

function Combat.popup(at: Vector3, text: string, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one * 0.2
	p.CFrame = CFrame.new(at)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(80, 36)
	bb.AlwaysOnTop = true
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.2
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.Parent = bb
	bb.Parent = p
	p.Parent = workspace
	task.spawn(function()
		for i = 1, 12 do
			p.CFrame = p.CFrame + Vector3.new(0, 0.12, 0)
			t.TextTransparency = i / 14
			task.wait(0.04)
		end
		p:Destroy()
	end)
end

function Combat.swoosh(player: Player)
	local root = G.Util.root(player)
	if not root then
		return
	end
	G.remotes.Fx:FireAllClients("swing", root.Position + root.CFrame.LookVector * 3)
end

-- applique un coup (corps à corps ou flèche) à la cible choisie
-- Effets des armes de créatures (Shared/Equilibre) : venin = 3 piqûres (15 % des dégâts) ; feu =
-- 2 brûlures (20 %) ; givre = l'ennemi ralentit de 40 % pendant 3 s (Enemies : moveToward).
local FX_COLOR = { venin = Color3.fromRGB(120, 220, 90), feu = Color3.fromRGB(255, 150, 60), saigne = Color3.fromRGB(200, 40, 40) }
local function weaponEffect(player: Player, en, fx: string, dmg: number)
	if fx == "givre" then
		en.slowUntil = os.clock() + 3
		return
	end
	local ticks, part = 3, 0.15
	if fx == "feu" then
		ticks, part = 2, 0.2
	elseif fx == "saigne" then
		ticks, part = 3, 0.1 -- sabre (Shared/Armes) : saignement
	end
	task.spawn(function()
		for _ = 1, ticks do
			task.wait(1)
			if en.dead or not (en.model and en.model.Parent) then
				return
			end
			local d = math.max(1, math.floor(dmg * part))
			en.invuln = 0
			G.Enemies.hit(en, d, player)
			if en.pos then
				Combat.popup(en.pos + Vector3.new(0, 4, 0), tostring(d), FX_COLOR[fx] or Color3.new(1, 1, 1))
			end
		end
	end)
end

local function applyHit(player: Player, best, kind: string, dmg: number, root: BasePart, opts)
	if kind == "enemy" then
		G.Enemies.hit(best, dmg, player)
		local wprof = G.Joueurs.get(player)
		local w = wprof and wprof.equipped and wprof.equipped.weapon
		if w and w.effect then
			weaponEffect(player, best, w.effect, dmg)
		end
	elseif kind == "npc" then
		G.Npcs.hit(best, dmg, player)
	elseif kind == "animal" then
		G.Animals.hit(best, player)
	elseif kind == "pet" then
		G.Compagnons.hit(best, dmg, player)
	elseif kind == "dummy" then
		-- mannequin : on voit ses dégâts, un peu d'XP de combat (plafonnée : 150 par jour)
		Combat.popup(Vector3.new(best.x, G.Util.groundY(best.x, best.z) + 5, best.z), tostring(dmg), Color3.fromRGB(255, 230, 150))
		G.Joueurs.addSkillXpCapped(player, "combat", 2, "mannequin", 150)
	elseif kind == "player" then
		local victim = best :: Player
		local vprof = G.Joueurs.get(victim)
		local vroot = G.Util.root(victim)
		if not vprof or not vroot then
			return
		end
		if not G.Config.LIBRE.bouclierArrivee then
			-- monde libre : pas de bouclier d'arrivée
		elseif os.clock() < (victim:GetAttribute("SpawnShield") or 0) or os.clock() < (player:GetAttribute("SpawnShield") or 0) then
			G.Util.toast(player, "Protection d'arrivée : pas de combat entre joueurs pendant 20 s.")
			return
		end
		-- zone sûre : l'arrivée du monde (pas d'embuscade sur ceux qui débarquent)
		if G.Config.LIBRE.zoneSureArrivee and (vroot.Position - G.Game.spawnPos()).Magnitude < SAFE_SPAWN_R then
			G.Util.toast(player, "On ne se bat pas sur le lieu d'arrivée.")
			return
		end
		-- anti-acharnement : celui qui t'a mis K.O. ne peut plus te frapper pendant 10 minutes
		local k = koBy[victim.UserId]
		if G.Config.LIBRE.graceApresKO and k and k[player.UserId] and os.clock() - k[player.UserId] < KO_GRACE then
			G.Util.toast(player, victim.DisplayName .. " vient de se relever : laisse-le tranquille un moment.")
			return
		end
		-- duel consenti (Systemes/Duels) : pas de crime entre les deux duellistes
		if (vprof.stars or 0) <= 0 and not (G.Duels and rawget(G.Duels, "paired") and G.Duels.paired(player, victim)) then
			G.Law.crime(player, "assault", vroot.Position, G.Util.pid(victim))
		end
		victim:SetAttribute("LastHitBy", player.UserId)
		victim:SetAttribute("LastHitAt", os.clock())
		Combat.hurtPlayer(victim, dmg, root.Position, { source = player, armure = opts and opts.armure, garde = opts and opts.garde })
		Combat.popup(vroot.Position + Vector3.new(0, 3, 0), tostring(dmg), Color3.fromRGB(255, 120, 100))
	end
end

-- Multiplicateur propre à la cible : résistance de la créature au type de dégâts, coup dans le dos (dague)
local function cibleMult(best, kind: string, typ: string, prof, root: BasePart): number
	local m = 1
	if kind == "enemy" and best.k then
		local r = (best.k.resist and best.k.resist[typ]) or (Armes.RESIST[best.k.form or ""] or {})[typ]
		m *= r or 1
		if prof.dos and best.model then
			local face = best.model:GetPivot().LookVector
			local d = Vector3.new(best.pos.X - root.Position.X, 0, best.pos.Z - root.Position.Z)
			if d.Magnitude > 0.1 and face:Dot(d.Unit) > 0.4 then
				m *= prof.dos -- on la frappe dans le dos
				if root.Parent and root.Parent:IsA("Model") then
					local pl = game:GetService("Players"):GetPlayerFromCharacter(root.Parent)
					if pl and pl:GetAttribute("Specialisation") == "ombre" then
						m *= Equip.SPEC_PASSIF.ombre
					end
				end
			end
		end
	end
	return m
end

-- Tir à l'arc (19/11) : un arc ou une arbalète équipés tirent à distance (RANGE studs) une FLÈCHE
-- (objet « arrow », fabriqué à l'établi) ; il faut voir sa cible (rien entre les deux). La cible
-- choisie (clic) passe en priorité, sinon ce qui est le plus en face. Une flèche part même dans le
-- vide (et se perd). Cadence plus lente qu'à l'épée.
Combat.RANGE = 48
Combat.BOW_COOLDOWN = 0.9
local function rangedWeapon(player: Player)
	local prof = G.Joueurs.get(player)
	local w = prof and prof.equipped and prof.equipped.weapon
	local n = w and w.name or ""
	if w and (w.ranged or string.find(n, "^Arc") or string.find(n, "Arbal")) then
		return w
	end
	return nil
end
Combat.rangedWeapon = rangedWeapon

-- Famille de geste et de son de l'attaque (client Gestes : taille, estoc, lourd, poing, tir, lancer).
-- Outil tenu (hache, pioche…) d'abord, sinon la forme de l'arme portée (Shared/GearDesign), sinon le poing.
local FAMILLE_FORME = {
	sword = "taille", saber = "taille", scythe = "taille", reaper = "taille", greatsword = "lourd", dagger = "estoc",
	pike = "estoc", longpike = "estoc", halberd = "lourd", javelin = "lancer", axe = "lourd", mace = "lourd",
	hammer = "lourd", club = "lourd", staff = "lourd", bow = "tir", shortbow = "tir", longbow = "tir", crossbow = "tir",
}
local IMPACT = { taille = "impact_lame", estoc = "impact_lame", lourd = "impact_sourd", poing = "impact_poing", tir = "impact_lame", lancer = "impact_lame" }
local function famille(player: Player, itemId: string?): string
	local base = itemId and G.Config.baseOf and G.Config.baseOf(itemId)
	if base == "sword" then
		return "taille"
	elseif base == "club" or base == "axe" or base == "pickaxe" or base == "hammer" then
		return "lourd"
	end
	local prof = G.Joueurs.get(player)
	local w = prof and prof.equipped and prof.equipped.weapon
	if not w then
		return "poing"
	end
	local okD, Design = pcall(require, game:GetService("ReplicatedStorage").Shared.GearDesign)
	local form = okD and Design.formOf(w) or nil
	return FAMILLE_FORME[form or ""] or "taille"
end
Combat.famille = famille

local function arrowFx(from: Vector3, to: Vector3)
	local d = to - from
	if d.Magnitude < 1 then
		return
	end
	local a = Instance.new("Part")
	a.Name = "Fleche"
	a.Anchored = true
	a.CanCollide = false
	a.CanQuery = false
	a.CanTouch = false
	a.CastShadow = false
	a.Size = Vector3.new(0.15, 0.15, 2.4)
	a.Color = Color3.fromRGB(120, 84, 50)
	a.Material = Enum.Material.Wood
	a.CFrame = CFrame.lookAt(from, to)
	a.Parent = workspace
	game:GetService("TweenService"):Create(a, TweenInfo.new(d.Magnitude / 140, Enum.EasingStyle.Linear), { CFrame = CFrame.lookAt(to, to + d.Unit) }):Play()
	game:GetService("Debris"):AddItem(a, d.Magnitude / 140 + 1.5)
end

function Combat.shoot(player: Player, targetId: string?, charge: number?)
	local root = G.Util.root(player)
	if not root or player:GetAttribute("Carrying") then
		return
	end
	-- munitions : flèches, sinon carreaux (19/11 : les carreaux n'avaient aucun usage)
	-- arme de jet (Shared/Equilibre) : sa propre munition (pierres, javelots, couteaux) ; sinon flèches puis carreaux
	local w = rangedWeapon(player)
	local ammoOf = w and w.ammo
	local okE, Eq = pcall(require, game:GetService("ReplicatedStorage").Shared.Equilibre)
	local ammoUsed
	if ammoOf then
		ammoUsed = G.Joueurs.take(player, ammoOf, 1) and ammoOf or nil
	else
		for _, a in (okE and Eq.BOW_AMMO) or { "arrow", "bolt", "bolt_heavy" } do
			if G.Joueurs.take(player, a, 1) then
				ammoUsed = a
				break
			end
		end
	end
	local hasAmmo = ammoUsed ~= nil
	if not hasAmmo then
		local names = { stone = "⛰️ Plus de pierres pour la fronde.", javelin = "🔱 Plus de javelots. (Établi : planche, fer et plume.)", throwing_knife = "🔪 Plus de couteaux de lancer. (Enclume : fer.)", throwing_axe = "⚔️ Plus de haches de jet. (Enclume : fer et planche.)" }
		G.Util.toast(player, names[ammoOf or ""] or "🏹 Plus de flèches. (Établi : bois, silex et plume.)")
		return
	end
	local cle, prof = Combat.profilDistance(player)
	local k = (charge and charge >= Armes.CHARGE_MIN) and math.min(1, charge / Armes.CHARGE_MAX) or 0
	local RANGE = prof.portee * (1 + 0.4 * k) * (player:GetAttribute("Specialisation") == "rodeur" and Equip.SPEC_PASSIF.rodeur or 1)
	local fatigue = spend(player, prof.endu * (k > 0 and 2 or 1)) and 1 or 0.6
	local char = player.Character
	local from = root.Position + Vector3.new(0, 1.2, 0) + root.CFrame.LookVector * 1.5
	local look = root.CFrame.LookVector
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function visible(pos: Vector3, model: Instance?): boolean
		params.FilterDescendantsInstances = { char, model }
		local r = workspace:Raycast(from, pos - from, params)
		return r == nil
	end
	local best, bestScore, kind, aim = nil, -math.huge, nil, nil
	local function consider(pos: Vector3, target, k: string, model: Instance?)
		local d = pos - root.Position
		local dist = d.Magnitude
		if dist > RANGE or dist < 0.5 then
			return
		end
		local dot = look:Dot(d.Unit)
		if dot < prof.vise then
			return
		end
		local score = dot * 2 - dist / RANGE
		if score > bestScore and visible(pos, model) then
			best, bestScore, kind, aim = target, score, k, pos
		end
	end
	local chosen = targetId and G.Enemies.byId(targetId)
	if chosen and not chosen.dead and chosen.model.Parent then
		local d = chosen.pos - root.Position
		if d.Magnitude <= RANGE and visible(chosen.pos, chosen.model) then
			best, kind, aim = chosen, "enemy", chosen.pos
			local flat = Vector3.new(d.X, 0, d.Z)
			if flat.Magnitude > 0.1 then
				root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
			end
		end
	end
	if not best then
		for _, en in G.Enemies.list do
			if not en.dead and en.model.Parent then
				consider(en.pos, en, "enemy", en.model)
			end
		end
		for _, a in G.Animals.list or {} do
			if a.model.Parent then
				consider(a.pos, a, "animal", a.model)
			end
		end
		for _, e in G.Npcs.list do
			if e.model.Parent and e.state ~= "ko" and e.state ~= "carried" and e.state ~= "gone" and not e.data.child then
				consider(e.root.Position, e, "npc", e.model)
			end
		end
		for _, other in G.Game.players() do
			local r = other ~= player and G.Util.root(other)
			if r then
				consider(r.Position, other, "player", other.Character)
			end
		end
		-- mannequins d'entraînement posés (Shared/Equilibre)
		for _, reg in G.World.loaded do
			for _, m in (reg.placedFolder and reg.placedFolder:GetChildren()) or {} do
				if m:IsA("Model") and m:GetAttribute("Mannequin") then
					local pos = m:GetPivot().Position + Vector3.new(0, 2.5, 0)
					consider(pos, { x = pos.X, z = pos.Z }, "dummy", m)
				end
			end
		end
	end
	G.Util.geste(player, (ammoOf == "javelin" or ammoOf == "throwing_knife" or ammoOf == "throwing_axe" or ammoOf == "stone") and "lancer" or "tir")
	G.Util.sfx("coup", root.Position)
	if not best then
		arrowFx(from, from + look * RANGE)
		return
	end
	arrowFx(from, aim + Vector3.new(0, 0.8, 0))
	local typ = Armes.TYPE_MUNITION[ammoUsed or ""] or prof.type
	local mult = prof.mult * (1 + Armes.CHARGE_BONUS * k) * fatigue * maitrise(player, cle) * cibleMult(best, kind, typ, {}, root)
	if prof.loin and (aim - from).Magnitude > 40 then
		mult *= prof.loin -- arc long : il paie à grande distance
	end
	if k >= 0.8 and (kind == "npc" or kind == "player") and math.random() < Armes.TETE_CHANCE then
		mult *= Armes.TETE_MULT
		Combat.popup(aim + Vector3.new(0, 4.5, 0), "En pleine tête !", Color3.fromRGB(255, 210, 90))
	end
	local dmg = math.floor(Combat.damageOf(player, nil) * ((okE and Eq.AMMO_DMG and Eq.AMMO_DMG[ammoUsed]) or 1) * mult)
	G.Joueurs.addSkillXp(player, "combat", 1)
	entrainer(player, cle)
	task.delay((aim - from).Magnitude / 140, function()
		if player.Parent and root.Parent then
			applyHit(player, best, kind, dmg, root, { armure = prof.armure })
			if ammoUsed == "arrow_barbed" and kind == "enemy" then
				weaponEffect(player, best, "saigne", dmg) -- flèche barbelée : saignement
			end
		end
	end)
end

function Combat.attack(player: Player, itemId: string?, targetId: string?, charge: number?)
	local now = os.clock()
	local charged = charge ~= nil and charge >= Armes.CHARGE_MIN
	-- arc équipé et rien d'autre en main (une épée ou un outil tenus frappent au corps à corps)
	local held = itemId and G.Config.ITEMS[itemId]
	if rangedWeapon(player) and (held == nil or not (held.weapon or held.tool)) then
		local _, dprof = Combat.profilDistance(player)
		-- un tir chargé suit le tir de l'appui : il lui faut seulement la durée minimale de charge
		if cooldown[player] and now - cooldown[player] < (charged and math.min(dprof.cd * 1.3, Armes.CHARGE_MIN - 0.05) or dprof.cd * hate(player)) then
			return
		end
		cooldown[player] = now
		return Combat.shoot(player, targetId, charge)
	end
	local cle, prof = Combat.profil(player, itemId)
	if cooldown[player] and now - cooldown[player] < (charged and math.min(prof.cd * 1.5, Armes.CHARGE_MIN - 0.05) or prof.cd * hate(player)) then
		return
	end
	if garde[player] then
		Combat.setGuard(player, false) -- on ne frappe pas en gardant
	end
	cooldown[player] = now
	-- enchaînement : coups rapprochés → 1, 2, 3 (le 3e est le coup final)
	if lastSwing[player] and now - lastSwing[player] < prof.cd + Armes.COMBO_FENETRE then
		comboN[player] = (comboN[player] or 0) % 3 + 1
	else
		comboN[player] = 1
	end
	lastSwing[player] = now
	player:SetAttribute("Combo", comboN[player])
	player:SetAttribute("CoupCharge", charged or nil)
	local root = G.Util.root(player)
	if not root or player:GetAttribute("Carrying") then
		return
	end
	local fam = famille(player, itemId)
	G.Util.geste(player, fam) -- geste du coup (client Gestes), son de l'arme dans le vide compris
	Combat.swoosh(player)
	local fatigue = spend(player, prof.endu * (charged and 2 or 1)) and 1 or 0.6 -- à bout de souffle : coup mou
	local kc = charged and math.min(1, charge / Armes.CHARGE_MAX) or 0
	local dmg = Combat.damageOf(player, itemId) * prof.mult * fatigue * maitrise(player, cle)
		* (comboN[player] == 3 and Armes.COMBO_FINAL or 1) * (1 + Armes.CHARGE_BONUS * kc)
	if prof.charge and player:GetAttribute("Riding") then
		dmg *= prof.charge -- lance en selle : charge
	end
	local look = root.CFrame.LookVector
	local reachMax = prof.portee * (charged and 1.15 or 1)
	local best, bd, kind = nil, reachMax, nil
	local hits = {} -- cibles possibles (armes qui touchent plusieurs ennemis : espadon, hast)
	local function consider(pos: Vector3, target, k: string, reach: number)
		local d = pos - root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		local dist = flat.Magnitude - reach
		if dist < reachMax and math.abs(d.Y) < 8 and (flat.Magnitude < 3 or look:Dot(flat.Unit) > (prof.cone or 0.35)) then
			table.insert(hits, { t = target, k = k, d = dist })
			if dist < bd then
				best, bd, kind = target, dist, k
			end
		end
	end
	-- cible choisie (clic façon WoW) : frappée en priorité si elle est à portée, on se tourne vers elle
	local chosen = targetId and G.Enemies.byId(targetId)
	if chosen and chosen.model.Parent then
		local d = chosen.pos - root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude - (chosen.radius or 1.5) < reachMax and math.abs(d.Y) < 8 then
			best, bd, kind = chosen, -1e9, "enemy"
			if flat.Magnitude > 0.1 then
				root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
			end
		end
	end
	for _, en in G.Enemies.list do
		if not en.dead and en.model.Parent then
			consider(en.pos, en, "enemy", en.radius or 1.5)
		end
	end
	for _, e in G.Npcs.list do
		-- les enfants ne sont jamais des cibles
		if e.model.Parent and e.state ~= "ko" and e.state ~= "carried" and e.state ~= "gone" and not e.data.child then
			consider(e.root.Position, e, "npc", 1)
		end
	end
	for _, a in G.Animals.list or {} do
		if a.model.Parent then
			consider(a.pos, a, "animal", 1.5)
		end
	end
	for _, pet in G.Compagnons.list do
		if not pet.dead and pet.model.Parent and not G.Util.owns(player, pet.owner) then
			consider(pet.pos, pet, "pet", pet.radius or 1.2)
		end
	end
	-- les autres joueurs : légal sur un recherché (chasse aux primes), agression sinon
	for _, other in G.Game.players() do
		local r = other ~= player and G.Util.root(other)
		if r then
			consider(r.Position, other, "player", 1)
		end
	end
	if not best then
		return
	end
	-- l'arme qui touche s'use (comme les outils : elle finit par casser, cf. Joueurs.wearTool)
	if itemId and G.Joueurs.wearTool then
		local base = G.Config.baseOf(itemId)
		if base == "sword" or base == "club" or base == "axe" or base == "pickaxe" then
			G.Joueurs.wearTool(player, base)
		end
	end
	local at = (best.pos or (best.root and best.root.Position) or (G.Util.root(best) and G.Util.root(best).Position)) or root.Position
	if typeof(at) == "Vector3" then
		G.Util.sfx(IMPACT[fam] or "impact_lame", at) -- le coup porte : lame, choc sourd ou poing
	end
	-- la cible choisie d'abord, puis les plus proches (multi : espadon 3, hast 2)
	local list = { { t = best, k = kind } }
	if (prof.multi or 1) > 1 then
		table.sort(hits, function(a, b)
			return a.d < b.d
		end)
		for _, h in hits do
			if #list >= prof.multi then
				break
			end
			if h.t ~= best and h.k ~= "player" then -- le balayage n'emporte pas d'autres joueurs par mégarde
				table.insert(list, h)
			end
		end
	end
	for _, h in list do
		local d = math.max(1, math.floor(dmg * cibleMult(h.t, h.k, prof.type, prof, root)))
		applyHit(player, h.t, h.k, d, root, { armure = prof.armure, garde = prof.garde })
		if prof.saigne and h.k == "enemy" then
			weaponEffect(player, h.t, "saigne", d)
		end
	end
	entrainer(player, cle)
	user(player, "weapon")
end

-- Appelé par Game.onDeath quand un joueur est mis K.O. par un autre
function Combat.noteKO(victim: Player, attackerId: number)
	koBy[victim.UserId] = koBy[victim.UserId] or {}
	koBy[victim.UserId][attackerId] = os.clock()
end

function Combat.hurtPlayer(player: Player, dmg: number, fromPos: Vector3?, opts)
	local now = os.clock()
	if (dodgeUntil[player] or 0) > now then
		return -- esquive : le coup passe à côté
	end
	if invuln[player] and now - invuln[player] < 0.6 then
		return
	end
	-- « Peau de pierre » (Systemes/Magie) : dégâts divisés par deux
	if G.Magie and rawget(G.Magie, "damageMult") then
		dmg *= G.Magie.damageMult(player)
	end
	-- garde : seulement contre un coup venu de face
	local root = G.Util.root(player)
	if garde[player] and fromPos and root then
		local d = Vector3.new(fromPos.X - root.Position.X, 0, fromPos.Z - root.Position.Z)
		if d.Magnitude < 0.1 or root.CFrame.LookVector:Dot(d.Unit) > Armes.GARDE_CONE then
			local src = opts and opts.source
			if now - (gardeStart[player] or 0) < Armes.PARADE then
				-- PARADE : rien ne passe, riposte sur l'attaquant (sonné)
				G.Util.sfx("impact_metal", root.Position)
				Combat.popup(root.Position + Vector3.new(0, 4, 0), "Paré !", Color3.fromRGB(255, 230, 140))
				local rip = math.floor(Combat.damageOf(player, nil) * Armes.PARADE_RIPOSTE)
				if type(src) == "table" and src.k and not src.dead then
					src.invuln = 0
					G.Enemies.hit(src, rip, player)
					src.slowUntil = now + 1.5
				elseif typeof(src) == "Instance" and src:IsA("Player") then
					spend(src, 25)
				end
				invuln[player] = now
				return
			end
			local pass = hasShield(player) and Armes.GARDE_BOUCLIER or Armes.GARDE_ARME
			local cost = dmg * (1 - pass) * Armes.GARDE_COUT * ((opts and opts.garde) or 1)
				* (player:GetAttribute("Specialisation") == "gardien" and Equip.SPEC_PASSIF.gardien or 1)
			if spend(player, cost) then
				G.Util.sfx("impact_metal", root.Position)
				dmg = math.max(1, math.floor(dmg * pass))
			else
				-- garde brisée : à bout de souffle, plus de garde pendant un moment
				gardeBrisee[player] = now + Armes.GARDE_BRISEE
				Combat.setGuard(player, false)
				G.Util.sfx("casse", root.Position)
			end
		end
	end
	invuln[player] = now
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	local def = (G.Joueurs.stats(player).defense or 0) * (1 - ((opts and opts.armure) or 0)) -- masse, arbalète : percent l'armure
	-- caparaçon dans le sac : protège le cavalier tant qu'il est en selle (Shared/Equilibre.CAPARISON_DEF)
	if player:GetAttribute("Riding") and G.Joueurs.has(player, "caparison") then
		local okE, Eq = pcall(require, game:GetService("ReplicatedStorage").Shared.Equilibre)
		def += okE and Eq.CAPARISON_DEF or 0
	end
	local real = math.max(1, math.floor(dmg * (1 - math.min(0.6, def * 0.04))))
	hum:TakeDamage(real)
	user(player, nil) -- une pièce d'armure au hasard s'use
	G.remotes.Fx:FireClient(player, "hurt", fromPos)
end

return Combat
