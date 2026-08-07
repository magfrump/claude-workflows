# Performance Review — e3-loops arm1 (verification pass, critic stage)

Commit: 1eb081e
Range reviewed: `git diff d86d2dc..HEAD` (HEAD = 1eb081e559d4a19276ae397b7096544db83ef29e, branch e3/csp-arm1)
Worktree: /workspace/runs/review-arms/e3-loops/wt-csp-arm1
Reviewer: performance-reviewer skill
Merge standard: 0R + 0A

## Verdict up front

**0 Red. Nothing Critical or High exists in this range.** All per-request work in
the CSP proxy hot path is sub-microsecond and either unavoidable given the
per-request-nonce design or a deliberate, self-documented security tradeoff.

Two items carry into this pass and one resolves:

- **F1 (CARRIED, Medium):** the force-dynamic SSR render per navigation (`await headers()` in `layout.tsx`). Behavior is **unchanged** from the full-2 state; only the comment was corrected (it no longer claims the cost is "nil"). Previously waived; still advisory.
- **F2 (NEW, Low):** removing the `missing:` prefetch exclusion from the proxy matcher means prefetch navigations now run nonce generation + `buildCsp` where they were previously skipped. Deliberate security choice; ~0.75 µs/prefetch by the code's own estimate.
- **F3 (RESOLVED):** the prior full-2 finding "x-nonce dead per-request work" is fixed — the `requestHeaders.set("x-nonce", nonce)` write is **deleted**. Confirmed gone (see below).

### x-nonce deletion — confirmation

The per-request `requestHeaders.set("x-nonce", nonce)` write is gone from
`proxy.ts`. `git grep x-nonce 1eb081e` returns only (a) a comment in `proxy.ts`
stating the header is intentionally absent, (b) a comment in `layout.tsx`, and
(c) a `proxy.test.ts` case that asserts the header is `null`. No live write
remains. The dead per-request work the full-2 review flagged is eliminated.

---

## Findings

### F1 — Layout opted out of static rendering; one SSR shell render per navigation

- **Status:** CARRIED (from full-2; previously waived)
- **Severity / RAG:** Medium / Amber (advisory)
- **Classification:** Feature-inherent cost (design constraint of per-request nonces), not a defect.
- **Move:** Hot-path unnecessary-work scan → determined the work is *necessary*, not unnecessary.
- **Location:** `app/layout.tsx`, `await headers();` in `RootLayout` (now `async`).
- **What / why:** `await headers()` opts the root layout out of static rendering
  so `proxy.ts` runs per request and a fresh nonce reaches every rendered
  document. Per-request nonces and a cached prerender are mutually exclusive by
  construction — a prerendered document is built once and would carry a stale
  (or absent) nonce that the CSP blocks on every subsequent request. The cost is
  one SSR shell render per navigation instead of a cached/CDN-served prerender.
- **Change in 1eb081e:** runtime behavior is **identical** to the parent commit.
  The 1eb081e diff only rewrites the explanatory comment — the prior comment
  claimed "The cost here is nil"; the new comment correctly states the cost is
  one SSR shell render per navigation and loss of shared/CDN cacheability. This
  is a truthfulness improvement in the documentation, not a new runtime cost.
- **Baseline:** no baseline available — flagged as speculative. The code's own
  comment concedes the two numbers that would size it are unmeasured: the build
  output's static/dynamic marker and one TTFB sample.
