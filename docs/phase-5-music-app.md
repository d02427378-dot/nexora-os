# Phase 5 — application Musique Nexora

## Fonctionnalités livrées

- `src/apps/music/MusicApp.qml` est une application indépendante de Média, intégrée au dock, au lanceur et à la barre de commande.
- Choix d’un dossier local par le sélecteur natif; affichage des pistes audio lisibles du dossier courant, triées par nom. Le bouton de dossier parent permet de parcourir l’arborescence manuellement.
- Lecture d’une piste au clic, pause/reprise, piste suivante/précédente, seek, contrôle du volume, Muet, lecture aléatoire et trois modes de répétition (aucune, tout le dossier, piste).
- Qt Multimedia décode localement la piste et utilise la sortie audio du système. Les noms des fichiers constituent les titres affichés; l’application ne modifie pas les métadonnées.
- Extensions listées : MP3, FLAC, OGG/OGA, OPUS, M4A, AAC, WAV et WMA. La présence d’une extension dans le filtre ne garantit pas qu’un codec compatible est installé.
- `qml6-module-qtmultimedia` et `qml6-module-qt-labs-folderlistmodel` sont déjà dans le manifeste runtime de la distribution; cette app ne requiert pas de nouvelle dépendance.

## Différence avec Média

**Média** est un lecteur simple ouvrant un fichier audio ou vidéo individuel. **Musique** est une interface audio centrée sur une liste locale, avec transport de pistes et lecture répétée/aléatoire. Elle n’affiche pas la vidéo.

## Limites et sécurité

La bibliothèque est limitée aux fichiers audio directement contenus dans le dossier courant. Le scan n’est ni récursif ni persistant : utilisez le sélecteur ou le bouton parent pour explorer un autre dossier. Aucune base de données, modification de fichiers, extraction de métadonnées, téléchargement, playlist sauvegardée, flux réseau ou installation de codec n’est faite. Les URL autres que `file:///` sont refusées. N’ouvrez que des fichiers audio de confiance, car les bibliothèques de décodage traitent des données complexes.

## Test reproductible

```sh
scripts/build-desktop-shell.sh
scripts/test-music-runtime.sh
QT_QPA_PLATFORM=offscreen scripts/test-desktop-shell.sh
```

Le smoke test instancie `WindowCard → Loader → MusicApp`, scanne `tests/fixtures/media/test-tone.wav`, vérifie le refus d’un emplacement réseau, décode le WAV puis teste lecture, pause et seek à volume nul. Il vérifie aussi l’état des contrôles aléatoire et répétition. Aucun périphérique audio ni fichier personnel n’est requis. Sans serveur audio dans le sandbox, les plugins PulseAudio/ALSA peuvent produire des avertissements, mais le décodage et les transitions du lecteur ont été validés.
