#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/scripts/install-nexora-vm.sh"

bash -n "$INSTALLER"
OUTPUT="$(bash "$INSTALLER" --dry-run)"

grep -Fq 'Simulation uniquement : aucun paquet ni fichier ne sera modifié.' <<<"$OUTPUT"
grep -Fq 'qml6-module-qtwebengine' <<<"$OUTPUT"
grep -Fq 'firefox-esr' <<<"$OUTPUT"
grep -Fq 'Aucune opération de partitionnement' <<<"$OUTPUT"

printf '%s\n' 'OK : syntaxe valide, dépendances attendues présentes et dry-run sans changements.'
