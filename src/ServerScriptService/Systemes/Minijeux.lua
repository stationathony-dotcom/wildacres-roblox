-- Mini-jeux d'adresse (crochetage, apprivoisement…) VÉRIFIÉS PAR LE SERVEUR.
-- Un curseur oscille : position(t) = 0.5 + 0.5 * sin(2π · vitesse · t + phase). Il faut appuyer quand il
-- est dans la zone (largeur `zone`, centre tiré au hasard pour chaque goupille). Le client ne fait
-- qu'afficher et envoyer « j'appuie » : le serveur recalcule où était le curseur à cet instant (en
-- retirant le ping) et décide. Envoyer « réussi » soi-même est impossible.

local Players = game:GetService("Players")

local Minijeux = {}
local G
local sessions = {} -- joueur -> session
local TOL = 0.035 -- marge (en fraction de la barre) pour le réseau

function Minijeux.init(g)
	G = g
	G.Interact.onAction("mg_press", function(player)
		Minijeux.press(player)
	end)
	G.Interact.onAction("mg_cancel", function(player)
		Minijeux.finish(player, false, "Abandon.")
	end)
	Players.PlayerRemoving:Connect(function(p)
		sessions[p] = nil
	end)
end

local function cursorAt(s, t: number): number
	return 0.5 + 0.5 * math.sin(2 * math.pi * s.speed * t + s.phase)
end

local function newPin(s)
	s.center = s.zone / 2 + math.random() * (1 - s.zone)
	s.phase = math.random() * math.pi * 2
	s.pinStart = os.clock()
end

local function send(player: Player, s, event: string)
	G.remotes.Menu:FireClient(player, {
		kind = "minigame", event = event, title = s.title, hint = s.hint,
		pins = s.pins, done = s.done, misses = s.misses, missed = s.missed,
		zone = s.zone, speed = s.speed, center = s.center, phase = s.phase,
	})
end

-- params : title, hint, pins, zone (0-1), speed (cycles / s), misses (fautes permises), timeout (s),
--          near = fonction() -> bool (le joueur est-il toujours sur place ?)
-- onDone(ok: boolean, info) est appelé une seule fois.
function Minijeux.start(player: Player, params, onDone: (boolean, any) -> ())
	if sessions[player] then
		Minijeux.finish(player, false, nil)
	end
	local s = {
		title = params.title or "", hint = params.hint or "Appuie quand le curseur est dans la zone verte !",
		pins = params.pins or 3, zone = math.clamp(params.zone or 0.2, 0.05, 0.6), speed = params.speed or 1,
		misses = params.misses or 2, missed = 0, done = 0, timeout = params.timeout or 40,
		started = os.clock(), near = params.near, onDone = onDone, lastPress = 0,
	}
	newPin(s)
	sessions[player] = s
	send(player, s, "start")
	-- délai max
	task.delay(s.timeout, function()
		if sessions[player] == s then
			Minijeux.finish(player, false, "Trop lent…")
		end
	end)
	return true
end

function Minijeux.active(player: Player): boolean
	return sessions[player] ~= nil
end

function Minijeux.press(player: Player)
	local s = sessions[player]
	if not s then
		return
	end
	local now = os.clock()
	if now - s.lastPress < 0.18 then
		return -- pas de mitraillage
	end
	s.lastPress = now
	if s.near and not s.near() then
		Minijeux.finish(player, false, "Tu t'es éloigné.")
		return
	end
	-- où était le curseur quand le joueur a appuyé ? (on essaie plusieurs retards réseau plausibles)
	local ping = 0.1
	pcall(function()
		ping = math.clamp(player:GetNetworkPing(), 0, 0.5)
	end)
	local t = now - s.pinStart
	local hit = false
	for _, lag in { ping, ping * 2, ping * 0.5, 0 } do
		local pos = cursorAt(s, math.max(0, t - lag))
		if math.abs(pos - s.center) <= s.zone / 2 + TOL then
			hit = true
			break
		end
	end
	if hit then
		s.done += 1
		if s.done >= s.pins then
			Minijeux.finish(player, true, nil)
			return
		end
		newPin(s)
		send(player, s, "pin")
	else
		s.missed += 1
		if s.missed > s.misses then
			Minijeux.finish(player, false, "Raté !")
			return
		end
		send(player, s, "miss")
	end
end

function Minijeux.finish(player: Player, ok: boolean, msg: string?)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	G.remotes.Menu:FireClient(player, { kind = "minigame", event = "end", ok = ok, msg = msg })
	local done = s.onDone
	if done then
		local okCall, err = pcall(done, ok, { missed = s.missed, done = s.done })
		if not okCall then
			warn("[WildAcres] mini-jeu : " .. tostring(err))
		end
	end
end

return Minijeux
