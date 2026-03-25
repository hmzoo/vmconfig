#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./options/install_node.sh [major_version]
# Example:
#   ./options/install_node.sh 22

NODE_MAJOR="${1:-22}"

if [[ "${EUID}" -ne 0 ]]; then
	SUDO="sudo"
else
	SUDO=""
fi

echo "[node] Installation des dependances"
${SUDO} apt-get update -y
${SUDO} apt-get install -y ca-certificates curl gnupg

echo "[node] Ajout du depot NodeSource (Node.js ${NODE_MAJOR}.x)"
${SUDO} install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | ${SUDO} gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
${SUDO} chmod a+r /etc/apt/keyrings/nodesource.gpg

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
	| ${SUDO} tee /etc/apt/sources.list.d/nodesource.list >/dev/null

echo "[node] Installation"
${SUDO} apt-get update -y
${SUDO} apt-get install -y nodejs

echo "[node] Verification"
node --version
npm --version
