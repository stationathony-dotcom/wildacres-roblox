-- Studio Edit : enrichit les outils et régénère les miniatures utilisées en jeu.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local configCopy = RS.Shared:Clone()
configCopy.Parent = SS
local ok, C, catalogue = pcall(function()
	return require(configCopy.Config), require(configCopy.Catalogue)
end)
configCopy:Destroy()
assert(ok, tostring(C))

local rgb, v, cf = Color3.fromRGB, Vector3.new, CFrame.new
local wood, leather, steel, bronze = rgb(119, 70, 37), rgb(66, 39, 29), rgb(158, 178, 197), rgb(190, 129, 57)
local function part(parent, name, size, transform, color, material, shape)
	local class = ({ Wedge = "WedgePart", Corner = "CornerWedgePart", Ladder = "TrussPart" })[shape] or "Part"
	local p = Instance.new(class)
	p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, transform, color, material
	if shape == "Ball" or shape == "Cylinder" then p.Shape = Enum.PartType[shape] end
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local tools = SS:WaitForChild("Outils")
local function details(name, build)
	local tool = assert(tools:FindFirstChild(name), name)
	local handle = assert(tool:FindFirstChild("Handle"), name)
	local old = tool:FindFirstChild("FinitionsVisuelles")
	if old then old:Destroy() end
	local holder = Instance.new("Model")
	holder.Name = "FinitionsVisuelles"
	local function add(label, size, offset, color, mat, shape)
		local p = part(holder, label, size, handle.CFrame * offset, color, mat, shape)
		p.Anchored, p.Massless = false, true
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = handle, p, p
	end
	build(tool, handle, add)
	holder.Parent = tool
end
local function ring(add, y, width, diameter, color, mat)
	add("Bague", v(width, diameter, diameter), cf(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), color, mat, "Cylinder")
end
local metal, brass, fabric = Enum.Material.Metal, Enum.Material.Foil, Enum.Material.Fabric
details("Épée", function(tool, handle, add)
	handle.Color, handle.Material = leather, fabric
	tool.Lame.Color, tool.Garde.Color = steel, bronze
	for i=-2, 2 do ring(add, i*0.17, 0.075, 0.33, wood, fabric) end
	ring(add, -0.61, 0.21, 0.48, bronze, brass)
	local blade = tool.Lame
	local at = handle.CFrame:ToObjectSpace(blade.CFrame)
	add("Pointe", v(blade.Size.X, 0.28, blade.Size.Z), at * cf(0, blade.Size.Y/2+0.13, 0) * CFrame.Angles(0, 0, math.pi), steel, metal, "Wedge")
	for _, sign in ipairs({-1, 1}) do
		add("Nervure de lame", v(0.102, blade.Size.Y*0.84, 0.026), at * cf(0, -0.10, sign*0.065), rgb(207, 222, 234), metal)
	end
	for _, sign in ipairs({-1, 1}) do
		add("Bout de garde", v(0.26, 0.28, 0.32), handle.CFrame:ToObjectSpace(tool.Garde.CFrame) * cf(sign*0.63, 0, 0), bronze, brass, "Ball")
	end
end)
for _, spec in ipairs({
	{"Hache","Fer",1.4}, {"Pioche","Fer",1.4}, {"Houe","Lame",1.6}, {"Pelle","Pelle",1.6},
	{"Gourdin","Tete",1.05}, {"Canne à pêche","Moulinet",1.65},
}) do
	details(spec[1], function(tool, handle, add)
		handle.Color, handle.Material = wood, Enum.Material.Wood
		for i=0,3 do ring(add, -handle.Size.Y*0.31+i*0.13, 0.083, 0.335, leather, fabric) end
		local head = tool:FindFirstChild(spec[2])
		if head then
			ring(add, spec[3], 0.16, 0.37, bronze, brass)
			if spec[1] ~= "Gourdin" and spec[1] ~= "Canne à pêche" then head.Color = steel end
			local rel = handle.CFrame:ToObjectSpace(head.CFrame)
			for _, sign in ipairs({-1, 1}) do
				add("Rivet", v(0.14, 0.15, 0.15), rel * cf(sign*head.Size.X*0.49, 0, 0), bronze, brass, "Ball")
			end
		end
	end)
end
details("Arrosoir", function(tool, handle, add)
	local spout = handle.CFrame:ToObjectSpace(tool.Bec.CFrame)
	local body = handle.CFrame:ToObjectSpace(tool.Cuve.CFrame)
	tool.Cuve.Color, tool.Bec.Color = rgb(99,137,132), steel
	for _, sign in ipairs({-1,1}) do
		add("Renfort de cuve",v(1.22,0.12,1.62),body*cf(0,sign*0.38,0),bronze,brass)
	end
	add("Pomme d’arrosage",v(0.48,0.48,0.16),spout*cf(0,0,0.53),steel,metal)
end)
details("Graines", function(tool, handle, add)
	local sack = handle.CFrame:ToObjectSpace(tool.Sac.CFrame)
	tool.Sac.Color, tool.Sac.Material = rgb(178,140,90), fabric
	add("Lien",v(0.76,0.10,0.61),sack*cf(0,0.31,0),leather,fabric)
	add("Étiquette",v(0.34,0.32,0.04),sack*cf(0,-0.08,-0.36),rgb(229,202,148),fabric)
end)

local function folder(name)
	local f = RS:FindFirstChild(name)
	if not f then f = Instance.new("Folder") f.Name = name f.Parent = RS end
	return f
end
local toolIcons, itemIcons = folder("IconesOutils"), folder("IconesObjets")
local function publish(container, model)
	local old = container:FindFirstChild(model.Name)
	if old then old:Destroy() end
	model.Parent = container
