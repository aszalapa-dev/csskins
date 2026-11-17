--!strict
--[[
	Reseau.luau (serveur) — point d'entrée unique pour les Remotes.
	- Un seul RemoteEvent « Action » client -> serveur : chaque action est enregistrée avec surAction(),
	  et passe d'abord par une limite de débit (Config.Debit).
	- « Etat », « Notification », « Effet » : serveur -> client uniquement.
	Le serveur ne fait JAMAIS confiance aux arguments reçus : chaque gestionnaire revérifie tout.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

export type GenreNotification = "Info" | "Succes" | "Erreur" | "Cadeau"

local Reseau = {}

-- Les Remotes sont déclarés dans default.project.json ; on les crée s'ils manquent (sécurité).
local dossier = ReplicatedStorage:FindFirstChild("Remotes")
if dossier == nil then
	local nouveau = Instance.new("Folder")
	nouveau.Name = "Remotes"
	nouveau.Parent = ReplicatedStorage
	dossier = nouveau
end

local function remote(nom: string): RemoteEvent
	local existant = (dossier :: Instance):FindFirstChild(nom)
	if existant ~= nil and existant:IsA("RemoteEvent") then
		return existant
	end
	local nouveau = Instance.new("RemoteEvent")
	nouveau.Name = nom
	nouveau.Parent = dossier
	return nouveau
end

local remoteAction = remote("Action")
local remoteEtat = remote("Etat")
local remoteNotification = remote("Notification")
local remoteEffet = remote("Effet")

-- ───────────── Limite de débit (fenêtre glissante simple, par joueur et par action) ─────────────
type Compteur = { Debut: number, Nombre: number }
local compteurs: { [Player]: { [string]: Compteur } } = {}

local function debitAutorise(joueur: Player, action: string): boolean
	local limite = (Config.Debit :: { [string]: { Max: number, Fenetre: number } })[action] or Config.Debit.Defaut
	local parJoueur = compteurs[joueur]
	if parJoueur == nil then
		parJoueur = {}
		compteurs[joueur] = parJoueur
	end
	local maintenant = os.clock()
	local compteur = parJoueur[action]
	if compteur == nil or maintenant - compteur.Debut >= limite.Fenetre then
		parJoueur[action] = { Debut = maintenant, Nombre = 1 }
		return true
	end
	compteur.Nombre += 1
	return compteur.Nombre <= limite.Max
end

Players.PlayerRemoving:Connect(function(joueur)
	compteurs[joueur] = nil
end)

-- ───────────── Actions client -> serveur ─────────────
local gestionnaires: { [string]: (joueur: Player, ...any) -> () } = {}

function Reseau.surAction(nom: string, gestionnaire: (joueur: Player, ...any) -> ())
	gestionnaires[nom] = gestionnaire
end

remoteAction.OnServerEvent:Connect(function(joueur: Player, nom: any, ...: any)
	if type(nom) ~= "string" or #nom > 40 then
		return
	end
	local gestionnaire = gestionnaires[nom]
	if gestionnaire == nil then
		return
	end
	if not debitAutorise(joueur, nom) then
		return -- trop d'appels : on ignore en silence
	end
	-- Au plus 4 arguments simples : on coupe le reste pour éviter les abus
	local arguments = table.pack(...)
	if arguments.n > 4 then
		return
	end
	local ok, erreur = (pcall :: any)(gestionnaire, joueur, table.unpack(arguments, 1, arguments.n))
	if not ok then
		warn(`[Reseau] Erreur dans l'action {nom} : {erreur}`)
	end
end)

-- ───────────── Serveur -> client ─────────────

function Reseau.envoyerEtat(joueur: Player, etat: { [string]: any })
	remoteEtat:FireClient(joueur, etat)
end

function Reseau.notifier(joueur: Player, texte: string, genre: GenreNotification?)
	remoteNotification:FireClient(joueur, texte, genre or "Info")
end

function Reseau.notifierTous(texte: string, genre: GenreNotification?)
	remoteNotification:FireAllClients(texte, genre or "Info")
end

-- Déclenche un effet visuel/sonore côté client (voir client/Effets.luau)
function Reseau.effet(joueur: Player, nom: string, parametres: { [string]: any }?)
	remoteEffet:FireClient(joueur, nom, parametres or {})
end

function Reseau.effetTous(nom: string, parametres: { [string]: any }?)
	remoteEffet:FireAllClients(nom, parametres or {})
end

return Reseau
