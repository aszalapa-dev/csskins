--!strict
--[[
	ServiceProgression.luau — améliorations, déblocage des zones, fusion en doré et rebirth.
	Chaque action revérifie tout côté serveur (prix, niveaux, quantités).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalogue = require(ReplicatedStorage.Shared.Catalogue)
local Formules = require(ReplicatedStorage.Shared.Formules)
local Badges = require(script.Parent.Badges)
local Reseau = require(script.Parent.Reseau)
local ServiceBoule = require(script.Parent.ServiceBoule)
local ServiceTerrains = require(script.Parent.ServiceTerrains)
local Sessions = require(script.Parent.Sessions)

type Session = Sessions.Session

local ServiceProgression = {}

-- Applique la vitesse de marche correspondant au niveau de « Bottes »
function ServiceProgression.appliquerVitesse(session: Session)
	local personnage = session.Joueur.Character
	local humanoide = if personnage then personnage:FindFirstChildOfClass("Humanoid") else nil
	if humanoide ~= nil then
		humanoide.WalkSpeed = Formules.vitesse(session.Donnees.Ameliorations.Bottes or 0)
	end
end

-- Étiquette au-dessus de la tête : étoiles de rebirth + couronne VIP (visible par tous)
function ServiceProgression.majEtiquette(session: Session)
	local personnage = session.Joueur.Character
	local tete = if personnage then personnage:FindFirstChild("Head") else nil
	if tete == nil or not tete:IsA("BasePart") then
		return
	end
	local texte = ""
	if session.Passes.VIP then
		texte ..= "👑 VIP "
	end
	if session.Donnees.Rebirths > 0 then
		texte ..= `⭐ {session.Donnees.Rebirths}`
	end
	local gui = tete:FindFirstChild("EtiquetteSnowpal")
	if texte == "" then
		if gui then
			gui:Destroy()
		end
		return
	end
	local label: TextLabel?
	if gui ~= nil and gui:IsA("BillboardGui") then
		label = gui:FindFirstChild("Texte") :: TextLabel?
	else
		local nouveau = Instance.new("BillboardGui")
		nouveau.Name = "EtiquetteSnowpal"
		nouveau.Size = UDim2.fromScale(5, 1)
		nouveau.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
		nouveau.MaxDistance = 80
		nouveau.LightInfluence = 0
		nouveau.Adornee = tete
		local texteNeuf = Instance.new("TextLabel")
		texteNeuf.Name = "Texte"
		texteNeuf.BackgroundTransparency = 1
		texteNeuf.Size = UDim2.fromScale(1, 1)
		texteNeuf.TextColor3 = Color3.fromRGB(255, 215, 80)
		texteNeuf.TextScaled = true
		texteNeuf.Font = Enum.Font.FredokaOne
		texteNeuf.TextStrokeTransparency = 0.3
		texteNeuf.Parent = nouveau
		nouveau.Parent = tete
		label = texteNeuf
	end
	if label ~= nil then
		label.Text = texte
	end
end

-- À appeler à chaque apparition du personnage (voir init.server.luau)
function ServiceProgression.equiperPersonnage(session: Session, personnage: Model)
	-- Le personnage peut ne pas être complet tout de suite : on attend l'humanoïde (avec délai max)
	local humanoide = personnage:WaitForChild("Humanoid", 10)
	personnage:WaitForChild("Head", 10)
	if humanoide == nil or session.Joueur.Character ~= personnage then
		return
	end
	ServiceProgression.appliquerVitesse(session)
	ServiceProgression.majEtiquette(session)
end

local function acheterAmelioration(joueur: Player, nom: any)
	local session = Sessions.obtenir(joueur)
	if session == nil or type(nom) ~= "string" then
		return
	end
	local niveau = session.Donnees.Ameliorations[nom]
	if niveau == nil then
		return
	end
	local prix = Formules.prixAmelioration(nom, niveau)
	if prix == nil then
		Reseau.notifier(joueur, "Niveau maximum atteint !", "Info")
		return
	end
	if not Sessions.payer(session, prix) then
		Reseau.notifier(joueur, "Pas assez de flocons ❄️", "Erreur")
		return
	end
	session.Donnees.Ameliorations[nom] = niveau + 1
	Sessions.progresserQuete(session, "Ameliorations", 1)
	if nom == "Bottes" then
		ServiceProgression.appliquerVitesse(session)
	elseif nom == "Socles" then
		ServiceTerrains.rafraichir(session)
	end
	Reseau.effet(joueur, "Achat", { Nom = nom })
	Sessions.envoyer(session)
end

local function acheterZone(joueur: Player)
	local session = Sessions.obtenir(joueur)
	if session == nil then
		return
	end
	local suivante = Config.Zones[session.Donnees.ZoneMax + 1]
	if suivante == nil then
		return
	end
	if not Sessions.payer(session, suivante.Prix) then
		Reseau.notifier(joueur, "Pas assez de flocons ❄️", "Erreur")
		return
	end
	session.Donnees.ZoneMax = suivante.Id
	Reseau.effet(joueur, "Achat", { Nom = "Zone" })
	Reseau.notifier(
		joueur,
		`🎉 Nouvelle zone débloquée : {suivante.Nom} (❄️ x{suivante.Multiplicateur}) !`,
		"Succes"
	)
	Sessions.envoyer(session)
end

local function fusionner(joueur: Player, id: any)
	local session = Sessions.obtenir(joueur)
	if session == nil or type(id) ~= "string" or Catalogue.ParId[id] == nil then
		return
	end
	local exemplaires = session.Donnees.Snowpals[id]
	if exemplaires == nil or exemplaires.N < Config.Dore.CoutFusion then
		Reseau.notifier(joueur, `Il faut {Config.Dore.CoutFusion} exemplaires pour fusionner.`, "Erreur")
		return
	end
	exemplaires.N -= Config.Dore.CoutFusion
	exemplaires.D += 1
	session.Donnees.Index[id .. "_D"] = true
	Sessions.progresserQuete(session, "Fusions", 1)
	Badges.donner(joueur, "PremierDore")
	if Formules.entreesIndex(session.Donnees.Index) >= Catalogue.tailleIndex() / 2 then
		Badges.donner(joueur, "Collectionneur")
	end
	ServiceTerrains.rafraichir(session)
	Reseau.effet(joueur, "Fusion", { Snowpal = id })
	Sessions.envoyer(session)
end

local function rebirth(joueur: Player)
	local session = Sessions.obtenir(joueur)
	if session == nil then
		return
	end
	if not Formules.peutRebirth(session.Donnees) then
		Reseau.notifier(joueur, "Pas encore assez de flocons pour un Nouvel Hiver.", "Erreur")
		return
	end
	Formules.appliquerRebirth(session.Donnees)
	ServiceBoule.reinitialiser(session)
	ServiceProgression.appliquerVitesse(session)
	ServiceProgression.majEtiquette(session)
	ServiceTerrains.rafraichir(session)
	Badges.donner(joueur, "NouvelHiver")
	Reseau.effet(joueur, "Rebirth", { Rebirths = session.Donnees.Rebirths })
	Reseau.effetTous("Annonce", {
		Texte = `{joueur.DisplayName} commence son Nouvel Hiver n°{session.Donnees.Rebirths} ! ⭐`,
		Couleur = Config.Couleurs.Dore,
	})
	local terrain = ServiceTerrains.terrain(session.Terrain)
	if terrain ~= nil then
		Reseau.effetTous("Spectacle", { Position = terrain.CentreAtelier, Rarete = 6 })
	end
	Sessions.envoyer(session)
end

function ServiceProgression.initialiser()
	Reseau.surAction("AcheterAmelioration", acheterAmelioration)
	Reseau.surAction("AcheterZone", acheterZone)
	Reseau.surAction("Fusionner", fusionner)
	Reseau.surAction("Rebirth", rebirth)
end

return ServiceProgression
