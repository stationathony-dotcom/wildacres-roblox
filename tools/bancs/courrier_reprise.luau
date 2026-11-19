-- Banc Studio Edit. Charge Poste dans un environnement sans DataStore réel.
local source = game.ServerScriptService.Systemes.Poste.Source
local http = game:GetService("HttpService")
local function runScenario(parcels, claimed)
	local stored = http:JSONEncode(parcels)
	local saveFails, updateFails = false, false
	local store = {
		GetAsync = function()
			return stored
		end,
		UpdateAsync = function(_, _, transform)
			assert(not updateFails, "panne simulée de la boîte")
			local value = transform(stored)
			if value then
				stored = value
			end
		end,
	}
	local services = {
		DataStoreService = { GetDataStore = function() return store end },
		HttpService = http,
		RunService = { IsStudio = function() return false end },
		Players = {},
	}
	local load = assert(loadstring(source))
	setfenv(load, setmetatable({
		game = { GetService = function(_, name) return assert(services[name]) end },
		task = { spawn = function() end },
	}, { __index = getfenv() }))
	local poste = load()
	local prof = { mailClaimed = claimed, gold = 0 }
	local player = { UserId = 1 }
	local menu
	poste.init({
		Config = { ITEMS = {} },
		Interact = { onPrompt = function() end, onAction = function() end },
		Util = { root = function() return { Position = Vector3.zero } end, toast = function() end },
		Joueurs = {
			get = function() return prof end,
			add = function(_, item, n) prof[item] += n end,
			sync = function() end,
		},
		Economie = { record = function() end },
		Save = { save = function() return not saveFails end },
		world = { day = 0 },
		remotes = { Menu = { FireClient = function(_, _, data) menu = data end } },
	})
	poste.open(player)
	return {
		collect = function(failSave, failUpdate)
			saveFails, updateFails = failSave, failUpdate
			poste.collect(player)
			return prof.gold, http:JSONDecode(stored), menu
		end,
	}
end

local first = runScenario({ { id = "a", gold = 9 } })
local gold, box, menu = first.collect(true, false)
assert(gold == 9 and #box == 1 and #menu.mail == 0 and menu.mailPending)
gold, box, menu = first.collect(false, false)
assert(gold == 9 and #box == 0 and not menu.mailPending)

local second = runScenario({ { id = "b", gold = 7 } })
gold, box, menu = second.collect(false, true)
assert(gold == 7 and #box == 1 and menu.mailPending)
gold, box, menu = second.collect(false, false)
assert(gold == 7 and #box == 0 and not menu.mailPending)

local legacy = runScenario({ { from = "Ada", t = 42, gold = 8 }, { from = "Ada", t = 42, gold = 3 } },
	{ ancien_42_Ada_0 = 1 })
gold, box = legacy.collect(false, true)
assert(gold == 0 and #box == 2 and not box[1].id)
gold, box = legacy.collect(true, false)
assert(gold == 3 and #box == 2 and box[1].id == "ancien_42_Ada_0" and box[2].id ~= box[1].id)
gold, box, menu = legacy.collect(false, false)
assert(gold == 3 and #box == 0 and not menu.mailPending)
return "Courrier : 3 scénarios réussis"
