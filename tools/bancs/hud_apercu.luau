-- Aperçu du HUD en mode Edit (sans Play) : construit le HUD dans StarterGui.ApercuHud avec des
-- données d'exemple, pour une capture d'écran. Relancer = remplace l'aperçu. Pour l'enlever :
-- game.StarterGui.ApercuHud:Destroy()
local SG = game:GetService("StarterGui")
local old = SG:FindFirstChild("ApercuHud")
if old then
	old:Destroy()
end
local scripts = game.StarterPlayer.StarterPlayerScripts
local tmp = scripts.Hud:Clone()
local themeSource = scripts:FindFirstChild("ThemeInterface")
local shared = game.ReplicatedStorage.Shared:Clone()
local folder = Instance.new("Folder")
folder.Parent = game:GetService("ServerStorage")
tmp.Parent, shared.Parent = folder, folder
local Theme
if themeSource then
	local copie = themeSource:Clone()
	copie.Parent = folder
	Theme = require(copie)
end
local Hud = require(tmp)
local Config = require(shared.Config)
local WG = require(shared.WorldGen)

local gui = Instance.new("ScreenGui")
gui.Name = "ApercuHud"
-- jamais copié dans le PlayerGui en Play (il recouvrait le vrai HUD) ni enregistré dans la place
gui.Archivable = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local cam = workspace.CurrentCamera
local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
local sc = Instance.new("UIScale")
sc.Scale = Hud.scaleFor(v) -- même échelle qu'en jeu (proportions de l'image cible)
sc.Parent = gui

local hud = Hud.build(gui, {
	menu = {
		{ icon = "🎒", label = "Inventaire", key = "B" }, { icon = "🧍", label = "Personnage", key = "P" },
		{ icon = "⭐", label = "Compétences", key = "K" }, { icon = "📜", label = "Quêtes", key = "J" },
		{ icon = "🗺️", label = "Carte", key = "M" }, { icon = "🛡️", label = "Clan", key = "L" },
		{ icon = "🛠️", label = "Atelier", key = "C" }, { icon = "⚙️", label = "Paramètres", key = "O" },
	},
})
local exemple = Instance.new("Model")
local tete = Instance.new("Part")
tete.Name, tete.Size, tete.Parent = "Head", Vector3.new(1.16, 1.18, 1.16), exemple
require(shared.Apparence).peindre(exemple, { skin = 2, hair = "meche", eyes = "amande", beard = "courte" })
hud:setPlayer("WildPlayer", "😇")
hud:setPortrait(exemple)
exemple:Destroy()
hud:setBars(850, 850, 320, 320)
hud:setGold(1240)
hud:setStars(0, 5)
hud:setPlace("🏠", "Valdor")
hud:setClock(12, 14, 35, "☀️", "Ensoleillé")
hud:notify("✅", "Quête acceptée !", "Parler au maire", Color3.fromRGB(120, 220, 90), 600)
hud:notify("💰", "+120 Or", "Récompense de quête", nil, 600)

