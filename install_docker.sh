#!/bin/bash

# Script d'installation de Docker et Docker Compose
# Auteur: hmzoo
# Date: $(date +%Y-%m-%d)

# Variables
LOG_FILE="/var/log/install_docker.log"
USER="hmj"  # Nom d'utilisateur à ajouter au groupe docker

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "[ERREUR] Ce script doit être exécuté avec les droits root (sudo)"
    exit 1
fi

log "[INFO] Début de l'installation de Docker"

# Désinstallation des anciennes versions
log "[INFO] Suppression des anciennes versions de Docker..."
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Installation des prérequis
log "[INFO] Installation des prérequis..."
apt update
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

# Ajout de la clé GPG officielle de Docker
log "[INFO] Ajout de la clé GPG Docker..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Ajout du dépôt Docker
log "[INFO] Ajout du dépôt Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Mise à jour des paquets
log "[INFO] Mise à jour des paquets..."
apt update

# Installation de Docker Engine
log "[INFO] Installation de Docker Engine..."
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Démarrage et activation de Docker
log "[INFO] Activation du service Docker..."
systemctl start docker
systemctl enable docker

# Ajout de l'utilisateur au groupe docker
log "[INFO] Ajout de l'utilisateur $USER au groupe docker..."
usermod -aG docker "$USER"

# Test de l'installation
log "[INFO] Test de l'installation Docker..."
if docker --version >/dev/null 2>&1; then
    log "[SUCCESS] Docker installé avec succès : $(docker --version)"
else
    log "[ERROR] Erreur lors de l'installation de Docker"
    exit 1
fi

# Installation de Docker Compose standalone (optionnel, pour compatibilité)
log "[INFO] Installation de Docker Compose standalone..."
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Création d'un lien symbolique pour la compatibilité
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Configuration de Docker
log "[INFO] Configuration de Docker (logs, réseau, stockage)..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-address-pools": [
    {
      "base": "10.222.0.0/16",
      "size": 24
    }
  ],
  "bip": "10.222.1.1/24"
}
EOF

# Redémarrage du service Docker pour appliquer la configuration
systemctl restart docker

log "[INFO] Installation de Docker terminée avec succès!"

echo ""
echo "=================================="
echo "Docker installé avec succès !"
echo "=================================="
echo ""
echo "Versions installées :"
docker --version
docker compose version
echo ""
echo "IMPORTANT :"
echo "- L'utilisateur '$USER' a été ajouté au groupe docker"
echo "- Redémarrez votre session ou exécutez : newgrp docker"
echo "- Pour tester : docker run hello-world"
echo ""
echo "Commandes utiles :"
echo "- docker ps                    # Lister les conteneurs"
echo "- docker images                # Lister les images"
echo "- docker system prune          # Nettoyer le système"
echo "- docker compose up -d         # Lancer un stack en arrière-plan"
echo ""
echo "Log d'installation : $LOG_FILE"