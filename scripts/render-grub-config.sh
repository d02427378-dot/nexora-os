#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$ROOT/config/grub/grub.cfg.in"

usage() {
  cat >&2 <<'EOF'
Usage:
  render-grub-config.sh WINDOWS_ESP_UUID NEXORA_BOOT_UUID NEXORA_ROOT_UUID OUTPUT_FILE

Rend un fichier GRUB autonome à partir du modèle. OUTPUT_FILE doit ne pas exister.
Le script n’installe rien, ne lance pas grub-install/update-grub et ne modifie aucun disque.
EOF
}

if [[ $# -ne 4 ]]; then usage; exit 2; fi
windows_esp_uuid=$1
nexora_boot_uuid=$2
nexora_root_uuid=$3
output_file=$4

valid_uuid() { [[ "$1" =~ ^[[:xdigit:]]+(-[[:xdigit:]]+)*$ ]]; }
for pair in \
  "WINDOWS_ESP_UUID:$windows_esp_uuid" \
  "NEXORA_BOOT_UUID:$nexora_boot_uuid" \
  "NEXORA_ROOT_UUID:$nexora_root_uuid"; do
  name=${pair%%:*}
  value=${pair#*:}
  if ! valid_uuid "$value"; then
    printf 'UUID invalide pour %s : %s\n' "$name" "$value" >&2
    exit 2
  fi
done

if [[ -e "$output_file" ]]; then
  printf 'Refus d’écraser le fichier existant : %s\n' "$output_file" >&2
  exit 1
fi

mkdir -p -- "$(dirname -- "$output_file")"
python3 - "$TEMPLATE" "$output_file" "$windows_esp_uuid" "$nexora_boot_uuid" "$nexora_root_uuid" <<'PY'
from pathlib import Path
import sys

source, target, windows_esp, nexora_boot, nexora_root = sys.argv[1:]
text = Path(source).read_text(encoding="utf-8")
replacements = {
    "__WINDOWS_ESP_UUID__": windows_esp,
    "__NEXORA_BOOT_UUID__": nexora_boot,
    "__NEXORA_ROOT_UUID__": nexora_root,
}
for marker, value in replacements.items():
    if text.count(marker) != 1:
        raise SystemExit(f"Le modèle doit contenir exactement un marqueur {marker}")
    text = text.replace(marker, value)
if "__" in text:
    raise SystemExit("Marqueur non remplacé dans la configuration générée")
Path(target).write_text(text, encoding="utf-8")
PY
printf 'Configuration rendue : %s\n' "$output_file"
printf 'Aucune installation GRUB ni écriture sur disque n’a été effectuée.\n'
