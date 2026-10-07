Commit: e48cf0f7

# API Consistency Review — feat/build-loop-u2a3b (final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test docs/working` at e48cf0f7 (lib `scripts/lib/dev-cycle-read.sh` :1-35 and :440-680, `check_fix` in `scripts/dev-cycle.sh`, the header's `--check-fix` paragraph :50-55)
**Date:** 2026-10-06
**Based on:** Stage-1 fact-check summary (fc-final-summary.md; replicates `code-fact-check-report-build-loop-u2a3b-final-r{1,2,3}.md`), iteration-2 API review `api-consistency-reviewer-review-2026-10-06-build-loop-u2a3b.md`, rubric `code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md`

Escalations: the Stage-1 summary addresses none to api-consistency. The security escalation (failing `tr` exits before check_fix's walk-failed wording) touches my check_fix surface. It comes from `lp="$(printf ... | tr ...)"` at `scripts/dev-cycle.sh:175`, which this branch does not change, so I note it under Overall Assessment and file nothing.

## Baseline Conventions

- **Walk return contract (main_imports, U2a3).** It returns 1 and sets the result variable to the sentinel `error` on any failure. The result is cached under a key, and a cached error returns 1 again (`[[ "$IMPORTED_MAIN_DONE" == ... ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }`). Callers run it under `if` or `||`.
- **Listing helpers.** They write NUL-separated output on stdout and are read through `nul_list NAME CMD...`, which fails unless CMD exited 0 and its output was empty or ended in NUL (`untracked_md`, `git ls-tree -r -z`, `git ls-files -z`).
- **Pipefail locality.** A function that pipes sets it locally with `local -; set -o pipefail` (brief_fields :322, main_imports :602, :769 "as brief_fields").
- **isimported.** It answers "imported" (0) whenever it cannot decide, so a caller that tests it with `if` refuses.
- **check_fix skip wording.** Each line reads `skip $a: <reason>`, and every policy refusal ends `; file it instead`. The comment above check_fix says "the header's --check-fix paragraph is the rule, and the skip messages below repeat it".
- **Lib inventory test.** `test/scripts/dev-cycle.bats:1095-1097` lists every function the lib defines.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `tree_starts` | function (NUL lister) | `untracked_md`, `instruction_names`, `main_imports` | `scripts/lib/dev-cycle-read.sh:556-602` | Consistent. "tree" matches isimported's walk name `tree`. The output is NUL-separated and read through nul_list, like `untracked_md`. It uses `local -; set -o pipefail` like brief_fields and main_imports. |
| `IMPORTED=error` (initial value) | state sentinel | `IMPORTED_MAIN=error` | `scripts/lib/dev-cycle-read.sh:481` | Consistent. This closes iteration 2's I2-C5 asymmetry. |
| skip reason "the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead" | CLI output reason | "an instruction file imports it with @ ..., so it is read as instructions; file it instead", "in-cycle fixes edit only ...; file it instead" | `scripts/dev-cycle.sh:180-184` | Consistent with its sibling reasons: same `skip $a:` lead, a "so" clause and `; file it instead`. Its gap against the header paragraph is Finding 1. |

The other surfaces add no new public names; their return contracts change. `import_targets` now returns 1 on a sed or grep failure. `instruction_names` returns 0 on no match and 1 on a grep failure. `imported_names` returns 1 with IMPORTED=error, and the error is cached. `isimported tree` now uses `|| return 0`, as `main` does.

## Findings

#### 1. The header's --check-fix paragraph, which check_fix's comment calls "the rule", does not mention the new walk-failed refusal

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:50-55`, `scripts/dev-cycle.sh:181-182` (mirror: `skills/dev-cycle/SKILL.md:72-76`)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a dev-cycle operator, or the loop's agent, reading the header or SKILL.md to learn why a path was refused

Evidence: the header says `--check-fix  "ok <path>" for a file an in-cycle fix may edit: a tracked .md file under docs/ (not the cycle's own files, ... an instruction file, or a file an instruction file imports with @; compared ignoring case) or README.md; "skip <path>: <reason>" otherwise.` check_fix's comment says `the header's --check-fix paragraph is the rule, and the skip messages below repeat it`. The new branch is `elif ! imported_names; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"`.

The refusal is correct (fail-closed), and "otherwise" technically covers it. Every other skip reason restates a clause of the paragraph, but this one has no clause. A reader could take the paragraph to mean that a docs/ file nothing imports is always `ok`. A whole-cycle refusal, where every path skips because a corrupt index or a failing grep broke the walk, is then undocumented in both the header and SKILL.md. The `--check-answer` paragraph sets the stronger precedent here: it lists each "cannot be read" case.

**Recommendation:** Add a clause such as "; also skip when the import walk fails (every path then skips)" to the header paragraph, and mirror it in SKILL.md :72-76.

#### 2. The lib inventory test omits the new function tree_starts

**Severity:** Minor
**Location:** `test/scripts/dev-cycle.bats:1095-1097`
**Move:** 3 (test drift)
**Confidence:** High (executed: every `name()` in the lib was compared against the list, and only `tree_starts` was missing)
**Legibility-target:** a later maintainer, who relies on the sourcing test to catch a lib function that was dropped or renamed

Evidence: `for f in scrub scrub_reexec ... main_imports nul_list import_targets instruction_names untracked_md; do declare -F "$f" >/dev/null || echo "missing $f"`. The lib has `tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }` at :562.

Every other lib function is listed, including the U2a3 helpers nul_list, instruction_names and untracked_md. If tree_starts is renamed or deleted, imported_names still fails closed: `nul_list recs tree_starts || return 1`, and an unknown command returns 127. The walk would then fail everywhere, check_fix would refuse every path, and this test would stay green. Other --check-fix tests would catch that, so the impact is low.

**Recommendation:** Append `tree_starts` to the list.

#### 3. The lib header's pipefail parenthetical and imported_names' "each call sits in an if or ||" do not match the code and its callers

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:12-13`, `scripts/lib/dev-cycle-read.sh:453`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a caller of the lib reading the header for its contract

Evidence: the header says `The caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves)`. `tree_starts` (:562) and `imported_names` (:564) now also set it, and `main_imports` (:602, U2a3) already did. The comment at :453 says `(each call sits in an \`if\` or \`||\`, where set -e is off)`, but `test/scripts/dev-cycle.bats:1176-1177` calls `imported_names` bare under `set -euo pipefail`.

The new header sentence (:18-19, "imported_names and main_imports return 1 when the walk fails: call them under if or ||") is the right contract and matches main_imports. The bare test call is harmless: a failure would exit and fail the test. Stage 1 r2 already raised the :453 point, which I cite here rather than verdict independently.

**Recommendation:** Either turn the :453 parenthetical into the instruction ("call it under if or ||") or drop it. Extend or generalize the :12-13 list ("several functions set pipefail locally").

#### 4. IMPORTED=error is a sentinel only for code that tests it

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:481`
**Move:** 8 (nullability/sentinel contract)
**Confidence:** Medium
**Legibility-target:** a future reader of `$IMPORTED` outside isimported (for example, U2a4's floor)

Evidence: `IMPORTED=error; IMPORTED_DONE=""; IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=""`.

A raw membership test such as `[[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]`, run on an unwalked or failed state, reads "not imported", just as the old `$'\n'` did. Only isimported (which walks first and checks the return) and an explicit `!= error` test fail closed. This matches IMPORTED_MAIN exactly, so it is consistent. No reader outside isimported and the walk's own cache test exists today (rg over scripts/). I record it so that U2a4 reads the variables only through isimported.

**Recommendation:** None required. Optionally, add one clause to the block comment above :481: "read the lists only through isimported".

No settled override row was re-filed. Iteration 2's I2-C2 (main_imports' header omits the lower guard) is still true at :589-601, but it is a deferred override row routed to U2a3, and I see no new evidence.

## What Looks Good

Each of these is `[unverified — submitted as claim]`.

- `imported_names` now has main_imports' exact contract. It returns 1, sets `IMPORTED=error` before any work, and a cached error returns 1 again (`[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }`, :566). IMPORTED is set to `$'\n'` only after the start listing succeeds (:577). This closes I2-C5.
- `isimported` is now symmetric. It uses `tree) imported_names || return 0;` like `main) main_imports || return 0;`, and `lp="$(lower "$2")" || return 0` answers imported on a failed lower. Its header (:668-671) names both walks for a caller that words a failure. This closes I2-A4's contract half.
- `instruction_names` changes from `|| true` to `|| [[ $? -eq 1 ]]`, documented as "returns 0 when no name matches and 1 when grep fails". This brings grep's inverted status in line with nul_list's "CMD exited 0" contract.
- `tree_starts` reuses nul_list as main_imports does. grep -z ends each record in NUL, and an empty listing exits 0, so nul_list's "empty or ended in NUL" rule holds both when there are no starts and when there are some.
- `import_targets` now returns 1 when sed or grep fails (the comment at :509 states it). Both callers check it: imported_names at :581 (`|| { IMPORTED=error; return 1; }`) and main_imports at :634. The only other direct caller, `test/scripts/build-loop-check.bats:374`, calls it under `if`. An empty input still returns 0 (executed: rc=0). "Each path once" holds per token. The same path from two tokens is printed twice (executed), and both walks deduplicate with `seen`.
- check_fix's new reason matches its siblings' shape (`skip $a: <reason>, so <consequence>; file it instead`). It runs before isimported, so it never prints the false "imports it" reason.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The --check-fix header paragraph ("the rule") and the SKILL.md mirror omit the walk-failed refusal | Minor | `scripts/dev-cycle.sh:50-55`, `:181-182` | High |
| 2 | The lib inventory test omits tree_starts | Minor | `test/scripts/dev-cycle.bats:1095-1097` | High |
| 3 | The pipefail parenthetical is incomplete, and "each call sits in an if or ||" is false for dev-cycle.bats:1176 | Informational | `scripts/lib/dev-cycle-read.sh:12-13`, `:453` | High |
| 4 | IMPORTED=error fails closed only when tested; raw membership reads "not imported" | Informational | `scripts/lib/dev-cycle-read.sh:481` | Medium |

## Overall Assessment

The changed surface is consistent with the conventions U2a3 set. The tree walk, its start lister and its parser now share main_imports' fail-closed return-and-sentinel contract and the nul_list listing idiom. isimported is symmetric across both walk names, and check_fix's new reason matches its siblings. Iteration 2's API findings 1, 3, 4, 5 and 6 hold as fixed. The remaining items are documentation and test drift that can be fixed in place: the header paragraph (and SKILL.md) that check_fix's comment names as the rule should mention the walk-failed refusal, and the inventory test should list tree_starts. Consumer impact is low, because every miss here over-refuses and none fails open.

The security escalation is noted, not filed. With a failing `tr`, `--check-fix` exits 1 with no output before the new wording. The cause is check_fix's pre-existing line `lp="$(printf '%s' "$a" | tr ...)"` (:175), which this branch does not change, and the result is still a refusal.

## Goal-Alignment Note

Success criterion: "A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: e48cf0f7` line at the top." This report is saved at `docs/reviews/api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a3b.md` in the worktree, with `Commit: e48cf0f7` as its first line and the skill's sections. It covers every surface the brief names: the lib header contract, the return contracts of import_targets, instruction_names, tree_starts, imported_names and isimported, nul_list's reuse, IMPORTED's initial value, and check_fix's new wording against its siblings and the header paragraph.
