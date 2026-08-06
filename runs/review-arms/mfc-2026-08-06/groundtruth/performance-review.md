# Performance Review — meta-formalism-copilot, HEAD~3..HEAD (post-review fix batch on integration/6.1)

Commit: 7f30210

**Scope:** `git diff HEAD~3..HEAD` in `/workspace/external/meta-formalism-copilot` — commits 4d5f743 (comment fixes), 2e23824 (CSP dev `'unsafe-eval'`), c0e0a35 (tension `between` crash guard + test), merge 7f30210. Files: `proxy.ts`, `proxy.test.ts`, `app/api/evidence-search/route.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx`, `app/components/panels/BalancedPerspectivesPanel.test.tsx`, `app/lib/stores/evidenceStore.ts`.
**Date:** 2026-08-06
**Based on:** merged code fact-check report (k=3, 0 Incorrect / 0 Stale) supplied with this task. Verified items used as foundation and not re-verified: the `route.ts:178-180` spread-bound comment (PER_QUERY_RESULTS=5; override path ≤5 queries → ≤25 spread args; LLM path ≤3 → ≤15; `data.results` is *not* defensively truncated at `route.ts:126`); the `evidenceStore` 300 ms trailing-debounce comment; `buildCsp` is called exactly once per request at `proxy.ts:53`.

**Measurement status for the whole review:** no profiler run, benchmark, load test, or production telemetry was available for this repository. Every finding below therefore carries the literal disclaimer rather than an invented number.

---

### Data Flow and Hot Paths

Three independent code paths are touched, at very different temperatures.

1. **`proxy.ts` — hot, per-request.** Next.js 16 Proxy (ex-Middleware). The matcher at `proxy.ts:74-82` applies it to every page navigation except `/api`, `_next/static`, `_next/image`, `favicon.ico`, and router prefetches. Per invocation the code generates a 128-bit nonce (`crypto.getRandomValues`, `proxy.ts:52`), calls `buildCsp(nonce)` once (`proxy.ts:53`), clones the request headers, and sets the CSP header on both request and response. `buildCsp` is the only function whose body this diff changed on a hot path. Expected frequency: one call per user-visible navigation — for a single-user local-first authoring tool this is single-digit calls per second at absolute worst; the work per call is pure string concatenation over a fixed 10-element array, no I/O.

2. **`app/api/evidence-search/route.ts` — warm, per-request but I/O-dominated.** `POST` validates the body, optionally makes one LLM call to generate queries (`generateSearchQueries`, `route.ts:164`), fans out `Promise.allSettled` over ≤5 OpenAlex `fetch` calls (`route.ts:167`), concatenates the results into `allWorks`, then does a `Math.max(...spread)` / `filter` / `map` / `deduplicate` / `slice` pipeline over that array (`route.ts:181-186`). Expected `N` (= `allWorks.length`) is ≤25 on the override path and ≤15 on the LLM path, per the fact-check. Wall-clock here is overwhelmingly the network: one LLM round trip plus up to 5 OpenAlex requests with an `OPENALEX_TIMEOUT_MS` abort guard (`route.ts:106`). **This diff changed only a comment in this file** (`route.ts:178-180`); no executable line moved.

3. **`BalancedPerspectivesPanel.tsx` — hot during generation, idle otherwise.** The panel re-renders on every partial-JSON streaming update while a Balanced Perspectives artifact is being generated (`streamingPreview` prop, merged via `mergeStreamingPreview` at line 25). Each render walks `displayMap.perspectives` and `displayMap.tensions`. Tension counts are LLM-authored and realistically single-digit (typically 2–6); streaming updates arrive at partial-JSON parse cadence, plausibly tens per generation. The changed lines add one truthiness check per tension per render (`BalancedPerspectivesPanel.tsx:113`).

