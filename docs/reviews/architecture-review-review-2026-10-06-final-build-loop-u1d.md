Commit: ab71bce5

# Architecture Review — feat/build-loop-u1d (final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1d -- scripts test` at ab71bce5 (83cdb005, 6c83af2a, 07c354c5, then a merge of main). Structural focus: `scripts/lib/dev-cycle-read.sh:1-33` (lib header), `:244-306` (`main_by_name`, `main_entry`, `brief_fields`), and every `main_entry` caller.
**Date:** 2026-10-06
**Based on:** the merged k=3 fact-check `docs/reviews/code-fact-check-report-build-loop-u1d.md` (Commit: ab71bce5, Claims 8 and 9), iteration 1's `docs/reviews/architecture-review-review-2026-10-06-build-loop-u1d.md` (Commit: 83cdb005), and the deferred and Won't-Fix rows listed in the shared context.

Scope check: in scope under trigger category 2 (public APIs), as in iteration 1. `main_entry` is a lib function with four call sites in two scripts, and the branch moves its path-form precondition into the function. The rest of the diff is comments, help text, one skip-reason string and tests. I did not review those structurally; the fact-check owns them.

Trust-boundary cross-reference: active only as a consistency check, because this pass produces no module-boundary findings. The most recent `docs/reviews/security-review-*.md` is still `security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`). Its `B5` is the `check_brief()` ls-tree mode gate, which is `main_entry`. That review predates this diff, so the boundary may be stale. The branch moves no crossing.

## What changed structurally since iteration 1

Nothing. Between 83cdb005 and ab71bce5, the only non-comment line that changed under `scripts/` is the `-h|--help` arm of `build-loop.sh`. Its trailing comment moved to its own line, and the code is unchanged:
```
$ git diff 83cdb005 ab71bce5 -- scripts | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | grep -vE '^[+-]\s*#'
-  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;  # the header, to the first non-empty line not starting with #
+  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```
The merge commit ab71bce5 brings in no `scripts/` or `test/` change. `main` is `ba465de2`, which is the merge base, and `git diff --stat <merge-base> main -- scripts test` is empty. The `main_entry` body, the guard line `:265`, and every caller's arm are byte-identical to what iteration 1 reviewed.

## Dependency Map

- The direction is unchanged. `scripts/dev-cycle.sh` and `scripts/build-loop.sh` source `scripts/lib/dev-cycle-read.sh`, and the lib depends on neither script. Inside the lib, `main_entry` calls `main_by_name` (`:249`) and `pathform` (`:142`). Both are in the same file, and `pathform` is a pure, locale-independent string predicate. No module edge or global was added.
- These are the `main_entry` call sites at HEAD (from `rg -n main_entry scripts`):
  - `brief_fields` at `dev-cycle-read.sh:298` runs `pathform`, then `main_entry`.
  - `check_brief` at `:336` runs `main_by_name`, `pathform`, `isbrief` and `blocker` before it.
  - `check_answer` at `:556` passes two fixed names.
  - `main_file` at `build-loop.sh:128` passes fixed names.
  - `dev-cycle.sh` has no direct caller.
  - The tests call it directly at `dev-cycle.bats:1234-1235` and `:1332`.

## Caller contract at HEAD: consistent

I checked each place in the lib that states who needs what. All of them agree with the code.

| Contract statement | Where | Code it describes | Consistent? |
|---|---|---|---|
| "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name (main_entry and brief_fields answer error)" | header `:22-25` | `main_entry` `:265`; `brief_fields` via `main_entry` `:298`; `check_brief` `:328`; `check_answer` `:554` | Yes. This closes iteration 1's F3 (the omission was fixed in 6c83af2a/07c354c5) |
| "check_brief, check_branch, check_answer, main_entry and brief_fields read its commit, so they answer only when it was found by name ... (main_entry and brief_fields answer error)" | MAIN comment `:244-247` | same as above | Yes |
| "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree" | header `:31-33` | `main_entry` runs only `git ls-tree` on `$MAIN_SHA` | Yes |
| "error (no default branch found by name, a path pathform refuses, ls-tree failed, or the tree lists a name twice ...). It runs main_by_name and pathform itself, before any read" | `main_entry` comment `:254-261` | guard `:265` comes before the ls-tree at `:267`; dup check `:273` | Yes (fact-check Claim 9: 8 refused forms answer error before ls-tree) |
| "error (... a path pathform refuses, any main_entry answer but blob, its error included ...)" | `brief_fields` comment `:288-291` | `:298` | Yes |
| "The caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves)" | header `:13-14` | `set -o pipefail` appears only at `:296` and `:552` | Yes (fact-check Claim 8) |

