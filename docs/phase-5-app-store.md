# Phase 5 — Nexora Store, catalogue APT

## Fonctionnalités livrées

- `src/apps/store/StoreApp.qml` est reliée au dock/lanceur et charge `SoftwareCenterBackend` via `Nexora.Store`.
- L’inventaire est consulté dans les index APT déjà configurés sur la machine. `apt-cache show` et `dpkg-query` déterminent la disponibilité, la version et l’état installé; aucun rafraîchissement de dépôt ni accès réseau n’est démarré par l’application.
- Recherche locale dans un catalogue explicite de 12 applications Debian courantes. Seuls ces identifiants exacts sont admissibles; les commandes et noms ne passent jamais par un shell.
- Avant chaque installation ou retrait, le backend lance `apt-get -s` en simulation. L’utilisateur voit le plan des paquets, puis doit confirmer l’opération exacte dans une boîte de dialogue. Seule cette confirmation appelle `pkexec /usr/bin/apt-get`; l’agent Polkit et l’authentification système effectuent l’élévation.
- L’installation demande `--no-install-recommends`. Le retrait utilise `apt-get remove` et ne purge pas les configurations. Aucun `autoremove`, changement de dépôt, `apt update`, commande personnalisée ni manipulation de partition n’est proposé.
- Le manifeste Nexora liste explicitement `apt` et `pkexec`; KDE fournit l’agent d’authentification de session requis par Polkit.

## Garde-fous et limites

La simulation `apt-get -s` ne change pas le système. En production, l’installation/le retrait ne démarre qu’après clic explicite sur le bouton de confirmation. Le backend ne permet pas d’envoyer un nom de paquet arbitraire : il revérifie l’allowlist, l’état disponible/installé, le résultat de simulation, le type d’action et l’identifiant exact avant de lancer `pkexec`. Ne confirmez que les dépendances que vous souhaitez installer ou retirer.

Le catalogue est volontairement limité à des applications connues; les paquets absents des sources configurées sont signalés indisponibles. L’application n’actualise pas les listes de dépôts. Les dépôts, leurs clés et leurs mainteneurs restent une dépendance de confiance de Debian : n’ajoutez pas de dépôt tiers sans en comprendre l’origine. Si aucune session Polkit fonctionnelle n’est présente, l’action privilégiée doit échouer sans changement.

## Test reproductible

```sh
scripts/build-desktop-shell.sh
ctest --test-dir build/desktop --output-on-failure
scripts/test-store-runtime.sh
QT_QPA_PLATFORM=offscreen scripts/test-desktop-shell.sh
```

Les tests C++ vérifient l’allowlist et le refus des confirmations prématurées sans lancer de commande privilégiée. Le smoke test lit les index APT locaux, contrôle les états installés et exécute `apt-get -s` sur un paquet disponible/non installé, puis vérifie le dialogue de confirmation. Il ne clique jamais sur « Confirmer » et n’exécute ni installation, ni retrait, ni `pkexec`.
