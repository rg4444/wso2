#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[*] Preparing env file..."
mkdir -p "${ROOT_DIR}/env"
ENV_FILE="${ROOT_DIR}/env/.env"
ENV_EXAMPLE_FILE="${ROOT_DIR}/env/.env.example"

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${ENV_EXAMPLE_FILE}" "${ENV_FILE}"
  echo "    Created env/.env from env/.env.example (edit if needed)"
else
  echo "    env/.env already exists, syncing missing variables from env/.env.example"

  # shellcheck disable=SC2016
  awk '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    {
      line = $0
      sub(/^[[:space:]]*export[[:space:]]+/, "", line)
      if (match(line, /^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=/, m)) {
        print m[1]
      }
    }
  ' "${ENV_FILE}" > "${ROOT_DIR}/env/.env.keys"

  appended_count=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue

    clean_line="${line#${line%%[![:space:]]*}}"
    clean_line="${clean_line#export }"

    if [[ "$clean_line" =~ ^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*= ]]; then
      key="${BASH_REMATCH[1]}"
      if ! rg -qx --fixed-strings "$key" "${ROOT_DIR}/env/.env.keys"; then
        printf '\n%s\n' "$line" >> "${ENV_FILE}"
        printf '%s\n' "$key" >> "${ROOT_DIR}/env/.env.keys"
        appended_count=$((appended_count + 1))
      fi
    fi
  done < "${ENV_EXAMPLE_FILE}"

  rm -f "${ROOT_DIR}/env/.env.keys"
  echo "    Added ${appended_count} missing variable(s) to env/.env"
fi

echo "[*] Done."
