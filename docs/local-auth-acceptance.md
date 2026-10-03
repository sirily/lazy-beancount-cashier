# Local container/browser auth acceptance

Tests exercise actual built PWA -> Caddy -> API; no API mocks.

## Build matching images

```sh
docker build -t cashier-auth-server:e2e /path/to/cashier-auth-server
docker build -t cashier-auth-pwa:e2e /path/to/cashier-auth-pwa
```

## Server acceptance

From server repository:

```sh
npm ci --prefix tests/acceptance --ignore-scripts
DOCKER_ACCEPTANCE=1 CASHIER_ACCEPTANCE_SKIP_BUILD=1 uv run --no-sync pytest tests -q
```

The suite creates uniquely named disposable containers, binds ephemeral localhost ports, passes a random runtime Bearer token and cleans up its own containers. The retained image is `cashier-auth-server:e2e`. Without skip-build, it builds this image first. Do not use `--no-sync` on a fresh environment: install the locked Python dependencies first.

## Browser/stack evidence for current local run

- Isolated Compose: `/home/claw/tmp/cashier-auth-e2e/docker-compose.yml`
- URL: `http://127.0.0.1:8788`
- Synthetic ledger only; `/workspace` read-only and fixed manual_transactions.bean bind writable.
- Browser report: `/home/claw/tmp/cashier-auth-e2e/browser-e2e-report.json`
- Overall verification: `/home/claw/tmp/cashier-auth-e2e/verification-summary.md`

Expected scenarios: empty/wrong token rejected; correct token downloads ledger and parses with zero errors; token persists after reload; completed transaction created through visible UI is sent/pulled/reconciled; unauthorized sync retains local transaction and does not mutate server; retry never duplicates it.

These checks do not validate production Pangolin path bypass. Enable that only after matching images and configured runtime token have been deployed and authenticated smoke checks pass. UI remains under SSO.
