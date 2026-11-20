Commit: d90d6bb

# Test Strategy: strict CSP proxy (d86d2dc..d90d6bb)

**Scope:** `proxy.ts` (new, 64 lines), `app/layout.tsx` (+8/-1); consumers affected by the policy (`app/lib/utils/exportGraph.ts`, `app/lib/utils/fileExtraction.ts`, `app/lib/utils/pdfPropositionParser.ts`)
**Reviewed:** 2026-11-19
**Method:** static. The worktree has no `node_modules`, so no test or build was run by this critic; Next 16 test-helper names below are unverified against the installed package.

## Test Conventions

- Runner: Vitest 4 (`"test": "vitest run"`), `vitest.config.ts` sets `environment: 'jsdom'`, `globals: true`, setup file `vitest.setup.ts` (jest-dom only), alias `@` -> repo root.
- Location and naming: co-located `*.test.ts` / `*.test.tsx` next to the source (24 files, e.g. `app/lib/utils/fileExtraction.test.ts`), plus `app/lib/stores/__tests__/`. Style is `describe`/`it`/`expect`, `vi.mock` at module boundaries (e.g. pdfjs-dist is mocked in `fileExtraction.test.ts`).
- No test imports `next/server` or any Next runtime module today, and none sets `// @vitest-environment node`. No Playwright/Cypress or other browser e2e infrastructure exists.
- CI (`.github/workflows/ci.yml`) runs lint, `npm test`, `tsc --noEmit` and `npm run build` on Node 20 and 22. It never starts the built server, so nothing in CI ever sees a response header or rendered HTML.

## Untested Paths Touched by the Change

- **G1** — proxy.ts:19-31 — `buildCsp` directive list (strict-dynamic + nonce in script-src, `connect-src 'self'`, no `'unsafe-eval'`, `object-src 'none'`, `frame-ancestors 'none'`) — not covered; nothing pins the policy, so a loosening (or the needed fixes for E2/E4) lands unobserved
- **G2** — proxy.ts:37 — nonce generation: fresh per call, base64 of a UUID — not covered
- **G3** — proxy.ts:41-47 — header placement: `x-nonce` set on forwarded request headers, `Content-Security-Policy` set on the response only, and not on the forwarded request headers that Next's renderer reads (fact-check Claim 3 / E1) — not covered
- **G4** — proxy.ts:55-62 — matcher `source` regex: arm that skips `api`, `_next/static`, `_next/image`, `favicon.ico`; unanchored `(?!api` also skips `/apiary`, `/api-docs` (E5) — neither arm covered
- **G5** — proxy.ts:58-61 — matcher `missing` arms: request carrying `next-router-prefetch` or `purpose: prefetch` gets no proxy run — not covered
- **G6** — app/layout.tsx:27-31 — end-to-end claim that Next tags every bootstrap `<script>` with the nonce from this proxy's CSP (commit 9b4e453 "Verified prod build ... applies the nonce"; fact-check Claims 3, 19) — not covered; CI builds but never serves, so the only verification was a one-off manual check
- **G7** — app/lib/utils/exportGraph.ts:24,37 — `fetch(dataUrl)` under `connect-src 'self'` (E2): graph PNG export and export-all fail in the browser, only a console.error reaches the user — not covered
- **G8** — app/lib/utils/fileExtraction.ts:25-28, app/lib/utils/pdfPropositionParser.ts:443-446 — pdf.js worker load under script-src `'strict-dynamic'` with no `worker-src` (E3) — not covered; the existing unit tests mock pdfjs-dist, so they cannot see it
- **G9** — proxy.ts:20-30 — `next dev` under a script-src with no `'unsafe-eval'` (E4) — not covered; there is no dev/prod branch to test yet

### Evidence for the cited locations

