-- Mariages (27/11, MANQUES-MMO n° 10, vie sociale). Rien d'imposé, tout se passe sur place :
--   · au village (Quetes.nearVillage), un joueur qui a une BAGUE SERTIE (ring_gem) la tend à un autre
--     joueur à moins de 12 studs : action « mariage_demande » { target = UserId } ;
--   · l'autre reçoit la demande (message « mariage_demande ») et répond « mariage_oui » dans la minute ;
--   · les deux profils notent prof.conjoint = { uid, name, day } ; la bague est donnée ; les témoins
--     présents (40 studs) le voient ; compteur « maries » (titre « Uni pour la vie »).
--   · Côte à côte (60 studs), les époux gagnent +10 % d'expérience (Social.groupBonus) ;
--   · « divorce » : rompt de son côté (et de l'autre s'il est là ; sinon à sa prochaine rencontre).

local Players = game:GetService("Players")

local Mariages = {}
local G

local asks = {} -- cible -> { from = Player, t = os.clock() }
Mariages.RING = "ring_gem"
Mariages.RANGE = 12

local function byId(uid: number?): Player?
	if not uid then
		return nil
	end
	return (G.playerById and G.playerById(uid)) or Players:GetPlayerByUserId(uid) -- les bancs passent G.playerById
end

local function spouseOf(player: Player)
	local p = G.Joueurs.get(player)
	return p and p.conjoint
end

-- époux en ligne, si le mariage est réciproque (sinon le lien périmé est effacé)
function Mariages.partner(player: Player): Player?
	local c = spouseOf(player)
	if not c then
		return nil
	end
	local other = byId(tonumber(c.uid))
	if not other then
		return nil
	end
	local oc = spouseOf(other)
	if not oc or tostring(oc.uid) ~= tostring(player.UserId) then
		G.Joueurs.get(player).conjoint = nil -- l'autre a divorcé entre-temps
		G.Joueurs.markDirty(player)
		return nil
	end
	return other
end

function Mariages.bonus(player: Player): number
	local o = Mariages.partner(player)
	local a, b = G.Util.root(player), o and G.Util.root(o)
	if a and b and (a.Position - b.Position).Magnitude < 60 then
		return 1.1
	end
	return 1
end

local function close(a: Player, b: Player, d: number): boolean
	local ra, rb = G.Util.root(a), G.Util.root(b)
	return ra ~= nil and rb ~= nil and (ra.Position - rb.Position).Magnitude <= d
end

function Mariages.ask(player: Player, targetId: number?): (boolean, string?)
	local target = byId(targetId)
	if not target or target == player then
		return false, nil
	end
	if not (G.Quetes and rawget(G.Quetes, "nearVillage") and G.Quetes.nearVillage(player)) then
		return false, "Un mariage se célèbre au village."
	end
	if not close(player, target, Mariages.RANGE) then
		return false, "Approche-toi de " .. target.DisplayName .. "."
	end
	if spouseOf(player) or spouseOf(target) then
		return false, "L'un de vous est déjà marié."
	end
	if G.Joueurs.count(player, Mariages.RING) < 1 then
		return false, "Il te faut une bague sertie à offrir."
	end
	if G.Admin and rawget(G.Admin, "blocks") and G.Admin.blocks(target, player) then
		return false, target.DisplayName .. " ne reçoit pas tes propositions."
	end
	asks[target] = { from = player, t = os.clock() }
	G.remotes.Menu:FireClient(target, { kind = "mariage_demande", from = player.DisplayName })
	return true, "Tu tends une bague à " .. target.DisplayName .. "…"
end

function Mariages.accept(player: Player): (boolean, string?)
	local a = asks[player]
	asks[player] = nil
	if not a or os.clock() - a.t > 60 or not (a.from.Parent or G.playerById) then
		return false, "Cette demande n'est plus valable."
	end
	local from = a.from
	if not close(player, from, Mariages.RANGE) or spouseOf(player) or spouseOf(from) then
		return false, "Le moment est passé."
	end
	if not G.Joueurs.take(from, Mariages.RING, 1) then
		return false, from.DisplayName .. " n'a plus la bague."
	end
	G.Joueurs.add(player, Mariages.RING, 1, true)
	local day = G.world.day or 1
	G.Joueurs.get(player).conjoint = { uid = tostring(from.UserId), name = from.DisplayName, day = day }
	G.Joueurs.get(from).conjoint = { uid = tostring(player.UserId), name = player.DisplayName, day = day }
	G.Joueurs.markDirty(player)
	G.Joueurs.markDirty(from)
	for _, p in { player, from } do
		G.Social.bump(p, "maries", 1)
		G.Joueurs.sync(p) -- la fiche [P] affiche le conjoint (X41)
	end
	local ra = G.Util.root(player)
	for _, q in G.Game.players() do
		local r = G.Util.root(q)
		if ra and r and (r.Position - ra.Position).Magnitude < 40 then
			G.Util.toast(q, "💍 " .. from.DisplayName .. " et " .. player.DisplayName .. " se marient !", "big")
		end
	end
	return true, nil
end

function Mariages.divorce(player: Player): (boolean, string?)
	local c = spouseOf(player)
	if not c then
		return false, "Tu n'es pas marié."
	end
	local other = byId(tonumber(c.uid))
	G.Joueurs.get(player).conjoint = nil
	G.Joueurs.markDirty(player)
	G.Joueurs.sync(player)
	if other and spouseOf(other) and tostring(spouseOf(other).uid) == tostring(player.UserId) then
		G.Joueurs.get(other).conjoint = nil
		G.Joueurs.markDirty(other)
		G.Util.toast(other, "💔 " .. player.DisplayName .. " a rompu votre mariage.")
		G.Joueurs.sync(other)
	end
	return true, "Tu n'es plus marié à " .. (c.name or "?") .. "."
end

function Mariages.init(g)
	G = g
	local function wrap(fn)
		return function(player, data)
			local ok, msg = fn(player, type(data) == "table" and tonumber(data.target) or nil)
			if msg then
				G.Util.toast(player, msg, ok and "gain" or nil)
			end
		end
	end
	G.Interact.onAction("mariage_demande", wrap(Mariages.ask))
	G.Interact.onAction("mariage_oui", wrap(Mariages.accept))
	G.Interact.onAction("divorce", wrap(Mariages.divorce))
	Players.PlayerRemoving:Connect(function(p)
		asks[p] = nil
	end)
end

return Mariages
