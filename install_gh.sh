#!/bin/bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
	SUDO="sudo"
else
	SUDO=""
fi

# Chargement optionnel du fichier .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USE_GITHUB_TOKEN="false"
GITHUB_TOKEN=""

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
	echo "[gh] Fichier .env detecte"
	while IFS='=' read -r key value; do
		# Ignorer les commentaires et lignes vides
		[[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
		# Trim whitespace
		key="${key#"${key%%[![:space:]]*}"}"
		key="${key%"${key##*[![:space:]]}"}"
		value="${value#"${value%%[![:space:]]*}"}"
		value="${value%"${value##*[![:space:]]}"}"
		# Remove quotes if present
		value="${value%\"}"
		value="${value#\"}"
		
		if [[ "$key" == "USE_GITHUB_TOKEN" ]]; then
			USE_GITHUB_TOKEN="$value"
		elif [[ "$key" == "GITHUB_TOKEN" ]]; then
			GITHUB_TOKEN="$value"
		fi
	done < "${SCRIPT_DIR}/.env"
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

if [[ "${USE_GITHUB_TOKEN}" == "true" && -n "${GITHUB_TOKEN}" ]]; then
	echo "[gh] Authentification via token detecte dans .env"
	echo "$GITHUB_TOKEN" | gh auth login --with-token
	
	if gh auth status >/dev/null 2>&1; then
		echo "[gh] Authentification reussie!"
		echo "[gh] Etat de connexion:"
		gh auth status
	else
		echo "[gh][WARN] Authentification via token a echoue."
		echo "[gh] Lancez manuellement:"
		echo "[gh]   gh auth login --hostname github.com --git-protocol https --web"
	fi
else
	echo "[gh] Authentification interactive requise."
	echo "[gh] Pour utiliser un token, creez/copiez un .env avec:"
	echo "[gh]   USE_GITHUB_TOKEN=true"
	echo "[gh]   GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxx"
	echo "[gh]"
	echo "[gh] Ou connectez-vous manuellement:"
	echo "[gh]   gh auth login"
	echo "[gh] Recommande (web + HTTPS):"
	echo "[gh]   gh auth login --hostname github.com --git-protocol https --web"
	echo "[gh] Verifier l'etat de connexion:"
	echo "[gh]   gh auth status"
fi
