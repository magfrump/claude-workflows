# Code Fact-Check Report

**Repository:** wt-csp-arm1 worktree (/workspace/runs/review-arms/e3-loops/wt-csp-arm1), branch e3/csp-arm1
**Scope:** `git diff d86d2dc..HEAD` — CSP feature (proxy.ts, app/layout.tsx) plus commit messages 9b4e453, b25e939, d90d6bb, e5d95a9
**Checked:** 2026-08-06
**Total claims checked:** 16
**Summary:** 6 Verified, 4 Mostly accurate, 1 Stale, 5 Incorrect. The headline finding (Claims 2, 5, 15): the nonce wiring does not do what the comments and the feature commit claim. Next.js extracts the script nonce from the **request** `content-security-policy` header (`node_modules/next/dist/server/app-render/app-render.js:166` reads `req.headers`), but proxy.ts sets the CSP only on the **response** and forwards only `x-nonce` on the request — so Next's renderer never receives a nonce and never tags its bootstrap scripts. Under `script-src 'self' 'nonce-…' 'strict-dynamic'` (where `'self'` is ignored), that plausibly blocks Next's own scripts in production. Secondary Incorrect findings: the `connect-src 'self'` sufficiency claim misses two client-side `fetch(data:…)` calls in the PNG export path; the `style-src 'unsafe-inline'` rationale misattributes the need to Tailwind v4; the "Edge runtime" comment contradicts Next 16, whose own error text says "Proxy always runs on Node.js runtime."

**Commit:** e5d95a9

## Claim 1: layout opts out of static rendering so the proxy can attach a fresh nonce

**Location:** app/layout.tsx:27-28
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Maintainer deciding whether `await headers()` can be removed

Claim: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce." Calling `headers()` in a server layout does mark the whole route dynamic (this is standard Next dynamic-API behavior; paraphrased — no quote available because the mechanism lives across Next's request-store internals rather than one quotable line). The call is present: `await headers();` (app/layout.tsx:41). Note the proxy itself runs on every matched request regardless of rendering mode; what the opt-out actually buys is that the *document* is re-rendered per request so a per-request nonce is meaningful — which the second paragraph of the same comment states correctly.

**Evidence:** `await headers();` — app/layout.tsx:41; `import { headers } from "next/headers";` — app/layout.tsx:3.

## Claim 2: "Next.js automatically tags its own bootstrap `<script>` elements with the nonce from the response's CSP header"

**Location:** app/layout.tsx:28-30
**Type:** Behavioral / invariant
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Anyone trusting that the CSP is functional in production

Two errors, one cosmetic and one load-bearing. (1) Mechanism: Next reads the nonce from the **request** headers, not the response: `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];` followed by `getScriptNonceFromHeader(csp)` — node_modules/next/dist/server/app-render/app-render.js:166-167, where `headers` derives from `parseRequestHeaders(req.headers, {` — app-render.js:1557. (2) Wiring: this app never sets `content-security-policy` on the forwarded request headers — proxy.ts sets only `requestHeaders.set("x-nonce", nonce);` (proxy.ts:49) and puts the CSP on the response alone: `response.headers.set("Content-Security-Policy", buildCsp(nonce));` (proxy.ts:55). So `getScriptNonceFromHeader` receives nothing, Next tags no scripts with the nonce, and the comment's "we don't need to read x-nonce here ourselves" conclusion rests on a mechanism that is not wired up. Practical consequence (flagged for the critics, not adjudicated here): with `'strict-dynamic'` present, `'self'` is ignored for script loading, so un-nonced Next bootstrap scripts would be blocked. This also contradicts the feature commit's runtime-verification claim (Claim 15).

**Evidence:** app/layout.tsx:28-30 ("Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header"); node_modules/next/dist/server/app-render/app-render.js:166-167, 1557; proxy.ts:49, 55; nonce parser at node_modules/next/dist/server/app-render/get-script-nonce-from-header.js ("First try to find the directive for the 'script-src'…").

## Claim 3: per-request nonces and static rendering are mutually exclusive; stale-nonce mechanism

**Location:** app/layout.tsx:32-36
**Type:** Architectural / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer evaluating the waived dynamic-rendering blocker

