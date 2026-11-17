# Snowpal Rollers — Game Design Document

> **Snowpal Rollers** — *Roule ta boule, collectionne tes bonshommes !*

## 1. Tendances (novembre 2026)

Recherche faite le 17 novembre 2026. Les chiffres viennent de résumés de recherche web : plusieurs
sites n'étaient pas ouvrables depuis l'environnement de travail, et les classements bougent chaque
jour. À revérifier sur la page « Top Playing Now » de Roblox avant la sortie.

| # | Tendance | Ce qu'on en retient pour le jeu |
|---|----------|---------------------------------|
| 1 | **Les jeux « collectionne des créatures qui rapportent sur ta base »** dominent : *Steal An Egg* était n°1 fin octobre (~713 K joueurs simultanés), après *Steal a Brainrot*. | Un terrain personnel où s'exposent des créatures à raretés, visibles par les autres joueurs. On garde la collection, on enlève le vol (frustrant pour les plus jeunes). |
| 2 | **Les jeux « idle » à croissance** tiennent dans la durée : *Grow a Garden 2* ~454 K en septembre. | Revenus passifs, tirelire à vider, gains hors ligne, retour quotidien. |
| 3 | **Les simulateurs « un seul verbe »** percent vite (*Sell Lemons*, *Kick a Lucky Block*, *Fish It*) : compréhensibles en 10 secondes, parfaits pour les vidéos courtes. | Un seul geste : **rouler**. Aucun bouton à apprendre, idéal sur téléphone. |
| 4 | **La saison d'hiver fait grimper l'activité** : événement officiel *Winter Spotlight*, mises à jour de Noël des gros jeux (Adopt Me, Dress to Impress), nouveaux jeux à thème hiver sortis dès l'automne. | Thème hiver/neige natif (pas un simple habillage), prêt pour décembre. |
| 5 | **Plateforme** (RDC 2026, septembre) : classement de découverte ajusté selon la tranche d'âge, jeux jouables hors de l'app Roblox (apps autonomes, navigateur), et toujours une majorité de joueurs sur mobile. | Jeu tout public très lisible, interface pensée téléphone d'abord, sessions courtes. |

