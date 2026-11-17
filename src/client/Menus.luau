--!strict
--[[
	Menus.luau (client) — les fenêtres du jeu : Améliorer, Index, Cadeaux (quotidien + temps de jeu +
	quêtes), Boutique et Nouvel Hiver (rebirth).
	Chaque fenêtre est construite UNE fois ; ensuite seuls les textes et couleurs sont mis à jour.
	Les boutons ne font qu'envoyer une demande au serveur (Etat.action) : c'est lui qui décide.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalogue = require(ReplicatedStorage.Shared.Catalogue)
local Formules = require(ReplicatedStorage.Shared.Formules)
local Recompenses = require(ReplicatedStorage.Shared.Recompenses)
local Etat = require(script.Parent.Etat)
local Interface = require(script.Parent.Interface)

local creer = Interface.creer
local joueur = Players.LocalPlayer

type EtatJeu = { [string]: any }

local Menus = {}

-- Fonctions de mise à jour de chaque fenêtre (appelées quand l'état change et à l'ouverture)
local rafraichisseurs: { [string]: (etat: EtatJeu) -> () } = {}
local fenetres: { [string]: Interface.Fenetre } = {}

local function carte(parent: Instance, taille: UDim2, ordre: number?): Frame
	return creer("Frame", {
		Size = taille,
		LayoutOrder = ordre or 0,
		BackgroundColor3 = Interface.couleur("Panneau"),
		ZIndex = 21,
		Parent = parent,
	}, { Interface.coins(14) })
end

local function titreSection(parent: Instance, texte: string, ordre: number): TextLabel
	return Interface.texte({
		Text = texte,
		LayoutOrder = ordre,
		Size = UDim2.new(1, 0, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Interface.couleur("Attention"),
		TailleMax = 24,
		ZIndex = 21,
		Parent = parent,
	})
end

-- Bouton vert si actif, gris sinon
local function reglerBouton(bouton: TextButton, texte: string, actif: boolean, teinteActive: Color3?)
	bouton.Text = texte
	bouton.BackgroundColor3 = if actif then teinteActive or Interface.couleur("Succes") else Interface.couleur("Grise")
	bouton.Active = actif
end

-- Texte décrivant une récompense { Flocons, BoostFlocons, BoostCroissance }
local function texteRecompense(recompense: { [string]: number }, facteur: number): string
	local texte = Formules.formater((recompense.Flocons or 0) * facteur) .. " ❄️"
	if recompense.BoostFlocons then
		texte ..= " +💎"
	end
	if recompense.BoostCroissance then
		texte ..= " +🌨️"
	end
	return texte
end

-- ───────────────────────────── Améliorer ─────────────────────────────

local function descriptionAmelioration(nom: string, niveau: number): string
	local suivant = niveau + 1
	if nom == "Gants" then
		return string.format("Taille max : %.1f ➜ %.1f", Formules.tailleMax(niveau), Formules.tailleMax(suivant))
	elseif nom == "Pelle" then
		local base = Config.Boule.CroissanceParNiveau
		return string.format(
			"Vitesse de la boule : +%d %% ➜ +%d %%",
			math.floor(niveau * base * 100 + 0.5),
			math.floor(suivant * base * 100 + 0.5)
		)
	elseif nom == "Bottes" then
		return string.format("Vitesse : %d ➜ %d", Formules.vitesse(niveau), Formules.vitesse(suivant))
	elseif nom == "Chance" then
		local base = Config.Ameliorations.Chance.BonusParNiveau
		return string.format(
			"Chance : +%d %% ➜ +%d %%",
			math.floor(niveau * base * 100 + 0.5),
			math.floor(suivant * base * 100 + 0.5)
		)
	elseif nom == "Socles" then
		return string.format(
			"Socles : %d ➜ %d",
			Config.Equipe.SoclesBase + niveau,
			Config.Equipe.SoclesBase + suivant
		)
	end
	return ""
end

local function construireAmeliorer()
	local fenetre = Interface.fenetre("⬆️ Améliorer", 640, 500)
	fenetres.Ameliorer = fenetre
	local liste = Interface.liste(fenetre.Contenu, 8)

	-- Ligne « zone suivante »
	local ligneZone = carte(liste, UDim2.new(1, 0, 0, 74), 0)
	local texteZone = Interface.texte({
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -200, 1, -12),
		TextXAlignment = Enum.TextXAlignment.Left,
		TailleMax = 22,
		ZIndex = 22,
		Parent = ligneZone,
	})
	local boutonZone = Interface.bouton({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(170, 56),
		ZIndex = 22,
	}, function()
		Etat.action("AcheterZone")
	end)
	boutonZone.Parent = ligneZone

	type Ligne = { Niveau: TextLabel, Description: TextLabel, Bouton: TextButton }
	local lignes: { [string]: Ligne } = {}
	for ordre, nom in Config.OrdreAmeliorations do
		local reglage = (Config.Ameliorations :: { [string]: any })[nom]
		local ligne = carte(liste, UDim2.new(1, 0, 0, 80), ordre)
		Interface.texte({
			Text = reglage.Icone,
			Position = UDim2.fromOffset(8, 12),
			Size = UDim2.fromOffset(56, 56),
			TailleMax = 44,
			ZIndex = 22,
			Parent = ligne,
		})
		Interface.texte({
			Text = reglage.Nom,
			Position = UDim2.fromOffset(72, 6),
			Size = UDim2.new(1, -330, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			TailleMax = 24,
			ZIndex = 22,
			Parent = ligne,
		})
		local niveau = Interface.texte({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -190, 0, 8),
			Size = UDim2.fromOffset(110, 22),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = Interface.couleur("Attention"),
			TailleMax = 18,
			ZIndex = 22,
			Parent = ligne,
		})
		local description = Interface.texte({
			Position = UDim2.fromOffset(72, 34),
			Size = UDim2.new(1, -262, 0, 40),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Interface.couleur("TexteDoux"),
			TextWrapped = true,
			TailleMax = 17,
			ZIndex = 22,
			Parent = ligne,
		})
		local bouton = Interface.bouton({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(170, 58),
			ZIndex = 22,
		}, function()
			Etat.action("AcheterAmelioration", nom)
		end)
		bouton.Parent = ligne
		lignes[nom] = { Niveau = niveau, Description = description, Bouton = bouton }
	end

	rafraichisseurs.Ameliorer = function(etat: EtatJeu)
		local suivante = Config.Zones[etat.ZoneMax + 1]
		if suivante then
			texteZone.Text =
				`🗺️ Nouvelle zone : {suivante.Nom}\nFlocons x{suivante.Multiplicateur} et nouveaux Snowpals !`
			reglerBouton(boutonZone, `❄️ {Formules.formater(suivante.Prix)}`, etat.Flocons >= suivante.Prix)
			boutonZone.Visible = true
		else
			texteZone.Text = "🗺️ Toutes les zones sont débloquées !"
			boutonZone.Visible = false
		end
		for nom, ligne in lignes do
			local niveau = etat.Ameliorations[nom] or 0
			local prix = Formules.prixAmelioration(nom, niveau)
			ligne.Niveau.Text = `Niv. {niveau}/{Formules.niveauMax(nom)}`
			if prix == nil then
				ligne.Description.Text = (Config.Ameliorations :: { [string]: any })[nom].Description
				reglerBouton(ligne.Bouton, "MAX", false)
			else
				ligne.Description.Text = descriptionAmelioration(nom, niveau)
				reglerBouton(ligne.Bouton, `❄️ {Formules.formater(prix)}`, etat.Flocons >= prix)
			end
		end
	end
end

-- ───────────────────────────── Index ─────────────────────────────

local function construireIndex()
	local fenetre = Interface.fenetre("📖 Index des Snowpals", 700, 520)
	fenetres.Index = fenetre
	local entete = Interface.texte({
		Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Interface.couleur("Attention"),
		TailleMax = 20,
		ZIndex = 21,
		Parent = fenetre.Contenu,
	})
	-- Transparence : les chances de base de chaque rareté sont affichées
	local chances = {}
	for _, rarete in Config.Raretes do
		table.insert(chances, `{rarete.Nom} {string.format("%.3g", rarete.Probabilite * 100)} %`)
	end
	Interface.texte({
		Text = "Chances de base : " .. table.concat(chances, " · "),
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Interface.couleur("TexteDoux"),
		TailleMax = 14,
		ZIndex = 21,
		Parent = fenetre.Contenu,
	})
	local grille: ScrollingFrame = creer("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Interface.couleur("Principal"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 21,
		Parent = fenetre.Contenu,
	}, {
		creer("UIGridLayout", {
			CellSize = UDim2.fromOffset(156, 196),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		creer(
			"UIPadding",
			{ PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6) }
		),
	})

	type Cellule = {
		Cadre: Frame,
		Icone: Frame?,
		Nom: TextLabel,
		Rarete: TextLabel,
		Quantite: TextLabel,
		Fusion: TextButton,
		Signature: string,
	}
	local cellules: { [string]: Cellule } = {}
	for ordre, definition in Catalogue.Liste do
		local rarete = Config.Raretes[definition.Rarete]
		local cadre = carte(grille, UDim2.fromOffset(156, 196), ordre)
		creer("UIStroke", { Color = Interface.rgb(rarete.Couleur), Thickness = 3, Parent = cadre })
		local nom = Interface.texte({
			Position = UDim2.fromOffset(4, 88),
			Size = UDim2.new(1, -8, 0, 24),
			TailleMax = 19,
			ZIndex = 22,
			Parent = cadre,
		})
		local texteRarete = Interface.texte({
			Text = `{rarete.Nom} · {Config.Zones[definition.Zone].Nom}`,
			Position = UDim2.fromOffset(4, 112),
			Size = UDim2.new(1, -8, 0, 16),
			TextColor3 = Interface.rgb(rarete.Couleur),
			TailleMax = 13,
			ZIndex = 22,
			Parent = cadre,
		})
		local quantite = Interface.texte({
			Position = UDim2.fromOffset(4, 130),
			Size = UDim2.new(1, -8, 0, 20),
			TextColor3 = Interface.couleur("TexteDoux"),
			TailleMax = 16,
			ZIndex = 22,
			Parent = cadre,
		})
		local fusion = Interface.bouton({
			Position = UDim2.new(0, 8, 1, -42),
			Size = UDim2.new(1, -16, 0, 36),
			BackgroundColor3 = Interface.couleur("Dore"),
			TextColor3 = Color3.fromRGB(60, 40, 0),
			TailleMax = 16,
			ZIndex = 22,
		}, function()
			Etat.action("Fusionner", definition.Id)
		end)
		fusion.Parent = cadre
		cellules[definition.Id] = {
			Cadre = cadre,
			Icone = nil,
			Nom = nom,
			Rarete = texteRarete,
			Quantite = quantite,
			Fusion = fusion,
			Signature = "",
		}
	end

	rafraichisseurs.Index = function(etat: EtatJeu)
		local decouvertes = Formules.entreesIndex(etat.Index)
		entete.Text = `Découverts : {decouvertes}/{Catalogue.tailleIndex()}   ➜   +{math.floor(
			decouvertes * Config.BonusIndexParEntree * 100 + 0.5
		)} % de flocons`
		for id, cellule in cellules do
			local definition = Catalogue.ParId[id]
			local exemplaires = etat.Snowpals[id] or { N = 0, D = 0 }
			local decouvert = etat.Index[id] == true
			local doreDecouvert = etat.Index[id .. "_D"] == true
			-- L'icône n'est reconstruite que si son apparence change
			local signature = `{decouvert}{doreDecouvert}`
			if signature ~= cellule.Signature then
				cellule.Signature = signature
				if cellule.Icone then
					cellule.Icone:Destroy()
				end
				local icone = Interface.iconeSnowpal(id, doreDecouvert, decouvert, 84)
				icone.AnchorPoint = Vector2.new(0.5, 0)
				icone.Position = UDim2.new(0.5, 0, 0, 4)
				icone.Parent = cellule.Cadre
				cellule.Icone = icone
			end
			cellule.Nom.Text = if decouvert then definition.Nom else "???"
			cellule.Quantite.Text = if decouvert
				then `x{exemplaires.N}   ★ x{exemplaires.D}   (+{Formules.formater(Formules.revenuSnowpal(id, false))}/s)`
				else "Pas encore trouvé"
			local peutFusionner = exemplaires.N >= Config.Dore.CoutFusion
			cellule.Fusion.Visible = decouvert
			reglerBouton(
				cellule.Fusion,
				if peutFusionner
					then "★ Fusionner en doré"
					else `★ Doré : {exemplaires.N}/{Config.Dore.CoutFusion}`,
				peutFusionner,
				Interface.couleur("Dore")
			)
		end
	end
end

-- ───────────────────────────── Cadeaux : quotidien, temps de jeu, quêtes ─────────────────────────────

local function construireCadeaux()
	local fenetre = Interface.fenetre("🎁 Cadeaux et quêtes", 700, 520)
	fenetres.Cadeaux = fenetre
	local liste = Interface.liste(fenetre.Contenu, 8)

	-- 1) Récompense quotidienne
	titreSection(liste, "📅 Récompense quotidienne (7 jours)", 1)
	local rangeeJours: Frame = creer("Frame", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 92),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = liste,
	}, {
		creer("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	type CaseJour = { Cadre: Frame, Montant: TextLabel, Etat: TextLabel }
	local casesJours: { CaseJour } = {}
	for jour = 1, #Config.Quotidien do
		local cadre = carte(rangeeJours, UDim2.fromOffset(86, 92), jour)
		Interface.texte({
			Text = `Jour {jour}`,
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.fromOffset(0, 4),
			TailleMax = 17,
			ZIndex = 22,
			Parent = cadre,
		})
		local montant = Interface.texte({
			Size = UDim2.new(1, -6, 0, 34),
			Position = UDim2.fromOffset(3, 26),
			TextColor3 = Interface.couleur("TexteDoux"),
			TextWrapped = true,
			TailleMax = 15,
			ZIndex = 22,
			Parent = cadre,
		})
		local etatCase = Interface.texte({
			Size = UDim2.new(1, 0, 0, 26),
			Position = UDim2.new(0, 0, 1, -30),
			TailleMax = 22,
			ZIndex = 22,
			Parent = cadre,
		})
		casesJours[jour] = { Cadre = cadre, Montant = montant, Etat = etatCase }
	end
	local boutonQuotidien = Interface.bouton({ LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 50), ZIndex = 22 }, function()
		Etat.action("ReclamerQuotidien")
	end)
	boutonQuotidien.Parent = liste

	-- 2) Cadeaux de temps de jeu
	titreSection(liste, "⏰ Cadeaux de temps de jeu (chaque jour)", 4)
	local rangeeCadeaux: Frame = creer("Frame", {
		LayoutOrder = 5,
		Size = UDim2.new(1, 0, 0, 96),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = liste,
	}, {
		creer("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	type CaseCadeau = { Bouton: TextButton, Montant: TextLabel }
	local casesCadeaux: { CaseCadeau } = {}
	for indice, cadeau in Config.Cadeaux do
		local cadre = carte(rangeeCadeaux, UDim2.fromOffset(101, 96), indice)
		Interface.texte({
			Text = `🎁 {cadeau.Minutes} min`,
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.fromOffset(0, 4),
			TailleMax = 16,
			ZIndex = 22,
			Parent = cadre,
		})
		local montant = Interface.texte({
			Size = UDim2.new(1, -6, 0, 22),
			Position = UDim2.fromOffset(3, 26),
			TextColor3 = Interface.couleur("TexteDoux"),
			TailleMax = 14,
			ZIndex = 22,
			Parent = cadre,
		})
		local bouton = Interface.bouton({
			Position = UDim2.new(0, 6, 1, -42),
			Size = UDim2.new(1, -12, 0, 36),
			TailleMax = 17,
			ZIndex = 22,
		}, function()
			Etat.action("ReclamerCadeau", indice)
		end)
		bouton.Parent = cadre
		casesCadeaux[indice] = { Bouton = bouton, Montant = montant }
	end

	-- 3) Quêtes du jour
	titreSection(liste, "🎯 Quêtes du jour", 6)
	type LigneQuete = { Cadre: Frame, Texte: TextLabel, Barre: Frame, Bouton: TextButton }
	local lignesQuetes: { LigneQuete } = {}
	for indice = 1, Config.NombreGroupesQuetes do
		local cadre = carte(liste, UDim2.new(1, 0, 0, 64), 6 + indice)
		local texte = Interface.texte({
			Position = UDim2.fromOffset(12, 6),
			Size = UDim2.new(1, -200, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			TailleMax = 20,
			ZIndex = 22,
			Parent = cadre,
		})
		local fond: Frame = creer("Frame", {
			Position = UDim2.fromOffset(12, 38),
			Size = UDim2.new(1, -200, 0, 16),
			BackgroundColor3 = Interface.couleur("Fond"),
			ZIndex = 22,
			Parent = cadre,
		}, { Interface.coins(8) })
		local barre: Frame = creer("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = Interface.couleur("Succes"),
			ZIndex = 23,
			Parent = fond,
		}, { Interface.coins(8) })
		local bouton = Interface.bouton({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(168, 48),
			TailleMax = 18,
			ZIndex = 22,
		}, function()
			Etat.action("ReclamerQuete", indice)
		end)
		bouton.Parent = cadre
		lignesQuetes[indice] = { Cadre = cadre, Texte = texte, Barre = barre, Bouton = bouton }
	end

	rafraichisseurs.Cadeaux = function(etat: EtatJeu)
		local echelle = etat.Echelle or 1
		-- Quotidien
		local facteurQuotidien = echelle * (if etat.Passes.VIP then 2 else 1)
		for jour, case in casesJours do
			case.Montant.Text = texteRecompense(Config.Quotidien[jour], facteurQuotidien)
			local courant = jour == etat.Quotidien.Jour
			local dejaPris = jour < etat.Quotidien.Jour or (courant and not etat.Quotidien.Disponible)
			case.Etat.Text = if dejaPris then "✅" elseif courant then "🎁" else "🔒"
			case.Cadre.BackgroundColor3 = if courant and etat.Quotidien.Disponible
				then Interface.couleur("Succes")
				else Interface.couleur("Panneau")
		end
		reglerBouton(
			boutonQuotidien,
			if etat.Quotidien.Disponible
				then `Réclamer le jour {etat.Quotidien.Jour} !`
				else "Reviens demain pour la suite !",
			etat.Quotidien.Disponible
		)
		-- Temps de jeu
		local secondes = etat.Cadeaux.Secondes + Etat.depuisReception()
		for indice, case in casesCadeaux do
			local cadeau = Config.Cadeaux[indice]
			case.Montant.Text = texteRecompense(cadeau, echelle)
			if etat.Cadeaux.Reclames[tostring(indice)] then
				reglerBouton(case.Bouton, "✅", false)
			elseif secondes >= cadeau.Minutes * 60 then
				reglerBouton(case.Bouton, "Ouvrir !", true)
			else
				reglerBouton(case.Bouton, Formules.formaterDuree(cadeau.Minutes * 60 - secondes), false)
			end
		end
		-- Quêtes
		for indice, ligne in lignesQuetes do
			local quete = etat.Quetes[indice]
			local reglage = if quete then Recompenses.ParId[quete.Id] else nil
			ligne.Cadre.Visible = reglage ~= nil
			if quete ~= nil and reglage ~= nil then
				ligne.Texte.Text = reglage.Texte
				ligne.Barre.Size = UDim2.fromScale(math.clamp(quete.Progres / reglage.Objectif, 0, 1), 1)
				local recompense = Formules.formater(reglage.Flocons * echelle) .. " ❄️"
				if quete.Reclamee then
					reglerBouton(ligne.Bouton, "✅ Terminé", false)
				elseif quete.Progres >= reglage.Objectif then
					reglerBouton(ligne.Bouton, "Réclamer " .. recompense, true)
				else
					reglerBouton(ligne.Bouton, `{quete.Progres}/{reglage.Objectif} · {recompense}`, false)
				end
			end
		end
	end
end

-- ───────────────────────────── Boutique ─────────────────────────────

local function construireBoutique()
	local fenetre = Interface.fenetre("🛒 Boutique", 700, 520)
	fenetres.Boutique = fenetre
	local liste = Interface.liste(fenetre.Contenu, 8)

	local function grille(ordre: number): Frame
		return creer("Frame", {
			LayoutOrder = ordre,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 21,
			Parent = liste,
		}, {
			creer("UIGridLayout", {
				CellSize = UDim2.fromOffset(322, 132),
				CellPadding = UDim2.fromOffset(8, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
	end

	-- Carte d'article : icône, nom, description, bouton
	local function article(parent: Instance, ordre: number, reglage: { [string]: any }): TextButton
		local cadre = carte(parent, UDim2.fromOffset(322, 132), ordre)
		Interface.texte({
			Text = reglage.Icone,
			Position = UDim2.fromOffset(6, 8),
			Size = UDim2.fromOffset(60, 60),
			TailleMax = 48,
			ZIndex = 22,
			Parent = cadre,
		})
		Interface.texte({
			Text = reglage.Nom,
			Position = UDim2.fromOffset(72, 6),
			Size = UDim2.new(1, -80, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			TailleMax = 22,
			ZIndex = 22,
			Parent = cadre,
		})
		Interface.texte({
			Text = reglage.Description,
			Position = UDim2.fromOffset(72, 32),
			Size = UDim2.new(1, -80, 0, 44),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = Interface.couleur("TexteDoux"),
			TextWrapped = true,
			TailleMax = 15,
			ZIndex = 22,
			Parent = cadre,
		})
		local bouton = Interface.bouton({
			Position = UDim2.new(0, 10, 1, -50),
			Size = UDim2.new(1, -20, 0, 42),
			TailleMax = 20,
			ZIndex = 22,
		}, function() end)
		bouton.Parent = cadre
		return bouton
	end

	-- Prix réel en Robux, demandé une seule fois par article (appel protégé)
	local prixConnus: { [string]: string } = {}
	local function chargerPrix(cle: string, id: number, genre: Enum.InfoType)
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(id, genre)
			end)
			if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
				prixConnus[cle] = ` {info.PriceInRobux}`
				local etat = Etat.valeur
				if etat and rafraichisseurs.Boutique then
					rafraichisseurs.Boutique(etat)
				end
			end
		end)
	end

	titreSection(liste, "👑 Passes permanents", 1)
	local grillePasses = grille(2)
	local boutonsPasses: { [string]: TextButton } = {}
	for ordre, cle in Config.OrdreGamepasses do
		local reglage = (Config.Gamepasses :: { [string]: any })[cle]
		local bouton = article(grillePasses, ordre, reglage)
		boutonsPasses[cle] = bouton
		bouton.Activated:Connect(function()
			local etat = Etat.valeur
			if reglage.Id ~= 0 and not (etat and etat.Passes[cle]) then
				pcall(function()
					MarketplaceService:PromptGamePassPurchase(joueur, reglage.Id)
				end)
			end
		end)
		if reglage.Id ~= 0 then
			chargerPrix(cle, reglage.Id, Enum.InfoType.GamePass)
		end
	end

	titreSection(liste, "⚡ Boosts et sacs de flocons", 3)
	local grilleProduits = grille(4)
	local boutonsProduits: { [string]: TextButton } = {}
	for ordre, cle in Config.OrdreProduits do
		local reglage = (Config.Produits :: { [string]: any })[cle]
		local bouton = article(grilleProduits, ordre, reglage)
		boutonsProduits[cle] = bouton
		bouton.Activated:Connect(function()
			if reglage.Id ~= 0 then
				pcall(function()
					MarketplaceService:PromptProductPurchase(joueur, reglage.Id)
				end)
			end
		end)
		if reglage.Id ~= 0 then
			chargerPrix(cle, reglage.Id, Enum.InfoType.Product)
		end
	end
	Interface.texte({
		Text = "Aucun achat n'est nécessaire pour jouer. Demande toujours à un adulte avant d'acheter.",
		LayoutOrder = 5,
		Size = UDim2.new(1, 0, 0, 20),
		TextColor3 = Interface.couleur("TexteDoux"),
		TailleMax = 14,
		ZIndex = 21,
		Parent = liste,
	})

	rafraichisseurs.Boutique = function(etat: EtatJeu)
		for cle, bouton in boutonsPasses do
			local reglage = (Config.Gamepasses :: { [string]: any })[cle]
			if etat.Passes[cle] then
				reglerBouton(bouton, "✅ Possédé", false)
			elseif reglage.Id == 0 then
				reglerBouton(bouton, "Bientôt", false)
			else
				reglerBouton(bouton, "Acheter" .. (prixConnus[cle] or ""), true)
			end
		end
		for cle, bouton in boutonsProduits do
			local reglage = (Config.Produits :: { [string]: any })[cle]
			if reglage.Id == 0 then
				reglerBouton(bouton, "Bientôt", false)
			else
				reglerBouton(bouton, "Acheter" .. (prixConnus[cle] or ""), true, Interface.couleur("Principal"))
			end
		end
	end
end

-- Y a-t-il au moins un article réellement en vente ? (sinon, pas de rappel boutique)
function Menus.boutiqueActive(): boolean
	for _, reglage in Config.Gamepasses :: { [string]: any } do
		if reglage.Id ~= 0 then
			return true
		end
	end
	for _, reglage in Config.Produits :: { [string]: any } do
		if reglage.Id ~= 0 then
			return true
		end
	end
	return false
end

-- ───────────────────────────── Nouvel Hiver (rebirth) ─────────────────────────────

local function construireRebirth()
	local fenetre = Interface.fenetre("⭐ Nouvel Hiver", 580, 430)
	fenetres.Rebirth = fenetre
	Interface.texte({
		Text = "Recommence un nouvel hiver : tes flocons, améliorations et zones repartent à zéro...\n"
			.. "MAIS tu gardes tous tes Snowpals et ton Index, et tu gagnes un bonus de flocons permanent !",
		Size = UDim2.new(1, 0, 0, 96),
		TextWrapped = true,
		TextColor3 = Interface.couleur("TexteDoux"),
		TailleMax = 19,
		ZIndex = 21,
		Parent = fenetre.Contenu,
	})
	local texteBonus = Interface.texte({
		Position = UDim2.fromOffset(0, 104),
		Size = UDim2.new(1, 0, 0, 44),
		TextColor3 = Interface.couleur("Attention"),
		TailleMax = 32,
		ZIndex = 21,
		Parent = fenetre.Contenu,
	})
	local fond: Frame = creer("Frame", {
		Position = UDim2.fromOffset(20, 164),
		Size = UDim2.new(1, -40, 0, 34),
		BackgroundColor3 = Interface.couleur("Panneau"),
		ZIndex = 21,
		Parent = fenetre.Contenu,
	}, { Interface.coins(17) })
	local barre: Frame = creer("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(170, 110, 255),
		ZIndex = 22,
		Parent = fond,
	}, { Interface.coins(17) })
	local texteBarre = Interface.texte({ Size = UDim2.fromScale(1, 1), TailleMax = 20, ZIndex = 23, Parent = fond })
	local bouton = Interface.bouton({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(380, 70),
		TailleMax = 28,
		ZIndex = 22,
	}, function()
		Etat.action("Rebirth")
	end)
	bouton.Parent = fenetre.Contenu

	rafraichisseurs.Rebirth = function(etat: EtatJeu)
		local prix = Formules.prixRebirth(etat.Rebirths)
		local bonus = Config.Rebirth.BonusParRebirth
		if prix == nil then
			texteBonus.Text = `Hiver n°{etat.Rebirths} : maximum atteint !`
			barre.Size = UDim2.fromScale(1, 1)
			texteBarre.Text = "MAX"
			reglerBouton(bouton, "Tu es le roi de l'hiver 👑", false)
			return
		end
		texteBonus.Text =
			string.format("Bonus : x%.1f  ➜  x%.1f", 1 + bonus * etat.Rebirths, 1 + bonus * (etat.Rebirths + 1))
		barre.Size = UDim2.fromScale(math.clamp(etat.Flocons / prix, 0, 1), 1)
		texteBarre.Text = `{Formules.formater(etat.Flocons)} / {Formules.formater(prix)} ❄️`
		reglerBouton(
			bouton,
			if etat.Flocons >= prix then "⭐ Commencer un Nouvel Hiver !" else "Pas encore assez de flocons",
			etat.Flocons >= prix,
			Color3.fromRGB(170, 110, 255)
		)
	end
end

-- ───────────────────────────── Démarrage ─────────────────────────────

local function ouvrir(nom: string)
	local fenetre = fenetres[nom]
	if fenetre == nil then
		return
	end
	if fenetre.estOuverte() then
		fenetre.fermer()
		return
	end
	local etat = Etat.valeur
	if etat ~= nil then
		rafraichisseurs[nom](etat)
	end
	fenetre.ouvrir()
end

function Menus.ouvrir(nom: string)
	ouvrir(nom)
end

-- Construit toutes les fenêtres et renvoie les fonctions d'ouverture pour le HUD
function Menus.demarrer(): { [string]: () -> () }
	construireAmeliorer()
	construireIndex()
	construireCadeaux()
	construireBoutique()
	construireRebirth()

	local function rafraichirOuvertes(etat: EtatJeu)
		for nom, fenetre in fenetres do
			if fenetre.estOuverte() then
				rafraichisseurs[nom](etat)
			end
		end
	end
	Etat.surChangement(rafraichirOuvertes)
	-- Les minuteries des cadeaux avancent même sans nouvel état du serveur
	task.spawn(function()
		while true do
			task.wait(1)
			local etat = Etat.valeur
			if etat ~= nil and fenetres.Cadeaux.estOuverte() then
				rafraichisseurs.Cadeaux(etat)
			end
		end
	end)

	local fonctions: { [string]: () -> () } = {}
	for nom in fenetres do
		fonctions[nom] = function()
			ouvrir(nom)
		end
	end
	return fonctions
end

return Menus
