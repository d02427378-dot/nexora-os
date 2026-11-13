# Phase 5 — troisième application : Terminal Bash

## Livrable

Le terminal est un vrai interpréteur Bash local :

- `src/apps/terminal/TerminalApp.qml` — interface Nexora, entrée de commande, historique de sortie, code de retour, répertoire courant, effacement et bouton d’annulation.
- `src/desktop/TerminalBackend.{hpp,cpp}` — backend Qt `QProcess`, Bash sans profils interactifs, lecture asynchrone de stdout/stderr, conservation du dossier courant entre commandes, sanitation de caractères ANSI de contrôle et limites de sortie.
- `tests/cpp/tst_terminalbackend.cpp` — tests C++ limités à `printf`, `pwd`, `cd /tmp` et à l’annulation de `sleep`.
- `tests/qml/TerminalWindowSmoke.qml` et `scripts/test-terminal-runtime.sh` — test d’intégration qui ouvre la véritable fenêtre du bureau puis exécute uniquement un `printf` inoffensif.

Le backend n’interprète pas les commandes dans QML et ne réutilise pas la console fictive de phase 4. Chaque saisie est passée à Bash comme commande, dans un processus enfant séparé. La variable `PWD` et le répertoire de travail sont reportés au processus suivant. Bash n’est pas lancé en mode interactif; son entrée standard est fermée pour éviter d’attendre une saisie invisible. Les variables de pagination sont désactivées autant que possible.

## Construire et tester

Pré-requis runtime Qt 6 et Bash. Pour les tests C++, il faut en plus Qt Test.

```sh
scripts/build-desktop-shell.sh
scripts/test-terminal-runtime.sh
ctest --test-dir build/desktop --output-on-failure
scripts/test-desktop-shell.sh
```

Le module QML `Nexora.Terminal` est enregistré par le runner C++ de Nexora. Un lecteur QML générique tel que `qmlscene` ne peut donc pas instancier l’application Terminal seule sans ce runner. `qmllint` peut signaler le type importé comme inconnu pour la même raison; le build C++/MOC et le smoke test UI sont les vérifications d’exécution pertinentes.

## Avertissement de sécurité — commandes locales réelles

Cette application exécute les commandes saisies sur l’hôte où Nexora tourne et avec **les permissions complètes de l’utilisateur courant**. Elle ne filtre pas les commandes, n’interdit pas `sudo`, ne confine pas l’accès au système de fichiers et n’est pas un bac à sable. L’utilisateur peut lire, écraser ou supprimer les fichiers auxquels son compte a accès et peut modifier le système s’il dispose de privilèges administratifs. Le bouton **Annuler** envoie SIGTERM au groupe du processus, puis SIGKILL après un court délai; il ne garantit pas de pouvoir arrêter un enfant qui s’est détaché de ce groupe.

Lancez uniquement des commandes comprises et fiables. Ne collez pas une commande reçue d’une page web ou d’un tiers sans la vérifier. Ne testez pas sur une machine contenant des données irremplaçables : préférez une machine virtuelle QEMU/VirtualBox avec un disque virtuel jetable et faites une sauvegarde vérifiée avant toute modification de partition. Le Terminal Nexora n’est pas une interface d’installation et aucun essai d’ISO ne doit écrire sur un disque réel.

## Limites connues

Ce prototype ne fournit pas de pseudo-terminal complet : pas d’applications interactives TUI, pas de saisie stdin après le lancement, pas de couleurs ANSI, pas d’historique persistant, pas d’onglets, de copier/coller spécialisé, de complétion ou d’isolation. Les commandes de longue durée restent actives jusqu’à leur fin ou leur annulation. La sortie affichée et le tampon sont limités; les sorties volumineuses sont tronquées.
