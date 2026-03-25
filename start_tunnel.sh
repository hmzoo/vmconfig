#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   sudo ./start_tunnel.sh [username]
#   ./start_tunnel.sh

CLI_BIN="/usr/local/bin/code"
TARGET_USER="${1:-${SUDO_USER:-$(id -un)}}"

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

		if [[ "$key" == "VSCODE_TUNNEL_NAME" && -n "$value" ]]; then
			VSCODE_TUNNEL_NAME="$value"
		fi
	done < "${SCRIPT_DIR}/.env"
fi

if ! id -u "${TARGET_USER}" >/dev/null 2>&1; then
	echo "[ERREUR] Utilisateur introuvable: ${TARGET_USER}"
	exit 1
fi

if [[ ! -x "${CLI_BIN}" ]]; then
	echo "[ERREUR] CLI VS Code introuvable: ${CLI_BIN}"
	echo "[INFO] Lancez d'abord: sudo ./install_vscode.sh ${TARGET_USER}"
	exit 1
fi

HOME_DIR="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
if [[ -z "${HOME_DIR}" || ! -d "${HOME_DIR}" ]]; then
	echo "[ERREUR] Home introuvable pour ${TARGET_USER}"
	exit 1
fi

STATE_DIR="${HOME_DIR}/.vscode-tunnel"
PID_FILE="${STATE_DIR}/tunnel.pid"
LOG_FILE="${STATE_DIR}/tunnel.log"

run_as_user() {
	local cmd="$1"
	if [[ "$(id -un)" == "${TARGET_USER}" ]]; then
		bash -lc "$cmd"
		return
	fi

	if [[ "${EUID}" -ne 0 ]]; then
		echo "[ERREUR] Lancez ce script en root (sudo) ou avec l'utilisateur ${TARGET_USER}."
		exit 1
	fi

	runuser -u "${TARGET_USER}" -- bash -lc "$cmd"
}

run_as_user "mkdir -p '${STATE_DIR}'"

if [[ -f "${PID_FILE}" ]]; then
	EXISTING_PID="$(cat "${PID_FILE}" 2>/dev/null || true)"
	if [[ -n "${EXISTING_PID}" ]] && run_as_user "kill -0 ${EXISTING_PID} 2>/dev/null"; then
		echo "[INFO] Tunnel deja actif (PID ${EXISTING_PID})."
		echo "[INFO] Logs: ${LOG_FILE}"
		exit 0
	fi
	# PID obsolet: on nettoie avant de relancer.
	rm -f "${PID_FILE}"
fi

START_CMD="cd '${HOME_DIR}' && nohup '${CLI_BIN}' tunnel --accept-server-license-terms --name '${VSCODE_TUNNEL_NAME}' >> '${LOG_FILE}' 2>&1 & echo \$! > '${PID_FILE}'"
run_as_user "${START_CMD}"

sleep 2
NEW_PID="$(cat "${PID_FILE}" 2>/dev/null || true)"

if [[ -z "${NEW_PID}" ]] || ! run_as_user "kill -0 ${NEW_PID} 2>/dev/null"; then
	echo "[ERREUR] Echec du demarrage du tunnel."
	echo "[INFO] Consultez les logs: ${LOG_FILE}"
	exit 1
fi

echo "[OK] Tunnel VS Code demarre en arriere-plan."
echo "[INFO] Utilisateur : ${TARGET_USER}"
echo "[INFO] Nom tunnel : ${VSCODE_TUNNEL_NAME}"
echo "[INFO] PID       : ${NEW_PID}"
echo "[INFO] Logs      : ${LOG_FILE}"
echo ""
echo "[INFO] Pour suivre les logs :"
echo "[INFO]   tail -f '${LOG_FILE}'"
echo "[INFO] Pour arreter le tunnel :"
echo "[INFO]   kill '${NEW_PID}'"