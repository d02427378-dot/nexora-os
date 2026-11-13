# Nexora OS — architecture proposée

## Objectif et périmètre de la phase 1

Nexora OS sera une distribution personnalisée basée sur un noyau Linux existant. Le projet ne réécrit pas de noyau et ne prétend pas être un système installable à ce stade. Cette phase fixe les choix techniques, les interfaces entre composants et le squelette de travail. La production d’une ISO et la procédure d’installation sont explicitement réservées à la phase 6.

## Choix : Debian stable + KDE Plasma

Debian stable est retenue plutôt qu’Arch pour privilégier une base prévisible, une longue fenêtre de maintenance et un flux maîtrisé de paquets. C’est mieux adapté à une ISO destinée à être testée et installée par des utilisateurs, tandis qu’Arch demanderait davantage de maintenance continue et d’attention aux mises à jour. `live-build` fournit la voie de construction Debian et permet de versionner les paquets et réglages.

KDE Plasma est retenu comme socle de bureau : il fournit déjà la gestion de fenêtres, les espaces de travail, les écrans, l’accessibilité, les raccourcis et une intégration système mature. Nexora ajoutera une identité et une expérience propres au lieu de réimplémenter ces fonctions fragiles.

## Couches prévues

1. **Base système** — Debian stable `amd64`, noyau Debian, systemd, NetworkManager, PipeWire et pilotes libres disponibles dans Debian. Les firmwares non libres éventuellement nécessaires seront traités explicitement dans le manifeste de build et dans les notes de licence.
2. **Bureau** — Plasma/SDDM pour la session et l’écran de connexion; une surcouche Nexora en Qt 6/QML fournira le dock/barre, le lanceur universel, les espaces visuels, le panneau rapide et les thèmes. Les composants du bureau seront des paquets distincts pour faciliter les mises à jour et les tests.
3. **Applications Nexora** — applications ciblées par des interfaces stables (Qt/QML, avec des services isolés lorsque c’est utile). Le navigateur Qt WebEngine, l’explorateur Qt FolderListModel, l’éditeur, Images, Média et l’interface terminal sont dans `src/apps/`; les backends locaux C++ sont dans `src/desktop/`. L’éditeur n’écrit que sur une action explicite et passe par `QSaveFile`; Images travaille sur `QImage` en mémoire et utilise un `QQuickImageProvider` pour l’aperçu, puis `QSaveFile` pour les copies explicitement exportées. Média utilise Qt Multimedia pour décoder des fichiers `file:///` sélectionnés par l’utilisateur, avec `VideoOutput`/`AudioOutput`; il n’accepte pas de flux réseau. Le Terminal est un outil local non confiné qui exerce les permissions du compte, et l’interface ne doit pas laisser entendre qu’il constitue une sandbox. Les logiciels existants ne seront pas présentés comme ayant été « créés » par Nexora.
4. **Assistant IA** — interface d’actions avec permissions explicites. Les actions locales seront limitées à une liste autorisée, avec aperçu et confirmation pour les opérations destructrices ou externes. Les clés API ne seront jamais incluses dans l’ISO. Un mode sans réseau et un fournisseur configurable seront prévus.
5. **Démarrage** — GRUB 2 en UEFI, thème Nexora et entrées Windows Boot Manager/Nexora. Objectif de conception : choix visible, délai de 10 secondes, défaut documenté et préférence mémorisable. L’intégration avec Secure Boot, le comportement exact du rappel du choix et le retour au chargeur Windows devront être validés en VM avant toute procédure réelle; aucune installation ne doit remplacer l’ESP ni supprimer l’entrée Windows.
6. **Image** — `live-build` produit une image hybride Debian Live/installer personnalisée, d’abord construite dans un builder Debian dédié puis démarrée uniquement sur disque virtuel. Le profil Trixie `amd64`, le hook de compilation dans le chroot, le script et le guide sont livrés. Un ISO a été généré et reconnu comme image ISO9660 amorçable; son démarrage et l’installation UEFI restent à tester.

