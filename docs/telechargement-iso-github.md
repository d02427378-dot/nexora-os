# Télécharger et recomposer l’ISO depuis GitHub

La [page des releases Nexora OS](https://github.com/d02427378-dot/nexora-os/releases) contient deux morceaux de l’ISO, ainsi que son fichier SHA-256 et ce guide. Le dépôt est privé : connecte-toi au compte GitHub autorisé pour accéder aux fichiers.

GitHub impose une limite de moins de 2 Gio par fichier de release. L’ISO Nexora complète dépasse cette taille; les morceaux doivent donc être téléchargés tous les deux dans le même dossier et assemblés dans l’ordre `part00`, puis `part01`. Ne tente pas de démarrer directement l’un des morceaux.

## Sous Windows

Dans l’Explorateur, télécharge les assets `nexora-os-trixie-amd64.hybrid.iso.part00`, `nexora-os-trixie-amd64.hybrid.iso.part01` et `nexora-os-trixie-amd64.hybrid.iso.sha256` dans un même dossier. Ouvre **Invite de commandes** (`cmd.exe`) dans ce dossier, puis lance :

```bat
copy /b nexora-os-trixie-amd64.hybrid.iso.part00+nexora-os-trixie-amd64.hybrid.iso.part01 nexora-os-trixie-amd64.hybrid.iso
certutil -hashfile nexora-os-trixie-amd64.hybrid.iso SHA256
```

Vérifie que le résultat SHA-256 est exactement :

```text
d3e1a6e5d9a8bb6d8e5a9a919c055262b303daf06d3c92c4de7550282763541a
```

## Sous Linux

Dans le dossier contenant les trois assets, lance :

```sh
cat nexora-os-trixie-amd64.hybrid.iso.part00 nexora-os-trixie-amd64.hybrid.iso.part01 > nexora-os-trixie-amd64.hybrid.iso
sha256sum -c nexora-os-trixie-amd64.hybrid.iso.sha256
```

Le résultat attendu pour la vérification est `nexora-os-trixie-amd64.hybrid.iso: OK`.

## Avertissement d’essai

Cette image est une préversion expérimentale. Teste-la d’abord dans une machine virtuelle neuve, avec un disque virtuel, et n’attache aucun disque physique de l’hôte. Le démarrage UEFI de l’image n’est pas encore validé dans VirtualBox; si l’écran reste noir, éteins la VM sans lancer l’installation. L’installation réelle et le dual-boot Windows/Nexora ne sont pas validés.
