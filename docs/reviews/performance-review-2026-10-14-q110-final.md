Commit: 16ce27bf
# Performance Review — fix/q110-not-run-undercount (iteration 2, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test docs/thoughts` (scripts/run-tests.sh, test/skills/eval-helpers-gating.bats, docs/thoughts/failure-patterns.md), full branch, 5 commits ahead of main b279a2ba
**Date:** 2026-10-14
**Based on:** docs/reviews/code-fact-check-report-q110-final.md (k=3, merged, stamped 16ce27bf); docs/reviews/code-fact-check-submitted-claims-q110.md (claim 25b)

## Data Flow and Hot Paths

`scripts/run-tests.sh` is a CLI test runner, started once per test run by a developer or twice per health check (`scripts/health-check.sh:431` fast, `:439` slow, each with its own `RUN_TESTS_NOT_RUN_FILE`). The branch adds one builtin, `unset RUN_TESTS_NOT_RUN_FILE` (`scripts/run-tests.sh:369`), after the count write (`:360-361`) and before the NOT RUN listing, the `--failed` filter, the GNU parallel probe, `bats --count` (`:442`) and `exec bats` (`:453`). It runs once per runner invocation, adds no loop, file access, subprocess or allocation, and removes one exported variable from the environment bats and every suite process inherits. Path temperature: cold (once-per-run CLI setup, before any test executes).

The new test (`test/skills/eval-helpers-gating.bats:74-86`) runs the runner once more against a throwaway layout with a stub bats, as tests 1-2 already do. It is in a `# @category fast` suite. Measured on this pass: `bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats` took 2.28 s wall for all 7 tests (single run, this worktree at 16ce27bf, 2026-10-14). The new test is one seventh of a suite that is itself one file of the fast tier. Path temperature: cold (test-suite setup, no per-item scaling).

FP-173 is one appended line in a docs file; it has no performance surface.

Work count does not change. The nested runner start inside `eval-helpers-gating.bats` existed before the branch. The fix stops it writing to the caller's file and adds no runs. Per fact-check claim 25b (Incorrect), the old defect was a sequential overwrite, not a race between parallel suites, and `--jobs` neither caused nor worsens it. This review does not re-raise a concurrency mechanism.

## Findings

No findings.

(Checked with the cognitive moves that apply. Hidden multiplication: the unset runs once per runner invocation and adds no loop. Wrong place: it sits after the last reader of the variable (the write at `:360-361`; fact-check cluster 3 found nothing after the unset that needs it). Memory lifecycle and contention: no allocation, no lock. The lock fd 9 is unchanged and stays open into `exec bats` as before. Cache: none touched. Deployment: local CLI only. A finding below Informational would be Micro × Cold. The skill puts that at Informational with nothing worth a reviewer's time, so none is filed.)

## Endorsements

- The unset reaches every path to `bats --count` (`:442`) and `exec bats` (`:453`), including `--failed` and the early `exit 0` paths, so neither bats nor a nested runner writes to the caller's file. This means no second write to that file can happen during a run. [fact-check: cluster 3 — Verified]
- The fix removes the overwrite without adding work. On main's runner a stub suite overwrote the caller's file (99); on HEAD's runner the caller's count stays 4, serially and under `--jobs 2`. [fact-check: cluster 10 — Verified (executed)]
- The regression test fails on main's runner (`test/skills/eval-helpers-gating.bats:84`) and passes 7/7 on HEAD's, so its extra ~0.3 s pays for a real guard and is not a vacuous run. [fact-check: cluster 21 — Verified (executed)]
- Claim: the health check's two runner invocations (`scripts/health-check.sh:431`, `:439`) take the same time before and after the branch, because the only runtime change is one shell builtin before `exec bats`. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The branch has no performance effect worth tracking: one builtin on a cold CLI path and one stub-backed test in an existing fast suite (whole suite 2.28 s measured). Run count, I/O and concurrency stay as they were. The fix narrows what the suites inherit and adds no work. Nothing needs profiling or benchmarking. On performance grounds the branch can land.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path given in your tail, structured per your skill.
- **Answered:** yes. Saved at docs/reviews/performance-review-2026-10-14-q110-final.md with the skill's header, Data Flow, Findings (none), evidence-tagged Endorsements, Summary Table and Overall Assessment. Endorsements are keyed to the merged fact-check report's execution verdicts. The one that is not is tagged `[unverified — submitted as claim]`.
- **Out of scope:** the early runner exits that never write the count (lock held, no matched files, bad tag; fact-check Escalation 3, pre-existing); `PARALLEL_ENV` re-injection under `--jobs` (correctness, not performance; fact-check cluster 9); iteration-1 rubric line numbers (fact-check claim 1, Stale, docs only).
- **Escalate:** none from this critic. The fact-check report's escalations (Q-110 entry citation and status; the brief's "6 commits ahead" typo, since the branch is 5 ahead) stand as routed to the orchestrator.
