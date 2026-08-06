# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-csp-clean, detached at 4f018ab)
**Scope:** `git diff d86d2dc..4f018ab` — CSP feature (9b4e453) plus comment fixes (b25e939, d90d6bb) and review-fix commit (4f018ab): `proxy.ts`, `proxy.test.ts`, `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, and the four commit messages.
**Checked:** comments and docstrings in the four changed files; commit-message claims in the range; supporting claims verified against callers/consumers across `app/` and `package.json`.
**Total claims checked:** 15
**Summary:** 9 Verified, 4 Mostly accurate, 1 Incorrect, 1 Unverifiable. The one Incorrect finding is in `proxy.test.ts`: the test titled "does not allow eval, wildcards, or http: schemes anywhere" uses a regex (`/\bhttp:\b/`) that can never match an `http:` source in a real CSP string (there is no word boundary between `:` and a following `/`, space, or end-of-string), and a wildcard regex (`/\*\s/`) that misses a trailing or directive-final `*`. The header-comment pinning claim itself holds. Everything else checks out, with minor drift: the connect-src rationale names OpenAlex, which does not exist anywhere in the codebase; the "so layouts can read it via headers()" x-nonce comment describes a capability nothing exercises; KaTeX `trust:false` is the library default, not an explicit setting.

**Commit:** 4f018ab

## Claim 1: Dynamic rendering lets the HTML pick up the nonce set by proxy.ts

**Location:** app/layout.tsx:24-27
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** Medium — the in-repo wiring is fully confirmed by reading code; the final link (Next.js reading the nonce from the request's `Content-Security-Policy` header and tagging its bootstrap scripts during dynamic render) is documented framework behavior that cannot be confirmed from `node_modules` (not installed in this worktree) or by execution.

The comment reads:

> "Opt this layout into dynamic rendering so Next.js injects the per-request nonce (set by proxy.ts) into its own bootstrap <script> tags during render. The proxy already runs per request via its matcher; the dynamic-rendering switch is what lets the rendered HTML pick up the nonce." — app/layout.tsx:24-27

End-to-end delivery mechanism, verified in order:

1. The proxy generates the nonce and — critically — sets it inside the CSP header **on the forwarded request**, which is the header Next.js reads a nonce from (Next parses `'nonce-...'` out of the incoming request's `Content-Security-Policy` header; the `x-nonce` header is a userland side-channel Next itself does not consume):

   > `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:50

2. The layout opts into dynamic rendering via `await headers();` (app/layout.tsx:28), which is required because a statically rendered page is generated once at build time and cannot embed a per-request nonce.

Note that this wiring only became correct in 4f018ab: at d90d6bb the request carried only `x-nonce` (no request-side CSP header), so at that intermediate commit Next.js had no header to read a nonce from. The comment as it stands at 4f018ab matches the code as it stands at 4f018ab.

**Evidence:** proxy.ts:49-50 (`requestHeaders.set("x-nonce", nonce); requestHeaders.set("Content-Security-Policy", csp);`); app/layout.tsx:28 (`await headers();`). Framework-side nonce pickup: paraphrased — no quote available because Next.js is not installed in this worktree (`node_modules` absent), so the claim rests on documented Next.js CSP-nonce behavior.

## Claim 2: toBlob avoids needing `data:` in connect-src

**Location:** app/lib/utils/exportGraph.ts:6
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

> "Use toBlob (not toPng + fetch) so we don't need `data:` in CSP connect-src." — app/lib/utils/exportGraph.ts:6

The pre-change code fetched a `data:` URL, which is a connect-src-governed network initiation, and `connect-src 'self'` (proxy.ts:29) does not allow `data:`:

> `const dataUrl = await toPng(viewportElement, {...}); const res = await fetch(dataUrl);` — pre-change app/lib/utils/exportGraph.ts (from `git diff d86d2dc..4f018ab`, removed lines)

The replacement calls `toBlob` and never fetches:

> `const blob = await toBlob(viewportElement, { pixelRatio: 2, backgroundColor: EXPORT_BG });` — app/lib/utils/exportGraph.ts:18-21