"a statically prerendered document is built once, so its `<script>` tags would carry a stale nonce (or none) and be blocked by the CSP on every request after the first." Given the design (fresh nonce per request at proxy.ts:46, embedded in the response CSP at proxy.ts:55), a prerendered document's embedded nonce could not match subsequent responses' `'nonce-…'` values by construction. The reasoning is internally sound and independent of the Claim 2 wiring defect (which affects whether nonces reach scripts at all, not this incompatibility).

**Evidence:** `const nonce = Buffer.from(crypto.randomUUID()).toString("base64");` — proxy.ts:46; `` `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${devOnly}` `` — proxy.ts:29.

## Claim 4: "the app is a single 'use client' route with no generateStaticParams, revalidate, or ISR — so there is nothing static to lose"

**Location:** app/layout.tsx:36-38
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer evaluating the performance cost of forced dynamic rendering

`rg --files -g 'page.tsx' app` returns exactly one route file, app/page.tsx, whose first line is `"use client";` (app/page.tsx:1). A repo-wide grep for `generateStaticParams|revalidate|force-static|dynamic =` under app/ matches only the layout comment itself (app/layout.tsx:37).

**Evidence:** app/page.tsx:1 (`"use client";`); grep results as described (paraphrased — no quote available because the evidence is the absence of matches).

## Claim 5: nonce + 'strict-dynamic' docstring — "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust"

**Location:** proxy.ts:7-10
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Security reviewer assessing the XSS guardrail's actual protection

The CSP semantics described (nonce gates initial scripts; `'strict-dynamic'` propagates trust to loaded scripts) are textbook-accurate, but the premise — "scripts that Next.js has explicitly tagged with the nonce" — is false for this wiring: Next tags nothing because it never sees the nonce (see Claim 2 evidence: app-render reads the request `content-security-policy` header, which this proxy does not set). As implemented, the policy does not distinguish Next's own scripts from injected ones by nonce; it blocks both categories of parser-inserted script equally.

**Evidence:** proxy.ts:7-10 ("only scripts that Next.js has explicitly tagged with the nonce can run"); proxy.ts:49, 55; node_modules/next/dist/server/app-render/app-render.js:166-167.

## Claim 6: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles"

**Location:** proxy.ts:12-15
**Type:** Configuration / architectural rationale
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** Maintainer considering tightening style-src

Tailwind v4 in this app is compiled to a regular stylesheet: app/globals.css begins `@import "tailwindcss";` / `@plugin "@tailwindcss/typography";` (app/globals.css:1-2), processed by `@tailwindcss/postcss` (postcss.config.mjs; package.json:49 `"tailwindcss": "^4"`), and shipped as linked CSS — not HTML inline styles. The carve-out is nonetheless genuinely needed, but for other reasons: at least 10 components use React `style={…}` attributes (e.g. app/components/panels/ArtifactPanelShell.tsx, app/components/features/causal-graph/CausalGraphNode.tsx, app/components/features/output-editing/EditableOutput.tsx — `rg 'style=\{' -l`), which `style-src` without `'unsafe-inline'` blocks (attribute styles fall under style-src absent a style-src-attr directive; paraphrased — no quote available because this is CSP spec behavior, not repo code), plus dev-mode `<style>` injection. Wrong reason, right directive — the misattribution matters because "rework how Tailwind ships styles" (proxy.ts:13-14) would not by itself allow tightening.

**Evidence:** app/globals.css:1-2; proxy.ts:12-15; `rg -l "style=\{"` listing 10 component files.

## Claim 7: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server"

**Location:** proxy.ts:16-17
**Type:** Behavioral / invariant
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Anyone relying on the CSP not to break existing features

