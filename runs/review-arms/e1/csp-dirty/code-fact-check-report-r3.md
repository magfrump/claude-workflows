# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-csp-dirty, detached at d90d6bb)
**Scope:** `git diff d86d2dc..d90d6bb` — new `proxy.ts` (CSP with per-request nonces) and `app/layout.tsx` made async; commit messages 9b4e453, b25e939, d90d6bb
**Checked:** comments and docstrings in `proxy.ts` and `app/layout.tsx`; commit-message claims in the range; verified against the full repo state at d90d6bb plus Next.js 16 documentation
**Total claims checked:** 13
**Summary:** 5 Verified, 3 Mostly accurate, 4 Incorrect, 1 Unverifiable, 0 Stale. The two most consequential findings: (1) Next.js discovers the nonce from the *request's* `Content-Security-Policy` header, which this proxy never sets — so Next cannot tag its scripts with the nonce and, under `'strict-dynamic'`, the app's own scripts would be blocked; (2) `connect-src 'self'` is not sufficient — the graph PNG export does client-side `fetch(dataUrl)` on `data:` URLs, which connect-src governs and `'self'` does not permit.

**Commit:** d90d6bb

## Claim 1: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce."

**Location:** app/layout.tsx:27-28
**Type:** Behavioral / mechanism
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Two sub-claims. (a) `await headers()` opts the layout out of static rendering — accurate: `headers()` is a Next.js Dynamic API; awaiting it in the root layout forces dynamic rendering of every route. The code does call it:

**Evidence:**
> `await headers();` — app/layout.tsx:32

(b) The stated *reason* — "so proxy.ts runs on every request" — misattributes the mechanism. Proxy (middleware) runs at the request boundary on every matched request regardless of whether the page it fronts is statically rendered; static rendering does not stop proxy.ts from executing. Paraphrased — no quote available because this is framework runtime behavior not expressed in repo code; per Next.js middleware/proxy semantics, the interceptor runs before route resolution on all matched requests. The genuine reason dynamic rendering is required is that a statically prerendered HTML page would have nonce attributes baked at build time, which could never match the fresh per-request nonce in the response CSP header. Commit 9b4e453 states the correct reason ("Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached"); the comment as rewritten in d90d6bb regressed to the wrong causal story. Net effect of the code is correct; the explanation is not.

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** app/layout.tsx:28-30
**Type:** Behavioral (framework mechanism)
**Verdict:** Incorrect
**Confidence:** High (for the mechanism — which header Next reads); Medium-High for the operational consequence, which I could not confirm with a live build (no node_modules in the worktree)

Next.js does auto-tag its scripts with a nonce, but it discovers the nonce from the **request's** `Content-Security-Policy` header during server-side rendering, not from the response's. The official Next.js CSP guide's proxy example sets the CSP header on the forwarded request headers *and* the response, and explains why:

**Evidence (Next.js docs, vercel/next.js `docs/01-app/02-guides/content-security-policy.mdx`):**
> "During rendering, Next.js parses the `Content-Security-Policy` header and extracts the nonce using the `'nonce-{value}'` pattern."
> Example sets both: `requestHeaders.set('Content-Security-Policy', contentSecurityPolicyHeaderValue)` and `response.headers.set('Content-Security-Policy', contentSecurityPolicyHeaderValue)`.

This repo's proxy forwards only `x-nonce` on the request and sets CSP only on the response:

**Evidence:**
> `requestHeaders.set("x-nonce", nonce);` — proxy.ts:42
> `response.headers.set("Content-Security-Policy", buildCsp(nonce));` — proxy.ts:47

Since rendering sees request headers (that is what `headers()` returns) and the request carries no `Content-Security-Policy` header, Next has no nonce to apply. With `script-src 'self' 'nonce-…' 'strict-dynamic'` (proxy.ts:22) — and `'strict-dynamic'` causing browsers to ignore `'self'` — untagged framework scripts would be blocked, breaking the app on any CSP-enforcing browser. The claim is wrong on the header source (response vs. request) and wrong in its conclusion that no further wiring is needed. Note the pre-cleanup comment at b25e939 ("present on the response") had the same error, so this is not a d90d6bb regression — it was wrong from 9b4e453 onward.

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** proxy.ts:5 (also commit 9b4e453: "File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning).")
**Type:** Reference / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Confirmed against Next.js 16 release notes and the migration guide ("Renaming Middleware to Proxy", nextjs.org/docs/messages/middleware-to-proxy): `middleware.ts` was renamed to `proxy.ts` with the export renamed from `middleware` to `proxy`. The repo pins the matching version.

