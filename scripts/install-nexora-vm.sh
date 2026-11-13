#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/config/package-lists/nexora.list.chroot"
INSTALL_PREFIX="/opt/nexora-vm"
INSTALL_MARKER="$INSTALL_PREFIX/.nexora-vm-install"
DRY_RUN=0

usage() {
    cat <<'EOF'
Usage : sudo bash scripts/install-nexora-vm.sh [--dry-run | --help]

Installe le shell et les applications Nexora sur une VM Debian 13 déjà équipée
de KDE Plasma. Le script installe les dépendances APT, compile Nexora dans
/var/tmp, pose les fichiers sous /opt/nexora-vm et active un service utilisateur
pour la session Plasma de la personne qui a lancé sudo.

Il ne partitionne aucun disque et ne modifie ni GRUB ni la configuration SDDM.
--dry-run affiche les dépendances sans effectuer de changement.
EOF
}

die() {
    printf 'Erreur : %s\n' "$*" >&2
    exit 1
}

case "${1:-}" in
    "") ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

[[ -r "$MANIFEST" ]] || die "Manifeste Nexora introuvable : $MANIFEST. Lance le script depuis l’archive source complète."

mapfile -t RUNTIME_PACKAGES < <(
    awk '
        /^# Runtime Nexora Desktop/ { runtime = 1; next }
        runtime && /^[[:space:]]*#/ { next }
        runtime && NF { print $1 }
    ' "$MANIFEST"
)

BUILD_PACKAGES=(build-essential cmake qt6-base-dev qt6-declarative-dev)
APP_PACKAGES=(firefox-esr dolphin konsole kate gwenview vlc pkexec polkit-kde-agent-1 git curl ca-certificates)
PACKAGES=("${BUILD_PACKAGES[@]}" "${RUNTIME_PACKAGES[@]}" "${APP_PACKAGES[@]}")

if (( DRY_RUN )); then
    printf '%s\n' 'Simulation uniquement : aucun paquet ni fichier ne sera modifié.'
    printf 'Pré-requis réel : Debian 13 + KDE Plasma, dans une VM, lancé depuis un terminal graphique.\n'
    printf 'Préfixe d’installation : %s\n' "$INSTALL_PREFIX"
    printf 'Paquets APT prévus (%d) :\n' "${#PACKAGES[@]}"
    printf '  %s\n' "${PACKAGES[@]}"
    printf '%s\n' 'Étapes prévues : apt-get update/install, compilation CMake, installation du shell/QML, service utilisateur Plasma.'
    printf '%s\n' 'Aucune opération de partitionnement, d’écriture d’image disque, de configuration GRUB ou de SDDM.'
    exit 0
fi

(( EUID == 0 )) || die "Lance cette commande avec sudo : sudo bash scripts/install-nexora-vm.sh"

TARGET_USER="${SUDO_USER:-}"
[[ -n "$TARGET_USER" && "$TARGET_USER" != root ]] || die "Lance sudo depuis le compte de bureau visé; ne lance pas ce script depuis une session root."

# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == debian && "${VERSION_ID:-}" == 13 ]] || die "Seul Debian 13 est pris en charge; aucun changement n’a été effectué."

VIRT="$(systemd-detect-virt --vm 2>/dev/null || true)"
[[ -n "$VIRT" && "$VIRT" != none ]] || die "Aucune VM n’a été détectée. Par sécurité, cet installateur refuse de continuer sur un hôte non virtualisé."

command -v plasmashell >/dev/null 2>&1 || die "KDE Plasma n’est pas installé. Crée d’abord une VM Debian 13 avec KDE Plasma."
command -v apt-get >/dev/null 2>&1 || die "apt-get est introuvable."

