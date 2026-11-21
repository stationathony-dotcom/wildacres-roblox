-- Vie sociale : collections et titres (affichés dans la liste des joueurs), groupes d'aventure.
--  · Collections (perso global) : poissons pêchés, créatures vaincues, cultures récoltées, minerais,
--    bêtes apprivoisées, mondes visités. Chaque collection complétée (ou palier) débloque un titre.
--  · Groupes (5 max, par serveur) : invitation [U] au-dessus d'un joueur, membres en surbrillance,
--    +10 % d'expérience quand un membre est proche.

local Players = game:GetService("Players")

local Social = {}
local G, Config

local groups = {} -- joueur -> groupe {members = {...}, leader}
local invites = {} -- invité -> qui invite

-- Titres : id -> {nom, condition(profil) -> bool}
local TITLES = {
	{ id = "novice", name = "Nouvel arrivant", test = function()
		return true
	end },
	{ id = "pecheur", name = "Pêcheur accompli", test = function(p)
		return Social.count(p, "fish") >= 7
	end },
	{ id = "botaniste", name = "Botaniste", test = function(p)
		return Social.count(p, "crops") >= 9
	end },
	{ id = "prospecteur", name = "Prospecteur", test = function(p)
		return Social.count(p, "ores") >= 5
	end },
	{ id = "chasseur", name = "Chasseur de monstres", test = function(p)
		return Social.count(p, "creatures") >= 15
	end },
	{ id = "dompteur", name = "Dompteur", test = function(p)
		return Social.count(p, "tames") >= 6
	end },
	{ id = "voyageur", name = "Grand voyageur", test = function(p)
		return Social.count(p, "worlds") >= 5
	end },
	{ id = "explorateur", name = "Explorateur", test = function(p)
		return (p.stats.discovered or 0) >= 1
	end },
	-- collections du 19/11 : plantes sauvages, antiquités étudiées, recettes connues
	{ id = "herboriste", name = "Herboriste", test = function(p)
		return Social.count(p, "herbs") >= 8
	end },
	{ id = "antiquaire", name = "Antiquaire", test = function(p)
		return Social.count(p, "trouvailles") >= 6
	end },
	{ id = "conservateur", name = "Conservateur de musée", test = function(p)
		return Social.count(p, "trouvailles") >= 10
	end },
	{ id = "encyclopediste", name = "Encyclopédiste", test = function(p)
		local n = 0
		for _ in p.known or {} do
			n += 1
		end
		return n >= 150
	end },
	{ id = "notoire", name = "Hors-la-loi notoire", test = function(p)
		return (p.stats.maxBounty or 0) >= 500
	end },
	{ id = "justicier", name = "Chasseur de primes", test = function(p)
		return (p.stats.bounties or 0) >= 3
	end },
	{ id = "artisan", name = "Maître artisan", test = function(p)
		return Config.skillLevel(p.skills.artisanat or 0) >= 30
	end },
	{ id = "fermier", name = "Grand fermier", test = function(p)
		return Config.skillLevel(p.skills.agriculture or 0) >= 30
	end },
	-- 18/11 : métiers de récolte, grottes et mer
	{ id = "herboriste", name = "Herboriste", test = function(p)
		return Social.count(p, "herbs") >= 6
	end },
	{ id = "maitre_herboriste", name = "Maître herboriste", test = function(p)
		return Social.count(p, "herbs") >= 11 and Config.skillLevel(p.skills.agriculture or 0) >= 20
	end },
	{ id = "bucheron", name = "Bûcheron", test = function(p)
		return (p.stats.felled or 0) >= 100
	end },
	{ id = "mineur", name = "Mineur", test = function(p)
		return (p.stats.mined or 0) >= 100
	end },
	{ id = "speleologue", name = "Spéléologue", test = function(p)
		return (p.stats.caves or 0) >= 3
	end },
	{ id = "capitaine", name = "Capitaine", test = function(p)
		return p.stats.voilier == true
	end },
	{ id = "veteran", name = "Vétéran", test = function(p)
		local n = 0
		for _, xp in p.statXp or {} do
			n += Config.statLevel(xp)
		end
		return n >= 40 -- 40 rangs de caractéristiques gagnés en pratiquant
	end },
	-- titres de noblesse accordés par le seigneur d'un château (Metiers : honneur + or au trésor)
	{ id = "ecuyer", name = "Écuyer", test = function(p)
		return (p.stats.noblesse or 0) >= 1
	end },
	{ id = "chevalier", name = "Chevalier", test = function(p)
		return (p.stats.noblesse or 0) >= 2
	end },
	{ id = "baron", name = "Baron", test = function(p)
		return (p.stats.noblesse or 0) >= 3
	end },
}
-- Succès (19/11, « à ne pas oublier » : défis et accomplissements) : un compteur de p.stats et un
-- seuil ; atteint, il donne un titre à porter. Les compteurs montent par Social.bump (pas de scan).
local FEATS = {
	{ "serviable", "Serviable", "quests", 10 },
	{ "pilier", "Pilier de la communauté", "quests", 50 },
	{ "apprenti", "Apprenti", "crafted", 50 },
	{ "mille_ouvrages", "Mille ouvrages", "crafted", 1000 },
	{ "main_verte", "Main verte", "harvested", 500 },
	{ "cartographe", "Cartographe", "discovered", 10 },
	{ "tueur_betes", "Fléau des bêtes", "kills", 250 },
	{ "tueur_boss", "Tueur de géants", "bosses", 1 },
	{ "legende", "Légende vivante", "bosses", 5 },
	{ "loup_de_mer", "Loup de mer", "fished", 200 },
	{ "marchand", "Marchand prospère", "soldGold", 10000 },
	{ "batisseur", "Bâtisseur", "built", 500 },
	{ "marin", "Marin au long cours", "voyages", 20 },
	{ "faucheur", "Faucheur", "fauche", 300 },
	{ "bien_vu", "Bien vu au village", "repBest", 50 },
	{ "heros", "Héros du peuple", "repBest", 85 },
	{ "pisteur", "Pisteur", "lieux", 25 },
	{ "grand_explorateur", "Grand explorateur", "lieux", 100 },
	{ "fondateur", "Fondateur", "villes", 1 },
	{ "conteur", "Conteur", "chroniques", 1 },
	{ "chroniqueur", "Chroniqueur", "chroniques", 6 },
}
for _, f in FEATS do
	local stat, need = f[3], f[4]
	table.insert(TITLES, { id = f[1], name = f[2], stat = stat, need = need, test = function(p)
		return (tonumber(p.stats[stat]) or 0) >= need
	end })
