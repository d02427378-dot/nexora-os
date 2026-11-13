#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
runner=""
for candidate in qmltestrunner; do
  if command -v "$candidate" >/dev/null 2>&1; then
    runner="$(command -v "$candidate")"
    break
  fi
done
if [[ -z "$runner" && -x /usr/lib/qt6/bin/qmltestrunner ]]; then
  runner=/usr/lib/qt6/bin/qmltestrunner
fi
if [[ -z "$runner" ]]; then
  cat >&2 <<'EOF'
qmltestrunner absent. Installez les outils de test Qt 6 et le module QML QtTest
(qml6-module-qttest sur les systèmes Debian/Ubuntu compatibles).
EOF
  exit 127
fi

export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}"
TEST_SETTINGS_FILE=/tmp/nexora-desktop-shell-settings-test.ini
rm -f "$TEST_SETTINGS_FILE"
trap 'rm -f "$TEST_SETTINGS_FILE"' EXIT
"$runner" -input "$ROOT/tests/qml" -o -,txt "$@"
