--!strict
--[[
	Formules.luau — toutes les formules d'économie du jeu.
	Module pur (aucune API Roblox) : utilisé par le serveur, le client (affichage) et les tests.
]]

local Config = require(script.Parent.Config)
local Catalogue = require(script.Parent.Catalogue)
local ModeleDonnees = require(script.Parent.ModeleDonnees)

type Donnees = ModeleDonnees.Donnees

export type MembreEquipe = { Id: string, Dore: boolean, Revenu: number }

-- Tout ce qui influence le multiplicateur de flocons d'un joueur
export type Contexte = {
	Rebirths: number,
	EntreesIndex: number,
	Amis: number,
	DoubleFlocons: boolean,
	VIP: boolean,
	BoostFlocons: boolean,
}

local Formules = {}

-- ───────────── Améliorations ─────────────

function Formules.niveauMax(nom: string): number
	local reglage = (Config.Ameliorations :: { [string]: any })[nom]
	return if reglage then reglage.NiveauMax else 0
end

-- Prix pour passer du niveau `niveau` au niveau suivant (nil si déjà au maximum ou inconnu)
function Formules.prixAmelioration(nom: string, niveau: number): number?
	local reglage = (Config.Ameliorations :: { [string]: any })[nom]
	if reglage == nil or niveau >= reglage.NiveauMax then
		return nil
	end
	return math.floor(reglage.PrixBase * reglage.Croissance ^ niveau)
end

function Formules.tailleMax(niveauGants: number): number
	return Config.Boule.TailleMaxBase + Config.Boule.TailleMaxParNiveau * niveauGants
end

-- Diamètre gagné par stud parcouru
function Formules.croissanceParStud(niveauPelle: number, rouleurPro: boolean, boost: boolean, tempete: boolean): number
	local valeur = Config.Boule.CroissanceParStud * (1 + Config.Boule.CroissanceParNiveau * niveauPelle)
	if rouleurPro then
		valeur *= Config.MultiplicateurRouleurPro
	end
	if boost then
		valeur *= Config.MultiplicateurBoost
	end
	if tempete then
		valeur *= Config.Tempete.MultiplicateurCroissance
	end
	return valeur
end

function Formules.vitesse(niveauBottes: number): number
	return Config.Deplacement.VitesseBase + Config.Deplacement.VitesseParNiveau * niveauBottes
end

function Formules.socles(niveauSocles: number, gamepass: boolean): number
	local nombre = math.min(Config.Equipe.SoclesBase + niveauSocles, Config.Equipe.SoclesMax)
	if gamepass then
		nombre += Config.Equipe.SoclesGamepass
	end
	return nombre
end

-- ───────────── Zones ─────────────

-- Numéro de zone pour une distance au centre de la map (0 = village ou hors île)
function Formules.zoneDepuisDistance(distance: number): number
	for _, zone in Config.Zones do
		if distance >= zone.RayonMin and distance < zone.RayonMax then
			return zone.Id
		end
	end
	return 0
end

function Formules.multiplicateurZone(zone: number): number
	local reglage = Config.Zones[zone]
	return if reglage then reglage.Multiplicateur else 1
end

-- ───────────── Flocons ─────────────

function Formules.multiplicateurFlocons(contexte: Contexte): number
	local valeur = 1 + Config.Rebirth.BonusParRebirth * contexte.Rebirths
	valeur *= 1 + Config.BonusIndexParEntree * contexte.EntreesIndex
	valeur *= 1 + math.min(Config.Social.BonusParAmi * contexte.Amis, Config.Social.BonusAmisMax)
	if contexte.DoubleFlocons then
		valeur *= 2
	end
	if contexte.VIP then
		valeur *= 1 + Config.BonusVIP
	end
	if contexte.BoostFlocons then
		valeur *= Config.MultiplicateurBoost
	end
	return valeur
end

-- Valeur d'une boule livrée, AVANT multiplicateur de flocons du joueur
function Formules.valeurBoule(taille: number, zone: number): number
	return Config.Boule.ValeurBase * taille ^ Config.Boule.ExposantValeur * Formules.multiplicateurZone(zone)
end

-- ───────────── Chance et tirage ─────────────

-- Multiplicateur de chance : amélioration « Trèfle givré » + taille de la boule
function Formules.chance(niveauChance: number, taille: number): number
	local parNiveau = Config.Ameliorations.Chance.BonusParNiveau
	local bonusTaille = math.max(0, taille - Config.Boule.TailleDepart) * Config.Boule.ChanceParTaille
	return (1 + parNiveau * niveauChance) * (1 + bonusTaille)