`grep` confirms no remaining `fetch(` in `app/lib/utils/` (searched all of `app/lib`; only hits are in `app/lib/llm/` and `app/lib/formalization/`). The blob is handed to `triggerDownload`, which uses `URL.createObjectURL` (app/lib/utils/export.ts:8) — object URLs are not a connect-src concern.

**Evidence:** diff hunk for app/lib/utils/exportGraph.ts in `git diff d86d2dc..4f018ab`; app/lib/utils/export.ts:8 (`const url = URL.createObjectURL(blob);`); proxy.ts:29 (`"connect-src 'self'"`).

## Claim 3: Test header — pinning the directive list makes weakening the four named directives fail loudly

**Location:** proxy.test.ts:3-6
**Type:** Behavioral (test coverage)
**Verdict:** Verified
**Confidence:** High

> "Pin the CSP directive list so a refactor that weakens script-src, connect-src, frame-ancestors, or object-src fails loudly in tests rather than silently shipping." — proxy.test.ts:3-5

Each of the four named directives is asserted as an **exact full-directive string** via `toContain` against `csp.split("; ")`, so adding any source to any of them changes the string and fails the assertion:

> `expect(directives).toContain(`script-src 'self' 'nonce-${NONCE}' 'strict-dynamic'`);` — proxy.test.ts:14-16
> `expect(directives).toContain("connect-src 'self'"); ... expect(directives).toContain("frame-ancestors 'none'"); expect(directives).toContain("object-src 'none'");` — proxy.test.ts:21-23

Removing a directive outright is also caught by the stable-order test (proxy.test.ts:35-46), which asserts the exact 10-name sequence. This claim, scoped to the four named directives, holds. (The *disallowance* test titles are a separate, weaker story — see Claim 4.)

**Evidence:** proxy.test.ts:11-24, 35-46.

## Claim 4: Test — "does not allow eval, wildcards, or http: schemes anywhere"

**Location:** proxy.test.ts:18
**Type:** Behavioral (test coverage)
**Verdict:** Incorrect
**Confidence:** High — verified by executing the exact regexes in Node against weakened CSP strings.

> `it("does not allow eval, wildcards, or http: schemes anywhere", () => { expect(csp).not.toMatch(/'unsafe-eval'/); expect(csp).not.toMatch(/\*\s/); expect(csp).not.toMatch(/\bhttp:\b/); });` — proxy.test.ts:18-22

Two of the three assertions do not enforce what the title claims:

- **`http:` check is vacuous.** `/\bhttp:\b/` requires a word boundary immediately after the colon, i.e. the next character must be a word character. In every realistic weakened CSP, `http:` is followed by `/` (a URL), a space, `;`, or end-of-string — all non-word characters, so no boundary exists and the regex never matches. Executed verification: `/\bhttp:\b/.test("img-src http:")` → `false`; `/\bhttp:\b/.test("connect-src http://evil.com")` → `false`. A refactor adding `http:` sources would pass this test.
- **Wildcard check misses trailing wildcards.** `/\*\s/` requires whitespace after `*`. `join("; ")` puts `;` (not whitespace) after every non-final directive and nothing after the last, so both `"img-src *; font-src 'self'"` and a final `"img-src *"` escape it. Executed verification: `/\*\s/.test("img-src *; font-src 'self'")` → `false`; it only catches a wildcard followed by another source in the same directive (`"img-src * data:"` → `true`).
- The `'unsafe-eval'` assertion is sound.

The in-code comment on the wildcard line — "wildcard source not followed by directive end" (proxy.test.ts:20) — accurately describes the regex's narrow reach, which itself concedes the test title overclaims.

**Evidence:** proxy.test.ts:18-22; Node execution of the three regexes against `"img-src http:"`, `"connect-src http://evil.com"`, `"img-src *; font-src 'self'"`, `"img-src * data:"` (results quoted above).

## Claim 5: "Next.js 16 renamed Middleware → Proxy"

**Location:** proxy.ts:5
**Type:** Reference (framework)
**Verdict:** Verified
**Confidence:** Medium — external framework fact; consistent with everything in-repo but not independently checkable without docs/`node_modules`.

