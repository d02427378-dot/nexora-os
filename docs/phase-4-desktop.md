# Phase 4 — shell de bureau Nexora

## Code livré

- `src/desktop/NexoraShell.qml` — fenêtre principale du shell de démonstration : barre supérieure, fond, dock, lanceur, panneau rapide, barre de commande, thèmes et espaces.
- `src/desktop/WindowCard.qml` — fenêtres internes déplaçables et routage vers les applications de phase 5.
- `assets/branding/nexora-grub-mark.png` — icône PNG utilisée par le shell pour éviter un greffon SVG Qt à l’exécution; le logo SVG maître reste disponible.
- `tests/qml/tst_desktop.qml` — tests de thèmes, espaces, fenêtres, recherche et garde-fous du terminal.
- `scripts/run-desktop-preview.sh` et `scripts/test-desktop-shell.sh` — lancement local et tests.

## Interactions présentes

- Lanceur d’applications filtrable, ouvert depuis l’icône Nexora du dock.
- Barre de commande universelle avec `Ctrl + Space` ou `Meta + Space` : recherche d’applications/actions; les requêtes libres sans résultat proposent Assistant Nexora et y sont préremplies, sans envoi automatique.
- Quatre espaces visuels Focus, Studio, Play et Lab avec miniatures; raccourcis `Ctrl + Alt + 1…4`.
- Fenêtres dimensionnées selon l’écran, déplaçables par leur barre de titre et fermables; le redimensionnement manuel n’est pas encore implémenté.
- Thèmes Obsidian, Aurora et Nebula.
- Mode Gamer visuel : il réduit certaines décorations; il ne règle pas les services, pilotes, fréquences ou ressources système.

## Lancer et tester

Dépendances de développement : Qt 6 avec Qt Quick Controls, Qt Quick Layouts et Qt Network.

```sh
scripts/run-desktop-preview.sh
scripts/test-desktop-shell.sh
```

L’aperçu est un shell autonome en fenêtre maximisée; il ne remplace pas le gestionnaire de fenêtres ou la session Plasma. Il ne modifie ni fichiers système ni réglages du poste.

## Limites explicites

Le shell est encore une surcouche prototype et n’est pas la session Nexora installée. Les douze applications désormais reliées sont Navigateur, Fichiers, Terminal, Éditeur, Images, Média, Musique, Boutique, Paramètres, Moniteur, Mini-jeux et Assistant IA. Elles ont des fonctions réelles et des tests associés; les détails sont dans les documents `phase-5-*.md`.

L’Assistant utilise un endpoint compatible Chat Completions configurable par l’utilisateur; aucune clé ou modèle n’est livré. La requête n’est envoyée qu’après clic. Les propositions sont limitées à l’ouverture d’apps, au changement d’espace/thème et au Mode Gamer, avec confirmation explicite. Le code généré reste un brouillon non exécuté et doit être enregistré manuellement depuis l’Éditeur.

## Vérification

La validation actuelle utilise Qt 6.4.2 / Ubuntu 24.04 sandbox : tests Qt Quick, CTest C++ et smoke tests applicatifs, dont un backend Assistant factice et un serveur HTTP loopback. Les tests réseau n’appellent aucun fournisseur distant; les tests média décodent des fixtures synthétiques à volume nul. Cela ne remplace pas l’essai sur Debian stable ni la validation de la future ISO en VM.