end

-- Probabilité de chaque rareté pour un multiplicateur de chance donné (somme = 1).
-- La chance multiplie les raretés non communes ; le « Commun » prend le reste.
function Formules.probabilites(chance: number): { number }
	local resultat = table.create(#Config.Raretes, 0)
	local somme = 0
	for rang = 2, #Config.Raretes do
		local p = Config.Raretes[rang].Probabilite * math.max(chance, 0)
		resultat[rang] = p
		somme += p
	end
	if somme > Config.PlafondChanceNonCommun then
		local facteur = Config.PlafondChanceNonCommun / somme
		for rang = 2, #Config.Raretes do
			resultat[rang] *= facteur
		end
		somme = Config.PlafondChanceNonCommun
	end
	resultat[1] = 1 - somme
	return resultat
end

-- `alea` : nombre dans [0, 1). Renvoie le rang de rareté tiré.
function Formules.tirerRarete(chance: number, alea: number): number
	local probabilites = Formules.probabilites(chance)
	-- On parcourt du plus rare au plus commun pour que les petites probabilités soient exactes
	local cumul = 0
	for rang = #probabilites, 2, -1 do
		cumul += probabilites[rang]
		if alea < cumul then
			return rang
		end
	end
	return 1
end

-- Tire un Snowpal de la zone. `alea1` choisit la rareté, `alea2` le Snowpal parmi les candidats.
function Formules.tirerSnowpal(zone: number, chance: number, alea1: number, alea2: number): Catalogue.Snowpal
	local rang = Formules.tirerRarete(chance, alea1)
	local candidats = Catalogue.candidats(zone, rang)
	-- Sécurité : si une zone n'a pas de Snowpal de cette rareté, on descend d'un rang
	while #candidats == 0 and rang > 1 do
		rang -= 1
		candidats = Catalogue.candidats(zone, rang)
	end
	if #candidats == 0 then
		return Catalogue.Liste[1]
	end
	local indice = math.clamp(math.floor(alea2 * #candidats) + 1, 1, #candidats)
	return candidats[indice]
end

-- ───────────── Snowpals et revenus ─────────────

-- Revenu de base (flocons/s) d'un Snowpal, avant multiplicateur de flocons
function Formules.revenuSnowpal(id: string, dore: boolean): number
	local snowpal = Catalogue.ParId[id]
	if snowpal == nil then
		return 0
	end
	local revenu = Config.Raretes[snowpal.Rarete].Revenu * Formules.multiplicateurZone(snowpal.Zone)
	if dore then
		revenu *= Config.Dore.MultiplicateurRevenu
	end
	return revenu
end

-- Les `nombreSocles` meilleurs exemplaires possédés, du plus rentable au moins rentable.
-- (L'équipe est choisie automatiquement : pas de gestion d'inventaire à faire sur téléphone.)
function Formules.equipe(snowpals: { [string]: ModeleDonnees.Exemplaires }, nombreSocles: number): { MembreEquipe }
	local types = {} :: { { Id: string, Dore: boolean, Revenu: number, Quantite: number } }
	for id, exemplaires in snowpals do
		if Catalogue.ParId[id] ~= nil then
			if exemplaires.D > 0 then
				table.insert(
					types,
					{ Id = id, Dore = true, Revenu = Formules.revenuSnowpal(id, true), Quantite = exemplaires.D }
				)
			end
			if exemplaires.N > 0 then
				table.insert(
					types,
					{ Id = id, Dore = false, Revenu = Formules.revenuSnowpal(id, false), Quantite = exemplaires.N }
				)
			end
		end
	end
	table.sort(types, function(a, b)
		if a.Revenu ~= b.Revenu then
			return a.Revenu > b.Revenu
		end
		if a.Id ~= b.Id then
			return a.Id < b.Id -- ordre stable et déterministe
		end
		return a.Dore and not b.Dore
	end)
	local equipe = {} :: { MembreEquipe }
	for _, groupe in types do
		for _ = 1, groupe.Quantite do
			if #equipe >= nombreSocles then
				return equipe
			end
			table.insert(equipe, { Id = groupe.Id, Dore = groupe.Dore, Revenu = groupe.Revenu })
		end
	end
	return equipe
end

function Formules.revenuEquipe(equipe: { MembreEquipe }): number
	local total = 0
	for _, membre in equipe do
		total += membre.Revenu
	end
	return total
end

function Formules.entreesIndex(index: { [string]: boolean }): number
	local nombre = 0
	for _ in index do
		nombre += 1
	end
	return nombre
end

-- Flocons gagnés pendant l'absence du joueur (déjà multipliés par `multiplicateur`)
function Formules.revenuHorsLigne(secondesAbsence: number, revenuParSeconde: number, multiplicateur: number): number
	local secondes = math.clamp(secondesAbsence, 0, Config.Equipe.HorsLigneMaxSecondes)
	return math.floor(secondes * revenuParSeconde * multiplicateur * Config.Equipe.HorsLigneRendement)
end

-- Capacité de la tirelire du terrain
function Formules.reserveMax(revenuParSeconde: number, multiplicateur: number): number
	return math.max(50, revenuParSeconde * multiplicateur * Config.Equipe.ReserveMaxSecondes)
end

-- ───────────── Rebirth ─────────────

function Formules.prixRebirth(rebirths: number): number?
	if rebirths >= Config.Rebirth.Max then
		return nil
	end
	return math.floor(Config.Rebirth.PrixBase * Config.Rebirth.Croissance ^ rebirths)
end

-- Applique un rebirth sur les données (ne vérifie PAS le prix : voir peutRebirth).
-- On garde : Snowpals, Index, rebirths, récompenses. On remet à zéro : flocons, améliorations, zones.
function Formules.appliquerRebirth(donnees: Donnees)
	donnees.Rebirths += 1
	donnees.Flocons = 0
	donnees.Reserve = 0
	donnees.ZoneMax = 1
	for nom in donnees.Ameliorations do
		donnees.Ameliorations[nom] = 0
	end
end

function Formules.peutRebirth(donnees: Donnees): boolean
	local prix = Formules.prixRebirth(donnees.Rebirths)
	return prix ~= nil and donnees.Flocons >= prix
end

-- ───────────── Récompenses proportionnelles à la progression ─────────────

-- Facteur appliqué aux récompenses fixes (quotidien, cadeaux, quêtes) pour qu'elles restent utiles
function Formules.echelleRecompense(donnees: Donnees): number
	return Formules.multiplicateurZone(donnees.ZoneMax) * (1 + donnees.Rebirths)
end

-- Estimation des flocons gagnés par seconde par un joueur actif (revenus passifs + boules)
function Formules.gainEstimeParSeconde(donnees: Donnees, multiplicateur: number, nombreSocles: number): number
	local passif = Formules.revenuEquipe(Formules.equipe(donnees.Snowpals, nombreSocles))
	local boule = Formules.valeurBoule(Formules.tailleMax(donnees.Ameliorations.Gants or 0), donnees.ZoneMax)
	return (passif + boule / 40) * multiplicateur -- une boule maximale toutes les ~40 s
end

-- Contenu d'un paquet de flocons acheté en Robux
function Formules.floconsPaquet(secondes: number, minimum: number, donnees: Donnees, gainParSeconde: number): number
	return math.floor(math.max(minimum * Formules.echelleRecompense(donnees), secondes * gainParSeconde))
end

-- ───────────── Affichage ─────────────

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

-- 1234 -> "1.23K", 15300000 -> "15.3M"
function Formules.formater(nombre: number): string
	if nombre ~= nombre then
		return "0"
	end
	local valeur = math.floor(math.abs(nombre))
	if valeur < 1000 then
		return tostring(valeur)
	end
	local rang = 1
	local reduit = valeur
	while reduit >= 1000 and rang < #SUFFIXES do
		reduit /= 1000
		rang += 1
	end
	local texte
	if reduit >= 100 then
		texte = string.format("%d", math.floor(reduit))
	elseif reduit >= 10 then
		texte = string.format("%.1f", math.floor(reduit * 10) / 10)
	else
		texte = string.format("%.2f", math.floor(reduit * 100) / 100)
	end
	return texte .. SUFFIXES[rang]
end

-- 125 -> "2:05"
function Formules.formaterDuree(secondes: number): string
	local total = math.max(0, math.floor(secondes))
	if total >= 3600 then
		return string.format("%d:%02d:%02d", total // 3600, (total % 3600) // 60, total % 60)
	end
	return string.format("%d:%02d", total // 60, total % 60)
end

return Formules
