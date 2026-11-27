-- Banc du prestige (27/11, Systemes/Social) en mode Edit, faux G : records du monde, succès secrets, titres de magie.
local m = game.ServerScriptService.Systemes.Social:Clone()
m.Parent = game.ServerStorage
local S = require(m)
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK   " or "ÉCHEC ") .. name)
end
local prof = { stats = {}, titles = {} }
local G = { world = { extra = {} }, Config = require(game.ReplicatedStorage.Shared.Config),
	Joueurs = { get = function() return prof end, markDirty = function() end, sync = function() end },
	Util = { toast = function() end }, Interact = { onAction = function() end, onPrompt = function() end },
	remotes = { Menu = { FireClient = function() end } } }
pcall(S.init, G)
local function P(id, n)
	local p = { UserId = id, DisplayName = n }
	function p:FindFirstChild() return nil end
	function p:SetAttribute() end
	function p:GetAttribute() end
	return p
end
local A, B = P(1, "Alix"), P(2, "Bran")
S.bump(A, "fished", 15)
prof = { stats = {}, titles = {} }
S.bump(B, "fished", 12)
check("record : 12 ne bat pas 15", G.world.extra.records.fished.name == "Alix")
prof = { stats = {}, titles = {} }
S.bump(B, "fished", 20)
check("record : 20 bat 15", G.world.extra.records.fished.name == "Bran" and G.world.extra.records.fished.value == 20)
local sec
for _, f in S.featsOf(A) do
	if f.id == "archimage" then
		sec = f
	end
end
check("succès secret caché (« ??? »)", sec and sec.name == "???")
prof = { stats = {}, titles = {} }
pcall(S.bump, A, "sorts", 3, true)
check("3 sorts appris : titre « Mage itinérant »", prof.titles.mage == true)
local n = 0
for _, r in S.records() do
	n += 1
end
check("registre des records lisible (" .. n .. " lignes)", n >= 5)
m:Destroy()
return fails .. " échec(s)\n" .. table.concat(out, "\n")
