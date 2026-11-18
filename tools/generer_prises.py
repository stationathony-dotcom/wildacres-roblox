# Génère src/ReplicatedStorage/Shared/Prises.lua (prises de créatures + équipement) à partir de
# tools/creatures_liste.txt (liste des créatures, extraite de Bestiaire + Enemies). Lancer : python tools/generer_prises.py
import io, os, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
dump = io.open(os.path.join(ROOT, "tools", "creatures_liste.txt"), encoding="utf-8").read().splitlines()
K = {}
for l in dump:
    m = re.match(r"(\w+):(\w+)=(.*?)\|(.*?)\|(.*?)\|(\d+)", l)
    if m:
        K[m.group(2)] = {"name": m.group(3), "form": m.group(4), "rank": m.group(5), "level": int(m.group(6))}
# nouveaux boss (ajoutés au Bestiaire plus bas)
K["snow_wyvern"] = {"name": "Wyverne des neiges", "form": "volant", "rank": "B", "level": 10}
K["mountain_giant"] = {"name": "Géant des montagnes", "form": "humain", "rank": "B", "level": 10}
K["deep_beast"] = {"name": "Bête des profondeurs", "form": "serpent", "rank": "B", "level": 10}

# Enemies : forme d'après le modèle
EF = {"Ours": "quadrupede", "Sanglier": "quadrupede", "Chef_Gobelin": "humain", "Myconide_Ancien": "masse", "Roi_Slimes": "masse",
      "Cambrioleur": "humain", "Chameau": "quadrupede", "Croco": "serpent", "Cerf": "quadrupede", "Flamant": "volant", "Renard": "quadrupede",
      "Colosse_Verre": "golem", "Gobelin": "humain", "Gardien_Moissons": "golem", "Golem_Glace": "golem", "Dormeur_Glaces": "quadrupede",
      "Roi_Mycelien": "masse", "Myconide": "masse", "Pingouin": "volant", "Lapin": "quadrupede", "Epouvantail_Maudit": "humain",
      "Scorpion": "insecte", "Ombre": "spectre", "Slime_Bleu": "masse", "Slime": "masse", "Araignee": "insecte", "Crapaud": "quadrupede",
      "Feu_Follet": "spectre", "Loup_Blanc": "quadrupede", "Loup": "quadrupede", "Yeti": "humain"}
for k, v in K.items():
    if v["form"] in EF:
        v["form"] = EF[v["form"]]

