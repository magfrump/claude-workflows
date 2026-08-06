# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-csp-clean, detached HEAD)
**Scope:** `git diff d86d2dc..4f018ab` — CSP feature (9b4e453) plus review-fix commits (b25e939, d90d6bb, 4f018ab); comments, docstrings, and commit messages in that range
**Checked:** 2026-08-06
**Total claims checked:** 16
**Summary:** 8 Verified, 5 Mostly accurate, 1 Incorrect, 0 Stale, 2 Unverifiable. The one Incorrect finding is proxy.test.ts's claim that it disallows "wildcards, or http: schemes anywhere": the `/\bhttp:\b/` regex can never match a realistic `http:` source (the `\b` after `:` requires a following word character, which `//`, space, or end-of-string never supply), and the `/\*\s/` wildcard regex misses a `*` at the end of any directive. The four named directive pins are exact-string matches and do hold. All other checked claims are accurate or accurate-with-minor-imprecision; notably, the "connect-src 'self' is sufficient" claim survives full enumeration of client-side network initiations, and the review-fix removal of `fetch(dataUrl)` was the only data:-URL fetch in the app.

**Commit:** 4f018ab

## Claim 1: layout.tsx — dynamic rendering lets the rendered HTML pick up the nonce set by proxy.ts

**Location:** app/layout.tsx:27-30
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** Medium — the in-repo wiring is fully verified by reading code; the Next.js-internal half (which request header Next reads the nonce from) rests on knowledge of Next.js documented behavior, not on inspectable vendored code (`node_modules` is absent from the worktree).
**Legibility-target:** for-orchestrator-synthesis

The comment claims:

> "Opt this layout into dynamic rendering so Next.js injects the per-request nonce (set by proxy.ts) into its own bootstrap `<script>` tags during render. The proxy already runs per request via its matcher; the dynamic-rendering switch is what lets the rendered HTML pick up the nonce." — app/layout.tsx:24-27

