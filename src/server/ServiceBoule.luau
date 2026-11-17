--!strict
--[[
	ServiceBoule.luau — la boucle de jeu principale, entièrement décidée par le serveur :
	  1. le joueur marche dans une zone enneigée -> sa boule grossit selon la distance parcourue
	  2. il revient sur l'atelier de son terrain -> la boule est vendue (flocons) et devient un Snowpal
	Le client n'envoie RIEN : le serveur lit la position du personnage 4 fois par seconde et limite la
	distance comptée par tick (anti-téléportation / anti-speedhack).
	L'affichage de la boule est fait côté client à partir de l'attribut « TailleBoule » du joueur.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalogue = require(ReplicatedStorage.Shared.Catalogue)
local Formules = require(ReplicatedStorage.Shared.Formules)
local Badges = require(script.Parent.Badges)
local ConstructeurMap = require(script.Parent.ConstructeurMap)
local Reseau = require(script.Parent.Reseau)
local ServiceTerrains = require(script.Parent.ServiceTerrains)
local Sessions = require(script.Parent.Sessions)

type Session = Sessions.Session

local ServiceBoule = {}

local alea = Random.new()

local function publierBoule(session: Session)
	local joueur = session.Joueur
	local boule = session.Boule
	local taille = if boule then math.floor(boule.Taille * 20 + 0.5) / 20 else 0
	if joueur:GetAttribute("TailleBoule") ~= taille then
		joueur:SetAttribute("TailleBoule", taille)
	end
	local max = boule ~= nil and boule.Taille >= Formules.tailleMax(session.Donnees.Ameliorations.Gants or 0) - 1e-3
	if joueur:GetAttribute("BouleMax") ~= max then
		joueur:SetAttribute("BouleMax", max)
	end
end

function ServiceBoule.reinitialiser(session: Session)
	session.Boule = nil
	publierBoule(session)
end

-- Zone dans laquelle la boule a le plus grossi
local function zoneDeLaBoule(boule: Sessions.Boule): number
	local meilleure, croissance = 1, -1
	for zone, valeur in boule.ParZone do
		if valeur > croissance then
			meilleure, croissance = zone, valeur
		end
	end
	return meilleure
end

--[[
	Livre la boule du joueur à son atelier : flocons + tirage d'un Snowpal.
	Toute la validation a déjà été faite par l'appelant (position, taille minimale).
]]
function ServiceBoule.livrer(session: Session, zoneForcee: number?)
	local boule = session.Boule
	if boule == nil then
		return
	end
	local donnees = session.Donnees
	local zone = math.clamp(zoneForcee or zoneDeLaBoule(boule), 1, donnees.ZoneMax)
	local taille = boule.Taille
	local tailleMax = Formules.tailleMax(donnees.Ameliorations.Gants or 0)
	session.Boule = nil
	publierBoule(session)

	-- 1) Flocons
	local flocons = math.floor(Formules.valeurBoule(taille, zone) * Sessions.multiplicateur(session))
	Sessions.ajouterFlocons(session, flocons)

	-- 2) Snowpal
	local chance = Formules.chance(donnees.Ameliorations.Chance or 0, taille)
	local snowpal = Formules.tirerSnowpal(zone, chance, alea:NextNumber(), alea:NextNumber())
	local exemplaires = donnees.Snowpals[snowpal.Id]
	if exemplaires == nil then
		exemplaires = { N = 0, D = 0 }
		donnees.Snowpals[snowpal.Id] = exemplaires
	end
	exemplaires.N += 1
	local nouveau = donnees.Index[snowpal.Id] ~= true
	donnees.Index[snowpal.Id] = true

	-- 3) Statistiques, quêtes, badges
	donnees.Stats.Boules += 1
	donnees.Stats.Snowpals += 1
	donnees.Stats.PlusGrosse = math.max(donnees.Stats.PlusGrosse, taille)
	Sessions.progresserQuete(session, "Boules", 1)
	Sessions.progresserQuete(session, "Snowpals", 1)
	if taille >= tailleMax - 1e-3 then
		Sessions.progresserQuete(session, "BoulesMax", 1)
	end
	if snowpal.Rarete >= 3 then
		Sessions.progresserQuete(session, "Rares", 1)
	end
	Badges.donner(session.Joueur, "PremierSnowpal")
	if snowpal.Rarete == 5 then
		Badges.donner(session.Joueur, "Legendaire")
	elseif snowpal.Rarete >= 6 then
		Badges.donner(session.Joueur, "Mythique")
	end
	if Formules.entreesIndex(donnees.Index) >= Catalogue.tailleIndex() / 2 then
		Badges.donner(session.Joueur, "Collectionneur")
	end

	session.Sale = true
	ServiceTerrains.rafraichir(session)

	-- 4) Effets : pour le joueur, et pour tout le serveur si c'est une belle obtention
	Reseau.effet(session.Joueur, "Livraison", {
		Flocons = flocons,
		Snowpal = snowpal.Id,
		Nouveau = nouveau,
		Rarete = snowpal.Rarete,
	})
	local terrain = ServiceTerrains.terrain(session.Terrain)
	if snowpal.Rarete >= Config.RareteSpectacle and terrain ~= nil then
		Reseau.effetTous("Spectacle", { Position = terrain.CentreAtelier, Rarete = snowpal.Rarete })
	end
	if snowpal.Rarete >= Config.RareteAnnonce then
		local rarete = Config.Raretes[snowpal.Rarete]
		Reseau.effetTous("Annonce", {
			Texte = `{session.Joueur.DisplayName} a obtenu {snowpal.Nom} ({rarete.Nom}) !`,
			Couleur = rarete.Couleur,
		})
	end
