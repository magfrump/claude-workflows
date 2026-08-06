# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-csp-dirty, detached at d90d6bb)
**Scope:** `git diff d86d2dc..d90d6bb` — new `proxy.ts` (CSP with per-request nonces) and `app/layout.tsx` made async; commit messages 9b4e453, b25e939, d90d6bb
**Checked:** comments and docstrings in `proxy.ts` and `app/layout.tsx`; factual assertions in the three in-range commit messages; verified against the full repo state at d90d6bb (all of `app/`, `package.json`, `next.config.ts`)
**Total claims checked:** 13
**Summary:** 3 Verified, 5 Mostly accurate, 0 Stale, 4 Incorrect, 1 Unverifiable. The two load-bearing Incorrect findings share one root cause: the CSP header is set only on the *response*, but Next.js discovers the nonce from the *request's* `Content-Security-Policy` header — so Next never tags its bootstrap scripts with the nonce, and (independently) `connect-src 'self'` breaks the graph PNG export, which does a client-side `fetch(dataUrl)` of a `data:` URL. Note: this environment has no network access and the worktree has no `node_modules`, so Next.js-framework-behavior claims rest on documented Next.js behavior known to me rather than quotable source; those are tagged and capped at Medium confidence.

**Commit:** d90d6bb

## Claim 1: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce."

**Location:** app/layout.tsx:27-28
**Type:** Behavioral / mechanism
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

The mechanism half is right: `await headers()` (app/layout.tsx:31, `headers` imported from `next/headers` at app/layout.tsx:3) is a Next.js Dynamic API, and reading it opts the route into dynamic (per-request) rendering — paraphrased — no quote available because this is Next.js framework behavior and the worktree has no `node_modules` and this environment has no network access to nextjs.org docs.

The *purpose* clause is imprecise: proxy.ts runs on every matched request regardless of whether the page is statically or dynamically rendered — middleware/proxy executes before the route is resolved. What dynamic rendering actually buys is that the HTML is re-rendered per request, so a per-request nonce embedded in the HTML can't be served stale from the prerender cache. The opt-out is genuinely required for per-request nonces (commit 9b4e453 states the correct reason: "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached"), but not because it makes the proxy run.

**Evidence:**
- app/layout.tsx:27-31: the comment plus `await headers();`
- Commit 9b4e453 message: "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached."
- Proxy-runs-regardless-of-rendering-mode: paraphrased — no quote available because it is Next.js framework behavior with no local `node_modules` to cite.

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** app/layout.tsx:28-30
**Type:** Behavioral (framework mechanism)
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author

Next.js does not read the nonce from the **response's** CSP header. Its documented nonce-discovery mechanism reads the `Content-Security-Policy` header from the **incoming request headers** — which is why the official Next.js CSP guide's middleware example sets `Content-Security-Policy` on `requestHeaders` and passes them via `NextResponse.next({ request: { headers: requestHeaders } })`, in addition to setting the response header. The app renderer extracts the nonce from that request header and applies it to framework `<script>` tags. (Paraphrased — no quote available because there is no `node_modules/next` in the worktree and no network access to the Next.js CSP guide; confidence capped at Medium accordingly.)

This repo's wiring forwards only `x-nonce` on the request and sets the CSP **only on the response**:

- proxy.ts:41-42: `const requestHeaders = new Headers(request.headers); requestHeaders.set("x-nonce", nonce);`
- proxy.ts:44-47: `const response = NextResponse.next({ request: { headers: requestHeaders } }); response.headers.set("Content-Security-Policy", buildCsp(nonce));`

Nothing puts `Content-Security-Policy` on the request headers, so Next has no way to discover the nonce, and its bootstrap scripts will render un-nonced. Under `script-src 'self' 'nonce-...' 'strict-dynamic'` (proxy.ts:22 — note `'strict-dynamic'` causes CSP3 browsers to ignore `'self'`), un-nonced framework scripts are blocked, which would break hydration on every page. The consequence half of the claim ("we don't need to read x-nonce here ourselves") is therefore also wrong in effect: with this wiring, *nobody* delivers the nonce to Next.

Note the churn history: the pre-cleanup comment (before d90d6bb) said Next applies the nonce "when a CSP with 'strict-dynamic' + nonce-... is present on the response" — d90d6bb's "correction" preserved the same wrong premise.

