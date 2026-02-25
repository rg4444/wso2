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


if [[ -f "${ENV_FILE}" ]]; then
  read_env_value() {
    local key="$1"
    local value
    value="$(grep -E "^[[:space:]]*${key}=" "${ENV_FILE}" | tail -n1 | sed -E "s/^[[:space:]]*${key}=//" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
    value="${value%\"}"
    value="${value#\"}"
    printf '%s' "${value}"
  }

  enable_apim="$(read_env_value ENABLE_APIM)"
  if [[ "${enable_apim:-0}" == "1" ]]; then
    apim_http_port="$(read_env_value APIM_HTTP_PORT)"
    if [[ -z "${apim_http_port}" ]]; then
      printf "\nAPIM_HTTP_PORT=9763\n" >> "${ENV_FILE}"
      echo "    Added APIM_HTTP_PORT=9763 (required when ENABLE_APIM=1)"
    fi

    apim_public_host="$(read_env_value APIM_PUBLIC_HOST)"
    if [[ -z "${apim_public_host}" ]]; then
      printf "\nAPIM_PUBLIC_HOST=10.0.0.5\n" >> "${ENV_FILE}"
      echo "    Added APIM_PUBLIC_HOST=10.0.0.5 (required when ENABLE_APIM=1)"
    fi

    apim_ui_protocol="$(read_env_value APIM_UI_PROTOCOL)"
    if [[ -z "${apim_ui_protocol}" ]]; then
      apim_ui_protocol="http"
      printf "\nAPIM_UI_PROTOCOL=%s\n" "${apim_ui_protocol}" >> "${ENV_FILE}"
      echo "    Added APIM_UI_PROTOCOL=${apim_ui_protocol} (required when ENABLE_APIM=1)"
    fi

    apim_ui_port="$(read_env_value APIM_UI_PORT)"
    if [[ -z "${apim_ui_port}" ]]; then
      if [[ "${apim_ui_protocol}" == "https" ]]; then
        apim_ui_port="9443"
      else
        apim_ui_port="9763"
      fi
      printf "\nAPIM_UI_PORT=%s\n" "${apim_ui_port}" >> "${ENV_FILE}"
      echo "    Added APIM_UI_PORT=${apim_ui_port} (required when ENABLE_APIM=1)"
    fi
  fi
fi

echo "[*] Done."
