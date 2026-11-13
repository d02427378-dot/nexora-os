# Phase 5 — quatrième application : Éditeur de code Nexora

## Livrable

- `src/apps/editor/CodeEditorApp.qml` — éditeur monospace avec curseur ligne/colonne, ouverture de fichier, nouveau document, sauvegarde explicite, sauvegarde sous, indicateur de modification et dialogues d’abandon/remplacement.
- `src/desktop/CodeEditorBackend.{hpp,cpp}` — backend C++ enregistré sous `Nexora.Editor`; lecture locale UTF-8 et sauvegarde atomique via `QSaveFile`.
- `tests/cpp/tst_codeeditorbackend.cpp` — tests sur des fichiers créés dans `QTemporaryDir`, y compris refus d’écrasement sans confirmation, refus d’URL distante et rejet de données binaires.
- `tests/qml/CodeEditorWindowSmoke.qml` et `scripts/test-code-editor-runtime.sh` — test de l’intégration `WindowCard → Loader → CodeEditorApp`, qui modifie le tampon en mémoire sans écrire de fichier.

Le composant est chargé par l’entrée **Éditeur** du shell. L’ouverture se fait par le sélecteur Qt natif. Seuls les fichiers locaux sont acceptés; les liens symboliques valides sont résolus vers leur cible locale, les URL réseau sont refusées. Les fichiers de plus de 2 Mio, les contenus comprenant des octets NUL et les textes qui ne font pas un aller-retour UTF-8 exact sont refusés.

## Enregistrer et protéger les changements

L’éditeur **n’enregistre jamais automatiquement** pendant la frappe. Il montre « Modifié » et le bouton Enregistrer n’écrit qu’après action explicite. Un nouveau document doit être nommé avec **Enregistrer sous…**. Si la destination existe déjà, un dialogue distinct demande le remplacement; le backend revérifie aussi l’existence avant la création, afin qu’un fichier apparu entre-temps ne soit pas silencieusement écrasé. `QSaveFile` écrit un fichier temporaire puis le remplace atomiquement au commit.

Si l’utilisateur ouvre un autre fichier ou crée un document alors que le tampon est modifié, un dialogue propose **Annuler**, **Abandonner** ou **Enregistrer**. Si le document n’a pas encore de chemin, Enregistrer passe par Enregistrer sous et l’action en attente continue après une sauvegarde réussie.

## Construire et tester

```sh
scripts/build-desktop-shell.sh
scripts/test-code-editor-runtime.sh
ctest --test-dir build/desktop --output-on-failure
QT_QPA_PLATFORM=offscreen scripts/test-desktop-shell.sh
```

Les tests backend utilisent seulement des répertoires temporaires isolés; aucun fichier personnel n’est ouvert ou modifié. Le smoke test d’interface écrit uniquement dans le tampon en mémoire. La suite QML shell générique ne charge pas les applications nécessitant l’enregistrement C++ personnalisé; le smoke test dédié utilise le vrai exécutable Nexora qui enregistre TerminalBackend et CodeEditorBackend.

## Limites

Ce n’est pas un IDE complet : pas de coloration syntaxique, projets, diagnostics, complétion, recherche multi-fichiers, terminal intégré, onglets, récupération après crash ou contrôle de version. Les fichiers sont interprétés comme texte UTF-8; les autres encodages et les gros fichiers sont refusés. Un fichier ouvert peut être remplacé atomiquement lorsqu’on choisit explicitement Enregistrer; il n’existe pas encore de détection des modifications concurrentes externes depuis l’ouverture.

La sauvegarde modifie volontairement le fichier choisi et remplace ses octets par le contenu édité; n’écrasez que des fichiers que vous avez sélectionnés et vérifiés. Pour les essais Nexora, utilisez d’abord une VM et des fichiers de test, et sauvegardez vos données avant toute modification de partition.
