# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-csp-clean, detached at 4f018ab)
**Scope:** `git diff d86d2dc..4f018ab` (CSP feature + review-fix commits: 9b4e453, b25e939, d90d6bb, 4f018ab) — comments, docstrings, and commit-message claims in `proxy.ts`, `proxy.test.ts`, `app/layout.tsx`, `app/lib/utils/exportGraph.ts`
**Checked:** 2026-08-06
**Total claims checked:** 16
**Summary:** 9 Verified, 4 Mostly accurate, 2 Incorrect, 1 Unverifiable. The two Incorrect findings are the same defect seen from two places: `proxy.test.ts`'s "disallows wildcards and http:" assertions (also claimed in the 4f018ab commit message) use regexes that demonstrably fail to match realistic wildcard (`img-src *`) and `http:`/`http://` source forms, so the test does not enforce what its comment and the commit message say it enforces. The load-bearing security claims (connect-src sufficiency, nonce entropy, directive pinning for the four named high-risk directives, matcher scope) all check out.

**Commit:** 4f018ab

## Claim 1: layout dynamic rendering is what lets the rendered HTML pick up the nonce

**Location:** app/layout.tsx:27-31
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** Medium — the app-side wiring is fully verified from source; the Next.js-internal step (nonce extracted from the incoming `Content-Security-Policy` request header during dynamic render) could not be read from `node_modules` (not installed in this worktree) and rests on documented Next.js behavior.
**Legibility-target:** for-orchestrator-synthesis

The comment claims:

> ```
> // Opt this layout into dynamic rendering so Next.js injects the per-request
> // nonce (set by proxy.ts) into its own bootstrap <script> tags during render.
> // The proxy already runs per request via its matcher; the dynamic-rendering
> // switch is what lets the rendered HTML pick up the nonce.
> ```
> — app/layout.tsx:27-30

The delivery chain end-to-end, as of 4f018ab: the proxy sets the CSP (containing `'nonce-…'`) on the **forwarded request** headers — `requestHeaders.set("Content-Security-Policy", csp);` (proxy.ts:50) — and the layout forces per-request rendering with `await headers();` (app/layout.tsx:31). Next.js reads the nonce it injects into its bootstrap scripts from the request's `Content-Security-Policy` header during app render (paraphrased — no quote available because `node_modules` is not installed in this worktree; this is documented Next.js behavior, and it is exactly why commit 4f018ab added the request-side header — see Claim 8 and Claim 16). The matcher does run the proxy on every page navigation (proxy.ts:63-70), so "the proxy already runs per request" is accurate; the remaining gate is static-vs-dynamic rendering, which `await headers()` switches (paraphrased — no quote available because this is framework behavior, not app code). The comment's causal story matches the code as wired at this commit.

**Evidence:**
- `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:50
- `await headers();` — app/layout.tsx:31
- `import { headers } from "next/headers";` — app/layout.tsx:3

## Claim 2: toBlob avoids needing `data:` in connect-src

**Location:** app/lib/utils/exportGraph.ts:6
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium — the removal of the `fetch(dataUrl)` call is verified directly from the diff; that `html-to-image`'s `toBlob` produces the blob via `canvas.toBlob` without a network fetch is paraphrased — no quote available because `node_modules` is not installed (html-to-image 1.11.13 per package-lock.json), and this rests on the library's documented API.
**Legibility-target:** for-orchestrator-synthesis

> `// Use toBlob (not toPng + fetch) so we don't need `data:` in CSP connect-src.` — app/lib/utils/exportGraph.ts:6

The pre-change code fetched a `data:` URL: `const dataUrl = await toPng(viewportElement, {...}); const res = await fetch(dataUrl);` (paraphrased quote from `git show` of the removed lines; visible in the range diff for app/lib/utils/exportGraph.ts). A `fetch()` of a `data:` URL is governed by `connect-src`, and the policy is `"connect-src 'self'"` (proxy.ts:28) with no `data:`, so the old code would indeed have violated the policy. The new code has no `fetch` at all — `const blob = await toBlob(viewportElement, { pixelRatio: 2, backgroundColor: EXPORT_BG });` (app/lib/utils/exportGraph.ts:18-21) — and hands the blob to `triggerDownload`, which uses `URL.createObjectURL(blob)` (app/lib/utils/export.ts:8), not a network request. Grepping the whole of `app/` finds no other `fetch` of a `data:` or `blob:` URL (see Claim 7 enumeration).

