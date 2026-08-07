# Performance Review — e3/csp-arm2 (verification pass, critic stage)

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm2`
**Commit:** ab4dbdb
**Date:** 2026-08-06
**Based on:** `code-fact-check-report.md` (same verify/ directory)
**Merge standard:** 0R + 0A. This pass confirms 0 red and surfaces any NEW amber introduced by ab4dbdb.

The prior full-3 performance review already dispositioned this feature: the `force-dynamic`
High is an ACKED accepted feature cost (A9) and is **not re-raised as red** here; the decode
cost (~5 ms/MiB) and per-request proxy cost (~2.67 µs/req) were measured and settled. Those
are carried, not re-litigated. This pass focuses on whether ab4dbdb's changes (matcher
anchoring + prefetch-clause deletion, `form-action` addition, `x-nonce` write deletion,
`dataUrlToBlob` file move) introduce any NEW performance concern.

## Data Flow and Hot Paths

- **`proxy.ts`** — Hot path. Runs once per matched request (all page navigations, prefetched
  documents, `public/` assets, 404s; excludes `/api`, `_next/static`, `_next/image`,
  `/favicon.ico`). Per invocation it generates a nonce (`crypto.randomUUID()` → `Buffer`
  base64), builds an ~11-directive CSP string via array `join`, clones request headers, and
  sets two headers. Settled baseline ~2.67 µs/req.
- **`app/layout.tsx`** — `export const dynamic = "force-dynamic"`. Opts the whole subtree out
  of static generation / PPR, so every route renders per request. This is the nonce control's
  layout half. Accepted feature cost (ACKED A9).
- **`app/lib/utils/dataUrl.ts` (`dataUrlToBlob`)** — Cold path (user-initiated graph PNG
  export, infrequent). Synchronous `atob` + per-byte loop over the decoded string; settled
  ~5 ms/MiB. Base64 image payloads for a viewport PNG are on the order of a few MiB at most.
- **`app/lib/utils/exportGraph.ts`** — Cold path. Two call sites swapped `await fetch(dataUrl)`
  + `await res.blob()` for the synchronous `dataUrlToBlob(dataUrl)`. Behavior byte-identical
  (confirmed by `dataUrl.test.ts`).

## Findings

#### Prefetch documents now run the proxy (nonce generation) per prefetch

**Severity:** Low
**Location:** `proxy.ts:78-92` (matcher), behavioral change vs. the deleted prefetch-skip clause
**Move:** Find the work that moved to the wrong place (more precisely: work that now runs on a path it previously skipped)
**Classification:** Micro (fixed ~2.67 µs cost per invocation) / Hot path (per-request proxy)
**Confidence:** High
**Baseline:** ~2.67 µs/req proxy cost, measured and settled in the prior full-3 review

ab4dbdb deletes the request-header-conditioned skip so prefetched documents now receive the
CSP (a correctness fix — a prefetched, paintable document otherwise ships bootstrap scripts
with no nonce). The performance consequence is that the per-request nonce generation now also
runs for prefetch requests, of which Next can issue several per page (one per in-viewport
link). At ~2.67 µs each this is negligible relative to rendering a `force-dynamic` document,
and the extra requests were always going to be rendered anyway — the proxy work is a rounding
error on top. Flagged only for completeness; not amber.

**Recommendation:** None. The added coverage is required for the nonce to hold on prefetched
documents; the marginal cost is immaterial. No action before merge.

#### Anchored matcher regex — negligible constant-factor change

**Severity:** Informational
**Location:** `proxy.ts:89-91`
**Move:** Check the asymptotic behavior, not just the constant
**Classification:** Micro (one regex evaluation) / Hot path (Next router, per request)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The matcher gained anchors (`api(?:/|$)`, `favicon\.ico$`) to stop exclusions swallowing
sibling routes (`/apidocs`, `/favicon.ico.map`). This is a single negative-lookahead regex
compiled once by Next and evaluated per request in the router; the added alternation/anchors
do not change its complexity class and the constant-factor difference is unmeasurable against
per-request render cost. Correctness-motivated, perf-neutral.

**Recommendation:** None.

#### `form-action` directive adds one constant string per CSP build

**Severity:** Informational
**Location:** `proxy.ts:32-35`
**Move:** Identify the serialization tax (CSP string assembly)
**Classification:** Micro (one array element + join) / Hot path (per request)
**Confidence:** High
**Baseline:** ~2.67 µs/req proxy cost (settled); the added element is a sub-nanosecond fraction of it

One more constant directive in the `buildCsp` array. The `join` cost scales with directive
count but 11 vs 10 directives is immaterial. Perf-neutral.

**Recommendation:** None.

## What Looks Good

- **`x-nonce` per-request header write deleted** (`proxy.ts:63-67`): removes one `Headers.set`
  per request that had no consumer under `app/`. A small, correct reduction of per-request work
  on the hot path. Net positive.
- **`fetch(dataUrl)` → synchronous `dataUrlToBlob`** (`exportGraph.ts:24,36`): eliminates an
  async round-trip through the fetch stack (and the `connect-src` widening it would have forced)
  for a purely in-process base64 decode. Fewer microtasks, no network-layer involvement, and
  the CSP `connect-src` stays tight. Behavior is byte-identical per `dataUrl.test.ts`.
- **`dataUrlToBlob` extracted to its own module** (`app/lib/utils/dataUrl.ts`): the file move is
  byte-identical in behavior but preserves the code-split boundary — a second consumer can use
  the codec without importing `exportGraph.ts` and dragging `html-to-image` into its chunk. Good
  for bundle hygiene; documented in the module docblock.
- **`dataUrlToBlob` decode loop**: standard `atob` + `Uint8Array` per-byte copy, O(n) in payload
  size, cold path, settled at ~5 ms/MiB. Appropriate for the export use case; no materialization
  of intermediate arrays beyond the single output buffer.

## Summary Table

| # | Finding | Severity | Location | Confidence | NEW/CARRIED |
|---|---------|----------|----------|------------|-------------|
| — | `force-dynamic` renders whole subtree per request (accepted feature cost, ACKED A9) | High | `app/layout.tsx:33` | High | CARRIED (ACKED — not red) |
| 1 | Prefetch documents now run the proxy per prefetch | Low | `proxy.ts:78-92` | High | NEW |
| 2 | Anchored matcher regex — negligible constant-factor change | Informational | `proxy.ts:89-91` | High | NEW |
| 3 | `form-action` adds one constant string per CSP build | Informational | `proxy.ts:32-35` | High | NEW |

## Overall Assessment

Clean. There are **0 Critical and 0 new High** findings. The only High in the scope is the
`force-dynamic` render cost, which is an ACKED accepted feature cost (A9) carried from the
prior full-3 review and explicitly not re-raised as red. ab4dbdb's changes are comment and
small-code refactors that are performance-neutral-to-positive: the `x-nonce` deletion and the
`fetch`→`dataUrlToBlob` swap each remove per-invocation work, and the `dataUrlToBlob` file move
preserves a code-split boundary. The one behavioral change with any hot-path footprint —
prefetch requests now running the proxy — costs ~2.67 µs/req against documents that were being
rendered regardless, and is required for nonce correctness. **No NEW amber (Medium) or red.**
No profiling or new benchmarking is needed; all impacted paths have settled baselines.

## Goal-Alignment Note

Under the 0R+0A merge standard, this arm passes the performance critic: 0 red confirmed, and
ab4dbdb introduces no new amber. The `force-dynamic` High remains the sole High and is honored
as an accepted feature cost per the historical rule — it is not a blocker and is not re-raised.
Recommendation: **merge-clear** on performance grounds.
