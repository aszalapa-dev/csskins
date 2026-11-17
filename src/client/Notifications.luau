--!strict
--[[
	Notifications.luau (client) — messages courts en haut de l'écran, grands textes (« INCROYABLE ! »),
	bandeau d'annonce serveur et carte de révélation d'un Snowpal.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalogue = require(ReplicatedStorage.Shared.Catalogue)
local Interface = require(script.Parent.Interface)

local creer = Interface.creer

local Notifications = {}

local pile: Frame? = nil
local MAX_VISIBLES = 3

local COULEURS_GENRE: { [string]: string } = {
	Info = "PanneauClair",
	Succes = "Succes",
	Erreur = "Danger",
	Cadeau = "Attention",
}

function Notifications.demarrer()
	pile = creer("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 112),
		Size = UDim2.fromOffset(520, 150),
		BackgroundTransparency = 1,
		ZIndex = 40,
		Parent = Interface.ecran(),
	}, {
		creer("UIListLayout", {
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local compteur = 0

-- Petit message qui disparaît tout seul
function Notifications.message(texte: string, genre: string?)
	local conteneur = pile
	if conteneur == nil then
		return
	end
	-- On garde au plus MAX_VISIBLES messages : le plus ancien part
	local visibles = {}
	for _, enfant in conteneur:GetChildren() do
		if enfant:IsA("Frame") then
			table.insert(visibles, enfant)
		end
	end
	table.sort(visibles, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #visibles >= MAX_VISIBLES do
		visibles[1]:Destroy()
		table.remove(visibles, 1)
	end

	compteur += 1
	local carte: Frame = creer("Frame", {
		LayoutOrder = compteur,
		Size = UDim2.fromOffset(500, 40),
		BackgroundColor3 = Interface.couleur(COULEURS_GENRE[genre or "Info"] or "PanneauClair"),
		ZIndex = 40,
		Parent = conteneur,
	}, { Interface.coins(12), Interface.contour(Color3.new(0, 0, 0), 2) })
	Interface.texte({
		Text = texte,
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		TailleMax = 22,
		ZIndex = 41,
		Parent = carte,
	})
	local grossissement: UIScale = creer("UIScale", { Scale = 0.6, Parent = carte })
	TweenService:Create(grossissement, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	if genre == "Erreur" then
		Interface.jouerSon("Erreur")
	else
		Interface.jouerSon("Notification")
	end
	Debris:AddItem(carte, 3.2)
end

-- Grand texte au centre de l'écran qui grossit puis s'efface
function Notifications.grandTexte(texte: string, teinte: Color3)
	local label = Interface.texte({
		Text = texte,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(760, 96),
		TextColor3 = teinte,
		TailleMax = 84,
		Rotation = -4,
		ZIndex = 60,
		Parent = Interface.ecran(),
	})
	local contour: UIStroke = creer("UIStroke", { Color = Color3.fromRGB(20, 30, 60), Thickness = 5, Parent = label })
	local grossissement: UIScale = creer("UIScale", { Scale = 0.2, Parent = label })
	TweenService
		:Create(grossissement, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	TweenService:Create(label, TweenInfo.new(0.35), { Rotation = 3 }):Play()
	task.delay(1.3, function()
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(contour, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end)
	Debris:AddItem(label, 1.8)
end

-- Texte « +123 ❄️ » qui monte et disparaît
function Notifications.gain(texte: string, teinte: Color3?)
	local label = Interface.texte({
		Text = texte,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-90, 90), 0.55, 0),
		Size = UDim2.fromOffset(320, 50),
		TextColor3 = teinte or Color3.fromRGB(170, 230, 255),
		TailleMax = 44,
		ZIndex = 55,
		Parent = Interface.ecran(),
	})
	local contour: UIStroke = creer("UIStroke", { Color = Color3.fromRGB(20, 30, 60), Thickness = 3, Parent = label })
	TweenService:Create(label, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = label.Position - UDim2.fromScale(0, 0.16),
		TextTransparency = 1,
	}):Play()
	TweenService:Create(contour, TweenInfo.new(1.1), { Transparency = 1 }):Play()
	Debris:AddItem(label, 1.2)
end

-- Bandeau d'annonce serveur (belles obtentions, tempête) + message dans le chat
function Notifications.annonce(texte: string, teinte: Color3)
	local bandeau: Frame = creer("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -60),
		Size = UDim2.fromOffset(700, 44),
		BackgroundColor3 = Interface.couleur("Fond"),
		ZIndex = 50,
		Parent = Interface.ecran(),
	}, { Interface.coins(14), Interface.contour(teinte, 3) })
	Interface.texte({
		Text = texte,
		Size = UDim2.new(1, -24, 1, -8),
		Position = UDim2.fromOffset(12, 4),
		TextColor3 = teinte,
		TailleMax = 24,
		ZIndex = 51,
		Parent = bandeau,
	})
	TweenService:Create(bandeau, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 62) })
		:Play()
	task.delay(4.5, function()
		TweenService:Create(bandeau, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, -60) }):Play()
	end)
	Debris:AddItem(bandeau, 5)

	-- Aussi dans le chat (si le canal par défaut existe)
	pcall(function()
		local canaux = TextChatService:FindFirstChild("TextChannels")
		local general = if canaux then canaux:FindFirstChild("RBXGeneral") else nil
		if general ~= nil and general:IsA("TextChannel") then
			general:DisplaySystemMessage(`<font color="#{teinte:ToHex()}">[Annonce] {texte}</font>`)
		end
	end)
end

-- Carte de révélation du Snowpal obtenu
function Notifications.revelation(id: string, nouveau: boolean)
	local definition = Catalogue.ParId[id]
	if definition == nil then
		return
	end
	local rarete = Config.Raretes[definition.Rarete]
	local teinte = Interface.rgb(rarete.Couleur)
	local carte: Frame = creer("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(230, 230),
		BackgroundColor3 = Interface.couleur("Fond"),
		ZIndex = 45,
		Parent = Interface.ecran(),
	}, { Interface.coins(20), Interface.contour(teinte, 5) })
	local icone = Interface.iconeSnowpal(id, false, true, 130)
	icone.AnchorPoint = Vector2.new(0.5, 0)
	icone.Position = UDim2.new(0.5, 0, 0, 8)
	icone.ZIndex = 46
	icone.Parent = carte
	Interface.texte({
		Text = definition.Nom,
		Position = UDim2.fromOffset(8, 140),
		Size = UDim2.new(1, -16, 0, 34),
		TailleMax = 30,
		ZIndex = 46,
		Parent = carte,
	})
	Interface.texte({
		Text = rarete.Nom,
		Position = UDim2.fromOffset(8, 174),
		Size = UDim2.new(1, -16, 0, 24),
		TextColor3 = teinte,
		TailleMax = 22,
		ZIndex = 46,
		Parent = carte,
	})
	if nouveau then
		Interface.texte({
			Text = "NOUVEAU !",
			Position = UDim2.fromOffset(8, 198),
			Size = UDim2.new(1, -16, 0, 24),
			TextColor3 = Interface.couleur("Attention"),
			TailleMax = 22,
			ZIndex = 46,
			Parent = carte,
		})
	end
	local grossissement: UIScale = creer("UIScale", { Scale = 0.1, Parent = carte })
	TweenService
		:Create(grossissement, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	task.delay(1.9, function()
		TweenService
			:Create(grossissement, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
			:Play()
	end)
	Debris:AddItem(carte, 2.2)
end

return Notifications
