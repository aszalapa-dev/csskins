# Journal de bord — mission autonome du 17 novembre 2026

Décisions prises seul, problèmes rencontrés et résultats des vérifications.

## Décisions

- **Emplacement** : le dépôt contenait déjà un site web (`index.html`, `api/`, `js/`…). Je n'y ai pas
  touché. Le projet Roblox est à la racine (`default.project.json`, `src/`, `tests/`, `build/`) pour
  que `rojo build` marche directement comme demandé. Seul `.gitignore` a reçu trois lignes en plus.
- **Concept** : « Snowpal Rollers » (voir DESIGN.md). Pas de mécanique de vol entre joueurs
  (frustrante pour les plus jeunes) et aucune physique fragile, puisque rien ne pouvait être testé.
- **Pas de vente de chance** : la chance ne s'achète qu'avec des flocons. Aucun produit en Robux ne
  touche au tirage, pour rester loin de tout « objet aléatoire payant ». Les chances sont affichées.
- **Équipe automatique** : les meilleurs Snowpals s'exposent seuls. Pas d'inventaire à gérer sur
  téléphone.
- **Langue** : interface en français (textes dans le code et dans Config). La traduction automatique
  de Roblox pourra être activée ensuite.
- **Sons** : j'ai mis des sons intégrés au client Roblox (`rbxasset://sounds/...`) plutôt que des IDs
  de bibliothèque que je ne pouvais pas écouter ni vérifier. **À vérifier dans Studio** et à remplacer
  par des `rbxassetid://` dans `Config.Sons` (un son vide `""` est simplement ignoré).
- **Données temporaires** : seulement dans Studio. Sur un vrai serveur, si le DataStore ne répond
  pas, le joueur est renvoyé avec un message au lieu de jouer sur des données vides.
- **Réglages du projet** : `StreamingEnabled = false` (petite map, plus simple et plus sûr),
  orientation paysage forcée sur téléphone, éclairage « Future ».
- **Spawn** : chaque terrain a son point d'apparition (`RespawnLocation`), plus un spawn central de
  secours sur la place.
- **Commits** : j'ai développé les phases A à G d'un bloc puis relu l'ensemble, donc il y a un commit
  par grande étape (base + tests, jeu complet, relecture, documentation) plutôt qu'un par phase.

## Outils

| Outil | Résultat |
|-------|----------|
| Rojo 7.6.1 | installé, `rojo build` OK |
| Luau (CLI) | installé, exécute les tests |
| StyLua 2.3.0 | installé, tout le code est formaté |
| Selene 0.29.0 | installé, **mais** `selene generate-roblox-std` a échoué 2 fois (certificat du proxy refusé). J'ai lancé selene avec une bibliothèque minimale de secours (`tests/selene_secours.yml`) : 0 erreur, 0 avertissement. Le `selene.toml` du dépôt utilise bien `std = "roblox"` : **relancer `selene src` sur ton PC** pour la vérification complète des API. |
| luau-analyze | ne connaît pas les types Roblox. J'ai utilisé `luau-lsp analyze` (même moteur, avec les définitions Roblox) en mode strict : 0 erreur sur tout `src/`. |

`./verifier.sh` relance tout (build, types, lint, format, tests, simulation).

## Résultats des vérifications

- `rojo build -o build/jeu.rbxl` : OK.
- Analyse de types stricte : 0 erreur. Selene (bibliothèque de secours) : 0 erreur. StyLua : conforme.
- Tests en Luau pur : 24 réussis sur 24 (formules, tirage, rebirth, quêtes, récompenses, migration).
- Simulation d'équilibrage : 1er Snowpal 0:21, 1re amélioration 0:42, zone 2 à 15:54, zone 3 à 34:06,
  1er rebirth à 1:22:16, 2e à 1:48:07. Le premier jet tombait déjà dans la cible ; j'ai seulement
  monté le prix du rebirth de 2,5 M à 3,2 M pour viser 1 h 30 avec un joueur réel.

## Bugs trouvés en relisant (corrigés)

- Une panne de DataStore en production aurait donné des données vides au joueur : désormais renvoi.
- La tirelire se vidait 4 fois par seconde en restant sur l'atelier (quête « vide ta tirelire »
  triviale, effets en rafale) : elle ne se vide plus qu'en entrant sur l'atelier.
- `TailleMax` (réglage interne) était recopié comme propriété de TextLabel : erreur au premier texte.
- Boucles serveur qui parcouraient la liste des joueurs pendant des appels web : copie d'abord.
- Interface trop large en mode portrait ; boule mal posée au sol pour les avatars R6 ; personnage
  tourné dos à la neige en apparaissant.

## Ce qui n'a PAS pu être vérifié

Rien n'a tourné dans Roblox. Tout ce qui est visuel, sonore ou lié aux services Roblox reste à
confirmer dans Studio : voir la section « Points incertains » du README.
