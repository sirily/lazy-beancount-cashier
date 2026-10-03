#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-}"
API_TOKEN="${CASHIER_API_TOKEN:-}"

if [[ -z "$BASE_URL" || -z "$API_TOKEN" ]]; then
  echo "Usage: CASHIER_API_TOKEN=<token> $0 http://127.0.0.1:8080" >&2
  exit 1
fi

BASE_URL="${BASE_URL%/}"

check_public() {
  local path="$1"
  echo "Checking ${BASE_URL}${path}"
  curl -fsS --max-time 20 "${BASE_URL}${path}" >/dev/null
}

check_api() {
  local path="$1"
  echo "Checking authenticated ${BASE_URL}${path}"
  curl -fsS --max-time 20 -H "Authorization: Bearer ${API_TOKEN}" \
    "${BASE_URL}${path}" >/dev/null
}

check_public "/"
check_public "/api/health"

echo "Checking tokenless API rejection"
status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "${BASE_URL}/api/ping")"
if [[ "$status" != "401" ]]; then
  echo "Expected tokenless /api/ping to return 401, got ${status}" >&2
  exit 1
fi

check_api "/api/ping"
check_api "/api/infrastructure?file_path=main.bean"
check_api "/api?query=SELECT%20account%20FROM%20accounts"

echo "Smoke tests passed for ${BASE_URL}"
