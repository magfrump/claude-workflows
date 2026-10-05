Commit: 698348ac

# Architecture Review — feat/build-loop-u0b, final confirming pass

**Scope:** `git diff feat/build-loop-u0a..feat/build-loop-u0b` (3 commits: 0b53fe50, fbe3a219, 698348ac) and their messages; U0a/U0c and the plan at the U0c tip as context only
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u0b.md` (merged k=3, Commit 698348ac); plan "Approach" with its 2026-10-05 amendment; `docs/reviews/architecture-review-build-loop-handoff.md`; override-log rows dated 2026-10-05

Scope check: in scope (public API). U0b adds `FENCE_AWK`, `oddwhy`, `check_brief`, `check_branch`, `resolve_main` and `main_by_name` to the lib's surface, and turns the default-branch resolution from top-level exiting code into a returning function.

Trust-boundary cross-reference: no-op. Neither finding sits on B1 or B2 of `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`).

Known items not re-filed:
- The fact-check's header sentence (claim 1), commit 0b53fe50's "returns 1" (claim 2) and the unverifiable build-loop.sh claim (claim 3).
- Override rows 201 (`git log -G` growth), 208 (main resolved in another repository) and 209 (origin/HEAD naming a loop-created branch).

## Dependency Map

```
dev-cycle.sh ──calls──▶ resolve_main (returns 1; dev-cycle.sh keeps its exit + message, :328)
dev-cycle.sh ──main_by_name──▶ exit 1 for --check-brief/--check-branch (:332, same predicate as the lib)
check_brief ──need_root (exit)──▶ main_by_name (skip) ──▶ pathform/isbrief ──▶ blocker ──▶ git ls-tree/cat-file/log at MAIN_SHA ──▶ FENCE_AWK
check_branch ──main_by_name (skip)──▶ git show-ref / rev-list at MAIN_SHA (no file reads, so no need_root)
```

The lib still depends on nothing in dev-cycle.sh. `MAIN`, `MAIN_SHA` and `MAIN_BY_NAME` are now lib-owned globals, initialised at source time and written only by `resolve_main`. The plan's plan-stage concerns 2 and 3 are resolved here: resolution returns instead of exiting, and the amended Approach has build-loop.sh resolve `MAIN_SHA` once and call the lib in-process, so there is no second snapshot of main.

## Findings

#### 1. The verdict functions print their answer, but the header forbids the only way an in-process caller can read it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:12-16` (header), `:236-239` (`check_brief`'s opening), at 698348ac
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (698348ac):

```
# calling any file check. inrepo, dirok, skipped and check_brief exit 1
# (need_root) when ROOT_REAL is unset or is not the current directory; rawfile,
# plaindir and blocker then read nothing as plain. Call the exiting checks in
# the caller's shell, not inside $(...) or `local x="$(...)"`, where an exit
# ends only the subshell.
```
(header `:12-16`)

```bash
check_brief() {
  local a="$1" st c n why
  need_root
  if ! main_by_name; then echo "skip ${a//$'\n'/ }: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi
```
(excerpt ends inside check_brief. I read the whole function: every outcome is an `echo` of an `ok …`/`skip …` line followed by `return`, and stdout is its only result channel.)

> "`build-loop.sh` resolves `MAIN_SHA` once and calls the lib directly, with no subprocess." (plan Approach, `docs/working/plan-build-loop-handoff.md:194`)

dev-cycle.sh can follow the header's rule because it passes `check_brief`'s line straight through to its own stdout. build-loop.sh cannot. `--status`, `--check` and `--merge` need the brief's state as data: they fold it into `ok BRIEF STATE POLICY …` and gate on `open`. The only in-process ways to get it are `$(...)`, `< <(...)` or a temp file, and the header forbids the first. Which pattern the U1 author picks decides whether `need_root` still fails closed. I tested this against the lib with `ROOT_REAL` unset:

- Plain `st="$(check_brief …)"` under `set -e` stops the caller. It fails closed.
- `if out="$(check_answer Q-001)"` continues with status 1 and an empty `out`.
- `while read …; done < <(check_brief …)` reads **0 lines and the caller continues**. Any gate that refuses on a `skip` line, rather than requiring an `ok` line, then passes.

So the interface and its usage rule conflict for exactly the consumer the lib was extracted for. The safe pattern exists, but nothing names it.

**Recommendation:** This needs a header sentence now, or in U1 before build-loop.sh's first call. The sentence: "a caller that consumes a check's line captures it by plain assignment (`x="$(check_brief …)"` under `set -e`) or calls `need_root` itself first; never `local x="$(…)"`, `if x="$(…)"` or `< <(…)`, and it treats any line that is not `ok` as a refusal". Alternatively, in U1, split a data core (for example `brief_state` setting `BRIEF_STATE`/`BRIEF_SHA`) from the printing wrapper, which would also give `brief_fields` (plan-stage finding 1) one Status reader to share.

#### 2. Two caller-contract violations take two different channels

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:228` (`main_by_name`), `:239` and `:285` (the skips), `:297-324` (`resolve_main`), at 698348ac
**Move:** 3, 6 (substitutability of "found")
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```bash
main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }
```
(`:228`, whole)

```
# The default branch: sets MAIN (its name), MAIN_SHA and MAIN_BY_NAME (1 when the
# name is origin/HEAD's, main or master, not the current branch's), and returns 1
# when MAIN_SHA is empty.
```
(`resolve_main`'s comment. I read the function to its close: it returns 0 for the current-branch fallback.)

The lib's guards follow a sound three-way rule:

1. A broken caller contract exits: `need_root`.
2. A repo-wide state returns a status and leaves the policy to the caller: `resolve_main`.
3. A per-argument verdict prints a `skip` line.

"`resolve_main` has not run" is a broken caller contract too, but it lands in the third channel, as a per-argument `skip` with exit 0 that looks the same as a repo-state skip. The fail-closed outcome is correct, and api-consistency already made the message name the cause. Two consequences for later units are not written down anywhere:

- **The gate must treat every non-`ok` line as a refusal.** This links to finding 1.
- **`resolve_main`'s return code does not mean "the default branch was found".** A return of 0 also covers the current-branch fallback. U3's `--merge`, which does a CAS onto `refs/heads/$MAIN`, must gate on `main_by_name`, as dev-cycle.sh does at `scripts/dev-cycle.sh:332`, not on `resolve_main`'s status. Otherwise it could merge into whatever branch is checked out.

**Recommendation:** Add the three-way rule, with `main_by_name` named as the one predicate for "main found by name", in one header sentence, in U1 at the latest. Carry "--merge and --start require `main_by_name`, not `resolve_main`'s status" into U3's test list.

## What Looks Good

- **The resolution returns instead of exiting.** `resolve_main` sets three globals, returns a status, and leaves dev-cycle.sh's message and exit code where they were (`scripts/dev-cycle.sh:328`). This follows plan-stage finding 2's recommendation exactly.
- **One predicate, two policies.** dev-cycle.sh's early exit and the lib's per-argument skip now both call `main_by_name` (698348ac). The condition lives in one place, and each script keeps its own exit policy.
- **The guard lives inside the function.** `check_brief` and `check_branch` refuse to answer without main found by name, so a second caller cannot get a landed brief read as `new`. The test covers both the not-run and the fallback case.
- **Only file readers carry `need_root`.** `check_branch` reads only refs, so it has no `need_root`. The guard marks exactly the functions that depend on the cwd.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Print-only verdicts vs the "not inside `$(...)`" rule; `< <(…)` fails open for an in-process caller | Minor | lib `:12-16`, `:236-239` | Medium |
| 2 | Unrun `resolve_main` is a skip, not an exit; `resolve_main`'s 0 is not "found by name" | Informational | lib `:228`, `:297-324` | Medium |

## Overall Assessment

U0b improves the structure. The default branch becomes a returning lib function with one predicate, and the brief and branch checks carry their own preconditions, so they can be called from a second script without dev-cycle.sh's surrounding code. Both findings are about how the second caller will consume this surface, and neither changes dev-cycle.sh's behaviour. The most important one is finding 1: the lib's only result channel for `check_brief` is stdout, the header forbids capturing it, and one natural capture pattern fails open. One header sentence fixes it now, and U1 can fix it in the structure.

## Goal-Alignment Note

The goal is to land U0b after a clean loop. No Structural or Coupling finding remains. The prior iterations' Coupling item (rubric A1) is closed. Finding 1 is Minor (🟢 Consider) and finding 2 is Informational, so neither blocks the merge. Finding 1 is cheapest as a header sentence before U1 starts, because U1's `--status` is the first code that will capture `check_brief`. If the loop lands without it, record it in the override log with "Revisit trigger: U1's first in-process call to check_brief". Finding 2's `--merge` note belongs in U3's tests.
