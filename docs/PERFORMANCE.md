# Wild Acres — performance (lot C12 côté serveur, X23 côté client)

Mesures en **Edit** sur le PC portable (banc `tools/bancs/perf_serveur.luau`) ; les mesures en **Play** se font
sur le PC fixe avec `docs/TEST-PLAY.md` § P7 (`/wa perf`, `/wa etat`) et vont dans `retours.txt`.

## Budgets serveur (40 joueurs)

| Poste | Budget | Mesuré (21/11, Edit, portable) | Note |
|---|---|---|---|
| Boucle de jeu (`/wa perf`, somme des `step`) | ≤ 4 ms / image | à mesurer en Play | chaque système est chronométré (moyenne glissante) |
| Plan d'une région (génération) | ≤ 150 ms au total | moyenne 66–117 ms, max 92–234 ms | varie selon la charge du portable |
| Plus long bloc sans céder la main pendant un chargement de région | ≤ 60 ms | **~19 ms par étape** (55 ms au tout premier plan du serveur : réseau de routes) | avant le 21/11 : tout le plan d'un bloc → saccade à chaque région traversée |
| Recherche d'une falaise à cascade | ≤ 8 ms / région | 0,8–4,6 ms | une fois par chargement |
| Comptage des bêtes d'un joueur (quête troupeau) | ≤ 2 ms | 0,05 ms pour 1 200 bêtes | toutes les 3 s au plus |

## Ce qui a été fait

- **21/11 — pauses du calcul de plan** (`RegionPlan` : `WG.pauseHook`, posé par `World.init`) : le plan d'une
  région cède la main entre ses étapes et toutes les 12–14 lignes dans les deux boucles lourdes (lieux / eau
  brute, distances eau / terre). Seulement dans la tâche de chargement de `World` (`planThread`) : un système qui
  demande un plan pendant sa boucle n'est jamais suspendu. Les tirages ne changent pas (mêmes mondes).

## À mesurer en Play (propriétaire, PC fixe)

1. `/wa perf` au départ, au milieu d'un grand village, pendant un combat, en traversant l'île au galop.
2. `/wa etat` : mémoire du serveur, dernière sauvegarde.
3. Deux joueurs ou plus : nombre de régions chargées (`World.loaded`) et temps d'arrivée des régions au galop.
4. Côté client (Codex, X23) : premier affichage de la carte, aperçus 3D, images par seconde au village.

## Côté client (Codex, X23)

_À compléter par Codex._
