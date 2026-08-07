Commit: f25d968

# Security Review — e3/csp-arm1 (strict CSP with per-request nonces), full-loop iteration 2

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm1` — `proxy.ts` (new), `proxy.test.ts` (new), `app/lib/security/csp.ts` (new), `app/lib/security/csp.test.ts` (new), `app/layout.tsx`, `app/lib/utils/exportGraph.ts`
**Date:** 2026-08-06
**Based on:** merged code-fact-check (k=3; 0 Incorrect, 0 Stale) supplied by the orchestrator; full-1 security review treated as advisory only, with its "independently confirmed OpenAlex integration" claim discarded (verified below: no OpenAlex code exists in this tree).

**No Critical and no High findings.** The four full-1 reds are genuinely fixed, and the fixes are the right ones rather than the convenient ones. Everything below is Medium or lower, and every item is a hardening or scoping gap in a control that is otherwise well built.

## Trust Boundary Map

```
B1 (new):  [browser-supplied request headers:        → [proxy.ts matcher +      → [Next renderer's request
            x-nonce, Content-Security-Policy,           requestHeaders.set()]      headers → nonce stamped
            next-router-prefetch, purpose]                                         onto bootstrap <script>]

B2 (new):  [proxy-minted nonce                       → [buildCsp() policy       → [browser CSP engine
            crypto.randomUUID() → base64]               string]                    enforcing script execution]

B3 (new):  [build-time NODE_ENV]                     → [buildCsp(nodeEnv)       → ['unsafe-eval' present or
                                                        `=== "development"`]      absent in shipped policy]

B4 (moved):[graph DOM subtree (LLM/user-derived      → [html-to-image toBlob →  → [downloaded file]
            node labels)]                               canvas.toBlob()]           (no longer crosses
                                                                                   connect-src via fetch)
```

What enters from outside: a browser's raw request headers (B1) — including two headers this diff makes *security-relevant* for the first time (`x-nonce`, and `purpose`/`next-router-prefetch`, which decide whether the control runs at all). What crosses upward in trust: the minted nonce (B2), which the renderer treats as an execution grant, and `NODE_ENV` (B3), which decides whether `'unsafe-eval'` ships. B4 is a boundary the diff *removes* — the previous `fetch(dataUrl)` round-trip crossed `connect-src`; `toBlob` keeps the pixel data inside the DOM. The diff's central trust assumption is that anything Next tags with the request-header nonce is trusted, and `'strict-dynamic'` extends that trust transitively to whatever those scripts load.

## Findings

#### Whether the CSP applies at all is decided by a client-supplied request header

**Severity:** Medium
**Location:** `proxy.ts:41-52`
**Boundary:** B1
**Move:** #5 (invert the access control model) — enumerate what the matcher does *not* cover
**Confidence:** Medium

**Evidence:**
```
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```

**Legibility-target:** A reader can confirm the mechanism in one step — `missing` is a negative match, so a request carrying `Purpose: prefetch` skips `proxy()` entirely and its response therefore has no `Content-Security-Policy` header at all. What a reader cannot confirm from the diff, and what sets the severity, is whether a browser ever serves such a response as a rendered top-level document.

The comment justifies this exclusion on cost grounds ("would otherwise burn a nonce on a request that may never paint"), which is true for Next's own RSC prefetches. But `Purpose: prefetch` is not exclusively a Next-internal signal: Chrome has historically attached it to browser-initiated `<link rel=prefetch/prerender>` and omnibox prefetches of *full documents*, and a prerendered document can subsequently be activated by the user's real navigation. On that path the user ends up on an HTML document that was served with no CSP, no `frame-ancestors`, and no nonce — the control silently does not exist for that page view, and nothing in the app observes the gap (see the violation-reporting finding below). The inversion worth stating plainly: this is the one place where an input on the untrusted side of B1 determines whether a security control on the trusted side executes, and the default for the uncovered case is *no policy* rather than a policy. An attacker cannot force this directly (cross-origin attackers cannot set request headers on a navigation or an iframe load), which is why this is Medium and not High — the realistic exposure is loss of coverage on legitimate browser-prefetched navigations, not a targeted bypass.

**Recommendation:** Drop the `missing` clause and let prefetches receive a policy too — minting a UUID and joining nine strings is not a cost worth a coverage hole. If the exclusion is kept, narrow it to Next's own `next-router-prefetch` (which really is RSC-payload-only) and delete the generic `purpose: prefetch` entry, and add a test asserting that a request with `Purpose: prefetch` still gets a CSP.

#### Request-header normalization is path-scoped, so excluded paths receive `x-nonce` and `Content-Security-Policy` verbatim from the client

**Severity:** Low
**Location:** `proxy.ts:25-31, 41-52`
**Boundary:** B1
**Move:** #2 (find the implicit sanitization assumption)
**Confidence:** High

**Evidence:**
```
  requestHeaders.set("Content-Security-Policy", csp);
  ...
  requestHeaders.set("x-nonce", nonce);
