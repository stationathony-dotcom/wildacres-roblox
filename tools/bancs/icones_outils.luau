-- (Re)fait ReplicatedStorage.IconesOutils : une maquette (Model) par outil de ServerStorage.Outils,
-- et ReplicatedStorage.IconesObjets : une maquette par RESSOURCE (nommée par l'id d'objet), tirée
-- des modèles du décor. Pièces seules, ancrées, sans script ni invite. Le client s'en sert pour les
-- icônes 3D de la barre rapide et du sac (Hud.objectViewport). À relancer si un modèle change.
local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("IconesOutils")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "IconesOutils"
local out = {}
for _, tool in game:GetService("ServerStorage").Outils:GetChildren() do
	local m = Instance.new("Model")
	m.Name = tool.Name
	local n = 0
	for _, d in tool:GetDescendants() do
		if d:IsA("BasePart") then
			local c = d:Clone()
			c:ClearAllChildren()
			for _, k in d:GetChildren() do
				if k:IsA("SpecialMesh") or k:IsA("Decal") or k:IsA("Texture") or k:IsA("SurfaceAppearance") then
					k:Clone().Parent = c
				end
			end
			c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch = true, false, false, false
			c.Parent = m
			n += 1
		end
	end
	m.Parent = folder
	table.insert(out, tool.Name .. "=" .. n)
end
folder.Parent = RS

-- ressources : id d'objet -> modèle du décor (et, si besoin, une seule pièce / sous-modèle)
local OBJETS = {
	wood = { "Tronc_Couche" }, stone = { "Rocher" }, coal = { "Filon_Charbon" }, copper_ore = { "Filon_Cuivre" },
	ore = { "Filon_Fer" }, gold_ore = { "Filon_Or" }, clay = { "Argile" }, flower = { "Fleurs" }, mushroom = { "Champignon" },
	fiber = { "Touffe" }, berries = { "Buisson" }, wheat = { "Champ_Ble", "Touffe" }, hay = { "Botte_Foin" },
}
local old2 = RS:FindFirstChild("IconesObjets")
if old2 then
	old2:Destroy()
end
local objs = Instance.new("Folder")
objs.Name = "IconesObjets"
local Modeles = game:GetService("ServerStorage").Modeles
for id, spec in OBJETS do
	local src = Modeles:FindFirstChild(spec[1])
	if src and spec[2] then
		src = src:FindFirstChild(spec[2])
	end
	if src then
		local m = Instance.new("Model")
		m.Name = id
		local n = 0
		for _, d in src:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 1 then
				local c = d:Clone()
				c:ClearAllChildren()
				c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch = true, false, false, false
				c.Parent = m
				n += 1
			end
		end
		m.Parent = objs
		table.insert(out, id .. "=" .. n)
	else
		table.insert(out, id .. "=ABSENT")
	end
end
objs.Parent = RS
return table.concat(out, ", ")
