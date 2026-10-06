Commit: d48f4645

# Performance Review — feat/build-loop-u2a1 (final confirming pass)

**Scope:** `git diff main...HEAD` at d48f4645 (6f624cdf unit, 706e0499 review artifacts, d48f4645 iteration-1 fixes); code files scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/{dev-cycle,build-loop-read}.bats
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2a1-r{1,2,3}.md (k=3 at d48f4645; 0 Incorrect, 0 Stale, 0 Unverifiable); settled context: rubric docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md and override-log rows 306-325

## Data Flow and Hot Paths

Unchanged from iteration 1 in shape; every touched path is a CLI cold path (run by a human or the orchestrator a few times per cycle, N = a handful of arguments or tens of briefs):

- `entry_why` (lib:283-292) runs only on main_entry's refusal arm, and every caller returns on the same line: `main_file` (build-loop.sh:133, twice per run at most), `check_brief` (lib:354, once per brief argument), `check_answer` (lib:573-574, once per question ID, since the loop `return`s). Iteration 1 added two in-function parameter expansions (newline folding) and split check_answer's arm in two; neither adds a fork beyond the one command substitution already settled as C4 / override row 325.
- `isclosed` (lib:158): pure bash, no fork; called from `writable` (lib:161), `check_brief` (lib:344) and `shared_branches`' per-hit loop (build-loop.sh:318), which runs once per process after one `git grep -l`. Iteration 1 did not touch it.
- `check_fix` (dev-cycle.sh:182) gains one string comparison (`"$lp" == docs/constraints.md`) per argument; no fork.
- New in iteration 1: both suites' setup runs `unset $(git rev-parse --local-env-vars)` (fixtures:15, dev-cycle.bats:13): one git fork per test.

Measured on this host (WSL2, bash 5; scratch microbenchmark under the perf scratch dir, 2026-10-06, at d48f4645):

| Operation | Cost |
|---|---|
| `x="$(entry_why notfile docs/a.md)"` | 488 µs/call (1,000 iterations) |
| `x="$(entry_why "notdir docs/w" "")"` | 439 µs/call (1,000 iterations) |
| `x="$(git rev-parse --local-env-vars)"` | 1,068 µs/call (200 iterations); 16 names; also exits 0 outside a repository |

entry_why's figure is above iteration 1's 335 µs; the gap is host noise in fork cost (both are one subshell; the newline expansions are in-process string operations), and either value sits under the ~1 ms git fork that main_entry already pays on the same path. C4's Won't-Fix reasoning still applies; not re-filed.

## Findings

#### Each test's setup now forks git once to list repo-local variables

**Severity:** Informational
**Location:** `test/lib/build-loop-fixtures.bash:15`, `test/scripts/dev-cycle.bats:13`
**Move:** Count the hidden multiplications
**Classification:** Micro (one process per call) / Cold path (test setup, once per test; ~95 tests per full run)
**Confidence:** High
**Baseline:** 1,068 µs per `git rev-parse --local-env-vars` call, measured by scratch microbenchmark on this host 2026-10-06 (200 iterations)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    unset $(git rev-parse --local-env-vars)
```
(`test/lib/build-loop-fixtures.bash:15`)
```
    unset $(git rev-parse --local-env-vars)
```
(`test/scripts/dev-cycle.bats:13`)

The A1/C5 fix replaces a would-be static list with git's own list, at one fork per test: about 95 × 1.07 ms ≈ 0.1 s per full run of both suites, against iteration 1's measured ~27 s suite sum and its 0.8-1.4 s run-to-run spread, so it is not observable as a suite-time change. The cost buys tracking git's list across versions (the reason C5 was raised), which a hard-coded list would not. Hoisting it into `setup_file` would not work as-is, since bats runs each test in its own process and the unset must take effect there; the cost is not worth any restructuring.

**Recommendation:** None. Recorded so synthesis has a number for the one new process the iteration-1 fixes add.

## Endorsements

- The iteration-1 fixes add no fork on any script path: entry_why's newline folding is two in-function `${var//…}` expansions, and check_answer's split notdir arm still makes exactly one `$(entry_why …)` call before `return`. [read: scripts/lib/dev-cycle-read.sh:283-292, scripts/lib/dev-cycle-read.sh:566-575]
- `badform` is answered before any git call, so a refused path form costs no `ls-tree` fork. [fact-check: "badform with 0 git calls" — Verified (executed), r1-r3]
- check_fix's constraints.md refusal is one extra string comparison per argument inside the existing condition. [read: scripts/dev-cycle.sh:178-182]
- Adding the per-test `git rev-parse --local-env-vars` fork leaves both suites' wall time within run-to-run noise (estimated +~0.1 s on ~27 s). [unverified — submitted as claim: time both suites at main and at d48f4645, alternating, ≥3 runs each]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Each test's setup forks git once (~1.07 ms; ~0.1 s per full run) | Informational | `test/lib/build-loop-fixtures.bash:15`; `test/scripts/dev-cycle.bats:13` | High |

## Overall Assessment

The iteration-1 fixes (A1-A6) are performance-neutral on every script path: they change wording, add in-process string operations and one comparison, and keep entry_why's single fork on terminal refusal arms (C4, settled Won't-Fix). The one new process is in test setup, ~1 ms per test, invisible at suite scale. No complexity class, N, or git-call count changes on any success path. Nothing to fix; no profiling needed. Override row 310 (U2's --check at ~2 ms per changed path through main_entry) and row 214 (the import walk's per-path forks) remain the pending performance triggers, for U2a2's floor.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-final-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d48f4645` as its first line.
- **Answered:** Full-branch performance pass at d48f4645, including whether iteration-1 fixes A1-A6 introduced cost: they add no script-path fork; the setup unset adds one measured ~1.07 ms git fork per test (Informational). C4 / row 325 re-checked and still applies (entry_why 439-488 µs on this host, still one fork on a returning arm).
- **Out of scope:** Correctness of the wording mapping, isclosed equivalence and the hermeticity fix (fact-check's, verified there); pending perf rows 214 and 310 (U2a2's floor).
- **Escalate:** None.
- **Questions / Decisions:** None.
