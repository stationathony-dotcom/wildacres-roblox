-- Banc de régression unique (lot C1, 20/11) — mode Edit, sans Play. Prérequis : python tools/sync.py.
-- Lance un par un tous les bancs Edit de tools/bancs et rend un verdict VERT / ROUGE par banc.
--   local H = game:GetService("HttpService")
--   loadstring(H:GetAsync("http://127.0.0.1:34873/banc?f=tout"))()            -- bancs rapides
--   loadstring(H:GetAsync("http://127.0.0.1:34873/banc?f=tout"))("lourds")    -- + génération, châteaux,
--                                                                              --   secteurs, sauvegardes
--   loadstring(...)({ "arc", "froid" })                                       -- seulement ceux-là
-- Tourne en task.spawn (sinon le MCP décroche) : lire ensuite l'attribut ServerStorage.BancTout
-- (« en cours » tant que ce n'est pas fini ; BancToutEtape = banc en cours).
-- Laissés de côté exprès : pousser, reference (écrivent), regression_play et recettes (Play), aperçus et
-- planches visuelles (hud_apercu, village_apercu, visuels_*, icones_outils), pnj_looks (empreinte à
-- comparer à la main avant / après un changement de génération).
-- Ajouter ici tout nouveau banc Edit.
local mode = ...
local SS = game:GetService("ServerStorage")
local H = game:GetService("HttpService")
local URL = "http://127.0.0.1:34873/banc?f="

local RAPIDES = {
	"animaux", "apparence", "applique", "arc", "enums", "objets", "armee", "audit_contenu", "bestiaire_livre", "bosquets", "creatures_voxel", "lointain", "butin", "butin_creatures", "chantiers",
	"chasse_au_tresor", "chroniques", "courrier_reprise", "course", "demandes", "demandes_joueurs", "diligence", "donjons_groupe", "duels", "ecurie", "economie",
	"equilibre", "flux_or", "fauche", "formes", "froid", "harpon", "herbes", "infos", "concours", "route", "berger", "etats", "mecanismes", "moissons", "ouvriers", "pnj_danger", "quetes",
	"quetes_lieux", "relations_pnj", "reputation", "resistance", "roue_eau", "save_instantane",
	"securite", "selection", "sommeil_collectif", "stats", "talents", "tourelles", "tresors", "usure", "ventes", "villes",
}
local LOURDS = { "generation", "chateaux", "secteurs", "save_concurrence", "cascades", "perf_serveur" }

local SAVE_ATTENDU = {
	firstLoad = "new", saveA = true, bWhileLocked = "nil", releaseA = true, bAfterRelease = "ok", bGold = 70,
	lateA = false, saveBflaky = true, dbGold = 90, cOnFail = "error", corrupt = "error",
}

-- Verdict d'un résultat : renvoie (vert?, résumé court)
local function verdict(name, res)
	if type(res) == "table" then
		res = H:JSONEncode(res)
	end
	res = tostring(res)
	local first = string.split(res, "\n")[1]
	if name == "generation" then
		local ok, data = pcall(H.JSONDecode, H, res)
		if not ok then
			return false, "résultat illisible"
		end
		for seed, st in data do
			if (st.houseOverlap or 0) > 0 or (st.houseWater or 0) > 0 or (st.propInHouse or 0) > 0
				or (st.flooded or 0) > 0 or st.starts ~= 1 or st.err then
				return false, "graine " .. seed .. " : " .. H:JSONEncode(st)
			end
		end
		return true, "toutes les graines propres"
	elseif name == "secteurs" then
		local c = tonumber(res:match("rechargé : (%d+)"))
		return c == 72000, "rechargé " .. tostring(c) .. " / 72000"
	elseif name == "save_concurrence" then
		local ok, data = pcall(H.JSONDecode, H, res)
		if not ok then
			return false, "résultat illisible"
		end
		for k, v in SAVE_ATTENDU do
			if data[k] ~= v then
				return false, k .. " = " .. tostring(data[k]) .. " (attendu " .. tostring(v) .. ")"
			end
		end
		return true, "verrous, pannes et corruption OK"
	end
	local n = tonumber(res:match("(%d+) échec")) or tonumber(res:match("échecs : (%d+)"))
		or tonumber(res:match("(%d+) problème"))
	if n and n > 0 then
		return false, first
	end
	if res:find("^ÉCHEC") or res:find("\nÉCHEC") or res:find("À VOIR") then
		local bad = res:match("\n(ÉCHEC[^\n]*)") or res:match("(À VOIR[^\n]*)") or first
		return false, bad
	end
	return true, first:sub(1, 90)
end

local function runOne(name)
	local okGet, src = pcall(H.GetAsync, H, URL .. name)
	if not okGet then
		return false, "introuvable : " .. tostring(src)
	end
	local f, err = loadstring(src)
	if not f then
		return false, "syntaxe : " .. tostring(err)
	end
	local ok, res = pcall(f)
	if not ok then
		return false, "erreur : " .. tostring(res):sub(1, 200)
	end
	if name == "chateaux" then
		-- résultat asynchrone dans l'attribut BancChateaux
		local t = os.clock()
		while SS:GetAttribute("BancChateaux") == "en cours" and os.clock() - t < 300 do
			task.wait(1)
		end
		res = SS:GetAttribute("BancChateaux")
	end
	return verdict(name, res)
end

local list = type(mode) == "table" and mode or table.clone(RAPIDES)
if mode == "lourds" then
	table.move(LOURDS, 1, #LOURDS, #list + 1, list)
end

SS:SetAttribute("BancTout", "en cours")
task.spawn(function()
	local lines, reds, t0 = {}, 0, os.clock()
	for _, name in list do
		SS:SetAttribute("BancToutEtape", name)
		local t = os.clock()
		local ok, green, detail = pcall(runOne, name)
		if not ok then
			green, detail = false, "plantage : " .. tostring(green)
		end
		if not green then
			reds += 1
		end
		table.insert(lines, string.format("%s %-18s %4.1fs  %s", green and "VERT " or "ROUGE", name, os.clock() - t,
			tostring(detail)))
		task.wait()
	end
	-- ménage : copies et maquettes laissées par les bancs (sinon elles partent dans la place enregistrée)
	local swept = 0
	for _, c in SS:GetChildren() do
		if c:IsA("Folder") and (c.Name == "Folder" or c.Name == "Shared" or c.Name:sub(1, 4) == "Banc") then
			c:Destroy()
			swept += 1
		end
	end
	for _, c in workspace:GetChildren() do
		if c.Name == "Fleche" or c.Name == "QuetesLieux" or c.Name:sub(1, 4) == "Banc" then
			c:Destroy()
			swept += 1
		end
	end
	table.insert(lines, 1, string.format("%d banc(s) rouge(s) sur %d — %.0f s — %d reste(s) de banc effacé(s)", reds, #list,
		os.clock() - t0, swept))
	SS:SetAttribute("BancToutEtape", nil)
	SS:SetAttribute("BancTout", table.concat(lines, "\n"))
end)
return "lancé (" .. #list .. " bancs)"
