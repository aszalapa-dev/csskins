--!strict
--[[
	Effets.luau (client) — tout ce qui est purement visuel dans le monde 3D :
	  - la boule de neige qui roule devant CHAQUE joueur (d'après l'attribut « TailleBoule » du serveur)
	  - la neige qui tombe (plus forte pendant la tempête)
	  - le tremblement léger de caméra, les feux d'artifice visibles par tous
	  - le rayon lumineux qui guide vers l'atelier quand la boule est prête
	Rien ici n'a d'effet sur le jeu : le serveur ne lit jamais ces objets.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Interface = require(script.Parent.Interface)

local creer = Interface.creer
local joueurLocal = Players.LocalPlayer

local Effets = {}

local dossier: Folder

-- ───────────── Boules de neige des joueurs ─────────────

type BouleVisuelle = {
	Part: Part,
	Taches: { { Part: Part, Orientation: CFrame } },
	Taille: number,
	Angle: number,
	Derniere: Vector3?,
}
local boules: { [Player]: BouleVisuelle } = {}

local function retirerBoule(joueur: Player)
	local visuelle = boules[joueur]
	if visuelle ~= nil then
		visuelle.Part:Destroy()
		boules[joueur] = nil
	end
end

local function majBoule(joueur: Player, dt: number)
	local taille = joueur:GetAttribute("TailleBoule")
	local personnage = joueur.Character
	local racine = if personnage then personnage:FindFirstChild("HumanoidRootPart") else nil
	local humanoide = if personnage then personnage:FindFirstChildOfClass("Humanoid") else nil
	if type(taille) ~= "number" or taille <= 0 or racine == nil or not racine:IsA("BasePart") or humanoide == nil then
		retirerBoule(joueur)
		return
	end
	local visuelle = boules[joueur]
	if visuelle == nil then
		local part: Part = creer("Part", {
			Name = "Boule_" .. joueur.Name,
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(250, 252, 255),
			Material = Enum.Material.Snow,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Size = Vector3.one * taille,
			Parent = dossier,
		})
		-- Petites taches pour qu'on voie la boule tourner
		local taches = {}
		for i = 1, 3 do
			local tache: Part = creer("Part", {
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(200, 222, 245),
				Material = Enum.Material.Snow,
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				CastShadow = false,
				Size = Vector3.one * 0.3,
				Parent = part,
			})
			table.insert(taches, { Part = tache, Orientation = CFrame.Angles(i * 2.1, i * 1.3, 0) })
		end
		visuelle = { Part = part, Taches = taches, Taille = taille, Angle = 0, Derniere = nil }
		boules[joueur] = visuelle
	end
	-- Taille lissée
	visuelle.Taille += (taille - visuelle.Taille) * math.min(1, dt * 8)
	local diametre = visuelle.Taille
	local part = visuelle.Part
	part.Size = Vector3.one * diametre
	-- Position : devant le joueur, posée au sol
	local regard = racine.CFrame.LookVector
	local aPlat = Vector3.new(regard.X, 0, regard.Z)
	if aPlat.Magnitude < 0.01 then
		aPlat = Vector3.new(0, 0, -1)
	end
	aPlat = aPlat.Unit
	-- Hauteur du sol sous le personnage (les avatars R6 ont HipHeight = 0 et des jambes de 2 studs)
	local jambes = if humanoide.RigType == Enum.HumanoidRigType.R6 then 2 else humanoide.HipHeight
	local sol = racine.Position.Y - jambes - racine.Size.Y / 2
	local centre = Vector3.new(racine.Position.X, sol + diametre / 2, racine.Position.Z) + aPlat * (diametre / 2 + 1.4)
	-- Rotation : proportionnelle à la distance parcourue
	if visuelle.Derniere ~= nil then
		local deplacement = (centre - visuelle.Derniere) * Vector3.new(1, 0, 1)
		visuelle.Angle += deplacement.Magnitude / math.max(diametre / 2, 0.3)
	end
	visuelle.Derniere = centre
	part.CFrame = CFrame.lookAt(centre, centre + aPlat) * CFrame.Angles(-visuelle.Angle, 0, 0)
	for _, tache in visuelle.Taches do
		tache.Part.Size = Vector3.one * diametre * 0.22
		tache.Part.CFrame = part.CFrame * tache.Orientation * CFrame.new(0, diametre * 0.46, 0)
	end
end

-- ───────────── Neige qui tombe ─────────────

local emetteurNeige: ParticleEmitter? = nil
local supportNeige: Part? = nil

local function creerNeige()
	local support: Part = creer("Part", {
		Name = "Neige",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(90, 1, 90),
		Parent = dossier,
	})
	local emetteur: ParticleEmitter = creer("ParticleEmitter", {
		Rate = 70,
		Lifetime = NumberRange.new(5, 7),
		Speed = NumberRange.new(7, 11),
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(12, 12),
		Size = NumberSequence.new(0.28),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.5) }),
		Color = ColorSequence.new(Color3.new(1, 1, 1)),
		LightEmission = 0.4,
		Acceleration = Vector3.new(1.5, 0, 0.5),
		Parent = support,
	})
	supportNeige = support
	emetteurNeige = emetteur
