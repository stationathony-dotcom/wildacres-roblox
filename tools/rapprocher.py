# Rapprochement des listes d'idées (docs/INVENTAIRE-MISSIONS.md) avec ce qui existe dans le jeu (21/11, Claude).
#   python tools/rapprocher.py          -> coche les entrées trouvées (« → nom en jeu ») et affiche le bilan
#   python tools/rapprocher.py --sec    -> n'écrit rien, affiche seulement ce qui reste
# Sections traitées : « liste items.txt », « listes ennemi.txt », « tools/creatures_liste.txt ».
# Une entrée est cochée si tous ses mots utiles se retrouvent dans un nom du jeu (objets, pièces de construction,
# créatures, chaînes du code), ou si elle figure dans SYNONYMES / ABSENTS ci-dessous. Les cases déjà cochées
# ne sont pas touchées. Relancer après chaque ajout de contenu.
import glob
import re
import sys
import unicodedata

ROOT = __file__.replace("\\", "/").rsplit("/tools/", 1)[0]
DOC = ROOT + "/docs/INVENTAIRE-MISSIONS.md"

# entrée de la liste -> nom (ou id) en jeu, quand les mots diffèrent
SYNONYMES = {
    "Poutre carrée": "Poutre", "Poutre ronde": "Poteau rond", "Poutre taillée": "Poutre (Pierre taillée)",
    "Planche brute": "Planches", "Planche rabotée": "Planches", "Équerre en bois": "Linteau",
    "Claie en bois": "Treillis", "Perche": "Échalas", "Mur en terre": "Pan de mur (Pisé)",
    "Mur en palissade": "Palissade", "Demi-mur": "Muret", "Mur arrondi": "Mur courbe",
    "Terre battue": "Dalle (Pisé)", "Sol en herbe": "Dalle (Herbe)", "Sol en gravier": "Dalle (Gravier)",
    "Sol en sable": "Dalle (Sable)", "Sol en planches": "Dalle (Bois)", "Plancher en pin": "Grande dalle (Pin)",
    "Fondation en pierre": "Fondation (Pierre)", "Fondation en bois": "Fondation (Bois)",
    "Toit en planches": "Pente de toit (Bois)", "Toit plat": "Dalle", "Panneau incliné": "Pente de toit",
    "Panneau triangulaire": "Pignon", "Panneau trapézoïdal": "Pente raide", "Chevron": "Chevron de toit",
    "Toit arrondi": "Dôme", "Coupole": "Dôme", "Gouttière en bois": "Gouttière (Bois)", "Rive de toiture": "Linteau",
    "Fenêtre carrée": "Mur avec fenêtre", "Escalier tournant": "Escalier en colimaçon",
    "Escalier de tour": "Escalier en colimaçon", "Garde-corps": "Barrière", "Rambarde": "Barrière",
    "Colonne ronde": "Colonne", "Demi-dôme": "Dôme", "Clou en fer": "Clous", "Clou en cuivre": "Clous de cuivre",
    "Charnière en fer": "Charnière", "Gond": "Charnière", "Équerre en fer": "Ferrure",
    "Pointes de palissade": "Palissade", "Lit simple": "Lit", "Four de cuisson": "Four",
    "Clôture en bois": "Clôture", "Échelle de grange": "Échelle", "Roue de moulin": "Moulin",
    "Aile de moulin": "Moulin", "Axe rotatif": "Moulin", "Manivelle": "Pont-levis", "Trappe mécanique": "Trappe",
    "Roue hydraulique": "Roue à eau", "Bois brut": "Bois", "Branches mortes": "Branches",
    "Fibre végétale": "Fibre", "Roseaux secs": "Roseaux", "Pierre brute": "Pierre", "Miel sauvage": "Miel",
    "Épis de blé": "Blé", "Fibres de lin": "Lin", "Lames": "Lame", "Grande hache": "Hache de fer",
    "Carreaux d'arbalète": "Carreau", "Fourrure de renard": "Fourrure", "Plumes de faisan": "Plume",
    "Panier à poissons": "Nasse", "Selle simple": "Selle de cuir", "Bride": "Bride et rênes",
    "Rênes": "Bride et rênes", "Fer à cheval": "ferrage (C.SHOD_BONUS)", "Selle militaire": "Selle de guerre",
    "Couverture de cheval": "Couverture", "Brosse pour cheval": "Brosse", "Peigne à crinière": "Peigne",
    "Collier pour animal": "Collier clouté", "Panier de transport": "Panier en osier",
    "Journal d'exploration": "Journal", "Carnet de notes": "Journal", "Bouteille contenant un message": "Bouteille à la mer",
    "Bouteille à message": "Bouteille à la mer", "Parchemin ancien": "Page ancienne", "Livre oublié": "Livre rare",
    "Carte ancienne": "Carte de la région", "Lanterne de voyage": "Lanterne", "Piolet décoratif": "Piolet",
    "Sac de voyage": "Besace en toile", "Sac de pièces": "Bourse", "Assiette en céramique": "Assiette",
    "Petite statue": "Figurine en pierre", "Trophée de compétition": "Ruban de champion",
    "Souvenir d'un événement": "Jeton de foire", "Souvenir de découverte": "lieux découverts (stats)",
    "Pierre ancienne": "Fragment de ruine", "Cristal lumineux": "Cristal ancien", "Perle rare": "Perle",
    "Éclat de relique": "Fragment de relique", "Amulette ancienne": "Bijou ancien", "Fossile étrange": "Fossile",
    "Fragment de statue ancienne": "Fragment de ruine", "Graine mystérieuse": "Graines", "Pollen scintillant": "Pollen",
    "Panier de semences": "Sac de graines", "Panier de récolte": "Panier en osier", "Panier d'apiculteur": "Ruche",
    "Cadre de ruche": "Ruche", "Flotteur en liège": "Flotteur", "Moule à pain": "Rouleau à pâtisserie",
    "Passoire": "Tamis", "Broche de cuisson": "Feu de camp", "Bobine": "Fil de lin", "Pelote de laine": "Laine",
    "Écheveau de fil": "Fil de lin", "Navette de tissage": "Métier à tisser", "Lettre de livraison": "Courrier",
    "Bon de commande": "commandes entre joueurs (/commande)", "Commande spéciale": "commandes entre joueurs (/commande)",
    "Facture": "journal des ventes (hôtel des ventes)", "Coffret de marchandises": "Marchandises emballées",
    "Lettre scellée": "quête « Une lettre importante »", "Colis à livrer": "quête « livrer »",
    "Paquet mystérieux": "Marchandises emballées", "Invitation à une foire": "Jeton de foire",
    "Affiche de concours": "concours de village (tableau)", "Insigne d'exploration": "voie Explorateur (titres)",
    "Insigne de réputation": "Systemes/Reputation", "Titre honorifique": "titres (/titres)",
    "Certificat de métier": "rangs de maîtrise", "Contrat de travail": "Contrat", "Marque d'élevage": "lignées des bêtes",
    "Médaille pour animal": "Médaille", "Seau d'alimentation": "Seau", "Instrument de musique": "Luth",
    "Uniforme": "Tenue de garde", "Équipement de garde": "Insigne de garde", "Blason miniature": "Sceau",
    "Porte renforcée": "Porte de château", "Porte à barreaux": "Grille (Fer)", "Porte de cave": "Trappe",
    "Portail de palissade": "Palissade", "Sac de bât": "Besace en toile", "Voile": "Voilier", "Rame": "Barque",
    "Veau": "Vache", "Agneau": "Mouton", "Porcelet": "Sanglier", "Coq": "Poule", "Faucon": "Aigle",
    "Souvenir d'un événement": "Jeton d'événement", "Invitation à une foire": "Billet de foire",
    "Pierre ancienne": "Objet d'une ruine", "Fragment de statue ancienne": "Objet d'une ruine",
    "Objet provenant d'une ruine": "Objet d'une ruine", "Marque d'élevage": "lignées des bêtes (/ecurie)",
    "Certificat de métier": "rangs de maîtrise (Metiers)", "Écaille de créature ancienne": "Écaille ancienne",
    "Longue-vue ancienne": "Longue-vue", "Sac de nourriture animale": "Nourriture animale",
    "Jeu de cartes médiévales fictif": "Jeu de cartes", "Livre de chansons originales": "Livre de chansons",
    "Poutre courbée": "Arche", "Mur en pierre brute": "Pan de mur (Pierre)", "Mur avec ouverture de porte": "Mur avec porte",
    "Porte en bois simple": "Porte", "Pont-levis fonctionnel": "Pont-levis",
    "1. **Pièces simples :** poutres, planches, pierres, murs, sols et toits.": "construction libre (Batir, 234 pièces)",
    "2. **Pièces travaillées :** arches, colonnes, escaliers tournants, fenêtres arrondies, poutres courbes.": "formes composées (Config.SHAPE_PARTS)",
    'Chasseur de primes hostile': 'Chasseur de primes (Bestiaire)',
    'Loup des neiges': 'Loup polaire (Bestiaire)',
    'Aigle géant fantastique': 'Aigle géant (Bestiaire)',
    'Crocodile des marais': 'Croco (Enemies)',
    'Homme-champignon': 'Myconide (Enemies)',
    'Scorpion géant': 'Scorpion (Enemies)',
    'Chacal sauvage': 'Chacal (Bestiaire)',
    'Poisson carnassier géant': 'Brochet géant (Bestiaire)',
    "Méduse d'eau douce fantastique": 'Méduse des marais (Bestiaire)',
    'Monstre des profondeurs': 'Bête des profondeurs (Bestiaire)',
    'Convoi de bandits': 'convoi (Evenements)',
    'Meute de loups affamés': 'meutes (Bestiaire, pack)',
    'Migration de créatures': 'faune itinérante (Bestiaire / Animals)',
    'Invasion de gobelins': 'invasion (Evenements)',
    'Chasseurs de trésors hostiles': 'Pilleur de ruines (Bestiaire)',
    'Patrouille de gardes renégats': 'Garde renégat (Bestiaire, pack)',
    "Apparition d'un spectre ancien": 'spectres (Bestiaire)',
    "Réveil d'un golem": 'événement golem (Evenements)',
    'Créature attirée par une tempête': 'orage (Evenements)',
    'Boss itinérant': 'boss itinérants (Evenements)',
    "Gardien d'une ruine nouvellement découverte": 'Gardien des ruines (Bestiaire)',
    'Bête qui rôde autour des villages la nuit': 'créatures de nuit (Enemies)',
    '**Territoire :** où il vit.': 'biomes (Bestiaire.islandPool)',
    '**Horaires :** jour, nuit ou toutes les heures.': 'jour / nuit (Enemies)',
    '**Comportement :** passif, méfiant, territorial ou agressif.': 'styles (Bestiaire : style)',
    '**Rareté :** commun, rare, très rare ou légendaire.': 'rangs E / B (Bestiaire)',
    '**Difficulté :** adaptée à sa dangerosité.': 'niveaux (Bestiaire : level)',
    '**Butin :** ressources ou objets particuliers.': 'prises (Shared/Prises)',
    '**Variantes :** apparence, taille et caractéristiques différentes.': 'variantes (Bestiaire : look)',
    '**Réaction :** fuit, défend son territoire, poursuit ou appelle ses congénères.': 'fuite / meute (Bestiaire)',
    'Médecins': 'guérisseur (Metiers)',
    'Nobles': 'seigneur des châteaux (Chateaux)',
    'Rois et seigneurs': 'seigneur des châteaux (Chateaux)',
    'Bandits PNJ': 'bandits (Bestiaire)',
    'Enfants PNJ': 'enfants (Metiers)',
    'Écureuils': 'écureuils (Faune.client)',
    'Papillons': 'papillons (Faune.client)',
    'Menuiserie': 'menuiserie (établi, construction)',
    'Tissage': 'tissage (métier à tisser)',
    'Tannerie': 'tannerie (bac de tannage)',
    'Apiculture': 'ruches (Machines.hive)',
    'Extraction minière': 'minage (Props, filons)',
    'Équitation': 'montures (Horses)',
    'Transport de marchandises': 'marchandises emballées / diligence',
    'Scieries': 'scie à main / établi',
    'Mines': 'grottes et filons (Donjons)',
    'Cimetières': 'lieux (WorldGen)',
    'Tours de guet': 'avant-postes (Avantpostes)',
    'Camps de bandits': 'camps (Bestiaire)',
    'Sanctuaires': 'lieux (WorldGen)',
    'Ports': 'ports (Mondes)',
    'Ponts': 'ponts (WorldGen)',
    'Carrières': 'filons de pierre (Props)',
    'Campements de voyageurs': 'colporteur (Metiers)',
    'Chevaux de différentes races': 'robes et lignées (Horses / Ecurie)',
    'Ânes': 'Âne (Config.MOUNTS)',
    'Diligences': 'diligence (Activites)',
    'Navires marchands': 'Voilier / Barques (Barques)',
    'Traversées en ferry': 'voyage en mer (Mondes)',
    'Routes commerciales': 'routes (WorldGen)',
    'Succès': 'succès (Social.bump)',
    'Recettes à débloquer': 'recettes à découvrir (Config.STARTER_RECIPES)',
    'Plans rares': "Plan d'artisan",
    'Maîtrise des métiers': 'rangs de maîtrise (Metiers)',
    'Marchands PNJ': 'marchands (Shop)',
    'Boutiques de joueurs': 'étals (Ventes)',
    'Échanges entre joueurs': 'troc (Social)',
    'Contrats commerciaux': 'commandes entre joueurs (/commande)',
    'Prix variables': 'demandes régionales / pénuries (Shop.wanted)',
    'Taxes': 'taxe du village (Politique)',
    'Coffres-forts': 'coffres + serrures (Protection)',
    'Locations de propriétés': 'lits à louer (Villages, auberge)',
    'Système de réputation commerciale': 'réputation (Reputation)',
    'Courses de chevaux': 'courses (Activites)',
    "Tir à l'arc sportif": 'concours (Activites)',
    'Concours agricoles': 'concours (Activites)',
    'Jeux de plateau': 'Jeu de plateau (E.USES)',
    'Danse': 'gestes /danse (Admin)',
    "Collection d'objets": 'titres de collection (Social)',
    'Exploration de ruines': 'ruines et fouilles (Evenements)',
    "Concours d'artisanat": 'concours (Activites)',
    'Décoration de maisons': 'décor posable (construction)',
    'Événements organisés par les joueurs': 'monde libre (règle 3)',
    'Création de clans': 'clans (Clans)',
    'Grades et responsabilités': 'grades (Clans)',
    'Quartiers généraux': 'territoire de clan (Parcelles p.clan)',
    'Élections de dirigeants': 'élections (Politique)',
    'Marché itinérant': 'colporteur (Metiers)',
    'Fête des récoltes': 'fête (Quetes / Evenements)',
    'Foire médiévale': 'foire (Evenements)',
    'Inondation': 'inondation (Evenements → Farm.flood)',
    'Migration animale': 'faune itinérante (Animals)',
    'Invasion de créatures': 'invasion (Evenements)',
    "Apparition d'un boss": 'boss itinérants (Evenements)',
    'Convoi marchand': 'convoi (Evenements)',
    "Découverte d'une ruine": 'ruines (Evenements)',
    'Trésor enfoui': 'trésors (Tresors, chasse au trésor)',
    'Événement maritime': 'Serpent marin / pêche (Evenements)',
    'Cycle jour/nuit': 'jour / nuit (Clock)',
    'Vents': 'météo (Meteo)',
    'Végétation évolutive': 'repousse (Moissons / Bosquets)',
    'Ressources renouvelables': 'repousse (Moissons / Props)',
    'Traces laissées par les joueurs': 'constructions et témoins persistants (monde)',
    'Faune avec des comportements naturels': 'faune (Animals, fuite du gibier)',
    'Échanges sécurisés': 'troc à deux validations (Social)',
    'Commerce entre joueurs': 'hôtel des ventes (Ventes)',
    'Propriétés privées': 'parcelles (Parcelles)',
    'Coffres partagés': 'coffres + confiance (Util.trusted)',
    'Construction collaborative': 'confiance « batir » (Util.trusted)',
    'Visites de maisons': 'monde libre (règle 3)',
    'Liste des joueurs': 'liste Roblox + /classement',
    'Gestion des permissions': 'confiance (Util.trusted)',
    'Signalement et modération': 'Demandes (/bug /appel)',
    'Protection contre le harcèlement': 'bannissement maison (Demandes)',
    'Journal de quêtes': 'journal [J] (Quetes.client)',
    'Menu des compétences': 'menu commun (X1)',
    'Menu des talents': 'talents [K] (menu commun)',
    'Menu des clans': 'menu commun (X1)',
    'Menu de construction': 'mode [V] (Batir)',
    'Menu de commerce': 'hôtel des ventes (HotelVentes.client)',
    'Menu des animaux': 'écurie (/ecurie)',
    'Menu des montures': 'écurie (/ecurie)',
    'Paramètres graphiques': 'Paramètres (X11)',
    'Commandes mobiles': 'menu tactile (X1, X4)',
    '1. **PNJ et habitants** : donner de la vie aux villages.': 'Npcs / Metiers',
    '2. **Animaux et faune** : peupler les biomes.': 'Animals / Bestiaire / Faune',
    '3. **Métiers et activités** : donner des occupations aux joueurs.': 'compétences (11) + Activites',
    "4. **Lieux et bâtiments** : enrichir l'exploration.": 'WorldGen (îles à thème)',
    '5. **Montures et transports** : faciliter les déplacements.': 'Horses / Barques / diligence',
    '6. **Économie et progression** : créer une vraie durée de vie.': 'Economie / statXp',
    '7. **Clans et événements** : développer la dimension MMORPG.': 'Clans / Evenements',
    "3. **Pièces fonctionnelles :** portes, serrures, moulins, treuils, pièges fictifs, ponts-levis et mécanismes.": "Doors / Protection / Machines / pont-levis (mécanismes)",
}
# entrées laissées de côté exprès (AGENTS.md § 1) : -> raison
ABSENTS = {
    "Mandragore fantastique": "doublon de Racine ancienne / plantes sauvages",
    "Élixir fictif": "doublon de Élixir de vigueur",
    "Permis de commerce fictif": "monde libre sans arbitre (règle 3) : on commerce sans permis",
    "Assassin fictif": "violence adoucie (règle 9) : remplacé par le bandit / le chasseur de primes",
    'Niveaux du personnage': 'règle 4 : pas de niveau de personnage, les caractéristiques montent en pratiquant',
    'Jeux de dés': 'règle 10 : pas de jeux de hasard',
    'Guerres de clans': 'règle 1 : pas de guerre déclarée',
    'Alliances': 'règle 1 : pas de système encadré, les alliances naissent des joueurs',
    'Relations entre clans': 'règle 1 : pas de système encadré',
    'Taxes territoriales': "règle 3 : pas d'arbitre territorial ; taxe de village seulement",
    'Hiver rigoureux': 'règle 10 : saisons retirées (biomes enneigés à la place)',
    'Événement saisonnier': 'règle 10 : saisons retirées',
    'Tutoriel et aide': 'règle 1 : sans indication',
}

