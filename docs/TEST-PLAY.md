# Wild Acres — fiche de test en Play (pour le PC fixe)

Fiche du lot C3 (20/11). Elle sert à vérifier **en jouant** ce que les bancs ne peuvent pas voir :
est-ce qu'on comprend, est-ce que ça s'affiche, est-ce que ça marche du début à la fin.

**Où noter les problèmes :** dans `retours.txt` à la racine du dépôt, une ligne par problème :

```
P2 étape 3 — le panneau de propriété ne se pose pas, message « trop près d'un village » alors que je suis loin (capture : retour1.png)
```

(numéro du parcours, étape, ce que tu as vu, et une capture si possible, posée à côté du fichier).
Claude et Codex lisent ce fichier au début de chaque session et corrigent.

---

## 0. Avant de commencer (5 min)

- [ ] Ouvrir `wildacres.rbxl` dans Studio, puis **Play**.
- [ ] Contrôle automatique : pendant la partie, dans la barre de commande de Studio, côté **Serveur**,
      coller :
      `loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34873/banc?f=regression_play"))()`
      (il faut `python tools/sync.py` lancé). Chaque ligne doit finir par **OK**. Sinon : copier le
      résultat dans `retours.txt`.
- [ ] Noter dans `retours.txt` : la date, la graine affichée (Workspace → attribut `DevSeed`, 4242 par
      défaut) et l'appareil (PC fixe).

## P1. Mains vides → outil → vente (20 min)

Le parcours d'un nouveau joueur qui ne sait rien.

1. [ ] À l'arrivée : création du personnage, fondu « Arrivée à … », HUD complet (portrait, boussole,
       météo, minicarte, colonne de menus, barre 9 cases). Rien ne déborde, rien ne cache le perso.
2. [ ] Ramasser à la main : herbe haute (clic), baies, cailloux, branches. Le butin tombe au sol et se
       ramasse (clic, [E], [Q] tout autour).
3. [ ] Ouvrir l'atelier [C] : composer une hache ou une pioche de pierre dans la grille 3×3, la
       fabriquer, la glisser dans la barre rapide, la prendre en main (touche 1-9).
4. [ ] Couper un arbre et miner un rocher : plusieurs coups, barre d'usure du nœud, graine d'arbre
       parfois. Un filon de fer **refuse** la pioche de pierre (message clair).
5. [ ] Parler à un marchand [E] → boutique : vendre du bois, acheter quelque chose. L'or change dans le
       HUD. Les prix changent-ils selon ta réputation (`/reputation`) ?
6. [ ] Ouvrir le sac [B], la fiche Personnage [P], les talents [K], les quêtes [J], la carte [M], les
       paramètres [O] : chacun s'ouvre, se ferme (Échap), et ne fait pas frapper derrière lui.

## P2. Panneau → parcelle → protection (20 min)

1. [ ] Fabriquer un panneau de propriété (4 planches + 1 corde), le poser **hors village**. Le premier
       terrain est gratuit, le deuxième payant.
2. [ ] Construire : prendre une pièce (mur, dalle, poutre) dans la barre, fantôme vert, clic = poser,
       [R] tourner, [Z] retourner, [X] reprendre. Poser un toit, une porte, une fenêtre.
3. [ ] Poser un coffre, une serrure sur la porte, une alarme. Mettre des objets dans le coffre.
4. [ ] Poser une tourelle avec des munitions.
5. [ ] Dormir dans un lit : la nuit passe seulement si tous les joueurs dorment.

## P3. Découverte → grotte → retour (20 min)

1. [ ] Partir à l'aventure sans savoir où aller : la boussole, la minicarte et le nom du lieu
       suffisent-ils ? Les lieux découverts s'ajoutent à la carte.
