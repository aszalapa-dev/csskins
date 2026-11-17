--!strict
--[[
	ServiceDonnees.luau — chargement et sauvegarde des données des joueurs.
	- DataStore au nom versionné (Config.Donnees.NomDataStore)
	- chaque appel est protégé par pcall, avec plusieurs tentatives
	- verrou de session simple : un serveur écrit son JobId dans les données ; un autre serveur attend
	  que le verrou soit libéré (ou expiré) avant de charger
	- si les API DataStore ne sont pas disponibles (Studio sans accès API), le jeu fonctionne avec des
	  données temporaires en mémoire
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local ModeleDonnees = require(ReplicatedStorage.Shared.ModeleDonnees)

type Donnees = ModeleDonnees.Donnees

local ServiceDonnees = {}

local REGLAGES = Config.Donnees
local idServeur = if game.JobId ~= "" then game.JobId else "studio"

-- nil = pas encore testé (ou échec hors Studio : on retestera) ; false = mode temporaire (Studio)
local magasin: DataStore? = nil
local disponible: boolean? = nil

-- Renvoie le DataStore, ou nil s'il n'est pas utilisable pour l'instant.
-- Le mode « données temporaires » n'existe QUE dans Studio : sur un vrai serveur, une panne du
-- DataStore ne doit jamais faire croire à un joueur qu'il repart de zéro.
local function obtenirMagasin(): DataStore?
	if disponible == nil then
		local ok, resultat = pcall(function()
			local store = DataStoreService:GetDataStore(REGLAGES.NomDataStore)
			store:GetAsync("__test") -- dans Studio sans accès API, c'est cet appel qui échoue
			return store
		end)
		if ok then
			magasin = resultat
			disponible = true
		elseif RunService:IsStudio() then
			disponible = false
			warn(`[Donnees] DataStore indisponible ({resultat}) : données TEMPORAIRES pour cette session Studio.`)
		else
			warn(`[Donnees] DataStore indisponible ({resultat}) : nouvel essai au prochain appel.`)
		end
	end
	return magasin
end

-- true = on joue avec des données en mémoire, jamais sauvegardées (Studio sans accès API)
function ServiceDonnees.estTemporaire(): boolean
	obtenirMagasin()
	return disponible == false
end

local function cle(idJoueur: number): string
	return "Joueur_" .. tostring(idJoueur)
end

-- Exécute `operation` avec pcall et jusqu'à Config.Donnees.Tentatives nouvelles tentatives.
local function avecTentatives<T>(nom: string, operation: () -> T): (boolean, T?)
	local derniereErreur: any = nil
	for essai = 0, REGLAGES.Tentatives do
		local ok, resultat = pcall(operation)
		if ok then
			return true, resultat
		end
		derniereErreur = resultat
		if essai < REGLAGES.Tentatives then
			task.wait(REGLAGES.DelaiTentative * (essai + 1))
		end
	end
	warn(`[Donnees] Échec de « {nom} » après {REGLAGES.Tentatives + 1} essais : {derniereErreur}`)
	return false, nil
end

--[[
	Charge les données d'un joueur et pose le verrou de session.
	Renvoie (donnees, nil) en cas de succès, ou (nil, raison) si le chargement a échoué :
	dans ce cas il ne faut SURTOUT PAS sauvegarder (on écraserait la vraie sauvegarde).
]]
function ServiceDonnees.charger(idJoueur: number): (Donnees?, string?)
	local store = obtenirMagasin()
	if store == nil then
		if disponible == false then
			return ModeleDonnees.defaut(), nil -- mode temporaire (Studio)
		end
		return nil, "DataStore indisponible"
	end

	-- On réessaie quelques fois si un autre serveur tient encore le verrou (changement de serveur rapide)
	for essaiVerrou = 1, 4 do
		local verrouille = false
		local charge: any = nil
		local ok = avecTentatives("chargement", function()
			verrouille = false
			store:UpdateAsync(cle(idJoueur), function(ancien: any): any
				local brut = if type(ancien) == "table" then ancien else nil
				local verrou = if brut then brut.Verrou else nil
				local maintenant = os.time()
				if
					type(verrou) == "table"
					and verrou.Serveur ~= idServeur
					and type(verrou.Temps) == "number"
					and maintenant - verrou.Temps < REGLAGES.DureeVerrou
					and essaiVerrou < 4 -- au dernier essai, on prend le verrou de force
				then
					verrouille = true
					return nil -- on n'écrit rien
				end
				local donnees = (brut or {}) :: { [string]: any }
				donnees.Verrou = { Serveur = idServeur, Temps = maintenant }
				charge = donnees
				return donnees
			end)
			return true
		end)
		if not ok then
			return nil, "Erreur DataStore"
		end
		if not verrouille and charge ~= nil then
			local verrou = charge.Verrou
			charge.Verrou = nil
			local donnees = ModeleDonnees.migrer(charge);
			(donnees :: any).Verrou = verrou
			return donnees, nil
		end
		task.wait(4)
	end
	return nil, "Session verrouillée"
end

--[[
	Sauvegarde les données. `liberer` = true à la déconnexion (retire le verrou de session).
	Renvoie true si la sauvegarde a réussi (toujours true en mode temporaire).
]]
function ServiceDonnees.sauvegarder(idJoueur: number, donnees: Donnees, liberer: boolean): boolean
	local store = obtenirMagasin()
	if store == nil then
		return disponible == false -- « réussi » seulement en mode temporaire
	end
	donnees.DerniereConnexion = os.time()
	local abandon = false
	local ok = avecTentatives("sauvegarde", function()
		abandon = false
		store:UpdateAsync(cle(idJoueur), function(ancien: any): any
			-- Si un AUTRE serveur a pris le verrou entre-temps, on n'écrase pas ses données.
			if type(ancien) == "table" and type(ancien.Verrou) == "table" and ancien.Verrou.Serveur ~= idServeur then
				abandon = true
				return nil
			end
			local copie = table.clone(donnees) :: { [string]: any }
			if liberer then
				copie.Verrou = nil
			else
				copie.Verrou = { Serveur = idServeur, Temps = os.time() }
			end
			return copie
		end)
		return true
	end)
	if abandon then
		warn(`[Donnees] Sauvegarde ignorée pour {idJoueur} : la session appartient à un autre serveur.`)
		return false
	end
	return ok
end

return ServiceDonnees
