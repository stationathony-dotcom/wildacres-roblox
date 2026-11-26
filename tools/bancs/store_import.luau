-- Import sûr d'un modèle gratuit du Store créateur (lot C17, 26/11). À lancer en Édition (execute_luau / loadstring).
-- Usage : local imp = loadstring(<ce fichier>)() ; imp(<assetId>, "<NomRangé>") → rapport (table)
--
-- Le modèle est chargé par InsertService, NETTOYÉ, puis rangé dans ServerStorage.StoreImports.<NomRangé>.
-- Il n'est JAMAIS posé dans le Workspace ni dans le jeu par ce banc : c'est ensuite un constructeur
-- (ConstruireModeles, couloir Codex) qui le reprend.
--
-- Nettoyage (règle « attention aux scripts » du propriétaire) :
--   - tout Script / LocalScript / ModuleScript / BaseScript est supprimé (même désactivé, même caché) ;
--   - les objets qui peuvent exécuter ou relayer du code ou du réseau sont supprimés :
--     RemoteEvent/RemoteFunction/BindableEvent/BindableFunction/UnreliableRemoteEvent, *Value (souvent des
--     relais de « require » obfusqués), ProximityPrompt, ClickDetector, Tool, Configuration ;
--   - les sons / particules sont gardés mais comptés (à vérifier) ;
--   - la source de chaque script supprimé est scannée : require(<nombre>), getfenv, setfenv, loadstring,
--     HttpService, MarketplaceService, TeleportService, \x / string.char / reverse → le rapport le signale
--     comme « suspect » (le modèle est alors REFUSÉ et détruit, même nettoyé : un auteur qui cache du code
--     ne fait pas partie des sources fiables).
--   - pièces : compte, budget (≤ 400 par défaut), toutes ancrées, CanTouch coupé.

local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local KILL_CLASSES = {
	"RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent", "BindableEvent", "BindableFunction",
	"ProximityPrompt", "ClickDetector", "Tool", "Configuration", "Actor",
}
local SUSPECT = {
	"require%s*%(%s*%d", "getfenv", "setfenv", "loadstring", "HttpService", "MarketplaceService",
	"TeleportService", "\\x%x%x", "string%.char", "%:reverse%(", "InsertService",
}

local function isValueObject(inst: Instance): boolean
	return inst:IsA("ValueBase")
end

return function(assetId: number, rangeName: string, budget: number?)
	budget = budget or 400
	local report = { id = assetId, nom = rangeName, scripts = 0, suspects = {}, retires = {}, pieces = 0,
		sons = 0, particules = 0, ok = false }

	local okLoad, container = pcall(InsertService.LoadAsset, InsertService, assetId)
	if not okLoad then
		report.erreur = "chargement : " .. tostring(container)
		return report
	end

	-- 1) scripts : scanner puis supprimer
	for _, d in container:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			report.scripts += 1
			local okSrc, src = pcall(function()
				return (d :: any).Source
			end)
			if okSrc and type(src) == "string" then
				for _, pat in SUSPECT do
					if string.find(src, pat) then
						table.insert(report.suspects, d:GetFullName() .. " : " .. pat)
					end
				end
			end
			d:Destroy()
		end
	end

	if #report.suspects > 0 then
		container:Destroy()
		report.erreur = "REFUSÉ : code suspect dans le modèle"
		return report
	end

	-- 2) objets qui relaient du code ou des interactions
	for _, d in container:GetDescendants() do
		if d.Parent == nil then
			continue
		end
		local kill = isValueObject(d)
		for _, cn in KILL_CLASSES do
			if d:IsA(cn) then
				kill = true
			end
		end
		if kill then
			table.insert(report.retires, d.ClassName .. " " .. d.Name)
			d:Destroy()
		end
	end

	-- 3) pièces
	for _, d in container:GetDescendants() do
		if d:IsA("BasePart") then
			report.pieces += 1
			d.Anchored = true
			d.CanTouch = false
		elseif d:IsA("Sound") then
			report.sons += 1
		elseif d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
			report.particules += 1
		end
	end
	if report.pieces > budget then
		container:Destroy()
		report.erreur = ("REFUSÉ : %d pièces (budget %d)"):format(report.pieces, budget)
		return report
	end

	-- 4) rangement
	local dossier = ServerStorage:FindFirstChild("StoreImports")
	if not dossier then
		dossier = Instance.new("Folder")
		dossier.Name = "StoreImports"
		dossier.Parent = ServerStorage
	end
	local old = dossier:FindFirstChild(rangeName)
	if old then
		old:Destroy()
	end
	local model = container:GetChildren()[1]
	if not model then
		container:Destroy()
		report.erreur = "modèle vide"
		return report
	end
	model.Name = rangeName
	model:SetAttribute("StoreId", assetId)
	model.Parent = dossier
	container:Destroy()
	report.ok = true
	return report
end
