# Test Strategy: CSP proxy with per-request nonces (mfc-csp)

**Commit:** d90d6bb
**Scope:** `git diff d86d2dc...HEAD` — `proxy.ts` (new: `buildCsp`, `proxy`, matcher config), `app/layout.tsx` (dynamic-rendering opt-out)
**Reviewed:** 2026-08-18
**Context:** Merged code-fact-check report (k=2, executed) at `runs/review-arms/e8-evidence-pipeline/mfc-csp/code-fact-check-report.md`; its executed evidence is treated as ground truth for current behavior and is not re-verified here.

## Test Conventions

- **Framework:** Vitest (`environment: 'jsdom'`, `globals: true`, setup file `vitest.setup.ts`), React Testing Library for components.
- **Location/naming:** tests are colocated next to the implementation with a `.test.ts` / `.test.tsx` suffix (e.g., `app/lib/llm/streamLlm.test.ts`, `app/hooks/useDecomposition.test.ts`). One directory uses `__tests__/` (`app/lib/stores/__tests__/`), but colocated-suffix is the dominant pattern — a proxy test belongs at repo root as `proxy.test.ts`, next to `proxy.ts`.
- **Infrastructure:** no HTTP-integration or server-boot test harness exists; all 221 existing tests are unit/component tests. There is no existing test that imports `proxy.ts` or exercises `app/layout.tsx`.
- **Testability constraint:** `buildCsp` is module-private. Either export it (it is a pure function; exporting for test is the cheapest change) or test it indirectly through `proxy()`'s response header. Recommendations below assume it gets exported; if the team prefers not to, T1 folds into T2.
- **Runtime note (from fact-check Claim 7c):** the proxy runs on the **Node.js** runtime (the code comment claiming Edge is refuted), so Vitest's Node process is a faithful host for `Buffer`/`crypto.randomUUID` behavior — no Edge shim needed in tests.

## Untested Paths Touched by the Change

No path introduced by this diff is exercised by any existing test. The fact-check *executed* several of these (matcher probes, nonce freshness, header/HTML nonce agreement) — that is one-off evidence, not regression protection; every entry below has zero automated coverage.

- **G1** — `proxy.ts:19-31` — `buildCsp` directive-list contract: the exact 9 directives, their values, `"; "` join with no trailing separator — not covered
- **G2** — `proxy.ts:22` — nonce interpolation site: the nonce lands only inside `script-src` as `'nonce-<value>'`, exactly once; `buildCsp` performs no validation, so a nonce containing `'`, `;`, or whitespace would silently corrupt the policy — not covered
- **G3** — `proxy.ts:37` — nonce generation: base64-of-UUID shape, CSP-safe charset (no quotes/semicolons/whitespace — base64 of a 36-byte UUID string is 48 chars, unpadded), and distinctness across consecutive `proxy()` calls — not covered (fact-check Claims 1c/7a observed freshness by curl; no test pins it)
- **G4** — `proxy.ts:41-47` — header agreement invariant: the `x-nonce` value forwarded on the overridden request headers is byte-identical to the nonce inside the response's `Content-Security-Policy` header (this is the invariant that makes Next's HTML nonce-tagging match the policy; fact-check Claims 2/8 executed it once) — not covered
- **G5** — `proxy.ts:44-48` — `proxy()` return contract: a `NextResponse` carrying both the `Content-Security-Policy` response header and the request-header override for `x-nonce` — not covered
- **G6** — `proxy.ts:55-57` — matcher route coverage (inclusion/exclusion): pages and unknown routes (404s) get a CSP; `/api/*`, `/_next/static/*`, `/_next/image*`, `/favicon.ico` get none. Includes the prefix edge the negative lookahead creates: any path segment merely *starting* with `api` (e.g. `/apidocs`, `/apix`) is silently excluded and served **without any CSP** — not covered, and the prefix edge is not even documented
- **G7** — `proxy.ts:58-61` — prefetch skip: requests carrying `next-router-prefetch` or `purpose: prefetch` headers bypass the proxy entirely (no CSP, no nonce burn) — not covered
- **G8** — `proxy.ts:20-30` — dev-vs-prod invariance: `buildCsp` has **no** environment branch — the same strict policy (no `'unsafe-eval'`, no dev carve-out) is served in dev and prod. Fact-check r1/r2 confirmed the dev server functions under it (nonced scripts, external stylesheets), but nothing pins this deliberate strictness against the common "add `unsafe-eval` in dev" drift — not covered
- **G9** — `app/layout.tsx:25-31` — `async` layout + `await headers()` dynamic-rendering opt-out: every route builds as `ƒ (Dynamic)`; removing the `await headers()` line would silently revert routes to static rendering with a stale baked-in nonce (fact-check Claim 1a verified via r2's build log; Claim 1b establishes the comment's stated mechanism is wrong, so the comment cannot be trusted to defend the line in review) — not covered

