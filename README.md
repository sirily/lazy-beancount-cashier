# lazy-beancount-cashier

Deployment repository for the self-hosted Cashier stage-1 stack.

This repository does **not** build Cashier application code. It wires together the two prebuilt images:

- `ghcr.io/sirily/cashier-sveltekit:latest` — Cashier PWA/static web app
- `ghcr.io/sirily/cashier-server-python:latest` — Cashier read/sync API for Beancount

## Architecture

```text
[phone / Cashier PWA]
   ↓
[host port from CASHIER_HTTP_BIND]
   ↓
[cashier-caddy]
   ├── /api/* → cashier-server:3000
   └── /*      → cashier-pwa:8080
```

The server reads the full Beancount workspace from the host directory set by `HOST_BEANCOUNT_WORKSPACE` in `.env`, mounted inside the container as:

```text
/workspace
```

## Stage 1 scope

Stage 1 is intentionally **read-only sync**:

- use existing server endpoints: `/`, `/ping`, `/health`, `/reload`, `/infrastructure?file_path=...`;
- mount the Beancount file read-only: `${HOST_BEANCOUNT_WORKSPACE}:/workspace:ro`;
- set `BEANCOUNT_FILE=/workspace`;
- do **not** add `POST /xact`;
- do **not** write to `manual_transactions`;
- do **not** mount `/workspace` read-write.

Phone-created/offline transactions and server-side write-back belong to a later stage after the PWA sync/offline flow is validated.

## Files

- `docker-compose.yml` — Caddy + PWA + server runtime stack
- `Caddyfile` — routes `/api*` to the server and everything else to the PWA
- `.env.example` — deployment settings
- `scripts/deploy.sh` — pull and start the stack
- `scripts/smoke.sh` — HTTP smoke tests
- `scripts/logs.sh` — follow service logs
- `docs/deploy.md` — deployment runbook
- `docs/phone-setup.md` — PWA setup and offline test
- `docs/operations.md` — common operations

## Quick start

```sh
cp .env.example .env
# edit HOST_BEANCOUNT_WORKSPACE and optionally CASHIER_HTTP_BIND

docker compose --env-file .env config
docker compose --env-file .env pull
docker compose --env-file .env up -d
```

Run smoke tests:

```sh
./scripts/smoke.sh "http://127.0.0.1:8080"
```

For checks against another published address or tunnel, pass the corresponding base URL.

## Cashier PWA setting

In the PWA, set the sync server URL to the absolute API URL:

```text
https://cashier.example.com/api
```

Using a relative `/api` URL is not assumed to work in stage 1 because the current PWA code builds URLs from the configured server URL.
