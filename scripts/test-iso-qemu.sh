#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$ROOT/build/iso/nexora-os-trixie-amd64.hybrid.iso}"
VM_DIR="$ROOT/build/vm"
DISK="$VM_DIR/nexora-first-boot.qcow2"
VARS="$VM_DIR/OVMF_VARS.fd"
MONITOR="$VM_DIR/qemu-monitor.sock"
DISK_SIZE="${NEXORA_VM_DISK_SIZE:-64G}"

fail() { printf 'Impossible de lancer le test VM : %s\n' "$1" >&2; exit 1; }
[[ -f "$ISO" ]] || fail "ISO introuvable : $ISO"
command -v qemu-system-x86_64 >/dev/null 2>&1 || fail 'installer qemu-system-x86.'
command -v qemu-img >/dev/null 2>&1 || fail 'installer qemu-utils.'

if [[ -n "${NEXORA_OVMF_CODE:-}" && -n "${NEXORA_OVMF_VARS_TEMPLATE:-}" ]]; then
  OVMF_CODE="$NEXORA_OVMF_CODE"
  OVMF_VARS_TEMPLATE="$NEXORA_OVMF_VARS_TEMPLATE"
elif [[ -f /usr/share/OVMF/OVMF_CODE_4M.fd && -f /usr/share/OVMF/OVMF_VARS_4M.fd ]]; then
  OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.fd
  OVMF_VARS_TEMPLATE=/usr/share/OVMF/OVMF_VARS_4M.fd
elif [[ -f /usr/share/OVMF/OVMF_CODE.fd && -f /usr/share/OVMF/OVMF_VARS.fd ]]; then
  OVMF_CODE=/usr/share/OVMF/OVMF_CODE.fd
  OVMF_VARS_TEMPLATE=/usr/share/OVMF/OVMF_VARS.fd
else
  fail 'OVMF introuvable; installer le paquet OVMF ou définir NEXORA_OVMF_CODE et NEXORA_OVMF_VARS_TEMPLATE.'
fi
[[ -r "$OVMF_CODE" && -r "$OVMF_VARS_TEMPLATE" ]] || fail 'fichiers OVMF illisibles.'
[[ ! -e "$DISK" && ! -e "$VARS" ]] || fail "refus d’écraser un état VM existant dans $VM_DIR; conservez-le ou déplacez-le manuellement après vérification."
[[ ! -e "$MONITOR" ]] || fail "refus d’écraser le socket de contrôle VM existant : $MONITOR"

mkdir -p "$VM_DIR"
cp -- "$OVMF_VARS_TEMPLATE" "$VARS"
qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"

if [[ -r /dev/kvm && -w /dev/kvm ]]; then
  accelerator=(-accel kvm)
else
  accelerator=(-accel tcg,thread=multi)
fi

if [[ "${NEXORA_VM_HEADLESS:-0}" == 1 ]]; then
  display=(-display none)
  monitor=(-monitor "unix:$MONITOR,server,nowait")
else
  display=()
  monitor=()
fi

printf '%s\n' "ISO : $ISO" "Disque virtuel neuf : $DISK ($DISK_SIZE, qcow2)" \
  'Réseau VM : désactivé; aucun disque hôte n’est attaché.'
if [[ "${NEXORA_VM_HEADLESS:-0}" == 1 ]]; then
  printf '%s\n' "Mode headless; console de contrôle QEMU : $MONITOR"
fi
exec qemu-system-x86_64 \
  "${accelerator[@]}" \
  -machine q35 \
  -m "${NEXORA_VM_MEMORY:-6G}" \
  -smp "${NEXORA_VM_CPUS:-4}" \
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
  -drive "if=pflash,format=raw,file=$VARS" \
  -drive "file=$ISO,media=cdrom,readonly=on" \
  -drive "file=$DISK,format=qcow2,if=virtio" \
  -boot order=d,menu=on \
  "${display[@]}" \
  "${monitor[@]}" \
  -nic none
