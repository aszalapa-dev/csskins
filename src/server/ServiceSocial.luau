--!strict
--[[
	ServiceSocial.luau — bonus d'amis, tempête de neige régulière (événement visible par tous).
	Les annonces des belles obtentions sont envoyées par ServiceBoule / ServiceProgression.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Reseau = require(script.Parent.Reseau)
local ServiceTerrains = require(script.Parent.ServiceTerrains)
local Sessions = require(script.Parent.Sessions)

local ServiceSocial = {}

-- Résultat d'amitié mémorisé par paire de joueurs (un seul appel web par paire)
local amities: { [string]: boolean } = {}

local function clePaire(a: number, b: number): string
	return if a < b then `{a}_{b}` else `{b}_{a}`
end

local function sontAmis(a: Player, b: Player): boolean
	local cle = clePaire(a.UserId, b.UserId)
	local connu = amities[cle]
	if connu ~= nil then
		return connu
	end
	local ok, resultat = pcall(function()
		return a:IsFriendsWithAsync(b.UserId)
	end)
	if ok then
		amities[cle] = resultat
		return resultat
	end
	return false
end

-- Recompte les amis présents pour chaque joueur
function ServiceSocial.majAmis()
	for joueur, session in Sessions.toutes() do
		local nombre = 0
		for autre in Sessions.toutes() do
			if autre ~= joueur and joueur.Parent == Players and autre.Parent == Players and sontAmis(joueur, autre) then
				nombre += 1
			end
		end
		if nombre ~= session.Amis then
			local gagne = nombre > session.Amis
			session.Amis = nombre
			session.Sale = true
			ServiceTerrains.rafraichir(session)
			if gagne then
				local bonus = math.floor(math.min(nombre * Config.Social.BonusParAmi, Config.Social.BonusAmisMax) * 100)
				Reseau.notifier(joueur, `👫 Bonus d'amis : +{bonus} % de flocons !`, "Succes")
			end
		end
	end
end

function ServiceSocial.lancerTempete()
	if Workspace:GetAttribute("Tempete") == true then
		return
	end
	Workspace:SetAttribute("Tempete", true)
	Reseau.effetTous("Annonce", {
		Texte = `🌨️ TEMPÊTE DE NEIGE ! Les boules grossissent x{Config.Tempete.MultiplicateurCroissance} pendant {Config.Tempete.Duree} s !`,
		Couleur = { 150, 220, 255 },
	})
	task.delay(Config.Tempete.Duree, function()
		Workspace:SetAttribute("Tempete", false)
		Reseau.notifierTous("La tempête se calme... À la prochaine !", "Info")
	end)
end

function ServiceSocial.demarrer()
	Workspace:SetAttribute("Tempete", false)
	task.spawn(function()
		while true do
			task.wait(Config.Social.IntervalleVerifAmis)
			local ok, erreur = (pcall :: any)(ServiceSocial.majAmis)
			if not ok then
				warn(`[Social] {erreur}`)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Tempete.Intervalle)
			if next(Sessions.toutes()) ~= nil then
				ServiceSocial.lancerTempete()
			end
		end
	end)
end

return ServiceSocial
