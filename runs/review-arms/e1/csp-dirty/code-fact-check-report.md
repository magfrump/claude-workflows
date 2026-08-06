# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-csp-dirty, detached at d90d6bb)
**Scope:** `git diff d86d2dc..d90d6bb` — new `proxy.ts` (CSP with per-request nonces) and `app/layout.tsx` made async; commit messages 9b4e453, b25e939, d90d6bb
**Checked:** 2026-08-06
**Total claims checked:** 15
**Summary:** 3 Verified, 6 Mostly accurate, 1 Stale, 4 Incorrect, 1 Unverifiable. Merged from 3 replicate fact-check passes, most-severe verdict per cluster. The two load-bearing Incorrect findings share one root cause: Next.js discovers the CSP nonce from the *request's* `Content-Security-Policy` header, which this proxy never sets (it sets CSP only on the response and forwards only `x-nonce`) — so Next cannot tag its bootstrap scripts with the nonce and, under `'strict-dynamic'`, the app's own scripts would be blocked in any CSP-enforcing browser. Independently, `connect-src 'self'` blocks the client-side `fetch(dataUrl)` calls in the graph PNG export path.

**Commit:** d90d6bb
**Replication:** k=3

## Claim 1: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce."

**Location:** app/layout.tsx:27-28
**Type:** Behavioral / mechanism
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

Two sub-claims. (a) `await headers()` opts the layout out of static rendering — accurate: `headers()` is a Next.js Dynamic API; awaiting it in the root layout forces dynamic rendering of every route, and the code does call it (app/layout.tsx:32). (b) The stated *reason* — "so proxy.ts runs on every request" — misattributes the mechanism. Proxy (middleware) runs at the request boundary on every matched request regardless of whether the page it fronts is statically rendered; static rendering does not stop proxy.ts from executing. The genuine reason dynamic rendering is required is that a statically prerendered HTML page would have nonce attributes baked at build time, which could never match the fresh per-request nonce in the response CSP header. Commit 9b4e453 states the correct reason ("Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached"); the comment as rewritten in d90d6bb regressed to the wrong causal story. Net effect of the code is correct; the explanation is not.

**Evidence:**
- `await headers();` — app/layout.tsx:32; `headers` imported from `next/headers` at app/layout.tsx:3.
- Commit 9b4e453 message: "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached."
- Proxy-runs-regardless-of-rendering-mode: paraphrased — no quote available because this is Next.js framework runtime behavior not expressed in repo code (no node_modules, no network).

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** app/layout.tsx:28-30
**Type:** Behavioral (framework mechanism)
**Verdict:** Incorrect
**Confidence:** High (for the mechanism — which header Next reads); Medium-High for the operational consequence, not confirmed with a live build
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

Next.js does auto-tag its scripts with a nonce, but it discovers the nonce from the **request's** `Content-Security-Policy` header during server-side rendering, not from the response's. The official Next.js CSP guide's proxy example sets the CSP header on the forwarded request headers *and* the response.

This repo's proxy forwards only `x-nonce` on the request and sets CSP only on the response. Since rendering sees request headers (that is what `headers()` returns) and the request carries no `Content-Security-Policy` header, Next has no nonce to apply. With `script-src 'self' 'nonce-…' 'strict-dynamic'` (proxy.ts:22) — and `'strict-dynamic'` causing browsers to ignore `'self'` — untagged framework scripts would be blocked, breaking the app on any CSP-enforcing browser. The claim is wrong on the header source (response vs. request) and wrong in its conclusion that no further wiring is needed. Note the pre-cleanup comment at b25e939 ("present on the response") had the same error, so this is not a d90d6bb regression — it was wrong from 9b4e453 onward.

**Evidence:**
- Next.js docs (vercel/next.js `docs/01-app/02-guides/content-security-policy.mdx`): "During rendering, Next.js parses the `Content-Security-Policy` header and extracts the nonce using the `'nonce-{value}'` pattern." Example sets both: `requestHeaders.set('Content-Security-Policy', contentSecurityPolicyHeaderValue)` and `response.headers.set('Content-Security-Policy', contentSecurityPolicyHeaderValue)`.
- `requestHeaders.set("x-nonce", nonce);` — proxy.ts:42
- `response.headers.set("Content-Security-Policy", buildCsp(nonce));` — proxy.ts:47
- Repo-wide grep for `x-nonce` returns only proxy.ts:42 (the write) and app/layout.tsx:30 (this comment) — no reader exists.

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces."

