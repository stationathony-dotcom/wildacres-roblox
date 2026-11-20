# Wild Acres — procédures d'exploitation (18/11/2026)

Étapes 22 et 24 du plan. Tout repose sur des outils qui existent déjà dans le code.

## 1. Déployer une mise à jour sans casser les mondes existants
1. **Générateur du monde** : ne jamais modifier le tirage d'une version publiée. Un changement de
   génération = nouvelle valeur `WG.CURRENT_GEN` (aujourd'hui 2) ; chaque monde garde la version
   avec laquelle il a été créé (`Gen` du registre). Les anciens mondes ne bougent pas.
2. **Ajouts au monde** (châteaux, bosquets, plantes, champs, quais…) : toujours « par-dessus » la
   génération, avec leur propre graine (`WG.hash(seed, "<nom>", rx, rz)`) et des identifiants à part
   (`bq…`, `hb…`). Ne jamais insérer de tirage au milieu d'un tirage existant (ex. : nouveaux bâtiments
   de village ajoutés EN DERNIER dans `Villages.BUILDINGS`).
3. **Sauvegardes du perso** : un nouveau champ facultatif s'ajoute à `Save.FIELDS` (absent = valeur
   par défaut). Un changement de FORMAT = migration dans `Save.MIGRATIONS` (ne jamais modifier une
   migration publiée).
4. **Avant publication** : lancer les bancs Edit (`tools/bancs/*.luau`, cf. README), régénérer
   `docs/REFERENCE.md` (banc `reference`), vérifier l'empreinte des PNJ (banc `pnj_looks`), puis une
   partie en Play.
5. **Publier** : annoncer (`/wa annonce`), sauvegarder (`/wa sauver`), fermer proprement les serveurs
   (`/wa ferme <raison>` : chacun est sauvegardé avant l'expulsion), publier, vérifier un monde ancien.
6. **Retour arrière** : republier la version précédente depuis l'historique Roblox ; les sauvegardes
   écrites par la nouvelle version restent lisibles si la règle 3 a été suivie.

## 2. Réagir à un exploit, une faille ou un comportement dangereux
1. **Couper tout de suite** l'action exploitée sur tous les serveurs : `/wa coupe <action> <raison>`
   (≤ 1 min) — l'action répond « Indisponible (maintenance) ». `/wa rallume <action>` après correctif.
2. **Mesurer** : `/wa journal` (registre : gains d'or anormaux, échanges, ventes, sanctions),
   `/wa joueur <pseudo>`, `/wa perf`.
3. **Corriger les comptes touchés** après preuve : `/wa versions <userId>` puis
   `/wa restaurer <userId> <version>` (version d'avant l'abus), ou `/wa donner` pour rendre un objet perdu.
4. **Sanctionner graduellement** les abuseurs : `/wa avertir` → `/wa muet <min>` → `/wa expulser`
   → `/wa bannir <jours>` (tout est noté au registre).
5. **Corriger le code**, ajouter un banc qui reproduit l'exploit, noter la faille dans `AUDIT.md` et
   `CHANGELOG.md`.

## 3. Signalements des joueurs
- Un joueur tape `/signaler <pseudo> <motif>` : noté au registre (« signalement »), admins présents
  prévenus. `/bloquer <pseudo>` coupe invitations, échanges, courrier et annonces de ce joueur.
- Traitement : un admin lit `/wa journal`, regarde `/wa joueur`, sanctionne si besoin (section 2.4).

## 4. Demandes, bugs et appel d'une sanction (décidé le 20/11 : dans le jeu)
- Le joueur écrit `/demande <texte>`, `/bug <texte>` ou `/appel <texte>` (3 par jour). Pour un bug, la position,
  le biome, le monde, le jour et le serveur sont joints tout seuls. Les admins présents sont prévenus.
- Un **banni** ne peut entrer dans aucun monde, mais il peut rester sur l'écran d'accueil (muet pour les autres)
  et y taper `/appel`. Le bannissement n'est plus celui de Roblox (qui fermait toute porte) : `Systemes/Demandes`.
- Traitement : `/wa demandes [bug|appel|demande]` (les 8 plus récentes ouvertes), `/wa repondre <n°> <texte>`
  (réponse tout de suite, ou à la prochaine connexion du joueur, sur n'importe quel serveur), `/wa clore <n°>`.
- Sanction injustifiée : `/wa debannir <userId>` ; avertissement → remettre `warnings` à zéro (restauration ou
  correction admin) ; répondre à l'appel pour le dire au joueur.
