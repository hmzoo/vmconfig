#!/bin/bash

# Script d'installation de Node.js et npm
# Auteur: hmzoo
# Date: $(date +%Y-%m-%d)

# Variables
LOG_FILE="/var/log/install_node.log"
NODE_VERSION="lts"  # Options: lts, current, ou version spécifique (ex: 18.x)

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "[ERREUR] Ce script doit être exécuté avec les droits root (sudo)"
    exit 1
fi

log "[INFO] Début de l'installation de Node.js"

# Désinstallation des anciennes versions
log "[INFO] Suppression des anciennes versions de Node.js..."
apt remove -y nodejs npm 2>/dev/null || true

# Installation des prérequis
log "[INFO] Installation des prérequis..."
apt update
apt install -y curl ca-certificates gnupg lsb-release

# Installation via NodeSource (méthode recommandée)
log "[INFO] Ajout du dépôt NodeSource..."

if [ "$NODE_VERSION" = "lts" ]; then
    # Installation de la version LTS
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
elif [ "$NODE_VERSION" = "current" ]; then
    # Installation de la version Current
    curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
else
    # Installation d'une version spécifique
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -
fi

# Installation de Node.js et npm
log "[INFO] Installation de Node.js et npm..."
apt install -y nodejs

# Vérification de l'installation
log "[INFO] Vérification de l'installation..."
if node --version >/dev/null 2>&1 && npm --version >/dev/null 2>&1; then
    NODE_VER=$(node --version)
    NPM_VER=$(npm --version)
    log "[SUCCESS] Node.js installé avec succès : $NODE_VER"
    log "[SUCCESS] npm installé avec succès : $NPM_VER"
else
    log "[ERROR] Erreur lors de l'installation de Node.js"
    exit 1
fi

# Mise à jour de npm vers la dernière version
log "[INFO] Mise à jour de npm vers la dernière version..."
npm install -g npm@latest

# Installation d'outils de développement Node.js utiles
log "[INFO] Installation d'outils de développement Node.js..."
npm install -g \
    yarn \
    pnpm \
    nodemon \
    pm2 \
    typescript \
    ts-node \
    eslint \
    prettier \
    create-react-app \
    @angular/cli \
    @vue/cli \
    express-generator

# Configuration des permissions pour npm global (optionnel)
log "[INFO] Configuration des permissions npm pour l'utilisateur hmj..."
USER_HOME="/home/hmj"
NPM_CONFIG_DIR="$USER_HOME/.npm-global"

# Création du répertoire npm global pour l'utilisateur
sudo -u hmj mkdir -p "$NPM_CONFIG_DIR"
sudo -u hmj npm config set prefix "$NPM_CONFIG_DIR"

# Ajout du répertoire au PATH dans .bashrc
if ! grep -q "NPM_CONFIG_PREFIX" "$USER_HOME/.bashrc"; then
    echo "" >> "$USER_HOME/.bashrc"
    echo "# Configuration npm global" >> "$USER_HOME/.bashrc"
    echo "export NPM_CONFIG_PREFIX=~/.npm-global" >> "$USER_HOME/.bashrc"
    echo "export PATH=\$PATH:~/.npm-global/bin" >> "$USER_HOME/.bashrc"
fi

# Configuration de npm pour éviter les problèmes de permissions
sudo -u hmj npm config set fund false
sudo -u hmj npm config set audit-level moderate

log "[INFO] Installation de Node.js terminée avec succès!"

echo ""
echo "=================================="
echo "Node.js installé avec succès !"
echo "=================================="
echo ""
echo "Versions installées :"
node --version
npm --version
yarn --version 2>/dev/null || echo "Yarn: installation en cours..."
echo ""
echo "Outils installés :"
echo "- Node.js et npm"
echo "- Yarn et pnpm (gestionnaires de paquets alternatifs)"
echo "- TypeScript et ts-node"
echo "- Nodemon (rechargement automatique)"
echo "- PM2 (gestionnaire de processus)"
echo "- ESLint et Prettier (formatage de code)"
echo "- CLI pour React, Angular, Vue.js"
echo ""
echo "Configuration :"
echo "- Répertoire npm global : ~/.npm-global"
echo "- Redémarrez votre terminal ou exécutez : source ~/.bashrc"
echo ""
echo "Commandes utiles :"
echo "- npm install <package>        # Installer un paquet localement"
echo "- npm install -g <package>     # Installer un paquet globalement"
echo "- yarn add <package>           # Alternative avec Yarn"
echo "- npx <command>                # Exécuter un paquet sans installation"
echo "- pm2 start app.js             # Lancer une app avec PM2"
echo ""
echo "Log d'installation : $LOG_FILE"