#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./install_base.sh

if [[ "${EUID}" -ne 0 ]]; then
	SUDO="sudo"
else
	SUDO=""
fi

log() {
	echo "[base] $*"
}

require_supported_ubuntu() {
	if [[ ! -f /etc/os-release ]]; then
		echo "[base][ERREUR] Impossible de verifier la distribution (fichier /etc/os-release absent)."
		exit 1
	fi

	# shellcheck disable=SC1091
	source /etc/os-release
	if [[ "${ID:-}" != "ubuntu" ]]; then
		echo "[base][ERREUR] Ce script supporte uniquement Ubuntu."
		exit 1
	fi

	local major_version="${VERSION_ID%%.*}"
	if [[ "${major_version}" != "22" && "${major_version}" != "24" && "${major_version}" != "26" ]]; then
		echo "[base][ERREUR] Version detectee: ${VERSION_ID:-inconnue}. Versions supportees: Ubuntu 22.x, 24.x, 26.x."
		exit 1
	fi

	log "Ubuntu ${VERSION_ID:-inconnue} detecte: version supportee"
}

require_supported_ubuntu

log "Mise a jour des index APT"
${SUDO} apt-get update -y

log "Installation des paquets de base"
${SUDO} apt-get install -y \
	ca-certificates \
	curl \
	gnupg \
	lsb-release \
	apt-transport-https \
	software-properties-common \
	git \
	jq \
	unzip \
	zip \
	make \
	build-essential \
	net-tools \
	htop

log "Mise a niveau des paquets installes"
${SUDO} env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log "Installation terminee"