> "CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces." — proxy.ts:5

`package.json:23` pins `"next": "16.2.4"`. The repo consistently treats `proxy.ts` as the middleware-equivalent entry point (exported `proxy` function plus `config.matcher`, the middleware convention), and commit 9b4e453's message states `middleware.ts` still builds "with a deprecation warning" — consistent with a rename rather than a removal. Next.js 16's rename of middleware to proxy matches my knowledge of the release. Paraphrased — no quote available because the Next.js docs/source are not present in this worktree.

**Evidence:** package.json:23 (`"next": "16.2.4"`); proxy.ts:38-59 (exported `proxy` + `config.matcher` convention).

## Claim 6: style-src 'unsafe-inline' rationale — named inline-style sites exist

**Location:** proxy.ts:12-17
**Type:** Behavioral / configuration rationale
**Verdict:** Verified
**Confidence:** High for the named sites; the Next.js SSR `<style>`-injection premise is Medium (framework behavior, not executable here).

> "many React components use inline `style={{...}}` props (e.g. proof-graph node positioning, refinement preview, collapsible sections), and Next.js's SSR style injection also emits inline <style> tags." — proxy.ts:12-15

All three named sites verified:

- **Proof graph:** `style={{ borderColor: statusColor, borderWidth: 2, minWidth: 160 }}` — app/components/features/proof-graph/ProofGraphNode.tsx:45 (plus lines 52, 58, 70). Pedantic note: these props set colors/width, not positioning — node *positioning* transforms come from the React Flow library's own inline styles, which are equally inline-style-dependent, so the rationale stands either way.
- **Refinement preview:** `style={{ lineHeight: 1.6 }}` — app/components/features/context-input/RefinementPreview.tsx:24 and :35.
- **Collapsible sections:** `<div style={open ? undefined : HIDDEN_STYLE}>{children}</div>` — app/components/ui/CollapsibleSection.tsx:51.

And the pattern is codebase-wide: `rg "style=\{\{" app/` matches 19 component files (30 occurrences), so tightening to nonced styles would indeed require a broad audit as claimed.

**Evidence:** file:line quotes above; `rg -c "style=\{\{" app/` file list (19 files). SSR `<style>` injection: paraphrased — no quote available because it is framework runtime behavior and Next.js is not installed here.

## Claim 7: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server"

**Location:** proxy.ts:18-19
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** High

> "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party." — proxy.ts:18-19

**The conclusion is correct.** Full enumeration of client-side network initiations across `app/` (`rg "fetch\(|XMLHttpRequest|WebSocket|EventSource|sendBeacon"`, excluding tests):

- `fetch("/api/analytics")` and `fetch("/api/analytics", { method: "DELETE" })` — app/hooks/useAnalytics.ts:11,30 (`"use client"` at line 1). Same-origin.
- `fetchApi`/`fetchStreamingApi` (app/lib/formalization/api.ts:10,38) — every caller passes a same-origin path: `"/api/verification/lean"` (api.ts:104), `"/api/edit/artifact"` (useArtifactEditing.ts:39,48), `"/api/edit/inline"` / `"/api/edit/whole"` (OutputPanel.tsx:50,66; SemiformalPanel.tsx:43,59; EditableSection.tsx:77,84), `"/api/decomposition/extract"` (useDecomposition.ts:129-131), and `ARTIFACT_ROUTE[type]` lookups (useArtifactGeneration.ts:42, formalizeNode.ts:114) resolving to `/api/...` routes.
- `fetch("/api/refine/context")` — ContextInput.tsx:25; `fetch("/api/explanation/lean-error")` — LeanCodeDisplay.tsx:88. Same-origin.
- No `XMLHttpRequest`, `WebSocket`, `EventSource`, or `sendBeacon` anywhere in `app/` (zero grep hits; SSE is consumed via `res.body.getReader()` on a same-origin fetch, app/lib/formalization/api.ts:50).
- The only `data:`-URL fetch (exportGraph.ts) was removed in this very range (Claim 2). `URL.createObjectURL` (export.ts:8) and pdfjs `getDocument({ data: buffer })` (fileExtraction.ts:37, pdfPropositionParser.ts:449) are not connect-src initiations; the pdfjs worker is bundled same-origin via `new URL("pdfjs-dist/build/pdf.worker.min.mjs", import.meta.url)` (fileExtraction.ts:26-29) and is worker-src/script-src territory regardless.
- Third-party fetches exist only server-side: `fetch(OPENROUTER_API_URL)` (app/lib/llm/callLlm.ts:164, streamLlm.ts:249, URL `https://openrouter.ai/api/v1/chat/completions` at callLlm.ts:7) — imported only by `app/api/*/route.ts` files and `app/lib/formalization/artifactRoute.ts` (itself only used by API routes); and `fetch(\`${LEAN_VERIFIER_URL}/verify\`)` inside app/api/verification/lean/route.ts:21.