end

local function majTempete()
	local tempete = Workspace:GetAttribute("Tempete") == true
	if emetteurNeige then
		emetteurNeige.Rate = if tempete then 220 else 70
		emetteurNeige.Speed = if tempete then NumberRange.new(16, 24) else NumberRange.new(7, 11)
		emetteurNeige.Acceleration = if tempete then Vector3.new(14, 0, 6) else Vector3.new(1.5, 0, 0.5)
	end
end

-- ───────────── Rayon guide vers l'atelier ─────────────

local rayon: Beam? = nil
local attacheAtelier: Attachment? = nil
local attacheJoueur: Attachment? = nil
local positionAtelier: Vector3? = nil

-- Retrouve l'atelier du terrain du joueur dans la map (construite par le serveur)
function Effets.definirTerrain(numero: number)
	task.spawn(function()
		local map = Workspace:WaitForChild("Map", 30)
		local terrains = if map then map:WaitForChild("Terrains", 10) else nil
		local terrain = if terrains then terrains:WaitForChild("Terrain" .. numero, 10) else nil
		local atelier = if terrain then terrain:WaitForChild("Atelier", 10) else nil
		if atelier ~= nil and atelier:IsA("BasePart") then
			positionAtelier = atelier.Position
			if attacheAtelier == nil then
				local ancre: Part = creer("Part", {
					Name = "AncreAtelier",
					Anchored = true,
					CanCollide = false,
					CanQuery = false,
					CanTouch = false,
					Transparency = 1,
					Size = Vector3.one,
					Parent = dossier,
				})
				attacheAtelier = creer("Attachment", { Parent = ancre })
				ancre.Position = atelier.Position + Vector3.new(0, 1.5, 0)
			else
				(attacheAtelier.Parent :: Part).Position = atelier.Position + Vector3.new(0, 1.5, 0)
			end
		end
	end)
end

function Effets.positionAtelier(): Vector3?
	return positionAtelier
end

local function majRayon()
	local personnage = joueurLocal.Character
	local racine = if personnage then personnage:FindFirstChild("HumanoidRootPart") else nil
	local actif = joueurLocal:GetAttribute("BouleMax") == true and racine ~= nil and attacheAtelier ~= nil
	if not actif then
		if rayon then
			rayon.Enabled = false
		end
		return
	end
	if attacheJoueur == nil or attacheJoueur.Parent ~= racine then
		if attacheJoueur then
			attacheJoueur:Destroy()
		end
		attacheJoueur = creer("Attachment", { Name = "GuideAtelier", Parent = racine })
	end
	if rayon == nil then
		rayon = creer("Beam", {
			Color = ColorSequence.new(Color3.fromRGB(90, 200, 255)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(1, 0.5),
			}),
			Width0 = 1.2,
			Width1 = 3,
			FaceCamera = true,
			LightEmission = 1,
			Segments = 1,
			Parent = dossier,
		})
	end
	if rayon then
		rayon.Attachment0 = attacheJoueur
		rayon.Attachment1 = attacheAtelier
		rayon.Enabled = true
	end
