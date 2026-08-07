# Architecture Review — validate-T arm 2 pass 2 (e3-loops)

**Commit:** 99e1229 (`fix: address full-review blockers R1-R4 (e3 arm2 iter1)`)
**Scope:** `git diff d86d2dc..HEAD` in `runs/review-arms/e3-loops/wt-validate-arm2` (detached at 99e1229; ancestors of 99e1229 only, fresh draw)
**Date:** 2026-08-06
**Based on:** `code-fact-check-report.md` (merged k=3) in this directory
**Trigger:** new top-level module (`proxy.ts`) + cross-cutting concern (CSP/nonce pipeline)
**Cross-reference:** no `security-review.md` present in the output dir at review time → trust-boundary cross-reference is a no-op.

Files in scope: `proxy.ts` (new), `proxy.test.ts` (new), `app/layout.tsx` (config export added), `app/lib/utils/exportGraph.ts` (new export + call-site swap), `app/lib/utils/exportGraph.test.ts` (new).

---

## Scope check

In scope on two trigger categories:
- **Module structure** — `proxy.ts` is a new top-level module (Next.js 16 Proxy, formerly Middleware).
- **Cross-cutting concerns** — the CSP/per-request-nonce pipeline spans the proxy, the root layout's render mode, and framework behavior.
- **Public APIs** — two new exports (`buildCsp`, `dataUrlToBlob`) and one new module-surface config export (`export const dynamic`).

Proceeding with the full review.

---

## Prior-red closure verification

The task requires confirming that the two original Structural reds are closed in this state.

- **R3 — untested policy → CLOSED.** The CSP string is now produced by a pure exported function `buildCsp(nonce)` (`proxy.ts:19-31`), imported and asserted by `proxy.test.ts` (directive-set, nonce/`strict-dynamic` on `script-src`, `unsafe-inline` carve-out on `style-src`). Extracting the policy from the proxy handler into a pure, dependency-free function is the *correct structural move* to make the policy assertable without standing up the framework. The untestable-policy structural defect no longer exists.
- **R4 — discarded `await headers()` → CLOSED.** The runtime call whose result was thrown away is replaced by a declarative module-surface config, `export const dynamic = "force-dynamic"` (`app/layout.tsx:24`). This is a static structural declaration rather than a runtime side-effect-free call — the anti-pattern (a call with no consumed return) is gone. Fact-check Cluster 4 confirms no `headers()` call remains in the layout.

**No Structural finding exists in this diff.** See Overall Assessment.

---

## Dependency Map

```
proxy.ts ──imports──> next/server (NextResponse, NextRequest type)   [entry → framework: correct]
  └─ buildCsp(nonce): string        pure, zero imports               [leaf; depended on by proxy() + proxy.test.ts]
  └─ proxy(request): NextResponse   composition root for CSP
  └─ config { matcher }             framework-consumed declaration

app/layout.tsx
  └─ export const dynamic="force-dynamic"   framework-consumed declaration; participates in the nonce invariant

app/lib/utils/exportGraph.ts ──imports──> html-to-image, ./export (triggerDownload)
  └─ dataUrlToBlob(dataUrl): Blob   pure codec, zero new imports (replaces removed fetch())
  └─ downloadGraphAsPng / graphToPngBlob   now call dataUrlToBlob instead of fetch()
```

Directions are all correct: the volatile entry module (`proxy.ts`) depends on the framework; the reusable pure functions (`buildCsp`, `dataUrlToBlob`) are leaves with no outward or upward dependencies. `dataUrlToBlob` *removes* a dependency edge — the former `fetch(dataUrl)` implicit dependency on the network/`connect-src` boundary is gone, replaced by in-process decoding. That is a dependency-surface reduction and is architecturally positive.

The one non-local structure worth attention is the **CSP-nonce invariant**, which is not owned by a single module: it is distributed across `proxy.ts` (sets both request and response CSP headers), `app/layout.tsx` (forces per-request render), and Next's framework internals (reads the request CSP header, stamps the nonce onto bootstrap scripts). This is the subject of finding C1.

---

## Findings

#### C1 — The CSP-nonce invariant is distributed across three touch points with no single owner

**Severity:** Coupling
**Location:** `proxy.ts:37-49`, `app/layout.tsx:12-24` (+ implicit Next.js render behavior)
**Move:** #4 (layer violation / cross-cutting concern) · #7 (coupling surface)
**Confidence:** High
**Legibility-target:** a future maintainer who edits the proxy matcher, removes `force-dynamic`, or refactors the layout, and cannot see that they have broken nonce delivery.

