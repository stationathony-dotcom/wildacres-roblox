-- Livres (19/11, interface § 9 de « à ne pas oublier ») : le BESTIAIRE du joueur. Une fiche par
-- créature déjà vaincue (collection « creatures ») : niveau, humeur, où et quand on la croise, ce
-- qu'elle laisse ; les autres restent « ??? » (on sait seulement combien il en reste à découvrir).
-- Ouvert par /bestiaire ou en touchant « Créatures » dans l'onglet Collections de la fiche [P].
-- Affiché par Livre.client (événement « Livre » : { titre, sous, lignes = { { t, x } } }).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Livres = {}
local G
local remote

local BIOME = { prairie = "prairie", foret = "forêt", desert = "désert", neige = "neige", marais = "marais" }

function Livres.init(g)
	G = g
	remote = ReplicatedStorage:FindFirstChild("Livre") or Instance.new("RemoteEvent")
	remote.Name = "Livre"
	remote.Parent = ReplicatedStorage
	G.Interact.onAction("livre_bestiaire", function(player)
		Livres.bestiaire(player)
	end)
	G.Interact.onAction("livre_animaux", function(player)
		Livres.animaux(player)
	end)
	G.Interact.onAction("livre_cultures", function(player)
		Livres.cultures(player)
	end)
end

function Livres.send(player: Player, d)
	remote:FireClient(player, d)
end

-- où vit une créature : { "prairie (jour)", "forêt (nuit)" … }
local whereCache = nil
local function whereOf(kind: string): string
	if not whereCache then
		whereCache = {}
		local B = G.Bestiaire
		local W = G.WG or {}
		for _, part in { { rawget(B, "DAY"), "jour" }, { rawget(B, "NIGHT"), "nuit" }, { W.BIOME_FOES, "jour" }, { W.BIOME_FAUNA, "jour" } } do
			for biome, list in part[1] or {} do
				for _, k in list do
					whereCache[k] = whereCache[k] or {}
					local label = (BIOME[biome] or biome) .. " (" .. part[2] .. ")"
					if not table.find(whereCache[k], label) then
						table.insert(whereCache[k], label)
					end
				end
			end
		end
	end
	local w = whereCache[kind]
	return w and table.concat(w, ", ") or "lieux secrets"
end

local function mood(k): string
	if k.boss then
		return "boss"
	elseif k.passive then
		return "paisible"
	elseif k.neutral then
		return "neutre (riposte)"
	end
	return "hostile"
end

