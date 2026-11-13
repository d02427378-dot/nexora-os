#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build/desktop}"
PREFIX="${CMAKE_INSTALL_PREFIX:-/usr/local}"

cmake -S "$ROOT/src/desktop" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-RelWithDebInfo}" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build "$BUILD_DIR" --parallel "${BUILD_JOBS:-2}"
printf '\nShell compilé : %s/nexora-shell\n' "$BUILD_DIR"
printf 'Aucune installation système n’a été effectuée.\n'
