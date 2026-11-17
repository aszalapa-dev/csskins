--!strict
--[[
	ServiceRecompenses.luau — récompenses quotidiennes (7 jours), cadeaux de temps de jeu,
	quêtes quotidiennes, revenus hors ligne et tutoriel.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formules = require(ReplicatedStorage.Shared.Formules)
local Recompenses = require(ReplicatedStorage.Shared.Recompenses)
local Badges = require(script.Parent.Badges)
local Reseau = require(script.Parent.Reseau)
local Sessions = require(script.Parent.Sessions)

type Session = Sessions.Session

local ServiceRecompenses = {}

local function jourActuel(): number
	return Recompenses.numeroJour(os.time())
end

-- Remet à jour cadeaux et quêtes si le jour a changé (appelé à la connexion puis régulièrement)
local function rafraichirJour(session: Session)
	local jour = jourActuel()
	local donnees = session.Donnees
	if donnees.Cadeaux.Jour ~= jour then
		Recompenses.rafraichirCadeaux(donnees.Cadeaux, jour)
		session.Sale = true
	end
	if Recompenses.rafraichirQuetes(donnees.Quetes, jour) then
		session.Sale = true
	end
end

-- À la connexion : jour courant, revenus hors ligne, badge de bienvenue
function ServiceRecompenses.initialiserSession(session: Session)
	rafraichirJour(session)
	local donnees = session.Donnees
	if donnees.DerniereConnexion > 0 then
		local absence = os.time() - donnees.DerniereConnexion
		if absence > 120 then
			local revenu = Formules.revenuEquipe(Sessions.equipe(session))
			-- Hors ligne : on ne compte que les bonus permanents (pas les amis ni les boosts)
			local contexte = Sessions.contexte(session)
			contexte.Amis = 0
			contexte.BoostFlocons = false
			local gain = Formules.revenuHorsLigne(absence, revenu, Formules.multiplicateurFlocons(contexte))
			if gain > 0 then
				Sessions.ajouterFlocons(session, gain)
				task.delay(6, function()
					if Sessions.obtenir(session.Joueur) == session then
						Reseau.notifier(
							session.Joueur,
							`💤 Pendant ton absence, tes Snowpals ont gagné {Formules.formater(gain)} ❄️ !`,
							"Cadeau"
						)
					end
				end)
			end
		end
	end
	Badges.donner(session.Joueur, "Bienvenue")
end

-- Appelé une fois par seconde pour chaque joueur
function ServiceRecompenses.chaqueSeconde(session: Session)
	local donnees = session.Donnees
	local avant = donnees.Cadeaux.Secondes
	donnees.Cadeaux.Secondes = avant + 1
	donnees.Stats.TempsJeu += 1
	if donnees.Stats.TempsJeu % 60 == 0 then
		Sessions.progresserQuete(session, "Minutes", 1)
	end
	if donnees.Stats.TempsJeu % 20 == 0 then
		rafraichirJour(session)
	end
	-- Un cadeau vient de devenir disponible : on prévient le client
	for indice, cadeau in Config.Cadeaux do
		if avant < cadeau.Minutes * 60 and donnees.Cadeaux.Secondes >= cadeau.Minutes * 60 then
			if not donnees.Cadeaux.Reclames[tostring(indice)] then
				session.Sale = true
				Reseau.notifier(session.Joueur, "🎁 Un cadeau de temps de jeu est prêt !", "Cadeau")
			end
		end
	end
end

local function reclamerQuotidien(joueur: Player)
	local session = Sessions.obtenir(joueur)
	if session == nil then
		return
	end
	local jourSerie = Recompenses.reclamerQuotidien(session.Donnees.Quotidien, jourActuel())
	if jourSerie == nil then
		Reseau.notifier(joueur, "Reviens demain pour la prochaine récompense !", "Info")
		return
	end
	local facteur = Formules.echelleRecompense(session.Donnees) * (if session.Passes.VIP then 2 else 1)
	local flocons = Sessions.donnerRecompense(session, Config.Quotidien[jourSerie], facteur)
	Reseau.effet(joueur, "Recompense", { Flocons = flocons, Titre = `Jour {jourSerie}` })
	Sessions.envoyer(session)
end

local function reclamerCadeau(joueur: Player, indice: any)
	local session = Sessions.obtenir(joueur)
	if session == nil or type(indice) ~= "number" or indice ~= math.floor(indice) then
		return
	end
	rafraichirJour(session)
	local cadeaux = session.Donnees.Cadeaux
	if not Recompenses.cadeauDisponible(cadeaux, indice) then
		return
	end
	cadeaux.Reclames[tostring(indice)] = true
	local flocons =
		Sessions.donnerRecompense(session, Config.Cadeaux[indice], Formules.echelleRecompense(session.Donnees))
	Reseau.effet(joueur, "Recompense", { Flocons = flocons, Titre = "Cadeau" })
	Sessions.envoyer(session)
end

local function reclamerQuete(joueur: Player, indice: any)
	local session = Sessions.obtenir(joueur)
	if session == nil or type(indice) ~= "number" or indice ~= math.floor(indice) then
		return
	end
	local base = Recompenses.reclamerQuete(session.Donnees.Quetes.Liste, indice)
	if base == nil then
		return
	end
	local flocons = math.floor(base * Formules.echelleRecompense(session.Donnees))
	Sessions.ajouterFlocons(session, flocons)
	Reseau.effet(joueur, "Recompense", { Flocons = flocons, Titre = "Quête terminée" })
	Sessions.envoyer(session)
end

local function tutorielFini(joueur: Player)
	local session = Sessions.obtenir(joueur)
	if session ~= nil and not session.Donnees.Tutoriel then
		session.Donnees.Tutoriel = true
		session.Sale = true
	end
end

local function demanderEtat(joueur: Player)
	local session = Sessions.obtenir(joueur)
	if session ~= nil then
		Sessions.envoyer(session)
	end
end

function ServiceRecompenses.initialiser()
	Reseau.surAction("ReclamerQuotidien", reclamerQuotidien)
	Reseau.surAction("ReclamerCadeau", reclamerCadeau)
	Reseau.surAction("ReclamerQuete", reclamerQuete)
	Reseau.surAction("TutorielFini", tutorielFini)
	Reseau.surAction("DemanderEtat", demanderEtat)
end

return ServiceRecompenses
