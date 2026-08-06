# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-csp-clean, detached at 4f018ab)
**Scope:** `git diff d86d2dc..4f018ab` (CSP feature + review-fix commits: 9b4e453, b25e939, d90d6bb, 4f018ab) — comments, docstrings, and commit-message claims in `proxy.ts`, `proxy.test.ts`, `app/layout.tsx`, `app/lib/utils/exportGraph.ts`
**Checked:** 2026-08-06
**Total claims checked:** 18 (merged clusters from 16 + 15 + 16 replicate claims)
**Summary:** 11 Verified, 5 Mostly accurate, 1 Incorrect, 0 Stale, 1 Unverifiable. All three replicates independently found the same Incorrect defect: `proxy.test.ts`'s "does not allow eval, wildcards, or http: schemes anywhere" test enforces only the eval part — `/\bhttp:\b/` can never match a realistic `http:` source and `/\*\s/` misses a wildcard at directive end (each replicate confirmed by executing the regexes in Node). The 4f018ab commit message propagates the same overclaim. The load-bearing security claims (connect-src sufficiency via full client-side network enumeration, nonce entropy arithmetic, exact-string directive pinning for the four named high-risk directives, matcher scope) check out in all replicates. Recurrent minor drift: the connect-src rationale names OpenAlex, which exists nowhere in the repo; the x-nonce forwarding comment describes a capability nothing exercises; "KaTeX trust:false" is a library default, not an explicit setting.

**Commit:** 4f018ab
**Replication:** k=3 (merged most-severe-wins from replicate reports r1, r2, r3)

## Claim 1: layout.tsx — dynamic rendering is what lets the rendered HTML pick up the nonce set by proxy.ts

**Location:** app/layout.tsx:24-31
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** Medium — the app-side wiring is fully verified from source; the Next.js-internal step (nonce extracted from the incoming `Content-Security-Policy` request header during dynamic render) could not be read from `node_modules` (not installed in this worktree) and rests on documented Next.js behavior.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

The comment claims:

> "Opt this layout into dynamic rendering so Next.js injects the per-request nonce (set by proxy.ts) into its own bootstrap `<script>` tags during render. The proxy already runs per request via its matcher; the dynamic-rendering switch is what lets the rendered HTML pick up the nonce." — app/layout.tsx

The delivery chain end-to-end, as of 4f018ab: the proxy sets the CSP (containing `'nonce-…'`) on the **forwarded request** headers — `requestHeaders.set("Content-Security-Policy", csp);` (proxy.ts:50) — and the layout forces per-request rendering with `await headers();`. Next.js reads the nonce it injects into its bootstrap scripts from the request's `Content-Security-Policy` header during app render (paraphrased — no quote available because `node_modules` is not installed in this worktree; documented Next.js behavior — the `x-nonce` header is a userland side-channel Next itself does not consume). The matcher runs the proxy on every page navigation, so "the proxy already runs per request" is accurate; the remaining gate is static-vs-dynamic rendering, which `await headers()` switches. r2 additionally noted this wiring only became correct at 4f018ab: at d90d6bb the request carried only `x-nonce` (no request-side CSP header). The comment's causal story matches the code as wired at this commit.

**Evidence:**
- `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:50
- `await headers();` — app/layout.tsx (return value discarded; opts into dynamic rendering)
- `import { headers } from "next/headers";` — app/layout.tsx:3

## Claim 2: exportGraph.ts — toBlob avoids needing `data:` in connect-src

**Location:** app/lib/utils/exportGraph.ts:6
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High (r2) — the removal of the only `fetch(dataUrl)` call is verified directly from the diff; r1/r3 rated Medium because `html-to-image`'s `toBlob` producing the blob via `canvas.toBlob` without a network fetch rests on the library's documented API (`node_modules` absent).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

> `// Use toBlob (not toPng + fetch) so we don't need `data:` in CSP connect-src.` — app/lib/utils/exportGraph.ts:6

The pre-change code fetched a `data:` URL: `const dataUrl = await toPng(viewportElement, {...}); const res = await fetch(dataUrl);` (removed lines, visible in the range diff). A `fetch()` of a `data:` URL is governed by `connect-src`, and the policy is `"connect-src 'self'"` with no `data:`, so the old code would have violated the policy. The new code has no `fetch` at all — `const blob = await toBlob(viewportElement, { pixelRatio: 2, backgroundColor: EXPORT_BG });` (app/lib/utils/exportGraph.ts:18-21) — and hands the blob to `triggerDownload`, which uses `URL.createObjectURL(blob)` (app/lib/utils/export.ts:8), not a network request. Repo-wide search confirms no other `fetch` of a `data:`/`blob:` URL remains; the only `data:` hits in `app/lib/utils/` are pdf.js `getDocument({ data: buffer })` (in-memory, not a URL fetch).

