# Phase 5 — Assistant IA intégré

## Fonctionnalités

**Assistant Nexora** est accessible depuis le lanceur et la barre de commande universelle. Une requête libre sans résultat de recherche apparaît comme « Demander à Nexora IA » : elle ouvre l’assistant et préremplit le texte, mais **ne l’envoie pas**. L’utilisateur examine la demande, configure son fournisseur, puis clique sur Envoyer.

L’application accepte un point d’accès compatible avec l’API Chat Completions, un identifiant de modèle choisi par l’utilisateur et une clé API saisie dans le champ masqué. Le point d’accès initial est `https://api.openai.com/v1/chat/completions`; aucun modèle ni secret n’est imposé ou inclus dans le dépôt. Un serveur local peut être utilisé sur `localhost`/loopback en HTTP.

Le modèle est invité à produire une réponse JSON avec trois éléments : un message, un brouillon de code facultatif, et une proposition d’action facultative. Le code peut être prévisualisé puis envoyé dans un nouveau tampon de l’Éditeur. Ce document reste non enregistré et non exécuté jusqu’à ce que l’utilisateur le vérifie et choisisse explicitement de l’enregistrer.

## Actions autorisées

L’assistant ne dispose d’aucun outil permettant d’appeler un shell, d’installer un paquet ou de lire/écrire des fichiers. Le backend valide indépendamment toute action et n’accepte que : ouvrir une application Nexora allowlistée; basculer entre les quatre espaces visuels; changer parmi Obsidian, Aurora et Nebula; ou activer/désactiver le Mode Gamer du shell. L’interface présente l’action, puis demande une confirmation explicite. Un second contrôle QML refuse également les valeurs hors liste. Les réponses du modèle ne sont jamais interprétées comme des commandes.

## Confidentialité et transport

- La clé API est gardée en mémoire pendant la vie de la fenêtre seulement; elle n’est ni persistée dans QSettings, ni écrite dans un fichier, ni incluse dans les journaux applicatifs. Le bouton « Vider la clé » permet de l’effacer immédiatement.
- La requête ne part qu’après le clic explicite sur Envoyer et est transmise au point d’accès configuré. Une note avertit que le texte peut être reçu par le fournisseur choisi; ne pas y coller de données sensibles sans en évaluer les conditions.
- Les fournisseurs distants doivent utiliser HTTPS. HTTP est limité aux hôtes localhost ou aux adresses loopback; les identifiants intégrés dans l’URL et les redirections HTTP sont refusés.
- Le backend limite la demande, la durée de transfert et la taille de réponse, attend un JSON conforme, et rejette les actions inconnues. L’historique n’est pas conservé entre les requêtes ou sessions.
- Les requêtes ne sont pas envoyées à un service Manus et aucun crédit ou modèle n’est préconfiguré. L’utilisateur fournit son propre endpoint, modèle et moyen d’accès; les éventuels coûts relèvent du fournisseur configuré.

## Validation

```sh
scripts/test-assistant-runtime.sh
scripts/test-desktop-shell.sh
ctest --test-dir build/desktop --output-on-failure
```

`test-assistant-runtime.sh` compile le shell, teste le backend contre un serveur HTTP loopback local, vérifie le rejet d’un endpoint distant HTTP et d’une action `run_shell` malveillante, puis lance l’intégration QML avec un backend factice. Il ne contacte aucun modèle externe, n’utilise aucune clé réelle et n’écrit aucun fichier utilisateur. Le smoke confirme le préremplissage manuel, la confirmation d’une action allowlistée et le transfert du code dans l’Éditeur en tant que document modifié sans chemin.

## Limites

La génération dépend d’un modèle et d’un fournisseur compatibles configurés par l’utilisateur; cette livraison n’inclut ni modèle local, ni clé, ni service hébergé. Le brouillon de code n’est ni compilé ni exécuté automatiquement. Les commandes terminal, opérations de fichiers, installations APT, partitionnements et actions système privilégiées ne font pas partie de l’API d’actions Nexora.
