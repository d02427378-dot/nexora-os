# Phase 5 — deuxième application : Explorateur de fichiers

## Livrable

`src/apps/files/FileManagerApp.qml` est relié à l’entrée **Fichiers** du shell au moyen du chargeur d’applications de `WindowCard.qml`. Il utilise le modèle système Qt `FolderListModel`, pas une liste d’exemples.

Fonctions présentes : ouverture sur le dossier personnel, navigation dans les sous-dossiers et vers le parent, saisie d’un chemin local ou d’une URL `file://`, classement des dossiers avant les fichiers, filtre par nom, affichage facultatif des fichiers cachés, sélection et ouverture avec l’application associée du système.

## Construire, lancer et tester

Les dépendances runtime ajoutées au manifeste sont `qml6-module-qt-labs-folderlistmodel` et `qml6-module-qt-labs-platform` (StandardPaths). Le build du shell reste identique :

```sh
scripts/build-desktop-shell.sh
scripts/run-desktop-preview.sh
scripts/test-desktop-shell.sh
```

Dans le shell, ouvrir **Fichiers**. Un clic sélectionne un élément; double-cliquer sur un dossier ou le sélectionner puis choisir **Ouvrir** permet d’y entrer. Pour ouvrir un fichier pris en charge, sélectionnez-le puis utilisez **Ouvrir** ou double-cliquez. L’application associée est lancée par le système via `Qt.openUrlExternally`.

La suite Qt Quick vérifie le contenu d’un dossier fixture, les fichiers cachés, le filtre, l’aller-retour parent/enfant, le refus des URL distantes et le branchement depuis le shell. La fixture contient notamment `danger.sh`; le test confirme qu’elle n’est jamais envoyée à une application externe.

## Limites et sécurité

Cette version ne crée, ne modifie, ne renomme, ne déplace et ne supprime aucun fichier. Elle n’a ni corbeille, ni aperçu intégré, ni sélection multiple, ni opérations de copie/collage. Seules les extensions de document/média prévues dans la liste blanche sont transmises à l’application associée; les extensions d’exécution usuelles (`.sh`, `.AppImage`, `.exe`, etc.) et les fichiers sans extension sont bloqués. Ce contrôle est basé sur le nom et ne vérifie pas le bit exécutable Unix. N’ouvrez que les documents auxquels vous faites confiance.

Les fichiers cachés ne sont pas visibles par défaut. Le champ d’emplacement n’accepte que les chemins locaux et les URL `file://`; le navigateur Internet ne peut pas être utilisé comme transport depuis cet explorateur. Il n’existe pas encore de garde d’accès par périmètre : les permissions Linux de l’utilisateur courant restent la limite d’accès effective.