STOP = set("de du des la le les l d en a au aux et ou un une pour avec sans sur fictif fictive fictifs fictives".split())


def norm(s):
    s = unicodedata.normalize("NFD", s.lower())
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9 ]", " ", s)


def toks(s):
    return [t[:5] for t in norm(s).split() if t not in STOP and len(t) > 1]


def game_names():
    names = []
    for line in open(ROOT + "/docs/REFERENCE.md", encoding="utf-8"):
        m = re.match(r"\| (.+?) \| `([^`]+)` \|", line)
        if m:
            names.append(re.sub(r"^\W+", "", m.group(1)))
    for l in open(ROOT + "/src/ReplicatedStorage/Shared/Catalogue.lua", encoding="utf-8"):
        m = re.match(r"^\s*(\w+)\|([^|]+)\|", l)
        if m:
            names.append(m.group(2))
    cfg = open(ROOT + "/src/ReplicatedStorage/Shared/Config.lua", encoding="utf-8").read()
    mats = dict(re.findall(r'\{ id = "(\w+)", name = "([^"]+)", item =', cfg))
    for sh, ms in re.findall(r'\{ id = "\w+", name = "([^"]+)", shape = "\w+", size = .*?mats = \{([^}]*)\}', cfg):
        for mid in re.findall(r'"(\w+)"', ms):
            names.append(sh + " (" + mats.get(mid, mid) + ")")
    quoted = re.compile('"([A-ZÀ-Ý][^"\r\n]{2,60})"')
    for f in glob.glob(ROOT + "/src/**/*.lua", recursive=True):
        names += quoted.findall(open(f, encoding="utf-8").read())
    for l in open(ROOT + "/tools/creatures_liste.txt", encoding="utf-8"):
        m = re.match(r"^\w+:\w+=([^|]+)\|", l)
        if m:
            names.append(m.group(1))
    return names


