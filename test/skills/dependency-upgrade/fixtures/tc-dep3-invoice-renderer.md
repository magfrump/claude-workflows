# Upgrade request: ledgerline 1.9.0 → 2.0.0

Dependabot opened a PR bumping `ledgerline`, the library that renders our
invoice PDFs. We have no feature request waiting on it; the team asks whether
to merge it along with this week's other dependency PRs.

## Manifest (package.json)

```json
{
  "name": "billing-worker",
  "engines": { "node": ">=18" },
  "dependencies": {
    "ledgerline": "^1.9.0"
  }
}
```

Dependabot's change:

```diff
-    "ledgerline": "^1.9.0"
+    "ledgerline": "^2.0.0"
```

## Runtime

`Dockerfile`

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
CMD ["node", "src/worker.js"]
```

CI (`.ci/pipeline.yml`) runs the tests on the same image.

## How the project uses ledgerline

These are all of the call sites.

`src/render/invoice.js`

```js
const { Document } = require("ledgerline");

async function renderInvoice(invoice) {
  const doc = new Document({ size: "A4", margin: 36 });
  doc.heading(`Invoice ${invoice.number}`);
  doc.table(invoice.lines, { columns: ["description", "qty", "amount"] });
  doc.total(invoice.total, { currency: invoice.currency });
  return doc.toBuffer();
}

module.exports = { renderInvoice };
```

## Release notes (complete, 1.9.0 → 2.0.0)

### 2.0.0 (major)

- Requirements: Node.js 22 or later. The package now uses the built-in
  `process.getBuiltinModule()` and will throw at import time on older
  runtimes. `engines.node` is set to `>=22`.
- Breaking: removed the `Document#image()` alias. Use `Document#picture()`.
- Breaking: `doc.table()` no longer accepts a bare array of column names as its
  second argument. Pass `{ columns: [...] }`.
- Smaller output files: fonts are subset by default.

### 1.10.0

- `doc.total()` accepts `{ currency }` for ISO 4217 codes.
- Deprecated `Document#image()`.
