#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source ./scripts/compose.sh
compose_cmd down
compose_cmd up -d
compose_cmd ps

# Patch portals to use HTTP/LAN host (avoid TLS SAN/IP issue)
./scripts/apim_portals_patch.sh
