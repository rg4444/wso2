#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/env/.env"

# Load env/.env safely (only KEY=VALUE lines; ignore everything else)
set -a
# shellcheck disable=SC1090
. <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "${ENV_FILE}" | sed 's/\r$//')
set +a

if [[ "${ENABLE_APIM:-0}" != "1" ]]; then
  exit 0
fi

HOST="${APIM_PUBLIC_HOST:-10.0.0.5}"
PROTO="${APIM_UI_PROTOCOL:-http}"

# Pick port based on protocol (http->APIM_HTTP_PORT, https->APIM_HTTPS_PORT)
if [[ "${PROTO}" == "https" ]]; then
  PORT="${APIM_HTTPS_PORT:-9443}"
else
  PORT="${APIM_HTTP_PORT:-9763}"
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
  sed -i -E \
    -e "s/\"host\"[[:space:]]*:[[:space:]]*\"localhost\"/\"host\": \"${HOST}\"/g" \
    -e "s/\"host\"[[:space:]]*:[[:space:]]*\"127\.0\.0\.1\"/\"host\": \"${HOST}\"/g" \
    -e "s/\"protocol\"[[:space:]]*:[[:space:]]*\"https\"/\"protocol\": \"${PROTO}\"/g" \
    -e "s/\"protocol\"[[:space:]]*:[[:space:]]*\"http\"/\"protocol\": \"${PROTO}\"/g" \
    -e "s/\"port\"[[:space:]]*:[[:space:]]*9443/\"port\": ${PORT}/g" \
    -e "s/\"port\"[[:space:]]*:[[:space:]]*9763/\"port\": ${PORT}/g" \
    "${f}" || true
done
'
echo "[*] Portal settings patch complete."
