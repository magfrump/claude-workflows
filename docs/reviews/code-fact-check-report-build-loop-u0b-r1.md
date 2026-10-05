Commit: 698348ac

# Code Fact-Check Report

**Commit:** 698348ac
**Replication:** k=3, replicate 1 (final confirming pass, iteration 3, full scope)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-handoff)
**Scope:** U0b full range `git diff feat/build-loop-u0a..feat/build-loop-u0b` (0b53fe50, fbe3a219, 698348ac: scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats) and the three commit messages. U0a/U0c are context only. Scratch: `/home/node/.claude/jobs/989f3e5a/tmp/review/final-fc-r1` (below: `$SCRATCH`).
**Checked:** 2026-10-05
**Total claims checked:** 17
**Summary:** 16 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read; no claim matches a logged pattern. Override-log rows for feat/build-loop-u0b dated 2026-10-05 (rows 201, 208, 209) were read and are not re-raised.

Shared executions (2026-10-05, 07:30Z-07:40Z, detached worktrees under `$SCRATCH/wt-*`):
- E1 `bats test/scripts/dev-cycle.bats` at 0b53fe50, fbe3a219, 698348ac → exit 0; 57 / 58 / 58 ok, every main test name present. Logs `$SCRATCH/logs/bats-{0b53fe50,fbe3a219,u0b}.log`, `$SCRATCH/logs/intermediate.log`.
- E2 digest and every `--check-*` mode on this repo (cwd `$SCRATCH/wt-main`, DEV_CYCLE_TODAY=2026-10-05) with each commit's script, `diff -r` against main's: identical at all three. `$SCRATCH/compare.sh`, `$SCRATCH/intermediate.sh`; logs `$SCRATCH/logs/compare-summary.log`, `$SCRATCH/logs/intermediate.log`.
- E3 mutations (`$SCRATCH/mutate.sh`, 07:34:31Z) on a copy of the U0c tip, where these guards are unchanged: `$SCRATCH/logs/mutate.log`.
- E4 `$SCRATCH/prefix-u0b.sh` (07:39:47Z): the parents' behaviour that fbe3a219 and 698348ac describe. `$SCRATCH/logs/prefix-u0b.log`.
- E5 `$SCRATCH/nomain.sh`: no default branch by name, detached and on `trunk`. `$SCRATCH/logs/nomain.log`.
- E6 move check (`comm` of removed vs added lines per move commit): `$SCRATCH/logs/move-verbatim.log`.
- E7 `$SCRATCH/setu.sh`: `$SCRATCH/logs/setu.log`.

---

## Claim 1: "the output scrub, the plain-file and path-form rules, the cycle's own file names, the Markdown shapes the readers refuse (FENCE_AWK), the brief and branch checks, and the default branch."

