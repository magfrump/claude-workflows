# Code Fact-Check Report (Merged, k=3)

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (meta-formalism-copilot, branch e3/csp-arm1)
**Scope:** `git diff d86d2dc..HEAD` (HEAD = f25d968) — app/layout.tsx, app/lib/security/csp.ts, app/lib/security/csp.test.ts, app/lib/utils/exportGraph.ts, proxy.ts, proxy.test.ts, plus commit-message claims of f25d968
**Checked:** 2026-08-06
**Commit:** f25d968
**Replication:** k=3 (mechanical merge of code-fact-check-report-r1/r2/r3.md; clustering: same file, ±5 lines, same assertion; most-severe verdict wins: Incorrect(high) > Incorrect(med) > Incorrect(low) > Stale > Mostly accurate > Unverifiable > Verified)
**Total clusters:** 22
**Summary:** 18 verified, 3 mostly accurate, 1 unverifiable, 0 stale, 0 incorrect

Replicates split claims at different granularity (each reported 18 claims; the union clusters to 22). "—" in a replicate-verdicts line means that replicate did not check the assertion as a distinct claim; "(subsumed)" means the replicate covered the assertion only inside a broader composite claim.

---

## Cluster 1: Layout opts out of static rendering via `await headers()` so proxy.ts runs per request

**Location:** `app/layout.tsx:23-27,41`
**Type:** Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (Med) · r2 Verified (High) · r3 —

Both covering replicates confirm `await headers()` at `app/layout.tsx:41` is Next's dynamic-rendering opt-out; r2 additionally quotes Next's own `StaticGenBailoutError` text (`node_modules/next/dist/server/request/headers.js:78`).

---

## Cluster 2: "Single 'use client' route with no generateStaticParams, revalidate, or ISR"

**Location:** `app/layout.tsx:37-40`
**Type:** Architectural
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

Unanimous: only page is `app/page.tsx` (`"use client"` at line 1); greps for `generateStaticParams|revalidate` match only the comment itself.

---

## Cluster 3: Next parses the nonce from the *request* Content-Security-Policy header, which proxy.ts sets on the forwarded request (same policy on both request and response)

**Location:** `app/layout.tsx:24-32`; `proxy.ts:18-26,36`
**Type:** Behavioral / Architectural
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High; claims 1 and 16) · r3 Verified (High)

Unanimous against installed Next 16.2.4: `parseRequestHeaders` reads `headers['content-security-policy']` (`node_modules/next/dist/server/app-render/app-render.js:155-167`); `proxy.ts:25-26` sets the forwarded request header; `proxy.ts:36` mirrors it on the response. Corrects the full-1 headline Incorrect finding (response-only delivery).

---

## Cluster 4: csp.ts "Extracted from proxy.ts ... can be imported and asserted on directly; the proxy entry point stays a thin wiring layer"

**Location:** `app/lib/security/csp.ts:4-7`
**Type:** Architectural / Reference
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 —

Both covering replicates confirm the direct import in `csp.test.ts:2`, proxy.ts consuming `buildCsp` as wiring (`proxy.ts:3,16`), and `git show e5d95a9:proxy.ts` containing the pre-extraction inline definition.

---

## Cluster 5: style-src 'unsafe-inline' dependents (React style props, reactflow, KaTeX, next/font, HMR — not Tailwind)

**Location:** `app/lib/security/csp.ts:13-19`
**Type:** Architectural
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (Med) · r2 Verified (Med) · r3 Verified (Med)

Unanimous: every named dependent exists (`package.json:29` reactflow, `app/layout.tsx:2-5` KaTeX/next-font, inline `style={{` sites); Tailwind is build-time PostCSS (`postcss.config.mjs:3`, `app/globals.css:1-2`). Medium across the board because runtime inline-injection behavior of third-party libs is not statically quotable.

---

## Cluster 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes)"

**Location:** `app/lib/security/csp.ts:20-24`
**Type:** Architectural
**Merged verdict:** Mostly accurate
**Replicate verdicts:** r1 Mostly accurate (High) · r2 Mostly accurate (High) · r3 Mostly accurate (High)