end
-- titres de maîtrise : niveau maximal d'une compétence (Grand maître)
local MASTERY = {
	agriculture = "Maître cultivateur", bucheronnage = "Maître bûcheron", minage = "Maître mineur", peche = "Maître pêcheur",
	cuisine = "Grand chef", artisanat = "Grand artisan", combat = "Maître d'armes", crochetage = "Roi des serrures",
	dressage = "Maître dresseur", elevage = "Maître éleveur", commerce = "Grand négociant",
}
local SKILL_ORDER = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")).SKILL_ORDER
for _, sk in SKILL_ORDER do
	local name = MASTERY[sk]
	if name then
		table.insert(TITLES, { id = "maitrise_" .. sk, name = name, test = function(p)
			return Config.skillLevel((p.skills or {})[sk] or 0) >= Config.SKILL_MAX
		end })
	end
end
Social.TITLES = TITLES
local WATCH = {} -- compteur -> seuils qui donnent un titre
for _, f in FEATS do
	WATCH[f[3]] = WATCH[f[3]] or {}
	table.insert(WATCH[f[3]], f[4])
end
local TITLE_BY_ID = {}
for _, t in TITLES do
	TITLE_BY_ID[t.id] = t
end
local inviteAt = setmetatable({}, { __mode = "k" }) -- joueur invité -> os.clock() : une invitation expire au bout de 60 s

function Social.init(g)
	G = g
	Config = G.Config
	G.Interact.onAction("set_title", function(player, data)
		Social.setTitle(player, data.id)
	end)
	G.Interact.onAction("group_invite", function(player, data)
		Social.invite(player, tonumber(data.target))
	end)
	G.Interact.onAction("group_accept", function(player)
		Social.accept(player)
	end)
	G.Interact.onAction("group_leave", function(player)
		Social.leave(player)
	end)
	Social.setupRejoin()
end

-- ----------------------------------------------------------------- Collections et titres

local function col(p)
	p.col = p.col or {}
	return p.col
end

function Social.count(p, kind: string): number
	local n = 0
	for _ in col(p)[kind] or {} do
		n += 1
	end
	return n
end

