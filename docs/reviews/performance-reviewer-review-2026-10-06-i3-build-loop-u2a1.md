Commit: d07cc89c

# Performance Review — feat/build-loop-u2a1 (iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` at d07cc89c (unit 6f624cdf; fixes d48f4645, 91469367; review artifacts 706e0499, d07cc89c). Code files: scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/{dev-cycle,build-loop-read,fixture-git-env}.bats
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2a1-r{1,2,3}.md (k=3 at d07cc89c; no defect in the unit's code); settled context: rubric docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md (iterations 1-2) and override-log rows 306-330 (C4 = row 325, C8 = row 328 Won't-Fix; rows 214 and 310 pending for U2a2's floor)

## Data Flow and Hot Paths

Every script path the branch touches is a CLI cold path (run by a human or the orchestrator a few times per cycle; N = a handful of arguments, or tens of briefs in shared_branches). Iteration 2 (91469367) changed, on script paths:

- `entry_why` (scripts/lib/dev-cycle-read.sh:286-296): `p="${2//…}"` became `p="${2-}"` then `p="${p//$'\n'/ }"`: two in-process expansions instead of one; no fork. Comment-only otherwise.
- `check_answer` (scripts/lib/dev-cycle-read.sh:567 onward, read in full): its separate `notdir` arm was folded into the default arm. Still exactly one `$(entry_why …)` command substitution, on an arm that `return`s on the same line; one fewer case pattern.
- `main_entry` (scripts/lib/dev-cycle-read.sh:263-280): comment only; the two guards (`main_by_name`, then `pathform`) were already split in 6f624cdf, so the order costs the same as before.
- `scripts/dev-cycle.sh:168`: comment wording only.

Iteration 2's one new process-level cost is in the test tier: test/scripts/fixture-git-env.bats (tagged `# @category fast`) runs a nested `bats -f` over dev-cycle.bats and build-loop-read.bats, one test each.

Measured on this host (WSL2, bash 5, TMPDIR from `mktemp -d /tmp/u2a1i3x-XXXX`, script under the perf scratch dir, 2026-10-06, at d07cc89c):

| Run | Wall time |
|---|---|
| `bats test/scripts/fixture-git-env.bats` (3 runs) | 4.12 s, 0.69 s, 0.72 s |
| `bats -f '^prints all eight sections' dev-cycle.bats` (2 runs) | 0.35 s, 0.34 s |
| `bats -f 'exact policy line is set' build-loop-read.bats` (2 runs) | 0.26 s, 0.28 s |
| `bats test/scripts/dev-cycle.bats` (75 tests, 1 run) | 16.11 s |
| `bats test/scripts/build-loop-read.bats` (1 run) | 9.39 s |

All runs exited 0.

## Findings

#### fixture-git-env.bats adds a nested bats run per test in the fast tier

**Severity:** Informational
**Location:** `test/scripts/fixture-git-env.bats:2`, `:24-32`
**Move:** Count the hidden multiplications
**Classification:** Micro (one nested bats process per test, constant) / Cold path (test suite, run per developer invocation)
**Confidence:** High
**Baseline:** 0.69-0.72 s wall time for the whole suite (2 tests), warm, measured on this host 2026-10-06 at d07cc89c (3 runs; the first, cold run took 4.12 s)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# @category fast
```
(`test/scripts/fixture-git-env.bats:2`)
```
    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f '^prints all eight sections' "$REPO_ROOT/test/scripts/dev-cycle.bats"
```
```
    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f 'exact policy line is set' "$REPO_ROOT/test/scripts/build-loop-read.bats"
```

Each test starts a second bats, which loads and preprocesses the whole target file (dev-cycle.bats has 75 tests) before the filter selects one; warm, that is ~0.35 s per test, within run-tests.sh's "fast tests (... <1s each)" description and ~3% of the two suites' ~25.5 s it guards. The 4.12 s first run is a single cold-cache sample (cause not isolated); it does not repeat. The cost grows only if more tests are added here, which override row 327 plans (one per further suite fixed): each adds roughly that suite's load time plus one test. No complexity concern; the nested run is the only way to observe the target suite's setup under an inherited GIT_DIR.

**Recommendation:** None now. If row 327's follow-ups add several more nested runs, keep each `-f` filter on one short test (as both current ones are) so the suite stays under the fast tier's per-test description.

## Endorsements

- Iteration 2's script changes add no fork on any path: entry_why gains one in-function parameter expansion, and check_answer's folded arm still makes one `$(entry_why …)` call before `return`. [read: scripts/lib/dev-cycle-read.sh:286-296, scripts/lib/dev-cycle-read.sh:567-580]
- `badform` is answered before any git call, so a refused path form costs no `ls-tree` fork. [fact-check: "badform with 0 git calls" — Verified (executed), r1-r3 at d07cc89c]
- Each fixture-git-env `-f` filter selects exactly one test of its target suite, so the nested runs cost one test each. [fact-check: "each fixture-git-env -f filter matches one test" — Verified (executed), r1-r3]
- Iteration 2's changes leave both main suites' wall time within run-to-run noise of d48f4645 (16.11 s and 9.39 s here, one run each). [unverified — submitted as claim: time dev-cycle.bats and build-loop-read.bats at d48f4645 and d07cc89c, alternating, ≥3 runs each]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | fixture-git-env.bats runs a nested bats per test in the fast tier (~0.35 s/test warm; 0.69-0.72 s suite) | Informational | `test/scripts/fixture-git-env.bats:2,24-32` | High |

## Overall Assessment

Iteration 2's fixes (91469367) are performance-neutral on every script path: wording, one in-process expansion, and one fewer case arm; entry_why's single fork on terminal refusal arms stays as settled in C4 / row 325, and the per-test `git rev-parse --local-env-vars` fork stays as settled in C8 / row 328 (neither re-filed). The only new cost is the fixture-git-env suite's two nested bats runs, measured at ~0.7 s warm, Informational. No complexity class, N, or git-call count changes on any success path; nothing to fix, no further profiling needed. Rows 214 and 310 remain the pending performance triggers for U2a2's floor.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-i3-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d07cc89c` as its first line.
- **Answered:** Full-branch performance pass at d07cc89c, including whether iteration 2's fixes (91469367) are correct and introduced cost: no script-path fork added; one Informational, measured finding on the new nested-bats suite (0.69-0.72 s warm). C4/row 325 and C8/row 328 still apply and are not re-filed.
- **Out of scope:** Correctness of wording, isclosed equivalence and the hermeticity tests (fact-check's; its Mostly-accurate items on fixture-git-env's header and the "five other suites" row are not performance claims); pending perf rows 214 and 310 (U2a2's floor).
- **Escalate:** None.
- **Questions / Decisions:** None.