def pick(name, form):
    n = name.lower()
    # matériau qui a du sens pour la bête, emplacement de la pièce, nom de la pièce
    if "sorci" in n or "moine" in n: return ("Grimoire déchiré", "📜", "hat", "Capuche ensorcelée")
    if "gobelin" in n: return ("Oreille pointue", "👂", "trinket", "Amulette gobeline")
    if "wyverne" in n: return ("Écailles", "🐉", "armor", "Armure d'écailles")
    if "griffon" in n or "hippogriffe" in n or "chouette" in n or "rapace" in n: return ("Plumes", "🐦", "hat", "Coiffe à plumes")
    if "dragonnet" in n: return ("Écailles de feu", "🐉", "armor", "Armure d'écailles")
    if "mante" in n: return ("Faux", "🗡️", "weapon", "Faucille de mante")
    if "crabe" in n: return ("Pince", "🦀", "weapon", "Masse-pince")
    if "tortue" in n: return ("Carapace", "🐢", "armor", "Bouclier-carapace")
    if "anguille" in n: return ("Peau visqueuse", "🐍", "armor", "Tunique d'anguille")
    if "kelpie" in n: return ("Crin", "🐴", "trinket", "Bracelet de crin")
    if "sirène" in n: return ("Écaille chantante", "🧜", "trinket", "Collier de la sirène")
    if "fée" in n: return ("Poussière", "✨", "trinket", "Amulette féerique")
    if "homme-taureau" in n: return ("Corne", "🐂", "weapon", "Hache à corne")
    if "chevalier" in n: return ("Écu brisé", "🛡️", "armor", "Armure de chevalier")
    if "rôdeur" in n: return ("Cape d'ombre", "🌑", "hat", "Capuche d'ombre")
    if "dévoreur" in n: return ("Noyau d'ombre", "🌑", "trinket", "Talisman d'ombre")
    if "hurleur" in n: return ("Croc", "🐺", "trinket", "Collier de crocs")
    if "chasseur de lune" in n or "chasseur nocturne" in n: return ("Carquois", "🏹", "trinket", "Carquois enchanté")
    if "braconnier" in n: return ("Collet", "➰", "trinket", "Ceinture de collets")
    if "contrebandier" in n: return ("Sceau de contrebande", "🧾", "trinket", "Chevalière de contrebandier")
    if "faux marchand" in n: return ("Faux sceau", "🧾", "trinket", "Bague de faussaire")
    if "mercenaire" in n: return ("Écusson", "🛡️", "armor", "Brigandine")
    if "chasseur de primes" in n: return ("Avis de recherche", "📜", "hat", "Chapeau de traqueur")
    if "cambrioleur" in n: return ("Crochet", "🗝️", "trinket", "Trousseau de passe-partout")
    if "pillard du désert" in n: return ("Turban", "👳", "hat", "Turban du désert")
    if "voleur" in n or "bandit" in n or "maraudeur" in n or "pillard" in n or "pilleur" in n: return ("Masque", "🎭", "hat", "Masque de détrousseur")
    if "garde" in n or "soldat" in n: return ("Insigne", "🎖️", "armor", "Cotte de mailles")
    if "araign" in n: return ("Glande à soie", "🕸️", "armor", "Tunique de soie")
    if "scorpion" in n: return ("Dard", "🦂", "weapon", "Dague à dard")
    if "scarab" in n: return ("Élytre", "🐞", "armor", "Plastron d'élytres")
    if "abeille" in n: return ("Gelée royale", "🍯", "trinket", "Pendentif de cire")
    if "chauve" in n: return ("Aile membraneuse", "🦇", "hat", "Capuche d'aile")
    if "loup" in n or "vargor" in n: return ("Croc", "🐺", "trinket", "Collier de crocs")
    if "ours" in n: return ("Griffe", "🐻", "weapon", "Gantelet griffu")
    if "sanglier" in n: return ("Défense", "🐗", "weapon", "Hache à défense")
    if "cerf" in n: return ("Bois", "🦌", "hat", "Couronne de bois")
    if "renard" in n: return ("Queue", "🦊", "hat", "Chapka")
    if "lynx" in n or "chacal" in n or "hy" in n or "chien" in n: return ("Croc", "🦴", "trinket", "Collier de crocs")
    if "lapin" in n: return ("Patte", "🐇", "trinket", "Porte-bonheur")
    if "chameau" in n: return ("Bosse de graisse", "🐫", "trinket", "Gourde de voyageur")
    if "pingouin" in n or "flamant" in n: return ("Plume", "🐦", "hat", "Chapeau à plume")
    if "basilic" in n or "lézard" in n or "croco" in n: return ("Écailles", "🐊", "armor", "Armure d'écailles")
    if "crapaud" in n: return ("Glande à venin", "🐸", "trinket", "Fiole d'antidote")
    if "slime" in n or "boue" in n or "vase" in n or "marais" in n or "sangsue" in n: return ("Gelée", "🟢", "trinket", "Amulette de gelée")
    if "myconide" in n or "mycél" in n: return ("Spores", "🍄", "hat", "Chapeau-champignon")
    if "serpent" in n or "ver " in n or "bête des profondeurs" in n: return ("Venin", "🐍", "weapon", "Lame venimeuse")
    if "corbeau" in n or "aigle" in n or "harpie" in n or "wyverne" in n: return ("Plumes", "🐦", "hat", "Coiffe à plumes")
    if "gargouille" in n: return ("Éclat de pierre", "🗿", "armor", "Épaulières de pierre")
    if "golem" in n or "colosse" in n or "gardien" in n or "ent " in n or "ronces" in n: return ("Cœur", "💠", "armor", "Plastron de cœur")
    if "squelette" in n or "momie" in n or "goule" in n: return ("Os maudit", "💀", "weapon", "Masse d'os")
    if "spectre" in n or "esprit" in n or "fantôme" in n or "revenant" in n or "ombre" in n or "marcheur" in n or "feu follet" in n or "brumeglace" in n or "roi sans" in n:
        return ("Essence", "👻", "trinket", "Talisman d'essence")
    if "troll" in n or "ogre" in n or "cyclope" in n or "géant" in n or "minotaure" in n or "yéti" in n: return ("Os massif", "🦴", "weapon", "Massue d'os")
    if "épouvantail" in n or "moissons" in n: return ("Paille maudite", "🌾", "hat", "Chapeau de paille maudit")
    if "dormeur" in n: return ("Givre éternel", "❄️", "armor", "Manteau de givre")
    if "verre" in n: return ("Éclat de verre vivant", "💎", "weapon", "Lame de verre")
    # humains (bandits, gardes…)
    if form == "humain": return ("Insigne", "🎖️", "weapon", "Lame")
    return ("Fragment", "✨", "trinket", "Talisman")

SECOND = {"quadrupede": "vitesse", "insecte": "defense", "serpent": "discretion", "volant": "vitesse", "golem": "vie",
          "spectre": "discretion", "masse": "vie", "humain": "charisme"}
MAIN = {"weapon": "force", "armor": "defense", "hat": "chance", "trinket": "force"}
BASE = {"weapon": ("{ iron_ingot = 2, planks = 1 }", "anvil"), "armor": ("{ leather = 3, rope = 1 }", "tannery"),
        "hat": ("{ cloth = 2 }", "loom"), "trinket": ("{ rope = 1, copper_ingot = 1 }", "bench")}

