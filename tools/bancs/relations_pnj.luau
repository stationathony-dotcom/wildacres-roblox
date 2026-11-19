-- Banc ciblé des relations PNJ. Exécuter côté serveur dans Studio.
local RelationsPnj = require(game.ServerScriptService.Systemes.RelationsPnj)
local HttpService = game:GetService("HttpService")

local pnj = { lastTalk = 10, lastChat = 10, lastGift = 10, ops = { u1 = 24 } }
for _, action in { "salutation", "discussion", "cadeau" } do
	assert(RelationsPnj.disponible(pnj, 10, "u1", action), "Ancienne sauvegarde compatible")
	assert(RelationsPnj.enregistrer(pnj, 10, "u1", action), "Premier gain du joueur")
	assert(not RelationsPnj.disponible(pnj, 10, "u1", action), "Action consommée pour ce joueur")
	assert(not RelationsPnj.enregistrer(pnj, 10, "u1", action), "Action non cumulable")
	assert(RelationsPnj.enregistrer(pnj, 10, "u2", action), "Gain indépendant pour le deuxième joueur")
end

local recharge = HttpService:JSONDecode(HttpService:JSONEncode(pnj))
assert(not RelationsPnj.disponible(recharge, 10, "u1", "cadeau"), "Limite conservée à la reprise")
assert(RelationsPnj.disponible({}, 10, "u1", "cadeau"), "Limite indépendante pour un autre PNJ")
assert(RelationsPnj.enregistrer(recharge, 11, "u1", "cadeau"), "Nouveau jour")
assert(RelationsPnj.disponible(recharge, 11, "u2", "cadeau"), "Anciennes limites expirées")
assert(RelationsPnj.disponible(recharge, 11, "u1", "discussion"), "Actions indépendantes")
assert(recharge.ops.u1 == 24, "Opinion conservée")

return "Relations PNJ : tous les contrôles passent"
