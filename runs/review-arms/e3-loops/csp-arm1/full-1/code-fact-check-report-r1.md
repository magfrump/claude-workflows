# Code Fact-Check Report

**Repository:** meta-formalism-copilot worktree at /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (branch e3/csp-arm1)
**Scope:** `git diff d86d2dc..HEAD` — commits 9b4e453, b25e939, d90d6bb, e5d95a9 (CSP proxy feature + lite-fix); files app/layout.tsx, proxy.ts; commit-message claims for e5d95a9 and 9b4e453
**Checked:** comments and docstrings in proxy.ts and app/layout.tsx; commit messages e5d95a9 and 9b4e453; verified against app/ client code, node_modules/next@16.2.4 internals, node_modules/pdfjs-dist build output
**Total claims checked:** 13
**Summary:** 4 Verified, 5 Mostly accurate, 1 Stale, 2 Incorrect, 1 Unverifiable. The two Incorrect findings: (1) the `connect-src 'self'` sufficiency claim is falsified by client-side `fetch(dataUrl)` of `data:` URLs in app/lib/utils/exportGraph.ts — graph PNG export will be blocked by this CSP; (2) "Tailwind v4 emits inline styles" misattributes the `style-src 'unsafe-inline'` carve-out — Tailwind compiles to an external stylesheet; the carve-out is actually needed for React `style={}` attributes (15+ files, incl. reactflow-based panels) and Next's dev-mode `<style>` injection. One Stale: proxy runs on the Node.js runtime in Next 16, not Edge. The nonce-delivery mechanism claim in layout.tsx is Mostly accurate but rests on an undocumented Next router behavior (middleware response headers mirrored into `req.headers`) rather than the documented request-header wiring — flagged for attention.

**Commit:** e5d95a9

## Claim 1: Next.js auto-tags its scripts with the nonce from the response CSP header

**Location:** app/layout.tsx:27-30
**Type:** Behavioral / mechanism
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Future maintainers deciding whether nonce plumbing is complete

The comment claims: "Next.js automatically tags its own bootstrap `<script>` elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves." (app/layout.tsx:28-30).

Next.js does not read the nonce from the response. The app renderer extracts the nonce from the **incoming request's** CSP header:

> `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];` — node_modules/next/dist/server/app-render/app-render.js:166, where `headers` comes from `parseRequestHeaders(req.headers, ...)` (app-render.js:1557)

proxy.ts sets the CSP only on the **response** (`response.headers.set("Content-Security-Policy", buildCsp(nonce))`, proxy.ts:56) and forwards only `x-nonce` on the request (proxy.ts:49). The wiring nonetheless works in the self-hosted server because Next's router mirrors middleware/proxy response headers back into the request before rendering:

> `resHeaders[key] = value;` / `req.headers[key] = value;` — node_modules/next/dist/server/lib/router-utils/resolve-routes.js:445-446 (loop over middleware response headers; `content-security-policy` is not in `ipcForbiddenHeaders`, node_modules/next/dist/server/lib/server-ipc/utils.js:31-39)

So the outcome the comment describes is real, but the stated mechanism ("from the response's CSP header") is only true via this mirroring, which is an implementation detail of the Node router path, not the documented contract. The official Next.js nonce pattern sets the CSP on the forwarded request headers as well. On deployment paths where the proxy runs on separate infrastructure (e.g., Vercel edge middleware in front of a lambda), the mirroring is not guaranteed, and Next would see no request CSP → no nonce on its scripts → `script-src 'nonce-…' 'strict-dynamic'` blocks the app.

**Evidence:** app/layout.tsx:27-30; proxy.ts:47-57; node_modules/next/dist/server/app-render/app-render.js:166, 1557; node_modules/next/dist/server/lib/router-utils/resolve-routes.js:426-446; node_modules/next/dist/server/lib/server-ipc/utils.js:31-39.

## Claim 2: Static prerender and per-request nonces are mutually exclusive; stale nonce would be blocked

**Location:** app/layout.tsx:32-40
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewers evaluating the waived "app-wide dynamic rendering" finding

The comment claims: "a statically prerendered document is built once, so its `<script>` tags would carry a stale nonce (or none) and be blocked by the CSP on every request after the first. Per-request nonces and static rendering are mutually exclusive by construction." (app/layout.tsx:33-37).

Mechanism checks out: the proxy generates a fresh nonce per request (proxy.ts:45) and the response CSP carries that fresh nonce, while a prerendered document's markup is fixed at build time — any embedded nonce cannot match subsequent responses' CSP. This matches Next's own documented constraint (nonces require dynamic rendering). `await headers()` (app/layout.tsx:41) is a Next dynamic API and opts the route out of static rendering, which is exactly what the comment says it is for.

