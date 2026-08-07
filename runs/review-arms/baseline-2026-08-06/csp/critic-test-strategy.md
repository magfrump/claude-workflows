Commit: d90d6bb
# Test Strategy: CSP proxy + layout static-rendering opt-out

**Scope:** `git diff d86d2dc..d90d6bb` — `proxy.ts` (new), `app/layout.tsx` (modified)
**Reviewed:** 2026-08-06
**Tier:** Advisory (green / Consider). No blocking findings — this is a coverage-gap enumeration for a diff that ships zero tests.

## Test Conventions

- **Framework:** Vitest (`vitest run`), `environment: 'jsdom'`, `globals: true`, setup in `vitest.setup.ts`. Config at `vitest.config.ts`; `@` alias maps to repo root.
- **Location:** tests colocated with source as `*.test.ts` / `*.test.tsx` (e.g. `app/lib/llm/costs.test.ts`), or under `__tests__/` for stores.
- **Style:** `describe` / `it` / `expect`, arrange-act-assert, one `describe` per exported function (see `costs.test.ts`).
- **Infra note:** `proxy.ts` imports from `next/server` (`NextRequest`/`NextResponse`). No existing test constructs these; a test would need to import `NextRequest`/`NextResponse` from `next/server` directly (they run in jsdom/node) — no new mock infra beyond that. `crypto.randomUUID` and `Buffer` are available under Node/jsdom test runtime.

## Untested Paths Touched by the Change

No test file exists for `proxy.ts` or `app/layout.tsx` (confirmed: `rg --files -g '*proxy*'` returns only `proxy.ts`). Every path below is uncovered.

- **G1** — `proxy.ts:36` — `proxy()` generates a fresh nonce per invocation (`Buffer.from(crypto.randomUUID()).toString("base64")`); two calls must yield distinct nonces — not covered.
- **G2** — `proxy.ts:37-46` — `proxy()` sets `x-nonce` on the forwarded *request* headers and passes them via `NextResponse.next({ request: { headers } })` — not covered.
- **G3** — `proxy.ts:47` — `proxy()` sets `Content-Security-Policy` on the *response* headers, and the `script-src` directive embeds the same nonce used in the request's `x-nonce` (invariant: response CSP nonce === `x-nonce`) — not covered. **This test would surface fact-check Claim 2 (Incorrect):** the CSP is set only on the response, never on the request headers, so Next.js's documented auto-tagging (which reads the *request* CSP header) has no source — a test asserting `requestHeaders.get("Content-Security-Policy")` is non-null would fail, making the wiring gap executable rather than prose.
- **G4** — `proxy.ts:19-31` (`buildCsp`) — the directive string contains each required directive with expected values: `default-src 'self'`, `script-src` with `'nonce-…' 'strict-dynamic'`, `style-src 'self' 'unsafe-inline'`, `connect-src 'self'`, `frame-ancestors 'none'`, `object-src 'none'`, `base-uri 'self'` — not covered. `buildCsp` is **not exported** (only `proxy` and `config` are); testing it directly requires either exporting it or asserting via the response CSP header from `proxy()`.
- **G5** — `proxy.ts:51-63` (`config.matcher` regex `/((?!api|_next/static|_next/image|favicon.ico).*)`) — the negative-lookahead source string matches page routes (`/`, `/foo`) and excludes `api/*`, `_next/static/*`, `_next/image/*`, `favicon.ico`; the `missing` prefetch clause is data Next consumes, not runtime-callable — not covered. Regex-string behavior is unit-testable in isolation; the `missing` clause is not (it is declarative config Next interprets).
- **G6** — `app/layout.tsx:31` — `await headers()` opts the layout out of static rendering (async RootLayout). No existing layout test; async server-component rendering is not exercised by the jsdom suite — not covered (and low testability here; see What NOT to Test).

## Recommended Tests

#### proxy() emits a valid per-request CSP and nonce

