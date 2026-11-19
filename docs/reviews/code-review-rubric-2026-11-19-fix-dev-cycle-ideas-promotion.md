Commit: d15211a8

# Code Review Rubric

**Scope:** fix/dev-cycle-ideas-promotion vs main at 610130f5 (full branch) | **Reviewed:** 2026-11-19 | **Status: 🟡 IN PROGRESS** — iteration 1 found 0 red, 2 amber, 4 green; fixes in the next commit, re-review pending

Iteration 1: one fresh reviewer, single pass (k=1 loop pass), no sub-critic panel (the reviewer read the 5-file diff itself, ran the 16 section-5 bats cases, `migrations.sh check`, the digest on the real roadmap and a hermetic probe repo). Override log: row 170 (section 5 reads `questions.sh open`'s columns, Won't-Fix) touches the reused holds path, unchanged here; no other override matched.

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|

None.

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | "parked" or "dropped" anywhere in an Idea, its signal prose included ("the hook dropped events"), printed "says parked or dropped", which step 6 leaves in Ideas: the failure the change exists to stop (`scripts/dev-cycle.sh:521`, probe executed). | Correctness | Medium | reviewer | for-author | none | Fixed: only the item's head, its text before the first `Signal:`, is read for parked or dropped; step 5 keeps the words out of that head unless an owner answer applies; test case "Drop guard" lists as unheld | |
| A2 | The brief's Status line is still `open`. | Process | Low | reviewer | for-author | none | Fixed in the branch's final change, as the brief asks | |

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | Any `F-NNN` matches, whatever its namespace ("review finding F-1"); the cost is a spurious move or ask, not a miss. | reviewer | Won't-Fix: errs toward asking; step 5 now names the entry's ID shape |
| C2 | The header's shape list omitted "owner's request/report", which the awk accepts. | reviewer | Fixed: the header lists both |
| C3 | The first run moves about 12 Ideas to Now at once. | reviewer | Won't-Fix: one-time, recorded on the `6.` line; step 8's slots pace the briefs (research doc) |
| C4 | No test had parked or dropped inside signal prose. | reviewer | Fixed with A1 |

## ⏭️ Skipped Core Critics

- security-reviewer, performance-reviewer, api-consistency-reviewer as separate dispatches: the iteration-1 reviewer covered the diff in one pass (small digest/doc change, no trust boundary beyond the reused 0x1f and ID checks).

## 🧩 Composition check

A1 and C4 share a root (the parked match too broad, no test pinning it); one fix.
