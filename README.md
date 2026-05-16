# lazy-beancount-cashier

Deployment repository for the self-hosted Cashier stage-1 stack.

This repository does **not** build Cashier application code. It wires together the two prebuilt images:

- `ghcr.io/sirily/cashier-sveltekit:latest` — Cashier PWA/static web app
- `ghcr.io/sirily/cashier-server-python:latest` — Cashier read/sync API for Beancount

## Architecture

```text
[phone / Cashier PWA]
   ↓ HTTPS + auth cookie
[Pangolin → Traefik]
   ↓
[cashier-caddy]
   ├── /api/* → cashier-server:3000
   └── /*      → cashier-pwa:8080
```

The server reads the full Lazy Beancount book from:

```text
/mnt/raid4t/homelab/appdata/lazybean/main.bean
```

inside the container as:

```text
/workspace/main.bean
```

## Stage 1 scope

Stage 1 is intentionally **read-only sync**:

- use existing server endpoints: `/`, `/ping`, `/health`, `/reload`, `/infrastructure?file_path=...`;
- mount Lazy Beancount as read-only: `:/workspace:ro`;
- set `BEANCOUNT_FILE=/workspace/main.bean`;
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
# edit CASHIER_HOST if needed

docker compose --env-file .env config
docker compose --env-file .env pull
docker compose --env-file .env up -d
```

Run smoke tests:

```sh
./scripts/smoke.sh "https://cashier.example.com"
```

For local checks against a published port or tunnel, pass the corresponding base URL.

## Cashier PWA setting

In the PWA, set the sync server URL to the absolute API URL:

```text
https://cashier.example.com/api
```

Using a relative `/api` URL is not assumed to work in stage 1 because the current PWA code builds URLs from the configured server URL.
