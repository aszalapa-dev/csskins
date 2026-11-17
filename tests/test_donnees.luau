-- Tests du modèle de données et de la migration.
local Config = require(script.Parent.Config)
local ModeleDonnees = require(script.Parent.ModeleDonnees)
local T = require(script.Parent.outils)

T.test("données par défaut", function()
	local d = ModeleDonnees.defaut()
	T.egal(d.Version, Config.Donnees.Version)
	T.egal(d.Flocons, 0)
	T.egal(d.ZoneMax, 1)
	for _, nom in Config.OrdreAmeliorations do
		T.egal(d.Ameliorations[nom], 0, nom)
	end
	T.vrai(ModeleDonnees.defaut() ~= ModeleDonnees.defaut(), "chaque appel crée une nouvelle table")
	T.vrai(ModeleDonnees.defaut().Snowpals ~= ModeleDonnees.defaut().Snowpals)
end)

T.test("migration : valeurs invalides -> défaut", function()
	for _, brut in { 0, "abc", true } :: { any } do
		T.egal(ModeleDonnees.migrer(brut).Flocons, 0)
	end
	T.egal(ModeleDonnees.migrer(nil).Version, Config.Donnees.Version)
end)

T.test("migration v1 -> v2", function()
	local v1 = {
		Version = 1,
		Flocons = 500,
		Zones = { true, true },
		Ameliorations = { Gants = 4 },
		Snowpals = { flocon = { N = 2, D = 0 } },
	}
	local d = ModeleDonnees.migrer(v1)
	T.egal(d.Version, Config.Donnees.Version)
	T.egal(d.ZoneMax, 2, "Zones converties en ZoneMax")
	T.egal((d :: any).Zones, nil)
	T.egal(d.FloconsTotal, 500, "FloconsTotal initialisé")
	T.egal(d.Ameliorations.Gants, 4, "valeurs existantes gardées")
	T.egal(d.Ameliorations.Pelle, 0, "champs manquants complétés")
	T.egal(d.Snowpals.flocon.N, 2)
	T.egal(d.Tutoriel, false)
	T.egal(d.Quotidien.Serie, 0)
end)

T.test("migration : données sans version traitées comme v1", function()
	local d = ModeleDonnees.migrer({ Flocons = 10 })
	T.egal(d.Version, Config.Donnees.Version)
	T.egal(d.FloconsTotal, 10)
end)

T.test("migration : bornes et corruption", function()
	local d = ModeleDonnees.migrer({
		Version = 2,
		Flocons = -50,
		FloconsTotal = 0 / 0,
		Rebirths = 9999,
		ZoneMax = 42,
		Ameliorations = { Gants = 1e6, Pelle = -3, Bottes = "x" },
		Snowpals = { flocon = "cassé", boulette = { N = 2.7, D = -1 } },
		Quotidien = "cassé",
		Stats = { Boules = 3 },
	})
	T.egal(d.Flocons, 0)
	T.egal(d.FloconsTotal, 0)
	T.egal(d.Rebirths, Config.Rebirth.Max)
	T.egal(d.ZoneMax, #Config.Zones)
	T.egal(d.Ameliorations.Gants, Config.Ameliorations.Gants.NiveauMax)
	T.egal(d.Ameliorations.Pelle, 0)
	T.egal(d.Ameliorations.Bottes, 0)
	T.egal(d.Snowpals.flocon, nil)
	T.egal(d.Snowpals.boulette.N, 2)
	T.egal(d.Snowpals.boulette.D, 0)
	T.egal(d.Quotidien.Serie, 0, "table corrompue remplacée")
	T.egal(d.Stats.Boules, 3)
	T.egal(d.Stats.PlusGrosse, 0)
end)

T.test("migration idempotente", function()
	local d = ModeleDonnees.migrer({ Version = 1, Flocons = 77, Zones = { true, true, true } })
	local d2 = ModeleDonnees.migrer(d)
	T.egal(d2.ZoneMax, 3)
	T.egal(d2.Flocons, 77)
	T.egal(d2.FloconsTotal, 77)
end)

T.bilan("test_donnees")
return true
