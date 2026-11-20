-- Banc d'équilibre économique (lot C8, 20/11) — mode Edit. Estime l'OR PAR MINUTE de chaque activité
-- avec les vraies données du jeu (résistances de Props, prix du catalogue, cultures, poissons, butins du
-- Bestiaire) et écrit docs/EQUILIBRE-ECONOMIE.md (via sync.py). Hypothèses (à corriger par les essais en Play) :
--   · vente au marchand = 90 % du prix catalogue ; compétences à 0 (elles accélèrent tout pareil) ;
--   · récolte : coups = résistance ÷ force (pierre 1, cuivre 1,6, fer 2,3, mains 0,35 pour le bois),
--     0,25 s par coup + le temps de trouver le suivant (SEARCH : 6 s pour un arbre, 30 s pour un filon,
--     plus rare et réparti par biome) ;
--   · ferme : une case rapporte (prix × 0,9 − graine) par pousse ; 1 jour = 6 min ; une ferme de 40 cases
--     demande ~1 min d'arrosage par jour ;
--   · pêche : 5 s d'attente moyenne + 3 s de lancer / ferrage, 1 prise ratée sur 6 (≈ 9,6 s par poisson) ;
--   · combat : arme de fer ≈ 25 dégâts/s, 12 s pour trouver la bête suivante ; butin moyen + or.
-- Renvoie un résumé ; le détail est dans le document.
local H = game:GetService("HttpService")
local sh = game.ReplicatedStorage.Shared:Clone()
sh.Parent = game:GetService("ServerStorage")
local C = require(sh.Config)
sh:Destroy()
local PropsSrc = game.ServerScriptService.Systemes.Props.Source
local B = require(game.ServerScriptService.Systemes.Bestiaire:Clone())

local SELL = 0.9
local function price(id)
	local i = C.ITEMS[id]
	return i and (i.price or 0) * SELL or 0
end

-- tables de Props lues dans la source (pas de require : le module veut un G complet)
local function tableOf(name)
	local body = string.match(PropsSrc, "local " .. name .. " = (%b{})")
	return assert(loadstring("return " .. body))()
end
local KINDS = tableOf("KINDS")
local TOUGH = tableOf("TOUGH")
local POWER = { [0] = 0.35, [1] = 1, [2] = 1.6, [3] = 2.3 }
local SEARCH = { ore_coal = 30, ore_copper = 30, ore_iron = 30, ore_gold = 40, rock = 10, clay = 12, mushroom = 12, flower = 10,
	log = 8, stump = 8, cactus = 8, stick = 5, stone = 5, tuft = 4 }
local TIER_NAME = { [0] = "mains", [1] = "pierre", [2] = "cuivre", [3] = "fer" }

local rows = {} -- { activité, catégorie, or/min, note }
local function add(cat, name, gpm, note)
	table.insert(rows, { cat = cat, name = name, gpm = gpm, note = note or "" })
end

-- 1. récolte
for kind, k in KINDS do
	local gives = k.gives or (k.tree and { wood = k.wood })
	local tough = TOUGH[kind]
	if gives and tough then
		local value = 0
		for item, r in gives do
			value += (r[1] + r[2]) / 2 * price(item)
		end
		if k.coal then
			value += k.coal * 3 * price("coal")
		end
		local tool = k.tool or (k.tree and "axe") or nil
		for tier = (tool == "axe" or not tool) and 0 or 1, 3 do
			if tier >= (k.tier or 1) or tier == 0 then
				local hits = tool and math.max(1, math.ceil(tough / POWER[tier])) or 1
				local secs = hits * 0.25 + (SEARCH[kind] or 6)
				add("récolte", kind .. " (" .. (tool and TIER_NAME[tier] or "main") .. ")", value / secs * 60,
					string.format("%.0f or / exemplaire, %d coups", value, hits))
			end
			if not tool then
				break
			end
		end
	end
end

-- 2. ferme (une ferme de 40 cases, ~1 min d'arrosage par jour de 6 min)
for id, c in C.CROPS do
	local profit = (c.price or 0) * SELL - (c.seed_price or 0)
	local perDay = profit / (c.days or 3) * 40 -- or par jour de jeu pour 40 cases
	add("ferme", id .. " (40 cases)", perDay / 6, string.format("%.0f or par case et par pousse ; on joue à autre chose 5 min sur 6", profit))
end

-- 3. pêche
local wsum, vsum = 0, 0
for _, f in C.FISH do
	if (f.skill or 0) == 0 then
		wsum += f.weight
		vsum += f.weight * f.price * SELL
	end
end
local CATCH = 9.6
add("pêche", "pêche (débutant)", vsum / wsum / CATCH * 60, string.format("%.0f or par prise", vsum / wsum))
wsum, vsum = 0, 0
for _, f in C.FISH do
	if (f.skill or 0) <= 15 then
		wsum += f.weight
		vsum += f.weight * f.price * SELL
	end
end
add("pêche", "pêche (compétence 15)", vsum / wsum / CATCH * 60, string.format("%.0f or par prise", vsum / wsum))

-- 4. combat (par niveau de créature : moyenne des créatures non-boss de ce niveau)
local byLevel = {}
for id, k in B.KINDS do
	if not k.boss and not k.passive and (k.hp or 0) > 0 then
		local value = (k.gold or 0) * 5
		for _, l in k.loot or {} do
			value += (l[2] + l[3]) / 2 * (l[4] or 1) * price(l[1])
		end
		local secs = k.hp / 25 + 12
		local lv = k.level or 1
		byLevel[lv] = byLevel[lv] or { n = 0, gpm = 0 }
		byLevel[lv].n += 1
		byLevel[lv].gpm += value / secs * 60
	end
end
for lv, t in byLevel do
	add("combat", "créatures niveau " .. lv .. " (" .. t.n .. ")", t.gpm / t.n, "butin vendu + or")
end

-- médiane et écarts
local all = {}
for _, r in rows do
	table.insert(all, r.gpm)
end
table.sort(all)
local median = all[math.floor(#all / 2) + 1] or 1
table.sort(rows, function(a, b)
	if a.cat ~= b.cat then
		return a.cat < b.cat
	end
	return a.gpm > b.gpm
end)
local md = {
	"# Wild Acres — équilibre économique (généré)",
	"",
	"Généré par `tools/bancs/economie.luau` (" .. os.date("%d/%m/%Y") .. ") : **ne pas modifier à la main**. Or par minute de jeu",
	"estimé avec les vraies données ; hypothèses en tête du banc. Médiane de toutes les activités : **" .. math.floor(median) .. " or/min**.",
	"« TROP » = plus de 3 × la médiane, « faible » = moins d'un tiers (une activité ne doit pas rendre les autres inutiles).",
	"",
	"| Activité | Catégorie | Or / min | Repère | Note |",
	"|---|---|---|---|---|",
}
local over, under = {}, {}
for _, r in rows do
	local flag = r.gpm > median * 3 and "TROP" or (r.gpm < median / 3 and "faible" or "")
	if flag == "TROP" then
		table.insert(over, r.name)
	elseif flag == "faible" then
		table.insert(under, r.name)
	end
	table.insert(md, string.format("| %s | %s | %.0f | %s | %s |", r.name, r.cat, r.gpm, flag, r.note))
end
H:PostAsync("http://127.0.0.1:34873/doc?f=EQUILIBRE-ECONOMIE.md", table.concat(md, "\n") .. "\n")
return string.format("%d activités, médiane %.0f or/min\nTROP : %s\nfaible : %s", #rows, median, table.concat(over, ", "),
	table.concat(under, ", "))
