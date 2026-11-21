Commit: 34f24441
# Code Review Rubric

**Scope:** fix/cycle-diff-record-prefix, adf18cd0..34f24441 (6894f9fc, 06b81d73, 2468119c, 34f24441) | **Reviewed:** 2026-11-20 | **Status: 🟢 PASSES.** 0 red items; 1 amber item, fixed.

Two review passes, each by a fresh-context reviewer given the code, not the author's conclusions:
- Pass 1 (whole diff): `record_kept` and `RECORD_AWK` edge cases under mawk 1.3.4 (no heading, no trailing newline, CRLF, empty side, inserted heading, grep -b offsets), and a replay of the rule over every cycle-record land on main (277 judgements).
- Pass 2 (2468119c, the pass-1 fix): the in-order matching with Paths landed additions (an exchange argument plus probes: repeated lines, mid-section adds, two or no Paths landed headings, adds in Roadmap diff).

The design record is docs/working/research-2026-11-20-cycle-diff-record-prefix.md. `scripts/health-check.sh` passes at 34f24441 (2143 ok, 0 not ok).

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|---|
| A1 | **Step 10's land, done as the skill says, was refused.** Skill step 9.1 says step 10's land lists its own paths under `### Paths landed`; 17 lands on main did; the first cut allowed only the `9.`/`10.` lines. | Correctness | High | Pass 1 F1 | `scripts/build-loop.sh` RECORD_AWK | for-author | Changing the skill instead (records' shape out of scope) | ✅ Fixed in 2468119c | Lines added inside the last block's Paths landed section are taken, all base lines kept in order. |

---

## 🟢 Consider

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| C1 | A fix to an already-landed block, or a restore of dropped blocks, cannot land through `--land-cycle`. | Docs | Pass 1 F2 | ✅ Fixed in 2468119c | Header says it lands by hand; research doc lists it. |
| C2 | An inserted `## Iteration` line can drop the last block's `9.`/`10.` lines. | Correctness | Pass 1 F3, pass 2 #1 | ✅ Fixed in 34f24441 | Residual restated accurately in the research doc. |
| C3 | Another session's block landing between step 9 and step 10 refuses step 10's land. | Correctness | Pass 1 F4 | ✅ Fixed in 2468119c | Fails closed; residual noted. |
| C4 | Stale comment, test title and quoted refusal text. | Docs | Pass 2 #2, #3 | ✅ Fixed in 34f24441 | — |
| C5 | The fixture never tested the Paths landed section's end. | Tests | Pass 2 #4 | ✅ Fixed in 34f24441 | Roadmap diff section added; mutation-checked. |