Unanimous. The conclusion holds: the only third-party fetch target is OpenRouter (`app/lib/llm/callLlm.ts:7`), `callLlm`/`streamLlm` are imported only from server-side route code (the sole client-side importer is a type-only import at `app/lib/formalization/api.ts:3`), and all browser fetches are same-origin relative URLs; r3 additionally swept for `XMLHttpRequest`/`EventSource`/`WebSocket`/`sendBeacon` with no hits. The imprecision, found by all three: **OpenAlex appears nowhere in the repo except this comment** (r2 confirmed it is also absent at d86d2dc; r3 traced it to the non-ancestor `integration/6.1` branch). r2 further notes "Anthropic" names no direct Anthropic API call — it appears only as an OpenRouter model-id prefix (`app/lib/llm/models.ts:2`). Fix: drop OpenAlex (and per r2, tighten to "the only third-party API call is OpenRouter, made server-side from API route code").

---

## Cluster 7: connect-src "also governs `fetch()` of `data:` URLs — see exportGraph.ts, which decodes canvases with toBlob"

**Location:** `app/lib/security/csp.ts:22-23`
**Type:** Reference / Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (Med) · r2 — · r3 Verified (High)

Cross-reference resolves (`app/lib/utils/exportGraph.ts:6` imports `toBlob`; no `fetch(` remains outside the comment). The `data:`-scheme exclusion from `'self'` is CSP/Fetch spec behavior, not repo-quotable (basis of r1's Medium).

---

## Cluster 8: 'unsafe-eval' gated to development; pdfjs-dist probes eval with `new Function("")` inside try/catch and falls back

**Location:** `app/lib/security/csp.ts:25-30,45`
**Type:** Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (Med) · r2 Verified (Med) · r3 Verified (Med)

Unanimous: gate is `nodeEnv === "development"` (`csp.ts:45`); the probe exists verbatim in `node_modules/pdfjs-dist/build/pdf.mjs:506-513` wrapped in try/catch, feeding a feature flag rather than a hard requirement (r2: `pdf.mjs:14689`).

---

## Cluster 9: "Next's dev server loads modules and applies Fast Refresh through eval-based bundles" (dev-server HMR fragment of the unsafe-eval rationale)

**Location:** `app/lib/security/csp.ts:25-27`
**Type:** Behavioral
**Merged verdict:** Unverifiable
**Replicate verdicts:** r1 Verified (subsumed in composite, Med) · r2 Verified (subsumed in composite, Med) · r3 Unverifiable (Med)

r3 split this fragment out as a distinct claim: whether Next's dev server actually eval-loads bundles and HMR breaks without the carve-out requires running the dev server under a strict CSP; consistent with documented Next behavior, contradicted by nothing. r1/r2 rated their composite unsafe-eval claims Verified but at Medium confidence for exactly this fragment. Most-severe wins: Unverifiable. No action required — this is a confidence ceiling, not a mismatch.

---

## Cluster 10: `nodeEnv` as parameter (testable without mutating global state); comparison against the permissive value so unset/misspelled envs fail closed

**Location:** `app/lib/security/csp.ts:36-45`; `app/lib/security/csp.test.ts:53-59`
**Type:** Behavioral / Invariant
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High; claims 3 and 9) · r3 Verified (High)

Unanimous: signature `nodeEnv: string | undefined = process.env.NODE_ENV`; only exact `"development"` yields `'unsafe-eval'`; fail-closed sweep test exercises `[undefined, "", "Development", "dev", "test", "prod"]`; the comparison is unchanged from e5d95a9, only relocated.

---

## Cluster 11: csp.test.ts regression-guard comment (export must decode in-DOM, not fetch a data URL)

**Location:** `app/lib/security/csp.test.ts:67-72`
**Type:** Reference / Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

Unanimous: `exportGraph.ts` uses `toBlob`; the guarded assertion matches the built policy (`"connect-src 'self'"` at `csp.ts:52`).

