Commit: d90d6bb

# Performance Review — meta-formalism-copilot CSP proxy (d86d2dc..d90d6bb)

**Scope:** `git diff d86d2dc..d90d6bb` (3 commits; `proxy.ts` new, `app/layout.tsx` modified)
**Date:** 2026-11-19
**Based on:** Stage-1 merged code-fact-check report (`runs/review-arms/a8-2026-11-20/csp/code-fact-check-report.md`, k=3; Claims 2, 3, 11, 13, 14 used below)

## Data Flow and Hot Paths

The app has exactly one page route, `app/page.tsx`, a `"use client"` component that imports about 20 panel components and hooks (lines 1-37). Every other route under `app/` is an API route (`app/api/**/route.ts`), and the new matcher excludes those. Before this change the root layout read no request data, so Next could prerender `/` at build time and serve it as a static file (from the CDN on Vercel). The change adds two pieces of per-request work:

1. **`proxy.ts`** runs on every request the matcher lets through. Per fact-check Claim 11 it runs on the Node.js runtime, not Edge. Each run generates a UUID, base64-encodes it, copies the request headers, adds `x-nonce`, builds a 9-directive string and sets one response header. The cost is constant per request (no loops, no I/O). Requests it sees: navigations to `/`, non-prefetch RSC requests, and any `public/` file (Claim 14).
2. **`app/layout.tsx:31`** calls `await headers()`. That makes the root layout, and so the whole route tree, dynamically rendered. `/` is now server-rendered on every request instead of being served prerendered.

Both are on the hot path: every page load of the only page in the app. Traffic is unknown: there are no measurements in the repo. `docs/` and `documentation/` contain no latency or throughput numbers for page serving.

## Findings

#### Root layout opt-out removes static prerendering of the only page; every load now runs SSR

**Severity:** Medium
**Location:** `app/layout.tsx:27-31`
**Move:** Find the work that moved to the wrong place; Price the deployment environment
**Classification:** Macro (structural: a build-time render and a CDN-cacheable response became one server render per request) / Hot path (every navigation to `/`)
**Confidence:** Medium
**Legibility-target:** for-author
**Baseline:** no baseline available — flagged as speculative

**Evidence** (`app/layout.tsx:27-31`; excerpt ends :31; the enclosing `RootLayout` continues to :42, where it returns the `<html>/<body>` shell around `children` and reads nothing else from the request — read):
```tsx
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();
```

Before the change, `/` was a static prerender: one render at build time, then file or CDN serving with no server compute per view. Now each page view server-renders the full client component tree (`app/page.tsx` and its ~20 imported panels) into HTML before the first byte goes out. On Vercel, the deploy target the 9b4e453 commit body names, each view also becomes a billed function invocation instead of a CDN hit, and cold starts add to TTFB. Per-request nonces cannot coexist with a cached HTML response, so some version of this cost comes with the chosen design. That is the reason this is Medium and not the matrix default of High. But nothing in the change records that the cost was weighed. The comment also gives the wrong reason (Claim 2, Incorrect 3/3: the proxy runs whether or not the page is static). There is a further risk. Per Claim 3 (contested: r1 and r3 say Next never receives the nonce because CSP is set only on the response; r2 says the self-hosted router copies it over; Vercel is unconfirmed), if the nonce does not reach Next's renderer on the deployed platform, the app pays the full dynamic-rendering cost and gets a CSP that blocks its own bootstrap scripts.

**Recommendation:** Decide on purpose whether nonce CSP is worth losing static serving for this page. Hash-based CSP or Next's experimental SRI support could keep `/` static. If nonces stay, take a TTFB and invocation-count baseline on the Vercel preview before and after merging. Correct the comment so it names the real reason: the HTML must carry the per-request nonce.

#### Matcher still routes `public/` files and non-prefetch RSC requests through the proxy

**Severity:** Informational
**Location:** `proxy.ts:55-63`
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed per-request proxy overhead) / Hot path (any matched request)
**Confidence:** Medium
**Legibility-target:** for-author
**Baseline:** no baseline available — flagged as speculative