**Evidence:** app/layout.tsx:27-41; proxy.ts:45 (`const nonce = Buffer.from(crypto.randomUUID()).toString("base64")`), proxy.ts:56. The "blocked on every request after the first" phrasing is paraphrased-mechanism — no runtime quote available because this fact-check is static-only; the logic follows from per-request nonce generation vs. build-time-fixed markup.

## Claim 3: The app is a single "use client" route with no generateStaticParams, revalidate, or ISR

**Location:** app/layout.tsx:37-39 (also asserted in commit e5d95a9's message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewers assessing the cost of forced dynamic rendering

Claim: "the app is a single 'use client' route with no generateStaticParams, revalidate, or ISR — so there is nothing static to lose." (app/layout.tsx:37-39).

`rg --files app -g 'page.tsx'` returns exactly one route file, app/page.tsx, whose first line is `"use client";` (app/page.tsx:1). `rg -ln 'generateStaticParams|revalidate|force-static|export const dynamic' app` matches only app/layout.tsx:37 — i.e., the comment text itself; no route segment config exists anywhere under app/. app/api/ contains only route handlers (analytics, decomposition, edit, explanation, formalization, predict, refine, verification), which the matcher excludes anyway.

**Evidence:** app/page.tsx:1 (`"use client";`); app/layout.tsx:37; grep results as above (paraphrased — no quote available because the evidence is the absence of matches).

## Claim 4: Nonce + 'strict-dynamic' blocks injected scripts while letting Next-tagged scripts run and load others

**Location:** proxy.ts:7-11
**Type:** Behavioral / security invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Security reviewers

Claim: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing" (proxy.ts:7-10). This is a correct description of CSP3 `'nonce-…' 'strict-dynamic'` semantics: parser-inserted injected scripts without the nonce are blocked; nonced scripts propagate trust to scripts they programmatically load. The directive as built is `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'` (proxy.ts:29). Note `'self'` in that directive is ignored by strict-dynamic-supporting browsers — harmless fallback for older ones, consistent with the claim.

**Evidence:** proxy.ts:7-11, 29. CSP semantics paraphrased — no quote available because the behavior is specified by the CSP3 standard, not repo code. Effectiveness is contingent on Claim 1's nonce delivery actually happening.

## Claim 5: `style-src 'unsafe-inline'` is needed because "Tailwind v4 emits inline styles"

**Location:** proxy.ts:12-15
**Type:** Configuration rationale
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** Future maintainers who might tighten style-src based on this rationale

Claim: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles." (proxy.ts:12-13).

Tailwind v4 in this app is compiled to an external stylesheet: it enters via `@import "tailwindcss";` in app/globals.css:1 (with `@theme inline {` at globals.css:28 — a Tailwind config directive, not inline-style emission), and Next ships it as a linked .css asset in production. What actually requires `'unsafe-inline'` in style-src:

- React `style={{...}}` attributes across at least 15 client files (e.g., app/components/features/proof-graph/ProofGraphNode.tsx: 4 occurrences; app/components/features/output-editing/EditableOutput.tsx: 3; GraphPanel.tsx: 2 — counts from `rg -c 'style=\{' app --glob '*.tsx'`), plus reactflow's runtime-injected inline styles. Style attributes fall under style-src-attr, which falls back to style-src; without `'unsafe-inline'` they are blocked.
- Next's dev pipeline injects all CSS (including compiled Tailwind output) as `<style>` elements for HMR.

So the carve-out is genuinely required — removing it would break the UI — but the attribution to Tailwind is wrong in production, and in dev the inline `<style>` injection is Next's behavior for any CSS, not something Tailwind "emits."

**Evidence:** proxy.ts:12-15, 30 (`"style-src 'self' 'unsafe-inline'"`); app/globals.css:1, 28; inline-style counts per rg output (paraphrased — no single quote available because the evidence is an aggregate count across 15 files).

## Claim 6: `connect-src 'self'` is sufficient because external API calls are server-to-server

**Location:** proxy.ts:16-17
**Type:** Behavioral / configuration sufficiency
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Whoever ships this CSP — this one breaks a user-facing feature

Claim: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party." (proxy.ts:16-17).

The server-to-server half is verified. Enumerating every client-side network initiation under app/ (`fetch(`, `XMLHttpRequest`, `WebSocket`, `EventSource`, `sendBeacon`):

- All API traffic from client code targets relative `/api/...` routes: app/hooks/useAnalytics.ts:11,30; app/lib/formalization/api.ts:10,38,104 (callers pass `/api/edit/*`, `/api/decomposition/extract`, and `ARTIFACT_ROUTE` values, all `/api/formalization/*` per app/lib/types/artifacts.ts:192-198); app/components/features/lean-display/LeanCodeDisplay.tsx:88; app/components/features/context-input/ContextInput.tsx:25. Covered by `'self'`.
- The OpenRouter fetches (`const response = await fetch(OPENROUTER_API_URL, {`, app/lib/llm/callLlm.ts:164 and streamLlm.ts:249) are imported only by app/api/**/route.ts handlers and app/lib/formalization/artifactRoute.ts — server-side only. Verified.

But the sufficiency claim is falsified by the export utilities, which fetch `data:` URLs **in the browser**:

> `const dataUrl = await toPng(viewportElement, {...}); const res = await fetch(dataUrl);` — app/lib/utils/exportGraph.ts:20-24 (and again at :33-37 in `graphToPngBlob`)

`toPng` (html-to-image) returns a `data:image/png;base64,...` URL. `fetch()` of a `data:` URL is governed by connect-src, and `'self'` does not include `data:` — browsers block it ("Refused to connect to 'data:...'"). These functions run client-side (caller app/components/panels/GraphPanel.tsx is `"use client"`, GraphPanel.tsx:1; `graphToPngBlob` also feeds app/lib/utils/exportAll.ts for the zip export). Under this CSP, graph PNG export and the zip export's graph image will fail. Fix is one token: `connect-src 'self' data:` — or convert the data-URL round-trip to `toBlob`.

(Adjacent, not connect-src: pdfjs spawns a worker from a same-origin bundled URL — app/lib/utils/fileExtraction.ts:26-29 — governed by worker-src/script-src fallback, and `img-src 'self' data: blob:` at proxy.ts:31 covers html-to-image's intermediate data:-URL images.)

**Evidence:** proxy.ts:16-17, 33 (`"connect-src 'self'"`); app/lib/utils/exportGraph.ts:20-38; app/components/panels/GraphPanel.tsx:1; app/lib/utils/exportAll.ts (imports graphToPngBlob); app/lib/llm/callLlm.ts:7,164; importer list of callLlm/streamLlm = 9 files, all under app/api/ or app/lib/formalization/ (paraphrased — no quote available because it's an rg -l file list). The data:-URL/connect-src blocking rule is CSP spec behavior, paraphrased — no repo quote available.

## Claim 7: 'unsafe-eval' is dev-only; Next dev needs eval; "Production builds contain no eval"

**Location:** proxy.ts:19-27 (added by e5d95a9)
**Type:** Behavioral / configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Security reviewers auditing the carve-out

Three sub-claims. (a) The gating mechanism is verified: `const devOnly = process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : "";` (proxy.ts:25-26) appended only to script-src (proxy.ts:29) — `next build`/`next start` set NODE_ENV=production, so the token never ships. (b) "Next's dev server loads modules and applies Fast Refresh through eval-based bundles" — consistent with Next's documented dev behavior (webpack eval-source-map; dev-mode CSP guidance), but not statically verifiable from this repo, and Next 16 defaults to Turbopack in dev, whose eval usage I could not confirm from node_modules. (c) "Production builds contain no eval" — slightly overstated: the client bundle includes pdfjs-dist, whose main-thread build contains an eval-family probe:

> `function isEvalSupported() { try { new Function(""); return true; } catch { return false; } }` — node_modules/pdfjs-dist/build/pdf.mjs:506-512

Under the production CSP this probe throws, is caught, and pdfjs falls back to non-eval paths — so nothing breaks and `'unsafe-eval'` is not needed in production, but the literal "contain no eval" is not strictly true (and the probe will log a CSP violation report in the console).

**Evidence:** proxy.ts:19-29; node_modules/pdfjs-dist/build/pdf.mjs:506-512 (sole `new Function` occurrence in the main-thread bundle; the worker bundle's 2 occurrences run under the worker's own policy, not the page CSP).

## Claim 8: crypto.randomUUID and Buffer are available "in the Edge runtime that Next proxy runs in"

**Location:** proxy.ts:43-44
**Type:** Architectural / runtime
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** Maintainers reasoning about what APIs proxy.ts may use

Claim: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in." (proxy.ts:43-44). Next 16's proxy does not run on the Edge runtime — Next's own build-time validation says so:

> `const message = 'Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. ...'` — node_modules/next/dist/build/analysis/get-page-static-info.js:576

The operative conclusion survives — both APIs are available in the Node.js runtime (natively, no polyfill needed) — so the code is correct; the runtime identification reads as carried over from pre-Next-16 Edge middleware and is stale.

**Evidence:** proxy.ts:43-45; node_modules/next/dist/build/analysis/get-page-static-info.js:573-576; package.json:23 (`"next": "16.2.4"`).

## Claim 9: x-nonce is forwarded "so layouts can read it via headers() and pass it to <Script> tags"

**Location:** proxy.ts:47-49
**Type:** Reference / dataflow
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Readers tracing the nonce dataflow

Claim: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to `<Script>` tags they render." (proxy.ts:47-48). The forwarding is real (`requestHeaders.set("x-nonce", nonce)`, proxy.ts:49, passed via `NextResponse.next({ request: { headers: requestHeaders } })`, proxy.ts:52-54), and layouts *could* read it. But nothing does: `rg -n 'x-nonce'` across the repo matches only proxy.ts:49 (the write) and app/layout.tsx:30 (a comment explaining it is deliberately not read). The layout renders no `<Script>` tags. The stated purpose has no consumer — the comment describes an aspirational capability, not current dataflow. Consistent with commit d90d6bb's own correction ("the nonce is only written, never read by the layout") and with the lite iteration-2 Low finding.

**Evidence:** proxy.ts:47-54; app/layout.tsx:28-30; repo-wide x-nonce grep = 2 matches (paraphrased — no quote available because the evidence is the absence of any reader).

## Claim 10: Matcher applies CSP to page navigations only, skipping API routes, static assets, and prefetches

**Location:** proxy.ts:59-70
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Reviewers checking CSP coverage

Claim: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches" (proxy.ts:59-61). The pattern `"/((?!api|_next/static|_next/image|favicon.ico).*)"` (proxy.ts:64) and the `missing` entries (proxy.ts:65-68) implement this, with two accuracy caveats:

- **Prefix matching:** the negative lookahead excludes any path *starting with* those strings — `/apiary` or `/api-docs` would also be skipped, not just `/api/*`. Overbroad but harmless for this app (single route `/`). Matches the lite iteration-2 Low finding.
- **`missing` semantics verified:** Next skips the proxy if *any* listed header is present — `const allMatch = has.every(...) && !missing.some((item)=>hasMatch(item));` (node_modules/next/dist/shared/lib/router/utils/prepare-destination.js:118) — so a request bearing either `next-router-prefetch` or `purpose: prefetch` bypasses the proxy, which is the stated intent. The header name is current: `const NEXT_ROUTER_PREFETCH_HEADER = 'next-router-prefetch'` (node_modules/next/dist/client/components/app-router-headers.js:106).

Also note other `_next/*` paths (e.g., RSC payload requests) still hit the proxy and get CSP headers — harmless, but "page navigations only" is approximate.

**Evidence:** proxy.ts:59-70; node_modules/next/dist/shared/lib/router/utils/prepare-destination.js:57-122; node_modules/next/dist/client/components/app-router-headers.js:106.

## Claim 11: Commit e5d95a9 — fix and waive rationale

**Location:** commit e5d95a9 message, Blocker 1 and Blocker 2 paragraphs
**Type:** Commit-message behavioral claims
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Review-loop auditors

Blocker 1 ("buildCsp now appends 'unsafe-eval' to script-src when process.env.NODE_ENV === 'development' only"): matches the code exactly (proxy.ts:25-26, 29); rationale recorded in the header comment as claimed (proxy.ts:19-23). Blocker 2 waive rationale ("app has exactly one page route (app/page.tsx), it is 'use client', and there is no generateStaticParams, revalidate, ISR, or force-static anywhere under app/"): all independently verified in Claim 3. The mutual-exclusion premise is verified in Claim 2. The message's "the existing comment ... has been expanded to record this reasoning" matches the diff (app/layout.tsx:27-40 expanded in e5d95a9).

**Evidence:** commit e5d95a9 message (quoted sections above via `git log`); proxy.ts:19-29; app/layout.tsx:27-41; app/page.tsx:1; grep results per Claim 3.

## Claim 12: Commit e5d95a9 — verification counts ("npm test 24 files / 221 tests passing"; tsc/lint clean)

**Location:** commit e5d95a9 message, Verification paragraph
**Type:** Verification-status claims (static check only, per scope)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Review-loop auditors

Static corroboration is exact: `rg --files app -g '*.test.*'` counts **24** test files, and `rg -c '^\s*(it|test)(\.\w+)?\('` across them sums to **221** call sites with zero `it.each`/`test.each` (so call sites ≈ test count). Both figures match the message. The *passing* status, `npx tsc --noEmit` cleanliness, and the "2 pre-existing exhaustive-deps warnings in app/page.tsx" are process claims not verifiable statically — hence Mostly accurate rather than Verified: counts confirmed, execution results taken on trust per the static-only scope.

**Evidence:** commit e5d95a9 message ("npm test 24 files / 221 tests passing"); file/test counts paraphrased — no quote available because the evidence is aggregate rg counts (24 files; 221 summed matches; 0 `.each` matches).

## Claim 13: Commit 9b4e453 — XSS-surface premises and end-to-end verification claim

**Location:** commit 9b4e453 message
**Type:** Commit-message behavioral claims
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** Security reviewers relying on the "guardrail, not a fix" framing

Sub-claims: (a) "no dangerouslySetInnerHTML, no rehype-raw" — **verified**: repo-wide grep for `dangerouslySetInnerHTML|rehypeRaw|rehype-raw` under app/ returns zero matches (paraphrased — evidence is absence of matches). (b) "KaTeX trust:false" — **mostly accurate**: no explicit `trust` option is set anywhere (`const rehypePlugins = [rehypeKatex];`, app/components/features/output-editing/LatexRenderer.tsx:10); `trust: false` is KaTeX's *default*, so the property holds but is not explicitly configured as the message implies. (c) "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates" — **unverifiable** statically (no build run in this pass); it is mechanism-consistent with the header-mirroring path found in Claim 1, but that same analysis shows the guarantee is deployment-dependent, and the commit itself concedes "Manual end-to-end browser verification on the Vercel preview is still recommended." Overall verdict keyed to (c), the load-bearing unverified claim.

**Evidence:** commit 9b4e453 message (quoted via `git log`); app/components/features/output-editing/LatexRenderer.tsx:6,10; grep results for (a) (paraphrased — absence of matches); Claim 1 evidence chain for (c).

## Claims Requiring Attention

1. **Claim 6 (Incorrect, High)** — `connect-src 'self'` breaks graph PNG export: app/lib/utils/exportGraph.ts:24,37 `fetch(dataUrl)` on `data:` URLs is blocked by this CSP in the browser (affects GraphPanel download and exportAll zip embedding). Smallest fix: add `data:` to connect-src, or replace the fetch-of-data-URL with a direct `toBlob` path.
2. **Claim 5 (Incorrect, Medium)** — "Tailwind v4 emits inline styles" is the wrong rationale for `style-src 'unsafe-inline'`. Do NOT remove the carve-out (React `style={}` attributes and reactflow require it); rewrite the comment so a future tightening attempt targets the real dependents.
3. **Claim 1 (Mostly accurate, Medium)** — nonce delivery relies on Next's router mirroring proxy *response* headers into `req.headers` (resolve-routes.js:445-446), an implementation detail. The documented pattern also sets `Content-Security-Policy` on the forwarded *request* headers; adding one line (`requestHeaders.set("Content-Security-Policy", csp)`) makes the wiring match the contract and survive deployment paths (e.g., Vercel) where mirroring may not occur. Claim 13(c)'s unverified Vercel behavior compounds this.
4. **Claim 8 (Stale, High)** — comment says proxy runs on the Edge runtime; Next 16 proxy always runs on Node.js. One-line comment fix.
5. **Claim 9 (Mostly accurate, High)** — `x-nonce` request header has no reader anywhere; either delete the forwarding or reword the comment to mark it as provision for future `<Script>` use.

## Goal-Alignment Note
- Answered: all 8 briefed claim areas — client network-call enumeration (incl. data:/blob: export paths), nonce/prerender mechanism incl. which header Next actually reads, proxy runtime, x-nonce consumers, style-src rationale, dev-eval gate and eval-free-production premise, matcher pattern + missing semantics, and e5d95a9/9b4e453 commit-message claims (static).
- Out of scope: running build/tests/lint (execution-status claims taken on static corroboration only); whether skipping CSP on prefetch responses is a security gap (reviewer question, not a fact-check of a claim); worker-src coverage for the pdfjs worker (no comment claims it).
- Escalate: Claim 6 (feature-breaking CSP directive) to the fix stage as a likely blocker; Claim 1/Claim 13(c) jointly to whoever owns deployment — nonce delivery is unverified on Vercel and rests on undocumented router behavior.
