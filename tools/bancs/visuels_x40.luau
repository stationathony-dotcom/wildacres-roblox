-- Banc Édition X40. Vérifie les instances, les ancrages et les dimensions sans personnage ni serveur.
local scripts = game:GetService("StarterPlayer").StarterPlayerScripts
local Theme = require(scripts.ThemeInterface)
local Cadre = require(scripts.Cadre)
local Hud = require(scripts.Hud)
local MiseEnPage = require(scripts.MiseEnPage)
local racine = Instance.new("ScreenGui")
racine.Name = "BancX40"

local function compter(origine)
	return 1 + #origine:GetDescendants()
end

local function verifier()
	assert(Hud.REF == Vector2.new(1672, 941))
	assert(Hud.scaleFor(Hud.REF) == 1)
	assert(Hud.scaleFor(Vector2.new(390, 844)) == 0.42)
	local hud = Hud.build(racine, { menu = { { label = "Sac", icon = "🎒", key = "B" } } })
	local cadre = hud.root
	assert(cadre.Joueur.Position == UDim2.fromOffset(20, 31) and cadre.Joueur.Size == UDim2.fromOffset(420, 150))
	assert(cadre.Boussole.Position == UDim2.new(0.5, 0, 0, 27) and cadre.Boussole.Size == UDim2.fromOffset(448, 36))
	assert(cadre.Minicarte.Position == UDim2.new(1, -12, 0, 10) and cadre.Minicarte.Size == UDim2.fromOffset(202, 202))
	assert(cadre.Horloge.Size == UDim2.fromOffset(240, 66))
	assert(cadre.Menu.Position == UDim2.fromOffset(16, 252) and cadre.Menu.Sac.Size == UDim2.fromOffset(216, 52))
	assert(cadre.Menu.Sac.SelectionImageObject ~= nil)
	assert(cadre.Notifications.Position == UDim2.new(1, -14, 1, -110))
	assert(#hud.mapCells == 23 ^ 2)
	assert(compter(cadre.Joueur) == 54, "carte joueur")
	assert(compter(cadre.Boussole) == 79, "rail de boussole")
	assert(compter(cadre.Horloge) == 11, "horloge")
	assert(compter(cadre.Minicarte) == 546, "minicarte")
	assert(compter(cadre.Menu.Sac) == 16, "bouton de menu avec raccourci")
	local note = hud:notify("★", "Objets récoltés", "Bois × 4")
	assert(compter(note) == 13, "notification")

	local panneau = Instance.new("Frame")
	panneau.Position, panneau.Size = UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(700, 520)
	Theme.coin(panneau, 6)
	Theme.bord(panneau, Theme.couleurs.joint, 2)
	local titre = Instance.new("TextLabel", panneau)
	titre.Text, titre.TextSize = "Sac", 20
	local avant = compter(panneau)
	Cadre.habiller(panneau)
	assert(compter(panneau) - avant == 14, "garniture de fenêtre")
	Cadre.habiller(panneau)
	assert(compter(panneau) - avant == 14, "pose unique du cadre")
	assert(panneau.Position == UDim2.fromScale(0.5, 0.5) and panneau.Size == UDim2.fromOffset(700, 520))
	assert(panneau.BandeauMiel.Interactable == false and titre.ZIndex > panneau.BandeauMiel.ZIndex)

	local dynamique = Instance.new("TextButton", panneau)
	dynamique.BackgroundColor3, dynamique.TextColor3 = Color3.fromRGB(40, 36, 31), Color3.new(1, 1, 1)
	task.wait()
	assert(dynamique:FindFirstChild("VernisX40") and dynamique.SelectionImageObject, "bouton issu d'un rendu différé")
	assert(not dynamique.EclatEmail.Interactable, "décorations hors navigation")
	panneau:Destroy()

	local dims, etroit = MiseEnPage.dimensions(Vector2.new(700, 520), Vector2.new(390, 844), 0.9, 320)
	assert(etroit and math.abs(dims.X * 0.9 - 370) < 0.01 and dims.Y * 0.9 <= 506)
	assert(Theme.rarete(0) == Theme.rarete(1) and Theme.rarete(9) == Theme.rarete(5))
end

local ok, erreur = pcall(verifier)
racine:Destroy()
assert(ok, erreur)
return "VERT X40 · composants, géométrie du HUD et dimensions tactiles"
