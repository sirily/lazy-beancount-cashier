# Deploy

This is the deployment runbook for the read-only Cashier stage-1 stack.

## Requirements

- Docker Engine with the Docker Compose v2 plugin.
- External Docker network used by Pangolin/Traefik, default: `traefik`.
- Published images:
  - `ghcr.io/sirily/cashier-sveltekit:latest`
  - `ghcr.io/sirily/cashier-server-python:latest`
- Lazy Beancount data on the host:
  - `/absolute/path/to/lazybean/main.bean` (replace with your real host path)
- Pangolin/Traefik route for `CASHIER_HOST` to the `cashier-caddy` service.

## Configure

```sh
cp .env.example .env
$EDITOR .env
```

Important values:

```env
CASHIER_HOST=cashier.example.com
LAZYBEAN_PATH=/absolute/path/to/lazybean
BEANCOUNT_FILE=/workspace/main.bean
CASHIER_ENABLE_SHUTDOWN=false
```

Set `LAZYBEAN_PATH` to the host directory containing your Beancount files (e.g. where `main.bean` is located).

Do not change the Lazy Beancount mount to read-write in stage 1.

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

External smoke tests:

```sh
./scripts/smoke.sh "https://cashier.example.com"
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
curl -fsS "https://cashier.example.com/" >/dev/null
curl -fsS "https://cashier.example.com/api/ping"
curl -fsS "https://cashier.example.com/api/health"
curl -fsS "https://cashier.example.com/api/reload"
curl -fsS "https://cashier.example.com/api/infrastructure?file_path=main.bean" >/dev/null
curl -fsS "https://cashier.example.com/api?query=accounts" >/dev/null
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
  - ${LAZYBEAN_PATH}:/workspace:ro
```

```env
BEANCOUNT_FILE=/workspace/main.bean
CASHIER_ENABLE_SHUTDOWN=false
```

Do not add server-side append endpoints, `POST /xact`, `manual_transactions` write-back, or a read-write `/workspace` mount in this repository during stage 1.
