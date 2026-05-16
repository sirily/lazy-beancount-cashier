# Operations

## Pull and restart

```sh
docker compose --env-file .env pull
docker compose --env-file .env up -d --remove-orphans
```

## Service status

```sh
docker compose --env-file .env ps
```

## Logs

```sh
docker compose --env-file .env logs -f cashier-caddy
docker compose --env-file .env logs -f cashier-pwa
docker compose --env-file .env logs -f cashier-server
```

Or:

```sh
./scripts/logs.sh
./scripts/logs.sh cashier-server
```

## Restart one service

```sh
docker compose --env-file .env restart cashier-server
docker compose --env-file .env restart cashier-pwa
docker compose --env-file .env restart cashier-caddy
```

## Validate Caddy config

```sh
docker compose --env-file .env exec cashier-caddy \
  caddy validate --config /etc/caddy/Caddyfile
```

## Verify server health from inside the stack

```sh
docker compose --env-file .env exec cashier-caddy \
  wget -qO- http://cashier-server:3000/ping

docker compose --env-file .env exec cashier-caddy \
  wget -qO- http://cashier-server:3000/health
```

## Verify Beancount mount

```sh
docker compose --env-file .env exec cashier-server \
  sh -lc 'id && ls -lah /workspace && test -f /workspace/main.bean && echo main.bean found'
```

The mount must remain read-only in stage 1:

```sh
docker compose --env-file .env exec cashier-server \
  sh -lc 'touch /workspace/.write-test 2>/dev/null && echo "ERROR: writable" || echo "OK: read-only"'
```

## Roll back image versions

Pin image tags in `docker-compose.yml` and redeploy:

```sh
./scripts/deploy.sh
```

## Stage 2 reminder

Do not enable write-back by operational workaround. The future write-back stage needs an explicit implementation plan:

- understand the current PWA save/push flow;
- design a server append endpoint or export/import flow;
- mount only the required target as writable;
- append only to `manual_transactions...`;
- validate with `bean-check /workspace/main.bean`;
- rollback on validation failure.
