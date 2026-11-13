# Phase 2 — identité visuelle Nexora

## Ressources livrées

- `assets/branding/nexora-mark.svg` — symbole seul sur fond transparent : hexagone néon violet/cyan et étoile à quatre branches.
- `assets/branding/nexora-logo.svg` — logo complet sur fond sombre, avec le nom Nexora et son descripteur.
- `assets/branding/boot-pulse.svg` — écran de démarrage animé en boucle (halo, étoile et indicateur de progression).
- `assets/branding/splash-preview.html` — aperçu autonome, lisible dans un navigateur moderne.
- `assets/branding/theme.css` — variables et conventions de couleur, surfaces, arrondis, focus et mouvement réduit pour les futures interfaces.

## Palette

| Rôle | Valeur |
|---|---|
| Fond profond | `#090C16` |
| Surface | `#101629` |
| Texte principal | `#EDF0FF` |
| Texte secondaire | `#93A0BF` |
| Violet | `#A56BFF` |
| Indigo | `#7771FF` |
| Cyan | `#41E7FF` |
| Focus clavier | `#70EAFF` |

## Rendu au démarrage

L’animation SVG est une ressource animée réelle, testable dans un navigateur compatible SVG SMIL, et possède une composition statique de repli. **Elle n’est pas un thème GRUB animé.** GRUB utilisera un fond/logo statique pour rester compatible; le pulse sera rendu après le chargement du noyau par le thème Plymouth à intégrer et valider sur la VM dans le travail d’assemblage. Les références aux fichiers SVG de cette phase ne constituent pas encore un installateur ni une ISO bootable.

Les contrôles visuels privilégient une animation lente et non essentielle à la compréhension. Les futures interfaces doivent respecter la préférence système de réduction des animations.
