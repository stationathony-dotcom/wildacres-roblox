-- Banc du découpage des secteurs (Mondes) — execute_luau en mode Edit. DataStore simulé (refuse
-- > 4 Mo comme Roblox). Attendu : 3 clés m_T_r_*, un index m_T_s_0,0 court, 72000 pièces rechargées.
local src = game.ServerScriptService.Systemes.Mondes.Source
local db = {}
local mock = {}
function mock:GetAsync(k)
	return db[k]
end
function mock:SetAsync(k, v)
	if #v > 4000000 then
		error("trop gros")
	end
	db[k] = v
end
function mock:UpdateAsync(k, fn)
	local nv = fn(db[k])
	if nv ~= nil then
		db[k] = nv
	end
	return nv
end
local fakeRS = Instance.new("Folder")
local rem = Instance.new("Folder")
rem.Name = "Remotes"
rem.Parent = fakeRS
local function make()
	local gproxy = setmetatable({ JobId = "J", PrivateServerId = "", PlaceId = 0 }, { __index = function(_, k)
		if k == "GetService" then
			return function(_, n)
				if n == "DataStoreService" then
					return { GetDataStore = function() return mock end }
				end
				if n == "RunService" then
					return { IsStudio = function() return false end }
				end
				if n == "MemoryStoreService" then
					return { GetSortedMap = function() return {} end }
				end
				if n == "Players" then
					return { GetPlayers = function() return {} end, PlayerRemoving = { Connect = function() end } }
				end
				if n == "TeleportService" then
					return { TeleportInitFailed = { Connect = function() end } }
				end
				if n == "ReplicatedStorage" then
					return fakeRS
				end
				return game:GetService(n)
			end
		end
		return game[k]
	end })
	local env = setmetatable({ game = gproxy, workspace = { SetAttribute = function() end, GetAttribute = function() return nil end }, warn = function() end },
		{ __index = getfenv() })
	local f = loadstring(src)
	setfenv(f, env)
	local M = f()
	local G = { Config = { DAY_START = 360 }, Interact = { onAction = function() end, onPrompt = function() end },
		Npcs = { saveAll = function() end }, Compagnons = { sync = function() end } }
	M.init(G)
	M.id = "T"
	return M, G
end
local M, G = make()
G.world = { id = "T", regions = {}, players = {}, npcs = {}, law = {}, orders = {}, market = {}, extra = {} }
M.ensureRegion(0, 0)
local big = {}
for i = 1, 24000 do
	big[i] = { id = "b" .. i, b = "mur_bois", x = i, y = 1, z = 2, r = 0, o = "u1" }
end
G.world.regions["0,0"] = { built = big }
G.world.regions["1,0"] = { built = big }
G.world.regions["2,1"] = { built = big }
M.saveWorld()
local keys = {}
for k, v in db do
	table.insert(keys, k .. ":" .. #v)
end
table.sort(keys)
local M2, G2 = make()
G2.world = { id = "T", regions = {}, players = {} }
M2.ensureRegion(0, 0)
local c = 0
for _, r in G2.world.regions do
	c += #r.built
end
fakeRS:Destroy()
return table.concat(keys, "\n") .. "\nrechargé : " .. c .. " pièces (attendu 72000)"
