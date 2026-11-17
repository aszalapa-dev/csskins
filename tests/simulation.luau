--[[
	simulation.luau — simule un joueur « moyen » pour vérifier l'équilibrage.
	Objectifs : 1er Snowpal + 1re amélioration en moins de 2 min, 1er rebirth vers 1 h 30.
	Lancer : python3 tests/lancer.py simulation
]]
local Config = require(script.Parent.Config)
local Formules = require(script.Parent.Formules)
local ModeleDonnees = require(script.Parent.ModeleDonnees)

local RAYON_TERRAIN = 75 -- distance du terrain au centre (voir ConstructeurMap)
local PAUSE_PAR_CYCLE = 5 -- secondes perdues (menus, hésitations, effets)
local DUREE_MAX = 4 * 3600

-- Générateur pseudo-aléatoire déterministe (LCG) pour des résultats reproductibles
local graine = 12345
local function alea(): number
	graine = (graine * 1103515245 + 12345) % 2147483648
	return graine / 2147483648
end

local function simuler(verbeux: boolean)
	local d = ModeleDonnees.defaut()
	local temps = 0
	local jalons = {}
	local function jalon(nom: string)
		if jalons[nom] == nil then
			jalons[nom] = temps
			if verbeux then
				print(string.format("  %-28s %s", nom, Formules.formaterDuree(temps)))
			end
		end
	end
	local gainsRecents = 0 -- flocons/s lissés

	while temps < DUREE_MAX and d.Rebirths < 2 do
		local socles = Formules.socles(d.Ameliorations.Socles, false)
		local mult = Formules.multiplicateurFlocons({
			Rebirths = d.Rebirths,
			EntreesIndex = Formules.entreesIndex(d.Index),
			Amis = 0,
			DoubleFlocons = false,
			VIP = false,
			BoostFlocons = false,
		})
		local zone = d.ZoneMax
		local vitesse = Formules.vitesse(d.Ameliorations.Bottes)
		local taille = Formules.tailleMax(d.Ameliorations.Gants)
		local croissance = Formules.croissanceParStud(d.Ameliorations.Pelle, false, false, false)
		local tempsRoulage = (taille - Config.Boule.TailleDepart) / croissance / vitesse
		local trajet = 2 * (Config.Zones[zone].RayonMin + 10 - RAYON_TERRAIN) / vitesse
		local cycle = tempsRoulage + trajet + PAUSE_PAR_CYCLE

		local revenu = Formules.revenuEquipe(Formules.equipe(d.Snowpals, socles))
		local gain = (Formules.valeurBoule(taille, zone) + revenu * cycle) * mult
		temps += cycle
		d.Flocons += gain
		d.FloconsTotal += gain
		gainsRecents = gainsRecents * 0.7 + (gain / cycle) * 0.3

		-- Tirage du Snowpal
		local pal = Formules.tirerSnowpal(zone, Formules.chance(d.Ameliorations.Chance, taille), alea(), alea())
		local ex = d.Snowpals[pal.Id] or { N = 0, D = 0 }
		ex.N += 1
		d.Snowpals[pal.Id] = ex
		d.Index[pal.Id] = true
		jalon("Premier Snowpal")
		if pal.Rarete >= 5 then
			jalon("Premier Legendaire+")
		end
		-- Fusion automatique
		while ex.N >= Config.Dore.CoutFusion + 1 do
			ex.N -= Config.Dore.CoutFusion
			ex.D += 1
			d.Index[pal.Id .. "_D"] = true
			jalon("Premier dore")
		end

		-- Achats : on achète ce qui se rembourse vite, sinon on économise pour le rebirth
		local achete = true
		while achete do
			achete = false
			local budget = math.max(60, gainsRecents * 300) -- au plus 5 min de gains par achat
			local meilleur, meilleurPrix = nil, math.huge
			for _, nom in Config.OrdreAmeliorations do
				local prix = Formules.prixAmelioration(nom, d.Ameliorations[nom])
				if prix and prix < meilleurPrix then
					meilleur, meilleurPrix = nom, prix
				end
			end
			local zoneSuivante = Config.Zones[d.ZoneMax + 1]
			if zoneSuivante and zoneSuivante.Prix <= d.Flocons then
				d.Flocons -= zoneSuivante.Prix
				d.ZoneMax += 1
				jalon("Zone " .. d.ZoneMax)
				achete = true
			elseif meilleur and meilleurPrix <= d.Flocons and meilleurPrix <= budget then
				d.Flocons -= meilleurPrix
				d.Ameliorations[meilleur] += 1
				jalon("Premiere amelioration")
				achete = true
			end
		end

		if Formules.peutRebirth(d) then
			if verbeux then
				local a = d.Ameliorations
				print(
					string.format(
						"  [avant rebirth] Gants %d Pelle %d Bottes %d Chance %d Socles %d | cycle %.0fs | %s flocons/s | index %d/%d",
						a.Gants,
						a.Pelle,
						a.Bottes,
						a.Chance,
						a.Socles,
						cycle,
						Formules.formater(gainsRecents),
						Formules.entreesIndex(d.Index),
						#require(script.Parent.Catalogue).Liste * 2
					)
				)
			end
			Formules.appliquerRebirth(d)
			jalon("Rebirth " .. d.Rebirths)
		end
	end
	return jalons, d
end

print("=== Simulation d'équilibrage Snowpal Rollers ===")
local jalons = simuler(true)

local function verifier(nom: string, minimum: number, maximum: number)
	local t = jalons[nom]
	local ok = t ~= nil and t >= minimum and t <= maximum
	print(
		string.format(
			"%s %-24s %s (attendu entre %s et %s)",
			if ok then "OK  " else "ECHEC",
			nom,
			if t then Formules.formaterDuree(t) else "jamais",
			Formules.formaterDuree(minimum),
			Formules.formaterDuree(maximum)
		)
	)
	return ok
end

local tout = true
tout = verifier("Premier Snowpal", 10, 60) and tout
tout = verifier("Premiere amelioration", 15, 120) and tout
tout = verifier("Zone 2", 8 * 60, 25 * 60) and tout
tout = verifier("Zone 3", 30 * 60, 65 * 60) and tout
tout = verifier("Rebirth 1", 75 * 60, 105 * 60) and tout
if not tout then
	error("Equilibrage hors cible : ajuster Config")
end
print("Equilibrage dans la cible.")