# Quêtes (« liste quetes.txt », réservoir d'idées) : un titre repris tel quel dans le code est coché « repris » ;
# sinon, l'idée est cochée par la SORTE d'offre que le générateur tire déjà (Systemes/Quetes + QuetesLieux),
# d'après son verbe. Les idées sans verbe reconnu restent ouvertes.
VERBE_SORTE = {
    "decouvrir": "découvrir / visiter (QuetesLieux)", "explorer": "visiter (QuetesLieux)", "visiter": "visiter (QuetesLieux)",
    "atteindre": "visiter (QuetesLieux)", "parcourir": "visiter (QuetesLieux)", "reperer": "visiter (QuetesLieux)",
    "observer": "visiter (QuetesLieux)", "traverser": "naviguer / visiter (Quetes)", "rejoindre": "visiter (QuetesLieux)",
    "retrouver": "retrouver (QuetesLieux)", "trouver": "retrouver (QuetesLieux)",
    "fabriquer": "fabriquer (Quetes)", "produire": "fabriquer (Quetes)", "preparer": "fabriquer (Quetes, cuisine)",
    "creer": "fabriquer (Quetes)", "construire": "bâtir (Quetes)", "installer": "bâtir / étal (QuetesLieux)",
    "decorer": "bâtir (Quetes)", "restaurer": "réparer (QuetesLieux)", "reparer": "réparer (QuetesLieux)",
    "livrer": "livrer (QuetesLieux)", "apporter": "apporter (Quetes)", "fournir": "apporter (Quetes)",
    "rapporter": "apporter (Quetes)", "transporter": "livrer (QuetesLieux)", "transmettre": "lettre (Quetes)",
    "reunir": "apporter (Quetes)", "rassembler": "apporter (Quetes)", "obtenir": "apporter (Quetes)", "donner": "apporter (Quetes)",
    "recolter": "récolter (Quetes)", "cultiver": "semer / récolter (Quetes)", "planter": "semer (Quetes)",
    "pecher": "pêcher (Quetes)", "escorter": "escorter (QuetesLieux)", "suivre": "escorter / enquêter (QuetesLieux)",
    "identifier": "enquêter (QuetesLieux)", "resoudre": "enquêter (QuetesLieux)", "interroger": "enquêter (QuetesLieux)",
    "ecouter": "enquêter (QuetesLieux)", "enqueter": "enquêter (QuetesLieux)",
    "participer": "concours / courses (Activites)", "gagner": "concours / courses (Activites)",
    "reussir": "concours / courses (Activites)", "vaincre": "tuer / prime (Quetes)", "chasser": "tuer (Quetes, chasse en groupe)",
    "eliminer": "tuer (Quetes)", "capturer": "prime (Quetes)", "arreter": "prime (Quetes)", "apprivoiser": "apprivoiser (Quetes)",
    "dresser": "apprivoiser (Quetes)", "miner": "miner (Quetes)", "extraire": "miner (Quetes)", "abattre": "abattre (Quetes)",
    "couper": "abattre (Quetes)", "vendre": "vendre (Quetes)", "collecter": "collecter (Quetes)", "naviguer": "naviguer (Quetes)",
    "contribuer": "chantiers de village (Chantiers)", "nourrir": "apporter (Quetes)", "proteger": "escorter (QuetesLieux)",
    "defendre": "invasion / chantiers (Evenements)",
}


