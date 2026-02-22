#!/usr/bin/env bash
set -euo pipefail
SERVICE="${1:-}"
if [[ -z "$SERVICE" ]]; then
  echo "Usage: ./scripts/logs.sh <mi|icp>"
  exit 1
fi
docker logs -f "$SERVICE"
