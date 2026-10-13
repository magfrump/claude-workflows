Commit: 414c9295
Loop-pass short-circuit: used at 414c9295

# Code Review Rubric: feat/build-loop-u3c

**Scope:** full branch, `git diff main...HEAD` (main dafc0e74; first pass of the loop). Delivery mode: self-read (shared brief on disk).
**Iteration 1** (`--loop-pass`, k=1 fact-check). Stopped at Stage 1 by the first-red short-circuit.
**Reports:** `docs/reviews/code-fact-check-report-2026-10-12-u3c-i1.md`.

## 🔴 Must Fix

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A1 | `--cycle-diff` sorts each side's key lines before comparing, so the order of lines inside an entry is lost; `--check-answer` reads an entry's first Needs line and first answer line. Swapping two answer lines (`drop` → `keep`) or two Needs lines (`open` → `keep`) passes with no `--answered`: the F33 laundering the mode exists to stop. Fix: compare key lines in file order within each entry, a move between the two files still free; add a reorder case to T38. | fact-check claims 4, 10, 32 (executed, probes P1, P2) | Incorrect (high), behavioral | `scripts/build-loop.sh:1848-1850` `LC_ALL=C sort -o "$t.qo" "$t.qo" && LC_ALL=C sort -o "$t.qn" "$t.qn"`; `scripts/lib/dev-cycle-read.sh:2084-2092` (`!header && /^\*\*Needs:\*\*/` ... `!done {`) | Open |

## 🟡 Must Address

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A2 | Commit f34fceb0's body says row 722 is "re-keyed to U4", but `docs/reviews/override-log.md` has no such row on the branch. | fact-check claim 32 | Incorrect (doc) | `docs/reviews/override-log.md:722` unchanged | Open |
| A3 | T38's comment lists "a new archive file" but no new-file case runs; "a deleted entry" has no case of its own. | fact-check claims 27, 28 | Incorrect / Mostly accurate (test text) | `test/scripts/build-loop-orchestrator.bats:408,413` | Open |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| A4 | Header "A new file ... is not judged" is false for a new questions file (it is judged, and refused when filed answered). | fact-check claim 13 | Open |
| A5 | cyc_blob's comment names the all-zero id; it tests mode 000000, and returns gate_git's status (possibly 3), not 1. | fact-check claim 20 | Open |
| A6 | QKEYS_AWK does not repeat ANSWER_AWK's whole-file refusals (a fenced `### Q-` heading, a duplicate heading); fails safe. | fact-check claims 3, 11, 17 | Open |

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review | loop-pass short-circuit (behavioral red confirmed) |

## Considered overrides

- Row 724 (three `--raw -z` readers): discharged by raw_records; fact-check found it equivalent to the old readers (chore loop now classes an unparsed record other).
- Row 722 (a chore merge's other paths): kept deferred by this unit; the re-key row is owed (A2).
- Row 682 (health-check.sh not gate code): pre-existing, routed to U5/Q-103.

**Status:** 🔴 1 Must Fix, 🟡 2 Must Address, 🟢 3 Consider. Not mergeable this pass.