The security feature only works if three things stay aligned: (a) `proxy()` sets the same CSP on *both* the forwarded request headers and the response, (b) the root layout renders per-request so a nonce is not baked into a static document, and (c) Next reads the nonce off the request CSP header at render time. None of these three is mechanically linked to the others — the coupling is held together entirely by prose comments. Removing `export const dynamic = "force-dynamic"`, editing the matcher to exclude the page route, or dropping the request-side header set would each silently disable the nonce with no failing unit test (the fact-check caveat notes test execution can't cover the render-time half; only manual browser verification catches it). This is control/temporal coupling across a module boundary and a framework seam: correctness depends on a non-local, comment-documented contract.

**Evidence (verbatim):**
`proxy.ts:37-46`
```
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("Content-Security-Policy", csp);
  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled
  // through to a server component.
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", csp);
```
`app/layout.tsx:19-24`
```
// Next.js takes the nonce from the request's
// Content-Security-Policy header (set in proxy.ts) and stamps it onto the
// bootstrap <script> tags it emits, so nothing here reads it directly.
export const dynamic = "force-dynamic";
```

**Recommendation:** Accept as a documented, inherent property of the Next.js nonce mechanism (the framework dictates this shape — it is not gratuitous coupling). To harden it against silent regression, add a comment cross-link in `proxy.ts` pointing at the `layout.tsx` `force-dynamic` dependency (the layout already points back), and — where feasible — an integration/e2e assertion that a rendered document carries a `nonce-` attribute matching the response CSP, closing the gap the unit tests structurally cannot.

---

#### C2 — `buildCsp` widens the proxy entry module's public surface for testability

**Severity:** Coupling
**Location:** `proxy.ts:19-31`
**Move:** #3 (module boundary) · #2 (single responsibility)
**Confidence:** Medium
**Legibility-target:** a reader treating `proxy.ts` as a framework entry point who now finds a general-purpose policy builder exported from the same file, and any future importer that binds to `buildCsp` from the entry module.

`proxy.ts` is a framework composition root: its natural public surface is the `proxy` handler and the `config` matcher that Next consumes by convention. Exporting `buildCsp` as a second public symbol from that same file mixes "framework entry point" with "reusable CSP policy library" on one surface. The export exists to make the policy unit-testable (the R3 fix), which is a good reason — but the structural cost is that the entry module now has two reasons to change and two consumer classes (the framework; the test, and any future policy consumer). This is a known-open amber, correctly classified: it is a surface-minimality stretch, not a dependency-direction or layering fault.

**Evidence (verbatim):**
`proxy.ts:19`
```
export function buildCsp(nonce: string): string {
```
`proxy.test.ts:3`
```
import { buildCsp, proxy } from "./proxy";
```

**Recommendation:** Optional. If a second CSP consumer appears, extract `buildCsp` to a dedicated `app/lib/csp.ts` (or similar) and have both `proxy.ts` and the test import it there, keeping the entry module's surface to `proxy` + `config`. For a single pure function consumed only by the handler and its test, leaving it in place is a defensible pragmatic call.

---

#### C3 — `dataUrlToBlob` is a generic codec housed in a domain-specific export module

**Severity:** Minor
**Location:** `app/lib/utils/exportGraph.ts:16-44`
**Move:** #2 (single responsibility) · #3 (module boundary)
**Confidence:** Medium
**Legibility-target:** a future developer needing data-URL decoding elsewhere who won't find it under a graph-export module, and a reader of `exportGraph.ts` who must understand the app's CSP posture to see why a codec lives here.

`exportGraph.ts` is documented as graph-image export utilities (its header cites code-splitting for `html-to-image`). `dataUrlToBlob` is a fully generic `data:` URL decoder with no graph- or export-specific logic, exported publicly. Its placement couples a general utility to a domain module: a reader must know the CSP `connect-src 'self'` rationale — which lives in `proxy.ts` — to understand why the helper exists here at all (the "why" comment references a policy owned by another module). This is low-impact today (only two in-file call sites) but is a mild boundary smudge: the module's stated responsibility and this export's responsibility differ.

**Evidence (verbatim):**
`exportGraph.ts:1-4`
```
/**
 * Graph image export utilities. Separated for code-splitting since
 * html-to-image is only needed when exporting the React Flow graph.
 */
```
`exportGraph.ts:16-23`
```
/**
 * Decode a `data:` URL to a Blob in-process.
 *
 * `fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, and
 * the app's CSP sets `connect-src 'self'`, which refuses `data:`. Decoding here
 * keeps that directive tight instead of widening it for an export helper.
 */
export function dataUrlToBlob(dataUrl: string): Blob {
```

**Recommendation:** Optional. If another caller needs it, move `dataUrlToBlob` to a neutral `app/lib/utils/dataUrl.ts` and re-import in `exportGraph.ts`. Until then, keeping it co-located with its sole consumers is acceptable; the export being public (not module-private) is the only thing that raises this above informational.

---

#### I1 — `x-nonce` forwarded header is a seam with no consumer

**Severity:** Informational
**Location:** `proxy.ts:44-45`
**Move:** #8 (extension points) · #3 (module boundary)
**Confidence:** High
**Legibility-target:** a reader who infers from the "smuggled through to a server component" comment that some server component reads `x-nonce`, when none does.

The proxy forwards an `x-nonce` request header (and defensively overwrites any client-supplied value), but no server component reads it — the nonce actually reaches the framework via the request CSP header (finding C1). Architecturally this is a public seam / extension point defined ahead of a consumer that does not yet exist. It is harmless and correctly overwrite-not-append, but it is dead structural surface: the comment implies an active data path that is currently inert (corroborated by fact-check Cluster B). Not a coupling cost today because nothing binds to it.

**Evidence (verbatim):**
`proxy.ts:41-45`
```
  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled
  // through to a server component.
  requestHeaders.set("x-nonce", nonce);
```

**Recommendation:** Either drop the `x-nonce` header until a consumer needs it, or reword the comment to mark it explicitly as defense-in-depth for a future/absent consumer so a reader doesn't assume a live path. No structural change required.

---

## What Looks Good

- **Policy extracted into a pure, testable function (R3 fix).** Pulling the CSP string out of the request handler into `buildCsp(nonce)` — zero dependencies, deterministic — is exactly the right structural response to "the policy is untested." The proxy handler is now a thin composition root over a pure core.
- **Declarative render-mode config replaces a discarded runtime call (R4 fix).** `export const dynamic = "force-dynamic"` states an invariant at the module surface rather than performing a runtime call whose result was thrown away. Less surface area for the same effect.
- **`dataUrlToBlob` reduces the dependency surface.** Replacing `fetch(dataUrl)` with in-process decoding removes an implicit dependency on the network/`connect-src` boundary and lets the CSP `connect-src 'self'` directive stay tight — a change that keeps a security boundary narrow *is* good architecture, and the "why" is documented at the call boundary.
- **Matcher scoping is deliberate and minimal.** The `config.matcher` excludes API routes, static assets, and prefetches with a documented rationale, keeping the cross-cutting concern applied only where it is load-bearing (page navigations).
- **Correct dependency direction throughout.** Entry module depends on the framework; pure leaves depend on nothing; no core-depends-on-detail inversion, no circular dependency, no layer skip.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| C1 | CSP-nonce invariant distributed across proxy + layout + framework, no single owner | Coupling | `proxy.ts:37-49`, `app/layout.tsx:12-24` | High |
| C2 | `buildCsp` widens the proxy entry module's public surface for testability | Coupling | `proxy.ts:19-31` | Medium |
| C3 | `dataUrlToBlob` generic codec housed in a domain-specific export module | Minor | `app/lib/utils/exportGraph.ts:16-44` | Medium |
| I1 | `x-nonce` forwarded header is a seam with no consumer | Informational | `proxy.ts:44-45` | High |

**Structural: 0.** Coupling: 2. Minor: 1. Informational: 1.

---

## Overall Assessment

This change maintains and, in the two prior-red areas, improves the system's structural integrity. Both original Structural reds are genuinely closed: the untested-policy defect (R3) is resolved by the correct structural move — extracting a pure `buildCsp` from the handler so the policy is assertable — and the discarded-`await headers()` defect (R4) is resolved by a declarative module-surface config. **No Structural finding exists in this diff.** The remaining items are all known-open ambers and below, exactly the three the task flagged (C2 `buildCsp` from the entry file, I1 `x-nonce` dead seam, C3 `dataUrlToBlob` placement) plus one I consider the most important standing structural concern: C1, the CSP-nonce invariant that spans `proxy.ts`, `layout.tsx`, and framework internals held together only by comments and testable only in part by unit tests. C1 is inherent to the Next.js nonce mechanism rather than gratuitous, so it is Coupling (mitigate with a cross-link comment and an e2e assertion), not Structural. Every finding is fixable in place; none indicates a need for restructuring.

## Goal-Alignment Note

The task is to validate decision 031 tier policy T by confirming **0 red at arm 2 pass 2 (99e1229)** on the architecture axis. Under the rubric mapping (Structural → 🔴, Coupling → 🟡, Minor/Informational → 🟢), this review yields **0 Structural → 0 architecture 🔴**. The two original Structural reds (R3, R4) are verified closed. The residual set is 2 Coupling (🟡) + 1 Minor + 1 Informational (🟢) — all previously known-open ambers or below, consistent with the historical rule that these are ambers, not reds. The architecture axis therefore contributes **zero red** to arm 2 pass 2, consistent with tier policy T's expectation that this pass reaches 0-red. Combined with the fact-check axis's independently reported 0-red, the architecture stage produces no blocker to loop termination. (Final termination determination remains the loop owner's.)
