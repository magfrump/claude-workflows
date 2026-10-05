Commit: d8da1fba

# Code Fact-Check Report

**Commit:** d8da1fba
**Replication:** k=3, replicate 1 (final confirming pass, iteration 3, full scope)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-handoff)
**Scope:** U0c full range `git diff feat/build-loop-u0b..feat/build-loop-u0c` (41065ce6, 1c7373d3, d8da1fba: scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md) and the three commit messages; plan edits checked against `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md`. U0a/U0b are context only. Scratch: `/home/node/.claude/jobs/989f3e5a/tmp/review/final-fc-r1` (below: `$SCRATCH`).
**Checked:** 2026-10-05
**Total claims checked:** 19
**Summary:** 15 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read; no claim matches a logged pattern. Override-log rows for feat/build-loop-u0c dated 2026-10-05 (rows 202-207, 210) were read. Claim 13 is row 210's subject and is not re-raised.

Shared executions (2026-10-05, 07:30Z-07:40Z, detached worktrees under `$SCRATCH/wt-*`):
- E1 `bats test/scripts/dev-cycle.bats` at 41065ce6, 1c7373d3, d8da1fba → exit 0; 58 / 59 / 59 ok, every main test name present. Logs `$SCRATCH/logs/bats-{41065ce6,1c7373d3,u0c}.log`, `$SCRATCH/logs/intermediate.log`.
- E2 digest and every `--check-*` mode on this repo (cwd `$SCRATCH/wt-main`, DEV_CYCLE_TODAY=2026-10-05; `--check-answer` over every Q-ID in both questions files plus Q-999 and `bad`; `--check-fix` over every tracked docs .md, README.md, the root .md files, `.envrc` and `docs/working/x.md`) with each commit's script, `diff -r` against main's: identical at all three. `$SCRATCH/compare.sh`, `$SCRATCH/intermediate.sh`; logs `$SCRATCH/logs/compare-summary.log`, `$SCRATCH/logs/intermediate.log`, outputs `$SCRATCH/logs/out-*/`.
- E3 mutations of the U0c tip (`$SCRATCH/mutate.sh`, 07:34:31Z): `$SCRATCH/logs/mutate.log`.
- E4 `$SCRATCH/walk-prefix.sh` (07:36:04Z): the walk without ROOT_REAL at 41065ce6, 27e38dc4 (the reviewed commit) and 1c7373d3. `$SCRATCH/logs/walk-prefix.log`.
- E5 `$SCRATCH/answer-noroot.sh` (07:38:44Z): check_answer without ROOT_REAL. `$SCRATCH/logs/answer-noroot.log`.
- E6 move check: `$SCRATCH/logs/move-verbatim.log`. E7 `$SCRATCH/setu.sh`: `$SCRATCH/logs/setu.log`.

---

## Claim 1: "the output scrub, the plain-file and path-form rules, the cycle's own file names, the Markdown shapes the readers refuse (FENCE_AWK), the brief, branch and answer checks, the instruction-file import walk, and the default branch."

**Location:** `scripts/lib/dev-cycle-read.sh:3-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib's contents at d8da1fba.
**Legibility target:** for-orchestrator-synthesis

Added in this range: `INSTRUCTION_FILE=` (`:331`), `IMPORTED=$'\n'; IMPORTED_DONE=""` (`:344`), `lower`, `imported_names` (`:346-376`), `ANSWER_AWK=` (`:403`) and `check_answer` (`:457-476`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:3-6`, `:328-476`

---

## Claim 2: "inrepo, dirok, skipped, check_brief and the import walk exit 1 (need_root) when ROOT_REAL is unset or is not the current directory"

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named function, which does exit; does not hold as the complete list the next sentence relies on ("Call the exiting checks in the caller's shell"): check_answer, moved in this range, also exits.
**Legibility target:** for-author