The server-to-server half checks out: `OPENROUTER_API_URL` is fetched only in app/lib/llm/callLlm.ts:164 and app/lib/llm/streamLlm.ts:249, whose importers are API routes and server-side formalization modules (app/api/refine/context/route.ts, app/api/edit/inline/route.ts, app/api/formalization/lean/route.ts, app/api/decomposition/extract/route.ts, app/lib/formalization/artifactRoute.ts); callLlm.ts also imports the Node builtin `crypto` (callLlm.ts:1), confirming server-only. The Lean verifier fetch is likewise in a route handler (app/api/verification/lean/route.ts:21). But "sufficient" fails on enumeration of client-side initiations: app/lib/utils/exportGraph.ts fetches **data: URLs** in the browser — `const dataUrl = await toPng(viewportElement, {…}); const res = await fetch(dataUrl);` (exportGraph.ts:20-24, and again at :33-37) — invoked from the client component GraphPanel (app/components/panels/GraphPanel.tsx imports `downloadGraphAsPng`/`graphToPngBlob`). `connect-src 'self'` does not match `data:` URLs (scheme sources must be listed explicitly; paraphrased — no quote available because this is CSP source-matching spec behavior), so PNG export of the graph would be blocked under this policy. Remaining client fetches are same-origin `/api/...` (app/hooks/useAnalytics.ts:11,30; app/lib/formalization/api.ts:10,38,104; app/components/features/lean-display/LeanCodeDisplay.tsx:88; app/components/features/context-input/ContextInput.tsx:25) — fine under `'self'`. No WebSocket/EventSource/sendBeacon/XHR uses found in app/. Adjacent, outside connect-src: pdfjs spawns a bundled same-origin Worker (app/lib/utils/fileExtraction.ts:26-28, pdfPropositionParser.ts:443-445) — governed by worker-src/script-src fallback, noted for the critics.

**Evidence:** app/lib/utils/exportGraph.ts:24 (`const res = await fetch(dataUrl);`), :37; app/lib/llm/callLlm.ts:7 (`export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";`), :164; importer list from `rg -l "callLlm|streamLlm"` (API routes + lib only, no components).

## Claim 8: dev-only 'unsafe-eval' — "Next's dev server loads modules and applies Fast Refresh through eval-based bundles… Production builds contain no eval, so the carve-out is gated on NODE_ENV and never ships"

**Location:** proxy.ts:19-23, 26-27
**Type:** Behavioral / configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Security reviewer confirming the carve-out cannot reach production

The gate itself is correctly implemented and dev-only: `const devOnly = process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : "";` (proxy.ts:26-27), appended only to script-src (proxy.ts:29); `next dev`/`next build` set NODE_ENV accordingly (package.json:6-8 uses stock `next dev`/`next build`/`next start`). The eval-based-dev-bundles mechanism is corroborated for the webpack path by Next's own shipped plugin node_modules/next/dist/build/webpack/plugins/eval-source-map-dev-tool-plugin.js. Two unverified edges keep this from full Verified: Next 16 defaults dev to Turbopack (no `--turbopack`/`--webpack` flag in package.json:6), and I could not statically confirm Turbopack's dev output uses eval; and "production builds contain no eval" is a claim about the emitted bundle (no .next/ present to grep) — plausible (prod webpack/turbopack use non-eval devtools) but not statically proven, including for third-party deps.

**Evidence:** proxy.ts:26-29; package.json:6-8 (`"dev": "next dev"`, `"build": "next build"`); existence of eval-source-map-dev-tool-plugin.js in node_modules/next/dist/build/webpack/plugins/.

## Claim 9: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in"

**Location:** proxy.ts:44-45
**Type:** Configuration / runtime
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Maintainer reasoning about what APIs the proxy may use

Next 16's proxy does not run in the Edge runtime. Next's own build-time error text states it flatly: "Route segment config is not allowed in Proxy file at … Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy" — node_modules/next/dist/build/analysis/get-page-static-info.js:576. The comment's operative conclusion survives by accident: `crypto.randomUUID` and `Buffer` are both available in Node.js, so proxy.ts:46 works — but the runtime identification is wrong (a holdover from the middleware-era Edge default), and future readers could draw wrong inferences (e.g. avoiding Node-only APIs unnecessarily).

**Evidence:** node_modules/next/dist/build/analysis/get-page-static-info.js:576 ("Proxy always runs on Node.js runtime"); proxy.ts:44-46.

## Claim 10: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to `<Script>` tags they render"

**Location:** proxy.ts:47-48
**Type:** Reference / architectural intent
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** Reader tracing where x-nonce is consumed

The mechanism described would work (request headers set via `NextResponse.next({ request: { headers } })` are readable by `headers()` in layouts), but nothing consumes it: `rg -n "x-nonce"` across the repo (excluding node_modules) matches only the write site (proxy.ts:49) and the layout comment explicitly declining to read it ("we don't need to read x-nonce here ourselves" — app/layout.tsx:30). No `<Script>` tags are rendered by any layout. The comment describes a consumer that does not exist — and given Claim 2, x-nonce is also not the header Next itself would need. Corroborates the iteration-2 lite hint (comment overstates a consumer).

**Evidence:** proxy.ts:47-49; app/layout.tsx:30; x-nonce grep yielding exactly those two hits.