---

## Cluster 12: exportGraph.ts "Separated for code-splitting since html-to-image is only needed when exporting"

**Location:** `app/lib/utils/exportGraph.ts:1-4`
**Type:** Architectural
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 — · r3 Verified (High)

Both covering replicates confirm both consumption paths are dynamic `import()` (`GraphPanel.tsx:102`, `page.tsx:576`); `exportAll.ts`'s static import is itself only dynamically loaded.

---

## Cluster 13: "html-to-image's toBlob goes canvas → canvas.toBlob(), staying entirely within the DOM; the replaced toPng + fetch(dataUrl) route throws a TypeError under connect-src 'self'"

**Location:** `app/lib/utils/exportGraph.ts:16-22`
**Type:** Behavioral
**Merged verdict:** Mostly accurate
**Replicate verdicts:** r1 Mostly accurate (High) · r2 Verified (High) · r3 Mostly accurate (High)

All three confirm the core mechanism in the installed html-to-image 1.11.13: `toBlob` = `toCanvas` + `canvasToBlob` (pure canvas API, no fetch on the decode path), and the removed `fetch(dataUrl)` step is exactly the delta. r1 and r3 dock it to Mostly accurate because "staying entirely within the DOM" is over-broad: the shared `toCanvas` pipeline can `fetch()` external resources (webfont/image embedding — `embed-webfonts.js:54`, `dataurl.js:56`); those fetches existed identically on the old `toPng` path and are same-origin-permitted. r2 noted the same qualifier but kept Verified. Most-severe wins. Optional one-word tighten: "the final decode stays in-DOM".

---

## Cluster 14: renderGraphToBlob shared helper; both call sites route through it; toBlob's null failure throws instead of downloading an empty file

**Location:** `app/lib/utils/exportGraph.ts:24-48`; commit f25d968 (R2 paragraph)
**Type:** Behavioral / Architectural
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 —

Both covering replicates confirm `downloadGraphAsPng` (line 39) and `graphToPngBlob` (line 47) route through the helper, the `if (!blob) throw` branch at lines 29-31, and that `canvas.toBlob`'s null callback value propagates through html-to-image unchanged.

---

## Cluster 15: "Why nonces + 'strict-dynamic': only nonce-tagged scripts run, and scripts they load inherit trust"

**Location:** `app/lib/security/csp.ts:8-11,48`
**Type:** Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1 — · r2 — · r3 Verified (High)

r3 only: the built directive matches (`script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`); transitive-trust semantics are CSP3 spec behavior.

---

## Cluster 16: `NextResponse.next({ request: { headers } })` encodes forwarded headers as `x-middleware-request-<name>`, unpacked by Next before rendering

**Location:** `proxy.test.ts:8-13`
**Type:** Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

