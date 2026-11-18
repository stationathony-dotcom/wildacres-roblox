-- Pousse dans Studio (mode Edit) tous les scripts de src/ qui diffèrent, après vérification de
-- syntaxe ; crée les scripts nouveaux. Prérequis : python tools/sync.py en arrière-plan.
local H = game:GetService("HttpService")
local list = H:JSONDecode(H:GetAsync("http://127.0.0.1:34873/list"))
local out = {}
for path, cls in list do
	local parts = string.split(path, ".")
	local inst = game
	for i, part in parts do
		local nxt = inst:FindFirstChild(part)
		if not nxt and i == #parts then
			nxt = Instance.new(cls)
			nxt.Name = part
			nxt.Parent = inst
			table.insert(out, path .. " CRÉÉ")
		end
		inst = nxt
		if not inst then
			break
		end
	end
	local src = H:GetAsync("http://127.0.0.1:34873/file?p=" .. H:UrlEncode(path))
	if inst and src:gsub("\r\n", "\n") ~= inst.Source:gsub("\r\n", "\n") then
		local f, err = loadstring(src)
		if not f then
			table.insert(out, path .. " ERR " .. tostring(err))
		else
			inst.Source = src
			table.insert(out, path .. " ok")
		end
	end
end
return table.concat(out, "\n")
