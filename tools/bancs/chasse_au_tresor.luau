-- Banc Studio Edit. Fournir JournalSource pour tester le worktree sans synchroniser la place.
local source = JournalSource or game.ServerScriptService.Systemes.Journal.Source
local json = game:GetService("HttpService")
local player = {}
local root = { Position = Vector3.new(100, 43, 100) }
-- Ancienne carte active, sans compteur, et cache distincte sur une autre île.
local profile = { treasures = { ile = { x = 100, z = 100 }, autre = { x = 100, z = 100, dug = 1 } } }
local dirty, rewards, cleared, spent = 0, 0, 0, 0
local toast, snapshot
local G = {
	world = { id = "ile" },
	Config = { Catalogue = { TREASURE = { { "gold", 1, 1 } } } },
	Util = {
		root = function() return root end,
		groundY = function(x, z)
			assert(x == 100 and z == 100)
			return 40
		end,
		toast = function(_, message) toast = message end,
		sfx = function() end,
		finds = function() end,
	},
	Joueurs = {
		get = function() return profile end,
		has = function() return false end,
		talent = function() return 0 end,
		take = function() spent += 1 end,
		add = function() rewards += 1 end,
		markDirty = function()
			dirty += 1
			snapshot = json:JSONEncode(profile)
		end,
	},
	remotes = {
		Fx = { FireClient = function(_, p, kind, position)
			assert(p == player and kind == "tresor" and position == nil)
			cleared += 1
		end },
	},
}
local function loadJournal()
	local chunk = assert(loadstring(source, "Journal"))
	setfenv(chunk, setmetatable({
		game = { GetService = function()
			return { PlayerRemoving = { Connect = function() end } }
		end },
		task = { spawn = function() end },
	}, { __index = getfenv() }))
	local journal = chunk()
	journal.init(G)
	return journal
end

local journal = loadJournal()
for _, position in { Vector3.new(109, 43, 100), Vector3.new(100, 25, 100), Vector3.new(100, 55, 100) } do
	root.Position = position
	assert(not journal.digTreasure(player))
end
assert(dirty == 0 and rewards == 0 and profile.treasures.ile.dug == nil)

root.Position = Vector3.new(100, 43, 100)
assert(journal.digTreasure(player) and dirty == 1 and rewards == 0)
profile = json:JSONDecode(snapshot)
journal = loadJournal()
journal.readTreasureMap(player)
assert(toast:find("1/3", 1, true) and spent == 0 and dirty == 1)
assert(journal.digTreasure(player) and dirty == 2 and rewards == 0)
assert(journal.digTreasure(player) and dirty == 3 and rewards == 4 and cleared == 1)
profile = json:JSONDecode(snapshot)
assert(profile.treasures.ile == nil and profile.treasures.autre.dug == 1)
assert(not journal.digTreasure(player) and rewards == 4 and cleared == 1)
return "Chasse au trésor OK : portée, reprise, relecture, paiement unique et isolation par île"