def quest_match(entry, code_norm):
    m = re.match(r"^\d+\. \*\*(.+?)\*\* — (.+)$", entry)
    if not m:
        return None
    title, desc = m.group(1), m.group(2)
    t = " ".join(norm(title).split())
    if len(t) > 6 and t in code_norm:
        return "repris tel quel (Quetes)"
    nd = norm(desc)
    if "reputation" in nd or "confiance" in nd or "reconnu" in nd:
        return "réputation par village (Reputation)"
    first = nd.split()
    for w in first[:3]:
        if w in VERBE_SORTE:
            return "sorte « " + VERBE_SORTE[w] + " »"
    return None


def main():
    write = "--sec" not in sys.argv
    names = game_names()
    index = [(set(toks(n)), n) for n in names if toks(n)]
    code = "\n".join(open(f, encoding="utf-8").read() for f in glob.glob(ROOT + "/src/**/*.lua", recursive=True))
    lines = open(DOC, encoding="utf-8").read().split("\n")
    quetes_src = ""
    for f in ("Quetes.lua", "QuetesLieux.lua", "Chantiers.lua"):
        quetes_src += open(ROOT + "/src/ServerScriptService/Systemes/" + f, encoding="utf-8").read()
    code_norm = " ".join(norm(quetes_src).split())
    sec = None
    done, left, stats = 0, {}, {}
    for i, l in enumerate(lines):
        h = re.match(r"^## (.+)$", l)
        if h:
            sec = h.group(1).strip()
            continue
        if sec not in ("liste items.txt", "listes ennemi.txt", "tools/creatures_liste.txt", "liste quetes.txt"):
            continue
        m = re.match(r"^- \[ \] \((\d+)\) (.+)$", l)
        if not m:
            continue
        entry = m.group(2).strip()
        found = None
        if sec == "liste quetes.txt":
            found = quest_match(entry, code_norm)
        elif sec == "tools/creatures_liste.txt":
            cid = re.match(r"`\w+:(\w+)`", entry)
            if cid and re.search(r"\b" + cid.group(1) + r"\b", code):
                found = "Bestiaire"
        elif entry in ABSENTS:
            found = "volontairement absent : " + ABSENTS[entry]
        elif entry in SYNONYMES:
            target = SYNONYMES[entry]
            t = set(toks(target))
            # un synonyme n'est accepté que si sa cible existe vraiment (sauf renvoi à un système : « ( », « / », « « »)
            if any(ch in target for ch in "(/«") or any(t <= c for (c, n) in index):
                found = target
            else:
                print("synonyme sans cible en jeu :", entry, "->", target)
        else:
            t = set(toks(entry))
            best = [n for (c, n) in index if t and t <= c]
            if best:
                found = min(best, key=len)
        stats.setdefault(sec, [0, 0])
        if found:
            lines[i] = "- [x] (" + m.group(1) + ") " + entry + " → " + found
            done += 1
            stats[sec][0] += 1
        else:
            left.setdefault(sec, []).append(entry)
            stats[sec][1] += 1
    if write:
        open(DOC, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
    for s, (a, b) in stats.items():
        print(f"{s} : {a} cochées, {b} restent")
    for s, v in left.items():
        print(f"\n## restent — {s} ({len(v)})\n" + " · ".join(v))


if __name__ == "__main__":
    main()
