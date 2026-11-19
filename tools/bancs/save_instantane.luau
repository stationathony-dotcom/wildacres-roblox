-- Banc Studio : exécuter avec la source Rojo de Save, sans accès au DataStore réel.
local source = game.ServerScriptService.Systemes.Save.Source
local http = game:GetService("HttpService")
local stored, pauseWrite
local fakeStore = {}

function fakeStore:UpdateAsync(_, transform)
	if pauseWrite then
		pauseWrite = false
		coroutine.yield()
	end
	local updated = transform(stored)
	if updated then
		stored = updated
	end
end

local services = {
	DataStoreService = { GetDataStore = function() return fakeStore end },
	RunService = { IsStudio = function() return false end },
	HttpService = http,
}
local env = setmetatable({
	game = {
		JobId = "banc-instantane",
		GetService = function(_, name) return services[name] end,
	},
	task = { wait = coroutine.yield },
}, { __index = getfenv() })
local chunk = assert(loadstring(source))
setfenv(chunk, env)
local Save = chunk()
local profile = { inv = { orbes = 10 }, journal = { visites = { "Valdor" } } }
local player = { UserId = 1, Parent = true }
Save.init({ Joueurs = { get = function() return profile end } })
local _, status = Save.load(player)
assert(status == "new")

local function resume(thread)
	local ok, err = coroutine.resume(thread)
	assert(ok, err)
end

pauseWrite = true
local autosave = coroutine.create(function()
	assert(Save.save(player))
end)
resume(autosave)
assert(coroutine.status(autosave) == "suspended")

profile.inv.orbes = 20
local departure = coroutine.create(function()
	assert(Save.save(player, true))
end)
resume(departure)
assert(coroutine.status(departure) == "suspended")

profile.inv.orbes = 30
table.insert(profile.journal.visites, "Falaise")
resume(autosave)
resume(departure)
assert(coroutine.status(autosave) == "dead")
assert(coroutine.status(departure) == "dead")

local saved = http:JSONDecode(stored)
assert(saved.inv.orbes == 20, "le départ doit conserver le solde mis en file")
assert(#saved.journal.visites == 1 and saved.journal.visites[1] == "Valdor", "le journal imbriqué doit être isolé")
assert(saved.seq == 2 and saved.lock == nil and Save.pending() == 0)
return "OK — instantané du départ isolé pendant une sauvegarde concurrente"
