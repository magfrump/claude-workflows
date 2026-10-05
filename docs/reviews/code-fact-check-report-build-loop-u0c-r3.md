Commit: d8da1fba

# Code Fact-Check Report

**Commit:** d8da1fba
**Replication:** k=3, replicate 3 (final confirming pass, iteration 3)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-handoff, feat/build-loop-u0c)
**Scope:** Full U0c range `git diff feat/build-loop-u0b..feat/build-loop-u0c` (41065ce6, 1c7373d3, d8da1fba): scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, and the three commit messages; the plan amendment checked against docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md. U0a/U0b are context only.
**Checked:** 2026-10-05
**Total claims checked:** 34
**Summary:** 29 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution logs: `/home/node/.claude/jobs/989f3e5a/tmp/review/final-fc-r3/logs/` (`LOGS/` below), produced by `.../final-fc-r3/{run-modes.sh,run-commits.sh,exp.sh,exp2.sh,mutate.sh}`. Hallucination log read; no claim matches a logged pattern (test counts checked against `bats`). U0a's Incorrect need_root parenthetical ("set -u fires there", `scripts/lib/dev-cycle-read.sh:76-77` here) is unchanged in this range and is reported in the U0a report.

---

## Claim 1: "the output scrub, the plain-file and path-form rules, the cycle's own file names, the Markdown shapes the readers refuse (FENCE_AWK), the brief, branch and answer checks, the instruction-file import walk, and the default branch."

**Location:** `scripts/lib/dev-cycle-read.sh:2-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib's contents at the tip; does not establish build-loop.sh's use (the file does not exist).
**Legibility target:** for-orchestrator-synthesis

The lib adds `INSTRUCTION_FILE` (`:331`), `IMPORTED`/`IMPORT_RE`, `lower`, `imported_names` (`:344-376`), `ANSWER_AWK` (`:403`) and `check_answer` (`:457`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:328-476`

---

## Claim 2: "inrepo, dirok, skipped, check_brief and the import walk exit 1 (need_root) when ROOT_REAL is unset or is not the current directory"

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed function and check_answer; does not establish behaviour of future additions.
**Legibility target:** for-author

Each listed function does exit: `imported_names() { local ...; need_root` (`:347-349`). E7b printed the need_root message, rc=1. But check_answer, which this range moved into the lib, exits 1 as well, through its first `skipped` call (`if skipped "$f"; then`, `:461`). The list leaves it out. E3: `check_answer Q-001` with ROOT_REAL unset → "ROOT_REAL is not set", subshell rc=1. E3b: inside `$(...)` the caller kept running. A reader who uses the list to decide which calls must stay out of `$(...)` would wrap check_answer. Precise version: "inrepo, dirok, skipped, check_brief, check_answer and the import walk exit 1".

Command: `bash exp.sh .../wt-build-loop-u0c` · cwd scratch · exit 0 · 2026-10-05T00:34:06-07:00, E3/E3b/E7b.

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-16,113,347-350,457-462`, `LOGS/exp.txt`

---

## Claim 3a: "rawfile, plaindir and blocker then read nothing as plain" (ROOT_REAL unset)

**Location:** `scripts/lib/dev-cycle-read.sh:14`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Unset case only (3b is the other).
**Legibility target:** for-orchestrator-synthesis

`rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && ...` (`:84`). E1: `blocker f file` printed `f`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:84,87`, `LOGS/exp.txt`

---

## Claim 3b: "...or is not the current directory; rawfile, plaindir and blocker then read nothing as plain."

**Location:** `scripts/lib/dev-cycle-read.sh:13-14`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers direct calls with a root other than the cwd; dev-cycle.sh never makes them.
**Legibility target:** for-author

`[[ "$r" == "$ROOT_REAL/$1" ]]` (`:84`) passes for a symlink in the cwd that leads into ROOT_REAL at the same relative path. E2: `rawfile d/f: plain`, `plaindir d: plain` (a symlink in the cwd), `blocker d/f: []`. This range rewrote the sentence (adding the import walk), so it is in scope here too. Precise version: limit "read nothing as plain" to the unset case.

