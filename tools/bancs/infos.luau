-- Banc Edit (21/11) : Systemes/Infos (aperçu de parcelle, repères de carte) + Parcelles.check, G simulé.
local RS = game:GetService("ReplicatedStorage")
local P = assert(loadstring(game.ServerScriptService.Systemes.Parcelles.Source, "Parcelles"))()
local I = assert(loadstring(game.ServerScriptService.Systemes.Infos.Source, "Infos"))()
local out, fails = {}, 0
local function check(name, ok)
	if not ok then
		fails += 1
	end
	table.insert(out, (ok and "OK    " or "ÉCHEC ") .. name)
end
-- dossier Remotes temporaire si absent (en Edit, Main ne tourne pas)
local madeRemotes = false
if not RS:FindFirstChild("Remotes") then
	local f = Instance.new("Folder")
	f.Name = "Remotes"
	f.Parent = RS
	madeRemotes = true
end
local hadRF = RS.Remotes:FindFirstChild("Infos") ~= nil
local hadParc = RS:FindFirstChild("Parcelles") ~= nil

local bag, toasts, actions = {}, {}, {}
local function mk(id, name)
	local p = { UserId = id, DisplayName = name, Name = name }
	bag[p] = { gold = 50 }
	return p
end
local A, B = mk(1, "Alix"), mk(2, "Bastien")
local G = {
	world = { day = 3, players = {} },
	Config = { LIBRE = { batirChezAutrui = false, parcelleProcheVillage = false }, CELL = 4, REGION = 64 },
	WG = { regionOf = function(cx, cz) return math.floor(cx / 64), math.floor(cz / 64) end, placeLabel = function(poi) return "Valdor" end },
	wg = { poiOf = function(_, qx, qz) if qx == 0 and qz == 0 then return { x0 = 10, z0 = 10, w = 10, d = 10 } end return nil end },
	Util = { root = function() return { Position = Vector3.new(0, 5, 0) } end, toast = function(p, t, k) table.insert(toasts, { p, t, k }) end,
		owns = function() return false end, trusted = function() return false end, pid = function(p) return "u" .. p.UserId end },
	Joueurs = { has = function(p, i, n) return (bag[p][i] or 0) >= n end, take = function(p, i, n) if (bag[p][i] or 0) < n then return false end bag[p][i] -= n return true end },
	Clans = { clanOfUid = function() return nil end },
	Interact = { onAction = function(k, f) actions[k] = f end },
}
G.Mondes = { playerRecord = function(p) local k = tostring(p.UserId) G.world.players[k] = G.world.players[k] or {} return G.world.players[k] end }
G.Parcelles = P
P.init(G)
I.init(G)

-- aperçu de parcelle (X18)
local v = I.parcelle(A, { x = 1000, z = 1000 })
check("1er terrain loin de tout : ok, gratuit, demi-côté 24", v and v.ok == true and v.prix == 0 and v.n == 0 and v.half == 24)
check("aperçu sans effet : aucun terrain créé", #P.plotsOf(G.world.players["1"]) == 0 and #toasts == 0)
v = I.parcelle(A, { x = 60, z = 60 })
check("trop près d'un village : refus avec le nom (" .. tostring(v and v.motif) .. ")", v and v.ok == false and v.motif:find("Valdor") ~= nil)
check("coordonnées non finies : rien", I.parcelle(A, { x = 0 / 0, z = 1 }) == nil and I.parcelle(A, { x = math.huge, z = 1 }) == nil and I.parcelle(A, "x") == nil)
check("création : 1er terrain posé", P.create(A, Vector3.new(1000, 5, 1000)) == true)
v = I.parcelle(B, { x = 1030, z = 1000 })
check("Bastien trop près du terrain d'Alix : refus", v and v.ok == false and v.motif:find("Alix") ~= nil)
v = I.parcelle(A, { x = 2000, z = 2000 })
check("2e terrain d'Alix : 100 or, refusé avec 50 or", v and v.ok == false and v.prix == 100 and v.n == 1)
check("create refusé : toast de sorte « refus », or intact", P.create(A, Vector3.new(2000, 5, 2000)) == false and toasts[#toasts][3] == "refus" and bag[A].gold == 50)
bag[A].gold = 150
check("avec 150 or : 2e terrain payé 100", P.create(A, Vector3.new(2000, 5, 2000)) == true and bag[A].gold == 50)

-- repères (X15)
check("poser un repère « lit »", I.poser(A, { x = 12.7, z = -40.2, sorte = "lit" }) == true)
I.poser(A, { x = 50, z = 50, sorte = "licorne" })
local r = I.reperes(A)
check("2 repères, coordonnées arrondies", #r == 2 and r[1].x == 12 and r[1].z == -41)
check("sorte inconnue → « perso »", r[2].sorte == "perso")
check("nom donné par le serveur (lieu proche)", r[1].nom == "Lit · Valdor")
check("les repères d'Alix ne sont pas ceux de Bastien", #I.reperes(B) == 0)
check("retirer un repère par id", I.retirer(A, { id = r[1].id }) == true and #I.reperes(A) == 1)
check("retirer un id inconnu : rien", I.retirer(A, { id = 999 }) == false)
check("coordonnées non finies : refusé", I.poser(A, { x = 0 / 0, z = 0 }) == false)
for _ = 1, I.MAX_MARKS do
	I.poser(B, { x = 1, z = 1 })
end
check("plafond technique : le 201e est refusé avec un motif", I.poser(B, { x = 1, z = 1 }) == false and toasts[#toasts][3] == "refus")
check("actions branchées (repere_poser, repere_retirer)", actions.repere_poser ~= nil and actions.repere_retirer ~= nil)

-- retour (X22) : lit du monde courant + journal d'absence gardé pour la session
local rt = I.retour(A)
check("retour sans lit ni absence : { absence = {} }", rt and rt.lit == nil and #rt.absence == 0)
G.world.players["1"].bed = { 120, 8, -36 }
G.Protection = { absenceVue = { [A] = { { day = 2, text = "Un voleur a forcé ton coffre." } } } }
rt = I.retour(A)
check("retour : lit en x/z", rt.lit and rt.lit.x == 120 and rt.lit.z == -36)
check("retour : journal d'absence recopié", #rt.absence == 1 and rt.absence[1].day == 2 and rt.absence[1].text:find("voleur") ~= nil)
rt.absence[1].text = "modifié"
check("retour : copie (le journal de session reste intact)", G.Protection.absenceVue[A][1].text:find("voleur") ~= nil)
G.world.players["2"].bed = { 0 / 0, 1, 1 }
check("retour : lit non fini ignoré", I.retour(B).lit == nil)
local Prot = assert(loadstring(game.ServerScriptService.Systemes.Protection.Source, "Protection"))()
check("Protection : absenceVue publié", type(Prot.absenceVue) == "table")

-- ménage
if not hadRF and RS.Remotes:FindFirstChild("Infos") then
	RS.Remotes.Infos:Destroy()
end
if madeRemotes then
	RS.Remotes:Destroy()
end
if not hadParc and RS:FindFirstChild("Parcelles") then
	RS.Parcelles:Destroy()
end
return fails .. " échec(s)\n" .. table.concat(out, "\n")