**The inaccuracy:** "OpenAlex" appears nowhere in the codebase — `rg -i openalex` across the repo matches only this proxy.ts docstring itself. There are no OpenAlex calls, server-to-server or otherwise. Anthropic models are reached via OpenRouter (app/lib/llm/models.ts model IDs), not a direct Anthropic endpoint, which is a harmless reading of "Anthropic ... server-to-server" but the OpenAlex mention describes a nonexistent integration.

**Evidence:** all path:line citations above; `rg -i "openalex"` whole-repo result (single hit: proxy.ts docstring).

## Claim 8: "form-action does NOT fall back to default-src (CSP3); set explicitly"

**Location:** proxy.ts:31
**Type:** Reference (spec) + configuration
**Verdict:** Verified
**Confidence:** High for the directive's presence; Medium for the spec citation (from knowledge — CSP3's `form-action` is a navigation directive with no `default-src` fallback, unlike fetch directives).

> `// form-action does NOT fall back to default-src (CSP3); set explicitly.` followed by `"form-action 'self'",` — proxy.ts:31-32

The directive is present in `buildCsp` and pinned by the test (`expect(directives).toContain("form-action 'self'")` — proxy.test.ts:24; order list proxy.test.ts:45). The spec claim matches CSP Level 3: paraphrased — no quote available because the W3C spec is external to the repo; per CSP3 §6.4, `form-action` does not use the `default-src` fallback chain.

**Evidence:** proxy.ts:31-32; proxy.test.ts:24,45.

## Claim 9: 128-bit nonce; crypto.getRandomValues + Buffer available in the Node.js runtime Next 16 Proxy uses by default

**Location:** proxy.ts:39-41
**Type:** Behavioral + reference (runtime)
**Verdict:** Verified
**Confidence:** Medium — the entropy arithmetic and code are High; the runtime-default and API-availability premises are framework/platform facts not executable here.

> "Generate a fresh 128-bit nonce per request. crypto.getRandomValues + Buffer are both available in the Node.js runtime Next 16 Proxy runs on by default." — proxy.ts:39-40
> `const nonce = Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64");` — proxy.ts:41

