Commit: b5209cbc

# Architecture Review — feat/build-loop-u0a (U0a: scrub and file rules into the reader lib)

**Scope:** `git diff feat/build-loop-handoff..feat/build-loop-u0a` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats), read at tip b5209cbc with `git show`
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0a.md (Stage 1); plan rev 4 "Approach"; docs/reviews/architecture-review-build-loop-handoff.md (the plan-stage review the extraction was designed against)

Scope check: in scope (module structure: a new shared module `scripts/lib/dev-cycle-read.sh` and a new source-time dependency from `dev-cycle.sh`).

Trust-boundary cross-reference: active scan, no-op for this unit. The most recent security review is `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73` — security review predates this diff; boundaries may be stale). None of the findings below sits on its B1–B5 crossings: U0a moves the scrub and the plain-file rules, which are inputs to every boundary but not a boundary transition themselves.

Not re-filed (already in the fact-check report): the present-tense "shared by … build-loop.sh" (Claims 3a, 5), the Exit list missing the missing-lib exit (Claim 1), "the digest"/"section 8" wording now in the lib (Claim 12), "moved verbatim" covering the rewritten wrapper (Claim 17), and the commit Note misdescribing the plan on `check_fix` (Claim 22b; the placement question itself is assessed in the U0c report).

## Dependency Map

```
dev-cycle.sh ──source (from $SCRIPT_DIR/lib, no fallback)──▶ lib/dev-cycle-read.sh
dev-cycle.sh ──subprocess (SCRIPT_DIR, fallback ~/.claude/scripts)──▶ questions.sh   (unchanged)
lib/dev-cycle-read.sh ──▶ perl (scrub), realpath, bash (re-exec of the caller's own path)
```

The lib depends on nothing in the repo. Its inputs are the caller's process state, not arguments: the cwd (the repo root), `ROOT_REAL`, and `set -euo pipefail`. `scrub_reexec` takes the caller's own path as an explicit argument, so the lib does not depend on `BASH_SOURCE` resolution inside a sourced file. The direction is right: the volatile script depends on the stable reader, and nothing in the lib names `dev-cycle.sh` in code (only in comments). There are no cycles.

## Findings

