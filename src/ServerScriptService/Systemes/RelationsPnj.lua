local RelationsPnj = {}

-- Un seul jour de suivi par PNJ. Les opinions, elles, restent acquises.
function RelationsPnj.disponible(per, day: number, uid: string, action: string): boolean
	local suivi = per.relationsDuJour
	return not suivi or suivi.day ~= day or not (suivi.joueurs[uid] and suivi.joueurs[uid][action])
end

function RelationsPnj.enregistrer(per, day: number, uid: string, action: string): boolean
	if not RelationsPnj.disponible(per, day, uid, action) then
		return false
	end
	local suivi = per.relationsDuJour
	if not suivi or suivi.day ~= day then
		suivi = { day = day, joueurs = {} }
		per.relationsDuJour = suivi
	end
	local actions = suivi.joueurs[uid] or {}
	actions[action] = true
	suivi.joueurs[uid] = actions
	return true
end

return RelationsPnj