TARGET_UID="$(id -u "$TARGET_USER")"
TARGET_GROUP="$(id -gn "$TARGET_USER")"
USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -n "$USER_HOME" && "$USER_HOME" == /* && "$USER_HOME" != / ]] || die "Répertoire personnel invalide pour $TARGET_USER."
USER_RUNTIME="/run/user/$TARGET_UID"
USER_BUS="$USER_RUNTIME/bus"
[[ -S "$USER_BUS" ]] || die "Aucune session graphique utilisateur active. Ouvre Konsole dans Plasma, puis relance la commande sudo."
if ! runuser -u "$TARGET_USER" -- env \
    "XDG_RUNTIME_DIR=$USER_RUNTIME" \
    "DBUS_SESSION_BUS_ADDRESS=unix:path=$USER_BUS" \
    systemctl --user is-active --quiet plasma-core.target
then
    die "plasma-core.target n’est pas actif. Lance la commande depuis une session KDE Plasma connectée."
fi

if [[ -e "$INSTALL_PREFIX" && ! -f "$INSTALL_MARKER" ]]; then
    die "$INSTALL_PREFIX existe sans marqueur Nexora; refus de remplacer des fichiers inconnus."
fi

UNIT_DIR="$USER_HOME/.config/systemd/user"
UNIT_FILE="$UNIT_DIR/nexora-shell.service"
if [[ -e "$UNIT_FILE" ]] && ! grep -q '^# Managed by install-nexora-vm.sh$' "$UNIT_FILE"; then
    die "$UNIT_FILE existe et ne porte pas la marque de cet installateur; sauvegarde-le et inspecte-le avant toute action."
fi

cat <<EOF
Cet installateur va agir uniquement sur la VM détectée « $VIRT » et le compte « $TARGET_USER ».
Il installera des paquets APT, compilera Nexora, écrira sous $INSTALL_PREFIX et activera
un service utilisateur Plasma. Il ne touche pas aux partitions, à GRUB ou à SDDM.
Une connexion Internet est nécessaire pour APT. Vérifie que cette VM ne contient
aucun disque physique de l’hôte et qu’un instantané est disponible.
EOF
read -r -p 'Tape OUI pour continuer : ' CONFIRMATION
[[ "$CONFIRMATION" == OUI ]] || die "Installation annulée; aucune modification Nexora n’a été faite."

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --yes --no-install-recommends "${PACKAGES[@]}"
unset DEBIAN_FRONTEND

BUILD_DIR="$(mktemp -d /var/tmp/nexora-vm-build.XXXXXX)"
printf 'Compilation dans %s\n' "$BUILD_DIR"
cmake -S "$ROOT/src/desktop" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
cmake --build "$BUILD_DIR" --target nexora-shell --parallel 2
cmake --install "$BUILD_DIR"
printf 'installateur=install-nexora-vm.sh\nversion=0.1.0-alpha\n' > "$INSTALL_MARKER"

install -d -o "$TARGET_USER" -g "$TARGET_GROUP" "$UNIT_DIR"
cat > "$UNIT_FILE" <<EOF
# Managed by install-nexora-vm.sh
[Unit]
Description=Nexora OS Desktop Shell (VM installation)
After=plasma-core.target
PartOf=plasma-core.target

[Service]
Type=simple
ExecStart=$INSTALL_PREFIX/bin/nexora-shell
Restart=on-failure
RestartSec=5

[Install]
WantedBy=plasma-core.target
EOF
chown "$TARGET_USER:$TARGET_GROUP" "$UNIT_FILE"
chmod 0644 "$UNIT_FILE"

user_systemctl() {
    runuser -u "$TARGET_USER" -- env \
        "XDG_RUNTIME_DIR=$USER_RUNTIME" \
        "DBUS_SESSION_BUS_ADDRESS=unix:path=$USER_BUS" \
        systemctl --user "$@"
}

user_systemctl daemon-reload
user_systemctl enable nexora-shell.service
if user_systemctl is-active --quiet plasma-core.target; then
    user_systemctl start nexora-shell.service
    printf '%s\n' 'Nexora est installé et son service a été démarré dans la session Plasma actuelle.'
else
    printf '%s\n' 'Nexora est installé et activé; il démarrera à la prochaine connexion Plasma.'
fi

printf '\nInstallation terminée. Les fichiers compilés temporaires restent dans %s pour diagnostic.\n' "$BUILD_DIR"
printf 'Préfixe Nexora : %s\n' "$INSTALL_PREFIX"
printf 'Pour vérifier le service : systemctl --user status nexora-shell.service\n'
