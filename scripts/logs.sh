#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ENV_FILE="${ENV_FILE:-.env}"
SERVICE="${1:-}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Copy .env.example to .env and edit it first." >&2
  exit 1
fi

if [[ -n "$SERVICE" ]]; then
  docker compose --env-file "$ENV_FILE" logs -f --tail=200 "$SERVICE"
else
  docker compose --env-file "$ENV_FILE" logs -f --tail=200 cashier-caddy cashier-pwa cashier-server
fi
