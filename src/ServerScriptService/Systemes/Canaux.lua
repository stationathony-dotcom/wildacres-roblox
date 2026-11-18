-- Canaux de discussion façon image cible (onglets Monde / Groupe / Clan / Commerce du chat Roblox).
--   Monde    = canal général de Roblox (RBXGeneral) ;
--   Commerce = tout le monde (pour vendre / acheter sans encombrer le général) ;
--   Clan     = un canal par clan, réservé à ses membres (Systemes/Clans) ;
--   Groupe   = un canal par groupe, réservé à ses membres (Systemes/Social).
-- Les onglets du chat (ChannelTabsConfiguration, activée par Interface.client) n'affichent que les
-- canaux dont on fait partie. Synchronisation toutes les 3 s : rien à brancher dans Clans / Social.
-- Le texte est filtré par Roblox comme tout message du chat (TextChatService).

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local Canaux = {}
local G

local PERIOD = 3
local channels = {} -- clé ("commerce", "clan:<id>", "groupe:<uid du chef>") -> TextChannel

local function folder(): Instance?
	return TextChatService:FindFirstChild("TextChannels")
end

local function channel(key: string, name: string): TextChannel?
	local c = channels[key]
	if c and c.Parent then
		return c
	end
	local f = folder()
	if not f then
		return nil
	end
	c = Instance.new("TextChannel")
	c.Name = name
	c:SetAttribute("Canal", key)
	c.Parent = f
	channels[key] = c
	return c
end

local function sourceOf(c: TextChannel, player: Player): TextSource?
	for _, s in c:GetChildren() do
		if s:IsA("TextSource") and s.UserId == player.UserId then
			return s
		end
	end
	return nil
end

-- clés des canaux où ce joueur doit être
local function wanted(player: Player)
	local keys = { commerce = "Commerce" }
	-- id du clan lu sur le profil (pas de chargement de clan toutes les 3 s)
	local prof = G.Joueurs.get(player)
	local clanId = prof and prof.clan
	if clanId then
		keys["clan:" .. tostring(clanId)] = "Clan"
	end
	local okG, grp = pcall(function()
		return G.Social.groupOf(player)
	end)
	if okG and grp and grp.leader then
		keys["groupe:" .. tostring(grp.leader.UserId)] = "Groupe"
	end
	return keys
end

function Canaux.sync()
	if not folder() then
		return
	end
	local need = {} -- clé -> { joueurs }
	for _, p in Players:GetPlayers() do
		for key, name in wanted(p) do
			local c = channel(key, name)
			if c then
				need[key] = need[key] or {}
				need[key][p] = true
				if not sourceOf(c, p) then
					pcall(function()
						c:AddUserAsync(p.UserId)
					end)
				end
			end
		end
	end
	-- départs : on retire la personne ; canal vide (hors Commerce) : supprimé
	for key, c in channels do
		if c.Parent then
			for _, s in c:GetChildren() do
				if s:IsA("TextSource") then
					local p = Players:GetPlayerByUserId(s.UserId)
					if not p or not (need[key] and need[key][p]) then
						s:Destroy()
					end
				end
			end
			if key ~= "commerce" and not need[key] then
				c:Destroy()
				channels[key] = nil
			end
		else
			channels[key] = nil
		end
	end
end

function Canaux.init(g)
	G = g
	if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
		return
	end
	task.spawn(function()
		while true do
			local ok, err = pcall(Canaux.sync)
			if not ok then
				warn("[WildAcres] Canaux : " .. tostring(err))
			end
			task.wait(PERIOD)
		end
	end)
end

return Canaux
