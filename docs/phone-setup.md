# Phone setup

Use this document to validate the stage-1 goal: Cashier PWA can sync from the self-hosted server and remain useful offline on the phone.

## Install PWA

1. Open the public Cashier URL on the phone:

   ```text
   https://cashier.example.com
   ```

2. Install it as a PWA from the browser menu.
3. Open the installed PWA.

## Configure sync server

Set the Cashier sync server URL to the absolute API URL:

```text
https://cashier.example.com/api
```

Do not rely on a relative `/api` URL in stage 1.

## Online sync test

1. Confirm that the phone is online.
2. Run Cashier sync.
3. Confirm that accounts/balances/register data load from the Beancount book.
4. If sync fails, check:

   ```sh
   curl -fsS "https://cashier.example.com/api/ping"
   curl -fsS "https://cashier.example.com/api/health"
   curl -fsS "https://cashier.example.com/api?query=accounts"
   ```

## Offline test

1. Complete a successful online sync first.
2. Enable airplane mode or otherwise remove network access.
3. Close and reopen the installed PWA.
4. Confirm that previously synced data is still available.
5. Create any local/offline test entry only if the UI supports it, but do not expect it to be written back to the homelab Beancount files in stage 1.
6. Restore network and confirm the PWA can sync again.

## What stage 1 does not prove

Stage 1 does not prove server-side write-back. In particular, it does not append phone-created transactions to:

```text
/mnt/raid4t/homelab/appdata/lazybean/manual_transactions...
```

That is stage 2 and requires a separate design for append, validation, rollback, and conflict handling.
