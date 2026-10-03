# Phone setup

Use this document to validate the stage-1 goal: Cashier PWA can sync from the self-hosted server and remain useful offline on the phone.

## Install PWA

1. Open the public Cashier URL on the phone:

   ```text
    http://127.0.0.1:8080
   ```

2. Install it as a PWA from the browser menu.
3. Open the installed PWA.

## Configure sync server

Set the Cashier sync server URL to the absolute API URL:

```text
http://127.0.0.1:8080/api
```

Do not rely on a relative `/api` URL in stage 1.

Enter the value of `CASHIER_API_TOKEN` from the deployment `.env` in the
**API token** field. The PWA stores it in its local IndexedDB settings and sends
it as an `Authorization: Bearer …` header on Cashier API requests. The token is
excluded from Cashier settings backups.

## Online sync test

1. Confirm that the phone is online.
2. Run Cashier sync.
3. Confirm that accounts/balances/register data load from the Beancount book.
4. If sync fails, check:

   ```sh
curl -fsS -H "Authorization: Bearer $CASHIER_API_TOKEN" "http://127.0.0.1:8080/api/ping"
curl -fsS "http://127.0.0.1:8080/api/health"
curl -fsS -H "Authorization: Bearer $CASHIER_API_TOKEN" "http://127.0.0.1:8080/api?query=SELECT%20account%20FROM%20accounts"
   ```

## Offline test

1. Complete a successful online sync first.
2. Enable airplane mode or otherwise remove network access.
3. Close and reopen the installed PWA.
4. Confirm that previously synced data is still available.
5. Create any local/offline test entry only if the UI supports it, but do not expect it to be written back to the homelab Beancount files in stage 1.
6. Restore network and confirm the PWA can sync again.

## What stage 1 does not prove

Stage 1 does not prove server-side write-back.

That is stage 2 and requires a separate design for append, validation, rollback, and conflict handling.