**Evidence:**
- `const blob = await toBlob(viewportElement, {` — app/lib/utils/exportGraph.ts:18
- `const url = URL.createObjectURL(blob);` — app/lib/utils/export.ts:8
- `"connect-src 'self'",` — proxy.ts:28

## Claim 3: test pins the directive list so weakening script-src, connect-src, frame-ancestors, or object-src fails loudly

**Location:** proxy.test.ts:4-7
**Type:** Behavioral (test coverage)
**Verdict:** Verified
**Confidence:** High — assertions read directly; each of the four named directives is pinned by exact-string `toContain` against `csp.split("; ")`, so any added or removed source in those directives changes the full directive string and fails the match.
**Legibility-target:** for-orchestrator-synthesis

> ```
> // Pin the CSP directive list so a refactor that weakens script-src,
> // connect-src, frame-ancestors, or object-src fails loudly in tests rather
> // than silently shipping.
> ```
> — proxy.test.ts:4-6

All four named directives are asserted as exact full-directive strings: `` expect(directives).toContain(`script-src 'self' 'nonce-${NONCE}' 'strict-dynamic'`,) `` (proxy.test.ts:14-16), `expect(directives).toContain("connect-src 'self'");` (proxy.test.ts:21), `expect(directives).toContain("frame-ancestors 'none'");` (proxy.test.ts:22), `expect(directives).toContain("object-src 'none'");` (proxy.test.ts:23). Because `directives` is `csp.split("; ")` (proxy.test.ts:11), appending e.g. `https://evil.com` to `connect-src` makes the element `"connect-src 'self' https://evil.com"`, which no longer equals the pinned string — the test fails. The header comment's claim is accurate **for the four directives it names**. (The weaker third test block is a separate claim — see Claim 4.)

**Evidence:**
- `const directives = csp.split("; ");` — proxy.test.ts:11
- `expect(directives).toContain("connect-src 'self'");` — proxy.test.ts:21
- `expect(directives).toContain("object-src 'none'");` — proxy.test.ts:23

## Claim 4: test "does not allow eval, wildcards, or http: schemes anywhere"

**Location:** proxy.test.ts:28-31
**Type:** Behavioral (test coverage)
**Verdict:** Incorrect
**Confidence:** High — demonstrated by executing the exact regexes from the test against realistic weakened-CSP strings in Node.
**Legibility-target:** for-author

> `it("does not allow eval, wildcards, or http: schemes anywhere", () => {` — proxy.test.ts:28
> `expect(csp).not.toMatch(/\*\s/); // wildcard source not followed by directive end` — proxy.test.ts:30
> `expect(csp).not.toMatch(/\bhttp:\b/);` — proxy.test.ts:31

The `'unsafe-eval'` assertion (proxy.test.ts:29) works. The other two do not enforce what the test name claims:

- **Wildcards:** `/\*\s/` only matches a `*` followed immediately by whitespace, i.e. a wildcard in the *middle* of a source list. The common weakening — a wildcard as the last (or only) source of a directive, e.g. `img-src *`, where `*` is followed by `;` or end-of-string — is not matched. Executed check: `/\*\s/.test("img-src *; font-src 'self'")` → `false` (paraphrased transcript of the Node run; the regex and inputs are quoted verbatim). Since only `img-src`, `font-src`, and `style-src` are *not* pinned by exact string elsewhere in the file, a refactor to `img-src *` would pass the entire suite.
- **http: schemes:** `/\bhttp:\b/` requires a word boundary after the colon, i.e. a word character immediately following `:`. Neither realistic form has one: the CSP scheme-source `http:` is followed by a space or delimiter, and `http://example.com` follows the colon with `/`. Executed check: `/\bhttp:\b/.test("script-src http: 'self'")` → `false` and `/\bhttp:\b/.test("connect-src http://evil.com")` → `false` (paraphrased transcript of the Node run). The assertion can essentially never fire on valid CSP syntax.

The inline comment `// wildcard source not followed by directive end` (proxy.test.ts:30) also inverts what the regex does — it matches a wildcard followed by whitespace, which in this string format means a wildcard that is *not* at a directive end.

