Commit: 7cbbe8d2

# Performance Review — feat/build-loop-u0b (pure move: FENCE_AWK, check_brief, check_branch, resolve_main)

**Scope:** `git diff feat/build-loop-u0a..feat/build-loop-u0b` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats)
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0b.md (Commit 7cbbe8d2)

## Data Flow and Hot Paths

The unit moves `FENCE_AWK` (an awk program held in a shell variable), `oddwhy`, `check_brief`, `check_branch`, and turns the top-level default-branch block into `resolve_main`. Path temperature: **cold**. `resolve_main` runs once per process; `check_brief` and `check_branch` run once per `--check-brief` / `--check-branch` argument, and the cycle passes a handful (open briefs, capped by slots at ≤9).

The three things the brief asks about:

- **When the default branch is resolved.** Unchanged. The call `resolve_main || [[ -n "$CHECK" ]] || { ...; exit 1; }` sits at `scripts/dev-cycle.sh:328`, the same place the inline block occupied (after all definitions, before the check-mode dispatch), and well after `scrub_reexec` at `:90`. So the git calls it makes (`symbolic-ref`, up to three `show-ref` + `rev-parse` pairs, possibly `symbolic-ref HEAD` + `rev-parse`) still run only in the scrubbed child, once, not in the parent. Defining the function at source time costs nothing at run time.
- **Extra spawns or file reads from sourcing.** The lib grows by ~170 lines of definitions; sourcing runs nothing (T29, extended in this unit). The parent and child each parse the extra text; measured at the stack tip, sourcing the whole 447-line lib costs ≈0.53 ms (see the u0a report for the method).
- **Per-call cost of the moved functions.** Unchanged: the bodies are verbatim (fact-check textual-diff claim). `check_brief` per call: a `blocker` walk (one subshell + `realpath` per path component), `git ls-tree | cut`, `git cat-file | awk`, and one or two `git log -1 ... -- <path>` history walks. That cost is pre-existing and settled; a second script calling it does not change it.

## Findings

No findings.

(Forward note, not a finding on this diff: `check_brief`'s `git log -1 --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a"` at `scripts/lib/dev-cycle-read.sh:247` walks first-parent history per brief, so its cost grows with history length × briefs checked. With ≤9 slots and a cycle that runs every ≤30 min this is cold; if U1's build-loop.sh calls `check_brief` per brief on every `--status`, that is the call to measure first. No baseline available — flagged as speculative.)

## Endorsements

- `resolve_main` is called at the same point in dev-cycle.sh as the inline block it replaces, so default-branch resolution still happens once, in the child only. (basis: read: scripts/dev-cycle.sh:90,328 and scripts/lib/dev-cycle-read.sh:278-299 at feat/build-loop-u0b) [unverified — submitted as claim]
- Moving `FENCE_AWK` into the lib leaves the awk program text unchanged, so `check_brief` and `check_answer` still pass the same program to one `awk` per file (no extra awk process, no extra pass). [unverified — submitted as claim]
- Sourcing the extended lib still invokes no git or perl. (basis: fact-check: T29 extended in this unit — executed, passing) [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

Nothing in my domain. The move adds only definitions to a sourced file; default-branch resolution keeps its timing and its once-per-process count, and the per-call cost of `check_brief` and `check_branch` is unchanged. The only performance question this code raises belongs to U1 (how often build-loop.sh calls `check_brief`), noted above as a forward, speculative item.

## Goal-Alignment Note

The goal is a pure move with dev-cycle.sh's behaviour unchanged. Performance-wise it is: no change in what runs, how often, or in which process (parent vs. scrubbed child). Nothing here blocks landing U0b.
