#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/env/.env"

ok() { echo "[OK] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERR] $*"; }

status=0

check_cmd() {
  local cmd="$1"
  if command -v "${cmd}" >/dev/null 2>&1; then
    ok "Found command: ${cmd}"
  else
    err "Missing command: ${cmd}"
    status=1
  fi
}

echo "[*] WSO2 Ubuntu/Docker preflight"
check_cmd docker
check_cmd awk
check_cmd rg

if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose plugin available"
  else
    err "Docker Compose plugin missing"
    status=1
  fi

  if docker info >/dev/null 2>&1; then
    ok "Docker daemon reachable"
  else
    err "Docker daemon not reachable for current user"
    status=1
  fi
fi

if [[ -f "${ENV_FILE}" ]]; then
  ok "Found env/.env"
else
  warn "env/.env not found (run ./scripts/install.sh first)"
fi

if command -v free >/dev/null 2>&1; then
  mem_mb="$(free -m | awk '/Mem:/ {print $2}')"
  if [[ -n "${mem_mb}" && "${mem_mb}" -lt 4096 ]]; then
    warn "System memory is ${mem_mb}MB; APIM may need >=4GB for stable startup"
  else
    ok "System memory looks sufficient (${mem_mb}MB)"
  fi
fi

exit "${status}"
