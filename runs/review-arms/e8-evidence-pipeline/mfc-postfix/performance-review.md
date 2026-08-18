# Performance Review — mfc-postfix (evidence-query lifecycle, streaming-preview merge, `between` guard)

**Scope:** `git diff 9c9edf5...HEAD` — `app/api/evidence-search/route.ts`, `app/lib/utils/mergeStreamingPreview.ts` (consumed), `app/components/panels/BalancedPerspectivesPanel.tsx`, `app/lib/stores/evidenceStore.ts`, `proxy.ts`, `proxy.test.ts`
**Commit:** 7f30210
**Date:** 2026-08-18
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-postfix/code-fact-check-report.md` (k=2, commit 7f30210)

## Data Flow and Hot Paths

`POST /api/evidence-search` (`route.ts:142`) is the request handler — a **hot path** per invocation, though invoked interactively (a user clicks "Find evidence"), not at high frequency. Per request it: (1) resolves queries from a sanitized override (≤5, `querySanitize.ts:9`) or an LLM call yielding ≤3 (`route.ts:94`); (2) fans out one OpenAlex `fetch` per query in parallel via `Promise.allSettled` (`route.ts:167`), each with a 10 s abort timeout; (3) flattens results into `allWorks`, computes a relevance threshold via `Math.max(...allWorks.map(...))` (`route.ts:181`), filters, maps (`mapOpenAlexWork` + `reconstructAbstract` per work), dedups, and caps at `MAX_RESULTS = 8`. Under code-controlled inputs `allWorks` is bounded to 25 (override, 5×5) or 15 (LLM, 3×5) — fact-check Claim 6, Verified.

`mergeStreamingPreview` (`mergeStreamingPreview.ts:8`) runs once per panel render; during streaming the panel re-renders per parsed token. The `BalancedPerspectivesPanel` change adds one truthiness check (`t.between &&`) inside the per-tension `.map` render loop.

No baseline measurements exist in the repo or the fact-check report for this path; all findings below are flagged speculative accordingly.

## Findings

#### Argument-count safety of `Math.max(...allWorks.map(...))` rests on an external-service bound the fact-check could not establish

**Severity:** Low
**Location:** `app/api/evidence-search/route.ts:181`
**Move:** Ask "what's the size of N?" / Check the asymptotic behavior
**Classification:** Micro (spread argument count) / Hot path (per-request API handler)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

`Math.max(...allWorks.map((w) => w.relevance_score ?? 0), 1)` spreads one argument per element of `allWorks`. The fact-check (Claim 6, Verified) confirmed the **code-controlled** bound — `PER_QUERY_RESULTS = 5` is sent as `per_page` and the query count is capped — so `allWorks.length ≤ 25`, far under V8's spread/arg-count ceiling (tens of thousands, above which `Math.max(...arr)` throws `RangeError: Maximum call stack size exceeded`). But Claim 6's Scope **explicitly excludes** what OpenAlex actually returns: `searchOpenAlex` trusts `data.results` verbatim (`route.ts:126`, `return (data.results ?? []) as OpenAlexWork[]`) with no length clamp. If OpenAlex ignored `per_page`, the bound would be its documented `per_page` ceiling (200) → ~1000 args worst-case across 5 queries — still safe, but that 200 cap is an external contract, not something enforced here. The spread is therefore safe today, but its safety is inherited from an upstream service rather than guaranteed locally.

**Recommendation:** Replace the spread with an allocation-free single pass that has no argument-count dependency at all: `allWorks.reduce((m, w) => Math.max(m, w.relevance_score ?? 0), 1)`. This removes both the intermediate `.map` array and any coupling to how many results OpenAlex returns, at no readability cost.

#### Relevance stage makes three separate passes over `allWorks`

**Severity:** Informational
**Location:** `app/api/evidence-search/route.ts:181-186`
**Move:** Count the hidden multiplications
**Classification:** Micro (redundant passes over a small collection) / Hot path (per-request handler)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The relevance stage iterates `allWorks` three times: `.map(...)` for `Math.max`, `.filter(...)` for the threshold, then `.map(mapOpenAlexWork)` on the survivors. With `allWorks ≤ 25` this is trivially cheap and dominated entirely by the preceding network fetches (10 s timeout each), so it is not worth optimizing on its own — noted only because folding the `Math.max` into the reduce recommended above already removes one of the three passes for free.

**Recommendation:** None required for performance; if the `Math.max` reduce is adopted it collapses one pass incidentally. Do not restructure for its own sake — N is bounded and the stage is off the critical latency path (network-bound).

## Endorsements (evidence-gated)

- OpenAlex queries fan out concurrently via `Promise.allSettled(queries.map(searchOpenAlex))` rather than sequentially, so total wait is the slowest single query (≤10 s timeout) not the sum — the correct shape for independent I/O. `[read: route.ts:167-173]`
- The number of concurrent OpenAlex fetches is bounded (≤5 override / ≤3 LLM), so the fan-out cannot amplify into an unbounded outbound-request storm under code-controlled inputs. `[fact-check: claim 6 — Verified]`
- Evidence-store persistence coalesces rapid updates through a 300 ms debounced `setItem`, avoiding a `JSON.stringify` + `localStorage` write on every keystroke-scale update. `[fact-check: claim 7 — Verified]`
- `mergeStreamingPreview` selects between `finalData`/`streamingPreview` by reference (`finalData ?? streamingPreview ?? null`) and does no cloning or deep copy, so its per-render cost is O(1) plus the caller's `hasContent` predicate — the added `t.between &&` guard is a single truthiness check per tension per render. `[read: mergeStreamingPreview.ts:8-16]`

## Submitted claims (unverified — route to fact-check)

- **Claim:** OpenAlex honors the `per_page=5` request parameter and never returns more than its documented `per_page` ceiling (200) results in a single `data.results` array, so `allWorks.length` cannot exceed 1000 even if the requested `per_page` were disregarded. `[unverified — submitted as claim]` — this is the external-service assumption Claim 6's Scope explicitly left open; the `Math.max` spread's argument-count safety depends on it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `Math.max` spread bound inherited from external OpenAlex `per_page`, not enforced locally | Low | `route.ts:181` | Medium |
| 2 | Three passes over `allWorks` in the relevance stage | Informational | `route.ts:181-186` | High |

## Overall Assessment

The performance posture of this change is sound. The evidence-search path is network-bound (parallel fetches with 10 s timeouts dominate), the collections it processes are bounded to ≤25 elements under code-controlled inputs, and the streaming-merge / `between`-guard additions are O(1) per render with no cloning or allocation. There is no N+1, no unbounded growth, and no hot-path algorithmic problem. The single substantive observation is architectural rather than a live bug: the `Math.max(...allWorks.map(...))` spread's argument-count safety is inherited from OpenAlex honoring `per_page` — a boundary the fact-check verified only on the code-controlled side. Converting the spread to a `reduce` (Finding 1) removes that external coupling and one redundant pass in one edit, and is the only change worth making; no profiling is needed to justify it, and none of the findings should block shipping.
