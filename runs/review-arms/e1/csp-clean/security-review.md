# Security Review — csp-clean (d86d2dc..4f018ab)

**Scope:** `git diff d86d2dc..4f018ab` — strict-CSP feature (9b4e453) plus its review-fix commit (4f018ab). Files: `proxy.ts` (new), `proxy.test.ts` (new), `app/layout.tsx`, `app/lib/utils/exportGraph.ts`. Repo state reviewed as of 4f018ab; code outside the range is treated as context, not as reviewable surface.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3). Its findings are taken as foundation and not re-verified.
`Commit: 4f018ab`

---

### Trust Boundary Map

- **B1: Untrusted browser request (any headers, any path) → Next 16 Proxy `proxy()` matcher + `buildCsp()` → HTML document served with per-request nonce CSP.** This is the boundary the whole change exists to create. The transition is conditional: it fires only when the request path survives the matcher's exclusion regex *and* the request lacks the two prefetch headers. Everything the CSP protects sits downstream of a per-request predicate that the client partially controls (path, and the `purpose`/`next-router-prefetch` headers).
- **B2: Untrusted browser request → `/api/*` route handlers → LLM providers (Anthropic / OpenRouter) and local filesystem analytics.** The proxy matcher deliberately excludes `api`, so this boundary is crossed with **no** CSP, no `frame-ancestors`, and no `nosniff`. Routes here return `application/json` and `text/event-stream` carrying raw model output.
- **B3: LLM provider output (semi-trusted third-party text) → SSE stream → `LatexRenderer` → `react-markdown` + `rehype-katex` → live DOM.** This is the injection path the CSP comment names ("even if something slipped past markdown sanitization"). `script-src 'self' 'nonce-…' 'strict-dynamic'` is the last line of defense here, and it is only present because B1 fired for the document that loaded this client component.
- **B4: In-page DOM (graph viewport, potentially containing model-derived labels) → `html-to-image` `toBlob()` → `URL.createObjectURL` → user download.** The 4f018ab change removed a `fetch(dataUrl)` hop from this path, so the boundary no longer traverses `connect-src` at all — serialization now stays inside the page.
- **B5: Prefetch response → shared HTTP cache → later top-level navigation.** A document fetched across B1's `missing:` carve-out re-enters the browser as a real document later, carrying whatever headers it was cached with.

Findings below cross-reference these labels.

---

### Findings

#### Prefetched documents are served with no CSP at all, and can be reused as real navigations

**Severity:** Medium
**Location:** `proxy.ts:57-70` (`config.matcher` → `missing`)
**Boundary:** B1 → B5
**Move:** invert access control (what do the checks *not* cover?) / TOCTOU
**Confidence:** Medium — the header-skip is unambiguous in the code; whether a given deployment's cache actually replays the prefetched body for a subsequent navigation depends on `Cache-Control` on the rendered page, which this diff does not set.
**Evidence:**
```
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```
with the stated rationale: `// would otherwise burn a nonce on a request that may never paint).`

**Legibility-target:** the security model of the matcher — reviewers read `matcher` as "which paths are protected" and miss that it also encodes "which *requests* are protected."

The `missing:` clause makes CSP application contingent on a client-supplied request header rather than on the response's content. Any party that can cause the victim's browser to emit `Purpose: prefetch` for a page of this app — a cross-origin `<link rel="prefetch">`, a speculation rule, or a same-site link in a Next router prefetch — obtains a fully-rendered HTML document with no `Content-Security-Policy`, no `frame-ancestors 'none'`, and no nonce. If that response lands in the HTTP cache and is later reused for the top-level navigation (the normal purpose of prefetch), the user browses a CSP-less copy of the app, silently reverting the entire hardening for that page view. The nonce-cost rationale is weak: nonce generation is 16 bytes of `getRandomValues`, and an unused nonce costs nothing, whereas an unprotected cached document costs the whole control.

**Recommendation:** Drop the `missing:` clause and apply CSP unconditionally to matched paths; a prefetched document that is later promoted to a navigation must carry the same headers as a directly-navigated one. If prefetch must stay excluded for a measured reason, ensure prefetched HTML is marked `Cache-Control: no-store` so it can never be promoted, and add a test pinning that behavior.

---

