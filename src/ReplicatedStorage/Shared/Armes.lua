-- Armes : profils de combat par famille, types de dégâts, résistances des créatures, garde et esquive
-- (26/11, demande du propriétaire : « les armes catégorisées, un vrai jeu par type, blocages au bouclier »).
-- Données partagées : serveur (Systemes/Combat) et client (Interface, Gestes : temps de recharge, portée).
--
-- Profil : cd = temps entre deux coups (s) · portee (studs) · mult = dégâts × · type = tranchant / contondant /
-- perforant · endu = endurance par coup · multi = nombre de cibles d'un même coup · garde = coût d'endurance en plus
-- quand ce coup frappe une garde (brise-garde) · armure = part de la défense adverse ignorée · dos = × dans le dos ·
-- charge = × en selle · saigne = saignement (3 × 10 %) · cone = ouverture (produit scalaire minimal, plus bas = plus large)

local A = {}

A.PROFILS = {
	poing = { nom = "Poings", cd = 0.38, portee = 5.5, mult = 0.8, type = "contondant", endu = 2, cone = 0.35 },
	dague = { nom = "Dague", cd = 0.32, portee = 6, mult = 0.75, type = "perforant", endu = 3, cone = 0.45, dos = 2.2 },
	epee = { nom = "Épée", cd = 0.45, portee = 7.5, mult = 1, type = "tranchant", endu = 5, cone = 0.35 },
	sabre = { nom = "Sabre", cd = 0.42, portee = 7.5, mult = 0.95, type = "tranchant", endu = 5, cone = 0.3, saigne = true },
	espadon = { nom = "Espadon", cd = 0.85, portee = 9, mult = 1.6, type = "tranchant", endu = 12, cone = -0.1, multi = 3 },
	hache = { nom = "Hache", cd = 0.62, portee = 7, mult = 1.3, type = "tranchant", endu = 8, cone = 0.3, garde = 1.6 },
	masse = { nom = "Masse et marteau", cd = 0.7, portee = 7, mult = 1.3, type = "contondant", endu = 9, cone = 0.3, garde = 2, armure = 0.5 },
	lance = { nom = "Lance", cd = 0.6, portee = 11, mult = 1.1, type = "perforant", endu = 7, cone = 0.7, charge = 1.7 },
	hast = { nom = "Hallebarde et fauchard", cd = 0.8, portee = 10, mult = 1.45, type = "tranchant", endu = 11, cone = 0.0, multi = 2, garde = 1.4 },
	baton = { nom = "Bâton", cd = 0.5, portee = 8.5, mult = 0.9, type = "contondant", endu = 5, cone = 0.2, garde = 1.3 },
}

-- forme de l'arme portée (Shared/GearDesign.formOf) ou outil tenu (Config.baseOf) → profil
A.DE_FORME = {
	sword = "epee", shortsword = "epee", longsword = "epee", bastard = "epee", venomblade = "dague", dagger = "dague",
	saber = "sabre", greatsword = "espadon", axe = "hache", throwaxes = "hache", mace = "masse", hammer = "masse",
	club = "masse", claw = "masse", clawglove = "poing", pike = "lance", longpike = "lance", javelin = "lance",
	halberd = "hast", scythe = "hast", reaper = "hast", sickle = "sabre", staff = "baton",
}
A.DE_OUTIL = { sword = "epee", club = "masse", axe = "hache", pickaxe = "masse" }

-- Résistances par forme de créature (Bestiaire KINDS.form) : × appliqué aux dégâts de ce type
A.RESIST = {
	golem = { tranchant = 0.6, perforant = 0.7, contondant = 1.45 },
	insecte = { tranchant = 0.8, perforant = 0.9, contondant = 1.35 },
	spectre = { tranchant = 0.85, perforant = 0.75, contondant = 0.7 },
	masse = { tranchant = 1.25, perforant = 0.8, contondant = 0.75 },
	serpent = { tranchant = 1.1, perforant = 1.2, contondant = 0.9 },
	volant = { tranchant = 1, perforant = 1.3, contondant = 0.9 },
	quadrupede = { tranchant = 1.05, perforant = 1.1, contondant = 0.95 },
}

