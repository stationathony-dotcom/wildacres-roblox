-- Banc des duels (Systemes/Duels, 20/11) — mode Edit, G simulé.
local D = assert(loadstring(game.ServerScriptService.Systemes.Duels.Source, "Duels"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end
local gold, pos = {}, {}
local function mk(name)
	local p = { Name = name, DisplayName = name, UserId = #name, Parent = true }
	gold[p], pos[p] = 100, Vector3.zero
	return p
end
local A, B, C = mk("Arthur"), mk("Brune"), mk("Cyril")
local mail = {}
local G = {
	Util = { root = function(p) return { Position = pos[p] } end, toast = function() end, newId = function() return "d1" end },
	Joueurs = { count = function(p) return gold[p] end, take = function(p, _, n) gold[p] -= n return true end, add = function(p, _, n) gold[p] += n end, sync = function() end },
	Economie = { record = function() end },
	Poste = { deliverSystem = function(uid, parcel) table.insert(mail, { uid, parcel.gold }) end },
}
D.init(G)
pos[C] = Vector3.new(100, 0, 0)
check("défier quelqu'un de trop loin : refusé", not D.challenge(A, C, 10))
check("mise plus grosse que sa bourse : refusée", not D.challenge(A, B, 500))
check("défi lancé (mise 30)", D.challenge(A, B, 30))
check("refus : rien n'est pris", D.answer(B, false) and gold[A] == 100 and gold[B] == 100)
D.challenge(A, B, 30)
check("accepté : 30 pris à chacun", D.answer(B, true) and gold[A] == 70 and gold[B] == 70)
check("adversaires appariés (pas de crime entre eux)", D.paired(A, B) and D.paired(B, A) and not D.paired(A, C))
check("un 3e ne peut pas défier un duelliste", not D.challenge(C, A, 0))
check("K.O. de Brune : fin du duel", D.onKO(B, A) == true)
check("Arthur gagne les deux mises (130)", gold[A] == 130 and gold[B] == 70 and not D.inDuel(A))
check("hors duel, un K.O. n'est pas un duel", D.onKO(B, A) == false)
-- match nul : éloignement
D.challenge(A, B, 20)
D.answer(B, true)
pos[B] = Vector3.new(200, 0, 0)
D.step(1.1)
check("trop éloignés : match nul, mises rendues", not D.inDuel(A) and gold[A] == 130 and gold[B] == 70)
-- match nul : départ d'un joueur → sa mise par courrier
pos[B] = Vector3.zero
D.challenge(A, B, 10)
D.answer(B, true)
B.Parent = nil
D.step(1.1)
check("parti en plein duel : mise rendue par courrier", #mail == 1 and mail[1][2] == 10 and gold[A] == 130)
return fails .. " échec(s)\n" .. table.concat(out, "\n")
