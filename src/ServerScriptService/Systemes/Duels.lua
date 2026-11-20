-- Duels entre joueurs (20/11, étape 19 « tournois et défis de compétences, avec règles sûres ») :
--   /defi <pseudo> [mise]  → l'autre (à moins de 30 studs) répond /defi oui ou /defi non (30 s) ;
--   la mise (en or) est prise aux deux et gardée par le jeu ; pendant le duel, se frapper n'est pas un
--   crime (pas d'étoile, pas de témoin) ; le premier mis K.O. perd, le vainqueur reçoit les deux mises.
--   3 min sans vainqueur, l'un qui part (plus de 120 studs, déconnexion) : match nul, chacun reprend sa mise.
-- Rien d'imposé : c'est un outil que les joueurs utilisent pour organiser leurs propres tournois.

local Duels = {}
local G

local Players = game:GetService("Players")

Duels.RANGE = 30 -- studs pour lancer / accepter
Duels.LEAVE = 120 -- studs : au-delà, le duel s'arrête (match nul)
Duels.TIME = 180 -- secondes
Duels.OFFER = 30 -- secondes pour répondre

local offers = {} -- défié -> { from, stake, t }
local active = {} -- joueur -> duel { a, b, stake, t }

local function dist(a: Player, b: Player): number
	local ra, rb = G.Util.root(a), G.Util.root(b)
	return (ra and rb) and (ra.Position - rb.Position).Magnitude or math.huge
end

function Duels.inDuel(player: Player): boolean
	return active[player] ~= nil
end

-- les deux sont adversaires dans le même duel (Combat : pas de crime entre eux)
function Duels.paired(a: Player?, b: Player?): boolean
	local d = a and active[a]
	return d ~= nil and b ~= nil and (d.a == b or d.b == b)
end

local function say(p: Player, msg: string, kind: string?)
	if p and p.Parent then
		G.Util.toast(p, msg, kind)
	end
end

function Duels.challenge(player: Player, target: Player?, stake: number?): (boolean, string)
	stake = math.max(0, math.floor(tonumber(stake) or 0))
	if not target or target == player then
		return false, "/defi <pseudo> [mise en or]  (un joueur près de toi)"
	end
	if active[player] or active[target] then
		return false, "L'un de vous est déjà en duel."
	end
	if dist(player, target) > Duels.RANGE then
		return false, "Approche-toi : il faut être à moins de " .. Duels.RANGE .. " studs pour lancer un défi."
	end
	if stake > 0 and G.Joueurs.count(player, "gold") < stake then
		return false, "Il te faut " .. stake .. " 💰 pour cette mise."
	end
	offers[target] = { from = player, stake = stake, t = os.clock() }
	say(target, "⚔️ " .. player.DisplayName .. " te défie en duel" .. (stake > 0 and (" (mise : " .. stake .. " 💰 chacun)") or "")
		.. ". /defi oui pour accepter, /defi non pour refuser (30 s).", "big")
	return true, "⚔️ Défi lancé à " .. target.DisplayName .. "."
end

local function finish(d, winner: Player?, why: string)
	active[d.a], active[d.b] = nil, nil
	if winner then
		local loser = winner == d.a and d.b or d.a
		if d.stake > 0 then
			G.Joueurs.add(winner, "gold", d.stake * 2, true)
			G.Joueurs.sync(winner)
		end
		G.Economie.record(winner, "duel", "gagné contre " .. tostring(loser.UserId) .. " mise " .. d.stake)
		say(winner, "🏆 Duel gagné contre " .. loser.DisplayName .. (d.stake > 0 and (" : +" .. d.stake * 2 .. " 💰") or "") .. ".", "big")
		say(loser, "Duel perdu contre " .. winner.DisplayName .. ".")
		if G.Social and G.Social.bump then
			pcall(G.Social.bump, winner, "duels")
		end
	else
		for _, p in { d.a, d.b } do
			if d.stake > 0 and p.Parent then
				G.Joueurs.add(p, "gold", d.stake, true)
				G.Joueurs.sync(p)
			elseif d.stake > 0 then
				G.Poste.deliverSystem(p.UserId, { id = "duel_" .. d.id .. "_" .. p.UserId, from = "Duel (mise rendue)", gold = d.stake })
			end
			say(p, "Duel terminé : " .. why .. (d.stake > 0 and " Mise rendue." or ""))
		end
	end
end

function Duels.answer(player: Player, yes: boolean): (boolean, string)
	local o = offers[player]
	offers[player] = nil
	if not o or os.clock() - o.t > Duels.OFFER or not o.from.Parent then
		return false, "Personne ne te défie en ce moment."
	end
	local from = o.from
	if not yes then
		say(from, player.DisplayName .. " refuse ton défi.")
		return true, "Défi refusé."
	end
	if active[player] or active[from] then
		return false, "L'un de vous est déjà en duel."
	end
	if dist(player, from) > Duels.RANGE then
		return false, "Vous êtes trop loin l'un de l'autre."
	end
	local stake = o.stake
	if stake > 0 then
		if G.Joueurs.count(player, "gold") < stake or G.Joueurs.count(from, "gold") < stake then
			say(from, "Duel annulé : l'un de vous n'a plus la mise.")
			return false, "L'un de vous n'a plus la mise (" .. stake .. " 💰)."
		end
		G.Joueurs.take(player, "gold", stake)
		G.Joueurs.take(from, "gold", stake)
		G.Joueurs.sync(player)
		G.Joueurs.sync(from)
	end
	local d = { a = from, b = player, stake = stake, t = os.clock(), id = G.Util.newId and G.Util.newId("duel") or tostring(os.clock()) }
	active[from], active[player] = d, d
	for _, p in { from, player } do
		say(p, "⚔️ En garde ! Duel contre " .. (p == from and player or from).DisplayName .. " — le premier à terre perd.", "big")
	end
	return true, "Duel accepté."
end

-- K.O. d'un joueur (Game.onDeath) : renvoie true si c'était la fin d'un duel
function Duels.onKO(victim: Player, by: Player?): boolean
	local d = active[victim]
	if not d then
		return false
	end
	-- le premier à terre perd, quel que soit le dernier coup (bête, chute…)
	finish(d, d.a == victim and d.b or d.a, "")
	local _ = by
	return true
end

local acc = 0
function Duels.step(dt: number)
	acc += dt
	if acc < 1 then
		return
	end
	acc = 0
	local seen = {}
	for _, d in active do
		if not seen[d] then
			seen[d] = true
			if not d.a.Parent or not d.b.Parent then
				finish(d, nil, "un des duellistes est parti.")
			elseif os.clock() - d.t > Duels.TIME then
				finish(d, nil, "temps écoulé, match nul.")
			elseif dist(d.a, d.b) > Duels.LEAVE then
				finish(d, nil, "vous vous êtes trop éloignés, match nul.")
			end
		end
	end
	for p, o in offers do
		if os.clock() - o.t > Duels.OFFER then
			offers[p] = nil
		end
	end
end

function Duels.init(g)
	G = g
	Players.PlayerRemoving:Connect(function(p)
		offers[p] = nil
	end)
end

return Duels
