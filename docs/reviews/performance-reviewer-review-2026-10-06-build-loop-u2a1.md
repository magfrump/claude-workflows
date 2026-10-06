Commit: 6f624cdf

# Performance Review — feat/build-loop-u2a1

**Scope:** `git diff main...HEAD` (one commit, 6f624cdf): scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, test/lib/build-loop-fixtures.bash, test/scripts/{dev-cycle,build-loop-read}.bats
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2a1.md (k=1; 24 claims, 0 Incorrect)

## Data Flow and Hot Paths

The diff touches three CLI paths, all per-invocation and per-argument:

- `main_entry` / `entry_why`: called once per file by `main_file` (build-loop.sh, settings and constraints: twice per run), once per brief by `check_brief` (per `--check-brief` path, and per `--status` path via `status_line`), and up to twice per question ID by `check_answer`. `entry_why` runs only on the refusal arm, and every refusal arm `return`s immediately, so it runs at most once per argument.
- `isclosed`: pure-bash glob plus one `isbrief` regex; no fork. Called from `writable` (per `--check-write`/`--check-fix` path), `check_brief` (per brief), and `shared_branches`, which loops over the `git grep -l` hits for `Status: open` under docs/working/briefs/ once per build-loop.sh process (memoised in `SHARED_BRANCHES`).
- Test-only changes: `bl_setup` gains one `unset` builtin; one test adds a `git replace -d`; dev-cycle.bats adds two `--check-fix` paths and three `main_entry` probes.

N is small everywhere: briefs on main number in the tens; arguments per run are a handful. All paths are CLI cold paths run by a human or orchestrator a few times per cycle, not request handlers.

Measured on this host (16 cores, WSL2; scratch microbenchmark, 1,000 iterations each, bash 5):

| Operation | Cost |
|---|---|
| `x="$(entry_why notfile docs/a.md)"` (one subshell) | 335 µs/call |
| new pair `{ isbrief p \|\| isclosed p; }` for one closed + one open path | 52 µs/pair |
| old pair `isbrief "${p/#…closed\//…/}"` for the same two paths | 35 µs/pair |
| `x="$(git rev-parse HEAD)"` (one git fork, for scale) | 995 µs/call |

Suite wall time, main snapshot (git archive) vs branch, two alternating runs each, TMPDIR under the scratch path (test 25 fails on both sides, pre-existing per the brief):

| Suite | main run 1 / 2 | branch run 1 / 2 |
|---|---|---|
| build-loop-read.bats (19 tests) | 9,204 / 9,439 ms | 9,467 / 10,847 ms |
| dev-cycle.bats (73 tests) | 16,991 / 17,578 ms | 17,108 / 16,800 ms |
| Sum | 26,195 / 27,017 ms | 26,575 / 27,647 ms |

The sum moves +380 / +630 ms (~1.4–2.3%), inside the run-to-run spread on either side (main itself varies 822 ms between runs; branch build-loop-read varies 1,380 ms). No delta attributable to the diff.

## Findings

#### entry_why adds one subshell fork per refused argument

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:352`, `scripts/lib/dev-cycle-read.sh:570`, `scripts/build-loop.sh:133`
**Move:** Count the hidden multiplications
**Classification:** Micro (one fork per call) / Cold path (CLI, at most once per argument; every caller `return`s on the same line)
**Confidence:** High
**Baseline:** 335 µs per `$(entry_why …)` call, measured by scratch microbenchmark on this host 2026-10-06 (1,000 iterations)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    *) echo "skip $a: $(entry_why "$e" "$a")"; return ;;
```
(`scripts/lib/dev-cycle-read.sh:352`)
```
      *) echo "skip $a: $(entry_why "$e" "$f"), so $f is not read"; return ;;
```
(`scripts/lib/dev-cycle-read.sh:570`)
```
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
```
(`scripts/build-loop.sh:133`)