Ambiguity surfaced (G6): is excluding `/apidocs`-style paths intended? The comment (`proxy.ts:52-54`) describes excluding "API routes," which in Next means `/api/...` — the lookahead `(?!api|...)` is broader than the stated intent. Whichever way it resolves, a test should pin the decision.

## Recommended Tests

#### T1 — `buildCsp` directive-list contract (unit)

**Closes gaps:** G1, G2
**Type:** unit
**Priority:** high
**File:** `proxy.test.ts` (repo root, colocated with `proxy.ts`; requires exporting `buildCsp`)
**What it verifies:** the exact directive set and the nonce's single, correctly-quoted landing site — the contract Next's renderer and the browser both depend on.
**Key cases:**
- `buildCsp("FIXED")` equals the exact expected string: `default-src 'self'; script-src 'self' 'nonce-FIXED' 'strict-dynamic'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; object-src 'none'` (a full-string assertion, not per-directive `toContain`, so a dropped or reordered directive fails loudly; splitting on `"; "` and asserting the 9-element array is an acceptable equivalent)
- the nonce appears exactly once in the output, and only within `script-src` (`output.split("FIXED").length === 2`)
- no trailing `;` and no empty directive (guards against a future `.join` or array edit regression)
**Setup needed:** none — pure function. This is the cheapest test in the plan.

#### T2 — `proxy()` response/request header contract (unit)

**Closes gaps:** G3, G4, G5
**Type:** unit
**Priority:** high
**File:** `proxy.test.ts`
**What it verifies:** the header-agreement invariant that makes the whole scheme work — the nonce Next reads from the CSP header (fact-check Claim 2) and the nonce forwarded via `x-nonce` are the same fresh value, per request.
**Key cases:**
- `proxy(new NextRequest("http://localhost/"))` returns a response whose `Content-Security-Policy` header matches `buildCsp` output for *some* nonce (extract via `/'nonce-([^']+)'/`)
- the extracted nonce is 48 chars of base64 with no `'`, `;`, or whitespace, and `Buffer.from(nonce, 'base64').toString()` matches the UUID regex — pinning the CSP-safe charset G3 names
- the forwarded `x-nonce` equals the nonce extracted from the CSP header (G4). `NextResponse.next({ request })` encodes overrides onto the response as `x-middleware-override-headers` / `x-middleware-request-x-nonce`; assert via those, with a one-line comment noting they are Next's documented override channel (per `MiddlewareResponseInit` in `next/dist/server/web/spec-extension/response.d.ts`) — if this feels too internal, asserting `x-nonce` presence via a spy on `NextResponse.next` is the alternative
- two consecutive `proxy()` calls yield different nonces (G3 distinctness — the property fact-check r1 observed by curl)
**Setup needed:** `NextRequest` constructed directly from `next/server`; runs fine under the existing jsdom+Node vitest config (proxy is Node-runtime per fact-check Claim 7c).

