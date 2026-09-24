# Performance Reviewer — Evaluation Criteria

Hand-written fixtures, one planted defect each, drawn from the problem classes
`skills/performance-reviewer/SKILL.md` targets (N+1, accidental quadratic work,
unbounded growth, missing pagination, contention). Two clean negatives test the
hot-path gate and the "what's the size of N?" move against false positives.

## Fixture → Expected Finding Map

| Fixture | Defect | Expected Severity | Must Mention |
|---|---|---|---|
| tc-perf1-orm-n-plus-one.py | Django view: `order.customer`, `order.items.count()`, `order.shipping_method` per row of a 50-order page | High | N+1, `select_related` / `prefetch_related` / `annotate` |
| tc-perf2-quadratic-merge.ts | `findIndex` over the merged list inside the loop over an uploaded, unbounded contact list | Critical or High | quadratic / O(n·m), index by email in a `Map`/`Set` |
| tc-perf3-unbounded-cache.go | Handler-owned map keyed by user-typed address, never evicted | Critical or High | unbounded growth, eviction / LRU / TTL / size cap |
| tc-perf4-missing-pagination.py | Audit-events endpoint returns the org's whole history, no `LIMIT` | High or Critical | pagination, `LIMIT` / cursor / keyset |
| tc-perf5-lock-across-io.go | Service-wide mutex held across the upstream HTTP call | High or Critical | contention / serialization, move I/O outside the lock |
| tc-perf6-startup-config-scan.py | Clean: pairwise plugin scan, once at worker start | none above Medium | cold / startup path |
| tc-perf7-bounded-schedule.ts | Clean: nested loops in a handler, input capped at `MAX_SHIFTS = 21` × 7 days | none above Medium | the bound (`MAX_SHIFTS`, 21, bounded) |

## Notes

- **Why two tiers are allowed.** SKILL.md's severity list puts "O(n²) in hot path"
  and "unbounded resource consumption" at Critical and "N+1 / missing pagination"
  at High, while its calibration matrix anchors Macro × Hot at High and escalates
  to Critical "when unbounded / DoS-enabling". tc-perf2–5 are all unbounded hot-path
  macro problems, so either tier follows the rubric. tc-perf1 is pinned to High:
  the page size is fixed at 50, so the N+1 is bounded and the escalation doesn't apply.
- **Clean negatives** forbid Critical and High only. A Low or Informational note
  (e.g. "verify manifest size") is consistent with the rubric's Macro × Cold → Low
  and is not a false positive. Medium is also tolerated to keep the check about
  the hot-path gate rather than phrasing.
- **cites_pattern** alternations match the mechanism *or* the fix, so any correct
  report passes regardless of wording. Patterns must not contain `;` (the
  KEY_CHECK separator).
- **format_check** runs `performance-reviewer-format.bats` on tc-perf1 (a finding
  report) and tc-perf7 (likely a `No findings.` report), covering both shapes.
- Fixtures contain no comments naming or hinting at the defect; comments only
  state call frequency or data provenance, which SKILL.md tells the reviewer to
  establish anyway.
