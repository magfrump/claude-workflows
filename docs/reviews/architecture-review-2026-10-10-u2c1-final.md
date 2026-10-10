Commit: 9e7c61c5

# Architecture Review: feat/build-loop-u2c1 (U2c1, final confirming pass, full branch)

**Scope:** `git diff main...HEAD` at 9e7c61c5: scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh (header contract, ownfile and FLOOR_WHY comments), test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md, override-log rows dated 2026-10-10 (review reports excluded as artifacts)
**Date:** 2026-10-10
**Based on:** the final fact-check summary (`u2c1-final-fc-summary.md`) and replicates `code-fact-check-report-build-loop-u2c1-final-r1/-r2/-r3.md`; prior reports `architecture-review-2026-10-10-u2c1.md` (i1) and `-i2.md` (i2) as context

## Scope check

In scope: the diff adds and changes contracts across the build-loop.sh/lib boundary (public API category): `list_entries` becomes the shared list-line parser with a new `LIST_BAD` output; `srules` consumes the lib's `floor` and `ownfile` under a stated case contract; the lib's gate caller contract (items 1, 3, 5) and `ownfile`'s precondition text change; `check_line` moves from a subshell to the parent shell (a cross-cutting change to error handling and global-state isolation).

Trust-boundary cross-reference: the security reviews present (`security-review-2026-10-10-u2c1*.md`) are for earlier commits; no finding below proposes moving a boundary, so the section is a no-op.

## Dependency Map