- **Evidence (verbatim, `app/layout.tsx`):**
  > Per-request nonces and static rendering are mutually
  > exclusive by construction. The cost is one SSR shell render per navigation
  > instead of a cached prerender, and the document is no longer shared- or
  > CDN-cacheable; accepted because nonces require it, and small here because
  > the app is a single "use client" route with no generateStaticParams,
  > revalidate, or ISR. (Unmeasured: the two numbers that would size it are the
  > build output's static/dynamic marker and one TTFB sample.)
- **Legibility-target:** for the next reader deciding whether this is worth
  measuring: capture the static/dynamic marker from `next build` output and one
  TTFB sample against a warm prerender baseline. Until then this stays a known,
  accepted feature cost, not a regression introduced by this range.

### F2 — Prefetch navigations now run the proxy (matcher `missing:` exclusion removed)

- **Status:** NEW in 1eb081e
- **Severity / RAG:** Low / Amber (advisory)
- **Classification:** Deliberate security-vs-cost tradeoff (added work is intentional coverage, not accidental).
- **Move:** Hot-path frequency scan → which requests now enter the proxy that previously did not.
- **Location:** `proxy.ts`, `config.matcher` — the `missing: [next-router-prefetch, purpose=prefetch]` block was deleted.
- **What / why:** Previously, prefetch requests (carrying `next-router-prefetch`
  or `purpose: prefetch` headers) were excluded from the matcher and skipped the
  proxy entirely, saving one nonce generation + `buildCsp` call each. Those
  requests now run the full proxy body. The tradeoff is deliberate and correct
  on the merits: the old exclusion made CSP coverage a function of a
  client-supplied request header, so any caller setting those headers could
  fetch a rendered document with no CSP, no nonce, and no `frame-ancestors`.
  Closing that hole costs the nonce work on prefetches.
- **Per-request cost added:** `Buffer.from(crypto.randomUUID()).toString("base64")`
  plus a 9-element array `join` per prefetch. Both sub-microsecond; no I/O, no
  allocation of note, no loop over collections.
- **Baseline:** ~0.75 µs of nonce generation per prefetch — source: the
  `proxy.ts` comment (in-code estimate, not independently measured here). No
  measured production prefetch-rate baseline available — flagged as speculative
  for aggregate impact.
- **Evidence (verbatim, `proxy.ts`):**
  > Deliberately no `missing:` prefetch exclusion: every exclusion here must be
  > server-determined, or CSP coverage becomes a function of a client-supplied
  > request header. Skipping on `purpose: prefetch` / `next-router-prefetch`
  > saved ~0.75 µs of nonce generation and let any caller that sets those
  > headers receive a rendered document with no CSP, no nonce, and no
  > frame-ancestors.
- **Legibility-target:** a reader should read this as "security bought at ~0.75 µs
  of CPU per prefetch request, no I/O" — negligible under any realistic load, and
  not a scaling bottleneck (cost is O(1) per request, no shared contention).

### F3 — x-nonce dead per-request work (prior full-2 finding)

- **Status:** RESOLVED in 1eb081e
- **Severity / RAG:** Green (was the full-2 advisory item; now fixed)
- **Location:** `proxy.ts` — deleted `requestHeaders.set("x-nonce", nonce)`.
- **What:** The prior review flagged the per-request `x-nonce` header write as
  dead work (no reader consumed it). It is now removed; per-request work in the
  proxy is strictly reduced by one `Headers.set` call. A regression test
  (`proxy.test.ts` "publishes no x-nonce header") locks the absence in.
- **Baseline:** N/A (removal of work; no measurement needed).
- **Evidence (verbatim, `proxy.ts`):**
  > No `x-nonce` header: the conventional seam for server components rendering
  > their own <Script> tags had no readers, and a published-but-unread header
  > reads as live plumbing.

---

## What Looks Good

- **Policy construction is pure and cheap.** `buildCsp` builds a fixed 9-element
  string array and joins it — O(1), no allocation growth with input, no
  branching beyond one env comparison. Making `nodeEnv` a required parameter
  (1eb081e) is a purity/testability win with zero runtime cost; the env read
  moved to the single production call site, not duplicated per invocation.
- **Nonce generation is the minimum viable work.** `crypto.randomUUID()` +
  `Buffer` base64 are Node core, no external calls, sub-µs. There is no cheaper
  way to satisfy a per-request unique nonce.
- **Export path change is a genuine perf improvement (from earlier in range).**
  `exportGraph.ts` moved from `toPng` + `fetch(dataUrl)` (base64 encode →
  data-URL round-trip → re-fetch → blob) to `toBlob` (canvas → `canvas.toBlob()`
  in-DOM). This removes a base64 encode/decode round-trip on each graph export.
  In 1eb081e this file saw only comment + test additions, so it is not a NEW
  finding, but it is a net reduction in work on the export click path and worth
  noting as healthy.
- **Matcher still excludes API and static-asset routes**, so the proxy does not
  run on `_next/static`, `_next/image`, `favicon.ico`, or `api/*` — the
  high-frequency asset paths stay off the hot path.

## Summary Table

| ID | Finding | Severity / RAG | Status | Baseline |
|----|---------|----------------|--------|----------|
| F1 | Force-dynamic SSR render per navigation (`await headers()`) | Medium / Amber | CARRIED (waived; behavior unchanged, comment corrected) | Speculative — unmeasured (static/dynamic marker + TTFB) |
| F2 | Prefetch requests now run proxy nonce gen (matcher `missing:` removed) | Low / Amber | NEW | ~0.75 µs/prefetch (in-code estimate) |
| F3 | x-nonce dead per-request write | Green | RESOLVED (deleted; confirmed) | N/A |

## Overall Assessment

No Critical or High performance issue exists in `d86d2dc..HEAD`. The CSP proxy
is a per-request hot path, and every unit of work in it is either unavoidable
under the per-request-nonce design (nonce mint, policy build, header set) or a
deliberate, sub-microsecond security tradeoff (F2). The one prior dead-work
finding (x-nonce) is resolved and regression-guarded. The force-dynamic cost
(F1) is carried forward unchanged and was previously waived; 1eb081e only made
its documentation honest. Against a 0R+0A merge standard, there is 0 Red; the
two Amber items are advisory and both are deliberate, documented design costs
rather than defects.

## Goal-Alignment Note

The stated goal is a strict per-request-nonce CSP. Every performance cost in
this range is in direct service of that goal: the force-dynamic render (F1) is
what makes per-request nonces reach the document at all, and the removed
prefetch exclusion (F2) is what makes CSP coverage independent of a
client-supplied header. Optimizing either away would weaken the security
property the change exists to provide. The performance profile is therefore
aligned with the goal — the costs are the goal's price, not overhead to trim.
The only goal-neutral cost (x-nonce dead work) has already been removed.
