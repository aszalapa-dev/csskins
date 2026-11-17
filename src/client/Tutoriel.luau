--!strict
--[[
	Tutoriel.luau (client) — guide de première connexion, en 4 étapes courtes.
	Il avance tout seul quand le joueur fait l'action demandée, et peut être passé à tout moment.
	Le serveur enregistre « Tutoriel = true » pour ne plus jamais le montrer.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Etat = require(script.Parent.Etat)
local Interface = require(script.Parent.Interface)

local creer = Interface.creer
local joueur = Players.LocalPlayer

local Tutoriel = {}

local panneau: Frame? = nil
local texte: TextLabel? = nil
local etape = 0
local actif = false

local function terminer()
	if not actif then
		return
	end
	actif = false
	Etat.action("TutorielFini")
	if panneau then
		panneau:Destroy()
		panneau = nil
	end
end

local function afficher(numero: number)
	etape = numero
	local message = Config.Tutoriel[numero]
	if message == nil then
		terminer()
		return
	end
	if texte then
		texte.Text = `{numero}/{#Config.Tutoriel}  {message}`
	end
	if panneau then
		local grossissement = panneau:FindFirstChildOfClass("UIScale")
		if grossissement then
			grossissement.Scale = 0.85
			TweenService:Create(grossissement, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end
	Interface.jouerSon("Notification")
end

-- Appelé par le script principal quand une boule vient d'être livrée
function Tutoriel.surLivraison()
	if actif and etape <= 2 then
		afficher(3)
		task.delay(7, function()
			if actif and etape == 3 then
				afficher(4)
				task.delay(8, function()
					if actif and etape == 4 then
						terminer()
					end
				end)
			end
		end)
	end
end

function Tutoriel.demarrer()
	if actif then
		return
	end
	actif = true
	local cadre: Frame = creer("Frame", {
		Name = "Tutoriel",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -134),
		Size = UDim2.fromOffset(640, 70),
		BackgroundColor3 = Interface.couleur("Fond"),
		ZIndex = 10,
		Parent = Interface.ecran(),
	}, { Interface.coins(16), Interface.contour(Interface.couleur("Attention"), 3), creer("UIScale", {}) })
	panneau = cadre
	texte = Interface.texte({
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -140, 1, -12),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		TailleMax = 20,
		ZIndex = 11,
		Parent = cadre,
	})
	local passer = Interface.bouton({
		Text = "Passer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(108, 50),
		BackgroundColor3 = Interface.couleur("Grise"),
		TailleMax = 20,
		ZIndex = 11,
	}, terminer)
	passer.Parent = cadre
	afficher(1)

	-- Étape 1 -> 2 : dès que la boule est assez grosse pour être livrée
	task.spawn(function()
		while actif and etape == 1 do
			local taille = joueur:GetAttribute("TailleBoule")
			if type(taille) == "number" and taille >= Config.Boule.TailleMinLivraison then
				afficher(2)
			end
			task.wait(0.3)
		end
	end)
end

return Tutoriel