**Location:** proxy.ts:5
**Type:** Reference / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Confirmed against Next.js 16 release notes and the migration guide ("Renaming Middleware to Proxy", nextjs.org/docs/messages/middleware-to-proxy): `middleware.ts` was renamed to `proxy.ts` with the export renamed from `middleware` to `proxy`. The repo pins the matching version, the file is named `proxy.ts` at the repo root with a `config.matcher`, and the per-request-nonce half is directly verified: the nonce is generated inside the handler per invocation.

**Evidence:**
- `"next": "16.2.4",` — package.json:23
- `export function proxy(request: NextRequest): NextResponse {` — proxy.ts:34
- `const nonce = Buffer.from(crypto.randomUUID()).toString("base64");` — proxy.ts:37

## Claim 4: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing..."

**Location:** proxy.ts:7-10
**Type:** Behavioral (CSP semantics)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Verified

The CSP semantics are correct in the abstract: `script-src 'nonce-...' 'strict-dynamic'` (proxy.ts:22: `` `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'` ``) allows only nonced scripts plus scripts they programmatically load, and an injected `<script>` without the nonce is blocked. The inaccurate part is the premise "scripts that Next.js has explicitly tagged with the nonce": per Claim 2, with this wiring Next never receives the nonce, so *no* scripts are tagged. The protective claim (injected script can't run) still holds — trivially, since nothing can run — but the description of how legitimate scripts are authorized does not match what the code achieves.

**Evidence:**
- proxy.ts:22 (directive as quoted); dependency on Claim 2's evidence (proxy.ts:41-47).
- CSP `'strict-dynamic'` semantics: paraphrased — no quote available because it is web-platform spec behavior, no network access.

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** proxy.ts:12-14
**Type:** Behavioral / configuration rationale
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect

The carve-out itself is genuinely needed, but the attribution is wrong. Tailwind v4 in this repo is compiled through PostCSS into `globals.css` and shipped by Next as a linked stylesheet in production builds — it does not emit inline styles. What actually requires `'unsafe-inline'` in `style-src` here: (a) React inline `style={}` attributes, which are governed by `style-src-attr` falling back to `style-src` — 20 files under `app/` use `style={` (e.g. app/components/features/proof-graph/ProofGraphNode.tsx, app/components/panels/GraphPanel.tsx; enumerated via `rg -c 'style=\{' app`); (b) reactflow v11 (package.json:29, `"reactflow": "^11.11.4"`), which positions nodes via inline style attributes; (c) KaTeX-rendered spans via rehype-katex (app/components/features/output-editing/LatexRenderer.tsx:6-7); (d) Next dev-mode `<style>` injection for HMR. Confidence Medium because a production build could not be run to inspect emitted tags, but the dependency wiring is unambiguous about Tailwind's output path.

**Evidence:**
- `"@tailwindcss/postcss": "^4",` — package.json:36 (devDependencies)
- `import "./globals.css";` — app/layout.tsx:4
- `style-src 'self' 'unsafe-inline'` — proxy.ts:23; `style={` hit counts and reactflow/KaTeX wiring as cited above.

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** proxy.ts:16-17
**Type:** Behavioral / invariant
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Incorrect

The premise is verified; the sufficiency conclusion is falsified by a client-side `fetch()` of a `data:` URL.

Premise (verified): every third-party API call site is server-side. `fetch(OPENROUTER_API_URL, ...)` appears only in app/lib/llm/callLlm.ts:164 and app/lib/llm/streamLlm.ts:249; their only consumers outside `app/lib/llm/` are `app/lib/formalization/artifactRoute.ts` (which imports `callLlm`/`streamLlm` at lines 2-4) and the `app/api/**/route.ts` files — all server. The Anthropic SDK client lives in callLlm.ts (`getAnthropicClient`, app/lib/llm/callLlm.ts:12-17), server-side only. The Lean verifier call is inside an API route (app/api/verification/lean/route.ts:21). Every browser-side fetch found by enumeration (`rg "fetch\(|XMLHttpRequest|WebSocket|EventSource|sendBeacon" app`) targets a relative same-origin URL — e.g. app/hooks/useAnalytics.ts:11 `fetch("/api/analytics")`, app/lib/formalization/api.ts:10, app/components/features/context-input/ContextInput.tsx:25, app/components/features/lean-display/LeanCodeDisplay.tsx:88 — **except**:

Counterexample: app/lib/utils/exportGraph.ts:20-26 —

```ts
const dataUrl = await toPng(viewportElement, { pixelRatio: 2, backgroundColor: EXPORT_BG });
const res = await fetch(dataUrl);
const blob = await res.blob();
```

and the identical pattern at app/lib/utils/exportGraph.ts:33-38 (`graphToPngBlob`). `toPng` (html-to-image) returns a `data:image/png;base64,...` URL, and a browser `fetch()` of a `data:` URL is governed by `connect-src`; `'self'` does not match the `data:` scheme (the policy grants `data:` to `img-src` and `font-src` at proxy.ts:24-25 but not to `connect-src`, proxy.ts:26: `"connect-src 'self'"`). These functions are exercised from the UI: `downloadGraphAsPng`/`graphToPngBlob` are imported by app/components/panels/GraphPanel.tsx and app/lib/utils/exportAll.ts. So with this CSP, graph PNG export (and the zip export that embeds the PNG) is blocked in the browser. `connect-src 'self'` is not sufficient; it needs `data:` (or the code should convert the canvas via `toBlob` instead of fetching a data URL). Minor additional inaccuracy (from r3): "OpenAlex" appears nowhere in the repo except this docstring (`rg -il openalex .` matches only proxy.ts) — there is no OpenAlex call, server-side or otherwise, at d90d6bb.

**Evidence:**
- proxy.ts:16-17, 26; app/lib/utils/exportGraph.ts:20-26 and 33-38 (quoted); import sites per `rg -ln "downloadGraphAsPng|graphToPngBlob"` → app/components/panels/GraphPanel.tsx, app/lib/utils/exportAll.ts.
- Server-side-only third-party calls: file list quoted above.
- fetch-of-data:-URL-is-subject-to-connect-src: paraphrased — no quote available because it is Fetch/CSP spec behavior, no network access to cite the spec.

## Claim 7: "Generate a fresh nonce per request. crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** proxy.ts:35-37
**Type:** Configuration / runtime
**Verdict:** Stale
**Confidence:** Medium
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Stale · r3=Mostly accurate

In Next.js 16, `proxy.ts` runs on the **Node.js runtime** by default — the Edge default belonged to the pre-16 `middleware.ts` era (Node middleware stabilized in 15.5; Next 16's proxy convention is Node-first). Nothing in this repo opts back into Edge: next.config.ts is an empty config (`const nextConfig: NextConfig = { /* config options here */ };`) and proxy.ts exports no `runtime` config (its only `config` export is the matcher, proxy.ts:52-63). So "the Edge runtime that Next proxy runs in" misidentifies the runtime. The availability half of the claim is functionally harmless: `crypto.randomUUID` and `Buffer` are both first-class in Node.js, so `Buffer.from(crypto.randomUUID()).toString("base64")` (proxy.ts:37) works where the code actually runs. The comment's premise is a holdover — note the d90d6bb diff shows this comment was *edited* in the cleanup commit (adding "and Buffer") while retaining the stale Edge framing.

**Evidence:**
- next.config.ts (empty config object); proxy.ts:37, proxy.ts:52-63; `git show d90d6bb` proxy.ts hunk showing the comment edit.
- Runtime-default assertion paraphrased — no quote available because Next.js 16 release documentation is external and unreachable from the sandbox.

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** proxy.ts:39-41
**Type:** Architectural / behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified

The mechanism is real: `requestHeaders.set("x-nonce", nonce)` (proxy.ts:42) followed by `NextResponse.next({ request: { headers: requestHeaders } })` (proxy.ts:44-45) does make `x-nonce` readable via `headers()` in server components. But the described consumer does not exist: a repo-wide grep for `x-nonce` finds only proxy.ts:42 (the write) and the app/layout.tsx:30 comment (which explicitly declines to read it); a grep for `next/script` / `<Script` across `app/` returns zero hits — no layout or component renders a `<Script>` tag at all. The forwarding is dead plumbing at d90d6bb. Combined with Claim 2 (Next.js very likely never sees the nonce via the response header either), `x-nonce` is the only channel by which the nonce could reach markup, and nothing uses it. Commit d90d6bb itself acknowledges this ("the nonce is only written, never read by the layout").

**Evidence:**
- proxy.ts:42, 44-45; grep `x-nonce` → proxy.ts:42 and app/layout.tsx:30 only; grep `next/script|<Script` in app/ → no matches.

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** proxy.ts:52-55
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

The matcher does what the comment says:

```
proxy.ts:57: source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
proxy.ts:58-61: missing: [
    { type: "header", key: "next-router-prefetch" },
    { type: "header", key: "purpose", value: "prefetch" },
  ],
```

The negative lookahead excludes paths beginning `api` (API routes), `_next/static` and `_next/image` (static assets), and `favicon.ico`; the `missing` entries exclude requests carrying either documented prefetch header, so prefetches don't trigger the proxy. Two harmless imprecisions, noted for completeness: the alternation is unanchored per-segment, so any path *starting with* the string `api` (e.g. a hypothetical `/apidocs` page) would also be skipped — no such route exists in `app/`; and other `public/` files (e.g. SVGs) still match and receive a CSP header, which is inert.

**Evidence:**
- proxy.ts:57-61 (quoted above); `ls app/` route tree contains no non-`api` path starting with "api".

## Claim 10: commit 9b4e453 — "feat: add strict CSP with per-request nonces"

**Location:** git log d86d2dc..d90d6bb (9b4e453)
**Type:** Commit-message / behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection

The commit does add a CSP whose nonce is regenerated per request (proxy.ts:37 inside the handler) with `'strict-dynamic'` (proxy.ts:23) — the "strict CSP" pattern by name. Qualifier: per Claims 2 and 8, the nonce very likely never reaches any script element in the served HTML, so the shipped policy behaves less like a working strict-CSP deployment and more like a nonce-shaped allowlist that would block Next's own bootstrap scripts. The message accurately describes the intent and the diff's content, not necessarily a functioning result.

**Evidence:**
- proxy.ts:23,37; `git log d86d2dc..d90d6bb` message text; cross-reference Claims 2 and 8.

## Claim 11: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit 9b4e453 (message body)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=— · r3=Mostly accurate

`rg -n 'dangerouslySetInnerHTML|rehype-raw'` across `app/` returns zero matches, and `rehype-raw` is absent from package.json — those two sub-claims are Verified. The third is imprecise: no code sets `trust: false` on KaTeX (`rg -n 'trust' app` finds no KaTeX trust option; LaTeX rendering goes through `import rehypeKatex from "rehype-katex";` — app/components/features/output-editing/LatexRenderer.tsx:6 with no options object passing `trust`). KaTeX's `trust` option *defaults* to false, so the security property holds, but it holds by default rather than by explicit configuration as the phrasing implies.

**Evidence:**
- rg results (zero hits for dangerouslySetInnerHTML / rehype-raw); app/components/features/output-editing/LatexRenderer.tsx:6,10.

## Claim 12: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit 9b4e453 (message body)
**Type:** Behavioral / verification claim
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=— · r3=Incorrect

The first half (header emission) is plausible — the proxy unconditionally sets the response header (proxy.ts:47). The second half is contradicted by the mechanism established in Claim 2: Next extracts the nonce from the request's `Content-Security-Policy` header, which this proxy never sets, so Next has no nonce to apply to any `<script>` tag. Either the verification was not actually performed as described, or it was performed in a way that didn't check nonce attributes (e.g., observing the header in devtools without inspecting script tags, or checking in a context where CSP wasn't enforced). Confidence Medium rather than High because the build could not be reproduced (the worktree has no node_modules and installing was out of scope), so this rests on the documented framework mechanism plus the code's header wiring rather than a live repro. The commit's own hedge — "Manual end-to-end browser verification on the Vercel preview is still recommended — CSP issues sometimes only appear once Next's full bootstrap is exercised" — is apt: that is precisely where this would fail.

**Evidence:**
- proxy.ts:41-47 (quoted under Claim 2); app/layout.tsx:28-30; nonce-discovery mechanism per Claim 2's evidence.

## Claim 13: commit b25e939 — "fix: correct layout comment to reference proxy.ts (renamed from middleware.ts)"

**Location:** git log d86d2dc..d90d6bb (b25e939)
**Type:** Commit-message / reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection

`git show b25e939 --stat` shows exactly `app/layout.tsx | 2 +-` (1 insertion, 1 deletion), a comment-only change, and the layout comment at d90d6bb references proxy.ts (app/layout.tsx:27). Consistent with the message.

**Evidence:**
- `git show b25e939 --stat` output quoted in-session; app/layout.tsx:27.

## Claim 14: "No behavior change; CSP directives preserved exactly."

**Location:** commit d90d6bb (message body)
**Type:** Behavioral (refactor invariant)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified

No behavior change — verified: the d90d6bb diff to proxy.ts adds a return type annotation (`export function proxy(request: NextRequest): NextResponse`), inlines the single-use `csp` local into `buildCsp(nonce)` at the `response.headers.set` call, and edits comments; the layout diff is comment-only. `buildCsp` and the directives array are untouched, so "CSP directives preserved exactly" holds. Also note the message's own framing — "correct comment" — while the corrected comment introduced/retained the incorrect response-header mechanism (Claim 2); that is a documentation defect, not a behavior change.

**Evidence:**
- `git show d90d6bb` full diff (comment rewrites, return-type annotation, `csp` local inlining; `buildCsp` untouched).

## Claim 15: "Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb (message body)
**Type:** Verification claim
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable

The worktree has no node_modules, so neither `npm run lint` nor the vitest suite can be executed without an install, which is outside this pass's footprint. "221/221 tests pass" is corroborated but not confirmed: a static count of `it(`/`test(` declarations across the worktree totals exactly 221, matching the claimed count. "Lint clean" is unverifiable for the same reason. Nothing in the diff (comments, a return-type annotation, a variable inlining) would plausibly change lint or test results, so the claim is consistent with the evidence, just not reproducible here.

**Evidence:**
- node_modules absent from the pinned worktree; `rg -c "^\s*(it|test)\(" ` static count summed = 221; diff scope per Claim 14.

## Claims Requiring Attention

### Incorrect
- **Claim 2** (app/layout.tsx:28-30): Next.js reads the CSP nonce from the *request's* Content-Security-Policy header, not the response's. This app sets the CSP only on the response and forwards only `x-nonce` (which Next.js does not read), so Next's bootstrap scripts get no nonce; under `'strict-dynamic'` with no `'unsafe-inline'` fallback they would be blocked. Root-cause defect of the whole feature.
- **Claim 5** (proxy.ts:12-14): Tailwind v4 does not emit inline styles here (PostCSS → linked stylesheet); `'unsafe-inline'` is actually needed for React `style={}` attributes, reactflow, KaTeX, and dev-mode style injection.
- **Claim 6** (proxy.ts:16-17): `connect-src 'self'` is not sufficient — `fetch(dataUrl)` on `data:` URLs in app/lib/utils/exportGraph.ts:24,37 is governed by connect-src and would be blocked, breaking graph PNG export and zip embedding. Also, OpenAlex is not referenced anywhere in the repo.
- **Claim 12** (commit 9b4e453): "Next applies the nonce to every <script> tag" cannot be true given the wiring in Claim 2; the verification claim as stated is contradicted by the mechanism.

### Stale
- **Claim 7** (proxy.ts:35-37): Next 16's proxy runs on the Node.js runtime by default, not Edge; the code works anyway (both APIs exist in Node), but the runtime premise is a pre-16 holdover — and was re-edited without correction in d90d6bb.

### Mostly Accurate
- **Claim 1** (app/layout.tsx:27-28): `await headers()` does force dynamic rendering, but the stated reason ("so proxy.ts runs on every request") is wrong — proxy runs regardless; dynamic rendering is needed so per-request nonces aren't baked into cached HTML.
- **Claim 4** (proxy.ts:7-10): CSP `'strict-dynamic'` semantics correctly described; the premise "scripts that Next.js has explicitly tagged with the nonce" fails per Claim 2 — nothing is tagged.
- **Claim 8** (proxy.ts:39-41): the `x-nonce` forwarding mechanism works but has zero readers and no `<Script>` tags exist anywhere in `app/` — the described purpose has no consumer.
- **Claim 10** (commit 9b4e453): diff matches the message; "strict CSP" is aspirational given Claim 2.
- **Claim 11** (commit 9b4e453): no dangerouslySetInnerHTML / no rehype-raw confirmed; "KaTeX trust:false" holds only by library default, not explicit configuration.
- **Claim 14** (commit d90d6bb): no-behavior-change and directive-preservation verified by diff read; flagged Mostly accurate by one replicate because the "corrected" comment retained the Claim 2 error.

### Unverifiable
- **Claim 15** (commit d90d6bb): "Lint clean; 221/221 tests pass" — no node_modules in the pinned worktree; cannot execute lint or tests. Static test-declaration count (221) matches the claimed 221.

## Verdict stability

- **Total clusters:** 15
- **Agreed clusters:** 8 (Claims 1, 2, 3, 9, 12, 15 unanimous across surfacing replicates; Claims 10 and 13 single-replicate, trivially agreed)
- **Disagreeing clusters:** 7
  - Claim 4 (proxy.ts:7-10): r1=Mostly accurate · r2=— · r3=Verified → merged Mostly accurate
  - Claim 5 (proxy.ts:12-14): r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect → merged Incorrect
  - Claim 6 (proxy.ts:16-17): r1=Incorrect · r2=Mostly accurate · r3=Incorrect → merged Incorrect
  - Claim 7 (proxy.ts:35-37): r1=Mostly accurate · r2=Stale · r3=Mostly accurate → merged Stale
  - Claim 8 (proxy.ts:39-41): r1=Mostly accurate · r2=Mostly accurate · r3=Verified → merged Mostly accurate
  - Claim 11 (9b4e453 XSS surface): r1=Verified · r2=— · r3=Mostly accurate → merged Mostly accurate
  - Claim 14 (d90d6bb no behavior change): r1=Verified · r2=Mostly accurate · r3=Verified → merged Mostly accurate
- **Agreement rate:** 8/15 = 53% (excluding the two single-replicate clusters: 6/13 = 46%)

## Goal-Alignment Note
- Answered: All 7 briefed claims checked by all three replicates (client-side network-initiation enumeration incl. the `fetch(dataUrl)` counterexample; proxy runtime; nonce-discovery mechanism; x-nonce readers; unsafe-inline justification; matcher behavior; `await headers()` dynamic-rendering), plus commit-message claims for all three in-range commits.
- Out of scope (union, deduplicated): Whether the CSP design should be fixed and how (setting CSP on forwarded request headers, adding `data:` to connect-src vs. refactoring exportGraph to `toBlob`, whether strict-dynamic is the right policy) — remediation is critic/author work, not fact-check. Security adequacy of the directive set beyond documented claims. pdfjs worker loading under script-src/worker-src (app/lib/utils/pdfPropositionParser.ts:443) — a potential runtime issue not claimed in any comment, flagged as context for security review. Running the test suite or lint (deps not installed in the pinned worktree).
- Escalate (union, deduplicated): (1) Claims 2 + 12 together indicate the shipped CSP likely breaks script execution/hydration on every page in CSP-enforcing browsers — critics and synthesis should treat "nonce is actually applied" / "CSP works as documented" as false until a live build proves otherwise; the fix is the documented pattern of also setting `Content-Security-Policy` on the forwarded request headers; a runtime smoke test would settle it. (2) Claim 6: `connect-src 'self'` breaks graph PNG export and Export All via blocked `data:` fetches — user-visible feature loss. (3) Verification claims in commit 9b4e453 should not be trusted as evidence by downstream reviewers. (4) Framework-behavior verdicts (Claims 2, 3, 7, 9, 12) rest partly on documented Next.js behavior recalled offline (no network, no node_modules in two of three replicate environments); if the orchestrator has network access, a one-shot check of the Next.js CSP guide and proxy docs would raise those confidences.
