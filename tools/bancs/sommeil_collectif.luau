-- Banc Studio Edit. Charger le Game.lua du worktree comme chaîne gameSource avant ce bloc.
local gameSource = gameSource or game.ServerScriptService.Systemes.Game.Source
-- Horloge, joueurs et sauvegardes factices : aucun monde ou profil réel n'est modifié.
local function scenario()
	local now, hour = 0, 22
	local world = { day = 1 }
	local saves, players, records = {}, {}, {}
	local service = { PlayerRemoving = { Connect = function() end } }
	local chunk = assert(loadstring(gameSource, "Game.lua"))
	setfenv(chunk, setmetatable({
		game = { GetService = function() return service end },
		os = { clock = function() return now end },
		task = { spawn = function(fn, ...) fn(...) end },
	}, { __index = getfenv() }))
	local Game = chunk()
	Game.players = function() return players end
	Game.init({
		world = world,
		Config = { SLEEP_FROM = 18, MAX_STAMINA = 100 },
		Clock = {
			hour = function() return hour end,
			skipToMorning = function()
				hour = 6
				world.day += 1
			end,
		},
		Interact = { onAction = function() end },
		Joueurs = { get = function() return { stars = 0 } end },
		Mondes = { playerRecord = function(p) return records[p] end },
		Util = { toast = function() end },
		remotes = { Fade = { FireClient = function() end } },
		Save = { save = function(p) saves[p] = (saves[p] or 0) + 1 end },
	})
	local function join()
		local attrs = {}
		local p = {
			Parent = true,
			SetAttribute = function(_, key, value) attrs[key] = value end,
			GetAttribute = function(_, key) return attrs[key] end,
		}
		records[p] = {}
		table.insert(players, p)
		return p
	end
	local function step(t)
		now = t
		Game.step(0)
	end
	local function sleep(p)
		Game.sleep(p, Vector3.new(1, 2, 3))
	end
	return Game, world, players, saves, records, join, step, sleep, function(h) hour = h end
end

do
	local Game, world, _, saves, records, join, step, sleep = scenario()
	local a, b = join(), join()
	sleep(a)
	step(0)
	step(3)
	assert(world.day == 1 and Game.isSleeping(a), "un joueur éveillé empêche le passage au matin")
	sleep(b)
	step(3)
	step(4.99)
	assert(world.day == 1, "attendre deux secondes complètes")
	step(5)
	step(7)
	assert(world.day == 2 and saves[a] == 1 and saves[b] == 1, "un seul matin et une sauvegarde par dormeur")
	assert(not Game.isSleeping(a) and not Game.isSleeping(b), "réveiller les deux joueurs")
	assert(records[a].bed[2] == 2, "conserver le point de réapparition")
end

do
	local Game, world, players, saves, _, join, step, sleep = scenario()
	local a = join()
	sleep(a)
	step(0)
	local b = join()
	step(2)
	assert(world.day == 1, "une arrivée annule le passage au matin")
	b.Parent = nil
	table.remove(players, 2)
	step(3)
	step(4)
	assert(world.day == 1, "le départ relance les deux secondes")
	step(5)
	assert(world.day == 2 and saves[a] == 1 and saves[b] == nil and not Game.isSleeping(a))
end

do
	local Game, world, _, saves, _, join, step, sleep = scenario()
	local a, b = join(), join()
	sleep(a)
	step(0)
	sleep(b)
	step(7)
	step(9)
	assert(world.day == 1 and saves[a] == nil and not Game.isSleeping(a), "le réveil individuel annule le passage")
end

do
	local _, world, _, saves, _, join, step, sleep, setHour = scenario()
	local a = join()
	sleep(a)
	step(0)
	world.day += 1
	setHour(6)
	step(2)
	assert(world.day == 2 and saves[a] == nil, "l'aube naturelle ne déclenche pas un deuxième jour")
end

return "4 scénarios de sommeil collectif réussis"