```
and
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

**Legibility-target:** A reader can check this by noting that the `set()` calls live inside `proxy()`, and `proxy()` does not run for any path the matcher excludes — so for `/api/*` the renderer/route handler sees whatever `x-nonce` and `Content-Security-Policy` request headers the client chose to send.

`proxy.test.ts` correctly asserts that a client-supplied `x-nonce` is clobbered rather than appended, and the code comment explains the `.set`-not-`.append` choice. Both are right — but they establish that property only on matched paths. The overwrite is not a global invariant of the app; it is a property of one route class. Nothing reads `x-nonce` today, so there is no live exploit. The risk is the shape of the assumption: a future server component or route handler that reads `x-nonce` and treats it as "the proxy set this" would be correct for pages and wrong for `/api/*`, and the test suite as written would not catch the difference. The same applies to the `Content-Security-Policy` *request* header, which is now load-bearing input to Next's renderer: on excluded paths a client can set it freely.

**Recommendation:** Either strip `x-nonce` and `Content-Security-Policy` from inbound request headers unconditionally (widen the matcher and branch inside `proxy()` instead of excluding paths from it), or add a comment at the `requestHeaders.set("x-nonce", ...)` line stating that the clobber holds only for matcher-covered paths, so a future reader of `x-nonce` knows not to trust it in a route handler.

#### Matcher exclusions are unanchored prefixes, not path segments

**Severity:** Low
**Location:** `proxy.ts:44`
**Boundary:** B1
**Move:** #5 (invert the access control model)
**Confidence:** High

**Evidence:**
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

**Legibility-target:** Verifiable by inspection of the regex: the negative lookahead has no trailing `/` or `$`, so it excludes any path *beginning with* those strings — `/api-docs`, `/apiary`, `/favicon.icon`, `/_next/staticky` — not just the intended path segments.

No such routes exist in this tree today (`app/` contains only `api/`, `page.tsx`, and `layout.tsx`), so this is latent rather than live. It matters because the failure mode is silent and default-open in two ways at once: a page route named `/api-status` would render with no CSP *and* would receive an unfiltered `x-nonce` request header (previous finding). A route author adding such a page has no signal that they have opted out of a security control.

**Recommendation:** Anchor the exclusions to segment boundaries — `"/((?!api/|api$|_next/static/|_next/image/|favicon\\.ico$).*)"` — and add a matcher test asserting that a path like `/api-docs` is covered.

#### Nonce-bearing documents carry no explicit cache directive

**Severity:** Low
**Location:** `proxy.ts:33-37`, `app/layout.tsx:26-42`
**Boundary:** B2
**Move:** #4 (time-of-check to time-of-use)
**Confidence:** Medium

**Evidence:**
```
  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", csp);
```

**Legibility-target:** A reader can confirm that the proxy sets no `Cache-Control` and that the freshness guarantee therefore rests entirely on Next's own dynamic-rendering defaults, which follow from the `await headers()` opt-out in `layout.tsx` rather than from anything in `proxy.ts`.

A per-request nonce is a check-then-use pair separated by the network: the policy is minted at request time and enforced when the document executes. Anything that stores the document between those points — a CDN, a corporate caching proxy, a reverse proxy added later — decouples them, and the same nonce is then served to many users. A reused nonce is a weakened nonce: an attacker who can read one cached response learns a value that will be accepted on other users' page views, which is precisely the property `'strict-dynamic'` is relying on. The layout comment reasons carefully about *static prerendering* being incompatible with nonces, which is the same hazard one layer up, but the intermediary-caching case is not addressed and is not enforced by anything in this diff. Confidence is Medium because Next does mark dynamic responses no-store today; the point is that the guarantee is implicit and could be lost without any change to this code.

**Recommendation:** Have the proxy set `Cache-Control: no-store` (or at minimum `private, no-cache`) alongside the CSP header on the responses it stamps, so nonce freshness is asserted by the same code that mints the nonce rather than inherited from an unrelated framework default.

#### `form-action` is absent from the policy

**Severity:** Low
**Location:** `app/lib/security/csp.ts:41-53`
**Boundary:** B2
**Move:** #5 (invert the access control model)
**Confidence:** High

**Evidence:**
```
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
```

**Legibility-target:** Checkable against the directive list asserted in `csp.test.ts` — the test enumerates all nine directives exactly, and `form-action` is not among them.

The policy covers the classic script-gadget trio (`base-uri`, `object-src`, `frame-ancestors`) but omits `form-action`, which is the directive that stops injected markup from posting data to an attacker-controlled origin. `form-action` does not fall back to `default-src`, so `default-src 'self'` does not cover it. The live exposure is small: `react-markdown` v10 is used without `rehype-raw`, so raw HTML in LLM- or user-supplied markdown is escaped, and there is no `dangerouslySetInnerHTML` anywhere in the tree. But the whole justification for this CSP, stated in `csp.ts`, is defense against something that "slipped past markdown sanitization" — and in exactly that scenario, `style-src 'unsafe-inline'` plus a missing `form-action` leaves a viable markup-only exfiltration path that does not require script execution.

**Recommendation:** Add `form-action 'self'` to the directive list and to the expected-directive assertion in `csp.test.ts`. There are no forms in the app that post cross-origin, so this costs nothing.

#### No CSP violation reporting

**Severity:** Informational
**Location:** `app/lib/security/csp.ts:41-53`
**Boundary:** B2
**Move:** #3 (check the error path, not just the happy path)
**Confidence:** High

**Evidence:**
```
 * depend on eval (pdfjs-dist probes for it with `new Function("")`, but that
 * probe is caught and pdfjs falls back — it only logs a CSP violation), so the
 * carve-out is gated on the environment and never ships in a production build.
```

**Legibility-target:** The policy has no `report-to` or `report-uri` directive, so the "logs a CSP violation" the comment relies on lands only in the end user's browser console and is never observable by the operator.

This is the error path of the entire control. When the policy blocks something — a genuine injection attempt, or the pdfjs eval probe, or a future dependency that breaks under `'strict-dynamic'` — nobody finds out. That cuts both ways: real attacks are invisible, and legitimate breakage surfaces as a bug report rather than a signal, which historically is what pressures teams into widening directives. It also compounds the first two findings: coverage holes produce no violations *by construction*, since a page with no CSP cannot report one.

**Recommendation:** Add `report-to` (with a `Reporting-Endpoints` response header) pointing at a lightweight collector route, even one that only logs. Failing that, note the deliberate omission in the `csp.ts` header comment so a future reader does not assume violations are being captured.

#### CSP is the only security header set, and `/api/*` responses get none

**Severity:** Informational
**Location:** `proxy.ts:33-37, 41-52`
**Boundary:** B1, B2
**Move:** #1 (trace the trust boundaries)
**Confidence:** High

**Evidence:**
```
  response.headers.set("Content-Security-Policy", csp);
  return response;
```

**Legibility-target:** `next.config.ts` is empty (`/* config options here */`), so the single `set` in `proxy.ts` is the app's entire response-header security posture, and it does not run for `/api/*`.

The diff establishes a response-header seam and uses it for exactly one header. `X-Content-Type-Options: nosniff` and `Referrer-Policy` are absent everywhere, and the API routes — which are the ones returning LLM-derived text, including `text/event-stream` bodies from `streamLlm.ts` — are excluded from the proxy entirely. Modern browsers do not sniff `application/json` into HTML, so this is hardening rather than a live hole, but the excluded surface is the one carrying the least-trusted content in the app.

**Recommendation:** Set `nosniff` and a `Referrer-Policy` in `next.config.ts` `headers()` so they apply to all routes including `/api/*`, leaving `proxy.ts` responsible only for the per-request nonce policy that genuinely requires request-time computation.

#### `x-nonce` is a live header with no consumer

**Severity:** Informational
**Location:** `proxy.ts:27-31`
**Boundary:** B1
**Move:** #1 (trace the trust boundaries)
**Confidence:** High

**Evidence:**
```
  // x-nonce is the conventional seam for server components that render their
  // own <Script> tags. Nothing reads it today (Next handles its own bootstrap
  // scripts via the header above); `.set` rather than `.append` so a
  // client-supplied value is clobbered rather than joined into a comma-list.
```

**Legibility-target:** Confirmed by grep — no file in `app/` reads `x-nonce`; `proxy.test.ts` is its only consumer.

The comment is honest about the seam being unused, which is the right call and much better than silently shipping it. Recording it as Informational rather than passing over it: a header that exists, is tested, and is never read tends to be mistaken by later readers for an enforced invariant, and the invariant it looks like it provides ("`x-nonce` is trustworthy") is only true on matcher-covered paths (see the second finding). The test `"overwrites a client-supplied x-nonce rather than appending to it"` is the one test in the suite that guards a property nothing currently depends on.

**Recommendation:** No change required. If the seam is still unused at the next touch of this file, consider deleting it and its test rather than carrying an untrusted-input surface that exists only for a hypothetical consumer.

#### `csp.ts` justifies `connect-src 'self'` partly on an integration that does not exist

**Severity:** Informational
**Location:** `app/lib/security/csp.ts:20-24`
**Boundary:** B2
**Move:** #2 (find the implicit sanitization assumption) — applied to the documented threat model rather than to code
**Confidence:** High

**Evidence:**
```
 * `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter
 * calls are server-to-server (Next API routes), not browser-to-third-party.
```

**Legibility-target:** Directly checkable: `rg -i openalex` over the tree returns exactly one hit, this comment line. The only external endpoint in the codebase is `OPENROUTER_API_URL` in `app/lib/llm/callLlm.ts:7`, and no client-side code fetches an absolute `https://` URL.

This restates the merged fact-check's MA, and I verified it independently rather than inheriting it: there is no OpenAlex client, server, or config in this tree. Flagging it under security rather than leaving it to the fact-check because the sentence is a *threat-model claim* — it is the stated reason a security directive is tight enough — and a reader auditing whether `connect-src 'self'` is still correct will go looking for an OpenAlex call path, fail to find one, and be left unsure whether the comment is stale documentation or a missing integration. The conclusion (`connect-src 'self'` is right) is correct; only the enumeration is wrong. Note also for the record that full-1's security review asserted this integration was "independently confirmed"; it does not exist, and that assertion should not be carried forward.

**Recommendation:** Replace the enumeration with the verifiable form the fact-check suggests: "the only third-party call is OpenRouter, and it is made server-side from Next API routes."

## What Looks Good

- **The nonce-delivery fix is the correct one, and the test proves it.** Setting the policy on the *forwarded request* headers (`proxy.ts:25`) is the non-obvious half of nonce-based CSP in Next, and the comment cites the actual mechanism (`app-render.js` parsing the request header) rather than asserting it. `proxy.test.ts` reads the value back through `x-middleware-request-content-security-policy` and states in-line that deleting the `set` must fail the test — a falsification test, verified by mutation per the orchestrator. This is the finding class where a plausible-looking fix (response header only) yields a CSP that blocks the app's own bootstrap, and it was avoided.
- **The `exportGraph` fix resists the tempting wrong answer.** The failure was `fetch(dataUrl)` hitting `connect-src`; the easy fix is widening `connect-src` to `data:`, which would have punched a hole in an otherwise tight directive. Moving to `toBlob` keeps the operation inside the DOM instead, and both the code comment and a dedicated regression test in `csp.test.ts` say explicitly that widening the directive is the wrong fix. Directive tightness is now defended by a test rather than by memory.
- **The dev carve-out fails closed and is proven to.** `nodeEnv === "development"` compares against the *permissive* value, so unset, misspelled, and unexpected environments all get the strict policy — and `csp.test.ts` iterates `[undefined, "", "Development", "dev", "test", "prod"]` to demonstrate it. The differential test asserting that dev and prod differ by exactly `' 'unsafe-eval''` is a good way to prevent the carve-out from silently growing.
- **Nonce generation is sound.** `crypto.randomUUID()` is CSPRNG-backed (~122 bits of entropy) and base64-encoded for header safety; `proxy.test.ts` asserts freshness across two calls. Passing `nodeEnv` as a parameter rather than reading ambient `process.env` is what makes the production branch observable from a test process without mutating global state — a small design choice that is why the fail-closed test above can exist at all.
- **The `await headers()` opt-out is documented as load-bearing rather than left as a puzzle.** The layout comment explains why per-request nonces and static prerendering are mutually exclusive, states the cost as nil with the specific reason (single `"use client"` route, no `generateStaticParams`/`revalidate`/ISR), and names the condition under which to revisit (switching to hashes). A future reader tempted to "optimize" the `await` away has what they need to not do that.
- **`'strict-dynamic'` is safe in this tree.** Its transitive-trust property is only as good as what nonced scripts load; here that is Next's own chunk loader, and there is no `dangerouslySetInnerHTML` or `rehype-raw` anywhere, so no user- or LLM-derived markup reaches the DOM as HTML. The pdfjs worker is loaded from a same-origin bundled URL (`new URL("pdfjs-dist/build/pdf.worker.min.mjs", import.meta.url)`), so it is permitted by `default-src 'self'` via the `worker-src → child-src → default-src` fallback chain and is not affected by `'strict-dynamic'`.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | CSP application gated on client-supplied `purpose: prefetch` header | Medium | B1 | `proxy.ts:41-52` | Medium |
| 2 | `x-nonce` / CSP request-header normalization is path-scoped, not global | Low | B1 | `proxy.ts:25-31, 41-52` | High |
| 3 | Matcher exclusions are unanchored prefixes, not segments | Low | B1 | `proxy.ts:44` | High |
| 4 | No explicit `Cache-Control` on nonce-bearing documents | Low | B2 | `proxy.ts:33-37` | Medium |
| 5 | `form-action` missing from the policy | Low | B2 | `app/lib/security/csp.ts:41-53` | High |
| 6 | No CSP violation reporting (`report-to`/`report-uri`) | Informational | B2 | `app/lib/security/csp.ts:41-53` | High |
| 7 | CSP is the only security header; `/api/*` gets none | Informational | B1, B2 | `proxy.ts:33-37` | High |
| 8 | `x-nonce` seam has no consumer | Informational | B1 | `proxy.ts:27-31` | High |
| 9 | `csp.ts` cites a nonexistent OpenAlex integration in its threat model | Informational | B2 | `app/lib/security/csp.ts:20-24` | High |

## Overall Assessment

This is a well-built security control and the iteration has visibly improved it: the nonce now actually reaches the renderer, the export path was fixed by tightening the code rather than loosening the policy, and the policy itself is an isolated pure function with eleven tests including a fail-closed environment check and a directive-tightness regression guard. **Nothing Critical or High exists in this diff**, and none of the findings below indicate an architectural problem — every one is fixable in place, most in a line or two. The pattern that ties the top three findings together is worth naming, though: the *policy* is thoroughly tested while the *scope* of the policy is not. `csp.ts` has eleven tests; the matcher in `proxy.ts` has zero, and it is the matcher that decides which requests the policy protects — via an unanchored regex and a negative header match on a client-supplied value. The single most important thing to address is finding #1: remove or narrow the `purpose: prefetch` exclusion so that whether the CSP applies is not a function of an inbound request header, and add matcher-coverage tests so the scope is defended the way the policy already is.

## Goal-Alignment Note

- **Answered:** Whether the four full-1 fixes introduce new security exposure (they do not); the status of the six prior-known ambers in the security domain — prefetch CSP bypass (confirmed, raised to Medium with a concrete non-attacker path), missing `form-action` (confirmed, Low), matcher prefix anchoring (confirmed, Low, latent), `x-nonce` dead seam (confirmed, Informational, no live exploit — clobber verified but only on matched paths), no violation reporting (confirmed, Informational), `/api` no `nosniff` (confirmed, Informational, folded into a broader response-header finding); and the explicit Critical/High question — none exist.
- **Out of scope:** Pre-existing issues outside `d86d2dc..HEAD` — notably the unauthenticated `DELETE /api/analytics` handler (`app/api/analytics/route.ts`) and the general absence of authn/authz on API routes. These are not touched by this diff and were not introduced by it; they are noted here only so a reader does not mistake their omission for a clean bill of health on the API surface. No dependency manifest or lockfile changed in this diff, so cognitive move #10 did not apply.
- **Escalate:** Nothing. No canonical HALT-ESCALATE pattern matched (no plaintext secrets, no missing authn on privileged endpoints introduced here, no SQL/command injection, no disabled TLS verification, no hardcoded cryptographic keys).
