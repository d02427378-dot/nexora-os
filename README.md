# Nexora OS

Un projet de distribution Linux personnalisée, conçue pour cohabiter avec Windows. **L’ISO Debian Trixie actuelle est construite et son SHA-256 vérifié, mais le bureau reste noir dans le parcours UEFI/OVMF sous QEMU TCG; seul le démarrage direct du noyau a affiché le bureau dans le sandbox. L’installation et le dual-boot ne sont pas validés en VM.** Douze applications sont reliées au shell : Navigateur, Fichiers, Terminal, Éditeur, Images, Média, Musique, Nexora Store, Paramètres, Moniteur, Arcade Nexora et Assistant IA. Les tests applicatifs n’effacent pas les disques utilisateur; Nexora Store peut lancer une installation de paquet après confirmation et authentification système.

## Choix de base

- Debian 13 « Trixie » `amd64` est épinglée dans le profil live-build pour rendre ce build reproductible; KDE Plasma fournit le socle de bureau.
- GRUB 2 est prévu en UEFI, avec un chemin BIOS pour l’ISO hybride et un helper post-installation pour détecter Windows.
- Shell en Qt 6 / QML, avec un lanceur C++ qui prépare correctement Qt WebEngine.
- `live-build` compile le runner dans le chroot Debian et construit l’image dans `build/iso`.

Le raisonnement technique se trouve dans [`docs/architecture.md`](docs/architecture.md), le plan dans [`docs/plan-de-projet.md`](docs/plan-de-projet.md), et les livrables dans les documents `docs/phase-*-*.md`.

## Construire et lancer le shell

Prérequis de développement : CMake 3.21+, compilateur C++17, Qt 6 Core/Gui/Qml/Quick/Network, Qt WebEngine et le module QML `Qt.labs.settings`. Les dépendances runtime Qt 6 sont listées dans `config/package-lists/nexora.list.chroot`.

```sh
scripts/build-desktop-shell.sh
scripts/run-desktop-preview.sh
```

Le build produit `build/desktop/nexora-shell` dans le dépôt et n’effectue aucune installation système. Le shell comprend quatre espaces visuels, un lanceur, une barre de commande, des fenêtres, trois thèmes et des préférences utilisateur persistantes.

## Applications et tests

Le Navigateur Nexora utilise Qt WebEngine; **Fichiers** parcourt les dossiers locaux; **Éditeur** ouvre du texte UTF-8 et sauvegarde sur demande; **Images** offre des transformations et un export en copie avec confirmation; **Média** lit un fichier audio ou vidéo local; **Musique**, distincte de Média, parcourt le dossier local choisi et gère pistes, seek, volume, aléatoire et répétition; **Nexora Store** interroge le catalogue APT local pour un ensemble contrôlé d’applications; **Paramètres** mémorise thème, Mode Gamer et réduction des effets décoratifs; **Moniteur** affiche CPU, mémoire, uptime et processus lus dans `/proc`, avec filtre local; **Arcade Nexora** comprend Morpion, Snake, Memory et 2048, jouables hors ligne; **Assistant IA** reçoit une requête libre après confirmation d’envoi, propose du code en brouillon non exécuté et des actions du shell soumises à confirmation. L’assistant nécessite le point d’accès, le modèle et la clé du fournisseur configurés par l’utilisateur; aucune clé n’est incluse et elle reste en mémoire de session. Le Moniteur est en lecture seule; le Terminal, lui, exécute Bash avec les permissions du compte, sans bac à sable. Voir [`Navigateur`](docs/phase-5-browser.md), [`Fichiers`](docs/phase-5-file-manager.md), [`Éditeur`](docs/phase-5-code-editor.md), [`Images`](docs/phase-5-image-editor.md), [`Média`](docs/phase-5-media-player.md), [`Musique`](docs/phase-5-music-app.md), [`Boutique`](docs/phase-5-app-store.md), [`Paramètres`](docs/phase-5-settings.md), [`Moniteur`](docs/phase-5-task-manager.md), [`Mini-jeux`](docs/phase-5-mini-games.md), [`Assistant IA`](docs/phase-5-ai-assistant.md) et [`Terminal`](docs/phase-5-terminal.md).

```sh
scripts/test-desktop-shell.sh
scripts/test-settings-runtime.sh
scripts/test-monitor-runtime.sh
scripts/test-browser-runtime.sh
scripts/test-code-editor-runtime.sh
scripts/test-image-editor-runtime.sh
scripts/test-media-runtime.sh
scripts/test-music-runtime.sh
scripts/test-store-runtime.sh
scripts/test-mini-games-runtime.sh
scripts/test-assistant-runtime.sh
scripts/test-terminal-runtime.sh
ctest --test-dir build/desktop --output-on-failure
```