Command: `bash exp.sh .../wt-build-loop-u0c` · exit 0 · 2026-10-05T00:34:06-07:00, E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:84,87,95-105`, `LOGS/exp.txt`

---

## Claim 4: "Call the exiting checks in the caller's shell, not inside $(...) or `local x="$(...)"`, where an exit ends only the subshell."

**Location:** `scripts/lib/dev-cycle-read.sh:14-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism and every call site in dev-cycle.sh and the lib; does not cover future callers.
**Legibility target:** for-orchestrator-synthesis

E3b: `after $(...): rc=1 out=[] caller still running`. In both files, `rg` for an exiting check inside `$(...)` or after a pipe found nothing. The walk calls `inrepo` inside `while ... done < <(...)` loops, which run in the caller's shell (`:351-362,366-374`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:351-375`, `scripts/dev-cycle.sh:174,191-200`, `LOGS/exp.txt`

---

## Claim 5: "The caller runs resolve_main once per process (a second call re-reads main)"

**Location:** `scripts/lib/dev-cycle-read.sh:16-17`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** dev-cycle.sh's single call and the re-read; not future callers.
**Legibility target:** for-orchestrator-synthesis

The only call is `resolve_main || [[ -n "$CHECK" ]] || { ...; exit 1; }` (`scripts/dev-cycle.sh:183`). E6: `first=e412795 second=7e3c695`.

**Evidence:** `scripts/dev-cycle.sh:183`, `LOGS/exp.txt`

---

## Claim 6: "check_brief and check_branch skip every argument unless it returned 0 with main found by name."

**Location:** `scripts/lib/dev-cycle-read.sh:17-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Before resolve_main and after the current-branch fallback; with ROOT_REAL unset check_brief exits instead (Claim 2); a main resolved in another repo is settled (override-log row 208).
**Legibility target:** for-orchestrator-synthesis

E8: four `skip ...: no default branch found by name ...` lines; `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`:231`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:231,242,288`, `LOGS/exp.txt`, `LOGS/mutate-u0c.txt`

---

## Claim 7: "Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker."

**Location:** `scripts/lib/dev-cycle-read.sh:18-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The fixed marker name; not how a second script handles an inherited marker.
**Legibility target:** for-orchestrator-synthesis

`[[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0` / `DEV_CYCLE_SCRUBBED=1 bash "$self" "$@"` (`:67,69`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:66-71`

---

## Claim 8: "Inputs: check_brief and check_branch read the default branch's commit (check_brief also refuses a brief path that is not plain in the working tree); check_answer and the import walk read the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:19-22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which tree each reads; check_branch also reads `refs/heads/<name>` and its log (not a working-tree read); an absent working-tree path is not refused (`ok ... new`).
**Legibility target:** for-orchestrator-synthesis

`git ls-tree "$MAIN_SHA" -- "$a"` / `git cat-file blob "$MAIN_SHA:$a"` (`:250,258`); `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink..."` (`:247`). E5: a symlinked brief → skip; an absent one → `ok ... new`. check_answer reads `docs/working/questions.md` relative to the cwd after `skipped` (`:460-463`), whose need_root pins cwd == ROOT_REAL. The walk lists files with `git ls-files` and greps them in place (`:360-374`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:239-298,347-376,457-476`, `LOGS/exp.txt`

---

## Claim 9: "One result is cached, for the root in IMPORTED_DONE; a call for another ROOT_REAL recomputes it."

**Location:** `scripts/lib/dev-cycle-read.sh:342-343`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-root recompute; a working-tree change under the same root within a process is not re-read (consistent with "one result").
**Legibility target:** for-orchestrator-synthesis

`[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'` (`:350`). E7: `A: [,a.md,]`, `A again: [,a.md,]`, `B: [,b.md,]`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:344-350`, `LOGS/exp.txt`

---

## Claim 10: "The reader, kept in a lib ... from this script's own directory: the scrub, the file and path rules, FENCE_AWK, the brief, branch and answer checks, the instruction-file import walk, and the default branch."

**Location:** `scripts/dev-cycle.sh:83-86`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Lib contents at the tip; not build-loop.sh.
**Legibility target:** for-orchestrator-synthesis

Matches Claim 1. `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`:87`).

**Evidence:** `scripts/dev-cycle.sh:82-91`

---

## Claim 11: "# shellcheck disable=SC2034  # read by the lib's file rules and import walk"

