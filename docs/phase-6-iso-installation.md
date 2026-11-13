# Phase 6 — ISO Nexora et installation dual-boot

## État et périmètre

Le profil cible Debian 13 « Trixie », `amd64`, qui est la stable indiquée par Debian au 12 novembre 2026 [1]. `live-build` configure un ISO hybride BIOS/UEFI, un système live KDE Plasma, l’installateur Debian Live, le shell Nexora compilé dans le chroot Debian et un démarrage UEFI signé en mode `auto` lorsque les paquets requis sont disponibles [2] [3]. Le profil installe également des firmwares Debian du dépôt `non-free-firmware`.

Le build live-build du 13 novembre 2026 a produit l’ISO hybride actuel de 2 832 580 608 octets (2,83 Go décimaux, 2,64 Gio). Son SHA-256 est `d3e1a6e5d9a8bb6d8e5a9a919c055262b303daf06d3c92c4de7550282763541a`; le sidecar fourni a été vérifié avec `sha256sum -c`. La présence de `requestActivate()` ainsi que de l’unité systemd Nexora dans le SquashFS a été contrôlée. Les tests automatisés connus passent : 25 tests QML, 6 tests C++ et validations statiques du profil ISO et de GRUB.

Dans une VM QEMU/OVMF avec accélération TCG, le menu UEFI/GRUB de l’ISO apparaît, puis l’écran reste noir après le choix « Live system » [menu UEFI](evidence/uefi-grub-menu.png) [capture après 180 s](evidence/uefi-black-screen.png). Le mode « fail-safe » et un lancement provisoire depuis l’invite GRUB atteignent `graphical.target`, mais ne rendent pas le bureau [capture fail-safe](evidence/uefi-failsafe-black.png) [capture depuis l’invite GRUB](evidence/uefi-grub-commandline-black.png). Les diagnostics série confirment que Plasma et `nexora-shell.service` sont actifs. Deux essais supplémentaires, avec `QT_QUICK_BACKEND=software` puis `QSG_RHI_BACKEND=software`, laissent également l’écran noir [capture du test RHI logiciel](evidence/uefi-rhi-software-black.png); les avertissements EGL Mesa persistent. Une tentative avec ajout temporaire de `nomodeset` dans GRUB a produit une capture framebuffer corrompue [capture nomodeset](evidence/nomodeset-framebuffer-corruption.png), sans diagnostic système exploitable; son résultat est non concluant et cette option n’a pas été intégrée à l’ISO. La cause exacte reste indéterminée : le chemin graphique UEFI/TCG est suspecté, mais ce n’est pas démontré. En revanche, un test distinct qui démarre directement le noyau et l’initrd du même ISO (en contournant OVMF et GRUB) affiche le bureau Nexora en 1280 × 800, avec `nexora-shell.service` actif sans lancement manuel [capture du bureau automatique](evidence/direct-kernel-desktop.png). Le test direct-kernel ne valide pas le parcours UEFI normal. L’installateur, l’installation Windows/Nexora en dual-boot et Secure Boot ne sont pas validés. **Ne pas installer Nexora sur un ordinateur réel** avant d’avoir réussi le parcours UEFI complet et l’installation dans une VM à deux systèmes.

Le GRUB de l’ISO ne sert qu’à lancer la session live ou l’installateur. Après installation, Debian installe le chargeur UEFI du système cible. Le script post-installation fourni ajoute un menu de 10 secondes et demande à `os-prober` de repérer Windows; il ne formate pas de partition et ne lance pas `grub-install`. L’option « se souvenir de mon choix » du modèle de phase 3 reste expérimentale et n’est pas activée.

## Construire l’ISO dans une machine Debian de test

Utilisez de préférence une VM Debian 13 `amd64` dédiée comme machine de build. Prévoyez plusieurs dizaines de gigaoctets d’espace libre : KDE, les paquets, le chroot, le cache et l’image ISO occupent beaucoup plus que les seuls fichiers du projet. Gardez cette VM séparée de tout disque contenant des données à conserver.

Dans la VM Debian, installez les outils de build et de test :

```sh
sudo apt update
sudo apt install debian-archive-keyring live-build debootstrap xorriso qemu-system-x86 qemu-utils ovmf
```

Dans la copie de Nexora, vérifiez le profil puis préparez la configuration :

```sh
bash scripts/test-iso-profile.sh
bash scripts/test-grub-config.sh
scripts/build-iso.sh --config-only
```

Si la validation `lb config --validate` passe, construisez l’image dans le même environnement isolé :

```sh
sudo scripts/build-iso.sh --build
```

Le script refuse un lien symbolique ou un répertoire non reconnu à `build/iso`. Il ne lance pas de partitionneur, de formatage ni d’installation GRUB sur la machine de build. Le hook de construction compile le binaire Qt dans le chroot Trixie, installe les fichiers sous `/usr`, puis retire les sources et dépendances de compilation du système image. Les hooks chroot et inclusions locales utilisés ici suivent le mécanisme de personnalisation de Debian Live [2].

