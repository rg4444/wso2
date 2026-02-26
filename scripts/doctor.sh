#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/env/.env"

ok() { echo "[OK] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERR] $*"; }

status=0

default_iface=""

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
check_cmd ip

if command -v ip >/dev/null 2>&1; then
  default_iface="$(ip route show default 2>/dev/null | awk 'NR==1 {print $5}')"
  if [[ -n "${default_iface}" ]]; then
    ok "Detected default interface: ${default_iface}"
  else
    warn "Could not detect default interface (routing looks unusual)"
  fi

  if [[ -n "${default_iface}" ]]; then
    ipv4_count="$(ip -4 -o addr show dev "${default_iface}" 2>/dev/null | awk 'END {print NR+0}')"
    if [[ "${ipv4_count}" -gt 1 ]]; then
      warn "${default_iface} has ${ipv4_count} IPv4 addresses; this may cause asymmetric routing and remote TCP timeouts"
      ip -4 -o addr show dev "${default_iface}" | awk '{print "      - " $4}'
      status=1
    else
      ok "${default_iface} has a single primary IPv4 address"
    fi
  fi
fi

if command -v docker >/dev/null 2>&1; then
  docker_bin="$(command -v docker || true)"
  if [[ "${docker_bin}" == /snap/bin/* ]]; then
    warn "Docker CLI comes from snap (${docker_bin}); snap docker commonly causes container stop/start permission issues"
    warn "Recommended: remove snap docker and reinstall using ./scripts/install_docker_ubuntu.sh"
  else
    ok "Docker CLI path: ${docker_bin}"
  fi

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

if [[ -r /proc/sys/net/ipv4/conf/all/rp_filter ]]; then
  rp_all="$(cat /proc/sys/net/ipv4/conf/all/rp_filter)"
  if [[ "${rp_all}" != "0" ]]; then
    warn "net.ipv4.conf.all.rp_filter=${rp_all}; strict reverse-path filtering can drop valid LAN traffic"
  else
    ok "net.ipv4.conf.all.rp_filter=0"
  fi
fi

if [[ -n "${default_iface}" && -r "/proc/sys/net/ipv4/conf/${default_iface}/rp_filter" ]]; then
  rp_iface="$(cat "/proc/sys/net/ipv4/conf/${default_iface}/rp_filter")"
  if [[ "${rp_iface}" != "0" ]]; then
    warn "net.ipv4.conf.${default_iface}.rp_filter=${rp_iface}; recommend setting to 0 for multi-network Docker hosts"
  else
    ok "net.ipv4.conf.${default_iface}.rp_filter=0"
  fi
fi

if command -v iptables >/dev/null 2>&1; then
  input_policy="$(iptables -S 2>/dev/null | awk '/^-P INPUT / {print $3; exit}')"
  if [[ "${input_policy:-}" == "DROP" || "${input_policy:-}" == "REJECT" ]]; then
    warn "iptables INPUT policy is ${input_policy}; ensure WSO2 ports are explicitly allowed from your LAN"
  elif [[ -n "${input_policy:-}" ]]; then
    ok "iptables INPUT policy is ${input_policy}"
  fi
fi

if [[ -f "${ENV_FILE}" ]]; then
  ok "Found env/.env"

  missing_env=0
  for required_key in WSO2_ICP_IMAGE WSO2_MI_IMAGE WSO2_APIM_IMAGE APIM_PUBLIC_HOST; do
    if ! rg -q "^[[:space:]]*${required_key}=" "${ENV_FILE}"; then
      warn "env/.env missing required key: ${required_key}"
      missing_env=1
    fi
  done

  if [[ "${missing_env}" -eq 0 ]]; then
    ok "env/.env contains required image/host keys"
  else
    status=1
  fi
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
