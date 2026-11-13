#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
required=(
  "README.md"
  "docs/architecture.md"
  "docs/plan-de-projet.md"
  "config/package-lists/nexora.list.chroot"
  "scripts/validate-phase1.sh"
)
fail=0
for rel in "${required[@]}"; do
  if [[ -s "$ROOT/$rel" ]]; then
    printf 'OK   %s\n' "$rel"
  else
    printf 'MANQUE ou vide : %s\n' "$rel" >&2
    fail=1
  fi
done

if grep -qE 'Debian stable|Debian' "$ROOT/docs/architecture.md" &&
   grep -q 'KDE Plasma' "$ROOT/docs/architecture.md" &&
   grep -q 'GRUB' "$ROOT/docs/architecture.md" &&
   grep -q 'live-build' "$ROOT/docs/architecture.md"; then
  printf 'OK   choix d’architecture cohérents (Debian, Plasma, GRUB, live-build)\n'
else
  printf 'ERREUR : choix d’architecture incomplets\n' >&2
  fail=1
fi

if (( fail )); then
  exit 1
fi
printf '\nPhase 1 : squelette valide. Aucun build ni accès disque effectué.\n'
