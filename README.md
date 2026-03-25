# vmconfig

Scripts de bootstrap pour preparer rapidement un serveur Ubuntu au deploiement d'applications.

## Objectif

Ce depot installe un socle standard pour deployer vite:

- Outils systeme de base (git, curl, build tools, etc.)
- GitHub CLI (gh)
- VS Code tunnel via service systemd

Installations optionnelles via le dossier `options/`:

- Docker Engine + Docker Compose plugin
- Node.js

## Prerequis

- Serveur Ubuntu 22.x, 24.x ou 26.x
- Un utilisateur non-root existant (ex: hmj)
- Acces sudo

## Utilisation rapide (recommandee)

1. Rendre les scripts executables:

```bash
chmod +x ./*.sh
```

2. Lancer le setup par defaut (base + gh + vscode):

```bash
sudo ./install_all.sh
```

3. Ajouter des composants optionnels:

```bash
sudo ./install_all.sh --with-docker --with-node
```

Si la detection automatique de l'utilisateur echoue, passez-le explicitement:

```bash
sudo ./install_all.sh hmj --with-docker --with-node
```

## Utilisation script par script

```bash
sudo ./install_base.sh
sudo ./install_gh.sh
sudo ./install_vscode.sh hmj
sudo ./options/install_docker.sh hmj
sudo ./options/install_node.sh 22
```

## Verification rapide

```bash
docker --version
docker compose version
gh --version
node --version
npm --version
```

Si vous avez active le tunnel VS Code:

```bash
sudo systemctl status code-tunnel.service
sudo journalctl -u code-tunnel.service -f
```

## Notes importantes

- Apres installation Docker, reconnectez la session utilisateur pour appliquer le groupe docker.
- Le tunnel VS Code necessite une authentification GitHub initiale via les logs du service.
- Sur Ubuntu 26.x, le script Docker utilise temporairement le depot Docker `noble` (mode compatibilite) pour conserver un deploiement rapide en attendant un depot natif 26.x.