Le résultat se trouve à la racine de `build/iso/`, avec un fichier SHA-256 adjacent. L’ISO actuelle pèse 2 832 580 608 octets; contrôlez le nom et la taille réellement produits. Depuis la racine du projet, vérifiez la somme avec `(cd build/iso && sha256sum -c nexora-os-trixie-amd64.hybrid.iso.sha256)` avant de copier l’image sur un média amovible. Le sidecar ne contient que le nom du fichier et reste donc portable avec l’ISO téléchargé. La commande `--uefi-secure-boot auto` demande à `live-build` d’utiliser les paquets signés lorsqu’ils sont disponibles; cela ne certifie pas le démarrage Secure Boot de Nexora [3]. Si le build signale l’absence des paquets signés, ne supposez pas que l’ISO démarrera avec Secure Boot activé.

## Premier essai : machine virtuelle uniquement

Lancez le premier démarrage avec :

```sh
scripts/test-iso-qemu.sh
```

Ce script crée un disque virtuel neuf `qcow2` et une copie des variables UEFI OVMF sous `build/vm/`. Il refuse d’écraser ces fichiers s’ils existent déjà et désactive le réseau de la VM. Aucun disque physique de l’hôte n’est attaché. Le script ne supprime pas le disque virtuel après usage. Dans un environnement sans affichage, `NEXORA_VM_HEADLESS=1 scripts/test-iso-qemu.sh` active le moniteur de contrôle QEMU local; le mode par défaut ouvre l’affichage graphique.

Résultat des essais du 13 novembre 2026 : le menu UEFI/GRUB de l’ISO actuelle s’affiche. Sous OVMF/TCG, l’entrée fail-safe et un lancement manuel avec options TCG atteignent `graphical.target`, mais le bureau reste invisible, y compris après les deux essais de backend Qt logiciel. Le sandbox n’expose pas `/dev/kvm`; le trajet UEFI complet doit encore être vérifié sur un hôte avec KVM ou dans VirtualBox. Ne considérez pas le test direct-kernel comme un remplacement de cette validation firmware.

Lors de l’essai direct-kernel, le dock et le bureau sont visibles; les tests QML/C++ automatisés passent. Pour compléter la validation de l’ISO, refaites le parcours de démarrage UEFI dans une VM, testez le clavier et les applications principales, puis vérifiez seulement que l’installateur s’ouvre. Ne confirmez aucune écriture de partition pendant ce premier test.

Pour éprouver le dual-boot, créez une seconde VM séparée contenant une installation Windows légitime et une sauvegarde/snapshot de son disque virtuel. Ajoutez l’ISO Nexora à cette VM, démarrez l’installateur dans le même mode UEFI que Windows, puis vérifiez les deux chemins de démarrage. Le script fourni ne fabrique pas cette VM Windows et ne teste ni l’entrée Windows ni l’option `save_env`.

## Installer à côté de Windows

### Avant de partitionner

Faites une sauvegarde complète de Windows et de vos fichiers importants, puis vérifiez qu’elle peut être lue et restaurée. Le repartitionnement comporte un risque intrinsèque de perte de données [4]. Préparez aussi le support de récupération Windows et notez la configuration actuelle du firmware.

Si le chiffrement BitLocker ou le chiffrement de l’appareil est actif, retrouvez la clé de récupération, vérifiez son identifiant et gardez-en une copie accessible hors du PC avant tout changement de démarrage [8]. Si la clé est introuvable, arrêtez-vous. Le démarrage rapide de Windows doit être désactivé pour un dual-boot afin d’éviter de laisser les systèmes de fichiers Windows dans un état d’hibernation [5].

Dans Windows, utilisez **Gestion des disques** et l’action **Réduire le volume** sur le volume Windows choisi. Microsoft précise que la réduction produit de l’espace non alloué et peut être limitée par des fichiers non déplaçables [7]. Laissez cet espace **non alloué** : ne créez pas de volume Linux dans Windows. Ne réduisez, ne formatez et ne supprimez ni la partition EFI, ni les partitions Microsoft Recovery ou réservées.

### Pendant l’installation

Démarrez le média en mode **UEFI** depuis le menu de démarrage du firmware; ne choisissez pas une entrée Legacy/CSM si Windows est installé en UEFI. Le mode de démarrage détermine le type de chargeur que l’installateur configure, et un dual-boot doit rester cohérent [5].

Dans l’installateur, choisissez le partitionnement **manuel**. Créez les partitions Nexora uniquement dans l’espace non alloué préparé dans Windows. Une installation simple peut utiliser une partition Linux pour `/`; le swap peut être géré séparément ou comme fichier après installation. Les besoins varient selon le stockage et l’usage, donc le guide n’impose pas de taille universelle.

