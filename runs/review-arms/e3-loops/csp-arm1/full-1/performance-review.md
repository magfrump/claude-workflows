# Performance Review — Strict CSP (proxy + dynamic root layout)

**Commit:** e5d95a9
**Range:** `d86d2dc..HEAD` (4 commits: 9b4e453, b25e939, d90d6bb, e5d95a9)
**Worktree:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (branch `e3/csp-arm1`)
**Files in scope:** `app/layout.tsx` (+18/-1), `proxy.ts` (new, +71)
**Foundation:** merged fact-check (k=3) taken as given — not re-verified.

## Path-temperature calibration (applies to every finding below)

Two facts about temperature that bound every severity in this report:

- **Positionally hot:** `proxy()` runs on *every* non-excluded navigation and `RootLayout` now runs on every document request (fact-check: verified). Nothing here is behind a feature flag or a rare branch.
- **Low absolute volume:** this app is documented as a locally-run single-user tool — `README.md:56` and `CLAUDE.md:19` both point the operator at `http://localhost:3000`, and there is no deployment manifest, CDN config, or `output` setting in `next.config.ts`. N (requests/sec) is ~1 human's click rate.

So "hot" here means *unconditionally on the request path*, not *high-throughput*. Per the hot-path gate, that evidence supports Medium but does **not** support Critical/High: no finding below multiplies against a large N today. Where a finding would escalate under a different deployment, I say so explicitly rather than pricing it in now.

**There is no measured baseline anywhere in this repo** — no benchmark, no `next build` output committed, no timing harness. Every finding is therefore marked speculative on its Baseline line, and no finding below claims a measured millisecond number.

---

## Findings

#### F1 — `await headers()` moves the app's only route from build-time prerender to per-request SSR, and makes the document uncacheable by any shared cache

**Severity:** Medium
**Location:** `app/layout.tsx:41` (`await headers();`), interacting with `proxy.ts:44` (`response.headers.set("Content-Security-Policy", buildCsp(nonce))`)
**Move:** Work moved to the wrong place (build time → request time) + cache invalidation (a per-request-varying response header destroys shared cacheability)
**Classification:** Macro / Hot (positionally — every document request; see calibration)
**Confidence:** High on the mechanism; Medium on the magnitude (unmeasured)
**Baseline:** no baseline available — flagged as speculative
**Evidence:**

```tsx
  // exclusive by construction. The cost here is nil — the app is a single
  // "use client" route with no generateStaticParams, revalidate, or ISR — so
  // there is nothing static to lose. Revisit only if we drop nonces in favour
  // of hashes, which would let prerendered output keep a stable CSP.
  await headers();
```

**Legibility-target:** a reader of `app/layout.tsx` should be able to see *what* the dynamic opt-out costs, so that a future deployment decision (put this behind a CDN? serve it to more than one user?) is made with the cost visible rather than reconstructed.

The **decision** here is correct and I am not asking for it to be reversed. Per-request nonces and prerendered HTML are mutually exclusive: a document built once carries one nonce, the proxy mints a new one per response, and every request after the first would have its bootstrap scripts blocked. Reverting the opt-out breaks the feature. The waiver stands.

What does not hold is the *cost accounting* in the comment. Two corrections:

1. **`"use client"` does not exempt a route from static prerendering.** Next prerenders a client-component page to HTML at build time by default; the directive controls hydration and bundling, not prerender eligibility. The thing lost is not `generateStaticParams`/ISR (correctly noted absent) — it is the **full route cache entry for `/`**. Before this change the document was built once and served from cache; now every document request runs a server render of `RootLayout` → `page.tsx` (807 lines) → the panel tree it imports (`GraphPanel` 303 lines, `CausalGraphPanel` 175, `OutputPanel` 166, `NodeDetailPanel` 163, plus ~10 more panels). The scaling factor is not per-user-action but **per document navigation: one cached-file read → one full React server render of a ~2500-line component tree.** On localhost with one user that is a cold-start-shaped cost paid on refresh, which is why this is Medium and not High.
2. **The nonce also defeats *downstream* caching, not just Next's.** `Content-Security-Policy` varies per response, so the `/` document can never be served from a CDN edge, a reverse proxy, or a browser bfcache-adjacent shared cache. Today there is no CDN, so this is latent. It is the same root cause as (1), which is why it is folded in here rather than double-counted.

**Recommendation:** Keep the mechanism. Fix the comment: replace "The cost here is nil — the app is a single `"use client"` route" with the accurate statement — *"the cost is that `/` moves from the full route cache to per-request SSR; acceptable because this is a single-user localhost tool with one route. Re-price this if the app is ever served to multiple users or placed behind a CDN."* Keep the existing hash-based-CSP escape hatch note; it is the right revisit trigger and should be linked to the deployment condition, not left as a standalone aside.

---

#### F2 — Dead per-request work: the whole request-header set is cloned and re-serialized to forward an `x-nonce` nobody reads

