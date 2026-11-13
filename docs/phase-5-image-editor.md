# Phase 5 — cinquième application : Images Nexora

## Fonctionnalités livrées

- Ouverture d’images locales par sélecteur système et aperçu réel QImage fourni dans le shell.
- Rotation 90° gauche/droite, miroirs horizontal/vertical, noir et blanc, luminosité, contraste, redimensionnement proportionnel en boîte, annulation d’une transformation et retour à l’image chargée.
- Transformations non destructives : les pixels modifiés restent en mémoire jusqu’à **Enregistrer une copie…**.
- Export PNG, JPEG, WebP, BMP et TIFF par `QImageWriter` vers un `QSaveFile`; un dossier manquant, un format non supporté, une destination non locale, réseau ou lien symbolique est refusé.
- Dialogue avant écrasement d’un fichier existant. JPEG/WebP déclenchent aussi un avertissement de compression avec perte et, pour JPEG, de perte possible de transparence. Le fichier ouvert reste inchangé si l’utilisateur choisit une autre destination.
- Historique Undo borné à quatre opérations. Le preview image-provider est sans fichier temporaire et l’application ne crée aucun export automatiquement.

## Limites et garde-fous

- Images compressées plafonnées à 40 Mio, dimensions à 16 mégapixels, et limite d’allocation du décodeur Qt fixée à 256 Mio. L’historique peut encore demander une quantité importante de mémoire sur les grandes photos.
- Les GIF animés sont ouverts sur leur première image. Pas encore de recadrage interactif, calques, texte, outils de sélection, filtres artistiques, gestion avancée des profils colorimétriques ou multi-images.
- Les opérations pixel se font dans le backend C++; l’aperçu reste en mémoire. Les essais automatisés utilisent une petite fixture PNG synthétique, jamais une photo personnelle.
- **Enregistrer une copie…** n’écrase rien sans sélection explicite d’une destination et confirmation distincte. Vérifiez le chemin et le format avant d’accepter; JPEG/WebP sont avec perte. La sauvegarde est atomique, mais sélectionner délibérément le même chemin source et confirmer le remplacement change ce fichier.

## Tests

```sh
scripts/build-desktop-shell.sh
ctest --test-dir build/desktop --output-on-failure
scripts/test-image-editor-runtime.sh
QT_QPA_PLATFORM=offscreen scripts/test-desktop-shell.sh
```

La suite C++ crée des PNG dans `QTemporaryDir`, vérifie rotation, Undo, Reset, aperçu, export de copie et refus d’écraser sans confirmation. Le smoke test lance le vrai chemin `WindowCard → Loader → ImageEditorApp`, vérifie l’aperçu local puis rotation/Undo/Reset, et quitte sans exporter de fichier.
