--!strict
--[[
	ServiceBoutique.luau — gamepasses et produits développeur.
	- Un ID à 0 dans Config = « Bientôt » : rien n'est appelé, aucune erreur.
	- ProcessReceipt est idempotent : chaque PurchaseId traité est mémorisé dans les données du joueur,
	  et l'achat n'est confirmé à Roblox (PurchaseGranted) qu'après une sauvegarde réussie.
	- Aucun objet aléatoire payant : les produits donnent des boosts ou des flocons, jamais un tirage.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formules = require(ReplicatedStorage.Shared.Formules)
local Reseau = require(script.Parent.Reseau)
local ServiceDonnees = require(script.Parent.ServiceDonnees)
local ServiceProgression = require(script.Parent.ServiceProgression)
local ServiceTerrains = require(script.Parent.ServiceTerrains)
local Sessions = require(script.Parent.Sessions)

type Session = Sessions.Session
type ReglageProduit = {
	Id: number,
	Nom: string,
	Type: string,
	Boost: string?,
	Duree: number?,
	Secondes: number?,
	Minimum: number?,
}

local ServiceBoutique = {}

local PRODUITS = (Config.Produits :: any) :: { [string]: ReglageProduit }
local GAMEPASSES = (Config.Gamepasses :: any) :: { [string]: { Id: number, Nom: string } }

-- Active un gamepass pour la session et applique ses effets immédiats
function ServiceBoutique.activerPasse(session: Session, cle: string)
	if session.Passes[cle] then
		return
	end
	session.Passes[cle] = true
	session.Sale = true
	if cle == "SoclesBonus" then
		ServiceTerrains.rafraichir(session)
	elseif cle == "VIP" then
		ServiceProgression.majEtiquette(session)
	end
	ServiceTerrains.rafraichir(session)
end

-- Vérifie les gamepasses possédés (à la connexion). Appels protégés, hors du fil principal.
function ServiceBoutique.chargerPasses(session: Session)
	for cle, reglage in GAMEPASSES do
		if reglage.Id ~= 0 then
			task.spawn(function()
				local ok, possede = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(session.Joueur.UserId, reglage.Id)
				end)
				if ok and possede and Sessions.obtenir(session.Joueur) == session then
					ServiceBoutique.activerPasse(session, cle)
				end
			end)
		end
	end
end

-- Donne le contenu d'un produit développeur
local function accorder(session: Session, cle: string, produit: ReglageProduit)
	if produit.Type == "Boost" and produit.Boost ~= nil and produit.Duree ~= nil then
		Sessions.ajouterBoost(session, produit.Boost, produit.Duree)
		Reseau.notifier(session.Joueur, `⚡ {produit.Nom} activé !`, "Succes")
	elseif produit.Type == "Flocons" and produit.Secondes ~= nil and produit.Minimum ~= nil then
		local gainParSeconde =
			Formules.gainEstimeParSeconde(session.Donnees, Sessions.multiplicateur(session), Sessions.socles(session))
		local flocons = Formules.floconsPaquet(produit.Secondes, produit.Minimum, session.Donnees, gainParSeconde)
		Sessions.ajouterFlocons(session, flocons)
		Reseau.effet(session.Joueur, "Recompense", { Flocons = flocons, Titre = produit.Nom })
	else
		warn(`[Boutique] Produit mal configuré : {cle}`)
	end
end

local function produitParId(idProduit: number): (string?, ReglageProduit?)
	for cle, produit in PRODUITS do
		if produit.Id ~= 0 and produit.Id == idProduit then
			return cle, produit
		end
	end
	return nil, nil
end

local function traiterRecu(recu: { [string]: any }): Enum.ProductPurchaseDecision
	local joueur = Players:GetPlayerByUserId(recu.PlayerId)
	local session = if joueur then Sessions.obtenir(joueur) else nil
	if joueur == nil or session == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox réessaiera plus tard
	end
	local cle, produit = produitParId(recu.ProductId)
	if cle == nil or produit == nil then
		warn(`[Boutique] Reçu pour un produit inconnu : {recu.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local traites = session.Donnees.AchatsTraites
	local idAchat = tostring(recu.PurchaseId)
	if table.find(traites, idAchat) == nil then
		accorder(session, cle, produit)
		table.insert(traites, idAchat)
		while #traites > Config.Donnees.AchatsMemorises do
			table.remove(traites, 1)
		end
		Sessions.envoyer(session)
	end
	-- Déjà accordé (maintenant ou lors d'un essai précédent) : on confirme seulement si c'est sauvegardé.
	if ServiceDonnees.sauvegarder(joueur.UserId, session.Donnees, false) then
		session.DerniereSauvegarde = os.clock()
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function ServiceBoutique.initialiser()
	MarketplaceService.ProcessReceipt = function(recu: any): Enum.ProductPurchaseDecision
		local ok, decision = pcall(traiterRecu, recu)
		if ok then
			return decision
		end
		warn(`[Boutique] Erreur ProcessReceipt : {decision}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Gamepass acheté pendant la partie : effet immédiat, sans reconnexion
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(joueur: Player, idPasse: number, achete: boolean)
		if not achete then
			return
		end
		local session = Sessions.obtenir(joueur)
		if session == nil then
			return
		end
		for cle, reglage in GAMEPASSES do
			if reglage.Id ~= 0 and reglage.Id == idPasse then
				ServiceBoutique.activerPasse(session, cle)
				Reseau.effet(joueur, "Achat", { Nom = cle })
				Reseau.notifier(joueur, `Merci ! « {reglage.Nom} » est activé 💙`, "Succes")
			end
		end
	end)
end

return ServiceBoutique
