Commit: b8722aba

# Code Review Rubric

**Scope:** refactor/d6-block-into-image, 5b20d4bd..b8722aba | **Reviewed:** 2026-11-05 | **Status: 🟡 CONDITIONAL PASS** — iteration 2 of 3 ran the fact-check on the delta only, its Incorrect being a comment; the critics run on iteration 3's full pass

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| — | none | | | | | | | |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| A1 | `g()` folded a lib or `git_harden` failure into git's "no such ref", so a refusal named a false cause, and H2 wants a bats case for the path | Architecture | Coupling | architecture-review, api-consistency-reviewer | `scripts/d6.sh:36` | for-author | — | Fixed: tried alone before the loop, two T36 cases |
| A2 | Between the merge and the release, the image's GATE_CODE does not list `scripts/d6.sh`, so an honest brief naming it could self-merge | Security | Medium | security-reviewer | `scripts/lib/dev-cycle-read.sh:1032` | for-author | — | Accepted, stated in pre-mortem 3; the remedy is in `docs/dev-cycle.md`, which this branch may not edit, so it is in the ready marker |
| A3 | Comment and research claims about `caller_gate` were false; a lib failure was not always "absent"; a commit message's revert claim stopped holding | Docs | Incorrect | Fact-check | `scripts/d6.sh`, research doc | for-author | — | Fixed; the commit message is immutable history, corrected in the research doc |
| A5 | "Exit 1 can only be git's no such ref" was false: show-ref exits 1 for a ref it cannot use. Behaviour matches the block | Docs | Incorrect | Fact-check i2 | `scripts/d6.sh:50`, research pre-mortem 5 | for-author | — | Fixed |
| A4 | Plan rows F38, F39, T33, T36, T37 and the line-63 file list described the removed block | Docs | Stale | Fact-check, security-reviewer, api-consistency-reviewer | `docs/working/plan-build-loop-handoff.md` | for-author | — | Fixed |

---

## 🟢 Consider

| # | Finding | Source | Location | Legibility-target | Status |
|---|---|---|---|---|---|
| C1 | No test ran d6.sh from `D6_OPT/scripts/` | architecture-review | `test/scripts/build-loop-orchestrator.bats` | for-author | Fixed |
| C2 | "older than this skill" fits exit 127 only | api-consistency-reviewer | `skills/dev-cycle/SKILL.md` | for-author | Fixed |
| C3 | Exit 1 not stated in the skill | api-consistency-reviewer | `skills/dev-cycle/SKILL.md` | for-author | Fixed |
| C4 | `-f` let a symlink through; the scrub test pinned three of six variables | Fact-check | `scripts/d6.sh` | for-author | Fixed |
| C5 | Three readers of the default-branch rule can disagree (main with origin/HEAD at trunk) | architecture-review | `scripts/d6.sh`, `scripts/lib/dev-cycle-read.sh` | for-author | Open: predates this branch, and `--state` bounds it in a cycle |
| C6 | The lib is parsed more than once per call | performance-reviewer | `scripts/d6.sh` | for-author | Left: a few ms a call, and d6.sh is still faster than the block |

---

## ✅ Confirmed Good

None claimed on this pass: confirmed rows are the final pass's output.

## ⏭️ Skipped Core Critics

None.

## 🧩 Composition check

- `scripts/d6.sh:36-54`: fragments A1 (architecture, API consistency), fact-check claim 22a. One defect, already stated whole by A1: distinct defects not applicable, no composed row needed.

Considered overrides: no prior overrides matched this diff.