**Severity:** Low-Medium
**Location:** `proxy.ts:38-43`
**Move:** Unnecessary work in a hot path (dead data-flow kept alive) + per-request allocation with no consumer
**Classification:** Micro / Hot
**Confidence:** High that the work is dead (fact-check: `x-nonce` forwarded but never read); Medium on the size of the constant factor (depends on a Next internal, see below)
**Baseline:** no baseline available — flagged as speculative
**Evidence:**

```ts
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
```

**Legibility-target:** the proxy should contain only the work that actually produces the CSP. A reader should not have to trace `x-nonce` through the app to discover it has no consumer — and the comment above it actively asserts a consumer ("so layouts can read it") that does not exist.

Cost has two layers. The visible one is `new Headers(request.headers)` — an O(H) copy per request where H is the incoming header count (a real browser navigation with cookies is roughly 15-25 headers). The less visible one: passing `request.headers` to `NextResponse.next()` is not free bookkeeping — Next implements request-header overrides by encoding them onto the *response* as an `x-middleware-request-*` entry per header plus an `x-middleware-override-headers` manifest listing them, which the server then decodes. So the scaling factor is roughly **H header allocations and ~H extra internal response headers per navigation, to deliver a value with zero readers.** I mark the confidence on that second layer Medium because it rests on a Next internal rather than on code in this diff; even if that encoding differs in 16.2.4, the `Headers` clone alone is unambiguously dead.

Note this is *also* the load-bearing half of F1's premise: the layout comment correctly says it does not need to read `x-nonce`, which is precisely why the forwarding should go.

**Recommendation:** Delete the clone and the `request` option — `const response = NextResponse.next();` — and delete the now-false comment. If a future `<Script nonce>` needs the value, reintroduce the forwarding *with* its consumer in the same change. This is a 4-line deletion with no behavior change.

---

#### F3 — `buildCsp` reconstructs 8 constant directives and re-reads `process.env.NODE_ENV` on every request

**Severity:** Low
**Location:** `proxy.ts:24-38` (`buildCsp`)
**Move:** Hidden multiplication — a constant computed per call instead of per process
**Classification:** Micro / Hot
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**

```ts
function buildCsp(nonce: string): string {
  const devOnly =
    process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : "";
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${devOnly}`,
```

**Legibility-target:** the shape of the code should say which part of the policy is fixed and which part varies per request. Today all nine directives look equally dynamic, which is why the `NODE_ENV` read drifted into the per-request path in e5d95a9 without anyone flagging it.

Exactly one of nine directives depends on the argument. Per request the function allocates a 9-element array, one template string, and a joined ~230-character result, and performs a `process.env` lookup — which in the Edge runtime is a proxied object access, not a plain property read, and whose value cannot change after process start. The scaling factor is **9 string allocations + 1 array + 1 env proxy hit per navigation where 2 concatenations and 0 env hits would do.** At localhost volume this is genuinely negligible; it earns Low rather than Informational only because it sits unconditionally on the request path and the fix is smaller than the finding.

**Recommendation:** Hoist to module scope: compute `const CSP_PREFIX = "default-src 'self'; script-src 'self' 'nonce-"` and `const CSP_SUFFIX = \`' 'strict-dynamic'${DEV_ONLY}; style-src ...\`` once, with `const DEV_ONLY = process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : "";` evaluated at module load. `buildCsp` becomes `CSP_PREFIX + nonce + CSP_SUFFIX`. This also makes the fixed/variable split self-documenting. If the array-of-directives form is preferred for readability, keep it but hoist `DEV_ONLY` at minimum.

---

#### F4 — Matcher admits every non-`/api`, non-`_next/static` path, so future non-document assets will pay full nonce cost

**Severity:** Informational
**Location:** `proxy.ts:59-70` (`config.matcher`)
**Move:** Work applied at the wrong granularity (per-path filter broader than the set of responses that can use the result)
**Classification:** Micro / Cold (the admitted paths are not exercised today — see below)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**

