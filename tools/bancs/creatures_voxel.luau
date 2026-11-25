-- Banc des silhouettes du bestiaire (chantier A, 25/11, docs/DIRECTION-ARTISTIQUE.md § 2.A) — mode Edit.
-- A1 chaque créature se construit (sans retomber sur l'ancienne forme)
-- A2 silhouettes distinctes : aucune liste de pièces identique (tailles triées)
-- A3 au moins une pièce lumineuse (Neon) et au plus 7 couleurs
-- A4 boss : présence ≥ 12,5 (hauteur, ou moitié de la longueur) ; autres : hauteur entre 2 et 14
-- A5 budget : normal ≤ 90 pièces, élite ≤ 140, boss ≤ 260
-- A9 soudure : seule « Base » est ancrée, toutes les autres pièces lui sont soudées
local folder = game.ServerScriptService.Systemes:Clone()
local B = require(folder.Bestiaire)
local LIMIT = { normal = 90, elite = 140, boss = 260 }
local fails, seen, n = {}, {}, 0
local warned = {}
local conn = game:GetService("LogService").MessageOut:Connect(function(msg)
	local id = string.match(msg, "silhouette de (%S+)")
	if id then
		warned[id] = msg
	end
end)
local ids = {}
for id in B.KINDS do
	table.insert(ids, id)
end
table.sort(ids)
for _, id in ids do
	local k = B.KINDS[id]
	if k.model and not string.match(k.model, "^Bete_") then
		continue -- modèle fait à la main (ServerStorage.Modeles, couloir Codex)
	end
	n += 1
	local ok, m = pcall(B.build, "Bete_" .. id)
	if not ok or not m then
		table.insert(fails, "A1 " .. id .. " : " .. tostring(m))
		continue
	end
	if m:GetAttribute("Silhouette") ~= true then
		table.insert(fails, "A1 " .. id .. " retombe sur l'ancienne forme")
	end
	local parts, cols, neon, anchored, welded = 0, {}, 0, 0, 0
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "Base" then
			parts += 1
			cols[p.Color:ToHex()] = true
			if p.Material == Enum.Material.Neon then
				neon += 1
			end
			if p.Anchored then
				anchored += 1
			end
			local w = p:FindFirstChildOfClass("WeldConstraint")
			if w and w.Part0 == m.PrimaryPart then
				welded += 1
			end
		end
	end
	local nc = 0
	for _ in cols do
		nc += 1
	end
	local _, size = m:GetBoundingBox()
	local tier = k.boss and "boss" or (k.elite and "elite" or "normal")
	-- empreinte = la liste triée des tailles de pièces (deux créatures qui ne diffèrent que par la couleur
	-- ont la même liste)
	local dims = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "Base" then
			table.insert(dims, string.format("%.2f,%.2f,%.2f", p.Size.X, p.Size.Y, p.Size.Z))
		end
	end
	table.sort(dims)
	local sig = table.concat(dims, ";")
	if seen[sig] then
		table.insert(fails, "A2 " .. id .. " a la même silhouette que " .. seen[sig])
	end
	seen[sig] = id
	if neon == 0 then
		table.insert(fails, "A3 " .. id .. " : aucune lueur")
	end
	if nc > 7 then
		table.insert(fails, string.format("A3 %s : %d couleurs", id, nc))
	end
	local presence = math.max(size.Y, math.max(size.X, size.Z) * 0.5)
	if k.boss and presence < 12.5 then
		table.insert(fails, string.format("A4 boss %s trop petit (%.1f)", id, presence))
	elseif not k.boss and (size.Y < 1 or size.Y > 14) then
		table.insert(fails, string.format("A4 %s hauteur %.1f", id, size.Y))
	end
	if parts > LIMIT[tier] then
		table.insert(fails, string.format("A5 %s [%s] %d pièces", id, tier, parts))
	end
	if anchored > 0 or welded ~= parts or not (m.PrimaryPart and m.PrimaryPart.Anchored) then
		table.insert(fails, string.format("A9 %s : %d ancrées, %d/%d soudées", id, anchored, welded, parts))
	end
	m:Destroy()
end
task.wait()
conn:Disconnect()
for id, msg in warned do
	table.insert(fails, "A1 " .. id .. " retombe sur l'ancienne forme : " .. msg)
end
folder:Destroy()
table.sort(fails)
if #fails == 0 then
	return string.format("creatures_voxel OK : %d créatures", n)
end
return string.format("ÉCHEC creatures_voxel : %d problème(s) sur %d créatures\n", #fails, n) .. table.concat(fails, "\n")
