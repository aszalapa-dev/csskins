--!strict
--[[
	ConstructeurSnowpal.luau — fabrique le modèle 3D d'un Snowpal uniquement avec des Parts.
	Toutes les pièces sont ancrées et sans collision (décor du terrain).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalogue = require(ReplicatedStorage.Shared.Catalogue)
local Formules = require(ReplicatedStorage.Shared.Formules)

local ConstructeurSnowpal = {}

local function couleur(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function piece(
	modele: Model,
	forme: Enum.PartType,
	taille: Vector3,
	cframe: CFrame,
	teinte: Color3,
	materiau: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Shape = forme
	part.Size = taille
	part.CFrame = cframe
	part.Color = teinte
	part.Material = materiau or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = modele
	return part
end

-- Construit le chapeau au-dessus de la tête. `sommet` = CFrame du haut de la tête, `e` = échelle.
local function chapeau(
	modele: Model,
	genre: Catalogue.Chapeau,
	sommet: CFrame,
	e: number,
	accent: Color3,
	neon: Enum.Material
)
	local couche = CFrame.Angles(0, 0, math.rad(90)) -- les cylindres sont couchés par défaut
	if genre == "HautDeForme" then
		piece(
			modele,
			Enum.PartType.Cylinder,
			Vector3.new(0.15, 1.6, 1.6) * e,
			sommet * CFrame.new(0, 0.05 * e, 0) * couche,
			accent
		)
		piece(
			modele,
			Enum.PartType.Cylinder,
			Vector3.new(0.9, 1, 1) * e,
			sommet * CFrame.new(0, 0.55 * e, 0) * couche,
			accent
		)
	elseif genre == "Bonnet" then
		piece(modele, Enum.PartType.Ball, Vector3.new(1.25, 1.1, 1.25) * e, sommet * CFrame.new(0, 0.05 * e, 0), accent)
		piece(
			modele,
			Enum.PartType.Ball,
			Vector3.new(0.45, 0.45, 0.45) * e,
			sommet * CFrame.new(0, 0.7 * e, 0),
			Color3.new(1, 1, 1)
		)
	elseif genre == "Couronne" then
		piece(
			modele,
			Enum.PartType.Cylinder,
			Vector3.new(0.35, 1.15, 1.15) * e,
			sommet * CFrame.new(0, 0.1 * e, 0) * couche,
			accent,
			neon
		)
		for i = 0, 4 do
			local angle = CFrame.Angles(0, math.rad(i * 72), 0)
			piece(
				modele,
				Enum.PartType.Block,
				Vector3.new(0.22, 0.45, 0.22) * e,
				sommet * angle * CFrame.new(0, 0.45 * e, 0.45 * e),
				accent,
				neon
			)
		end
	elseif genre == "Sapin" then
		for i = 0, 2 do
			local largeur = (1.3 - i * 0.4) * e
			piece(
				modele,
				Enum.PartType.Block,
				Vector3.new(largeur, 0.45 * e, largeur),
				sommet * CFrame.new(0, (0.2 + i * 0.42) * e, 0) * CFrame.Angles(0, math.rad(i * 45), 0),
				accent
			)
		end
	elseif genre == "Etoile" then
		for i = 0, 1 do
			piece(
				modele,
				Enum.PartType.Block,
				Vector3.new(0.9, 0.9, 0.2) * e,
				sommet * CFrame.new(0, 0.75 * e, 0) * CFrame.Angles(0, 0, math.rad(i * 45)),
				accent,
				Enum.Material.Neon
			)
		end
	elseif genre == "Cristaux" then
		for i = 0, 2 do
			piece(
				modele,
				Enum.PartType.Block,
				Vector3.new(0.3, 1 + (i % 2) * 0.4, 0.3) * e,
				sommet
					* CFrame.Angles(0, math.rad(i * 120), 0)
					* CFrame.new(0, 0.3 * e, 0.3 * e)
					* CFrame.Angles(math.rad(25), 0, 0),
				accent,
				Enum.Material.Neon
			)
		end
	elseif genre == "Aureole" then
		for i = 0, 7 do
			piece(
				modele,
				Enum.PartType.Ball,
				Vector3.new(0.3, 0.3, 0.3) * e,
				sommet * CFrame.Angles(0, math.rad(i * 45), 0) * CFrame.new(0, 0.6 * e, 0.6 * e),
				accent,
				Enum.Material.Neon
			)
		end
	end
end

--[[
	Construit un Snowpal posé sur `base` (CFrame du dessus du socle, regard vers -Z).
	Renvoie le Model (à parenter par l'appelant).
]]
function ConstructeurSnowpal.construire(id: string, dore: boolean, base: CFrame): Model?
	local definition = Catalogue.ParId[id]
	if definition == nil then
		return nil
	end
	local rarete = Config.Raretes[definition.Rarete]
	local e = 1 + 0.07 * (definition.Rarete - 1) -- les plus rares sont un peu plus grands
	local corps = if dore then couleur(Config.Couleurs.Dore) else couleur(definition.Corps)
	local accent = couleur(definition.Accent)
	local materiauCorps = if dore then Enum.Material.Foil else Enum.Material.SmoothPlastic
	local neon = if definition.Brillant or dore then Enum.Material.Neon else Enum.Material.SmoothPlastic

	local modele = Instance.new("Model")
	modele.Name = if dore then id .. "_D" else id

	-- Trois boules empilées
	local bas =
		piece(modele, Enum.PartType.Ball, Vector3.one * 2.4 * e, base * CFrame.new(0, 1.1 * e, 0), corps, materiauCorps)
	piece(modele, Enum.PartType.Ball, Vector3.one * 1.8 * e, base * CFrame.new(0, 2.6 * e, 0), corps, materiauCorps)
	local tete = piece(
		modele,
		Enum.PartType.Ball,
		Vector3.one * 1.3 * e,
		base * CFrame.new(0, 3.75 * e, 0),
		corps,
		materiauCorps
	)
	modele.PrimaryPart = bas

	-- Écharpe, boutons, yeux, nez
	piece(
		modele,
		Enum.PartType.Cylinder,
		Vector3.new(0.3, 1.5, 1.5) * e,
		base * CFrame.new(0, 3.25 * e, 0) * CFrame.Angles(0, 0, math.rad(90)),
		accent,
		neon
	)
	for i = 0, 1 do
		piece(
			modele,
			Enum.PartType.Ball,
			Vector3.one * 0.25 * e,
			base * CFrame.new(0, (2.4 + i * 0.5) * e, -0.88 * e),
			accent,
			neon
		)
	end
	local noir = Color3.fromRGB(30, 30, 40)
	piece(modele, Enum.PartType.Ball, Vector3.one * 0.2 * e, base * CFrame.new(-0.25 * e, 3.9 * e, -0.58 * e), noir)
	piece(modele, Enum.PartType.Ball, Vector3.one * 0.2 * e, base * CFrame.new(0.25 * e, 3.9 * e, -0.58 * e), noir)
	piece(
		modele,
		Enum.PartType.Block,
		Vector3.new(0.18, 0.18, 0.55) * e,
		base * CFrame.new(0, 3.72 * e, -0.8 * e),
		Color3.fromRGB(255, 140, 40)
	)

	chapeau(modele, definition.Chapeau, base * CFrame.new(0, 4.35 * e, 0), e, accent, neon)

	-- Lumière et étincelles pour les belles pièces
	if definition.Rarete >= 4 or dore then
		local lumiere = Instance.new("PointLight")
		lumiere.Color = if dore then couleur(Config.Couleurs.Dore) else couleur(rarete.Couleur)
		lumiere.Range = 10
		lumiere.Brightness = 1.2
		lumiere.Parent = tete
		local etincelles = Instance.new("ParticleEmitter")
		etincelles.Rate = 4
		etincelles.Lifetime = NumberRange.new(1, 1.6)
		etincelles.Speed = NumberRange.new(1, 2)
		etincelles.SpreadAngle = Vector2.new(180, 180)
		etincelles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		etincelles.Color = ColorSequence.new(lumiere.Color)
		etincelles.LightEmission = 0.8
		etincelles.Parent = bas
	end

	-- Étiquette : nom, rareté, revenu
	local etiquette = Instance.new("BillboardGui")
	etiquette.Name = "Etiquette"
	etiquette.Size = UDim2.fromScale(5.5, 1.7)
	etiquette.StudsOffsetWorldSpace = Vector3.new(0, 2.2 * e, 0)
	etiquette.MaxDistance = 70
	etiquette.LightInfluence = 0
	etiquette.Adornee = tete
	local function ligne(texte: string, teinte: Color3, position: number, hauteur: number)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, hauteur)
		label.Position = UDim2.fromScale(0, position)
		label.Text = texte
		label.TextColor3 = teinte
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextStrokeTransparency = 0.3
		label.Parent = etiquette
	end
	ligne(
		(if dore then "★ " else "") .. definition.Nom,
		if dore then couleur(Config.Couleurs.Dore) else Color3.new(1, 1, 1),
		0,
		0.42
	)
	ligne(rarete.Nom, couleur(rarete.Couleur), 0.42, 0.28)
	ligne(
		"+" .. Formules.formater(Formules.revenuSnowpal(id, dore)) .. " ❄️/s",
		Color3.fromRGB(190, 230, 255),
		0.7,
		0.3
	)
	etiquette.Parent = tete

	return modele
end

return ConstructeurSnowpal