**Closes gaps:** G1, G2, G3, G4
**Type:** unit
**Priority:** high
**File:** `proxy.test.ts` (repo root, colocated with `proxy.ts`)
**What it verifies:** each `proxy()` call attaches a response CSP whose `script-src` nonce matches the `x-nonce` set on the forwarded request, and that nonces differ across calls.
**Key cases:**
- Construct a `NextRequest` for `/`; call `proxy(req)`; assert `response.headers.get("Content-Security-Policy")` contains `script-src 'self' 'nonce-<X>' 'strict-dynamic'`.
- Extract `<X>` from the response CSP and assert it equals the `x-nonce` forwarded on the request headers (the response object's request headers, or by spying on the `NextResponse.next` argument) — this is the nonce-propagation invariant. **Expected to reveal:** there is currently no request-side CSP header, so Next's auto-tag path (fact-check Claim 2) is not wired; decide whether the test asserts the intended contract (request CSP header present) and fails loudly, or documents the current behavior.
- Call `proxy()` twice; assert the two `script-src` nonces are distinct (G1).
- Assert the full directive set from `buildCsp` is present with expected values (G4): `default-src`, `style-src 'unsafe-inline'`, `connect-src 'self'`, `frame-ancestors 'none'`, `object-src 'none'`, `base-uri 'self'`.

**Setup needed:** import `NextRequest`/`NextResponse` from `next/server`. No network, no mocks beyond request construction.

#### matcher source regex includes pages and excludes api/static

**Closes gaps:** G5
**Type:** unit
**Priority:** medium
**File:** `proxy.test.ts`
**What it verifies:** the `config.matcher[0].source` pattern selects page navigations and excludes API/static/image/favicon paths.
**Key cases:**
- Build a `RegExp` from the source and assert it matches `/`, `/workspace`, `/some/page`.
- Assert it does NOT match `/api/edit`, `/_next/static/chunk.js`, `/_next/image`, `/favicon.ico`.
- (Documentation case) assert `/_next/data/...` IS matched — surfaces the fact-check nuance that only `_next/static` and `_next/image`, not all `_next/*`, are excluded.

**Setup needed:** none (pure string/regex).

## What NOT to Test

- **G6 / `await headers()` static-opt-out (`app/layout.tsx:31`):** verifying "this render is dynamic not static" is a Next.js build-mode property, not a unit-testable behavior in jsdom — it needs a build/integration harness the project does not have. An E2E assertion (each page load carries a distinct CSP nonce) would cover the real user-facing invariant far more cheaply than trying to unit-test the render mode; note it as a future E2E, do not unit-test it now.
- **`config.matcher` `missing` prefetch clause:** declarative config consumed by Next's router; there is no runtime function to call, so it cannot be meaningfully unit-tested. Would require E2E with real prefetch headers.
- **Claim 8 (Edge-runtime availability of `Buffer`/`crypto.randomUUID`):** a runtime-environment property; not statically or unit-testable. Belongs in a smoke/deploy check, not the suite.

## Coverage Gaps Beyond Current Scope

**1.** The `x-nonce` request header is forwarded but never consumed (fact-check Claim 9 — no layout/component reads it, no `<Script>`/`next/script` usage exists). Any test asserting nonce *consumption* would have nothing to assert against; the propagation half of the feature is dead code until a consumer is added. This is a correctness gap the test plan surfaces but cannot close — a test can only pin the current (dead) behavior.

**2.** No integration/E2E test asserts the end-to-end CSP contract (a real page response carries a `Content-Security-Policy` header and Next's bootstrap scripts execute under `'strict-dynamic'`). Given Claim 2, the feature may not actually function in a browser; an E2E check is the only test that would catch a fully-broken nonce chain. Highest-value future addition once an E2E harness exists.

## Summary

The highest-value test is `proxy() emits a valid per-request CSP and nonce` (G1–G4): it is a pure unit test needing only `next/server` imports, and its nonce-propagation assertion turns fact-check Claim 2 (the CSP is set on the response but never the request, so Next's auto-tagging is unwired) from prose into a failing assertion. The main residual risk after this plan is that the *end-to-end* nonce chain — bootstrap scripts actually executing under `'strict-dynamic'` — stays unverified without an E2E harness the project lacks, and the `x-nonce` header has no consumer to test against. Open question surfaced by the enumeration: is the intended contract that the proxy set the CSP on request headers (per Next's documented pattern)? If so, the G3 test should assert that and is expected to fail against current code. `buildCsp` being unexported is a minor testability friction — export it or assert via the response header.
