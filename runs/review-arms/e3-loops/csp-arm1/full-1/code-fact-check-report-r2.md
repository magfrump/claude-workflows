# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree /workspace/runs/review-arms/e3-loops/wt-csp-arm1, branch e3/csp-arm1)
**Scope:** `git diff d86d2dc..HEAD` — app/layout.tsx, proxy.ts (new), plus commit messages 9b4e453, b25e939, d90d6bb, e5d95a9
**Checked:** 2026-08-06
**Total claims checked:** 13
**Summary:** 4 Verified, 5 Mostly accurate, 1 Stale, 3 Incorrect. The three Incorrect findings share one root: the proxy never forwards the CSP header on the *request*, so Next.js (which reads the nonce exclusively from the incoming request's `content-security-policy` header) never sees the nonce — contradicting the layout comment's "nonce from the response's CSP header" mechanism claim and 9b4e453's "Next applies the nonce to every `<script>` tag" verification claim. Separately, `connect-src 'self'` is not sufficient: the graph PNG export fetches `data:` URLs from the browser, which `'self'` does not permit.

**Commit:** e5d95a9

## Claim 1: Next.js auto-tags its scripts with the nonce from the response CSP header

**Location:** app/layout.tsx:24-27
**Type:** Behavioral / mechanism
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Future maintainer deciding whether the layout must consume x-nonce

The comment claims:

> "Next.js automatically tags its own bootstrap `<script>` elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves." (app/layout.tsx:25-27)

Next.js reads the nonce from the **incoming request's** `content-security-policy` header, not from the response:

> `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];`
> `const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;` (node_modules/next/dist/server/app-render/app-render.js:166-167, inside `parseRequestHeaders(headers, ...)` — request headers, see app-render.js:156)

A repo-wide search shows `getScriptNonceFromHeader` is called only from `app-render.js` and `render.js`, both on request headers (paraphrased — no quote available because the finding is the *absence* of any response-header caller; `rg -l getScriptNonceFromHeader node_modules/next/dist/` returns only those files).

This app's proxy sets the CSP **only on the response** and forwards only `x-nonce` (which Next ignores) on the request:

> `requestHeaders.set("x-nonce", nonce); ... response.headers.set("Content-Security-Policy", buildCsp(nonce));` (proxy.ts:48, 54)

So statically, Next's bootstrap scripts receive **no** nonce. Since the policy is `script-src 'self' 'nonce-…' 'strict-dynamic'` (proxy.ts:29) and `'strict-dynamic'` causes CSP3 browsers to ignore `'self'`, un-nonced parser-inserted scripts would be blocked (paraphrased — no quote available because browser CSP enforcement behavior is spec knowledge, not repo code). The fix used in the official Next.js CSP guide is to also set the CSP header on the forwarded request headers.

**Evidence:** proxy.ts:44-55; app/layout.tsx:23-27; node_modules/next/dist/server/app-render/app-render.js:155-167

## Claim 2: Dynamic opt-out rationale — nonces and static prerendering are mutually exclusive; cost is nil

**Location:** app/layout.tsx:28-39 (`await headers()` at line 40)
**Type:** Architectural / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer evaluating the waived "app-wide dynamic rendering" perf finding

The comment claims a statically prerendered document "is built once, so its `<script>` tags would carry a stale nonce (or none) and be blocked … Per-request nonces and static rendering are mutually exclusive by construction" (app/layout.tsx:30-34) and that the cost is nil because "the app is a single `"use client"` route with no generateStaticParams, revalidate, or ISR" (app/layout.tsx:36-37).

- Mechanism: sound — a nonce baked into cached HTML cannot match a fresh per-request header nonce (paraphrased — no quote available because this is CSP semantics, not repo code). `await headers()` is Next's documented dynamic-rendering opt-in.
- Single route: `rg --files -g 'page.tsx' app/` returns only `app/page.tsx`, whose first line is `"use client";` (app/page.tsx:1).
- No static config: `rg -n "generateStaticParams|revalidate|force-static|dynamic =" app/` matches only the comment itself (app/layout.tsx:37).

Note the mechanism claim is verified *as stated*, but per Claim 1 the nonce currently never reaches the renderer at all — the rationale is correct about why dynamic rendering is needed, in a wiring where the nonce delivery itself is broken.

**Evidence:** app/layout.tsx:23-40; app/page.tsx:1; grep results above

## Claim 3: "Next.js 16 renamed Middleware → Proxy"

**Location:** proxy.ts:5
**Type:** Reference / configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Maintainer wondering why the file is not middleware.ts

package.json pins `"next": "16.2.4"` (package.json:23). The installed Next source refers to "this proxy (previously called middleware)" and links `https://nextjs.org/docs/messages/middleware-to-proxy`:

> "`This function is what Next.js runs for every request handled by this ${fileName === 'proxy' ? 'proxy (previously called middleware)' : 'middleware'}`" (node_modules/next/dist/build/analysis/get-page-static-info.js:299)

**Evidence:** package.json:23; node_modules/next/dist/build/analysis/get-page-static-info.js:299, 576

## Claim 4: Nonce + 'strict-dynamic' means only Next-tagged scripts run; injected `<script>` blocked

**Location:** proxy.ts:7-10
**Type:** Behavioral / security invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Security reviewer assessing the CSP's protective value

> "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing" (proxy.ts:7-10)

The description of nonce + `'strict-dynamic'` semantics is correct CSP behavior (paraphrased — no quote available because this is spec behavior). The blocking of injected scripts would indeed hold. The inaccuracy is the premise "scripts that Next.js has explicitly tagged with the nonce": per Claim 1, in this wiring Next tags **nothing** with the nonce, so the described trust chain has no trusted root — the policy would block Next's own scripts along with injected ones.

**Evidence:** proxy.ts:7-10, 29; see Claim 1 evidence

## Claim 5: `style-src 'unsafe-inline'` is needed because "Tailwind v4 emits inline styles"

**Location:** proxy.ts:12-15
**Type:** Configuration rationale
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Maintainer considering tightening style-src later

The carve-out itself is genuinely required, but the attribution is imprecise. Tailwind v4 is consumed via `globals.css` / `@tailwindcss/postcss` (package.json:36,49; CLAUDE.md "Tailwind v4 config via `@theme inline`"), and in a production Next build that compiles to a **linked** stylesheet served from `'self'`, not inline styles (paraphrased — no quote available because the claim concerns build-output form; the build was not run in this pass). What actually requires `'unsafe-inline'` in production:

- React inline `style={...}` attributes in 20 component files (`rg -c "style=\{" app/ -g '*.tsx'` → 20 files, e.g. app/components/panels/GraphPanel.tsx, app/components/features/output-editing/LatexRenderer.tsx) — style attributes fall under style-src absent `style-src-attr`.
- KaTeX-rendered output (rehype-katex, app/components/features/output-editing/LatexRenderer.tsx:6) emits elements with inline style attributes (paraphrased — no quote available because the styles are generated at runtime by the katex library).
- In dev, Next injects `<style>` elements for CSS/HMR (paraphrased — framework behavior, not repo code).

So the conclusion (keep `'unsafe-inline'`) is right; the stated cause is at best a dev-mode fraction of the story.

**Evidence:** proxy.ts:12-15, 31; package.json:36,49; grep results (20 files with `style={`); app/components/features/output-editing/LatexRenderer.tsx:6-10

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server"

**Location:** proxy.ts:17-18
**Type:** Behavioral / configuration
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** Reviewer verifying the CSP doesn't break app features

Enumeration of every client-side network initiation found under app/ (`rg -n "fetch\(|XMLHttpRequest|WebSocket|EventSource|sendBeacon"`):

| Site | Target | Under `connect-src 'self'` |
|---|---|---|
| app/hooks/useAnalytics.ts:11,30 | `/api/analytics` | allowed (self) |
| app/lib/formalization/api.ts:10,38,104 | relative `/api/...` URLs | allowed (self) |
| app/components/features/lean-display/LeanCodeDisplay.tsx:88 | `/api/explanation/lean-error` | allowed (self) |
| app/components/features/context-input/ContextInput.tsx:25 | `/api/refine/context` | allowed (self) |
| app/lib/utils/exportGraph.ts:24,37 | **`data:` URL** from `toPng` | **blocked** |
| app/lib/llm/callLlm.ts:164, streamLlm.ts:249 | OpenRouter | server-only (imported only from `app/api/**/route.ts` — `rg -ln "callLlm|streamLlm"` shows all non-lib importers are API routes) |
| app/api/verification/lean/route.ts:21 | LEAN_VERIFIER_URL | server-only (API route) |

No XMLHttpRequest, WebSocket, EventSource, or sendBeacon uses exist (search returned none). The server-to-server part of the claim is accurate. The "sufficient" part is not:

> `const dataUrl = await toPng(viewportElement, {...}); const res = await fetch(dataUrl);` (app/lib/utils/exportGraph.ts:20-24, and again at 33-37)

`toPng` returns a `data:image/png` URL, and these fetches run in the browser (caller GraphPanel.tsx is `"use client"` — app/components/panels/GraphPanel.tsx:1; also app/lib/utils/exportAll.ts). A `fetch()` of a `data:` URL is governed by connect-src, and `'self'` does not match the `data:` scheme — `connect-src` would need `data:` (or the code refactored to avoid fetch) for graph PNG export and export-all-zip to work (paraphrased — no quote available because CSP scheme-matching is spec behavior). Confidence Medium rather than High only because the blocking behavior is browser-spec knowledge, not statically executable here.

**Evidence:** proxy.ts:17-18, 33; app/lib/utils/exportGraph.ts:16-39; app/components/panels/GraphPanel.tsx:1; grep enumeration above

## Claim 7: Dev-only 'unsafe-eval'; "Production builds contain no eval, so the carve-out … never ships"

**Location:** proxy.ts:19-22, 25-27
**Type:** Configuration / behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Security reviewer confirming the dev carve-out cannot leak to prod

- Gating mechanism: Verified. `const devOnly = process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : "";` (proxy.ts:25-26). `next dev` sets NODE_ENV=development, `next build`/`next start` set production; the proxy runs on the Node.js runtime (see Claim 8), where `process.env.NODE_ENV` is reliably set (paraphrased — framework behavior). So the carve-out cannot appear in a production header.
- Dev premise ("Next's dev server loads modules and applies Fast Refresh through eval-based bundles"): consistent with Next's dev bundling using eval-based source maps (paraphrased — framework behavior, not statically checkable in-repo).
- "Production builds contain no eval": strictly false. The client bundle includes pdfjs-dist, whose build contains `new Function` (eval-equivalent under CSP):

> `function isEvalSupported() { try { new Function(""); return true; } catch { return false; } }` (node_modules/pdfjs-dist/build/pdf.mjs:506-513, used via `FeatureTest.isEvalSupported` and `src.isEvalSupported !== false` at pdf.mjs:14689)

  Because pdfjs feature-detects and falls back, blocking eval degrades font-path compilation gracefully rather than erroring, so the practical conclusion (prod works without 'unsafe-eval') holds — but "contain no eval" is an overstatement.

**Evidence:** proxy.ts:19-27; node_modules/pdfjs-dist/build/pdf.mjs:506-519, 14689; app/lib/utils/fileExtraction.ts:24-30 (pdfjs imported client-side)

## Claim 8: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in"

**Location:** proxy.ts:42-43
**Type:** Runtime / configuration
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** Maintainer reasoning about which APIs the proxy may use

In Next 16, Proxy does not run on the Edge runtime:

> "Route segment config is not allowed in Proxy file at ... **Proxy always runs on Node.js runtime.** Learn more: https://nextjs.org/docs/messages/middleware-to-proxy" (node_modules/next/dist/build/analysis/get-page-static-info.js:576)

The availability conclusion survives trivially — `Buffer` and `crypto.randomUUID` are core Node.js APIs — so the code is fine; only the runtime identification is out of date (it described Edge-runtime middleware from earlier Next versions). Marked Stale rather than Incorrect because the operative claim (these APIs are available where this code runs) remains true.

**Evidence:** proxy.ts:41-43; node_modules/next/dist/build/analysis/get-page-static-info.js:576; package.json:23

## Claim 9: "Forward the nonce … so layouts can read it via `headers()` and pass it to `<Script>` tags they render"

**Location:** proxy.ts:46-47
**Type:** Architectural / reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Maintainer tracing where x-nonce is consumed

The capability is real: `requestHeaders.set("x-nonce", nonce)` on headers passed through `NextResponse.next({ request: { headers: requestHeaders } })` (proxy.ts:48-52) is the documented way to make a value readable via `headers()` in server components. But no consumer exists: `rg -ln "x-nonce"` matches only proxy.ts and app/layout.tsx, and the layout's mention is an explicit refusal to read it ("we don't need to read x-nonce here ourselves", app/layout.tsx:26-27). No `next/script` / `<Script>` usage exists anywhere in app/ (`rg -n "Script|next/script" app/ -g '*.tsx'` → no matches). The comment describes an enabling mechanism that nothing exercises — accurate as a capability statement, overstated as a description of what layouts do. (Matches lite iter-2's Low on this comment overstating a consumer.)

**Evidence:** proxy.ts:45-52; app/layout.tsx:23-27; grep results (x-nonce and Script)

## Claim 10: Matcher applies CSP to "page navigations only; skip API routes … static assets … and prefetches"

**Location:** proxy.ts:58-70
**Type:** Configuration / behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Reviewer verifying CSP coverage boundaries

- Missing-header semantics: Verified. Next's matcher evaluates `has.every(...) && !missing.some((item)=>hasMatch(item))` (node_modules/next/dist/shared/lib/router/utils/prepare-destination.js:118) — i.e., the proxy is skipped when **either** listed header is present, which is the intended prefetch skip. The header name matches Next's constant: `const NEXT_ROUTER_PREFETCH_HEADER = 'next-router-prefetch'` (node_modules/next/dist/client/components/app-router-headers.js:106); with no `value` in the matcher entry, both prefetch values ('1' runtime, '2' segment) are caught.
- Exclusion caveat: the pattern `"/((?!api|_next/static|_next/image|favicon.ico).*)"` (proxy.ts:63) uses an unanchored-alternative negative lookahead, so it excludes any path whose first segment merely **starts with** the listed strings — e.g. `/apidocs` or `/api-status` would also silently lose the CSP header, and other `_next/*` paths (not static/image) still receive it. Today no such routes exist (only app/page.tsx and app/api/*), so behavior currently matches the comment. (Matches lite iter-2's Low on prefix-match exclusions.)

**Evidence:** proxy.ts:58-70; node_modules/next/dist/shared/lib/router/utils/prepare-destination.js:57,118; node_modules/next/dist/client/components/app-router-headers.js:106

## Claim 11: Commit e5d95a9 — fix description and waive rationale

**Location:** commit e5d95a9 message (body, Blockers 1-2)
**Type:** Commit-message claims (behavioral + configuration)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer auditing the lite-loop fix/waive decisions

- Blocker 1 fix description matches the diff exactly: "buildCsp now appends 'unsafe-eval' to script-src when process.env.NODE_ENV === 'development' only" — matches proxy.ts:25-29; "Rationale recorded in the file's header comment" — matches proxy.ts:19-22.
- Waive rationale factual claims all check out statically: "the app has exactly one page route (app/page.tsx)" — `rg --files -g 'page.tsx' app/` → only app/page.tsx; "it is 'use client'" — app/page.tsx:1; "no generateStaticParams, revalidate, ISR, or force-static anywhere under app/" — grep matches only the layout comment itself (app/layout.tsx:37). The incompatibility premise (per-request nonces vs static rendering) is consistent with Next's per-request nonce extraction (app-render.js:166-167).

Note: the waive is sound *given the feature design*; the deeper issue (Claim 1: the nonce never reaches the renderer) is outside what this commit claimed to fix.

**Evidence:** git log e5d95a9; proxy.ts:19-29; app/page.tsx:1; grep results as in Claim 2

## Claim 12: Commit e5d95a9 — "npm test 24 files / 221 tests passing; npx tsc --noEmit clean; npm run lint clean (2 pre-existing exhaustive-deps warnings)"

**Location:** commit e5d95a9 message (Verification paragraph)
**Type:** Verification / test-count claims (checked statically only, per scope)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Reviewer deciding whether to trust the commit's green-state claim

- Test counts corroborated statically: `rg --files -g '*.test.*'` (excluding node_modules) → exactly **24** files; counting `it(`/`test(` declarations across them → exactly **221**, with zero `it.each`/`test.each` (which would inflate runtime counts). The counts are precisely consistent with the claim.
- "passing", "tsc clean", "lint clean", and "2 pre-existing exhaustive-deps warnings in app/page.tsx": not re-executed in this pass (static-only scope) — paraphrased, no quote available because these are runtime tool outcomes. Marked Mostly accurate overall: everything checkable matches; execution outcomes taken on the commit's word.

**Evidence:** file/declaration counts as above; commit e5d95a9 message

## Claim 13: Commit 9b4e453 — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates"; defensive-XSS-surface claims

**Location:** commit 9b4e453 message
**Type:** Verification + behavioral claims
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** Reviewer relying on the feature commit's end-to-end verification

- "emits the CSP header": plausible and consistent with proxy.ts:54 setting the response header.
- "Next applies the nonce to every `<script>` tag it generates": contradicted by static evidence. Next derives the render nonce solely from the **request's** `content-security-policy` header (app-render.js:166-167; sole callers of `getScriptNonceFromHeader` operate on request headers), and this proxy forwards only `x-nonce` on the request (proxy.ts:48-52). Statically, the renderer's nonce is `undefined` and no script tag can be nonce-tagged. Confidence Medium (not High) only because this pass could not run the prod build to observe output; every code path inspected says the claimed verification result cannot occur as described.
- Supporting surface claims: "no dangerouslySetInnerHTML" — Verified (`rg "dangerouslySetInnerHTML" app/` → none); "no rehype-raw" — Verified (only `rehype-katex` in package.json:30 and LatexRenderer.tsx:6); "KaTeX trust:false" — Mostly accurate: no explicit `trust` option is set anywhere (`rg -n "trust" app/` → no katex option hits); `trust: false` is KaTeX's *default*, so the property holds but is not explicitly configured (paraphrased — no quote available because it is a library default plus an absence finding).

**Evidence:** git log 9b4e453; proxy.ts:44-55; node_modules/next/dist/server/app-render/app-render.js:155-167; package.json:30; app/components/features/output-editing/LatexRenderer.tsx:6-10

## Claims Requiring Attention

1. **Claim 1 (Incorrect, High)** — app/layout.tsx:24-27: Next reads the nonce from the *request's* CSP header, never the response's; this app never puts the CSP on the request, so no script gets nonce-tagged. With `'strict-dynamic'` ignoring `'self'`, the shipped policy would block Next's own bootstrap scripts in production. This is the load-bearing defect behind Claims 4 and 13. Fix direction: also `requestHeaders.set("Content-Security-Policy", csp)` before `NextResponse.next(...)` (the official Next CSP pattern).
2. **Claim 6 (Incorrect, Medium)** — proxy.ts:17-18: `connect-src 'self'` blocks the browser-side `fetch(dataUrl)` calls in app/lib/utils/exportGraph.ts:24,37, breaking graph PNG export and export-all. Needs `connect-src 'self' data:` or a non-fetch decode path.
3. **Claim 13 (Incorrect, Medium)** — 9b4e453's "Verified … Next applies the nonce to every `<script>` tag" cannot be true as wired; the verification claim should not be relied on.
4. **Claim 8 (Stale, High)** — "Edge runtime" comment: Next 16 Proxy always runs Node.js; comment should be updated even though the code is unaffected.
5. **Claims 5, 7, 9, 10 (Mostly accurate)** — imprecise rationales (Tailwind attribution; "no eval" vs pdfjs `new Function`; unconsumed x-nonce purpose; prefix-match exclusions) worth a comment sweep, none load-bearing.

## Goal-Alignment Note
- Answered: All 8 briefed check items (client network enumeration incl. data:/blob: fetches; nonce/prerender mechanism and which header Next reads; Proxy runtime; x-nonce consumers; style-src rationale; dev-eval gate and eval-free-prod premise; matcher semantics incl. missing-header logic; e5d95a9 message claims with static test counts).
- Out of scope: Running the prod build/dev server to observe emitted headers or rendered script tags; executing tests/tsc/lint; browser-level CSP enforcement (reported as spec knowledge with reduced confidence); whether `new Worker` for pdfjs is permitted under `'strict-dynamic'` (no comment claims it — noted here as a residual risk adjacent to Claim 7).
- Escalate: Claim 1's root cause implies the CSP feature as shipped likely breaks all script execution in production (or, if scripts do run, the nonce provides no protection) — this exceeds fact-check scope and warrants a functional verification (prod build + browser check) before merge; also the Claim 6 export breakage for the same functional pass.