Sources :
- [StudioKrew — classement RoWatcher du 29 oct. 2026](https://studiokrew.com/blog/?p=2072)
- [GGRecon — les 10 nouveaux jeux Roblox qui grandissent le plus vite (nov. 2026)](https://www.ggrecon.com/articles/fastest-growing-new-roblox-games-november-2026/)
- [Everything Edinburgh — Best Roblox Games in 2026](https://everythingedinburgh.com/games/gaming/best-roblox-games/)
- [RoWatcher — jeux les plus joués en direct](https://rowatcher.com/news/the-most-popular-roblox-games-right-now-ranked-by-live-players)
- [Gamezebo — Roblox Winter Spotlight](https://www.gamezebo.com/walkthroughs/roblox-winter-spotlight/)
- [Vice — expériences d'hiver à durée limitée](https://www.vice.com/en/article/roblox-is-adding-a-whole-suite-of-limited-time-winter-themed-games-and-experiences/)
- [games.gg — tendances Roblox de décembre 2025](https://games.gg/news/roblox-top-games-and-trends-december-2025/)
- [Roblox Newsroom — RDC 2026](https://about.roblox.com/newsroom/2026/09/rdc-2026-the-world-needs-more-play)
- [PocketGamer.biz — nouveautés RDC 2026](https://www.pocketgamer.biz/roblox-unveils-new-play-creation-and-monetisation-tools-at-rdc-2026/)

## 2. Trois concepts et leur note

| Critère (sur 10) | A. **Snowpal Rollers** — rouler une boule de neige qui devient un bonhomme à collectionner | B. **Sled Stack** — dévaler une piste en luge en empilant des cadeaux | C. **Igloo Bakery** — tenir une pâtisserie de Noël (tycoon de service) |
|---|---|---|---|
| Attrait enfants | 9 | 8 | 7 |
| Compréhensible en 10 s | 9 | 8 | 6 |
| Rejouabilité | 8 | 6 | 7 |
| Robux honnêtes | 8 | 6 | 8 |
| Faisabilité (code seul, sans Studio) | 9 | 5 (physique de luge impossible à régler sans tester) | 6 (beaucoup d'interface et d'IA de clients) |
| Viralité | 8 | 8 | 5 |
| **Total / 60** | **51** | 41 | 39 |

**Choix : A.** Il combine les tendances 1 à 4, ne dépend d'aucune physique fragile (important puisque
rien n'a pu être testé en jeu), et la map se décrit entièrement en blocs.

## 3. Pitch

> Fais rouler une boule de neige qui grossit sous tes pas, ramène-la à ton atelier : elle se transforme
> en flocons… et en **Snowpal**, un bonhomme de neige à collectionner qui travaille pour toi.

## 4. Boucle de jeu

**Boucle courte (20 à 45 s)**
1. Sortir du village : une boule de neige apparaît devant soi et **grossit avec la distance parcourue**.
2. Quand la jauge est pleine, un rayon lumineux guide vers l'**atelier** de son terrain.
3. Marcher sur l'atelier : la boule est vendue (flocons ❄️) et un **Snowpal** est tiré au sort
   (rareté selon la taille de la boule et la chance). Révélation, effets, annonce si c'est rare.
4. Les meilleurs Snowpals s'exposent tout seuls sur les socles du terrain et rapportent des flocons
   par seconde dans la **tirelire**, vidée en repassant par l'atelier.

**Objectifs longs** : compléter l'**Index** (24 Snowpals × normal/doré = 48 entrées, +1 % de flocons
par entrée), fusionner 5 exemplaires en **doré** (revenu ×4), débloquer les 3 zones, faire des
**Nouveaux Hivers** (rebirth : +50 % de flocons chacun), grimper au **classement mondial**.

## 5. Progression de 0 à 2 h (simulation `tests/simulation.luau`)

| Temps | Étape |
|-------|-------|
| 0:20 | Premier Snowpal |
| 0:40 | Première amélioration (Gants) |
| ~9 min | Premier Snowpal doré |
| ~15 min | Premier Légendaire, puis zone 2 « Bois Cristal » (flocons ×4) à ~16 min |
| ~34 min | Zone 3 « Pic Aurore » (flocons ×15) |
| ~1 h 22 | Premier Nouvel Hiver (rebirth), toutes les améliorations au maximum |
| ~1 h 48 | Deuxième Nouvel Hiver |

La simulation joue « parfaitement » (aucune pause longue) : un vrai joueur mettra plutôt 1 h 30 à 2 h.

## 6. Économie

- **Monnaie unique : les flocons ❄️.** Sources : vente de la boule (`2,2 × taille² × zone`), revenus
  passifs des Snowpals, récompenses (quotidien, cadeaux, quêtes), gains hors ligne (25 %, 2 h max).
- **Dépenses** : 5 améliorations (Gants = taille max, Pelle = vitesse de croissance, Bottes = vitesse
  de course, Trèfle givré = chance, Socles = Snowpals exposés), 2 zones, rebirth.
- **Multiplicateur de flocons** = rebirths × Index × amis présents × passes × boost.
- **Raretés** (chances de base, affichées dans l'Index) : Commun 60 %, Peu commun 25 %, Rare 10 %,
  Épique 4 %, Légendaire 0,9 %, Mythique 0,1 %. La chance multiplie les raretés non communes.
- Tous les chiffres sont dans `src/shared/Config.luau`, toutes les formules dans `Formules.luau`.

## 7. Monétisation (honnête)

- **5 gamepasses** : Flocons x2, Rouleur Pro (boule +50 % plus rapide), Collecte Auto, Grand Terrain
  (+2 socles), VIP Givré (+20 %, quotidien x2, étiquette).
- **4 produits** : Boost Flocons x2 (15 min), Boost Boule x2 (15 min), Petit et Gros sac de flocons
  (proportionnels à la progression du joueur).
- **Aucun tirage payant** : on ne vend ni chance ni Snowpal aléatoire. Les Robux achètent du temps
  (boosts, flocons), jamais un résultat au hasard.
- Rappels : une astuce discrète toutes les 5 min au maximum, et seulement si un article est en vente.
- Un ID à 0 affiche « Bientôt » : le jeu fonctionne entièrement sans aucun article configuré.

## 8. Direction artistique

Blocs et sphères aux couleurs vives, île ronde sous un ciel d'hiver clair : place centrale avec un
sapin géant illuminé, 8 terrains pastel en cercle, puis trois anneaux de neige de plus en plus
féeriques (sapins enneigés → cristaux turquoise → piliers d'aurore violets et rubans lumineux dans le
ciel), ceinturés de montagnes. Les Snowpals sont trois boules empilées avec écharpe et chapeau ; les
rares brillent (néon, lumière, étincelles). Interface arrondie, gros boutons, police ronde.

## 9. Architecture

```
default.project.json      Arbre Rojo (Remotes déclarés ici)
src/shared/               ReplicatedStorage.Shared — logique PURE, testée sans Roblox
  Config.luau             tous les réglages
  Catalogue.luau          les 24 Snowpals
  Formules.luau           économie, tirage, rebirth, formatage
  ModeleDonnees.luau      forme des données, valeurs par défaut, migration
  Recompenses.luau        quotidien, cadeaux, quêtes
src/server/               ServerScriptService.Serveur (init.server.luau + modules)
  ConstructeurMap         toute la map + éclairage, déterministe
  ConstructeurSnowpal     modèle 3D d'un Snowpal
  Reseau                  Remotes + limite de débit
  Sessions                état en mémoire des joueurs, instantané envoyé au client
  ServiceDonnees          DataStore : pcall, tentatives, verrou de session, mode temporaire (Studio)
  ServiceBoule            boucle principale (4 ticks/s) : croissance, livraison, tirage
  ServiceTerrains         terrains, socles, tirelire
  ServiceProgression      améliorations, zones, fusion, rebirth
  ServiceRecompenses      quotidien, cadeaux, quêtes, hors ligne, tutoriel
  ServiceBoutique         gamepasses, produits, ProcessReceipt
  ServiceSocial           bonus d'amis, tempête de neige
  ServiceClassement       OrderedDataStore -> panneau de la place
  Badges                  badges (ID 0 = ignoré)
src/client/               StarterPlayerScripts.Client (init.client.luau + modules)
  Etat, Interface, HUD, Menus, Notifications, Effets, Tutoriel
tests/                    tests en Luau pur + simulation d'équilibrage
```

**Principe de sécurité** : le client n'envoie que des *demandes* par un seul RemoteEvent (`Action`),
limité en débit par action. La boule grossit d'après la position du personnage lue par le serveur,
avec un plafond de distance par tick. Le client ne reçoit qu'une copie de l'état.