## Claim 11: matcher comment — "Apply CSP to page navigations only. Skip API routes…, Next's static assets…, and prefetches"

**Location:** proxy.ts:58-61
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Maintainer editing the matcher

The pattern `"/((?!api|_next/static|_next/image|favicon.ico).*)"` (proxy.ts:63) excludes the named paths, and the `missing` entries (proxy.ts:64-67: `next-router-prefetch` header; `purpose: prefetch`) mean the rule matches only when those headers are absent — i.e. prefetch requests are skipped, matching the comment and the standard Next CSP-middleware pattern. Docked to Mostly accurate on one nuance (the iteration-2 lite hint): the negative lookahead is a prefix match with no boundary, so it also excludes any hypothetical route beginning with those strings (e.g. `/apiary`, `/api-docs` would get no CSP). With a single `/` route today this is latent, not live.

**Evidence:** proxy.ts:63-67; comment at proxy.ts:58-61.

## Claim 12: commit e5d95a9 — Blocker 1 fix description ("buildCsp now appends 'unsafe-eval' to script-src when process.env.NODE_ENV === 'development' only")

**Location:** commit e5d95a9 message, Blocker 1 paragraph
**Type:** Behavioral (commit-message claim)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer auditing the lite-fix commit against its diff

The diff matches the description exactly: the ternary at proxy.ts:26-27 gates on `process.env.NODE_ENV === "development"`, the string is appended only into the script-src directive (proxy.ts:29), and the rationale was added to the header comment (proxy.ts:19-23) alongside the existing style-src/connect-src paragraphs, as the message says.

**Evidence:** proxy.ts:26-29, 19-23; e5d95a9 diff hunk adding those lines.

## Claim 13: commit e5d95a9 — Blocker 2 waive rationale (nonce/static incompatibility; app has exactly one page route; no static config anywhere under app/)

**Location:** commit e5d95a9 message, Blocker 2 paragraph
**Type:** Architectural / configuration (commit-message claim)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer deciding whether the waiver was justified

Every checkable sub-claim holds: exactly one page route (app/page.tsx, the only `page.tsx` under app/); it is `"use client"` (app/page.tsx:1); no `generateStaticParams`, `revalidate`, ISR, or `force-static` anywhere under app/ (grep matches only the layout comment text); the nonce/static mutual-exclusion argument is sound (Claim 3). The waiver's framing "removing it would break the CSP" is consistent with the design — though note the CSP has a deeper delivery problem regardless (Claim 2), which the waiver text does not (and was not asked to) address.

**Evidence:** app/page.tsx:1; page-route glob result (single file); grep absence result (paraphrased — no quote available because the evidence is the absence of matches).

## Claim 14: commit e5d95a9 — "npm test 24 files / 221 tests passing" (static check of counts)

**Location:** commit e5d95a9 message, Verification paragraph
**Type:** Reference (commit-message claim)
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** Reviewer sanity-checking the stated verification

Static counts match exactly: `rg --files -g '*.test.*'` under app/ and scripts/ finds **24** test files, and counting `it(`/`test(` case declarations across them totals **221**. (Pass/fail status and the tsc/lint claims are runtime results not verified here — counts only, per scope. Confidence Medium because statically counted cases can diverge from runner-reported totals via skips or `each`-style expansion; here they agree to the digit.)

**Evidence:** file count 24 and case count 221 from ripgrep over `*.test.*` (paraphrased — no quote available because the evidence is aggregate command output, not a code line).

## Claim 15: commit 9b4e453 — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates"

**Location:** commit 9b4e453 message, verification paragraph
**Type:** Behavioral (commit-message claim)
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** Anyone trusting the feature's claimed end-to-end verification

The first half (header emitted) is consistent with the code (proxy.ts:55 sets the response header). The second half is statically contradicted: Next's nonce extraction reads the request `content-security-policy` header (app-render.js:166-167 via `req.headers`, app-render.js:1557), which this proxy never sets — `getScriptNonceFromHeader` therefore returns `undefined` and no nonce attribute can be applied to generated script tags. Either the verification observed something other than nonce-tagged scripts, or it was performed against different wiring than what was committed. Confidence Medium rather than High only because this adjudicates a claimed runtime observation by static analysis; the static contradiction itself is High-confidence (Claim 2). Notably the same commit recommends "Manual end-to-end browser verification on the Vercel preview is still recommended — CSP issues sometimes only appear once Next's full bootstrap is exercised," which is exactly where this would surface.

