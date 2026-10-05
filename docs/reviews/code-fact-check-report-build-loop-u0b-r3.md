Commit: 698348ac

# Code Fact-Check Report

**Commit:** 698348ac
**Replication:** k=3, replicate 3 (final confirming pass, iteration 3)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-handoff; unit tip checked out at a scratch worktree)
**Scope:** Full U0b range `git diff feat/build-loop-u0a..feat/build-loop-u0b` (0b53fe50, fbe3a219, 698348ac): scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/dev-cycle.bats, and the three commit messages. U0a/U0c are context only.
**Checked:** 2026-10-05
**Total claims checked:** 20
**Summary:** 19 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution logs: `/home/node/.claude/jobs/989f3e5a/tmp/review/final-fc-r3/logs/` (`LOGS/` below), produced by `.../final-fc-r3/{run-modes.sh,run-commits.sh,exp.sh,exp2.sh,mutate.sh}`. Hallucination log read; no claim matches a logged pattern (test counts checked against `bats`). U0a's Incorrect need_root parenthetical (`:73-74` here, "set -u fires there") is outside this range's diff and is reported in the U0a report.

---

## Claim 1: "the output scrub, the plain-file and path-form rules, the cycle's own file names, the Markdown shapes the readers refuse (FENCE_AWK), the brief and branch checks, and the default branch."

**Location:** `scripts/lib/dev-cycle-read.sh:2-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib's contents at the U0b tip; does not establish build-loop.sh's use.
**Legibility target:** for-orchestrator-synthesis

The lib now also defines `FENCE_AWK`, `oddwhy`, `main_by_name`, `check_brief`, `check_branch` and `resolve_main` (paraphrased — no quote available because the claim covers the file's whole set of definitions; T29's list, which passes, names each one).

**Evidence:** `scripts/lib/dev-cycle-read.sh:170-325`, `test/scripts/dev-cycle.bats:1023-1037`

---

## Claim 2: "inrepo, dirok, skipped and check_brief exit 1 (need_root) when ROOT_REAL is unset or is not the current directory"

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named functions; check_branch (no file read) correctly does not exit; does not establish the list is complete for later units.
**Legibility target:** for-orchestrator-synthesis

`check_brief() { local a="$1" st c n why` / `need_root` (`:236-238`). The test's second block asserts status 1 and "ROOT_REAL is not set" for check_brief. The mutant with check_brief's need_root removed fails it (CAUGHT). With ROOT_REAL unset, `check_branch foo` printed `absent foo` and returned (E4).

Command: `bash mutate.sh u0c` · exit 0 · 2026-10-05T00:35:38-07:00; `bash exp.sh .../wt-build-loop-u0b` · exit 0 · 2026-10-05T00:34:06-07:00.

**Evidence:** `scripts/lib/dev-cycle-read.sh:77-80,106-110,236-238`, `LOGS/mutate-u0c.txt`, `LOGS/exp.txt`

---

## Claim 3a: "rawfile, plaindir and blocker then read nothing as plain" (ROOT_REAL unset)

**Location:** `scripts/lib/dev-cycle-read.sh:13-14`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Unset case only; the mismatched-root case is 3b.
**Legibility target:** for-orchestrator-synthesis

`[[ -n "${ROOT_REAL:-}" && -f "$1" ]] && ...` (`:81`, plaindir `:84`). In E1, `blocker f file` printed `f` (blocked).

**Evidence:** `scripts/lib/dev-cycle-read.sh:81,84`, `LOGS/exp.txt`

---

## Claim 3b: "...when ROOT_REAL ... is not the current directory; rawfile, plaindir and blocker then read nothing as plain."

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers direct calls with a root other than the cwd; dev-cycle.sh never makes such calls.
**Legibility target:** for-author

The check `[[ "$r" == "$ROOT_REAL/$1" ]]` (`:81`) passes for a symlink in the cwd that leads into ROOT_REAL at the same relative path. In E2 at U0b: `rawfile d/f: plain`, `plaindir d: plain` (`d` is a symlink in the cwd), `blocker d/f: []`. This range's 698348ac rewrote the sentence (adding check_brief), so it is in scope here. Precise version: limit "read nothing as plain" to the unset case.

Command: `bash exp.sh .../wt-build-loop-u0b` · exit 0 · 2026-10-05T00:34:06-07:00, E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:81,84,92-102`, `LOGS/exp.txt`

---

## Claim 4: "Call the exiting checks in the caller's shell, not inside $(...) or `local x="$(...)"`, where an exit ends only the subshell."

**Location:** `scripts/lib/dev-cycle-read.sh:14-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism and dev-cycle.sh's call sites (`check_brief "$a"` in the caller's loop); does not cover future callers.
**Legibility target:** for-orchestrator-synthesis

E3b shows an exit inside `$(...)` leaving the caller running. dev-cycle.sh calls `--check-brief) check_brief "$a" ;;` directly in its loop (paraphrased — no quote available because the U0b line differs from U0c's `scripts/dev-cycle.sh:195`). An `rg` for exiting checks inside `$(...)` found none.

**Evidence:** `LOGS/exp.txt`, `scripts/dev-cycle.sh` (check loop)

---

## Claim 5: "The caller runs resolve_main once per process (a second call re-reads main)"

**Location:** `scripts/lib/dev-cycle-read.sh:16-17`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh's single call and the re-read on a second call; does not establish future callers' discipline.
**Legibility target:** for-orchestrator-synthesis

`resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch ..." >&2; exit 1; }` (`scripts/dev-cycle.sh:328`) is the only call. E6: after a new commit, a second call gave `first=e412795 second=7e3c695`.

