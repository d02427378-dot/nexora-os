#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML_FILE="$ROOT/src/desktop/NexoraShell.qml"
BINARY="${NEXORA_SHELL_BIN:-$ROOT/build/desktop/nexora-shell}"

if [[ ! -x "$BINARY" ]]; then
  "$ROOT/scripts/build-desktop-shell.sh"
fi

exec "$BINARY" "$QML_FILE" "$@"
