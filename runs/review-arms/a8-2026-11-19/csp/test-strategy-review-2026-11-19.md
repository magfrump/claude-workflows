Commit: d90d6bb

# Test Strategy: strict CSP proxy (d86d2dc..d90d6bb)

**Scope:** `proxy.ts` (new, 64 lines) and `app/layout.tsx` (made async, `await headers()`); 3 commits, no test changes.
**Reviewed:** 2026-11-19
**Role:** Stage 2 contextual critic (advisory), terminal review pass.

## Test Conventions

- **Framework:** Vitest 4 (`vitest.config.ts`), `environment: 'jsdom'`, `globals: true`, setup `vitest.setup.ts` (jest-dom matchers only). Alias `@` → repo root.
- **Layout:** co-located `*.test.ts(x)` next to the source (`app/lib/utils/fileExtraction.test.ts`, `app/components/panels/OutputPanel.test.tsx`), plus `app/lib/stores/__tests__/`. No file sets `// @vitest-environment node` today (`rg vitest-environment app` finds nothing), so a proxy test would be the first one.
- **What is not there:** no API-route tests, no proxy/middleware tests, no Playwright or any browser e2e harness, no HTTP smoke test. `scripts/` holds only `diagnose-pdf.mjs` and `load-example-workspace.mjs`.
- **CI** (`.github/workflows/ci.yml`): `npm ci` → `npm run lint` → `npm test` → `npx tsc --noEmit` → `npm run build`, on Node 20 and 22. CI builds but never starts the server, so nothing checks the response headers or the rendered HTML. The commit's "221/221 tests pass" is true (r3 ran them), but no test reaches `proxy.ts` or `app/layout.tsx`, so that pass tells you nothing about this change.

## Untested Paths Touched by the Change

- **G1** — `proxy.ts:19-32` — `buildCsp(nonce)` directive set: the nonce goes into `script-src` together with `'strict-dynamic'`, plus the exact `connect-src`, `object-src`, `base-uri` and `frame-ancestors` values — not covered. Nothing pins the policy string, so a loosening edit (adding `'unsafe-inline'` to `script-src`, dropping `object-src 'none'`) would land without a test failing.
- **G2** — `proxy.ts:37` — nonce generation: a fresh value per call, base64 charset that is valid inside `'nonce-…'` — not covered (no test checks that two calls give different nonces).
- **G3** — `proxy.ts:41-47` — header propagation: `x-nonce` is set on the forwarded request headers, and `Content-Security-Policy` is set **only on the response**, never on `requestHeaders` — not covered. This is the path that fact-check Claim 3 / escalation E1 found to be load-bearing. Next reads the nonce from the *request* CSP header. On self-hosted `next start` it only gets the nonce because the router copies proxy response headers onto `req.headers` (`resolve-routes.js:443-446`). Vercel is unconfirmed. No test would notice if that implicit copy stopped happening.
- **G4** — `proxy.ts:55-63` — matcher `source` negative lookahead: `/api…`, `/_next/static…`, `/_next/image…` and `favicon.ico` are excluded, and so is any path that merely *starts with* `api` (`/apiary`, `/api-docs`) — not covered. The over-match on `/api*` prefixes is unintended; `public/*.svg` and non-prefetch RSC navigations are included.
- **G5** — `proxy.ts:58-61` — `missing` arms: a request with `next-router-prefetch` present, or `purpose: prefetch`, skips the proxy; a request with `purpose` set to any other value still runs it — not covered (both arms and the value-mismatch case).
- **G6** — `app/layout.tsx:31` — `await headers()` opting the root layout out of static prerendering — not covered. r3's no-headers build (`fc-r3-logs/noheaders-headers.txt`) shows what happens without it: `x-nextjs-cache: HIT`, `x-nextjs-prerender: 1`, `Cache-Control: s-maxage=31536000`, and a **fresh** CSP nonce on a **cached** HTML body. Every script would then be blocked by `'strict-dynamic'`. Deleting the line as "unused" (the comment itself says nothing is read) breaks the whole app, and no test or build step would fail.
- **G7** — `app/layout.tsx:27-31` with `proxy.ts:22` — end-to-end invariant: every `<script>` in the served HTML carries `nonce="<value from this response's CSP header>"`. Not covered. r3 checked it by hand once on `next start` for `/` (15/15 scripts); nothing re-checks it, and it was never checked on Vercel.
- **G8** — `proxy.ts:26` against `app/lib/utils/exportGraph.ts:24,37` — `connect-src 'self'` blocks `fetch(dataUrl)` on a `data:` URL. Not covered. Graph PNG export fails silently (`GraphPanel.tsx` `handleExportGraph` catches and only `console.error`s). Export All (`exportAll.ts:60-68`) still produces the zip but drops `proof-graph.png` with a `console.warn`. jsdom does not enforce CSP, so existing component tests cannot catch this.
- **G9** — `proxy.ts:19-31` (no `worker-src`; `script-src` is the fallback) against `app/lib/utils/fileExtraction.ts:26-29` and `pdfPropositionParser.ts:443-446` — the pdf.js worker loaded from a same-origin URL. `'strict-dynamic'` causes `'self'` to be ignored, so the worker may be blocked. Not covered, and the outcome is unresolved: the existing tests `fileExtraction.test.ts` and `pdfPropositionParser.test.ts` run in jsdom, where CSP is not enforced.