**Evidence:** node_modules/next/dist/server/app-render/app-render.js:166-167, 1557; proxy.ts:49, 55; commit 9b4e453 message text.

## Claim 16: commit 9b4e453 — "no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false" and "middleware.ts builds with a deprecation warning"

**Location:** commit 9b4e453 message, first and second paragraphs
**Type:** Configuration / reference (commit-message claims)
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Security reviewer assessing the pre-existing XSS surface

`dangerouslySetInnerHTML` and `rehype-raw`: zero matches under app/ (excluding tests) — verified by absence. "KaTeX trust:false": no `trust` option is set anywhere in app code (the KaTeX usage is via `rehypeKatex` — app/components/features/output-editing/LatexRenderer.tsx:6 — with no trust option passed); KaTeX's default is `trust: false` (paraphrased — no quote available because the default lives in KaTeX documentation/source, not repo code), so the effective behavior matches but the phrasing implies an explicit setting that does not exist — hence Mostly accurate. The middleware-deprecation claim is confirmed by Next's shipped warning: `The "${MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${PROXY_FILENAME}" instead.` — node_modules/next/dist/build/index.js (warnOnce call).

**Evidence:** LatexRenderer.tsx:6-7; absence-of-match greps (paraphrased as above); node_modules/next/dist/build/index.js warnOnce text; node_modules/next/dist/lib/constants.js:289 (`const PROXY_FILENAME = 'proxy';`).

## Claims Requiring Attention

- **Claim 2 (Incorrect, High)** — app/layout.tsx:28-30: Next reads the nonce from the *request* CSP header, which this app never sets; nonce delivery to Next's renderer is not wired. Likely production-breaking under `'strict-dynamic'`. Highest-priority finding; invalidates the comment's "we don't need to read x-nonce" conclusion.
- **Claim 5 (Incorrect, High)** — proxy.ts:7-10: docstring's protection story presumes nonce-tagged Next scripts, which do not exist under current wiring.
- **Claim 15 (Incorrect, Medium)** — commit 9b4e453's claimed verification ("Next applies the nonce to every script tag") is statically contradicted.
- **Claim 7 (Incorrect, High)** — proxy.ts:16-17: `connect-src 'self'` blocks the client-side `fetch(data:…)` calls in app/lib/utils/exportGraph.ts:24,37 (graph PNG export).
- **Claim 6 (Incorrect, Medium)** — proxy.ts:12-15: `'unsafe-inline'` for style-src is needed for React `style={}` attributes and dev style injection, not because "Tailwind v4 emits inline styles."
- **Claim 9 (Incorrect, High)** — proxy.ts:44-45: proxy runs on Node.js, not Edge, per Next 16's own error text; conclusion harmless, premise wrong.
- **Claim 10 (Stale, High)** — proxy.ts:47-48: x-nonce has no consumer anywhere in the repo.

## Goal-Alignment Note
- Answered: All 8 briefed claim areas: connect-src enumeration incl. data:/blob: export paths (Claim 7), layout dynamic-rendering rationale and the nonce-delivery mechanism incl. which header Next actually reads (Claims 1-4), Edge-runtime claim vs Next 16 Proxy (Claim 9), x-nonce consumers (Claim 10), Tailwind style-src rationale (Claim 6), dev-eval gate and eval-free-production premise (Claim 8), matcher semantics incl. missing-entries and prefix-match nuance (Claim 11), and e5d95a9's commit-message claims with static test counts (Claims 12-14), plus the feature commit's verification claim (Claim 15) and XSS-surface claims (Claim 16). Both lite hints were corroborated (Claims 10, 11).
- Out of scope: Whether the CSP *should* be fixed and how (request-header CSP forwarding per the Next docs pattern, adding `data:` to connect-src, worker-src for the pdfjs worker) — code-review territory; runtime verification of tsc/lint/test pass-status; Turbopack dev-eval behavior beyond static evidence.
- Escalate: The Claim 2/5/15 cluster to the security/correctness critics as a single root cause: the nonce never reaches Next's renderer, so the deployed CSP likely blocks Next's own bootstrap scripts in production (or, at minimum, provides none of the claimed nonce-based protection). Also escalate Claim 7 (export feature breakage) as a user-visible regression the lite passes did not catch.
