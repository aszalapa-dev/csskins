-- Tests des formules d'économie, du tirage et du rebirth.
local Config = require(script.Parent.Config)
local Catalogue = require(script.Parent.Catalogue)
local Formules = require(script.Parent.Formules)
local ModeleDonnees = require(script.Parent.ModeleDonnees)
local T = require(script.Parent.outils)

T.test("prix des améliorations croissants et bornés", function()
	for _, nom in Config.OrdreAmeliorations do
		local precedent = 0
		local max = Formules.niveauMax(nom)
		T.vrai(max > 0, nom .. " a un niveau max")
		for niveau = 0, max - 1 do
			local prix = Formules.prixAmelioration(nom, niveau)
			T.vrai(prix ~= nil and prix > precedent, nom .. " prix croissant au niveau " .. niveau)
			precedent = prix :: number
		end
		T.egal(Formules.prixAmelioration(nom, max), nil, nom .. " plus de prix au max")
	end
	T.egal(Formules.prixAmelioration("Inconnue", 0), nil)
	T.egal(Formules.prixAmelioration("Gants", 0), Config.Ameliorations.Gants.PrixBase)
end)

T.test("taille, vitesse, croissance, socles", function()
	T.egal(Formules.tailleMax(0), Config.Boule.TailleMaxBase)
	T.vrai(Formules.tailleMax(10) > Formules.tailleMax(9))
	T.egal(Formules.vitesse(0), 16)
	local base = Formules.croissanceParStud(0, false, false, false)
	T.proche(Formules.croissanceParStud(0, true, false, false), base * Config.MultiplicateurRouleurPro)
	T.proche(Formules.croissanceParStud(0, true, true, true), base * 1.5 * 2 * 2)
	T.egal(Formules.socles(0, false), Config.Equipe.SoclesBase)
	T.egal(Formules.socles(99, false), Config.Equipe.SoclesMax)
	T.egal(Formules.socles(99, true), Config.Equipe.SoclesMax + Config.Equipe.SoclesGamepass)
	T.vrai(
		Config.Equipe.SoclesBase + Config.Ameliorations.Socles.NiveauMax == Config.Equipe.SoclesMax,
		"socles cohérents"
	)
end)

T.test("zones par distance", function()
	T.egal(Formules.zoneDepuisDistance(0), 0)
	T.egal(Formules.zoneDepuisDistance(Config.RayonVillage - 1), 0)
	T.egal(Formules.zoneDepuisDistance(Config.RayonVillage), 1)
	T.egal(Formules.zoneDepuisDistance(250), 2)
	T.egal(Formules.zoneDepuisDistance(300), 3)
	T.egal(Formules.zoneDepuisDistance(Config.RayonIle + 1), 0)
	-- les anneaux se touchent sans trou
	for i = 1, #Config.Zones - 1 do
		T.egal(Config.Zones[i].RayonMax, Config.Zones[i + 1].RayonMin)
	end
end)

T.test("multiplicateur de flocons", function()
	local c = { Rebirths = 0, EntreesIndex = 0, Amis = 0, DoubleFlocons = false, VIP = false, BoostFlocons = false }
	T.proche(Formules.multiplicateurFlocons(c), 1)
	c.Rebirths = 2
	T.proche(Formules.multiplicateurFlocons(c), 2)
	c.Amis = 10 -- plafonné
	T.proche(Formules.multiplicateurFlocons(c), 2 * (1 + Config.Social.BonusAmisMax))
	c.Amis = 0
	c.DoubleFlocons, c.VIP, c.BoostFlocons = true, true, true
	T.proche(Formules.multiplicateurFlocons(c), 2 * 2 * 1.2 * 2)
end)

T.test("probabilités : somme 1, plafond, monotonie", function()
	for _, chance in { 0, 1, 2, 5, 20, 1000 } do
		local p = Formules.probabilites(chance)
		local somme = 0
		for _, v in p do
			T.vrai(v >= 0, "probabilité positive")
			somme += v
		end
		T.proche(somme, 1, 1e-9, "somme pour chance " .. chance)
		T.vrai(p[1] >= 1 - Config.PlafondChanceNonCommun - 1e-9, "il reste toujours du Commun")
	end
	local sommeBase = 0
	for _, r in Config.Raretes do
		sommeBase += r.Probabilite
	end
	T.proche(sommeBase, 1, 1e-9, "Config.Raretes somme à 1")
	T.vrai(Formules.probabilites(3)[6] > Formules.probabilites(1)[6], "plus de chance = plus de Mythique")
end)

T.test("tirage de rareté", function()
	T.egal(Formules.tirerRarete(1, 0), 6, "alea 0 -> le plus rare")
	T.egal(Formules.tirerRarete(1, 0.9999), 1, "alea ~1 -> Commun")
	T.egal(Formules.tirerRarete(0, 0), 1, "chance 0 -> toujours Commun")
	-- distribution empirique proche de la théorie
	local compte = table.create(6, 0)
	local n = 200000
	for i = 0, n - 1 do
		local rang = Formules.tirerRarete(1, (i + 0.5) / n)
		compte[rang] += 1
	end
	for rang, r in Config.Raretes do
		T.proche(compte[rang] / n, r.Probabilite, 0.001, "fréquence " .. r.Id)
	end
end)

