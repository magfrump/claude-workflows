Commit: d8da1fba
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-handoff (claude-workflows)
**Scope:** U0c full range `feat/build-loop-u0b..feat/build-loop-u0c` (41065ce6, 1c7373d3, d8da1fba): `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`, `docs/working/plan-build-loop-handoff.md`, and the three commit messages. Final confirming pass, replicate 2 of 3.
**Commit:** d8da1fba
**Checked:** 2026-10-05
**Total claims checked:** 12
**Summary:** 8 verified, 3 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

The hallucination-pattern log was read. All test counts in this range match the bats runs. The shared execution provenance (E-bats, E-modes, E-mut, E-probe1, E-probe2, E-moved, SCRATCH) is defined in `docs/reviews/code-fact-check-report-build-loop-u0a-r2.md`, and every log it names is under `SCRATCH/logs/`. Additional run for this unit:
- **E-envrc:** `LC_ALL=C timeout 30 bash SCRATCH/wt-u0c/scripts/dev-cycle.sh --check-fix .envrc`, run in `SCRATCH/probe2-repo` (a scratch repo with `.envrc` tracked) at 2026-10-05T07:37:43Z, exit 0. Output in `SCRATCH/logs/envrc.txt`.

The need_root parenthetical "set -u fires there" (`:76-77`) is carried unchanged from U0a. It is reported once, as Incorrect, in the U0a report (Claim 7).

---

## Claim 1: "inrepo, dirok, skipped, check_brief and the import walk exit 1 (need_root) when ROOT_REAL is unset or is not the current directory"

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which u0c lib functions reach need_root in the caller's shell. It does not establish anything about callers' use of check_answer inside `$(...)` (dev-cycle.sh calls it directly).
**Legibility target:** for-author

Every function listed does exit. The list leaves out check_answer, which moved into the lib in this unit. check_answer exits 1 the same way through `skipped`:

```bash
# scripts/lib/dev-cycle-read.sh:460-461
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    if skipped "$f"; then echo "skip $a: $SKIP_AT is not a plain file or directory, so $f is not read"; return; fi
```
(excerpt ends :461; enclosing check_answer() continues to :476 — read)

E-probe1 P1: `check_answer Q-001` with ROOT_REAL unset prints `dev-cycle-read.sh: ROOT_REAL is not set; …` and returns rc=1, and the line after it never runs. The omission matters because the next sentence says to keep "the exiting checks" out of `$(...)`. check_answer prints its answer, so `$(...)` is the natural way to call it. Precise version: "inrepo, dirok, skipped, check_brief, check_answer and the import walk exit 1 …".

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-16, 457-476`, `SCRATCH/logs/probe1.txt` (P1, P2)

---

## Claim 2: "Inputs: check_brief and check_branch read the default branch's commit (check_brief also refuses a brief path that is not plain in the working tree); check_answer and the import walk read the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:19-22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where each function's content comes from. It does not establish that check_branch reads only MAIN_SHA: it also reads `refs/heads/<name>` and that branch's tip. It also does not establish that the walk reads only tracked files (it lists untracked ones too, through `--others`).
**Legibility target:** for-orchestrator-synthesis

check_brief reads `git cat-file blob "$MAIN_SHA:$a"` (`:258`) after `blocker "$a" file` on the working tree (`:247`). check_branch runs `git rev-list --count "$MAIN_SHA..$sha"` (`:296`). check_answer runs awk over `docs/working/questions.md` relative to the cwd, which need_root ties to ROOT_REAL (`:460-463`). The walk runs `git ls-files` plus `grep -oE "$IMPORT_RE" -- "$f"` on checkout files (`:360-374`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:239-299, 347-376, 457-476`

---

## Claim 3: lib header contents list (":2-6 … the brief, branch and answer checks, the instruction-file import walk, and the default branch") and dev-cycle.sh's source-line comment (":83-86")

**Location:** `scripts/lib/dev-cycle-read.sh:2-6`, `scripts/dev-cycle.sh:83-86`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lists against the lib's definitions (T29). It does not establish anything about build-loop.sh, which is planned.
**Legibility target:** for-orchestrator-synthesis

T29 at u0c checks 21 functions and 11 globals, including `lower imported_names check_answer` and `ANSWER_AWK INSTRUCTION_FILE IMPORT_RE IMPORTED IMPORTED_DONE`, and passes. The mutant `c-t29-drop-var` (IMPORTED_DONE undeclared) is KILLED.

**Evidence:** `test/scripts/dev-cycle.bats` T29, `SCRATCH/logs/mutations.txt`

---

## Claim 4: "One result is cached, for the root in IMPORTED_DONE; a call for another ROOT_REAL recomputes it."