**Evidence:**
- `const blob = await toBlob(viewportElement, {` — app/lib/utils/exportGraph.ts:18
- `const url = URL.createObjectURL(blob);` — app/lib/utils/export.ts:8
- `"connect-src 'self'",` — proxy.ts (buildCsp directive array)

## Claim 3: proxy.test.ts header — pins the directive list so weakening script-src, connect-src, frame-ancestors, or object-src fails loudly

**Location:** proxy.test.ts:3-6
**Type:** Behavioral (test coverage)
**Verdict:** Verified
**Confidence:** High — assertions read directly; each of the four named directives is pinned by exact-string `toContain` against `csp.split("; ")`, so any added or removed source in those directives changes the full directive string and fails the match.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

> "Pin the CSP directive list so a refactor that weakens script-src, connect-src, frame-ancestors, or object-src fails loudly in tests rather than silently shipping." — proxy.test.ts

All four named directives are asserted as exact full-directive strings: `` expect(directives).toContain(`script-src 'self' 'nonce-${NONCE}' 'strict-dynamic'`) ``, `expect(directives).toContain("connect-src 'self'");`, `expect(directives).toContain("frame-ancestors 'none'");`, `expect(directives).toContain("object-src 'none'");`. Because `directives` is `csp.split("; ")`, appending e.g. `https://evil.com` to `connect-src` makes the element no longer equal the pinned string — the test fails. r2/r3 add: removing a directive outright is also caught by the stable-order test (see Claim 5), which closes the gap of a second, weaker list under the same directive name. The header comment's claim is accurate **for the four directives it names**. (The weaker disallowance test is a separate claim — see Claim 4.)

**Evidence:**
- `const directives = csp.split("; ");` — proxy.test.ts
- `expect(directives).toContain("connect-src 'self'");` — proxy.test.ts
- `expect(directives).toContain("object-src 'none'");` — proxy.test.ts

## Claim 4: proxy.test.ts — "does not allow eval, wildcards, or http: schemes anywhere"

**Location:** proxy.test.ts:27-31
**Type:** Behavioral (test coverage)
**Verdict:** Incorrect
**Confidence:** High — all three replicates independently demonstrated the defect by executing the exact regexes from the test against realistic weakened-CSP strings in Node.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

> `it("does not allow eval, wildcards, or http: schemes anywhere", () => { expect(csp).not.toMatch(/'unsafe-eval'/); expect(csp).not.toMatch(/\*\s/); // wildcard source not followed by directive end expect(csp).not.toMatch(/\bhttp:\b/); });` — proxy.test.ts

The `'unsafe-eval'` assertion works. The other two do not enforce what the test name claims:

- **`http:` check is vacuous.** `/\bhttp:\b/` requires a word boundary after the colon, i.e. a word character immediately following `:`. In every realistic weakened CSP, `http:` is followed by `/` (a URL), a space, `;`, or end-of-string — all non-word characters, so no boundary exists and the regex never matches. A refactor adding `http:` sources would pass this test.
- **Wildcard check misses trailing wildcards.** `/\*\s/` only matches a `*` followed immediately by whitespace, i.e. a wildcard in the *middle* of a source list. Directives are joined with `"; "`, so a directive ending in `*` is followed by `;` (not whitespace) or end-of-string — `img-src *` or a final `form-action *` passes. r1 adds: since only `img-src`, `font-src`, and `style-src` are *not* pinned by exact string elsewhere in the file, a refactor to `img-src *` would pass the entire suite.

The inline comment `// wildcard source not followed by directive end` acknowledges the regex's narrow reach, but the test *name* claims wildcards are disallowed "anywhere" (r1 additionally reads the comment as inverting what the regex does). The 4f018ab commit message repeats the overclaim ("disallows unsafe-eval, wildcards, and http:") — see Claim 18.

