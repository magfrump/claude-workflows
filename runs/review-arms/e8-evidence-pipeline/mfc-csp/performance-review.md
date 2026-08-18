# Performance Review — mfc-csp CSP proxy (d86d2dc...d90d6bb)

**Commit:** d90d6bb
**Scope:** `git diff d86d2dc...HEAD` — `app/layout.tsx`, `proxy.ts` (CSP proxy with per-request nonces)
**Date:** 2026-08-18
**Based on:** merged code-fact-check report `runs/review-arms/e8-evidence-pipeline/mfc-csp/code-fact-check-report.md` (k=2, commit d90d6bb)

## Data Flow and Hot Paths

The diff adds a root-level `proxy.ts` (Next.js 16's renamed middleware) that runs on every
matched incoming request — all page navigations, excluding `api/`, `_next/static`,
`_next/image`, `favicon.ico`, and prefetch-headered requests (matcher behavior
execution-verified, fact-check Claim 9). Per matched request it: generates a nonce
(`Buffer.from(crypto.randomUUID()).toString("base64")`), clones the full request header set,
sets `x-nonce` on the clone, builds the CSP string from a 9-element directive array, and sets
one response header. The proxy runs on the Node.js runtime, not Edge (fact-check Claim 7c —
the comment's Edge claim is refuted by the executed build manifest).

The second half of the diff is `await headers()` in the root layout, which opts the layout out
of static rendering. The fact-check established by executed production build that **every**
route, including `/`, is now rendered dynamically (`ƒ (Dynamic) server-rendered on demand`,
Claim 1a, Verified/executed). So the hot path for this diff is *every page request to the
site*: each one now pays proxy execution plus a full server render, where `/` previously
could be served as prerendered static output.

Data sizes are small and bounded (one UUID, ~9 short directive strings, one header map per
request); the interesting costs here are structural — where rendering work happens — not
collection growth.

## Findings

#### Root-layout `await headers()` converts the entire site to per-request dynamic rendering

**Severity:** High
**Location:** `app/layout.tsx:27-31`
**Move:** Find the work that moved to the wrong place (per-route build-time render → per-request render)
**Classification:** Macro (structural: static output replaced by per-request SSR, site-wide) / Hot path (every page request)
**Confidence:** High
**Baseline:** `GET / 200 in 5.3s (next.js: 4.8s, proxy.ts: 138ms, application-code: 384ms)` — one request measured on r1's dev server (`evidence/r1-dev-server.log`, 2026-08-17); dev-mode timing, not production-representative, but the only measured render number in the repo.

Because `await headers()` sits in the *root* layout, the dynamic opt-out is not scoped to
routes that need per-request work — the executed production build shows every route,
including `/` and `/_not-found`, marked dynamic (fact-check Claim 1a, execution verdict; I am
not re-deriving this). Consequences: no route can be served from prerendered static output or
a CDN/full-route cache; every page view pays a full React server render plus the proxy on the
server; on serverless hosting every page view is a billed server invocation rather than a
static-asset hit. Note the fact-check also refuted the comment's stated mechanism (Claim 1b,
Incorrect): the opt-out does **not** make `proxy.ts` run — the matcher alone governs that.
What the opt-out actually buys is a re-rendered HTML document whose embedded nonce matches
the fresh CSP header. That is a real requirement of nonce-based CSP with nonced markup, so
the cost may be an accepted price — but it is currently paid site-wide and undocumented as a
performance tradeoff, and the incorrect comment hides that the *rendering* cost, not proxy
execution, is what the line purchases.

**Recommendation:** Treat "whole site becomes dynamic" as an explicit, documented decision:
fix the comment per the fact-check, and evaluate whether a hash-based or static-shell CSP
strategy could keep content-stable routes static. If the nonce design stays, capture a
production render-latency and hosting-cost baseline before and after this change so the price
is known rather than implied.

#### `x-nonce` request-header forwarding is per-request work with no consumer

**Severity:** Low
**Location:** `proxy.ts:39-47`
**Move:** Count the hidden multiplications (per-request work with zero readers)
**Classification:** Micro (header-map clone + request override per call) / Hot path (every matched request)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

Every matched request clones the full incoming header set (`new Headers(request.headers)`),
sets `x-nonce`, and passes the override through `NextResponse.next({ request: ... })`. The
fact-check verified the mechanism works (Claim 8, executed via probe page) but its scope
notes no current layout or component consumes `x-nonce` — `app/layout.tsx:28-30` itself says
it is not needed because Next reads the nonce from the CSP header (Claim 2,
Verified/executed). So the clone-and-override is speculative plumbing paid on the hottest
path in the app. The constant is small, but it is the largest avoidable per-request
allocation this diff adds, and the request-override path also makes Next treat request
headers as modified.

**Recommendation:** Either delete the `requestHeaders` block and call `NextResponse.next()`
bare (see submitted claim in Endorsements — verify before relying on it), or add the consumer
the comment anticipates. Keep dead capability out of the per-request path.

#### `buildCsp` reassembles the full directive array per request

**Severity:** Informational
**Location:** `proxy.ts:19-32`, `proxy.ts:47`
**Move:** Find the work that moved to the wrong place (constant strings rebuilt per call)
**Classification:** Micro (array literal + join of 9 short strings) / Hot path (every matched request)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

Only the nonce varies between requests; the other 8 directives are compile-time constants,
yet the array is re-allocated and re-joined per request. This is a trivial constant factor at
any plausible traffic level for this app — flagged for completeness, not action. If it were
ever touched, precomputing a prefix/suffix around the nonce segment (template with two
constant strings) is the shape; it is not worth a change on its own.

**Recommendation:** No action required. Fold into the change only if `proxy.ts` is edited for
the x-nonce finding anyway.

#### Runtime comment says Edge; proxy actually runs on Node.js — capacity/cost assumptions would be mispriced

**Severity:** Informational
**Location:** `proxy.ts:35-36`
**Move:** Price the deployment environment
**Classification:** Micro (documentation-driven misestimation, no code cost) / Hot path (comment governs reasoning about every matched request)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The fact-check refuted the comment's Edge-runtime claim (Claim 7c, Incorrect, High — executed
build manifest records `"runtime": "nodejs"`); that refutation binds this review. The
performance relevance: anyone sizing or pricing this middleware from the comment — Edge
cold-start, geographic distribution, per-invocation pricing, or API-availability constraints
— would model the wrong platform. On Node runtime the proxy shares the server process (or a
serverless Node function) with rendering, so its 100+ ms dev-observed cost per request
(`proxy.ts: 138ms` in `evidence/r1-dev-server.log`, dev-mode) lands on the same capacity pool
as SSR, which finding 1 already makes per-request.

