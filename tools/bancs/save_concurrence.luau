-- Banc de test de Save (étape 1C) — à coller dans execute_luau (mode Edit) ou la barre de commande.
-- Simule deux / trois serveurs (JobId différents) sur un DataStore factice partagé, avec pannes.
-- Attendu : {"firstLoad":"new","saveA":true,"bWhileLocked":"nil","releaseA":true,"bAfterRelease":"ok",
--   "bGold":70,"lateA":false,"saveBflaky":true,"dbGold":90,"cOnFail":"error","corrupt":"error",
--   "corruptKept":"{corrompu"}   (dure ~1 min : la lecture en panne réessaie 6 fois)
local H = game:GetService("HttpService")
local src = game.ServerScriptService.Systemes.Save.Source
local db, failNext = {}, 0
local mock = {}
function mock:UpdateAsync(k, fn)
	task.wait(0.01)
	if failNext > 0 then
		failNext -= 1
		error("503 simulé")
	end
	local nv = fn(db[k])
	if nv ~= nil then
		db[k] = nv
	end
	return nv
end
function mock:RemoveAsync(k)
	db[k] = nil
end
local function makeServer(job)
	local gproxy = setmetatable({ JobId = job }, { __index = function(_, k)
		if k == "GetService" then
			return function(_, n)
				if n == "DataStoreService" then
					return { GetDataStore = function() return mock end }
				end
				if n == "RunService" then
					return { IsStudio = function() return false end }
				end
				return game:GetService(n)
			end
		end
		return game[k]
	end })
	local env = setmetatable({ game = gproxy, workspace = { GetAttribute = function() return nil end }, warn = function() end },
		{ __index = getfenv() })
	local f = loadstring(src)
	setfenv(f, env)
	local S = f()
	local prof = { inv = { gold = 0 } }
	S.init({ Joueurs = { get = function() return prof end } })
	S.LOCK_TIMEOUT = 6
	return S, prof
end
local player = { UserId = 1, Parent = true }
local R = {}
local A, pa = makeServer("A")
local _, st = A.load(player)
R.firstLoad = st
pa.inv.gold = 50
R.saveA = A.save(player)
local B, pb = makeServer("B")
local bStatus
task.spawn(function()
	local dd, s = B.load(player)
	bStatus = s
	if dd then
		pb.inv = dd.inv
	end
end)
task.wait(1)
R.bWhileLocked = tostring(bStatus)
pa.inv.gold = 70
R.releaseA = A.save(player, true)
local t = os.clock()
while not bStatus and os.clock() - t < 10 do
	task.wait(0.1)
end
R.bAfterRelease = tostring(bStatus)
R.bGold = pb.inv.gold
R.lateA = A.save(player)
pb.inv.gold = 90
failNext = 2
R.saveBflaky = B.save(player)
R.dbGold = H:JSONDecode(db.p_1).inv.gold
local C = makeServer("C")
failNext = 99
local _, cs = C.load({ UserId = 2, Parent = true })
failNext = 0
R.cOnFail = cs
db.p_3 = "{corrompu"
local D = makeServer("D")
local _, ds = D.load({ UserId = 3, Parent = true })
R.corrupt = ds
R.corruptKept = db.p_3
return H:JSONEncode(R)
