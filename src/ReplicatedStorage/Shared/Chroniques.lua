-- Chroniques des îles (19/11, « Secrets et découvertes » de « à ne pas oublier.txt ») : des récits
-- anciens éparpillés en PAGES. On trouve des « pages anciennes » en fouillant, en minant, lors des
-- événements ou dans les trésors ; en lire une révèle une page qu'on ne connaissait pas. Rien ne dit
-- où chercher ni dans quel ordre : on reconstitue les histoires au hasard des trouvailles.
-- Une chronique complète rapporte un secret (carte au trésor) et un objet ancien (Systemes/Chroniques).
-- Récits originaux du monde de Wild Acres.

local C = {}

C.LIST = {
	{
		id = "naufrage", titre = "Le naufrage de l'Hirondelle", recompense = "ancient_jewel",
		pages = {
			"Nous étions quarante à bord de l'Hirondelle, partis des terres du sud avec des graines, des outils et l'espoir d'une île où personne ne nous dirait quoi semer.",
			"La tempête dura trois nuits. Le mât se brisa la deuxième. À l'aube, il ne restait que la coque échouée sur une plage de sable blanc, et dix-neuf d'entre nous.",
			"Nous avons bâti les premières huttes avec les planches du navire. La cloche de bord sert encore aujourd'hui à appeler le village au marché.",
			"On dit qu'à marée basse, par temps clair, on voit encore la quille de l'Hirondelle sous l'eau. Le capitaine y aurait caché le coffre des semences rares.",
		},
	},
	{
		id = "roi_mycelien", titre = "Le Roi des champignons", recompense = "relic",
		pages = {
			"Avant les villages, la forêt appartenait aux spores. Les anciens parlent d'un esprit fait de racines blanches qui reliait chaque arbre à tous les autres.",
			"Le premier bûcheron qui abattit un chêne centenaire sentit la terre trembler sous ses pieds. Le lendemain, des champignons poussaient en cercle autour de sa maison.",
			"Les herboristes apprirent à lui parler : on ne prend jamais le dernier champignon d'un cercle, et l'on replante un gland pour chaque arbre tombé.",
			"Quand les hommes oublient ces règles, il se lève. On l'appelle le Roi Mycélien. Il ne hait personne : il rend simplement à la forêt ce qu'on lui a pris.",
		},
	},
	{
		id = "colosse", titre = "Le Colosse de verre", recompense = "ancient_crystal",
		pages = {
			"Dans le désert, un peuple de souffleurs de verre vivait de sable et de feu. Leurs fours brûlaient jour et nuit au pied des dunes rouges.",
			"Leur maître verrier voulut un gardien que nulle lame ne pourrait blesser. Il fondit mille sacs de sable sous la foudre d'un orage et en tira un géant transparent.",
			"Le géant protégea la cité pendant cent ans. Puis les fours s'éteignirent, les souffleurs partirent, et le colosse resta seul à garder des ruines vides.",
			"Il marche encore les nuits de tempête de sable. Ceux qui l'ont vu racontent qu'au centre de sa poitrine brille un cristal ancien, le cœur du dernier four.",
		},
	},
	{
		id = "dormeur", titre = "Le Dormeur des glaces", recompense = "ancient_scale",
		pages = {
			"Au nord, les chasseurs de phoques gravaient des signes sur la glace pour ne pas réveiller ce qui dort dessous.",
			"Un hiver sans fin vint pourtant. Les chasseurs crurent qu'un des leurs avait brisé un signe, et le bannirent sur la banquise.",
			"Le banni marcha jusqu'au cœur du glacier et y trouva une bête immense, endormie, couverte d'écailles bleues. Il se coucha contre elle pour avoir chaud.",
			"Au printemps, la glace fondit et le banni revint, vivant. Il ne dit jamais ce qu'il avait vu. Il portait autour du cou une écaille bleue qui ne fondait pas.",
		},
	},
	{
		id = "brigands", titre = "La bande du Corbeau", recompense = "royal_seal",
		pages = {
			"Le Corbeau n'était pas né brigand. Il était collecteur d'impôts pour un seigneur qui taxait jusqu'au pain des enfants.",
			"Un soir, il garda la recette au lieu de la porter au château et la rendit aux familles, sou par sou. Le lendemain, sa tête était mise à prix.",
			"Il prit la forêt avec quelques fidèles. Ils volaient les convois du seigneur et laissaient toujours une plume noire sur les coffres vides.",
			"Le seigneur mourut sans héritier. Le Corbeau ne revint jamais. On dit que son dernier butin dort encore sous un arbre marqué d'une plume gravée.",
		},
	},
	{
		id = "moisson", titre = "Le Gardien des moissons", recompense = "festival_prize",
		pages = {
			"Chaque automne, les fermiers bâtissaient un épouvantail plus grand que les autres et le couronnaient d'épis : le Gardien des moissons.",
			"Une année, la fête fut oubliée. Les récoltes furent maigres et une silhouette de paille fut aperçue, la nuit, marchant entre les champs.",
			"Les anciens comprirent : on ne l'avait pas fêté, alors il venait chercher sa part. On lui laissa du pain et de la bière au bout des sillons.",
			"Depuis, quand quelqu'un traite mal la terre, le Gardien revient. Il n'est ni bon ni mauvais : il veille sur ce qui pousse, et sur ceux qui le font pousser.",
		},
	},
}

C.BY_ID = {}
C.TOTAL = 0
for _, s in C.LIST do
	C.BY_ID[s.id] = s
	C.TOTAL += #s.pages
end

return C
