Commit: a57e5d27

# Security Review — feat/build-loop-u0c, iteration 2 (fix a57e5d27: walk need_root, root-keyed import cache)

**Scope:** `git diff feat/build-loop-u0c~1 feat/build-loop-u0c` (lib, dev-cycle.sh comment, bats, plan amendment); `git range-diff 27e38dc4^! feat/build-loop-u0c~1^!` (commit message, header comments, T29 list — checked, no code change)
**Date:** 2026-10-05
**Based on:** iteration-1 report docs/reviews/security-reviewer-review-2026-10-04-build-loop-u0c.md; rubric docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0c.md

> ⚠️ **No iteration-2 code fact-check report provided.** Claims below rest on executed probes and a mutation run.

## Prior findings

| Iteration-1 finding | Status | Evidence |
|---|---|---|
| 1. Import walk returns an empty set without ROOT_REAL (Low, B1) | **Resolved** | `need_root` is the walk's first statement, before `IMPORTED_DONE` is set (`scripts/lib/dev-cycle-read.sh:339-340`); executed: probe1.sh C11 (walk inside `$(...)`, `set -e`) exits 1 with `ROOT_REAL is not set`; bats case `:1086` fails when the line is removed. |
| 2. Working-tree check_answer in the shared lib ahead of U1 (Informational) | Deferred (override-log 2026-10-05, U1) — not made worse; check_answer now exits 1 without ROOT_REAL (C13). |
| 3. Import-set cache not keyed to the root it walked (Informational) | **Resolved as recommended** | `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'`; bats case recomputes for a second root; reverting the key makes it fail (`[ docs/a.md docs/a.md ]`). Residual: see Finding 1. |

## Trust Boundary Map

```
B1 (changed): [instruction files and @tokens in the WORKING TREE of the cwd] → [need_root; cache key ROOT_REAL; inrepo; realpath -ms vs ROOT_REAL] → [IMPORTED set → check_fix refusal]
B6 (new):     [caller's (cwd, ROOT_REAL) pair]                                → [cache hit test on ROOT_REAL alone]                                  → [IMPORTED reused or recomputed]
```

```
S1: instruction-file text and @tokens — repo-mutable — UNTRUSTED for path sinks; under-reading means under-refusing
S4: ROOT_REAL — caller-set; need_root checks non-empty only
S6: cwd — caller-set; git ls-files lists the cwd's repository, inrepo compares realpaths against ROOT_REAL
```

check_fix in dev-cycle.sh is unaffected by the key change: dev-cycle.sh never changes directory after `cd "$ROOT"` (`scripts/dev-cycle.sh:114`), sets ROOT_REAL once (`:116`) and calls check_fix in the main shell (`:197`), so the walk still runs once per process.

## Findings

