-- outils.luau — mini-bibliothèque d'assertions pour les tests en Luau pur.
local Outils = {}
local reussis, echoues = 0, 0

function Outils.test(nom: string, corps: () -> ())
	local ok, erreur = pcall(corps)
	if ok then
		reussis += 1
	else
		echoues += 1
		print("ECHEC  " .. nom .. " : " .. tostring(erreur))
	end
end

function Outils.egal(obtenu: any, attendu: any, message: string?)
	if obtenu ~= attendu then
		error(string.format("%s : obtenu %s, attendu %s", message or "valeur", tostring(obtenu), tostring(attendu)), 2)
	end
end

function Outils.proche(obtenu: number, attendu: number, tolerance: number?, message: string?)
	if math.abs(obtenu - attendu) > (tolerance or 1e-6) then
		error(string.format("%s : obtenu %s, attendu ~%s", message or "valeur", tostring(obtenu), tostring(attendu)), 2)
	end
end

function Outils.vrai(condition: any, message: string?)
	if not condition then
		error(message or "condition fausse", 2)
	end
end

function Outils.bilan(nomSuite: string)
	print(string.format("%-22s %d réussis, %d échoués", nomSuite, reussis, echoues))
	if echoues > 0 then
		error("Des tests ont échoué dans " .. nomSuite)
	end
	reussis, echoues = 0, 0
end

return Outils
