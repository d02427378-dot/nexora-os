#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
OUT="$TMP/grub.cfg"

"$ROOT/scripts/render-grub-config.sh" \
  ABCD-1234 11111111-2222-3333-4444-555555555555 \
  aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee "$OUT"

grep -Fq 'set timeout=10' "$OUT"
grep -Fq 'set default=nexora' "$OUT"
grep -Fq 'search --no-floppy --fs-uuid --set=root ABCD-1234' "$OUT"
grep -Fq 'chainloader /EFI/Microsoft/Boot/bootmgfw.efi' "$OUT"
grep -Fq 'root=UUID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' "$OUT"
grep -Fq 'menuentry "Rester sur Windows" --id=windows' "$OUT"
grep -Fq 'menuentry "Lancer Nexora OS" --id=nexora' "$OUT"
grep -Fq 'menuentry "Basculer « se souvenir de mon choix »"' "$OUT"
if grep -q '__[A-Z_]*__' "$OUT"; then
  echo 'Échec : marqueur UUID non remplacé.' >&2
  exit 1
fi

if command -v grub-script-check >/dev/null 2>&1; then
  grub-script-check "$OUT"
  echo 'Syntaxe contrôlée par grub-script-check.'
else
  echo 'INFO : grub-script-check absent; validation statique seulement, syntaxe runtime à vérifier en VM.'
fi

if "$ROOT/scripts/render-grub-config.sh" ABCD-1234 11111111-2222-3333-4444-555555555555 \
  aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee "$OUT" >/dev/null 2>&1; then
  echo 'Échec : le générateur a écrasé un fichier existant.' >&2
  exit 1
fi

echo 'OK : menu Windows/Nexora, temporisation, UUID et garde anti-écrasement vérifiés.'
