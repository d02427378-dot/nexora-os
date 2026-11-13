#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/config/live-build/profile/config"

bash -n "$ROOT/scripts/build-iso.sh"
bash -n "$ROOT/scripts/test-iso-qemu.sh"
bash -n "$PROFILE/includes.chroot/usr/share/nexora/scripts/configure-grub-after-install.sh"
sh -n "$PROFILE/hooks/live/0100-build-nexora.hook.chroot"
sh -n "$PROFILE/includes.chroot/usr/lib/live/config/0086-nexora-sddm-session"

for token in \
  '--distribution trixie' '--architecture amd64' '--binary-image iso-hybrid' \
  '--bootloaders "syslinux grub-efi"' '--debian-installer live' \
  '--uefi-secure-boot auto' '--checksums sha256'; do
  grep -Fq -- "$token" "$ROOT/scripts/build-iso.sh"
done

grep -Fq 'lb clean --all' "$ROOT/scripts/build-iso.sh"
CLEAN_LINE="$(grep -nFx 'lb clean --all' "$ROOT/scripts/build-iso.sh" | cut -d: -f1)"
CONFIG_AFTER_CLEAN="$(grep -nFx 'lb config "${config_args[@]}"' "$ROOT/scripts/build-iso.sh" | awk -F: -v clean="$CLEAN_LINE" '$1 > clean {print $1; exit}')"
[[ -n "$CONFIG_AFTER_CLEAN" ]]

grep -Fxq 'debian-installer-launcher' "$ROOT/config/package-lists/nexora.list.chroot"
grep -Fxq 'os-prober' "$ROOT/config/package-lists/nexora.list.chroot"
UNIT="$PROFILE/includes.chroot/usr/lib/systemd/user/nexora-shell.service"
WANTS="$PROFILE/includes.chroot/usr/lib/systemd/user/plasma-core.target.wants/nexora-shell.service"
LIVE_SDDM="$PROFILE/includes.chroot/usr/lib/live/config/0086-nexora-sddm-session"
LIVE_GRUB="$ROOT/config/live-build/profile/config/bootloaders/grub-pc/config.cfg"
grep -Fq 'ExecStart=/usr/bin/nexora-shell' "$UNIT"
grep -Fq 'WantedBy=plasma-core.target' "$UNIT"
[[ -L "$WANTS" ]]
[[ "$(readlink "$WANTS")" == '../nexora-shell.service' ]]
[[ ! -e "$PROFILE/includes.chroot/etc/xdg/autostart/nexora-shell.desktop" ]]
[[ -x "$LIVE_SDDM" ]]
grep -Fq 'component_was_executed "sddm"' "$LIVE_SDDM"
grep -Fq 'Session=plasma.desktop' "$LIVE_SDDM"
grep -Fq 'set timeout_style=menu' "$LIVE_GRUB"
grep -Fq 'set timeout=10' "$LIVE_GRUB"
grep -Fq 'set default=0' "$LIVE_GRUB"
grep -Fq 'GRUB_TIMEOUT=10' "$PROFILE/includes.chroot/etc/default/grub.d/41-nexora.cfg"
grep -Fq 'GRUB_DISABLE_OS_PROBER=false' "$PROFILE/includes.chroot/usr/share/nexora/scripts/configure-grub-after-install.sh"
grep -Fq 'IMAGE_NAME=nexora-os-trixie' "$ROOT/scripts/build-iso.sh"
grep -Fq 'find "$WORKSPACE" -maxdepth 1 -type f -name '\''*.iso'\''' "$ROOT/scripts/build-iso.sh"
grep -Fq 'sha256sum "$(basename "$iso_file")" > "$(basename "$iso_file").sha256"' "$ROOT/scripts/build-iso.sh"
grep -Fq 'ISO="${1:-$ROOT/build/iso/nexora-os-trixie-amd64.hybrid.iso}"' "$ROOT/scripts/test-iso-qemu.sh"
grep -Fq -- '-nic none' "$ROOT/scripts/test-iso-qemu.sh"
grep -Fq 'format=qcow2' "$ROOT/scripts/test-iso-qemu.sh"
grep -Fq 'NEXORA_VM_HEADLESS' "$ROOT/scripts/test-iso-qemu.sh"

for file in "$ROOT/scripts/build-iso.sh" "$ROOT/config/live-build/profile/config/hooks/live/0100-build-nexora.hook.chroot"; do
  if grep -Eq '(^|[[:space:]])(mkfs|parted|wipefs|sgdisk|fdisk|dd|grub-install)([[:space:]]|$)' "$file"; then
    printf 'Opération disque physique interdite dans %s\n' "$file" >&2
    exit 1
  fi
done

printf '%s\n' 'OK : profil live-build, hook, installateur, GRUB et lanceur QEMU validés statiquement.'
printf '%s\n' 'Ce test statique ne construit pas d’ISO et ne lance pas de VM.'