end

-- ───────────── Caméra ─────────────

-- Tremblement léger et court (désactivé si le personnage n'existe pas)
function Effets.tremblement(force: number, duree: number)
	task.spawn(function()
		local personnage = joueurLocal.Character
		local humanoide = if personnage then personnage:FindFirstChildOfClass("Humanoid") else nil
		if humanoide == nil then
			return
		end
		local debut = os.clock()
		while os.clock() - debut < duree do
			local reste = 1 - (os.clock() - debut) / duree
			humanoide.CameraOffset = Vector3.new((math.random() - 0.5), (math.random() - 0.5), 0) * force * reste
			RunService.RenderStepped:Wait()
		end
		humanoide.CameraOffset = Vector3.zero
	end)
end

-- ───────────── Feux d'artifice (visibles par tous) ─────────────

function Effets.spectacle(position: Vector3, rang: number)
	local rarete = Config.Raretes[math.clamp(rang, 1, #Config.Raretes)]
	local teinte = Interface.rgb(rarete.Couleur)
	-- Colonne de lumière
	local colonne: Part = creer("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Color = teinte,
		Transparency = 0.35,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(160, 5, 5),
		CFrame = CFrame.new(position + Vector3.new(0, 80, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = dossier,
	})
	TweenService:Create(colonne, TweenInfo.new(2.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(160, 16, 16),
		Transparency = 1,
	}):Play()
	Debris:AddItem(colonne, 2.6)
	-- Bouquets de particules
	local bouquets = 2 + rang
	for i = 1, bouquets do
		task.delay((i - 1) * 0.22, function()
			local source: Part = creer("Part", {
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				Transparency = 1,
				Size = Vector3.one,
				Position = position + Vector3.new(math.random(-14, 14), math.random(16, 34), math.random(-14, 14)),
				Parent = dossier,
			})
			local emetteur: ParticleEmitter = creer("ParticleEmitter", {
				Rate = 0,
				Lifetime = NumberRange.new(0.9, 1.5),
				Speed = NumberRange.new(16, 30),
				SpreadAngle = Vector2.new(180, 180),
				Drag = 3,
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 0) }),
				Color = ColorSequence.new(teinte, Color3.new(1, 1, 1)),
				LightEmission = 1,
				Acceleration = Vector3.new(0, -14, 0),
				Parent = source,
			})
			emetteur:Emit(40)
			Debris:AddItem(source, 2)
		end)
	end
end

-- Petite gerbe de flocons à l'atelier du joueur
function Effets.gerbe(position: Vector3, teinte: Color3, nombre: number)
	local source: Part = creer("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.one,
		Position = position + Vector3.new(0, 2, 0),
		Parent = dossier,
	})
	local emetteur: ParticleEmitter = creer("ParticleEmitter", {
		Rate = 0,
		Lifetime = NumberRange.new(0.7, 1.2),
		Speed = NumberRange.new(10, 20),
		SpreadAngle = Vector2.new(60, 60),
		EmissionDirection = Enum.NormalId.Top,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) }),
		Color = ColorSequence.new(teinte),
		LightEmission = 0.8,
		Acceleration = Vector3.new(0, -30, 0),
		Parent = source,
	})
	emetteur:Emit(nombre)
	Debris:AddItem(source, 1.6)
end

-- ───────────── Démarrage ─────────────

function Effets.demarrer()
	dossier = creer("Folder", { Name = "EffetsLocaux", Parent = Workspace })
	creerNeige()
	majTempete()
	Workspace:GetAttributeChangedSignal("Tempete"):Connect(majTempete)
	Players.PlayerRemoving:Connect(retirerBoule)

	RunService.RenderStepped:Connect(function(dt: number)
		for _, joueur in Players:GetPlayers() do
			majBoule(joueur, dt)
		end
		local camera = Workspace.CurrentCamera
		if camera and supportNeige then
			supportNeige.Position = camera.CFrame.Position + Vector3.new(0, 38, 0)
		end
		majRayon()
	end)
end

return Effets
