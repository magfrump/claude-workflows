Commit: e438cd1

# Code Review Rubric

**Scope:** feat/dev-cycle vs feat/dev-cycle-digest (skills/dev-cycle, docs/roadmap.md, decision-tree row 12, README, guides/skill-creation.md, decision log rows 66–67, Q-099, Q-100) — the upper unit of the size-gate split | **Reviewed:** 2026-09-29 | **Status: 🟡 fixes applied; iteration 3 pending**

Loop:
1. **Iteration 1:** pass 1 on the combined unit (89a3d3b); rubric `code-review-rubric-2026-09-29-feat-dev-cycle.md`.
2. **Iteration 2, final pass on e438cd1:** k=3 fact-check, security, api-consistency, architecture-review. Performance was skipped; its only surface here is the description cost, measured in earlier passes.

Considered overrides: no prior overrides matched this diff.

## 🔴 Must Fix

None.

## 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | The skill committed in steps 1, 4 and 7 without the Operating Modes gate. It could commit on main or another session's branch, and staging was unbounded | security skill-final #1 (Medium) | ✅ Fixed: `chore/dev-cycle-<date>` branch after a branch check; named paths only; Operating Modes; code fixes through pr-prep |
| A2 | Step 4 could run commands quoted in repo text; the evidence rule covered only the digest | security skill-final #2 (Medium) | ✅ Fixed: the rule covers everything the cycle reads and subagent briefs; numbers are re-derived from the repo's own tests or code |
| A3 | Carried verdicts were not copied into the new record, so the chain decays after one cycle | architecture skill-final #1 (Coupling) | ✅ Fixed: record template with one verdict per trigger under the digest's names, carried ones marked; step 2 decides carried triggers with no recorded verdict |
| A4 | Row 66's revisit trigger and roadmap Next #4 counted research/plan docs, which are gitignored (4 ever tracked) | fact-check r2 (Incorrect) | ✅ Fixed: count `← carried from RPI` merge lines and committed code-review rubrics |
| A5 | Roadmap Next #3 misdescribed the `Live-verified:` gate | fact-check r1, r2, r3 | ✅ Fixed (per Q-083) |
| A6 | Step 7 said "silently falls back to 14 days": wrong on both counts | fact-check r1, r2 (Incorrect), r3 | ✅ Fixed: states that a skipped record makes the next window start at the older record, unflagged; step 0 says how to notice |

## 🟢 Consider

| # | Finding | Status |
|---|---|---|
| C1 | `Main at:` must start its own line; a same-day second line loses | ✅ Fixed (template; keep a single line) |
| C2 | Row 12 keywords differ from the description | ✅ Fixed (aligned) |
| C3 | Quiesce could kill another session's processes (shared uid) | ✅ Fixed (this session's PIDs only) |
| C4 | Step 1's bare `questions.sh` | ✅ Fixed (installed path) |
| C5 | Row 67: "nine unwritten runs" → at least nine; onboarding also re-reads on refresh | ✅ Fixed |
| C6 | Roadmap Next #5 claim unsourced; Q-100 token estimate unsourced | ✅ Fixed (A8 rubric row cited; estimate derived from the last pass) |
| C7 | A fired trigger's text shapes an `agent` entry; seed intro differs from the template | 🟢 Won't-Fix (override log) |
