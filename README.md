# Snowpal Rollers ❄️

*Roule ta boule, collectionne tes bonshommes !* — un jeu Roblox complet écrit en projet Rojo,
sans Roblox Studio. **Rien n'a encore été testé en jeu** : suis la checklist ci-dessous.

> Ce dépôt contient aussi un site web (`index.html`, `api/`, `js/`…) qui n'a pas été modifié.
> Tout le jeu Roblox est dans `default.project.json`, `src/`, `tests/` et `build/`.

## Le jeu

Fais rouler une boule de neige qui grossit sous tes pas, ramène-la à ton atelier : elle se
transforme en flocons… et en **Snowpal**, un bonhomme de neige à collectionner qui travaille pour toi.

- Boucle de 20 à 45 s : rouler → livrer → révélation d'un Snowpal (6 raretés).
- 24 Snowpals × normal/doré, 3 zones, 5 améliorations, rebirth « Nouvel Hiver », classement mondial.
- Récompenses quotidiennes, cadeaux de temps de jeu, 3 quêtes par jour, badges, tutoriel.
- Bonus d'amis, annonces serveur, feux d'artifice visibles par tous, tempête de neige toutes les 8 min.

**Tendances suivies** (détail et sources dans [DESIGN.md](DESIGN.md)) : jeux de collection de
créatures sur une base personnelle, jeux « idle » à croissance, simulateurs à un seul geste, saison
d'hiver, public majoritairement sur téléphone.

## Ouvrir le jeu

```bash
git pull
rojo build -o jeu.rbxl      # puis ouvrir jeu.rbxl dans Roblox Studio
```

- Ou ouvrir directement **`build/jeu.rbxl`** (déjà construit).
- Ou, pour modifier le code en direct : `rojo serve`, puis dans Studio le plugin Rojo → *Connect*.

La map n'est pas dans le fichier : elle est construite par le serveur quand on appuie sur **Play**.

## Checklist, dans l'ordre

### 1. Tester dans Studio (Play, puis « Test → Démarrer » avec 2 joueurs)

À regarder en priorité :
1. **Fenêtre Sortie** : aucune erreur rouge. Tu dois lire `[Snowpal Rollers] Serveur prêt.`
2. **La map** apparaît (île, sapin, 8 terrains) et tu apparais sur ton terrain, face à la neige.
3. **La boucle** : cours dans la neige → une boule roule devant toi et la jauge monte → reviens sur
   le disque bleu « ATELIER » → flocons, carte du Snowpal, bonhomme posé sur un socle.
4. **Les 5 boutons du bas** s'ouvrent et les achats marchent (Améliorer surtout).
5. **Émulateur d'appareil** (un téléphone en paysage) : rien ne déborde, les boutons ne gênent ni le
   joystick ni le bouton de saut.
6. **Les sons** se jouent (clic, livraison, rare).

Commandes de test (dans le chat, Studio uniquement) : `/flocons 100000`, `/pal roi_givre`,
`/boule 5`, `/zone 3`, `/tempete`, `/passe VIP`, `/boost Flocons`, `/jour`, `/reset`.

### 2. Publier l'emplacement et activer l'accès API

