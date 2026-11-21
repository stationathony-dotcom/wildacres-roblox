-- Outil Edit (21/11) : pose une PLANCHE de miniatures (ReplicatedStorage.IconesObjets ou IconesEquipement) sur une
-- grille 8 × 6 loin du monde. Les noms ne s'affichent pas en capture : l'outil rend la liste ordonnée (`noms`).
--   loadstring(H:GetAsync(".../banc?f=planche_miniatures"))("IconesObjets", 1)   -- planche n° 1 (objets 1 à 48)
-- Rend : { n = nombre posé, total = …, camera = { pos, look } } pour screen_capture. Efface la planche précédente.
-- Ordre : alphabétique des identifiants (« de 1 à Z »).
local dossier, num = ...
dossier = dossier or "IconesObjets"
num = tonumber(num) or 1
local RS = game:GetService("ReplicatedStorage")
local src = RS:FindFirstChild(dossier)
assert(src, "dossier introuvable : " .. tostring(dossier))
local COLS, ROWS, STEP = 8, 6, 6
local PER = COLS * ROWS
local ids = {}
for _, m in src:GetChildren() do
	if m:IsA("Model") then
		table.insert(ids, m.Name)
	end
end
table.sort(ids)
local old = workspace:FindFirstChild("PlancheMiniatures")
if old then
	old:Destroy()
end
local f = Instance.new("Folder")
f.Name = "PlancheMiniatures"
local base = Vector3.new(-3000, 700, -3000)
local sol = Instance.new("Part")
sol.Anchored, sol.Size = true, Vector3.new(COLS * STEP + 4, 1, ROWS * STEP + 4)
sol.Position = base + Vector3.new((COLS - 1) * STEP / 2, -0.5, (ROWS - 1) * STEP / 2)
sol.Color, sol.Material = Color3.fromRGB(58, 64, 54), Enum.Material.SmoothPlastic
sol.Parent = f
local n = 0
local noms = {} -- ordre de lecture : ligne par ligne, de gauche à droite vue de la caméra
for i = (num - 1) * PER + 1, math.min(num * PER, #ids) do
	local k = i - (num - 1) * PER - 1
	local col, row = k % COLS, math.floor(k / COLS)
	local at = base + Vector3.new(col * STEP, 0, row * STEP)
	local m = src[ids[i]]:Clone()
	-- mise à l'échelle : la plus grande dimension vaut 3,6 studs, posé sur la dalle
	local cf, size = m:GetBoundingBox()
	local s = 3.6 / math.max(size.X, size.Y, size.Z, 0.01)
	m:ScaleTo(math.clamp(m:GetScale() * s, 0.05, 20))
	cf, size = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + (at + Vector3.new(0, size.Y / 2 + 0.05, -0.6) - cf.Position))
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	m.Parent = f
	table.insert(noms, i .. " " .. ids[i])
	n += 1
end
f.Parent = workspace
local centre = base + Vector3.new((COLS - 1) * STEP / 2, 0, (ROWS - 1) * STEP / 2)
return {
	n = n,
	noms = table.concat(noms, " · "),
	total = #ids,
	planches = math.ceil(#ids / PER),
	camera = { centre.X, centre.Y + 34, centre.Z + 26 },
	look = { centre.X, centre.Y, centre.Z + 1 },
}
