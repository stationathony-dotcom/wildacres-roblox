-- Gazette des joueurs (27/11, MANQUES-MMO n° 10 « journaux de joueurs »). Sur place, jamais à distance :
--   · « gazette_ecrire » { titre, texte } au village : coûte 1 papier + 1 encre ; texte FILTRÉ par Roblox
--     (TextService, obligatoire pour du texte écrit par un joueur et lu par d'autres) ;
--   · « gazette » : les articles du monde, du plus récent au plus ancien (message « gazette ») ;
--   · on garde les Gazette.KEEP derniers ; l'auteur peut retirer le sien (« gazette_retirer » { id }).
-- État : G.world.extra.gazette = { {id, uid, auteur, titre, texte, jour, village} }.

local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local Gazette = {}
local G

Gazette.KEEP = 40
Gazette.COST = { paper = 1, ink = 1 }

local function list()
	G.world.extra = G.world.extra or {}
	G.world.extra.gazette = G.world.extra.gazette or {}
	return G.world.extra.gazette
end

-- texte d'un joueur lu par tous : filtré (en Studio, le service peut manquer : texte tel quel)
function Gazette.filter(player: Player, text: string): string?
	local ok, res = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		return RunService:IsStudio() and text or nil
	end
	return res
end

local function clean(s: any, maxLen: number): string?
	if type(s) ~= "string" then
		return nil
	end
	s = utf8.nfcnormalize((string.gsub(s, "^%s+", ""):gsub("%s+$", "")))
	local n = utf8.len(s)
	if not n or n < 3 then
		return nil
	end
	if n > maxLen then
		s = string.sub(s, 1, utf8.offset(s, maxLen + 1) - 1)
	end
	return s
end

function Gazette.write(player: Player, titre: any, texte: any): (boolean, string)
	local v = G.Quetes and rawget(G.Quetes, "nearVillage") and G.Quetes.nearVillage(player)
	if not v then
		return false, "La gazette s'écrit au tableau d'un village."
	end
	titre, texte = clean(titre, 60), clean(texte, 600)
	if not titre or not texte then
		return false, "Un titre et un texte (3 lettres au moins)."
	end
	for item, n in Gazette.COST do
		if G.Joueurs.count(player, item) < n then
			return false, "Il te faut du papier et de l'encre."
		end
	end
	local ft, fx = Gazette.filter(player, titre), Gazette.filter(player, texte)
	if not ft or not fx then
		return false, "La gazette n'a pas pu être relue, réessaie."
	end
	for item, n in Gazette.COST do
		G.Joueurs.take(player, item, n)
	end
	local L = list()
	table.insert(L, 1, { id = "gz" .. HttpService:GenerateGUID(false), uid = player.UserId, auteur = player.DisplayName, titre = ft, texte = fx,
		jour = G.world.day, village = v.name })
	while #L > Gazette.KEEP do
		table.remove(L)
	end
	G.Social.bump(player, "articles", 1)
	G.Joueurs.sync(player)
	G.Mondes.saveSoon(player)
	return true, "📰 Ton article est affiché à la gazette."
end

function Gazette.remove(player: Player, id: any): (boolean, string)
	for i, a in list() do
		if a.id == id and a.uid == player.UserId then
			table.remove(list(), i)
			return true, "Article retiré."
		end
	end
	return false, "Cet article n'est pas le tien."
end

function Gazette.init(g)
	G = g
	G.Interact.onAction("gazette_ecrire", function(player, data)
		if type(data) ~= "table" then
			return
		end
		local ok, msg = Gazette.write(player, data.titre, data.texte)
		G.Util.toast(player, msg, ok and "gain" or nil)
	end)
	G.Interact.onAction("gazette_retirer", function(player, data)
		local ok, msg = Gazette.remove(player, type(data) == "table" and data.id)
		G.Util.toast(player, msg, ok and "gain" or nil)
	end)
	G.Interact.onAction("gazette", function(player)
		if not (G.Quetes and rawget(G.Quetes, "nearVillage") and G.Quetes.nearVillage(player)) then
			G.Util.toast(player, "La gazette se lit au tableau d'un village.")
			return
		end
		G.remotes.Menu:FireClient(player, { kind = "gazette", articles = list() })
	end)
end

return Gazette
