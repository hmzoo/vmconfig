#!/bin/bash

# Variables
CLI_URL="https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64"
CLI_ARCHIVE="/tmp/vscode_cli.tar.gz"
CLI_DIR="/opt/vscode-cli"
SERVICE_NAME="code-tunnel.service"
USER="hmj"  # remplacer par le nom d'utilisateur du serveur

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "[ERREUR] Ce script doit être exécuté avec les droits root (sudo)"
    exit 1
fi

# Installation CLI Code
echo "[INFO] Téléchargement de la CLI VS Code..."
curl -Lk "$CLI_URL" -o "$CLI_ARCHIVE"

echo "[INFO] Extraction..."
mkdir -p "$CLI_DIR"
tar -xf "$CLI_ARCHIVE" -C "$CLI_DIR" --strip-components=1

# Définition des permissions appropriées
chown -R "$USER:$USER" "$CLI_DIR"
chmod +x "$CLI_DIR/code"

# Création du service systemd pour code tunnel
echo "[INFO] Création du service systemd $SERVICE_NAME..."
cat <<EOF > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=VS Code Remote Tunnel
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=/home/$USER
ExecStart=$CLI_DIR/code tunnel --accept-server-license-terms
Restart=always
RestartSec=10
Environment=HOME=/home/$USER

[Install]
WantedBy=multi-user.target
EOF

# Permissions et activation du service
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Nettoyage
rm -f "$CLI_ARCHIVE"

echo "[INFO] Installation terminée. Le tunnel VS Code est lancé automatiquement au démarrage."

echo "Important : La première authentification GitHub doit être réalisée manuellement."
echo "Ouvrez les logs du service avec : sudo journalctl -u $SERVICE_NAME -f"
echo "Puis accédez à l'URL d'authentification affichée pour valider."
echo ""
echo "Statut du service : sudo systemctl status $SERVICE_NAME"