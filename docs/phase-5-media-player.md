# Phase 5 — lecteur Média Nexora

## Fonctionnalités livrées

- `src/apps/media/MediaPlayerApp.qml` utilise `QtMultimedia.MediaPlayer`, `AudioOutput` et `VideoOutput`.
- Ouverture par sélecteur système de fichiers audio/vidéo locaux; le code accepte uniquement des URL `file:///` et ne propose ni champ URL ni lecture réseau.
- Lecture, pause, arrêt, barre de position/seek, durée, volume et bascule Muet. La sortie vidéo intégrée conserve le ratio d’image; l’audio affiche un panneau d’album Nexora.
- Les erreurs de décodage sont visibles. Les formats et codecs réellement lisibles dépendent des plugins Qt/FFmpeg présents dans la distribution.
- `qml6-module-qtmultimedia` est ajouté au manifeste Debian Nexora; ses dépendances apportent les bibliothèques Multimedia et le plugin FFmpeg sur cette base Debian/Ubuntu. Le shell n’intègre pas sa propre copie de codecs.

## Limites et sécurité

Pas de playlist, bibliothèque musicale, sous-titres, chapitres, égaliseur, streaming, téléchargement ou import de playlist. Cette application Média est un lecteur général simple; l’application musique distincte demandée reste à réaliser. Le filtre de fichiers ne garantit pas que chaque format/codec est installé : Qt affiche une erreur si aucun décodeur compatible n’est disponible. N’ouvrez que des médias de confiance, comme pour toute bibliothèque de décodage.

Le lecteur ne fait aucune écriture, n’enregistre pas de préférences et n’accepte pas les sources HTTP/HTTPS. Le smoke test coupe le volume, car son but est de valider le décodage et le transport, pas de produire du son dans la machine de test.

## Test reproductible

```sh
scripts/build-desktop-shell.sh
scripts/test-media-runtime.sh
```

Le smoke test instancie le vrai chemin `WindowCard → Loader → MediaPlayerApp`, charge `tests/fixtures/media/test-tone.wav` (ton synthétique généré pour les tests), vérifie décodage, durée, piste audio, lecture, pause et seek. Il ne touche aucun fichier personnel et n’exige pas de périphérique audio. Dans le sandbox sans serveur audio, PulseAudio/ALSA peut imprimer des avertissements; la lecture de la fixture et les transitions de contrôle ont toutefois réussi.
