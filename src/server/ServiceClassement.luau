--!strict
--[[
	ServiceClassement.luau — classement mondial (OrderedDataStore) affiché sur le panneau de la place.
	Une seule boucle lente (Config.Classement.IntervalleRafraichissement) ; tout est protégé par pcall.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formules = require(ReplicatedStorage.Shared.Formules)
local ConstructeurMap = require(script.Parent.ConstructeurMap)
local ServiceDonnees = require(script.Parent.ServiceDonnees)
local Sessions = require(script.Parent.Sessions)

local ServiceClassement = {}

local noms: { [number]: string } = {}

local function nomDe(idJoueur: number): string
	local connu = noms[idJoueur]
	if connu ~= nil then
		return connu
	end
	local joueur = Players:GetPlayerByUserId(idJoueur)
	local nom = if joueur then joueur.Name else nil
	if nom == nil then
		local ok, resultat = pcall(function()
			return Players:GetNameFromUserIdAsync(idJoueur)
		end)
		nom = if ok then resultat else "Joueur"
	end
	noms[idJoueur] = nom :: string
	return nom :: string
end

-- Classement local (joueurs du serveur) : utilisé quand le DataStore n'est pas disponible
local function afficherLocal(lignes: { TextLabel })
	local liste = {}
	for joueur, session in Sessions.toutes() do
		table.insert(liste, { Nom = joueur.Name, Valeur = session.Donnees.FloconsTotal })
	end
	table.sort(liste, function(a, b)
		return a.Valeur > b.Valeur
	end)
	for rang, ligne in lignes do
		local entree = liste[rang]
		ligne.Text = if entree
			then `{rang}.  {entree.Nom}  —  {Formules.formater(entree.Valeur)} ❄️`
			else `{rang}.  —`
	end
end

local function rafraichir(magasin: OrderedDataStore, lignes: { TextLabel })
	-- 1) Envoie le score des joueurs présents
	-- (SetAsync attend : on copie d'abord les scores pour ne pas parcourir une table qui change)
	local scores = {}
	for joueur, session in Sessions.toutes() do
		table.insert(scores, { Id = joueur.UserId, Valeur = math.floor(math.min(session.Donnees.FloconsTotal, 9e15)) })
	end
	for _, score in scores do
		if score.Valeur > 0 then
			pcall(function()
				magasin:SetAsync(tostring(score.Id), score.Valeur)
			end)
		end
	end
	-- 2) Lit le haut du classement
	local ok, pages = pcall(function()
		return magasin:GetSortedAsync(false, Config.Classement.Taille)
	end)
	if not ok then
		return
	end
	local entrees = (pages :: DataStorePages):GetCurrentPage()
	for rang, ligne in lignes do
		local entree = entrees[rang]
		if entree ~= nil then
			local id = tonumber(entree.key)
			local nom = if id then nomDe(id) else "Joueur"
			ligne.Text = `{rang}.  {nom}  —  {Formules.formater(entree.value)} ❄️`
		else
			ligne.Text = `{rang}.  —`
		end
	end
end

function ServiceClassement.demarrer(map: ConstructeurMap.Map)
	local lignes = map.LignesClassement
	if #lignes == 0 then
		return
	end
	task.spawn(function()
		local magasin: OrderedDataStore? = nil
		if not ServiceDonnees.estTemporaire() then
			local ok, resultat = pcall(function()
				return DataStoreService:GetOrderedDataStore(Config.Donnees.NomClassement)
			end)
			if ok then
				magasin = resultat
			end
		end
		task.wait(10) -- laisse le temps aux premiers joueurs de charger
		while true do
			if magasin ~= nil then
				local ok, erreur = (pcall :: any)(rafraichir, magasin, lignes)
				if not ok then
					warn(`[Classement] {erreur}`)
				end
			else
				afficherLocal(lignes)
			end
			task.wait(if magasin ~= nil then Config.Classement.IntervalleRafraichissement else 15)
		end
	end)
end

return ServiceClassement