```
   262	main_entry() {
   263	  local p="" rest="$1" out mode path dup="" want=()
   264	  local -A m=()
   265	  if ! main_by_name || ! pathform "$1"; then echo error; return; fi
   266	  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
   267	  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
   (excerpt ends :267; enclosing main_entry() continues to :278 — read: map build, dup → error, parents → absent/notdir, leaf → absent/blob/notfile)
```

At HEAD, both lib tests that pin this contract pass when run directly: `ok 4 ... main_entry fails closed` and `ok 5 main_entry answers error for a path pathform refuses (U1d)`. The fact-check's mutants (Claim 14) show that reverting the guard fails the U1d test.

## Findings

No findings.

Status of iteration 1's findings, not re-filed:
- **F1** (Minor: `error` also covers a path form `pathform` refuses, and each caller's `error` arm names only an unreadable tree). This is deferred to U2 with the `badform` recommendation. There is no new evidence: the guard and the three `error` arms (`dev-cycle-read.sh:341`, `:561`, `build-loop.sh:133`) are unchanged, and no current caller can reach the refused-form case. `check_brief` and `brief_fields` check `pathform` first, and `check_answer` and `main_file` pass fixed names that `pathform` accepts.
- **F2** (Informational: `brief_fields`' own `pathform` check is redundant). This is Won't-Fix, and the code is unchanged.
- **F3** (Informational: the `resolve_main` sentence omitted `main_entry` and `brief_fields`). This is closed at HEAD (`:24-25`, `:244-247`; table above).

## What Looks Good

- **The gate owns its preconditions.** `main_entry` (the `B5` ls-tree gate) runs `main_by_name` and `pathform` before any read. U2's floor can pass arbitrary changed paths without relying on a pre-check from the caller to keep ls-tree output unquoted. It also keeps pathspec magic away from ls-tree in a direct sourcer that does not export `GIT_LITERAL_PATHSPECS`.
- **The prose follows the code.** The three places that describe the main-found-by-name rule (header, MAIN comment, `main_entry` comment) now name the same five functions and the same `error` answer. They no longer leave readers to infer the lib's two non-printing-line functions.
- **The test exercises the lib directly.** The U1d test sources the lib and calls `main_entry` without a script between them, so it pins the lib's contract rather than one caller's behaviour.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No new findings. Iteration 1: F1 deferred to U2 (`badform`), F2 Won't-Fix, F3 closed | — | — | High |

## Overall Assessment

The structure is unchanged since iteration 1, and the lib's caller contract is consistent at HEAD. Every statement about who needs main found by name, who answers `error`, who sets pipefail and who reads only the commit matches the code. Iteration 1's F3 is closed. Since 83cdb005 the only code change is a moved comment in the help arm, and the merge of main changed nothing under `scripts/` or `test/`. The one structural concern is still F1, the two meanings of `error`. It fails closed, no current caller can trigger it, and it is deferred to U2 with its override row. From an architectural standpoint, U1d is ready to land.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/architecture-review-review-2026-10-06-final-build-loop-u1d.md (first line `Commit: ab71bce5`), structured per the architecture-review skill.
- Answered: yes. The caller contract is consistent at HEAD (table, with verbatim evidence). Nothing structural changed since iteration 1: the diff since 83cdb005 changes no non-comment code line apart from moving the help arm's comment, and the merge brought no `scripts/` or `test/` change. There are no new findings.
- Out of scope: wording and test-strength claims, including fact-check Claims 13, 15, 17, 18 and 19 (the fact-check and test-strategy own these); security and performance.
- Escalate: nothing. F1 stays deferred to U2 under its existing override row. There is no new evidence to re-file it.
- Decisions I made: I used the 2026-10-02 digest-pass38 security review as the trust-boundary source, as iteration 1 did. The `security-reviewer-review-*-u1d` files do not match the `security-review-*.md` scan pattern, and no module-boundary finding depends on them.
