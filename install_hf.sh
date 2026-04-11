#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./install_hf.sh
# Installe le CLI officiel Hugging Face (commande `hf`)
# via l'installateur officiel : https://huggingface.co/docs/huggingface_hub/installation
# Lit optionnellement HF_TOKEN et HF_HOME depuis un fichier .env adjacent.

log() {
	echo "[hf] $*"
}

# Chargement optionnel du fichier .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HF_TOKEN=""
HF_HOME=""

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
	log "Fichier .env detecte"
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

		if [[ "$key" == "HF_TOKEN" ]]; then
			HF_TOKEN="$value"
		elif [[ "$key" == "HF_HOME" ]]; then
			HF_HOME="$value"
		fi
	done < "${SCRIPT_DIR}/.env"
fi

# Appliquer HF_HOME si defini
if [[ -n "${HF_HOME}" ]]; then
	log "HF_HOME configure : ${HF_HOME}"
	export HF_HOME="${HF_HOME}"
	mkdir -p "${HF_HOME}"
	# Persister dans ~/.bashrc si pas deja present
	if ! grep -qF "HF_HOME" "${HOME}/.bashrc" 2>/dev/null; then
		echo "export HF_HOME=\"${HF_HOME}\"" >> "${HOME}/.bashrc"
	fi
fi

log "Installation du CLI Hugging Face"
curl -LsSf https://hf.co/cli/install.sh | bash

# S'assurer que ~/.local/bin est dans le PATH pour la session courante
if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
	export PATH="${HOME}/.local/bin:${PATH}"
fi

log "Verification de l'installation"
if ! command -v hf &>/dev/null; then
	log "ATTENTION : la commande 'hf' est introuvable dans le PATH."
	log "Ajoutez '~/.local/bin' a votre PATH puis relancez votre shell."
	log "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
	log "  source ~/.bashrc"
	exit 1
fi

hf --version

# Authentification automatique via token
if [[ -n "${HF_TOKEN}" ]]; then
	log "Authentification via token detecte dans .env"
	hf auth login --token "${HF_TOKEN}"
	if hf auth status >/dev/null 2>&1; then
		log "Authentification reussie !"
		hf auth status
	else
		log "WARN : Authentification via token a echoue."
		log "Lancez manuellement : hf auth login"
	fi
else
	log "Installation reussie -- lancez 'hf auth login' pour vous connecter au Hub"
	log "Ou ajoutez HF_TOKEN dans le fichier .env pour une auth automatique."
fi
