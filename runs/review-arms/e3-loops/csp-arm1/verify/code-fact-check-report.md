# Code Fact-Check Report (merged, k=3)

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (branch `e3/csp-arm1`)
**Commit:** 1eb081e
**Scope:** `git diff d86d2dc..HEAD` — app/layout.tsx, app/lib/security/csp.ts, app/lib/security/csp.test.ts, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts, proxy.ts, proxy.test.ts
**Checked:** 2026-08-06
**Replication:** k=3 (mechanical merge of code-fact-check-report-r1/r2/r3.md, most-severe-wins)
**Total clusters:** 21 (from 56 replicate claims: r1=18, r2=18, r3=20)
**Summary:** 18 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Merge method: replicate claims clustered by (same file, ±5 lines, same assertion); cluster verdict = most-severe replicate verdict (Incorrect(high) > Incorrect(med) > Incorrect(low) > Stale > Mostly accurate > Unverifiable > Verified). All three replicates independently ran the suite green (15/15 vitest across the three new/changed test files); r2 and r3 also confirmed `npx tsc --noEmit` exits 0. The jsdom `MISSING DEPENDENCY` line reproduced as an environment artifact (acked 🟡-9) and did not affect the green result. No `docs/reviews/hallucination-patterns.md` exists; no fabrications found.

---

## Claim 1: Next tags its bootstrap `<script>`s with the nonce parsed from the *request* CSP header (set by proxy.ts on the forwarded request), so layout need not read `x-nonce`.

**Location:** `app/layout.tsx:24-32`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