def lua_str(t): return '"' + t.replace('"', '\\"') + '"'
BOSS_DU = ("Roi", "Chef", "Scarabée", "Myconide", "Gardien", "Colosse", "Dormeur", "Géant")
BOSS_DELA = ("Mère", "Wyverne", "Bête")
def de(name, boss=False):
    n = name.split(",")[0]
    if boss:
        if n.startswith("Le "): return "du " + n[3:]
        if n.startswith(BOSS_DU): return "du " + n
        if n.startswith(BOSS_DELA): return "de la " + n
        return "de " + n
    low = n[0].lower() + n[1:] if not n.startswith("Le ") else n
    if n.startswith("Le "): return "du " + n[3:]
    if n.startswith("La "): return "de la " + n[3:]
    if n[0] in "AEÉÈIOU" or (n[0] == "H" and not n.startswith(("Harp", "Hurl"))): return "d'" + low
    return "de " + low

lines = ["-- Prises (18/11, généré par tools : une matière PROPRE à chaque créature, qui a du sens — soie des",
         "-- araignées, venin des serpents, crocs des loups, essence des spectres… — et la pièce d'équipement",
         "-- qu'on en tire, façon MMORPG : stats selon le niveau de la bête, rareté selon son rang). Les boss",
         "-- donnent aussi une ÂME rare, pour une pièce LÉGENDAIRE. Lu par Config (objets + recettes) et par",
         "-- Enemies (butin). Ne pas éditer à la main : relancer le générateur.",
         "local P = {}", "P.KINDS = {"]
for k in sorted(K):
    v = K[k]
    mat, icon, slot, gname = pick(v["name"], v["form"])
    lvl, rank = v["level"], v["rank"]
    cname = v["name"].split(",")[0]
    rar = 4 if rank == "B" else (3 if rank == "E" else (2 if lvl >= 5 else 1))
    tot = 2 + int(lvl * 0.8) + (2 if rank == "E" else 0)
    s1, s2 = MAIN[slot], SECOND.get(v["form"], "chance")
    if s2 == s1: s2 = "vie"
    a = (tot + 1) // 2
    stats = "{ %s = %d, %s = %d }" % (s1, a, s2, tot - a)
    needs, station = BASE[slot]
    nprise = 2 if rank in ("E", "B") else 3
    power = (', power = %d, visual = "%d"' % (2 + lvl // 2, min(8, 2 + lvl // 2))) if slot == "weapon" else ""
    price = 6 + lvl * 5 * (3 if rank == "E" else (6 if rank == "B" else 1))
    soul = ""
    if rank == "B":
        st = "{ %s = %d, %s = %d, vie = 3 }" % (s1, 6, s2, 5)
        soul = (', soul = { id = "ame_%s", name = %s, icon = "🔮", price = %d, gear = { slot = "%s", name = %s, rarity = 4, stats = %s%s } }'
                % (k, lua_str("Âme " + de(cname, True)), 400 + lvl * 40, slot, lua_str(gname + " légendaire " + de(cname, True)), st,
                   (', power = %d, visual = "8"' % (6 + lvl // 2)) if slot == "weapon" else ""))
    lines.append('\t%s = { mat = "prise_%s", name = %s, icon = "%s", price = %d, rank = "%s", level = %d, n = %d, needs = %s, station = "%s", skill = %d,'
                 % (k, k, lua_str(mat + " " + de(cname, rank == "B")), icon, price, rank or "-", lvl, nprise, needs, station, min(30, lvl * 2)))
    lines.append('\t\tgear = { slot = "%s", name = %s, rarity = %d, stats = %s%s }%s },'
                 % (slot, lua_str(gname + " " + de(cname, rank == "B")), rar, stats, power, soul))
lines += ["}", "",
          "-- ajoute objets et recettes au Config (appelé à la fin de Config)",
          "function P.apply(C)",
          "\tfor _, d in P.KINDS do",
          "\t\tC.ITEMS[d.mat] = { name = d.name, icon = d.icon, price = d.price }",
          "\t\tlocal needs = table.clone(d.needs)",
          "\t\tneeds[d.mat] = d.n",
          "\t\ttable.insert(C.RECIPES, { gear = d.gear, needs = needs, station = d.station, cat = \"equipement\", skill = { \"artisanat\", d.skill } })",
          "\t\tif d.soul then",
          "\t\t\tC.ITEMS[d.soul.id] = { name = d.soul.name, icon = d.soul.icon, price = d.soul.price }",
          "\t\t\ttable.insert(C.RECIPES, { gear = d.soul.gear, needs = { [d.soul.id] = 1, [d.mat] = 3, gold_ingot = 2 }, station = \"anvil\", cat = \"equipement\", skill = { \"artisanat\", 20 } })",
          "\t\tend",
          "\tend",
          "end", "", "return P", ""]
io.open(ROOT + r"\src\ReplicatedStorage\Shared\Prises.lua", "w", encoding="utf-8", newline="").write("\n".join(lines))
print(len(K), "créatures")