**Evidence:** `scripts/dev-cycle.sh:328`, `scripts/lib/dev-cycle-read.sh:302-324`, `LOGS/exp.txt`

---

## Claim 6: "check_brief and check_branch skip every argument unless it returned 0 with main found by name."

**Location:** `scripts/lib/dev-cycle-read.sh:17-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers before-resolve_main and the current-branch fallback; with ROOT_REAL unset check_brief exits instead (Claim 2); main resolved in another repository is settled (override-log row 208).
**Legibility target:** for-orchestrator-synthesis

`main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`:228`), checked first in both functions. E8 printed four `skip ...: no default branch found by name ..., or resolve_main has not run` lines (before resolve_main, and after its `trunk` fallback with `BY_NAME=[]`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:228,239,285`, `LOGS/exp.txt`

---

## Claim 7: "The default branch, set by resolve_main (below). check_brief and check_branch read its commit, so they answer only when it was found by name, never for the current branch's fallback or before resolve_main has succeeded."

**Location:** `scripts/lib/dev-cycle-read.sh:224-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 6.
**Legibility target:** for-orchestrator-synthesis

Same evidence as Claim 6. Mutants that drop either function's main_by_name check, or make main_by_name ignore MAIN_BY_NAME, are each CAUGHT by the skip test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:224-228`, `LOGS/exp.txt`, `LOGS/mutate-u0c.txt`

---

## Claim 8: "The default branch is refused, and so is every name when there is no default branch found by name (main_by_name)."

**Location:** `scripts/lib/dev-cycle-read.sh:281-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_branch's two refusals; does not establish its ok/absent output.
**Legibility target:** for-orchestrator-synthesis

`elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"` (paraphrased — no quote available because only the U0c line numbers were captured: `:292`). On this repo `--check-branch main` → `skip main: the default branch`, and E8 shows the no-main skip.

**Evidence:** `LOGS/out-build-loop-u0b/branch.txt`, `LOGS/exp.txt`

---

## Claim 9: "The default branch: sets MAIN (its name), MAIN_SHA and MAIN_BY_NAME (1 when the name is origin/HEAD's, main or master, not the current branch's), and returns 1 when MAIN_SHA is empty."

**Location:** `scripts/lib/dev-cycle-read.sh:297-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback and the outside-repo return; origin/HEAD candidates are settled (override-log row 209).
**Legibility target:** for-orchestrator-synthesis

The resolve_main test prints `trunk <sha> by-name=no` and `none 1: [] []`. Mutants that make resolve_main exit, or remove the current-branch fallback, are CAUGHT.

**Evidence:** `scripts/lib/dev-cycle-read.sh:297-324`, `test/scripts/dev-cycle.bats:1068-1077`, `LOGS/mutate-u0c.txt`

---

## Claim 10: "The reader, kept in a lib ... from this script's own directory: the scrub, the file and path rules, FENCE_AWK, the brief and branch checks, and the default branch."

**Location:** `scripts/dev-cycle.sh:83-85`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the U0b lib's contents; does not establish build-loop.sh.
**Legibility target:** for-orchestrator-synthesis

Matches Claim 1's contents. `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`:86`).

**Evidence:** `scripts/dev-cycle.sh:82-92`

