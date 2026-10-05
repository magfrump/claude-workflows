Commit: e97eefce

# Architecture Review — feat/build-loop-u0a, iteration 2 (fix e97eefce)

**Scope:** `git diff feat/build-loop-u0a~1 feat/build-loop-u0a` (scripts/dev-cycle.sh header, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats). The move commit d7ea20b9 differs from the reviewed b5209cbc only in its message.
**Date:** 2026-10-05
**Based on:** iteration-1 report `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0a.md`; rubric `docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0a.md`; override-log rows dated 2026-10-05.

> ⚠️ **No code fact-check report provided for iteration 2.** Architectural claims in the new comments were checked against the code by this reviewer only.

Scope check: in scope. The fix adds a lib function (`need_root`) and changes the lib's failure contract. The trust-boundary scan is a no-op, as in iteration 1: no finding below sits on a B1–B5 crossing of `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`; that review predates this diff, so the boundary may be stale).

## Status of iteration-1 items

| Item | Status |
|---|---|
| Rubric A1–A4 (Must Address; none of them from architecture) | All four were fixed in e97eefce or d7ea20b9. Structurally, A3 (fail-open with no ROOT_REAL) is closed: `need_root` runs outside the `$(blocker …)` substitution (lib `:93`, `:96-97`), and `rawfile`/`plaindir` fail closed (`:68`, `:71`). |
| Arch I1 (shared `DEV_CYCLE_SCRUBBED` marker) | Resolved. The header now says "Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker." (lib `:10-11`). |
| Arch I2, I3 | Deferred to U1 (override-log rows 196, 197). The fix does not make either worse. |

## Dependency Map

```
dev-cycle.sh ──source──▶ lib/dev-cycle-read.sh      (unchanged)
lib inrepo / dirok / skipped ──▶ need_root ──exit 1──▶ the calling process
lib rawfile / plaindir ──▶ ROOT_REAL (empty → "not plain")
```

The fix adds no new module dependency. What it changes is the lib's failure contract. Until now every lib function reported through its return status or a printed line, and `resolve_main` was written to return instead of exiting. Now one class of failure ends the caller's process.

## Findings

#### 1. The lib now has an exiting failure path; the rule that separates it from "return" is implicit

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:64-67`, `:93-97`, header `:9-11`
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** Medium
**Legibility target:** for-orchestrator-synthesis

Evidence (tip e97eefce):

```bash
need_root() { [[ -n "${ROOT_REAL:-}" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not set; the caller sets it before any file check" >&2; exit 1; }; }
...
inrepo() { need_root; [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }
...
skipped() { need_root; SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT"); }
```
(each function quoted whole)

The brief asked whether exiting from a lib cuts against the "returns instead of exiting" direction set for `resolve_main`. I judge that it does not. A missing default branch is a state of the repo, and each script picks its own policy for it, which is why `resolve_main` returns. A missing ROOT_REAL is a caller bug that no consumer can recover from. Stopping is the only fail-closed answer, and exit 1 matches dev-cycle.sh's "1 bad usage" code. The cost is in legibility. The header states the effect ("a check run without it exits 1 (need_root)") but not the rule behind it, so a U1 author adding a lib function has nothing telling them which channel to use. The guard has one more limit, which the comment at `:64-66` explains for `blocker` but which the header does not pass on to callers: `need_root` stops the process only when the check runs in the caller's own shell. A consumer that writes `local v="$(check_answer …)"` hides the exit.

**Recommendation:** Add one header clause in U1 (or now): "a broken caller contract (ROOT_REAL unset) exits 1; a state of the repo never exits and is a return status or a `skip` line. Call the checks in the caller's shell, not inside a `local x=$(…)`". No code change.

## What Looks Good

- **The guard sits at the boundary.** The precondition is enforced inside the module that depends on it rather than in each caller, which is the same shape the U0b fix uses for `main_by_name`.
- **Defence in depth without behaviour drift.** `rawfile`/`plaindir` fail closed on their own, so even a `blocker` call inside a subshell cannot read a symlink as plain. dev-cycle.sh sets ROOT_REAL at `scripts/dev-cycle.sh:116`, before any check, so its output is unchanged.
- **The test can fail.** With `need_root` turned into a no-op, "the lib's file checks stop, not pass, when the caller has not set ROOT_REAL" fails. I ran this mutation in a scratch worktree at the U0c tip, which contains the same code. The full suite is 59/59 at the U0c tip.
- **The comments name the planned consumer.** The header and `scripts/dev-cycle.sh:83-84` now call build-loop.sh "planned", so the module's stated consumers match reality.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Exiting failure path is principled, but the exit-vs-return rule and the "not inside `$(…)`" limit are not in the header | Informational | `scripts/lib/dev-cycle-read.sh:9-11, 64-67, 93-97` | Medium |

## Overall Assessment

The fix keeps U0a's structure sound and closes the one boundary weakness the loop found (A3). The precondition is now enforced inside the lib, fails closed at two layers, and is tested. The new exit path does not add coupling: it fires only on a broken caller contract, which no consumer can handle, so it does not conflict with `resolve_main`'s returns-not-exits contract. The only gap is that the header does not write that rule down for the next contributor. That is Informational and needs no further iteration.

## Goal-Alignment Note

The goal is to land U0a after a clean loop. No Structural or Coupling findings remain, all four rubric Must Address items are closed, and dev-cycle.sh's behaviour is unchanged (the ROOT_REAL guard cannot fire from dev-cycle.sh, and 59/59 tests pass at the stack tip). From the architecture lens, U0a is ready to land. Finding 1 is a header sentence that U1 can carry.
