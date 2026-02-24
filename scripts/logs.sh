#!/usr/bin/env bash
set -euo pipefail
SERVICE="${1:-}"
if [[ -z "$SERVICE" ]]; then
  echo "Usage: ./scripts/logs.sh <mi|icp|apim>"
  exit 1
fi

case "$SERVICE" in
  mi|icp|apim) ;;
  *)
    echo "Usage: ./scripts/logs.sh <mi|icp|apim>"
    exit 1
    ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source ./scripts/compose.sh
compose_cmd logs -f "$SERVICE"