---

## Claim 11: "The lib now also holds FENCE_AWK and oddwhy, check_brief, check_branch and the default-branch resolution, moved verbatim. The resolution becomes resolve_main, which returns 1 instead of exiting ...; dev-cycle.sh keeps its exit and message."

**Location:** commit `0b53fe50` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the move commit's removed vs added lines and the exit message; the later fix commits' edits are intended.
**Legibility target:** for-orchestrator-synthesis

The moved-lines diff for 0b53fe50 leaves only header and source-comment lines, FENCE_AWK's shellcheck directive, the resolution wrapped as `resolve_main() { local c sha cur origin_head candidates=() ... [[ -n "$MAIN_SHA" ]] }` (re-indented, otherwise the same lines), and the exit moved to dev-cycle.sh as `resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }`. E9 prints that message with rc=1.

**Evidence:** `LOGS/movediff-0b53fe50.txt`, `LOGS/exp.txt`, `scripts/dev-cycle.sh:328`

---

## Claim 12: "The 53 existing tests pass, the digest of this repo is byte-identical to main's, and --check-brief/-branch/-answer/-fix print the same on this repo." (0b53fe50); "all tests at this tip pass ...; the digest and --check-brief and --check-branch output on this repo are unchanged" (fbe3a219); "all 58 tests at this tip pass ...; the digest, --check-brief and --check-branch output on this repo, and the no-main-branch refusal, are unchanged" (698348ac)

**Location:** commits `0b53fe50`, `fbe3a219`, `698348ac` messages
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this repo's digest (two windows) and all six check modes at each commit, and the no-main refusal at the tip; does not establish other repos.
**Legibility target:** for-orchestrator-synthesis

Suite: 0b53fe50 57 ok; fbe3a219 58; 698348ac 58; 0 failing. `diff -r` against main's outputs: identical at all three. No-main refusal: `--check-brief needs a default branch (origin/HEAD, main or master); found none`, rc=1, the same text as U0a's, which still has main's code there (E9).

Commands: `bash run-commits.sh` · exit 0 · 2026-10-05T00:37:40-07:00; `bash run-modes.sh` · exit 0 · 2026-10-05T00:33:19-07:00; `bash exp.sh` · 2026-10-05T00:34:06-07:00.

**Evidence:** `LOGS/run-commits.txt`, `LOGS/run-modes.txt`, `LOGS/bats2-build-loop-u0b.txt`, `LOGS/exp.txt`

---

## Claim 13: "the found-by-name rule lived only in dev-cycle.sh, so a second caller of the lib could get a landed brief read as "new", or a brief's Status read from a loop-written current branch."

**Location:** commit `fbe3a219` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both pre-fix behaviours on the 0b53fe50 lib; does not establish that any caller hit them.
**Legibility target:** for-orchestrator-synthesis

With 0b53fe50's lib, check_brief before resolve_main printed `MAIN_SHA: unbound variable` (from inside a substitution) and then `ok docs/working/briefs/2026-10-02-a-b.md new` for a committed brief. On a `loopbranch` fallback it printed `ok ... open <sha>` read from that branch.

Command: `bash exp2.sh` · cwd scratch · exit 0 · 2026-10-05T00:38:47-07:00.

**Evidence:** `LOGS/exp2.txt`

---

## Claim 14: "Both functions now skip every argument unless main_by_name holds, and MAIN, MAIN_SHA and MAIN_BY_NAME start empty when the lib is sourced. dev-cycle.sh exits before calling them in that case ... New test: four skips, no ok line. ... FENCE_AWK's SC2034 directive is dropped (check_brief reads it). The resolve_main test now asserts the return code of 1."

**Location:** commit `fbe3a219` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each described edit; shellcheck as installed here, not CI's.
**Legibility target:** for-orchestrator-synthesis

`MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""` at top level (`:227`). The test asserts `grep -c 'no default branch found by name'` = 4 and `!= *"ok "*`. The resolve_main test expects `none 1: [] []`. shellcheck on the lib alone and with `-x` printed nothing at U0b.

**Evidence:** `scripts/lib/dev-cycle-read.sh:227-228`, `test/scripts/dev-cycle.bats:1068-1095`, `LOGS/shellcheck.txt`

---

## Claim 15: "the header said a check run without ROOT_REAL exits 1, but check_brief called blocker directly and skipped every brief as "reached through a symlink"."

**Location:** commit `698348ac` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix behaviour on fbe3a219's lib.
**Legibility target:** for-orchestrator-synthesis