**Evidence:**
> `"next": "16.2.4",` — package.json:23
> `export function proxy(request: NextRequest): NextResponse {` — proxy.ts:34

## Claim 4: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust."

**Location:** proxy.ts:7-8
**Type:** Behavioral (CSP semantics)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

This is an accurate statement of CSP3 `'strict-dynamic'` semantics: nonce-bearing scripts execute, and scripts they programmatically create inherit trust, while `'self'`/host allowlists are ignored. Paraphrased — no quote available because this is CSP specification behavior, not repo code. The directive as built matches the description:

**Evidence:**
> `` `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`, `` — proxy.ts:22

Caveat for synthesis: the semantics are correctly described, but the premise "scripts that Next.js has explicitly tagged with the nonce" never obtains in this wiring (see Claim 2).

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** proxy.ts:12-14
**Type:** Behavioral / configuration rationale
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author

The carve-out itself is genuinely needed, but the attribution is wrong. Tailwind v4 in this repo is compiled through PostCSS into `globals.css` and shipped by Next as a linked stylesheet in production builds — it does not emit inline styles:

**Evidence:**
> `"@tailwindcss/postcss": "^4",` — package.json:36 (devDependencies)
> `import "./globals.css";` — app/layout.tsx:4

What actually requires `'unsafe-inline'` in `style-src` here: (a) React inline `style={}` attributes, which are governed by `style-src-attr` falling back to `style-src` — 20 files under `app/` use `style={` (e.g. app/components/features/proof-graph/ProofGraphNode.tsx, app/components/panels/GraphPanel.tsx; enumerated via `rg -c 'style=\{' app`); (b) reactflow v11 (package.json:29, `"reactflow": "^11.11.4"`), which positions nodes via inline style attributes; (c) KaTeX-rendered spans via rehype-katex (app/components/features/output-editing/LatexRenderer.tsx:6-7); (d) Next dev-mode `<style>` injection for HMR. Confidence Medium because I could not run a production build to inspect emitted tags, but the dependency wiring above is unambiguous about Tailwind's output path.

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** proxy.ts:16-17 (also commit 9b4e453: "connect-src is just 'self' because all external API calls (Anthropic, OpenAlex, OpenRouter) go server-to-server, never browser-to-third-party.")
**Type:** Behavioral / invariant
**Verdict:** Incorrect
**Confidence:** Medium-High
**Legibility-target:** for-author

The server-to-server half checks out. Full enumeration of client-side network initiations under `app/` (fetch/XHR/WebSocket/EventSource/sendBeacon — the latter four have zero occurrences; `rg 'fetch\(|XMLHttpRequest|WebSocket|EventSource|sendBeacon'`):

- Same-origin `/api/...` fetches: app/hooks/useAnalytics.ts:11,30; app/lib/formalization/api.ts:10,38,104; app/components/features/lean-display/LeanCodeDisplay.tsx:88; app/components/features/context-input/ContextInput.tsx:25 — all allowed by `'self'`.
- Third-party fetches exist only server-side: `const response = await fetch(OPENROUTER_API_URL, {` — app/lib/llm/callLlm.ts:164 (and streamLlm.ts:249), imported solely by `app/api/*/route.ts` files; the one client-side import is type-only (`import type { LlmCallUsage } from "@/app/lib/llm/callLlm";` — app/lib/formalization/api.ts:3). The Anthropic SDK client lives in the same server-only module (callLlm.ts:12-17).

But "sufficient" fails on the graph export path:

**Evidence:**
> `const dataUrl = await toPng(viewportElement, {...});` / `const res = await fetch(dataUrl);` — app/lib/utils/exportGraph.ts:20-24, and again at :33-37

`fetch()` of a `data:` URL is governed by `connect-src`, and `'self'` does not match the `data:` scheme (that is why `connect-src ... data:` exists as a directive value). Under this CSP, "Download graph as PNG" (`downloadGraphAsPng`) and the zip embed path (`graphToPngBlob`, used by app/lib/utils/exportAll.ts and app/components/panels/GraphPanel.tsx) would be blocked by the browser. Confidence Medium-High: the enumeration of call sites is exhaustive and directly quoted; the `data:`-vs-connect-src enforcement is standard documented browser behavior I could not exercise in a live browser here. Minor additional inaccuracy: "OpenAlex" appears nowhere in the repo except this docstring (`rg -il openalex .` matches only proxy.ts) — there is no OpenAlex call, server-side or otherwise, at d90d6bb.

