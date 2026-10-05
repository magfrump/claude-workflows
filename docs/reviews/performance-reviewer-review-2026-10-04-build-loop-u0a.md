Commit: b5209cbc

# Performance Review — feat/build-loop-u0a (pure move: scrub, scrub_reexec, file and path rules)

**Scope:** `git diff feat/build-loop-handoff..feat/build-loop-u0a` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats)
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0a.md (Commit b5209cbc)

## Data Flow and Hot Paths

dev-cycle.sh is a CLI run once per cycle step (the digest) or once per `--check-*` call; every run is a parent that re-execs itself as a scrubbed child (`scrub_reexec`), with two perl `scrub` filters in the pipeline. Path temperature: **cold** for the whole diff (process start-up and one-time setup); the per-item functions moved here (`blocker`, `inrepo`, `pathform`, `isbrief`, `writable`) were moved byte-for-byte (fact-check E1/E2) and their per-call cost is unchanged.

What the move changes in work per run:

- **Parent process, new work before the re-exec.** Previously the parent ran `command -v perl` and then the re-exec block, and exited without reading further. Now it also computes `SCRIPT_DIR` (one `$(...)` subshell plus one `dirname` exec), tests the lib exists, and sources the lib (one file open and parse). The child does the same again; in the child, `SCRIPT_DIR` was already computed before (it moved from after argument parsing to before the re-exec, fact-check claim on `:82`), so the child's net new work is only the `source`.
- **Default branch resolution:** not touched by this unit.
- **Per-call cost of the moved functions:** unchanged (same text, same callers). Calling them from a second script adds no cost to dev-cycle.sh.

Measured on this host (2026-10-04, scratch copies of the scripts, 30 runs each, `--check-path README.md` against this worktree): `feat/build-loop-handoff` dev-cycle.sh 20.7 ms/run; the stack tip (u0c, with the full lib) 21.1–21.5 ms/run. Isolated parts: `SCRIPT_DIR` resolution ≈ 0.93 ms; sourcing the full u0c lib (447 lines) ≈ 0.53 ms over a bare `bash -c`. U0a's lib is 129 lines, so its share is smaller.

## Findings

#### Parent process now pays a subshell, a `dirname` exec and a lib parse before re-exec

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:82-89`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (fixed per-run constant) / Cold path (process start-up, once per invocation)
**Confidence:** High
**Legibility-target:** maintainer
**Baseline:** 20.7 ms/run for `dev-cycle.sh --check-path README.md` at feat/build-loop-handoff, measured by this reviewer on 2026-10-04 (30-run loop, scratch copy); `SCRIPT_DIR` resolution measured at 0.93 ms/run in the same session.

Evidence (feat/build-loop-u0a):
```
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # before the cd: relative paths work
...
READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"
[[ -f "$READ_LIB" ]] || { echo "dev-cycle.sh needs $READ_LIB" >&2; exit 1; }
# shellcheck source=lib/dev-cycle-read.sh
source "$READ_LIB"
scrub_reexec "${BASH_SOURCE[0]}" "$@"
```
Because the lib holds `scrub_reexec`, the parent must locate and source it before it can re-exec, so the parent now does work it previously skipped: about 1–1.5 ms per invocation (≈2–4% of a check-mode run, measured end-to-end at the stack tip as +0.3 to +0.8 ms). It is a fixed constant per process, not per item, and dev-cycle.sh runs a handful of times per cycle, so it does not matter. It would matter only if a future caller (build-loop.sh's `--status` over N briefs) shelled out to dev-cycle.sh once per item at high N; the plan caps live loops at 9 slots, so it does not.

**Recommendation:** None needed. If build-loop.sh later needs per-item checks, have it source the lib and call the functions in-process rather than spawning dev-cycle.sh per item.

## Endorsements

- Sourcing the lib runs no external command (no git, no perl) at source time, so the parent's added cost is bounded to the parse and the `SCRIPT_DIR` subshell. (basis: T29 "sourcing the reader lib defines its functions and runs nothing", which stubs git and perl; the fact-check report records the two new tests passing) [unverified — submitted as claim]
- `scrub_reexec` keeps the one-pipeline, two-filter shape (no extra scrub process, no extra buffering stage) and the shell still waits for both filters. (basis: fact-check: claim 10 — Verified) [unverified — submitted as claim]
- The moved helpers' per-call cost is unchanged because the moved text is byte-identical except the wrapper. (basis: fact-check: E1 byte-identity — Verified) [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Parent now pays SCRIPT_DIR subshell + dirname + lib parse before re-exec (~1–1.5 ms/run) | Informational | `scripts/dev-cycle.sh:82-89` | High |

## Overall Assessment

No performance concern. The one change in work per run is a measured ~1 ms constant on a cold start-up path, the inevitable price of putting the re-exec wrapper in a sourced file. No loop gained an iteration, no per-item function changed, and default-branch resolution is untouched in this unit. No profiling beyond the timings above is needed.

## Goal-Alignment Note

The unit's goal is a pure move with dev-cycle.sh's behaviour unchanged. From a performance standpoint it meets that goal: the only measurable change is the ~1 ms start-up constant described above, which is inherent to sourcing the wrapper and is not a regression worth acting on. Nothing in this report blocks landing U0a.
