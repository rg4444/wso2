#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[*] Preparing env file..."
mkdir -p "${ROOT_DIR}/env"
if [[ ! -f "${ROOT_DIR}/env/.env" ]]; then
  cp "${ROOT_DIR}/env/.env.example" "${ROOT_DIR}/env/.env"
  echo "    Created env/.env from env/.env.example (edit if needed)"
else
  echo "    env/.env already exists"
fi

echo "[*] Done."
