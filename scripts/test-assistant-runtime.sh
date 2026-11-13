#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/scripts/build-desktop-shell.sh" >/dev/null
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}"
settings_import=/tmp/nexora-qml-settings/root/usr/lib/x86_64-linux-gnu/qt6/qml
if [[ -d "$settings_import" ]]; then
  export QML2_IMPORT_PATH="${QML2_IMPORT_PATH:+$QML2_IMPORT_PATH:}$settings_import"
fi
"$ROOT/build/desktop/tst-assistant-backend"
if command -v timeout >/dev/null 2>&1; then
  timeout 30s "$ROOT/build/desktop/nexora-shell" "$ROOT/tests/qml/AssistantAppSmoke.qml"
else
  "$ROOT/build/desktop/nexora-shell" "$ROOT/tests/qml/AssistantAppSmoke.qml"
fi