#### The regression test that is supposed to prevent CSP weakening does not test what it claims

**Severity:** Medium
**Location:** `proxy.test.ts:27-31`
**Boundary:** B1 (the guard on the boundary's definition, not the boundary itself)
**Move:** implicit sanitization assumptions — here, an implicit assumption that a negative assertion actually constrains the string
**Confidence:** High — established by the merged fact-check as **Incorrect**; the regex behavior is deterministic.
**Evidence:**
```
  it("does not allow eval, wildcards, or http: schemes anywhere", () => {
    expect(csp).not.toMatch(/'unsafe-eval'/);
    expect(csp).not.toMatch(/\*\s/); // wildcard source not followed by directive end
    expect(csp).not.toMatch(/\bhttp:\b/);
  });
```

**Legibility-target:** the test's own title, and the commit message that repeats its claim — both assert coverage the assertions do not provide.

Only the `'unsafe-eval'` assertion is operative. `/\*\s/` requires whitespace after the `*`, so a directive-final wildcard (`img-src *` at the end of a directive, immediately followed by `;` or end-of-string) passes. `/\bhttp:\b/` can never match a real source expression, because `\b` after the colon requires a following word character and real sources continue with `//`, a space, or end-of-string. Combined with the fact that `img-src`, `font-src`, and `style-src` are pinned only by *name* in the ordering test and never by *value*, a future change to `img-src *` or `font-src http://cdn.example.com` would ship with a green suite while the file's header comment promises the opposite ("fails loudly in tests rather than silently shipping"). This is exactly the failure mode a pinning test exists to prevent, and its presence discourages anyone from adding a real one.

**Recommendation:** Replace the regex negatives with full-value equality assertions for every directive (the same treatment `default-src`, `connect-src`, `frame-ancestors`, `object-src`, `base-uri`, and `form-action` already get), or assert on the parsed directive map so an unpinned directive is a test failure by construction. At minimum, fix the wildcard regex to `/(^|\s)\*($|[\s;])/` and the scheme regex to `/http:\/\//`, and correct the commit-message claim.

---

#### `worker-src` is unset, so Web Workers fall through to a `'strict-dynamic'` `script-src`

**Severity:** Medium
**Location:** `proxy.ts:20-33` (`buildCsp` directive list); consumer at `app/lib/utils/fileExtraction.ts:26-29`
**Boundary:** B1 (policy content) affecting B3 (document ingestion path)
**Move:** error paths — what happens when the policy blocks a load the app needs, and what does the fix look like?
**Confidence:** Medium — the directive omission is certain; the browser-specific fallback behavior for `worker-src` under `'strict-dynamic'` is not runtime-verified here.
**Evidence:**
```
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```
and the PDF ingestion path that depends on a worker:
```
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
    "pdfjs-dist/build/pdf.worker.min.mjs",
    import.meta.url,
  ).toString();
```

**Legibility-target:** the CSP's completeness — `buildCsp` reads as an exhaustive list, but `worker-src` is a directive whose absence is not visible from reading the list.

`worker-src` falls back through `child-src` to `script-src` in CSP Level 3 implementations. Because `'strict-dynamic'` causes conforming browsers to **ignore** the `'self'` source expression in `script-src`, and because a `Worker` URL cannot carry a nonce, same-origin worker construction can be blocked even though the worker script is served from the app's own origin. The consequence is not a vulnerability but an availability break in a primary input path (PDF upload → text extraction), and the realistic remediation under time pressure is to relax `script-src` — reintroducing exactly the weakness this change removed. Erosion-by-hotfix is the risk, not the block itself.

**Recommendation:** Add an explicit `worker-src 'self'` (and consider `child-src 'self'`) to the directive list so worker loading never depends on `script-src` fallback semantics, and pin it in `proxy.test.ts`. Verify PDF extraction in a browser with the header applied before relying on the current list.

---

#### `/api/*` responses cross the browser boundary with no CSP and no `nosniff`

**Severity:** Low
**Location:** `proxy.ts:59` (`source: "/((?!api|_next/static|_next/image|favicon.ico).*)"`)
**Boundary:** B2
**Move:** trace trust boundaries / invert access control
**Confidence:** High — the exclusion is explicit; the impact is bounded by current response content types, which I verified are JSON and `text/event-stream`.
**Evidence:**
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
with the rationale comment: `// Apply CSP to page navigations only. Skip API routes (they don't render HTML)`.

The rationale is accurate for the repo as it stands today — every route under `app/api/` returns `NextResponse.json` or an SSE stream — but it encodes a property of the *current* handlers into a *permanent* exclusion, with nothing enforcing it. These responses carry raw LLM output (B3's source material) and are reachable by direct navigation; with no `X-Content-Type-Options: nosniff` anywhere in the change, a future route that returns HTML, SVG, or an unlabeled body would be rendered as a document with zero policy — no `object-src 'none'`, no `frame-ancestors 'none'`, no script restrictions. The cheapest correct posture is to apply a restrictive CSP to API responses too, since a JSON endpoint has nothing to lose from `default-src 'none'`.

**Recommendation:** Stop excluding `api` from the matcher and instead branch inside `proxy()`: serve `default-src 'none'; frame-ancestors 'none'; sandbox` plus `X-Content-Type-Options: nosniff` for `/api/*`, and the nonce policy for everything else. Failing that, add `nosniff` globally.

---

#### `style-src 'unsafe-inline'` leaves a documented but unmitigated CSS-injection channel

**Severity:** Low
**Location:** `proxy.ts:23`
**Boundary:** B3
**Move:** implicit sanitization assumptions
**Confidence:** High on the directive; Medium on exploitability, which depends on markdown/KaTeX escaping that the fact-check confirms is at library defaults.
**Evidence:**
```
    "style-src 'self' 'unsafe-inline'",
```
with the header comment: `Documented as a deliberate carve-out, not an oversight.`

The carve-out is honestly documented and the reasoning (React inline `style={{…}}` props plus Next's SSR style injection) is real, so this is not an oversight finding — it is a note that the residual risk is not zero. With `'unsafe-inline'` styles permitted, injected CSS in the B3 path can still restyle or overlay the UI for clickjacking-like effects and, via attribute selectors on `img-src`-permitted URLs, leak page content character-by-character; `img-src 'self' data: blob:` limits but does not eliminate the exfiltration shapes. The mitigating fact is that `react-markdown` escapes raw HTML by default (no `rehype-raw`) and `rehype-katex` runs with `trust` at its library default of `false`, so there is currently no known route by which model output becomes a `<style>` element or a `style` attribute.

**Recommendation:** Keep the carve-out, but pin the two properties that make it survivable — add tests asserting that `rehype-raw` is absent from `LatexRenderer`'s plugin list and that `rehypeKatex` is never passed `trust: true` — so the carve-out's safety precondition is enforced rather than assumed.

---

#### `await headers()` in the root layout makes every page dynamic, with no rate limiting anywhere

**Severity:** Low
**Location:** `app/layout.tsx:29-33`
**Boundary:** B1
**Move:** million-of-these (unbounded work per unauthenticated request)
**Confidence:** Medium — the rendering-mode consequence is certain; the load impact is a function of deployment, which this repo does not pin.
**Evidence:**
```
  // Opt this layout into dynamic rendering so Next.js injects the per-request
  // nonce (set by proxy.ts) into its own bootstrap <script> tags during render.
  await headers();
```

Placing this in the *root* layout opts the entire route tree out of static generation and full-route caching, converting every page request into a server render. That is a necessary consequence of per-request nonces, not a mistake — but it changes the cost of an anonymous request from "serve a cached string" to "run React SSR," and nothing in the repo (no proxy-level throttle, no per-IP limit on `/api/*`) bounds the request rate. The security-relevant part is the composition: a cheap unauthenticated request now consumes server CPU, adjacent to API routes that spend money at a third-party LLM provider.

**Recommendation:** Accept the dynamic rendering (it is required), but add a rate limit at the proxy — the same per-request hook already exists — before this is exposed to the open internet, and confirm the deployment sits behind a CDN/WAF that can absorb navigation floods.

---

#### No CSP violation reporting, so policy failures and injection attempts are silent

**Severity:** Informational
**Location:** `proxy.ts:20-33` (directive list); no `report-to` / `report-uri`
**Boundary:** B1
**Move:** error paths
**Confidence:** High
**Evidence:** the complete directive list —
```
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
    // form-action does NOT fall back to default-src (CSP3); set explicitly.
    "form-action 'self'",
  ];
```

A nonce-based `'strict-dynamic'` policy fails closed, which is the right default, but it also fails *invisibly*: a blocked bootstrap script, a blocked worker (see the `worker-src` finding), or an actual injection attempt all produce a browser console message and nothing server-side. Without a report endpoint there is no signal distinguishing "the policy is working" from "the policy is breaking the app for a subset of browsers," and no detection of attempted injection against B3.

**Recommendation:** Add `report-to` with a `Reporting-Endpoints` header pointing at a lightweight collector route, and consider shipping the next CSP change in `Content-Security-Policy-Report-Only` alongside the enforcing header to measure before enforcing.

---

#### Nonce delivery is unverified at runtime, and `x-nonce` is a dead header

**Severity:** Informational
**Location:** `proxy.ts:41-47`
**Boundary:** B1
**Move:** trace trust boundaries (does the mechanism actually connect end-to-end?)
**Confidence:** High on the dead header (fact-check: `x-nonce` is written but never read); the runtime-injection question is flagged by the fact-check as **Unverifiable** from source alone.
**Evidence:**
```
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
  requestHeaders.set("Content-Security-Policy", csp);
```

The operative mechanism is the request-side `Content-Security-Policy` header on the second line — that is what Next reads to nonce its own bootstrap scripts. `x-nonce` is set for a consumer that does not exist in this repo; the comment above it ("so layouts can read it via `headers()` and pass it to `<Script>` tags they render") describes intent, not current behavior. That is harmless, but it leaves a reader unsure which line is load-bearing, and the whole feature's central claim — that Next injects the nonce into bootstrap scripts under this configuration — has never been observed at runtime. If it does not hold, the failure is fail-closed (a blank app), not insecure, which is why this is Informational rather than higher.

**Recommendation:** Verify once in a browser that the served HTML's Next bootstrap `<script>` tags carry `nonce=` matching the response header, and record that verification. Either delete `x-nonce` or add the consumer that justifies it; a comment on the request-side CSP line should state that it is the mechanism, not a mirror of the response header.

---

#### CSP is the only security header set; the usual companions are absent

**Severity:** Informational
**Location:** `proxy.ts:48-51`; `next.config.ts` (no `headers()` entry)
**Boundary:** B1
**Move:** invert access control
**Confidence:** High
**Evidence:**
```
  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", csp);
  return response;
```
and `next.config.ts` in its entirety: `const nextConfig: NextConfig = { /* config options here */ };`

`frame-ancestors 'none'` covers clickjacking and `base-uri 'self'` covers base-tag hijacking, so the highest-value non-CSP headers are already subsumed. What remains unset is `X-Content-Type-Options: nosniff` (relevant to the `/api/*` exclusion above), `Referrer-Policy` (documents may contain proof text in paths/queries that leaks to third parties on outbound navigation), and `Permissions-Policy`. `Strict-Transport-Security` is a deployment concern rather than a code one. None of these is exploitable on its own here; they are listed so the header set is a deliberate choice rather than a default.

**Recommendation:** Set `nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, and a minimal `Permissions-Policy` in the same `proxy()` function, and pin them in `proxy.test.ts` alongside the CSP directives.

---

### What Looks Good

- **Nonce entropy and lifecycle are correct.** 128 bits from `crypto.getRandomValues`, generated fresh per request, never persisted, never reused across responses, and never read back from a client-controllable source — the incoming `x-nonce`/`Content-Security-Policy` request headers are unconditionally overwritten with `set()` rather than appended, so a client cannot inject its own nonce value into the policy. This is the single most important thing to get right in a nonce-based CSP and it is right.
- **The `exportGraph` rewrite removes a boundary rather than widening a policy.** Dropping `toPng` + `fetch(dataUrl)` in favor of `toBlob` means the export path no longer makes a request at all, so `connect-src 'self'` needed no `data:` carve-out. Fixing a CSP conflict by eliminating the crossing instead of loosening the directive is the right instinct, and the shared `renderGraphPng` helper removed the duplicated render logic in the process.
- **`form-action 'self'` is set explicitly with the reason recorded** (`// form-action does NOT fall back to default-src (CSP3); set explicitly.`). This is a genuinely easy directive to omit, and the comment explains the non-obvious CSP3 fallback rule for the next reader.
- **`object-src 'none'` and `frame-ancestors 'none'`** close the two highest-leverage legacy vectors, and both are pinned by exact value in the test suite.
- **The `style-src` carve-out is documented as a decision, not a default.** The comment names the specific components that force it and states the cost of removing it — that is the right way to leave a known-weaker directive in a policy.

---

### Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---|---|---|---|---|
| 1 | Prefetched documents bypass CSP entirely and may be cache-promoted | Medium | B1 → B5 | `proxy.ts:57-70` | Medium |
| 2 | CSP pinning test's negative assertions are inoperative | Medium | B1 (guard) | `proxy.test.ts:27-31` | High |
| 3 | `worker-src` unset; falls through to `'strict-dynamic'` `script-src` | Medium | B1 → B3 | `proxy.ts:21`; `fileExtraction.ts:26` | Medium |
| 4 | `/api/*` excluded from CSP, no `nosniff` | Low | B2 | `proxy.ts:59` | High |
| 5 | `style-src 'unsafe-inline'` CSS-injection residual | Low | B3 | `proxy.ts:23` | High / Med |
| 6 | Root-layout `await headers()` forces dynamic render, no rate limit | Low | B1 | `app/layout.tsx:29-33` | Medium |
| 7 | No CSP violation reporting | Informational | B1 | `proxy.ts:20-33` | High |
| 8 | Nonce injection unverified at runtime; `x-nonce` dead header | Informational | B1 | `proxy.ts:41-47` | High |
| 9 | No `nosniff` / `Referrer-Policy` / `Permissions-Policy` | Informational | B1 | `proxy.ts:48-51` | High |

No finding met the HALT-ESCALATE criteria (plaintext secrets, missing auth on privileged endpoints, SQL/command injection, disabled TLS verification, hardcoded keys). API credentials are read from `process.env` at call time and are not present in this diff.

---

### Overall Assessment

This change moves the application from no CSP to a nonce-based `'strict-dynamic'` policy, which is a substantial net improvement and is implemented with the hard parts correct: fresh 128-bit nonces, no client influence over the policy, an explicit `form-action`, and a fix (`toBlob`) that removed a boundary crossing rather than widening a directive. The review-fix commit's addition of the request-side CSP header is what makes the mechanism actually work.

The residual risk is concentrated not in the policy's *content* but in the *conditions under which it is applied* and in the *guard that is supposed to keep it strong*. The prefetch carve-out makes protection contingent on a client-supplied header for a class of requests whose entire purpose is to be replayed as navigations; the pinning test that the commit message cites as the safeguard against future weakening enforces roughly one third of what it claims. Those two, plus the unset `worker-src` that invites a hotfix loosening of `script-src`, are the items I would want closed before treating this policy as load-bearing. Everything else is hardening-on-top.

One process note: the feature's central claim — that Next injects the nonce into its bootstrap scripts under this configuration — remains runtime-unverified. It fails closed if wrong, so it is not a security risk, but the policy should not be considered validated until someone has looked at a served page's `<script nonce=…>` attributes.

---

## Goal-Alignment Note

- **Answered:** Whether the strict-CSP change (d86d2dc..4f018ab) introduces or leaves design-level security flaws — trust-boundary gaps in the proxy matcher, directive completeness of `buildCsp`, nonce generation and lifecycle, the request/response header delivery mechanism, the `exportGraph` serialization-path change, and whether the new `proxy.test.ts` actually constrains what it claims to constrain. All severities reported down to Informational, per the measurement-run instruction.
- **Out of scope:** Pre-existing security posture outside the diff range — absence of authentication and rate limiting on `/api/*`, LLM prompt-injection handling, the analytics filesystem-persistence path, and dependency-level vulnerabilities (no manifest changes in this range). These are named only where they compose with a finding inside the range. No fix loop was run; no code was modified.
- **Escalate:** Nothing meets HALT-ESCALATE. The three Medium findings (prefetch CSP bypass, inoperative pinning test, unset `worker-src`) are the recommended blocking set for a normal review; the runtime nonce-injection verification is a prerequisite for trusting any of the above conclusions about the policy actually reaching the browser.
