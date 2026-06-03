# Deploy

This is the deployment runbook for the Cashier stack, including Stage 1 read-only sync and the Stage 2 single-file manual transaction writeback channel.

## Requirements

- Docker Engine with the Docker Compose v2 plugin.
- External Docker network may be used for a reverse proxy if needed.
- Published images:
  - `ghcr.io/sirily/cashier-sveltekit:${PWA_VERSION:-latest}`
  - `ghcr.io/sirily/cashier-server-python:${SERVER_VERSION:-latest}`
- Beancount file on the host:
  - `/absolute/path/to/main.bean` (replace with your real host directory)
- The `cashier-caddy` service is reachable at the host address/port defined by `CASHIER_HTTP_BIND` (default 127.0.0.1:8080).

## Configure

```sh
cp .env.example .env
$EDITOR .env
```

Important values:

```env
HOST_BEANCOUNT_WORKSPACE=/tmp/cashier-beancount-workspace
HOST_BEANCOUNT_MANUAL_TRANSACTIONS_FILE=/tmp/cashier-beancount-workspace/manual_transactions.bean
PWA_VERSION=sha-abcdef1234567890
SERVER_VERSION=sha-123456abcdef7890
CASHIER_HTTP_BIND=127.0.0.1:8080
CASHIER_CORS_ORIGINS=
```

Set `HOST_BEANCOUNT_WORKSPACE` to the absolute host directory of your main Beancount file. Set `HOST_BEANCOUNT_MANUAL_TRANSACTIONS_FILE` to the one writable manual transaction file included by `main.bean`. Set `CASHIER_HTTP_BIND` to the host address and port Caddy should publish. Use `sha-*` image tags for `PWA_VERSION` and `SERVER_VERSION` when available.

For Stage 2 writeback, create the manual transactions file before deploying and make it writable by the server container runtime user. The current `cashier-server-python` image runs as uid/gid `999:999`:

```sh
touch "$HOST_BEANCOUNT_MANUAL_TRANSACTIONS_FILE"
chown 999:999 "$HOST_BEANCOUNT_MANUAL_TRANSACTIONS_FILE"
chmod 664 "$HOST_BEANCOUNT_MANUAL_TRANSACTIONS_FILE"
```

Do not change the full Beancount workspace mount to read-write. Only `manual_transactions.bean` is writable.

## Validate Compose

```sh
docker compose --env-file .env config
```

## Deploy

```sh
docker compose --env-file .env pull
docker compose --env-file .env up -d --remove-orphans
docker compose --env-file .env ps
```

Or use:

```sh
./scripts/deploy.sh
```

## Smoke tests

Smoke tests:

```sh
./scripts/smoke.sh "http://127.0.0.1:8080"
```

The script checks:

- `/`
- `/api/ping`
- `/api/health`

- `/api/infrastructure?file_path=main.bean`
- `/api?query=accounts`

Manual checks:

```sh
curl -fsS "http://127.0.0.1:8080/" >/dev/null
curl -fsS "http://127.0.0.1:8080/api/ping"
curl -fsS "http://127.0.0.1:8080/api/health"
curl -fsS "http://127.0.0.1:8080/api/infrastructure?file_path=main.bean" >/dev/null
curl -fsS "http://127.0.0.1:8080/api?query=accounts" >/dev/null
```

## Internal checks

```sh
docker compose --env-file .env exec cashier-caddy caddy validate --config /etc/caddy/Caddyfile

docker compose --env-file .env exec cashier-caddy \
  wget -qO- http://cashier-server:3000/health

docker compose --env-file .env exec cashier-server \
  sh -lc 'test -f /workspace && echo ok'
```

## Stage 1 read-only guardrails

Keep these invariants until write-back is explicitly designed:

```yaml
volumes:
  - ${HOST_BEANCOUNT_WORKSPACE}:/workspace:ro
```

```env
BEANCOUNT_FILE=/workspace
CASHIER_ENABLE_SHUTDOWN=false
```

Do not add server-side append endpoints, `POST /xact`, `manual_transactions` write-back, or a read-write `/workspace` mount in this repository during stage 1.