end

local function tick(session: Session, dt: number)
	local personnage = session.Joueur.Character
	local racine = if personnage then personnage:FindFirstChild("HumanoidRootPart") else nil
	local humanoide = if personnage then personnage:FindFirstChildOfClass("Humanoid") else nil
	if racine == nil or not racine:IsA("BasePart") or humanoide == nil or humanoide.Health <= 0 then
		session.DernierePosition = nil
		return
	end
	local donnees = session.Donnees
	local position = racine.Position
	local precedente = session.DernierePosition
	session.DernierePosition = position

	-- Distance horizontale parcourue depuis le dernier tick, plafonnée par la vitesse autorisée
	local distance = 0
	if precedente ~= nil then
		distance = Vector3.new(position.X - precedente.X, 0, position.Z - precedente.Z).Magnitude
		local limite = Formules.vitesse(donnees.Ameliorations.Bottes or 0) * dt * Config.Boule.MargeVitesse + 1
		if distance > limite then
			distance = 0 -- téléportation, réapparition ou triche : on ne compte rien
		end
	end

	local rayon = Vector3.new(position.X, 0, position.Z).Magnitude
	local zone = Formules.zoneDepuisDistance(rayon)

	if zone >= 1 then
		if zone > donnees.ZoneMax then
			local reglage = Config.Zones[zone]
			Sessions.aviser(
				session,
				"ZoneVerrouillee",
				6,
				`🔒 {reglage.Nom} est verrouillée. Débloque-la dans « Améliorer » !`,
				"Erreur"
			)
		else
			local boule: Sessions.Boule = session.Boule
				or { Taille = Config.Boule.TailleDepart, ParZone = table.create(#Config.Zones, 0) }
			session.Boule = boule
			local tailleMax = Formules.tailleMax(donnees.Ameliorations.Gants or 0)
			if boule.Taille < tailleMax and distance > 0 then
				local croissance = distance
					* Formules.croissanceParStud(
						donnees.Ameliorations.Pelle or 0,
						session.Passes.RouleurPro == true,
						Sessions.boostActif(session, "Croissance"),
						Workspace:GetAttribute("Tempete") == true
					)
				croissance = math.min(croissance, tailleMax - boule.Taille)
				boule.Taille += croissance
				boule.ParZone[zone] += croissance
			end
		end
	end

	-- Sur l'atelier de son terrain : collecte de la tirelire + livraison de la boule
	local terrain = ServiceTerrains.terrain(session.Terrain)
	if terrain ~= nil then
		local ecart = position - terrain.CentreAtelier
		if
			Vector3.new(ecart.X, 0, ecart.Z).Magnitude <= ConstructeurMap.RAYON_ATELIER + 1
			and math.abs(ecart.Y) < 14
		then
			local collecte = ServiceTerrains.collecter(session)
			if collecte > 0 then
				Reseau.effet(session.Joueur, "Collecte", { Flocons = collecte })
			end
			local boule = session.Boule
			if boule ~= nil then
				if boule.Taille >= Config.Boule.TailleMinLivraison then
					ServiceBoule.livrer(session)
				else
					Sessions.aviser(
						session,
						"BouleTropPetite",
						12,
						"Ta boule est trop petite ! Fais-la rouler dans la neige.",
						"Info"
					)
				end
			end
		end
	end

	publierBoule(session)
end

function ServiceBoule.demarrer()
	task.spawn(function()
		local intervalle = Config.Boule.IntervalleTick
		local dernier = os.clock()
		while true do
			task.wait(intervalle)
			local maintenant = os.clock()
			local dt = math.min(maintenant - dernier, 1)
			dernier = maintenant
			for joueur, session in Sessions.toutes() do
				if joueur.Parent == Players then
					local ok, erreur = (pcall :: any)(tick, session, dt)
					if not ok then
						warn(`[Boule] {erreur}`)
					end
				end
			end
		end
	end)
end

return ServiceBoule