## Recommended Tests

#### Proxy unit test: policy string, nonce freshness, header placement

**Closes gaps:** G1, G2, G3
**Type:** unit
**Priority:** high
**File:** `proxy.test.ts` at the repo root next to `proxy.ts` (co-located, per convention), with `// @vitest-environment node` as its first line, since `NextRequest`/`NextResponse` need the Node fetch globals rather than jsdom's.
**What it verifies:** `proxy()` returns a response whose CSP header pins the intended directives with a per-call nonce, and forwards that nonce on the request side.
**Key cases:**
- `proxy(new NextRequest("http://localhost/"))` → the response header `content-security-policy` split on `"; "` deep-equals the expected 9-directive array, with `script-src` matching `/^script-src 'self' 'nonce-[A-Za-z0-9+/=]+' 'strict-dynamic'$/`. Assert explicitly that `script-src` does not contain `'unsafe-inline'` or `'unsafe-eval'`, and that `object-src 'none'` and `base-uri 'self'` are present. A whole-string snapshot is the cheaper alternative, but the explicit negative asserts say *why* a change is wrong.
- Two calls → the two nonces differ, and each nonce decodes from base64 to a UUID-shaped string.
- The nonce in the response CSP equals the forwarded `x-nonce`. Read it from the `x-middleware-request-x-nonce` response header, which is how `NextResponse.next({ request: { headers } })` serialises overrides; confirm the exact header name against the installed Next 16.2.4 before writing the assert.
- **The G3 decision test:** assert where `Content-Security-Policy` ends up on the forwarded request headers (`x-middleware-request-content-security-policy`). Today it is absent. If the author adopts the Next-documented pattern (`requestHeaders.set("Content-Security-Policy", csp)`), this test flips to asserting it is present and then guards the fix. Either way it records the decision, which nothing records now. Hold this case until E1 is resolved.

**Setup needed:** none beyond the environment pragma. No mocks; `crypto.randomUUID` and `Buffer` are real in Node.

#### Matcher table test

**Closes gaps:** G4, G5
**Type:** unit (table-driven)
**Priority:** medium
**File:** `proxy.test.ts` (same file).
**What it verifies:** `config.matcher` selects page navigations and skips API routes, static assets and prefetches.
**Key cases:** (path, headers) → matched?
- `/` → yes; `/foo` → yes; `/next.svg` → yes (documents that `public/` files get a CSP)
- `/api/analytics` → no; `/_next/static/chunks/x.js` → no; `/_next/image?url=…` → no; `/favicon.ico` → no
- `/apiary` → **no** under the current regex. Record this as the known over-exclusion, or fix the regex to `api(?:/|$)` and flip the case to yes.
- `/` with `next-router-prefetch: 1` → no; `/` with `purpose: prefetch` → no; `/` with `purpose: other` → yes

**Setup needed:** Next 16 does not obviously ship the `unstable_doesMiddlewareMatch` helper in this version, and `node_modules` was not available to confirm it, so check `next/experimental/testing/server` first. If it is missing, test only the `source` regex against the path list by compiling `^${source}$`; that tests the regex, not Next's matcher engine. The `missing` arms then fall to the smoke test below.

#### Built-app CSP smoke test in CI