- `build-loop.sh` (the gate CLI) depends on the lib `scripts/lib/dev-cycle-read.sh` for `floor`, `ownfile`, `truthrule`, `pathform`, `lower`/`lower_all`, `brief_fields`, `import_reset`, `need_root` and `NAMECHARS`. Direction is correct: the volatile CLI depends on the stable reader lib. The lib refers to build-loop.sh only in prose (contract item 5, FLOOR_WHY's comment; settled by row 614).
- Inside build-loop.sh: `read_settings` and `read_paths` both call `list_entries` (one parser, FORM passed by name: `globform` or `pathform`); `check_line` → `nrules` (N rules) → `srules` (S rules) → lib `floor`, then `NEVER_RES` (built once by `never_res` from read_settings' `NEVER`), then lib `ownfile`, then `PATHS`.
- `check_line` now shares the parent shell with the main loop: separation between briefs rests on each helper resetting its own globals and on `import_reset`.

## Findings

#### F1. srules' own-file case rule still lives in ownfile's patterns, and those patterns do not enforce it for a review's NAME

**Severity:** Minor
**Location:** `scripts/build-loop.sh:649-668`, `scripts/lib/dev-cycle-read.sh:1799-1811`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High

Evidence (srules' comment, build-loop.sh:654-657):
```
# Self-merge never: glob, then the allowlist (Paths:, or ownfile). The
# allowlist widens nothing by case: Paths: entries compare exactly, and ownfile
# gets the path as spelled, so an own file passes only when the diff spells
# it in lower case (ownfile folds nothing).
```
Evidence (ownfile, dev-cycle-read.sh:1810):
```
  [[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]
```
Probe (ownfile extracted and called alone, stem `2026-10-01-x`, status A): `docs/reviews/Code-Review-2026-10-01-x.md` → own; `docs/working/Plan-2026-10-01-x.md` → not own. This agrees with fact-check r3's Incorrect verdict.

This is i2 F-i with its basis changed. C3 made ownfile's comment honest ("it folds no case"), but "folds no case" is not "matches only lower case": the `NAME-` prefix is a free glob. So the rule srules, --help (`:185-186`) and plan `:311` promise is enforced by whatever the regex in another module happens to spell out. It holds for the working-doc patterns and fails for the review NAME. A future edit to ownfile's patterns, or a brief whose stem holds an upper-case letter, changes srules' allowlist with no change to srules. Who owns the case rule is the structural question here; the landing consequence belongs to security.

**Recommendation:** Put the case rule in the module that states it: srules already holds the lower-cased spelling as `$3`, so `[[ "$2" == "$3" ]] && ownfile "$2" "$1" "$4"` enforces "only in lower case" without depending on ownfile's patterns, and the comment can then drop "(ownfile folds nothing)" as the reason.

#### F2. The lib's caller contract item 8 still tells callers to pass ownfile a lower-cased path, against ownfile's comment and srules' call

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:90-93` (against `:1799-1801` and `scripts/build-loop.sh:663`)
**Move:** 3 (module boundary)
**Confidence:** High

Evidence (item 8):
```
#  8. Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a
#     lower-cased path (prompt_dir and prompt_bases also take the path as
#     spelled; floor, check_fix and the walks lower first; truthrule refuses an
```
Evidence (ownfile's comment, as changed by C3):
```
# shared by two dates is not a collision), for a path $1 (it folds no case:
# floor passes it lower-cased, build-loop.sh srules as spelled) with
```
Evidence (srules, build-loop.sh:663): `  ! ownfile "$2" "$1" "$4" || return 0` ($2 is the path as spelled).

The header calls itself "the one statement" of the gate caller contract (row 459), and item 8 now contradicts both the function's own comment and the second caller's use of it. A reader who follows the contract gets the opposite of what srules does on purpose (B1). Fact-check r2 and r3 report the same Stale. C3 fixed one of the two places that state ownfile's precondition.

**Recommendation:** Move ownfile out of item 8's lower-cased list, or add it beside prompt_dir/prompt_bases with the case it takes from each caller (and, once F1 is done, say the caller owns the case rule).

#### F3. The re-read refusal now has two channels: the verdict (`co`) and a Paths: reason that says own files land

**Severity:** Informational
**Location:** `scripts/build-loop.sh:815-818`, `:649-653`, `:664`; `docs/reviews/override-log.md` row "check_line's verdict chain grows again"
**Move:** 2 (responsibility boundaries), 7
**Confidence:** High

Evidence (check_line):
```
    if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY="could not be read again"; co="${co:-refuse $a: the brief could not be read again from the default branch}"; fi
```
Evidence (srules): `  [[ -z "$PATHS_WHY" ]] || { DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"; return 0; }`, and its comment names `$5` "the checkout refusal, if any".

C1 fixed i2 F-iv's behavioural half (the verdict now refuses) but kept the second write of PATHS_WHY. So a brief-level failure is reported through the Paths: line's channel, and its deny text ("the brief's Paths: line could not be read again, so only its own files land") is false because nothing lands. srules' `$5` now carries the re-read refusal too, so its name ("the checkout refusal") and the floor-skip rationale ("it walks the checkout") describe only one of its two sources. Override row 613's reason ("it now lands only own files with every line printed") also predates C1 (fact-check r1, r2). No harm today: the verdict refuses either way.

**Recommendation:** When the U3 verdict-chain revisit lands (row 613's trigger), give the re-read failure its own deny reason, or none, instead of PATHS_WHY. For now, rename `$5` in srules' comment to "the verdict refusal (checkout or brief re-read)".

#### F4. check_line's list of reset globals omits LIST_BAD

**Severity:** Informational
**Location:** `scripts/build-loop.sh:765-768`
**Move:** 7
**Confidence:** High

Evidence:
```
# Nothing but its locals and the walk caches it resets may carry from one
# brief to the next: each helper empties its own globals before use (DENY,
# PATHS and PATHS_WHY, LIST and LIST_WHY, BRIEF, CHECKOUT_WHY, FLOOR_WHY,
# TRUTH_WHY).
```
C2 added `LIST_BAD`, which `list_entries` does reset (`:367`), but the list that C4 rewrote to read as complete leaves it out. The invariant holds. The list is just the comment a future helper author checks against.

**Recommendation:** Add LIST_BAD to the list, or say "for example" so the list is not read as exhaustive.

## Settled rows considered (not re-raised)

Rows 614, 615 (lib prose naming the caller; dynamic LC_ALL), 616 plus its corrected-reason row (reader_settings' copy of the list grammar). The corrected reason is accurate: `list_entries` takes FORM by name and uses nothing else from build-loop.sh. The U2c2/U3 deferrals (directory at an instruction name, floor's per-path forks, the per-path malformed-Paths reason, the verdict chain) were also considered, and the branch does not change their basis. F3 touches row 613 only to note that its reason text is stale.

## What Looks Good

- One list-line parser (`list_entries`) for both build-loop.sh lists, with FORM injected. `LIST_BAD` replaces read_settings' match on the reason's wording (i2 F-ii), and `none` is read from the empty LIST instead of being parsed again. The coupling is now data, not text.
- Dependency direction stays CLI → lib. The S rules compose lib predicates (`floor`, `ownfile`) and keep the gate-specific allowlist and never-glob logic in build-loop.sh.
- `never_res` compiles the globs once per run, apart from the per-path loop. srules' first-match order is a flat early-return chain that is easy to extend.
- Moving check_line into the parent shell makes need_root's exit and import_reset effective. The comment now states the set -e and global-reset convention that this depends on.
- The plan's U2c split note gives each deferred item an owning unit.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | srules' "own files only in lower case" rests on ownfile's patterns, which leave a review's NAME any case | Minor | `scripts/build-loop.sh:654-663`, `scripts/lib/dev-cycle-read.sh:1810` | High |
| F2 | Lib contract item 8 still says ownfile takes a lower-cased path | Minor | `scripts/lib/dev-cycle-read.sh:90-93` | High |
| F3 | Re-read refusal also written as PATHS_WHY ("so only its own files land"); srules' `$5` named for the checkout only; row 613 reason stale | Informational | `scripts/build-loop.sh:817`, `:664` | High |
| F4 | check_line's reset-globals list omits LIST_BAD | Informational | `scripts/build-loop.sh:765-768` | High |

Rubric mapping: no Structural (🔴) and no Coupling (🟡) findings. All four map to 🟢 Consider.

## Overall Assessment

The branch keeps the system's structure sound. Dependencies flow from the CLI to the lib, the list grammar has one parser in build-loop.sh, and the parent-shell move is documented where it matters. The fixes needed are local and small. The most important concern is F1: a rule the --help, the plan and srules all promise is owned by none of them. It is enforced by the shape of a regex in another module, and that regex does not fully enforce it. A one-condition change in srules (compare the path with its lower-cased spelling) puts the rule where it is stated. F2 is the matching edit to the lib's contract text.

## Goal-Alignment Note

The user's goal is to land U2c1 after a clean review-fix loop. Nothing here blocks that at the architecture tier (no 🔴/🟡). F1 and F2 are the same small, cheap fix: one condition plus one contract line. Taking them before merge closes the only promise in the unit's own --help that the code does not keep. F3 and F4 are wording, and F3's structural half fits row 613's U3 revisit.
