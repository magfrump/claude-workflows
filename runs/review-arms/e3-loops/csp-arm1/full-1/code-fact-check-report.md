# Code Fact-Check Report

**Repository:** meta-formalism-copilot worktree at /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (branch e3/csp-arm1)
**Scope:** `git diff d86d2dc..HEAD` — proxy.ts (new), app/layout.tsx, plus commit messages 9b4e453, b25e939, d90d6bb, e5d95a9
**Checked:** 2026-08-06 (merged from 3 independent replicate reports; mechanical collation, most-severe-wins)
**Total claims checked:** 15 (clusters merged from replicate reports of 13, 13, and 16 claims)
**Summary:** 4 Verified, 4 Mostly accurate, 1 Stale, 6 Incorrect (4 High, 2 Medium). Headline: the nonce-delivery cluster (Claims 1, 4, 13) — Next.js extracts the script nonce from the **request** `content-security-policy` header (app-render.js:166-167), which this proxy never sets; two of three replicates conclude the nonce never reaches the renderer and `'strict-dynamic'` would block Next's own bootstrap scripts in production. The third replicate found an undocumented router-mirroring path that may make it work self-hosted (see Claim 1 prose). Separately, `connect-src 'self'` blocks the browser-side `fetch(data:…)` calls in the graph PNG export path — unanimous Incorrect across replicates.

**Commit:** e5d95a9
**Replication:** k=3

## Claim 1: Next.js auto-tags its bootstrap scripts with the nonce from the response CSP header

**Location:** app/layout.tsx:27-30
**Type:** Behavioral / mechanism
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Future maintainers deciding whether nonce plumbing is complete
**Replicate verdicts:** r1 = Mostly accurate (Medium) · r2 = Incorrect (High) · r3 = Incorrect (High)

The comment claims: "Next.js automatically tags its own bootstrap `<script>` elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves." All three replicates agree on the underlying facts: Next reads the nonce from the **incoming request's** CSP header, not the response — `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];` followed by `getScriptNonceFromHeader(csp)` (node_modules/next/dist/server/app-render/app-render.js:166-167, where `headers` derives from `parseRequestHeaders(req.headers, ...)`, app-render.js:1557). proxy.ts sets the CSP only on the **response** (proxy.ts:55-56) and forwards only `x-nonce` (which Next ignores) on the request (proxy.ts:49). r2/r3 conclude the renderer's nonce is statically `undefined`, so no script is nonce-tagged and — since `'strict-dynamic'` causes CSP3 browsers to ignore `'self'` — un-nonced parser-inserted scripts, including Next's own bootstrap scripts, would be blocked.

**Materially relevant dissent (r1):** r1 found that in the self-hosted Node server path, Next's router mirrors middleware/proxy *response* headers back into `req.headers` before rendering — `resHeaders[key] = value;` / `req.headers[key] = value;` (node_modules/next/dist/server/lib/router-utils/resolve-routes.js:445-446, loop over middleware response headers; `content-security-policy` is not in `ipcForbiddenHeaders`, node_modules/next/dist/server/lib/server-ipc/utils.js:31-39). Via this mirroring the wiring can work self-hosted — but it is an undocumented implementation detail of the Node router path, not the documented contract, and is not guaranteed on deployment paths where the proxy runs on separate infrastructure (e.g., Vercel edge middleware in front of a lambda). All three replicates converge on the same fix direction: also set the CSP on the forwarded request headers (`requestHeaders.set("Content-Security-Policy", csp)`), the official Next.js CSP pattern.

**Evidence:** app/layout.tsx:27-30; proxy.ts:47-57; node_modules/next/dist/server/app-render/app-render.js:155-167, 1557; node_modules/next/dist/server/lib/router-utils/resolve-routes.js:426-446; node_modules/next/dist/server/lib/server-ipc/utils.js:31-39; node_modules/next/dist/server/app-render/get-script-nonce-from-header.js.

