-- Banc Edit (21/11) : chaque `Enum.X.Y` écrit dans un script de la place existe vraiment.
-- Né d'un plantage en Play (GroupeHud : Enum.ScrollBarInset.Scrollbar au lieu de ScrollBar) qui arrêtait le
-- démarrage de l'interface : une faute de frappe d'Enum ne se voit ni au loadstring ni dans les autres bancs.
local bad, n = {}, 0
for _, s in game:GetDescendants() do
	local ok, isScript = pcall(function()
		return s:IsA("LuaSourceContainer")
	end)
	if ok and isScript then
		local okS, code = pcall(function()
			return s.Source
		end)
		if okS and code then
			for e, item in string.gmatch(code, "Enum%.(%w+)%.([%w_]+)") do
				n += 1
				local okE = pcall(function()
					return Enum[e][item]
				end)
				if not okE then
					table.insert(bad, s:GetFullName() .. " : Enum." .. e .. "." .. item)
				end
			end
		end
	end
end
return #bad .. " échec(s) — " .. n .. " Enum vérifiés\n" .. table.concat(bad, "\n")
