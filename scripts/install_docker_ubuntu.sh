#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "[!] This script requires root (or sudo)."
    exit 1
  fi
else
  SUDO=""
fi

export DEBIAN_FRONTEND=noninteractive

echo "[*] Installing Docker Engine + Compose plugin on Ubuntu..."
${SUDO} apt-get update
${SUDO} apt-get install -y ca-certificates curl gnupg lsb-release

${SUDO} install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO} gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
${SUDO} chmod a+r /etc/apt/keyrings/docker.gpg

CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
  | ${SUDO} tee /etc/apt/sources.list.d/docker.list >/dev/null

${SUDO} apt-get update
${SUDO} apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
${SUDO} systemctl enable --now docker

if id -nG "${USER}" | tr ' ' '\n' | rg -qx docker; then
  echo "[*] User '${USER}' is already in docker group."
else
  ${SUDO} usermod -aG docker "${USER}" || true
  echo "[*] Added user '${USER}' to docker group. Log out and back in (or run: newgrp docker)."
fi

echo "[*] Docker installation complete."
docker --version || true
docker compose version || true
