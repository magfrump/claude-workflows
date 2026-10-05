Commit: d8da1fba

# Architecture Review — feat/build-loop-u0c, final confirming pass

**Scope:** `git diff feat/build-loop-u0b..feat/build-loop-u0c` (3 commits: 41065ce6, 1c7373d3, d8da1fba, including the plan amendment) and their messages; U0a/U0b as context only
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u0c.md` (merged k=3, Commit d8da1fba); plan "Approach" with its 2026-10-05 amendment (`docs/working/plan-build-loop-handoff.md:192`); `docs/reviews/architecture-review-build-loop-handoff.md`; override-log rows 202–207, 210

Scope check: in scope (module structure, public API, and the plan's module-boundary list). U0c moves `INSTRUCTION_FILE`, the import walk (`lower`, `imported_names`, the `IMPORTED`/`IMPORTED_DONE` cache) and `ANSWER_AWK`/`check_answer` into the lib. It keys the walk's cache on the root and amends the plan's extraction list.

Trust-boundary cross-reference: active. The walk is **B2**'s transition point and `check_fix` is **B1**'s gate in `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73` — security review predates this diff; boundary may be stale).

Known items not re-filed:
- Fact-check claim 1: the header's exiting list omits `check_answer`.
- Claim 2: "F11's row below".
- Claim 3: the amendment drops "with no untracked instruction files" and "and test it".
- Claim 4: the rollback line.
- Claim 5 and override row 210.
- Override rows 202–207: `check_fix`'s predicate, `isimported`, the read-as-truth lists, the walk bound to the working tree, `check_answer` on F28, and the per-process cache.
- Iteration 2's findings 1 and 2 (the amendment's omissions and the move-commit wording) are **closed** at this tip. The amendment now carries the leading-dot test and the B2 note. F11 (`:126`) and step 13 carry the `MAIN_SHA` precondition. Both move messages (4ef450da, 41065ce6) say the predicate stays.

## Dependency Map

```
dev-cycle.sh check_fix ──▶ lib imported_names ──need_root (ROOT_REAL == pwd -P)──▶ git ls-files (tracked + --others) ──▶ inrepo
                       ──reads──▶ IMPORTED (newline-framed, lower-cased; row 203, isimported in U2)
