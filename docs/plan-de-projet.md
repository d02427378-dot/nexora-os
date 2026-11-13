# Structure du dépôt et plan par phases

## Arborescence actuelle

```text
nexora-os/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── phase-2-brand.md
│   ├── phase-3-boot.md
│   ├── phase-4-desktop.md
│   ├── phase-5-browser.md
│   ├── phase-5-file-manager.md
│   ├── phase-5-terminal.md
│   ├── phase-5-code-editor.md
│   ├── phase-5-image-editor.md
│   ├── phase-5-media-player.md
│   ├── phase-5-music-app.md
│   ├── phase-5-app-store.md
│   ├── phase-5-settings.md
│   ├── phase-5-task-manager.md
│   ├── phase-5-mini-games.md
│   ├── phase-5-ai-assistant.md
│   ├── phase-6-iso-installation.md
│   └── plan-de-projet.md
├── config/
│   ├── grub/              # modèle de menu et thème GRUB
│   ├── live-build/profile/ # profil ISO Debian Live, hooks et inclusions
│   └── package-lists/     # manifeste Debian et modules Qt runtime
├── assets/branding/       # logos, animation, palette et PNG GRUB
├── src/
│   ├── desktop/           # shell QML, runner et backends C++
│   │   ├── SoftwareCenterBackend.*  # catalogue APT, simulation et polkit
│   │   ├── SystemMonitorBackend.*   # métriques procfs en lecture seule
│   │   └── AssistantBackend.*       # Chat Completions, validations et liste d’actions sûres
│   └── apps/
│       ├── browser/       # navigateur Qt WebEngine
│       ├── files/         # explorateur Qt FolderListModel
│       ├── terminal/      # interface Bash locale
│       ├── editor/        # éditeur texte/code UTF-8
│       ├── image/         # éditeur d’images QML
│       ├── media/         # lecteur audio/vidéo
│       ├── music/         # bibliothèque audio locale
│       ├── store/         # boutique APT à catalogue contrôlé
│       ├── settings/      # préférences persistantes
│       ├── monitor/       # ressources et processus Linux
│       ├── games/         # Arcade : Morpion, Snake, Memory et 2048
│       └── assistant/     # assistant IA QML avec confirmation
├── scripts/               # build shell/ISO, QEMU, validations et smoke tests
└── tests/
    ├── cpp/               # tests des backends Qt
    ├── fixtures/          # fichiers synthétiques pour les tests
    ├── http/              # fixture loopback navigateur
    └── qml/               # tests Qt Quick et smoke tests applicatifs
```

## Phases et critères de sortie

1. **Architecture — terminée** — base, composants, arborescence et règles de sécurité définis; `scripts/validate-phase1.sh` valide le squelette.
2. **Identité visuelle — terminée** — symbole et logo SVG, animation de démarrage, aperçu navigateur et palette Nexora. L’animation est prévue pour Plymouth après chargement du noyau; GRUB reste statique.
3. **Démarrage dual-boot — prototype de configuration livré** — menu GRUB autonome Windows/Nexora, délai de 10 secondes, choix mémorisé et thème statique. Tests statiques présents; le comportement `save_env` doit encore être validé en VM UEFI. Aucune ISO ni installation n’est fournie.
4. **Bureau — prototype QML livré et testé** — barre, dock, lanceur, fenêtres, quatre espaces visuels, barre universelle, trois thèmes et Mode Gamer visuel. Le shell n’est pas encore la session installée de Nexora.
5. **Applications et assistant — terminée** — douze applications reliées au shell : Navigateur Qt WebEngine, Fichiers, Terminal Bash, Éditeur UTF-8, Images, Média audio/vidéo, Musique, Nexora Store avec APT contrôlé, Paramètres persistants, Moniteur `/proc` en lecture seule, Arcade hors ligne (Morpion, Snake, Memory, 2048) et Assistant IA configurable. Tests C++/QML, fixtures et smoke tests sont fournis. L’assistant propose des brouillons de code non exécutés et des actions de shell allowlistées avec confirmation.
6. **ISO et installation — en cours** — profil Trixie `amd64`, hook de compilation du shell dans le chroot, script `build-iso.sh`, lanceur QEMU sur disque virtuel `qcow2`, helper GRUB post-installation et guide livrés. Un ISO hybride a été généré le 12 novembre 2026 et son format bootable ISO9660 vérifié. Un défaut de chemin du wrapper a été corrigé après ce build. Il reste à démarrer l’image et tester l’installation dual-boot, le chargeur UEFI, Secure Boot et le retour arrière dans une VM avant tout usage réel.

## Dépendances de travail et sécurité

- Le menu de phase 3 reste un modèle autonome. Le profil ISO fournit un helper séparé pour détecter Windows après installation, mais le choix mémorisé avec `save_env` n’est ni intégré ni testé. L’animation de démarrage est destinée à Plymouth, pas à GRUB.
- Navigateur, Fichiers, Terminal, Éditeur, Images, Média, Musique, Boutique, Paramètres, Moniteur, Mini-jeux et Assistant sont reliés à des fonctions réelles, avec les limites décrites dans leurs documents de phase 5.
- Paramètres ne change que les préférences du compte; les réglages système avancés restent gérés par KDE. Moniteur lit `/proc` sans commande de contrôle des processus.
- Fichiers n’écrit ni ne supprime. L’Éditeur ne sauvegarde qu’après action explicite, refuse les contenus non textuels et les fichiers de plus de 2 Mio, et demande confirmation avant remplacement. Images transforme en mémoire, borne les dimensions à 16 MP et demande confirmation avant export avec perte ou remplacement.
- Terminal exécute Bash sans sandbox, avec les droits du compte : réserver les essais à une VM et ne pas y lancer de commande destructive sur un disque réel.
- Boutique ne rafraîchit pas APT et ne consulte que les index locaux. Elle restreint les paquets, simule la transaction et requiert une confirmation puis Polkit pour toute mutation.
- Média et Musique ne lisent que des fichiers locaux; les codecs dépendent des composants Qt/FFmpeg installés. Musique ne scanne que le dossier choisi, sans récursion.
- Mini-jeux n’accède ni au réseau ni aux fichiers utilisateur; score et partie restent en mémoire.
- Assistant ne contient aucune clé ou modèle intégré. Clé et historique ne sont pas persistés; une requête est envoyée au fournisseur configuré seulement après clic. HTTPS est obligatoire à distance et HTTP limité au loopback. Les propositions d’actions sont validées deux fois et confirmées par l’utilisateur; le code reste un brouillon dans l’Éditeur, sans exécution ni sauvegarde automatique.
- Le Mode Gamer réduit les effets visuels; il ne change ni le noyau ni les services.
- Sauvegarder les données et vérifier la clé de récupération BitLocker avant toute modification réelle de partition. Tester l’ISO, l’installation et le dual-boot sur des disques virtuels; ne jamais utiliser un disque réel pendant les essais.
