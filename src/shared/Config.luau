--!strict
--[[
	Config.luau — TOUS les réglages du jeu « Snowpal Rollers ».
	Rien d'autre que des données ici : ce module est aussi chargé par les tests en Luau pur,
	il ne doit donc utiliser AUCUNE API Roblox (pas de Color3, pas d'Instance...).
	Les couleurs sont des tables {R, G, B} (0-255) converties par les modules Roblox.
]]

local Config = {}

-- ───────────────────────────── Général ─────────────────────────────
Config.NomJeu = "Snowpal Rollers"
Config.SousTitre = "Roule ta boule, collectionne tes bonshommes !"
Config.JoueursMax = 8 -- doit correspondre au réglage « joueurs max » du jeu (8 terrains dans la map)

-- ───────────────────────────── Données ─────────────────────────────
Config.Donnees = {
	NomDataStore = "SnowpalRollers_Donnees_v1", -- changer le suffixe = repartir de zéro
	NomClassement = "SnowpalRollers_Classement_v1",
	Version = 2, -- version du format de données (voir ModeleDonnees.migrer)
	IntervalleSauvegarde = 60, -- secondes
	Tentatives = 3, -- nombre de nouvelles tentatives après un échec
	DelaiTentative = 2, -- secondes entre deux tentatives
	DureeVerrou = 180, -- secondes avant qu'un verrou de session soit considéré comme abandonné
	AchatsMemorises = 60, -- nombre de reçus d'achat gardés pour l'idempotence
}

-- ───────────────────────────── Boule de neige ─────────────────────────────
Config.Boule = {
	TailleDepart = 1, -- diamètre (studs) d'une boule toute neuve
	TailleMinLivraison = 1.6, -- en dessous, l'atelier refuse la boule
	TailleMaxBase = 3, -- diamètre max sans amélioration
	TailleMaxParNiveau = 0.5, -- + par niveau de « Gants »
	CroissanceParStud = 0.011, -- diamètre gagné par stud parcouru (niveau 0 de « Pelle »)
	CroissanceParNiveau = 0.14, -- +14 % par niveau de « Pelle »
	ValeurBase = 2.2, -- flocons = ValeurBase × taille ^ ExposantValeur × multiplicateurs
	ExposantValeur = 2,
	IntervalleTick = 0.25, -- secondes entre deux mises à jour serveur
	MargeVitesse = 1.6, -- tolérance anti-triche sur la distance parcourue par tick
	ChanceParTaille = 0.12, -- + chance par stud de diamètre au-delà de la taille de départ
}

Config.Deplacement = {
	VitesseBase = 16,
	VitesseParNiveau = 1, -- + par niveau de « Bottes »
}

-- ───────────────────────────── Zones (anneaux autour du village) ─────────────────────────────
-- Une zone est un anneau : RayonMin <= distance au centre < RayonMax.
Config.RayonVillage = 105
Config.Zones = {
	{
		Id = 1,
		Nom = "Prairie Givrée",
		RayonMin = 105,
		RayonMax = 200,
		Multiplicateur = 1,
		Prix = 0,
		CouleurSol = { 235, 245, 255 },
		CouleurAccent = { 120, 200, 255 },
	},
	{
		Id = 2,
		Nom = "Bois Cristal",
		RayonMin = 200,
		RayonMax = 290,
		Multiplicateur = 4,
		Prix = 6000,
		CouleurSol = { 205, 240, 235 },
		CouleurAccent = { 80, 220, 190 },
	},
	{
		Id = 3,
		Nom = "Pic Aurore",
		RayonMin = 290,
		RayonMax = 380,
		Multiplicateur = 15,
		Prix = 150000,
		CouleurSol = { 228, 215, 255 },
		CouleurAccent = { 190, 110, 255 },
	},
}
Config.RayonIle = 380

-- ───────────────────────────── Raretés ─────────────────────────────
-- Probabilite = chance de base (somme = 1). Revenu = flocons/s en zone 1 (× multiplicateur de zone).
Config.Raretes = {
	{ Id = "Commun", Nom = "Commun", Probabilite = 0.60, Revenu = 1, Couleur = { 200, 205, 215 } },
	{ Id = "PeuCommun", Nom = "Peu commun", Probabilite = 0.25, Revenu = 3, Couleur = { 90, 210, 110 } },
	{ Id = "Rare", Nom = "Rare", Probabilite = 0.10, Revenu = 8, Couleur = { 70, 150, 255 } },
	{ Id = "Epique", Nom = "Épique", Probabilite = 0.04, Revenu = 25, Couleur = { 180, 90, 255 } },
	{ Id = "Legendaire", Nom = "Légendaire", Probabilite = 0.009, Revenu = 90, Couleur = { 255, 190, 40 } },
	{ Id = "Mythique", Nom = "Mythique", Probabilite = 0.001, Revenu = 400, Couleur = { 255, 80, 140 } },
}
Config.PlafondChanceNonCommun = 0.97 -- part maximale des raretés non communes après bonus de chance
Config.RareteAnnonce = 5 -- à partir de ce rang (Légendaire), annonce à tout le serveur
Config.RareteSpectacle = 4 -- à partir de ce rang (Épique), gros effet visuel

Config.Dore = {
	CoutFusion = 5, -- nombre d'exemplaires normaux pour créer un doré
	MultiplicateurRevenu = 4,
}

-- ───────────────────────────── Snowpals (revenus passifs) ─────────────────────────────
Config.Equipe = {
	SoclesBase = 3,
	SoclesMax = 10, -- hors gamepass
	SoclesGamepass = 2, -- socles bonus du gamepass
	ReserveMaxSecondes = 900, -- la tirelire du terrain stocke au plus 15 min de revenus
	HorsLigneMaxSecondes = 7200, -- revenus hors ligne plafonnés à 2 h
	HorsLigneRendement = 0.25, -- 25 % du revenu normal pendant l'absence
	IntervalleRevenu = 1, -- secondes
}

-- ───────────────────────────── Améliorations ─────────────────────────────
-- Prix du niveau n (en partant de 0) = PrixBase × Croissance ^ n
Config.Ameliorations = {
	Gants = {
		Nom = "Gants",
		Description = "Boule de neige plus grosse",
		Icone = "🧤",
		PrixBase = 25,
		Croissance = 1.45,
		NiveauMax = 30,
	},
	Pelle = {
		Nom = "Pelle",
		Description = "La boule grossit plus vite",
		Icone = "⛏️",
		PrixBase = 40,
		Croissance = 1.5,
		NiveauMax = 25,
	},
	Bottes = {
		Nom = "Bottes",
		Description = "Tu cours plus vite",
		Icone = "🥾",
		PrixBase = 60,
		Croissance = 1.75,
		NiveauMax = 14,
	},
	Chance = {
		Nom = "Trèfle givré",
		Description = "Plus de chance d'avoir des Snowpals rares",
		Icone = "🍀",
		PrixBase = 150,
		Croissance = 1.6,
		NiveauMax = 20,
		BonusParNiveau = 0.1, -- +10 % de chance par niveau
	},
	Socles = {
		Nom = "Socles",
		Description = "Un Snowpal de plus sur ton terrain",
		Icone = "🏠",
		PrixBase = 300,
		Croissance = 4.2,
		NiveauMax = 7, -- SoclesBase + 7 = SoclesMax
	},
}
Config.OrdreAmeliorations = { "Gants", "Pelle", "Bottes", "Chance", "Socles" }

-- ───────────────────────────── Rebirth (« Nouvel Hiver ») ─────────────────────────────
Config.Rebirth = {
	PrixBase = 3200000,
	Croissance = 3.5, -- prix × 3,5 à chaque rebirth
	BonusParRebirth = 0.5, -- +50 % de flocons par rebirth
	Max = 50,
}
Config.BonusIndexParEntree = 0.01 -- +1 % de flocons par entrée découverte dans l'Index

-- ───────────────────────────── Social ─────────────────────────────
Config.Social = {
	BonusParAmi = 0.1, -- +10 % de flocons par ami présent sur le serveur
	BonusAmisMax = 0.3,
	IntervalleVerifAmis = 60,
}

-- Événement serveur régulier, visible par tous
Config.Tempete = {
	Intervalle = 480, -- une tempête toutes les 8 min
	Duree = 60,
	MultiplicateurCroissance = 2,
}

-- ───────────────────────────── Récompenses quotidiennes (7 jours) ─────────────────────────────
-- Flocons = base × multiplicateur de progression du joueur (voir Formules.echelleRecompense)
Config.Quotidien = {
	{ Flocons = 100 },
	{ Flocons = 200 },
	{ Flocons = 350, BoostFlocons = 300 },
	{ Flocons = 500 },
	{ Flocons = 750, BoostCroissance = 300 },
	{ Flocons = 1000 },
	{ Flocons = 2000, BoostFlocons = 900, BoostCroissance = 900 },
}

-- ───────────────────────────── Cadeaux de temps de jeu (par jour) ─────────────────────────────
Config.Cadeaux = {
	{ Minutes = 2, Flocons = 60 },
	{ Minutes = 5, Flocons = 150 },
	{ Minutes = 10, Flocons = 300, BoostCroissance = 180 },
	{ Minutes = 15, Flocons = 500 },
	{ Minutes = 25, Flocons = 900, BoostFlocons = 300 },
	{ Minutes = 40, Flocons = 1500 },
}

-- ───────────────────────────── Quêtes quotidiennes ─────────────────────────────
-- 3 quêtes tirées chaque jour (une par « Groupe »). Type = compteur suivi par le serveur.
Config.Quetes = {
	{ Id = "Boules10", Groupe = 1, Type = "Boules", Objectif = 10, Texte = "Livre 10 boules de neige", Flocons = 150 },
	{ Id = "Boules25", Groupe = 1, Type = "Boules", Objectif = 25, Texte = "Livre 25 boules de neige", Flocons = 320 },
	{ Id = "Geante3", Groupe = 1, Type = "BoulesMax", Objectif = 3, Texte = "Livre 3 boules à taille maximale", Flocons = 200 },
	{ Id = "Snowpals8", Groupe = 2, Type = "Snowpals", Objectif = 8, Texte = "Obtiens 8 Snowpals", Flocons = 180 },
	{ Id = "Rares2", Groupe = 2, Type = "Rares", Objectif = 2, Texte = "Obtiens 2 Snowpals Rares ou mieux", Flocons = 300 },
	{ Id = "Fusion1", Groupe = 2, Type = "Fusions", Objectif = 1, Texte = "Crée 1 Snowpal doré", Flocons = 350 },
	{ Id = "Temps10", Groupe = 3, Type = "Minutes", Objectif = 10, Texte = "Joue 10 minutes", Flocons = 200 },
	{ Id = "Ameliore3", Groupe = 3, Type = "Ameliorations", Objectif = 3, Texte = "Achète 3 améliorations", Flocons = 180 },
	{ Id = "Collecte5", Groupe = 3, Type = "Collectes", Objectif = 5, Texte = "Vide ta tirelire 5 fois", Flocons = 160 },
}
Config.NombreGroupesQuetes = 3

-- ───────────────────────────── Monétisation (IDs à 0 = « Bientôt ») ─────────────────────────────
Config.Gamepasses = {
	DoubleFlocons = {
		Id = 0,
		Nom = "Flocons x2",
		Description = "Double TOUS tes gains de flocons, pour toujours.",
		Icone = "❄️",
		PrixSuggere = 199,
	},
	RouleurPro = {
		Id = 0,
		Nom = "Rouleur Pro",
		Description = "Ta boule grossit 50 % plus vite.",
		Icone = "⚡",
		PrixSuggere = 149,
	},
	CollecteAuto = {
		Id = 0,
		Nom = "Collecte Auto",
		Description = "Les flocons de tes Snowpals arrivent tout seuls, sans passer par la tirelire.",
		Icone = "🤖",
		PrixSuggere = 99,
	},
	SoclesBonus = {
		Id = 0,
		Nom = "Grand Terrain",
		Description = "+2 socles pour exposer plus de Snowpals.",
		Icone = "🏰",
		PrixSuggere = 129,
	},
	VIP = {
		Id = 0,
		Nom = "VIP Givré",
		Description = "+20 % de flocons, récompenses quotidiennes x2 et étiquette VIP dorée.",
		Icone = "👑",
		PrixSuggere = 249,
	},
}
Config.OrdreGamepasses = { "DoubleFlocons", "RouleurPro", "CollecteAuto", "SoclesBonus", "VIP" }
Config.MultiplicateurRouleurPro = 1.5
Config.BonusVIP = 0.2

-- Produits développeur. Type "Boost" : Duree en secondes. Type "Flocons" : Secondes de revenu offertes
-- (proportionnel à la progression, voir Formules.floconsPaquet), avec un minimum garanti.
Config.Produits = {
	BoostFlocons = {
		Id = 0,
		Nom = "Boost Flocons x2",
		Description = "x2 flocons pendant 15 minutes.",
		Icone = "💎",
		Type = "Boost",
		Boost = "Flocons",
		Duree = 900,
		PrixSuggere = 29,
	},
	BoostCroissance = {
		Id = 0,
		Nom = "Boost Boule x2",
		Description = "Ta boule grossit 2x plus vite pendant 15 minutes.",
		Icone = "🌨️",
		Type = "Boost",
		Boost = "Croissance",
		Duree = 900,
		PrixSuggere = 29,
	},
	PetitSac = {
		Id = 0,
		Nom = "Petit sac de flocons",
		Description = "Un sac de flocons adapté à ta progression.",
		Icone = "🎒",
		Type = "Flocons",
		Secondes = 900,
		Minimum = 2500,
		PrixSuggere = 49,
	},
	GrosSac = {
		Id = 0,
		Nom = "Gros sac de flocons",
		Description = "Un énorme sac de flocons adapté à ta progression.",
		Icone = "🛷",
		Type = "Flocons",
		Secondes = 3600,
		Minimum = 12000,
		PrixSuggere = 149,
	},
}
Config.OrdreProduits = { "BoostFlocons", "BoostCroissance", "PetitSac", "GrosSac" }
Config.MultiplicateurBoost = 2
Config.DureeBoostMax = 6 * 3600 -- on ne peut pas empiler plus de 6 h de boost
Config.IntervalleRappelBoutique = 300 -- au maximum un rappel doux toutes les 5 min

-- ───────────────────────────── Badges (IDs à 0 = ignorés sans erreur) ─────────────────────────────
Config.Badges = {
	Bienvenue = { Id = 0, Nom = "Bienvenue au village !", Description = "Tu as rejoint Snowpal Rollers." },
	PremierSnowpal = { Id = 0, Nom = "Premier Snowpal", Description = "Tu as créé ton premier bonhomme." },
	PremierDore = { Id = 0, Nom = "Touche dorée", Description = "Tu as fusionné un Snowpal doré." },
	Legendaire = { Id = 0, Nom = "Légende des neiges", Description = "Tu as obtenu un Snowpal Légendaire." },
	Mythique = { Id = 0, Nom = "Mythe vivant", Description = "Tu as obtenu un Snowpal Mythique." },
	NouvelHiver = { Id = 0, Nom = "Nouvel Hiver", Description = "Tu as fait ton premier rebirth." },
	Collectionneur = { Id = 0, Nom = "Collectionneur", Description = "Tu as découvert la moitié de l'Index." },
}

-- ───────────────────────────── Sécurité : limites de débit des Remotes ─────────────────────────────
-- { Max = nombre d'appels autorisés, Fenetre = par fenêtre de X secondes }
Config.Debit = {
	Defaut = { Max = 8, Fenetre = 2 },
	AcheterAmelioration = { Max = 12, Fenetre = 2 },
	DemanderEtat = { Max = 2, Fenetre = 5 },
	Rebirth = { Max = 2, Fenetre = 5 },
}

-- ───────────────────────────── Classement ─────────────────────────────
Config.Classement = {
	Taille = 10,
	IntervalleRafraichissement = 120,
}

-- ───────────────────────────── Sons ─────────────────────────────
-- Sons intégrés au client Roblox (rbxasset://) : ils marchent sans rien téléverser.
-- À REMPLACER par des « rbxassetid://123 » de la bibliothèque Roblox pour un meilleur rendu.
Config.Sons = {
	Clic = "rbxasset://sounds/clickfast.wav",
	Achat = "rbxasset://sounds/electronicpingshort.wav",
	Livraison = "rbxasset://sounds/snap.mp3",
	Rare = "rbxasset://sounds/victory.wav",
	Erreur = "rbxasset://sounds/uuhhh.mp3",
	Collecte = "rbxasset://sounds/electronicpingshort.wav",
	Notification = "rbxasset://sounds/switch.wav",
	Musique = "", -- ex. "rbxassetid://..." (vide = pas de musique)
}
Config.VolumeSons = 0.5

-- ───────────────────────────── Couleurs de l'interface ─────────────────────────────
Config.Couleurs = {
	Fond = { 24, 38, 66 },
	Panneau = { 36, 56, 96 },
	PanneauClair = { 54, 82, 136 },
	Texte = { 255, 255, 255 },
	TexteDoux = { 190, 210, 240 },
	Principal = { 70, 170, 255 },
	Succes = { 80, 210, 120 },
	Attention = { 255, 190, 40 },
	Danger = { 240, 90, 90 },
	Dore = { 255, 205, 60 },
	Grise = { 110, 120, 140 },
}

-- ───────────────────────────── Tutoriel ─────────────────────────────
Config.Tutoriel = {
	"Bienvenue ! Cours dans la neige au-delà du village : une boule de neige roule devant toi et grossit.",
	"Quand elle est assez grosse, ramène-la sur l'ATELIER bleu de ton terrain.",
	"Ta boule devient des flocons ❄️ ET un Snowpal qui travaille pour toi !",
	"Achète des améliorations, complète l'Index et deviens le roi de l'hiver !",
}

return Config