- **G1/G9** — Severity: medium · Location: `proxy.ts:22-26` · Confidence: high · Legibility-target: for-author
  ```
      `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: blob:",
      "font-src 'self' data:",
      "connect-src 'self'",
  ```
  (excerpt ends :26; enclosing `buildCsp()` continues to :32 — read)
- **G2/G3** — Severity: high · Location: `proxy.ts:37-47` · Confidence: high on the shape; medium on the consequence (r2 found the self-hosted router copies response headers onto the request; Vercel unconfirmed) · Legibility-target: for-author
  ```
    const nonce = Buffer.from(crypto.randomUUID()).toString("base64");

    // Forward the nonce to server components via a request header so layouts
    // can read it via `headers()` and pass it to <Script> tags they render.
    const requestHeaders = new Headers(request.headers);
    requestHeaders.set("x-nonce", nonce);

    const response = NextResponse.next({
      request: { headers: requestHeaders },
    });
    response.headers.set("Content-Security-Policy", buildCsp(nonce));
  ```
  (excerpt ends :47; enclosing `proxy()` continues to :49 `return response;` — read)
- **G4/G5** — Severity: low (no page under an `api*` path exists today) · Location: `proxy.ts:57-60` · Confidence: high · Legibility-target: for-author
  ```
        source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
        missing: [
          { type: "header", key: "next-router-prefetch" },
          { type: "header", key: "purpose", value: "prefetch" },
  ```
  (excerpt ends :60; enclosing `config` continues to :64 — read)
- **G6** — Severity: high · Location: `app/layout.tsx:28-31` · Confidence: medium (static; no replicate or this critic could build) · Legibility-target: for-author
  ```
    // and can attach a fresh per-request CSP nonce. Next.js automatically tags
    // its own bootstrap <script> elements with the nonce from the response's
    // CSP header, so we don't need to read x-nonce here ourselves.
    await headers();
  ```
  (excerpt ends :31; enclosing `RootLayout()` continues to :42 — read)
- **G7** — Severity: medium · Location: `app/lib/utils/exportGraph.ts:24-25` · Confidence: high on the code path, medium on browser behavior (data: URLs are governed by connect-src for fetch) · Legibility-target: for-author
  ```
    const res = await fetch(dataUrl);
    const blob = await res.blob();
  ```
  (excerpt ends :25; enclosing `downloadGraphAsPng()` continues to :27 — read; `graphToPngBlob()` :37 has the same call)
- **G8** — Severity: medium · Location: `app/lib/utils/fileExtraction.ts:25-28` · Confidence: low (browser treatment of a same-origin module worker under `'strict-dynamic'` not checked) · Legibility-target: for-orchestrator-synthesis
  ```
    pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
      "pdfjs-dist/build/pdf.worker.min.mjs",
      import.meta.url,
    ).toString();
  ```
  (excerpt ends :28; enclosing `getPdfjs()` continues to :30 — read)

## Recommended Tests

#### Production-server CSP smoke: header nonce matches every script tag

**Closes gaps:** G6, G3 (consequence), G2 (distinctness across requests)
**Type:** integration (built server, HTTP only, no browser)
**Priority:** high
**File:** `scripts/csp-smoke.mjs` (new), run as a CI step after `npm run build` in `.github/workflows/ci.yml`
**What it verifies:** on `next start`, every `<script>` in the served HTML of `/` carries `nonce="<N>"` where `<N>` is the nonce in that response's `Content-Security-Policy` header.
**Key cases:**
- `GET /` -> 200, CSP header present, parse `'nonce-([^']+)'`; every `<script` tag in the body has `nonce="<that value>"`; zero scripts without a nonce. Fails today if Next got no nonce (r1/r3 reading of Claim 3).
- two consecutive `GET /` -> different nonces (no static caching; proves the `await headers()` opt-out works).
- `GET /api/<any route>` -> no CSP header (matcher skip arm, real Next matching).
- `GET /` with header `next-router-prefetch: 1` -> no CSP header (G5, real Next matching).
**Setup needed:** start `next start` on a free port under `timeout`, poll until ready, kill by PID afterwards. Needs the build to succeed, which needs network for `next/font/google` (CI has it). This tests self-hosted only; Vercel needs the manual preview check (see What NOT to Test).

#### `proxy()` unit: header placement and nonce shape

**Closes gaps:** G2, G3
**Type:** unit
**Priority:** high
**File:** `proxy.test.ts` (repo root, co-located with `proxy.ts`), first line `// @vitest-environment node`
**What it verifies:** the proxy writes the nonce consistently to the places Next reads.
**Key cases:**
- `proxy(new NextRequest("http://localhost/"))` -> response `Content-Security-Policy` contains `'nonce-X'` and forwarded request header `x-nonce` equals `X` (read forwarded headers via `x-middleware-request-x-nonce` on the response, or the `next/experimental/testing/server` helpers if Next 16 still ships them — unverified here).
- after the E1 fix: forwarded request headers also carry `Content-Security-Policy` with the same nonce (this is the assertion that pins the Vercel-safe placement; write it with the fix).
- two calls -> two different nonces; each matches `/^[A-Za-z0-9+/]+=*$/` and decodes to a UUID string.
**Setup needed:** none beyond `next/server` in the node environment; jsdom default would not provide the Edge/Node `Request` semantics `NextRequest` expects.

#### `buildCsp` policy pin

