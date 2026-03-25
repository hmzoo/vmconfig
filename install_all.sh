#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   sudo ./install_all.sh [username] [--with-docker] [--with-node]
# Exemple:
#   sudo ./install_all.sh --with-docker --with-node
#   sudo ./install_all.sh hmj --with-docker --with-node
# Compatible: Ubuntu 22.x, 24.x, 26.x

if [[ "${EUID}" -ne 0 ]]; then
  echo "[all][ERREUR] Lancez ce script avec sudo."
  exit 1
fi

TARGET_USER=""

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

if [[ $# -gt 0 && "$1" != --* ]]; then
  TARGET_USER="$1"
  shift || true
fi

WITH_DOCKER="false"
WITH_NODE="false"
for arg in "$@"; do
  case "$arg" in
    --with-docker)
      WITH_DOCKER="true"
      ;;
    --with-node)
      WITH_NODE="true"
      ;;
    *)
      echo "[all][ERREUR] Option inconnue: $arg"
      echo "Usage: sudo ./install_all.sh [username] [--with-docker] [--with-node]"
      exit 1
      ;;
  esac
done

if [[ -z "${TARGET_USER}" ]]; then
  TARGET_USER="$(detect_default_user)"
fi

if [[ -z "${TARGET_USER}" ]]; then
  echo "[all][ERREUR] Utilisateur introuvable automatiquement."
  echo "Utilisation: sudo ./install_all.sh <username> [--with-docker] [--with-node]"
  exit 1
fi

if ! id -u "${TARGET_USER}" >/dev/null 2>&1; then
  echo "[all][ERREUR] Utilisateur introuvable: ${TARGET_USER}"
  exit 1
fi

echo "[all] Utilisateur cible: ${TARGET_USER}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_step() {
  local name="$1"
  local cmd="$2"
  echo ""
  echo "[all] >>> ${name}"
  eval "$cmd"
}

run_step "Base system" "bash \"${ROOT_DIR}/install_base.sh\""
run_step "GitHub CLI" "bash \"${ROOT_DIR}/install_gh.sh\""
run_step "VS Code tunnel" "bash \"${ROOT_DIR}/install_vscode.sh\" \"${TARGET_USER}\""

if [[ "${WITH_DOCKER}" == "true" ]]; then
  run_step "Docker (option)" "bash \"${ROOT_DIR}/options/install_docker.sh\" \"${TARGET_USER}\""
fi

if [[ "${WITH_NODE}" == "true" ]]; then
  run_step "Node.js (option)" "bash \"${ROOT_DIR}/options/install_node.sh\""
fi

echo ""
echo "[all] Setup termine."
echo "[all] Deconnectez/reconnectez ${TARGET_USER} pour activer le groupe docker."