Unanimous against `node_modules/next/dist/server/web/spec-extension/response.js:36-39` (including the `x-middleware-override-headers` join backing the test's assertion).

---

## Cluster 17: Falsification — deleting the `requestHeaders.set("Content-Security-Policy", csp)` line fails exactly 2 of proxy.test.ts's 5 tests

**Location:** `proxy.test.ts:30-31`; commit f25d968 (R3 paragraph)
**Type:** Behavioral / Invariant
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (Med) · r2 Verified (Med) · r3 Verified (High)

Unanimous, each by independent assertion tracing without mutating the worktree: test 1 fails (`expect(requestCsp).toBeTruthy()` receives null), test 2 fails (response header still set at `proxy.ts:36` vs. null forwarded copy), tests 3-5 pass — exactly 2 of 5, matching the commit.

---

## Cluster 18: "Next 16's Proxy always runs on the Node.js runtime ... so crypto.randomUUID and Buffer are available" (and the Middleware → Proxy rename)

**Location:** `proxy.ts:6,12-15`
**Type:** Behavioral / Reference
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

Unanimous against Next's own error text: `node_modules/next/dist/build/analysis/get-page-static-info.js:576` ("Proxy always runs on Node.js runtime", with the `middleware-to-proxy` URL corroborating the rename). Resolves full-1's Edge-runtime Incorrect finding; no stale "Edge" text remains.

---

## Cluster 19: x-nonce is a conventional seam; nothing reads it today; `.set` clobbers a client-supplied value rather than joining it

**Location:** `proxy.ts:27-31`
**Type:** Architectural / Behavioral / Invariant
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

Unanimous: repo-wide grep finds no reader of `x-nonce` outside the writer, the layout comment declining to read it, and tests; the clobber is pinned by `proxy.test.ts:76-85` ("attacker-supplied" not forwarded). This is the Y1 rationale comment the commit restored.

---

## Cluster 20: Matcher comment — CSP on page navigations only; skip API routes, static assets, and prefetches

**Location:** `proxy.ts:40-52`
**Type:** Configuration / Reference
**Merged verdict:** Verified
**Replicate verdicts:** r1 — (noted in goal-alignment sweep only) · r2 Verified (subsumed in claim 18) · r3 Verified (High)

The negative-lookahead excludes exactly `api|_next/static|_next/image|favicon.ico`; the `missing` conditions exclude both prefetch headers; r2 confirms `next-router-prefetch` is Next's real prefetch header (`app-router-headers.js:106`).

---

## Cluster 21: Commit f25d968 verification counts — "26 test files / 232 tests pass (was 24 / 221)", "Two new test files, 11 tests", tsc/lint claims

**Location:** commit f25d968 (message body)
**Type:** Configuration
**Merged verdict:** Mostly accurate
**Replicate verdicts:** r1 Mostly accurate (High) · r2 Verified (High) · r3 Verified (High)

r1 and r3 re-ran the suite and reproduced `26 passed / 232 passed` exactly; r2 verified the counts statically (26 files; 232 `it(`/`test(` blocks, no `.each` multipliers) and executed the 11 new tests. The 24/221 baseline is arithmetically consistent (26−2, 232−11) in all three. r3 additionally reproduced `tsc --noEmit` clean and lint's exactly-2 `exhaustive-deps` warnings in `app/page.tsx` (209:6, 271:6). r1's docking reason, which carries by most-severe-wins: the vitest run emits a `MISSING DEPENDENCY Cannot find dependency 'jsdom'` resolution error before completing with all tests passing, so "232 tests pass" is true but the commit's clean framing omits that noise. r3 also notes the `npm run build` next/font network-failure fragment was not re-executed (environment observation, not a code claim). No action needed beyond awareness.

---

## Cluster 22: `@vitest-environment node` pragma — NextRequest needs web-standard globals the default jsdom environment doesn't provide

**Location:** `proxy.test.ts:1-3`; `vitest.config` (`environment: 'jsdom'`)
**Type:** Configuration
**Merged verdict:** Verified
**Replicate verdicts:** r1 Verified (subsumed in claim 18) · r2 Verified (High) · r3 Verified (subsumed in claim 18)

The jsdom default is confirmed in the vitest config; r2 observed the pragma honored at runtime (both new files pass under the node environment even while jsdom resolution fails for the default).

---

## Claims Requiring Attention

### Incorrect
- None (0/3 replicates found any Incorrect claim).

### Stale
- None (0/3 replicates found any Stale claim).

### Mostly Accurate
- **Cluster 6** (`app/lib/security/csp.ts:20-24`, 3/3 replicates): `connect-src 'self'` sufficiency is correct, but the enumeration is wrong — no OpenAlex integration exists anywhere in this tree (r2: nor at d86d2dc; r3: it lives on the non-ancestor `integration/6.1` branch), and "Anthropic" is reached only as an OpenRouter model-id prefix. Tighten to: "the only third-party API call is OpenRouter, made server-side from API route code." Carried verbatim from 9b4e453 through the extraction.
- **Cluster 13** (`app/lib/utils/exportGraph.ts:17-18`, 2/3 replicates): "staying entirely within the DOM" is over-broad — html-to-image's shared `toCanvas` pipeline can `fetch()` external resources (webfont/image embedding); the removed `fetch(dataUrl)` step is the exact and correctly-stated delta. Optional one-word tighten ("the final decode stays in-DOM").
- **Cluster 21** (commit f25d968, 1/3 replicates): "26 files / 232 tests pass" reproduces exactly, but the suite emits a jsdom dependency-resolution error before passing; the commit's clean framing omits that noise. No action needed beyond awareness.

### Unverifiable
- **Cluster 9** (`app/lib/security/csp.ts:25-27`, split out by r3): Next dev-server eval/HMR behavior under a strict CSP requires a running dev server to confirm; consistent with documented Next behavior, contradicted by nothing in the tree.

---

## Verdict stability

- **Unanimous clusters:** 19/22 — every replicate that checked the assertion returned the same verdict (12 clusters checked by all three replicates; 6 by two; 1 by one).
- **Split clusters:** 3/22:
  - Cluster 13 (toBlob "entirely within the DOM"): MA / V / MA — all three found the same over-broad phrasing; only the Verified/Mostly-accurate threshold differed. Merged MA.
  - Cluster 21 (commit verification counts): MA / V / V — the split is r1's severity call on the jsdom resolution noise, not a factual disagreement (all three reproduced or confirmed the counts). Merged MA.
  - Cluster 9 (dev-server eval/HMR): V(subsumed) / V(subsumed) / Unverifiable — a granularity split: r3 carved the runtime-unverifiable fragment out of the composite unsafe-eval claim that r1/r2 rated Verified at Medium confidence for the same reason. Merged Unverifiable.
- **Agreement rate:** 19/22 clusters (86%) unanimous among covering replicates; no split involves a factual contradiction between replicates, only severity-threshold and claim-granularity differences.
- **Headline findings fully stable:** 0 Incorrect and 0 Stale in all three replicates; the OpenAlex enumeration (Cluster 6) is the sole substantive residual and was found independently by all three.

---

## Goal-Alignment Note

- Answered: All six brief items, in all three replicates. (1) Request-header CSP wiring verified against Next 16.2.4's `parseRequestHeaders` (and, in r3, `getScriptNonceFromHeader`) source (Cluster 3). (2) exportGraph toBlob path verified in the installed html-to-image source; both call sites through the shared `renderGraphToBlob` helper; null handling throws instead of downloading an empty file (Clusters 13-14). (3) csp.ts `nodeEnv` parameter mechanism, `=== "development"` fail-closed comparison, and docstring accuracy checked with fresh client-network-call enumerations on this state (Clusters 5-10). (4) Falsification claim verified independently by assertion tracing in all three replicates: exactly tests 1 and 2 of 5 fail if the `requestHeaders.set` line is deleted (Cluster 17). (5) Commit counts 26/232 reproduced (by execution in r1/r3, statically in r2); per-blocker claims R1-R4 all check out (Clusters 3, 13-14, 10, 18); r3 also reproduced tsc and lint claims (Cluster 21). (6) Comment sweep of all changed files: layout comment now correct, x-nonce rationale restored and accurate, matcher comment matches config, runtime comment corrected — the OpenAlex mention is the only surviving comment inaccuracy.
- Out of scope (all replicates): Runtime browser verification of the CSP (prod build + devtools) — the commit itself flags this as unavailable in the sandbox; R2/G1 remain runtime-unverified as the commit states; dev-server HMR behavior under CSP (Cluster 9); `npm run build` not re-attempted.
- Escalate: Nothing at Incorrect/Stale severity in any replicate — if the loop-termination bar is "no Incorrect/Stale," this pass meets it unanimously. The sole residual is the Cluster 6 OpenAlex/Anthropic enumeration (Mostly accurate, comment-only, amber-scope at most; r3 notes it would become accurate if `integration/6.1` merges into this line). **Carried forward from r2: the full-1 security review asserted the OpenAlex connect-src claim was "independently confirmed" — that confirmation does not hold on this state and must not be carried forward into any full-2 synthesis or downstream review.**