dev-cycle.sh --check-answer ──▶ lib check_answer ──skipped (need_root)──▶ questions*.md in the working tree ──▶ FENCE_AWK + ANSWER_AWK
U2 floor (planned) ──▶ INSTRUCTION_FILE, imported_names (at MAIN_SHA per the amendment), writable, + new dot test, isimported
```

The direction is unchanged: lib ← dev-cycle.sh, and later lib ← build-loop.sh. Iteration 2's Informational finding 3 (the cache key is `ROOT_REAL` but the walk reads the cwd) is now enforced, not just documented: `need_root` at the walk's top requires `ROOT_REAL == $(pwd -P)` (U0a's 497c8cb5), so the key and the tree read cannot diverge. With this, the amendment's U1/U2 path is coherent:

- every shared piece the U2 floor needs (`INSTRUCTION_FILE`, the walk, `writable`) is in the lib;
- `check_fix` stays whole;
- `isimported` removes the cache-format coupling when the second user arrives;
- `check_answer` is in place for U1 to move to main's commit (D8).

One part of the path changes B2, and finding 1 covers it.

## Findings

#### 1. The amendment's "worktree at `MAIN_SHA`" option shrinks B2's start set for the gate: untracked and ignored instruction files drop out

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:192` (amendment), `:126` (F11 row); `scripts/lib/dev-cycle-read.sh:334-336`, `:360-362` at d8da1fba
**Move:** 3 (module boundary), 1 (what the gate's import set depends on)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (d8da1fba):

```
The import walk reads the working tree at `ROOT_REAL`, so the gate must run it in a worktree checked out at `MAIN_SHA` or use a commit-reading variant; F11's row below and step 13's Q-103 text now carry this precondition.
```
(plan `:192`, the amendment's sentence on the tree binding)

```
# instructions, so an in-cycle fix never edits it. The walk starts at every
# instruction file in the checkout, tracked or not (CLAUDE.local.md is usually
# gitignored), resolves each @path against the importing file's directory as
```
(lib `:334-336`)

```
B2: [instruction files: tracked, untracked, ignored, incl. node_modules] → [imported_names() walk :425-447: grep IMPORT_RE, realpath -ms, inrepo] → [IMPORTED refusal set]
```
(pass-38 security review, Trust Boundary Map)

By design, the walk's start set includes untracked and ignored instruction files (`git ls-files -z --others`, lib `:361`), because a personal `CLAUDE.local.md` is loaded as instructions in the user's own checkout. A fresh worktree at `MAIN_SHA` holds only tracked files. Fact-check claim 3's "clean worktree" correction pushes the same way. In that worktree, a file that only the user's `CLAUDE.local.md` imports is outside the gate's `IMPORTED` set. A loop could then self-merge an edit to it, and the user's next session would load the edited file as instructions. This is not one of the walk's known F11 gaps, which the amendment says U2 will confirm. It is a narrowing that the amendment's first option introduces. dev-cycle.sh's `check_fix` refuses the same file today because it walks the user's checkout. The amendment's either/or presents the two options as equivalent, and for B2 they are not: a commit-reading variant has the same narrowing unless it adds the checkout's untracked instruction files.

**Security implication:** this moves B2's source from "instruction files: tracked, untracked, ignored" to "tracked at `MAIN_SHA`" for the gate's sink. It is not a security finding. The combined U2 architecture/security review should decide it rather than inherit it.

**Recommendation:** Make it a plan-text edit now, or in U2 at the latest. Say that the gate's start set is the instruction files at `MAIN_SHA` **plus** the untracked and ignored instruction files of the orchestrator's checkout (the walk's current start set), and only the tracked import targets are read at `MAIN_SHA`. Alternatively, record the narrowing as an accepted gap in F11's Q-103 text. Add a U2 test: a gitignored `CLAUDE.local.md` imports `docs/x.md`, and the gate refuses a loop's edit to `docs/x.md`.

#### 2. `check_answer` joins the print-only, exiting family that the gate will capture

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:457-461` at d8da1fba
**Move:** 3, 7
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```bash
check_answer() {
  local a="$1" f r hit="" where="" n why
  if [[ ! "$a" =~ ^Q-[0123456789]+$ ]]; then echo "skip ${a//$'\n'/ }: not a question ID (Q- and digits)"; return; fi
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    if skipped "$f"; then echo "skip $a: $SKIP_AT is not a plain file or directory, so $f is not read"; return; fi
```
(excerpt ends inside check_answer. I read it to its close: every outcome is an echoed line, and `skipped` runs `need_root`.)

This has the same shape as U0b's finding 1, with a higher-stakes consumer. Plan D4 has `--merge … --approved Q-NNN` read the answer through this function after U1 moves it to main's commit. That makes `check_answer`'s line a merge authorisation, which build-loop.sh can only read by capturing it. When `ROOT_REAL` is unset, `if r="$(check_answer Q-001)"` continues with status 1 and an empty result (executed in scratch). A gate written as "refuse on `drop`/`skip`" would pass. Fact-check claim 1 already notes that the header's exiting list omits `check_answer`.

**Recommendation:** When U1 rewrites `check_answer` for main's commit, apply U0b finding 1's rule: capture by plain assignment, accept only a positive `keep` line, and add `main_by_name` to it as `check_brief` has. No change in U0c.

## What Looks Good

- **The amendment is now faithful and complete at the module boundary.**
  - `check_fix`'s predicate stays in dev-cycle.sh for good, which avoids a control-coupled policy switch.
  - The floor is a separate lib function built from shared parts.
  - `isimported` will remove the cache-format coupling.
  - Each U2 obligation from iteration 1 is written down: the leading-dot test, the read-as-truth list, and the B2 note.
- **The root-keyed cache is now safe.** With `need_root`'s cwd check, `IMPORTED_DONE == ROOT_REAL` identifies the tree the walk read. The single-slot cache gives the gate the extension point its worktree design needs, with no API change for `check_fix`.
- **The moves are verbatim and the boundary is explicit.** The header states which readers use main's commit and which use the working tree (`:19-22`). T29 checks that every lib global is declared.
- **The commit record is fixed.** No message in the range still frames `check_fix` as a deferred extraction.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Worktree-at-`MAIN_SHA` gate walk drops untracked/ignored instruction files (`CLAUDE.local.md`) from B2's start set | Minor | plan `:192`, `:126`; lib `:334-336`, `:361` | Medium |
| 2 | `check_answer` is print-only and exiting; `--approved` will capture it | Informational | lib `:457-461` | Medium |

## Overall Assessment

U0c completes the extraction cleanly. The lib now holds every shared piece the plan names except `brief_fields` (U1). The dependency graph is acyclic and points at the lib, and the amendment gives U1 and U2 a coherent path: one floor function beside an unchanged `check_fix`, a predicate in place of the cache format, and the walk run against main's tree. The one structural gap is in that last step. The amendment treats "a worktree at `MAIN_SHA`" as equivalent to the walk the cycle runs today, but the walk deliberately starts from the user's untracked instruction files, and a clean worktree has none. It is a one-sentence plan edit, or a U2 design choice that the combined review must make explicitly, and it does not affect U0c's code.

## Goal-Alignment Note

The goal is to land U0c after a clean loop. Iteration 2's two Minor items are closed. No Structural or Coupling finding exists. Finding 1 is Minor (🟢 Consider) and concerns plan text for U2, not U0c's code. It is cheapest to add the sentence to `:192` now, while the amendment is being written. Otherwise, record it in the override log with "Revisit trigger: U2's design of the gate's import walk", so the U2 author does not build the narrowing in. Finding 2 is Informational and is resolved when U1 rewrites `check_answer`.
