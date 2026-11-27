-- visuels_objets passe son dossier temporaire pour la phase objets.
-- Un appel sans paramètre conserve la génération des visuels d'équipement.
local cibleObjets, moduleObjets, configObjets = ...
local RS, SS = game.ReplicatedStorage, game.ServerStorage
local miniatures = moduleObjets
if not miniatures then
	local clone = SS.OutilsDev.ConstruireModelesMiniatures:Clone()
	local ok, resultat = pcall(require, clone)
	clone:Destroy()
	assert(ok, resultat)
	miniatures = resultat
end
local config = configObjets
if not config then
	local shared = RS.Shared:Clone()
	shared.Parent = SS
	local ok
	ok, config = pcall(require, shared.Config)
	shared:Destroy()
	assert(ok, config)
end
local items = cibleObjets

local rgb, v, cf = Color3.fromRGB, Vector3.new, CFrame.new
local wood, dark, brass, steel = rgb(125,78,42), rgb(58,38,28), rgb(193,139,66), rgb(159,174,179)
local linen, ivory, leaf = rgb(195,172,125), rgb(223,209,177), rgb(99,142,63)
local metal, cloth, leather = Enum.Material.Metal, Enum.Material.Fabric, Enum.Material.Leather
local function draw(model)
	local d = { model = model }
	function d.part(name, size, at, color, kind, material)
		local p = Instance.new(kind == "wedge" and "WedgePart" or kind == "corner" and "CornerWedgePart" or "Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, at, color
		if kind == "ball" or kind == "cylinder" then
			p.Shape = kind == "ball" and Enum.PartType.Ball or Enum.PartType.Cylinder
		end
		p.Material = material or Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Parent = model
		return p
	end
	function d.box(n, x,y,z, X,Y,Z, c, tilt, mat)
		return d.part(n,v(x,y,z),cf(X,Y,Z)*CFrame.Angles(0,0,tilt or 0),c,nil,mat)
	end
	function d.ball(n, x,y,z, X,Y,Z, c)
		return d.part(n,v(x,y,z),cf(X,Y,Z),c,"ball")
	end
	function d.disc(n, diameter, height, X,Y,Z, c, mat)
		return d.part(n,v(height,diameter,diameter),cf(X,Y,Z)*CFrame.Angles(0,0,math.pi/2),c,"cylinder",mat)
	end
	function d.line(n, a,b,width,c,mat,depth)
		return d.part(n,v(width,width, (a-b).Magnitude),CFrame.lookAt((a+b)/2,b),c,nil,mat)
	end
	function d.oval(n, X,Y,Z, rx,ry,width,c,mat,segments)
		local steps=segments or 12
		for i=1,steps do
			local a,b=(i-1)*2*math.pi/steps,i*2*math.pi/steps
			d.line(n,v(X+math.cos(a)*rx,Y+math.sin(a)*ry,Z),v(X+math.cos(b)*rx,Y+math.sin(b)*ry,Z),width,c,mat)
		end
	end
	return d
end

local function mix(c, b, f) return c:Lerp(b,f) end
local function bolt(d,x,y,z,c)
	d.ball("Rivet",0.105,0.105,0.082,x,y,z,c or brass)
end
local function palette(name)
	local lower = name:gsub("É","é"):gsub("À","à"):lower()
	for _, p in ipairs({
		{"givre",rgb(132,189,221)},{"glace",rgb(130,168,210)},{"hiver",rgb(186,196,198)},{"neige",rgb(195,211,222)},{"blanc",rgb(217,216,197)},
		{"diamant",rgb(119,209,222)},{"rubis",rgb(160,45,57)},{"saphir",rgb(66,110,173)},{"émeraude",rgb(61,141,98)},{"ambre",rgb(204,124,44)},{"jade",rgb(85,163,124)},
		{"cuivre",rgb(184,110,63)},{"argent",rgb(179,191,203)},{"acier",rgb(115,146,167)},{" d'or",rgb(227,176,64)},
		{"rouge",rgb(153,63,52)},{"ombre",rgb(65,60,86)},{"noir",rgb(62,59,64)},{"spectr",rgb(126,173,179)},{"désert",rgb(172,132,88)},{"sabl",rgb(165,124,76)},
		{"royal",rgb(113,114,173)},{"légendaire",rgb(143,105,157)},{"ronces",rgb(105,124,65)},{"bois",rgb(136,94,60)},{"marais",rgb(99,124,79)},{"slime",rgb(109,148,88)},
		{"gobelin",rgb(117,131,80)},{"fer",steel},{"fourr",rgb(155,110,73)},{"lin",linen},{"cuir",rgb(132,84,53)},{"pierre",rgb(134,137,129)},{"os ",ivory},
	}) do
		if lower:find(p[1],1,true) then return p[2],lower end
	end
	local variants={rgb(126,96,71),rgb(119,130,104),rgb(133,105,89),rgb(129,144,154),rgb(156,116,80),rgb(120,106,134)}
	local k=0
	for i=1,#name do k=(k*31+name:byte(i))%997 end
	return variants[k%#variants+1],lower
end

local function clothStack(d,c,kind)
	for i=1,3 do d.box("Pli",1.43,0.11,0.82,(i%2)*0.10,(i-2)*0.105,0,mix(c,ivory,i*0.09),0,cloth) end
	if kind=="dyed_cloth" then
		for _,x in ipairs({-0.48,0.51}) do d.box("Galon teint",0.10,0.022,0.77,x,0.17,0,brass,0,cloth) end
	elseif kind=="canvas" then
		d.box("Bordure cousue",1.38,0.026,0.07,0,0.17,-0.37,ivory,0,cloth)
	end
end
local function strap(d,a,b,width,c)
	d.line("Lanière",a,b,width,c or dark,leather)
end
local function fang(d, at, scale, c)
	for i=0,3 do
		local width=(0.30-i*0.060)*scale
		d.part("Courbe",v(width,0.29*scale,width),cf(at+v(i*i*0.018*scale,-i*0.19*scale,0))*CFrame.Angles(0,0,i*0.16),mix(c,ivory,i*0.12),"ball")
	end
end
local function wing(d,x,y,z,c,sign)
	for i=1,4 do
		local lean=sign*(0.52+i*0.10)
		d.part("Plume taillée",v(0.16,0.49-i*0.035,0.080),cf(x+sign*i*0.10,y-i*0.055,z)*CFrame.Angles(0,0,lean),mix(c,ivory,i*0.06),"wedge")
	end
end
local function gem(d,x,y,z,c,scale)
	local q=scale or 1
	d.part("Facette",v(0.40,0.61,0.34)*q,cf(x,y,z)*CFrame.Angles(0.08,0.35,-0.24),c,"corner")
	d.part("Facette lumineuse",v(0.19,0.44,0.31)*q,cf(x+0.121*q,y,z-0.025*q)*CFrame.Angles(0.08,0.35,0.2),mix(c,ivory,0.42),"wedge")
end
local function flask(d,c)
	d.ball("Fiole",0.70,0.77,0.61,0,-0.06,0,c)
	d.disc("Col",0.26,0.31,0,0.416,0,mix(c,ivory,0.31))
	d.disc("Bouchon",0.33,0.16,0,0.61,0,wood)
	d.box("Bande d'étiquette",0.39,0.22,0.045,0,-0.08,-0.30,ivory,0,cloth)
end
-- Le motif occupe la face de l’étiquette. Sa silhouette reste visible après réduction.
local function cropMark(d,kind,c,x,y,z)
	local y0=y or 0
	local g=rgb(77,123,64)
	if kind=="root" then
		d.part("Racine imprimée",v(0.067,0.44,0.32),cf(x,y0-0.05,z)*CFrame.Angles(0,math.pi/2,math.pi),c,"wedge")
		for s=-1,1,2 do d.box("Fane",0.085,0.16,0.034,x+s*0.059,y0+0.22,z,g,s*-0.31) end
	elseif kind=="grain" or kind=="barley" or kind=="oat" or kind=="rye" then
		d.box("Épi",0.035,0.58,0.03,x,y0,z,g)
		local wide=kind=="oat" and 0.16 or kind=="rye" and 0.08 or 0.12
		for n=0,2 do for s=-1,1,2 do
			d.part("Grain",v(wide,0.16,0.049),cf(x+s*wide*0.68,y0+n*0.14-0.11,z)*CFrame.Angles(0,0,-s*0.53),c,"ball")
		end end
		if kind=="barley" then
			for s=-1,1,2 do d.box("Barbe",0.028,0.16,0.027,x+s*0.105,y0+0.30,z,c,s*-0.31) end
		end
	elseif kind=="bunch" or kind=="cherry" then
		local n=kind=="cherry" and 2 or 5
		for i=0,n-1 do
			local dx=(i%2==0 and -0.10 or 0.10)
			if n==5 and i==4 then dx=0 end
			d.ball("Fruit",0.20,0.20,0.046,x+dx,y0+0.08-math.floor(i/2)*0.15,z,c)
		end
		d.box("Tige",0.046,0.19,0.026,x,y0+0.21,z,g)
	elseif kind=="leaf" or kind=="cabbage" or kind=="flower" then
		d.box("Tige",0.052,0.42,0.026,x,y0-0.06,z,g)
		for s=-1,1,2 do d.part("Feuille",v(0.23,0.18,0.050),cf(x+s*0.13,y0+0.016,z)*CFrame.Angles(0,0,s*0.47),c,"ball") end
		d.ball("Sommet",0.18,0.20,0.05,x,y0+0.17,z,c)
	elseif kind=="pod" or kind=="kidney" then
		d.part("Gousse",v(0.49,0.23,0.058),cf(x,y0,z)*CFrame.Angles(0,0,0.45),mix(c,g,0.39),"ball")
		for i=-1,1 do d.ball("Grain rond",0.12,0.12,0.044,x+i*0.125,y0+i*0.062,z-0.029,c) end
	elseif kind=="cone" or kind=="acorn" then
		d.ball("Corps",0.30,0.43,0.060,x,y0-0.046,z,c)
		for i=-1,1 do d.box("Coiffe",0.29-0.055*math.abs(i),0.063,0.036,x,y0+0.12+i*0.06,z-0.022,mix(c,dark,0.32)) end
	else
		local elongated=kind=="squash" or kind=="tuber"
		local lobes=kind=="cloves" or kind=="melon"
		if lobes then for i=-1,1 do d.ball("Lobe",0.21,0.36,0.051,x+i*0.105,y0,z,mix(c,ivory,0.15*math.abs(i))) end
		else d.part("Fruit",elongated and v(0.30,0.43,0.062) or v(0.40,0.34,0.062),cf(x,y0,z)*CFrame.Angles(0,0,elongated and -0.4 or 0),c,"ball") end
		if kind~="tuber" then d.box("Pédoncule",0.08,0.14,0.028,x+0.02,y0+0.19,z,g,0.23) end
	end
end
local function juice(d,id)
	local kind,c,body
	if id=="apple_juice" then kind,c,body="fruit",rgb(193,119,48),v(0.82,0.97,0.70)
	elseif id=="berry_juice" then kind,c,body="bunch",rgb(157,47,79),v(0.92,0.75,0.82)
	else kind,c,body="bunch",rgb(113,56,136),v(0.63,1.14,0.60) end
	if id=="grape_juice" then d.disc("Bouteille haute",0.64,1.10,0,0,0,c)
	else d.part(id=="berry_juice" and "Fiole large" or "Bouteille carrée",body,cf(),c,id=="berry_juice" and "ball" or nil) end
	d.disc("Goulot",0.29,0.23,0,body.Y/2+0.07,0,mix(c,ivory,0.23))
	d.disc("Bouchon",0.35,0.12,0,body.Y/2+0.23,0,wood)
	d.box("Étiquette de fruit",0.54,0.62,0.054,0,-0.022,-body.Z*0.49,ivory)
	cropMark(d,kind,id=="apple_juice" and rgb(184,62,54) or mix(c,ivory,0.16),0,-0.05,-body.Z*0.49-0.035)
	d.box("Reflet",0.05,0.47,0.021,-body.X*0.37,0.14,-body.Z*0.53,mix(c,ivory,0.53))
end
local sackTypes={
	backpack="pack",canvas_bag="satchel",satchel="satchel",merchant_bag="merchant",provision_bag="food",rations="wrapped",
	seed_sack="grain",flour_sack="flour",flour="flour",spice_sack="spice",salt_sack="salt",coin_purse="coin",merchant_purse="coin",
	animal_feed="grain",compost="compost",cloth_bale="bale",
}
local function sack(d,id)
	local form=sackTypes[id]
	local dyes={pack=rgb(68,101,86),satchel=rgb(144,99,61),merchant=rgb(117,84,62),food=rgb(166,119,59),wrapped=rgb(176,137,77),grain=rgb(157,116,68),flour=rgb(213,189,141),spice=rgb(161,100,75),salt=rgb(160,170,163),coin=rgb(113,66,62),compost=rgb(111,83,55),bale=rgb(152,113,87)}
	local c=dyes[form]
	local framed=form=="pack" or form=="satchel" or form=="merchant" or form=="wrapped" or form=="food" or form=="bale"
	if framed then
		d.box("Corps tendu",1.20,form=="pack" and 1.26 or 0.82,0.74,0,-0.04,0,c,0,form=="satchel" and leather or cloth)
		d.box("Rabat",1.23,0.38,0.096,0,0.21,-0.385,mix(c,linen,0.29),0,cloth)
		local offset=form=="satchel" and 0.04 or 0.34
		local straps=form=="satchel" and {offset} or {-offset,offset}
		for _,x in ipairs(straps) do
			d.box("Sangle",0.105,0.73,0.055,x,-0.03,-0.425,dark,0,leather)
			d.box("Boucle",0.21,0.15,0.058,x,-0.16,-0.457,brass,0,metal)
		end
		if form=="pack" or form=="merchant" then d.oval("Anse",0,0.55,0,0.29,0.20,0.077,dark,leather,8) end
		if form=="pack" then d.box("Poche extérieure",0.45,0.28,0.11,0,-0.31,-0.43,mix(c,dark,0.20),0,cloth) end
		if form=="food" then d.box("Bord du paquet",0.49,0.12,0.09,0.21,0.43,0.02,linen,0.2,cloth) end
	else
		d.part("Sac renflé",form=="coin" and v(0.92,0.87,0.72) or v(1.13,1.07,0.78),cf(0,-0.06,0),c,"ball",cloth)
		d.disc("Col noué",form=="coin" and 0.42 or 0.59,0.22,0,0.43,0,mix(c,linen,0.25),cloth)
		d.disc("Lien",0.45,0.076,0,0.38,0,dark,leather)
		d.line("Extrémité du lien",v(0.09,0.36,-0.29),v(0.34,0.21,-0.38),0.059,dark)
		if form=="coin" then
			for i=0,2 do d.disc("Pièce",0.33,0.073,-0.33-i*0.09,-0.40+i*0.077,-0.24,brass,metal) end
		else
			local contents={grain=rgb(221,176,73),flour=ivory,spice=rgb(218,95,58),salt=rgb(238,234,206),compost=rgb(95,63,42)}
			local material=contents[form]
			d.disc("Contenu visible",0.45,0.066,0,0.551,0,material)
			d.box("Marque",0.39,0.39,0.052,0,-0.04,-0.382,linen)
			for i=-1,1 do d.ball("Grains",0.11,0.12,0.080,i*0.097,-0.046+(i%2)*0.073,-0.42,mix(material,dark,0.15)) end
		end
	end
end
local function heartTheme(name)
	name=name:lower()
	if name:find("verre",1,true) then return "glass",rgb(152,215,207) end
	if name:find("dormeur",1,true) then return "dormant",rgb(147,220,232) end
	if name:find("glace",1,true) or name:find("gelé",1,true) or name:find("givre",1,true) then return "frost",rgb(122,189,230) end
	if name:find("rouille",1,true) or name:find("maudit",1,true) or name:find("tombes",1,true) then return "cursed",rgb(154,77,136) end
	if name:find("lac",1,true) then return "water",rgb(76,172,186) end
	if name:find("moissons",1,true) then return "harvest",rgb(225,186,91) end
	if name:find("ronce",1,true) then return "thorn",rgb(167,114,141) end
	if name:find("bois",1,true) or name:find("ent ",1,true) then return "root",rgb(153,182,78) end
	if name:find("grès",1,true) then return "sand",rgb(216,133,65) end
	if name:find("terre",1,true) then return "clay",rgb(186,104,68) end
	if name:find("granit",1,true) then return "granite",rgb(180,155,181) end
	if name:find("ruine",1,true) then return "relic",rgb(231,181,65) end
	return "stone",rgb(217,124,75)
end
local function core(d,name,ornament)
	local theme,c=heartTheme(name)
	local scale=ornament and 0.57 or 1
	local Z=ornament and -0.129 or 0
	local host=(theme=="root" or theme=="thorn" or theme=="harvest") and wood or theme=="water" and rgb(62,102,112) or (theme=="sand" or theme=="clay") and rgb(139,87,63)
		or theme=="cursed" and rgb(77,52,79) or theme=="relic" and brass or rgb(93,104,112)
	local radius=(theme=="glass" and 0.39 or 0.49)*scale
	local function pos(x,y,z) return cf(x*scale,y*scale,z*scale+Z) end
	if ornament then d.oval("Chaînette",0,0.39,0,0.47,0.40,0.069,dark,leather,12) end
	local y=ornament and -0.24 or 0
	gem(d,0,y,Z-0.045,c,1.48*scale)
	if theme=="dormant" then
		d.oval("Couronne de glace",0,y,Z-0.01,0.40*scale,0.51*scale,0.11*scale,rgb(108,155,215),metal,6)
		d.part("Pointe du Dormeur",v(0.25,0.52,0.19)*scale,pos(0,0.55,-0.12),c,"wedge")
		bolt(d,0,y-0.39*scale,Z-0.22,rgb(218,248,248))
	elseif theme=="frost" or theme=="glass" then
		for s=-1,1,2 do
			d.part("Éclat ramifié",v(0.27,theme=="glass" and 0.83 or 0.61,0.27)*scale,pos(s*0.34,0.18,0)*CFrame.Angles(0,s*0.33,-s*0.60),mix(c,ivory,0.30),theme=="glass" and "wedge" or "corner")
		end
	elseif theme=="root" or theme=="thorn" or theme=="harvest" then
		local tall=theme=="harvest" and 0.68 or 0.52
		for s=-1,1,2 do
			d.line("Racine",v(s*radius,-0.43*scale,Z),v(s*radius*0.73,0.17*scale,Z-0.07),0.15*scale,host)
			d.line("Rameau",v(s*radius*0.73,0.17*scale,Z-0.07),v(s*radius*0.94,tall*scale,Z),0.088*scale,host)
			if theme=="root" then d.ball("Bourgeon",0.20*scale,0.16*scale,0.21*scale,s*radius*0.96,0.57*scale,Z,mix(c,ivory,0.24))
			elseif theme=="harvest" then
				for i=0,2 do
					d.part("Épi des Moissons",v(0.13,0.22,0.12)*scale,pos(s*(0.27+0.047*i),0.39+i*0.12,-0.06)*CFrame.Angles(0,0,s*0.49),c,"ball")
				end
			else
				d.part("Épine",v(0.14,0.42,0.18)*scale,pos(s*0.52,0.32,0)*CFrame.Angles(0,0,s*0.54),mix(c,wood,0.26),"wedge")
			end
		end
	elseif theme=="water" then
		d.oval("Anneau d’eau",0,y,Z+0.055,0.49*scale,0.52*scale,0.089*scale,host,metal,10)
		for _,u in ipairs({{-0.42,0.32},{0.36,-0.29}}) do
			d.ball("Goutte",0.18*scale,0.29*scale,0.20*scale,u[1]*scale,u[2]*scale,Z,mix(c,ivory,0.27))
		end
	elseif theme=="relic" or theme=="cursed" then
		d.oval("Monture gravée",0,y,Z+0.085,radius,0.48*scale,0.103*scale,host,metal,8)
		for s=-1,1,2 do bolt(d,s*radius,y,Z-0.07,c) end
	elseif theme=="sand" or theme=="clay" then
		local width=theme=="sand" and 1.34 or 1.04
		for i=0,2 do
			d.part("Strate",v(width-i*0.14,0.16,0.61)*scale,pos(i*0.044,-0.45+i*0.20,0.20)*CFrame.Angles(0,i*0.18,0),mix(host,c,i*0.16),"wedge")
		end
	elseif theme=="granite" then
		for s=-1,1,2 do d.part("Pointe de granit",v(0.39,0.87,0.29)*scale,pos(s*0.38,-0.011,0.12)*CFrame.Angles(0,0,s*0.33),mix(host,c,0.36),"corner") end
	else
		for i=-1,1 do
			d.part("Écorce minérale",v(0.48,0.66+math.abs(i)*0.16,0.37)*scale,pos(i*0.34,-0.13+math.abs(i)*0.06,0.10)*CFrame.Angles(0,i*0.29,i*0.23),mix(host,ivory,(i+1)*0.11),"corner")
		end
	end
end
local function grainWood(d,id)
	if id=="bark" then
		for i=-1,1 do
			d.part("Éclisse d’écorce",v(0.37,0.14,1.21-0.14*i),cf(i*0.30,0.06*math.abs(i),0)*CFrame.Angles(0,i*0.11,i*0.16),mix(dark,wood,(i+1)*0.15),"wedge",Enum.Material.Wood)
		end
		return
	end
	if id=="planks" then
		for i=0,2 do
			d.part("Planche sciée",v(1.39,0.14,0.63),cf((i%2)*0.20,i*0.16,(i%2)*0.05)*CFrame.Angles(0,i*0.047,0),mix(wood,linen,0.16+i*0.08),nil,Enum.Material.WoodPlanks)
			d.box("Chant",0.035,0.14,0.59,0.696+(i%2)*0.20,i*0.16,-0.015,mix(wood,linen,0.34+i*0.05))
		end
		return
	end
	if id=="branches" or id=="ancient_root" then
		for i=-1,1 do
			d.line("Branche",v(i*0.26,-0.56,-0.04),v(i*0.35+0.13,0.59,-i*0.06),0.18,wood,Enum.Material.Wood)
			d.line("Ramification",v(i*0.29,0.10,-i*0.06),v(i*0.35+0.31,0.47,0),0.09,wood)
		end
		if id=="branches" then d.box("Lien",0.78,0.12,0.23,0,-0.29,-0.03,linen,0,cloth)
		else gem(d,0,-0.32,-0.09,rgb(133,145,79),0.38) end
		return
	end
	local isPine=id=="pine_log"
	local barkTone=isPine and rgb(103,66,54) or id=="oak_log" and rgb(82,58,42) or rgb(112,78,54)
	local sapwood=isPine and rgb(221,163,103) or rgb(172,119,75)
	local heartwood=mix(sapwood,dark,0.35)
	local function log(x,y,z,length,diameter,rotation)
		local at=cf(x,y,z)*CFrame.Angles(0,rotation,0)
		d.part("Rondin",v(length,diameter,diameter),at,barkTone,"cylinder",Enum.Material.Wood)
		for s=-1,1,2 do
			d.part("Coupe fraîche",v(0.04,diameter*0.94,diameter*0.94),at*cf(s*(length/2+0.007),0,0),sapwood,"cylinder")
			d.part("Cerne externe",v(0.047,diameter*0.71,diameter*0.71),at*cf(s*(length/2+0.020),0.018,0),heartwood,"cylinder")
			d.part("Cerne interne",v(0.055,diameter*0.59,diameter*0.59),at*cf(s*(length/2+0.025),0.018,0),sapwood,"cylinder")
			d.part("Moelle",v(0.059,diameter*0.25,diameter*0.25),at*cf(s*(length/2+0.028),0.025,0),heartwood,"cylinder")
		end
		d.part("Nœud sur l’écorce",v(diameter*0.38,0.10,diameter*0.22),at*cf(-0.15,diameter*0.48,0.054),sapwood,"ball")
	end
	if id=="wood" then
		log(0,-0.16,-0.22,1.30,0.49,0.18)
		log(-0.12,-0.14,0.23,1.19,0.49,0.03)
		log(0.02,0.23,0.01,1.11,0.42,0.12)
	else
		log(0,0,0,isPine and 1.53 or 1.23,isPine and 0.55 or 0.78,0.28)
		if not isPine then d.part("Souche de branche",v(0.19,0.35,0.19),cf(-0.34,0.38,0)*CFrame.Angles(0,0,0.43),barkTone,nil,Enum.Material.Wood) end
	end
end
local function nails(d,id)
	local c=id=="copper_nails" and rgb(198,117,68) or steel
	local count=id=="rivet" and 3 or 4
	for i=1,count do
		local at=cf((i-(count+1)/2)*0.31,0,(i%2-0.5)*0.12)*CFrame.Angles(0,0,(i-(count+1)/2)*0.23)
		local length=id=="rivet" and 0.55 or 0.88+i*0.07
		d.part("Tige forgée",v(0.105,length,0.11),at,c,nil,metal)
		d.part("Tête",v(0.097,0.26,0.26),at*cf(0,length/2+0.017,0)*CFrame.Angles(0,0,math.pi/2),mix(c,ivory,0.21),"cylinder",metal)
		if id=="rivet" then d.part("Bout du rivet",v(0.13,0.13,0.13),at*cf(0,-length/2,0),c,"ball",metal)
		else d.part("Pointe",v(0.11,0.20,0.11),at*cf(0,-length/2-0.077,0)*CFrame.Angles(0,0,math.pi),c,"wedge",metal) end
	end
end
local function book(d,c,loose)
	if loose then
		d.box("Feuille",1.18,0.08,0.92,0,0,0,linen)
		for i=1,3 do d.box("Trait d'encre",0.64-i*0.075,0.02,0.035,-0.13,0.05,i*0.15-0.34,dark) end
		if loose=="map" then
			d.line("Tracé",v(-0.39,0.058,-0.26),v(0.35,0.058,0.30),0.038,rgb(141,68,49))
		else d.disc("Sceau",0.24,0.035,0.31,0.059,0.24,c) end
	else
		d.box("Pages",1.07,1.31,0.30,0,0,0,ivory)
		for _,s in ipairs({-1,1}) do d.box("Couverture",1.15,1.39,0.07,0,0,s*0.17,c,0,leather) end
		d.box("Dos",0.14,1.40,0.38,-0.55,0,0,mix(c,brass,0.3))
	end
end

local function shield(d,c,kind)
	if kind=="round" or kind=="shell" then
		d.part("Écu rond",v(0.19,1.32,1.32),cf()*CFrame.Angles(0,math.pi/2,0),c,"cylinder")
	else
		d.box("Planche d'écu",1.17,1.07,0.18,0,0.14,0,c,0,Enum.Material.WoodPlanks)
		d.part("Pointe",v(0.24,0.55,1.17),cf(0,-0.54,0)*CFrame.Angles(0,math.pi/2,math.pi),c,"wedge")
	end
	d.ball("Umbo",0.34,0.34,0.18,0,0.02,-0.15,brass)
	if kind=="shell" then
		for i=-1,1 do d.box("Nervure de carapace",0.17,0.76,0.07,i*0.29,0,-0.121,mix(c,ivory,0.31),i*0.22) end
	else
		for _,s in ipairs({-1,1}) do d.box("Armature",0.105,0.9,0.07,s*0.38,0.03,-0.112,steel,s*0.15,metal) end
	end
end

local function hat(d,c,kind)
	if kind=="turban" then
		d.ball("Calotte de lin",1.19,0.71,1.12,0,0.12,0,c)
		for i=-1,1 do
			d.part("Pli enroulé",v(1.24,0.16,1.13),cf(0,i*0.16,0)*CFrame.Angles(0,0,i*0.18),mix(c,ivory,0.18+(i+1)*0.14),"ball",cloth)
		end
		d.box("Panseau noué",0.24,0.70,0.09,0.29,-0.21,-0.41,c,0.20,cloth)
	elseif kind=="hood" or kind=="helmet" then
		local mat=kind=="hood" and cloth or metal
		d.ball("Calotte",1.03,1.06,0.93,0,0.075,0,c)
		d.box("Ouverture du visage",0.56,0.48,0.075,0,-0.13,-0.446,dark)
		for s=-1,1,2 do d.box("Bord",0.119,0.68,0.12,s*0.28,-0.085,-0.47,mix(c,ivory,0.3),s*0.16,mat) end
		d.box(kind=="hood" and "Col" or "Visière",0.83,0.13,0.54,0,kind=="hood" and -0.43 or -0.08,-0.29,mix(c,ivory,0.28),0,mat)
	elseif kind=="mask" then
		d.box("Masque",1.01,0.56,0.17,0,0,0,c,0,cloth)
		for s=-1,1,2 do d.box("Ouverture",0.29,0.15,0.035,s*0.25,0.05,-0.10,dark,s*0.14) end
	elseif kind=="crown" or kind=="antlers" then
		d.disc("Bandeau",1.10,0.16,0,-0.26,0,kind=="antlers" and wood or brass)
		for i=-2,2 do
			if kind=="crown" then
				d.part("Fleuron",v(0.20,0.39+0.07*(2-math.abs(i)),0.13),cf(i*0.215,-0.045,-0.27),mix(brass,c,0.35),"wedge",metal)
			elseif math.abs(i)==2 then
				local s=i/2
				d.line("Ramure",v(s*0.37,-0.20,0),v(s*0.66,0.59,0),0.13,ivory)
				d.line("Andouiller",v(s*0.50,0.18,0),v(s*0.30,0.55,0),0.10,ivory)
				d.line("Andouiller",v(s*0.54,0.28,0),v(s*0.77,0.45,0),0.09,ivory)
			end
		end
	else
		local mushroom=kind=="mushroom"
		d.ball(mushroom and "Chapeau de champignon" or "Calotte",mushroom and 1.54 or 1.05,mushroom and 0.74 or 0.63,mushroom and 1.33 or 0.94,0,0.10,0,c)
		d.disc("Bord",mushroom and 1.40 or kind=="fur" and 1.11 or 1.45,0.15,0,-0.23,0,kind=="fur" and ivory or mix(c,ivory,0.23))
		d.disc("Bande",1.03,0.09,0,-0.11,0,dark)
		if kind=="feathered" then wing(d,0.28,0.49,-0.13,ivory,1) end
		if mushroom then
			for i=-1,1 do d.ball("Verrue",0.16,0.10,0.16,i*0.33,0.38-math.abs(i)*0.052,-0.15,ivory) end
		end
		if kind=="fur" then for s=-1,1,2 do d.box("Rabat",0.25,0.43,0.31,s*0.41,-0.29,0,ivory,0,cloth) end end
	end
end

local function trinket(d,c,kind)
	if kind=="boots" then
		for s=-1,1,2 do
			local x=s*0.31
			d.box("Tige",0.39,0.73,0.53,x,0.04,0.08,c,0,leather)
			d.box("Pied",0.41,0.32,0.83,x,-0.29,-0.12,c,0,leather)
			d.box("Semelle",0.43,0.10,0.88,x,-0.49,-0.12,dark,0,leather)
			bolt(d,x,0.10,-0.22)
		end
	elseif kind=="shield" or kind=="roundshield" or kind=="shell" then shield(d,c,kind=="roundshield" and "round" or kind)
	elseif kind=="vial" or kind=="gourd" then flask(d,c)
	elseif kind=="saddle" then
		d.box("Tapis de selle",1.24,0.17,1.06,0,-0.18,0,c,0,cloth)
		d.box("Assise",0.74,0.28,0.88,0,0.04,0,wood,0,leather)
		for _,z in ipairs({-0.36,0.36}) do d.box("Arçon",0.72,0.34,0.19,0,0.12,z,dark,0,leather) end
		for s=-1,1,2 do strap(d,v(s*0.48,-0.09,0),v(s*0.48,-0.61,0),0.10) end
	elseif kind=="belt" or kind=="ring" or kind=="horseshoe" then
		if kind=="horseshoe" then
			for i=0,8 do
				local a,b=(i+1)*0.52,(i+2)*0.52
				d.line("Fer courbé",v(math.cos(a)*0.47,math.sin(a)*0.5,0),v(math.cos(b)*0.47,math.sin(b)*0.5,0),0.14,steel,metal)
			end
		else
			d.oval("Anneau",0,0,0,kind=="belt" and 0.64 or 0.40,kind=="belt" and 0.39 or 0.43,0.14,kind=="belt" and dark or brass,kind=="belt" and leather or metal)
			if kind=="belt" then d.box("Boucle",0.32,0.24,0.16,0,-0.31,-0.10,brass,0,metal)
			else gem(d,0,0.43,-0.05,c,0.62) end
		end
	elseif kind=="quiver" then
		d.disc("Fourreau",0.55,1.03,0,-0.22,0,c,leather)
		d.disc("Cerclage",0.58,0.11,0,0.29,0,brass,metal)
		for i=-1,1 do
			d.box("Flèche",0.066,1.1,0.065,i*0.137,0.29,0,wood,-i*0.075)
			d.box("Empennage",0.13,0.22,0.045,i*0.165,0.73,0,ivory,-i*0.075,cloth)
		end
	elseif kind=="net" then
		d.oval("Cadre",0,0.24,0,0.54,0.49,0.073,wood,cloth)
		for i=-2,2 do
			d.line("Maille",v(i*0.155,-0.13,0),v(i*0.155,0.61,0),0.032,linen)
			d.line("Maille",v(-0.44,0.25+i*0.14,0),v(0.44,0.25+i*0.14,0),0.032,linen)
		end
		d.box("Manche",0.11,0.71,0.11,0,-0.50,0,wood)
	elseif kind=="basket" or kind=="satchel" then
		d.box(kind=="basket" and "Corbeille" or "Sacoche",1.10,0.64,0.73,0,-0.15,0,c,0,kind=="basket" and cloth or leather)
		d.box("Bord",1.14,0.105,0.77,0,0.13,0,brass)
		d.oval("Anse",0,0.23,0,0.43,0.43,0.085,wood,leather,8)
		if kind=="satchel" then d.box("Rabat",0.94,0.31,0.09,0,0,-0.38,mix(c,ivory,0.2),0,leather) end
	elseif kind=="torch" or kind=="lamp" then
		if kind=="torch" then
			d.box("Branche",0.19,1.00,0.18,0,-0.25,0,wood)
			d.part("Flamme",v(0.46,0.66,0.38),cf(0,0.48,0),rgb(237,125,41),"wedge")
			d.part("Cœur",v(0.26,0.43,0.24),cf(0,0.39,-0.11),rgb(254,201,72),"wedge")
		else
			d.box("Verre",0.64,0.72,0.62,0,0,0,rgb(233,174,75))
			for s=-1,1,2 do
				d.box("Montant",0.09,0.79,0.09,s*0.30,0,-0.30,c,0,metal)
				d.box("Montant",0.09,0.79,0.09,s*0.30,0,0.30,c,0,metal)
			end
			for _,y in ipairs({-0.41,0.41}) do d.box("Cadre",0.79,0.14,0.76,0,y,0,c,0,metal) end
			d.oval("Poignée",0,0.49,0,0.22,0.24,0.09,steel,metal,8)
		end
	elseif kind=="bracer" or kind=="greaves" or kind=="gloves" then
		for s=-1,1,2 do
			local x=s*0.31
			d.box("Protection",0.43,kind=="greaves" and 1.28 or 0.81,0.32,x,0,0,c,s*0.14,leather)
			for _,y in ipairs({-0.23,0.20}) do d.box("Sangle",0.46,0.105,0.35,x,y,0,brass,s*0.14) end
			if kind=="gloves" then for i=-1,1 do d.box("Doigt",0.10,0.27,0.19,x+i*0.12,0.43,0,c) end end
		end
	elseif kind=="keyring" then
		d.oval("Trousseau",0,0.36,0,0.32,0.27,0.07,brass,metal)
		for i=-1,1 do
			d.box("Clef",0.10,0.66,0.095,i*0.22,-0.18,-0.01,steel,-i*0.23,metal)
			d.box("Panneton",0.23,0.11,0.095,i*0.26,-0.44,-0.01,steel,-i*0.23,metal)
		end
	elseif kind=="shard" then gem(d,0,0,0,c,1.7)
	elseif kind=="heart" then
		for s=-1,1,2 do d.ball("Lobe",0.55,0.58,0.46,s*0.23,0.21,0,c) end
		d.part("Pointe",v(0.62,0.62,0.44),cf(0,-0.21,0)*CFrame.Angles(0,0,math.pi),c,"wedge")
	else
		d.oval("Cordon",0,0.23,0,0.51,0.49,0.071,dark,leather)
		if kind=="fangs" or kind=="bone" then
			for i=-1,1 do fang(d,v(i*0.31,-0.10+math.abs(i)*0.04,0),i==0 and 0.77 or 0.56,ivory) end
		elseif kind=="gel" then
			d.ball("Cabochon",0.57,0.47,0.28,0,-0.33,0,c)
			d.ball("Reflet",0.23,0.15,0.10,-0.10,-0.20,-0.13,mix(c,ivory,0.63))
		else
			d.part("Monture",v(0.60,0.61,0.18),cf(0,-0.26,0)*CFrame.Angles(0,0,math.pi/4),brass,nil,metal)
			gem(d,0,-0.26,-0.15,c,0.83)
		end
	end
end

-- Un polygone de découpe devient des prismes triangulaires orientés dans le plan de travail.
local function cut(d,name,outline,x,y,z,thickness,color,sx,sz)
	local polygon={}
	for i,p in ipairs(outline) do polygon[i]=v(x+p[1]*sx,y,z+p[2]*sz) end
	local function prism(a,b,c)
		local ab,ac,bc=(b-a).Magnitude,(c-a).Magnitude,(c-b).Magnitude
		if ac>ab and ac>=bc then b,c=c,b
		elseif bc>ab then a,b,c=b,c,a end
		local direction=(b-a).Unit
		local foot=a+direction*(c-a):Dot(direction)
		local up=(c-foot).Unit
		for _,endPoint in ipairs({a,b}) do
			local length=(endPoint-foot).Magnitude
			if length>0.001 then
				local back=(foot-endPoint).Unit
				local center=foot+(endPoint-foot+c-foot)/2
				d.part(name,v(thickness,(c-foot).Magnitude,length),CFrame.fromMatrix(center,up:Cross(back),up,back),color,"wedge")
			end
		end
	end
	for i=2,#polygon-1 do prism(polygon[1],polygon[i],polygon[i+1]) end
end
local cuts = {
	raw={{-0.54,-0.24},{-0.20,-0.42},{0.33,-0.34},{0.58,-0.06},{0.34,0.30},{-0.42,0.25}},
	steak={{-0.58,-0.17},{-0.39,-0.39},{0.14,-0.45},{0.43,-0.32},{0.61,0.04},{0.36,0.32},{0.04,0.40},{-0.43,0.25}},
	medallion={{-0.49,-0.19},{-0.31,-0.37},{0.24,-0.33},{0.50,-0.11},{0.39,0.24},{0.05,0.35},{-0.38,0.25}},
	rib={{-0.54,-0.24},{-0.25,-0.42},{0.54,-0.25},{0.53,0.22},{0.15,0.40},{-0.37,0.28}},
}
local function meat(d,id)
	local raw,cooked,rind = rgb(156,62,60),rgb(134,68,41),rgb(186,107,60)
	local cream=rgb(232,173,131)
	if id=="rabbit_meat" then
		d.box("Os ivoire",0.20,0.70,0.21,0.33,0,0,ivory,1.32)
		d.ball("Articulation",0.28,0.24,0.23,0.63,0.095,0,ivory)
		d.ball("Cuisse",1.10,0.52,0.73,-0.23,0,-0.025,rgb(193,125,115))
		d.ball("Hanche",0.48,0.43,0.56,0.10,0.01,0.07,rgb(177,104,99))
		for i = -1, 1 do
			d.line("Fibre de la cuisse", v(-0.32 + i * 0.14, 0.20, -0.18),
				v(-0.24 + i * 0.13, 0.22, 0.08), 0.055, cream)
		end
	elseif id=="venison" then
		local c=rgb(125,48,50)
		cut(d,"Médaillon",cuts.medallion,-0.34,0,0.17,0.22,c,0.65,0.69)
		cut(d,"Médaillon",cuts.medallion,0.29,0.06,-0.17,0.25,mix(c,cream,0.13),0.78,0.75)
		d.line("Fibre",v(0.17,0.209,-0.27),v(0.39,0.209,-0.16),0.041,mix(c,cream,0.42))
	elseif id=="boar_meat" or id=="roast_boar" then
		local roast=id=="roast_boar"
		local c=roast and rgb(104,58,37) or rgb(139,57,54)
		local h=roast and 0.61 or 0.36
		cut(d,"Côte épaisse",cuts.rib,-0.19,0,0,h,c,1.04,0.96)
		cut(d,"Croûte de côte",cuts.rib,-0.19,h/2,0,0.054,mix(c,rind,0.29),0.96,0.91)
		d.box("Bord de gras",0.91,0.12,0.16,-0.23,h*0.34,-0.38,roast and rind or cream,0.06)
		d.box("Os de côte",0.64,0.16,0.19,0.39,0.045,0.04,ivory,0.26)
		d.ball("Extrémité d'os",0.26,0.20,0.22,0.70,0.13,0.04,ivory)
	elseif id=="jerky" then
		local laniere = { {-0.45,-0.31}, {0.28,-0.44}, {0.52,-0.12}, {0.30,0.42}, {-0.39,0.37} }
		for i=-1,1 do
			cut(d,"Lamelle sèche",laniere,i*0.36,i%2*0.067,-i*0.16,0.12,mix(rgb(104,52,36),rind,(i+1)*0.16),0.38,1.70-i*0.17)
			d.part("Bord sec",v(0.21,0.088,0.34),cf(i*0.29+0.04,0.08,0.56-i*0.13)*CFrame.Angles(0,i*0.16,0),cooked,"wedge")
		end
	elseif id=="roast" then
		d.part("Rôti",v(1.39,0.68,0.68),cf(),cooked,"cylinder")
		d.part("Face tranchée",v(0.055,0.60,0.60),cf(0.704,0,0),rgb(172,99,70),"cylinder")
		for i=-1,1 do
			d.part("Ficelle",v(0.042,0.705,0.705),cf(i*0.39,0,0),linen,"cylinder")
			d.ball("Nœud",0.14,0.095,0.13,i*0.39,0.36,-0.04,linen)
		end
	else
		local grill=id=="steak"
		local c=grill and cooked or raw
		local outline=grill and cuts.steak or cuts.raw
		cut(d,"Face de coupe",outline,-0.06,0,0.02,0.28,c,1.15,1.13)
		if grill then
			d.ball("Face saisie", 1.16, 0.12, 0.79, -0.03, 0.11, 0.016, mix(c,rind,0.21))
		else
			cut(d,"Bord de coupe",outline,-0.06,0.137,0.02,0.035,mix(c,cream,0.20),1.03,1.02)
		end
		d.line(grill and "Croûte" or "Gras",v(-0.70,0.079,-0.02),v(-0.31,0.103,-0.30),0.088,grill and rind or cream)
		for i=-1,0 do
			d.line(grill and "Grille" or "Marbrure",v(i*0.37+0.05,0.147,-0.16),v(i*0.36+0.19,0.147,0.31),0.042,grill and dark or cream)
		end
	end
end

local itemForms = {}
local function assign(form, ids)
	for id in ids:gmatch("%S+") do
		assert(not itemForms[id],id)
		itemForms[id]=form
	end
end

local ice, purple, amber = rgb(164,226,229), rgb(132,82,161), rgb(226,155,67)
local green, moss, soot, rose = rgb(110,164,81), rgb(82,119,76), rgb(63,59,80), rgb(185,81,104)
-- Les prises, potions, teintures, graines et âmes sont rendues par leur banc dédié.
local jellyLooks = { slime_gel = { "pile", rgb(174,206,83) } }
local vialLooks = {
	oil = { "oil", amber },
	vinegar = { "sour", rgb(164,92,63) },
	fruit_syrup = { "syrup", rose },
}
local boneLooks = { fossil_bone = { "fossil", rgb(171,145,111) } }
local scaleLooks = {
	golden_carapace = { "gold", amber },
	scales = { "plain", rgb(126,157,121) },
}
local fangLooks = {
	monster_tooth = { "serrated", rgb(217,184,146) },
	claw = { "claw_pair", ivory },
}

local function jellyShape(d,k,c)
	local light=mix(c,ivory,0.54)
	if k=="comb" then
		for i=0,5 do
			local a=i*math.pi/3
			d.disc("Alvéole de cire",0.52,0.29,math.cos(a)*0.40,0,math.sin(a)*0.40,c)
			d.disc("Gelée dans l’alvéole",0.36,0.058,math.cos(a)*0.40,0.17,math.sin(a)*0.40,light)
		end
	elseif k=="bell" then
		d.ball("Ombrelle de gelée",1.22,0.59,0.97,0,0.29,0,c)
		for i=-2,2 do
			d.line("Filament translucide",v(i*0.18,0.13,0),v(i*0.23,-0.47+math.abs(i)*0.09,0.09),0.088,light)
		end
	elseif k=="strip" then
		for i=0,4 do
			d.part("Ruban de gelée",v(0.35,0.20,0.40),cf(i*0.24-0.50,(i%2)*0.03,math.sin(i*0.78)*0.18)*CFrame.Angles(0,i*0.38,0),mix(c,light,i%2*0.18),"ball")
		end
		d.ball("Goutte",0.32,0.17,0.33,0.29,-0.14,-0.30,c)
	elseif k=="block" or k=="ice" then
		for i=-1,1 do
			local h=0.45+0.20*(i+1)
			d.part("Fragment de gel",v(0.43,h,0.61),cf(i*0.36,h*0.22,0)*CFrame.Angles(0,i*0.22,i*0.13),mix(c,light,(i+1)*0.13),k=="ice" and "corner" or "wedge")
		end
		d.ball("Coulure",0.83,0.12,0.45,0,-0.17,-0.30,light)
	else
		local low=k=="mud" or k=="reed"
		d.ball("Base irrégulière",1.24,low and 0.28 or 0.43,0.94,0,-0.25,0,c)
		for i=0,k=="pile" and 5 or 3 do
			local a=i*2.399
			d.ball("Goutte de gelée",0.37+i%2*0.11,low and 0.17 or 0.36+i%2*0.14,0.37,math.cos(a)*0.41,i%2*0.13-0.19,math.sin(a)*0.35,mix(c,light,(i%3)*0.11))
		end
		if k=="crown" then
			d.disc("Bourrelet royal",0.90,0.20,0,0.12,0,light)
			for s=-1,1 do
				d.part("Pointe de gel",v(0.25,0.55-math.abs(s)*0.11,0.25),cf(s*0.28,0.42,0)*CFrame.Angles(0,0,-s*0.29),c,"wedge")
			end
		elseif k=="drop" then
			d.part("Goutte étirée",v(0.42,0.72,0.38),cf(0.04,0.26,0.02)*CFrame.Angles(0,0,-0.25),c,"ball")
		elseif k=="reed" then
			for s=-1,1,2 do d.line("Roseau pris dans la gelée",v(s*0.33,-0.16,0),v(s*0.45,0.50,0),0.073,light) end
		end
	end
end

local function vialShape(d,k,c)
	local square=k=="ruin" or k=="mask" or k=="dye" or k=="bound" or k=="vigor" or k=="stone" or k=="great_heal" or k=="venom_sand"
	local round=k=="heal" or k=="perfume" or k=="calm" or k=="water" or k=="tree" or k=="wisp" or k=="moon" or k=="bull" or k=="charm" or k=="venom_water"
	local tall=k=="empty" or k=="extract" or k=="storm" or k=="frost" or k=="sand" or k=="fang" or k=="grit" or k=="letter" or k=="air" or k=="root"
	local low=k=="balm" or k=="crawl" or k=="toad" or k=="deep"
	local width=k=="great_heal" and 0.94 or low and 0.98 or tall and 0.54 or round and 0.89 or 0.76
	local height=k=="great_heal" and 1.21 or low and 0.55 or tall and 1.22 or round and 0.82 or 1.04
	local shell=mix(c,ice,0.28)
	local liquid=k~="empty" and k~="letter"
	if square then
		d.box("Corps à pans",width,height,0.62,0,0,0,c,0,Enum.Material.Glass)
		d.box("Arête du verre",0.06,height*0.81,0.04,-width*0.42,0,-0.315,shell)
	elseif round then
		d.ball("Corps bombé",width,height,width*0.88,0,0,0,c)
	else
		local glass=d.disc("Paroi de verre",width,height,0,0,0,shell,Enum.Material.Glass)
		glass.Transparency=liquid and 0.20 or 0.42
		if liquid then d.disc("Liquide",width*0.84,height*0.65,0,-height*0.14,0,c) end
		if k=="letter" then
			d.part("Lettre roulée",v(0.19,height*0.73,0.14),cf(0,-0.06,-0.06)*CFrame.Angles(0,0,0.18),ivory)
			d.box("Cordon du message",0.23,0.063,0.15,0,-0.13,-0.10,rose)
		end
	end
	local neck=low and width*0.88 or tall and width*0.62 or width*0.42
	d.disc("Col",neck,0.14,0,height/2+0.057,0,shell)
	d.disc("Bouchon",neck*1.12,0.13,0,height/2+0.16,0,(k=="night" or k=="king" or k=="perfume") and brass or wood)
	local z=-(square and 0.32 or round and width*0.43 or width/2)-0.032
	local function tab(tone)
		d.box("Étiquette",width*0.69,height*0.38,0.052,0,0,z,tone)
	end
	local pale=mix(c,ivory,0.61)
	if k=="heal" or k=="great_heal" then
		tab(ivory)
		d.box("Signe de soin",0.10,0.27,0.042,0,0,z-0.034,rose)
		d.box("Signe de soin",0.25,0.09,0.042,0,0,z-0.034,rose)
		if k=="great_heal" then
			d.box("Bague de renfort",0.94,0.09,0.67,0,-0.43,0,brass)
		end
	elseif k=="vigor" or k=="storm" then
		for _,e in ipairs({{0.11,0.29,-0.09,0.04},{-0.09,0.04,0.10,0.08},{0.10,0.08,-0.11,-0.25}}) do
			d.line("Éclair",v(e[1],e[2],z),v(e[3],e[4],z),0.083,k=="storm" and ice or ivory)
		end
	elseif k=="night" or k=="veil" or k=="moon" then
		for i=0,6 do
			local a,b=i*0.60,(i+1)*0.60
			d.line("Croissant",v(math.cos(a)*0.22,math.sin(a)*0.24,z),v(math.cos(b)*0.22,math.sin(b)*0.24,z),0.082,pale)
		end
	elseif k=="frost" or k=="blizzard" then
		for s=-1,1 do gem(d,s*width*0.26,-0.13+math.abs(s)*0.14,z,pale,0.42) end
	elseif k=="shade" or k=="crawl" or k=="bound" then
		for s=-1,1,2 do d.box("Cerclage sombre",width*0.82,0.11,0.05,0,s*0.19,z,k=="bound" and brass or pale,s*0.29) end
		if k=="bound" then bolt(d,0,0,z-0.03,brass) end
	elseif k=="water" or k=="sunken" or k=="river" then
		for i=0,2 do d.ball("Bulle",0.12+i*0.035,0.12+i*0.035,0.067,(i%2-0.5)*0.25,i*0.23-0.20,z,pale) end
		if k=="sunken" then strap(d,v(-0.27,-0.18,z),v(0.28,0.09,z),0.086,moss) end
	elseif k=="root" then
		d.line("Racine",v(0,0.31,z),v(0,-0.19,z),0.083,wood)
		for s=-1,1,2 do
			d.line("Radicelle",v(0,-0.15,z),v(s*0.16,-0.39,z),0.071,pale)
			d.ball("Bourgeon",0.16,0.13,0.048,s*0.11,0.20,z,green)
		end
	elseif k=="tree" or k=="leaf" or k=="extract" or k=="balm" then
		tab(ivory)
		cropMark(d,"leaf",k=="tree" and wood or moss,0,0,z-0.034)
	elseif k=="king" or k=="ruin" or k=="mask" or k=="bone" then
		local tint=k=="king" and brass or pale
		for s=-1,1 do
			d.box(k=="mask" and "Visière" or "Relief",0.10,0.26,0.055,s*width*0.23,-0.01,z,tint,(k=="bone" and s*0.31 or 0))
		end
		d.box("Bande centrale",width*0.69,0.09,0.057,0,k=="mask" and 0.10 or -0.16,z,tint)
	elseif k=="bull" then
		for s=-1,1,2 do
			d.line("Corne",v(s*0.12,0,z),v(s*0.32,0.29,z),0.091,ivory)
		end
		d.box("Front du taureau",0.24,0.30,0.056,0,-0.03,z,ivory)
	elseif k=="wild" then
		for s=-1,1 do
			d.line("Griffe peinte",v(s*0.155-0.08,-0.24,z),v(s*0.145+0.08,0.27,z),0.066,ivory)
		end
	elseif k=="air" then
		d.oval("Volute",0,0.14,z,0.19,0.13,0.060,ivory,nil,8)
		d.line("Traînée",v(-0.13,-0.16,z),v(0.17,-0.05,z),0.060,pale)
	elseif k=="stone" then
		gem(d,0,0,z,pale,0.70)
	elseif k=="clover" then
		tab(ivory)
		for i=0,3 do d.ball("Trèfle",0.17,0.16,0.066,(i%2-0.5)*0.123,(math.floor(i/2)-0.5)*0.123,z-0.036,moss) end
	elseif k=="charm" then
		for s=-1,1,2 do d.ball("Lobe du sceau",0.22,0.23,0.065,s*0.09,0.056,z,ivory) end
		d.part("Pointe du sceau",v(0.28,0.23,0.065),cf(0,-0.07,z)*CFrame.Angles(0,0,math.pi),ivory,"wedge")
	elseif k=="venom_sand" or k=="venom_water" or k=="fang" or k=="deep" or k=="toad" or k=="grit" then
		for s=-1,1,2 do fang(d,v(s*width*0.19,0.14,z),k=="fang" and 0.68 or 0.49,pale) end
		if k=="venom_sand" then
			d.box("Bande de cuir",width*0.98,0.11,0.045,0,-height*0.39,z,wood,0,leather)
		elseif k=="venom_water" then d.ball("Bulle",0.19,0.15,0.06,0,0.23,z,pale) end
	elseif k=="perfume" then
		d.ball("Pompe",0.51,0.30,0.29,0.21,height*0.62,0,rose)
		d.box("Plaquette",0.32,0.24,0.09,0,-0.07,z,brass)
	elseif k=="sand" or k=="mist" or k=="wisp" then
		for i=0,3 do d.ball("Particule",0.14+i%2*0.051,0.14,0.07,math.sin(i*1.6)*width*0.28,i*0.21-0.30,z,pale) end
	elseif k=="oil" or k=="syrup" or k=="sour" or k=="calm" or k=="dye" then
		tab(ivory)
		d.ball("Marque du contenu",0.24,0.27,0.067,0,0,z-0.03,c)
	elseif k=="empty" then
		d.box("Reflet du verre",0.060,0.61,0.025,-width*0.28,0.03,z,ice)
	end
end

local function boneShape(d,k,c)
	local thick=k=="thick" or k=="broken" or k=="brow"
	local length=thick and 1.43 or k=="joint" and 0.86 or 1.26
	local breadth=thick and 0.36 or 0.23
	local edge=mix(c,ivory,0.42)
	if k=="rib" or k=="brow" then
		for i=0,5 do
			local a,b=i*0.43,(i+1)*0.43
			d.line("Arc osseux",v(math.cos(a)*0.66,math.sin(a)*0.77-0.39,0),v(math.cos(b)*0.66,math.sin(b)*0.77-0.39,0),breadth,c)
		end
		d.ball("Tête",0.37,0.32,0.30,0.68,-0.36,0,edge)
		if k=="brow" then d.ball("Orbitaire",0.30,0.20,0.09,0,-0.03,-0.17,dark) end
	else
		d.line("Diaphyse",v(-0.10,-length*0.45,0),v(0.11,length*0.44,0),breadth,c)
		for s=-1,1,2 do
			local y=s*length*0.48
			if not (k=="broken" and s==1) then
				for n=-1,1,2 do
					d.ball("Condyle",breadth*1.19,0.29,breadth*1.10,s*0.09+n*breadth*0.35,y,0,edge)
				end
			else
				d.part("Cassure",v(breadth,0.30,0.29),cf(0.09,y,0)*CFrame.Angles(0,0,-0.26),edge,"corner")
			end
		end
	end
	if k=="ice" or k=="icewrap" then
		for s=-1,1,2 do gem(d,s*0.25,s*0.23,-0.10,ice,k=="ice" and 0.63 or 0.42) end
	elseif k=="moss" or k=="root" then
		strap(d,v(-0.24,-0.41,-0.10),v(0.24,0.16,-0.14),0.10,k=="root" and wood or moss)
		d.ball("Nœud",0.17,0.22,0.13,0.16,0.18,-0.15,k=="root" and green or moss)
	elseif k=="linen" or k=="fur" then
		for i=-1,1 do
			d.box(k=="linen" and "Bandelette" or "Fourrure",breadth*1.28,0.13,0.10,i*0.023,i*0.22,-0.147,k=="linen" and linen or edge,0.22+i*0.16,cloth)
		end
	elseif k=="fossil" or k=="basalt" or k=="shale" then
		d.part("Matrice rocheuse",v(0.70,0.56,0.42),cf(0,-0.49,0.11)*CFrame.Angles(0,0,k=="shale" and 0.21 or -0.13),k=="basalt" and soot or rgb(118,107,87),"corner")
	elseif k=="crack" or k=="rune" or k=="carved" then
		for i=-1,1 do d.line("Entaille",v(-0.09,i*0.21,-0.14),v(0.12,i*0.21+0.11,-0.15),0.05,k=="rune" and purple or dark) end
	end
end

local function trophyTooth(d,k,c)
	local molar=k=="molar"
	local tusk=k=="tusk" or k=="big" or k=="swamp" or k=="tusk_ice"
	local claws=k:match("^claw")~=nil
	local width=k=="big" and 0.38 or tusk and 0.30 or claws and 0.24 or k=="thin" and 0.18 or 0.26
	local shapes={
		wolf={0.26,1.04,0.42},white={0.21,1.17,0.32},black={0.30,0.98,0.62},
		shadow={0.18,1.26,0.72},ice={0.33,1.03,0.35},night={0.23,1.13,0.58},
		claw={0.24,1.12,0.69},claw_brown={0.31,0.99,0.56},claw_deep={0.23,1.22,0.83},claw_ice={0.27,1.10,0.69},
	}
	if molar then
		d.ball("Couronne",0.79,0.63,0.51,0,0.24,0,c)
		for s=-1,1,2 do
			d.part("Racine dentaire",v(0.23,0.59,0.26),cf(s*0.18,-0.23,0)*CFrame.Angles(0,0,-s*0.19),mix(c,wood,0.20),"wedge")
		end
		return
	end
	local reach=k=="big" and 1.44 or tusk and 1.27 or k=="blunt" and 0.74 or 1.04
	local curve=tusk and 0.91 or (k=="hook" or claws) and 0.69 or 0.42
	if shapes[k] then width,reach,curve=table.unpack(shapes[k]) end
	local function fangAt(offset,size)
		local path={
			v(-curve*0.52,reach*0.42,0),v(-curve*0.39,reach*0.11,0),v(-curve*0.07,-reach*0.16,0),v(curve*0.50,-reach*0.36,0),
		}
		for i=1,#path-1 do
			local a,b=path[i]*size+offset,path[i+1]*size+offset
			local w=width*size*(1-(i-1)*0.26)
			d.part("Surface de la dent",v(w,w*0.78,(a-b).Magnitude+0.07),CFrame.lookAt((a+b)/2,b),mix(c,ivory,(i-1)*0.13))
		end
		local last=path[#path]*size+offset
		d.part("Pointe",v(0.10,0.25,0.12)*size,cf(last+v(0.06,-0.055,0)*size)*CFrame.Angles(0,0,math.pi-curve),mix(c,ivory,0.22),"wedge")
	end
	if k=="pair" or k=="claw_pair" then fangAt(v(-0.22,0,0),0.85) fangAt(v(0.22,0.11,0),0.68) else fangAt(v(0,0,0),1) end
	if k=="serrated" or k=="notch" then
		for i=0,2 do d.part("Denture",v(0.16,0.20,0.091),cf(-0.21+i*0.085,0.17-i*0.17,-0.08)*CFrame.Angles(0,0,-0.65),c,"wedge") end
	elseif k=="shadow" then
		d.line("Fissure d’ombre",v(-0.21,0.28,-0.10),v(0.19,-0.30,-0.086),0.058,purple)
	elseif k=="king" or k=="night" then
		d.box("Collier de racine",0.34,0.11,0.23,-0.19,0.34,0,k=="king" and brass or purple,-0.20,metal)
	elseif k=="tusk_ice" or k=="claw_ice" or k=="ice" then gem(d,-0.30,0.33,-0.12,ice,0.39)
	elseif k=="swamp" then d.ball("Écorce de marais",0.22,0.32,0.12,-0.30,0.29,-0.10,moss) end
end

local function scaleShape(d,k,c)
	local ceremonial=k=="royal" or k=="gold"
	local shell=k=="shell" or ceremonial or k=="elytra"
	local shimmer=mix(c,ivory,0.42)
	if shell then
		d.ball("Carapace arquée",1.36,0.56,1.09,0,0,0,c)
		for s=-1,1,2 do
			d.part(k=="shell" and "Plaque hexagonale" or "Élytre",v(0.56,0.36,0.89),cf(s*0.28,0.05,0)*CFrame.Angles(0,s*0.28,s*0.15),mix(c,ivory,0.17),"ball")
			for i=-1,1 do
				d.line("Nervure",v(s*0.16,0.28,i*0.26),v(s*0.52,0.16,i*0.31),0.057,shimmer,metal)
			end
		end
		if ceremonial then gem(d,0,0.26,-0.22,ice,k=="royal" and 0.64 or 0.44) end
		return
	end
	local wide=k=="croc" or k=="plain" or k=="bog"
	local single=k=="siren" or k=="black" or k=="ancient"
	local count=single and 0 or 1
	for i=-count,count do
		local x=i*(wide and 0.38 or 0.31)
		local height=single and 1.24 or 0.91-math.abs(i)*0.13
		local at=cf(x,-math.abs(i)*0.09,math.abs(i)*0.10)*CFrame.Angles(0,i*0.31,i*0.29)
		d.part("Écaille bombée",v(wide and 0.59 or single and 0.74 or 0.45,height*0.78,0.25),at,c,"ball")
		d.part("Extrémité pointue",v(wide and 0.38 or 0.31,height*0.47,0.15),at*cf(0,-height*0.36,0)*CFrame.Angles(0,0,math.pi),c,"wedge")
		d.line("Arête",at*v(0,-height*0.34,-0.11),at*v(0,height*0.27,-0.11),0.065,shimmer,metal)
		if k=="croc" or k=="bog" then
			for j=-1,1 do d.part("Aspérité",v(0.14,0.13,0.057),at*cf(0.15,j*0.19,-0.09),shimmer,"corner") end
		end
	end
	if k=="frost" or k=="ember" or k=="siren" then
		gem(d,0,0.23,-0.17,k=="ember" and amber or shimmer,0.47)
	elseif k=="sand" then for i=-1,1 do d.ball("Grain",0.10,0.11,0.052,i*0.19,0.15-i*0.11,-0.16,amber) end end
end

local lootForms={
	gel_art={looks=jellyLooks,build=jellyShape}, vial_art={looks=vialLooks,build=vialShape},
	bone_art={looks=boneLooks,build=boneShape},
	scale_art={looks=scaleLooks,build=scaleShape}, fang_art={looks=fangLooks,build=trophyTooth},
}
assign("meat","steak meat boar_meat rabbit_meat venison roast roast_boar jerky")
assign("cloth","soft_leather canvas dyed_cloth")
assign("hide","worked_fur scraped_hide fur royal_fur raw_hide deer_hide wolf_pelt")
assign("heap","bonemeal gravel compost sugar incense pollen sand sulfur dirt resin")
assign("nugget","silver_ore petrified_wood")
assign("bar","precious_ingot silver_ingot steel")
assign("brick","prepared_clay")
assign("wood","peg")
assign("timber","wood planks branches ancient_root oak_log pine_log bark")
assign("brush","brush comb")
assign("horse","horseshoes")
assign("lamp","miner_lamp")
assign("bell","herd_bell bell_small")
assign("seeds","bait bean pea ancient_seed")
assign("badge","guard_badge champion_ribbon")
assign("weights","weights")
assign("scale","scales_tool")
assign("gear","gear_wood gear_iron")
assign("ball","leather_ball")
assign("boat","barque voilier")
assign("kite","kite")
assign("figurine","wood_figurine stone_figurine wood_toy rag_doll")
assign("instrument","harp lute drum flute")
assign("osselets","dice")
assign("horn","antler")
assign("shell","golden_carapace")
assign("skinscale","ancient_scale black_scale scales")
assign("mushroom","glow_mushroom rare_mushroom")
assign("spores","royal_spore slime_gel")
assign("fang","stinger tooth monster_tooth claw")
assign("bone","bone fossil_bone")
assign("tablet","inscription carved_stone fossil relic_fragment")
assign("map","map_fragment")
assign("feather","quill feather night_feather")
assign("root","mandrake")
assign("flower","moon_flower night_flower")
assign("bundle","lost_item")
assign("egg","mystery_egg")
assign("pearl","pearl")
assign("rotten","rotten")
assign("fish","grilled_fish smoked_fish")
assign("crown","crown")
assign("banner","banniere")
assign("anchor","anchor")
assign("hardware","chain hinge fitting pulley")
assign("cloth","towel")
assign("liquid","oil")
assign("tablegame","cards board_game")
assign("hanging_art","painting")
assign("case","scroll_case")
assign("horn_call","horn_call trumpet")
assign("juice","apple_juice berry_juice grape_juice")
assign("forged_nails","nails copper_nails rivet")
assign("core","frozen_heart mineral_heart")
for id in sackTypes do if config.ITEMS[id] then itemForms[id]="sack" end end
for family, spec in lootForms do
	for id in spec.looks do
		if config.ITEMS[id] then itemForms[id]=family end
	end
end
local function itemShape(d,id,kind,c)
	local loot=lootForms[kind]
	if loot then
		local look=loot.looks[id]
		loot.build(d,look[1],look[2])
	elseif kind=="juice" then juice(d,id)
	elseif kind=="sack" then sack(d,id)
	elseif kind=="timber" then grainWood(d,id)
	elseif kind=="core" then core(d,config.ITEMS[id].name,false)
	elseif kind=="forged_nails" then nails(d,id)
	elseif kind=="meat" then meat(d,id)
	elseif kind=="cloth" then clothStack(d,id=="canvas" and linen or c,id)
	elseif kind=="hide" then
		local fur=id:find("fur") or id=="wolf_pelt"
		d.box("Peau déployée",0.93,1.19,0.15,0,0,0,c,0,fur and cloth or leather)
		for s=-1,1,2 do
			d.box("Patte avant",0.42,0.23,0.16,s*0.49,0.37,0,c,s*0.37,leather)
			d.box("Patte arrière",0.40,0.19,0.16,s*0.44,-0.45,0,c,-s*0.3,leather)
			if fur then d.box("Bord de fourrure",0.12,0.91,0.13,s*0.33,0,-0.091,mix(c,ivory,0.35),0,cloth) end
		end
		d.box("Encolure",0.35,0.27,0.15,0,0.65,0,c)
	elseif kind=="heap" then
		local tones={sugar=ivory,bonemeal=rgb(206,190,155),sulfur=rgb(223,181,52),pollen=rgb(230,174,59),sand=rgb(188,157,109),compost=rgb(105,78,51),dirt=rgb(117,78,47),resin=rgb(192,104,39),gravel=rgb(129,132,126)}
		local base=tones[id] or c
		if id=="incense" then
			d.disc("Coupelle",1.12,0.17,0,-0.29,0,wood)
			for i=-1,1 do d.box("Bâton d'encens",0.058,1.29,0.062,i*0.20,0.26,0,base,i*0.23) end
			d.ball("Braise",0.10,0.10,0.10,0,0.90,0,rgb(214,122,62))
		else
			d.disc("Tas",1.34,0.18,0,-0.12,0,base)
			for i=0,7 do
				local a=i*math.pi/4
				d.part(id=="gravel" and "Gravier" or "Grain",v(0.24,0.18+(i%3)*0.073,0.29),cf(math.cos(a)*0.43,-0.02+(i%2)*0.053,math.sin(a)*0.43)*CFrame.Angles(0,a,0),mix(base,ivory,0.1+(i%3)*0.11),"corner")
			end
			d.part("Sommet",v(0.55,0.33,0.66),cf(0,0.08,0),mix(base,ivory,0.13),"wedge")
		end
	elseif kind=="nugget" or kind=="tablet" then
		local sc=id=="silver_ore" and rgb(94,110,111) or id=="petrified_wood" and wood or c
		if kind=="nugget" then
			d.part("Roche",v(1.38,0.83,0.93),cf()*CFrame.Angles(0,0.28,0.1),sc,"corner",Enum.Material.Rock)
			for i=-1,1 do gem(d,i*0.32,0.044+i%2*0.11,-0.19,id=="silver_ore" and rgb(204,212,216) or mix(sc,ivory,0.35),0.50) end
		else
			d.box("Tablette",1.19,0.25,0.91,0,0,0,sc,0,Enum.Material.Slate)
			d.part("Fracture",v(0.37,0.24,0.89),cf(0.62,0,0),sc,"wedge",Enum.Material.Slate)
			for i=0,3 do
				if id=="fossil" then
					local a=i*math.pi/2
					d.part("Spire",v(0.18+i*0.069,0.045,0.08),cf(math.cos(a)*0.16,0.148,math.sin(a)*0.16)*CFrame.Angles(0,a,0),ivory)
				else d.box("Gravure",0.52-i*0.065,0.032,0.049,-0.07,0.14,i*0.15-0.24,mix(sc,ivory,0.40)) end
			end
		end
	elseif kind=="bar" or kind=="brick" then
		local base=id=="silver_ingot" and rgb(182,199,202) or id=="steel" and rgb(103,137,158)
			or kind=="brick" and rgb(171,104,80) or rgb(203,166,99)
		for i=0,kind=="brick" and 1 or 2 do
			d.box("Bloc",1.28,0.24,0.68,i%2*0.18,i*0.24,0,base,0,kind=="bar" and metal or nil)
			d.box("Face",1.11,0.045,0.54,i%2*0.18,i*0.24+0.13,0,mix(base,ivory,0.36))
		end
	elseif kind=="wood" or kind=="root" then
		if id=="oak_log" or id=="pine_log" or id=="bark" then
			local core=id=="pine_log" and rgb(151,96,55) or wood
			d.part("Écorce",v(1.43,0.63,0.63),cf(),dark,id=="bark" and nil or "cylinder",Enum.Material.Wood)
			for s=-1,1,2 do d.part("Coupe",v(0.05,0.49,0.49),cf(s*0.718,0,0),core,"cylinder",Enum.Material.Wood) end
			d.part("Cernes",v(0.052,0.29,0.29),cf(0.735,0,0),mix(core,ivory,0.19),"cylinder")
		else
			local tone=id=="mandrake" and rgb(163,108,54) or wood
			d.line("Tige",v(-0.13,-0.55,0),v(0.06,0.57,0),0.23,tone)
			for s=-1,1,2 do
				d.line("Ramification",v(0,-0.33,0),v(s*0.32,-0.66,0),0.11,tone)
				if kind=="root" then d.part("Feuille",v(0.32,0.54,0.07),cf(s*0.20,0.45,0)*CFrame.Angles(0,0,-s*0.34),leaf,"wedge") end
			end
			if kind == "root" then
				d.ball("Tubercule", 0.38, 0.55, 0.32, -0.02, 0.03, 0.013, tone)
				d.line("Radicelle", v(-0.10,-0.27,-0.03), v(0.16,-0.70,-0.14), 0.075, tone)
			end
			if id=="peg" then d.part("Pointe de cheville",v(0.24,0.45,0.22),cf(0.06,0.58,0),wood,"wedge") end
		end
	elseif kind=="brush" then
		d.box("Dos",1.29,0.19,0.39,0,0.08,0,wood)
		for i=-4,4 do d.box(id=="brush" and "Poils" or "Dent",0.069,id=="comb" and 0.44 or 0.29,0.19,i*0.125,-0.18,0,id=="comb" and linen or dark) end
		if id=="brush" then d.box("Poignée",0.56,0.105,0.21,0.18,0.22,0,wood,0,Enum.Material.Wood) end
	elseif kind=="horse" then trinket(d,c,"horseshoe")
	elseif kind=="lamp" then trinket(d,steel,"lamp")
	elseif kind=="bell" then
		d.disc("Pavillon",0.92,0.17,0,-0.33,0,brass,metal)
		d.ball("Corps évasé",0.77,0.74,0.77,0,-0.02,0,brass)
		d.oval("Anse",0,0.38,0,0.20,0.23,0.085,steel,metal,8)
		d.ball("Battant",0.17,0.18,0.17,0,-0.46,0,steel)
	elseif kind=="seeds" then
		for i=0,4 do
			local a=i*math.pi*2/5
			d.ball(id=="bait" and "Grain d'appât" or "Graine",0.33,0.21,0.30,math.cos(a)*0.35,(i%2)*0.055,math.sin(a)*0.31,id=="pea" and leaf or mix(linen,c,i*0.12))
		end
		if id=="pea" or id=="bean" then d.part("Gousse",v(1.13,0.35,0.27),cf(0,0.07,0.31),leaf,"ball") end
	elseif kind=="badge" then
		d.disc("Médaille",1.0,0.16,0,0,0,brass,metal)
		for s=-1,1,2 do d.box("Ruban",0.22,0.47,0.10,s*0.19,-0.35,0,c,s*0.11,cloth) end
		d.part("Relief",v(0.36,0.06,0.36),cf(0,0.095,0)*CFrame.Angles(0,math.pi/4,0),ivory)
	elseif kind=="weights" or kind=="scale" then
		if kind=="scale" then
			d.disc("Socle",0.63,0.13,0,-0.47,0,wood)
			d.box("Axe",0.12,1.09,0.12,0,0,0,brass)
			d.box("Fléau",1.38,0.092,0.105,0,0.44,0,brass)
			for s=-1,1,2 do
				for _,x in ipairs({-0.23,0.23}) do d.line("Suspente",v(s*0.60,0.40,0),v(s*0.60+x,-0.103,0),0.035,linen) end
				d.disc("Plateau",0.51,0.08,s*0.60,-0.13,0,steel,metal)
			end
		else
			for i=0,2 do
				local x=i*0.50-0.55
				d.disc("Poids",0.41+i*0.09,0.33+i*0.14,x,i*0.06,0,steel,metal)
				d.oval("Anneau",x,0.22+i*0.13,0,0.10,0.11,0.05,brass,metal,8)
			end
		end
	elseif kind=="gear" then
		local wheel=id=="gear_wood" and wood or steel
		d.oval("Couronne dentée",0,0,0,0.49,0.49,0.17,wheel,nil,9)
		for i=0,7 do
			local a=i*math.pi/4
			d.box("Dent",0.17,0.24,0.18,math.sin(a)*0.59,math.cos(a)*0.59,0,wheel,-a)
		end
		for i=0,3 do
			local a=i*math.pi/2
			d.line("Rayon",v(0,0,0),v(math.cos(a)*0.42,math.sin(a)*0.42,0),0.12,wheel)
		end
		d.ball("Moyeu",0.26,0.26,0.24,0,0,0,brass)
	elseif kind=="ball" or kind=="egg" or kind=="pearl" then
		local base=kind=="pearl" and rgb(207,211,189) or kind=="egg" and rgb(160,130,115) or wood
		d.ball(kind=="pearl" and "Perle" or kind=="egg" and "Coquille" or "Ballon",0.97,kind=="egg" and 1.30 or 0.95,0.95,0,0,0,base)
		if kind=="ball" then
			for i=-2,2 do d.box("Couture",0.079,0.035,0.045,i*0.14,0.22,-0.415,ivory) end
		elseif kind=="egg" then
			for i=-1,1 do d.ball("Tache",0.13,0.15,0.031,i*0.22,0.10+i*0.14,-0.40,mix(c,dark,0.31)) end
		else
			d.ball("Nacre",0.43,0.27,0.16,-0.18,0.33,-0.22,ivory)
		end
	elseif kind=="boat" then
		d.box("Fond",0.91,0.15,1.42,0,-0.15,0,wood,0,Enum.Material.WoodPlanks)
		for s=-1,1,2 do
			d.box("Bordé",0.13,0.33,1.39,s*0.43,0,0,wood,s*0.18,Enum.Material.WoodPlanks)
			d.line("Étrave",v(s*0.42,0.11,-0.53),v(0,0.17,-0.86),0.12,wood)
		end
		for _,z in ipairs({-0.32,0.31}) do d.box("Banc",0.79,0.09,0.25,0,0.14,z,mix(wood,ivory,0.22)) end
		if id=="voilier" then
			d.box("Mât",0.074,1.21,0.074,0,0.69,0,wood)
			d.part("Voile",v(0.055,0.81,0.79),cf(0.04,0.79,0.13)*CFrame.Angles(0,1.1,0),ivory,"wedge",cloth)
		else d.part("Rame",v(0.092,0.095,1.28),cf(0.22,0.23,0.13)*CFrame.Angles(0,0.6,0),wood) end
	elseif kind=="kite" or kind=="banner" then
		if kind=="banner" then d.box("Hampe",0.09,1.48,0.09,-0.42,0,0,wood) end
		d.part(kind=="kite" and "Toile du cerf-volant" or "Toile de bannière",kind=="kite" and v(0.96,0.96,0.071) or v(0.74,1.05,0.077),cf(0,0.18,0)*CFrame.Angles(0,0,kind=="kite" and 0.785 or 0),c,nil,cloth)
		if kind=="kite" then
			d.line("Armature",v(-0.49,0.18,-0.05),v(0.49,0.18,-0.05),0.050,wood)
			d.line("Queue",v(0,-0.23,0),v(0.35,-0.68,0),0.058,linen)
		else d.box("Motif",0.31,0.28,0.033,0,0.18,-0.052,brass,0.785) end
	elseif kind=="figurine" then
		local c2=id=="stone_figurine" and steel or id=="rag_doll" and linen or wood
		d.ball("Tête",0.40,0.40,0.35,0,0.45,0,c2)
		d.box("Buste",0.48,0.53,0.24,0,0.04,0,c2)
		for s=-1,1,2 do
			d.box("Bras",0.13,0.38,0.19,s*0.29,0.02,0,c2,s*0.26)
			d.box("Pied",0.16,0.31,0.24,s*0.14,-0.36,0,c2,s*0.10)
		end
		if id=="rag_doll" then d.box("Ourlet",0.53,0.14,0.25,0,-0.18,0,c,0,cloth) end
	elseif kind=="instrument" then
		if id=="harp" then
			d.box("Socle",0.92,0.18,0.20,0,-0.51,0,wood)
			d.line("Colonne",v(-0.40,-0.51,0),v(-0.32,0.68,0),0.16,wood)
			d.line("Console",v(-0.32,0.68,0),v(0.44,0.18,0),0.15,wood)
			d.line("Caisse",v(0.44,0.18,0),v(0.38,-0.48,0),0.16,wood)
			for i=0,5 do d.line("Corde",v(i*0.105-0.25,0.58-i*0.082,0),v(i*0.105-0.25,-0.43,0),0.032,linen) end
		elseif id=="drum" then
			d.disc("Fût",1.03,0.56,0,0,0,wood)
			for _,y in ipairs({-0.295,0.295}) do d.disc("Peau",1.08,0.12,0,y,0,ivory) end
			d.box("Baguette",0.12,0.11,1.09,0.34,0.41,0,wood,0.20)
		elseif id=="flute" then
			d.disc("Tube",0.31,1.33,0,0,0,wood)
			for i=0,4 do d.ball("Trou de jeu",0.105,0.105,0.063,0,i*0.21-0.44,-0.139,dark) end
			d.disc("Ligature",0.36,0.085,0,-0.57,0,brass)
		else
			d.ball("Caisse",0.91,1.00,0.42,0,-0.18,0,wood)
			d.box("Manche",0.22,0.72,0.18,0,0.54,0,wood)
			d.ball("Rosace",0.25,0.25,0.065,0,-0.09,-0.203,dark)
			for i=-1,1 do d.line("Corde",v(i*0.061,-0.35,-0.221),v(i*0.061,0.81,-0.105),0.027,ivory) end
		end
	elseif kind=="osselets" then
		miniatures.formeOsselets(function(nom, taille, pose, couleur, forme)
			d.part(nom, taille, pose, couleur, forme:lower())
		end)
	elseif kind=="horn" then
		hat(d,c,"antlers")
	elseif kind=="shell" then shield(d,mix(c,brass,0.45),"shell")
	elseif kind=="skinscale" then
		for i=-1,1 do d.part("Écaille",v(0.49,0.72,0.19),cf(i*0.35,math.abs(i)*-0.1,0)*CFrame.Angles(0,0,i*0.23),mix(c,ivory,(i+1)*0.10),"wedge") end
	elseif kind=="mushroom" or kind=="flower" then
		local base=id=="glow_mushroom" and rgb(111,180,169) or id=="moon_flower" and rgb(214,208,170) or id=="night_flower" and rgb(137,117,174) or c
		d.box("Tige",0.11,0.81,0.118,0,-0.11,0,kind=="flower" and leaf or ivory)
		if kind=="mushroom" then
			d.ball("Chapeau",1.12,0.47,0.97,0,0.33,0,base)
			for i=-1,1 do d.ball("Verrue",0.12,0.097,0.12,i*0.29,0.46,-0.16,mix(base,ivory,0.60)) end
		else
			for i=0,4 do
				local a=i*2*math.pi/5
				d.part("Pétale",v(0.36,0.23,0.12),cf(math.cos(a)*0.28,0.40+math.sin(a)*0.28,0)*CFrame.Angles(0,0,a),base,"ball")
			end
			d.ball("Cœur de fleur",0.22,0.23,0.15,0,0.40,-0.073,brass)
			d.part("Feuille",v(0.39,0.25,0.1),cf(0.21,-0.18,0)*CFrame.Angles(0,0,0.30),leaf,"wedge")
		end
	elseif kind=="spores" then
		local tone=id=="slime_gel" and rgb(109,165,77) or rgb(181,147,113)
		for i=0,5 do
			local a=i*math.pi/3
			d.ball(id=="slime_gel" and "Amas de gel" or "Spore",0.50,0.28+i%3*0.10,0.50,math.cos(a)*0.28,i%3*0.11,math.sin(a)*0.28,mix(tone,ivory,i*0.07))
		end
	elseif kind=="fang" then fang(d,v(0.04,0.36,0),1.35,id=="stinger" and rgb(139,95,62) or ivory)
	elseif kind=="bone" then
		d.box("Diaphyse",0.25,1.33,0.26,0,0,0,id=="fossil_bone" and linen or ivory)
		for s=-1,1,2 do for _,x in ipairs({-0.12,0.12}) do d.ball("Épiphyse",0.34,0.26,0.33,x,s*0.66,0,ivory) end end
	elseif kind=="map" then book(d,c,"map")
	elseif kind=="feather" then
		local f=id=="night_feather" and rgb(91,84,131) or mix(c,ivory,0.45)
		wing(d,-0.14,0.33,0,f,1)
		wing(d,0.15,0.29,0,f,-1)
		d.line("Rachis",v(-0.26,-0.56,0),v(0.12,0.57,0),0.059,ivory)
	elseif kind=="bundle" then
		d.box("Paquet noué",1.08,0.63,0.81,0,0,0,linen,0,cloth)
		d.box("Corde",0.12,0.665,0.85,0,0,0,dark)
		d.box("Corde",1.11,0.665,0.12,0,0,0,dark)
		d.ball("Nœud",0.29,0.17,0.23,0,0.37,0,dark)
	elseif kind=="rotten" then
		d.ball("Aliment gâté",1.18,0.60,0.78,0,0,0,rgb(108,104,69))
		for i=-1,1 do d.ball("Moisissure",0.26,0.12,0.25,i*0.25,0.27,-0.07,rgb(153,171,101)) end
		d.ball("Partie desséchée", 0.57, 0.27, 0.42, 0.40, -0.08, -0.12, rgb(112, 75, 58))
		d.ball("Tache sombre", 0.25, 0.07, 0.24, -0.27, 0.24, 0.19, rgb(68, 72, 45))
	elseif kind=="fish" then
		local grilled=id=="grilled_fish"
		for i=0,grilled and 0 or 1 do
			local Z=i*0.39-0.16
			d.part("Filet",v(1.19,0.31,0.42),cf(0,0.045,Z)*CFrame.Angles(0,0.14*i,0),grilled and rgb(165,89,52) or rgb(116,74,43),"wedge")
		end
		if grilled then
			d.box("Broche",1.74,0.067,0.085,0,0,-0.18,wood)
			for i=-1,1 do d.box("Grillade",0.042,0.028,0.31,i*0.24,0.14,-0.18,dark) end
		else d.box("Lien du fumage",0.10,0.28,0.69,0.31,0.09,0.05,linen) end
	elseif kind=="crown" then hat(d,c,"crown")
	elseif kind=="anchor" then
		d.box("Verge",0.15,1.21,0.14,0,0.02,0,steel,0,metal)
		d.box("Jas",0.84,0.11,0.14,0,0.39,0,dark,0,metal)
		d.oval("Organeau",0,0.76,0,0.15,0.16,0.075,steel,metal,8)
		for s=-1,1,2 do
			d.line("Bras",v(0,-0.61,0),v(s*0.59,-0.39,0),0.14,steel,metal)
			d.part("Patte",v(0.29,0.36,0.13),cf(s*0.55,-0.30,0)*CFrame.Angles(0,0,s*0.40),steel,"wedge",metal)
		end
	elseif kind=="hardware" then
		if id=="chain" then
			for _,x in ipairs({-0.53,0.53}) do d.oval("Maillon de face",x,0,0,0.32,0.20,0.095,steel,metal,12) end
			for i=0,11 do
				local a,b=i*math.pi/6,(i+1)*math.pi/6
				d.line("Maillon de biais",v(math.cos(a)*0.31,0.13*math.sin(a),0.16*math.sin(a)),v(math.cos(b)*0.31,0.13*math.sin(b),0.16*math.sin(b)),0.095,steel,metal)
			end
		elseif id=="pulley" then
			d.box("Chape",0.57,0.95,0.24,0,0.11,0.19,wood,0,Enum.Material.Wood)
			for _,z in ipairs({0,-0.16}) do
				d.part("Roue à gorge",v(0.10,0.88,0.88),cf(0,-0.12,z)*CFrame.Angles(0,math.pi/2,0),wood,"cylinder")
			end
			d.ball("Axe",0.24,0.24,0.19,0,-0.12,-0.23,steel)
			d.oval("Suspente",0,0.65,0,0.18,0.18,0.087,steel,metal,8)
		else
			local hinge=id=="hinge"
			for s=-1,1,2 do
				d.box(hinge and "Battant" or "Équerre",0.64,0.92,0.10,s*0.37,0,0,steel,hinge and 0 or s*0.16,metal)
				for _,y in ipairs({-0.31,0.31}) do bolt(d,s*0.46,y,-0.056,dark) end
			end
			if hinge then d.disc("Gond",0.18,1.04,0,0,-0.041,brass,metal)
			else d.box("Renfort",0.14,0.87,0.11,0,0,-0.06,brass,0,metal) end
		end
	elseif kind=="liquid" then
		flask(d,rgb(188,148,55))
	elseif kind=="seal" then
		d.disc("Cachet contrefait",1.19,0.22,0,0,0,rgb(138,54,45))
		d.disc("Empreinte",0.89,0.045,0,0.12,0,rgb(189,82,59))
		d.line("Fente",v(-0.44,0.15,-0.19),v(0.33,0.15,0.22),0.064,dark)
	elseif kind=="tablegame" then
		if id=="cards" then
			for i=-1,1 do
				d.part("Carte en éventail",v(0.58,0.05,0.84),cf(i*0.29,(i+1)*0.032,0)*CFrame.Angles(0,i*0.29,0),ivory)
				d.disc("Pip",0.17,0.018,i*0.27,(i+1)*0.032+0.032,-0.15,rgb(151,50,46))
			end
		else
			d.box("Plateau",1.45,0.15,1.4,0,-0.06,0,wood,0,Enum.Material.WoodPlanks)
			for x=0,3 do for z=0,3 do
				d.box("Case",0.30,0.032,0.30,x*0.30-0.45,0.029,z*0.30-0.45,(x+z)%2==0 and linen or dark)
			end end
			for i=0,3 do
				d.disc("Pion",0.20,0.12,(i%2)*0.31-0.15,0.105,i*0.28-0.4,i<2 and ivory or rgb(145,64,46))
			end
		end
	elseif kind=="hanging_art" then
		d.box("Toile",1.23,1.02,0.13,0,0,0,rgb(111,164,168))
		for _,x in ipairs({-0.66,0.66}) do d.box("Cadre",0.13,1.14,0.20,x,0,-0.025,wood) end
		for _,y in ipairs({-0.55,0.55}) do d.box("Cadre",1.41,0.13,0.20,0,y,-0.025,wood) end
		d.box("Paysage",1.20,0.33,0.045,0,-0.32,-0.082,leaf)
		d.ball("Soleil",0.21,0.21,0.034,0.35,0.28,-0.082,linen)
	elseif kind=="case" then
		d.disc("Tube de cuir",0.54,1.43,0,0,0,wood,leather)
		for _,y in ipairs({-0.66,0.67}) do d.disc("Embout",0.59,0.12,0,y,0,brass,metal) end
		strap(d,v(-0.23,0.38,0),v(-0.48,0,0),0.075,dark)
		strap(d,v(-0.48,0,0),v(-0.20,-0.43,0),0.075,dark)
	elseif kind=="horn_call" then
		local trumpet=id=="trumpet"
		local material=trumpet and brass or ivory
		local path={v(-0.62,0.21,0),v(-0.32,-0.13,0),v(0.08,-0.21,0),v(0.43,0.04,0)}
		for i=1,#path-1 do d.line("Tube",path[i],path[i+1],0.12+i*0.05,material) end
		d.part("Pavillon",v(0.19,0.50,0.50),cf(0.45,0.045,0)*CFrame.Angles(0,0,0.46),material,"cylinder")
		d.part("Ouverture",v(0.035,0.35,0.35),cf(0.54,0.09,0)*CFrame.Angles(0,0,0.46),dark,"cylinder")
	else error("Silhouette inconnue : "..kind) end
end

-- Préparer et valider hors de la place avant de remplacer les modèles.
local pending, result = {}, {}
local function stage(parent,id,kind,build)
	local model=Instance.new("Model")
	model.Name=id
	model:SetAttribute("ApercuDroit",true)
	model:SetAttribute("SilhouetteDediee",true)
	model:SetAttribute("FamilleVisuelle",kind)
	build(draw(model))
	assert(model:FindFirstChildWhichIsA("BasePart"),id)
	pending[#pending+1]={parent=parent,model=model}
	result[id]=kind
	if #pending%60==0 then task.wait() end
end
local profilsObjets = {
	meat = "croute", cloth = "tissu", hide = "tissu", heap = "filon", nugget = "filon", bar = "lingot",
	brick = "chantier", wood = "ecorce", timber = "ecorce", brush = "outil", horse = "outil",
	lamp = "outil", bell = "outil", seeds = "graine", badge = "quete", weights = "outil", scale = "outil",
	gear = "outil", ball = "tissu", boat = "chantier", kite = "tissu", figurine = "quete",
	instrument = "ecorce", osselets = "bijou", horn = "prise", shell = "prise", skinscale = "prise",
	mushroom = "feuille", spores = "prise", fang = "prise", bone = "prise", tablet = "quete", map = "ecrit",
	feather = "feuille", root = "feuille", flower = "feuille", bundle = "quete", egg = "graine",
	pearl = "gemme", rotten = "croute", fish = "prise", crown = "bijou", banner = "tissu", anchor = "outil",
	hardware = "outil", liquid = "verre", tablegame = "ecrit", hanging_art = "quete", case = "ecrit",
	horn_call = "outil", juice = "verre", forged_nails = "outil", core = "gemme",
	sack = "tissu", scale_art = "prise", gel_art = "ame", fang_art = "prise", bone_art = "prise",
	vial_art = "verre",
}
if cibleObjets then
	for id,kind in itemForms do
		local existant = items:FindFirstChild(id)
		if id:match("^seed_") or id:match("^ame_") or id:match("^prise_")
			or (existant and existant:GetAttribute("PaletteDediee")) then continue end
		local info = assert(config.ITEMS[id], id)
		local c = palette(info.name)
		stage(items, id, kind, function(d)
			d.model:SetAttribute("PaletteDediee", true)
			itemShape(d, id, kind, c)
			miniatures.rehausser(d.model, assert(profilsObjets[kind], kind))
		end)
	end
	for _, entry in pending do
		local old = items:FindFirstChild(entry.model.Name)
		if old then old:Destroy() end
		entry.model.Parent = items
	end
	return result
end

local http = game:GetService("HttpService")
local equipmentReport = assert(loadstring(http:GetAsync("http://127.0.0.1:34873/banc?f=visuels_equipement"),
	"=visuels_equipement"))()
local tools, toolIcons=SS.Outils,RS.IconesOutils
local toolVariants={}
for _,spec in ipairs({{"axe","Hache","Fer"},{"pickaxe","Pioche","Fer"},{"sword","Épée","Lame"}}) do
	for _,tier in ipairs({4,5}) do
		local id=spec[1]..(tier==4 and "_steel" or "_diamond")
		local t=tools[spec[2]]:Clone()
		t.Name=id
		t:SetAttribute("PaletteDediee",true)
		for _,obj in t:GetDescendants() do
			if obj:IsA("BasePart") and (obj.Material==metal or obj.Material==Enum.Material.Rock or obj.Material==Enum.Material.Slate) then
				obj.Color=config.TOOL_TINTS[tier]
			end
		end
		local head=t[spec[3]]
		if tier==5 then
			for s=-1,1,2 do
				local stud=Instance.new("Part")
				stud.Name="Inset de diamant"
				stud.Size=v(0.13,0.23,0.17)
				stud.Color=rgb(149,234,239)
				stud.Material=Enum.Material.Glass
				stud.CFrame=head.CFrame*cf(0,-head.Size.Y*0.21,s*(head.Size.Z/2+0.031))*CFrame.Angles(0,0,math.pi/4)
				stud.Massless=true
				stud.CanCollide,stud.CanQuery,stud.CanTouch=false,false,false
				local weld=Instance.new("WeldConstraint")
				weld.Part0,weld.Part1,weld.Parent=head,stud,stud
				stud.Parent=t
			end
		end
		toolVariants[#toolVariants+1]=t
		stage(toolIcons,id,tier==5 and "outil_diamant" or "outil_acier",function(d)
			for _,obj in t:GetDescendants() do
				if obj:IsA("BasePart") and obj.Transparency<0.95 then
					local copy=obj:Clone()
					for _,child in copy:GetChildren() do
						if not (child:IsA("SpecialMesh") or child:IsA("Texture") or child:IsA("Decal")) then child:Destroy() end
					end
					copy.Anchored,copy.CanCollide,copy.CanQuery,copy.CanTouch=true,false,false,false
					copy.Parent=d.model
				end
			end
		end)
		local icon=pending[#pending].model
		icon:SetAttribute("PaletteDediee",true)
		icon:SetAttribute("ApercuDroit",false)
	end
end
for _,tool in ipairs(toolVariants) do
	local previous=tools:FindFirstChild(tool.Name)
	if previous then previous:Destroy() end
	tool.Parent=tools
end
for i,entry in ipairs(pending) do
	local old=entry.parent:FindFirstChild(entry.model.Name)
	if old then old:Destroy() end
	entry.model.Parent=entry.parent
	if i%90==0 then task.wait() end
end
return http:JSONEncode({count = #pending, models = result, equipement = equipmentReport})
