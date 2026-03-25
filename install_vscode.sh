#!/bin/bash
set -euo pipefail

# Variables
CLI_URL="https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64"
CLI_ARCHIVE="/tmp/vscode_cli.tar.gz"
CLI_DIR="/usr/local/lib/vscode-cli"
CLI_BIN="/usr/local/bin/code"
SERVICE_NAME="code-tunnel.service"
TARGET_USER="${1:-${SUDO_USER:-}}"

# Chargement optionnel du fichier .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSCODE_TUNNEL_NAME="$(hostname 2>/dev/null || echo 'vscode-tunnel')"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
		key="${key#"${key%%[![:space:]]*}"}"
		key="${key%"${key##*[![:space:]]}"}"
		value="${value#"${value%%[![:space:]]*}"}"
		value="${value%"${value##*[![:space:]]}"}"
		value="${value%\"}"
		value="${value#\"}"
		
		if [[ "$key" == "VSCODE_TUNNEL_NAME" ]]; then
			VSCODE_TUNNEL_NAME="$value"
		fi
	done < "${SCRIPT_DIR}/.env"
fi

if [[ -z "${TARGET_USER}" ]]; then
    echo "[ERREUR] Utilisateur cible introuvable."
    echo "Exemple: sudo ./install_vscode.sh hmj"
    exit 1
fi

if ! id -u "$TARGET_USER" >/dev/null 2>&1; then
    echo "[ERREUR] Utilisateur introuvable: $TARGET_USER"
    exit 1
fi

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "[ERREUR] Ce script doit être exécuté avec les droits root (sudo)"
    exit 1
fi

# Installation CLI Code
echo "[INFO] Téléchargement de la CLI VS Code..."
curl -fL --retry 3 --retry-delay 2 "$CLI_URL" -o "$CLI_ARCHIVE"

if [[ ! -s "$CLI_ARCHIVE" ]]; then
    echo "[ERREUR] Le fichier téléchargé est vide: $CLI_ARCHIVE"
    exit 1
fi

if ! tar -tzf "$CLI_ARCHIVE" >/dev/null 2>&1; then
    echo "[ERREUR] Le téléchargement VS Code CLI n'est pas une archive valide."
    echo "URL testée: $CLI_URL"
    exit 1
fi

echo "[INFO] Extraction..."
mkdir -p "$CLI_DIR"
rm -f "$CLI_DIR/code"
tar -xzf "$CLI_ARCHIVE" -C "$CLI_DIR"

if [[ ! -f "$CLI_DIR/code" ]]; then
    echo "[ERREUR] Binaire VS Code CLI introuvable apres extraction: $CLI_DIR/code"
    exit 1
fi

ln -sf "$CLI_DIR/code" "$CLI_BIN"

# Définition des permissions appropriées
chown -R "$TARGET_USER:$TARGET_USER" "$CLI_DIR"
chmod +x "$CLI_DIR/code"

# Création du service systemd pour code tunnel
echo "[INFO] Création du service systemd $SERVICE_NAME..."
echo "[INFO] Nom du tunnel: $VSCODE_TUNNEL_NAME"
cat <<EOF > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=VS Code Remote Tunnel
After=network.target

[Service]
Type=simple
User=$TARGET_USER
Group=$TARGET_USER
WorkingDirectory=/home/$TARGET_USER
ExecStart=$CLI_BIN tunnel --accept-server-license-terms --name $VSCODE_TUNNEL_NAME
Restart=always
RestartSec=10
Environment=HOME=/home/$TARGET_USER

[Install]
WantedBy=multi-user.target
EOF

# Permissions et activation du service
if systemctl status >/dev/null 2>&1; then
    echo "[INFO] Configuration et demarrage du service systemd..."
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    SYSTEMD_AVAILABLE="true"
else
    echo "[WARN] systemd n'est pas disponible (conteneur/environnement sans init)."
    SYSTEMD_AVAILABLE="false"
fi

echo "[INFO] Recuperation des informations de connexion tunnel..."
AUTH_LINE=""

if [[ "${SYSTEMD_AVAILABLE}" == "true" ]]; then
    for _ in {1..10}; do
        RECENT_LOGS="$(journalctl -u "$SERVICE_NAME" -n 80 --no-pager 2>/dev/null || true)"
        AUTH_LINE="$(printf '%s\n' "$RECENT_LOGS" | grep -E 'https://github.com/login/device|use code [A-Z0-9-]+' | tail -n 1 || true)"

        if [[ -n "$AUTH_LINE" ]]; then
            break
        fi

        sleep 2
    done
fi

# Nettoyage
rm -f "$CLI_ARCHIVE"

if [[ "${SYSTEMD_AVAILABLE}" == "true" ]]; then
    echo "[INFO] Installation terminee. Le tunnel VS Code est lance automatiquement au demarrage."
    echo "[INFO] Dernieres lignes du service:"
    journalctl -u "$SERVICE_NAME" -n 20 --no-pager || true
else
    echo "[INFO] Installation terminee. Binaire VS Code CLI installe: $CLI_BIN"
fi

if [[ -n "$AUTH_LINE" ]]; then
    DEVICE_CODE="$(printf '%s\n' "$AUTH_LINE" | sed -n 's/.*use code \([A-Z0-9-]\+\).*/\1/p')"
    echo ""
    echo "[INFO] Authentification GitHub detectee:"
    echo "[INFO] URL  : https://github.com/login/device"
    if [[ -n "$DEVICE_CODE" ]]; then
        echo "[INFO] Code : $DEVICE_CODE"
    fi
else
    echo ""
    if [[ "${SYSTEMD_AVAILABLE}" == "true" ]]; then
        echo "[INFO] Le code de connexion GitHub n'a pas ete detecte automatiquement."
        echo "[INFO] Lancez: sudo journalctl -u $SERVICE_NAME -f"
        echo "[INFO]"
        echo "[INFO] VS Code tunnel utilise l'authentification GitHub 'device flow':"
        echo "[INFO] Tu dois scanner/ouvrir l'URL affichee dans les logs et autoriser l'acces."
        echo "[INFO] Cela ne peut pas etre automatise pour des questions de securite."
    else
        echo "[INFO] Service systemd non disponible - configuration manuelle requise."
        echo "[INFO] Pour demarrer le tunnel VS Code, lancez:"
        echo "[INFO]   su - $TARGET_USER"
        echo "[INFO]   $CLI_BIN tunnel --accept-server-license-terms --name $VSCODE_TUNNEL_NAME"
        echo "[INFO]"
        echo "[INFO] VS Code tunnel utilise l'authentification GitHub 'device flow':"
        echo "[INFO] Tu dois scanner/ouvrir l'URL affichee et autoriser l'acces."
    fi
fi

if [[ "${SYSTEMD_AVAILABLE}" == "true" ]]; then
    echo ""
    echo "[INFO] Configuration terminee avec systemd."
    echo "[INFO] Pour voir les logs en temps reel:"
    echo "[INFO]   sudo journalctl -u $SERVICE_NAME -f"
fi
echo ""
echo "Statut du service : sudo systemctl status $SERVICE_NAME"