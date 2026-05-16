#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-}"

if [[ -z "$BASE_URL" ]]; then
  echo "Usage: $0 http://127.0.0.1:8080" >&2
  exit 1
fi

BASE_URL="${BASE_URL%/}"

check() {
  local path="$1"
  echo "Checking ${BASE_URL}${path}"
  curl -fsS --max-time 20 "${BASE_URL}${path}" >/dev/null
}

check "/"
check "/api/ping"
check "/api/health"

check "/api/infrastructure?file_path=main.bean"
check "/api?query=accounts"

echo "Smoke tests passed for ${BASE_URL}"