**Evidence:**
- app/layout.tsx:27-30 (the comment); proxy.ts:41-47 (quoted above).
- `git show d90d6bb` diff to app/layout.tsx shows the comment rewrite retaining "from the response's CSP header".
- Next-reads-request-header mechanism: paraphrased — no quote available because no local Next source and no network.

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces."

**Location:** proxy.ts:5
**Type:** Reference / architectural
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Next.js 16 did rename the middleware convention to `proxy.ts` with an exported `proxy` function (paraphrased — no quote available because no network access; known from Next.js 16 release documentation). The repo is on `"next": "16.2.4"` (package.json:24), the file is named `proxy.ts` at the repo root, exports `export function proxy(request: NextRequest)` (proxy.ts:35) plus a `config.matcher` (proxy.ts:53-63) — all consistent with the Next 16 proxy convention. The per-request-nonce half is directly verified: `const nonce = Buffer.from(crypto.randomUUID()).toString("base64")` runs inside `proxy()` per request (proxy.ts:38).

**Evidence:**
- package.json:24: `"next": "16.2.4"`
- proxy.ts:35, 38, 53-63 as quoted above.

## Claim 4: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing..."

**Location:** proxy.ts:7-10
**Type:** Behavioral (CSP semantics)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

The CSP semantics are correct in the abstract: `script-src 'nonce-...' 'strict-dynamic'` (proxy.ts:22: `` `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'` ``) allows only nonced scripts plus scripts they programmatically load, and an injected `<script>` without the nonce is blocked. The inaccurate part is the premise "scripts that Next.js has explicitly tagged with the nonce": per Claim 2, with this wiring Next never receives the nonce, so *no* scripts are tagged. The protective claim (injected script can't run) still holds — trivially, since nothing can run — but the description of how legitimate scripts are authorized does not match what the code achieves.

**Evidence:**
- proxy.ts:22 (directive as quoted); dependency on Claim 2's evidence (proxy.ts:41-47).
- CSP `'strict-dynamic'` semantics: paraphrased — no quote available because it is web-platform spec behavior, no network access.

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles."

**Location:** proxy.ts:12-14
**Type:** Behavioral / configuration rationale
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

The carve-out is justified; the attribution is wrong. Tailwind v4 in this repo is compiled via `@tailwindcss/postcss` (package.json devDependencies: `"@tailwindcss/postcss": "^4"`) from `app/globals.css` imported in the layout (app/layout.tsx:4: `import "./globals.css";`) — in a production build that emits a linked stylesheet, not inline styles. What actually needs `'unsafe-inline'` in this app: (a) React inline `style={{...}}` attributes, which style-src governs via the style-src-attr fallback — present in at least app/components/features/formalization-controls/FormalizationControls.tsx, app/components/layout/IconRail.tsx, app/components/panels/ArtifactPanelShell.tsx, app/components/panels/GraphPanel.tsx (2 uses), app/components/features/workspace-session/WorkspaceSessionBar.tsx (2 uses) (`rg -c "style=\{\{"`); and (b) dev-server `<style>` injection by the bundler. So dropping `'unsafe-inline'` would indeed break the app, but because of inline style attributes and dev-mode injection, not because "Tailwind v4 emits inline styles."

**Evidence:**
- proxy.ts:12-14 (the docstring); proxy.ts:23: `"style-src 'self' 'unsafe-inline'"`
- app/layout.tsx:4; package.json (Tailwind v4 via PostCSS); `style={{` hit counts as listed.
- Tailwind-v4-emits-a-stylesheet and style-src-attr fallback: paraphrased — no quote available because build output and web-platform spec are not inspectable offline here.

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** proxy.ts:16-17
**Type:** Behavioral / invariant
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The premise is verified; the sufficiency conclusion is falsified by a client-side `fetch()` of a `data:` URL.

Premise (verified): every third-party API call site is server-side. `fetch(OPENROUTER_API_URL, ...)` appears only in app/lib/llm/callLlm.ts:164 and app/lib/llm/streamLlm.ts:249; their only consumers outside `app/lib/llm/` are `app/lib/formalization/artifactRoute.ts` (which imports `callLlm`/`streamLlm` at lines 2-4) and the `app/api/**/route.ts` files — all server. The Anthropic SDK client lives in callLlm.ts (`getAnthropicClient`, app/lib/llm/callLlm.ts:12-17), server-side only. The Lean verifier call is inside an API route (app/api/verification/lean/route.ts:21). Every browser-side fetch found by enumeration (`rg "fetch\(|XMLHttpRequest|WebSocket|EventSource|sendBeacon" app`) targets a relative same-origin URL — e.g. app/hooks/useAnalytics.ts:11 `fetch("/api/analytics")`, app/lib/formalization/api.ts:10 `fetch(url, ...)` with `/api/...` URLs, app/components/features/context-input/ContextInput.tsx:25 `fetch("/api/refine/context", ...)`, app/components/features/lean-display/LeanCodeDisplay.tsx:88 — **except**:

Counterexample: app/lib/utils/exportGraph.ts:20-26 —

```ts
const dataUrl = await toPng(viewportElement, { pixelRatio: 2, backgroundColor: EXPORT_BG });
const res = await fetch(dataUrl);
const blob = await res.blob();
```

and the identical pattern at app/lib/utils/exportGraph.ts:33-38 (`graphToPngBlob`). `toPng` (html-to-image) returns a `data:image/png;base64,...` URL, and a browser `fetch()` of a `data:` URL is governed by `connect-src`; `'self'` does not match the `data:` scheme (the policy grants `data:` to `img-src` and `font-src` at proxy.ts:24-25 but not to `connect-src`, proxy.ts:26: `"connect-src 'self'"`). These functions are exercised from the UI: `downloadGraphAsPng`/`graphToPngBlob` are imported by app/components/panels/GraphPanel.tsx and app/lib/utils/exportAll.ts. So with this CSP, graph PNG export (and the zip export that embeds the PNG) is blocked in the browser. `connect-src 'self'` is not sufficient; it needs `data:` (or the code should convert the canvas via `toBlob` instead of fetching a data URL).

**Evidence:**
- proxy.ts:16-17, 26; app/lib/utils/exportGraph.ts:20-26 and 33-38 (quoted); import sites per `rg -ln "downloadGraphAsPng|graphToPngBlob"` → app/components/panels/GraphPanel.tsx, app/lib/utils/exportAll.ts.
- Server-side-only third-party calls: file list quoted above.
- fetch-of-data:-URL-is-subject-to-connect-src: paraphrased — no quote available because it is Fetch/CSP spec behavior, no network access to cite the spec.

## Claim 7: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** proxy.ts:36-37
**Type:** Configuration / runtime
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

The operative conclusion holds — the code works — but the runtime attribution is wrong for this repo's configuration. In Next.js 16, `proxy.ts` runs on the **Node.js runtime** by default (Node middleware was stabilized in 15.5 and Next 16's proxy convention defaults to Node); nothing in this repo opts into Edge — `next.config.ts` is empty (`const nextConfig: NextConfig = {};`) and proxy.ts exports no `runtime` config (its only `config` export is the matcher, proxy.ts:52-63). Both `crypto.randomUUID` and `Buffer` are available in Node, and both are also available in Next's Edge runtime, so `Buffer.from(crypto.randomUUID()).toString("base64")` (proxy.ts:38) is fine either way — the comment simply names the wrong runtime. (Runtime-default claim: paraphrased — no quote available because no network access and no `node_modules`; confidence Medium.)

