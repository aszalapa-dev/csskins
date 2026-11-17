--!strict
--[[
	ConstructeurMap.luau — construit TOUTE la map en Parts au démarrage du serveur, de façon
	déterministe (même graine = même map). Si Workspace.Map existe déjà (map retouchée et enregistrée
	dans Studio), on ne reconstruit rien : on retrouve simplement les éléments par leur nom.

	Plan (vue de dessus, tout est centré sur l'origine) :
	  - place centrale (sapin géant, classement, spawn)          rayon 0 – 38
	  - village : 8 terrains de joueurs en cercle                rayon ~75
	  - zone 1 « Prairie Givrée », zone 2 « Bois Cristal », zone 3 « Pic Aurore » : anneaux (Config.Zones)
	  - montagnes tout autour (mur naturel)
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

export type Terrain = {
	Numero: number,
	Origine: CFrame, -- centre du terrain, au niveau du sol, -Z vers l'extérieur de l'île
	CentreAtelier: Vector3,
	Socles: { CFrame }, -- dessus de chaque socle, du plus central au plus éloigné
	Spawn: SpawnLocation?,
	Panneau: TextLabel?, -- nom du propriétaire + revenu
	Tirelire: TextLabel?, -- contenu de la tirelire
	Snowpals: Folder, -- les modèles des Snowpals exposés
}

export type Map = {
	Terrains: { Terrain },
	LignesClassement: { TextLabel },
}

local ConstructeurMap = {}

ConstructeurMap.RAYON_ATELIER = 7
ConstructeurMap.RAYON_TERRAINS = 75
local NOMBRE_TERRAINS = Config.JoueursMax
local NOMBRE_SOCLES = Config.Equipe.SoclesMax + Config.Equipe.SoclesGamepass
local HAUTEUR_TERRAIN = 0.75
local ATELIER_LOCAL = Vector3.new(0, 0, -8)

local COULEURS_TERRAINS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(255, 180, 90),
	Color3.fromRGB(250, 225, 90),
	Color3.fromRGB(130, 220, 120),
	Color3.fromRGB(90, 210, 220),
	Color3.fromRGB(110, 150, 255),
	Color3.fromRGB(190, 130, 255),
	Color3.fromRGB(255, 140, 210),
}

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

type Options = {
	Nom: string?,
	Forme: Enum.PartType?,
	Materiau: Enum.Material?,
	Transparence: number?,
	Collision: boolean?,
	Ombre: boolean?,
}

-- Crée une Part ancrée. Par défaut : bloc, plastique lisse, avec collision.
local function bloc(parent: Instance, taille: Vector3, cframe: CFrame, teinte: Color3, options: Options?): Part
	local o: Options = options or {}
	local part = Instance.new("Part")
	part.Name = o.Nom or "Bloc"
	part.Shape = o.Forme or Enum.PartType.Block
	part.Size = taille
	part.CFrame = cframe
	part.Color = teinte
	part.Material = o.Materiau or Enum.Material.SmoothPlastic
	part.Transparency = o.Transparence or 0
	part.Anchored = true
	part.CanCollide = o.Collision ~= false
	part.CastShadow = o.Ombre ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Disque horizontal (cylindre couché) dont le dessus est à la hauteur `dessus`.
local function disque(
	parent: Instance,
	rayon: number,
	epaisseur: number,
	centre: Vector3,
	teinte: Color3,
	options: Options?
): Part
	local o: Options = options or {}
	o.Forme = Enum.PartType.Cylinder
	return bloc(
		parent,
		Vector3.new(epaisseur, rayon * 2, rayon * 2),
		CFrame.new(centre.X, centre.Y - epaisseur / 2, centre.Z) * CFrame.Angles(0, 0, math.rad(90)),
		teinte,
		o
	)
end

local function dossier(parent: Instance, nom: string): Folder
	local f = Instance.new("Folder")
	f.Name = nom
	f.Parent = parent
	return f
end

-- Texte flottant au-dessus d'une Part
local function affiche(
	adornee: BasePart,
	texte: string,
	teinte: Color3,
	taille: UDim2,
	decalage: number,
	distance: number
): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "Affiche"
	gui.Size = taille
	gui.StudsOffsetWorldSpace = Vector3.new(0, decalage, 0)
	gui.MaxDistance = distance
	gui.LightInfluence = 0
	gui.Adornee = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Texte"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = texte
	label.TextColor3 = teinte
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	gui.Parent = adornee
	return label
end

-- Position sur le sol à partir d'un angle (degrés) et d'un rayon
local function polaire(angle: number, rayon: number, hauteur: number?): Vector3
	local a = math.rad(angle)
	return Vector3.new(math.cos(a) * rayon, hauteur or 0, math.sin(a) * rayon)
end

-- Hauteur du sol à une distance donnée du centre (les disques sont empilés avec de petites marches)
local function hauteurSol(rayon: number): number
	if rayon < 38 then
		return 0.6
	elseif rayon < Config.RayonVillage then
		return 0.45
	elseif rayon < Config.Zones[1].RayonMax then
		return 0.3
	elseif rayon < Config.Zones[2].RayonMax then
		return 0.15
	end
	return 0
end

-- CFrame posé au sol, tourné vers le centre de l'île
local function versCentre(position: Vector3): CFrame
	return CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
end

-- ───────────────────────────── Sol et relief ─────────────────────────────

local function construireSol(map: Folder)
	local sol = dossier(map, "Sol")
	bloc(sol, Vector3.new(2048, 2, 2048), CFrame.new(0, -5, 0), Color3.fromRGB(140, 195, 235), {
		Nom = "Banquise",
		Materiau = Enum.Material.Ice,
	})
	-- Disques empilés : zone 3 (le plus grand, tout en bas) -> place centrale (tout en haut)
	disque(
		sol,
		Config.RayonIle,
		6,
		Vector3.new(0, 0, 0),
		rgb(Config.Zones[3].CouleurSol),
		{ Nom = "Zone3", Materiau = Enum.Material.Snow }
	)
	disque(sol, Config.Zones[2].RayonMax, 6, Vector3.new(0, 0.15, 0), rgb(Config.Zones[2].CouleurSol), {
		Nom = "Zone2",
		Materiau = Enum.Material.Snow,
	})
	disque(sol, Config.Zones[1].RayonMax, 6, Vector3.new(0, 0.3, 0), rgb(Config.Zones[1].CouleurSol), {
		Nom = "Zone1",
		Materiau = Enum.Material.Snow,
	})
	disque(sol, Config.RayonVillage, 6, Vector3.new(0, 0.45, 0), Color3.fromRGB(214, 226, 240), {
		Nom = "Village",
		Materiau = Enum.Material.Sand,
	})
	disque(
		sol,
		38,
		6,
		Vector3.new(0, 0.6, 0),
		Color3.fromRGB(176, 190, 214),
		{ Nom = "Place", Materiau = Enum.Material.Cobblestone }
	)

	-- Montagnes en blocs tout autour + mur invisible (personne ne tombe de l'île)
	local montagnes = dossier(map, "Montagnes")
	local alea = Random.new(77)
	local nombre = 44
	for i = 0, nombre - 1 do
		local angle = i * 360 / nombre
		local hauteur = alea:NextNumber(34, 70)
		local largeur = alea:NextNumber(60, 76)
		local position = polaire(angle, Config.RayonIle + 24 + alea:NextNumber(0, 10))
		local base = versCentre(position)
		local gris = Color3.fromRGB(150, 170, 200):Lerp(Color3.fromRGB(190, 205, 230), alea:NextNumber())
		bloc(
			montagnes,
			Vector3.new(largeur, hauteur, 54),
			base * CFrame.new(0, hauteur / 2 - 3, 0),
			gris,
			{ Materiau = Enum.Material.Rock }
		)
		bloc(
			montagnes,
			Vector3.new(largeur * 0.68, hauteur * 0.5, 38),
			base
				* CFrame.new(0, hauteur + hauteur * 0.25 - 3, 4)
				* CFrame.Angles(0, math.rad(alea:NextNumber(-12, 12)), 0),
			gris:Lerp(Color3.new(1, 1, 1), 0.35),
			{ Materiau = Enum.Material.Rock, Collision = false }
		)
		bloc(
			montagnes,
			Vector3.new(largeur * 0.4, hauteur * 0.3, 24),
			base * CFrame.new(0, hauteur * 1.5 + hauteur * 0.15 - 3, 6),
			Color3.fromRGB(250, 252, 255),
			{ Materiau = Enum.Material.Snow, Collision = false }
		)
	end
	local segments = 40
	local longueur = 2 * math.pi * (Config.RayonIle + 1) / segments + 4
	for i = 0, segments - 1 do
		local position = polaire(i * 360 / segments, Config.RayonIle + 1, 40)
		bloc(montagnes, Vector3.new(longueur, 90, 2), versCentre(position), Color3.new(1, 1, 1), {
			Nom = "MurInvisible",
			Transparence = 1,
			Ombre = false,
		})
	end
end

-- ───────────────────────────── Place centrale ─────────────────────────────

local function construirePlace(map: Folder)
	local place = dossier(map, "Place")
	local y = 0.6

	-- Sapin géant en blocs
	bloc(
		place,
		Vector3.new(4, 8, 4),
		CFrame.new(0, y + 4, 0),
		Color3.fromRGB(120, 80, 50),
		{ Nom = "Tronc", Materiau = Enum.Material.Wood }
	)
	local decorations = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(255, 210, 60),
		Color3.fromRGB(90, 170, 255),
		Color3.fromRGB(255, 130, 220),
	}
	local etages = 6
	for i = 0, etages - 1 do
		local largeur = 24 - i * 3.6
		local hauteur = y + 7 + i * 4.6
		local etage = bloc(
			place,
			Vector3.new(largeur, 5, largeur),
			CFrame.new(0, hauteur, 0) * CFrame.Angles(0, math.rad(i * 45), 0),
			Color3.fromRGB(40, 150 + i * 8, 80),
			{ Nom = "Etage", Materiau = Enum.Material.Grass, Collision = i == 0 }
		)
		bloc(
			place,
			Vector3.new(largeur * 0.8, 0.8, largeur * 0.8),
			etage.CFrame * CFrame.new(0, 2.7, 0),
			Color3.fromRGB(250, 252, 255),
			{
				Nom = "Neige",
				Materiau = Enum.Material.Snow,
				Collision = false,
				Ombre = false,
			}
		)
		-- Une boule lumineuse à chaque coin
		for coin = 0, 3 do
			local sx = if coin % 2 == 0 then 1 else -1
			local sz = if coin < 2 then 1 else -1
			bloc(
				place,
				Vector3.one * 1.5,
				etage.CFrame * CFrame.new(sx * largeur / 2, -2, sz * largeur / 2),
				decorations[(i + coin) % #decorations + 1],
				{
					Nom = "BouleLumineuse",
					Forme = Enum.PartType.Ball,
					Materiau = Enum.Material.Neon,
					Collision = false,
					Ombre = false,
				}
			)
		end
	end
	local sommet = y + 7 + etages * 4.6
	for i = 0, 1 do
		local etoile = bloc(
			place,
			Vector3.new(5, 5, 1),
			CFrame.new(0, sommet + 1.5, 0) * CFrame.Angles(0, 0, math.rad(i * 45)),
			Color3.fromRGB(255, 225, 90),
			{ Nom = "Etoile", Materiau = Enum.Material.Neon, Collision = false, Ombre = false }
		)
		if i == 0 then
			local lumiere = Instance.new("PointLight")
			lumiere.Color = Color3.fromRGB(255, 225, 140)
			lumiere.Range = 50
			lumiere.Brightness = 2
			lumiere.Parent = etoile
		end
	end

	-- Cadeaux au pied du sapin
	local alea = Random.new(5)
	for i = 0, 9 do
		local taille = alea:NextNumber(2, 3.6)
		local position = polaire(i * 36 + alea:NextNumber(-8, 8), alea:NextNumber(15, 19), y + taille / 2)
		local cadeau = bloc(
			place,
			Vector3.one * taille,
			CFrame.new(position) * CFrame.Angles(0, alea:NextNumber(0, 6), 0),
			decorations[i % #decorations + 1],
			{ Nom = "Cadeau" }
		)
		bloc(
			place,
			Vector3.new(taille + 0.1, taille + 0.1, taille * 0.2),
			cadeau.CFrame,
			Color3.new(1, 1, 1),
			{ Nom = "Ruban", Collision = false }
		)
		bloc(
			place,
			Vector3.new(taille * 0.2, taille + 0.1, taille + 0.1),
			cadeau.CFrame,
			Color3.new(1, 1, 1),
			{ Nom = "Ruban", Collision = false }
		)
	end

	-- Lampadaires
	for i = 0, 7 do
		local position = polaire(i * 45, 46, 0.45)
		bloc(
			place,
			Vector3.new(0.8, 9, 0.8),
			CFrame.new(position + Vector3.new(0, 4.5, 0)),
			Color3.fromRGB(60, 70, 100),
			{ Nom = "Lampadaire" }
		)
		local globe =
			bloc(place, Vector3.one * 2, CFrame.new(position + Vector3.new(0, 9.8, 0)), Color3.fromRGB(255, 236, 170), {
				Nom = "Globe",
				Forme = Enum.PartType.Ball,
				Materiau = Enum.Material.Neon,
				Collision = false,
				Ombre = false,
			})
		local lumiere = Instance.new("PointLight")
		lumiere.Color = Color3.fromRGB(255, 225, 170)
		lumiere.Range = 26
		lumiere.Brightness = 1.2
		lumiere.Parent = globe
	end

	-- Spawn central (utilisé seulement si le joueur n'a pas encore de terrain)
	local apparition = Instance.new("SpawnLocation")
	apparition.Name = "SpawnCentral"
	apparition.Size = Vector3.new(10, 0.4, 10)
	apparition.CFrame = CFrame.new(polaire(180, 27, y + 0.2))
	apparition.Anchored = true
	apparition.Neutral = true
	apparition.Duration = 0
	apparition.Color = Color3.fromRGB(120, 200, 255)
	apparition.Material = Enum.Material.Neon
	apparition.Transparency = 0.4
	apparition.TopSurface = Enum.SurfaceType.Smooth
	apparition.Parent = place

	-- Panneau du classement mondial
	local position = polaire(0, 30, y + 7.5)
	local panneau = bloc(
		place,
		Vector3.new(20, 13, 1),
		versCentre(position),
		Color3.fromRGB(30, 44, 80),
		{ Nom = "PanneauClassement" }
	)
	for _, cote in { -9, 9 } do
		bloc(
			place,
			Vector3.new(1.2, 15, 1.2),
			panneau.CFrame * CFrame.new(cote, -1, 0.2),
			Color3.fromRGB(255, 205, 60),
			{ Nom = "Poteau" }
		)
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Classement"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = panneau
	local titre = Instance.new("TextLabel")
	titre.Name = "Titre"
	titre.Size = UDim2.fromScale(1, 0.16)
	titre.BackgroundColor3 = Color3.fromRGB(255, 205, 60)
	titre.BorderSizePixel = 0
	titre.Text = "🏆 TOP FLOCONS MONDIAL 🏆"
	titre.TextColor3 = Color3.fromRGB(30, 44, 80)
	titre.TextScaled = true
	titre.Font = Enum.Font.FredokaOne
	titre.Parent = gui
	for rang = 1, Config.Classement.Taille do
		local ligne = Instance.new("TextLabel")
		ligne.Name = "Ligne" .. rang
		ligne.Size = UDim2.fromScale(0.94, 0.076)
		ligne.Position = UDim2.fromScale(0.03, 0.18 + (rang - 1) * 0.081)
		ligne.BackgroundTransparency = if rang % 2 == 0 then 1 else 0.85
		ligne.BackgroundColor3 = Color3.new(1, 1, 1)
		ligne.BorderSizePixel = 0
		ligne.Text = rang .. ".  —"
		ligne.TextXAlignment = Enum.TextXAlignment.Left
		ligne.TextColor3 = if rang <= 3 then Color3.fromRGB(255, 220, 110) else Color3.new(1, 1, 1)
		ligne.TextScaled = true
		ligne.Font = Enum.Font.FredokaOne
		ligne.Parent = gui
	end
end

-- ───────────────────────────── Terrains des joueurs ─────────────────────────────

local function origineTerrain(numero: number): CFrame
	local angle = (numero - 1) * 360 / NOMBRE_TERRAINS + 22.5
	local position = polaire(angle, ConstructeurMap.RAYON_TERRAINS, HAUTEUR_TERRAIN)
	-- -Z (l'avant) pointe vers l'extérieur de l'île, là où se trouve la neige
	return CFrame.lookAt(position, position + Vector3.new(position.X, 0, position.Z))
end

-- Positions locales des socles : 2 rangées de 6, remplies du centre vers les bords
local function soclesLocaux(): { Vector3 }
	local ordreColonnes = { 2, 3, 1, 4, 0, 5 }
	local positions = {}
	for rangee = 0, 1 do
		for _, colonne in ordreColonnes do
			if #positions < NOMBRE_SOCLES then
				table.insert(positions, Vector3.new(-13.75 + colonne * 5.5, 0, 5 + rangee * 6.5))
			end
		end
	end
	return positions
end

local function construireTerrain(parent: Folder, numero: number)
	local terrain = dossier(parent, "Terrain" .. numero)
	local origine = origineTerrain(numero)
	local teinte = COULEURS_TERRAINS[(numero - 1) % #COULEURS_TERRAINS + 1]
	local clair = teinte:Lerp(Color3.new(1, 1, 1), 0.55)

	-- Dalle (son CFrame sert de repère : dessus de la dalle = origine du terrain)
	bloc(
		terrain,
		Vector3.new(38, 0.75, 34),
		origine * CFrame.new(0, -0.375, 0),
		clair,
		{ Nom = "Base", Materiau = Enum.Material.Concrete }
	)
	-- Bordures colorées
	for _, cote in { -1, 1 } do
		bloc(terrain, Vector3.new(1, 1.6, 34), origine * CFrame.new(cote * 18.5, 0.3, 0), teinte, { Nom = "Bordure" })
	end
	bloc(terrain, Vector3.new(38, 1.6, 1), origine * CFrame.new(0, 0.3, 16.5), teinte, { Nom = "Bordure" })

	-- Atelier : disque lumineux + arche
	local atelier = disque(
		terrain,
		ConstructeurMap.RAYON_ATELIER,
		0.3,
		(origine * CFrame.new(ATELIER_LOCAL + Vector3.new(0, 0.2, 0))).Position,
		Color3.fromRGB(70, 180, 255),
		{
			Nom = "Atelier",
			Materiau = Enum.Material.Neon,
			Collision = false,
			Ombre = false,
		}
	)
	for _, cote in { -1, 1 } do
		bloc(
			terrain,
			Vector3.new(1.4, 11, 1.4),
			origine * CFrame.new(cote * 8.2, 5.5, ATELIER_LOCAL.Z),
			teinte,
			{ Nom = "Pilier" }
		)
		bloc(
			terrain,
			Vector3.one * 2.2,
			origine * CFrame.new(cote * 8.2, 11.8, ATELIER_LOCAL.Z),
			Color3.fromRGB(250, 252, 255),
			{
				Nom = "BoulePilier",
				Forme = Enum.PartType.Ball,
				Materiau = Enum.Material.Snow,
				Collision = false,
			}
		)
	end
	local linteau = bloc(
		terrain,
		Vector3.new(18, 1.6, 1.6),
		origine * CFrame.new(0, 10.4, ATELIER_LOCAL.Z),
		teinte,
		{ Nom = "Linteau", Collision = false }
	)
	affiche(linteau, "❄️ ATELIER ❄️", Color3.new(1, 1, 1), UDim2.fromScale(14, 2.6), 2.6, 160)
	affiche(atelier, "Dépose ta boule ici !", Color3.fromRGB(190, 235, 255), UDim2.fromScale(11, 1.6), 3.2, 60)

	-- Tirelire (les revenus des Snowpals s'y accumulent)
	local coffre =
		bloc(terrain, Vector3.new(3.4, 2.6, 3.4), origine * CFrame.new(13.5, 1.3, -9), Color3.fromRGB(255, 205, 60), {
			Nom = "TirelireCoffre",
			Materiau = Enum.Material.Foil,
		})
	bloc(
		terrain,
		Vector3.new(3.8, 0.7, 3.8),
		coffre.CFrame * CFrame.new(0, 1.6, 0),
		Color3.fromRGB(200, 60, 60),
		{ Nom = "TirelireCouvercle", Collision = false }
	)
	local texteTirelire =
		affiche(coffre, "Tirelire : 0 ❄️", Color3.fromRGB(255, 225, 110), UDim2.fromScale(9, 1.5), 3.4, 90)
	texteTirelire.Name = "TexteTirelire"

	-- Socles des Snowpals
	for indice, position in soclesLocaux() do
		disque(
			terrain,
			1.9,
			1,
			(origine * CFrame.new(position + Vector3.new(0, 1, 0))).Position,
			if indice % 2 == 0 then teinte else Color3.fromRGB(250, 252, 255),
			{
				Nom = "Socle" .. indice,
			}
		)
	end

	-- Panneau du propriétaire, au fond, tourné vers l'atelier
	local panneau = bloc(
		terrain,
		Vector3.new(20, 5.5, 0.8),
		origine * CFrame.new(0, 9, 16.4),
		Color3.fromRGB(30, 44, 80),
		{ Nom = "Panneau" }
	)
	for _, cote in { -1, 1 } do
		bloc(terrain, Vector3.new(1, 12, 1), origine * CFrame.new(cote * 9.6, 6, 16.4), teinte, { Nom = "Poteau" })
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Ecriteau"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = panneau
	local texte = Instance.new("TextLabel")
	texte.Name = "TexteProprietaire"
	texte.Size = UDim2.fromScale(1, 1)
	texte.BackgroundTransparency = 1
	texte.Text = "Terrain libre"
	texte.TextColor3 = Color3.new(1, 1, 1)
	texte.TextScaled = true
	texte.Font = Enum.Font.FredokaOne
	texte.Parent = gui

	-- Point d'apparition du propriétaire
	local apparition = Instance.new("SpawnLocation")
	apparition.Name = "Spawn"
	apparition.Size = Vector3.new(6, 0.3, 6)
	apparition.CFrame = origine * CFrame.new(-13, 0.15, -9) * CFrame.Angles(0, math.rad(180), 0)
	apparition.Anchored = true
	apparition.Neutral = true
	apparition.Duration = 0
	apparition.Color = teinte
	apparition.Material = Enum.Material.Neon
	apparition.Transparency = 0.5
	apparition.CanCollide = false
	apparition.TopSurface = Enum.SurfaceType.Smooth
	apparition.Parent = terrain

	dossier(terrain, "Snowpals")
end

-- ───────────────────────────── Zones : portails et décor ─────────────────────────────

local function sapin(parent: Instance, position: Vector3, echelle: number, feuillage: Color3, alea: Random)
	local base = CFrame.new(position) * CFrame.Angles(0, alea:NextNumber(0, 6.28), 0)
	bloc(
		parent,
		Vector3.new(1.6, 5, 1.6) * echelle,
		base * CFrame.new(0, 2.5 * echelle, 0),
		Color3.fromRGB(110, 76, 50),
		{
			Nom = "Tronc",
			Materiau = Enum.Material.Wood,
		}
	)
	for i = 0, 2 do
		local largeur = (8 - i * 2.4) * echelle
		local etage = bloc(
			parent,
			Vector3.new(largeur, 3 * echelle, largeur),
			base * CFrame.new(0, (5 + i * 2.8) * echelle, 0) * CFrame.Angles(0, math.rad(i * 30), 0),
			feuillage,
			{ Nom = "Feuillage", Materiau = Enum.Material.Grass, Collision = false }
		)
		bloc(
			parent,
			Vector3.new(largeur * 0.75, 0.6 * echelle, largeur * 0.75),
			etage.CFrame * CFrame.new(0, 1.7 * echelle, 0),
			Color3.fromRGB(250, 252, 255),
			{
				Nom = "Neige",
				Materiau = Enum.Material.Snow,
				Collision = false,
				Ombre = false,
			}
		)
	end
end

local function cristaux(parent: Instance, position: Vector3, echelle: number, teinte: Color3, alea: Random)
	for i = 0, alea:NextInteger(2, 4) do
		local hauteur = alea:NextNumber(4, 11) * echelle
		bloc(
			parent,
			Vector3.new(1.6 * echelle, hauteur, 1.6 * echelle),
			CFrame.new(position)
				* CFrame.Angles(0, alea:NextNumber(0, 6.28), 0)
				* CFrame.new(i * 0.9 * echelle, hauteur * 0.4, 0)
				* CFrame.Angles(math.rad(alea:NextNumber(-22, 22)), math.rad(45), math.rad(alea:NextNumber(-22, 22))),
			teinte:Lerp(Color3.new(1, 1, 1), alea:NextNumber(0, 0.4)),
			{ Nom = "Cristal", Materiau = Enum.Material.Neon, Transparence = 0.25, Collision = i == 0, Ombre = false }
		)
	end
end

local function congere(parent: Instance, position: Vector3, echelle: number)
	bloc(
		parent,
		Vector3.new(9, 5, 7) * echelle,
		CFrame.new(position + Vector3.new(0, -0.8 * echelle, 0)),
		Color3.fromRGB(250, 252, 255),
		{
			Nom = "Congere",
			Forme = Enum.PartType.Ball,
			Materiau = Enum.Material.Snow,
			Collision = false,
		}
	)
end

local function rocher(parent: Instance, position: Vector3, echelle: number, alea: Random)
	local base = CFrame.new(position) * CFrame.Angles(0, alea:NextNumber(0, 6.28), 0)
	bloc(
		parent,
		Vector3.new(5, 3.4, 4) * echelle,
		base * CFrame.new(0, 1.4 * echelle, 0),
		Color3.fromRGB(140, 150, 170),
		{
			Nom = "Rocher",
			Materiau = Enum.Material.Rock,
		}
	)
	bloc(
		parent,
		Vector3.new(4, 0.7, 3.2) * echelle,
		base * CFrame.new(0, 3.3 * echelle, 0),
		Color3.fromRGB(250, 252, 255),
		{
			Nom = "Neige",
			Materiau = Enum.Material.Snow,
			Collision = false,
		}
	)
end

local function pilierAurore(parent: Instance, position: Vector3, echelle: number, teinte: Color3)
	local hauteur = 26 * echelle
	bloc(parent, Vector3.new(2.4, hauteur, 2.4), CFrame.new(position + Vector3.new(0, hauteur / 2, 0)), teinte, {
		Nom = "PilierAurore",
		Materiau = Enum.Material.Neon,
		Transparence = 0.45,
		Ombre = false,
	})
	bloc(
		parent,
		Vector3.one * 4.5 * echelle,
		CFrame.new(position + Vector3.new(0, hauteur + 3, 0)),
		Color3.new(1, 1, 1):Lerp(teinte, 0.4),
		{
			Nom = "Orbe",
			Forme = Enum.PartType.Ball,
			Materiau = Enum.Material.Neon,
			Collision = false,
			Ombre = false,
		}
	)
end

local function construireZones(map: Folder)
	local zones = dossier(map, "Zones")
	local alea = Random.new(2026)

	for _, zone in Config.Zones do
		local dossierZone = dossier(zones, "Zone" .. zone.Id)
		local accent = rgb(zone.CouleurAccent)

		-- Portails d'entrée aux 8 directions, à la frontière intérieure de la zone
		for i = 0, 7 do
			local position = polaire(i * 45, zone.RayonMin, hauteurSol(zone.RayonMin + 1))
			local base = versCentre(position)
			for _, cote in { -1, 1 } do
				bloc(
					dossierZone,
					Vector3.new(2, 13, 2),
					base * CFrame.new(cote * 7, 6.5, 0),
					accent,
					{ Nom = "PilierPortail" }
				)
			end
			local linteau = bloc(dossierZone, Vector3.new(18, 2.2, 2.2), base * CFrame.new(0, 13.6, 0), accent, {
				Nom = "LinteauPortail",
				Materiau = Enum.Material.Neon,
				Collision = false,
			})
			if i % 2 == 0 then
				affiche(
					linteau,
					`{zone.Nom}  ❄️ x{zone.Multiplicateur}`,
					Color3.new(1, 1, 1),
					UDim2.fromScale(20, 3),
					3.2,
					220
				)
			end
		end

		-- Décor dispersé (graine fixe = toujours la même map)
		local nombre = 46 + zone.Id * 6
		for _ = 1, nombre do
			local angle = alea:NextNumber(0, 360)
			-- On laisse dégagés les couloirs des portails
			local ecart = math.abs((angle + 22.5) % 45 - 22.5)
			if ecart < 4 then
				angle += 8
			end
			local rayon = alea:NextNumber(zone.RayonMin + 10, zone.RayonMax - 10)
			local position = polaire(angle, rayon, hauteurSol(rayon))
			local echelle = alea:NextNumber(0.8, 1.5)
			local tirage = alea:NextNumber()
			if zone.Id == 1 then
				if tirage < 0.55 then
					sapin(dossierZone, position, echelle, Color3.fromRGB(46, 140, 84), alea)
				elseif tirage < 0.82 then
					congere(dossierZone, position, echelle)
				else
					rocher(dossierZone, position, echelle, alea)
				end
			elseif zone.Id == 2 then
				if tirage < 0.5 then
					cristaux(dossierZone, position, echelle, accent, alea)
				elseif tirage < 0.8 then
					sapin(dossierZone, position, echelle, Color3.fromRGB(70, 190, 180), alea)
				else
					congere(dossierZone, position, echelle)
				end
			else
				if tirage < 0.4 then
					pilierAurore(
						dossierZone,
						position,
						echelle,
						accent:Lerp(Color3.fromRGB(110, 255, 200), alea:NextNumber())
					)
				elseif tirage < 0.8 then
					cristaux(dossierZone, position, echelle * 1.2, Color3.fromRGB(255, 130, 220), alea)
				else
					rocher(dossierZone, position, echelle * 1.4, alea)
				end
			end
		end
	end

	-- Rubans d'aurore dans le ciel, au-dessus de la dernière zone
	local aurores = dossier(zones, "Aurores")
	local teintes = { Color3.fromRGB(90, 255, 190), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 120, 210) }
	for i = 0, 17 do
		local position = polaire(i * 20, 330 + (i % 3) * 22, 120 + (i % 4) * 9)
		bloc(
			aurores,
			Vector3.new(110, 16, 1.5),
			versCentre(position) * CFrame.Angles(math.rad(12), 0, math.rad((i % 5 - 2) * 5)),
			teintes[i % #teintes + 1],
			{ Nom = "Aurore", Materiau = Enum.Material.Neon, Transparence = 0.72, Collision = false, Ombre = false }
		)
	end
end

-- ───────────────────────────── Éclairage ─────────────────────────────

local function reglerEclairage()
	Lighting.ClockTime = 15.2
	Lighting.GeographicLatitude = 38
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(120, 135, 170)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 165, 200)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 220)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.4

	local function unique(classe: string): Instance
		local existant = Lighting:FindFirstChildOfClass(classe)
		if existant ~= nil then
			return existant
		end
		local nouveau = Instance.new(classe)
		nouveau.Parent = Lighting
		return nouveau
	end

	local atmosphere = unique("Atmosphere") :: Atmosphere
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(205, 225, 255)
	atmosphere.Decay = Color3.fromRGB(150, 180, 235)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1.4

	unique("Sky") -- ciel par défaut de Roblox

	local bloom = unique("BloomEffect") :: BloomEffect
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.4

	local couleurs = unique("ColorCorrectionEffect") :: ColorCorrectionEffect
	couleurs.Saturation = 0.18
	couleurs.Contrast = 0.06
	couleurs.TintColor = Color3.fromRGB(245, 250, 255)
end

-- ───────────────────────────── Construction et références ─────────────────────────────

-- Retrouve dans la map (construite ou enregistrée) tout ce dont les services ont besoin.
local function referencer(map: Instance): Map
	local resultat: Map = { Terrains = {}, LignesClassement = {} }
	local terrains = map:FindFirstChild("Terrains")
	local locaux = soclesLocaux()
	for numero = 1, NOMBRE_TERRAINS do
		local instance = if terrains then terrains:FindFirstChild("Terrain" .. numero) else nil
		local base = if instance then instance:FindFirstChild("Base") else nil
		local origine = if base ~= nil and base:IsA("BasePart")
			then base.CFrame * CFrame.new(0, 0.375, 0)
			else origineTerrain(numero)
		local socles = {}
		for _, position in locaux do
			table.insert(socles, origine * CFrame.new(position + Vector3.new(0, 1, 0)))
		end
		local snowpals: Folder
		local existants = if instance then instance:FindFirstChild("Snowpals") else nil
		if existants ~= nil and existants:IsA("Folder") then
			snowpals = existants
			snowpals:ClearAllChildren() -- au cas où des Snowpals auraient été enregistrés avec la map
		else
			snowpals = dossier(instance or map, "Snowpals")
		end
		local apparition = if instance then instance:FindFirstChild("Spawn") else nil
		local panneau = if instance then instance:FindFirstChild("TexteProprietaire", true) else nil
		local tirelire = if instance then instance:FindFirstChild("TexteTirelire", true) else nil
		table.insert(resultat.Terrains, {
			Numero = numero,
			Origine = origine,
			CentreAtelier = (origine * CFrame.new(ATELIER_LOCAL)).Position,
			Socles = socles,
			Spawn = if apparition ~= nil and apparition:IsA("SpawnLocation") then apparition else nil,
			Panneau = if panneau ~= nil and panneau:IsA("TextLabel") then panneau else nil,
			Tirelire = if tirelire ~= nil and tirelire:IsA("TextLabel") then tirelire else nil,
			Snowpals = snowpals,
		})
	end
	local panneauClassement = map:FindFirstChild("PanneauClassement", true)
	if panneauClassement ~= nil then
		for rang = 1, Config.Classement.Taille do
			local ligne = panneauClassement:FindFirstChild("Ligne" .. rang, true)
			if ligne ~= nil and ligne:IsA("TextLabel") then
				table.insert(resultat.LignesClassement, ligne)
			end
		end
	end
	return resultat
end

function ConstructeurMap.construire(): Map
	reglerEclairage()
	local existante = Workspace:FindFirstChild("Map")
	if existante ~= nil then
		return referencer(existante)
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	construireSol(map)
	construirePlace(map)
	local terrains = dossier(map, "Terrains")
	for numero = 1, NOMBRE_TERRAINS do
		construireTerrain(terrains, numero)
	end
	construireZones(map)
	map.Parent = Workspace -- on parente à la fin : une seule réplication
	return referencer(map)
end

return ConstructeurMap
