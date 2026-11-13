#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="$ROOT/build/desktop/nexora-shell"
if [[ ! -x "$BINARY" ]]; then
  "$ROOT/scripts/build-desktop-shell.sh"
fi
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}"
if command -v timeout >/dev/null 2>&1; then
  timeout 15s "$BINARY" "$ROOT/tests/qml/CodeEditorWindowSmoke.qml"
else
  "$BINARY" "$ROOT/tests/qml/CodeEditorWindowSmoke.qml"
fi
