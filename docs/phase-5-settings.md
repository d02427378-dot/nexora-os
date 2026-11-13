# Phase 5 — Paramètres Nexora

## Fonctionnalités livrées

`src/apps/settings/SettingsApp.qml` remplace la maquette de paramètres et est reliée à la fenêtre du shell. Les choix sont conservés avec `Qt.labs.settings`/`QSettings`, sous l’identité d’application Nexora :

- **Apparence** — sélection immédiate d’Obsidian, Aurora ou Nebula; le thème sélectionné est restauré au lancement suivant.
- **Accessibilité** — « Réduire les animations » désactive le fond décoratif pulsant du shell et reste mémorisé.
- **Bureau** — Mode Gamer masque le décor et les panneaux facultatifs du prototype; la préférence est mémorisée. Les quatre espaces visuels sont listés.
- **Système** — nom de l’écran, dimensions de la fenêtre d’aperçu et densité de pixels sont affichés en lecture seule; l’onglet À propos indique la plateforme et la version Qt.
- **Rétablir les préférences** réinitialise le thème et les options du shell aux valeurs par défaut.

Le module runtime `qml6-module-qt-labs-settings` est ajouté au manifeste Debian. Le runner définit l’identité d’organisation avant l’initialisation QML afin que QSettings utilise le fichier de configuration utilisateur normal.

## Limites et garde-fous

Cette application enregistre uniquement des préférences du compte utilisateur. Elle ne modifie pas la résolution matérielle, les services, le réseau, l’heure, les comptes ni les fichiers de configuration système. Les réglages avancés de matériel et de système restent confiés à KDE Configuration du système. Le Mode Gamer de cette phase est un réglage visuel; il ne change pas les services ni les performances du noyau.

Le test QML emploie un magasin mémoire afin de ne pas écrire dans le profil réel. Un smoke test séparé lance le runner Nexora, écrit un fichier QSettings sous `/tmp`, crée le shell complet et vérifie qu’il restaure le thème et les options; le fichier temporaire est supprimé à la sortie.

## Tests

```sh
scripts/build-desktop-shell.sh
scripts/test-desktop-shell.sh
scripts/test-settings-runtime.sh
```

Le smoke QSettings nécessite le module `qml6-module-qt-labs-settings` du manifeste. Aucun privilège administrateur ni changement matériel n’est utilisé.
