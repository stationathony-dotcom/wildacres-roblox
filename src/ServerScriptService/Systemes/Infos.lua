-- Infos (21/11) : questions de l'interface au serveur, sans rien changer au jeu, + repères de carte.
-- Préparé pour la 2e vague de Codex (docs/LOTS.md) :
--   · X18 — aperçu du terrain avant de planter le panneau :
--       Remotes.Infos:InvokeServer("parcelle", { x = …, z = … })
--       → { ok = bool, motif = texte|nil, prix = or, n = terrains déjà possédés, half = demi-côté (studs) }
--   · X15 — repères posés par le joueur sur la carte (gardés PAR MONDE, dans G.world.players[uid].marks) :
--       Remotes.Infos:InvokeServer("reperes") → { { id, x, z, sorte, nom } }
--       Action:FireServer("repere_poser", { x = …, z = …, sorte = "village"|"lit"|"parcelle"|"quete"|"perso" })
--       Action:FireServer("repere_retirer", { id = … })
--     Pas de texte libre : le nom est donné par le serveur (lieu le plus proche), donc rien à filtrer.
--     Plafond technique de 200 repères (taille de la sauvegarde du monde), pas une règle de jeu.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Infos = {}
local G

Infos.MAX_MARKS = 200
Infos.SORTES = { village = true, lit = true, parcelle = true, quete = true, perso = true }
local NOM_SORTE = { village = "Village", lit = "Lit", parcelle = "Terrain", quete = "Remise de quête", perso = "Repère" }

local calls = {} -- joueur -> { jetons, horloge } : 10 questions / s au plus
local function allow(player: Player): boolean
	local now = os.clock()
	local b = calls[player]
	if not b then
		b = { 10, now }
		calls[player] = b
	end
	b[1] = math.min(10, b[1] + (now - b[2]) * 10)
	b[2] = now
	if b[1] < 1 then
		return false
	end
	b[1] -= 1
	return true
end

local function finite(v): boolean
	return type(v) == "number" and v == v and v > -1e6 and v < 1e6
end

-- Nom d'un repère : le lieu le plus proche (village, ferme…) s'il est à moins de 2 régions, sinon la sorte
local function nameAt(x: number, z: number, sorte: string): string
	local base = NOM_SORTE[sorte] or "Repère"
	local ok, label = pcall(function()
		local CELL = G.Config.CELL
		local cx, cz = math.floor(x / CELL), math.floor(z / CELL)
		local rx, rz = G.WG.regionOf(cx, cz)
		local best, bestD = nil, math.huge
		for qx = rx - 1, rx + 1 do
			for qz = rz - 1, rz + 1 do
				local poi = G.wg:poiOf(qx, qz)
				if poi then
					local px, pz = poi.x0 + poi.w / 2, poi.z0 + poi.d / 2
					local dd = (px - cx) ^ 2 + (pz - cz) ^ 2
					if dd < bestD then
						best, bestD = poi, dd
					end
				end
			end
		end
		return best and G.WG.placeLabel(best)
	end)
	if ok and type(label) == "string" and label ~= "" then
		return base .. " · " .. label
	end
	return base
end

local function marksOf(player: Player)
	local rec = G.Mondes.playerRecord(player)
	if not rec then
		return nil
	end
	rec.marks = rec.marks or {}
	return rec, rec.marks
end

function Infos.parcelle(player: Player, data)
	if type(data) ~= "table" or not finite(data.x) or not finite(data.z) then
		return nil
	end
	local root = G.Util.root(player)
	local pos = Vector3.new(data.x, root and root.Position.Y or 0, data.z)
	local ok, motif, prix = G.Parcelles.check(player, pos)
	local rec = G.Mondes.playerRecord(player)
	return { ok = ok, motif = motif, prix = prix, n = rec and #G.Parcelles.plotsOf(rec) or 0, half = G.Parcelles.HALF }
end

function Infos.reperes(player: Player)
	local _, marks = marksOf(player)
	local out = {}
	for _, m in marks or {} do
		table.insert(out, { id = m.id, x = m.x, z = m.z, sorte = m.sorte, nom = m.nom })
	end
	return out
end

function Infos.poser(player: Player, data): boolean
	if type(data) ~= "table" or not finite(data.x) or not finite(data.z) then
		return false
	end
	local sorte = Infos.SORTES[data.sorte] and data.sorte or "perso"
	local rec, marks = marksOf(player)
	if not rec then
		return false
	end
	if #marks >= Infos.MAX_MARKS then
		G.Util.toast(player, "Ta carte est couverte de repères : retires-en quelques-uns.", "refus")
		return false
	end
	rec.markN = (rec.markN or 0) + 1
	local x, z = math.floor(data.x), math.floor(data.z)
	table.insert(marks, { id = rec.markN, x = x, z = z, sorte = sorte, nom = nameAt(x, z, sorte) })
	return true
end

function Infos.retirer(player: Player, data): boolean
	local id = type(data) == "table" and tonumber(data.id)
	local _, marks = marksOf(player)
	if not id or not marks then
		return false
	end
	for i, m in marks do
		if m.id == id then
			table.remove(marks, i)
			return true
		end
	end
	return false
end

function Infos.init(g)
	G = g
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local rf = remotes:FindFirstChild("Infos")
	if not rf then
		rf = Instance.new("RemoteFunction")
		rf.Name = "Infos"
		rf.Parent = remotes
	end
	rf.OnServerInvoke = function(player, action, data)
		if not allow(player) or not G.world then
			return nil
		end
		if action == "parcelle" then
			return Infos.parcelle(player, data)
		elseif action == "reperes" then
			return Infos.reperes(player)
		end
		return nil
	end
	G.Interact.onAction("repere_poser", function(player, data)
		Infos.poser(player, data)
	end)
	G.Interact.onAction("repere_retirer", function(player, data)
		Infos.retirer(player, data)
	end)
	Players.PlayerRemoving:Connect(function(p)
		calls[p] = nil
	end)
end

return Infos
