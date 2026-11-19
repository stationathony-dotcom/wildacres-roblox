-- Banc des caractéristiques par la pratique (mode Edit, sans Play) : Joueurs avec un G simulé.
-- Vérifie : plus de niveau ; l'XP de compétence nourrit les caractéristiques ; rangs ; anciens
-- points convertis ; points de talent depuis la maîtrise ; champs sauvegardés.
local folder = Instance.new("Folder")
folder.Parent = game:GetService("ServerStorage")
local shared = game.ReplicatedStorage.Shared:Clone()
shared.Parent = folder
local jm = game.ServerScriptService.Systemes.Joueurs:Clone()
jm.Parent = folder
local sv = game.ServerScriptService.Systemes.Save:Clone()
sv.Parent = folder
local Config = require(shared.Config)
local Gear = require(shared.Gear)
local J = require(jm)
local okSave, Save = pcall(require, sv)

local res, fails = {}, 0
local function check(name, cond)
	table.insert(res, (cond and "OK   " or "ÉCHEC ") .. name)
	if not cond then
		fails += 1
	end
end

local attrs = {}
local P = { UserId = 7, Name = "T", DisplayName = "T", Character = nil }
function P:SetAttribute(k, v)
	attrs[k] = v
end
function P:GetAttribute(k)
	return attrs[k]
end
function P:FindFirstChildOfClass()
	return nil
end
local toasts = {}
local G = {
	Config = Config,
	Gear = Gear,
	world = { day = 1, id = "w" },
	Util = { toast = function(_, t) table.insert(toasts, t) end, root = function() return nil end },
	Social = { checkTitles = function() end, bump = function() end, titlesOf = function() return {} end, count = function() return 0 end },
	remotes = { Inventory = { FireClient = function() end } },
	Interact = { onAction = function() end, onPrompt = function() end },
}
pcall(J.init, G)
G.Joueurs = J
local prof = J.newProfile()
prof.attrs = { force = 3 } -- ancien point placé
local ok, err = pcall(J.set, P, prof)
check("chargement du profil (" .. tostring(err) .. ")", ok)
local p = J.profiles[P]
check("plus de niveau / xp / points", p and p.level == nil and p.xp == nil and p.points == nil)
check("anciens points convertis : Force 3 → rang 3", p and Config.statLevel(p.statXp.force) == 3 and next(p.attrs) == nil)
check("Force 3 dans les stats", J.stats(P).force == 3)

-- pratique : 400 xp de bûcheronnage → Force (déjà 900 xp) +400
J.addSkillXp(P, "bucheronnage", 400)
check("bûcheronnage nourrit la Force (1300 xp → rang 3)", p.statXp.force == 1300 and J.stats(P).force == 3)
-- anti-farm : au-delà de 400 xp en 5 min dans la même compétence, gains ÷ 4
J.addSkillXp(P, "bucheronnage", 300)
check("anti-farm : 300 xp de plus → seulement 75", p.statXp.force == 1375)
J.addStatXp(P, "force", 225)
check("Force rang 4 à 1600 xp", J.stats(P).force == 4)
local up = false
for _, t in toasts do
	if string.find(t, "Force") and string.find(t, "%(4%)") then
		up = true
	end
end
check("message « +1 💪 Force (4) »", up)

-- répartition : combat = moitié force, moitié défense
local f0, d0 = p.statXp.force, p.statXp.defense or 0
J.addSkillXp(P, "combat", 100)
check("combat : 50 force + 50 défense", p.statXp.force - f0 == 50 and (p.statXp.defense or 0) - d0 == 50)

-- talents : 1 point / 15 rangs de compétence cumulés
p.skills = { agriculture = 4 * 10 * 10, peche = 4 * 10 * 10, minage = 4 * 10 * 10 } -- 3 × rang 10 = 30
p.talents = {}
check("30 rangs de compétence → 2 points de talent", J.talentFree(P) == 2)

-- toutes les compétences ont une caractéristique
local all = true
for _, sk in Config.SKILL_ORDER do
	if not Config.STAT_FROM_SKILL[sk] then
		all = false
	end
end
check("chaque compétence nourrit au moins une caractéristique", all)
check("vitesse travaillée (course + dressage)", Config.STAT_FROM_SKILL.dressage.vitesse ~= nil)

if okSave then
	check("statXp sauvegardé, level/xp/points plus sauvegardés", table.find(Save.FIELDS, "statXp") ~= nil and not table.find(Save.FIELDS, "level") and not table.find(Save.FIELDS, "xp"))
else
	check("Save chargeable", false)
end
folder:Destroy()
return string.format("%d échec(s)\n%s", fails, table.concat(res, "\n"))
