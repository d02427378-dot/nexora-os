#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="${NEXORA_SHELL_BIN:-$ROOT/build/desktop/nexora-shell}"
HARNESS="${NEXORA_BROWSER_HARNESS:-$ROOT/tests/qml/BrowserWindowSmoke.qml}"
PORT=18765
LOG="$(mktemp)"
SERVER_LOG="$(mktemp)"
SERVER_PID=""
cleanup() {
  if [[ -n "$SERVER_PID" ]]; then kill "$SERVER_PID" 2>/dev/null || true; fi
  rm -f "$LOG" "$SERVER_LOG"
}
trap cleanup EXIT

if [[ ! -x "$BINARY" ]]; then
  "$ROOT/scripts/build-desktop-shell.sh"
fi

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$ROOT/tests/http" >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
ready=0
for _ in $(seq 1 30); do
  if curl --silent --fail "http://127.0.0.1:$PORT/health.html" >/dev/null; then
    ready=1
    break
  fi
  sleep 0.1
done
if [[ $ready -ne 1 ]]; then
  cat "$SERVER_LOG" >&2
  echo "Le serveur loopback de test n’a pas démarré sur le port $PORT." >&2
  exit 1
fi

set +e
if command -v xvfb-run >/dev/null 2>&1; then
  timeout "${NEXORA_BROWSER_SMOKE_TIMEOUT:-15s}" xvfb-run -a "$BINARY" "$HARNESS" >"$LOG" 2>&1
else
  QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}" \
    timeout "${NEXORA_BROWSER_SMOKE_TIMEOUT:-15s}" "$BINARY" "$HARNESS" >"$LOG" 2>&1
fi
status=$?
set -e
cat "$LOG"
if [[ $status -ne 0 ]]; then
  echo "Échec du smoke test navigateur (code $status)." >&2
  exit "$status"
fi
if grep -E 'QQmlApplicationEngine failed|ReferenceError|TypeError|Cannot assign|Cannot load|Error:.*QML|Timeout pendant' "$LOG"; then
  echo "Erreur QML ou timeout détecté dans le navigateur." >&2
  exit 1
fi
if ! grep -q 'Chargement HTTP local confirmé par Qt WebEngine' "$LOG"; then
  echo "Qt WebEngine n’a pas confirmé le chargement de la page locale." >&2
  exit 1
fi
printf 'OK : BrowserApp a chargé la fixture HTTP depuis 127.0.0.1; aucune page publique n’a été contactée.\n'