-- Note une découverte ; renvoie true si c'était nouveau
function Social.collect(player: Player, kind: string, key: string)
	local p = G.Joueurs.get(player)
	if not p or not key then
		return false
	end
	local c = col(p)
	c[kind] = c[kind] or {}
	if c[kind][key] then
		return false
	end
	c[kind][key] = true
	G.Util.toast(player, "📖 Nouvelle entrée de collection !", "gain")
	Social.checkTitles(player)
	G.Joueurs.markDirty(player)
	return true
end

function Social.checkTitles(player: Player)
	local p = G.Joueurs.get(player)
	if not p then
		return
	end
	p.titles = p.titles or {}
	for _, t in TITLES do
		if not p.titles[t.id] then
			local ok, res = pcall(t.test, p)
			if ok and res then
				p.titles[t.id] = true
				if t.id ~= "novice" then
					G.Util.toast(player, "🏅 Titre débloqué : " .. t.name .. " (choisis-le dans ton sac)", "big")
				end
			end
		end
	end
	Social.refreshStats(player)
end

-- fait monter un compteur de succès (n par défaut 1) ; « max » = garde le plus haut (repBest)
function Social.bump(player: Player, stat: string, n: number?, max: boolean?)
	local p = G.Joueurs.get(player)
	if not p then
		return
	end
	p.stats = p.stats or {}
	local old = tonumber(p.stats[stat]) or 0
	local new = max and math.max(old, n or 0) or old + (n or 1)
	if new == old then
		return
	end
	p.stats[stat] = new
	G.Joueurs.markDirty(player)
	for _, need in WATCH[stat] or {} do
		if old < need and new >= need then
			Social.checkTitles(player)
			break
		end
	end
end

-- progression des succès (pour la fiche) : { id, name, got, need, owned }
function Social.featsOf(player: Player)
	local p = G.Joueurs.get(player)
	local out = {}
	for _, f in FEATS do
		table.insert(out, { id = f[1], name = f[2], got = p and tonumber(p.stats[f[3]]) or 0, need = f[4],
			owned = p and p.titles and p.titles[f[1]] == true })
	end
	return out
end

function Social.setTitle(player: Player, id: string)
	local p = G.Joueurs.get(player)
	if p and type(id) == "string" and p.titles and p.titles[id] then
		p.title = id
		Social.refreshStats(player)
		G.Joueurs.markDirty(player)
	end
end

-- Liste des joueurs Roblox : niveau et titre
function Social.refreshStats(player: Player)
	local p = G.Joueurs.get(player)
	if not p then
		return
	end
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
		local lvl = Instance.new("IntValue")
		lvl.Name = "Maîtrise" -- somme des rangs de compétence (pas de niveau de personnage)
		lvl.Parent = ls
		local tt = Instance.new("StringValue")
		tt.Name = "Titre"
		tt.Parent = ls
	end
	local m = 0
	for _, xp in p.skills or {} do
		m += Config.skillLevel(xp)
	end
	ls["Maîtrise"].Value = m
	local t = TITLE_BY_ID[p.title or "novice"] or TITLES[1]
	ls.Titre.Value = t.name
end

function Social.titlesOf(player: Player)
	local p = G.Joueurs.get(player)
	local out = {}
	for _, t in TITLES do
		local row = { id = t.id, name = t.name, owned = p and p.titles and p.titles[t.id] == true, on = p and p.title == t.id }
		if t.stat and p then
			row.got, row.need = math.min(tonumber(p.stats[t.stat]) or 0, t.need), t.need -- succès : progression
		end
		table.insert(out, row)
	end
	return out
end

-- ----------------------------------------------------------------- Groupes

-- règle 2 (21/11) : plus de groupe limité à 5 ; seule borne = la capacité d'un monde (technique)
local MAX_GROUP = 40

local function publish(group)
	local names = {}
	for _, m in group.members do
		table.insert(names, m.UserId)
	end
	for _, m in group.members do
		G.remotes.Menu:FireClient(m, { kind = "group", members = names, leader = group.leader.UserId })
	end
end

function Social.groupOf(player: Player)
	return groups[player]
end

-- Bonus d'expérience : un membre du groupe dans les 60 studs
function Social.groupBonus(player: Player): number
	local g = groups[player]
	local r = G.Util.root(player)
	if not g or not r then
		return 1
	end
	for _, m in g.members do
		local mr = m ~= player and G.Util.root(m)
		if mr and (mr.Position - r.Position).Magnitude < 60 then
			return 1.1
		end
	end
	return 1
