Commit: 497c8cb5

# Performance Review — feat/build-loop-u0a, final confirming pass (full range)

**Scope:** `git diff feat/build-loop-handoff..feat/build-loop-u0a` (4ef450da, 32b9ae0e, 497c8cb5) and their commit messages
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u0a.md` (merged k=3, Commit 497c8cb5: no behavioural claim wrong; byte-identical output vs main verified by execution)

## Data Flow and Hot Paths

U0a moves the scrub, the plain-file rules (`rawfile`, `plaindir`, `blocker`, `inrepo`, `dirok`, `skipped`), `pathform` and the bookkeeping-name rules into `scripts/lib/dev-cycle-read.sh`, sourced once per process (twice per run: the parent before `scrub_reexec`, and the child). Every function is a per-process CLI path: a digest calls `inrepo`/`dirok`/`skipped` a fixed handful of times (fixed-name inputs and decision/cycle directories), and the check modes call them once per argument. Path temperature: cold (one CLI run, argument count set by the skill, not by data).

Measurements by this reviewer, 2026-10-05, this machine, scratch worktrees at each tip, all runs against the same checkout (u0c tip):

- Digest (`--since=2026-09-01`), 7 interleaved runs each, wall ms: main 437 433 414 421 408 849 421 (median 421); U0a 428 416 429 412 414 430 438 (median 428). Output md5 identical for main, handoff, U0a, U0b, U0c.
- `bash -x` trace of one digest run: main 0 `need_root` / 1 `pwd -P`; U0c tip 11 `need_root` / 12 `pwd -P` (inrepo 5, dirok 2, skipped 4 — the same counts as main).
- Microbenchmark, 1,000 calls each: `need_root` 324 ms (~324 µs/call, dominated by the `$(pwd -P)` subshell); `[[ "$ROOT_REAL" == "$PWD" ]]` 2 ms (~2 µs/call); `inrepo README.md` 1,652 ms (~1.65 ms/call including need_root).
- Start-up: `bash -c 'source scripts/lib/dev-cycle-read.sh'` 1.5 ms vs `bash -c :` 0.9 ms per run (~0.6 ms per source, two sources per run).

## Findings

#### need_root's ROOT_REAL == $(pwd -P) test forks a subshell on every file check

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:73-76` (U0a tip; `:80-83` at U0c), callers `inrepo`/`dirok`/`skipped` `:102-106`
**Move:** Find the work that moved to the wrong place (per-call recomputation of a per-process fact)
**Classification:** Micro (one fork per call) / Cold path (per CLI run; N = fixed inputs or argv count)
**Confidence:** High
**Baseline:** need_root ~324 µs/call (1,000-call microbenchmark, this reviewer, 2026-10-05); digest median 421 ms main vs 428 ms U0a (7 runs each)
**Evidence:** `  [[ "$ROOT_REAL" == "$(pwd -P)" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not the current directory; the caller cds to the root it names" >&2; exit 1; }`
**Legibility-target:** for-author

497c8cb5 turned need_root from a builtin test into one `$(pwd -P)` subshell per call, so each `inrepo`/`dirok`/`skipped` now pays two subshells (need_root's and blocker's) instead of one, about +20% per call (~0.32 of ~1.65 ms). A digest makes 11 such calls (+~3.5 ms, within run-to-run noise of the 421 ms total); the import walk makes one per instruction file and per import (49 on this repo, see the U0c report). It stays linear in inputs and is unobservable at today's counts. Note that the iteration-2 endorsement in `performance-reviewer-review-2026-10-05-build-loop-u0a.md` ("adds ~2 µs ... introduces no new fork or subshell") predates 497c8cb5 and is now stale for need_root; the `[[ -n ]]` half it described is still fork-free.

**Recommendation:** No change needed to land. If U1/U2 put need_root in a per-path loop at scale, a fork-free fast path such as `[[ "$PWD" == "$ROOT_REAL" ]] || [[ "$ROOT_REAL" == "$(pwd -P)" ]]` is not equivalent (a stale logical `$PWD` could pass), so any such change belongs to the security critic first; measure before changing.

## Endorsements

- The move is behaviour- and work-preserving for the digest: same output bytes and the same `inrepo`/`dirok`/`skipped`/`blocker`/`rawfile`/`realpath` call counts as main (5/2/4/11/41/62) in one traced run. [unverified — submitted as claim]
- Sourcing the lib adds ~0.6 ms per process start (two starts per run), a fixed cost independent of input size (override-log row 2026-10-05, performance I1, Won't-Fix). [unverified — submitted as claim]
- The `${ROOT_REAL:-}` guards in `rawfile`/`plaindir` are builtin tests ahead of the existing `realpath` fork and add no fork. [read: scripts/lib/dev-cycle-read.sh:77-80]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | need_root forks `$(pwd -P)` per file check | Informational | `scripts/lib/dev-cycle-read.sh:73-76` | High |

## Overall Assessment

U0a is a verbatim move with fail-closed guards; output is byte-identical and digest wall time is unchanged within noise (median 421 → 428 ms, spread ±10 ms plus one 849 ms outlier on main). The only new per-call cost is need_root's `$(pwd -P)` subshell (~0.3 ms per file check), cold and bounded by input count. Nothing to fix before landing.

## Goal-Alignment Note

Serves landing U0a after a clean loop: measured the digest against main (same bytes, same time), counted how often the new guard runs, and priced its fork. The one item is Informational and does not block; the stale prior endorsement is flagged so synthesis does not count it as Confirmed-Good. From the performance side U0a is clean to land.