**Location:** `scripts/dev-cycle.sh:115`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** ROOT_REAL's readers at the tip; shellcheck as installed here.
**Legibility target:** for-orchestrator-synthesis

After this range dev-cycle.sh no longer reads ROOT_REAL itself. The lib reads it in need_root, rawfile and plaindir (`:81-87`) and in imported_names (`:350,370`). shellcheck `-x` on both files printed nothing.

**Evidence:** `scripts/dev-cycle.sh:115-116`, `scripts/lib/dev-cycle-read.sh:81-87,350,370`, `LOGS/shellcheck.txt`

---

## Claim 12: "The lib now also holds INSTRUCTION_FILE and the @-import walk (lower, imported_names) and ANSWER_AWK with check_answer, moved verbatim."

**Location:** commit `41065ce6` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The move commit's removed vs added lines; 1c7373d3's later walk edits are intended.
**Legibility target:** for-orchestrator-synthesis

The removed dev-cycle.sh lines and the added lib lines in 41065ce6 differ only in the header line and the source-line comment.

Command: `git show 41065ce6 -- <file> | rg ...; diff` · exit 1 (two lines differ) · 2026-10-05T00:39.

**Evidence:** `LOGS/movediff-41065ce6.txt`

---

## Claim 13: "check_fix, check_path and check_write stay in dev-cycle.sh, check_fix's predicate included although the plan lists it: U2 writes the floor as its own lib function instead (plan amendment)."

**Location:** commit `41065ce6` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Where the functions live and the amendment's presence.
**Legibility target:** for-orchestrator-synthesis

`check_path() {`, `check_write() {`, `check_fix() {` sit at `scripts/dev-cycle.sh:139,155,167`. The amendment is at `docs/working/plan-build-loop-handoff.md:192`.

**Evidence:** `scripts/dev-cycle.sh:139-182`, `docs/working/plan-build-loop-handoff.md:187,192`

---

## Claim 14: "check_answer still reads the working tree; U1 moves it to main's commit (D8)."

**Location:** commit `41065ce6` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The plan's assignment; not U1's implementation.
**Legibility target:** for-orchestrator-synthesis