```ts
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

**Legibility-target:** the matcher's comment claims "page navigations only"; the pattern implements "everything except three prefixes." A reader should be able to tell which one is true without enumerating the filesystem.

The exclusion list covers `/api`, `/_next/static`, `/_next/image`, and `/favicon.ico`. It does **not** cover `public/` assets, `/robots.txt`, `/sitemap.xml`, or `/manifest.json`. Each such request would mint a UUID, base64 it, clone the header set (F2), build a CSP string (F3), and attach a `Content-Security-Policy` header to a response that has no scripts to govern. I classify this Cold because I checked: the five files in `public/` (`file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg`) are Next scaffolding leftovers with **zero references anywhere under `app/`**, and none of the other listed paths exist. So the over-broad set is currently empty of traffic — the finding is about the trap, not a live cost.

The scaling factor if that changes: **one wasted nonce generation + header clone + CSP build per static asset request**, which for an image-heavy page is per-asset rather than per-navigation — i.e. it multiplies by assets-per-page rather than staying at 1. That is the escalation path from Informational to Low-Medium, and it triggers silently the first time someone drops a logo in `public/`.

**Recommendation:** Either narrow the pattern to also exclude file-extension paths (append a `\\..*` guard, e.g. `/((?!api|_next/static|_next/image|.*\\.[a-z0-9]+$).*)`) or, more cheaply, correct the comment to state the actual rule ("everything except API routes, Next build assets, and the favicon — including anything added to `public/`") so the next person adding an asset sees the cost. Given current traffic, the comment fix alone is a defensible close.

---

## What Looks Good

- **Prefetch exclusion is a real and well-reasoned optimization.** The `missing` clause on `next-router-prefetch` / `purpose: prefetch` keeps the proxy off speculative requests. The comment's justification ("would otherwise burn a nonce on a request that may never paint") is the correct reason, and it is the one place in this diff where per-request cost was explicitly designed against.
- **`/api` is excluded from the matcher.** API routes are where this app's actual latency lives (Anthropic/OpenAlex/OpenRouter calls per `proxy.ts:17-18`); adding even a microsecond of proxy work to those paths would have been the one genuinely load-bearing mistake available here, and it was avoided.
- **The `'unsafe-eval'` carve-out is gated, not blanket.** Whatever its cost as a per-call env read (F3), scoping it to `NODE_ENV === "development"` means the production policy string is unchanged in length and content — no production-path regression from the e5d95a9 fix.
- **No N+1, no unbounded growth, no unbounded memory.** There is no loop, no collection traversal, no cache, no retained state, and no allocation whose size depends on user data anywhere in the diff. Everything above is a bounded per-request constant. That is worth stating explicitly: the asymptotic profile of this change is flat.
- **`crypto.randomUUID()` is the right primitive.** It is a native CSPRNG call, not a JS-level random-string builder, and the `Buffer.from(...).toString("base64")` wrapper is one 36→48-byte transform. No cheaper correct option is worth chasing.

## Summary Table

| ID | Finding | Severity | Class | Temp | Confidence |
|----|---------|----------|-------|------|------------|
| F1 | `await headers()` trades the `/` full-route-cache entry for per-request SSR of a ~2500-line tree; also defeats shared HTTP caching. Mechanism is load-bearing; the comment's "cost is nil" is the defect. | Medium | Macro | Hot | High (mechanism) / Medium (magnitude) |
| F2 | Request headers cloned and re-serialized per request to forward an `x-nonce` with no reader. | Low-Medium | Micro | Hot | High (dead) / Medium (constant factor) |
| F3 | `buildCsp` rebuilds 8 constant directives + re-reads `NODE_ENV` per request. | Low | Micro | Hot | High |
| F4 | Matcher admits `public/` assets and top-level files; empty of traffic today, silently costly later. | Informational | Micro | Cold | High |

## Overall Assessment

This diff is performance-clean in the way that matters most: **it introduces no new asymptotics.** Nothing loops, nothing accumulates, nothing scales with user data or collection size. Every cost identified is a bounded per-request constant, and the one structural change (F1) is mandatory for the feature to be correct at all.

The gap between this review and the lite loop's is narrow and specific. The lite loop flagged the dynamic-rendering opt-out and waived it; I agree with the waiver and am not reopening it. What I do not agree with is the sentence the waiver left in the code — "The cost here is nil ... there is no static to lose" — which rests on treating `"use client"` as if it excluded a route from prerendering. It does not. The cost is real (full route cache → per-request render) and merely *small in this deployment*, which is a different claim with a different revisit trigger. Encoding "nil" rather than "small, because localhost, one user, one route" is what makes this Medium instead of Informational: the next person to consider putting this behind a CDN will read the comment and conclude there is nothing to reconsider.

F2 is the one I would actually fix before merge, because it is a pure deletion that removes work *and* removes a comment asserting a consumer that does not exist — the cheapest legibility-per-line in the diff. F3 and F4 are comment-or-hoist changes that can ride along or wait.

No blocking performance issue. Recommend merge after the F1 comment correction and the F2 deletion.

## Goal-Alignment Note

- **Answered:** Whether the CSP proxy and the dynamic-rendering opt-out introduce performance problems on the request path, at what scaling factor, and with what severity given this app's actual deployment shape. Four findings, all bounded-constant or structural-but-mandatory; none blocking.
- **Out of scope:** Security adequacy of the policy itself (`'unsafe-inline'` for styles, `'strict-dynamic'` semantics, the `(?!api...)` prefix-match admitting `/apifoo`) — that is the security critic's call, and I raise the regex only as a perf-breadth matter in F4. Correctness of the dev-mode `'unsafe-eval'` fix. Whether the waiver decision in e5d95a9 was procedurally correct. Re-verification of any fact-check finding.
- **Escalate:** (1) The `"use client"` ⇒ not-prerendered premise appears in both the commit message and the source comment for e5d95a9 and is inaccurate; the *conclusion* (waive) survives, but if any downstream artifact reuses that premise to justify a different decision, it should be re-derived. (2) F1 and F4 both change severity under a non-localhost deployment; if this app is ever intended to be served to multiple users or fronted by a CDN, this review should be re-run against that assumption rather than trusted as-is.