-- Enchaînement : coups successifs à moins de COMBO_FENETRE s ; le 3e est le coup final
A.COMBO_FENETRE = 1.2
A.COMBO_FINAL = 1.3
-- Coup chargé : clic maintenu puis relâché (client) ; plein effet à CHARGE_MAX s
A.CHARGE_MIN, A.CHARGE_MAX, A.CHARGE_BONUS = 0.5, 1.5, 0.8
-- Garde (touche [Z] maintenue) : réduction des dégâts reçus de face, coût en endurance
A.GARDE_BOUCLIER = 0.2 -- part des dégâts qui passe avec un bouclier
A.GARDE_ARME = 0.55 -- sans bouclier : on pare avec l'arme
A.GARDE_COUT = 0.5 -- endurance perdue par point de dégât bloqué
A.GARDE_CONE = 0.2 -- il faut faire face au coup
A.PARADE = 0.3 -- s : un coup reçu juste après avoir levé la garde est PARÉ (aucun dégât, riposte)
A.PARADE_RIPOSTE = 0.6 -- × des dégâts du joueur renvoyés à l'attaquant, qui est sonné
A.GARDE_BRISEE = 1.5 -- s sans pouvoir relever la garde quand l'endurance est épuisée
-- Esquive ([Alt]) : invulnérable un court instant, coût en endurance
A.ESQUIVE_COUT, A.ESQUIVE_INVULN, A.ESQUIVE_CD = 22, 0.35, 0.8
-- Maîtrise par famille : niveau = racine(xp / 6), max 30 ; +0,5 % de dégâts par niveau
A.MAITRISE_MAX, A.MAITRISE_PAR_NIVEAU = 30, 0.005

-- Armes à distance (26/11, « pousser un peu plus ») : vise = précision minimale (produit scalaire avec la visée),
-- loin = bonus au-delà de 40 studs. Clic maintenu puis relâché = TIR CHARGÉ (on bande l'arc) : dégâts et portée en
-- plus ; un tir pleinement chargé sur un humanoïde peut toucher en pleine tête (TETE_CHANCE, × TETE_MULT).
A.DISTANCE = {
	arc = { nom = "Arc", cd = 0.9, portee = 48, mult = 1, type = "perforant", endu = 3, vise = 0.9 },
	arc_court = { nom = "Arc court", cd = 0.6, portee = 38, mult = 0.85, type = "perforant", endu = 2, vise = 0.87 },
	arc_long = { nom = "Arc long", cd = 1.2, portee = 72, mult = 1.25, type = "perforant", endu = 4, vise = 0.93, loin = 1.25 },
	arbalete = { nom = "Arbalète", cd = 1.7, portee = 60, mult = 1.75, type = "perforant", endu = 3, vise = 0.95, armure = 0.5 },
	fronde = { nom = "Fronde", cd = 0.7, portee = 36, mult = 0.8, type = "contondant", endu = 2, vise = 0.86 },
	jet = { nom = "Armes de jet", cd = 0.8, portee = 30, mult = 1.1, type = "perforant", endu = 4, vise = 0.88 },
}
A.DE_FORME_DIST = {
	bow = "arc", shortbow = "arc_court", longbow = "arc_long", crossbow = "arbalete", sling = "fronde",
	throwing = "jet", throwaxes = "jet", javelin = "jet", bandolier = "jet",
}
-- munitions de jet : type de dégâts propre
A.TYPE_MUNITION = { stone = "contondant", javelin = "perforant", throwing_knife = "perforant", throwing_axe = "tranchant", arrow_barbed = "perforant" }
A.TETE_CHANCE, A.TETE_MULT = 0.25, 1.5

function A.profil(cle: string?)
	return A.PROFILS[cle or ""] or A.PROFILS.poing
end

function A.maitriseNiveau(xp: number?): number
	return math.min(A.MAITRISE_MAX, math.floor(math.sqrt((xp or 0) / 6)))
end

return A
