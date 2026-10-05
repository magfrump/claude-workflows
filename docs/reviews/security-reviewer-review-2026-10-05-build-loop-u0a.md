Commit: e97eefce

# Security Review — feat/build-loop-u0a, iteration 2 (fix e97eefce: need_root, rawfile/plaindir fail closed)

**Scope:** `git diff feat/build-loop-u0a~1 feat/build-loop-u0a` (scripts/dev-cycle.sh comments, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats); move commit d7ea20b9 differs from the reviewed b5209cbc only in its message (range-diff checked)
**Date:** 2026-10-05
**Based on:** iteration-1 report docs/reviews/security-reviewer-review-2026-10-04-build-loop-u0a.md; rubric docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0a.md

> ⚠️ **No iteration-2 code fact-check report provided.** Claims about the new guard's comments were checked against executed probes below, not against a fact-check report.

## Prior findings

| Iteration-1 finding | Status | Evidence |
|---|---|---|
| 1. Symlink guard fails open without ROOT_REAL; `set -u` does not catch it (Low, B3) | **Resolved** | Executed (probe1.sh C4–C7, mutation run): `inrepo`, `dirok`, `skipped` now exit 1 with `ROOT_REAL is not set` before `blocker`'s subshell runs, in a `$(...)`, in an `if` condition, and with `set +e`; `blocker` called directly without ROOT_REAL now prints the first existing part (`[docs/] [real/] [linkdir/]`), i.e. refuses. |

## Trust Boundary Map

```
B3 (changed): [repo paths from repo text; working-tree entries/symlinks] → [need_root, then blocker/rawfile/plaindir vs ROOT_REAL] → [file reads (inrepo/dirok/skipped)]
B5 (new):     [caller's ROOT_REAL global (or its absence)]               → [need_root: non-empty test, outside $(...)]          → [exit 1, or the B3 checks run]
```

```
S4: repo-text paths and working-tree entries — repo-mutable — UNTRUSTED for read/path sinks
S5: ROOT_REAL — code-set by the sourcing script — trusted when set to the cwd's real path; need_root checks only that it is non-empty
```

The fix moves the ROOT_REAL precondition from prose to a check outside the command substitution, and makes rawfile/plaindir refuse when it is empty. A *wrong* but non-empty ROOT_REAL is not checked; it makes every read refuse (closed for reads).

## Findings

#### 1. The new test does not pin rawfile/plaindir's `-n ROOT_REAL` fail-closed clause

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:1046-1058` (guard at `scripts/lib/dev-cycle-read.sh:68,71`)
**Boundary:** B5
**Move:** #11 (bypass the guard)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (u0a tip):
```
rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
```
```
    run env LC_ALL=C bash -c 'source "$1"; rawfile real/f.md || echo closed; plaindir real || echo closed' _ \
```
Mutation run (mutate.sh, scratch worktree at the tip): deleting `-n "${ROOT_REAL:-}" &&` from both functions leaves the test **passing**, because with ROOT_REAL unset the comparison is against `/real/f.md`, which fails anyway unless the cwd is `/`. Deleting `need_root`'s body (`return 0`) makes the test fail at the stderr assertion, so the guard that matters is pinned. The `-n` clause only changes behaviour when cwd is `/` (or under `set -u`, where the unbound expansion would end the shell); not exploitable, defence in depth. No change needed unless the author wants the assertion to mean what its name says (run it with `cd /`).

**Recommendation:** Optional: run the rawfile/plaindir half from `/` with a path that exists there, or drop the claim that this half tests the clause.

## Untested bypass candidates

- ROOT_REAL set to a symlinked spelling of the root (e.g. `/workspace` via a link) by a future caller: every read refuses (closed); not executed for a symlinked spelling, but C1/C2/C3/C12 (relative, `/`, the symlink's target dir, trailing slash) all refused in probe1.sh. Closed for reads; for the import walk the same state is fail-open, see the U0c report.

(Tested candidates, all refused or exited 1: unset ROOT_REAL via `$(...)`, `if`, `set +e`; `ROOT_REAL=repo` (relative); `ROOT_REAL=/`; ROOT_REAL = the outside directory a committed symlink points at; trailing slash; `ROOT_REAL=/` exported in the env before sourcing.)

## Endorsement Claims

- **Claim:** With ROOT_REAL unset, `inrepo`, `dirok` and `skipped` exit the sourcing shell with status 1 and a stderr message, before any file is read, whether called directly, in an `if` condition, under `set +e`, or inside `$(...)` with `set -e`.
  **Location:** `scripts/lib/dev-cycle-read.sh:67,93,96,97`
  **Evidence:** executed
  **Verified:** probe1.sh C4, C5, C6 against the u0a-tip lib (identical lines at u0c); bats case at `test/scripts/dev-cycle.bats:1046` passes at the tip and fails when need_root is made a no-op.
  **Not verified:** a caller that runs these inside `$(...)` **without** `set -e` — the subshell exits, the outer assignment gets empty output and continues (the message still reaches stderr).
  **route: code-fact-check**
- **Claim:** A non-empty ROOT_REAL that is not the cwd's real path makes rawfile/plaindir refuse the probed paths (relative, `/`, symlink target dir, trailing slash).
  **Location:** `scripts/lib/dev-cycle-read.sh:68,71`
  **Evidence:** executed
  **Verified:** probe1.sh C1, C2, C3, C12: `refused` for a symlink and for a plain file.
  **Not verified:** ROOT_REAL spelled through a symlink.
  **route: code-fact-check**

## Primitive sweep

Primitive: path resolution / file read guard
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:68` rawfile `realpath -e` | S4, S5 | `-n ROOT_REAL`, compare to `$ROOT_REAL/$1` | cleared — closed when S5 empty or wrong (executed); Finding 1 (test does not pin `-n`) |
| `:71` plaindir `realpath -e` | S4, S5 | same | cleared — as above |
| `:93,96,97` inrepo/dirok/skipped | S4, S5 | need_root outside `$(...)` | cleared — prior Finding 1 resolved (executed) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | New test does not pin rawfile/plaindir's `-n ROOT_REAL` clause | Informational | B5 | `test/scripts/dev-cycle.bats:1046-1058` | High |

## Overall Assessment

The iteration-1 Low finding is closed: the precondition is now enforced outside the command substitution and the two primitive checks refuse on an empty root, and every bypass candidate probed either refused or exited 1. need_root checks presence, not correctness; a wrong root fails closed for reads (the U0c report covers the one place where read-refusal turns into fewer refusals). The only note is a test half that cannot fail. No findings within the code paths read; endorsement claims pending execution verification by code-fact-check.

## Goal-Alignment Note
- Success criterion (restated verbatim): one markdown report per unit at OUTPUT_PATTERN (unit = u0a, u0b, u0c), structured per your skill, first line `Commit: <unit tip short SHA>`, ending with the Goal-Alignment Note.
- Answered: yes — prior Low resolved (executed), need_root placement under set -e / `$(...)` / `if` probed, new test mutation-checked.
- Out of scope: the D6 hash-check note (override-log row 2026-10-05, deferred to U3b); verbatim-moved scrub.
- Escalate: none.
- Decisions I made: rated the untested `-n` clause Informational (behaviour differs only with cwd `/`).
