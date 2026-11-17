-- Tests des récompenses quotidiennes, cadeaux et quêtes.
local Config = require(script.Parent.Config)
local Recompenses = require(script.Parent.Recompenses)
local T = require(script.Parent.outils)

T.test("numéro du jour", function()
	T.egal(Recompenses.numeroJour(0), 0)
	T.egal(Recompenses.numeroJour(86399), 0)
	T.egal(Recompenses.numeroJour(86400), 1)
end)

T.test("récompense quotidienne : série de 7 jours", function()
	local q = { Serie = 0, DernierJour = 0 }
	local jour = 20000
	for attendu = 1, 7 do
		T.egal(Recompenses.reclamerQuotidien(q, jour), attendu)
		T.egal(Recompenses.reclamerQuotidien(q, jour), nil, "une seule fois par jour")
		local dispo, case = Recompenses.etatQuotidien(q, jour)
		T.egal(dispo, false)
		T.egal(case, attendu)
		jour += 1
	end
	T.egal(Recompenses.reclamerQuotidien(q, jour), 1, "après le jour 7 on repart au jour 1")
	T.egal(Recompenses.reclamerQuotidien(q, jour + 2), 1, "série cassée -> jour 1")
	T.egal(Recompenses.reclamerQuotidien(q, jour + 3), 2)
	T.egal(#Config.Quotidien, 7)
end)

T.test("cadeaux de temps de jeu", function()
	local c = { Jour = 5, Secondes = 0, Reclames = {} }
	T.egal(Recompenses.cadeauDisponible(c, 1), false)
	c.Secondes = Config.Cadeaux[1].Minutes * 60
	T.egal(Recompenses.cadeauDisponible(c, 1), true)
	T.egal(Recompenses.cadeauDisponible(c, 2), false)
	T.egal(Recompenses.cadeauDisponible(c, 99), false)
	c.Reclames["1"] = true
	T.egal(Recompenses.cadeauDisponible(c, 1), false)
	Recompenses.rafraichirCadeaux(c, 5)
	T.egal(c.Reclames["1"], true, "même jour : rien ne change")
	Recompenses.rafraichirCadeaux(c, 6)
	T.egal(c.Secondes, 0)
	T.egal(c.Reclames["1"], nil)
	local precedent = 0
	for _, cadeau in Config.Cadeaux do
		T.vrai(cadeau.Minutes > precedent, "cadeaux triés par durée")
		precedent = cadeau.Minutes
	end
end)

T.test("quêtes du jour : 3 quêtes, une par groupe, déterministes", function()
	for jour = 20000, 20030 do
		local liste = Recompenses.quetesDuJour(jour)
		T.egal(#liste, 3)
		local groupes = {}
		for _, q in liste do
			local reglage = Recompenses.ParId[q.Id]
			T.vrai(reglage ~= nil)
			T.vrai(not groupes[reglage.Groupe], "un seul par groupe")
			groupes[reglage.Groupe] = true
			T.egal(q.Progres, 0)
		end
		T.egal(Recompenses.quetesDuJour(jour)[1].Id, liste[1].Id)
	end
	-- toutes les quêtes finissent par sortir
	local vues = {}
	for jour = 1, 60 do
		for _, q in Recompenses.quetesDuJour(jour) do
			vues[q.Id] = true
		end
	end
	for _, reglage in Config.Quetes do
		T.vrai(vues[reglage.Id], reglage.Id .. " jamais proposée")
	end
end)

T.test("progression et réclamation des quêtes", function()
	local liste =
		{ { Id = "Boules10", Progres = 0, Reclamee = false }, { Id = "Rares2", Progres = 0, Reclamee = false } }
	T.egal(Recompenses.progresser(liste, "Boules", 4), true)
	T.egal(liste[1].Progres, 4)
	T.egal(liste[2].Progres, 0)
	T.egal(Recompenses.progresser(liste, "TypeInconnu", 4), false)
	T.egal(Recompenses.reclamerQuete(liste, 1), nil, "pas encore terminée")
	Recompenses.progresser(liste, "Boules", 100)
	T.egal(liste[1].Progres, 10, "plafonné à l'objectif")
	T.egal(Recompenses.progresser(liste, "Boules", 1), false, "terminée : n'avance plus")
	T.egal(Recompenses.reclamerQuete(liste, 1), 150)
	T.egal(Recompenses.reclamerQuete(liste, 1), nil, "une seule fois")
	T.egal(Recompenses.reclamerQuete(liste, 9), nil)
end)

T.test("renouvellement des quêtes", function()
	local q = { Jour = 0, Liste = {} }
	T.egal(Recompenses.rafraichirQuetes(q, 100), true)
	T.egal(#q.Liste, 3)
	q.Liste[1].Progres = 3
	T.egal(Recompenses.rafraichirQuetes(q, 100), false)
	T.egal(q.Liste[1].Progres, 3)
	T.egal(Recompenses.rafraichirQuetes(q, 101), true)
	T.egal(q.Liste[1].Progres, 0)
end)

T.bilan("test_recompenses")
return true