Les smoke tests utilisent des fixtures, des données réelles en lecture seule ou un backend factice local. Paramètres vérifie QSettings avec un fichier temporaire supprimé après le test; Moniteur lit `/proc` sans piloter de processus. Média et Musique décodent un WAV synthétique à volume nul. Store lit les index APT et simule une transaction; les tests n’appellent jamais `pkexec`. Mini-jeux teste les règles de ses quatre jeux. Assistant teste un serveur HTTP loopback et un backend QML simulé; aucune requête n’est envoyée à un fournisseur externe. Le test de code confirme que le brouillon arrive dans l’Éditeur sans chemin et sans sauvegarde. Le Terminal n’exécute que des commandes bénignes en test. Aucun smoke test ne modifie de fichier personnel.

## Phase 6 — ISO et installation

Le profil Debian Live, le hook de compilation Qt, le script de construction et le guide d’installation sont disponibles dans [`docs/phase-6-iso-installation.md`](docs/phase-6-iso-installation.md). Le [`guide utilisateur`](docs/guide-utilisateur.md) décrit le bureau et les douze applications. Pour télécharger et recomposer les morceaux de l’ISO hébergée dans la release GitHub, consultez [`docs/telechargement-iso-github.md`](docs/telechargement-iso-github.md). Pour construire l’ISO, utilisez une VM Debian 13 dédiée; n’utilisez pas comme builder un système contenant des disques qu’il ne faut pas modifier.

Le builder doit disposer de `debian-archive-keyring`, `live-build`, `debootstrap` et `xorriso`; le guide détaille aussi les paquets nécessaires aux essais QEMU/UEFI.

```sh
scripts/test-iso-profile.sh
scripts/test-grub-config.sh
scripts/build-iso.sh --config-only
sudo scripts/build-iso.sh --build
scripts/test-iso-qemu.sh
```

`--config-only` nécessite `live-build` et ne lance aucun chroot. Le build complet demande root pour `live-build`, mais écrit le workspace sous `build/iso`; il ne partitionne pas le PC de build. Le lanceur QEMU crée un nouveau disque virtuel `qcow2` dans `build/vm`, sans réseau et sans disque physique attaché. Le dossier `/build` est exclu du dépôt source afin de ne pas y pousser les chroots, caches, VM et images générées. L’ISO actuelle pèse 2 832 580 608 octets (2,83 Go décimaux; 2,64 Gio), SHA-256 `d3e1a6e5d9a8bb6d8e5a9a919c055262b303daf06d3c92c4de7550282763541a`; sa somme sidecar a été vérifiée. Sous UEFI/OVMF/TCG, le menu GRUB s’affiche mais le bureau reste noir; une tentative `nomodeset` n’a pas donné de résultat exploitable. Le démarrage direct du noyau affiche le bureau, sans remplacer le test UEFI requis.

Le guide décrit le partitionnement manuel à côté de Windows, la conservation de l’ESP, la détection GRUB de Windows et la clé BitLocker. Le script GRUB post-installation a été testé en copie isolée avec commandes simulées, mais pas sur un système installé. Le menu de phase 3 avec choix mémorisé n’est pas intégré au GRUB produit. **N’installez pas cette image sur un disque réel** tant que le démarrage UEFI, l’installateur et le dual-boot n’ont pas réussi dans une VM.

## Sécurité et limites

**Le Terminal lance des commandes Bash réelles avec les permissions de l’utilisateur, sans bac à sable.** L’Éditeur sauvegarde uniquement sur action explicite; Images exporte une copie et demande confirmation avant remplacement. Store restreint les paquets, simule et exige confirmation et authentification Polkit. Paramètres ne modifie que des préférences du compte. Le Mode Gamer réduit les effets du shell, pas les services ni les paramètres du noyau. Les mini-jeux n’accèdent ni au réseau ni aux fichiers utilisateur.

L’Assistant IA envoie le texte uniquement après le clic explicite sur Envoyer vers le point d’accès configuré. À distance, HTTPS est obligatoire; HTTP n’est accepté que sur localhost/loopback. Le fournisseur peut recevoir les demandes; la clé reste en mémoire et n’est pas enregistrée. Les actions disponibles se limitent à ouvrir une app, changer d’espace, de thème ou de Mode Gamer, toujours après confirmation. Le code généré reste un brouillon non exécuté; l’utilisateur doit le relire avant de l’enregistrer.

Tout premier essai de démarrage et d’installation doit se faire dans QEMU ou VirtualBox, sur un disque virtuel. **Sauvegardez vos données et vérifiez la sauvegarde avant toute modification réelle de partition.** Ne formatez pas l’ESP Windows et ne choisissez jamais « utiliser tout le disque » pour une installation dual-boot.
