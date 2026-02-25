#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/env/.env"

# Read a single KEY from env/.env without "sourcing" it.
# This avoids failures when values contain spaces and are not quoted (e.g. JVM opts).
get_env() {
  local key="$1"
  local default="${2:-}"
  local val

  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "${default}"
    return 0
  fi

  # Grab everything after the first '=' for the *last* matching key (later lines win)
  val="$(awk -F= -v k="${key}" '
    $1==k {
      $1=""; sub(/^=/,""); v=$0
    }
    END { print v }
  ' "${ENV_FILE}" | sed 's/\r$//' )"

  # Trim whitespace
  val="$(printf "%s" "${val}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  # Strip surrounding quotes if present
  if [[ "${val}" =~ ^".*"$ ]]; then
    val="${val:1:${#val}-2}"
  elif [[ "${val}" =~ ^\'.*\'$ ]]; then
    val="${val:1:${#val}-2}"
  fi

  if [[ -z "${val}" ]]; then
    echo "${default}"
  else
    echo "${val}"
  fi
}

ENABLE_APIM="$(get_env ENABLE_APIM 0)"
if [[ "${ENABLE_APIM}" != "1" ]]; then
  exit 0
fi

HOST="$(get_env APIM_PUBLIC_HOST 10.0.0.5)"
PROTO="$(get_env APIM_UI_PROTOCOL http)"

UI_PORT="$(get_env APIM_UI_PORT)"
if [[ -n "${UI_PORT}" ]]; then
  PORT="${UI_PORT}"
elif [[ "${PROTO}" == "https" ]]; then
  PORT="$(get_env APIM_HTTPS_PORT 9443)"
else
  PORT="$(get_env APIM_HTTP_PORT 9763)"
fi

echo "[*] Patching APIM portal settings.json to ${PROTO}://${HOST}:${PORT} ..."

# Find the 3 portal config files dynamically (version-safe)
docker exec -i apim bash -lc '
set -euo pipefail
HOST="'"${HOST}"'"
PORT="'"${PORT}"'"
PROTO="'"${PROTO}"'"

files="$(find /home/wso2carbon -type f -name settings.json 2>/dev/null | egrep "/webapps/(publisher|devportal|admin)/" || true)"
if [[ -z "${files}" ]]; then
  echo "No settings.json files found yet (APIM may still be starting)."
  exit 0
fi

for f in ${files}; do
  echo "  - Updating ${f}"
  sed -i -E     -e "s/\"host\"[[:space:]]*:[[:space:]]*\"localhost\"/\"host\": \"${HOST}\"/g"     -e "s/\"host\"[[:space:]]*:[[:space:]]*\"127\.0\.0\.1\"/\"host\": \"${HOST}\"/g"     -e "s/\"protocol\"[[:space:]]*:[[:space:]]*\"https\"/\"protocol\": \"${PROTO}\"/g"     -e "s/\"protocol\"[[:space:]]*:[[:space:]]*\"http\"/\"protocol\": \"${PROTO}\"/g"     -e "s/\"port\"[[:space:]]*:[[:space:]]*9443/\"port\": ${PORT}/g"     -e "s/\"port\"[[:space:]]*:[[:space:]]*9763/\"port\": ${PORT}/g"     "${f}" || true
done
'
echo "[*] Portal settings patch complete."
