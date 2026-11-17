--!strict
--[[
	Catalogue.luau — la liste de tous les Snowpals (contenu, pas de réglages d'économie).
	Module pur (aucune API Roblox) : utilisable par les tests.
	Le revenu d'un Snowpal vient de Config (rareté × multiplicateur de zone).
]]

export type Chapeau = "Aucun" | "HautDeForme" | "Bonnet" | "Couronne" | "Sapin" | "Etoile" | "Cristaux" | "Aureole"

export type Snowpal = {
	Id: string,
	Nom: string,
	Rarete: number, -- rang dans Config.Raretes (1 = Commun ... 6 = Mythique)
	Zone: number,
	Corps: { number }, -- couleur {R, G, B}
	Accent: { number },
	Chapeau: Chapeau,
	Brillant: boolean, -- matériau Neon pour les raretés élevées
}

local Catalogue = {}

local function pal(
	id: string,
	nom: string,
	rarete: number,
	zone: number,
	corps: { number },
	accent: { number },
	chapeau: Chapeau,
	brillant: boolean?
): Snowpal
	return {
		Id = id,
		Nom = nom,
		Rarete = rarete,
		Zone = zone,
		Corps = corps,
		Accent = accent,
		Chapeau = chapeau,
		Brillant = brillant == true,
	}
end

-- L'ordre de cette liste est l'ordre d'affichage dans l'Index.
Catalogue.Liste = {
	-- Zone 1 : Prairie Givrée
	pal("flocon", "Flocon", 1, 1, { 250, 252, 255 }, { 255, 140, 40 }, "Aucun"),
	pal("boulette", "Boulette", 1, 1, { 240, 245, 250 }, { 220, 60, 60 }, "Bonnet"),
	pal("carotin", "Carotin", 2, 1, { 255, 236, 215 }, { 255, 120, 20 }, "HautDeForme"),
	pal("echarpy", "Écharpy", 2, 1, { 245, 250, 255 }, { 60, 190, 90 }, "Bonnet"),
	pal("glacon_chic", "Glaçon Chic", 3, 1, { 170, 220, 255 }, { 30, 60, 140 }, "HautDeForme"),
	pal("sapinou", "Sapinou", 4, 1, { 190, 240, 200 }, { 30, 140, 70 }, "Sapin"),
	pal("roi_givre", "Roi Givre", 5, 1, { 200, 235, 255 }, { 255, 200, 50 }, "Couronne", true),
	pal("etoile_polaire", "Étoile Polaire", 6, 1, { 255, 250, 200 }, { 255, 220, 80 }, "Etoile", true),
	-- Zone 2 : Bois Cristal
	pal("menthol", "Menthol", 1, 2, { 200, 250, 235 }, { 40, 170, 140 }, "Aucun"),
	pal("myrtille", "Myrtille", 1, 2, { 200, 210, 255 }, { 80, 70, 200 }, "Bonnet"),
	pal("cristalin", "Cristalin", 2, 2, { 180, 245, 240 }, { 0, 200, 200 }, "Cristaux"),
	pal("bonbonnet", "Bonbonnet", 2, 2, { 255, 215, 230 }, { 240, 80, 140 }, "Bonnet"),
	pal("turquoise", "Turquoise", 3, 2, { 120, 230, 220 }, { 20, 110, 130 }, "HautDeForme"),
	pal("amethyste", "Améthyste", 4, 2, { 215, 180, 255 }, { 130, 60, 220 }, "Cristaux", true),
	pal("baron_cristal", "Baron Cristal", 5, 2, { 160, 250, 240 }, { 255, 200, 50 }, "Couronne", true),
	pal("comete", "Comète", 6, 2, { 150, 220, 255 }, { 255, 255, 255 }, "Etoile", true),
	-- Zone 3 : Pic Aurore
	pal("aurorin", "Aurorin", 1, 3, { 225, 205, 255 }, { 150, 90, 230 }, "Aucun"),
	pal("guimauve", "Guimauve", 1, 3, { 255, 220, 240 }, { 255, 130, 190 }, "Bonnet"),
	pal("nebulo", "Nébulo", 2, 3, { 190, 170, 255 }, { 90, 60, 200 }, "Aureole"),
	pal("prismo", "Prismo", 2, 3, { 200, 255, 230 }, { 255, 110, 200 }, "Cristaux"),
	pal("galaxo", "Galaxo", 3, 3, { 110, 90, 200 }, { 255, 230, 120 }, "Etoile", true),
	pal("solaris", "Solaris", 4, 3, { 255, 200, 110 }, { 255, 90, 40 }, "Aureole", true),
	pal("empereur_aurore", "Empereur Aurore", 5, 3, { 190, 140, 255 }, { 255, 215, 70 }, "Couronne", true),
	pal("arc_eternel", "Arc-en-ciel Éternel", 6, 3, { 255, 160, 220 }, { 120, 255, 220 }, "Aureole", true),
} :: { Snowpal }

-- Accès rapide par identifiant
Catalogue.ParId = {} :: { [string]: Snowpal }
for _, snowpal in Catalogue.Liste do
	Catalogue.ParId[snowpal.Id] = snowpal
end

-- Snowpals d'une zone et d'une rareté données (pour le tirage)
function Catalogue.candidats(zone: number, rarete: number): { Snowpal }
	local resultat = {}
	for _, snowpal in Catalogue.Liste do
		if snowpal.Zone == zone and snowpal.Rarete == rarete then
			table.insert(resultat, snowpal)
		end
	end
	return resultat
end

-- Nombre total d'entrées de l'Index (normal + doré)
function Catalogue.tailleIndex(): number
	return #Catalogue.Liste * 2
end

return Catalogue
