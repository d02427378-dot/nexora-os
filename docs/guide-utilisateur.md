# Guide utilisateur — Nexora OS

**Édition de test — 13 novembre 2026.** Nexora OS est un prototype fonctionnel basé sur Debian 13, KDE Plasma et un shell Qt 6/QML. L’ISO est construite et son empreinte a été vérifiée. Toutefois, le démarrage graphique UEFI normal n’est pas validé : dans QEMU/OVMF avec accélération TCG, le menu GRUB apparaît, puis le bureau reste noir. Le shell et `graphical.target` sont actifs d’après la console série. Les essais avec les deux backends logiciels Qt Quick n’ont pas corrigé l’affichage. Une tentative temporaire avec `nomodeset` n’a produit qu’une capture framebuffer corrompue, sans preuve que la session live ait démarré; ce résultat n’est pas concluant et l’option n’a pas été intégrée à l’ISO. Un essai technique qui démarre directement le noyau et l’initrd montre le bureau, mais ne valide pas le démarrage UEFI normal. **N’installez pas cette image sur un ordinateur ou un disque réel.** L’installation et le dual-boot avec Windows doivent d’abord réussir dans une VM dédiée.

Pour les contrôles, le partitionnement et les avertissements préalables, consulter le [guide ISO et installation dual-boot](phase-6-iso-installation.md).
Pour choisir entre le démarrage de l’ISO et l’installation du shell dans Debian 13/KDE, voir le [guide des deux méthodes VirtualBox](methodes-installation.md).

## 1. Premier essai — VM uniquement

Créez une machine virtuelle neuve et isolée, sans disque physique de l’ordinateur hôte. Une configuration de test adaptée est : firmware UEFI, 4 processeurs virtuels, 6 Go de mémoire, un disque virtuel vierge d’au moins 64 Go et réseau désactivé pour le tout premier démarrage. Attachez l’ISO Nexora en lecteur optique virtuel et démarrez sur celle-ci. Ne connectez aucun disque contenant des données à conserver.

### Procédure VirtualBox

