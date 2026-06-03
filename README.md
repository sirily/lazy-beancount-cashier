# lazy-beancount-cashier

Deployment repository for the self-hosted Cashier stack.

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

## Stage 1 and Stage 2 scope

Stage 1 is read-only offline-ledger sync:

- use existing server endpoints: `/`, `/ping`, `/health`, `/reload`, `/infrastructure?file_path=...`;
- mount the Beancount workspace read-only: `${HOST_BEANCOUNT_WORKSPACE}:/workspace:ro`;
- set `BEANCOUNT_FILE=/workspace/main.bean`.

Stage 2 adds exactly one narrow writeback channel for PWA-created manual transactions:

- expose the server `POST /xact` endpoint through Caddy as `/api/xact`;
- keep the full Beancount workspace read-only;
- bind-mount only the configured manual transactions file read-write:
  `${HOST_BEANCOUNT_MANUAL_TRANSACTIONS_FILE}:/workspace/manual_transactions.bean:rw`;
- set `BEANCOUNT_MANUAL_TRANSACTIONS_FILE=/workspace/manual_transactions.bean`;
- ensure `main.bean` includes `manual_transactions.bean` exactly once;
- ensure the mounted file is writable by the server container runtime user. The current `cashier-server-python` image runs as uid/gid `999:999`.

Do **not** mount the whole `/workspace` read-write. Stage 2 is not a general Beancount mutation API; only the single manual transactions file is writable.

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
