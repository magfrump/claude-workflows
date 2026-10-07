Commit: 34edec56

# Architecture Review — feat/build-loop-u2a3 (iteration 2)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 34edec56): `scripts/lib/dev-cycle-read.sh` (main_imports, isimported, header comments), tests, plan F11/U2a3/U2b, known issue A5, review artifacts
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3-i2.md` and `docs/reviews/code-fact-check-report-build-loop-u2a3.md` (via the iteration-2 fact-check summary); trust boundaries from `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md` (Commit: 7697c6e6) and `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a.md` (Commit: 36b79f72), both predating this diff, so the boundaries may be stale

**Scope check:** in scope. The diff changes a **public API** (a new lib function `main_imports`, a new `isimported main` selector, two new module globals `IMPORTED_MAIN` / `IMPORTED_MAIN_DONE` that dev-cycle.bats' inventory now pins) and adds a **caching layer** with a caller contract. Tests, plan and review-artifact files were read only for context.

## Dependency Map

- `scripts/lib/dev-cycle-read.sh` is the shared module, sourced by `scripts/dev-cycle.sh` and `scripts/build-loop.sh`. Nothing calls `main_imports` or `isimported main` yet. U2a4's `floor` will be the first caller, and U2b's `--check` will be the first process to run it.
- Inside the lib, `main_imports` depends on `need_root`/`ROOT_REAL`, on `resolve_main`'s globals (`MAIN_SHA`, `MAIN_BY_NAME` through `main_by_name`), on `untracked_md`, `inrepo_here`/`blocker`, `INSTRUCTION_FILE`, `lower`, and on the shared parser `import_targets`. It shares the parser with the tree walk `imported_names` but has its own queue, start-set rule and cache.
- Dependency direction is sound. The new code depends only on lib primitives and git plumbing, and no lib code depends on a caller. The walk reads two sources: main's commit (`ls-tree`, `cat-file`) and the checkout (`ls-files --others`, file reads, `-e`/`-L`/`-d` probes). The cache and contract findings below come from that second source.
- Trust boundaries: `main_imports` sits on B5 of the final U2a2 security review (`[main's blobs] → [import_targets (shared)] → [IMPORTED_MAIN / floor]`, Commit 7697c6e6) and on B3 of the U2a security review (`checkout's untracked/ignored *.md files → untracked_md → extra walk start set`, Commit 36b79f72). Both reviews predate this diff, so the boundaries may be stale.

## Findings

#### 1. The main walk's cache key leaves out the checkout, which the walk reads

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:549-550`, `:562-565`, `:580-583`, `:600`; comment `:469-470`
**Move:** 3 (module boundary / encapsulation), 7 (coupling surface)
**Confidence:** High (mechanism, probe-confirmed); Medium (exposure: no caller yet)
**Legibility-target:** U2a4/U2b author writing the first caller of `isimported main`

**Evidence:**
```
549:  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
550:  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"
```
```
562:  mapfile -d '' recs < <(untracked_md && printf rc=0 || printf rc=1)
```
```
600:            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
```
```
469:# absolute imports. IMPORTED_MAIN reads "error" until a walk succeeds; the result is
470:# cached for the commit and root in IMPORTED_MAIN_DONE. isimported asks either
```
(excerpts are from main_imports :545-615, read in full.)

The walk's answer depends on three checkout inputs: untracked start files (:562-565), plain checkout files read for targets main lacks (:580), and `-L`/`-e` probes on checkout paths (:582, :600, which 4f087967 added for link text). The cache key is only `MAIN_SHA ROOT_REAL`. A probe in `/tmp/u2a3-arch-i2-lAtr` on a one-commit repo called `isimported main docs/b.md` (not imported), then added an untracked `CLAUDE.local.md` holding `@docs/b.md`. The second call still answered "not imported". After clearing `IMPORTED_MAIN_DONE`, a fresh walk answered "imported". The walk is presented as reading main's commit, but its cached answer is only valid while the checkout stays the same, and nothing at the interface says so. The comment says what the key holds, not which inputs it leaves out. The tree walk has the same property (`IMPORTED_DONE` is keyed on the root alone, row 207 "per process"), so this follows the existing pattern. But this walk feeds the self-merge gate, and in the gate's direction a stale answer fails open. Current exposure is low. Row 207 makes a `--check` one process per run, and merge-tree does not write the checkout. The risk is a future long-lived caller or a gate step that writes into the checkout before asking. The fact-check escalated this from iteration 1, carried as (a). The MAIN_BY_NAME half of that escalation fails closed and needs no change.

**Recommendation:** State the contract at the cache comment: valid for one process and an unchanged checkout, so a caller that changes the checkout clears `IMPORTED_MAIN_DONE`. Alternatively, give U2a4 a one-line reset helper so callers do not write the global themselves. Add a test that pins the reset, alongside the iteration-1 cache gap the fact-check sent to test-strategy.

#### 2. `isimported main` answers for import targets only, and the start-set rule it knows is not exposed

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:569-574`, `:616-630`
**Move:** 3 (module boundary), 5 (interface completeness)
**Confidence:** Medium
**Legibility-target:** U2a4 author of `floor` (floor item 1)

**Evidence:**
```
571:    if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then
572:      seen[${cand[i]:2}]=1; queue+=("${cand[i]}")
```
```
616:# Whether path $2 (any case) is imported, by the walk $1 names: tree or main.
```
(excerpt ends :572; the enclosing loop continues to :574 and main_imports to :615. All of it was read.)

Start files go into `seen` and `queue` but never into `IMPORTED_MAIN`. The same probe answered "not" for both `CLAUDE.md` and `.claude/rules/x.md`. So "what Claude Code loads as instructions on main" is split across two places. The walk's start predicate (:571) is an inline expression in main_imports, and the floor's denial set is `INSTRUCTION_FILE` plus a dot-component rule (plan amendment, :192). Today the floor covers every start the walk knows: `.claude/rules/**` has a dot component. That coverage comes from the dot rule happening to match, not from a shared rule. If the start set grows (another loaded directory without a dot, or a change to the rules glob), :571 changes and the floor does not. A floor author who reads `isimported main` as "loaded as instructions" would leave out the starts. This is the same split that U2a review row 347 settled for the two walks. Here it is between the walk and its first consumer, and this diff creates that split. Row 347 does not cover it.

**Recommendation:** Name the start rule as a lib predicate (for example `isstart PATH`) and call it from main_imports. U2a4's floor can then deny `isstart || isimported main`. As a smaller option, state in `isimported`'s comment that start files are not included and that the floor must cover them itself.

#### 3. The lib's own `isimported main` runs the whole walk with errexit off, so fail-closed rests on per-command checks

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:626`, with the walk body `:575-614`
**Move:** 7 (coupling: a hidden contract between the module and its runtime mode)
**Confidence:** Medium (mechanism is standard bash, and the instance at :609 is the one fact-check/U2a3b already found)
**Legibility-target:** Future editors of main_imports

**Evidence:**
```
626:    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
```
```
575:  IMPORTED_MAIN=$'\n'
...
609:      IMPORTED_MAIN+="$(lower "$p")"$'\n'
```
The lib header (:12) relies on the caller's `-euo pipefail`. But in bash, errexit is suspended for the whole of `main_imports` because the function runs on the left of `||`, and the function's only public entry is that `||`. A failing command that does not carry its own `|| { IMPORTED_MAIN=error; return 1; }` therefore lets the walk continue. It publishes a partial set and returns 0, and in the gate's direction that fails open. `IMPORTED_MAIN` is also set to `$'\n'` (:575) before the queue runs, so the global holds a partial set during the walk rather than only after success. The known instance, a failing `lower` at :609, is **fixed in U2a3b (stacked)**. The structural issue remains: every command added to the walk must carry an explicit failure arm, and nothing enforces or states that rule. U2a2 final review row 359 deferred this for the tree walk under the caller's `elif`. What changed is that the lib's own predicate now does it for the gate walk.

**Recommendation:** Add one line to main_imports' comment saying it runs with errexit off (under `isimported`'s `||`), so every command's status must be checked explicitly. Optionally, build the set in a local and assign `IMPORTED_MAIN` once at the end, so the global never holds a partial set. That does not fix an unchecked failure, but it shrinks what one can corrupt.

#### 4. The link-text resolution step is an inline algorithm in a case arm and cannot be tested separately

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:587-603`
**Move:** 2 (responsibility), 8 (extension point)
**Confidence:** Medium
**Legibility-target:** test-strategy / the next fixer of a symlink shape

**Evidence:**
```
596:          lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"
597:          for c in "${parts[@]}"; do
598:            [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
599:            p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
600:            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
601:          done
602:          out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..
```
Iteration 1's only red was in this step, and both fix commits (4f087967, 34edec56) changed it. It is now about 15 lines of read, NUL count, component check and lexical resolution inside the BFS's case arm. It is the part of the walk most likely to change again: Q10/Q11's fail-open goes through a symlinked directory, and Claim 11 found that the step checks per component but resolves the target lexically at :602. A mutant that removes the `! -L` half survives because nothing pins it. As a named helper (for example `link_target DIR TEXT`, printing the repo-relative target or failing), it could be tested on its own with a crafted `ent` map, and the BFS would read as "blob, link or skip".

**Recommendation:** Consider extracting the 120000 arm into a helper when the Q10/Q11 fix touches it next. Not required for this unit.

#### 5. One set of gaps is now described in three places, and the lib's version is the one that is wrong

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:464-469`; `docs/working/known-issues-dev-cycle.md` A5; `docs/working/plan-build-loop-handoff.md:126`
**Move:** 3 (the documented contract of a public function)
**Confidence:** High (from fact-check i2 Claims 3, 19: Incorrect)
**Legibility-target:** Reader deciding what the gate covers (Q-103 / U5)

**Evidence:**
```
466:# untracked nested repo (neither listing enters one either), an @ token's path
467:# (link text is checked above) through a directory main stores as a symlink
```
A5 and F11 say "an import path through a directory main stores as a symlink", which covers link text. The lib comment narrows that to "@ token's path" and says link text "is checked above". Fact-check Q10/Q11 show that link text through such a directory also fails open. The gate's not-covered list is part of its interface for U5's Q-103 text, and the three copies already disagree after two fix commits. This is a fact-check finding. Its architectural consequence is drift: the gap list belongs in one place (A5), and the lib comment should point to A5 rather than restate it.

**Recommendation:** When fixing the wording, cut the lib comment's gap list down to a pointer to A5 (plus the one-line refusal set), so later fixes edit one list.

#### 6. The "commit-reading" walk's dependence on the checkout grew (carried row 351)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:600`, `:579-583`; plan F11 `:126`
**Move:** 1 (dependency direction / inputs)
**Confidence:** High
**Legibility-target:** U2b author naming the checkout `--check` runs in

**Evidence:**
```
600:            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
```
Override row 351 (`feat/build-loop-u2a`) deferred "untracked start files come from the checkout" to U2b. Since then this diff added two more checkout reads to the walk: checkout files for targets main lacks (:580), and `-L` probes at each link-text component (:600), which can now fail a walk over main-only data. F11 lists all three, so the documentation is accurate. What changed is that the walk's result is now a function of (commit, checkout), and Finding 1's cache, U2b's checkout choice and Finding 2's floor all depend on that. B3 of the U2a security review (Commit 36b79f72, which predates this diff, so the boundary may be stale) covers only the untracked start set. The new checkout reads cross the same boundary and widen it. No structural change is recommended here, so there is no Security implication line. This finding notes the widening for the security reviewer's map.

**Recommendation:** None for this unit beyond Finding 1. Revisit row 351's trigger (U2b) with all three reads, not only the start set.

## What Looks Good

- **Fail-closed by refusal, one sentinel.** The walk models a narrow set of tree and link shapes and refuses everything else, setting `IMPORTED_MAIN=error`, which `isimported main` maps to "imported". This matches FENCE_AWK's pattern elsewhere in the lib. The sentinel starts as `error` at source time (:472), so an unrun walk never reads as an empty set.
- **One public predicate, cache format hidden.** Callers ask `isimported main|tree`, as the U0c plan amendment (row 203) required. They do not read the newline-framed cache, and an unknown selector answers imported.
- **Commit-sourced reads.** `ls-tree -r -z --full-tree` and `cat-file` by `MAIN_SHA` follow main_entry's and check_brief's existing contract (main found by name, otherwise error), so the gate does not depend on a worktree checked out at main.
- **Shared parser, separate walk.** Both walks reuse `import_targets`, so token rules have one home (U2a3b changes both at once). Row 347 settled the separate BFS on purpose.
- **Dependency direction.** No new outward dependency. The lib stays a leaf that both scripts source.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Cache key `MAIN_SHA ROOT_REAL` leaves out the checkout the walk reads; a second call misses a new untracked start (probe-confirmed) | Minor | `scripts/lib/dev-cycle-read.sh:549-550` | High (mechanism) / Medium (exposure) |
| 2 | `isimported main` covers targets only; start-set rule inline, not shared with U2a4's floor | Minor | `scripts/lib/dev-cycle-read.sh:571`, `:616-630` | Medium |
| 3 | `isimported main`'s `||` runs the whole walk with errexit off; fail-closed depends on per-command arms; partial set published during the walk (the `lower` instance is fixed in U2a3b) | Minor | `scripts/lib/dev-cycle-read.sh:575`, `:626` | Medium |
| 4 | Link-text resolution is an inline 15-line algorithm in a case arm; extract to test it | Informational | `scripts/lib/dev-cycle-read.sh:587-603` | Medium |
| 5 | Gap list described three times; the lib's copy is wrong (fact-check i2 Claims 3, 19) | Informational | `scripts/lib/dev-cycle-read.sh:466-467` | High |
| 6 | The walk's checkout inputs grew from one to three (row 351 carried) | Informational | `scripts/lib/dev-cycle-read.sh:580`, `:600` | High |

Rubric mapping: no Structural (🔴) or Coupling (🟡) findings. All six are 🟢 Consider.

## Overall Assessment

The change keeps the lib's structure intact. The new walk is a leaf-level function behind the existing `isimported` predicate, its dependencies point only at lib primitives and git plumbing, and it follows the established fail-closed refusal pattern. The issues are contract issues at the seam U2a4 is about to use, and all are fixable in place. The most important one is Finding 1. The walk is presented as reading main's commit, but its result also depends on the checkout, and its cache ignores that. The fix is a stated contract or a reset hook before the floor starts calling it. Findings 2 and 3 are things the U2a4 author needs to know: start files are not in the set, and the walk runs with errexit off. No disagreement with the security reviews' boundary placement.

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to docs/reviews/architecture-review-review-2026-10-06-build-loop-u2a3.md, structured per the architecture-review skill (Structural / Coupling / Minor / Informational).

**Answered:** Yes. The report is saved at that path, with a dependency map, six findings carrying Evidence, Severity, Confidence and Legibility-target, What Looks Good, a summary table and an overall assessment. The fact-check's architecture escalation (the cache key) is answered in Finding 1 and confirmed by a probe. The MAIN_BY_NAME half fails closed.

**Out of scope:** The Q10/Q11 fail-open itself and lstat outside the repo (security-reviewer). The untested `! -L` half and the iteration-1 test gaps (test-strategy). The B14 bypass candidates and the backslash-escape import form (security / U2a3b). Per-record loop cost (row B6, performance). Parser and `lower` failure behaviours (fixed in U2a3b, stacked).

**Escalate:** None for blocking. Finding 1's contract (or reset helper) and Finding 2's start-set predicate should be decided before U2a4 writes `floor`. If deferred, record them as override rows with U2a4 as the revisit trigger.