`imported_names() { local ...; need_root` (`:347-349`); E3's M13 fails the walk test. check_answer also reaches need_root: `if skipped "$f"; then ...` (`:461`), and skipped begins `need_root;` (`:113`). E5 at this tip, ROOT_REAL unset: `check_answer Q-104` prints `dev-cycle-read.sh: ROOT_REAL is not set ...` and exits 1. Written as `r="$(check_answer Q-104)" || true` (a natural way to call a function that prints its answer), the caller continues with `r=[]`. The precise version adds check_answer to the list (it exits through skipped).

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-16`, `:113`, `:347-350`, `:457-462`, `$SCRATCH/logs/answer-noroot.log`, `$SCRATCH/logs/mutate.log`

---

## Claim 3: "rawfile, plaindir and blocker then read nothing as plain."

**Location:** `scripts/lib/dev-cycle-read.sh:14`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same sentence as U0a claim 5, rewrapped in this range.
**Legibility target:** for-author

E7: with ROOT_REAL set to another tree, a cwd symlink resolving to `$ROOT_REAL/f.md` gives `rawfile f.md: plain`. Exact: "nothing outside ROOT_REAL".

**Evidence:** `scripts/lib/dev-cycle-read.sh:84`, `:87`, `$SCRATCH/logs/setu.log`

---

## Claim 4: "Inputs: check_brief and check_branch read the default branch's commit (check_brief also refuses a brief path that is not plain in the working tree); check_answer and the import walk read the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:19-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each function's data source; does not establish which untracked files the walk reads beyond what its own comment says (`--others`).
**Legibility target:** for-orchestrator-synthesis

check_brief reads `git ls-tree "$MAIN_SHA"` and `git cat-file blob "$MAIN_SHA:$a"` (`:250`, `:258`) after `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink ..."` (`:247`); check_branch counts `"$MAIN_SHA..$sha"` (`:296`). check_answer runs awk on `docs/working/questions.md` and the archive as files (`:460-463`); the walk lists `git ls-files -z` plus `--others` and greps each file (`:360-374`), with need_root holding cwd = ROOT_REAL.

**Evidence:** `scripts/lib/dev-cycle-read.sh:239-276`, `:286-299`, `:347-376`, `:457-476`

---

## Claim 5: Header sentences rewrapped in this range: "The caller runs resolve_main once per process (a second call re-reads main); check_brief and check_branch skip every argument unless it returned 0 with main found by name. Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker." and "Call the exiting checks in the caller's shell, not inside $(...) ..."