With fbe3a219's lib, main resolved and ROOT_REAL unset: `skip docs/working/briefs/2026-10-02-a-b.md: reached through a symlink, or not a regular file`, `returned rc=0`.

**Evidence:** `LOGS/exp2.txt`

---

## Claim 16: "It now runs need_root first ..., and the header lists it with the exiting checks. ... the skip now also names a resolve_main that has not run ... the header's subject for "runs resolve_main" is the caller. ... dev-cycle.sh's found-by-name exit uses main_by_name instead of its own -z "$MAIN_BY_NAME" test (same condition). ... MAIN_BY_NAME's SC2034 directive is dropped; the lib reads it in main_by_name."

**Location:** commit `698348ac` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each described edit. "Same condition" holds because resolve_main sets MAIN_BY_NAME=1 only with MAIN_SHA; a caller setting the globals by hand is not covered.
**Legibility target:** for-orchestrator-synthesis

`if [[ ( "$CHECK" == --check-brief || "$CHECK" == --check-branch ) ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:332`). U0a had `&& -z "$MAIN_BY_NAME"` (U0a `scripts/dev-cycle.sh:493`). `MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1` is the only place MAIN_BY_NAME is set (`lib:314`). The skip text ends `, or resolve_main has not run` (`lib:239`). No SC2034 directive remains for MAIN_BY_NAME (grep).

**Evidence:** `scripts/dev-cycle.sh:328-334`, `scripts/lib/dev-cycle-read.sh:12-19,228,239,314`

---

## Claim 17: Test name "resolve_main returns instead of exiting: the current branch when no main, 1 outside a repo"

**Location:** `test/scripts/dev-cycle.bats:1068`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback and the outside-repo return under set -e; does not cover origin/HEAD.
**Legibility target:** for-orchestrator-synthesis

The test asserts status 0 under `set -euo pipefail` and exact output; mutants `resolve_main exits` and `resolve_main no fallback` are CAUGHT.

**Evidence:** `test/scripts/dev-cycle.bats:1068-1077`, `LOGS/mutate-u0c.txt`

---

## Claim 18: Test name "check_brief and check_branch skip, not answer, without a default branch found by name" and its comment "With main found by name but no ROOT_REAL, check_brief stops rather than skipping as a symlink."

**Location:** `test/scripts/dev-cycle.bats:1079,1089`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both blocks; does not cover main resolved in another repository (settled, row 208).
**Legibility target:** for-orchestrator-synthesis

Four mutants (check_brief without main_by_name / without need_root, check_branch without main_by_name, main_by_name ignoring MAIN_BY_NAME) are each CAUGHT.

**Evidence:** `test/scripts/dev-cycle.bats:1079-1095`, `LOGS/mutate-u0c.txt`

---

## Claim 19: "T29 lists the new functions" (0b53fe50)

**Location:** commit `0b53fe50` message; `test/scripts/dev-cycle.bats:1029-1033`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function list and the FENCE_AWK check; does not cover other globals (added in U0c).
**Legibility target:** for-orchestrator-synthesis

The list gains `oddwhy check_brief check_branch resolve_main main_by_name` and `[[ -n "$FENCE_AWK" ]] || echo "no FENCE_AWK"`. Renaming a listed function is caught in the U0c form of the test.

**Evidence:** `test/scripts/dev-cycle.bats:1023-1040`, `LOGS/mutate-u0c.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3b** (`scripts/lib/dev-cycle-read.sh:12-14`): with ROOT_REAL set but not the cwd, rawfile/plaindir/blocker can pass a symlink that leads into the root; limit "read nothing as plain" to the unset case.

### Stale
- none

### Mostly Accurate
- none

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): one markdown report per unit at OUTPUT_PATTERN (unit = u0a, u0b, u0c), structured per your skill, first line `Commit: <unit tip short SHA>`, ending with the Goal-Alignment Note.
- Answered: yes. Full U0b range checked, with outputs compared to main at each commit, pre-fix behaviours reproduced, and the new tests mutation-checked.
- Out of scope: U0a's need_root "set -u fires" comment (unchanged in this range; reported in U0a); settled override rows 201, 208 and 209.
- Escalate: Claim 3b repeats U0a's 4b in the sentence this range rewrote. One comment fix covers both.
- Decisions I made: I ran the mutation suite once, on the U0c tip, where the U0b tests and guards are byte-identical, rather than once per tip.
