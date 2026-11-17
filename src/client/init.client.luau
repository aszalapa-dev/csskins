--!strict
--[[
	Client — point d'entrée de l'interface et des effets de « Snowpal Rollers ».
	Le client affiche et demande ; toutes les décisions sont prises par le serveur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Les modules partagés et les Remotes peuvent arriver après ce script : on les attend.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(Shared:WaitForChild("Config"))

local Effets = require(script.Effets)
local Etat = require(script.Etat)
local HUD = require(script.HUD)
local Interface = require(script.Interface)
local Menus = require(script.Menus)
local Notifications = require(script.Notifications)
local Tutoriel = require(script.Tutoriel)

Notifications.demarrer()
Effets.demarrer()
local ouvrir = Menus.demarrer()
HUD.demarrer(ouvrir)
Etat.demarrer()

-- ───────────── Messages du serveur ─────────────

local remoteNotification = Remotes:WaitForChild("Notification") :: RemoteEvent
local remoteEffet = Remotes:WaitForChild("Effet") :: RemoteEvent

remoteNotification.OnClientEvent:Connect(function(texte: any, genre: any)
	if type(texte) == "string" then
		Notifications.message(texte, if type(genre) == "string" then genre else "Info")
	end
end)

local CRIS = { [3] = "RARE !", [4] = "ÉPIQUE !", [5] = "LÉGENDAIRE !!", [6] = "MYTHIQUE !!!" }

local function formater(nombre: any): string
	return require(Shared:WaitForChild("Formules")).formater(if type(nombre) == "number" then nombre else 0)
end

local effets: { [string]: (p: { [string]: any }) -> () } = {}

function effets.Livraison(p)
	Interface.jouerSon("Livraison")
	Notifications.gain(`+{formater(p.Flocons)} ❄️`)
	if type(p.Snowpal) == "string" then
		Notifications.revelation(p.Snowpal, p.Nouveau == true)
	end
	local rang = if type(p.Rarete) == "number" then p.Rarete else 1
	local atelier = Effets.positionAtelier()
	if atelier then
		Effets.gerbe(
			atelier,
			Interface.rgb(Config.Raretes[math.clamp(rang, 1, #Config.Raretes)].Couleur),
			14 + rang * 6
		)
	end
	if CRIS[rang] then
		Interface.jouerSon("Rare")
		Notifications.grandTexte(CRIS[rang], Interface.rgb(Config.Raretes[rang].Couleur))
		Effets.tremblement(0.25 + rang * 0.08, 0.45)
	elseif p.Nouveau == true then
		Notifications.grandTexte("NOUVEAU !", Interface.couleur("Attention"))
	end
	Tutoriel.surLivraison()
end

function effets.Collecte(p)
	Interface.jouerSon("Collecte")
	Notifications.gain(`+{formater(p.Flocons)} ❄️ (tirelire)`, Interface.couleur("Dore"))
end

function effets.Achat(_p)
	Interface.jouerSon("Achat")
end

function effets.Fusion(_p)
	Interface.jouerSon("Rare")
	Notifications.grandTexte("SNOWPAL DORÉ !", Interface.couleur("Dore"))
	Effets.tremblement(0.4, 0.4)
end

function effets.Recompense(p)
	Interface.jouerSon("Achat")
	Notifications.gain(`+{formater(p.Flocons)} ❄️`, Interface.couleur("Attention"))
	if type(p.Titre) == "string" then
		Notifications.message(`🎁 {p.Titre} : +{formater(p.Flocons)} ❄️`, "Cadeau")
	end
end

function effets.Rebirth(_p)
	Interface.jouerSon("Rare")
	Interface.fermerFenetres()
	Notifications.grandTexte("NOUVEL HIVER !", Color3.fromRGB(190, 130, 255))
	Effets.tremblement(0.6, 0.7)
end

function effets.Spectacle(p)
	if typeof(p.Position) == "Vector3" then
		Effets.spectacle(p.Position, if type(p.Rarete) == "number" then p.Rarete else 4)
	end
end

function effets.Annonce(p)
	if type(p.Texte) == "string" then
		local teinte = if type(p.Couleur) == "table" then Interface.rgb(p.Couleur) else Color3.new(1, 1, 1)
		Notifications.annonce(p.Texte, teinte)
	end
end

remoteEffet.OnClientEvent:Connect(function(nom: any, parametres: any)
	local effet = if type(nom) == "string" then effets[nom] else nil
	if effet ~= nil and type(parametres) == "table" then
		effet(parametres)
	end
end)

-- ───────────── Premier état reçu : terrain du joueur et tutoriel ─────────────

local terrainConnu = 0
local tutorielVerifie = false
Etat.surChangement(function(etat)
	if type(etat.Terrain) == "number" and etat.Terrain ~= terrainConnu then
		terrainConnu = etat.Terrain
		Effets.definirTerrain(etat.Terrain)
	end
	if not tutorielVerifie then
		tutorielVerifie = true
		if etat.Tutoriel ~= true then
			task.delay(1.5, Tutoriel.demarrer)
		end
	end
end)

-- ───────────── Rappel doux de la boutique (au maximum 1 toutes les 5 min) ─────────────

task.spawn(function()
	local astuces = {
		"💡 Astuce : un boost x2 t'attend dans la Boutique 🛒",
		"💡 Astuce : le passe « Collecte Auto » ramasse ta tirelire tout seul 🤖",
		"💡 Astuce : joue avec des amis pour gagner jusqu'à +30 % de flocons 👫",
	}
	local indice = 0
	while true do
		task.wait(Config.IntervalleRappelBoutique)
		indice = indice % #astuces + 1
		-- Les rappels d'achat ne sont montrés que si la boutique vend vraiment quelque chose
		if indice == 3 or Menus.boutiqueActive() then
			Notifications.message(astuces[indice], "Info")
		end
	end
end)

-- ───────────── Musique d'ambiance (facultative) ─────────────

if Config.Sons.Musique ~= "" then
	local musique = Instance.new("Sound")
	musique.Name = "Musique"
	musique.SoundId = Config.Sons.Musique
	musique.Looped = true
	musique.Volume = 0.25
	musique.Parent = SoundService
	musique:Play()
end
