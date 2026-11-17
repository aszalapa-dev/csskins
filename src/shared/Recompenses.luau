--!strict
--[[
	Recompenses.luau — logique pure des récompenses quotidiennes, cadeaux de temps de jeu et quêtes.
	Module pur (aucune API Roblox) : testé dans tests/.
]]

local Config = require(script.Parent.Config)
local ModeleDonnees = require(script.Parent.ModeleDonnees)

type Donnees = ModeleDonnees.Donnees
type QueteActive = ModeleDonnees.QueteActive

export type ReglageQuete = {
	Id: string,
	Groupe: number,
	Type: string,
	Objectif: number,
	Texte: string,
	Flocons: number,
}

local Recompenses = {}

-- Numéro du jour (UTC) pour un os.time()
function Recompenses.numeroJour(temps: number): number
	return temps // 86400
end

-- ───────────── Récompense quotidienne (7 jours) ─────────────

-- Renvoie (disponible, jourDeSerie) : jourDeSerie = 1..7, la case qui sera (ou a été) réclamée aujourd'hui.
function Recompenses.etatQuotidien(quotidien: { Serie: number, DernierJour: number }, jour: number): (boolean, number)
	local longueur = #Config.Quotidien
	if quotidien.DernierJour == jour then
		return false, math.clamp(quotidien.Serie, 1, longueur)
	end
	if quotidien.DernierJour == jour - 1 and quotidien.Serie >= 1 then
		return true, quotidien.Serie % longueur + 1 -- la série continue (après 7 on recommence à 1)
	end
	return true, 1 -- première fois ou série cassée
end

-- Marque la récompense du jour comme prise. Renvoie le jour de série réclamé, ou nil si déjà prise.
function Recompenses.reclamerQuotidien(quotidien: { Serie: number, DernierJour: number }, jour: number): number?
	local disponible, jourSerie = Recompenses.etatQuotidien(quotidien, jour)
	if not disponible then
		return nil
	end
	quotidien.Serie = jourSerie
	quotidien.DernierJour = jour
	return jourSerie
end

-- ───────────── Cadeaux de temps de jeu ─────────────

-- Remet les cadeaux à zéro si on a changé de jour
function Recompenses.rafraichirCadeaux(cadeaux: { Jour: number, Secondes: number, Reclames: { [string]: boolean } }, jour: number)
	if cadeaux.Jour ~= jour then
		cadeaux.Jour = jour
		cadeaux.Secondes = 0
		cadeaux.Reclames = {}
	end
end

function Recompenses.cadeauDisponible(
	cadeaux: { Jour: number, Secondes: number, Reclames: { [string]: boolean } },
	indice: number
): boolean
	local reglage = Config.Cadeaux[indice]
	if reglage == nil or cadeaux.Reclames[tostring(indice)] then
		return false
	end
	return cadeaux.Secondes >= reglage.Minutes * 60
end

-- ───────────── Quêtes quotidiennes ─────────────

Recompenses.ParId = {} :: { [string]: ReglageQuete }
for _, quete in Config.Quetes :: { ReglageQuete } do
	Recompenses.ParId[quete.Id] = quete
end

-- Les quêtes du jour : une par groupe, choisie de façon déterministe à partir du numéro du jour
-- (tous les joueurs ont les mêmes quêtes le même jour).
function Recompenses.quetesDuJour(jour: number): { QueteActive }
	local liste = {} :: { QueteActive }
	for groupe = 1, Config.NombreGroupesQuetes do
		local candidates = {} :: { ReglageQuete }
		for _, quete in Config.Quetes :: { ReglageQuete } do
			if quete.Groupe == groupe then
				table.insert(candidates, quete)
			end
		end
		if #candidates > 0 then
			local indice = (jour * 7 + groupe * 13) % #candidates + 1
			table.insert(liste, { Id = candidates[indice].Id, Progres = 0, Reclamee = false })
		end
	end
	return liste
end

-- Remplace les quêtes si on a changé de jour. Renvoie true si elles ont été renouvelées.
function Recompenses.rafraichirQuetes(quetes: { Jour: number, Liste: { QueteActive } }, jour: number): boolean
	if quetes.Jour == jour and #quetes.Liste > 0 then
		return false
	end
	quetes.Jour = jour
	quetes.Liste = Recompenses.quetesDuJour(jour)
	return true
end

-- Ajoute `montant` aux quêtes du type donné. Renvoie true si une quête a avancé.
function Recompenses.progresser(liste: { QueteActive }, typeQuete: string, montant: number): boolean
	local change = false
	for _, quete in liste do
		local reglage = Recompenses.ParId[quete.Id]
		if reglage ~= nil and reglage.Type == typeQuete and not quete.Reclamee and quete.Progres < reglage.Objectif then
			quete.Progres = math.min(reglage.Objectif, quete.Progres + montant)
			change = true
		end
	end
	return change
end

function Recompenses.queteTerminee(quete: QueteActive): boolean
	local reglage = Recompenses.ParId[quete.Id]
	return reglage ~= nil and quete.Progres >= reglage.Objectif
end

-- Marque la quête n° `indice` comme réclamée. Renvoie les flocons de base gagnés, ou nil si impossible.
function Recompenses.reclamerQuete(liste: { QueteActive }, indice: number): number?
	local quete = liste[indice]
	if quete == nil or quete.Reclamee or not Recompenses.queteTerminee(quete) then
		return nil
	end
	quete.Reclamee = true
	return Recompenses.ParId[quete.Id].Flocons
end

return Recompenses
