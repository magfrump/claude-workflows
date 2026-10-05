Commit: 27e38dc4

# Security Review — feat/build-loop-u0c (U0c: INSTRUCTION_FILE, the @-import walk, ANSWER_AWK and check_answer moved into the lib)

**Scope:** `git diff feat/build-loop-u0b..feat/build-loop-u0c` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats)
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0c.md (Claims 4, 10b, 11)

## Trust Boundary Map

```
B1 (moved): [instruction files and @path tokens in repo text (tracked or untracked)] → [imported_names: INSTRUCTION_FILE, inrepo, realpath -ms vs ROOT_REAL, ..-prefix drop] → [IMPORTED set → check_fix refusal]
B2 (moved): [docs/working/questions{,-archive}.md in the WORKING TREE]               → [check_answer: skipped(), FENCE_AWK+ANSWER_AWK]                     → [keep/drop/done verdict]
B3 (moved): [question ID argument]                                                  → [^Q-[0-9]+$ check]                                                    → [awk -v id=]
```

```
S1: instruction-file text and @-tokens — repo-mutable, including gitignored files in the working tree — UNTRUSTED for path sinks; its only effect is to add refusals (over-reading over-refuses)
S2: questions files in the working tree — runtime-mutable by any loop writing under /workspace (plan F28) — UNTRUSTED as a source of answers for autonomous unblocking
S3: question ID from repo text         — UNTRUSTED for awk -v (escape processing) — validated ^Q-digits
S4: ROOT_REAL                          — caller-set — see U0a Finding 1
```

The walk and the answer reader moved verbatim. Two move-induced effects matter: the walk's correctness now depends on the same ROOT_REAL precondition as U0a's guard (and fails open the same way), and a working-tree answer reader is now exported to a second script before U1 moves it to main's commit.

## Findings