## Claim 7: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** proxy.ts:35-36
**Type:** Configuration / runtime
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The operative conclusion — that the line `const nonce = Buffer.from(crypto.randomUUID()).toString("base64");` (proxy.ts:37) is safe to run — is true, but the premise is wrong: in Next.js 16, `proxy.ts` runs on the **Node.js** runtime, not Edge. Per the Next.js 16 upgrade guide and proxy file-convention docs: proxy defaults to (and only supports) the Node.js runtime; the Edge runtime is not supported in proxy, and setting `runtime` in a proxy file throws. This repo has no runtime override anywhere (`next.config.ts` is empty of options: "config options here" placeholder only — next.config.ts:3-5; no `export const runtime` in proxy.ts). Both `crypto.randomUUID` (global WebCrypto in Node 19+/repo requires Node 18+ where it exists on `crypto`) and `Buffer` are natively available in the Node.js runtime, so the code works — the comment just names the wrong runtime, a hangover from pre-16 middleware docs.

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** proxy.ts:39-41
**Type:** Architectural / capability
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The mechanism described is real and correctly wired: `requestHeaders.set("x-nonce", nonce)` (proxy.ts:42) with `NextResponse.next({ request: { headers: requestHeaders } })` (proxy.ts:44-46) does make `(await headers()).get("x-nonce")` work in any dynamically rendered server component — the documented Next.js pattern. The claim is a capability statement ("so layouts *can* read it"), and the capability exists. For synthesis: no code currently exercises it — `x-nonce` appears nowhere outside proxy.ts (`rg -n 'x-nonce' app proxy.ts`: writes at proxy.ts:42, mentioned-but-declined at app/layout.tsx:30), and no `<Script>` component is rendered anywhere in `app/`. Commit d90d6bb itself acknowledges this ("the nonce is only written, never read by the layout"), so this is documented forward-provisioning, not drift.

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** proxy.ts:52-54
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The matcher implements exactly this:

**Evidence:**
> `source: "/((?!api|_next/static|_next/image|favicon.ico).*)",` — proxy.ts:57
> `missing: [ { type: "header", key: "next-router-prefetch" }, { type: "header", key: "purpose", value: "prefetch" } ],` — proxy.ts:58-61

The negative-lookahead source excludes `/api/*` (all API handlers in this repo live under app/api/ — e.g. app/api/verification/lean/route.ts), `_next/static`, `_next/image`, and `favicon.ico`. The `missing` conditions use Next's matcher semantics — the proxy runs only when every listed header is absent — so requests carrying either prefetch marker (`next-router-prefetch`, or legacy `purpose: prefetch`) are skipped. This is byte-for-byte the pattern from the official Next.js CSP guide. Minor scope note, not an inaccuracy: other files served from `public/` (anything besides favicon.ico) still receive the CSP header; harmless for non-HTML responses.

## Claim 10: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit 9b4e453 (message body)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

`rg -n 'dangerouslySetInnerHTML|rehype-raw'` across `app/` returns zero matches, and `rehype-raw` is absent from package.json — those two sub-claims are Verified. The third is imprecise: no code sets `trust: false` on KaTeX (`rg -n 'trust' app` finds no KaTeX trust option; LaTeX rendering goes through `import rehypeKatex from "rehype-katex";` — app/components/features/output-editing/LatexRenderer.tsx:6 with no options object passing `trust`). KaTeX's `trust` option *defaults* to false, so the security property holds, but it holds by default rather than by explicit configuration as the phrasing implies.

## Claim 11: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit 9b4e453 (message body)
**Type:** Behavioral / verification claim
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author