**Recommendation:** Fix the comment to say Node.js runtime (as the fact-check directs); make
any hosting cost model use Node-runtime middleware pricing.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Root-layout `await headers()` makes every route dynamic per request | High | `app/layout.tsx:27-31` | High |
| 2 | `x-nonce` forwarding: per-request header clone with no consumer | Low | `proxy.ts:39-47` | High |
| 3 | `buildCsp` rebuilds constant directive array per request | Informational | `proxy.ts:19-32` | High |
| 4 | Edge-runtime comment mispricing (actual runtime is Node.js) | Informational | `proxy.ts:35-36` | High |

## Endorsements (evidence-gated)

- Prefetch requests (`next-router-prefetch`, `purpose: prefetch`) and API/static-asset routes are excluded by the matcher, so no nonce generation, header cloning, or CSP work runs on them — the proxy's per-request cost is confined to real page navigations. [fact-check: claim 9 — Verified (executed)]
- Each matched request observably receives a distinct fresh nonce on both dev and production servers, so nonce generation is a single UUID+base64 per request with no cross-request state, locking, or accumulation observed in the probes. [fact-check: claims 1c/7a — Verified (executed)]
- The cleanup commit (b25e939→d90d6bb) added no per-request work: the diff touches only comments, a return type, and inlining of a single-use local, with CSP directives byte-identical. [fact-check: claim 13 — Verified]
- Next reads the nonce from the response CSP header and tags all generated scripts itself, so the design avoids any per-component nonce-plumbing work in application code. [fact-check: claim 2 — Verified (executed)]
- Removing the `x-nonce` forwarding block (`proxy.ts:41-45`, replacing `NextResponse.next({ request: ... })` with bare `NextResponse.next()`) would leave the served CSP header and the rendered HTML's script nonces unchanged, because no server component reads `x-nonce` and Next sources the nonce from the response CSP header. [unverified — submitted as claim]

## Overall Assessment

The proxy itself is cheap and well-scoped — the matcher keeps its per-request cost off API
routes, static assets, and prefetches, and the fact-check's executed probes confirm the nonce
mechanism works with no per-component plumbing. The performance story of this diff is not the
middleware; it is the one-line `await headers()` in the root layout, which the executed build
shows converts the entire site to per-request dynamic rendering. That is the structural price
of nonce-based CSP as implemented, and it may be acceptable for this app, but it is currently
paid site-wide, justified by a comment whose causal mechanism the fact-check refuted, and
unmeasured — no production render-latency or hosting-cost baseline exists (the only measured
numbers in the repo are dev-mode timings). The most important action is to make that tradeoff
explicit and measured; the secondary cleanup is deleting the unconsumed `x-nonce` forwarding
from the hot path (pending verification of the submitted claim). Production profiling of
render latency before/after the dynamic opt-out is the one measurement needed to confirm or
downgrade finding 1's practical impact.
