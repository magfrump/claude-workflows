⚠️ **No code fact-check report provided.** Performance claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# Performance Review: subject.ts

**Scope:** `subject.ts` (explicit scope, whole file)
**Date:** 2026-11-19

## Data Flow and Hot Paths

`updateOpeningHours` is an Express handler for `PUT /api/stores/:id/opening-hours`. It reads `req.body.shifts` and rejects anything that isn't an array or has more than `MAX_SHIFTS = 21` entries. It then:

1. Groups shifts by weekday: 7 × `filter` over the whole array, then a `sort` within each day.
2. Checks for overlapping shifts with a nested pairwise loop within each day.
3. Builds a per-day `openHours` total.

It makes no database, network or file calls, and keeps no state between requests.

**Path temperature:** hot in form, because it runs once per request. In practice it is probably low-frequency, since store owners edit opening hours rarely. That is an assumption; I found no traffic data.

**Data size:** N ≤ 21, enforced at line 17 before any per-shift work runs. Worst case:
- Grouping: 7 × 21 = 147 predicate calls.
- Sorting: at most 21 elements.
- Overlap check: if all 21 shifts fall on one day, C(21,2) = 210 comparisons.

Every step is bounded by a small constant. The only unbounded input is the raw request body, which Express's JSON body parser handles before this code runs. Its size limit is configured outside this file and is not reviewed here.

## Findings

#### Overlap check is pairwise when an adjacent-pair check is enough after sorting

**Severity:** Informational
**Location:** `subject.ts:27-35`
**Move:** Check the asymptotic behavior (9) / What's the size of N? (2)
**Classification:** Micro (bounded constant work, because N ≤ 21) / Hot path (per-request handler, likely low frequency)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

Each day's shifts are sorted by `startHour`, so comparing each shift with the next one is enough. The reasoning: if `j > i+1` and `s[j].start < s[i].end`, then `s[i+1].start ≤ s[j].start < s[i].end`, so the adjacent pair already overlaps. The current `j` loop is O(k²) per day where O(k) would do. Because `MAX_SHIFTS` caps k at 21, the worst case is 210 comparisons against at most 20, a difference of microseconds. This is not a real performance problem today. It only matters if someone raises or removes `MAX_SHIFTS` without revisiting this loop.

**Recommendation:** Optional. If the cap may grow, replace the inner loop with a check of `dayShifts[i+1].startHour < dayShifts[i].endHour`. Otherwise leave it as is.

## Endorsements

- The length cap (`shifts.length > MAX_SHIFTS`) is checked before any `filter`, `sort`, or nested-loop work. This bounds every later step of the handler at N ≤ 21. [read: subject.ts:16-40]
- The handler does no I/O (no DB, cache or network calls), so it has no N+1 risk, no contention, and no resource-lifecycle concerns. [read: subject.ts:1-43]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Pairwise overlap check; adjacent-pair check is enough after sorting | Informational | `subject.ts:27-35` | High |

## Overall Assessment

This handler has no performance problems. All of its work is capped by `MAX_SHIFTS = 21`, which is enforced before any processing, so even the quadratic overlap loop stays at a few hundred comparisons. It does no I/O, has no shared state and allocates almost nothing. The one finding only matters if the cap is raised. No profiling is needed.

**Outside this file:**
- **Body-size limit:** the Express JSON body-parser limit decides how large a payload gets parsed before line 17 runs. Check it where the app is set up.
- **Persistence:** the handler doesn't save the shifts. If saving is added later, review that code path separately.