**Evidence:**
- proxy.ts:36-38 (comment + code); next.config.ts (empty config object); proxy.ts:52-63 (no runtime key).
- Next 16 proxy default runtime: paraphrased as tagged above.

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** proxy.ts:40-41
**Type:** Architectural / behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The mechanism is real and correctly implemented: proxy.ts:42-46 sets `x-nonce` on a copy of the request headers and passes it via `NextResponse.next({ request: { headers: requestHeaders } })`, which does make it readable via `headers()` in server components. But the stated purpose is exercised nowhere: `rg -n "x-nonce"` over the repo (excluding node_modules) finds only proxy.ts:42 (the write) and app/layout.tsx:30 (a comment saying it is *not* read). No file imports `next/script` and no `<Script` element exists anywhere in `app/` (`rg "next/script|<Script"` → zero hits). The layout explicitly declines to read it, and commit d90d6bb confirms: "the nonce is only written, never read by the layout." The comment describes a forwarding path with no consumer — accurate as mechanism, misleading as description of what the app does.

**Evidence:**
- proxy.ts:40-46; app/layout.tsx:30; rg results as stated (zero `<Script`/`next/script` hits; only two `x-nonce` occurrences).

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** proxy.ts:53-55
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The matcher does what the comment says. `source: "/((?!api|_next/static|_next/image|favicon.ico).*)"` (proxy.ts:58) is a negative lookahead excluding `/api/*`, `/_next/static/*`, `/_next/image*`, and `/favicon.ico` — matching the claimed skips (API routes and static assets; `_next/image` and favicon are reasonably covered by "static assets"). The `missing` entries (proxy.ts:59-62: `{ type: "header", key: "next-router-prefetch" }` and `{ type: "header", key: "purpose", value: "prefetch" }`) skip requests carrying either prefetch header, which are exactly the two prefetch signals Next's router sends (`next-router-prefetch` for App Router, `purpose: prefetch` for the legacy/pages signal) — that header-name pairing matches the official Next.js CSP-guide matcher example (paraphrased — no quote available, no network access; hence Medium rather than High). API routes returning JSON rather than HTML is consistent with every `app/api/**/route.ts` in the repo.

