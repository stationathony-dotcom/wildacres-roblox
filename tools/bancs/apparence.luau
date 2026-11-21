-- Banc Édition : validation, ateliers et rendu R15 du catalogue joueur.
local shared = game.ReplicatedStorage.Shared
local WG = require(shared.WorldGen)
local Looks = require(shared.Apparence)
local mod = game.ServerScriptService.Systemes.Avatar:Clone()
local A = require(mod)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then fails += 1 end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end

local prof = {}
local gold = 350
local sent = {}
local root = { Position = Vector3.zero }
local G = {
	WG = WG,
	Interact = { onAction = function() end },
	Joueurs = {
		get = function() return prof end, markDirty = function() end, sync = function() end,
		take = function(_, _, n)
			if gold < n then return false end
			gold -= n
			return true
		end,
	},
	Util = { toast = function() end, root = function() return root end },
	remotes = { Menu = { FireClient = function(_, _, d) table.insert(sent, d) end } },
}
A.init(G)
local P = { UserId = 1234, Character = nil }
local creation = {
	ctx = "creation", skin = #Looks.SKINS, hair = "couronne", hairColor = 8, eyes = "amande", eyeColor = 3,
	brows = "epais", mouth = "coin", beard = "tressee", mustache = "guidon", marks = "rousseur_joue",
	shirt = #Looks.SHIRTS, shirtCut = "longue", pants = #Looks.PANTS, pantsCut = "guetres",
}

