-- Herbe haute (19/11, image cible : prairies en herbe drue) : placement DÉTERMINISTE partagé par le
-- client (qui dessine les touffes autour du joueur, HerbeHaute.client) et le serveur (qui valide la
-- fauche, Systemes/Fauche). Grille de CELL studs ; une case a une touffe ou pas selon un hash
-- (graine du monde + coordonnées) ; la sorte dépend du sol (matériau de terrain sous la case).
-- Rien n'est envoyé sur le réseau pour l'afficher : seules les cases fauchées sont publiées
-- (attributs du dossier ReplicatedStorage.Fauche, effacés quand l'herbe repousse).

local HH = {}

HH.CELL = 5
HH.REACH = 14 -- studs entre le joueur et la touffe (comme les moissons)

-- par matériau de terrain : densité (0..1), hauteur min/max, couleurs, ce que donne la fauche
HH.SORTES = {
	[Enum.Material.Grass] = {
		nom = "herbe", densite = 0.32, h = { 1.6, 2.8 }, larg = 0.55,
		couleurs = { Color3.fromRGB(86, 150, 54), Color3.fromRGB(104, 166, 60), Color3.fromRGB(122, 170, 66), Color3.fromRGB(150, 168, 70) },
		donne = { fiber = { 0, 1 } }, bonus = "seed_wheat", bonusP = 0.06,
	},
	[Enum.Material.Mud] = {
		nom = "roseaux", densite = 0.22, h = { 2.8, 4.4 }, larg = 0.4,
		couleurs = { Color3.fromRGB(92, 118, 60), Color3.fromRGB(116, 124, 66), Color3.fromRGB(80, 104, 56) },
		donne = { fiber = { 1, 2 } },
	},
	[Enum.Material.Sand] = {
		nom = "oyats", densite = 0.07, h = { 1.2, 2 }, larg = 0.45,
		couleurs = { Color3.fromRGB(190, 182, 110), Color3.fromRGB(170, 168, 96) },
		donne = { fiber = { 0, 1 } },
	},
}

-- hash entier rapide (pas de chaîne : le client en calcule des centaines par seconde)
local function mix(a: number, b: number, s: number): number
	local h = bit32.bxor(s, 0x9E3779B9)
	h = bit32.bxor(h, a * 374761393)
	h = bit32.lrotate(h, 13)
	h = bit32.bxor(h, b * 668265263)
	h = bit32.lrotate(h, 17) * 1274126177
	h = bit32.bxor(h, bit32.rshift(h, 16))
	return h % 1000003 / 1000003
end

local function seedNum(): number
	local s = workspace:GetAttribute("Seed")
	return (tonumber(s) or 0) % 2147483647
end

-- case → nil ou { x, z, r (tirage 0..1 pour la densité), t (taille 0..1), v (variante), yaw }
function HH.at(cx: number, cz: number)
	local s = seedNum()
	local r = mix(cx, cz, s)
	if r > 0.5 then
		return nil -- au-delà de la plus forte densité : jamais de touffe
	end
	local ox = mix(cx, cz, s + 1)
	local oz = mix(cx, cz, s + 2)
	return {
		x = (cx + 0.15 + ox * 0.7) * HH.CELL,
		z = (cz + 0.15 + oz * 0.7) * HH.CELL,
		r = r,
		t = mix(cx, cz, s + 3),
		v = mix(cx, cz, s + 4),
		yaw = mix(cx, cz, s + 5) * 360,
	}
end

-- la touffe de cette case pousse-t-elle sur ce sol ?
function HH.sorteFor(info, material: Enum.Material)
	local sorte = HH.SORTES[material]
	if sorte and info and info.r < sorte.densite then
		return sorte
	end
	return nil
end

function HH.id(cx: number, cz: number): string
	return "fh|" .. cx .. "|" .. cz
end

function HH.parse(id: string): (number?, number?)
	local a, b = string.match(id, "^fh|(%-?%d+)|(%-?%d+)$")
	return tonumber(a), tonumber(b)
end

-- nom d'attribut (lettres, chiffres, _ seulement) d'une case fauchée
function HH.attr(cx: number, cz: number): string
	return "c" .. (cx + 500000) .. "_" .. (cz + 500000)
end

return HH