**Evidence:**
- `expect(csp).not.toMatch(/'unsafe-eval'/);` — proxy.test.ts:29 (this one is effective)
- Node execution: `/\*\s/` vs `"img-src *; font-src 'self'"` → false; `/\bhttp:\b/` vs `"script-src http: 'self'"` and `"connect-src http://evil.com"` → false; `/\*\s/` vs `"img-src 'self' * data:"` → true (paraphrased — transcript of an ad-hoc `node -e` run outside the worktree; regexes copied verbatim from proxy.test.ts:30-31)
- Unpinned directives that could absorb a wildcard silently: `"style-src 'self' 'unsafe-inline'",` / `"img-src 'self' data: blob:",` / `"font-src 'self' data:",` — proxy.ts:25-27 (no `toContain` for these in proxy.test.ts:19-26)

## Claim 5: Next.js 16 renamed Middleware → Proxy

**Location:** proxy.ts:5
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium — the repo is on Next 16 and the file layout is consistent with the claim; the rename itself is framework history that cannot be confirmed from repo contents alone.
**Legibility-target:** for-orchestrator-synthesis

> `* CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces.` — proxy.ts:5

package.json pins `"next": "16.2.4"` (package.json:23) and the file exports `export function proxy(request: NextRequest): NextResponse {` (proxy.ts:38) plus a root-level `config.matcher` (proxy.ts:59-72) — the middleware-convention shape under the new name. The rename claim matches Next.js 16's documented deprecation of `middleware.ts` in favor of `proxy.ts` (paraphrased — no quote available because `node_modules` is not installed in this worktree). The feature commit also states the motivation: "File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning)" (git log 9b4e453).

**Evidence:**
- `"next": "16.2.4",` — package.json:23
- `export function proxy(request: NextRequest): NextResponse {` — proxy.ts:38

## Claim 6: style-src 'unsafe-inline' rationale — inline style props at named sites

**Location:** proxy.ts:12-16
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** High for the overall rationale (19 non-test component files use inline `style` props); the one imprecise detail is directly readable in source.
**Legibility-target:** for-author

> ```
> * Why `style-src 'unsafe-inline'`: many React components use inline
> * `style={{...}}` props (e.g. proof-graph node positioning, refinement
> * preview, collapsible sections), and Next.js's SSR style injection also
> * emits inline <style> tags.
> ```
> — proxy.ts:12-15

