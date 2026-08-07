Commit: 7f30210

# Performance Review — postfix (git diff 9c9edf5..7f30210)

**Scope:** `app/api/evidence-search/route.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx` (+test), `app/lib/stores/evidenceStore.ts`, `proxy.ts` (+test)
**Date:** 2026-08-06
**Based on:** code fact-check report at `/workspace/runs/review-arms/baseline-2026-08-06/postfix/fact-check.md` (9 claims: 7 verified, 2 unverifiable)

## Data Flow and Hot Paths

The changeset is a post-review-fix pass. Its substantive code changes are:

1. `route.ts` — **comment only** (rewords the safety rationale for the `Math.max(...allWorks.map(...))` spread). No executable change.
2. `BalancedPerspectivesPanel.tsx` — wraps the `t.between[0]/[1]` render in a `t.between &&` guard. React render path, per-tension in a `.map`. N = tensions per artifact (single-digit, LLM-generated).
3. `evidenceStore.ts` — **comment only** (rewords the debounce docstring). The debounced adapter itself is unchanged.
4. `proxy.ts` — `buildCsp` gains an `allowUnsafeEval` parameter (default `NODE_ENV !== "production"`) and hoists `scriptSrc` into a local. Runs once per proxied request.
5. Two test files (cold path — not shipped).

I read the current (7f30210) evidence-search spread/bounds path (`route.ts:167-186`) and the debounced-persistence path (`evidenceStore.ts:20-48`) per the Stage-1 (021) requirement. Both are unchanged by this diff except for comments; the bounds the comment describes are real (`PER_QUERY_RESULTS=5`, override capped at `MAX_OVERRIDE_QUERIES=5`, LLM path `.slice(0,3)` — fact-check Claim 1, verified), so `allWorks` is bounded to ≤25 elements and the spread into `Math.max` is safe. No performance regression, and no pre-existing performance issue in these paths worth flagging.

## Findings

No performance findings at Medium or above. The diff introduces no new loops, allocations, queries, serialization boundaries, caches, or contention points; it does not move work between cold and hot paths. Two Informational notes follow for completeness.

#### Per-request CSP string reassembly is unchanged in cost

**Severity:** Informational
**Location:** `proxy.ts:26-35`
**Move:** Find the work that moved to the wrong place (#3)
**Classification:** Micro (string template construction) / Hot path (per-request proxy)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`buildCsp` runs once per proxied request and builds the CSP via string interpolation. The refactor hoists `scriptSrc` into its own template literal and adds one boolean check on `allowUnsafeEval`, but the total string work is essentially identical to before (same directives, one extra conditional concatenation). This is negligible constant-factor work relative to the network I/O of a proxied request; noted only to confirm the refactor did not relocate expensive work into the hot path. Not actionable.

#### `t.between` guard adds a trivial truthiness check in the tension render loop

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-120`
**Move:** Count the hidden multiplications (#1)
**Classification:** Micro (one truthiness check) / Cold-ish (React render, single-digit N)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The added `t.between &&` guard executes once per tension inside `displayMap.tensions?.map(...)`. N is the number of tensions in an LLM-generated balanced-perspectives artifact (single digits). The guard is a correctness fix (prevents a TypeError crash on partial-stream data, fact-check Claim 6) and its per-item cost is a single truthiness test — immeasurable at this scale. Not actionable.

## What Looks Good

- **Evidence-search spread is correctly bounded.** `allWorks` is provably ≤25 elements (fact-check Claim 1), so `Math.max(...allWorks.map(...))` (`route.ts:181`) cannot hit the argument-count/stack limit. The reworded comment now states the actual bound accurately.
- **Parallel OpenAlex fan-out with `Promise.allSettled`** (`route.ts:167`) — bounded query count, each with a 10s abort timeout (`route.ts:106`); failures degrade to empty results rather than blocking. Sound under load.
- **Debounced localStorage writes** (`evidenceStore.ts:20-48`) — 300ms debounce collapses rapid updates into one serialization + write, avoiding per-keystroke `JSON.stringify` of the store. Correct pattern for a persist path; unchanged by this diff.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Per-request CSP string reassembly unchanged in cost | Informational | `proxy.ts:26-35` | High |
| 2 | `t.between` guard adds trivial check in render loop | Informational | `BalancedPerspectivesPanel.tsx:113-120` | High |

## Overall Assessment

The performance posture is unchanged by this diff. The two `route.ts`/`evidenceStore.ts` edits are comment rewrites over unchanged (and correctly bounded / correctly debounced) hot paths; the `proxy.ts` change adds a cheap parameter and a hoisted local with no relocation of expensive work; the panel change is a per-item truthiness guard fixing a crash. Nothing here introduces algorithmic, N+1, allocation, serialization, or contention problems, and nothing warrants a benchmark. No blocking or High-severity issues. Ship from a performance standpoint.