- **128 bits:** `Uint8Array(16)` = 16 bytes × 8 = 128 bits of CSPRNG output, all preserved by base64 encoding. Verified.
- **Runtime:** Next.js 16 runs proxy/middleware on the Node.js runtime by default (the same fact commit 4f018ab's message relies on when it says the old Edge-runtime comment was dropped). Node ≥ 18/20 exposes `globalThis.crypto.getRandomValues` (WebCrypto global), and `Buffer` is Node core. Next 16 requires Node ≥ 20, where both hold. Paraphrased — no quote available because Next.js/Node are not installed in this worktree; consistent with `"next": "16.2.4"` (package.json:23) and with the commit-message rationale.

**Evidence:** proxy.ts:39-41; package.json:23.

## Claim 10: Forward nonce via request header "so layouts can read it via headers() and pass it to <Script> tags"; setting CSP on both request and response "matches the canonical Next.js docs example"

**Location:** proxy.ts:44-47
**Type:** Architectural / reference
**Verdict:** Mostly accurate
**Confidence:** High for the in-repo facts; Medium for the docs-example correspondence (external).

> "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render. Setting CSP on both the forwarded request and the response matches the canonical Next.js docs example." — proxy.ts:44-47

- **Both settings exist:** `requestHeaders.set("Content-Security-Policy", csp);` (proxy.ts:50) and `response.headers.set("Content-Security-Policy", csp);` (proxy.ts:55). The request-side copy is what lets Next.js discover the nonce for its own scripts (Claim 1); the response-side copy is what the browser enforces. This matches the structure of the official Next.js CSP guide's middleware example (paraphrased — no quote available because the docs are external; the guide sets `x-nonce` plus CSP on both request and response, exactly this shape).
- **The "so layouts can read it" clause is aspirational, not exercised:** `x-nonce` is written at proxy.ts:49 and read by nothing — `rg -n "x-nonce"` across the repo matches only that one line. The layout deliberately does not read it (its own comment at app/layout.tsx:24-27, and d90d6bb's message: "the nonce is only written, never read by the layout"). "Can read" is technically a capability statement, but the comment presents an unused mechanism as the header's purpose.

**Evidence:** proxy.ts:49-55; `rg -n "x-nonce"` single-hit result; app/layout.tsx:24-28.

## Claim 11: Matcher skips API routes, static assets, and prefetches

**Location:** proxy.ts:59-61
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

> "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)." — proxy.ts:59-61

The matcher does exactly this:

> `source: "/((?!api|_next/static|_next/image|favicon.ico).*)",` — proxy.ts:64

The negative lookahead excludes `/api/*`, `/_next/static/*`, `/_next/image/*`, and `/favicon.ico`. The `missing` entries (proxy.ts:65-68: `next-router-prefetch` and `purpose: prefetch` headers) use Next's "match only when header is absent" semantics, so prefetch requests bearing either header bypass the proxy — matching the "skip prefetches" claim. Minor completeness note: `_next/image` and `favicon.ico` are also skipped but not itemized in the prose; they fall under "static assets" reasonably.

**Evidence:** proxy.ts:63-69.

## Claim 12: Feature-commit XSS-surface claims (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)

**Location:** commit 9b4e453 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

> "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)" — commit 9b4e453 message

- `rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" app/` (excluding tests): zero hits. Verified.
- Markdown rendering goes through ReactMarkdown with only `remarkGfm`, `remarkMath`, `rehypeKatex`:

  > `const remarkPlugins = [remarkGfm, remarkMath]; const rehypePlugins = [rehypeKatex];` — app/components/features/output-editing/LatexRenderer.tsx:9-10

- **The inaccuracy:** `rehypeKatex` is used with no options object, so KaTeX `trust` is the library **default** of `false` — nothing in the codebase sets `trust: false` explicitly (`rg -n "trust"` finds no KaTeX-related hit). The security posture claimed is real, but "KaTeX trust:false" reads as a deliberate configuration when it is an inherited default that a future options object could silently change.

**Evidence:** LatexRenderer.tsx:9-10, 35-38; zero-hit grep results described above (paraphrased — no quote available because the assertions are about absence of matches).

## Claim 13: Cleanup commit — "No behavior change; CSP directives preserved exactly. ... 221/221 tests pass."

**Location:** commit d90d6bb message
**Type:** Behavioral + staleness signal
**Verdict:** Verified
**Confidence:** High for "no behavior change"; Medium for the test count (static consistency only).

`git diff b25e939..d90d6bb` touches only: two comment blocks, an added `: NextResponse` return-type annotation, and inlining the single-use `csp` local into `response.headers.set("Content-Security-Policy", buildCsp(nonce))` — all semantics-preserving; `buildCsp`'s directive array is untouched. The 221 count is consistent with the repo's current 225 static `it(`/`test(` declarations minus the 4 added later by proxy.test.ts (see Claim 15); tests were not executed.

**Evidence:** `git diff b25e939..d90d6bb` hunks (quoted lines: `- const csp = buildCsp(nonce);` / `+ response.headers.set("Content-Security-Policy", buildCsp(nonce));`).

## Claim 14: "Use crypto.getRandomValues(Uint8Array(16)) for full 128-bit nonce entropy (UUID-based was 122 bits)"

**Location:** commit 4f018ab message
**Type:** Behavioral / performance-of-crypto
**Verdict:** Verified
**Confidence:** High

Current code: `crypto.getRandomValues(new Uint8Array(16))` — proxy.ts:41 — is 16 × 8 = 128 bits. Prior code at d90d6bb:

> `const nonce = Buffer.from(crypto.randomUUID()).toString("base64");` — proxy.ts:37 at d90d6bb (via `git show d90d6bb:proxy.ts`)

`crypto.randomUUID()` returns a UUIDv4, which fixes 6 of its 128 bits (4 version bits + 2 variant bits), leaving 122 random bits; base64-encoding the 36-character string preserves exactly that entropy. Both figures check out.

**Evidence:** proxy.ts:41; `git show d90d6bb:proxy.ts` line 37; UUIDv4 122-bit figure: paraphrased — no quote available because RFC 4122 is external; 128 − 6 fixed bits = 122.

## Claim 15: "Lint clean; 225/225 tests pass" (and "toBlob ... don't violate connect-src 'self'")

**Location:** commit 4f018ab message
**Type:** Staleness signal / verification claim
**Verdict:** Unverifiable
**Confidence:** Medium — the countable half is confirmed statically; the pass/lint status cannot be confirmed without execution (`node_modules` is not installed in this worktree, and executing is outside this pass anyway).

Static cross-check strongly corroborates the count: `rg -c "^\s*(it|test)\(" -g '*.test.*'` summed across the repo yields exactly **225** test declarations, including proxy.test.ts's 4 (which also reconciles d90d6bb's "221/221" + 4). Nothing contradicts "pass" or "lint clean", but neither was executed here. The commit's toBlob/connect-src sub-claim is Verified separately as Claim 2.

**Evidence:** summed `rg -c "^\s*(it|test)\(" -g '*.test.*'` = 225 (paraphrased — no quote available because the evidence is an aggregate count across 30+ test files, not a single line).

## Claims Requiring Attention

### Incorrect

- **Claim 4** (proxy.test.ts:18): the "does not allow eval, wildcards, or http: schemes anywhere" test does not enforce two of its three named guarantees. `/\bhttp:\b/` can never match `http:` as a CSP scheme-source or URL (no word boundary between `:` and `/`, space, or end-of-string — verified by execution), and `/\*\s/` misses a wildcard at directive end (`*;`) or string end. Fix: `not.toMatch(/\bhttp:/)` (drop the trailing `\b`) and `not.toMatch(/(^|\s)\*(;|\s|$)/)` or simply assert no directive value contains a bare `*` token.

### Stale

- None.

### Mostly Accurate

- **Claim 7** (proxy.ts:18-19): connect-src conclusion fully verified by enumeration, but the rationale names OpenAlex, which appears nowhere else in the codebase — no such integration exists.
- **Claim 10** (proxy.ts:44-47): both CSP settings exist and match the docs-example shape, but the "so layouts can read it via headers()" purpose attached to `x-nonce` is exercised by nothing — `x-nonce` is written once and never read.
- **Claim 12** (commit 9b4e453): "KaTeX trust:false" is the library default, not an explicit setting; `rehypeKatex` is invoked with no options.

### Unverifiable

- **Claim 15** (commit 4f018ab): "Lint clean; 225/225 tests pass" — test count confirmed statically (exactly 225 declarations), pass/lint status requires execution.

## Goal-Alignment Note
- Answered: All nine briefed items — connect-src enumeration (full client-side initiation sweep incl. data:/blob: paths), nonce delivery end-to-end, runtime/API availability, dual CSP setting, style-src named sites, form-action fallback, test-coverage claims (with an executed-regex refutation), 4f018ab commit claims (entropy/test-count/toBlob), and the matcher comment.
- Out of scope: Whether `style-src 'unsafe-inline'` or the vacuous test regexes are *acceptable* security posture (reviewer judgment, not documentation accuracy); running the test suite or lint; browser-level CSP behavior verification.
- Escalate: Claim 4 to the security/test critics — the CSP-weakening guard test passes today but would also pass after a refactor that adds `http:` sources or a trailing wildcard, which defeats the test's stated purpose; cheap two-line regex fix.
