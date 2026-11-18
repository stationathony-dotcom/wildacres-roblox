-- Banc des châteaux (Systemes/Chateaux) en mode Edit : pour plusieurs graines, compte les villages,
-- les châteaux choisis et ceux qui trouvent un emplacement (plat, sec, loin des routes).
-- Long : lancé en task.spawn, résultat dans l'attribut ServerStorage.BancChateaux.
local SS = game:GetService("ServerStorage")
SS:SetAttribute("BancChateaux", "en cours")
task.spawn(function()
	local f = game.ReplicatedStorage.Shared:Clone()
	f.Name = "SharedBanc" .. math.random(1, 1e6)
	f.Parent = SS
	local sys = game.ServerScriptService.Systemes.Chateaux:Clone()
	sys.Parent = f
	local WG = require(f.RegionPlan)
	local Config = require(f.Config)
	local C = require(sys)
	local lines = {}
	local okAll = true
	for _, seed in { 4242, 1, 77777, 123456789 } do
		local wg = WG.new(seed, WG.CURRENT_GEN)
		C.init({ Config = Config, WG = WG, wg = wg, world = { seed = seed } })
		local villages, chosen, placed, bad = 0, 0, 0, 0
		local R = Config.WORLD_RADIUS
		for rx = -R, R do
			for rz = -R, R do
				if WG.inWorld(rx, rz) then
					local poi = wg:poiOf(rx, rz)
					if poi and poi.kind == "village" then
						villages += 1
					elseif not poi then
						local ok, s, vname = pcall(C.peek, rx, rz)
						if not ok then
							bad += 1
							okAll = false
							table.insert(lines, "ERR " .. tostring(s))
						elseif vname then
							chosen += 1
							if s then
								placed += 1
							end
						end
					end
				end
			end
			task.wait()
		end
		table.insert(lines, string.format("graine %d : villages %d, châteaux choisis %d, posés %d, erreurs %d", seed, villages, chosen, placed, bad))
	end
	f:Destroy()
	SS:SetAttribute("BancChateaux", (okAll and "OK\n" or "ÉCHEC\n") .. table.concat(lines, "\n"))
end)
return "lancé"
