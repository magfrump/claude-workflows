# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm2 (branch e3/csp-arm2)
**Scope:** `git diff d86d2dc..HEAD` — commits 9b4e453, b25e939, d90d6bb (feature state) + 99e1229 (iteration-1 fix). Files: app/layout.tsx, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts, proxy.ts, proxy.test.ts, plus commit-message claims.
**Checked:** comments, docstrings, test names/comments, and commit messages in the range, verified against the worktree code, node_modules/next@16.2.4 internals, and by running the test suite, tsc, and lint.
**Total claims checked:** 18
**Summary:** The iteration-1 fix commit's claims hold up: the nonce-delivery wiring (request-header CSP), the dataUrlToBlob decoder, the 8 proxy tests, the force-dynamic switch, and every stated verification number (234 tests / 26 files, tsc clean, lint 2 pre-existing warnings) all check out against the code and against Next 16.2.4's actual internals. What remains wrong is carried over from the feature commits, which the fix commit explicitly did not claim to clean up: the "Edge runtime" comment in proxy.ts (Next 16 proxy always runs on the Node.js runtime), the Tailwind attribution for the style-src carve-out (the real consumers are React style attributes / reactflow / KaTeX, as the fix commit's own test file states correctly), a phantom "OpenAlex" integration in the connect-src rationale, and the feature commit's "verified prod build applies the nonce to every script tag" claim, which is contradicted by the R1 mechanism the fix commit itself establishes.

**Commit:** 99e1229

## Claim 1: force-dynamic prevents baking one nonce into a prerendered document

**Location:** app/layout.tsx:21-26
**Type:** Behavioral / configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer deciding whether the export can be removed

Comment: "Every route under this layout must render per request: a statically prerendered HTML document would bake in one nonce and reuse it for every visitor, which defeats the nonce." `export const dynamic = "force-dynamic"` on a root layout does force dynamic rendering for all routes under it (paraphrased — no quote available because this is documented Next.js segment-config semantics rather than a single code line; the export is recognized by Next's static-info parser, which scans for `export const` segment config: `const PARSE_PATTERN = /...getStaticProps|getServerSideProps|generateStaticParams|export const|.../` at node_modules/next/dist/build/analysis/get-page-static-info.js:95). The prior state's `await headers()` call and its comment are fully removed — the file has no `headers` import and no other dynamic-opt-out mechanism (`import type { Metadata } from "next"; import { EB_Garamond, Geist_Mono } from "next/font/google";` are the only next imports, app/layout.tsx:1-2). No dangling imports or stale comment fragments remain.

**Evidence:** app/layout.tsx:1-27 (full head of file read; only imports are Metadata type, fonts, CSS); node_modules/next/dist/build/analysis/get-page-static-info.js:95.

## Claim 2: "Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap <script> tags it emits, so nothing here reads it directly."

**Location:** app/layout.tsx:23-25
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** maintainer wondering why the layout never touches the nonce

Next's app renderer reads the CSP from the request headers and extracts the nonce: `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only']; const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;` (node_modules/next/dist/server/app-render/app-render.js:166-167). That nonce is then threaded into the render (`App({ reactServerStream, ... preinitScripts, ServerInsertedHTMLProvider, nonce, images })`, app-render.js:1143). proxy.ts sets that request header (`requestHeaders.set("Content-Security-Policy", csp);` proxy.ts:46). "Nothing here reads it directly" is accurate: `rg -n "x-nonce" app` returns no hits in app/ — the only writers/readers of x-nonce are proxy.ts:50 and proxy.test.ts.

**Evidence:** node_modules/next/dist/server/app-render/app-render.js:166-167, 1143; proxy.ts:46, 50; rg for `x-nonce` over app/ (empty).

## Claim 3: `fetch(dataUrl)` "is a `connect-src` fetch, and the app's CSP sets `connect-src 'self'`, which refuses `data:`"

**Location:** app/lib/utils/exportGraph.ts:16-21 (dataUrlToBlob docstring)
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer asking why the helper exists instead of one-line fetch

The CSP does set the directive: `"connect-src 'self'"` (proxy.ts:27). `fetch()` is governed by connect-src, and `'self'` matches only same-origin URLs, not the `data:` scheme (paraphrased — no quote available because this is CSP3 spec behavior, not project code). The decoder itself is correct: the base64 branch strips the `;base64` suffix, takes the media type before any parameters (`.split(";")[0]`), and decodes via `atob` + `charCodeAt` into a `Uint8Array` (exportGraph.ts:29-42) — byte-exact, as the test's `//79` → `[0xff, 0xfe, 0xfd]` case confirms; the non-base64 branch uses `decodeURIComponent` per RFC 2397 percent-encoding (exportGraph.ts:33-35); missing media type falls back to `"application/octet-stream"` (exportGraph.ts:30-31). Both call sites use it: `triggerDownload(dataUrlToBlob(dataUrl), filename);` (exportGraph.ts:54) and `return dataUrlToBlob(dataUrl);` (exportGraph.ts:65). No `fetch(` of a data: URL remains anywhere in app/ — the remaining fetches are all relative `/api/...` paths or server-side external calls (see Claim 8).

**Evidence:** proxy.ts:27; app/lib/utils/exportGraph.ts:22-42, 54, 65; app/lib/utils/exportGraph.test.ts:20-23; rg `fetch\(` over app/ (11 hits, none data:).

## Claim 4: "1x1 transparent GIF — the shape toPng returns (base64 image data URL)."

**Location:** app/lib/utils/exportGraph.test.ts:10
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** test reader checking fixture realism

`toPng` (html-to-image) returns a `data:image/png;base64,...` URL, not a GIF (paraphrased — no quote available because the return format lives in the html-to-image library, not this repo). The comment's parenthetical scopes the claim to the *shape* — a base64 image data URL — which the GIF fixture does match, and the assertions themselves are internally correct: bytes `[0x47, 0x49, 0x46, 0x38, 0x39, 0x61]` are ASCII "GIF89a" and `0x3b` is the GIF trailer (exportGraph.test.ts:17-18). Minor looseness only: the fixture's media type differs from the production one.

**Evidence:** app/lib/utils/exportGraph.test.ts:10-19; app/lib/utils/exportGraph.ts:47-51 (`toPng(viewportElement, {...})` produces the dataUrl passed to the decoder).

## Claim 5: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** proxy.ts:5
**Type:** Reference / configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** developer looking for middleware.ts

The installed Next is 16.2.4 (`"next": "16.2.4"`, package.json). Next 16 recognizes the `proxy` filename as the middleware successor: `const PROXY_FILENAME = 'proxy'; const PROXY_LOCATION_REGEXP = ` `(?:src/)?${PROXY_FILENAME}` `;` (node_modules/next/dist/lib/constants.js:289-290), and its error messaging links "middleware-to-proxy" migration docs (see Claim 9 evidence).

**Evidence:** package.json (`"next": "16.2.4"`); node_modules/next/dist/lib/constants.js:289-290.

## Claim 6: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust."

**Location:** proxy.ts:7-11
**Type:** Behavioral (CSP semantics)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** security reviewer evaluating the policy design

`buildCsp` emits `` `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'` `` (proxy.ts:22). Under CSP3 `'strict-dynamic'`, only nonce-matching scripts execute, scripts they programmatically load inherit trust, and host/`'self'` sources are ignored (paraphrased — no quote available because this is CSP3 spec behavior). This also confirms the companion claim at proxy.ts:43-44 that "under 'strict-dynamic' the 'self' source is ignored, so un-nonced bootstrap scripts are refused" — which is exactly why the request-header wiring (Claim 10) is load-bearing.

**Evidence:** proxy.ts:20-31 (buildCsp directive list); CSP3 spec semantics (paraphrased as noted).

## Claim 7: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** proxy.ts:12-15
**Type:** Architectural rationale
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** security reviewer deciding whether the carve-out can be removed

The carve-out itself is justified, but the attribution is wrong. Tailwind v4 compiles to a stylesheet: the app imports it as a CSS file (`import "./globals.css";` app/layout.tsx:3), which Next ships as a linked stylesheet, not inline styles (paraphrased — no quote available because the shipping mechanism is Next's CSS pipeline, not project code). The actual consumers of `'unsafe-inline'` are inline `style={}` attributes, which are widespread in the app's own components (rg counts: GraphPanel.tsx 2, NodeDetailPanel.tsx 2, ArtifactPanelShell.tsx 1, SemiformalPanel.tsx 1, OutputPanel.tsx 1, plus others) and in reactflow's node transforms and KaTeX's rendered output (paraphrased — library-internal behavior). Notably, the fix commit's own test file states the correct rationale: "Required by React style={} attributes, reactflow's inline transforms and KaTeX; removing it silently breaks graph layout and equation sizing." (proxy.test.ts:57-58). The two rationales now disagree in-tree; proxy.ts is the wrong one. This is a feature-commit comment the fix commit did not claim to fix ("Amber and green findings are out of scope for this pass and remain open", commit 99e1229).

**Evidence:** proxy.ts:12-15; proxy.test.ts:56-61; app/layout.tsx:3; rg `style=\{` over app/ (multiple components).

## Claim 8: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** proxy.ts:16-17
**Type:** Invariant (client network-initiation enumeration)
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** security reviewer validating the tightest directive

Re-enumerated all `fetch(` call sites in app/ on this state (11 non-test hits). Client-side initiators all target same-origin relative paths: `fetch("/api/analytics")` (app/hooks/useAnalytics.ts:11, 30), `fetch("/api/verification/lean", ...)` (app/lib/formalization/api.ts:104, plus relative `url` fetches at :10, :38), `fetch("/api/explanation/lean-error", ...)` (app/components/features/lean-display/LeanCodeDisplay.tsx:88), `fetch("/api/refine/context", ...)` (app/components/features/context-input/ContextInput.tsx:25). External calls are server-side only: `fetch(OPENROUTER_API_URL, ...)` lives in app/lib/llm/callLlm.ts:164 and streamLlm.ts:249, imported exclusively by app/api/* routes and app/lib/formalization/artifactRoute.ts (rg over importers); the Lean verifier call is inside an API route (app/api/verification/lean/route.ts:21); `@anthropic-ai/sdk` is imported only in app/lib/llm/callLlm.ts. The former violator — `fetch(dataUrl)` in exportGraph.ts — is gone (Claim 3). Two inaccuracies keep this from Verified: (1) "OpenAlex" appears nowhere in the codebase (`rg -n "OpenAlex|openalex" app` — zero hits), so the enumeration names a phantom integration; (2) fonts are self-hosted via `next/font/google` (app/layout.tsx:2), and pdf.js workers are same-origin module URLs (`pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(...)`, app/lib/utils/fileExtraction.ts:26, pdfPropositionParser.ts:443) — consistent with the sufficiency conclusion, though workers are governed by script-src fallback rather than connect-src (paraphrased — CSP3 worker-src fallback chain).

**Evidence:** rg `fetch\(` over app/; app/hooks/useAnalytics.ts:11,30; app/lib/llm/callLlm.ts:164; app/lib/llm/streamLlm.ts:249; app/api/verification/lean/route.ts:21; rg importers of callLlm/streamLlm (all under app/api/ or artifactRoute.ts); rg "OpenAlex" (empty).

## Claim 9: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** proxy.ts:35-36
**Type:** Configuration / runtime claim
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** developer reasoning about which APIs are safe to use in proxy.ts

In Next 16, the proxy does not run in the Edge runtime — it always runs on Node.js. Next's own error message: "Route segment config is not allowed in Proxy file at ... Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy" (node_modules/next/dist/build/analysis/get-page-static-info.js:576), and the build forces it: `if (staticInfo.runtime === 'nodejs' || (0, _utils1.isProxyFile)(page)) { ... runtime: 'nodejs',` (node_modules/next/dist/build/index.js:1515-1519). The availability conclusion is harmless — `crypto.randomUUID` and `Buffer` are both natively available in Node — so the code works, but the runtime identification reflects the pre-Next-16 middleware-on-Edge world and would mislead someone avoiding Node-only APIs unnecessarily (or trusting Edge constraints that don't apply). Carried from the feature commit; not in the fix commit's claimed scope.

**Evidence:** node_modules/next/dist/build/analysis/get-page-static-info.js:576; node_modules/next/dist/build/index.js:1515-1519; proxy.ts:34-36.

## Claim 10: "Next.js reads the nonce off the *request* `Content-Security-Policy` header during render... Setting it only on the response is not enough... Both headers must carry the same policy."

**Location:** proxy.ts:41-45
**Type:** Behavioral / architectural (the R1 fix's core claim)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** the reviewer of the R1 blocker; future maintainer tempted to delete the "redundant" request-header line

The read side is confirmed at node_modules/next/dist/server/app-render/app-render.js:166-167 (quoted in Claim 2) — the nonce is extracted from *request* headers, so a response-only policy leaves `nonce === undefined` and the bootstrap scripts un-nonced; under `'strict-dynamic'` (which ignores `'self'`, Claim 6) they would be refused. The write side delivers: `NextResponse.next({ request: { headers: requestHeaders } })` encodes each forwarded header as `headers.set('x-middleware-request-' + key, value); ... headers.set('x-middleware-override-headers', keys.join(','));` (node_modules/next/dist/server/web/spec-extension/response.js:36-39), and the server unpacks them onto the request before render (`overrideHeaders = overrideHeaders.split(','); ... delete middlewareHeaders['x-middleware-override-headers'];`, node_modules/next/dist/server/lib/router-utils/resolve-routes.js:396-411). Both header writes carry the identical `csp` string (proxy.ts:46, 55).

**Evidence:** proxy.ts:38-56; node_modules/next/dist/server/app-render/app-render.js:166-167; node_modules/next/dist/server/web/spec-extension/response.js:25-40; node_modules/next/dist/server/lib/router-utils/resolve-routes.js:396-411.

## Claim 11: "Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through to a server component."

**Location:** proxy.ts:48-49
**Type:** Invariant / security
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** security reviewer checking header-injection surface

`requestHeaders.set("x-nonce", nonce);` (proxy.ts:50) — `Headers.set` replaces any existing value; `append` would join them (paraphrased — WHATWG Headers spec behavior). The test at proxy.test.ts:97-107 exercises exactly this with a client-supplied `"x-nonce": "attacker-controlled"` and asserts the forwarded value does not contain it. One accuracy note, not a defect: no server component currently reads x-nonce at all (rg over app/ — zero hits), so the header is written defensively for future consumers rather than protecting an existing read.

**Evidence:** proxy.ts:48-50; proxy.test.ts:97-107; rg `x-nonce` over app/ (empty).

## Claim 12: matcher comment — "Apply CSP to page navigations only. Skip API routes..., Next's static assets..., and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** proxy.ts:59-62
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** maintainer editing the matcher

The config matches the comment: `source: "/((?!api|_next/static|_next/image|favicon.ico).*)"` excludes api, static assets (and favicon.ico, unmentioned but consistent), and the `missing: [{ type: "header", key: "next-router-prefetch" }, { type: "header", key: "purpose", value: "prefetch" }]` clauses (proxy.ts:64-69) exclude prefetch requests — the route matches only when both prefetch markers are absent, which is the standard Next CSP-middleware recipe (paraphrased — matcher `missing` semantics are Next's, not project code).

**Evidence:** proxy.ts:63-71.

## Claim 13: proxy.test.ts header-observation mechanism comment

**Location:** proxy.test.ts:5-12
**Type:** Behavioral (test-harness mechanism)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** test reader deciding whether `x-middleware-request-*` probing is trustworthy

The comment: "Next encodes them onto the response as `x-middleware-request-<lowercased-name>`, with the overridden names listed in `x-middleware-override-headers`, and unpacks them before render." All three parts check out against Next 16.2.4 internals (quotes in Claim 10: response.js:36-39 for the encoding, resolve-routes.js:396-411 for the unpack). Lowercasing holds because `Headers` iteration yields normalized lowercase names (paraphrased — WHATWG Headers spec). The helper `forwardedRequestHeader` (proxy.test.ts:13-22) mirrors the encoding faithfully, including requiring the name in the override list before trusting the value. "Reading that encoding is the only way to assert from a unit test" is a judgment call rather than a checkable fact, but no alternative observable exists on the `NextResponse` surface (the forwarded request object is not exposed).

**Evidence:** proxy.test.ts:5-22; node_modules/next/dist/server/web/spec-extension/response.js:25-40; node_modules/next/dist/server/lib/router-utils/resolve-routes.js:396-411.

## Claim 14: proxy.test.ts test names match their assertions; the forwarded-CSP test falsifies the R1 wiring

**Location:** proxy.test.ts:34-114 (8 tests)
**Type:** Behavioral (test-to-name fidelity)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer trusting the suite as regression protection

Checked each of the 8 tests against its name: (1) "emits exactly the intended directive set" sorts and compares all 9 directive keys, matching buildCsp's list exactly (proxy.test.ts:36-52 vs proxy.ts:21-30); (2) nonce + `'strict-dynamic'` on script-src — asserted (test:54-58 vs proxy.ts:22); (3) style-src carve-out — asserted (test:60-66); (4) "sets the CSP on the response" — asserted via response header (test:73-77); (5) "forwards the same CSP on the request so Next can nonce its scripts" — asserts `forwarded !== null` **and** `forwarded === response CSP` (test:79-87). This is the falsifiability claim: with the pre-R1 wiring (`NextResponse.next()` with no `request.headers` init), the encoding block in response.js:25-40 never runs, `x-middleware-override-headers` is absent, `forwardedRequestHeader` returns null (proxy.test.ts:20), and `expect(forwarded).not.toBeNull()` fails — the test genuinely falsifies broken nonce delivery at the middleware boundary (it cannot, from a unit test, falsify a hypothetical change in *Next's* render-side read; that residual is acknowledged in the commit's Notes). (6) x-nonce matches the policy nonce — asserted by substring `'nonce-${nonce}'` (test:88-95); (7) overwrite-not-append — see Claim 11; (8) "issues a fresh nonce per request" compares two runs' CSP strings (test:109-113), valid since the nonce derives from `crypto.randomUUID()` per call (proxy.ts:36).

**Evidence:** proxy.test.ts:34-114; proxy.ts:21-36; node_modules/next/dist/server/web/spec-extension/response.js:25-40.

## Claim 15: commit 99e1229 — R1/R2 fix descriptions

**Location:** git log 99e1229 (message body, R1 and R2 paragraphs)
**Type:** Behavioral (commit-message claims)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer auditing the fix against the blocker list

R1: "proxy.ts now sets the same policy string on both the forwarded request headers and the response" — confirmed (proxy.ts:46, 55, single `csp` local; mechanism verified in Claim 10). R2: "Added dataUrlToBlob() in exportGraph.ts and replaced both fetch call sites, keeping connect-src tight rather than widening it with data:" — confirmed: both call sites replaced (exportGraph.ts:54, 65), `connect-src 'self'` unchanged (proxy.ts:27), no data:-URL fetch remains in app/ (Claim 3 evidence).

**Evidence:** git log 99e1229; proxy.ts:27, 46, 55; app/lib/utils/exportGraph.ts:54, 65.

## Claim 16: commit 99e1229 — R3: test inventory, falsifiability, and "234 tests pass (was 221)"

**Location:** git log 99e1229 (R3 paragraph and Verification line)
**Type:** Configuration / verification claims
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer checking claimed verification actually ran

Re-ran the claimed verification in the worktree: `npx vitest run` → "Test Files  26 passed (26) / Tests  234 passed (234)" — matching "26 files / 234 tests pass" exactly. "(was 221)" is consistent: the diff adds exactly 13 tests (proxy.test.ts: 3 buildCsp + 5 proxy = 8, matching the brief's "8 tests"; exportGraph.test.ts: 5), and 234 − 13 = 221, agreeing with d90d6bb's "221/221 tests pass". The claimed coverage list (directive set, nonce on script-src, style-src carve-out, per-request freshness, x-nonce overwrite, CSP forwarded on request) maps one-to-one onto the 8 tests (Claim 14). "That last assertion fails against the pre-R1 wiring" — verified by mechanism analysis (Claim 14, item 5). `npx tsc --noEmit` → exit 0, matching "clean". `npm run lint` → "✖ 2 problems (0 errors, 2 warnings)", both `react-hooks/exhaustive-deps` in app/page.tsx (lines 209, 271), a file untouched by this range — matching "2 pre-existing warnings in app/page.tsx, untouched".

**Evidence:** vitest run output (26 files / 234 tests, re-executed 2026-08-06); tsc exit 0; lint output quoting app/page.tsx:209, 271; proxy.test.ts + exportGraph.test.ts test counts.

## Claim 17: commit 9b4e453 — "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** git log 9b4e453 (feature commit message)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** security reviewer assessing whether CSP is guardrail or fix

`rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" app` — zero hits; both negatives confirmed. "KaTeX trust:false" overstates slightly: the KaTeX integration sets no `trust` option at all (`import rehypeKatex from "rehype-katex"; ... const rehypePlugins = [rehypeKatex];`, app/components/features/output-editing/LatexRenderer.tsx:6-10) — `trust: false` is KaTeX's *default*, not something this codebase configures (paraphrased — KaTeX library default, not project code). The security posture claimed is real; the phrasing implies an explicit setting that does not exist.

**Evidence:** rg over app/ (empty for both patterns); app/components/features/output-editing/LatexRenderer.tsx:6-10.

## Claim 18: commit 9b4e453 — "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** git log 9b4e453 (feature commit message)
**Type:** Verification claim (historical)
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** anyone treating the feature commit as evidence the CSP worked pre-fix

At 9b4e453 the policy was set only on the response; Next extracts the nonce from the *request* CSP header (app-render.js:166-167, Claim 2), so at that commit the renderer had no nonce and could not have stamped it "onto every <script> tag it generates" — this is precisely blocker R1, which the fix commit confirms: "R1 FIXED — nonce never reached the document. The policy was set only on the response" (git log 99e1229). The two commit messages contradict each other and R1's mechanism is the one the framework code supports. Confidence Medium only because I cannot re-run the historical manual verification; the mechanism evidence, however, is direct. (The companion d90d6bb claim "No behavior change; CSP directives preserved exactly" checks out for what it covers — that commit only inlined a local and edited comments.)

**Evidence:** node_modules/next/dist/server/app-render/app-render.js:166-167; git log 99e1229 (R1 paragraph); git log 9b4e453; git show d90d6bb --stat (comment/refactor only).

## Claims Requiring Attention

1. **Claim 9 (Stale, proxy.ts:35-36)** — "Edge runtime that Next proxy runs in" is wrong for Next 16: proxy always runs on the Node.js runtime (Next's own build error message says so verbatim). Behavior unaffected, but the comment misleads about which APIs are safe here. One-line comment fix.
2. **Claim 7 (Incorrect, proxy.ts:12-15)** — The style-src `'unsafe-inline'` carve-out is attributed to "Tailwind v4 emits inline styles"; the true consumers are React `style={}` attributes, reactflow transforms, and KaTeX — as proxy.test.ts:57-58 correctly states. The two in-tree rationales disagree; align proxy.ts with the test file.
3. **Claim 8 (Mostly accurate, proxy.ts:16-17)** — "OpenAlex" names an integration that does not exist anywhere in the codebase. Drop it from the enumeration.
4. **Claim 18 (Incorrect, 9b4e453 commit message)** — The feature commit's "verified prod build... applies the nonce to every <script> tag" cannot have been true given the R1 mechanism; commit history is immutable, but no doc should cite that verification.
5. **Claim 17 (Mostly accurate, 9b4e453 commit message)** — "KaTeX trust:false" is the library default, not an explicit project setting; a future KaTeX upgrade changing the default would silently void the claim.

## Goal-Alignment Note
- Answered: All seven briefed check areas — (1) request-header CSP wiring verified against Next 16.2.4 internals (Claims 2, 10); (2) dataUrlToBlob decode logic, both call sites, and no remaining data:-URL fetches (Claim 3); (3) all 8 proxy tests name-vs-assertion checked, including the falsifiability of the forwarded-CSP test and the x-middleware-request-* mechanism (Claims 13, 14); (4) force-dynamic mechanism and clean headers() removal (Claim 1); (5) connect-src client-initiation re-enumeration on this state (Claim 8); (6) commit 99e1229's per-blocker list and all verification numbers re-executed and confirmed (Claims 15, 16); (7) carried-over stale comments identified: Edge-runtime (Claim 9), Tailwind rationale (Claim 7), OpenAlex (Claim 8), plus the feature commit's untrue verification claim (Claim 18).
- Out of scope: Whether the carve-outs are the *right* security posture (critic territory); end-to-end browser confirmation that a running prod build hydrates under the CSP (unit + internals evidence only — Next could change its header encoding, as the commit's Notes acknowledge); the unused-x-nonce observation (design question, noted under Claim 11, not a factual error).
- Escalate: Nothing blocking — all fix-commit claims verified. The remaining Incorrect/Stale findings (Claims 7, 9) are comment-only fixes in proxy.ts the next iteration could take cheaply; Claim 18 is history-only.