2. [ ] Trouver une entrée de grotte (au pied d'une falaise), y entrer, combattre (plaques au-dessus des
       créatures, « ! » avant l'attaque), miner un filon, ouvrir le coffre du fond.
3. [ ] Tirer à l'arc (flèches dans le sac) sur une créature et sur le mannequin d'entraînement.
4. [ ] Être mis K.O. une fois : que se passe-t-il, où réapparaît-on, qu'a-t-on perdu ?
5. [ ] Ressortir, rentrer au village, déposer le butin à la banque.

## P4. Accueil → voyage → reconnexion (en ligne seulement, 15 min)

La téléportation ne marche pas dans Studio : il faut la version publiée.

1. [ ] Lancer le jeu depuis roblox.com : écran d'accueil, liste des mondes, **Jouer**.
2. [ ] Au port : prendre un bateau vers un autre monde (ou « Explorer l'inconnu »).
3. [ ] Quitter le jeu au milieu d'une action (en train de fabriquer, de vendre à l'hôtel des ventes).
4. [ ] Revenir : même perso, même or, même sac, même monde, la construction est toujours là.

## P5. À deux joueurs (avec un 2e compte ou un ami)

1. [ ] On se voit, on peut former un groupe [U], s'échanger des objets [Y] (double confirmation).
2. [ ] Voler une récolte de l'autre : des étoiles apparaissent, le shérif réagit.
3. [ ] Construire ensemble sur la même parcelle, puis l'un casse un mur de l'autre à la pioche.
4. [ ] Hôtel des ventes ([F] à la boîte aux lettres) : l'un met en vente, l'autre achète.
5. [ ] Courrier : envoyer un objet à l'autre pendant qu'il est déconnecté, il le reçoit en revenant.

## P6. Nouveautés du 19/11 jamais vues en Play (à regarder en priorité)

- [ ] Herbe haute : rendu, fauche au clic, repousse le lendemain.
- [ ] Villes de joueurs : Charte de ville + `/fonder <nom>`, un habitant arrive pour chaque lit posé.
- [ ] Pont-levis et trappe (ouvrir / fermer, serrure), roue à eau qui fait tourner le moulin.
- [ ] Quêtes à un lieu (retrouver, visiter, enquêter, escorter) données par un habitant.
- [ ] Chantiers de village (marché, palissade, lanternes, musée) : contribuer, voir le résultat.
- [ ] Écurie (`/ecurie`), diligence entre villages, ouvriers agricoles (`/ouvriers`).
- [ ] Froid la nuit en montagne, chaleur au désert le jour (boire protège).
- [ ] Équipement : exigences de caractéristique affichées, panoplies, armes à venin / givre, armes de
      jet, selle et étriers.
- [ ] Livres : `/bestiaire`, `/chroniques`, `/animaux`.

## P7. Armée et performance (10 min)

1. [ ] Avec 3 soldats ou plus (caserne sur ta parcelle) : `/armee suivre` (ils se rangent en colonne
       derrière toi), `/armee tenir` (en ligne devant toi), `/armee patrouiller`, puis `/armee attaquer`
       face à une bête. Un soldat à plus de 60 studs ne doit PAS obéir.
2. [ ] En admin : `/wa or` après avoir vendu et acheté au marchand (les deux doivent apparaître), `/wa etat` (serveur, mémoire, dernière sauvegarde, erreurs, mondes en ligne) et
       `/wa perf` au village de départ, puis au milieu d'un grand village et pendant un combat. Noter les
       chiffres dans `retours.txt` (boucle en ms/image, mémoire en Mo).
3. [ ] Ouvrir la carte [M] la première fois : combien de temps avant qu'elle s'affiche ?
4. [ ] Traverser l'île à cheval au galop : des trous dans le sol, des régions qui arrivent en retard ?

## P8. Demandes, bugs, appel (5 min)

1. [ ] `/bug Je teste le signalement de bug` → message « 🐞 Bug n°… reçue ».
2. [ ] En admin : `/wa demandes bug` montre ta demande avec la position et le monde ; `/wa repondre <n°> Merci`
       → la réponse s'affiche. Refaire en se déconnectant avant la réponse : elle arrive à la reconnexion.
3. [ ] Avec un 2e compte : `/wa bannir <pseudo> 1 test` → il est expulsé avec le message d'appel ; en revenant,
       il arrive sur l'accueil, ne peut pas entrer dans un monde, et `/appel …` marche. `/wa debannir <userId>`.

## Ce qu'il faut aussi noter (même si « ça marche »)

- Ce que tu n'as **pas compris** tout seul (sans tutoriel, il faut que le monde le fasse comprendre).
- Ce qui est **trop long / trop court** à obtenir (grind trop dur ou trop facile).
- Les **chutes d'images** (où, quand) et les messages rouges de la console (Affichage → Sortie).