Next parses the nonce from incoming request headers in `parseRequestHeaders` (`node_modules/next/dist/server/app-render/app-render.js:155-167`); proxy.ts sets exactly that header on the forwarded request (`proxy.ts:30-31`). Repo-wide grep for `x-nonce` returns only the two comments and the absence-test — no reader.

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:155-167`, `proxy.ts:30-31`, `proxy.test.ts:79-83`, `app/layout.tsx:24-32`

---

## Claim 2: Layout is a single `"use client"` route with no `generateStaticParams`, `revalidate`, or ISR; per-request nonces and static rendering are mutually exclusive.

**Location:** `app/layout.tsx:23-44`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

`rg --files app -g 'page.tsx'` returns only `app/page.tsx`, which opens `"use client"`. `generateStaticParams`/`revalidate`/`dynamic =` appear in `app/**` only inside this comment. `await headers()` is a Next dynamic API that bails out of static generation (r3 anchors the mechanism to Next's `StaticGenBailoutError`, `node_modules/next/dist/server/request/headers.js:77-115`).

**Evidence:** `app/page.tsx:1`, `app/layout.tsx:23-44`, `node_modules/next/dist/server/request/headers.js:77-115`

---

## Claim 3: The cost of the dynamic opt-out is one SSR shell render per navigation and the document is no longer shared-/CDN-cacheable (Unmeasured).

**Location:** `app/layout.tsx:34-42`
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Replication:** k=3
**Replicate verdicts:** r1=Mostly accurate, r2=Verified, r3=Verified

The mechanism is real and the comment self-labels the magnitude "(Unmeasured: ...)". r1 dropped this to Mostly accurate because the CDN-cacheability consequence depends on response headers Next emits at runtime, which static analysis cannot confirm; r2/r3 accepted the comment's unmeasured hedge as honest and rated the surrounding cost comment Verified. Minority (1/3) downgrade — a candidate amber. No edit needed: the comment already hedges precisely where the uncertainty is.

**Evidence:** `app/layout.tsx:23-44`

---

## Claim 4: `csp.ts` was extracted from `proxy.ts` so the policy can be imported and asserted on directly; proxy.ts stays a thin wiring layer.

**Location:** `app/lib/security/csp.ts:4-7`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

`proxy.ts:3` imports `buildCsp`; `csp.test.ts:2` imports it directly. proxy.ts contains no directive-string construction of its own — only nonce generation, header wiring, and matcher config.

**Evidence:** `proxy.ts:3`, `app/lib/security/csp.test.ts:2`, `app/lib/security/csp.ts:4-7`

---

## Claim 5: `style-src 'unsafe-inline'` dependents are React `style={{...}}`, reactflow transforms, KaTeX inline output, `next/font` injected declarations, and dev HMR — not Tailwind (external stylesheet).

**Location:** `app/lib/security/csp.ts:13-19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

Named packages all present (`katex ^0.16.45`, `reactflow ^11.11.4`, `tailwindcss ^4` / `@tailwindcss/postcss ^4`); `next/font` imported at `app/layout.tsx:2`; KaTeX writes element styles (`node_modules/katex/dist/katex.js:1086`); Tailwind v4 compiles to an external stylesheet (`app/globals.css`). Confidence Medium: the completeness of the dependent list is a runtime property confirmed by package presence, not by tracing every style write.

**Evidence:** `app/lib/security/csp.ts:13-19`, `package.json:16-49`, `app/layout.tsx:2`, `node_modules/katex/dist/katex.js:1086`, `app/globals.css:1-2`

---

## Claim 6: `connect-src 'self'` is sufficient because no browser-side code calls a third-party origin — every outbound call is made server-side from `app/api/**`.

**Location:** `app/lib/security/csp.ts:21-24`
**Type:** Invariant / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Mostly accurate

The load-bearing invariant holds on this tree: every client-side network call targets a relative `/api/...` path (all `ARTIFACT_ROUTE` values are `/api/formalization/*`); the only third-party origin is OpenRouter (`app/lib/llm/callLlm.ts:7`), and `callLlm`/`streamLlm` are imported only by `app/api/**` route handlers and by `artifactRoute.ts` (itself imported only by `app/api/formalization/*/route.ts`). r3 dropped this to Mostly accurate on a location nuance: the outbound `fetch` statements physically live in `app/lib/llm/*.ts` and `artifactRoute.ts`, not literally in `app/api/**` — they *execute* inside `app/api/**` handlers. Minority (1/3) downgrade; the security conclusion is unaffected. **Preserved residual** (may become an amber): tighten to "from server-side code invoked only by `app/api/**` handlers" if precision matters.

**Evidence:** `app/lib/security/csp.ts:21-24`, `app/lib/llm/callLlm.ts:7,164`, `app/lib/llm/streamLlm.ts:249`, `app/lib/formalization/api.ts:10,38,104-159`, `app/lib/types/artifacts.ts:192-198`

---

## Claim 7: `connect-src` also governs `fetch()` of `data:` URLs — see `exportGraph.ts`, which decodes canvases with `toBlob` rather than re-fetching a data URL.

**Location:** `app/lib/security/csp.ts:24-26`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Replication:** k=2 (r2, r3; r1 folds the data:-governance point into Claims 8 and 12)
**Replicate verdicts:** r2=Verified, r3=Verified

`exportGraph.ts` uses `toBlob` (no `fetch`). That `connect-src` governs `fetch()` of `data:` URLs and that `'self'` does not match the `data:` scheme is CSP3/Fetch spec behavior.

**Evidence:** `app/lib/security/csp.ts:24-26`, `app/lib/utils/exportGraph.ts:6,28-38`

---

## Claim 8: Regression guard — graph PNG/zip export must decode canvases in-DOM (`exportGraph.ts` uses `toBlob`) rather than `fetch()`-ing a data URL, which would be blocked.

**Location:** `app/lib/security/csp.test.ts:66-70`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

`exportGraph.ts:6` imports `toBlob`; the export call uses it (`exportGraph.ts:30-34`) and contains no `fetch`/`toPng`. The "would be blocked" premise matches the built policy `connect-src 'self'` (`csp.ts:53`) and standard CSP spec behavior.

**Evidence:** `app/lib/utils/exportGraph.ts:6,30-34`, `app/lib/security/csp.ts:53`, `app/lib/security/csp.test.ts:66-72`

---

## Claim 9: pdfjs-dist probes for eval with `new Function("")`, but the probe is caught and pdfjs falls back — it only logs a CSP violation.

**Location:** `app/lib/security/csp.ts:28-33`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

`isEvalSupported()` is wrapped in try/catch and returns `false` when eval is blocked (`node_modules/pdfjs-dist/build/pdf.mjs:506-513`); consumers branch on it (`pdf.mjs:14689`). Confidence Medium (r2/r3): the "only logs a CSP violation" clause is browser reporting behavior not statically checkable, and downstream non-eval fallback paths were not individually traced. `pdfjs-dist ^5.6.205` present (`package.json:25`).

**Evidence:** `node_modules/pdfjs-dist/build/pdf.mjs:506-519,14689`, `app/lib/security/csp.ts:28-33,47`, `package.json:25`, `proxy.ts:19`

---

## Claim 10: `nodeEnv` is a required, undefaulted parameter (no ambient `process.env` read); the comparison is against the permissive value so unset/misspelled/unexpected environments yield the stricter policy (fail-closed).

**Location:** `app/lib/security/csp.ts:36-47` (and fail-closed test `app/lib/security/csp.test.ts:52-59`)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

Signature `buildCsp(nonce: string, nodeEnv: string | undefined)` has no default and reads no ambient state; `devEvalDirective` compares against `"development"` (`csp.ts:46-47`). The fail-closed test loops `undefined/""/"Development"/"dev"/"test"/"prod"` and asserts no `'unsafe-eval'` (`csp.test.ts:54-59`). Sole production call site passes the env explicitly (`proxy.ts:19`); no other caller relies on a default; `tsc --noEmit` clean.

**Evidence:** `app/lib/security/csp.ts:36-47`, `app/lib/security/csp.test.ts:52-59`, `proxy.ts:17-19`

---

## Claim 11: `csp.test.ts` fires if someone widens `connect-src` to allow `data:`; the exportGraph tests fire if someone narrows the export path back to `toPng` + `fetch(dataUrl)`.

**Location:** `app/lib/utils/exportGraph.test.ts:4-12`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

CSP side: `expect(parse(buildCsp(NONCE,"production"))["connect-src"]).toBe("'self'")` (`csp.test.ts:71`). Export side: `toBlob` asserted called, `toPng`/`globalThis.fetch` asserted not called (`exportGraph.test.ts:41-45`). Both suites pass.

**Evidence:** `app/lib/security/csp.test.ts:66-72`, `app/lib/utils/exportGraph.test.ts:38-53`

---

## Claim 12: html-to-image's `toBlob` goes canvas → `canvas.toBlob()` in-DOM (webfont/image inlining may still `fetch()` same-origin); the legacy `toDataURL`/`atob` fallback is a base64 round-trip (runtime choice), and the replaced `toPng`+`fetch(dataUrl)` route throws a TypeError under `connect-src`.

**Location:** `app/lib/utils/exportGraph.ts:16-27`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High (TypeError sub-point Medium per r1)
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

`toBlob` → `toCanvas` → `canvasToBlob`, which prefers `canvas.toBlob` and falls back to `window.atob(canvas.toDataURL(...))` (`node_modules/html-to-image/lib/util.js:179-199`) — the fallback decodes via `atob`, not `fetch`, so even the slow path is not `connect-src`-governed. Webfont inlining calls `fetch` in `embed-webfonts.js:54`. `toPng` returns `toDataURL()` output, so re-fetching that `data:` URL is `connect-src`-blocked (spec behavior; r1 rates the TypeError sub-point Medium as it needs a browser runtime to confirm the exact thrown type).

**Evidence:** `node_modules/html-to-image/lib/index.js:157-174`, `node_modules/html-to-image/lib/util.js:179-199`, `node_modules/html-to-image/lib/embed-webfonts.js:44-56`, `app/lib/security/csp.ts:53`, `app/lib/utils/exportGraph.ts:16-27`

---

## Claim 13: `NextResponse.next({ request: { headers } })` encodes the forwarded headers onto the response as `x-middleware-request-<name>`, which Next unpacks before rendering.

**Location:** `proxy.test.ts:8-13`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

Next's response builder sets `x-middleware-request-<key>` and `x-middleware-override-headers` (`node_modules/next/dist/server/web/spec-extension/response.js:36-39`); the test helper reads them back with the same prefix (`proxy.test.ts:18`) and the companion override-headers assertion passes. next@16.2.4 (`package.json:23`).

**Evidence:** `node_modules/next/dist/server/web/spec-extension/response.js:36-39`, `proxy.test.ts:14-42`, `package.json:23`

---

## Claim 14: Load-bearing — deleting the `requestHeaders.set("Content-Security-Policy", csp)` line in proxy.ts must fail this test.

**Location:** `proxy.test.ts:26-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

The line exists verbatim (`proxy.ts:31`). Without it the forwarded-request CSP header is unset, so `forwardedRequestHeader(response,"content-security-policy")` returns null and `expect(requestCsp).toBeTruthy()` (`proxy.test.ts:37`) fails; nonce-parse mechanism confirmed under Claim 1.

**Evidence:** `proxy.ts:30-31`, `proxy.test.ts:31-42`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 15: The `x-nonce` seam had no readers; the write and its tests are gone, and an absence test pins the deleted state. Reinstate header + reader together, never the header alone.

**Location:** `proxy.ts:33-36`, `proxy.test.ts:79-83`
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

No `requestHeaders.set("x-nonce", ...)` remains; case-insensitive repo grep for `x-nonce` hits only the two comments and the absence-test, which asserts `toBeNull()` and passes (`proxy.test.ts:82`). Both comments phrase the header in the negative — no stale residue describing deleted code as live.

**Evidence:** `proxy.ts:30-36`, `proxy.test.ts:79-83`, `app/layout.tsx:28-32`

---

## Claim 16: Matcher applies CSP to everything except `api`/`_next/static`/`_next/image`/`favicon.ico`; deliberately no `missing:`/`has:` prefetch exclusion (every exclusion is server-determined).

**Location:** `proxy.ts:49-63`, `proxy.test.ts:85-94`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

The single matcher entry carries only `source: "/((?!api|_next/static|_next/image|favicon.ico).*)"`; no `missing:`/`has:` key exists outside comments. The invariant test iterates `config.matcher` and asserts `matcher.missing`/`matcher.has` are `undefined` (`proxy.test.ts:88-93`); passes.

**Evidence:** `proxy.ts:49-63`, `proxy.test.ts:85-94`

---

## Claim 17: Skipping on `purpose: prefetch` / `next-router-prefetch` saved ~0.75 µs of nonce generation and would have let prefetch callers receive a document with no CSP/nonce/frame-ancestors ("page navigations only").

**Location:** `proxy.ts:49-63` (perf/phrasing clause)
**Type:** Performance / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Mostly accurate, r2=Unverifiable, r3=Mostly accurate

The security half (a `missing:` clause keyed on client-suppliable headers would skip the proxy, yielding a header-less document) is verified. Two imprecisions keep it at Mostly accurate. (a) The "~0.75 µs" figure: fresh microbenchmarks of `Buffer.from(crypto.randomUUID()).toString("base64")` measured **~0.52 µs/op** (r1 ~10^6 iters; r3 200k iters) — same order of magnitude, tilde-hedged, but ~30–40% high and machine-dependent. (b) r1 also flags "page navigations only" as rounding up: the negative-lookahead matches every path outside the four prefixes, including RSC/prefetch fetches, not strictly document navigations. r2 rated the same sentence Unverifiable (the µs figure needs a runtime benchmark; no benchmark in-repo). Most-severe = Mostly accurate. **Preserved residual** (may become an amber). Optional tighten: "Apply CSP to everything except API routes and Next's static assets."

**Evidence:** `proxy.ts:49-63`, `proxy.test.ts:85-94`, microbenchmark runs 2026-08-06 (Node, worktree)

---

## Claim 18: The same policy string goes on both the forwarded request and the response; `.set` (not `.append`) clobbers a client-supplied Content-Security-Policy request header rather than joining it into a comma-list.

**Location:** `proxy.ts:21-31,38-41`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3 (r3 dedicated Claim 18; r1/r2 corroborate the clobber via the attacker-nonce test)
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

`requestHeaders.set("Content-Security-Policy", csp)` (`proxy.ts:31`) and `response.headers.set("Content-Security-Policy", csp)` (`proxy.ts:38-41`) apply the same string on both sides; the equality is asserted (`proxy.test.ts:47-50`). The `.set`-clobber property is proven by the passing attacker-nonce test supplying `script-src 'nonce-attacker'` and asserting the forwarded header does `not.toContain("attacker")` (`proxy.test.ts:64-77`).

**Evidence:** `proxy.ts:21-41`, `proxy.test.ts:45-77`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 19: Next.js 16 renamed Middleware → Proxy.

**Location:** `proxy.ts:6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

Next's own types document the rename (`node_modules/next/dist/server/web/types.d.ts:10-13`: "Middleware has been renamed to Proxy"; `ProxyConfig` aliases `MiddlewareConfigInput`). Installed next@16.2.4 (`package.json:23`).

**Evidence:** `node_modules/next/dist/server/web/types.d.ts:10-13`, `package.json:23`

---

## Claim 20: Next 16's Proxy always runs on the Node.js runtime (cannot move to Edge), so `crypto.randomUUID` and `Buffer` are available as Node core APIs.

**Location:** `proxy.ts:12-15`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

Next's build validation rejects a runtime segment config with "Proxy always runs on Node.js runtime" (`node_modules/next/dist/build/analysis/get-page-static-info.js:576`). `crypto.randomUUID`/`Buffer` are Node core globals; the proxy tests run under `@vitest-environment node` and execute `Buffer.from(crypto.randomUUID())` (`proxy.ts:15`), passing.

**Evidence:** `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `proxy.ts:12-15`, `proxy.test.ts:1-3`

---

## Claim 21: Typed against Next's `ProxyConfig` (matching `next.config.ts`'s `NextConfig` annotation) so a typo in a matcher key (`missng:`, `sources:`) fails the type check.

**Location:** `proxy.ts:43-47`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Replication:** k=3
**Replicate verdicts:** r1=Verified, r2=Verified, r3=Verified

`ProxyConfig` is re-exported from `next/server` (`node_modules/next/server.d.ts:14`), aliasing `MiddlewareConfigInput`, whose matcher entry has required `source` plus optional `has`/`missing`/`locale` (`node_modules/next/dist/build/segment-config/middleware/middleware-config.d.ts:2-11`). An excess/misspelled key trips TypeScript's excess-property check on the typed literal; `tsc --noEmit` clean. Sibling precedent `const nextConfig: NextConfig` (`next.config.ts:3`).

**Evidence:** `proxy.ts:2,43-47`, `node_modules/next/server.d.ts:14`, `node_modules/next/dist/build/segment-config/middleware/middleware-config.d.ts:2-11`, `next.config.ts:1-3`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None. All three replicates specifically swept for residue of the three deletions (the `x-nonce` write, the `missing:` prefetch clause, the `toPng`+`fetch(dataUrl)` path); every remaining mention is phrased as deliberate absence or historical contrast, not as live code.

### Mostly Accurate
- **Claim 3** (`app/layout.tsx:34-42`) — minority 1/3 (r1). The dynamic-rendering CDN-cacheability consequence rests on runtime response headers not confirmable statically; the comment already self-labels "(Unmeasured)". Candidate amber; no edit strictly needed.
- **Claim 6** (`app/lib/security/csp.ts:21-24`) — minority 1/3 (r3). *Preserved residual.* "every outbound call is made server-side from `app/api/**`" is correct about execution context but loose about code location (the `fetch` statements live in `app/lib/llm/*.ts` and `artifactRoute.ts`, invoked only by `app/api/**` handlers). Security conclusion holds.
- **Claim 17** (`proxy.ts:49-63`) — majority 2/3 Mostly accurate (r1, r3), r2 Unverifiable. *Preserved residual.* "~0.75 µs" measured ~0.52 µs/op on-machine (tilde-hedged, order-of-magnitude right, ~30–40% high); r1 additionally notes "page navigations only" rounds up. Argument (the saving is negligible) unaffected.

### Unverifiable
- None. (r2 alone rated Claim 17 Unverifiable; under most-severe-wins the cluster resolves to Mostly accurate.)

## Verdict stability

- **18 of 21 clusters unanimous** across all replicates that checked them (Verified). Cluster-level agreement rate: 18/21 ≈ 86%.
- **3 clusters disagreed** (Claims 3, 6, 17), all in the Verified↔Mostly-accurate↔Unverifiable band — no replicate ever returned Incorrect or Stale on any cluster. Every disagreement is a same-direction severity nuance (runtime-only confirmability, code-location phrasing, a machine-dependent µs constant), not a factual conflict about what the code does.
  - Claim 3: MA / V / V — r1 uniquely examined the CDN-cacheability sub-clause.
  - Claim 6: V / V / MA — r3 uniquely flagged the fetch-statement code-location looseness.
  - Claim 17: MA / Unverifiable / MA — split on how to classify the unmeasurable µs figure; both non-Verified dispositions are downgrades, so the merge lands on the more-severe Mostly accurate.
- Segmentation differed (r1=18, r2=18, r3=20 claims) mainly in how the layout comment (r1 split cost from structure) and the proxy Middleware→Proxy/Node-runtime/ProxyConfig block (r3 split into three) were carved; these are granularity differences, not verdict conflicts.

## Goal-Alignment Note

- **Answered:** All seven brief items, unanimously across replicates except the three residual downgrades above. (1) `buildCsp` `nodeEnv` is required with no default; sole production call site passes `process.env.NODE_ENV`; fail-closed comparison preserved and test-pinned (Claim 10). (2) `x-nonce` had zero readers ever; the write and its tests are gone; the load-bearing replacement is the `.set`-clobber property on the forwarded CSP header (Claims 1, 14, 15, 18). (3) The `missing:` block is gone; the comment matches the four server-determined exclusions; a test enforces no header-keyed matcher conditions (Claim 16). (4) The `connect-src` invariant was re-enumerated on this tree state: only third-party fetch is OpenRouter, reachable solely from `app/api/**`; all client fetches are relative `/api/...` (Claim 6, with the code-location residual). (5) Layout honest-cost rewrite and exportGraph toBlob/webfont-caveat comments check out against the vendored library (Claims 2, 3, 12). (6) `ProxyConfig` correctly imported from `next/server`, resolving to `MiddlewareConfigInput` with the named keys (Claim 21). (7) Sweep for newly introduced Incorrect/Stale: none across 21 clusters; the three Mostly-accurate items are phrasing/constant/runtime-confirmability nuances, not disposition regressions. All 15 tests pass in every replicate.
- **Out of scope:** Browser-runtime CSP enforcement (strict-dynamic script blocking, the `data:`-fetch TypeError, the pdfjs console violation report) — spec-level claims consistent with cited code but not statically checkable; the ~µs microbenchmark constant; code quality/design judgments (critic stages' remit); 🟢-row items and anything outside worktree-HEAD ancestors and this arm's artifacts.
- **Escalate:** Nothing. Under the 0R+0A comment-accuracy standard this merge finds no red: zero Incorrect, zero Stale, zero (merged) Unverifiable. The three Mostly-accurate clusters are advisory tightenings — candidate ambers, not blockers.
