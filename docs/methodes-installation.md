# Deux méthodes d’installation de Nexora dans VirtualBox

Ce guide distingue l’installation de l’ISO complète et l’ajout du bureau Nexora à une VM Debian 13 existante. Dans les deux cas, utilise une VM neuve, un disque virtuel dédié et aucun disque physique de l’ordinateur hôte.

## Méthode 1 — Démarrer l’ISO Nexora complète

Cette méthode essaie la distribution live Nexora depuis l’ISO.

1. Connecte-toi au dépôt GitHub privé et ouvre la [release expérimentale v0.1.0-alpha](https://github.com/d02427378-dot/nexora-os/releases/tag/v0.1.0-alpha).
2. Télécharge les deux assets `nexora-os-trixie-amd64.hybrid.iso.part00` et `.part01`, ainsi que le fichier `.sha256`. Recompose-les et vérifie leur somme en suivant le [guide de téléchargement](telechargement-iso-github.md).
3. Dans VirtualBox, crée une nouvelle VM **Debian 64-bit**, avec firmware **EFI**, contrôleur graphique **VMSVGA**, environ 6 Go de RAM et un disque VDI dynamique de 64 Go. Laisse la 3D désactivée au premier essai.
4. Monte l’ISO recomposée comme disque optique virtuel et démarre la VM. Sélectionne **Live system**.
5. **Arrête-toi si le bureau live n’apparaît pas.** Le bureau reste noir dans le test UEFI/OVMF avec QEMU/TCG; le démarrage UEFI dans VirtualBox n’est pas encore vérifié. N’ouvre pas l’installateur tant que le live n’est pas visible.
6. Même si le live fonctionne, n’installe que dans le VDI de 64 Go après avoir vérifié la destination affichée par l’installateur et pris un instantané de la VM. N’attache jamais un disque physique de l’hôte.

Cette méthode est celle qui vise à tester l’ISO en tant que système complet, mais l’installateur et le dual-boot Windows ne sont pas validés.

## Méthode 2 — Une commande dans une VM Debian 13 avec KDE

Cette méthode **n’installe pas une distribution indépendante** : elle ajoute le shell et les applications Nexora à une VM Debian 13/KDE déjà installée. Elle évite le démarrage de l’ISO, mais ne change ni les partitions, ni GRUB, ni SDDM.

### Préparer la VM et les sources

1. Crée une VM neuve et installe **Debian 13 avec KDE Plasma** à l’aide de l’installateur Debian officiel. Utilise un disque virtuel d’au moins 64 Go; ne passe aucun disque physique de l’hôte à la VM.
2. Démarre une session Plasma et crée un instantané VirtualBox. La VM doit avoir un accès Internet pour les paquets Debian.
3. Connecte-toi au dépôt privé Nexora sur GitHub, puis télécharge le ZIP des sources via **Code → Download ZIP**. Transfère-le dans la VM avec un dossier partagé VirtualBox ou télécharge-le depuis le navigateur de la VM après connexion à GitHub.
4. Extrais le ZIP dans ton dossier personnel. Avec la branche `main`, le répertoire extrait se nomme généralement `nexora-os-main`. Ouvre **Konsole** dans la session Plasma.

### La commande unique

Si le dossier extrait est bien `~/nexora-os-main`, colle cette ligne dans Konsole :

```sh
cd "$HOME/nexora-os-main" && sudo bash scripts/install-nexora-vm.sh
```

Le script vérifie Debian 13, KDE Plasma, la session utilisateur active et que l’environnement est détecté comme machine virtuelle. Il annonce ses changements et demande de taper `OUI` avant de continuer. Il installe les dépendances Qt et les applications APT prévues, compile le shell, installe le shell et les fichiers QML sous `/opt/nexora-vm`, puis active le service Nexora pour la session Plasma de l’utilisateur courant. Il peut démarrer le shell dans la session actuelle; sinon il démarrera à la prochaine connexion Plasma.

Pour vérifier le plan sans rien installer, exécute d’abord :

```sh
cd "$HOME/nexora-os-main" && bash scripts/install-nexora-vm.sh --dry-run
```

Si le nom du dossier est différent, adapte seulement le chemin après `cd`. La commande d’installation requiert le mot de passe `sudo`, une connexion Internet et la confirmation `OUI`.

## État de validation et sécurité

Le script d’installation Debian/KDE est une nouvelle méthode et **n’a pas encore été exécuté dans une VM VirtualBox réelle**; ses vérifications jusqu’ici sont syntaxiques et en mode `--dry-run`. Utilise d’abord un instantané et un VDI jetable. Il ne contient aucune opération de partitionnement ou de formatage, et ne modifie pas GRUB/SDDM. Les paquets APT ajoutés restent installés si tu désactives ensuite le service Nexora.

Aucune de ces méthodes ne constitue une installation validée en dual-boot sur un PC réel. Sauvegarde les données avant toute modification réelle de partition et ne désactive pas BitLocker/Secure Boot pour contourner un problème non diagnostiqué.