**Evidence:**
- proxy.ts:53-63 (matcher and missing entries as quoted).
- Prefetch header names: paraphrased as tagged above.

## Claim 10: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit 9b4e453 (message body)
**Type:** Invariant / staleness signal
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" app --glob '!*.test.*'` returns zero hits at d90d6bb. KaTeX is used only through `rehype-katex` with no options (app/components/features/output-editing/LatexRenderer.tsx:6: `import rehypeKatex from "rehype-katex";`, line 10: `const rehypePlugins = [rehypeKatex];`), and KaTeX's `trust` option defaults to `false` when unset (paraphrased — no quote available because KaTeX docs are unreachable offline; this is its long-standing documented default). So "trust:false" is the effective behavior, though it is the default rather than an explicit setting.

**Evidence:**
- rg results (zero hits); app/components/features/output-editing/LatexRenderer.tsx:6,10.

## Claim 11: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit 9b4e453 (message body)
**Type:** Behavioral (verification claim)
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author

The first half is plausible (the response header is set unconditionally at proxy.ts:47, so any matched request will carry CSP). The second half is contradicted by the wiring analysis in Claim 2: Next discovers the nonce from the request's `Content-Security-Policy` header, which this code never sets — only `x-nonce` is forwarded (proxy.ts:42) and the CSP goes only on the response (proxy.ts:47). Under that wiring Next cannot apply the nonce to its generated `<script>` tags, so the claimed verification result should not have been observable as described. I could not re-run the build to confirm (worktree has no `node_modules`, no network), hence Medium rather than High; but the mechanism evidence points one way, and the claim's own author-side story (a comment in the same range asserting the wrong discovery mechanism, app/layout.tsx:28-30) suggests the "verification" checked header emission, not per-script nonce application.

**Evidence:**
- proxy.ts:41-47 (quoted under Claim 2); app/layout.tsx:28-30.
- Nonce-discovery mechanism: paraphrased — no quote available, as tagged in Claim 2.

## Claim 12: "No behavior change; CSP directives preserved exactly."

