#!/usr/bin/env bash
# Vérifie tout le projet : build Rojo, analyse de types, lint, format, tests, simulation.
# Outils attendus dans le PATH : rojo, luau, luau-lsp (analyse avec les types Roblox), selene, stylua.
# TYPES_ROBLOX = chemin vers globalTypes.d.luau (https://github.com/JohnnyMorganz/luau-lsp, scripts/).
set -u
cd "$(dirname "$0")"
TYPES_ROBLOX="${TYPES_ROBLOX:-/opt/rbx/globalTypes.d.luau}"
echec=0

echo "== rojo build =="
rojo build -o build/jeu.rbxl || echec=1

echo "== analyse de types (luau-lsp analyze, mode strict) =="
rojo sourcemap default.project.json -o sourcemap.json >/dev/null
sortie=$(luau-lsp analyze --definitions="$TYPES_ROBLOX" --sourcemap=sourcemap.json --no-strict-dm-types src 2>&1 \
	| grep -v '^\[INFO\]\|^\[WARN\]' | sort -u)
if [ -n "$sortie" ]; then echo "$sortie"; echec=1; else echo "aucune erreur"; fi

echo "== selene =="
if [ -f roblox.yml ] || [ -z "${SELENE_STD_SECOURS:-}" ]; then
	selene src || echec=1
else
	(cd tests && selene --config selene_config_secours.toml ../src) || echec=1
fi

echo "== stylua --check =="
stylua --check src tests || echec=1

echo "== tests =="
python3 tests/lancer.py || echec=1

echo "== simulation d'équilibrage =="
python3 tests/lancer.py simulation | tail -7 || echec=1

[ $echec -eq 0 ] && echo "TOUT EST OK" || echo "DES VÉRIFICATIONS ONT ÉCHOUÉ"
exit $echec
