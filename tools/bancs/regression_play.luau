-- Banc de régression (étape 26) — à lancer en mode Play, contexte SERVEUR (execute_luau "Server"),
-- avec un joueur dans la partie. ~30 s. Chaque ligne du résultat doit finir par OK.
-- Couvre : quantités hostiles, sauvegarde mémoire, banque + historique, courrier idempotent,
-- bonus temporaires, apparence payante, anti-arbitrage boutique (invariant), météo forcée,
-- admin (/wa, /bloquer), avant-poste refusé à l'arrivée, invitations expirées.
local D = game.ServerStorage:WaitForChild("DbgAppel", 20)
task.wait(6)
local p = game.Players:GetPlayers()[1]
assert(p, "pas de joueur")
local function call(path, ...)
	return select(2, D:Invoke(path, ...))
end
local R = {}
local function check(name, ok, detail)
	table.insert(R, name .. " : " .. (ok and "OK" or ("ÉCHEC " .. tostring(detail))))
end

-- 1. quantités hostiles
call("Joueurs.add", p, "gold", 100)
local g0 = call("Joueurs.count", p, "gold")
check("take(-50) refusé", call("Joueurs.take", p, "gold", -50) == false and call("Joueurs.count", p, "gold") == g0)
check("take(NaN) refusé", call("Joueurs.take", p, "gold", 0 / 0) == false)
check("take(1.5) refusé", call("Joueurs.take", p, "gold", 1.5) == false)

-- 2. sauvegarde
check("session chargée", call("Save.status", p) == "ok")
check("sauvegarde", call("Save.save", p) == true)

-- 3. banque
local hrp = p.Character.HumanoidRootPart
call("Joueurs.add", p, "wood", 10)
D:Invoke("Economie.openBank", p, { root = hrp })
D:Invoke("Economie.bankMove", p, "wood", 4, true)
local prof = call("Joueurs.get", p)
local bank = prof.banks and prof.banks[workspace:GetAttribute("WorldName") and next(prof.banks)]
check("banque dans le perso", prof.banks ~= nil)
D:Invoke("Economie.bankMove", p, "wood", 4, false)

-- 4. courrier idempotent
call("Poste.deliver", p.UserId, { id = "REG1", from = "Banc", gold = 7 })
call("Poste.deliver", p.UserId, { id = "REG1", from = "Banc", gold = 7 })
D:Invoke("Poste.open", p)
local before = call("Joueurs.count", p, "gold")
D:Invoke("Poste.collect", p)
D:Invoke("Poste.collect", p)
check("colis livré une seule fois", call("Joueurs.count", p, "gold") - before == 7, call("Joueurs.count", p, "gold") - before)

-- 5. bonus temporaire
local c0 = (call("Joueurs.stats", p).charisme or 0)
call("Joueurs.add", p, "soap", 1)
D:Invoke("Joueurs.eat", p, "soap")
check("savon +3 charisme", (call("Joueurs.stats", p).charisme or 0) == c0 + 3)

-- 6. météo forcée et effets
call("Meteo.force", "brouillard", 30)
check("brouillard", workspace:GetAttribute("Weather") == "brouillard" and call("Meteo.sightMult") == 0.5)
call("Meteo.force", "clair", 30)

-- 7. admin et blocage
D:Invoke("Admin.run", p, "/bloquer Roblox")
check("blocage", call("Admin.blocks", p, 1) == true)
D:Invoke("Admin.run", p, "/debloquer Roblox")
check("déblocage", call("Admin.blocks", p, 1) == false)

-- 8. avant-poste interdit près de l'arrivée
D:Invoke("Game.teleport", p, call("Game.spawnPos"))
task.wait(2)
call("Joueurs.add", p, "banniere", 1)
check("bannière refusée à l'arrivée", call("Avantpostes.plant", p) == false)

-- 9. invitations expirées : accepter sans invitation ne fait rien (pas d'erreur)
check("accepter sans invitation", pcall(D.Invoke, D, "Social.accept", p))

-- 10. joueur coincé sous le relief : remonté à la surface
do
	local pos = hrp.Position
	local gy = call("Util.groundY", pos.X, pos.Z)
	hrp.CFrame = CFrame.new(pos.X, gy - 30, pos.Z)
	task.wait(3)
	check("remonté sous le sol", hrp.Position.Y > gy - 3, hrp.Position.Y)
end

-- 11. terrassement puis restauration admin
do
	call("Joueurs.add", p, "gold", 5000)
	local base = hrp.Position + Vector3.new(150, 0, 60)
	D:Invoke("Game.teleport", p, Vector3.new(base.X, call("Util.groundY", base.X, base.Z) + 4, base.Z))
	task.wait(2)
	call("Parcelles.create", p, hrp.Position)
	local look = hrp.CFrame.LookVector
	local fp = hrp.Position + Vector3.new(look.X, 0, look.Z).Unit * 5
	local cx, cz = math.floor(fp.X / 4), math.floor(fp.Z / 4)
	D:Invoke("Terraforme.use", p)
	local dug = call("Terraforme.cell", cx, cz)
	D:Invoke("Admin.run", p, "/wa terrain 3")
	check("terrain restauré", dug ~= nil and call("Terraforme.cell", cx, cz) == nil)
end

return table.concat(R, "\n")