**Location:** commit d90d6bb (message body)
**Type:** Behavioral (refactor invariant)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git diff b25e939..d90d6bb` touches only: (a) the layout comment text (app/layout.tsx:27-30, prose only); (b) proxy.ts adding an explicit `: NextResponse` return type, rewording a comment, and inlining `const csp = buildCsp(nonce)` into `response.headers.set("Content-Security-Policy", buildCsp(nonce))`. `buildCsp` and its directive list are untouched. No runtime behavior changes. (The rewritten layout comment does carry over an incorrect factual premise — see Claim 2 — but that is a documentation defect, not a behavior change.)

**Evidence:**
- `git diff b25e939..d90d6bb` (full diff read; changes enumerated above match its entirety).

## Claim 13: "Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb (message body)
**Type:** Verification claim
**Verdict:** Unverifiable
**Confidence:** High (that it is unverifiable here)
**Legibility-target:** for-orchestrator-synthesis

The worktree has no `node_modules` and the environment has no network, so `npm test` / `npm run lint` cannot be executed to confirm the count or the clean lint run. Nothing in the diff (comments, a return-type annotation, a variable inlining) would plausibly change test results, so the claim is consistent with the evidence, just not reproducible here.

**Evidence:**
- `ls node_modules` absent in worktree root (directory listing shows no node_modules); diff scope per Claim 12.

## Claims Requiring Attention

### Incorrect
- **Claim 2** (app/layout.tsx:28-30): Next.js reads the nonce from the *request's* CSP header, which this wiring never sets — only the response header carries CSP, so Next's bootstrap scripts are never nonced and would be blocked by `script-src 'nonce-…' 'strict-dynamic'` on every page. Root-cause defect of the whole feature.
- **Claim 6** (proxy.ts:16-17): `connect-src 'self'` is not sufficient — app/lib/utils/exportGraph.ts:24,37 does a browser `fetch()` of a `data:` URL (graph PNG export, used by GraphPanel and exportAll), which connect-src blocks without `data:`.
- **Claim 11** (commit 9b4e453): "Next applies the nonce to every <script> tag" — contradicted by the Claim 2 wiring; the verification as described should not have been observable.
- (Claim 4's premise "scripts that Next.js has explicitly tagged" fails for the same root cause; rated Mostly accurate because its protective conclusion still holds.)

### Stale
- None.

### Mostly Accurate
- **Claim 1** (app/layout.tsx:27-28): `headers()` → dynamic rendering is right; "so proxy.ts runs on every request" is the wrong purpose (proxy runs regardless; dynamic rendering prevents caching a stale nonce in HTML).
- **Claim 4** (proxy.ts:7-10): CSP semantics correct; "Next has tagged with the nonce" premise fails per Claim 2.
- **Claim 5** (proxy.ts:12-14): `'unsafe-inline'` is genuinely needed, but because of React `style={{}}` attributes and dev-mode style injection — Tailwind v4 emits a compiled stylesheet, not inline styles.
- **Claim 7** (proxy.ts:36-37): the APIs are available, but Next 16's proxy runs on the Node.js runtime by default, not Edge, in this repo's configuration.
- **Claim 8** (proxy.ts:40-41): the x-nonce forwarding mechanism works, but nothing in the app reads x-nonce and no `<Script>` tags exist — the described purpose has no consumer.

### Unverifiable
- **Claim 13** (commit d90d6bb): "Lint clean; 221/221 tests pass" — no node_modules/network to re-run; consistent with the comment-only diff.

## Goal-Alignment Note
- Answered: All seven brief items verified: (1) full client-side network-initiation enumeration done — found the `fetch(dataUrl)` counterexample in exportGraph.ts (Claim 6, Incorrect); (2) proxy runtime checked — Node.js default in Next 16, comment says Edge (Claim 7); (3) nonce-discovery mechanism checked — Next reads the request CSP header, wiring sets only the response header (Claim 2, Incorrect); (4) x-nonce is never read anywhere (Claim 8); (5) unsafe-inline is needed but not because of Tailwind (Claim 5); (6) matcher does what its comment says (Claim 9, Verified); (7) `await headers()` → dynamic rendering confirmed, purpose clause imprecise (Claim 1). Commit-message claims also checked (Claims 10-13).
- Out of scope: Whether the CSP design should be fixed (e.g., setting CSP on request headers, adding `data:` to connect-src, or switching exportGraph to `toBlob`) — remediation is the critics'/author's call, not fact-check. Security adequacy of the directive set beyond documented claims. pdfjs worker loading under script-src (a potential runtime issue not claimed in any comment).
- Escalate: (a) The Claim 2/11 root cause means the feature as shipped likely breaks script execution on every page in a CSP-enforcing browser — the security critic and synthesis should treat "CSP works as documented" as false until a live build proves otherwise. (b) Framework-behavior verdicts (Claims 2, 7, 9, 11) rest on documented Next.js behavior recalled offline (no network, no node_modules); if the orchestrator has network access, a one-shot check of the Next.js CSP guide and proxy docs would raise those confidences from Medium to High.
