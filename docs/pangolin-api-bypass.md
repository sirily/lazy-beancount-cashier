# Pangolin path bypass with Cashier API authentication

Cashier can keep the PWA UI behind Pangolin SSO while allowing `/api` requests
to bypass Pangolin authentication. The Cashier server then enforces its own
deployment-scoped bearer token.

## Required order

1. Deploy matching PWA and server versions that support the API token.
2. Generate a token with at least 32 random bytes:

   ```sh
   openssl rand -hex 32
   ```

3. Set that value as `CASHIER_API_TOKEN` in the deployment `.env` and recreate
   `cashier-server`.
4. In the installed PWA, open **Synchronization**, enter the same value in
   **API token**, and save it.
5. Verify authenticated API access before changing Pangolin:

   ```sh
   curl -fsS -H "Authorization: Bearer $CASHIER_API_TOKEN" \
     https://cashier.example.com/api/ping
   ```

6. In the Cashier Pangolin resource, add an authentication bypass only for the
   `/api` path prefix. Keep all other paths under SSO.

## Verification

After the bypass is active:

```sh
# Protected by the Cashier server: must return 401.
curl -i https://cashier.example.com/api/ping

# Valid token: must return 200 and "pong".
curl -i -H "Authorization: Bearer $CASHIER_API_TOKEN" \
  https://cashier.example.com/api/ping

# UI remains protected by Pangolin SSO.
curl -i https://cashier.example.com/
```

`/api/health` intentionally remains token-free for the container/reverse-proxy
health check and exposes only readiness booleans. Do not put the token in a URL,
Pangolin rule, image, repository, or logs. Rotate it by changing the server env
and PWA setting together.