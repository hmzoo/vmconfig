#!/bin/bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
	SUDO="sudo"
else
	SUDO=""
fi

echo "[gh] Mise a jour du gestionnaire de paquets"
${SUDO} apt-get update -y

echo "[gh] Installation des dependances"
${SUDO} apt-get install -y curl apt-transport-https ca-certificates gnupg

echo "[gh] Ajout de la cle GPG officielle"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | ${SUDO} tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null
${SUDO} chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

echo "[gh] Ajout du depot officiel"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | ${SUDO} tee /etc/apt/sources.list.d/github-cli.list > /dev/null

echo "[gh] Installation"
${SUDO} apt-get update -y
${SUDO} apt-get install -y gh

echo "[gh] Verification"
gh --version

echo ""
echo "[gh] Authentification"
echo "[gh] Lancez la connexion GitHub avec:"
echo "[gh]   gh auth login"
echo "[gh] Recommande (web + HTTPS):"
echo "[gh]   gh auth login --hostname github.com --git-protocol https --web"
echo "[gh] Verifier l'etat de connexion:"
echo "[gh]   gh auth status"
