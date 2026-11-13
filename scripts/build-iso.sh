#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="$ROOT/build/iso"
IMAGE_NAME=nexora-os-trixie
MODE="${1:-build}"

usage() {
  cat <<'EOF'
Usage: scripts/build-iso.sh [--config-only|--build]

  --config-only  prépare/vérifie la configuration live-build, sans chroot ni ISO
  --build        construit l’ISO (mode par défaut, live-build doit tourner en root)

La construction écrit uniquement dans nexora-os/build/iso. Elle ne partitionne,
formate ni installe GRUB sur aucun disque.
EOF
}

case "$MODE" in
  --config-only|--build|build) ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

command -v lb >/dev/null 2>&1 || {
  echo "live-build (commande lb) absent. Utiliser un environnement Debian 13 Trixie dédié; voir docs/phase-6-iso-installation.md." >&2
  exit 127
}

if [[ -L "$WORKSPACE" ]]; then
  echo "Refus : le workspace ISO est un lien symbolique : $WORKSPACE" >&2
  exit 1
fi
if [[ -e "$WORKSPACE" && ! -f "$WORKSPACE/.nexora-iso-workspace" ]]; then
  if [[ -n "$(find "$WORKSPACE" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    echo "Refus : $WORKSPACE existe déjà et n’est pas marqué comme workspace Nexora." >&2
    exit 1
  fi
fi
mkdir -p "$WORKSPACE"
printf '%s\n' 'Nexora live-build workspace — fichiers générés uniquement ici.' > "$WORKSPACE/.nexora-iso-workspace"

mkdir -p "$WORKSPACE/config"
cp -a "$ROOT/config/live-build/profile/config/." "$WORKSPACE/config/"
mkdir -p "$WORKSPACE/config/package-lists"
cp "$ROOT/config/package-lists/nexora.list.chroot" "$WORKSPACE/config/package-lists/nexora.list.chroot"

SOURCE_STAGE="$WORKSPACE/config/includes.chroot/usr/src/nexora"
mkdir -p "$SOURCE_STAGE/src" "$SOURCE_STAGE/tests/cpp" "$SOURCE_STAGE/assets/branding"
cp -a "$ROOT/src/desktop" "$ROOT/src/apps" "$SOURCE_STAGE/src/"
cp -a "$ROOT/tests/cpp/." "$SOURCE_STAGE/tests/cpp/"
cp "$ROOT/assets/branding/nexora-grub-mark.png" "$SOURCE_STAGE/assets/branding/nexora-grub-mark.png"
mkdir -p "$WORKSPACE/config/includes.chroot/usr/share/nexora/scripts"
cp "$ROOT/config/live-build/profile/config/includes.chroot/usr/share/nexora/scripts/configure-grub-after-install.sh" \
  "$WORKSPACE/config/includes.chroot/usr/share/nexora/scripts/configure-grub-after-install.sh"
chmod 0755 "$WORKSPACE/config/hooks/live/0100-build-nexora.hook.chroot"
chmod 0755 "$WORKSPACE/config/includes.chroot/usr/share/nexora/scripts/configure-grub-after-install.sh"
chmod 0755 "$WORKSPACE/config/includes.chroot/usr/lib/live/config/0086-nexora-sddm-session"

config_args=(
  --mode debian
  --distribution trixie
  --architecture amd64
  --binary-image iso-hybrid
  --bootloaders "syslinux grub-efi"
  --debian-installer live
  --debian-installer-gui true
  --uefi-secure-boot auto
  --archive-areas "main contrib non-free non-free-firmware"
  --firmware-binary true
  --firmware-chroot true
  --checksums sha256
  --image-name "$IMAGE_NAME"
  --iso-volume NEXORA_TRIXIE
  --iso-application "Nexora OS live installer"
  --iso-publisher "Nexora Project"
  --security true
  --updates true
  --bootappend-live "boot=live components locales=fr_FR.UTF-8 keyboard-layouts=fr"
)

cd "$WORKSPACE"
lb config "${config_args[@]}"
lb config --validate

if [[ "$MODE" == "--config-only" ]]; then
  printf '\nConfiguration live-build validée : %s/config\n' "$WORKSPACE"
  printf 'Aucun chroot, build ISO ou accès disque physique n’a été exécuté.\n'
  exit 0
fi

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Le build live-build nécessite root dans le builder isolé. Relancer avec sudo scripts/build-iso.sh --build." >&2
  exit 77
fi

if [[ ! -r /usr/share/keyrings/debian-archive-keyring.gpg ]]; then
  echo "Trousseau Debian absent : installer debian-archive-keyring sur le builder avant debootstrap." >&2
  exit 78
fi

# live-build reuses stage stamps even when local includes changed. Clear every
# generated stage so bootstrap/chroot are rebuilt consistently; keep caches and
# the profile config to avoid unnecessary package downloads.
lb clean --all
lb config "${config_args[@]}"
lb config --validate

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
export APT_LISTCHANGES_FRONTEND=none
lb build </dev/null
mapfile -t iso_files < <(find "$WORKSPACE" -maxdepth 1 -type f -name '*.iso' -print | sort)
if [[ ${#iso_files[@]} -ne 1 ]]; then
  printf 'Attendu : un ISO à la racine de %s, trouvé : %s\n' "$WORKSPACE" "${#iso_files[@]}" >&2
  printf '%s\n' "${iso_files[@]}" >&2
  exit 1
fi
iso_file="${iso_files[0]}"
(
  cd "$(dirname "$iso_file")"
  sha256sum "$(basename "$iso_file")" > "$(basename "$iso_file").sha256"
)
printf '\nISO construite : %s\n' "$iso_file"
printf 'Somme SHA-256 : %s\n' "$iso_file.sha256"
printf 'Aucune partition ou entrée UEFI de l’hôte n’a été modifiée.\n'