**Evidence:**
- `expect(csp).not.toMatch(/'unsafe-eval'/);` — proxy.test.ts (this one is effective)
- Node execution (r3's transcript; r1 and r2 ran equivalent checks with matching results):

```
/\*\s/.test("img-src *; font-src 'self'")        → false   (wildcard at directive end: NOT caught)
/\*\s/.test("form-action *")                     → false   (wildcard in final directive: NOT caught)
/\*\s/.test("script-src * self")                 → true    (mid-list wildcard: caught)
/\bhttp:\b/.test("connect-src http://evil.com")  → false   (NOT caught)
/\bhttp:\b/.test("script-src http: 'self'")      → false   (NOT caught)
/\bhttp:\b/.test("script-src http:")             → false   (NOT caught)
```

- Unpinned directives that could absorb a wildcard silently: `"style-src 'self' 'unsafe-inline'",` / `"img-src 'self' data: blob:",` / `"font-src 'self' data:",` — proxy.ts (no `toContain` for these in proxy.test.ts)
- Suggested-shape fix (r2/r3): `not.toMatch(/\bhttp:/)` (drop the trailing `\b`) and `/(^|\s)\*(;|\s|$)/`, or per-directive pins for style-src/img-src/font-src.

## Claim 5: proxy.test.ts — "emits the directive list in stable order"

**Location:** proxy.test.ts:34-46
**Type:** Behavioral (test coverage)
**Verdict:** Verified
**Confidence:** High — direct comparison of the two lists.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection

The expected order in the test — `default-src, script-src, style-src, img-src, font-src, connect-src, frame-ancestors, base-uri, object-src, form-action` (proxy.test.ts:35-45) — matches `buildCsp`'s directive array order exactly. (r2 cited this test as supporting evidence within Claim 3 without treating it as a standalone claim.)

**Evidence:** the `directives` array in proxy.ts:23-33 lists, in order: `"default-src 'self'"`, `` `script-src ...` ``, `"style-src 'self' 'unsafe-inline'"`, `"img-src 'self' data: blob:"`, `"font-src 'self' data:"`, `"connect-src 'self'"`, `"frame-ancestors 'none'"`, `"base-uri 'self'"`, `"object-src 'none'"`, `"form-action 'self'"`.

## Claim 6: proxy.ts — "Next.js 16 renamed Middleware → Proxy"

**Location:** proxy.ts:5
**Type:** Reference (framework)
**Verdict:** Verified
**Confidence:** Medium — the repo is on Next 16 and the file layout is consistent with the claim; the rename itself is framework history that cannot be confirmed from repo contents alone.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—

> `* CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces.` — proxy.ts:5

package.json pins `"next": "16.2.4"` and the file exports `export function proxy(request: NextRequest): NextResponse {` plus a root-level `config.matcher` — the middleware-convention shape under the new name. The rename claim matches Next.js 16's documented deprecation of `middleware.ts` in favor of `proxy.ts` (paraphrased — no quote available because `node_modules` is not installed in this worktree). The feature commit states the motivation: "File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning)" (git log 9b4e453) — consistent with a rename rather than a removal.

**Evidence:**
- `"next": "16.2.4",` — package.json:23
- `export function proxy(request: NextRequest): NextResponse {` — proxy.ts:38

## Claim 7: proxy.ts docstring — style-src 'unsafe-inline' rationale (named inline-style sites)

**Location:** proxy.ts:12-17
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** High for the overall rationale (19 non-test component files use inline `style` props); the one imprecise detail is directly readable in source.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate

> "Why `style-src 'unsafe-inline'`: many React components use inline `style={{...}}` props (e.g. proof-graph node positioning, refinement preview, collapsible sections), and Next.js's SSR style injection also emits inline <style> tags." — proxy.ts:12-15

"Many React components use inline `style={{...}}` props" is verified: 19 component files under `app/` match `style={{`, including all three named areas. Refinement preview: `style={{ lineHeight: 1.6 }}` (app/components/features/context-input/RefinementPreview.tsx:24 and :35). Collapsible sections: `<div style={open ? undefined : HIDDEN_STYLE}>{children}</div>` with `const HIDDEN_STYLE = { display: "none" } as const;` (app/components/ui/CollapsibleSection.tsx:51, :13). The imprecise detail (why r1/r3 downgrade; r2 called the same fact a "pedantic note" and kept Verified): "proof-graph node **positioning**" — the app's own proof-graph inline styles are colors and sizing, not positioning: `style={{ borderColor: statusColor, borderWidth: 2, minWidth: 160 }}` (app/components/features/proof-graph/ProofGraphNode.tsx:45), plus backgroundColor/color styles at lines 52, 58, 70. Actual node *positioning* inline styles are emitted by the React Flow library at runtime, not by app `style={{...}}` props (paraphrased — `node_modules` absent). The carve-out's justification stands either way — inline styles are pervasive — but the specific example is mislabeled.

**Evidence:**
- `style={{ borderColor: statusColor, borderWidth: 2, minWidth: 160 }}` — app/components/features/proof-graph/ProofGraphNode.tsx:45
- `style={{ lineHeight: 1.6 }}` — app/components/features/context-input/RefinementPreview.tsx:24
- `<div style={open ? undefined : HIDDEN_STYLE}>{children}</div>` — app/components/ui/CollapsibleSection.tsx:51
- 19 files matched by `rg -c "style=\{\{" app/ -g '*.tsx' -g '!*.test.*'` (paraphrased — count from ripgrep output)

## Claim 8: proxy.ts docstring — "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server"

**Location:** proxy.ts:18-19
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** High — full enumeration of client-side network initiations performed independently by all three replicates; the only inaccuracy is that no OpenAlex integration exists anywhere in the repo.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

> "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party." — proxy.ts:18-19

Enumeration of every client-side network initiation in `app/` (grep for `fetch(`, `XMLHttpRequest`, `new WebSocket`, `EventSource`, `sendBeacon`, `axios` over `*.ts`/`*.tsx` excluding tests):

- Same-origin relative fetches (allowed by `'self'`): `fetch("/api/analytics")` (app/hooks/useAnalytics.ts:11, :30); `fetch("/api/explanation/lean-error", {` (app/components/features/lean-display/LeanCodeDisplay.tsx:88); `fetch("/api/refine/context", {` (app/components/features/context-input/ContextInput.tsx:25); the shared helpers `fetchApi`/`fetchStreamingApi` (app/lib/formalization/api.ts:10, :38) whose call sites pass only relative routes — `"/api/decomposition/extract"` (app/hooks/useDecomposition.ts:130), `"/api/verification/lean"` (api.ts:104), edit routes (useArtifactEditing.ts, OutputPanel.tsx, SemiformalPanel.tsx, EditableSection.tsx), and `ARTIFACT_ROUTE[type]` lookups resolving to `/api/formalization/*` paths (app/lib/types/artifacts.ts).
- Server-side only (never runs in the browser): `fetch(OPENROUTER_API_URL, {` (app/lib/llm/callLlm.ts:164, app/lib/llm/streamLlm.ts:249) — the only importers of `callLlm`/`streamLlm` outside `app/lib/llm/` are API route files (`app/api/*/route.ts`) and `app/lib/formalization/artifactRoute.ts`, itself imported only by API routes; the client-shared `app/lib/formalization/api.ts` imports only a type. The Anthropic SDK lives in the same server-only module. `` fetch(`${LEAN_VERIFIER_URL}/verify`) `` (app/api/verification/lean/route.ts:21) is inside an API route.
- No WebSocket/EventSource/sendBeacon/XHR anywhere in `app/`; SSE streaming is consumed via same-origin `fetch` + `res.body.getReader()` (app/lib/formalization/api.ts). The former `fetch(dataUrl)` of a `data:` URL was removed in this range (Claim 2). pdfjs loads its worker from a bundled same-origin URL, not a CDN: `new URL("pdfjs-dist/build/pdf.worker.min.mjs", import.meta.url)` (app/lib/utils/fileExtraction.ts:26-29; app/lib/utils/pdfPropositionParser.ts:443-446) — governed by worker-src/script-src fallbacks, not connect-src, in any case.

So the sufficiency conclusion is correct. The inaccuracy: **OpenAlex is referenced nowhere in the repo except this comment itself** — `rg -il openalex` (excluding node_modules/package-lock) matches only `proxy.ts`. The claim that OpenAlex "calls are server-to-server" asserts calls that do not exist. r2/r3 add: "Anthropic" calls actually go through OpenRouter (app/lib/llm/callLlm.ts:164), not a direct Anthropic endpoint — a harmless reading, but noted.

**Evidence:**
- `export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";` — app/lib/llm/callLlm.ts:7
- `import { callLlm, OpenRouterError } from "@/app/lib/llm/callLlm";` — app/lib/formalization/artifactRoute.ts:2 (server-side consumer)
- `import type { LlmCallUsage } from "@/app/lib/llm/callLlm";` — app/lib/formalization/api.ts:3 (client-shared module imports type only)
- OpenAlex grep: only match is proxy.ts:18 (paraphrased — ripgrep produced a single-file result list)

## Claim 9: proxy.ts — "form-action does NOT fall back to default-src (CSP3); set explicitly"

**Location:** proxy.ts:31-33
**Type:** Configuration / reference (spec)
**Verdict:** Verified
**Confidence:** High for the directive's presence (r2); Medium overall per r1/r3 — the spec assertion matches CSP3's documented fallback list, which excludes `form-action`, but the spec itself is not consultable from this offline worktree.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

> `// form-action does NOT fall back to default-src (CSP3); set explicitly.` — proxy.ts

The directive is present immediately below: `"form-action 'self'",`, and pinned by the test: `expect(directives).toContain("form-action 'self'");`. The spec claim is accurate: in CSP3, `form-action` is a navigation directive and is not in the `default-src` fallback chain, so omitting it leaves form submissions unrestricted (paraphrased — no web access; well-established, stable spec behavior). r3 adds: attributing the no-fallback behavior specifically to "(CSP3)" if anything undersells it — it has been true since the directive was introduced in CSP2.

**Evidence:**
- `"form-action 'self'",` — proxy.ts
- `expect(directives).toContain("form-action 'self'");` — proxy.test.ts

## Claim 10: proxy.ts — 128-bit nonce; crypto.getRandomValues + Buffer available in the Node.js runtime Next 16 Proxy runs on by default

**Location:** proxy.ts:39-41
**Type:** Behavioral / configuration
**Verdict:** Verified
**Confidence:** Medium — the entropy arithmetic and API premises are solid (Next 16.2.4 requires Node >= 20.9.0 per the lockfile; global `crypto.getRandomValues` and `Buffer` are both available there); the "Node.js runtime by default" claim about Next 16 Proxy could not be confirmed from `node_modules` (absent) and rests on Next 16 documentation.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

> "Generate a fresh 128-bit nonce per request. crypto.getRandomValues + Buffer are both available in the Node.js runtime Next 16 Proxy runs on by default." — proxy.ts:39-40

Entropy: `crypto.getRandomValues(new Uint8Array(16))` fills 16 bytes = 128 bits of randomness — 16 × 8 = 128. Runtime premises: the lockfile records Next's engine requirement `{"node":">=20.9.0"}` for `next@16.2.4`. Global `crypto` (WebCrypto, including `getRandomValues`) has been available without flags since Node 19, and `Buffer` is a Node global — both hold on any Node >= 20.9 (paraphrased — platform behavior, not repo code). r3 adds: no runtime override is exported from proxy.ts (only `buildCsp`, `proxy`, and `config` with just a `matcher`), so the default runtime applies. That Next 16's Proxy defaults to the Node.js runtime (the 4f018ab commit message: "dropped Edge-runtime claim — Next 16 Proxy runs on Node.js by default") is consistent with Next 16 documentation but not independently confirmable offline.

**Evidence:**
- `const nonce = Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64");` — proxy.ts:41
- Next engines `{"node":">=20.9.0"}`, version 16.2.4 — package-lock.json, `packages["node_modules/next"]` (paraphrased — JSON object, no stable line number)

## Claim 11: proxy.ts — forward the nonce via request header "so layouts can read it via headers() and pass it to `<Script>` tags"

**Location:** proxy.ts:44-45
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** High — the header is set, but a repo-wide grep shows `x-nonce` is never read, and no layout passes a nonce to any `<Script>`; the intermediate commit in this very range concedes the point.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

> "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to `<Script>` tags they render." — proxy.ts:44-45

The capability is real: `requestHeaders.set("x-nonce", nonce);` makes the nonce readable by any server component via `headers()`. But nothing exercises it — `rg -n "x-nonce"` across the repo matches only proxy.ts:49 (the write); `app/layout.tsx` calls `await headers();` without reading the result, and no `<Script>` receives a nonce prop anywhere. The range's own commit d90d6bb states this: "headers() is called to opt out of static rendering … not to read x-nonce (the nonce is only written, never read by the layout)" (git log d90d6bb). The comment describes an unused capability as if it were the delivery mechanism; the mechanism actually in play is the request-side CSP header on the next line (proxy.ts:50, see Claims 1 and 12). Not wrong as a statement of what layouts *could* do ("can" technically survives, per r3), but it points readers at the wrong wire.

**Evidence:**
- `requestHeaders.set("x-nonce", nonce);` — proxy.ts:49 (sole `x-nonce` occurrence in the repo)
- `await headers();` — app/layout.tsx (return value discarded)
- "the nonce is only written, never read by the layout" — git log d90d6bb

## Claim 12: proxy.ts — "Setting CSP on both the forwarded request and the response matches the canonical Next.js docs example"

**Location:** proxy.ts:46-47
**Type:** Behavioral / reference
**Verdict:** Verified
**Confidence:** Medium — both settings are directly verified in code (High); the correspondence to the Next.js docs CSP example is from documented framework guidance, not consultable offline.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

(Clustering note: r2 assessed this sentence jointly with the x-nonce clause as one combined claim with printed verdict Mostly accurate; its severity driver was entirely the x-nonce clause, merged here as Claim 11 — r2's assessment of the docs-example assertion itself was verifying, so it is recorded as Verified for this cluster.)

> "Setting CSP on both the forwarded request and the response matches the canonical Next.js docs example." — proxy.ts:46-47

Both settings exist: request side — `requestHeaders.set("Content-Security-Policy", csp);` (proxy.ts:50), passed onward via `NextResponse.next({ request: { headers: requestHeaders } })` (proxy.ts:52-54); response side — `response.headers.set("Content-Security-Policy", csp);` (proxy.ts:55). Each serves a distinct purpose: the request-side copy is what Next.js's renderer parses the nonce out of when tagging its bootstrap scripts (r3: functionally load-bearing, not just docs-conformance), and the response-side copy is what the browser enforces. The Next.js CSP guide's middleware example does exactly this dual set — `x-nonce` plus `Content-Security-Policy` on the forwarded request headers, and the same CSP on the response (paraphrased — docs external, environment offline).

**Evidence:**
- `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:50
- `response.headers.set("Content-Security-Policy", csp);` — proxy.ts:55

## Claim 13: proxy.ts matcher — applies CSP to page navigations only; skips API routes, static assets, prefetches

**Location:** proxy.ts:57-62
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High — the matcher pattern and both `missing` entries are read directly and do what the comment says.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

> "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)." — proxy.ts

The source pattern `"/((?!api|_next/static|_next/image|favicon.ico).*)"` is a negative lookahead excluding paths beginning `api`, `_next/static`, `_next/image`, and `favicon.ico` — API routes and Next's static asset paths, as claimed. Prefetches are excluded via the `missing` conditions: `{ type: "header", key: "next-router-prefetch" },` and `{ type: "header", key: "purpose", value: "prefetch" },`, which match only requests *lacking* those prefetch-marker headers (paraphrased — `missing` semantics are Next.js matcher behavior; the config shape matches the documented convention). Both header keys are the standard Next.js/browser prefetch markers. Minor completeness note (r2/r3): `_next/image` and `favicon.ico` are skipped but not itemized in the prose; they fall under "static assets" reasonably.

**Evidence:**
- `source: "/((?!api|_next/static|_next/image|favicon.ico).*)",` — proxy.ts
- `{ type: "header", key: "next-router-prefetch" },` — proxy.ts
- `{ type: "header", key: "purpose", value: "prefetch" },` — proxy.ts

## Claim 14: Commit 9b4e453 — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates"

**Location:** git log 9b4e453 (commit message)
**Type:** Behavioral (verification claim)
**Verdict:** Unverifiable
**Confidence:** Low — it reports a manual build-time observation that cannot be replayed offline, and there is a code-level reason to doubt the second half as of that commit.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=— · r3=— · single-replicate detection

> "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates." — git log 9b4e453

The first half (response header emitted) is consistent with the code at 9b4e453: `response.headers.set("Content-Security-Policy", csp);` (present in `git show 9b4e453:proxy.ts`). The second half is in tension with the wiring at that commit: 9b4e453 forwarded only `x-nonce` on the request — no request-side `Content-Security-Policy` — while Next.js extracts the nonce it applies to its scripts from the request's CSP header (paraphrased — `node_modules` absent). If that mechanism is right, nonce application would only have begun working at 4f018ab, which added `requestHeaders.set("Content-Security-Policy", csp);` and justified it as "matching the canonical Next.js 16 docs example" (git log 4f018ab). The build cannot be rerun offline to settle whether the 9b4e453 observation was mistaken or Next has another nonce path; flagged for escalation. (r2 independently noted the same wiring gap at the intermediate commits within its Claim 1, without raising it as a standalone claim.)

**Evidence:**
- 9b4e453 proxy body sets `x-nonce` but not a request-side CSP header (paraphrased — from `git show 9b4e453:proxy.ts`)
- `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:50 (added by 4f018ab)

## Claim 15: Commit 9b4e453 — XSS-surface claims ("no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false")

**Location:** git log 9b4e453 (commit message)
**Type:** Behavioral (XSS surface)
**Verdict:** Mostly accurate
**Confidence:** High — greps are conclusive for the first two; the third is true only as a default, not as explicit configuration.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate

> "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)" — git log 9b4e453

- `rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" app/` (excluding tests): zero hits. Both "no" claims verified.
- Markdown rendering goes through ReactMarkdown with only `remarkGfm`, `remarkMath`, `rehypeKatex`: `const remarkPlugins = [remarkGfm, remarkMath]; const rehypePlugins = [rehypeKatex];` — app/components/features/output-editing/LatexRenderer.tsx:9-10.
- **The inaccuracy:** `rehypeKatex` is used with no options object, so KaTeX `trust` is the library **default** of `false` — nothing in the codebase sets `trust: false` explicitly (`rg -n "trust"` finds no KaTeX-related hit). The security posture claimed is real, but "KaTeX trust:false" reads as a deliberate configuration when it is an inherited default that a future options object could silently change.

**Evidence:**
- `const remarkPlugins = [remarkGfm, remarkMath]; const rehypePlugins = [rehypeKatex];` — app/components/features/output-editing/LatexRenderer.tsx:9-10
- Zero-hit grep results described above (paraphrased — the assertions are about absence of matches)

## Claim 16: Commit d90d6bb — "No behavior change; CSP directives preserved exactly … 221/221 tests pass"

**Location:** git log d90d6bb (commit message)
**Type:** Behavioral / staleness
**Verdict:** Verified
**Confidence:** High for behavior-neutrality (diff read directly); Medium for the test count (statically consistent, not executed).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

> "No behavior change; CSP directives preserved exactly. Lint clean; 221/221 tests pass." — git log d90d6bb

`git diff b25e939 d90d6bb` touches only comments, an added explicit return type (`export function proxy(request: NextRequest): NextResponse {`), and inlining of a single-use local (`response.headers.set("Content-Security-Policy", buildCsp(nonce));` replacing the `csp` temporary) — no directive strings change; app/layout.tsx changes are comment-only per the same diff. The 221 count is consistent with the tree at 4f018ab: static count of `it(`/`test(` declarations across all `*.test.*` files is 225, of which 4 are the proxy.test.ts cases added *after* d90d6bb — 225 − 4 = 221. Pass/fail cannot be executed offline (no `node_modules`). r3 also verified the same commit message's "the nonce is only written, never read by the layout" sentence (repo-wide grep: `x-nonce` appears exactly once, as a write — see Claim 11).

**Evidence:**
- `export function proxy(request: NextRequest): NextResponse {` — proxy.ts:38 (the added return type)
- Diff hunks: `- const csp = buildCsp(nonce);` / `+ response.headers.set("Content-Security-Policy", buildCsp(nonce));` — `git diff b25e939..d90d6bb`
- Static test-case count 225 total, 4 in proxy.test.ts (paraphrased — ripgrep count summed across files)

## Claim 17: Commit 4f018ab — "full 128-bit nonce entropy (UUID-based was 122 bits)"

**Location:** git log 4f018ab (commit message)
**Type:** Behavioral / arithmetic
**Verdict:** Verified
**Confidence:** High — both halves check arithmetically against the before/after code.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

> "Use crypto.getRandomValues(Uint8Array(16)) for full 128-bit nonce entropy (UUID-based was 122 bits)." — git log 4f018ab

After: `crypto.getRandomValues(new Uint8Array(16))` (proxy.ts:41) = 16 bytes × 8 = 128 random bits. Before: the 9b4e453/d90d6bb implementation was `const nonce = Buffer.from(crypto.randomUUID()).toString("base64");` (r2: `git show d90d6bb:proxy.ts` line 37). `crypto.randomUUID()` returns an RFC 4122 version-4 UUID, which fixes 4 version bits and 2 variant bits of its 128, leaving 122 bits of entropy (paraphrased — UUID spec, external to the repo). Base64-encoding the UUID string changes length, not entropy. Both figures are correct; no `randomUUID` remains in proxy.ts.

**Evidence:**
- `const nonce = Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64");` — proxy.ts:41
- `const nonce = Buffer.from(crypto.randomUUID()).toString("base64");` — proxy.ts:37 at d90d6bb (via `git show d90d6bb:proxy.ts`)

## Claim 18: Commit 4f018ab — "225/225 tests pass", toBlob doesn't violate connect-src, and the new test "disallows unsafe-eval, wildcards, and http:"

**Location:** git log 4f018ab (commit message)
**Type:** Behavioral (multiple sub-claims)
**Verdict:** Mostly accurate
**Confidence:** High for the incorrect sub-claim (regex demonstration); Medium for the test count (statically consistent, not executable); Medium for the toBlob sub-claim (see Claim 2).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Unverifiable · r3=Unverifiable

(Clustering note: r2 and r3 scoped this cluster to the "Lint clean; 225/225 tests pass" line alone and rated it Unverifiable; r1 assessed the full commit-message claim set including the test-description sub-claim, yielding Mostly accurate. Most-severe verdict wins; r1's evidence carried.)

Three checkable sub-claims:

1. > "Lint clean; 225/225 tests pass." — git log 4f018ab
   The count is exactly consistent with the tree: summing `it(`/`test(` declarations across every `*.test.*` file yields 225, with no `it.each`/`test.each` parameterization that would inflate runtime counts; r3 cross-check: d90d6bb claims 221/221 and proxy.test.ts adds exactly 4 `it(` blocks, 221 + 4 = 225 — the two commit messages are internally consistent. Pass/lint status not executable offline (no `node_modules`) — count verified, execution taken on faith.
2. > "switch from toPng + fetch(dataUrl) to toBlob so PNG graph export and zip export don't violate connect-src 'self'." — git log 4f018ab
   Verified — see Claim 2; both `downloadGraphAsPng` and `graphToPngBlob` (the zip-embedding path, app/lib/utils/exportGraph.ts:33-35) now route through the fetch-free `renderGraphPng` (app/lib/utils/exportGraph.ts:17-24).
3. > "New proxy.test.ts pins the directive list … and disallows unsafe-eval, wildcards, and http:." — git log 4f018ab
   The pinning half is Verified (Claim 3); the "disallows … wildcards, and http:" half is **Incorrect** — the assertions do not match realistic wildcard or http: forms (Claim 4). The commit message propagates the test's overclaim.

**Evidence:**
- `export function graphToPngBlob(viewportElement: HTMLElement): Promise<Blob> { return renderGraphPng(viewportElement); }` — app/lib/utils/exportGraph.ts:33-35 (paraphrased line-joining of the two-line body)
- `expect(csp).not.toMatch(/\bhttp:\b/);` — proxy.test.ts (see Claim 4 for the failing demonstration)
- Summed `rg -c "^\s*(it|test)\(" -g '*.test.*'` = 225 (paraphrased — aggregate count across 30+ test files)

## Claims Requiring Attention

### Incorrect
- **Claim 4** (proxy.test.ts:27-31): the "does not allow eval, wildcards, or http: schemes anywhere" test enforces only the eval part. `/\*\s/` misses a wildcard at the end of a directive (`img-src *;` or a final `form-action *` → no match) and `/\bhttp:\b/` matches neither the `http:` scheme source nor `http://host` URLs (the trailing `\b` after `:` requires a following word character, which `//`, space, and end-of-string all fail). A refactor to `img-src *` or `style-src http:` would pass the full suite, since img-src/font-src/style-src are not pinned elsewhere. Found independently by all three replicates with executed-regex demonstrations. Cheap fix: `not.toMatch(/\bhttp:/)` and `/(^|\s)\*(;|\s|$)/`, or per-directive pins.
- **Claim 18, sub-claim 3** (git log 4f018ab): the commit message repeats the same overclaim ("disallows unsafe-eval, wildcards, and http:").

### Stale
- None.

### Mostly Accurate
- **Claim 7** (proxy.ts:12-15): style-src rationale is sound and all three named sites use inline styles, but "proof-graph node positioning" mislabels what the app's own inline styles do there (colors/sizing; positioning styles come from the React Flow library). (r2 rated Verified, treating the same fact as a pedantic note — 2-of-3 downgrade wins.)
- **Claim 8** (proxy.ts:18-19): connect-src 'self' sufficiency fully verified by enumeration in all three replicates, but OpenAlex — named as one of the three server-to-server integrations — does not exist anywhere in the repo; Anthropic calls actually go via OpenRouter.
- **Claim 11** (proxy.ts:44-45): x-nonce is written but never read; the comment presents an unused capability as the delivery path, while the operative mechanism is the request-side CSP header set on the next line.
- **Claim 15** (git log 9b4e453): "KaTeX trust:false" is the library default, not an explicit setting; `rehypeKatex` is invoked with no options object, so a future options object could silently change the posture.
- **Claim 18** (git log 4f018ab): two of three sub-claims hold (225 test count statically corroborated; toBlob/connect-src verified); the third is the Incorrect test overclaim above. (r2/r3 scoped this to the test-count line and rated Unverifiable.)

### Unverifiable
- **Claim 14** (git log 9b4e453): "Next applies the nonce to every `<script>` tag" was claimed as verified at a commit that did not yet forward the CSP on the request — the header Next.js reads the nonce from. Cannot be replayed offline; see Escalate. (Single-replicate detection, r1; r2 independently noted the same wiring gap in passing.)

## Verdict stability

- **Total clusters:** 18
- **Agreed (all present replicates identical):** 16 — Claims 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 (Claims 5 and 14 single-replicate; Claims 6 and 15 two-replicate; Claim 12 recorded as agreed per the clustering note — r2's printed Mostly-accurate on the combined comment block was driven by the Claim-11 clause)
- **Disagreeing:** 2
  - Claim 7 (style-src rationale): r1=Mostly accurate · r2=Verified · r3=Mostly accurate → merged Mostly accurate (same underlying fact found by all three; severity judgment differed)
  - Claim 18 (4f018ab commit message): r1=Mostly accurate · r2=Unverifiable · r3=Unverifiable → merged Mostly accurate (scope difference: r1 included the test-overclaim sub-claim)
- **Agreement rate:** 16/18 = 88.9%

## Goal-Alignment Note
- Answered: All nine briefed items, by all three replicates — client network-initiation enumeration for connect-src (Claim 8), nonce delivery end-to-end (Claims 1, 11, 12), runtime/API availability (Claim 10), dual CSP setting (Claim 12), style-src named sites (Claim 7), form-action fallback (Claim 9), test-coverage claims (Claims 3, 4, 5), commit 4f018ab's entropy/test-count/toBlob claims (Claims 17, 18, 2), and the matcher (Claim 13). Additional coverage beyond the brief: 9b4e453's XSS-surface claims (Claim 15, r2+r3) and its "verified prod build" claim (Claim 14, r1).
- Out of scope: Whether `'strict-dynamic'` in script-src could break the same-origin pdfjs worker load (worker-src falls back through child-src to script-src, where `'strict-dynamic'` discards `'self'`) — a potential functional regression for PDF upload under this CSP, but a code-review finding, not a documentation-accuracy one (r1, r3). Whether `style-src 'unsafe-inline'` or the vacuous test regexes are *acceptable* security posture (reviewer judgment — r2). Running the test suite or lint; browser-level CSP behavior verification.
- Escalate: (1) All three replicates: the proxy.test.ts wildcard/http: assertions are security tests that assert nothing — the guard would also pass after a refactor adding `http:` sources or a trailing wildcard, defeating the test's stated purpose and misleading a reviewer relying on it (and on the 4f018ab commit message's repetition of the claim); cheap two-line regex fix, or per-directive pins for style-src/img-src/font-src, in the review-fix loop. (2) r1: Claim 14's tension — if Next reads the nonce only from the request CSP header, nonce injection was non-functional at 9b4e453 despite the commit's "verified" claim, and the range's manual-verification evidence should not be trusted for the current state either; recommend the E1 orchestrator note that runtime verification (prod build + header inspection) has not been performed for 4f018ab. (3) r1, r3, for the security critic: pdf.js Web Worker loading (app/lib/utils/fileExtraction.ts:26, pdfPropositionParser.ts:443) under `script-src 'strict-dynamic'` + no explicit worker-src is worth a functional check — not a doc-accuracy issue, but adjacent to the CSP claims verified here.