T.test("tirage de Snowpal : bonne zone, toujours valide", function()
	for zone = 1, #Config.Zones do
		for i = 0, 99 do
			local pal = Formules.tirerSnowpal(zone, 3, i / 100, (i * 37 % 100) / 100)
			T.egal(pal.Zone, zone)
			T.vrai(Catalogue.ParId[pal.Id] == pal)
		end
		for rang = 1, #Config.Raretes do
			T.vrai(#Catalogue.candidats(zone, rang) >= 1, "zone " .. zone .. " a la rareté " .. rang)
		end
	end
	T.egal(Formules.tirerSnowpal(1, 1, 0.5, 0.999999).Rarete, 1)
end)

T.test("catalogue : identifiants uniques et valides", function()
	local vus = {}
	for _, pal in Catalogue.Liste do
		T.vrai(not vus[pal.Id], "id en double : " .. pal.Id)
		vus[pal.Id] = true
		T.vrai(not string.find(pal.Id, "_D$"), "un id ne doit pas finir par _D")
		T.vrai(Config.Raretes[pal.Rarete] ~= nil and Config.Zones[pal.Zone] ~= nil)
	end
	T.egal(Catalogue.tailleIndex(), #Catalogue.Liste * 2)
end)

T.test("équipe : les meilleurs d'abord, limitée aux socles", function()
	local snowpals = {
		flocon = { N = 5, D = 0 },
		roi_givre = { N = 1, D = 0 },
		carotin = { N = 0, D = 1 },
		inconnu = { N = 3, D = 3 },
	}
	local equipe = Formules.equipe(snowpals, 3)
	T.egal(#equipe, 3)
	T.egal(equipe[1].Id, "roi_givre")
	T.egal(equipe[2].Id, "carotin")
	T.egal(equipe[2].Dore, true)
	T.egal(equipe[3].Id, "flocon")
	T.proche(Formules.revenuEquipe(equipe), 90 + 3 * 4 + 1)
	T.egal(#Formules.equipe(snowpals, 50), 7, "pas plus que le nombre possédé (inconnus ignorés)")
	T.egal(#Formules.equipe({}, 5), 0)
	T.proche(Formules.revenuSnowpal("comete", false), 400 * 4)
	T.egal(Formules.revenuSnowpal("nexistepas", false), 0)
end)

T.test("rebirth", function()
	local d = ModeleDonnees.defaut()
	T.egal(Formules.peutRebirth(d), false)
	d.Flocons = Formules.prixRebirth(0) :: number
	d.Ameliorations.Gants = 12
	d.ZoneMax = 3
	d.Snowpals.flocon = { N = 2, D = 1 }
	d.Index.flocon = true
	d.FloconsTotal = 123
	T.egal(Formules.peutRebirth(d), true)
	Formules.appliquerRebirth(d)
	T.egal(d.Rebirths, 1)
	T.egal(d.Flocons, 0)
	T.egal(d.ZoneMax, 1)
	T.egal(d.Ameliorations.Gants, 0)
	T.egal(d.Snowpals.flocon.N, 2, "les Snowpals sont gardés")
	T.egal(d.Index.flocon, true, "l'Index est gardé")
	T.egal(d.FloconsTotal, 123, "le total (classement) est gardé")
	T.vrai((Formules.prixRebirth(1) :: number) > (Formules.prixRebirth(0) :: number))
	T.egal(Formules.prixRebirth(Config.Rebirth.Max), nil)
end)

T.test("hors ligne, tirelire, paquets", function()
	T.egal(Formules.revenuHorsLigne(-50, 10, 1), 0)
	T.egal(Formules.revenuHorsLigne(100, 10, 2), math.floor(100 * 10 * 2 * Config.Equipe.HorsLigneRendement))
	T.egal(Formules.revenuHorsLigne(1e9, 10, 1), Formules.revenuHorsLigne(Config.Equipe.HorsLigneMaxSecondes, 10, 1))
	T.vrai(Formules.reserveMax(0, 1) >= 50)
	local d = ModeleDonnees.defaut()
	T.egal(Formules.floconsPaquet(900, 2500, d, 0), 2500, "minimum garanti")
	T.egal(Formules.floconsPaquet(900, 2500, d, 100), 90000, "proportionnel au revenu")
	d.Rebirths, d.ZoneMax = 1, 2
	T.egal(Formules.floconsPaquet(900, 2500, d, 0), 2500 * 4 * 2)
end)

T.test("formatage", function()
	T.egal(Formules.formater(0), "0")
	T.egal(Formules.formater(999), "999")
	T.egal(Formules.formater(1000), "1.00K")
	T.egal(Formules.formater(1234), "1.23K")
	T.egal(Formules.formater(15300000), "15.3M")
	T.egal(Formules.formater(999999), "999K")
	T.egal(Formules.formater(2.5e9), "2.50B")
	T.egal(Formules.formater(0 / 0), "0")
	T.egal(Formules.formaterDuree(125), "2:05")
	T.egal(Formules.formaterDuree(3725), "1:02:05")
	T.egal(Formules.formaterDuree(-4), "0:00")
end)

T.bilan("test_formules")
return true
