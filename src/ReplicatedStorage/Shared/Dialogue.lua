-- Répliques des PNJ selon leur caractère et la situation (repris du jeu Godot).
-- Variables : {titre} (comment on t'appelle), {nom} (le PNJ), {victime}, {lieu}, {dir}, {e}, {il}, {Il}, {lui}.
-- Version adoucie : on ne tue pas, on assomme ; un PNJ caché « disparaît ».

local D = {}

D.TRAITS = {
	bourru = { label = "Bourru", brave = true, gossip = 0.4, greed = 1.0, snitch = true },
	jovial = { label = "Jovial", brave = false, gossip = 0.6, greed = 0.9, snitch = true },
	anxieux = { label = "Anxieux", brave = false, gossip = 0.5, greed = 1.0, snitch = true },
	commere = { label = "Commère", brave = false, gossip = 1.0, greed = 1.0, snitch = true },
	radin = { label = "Radin", brave = false, gossip = 0.3, greed = 1.3, snitch = true },
	pieux = { label = "Pieux", brave = true, gossip = 0.5, greed = 0.9, snitch = true },
	filou = { label = "Filou", brave = false, gossip = 0.2, greed = 1.1, snitch = false },
	sherif = { label = "Shérif", brave = true, gossip = 0.3, greed = 1.0, snitch = true },
}
D.TRAIT_LIST = { "bourru", "jovial", "anxieux", "commere", "radin", "pieux", "filou" }

D.LINES = {
	commun = {
		greet = { "Bonjour.", "Belle journée, hein ?" },
		greet_good = { "Ah, {titre} ! Content de te voir." },
		greet_bad = { "Hm. Toi.", "Passe ton chemin." },
		wanted = { "Le shérif te cherche ! Reste loin de moi !" },
		robbed = { "Quelqu'un m'a volé cette nuit… Tu ne saurais rien, toi ?" },
		missing = { "{victime} a disparu. Personne ne sait où…" },
		mourning = { "On a retrouvé {victime} assommé{e} dans l'herbe. Qui a pu faire ça ?" },
		saw_theft = { "Hé ! Au voleur !" },
		saw_assault = { "À l'aide ! Il attaque les gens !" },
		saw_ko = { "Il l'a assommé ! AU SECOURS !" },
		hurt = { "Aïe ! Arrête !" },
		flee = { "Laisse-moi tranquille !" },
		fight = { "Tu vas le regretter !" },
		body = { "Oh non… {victime} ! {Il} ne bouge plus !" },
		gift = { "Pour moi ? Merci beaucoup !" },
		chat = { "Les récoltes poussent bien cette année.", "Tu as vu le ciel ce matin ?" },
		gossip = { "Paraît que {titre} n'est pas très honnête…" },
		rumor = { "Il y a {lieu} {dir}, à ce qu'on dit." },
		refuse = { "Je ne fais pas affaire avec des gens comme toi." },
		trade = { "Qu'est-ce qu'il te faut ?" },
		bye = { "À plus." },
		night = { "Il est tard, je rentre." },
		curious = { "Hein ? Qu'est-ce qui se passe ?" },
		trespass = { "Qu'est-ce que tu fais chez moi ?! Dehors !" },
	},
	bourru = {
		greet = { "Mouais. Qu'est-ce que tu veux ?", "T'as pas du travail, toi ?", "Si c'est pour causer, j'ai pas le temps." },
		greet_good = { "T'es pas si mal, pour un étranger.", "Ah, c'est toi. Bon. Assieds-toi si tu veux." },
		greet_bad = { "Toi, je t'ai à l'œil.", "Encore toi ? Dégage." },
		robbed = { "Un salopard m'a dépouillé. Si je le trouve, je lui casse les dents. C'est pas toi, hein ?" },
		saw_theft = { "HÉ ! Repose ça tout de suite !" },
		hurt = { "Tu cherches la bagarre ? Tu vas l'avoir !" },
		fight = { "Viens là, que je t'apprenne la politesse !" },
		gift = { "…Bon. Merci. Mais ça ne fait pas de nous des amis." },
		chat = { "Les jeunes, ça ne sait plus rien faire de ses mains.", "Ce shérif dort plus qu'il ne surveille." },
		gossip = { "Moi je dis que {titre} a une sale tête. Et j'ai jamais tort." },
		rumor = { "Va voir {lieu} {dir}. Et fiche-moi la paix." },
		refuse = { "Je vends rien aux crapules." },
		bye = { "C'est ça." },
	},
	jovial = {
		greet = { "Salut l'ami ! Quel temps magnifique !", "Oh, un nouveau visage ! Bienvenue par chez nous !", "Hé hé, tu as l'air d'avoir faim. Tu veux un conseil ?" },
		greet_good = { "{titre} ! Mon rayon de soleil du jour !", "Ha ! Toujours aussi fringant, toi !" },
		greet_bad = { "Euh… salut. On m'a raconté des choses sur toi, tu sais…" },
		robbed = { "Quelqu'un a pioché dans mes affaires… Bah, ça doit être un pauvre bougre affamé. Hein ?" },
		saw_theft = { "Oh ! Oh non, pas ça ! Je croyais qu'on était amis !" },
		hurt = { "Mais… pourquoi ?!" },
		gift = { "Oh ! Tu es un amour ! Je vais en faire une tarte !" },
		chat = { "Ce soir je chante à la taverne ! …Enfin, s'il y avait une taverne.", "Tu connais celle du navet qui voulait devenir carotte ?" },
		gossip = { "Il paraît que {titre} fait des choses louches. Moi je n'y crois pas ! …Un peu quand même." },
		rumor = { "Oh, tu dois absolument voir {lieu} {dir} ! C'est plein de surprises !" },
		bye = { "À bientôt, l'ami !" },
	},
	anxieux = {
		greet = { "Ah ! Tu m'as fait peur… Bonjour.", "B-bonjour. Tu ne vas rien me faire, hein ?" },
		greet_good = { "Ouf, c'est toi. Avec toi dans le coin je me sens… un peu plus en sécurité." },
		greet_bad = { "N-ne t'approche pas, s'il te plaît…", "J'ai entendu des choses horribles sur toi…" },
		wanted = { "AAAH ! C'est lui ! SHÉRIF !" },
		robbed = { "On est entré chez moi ! Je ne dormirai plus jamais !" },
		missing = { "{victime} a disparu… Et si j'étais le prochain ?" },
		mourning = { "Un agresseur rôde… Je ne sors plus après la tombée de la nuit." },
		saw_theft = { "Oh non oh non oh non… Je vais le dire au shérif !" },
		hurt = { "NON ! Pitié !" },
		flee = { "Au secours !" },
		gift = { "C'est… c'est gentil. Ce n'est pas empoisonné, hein ?" },
		chat = { "Vous avez entendu ce bruit cette nuit ?", "Je suis sûr que les corbeaux me surveillent." },
		rumor = { "On dit qu'il y a {lieu} {dir}… Moi je n'irais pas, c'est sûrement dangereux." },
		bye = { "Fais attention à toi…" },
	},
	commere = {
		greet = { "Oh, te voilà ! Tu ne devineras jamais ce que j'ai entendu…", "Tiens tiens, l'étranger ! On parle beaucoup de toi, tu sais." },
		greet_good = { "Mon chou ! Tout le monde dit du bien de toi, tu sais ? Enfin, presque tout le monde." },
		greet_bad = { "Ooh, toi… J'ai tout entendu. TOUT." },
		robbed = { "On m'a volée ! Et crois-moi, je vais trouver qui. Je trouve toujours." },
		missing = { "{victime} a disparu, et moi je dis : quelqu'un sait quelque chose. Et ce quelqu'un va parler." },
		mourning = { "{victime}, assommé{e} ! Le village entier ne parle que de ça. Et toi, où étais-tu ?" },
		saw_theft = { "Ah ben bravo ! Attends que tout le village l'apprenne !" },
		gift = { "Oh, comme c'est délicat ! Je dirai à tout le monde que tu es charmant." },
		chat = { "Tu savais que le shérif ronfle ? Je le tiens de source sûre.", "Le fermier d'à côté parle à ses patates. Si si." },
		gossip = { "Psst… {titre} ? Un voleur, que je te dis. Tout le monde le sait.", "Paraît qu'on a vu {titre} rôder la nuit… brr." },
		rumor = { "Entre nous ? Il y a {lieu} {dir}. Mais tu ne le tiens pas de moi !" },
		bye = { "File, et reviens me raconter !" },
	},
	radin = {
		greet = { "Si tu viens mendier, c'est non.", "Bonjour. Ça te coûtera rien. Pour une fois." },
		greet_good = { "Ah, un client sérieux ! Ou presque." },
		greet_bad = { "Mes prix viennent d'augmenter. Pour toi." },
		robbed = { "On m'a VOLÉ ! Chaque piécette était comptée ! Je saurai qui !" },
		saw_theft = { "Voleur ! Tu sais combien ça coûte, ça ?!" },
		gift = { "Gratuit ? …C'est quoi le piège ?" },
		chat = { "Le prix des graines, c'est du vol. Enfin, sauf les miennes.", "Un sou est un sou." },
		rumor = { "Une info ? Ça se paie, normalement… Bon. {lieu}, {dir}." },
		trade = { "Tout se vend, tout s'achète. Surtout chez moi." },
		refuse = { "Même pour de l'or je ne te vends rien. …Enfin, pas pour si peu." },
		bye = { "Reviens avec plus d'argent." },
	},
	pieux = {
		greet = { "Que ta journée soit bénie.", "Le travail honnête nourrit l'âme, l'ami." },
		greet_good = { "Ta bonté se raconte jusqu'ici. Continue ainsi." },
		greet_bad = { "Je prie pour ton âme. Elle en a besoin.", "Repens-toi tant qu'il est temps." },
		wanted = { "La justice te rattrapera ! Shérif !" },
		robbed = { "Voler un honnête homme… J'espère que le coupable trouvera la paix. Et une corde." },
		mourning = { "Que {victime} se remette vite. Et que son agresseur ne dorme plus jamais." },
		saw_theft = { "Le vol est un péché ! Rends ça !" },
		hurt = { "Tu frappes un innocent ? Alors je me défendrai !" },
		fight = { "Que la justice passe par mes mains !" },
		gift = { "Ta générosité ne sera pas oubliée." },
		chat = { "Chaque graine est un petit miracle.", "La terre rend ce qu'on lui donne." },
		gossip = { "On dit que {titre} s'égare du droit chemin. Prions pour lui." },
		bye = { "Va en paix." },
	},
	filou = {
		greet = { "Psst. T'as l'air de quelqu'un qui sait se débrouiller.", "Salut. T'as rien vu, j'ai rien vu." },
		greet_good = { "Toi t'es réglo. Enfin, réglo à ma façon." },
		greet_bad = { "Hé, on a tous nos petites affaires. Moi je juge pas." },
		wanted = { "Le shérif te colle aux basques ? Ha ! Viens, on va s'arranger…" },
		robbed = { "On m'a volé ? Moi ? Respect, sincèrement." },
		saw_theft = { "Discret, hein. J'ai rien vu… si tu vois ce que je veux dire." },
		saw_assault = { "Wow. Ça, ça va faire du bruit." },
		gift = { "Un cadeau ? Je note. Je note tout." },
		chat = { "Tout a un prix. Même le silence.", "Le shérif ? Il voit que ce qu'on lui montre." },
		gossip = { "{titre} ? Bon client. C'est tout ce que je dirai." },
		rumor = { "Pour les coins discrets : {lieu}, {dir}. Personne n'y met les pieds." },
		trade = { "Je rachète tout. Sans question. À mon prix." },
		bye = { "On s'est jamais parlé." },
	},
	sherif = {
		greet = { "Bonjour. Pas de grabuge dans mon village.", "Tout va bien, étranger ? Garde ça comme ça." },
		greet_good = { "Content de te voir. Les gens disent du bien de toi." },
		greet_bad = { "Je t'ai à l'œil. Un faux pas et c'est la cellule.", "On m'a parlé de toi. Rien de bon." },
		wanted = { "Halte ! Au nom de la loi !" },
		chase = { "HALTE ! Arrête-toi !", "Tu n'iras pas loin !" },
		arrest = { "Je te tiens. Direction la cellule." },
		search = { "Où est-il passé…", "Il ne peut pas être loin." },
		robbed = { "Il y a eu des vols. J'enquête. Tu as vu quelque chose ?" },
		missing = { "{victime} a disparu. Si tu sais quelque chose, parle maintenant." },
		mourning = { "Une agression. La première depuis des années. Je trouverai le coupable." },
		body = { "Quelqu'un est à terre ! Personne ne bouge !" },
		chat = { "Rien à signaler. Comme je les aime.", "La paix, ça se mérite." },
		gossip = { "On me signale {titre}. J'ai ouvert un dossier." },
		rumor = { "Officiellement ? Il y a {lieu} {dir}. Pas de bêtises là-bas." },
		bye = { "Circule." },
	},
}

-- Émoticônes au-dessus des PNJ (jamais de texte hors boîte de dialogue)
D.EMOJI = {
	happy = "😄", smile = "🙂", love = "🥰", annoyed = "😒", angry = "😠", sad = "😢",
	scared = "😨", nervous = "😰", question = "❓", alert = "❗", heart = "❤️", sly = "😏",
	sick = "🤢", sleepy = "💤", ko = "💫", money = "💰",
}

function D.persona(p: string)
	return D.TRAITS[p] or D.TRAITS.jovial
end

function D.gender(female: boolean)
	return {
		e = female and "e" or "",
		il = female and "elle" or "il",
		Il = female and "Elle" or "Il",
		lui = female and "elle" or "lui",
	}
end

local function format(text: string, vars: { [string]: any }?): string
	if not vars then
		return text
	end
	return (text:gsub("{(%w+)}", function(k)
		local v = vars[k]
		return v ~= nil and tostring(v) or ("{" .. k .. "}")
	end))
end
D.format = format

function D.line(persona: string, key: string, vars: { [string]: any }?, rng: Random?): string
	local own = D.LINES[persona]
	local pool = (own and own[key]) or D.LINES.commun[key] or { "…" }
	local r = rng or Random.new()
	return format(pool[r:NextInteger(1, #pool)], vars)
end

-- Émoticône jouée hors dialogue pour une situation donnée, nuancée par le caractère.
function D.emote_for(persona: string, key: string): string
	if key == "greet" or key == "chat" or key == "bye" then
		local t = { bourru = "annoyed", anxieux = "nervous", filou = "sly", radin = "smile", jovial = "happy" }
		return t[persona] or "smile"
	elseif key == "greet_good" or key == "gift" then
		return (persona == "jovial" or persona == "commere") and "love" or "heart"
	elseif key == "greet_bad" or key == "refuse" or key == "trespass" then
		return (persona == "bourru" or persona == "pieux" or persona == "sherif") and "angry" or "annoyed"
	elseif key == "wanted" or key == "flee" or key == "saw_assault" or key == "saw_ko" or key == "body" then
		return (persona == "bourru" or persona == "sherif") and "angry" or "scared"
	elseif key == "saw_theft" then
		return persona == "filou" and "sly" or "alert"
	elseif key == "robbed" or key == "missing" or key == "mourning" then
		return "sad"
	elseif key == "gossip" then
		return "sly"
	elseif key == "hurt" or key == "fight" or key == "chase" then
		return "angry"
	elseif key == "curious" or key == "search" then
		return "question"
	end
	return "smile"
end

-- Salutation selon l'état du monde et la mémoire du PNJ. `consume` : la nouvelle
-- (vol, agression…) n'est racontée qu'une fois, en dialogue.
-- opinion : avis de CE PNJ sur CE joueur (les avis sont par joueur depuis le multi)
function D.greeting_key(npc, honor: number, stars: number, consume: boolean, opinion: number?): string
	if stars >= 1 then
		return "wanted"
	end
	for _, key in { "robbed", "mourning", "missing" } do
		if npc.memory[key] and not npc.memory[key .. "_told"] then
			if consume then
				npc.memory[key .. "_told"] = true
			end
			return key
		end
	end
	local score = (opinion or npc.opinion or 0) + honor / 2
	if score >= 30 then
		return "greet_good"
	elseif score <= -30 then
		return "greet_bad"
	end
	return "greet"
end

function D.title_for(honor: number): string
	if honor >= 40 then
		return "le brave"
	elseif honor <= -60 then
		return "ce gredin"
	elseif honor <= -25 then
		return "le vaurien"
	end
	return "l'étranger"
end

-- Direction vue de la carte : X vers l'est, Z vers le sud.
function D.direction_word(dx: number, dz: number): string
	local dirs = { "à l'est", "au sud-est", "au sud", "au sud-ouest", "à l'ouest", "au nord-ouest", "au nord", "au nord-est" }
	local a = math.atan2(dz, dx)
	local i = math.floor(a / (math.pi / 4) + 0.5) % 8
	return dirs[i + 1]
end

return D
