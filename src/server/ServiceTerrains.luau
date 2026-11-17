--!strict
--[[
	ServiceTerrains.luau — attribution des terrains, exposition des Snowpals sur les socles,
	revenus passifs (tirelire) et textes des panneaux.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formules = require(ReplicatedStorage.Shared.Formules)
local ConstructeurMap = require(script.Parent.ConstructeurMap)
local ConstructeurSnowpal = require(script.Parent.ConstructeurSnowpal)
local Sessions = require(script.Parent.Sessions)

type Session = Sessions.Session

local ServiceTerrains = {}

local terrains: { ConstructeurMap.Terrain } = {}
local occupants: { [number]: Player? } = {}

function ServiceTerrains.initialiser(map: ConstructeurMap.Map)
	terrains = map.Terrains
end

function ServiceTerrains.terrain(numero: number): ConstructeurMap.Terrain?
	return terrains[numero]
end

-- Réserve un terrain libre pour le joueur (appel synchrone, dès son arrivée) et règle son point d'apparition.
function ServiceTerrains.reserver(joueur: Player): number
	local numero = 0
	for indice in terrains do
		if occupants[indice] == nil then
			numero = indice
			break
		end
	end
	if numero == 0 then
		-- Ne devrait pas arriver si « joueurs max » = Config.JoueursMax : on partage un terrain.
		numero = joueur.UserId % math.max(#terrains, 1) + 1
		warn("[Terrains] Plus de terrain libre : vérifier le réglage « joueurs max » du jeu.")
	else
		occupants[numero] = joueur
	end
	local terrain = terrains[numero]
	if terrain ~= nil and terrain.Spawn ~= nil then
		joueur.RespawnLocation = terrain.Spawn
	end
	return numero
end

function ServiceTerrains.liberer(joueur: Player, numero: number)
	if occupants[numero] ~= joueur then
		return
	end
	occupants[numero] = nil
	local terrain = terrains[numero]
	if terrain == nil then
		return
	end
	terrain.Snowpals:ClearAllChildren()
	if terrain.Panneau then
		terrain.Panneau.Text = "Terrain libre"
	end
	if terrain.Tirelire then
		terrain.Tirelire.Text = "Tirelire : 0 ❄️"
	end
end

-- Reconstruit les Snowpals exposés si l'équipe a changé, et met à jour le panneau.
function ServiceTerrains.rafraichir(session: Session)
	local terrain = terrains[session.Terrain]
	if terrain == nil then
		return
	end
	local equipe = Sessions.equipe(session)
	local morceaux = table.create(#equipe)
	for indice, membre in equipe do
		morceaux[indice] = if membre.Dore then membre.Id .. "_D" else membre.Id
	end
	local signature = table.concat(morceaux, ",")
	if signature ~= session.SignatureEquipe then
		session.SignatureEquipe = signature
		terrain.Snowpals:ClearAllChildren()
		for indice, membre in equipe do
			local socle: CFrame? = terrain.Socles[indice]
			if socle ~= nil then
				local modele = ConstructeurSnowpal.construire(membre.Id, membre.Dore, socle)
				if modele ~= nil then
					modele.Parent = terrain.Snowpals
				end
			end
		end
	end
	if terrain.Panneau then
		local revenu = Formules.revenuEquipe(equipe) * Sessions.multiplicateur(session)
		local etoiles = if session.Donnees.Rebirths > 0 then `  ⭐{session.Donnees.Rebirths}` else ""
		terrain.Panneau.Text = `{session.Joueur.DisplayName}{etoiles}\n+{Formules.formater(revenu)} ❄️/s`
	end
end

-- Appelé une fois par seconde pour chaque joueur : revenus passifs des Snowpals.
function ServiceTerrains.chaqueSeconde(session: Session)
	local donnees = session.Donnees
	local multiplicateur = Sessions.multiplicateur(session)
	local revenu = Formules.revenuEquipe(Sessions.equipe(session))
	local gain = revenu * multiplicateur
	if gain > 0 then
		if session.Passes.CollecteAuto then
			Sessions.ajouterFlocons(session, gain + donnees.Reserve)
			donnees.Reserve = 0
		else
			local plafond = Formules.reserveMax(revenu, multiplicateur)
			if donnees.Reserve < plafond then
				donnees.Reserve = math.min(plafond, donnees.Reserve + gain)
				session.Sale = true
			end
		end
	end
	local terrain = terrains[session.Terrain]
	if terrain ~= nil and terrain.Tirelire ~= nil then
		local texte = if session.Passes.CollecteAuto
			then "Collecte auto 🤖"
			else `Tirelire : {Formules.formater(donnees.Reserve)} ❄️`
		if terrain.Tirelire.Text ~= texte then
			terrain.Tirelire.Text = texte
		end
	end
end

-- Vide la tirelire dans les flocons du joueur. Renvoie le montant collecté.
function ServiceTerrains.collecter(session: Session): number
	local montant = math.floor(session.Donnees.Reserve)
	if montant <= 0 then
		return 0
	end
	session.Donnees.Reserve = 0
	Sessions.ajouterFlocons(session, montant)
	Sessions.progresserQuete(session, "Collectes", 1)
	return montant
end

return ServiceTerrains