4. **`evidenceStore.ts`, `proxy.test.ts`, `BalancedPerspectivesPanel.test.tsx` — cold.** A doc-comment edit and two test files. The store's actual debounce machinery (`evidenceStore.ts:20-41`, wired at `355-357`) is untouched by this diff.

Net: **the diff contains one behavioral change on a genuinely hot path (`buildCsp`), one behavioral change on a streaming-render path (the `between` guard), and three doc/test-only changes.** Nothing here adds I/O, a loop, a query, an allocation of unbounded size, or a lock.

---

### Findings

#### 1. The spread-bound comment now codifies a bound the code does not enforce

**Severity:** Medium
**Location:** `app/api/evidence-search/route.ts:178-181` (comment changed by this diff; the spread it describes is at line 181, unchanged)
**Move:** #9 — check asymptotic behavior, not just the constant (cliff vs. graceful degradation); secondary #2 — "what's the size of N?"
**Classification:** Macro (the failure mode is a hard `RangeError` cliff at a threshold, not a constant-factor slowdown) / Hot path — evidence: it sits inside the `POST` request handler at `route.ts:142`, executed once per evidence-search request.
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
>     // Safe to spread: allWorks holds at most PER_QUERY_RESULTS per query —
>     // worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25),
>     // fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit.
>     const topScore = Math.max(...allWorks.map((w) => w.relevance_score ?? 0), 1);
> ```
> and at `route.ts:126`:
> ```
>     return (data.results ?? []) as OpenAlexWork[];
> ```
**Legibility-target:** for-orchestrator-synthesis

The fact-check confirms the arithmetic is correct *given* that OpenAlex honors `per_page=PER_QUERY_RESULTS` (`route.ts:114`). The size of `N` is therefore not set by this codebase — it is set by a third-party API response that is cast to `OpenAlexWork[]` and pushed into `allWorks` without truncation (`route.ts:126`, `route.ts:171`). The scaling factor that matters is `queries × results_per_query`; the code pins the first factor (≤5) and *trusts* the second. If OpenAlex ever ignores `per_page`, changes its default, or returns a large page under a future API version, `Math.max(...)` spreads an unbounded array into an argument list and throws `RangeError: Maximum call stack size exceeded` — a hard 500 on every evidence search, not a gradual slowdown. My concern is specifically that this commit *strengthened* the comment's assurance ("Well under the arg-count limit") without adding the one line that would make it true by construction. I am rating this Medium rather than High because the upstream contract almost certainly holds today and this commit changed no executable code; it would become High if `PER_QUERY_RESULTS` or `MAX_OVERRIDE_QUERIES` were ever raised, or if a second results source were merged into `allWorks`.

**Recommendation:** Either truncate defensively at the boundary — `return ((data.results ?? []) as OpenAlexWork[]).slice(0, PER_QUERY_RESULTS)` at `route.ts:126` — or replace the spread with an allocation-free reduce (`allWorks.reduce((m, w) => Math.max(m, w.relevance_score ?? 0), 1)`), which removes the cliff entirely and lets the comment shrink to a single line about relevance filtering.

#### 2. `buildCsp` rebuilds a fully constant 10-directive array and re-joins it on every page navigation

**Severity:** Low
**Location:** `proxy.ts:26-47` (signature and `scriptSrc` construction changed by this diff), called at `proxy.ts:53`
**Move:** #3 — find the work that moved to the wrong place (init → hot path); secondary #1 — count the hidden multiplications
**Classification:** Micro (a fixed ~10 short string concatenations plus one array allocation and one `join`, no I/O, no allocation that scales with any input) / Hot path — evidence: `proxy.ts:53` runs inside `proxy()`, which the matcher at `proxy.ts:74-82` applies to every non-prefetch page navigation; the fact-check confirms one call per request.
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
>   const scriptSrc = `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${
>     allowUnsafeEval ? " 'unsafe-eval'" : ""
>   }`;
>   const directives = [
>     "default-src 'self'",
>     scriptSrc,
> ```
> and at `proxy.ts:53`:
> ```
>   const csp = buildCsp(nonce);
> ```
**Legibility-target:** for-author