-- minicarte : vraie génération (graine 4242) autour du village de départ
local wg = WG.new(4242)
local BIOME = {
	prairie = Color3.fromRGB(118, 172, 78), foret = Color3.fromRGB(186, 118, 56), desert = Color3.fromRGB(226, 200, 130),
	neige = Color3.fromRGB(226, 234, 240), marais = Color3.fromRGB(88, 112, 72),
}
local N, STEP = hud.mapN, 3 -- cases de 4 studs par point
local cx0, cz0 = Config.REGION + 13, 11
local colors, icons = {}, {}
for j = 0, N - 1 do
	for i = 0, N - 1 do
		local cx, cz = cx0 + (i - N // 2) * STEP, cz0 + (j - N // 2) * STEP
		colors[j * N + i + 1] = wg:wetRaw(cx, cz) and Color3.fromRGB(70, 120, 170) or BIOME[wg:biome(cx, cz)]
	end
end
table.insert(icons, { 0.62, 0.38, "🏘️" })
hud:setMap(colors, icons)
-- barre rapide d'exemple (même rendu qu'Interface : icônes 3D des outils, emoji sinon)
local bar = Instance.new("Frame")
bar.BackgroundTransparency = 1
bar.Size = UDim2.fromOffset(9 * 78 + 16, 84)
bar.Position = UDim2.new(0.5, 0, 1, -14)
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Parent = gui
local ll = Instance.new("UIListLayout")
ll.FillDirection = Enum.FillDirection.Horizontal
ll.Padding = UDim.new(0, 6)
ll.Parent = bar
local icons = game.ReplicatedStorage:FindFirstChild("IconesOutils")
local SLOTS = { { "Épée" }, { "Hache" }, { "Pioche" }, { "Houe" }, { nil, "🍞", 24 }, { nil, "🧪", 12 }, { "Canne à pêche" }, { "wood", nil, 64 }, { "stone", nil, 32 } }
local objs = game.ReplicatedStorage:FindFirstChild("IconesObjets")
for i, sl in SLOTS do
	local cell = Instance.new("Frame")
	cell.Size = UDim2.fromOffset(72, 72)
	cell.BackgroundColor3 = Color3.fromRGB(30, 26, 22)
	cell.BackgroundTransparency = 0.1
	cell.Parent = bar
	Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 6)
	local st = Instance.new("UIStroke", cell)
	st.Thickness = i == 1 and 3 or 1.5
	st.Color = i == 1 and Color3.fromRGB(246, 200, 70) or Color3.fromRGB(110, 90, 60)
	if Theme then
		local teinte = Theme.rarete(sl[1] and 2 or 1)
		Theme.surface(cell, i == 1 and Theme.couleurs.miel or teinte.fond, Theme.rayons.case, i == 1 and 3.5 or 2, teinte.encre)
		Theme.piece(cell, "PliDeCase", UDim2.fromOffset(9, 3), UDim2.new(1, -15, 0, 5), Theme.couleurs.relief, 2, -5)
	end
	local tpl = sl[1] and ((icons and icons:FindFirstChild(sl[1])) or (objs and objs:FindFirstChild(sl[1])))
	if tpl then
		local vf = Hud.objectViewport(tpl)
		vf.Parent = cell
	elseif sl[2] then
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Text = sl[2]
		t.TextSize = 40
		t.Parent = cell
	end
	local num = Instance.new("TextLabel")
	num.BackgroundTransparency = 1
	num.Text = tostring(i)
	num.Font = Enum.Font.GothamBold
	num.TextSize = 16
	num.TextColor3 = Color3.new(1, 1, 1)
	num.TextStrokeTransparency = 0.3
	num.Size = UDim2.fromOffset(18, 18)
	num.Position = UDim2.fromOffset(5, 3)
	num.TextXAlignment = Enum.TextXAlignment.Left
	num.Parent = cell
	if sl[3] then
		local q = num:Clone()
		q.Text = tostring(sl[3])
		q.Size = UDim2.new(1, -6, 0, 18)
		q.Position = UDim2.new(0, 0, 1, -20)
		q.TextXAlignment = Enum.TextXAlignment.Right
		q.Parent = cell
		if Theme then
			q.Font, q.TextColor3 = Theme.polices.gras, Theme.couleurs.encre
			q.TextStrokeTransparency = 1
		end
	end
	if Theme then
		num.Font, num.TextColor3 = Theme.polices.gras, Theme.couleurs.encre
		num.TextXAlignment, num.BackgroundTransparency, num.TextStrokeTransparency = Enum.TextXAlignment.Center, 0, 1
		Theme.surface(num, i == 1 and Theme.couleurs.miel or Theme.couleurs.feuillet, 6, 1)
	end
end
gui.Parent = SG
task.wait()
hud:setHeading(12)
folder:Destroy()
return "aperçu prêt"