Fichier → *Publier sur Roblox* (en privé pour l'instant). Puis Paramètres du jeu → Sécurité →
**Activer l'accès de Studio aux services API**. Relance Play : la sortie doit dire
`Données persistantes`. Joue, quitte, relance : ta progression doit être revenue.

### 3. Créer les gamepasses (Tableau de bord créateur → Monétisation → Passes)

| Clé dans Config | Nom | Description | Prix |
|---|---|---|---|
| `DoubleFlocons` | Flocons x2 | Double tous tes gains de flocons, pour toujours. | 199 R$ |
| `RouleurPro` | Rouleur Pro | Ta boule de neige grossit 50 % plus vite. | 149 R$ |
| `CollecteAuto` | Collecte Auto | Les flocons de tes Snowpals arrivent tout seuls. | 99 R$ |
| `SoclesBonus` | Grand Terrain | +2 socles pour exposer plus de Snowpals. | 129 R$ |
| `VIP` | VIP Givré | +20 % de flocons, récompenses quotidiennes x2, étiquette VIP. | 249 R$ |

### 4. Créer les produits développeur (Monétisation → Produits développeur)

| Clé dans Config | Nom | Description | Prix |
|---|---|---|---|
| `BoostFlocons` | Boost Flocons x2 | x2 flocons pendant 15 minutes. | 29 R$ |
| `BoostCroissance` | Boost Boule x2 | Ta boule grossit 2x plus vite pendant 15 minutes. | 29 R$ |
| `PetitSac` | Petit sac de flocons | Un sac de flocons adapté à ta progression. | 49 R$ |
| `GrosSac` | Gros sac de flocons | Un énorme sac de flocons adapté à ta progression. | 149 R$ |

### 5. Créer les badges (Engagement → Badges)

| Clé dans Config | Nom | Description |
|---|---|---|
| `Bienvenue` | Bienvenue au village ! | Tu as rejoint Snowpal Rollers. |
| `PremierSnowpal` | Premier Snowpal | Tu as créé ton premier bonhomme. |
| `PremierDore` | Touche dorée | Tu as fusionné un Snowpal doré. |
| `Legendaire` | Légende des neiges | Tu as obtenu un Snowpal Légendaire. |
| `Mythique` | Mythe vivant | Tu as obtenu un Snowpal Mythique. |
| `NouvelHiver` | Nouvel Hiver | Tu as fait ton premier rebirth. |
| `Collectionneur` | Collectionneur | Tu as découvert la moitié de l'Index. |

### 6. Coller les IDs

Ouvre **`src/shared/Config.luau`** et remplace `Id = 0` :
- gamepasses → table `Config.Gamepasses` (une entrée par clé ci-dessus) ;
- produits → table `Config.Produits` ;
- badges → table `Config.Badges`.

Un ID laissé à 0 affiche « Bientôt » (ou ignore le badge) sans erreur. Puis `rojo build -o jeu.rbxl`
(ou `rojo serve`), et **teste un achat dans Studio** (les achats de test sont gratuits) : le boost
doit s'afficher en haut, le sac doit créditer les flocons une seule fois.

### 7. Réglages du jeu

- **Joueurs max : 8** (il y a 8 terrains ; pour changer, modifier `Config.JoueursMax`).
- **Genre** : Simulation (sous-genre collection / incrémental).
- **Appareils** : Ordinateur, Téléphone, Tablette, Console.
- **Questionnaire de maturité** : aucune violence, sang, peur, langage grossier ni contenu
  romantique ; **pas d'objets aléatoires payants** (les tirages sont gratuits, obtenus en jouant, et
  les chances sont affichées dans l'Index) ; pas de jeux d'argent ; pas de liens externes.
  Résultat attendu : contenu « Minimal » / tous publics.
- Paramètres → Avatar : R15 conseillé (R6 est géré mais non testé).

### 8. Icône et miniatures (3 idées précises)

1. **Icône** : un enfant en doudoune rouge pousse une énorme boule de neige, vu de face, bouche
   ouverte de joie ; derrière lui un bonhomme de neige à couronne dorée qui brille. Fond bleu ciel uni.
2. **Miniature « collection »** : un terrain rempli de Snowpals alignés du plus commun au
   Mythique arc-en-ciel, avec la flèche « ??? » sur le dernier socle vide et le texte « 48 À TROUVER ! ».
3. **Miniature « avant / après »** : à gauche une minuscule boule et le texte « 0:00 », à droite une
   boule plus grande que le joueur sous l'aurore violette et le texte « 1 HEURE PLUS TARD ».

### 9. Page du jeu

**Titre** : `Snowpal Rollers ❄️ [NOUVEAU]`

**Description** :
```
❄️ Fais rouler ta boule de neige, plus elle est grosse, mieux c'est !
⛄ Ramène-la à ton atelier pour créer un SNOWPAL : 24 bonshommes à collectionner, du Commun au MYTHIQUE
★ Fusionne-les en version DORÉE
🗺️ Débloque le Bois Cristal et le Pic Aurore
⭐ Recommence un Nouvel Hiver pour devenir encore plus fort
👫 Joue avec tes amis : jusqu'à +30 % de flocons !
🎁 Cadeaux gratuits tous les jours

Mets un 👍 et ajoute le jeu en favori pour ne pas rater les mises à jour !
```

### 10. Publier

Relis la sortie une dernière fois, passe l'emplacement en **Public**, et joue une partie complète
depuis un téléphone avant d'en parler.

## Points incertains à vérifier en priorité

1. **Disques du sol** : l'île est faite de grands cylindres (jusqu'à 380 studs de rayon). Leur bord
   peut paraître anguleux et décalé de quelques studs par rapport à la limite réelle des zones.