#### 1. imported_names silently returns an empty import set when ROOT_REAL is unset, disabling the "imported as instructions" refusal

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:319-347`
**Boundary:** B1
**Move:** #3 (error path)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (u0c tip):
```
    if [[ ! "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]] || ! inrepo "$f"; then continue; fi
```
```
      p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$t" 2>/dev/null)" || continue
```
Same root cause as U0a Finding 1: both ROOT_REAL reads sit in command substitutions, so `set -u` kills only the subshell and the loop `continue`s. Probe (`probe.sh` in this unit's scratch dir: repo with `AGENTS.md` containing `@docs/x.md`):
```
with ROOT_REAL: $'\ndocs/x.md\n'
no ROOT_REAL, no -u: $'\n'
…/lib.sh: line 65: ROOT_REAL: unbound variable
…/lib.sh: line 341: ROOT_REAL: unbound variable
no ROOT_REAL, -u: $'\n'
exit(-u)=0
```
`IMPORTED_DONE=1` is then set, so the empty set is cached for the process. A caller that forgets ROOT_REAL would let a fix/merge rule treat an @-imported file as ordinary documentation — the plan's check_fix floor (D5) is exactly this predicate. Unreachable through dev-cycle.sh (`ROOT_REAL` set at `scripts/dev-cycle.sh:115` before any check); Medium-floor once build-loop.sh sources the lib.

**Recommendation:** Fold into U0a Finding 1's fix: call the same `need_root` guard at the top of `imported_names` (outside any `$(...)`), before `IMPORTED_DONE=1` is set.

#### 2. A working-tree answer reader is now part of the shared lib before U1 moves it to main's commit

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:428-447`
**Boundary:** B2
**Move:** #1
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
  for f in docs/working/questions.md docs/working/questions-archive.md; do
```
```
    r="$(env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f")"
```
The commit message says so (`check_answer still reads the working tree; U1 moves it to main's commit (D8)`, fact-check Claim 11 Verified), and plan F28 names forged working-tree answers as the threat. Nothing is wrong in this unit; the note is an ordering constraint: build-loop.sh must not call `check_answer` for any autonomous decision (`--merge --approved`, unblocking) until U1's main-commit reader replaces it. Recorded so the synthesis carries it into U1's review.

**Recommendation:** None for U0c. In U1, replace the function rather than adding a second one beside it, so no caller can keep the working-tree variant.

#### 3. imported_names' process-lifetime cache is not keyed to the tree it walked

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:316-321`
**Boundary:** B1
**Move:** #4 (TOCTOU)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
IMPORTED=$'\n'; IMPORTED_DONE=""
```
```
  [[ -n "$IMPORTED_DONE" ]] && return; IMPORTED_DONE=1
```
"Computed once" was safe in a one-shot dev-cycle.sh that never changes directory after `cd "$ROOT"`. As a library, a caller that walks one checkout (e.g., main's) and then evaluates paths after `cd` into another (a loop worktree, or an extracted MAIN_SHA tree) gets the first tree's import set. Not reachable today.

**Recommendation:** Key the cache to `$ROOT_REAL` (recompute when it differs from the root recorded at computation), or document that the caller must not change root after the first call.

## Untested bypass candidates

- B1: an @-token whose `realpath -ms` result starts with `..` only after symlink-free normalisation of a directory named like `..foo` — the `[[ "$p" != ..* ]]` test also drops `..foo/x.md`, which only under-records (a missed refusal). Pre-existing and moved verbatim; not tested.
- B1: an instruction file reachable only through a symlinked directory is skipped by `inrepo`, so its imports are not recorded (under-refusal). Pre-existing; not tested.

## Endorsement Claims

- **Claim:** The moved git and grep calls in the walk do not depend on dev-cycle.sh's exported `GIT_LITERAL_PATHSPECS=1`: the first listing has no pathspec, the second sets `GIT_LITERAL_PATHSPECS=0` itself, and grep takes `--`.
  **Location:** `scripts/lib/dev-cycle-read.sh:331-333, 345`
  **Evidence:** read-static
  **Verified:** `git ls-files -z` / `GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'` / `grep -oE "$IMPORT_RE" -- "$f"`.
  **Not verified:** a caller that exports `GIT_LITERAL_PATHSPECS=0` and calls check_brief (U0b) — pathform excludes `:` `*` `?` `[`, so no magic is expressible; not executed.
  **route: code-fact-check**
- **Claim:** The question ID reaches `awk -v` only after `^Q-[0123456789]+$`, so awk's escape processing of `-v` values has nothing to act on.
  **Location:** `scripts/lib/dev-cycle-read.sh:430, 434`
  **Evidence:** read-static
  **Verified:** `if [[ ! "$a" =~ ^Q-[0123456789]+$ ]]; then … return; fi` precedes the awk call in the same function.
  **Not verified:** the caller's locale for `[[ =~ ]]` (digits listed one by one, so range folding does not apply).
  **route: code-fact-check**

## Primitive sweep

Primitive: path resolution / file read
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:323` `inrepo "$f"` | S1 names, S4 | blocker vs ROOT_REAL | Finding 1 (S4 unset) |
| `:341` `realpath -ms --relative-to` | S1 tokens, S4 | `~`/`/` dropped, `..*` dropped | Finding 1 (S4 unset); otherwise cleared — verbatim |
| `:344` `inrepo "$p"` | S1, S4 | blocker | Finding 1 |
| `:345` `grep -oE … -- "$f"` | S1 file (passed inrepo) | `--` | cleared |
| `:432-434` skipped/awk on questions files | S2 | skipped() blocker | Finding 2 (working tree); symlink guard also subject to U0a Finding 1 |

Primitive: git invocation
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:331-332` git ls-files | none from input | fixed pathspec | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Import walk returns an empty set without ROOT_REAL (`set -u` does not catch it) | Low | B1 | `scripts/lib/dev-cycle-read.sh:319-347` | High |
| 2 | Working-tree check_answer exported to the shared lib ahead of U1 | Informational | B2 | `scripts/lib/dev-cycle-read.sh:428-447` | High |
| 3 | Import-set cache not keyed to the root it walked | Informational | B1 | `scripts/lib/dev-cycle-read.sh:316-321` | Medium |

## Overall Assessment

A faithful move: dev-cycle.sh still sets ROOT_REAL before any check, and the walk's and answer reader's behaviour through dev-cycle.sh is unchanged. The move's security effects are all about the second caller: the walk shares U0a's fail-open on a missing ROOT_REAL (one guard fixes both), its cache assumes one root per process, and the working-tree answer reader must not be used for autonomous decisions until U1. The single most important action is U0a Finding 1's guard, applied to `imported_names` too. No findings within dev-cycle.sh's code paths; endorsement claims pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-reviewer-review-2026-10-04-build-loop-u0c.md, structured per the skill, with `Commit: <reviewed tip short SHA>` as its first line.
- Answered: yes — move effects on the walk (ROOT_REAL, cache, pathspec env) and on check_answer reviewed; ROOT_REAL omission probed.
- Out of scope: ANSWER_AWK/FENCE_AWK parsing semantics and @-token grammar (moved verbatim, settled 2026-09-29..10-02).
- Escalate: for-orchestrator-synthesis — Finding 2 is an ordering constraint for U1 (no autonomous use of check_answer before D8 lands).