The first half (header emission) is plausible — the proxy unconditionally sets the response header (proxy.ts:47). The second half is contradicted by the mechanism established in Claim 2: Next extracts the nonce from the request's `Content-Security-Policy` header, which this proxy never sets, so Next has no nonce to apply to any `<script>` tag. Either the verification was not actually performed as described, or it was performed in a way that didn't check nonce attributes (e.g., observing the header in devtools without inspecting script tags, or checking in a context where CSP wasn't enforced). Confidence Medium rather than High because I could not reproduce the build (the worktree has no node_modules and installing was out of scope), so this rests on the documented framework mechanism plus the code's header wiring rather than a live repro. The commit's own hedge — "Manual end-to-end browser verification on the Vercel preview is still recommended — CSP issues sometimes only appear once Next's full bootstrap is exercised" — is apt: that is precisely where this would fail.

## Claim 12: "No behavior change; CSP directives preserved exactly."

**Location:** commit d90d6bb (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git diff b25e939..d90d6bb` shows only: comment rewrites in both files, an added explicit return type (`export function proxy(request: NextRequest): NextResponse {`), and inlining of the single-use `csp` local (`response.headers.set("Content-Security-Policy", buildCsp(nonce))` replacing the two-line form). The `buildCsp` directive list is untouched. No behavior change — accurate. (Note the commit's other assertion, that the layout comment was "corrected": the rewrite preserved the same underlying error about the response header — see Claim 2 — but that is covered there, not a behavior-change issue.)

## Claim 13: "Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb (message body)
**Type:** Verification claim
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

The worktree has no node_modules, so neither `npm run lint` nor `vitest run` can be executed without an install, which is outside this pass's footprint. The repo contains 24 `*.test.*` files under `app/` (via `rg --files app -g '*.test.*'`), which makes a 221-test total plausible but not confirmable. Nothing in the diff (comments + a return type + a local inlining) would plausibly break lint or tests, so there is no affirmative reason to doubt it — merely no way to check it here.

## Claims Requiring Attention

### Incorrect
- **Claim 2** (app/layout.tsx:28-30): Next.js reads the nonce from the *request's* CSP header, which this proxy never sets — nonce is never applied to any script; under `'strict-dynamic'` the app's own scripts would be blocked. The single most consequential finding.
- **Claim 5** (proxy.ts:12-14): Tailwind v4 does not emit inline styles here (PostCSS → linked stylesheet); `'unsafe-inline'` is actually needed for React `style={}` attributes, reactflow, KaTeX, and dev-mode style injection.
- **Claim 6** (proxy.ts:16-17): `connect-src 'self'` is not sufficient — `fetch(dataUrl)` on `data:` URLs in app/lib/utils/exportGraph.ts:24,37 is governed by connect-src and would be blocked, breaking graph PNG export and zip embedding. Also, OpenAlex is not referenced anywhere in the repo.
- **Claim 11** (commit 9b4e453): "Next applies the nonce to every <script> tag" cannot be true given the wiring in Claim 2; the verification claim as stated is contradicted by the mechanism.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (app/layout.tsx:27-28): `await headers()` does force dynamic rendering, but the stated reason ("so proxy.ts runs on every request") is wrong — proxy runs regardless; dynamic rendering is needed so per-request nonces aren't baked into cached HTML.
- **Claim 7** (proxy.ts:35-36): the APIs are available, but Next 16 proxy runs on the Node.js runtime, not Edge (Edge is unsupported in proxy).
- **Claim 10** (commit 9b4e453): no dangerouslySetInnerHTML / no rehype-raw confirmed; "KaTeX trust:false" holds only by library default, not explicit configuration.

### Unverifiable
- **Claim 13** (commit d90d6bb): "Lint clean; 221/221 tests pass" — no node_modules in the pinned worktree; cannot execute lint or tests without an install.

## Goal-Alignment Note
- Answered: All 7 claims from the shared brief were checked (brief items 1→Claim 6, 2→Claim 7, 3→Claim 2, 4→Claim 8, 5→Claim 5, 6→Claim 9, 7→Claim 1), plus 6 additional claims from docstrings and commit messages in the range. Client-side network initiations were exhaustively enumerated, including the `data:`-URL fetches in the export utilities.
- Out of scope: Whether the CSP *design* is good (e.g., whether to add `connect-src data:` vs. refactor exportGraph to skip the fetch; whether strict-dynamic is the right policy) — that is critic work, not fact-checking. Worker-src implications of the pdfjs worker (app/lib/utils/pdfPropositionParser.ts:443) are a security-review concern, flagged here only as context.
- Escalate: Claims 2 + 11 together indicate the shipped CSP would likely break the entire app in CSP-enforcing browsers once deployed (framework scripts blocked for lack of nonce). Critics and synthesis should treat "nonce is actually applied" as false until a live build proves otherwise; the fix is the documented pattern of also setting `Content-Security-Policy` on the forwarded request headers. Claim 6's export breakage is user-visible feature loss under the same header. Verification claims in commit 9b4e453 should not be trusted as evidence by downstream reviewers.