Every request allocates a 10-element array of string literals, one interpolated `scriptSrc`, and one joined result, when the only value that varies across requests is the 24-character base64 nonce. The multiplication factor is *requests × 10 constant strings*. This is a pre-existing shape that the diff extends by one conditional interpolation rather than introduces, and the absolute cost is nanoseconds against a request that is already doing `crypto.getRandomValues` and a full `Headers` clone (`proxy.ts:59`), so it is nowhere near worth a rewrite on its own. I note it because the change makes the hoisting opportunity newly obvious: with `allowUnsafeEval` resolved once at module load, the entire CSP reduces to two constant halves around the nonce.

**Recommendation:** If this ever shows up in a middleware latency profile, hoist a module-scope `` const CSP_PREFIX = `default-src 'self'; script-src 'self' 'nonce-` `` / `CSP_SUFFIX` pair and make `buildCsp` a two-part concat, keeping the exported signature for the tests. Do not do this speculatively — it trades the readable directive list for a measurement nobody has taken.

#### 3. `process.env.NODE_ENV` is read once per request via the new default parameter

**Severity:** Low
**Location:** `proxy.ts:28`
**Move:** #3 — work that moved to the wrong place (a constant that could be resolved at module init is resolved per call)
**Classification:** Micro (one property read on a host object, no allocation, no I/O) / Hot path — evidence: default parameters are evaluated at call time, and `proxy.ts:53` calls `buildCsp(nonce)` without the second argument on every matched navigation.
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
>   allowUnsafeEval: boolean = process.env.NODE_ENV !== "production",
> ```
**Legibility-target:** for-author

`process.env` access in Node is a trap into the host environment object rather than a plain property load, and it is a well-known (if small) hot-loop smell; here it is multiplied by one per request. The value is immutable for the process lifetime, so the read is pure repeated work. The design choice itself is good — putting the env check in a default parameter is exactly what made `proxy.test.ts` able to pin both modes explicitly (`buildCsp(NONCE, false)` at `proxy.test.ts:10`, `buildCsp(NONCE, true)` at line 37) instead of mutating ambient `NODE_ENV`, which is a real testability and determinism win. Only the evaluation site is per-request.

**Recommendation:** Hoist to `const ALLOW_UNSAFE_EVAL = process.env.NODE_ENV !== "production";` at module scope and use it as the default (`allowUnsafeEval: boolean = ALLOW_UNSAFE_EVAL`). This preserves the injectable-parameter testing pattern exactly while making the env read once-per-process.

#### 4. Tension list is index-keyed, so streaming updates re-reconcile the whole list

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:110-111` (adjacent to, but not changed by, this diff)
**Move:** #1 — count the hidden multiplications (renders × list length)
**Classification:** Micro (a handful of DOM nodes per tension over a single-digit list) / Hot path during generation — evidence: the component consumes `streamingPreview` (`BalancedPerspectivesPanel.tsx:13, 25-28`) and therefore re-renders on each partial-JSON update.
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
>                 {displayMap.tensions?.map((t, i) => (
>                   <EditableSection key={i} value={t} onChange={(newT) => updateArrayItem("tensions", i, newT)}>
> ```
**Legibility-target:** for-author

Using the array index as the React key means every streaming update that appends or reshapes a tension re-uses the same keys for different content, so React updates in place rather than matching identities; combined with the inline `onChange` closure allocated per item per render, each streaming tick does work proportional to the full tension list rather than the delta. At realistic sizes (2–6 tensions, tens of updates per generation) this is invisible — a few hundred cheap reconciliations across an entire generation. It is worth recording only because the new `t.between &&` guard sits inside this exact block, so a future author touching it should know the reconciliation shape. Unlike `perspectives` above (`key={p.id}`, line 70), tensions have no stable identifier in the type, so this is not a trivial fix.

**Recommendation:** Leave as is. If tension lists ever grow past ~50 or the panel shows visible jank during streaming, key on a content-derived stable string rather than the index, and hoist the `onChange` closure with `useCallback`.

#### 5. The `between` guard adds a negligible per-tension check and removes error-boundary churn

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`
**Move:** #1 — count the hidden multiplications (renders × tensions × one truthiness test); secondary #3 in reverse (expensive work removed from a hot path)
**Classification:** Micro (one truthiness test and one conditional subtree) / Hot path during generation — evidence: same streaming-render path as finding 4.
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
>                       {t.between && (
>                         <div className="flex items-center gap-1 text-xs font-mono text-red-700">
>                           <span>{t.between[0]}</span>
> ```
**Legibility-target:** for-author

The added cost is one truthiness check per tension per render — unmeasurable. The performance-relevant direction is the opposite one: before this change, a partially-streamed tension made `t.between[0]` throw a `TypeError` mid-render, which in React means the thrown render is discarded, the nearest error boundary unmounts the subtree, and (in development) the render is retried. That is a comparatively expensive event on a path that fires on every streaming tick, and it recurred for as long as the incomplete tension stayed in the preview. Replacing a per-update throw/unmount cycle with a skipped `<div>` is a strict improvement in both correctness and streaming-render cost.

**Recommendation:** No action. If the endpoints should render as they arrive, `t.between?.[0]` with the wrapper always present would be marginally more incremental, but the current form is clearer and the difference is not measurable.

#### 6. `evidenceStore` comment change is doc-only; the debounce shape it now describes is sound

**Severity:** Informational
**Location:** `app/lib/stores/evidenceStore.ts:8-9` (changed), describing `evidenceStore.ts:20-41` and `355-357` (unchanged)
**Move:** #4 — trace the memory lifecycle; #8 — question the cache (here, the write-coalescing buffer)
**Classification:** Micro (a comment; zero runtime effect) / Cold path — evidence: module-level doc comment, no executable change in this file in this diff.
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
>  * Persists to localStorage with debounced writes (see the debounced storage
>  * adapter below) to avoid excessive serialization on rapid updates.
> ```
**Legibility-target:** for-orchestrator-synthesis

The fact-check verifies the 300 ms trailing debounce this comment now points at. Reading the adapter for lifecycle safety: the single `pending` handle is cleared on both re-entry (`evidenceStore.ts:25`) and `removeItem` (`evidenceStore.ts:36-37`), the adapter instance is hoisted so `persist` never creates a second timer (`evidenceStore.ts:43-48`), and `partialize` (`evidenceStore.ts:359-361`) keeps transient loading maps out of the serialized payload — so there is no timer leak, no unbounded retained buffer, and no serialization of state that changes on every request. One structural note for the future: a single module-scope `pending` means one timer for all keys, which is correct only because exactly one store name (`"evidence-store-v1"`) uses this adapter; a second consumer would silently drop the first one's write. That is a latent correctness issue, not a current performance one.

**Recommendation:** No action. If a second store ever shares `createDebouncedStorage`, key `pending` by `name` rather than closing over a single handle.

#### 7. New RTL render tests add a small, bounded cost to the test suite

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:1-56`, `proxy.test.ts:30-46`
**Move:** #1 — count the hidden multiplications (CI runs × test count)
**Classification:** Micro (two jsdom renders and one extra pure-function assertion block) / Cold path — evidence: test-only files, executed by the runner, never by the application.
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
> // Mock child components to isolate panel logic
> vi.mock('@/app/components/features/output-editing/EditableSection', () => ({
> ```
**Legibility-target:** for-orchestrator-synthesis

The panel test mocks `EditableSection` and `ArtifactPanelShell` rather than rendering the real subtree, which keeps each case to a shallow jsdom render — the cheap way to write this. The new `proxy.test.ts` case calls `buildCsp` twice more and does a regex `match` over a short string. Suite-time impact is on the order of a couple of milliseconds. Recorded only for completeness in a ground-truth run.

**Recommendation:** No action.

#### 8. The evidence pipeline makes three separate passes over `allWorks`, plus a `map` allocation feeding `Math.max`

**Severity:** Informational
**Location:** `app/api/evidence-search/route.ts:181-186` (unchanged code; in scope only because this diff rewrote the comment that documents its bounds)
**Move:** #1 — count the hidden multiplications; #2 — what's the size of N?
**Classification:** Micro (three passes over ≤25 elements, one throwaway `number[]` allocation) / Hot path — evidence: inside the `POST` handler, `route.ts:142`.
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
>     const topScore = Math.max(...allWorks.map((w) => w.relevance_score ?? 0), 1);
>     const relevanceThreshold = topScore * 0.4;
>     const relevantWorks = allWorks.filter(
>       (w) => (w.relevance_score ?? 0) >= relevanceThreshold,
>     );
>     const papers = deduplicatePapers(relevantWorks.map(mapOpenAlexWork)).slice(0, MAX_RESULTS);
> ```
**Legibility-target:** for-author

`map` (allocating a `number[]` purely to feed the spread) → `filter` → `map` → `deduplicate` → `slice` is O(5N) over N ≤ 25, against a request that has already spent one LLM round trip plus up to five OpenAlex fetches with an abort timeout (`route.ts:106`, `route.ts:167`). The CPU here is rounding error next to the network. Fusing the passes would be a pure readability loss. The one substantive change worth making in this block is the reduce suggested in finding 1, which happens to remove the throwaway allocation as a side effect.

**Recommendation:** No action beyond finding 1's reduce.

---

### What Looks Good

- **The change with the largest performance effect in this diff is a removal of work, not an addition.** The `between` guard converts a per-streaming-tick `TypeError` + error-boundary unmount into a skipped subtree (finding 5). Crash guards on streaming render paths are usually filed as correctness fixes; this one is also the diff's best latency change.
- **Nothing was added to a hot path that scales.** No new loop, query, fetch, regex compilation, JSON round trip, lock, cache, or retained allocation appears anywhere in the diff. The `buildCsp` change is one conditional string interpolation; the panel change is one truthiness test; the remaining three files are comments and tests.
- **The dev/prod split is genuinely free in production.** `'unsafe-eval'` affects only script evaluation policy, and only when `NODE_ENV !== "production"`; the production CSP string is byte-identical to before, so there is no production parser or header-size change (`proxy.ts:30-32`). Header size grows by 13 bytes in dev only.
- **Parameterizing rather than reading ambient env inside the function** is the right structure for a hot path, and it let the tests pin both branches deterministically (`proxy.test.ts:10, 37`) rather than mutating `process.env` — which would have been both slower and order-dependent. Only the evaluation site needs hoisting (finding 3).
- **The evidence-search fan-out is already correctly shaped** for its cost profile: `Promise.allSettled` parallelizes the OpenAlex calls (`route.ts:167`) instead of awaiting them serially, each carries an `AbortController` timeout (`route.ts:105-106`), and failures degrade to `[]` rather than failing the request (`route.ts:122, 134`). This diff left that intact.
- **The debounced persistence adapter is leak-free** — timer cleared on re-entry and removal, single hoisted instance, transient state excluded via `partialize` (finding 6).
- **The comment rewrites make the perf-relevant invariants auditable.** Both edited comments now name the mechanism (`PER_QUERY_RESULTS` per query; "the debounced storage adapter below") rather than gesturing at a sibling module, which is what let finding 1 be stated precisely instead of guessed at.

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Spread-bound comment codifies a bound the code doesn't enforce (`Math.max(...)` cliff if OpenAlex ignores `per_page`) | Medium | `app/api/evidence-search/route.ts:178-181` | Medium |
| 2 | `buildCsp` rebuilds a constant 10-directive array + join per navigation | Low | `proxy.ts:26-47` (called `proxy.ts:53`) | High |
| 3 | `process.env.NODE_ENV` read per request via default parameter | Low | `proxy.ts:28` | High |
| 4 | Index-keyed tension list re-reconciles fully on each streaming update | Informational | `app/components/panels/BalancedPerspectivesPanel.tsx:110-111` | Medium |
| 5 | `between` guard: negligible added check, removes per-tick throw/unmount churn (net positive) | Informational | `app/components/panels/BalancedPerspectivesPanel.tsx:113-119` | High |
| 6 | `evidenceStore` comment doc-only; debounce adapter leak-free, single-consumer caveat | Informational | `app/lib/stores/evidenceStore.ts:8-9, 20-41` | High |
| 7 | New RTL/CSP tests add bounded suite cost | Informational | `BalancedPerspectivesPanel.test.tsx:1-56`, `proxy.test.ts:30-46` | High |
| 8 | Three passes over `allWorks` + throwaway `map` allocation, N ≤ 25, network-dominated | Informational | `app/api/evidence-search/route.ts:181-186` | High |

---

### Overall Assessment

**This is a low-risk diff from a performance standpoint, and the honest summary is that there is nothing here to escalate.** Three of the five changed source files are comment or test edits with zero runtime effect. Of the two behavioral changes, one (`buildCsp`) adds a single conditional string interpolation to a per-navigation path whose cost is already dominated by nonce generation and a `Headers` clone, and the other (the `between` guard) *removes* a recurring exception-and-unmount cycle from a streaming render path. If you shipped this unchanged, no user would observe a latency difference in production.

The one finding worth an author's attention is **finding 1**, and it is a robustness cliff rather than a slowdown. This commit strengthened a comment's claim that a spread is "well under the arg-count limit" while the array being spread is populated straight from a third-party API response with no defensive truncation (`route.ts:126`). The arithmetic is correct today — the fact-check confirms it — but it is correct *because OpenAlex honors `per_page`*, not because the code makes it so, and the failure mode if that ever changes is a hard `RangeError` 500 on every evidence search rather than a gradual degradation. A one-line `.slice()` at the fetch boundary, or swapping the spread for a `reduce`, converts a trusted external invariant into an enforced local one. I rate it Medium rather than High specifically because the diff changed no executable code there and the upstream contract is very likely stable; it becomes a High the moment `PER_QUERY_RESULTS` or `MAX_OVERRIDE_QUERIES` is raised or a second results source is merged into `allWorks`.

Findings 2 and 3 are the two `proxy.ts` micro-items. Both are real (constant work repeated per request) and both are almost certainly not worth acting on today — I would take finding 3's one-line module-scope hoist because it costs nothing and preserves the testing pattern exactly, and leave finding 2 alone until someone has a middleware latency number to point at. That is the main caveat on this review: **no measurement was available for any path here.** Every severity above is reasoned from code structure and stated bounds, with the speculative disclaimer attached, and the sizes of `N` throughout (≤25 OpenAlex works, single-digit tensions, one CSP build per navigation) are small enough that structural reasoning is the appropriate tool — none of these would repay a profiling session.

---

## Goal-Alignment Note
- Answered: yes — full performance review of HEAD~3..HEAD, all findings down to Informational
- Out of scope: the doc-precision items the fact-check flagged as Mostly-accurate (leftover parity comment `evidenceStore.ts:17`, the "optional chaining" mischaracterization, the "development only" `NODE_ENV` fail-open) are security/API-consistency territory, not performance, and are left to those critics; the single-`pending`-timer limitation noted in finding 6 is a latent correctness concern, flagged but not scored on the performance matrix
- Escalate: nothing — finding 1 is the only item warranting an author fix, and it is a preventive one-liner, not a blocker
