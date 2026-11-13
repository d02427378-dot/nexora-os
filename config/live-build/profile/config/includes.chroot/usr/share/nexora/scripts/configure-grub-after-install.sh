#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'Refus : %s\n' "$1" >&2; exit 1; }

[[ ${EUID:-$(id -u)} -eq 0 ]] || fail 'exécuter depuis le système installé avec sudo.'
[[ -d /sys/firmware/efi ]] || fail 'cette procédure est réservée à une installation démarrée en UEFI.'
[[ ! -e /run/live/medium ]] || fail 'ne pas lancer depuis la session live; redémarrer sur le système installé.'
command -v os-prober >/dev/null 2>&1 || fail 'le paquet os-prober est absent.'
command -v update-grub >/dev/null 2>&1 || fail 'update-grub est absent; GRUB doit être installé par l’installateur Debian.'
[[ -s /boot/grub/grub.cfg ]] || fail 'configuration GRUB installée introuvable dans /boot/grub/grub.cfg.'

printf '%s\n' 'Détection en lecture seule des systèmes démarrables :'
probe_output="$(os-prober 2>/dev/null || true)"
printf '%s\n' "${probe_output:-Aucun système détecté par os-prober.}"
printf '%s\n' "$probe_output" | grep -qi 'windows' || fail 'aucune entrée Windows détectée; aucun fichier GRUB n’a été modifié.'
printf '\nVérifiez que la sortie ci-dessus correspond au bon Windows et débranchez les supports externes non concernés.\n'
read -r -p 'Pour ajouter la détection Windows et mettre à jour GRUB, tapez OUI : ' confirmation
[[ "$confirmation" == OUI ]] || fail 'confirmation absente; aucun fichier GRUB n’a été modifié.'

config_dir=/etc/default/grub.d
config_file="$config_dir/41-nexora-windows.cfg"
[[ ! -e "$config_file" ]] || fail "$config_file existe déjà; ne pas l’écraser automatiquement."
mkdir -p -- "$config_dir"
backup="/boot/grub/grub.cfg.nexora-backup.$(date +%Y%m%d%H%M%S)"
cp --preserve=mode,timestamps /boot/grub/grub.cfg "$backup"
temporary="$(mktemp "$config_dir/.41-nexora-windows.XXXXXX")"
cleanup() { rm -f -- "$temporary"; }
trap cleanup EXIT
cat > "$temporary" <<'EOF'
# Nexora: menu visible, Nexora par défaut, délai de dix secondes.
GRUB_DISTRIBUTOR="Nexora OS"
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
GRUB_DEFAULT=0
GRUB_DISABLE_OS_PROBER=false
EOF
chmod 0644 "$temporary"
mv -- "$temporary" "$config_file"
trap - EXIT

if ! update-grub; then
    printf 'Échec update-grub; restauration de la configuration précédente depuis %s\n' "$backup" >&2
    cp --preserve=mode,timestamps "$backup" /boot/grub/grub.cfg
    rm -f -- "$config_file"
    exit 1
fi

if ! grep -qi 'Windows' /boot/grub/grub.cfg; then
    printf 'Aucune entrée Windows n’apparaît dans la nouvelle configuration; restauration de la précédente.\n' >&2
    cp --preserve=mode,timestamps "$backup" /boot/grub/grub.cfg
    rm -f -- "$config_file"
    printf 'Sauvegarde conservée : %s\n' "$backup" >&2
    exit 1
fi
printf '\nOK : le menu Nexora est visible pendant 10 secondes et une entrée Windows est présente.\n'
printf 'Sauvegarde GRUB : %s\n' "$backup"
printf '%s\n' 'Le choix mémorisé par le modèle GRUB Nexora n’est pas activé par ce script.'
