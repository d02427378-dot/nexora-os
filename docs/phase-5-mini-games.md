# Phase 5 — Mini-jeux Nexora

## Jeux livrés

`src/apps/games/MiniGamesApp.qml` regroupe quatre jeux QML locaux dans la fenêtre **Mini-jeux Nexora** :

- **Morpion** — deux joueurs sur le même appareil, détection des trois symboles alignés et des matchs nuls, compteur de victoires de la session.
- **Snake** — déplacement périodique, nourriture, score, détection des murs et du corps; touches fléchées ou WASD et commandes directionnelles tactiles. Le déplacement s’interrompt quand l’onglet Snake est masqué et reprend quand il est sélectionné.
- **Memory** — six paires mélangées, dévoilement des cartes, comptage des coups et retournement différé des paires erronées.
- **2048** — plateau 4×4, commandes fléchées ou WASD et tactiles, fusion d’une seule paire de même valeur par ligne et par déplacement, score et détection de fin de partie.

Les quatre jeux sont accessibles depuis le lanceur Nexora et la barre de commande universelle. L’Arcade est autonome et utilisable hors ligne.

## Implémentation et limites

Les jeux sont de petits composants Qt Quick/QML intégrés au shell. Snake dessine son plateau avec Canvas; les autres utilisent des contrôles QML. Aucun paquet de jeu, service réseau, privilège système, accès disque ni processus externe n’est requis. Le morpion est un duel local, pas un adversaire IA. Les scores et parties ne sont pas enregistrés entre les lancements.

## Validation

```sh
scripts/test-mini-games-runtime.sh
scripts/test-desktop-shell.sh
```

Le smoke test charge l’application par le vrai `WindowCard` et exerce les quatre jeux : victoire au morpion, déplacement et collision de Snake, correspondance d’une paire Memory, et règles de fusion/score de 2048. Le test Qt Quick vérifie aussi l’ouverture depuis le shell et l’entrée dans le catalogue. Tout s’exécute en mode offscreen, sans accès réseau ni écriture sur les disques utilisateur.
