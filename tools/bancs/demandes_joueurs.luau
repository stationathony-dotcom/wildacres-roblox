-- Banc des demandes des joueurs (Systemes/Demandes, 20/11) — mode Edit, en mémoire (pas de DataStore).
-- Dépôt (demande / bug / appel), refus des messages trop courts, 3 par jour, contexte joint, file des
-- admins, réponse, clôture, bannissement maison (expire, se lève) et refus d'entrer dans un monde.
local D = assert(loadstring(game.ServerScriptService.Systemes.Demandes.Source, "Demandes"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end
local actions = {}
local G = {
	Interact = { onAction = function(k, fn) actions[k] = fn end },
	Util = { toast = function() end, root = function() return { Position = Vector3.new(10.4, 3, -7.9) } end },
	Clock = { biomeAt = function() return "marais" end },
	Mondes = { id = "w42", mode = "monde" },
	world = { day = 12 },
	Economie = { record = function() end },
	Admin = { isAdmin = function() return false end },
}
D.init(G)
local P = { UserId = 777001, Name = "Testeur" }
local A = { Name = "Admin" }

local ok, msg = D.submit(P, "bug", "court")
check("message trop court refusé", not ok and msg:find("10") ~= nil)
ok = D.submit(P, "danser", "un message assez long pour passer")
check("sorte inconnue refusée", not ok)
ok, msg = D.submit(P, "bug", "Je tombe à travers le sol près du moulin")
check("bug reçu avec un numéro (" .. tostring(msg) .. ")", ok and msg:find("n°") ~= nil)
local list = D.list("bug")
check("dans la file des bugs, avec le contexte (pos, biome, monde, jour)",
	#list >= 1 and list[1].ctx:find("pos 10,3,%-8") ~= nil and list[1].ctx:find("marais") ~= nil and list[1].ctx:find("w42") ~= nil and list[1].ctx:find("jour 12") ~= nil)
local id = list[1].id
D.submit(P, "demande", "Comment je récupère mon cheval perdu ?")
ok = D.submit(P, "appel", "Je n'ai rien volé, c'était mon coffre")
check("3 demandes dans la journée : acceptées", ok)
ok, msg = D.submit(P, "appel", "Encore une demande de plus aujourd'hui")
check("4e dans la journée : refusée (anti-spam)", not ok and msg:find("3") ~= nil)
check("filtre par sorte : 1 appel", #D.list("appel") == 1)
ok, msg = D.reply(A, id, "Corrigé dans la prochaine version, merci !")
check("réponse enregistrée, demande traitée", ok and #D.list("bug") == 0 and D.list("bug", true)[1].reply ~= nil)
ok = D.reply(A, 99999, "rien")
check("n° inconnu : refusé", not ok)
-- action de l'interface
check("action « demande » branchée", actions.demande ~= nil)

-- bannissement maison
local info = D.ban(P.UserId, 3, "triche", "Admin")
check("banni : info + texte", D.isBanned(P) and D.banText(info):find("3 jour") ~= nil)
D.unban(P.UserId)
check("bannissement levé", not D.isBanned(P))
D.ban(P.UserId, 0, "test", "Admin") -- 0 jour : déjà expiré
check("bannissement expiré : plus banni", not D.isBanned(P))

-- texte montré au banni (expulsion d'un monde, refus de Mondes.join)
D.ban(P.UserId, 2, "insultes", "Admin")
check("texte de bannissement : durée et motif", D.banText(D.banInfo(P.UserId)):find("insultes") ~= nil)
D.unban(P.UserId)
return fails .. " échec(s)\n" .. table.concat(out, "\n")
