-- Villes fondées par les joueurs (19/11, « à ne pas oublier » § 10) : avec une CHARTE DE VILLE dans
-- le sac, « /fonder <nom> » fonde une ville à l'endroit où l'on se tient (loin des villages et des
-- autres villes). Rien d'autre n'est imposé : la ville est ce que les joueurs y bâtissent.
--   · son nom s'affiche en haut de l'écran à qui y entre (dossier ReplicatedStorage.Villes) ;
--   · des HABITANTS (PNJ) viennent s'y installer : un par lit posé dans la ville (RADIUS studs), le
--     lendemain matin — ils y vivent, travaillent, voient ce qui s'y passe (témoins) comme ailleurs ;
--   · pas de plafond : plus de lits = plus d'habitants (c'est le bois et le travail qui limitent).
-- État (monde) : G.world.extra.villes[id] = { name, x, z, founder, founderName, day }.
-- Les habitants sont posés par Metiers.spawnTown (apparence, noms, remplacement des disparus).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local Villes = {}
local G
local folder

Villes.RADIUS = 70 -- studs autour du centre : la ville
Villes.MIN_GAP = 320 -- studs : distance minimale à un village ou une autre ville

function Villes.init(g)
	G = g
	folder = ReplicatedStorage:FindFirstChild("Villes") or Instance.new("Folder")
	folder.Name = "Villes"
	folder.Parent = ReplicatedStorage
	-- passage Codex (21/11) : la charte utilisée depuis le sac → même validation que /fonder
	-- Action:FireServer("ville_fonder", { nom = "…" }) ; réponse par toast (« refus » si impossible)
	if G.Interact and G.Interact.onAction then
		G.Interact.onAction("ville_fonder", function(player, data)
			local nom = type(data) == "table" and type(data.nom) == "string" and data.nom or nil
			local ok, msg = Villes.found(player, nom)
			G.Util.toast(player, msg, ok and "big" or "refus")
		end)
	end
end

local function all()
	G.world.extra = G.world.extra or {}
	G.world.extra.villes = G.world.extra.villes or {}
	return G.world.extra.villes
end
Villes.all = all

-- publie les villes au client (nom + position, pour le bandeau du lieu)
function Villes.publish()
	if not folder then
		return
	end
	for _, c in folder:GetChildren() do
		c:Destroy()
	end
	for id, v in all() do
		local f = Instance.new("Configuration")
		f.Name = id
		f:SetAttribute("Name", v.name)
		f:SetAttribute("X", v.x)
		f:SetAttribute("Z", v.z)
		f:SetAttribute("R", Villes.RADIUS)
		f:SetAttribute("Founder", v.founderName)
		f.Parent = folder
	end
end

-- la ville qui contient cette position (nil sinon)
function Villes.at(pos: Vector3)
	for id, v in all() do
		if Vector2.new(v.x - pos.X, v.z - pos.Z).Magnitude <= Villes.RADIUS then
			return v, id
		end
	end
	return nil
end

local function filter(player: Player, text: string): string?
	local ok, res = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		return RunService:IsStudio() and text or nil
	end
	if string.find(res, "#", 1, true) then
		return nil
	end
	return res
end
Villes.filter = filter -- remplaçable par les bancs

function Villes.found(player: Player, name: string?): (boolean, string)
	name = name and string.gsub(name, "^%s+", ""):gsub("%s+$", "") or ""
	local len = utf8.len(name) -- en lettres, pas en octets (accents) ; nil = UTF-8 invalide
	if len then
		name = utf8.nfcnormalize(name) -- « é » composé et décomposé comptent pour une seule lettre
		len = utf8.len(name)
	end
	len = len or 0
	if len < 3 or len > 24 then
		return false, "/fonder <nom>  (3 à 24 lettres) — il faut une Charte de ville dans ton sac."
	end
	if (G.Joueurs.count(player, "charter") or 0) < 1 then
		return false, "Il te faut une Charte de ville (établi : planches, pierre, cordes, encre…)."
	end
	local root = G.Util.root(player)
	if not root then
		return false, "Où es-tu ?"
	end
	local pos = root.Position
	local Q = G.Quetes and rawget(G.Quetes, "villages")
	for _, v in (Q and Q()) or {} do
		if Vector2.new(v.x - pos.X, v.z - pos.Z).Magnitude < Villes.MIN_GAP then
			return false, "Trop près de " .. v.name .. " : une ville se fonde loin des villages."
		end
	end
	for _, v in all() do
		if Vector2.new(v.x - pos.X, v.z - pos.Z).Magnitude < Villes.MIN_GAP then
			return false, "Trop près de la ville de " .. v.name .. "."
		end
	end
	if G.Util.isWater(pos.X, pos.Z) then
		return false, "On ne fonde pas une ville sur l'eau."
	end
	local clean = Villes.filter(player, name)
	if not clean then
		return false, "Ce nom n'est pas possible, choisis-en un autre."
	end
	for _, v in all() do
		if string.lower(v.name) == string.lower(clean) then
			return false, "Une ville porte déjà ce nom."
		end
	end
	if not G.Joueurs.take(player, "charter", 1) then
		return false, "Il te faut une Charte de ville."
	end
	local id = G.Util.newId("ville")
	all()[id] = { name = clean, x = math.floor(pos.X), z = math.floor(pos.Z), founder = G.Util.pid(player), founderName = player.DisplayName, day = G.world.day }
	Villes.publish()
	G.Social.bump(player, "villes")
	G.Joueurs.sync(player)
	return true, "🏰 Tu fondes " .. clean .. " ! Pose des lits : des habitants viendront s'y installer."
end

-- lits posés dans la ville (un habitant par lit)
function Villes.beds(v)
	local beds = {}
	for _, rs in G.world.regions do
		for _, d in rs.placed or {} do
			if d.item == "bed" and Vector2.new(d.x - v.x, d.z - v.z).Magnitude <= Villes.RADIUS then
				table.insert(beds, d)
			end
		end
	end
	table.sort(beds, function(a, b)
		return tostring(a.id) < tostring(b.id)
	end)
	return beds
end

-- villes dont le centre est dans cette région chargée
local function townsIn(reg)
	local out = {}
	for id, v in all() do
		local r = G.World.regionAt(Vector3.new(v.x, 0, v.z))
		if r == reg then
			table.insert(out, { id = id, v = v })
		end
	end
	return out
end

local published = false
function Villes.onRegionLoad(reg)
	if not published then
		published = true -- première région chargée : le monde est là, on publie ses villes
		Villes.publish()
	end
	for _, t in townsIn(reg) do
		if G.Metiers and rawget(G.Metiers, "spawnTown") then
			pcall(G.Metiers.spawnTown, reg, t.id, t.v, Villes.beds(t.v))
		end
	end
end

-- chaque matin : de nouveaux habitants pour les nouveaux lits
function Villes.newDay()
	for _, reg in G.World.loaded do
		Villes.onRegionLoad(reg)
	end
	Villes.publish()
end

function Villes.describe(): { string }
	local lines = {}
	for _, v in all() do
		table.insert(lines, string.format("🏰 %s — fondée par %s le jour %d · %d lit(s)", v.name, v.founderName or "?", v.day or 0, #Villes.beds(v)))
	end
	if #lines == 0 then
		lines[1] = "Aucune ville de joueurs sur cette île. (Charte de ville + /fonder <nom>)"
	end
	return lines
end

return Villes