The old inline `case` arms built the message without a fork; the shared mapping now costs one command substitution, only on the refusal branch, which ends the function. Per refused argument the path already pays `main_entry`'s own `$(...)` plus one `git ls-tree` (~1 ms per git fork here), so the added 335 µs is a constant on a terminal error path. `check_answer` refuses at most once per ID (the loop `return`s). Not worth changing; a `printf -v`/global-variable form would remove the fork but cost the readable single mapping the unit exists to create.

**Recommendation:** None. Recorded so synthesis can mark the focus question answered with a number.

#### isclosed is ~17 µs slower per pair than the old substitution in shared_branches

**Severity:** Informational
**Location:** `scripts/build-loop.sh:318`, `scripts/lib/dev-cycle-read.sh:159`
**Move:** Count the hidden multiplications / Ask "what's the size of N?"
**Classification:** Micro (one extra function call and glob per non-brief path) / Cold path (once per build-loop.sh process, memoised in SHARED_BRANCHES)
**Confidence:** High
**Baseline:** 52 µs (new) vs 35 µs (old) per pair of one open and one closed path, measured by scratch microbenchmark on this host 2026-10-06 (1,000 iterations)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
```
(`scripts/lib/dev-cycle-read.sh:159`)
```
    if ! { isbrief "$f" || isclosed "$f"; } || ! brief_fields "$f"; then continue; fi
```
(`scripts/build-loop.sh:318`)

The loop runs once per `git grep -l` hit (files under docs/working/briefs/ with a `Status: open` line), and each hit that passes the name test then pays `brief_fields`, which reads a git object (≥1 fork, ~1 ms). The name test is pure bash and is ~1–2% of the per-brief cost; with tens of briefs the whole difference is well under a millisecond per run. Linear in N either way; no complexity change. Fact-check verified the three spellings agree on 23 edge cases, so there is no behavior cost either.

**Recommendation:** None.

## Endorsements

- `shared_branches` still computes once per process and only reads briefs pre-filtered by one `git grep -l`; the diff changes only the name test inside the loop, not its N or its git calls. [read: scripts/build-loop.sh:306-323]
- `badform` is answered before any git call, so a refused path form costs no `ls-tree` fork. [fact-check: "badform answered with 0 git calls" — Verified (executed)]
- The suite-time delta of this branch is within run-to-run noise (sums 26.2/27.0 s on main vs 26.6/27.6 s on branch, two runs each). [unverified — submitted as claim: re-run both suites alternately ≥3 times on an idle host to confirm]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | entry_why adds one 335 µs subshell per refused argument | Informational | `scripts/lib/dev-cycle-read.sh:352,570`; `scripts/build-loop.sh:133` | High |
| 2 | isclosed costs ~17 µs more per pair than the old substitution in shared_branches | Informational | `scripts/build-loop.sh:318`; `scripts/lib/dev-cycle-read.sh:159` | High |

## Overall Assessment

The diff is a wording/refactor unit on cold CLI paths; neither change alters complexity, N, or the number of git processes on a success path. Both measured costs are sub-millisecond, dwarfed by the git forks already on the same paths (~1 ms each), and the test suites' wall time is unchanged within noise. Nothing to fix; no profiling needed. Note for U2a2/U2b: the open performance trigger in override-log row 214 (the import walk's per-path `inrepo` forks, revisit at "U2's floor function") is not touched by this unit and stays pending for U2a2.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: 6f624cdf` as its first line.
- **Answered:** All three focus questions with measurements: entry_why's subshell (335 µs per refusal, once per argument at most), isclosed's per-brief cost in shared_branches (+~17 µs per pair, no fork), and the test-suite delta vs main (within noise, ~+0.4–0.6 s on ~27 s against 0.8–1.4 s run-to-run spread).
- **Out of scope:** Correctness of the wording mapping and isclosed equivalence (fact-check's; verified there); the pre-existing check_answer re-running main_entry per ID (not in the diff).
- **Escalate:** None.
- **Questions / Decisions:** None.