Plan: "`--check-answer` moves into the lib and reads main's commit (D8)" (`:221`); step 3 "U1 code ... `check_answer` reading main's commit" (`:270`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:85,221,270`

---

## Claim 15: "The 53 existing tests pass, the digest of this repo is byte-identical to main's, and --check-brief/-branch/-answer/-fix print the same on this repo." (41065ce6)

**Location:** commit `41065ce6` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This repo, both digest windows and all six check modes; not other repos (this repo has no `@`-imports, so the walk's refusal is exercised only by the suite).
**Legibility target:** for-orchestrator-synthesis

Suite at 41065ce6: 58 ok, 0 failing. Every output was identical to main's.

Command: `bash run-commits.sh` · exit 0 · 2026-10-05T00:37:40-07:00.

**Evidence:** `LOGS/run-commits.txt`

---

## Claim 16: "Security L1: without ROOT_REAL the walk returned an empty import set and cached it, turning off check_fix's import refusal."

**Location:** commit `1c7373d3` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Settled: override-log row 210 (2026-10-05, Won't-Fix). Not re-raised; listed only so the count is complete.
**Legibility target:** for-author

As recorded in iteration 2, after the U0a rebase inrepo's need_root already stopped the walk whenever an instruction file exists (paraphrased — no quote available because the pre-fix commit was rebased away; see `docs/reviews/override-log.md:210`).

**Evidence:** `docs/reviews/override-log.md:210`

---

## Claim 17: "Security I2: the cache recorded no root, so a caller that changed checkout got the first one's set; IMPORTED_DONE now holds the root it was computed for. New test covers both."

**Location:** commit `1c7373d3` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new keying and that the test fails on both regressions.
**Legibility target:** for-orchestrator-synthesis

Mutants `walk without need_root` and `walk cache not keyed on root` (`[[ -n "$IMPORTED_DONE" ]] && return`) are both CAUGHT by the new test.

Command: `bash mutate.sh u0c` · exit 0 · 2026-10-05T00:35:38-07:00.

**Evidence:** `scripts/lib/dev-cycle-read.sh:347-350`, `test/scripts/dev-cycle.bats:1097-1110`, `LOGS/mutate-u0c.txt`

---

## Claim 18: "the plan lists "check_fix's predicate" for the lib, which U0 does not move (U0a's and U0c's messages, reworded before merge, now say so). The plan carries a dated amendment ..."

**Location:** commit `1c7373d3` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The messages' text and the amendment's presence.
**Legibility target:** for-orchestrator-synthesis

4ef450da: "The plan's lib list also names check_fix's predicate; it stays in dev-cycle.sh". 41065ce6: "check_fix's predicate included although the plan lists it". The amendment is at plan `:192`.

**Evidence:** `git log feat/build-loop-handoff..feat/build-loop-u0c`, `docs/working/plan-build-loop-handoff.md:192`

---

## Claim 19: "The lib header says which readers read main's commit and which the working tree ...; the ROOT_REAL directive names the walk; T29 checks the lib's globals are declared." / "all tests at this tip pass (main's 53 among them); the digest, --check-answer and --check-fix output on this repo are unchanged."

**Location:** commit `1c7373d3` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Each described edit, the suite at 1c7373d3 and this repo's outputs.
**Legibility target:** for-orchestrator-synthesis

Header `:19-22` (Claim 8); directive `scripts/dev-cycle.sh:115` (Claim 11); T29 gained `for v in SKIPPED SKIP_AT MAIN MAIN_SHA MAIN_BY_NAME IMPORTED IMPORTED_DONE; do declare -p "$v" ... || echo "unset $v"; done`. Removing `IMPORTED_DONE=""` fails it (CAUGHT). Suite at 1c7373d3: 59 ok. Outputs identical to main's.

**Evidence:** `test/scripts/dev-cycle.bats:1035`, `LOGS/run-commits.txt`, `LOGS/mutate-u0c.txt`

---

## Claim 20: "The F11 row and step 13's Q-103 text now carry the precondition (the gate runs the import walk at MAIN_SHA)."

**Location:** commit `d8da1fba` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** That both texts carry it; fidelity to the review's wording is Claim 26.
**Legibility target:** for-orchestrator-synthesis

F11: "The walk reads the working tree, so the gate runs it in a worktree at `MAIN_SHA` or through a commit-reading variant (amendment 2026-10-05)" (`:126`). Step 13: "F11 (with its `MAIN_SHA` precondition for the import walk)" (`:290`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126,290`

---

## Claim 21: "the floor's dot test must also refuse a leading-dot top-level path (.envrc), and U2's review confirms the walk's B2 gaps rather than inheriting them. Both restored; "top-level dotfiles" is dropped from the list of differences (both policies refuse them). It now says the predicate stays in dev-cycle.sh for good."

**Location:** commit `d8da1fba` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** check_fix's refusal of `.envrc` and the floor's item 2; does not establish U2's implementation.
**Legibility target:** for-orchestrator-synthesis

`dev-cycle.sh --check-fix .envrc` → `skip .envrc: in-cycle fixes edit only tracked .md documentation under docs/ ...` (main and every commit identical). The floor refuses "any `.`-prefixed component" (plan `:70`). The amendment says "it is not extracted later either" and names `.envrc` and the B2 confirmation (`:192`).

**Evidence:** `LOGS/run-commits.txt`, `LOGS/out-main2/fix.txt`, `docs/working/plan-build-loop-handoff.md:70,192`

---

## Claim 22: "Fact-check: "computed once per process and repo root" overstated the cache: it holds one root, so a call for another root recomputes it." / "all 59 tests at this tip pass"

**Location:** commit `d8da1fba` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The new comment's text and the suite count.
**Legibility target:** for-orchestrator-synthesis

The comment now reads "One result is cached, for the root in IMPORTED_DONE" (`:342-343`), Verified in Claim 9. Suite: 59 ok, 0 failing.

Command: `bats test/scripts/dev-cycle.bats` · cwd `.../wt-build-loop-u0c` · exit 0 · 2026-10-05T00:32:45-07:00.

**Evidence:** `LOGS/bats2-build-loop-u0c.txt`

---

## Claim 23: "`check_fix` is an allowlist of docs an in-cycle fix may edit; D5's floor is a denylist over any path, and the two differ (`working/`, `reviews/`, `thoughts/`, `constraints.md`)."

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** check_fix's code and D5's list; not U2's floor.
**Legibility target:** for-orchestrator-synthesis

check_fix refuses `^docs/(working|human-author|reviews|decisions)/` and lets other tracked docs .md pass (`scripts/dev-cycle.sh:176-181`). Floor item 4 refuses `docs/constraints.md`, `docs/decisions/`, `docs/thoughts/`, `docs/human-author/` and only other briefs' working docs (plan `:72`). The four named paths are where the two differ.

**Evidence:** `scripts/dev-cycle.sh:167-182`, `docs/working/plan-build-loop-handoff.md:66-72`

---

## Claim 24: "(`check_fix`'s `*/.*` test misses it, harmlessly there because such a path also fails `^docs/`)"

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** `.envrc`; other leading-dot top-level names behave the same by the same regex.
**Legibility target:** for-orchestrator-synthesis

`|| "$a" == */.*` needs a `/` before the dot (`scripts/dev-cycle.sh:177`). `.envrc` was refused with the docs-scope reason (Claim 21).

**Evidence:** `scripts/dev-cycle.sh:176-178`, `LOGS/out-main2/fix.txt`

---

## Claim 25: "F11's row below and step 13's Q-103 text now carry this precondition."

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** The pointer's direction; the content is Claim 20.
**Legibility target:** for-author

The F11 row is at `:126`, in the pre-mortem table above the Approach section; the amendment is at `:192`. "below" should be "above" (or "F11's row in the pre-mortem table").

**Evidence:** `docs/working/plan-build-loop-handoff.md:126,181,192`

---

## Claim 26: "The import walk reads the working tree at `ROOT_REAL`, so the gate must run it in a worktree checked out at `MAIN_SHA` or use a commit-reading variant" (and F11's "the gate runs it in a worktree at `MAIN_SHA` or through a commit-reading variant"), as drawn from the cited architecture review

**Location:** `docs/working/plan-build-loop-handoff.md:126,192`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Fidelity to the review's recommendation and to the walk's inputs; not U2's design.
**Legibility target:** for-author

The review's precondition is "the gate runs the walk in a worktree checked out at `MAIN_SHA` with no untracked instruction files, and test it" (`docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md:147`). The amendment drops "with no untracked instruction files". The walk does read them: `git ls-files -z --others -- ':(glob,icase)**/*.md'` (`scripts/lib/dev-cycle-read.sh:361`). So a worktree at MAIN_SHA that holds an untracked or ignored instruction file would still change the refusal set. Precise version: "...in a clean worktree checked out at `MAIN_SHA` (no untracked or ignored instruction files)".

**Evidence:** `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md:145-147`, `scripts/lib/dev-cycle-read.sh:360-362`

---

## Claim 27: "Floor item 1 makes the gate a second user of the walk's refusal set (boundary B2 in the pass-38 security review), so the walk's known gaps (F11 "partly") become gate gaps too; U2's architecture and security review confirms that rather than inheriting it."

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The references; not the gaps themselves.
**Legibility target:** for-orchestrator-synthesis

B2 is "[instruction files ...] → [imported_names() walk ...] → [IMPORTED refusal set]" (`docs/reviews/security-review-2026-10-02-digest-pass38.md:14`). The review: "B2's known gap ... becomes a gate gap as well ... should confirm it rather than inherit it unexamined" (arch review `:77`).

**Evidence:** `docs/reviews/security-review-2026-10-02-digest-pass38.md:14`, `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md:77`

---

## Claim 28: "adds an `isimported` predicate so neither caller reads the walk's cache format, and either shares one read-as-truth list with `check_fix` or files the difference as a `you: judgment` entry."

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Fidelity to the review.
**Legibility target:** for-orchestrator-synthesis

The review recommends `isimported() { imported_names; [[ "$IMPORTED" == *$'\n'"$(lower "$1")"$'\n'* ]]; }` (`:107`) and "either share a single `truthdoc()` list ... or file a `you: judgment` entry" (`:127`).

**Evidence:** `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md:107,127`

---

## Claim 29: "Moving the predicate in U0 would mean splitting `check_fix`, which a pure move cannot do, and building a policy switch for a caller that does not exist yet. The predicate therefore stays in dev-cycle.sh; it is not extracted later either."

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Fidelity to the review.
**Legibility target:** for-orchestrator-synthesis

Review: "would mean splitting `check_fix` into a parameterized function serving two policies. That is not a move. It would put a policy switch into the lib ... to serve a consumer that does not exist yet" and "leave the two policies in the scripts that own them" (`:70`).

**Evidence:** `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md:70,76`

---

## Claim 30: "U0 also split into three units (U0a/U0b/U0c), not two: moved lines count twice under the 400-line cap."

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The plan's text and the branch layout; line counts not re-measured.
**Legibility target:** for-orchestrator-synthesis

Plan: "moved lines count twice" (`:266`) and "U0a/U0b if it measures over 400" (`:268`). Three unit branches exist.

**Evidence:** `docs/working/plan-build-loop-handoff.md:266-268`

---

## Claim 31: "`writable` and `isbrief` (`check_fix`'s predicate stays in dev-cycle.sh: amended 2026-10-05, see below);"

**Location:** `docs/working/plan-build-loop-handoff.md:187`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The pointer and the code.
**Legibility target:** for-orchestrator-synthesis

The amendment is at `:192`, below the list. `writable()`/`isbrief()` are in the lib (`:145-150`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:187,192`, `scripts/lib/dev-cycle-read.sh:145-150`

---

## Claim 32: Test name "the import walk stops without ROOT_REAL and recomputes for another repo root"

**Location:** `test/scripts/dev-cycle.bats:1097`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Both halves are mutation-checked; the not-current-directory case is not tested here (need_root's is).
**Legibility target:** for-orchestrator-synthesis

It asserts status 1 and "ROOT_REAL is not set" for a bare `imported_names`, then exact `" docs/a.md \n docs/b.md "` across two roots. Both mutants are CAUGHT (Claim 17).

**Evidence:** `test/scripts/dev-cycle.bats:1097-1110`, `LOGS/mutate-u0c.txt`

---

## Claim 33: T29 extended to "lower imported_names check_answer" and the four non-empty variables (41065ce6: "T29 lists the new functions and variables")

**Location:** commit `41065ce6` message; `test/scripts/dev-cycle.bats:1029-1034`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Names vs assertions; mutation-checked for a renamed function and a missing global.
**Legibility target:** for-orchestrator-synthesis

`for v in FENCE_AWK ANSWER_AWK INSTRUCTION_FILE IMPORT_RE; do [[ -n "${!v}" ]] || echo "no $v"; done`. Mutant `lib missing check_answer` (renamed) is CAUGHT.

**Evidence:** `test/scripts/dev-cycle.bats:1023-1040`, `LOGS/mutate-u0c.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3b** (`scripts/lib/dev-cycle-read.sh:13-14`): with ROOT_REAL set but not the cwd, rawfile/plaindir/blocker can pass a symlink that leads into the root; limit "read nothing as plain" to the unset case.

### Stale
- none

### Mostly Accurate
- **Claim 2** (`scripts/lib/dev-cycle-read.sh:12-14`): check_answer also exits through `skipped`'s need_root; add it to the list of exiting checks.
- **Claim 16** (commit `1c7373d3`): settled (override-log row 210); not re-raised.
- **Claim 25** (`docs/working/plan-build-loop-handoff.md:192`): "F11's row below" points the wrong way; the row is at `:126`, above.
- **Claim 26** (`docs/working/plan-build-loop-handoff.md:126,192`): the review's precondition includes "with no untracked instruction files"; the walk reads `--others`, so state a clean worktree.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): one markdown report per unit at OUTPUT_PATTERN (unit = u0a, u0b, u0c), structured per your skill, first line `Commit: <unit tip short SHA>`, ending with the Goal-Alignment Note.
- Answered: yes. Full U0c range checked, including the plan amendment against the architecture review, outputs compared with main at each commit, and the new tests mutation-checked.
- Out of scope: U0a's need_root "set -u fires" comment (unchanged here; in the U0a report); settled override rows 202-207 and 210. The Approach list's `brief_fields` entry is pre-existing plan text (U1 adds it) and was not verdicted.
- Escalate: Claims 2, 3b and 25-26 are comment or plan-text fixes; 3b and 26 matter once build-loop.sh and the gate become callers.
- Decisions I made: I read the header's exiting-check list as meant to be complete, because the `$(...)` warning depends on it, so I filed the missing check_answer as Mostly accurate.
