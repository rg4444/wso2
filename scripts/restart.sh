#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source ./scripts/compose.sh

ENV_FILE="${ROOT_DIR}/env/.env"
if [[ -z "${APIM_PUBLIC_HOST:-}" && -f "${ENV_FILE}" ]]; then
  APIM_PUBLIC_HOST="$(awk -F= '$1=="APIM_PUBLIC_HOST"{v=$0} END{sub(/^[^=]*=/,"",v); print v}' "${ENV_FILE}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/^\"//" -e "s/\"$//")"
fi

if [[ -z "${APIM_PUBLIC_HOST:-}" ]]; then
  echo "[!] APIM_PUBLIC_HOST is not set. Put it in env/.env (e.g., APIM_PUBLIC_HOST=apim.local)."
  exit 2
fi

APIM_UI_BASE_URL="https://${APIM_PUBLIC_HOST}:9443"


handle_stop_error() {
  local output="$1"
  if [[ "${output}" == *"permission denied"* ]]; then
    docker_bin="$(command -v docker || true)"
    echo "[!] Docker reported a permission-denied error while stopping containers."
    if [[ "${docker_bin}" == /snap/bin/* ]]; then
      echo "    Detected snap Docker CLI at ${docker_bin}."
      echo "    Cure:"
      echo "      sudo snap remove docker"
      echo "      ./scripts/install_docker_ubuntu.sh"
      echo "      newgrp docker"
    else
      echo "    Common cures:"
      echo "      - Ensure docker daemon is healthy: sudo systemctl restart docker"
      echo "      - Ensure current user can access docker: groups ${USER}"
      echo "      - If needed re-add docker group: sudo usermod -aG docker ${USER} && newgrp docker"
    fi
  fi
}

down_output=""
if ! down_output="$(compose_cmd down 2>&1)"; then
  printf '%s\n' "${down_output}"
  handle_stop_error "${down_output}"
  exit 1
fi
printf '%s\n' "${down_output}"

compose_cmd up -d
compose_cmd ps

# Patch portals to use configured APIM UI base URL
APIM_UI_BASE_URL="${APIM_UI_BASE_URL}" ./scripts/apim_portals_patch.sh
