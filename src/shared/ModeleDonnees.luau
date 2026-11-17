--!strict
--[[
	ModeleDonnees.luau — forme des données sauvegardées d'un joueur, valeurs par défaut et migration.
	Module pur (aucune API Roblox) : testé dans tests/.
]]

local Config = require(script.Parent.Config)

export type Exemplaires = { N: number, D: number } -- N = normaux, D = dorés

export type QueteActive = { Id: string, Progres: number, Reclamee: boolean }

export type Donnees = {
	Version: number,
	Flocons: number,
	FloconsTotal: number, -- total gagné depuis toujours (classement)
	Rebirths: number,
	Ameliorations: { [string]: number },
	ZoneMax: number, -- plus haute zone débloquée
	Snowpals: { [string]: Exemplaires },
	Index: { [string]: boolean }, -- "id" et "id_D" découverts
	Reserve: number, -- flocons en attente dans la tirelire du terrain
	DerniereConnexion: number, -- os.time() de la dernière sauvegarde
	Quotidien: { Serie: number, DernierJour: number },
	Cadeaux: { Jour: number, Secondes: number, Reclames: { [string]: boolean } },
	Quetes: { Jour: number, Liste: { QueteActive } },
	Tutoriel: boolean,
	Boosts: { [string]: number }, -- nom du boost -> os.time() d'expiration
	AchatsTraites: { string }, -- derniers PurchaseId traités (idempotence)
	Stats: { Boules: number, PlusGrosse: number, TempsJeu: number, Snowpals: number },
}

local ModeleDonnees = {}

function ModeleDonnees.defaut(): Donnees
	return {
		Version = Config.Donnees.Version,
		Flocons = 0,
		FloconsTotal = 0,
		Rebirths = 0,
		Ameliorations = { Gants = 0, Pelle = 0, Bottes = 0, Chance = 0, Socles = 0 },
		ZoneMax = 1,
		Snowpals = {},
		Index = {},
		Reserve = 0,
		DerniereConnexion = 0,
		Quotidien = { Serie = 0, DernierJour = 0 },
		Cadeaux = { Jour = 0, Secondes = 0, Reclames = {} },
		Quetes = { Jour = 0, Liste = {} },
		Tutoriel = false,
		Boosts = {},
		AchatsTraites = {},
		Stats = { Boules = 0, PlusGrosse = 0, TempsJeu = 0, Snowpals = 0 },
	}
end

-- Recopie dans `cible` les champs absents (récursif sur les tables-dictionnaires du modèle).
local function completer(cible: { [any]: any }, modele: { [any]: any })
	for cle, valeur in modele do
		if cible[cle] == nil then
			if type(valeur) == "table" then
				local copie = {}
				completer(copie, valeur)
				cible[cle] = copie
			else
				cible[cle] = valeur
			end
		elseif type(valeur) == "table" and type(cible[cle]) == "table" then
			completer(cible[cle], valeur)
		elseif type(valeur) ~= type(cible[cle]) then
			-- type corrompu : on remet la valeur par défaut
			cible[cle] = valeur
		end
	end
end

local function nombreSain(valeur: any, minimum: number, maximum: number, defaut: number): number
	if type(valeur) ~= "number" or valeur ~= valeur then
		return defaut
	end
	return math.clamp(valeur, minimum, maximum)
end

--[[
	Transforme n'importe quelle valeur lue dans le DataStore en données valides et à jour.
	- nil ou valeur invalide -> données par défaut
	- ancienne version -> migration pas à pas
	- champs manquants -> complétés ; valeurs hors limites -> ramenées dans les bornes
]]
function ModeleDonnees.migrer(brut: any): Donnees
	if type(brut) ~= "table" then
		return ModeleDonnees.defaut()
	end
	local donnees = brut :: { [string]: any }
	local version = if type(donnees.Version) == "number" then donnees.Version else 1

	-- v1 -> v2 : les zones étaient une liste de booléens { [1]=true, [2]=true }, devenue ZoneMax ;
	-- « FloconsTotal » n'existait pas.
	if version < 2 then
		if type(donnees.Zones) == "table" then
			local zoneMax = 1
			for indice, debloquee in donnees.Zones do
				local numero = tonumber(indice)
				if debloquee == true and numero ~= nil and numero > zoneMax then
					zoneMax = numero
				end
			end
			donnees.ZoneMax = zoneMax
			donnees.Zones = nil
		end
		if type(donnees.FloconsTotal) ~= "number" then
			donnees.FloconsTotal = if type(donnees.Flocons) == "number" then donnees.Flocons else 0
		end
		version = 2
	end

	donnees.Version = Config.Donnees.Version
	completer(donnees, ModeleDonnees.defaut())

	-- Bornes de sécurité
	donnees.Flocons = nombreSain(donnees.Flocons, 0, 1e18, 0)
	donnees.FloconsTotal = nombreSain(donnees.FloconsTotal, 0, 1e18, 0)
	donnees.Reserve = nombreSain(donnees.Reserve, 0, 1e18, 0)
	donnees.Rebirths = math.floor(nombreSain(donnees.Rebirths, 0, Config.Rebirth.Max, 0))
	donnees.ZoneMax = math.floor(nombreSain(donnees.ZoneMax, 1, #Config.Zones, 1))
	for nom, reglage in Config.Ameliorations :: { [string]: any } do
		donnees.Ameliorations[nom] = math.floor(nombreSain(donnees.Ameliorations[nom], 0, reglage.NiveauMax, 0))
	end
	for id, exemplaires in donnees.Snowpals do
		if type(exemplaires) ~= "table" then
			donnees.Snowpals[id] = nil
		else
			exemplaires.N = math.floor(nombreSain(exemplaires.N, 0, 1e9, 0))
			exemplaires.D = math.floor(nombreSain(exemplaires.D, 0, 1e9, 0))
		end
	end
	return donnees :: any
end

return ModeleDonnees