#### 1. The re-exec marker `DEV_CYCLE_SCRUBBED` is now a lib-wide name, not a per-script one

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:54-59`
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** Medium
**Legibility target:** for-author

Evidence (tip b5209cbc):

```bash
scrub_reexec() {
  [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0
  local self="$1"; shift
  { DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub
  exit "${PIPESTATUS[0]}"
}
```
(the whole function)

The plan-stage review's finding 5 (option 2) suggested that `build-loop.sh` wrap itself "under its own marker variable". Moving the wrapper into the lib with the marker hard-coded makes the marker shared by every consumer. When `build-loop.sh` calls `scrub_reexec`, `DEV_CYCLE_SCRUBBED` will mean "some ancestor scrubbed this process tree", not "this script is the child". That is safe today: a child that skips its scrub still writes into a scrubbed parent's pipes, and rev 4 has neither script spawn the other. It becomes a trap if a consumer later runs the other script with its output going somewhere other than the parent's streams, or if a test that sets the variable for one script also disables the other's scrub without anyone noticing.

**Recommendation:** Decide this in U1, when `build-loop.sh` first calls `scrub_reexec`. Either say in the lib header that the marker is deliberately shared and means "already inside a scrubbed tree", or take the marker name as a parameter. No change in U0a.

#### 2. The lib's interface is process state: caller-set inputs and digest-only accumulators

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:6-10`, `:63`, `:73`, `:92`; `scripts/dev-cycle.sh:113`
**Move:** 1, 7
**Confidence:** High
**Legibility target:** for-orchestrator-synthesis

Evidence (tip b5209cbc):

```bash
# of scripts/ with its lib/ is self-contained. The caller sets -euo pipefail,
# cds to the repo root and sets ROOT_REAL (that root, symlinks resolved) before
# calling any file check.
...
rawfile() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
...
SKIPPED=(); SKIP_AT=""
...
skipped() { SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT"); }
```

The lib reads globals the caller sets (`ROOT_REAL`, the cwd) and writes globals the caller reads (`SKIP_AT`, `SKIPPED`). `SKIPPED` exists only to feed dev-cycle.sh's digest section 8 (`scripts/dev-cycle.sh:766-770`). For a bash lib with one consumer this is the pragmatic shape, and the header states the input contract, so this is not a defect. The cost arrives with the second consumer. `build-loop.sh` must reproduce the setup order exactly, and lib functions it calls (U0c's `check_answer` calls `skipped`) will grow an accumulator that it never reads. That accumulator is harmless, but it shows that one consumer's presentation state lives in the shared module.

**Recommendation:** Keep the shape. In U1, have `build-loop.sh`'s first test source the lib under its own setup and run one file check, so the caller contract is tested from the second side too. If a third piece of digest-only state ever moves in, split it out instead of growing the shared globals.

#### 3. Lib-change discipline is not written down where a lib editor will see it

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1-10`; `test/scripts/dev-cycle.bats` (T29/T30 appended at the end)
**Move:** 3
**Confidence:** Medium
**Legibility target:** for-author

Evidence (tip b5209cbc): the header lists the consumers (`# The dev cycle's reader, shared by scripts/dev-cycle.sh and scripts/build-loop.sh:`) but has no line saying that a change to the lib runs both suites. The lib's own contract tests (T29 "sourcing the reader lib defines its functions and runs nothing", T30 "a copy of dev-cycle.sh without its lib exits 1") live inside `dev-cycle.bats`.

The plan-stage review recommended both a header note (its finding 7: "changes run both test suites") and lib tests in their own file (its finding 6). The plan's step 1 names T29/T30 without a file. Putting them in `dev-cycle.bats` is defensible while dev-cycle.sh is the only consumer, since any lib edit already has to run that suite. Once the gate also depends on the lib, though, its contract tests will sit in a file named after one consumer.

**Recommendation:** In U1, add one header line: "a change here runs dev-cycle.bats and the build-loop-*.bats suites". Optionally move T29 into a lib-named file at the same time. Nothing to do in U0a.

## What Looks Good

- **One sourcing path, no fallback.** `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"`, with exit 1 when it is absent (`scripts/dev-cycle.sh:85-88`). Unlike `questions.sh`'s `~/.claude/scripts` fallback, the lib cannot come from a different tree than the script (plan-stage finding 3's concern), and D6's extracted copy of `scripts/` + `scripts/lib/` is self-contained.
- **`writable` and `isbrief` are in the lib.** This closes plan-stage finding 2: build-loop's N-list (F12/T14: `writable` plus `docs/dev-cycle.md`) can reuse the cycle-owned-file set instead of re-encoding it.
- **The scrub is shared.** Taking plan-stage finding 5's option 2 gives one sanitisation policy for both scripts instead of field-by-field defences in `build-loop.sh`.
- **The caller path is explicit.** `scrub_reexec` takes `$self` rather than reading `BASH_SOURCE` inside a sourced function, which would name the lib. That avoids the most likely mistake when moving top-level code into a function.
- **The source-time contract is tested.** T29 makes "defines only, runs nothing" a checked property rather than an assumption, which plan-stage finding 6 asked for.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `DEV_CYCLE_SCRUBBED` is now shared by every consumer | Informational | `scripts/lib/dev-cycle-read.sh:54-59` | Medium |
| 2 | Lib interface is caller-set globals plus a digest-only accumulator | Informational | `scripts/lib/dev-cycle-read.sh:6-10, 63, 73, 92` | High |
| 3 | "Run both suites" is not in the header; lib contract tests sit in dev-cycle.bats | Informational | `scripts/lib/dev-cycle-read.sh:1-10` | Medium |

## Overall Assessment

U0a keeps the system's structure sound and improves it. It creates the stable lower layer the plan called for, the dependency direction is right, and the sourcing path is pinned to the script's own tree. It also adopts three of the plan-stage review's recommendations: `writable` in the lib, the shared scrub, and a source-time contract test. All three findings are Informational. Each one points to a decision that belongs in U1, when `build-loop.sh` becomes the second consumer: the shared marker's meaning, a second-side contract test, and the both-suites note. None of them needs a change to land U0a. The most important open point is not in this unit's code: the commit Note's account of `check_fix` (fact-check Claim 22b). The U0c report assesses where that predicate belongs.

## Goal-Alignment Note

The goal is a pure move with dev-cycle.sh's behaviour unchanged and the 53 tests green. Stage 1's executed evidence (55/55 ok, a byte-identical digest) and this review agree that the move adds no structural regression. The new module boundary is the one the approved plan specified. Nothing here blocks landing U0a. The three Informational items are forward notes for U1 and need no review-fix iteration.
