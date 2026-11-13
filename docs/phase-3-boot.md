# Phase 3 — menu de démarrage UEFI Windows / Nexora

## Fichiers livrés

- `config/grub/grub.cfg.in` : configuration autonome du menu avec Windows, Nexora, délai de 10 secondes et mémorisation facultative.
- `config/grub/nexora-defaults` : réglages proposés pour l’intégration GRUB.
- `config/grub/nexora-theme.txt` : thème graphique statique, fond sombre et menu lisible au clavier.
- `scripts/render-grub-config.sh` : remplace les UUID et écrit une nouvelle copie locale, sans écraser de fichier existant.
- `scripts/render-grub-assets.py` : génère les images PNG statiques nécessaires au thème, avec Pillow.
- `scripts/test-grub-config.sh` : tests statiques du rendu, des entrées et du refus d’écrasement.

## Fonctionnement

Le choix par défaut est **Lancer Nexora OS**. Le menu attend 10 secondes, puis lance Nexora si aucune entrée n’est sélectionnée. L’entrée Windows chaîne le fichier `EFI/Microsoft/Boot/bootmgfw.efi` sur la partition EFI Windows indiquée. L’entrée Nexora démarre `/vmlinuz` et `/initrd.img`, et passe à Linux l’UUID de la partition racine.

Le réglage « Basculer “se souvenir de mon choix” » est une entrée textuelle distincte. Quand il est activé, choisir Windows ou Nexora écrit l’ID correspondant dans `grubenv`; il devient le défaut au prochain démarrage. Quand il est désactivé, le défaut est Nexora. GRUB ne fournit pas de case graphique native dans son menu standard : il s’agit donc d’un interrupteur de menu, pas d’une case graphique. Les caractères accentués dépendent de la police configurée pour GRUB; ils seront validés en VM avec le thème.

## Générer les ressources statiques du thème

Dans un environnement de développement avec Pillow :

```sh
python3 scripts/render-grub-assets.py
```

Cela produit `assets/branding/nexora-grub-bg.png` et `assets/branding/nexora-grub-mark.png`. Ce thème est statique : l’animation de pulsation sera rendue après le chargement du noyau par Plymouth, pas par GRUB.

## Générer une copie de configuration d’essai

Les UUID d’exemple ci-dessous ne correspondent à aucun disque réel :

```sh
scripts/render-grub-config.sh \
  ABCD-1234 \
  11111111-2222-3333-4444-555555555555 \
  aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee \
  /tmp/nexora-grub.cfg
scripts/test-grub-config.sh
```

Le premier argument est l’UUID FAT de la partition EFI Windows; le deuxième est l’UUID de la partition contenant `/vmlinuz` et `/initrd.img`; le troisième est l’UUID du système de fichiers racine Nexora. Si `/boot` est séparé, fournir son UUID au deuxième argument. Si la racine est chiffrée, en sous-volume Btrfs, RAID/LVM, ou si Secure Boot est activé, cette configuration initiale ne suffit pas et le cas doit être conçu et testé séparément.

La partition `/boot` doit contenir un environnement GRUB (`grubenv`) initialisé lors de l’intégration de l’image; les commandes `save_env` ont besoin d’un environnement inscriptible pris en charge par GRUB. Aucune initialisation n’est effectuée sur l’hôte dans cette phase.

## Limites de validation

L’environnement de travail ne contient pas `grub-script-check`, `grub-install`, `grub-editenv` ni QEMU. Les tests du dépôt vérifient donc le rendu des variables et des éléments attendus, mais **ne certifient pas le démarrage réel**. Avant intégration, il reste obligatoire de valider syntaxe, `save_env`, UUID, chaîne Windows, délai et retour depuis Windows dans une VM UEFI avec disque virtuel. Aucun fichier généré ici n’est installé sur la machine hôte.

## Garde-fous

- Le modèle ne formate pas et ne partitionne aucun disque.
- Ne pas exécuter `grub-install` sur la machine réelle pour tester cette phase.
- En usage réel, sauvegarder les données, conserver la clé de récupération BitLocker et vérifier la sauvegarde avant toute modification de partition ou de chargeur.
- L’intégration future devra conserver la partition EFI et l’entrée Windows existantes, et documenter le retour arrière.

## Intégration prévue avec l’image de phase 6

Le profil Debian Live installe `os-prober`, mais ne l’active pas pendant la construction de l’ISO. Après une installation UEFI réussie, l’utilisateur peut exécuter explicitement `sudo /usr/share/nexora/scripts/configure-grub-after-install.sh`; le script présente d’abord les systèmes détectés, demande une confirmation, conserve une copie de `grub.cfg`, puis applique un délai de 10 secondes et active la détection Windows. Il ne lance pas `grub-install` et ne modifie pas l’ESP.

Ce helper ne déploie pas le modèle autonome `grub.cfg.in`. L’option de mémorisation `save_env`, le thème et le comportement exact des deux choix ne sont toujours pas validés dans une VM UEFI et ne doivent pas être annoncés comme intégrés. Voir [`phase-6-iso-installation.md`](phase-6-iso-installation.md) pour les limites et les essais requis.
