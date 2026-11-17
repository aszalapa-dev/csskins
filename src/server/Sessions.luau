--!strict
--[[
	Sessions.luau — l'état en mémoire de chaque joueur connecté (données + état de jeu), et les
	fonctions communes à tous les services : multiplicateur, gain de flocons, envoi de l'état au client.
	Le client ne reçoit qu'une COPIE (instantané) : il ne peut rien modifier.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formules = require(ReplicatedStorage.Shared.Formules)
local ModeleDonnees = require(ReplicatedStorage.Shared.ModeleDonnees)
local Recompenses = require(ReplicatedStorage.Shared.Recompenses)
local Reseau = require(script.Parent.Reseau)

export type Boule = { Taille: number, ParZone: { number } }

export type Session = {
	Joueur: Player,
	Donnees: ModeleDonnees.Donnees,
	Terrain: number, -- numéro du terrain attribué (1..8)
	Boule: Boule?,
	DernierePosition: Vector3?,
	SurAtelier: boolean, -- le joueur était sur son atelier au tick précédent
	Passes: { [string]: boolean },
	Amis: number, -- nombre d'amis présents sur le serveur
	Sale: boolean, -- l'état doit être renvoyé au client
	SignatureEquipe: string, -- pour savoir quand reconstruire les Snowpals du terrain
	DernierAvis: { [string]: number }, -- anti-spam des notifications répétées
	DerniereSauvegarde: number,
}

local Sessions = {}

local sessions: { [Player]: Session } = {}

function Sessions.creer(joueur: Player, donnees: ModeleDonnees.Donnees, terrain: number): Session
	local session: Session = {
		Joueur = joueur,
		Donnees = donnees,
		Terrain = terrain,
		Boule = nil,
		DernierePosition = nil,
		SurAtelier = false,
		Passes = {},
		Amis = 0,
		Sale = true,
		SignatureEquipe = "",
		DernierAvis = {},
		DerniereSauvegarde = os.clock(),
	}
	sessions[joueur] = session
	return session
end

function Sessions.obtenir(joueur: Player): Session?
	return sessions[joueur]
end

function Sessions.retirer(joueur: Player)
	sessions[joueur] = nil
end

function Sessions.toutes(): { [Player]: Session }
	return sessions
end

-- ───────────── Calculs dérivés ─────────────

function Sessions.boostActif(session: Session, nom: string): boolean
	local expiration = session.Donnees.Boosts[nom]
	return expiration ~= nil and expiration > os.time()
end

function Sessions.contexte(session: Session): Formules.Contexte
	return {
		Rebirths = session.Donnees.Rebirths,
		EntreesIndex = Formules.entreesIndex(session.Donnees.Index),
		Amis = session.Amis,
		DoubleFlocons = session.Passes.DoubleFlocons == true,
		VIP = session.Passes.VIP == true,
		BoostFlocons = Sessions.boostActif(session, "Flocons"),
	}
end

function Sessions.multiplicateur(session: Session): number
	return Formules.multiplicateurFlocons(Sessions.contexte(session))
end

function Sessions.socles(session: Session): number
	return Formules.socles(session.Donnees.Ameliorations.Socles or 0, session.Passes.SoclesBonus == true)
end

function Sessions.equipe(session: Session): { Formules.MembreEquipe }
	return Formules.equipe(session.Donnees.Snowpals, Sessions.socles(session))
end

-- ───────────── Modifications ─────────────

-- Ajoute des flocons (montant FINAL, multiplicateurs déjà appliqués par l'appelant).
function Sessions.ajouterFlocons(session: Session, montant: number)
	if montant ~= montant or montant <= 0 then
		return
	end
	local donnees = session.Donnees
	donnees.Flocons = math.min(donnees.Flocons + montant, 1e18)
	donnees.FloconsTotal = math.min(donnees.FloconsTotal + montant, 1e18)
	session.Sale = true
end

-- Retire des flocons si le joueur en a assez. Renvoie true si le paiement est fait.
function Sessions.payer(session: Session, prix: number): boolean
	if prix ~= prix or prix < 0 or session.Donnees.Flocons < prix then
		return false
	end
	session.Donnees.Flocons -= prix
	session.Sale = true
	return true
end

-- Prolonge un boost (les durées s'empilent, avec un plafond).
function Sessions.ajouterBoost(session: Session, nom: string, duree: number)
	local maintenant = os.time()
	local actuel = session.Donnees.Boosts[nom]
	local depart = if actuel ~= nil and actuel > maintenant then actuel else maintenant
	session.Donnees.Boosts[nom] = math.min(depart + duree, maintenant + Config.DureeBoostMax)
	session.Sale = true
end

-- Applique une récompense standard { Flocons, BoostFlocons, BoostCroissance } et renvoie les flocons donnés.
function Sessions.donnerRecompense(session: Session, recompense: { [string]: number }, facteur: number): number
	local flocons = math.floor((recompense.Flocons or 0) * facteur)
	Sessions.ajouterFlocons(session, flocons)
	if recompense.BoostFlocons then
		Sessions.ajouterBoost(session, "Flocons", recompense.BoostFlocons)
	end
	if recompense.BoostCroissance then
		Sessions.ajouterBoost(session, "Croissance", recompense.BoostCroissance)
	end
	return flocons
end

-- Avance les quêtes d'un type donné.
function Sessions.progresserQuete(session: Session, typeQuete: string, montant: number)
	if Recompenses.progresser(session.Donnees.Quetes.Liste, typeQuete, montant) then
		session.Sale = true
	end
end

-- Notification répétitive (ex. « zone verrouillée ») : au plus une toutes les `delai` secondes.
function Sessions.aviser(session: Session, cle: string, delai: number, texte: string, genre: Reseau.GenreNotification?)
	local maintenant = os.clock()
	local dernier = session.DernierAvis[cle]
	if dernier ~= nil and maintenant - dernier < delai then
		return
	end
	session.DernierAvis[cle] = maintenant
	Reseau.notifier(session.Joueur, texte, genre)
end

-- ───────────── Instantané envoyé au client ─────────────

function Sessions.instantane(session: Session): { [string]: any }
	local donnees = session.Donnees
	local maintenant = os.time()
	local multiplicateur = Sessions.multiplicateur(session)
	local equipe = Sessions.equipe(session)
	local revenu = Formules.revenuEquipe(equipe)
	local quotidienDispo, quotidienJour =
		Recompenses.etatQuotidien(donnees.Quotidien, Recompenses.numeroJour(maintenant))
	local boosts = {}
	for nom, expiration in donnees.Boosts do
		if expiration > maintenant then
			boosts[nom] = expiration - maintenant -- secondes restantes
		end
	end
	return {
		Flocons = donnees.Flocons,
		FloconsTotal = donnees.FloconsTotal,
		Rebirths = donnees.Rebirths,
		Ameliorations = donnees.Ameliorations,
		ZoneMax = donnees.ZoneMax,
		Snowpals = donnees.Snowpals,
		Index = donnees.Index,
		Reserve = donnees.Reserve,
		ReserveMax = Formules.reserveMax(revenu, multiplicateur),
		Revenu = revenu * multiplicateur,
		Multiplicateur = multiplicateur,
		Echelle = Formules.echelleRecompense(donnees),
		Socles = Sessions.socles(session),
		Equipe = equipe,
		Quotidien = { Disponible = quotidienDispo, Jour = quotidienJour },
		Cadeaux = { Secondes = donnees.Cadeaux.Secondes, Reclames = donnees.Cadeaux.Reclames },
		Quetes = donnees.Quetes.Liste,
		Tutoriel = donnees.Tutoriel,
		Boosts = boosts,
		Passes = session.Passes,
		Amis = session.Amis,
		Terrain = session.Terrain,
		Stats = donnees.Stats,
	}
end

-- Met à jour le classement intégré de Roblox (leaderstats)
local function majLeaderstats(session: Session)
	local stats = session.Joueur:FindFirstChild("leaderstats")
	if stats == nil then
		return
	end
	local flocons = stats:FindFirstChild("Flocons")
	if flocons ~= nil and flocons:IsA("NumberValue") then
		flocons.Value = math.floor(session.Donnees.Flocons)
	end
	local hivers = stats:FindFirstChild("Hivers")
	if hivers ~= nil and hivers:IsA("IntValue") then
		hivers.Value = session.Donnees.Rebirths
	end
end

function Sessions.creerLeaderstats(joueur: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local flocons = Instance.new("NumberValue")
	flocons.Name = "Flocons"
	flocons.Parent = stats
	local hivers = Instance.new("IntValue")
	hivers.Name = "Hivers"
	hivers.Parent = stats
	stats.Parent = joueur
end

-- Envoie immédiatement l'état au client
function Sessions.envoyer(session: Session)
	session.Sale = false
	majLeaderstats(session)
	Reseau.envoyerEtat(session.Joueur, Sessions.instantane(session))
end

-- Boucle légère : envoie l'état des joueurs « sales » au plus ~3 fois par seconde.
function Sessions.demarrer()
	task.spawn(function()
		while true do
			task.wait(0.35)
			for joueur, session in sessions do
				if session.Sale and joueur.Parent == Players then
					Sessions.envoyer(session)
				end
			end
		end
	end)
end

return Sessions
