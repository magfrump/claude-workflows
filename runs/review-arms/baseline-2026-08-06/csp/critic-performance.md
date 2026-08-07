Commit: d90d6bb
# Performance Review — CSP proxy + layout static-rendering opt-out (wt-csp)

**Scope:** `git diff d86d2dc..d90d6bb` — `app/layout.tsx`, `proxy.ts`
**Date:** 2026-08-06
**Based on:** `csp/fact-check.md` (code fact-check, 10 claims)

## Data Flow and Hot Paths

Two changes. (1) `proxy.ts` is a new Next 16 proxy (renamed middleware) that runs per matched request: it generates a per-request nonce, copies request headers to add `x-nonce`, and sets a `Content-Security-Policy` response header. Its `matcher` restricts execution to page navigations, excluding `api`, `_next/static`, `_next/image`, `favicon.ico`, and prefetch requests. (2) `app/layout.tsx` becomes an `async` component and `await headers()` to opt the root layout out of static rendering.

Critical context for severity: the app is effectively a single-page client SPA. `app/page.tsx` is a `"use client"` component and is the only page under the root layout. This bounds the real cost of the static-rendering opt-out — the server-rendered document is a small, near-constant shell (layout + client-component boundary), not a data-dependent render that grows with input.

No measurements (load test, dashboard, profiler, TTFB numbers) were provided in the diff, the PR intent, or the surrounding repo. Every finding below is therefore speculative.

## Findings

#### App-wide static-rendering opt-out forfeits static generation / CDN caching of the initial document

**Severity:** Medium
**Location:** `app/layout.tsx:31`
**Move:** Find the work that moved to the wrong place (build-time → per-request)
**Classification:** Macro (structural: forfeits full-route static generation) / Hot path (every initial page request)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

`await headers()` in the *root* layout makes the entire route tree dynamic. Because the root layout wraps every route, this is app-wide, not scoped to one page (fact-check Claim 1 confirms the opt-out mechanism is real). The initial HTML document, which Next would otherwise prerender at build time and serve as a static, CDN-cacheable file, is now rendered on the origin per request. The delta per request is one RSC/HTML render of the layout plus the client-component boundary, plus loss of edge/CDN caching of that document — so origin CPU and TTFB are paid on every navigation instead of amortized once at build. Under low traffic this is negligible; the concern is per-request origin cost under load. The magnitude is capped by the app being a client SPA (the shell render is small and constant, which is why this is Medium and not High), but the loss of static-document CDN caching applies to 100% of page loads.

**Recommendation:** Confirm this is the intended tradeoff (the PR intent already flags it). If per-request nonce embedding is the goal, prefer scoping dynamic behavior as narrowly as possible rather than forcing the whole tree dynamic; the CSP *response* header itself is already set by the proxy per request and does not require the layout to be dynamic. Before/after this change, capture a TTFB baseline on a representative deploy (static-shell vs. per-request render) so the cost is measured rather than assumed.

#### Dynamic-render cost is incurred but the per-request nonce benefit is not realized

**Severity:** Low
**Location:** `app/layout.tsx:28-31`, `proxy.ts:41-47`
**Move:** Find the work that moved to the wrong place (cost paid for no realized benefit)
**Classification:** Micro (fixed per-request overhead) / Hot path (every request)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

The static-rendering opt-out exists to let a per-request nonce be embedded in the rendered HTML. Per fact-check Claims 2 and 9, that wiring is not actually enabled: the proxy sets the CSP on the *response* headers (not the *request* headers Next reads for nonce auto-tagging) and `x-nonce` is forwarded but never consumed by any layout/component, with no `<Script>`/`next/script` usages in the repo. From a performance lens, the app currently pays the per-request dynamic-render cost of Finding 1 without obtaining the nonce-per-request benefit that justifies it. This is primarily a correctness issue (owned by the fact-check / security review), noted here only because it changes the cost/benefit of Finding 1: today it is cost-only.

**Recommendation:** Either wire the nonce through (set the CSP string on the request headers so Next tags bootstrap scripts, and have the layout read `x-nonce`), which makes the dynamic-render cost purposeful, or drop `await headers()` if a static shell plus a per-request CSP response header is acceptable, which removes the cost entirely.

## What Looks Good

- **Proxy matcher scoping** (`proxy.ts:51-63`): excluding `api`, `_next/static`, `_next/image`, `favicon.ico`, and prefetch requests keeps the per-request proxy work off asset and prefetch paths — the right instinct to avoid burning proxy cycles (and nonces) on requests that never paint. Confirmed by fact-check Claim 10.
- **Nonce generation cost** (`proxy.ts:37`): `Buffer.from(crypto.randomUUID()).toString("base64")` plus one `new Headers(request.headers)` copy is O(1) constant per request with no allocation growth or I/O; not a performance concern even in the hot path.
- No database access, loops over collections, N+1 patterns, unbounded growth, or caching changes in this diff — the proxy is a fixed-cost, per-request header transform.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | App-wide static-rendering opt-out forfeits static generation / CDN caching | Medium | `app/layout.tsx:31` | Medium |
| 2 | Dynamic-render cost incurred without realized nonce benefit | Low | `app/layout.tsx:28-31`, `proxy.ts:41-47` | Medium |

## Overall Assessment

No blocking performance issues. The proxy itself is O(1) per request and well-scoped by its matcher. The one performance-relevant change is the root-layout static-rendering opt-out, which is app-wide and moves the initial-document render from build-time-static (CDN-cacheable) to per-request origin SSR for every navigation. Because the app is a single-page client SPA, the per-request server render is small and constant, so the impact is bounded — Medium, not High — but the loss of static-document CDN caching applies to 100% of page loads and its real magnitude is unmeasured. The most important thing to address is confirming the tradeoff is intentional and measuring TTFB before/after; secondarily, note that per fact-check the nonce benefit that justifies the dynamic cost is not currently wired up, so today the cost is paid for no realized gain. A TTFB/origin-CPU load comparison is needed to confirm the impact — nothing here can be quantified from code alone.
