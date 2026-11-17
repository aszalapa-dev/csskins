#!/usr/bin/env python3
"""
Lance les tests en Luau pur (sans Roblox).
Les modules de src/shared utilisent `require(script.Parent.X)` comme dans Roblox ; ce script les
assemble dans un seul fichier avec un faux `script` et un faux `require`, puis l'exécute avec `luau`.

Usage : python3 tests/lancer.py            -> tous les tests (tests/test_*.luau)
        python3 tests/lancer.py simulation -> tests/simulation.luau
"""
import os, re, subprocess, sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PURS = ["Config", "Catalogue", "ModeleDonnees", "Formules", "Recompenses"]  # modules sans API Roblox

PRELUDE = """
local __modules, __cache = {}, {}
local function __require(ref)
	local nom = ref.__nom
	if __cache[nom] == nil then
		assert(__modules[nom], "module inconnu : " .. tostring(nom))
		__cache[nom] = __modules[nom]()
	end
	return __cache[nom]
end
local __script = { Parent = setmetatable({}, { __index = function(_, cle) return { __nom = cle } end }) }
"""

def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        source = f.read()
    # `export type` n'est permis qu'au premier niveau d'un fichier : on le neutralise dans le bundle
    return re.sub(r"(?m)^export type", "type", source)

def assembler(fichiers_test):
    morceaux = [PRELUDE]
    for nom in PURS:
        source = lire(os.path.join(RACINE, "src", "shared", nom + ".luau"))
        morceaux.append(f'__modules["{nom}"] = function()\nlocal script, require = __script, __require\n{source}\nend\n')
    morceaux.append(f'__modules["outils"] = function()\n{lire(os.path.join(RACINE, "tests", "outils.luau"))}\nend\n')
    for chemin in fichiers_test:
        nom = os.path.splitext(os.path.basename(chemin))[0]
        morceaux.append(f'__modules["{nom}"] = function()\nlocal script, require = __script, __require\n{lire(chemin)}\nend\n')
        morceaux.append(f'__require({{ __nom = "{nom}" }})\n')
    return "\n".join(morceaux)

def main():
    dossier = os.path.join(RACINE, "tests")
    if len(sys.argv) > 1:
        fichiers = [os.path.join(dossier, sys.argv[1] + ".luau")]
    else:
        fichiers = sorted(os.path.join(dossier, f) for f in os.listdir(dossier) if f.startswith("test_") and f.endswith(".luau"))
    sortie = os.path.join(RACINE, "build", "_tests_bundle.luau")
    os.makedirs(os.path.dirname(sortie), exist_ok=True)
    with open(sortie, "w", encoding="utf-8") as f:
        f.write(assembler(fichiers))
    sys.exit(subprocess.call(["luau", sortie] + sys.argv[2:]))

if __name__ == "__main__":
    main()
