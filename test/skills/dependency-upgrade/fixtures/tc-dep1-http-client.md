# Upgrade request: quillfetch 3.4.2 → 4.1.0

Renovate opened a PR bumping `quillfetch`, our HTTP client, to the latest
release. Nothing is broken today; the team wants to know whether to merge it.

## Manifest (package.json)

```json
{
  "name": "orderdesk-api",
  "engines": { "node": ">=20" },
  "dependencies": {
    "quillfetch": "^3.4.2"
  }
}
```

Renovate's change:

```diff
-    "quillfetch": "^3.4.2"
+    "quillfetch": "^4.1.0"
```

## How the project uses quillfetch

These are all of the call sites.

`src/clients/inventory.js`

```js
import { createClient } from "quillfetch";

export const inventory = createClient({
  baseUrl: process.env.INVENTORY_URL,
  timeout: 5000,
  headers: { "x-service": "orderdesk" },
});

export async function reserve(sku, qty) {
  const res = await inventory.post("/reservations", { json: { sku, qty } });
  return res.json();
}
```

`src/clients/payments.js`

```js
import { createClient } from "quillfetch";

export const payments = createClient({
  baseUrl: process.env.PAYMENTS_URL,
  timeout: 30000,
  retry: { limit: 2 },
});

export async function capture(intentId) {
  const res = await payments.post(`/intents/${intentId}/capture`);
  return res.json();
}
```

`test/clients/inventory.test.js` stubs the network with quillfetch's
`mockTransport()` and checks request bodies. No test exercises a slow upstream.

## Release notes (complete, 3.4.2 → 4.1.0)

### 4.1.0

- Added `client.stream()` for chunked response bodies.
- `retry.backoff` now accepts a function.

### 4.0.1

- Fixed a TypeScript declaration for `mockTransport()`.

### 4.0.0 (major)

- Breaking: the `timeout` option is now expressed in seconds, to match the
  `retry.maxDelay` option, which has always used seconds. Fractional values are
  allowed.
- Breaking: removed the deprecated `client.fetchRaw()` method. Use
  `client.request()` instead.
- Breaking: `hooks.beforeError` receives an object `{ error, request }` instead
  of the error alone.
- New: HTTP/2 is used automatically when the server supports it.

### 3.5.0

- Deprecated `client.fetchRaw()`.
- `mockTransport()` records request headers.
