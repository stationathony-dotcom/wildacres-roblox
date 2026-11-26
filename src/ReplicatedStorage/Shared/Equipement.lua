-- Équipement façon MMO (26/11, d'après « Pour Wild Acres, je créerais un véritable système d'équipements… »,
-- réadapté aux règles du jeu) : pas de classe imposée, c'est l'équipement qui fait la spécialisation.
-- Réadaptations : « niveau requis » → exigence de caractéristique entraînée (Equilibre.requirement, déjà là) ;
-- résistance au froid / chaleur → retirées (règle 10) ; capacité de transport → pas de plafond (règle 2) ;
-- signature / qualité de façon → retirées le 20/11.
--
-- 1. AFFIXES procéduraux : une pièce obtenue (butin, fabrication, armurier) peut recevoir un préfixe qui ajoute
--    une caractéristique → deux joueurs avec le même modèle n'ont pas forcément les mêmes statistiques.
-- 2. DURABILITÉ : une pièce s'use (arme : coups portés ; armure : coups reçus) ; à 0 elle est « brisée » (plus de
--    statistiques) jusqu'à réparation chez le forgeron ou l'armurier.
-- 3. TYPES D'ARMURE (forme du torse) : tissu / cuir / mailles / plates : protection contre mobilité.
-- 4. SPÉCIALISATION déduite de ce que l'on porte (Gardien, Guerrier, Rôdeur, Ombre…), avec un petit passif.

local E = {}

-- complément ajouté au nom (invariable : pas de faute d'accord), caractéristique, valeur de base (× rareté)
E.AFFIXES = {
	{ "de vigueur", "vie", 2 }, { "d'agilité", "vitesse", 1 }, { "de puissance", "force", 2 }, { "de fortune", "chance", 2 },
	{ "de prestige", "charisme", 2 }, { "de l'ombre", "discretion", 2 }, { "du rempart", "defense", 2 },
	{ "du tranchant", "critique", 2 }, { "de célérité", "hate", 2 }, { "des anciens", "maitrise", 1 },
}
-- chance d'un affixe selon la rareté (1 commun … 4 légendaire) ; les légendaires en ont deux
E.AFFIX_CHANCE = { 0.3, 0.55, 0.85, 1 }

-- durabilité maximale par rareté
E.DURA = { 120, 180, 260, 360, 450 }
E.USURE_ARME = 1 -- par coup porté
E.USURE_ARMURE = 1 -- par coup reçu (une pièce d'armure au hasard)
E.REPARER = { 0.35, 0.6, 1, 1.6, 2.4 } -- or par point de durabilité, selon la rareté

-- types d'armure selon la forme du torse (Shared/GearDesign.formOf) : vitesse ×, défense +%
E.ARMURES = {
	tissu = { nom = "Tissu", formes = { tunic = true, robe = true, cloak = true }, vitesse = 1.05, defense = 0 },
	cuir = { nom = "Cuir", formes = { leather = true, brigandine = true }, vitesse = 1.03, defense = 0.05 },
	mailles = { nom = "Mailles", formes = { mail = true, scale = true }, vitesse = 0.98, defense = 0.12 },
	plates = { nom = "Plates", formes = { plate = true }, vitesse = 0.94, defense = 0.22 },
}

-- critique (% de chance de coup double) et hâte (% de cadence en plus), plafonnés
E.CRIT_PAR_POINT, E.CRIT_MAX = 0.01, 0.35
E.HATE_PAR_POINT, E.HATE_MAX = 0.01, 0.3
E.MAITRISE_PAR_POINT = 0.01 -- maîtrise d'équipement : +1 % de dégâts par point

-- Spécialisations (déduites, recalculées à chaque changement d'équipement) : première qui correspond
E.SPECS = {
	{ id = "gardien", nom = "Gardien", test = "bouclier", passif = "garde 25 % moins coûteuse" },
	{ id = "ombre", nom = "Ombre", test = "dague", passif = "coups dans le dos +20 %" },
	{ id = "rodeur", nom = "Rôdeur", test = "distance", passif = "portée de tir +12 %" },
	{ id = "guerrier", nom = "Guerrier", test = "lourde", passif = "dégâts +6 % avec les armes lourdes" },
	{ id = "dresseur", nom = "Dresseur", test = "compagnon", passif = "compagnons +10 % de dégâts" },
	{ id = "artisan", nom = "Artisan", test = "metier", passif = "outils qui s'usent 15 % moins vite" },
	{ id = "aventurier", nom = "Aventurier", test = "defaut", passif = "aucun (polyvalent)" },
}
E.SPEC_PASSIF = { gardien = 0.75, ombre = 1.2, rodeur = 1.12, guerrier = 1.06, dresseur = 1.1, artisan = 0.85 }

-- Ajoute affixes et durabilité à une pièce neuve (une seule fois : champ `fini`)
function E.finaliser(piece, rng: Random?)
	if type(piece) ~= "table" or piece.fini then
		return piece
	end
	rng = rng or Random.new()
	piece.fini = true
	piece.stats = piece.stats or {}
	local rar = math.clamp(piece.rarity or 1, 1, 4)
	piece.duraMax = piece.duraMax or E.DURA[rar] or 120
	piece.dura = piece.dura or piece.duraMax
	local n = (rng:NextNumber() < E.AFFIX_CHANCE[rar]) and 1 or 0
	if rar >= 4 then
		n = 2
	end
	local pris = {}
	for _ = 1, n do
		local a = E.AFFIXES[rng:NextInteger(1, #E.AFFIXES)]
		if not pris[a[2]] then
			pris[a[2]] = true
			local v = a[3] * rar + rng:NextInteger(0, rar)
			piece.stats[a[2]] = (piece.stats[a[2]] or 0) + v
			piece.affixes = piece.affixes or {}
			table.insert(piece.affixes, a[1])
		end
	end
	if piece.affixes and piece.name and not string.find(piece.name, piece.affixes[1], 1, true) then
		piece.name = piece.name .. " " .. piece.affixes[1]
	end
	return piece
end

function E.brisee(piece): boolean
	return type(piece) == "table" and piece.dura ~= nil and piece.dura <= 0
end

return E
