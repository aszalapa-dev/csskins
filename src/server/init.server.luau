--!strict
--[[
	Serveur — point d'entrée du jeu « Snowpal Rollers ».
	Ordre de démarrage : map -> services -> joueurs. Voir DESIGN.md pour l'architecture.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalogue = require(ReplicatedStorage.Shared.Catalogue)

local ConstructeurMap = require(script.ConstructeurMap)
local Reseau = require(script.Reseau)
local ServiceBoule = require(script.ServiceBoule)
local ServiceBoutique = require(script.ServiceBoutique)
local ServiceClassement = require(script.ServiceClassement)
local ServiceDonnees = require(script.ServiceDonnees)
local ServiceProgression = require(script.ServiceProgression)
local ServiceRecompenses = require(script.ServiceRecompenses)
local ServiceSocial = require(script.ServiceSocial)
local ServiceTerrains = require(script.ServiceTerrains)
local Sessions = require(script.Sessions)

-- 1) La map (construite par code si Workspace.Map n'existe pas)
local map = ConstructeurMap.construire()

-- 2) Les services
ServiceTerrains.initialiser(map)
ServiceProgression.initialiser()
ServiceRecompenses.initialiser()
ServiceBoutique.initialiser()
Sessions.demarrer()
ServiceBoule.demarrer()
ServiceSocial.demarrer()
ServiceClassement.demarrer(map)

-- ───────────────────────────── Arrivée / départ des joueurs ─────────────────────────────

local enFermeture = false

local function surArrivee(joueur: Player)
	Sessions.creerLeaderstats(joueur)
	local numero = ServiceTerrains.reserver(joueur) -- synchrone : le point d'apparition est réglé tout de suite

	local donnees, raison = ServiceDonnees.charger(joueur.UserId) -- peut attendre (DataStore)
	if joueur.Parent ~= Players then
		-- Le joueur est parti pendant le chargement : on libère le verrou sans rien modifier
		if donnees ~= nil then
			ServiceDonnees.sauvegarder(joueur.UserId, donnees, true)
		end
		ServiceTerrains.liberer(joueur, numero)
		return
	end
	if donnees == nil then
		ServiceTerrains.liberer(joueur, numero)
		joueur:Kick(
			`Impossible de charger ta sauvegarde ({raison}). Tes données sont en sécurité : réessaie dans un instant !`
		)
		return
	end

	local session = Sessions.creer(joueur, donnees, numero)
	ServiceRecompenses.initialiserSession(session)
	ServiceBoutique.chargerPasses(session)
	ServiceTerrains.rafraichir(session)

	local function surPersonnage(personnage: Model)
		session.DernierePosition = nil
		ServiceProgression.equiperPersonnage(session, personnage)
	end
	joueur.CharacterAdded:Connect(surPersonnage)
	if joueur.Character then
		task.spawn(surPersonnage, joueur.Character)
	end

	Sessions.envoyer(session)
	task.spawn(ServiceSocial.majAmis)
end

-- Sauvegarde finale + libération du terrain. Idempotent (PlayerRemoving ET BindToClose peuvent l'appeler).
local function fermerSession(joueur: Player)
	local session = Sessions.obtenir(joueur)
	if session == nil then
		return
	end
	Sessions.retirer(joueur)
	ServiceTerrains.liberer(joueur, session.Terrain)
	ServiceDonnees.sauvegarder(joueur.UserId, session.Donnees, true)
end

Players.PlayerAdded:Connect(surArrivee)
for _, joueur in Players:GetPlayers() do
	task.spawn(surArrivee, joueur) -- joueurs arrivés avant la fin du démarrage
end

Players.PlayerRemoving:Connect(function(joueur)
	fermerSession(joueur)
	if not enFermeture then
		task.spawn(ServiceSocial.majAmis)
	end
end)

game:BindToClose(function()
	enFermeture = true
	local restants = 0
	for joueur in Sessions.toutes() do
		restants += 1
		task.spawn(function()
			fermerSession(joueur)
			restants -= 1
		end)
	end
	local debut = os.clock()
	while restants > 0 and os.clock() - debut < 25 do
		task.wait(0.1)
	end
end)

-- ───────────────────────────── Horloge : une seule boucle par seconde ─────────────────────────────

task.spawn(function()
	while true do
		task.wait(Config.Equipe.IntervalleRevenu)
		for joueur, session in Sessions.toutes() do
			if joueur.Parent == Players then
				local ok, erreur = pcall(function()
					ServiceTerrains.chaqueSeconde(session)
					ServiceRecompenses.chaqueSeconde(session)
				end)
				if not ok then
					warn(`[Horloge] {erreur}`)
				end
				-- Sauvegarde automatique (décalée entre joueurs car basée sur l'heure d'arrivée)
				if os.clock() - session.DerniereSauvegarde >= Config.Donnees.IntervalleSauvegarde then
					session.DerniereSauvegarde = os.clock()
					task.spawn(ServiceDonnees.sauvegarder, joueur.UserId, session.Donnees, false)
				end
			end
		end
	end
end)

-- ───────────────────────────── Commandes de debug (Studio uniquement) ─────────────────────────────

if RunService:IsStudio() then
	local function surMessage(joueur: Player, message: string)
		local session = Sessions.obtenir(joueur)
		if session == nil then
			return
		end
		local mots = string.split(message, " ")
		local commande = string.lower(mots[1] or "")
		if commande == "/flocons" then
			Sessions.ajouterFlocons(session, tonumber(mots[2]) or 1000)
		elseif commande == "/pal" then
			local id = mots[2] or "flocon"
			if Catalogue.ParId[id] then
				local exemplaires = session.Donnees.Snowpals[id] or { N = 0, D = 0 }
				exemplaires.N += tonumber(mots[3]) or 1
				session.Donnees.Snowpals[id] = exemplaires
				session.Donnees.Index[id] = true
				ServiceTerrains.rafraichir(session)
			end
		elseif commande == "/boule" then
			session.Boule = { Taille = tonumber(mots[2]) or 3, ParZone = { 1, 0, 0 } }
		elseif commande == "/zone" then
			session.Donnees.ZoneMax = math.clamp(tonumber(mots[2]) or 1, 1, #Config.Zones)
		elseif commande == "/tempete" then
			ServiceSocial.lancerTempete()
		elseif commande == "/passe" then
			if mots[2] and (Config.Gamepasses :: { [string]: any })[mots[2]] then
				ServiceBoutique.activerPasse(session, mots[2])
			end
		elseif commande == "/boost" then
			Sessions.ajouterBoost(session, mots[2] or "Flocons", 60)
		elseif commande == "/jour" then
			-- simule un nouveau jour pour tester récompenses quotidiennes, cadeaux et quêtes
			session.Donnees.Quotidien.DernierJour -= 1
			session.Donnees.Cadeaux.Jour = 0
			session.Donnees.Quetes.Jour = 0
		elseif commande == "/reset" then
			local neuf = require(ReplicatedStorage.Shared.ModeleDonnees).defaut()
			session.Donnees = neuf
			ServiceTerrains.rafraichir(session)
			ServiceProgression.appliquerVitesse(session)
		else
			return
		end
		session.Sale = true
		Reseau.notifier(joueur, `[debug] {message}`, "Info")
	end
	local function brancher(joueur: Player)
		joueur.Chatted:Connect(function(message)
			surMessage(joueur, message)
		end)
	end
	Players.PlayerAdded:Connect(brancher)
	for _, joueur in Players:GetPlayers() do
		brancher(joueur)
	end
	print(
		"[Snowpal Rollers] Commandes de debug : /flocons N, /pal id [n], /boule taille, /zone n, /tempete, /passe Cle, /boost Nom, /jour, /reset"
	)
end

print(
	`[Snowpal Rollers] Serveur prêt. Données {if ServiceDonnees.estTemporaire() then "TEMPORAIRES" else "persistantes"}.`
)