#### T3 — matcher route-coverage table (unit, table-driven)

**Closes gaps:** G6, G7
**Type:** unit (contract test on `config.matcher`)
**Priority:** high — ranked highest overall, see Summary
**What it verifies:** which paths receive a CSP and which are silently excluded — turning the fact-check's one-off curl probes (Claim 9) into a regression gate.
**File:** `proxy.test.ts`
**Key cases (table-driven, matching the project's existing table style in e.g. `costs.test.ts`):**
- Pin the source string exactly: `config.matcher[0].source === "/((?!api|_next/static|_next/image|favicon.ico).*)"` — crude but catches every accidental edit
- Behavior table against a matcher compiled from that source (either `new RegExp('^' + source.replace(...) + '$')` mirroring path-to-regexp's compilation of this pattern, or Next's own `getMiddlewareRouteMatcher` from `next/dist/shared/lib/router/utils/middleware-route-matcher` fed the built regexp — the latter also evaluates `missing`, closing G7 in the same table; note it is a Next internal, so pin it with a comment and accept it may need touch-up on major upgrades):
  - `/` → matched (CSP applied)
  - `/some-random-page` → matched (404s get CSP — fact-check r2 confirmed)
  - `/api/analytics` → not matched
  - `/_next/static/chunks/x.js`, `/_next/image?url=...`, `/favicon.ico` → not matched
  - `/apidocs` → **not matched** — this case documents the prefix edge; if the team decides `/apidocs`-like pages *should* get a CSP, the expected value flips and the source needs `api/` + anchoring instead of `api`
- With `getMiddlewareRouteMatcher`: request with `next-router-prefetch: 1` → not matched; with `purpose: prefetch` → not matched; same path without those headers → matched (G7)
**Setup needed:** import `config` from `proxy.ts`; minimal fake `{ headers }` request objects for the `missing` cases.

#### T4 — dev/prod CSP invariance guard (unit)

**Closes gaps:** G8
**Type:** unit
**Priority:** medium
**File:** `proxy.test.ts`
**What it verifies:** the deliberate absence of an environment branch — the policy served in dev is byte-identical to prod's and never contains `'unsafe-eval'` or `'unsafe-inline'` in `script-src`.
**Key cases:**
- `buildCsp("N")` with `NODE_ENV=development` (via `vi.stubEnv`) equals `buildCsp("N")` with `NODE_ENV=production`
- output never contains `'unsafe-eval'`; the `script-src` directive never contains `'unsafe-inline'`
- comment in the test citing why: dev was verified to function under the strict policy (fact-check Claims 2/5, dev-server evidence), so any future "loosen it for dev" change must be a conscious edit that breaks this test first
**Setup needed:** `vi.stubEnv` / `vi.unstubAllEnvs`. Near-zero cost since T1's fixture exists.

#### T5 — smoke script: served-header and nonce/HTML agreement (integration, out-of-band)

**Closes gaps:** G6, G4 (end-to-end confirmation), G9 (partially — see What NOT to Test)
**Type:** integration (not in vitest — a scripted `next build && next start` + curl probe, mirroring the fact-check's r2 procedure: page → CSP present with fresh nonce; `/api/analytics`, `/favicon.ico`, `/_next/static/...` → no CSP; HTML script tags carry the header's nonce)
**Priority:** medium
**File:** `scripts/csp-smoke.sh` (new; no existing integration harness to follow — keep it a plain script wired to CI or run pre-release, not a vitest file)
**What it verifies:** the real Next request pipeline applies the matcher and the renderer picks up the header nonce — the two things T2/T3 can only verify at the unit contract level, since matcher evaluation and HTML nonce-tagging live in Next, not in this repo's code.
**Key cases:** exactly the fact-check Claim 9 + Claim 2 probe set (documented in the report's evidence, `r2-curl-probes.log` / `r2-html-nonce-check.log`), reduced to pass/fail assertions.
**Setup needed:** production build (requires the Google Fonts mock trick in sandboxed CI — `NEXT_FONT_GOOGLE_MOCKED_RESPONSES`, per the fact-check's r2 build notes); ~minutes, hence medium priority and out-of-band placement.

## What NOT to Test

- **`await headers()` in `app/layout.tsx` at unit level (G9 via vitest):** jsdom cannot exercise Next's static-vs-dynamic rendering decision, and a test asserting "the layout source contains `await headers()`" is a grep in test's clothing. The behavior is only observable in build output (`ƒ (Dynamic)` per route — fact-check Claim 1a). The right guard is one grep-able assertion in T5's smoke script (`next build` output contains no `○ (Static)` route for `/`) plus fixing the layout comment's refuted mechanism claim (fact-check Claim 1b) so a future reviewer doesn't delete the line believing it only affects the proxy. Not worth a vitest file.
- **Next's own nonce-tagging of `<script>` elements:** framework behavior (`app-render.js` reads the CSP header — fact-check Claim 2). Unit-testing it would test Next, not this repo; T5 covers the end-to-end agreement once.
- **CSP enforcement semantics (`strict-dynamic` blocking injected scripts):** browser behavior per the CSP3 spec (fact-check Claim 4's scope note — no browser in the sandbox, and none in vitest either). A jsdom "test" of this would assert nothing real.
- **`Buffer`/`crypto.randomUUID` availability:** native to the Node runtime the proxy actually runs on (fact-check Claims 7b/7c). T2's charset assertions exercise both incidentally; a dedicated availability test adds nothing.

## Coverage Gaps Beyond Current Scope

**1.** The four **refuted rationale comments** (fact-check Claims 1b, 5, 6b, 7c: proxy-runs-because-of-rendering-mode, Tailwind-emits-inline-styles, OpenAlex, Edge runtime) are documentation defects no test can fix — but two of them (`style-src 'unsafe-inline'` attributed to Tailwind, Edge runtime) will misdirect the *next* person who tries to tighten the policy or debug the proxy. Fixing the comments is cheaper than any test and should ride along with the test PR.

**2.** `connect-src 'self'` sufficiency (fact-check Claim 6a) rests on "no browser code fetches absolute third-party URLs" — verified today by grep, enforceable tomorrow by a lint rule or a repo-invariant test (`rg 'https?://'` allowlist over `app/components`, `app/hooks`, `app/lib`). Without it, the first client-side third-party fetch will fail only at runtime in the browser console.

**3.** No test anywhere covers the `app/api/**/route.ts` handlers' response headers at all (they are matcher-excluded by design, so they ship with *no* CSP or other security headers); if API responses ever render HTML (error pages, redirects), that's an unprotected surface — worth a note in a future security-headers pass.

## Summary

The change ships a security control with zero automated coverage; everything currently known about its behavior lives in one-off fact-check executions. The highest-value recommendation is **T3 (matcher route-coverage table, closing G6/G7)** and G6 is the highest-ranked gap: a matcher regression fails *silently* — a route drops out of CSP protection with no error, no visual change, and no failing test, which is the "silent wrong answer" blast-radius class — and the negative-lookahead's undocumented prefix edge (`/apidocs` gets no CSP) is exactly the kind of thing a future "rename the api folder" or "tweak the regex" edit would trip. T1/T2 come next: cheap pure-function and header-contract pins that turn the fact-check's observed invariants (directive set, nonce freshness, x-nonce/CSP agreement) into regression gates. Residual risk after the plan: real matcher evaluation and HTML nonce-tagging happen inside Next, so unit tests pin this repo's contract while only the T5 smoke script confirms the pipeline end-to-end — and T5's build-time font-fetch dependency makes it the one piece needing CI plumbing. Open question surfaced by the enumeration: whether excluding all paths *starting with* `api` (not just `/api/`) is intended — T3 forces that decision to be recorded either way.