Sélectionnez la partition EFI FAT32 déjà utilisée par Windows et assignez-la comme ESP, généralement montée sur `/boot/efi`, mais vérifiez explicitement que l’option de formatage est **désactivée**. N’acceptez jamais « utiliser tout le disque ». Avant de confirmer l’écriture, relisez le résumé des changements : il ne doit montrer que les nouvelles partitions Linux dans l’espace libéré, sans formatage ou suppression de Windows, de la partition EFI ou des partitions de récupération. L’installateur Debian indique que le choix d’un disque entier peut entraîner la perte des données et que GRUB prend ensuite le contrôle du processus de démarrage [6].

Laissez l’installateur Debian installer GRUB en mode UEFI. Après le premier redémarrage, vérifiez d’abord Nexora, puis Windows depuis le menu GRUB ou, si nécessaire, depuis le menu de démarrage du firmware. N’activez ni ne désactivez une option Secure Boot sur le matériel réel pour contourner un échec non compris; reproduisez d’abord le problème en VM. Une modification du firmware peut provoquer une demande de récupération BitLocker.

### Ajouter l’entrée Windows au menu GRUB

Le profil inclut `os-prober`, mais ne l’active pas pendant le build : le processus de construction ne doit pas scanner les disques de la machine hôte. Si Windows n’apparaît pas dans le GRUB installé, retirez d’abord la clé USB d’installation et les supports amovibles non concernés. Depuis le système Nexora installé et démarré en UEFI, exécutez explicitement :

```sh
sudo /usr/share/nexora/scripts/configure-grub-after-install.sh
```

Le script affiche les systèmes détectés et exige que vous tapiez `OUI`. Il crée alors un fichier de réglages GRUB avec Nexora par défaut et un délai visible de 10 secondes, puis lance `update-grub`. Il conserve une copie de `/boot/grub/grub.cfg`; si la mise à jour échoue ou ne produit pas d’entrée Windows, il restaure le fichier précédent et retire son réglage. **Cette opération modifie la configuration GRUB du système installé**; elle ne touche pas à la table de partitions et n’installe pas de chargeur dans l’ESP. La détection peut échouer selon le matériel ou le chiffrement; ne forcez pas une entrée à partir d’un UUID inconnu.

La validation du 13 novembre a exécuté `bash -n` et une copie temporaire du script avec `os-prober` et `update-grub` simulés. Les scénarios « aucun Windows », confirmation refusée, génération réussie, échec de `update-grub` et absence d’entrée Windows après génération ont vérifié l’absence de mutation ou la restauration attendue. Aucun `/boot`, ESP ou disque réel n’a été touché. Cette simulation ne valide ni les commandes Debian réelles, ni une session GRUB/UEFI; la collision avec un fichier de réglages préexistant n’a pas été testée.

Le menu créé par `os-prober` peut comporter des entrées supplémentaires et des libellés propres aux versions de Windows et Debian. Il ne reproduit pas encore exactement les deux libellés demandés dans le prototype de phase 3. Le choix mémorisé et le comportement de `grubenv` demandent une validation UEFI distincte avant de pouvoir être annoncés comme fonctionnels.

## Retour arrière et critères avant usage réel

Avant tout essai matériel, exigez au minimum : un ISO dont la somme est contrôlée; démarrage live et installation complète testés dans une VM UEFI; Windows et Nexora redémarrés plusieurs fois dans une VM à deux systèmes; absence de modification des fichiers EFI Windows; et comportement documenté pour Secure Boot et BitLocker. Si l’un de ces contrôles échoue, ne passez pas sur le disque réel.

Après toute installation réelle, gardez la sauvegarde et la clé BitLocker. Si GRUB ne démarre pas, sélectionnez Windows Boot Manager depuis le firmware et ne supprimez aucune partition Linux/EFI avant d’avoir confirmé le chemin de récupération. Aucun outil ou script Nexora de cette phase n’efface ou ne repartitionne automatiquement un disque.

## Références

[1]: https://www.debian.org/releases/ "Debian Releases"
[2]: https://live-team.pages.debian.net/live-manual/html/live-manual.en.html "Debian Live Manual"
[3]: https://manpages.debian.org/trixie/live-build/lb_config.1.en.html "lb_config pour Debian Trixie"
[4]: https://www.debian.org/releases/trixie/amd64/ch03s05.en.html "Prépartitionnement Debian pour les systèmes multi-boot"
[5]: https://www.debian.org/releases/trixie/amd64/ch03s06.en.html "Configuration matérielle et système avant installation Debian"
[6]: https://www.debian.org/releases/trixie/amd64/ch06s03.en.html "Partitionnement et installation de GRUB avec Debian Installer"
[7]: https://learn.microsoft.com/en-us/windows-server/storage/disk-management/shrink-a-basic-volume "Réduire un volume de base Windows"
[8]: https://support.microsoft.com/en-us/windows/bitlocker-recovery-key-faq-6b71ad27-0b89-ea08-f143-056f5ab347d6 "Retrouver une clé de récupération BitLocker"
