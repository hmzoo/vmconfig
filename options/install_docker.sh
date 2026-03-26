#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   sudo ./options/install_docker.sh [username]

detect_default_user() {
	if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
		echo "${SUDO_USER}"
		return
	fi
	local login_user=""
	login_user="$(logname 2>/dev/null || true)"
	if [[ -n "${login_user}" && "${login_user}" != "root" ]]; then
		echo "${login_user}"
		return
	fi
	awk -F: '$3 >= 1000 && $1 != "nobody" { print $1; exit }' /etc/passwd
}

TARGET_USER="${1:-}"
if [[ -z "${TARGET_USER}" ]]; then
	TARGET_USER="$(detect_default_user)"
fi

if [[ "${EUID}" -ne 0 ]]; then
	SUDO="sudo"
else
	SUDO=""
fi

log() {
	echo "[docker] $*"
}

resolve_docker_codename() {
	# shellcheck disable=SC1091
	source /etc/os-release

	if [[ "${ID:-}" != "ubuntu" ]]; then
		echo "[docker][ERREUR] Ce script supporte uniquement Ubuntu."
		exit 1
	fi

	local major_version="${VERSION_ID%%.*}"
	local codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"

	if [[ "${major_version}" != "22" && "${major_version}" != "24" && "${major_version}" != "26" ]]; then
		echo "[docker][ERREUR] Version detectee: ${VERSION_ID:-inconnue}. Versions supportees: Ubuntu 22.x, 24.x, 26.x."
		exit 1
	fi

	if [[ "${major_version}" == "26" ]]; then
		# Docker peut publier le support Ubuntu 26 avec decalage; repli vers noble pour rester deployable.
		DOCKER_CODENAME="noble"
		log "Ubuntu 26.x detecte: utilisation du depot Docker 'noble' en mode compatibilite."
		return
	fi

	if [[ -z "${codename}" ]]; then
		echo "[docker][ERREUR] Impossible de determiner le codename Ubuntu."
		exit 1
	fi

	DOCKER_CODENAME="${codename}"
	log "Ubuntu ${VERSION_ID:-inconnue} detecte: depot Docker '${DOCKER_CODENAME}'."
}

if [[ -z "${TARGET_USER}" ]]; then
	echo "[docker][ERREUR] Impossible de determiner l'utilisateur cible."
	echo "Usage: sudo ./options/install_docker.sh [username]"
	exit 1
fi

if ! id -u "${TARGET_USER}" >/dev/null 2>&1; then
	echo "[docker][ERREUR] Utilisateur introuvable: ${TARGET_USER}"
	exit 1
fi

log "Suppression des anciennes versions Docker si presentes"
${SUDO} apt-get remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc || true

resolve_docker_codename

log "Installation des dependances"
${SUDO} apt-get update -y
${SUDO} apt-get install -y ca-certificates curl gnupg

log "Ajout de la cle et du depot Docker officiel"
${SUDO} install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO} gpg --dearmor -o /etc/apt/keyrings/docker.gpg
${SUDO} chmod a+r /etc/apt/keyrings/docker.gpg

echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${DOCKER_CODENAME} stable" \
	| ${SUDO} tee /etc/apt/sources.list.d/docker.list >/dev/null

log "Installation de Docker Engine et Compose plugin"
${SUDO} apt-get update -y
${SUDO} apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log "Activation du service docker"
${SUDO} systemctl enable docker
${SUDO} systemctl start docker

log "Ajout de ${TARGET_USER} au groupe docker"
${SUDO} usermod -aG docker "${TARGET_USER}"

log "Validation"
${SUDO} docker --version
${SUDO} docker compose version

echo "[docker] Installation terminee."
echo "[docker] IMPORTANT: reconnectez-vous pour appliquer le groupe docker a ${TARGET_USER}."
