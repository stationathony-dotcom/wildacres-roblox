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

return Livres