check("au moins 16 coiffures et 8 teints", #Looks.HAIR_LIST >= 16 and #Looks.SKINS >= 8)
for _, key in { "SKINS", "HAIR_COLORS", "SHIRTS", "PANTS" } do
	local colors = Looks[key]
	local same = #colors > #WG[key]
	for index, color in WG[key] do
		if colors[index] ~= color then same = false end
	end
	check(key .. " : anciennes couleurs aux mêmes indices", same)
end
local default = A.defaultLook(P)
check("apparence par défaut villageoise", default.mode == "villageois" and A.STARTER.hair[default.hair])
A.setLook(P, creation)
check("sans écran ouvert : refus", prof.look == nil)
A.open(P, "creation")
check("écran de création", sent[#sent].kind == "look" and sent[#sent].ctx == "creation")
for _, field in Looks.FIELDS do
	local invalid = table.clone(creation)
	invalid[field.key] = field.colors and #field.colors + 1 or "inconnu"
	A.setLook(P, invalid)
	check("choix inconnu refusé : " .. field.key, prof.look == nil and gold == 350)
end
for _, invalid in { { eyeColor = 0 / 0 }, { skin = 1.5 }, { shirt = "2" }, { beard = {} }, { mouth = false } } do
	A.setLook(P, invalid)
end
check("NaN, décimale et mauvais types refusés", prof.look == nil and gold == 350)
A.setLook(P, creation)
local saved = prof.look
local allSaved = saved and saved.created and gold == 350
for _, field in Looks.FIELDS do
	if not saved or saved[field.key] ~= creation[field.key] then allSaved = false end
end
check("création gratuite : tous les champs sont enregistrés", allSaved)
check("styles choisis à la création acquis", A.owned(prof, "hair", "couronne")
	and A.owned(prof, "shirt", creation.shirt) and A.owned(prof, "beard", "tressee"))
local messages = #sent
A.open(P, "creation")
check("création une seule fois", #sent == messages)

local barber = { root = { Position = Vector3.new(5, 0, 0) } }
A.open(P, "barbier", barber)
local shop = sent[#sent]
check("barbier : transmet les champs, le tarif et la possession", #shop.keys == 5 and shop.prices.beard > 0
	and shop.owned.hairColor["8"] and not shop.owned.hair.nattes and shop.owned.shirt == nil)
A.setLook(P, { ctx = "barbier", hair = "nattes", beard = "inconnue" })
check("barbier : choix invalide sans achat partiel", prof.look == saved and gold == 350 and not A.owned(prof, "hair", "nattes"))
A.setLook(P, {
	ctx = "barbier", hair = "nattes", brows = "arques", beard = "bouc", mustache = "fine",
	skin = 1, mouth = "neutre", eyeColor = 2, eyes = "ronds", marks = "aucune", shirtCut = "col",
})
local barberCost = A.UNLOCK.hair + A.UNLOCK.brows + A.UNLOCK.beard + A.UNLOCK.mustache + A.FEE
check("barbier : facturation des quatre styles et d’une façon", gold == 350 - barberCost
	and prof.look.hair == "nattes" and prof.look.brows == "arques" and prof.look.beard == "bouc" and prof.look.mustache == "fine")
check("barbier : les autres champs et la couleur omise sont conservés", prof.look.skin == creation.skin
	and prof.look.hairColor == 8 and prof.look.eyes == "amande" and prof.look.eyeColor == 3
	and prof.look.mouth == "coin" and prof.look.marks == "rousseur_joue" and prof.look.shirtCut == "longue")
A.open(P, "barbier", barber)
A.setLook(P, creation)
check("barbier : une session ne peut pas se déclarer en création", prof.look.hair == "nattes" and gold == 350 - barberCost)
A.setLook(P, { ctx = "barbier", hair = "couronne", brows = "epais", beard = "tressee", mustache = "guidon" })
check("retour aux choix de création : prix de la façon", prof.look.hair == "couronne" and gold == 350 - barberCost - A.FEE)

local tailor = { root = { Position = Vector3.new(5, 0, 0) } }
A.open(P, "tailleur", tailor)
A.setLook(P, { ctx = "tailleur", shirtCut = "tablier", pantsCut = "renforts", beard = "aucune" })
local afterTailor = 350 - barberCost - 2 * A.FEE - A.UNLOCK.shirtCut - A.UNLOCK.pantsCut
check("tailleur : les deux coupes, sans toucher à la barbe", prof.look.shirtCut == "tablier"
	and prof.look.pantsCut == "renforts" and prof.look.beard == "tressee" and gold == afterTailor)
A.open(P, "tailleur", tailor)
root.Position = Vector3.new(100, 0, 0)
A.setLook(P, { ctx = "tailleur", shirt = 1 })
check("trop loin : refus", prof.look.shirt == creation.shirt and gold == afterTailor)
root.Position = Vector3.zero
gold = 5
A.open(P, "barbier", barber)
A.setLook(P, { ctx = "barbier", hair = "nattes" })
check("pas assez d’or pour la façon : refus", prof.look.hair == "couronne" and gold == 5)

local legacy = { created = true, mode = "villageois", skin = 3, hair = "barbe", hairColor = 4, shirt = 25, pants = 9 }
prof = { look = legacy }
gold = 100
local normalized = Looks.normalize(legacy)
check("ancienne sauvegarde : valeurs implicites du visage", normalized.eyes == "droits" and normalized.eyeColor == 1
	and normalized.brows == "naturels" and normalized.mouth == "sourire" and normalized.marks == "aucune"
	and normalized.beard == "carree" and normalized.mustache == "droite")
A.open(P, "barbier", barber)
A.setLook(P, normalized)
check("ancien visage confirmé sans changement : aucun achat ni écriture", prof.look == legacy and gold == 100)

local character = Instance.new("Model")
local function bodyPart(name, size)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Parent = name, size, character
	return part
end
local head = bodyPart("Head", Vector3.new(1.16, 1.18, 1.16))
local torso = bodyPart("UpperTorso", Vector3.new(2, 1.5, 1))
bodyPart("LowerTorso", Vector3.new(1.8, 0.6, 1))
for _, name in { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" } do
	bodyPart(name, Vector3.new(0.82, 1, 0.80))
end
local decal = Instance.new("Decal")
decal.Name, decal.Parent = "face", head
P.Character = character
A.applyLook(P)
local face = character:FindFirstChild("Visage_WA")
local hair = character:FindFirstChild("Coiffure_WA")
local legacyBeard = face:FindFirstChild("Barbe")
local legacyMustache = face:FindFirstChild("Moustache")
check("ancien look rendu avec ses couleurs et sa coupe", head.Color == WG.SKINS[3]
	and not head:FindFirstChild("face") and torso.Color == WG.SHIRTS[25] and character.LeftUpperLeg.Color == WG.PANTS[9]
	and #hair:GetChildren() == 2 and not character:FindFirstChild("Tenue_WA"))
check("ancienne coupe barbu : géométrie historique conservée",
	#face:GetChildren() == 11 and legacyBeard and legacyMustache
	and (legacyBeard.Size - Vector3.new(0.95, 0.42, 0.22)).Magnitude < 0.0001
	and (legacyMustache.CFrame.Position - (head.CFrame * CFrame.new(0, -0.17, -0.6)).Position).Magnitude < 0.0001)
Looks.peindre(character, legacy, { covered = true })
check("ancienne coupe barbu sous casque : cheveux et barbe masqués",
	#character.Coiffure_WA:GetChildren() == 0 and not character.Visage_WA:FindFirstChild("Barbe"))
P.Character = nil
A.setLook(P, { ctx = "barbier", hair = "court" })
check("changer l’ancienne coupe conserve la barbe implicite", prof.look.hair == "court"
	and prof.look.beard == "carree" and prof.look.mustache == "droite" and gold == 100 - A.FEE)

local function welded(layer)
	if not layer then return false end
	for _, part in layer:GetChildren() do
		local weld = part:FindFirstChildWhichIsA("WeldConstraint")
		if not weld or not weld.Part0 or weld.Part0.Parent ~= character or weld.Part1 ~= part
			or part.CanCollide or part.CanQuery or part.CanTouch or not part.Massless then return false end
	end
	return true
end
Looks.peindre(character, creation)
face = character.Visage_WA
check("aperçu : iris, barbe, moustache, rousseur et cicatrice", face:FindFirstChild("Iris").Color == Looks.EYE_COLORS[3]
	and face:FindFirstChild("Rousseur") and face:FindFirstChild("Cicatrice") and face:FindFirstChild("Moustache")
	and face:FindFirstChild("Tresse"))
check("cheveux, visage et tenue soudés et sans collision", welded(character.Coiffure_WA)
	and welded(face) and welded(character.Tenue_WA) and character.Tenue_WA:FindFirstChild("Ourlet") and character.Tenue_WA:FindFirstChild("Guetre"))
local oldTenue = character.Tenue_WA
Looks.peindre(character, legacy)
check("repeindre détruit les anciennes couches", face.Parent == nil and oldTenue.Parent == nil
	and not character:FindFirstChild("Tenue_WA") and not character.Visage_WA:FindFirstChild("Cicatrice"))
for _, field in Looks.FIELDS do
	for _, choice in field.choices or {} do
		local look = table.clone(creation)
		look[field.key] = choice[1]
		Looks.peindre(character, look)
	end
end

character:Destroy()
mod:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