**Closes gaps:** G5, G6, G7
**Type:** integration (HTTP against `next start`)
**Priority:** high. This is the only test that catches the fatal failure modes: the layout getting prerendered, or the nonce not reaching the scripts.
**File:** `scripts/csp-smoke.mjs`, plus a CI step after `npm run build` in `.github/workflows/ci.yml`. Run it as `timeout 60 node scripts/csp-smoke.mjs`; it starts `next start -p <port>` itself, polls until ready, and kills the server by PID in `finally`. Keep it out of `vitest run`, because it needs a production build.
**What it verifies:** the served HTML is dynamic and every script carries the nonce from the same response's CSP header.
**Key cases:**
- `GET /` → the response has `content-security-policy`; extract the nonce. Every `<script` tag in the body has `nonce="<that nonce>"`, there is at least one script, and the count of scripts without a nonce is 0.
- `GET /` → the response does **not** have `x-nextjs-cache: HIT` or `x-nextjs-prerender`, and `Cache-Control` is not `s-maxage=…`. This catches G6: remove `await headers()` and this case fails, which r3's `noheaders-headers.txt` already shows.
- Two `GET /` → different nonces (proves no caching at the HTML layer).
- `GET /api/analytics` and `GET /_next/static/...` → no CSP header; `GET /` with `next-router-prefetch: 1` → no CSP header.

**Setup needed:** none new; it uses `fetch` from Node 20+. This covers self-hosting only. For Vercel (the open part of E1), run the same script against the preview URL by hand, or point it there with `CSP_SMOKE_URL`. That closes the gap the commit message itself flags ("manual end-to-end browser verification on the Vercel preview is still recommended").

#### Browser-enforced CSP check for the export and PDF paths

**Closes gaps:** G8, G9
**Type:** e2e (real browser, with CSP enforced)
**Priority:** medium. The impact is user-facing but recoverable. Fixing G8 is a one-line directive change, so the test matters mostly to keep it fixed.
**File:** no browser harness exists. The minimum-cost option is a manual checklist recorded in the PR or in `CONTRIBUTING.md`. If one Playwright spec gets added for CSP later, `e2e/csp.spec.ts` is the place.
**What it verifies:** the features that depend on what the CSP allows still work under the shipped policy.
**Key cases:**
- On a page with a decomposition graph, click Export Graph → a `proof-graph.png` download fires, and the console has no `Refused to connect to 'data:…'` violation. Expected to **fail** today (G8).
- Click Export All → the zip contains `proof-graph.png`. Expected to fail today: the zip arrives without the PNG and only a `console.warn` is logged.
- Upload a PDF → text extraction completes, with no `worker-src`/`script-src` violation for `pdf.worker.min.mjs` (G9; the outcome is unknown and this case settles it).
- Listen for `securitypolicyviolation` events across a full session → zero events.

**Setup needed:** a real Chromium. jsdom cannot do this.

## What NOT to Test

- **`app/layout.tsx` rendering via React Testing Library.** `await headers()` throws outside a Next request scope, and a jsdom render of `<html>`/`<body>` tells you nothing about prerendering. The CI smoke test closes G6 at the level where the failure actually shows up.
- **`style-src 'unsafe-inline'` behaviour.** It is a deliberate carve-out. Its stated *reason* is wrong (fact-check Claim 6), but that is a comment fix. The G1 policy assert already pins the value, so no behavioural test is needed.
- **Nonce cryptographic strength or entropy.** `crypto.randomUUID` is the platform's CSPRNG. Testing the "fresh per call" property (G2) is enough.
- **`x-nonce` consumption.** Nothing reads it (fact-check Claim 11). Test that it is forwarded (G3), not that it is used. If it stays unused, the better fix is to delete it rather than test it.
- **Runtime choice (Edge vs Node.js, Claim 9).** That is a comment correction. No test would add information.

## Coverage Gaps Beyond Current Scope

**1.** API routes (`app/api/*/route.ts`, 10+ handlers) have no tests at all. They are the server-to-server boundary that the `connect-src 'self'` rationale depends on, and the place an LLM-output sanitisation regression would first show up.
**2.** No test pins the markdown rendering safety that the commit message names as the actual XSS defence: no `rehype-raw`, and KaTeX with `trust: false` (which is the default, not configured; fact-check Claim 14). A unit test on `LatexRenderer` / the markdown renderer that feeds it `<img src=x onerror=…>` and `\href{javascript:…}` and asserts no live handler or `javascript:` link would be a cheaper and more direct guard than CSP. `LatexRenderer.test.tsx` already exists to put it in.
**3.** Graph export (`exportGraph.ts`, `exportAll.ts`) has no unit tests, even setting CSP aside. Its error handling is silent (only `console.error`/`console.warn`), so any export failure is invisible to the user.

