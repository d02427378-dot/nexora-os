# Phase 5 — Moniteur système Nexora

## Fonctionnalités

`src/apps/monitor/TaskManagerApp.qml` est chargé par `WindowCard` et relié à `SystemMonitorBackend`, un QObject enregistré dans `Nexora.System`.

Le backend lit directement procfs, sans lancer de commande externe :

- CPU global par différence entre les compteurs de `/proc/stat`;
- mémoire utilisée et totale depuis `/proc/meminfo` (`MemAvailable`, avec calcul de repli pour les noyaux anciens);
- uptime depuis `/proc/uptime`;
- nombre de processus visibles, noms, PID, RSS et deltas CPU à partir de `/proc/<pid>/comm`, `status` et `stat`.

Un échantillon est actualisé toutes les deux secondes. L’interface donne les mesures globales, une liste triée par activité CPU puis mémoire, et un filtre local par nom ou PID. La liste est limitée aux 120 processus les plus actifs/consommateurs visibles.

## Sécurité et limites

Le Moniteur est strictement en lecture seule. Il n’expose aucune fonction `kill`, `terminate` ou `suspend`, et n’écrit aucun fichier ni réglage système. Il ne lit pas les lignes de commande complètes : uniquement le nom `comm`, le PID, l’utilisation CPU et la mémoire RSS. Les processus masqués par les permissions ou la configuration `hidepid` peuvent ne pas apparaître dans la liste; le compteur reflète les répertoires PID visibles dans procfs. La mesure CPU par processus est une proportion de la capacité CPU totale du système entre deux échantillons.

Les fichiers `/proc` sont spécifiques à Linux; sur un système non Linux ou avec procfs restreint, certaines valeurs pourront être indisponibles. Ce Moniteur observe les processus, mais ne prétend pas remplacer les interfaces KDE de gestion ou de diagnostic.

## Tests

```sh
scripts/build-desktop-shell.sh
ctest --test-dir build/desktop --output-on-failure
scripts/test-monitor-runtime.sh
```

Le test C++ lit les vraies données procfs, contrôle les plages/valeurs et vérifie que le backend n’expose aucune méthode de contrôle de processus. Le smoke test lance le runner Nexora, charge `WindowCard` et `TaskManagerApp`, vérifie les métriques, la liste et le filtre. Aucune commande d’arrêt n’est appelée; aucun privilège n’est requis.
