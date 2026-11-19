-- Chroniques (19/11) : lire une « page ancienne » (objet trouvé : fouille, roches, événements, trésors)
-- révèle une page encore inconnue d'un des récits de Shared/Chroniques ; une chronique complète
-- rapporte son objet ancien, une carte au trésor et compte pour les succès Conteur / Chroniqueur.
-- Pages connues : collection « pages » du profil (Social.collect, clés « récit:n »), donc gardées
-- d'une île à l'autre. /chroniques : où on en est ; /chroniques <n> : relire un récit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Chroniques = {}
local G, C
local remote

function Chroniques.init(g)
	G = g
	C = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Chroniques"))
	remote = ReplicatedStorage:FindFirstChild("Chronique") or Instance.new("RemoteEvent")
	remote.Name = "Chronique"
	remote.Parent = ReplicatedStorage
end

-- envoi au client (remplaçable par les bancs)
function Chroniques.send(player: Player, d)
	remote:FireClient(player, d)
end

local function known(player: Player)
	local p = G.Joueurs.get(player)
	return p and p.col and p.col.pages or {}
end

local function countOf(set, s): number
	local n = 0
	for i = 1, #s.pages do
		if set[s.id .. ":" .. i] then
			n += 1
		end
	end
	return n
end

-- pages connues d'un récit, pour l'affichage
local function pagesOf(set, s)
	local out = {}
	for i, text in s.pages do
		table.insert(out, { n = i, texte = set[s.id .. ":" .. i] and text or nil })
	end
	return out
end

-- lit une page ancienne ; renvoie true si l'objet a été consommé
function Chroniques.read(player: Player): boolean
	local set = known(player)
	local started, fresh = {}, {}
	for _, s in C.LIST do
		local n = countOf(set, s)
		if n > 0 and n < #s.pages then
			table.insert(started, s)
		elseif n == 0 then
			table.insert(fresh, s)
		end
	end
	if #started == 0 and #fresh == 0 then
		G.Util.toast(player, "📜 Tu connais déjà toutes les chroniques : cette page n'apprend rien de neuf (garde-la ou vends-la).")
		return false
	end
	-- on avance plutôt un récit commencé (2 fois sur 3), sinon on en découvre un autre
	local pool = (#started > 0 and (#fresh == 0 or math.random() < 0.66)) and started or fresh
	local s = pool[math.random(1, #pool)]
	local missing = {}
	for i = 1, #s.pages do
		if not set[s.id .. ":" .. i] then
			table.insert(missing, i)
		end
	end
	local n = missing[math.random(1, #missing)]
	if not G.Joueurs.take(player, "old_page", 1) then
		return false
	end
	local prof = G.Joueurs.get(player)
	prof.col = prof.col or {}
	prof.col.pages = prof.col.pages or {}
	prof.col.pages[s.id .. ":" .. n] = true
	G.Joueurs.markDirty(player)
	set = prof.col.pages
	local got = countOf(set, s)
	Chroniques.send(player, { titre = s.titre, pages = pagesOf(set, s), nouvelle = n, connues = got, total = #s.pages })
	G.Joueurs.addSkillXp(player, "commerce", 2) -- le savoir se monnaie
	if got >= #s.pages then
		G.Joueurs.add(player, "treasure_map", 1)
		if s.recompense and G.Config.ITEMS[s.recompense] then
			G.Joueurs.add(player, s.recompense, 1)
		end
		G.Social.bump(player, "chroniques")
		G.Util.toast(player, "📖 Chronique complète : « " .. s.titre .. " » ! Entre les pages, une carte au trésor…", "big")
	else
		G.Util.toast(player, string.format("📜 « %s » : page %d (%d/%d)", s.titre, n, got, #s.pages), "gain")
	end
	G.Joueurs.sync(player)
	return true
end

-- relire un récit (n = son rang dans /chroniques)
function Chroniques.show(player: Player, n: number): boolean
	local s = C.LIST[n]
	local set = known(player)
	if not s or countOf(set, s) == 0 then
		return false
	end
	Chroniques.send(player, { titre = s.titre, pages = pagesOf(set, s), connues = countOf(set, s), total = #s.pages })
	return true
end

function Chroniques.describe(player: Player): { string }
	local set = known(player)
	local lines = {}
	for i, s in C.LIST do
		local n = countOf(set, s)
		if n > 0 then
			table.insert(lines, string.format("%d. %s %s (%d/%d)", i, n >= #s.pages and "📖" or "📜", s.titre, n, #s.pages))
		end
	end
	if #lines == 0 then
		lines[1] = "Aucune page lue. Les pages anciennes se trouvent en fouillant, en minant, dans les trésors…"
	end
	return lines
end

return Chroniques