2. **Petites marches** entre les anneaux (0,15 stud) et vers les terrains (0,3 stud) : vérifier
   qu'on ne bute pas dessus.
3. **Position de la boule** devant le personnage (hauteur au sol, distance), en R15 et en R6.
4. **Lisibilité sur téléphone** : taille des textes dans l'Index et la Boutique, emojis des boutons.
5. **Sons** : ce sont des sons intégrés (`rbxasset://`) choisis sans pouvoir les écouter. S'ils ne
   conviennent pas, changer `Config.Sons`.
6. **Brouillard et luminosité** (`reglerEclairage` dans `ConstructeurMap.luau`) : réglés à l'aveugle.
7. **Bonus d'amis** : utilise `Player:IsFriendsWithAsync`. Si la sortie montre une erreur à ce
   sujet, remplacer par `IsFriendsWith` dans `ServiceSocial.luau`.
8. **Commandes de debug** : elles écoutent `Player.Chatted` ; si elles ne réagissent pas avec le
   nouveau chat, utiliser la console serveur.
9. **Verrou de session** : changer de serveur très vite peut faire attendre le chargement jusqu'à
   ~16 s. À tester avec deux serveurs une fois le jeu publié.
10. **Selene** : relancer `selene src` sur ton PC (ici la bibliothèque Roblox complète n'a pas pu
    être téléchargée, voir [JOURNAL.md](JOURNAL.md)).

## Vérifications faites sans Studio

`./verifier.sh` : build Rojo OK, analyse de types stricte 0 erreur, lint 0 erreur, 24 tests réussis,
simulation d'équilibrage dans la cible (1er Snowpal à 0:21, rebirth à 1 h 22 en jeu parfait).

## Bugs connus et limites

- Si plus de 8 joueurs entrent (mauvais réglage « joueurs max »), deux joueurs partagent un terrain.
- La boule est un effet local : deux joueurs peuvent la voir à des positions légèrement différentes.
- Les quêtes sont les mêmes pour tout le monde un jour donné (voulu, mais peu varié : 9 quêtes).
- Pas de musique (`Config.Sons.Musique` est vide).
- Les prix affichés dans la boutique viennent de Roblox ; sans réponse, le bouton dit juste « Acheter ».

## Idées de mises à jour

- **Décembre — « La Nuit des Cadeaux »** : des cadeaux tombent du ciel dans les zones, 4 Snowpals de
  Noël à durée limitée (renne, lutin, pain d'épices, étoile filante), sapin de la place qui grandit
  avec le total de boules livrées par tout le serveur.
- **Janvier — zone 4 « Palais de Glace »** avec toboggans, plus un classement hebdomadaire.
- **Février — Snowpals « Cœur givré »** et échange de Snowpals entre amis (avec confirmation).
- **Printemps — « Le Grand Dégel »** : les Snowpals deviennent des versions fleuries ; même boucle,
  nouveau décor, pour que le jeu survive à l'hiver.
- Animaux de compagnie qui suivent le joueur, courses de boules de neige à plusieurs, codes cadeaux.
