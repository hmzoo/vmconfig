#!/bin/bash

# Mise à jour du gestionnaire de paquets
sudo apt update

# Installer les dépendances nécessaires
sudo apt install -y curl apt-transport-https ca-certificates

# Ajouter la clé GPG officielle GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null

# Ajouter le dépôt officiel GitHub CLI à la liste des sources apt
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Mise à jour des sources apt
sudo apt update

# Installation de l'outil gh
sudo apt install -y gh

# Vérification de l'installation
gh --version