## Summary

The highest-value addition is the built-app CSP smoke test wired into CI after `npm run build` (G6, G7). It is the only check that catches the two failures that would break every page: `await headers()` being removed as dead-looking code, and the nonce not reaching Next's scripts. CI already builds, so it costs one script and one step. The `proxy.test.ts` unit file (G1–G5) is cheap and pins the policy string against silent loosening, but it cannot see rendering. The main residual risk after this plan is deployment-specific. The nonce reaches Next only through an implicit router copy of response headers onto the request (E1), which is verified on `next start` and unknown on Vercel; only a run against the preview URL resolves it. Two known functional regressions, graph PNG export (G8) and the possibly blocked pdf.js worker (G9), are invisible to jsdom tests and need a real browser or a recorded manual check.

## Findings with locations

**F1 — `await headers()` is an untested load-bearing line that reads as dead code**
- **Severity:** high
- **Location:** `app/layout.tsx:27-31`
- **Evidence:**
  ```
    // Opt this layout out of static rendering so proxy.ts runs on every request
    // and can attach a fresh per-request CSP nonce. Next.js automatically tags
    // its own bootstrap <script> elements with the nonce from the response's
    // CSP header, so we don't need to read x-nonce here ourselves.
    await headers();
  ```
  (excerpt ends :31; enclosing `RootLayout` continues to :42, the JSX return — read; the awaited value is discarded)
- **Confidence:** high (r3 `fc-r3-logs/noheaders-headers.txt` shows a prerendered HIT carrying a fresh nonce when the line is removed)
- **Legibility-target:** for-author

**F2 — the CSP reaches the forwarded request only through an implicit copy, and no test records that**
- **Severity:** high
- **Location:** `proxy.ts:41-47`
- **Evidence:**
  ```
    const requestHeaders = new Headers(request.headers);
    requestHeaders.set("x-nonce", nonce);

    const response = NextResponse.next({
      request: { headers: requestHeaders },
    });
    response.headers.set("Content-Security-Policy", buildCsp(nonce));
  ```
  (excerpt ends :47; enclosing `proxy()` continues to :49 `return response;` — read)
- **Confidence:** medium (self-hosted behaviour verified by r3; Vercel unconfirmed)
- **Legibility-target:** for-author

**F3 — `connect-src 'self'` silently breaks graph PNG export; jsdom tests cannot see it**
- **Severity:** medium
- **Location:** `proxy.ts:26`; `app/lib/utils/exportGraph.ts:24`
- **Evidence:** `proxy.ts:26`: `    "connect-src 'self'",` · `exportGraph.ts:24`: `  const res = await fetch(dataUrl);` (excerpt ends :24; enclosing `downloadGraphAsPng` continues to :27 — read; `graphToPngBlob` repeats the pattern at :37)
- **Confidence:** high
- **Legibility-target:** for-author

**F4 — no test covers the matcher, including the unintended `/api*` prefix exclusion**
- **Severity:** low
- **Location:** `proxy.ts:57`
- **Evidence:** `      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",`
- **Confidence:** high
- **Legibility-target:** for-author

**F5 — CI never exercises the response the change produces**
- **Severity:** medium
- **Location:** `.github/workflows/ci.yml` (Build step, last step)
- **Evidence:**
  ```
        - name: Build
          run: npm run build
  ```
- **Confidence:** high
- **Legibility-target:** for-orchestrator-synthesis

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the test-strategy skill.
- Answered: yes
- Out of scope: Choosing the fix for E1, G8 and G9 (directive changes) belongs to security-reviewer. `node_modules` is absent from the worktree, so whether the matcher test helper exists in Next 16.2.4 was not confirmed.
- Escalate: (1) E1/G3: decide whether to set `Content-Security-Policy` on `requestHeaders` too (the documented pattern) before the unit test pins either behaviour; (2) G9: the pdf.js worker outcome under `'strict-dynamic'` is unresolved and needs a real-browser run; (3) the Vercel-preview smoke run is the only way to close the deployment half of G7.
- Decisions I made: I put the HTTP smoke test in `scripts/` plus a CI step rather than in `vitest run`, because it needs a production build. For G8 and G9 I recommended a manual checklist instead of adding Playwright, since the repo has no browser harness.
