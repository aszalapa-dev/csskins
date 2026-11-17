--!strict
--[[
	Etat.luau (client) — copie locale de l'état envoyé par le serveur + envoi des actions.
	Le client ne décide de rien : il affiche l'état et DEMANDE des actions au serveur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local remoteAction = Remotes:WaitForChild("Action") :: RemoteEvent
local remoteEtat = Remotes:WaitForChild("Etat") :: RemoteEvent

local Etat = {}

-- Dernier instantané reçu (nil tant que le serveur n'a pas répondu)
Etat.valeur = nil :: { [string]: any }?
-- os.clock() au moment de la réception (pour décompter boosts et cadeaux localement)
Etat.recuA = 0

local ecouteurs: { (etat: { [string]: any }) -> () } = {}

-- Appelle `ecouteur` à chaque nouvel état (et tout de suite si un état est déjà connu)
function Etat.surChangement(ecouteur: (etat: { [string]: any }) -> ())
	table.insert(ecouteurs, ecouteur)
	if Etat.valeur ~= nil then
		task.spawn(ecouteur, Etat.valeur)
	end
end

function Etat.action(nom: string, ...: any)
	remoteAction:FireServer(nom, ...)
end

-- Secondes écoulées depuis la réception du dernier état
function Etat.depuisReception(): number
	return os.clock() - Etat.recuA
end

function Etat.demarrer()
	remoteEtat.OnClientEvent:Connect(function(etat: any)
		if type(etat) ~= "table" then
			return
		end
		Etat.valeur = etat
		Etat.recuA = os.clock()
		for _, ecouteur in ecouteurs do
			task.spawn(ecouteur, etat)
		end
	end)
	-- Sécurité : si le premier envoi du serveur a été manqué, on redemande l'état
	task.spawn(function()
		while Etat.valeur == nil do
			Etat.action("DemanderEtat")
			task.wait(3)
		end
	end)
end

return Etat