#### 1. The cache key and the walk read different things: with cwd ≠ ROOT_REAL the walk returns an empty (or another tree's) import set, and the read guard's fail-closed becomes fail-open for the refusal

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:337-365` (need_root `:73`)
**Boundary:** B1, B6
**Move:** #3 (error path polarity), #4 (cached check), #11
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (u0c tip):
```
  need_root
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'
  while IFS= read -r -d '' f; do
    if [[ ! "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]] || ! inrepo "$f"; then continue; fi
```
```
need_root() { [[ -n "${ROOT_REAL:-}" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not set; …" >&2; exit 1; }; }
```
Probe (probe1.sh, repo whose `AGENTS.md` imports `@docs/imp.md`, second repo importing `@docs/o.md`):
```
--- C9 walk: cwd=repo, ROOT_REAL=other
[ ]
--- C10 walk at repo, then cd other without updating ROOT_REAL
[ docs/imp.md ]
--- C12 ROOT_REAL with trailing slash
[ ]
```
For reads, a ROOT_REAL that is non-empty but not the cwd's real path refuses everything (closed). The walk inverts that: every instruction file fails `inrepo`, so nothing is recorded, the empty set is cached under that key, and a check_fix-style denylist then lets an @-imported file through. C10 is the stale-key case: after `cd` without updating ROOT_REAL the cache hit returns the first tree's set. Neither is a regression (both behaved the same at iteration 1, where I listed the wrong-root case as untested), and dev-cycle.sh cannot reach them. They matter because the plan amendment added in this commit says the gate "must run it in a worktree checked out at `MAIN_SHA`" — a caller that changes directory and must keep ROOT_REAL in step by hand, with need_root checking only that the variable is non-empty. Rated Low under the same rule as iteration 1 (no caller reaches it yet); it meets the Medium floor once U2's gate cds into a worktree.

**Recommendation:** Make need_root check the pair, not just presence: `[[ -n "${ROOT_REAL:-}" && "$ROOT_REAL" == "$(pwd -P)" ]]` (one fork; the checks already fork for blocker), which closes C9, C10 and C12 and keeps the cache key meaningful. Or, at minimum, have the walk refuse to cache (or exit) when no instruction file in `git ls-files` passed inrepo. Add a bats case: walk with ROOT_REAL pointing at another repo → exit 1.

#### 2. check_brief calls blocker without need_root; without ROOT_REAL every brief skips with a misleading reason and status 0

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:236`
**Boundary:** B1 (shared file guard)
**Move:** #3
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence:
```
  if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi
```
probe1.sh C14 (main found by name, ROOT_REAL unset): both an existing and an absent brief print `skip …: reached through a symlink, or not a regular file`, then `continued`, exit 0. Closed (no wrong verdict), thanks to e97eefce's rawfile/plaindir clause, but it is the one lib entry point that reads ROOT_REAL without the guard the header promises ("a check run without it exits 1"). Introduced in U0b; filed here because it is part of the same need_root contract.

**Recommendation:** Add `need_root` at the top of check_brief (one line), so the header's promise holds for every file check.

## Untested bypass candidates

- B1: ROOT_REAL spelled through a symlinked path while cwd is the real root — expected: same as C12 (empty walk), not executed.
- B6: instruction files edited after the first walk in the same process (a long-running build-loop.sh): the cache is keyed on the root, not the tree's content, so a newly added `@import` is not seen until the process restarts. Not executed; no long-running caller exists yet.

## Endorsement Claims

- **Claim:** imported_names exits 1 with the ROOT_REAL message before setting IMPORTED_DONE when ROOT_REAL is unset, including inside `$(...)` under `set -e`.
  **Location:** `scripts/lib/dev-cycle-read.sh:339-340`
  **Evidence:** executed
  **Verified:** probe1.sh C11; bats case `test/scripts/dev-cycle.bats:1086` passes at the tip and fails when the `need_root` line is deleted (mutate.sh: `line 339: ROOT_REAL: unbound variable`, status assertion fails).
  **Not verified:** a caller without `set -e` that ignores the subshell's status.
  **route: code-fact-check**
- **Claim:** The walk recomputes when ROOT_REAL changes to another repository root after a matching `cd`.
  **Location:** `scripts/lib/dev-cycle-read.sh:340`
  **Evidence:** executed
  **Verified:** bats case output ` docs/a.md ` then ` docs/b.md `; with the old `IMPORTED_DONE=1` key it prints `docs/a.md` twice (mutate.sh).
  **Not verified:** cwd and ROOT_REAL out of step (Finding 1).
  **route: code-fact-check**
- **Claim:** dev-cycle.sh's check_fix sees one walk per process, as before the key change.
  **Location:** `scripts/dev-cycle.sh:114-116,174,197`
  **Evidence:** read-static
  **Verified:** single `cd "$ROOT"`, single ROOT_REAL assignment, check_fix called in the main shell.
  **Not verified:** the full bats suite at the tip (only the new case and its mutations were run).

## Primitive sweep

Primitive: path resolution / file read
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:342` `inrepo "$f"` | S1, S4, S6 | need_root, blocker | Finding 1 (wrong root → skipped → under-refusal) |
| `:360` `realpath -ms --relative-to="$ROOT_REAL"` | S1, S4 | need_root at `:339`; `~`/`/`/`..*` dropped | cleared for unset root; Finding 1 for wrong root |
| `:363` `inrepo "$p"` | S1, S4 | need_root, blocker | Finding 1 |
| `:236` check_brief `blocker` | S3, S4 | rawfile/plaindir `-n` clause only | Finding 2 (closed, misleading, no need_root) |
| check_answer `skipped "$f"` (`:451`) | S2, S4 | need_root | cleared — exits 1 without ROOT_REAL (C13) |

Primitive: git invocation
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:350-351` git ls-files | none from input; lists the cwd's repo (S6) | fixed pathspec | cleared for arguments; S6/S4 mismatch is Finding 1 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Walk caches an empty or foreign import set when cwd ≠ ROOT_REAL (need_root checks presence only) | Low | B1, B6 | `scripts/lib/dev-cycle-read.sh:337-365` | High |
| 2 | check_brief reads ROOT_REAL via blocker without need_root (closed, misleading skip, status 0) | Informational | B1 | `scripts/lib/dev-cycle-read.sh:236` | High |

## Overall Assessment

Both iteration-1 items on the walk are closed as recommended: the walk stops on a missing root before caching, and the cache recomputes for a new root; the new test fails under each mutation. The residual is that "root" is now the cache key but need_root checks only that ROOT_REAL is non-empty, not that it is the directory being walked, and for the walk a wrong root fails open (fewer refusals). Unreachable through dev-cycle.sh; worth closing before U2's gate cds into a worktree at MAIN_SHA, by having need_root compare ROOT_REAL with `pwd -P`. No findings within dev-cycle.sh's code paths; endorsement claims pending execution verification by code-fact-check.

## Goal-Alignment Note
- Success criterion (restated verbatim): one markdown report per unit at OUTPUT_PATTERN (unit = u0a, u0b, u0c), structured per your skill, first line `Commit: <unit tip short SHA>`, ending with the Goal-Alignment Note.
- Answered: yes — prior Low and the cache Informational resolved (executed); cache-key effect on check_fix traced; new test mutation-checked against both guards; wrong-root and stale-root bypasses probed.
- Out of scope: check_fix predicate placement and IMPORTED format (override-log 2026-10-05, deferred to U2); working-tree check_answer (deferred to U1).
- Escalate: for-orchestrator-synthesis — Finding 1 bears on the plan amendment's "run it in a worktree at MAIN_SHA" path for U2; one need_root change in U0a's function closes it for every check.
- Decisions I made: kept Finding 1 at Low (unreachable today, same rule as iteration 1), and filed the U0b-introduced check_brief gap here as Informational because it belongs to the need_root contract.
