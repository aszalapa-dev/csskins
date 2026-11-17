--!strict
--[[
	Badges.luau — attribution des badges. Un ID à 0 dans Config.Badges est simplement ignoré.
	Tous les appels réseau sont protégés par pcall et lancés hors du fil principal.
]]

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Badges = {}

-- Badges déjà traités pendant cette session (évite de rappeler l'API)
local traites: { [Player]: { [string]: boolean } } = {}

Players.PlayerRemoving:Connect(function(joueur)
	traites[joueur] = nil
end)

function Badges.donner(joueur: Player, cle: string)
	local reglage = (Config.Badges :: any)[cle] :: { Id: number }?
	if reglage == nil or reglage.Id == 0 then
		return
	end
	local parJoueur = traites[joueur]
	if parJoueur == nil then
		parJoueur = {}
		traites[joueur] = parJoueur
	end
	if parJoueur[cle] then
		return
	end
	parJoueur[cle] = true
	task.spawn(function()
		local ok, possede = pcall(function()
			return BadgeService:UserHasBadgeAsync(joueur.UserId, reglage.Id)
		end)
		if ok and not possede and joueur.Parent == Players then
			pcall(function()
				BadgeService:AwardBadge(joueur.UserId, reglage.Id)
			end)
		end
	end)
end

return Badges