**Location:** `scripts/lib/dev-cycle-read.sh:342-343`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache hit for the same root and the recompute with a reset for another root. It does not establish anything about cache invalidation when the files under one root change mid-process (they are not re-read).
**Legibility target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:349-350
  need_root
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'
```
(excerpt ends :350; enclosing imported_names() continues to :376 — read)

E-probe1 P6: a second call for the same root leaves the sentinel `IMPORTED=sentinel` untouched. The bats test gives ` docs/a.md ` and then ` docs/b.md ` for two roots. E-mut KILLS `c-cache-unkeyed` and `c-cache-noreset`. The noreset mutant yields `docs/a.md docs/b.md`.

**Evidence:** `SCRATCH/logs/probe1.txt` (P6), `SCRATCH/mut/c-cache-noreset.out`

---

## Claim 5: dev-cycle.sh "# shellcheck disable=SC2034  # read by the lib's file rules and import walk" (on ROOT_REAL)

**Location:** `scripts/dev-cycle.sh:115`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which code reads ROOT_REAL. It does not establish whether shellcheck would warn without the directive (shellcheck was not run).
**Legibility target:** for-orchestrator-synthesis

ROOT_REAL is read in need_root (`:81-82`), rawfile and plaindir (`:84`, `:87`) and imported_names (`:350`, `:370`). dev-cycle.sh itself never reads it after the assignment. (Paraphrased: no quote available because this rests on a grep of every `ROOT_REAL` use in the two files.)

**Evidence:** `scripts/dev-cycle.sh:113-116`, `scripts/lib/dev-cycle-read.sh:81-87, 349-370`

---

## Claim 6: commit 41065ce6: "INSTRUCTION_FILE and the @-import walk (lower, imported_names) and ANSWER_AWK with check_answer, moved verbatim. check_fix, check_path and check_write stay in dev-cycle.sh … check_answer still reads the working tree; U1 moves it to main's commit (D8). … The 53 existing tests pass, the digest of this repo is byte-identical to main's, and --check-brief/-branch/-answer/-fix print the same"

**Location:** commit 41065ce6 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line diff at 41065ce6 (header-only differences), where check_fix, check_path and check_write live, plan D8 and U1, and output identity at the u0c tip. It does not establish byte-identity at 41065ce6 itself.
**Legibility target:** for-orchestrator-synthesis

E-moved for 41065ce6: the only differences are the header lines of the source comment. The cumulative main→u0c diff differs only in the declared guards and comment edits. `check_path`, `check_write` and `check_fix` are defined in dev-cycle.sh (`:139`, `:155`, `:167`). Plan `:221`: "`--check-answer` moves into the lib and reads main's commit (D8)". E-bats u0c: 59 ok. E-modes: identical.

**Evidence:** `SCRATCH/rm-41065ce6.txt`, `SCRATCH/add-41065ce6.txt`, `SCRATCH/logs/moved-diff.txt`, `docs/working/plan-build-loop-handoff.md:85, 221, 270`

---

## Claim 7: commit 1c7373d3: "without ROOT_REAL the walk returned an empty import set and cached it, turning off check_fix's import refusal."

**Location:** commit 1c7373d3 message
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk at its parent 41065ce6 in the landed history. It does not re-raise the point, which override-log row 210 (2026-10-05) settled as Won't-Fix.
**Legibility target:** for-author

E-probe2 (d), lib at 41065ce6. In a repo whose root holds `CLAUDE.md`, the walk exits 1 via inrepo's need_root. In a repo with no instruction file it returns and caches (`DONE=[1]`). The empty set is cached only when the walk finds no instruction file. Settled, not re-raised.

**Evidence:** `SCRATCH/logs/probe2.txt` (d), `docs/reviews/override-log.md:210`

---

## Claim 8: commit 1c7373d3: "IMPORTED_DONE now holds the root it was computed for. New test covers both." and the test "the import walk stops without ROOT_REAL and recomputes for another repo root"

**Location:** commit 1c7373d3 message; `test/scripts/dev-cycle.bats` last test
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's two assertions and whether they catch the guard mutations. It does not establish anything about the cwd-elsewhere case for the walk, which the U0a test covers through need_root.
**Legibility target:** for-orchestrator-synthesis

E-mut: `c-walk-noneed`, `c-cache-unkeyed` and `c-cache-noreset` are all KILLED by this test. The test name matches its assertions (status 1 with "ROOT_REAL is not set", then two different import sets).

**Evidence:** `SCRATCH/logs/mutations.txt`, `test/scripts/dev-cycle.bats:1097-1110`

---

## Claim 9: plan amendment: "F11's row below and step 13's Q-103 text now carry this precondition."

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the location and content of the two edits. It does not establish whether the precondition should also carry the architecture review's "with no untracked instruction files" qualifier (see Claim 10's scope).
**Legibility target:** for-author

Both edits exist and carry the precondition. F11 (`:126`): "The walk reads the working tree, so the gate runs it in a worktree at `MAIN_SHA` or through a commit-reading variant (amendment 2026-10-05)". Step 13 (`:290`): "F11 (with its `MAIN_SHA` precondition for the import walk)". The amendment sits at `:192`, though, so F11's row is above it, not "below". Precise version: "F11's row above and step 13's Q-103 text below".

**Evidence:** `docs/working/plan-build-loop-handoff.md:126, 192, 290`

---

## Claim 10: plan amendment body vs `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md` (the policies differ on `working/`, `reviews/`, `thoughts/`, `constraints.md`; the predicate stays; U2 builds the floor from `INSTRUCTION_FILE`, the walk and `writable` plus a leading-dot-aware dot test; `isimported`; shared list or `you: judgment`; B2 gaps confirmed by U2's review)

**Location:** `docs/working/plan-build-loop-handoff.md:188, 192`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each element against review findings 1 to 4 (`:59-77`, `:107`, `:127`, `:147`). The amendment does not carry two parts of finding 4's recommendation: "with no untracked instruction files" and "and test it". It also adds "it is not extracted later either", which goes beyond the review but agrees with it ("leave the two policies in the scripts that own them").
**Legibility target:** for-orchestrator-synthesis

The review's `:63-67` lists the differences: "`check_fix` denies all of `working/` and `reviews/` … allows `docs/thoughts/` and `docs/constraints.md` … dot test misses a leading-dot top-level path … because such a path also fails `^docs/`". Recommendations `:76`, `:107` and `:127` match the amendment's floor function, `isimported`, and shared list or `you: judgment` entry. `:77` says U2's pass "should confirm it rather than inherit it unexamined".

**Evidence:** `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md:59-77, 105-107, 125-127, 145-147`, `docs/working/plan-build-loop-handoff.md:188-192`

---

## Claim 11: plan amendment: "`check_fix`'s `*/.*` test misses it, harmlessly there because such a path also fails `^docs/`" / commit d8da1fba: "'top-level dotfiles' is dropped from the list of differences (both policies refuse them)"

**Location:** `docs/working/plan-build-loop-handoff.md:192`; commit d8da1fba message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix on a tracked top-level dotfile. It does not establish the floor's behaviour, because the floor is U2 code that does not exist yet.
**Legibility target:** for-orchestrator-synthesis

The predicate is `[[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || … || "$a" == */.* || …` (`scripts/dev-cycle.sh:176-177`). E-envrc prints `skip .envrc: in-cycle fixes edit only tracked .md documentation under docs/ …`. D5 floor item 2 covers "any `.`-prefixed component" (`plan:70`).

**Evidence:** `scripts/dev-cycle.sh:167-182`, `SCRATCH/logs/envrc.txt`, `docs/working/plan-build-loop-handoff.md:70`

---

## Claim 12: plan amendment: "U0 also split into three units (U0a/U0b/U0c), not two: moved lines count twice under the 400-line cap." and the motive "building a policy switch for a caller that does not exist yet"

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Configuration / Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The split arithmetic is verified (U0a report, Claim 13). The unverifiable part is whether other plan passages were updated for three units. The rollback step (`:374`) still reads "`<U0b> <U0a>`" with no U0c, but that line is outside this range's diff, so it is noted rather than verdicted.
**Legibility target:** for-orchestrator-synthesis

The size arithmetic holds. Plan `:374` (unchanged in this range) reads "`git revert -m 1 <U5> … <U1> <U0b> <U0a>`", so a reader following the rollback would miss U0c's merge. Settling this needs a decision on whether the amendment is meant to cover the rollback list.

**Evidence:** `docs/working/plan-build-loop-handoff.md:268, 304, 374`

---

## Claims Requiring Attention

### Incorrect
- None new. The need_root "set -u fires there" clause (`:76-77`) is carried from U0a; see the U0a report, Claim 7.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`scripts/lib/dev-cycle-read.sh:12-14`): add check_answer to the list of checks that exit 1. It exits through `skipped`.
- **Claim 7** (commit 1c7373d3): settled in override-log row 210. Listed only for completeness.
- **Claim 9** (`docs/working/plan-build-loop-handoff.md:192`): "F11's row below" should be "above". The row is at `:126`.

### Unverifiable
- **Claim 12** (`docs/working/plan-build-loop-handoff.md:374`): the rollback list still names only U0b and U0a. Someone needs to decide whether the three-unit split should update it.

## Goal-Alignment Note

U0c's goal is to finish the behaviour-neutral extraction and record the check_fix amendment. All 59 tests pass. The digest and every check mode match main's output byte for byte. The new walk guard and the root-keyed cache are pinned by a test that fails on all three mutants. The amendment matches the architecture review it cites. The items to fix are wording only: check_answer missing from the header's list of checks that exit, "below" that should be "above" in the amendment, and the stale rollback list outside the diff. None of them blocks landing.