**Evidence** (`proxy.ts:55-63`; excerpt ends :63; the enclosing `config` object closes at :64 — read):
```ts
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

The lookahead excludes only `api*`, `_next/static`, `_next/image` and `favicon.ico`, so requests for files in `public/` also run the proxy (Claim 14, Mostly accurate). That includes the five `public/*.svg` files and any future `robots.txt`, `sitemap.xml` or images. Each such request gets a nonce, a header copy and a CSP header it does not need. On Vercel each one is also a proxy invocation where there was none before. Today none of the `public/*.svg` files is referenced from `app/` (rg finds no references), and the app has one page, so the multiplier is close to 1 and the impact is small. It grows as static assets are added to `public/`.

**Recommendation:** Add a file-extension exclusion to the lookahead (for example `.*\\.(?:svg|png|jpg|ico|txt|xml)$`), following the matcher pattern in the Next CSP guide, so static files skip the proxy.

#### `x-nonce` request-header copy is per-request work with no consumer

**Severity:** Informational
**Location:** `proxy.ts:41-46`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (one Headers clone plus one set per request) / Hot path
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** no baseline available — flagged as speculative

**Evidence** (`proxy.ts:41-46`; excerpt ends :46; the enclosing `proxy()` continues to :49, setting the response CSP header and returning — read):
```ts
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
```

Per Claim 13 (Mostly accurate), nothing reads `x-nonce`: the layout does not, and there is no `<Script>` in `app/`. Cloning the headers is a small constant cost per request, which is negligible as performance. The useful point is a correctness one: this is the same request-header copy that, per E1 and Claim 3, should also carry the `Content-Security-Policy` header so Next can find the nonce. The performance cost is already being paid, so adding CSP to `requestHeaders` costs nothing extra and may fix the larger problem.

**Recommendation:** Keep the copy, and also set `Content-Security-Policy` on `requestHeaders`, as the Next guide does. Otherwise drop `x-nonce` if nothing will read it.

## Endorsements (evidence-gated)

- The proxy does a constant amount of work per request, with no loops, I/O, network calls or state kept between requests. Its added cost per request is dominated by `crypto.randomUUID()` and a Headers clone, not by anything that scales with data. `[unverified — submitted as claim]`
- The `missing` conditions on `next-router-prefetch` and `purpose: prefetch` stop the proxy from running on router prefetches, so prefetches add no proxy invocations. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Root layout opt-out removes static prerendering of `/`; per-request SSR and function invocation on every view | Medium | `app/layout.tsx:27-31` | Medium |
| 2 | Matcher runs proxy on `public/` files and non-prefetch RSC requests | Informational | `proxy.ts:55-63` | Medium |
| 3 | `x-nonce` request-header copy has no consumer (and is where CSP should also go) | Informational | `proxy.ts:41-46` | High |

## Overall Assessment

The proxy itself is cheap: a constant amount of work per request, no I/O, no growth. The one real performance cost is structural and comes with the design. `await headers()` turns the app's only page from a static, CDN-served file into a server render on every view. It can be fixed in place: accept it on purpose and measure it, or move to a hash- or SRI-based CSP that keeps `/` static. The bigger risk is the cost/benefit pairing. If the fact-check's Claim 3 concern holds on Vercel, the app pays dynamic rendering on every view for a CSP that does not work. So the first thing to do is confirm on the Vercel preview that bootstrap scripts carry the nonce and run, and record TTFB and invocation counts before and after. No finding here rests on a measurement; all of them need profiling or preview metrics to size.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the performance-reviewer skill.
- Answered: yes
- Out of scope: Security effect of the CSP directives (E2-E5: connect-src export breakage, worker-src, unsafe-eval, matcher anchoring as a security gap) belongs to security-reviewer; test coverage (E6) belongs to test-strategy. No `next build` or runtime measurement was possible (no node_modules, no network).
- Escalate: (1) Confirm on the Vercel preview that the nonce reaches Next's renderer (Claim 3 / E1); if it does not, Finding 1's cost buys a broken page. Route to security-reviewer / architecture-review as already addressed. (2) Owner decision on whether losing static prerendering of `/` is acceptable versus a hash- or SRI-based CSP; capture a TTFB and invocation baseline either way.
- Decisions I made: Downgraded Finding 1 from the Macro×Hot default (High) to Medium because per-request nonces force dynamic rendering by design and the app has a single page with no evidence of high traffic. Rated the matcher finding Informational because the `public/` SVGs are currently unreferenced.