**Closes gaps:** G1, G9 (after fix), G7 (after fix)
**Type:** unit (table-driven over directives; not a raw string snapshot)
**Priority:** medium
**File:** `proxy.test.ts`
**What it verifies:** each directive the security argument depends on is present, and known-dangerous sources are absent.
**Key cases:**
- script-src contains `'strict-dynamic'` and `'nonce-…'`, and never `'unsafe-inline'` or `'unsafe-eval'` when `NODE_ENV=production`.
- `object-src 'none'`, `base-uri 'self'`, `frame-ancestors 'none'` present.
- after the E4 fix: `NODE_ENV=development` adds `'unsafe-eval'` to script-src and production does not (both arms).
- after the E2 fix: connect-src permits `data:` (or the export code no longer fetches a data URL — then drop this case).
**Setup needed:** export `buildCsp` (it is module-private today) or assert through `proxy()`'s response header; parse by splitting on `; ` so reordering does not break the test.

#### Matcher regex table

**Closes gaps:** G4
**Type:** unit (table-driven)
**Priority:** low
**File:** `proxy.test.ts`
**What it verifies:** which paths the `source` pattern admits.
**Key cases:**
- `/`, `/workspace` -> matched; `/api/formalization`, `/_next/static/x.js`, `/_next/image`, `/favicon.ico` -> skipped.
- `/apiary`, `/api-docs` -> documents the current unanchored behaviour (skipped); flip the expectation to "matched" with a `(?!api/|…)` fix.
**Setup needed:** prefer Next's own matcher helper if present in 16.2.4 (`unstable_doesMiddlewareMatch` or a proxy-renamed equivalent — unverified); fallback is `new RegExp("^" + source + "$")`, which approximates but is not Next's path-to-regexp compilation, so keep the smoke test's `/api` case as the real check.

#### Browser check of export and PDF upload under the CSP

**Closes gaps:** G7, G8
**Type:** e2e (manual checklist now; Playwright only if the project adopts it)
**Priority:** medium
**File:** checklist in the PR body / `docs/` test plan; no automated file, because the repo has no browser runner and adding Playwright for two checks is out of proportion
**What it verifies:** that the policy does not break user features that only fail inside a real browser.
**Key cases:**
- prod build, open the graph panel, click PNG export -> file downloads, no `Refused to connect` CSP violation in console.
- export-all -> zip contains the graph PNG.
- upload a PDF -> text extracted; console shows no worker CSP violation.
- `npm run dev` loads the app with no `unsafe-eval` violation (G9 until fixed).
**Setup needed:** a browser against `next start` and against the Vercel preview.

## What NOT to Test

- Randomness quality of `crypto.randomUUID` beyond distinctness across two calls: platform-provided.
- `RootLayout` rendered in jsdom: an async server component calling `headers()` needs the Next request context; mocking `next/headers` would assert only that a mock was awaited. G6's real behaviour is covered by the smoke test.
- Next's own prefetch/`missing` semantics in unit form (G5): re-implementing Next matching in a test proves nothing about Next; covered by one smoke-test case instead.
- `style-src 'unsafe-inline'` breakage: the carve-out is kept, so nothing breaks; the policy pin asserts its presence only implicitly. The wrong Tailwind justification in the comment (Claim 7) is a comment fix, not a test.
- Vercel-specific header propagation (E1 on Vercel): not reproducible locally; a manual check on the preview deploy is the only evidence available.

## Coverage Gaps Beyond Current Scope

**1.** `app/lib/utils/exportGraph.ts` and `app/lib/utils/exportAll.ts` have no tests at all; the export-all error branch (`exportAll.ts:67`) swallows the graph failure, so a broken PNG step is silent regardless of CSP.
**2.** CI builds but never serves the app, so any regression that needs a running server (headers, rendering mode, route matching) is invisible to it; the smoke step above is the cheapest general fix.

## Summary

The highest-value test is the production-server smoke step: it is the only check that can show whether Next actually receives and applies the nonce, which three fact-check replicates disagreed on, and CI already builds the app so it costs one script and one CI step. A `proxy.test.ts` in the node environment then pins header placement and the policy directives cheaply, and should be written together with the E1/E2/E4 fixes so each fix carries its assertion. Residual risk after the plan: Vercel header propagation and in-browser failures (PNG export, pdf.js worker, dev eval) stay manual. Open question: whether Next 16.2.4 still ships `next/experimental/testing/server` matcher helpers under the proxy name; unverified because the worktree has no `node_modules`.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the test-strategy skill.
- Answered: yes
- Out of scope: running vitest or `next build` (no `node_modules`, no network); fixing the CSP itself (other critics' lane)
- Escalate: (1) G6/G3 — whether Next receives the nonce at all is unproven in any automated check; the orchestrator should require the smoke test or a recorded `next start` + preview verification before merge. (2) G7/G8 — browser-only breakages (PNG export, pdf.js worker) need a manual check on the preview; route to security-reviewer for the policy change. (3) Next 16 matcher-helper availability is unverified.
- Decisions I made: recommended a script-based smoke test plus a manual browser checklist instead of adding Playwright, given no browser runner exists in the repo.
