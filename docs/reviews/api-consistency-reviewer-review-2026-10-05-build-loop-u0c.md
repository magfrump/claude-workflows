Commit: a57e5d27

# API Consistency Review — feat/build-loop-u0c, iteration 2 (fix a57e5d27)

> ⚠️ **No code fact-check report provided for iteration 2.** The fix's header, comment and plan-amendment claims were checked against the code here, by reading and by running it. The iteration-1 report (docs/reviews/code-fact-check-report-build-loop-u0c.md) covers the move commit.

**Scope:** `git diff feat/build-loop-u0c~1 feat/build-loop-u0c` (fix a57e5d27), plus `git range-diff 27e38dc4^! feat/build-loop-u0c~1^!`. The range-diff shows a reworded message and rebased header comments and T29 lists. Consumers: dev-cycle.sh's `--check-fix` now, build-loop.sh's floor (U2) later.
**Date:** 2026-10-05
**Based on:** docs/reviews/api-consistency-reviewer-review-2026-10-04-build-loop-u0c.md (iteration 1), docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0c.md, override-log rows 202-207

## Prior findings

| Iteration-1 item | Status | Evidence |
|---|---|---|
| API Finding 1 / rubric C4: the readers take input from two sources, the walk caches per process, and neither fact is in the contract | **Closed** (tree-or-commit parameter deferred) | Header `scripts/lib/dev-cycle-read.sh:15-17`: "Inputs: check_brief and check_branch read the default branch's commit; check_answer and the import walk read the working tree at ROOT_REAL." Cache comment `:332-333`: "Computed once per process and repo root (IMPORTED_DONE holds the root it was computed for)." Whether the walk should take a tree or a commit is U2's decision (override-log row 205, plan amendment). |
| Rubric A1: commit message contradicts plan :187 | Resolved | The range-diff shows the message now reads "extracting check_fix's predicate, which the plan lists, is deferred to U2". The plan's amendment paragraph sits under the lib list (`docs/working/plan-build-loop-handoff.md:192`), and its bullet at `:187` is reworded to match. |
| Rubric A2: an unset ROOT_REAL makes the walk return an empty set and cache it | Resolved | `need_root` is the walk's first statement (`:339`), outside any `$(...)`. dev-cycle.sh calls `imported_names` directly in `check_fix` (`scripts/dev-cycle.sh:174`), not in a substitution, so the exit stops the script. New test "the import walk stops without ROOT_REAL and recomputes for another repo root". |

## Baseline Conventions

These are unchanged from iterations 1 and 2 of U0a and U0b. Relevant here: lib-owned state is initialised when the lib is sourced (`IMPORTED=$'\n'; IMPORTED_DONE=""`, `:334`). A missing ROOT_REAL exits through `need_root` (`:73`).

## Name-Pattern Audit

The fix adds no new public names. One existing global changes meaning:

| Changed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `IMPORTED_DONE` (was `""`/`1`, now `""`/the root path) | lib global | `SKIP_AT` (holds a path), `MAIN_BY_NAME` (a `""`/`1` flag) | `scripts/lib/dev-cycle-read.sh:82,220` | Consistent. No consumer reads it: a grep of scripts/ and test/ at this tip finds it only in the lib, and in T29's "is it declared" list. Its emptiness when unset is unchanged. |

## Findings

No findings.

## What Looks Good

- **The cache-key change leaves check_fix's behaviour unchanged.** dev-cycle.sh sets ROOT_REAL once (`scripts/dev-cycle.sh:115`) and runs every `--check-fix` argument in one process. The first call computes the walk, and every later call matches `IMPORTED_DONE == ROOT_REAL` and returns, as the old `IMPORTED_DONE=1` did. The full bats suite, including its `--check-fix` import cases, passes 59/59 at this tip. `--check-fix README.md` gives byte-identical output and exit 0 compared with feat/build-loop-handoff. `route: code-fact-check`
- **dev-cycle.sh's CLI, `--help` and exit codes are unchanged apart from the documented missing-lib exit.** The nine probes (`--help`, `--bogus`, `--check-path` with no argument, `--sample=x`, `--since` with no value, and one call per check mode) match the base in stdout, stderr and exit code. The one exception is `--help` line 75, the Exit wording added in U0a. In a repo with no main or master, both by-name modes print the base's refusal and exit 1. With the lib absent, the script exits 1 with "dev-cycle.sh needs …/lib/dev-cycle-read.sh". `route: code-fact-check`
- The new test can fail. I removed `need_root` from `imported_names`, and separately put back the old `IMPORTED_DONE=1` flag. Each mutation made "the import walk stops without ROOT_REAL and recomputes for another repo root" fail (run in this pass, file restored). The test therefore pins both the guard and the per-root key.
- Recomputing resets `IMPORTED=$'\n'` (`:340`), so a walk for a second root never carries over the first root's names. The test's expected output (` docs/a.md ` then ` docs/b.md `) asserts exactly that.
- T29 now checks that all seven lib-owned globals are declared when the lib is sourced (`SKIPPED SKIP_AT MAIN MAIN_SHA MAIN_BY_NAME IMPORTED IMPORTED_DONE`), so the U0b initialisation is also pinned.
- The dev-cycle.sh directive comment (`:114`, "read by the lib's file rules and import walk") now names both readers of ROOT_REAL. `route: code-fact-check`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The fix closes iteration 1's Informational finding as far as U0c can: the header now states each reader's input source, and the cache comment states the cache's scope. The tree-or-commit question for the gate is deferred to U2 under a recorded row and plan amendment. Both rubric Must-Address items are resolved. The cache-key change is invisible to dev-cycle.sh's only consumer of the walk and makes a second root safe for build-loop.sh. Nothing blocks the land.

## Goal-Alignment Note

The goal is to finish the U0 extraction without changing dev-cycle.sh, leaving a lib that build-loop.sh can call directly. The probes and 59/59 bats confirm that dev-cycle.sh is unchanged. The fix makes the walk safe for a second caller in the two ways a caller could misuse it: a missing ROOT_REAL now exits, and switching roots recomputes. The plan amendment records what still stands between this lib and the U2 floor: check_fix's predicate, an `isimported` accessor, and a commit-reading walk. That keeps them out of this unit's scope. None of the deferred rows 202-207 became worse.