"Many React components use inline `style={{...}}` props" is verified: a census finds 19 component files under `app/` with `style={{` (plus CollapsibleSection's object-valued `style` prop), including all three named areas. Refinement preview: `style={{ lineHeight: 1.6 }}` (app/components/features/context-input/RefinementPreview.tsx:24 and :35). Collapsible sections: `<div style={open ? undefined : HIDDEN_STYLE}>{children}</div>` with `const HIDDEN_STYLE = { display: "none" } as const;` (app/components/ui/CollapsibleSection.tsx:51, :13). The one imprecise detail: "proof-graph node **positioning**" — the app's own proof-graph inline styles are colors and sizing, not positioning: `style={{ borderColor: statusColor, borderWidth: 2, minWidth: 160 }}` (app/components/features/proof-graph/ProofGraphNode.tsx:45), `style={{ backgroundColor: badgeColor }}` (:52), `style={{ backgroundColor: statusColor }}` (:58), `style={{ color: data.sourceColor }}` (:70). Actual node *positioning* inline styles are emitted by the React Flow library at runtime, not by app `style={{...}}` props (paraphrased — no quote available because `node_modules` is not installed; React Flow positions nodes via inline `transform` styles). The carve-out's justification stands either way — inline styles are pervasive — but the specific example is mislabeled.

**Evidence:**
- `style={{ borderColor: statusColor, borderWidth: 2, minWidth: 160 }}` — app/components/features/proof-graph/ProofGraphNode.tsx:45
- `style={{ lineHeight: 1.6 }}` — app/components/features/context-input/RefinementPreview.tsx:24
- `<div style={open ? undefined : HIDDEN_STYLE}>{children}</div>` — app/components/ui/CollapsibleSection.tsx:51
- 19 files matched by `rg -c "style=\{\{" app/ -g '*.tsx' -g '!*.test.*'` (paraphrased — count from ripgrep output; individual paths available on request)

## Claim 7: `connect-src 'self'` is sufficient; Anthropic / OpenAlex / OpenRouter calls are server-to-server

**Location:** proxy.ts:18-19
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** High — full enumeration of client-side network initiations performed; the only inaccuracy is that no OpenAlex integration exists anywhere in the repo.
**Legibility-target:** for-author

> ```
> * `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter
> * calls are server-to-server (Next API routes), not browser-to-third-party.
> ```
> — proxy.ts:18-19

Enumeration of every client-side network initiation in `app/` (grep for `fetch(`, `XMLHttpRequest`, `new WebSocket`, `EventSource`, `sendBeacon`, `axios` over `*.ts`/`*.tsx` excluding tests):

- Same-origin relative fetches (allowed by `'self'`): `fetch("/api/analytics")` (app/hooks/useAnalytics.ts:11, :30); `fetch("/api/explanation/lean-error", {` (app/components/features/lean-display/LeanCodeDisplay.tsx:88); `fetch("/api/refine/context", {` (app/components/features/context-input/ContextInput.tsx:25); the shared helpers `const res = await fetch(url, {` (app/lib/formalization/api.ts:10, :38) whose call sites pass only relative routes — `"/api/decomposition/extract"` (app/hooks/useDecomposition.ts:130) and `const route = ARTIFACT_ROUTE[type];` (app/hooks/useArtifactGeneration.ts:42) resolving to `/api/formalization/*` paths in the `ARTIFACT_ROUTE` map (app/lib/types/artifacts.ts); and `fetch("/api/verification/lean", {` (app/lib/formalization/api.ts:104).
- Server-side only (never runs in the browser): `fetch(OPENROUTER_API_URL, {` (app/lib/llm/callLlm.ts:164, app/lib/llm/streamLlm.ts:249) — the only importers of `callLlm`/`streamLlm` outside `app/lib/llm/` are API route files (`app/api/*/route.ts`) and `app/lib/formalization/artifactRoute.ts`, itself imported only by API routes; the client-shared `app/lib/formalization/api.ts` imports only a type: `import type { LlmCallUsage } from "@/app/lib/llm/callLlm";` (app/lib/formalization/api.ts:3). The Anthropic SDK (`import Anthropic from "@anthropic-ai/sdk";` — app/lib/llm/callLlm.ts:2) lives in the same server-only module. `fetch(\`${LEAN_VERIFIER_URL}/verify\`` (app/api/verification/lean/route.ts:21) is inside an API route.
- No WebSocket/EventSource/sendBeacon/XHR anywhere in `app/`; SSE streaming is consumed via same-origin `fetch` + `res.body.getReader()` (app/lib/formalization/api.ts:49). The former `fetch(dataUrl)` of a `data:` URL was removed in this range (Claim 2). pdfjs loads its worker from a bundled same-origin URL, not a CDN: `pdfjsLib.GlobalWorkerOptions.workerSrc = new URL("pdfjs-dist/build/pdf.worker.min.mjs", import.meta.url)` (app/lib/utils/fileExtraction.ts:26-28; same pattern at app/lib/utils/pdfPropositionParser.ts:443-445) — and worker loading is governed by worker-src/script-src fallbacks, not connect-src, in any case.

So the sufficiency conclusion is correct. The inaccuracy: **OpenAlex is referenced nowhere in the repo except this comment itself** — `rg -il openalex` over the repo (excluding node_modules/package-lock) matches only `./proxy.ts`. The claim that OpenAlex "calls are server-to-server" asserts calls that do not exist.

**Evidence:**
- `export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";` — app/lib/llm/callLlm.ts:7
- `import { callLlm, OpenRouterError } from "@/app/lib/llm/callLlm";` — app/lib/formalization/artifactRoute.ts:2 (server-side consumer)
- `import type { LlmCallUsage } from "@/app/lib/llm/callLlm";` — app/lib/formalization/api.ts:3 (client-shared module imports type only)
- OpenAlex grep: only match is `proxy.ts:18` (paraphrased — ripgrep produced a single-file result list)

## Claim 8: form-action does NOT fall back to default-src (CSP3)

**Location:** proxy.ts:32
**Type:** Configuration / reference (spec)
**Verdict:** Verified
**Confidence:** Medium — the directive's presence is directly verified (High); the spec assertion matches CSP3's documented fallback list, which excludes `form-action`, but the spec itself is not consultable from this offline worktree.
**Legibility-target:** for-orchestrator-synthesis

> `// form-action does NOT fall back to default-src (CSP3); set explicitly.` — proxy.ts:32

The directive is present immediately below: `"form-action 'self'",` (proxy.ts:33), and pinned by the test: `expect(directives).toContain("form-action 'self'");` (proxy.test.ts:25). The spec claim is accurate: in CSP3, `form-action` is a navigation directive and is not in the `default-src` fallback chain, so omitting it leaves form submissions unrestricted (paraphrased — no quote available because the CSP3 spec is external and this environment has no web access; this is well-established, stable spec behavior).

**Evidence:**
- `"form-action 'self'",` — proxy.ts:33
- `expect(directives).toContain("form-action 'self'");` — proxy.test.ts:25

## Claim 9: 128-bit nonce; crypto.getRandomValues + Buffer available in the Node.js runtime Next 16 Proxy uses by default

**Location:** proxy.ts:39-41
**Type:** Behavioral / configuration
**Verdict:** Verified
**Confidence:** Medium — the entropy arithmetic and API premises are solid (Next 16.2.4 requires Node >= 20.9.0 per the lockfile; global `crypto.getRandomValues` and `Buffer` are both available there); the "Node.js runtime by default" claim about Next 16 Proxy could not be confirmed from `node_modules` (absent) and rests on Next 16 documentation.
**Legibility-target:** for-orchestrator-synthesis

> ```
> // Generate a fresh 128-bit nonce per request. crypto.getRandomValues + Buffer
> // are both available in the Node.js runtime Next 16 Proxy runs on by default.
> ```
> — proxy.ts:39-40

Entropy: `crypto.getRandomValues(new Uint8Array(16))` (proxy.ts:41) fills 16 bytes = 128 bits of randomness — arithmetic: 16 × 8 = 128. Runtime premises: the lockfile records Next's engine requirement `{"node":">=20.9.0"}` for `next@16.2.4` (paraphrased — extracted from package-lock.json `packages["node_modules/next"].engines` via a Node one-liner; package-lock.json is machine-generated so no stable line number). Global `crypto` (WebCrypto, including `getRandomValues`) has been available without flags since Node 19, and `Buffer` is a Node global — both hold on any Node >= 20.9 (paraphrased — no quote available because this is Node.js platform behavior, not repo code). That Next 16's Proxy defaults to the Node.js runtime (the 4f018ab commit message says the earlier Edge-runtime comment was a fact-check correction: "dropped Edge-runtime claim — Next 16 Proxy runs on Node.js by default", git log 4f018ab) is consistent with Next 16 documentation but not independently confirmable offline.

**Evidence:**
- `const nonce = Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64");` — proxy.ts:41
- Next engines `{"node":">=20.9.0"}`, version 16.2.4 — package-lock.json, `packages["node_modules/next"]` (paraphrased — JSON object, no stable line number)

## Claim 10: forward the nonce via request header so layouts can read it via headers() and pass it to Script tags

**Location:** proxy.ts:44-45
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** High — the header is set, but a repo-wide grep shows `x-nonce` is never read, and no layout passes a nonce to any `<Script>`; the intermediate commit in this very range concedes the point.
**Legibility-target:** for-author

> ```
> // Forward the nonce to server components via a request header so layouts
> // can read it via `headers()` and pass it to <Script> tags they render.
> ```
> — proxy.ts:44-45

The capability is real: `requestHeaders.set("x-nonce", nonce);` (proxy.ts:49) makes the nonce readable by any server component via `headers()`. But nothing exercises it — `rg -n "x-nonce"` across `app/` and the repo root matches only proxy.ts:49 (the write); `app/layout.tsx` calls `await headers();` (app/layout.tsx:31) without reading the result, and no `<Script>` receives a nonce prop anywhere. The range's own commit d90d6bb states this: "headers() is called to opt out of static rendering … not to read x-nonce (the nonce is only written, never read by the layout)" (git log d90d6bb). The comment describes an unused capability as if it were the delivery mechanism; the mechanism actually in play is the request-side CSP header on the next line (proxy.ts:50, see Claims 1 and 11). Not wrong as a statement of what layouts *could* do, but it points readers at the wrong wire.

**Evidence:**
- `requestHeaders.set("x-nonce", nonce);` — proxy.ts:49 (sole `x-nonce` occurrence in the repo)
- `await headers();` — app/layout.tsx:31 (return value discarded)
- "the nonce is only written, never read by the layout" — git log d90d6bb

## Claim 11: setting CSP on both the forwarded request and the response matches the canonical Next.js docs example

**Location:** proxy.ts:46-47
**Type:** Behavioral / reference
**Verdict:** Verified
**Confidence:** Medium — both settings are directly verified in code (High); the correspondence to the Next.js docs CSP example is from documented framework guidance, not consultable offline.
**Legibility-target:** for-orchestrator-synthesis

> ```
> // Setting CSP on both the forwarded request and the response matches the
> // canonical Next.js docs example.
> ```
> — proxy.ts:46-47

Both settings exist: request side — `requestHeaders.set("Content-Security-Policy", csp);` (proxy.ts:50), passed onward via `NextResponse.next({ request: { headers: requestHeaders } })` (proxy.ts:52-54); response side — `response.headers.set("Content-Security-Policy", csp);` (proxy.ts:55). Each serves a distinct purpose: the request-side copy is what Next.js's renderer parses the nonce out of when tagging its bootstrap scripts (paraphrased — no quote available, `node_modules` absent; see Claim 1), and the response-side copy is what the browser enforces. The Next.js CSP guide's middleware example does exactly this dual set — `x-nonce` plus `Content-Security-Policy` on the forwarded request headers, and the same CSP on the response (paraphrased — no quote available because the docs are external and this environment is offline).

**Evidence:**
- `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:50
- `response.headers.set("Content-Security-Policy", csp);` — proxy.ts:55

## Claim 12: matcher applies CSP to page navigations only — skips API routes, static assets, prefetches

**Location:** proxy.ts:60-62
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High — the matcher pattern and both `missing` entries are read directly and do what the comment says.
**Legibility-target:** for-orchestrator-synthesis

> ```
> // Apply CSP to page navigations only. Skip API routes (they don't render
> // HTML), Next's static assets (no scripts to nonce), and prefetches (which
> // would otherwise burn a nonce on a request that may never paint).
> ```
> — proxy.ts:60-62

The source pattern `"/((?!api|_next/static|_next/image|favicon.ico).*)"` (proxy.ts:65) is a negative lookahead excluding paths beginning `api`, `_next/static`, `_next/image`, and `favicon.ico` — API routes and Next's static asset paths, as claimed. Prefetches are excluded via the `missing` conditions: `{ type: "header", key: "next-router-prefetch" },` and `{ type: "header", key: "purpose", value: "prefetch" },` (proxy.ts:67-68), which match only requests *lacking* those prefetch-marker headers (paraphrased — `missing` semantics are Next.js matcher behavior, not confirmable from the absent `node_modules`; the config shape matches the documented convention). Both header keys are the standard Next.js/browser prefetch markers.

**Evidence:**
- `source: "/((?!api|_next/static|_next/image|favicon.ico).*)",` — proxy.ts:65
- `{ type: "header", key: "next-router-prefetch" },` — proxy.ts:67
- `{ type: "header", key: "purpose", value: "prefetch" },` — proxy.ts:68

## Claim 13: (commit 9b4e453) "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates"

**Location:** git log 9b4e453 (commit message)
**Type:** Behavioral (verification claim)
**Verdict:** Unverifiable
**Confidence:** Low — it reports a manual build-time observation that cannot be replayed offline, and there is a code-level reason to doubt the second half as of that commit.
**Legibility-target:** for-orchestrator-synthesis

> "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates." — git log 9b4e453

The first half (response header emitted) is consistent with the code at 9b4e453: `response.headers.set("Content-Security-Policy", csp);` (present in `git show 9b4e453:proxy.ts`). The second half is in tension with the wiring at that commit: 9b4e453 forwarded only `x-nonce` on the request — `requestHeaders.set("x-nonce", nonce);` with no request-side `Content-Security-Policy` (git show 9b4e453:proxy.ts, proxy function body) — while Next.js extracts the nonce it applies to its scripts from the request's CSP header (paraphrased — no quote available, `node_modules` absent). If that mechanism is right, nonce application would only have begun working at 4f018ab, which added `requestHeaders.set("Content-Security-Policy", csp);` (proxy.ts:50) and justified it as "matching the canonical Next.js 16 docs example" (git log 4f018ab). I cannot rerun the build to settle whether the 9b4e453 observation was mistaken or Next has another nonce path; flagged for escalation.

**Evidence:**
- 9b4e453 proxy body sets `x-nonce` but not a request-side CSP header (paraphrased — from `git show 9b4e453:proxy.ts`; the request-header block reads `requestHeaders.set("x-nonce", nonce);` with no CSP line)
- `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:50 (added by 4f018ab)

## Claim 14: (commit d90d6bb) "No behavior change; CSP directives preserved exactly … 221/221 tests pass"

**Location:** git log d90d6bb (commit message)
**Type:** Behavioral / staleness
**Verdict:** Verified
**Confidence:** High for behavior-neutrality (diff read directly); Medium for the test count (statically consistent, not executed).
**Legibility-target:** for-orchestrator-synthesis

> "No behavior change; CSP directives preserved exactly. Lint clean; 221/221 tests pass." — git log d90d6bb

`git diff b25e939 d90d6bb` touches only comments, an added explicit return type (`export function proxy(request: NextRequest): NextResponse {`), and inlining of a single-use local (`response.headers.set("Content-Security-Policy", buildCsp(nonce));` replacing the `csp` temporary) — no directive strings change (paraphrased — from the range diff of proxy.ts between those commits; app/layout.tsx changes are comment-only per the same diff). The 221 count is consistent with the tree at 4f018ab: static count of `it(`/`test(` declarations across all `*.test.*` files is 225, of which 4 are the new proxy.test.ts cases added *after* d90d6bb — 225 − 4 = 221. Pass/fail cannot be executed offline (no `node_modules`).

**Evidence:**
- `export function proxy(request: NextRequest): NextResponse {` — proxy.ts:38 (the added return type)
- Static test-case count 225 total, 4 in proxy.test.ts (paraphrased — ripgrep count `rg -c "^\s*(it|test)\(" -g '*.test.*'` summed across files; proxy.test.ts contributes the `it(` blocks at lines 13, 19, 28, 34)

## Claim 15: (commit 4f018ab) "full 128-bit nonce entropy (UUID-based was 122 bits)"

**Location:** git log 4f018ab (commit message)
**Type:** Behavioral / arithmetic
**Verdict:** Verified
**Confidence:** High — both halves check arithmetically against the before/after code.
**Legibility-target:** for-orchestrator-synthesis

> "Use crypto.getRandomValues(Uint8Array(16)) for full 128-bit nonce entropy (UUID-based was 122 bits)." — git log 4f018ab

After: `crypto.getRandomValues(new Uint8Array(16))` (proxy.ts:41) = 16 bytes × 8 = 128 random bits. Before: the 9b4e453/d90d6bb implementation was `const nonce = Buffer.from(crypto.randomUUID()).toString("base64");` (paraphrased — from `git show 9b4e453:proxy.ts`). `crypto.randomUUID()` returns an RFC 4122 version-4 UUID, which fixes 4 version bits and 2 variant bits of its 128, leaving 122 bits of entropy (paraphrased — no quote available because this is the UUID spec, external to the repo). Base64-encoding the UUID string changes length, not entropy. Both figures are correct.

**Evidence:**
- `const nonce = Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64");` — proxy.ts:41
- Prior implementation used `crypto.randomUUID()` (paraphrased — `git show 9b4e453:proxy.ts`, nonce line)

## Claim 16: (commit 4f018ab) "225/225 tests pass", toBlob doesn't violate connect-src, and the new test "disallows unsafe-eval, wildcards, and http:"

**Location:** git log 4f018ab (commit message)
**Type:** Behavioral (multiple sub-claims)
**Verdict:** Mostly accurate
**Confidence:** High for the incorrect sub-claim (regex demonstration); Medium for the test count (statically consistent, not executable); Medium for the toBlob sub-claim (see Claim 2).
**Legibility-target:** for-author

Three checkable sub-claims:

1. > "Lint clean; 225/225 tests pass." — git log 4f018ab
   The count is exactly consistent with the tree: summing `it(`/`test(` declarations across every `*.test.*` file yields 225, with no `it.each`/`test.each` parameterization that would inflate runtime counts (paraphrased — ripgrep census; per-file counts available). Pass status not executable offline (no `node_modules`) — count verified, execution taken on faith.
2. > "switch from toPng + fetch(dataUrl) to toBlob so PNG graph export and zip export don't violate connect-src 'self'." — git log 4f018ab
   Verified — see Claim 2; both `downloadGraphAsPng` and `graphToPngBlob` (the zip-embedding path, app/lib/utils/exportGraph.ts:33-35) now route through the fetch-free `renderGraphPng` (app/lib/utils/exportGraph.ts:17-24).
3. > "New proxy.test.ts pins the directive list … and disallows unsafe-eval, wildcards, and http:." — git log 4f018ab
   The pinning half is Verified (Claim 3); the "disallows … wildcards, and http:" half is **Incorrect** — the assertions do not match realistic wildcard or http: forms (Claim 4). The commit message propagates the test's overclaim.

**Evidence:**
- `export function graphToPngBlob(viewportElement: HTMLElement): Promise<Blob> { return renderGraphPng(viewportElement); }` — app/lib/utils/exportGraph.ts:33-35 (paraphrased line-joining of the two-line body)
- `expect(csp).not.toMatch(/\bhttp:\b/);` — proxy.test.ts:31 (see Claim 4 for the failing demonstration)

## Claims Requiring Attention

### Incorrect
- **Claim 4** (proxy.test.ts:28-31): the "does not allow eval, wildcards, or http: schemes anywhere" test enforces only the eval part. `/\*\s/` misses a wildcard at the end of a directive (`img-src *;` → no match) and `/\bhttp:\b/` matches neither the `http:` scheme source nor `http://host` URLs. A refactor to `img-src *` or `style-src http:` would pass the full suite, since img-src/font-src/style-src are not pinned elsewhere.
- **Claim 16, sub-claim 3** (git log 4f018ab): the commit message repeats the same overclaim ("disallows unsafe-eval, wildcards, and http:").

### Stale
- None.

### Mostly Accurate
- **Claim 6** (proxy.ts:12-16): style-src rationale is sound and two of three named sites check out exactly; "proof-graph node positioning" mislabels what the app's own inline styles do there (colors/sizing; positioning styles come from the React Flow library).
- **Claim 7** (proxy.ts:18-19): connect-src 'self' sufficiency fully verified by enumeration, but OpenAlex — named as one of the three server-to-server integrations — does not exist anywhere in the repo.
- **Claim 10** (proxy.ts:44-45): x-nonce is written but never read; the comment presents an unused capability as the delivery path, while the operative mechanism is the request-side CSP header set on the next line.
- **Claim 16** (git log 4f018ab): two of three sub-claims hold; the third is the Incorrect test overclaim above.

### Unverifiable
- **Claim 13** (git log 9b4e453): "Next applies the nonce to every `<script>` tag" was claimed as verified at a commit that did not yet forward the CSP on the request — the header Next.js reads the nonce from. Cannot be replayed offline; see Escalate.

## Goal-Alignment Note
- Answered: All nine brief items — client network-initiation enumeration for connect-src (Claim 7), nonce delivery end-to-end (Claims 1, 10, 11), runtime/API availability (Claim 9), dual CSP setting (Claim 11), style-src named sites (Claim 6), form-action fallback (Claim 8), test-coverage claims (Claims 3, 4), commit 4f018ab's entropy/test-count/toBlob claims (Claims 15, 16, 2), and the matcher (Claim 12).
- Out of scope: Whether `'strict-dynamic'` in script-src could break the same-origin pdfjs worker load (worker-src falls back through child-src to script-src, where `'strict-dynamic'` discards `'self'`) — a potential functional regression for PDF upload under this CSP, but a code-review finding, not a documentation-accuracy one. Handing to the security/performance critics.
- Escalate: (1) The proxy.test.ts wildcard/http: assertions are security tests that assert nothing — worth a fix in the review-fix loop (two anchored regexes or per-directive pins for style-src/img-src/font-src). (2) Claim 13's tension — if Next reads the nonce only from the request CSP header, nonce injection was non-functional at 9b4e453 despite the commit's "verified" claim, and the range's own manual-verification evidence should not be trusted for the current state either; recommend the E1 orchestrator note that runtime verification (prod build + header inspection) has not been performed for 4f018ab.