function Livres.rows(player: Player)
	local p = G.Joueurs.get(player)
	local seen = (p and p.col and p.col.creatures) or {}
	local kinds = G.Enemies.KINDS
	local known, total = {}, 0
	for id, k in kinds do
		total += 1
		if seen[id] then
			table.insert(known, { id = id, k = k })
		end
	end
	table.sort(known, function(a, b)
		if (a.k.level or 1) ~= (b.k.level or 1) then
			return (a.k.level or 1) < (b.k.level or 1)
		end
		return (a.k.name or a.id) < (b.k.name or b.id)
	end)
	local lines = {}
	for _, e in known do
		local k = e.k
		local loot = {}
		for _, l in k.loot or {} do
			local info = G.Config.ITEMS[l[1]]
			if info and not table.find(loot, info.name) then
				table.insert(loot, info.name)
			end
		end
		local pr = G.Config.Prises and G.Config.Prises.KINDS and G.Config.Prises.KINDS[e.id]
		local mat = pr and G.Config.ITEMS[pr.mat]
		if mat then
			table.insert(loot, mat.name .. " (rare)")
		end
		table.insert(lines, {
			t = string.format("%s · niveau %d · %s", k.name or e.id, k.level or 1, mood(k)),
			x = string.format("%s points de vie%s. Vit : %s.%s", tostring(k.hp or "?"), (k.dmg or 0) > 0 and (", frappe " .. k.dmg) or "",
				whereOf(e.id), #loot > 0 and (" Laisse : " .. table.concat(loot, ", ") .. ".") or ""),
		})
	end
	return lines, #known, total
end

function Livres.bestiaire(player: Player)
	local lines, n, total = Livres.rows(player)
	if n == 0 then
		lines = { { t = "Pages blanches", x = "Aucune créature vaincue pour l'instant. Chaque bête abattue y laisse sa fiche." } }
	end
	Livres.send(player, { titre = "📕 Bestiaire", sous = string.format("%d créature(s) sur %d · %d encore à découvrir", n, total, total - n), lignes = lines })
end

-- Mes bêtes (19/11, « listes ennemi.txt » § interface : menu des animaux) : bêtes de ferme (où,
-- produit prêt), compagnons (confiance, faim), montures (écurie) ; places libres dans les abris.
function Livres.animaux(player: Player)
	local pid = G.Util.pid(player)
	local lines = {}
	local farm, n = {}, 0
	for key, rs in G.world.regions do
		for id, st in rs.animals or {} do
			if st.owner == pid and not st.gone then
				n += 1
				local kind
				for _, d in rs.myAnimals or {} do
					if d.id == id then
						kind = d.kind
						break
					end
				end
				local a = kind and G.Config.ANIMALS[kind]
				local name = a and a.name or "Bête"
				farm[name] = farm[name] or { n = 0, ready = 0, where = {}, best = 0, sum = 0 }
				local f = farm[name]
				f.n += 1
				local rend = G.Animals and rawget(G.Animals, "yieldOf") and G.Animals.yieldOf({ id = id, state = st }) or 1
				f.sum += rend
				f.best = math.max(f.best, rend)
				if st.product then
					f.ready += 1
				end
				f.where[key] = true
			end
		end
	end
	local cap = G.Animals and rawget(G.Animals, "capacity") and G.Animals.capacity(pid) or n
	for name, f in farm do
		local regions = 0
		for _ in f.where do
			regions += 1
		end
		table.insert(lines, { t = string.format("🐄 %s × %d", name, f.n), x = string.format("%s · %d région(s) · lignée moyenne %d %%, meilleure %d %%.",
			f.ready > 0 and (f.ready .. " produit(s) à récolter") or "rien à récolter pour l'instant", regions, math.floor(f.sum / f.n * 100 + 0.5), math.floor(f.best * 100 + 0.5)) })
	end
	local C = G.Compagnons and rawget(G.Compagnons, "recordsOf")
	for _, rec in (C and C(pid)) or {} do
		if not (G.Config.UNITS and G.Config.UNITS[rec.kind]) then
			local k = G.Enemies.KINDS[rec.kind]
			table.insert(lines, { t = "🐾 " .. ((k and k.name) or rec.kind) .. " (compagnon)", x = string.format("Confiance %d / 100%s · %s.", rec.trust or 0,
				(rec.hungry or 0) > 0 and (" · affamé depuis " .. rec.hungry .. " jour(s)") or " · nourri", rec.mode == "guard" and "garde son poste" or "te suit") })
		end
	end
	for _, l in G.Horses.describe(player) do
		table.insert(lines, { t = "🐎 Monture", x = l })
	end
	if #lines == 0 then
		lines[1] = { t = "Aucune bête", x = "Les fermiers vendent des bêtes ; on apprivoise les animaux sauvages avec un appât." }
	end
	Livres.send(player, { titre = "🐾 Mes bêtes", sous = string.format("Ferme : %d / %d places (chaque abri en ajoute)", n, cap), lignes = lines })
end

-- Carnet des cultures : sélection de chaque culture récoltée (Farm.selectionLevel)
function Livres.cultures(player: Player)
	local p = G.Joueurs.get(player)
	local sel = (p and p.selection) or {}
	local lines = {}
	for _, id in G.Config.CROP_ORDER do
		local n = sel[id]
		if n then
			local crop = G.Config.CROPS[id]
			local lvl = G.Farm.selectionLevel(n)
			local nextAt = lvl < G.Farm.SEL_MAX and (10 * (lvl + 1) ^ 2) or nil
			table.insert(lines, {
				t = string.format("%s %s · sélection %d / %d", crop.icon or "🌱", crop.name, lvl, G.Farm.SEL_MAX),
				x = string.format("%d récolte(s)%s. +%d %% de récoltes doubles%s.", n, nextAt and (" (niveau suivant à " .. nextAt .. ")") or "", lvl * 6, lvl >= 3 and ", parfois triples" or ""),
			})
		end
	end
	if #lines == 0 then
		lines[1] = { t = "Carnet vierge", x = "Chaque culture récoltée chez soi s'améliore avec le temps (sélection des semences)." }
	end
	Livres.send(player, { titre = "🌾 Carnet des cultures", sous = "Plus on récolte une culture, plus ses récoltes sont belles", lignes = lines })
end

return Livres
