--!strict
--[[
	HUD.luau (client) — affichage permanent : flocons, revenu, boosts, jauge de la boule et barre de
	gros boutons en bas au centre (zone libre sur téléphone, entre le joystick et le bouton de saut).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Formules = require(ReplicatedStorage.Shared.Formules)
local Recompenses = require(ReplicatedStorage.Shared.Recompenses)
local Etat = require(script.Parent.Etat)
local Interface = require(script.Parent.Interface)

local creer = Interface.creer
local joueur = Players.LocalPlayer

local HUD = {}

local texteFlocons: TextLabel
local texteRevenu: TextLabel
local texteBoosts: TextLabel
local jauge: Frame
local remplissage: Frame
local texteJauge: TextLabel
local pastilles: { [string]: Frame } = {}
local floconsAffiches = 0

-- Bouton de la barre du bas : emoji + libellé + pastille rouge de notification
local function boutonBarre(
	parent: Instance,
	ordre: number,
	emoji: string,
	libelle: string,
	teinte: Color3,
	action: () -> ()
): TextButton
	local bouton = Interface.bouton({
		Name = libelle,
		LayoutOrder = ordre,
		Size = UDim2.fromOffset(92, 78),
		BackgroundColor3 = teinte,
		Text = "",
	}, action)
	Interface.texte({
		Text = emoji,
		Position = UDim2.fromOffset(0, -2),
		Size = UDim2.new(1, 0, 0, 48),
		TailleMax = 40,
		Parent = bouton,
	})
	Interface.texte({
		Text = libelle,
		Position = UDim2.new(0, -4, 1, -24),
		Size = UDim2.new(1, 8, 0, 22),
		TailleMax = 18,
		Parent = bouton,
	})
	local pastille: Frame = creer("Frame", {
		Name = "Pastille",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 12, 0, -10),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Interface.couleur("Danger"),
		Visible = false,
		ZIndex = 3,
		Parent = bouton,
	}, { creer("UICorner", { CornerRadius = UDim.new(1, 0) }), Interface.contour(Color3.new(1, 1, 1), 2) })
	Interface.texte({ Text = "!", Size = UDim2.fromScale(1, 1), TailleMax = 20, ZIndex = 4, Parent = pastille })
	pastilles[libelle] = pastille
	bouton.Parent = parent
	return bouton
end

-- Y a-t-il quelque chose à réclamer dans le menu Cadeaux ?
local function cadeauxEnAttente(etat: { [string]: any }): boolean
	if etat.Quotidien.Disponible then
		return true
	end
	local secondes = etat.Cadeaux.Secondes + Etat.depuisReception()
	for indice, cadeau in Config.Cadeaux do
		if not etat.Cadeaux.Reclames[tostring(indice)] and secondes >= cadeau.Minutes * 60 then
			return true
		end
	end
	for _, quete in etat.Quetes do
		if not quete.Reclamee and Recompenses.queteTerminee(quete) then
			return true
		end
	end
	return false
end

local function ameliorationAbordable(etat: { [string]: any }): boolean
	for _, nom in Config.OrdreAmeliorations do
		local prix = Formules.prixAmelioration(nom, etat.Ameliorations[nom] or 0)
		if prix ~= nil and etat.Flocons >= prix then
			return true
		end
	end
	local zone = Config.Zones[etat.ZoneMax + 1]
	return zone ~= nil and etat.Flocons >= zone.Prix
end

local function majEtat(etat: { [string]: any })
	-- Compteur animé
	local depart = floconsAffiches
	local arrivee = etat.Flocons
	floconsAffiches = arrivee
	local valeur: NumberValue = creer("NumberValue", { Value = depart })
	valeur.Changed:Connect(function(v)
		texteFlocons.Text = "❄️ " .. Formules.formater(v)
	end)
	local tween = TweenService:Create(valeur, TweenInfo.new(0.3), { Value = arrivee })
	tween.Completed:Connect(function()
		texteFlocons.Text = "❄️ " .. Formules.formater(arrivee)
		valeur:Destroy()
	end)
	tween:Play()

	texteRevenu.Text = `+{Formules.formater(etat.Revenu)}/s   x{string.format("%.2f", etat.Multiplicateur)}`
	pastilles["Améliorer"].Visible = ameliorationAbordable(etat)
	pastilles["Cadeaux"].Visible = cadeauxEnAttente(etat)
	local prixRebirth = Formules.prixRebirth(etat.Rebirths)
	pastilles["Hiver"].Visible = prixRebirth ~= nil and etat.Flocons >= prixRebirth
end

-- Mise à jour légère 4 fois par seconde : jauge de boule, minuteries des boosts
local function majRapide()
	local etat = Etat.valeur
	local taille = joueur:GetAttribute("TailleBoule")
	if etat ~= nil and type(taille) == "number" and taille > 0 then
		local tailleMax = Formules.tailleMax(etat.Ameliorations.Gants or 0)
		local progression = math.clamp(
			(taille - Config.Boule.TailleDepart) / math.max(tailleMax - Config.Boule.TailleDepart, 0.01),
			0,
			1
		)
		jauge.Visible = true
		remplissage.Size = UDim2.fromScale(progression, 1)
		if joueur:GetAttribute("BouleMax") == true then
			remplissage.BackgroundColor3 = Interface.couleur("Succes")
			texteJauge.Text = "BOULE MAX ! Ramène-la à ton atelier ➜"
		else
			remplissage.BackgroundColor3 = Interface.couleur("Principal")
			texteJauge.Text = string.format("Boule : %.1f / %.1f", taille, tailleMax)
		end
	else
		jauge.Visible = false
	end

	if etat ~= nil then
		local morceaux = {}
		local ecoule = Etat.depuisReception()
		local restant = (etat.Boosts.Flocons or 0) - ecoule
		if restant > 0 then
			table.insert(morceaux, `💎 x2 {Formules.formaterDuree(restant)}`)
		end
		restant = (etat.Boosts.Croissance or 0) - ecoule
		if restant > 0 then
			table.insert(morceaux, `🌨️ x2 {Formules.formaterDuree(restant)}`)
		end
		if Workspace:GetAttribute("Tempete") == true then
			table.insert(morceaux, "🌪️ TEMPÊTE x2")
		end
		if etat.Amis > 0 then
			local bonus = math.min(etat.Amis * Config.Social.BonusParAmi, Config.Social.BonusAmisMax)
			table.insert(morceaux, `👫 +{math.floor(bonus * 100)} %`)
		end
		texteBoosts.Text = table.concat(morceaux, "   ")
		pastilles["Cadeaux"].Visible = cadeauxEnAttente(etat)
	end
end

--[[
	`ouvrir` : table { Ameliorer = function, Index = ..., Cadeaux = ..., Boutique = ..., Rebirth = ... }
	fournie par Menus pour brancher les boutons.
]]
function HUD.demarrer(ouvrir: { [string]: () -> () })
	local ecran = Interface.ecran()

	-- Haut : flocons + revenu
	local pilule: Frame = creer("Frame", {
		Name = "Flocons",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(300, 52),
		BackgroundColor3 = Interface.couleur("Fond"),
		Parent = ecran,
	}, { Interface.coins(26), Interface.contour(Interface.couleur("Principal"), 3) })
	texteFlocons = Interface.texte({
		Text = "❄️ 0",
		Position = UDim2.fromOffset(14, 4),
		Size = UDim2.new(1, -28, 0, 30),
		TailleMax = 30,
		Parent = pilule,
	})
	texteRevenu = Interface.texte({
		Text = "+0/s",
		Position = UDim2.fromOffset(14, 32),
		Size = UDim2.new(1, -28, 0, 16),
		TextColor3 = Interface.couleur("TexteDoux"),
		TailleMax = 15,
		Parent = pilule,
	})
	texteBoosts = Interface.texte({
		Name = "Boosts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 62),
		Size = UDim2.fromOffset(560, 22),
		TextColor3 = Interface.couleur("Attention"),
		TextStrokeTransparency = 0.4,
		TailleMax = 20,
		Parent = ecran,
	})

	-- Bas : barre de boutons
	local barre: Frame = creer("Frame", {
		Name = "Barre",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(500, 78),
		BackgroundTransparency = 1,
		Parent = ecran,
	}, {
		creer("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	boutonBarre(barre, 1, "⬆️", "Améliorer", Interface.couleur("Succes"), ouvrir.Ameliorer)
	boutonBarre(barre, 2, "📖", "Index", Interface.couleur("Principal"), ouvrir.Index)
	boutonBarre(barre, 3, "🎁", "Cadeaux", Interface.couleur("Attention"), ouvrir.Cadeaux)
	boutonBarre(barre, 4, "🛒", "Boutique", Color3.fromRGB(240, 110, 180), ouvrir.Boutique)
	boutonBarre(barre, 5, "⭐", "Hiver", Color3.fromRGB(170, 110, 255), ouvrir.Rebirth)

	-- Jauge de la boule, juste au-dessus de la barre
	jauge = creer("Frame", {
		Name = "JaugeBoule",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -96),
		Size = UDim2.fromOffset(420, 30),
		BackgroundColor3 = Interface.couleur("Fond"),
		Visible = false,
		Parent = ecran,
	}, { Interface.coins(15), Interface.contour(Color3.new(1, 1, 1), 2) })
	remplissage = creer("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Interface.couleur("Principal"),
		Parent = jauge,
	}, { Interface.coins(15) })
	texteJauge = Interface.texte({
		Size = UDim2.new(1, -16, 1, -4),
		Position = UDim2.fromOffset(8, 2),
		TextStrokeTransparency = 0.5,
		TailleMax = 20,
		ZIndex = 2,
		Parent = jauge,
	})

	Etat.surChangement(majEtat)
	task.spawn(function()
		while true do
			majRapide()
			task.wait(0.25)
		end
	end)
end

return HUD
