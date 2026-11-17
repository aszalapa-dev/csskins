--!strict
--[[
	Interface.luau (client) — boîte à outils pour construire l'interface par code.
	Toute l'interface est dessinée pour un écran de référence de 1100 x 620 puis mise à l'échelle
	avec un UIScale : elle reste lisible sur téléphone comme sur PC, avec de gros boutons.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalogue = require(ReplicatedStorage.Shared.Catalogue)

local Interface = {}

local REFERENCE = Vector2.new(1100, 620)
Interface.POLICE = Enum.Font.FredokaOne

function Interface.couleur(nom: string): Color3
	local c = (Config.Couleurs :: { [string]: { number } })[nom] or { 255, 255, 255 }
	return Color3.fromRGB(c[1], c[2], c[3])
end

function Interface.rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

--[[
	Crée une instance : creer("Frame", { Size = ... }, { enfants... }).
	Renvoie `any` exprès : les appelants annotent le type voulu (local f: Frame = creer(...)).
]]
function Interface.creer(classe: string, proprietes: { [string]: any }?, enfants: { any }?): any
	local instance = Instance.new(classe) :: any
	if proprietes then
		for cle, valeur in proprietes do
			if cle ~= "Parent" then
				instance[cle] = valeur
			end
		end
	end
	if enfants then
		for _, enfant in enfants do
			enfant.Parent = instance
		end
	end
	if proprietes and proprietes.Parent then
		instance.Parent = proprietes.Parent
	end
	return instance
end

local creer = Interface.creer

function Interface.coins(rayon: number): any
	return creer("UICorner", { CornerRadius = UDim.new(0, rayon) })
end

function Interface.contour(teinte: Color3, epaisseur: number): any
	return creer("UIStroke", { Color = teinte, Thickness = epaisseur, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

-- ───────────── Sons ─────────────

local sons: { [string]: Sound } = {}

function Interface.jouerSon(nom: string)
	local id = (Config.Sons :: { [string]: string })[nom]
	if id == nil or id == "" then
		return
	end
	local son: Sound? = sons[nom]
	if son == nil then
		local nouveau: Sound =
			creer("Sound", { Name = "Son" .. nom, SoundId = id, Volume = Config.VolumeSons, Parent = SoundService })
		sons[nom] = nouveau
		son = nouveau
	end
	if son then
		SoundService:PlayLocalSound(son)
	end
end

-- ───────────── Écran principal et mise à l'échelle ─────────────

local ecran: ScreenGui? = nil
local echelle: UIScale? = nil

local function majEchelle()
	local camera = Workspace.CurrentCamera
	if camera == nil or echelle == nil then
		return
	end
	local taille = camera.ViewportSize
	echelle.Scale = math.clamp(math.min(taille.X / REFERENCE.X, taille.Y / REFERENCE.Y), 0.45, 1.6)
end

-- Renvoie le ScreenGui du jeu (créé au premier appel). Il survit à la réapparition du personnage.
function Interface.ecran(): ScreenGui
	if ecran ~= nil then
		return ecran
	end
	local joueur = Players.LocalPlayer
	local gui: ScreenGui = creer("ScreenGui", {
		Name = "SnowpalRollers",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 5,
	})
	local nouvelleEchelle: UIScale = creer("UIScale", { Parent = gui })
	echelle = nouvelleEchelle
	ecran = gui
	majEchelle()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(majEchelle)
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(majEchelle)
	gui.Parent = joueur:WaitForChild("PlayerGui")
	return gui
end

-- ───────────── Composants ─────────────

function Interface.texte(proprietes: { [string]: any }): TextLabel
	local base = {
		BackgroundTransparency = 1,
		Font = Interface.POLICE,
		TextColor3 = Interface.couleur("Texte"),
		TextScaled = true,
		Text = "",
	}
	for cle, valeur in proprietes do
		base[cle] = valeur
	end
	local label: TextLabel = creer("TextLabel", base)
	-- Limite la taille du texte pour garder un rendu régulier
	creer("UITextSizeConstraint", { MaxTextSize = proprietes.TailleMax or 28, MinTextSize = 8, Parent = label })
	return label
end

-- Gros bouton arrondi avec petit effet d'appui et son de clic
function Interface.bouton(proprietes: { [string]: any }, action: () -> ()): TextButton
	local teinte = proprietes.BackgroundColor3 or Interface.couleur("Principal")
	local base = {
		AutoButtonColor = false,
		BackgroundColor3 = teinte,
		Font = Interface.POLICE,
		TextColor3 = Interface.couleur("Texte"),
		TextScaled = true,
		Text = "",
	}
	for cle, valeur in proprietes do
		if cle ~= "TailleMax" then
			base[cle] = valeur
		end
	end
	local bouton: TextButton = creer("TextButton", base, {
		Interface.coins(14),
		creer("UITextSizeConstraint", { MaxTextSize = proprietes.TailleMax or 24, MinTextSize = 8 }),
		creer("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
	})
	local stroke: UIStroke = creer("UIStroke", {
		Color = Color3.new(0, 0, 0),
		Transparency = 0.75,
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = bouton,
	})
	local _ = stroke
	local grossissement: UIScale = creer("UIScale", { Parent = bouton })
	bouton.MouseButton1Down:Connect(function()
		TweenService:Create(grossissement, TweenInfo.new(0.06), { Scale = 0.93 }):Play()
	end)
	local function relacher()
		TweenService:Create(grossissement, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end
	bouton.MouseButton1Up:Connect(relacher)
	bouton.MouseLeave:Connect(relacher)
	bouton.Activated:Connect(function()
		Interface.jouerSon("Clic")
		action()
	end)
	return bouton
end

export type Fenetre = {
	Racine: Frame,
	Contenu: Frame,
	Titre: TextLabel,
	ouvrir: () -> (),
	fermer: () -> (),
	estOuverte: () -> boolean,
}

local fenetres: { Fenetre } = {}

-- Fenêtre modale centrée (une seule ouverte à la fois), avec titre et bouton de fermeture
function Interface.fenetre(titre: string, largeur: number, hauteur: number): Fenetre
	local racine: Frame = creer("Frame", {
		Name = "Fenetre" .. titre,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(largeur, hauteur),
		BackgroundColor3 = Interface.couleur("Fond"),
		Visible = false,
		ZIndex = 20,
		Parent = Interface.ecran(),
	}, {
		Interface.coins(22),
		Interface.contour(Interface.couleur("Principal"), 4),
	})
	-- Bloque les clics vers le jeu derrière la fenêtre
	creer("TextButton", {
		Name = "Bloqueur",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 20,
		Parent = racine,
	})
	local labelTitre = Interface.texte({
		Name = "Titre",
		Text = titre,
		Position = UDim2.fromOffset(24, 10),
		Size = UDim2.new(1, -110, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		TailleMax = 34,
		ZIndex = 21,
		Parent = racine,
	})
	local contenu: Frame = creer("Frame", {
		Name = "Contenu",
		Position = UDim2.fromOffset(16, 62),
		Size = UDim2.new(1, -32, 1, -78),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = racine,
	})
	local grossissement: UIScale = creer("UIScale", { Parent = racine })

	local fenetre = {} :: Fenetre
	fenetre.Racine = racine
	fenetre.Contenu = contenu
	fenetre.Titre = labelTitre
	function fenetre.fermer()
		racine.Visible = false
	end
	function fenetre.estOuverte(): boolean
		return racine.Visible
	end
	function fenetre.ouvrir()
		for _, autre in fenetres do
			if autre ~= fenetre then
				autre.fermer()
			end
		end
		racine.Visible = true
		grossissement.Scale = 0.85
		TweenService
			:Create(grossissement, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
			:Play()
	end
	local fermer = Interface.bouton({
		Name = "Fermer",
		Text = "✕",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(56, 46),
		BackgroundColor3 = Interface.couleur("Danger"),
		TailleMax = 28,
		ZIndex = 22,
	}, fenetre.fermer)
	fermer.Parent = racine
	table.insert(fenetres, fenetre)
	return fenetre
end

function Interface.fermerFenetres()
	for _, fenetre in fenetres do
		fenetre.fermer()
	end
end

-- Liste défilante verticale (les enfants s'empilent automatiquement)
function Interface.liste(parent: Instance, espacement: number): ScrollingFrame
	local liste: ScrollingFrame = creer("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Interface.couleur("Principal"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 21,
		Parent = parent,
	}, {
		creer("UIListLayout", { Padding = UDim.new(0, espacement), SortOrder = Enum.SortOrder.LayoutOrder }),
		creer(
			"UIPadding",
			{ PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 6), PaddingTop = UDim.new(0, 2) }
		),
	})
	return liste
end

local CHAPEAUX: { [string]: string } = {
	Aucun = "",
	HautDeForme = "🎩",
	Bonnet = "🧶",
	Couronne = "👑",
	Sapin = "🌲",
	Etoile = "⭐",
	Cristaux = "💎",
	Aureole = "✨",
}

-- Petite icône de Snowpal dessinée avec des ronds (aucune image à téléverser).
-- `decouvert` = false -> silhouette sombre avec « ? ».
function Interface.iconeSnowpal(id: string, dore: boolean, decouvert: boolean, taille: number): Frame
	local definition = Catalogue.ParId[id]
	local corps = Color3.fromRGB(40, 52, 80)
	local accent = Color3.fromRGB(60, 74, 104)
	if decouvert and definition ~= nil then
		corps = if dore then Interface.couleur("Dore") else Interface.rgb(definition.Corps)
		accent = Interface.rgb(definition.Accent)
	end
	local cadre: Frame =
		creer("Frame", { Size = UDim2.fromOffset(taille, taille), BackgroundTransparency = 1, ZIndex = 22 })
	local function rond(diametre: number, y: number)
		creer("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, y),
			Size = UDim2.fromScale(diametre, diametre),
			BackgroundColor3 = corps,
			ZIndex = 22,
			Parent = cadre,
		}, { creer("UICorner", { CornerRadius = UDim.new(1, 0) }), Interface.contour(Color3.fromRGB(20, 30, 50), 2) })
	end
	rond(0.52, 0.72)
	rond(0.4, 0.42)
	-- écharpe
	creer("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.56),
		Size = UDim2.fromScale(0.36, 0.08),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 23,
		Parent = cadre,
	}, { Interface.coins(4) })
	local symbole = if not decouvert then "?" elseif definition then CHAPEAUX[definition.Chapeau] or "" else ""
	if symbole ~= "" then
		Interface.texte({
			Text = symbole,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = if decouvert then UDim2.fromScale(0.5, 0.17) else UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromScale(0.36, 0.3),
			TailleMax = 40,
			ZIndex = 24,
			Parent = cadre,
		})
	end
	return cadre
end

return Interface