## Choix de technologies par fonction

| Fonction | Choix initial | Motif |
|---|---|---|
| Distribution / paquets | Debian stable, `amd64` | Base maintenable, flux de paquets et outils de live image |
| Bureau | KDE Plasma | Socle complet, composants éprouvés, extensible |
| Shell Nexora | Qt 6 + QML | Animations, rendu fluide, intégration avec l’écosystème KDE |
| Session graphique | Wayland par défaut, X11 de repli si nécessaire | Expérience moderne avec voie de compatibilité |
| Écran de connexion | SDDM | Intégration KDE et thème personnalisable |
| Chargeur | GRUB 2 UEFI | Entrées Linux/Windows, délai et thème configurable |
| Construction ISO | Debian `live-build` | Configuration versionnable et reproductible |
| Langages | QML/JavaScript pour UI; Python ou C++ pour services selon besoin | Itération rapide sans faire de tout le shell un monolithe |

Le profil de phase 6 épingle le nom de code Debian `trixie` plutôt que l’alias mouvant `stable`, ainsi que l’architecture `amd64`. Le nom de code devra être révisé lors du passage à une future version stable; les mises à jour de sécurité et de stable sont activées pour la construction.

## Démarrage dual-boot : décision de conception

Le système doit s’ajouter à Windows, et non prendre sa place. Le scénario cible est une machine UEFI/GPT avec une partition EFI existante. GRUB doit ajouter/chaîner l’entrée Windows Boot Manager tout en conservant les fichiers et l’entrée firmware Windows. Le menu Nexora affichera les deux choix demandés et attendra 10 secondes avant d’appliquer le défaut retenu.

GRUB fournit la mémorisation d’une entrée via son environnement sauvegardé, mais le contrôle visuel « se souvenir de mon choix » doit être implémenté proprement dans l’interface de menu (et testé en UEFI). Il ne faut pas prétendre qu’une simple image de thème GRUB apporte un contrôle interactif. La phase 3 validera une implémentation fonctionnelle; si une case interactive fiable n’est pas réalisable avec GRUB seul, l’interface proposera explicitement une action équivalente sans masquer cette limite.

BitLocker, Secure Boot, démarrage rapide Windows, firmware UEFI différent et machines à plusieurs disques sont des cas à documenter. Une clé de récupération BitLocker doit être disponible avant tout changement du chargeur. Secure Boot ne sera déclaré pris en charge que si la chaîne signée correspondante est réellement construite et testée.

## Sécurité et validation

- Développement et premiers essais sur QEMU/VirtualBox, avec UEFI activé et disque virtuel dédié.
- Tester démarrage live, arrêt, réseau, affichage, audio, installation simulée, mises à jour et démarrage Windows après installation dans des snapshots VM.
- Avant toute modification de partition réelle : sauvegarder les fichiers importants, vérifier l’intégrité et l’accès à la sauvegarde, conserver la clé de récupération BitLocker, désactiver si nécessaire le démarrage rapide et utiliser l’outil Windows pour réduire la partition Windows.
- Ne pas formater la partition EFI existante. Ne pas choisir « utiliser tout le disque » dans l’installateur. Sélectionner uniquement de l’espace libre vérifié.
- Les futures instructions ne fourniront pas de commande destructive à exécuter à l’aveugle. Toute commande de partitionnement sera contextualisée, précédée d’un avertissement clair et testée d’abord en VM.
- L’assistant IA n’obtiendra pas un shell root libre. Les commandes système seront exposées par des actions autorisées, validées et journalisées.

## Hors périmètre de cette phase

Le logo, l’animation, le thème GRUB, le shell et ses applications sont livrés sous forme de prototypes. Le profil `live-build`, le hook de compilation, le script ISO, le lanceur QEMU sur `qcow2` et le guide sont présents. Un premier ISO Trixie a été généré. Il reste à démarrer l’image et éprouver le dual-boot, la détection Windows, Secure Boot et la récupération dans une VM UEFI avant toute installation réelle.
