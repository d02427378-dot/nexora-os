# Phase 5 — première application : Navigateur Nexora

## Livrable

Le Navigateur est la première application Nexora réellement reliée à un moteur de rendu web.

- `src/apps/browser/BrowserApp.qml` — barre d’adresse, Aller/Entrée, précédent, suivant, recharger/arrêter, progression, état et vue web intégrée.
- `src/apps/browser/BrowserNavigation.js` — normalisation des URL, recherche DuckDuckGo si la saisie ressemble à une requête et allowlist des schémas.
- `src/desktop/WindowCard.qml` — charge le navigateur à la demande dans une fenêtre Nexora; l’explorateur Fichiers est désormais une seconde application réelle.
- `src/desktop/main.cpp` — initialise les attributs OpenGL requis par Qt WebEngine avant `QGuiApplication`, puis démarre le shell QML.
- `src/desktop/CMakeLists.txt` et `scripts/build-desktop-shell.sh` — build local CMake, sans installation système.
- `tests/qml/tst_browser.qml` — tests sans réseau de normalisation et de refus des schémas.
- `tests/qml/BrowserWindowSmoke.qml` et `scripts/test-browser-runtime.sh` — vérification du chemin WindowCard → BrowserApp avec une page HTTP loopback.

## Construire et lancer

Outils de développement : CMake 3.21+, compilateur C++17, Qt 6 Core/Gui/Qml/Quick et module QML Qt WebEngine. Les noms de paquets varient selon la version Debian; le manifeste `config/package-lists/nexora.list.chroot` contient les modules runtime Qt 6 requis.

```sh
scripts/build-desktop-shell.sh
scripts/run-desktop-preview.sh
scripts/test-desktop-shell.sh
scripts/test-browser-runtime.sh
```

Le build produit `build/desktop/nexora-shell`. Il n’installe rien dans `/usr`, ne touche à aucune partition et ne modifie pas le bureau système. `scripts/run-desktop-preview.sh` lance ce binaire et compile automatiquement si nécessaire.

Dans le lanceur, ouvrir **Navigateur**, puis saisir une URL HTTP/HTTPS, un nom d’hôte ou une requête. Les requêtes sans nom d’hôte sont envoyées à DuckDuckGo. Le smoke test démarre un serveur sur `127.0.0.1`, charge sa fixture HTTP et ne contacte aucun site public.

## Mesures de sécurité présentes

- Le profil WebEngine est privé/éphémère (`offTheRecord`); cookies et données de profil ne sont pas conservés au-delà de cette instance.
- L’adresse accepte les protocoles HTTP et HTTPS; la navigation initiée par une page est aussi filtrée.
- Les schémas `file:`, `javascript:` et `data:` sont refusés par le résolveur. Les contenus locaux ne peuvent pas accéder aux fichiers ni aux URL distantes.
- Les plugins sont désactivés et JavaScript ne peut pas ouvrir de fenêtres popup.
- Les téléchargements sont annulés par défaut; aucune donnée n’est écrite sur le disque depuis une page web.
- Aucun certificat invalide n’est accepté par un contournement applicatif; le comportement TLS est laissé à Qt WebEngine.

Le moteur web demeure un composant complexe exécutant du contenu distant : il doit recevoir les mises à jour de sécurité de Debian. Le navigateur n’est pas un sandbox additionnel et ne doit pas être lancé avec des privilèges root.

## Limites connues et suite

Cette première livraison n’inclut pas encore les onglets, favoris, historique persistant, gestionnaire de téléchargements, extensions, bloqueur de publicité, réglage de moteur de recherche, contrôles de cookies ou interface de permissions. Les nouveaux onglets/popups sont bloqués et les téléchargements annulés; certains sites pourront donc avoir une expérience limitée. Fichiers, Terminal, Éditeur, Images et Média sont depuis reliés à des fonctions réelles, décrites dans `phase-5-file-manager.md`, `phase-5-terminal.md`, `phase-5-code-editor.md`, `phase-5-image-editor.md` et `phase-5-media-player.md`; paramètres, boutique et moniteur restent des maquettes.

Le C++ runner est nécessaire pour préparer Qt WebEngine correctement. Le smoke test confirme l’affichage d’une page servie sur `127.0.0.1`; il ne remplace pas les essais sur des sites réels, le rendu matériel, les mises à jour et la confidentialité à valider plus tard dans une VM Debian dédiée.
