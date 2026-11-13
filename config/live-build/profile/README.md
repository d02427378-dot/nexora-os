# Profil live-build Nexora

Le script `scripts/build-iso.sh` copie ce profil dans `build/iso`, ajoute la liste de paquets et les sources Nexora, puis appelle `lb config`/`lb build`. La configuration vise Debian 13 Trixie `amd64`, un média ISO hybride, l’installateur Debian Live, GRUB UEFI et Secure Boot en mode `auto` (paquets signés utilisés seulement s’ils sont disponibles).

Les fichiers `includes.chroot` sont des fichiers de l’image live. Le hook `0100-build-nexora.hook.chroot` compile le runner Qt contre les paquets de Trixie pendant le build, installe le binaire et les applications QML sous `/usr`, puis retire les outils de compilation et les sources du rootfs final. Il ne partitionne aucun disque et n’installe pas GRUB sur l’hôte.

Le build de l’ISO est une opération de construction séparée de l’installation du système. Son menu GRUB live affiche un compte à rebours visible de 10 secondes et lance par défaut « Live system »; la surcharge `config/bootloaders/grub-pc/config.cfg` conserve aussi le thème et les pilotes vidéo UEFI du modèle Debian Live. Le bootloader installé sur le disque est pris en charge par l’installateur Debian. La détection Windows et le menu visible de 10 secondes sont configurés après installation par l’outil explicite `configure-grub-after-install.sh`. Le menu GRUB installé avec mémorisation du choix reste un prototype non validé en VM UEFI.