end
local function miniature(source, id, budget)
	local m = Instance.new("Model")
	m.Name = id
	local parts = {}
	for _, d in source:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.95 then parts[#parts+1] = d end
	end
	local function volume(p) return p.Size.X*p.Size.Y*p.Size.Z end
	table.sort(parts, function(a,b) return volume(a)>volume(b) end)
	for i=1, math.min(#parts, budget) do
		local p = parts[i]:Clone()
		for _, d in p:GetChildren() do
			if not (d:IsA("SpecialMesh") or d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Texture")) then d:Destroy() end
		end
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Parent = m
	end
	if #parts == 0 then m:Destroy() return nil end
	return m
end
for _, tool in tools:GetChildren() do
	local m=miniature(tool, tool.Name, 28)
	if m then publish(toolIcons,m) end
end

local count = 0
local function icon(id, build)
	if not C.ITEMS[id] then return end
	local m = Instance.new("Model")
	m.Name = id
	m:SetAttribute("ApercuDroit", true)
	build(function(name, size, transform, color, material, shape)
		return part(m, name, size, transform, color, material, shape)
	end)
	publish(itemIcons, m)
	count += 1
end
for id,c in pairs({copper_ingot=rgb(203,112,65), iron_ingot=steel, gold_ingot=rgb(237,178,55), glass=rgb(122,194,192), brick=rgb(172,77,51)}) do
	icon(id,function(add)
		for i=0,2 do
			add("Lingot",v(1.46,0.27,0.69),cf(i%2*0.29,i*0.28,0) * CFrame.Angles(0, i*0.17,0),c,metal)
			add("Face polie",v(1.18,0.04,0.51),cf(i%2*0.29,i*0.28+0.145,0)*CFrame.Angles(0,i*0.17,0),c:Lerp(Color3.new(1,1,1),0.2),metal)
		end
	end)
end
for id,c in pairs({bread=rgb(189,112,42), country_bread=rgb(158,87,38), egg=rgb(242,219,174), apple=rgb(174,40,34), tomato=rgb(209,53,31), potato=rgb(153,106,65), melon=rgb(87,133,55), pumpkin=rgb(221,111,28), beetroot=rgb(120,40,67), eggplant=rgb(82,47,113)}) do
	icon(id,function(add)
		local loaf=id=="bread" or id=="country_bread"
		local oval=id=="potato" or id=="eggplant"
		add("Corps",loaf and v(2.0,0.89,1.05) or (oval and v(1.55,0.85,0.95) or v(1.12,id=="egg" and 1.44 or 1.04,1.05)),cf(),c,Enum.Material.SmoothPlastic,"Ball")
		if loaf then
			for i=-1,1 do add("Grigne",v(0.11,0.045,0.58),cf(i*0.39,0.37-math.abs(i)*0.035,0)*CFrame.Angles(0,0.35,0),rgb(244,188,110),Enum.Material.SmoothPlastic,"Ball") end
		elseif id~="egg" and id~="potato" then
			add("Tige",v(0.12,0.32,0.12),cf(0,0.53,0)*CFrame.Angles(0,0,0.22),wood,Enum.Material.Wood)
			add("Feuille",v(0.42,0.1,0.23),cf(0.18,0.54,0)*CFrame.Angles(0,0,0.33),rgb(81,134,54),Enum.Material.Grass,"Ball")
		end
	end)
end
for id,c in pairs({healing_potion=rgb(207,40,51), vial=rgb(152,203,198), bottle=rgb(80,145,100), perfume=rgb(173,91,190), fruit_syrup=rgb(174,59,58), cider=rgb(203,148,62), ink=rgb(48,52,100), honey=rgb(217,153,46), milk=rgb(248,230,197)}) do
	icon(id,function(add)
		local base = id=="healing_potion" and v(1.07,0.98,0.87) or v(0.94,1.14,0.83)
		add("Bouteille",base,cf(),c,Enum.Material.SmoothPlastic,"Ball")
		add("Goulot",v(0.30,0.32,0.30),cf(0,0.60,0),c:Lerp(Color3.new(1,1,1),0.25),Enum.Material.SmoothPlastic)
		add("Bouchon",v(0.23,0.40,0.40),cf(0,0.78,0)*CFrame.Angles(0,0,math.pi/2),wood,Enum.Material.Wood,"Cylinder")
		add("Reflet",v(0.13,0.53,0.06),cf(-0.25,0.10,-0.35)*CFrame.Angles(0,0,-0.18),c:Lerp(Color3.new(1,1,1),0.65),Enum.Material.SmoothPlastic,"Ball")
	end)
end
for id,c in pairs({planks=wood, leather=rgb(128,75,45), cloth=rgb(181,143,104), paper=rgb(234,212,162), wool=rgb(236,225,204)}) do
	icon(id,function(add)
		for i=0,2 do
			add("Couche",v(1.78,0.15,0.82),cf(0,i*0.16,0)*CFrame.Angles(0,i*0.10,0),c:Lerp(rgb(244,222,175),i*0.09),id=="planks" and Enum.Material.WoodPlanks or fabric)
		end
	end)
end
icon("rope",function(add)
	for turn=0,2 do
		for i=0,15 do
			local a=i*math.pi/8
			add("Toron",v(0.30,0.11,0.13),cf(math.cos(a)*0.57,turn*0.10,math.sin(a)*0.57)*CFrame.Angles(0,-a+math.pi/2,0),wood:Lerp(bronze,0.4+0.2*(i%2)),fabric)
		end
	end
end)
icon("flour",function(add)
	add("Sac",v(1.13,1.22,0.86),cf(),rgb(205,178,125),fabric,"Ball")
	add("Liens",v(0.45,0.16,0.42),cf(0,0.56,0),wood,fabric)
	add("Ouverture",v(0.57,0.19,0.51),cf(0,0.68,0),rgb(246,229,186),fabric,"Ball")
end)
local props = 0
for id,info in C.ITEMS do
	if type(info.place)=="string" and not itemIcons:FindFirstChild(id) then
		local src=SS.Modeles:FindFirstChild(info.place)
		local generated=not src and catalogue.build(info.place)
		local m=(src or generated) and miniature(src or generated,id,12)
		if generated then generated:Destroy() end
		if m then publish(itemIcons,m) props+=1 end
	end
	if type(info.place)=="string" then
		local existing = itemIcons:FindFirstChild(id)
		if existing then existing:SetAttribute("ApercuDroit",true) end
	end
end
local blocks = 0
for _, b in C.BLOCKS do
	local id = b.item
	if id then
		icon(id, function(add)
			local compose = C.SHAPE_PARTS[b.shape]
			if compose then
				for _, spec in compose(b.size) do
					local modelPart = C.makeSubPart(spec)
					modelPart.Size, modelPart.CFrame = spec[1], spec[2]
					local shape = modelPart:IsA("WedgePart") and "Wedge" or modelPart:IsA("CornerWedgePart") and "Corner" or modelPart:IsA("Part") and modelPart.Shape.Name or nil
					add("Pièce",modelPart.Size,modelPart.CFrame,b.color,b.mat,shape).Transparency = b.transp or 0
					modelPart:Destroy()
				end
			elseif b.shape == "pillar" then
				add("Pilier",v(b.size.Y,b.size.X,b.size.Z),CFrame.Angles(0,0,math.pi/2),b.color,b.mat,"Cylinder")
			else
				local shape = ({ wedge="Wedge", corner="Corner", ladder="Ladder" })[b.shape]
				add("Pièce",b.size,cf(),b.color,b.mat,shape).Transparency = b.transp or 0
			end
		end)
		blocks += 1
	end
end
local function buildIcon(add, family, c, variant)
	local mat=Enum.Material.SmoothPlastic
	local function shape(n,x,y,z,dx,dy,dz,col,form,angle,material)
		return add(n,v(x,y,z),cf(dx,dy,dz)*CFrame.Angles(0,0,angle or 0),col or c,material or mat,form)
	end
	local function disk(n,d,h,x,y,z,col)
		shape(n,h,d,d,x,y,z,col,"Cylinder",math.pi/2)
	end
	local cream, dark = rgb(235,216,173), rgb(56,40,29)
	if family=="book" then
		shape("Pages",1.22,1.52,0.27,0,0,0,cream)
		for _,s in ipairs({-1,1}) do shape("Couverture",1.31,1.61,0.075,0,0,s*0.17,c) end
		shape("Dos",0.18,1.62,0.40,-0.62,0,0,c)
		shape("Cartouche",0.56,0.36,0.035,0.03,0.13,-0.23,bronze)
	elseif family=="scroll" then
		shape("Feuille",1.22,1.56,0.07,0,0,0,cream)
		for _,s in ipairs({-1,1}) do shape("Rouleau",1.36,0.20,0.20,0,s*0.73,0,cream,"Cylinder") end
		for i=0,2 do shape("Encre",0.80-0.15*i,0.033,0.025,-0.02,0.26-i*0.18,-0.045,dark) end
		shape("Cachet",0.27,0.27,0.06,0.35,-0.43,-0.06,c,"Ball")
	elseif family=="seed" or family=="bag" then
		shape("Sac",1.18,1.31,0.87,0,0,0,c,"Ball",nil,fabric)
		disk("Lien",0.55,0.14,0,0.56,0,leather)
		shape("Étiquette",0.56,0.44,0.05,0,-0.03,-0.43,cream)
		if family=="seed" then
			shape("Germe",0.23,0.12,0.04,-0.07,0.02,-0.47,rgb(55,96,37),"Ball",0.5)
			shape("Germe",0.23,0.12,0.04,0.08,0.05,-0.48,rgb(76,121,42),"Ball",-0.4)
		else shape("Sangle",0.13,1.05,0.055,0,0,-0.45,dark) end
	elseif family=="jar" then
		shape("Flacon",0.99,1.18,0.89,0,0,0,c,"Ball")
		disk("Goulot",0.34,0.31,0,0.57,0,c)
		disk("Bouchon",0.40,0.16,0,0.78,0,wood)
		shape("Reflet",0.14,0.46,0.06,-0.23,0.10,-0.39,c:Lerp(Color3.new(1,1,1),0.66),"Ball")
	elseif family=="bowl" or family=="cup" or family=="pie" then
		local tall=family=="cup"
		disk("Récipient",tall and 0.91 or 1.47,tall and 0.84 or 0.33,0,0,0,wood)
		disk("Bord",tall and 0.97 or 1.55,0.14,0,tall and 0.42 or 0.16,0,cream)
		disk("Surface",tall and 0.83 or 1.39,0.055,0,tall and 0.50 or 0.24,0,c)
		if tall then shape("Anse",0.48,0.45,0.19,0.52,0.07,0,wood,"Ball") end
		if family=="pie" then
			for i=-1,1 do shape("Croûte",0.11,0.06,1.05,i*0.28,0.30,0,bronze,nil,0) end
		end
	elseif family=="fish" then
		shape("Corps",1.64,0.61,0.48,-0.10,0,0,c,"Ball")
		shape("Queue",0.57,0.68,0.11,0.76,0,0,c:Lerp(dark,0.21),"Wedge",math.pi)
		shape("Nageoire",0.42,0.30,0.08,-0.02,0.30,0,c,"Wedge")
		shape("Ventre",0.96,0.15,0.32,-0.18,-0.19,0,cream,"Ball")
		shape("Œil",0.12,0.12,0.08,-0.62,0.11,-0.15,dark,"Ball")
	elseif family=="plant" then
		for i=-1,1 do
			shape("Tige",0.075,1.12,0.075,i*0.21,0,0,wood,nil,-i*0.28)
			shape("Feuille",0.50,0.25,0.16,i*0.30,0.30,-0.025,c,"Ball",i*0.4)
		end
		shape("Lien",0.50,0.13,0.18,0,-0.26,0,cream)
	elseif family=="food" then
		shape("Produit",1.36,0.91,0.97,0,0,0,c,"Ball")
		shape("Détail",0.47,0.12,0.24,-0.18,0.38,-0.05,c:Lerp(cream,0.45),"Ball",0.3)
		if variant%2==0 then shape("Tige",0.14,0.24,0.13,0,0.46,0,wood,nil,0.24) end
	elseif family=="coin" or family=="compass" then
		disk("Monture",1.35,0.25,0,0,0,c)
		disk("Médaillon",1.13,0.08,0,0.15,0,bronze)
		shape("Insigne",0.58,0.045,0.20,0,0.21,0,cream,nil,0,brass)
	elseif family=="fastener" or family=="key" or family=="arrow" then
		local long=family=="arrow"
		shape("Tige",0.15,long and 1.65 or 1.22,0.18,0,0,0,long and wood or c,nil,0,metal)
		shape("Extrémité",long and 0.30 or 0.48,0.27,0.18,0,0.60,0,c,"Wedge")
		shape("Garniture",0.46,0.19,0.22,0,-0.51,0,bronze,nil,0,brass)
	elseif family=="lock" then
		shape("Boîtier",0.91,0.79,0.44,0,-0.19,0,c)
		for _,s in ipairs({-1,1}) do shape("Anse",0.14,0.55,0.17,s*0.29,0.38,0,steel,nil,-s*0.12,metal) end
		shape("Anse",0.55,0.15,0.17,0,0.63,0,steel)
		shape("Serrure",0.15,0.22,0.045,0,-0.19,-0.23,dark)
	elseif family=="cloth" then
		for i=0,2 do shape("Pli",1.41,0.14,0.91,(i%2)*0.12,i*0.15,0,c:Lerp(cream,i*0.09),nil,0,fabric) end
		shape("Liseré",1.42,0.046,0.07,0,0.36,-0.39,cream)
	elseif family=="crate" then
		shape("Caisse",1.39,0.92,0.91,0,0,0,c,nil,0,Enum.Material.WoodPlanks)
		for _,s in ipairs({-1,1}) do shape("Ferrure",0.14,0.94,0.96,s*0.47,0,0,wood) end
		shape("Plaque",0.29,0.20,0.04,0,0.06,-0.47,bronze)
	elseif family=="crystal" or family=="soul" then
		if family=="soul" then
			shape("Orbe",0.94,0.94,0.94,0,0.1,0,c,"Ball")
			disk("Socle",0.93,0.16,0,-0.48,0,bronze)
			shape("Lueur",0.39,0.52,0.15,-0.18,0.21,-0.40,c:Lerp(cream,0.66),"Ball")
		else
			for i=-1,1 do shape("Cristal",0.39,1.26-math.abs(i)*0.38,0.43,i*0.37,0,0,c:Lerp(cream,(i+1)*0.14),i==0 and "Corner" or "Wedge",i*-0.20) end
		end
	elseif family=="armor" then
		local cape = variant==4
		shape(cape and "Cape" or "Plastron",1.00,1.22,cape and 0.20 or 0.54,0,0,0,c,nil,0,fabric)
		for _,s in ipairs({-1,1}) do
			shape("Épaule",0.42,0.32,0.53,s*0.55,0.41,0,c:Lerp(cream,0.21),nil,-s*0.22)
			shape("Ourlet",0.08,0.99,0.05,s*0.42,-0.04,-0.28,bronze)
		end
		shape("Ceinture",1.03,0.15,0.56,0,-0.40,0,leather)
		shape("Boucle",0.22,0.18,0.055,0,-0.40,-0.30,bronze)
	elseif family=="hat" then
		disk("Bord",1.57,0.11,0,-0.33,0,variant==1 and bronze or c)
		shape("Calotte",0.99,variant==5 and 1.13 or 0.72,0.94,0,0.02,0,c,variant==5 and "Wedge" or "Ball")
		disk("Bande",1.03,0.14,0,-0.21,0,leather)
		shape("Ornement",0.23,0.19,0.08,0,-0.20,-0.49,bronze)
	elseif family=="ring" then
		for i=0,9 do
			local a=i*math.pi/5
			shape("Anneau",0.36,0.135,0.18,math.cos(a)*0.51,math.sin(a)*0.51,0,bronze,nil,a+math.pi/2,metal)
		end
		shape("Pierre",0.38,0.34,0.27,0,0.57,-0.03,c,"Ball")
	elseif family=="trophy" then
		disk("Monture",1.22,0.18,0,-0.10,0,leather)
		shape("Trophée",0.89,0.78,0.68,0,0.22,0,c,variant%2==0 and "Ball" or "Corner",0.12)
		for _,s in ipairs({-1,1}) do shape("Griffe",0.23,0.45,0.21,s*0.46,0.14,-0.16,cream,"Wedge",s*0.25) end
	else
		shape("Matière",1.26,0.76,0.87,0,0,0,c,variant%2==0 and "Ball" or "Corner")
		shape("Éclat",0.54,0.44,0.42,0.36,-0.09,-0.26,c:Lerp(cream,0.33),"Wedge",0.31)
	end
end

-- Ces objets ont une silhouette identifiable même à la taille d’une case.
-- Le groupe sert à réutiliser la technique, chaque recette garde sa teinte et ses détails.
local precise = {}
local function specific(ids, build)
	for _, id in ipairs(ids) do
		if C.ITEMS[id] then
			icon(id, function(add) build(add,id) end)
			local model = itemIcons:FindFirstChild(id)
			model:SetAttribute("SilhouetteDediee",true)
			precise[#precise+1] = id
		end
	end
end
local function box(add,n,s,x,y,z,color,mat,tilt)
	return add(n,s,cf(x,y,z) * CFrame.Angles(0,0,tilt or 0),color,mat or Enum.Material.SmoothPlastic)
end
local function round(add,n,s,x,y,z,color)
	return add(n,s,cf(x,y,z),color,Enum.Material.SmoothPlastic,"Ball")
end
local function disc(add,n,diameter,height,x,y,z,color)
	return add(n,v(height,diameter,diameter),cf(x,y,z)*CFrame.Angles(0,0,math.pi/2),color,Enum.Material.SmoothPlastic,"Cylinder")
end
specific({"cheese"},function(add)
	local rind, pale, holes = rgb(224,144,47),rgb(255,207,87),rgb(190,123,32)
	local pose = CFrame.Angles(0,0,math.pi/2)
	add("Pointe triangulaire",v(0.38,1.40,1.55),cf(0,0.02,0)*pose,pale,Enum.Material.SmoothPlastic,"Wedge")
	add("Croûte",v(0.095,1.40,1.55),cf(0,-0.192,0)*pose,rind,Enum.Material.SmoothPlastic,"Wedge")
	for _,h in ipairs({{0.54,-0.39,0.19},{0.39,-0.04,0.16},{0.24,0.29,0.26},{-0.22,0.55,0.16},{0.49,0.59,0.13}}) do
		disc(add,"Cavité",h[3],0.013,h[1],0.212,h[2],holes)
	end
end)
specific({"butter","fat","soap","beeswax","candle_wax"},function(add,id)
	local colors={butter=rgb(250,218,119),fat=rgb(230,194,159),soap=rgb(137,178,151),beeswax=rgb(218,169,71),candle_wax=rgb(233,218,175)}
	box(add,"Pain",v(1.28,0.42,0.78),0,0,0,colors[id])
	local top=colors[id]:Lerp(Color3.new(1,1,1),0.28)
	box(add,id=="soap" and "Marque du savon" or "Face de coupe",v(1.10,0.033,0.61),0,0.226,0,top)
	box(add,"Chant",v(0.07,0.43,0.77),0.63,0,0,colors[id]:Lerp(wood,0.28))
end)
specific({"steak","meat","boar_meat","rabbit_meat","venison","roast","roast_boar","jerky"},function(add,id)
	local cooked=id=="steak" or id=="roast" or id=="roast_boar" or id=="jerky"
	local cut=cooked and rgb(118,57,35) or rgb(175,52,55)
	local thick=id=="jerky" and 0.15 or id:find("roast") and 0.59 or 0.29
	round(add,"Gras extérieur",v(1.59,thick+0.07,1.01),0,0,0,cooked and rgb(193,119,63) or rgb(231,164,136))
	round(add,"Coupe",v(1.47,thick,0.92),0.01,0.048,-0.035,cut)
	for i=-1,1 do
		box(add,cooked and "Marque de cuisson" or "Persillage",v(0.055,0.024,0.51-0.10*math.abs(i)),i*0.28,thick/2+0.043,0,
			cooked and rgb(69,36,24) or rgb(235,178,160),nil,0.03*i)
	end
end)
specific({"apple_pie","meat_pie","pie","galette","honey_cake","omelette","whole_bread"},function(add,id)
	local isBread=id=="whole_bread"
	if isBread then
		round(add,"Miche",v(1.63,0.79,1.28),0,0,0,rgb(137,73,34))
		for i=-1,1 do round(add,"Incision",v(0.11,0.052,0.64),i*0.29,0.34-math.abs(i)*0.031,0,rgb(245,187,102)) end
		return
	end
	local cake=id=="honey_cake"
	local omelette=id=="omelette"
	disc(add,omelette and "Assiette" or "Croûte",1.55,cake and 0.54 or 0.23,0,0,0,omelette and rgb(233,215,184) or rgb(170,95,36))
	disc(add,"Garniture",1.39,0.090,0,cake and 0.30 or 0.15,0,omelette and rgb(255,200,61) or rgb(231,151,62))
	if cake then disc(add,"Couche de miel",1.51,0.06,0,0.055,0,rgb(249,181,59)) end
	if id:find("pie") then
		for i=-1,1 do
			box(add,"Treillis",v(0.10,0.045,1.1),i*0.33,0.21,0,rgb(247,184,92))
			box(add,"Treillis",v(1.1,0.045,0.10),0,0.24,i*0.32,rgb(247,184,92))
		end
	end
end)
specific({"broth","stew","soup","nettle_soup","fish_soup","rabbit_stew","game_stew","porridge","salad","cooked_veg"},function(add,id)
	local green=id=="salad" or id=="nettle_soup" or id=="cooked_veg"
	round(add,"Écuelle",v(1.53,0.55,1.53),0,0,0,rgb(112,66,38))
	disc(add,"Bord tourné",1.57,0.10,0,0.216,0,rgb(178,121,67))
	disc(add,"Contenu",1.38,0.041,0,0.267,0,green and rgb(92,112,45) or id=="porridge" and rgb(221,188,129) or rgb(143,78,36))
	for i=0,5 do
		local a=i*math.pi/3
		local color=green and (i%2==0 and rgb(115,152,60) or rgb(154,173,67)) or (i%2==0 and rgb(214,146,69) or rgb(237,175,107))
		if id=="porridge" then color=rgb(239,207,151) end
		box(add,green and "Feuille" or "Morceau",v(green and 0.24 or 0.15,0.064,0.13),math.cos(a)*0.43,0.298,math.sin(a)*0.43,color)
	end
end)
specific({"carrot","parsnip"},function(add,id)
	local c=id=="carrot" and rgb(229,116,28) or rgb(221,187,117)
	for i=0,4 do
		local width=0.48-i*0.087
		disc(add,"Racine",width,0.253,0,0.34-i*0.235,0,c:Lerp(wood,i*0.058))
	end
	for i=-1,1 do
		add("Fane",v(0.11,0.46,0.10),cf(i*0.12,0.67,0)*CFrame.Angles(0,0,-i*0.45),rgb(70,124,44),Enum.Material.Grass,"Ball")
	end
end)
specific({"onion","garlic","turnip","pickled_onions"},function(add,id)
	local colors={onion=rgb(188,124,62),garlic=rgb(230,218,186),turnip=rgb(151,77,126),pickled_onions=rgb(213,181,143)}
	local c=colors[id]
	for i=0,4 do
		local a=i*math.pi*2/5
		round(add,"Bulbe",v(0.65,0.9,0.65),math.cos(a)*0.22,0,math.sin(a)*0.22,c:Lerp(Color3.new(1,1,1),i*0.06))
	end
	box(add,"Col",v(0.19,0.29,0.18),0,0.49,0,rgb(117,106,66))
	box(add,"Racine",v(0.12,0.19,0.13),0,-0.48,0,rgb(135,99,61))
end)
specific({"cabbage","squash","pumpkin","melon"},function(add,id)
	local cabbage=id=="cabbage"
	local c=cabbage and rgb(99,143,62) or id=="melon" and rgb(78,126,63) or rgb(231,124,36)
	for i=0,5 do
		local a=i*math.pi/3
		add(cabbage and "Feuille" or "Côte",v(cabbage and 0.69 or 0.77,0.86,0.73),
			cf(math.cos(a)*0.30,0,math.sin(a)*0.30)*CFrame.Angles(0,-a,cabbage and 0.25 or 0),c:Lerp(rgb(239,225,145),i%2*0.15),Enum.Material.SmoothPlastic,"Ball")
	end
	box(add,"Tige",v(0.15,0.26,0.16),0,0.46,0,rgb(75,100,48),nil,0.21)
end)
specific({"grape","dried_fruit","berries","plum","pear"},function(add,id)
	local grouped=id=="grape" or id=="dried_fruit" or id=="berries"
	local c=id=="pear" and rgb(174,176,70) or id=="berries" and rgb(161,53,66) or id=="dried_fruit" and rgb(146,83,53) or rgb(102,60,142)
	if grouped then
		for row=0,2 do
			for j=0,2-row do
				round(add,"Grain",v(0.45,0.37,0.43),(j-(2-row)/2)*0.35,0.33-row*0.29,0,c:Lerp(rgb(240,181,154),(row+j)*0.06))
			end
		end
	else
		round(add,"Fruit",id=="pear" and v(0.92,0.83,0.83) or v(0.96,1.03,0.80),0,-0.14,0,c)
		if id=="pear" then round(add,"Col",v(0.57,0.62,0.57),0,0.24,0,c) end
	end
	box(add,"Tige",v(0.09,0.24,0.10),0,0.51,0,wood,nil,0.26)
	round(add,"Feuille",v(0.38,0.12,0.19),0.19,0.56,0,rgb(80,128,54))
end)
specific({"fish_1","fish_2","fish_3","fish_4","fish_5","fish_6","fish_7","fish","salmon","raw_fish","grilled_fish","smoked_fish"},function(add,id)
	local fishColors={rgb(128,180,200),rgb(174,160,91),rgb(181,112,92),rgb(96,138,77),rgb(97,138,168),rgb(143,114,153),rgb(198,164,106)}
	local c=fishColors[tonumber(id:match("%d+$")) or 1] or fishColors[1]
	if id=="salmon" then c=rgb(191,135,118) end
	if id=="grilled_fish" or id=="smoked_fish" then c=rgb(146,85,46) end
	buildIcon(add,"fish",c,0)
	for i=-1,1 do box(add,"Marque",v(0.045,0.25,0.031),i*0.21,0.036,-0.226,c:Lerp(rgb(230,211,171),0.45),nil,-0.20) end
end)
specific({"crab","crayfish","shellfish","rare_shell"},function(add,id)
	local shell=id=="shellfish" or id=="rare_shell"
	local c=shell and rgb(212,170,127) or rgb(173,65,41)
	round(add,"Carapace",v(1.1,0.40,shell and 0.99 or 0.66),0,0,0,c)
	for _,sign in ipairs({-1,1}) do
		for i=1,3 do
			box(add,shell and "Nervure" or "Patte",v(shell and 0.065 or 0.37,0.08,0.13),sign*(0.20+i*0.11),shell and 0.17 or -0.09,(i-2)*0.24,c:Lerp(rgb(248,198,131),0.25),nil,sign*0.27)
		end
		if not shell then round(add,"Pince",v(0.39,0.25,0.39),sign*0.58,0.04,-0.46,c) end
	end
end)
specific({"copper_coin","silver_coin","gold_coin","ancient_coin","gold","event_token"},function(add,id)
	local c=id=="silver_coin" and steel or id=="copper_coin" and rgb(192,112,66) or rgb(228,171,55)
	for i=0,(id=="gold" and 3 or 1) do
		disc(add,"Pièce",1.12,0.125,-i*0.13,i*0.13,0,c)
		disc(add,"Frappe",0.86,0.030,-i*0.13,i*0.13+0.073,0,c:Lerp(rgb(244,224,156),0.30))
	end
	box(add,"Empreinte",v(0.23,0.036,0.36),id=="gold" and -0.39 or -0.13,id=="gold" and 0.48 or 0.22,0,c:Lerp(wood,0.23))
end)
specific({"cup","wood_cup","mug","tankard","bucket","bucket_empty","water","ale","chamomile_tea","evening_tea","mint_tea","thyme_tea","sage_tea"},function(add,id)
	local bucket=id:find("bucket")~=nil
	local c=bucket and rgb(149,93,50) or rgb(126,77,48)
	disc(add,bucket and "Seau" or "Tasse",1.07,0.83,0,0,0,c)
	for _,y in ipairs({-0.30,0.31}) do disc(add,"Cerclage",1.09,0.075,0,y,0,bucket and steel or bronze) end
	disc(add,"Bord",1.11,0.10,0,0.41,0,c:Lerp(rgb(221,171,107),0.36))
	disc(add,"Intérieur",0.88,0.029,0,0.46,0,id=="bucket_empty" and rgb(68,43,29) or (bucket or id=="water") and rgb(72,133,161) or id=="ale" and rgb(229,180,92) or rgb(152,102,54))
	if bucket then
		for _,s in ipairs({-1,1}) do box(add,"Anse",v(0.075,0.65,0.09),s*0.48,0.54,0,steel,nil,s*0.36) end
		box(add,"Poignée",v(0.54,0.082,0.10),0,0.84,0,wood)
	else
		for _,y in ipairs({-0.19,0.22}) do box(add,"Anse",v(0.32,0.09,0.13),0.56,y,0,c) end
		box(add,"Anse",v(0.09,0.46,0.13),0.72,0.01,0,c)
	end
end)
specific({"table_knife","table_fork","spoon","ladle","blade","hook","lockpick","arrow","bolt","bolt_heavy","nails","copper_nails","rivet","iron_bar"},function(add,id)
	local shaft=id=="arrow" or id=="bolt" or id=="bolt_heavy"
	local large=id=="ladle" or id=="spoon"
	local c=id=="copper_nails" and rgb(196,114,67) or steel
	local handle=id=="table_knife" or id=="table_fork" or large
	box(add,"Manche",v(handle and 0.23 or 0.13,1.02,0.18),0,-0.26,0,(handle or shaft) and wood or c,handle and Enum.Material.Wood or metal)
	if large then
		round(add,"Cuilleron",v(id=="ladle" and 0.64 or 0.40,0.54,0.18),0,0.45,0,c)
	elseif id=="table_fork" then
		box(add,"Épaulement",v(0.37,0.21,0.088),0,0.27,0,c,metal)
		for i=-1,1 do box(add,"Dent",v(0.055,0.39,0.07),i*0.145,0.49,0,c,metal) end
	elseif id=="hook" or id=="lockpick" then
		box(add,"Crochet",v(0.11,0.42,0.12),0.15,0.41,0,c,metal,-0.9)
	else
		add("Pointe",v(shaft and 0.27 or 0.31,0.61,0.11),cf(0,0.40,0),c,Enum.Material.Metal,"Wedge")
		if shaft then
			add("Empennage",v(0.36,0.35,0.12),cf(0,-0.63,0),rgb(193,165,122),fabric,"Wedge")
		end
	end
end)
specific({"rusty_key","ancient_key","seal","wax_seal","flint","diamond","sapphire","ruby","emerald","amber"},function(add,id)
	local colors={diamond=rgb(162,213,230),sapphire=rgb(63,114,218),ruby=rgb(196,52,65),emerald=rgb(53,163,107),amber=rgb(227,153,44),flint=rgb(105,108,105)}
	if id:find("key") then
		box(add,"Tige",v(0.15,1.12,0.18),0,-0.20,0,bronze,metal)
		round(add,"Panneton",v(0.49,0.20,0.19),0.15,-0.56,0,bronze)
		for i=0,9 do
			local a=i*math.pi/5
			box(add,"Anneau",v(0.23,0.11,0.16),math.cos(a)*0.32,0.52+math.sin(a)*0.32,0,bronze,metal,a+math.pi/2)
		end
	elseif id:find("seal") then
		disc(add,"Cire",0.92,0.22,0,-0.09,0,rgb(160,49,40))
		box(add,"Motif",v(0.35,0.035,0.35),0,0.04,0,rgb(205,83,54),nil,0.18)
	else
		buildIcon(add,"crystal",colors[id],0)
	end
end)
specific({"bread","country_bread"},function(add,id)
	local c=id=="bread" and rgb(184,107,42) or rgb(152,82,35)
	round(add,"Croûte",id=="bread" and v(1.86,0.72,0.86) or v(1.68,0.78,1.04),0,0,0,c)
	for i=-1,1 do
		add("Grigne",v(0.16,0.066,id=="bread" and 0.49 or 0.60),cf(i*0.39,0.331-math.abs(i)*0.035,-0.015)*CFrame.Angles(0,0.34,0),
			rgb(239,174,87),Enum.Material.SmoothPlastic,"Ball")
	end
end)
specific({"rope","braided_rope","climbing_rope","linen_thread","wool_thread","silk"},function(add,id)
	local thread=id:find("thread") or id=="silk"
	local c=id=="silk" and rgb(225,209,175) or thread and rgb(187,168,139) or rgb(151,100,60)
	local radius=thread and 0.31 or 0.51
	if thread then
		disc(add,"Bobine",0.37,0.65,0,0,0,wood)
		for _,y in ipairs({-0.36,0.36}) do disc(add,"Flasque",0.79,0.10,0,y,0,wood) end
	end
	for layer=0,2 do
		for i=0,11 do
			local a=i*math.pi/6
			box(add,"Toron",v(radius*0.61,0.128,0.16),math.cos(a)*radius,(layer-1)*0.13,math.sin(a)*radius,c:Lerp(rgb(233,194,127),(i%2)*0.15),fabric)
		end
	end
	if not thread then box(add,"Bout libre",v(0.57,0.13,0.13),0.42,-0.13,-0.44,c,fabric,-0.08) end
end)
specific({"bowl","plate","wood_plate","decorated_ceramic","amphora","jug","old_vase","gourd","pot"},function(add,id)
	local bowl=id=="bowl" or id=="plate" or id=="wood_plate"
	local c=id=="old_vase" and rgb(88,135,130) or id=="gourd" and rgb(159,139,49) or (id=="bowl" or id=="wood_plate") and wood or rgb(179,100,63)
	if bowl then
		local size=id=="bowl" and 0.57 or 0.18
		round(add,"Fond",v(1.51,size,1.51),0,0,0,c)
		disc(add,"Bord",1.51,0.092,0,size*0.41,0,c:Lerp(rgb(226,179,118),0.28))
		disc(add,"Creux",1.27,0.016,0,size*0.49+0.01,0,c:Lerp(rgb(76,51,33),0.28))
	else
		round(add,"Panse",v(1.10,id=="amphora" and 1.22 or 0.98,0.97),0,0,0,c)
		disc(add,"Col",id=="pot" and 0.78 or 0.43,0.30,0,0.50,0,c)
		disc(add,"Lèvre",id=="pot" and 0.84 or 0.55,0.10,0,0.66,0,c:Lerp(rgb(227,177,127),0.25))
		disc(add,"Ouverture",id=="pot" and 0.65 or 0.33,0.02,0,0.72,0,rgb(68,44,32))
		if id=="amphora" or id=="jug" then
			box(add,"Anse",v(0.14,0.51,0.18),0.57,0.22,0,c,nil,-0.27)
			box(add,"Attache",v(0.27,0.12,0.17),0.48,0.39,0,c)
		end
	end
end)
specific({"compass","old_compass","pocket_mirror","hourglass","spyglass","inkwell"},function(add,id)
	if id=="hourglass" then
		for _,y in ipairs({-0.63,0.63}) do disc(add,"Plateau",0.99,0.11,0,y,0,wood) end
		for _,s in ipairs({-1,1}) do box(add,"Montant",v(0.09,1.23,0.09),s*0.41,0,0,wood) end
		round(add,"Ampoule",v(0.49,0.57,0.49),0,0.31,0,rgb(184,210,201))
		round(add,"Sable",v(0.49,0.57,0.49),0,-0.31,0,rgb(218,172,90))
	elseif id=="spyglass" then
		for i=0,2 do disc(add,"Tube",0.70-i*0.13,0.44,0,i*0.37-0.42,0,i%2==0 and bronze or leather) end
		disc(add,"Lentille",0.57,0.03,0,-0.65,0,rgb(104,150,172))
	elseif id=="inkwell" then
		box(add,"Encrier",v(0.94,0.58,0.72),0,0,0,rgb(51,53,77))
		disc(add,"Goulot",0.37,0.19,0,0.32,0,rgb(86,95,126))
		disc(add,"Encre",0.25,0.035,0,0.43,0,rgb(25,27,38))
	else
		disc(add,"Monture",1.37,0.18,0,0,0,bronze)
		disc(add,"Cadran",1.16,0.055,0,0.105,0,id=="pocket_mirror" and rgb(168,198,202) or rgb(236,211,156))
		if id~="pocket_mirror" then
			box(add,"Aiguille nord",v(0.095,0.04,0.375),0,0.15,0.19,rgb(165,40,39))
			box(add,"Aiguille sud",v(0.095,0.04,0.35),0,0.15,-0.16,rgb(64,77,102))
		end
	end
end)

local families = {}
for family,glyphs in pairs({
	book={"📓","📕","📗","📘","📙","📒","📔","📖","📚","🎶"}, scroll={"📜","📃","🧾","🗺️","✉️","🎟️","🃏","📐","📁"},
	bag={"👜","🎒","🛍️","👝","🧂"}, jar={"🏺","🧪","🍾","🧴","🧃","🍷","🌙","💪","🖋️"},
	bowl={"🍲","🥣","🍽️","🥗","🥘","🍳"}, cup={"🍺","🍵","🥤"}, pie={"🥧","🍰","🥞","🍞"},
	fish={"🐟","🍢"}, plant={"🌿","🌼","🌸","💜","🌾","🎋","🌶️"}, food={"🥩","🍖","🥓","🧀","🥚","🥕","🍐","🍇","🍬","🧅","🧄","🥬","🎃","🟣","🟨"},
	coin={"💰","🏅","🎖️","⭐","👑"}, compass={"🧭","⌛","⏳","🔍","🔭"}, fastener={"📌","🔩","🔪","⚙️","🦯","⛓️","🍴","🥄","⚓","🎣"},
	key={"🗝️"}, lock={"🔒","🔐"}, arrow={"🏹","🔱","📯","🎺"}, cloth={"🧶","🛏️","🎀","🎗️","🎐","🧵","🚩"},
	crate={"📦","🎁","🧺","🧰","🖼️","♟️"}, crystal={"💎","💠","❄️","☄️","🧊","🔴","🔵","✨","💗"}, soul={"🔮","👻"},
	ring={"💍","📿","⭕","🧿","🔶","🔘"},
}) do for _, glyph in ipairs(glyphs) do families[glyph]=family end end
local palette={rgb(153,93,54),rgb(183,131,73),rgb(97,133,85),rgb(103,141,158),rgb(125,95,146),rgb(180,97,76),rgb(134,152,159)}
local function variation(id)
	local key=0
	for i=1,#id do key=(key*31+id:byte(i))%997 end
	return key
end
local trophyFamilies = {
	essence="vial", os="bone", ["cœur"]="heart", croc="fang", ["gelée"]="gel", plumes="feather", plume="feather",
	glande="vial", venin="vial", ["écailles"]="scale", ["écaille"]="scale", masque="mask", oreille="ear",
	["défense"]="fang", griffe="fang", insigne="coin", ["écusson"]="coin", bois="horn", corne="horn",
	grimoire="book", queue="appendix", spores="spores", aile="feather", carquois="quiver", faux="reaper",
	["écu"]="shield", ["élytre"]="scale", avis="scroll", bosse="hide", cape="cloth", carapace="scale",
	collet="ring", crin="feather", crochet="key", dard="arrow", fragment="crystal", givre="crystal",
	noyau="crystal", paille="plant", patte="appendix", peau="hide", pince="claw", ["poussière"]="spores",
	sceau="coin", turban="cloth", ["éclat"]="crystal",
}
local function trophyShape(add, family, c, variant)
	local ivory=rgb(226,208,169)
	if family=="bone" then
		box(add,"Diaphyse",v(0.28,1.21,0.31),0,0,0,ivory)
		for _,y in ipairs({-0.61,0.61}) do
			for _,x in ipairs({-0.14,0.14}) do round(add,"Articulation",v(0.34,0.32,0.34),x,y,0,ivory) end
		end
	elseif family=="fang" or family=="horn" or family=="appendix" then
		local material=family=="appendix" and c or ivory
		for i=0,4 do
			local diameter=0.52-i*0.093
			add("Courbure",v(diameter,0.33,diameter),cf(i*i*0.027,i*0.248-0.48,0)*CFrame.Angles(0,0,-i*0.14),material:Lerp(rgb(132,97,67),0.055*i),Enum.Material.SmoothPlastic,"Ball")
		end
	elseif family=="feather" then
		box(add,"Rachis",v(0.07,1.54,0.075),0,0,0,wood,nil,-0.26)
		for s=-1,1,2 do
			for i=0,3 do
				add("Barbe",v(0.43-i*0.055,0.203,0.055),cf(s*(0.15-i*0.025)+i*0.031,i*0.23-0.21,0)*CFrame.Angles(0,0,s*(0.80-i*0.08)),c:Lerp(ivory,i*0.08),Enum.Material.SmoothPlastic,"Ball")
			end
		end
	elseif family=="heart" then
		for _,x in ipairs({-0.258,0.258}) do round(add,"Lobe",v(0.65,0.69,0.53),x,0.19,0,c) end
		add("Pointe",v(0.54,0.73,0.51),cf(0,-0.215,0)*CFrame.Angles(0,0,math.pi),c,Enum.Material.SmoothPlastic,"Wedge")
	elseif family=="gel" then
		round(add,"Gelée",v(1.36,0.51,1.08),0,0,0,c)
		round(add,"Reflet",v(0.53,0.21,0.40),-0.21,0.22,-0.16,c:Lerp(ivory,0.6))
	elseif family=="scale" or family=="shield" then
		for i=-1,1 do
			add(family=="shield" and "Plaque" or "Écaille",v(0.59,0.90,0.16),cf(i*0.34,0.15-math.abs(i)*0.11,i==0 and -0.05 or 0.02)*CFrame.Angles(0,0,-i*0.22),c:Lerp(ivory,(i+1)*0.12),metal,"Wedge")
		end
		if family=="shield" then round(add,"Umbo",v(0.28,0.27,0.14),0,-0.06,-0.17,bronze) end
	elseif family=="mask" or family=="ear" then
		round(add,family=="ear" and "Pavillon" or "Masque",family=="ear" and v(0.61,1.12,0.23) or v(1.12,0.74,0.36),0,0,0,c)
		for _,s in ipairs({-1,1}) do round(add,"Ouverture",v(0.27,0.13,0.05),s*0.22,0.09,-0.17,rgb(50,32,29)) end
	elseif family=="hide" then
		box(add,"Peau",v(0.80,1.18,0.13),0,0,0,c,fabric)
		for _,s in ipairs({-1,1}) do
			box(add,"Patte",v(0.49,0.23,0.15),s*0.42,0.37,0,c,fabric,s*0.37)
			box(add,"Patte",v(0.41,0.19,0.15),s*0.41,-0.46,0,c,fabric,-s*0.3)
		end
	elseif family=="spores" then
		for i=0,6 do
			local a=i*math.pi*2/7
			round(add,"Grain",v(0.29,0.31,0.29),math.cos(a)*0.39,(i%3)*0.10,math.sin(a)*0.37,c:Lerp(ivory,i*0.075))
		end
	elseif family=="claw" then
		for _,s in ipairs({-1,1}) do
			add("Pince",v(0.30,0.82,0.32),cf(s*0.28,0.24,0)*CFrame.Angles(0,0,s*0.34),c,Enum.Material.SmoothPlastic,"Wedge")
		end
		round(add,"Articulation",v(0.70,0.35,0.52),0,-0.24,0,c)
	elseif family=="quiver" then
		disc(add,"Carquois",0.52,1.0,0,-0.13,0,leather)
		for i=-1,1 do box(add,"Flèche",v(0.095,1.14,0.08),i*0.12,0.23,0,wood,nil,-i*0.12) end
		disc(add,"Lanière",0.56,0.11,0,-0.36,0,bronze)
	elseif family=="reaper" then
		box(add,"Manche",v(0.12,1.49,0.12),0,0,0,wood)
		add("Lame",v(0.87,0.37,0.11),cf(0.38,0.55,0),steel,metal,"Wedge")
	elseif family=="vial" then
		buildIcon(add,"jar",c,variant)
	else
		buildIcon(add,family,c,variant)
	end
end
for id, info in C.ITEMS do
	if id:match("^prise_") then
		local first=(info.name or ""):match("^%S+") or ""
		first=first:gsub("É","é"):gsub("Â","â"):lower()
		local family=trophyFamilies[first]
		if family then
			local n=variation(id)
			local base=palette[n%#palette+1]
			local color=family=="heart" and base:Lerp(rgb(157,50,58),0.6) or base
			specific({id},function(add) trophyShape(add,family,color,n) end)
		end
	end
end
local exact={copper_coin="coin",silver_coin="coin",gold_coin="coin",seed_sack="bag",bucket="cup",bucket_empty="cup",water="jar",dye="jar",silver_ingot="fastener",grilled_fish="fish",smoked_fish="fish",lockpick="key",braided_rope="ring",climbing_rope="ring",scales_tool="compass"}
local added=0
for id,info in C.ITEMS do
	if not info.tool and not itemIcons:FindFirstChild(id) then
		local k=variation(id)
		local f=exact[id] or ((info.seed or id:match("^seed_")) and "seed")
			or id:match("^ame_") and "soul" or id:match("^prise_") and "trophy" or families[info.icon] or (info.food and "food") or "material"
		local color=palette[k%#palette+1]
		if f=="seed" then color=wood:Lerp(color,0.54) end
		icon(id,function(add) buildIcon(add,f,color,k) end)
		added+=1
	end
end

local gearIcons=folder("IconesEquipement")
local gearCopy=RS.Shared.Gear:Clone()
gearCopy.Parent=SS
local Gear=require(gearCopy)
gearCopy:Destroy()
local function gearIcon(name,family,color,variant)
	local m=Instance.new("Model")
	m.Name=name
	m:SetAttribute("ApercuDroit",true)
	buildIcon(function(n,size,transform,c,mat,shape)
		return part(m,n,size,transform,c,mat,shape)
	end,family,color,variant)
	publish(gearIcons,m)
end
local armorColors={rgb(131,78,43),steel,rgb(74,109,59),rgb(67,56,79),bronze}
for i,info in ipairs(Gear.ARMORS) do gearIcon(info[1],"armor",armorColors[i],i) end
for i,info in ipairs(Gear.HATS) do gearIcon(info[1],"hat",palette[(i-1)%#palette+1],i) end
for i,info in ipairs(Gear.TRINKETS) do gearIcon(info[1],"ring",palette[i],i) end
gearIcon("armor","armor",armorColors[1],1)
gearIcon("hat","hat",palette[2],1)
gearIcon("trinket","ring",palette[5],1)

return {outils=#toolIcons:GetChildren(), objets=#itemIcons:GetChildren(), objetsCompletes=added, equipements=#gearIcons:GetChildren(), objetsPlacesAjoutes=props, piecesConstruction=blocks, refaits=precise}
