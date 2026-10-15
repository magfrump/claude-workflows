Commit: f84a9dfa
# Performance Review — fix/q110-not-run-undercount

**Scope:** `git diff main...HEAD` (70aa3a78, f84a9dfa): `scripts/run-tests.sh`, `test/skills/eval-helpers-gating.bats`, `docs/thoughts/failure-patterns.md`
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-q110.md` (k=3 merged, Commit f84a9dfa)

## Data Flow and Hot Paths

`scripts/run-tests.sh` is a CLI test runner. It runs once per invocation (by a developer, or twice per `scripts/health-check.sh` BATS gate, `health-check.sh:431` and `:439`), and finishes by `exec`ing bats (`run-tests.sh:452`). The change adds one `unset RUN_TESTS_NOT_RUN_FILE` (`run-tests.sh:368`). It runs once per runner invocation, after the single count write at `:359-361` and before the `--failed` filter, the `--jobs`/GNU parallel setup (`:421-435`), the `bats --count` step (`:441`) and the `exec`. Nothing after `:368` reads the variable (I read `:368-452` in full). The variable's only consumer is the caller, which reads it after the runner exits (`health-check.sh:436`, `:440`/`:442` via `_not_run_count`). That is consistent with fact-check cluster 5 (Verified).

Path temperature: **cold**. The whole runner is a one-shot CLI entry point. The new line is O(1) and does not touch any loop. The candidate loop (`:189-217`), `collect_tests` (`:274-301`) and the gating loop (`:330-351`) are unchanged. They scale with the number of `.bats` files, which is about 200 in this repo (verify data size).

The new test (`eval-helpers-gating.bats:74-86`) is one more fast-tier test. It makes one runner invocation against a 6-suite fixture and swaps the real bats for a stub, the same shape as the file's other 8 tests. The FP-173 line is documentation and has no runtime cost.

## Findings

No findings.

The diff adds no loop, query, allocation, cache or I/O on any path. It removes one I/O path: a nested runner can no longer write to the caller's file (see Endorsements). The new test adds one sub-second fixture run to the fast tier. That is Micro × Cold, which is below the threshold for a finding (no baseline available — flagged as speculative; noted here only so the omission is auditable).

## Endorsements (evidence-gated)

- The unset closes the path by which any number of nested runner invocations could each rewrite the caller's count file. An end-to-end run executed against both runners showed the caller's file read 99 (the stub's write) on `main`'s runner and 4 (the caller's own count) on HEAD's. `[fact-check: claim 17 (Verdict-stability cluster 17, executed) — Verified]`
- The unset sits at `run-tests.sh:368`, before the `--jobs` branch (`:428-435`). So under `--jobs N` (as health-check passes, `health-check.sh:431`), the N concurrent suite files no longer share one inherited output path. On the old runner, two or more parallel suites that each nested the runner could race on that single file, and the last writer won. Removing the inheritance removes that shared write target instead of serializing it. `[unverified — submitted as claim]`
- The fix adds no per-suite or per-test work: the cost is one builtin `unset` per runner invocation, independent of file count or `--jobs`. `[read: scripts/run-tests.sh:359-368]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The change has no performance weight. It is a one-line, O(1) environment change on a cold CLI path, plus one fixture-scale test. If anything it cuts I/O and removes a shared write target under parallel runs. Nothing needs profiling or benchmarking. The fact-check escalations (Q-110's stale line citation; early `exit 1` paths leave the caller's file unwritten) are correctness and bookkeeping issues outside this critic's mandate, and I have nothing to add to them.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved at the output path given in your tail, structured per your skill.
- Answered: yes. I reviewed the full branch diff with the enclosing units read (`run-tests.sh` whole, the `eval-helpers-gating.bats` whole, `health-check.sh:420-452`). There are no findings and 3 evidence-tagged endorsements.
- Out of scope: comment and commit-message accuracy (code-fact-check, done); whether a runner-side or suite-side fix is better as design (architecture/API critics); the pre-existing early-exit no-write (correctness, escalated by the fact-check).
- Escalate: none from this critic. The second endorsement (no parallel race on a shared file under `--jobs`) goes to fact-check intake as a submitted claim.