End-to-end delivery mechanism: Next.js (App Router) reads the nonce out of the **`Content-Security-Policy` request header** — not `x-nonce` — when rendering, and applies it to its own bootstrap scripts. Paraphrased — no quote available because the Next.js source is not vendored in this worktree (`node_modules` does not exist) and network access to nextjs.org is blocked in this environment; this is documented Next.js behavior (its CSP guide's `getScriptNonceFromHeader` path). The app-side half of that channel is present and verified:

**Evidence:**
- `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:50 (the header Next reads the nonce from is set on the **forwarded request**)
- `const nonce = Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64");` then `` const csp = buildCsp(nonce) `` with `` `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'` `` — proxy.ts:41-42, proxy.ts:25 (the CSP string embeds the nonce, so the request header carries it)
- `await headers();` — app/layout.tsx:28 (calling `headers()` opts the route into dynamic rendering, standard Next.js semantics)
- "The proxy already runs per request via its matcher" — consistent with the matcher covering all page navigations: `source: "/((?!api|_next/static|_next/image|favicon.ico).*)"` — proxy.ts:63

## Claim 2: exportGraph.ts — toBlob avoids needing `data:` in connect-src

**Location:** app/lib/utils/exportGraph.ts:6
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium — the removal of the only `fetch(dataUrl)` call is directly verified; the assertion that `html-to-image`'s `toBlob` performs no network fetch rests on library knowledge (renders to canvas, calls `canvas.toBlob`) and could not be confirmed against vendored source because `node_modules` is absent.
**Legibility-target:** for-orchestrator-synthesis

> "// Use toBlob (not toPng + fetch) so we don't need `data:` in CSP connect-src." — app/lib/utils/exportGraph.ts:6

**Evidence:**
- New implementation contains no fetch: `const blob = await toBlob(viewportElement, { pixelRatio: 2, backgroundColor: EXPORT_BG });` — app/lib/utils/exportGraph.ts:18-21
- The removed code (visible in the diff) was `const dataUrl = await toPng(...); const res = await fetch(dataUrl);` — diff hunk for app/lib/utils/exportGraph.ts (old lines 20-24)
- Repo-wide search confirms no other `fetch` of a `data:`/`blob:` URL remains: the only `data:` hits in `app/lib/utils/` are pdf.js `getDocument({ data: buffer })` (in-memory, not a URL fetch) — app/lib/utils/fileExtraction.ts:37, app/lib/utils/pdfPropositionParser.ts:449 — and this comment itself.
- CSP indeed has no `data:` in connect-src: `"connect-src 'self'"` — proxy.ts:29
- Note: `toBlob` renders via a `data:`-URL SVG image, which is covered by `"img-src 'self' data: blob:"` — proxy.ts:27. Paraphrased — no quote available because html-to-image source is not vendored in this worktree.

## Claim 3: proxy.test.ts header — pins the directive list so weakening the four named directives fails loudly

**Location:** proxy.test.ts:3-6
**Type:** Behavioral (test coverage)
**Verdict:** Verified
**Confidence:** High — the assertions are exact-string membership checks against the split directive list; any change to those directive strings fails the test.
**Legibility-target:** for-orchestrator-synthesis

> "// Pin the CSP directive list so a refactor that weakens script-src, connect-src, frame-ancestors, or object-src fails loudly in tests rather than silently shipping." — proxy.test.ts:3-5

All four named directives are pinned as exact strings, so any weakening edit to them fails:

**Evidence:**
- `` expect(directives).toContain(`script-src 'self' 'nonce-${NONCE}' 'strict-dynamic'`) `` — proxy.test.ts:14-16
- `expect(directives).toContain("connect-src 'self'");` — proxy.test.ts:21
- `expect(directives).toContain("frame-ancestors 'none'");` — proxy.test.ts:22
- `expect(directives).toContain("object-src 'none'");` — proxy.test.ts:23
- Caveat: `toContain` on the split list catches *modification* of these directives but not *addition* of a second, weaker source list under the same directive name elsewhere in the string; the stable-order test (proxy.test.ts:34-46) closes that gap by pinning the full directive-name sequence.

## Claim 4: proxy.test.ts — "does not allow eval, wildcards, or http: schemes anywhere"

**Location:** proxy.test.ts:27-31
**Type:** Behavioral (test coverage)
**Verdict:** Incorrect
**Confidence:** High — regex behavior confirmed by direct execution against adversarial CSP strings.
**Legibility-target:** for-author

> `it("does not allow eval, wildcards, or http: schemes anywhere", () => { expect(csp).not.toMatch(/'unsafe-eval'/); expect(csp).not.toMatch(/\*\s/); // wildcard source not followed by directive end expect(csp).not.toMatch(/\bhttp:\b/); });` — proxy.test.ts:27-31

The `unsafe-eval` assertion works. The other two do not enforce what the test name claims:

- **`/\bhttp:\b/` is vacuous.** The trailing `\b` after `:` (a non-word character) only asserts a boundary if the *next* character is a word character. In every realistic CSP source — `http://evil.com`, bare-scheme `http:` followed by a space, or `http:` at end of string — the next character is `/`, space, or nothing, so the regex never matches. A refactor adding `http://evil.com` or a bare `http:` scheme source to any directive passes this test.
- **`/\*\s/` misses wildcards at directive end.** Directives are joined with `"; "` (proxy.ts:34), so a directive ending in `*` is followed by `;` (not whitespace) or end-of-string. `img-src *` or a final `form-action *` passes the test; only a `*` in the middle of a source list (e.g. `script-src * 'self'`) is caught. The inline comment "wildcard source not followed by directive end" acknowledges this but the test *name* claims wildcards are disallowed "anywhere".

**Evidence:** executed in Node against constructed CSP strings:

```
/\*\s/.test("img-src *; font-src 'self'")        → false   (wildcard at directive end: NOT caught)
/\*\s/.test("form-action *")                     → false   (wildcard in final directive: NOT caught)
/\*\s/.test("script-src * self")                 → true    (mid-list wildcard: caught)
/\bhttp:\b/.test("connect-src http://evil.com")  → false   (NOT caught)
/\bhttp:\b/.test("script-src http: 'self'")      → false   (NOT caught)
/\bhttp:\b/.test("script-src http:")             → false   (NOT caught)
```

Suggested-shape fix (for the author): `/\bhttp:/` (drop trailing `\b`) and `/\*(?=[\s;]|$)/` or simply `/(^|\s)\*(;|\s|$)/`.

## Claim 5: proxy.test.ts — "emits the directive list in stable order"

**Location:** proxy.test.ts:34-46
**Type:** Behavioral (test coverage)
**Verdict:** Verified
**Confidence:** High — direct comparison of the two lists.
**Legibility-target:** for-orchestrator-synthesis

The expected order in the test — `default-src, script-src, style-src, img-src, font-src, connect-src, frame-ancestors, base-uri, object-src, form-action` (proxy.test.ts:35-45) — matches `buildCsp`'s directive array order exactly.

**Evidence:** the `directives` array in proxy.ts:23-33 lists, in order: `"default-src 'self'"`, `` `script-src ...` ``, `"style-src 'self' 'unsafe-inline'"`, `"img-src 'self' data: blob:"`, `"font-src 'self' data:"`, `"connect-src 'self'"`, `"frame-ancestors 'none'"`, `"base-uri 'self'"`, `"object-src 'none'"`, `"form-action 'self'"`.

## Claim 6: proxy.ts docstring — style-src 'unsafe-inline' rationale (named inline-style sites)

**Location:** proxy.ts:12-17
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** High for the existence of inline `style={{...}}` props at all three named sites; the "node positioning" descriptor is imprecise, and the Next.js SSR style-injection half is asserted from framework knowledge.
**Legibility-target:** for-author

> "Why `style-src 'unsafe-inline'`: many React components use inline `style={{...}}` props (e.g. proof-graph node positioning, refinement preview, collapsible sections), and Next.js's SSR style injection also emits inline <style> tags." — proxy.ts:12-15

All three named sites do use inline style props (19 component files in `app/` use `style={{` in total), so the carve-out rationale is sound. One imprecision: the ProofGraphNode inline styles are **colors and sizing, not positioning** — node positioning inline styles are emitted by the React Flow library itself, not this file.

**Evidence:**
- Proof graph: `style={{ borderColor: statusColor, borderWidth: 2, minWidth: 160 }}` — app/components/features/proof-graph/ProofGraphNode.tsx:45; also `style={{ backgroundColor: badgeColor }}` (line 52), `style={{ backgroundColor: statusColor }}` (line 58), `style={{ color: data.sourceColor }}` (line 70). None of these is positioning.
- Refinement preview: `style={{ lineHeight: 1.6 }}` — app/components/features/context-input/RefinementPreview.tsx:24 and :35
- Collapsible sections: `const HIDDEN_STYLE = { display: "none" } as const;` (app/components/ui/CollapsibleSection.tsx:13) used as `<div style={open ? undefined : HIDDEN_STYLE}>{children}</div>` — app/components/ui/CollapsibleSection.tsx:51
- "many React components": `rg -l "style=\{\{" app/` returns 19 `.tsx` files — paraphrased — no quote available because the evidence is a file-list count, not a single line.
- Next.js SSR inline `<style>` injection: paraphrased — no quote available because it happens inside framework rendering code not vendored in this worktree; it is standard Next.js behavior and consistent with the 4f018ab commit message's note that Tailwind v4 emits external CSS while SSR still injects inline styles.

## Claim 7: proxy.ts docstring — "connect-src 'self' is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server"

**Location:** proxy.ts:18-19
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** High for the conclusion (full enumeration of client-side network initiations found only same-origin targets); the premise's mention of OpenAlex is unsupported — no OpenAlex call exists anywhere in the app.
**Legibility-target:** for-author

> "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party." — proxy.ts:18-19

Enumeration of every client-side network initiation in `app/` (fetch / XMLHttpRequest / WebSocket / EventSource / sendBeacon / axios — only `fetch` is used anywhere):

**Browser-side fetches (all same-origin, relative `/api/...` URLs — allowed by `connect-src 'self'`):**
- `fetch("/api/analytics")` and `fetch("/api/analytics", { method: "DELETE" })` — app/hooks/useAnalytics.ts:11, :30
- `fetch("/api/explanation/lean-error", ...)` — app/components/features/lean-display/LeanCodeDisplay.tsx:88
- `fetch("/api/refine/context", ...)` — app/components/features/context-input/ContextInput.tsx:25
- `fetchApi`/`fetchStreamingApi` (app/lib/formalization/api.ts:10, :38) — every call site passes a relative URL: `"/api/verification/lean"` (api.ts:104), `"/api/formalization/lean"` (api.ts:121, :137), `"/api/formalization/semiformal"` (api.ts:146, :159), `"/api/decomposition/extract"` (app/hooks/useDecomposition.ts:130), and `ARTIFACT_ROUTE[type]` values which are all `"/api/formalization/..."` paths — app/lib/types/artifacts.ts:192-197

**Server-side only (never shipped to the browser):**
- `fetch(OPENROUTER_API_URL, ...)` — app/lib/llm/callLlm.ts:164 and app/lib/llm/streamLlm.ts:249; `callLlm`/`streamLlm` are imported only by `app/api/**/route.ts` files and server-side lib helpers (`app/lib/formalization/artifactRoute.ts`, itself imported only from `app/api/formalization/*/route.ts`)
- `` fetch(`${LEAN_VERIFIER_URL}/verify`, ...) `` — app/api/verification/lean/route.ts:21 (API route)

**Non-connect-src initiations checked:** the former `fetch(dataUrl)` in exportGraph.ts is removed (Claim 2); pdf.js worker loading (`GlobalWorkerOptions.workerSrc = new URL("pdfjs-dist/build/pdf.worker.min.mjs", import.meta.url)` — app/lib/utils/fileExtraction.ts:26-29, app/lib/utils/pdfPropositionParser.ts:443-446) resolves to a same-origin bundled asset and is governed by worker-src/script-src, not connect-src; `URL.createObjectURL(blob)` for downloads (app/lib/utils/export.ts:8) creates a link href, not a connection. No WebSocket/EventSource/sendBeacon/XHR anywhere.

**The imprecision:** "OpenAlex" appears nowhere in the codebase except this docstring (`rg -il openalex` matches only proxy.ts) — there are no OpenAlex calls, server-side or otherwise. And "Anthropic" calls actually go through OpenRouter (app/lib/llm/callLlm.ts:164), not to Anthropic directly. The conclusion — connect-src 'self' is sufficient — is fully verified; the premise names one integration that does not exist.

## Claim 8: proxy.ts — "form-action does NOT fall back to default-src (CSP3); set explicitly"

**Location:** proxy.ts:31
**Type:** Reference (spec) + configuration
**Verdict:** Verified
**Confidence:** Medium — the directive's presence is directly verified; the spec claim rests on knowledge of the CSP specification (network access to the spec is blocked in this environment).
**Legibility-target:** for-orchestrator-synthesis

> "// form-action does NOT fall back to default-src (CSP3); set explicitly." — proxy.ts:31

**Evidence:**
- The directive is present: `"form-action 'self'"` — proxy.ts:32, and pinned in the test: `expect(directives).toContain("form-action 'self'");` — proxy.test.ts:24
- Spec claim: paraphrased — no quote available because network access is blocked; per the CSP3 specification (and CSP Level 2 before it), `form-action` is a navigation directive and does not consult the `default-src` fallback list, so omitting it would leave form submission targets unrestricted. The claim is correct; if anything, attributing the no-fallback behavior specifically to "(CSP3)" undersells it — it has been true since the directive was introduced in CSP2.

## Claim 9: proxy.ts — 128-bit nonce; crypto.getRandomValues + Buffer available in the Node.js runtime Next 16 Proxy runs on by default

**Location:** proxy.ts:39-40
**Type:** Configuration / reference (runtime)
**Verdict:** Verified
**Confidence:** Medium — the entropy and API-usage halves are directly verified; the "Next 16 Proxy defaults to the Node.js runtime" half rests on framework knowledge (Next 16 renamed middleware to proxy and made Node.js the default runtime; Next 16 requires Node ≥ 20.9, where `globalThis.crypto` (global since Node 19) and `Buffer` are both available). Not confirmable against vendored code or docs from this sandbox.
**Legibility-target:** for-orchestrator-synthesis

> "// Generate a fresh 128-bit nonce per request. crypto.getRandomValues + Buffer are both available in the Node.js runtime Next 16 Proxy runs on by default." — proxy.ts:39-40

**Evidence:**
- `const nonce = Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64");` — proxy.ts:41. 16 bytes × 8 = 128 bits of entropy.
- Next version: `"next": "16.2.4"` — package.json:23
- No runtime override is exported from proxy.ts (the only exports are `buildCsp`, `proxy`, and `config` with just a `matcher` — proxy.ts:21, :37, :56), so the default runtime applies.
- Runtime-default and API-availability premises: paraphrased — no quote available because `node_modules` is absent and network access is blocked (see Confidence note).

## Claim 10: proxy.ts — x-nonce forwarded "so layouts can read it via headers() and pass it to `<Script>` tags"

**Location:** proxy.ts:44-46
**Type:** Architectural (capability)
**Verdict:** Mostly accurate
**Confidence:** High — the forwarding is directly verified; the capability it describes is real but unused by any current code, which the comment's phrasing ("can") technically survives but a reader could mistake for current behavior.
**Legibility-target:** for-author

> "// Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to `<Script>` tags they render." — proxy.ts:44-45

**Evidence:**
- `requestHeaders.set("x-nonce", nonce);` — proxy.ts:49
- Nothing reads it: `rg -n "x-nonce"` across the repo matches only proxy.ts:49. app/layout.tsx calls `await headers()` but discards the result (app/layout.tsx:28), and no component renders a nonce-bearing `<Script>`. The d90d6bb commit message states this explicitly: "the nonce is only written, never read by the layout" (see Claim 15). The comment describes a supported affordance, not exercised behavior — accurate as written ("can"), but worth tightening.

## Claim 11: proxy.ts — "Setting CSP on both the forwarded request and the response matches the canonical Next.js docs example"

**Location:** proxy.ts:46-47
**Type:** Reference (docs) + configuration
**Verdict:** Verified
**Confidence:** Medium — both settings are directly verified in code; the docs-example correspondence rests on knowledge of the Next.js CSP guide (which does set the CSP header on both the forwarded request headers and the response), unverifiable live because network access is blocked.
**Legibility-target:** for-orchestrator-synthesis

> "// Setting CSP on both the forwarded request and the response matches the canonical Next.js docs example." — proxy.ts:46-47

**Evidence:**
- Request side: `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:50, passed via `NextResponse.next({ request: { headers: requestHeaders } })` — proxy.ts:52-53
- Response side: `response.headers.set("Content-Security-Policy", csp);` — proxy.ts:55
- Purpose: the request-side copy is functionally load-bearing, not just docs-conformance — it is the channel Next.js reads the nonce from during render (see Claim 1). The response-side copy is what the browser enforces. Docs correspondence: paraphrased — no quote available because network access is blocked.

## Claim 12: proxy.ts matcher comment — skip API routes, static assets, and prefetches

**Location:** proxy.ts:57-59
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High — the pattern and `missing` entries directly implement each named exclusion.
**Legibility-target:** for-orchestrator-synthesis

> "// Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)." — proxy.ts:57-59

**Evidence:**
- `source: "/((?!api|_next/static|_next/image|favicon.ico).*)"` — proxy.ts:63 (negative lookahead excludes `/api`, `/_next/static`, `/_next/image`, `/favicon.ico`)
- Prefetch skip: `missing: [{ type: "header", key: "next-router-prefetch" }, { type: "header", key: "purpose", value: "prefetch" }]` — proxy.ts:64-67 (covers both Next's app-router prefetch header and the legacy `purpose: prefetch` header)
- Minor note (not a discrepancy): the pattern also excludes `_next/image` and `favicon.ico`, which the comment's "static assets" summary reasonably covers.

## Claim 13: Commit 4f018ab — "full 128-bit nonce entropy (UUID-based was 122 bits)"

**Location:** commit 4f018ab message (lines under "CSP directive tightening")
**Type:** Behavioral / performance (entropy)
**Verdict:** Verified
**Confidence:** High — arithmetic and code both check out.
**Legibility-target:** for-orchestrator-synthesis

> "Use crypto.getRandomValues(Uint8Array(16)) for full 128-bit nonce entropy (UUID-based was 122 bits)." — commit 4f018ab

**Evidence:**
- `crypto.getRandomValues(new Uint8Array(16))` — proxy.ts:41; 16 bytes = 128 random bits.
- UUID figure: a version-4 UUID fixes 4 version bits and 2 variant bits out of 128, leaving 122 random bits — paraphrased — no quote available because this is RFC 4122 arithmetic, not code in this repo. The predecessor code (`crypto.randomUUID()`-based, per the commit's own description) is confirmed replaced: no `randomUUID` remains in proxy.ts.

## Claim 14: Commit 4f018ab — "225/225 tests pass" (and "Lint clean")

**Location:** commit 4f018ab message (final line)
**Type:** Behavioral (test status)
**Verdict:** Unverifiable
**Confidence:** Medium — cannot execute the suite (no `node_modules` in the pinned worktree, network blocked, and the historical-review rule forbids mutating the worktree via install), but the static test count corroborates the number exactly.
**Legibility-target:** for-orchestrator-synthesis

> "Lint clean; 225/225 tests pass." — commit 4f018ab

**Evidence:**
- Static count of `it(`/`test(` declarations across all `*.test.*` files plus proxy.test.ts at this commit: **225** (`rg -c "^\s*(it|test)(\.each)?\(" -g '*.test.*'` summed). The count matches the claim exactly.
- Cross-check: d90d6bb (one commit earlier, before proxy.test.ts existed) claims "221/221 tests pass"; proxy.test.ts adds exactly 4 `it(` blocks (proxy.test.ts:13, :19, :27, :34), and 221 + 4 = 225. The two commit messages are internally consistent.
- Pass/fail status and lint status remain unverifiable without execution.

## Claim 15: Commit d90d6bb — "the nonce is only written, never read by the layout" and "No behavior change; CSP directives preserved exactly"

**Location:** commit d90d6bb message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High — repo-wide grep and diff inspection.
**Legibility-target:** for-orchestrator-synthesis

> "layout.tsx: correct comment — headers() is called to opt out of static rendering so the proxy can attach per-request CSP, not to read x-nonce (the nonce is only written, never read by the layout)." — commit d90d6bb

**Evidence:**
- `x-nonce` appears exactly once in the repo, as a write: `requestHeaders.set("x-nonce", nonce);` — proxy.ts:49. `await headers();` in app/layout.tsx:28 discards its return value.
- "CSP directives preserved exactly": `git show d90d6bb -- proxy.ts` shows only an added return type and inlined local; the `directives` array is untouched — paraphrased — no quote available because the evidence is the absence of directive-array lines in that commit's diff.

## Claim 16: Commit 9b4e453 — "no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false"

**Location:** commit 9b4e453 message (opening paragraph)
**Type:** Behavioral (XSS surface)
**Verdict:** Mostly accurate
**Confidence:** High — greps are conclusive for the first two; the third is true only as a default, not as explicit configuration.
**Legibility-target:** for-author

> "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)..." — commit 9b4e453

**Evidence:**
- `rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" app/` returns no matches (exit 1) — both "no" claims verified.
- "KaTeX trust:false": no `trust` option is set anywhere. The KaTeX renderer is wired as `const rehypePlugins = [rehypeKatex];` — app/components/features/output-editing/LatexRenderer.tsx:10 — with no options object, and `rg -n "trust"` finds no KaTeX-related hit in `app/`. KaTeX's *default* is `trust: false` (paraphrased — no quote available because KaTeX is not vendored in this worktree), so the security posture described is real, but the phrasing implies an explicit setting that does not exist in the code.

## Claims Requiring Attention

### Incorrect
- **Claim 4** (proxy.test.ts:27-31): the test named "does not allow eval, wildcards, or http: schemes anywhere" does not enforce two of its three named properties. `/\bhttp:\b/` can never match a realistic `http:` source (trailing `\b` after `:` needs a following word character; `//`, space, and end-of-string all fail it), and `/\*\s/` misses `*` at the end of any directive (directives are joined with `"; "`). Only the `'unsafe-eval'` assertion — and, separately, the exact-string pins of the four high-risk directives — provide the claimed protection.

### Stale
- None.

### Mostly Accurate
- **Claim 6** (proxy.ts:12-15): all three named inline-style sites exist, but ProofGraphNode's inline styles are colors/sizing, not "node positioning" (positioning inline styles come from the React Flow library).
- **Claim 7** (proxy.ts:18-19): conclusion fully verified by enumeration, but "OpenAlex" calls do not exist anywhere in the codebase, and "Anthropic" calls actually go via OpenRouter.
- **Claim 10** (proxy.ts:44-45): the x-nonce forwarding affordance is real but unused by any current code; phrasing could be tightened.
- **Claim 16** (commit 9b4e453): KaTeX `trust: false` is the library default, not an explicit setting in this repo.

### Unverifiable
- **Claim 14** (commit 4f018ab): "225/225 tests pass" / "Lint clean" — execution impossible in this environment; static test-case count is exactly 225 and is consistent with the prior commit's 221 + 4 new tests.

## Goal-Alignment Note
- Answered: All nine briefed claim areas were checked: connect-src sufficiency (full client-side network enumeration, including confirmation the removed `fetch(dataUrl)` was the only data:-URL fetch), the nonce delivery mechanism end-to-end (CSP request header is the channel; wiring present at proxy.ts:50), the Node-runtime/API-availability premises, the dual request/response CSP setting, the three named inline-style sites, the form-action fallback spec claim, the test-coverage claims (with one Incorrect finding on the vacuous `http:` regex and end-of-directive wildcards), the 4f018ab commit-message claims (entropy math verified; 225-test count corroborated statically), and the matcher pattern/missing entries.
- Out of scope: Whether CSP actually deploys correctly on Vercel/prod (9b4e453's own message flags manual browser verification as still recommended); whether `'strict-dynamic'` interacts correctly with pdf.js's bundled Worker under this policy (a behavior question, not a documentation-accuracy question — noted for the security critic); code-quality opinions on any of the above.
- Escalate: (1) Claim 4 — the test provides materially less protection than its name and the 4f018ab commit message ("disallows unsafe-eval, wildcards, and http:") claim; a reviewer relying on that guarantee would be misled. (2) For the security critic: pdf.js Web Worker loading (app/lib/utils/fileExtraction.ts:26, pdfPropositionParser.ts:443) under `script-src 'strict-dynamic'` + no explicit worker-src is worth a functional check — not a doc-accuracy issue, but adjacent to the CSP claims verified here.