**Location:** `scripts/lib/dev-cycle-read.sh:15-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same code as U0b claims 4-5 and U0a claims 6-7, unchanged at this tip; dev-cycle.sh still calls resolve_main once (`scripts/dev-cycle.sh:183`).
**Legibility target:** for-orchestrator-synthesis

`resolve_main || [[ -n "$CHECK" ]] || {...}` (`scripts/dev-cycle.sh:183`), the only call. E3: M10, M11, M15 fail the skip test at this tip; E5 shows the subshell behaviour.

**Evidence:** `scripts/lib/dev-cycle-read.sh:15-19`, `:230-231`, `scripts/dev-cycle.sh:183`, `$SCRATCH/logs/mutate.log`, `$SCRATCH/logs/answer-noroot.log`

---

## Claim 6: "One result is cached, for the root in IMPORTED_DONE; a call for another ROOT_REAL recomputes it."

**Location:** `scripts/lib/dev-cycle-read.sh:342-343`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache key and recompute; does not establish freshness within one root (a changed tree under the same root is not re-walked, which "one result is cached" implies).
**Legibility target:** for-orchestrator-synthesis

`[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'` (`:350`). The walk test computes ` docs/a.md ` then ` docs/b.md ` for a second root; E3's M14 (cache keyed on nothing) fails it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:342-350`, `test/scripts/dev-cycle.bats:1097-1110`, `$SCRATCH/logs/mutate.log`

---

## Claim 7: "The reader ... from this script's own directory: the scrub, the file and path rules, FENCE_AWK, the brief, branch and answer checks, the instruction-file import walk, and the default branch." / "# shellcheck disable=SC2034  # read by the lib's file rules and import walk"

**Location:** `scripts/dev-cycle.sh:83-86`, `:115`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against the lib and ROOT_REAL's readers; does not establish shellcheck's own output.
**Legibility target:** for-orchestrator-synthesis

`ROOT_REAL="$(pwd -P)"` (`:116`) is the only ROOT_REAL reference in dev-cycle.sh (`rg -n ROOT_REAL scripts/dev-cycle.sh` → `:116` only). The lib reads it in need_root, rawfile, plaindir (`:81-87`) and the walk (`:350`, `:370`).

**Evidence:** `scripts/dev-cycle.sh:83-90`, `:115-116`, `scripts/lib/dev-cycle-read.sh:80-87`, `:350`, `:370`

---

## Claim 8: 41065ce6: "The lib now also holds INSTRUCTION_FILE and the @-import walk (lower, imported_names) and ANSWER_AWK with check_answer, moved verbatim. check_fix, check_path and check_write stay in dev-cycle.sh, check_fix's predicate included although the plan lists it: U2 writes the floor as its own lib function instead (plan amendment). check_answer still reads the working tree; U1 moves it to main's commit (D8)."

**Location:** commit 41065ce6 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers line content of the moved blocks, where the three checks live, and the plan's D8/U1 text.
**Legibility target:** for-orchestrator-synthesis

E6 for 41065ce6: the only non-matching lines are the two header/source-line comment lines; every moved line matches. `check_path() {`, `check_write() {`, `check_fix() {` at `scripts/dev-cycle.sh:139`, `:155`, `:167`. Plan: "`--check-answer` moves into the lib and reads main's commit (D8)" (`docs/working/plan-build-loop-handoff.md:221`) and U1 "`check_answer` reading main's commit" (`:270`).

**Evidence:** `$SCRATCH/logs/move-verbatim.log`, `scripts/dev-cycle.sh:139-181`, `docs/working/plan-build-loop-handoff.md:85`, `:221`, `:270`

---

## Claim 9: 41065ce6: "Tests: T29 lists the new functions and variables. The 53 existing tests pass, the digest of this repo is byte-identical to main's, and --check-brief/-branch/-answer/-fix print the same on this repo."

**Location:** commit 41065ce6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 41065ce6 itself.
**Legibility target:** for-orchestrator-synthesis

E1 at 41065ce6: 58 ok, main's 53 present. E2: identical. T29 lists `lower imported_names check_answer` and `ANSWER_AWK INSTRUCTION_FILE IMPORT_RE`.

**Evidence:** `$SCRATCH/logs/bats-41065ce6.log`, `$SCRATCH/logs/intermediate.log`, `test/scripts/dev-cycle.bats:1023-1038`

---

## Claim 10: 1c7373d3: "Security I2: the cache recorded no root, so a caller that changed checkout got the first one's set; IMPORTED_DONE now holds the root it was computed for. New test covers both."

**Location:** commit 1c7373d3 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parent's `IMPORTED_DONE=1` cache and the new keyed cache with its test.
**Legibility target:** for-orchestrator-synthesis

Parent 41065ce6: `[[ -n "$IMPORTED_DONE" ]] && return; IMPORTED_DONE=1`. Tip: claim 6. E3: M14 (restoring the unkeyed form) and M13 (dropping need_root) each fail "the import walk stops without ROOT_REAL and recomputes for another repo root".

**Evidence:** `scripts/lib/dev-cycle-read.sh:347-350`, `$SCRATCH/logs/mutate.log`

---

## Claim 11: 1c7373d3: "Fact-check 10b (Incorrect): the plan lists "check_fix's predicate" for the lib, which U0 does not move (U0a's and U0c's messages, reworded before merge, now say so). The plan carries a dated amendment ... The lib header says which readers read main's commit and which the working tree (api-consistency U0c); the ROOT_REAL directive names the walk; T29 checks the lib's globals are declared."

**Location:** commit 1c7373d3 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed edit's presence.
**Legibility target:** for-orchestrator-synthesis

4ef450da: "The plan's lib list also names check_fix's predicate; it stays in dev-cycle.sh"; 41065ce6: "check_fix's predicate included although the plan lists it". Header `:19-22` (claim 4); directive `scripts/dev-cycle.sh:115` (claim 7); T29: `for v in SKIPPED SKIP_AT MAIN MAIN_SHA MAIN_BY_NAME IMPORTED IMPORTED_DONE; do declare -p "$v" ...`.

**Evidence:** commits 4ef450da, 41065ce6; `scripts/lib/dev-cycle-read.sh:19-22`; `test/scripts/dev-cycle.bats:1023-1038`

---

## Claim 12: 1c7373d3 Notes: "all tests at this tip pass (main's 53 among them); the digest, --check-answer and --check-fix output on this repo are unchanged."

**Location:** commit 1c7373d3 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 1c7373d3 itself.
**Legibility target:** for-orchestrator-synthesis

E1 at 1c7373d3: 59 ok; E2 identical for every mode.

**Evidence:** `$SCRATCH/logs/bats-1c7373d3.log`, `$SCRATCH/logs/intermediate.log`

---

## Claim 13: 1c7373d3: "Security L1: without ROOT_REAL the walk returned an empty import set and cached it, turning off check_fix's import refusal. It now stops (need_root)."

**Location:** commit 1c7373d3 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reviewed 27e38dc4 and the actual parent 41065ce6; settled by override-log row 210 and not re-raised.
**Legibility target:** for-author

E4: 27e38dc4 prints `ROOT_REAL: unbound variable` twice, then `walked, IMPORTED=$'\n'`, rc 0, as described. At the parent 41065ce6, inrepo's need_root already stopped it (`ROOT_REAL is not set ...`, rc 1) when an instruction file exists. The top-of-walk guard is still needed for the cache key and the no-instruction-file case.

**Evidence:** `$SCRATCH/logs/walk-prefix.log`, `docs/reviews/override-log.md:210`

---

## Claim 14: d8da1fba: "The F11 row and step 13's Q-103 text now carry the precondition (the gate runs the import walk at MAIN_SHA)." / "the floor's dot test must also refuse a leading-dot top-level path (.envrc), and U2's review confirms the walk's B2 gaps rather than inheriting them. Both restored; "top-level dotfiles" is dropped from the list of differences (both policies refuse them). It now says the predicate stays in dev-cycle.sh for good." / "computed once per process and repo root" overstated the cache"

**Location:** commit d8da1fba message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each described edit and the "both refuse" fact for `.envrc`.
**Legibility target:** for-orchestrator-synthesis

F11 row (`plan:126`) and step 13 (`plan:290`) carry the precondition. "both policies refuse them": E2's `--check-fix .envrc` prints `skip .envrc: in-cycle fixes edit only tracked .md documentation under docs/ ...` (`$SCRATCH/logs/out-u0c/fix:716`), and the floor's item 2 is "any `.`-prefixed component" (`plan:70`). Amendment: "it is not extracted later either" (`plan:192`). Cache comment: claim 6. "all 59 tests at this tip pass": E1.

**Evidence:** `docs/working/plan-build-loop-handoff.md:70`, `:126`, `:192`, `:290`, `$SCRATCH/logs/out-u0c/fix`, `$SCRATCH/logs/bats-u0c.log`

---

## Claim 15: Plan amendment: "`check_fix` is an allowlist of docs an in-cycle fix may edit; D5's floor is a denylist over any path, and the two differ (`working/`, `reviews/`, `thoughts/`, `constraints.md`). Moving the predicate in U0 would mean splitting `check_fix`, which a pure move cannot do, and building a policy switch for a caller that does not exist yet. ... U2 instead writes the floor as its own lib function from the shared pieces already in the lib (`INSTRUCTION_FILE`, the import walk, `writable`) plus a dot-component test that also refuses a leading-dot top-level path such as `.envrc` (`check_fix`'s `*/.*` test misses it, harmlessly there because such a path also fails `^docs/`), adds an `isimported` predicate ..., and either shares one read-as-truth list with `check_fix` or files the difference as a `you: judgment` entry."

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paragraph's agreement with architecture findings 1-3 and the `.envrc` mechanism; does not establish U2's future implementation.
**Legibility target:** for-orchestrator-synthesis

The review lists the same four differences and the shared parts "`INSTRUCTION_FILE`, the import walk, `writable`, and a dot-component test", calls the split "not a move" that "would put a policy switch into the lib ... to serve a consumer that does not exist yet", recommends "`check_fix` stays whole in dev-cycle.sh", an `isimported` predicate (finding 2), and "either share a single `truthdoc()` list ... or file a `you: judgment` entry" (finding 3). Mechanism: `"$a" == */.*` (`scripts/dev-cycle.sh:177`) has no slash to match in `.envrc`, which fails `^docs/.*\.md$` instead (E2 output above).

**Evidence:** `docs/working/plan-build-loop-handoff.md:192`, `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md:29-125`, `scripts/dev-cycle.sh:175-177`

---

## Claim 16: Plan amendment and F11 row: "The import walk reads the working tree at `ROOT_REAL`, so the gate must run it in a worktree checked out at `MAIN_SHA` or use a commit-reading variant" / "the gate runs it in a worktree at `MAIN_SHA` or through a commit-reading variant (amendment 2026-10-05)"

**Location:** `docs/working/plan-build-loop-handoff.md:192`, `:126`; step 13 `:290`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the precondition against the walk's code and its cited source; does not establish how U2 builds the worktree.
**Legibility target:** for-author

The walk reads more than tracked files at a commit: `GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'` (`scripts/lib/dev-cycle-read.sh:361`), so untracked and ignored instruction files (its comment names CLAUDE.local.md) in that worktree join the import set. The cited source states the precondition with that qualifier: "the gate runs the walk in a worktree checked out at `MAIN_SHA` with no untracked instruction files, and test it" (architecture review finding 4, `:147`). The amendment, F11 row and step 13 drop "with no untracked instruction files". Precise version: "a worktree checked out at `MAIN_SHA` with no untracked instruction files, or a commit-reading variant".

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `:192`, `:290`, `scripts/lib/dev-cycle-read.sh:332-336`, `:360-362`, `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md:145-147`

---

## Claim 17: Plan amendment: "Floor item 1 makes the gate a second user of the walk's refusal set (boundary B2 in the pass-38 security review), so the walk's known gaps (F11 "partly") become gate gaps too; U2's architecture and security review confirms that rather than inheriting it. Source: `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md`. U0 also split into three units (U0a/U0b/U0c), not two: moved lines count twice under the 400-line cap."

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with finding 1's security implication and the unit-split rule; the Source file exists in this worktree but is untracked (not on any of the three branches), so the reference resolves only once the review artifacts are committed.
**Legibility target:** for-orchestrator-synthesis

Review: "this places floor item 1 on B2 ... B2's known gap ... becomes a gate gap as well ... The combined architecture and security pass on U2 should confirm it rather than inherit it unexamined" (`:77`). Plan: "U0, extract the lib (~260 lines moved; U0a/U0b if it measures over 400)" (`:266` at feat/build-loop-handoff) and "moved lines count twice" (`:264`).

**Evidence:** `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md:77`, `docs/working/plan-build-loop-handoff.md:192`, `:264-266`

---

## Claim 18: Plan list line: "`writable` and `isbrief` (`check_fix`'s predicate stays in dev-cycle.sh: amended 2026-10-05, see below)"

**Location:** `docs/working/plan-build-loop-handoff.md:187`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the U0c tip's placement of writable, isbrief and check_fix.
**Legibility target:** for-orchestrator-synthesis

`isbrief()` and `writable()` are in the lib (`scripts/lib/dev-cycle-read.sh:145-150`); `check_fix() {` is in `scripts/dev-cycle.sh:167`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:145-150`, `scripts/dev-cycle.sh:167-181`

---

## Claim 19: New test name vs assertions: "the import walk stops without ROOT_REAL and recomputes for another repo root"; T29's added checks

**Location:** `test/scripts/dev-cycle.bats:1097-1110`, `:1023-1038`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name against its assertions (exit 1 with "ROOT_REAL is not set"; ` docs/a.md ` then ` docs/b.md `) and mutation sensitivity; does not test the not-the-cwd stop for the walk specifically (inrepo's test covers need_root's cwd half).
**Legibility target:** for-orchestrator-synthesis

E3: M13 and M14 fail only this test; the unmutated copy passes all six new tests. T29 fails under M01.

**Evidence:** `test/scripts/dev-cycle.bats:1097-1110`, `$SCRATCH/logs/mutate.log`

---

## Claims Requiring Attention

### Incorrect
- None in this range. (U0a's need_root comment "set -u fires there" is unchanged here and still wrong; see U0a claim 9b.)

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`scripts/lib/dev-cycle-read.sh:12-14`): check_answer also exits 1 through skipped's need_root but is missing from the list of exiting checks that must not run inside `$(...)`. Add it.
- **Claim 3** (`scripts/lib/dev-cycle-read.sh:14`): "nothing outside ROOT_REAL" is exact (U0a claim 5).
- **Claim 13** (commit 1c7373d3): pre-rebase behaviour. Settled by override-log row 210.
- **Claim 16** (`docs/working/plan-build-loop-handoff.md:126`, `:192`, `:290`): the precondition omits "with no untracked instruction files" from its source. The walk lists `--others`, so a worktree at MAIN_SHA alone is not enough.

### Unverifiable
- None.

## Goal-Alignment Note

U0c's moves are verbatim, and dev-cycle.sh's digest and every check mode, `--check-answer` and `--check-fix` included, are byte-identical to main on this repo. Tests are 58/59/59, main's 53 among them. The walk's need_root and root-keyed cache work as described, and their test fails without each one. The plan amendment matches the architecture review on every point but one: it drops the "no untracked instruction files" qualifier on the MAIN_SHA-worktree precondition. That matters only for U2's gate design, so recording it now keeps U2 from inheriting the gap. The header's exiting-checks list omits check_answer, a wording gap a second caller could trip on. Neither blocks landing U0c.
