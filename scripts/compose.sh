#!/usr/bin/env bash

compose_cmd() {
  local root_dir env_file enable_apim
  root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  env_file="${root_dir}/env/.env"

  local compose_args=( -f "${root_dir}/docker-compose.yml" )

  enable_apim="$(awk -F= '/^[[:space:]]*ENABLE_APIM=/{print $2; exit}' "${env_file}" 2>/dev/null | tr -d '[:space:]')"
  if [[ "${enable_apim}" == "1" && -f "${root_dir}/docker-compose.apim.yml" ]]; then
    compose_args+=( -f "${root_dir}/docker-compose.apim.yml" )
  fi

  docker compose "${compose_args[@]}" --env-file "${env_file}" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  compose_cmd "$@"
fi
