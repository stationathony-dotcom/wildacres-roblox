local Retour = {}

function Retour.lire(remotes)
	local infos = remotes:FindFirstChild("Infos") or remotes:WaitForChild("Infos", 2)
	if not infos then return nil end
	local ok, data = pcall(infos.InvokeServer, infos, "retour")
	if ok and type(data) == "table" then return data end
	return nil
end

return Retour