end

function Social.invite(player: Player, targetId: number?)
	local target = targetId and Players:GetPlayerByUserId(targetId)
	if not target or target == player then
		return
	end
	if G.Admin.blocks and G.Admin.blocks(target, player) then
		G.Util.toast(player, target.DisplayName .. " ne reçoit pas tes propositions.")
		return
	end
	local g = groups[player]
	if g and #g.members >= MAX_GROUP then
		G.Util.toast(player, "Ton groupe est complet (" .. MAX_GROUP .. ").")
		return
	end
	if groups[target] then
		G.Util.toast(player, target.DisplayName .. " est déjà dans un groupe.")
		return
	end
	invites[target] = player
	inviteAt[target] = os.clock()
	G.remotes.Menu:FireClient(target, { kind = "group_invite", from = player.DisplayName })
	G.Util.toast(player, "Invitation envoyée à " .. target.DisplayName .. ".")
end

function Social.accept(player: Player)
	local from = invites[player]
	invites[player] = nil
	if from and os.clock() - (inviteAt[player] or 0) > 60 then
		G.Util.toast(player, "Cette invitation a expiré.")
		return
	end
	if not from or not from.Parent or groups[player] then
		return
	end
	local g = groups[from]
	if not g then
		g = { leader = from, members = { from } }
		groups[from] = g
	end
	if #g.members >= MAX_GROUP then
		G.Util.toast(player, "Ce groupe est complet.")
		return
	end
	table.insert(g.members, player)
	groups[player] = g
	for _, m in g.members do
		G.Util.toast(m, player.DisplayName .. " rejoint le groupe.")
	end
	publish(g)
end

function Social.leave(player: Player)
	local g = groups[player]
	if not g then
		return
	end
	groups[player] = nil
	local i = table.find(g.members, player)
	if i then
		table.remove(g.members, i)
	end
	if player.Parent then
		G.remotes.Menu:FireClient(player, { kind = "group", members = {}, leader = 0 })
	end
	if #g.members <= 1 then
		for _, m in g.members do
			groups[m] = nil
			G.remotes.Menu:FireClient(m, { kind = "group", members = {}, leader = 0 })
			G.Util.toast(m, "Le groupe est dissous.")
		end
		return
	end
	if g.leader == player then
		g.leader = g.members[1]
	end
	for _, m in g.members do
		G.Util.toast(m, player.DisplayName .. " quitte le groupe.")
	end
	publish(g)
end


-- Reconnexion de groupe (appelée par init ; ici, après publish / MAX_GROUP)
function Social.setupRejoin()
	-- reconnexion (18/11) : qui décroche garde sa place 5 min ; à son retour il rejoint son groupe
	local rejoin = {} -- UserId -> { mates = { UserId… }, t }
	Players.PlayerRemoving:Connect(function(p)
		local g = groups[p]
		if g and #g.members > 1 then
			local mates = {}
			for _, m in g.members do
				if m ~= p then
					table.insert(mates, m.UserId)
				end
			end
			rejoin[p.UserId] = { mates = mates, t = os.clock() }
		end
		Social.leave(p)
		invites[p] = nil
	end)
	Players.PlayerAdded:Connect(function(p)
		local r = rejoin[p.UserId]
		rejoin[p.UserId] = nil
		if not r or os.clock() - r.t > 300 then
			return
		end
		task.delay(8, function() -- le temps que le perso charge
			if not p.Parent or groups[p] then
				return
			end
			for _, uid in r.mates do
				local mate = Players:GetPlayerByUserId(uid)
				local g = mate and groups[mate]
				if g and #g.members < MAX_GROUP then
					table.insert(g.members, p)
					groups[p] = g
					for _, m in g.members do
						G.Util.toast(m, p.DisplayName .. " revient dans le groupe.")
					end
					publish(g)
					return
				elseif mate and not groups[mate] then
					-- le groupe s'était dissous à son départ (il n'était plus que deux) : on le refait
					local ng = { leader = mate, members = { mate, p } }
					groups[mate], groups[p] = ng, ng
					G.Util.toast(mate, p.DisplayName .. " revient : le groupe est reformé.")
					G.Util.toast(p, "Groupe reformé avec " .. mate.DisplayName .. ".")
					publish(ng)
					return
				end
			end
		end)
	end)
end

return Social