1. Installez VirtualBox depuis la [page officielle de téléchargement](https://www.virtualbox.org/wiki/Downloads), puis ouvrez le Gestionnaire VirtualBox.
2. Cliquez sur **Nouvelle** et nommez la machine `Nexora OS`. Choisissez **Linux** puis **Debian (64-bit)** si ces choix sont proposés. Sélectionnez l’ISO Nexora comme image de démarrage et désactivez l’installation sans assistance si l’assistant VirtualBox la propose : Nexora doit démarrer depuis son propre menu live.
3. Attribuez environ **6 Go de RAM** et **2 à 4 processeurs**, sans priver Windows/macOS/Linux hôte de ses ressources. Si le PC a seulement 8 Go de RAM, commencez plutôt avec 4 Go et fermez les applications lourdes de l’hôte.
4. Créez un nouveau disque virtuel **VDI de 64 Go**, à allocation dynamique. Ce fichier restera le disque de Nexora dans la VM; il ne partitionne pas le disque physique de l’hôte.
5. Dans **Configuration → Système → Carte mère**, activez **EFI** et placez le lecteur optique avant le disque dur dans l’ordre de démarrage. Dans **Affichage**, gardez le contrôleur **VMSVGA** recommandé par VirtualBox pour Linux, réglez la mémoire vidéo à 128 Mo si disponible et laissez l’accélération 3D désactivée pour le premier essai.
6. Dans **Configuration → Stockage**, sélectionnez le lecteur optique vide et choisissez l’ISO Nexora. Le réseau peut rester désactivé pour le premier démarrage; passez-le en NAT plus tard si vous avez besoin d’Internet dans la VM.
7. Démarrez la VM et choisissez **Live system**. N’ouvrez pas l’installateur tant que le bureau live n’est pas visible. Le problème observé sous QEMU/TCG n’a pas encore été testé dans VirtualBox : un écran noir dans VirtualBox reste donc possible. Si cela arrive, éteignez la VM, ne choisissez aucune installation, et conservez son journal `VBox.log` ainsi que la version de VirtualBox pour le diagnostic.
8. Seulement lorsque le démarrage live et l’installateur ont été vérifiés dans cette VM, prenez un instantané VirtualBox avant l’installation. Installez alors **dans le disque virtuel VDI de 64 Go uniquement** et vérifiez que le récapitulatif de l’installateur ne désigne aucun disque physique de l’ordinateur. N’ajoutez jamais un disque réel de l’hôte à cette VM.

Le menu GRUB de l’ISO affiche un compte à rebours de 10 secondes; l’entrée par défaut lance la session live. Dans le sandbox de build, la sélection atteint le système graphique mais l’écran reste noir en UEFI/TCG. Cette limitation est documentée et n’est pas une invitation à contourner GRUB sur votre ordinateur. Essayez d’abord l’ISO dans une VM UEFI disposant d’une accélération appropriée; ne lancez pas l’installateur et n’écrivez pas sur un disque tant que le démarrage et l’installateur n’ont pas été validés dans une VM.

Le script fourni pour les essais crée un disque `qcow2` neuf et un fichier de variables OVMF dans `build/vm/`, désactive le réseau et n’attache aucun disque physique. Il refuse d’écraser les fichiers d’un essai précédent. Voir les instructions dans le guide Phase 6 avant de l’exécuter.

## 2. Utiliser le bureau Nexora

Le shell Nexora regroupe les applications, une barre de commande universelle, des fenêtres et quatre espaces de travail visuels. Utilisez le lanceur pour ouvrir les applications, puis la barre de commande pour rechercher une application, un fichier ou une action prise en charge. Les espaces permettent de séparer les tâches sans fermer les fenêtres. Les fonctions de la barre de commande restent celles de la version prototype; elle n’exécute pas les requêtes comme des commandes système privilégiées.

Dans **Paramètres**, choisissez l’un des thèmes **Obsidian**, **Aurora** ou **Nebula**. Vous pouvez réduire les animations décoratives et activer le **Mode Gamer**. Dans cette version, le Mode Gamer simplifie l’apparence et masque des éléments décoratifs; il ne coupe pas les services système, ne modifie pas le noyau et ne promet pas d’augmentation mesurée des performances.

## 3. Les douze applications

1. **Navigateur Nexora** — navigue sur le Web avec Qt WebEngine. Une connexion Internet est nécessaire pour les sites distants. Les cookies et le contenu web doivent être traités comme dans un navigateur classique; n’y saisissez pas d’informations sensibles sur un site auquel vous ne faites pas confiance.
2. **Fichiers** — parcourt les dossiers et fichiers locaux. L’application permet de consulter les fichiers du compte; vérifiez le chemin avant toute opération sur un fichier important.
3. **Terminal** — ouvre un shell Bash. Les commandes s’exécutent réellement avec les permissions du compte utilisateur, sans bac à sable. Une commande avec `sudo` peut modifier tout le système : ne collez pas de commande inconnue.
4. **Éditeur** — ouvre et modifie du texte UTF‑8. Les modifications restent dans le tampon tant que vous ne choisissez pas explicitement de les enregistrer. Vérifiez le nom et le chemin avant l’enregistrement.
5. **Images** — réalise les transformations proposées sur une image et exporte le résultat dans une copie. Vérifiez le fichier de destination; l’export ne doit pas être pris pour une sauvegarde complète.
6. **Média** — lit des fichiers audio ou vidéo locaux. Il s’agit d’un lecteur simple, pas d’un service de diffusion.
7. **Musique** — parcourt un dossier local choisi et permet de lire une piste, de régler le volume, de se déplacer dans la piste, et d’activer le mode aléatoire ou la répétition.
8. **Nexora Store** — présente un catalogue contrôlé de paquets Debian provenant des index APT déjà présents. L’application n’actualise pas les dépôts; si le catalogue est périmé, elle ne lance pas `apt update`. Avant chaque installation ou retrait, elle simule l’opération, affiche le plan, puis attend votre confirmation et, si nécessaire, l’authentification système. Seuls les paquets autorisés par son catalogue sont acceptés.
9. **Paramètres** — change le thème, réduit les animations, active ou désactive le Mode Gamer et rétablit les préférences du shell. Les réglages Nexora documentés sont des préférences du compte; les réglages matériels et avancés restent du ressort de KDE.
10. **Moniteur** — affiche des informations locales de processeur, mémoire, durée de fonctionnement et processus à partir de `/proc`. Cette application est en lecture seule : elle ne termine pas les processus et ne change pas les services.
11. **Arcade Nexora** — propose quatre mini-jeux hors ligne : Morpion, Snake, Memory et 2048.
12. **Assistant IA** — accepte une requête libre et peut proposer une réponse, un brouillon de code ou une action autorisée du shell. Il n’y a pas de modèle ni de clé inclus dans Nexora. Configurez un endpoint compatible Chat Completions, un identifiant de modèle et votre propre clé. La requête ne part qu’après votre clic explicite sur **Envoyer**. Le fournisseur choisi peut recevoir le texte : n’y transmettez pas de données confidentielles sans vérifier ses conditions. La clé reste en mémoire de la fenêtre et n’est pas enregistrée par Nexora. Un brouillon de code est inséré dans l’Éditeur comme document non enregistré et n’est pas exécuté automatiquement. Toute action proposée doit être relue et confirmée; l’assistant ne peut ni exécuter une commande shell, ni installer un paquet, ni modifier des partitions.

## 4. Sécurité et sauvegardes

Nexora est un prototype; ses applications ne remplacent pas une sauvegarde. Sauvegardez vos documents ailleurs avant toute opération système. N’utilisez pas le Terminal pour exécuter des commandes copiées sans en comprendre l’effet. Les commandes administrateur, l’installation de paquets et les écritures de fichiers doivent rester explicites.

Pour un futur essai dual-boot, le document Phase 6 détaille les précautions Windows : sauvegarde vérifiée, clé de récupération BitLocker, désactivation du démarrage rapide, réduction du volume Windows depuis Windows en laissant l’espace non alloué, partitionnement manuel dans cet espace, et conservation sans formatage de la partition EFI Windows. **Ne choisissez jamais « utiliser tout le disque »** pour une installation à côté de Windows. Ces indications ne signifient pas que l’installateur Nexora est actuellement validé : l’essai doit d’abord être effectué dans une VM avec des disques virtuels sauvegardés.

Le script post-installation qui demande à GRUB de détecter Windows a été testé uniquement dans une copie temporaire avec commandes simulées. Cela valide ses contrôles de confirmation et quelques scénarios de restauration, mais pas `os-prober`, `update-grub`, un démarrage UEFI réel ni un dual-boot complet.

## 5. Problème connu : écran noir sous UEFI/TCG

Dans l’environnement de build QEMU sans `/dev/kvm`, OVMF affiche GRUB, mais la session graphique reste noire. La console série confirme `graphical.target`, Plasma et le service `nexora-shell.service` actifs. Les essais avec `QT_QUICK_BACKEND=software` et `QSG_RHI_BACKEND=software` n’ont pas résolu le problème; la capture UEFI reste noire. La cause exacte n’est pas établie. Le démarrage direct du noyau et de l’initrd permet de voir le bureau dans ce même sandbox, mais contourne le chemin firmware/GRUB et ne suffit donc pas pour déclarer l’ISO prête à installer.

Avant toute utilisation sur une machine réelle, il faut réussir en VM UEFI le démarrage live, le clavier, les applications principales, l’ouverture de l’installateur et une installation complète sur disque virtuel. Pour déclarer le dual-boot prêt, il faut également vérifier plusieurs redémarrages de Windows et Nexora dans une VM à deux systèmes. Ces validations restent à faire.

## Documents associés

- [Guide de build ISO et installation dual-boot](phase-6-iso-installation.md)
- [README du projet et commandes de développement](../README.md)
- [Détails de l’Assistant IA](phase-5-ai-assistant.md)
- [Détails des Paramètres](phase-5-settings.md)
