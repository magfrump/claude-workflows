Commit: b1a6f0a2

# Architecture Review: feat/build-loop-u4a, final confirming pass (full branch vs main)

**Scope:** `git diff main...HEAD` at b1a6f0a2. Code: `scripts/build-loop.sh` (header, parser, `land`, `chore_msg`, `chore_record`, `log_class`, `cycle_diff`, `asked`, `cycle_rules`, `questions_rules`, `land_cycle`, the mode dispatch), `scripts/lib/dev-cycle-read.sh` (`isrecord`, `writable`, the `truthrule` header) and `test/scripts/build-loop-orchestrator.bats` (the three U4a tests). Context: plan D7, D13, the script-interface bullet (:212) and the U4a as-built note (:339); `scripts/dev-cycle.sh` `check_fix`; override rows 722, 745, 753-768.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-final.md` (Commit c4e36d1d; 1 Incorrect, since fixed in d46cd00f, which I confirmed at `:1976`). Trust Boundary Map from `docs/reviews/security-review-2026-10-13-u4a-i2.md` (Commit: `4e14d1cc`; that review predates this HEAD, so its boundaries may be stale).

Scope check: in scope. The branch adds a public mode (`--land-cycle`), a third `land()` authority, the shared units `cycle_rules BASE SIDE`, `questions_rules` and `chore_record`, and a lib predicate (`isrecord`). It also gives the lib's `truthrule` a new consumer.

Complete-unit reading: I read the following in full: `land` (:1480-1566), `gate_msg`, `chore_msg`, `chore_record`, `log_class` (:1755-1787), `cycle_diff` (:1874-1897), `asked`, `cycle_rules` (:1908-1981), `questions_rules` (:1987-2022), `land_cycle` (:2026-2059), `check_line` (:1345-1413), `state_start`, the dispatch `case` (:2061-2114), and the lib's `truthrule` with its header and `isrecord`/`writable`. I also read `scripts/dev-cycle.sh` `check_fix` (:180-195).

Probes:
- **probe1** (`/tmp/u4a-archf-XXXX`, `timeout 30`, removed afterwards) ran `--cycle-diff` in a throwaway repo. It supports finding 1.
- **probe2** ran the three U4a bats tests under `TMPDIR=/tmp/u4a-archf-XXXX`. All three printed `ok`.
- **Cleanup:** no `/tmp/u4a-archf-*` directories and no `build-loop.sh` processes remain.

## Dependency Map

- **Dispatch → mode functions.**
  - `--land-cycle`: `state_start`, then `land_cycle`.
  - `--cycle-diff`: `state_start`, then `cycle_diff`.
  - `--merge`: `gate_start`, `check_line`, the authority check, then `land`.
- **The parser** shares one loop between `--cycle-diff` and `--land-cycle`, with `--main` accepted only under `--land-cycle` (override row 756).
- **`cycle_diff`:** index listing against the fork point, then `RAW_*`. The questions guard (this caller's alone) returns before the rules run. Then `cycle_rules BASE index`.
- **`land_cycle`:**
  1. branch regex, `LAND_MAIN == MAIN_SHA`, clean index;
  2. `merge_result` and `store_check`;
  3. `diff-tree MAIN R`, which fills `RAW_*`;
  4. `cycle_rules MAIN merge`, then `chore_record B`;
  5. all six `VERDICT` keys and `CHANGED`, then `land cycle`.
- **`cycle_rules BASE SIDE`** reads `RAW_*` and calls:
  - from the lib: `GATE_CODE`, `truthrule`, `floor_why`, `anybrief`;
  - its own helpers: `cyc_blob`, `asked`, `ROADMAP_AWK`;
  - `questions_rules BASE SIDE I...`, which writes `$GATE_TMP/cy.new`. The Asked: rule (now inline) then reads that file.
- **`land`** is the one D7 move. It switches on the `cycle` authority twice, for the reflog word and for `chore_msg` vs `gate_msg`; row 763 settles that.
- **`chore_record`** reads `RAW_*`, the lib's `isrecord` and `gate_git`. Its callers are `log_class` (the `--main-log` reader) and `land_cycle` (the writer's pre-check). `log_class`' chore regex comment now names `chore_msg`.
- **The lib:**
  - `isrecord` serves `writable` and `chore_record`.
  - `truthrule` has four consumers: `check_fix`, `floor`, `nrules`, `cycle_rules`. Its header now names `cycle_rules` and the word-order invariant ("a cycle file must never take an earlier word").
- **Direction and cycles:** dependencies run from the scripts down to the lib, and no dependency cycle is introduced.

## Findings

#### 1. `questions_rules`' new-entry file means both "no entry filed" and "could not tell", so the Asked: rule adds a refusal with a false cause

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1982-1991`, `:1997-2009`, `:2019-2020` (questions_rules); `:1954`, `:1975` (cycle_rules)
**Move:** 7 (coupling surface: the output contract between two extracted units)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# questions_rules BASE SIDE I...: cycle_rules' questions-file rules over the
# RAW_* records I... (the questions files' indices); also writes
# $GATE_TMP/cy.new, the IDs of the entries the listing files (a "### Q-NNN"
# heading BASE lacks), one per line: empty when no questions file changed or
# a read failed. Prints refusals; returns 1 on any.
questions_rules() {
  local base="$1" side="$2" f k i p md id bad=0 t="$GATE_TMP/cy"
  shift 2
  : > "$t.new"
```
(excerpt; questions_rules continues to :2022, read)

```bash
# cycle_rules (excerpt; cycle_rules continues to :1981, read)
  questions_rules "$base" "$side" "${qi[@]}" || bad=1
  ...
      if ! grep -qxF -- "$id" "$t.new"; then echo "refuse ${ap[$f]}: its first Asked: line adds $x, which names no question entry this change files"; bad=1
```

Probe1 set up a chore index that files `### Q-002` in a `questions.md` with an unclosed fence, and appended `, Q-002` to a brief's `Asked:` line. `--cycle-diff` printed:

```
refuse docs/working/questions.md: --check-answer refuses its index copy whole (unbalanced 8)
refuse docs/working/briefs/2026-10-01-x.md: its first Asked: line adds Q-002, which names no question entry this change files
```

With the fence closed, the same change printed `ok`.

Splitting `questions_rules` out (which resolves i2 finding 3) gave the two rules a channel: a fixed temp file named by convention (`$GATE_TMP/cy.new`, read as `$t.new`). That file is empty in two different states: "the listing files no entry" and "the questions files were refused whole or could not be read". The consumer cannot tell them apart. So every legitimately added Asked: item gets a second refusal that names the wrong cause.

This fails closed: nothing lands. But it is the kind of misleading co-refusal that U4b's skill text will have to explain or route on. An orchestrator acting on the second line would edit a correct brief.

**Recommendation:** Have `questions_rules` signal "unknown" separately. For example, return 2 on a whole-file or read refusal, and have `cycle_rules` skip the "names no question entry" check, keeping the shape and once-only checks. Alternatively, word the refusal "names no question entry this change files (or the questions files were refused above)". Optionally, pass the output path as an argument instead of sharing `$GATE_TMP/cy` by convention.

#### 2. The shared rules' awk programs and comments still describe one caller ("--cycle-diff's", "the index")

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1808` (QKEYS_AWK), `:1823-1827` (QDIFF_AWK), `:1844` (ROADMAP_AWK), `:1946` and `:1999` (cycle_rules, questions_rules)
**Move:** 3 (module boundary: a shared unit's documented contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# --cycle-diff's questions reader, per file (FENCE_AWK first): "ID F K LINE"
# The base's key lines (file 1) against the index's (file 2), each side
# --cycle-diff's roadmap rule over the base (file 1) and the index (file 2):
      # Seeding and "## Brainstorm" only append: the base's bytes start the index's.
      # Unchanged in the index: the base's copy on both sides; no entry, no copy (fact-check i2 claim 15: a failed read refuses).
```

The refusal texts were made side-neutral in iteration 1 (`SIDE`), which resolved i1 finding 2. The comments on the programs and branches that `--land-cycle` now runs over `MAIN_SHA` and the merge R were not. A reader of `QDIFF_AWK` or the unchanged-file branch learns only one of its two bindings. That matters for the next edit that assumes "the index" (staged, pre-merge) semantics, such as a rule that reads the work tree.

**Recommendation:** When these lines are next touched, say "the listing's new side (the index, or the merge under --land-cycle)", or simply "the new side". No behaviour changes.

## Earlier findings: resolution check

| Earlier # | Finding | Status at b1a6f0a2 |
|---|---|---|
| i1 1 | land_cycle repeats check_line's compute half; missing-blob coverage unstated | **Resolved** (comment option): `:2044-2045` states store_check's coverage. The duplication remains, as the recommendation allowed. |
| i1 2 | Shared refusals say "index"/"stage again" under --land-cycle | **Resolved.** `SIDE` (`:2007`); `refuse index:` and "stage again" live only in `cycle_diff`. The comment-level remainder is finding 2. |
| i1 3 | Chore message has two literals; land switches twice | **Resolved.** `chore_msg` is the one writer, and `log_class` names it (`:1772`). The second switch is settled Won't-Fix by row 763. |
| i1 4 | VERDICT key sets differ; RAW_* reuse unstated | **Resolved.** All six keys are set (`:2055`), and the RAW_* invariant is stated at the call site (`:2051`). |
| i1 5 | isrecord vs dev-cycle.sh's own glob; lib comment names callers | **Settled, Defer** (row 758). Unchanged in code: `scripts/dev-cycle.sh:225` keeps its glob. Not re-filed. |
| i1 6 | Questions guard inside shared cycle_rules | **Resolved.** It is in `cycle_diff` (`:1884-1895`). |
| i1 7 | Plan D7/D13 prose does not name the cycle land | **Settled, Defer** (row 759). The script-interface bullet (:212) now names `--land-cycle` and says "It replaces pr-prep's hand merge for the chore branch". D7's trailer sentence and SKILL.md:387 wait for U4b. |
| i2 1 | asked_rule reads cycle_rules' locals by dynamic scope (fails open from another caller) | **Resolved.** The rule is inline in `cycle_rules` (`:1955-1979`), and its maps are that function's own `local -A`. |
| i2 2 | truthrule's fourth consumer missing from the lib contract; --check-fix subset unstated | **Resolved.** The lib header names `cycle_rules` and its invariant. The `cycle_rules` comment says "--check-fix refuses both, and more (its import walk)". The unjudged-path class is settled by rows 722, 745 and 764. |
| i2 3 | asked_rule reached from two exit paths around the questions block | **Resolved.** `questions_rules` is extracted, so each rule has one call site and `cycle_rules` ends flat (`:1954`, `:1961-1980`). Its new output channel is finding 1. |
| i2 4 | chore_msg to log_class link one-way; land switches twice | **Resolved** (`:1772` comment) and **settled** (row 763). |
| i2 5 | Moved questions guard returns first (two-round refusals) | **Resolved by documentation.** The header says "That refusal is printed alone." |

## Fit against plan D7 and D13 (the chore land moved from pr-prep into a gated mode)

- **D7 ("merges are computed"):** the cycle land runs D7's sequence through the same code as `--merge`:
  - `merge_result` (merge-tree, no repo config);
  - `store_check` of HEAD and R;
  - rules on `diff-tree --no-renames MAIN R`;
  - `land`'s `commit-tree R -p MAIN_SHA -p HEAD`;
  - then the CAS, or the hardened `--ff-only` in W with the state gate re-run.

  The tests pin the parents, tree, message and both move paths. The fact-check executed the absence of hooks. The one departure is that the message carries no `Build-loop-gate:` trailer. That is intentional (it is what `--main-log` reads as chore), and the D7 prose is deferred by row 759.
- **D13:**
  - The chore class `--main-log` reads is defined once (`chore_record`, `isrecord`) and checked by the writer before it writes.
  - `--cycle-diff` keeps the pre-commit questions guard.
  - `--land-cycle` judges what actually lands (rows 753 and 719), which `--cycle-diff`'s index could not.
  - Dispatch's `merge-base --is-ancestor <chore tip> main` holds, because HEAD is parent 2.
  - D11 is untouched, since the orchestrator stays the only questions writer.
- **Authority placement:** the `cycle` authority's own checks (branch name, `--main` CAS base, clean index, record) sit in `land_cycle`, beside the verdict they guard. `land` stays the shared move. This mirrors how `--merge` keeps the policy and approval checks in the dispatch, outside `land`.

## What Looks Good

- **One rule set, two listings.**
  - `cycle_rules BASE SIDE` judges whatever listing `RAW_*` holds. The land judges the merge against main and `--cycle-diff` judges the index against the fork, with no second copy of any rule.
  - The caller-specific guard lives in its one caller.
- **The flat shape of `cycle_rules`:** per-path rules, then `questions_rules`, then the Asked: rule, each with one call site and every refusal printed in one run.
- **Reusing `truthrule` and `GATE_CODE` from the lib** rather than copying class lists. A new truth word propagates to both cycle modes and fails closed, and the lib header now records the invariant this consumer depends on.
- **`chore_record` shared by writer and reader.** The land cannot write a merge that `--main-log` would class as `other`, and the `log_class` refactor narrows the record name to `isrecord`'s form as row 725 asked.
- **`land` reused, not re-implemented.** Every guard on W (the worktree scan, the state gate re-run, the untracked collision via `CHANGED`, the CAS) applies to the chore land unchanged.
- **Tests.** Each of the three U4a tests pins the behaviour its name claims (probe2: all `ok`). This includes the rename-pairing case that only the merge-side judgment catches.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `questions_rules`' `cy.new` is empty both for "no entry filed" and "questions files refused", so the Asked: rule adds a refusal with a false cause (probed) | Minor | `scripts/build-loop.sh:1982-1991, 2019-2020, 1954, 1975` | High |
| 2 | Shared awk programs' and branches' comments still say "--cycle-diff's" / "the index" | Informational | `scripts/build-loop.sh:1808, 1823, 1844, 1946, 1999` | High |

## Overall Assessment

The branch keeps the system's structure intact and improves the area it touches. The orchestrator's chore land moves from an ungated hand merge into D7's computed path, through `land`'s single move. The cycle rules are one parameterised unit over two listings. The chore class has one definition shared by its writer and its reader. Every earlier architecture finding is resolved or settled by an override row whose code still matches it. Nothing is Structural or Coupling-grade.

The single most important remaining concern is finding 1. The `questions_rules` extraction left an implicit file channel whose empty state is ambiguous, which produces a misleading second refusal. It fails closed and can be fixed in place. Neither finding blocks landing U4a.

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff (claude-workflows) once its review-fix loop is clean.
- **Current task:** final confirming-pass architecture review of `feat/build-loop-u4a` vs main at b1a6f0a2, covering:
  - the `cycle_rules` / `questions_rules` / `cycle_diff` / `land_cycle` structure;
  - `land()`'s third authority;
  - `chore_msg` and `chore_record` shared with `log_class`;
  - `isrecord` in the lib and `truthrule`'s new caller;
  - the chore land's move from pr-prep into a gated mode, against D7/D13.
- **Success criterion (verbatim):** "a markdown report saved at the exact path your own prompt names, structured per your skill."
- **Alignment:**
  - **Saved where named:** `docs/reviews/architecture-review-2026-10-13-u4a-final.md`, first line `Commit: b1a6f0a2`.
  - **Structure:** it follows the architecture-review skill's sections. Each finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target.
  - **Earlier reports:** the resolution of every finding in i1 and i2 is in the table above.
  - **Focus items:**
    - structure and the questions_rules channel: finding 1, and the resolution rows for i2 1/3;
    - the third authority: the D7/D13 section and i1 3/4;
    - `chore_msg` and `chore_record`: i1 3, i2 4 and What Looks Good;
    - `isrecord`: i1 5;
    - `truthrule`'s caller: i2 2;
    - the pr-prep move: the D7/D13 section.
  - **Blocking:** none.