## Claim 2: Per-request nonces and static prerendering are mutually exclusive; dynamic opt-out rationale

**Location:** app/layout.tsx:27-41 (`await headers()` at :41)
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewers evaluating the waived "app-wide dynamic rendering" finding
**Replicate verdicts:** r1 = Verified (High) · r2 = Verified (High) · r3 = Verified (High; split across its Claims 1 and 3, both Verified)

"A statically prerendered document is built once, so its `<script>` tags would carry a stale nonce (or none) and be blocked by the CSP on every request after the first. Per-request nonces and static rendering are mutually exclusive by construction." Mechanism checks out in all replicates: the proxy generates a fresh nonce per request (proxy.ts:45-46) embedded in the response CSP, while prerendered markup is fixed at build time — an embedded nonce cannot match subsequent responses' CSP. `await headers()` (app/layout.tsx:41) is a Next dynamic API and opts the route out of static rendering as intended. r2 notes the rationale is verified *as stated*, in a wiring where nonce delivery itself is broken (Claim 1).

**Evidence:** app/layout.tsx:27-41; app/layout.tsx:3; proxy.ts:45-46, 55-56.

## Claim 3: The app is a single "use client" route with no generateStaticParams, revalidate, or ISR

**Location:** app/layout.tsx:37-39 (also asserted in commit e5d95a9's message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewers assessing the cost of forced dynamic rendering
**Replicate verdicts:** r1 = Verified (High) · r2 = Verified (High; within its Claim 2) · r3 = Verified (High)

All three replicates independently confirm: `rg --files -g 'page.tsx' app` returns exactly one route file, app/page.tsx, whose first line is `"use client";` (app/page.tsx:1); greps for `generateStaticParams|revalidate|force-static|dynamic =` under app/ match only the layout comment text itself (app/layout.tsx:37). app/api/ contains only route handlers, which the matcher excludes anyway.

**Evidence:** app/page.tsx:1 (`"use client";`); app/layout.tsx:37; grep absence results (paraphrased — evidence is the absence of matches).

## Claim 4: Nonce + 'strict-dynamic' means only Next-tagged scripts run; injected `<script>` blocked

**Location:** proxy.ts:7-11
**Type:** Behavioral / security invariant
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Security reviewers assessing the XSS guardrail's actual protection
**Replicate verdicts:** r1 = Verified (High) · r2 = Mostly accurate (High) · r3 = Incorrect (High)

The CSP semantics described (nonce gates initial scripts; `'strict-dynamic'` propagates trust to programmatically loaded scripts; `'self'` ignored by strict-dynamic-supporting browsers) are textbook-accurate per all three replicates, and the directive as built is `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'` (proxy.ts:29). The verdict spread tracks Claim 1: r3 (most severe) holds that the premise — "scripts that Next.js has explicitly tagged with the nonce" — is false under current wiring because Next tags nothing (it never sees the nonce), so the policy does not distinguish Next's own scripts from injected ones; it blocks both categories of parser-inserted script equally. r1's Verified rests on its router-mirroring finding (Claim 1 dissent) making the trust chain real self-hosted. Effectiveness of this claim is wholly contingent on Claim 1's nonce delivery.

**Evidence:** proxy.ts:7-11, 29; Claim 1 evidence chain.

## Claim 5: `style-src 'unsafe-inline'` is needed because "Tailwind v4 emits inline styles"

**Location:** proxy.ts:12-15
**Type:** Configuration rationale
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** Future maintainers who might tighten style-src based on this rationale
**Replicate verdicts:** r1 = Incorrect (Medium) · r2 = Mostly accurate (Medium) · r3 = Incorrect (Medium)

Tailwind v4 in this app is compiled to an external linked stylesheet (`@import "tailwindcss";` in app/globals.css:1, processed via `@tailwindcss/postcss`), not inline styles. The carve-out is nonetheless genuinely required — removing it would break the UI — but for other reasons: React `style={{...}}` attributes across many client components (replicates counted 10-20 files, e.g. ProofGraphNode.tsx, EditableOutput.tsx, GraphPanel.tsx, ArtifactPanelShell.tsx; style attributes fall under style-src absent a style-src-attr directive), reactflow's runtime-injected inline styles, KaTeX-rendered output's inline style attributes (r2), and Next's dev-mode `<style>` injection for CSS/HMR. Wrong reason, right directive — the misattribution matters because "rework how Tailwind ships styles" (proxy.ts:13-14) would not by itself allow tightening.

**Evidence:** proxy.ts:12-15, 30-31; app/globals.css:1-2, 28; package.json:36,49; `rg -l "style=\{"` file listings (paraphrased — aggregate counts); app/components/features/output-editing/LatexRenderer.tsx:6-10.

## Claim 6: `connect-src 'self'` is sufficient because external API calls are server-to-server

**Location:** proxy.ts:16-18
**Type:** Behavioral / configuration sufficiency
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Whoever ships this CSP — this one breaks a user-facing feature
**Replicate verdicts:** r1 = Incorrect (High) · r2 = Incorrect (Medium) · r3 = Incorrect (High)

Unanimous Incorrect. The server-to-server half is verified by all replicates: the OpenRouter fetches (app/lib/llm/callLlm.ts:164, streamLlm.ts:249) are imported only by app/api/**/route.ts handlers and app/lib/formalization/artifactRoute.ts; the Lean verifier fetch is in a route handler (app/api/verification/lean/route.ts:21); all client-side API traffic targets relative `/api/...` routes (app/hooks/useAnalytics.ts:11,30; app/lib/formalization/api.ts:10,38,104; LeanCodeDisplay.tsx:88; ContextInput.tsx:25), covered by `'self'`. No XMLHttpRequest/WebSocket/EventSource/sendBeacon uses exist.

But the sufficiency claim is falsified by the export utilities, which fetch `data:` URLs **in the browser**: `const dataUrl = await toPng(viewportElement, {...}); const res = await fetch(dataUrl);` (app/lib/utils/exportGraph.ts:20-24, and again at :33-37 in `graphToPngBlob`). `toPng` (html-to-image) returns a `data:image/png;base64,...` URL; `fetch()` of a `data:` URL is governed by connect-src, and `'self'` does not match the `data:` scheme. These run client-side (caller GraphPanel.tsx is `"use client"`; `graphToPngBlob` also feeds app/lib/utils/exportAll.ts's zip export). Under this CSP, graph PNG export and the zip export's graph image fail. Smallest fix: `connect-src 'self' data:`, or convert the data-URL round-trip to `toBlob`.

**Evidence:** proxy.ts:16-18, 33; app/lib/utils/exportGraph.ts:16-39; app/components/panels/GraphPanel.tsx:1; app/lib/utils/exportAll.ts; app/lib/llm/callLlm.ts:7,164; importer list from `rg -l "callLlm|streamLlm"` (API routes + server lib only; paraphrased — file-list evidence).

## Claim 7: 'unsafe-eval' is dev-only; Next dev needs eval; "Production builds contain no eval"

**Location:** proxy.ts:19-27 (added by e5d95a9)
**Type:** Behavioral / configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Security reviewers auditing the carve-out
**Replicate verdicts:** r1 = Mostly accurate (Medium) · r2 = Mostly accurate (Medium) · r3 = Mostly accurate (Medium)

Unanimous. (a) Gating mechanism verified: `const devOnly = process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : "";` (proxy.ts:25-27), appended only to script-src (proxy.ts:29); `next build`/`next start` set NODE_ENV=production, so the token never ships. (b) Eval-based dev bundles: corroborated for the webpack path (node_modules/next/dist/build/webpack/plugins/eval-source-map-dev-tool-plugin.js), but Next 16 defaults dev to Turbopack, whose eval usage no replicate could confirm statically. (c) "Production builds contain no eval" is overstated: the client bundle includes pdfjs-dist, whose main-thread build contains an eval-family probe — `function isEvalSupported() { try { new Function(""); return true; } catch { return false; } }` (node_modules/pdfjs-dist/build/pdf.mjs:506-513). Under the production CSP the probe throws, is caught, and pdfjs falls back to non-eval paths — nothing breaks and `'unsafe-eval'` is not needed in production, but the literal "contain no eval" is not strictly true (and the probe logs a CSP violation in the console).

**Evidence:** proxy.ts:19-29; package.json:6-8; node_modules/pdfjs-dist/build/pdf.mjs:506-519, 14689; node_modules/next/dist/build/webpack/plugins/eval-source-map-dev-tool-plugin.js (existence); app/lib/utils/fileExtraction.ts:24-30.

## Claim 8: crypto.randomUUID and Buffer are available "in the Edge runtime that Next proxy runs in"

**Location:** proxy.ts:42-45
**Type:** Architectural / runtime
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Maintainers reasoning about what APIs proxy.ts may use
**Replicate verdicts:** r1 = Stale (High) · r2 = Stale (High) · r3 = Incorrect (High)

Next 16's proxy does not run on the Edge runtime — Next's own build-time error text states it flatly: "Route segment config is not allowed in Proxy file at ... Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy" (node_modules/next/dist/build/analysis/get-page-static-info.js:576). The operative conclusion survives — `crypto.randomUUID` and `Buffer` are core Node.js APIs, so proxy.ts:45-46 works — but the runtime identification is wrong (a holdover from the middleware-era Edge default). r3 (most severe) notes future readers could draw wrong inferences, e.g. avoiding Node-only APIs unnecessarily; r1/r2 filed the same facts as Stale because the operative claim (APIs available where the code runs) remains true.

**Evidence:** proxy.ts:41-46; node_modules/next/dist/build/analysis/get-page-static-info.js:573-576; package.json:23 (`"next": "16.2.4"`).

## Claim 9: x-nonce is forwarded "so layouts can read it via headers() and pass it to <Script> tags they render"

**Location:** proxy.ts:46-49
**Type:** Reference / dataflow
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** Readers tracing where x-nonce is consumed
**Replicate verdicts:** r1 = Mostly accurate (High) · r2 = Mostly accurate (High) · r3 = Stale (High)

The mechanism described would work: `requestHeaders.set("x-nonce", nonce)` on headers passed through `NextResponse.next({ request: { headers: requestHeaders } })` (proxy.ts:48-54) is the documented way to make a value readable via `headers()` in server components. But nothing consumes it: `rg -n "x-nonce"` across the repo matches only the write site (proxy.ts:49) and the layout comment explicitly declining to read it (app/layout.tsx:30). No layout renders `<Script>` tags; no `next/script` usage exists anywhere in app/. The comment describes a consumer that does not exist — and per Claim 1, x-nonce is also not the header Next itself would need. Consistent with commit d90d6bb's own correction and the lite iteration-2 Low finding.

**Evidence:** proxy.ts:46-54; app/layout.tsx:28-30; repo-wide x-nonce grep = 2 matches; `rg -n "Script|next/script" app/ -g '*.tsx'` = no matches (paraphrased — absence evidence).

## Claim 10: Matcher applies CSP to page navigations only, skipping API routes, static assets, and prefetches

**Location:** proxy.ts:58-70
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Reviewers checking CSP coverage
**Replicate verdicts:** r1 = Mostly accurate (High) · r2 = Mostly accurate (High) · r3 = Mostly accurate (High)

Unanimous. The pattern `"/((?!api|_next/static|_next/image|favicon.ico).*)"` (proxy.ts:63-64) and the `missing` entries (proxy.ts:64-68) implement the stated intent, with caveats: (1) **Prefix matching** — the negative lookahead excludes any path *starting with* the listed strings (`/apiary`, `/api-docs` would also silently lose the CSP); latent, not live, with a single `/` route today. Matches the lite iteration-2 Low finding. (2) **`missing` semantics verified** — Next skips the proxy if *any* listed header is present (`has.every(...) && !missing.some((item)=>hasMatch(item))`, node_modules/next/dist/shared/lib/router/utils/prepare-destination.js:118); the header name matches Next's constant (`NEXT_ROUTER_PREFETCH_HEADER = 'next-router-prefetch'`, app-router-headers.js:106). (3) Other `_next/*` paths (e.g. RSC payloads) still receive the CSP header — harmless, but "page navigations only" is approximate.

**Evidence:** proxy.ts:58-70; node_modules/next/dist/shared/lib/router/utils/prepare-destination.js:57-122; node_modules/next/dist/client/components/app-router-headers.js:106.

## Claim 11: Commit e5d95a9 — fix description and waive rationale

**Location:** commit e5d95a9 message, Blocker 1 and Blocker 2 paragraphs
**Type:** Commit-message behavioral claims
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Review-loop auditors
**Replicate verdicts:** r1 = Verified (High) · r2 = Verified (High) · r3 = Verified (High; split across its Claims 12 and 13, both Verified)

Unanimous. Blocker 1 ("buildCsp now appends 'unsafe-eval' to script-src when process.env.NODE_ENV === 'development' only") matches the diff exactly (proxy.ts:25-29), with the rationale recorded in the header comment as claimed (proxy.ts:19-23). Blocker 2's waive rationale sub-claims all verified independently (see Claims 2-3): exactly one page route, `"use client"`, no static config anywhere under app/, sound mutual-exclusion premise. r2/r3 note the waive is sound *given the feature design*; the deeper nonce-delivery issue (Claim 1) is outside what this commit claimed to fix.

**Evidence:** commit e5d95a9 message; proxy.ts:19-29; app/layout.tsx:27-41; app/page.tsx:1; grep results per Claim 3.

## Claim 12: Commit e5d95a9 — verification counts ("npm test 24 files / 221 tests passing"; tsc/lint clean)

**Location:** commit e5d95a9 message, Verification paragraph
**Type:** Verification-status claims (static check only, per scope)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Review-loop auditors
**Replicate verdicts:** r1 = Mostly accurate (Medium) · r2 = Mostly accurate (Medium) · r3 = Verified (Medium)

Static corroboration is exact in all three replicates: 24 test files (`rg --files -g '*.test.*'`) and 221 `it(`/`test(` call sites with zero `it.each`/`test.each`. Both figures match the message to the digit. The *passing* status, `npx tsc --noEmit` cleanliness, and the "2 pre-existing exhaustive-deps warnings in app/page.tsx" are process claims not verifiable statically — counts confirmed, execution results taken on trust per the static-only scope (r1/r2's basis for Mostly accurate rather than Verified; r3 scoped its claim to counts only).

**Evidence:** commit e5d95a9 message; file/test counts (paraphrased — aggregate rg counts: 24 files; 221 summed matches; 0 `.each` matches).

## Claim 13: Commit 9b4e453 — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates"

**Location:** commit 9b4e453 message, verification paragraph
**Type:** Verification / behavioral commit-message claim
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** Anyone relying on the feature commit's claimed end-to-end verification
**Replicate verdicts:** r1 = Unverifiable (Medium) · r2 = Incorrect (Medium) · r3 = Incorrect (Medium)

The first half (header emitted) is consistent with proxy.ts:55-56. The second half is statically contradicted per r2/r3: Next derives the render nonce solely from the request's `content-security-policy` header (app-render.js:166-167), which this proxy never sets — statically, the renderer's nonce is `undefined` and no script tag can be nonce-tagged. Either the verification observed something other than nonce-tagged scripts, or it was performed against different wiring than what was committed. r1's Unverifiable rests on its router-mirroring finding (Claim 1 dissent), under which the claim is mechanism-consistent self-hosted but deployment-dependent and unverified. All replicates note the commit itself concedes "Manual end-to-end browser verification on the Vercel preview is still recommended." Confidence Medium across the board because this adjudicates a claimed runtime observation by static analysis.

**Evidence:** commit 9b4e453 message; proxy.ts:44-56; node_modules/next/dist/server/app-render/app-render.js:155-167, 1557; Claim 1 evidence chain.

## Claim 14: Commit 9b4e453 — XSS-surface premises ("no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false"; middleware deprecation)

**Location:** commit 9b4e453 message, first and second paragraphs
**Type:** Configuration / reference commit-message claims
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Security reviewers assessing the pre-existing XSS surface
**Replicate verdicts:** r1 = Mostly accurate (sub-verdicts within its Claim 13) · r2 = Verified/Mostly accurate (sub-verdicts within its Claim 13) · r3 = Mostly accurate (High)

All replicates agree: "no dangerouslySetInnerHTML, no rehype-raw" — verified by absence (zero matches under app/; only `rehype-katex` in package.json:30 and LatexRenderer.tsx:6). "KaTeX trust:false" — Mostly accurate: no explicit `trust` option is set anywhere (`const rehypePlugins = [rehypeKatex];`, LatexRenderer.tsx:10); `trust: false` is KaTeX's *default*, so the property holds but the phrasing implies an explicit setting that does not exist. r3 additionally confirmed the middleware-deprecation claim via Next's shipped warning (`The "${MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${PROXY_FILENAME}" instead.`, node_modules/next/dist/build/index.js).

**Evidence:** commit 9b4e453 message; app/components/features/output-editing/LatexRenderer.tsx:6-10; package.json:30; absence-of-match greps (paraphrased); node_modules/next/dist/build/index.js warnOnce text; node_modules/next/dist/lib/constants.js:289.

## Claim 15: "Next.js 16 renamed Middleware → Proxy"

**Location:** proxy.ts:5
**Type:** Reference / configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Maintainer wondering why the file is not middleware.ts
**Replicate verdicts:** r1 = not covered · r2 = Verified (High) · r3 = not covered (corroborating evidence in its Claim 16)

package.json pins `"next": "16.2.4"` (package.json:23). The installed Next source refers to "this proxy (previously called middleware)" and links https://nextjs.org/docs/messages/middleware-to-proxy (node_modules/next/dist/build/analysis/get-page-static-info.js:299). r3's middleware-deprecation-warning evidence (Claim 14) independently corroborates.

**Evidence:** package.json:23; node_modules/next/dist/build/analysis/get-page-static-info.js:299, 576.

## Claims Requiring Attention

1. **Claim 1 (Incorrect, High; verdicts split MA/I/I)** — app/layout.tsx:27-30: Next reads the nonce from the *request's* CSP header, never the response's; this app never puts the CSP on the request, so statically no script gets nonce-tagged, and with `'strict-dynamic'` ignoring `'self'`, the shipped policy would block Next's own bootstrap scripts in production. r1's dissent: an undocumented Node-router mirroring path (resolve-routes.js:445-446 copies proxy response headers into `req.headers`) may make it work self-hosted — but not on split-infrastructure deployments (e.g., Vercel). Load-bearing defect behind Claims 4 and 13. Fix direction: also `requestHeaders.set("Content-Security-Policy", csp)` before `NextResponse.next(...)` (the official Next CSP pattern).
2. **Claim 6 (Incorrect, High; unanimous)** — proxy.ts:16-18: `connect-src 'self'` blocks the browser-side `fetch(dataUrl)` calls in app/lib/utils/exportGraph.ts:24,37, breaking graph PNG export and the export-all zip. Needs `connect-src 'self' data:` or a non-fetch decode path (`toBlob`).
3. **Claim 4 (Incorrect, High; verdicts split V/MA/I)** — proxy.ts:7-11: the docstring's protection story presumes nonce-tagged Next scripts, which under the statically-verifiable wiring do not exist; resolution tracks Claim 1.
4. **Claim 13 (Incorrect, Medium; verdicts split U/I/I)** — commit 9b4e453's claimed end-to-end verification ("Next applies the nonce to every `<script>` tag") is statically contradicted (or, per r1, deployment-dependent and unverified); it should not be relied on. Warrants a functional verification (prod build + browser check) before merge.
5. **Claim 8 (Incorrect, High; verdicts split S/S/I)** — proxy.ts:42-45: comment says proxy runs on the Edge runtime; Next 16 Proxy always runs on Node.js. Code unaffected; one-line comment fix.
6. **Claim 5 (Incorrect, Medium; verdicts split I/MA/I)** — "Tailwind v4 emits inline styles" is the wrong rationale for `style-src 'unsafe-inline'`. Do NOT remove the carve-out (React `style={}` attributes, reactflow, KaTeX, dev `<style>` injection require it); rewrite the comment so a future tightening attempt targets the real dependents.
7. **Claim 9 (Stale, High; verdicts split MA/MA/S)** — `x-nonce` request header has no reader anywhere; delete the forwarding or reword the comment as provision for future `<Script>` use.

## Verdict stability

- **Clusters:** 15. **Replicate coverage:** 13 clusters covered by all three replicates (k=3); Claim 14 standalone in r3 only (r1/r2 bundled it into their commit-9b4e453 claims); Claim 15 covered by r2 only.
- **Unanimous verdicts:** 8 of 15 clusters (Claims 2, 3, 6, 7, 10, 11, 14, 15 — counting single/bundled-coverage clusters as trivially agreeing). Restricted to the 13 k=3 clusters: 6 of 13 unanimous (46%).
- **Split verdicts (7):** Claims 1, 4, 13 (the nonce-delivery cluster — the only *materially* divergent split: r1's router-mirroring evidence vs r2/r3's statically-broken reading; most-severe wins but the dissent is recorded in Claim 1 prose); Claim 8 (Stale vs Incorrect — same facts, severity-labeling difference); Claim 9 (Mostly accurate vs Stale — same facts); Claim 5 (Incorrect vs Mostly accurate — same facts, attribution-severity difference); Claim 12 (Mostly accurate vs Verified — scope-labeling difference).
- **Stability assessment:** All splits except the nonce-delivery cluster are labeling differences over identical evidence. The nonce-delivery split is a genuine evidentiary divergence (one replicate found an additional code path) and is the single finding where replication changed the picture; it should be resolved empirically (prod build + browser check), not by vote.

## Goal-Alignment Note

- Answered (union of replicates): all 8 briefed claim areas — client network-call enumeration incl. data:/blob: export paths; nonce/prerender mechanism incl. which header Next actually reads (and r1's router-mirroring path); Proxy runtime vs the Edge-runtime comment; x-nonce consumers; style-src rationale; dev-eval gate and eval-free-production premise; matcher pattern + `missing` semantics; e5d95a9 and 9b4e453 commit-message claims with static test counts. Both lite iteration-2 hints corroborated (Claims 9, 10).
- Out of scope (all replicates): running build/tests/lint (execution-status claims taken on static corroboration only); browser-level CSP enforcement (reported as spec knowledge with reduced confidence); whether skipping CSP on prefetch responses is a security gap; worker-src coverage for the pdfjs worker (no comment claims it — noted as residual risk adjacent to Claim 7); how the CSP *should* be fixed (code-review territory); Turbopack dev-eval behavior beyond static evidence.
- Escalate: (1) The Claim 1/4/13 nonce-delivery cluster to the security/correctness critics as a single root cause — statically, the nonce never reaches Next's renderer; the deployed CSP either blocks Next's own bootstrap scripts in production or (if r1's mirroring path operates) works self-hosted while resting on undocumented router behavior that is not guaranteed on Vercel-style deployments; exceeds fact-check scope and warrants functional verification (prod build + browser check) before merge. (2) Claim 6 (feature-breaking connect-src, unanimous) to the fix stage as a likely blocker — a user-visible export regression the lite passes did not catch.
