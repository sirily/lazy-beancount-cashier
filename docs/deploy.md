# Deploy

This is the deployment runbook for the read-only Cashier stage-1 stack.

## Requirements

- Docker Engine with the Docker Compose v2 plugin.
- External Docker network may be used for a reverse proxy if needed.
- Published images:
  - `ghcr.io/sirily/cashier-sveltekit:latest`
  - `ghcr.io/sirily/cashier-server-python:latest`
- Beancount file on the host:
  - `/absolute/path/to/main.bean` (replace with your real host path)
- The `cashier-caddy` service is reachable at the host address/port defined by `CASHIER_HTTP_BIND` (default 127.0.0.1:8080).

## Configure

```sh
cp .env.example .env
$EDITOR .env
```

Important values:

```env
HOST_BEANCOUNT_FILE=/absolute/path/to/main.bean
CASHIER_HTTP_BIND=127.0.0.1:8080
CASHIER_CORS_ORIGINS=
```

Set `HOST_BEANCOUNT_FILE` to the absolute host path of your main Beancount file. Set `CASHIER_HTTP_BIND` to the host address and port Caddy should publish.

Do not change the Beancount mount to read-write in stage 1.

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
- `/api/reload`
- `/api/infrastructure?file_path=main.bean`
- `/api?query=accounts`

Manual checks:

```sh
curl -fsS "http://127.0.0.1:8080/" >/dev/null
curl -fsS "http://127.0.0.1:8080/api/ping"
curl -fsS "http://127.0.0.1:8080/api/health"
curl -fsS "http://127.0.0.1:8080/api/reload"
curl -fsS "http://127.0.0.1:8080/api/infrastructure?file_path=main.bean" >/dev/null
curl -fsS "http://127.0.0.1:8080/api?query=accounts" >/dev/null
```

## Internal checks

```sh
docker compose --env-file .env exec cashier-caddy caddy validate --config /etc/caddy/Caddyfile

docker compose --env-file .env exec cashier-caddy \
  wget -qO- http://cashier-server:3000/health

docker compose --env-file .env exec cashier-server \
  sh -lc 'test -f /workspace/main.bean && echo ok'
```

## Stage 1 read-only guardrails

Keep these invariants until write-back is explicitly designed:

```yaml
volumes:
  - ${HOST_BEANCOUNT_FILE}:/workspace/main.bean:ro
```

```env
BEANCOUNT_FILE=/workspace/main.bean
CASHIER_ENABLE_SHUTDOWN=false
```

Do not add server-side append endpoints, `POST /xact`, `manual_transactions` write-back, or a read-write `/workspace` mount in this repository during stage 1.