**Location:** `scripts/lib/dev-cycle-read.sh:3-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib's contents at 698348ac; does not establish anything about the planned second caller.
**Legibility target:** for-orchestrator-synthesis

The lib adds `FENCE_AWK='` (`:170`), `oddwhy`, `main_by_name` (`:228`), `check_brief` (`:236`), `check_branch` (`:283`) and `resolve_main` (`:302`) to U0a's set (paraphrased — no quote available because the claim is about the file's definition list).

**Evidence:** `scripts/lib/dev-cycle-read.sh:3-6`, `:170`, `:228-302`

---

## Claim 2: "inrepo, dirok, skipped and check_brief exit 1 (need_root) when ROOT_REAL is unset or is not the current directory"

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named functions; at this tip they are every lib function that calls need_root (check_branch does not read the working tree); does not cover U0c's additions.
**Legibility target:** for-orchestrator-synthesis

`check_brief() { local a="$1" st c n why` then `need_root` (`:237-238`), before main_by_name. E3: M12 (check_brief's need_root removed) fails "check_brief and check_branch skip, not answer, without a default branch found by name", whose second half asserts exit 1 and "ROOT_REAL is not set". E4 at 698348ac: `dev-cycle-read.sh: ROOT_REAL is not set ...`, `rc 1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:236-244`, `$SCRATCH/logs/mutate.log`, `$SCRATCH/logs/prefix-u0b.log`

---

## Claim 3: "rawfile, plaindir and blocker then read nothing as plain."

**Location:** `scripts/lib/dev-cycle-read.sh:13-14`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same sentence as U0a's claim 5, rewrapped in this range; covers the unset case fully and the not-the-cwd case except a path resolving to `$ROOT_REAL/<path>`.
**Legibility target:** for-author

E7: with ROOT_REAL set to another tree and a cwd symlink `f.md -> ../r/f.md`, `rawfile f.md: plain`. Precise version: "read nothing outside ROOT_REAL as plain". See U0a's report, claim 5.

**Evidence:** `scripts/lib/dev-cycle-read.sh:13-14`, `$SCRATCH/logs/setu.log`

---

## Claim 4: "The caller runs resolve_main once per process (a second call re-reads main)"

**Location:** `scripts/lib/dev-cycle-read.sh:16-17`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers resolve_main's reset-and-resolve and dev-cycle.sh's single call; does not establish anything about the future second caller.
**Legibility target:** for-orchestrator-synthesis

`MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""` is the first statement after the locals in resolve_main (paraphrased — no quote available because it sits at the head of the function `:302-324`, which re-runs the whole candidate loop on each call). dev-cycle.sh calls it once: `resolve_main || [[ -n "$CHECK" ]] || { ...; exit 1; }` (`scripts/dev-cycle.sh:328`); no other call in the script.

**Evidence:** `scripts/lib/dev-cycle-read.sh:302-324`, `scripts/dev-cycle.sh:328`

---

## Claim 5: "check_brief and check_branch skip every argument unless it returned 0 with main found by name."

**Location:** `scripts/lib/dev-cycle-read.sh:17-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers not-yet-run, fallback-to-current-branch and found-by-name states; does not cover a MAIN_SHA from another repository (settled, override-log row 208).
**Legibility target:** for-orchestrator-synthesis

`main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`:228`); both checks start `if ! main_by_name; then echo "skip ..."; return; fi` (`:239`, `:285`), and MAIN_BY_NAME is set only with MAIN_SHA in the by-name branch (`if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi`). E3: M10, M11 and M15 each fail the skip test (four skips, no `ok`). E4 at 698348ac: a skip both without resolve_main and after a fallback to branch `loop`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:224-239`, `:285`, `:302-324`, `$SCRATCH/logs/mutate.log`, `$SCRATCH/logs/prefix-u0b.log`

---

## Claim 6: "The default branch, set by resolve_main (below). check_brief and check_branch read its commit, so they answer only when it was found by name, never for the current branch's fallback or before resolve_main has succeeded."

**Location:** `scripts/lib/dev-cycle-read.sh:224-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the globals' initial values and the main_by_name gate; same evidence as claim 5.
**Legibility target:** for-orchestrator-synthesis

`MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""` (`:227`) at source time; T29 asserts all three are declared after sourcing. A failed resolve_main resets all three and returns 1 (`[[ -n "$MAIN_SHA" ]]`, `:323`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:224-228`, `:323`, `$SCRATCH/logs/mutate.log`

---

## Claim 7: "The default branch: sets MAIN (its name), MAIN_SHA and MAIN_BY_NAME (1 when the name is origin/HEAD's, main or master, not the current branch's), and returns 1 when MAIN_SHA is empty."

**Location:** `scripts/lib/dev-cycle-read.sh:297-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the by-name, fallback and no-repo cases; does not cover origin/HEAD naming a loop-created branch (settled, row 209).
**Legibility target:** for-orchestrator-synthesis

The resolve_main test asserts `trunk <sha> by-name=no` for the fallback and `none 1: [] []` outside a repo; E3's M09 (`|| exit 1` after the final test) fails it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:297-324`, `test/scripts/dev-cycle.bats:1068-1077`, `$SCRATCH/logs/mutate.log`

---

## Claim 8: "The default branch is refused, and so is every name when there is no default branch found by name (main_by_name)."

**Location:** `scripts/lib/dev-cycle-read.sh:281-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_branch's two refusals; does not re-check the moved name-form rules (E2 identical).
**Legibility target:** for-orchestrator-synthesis

`if ! main_by_name; then ... return; fi` (`:285`) and `elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"` (moved). E2's `--check-branch main ...` output equals main's.

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-296`, `$SCRATCH/logs/intermediate.log`

---

## Claim 9: "The reader ... from this script's own directory: the scrub, the file and path rules, FENCE_AWK, the brief and branch checks, and the default branch."

**Location:** `scripts/dev-cycle.sh:83-85`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against the lib's content at this tip.
**Legibility target:** for-orchestrator-synthesis

Matches claim 1; `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`:86`).

**Evidence:** `scripts/dev-cycle.sh:83-89`

---

## Claim 10: 0b53fe50: "The lib now also holds FENCE_AWK and oddwhy, check_brief, check_branch and the default-branch resolution, moved verbatim. The resolution becomes resolve_main, which returns 1 instead of exiting ...; dev-cycle.sh keeps its exit and message."

**Location:** commit 0b53fe50 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers line content of the moved blocks and the no-main exit; does not establish line order beyond E2's identical outputs.
**Legibility target:** for-orchestrator-synthesis

E6: the only non-matching lines are the resolution's re-indent into `resolve_main() {`, its `local` line, `[[ -n "$MAIN_SHA" ]]`, the header and source-line comments, and the two shellcheck directives; FENCE_AWK, oddwhy, check_brief and check_branch match. E5: with no main/master, the digest prints `Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)` and `--check-brief`/`--check-branch` print main's message, exit 1, at 0b53fe50's descendants as at main.

**Evidence:** `$SCRATCH/logs/move-verbatim.log`, `$SCRATCH/logs/nomain.log`

---

## Claim 11: 0b53fe50: "Tests: T29 lists the new functions; a new test checks that resolve_main falls back to the current branch and returns 1 outside a repo. The 53 existing tests pass, the digest of this repo is byte-identical to main's, and --check-brief/-branch/-answer/-fix print the same on this repo."

**Location:** commit 0b53fe50 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 0b53fe50 itself; does not establish modes E2 does not run.
**Legibility target:** for-orchestrator-synthesis

E1 at 0b53fe50: 57 ok, main's 53 present. E2: identical outputs for digest, brief, branch, answer, fix, path and write.

**Evidence:** `$SCRATCH/logs/bats-0b53fe50.log`, `$SCRATCH/logs/intermediate.log`

---

## Claim 12: fbe3a219: "the found-by-name rule lived only in dev-cycle.sh, so a second caller of the lib could get a landed brief read as "new", or a brief's Status read from a loop-written current branch."

**Location:** commit fbe3a219 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parent 0b53fe50 for a caller without set -u (with -u the unset MAIN_SHA aborts instead) and after a fallback; does not cover dev-cycle.sh, which exits first.
**Legibility target:** for-orchestrator-synthesis

E4 at 0b53fe50, brief landed with `Status: done` on main: without resolve_main, `fatal: Not a valid object name` then `ok docs/working/briefs/2026-10-02-a-b.md new`; on branch `loop` with no main, `MAIN=loop` and `ok ... open 5e383edb...` (the loop's own edit). At 698348ac both print the skip.

**Evidence:** `$SCRATCH/logs/prefix-u0b.log`

---

## Claim 13: fbe3a219: "Both functions now skip every argument unless main_by_name holds, and MAIN, MAIN_SHA and MAIN_BY_NAME start empty when the lib is sourced. dev-cycle.sh exits before calling them in that case, so its output is unchanged. New test: four skips, no ok line. ... FENCE_AWK's SC2034 directive is dropped (check_brief reads it). The resolve_main test now asserts the return code of 1."

**Location:** commit fbe3a219 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change at fbe3a219 and its tests/outputs.
**Legibility target:** for-orchestrator-synthesis

`# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal` (`:169`; 0b53fe50 had `SC2016,SC2034`). dev-cycle.sh's exit: `if [[ ( "$CHECK" == --check-brief || "$CHECK" == --check-branch ) ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:332` at this tip). The test asserts `grep -c 'no default branch found by name'` = 4 and no `ok `; the resolve_main test expects `none 1:`. E1 at fbe3a219: 58 ok; E2 identical.

**Evidence:** `scripts/lib/dev-cycle-read.sh:169`, `scripts/dev-cycle.sh:332`, `test/scripts/dev-cycle.bats:1068-1094`, `$SCRATCH/logs/bats-fbe3a219.log`, `$SCRATCH/logs/intermediate.log`

---

## Claim 14: 698348ac: "the header said a check run without ROOT_REAL exits 1, but check_brief called blocker directly and skipped every brief as "reached through a symlink". It now runs need_root first"

**Location:** commit 698348ac message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-rebase header text the iteration-2 report quoted and the parent fbe3a219's behaviour for a brief under an existing docs/; an absent first directory would not be skipped.
**Legibility target:** for-orchestrator-synthesis

Iteration 2's report quotes the header then under review: "a check run without it exits 1 (need_root)" (`docs/reviews/code-fact-check-report-build-loop-u0b.md:70`). E4 at fbe3a219, main found by name, ROOT_REAL unset: `skip docs/working/briefs/2026-10-02-a-b.md: reached through a symlink, or not a regular file`, `returned`, rc 0; at 698348ac: need_root's message and rc 1.

**Evidence:** `$SCRATCH/logs/prefix-u0b.log`, `docs/reviews/code-fact-check-report-build-loop-u0b.md:70`

---

## Claim 15: 698348ac: "the skip now also names a resolve_main that has not run ... the header's subject for "runs resolve_main" is the caller ... dev-cycle.sh's found-by-name exit uses main_by_name instead of its own -z "$MAIN_BY_NAME" test (same condition) ... MAIN_BY_NAME's SC2034 directive is dropped; the lib reads it in main_by_name."

**Location:** commit 698348ac message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each edit; "same condition" holds because resolve_main sets MAIN_BY_NAME only together with a non-empty MAIN_SHA; does not cover a caller that sets the globals by hand.
**Legibility target:** for-orchestrator-synthesis

Skip text `... (origin/HEAD, main or master), or resolve_main has not run` (`:239`, `:285`); header "The caller runs resolve_main" (`:16`); `! main_by_name` at `scripts/dev-cycle.sh:332` (fbe3a219 had `&& -z "$MAIN_BY_NAME" ]]`); no SC2034 directive anywhere in the lib or dev-cycle.sh at this tip (`rg SC2034` → none).

**Evidence:** `scripts/lib/dev-cycle-read.sh:16`, `:239`, `:285`, `scripts/dev-cycle.sh:332`

---

## Claim 16: 698348ac Notes: "all 58 tests at this tip pass (main's 53 among them); the digest, --check-brief and --check-branch output on this repo, and the no-main-branch refusal, are unchanged."

**Location:** commit 698348ac message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, outputs and both no-main shapes (detached, on `trunk`).
**Legibility target:** for-orchestrator-synthesis

E1: `1..58`, 58 ok, no main name missing. E2 identical. E5: identical messages and exit 1 at this tip and main.

**Evidence:** `$SCRATCH/logs/bats-u0b.log`, `$SCRATCH/logs/compare-summary.log`, `$SCRATCH/logs/nomain.log`

---

## Claim 17: New tests' names vs assertions: "resolve_main returns instead of exiting: the current branch when no main, 1 outside a repo"; "check_brief and check_branch skip, not answer, without a default branch found by name"

**Location:** `test/scripts/dev-cycle.bats:1068-1094`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its assertions and mutation sensitivity; the skip test also asserts check_brief's need_root stop, which its name does not mention (an extra assertion, not a mismatch).
**Legibility target:** for-orchestrator-synthesis

E3: M09 fails only the resolve_main test; M10, M11, M12 and M15 fail only the skip test; the unmutated copy passes all six new tests.

**Evidence:** `test/scripts/dev-cycle.bats:1068-1094`, `$SCRATCH/logs/mutate.log`

---

## Claims Requiring Attention

### Incorrect
- None in this range. (U0a's need_root comment, "set -u fires there", is unchanged at this tip and still wrong; it is reported under U0a, claim 9b.)

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`scripts/lib/dev-cycle-read.sh:13-14`): "read nothing as plain" has a cwd-symlink exception when ROOT_REAL is set to another tree; "nothing outside ROOT_REAL" is exact (same as U0a claim 5).

### Unverifiable
- None.

## Goal-Alignment Note

U0b's moves are verbatim, and resolve_main's return-instead-of-exit leaves dev-cycle.sh's refusal unchanged (E5). The new main_by_name and need_root guards behave as the header and commits say. Every described pre-fix behaviour reproduces on its parent commit, and every guard has a test that fails without it. Tests (57/58/58) and every output on this repo match main. Nothing in this range blocks landing. The one Mostly accurate is a header wording the author can tighten.
