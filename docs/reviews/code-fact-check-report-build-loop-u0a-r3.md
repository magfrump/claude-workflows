Commit: 497c8cb5

# Code Fact-Check Report

**Commit:** 497c8cb5
**Replication:** k=3, replicate 3 (final confirming pass, iteration 3)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-handoff; unit tip checked out at a scratch worktree)
**Scope:** Full U0a range `git diff feat/build-loop-handoff..feat/build-loop-u0a` (4ef450da, 32b9ae0e, 497c8cb5): scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/dev-cycle.bats, and the three commit messages. U0b/U0c are context only.
**Checked:** 2026-10-05
**Total claims checked:** 26
**Summary:** 22 verified, 1 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Execution logs live in the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review/final-fc-r3/logs/` (abbreviated `LOGS/` below). Scripts that produced them: `.../final-fc-r3/{run-modes.sh,run-commits.sh,exp.sh,exp2.sh,mutate.sh}`. Hallucination log read; no claim here matches a logged pattern (the test-count pattern was checked: every count below matches `bats`).

---

## Claim 1: "used by scripts/dev-cycle.sh and kept apart so the planned scripts/build-loop.sh can share it: the output scrub, the plain-file and path-form rules, and the cycle's own file names."

**Location:** `scripts/lib/dev-cycle-read.sh:2-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib's contents at the U0a tip and that build-loop.sh is planned, not present; does not establish anything about build-loop.sh's future use.
**Legibility target:** for-orchestrator-synthesis

The lib defines `scrub`, `scrub_reexec`, `rawfile`, `plaindir`, `blocker`, `inrepo`, `dirok`, `skipped`, `pathform`, `isbrief`, `writable` and `need_root` (paraphrased — no quote available because the claim is about the file's whole set of definitions; T29's list at `test/scripts/dev-cycle.bats:1023-1036` enumerates them and passes). `scripts/build-loop.sh` does not exist at any tip (`ls` returned "No such file or directory").

**Evidence:** `scripts/lib/dev-cycle-read.sh:1-140`, `LOGS/bats2-build-loop-u0a.txt`

---

## Claim 2: "Sourced, never run: it only defines functions and variables. Each script sources it from its own directory ... so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/lib/dev-cycle-read.sh:6-8`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that sourcing runs no git/perl and that dev-cycle.sh resolves the lib from `SCRIPT_DIR`; does not establish how a future build-loop.sh sources it.
**Legibility target:** for-orchestrator-synthesis

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` then `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`scripts/dev-cycle.sh:82,85`). T29 and T30 pass at the tip; mutants that add `git --version` or `perl -e 1` at the lib's top level, or drop the missing-lib guard, each fail their test.

Command: `bats test/scripts/dev-cycle.bats` · cwd `.../final-fc-r3/wt-build-loop-u0a` · exit 0 · 2026-10-05T00:32:44-07:00. Mutations: `bash mutate.sh u0c` (same T29/T30 bodies) · cwd scratch · exit 0 · 2026-10-05T00:35:38-07:00.

**Evidence:** `scripts/dev-cycle.sh:82-89`, `LOGS/bats2-build-loop-u0a.txt`, `LOGS/mutate-u0c.txt`

---

## Claim 3: "inrepo, dirok and skipped exit 1 (need_root) when ROOT_REAL is unset or is not the current directory"

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named functions under both conditions; does not establish that this list is every function that can exit (at U0a it is).
**Legibility target:** for-orchestrator-synthesis

`inrepo() { need_root; ...`, `dirok() { need_root; ...`, `skipped() { need_root; ...` (`:102,105,106`); `need_root` exits 1 on unset (`:74`) and on `"$ROOT_REAL" == "$(pwd -P)"` failing (`:75`). The ROOT_REAL test passes; removing `need_root` from any of the three, or the pwd check, makes it fail.

Command: `bash mutate.sh u0c` · exit 0 · 2026-10-05T00:35:38-07:00 (need_root and the three callers are byte-identical at U0a and U0c).

**Evidence:** `scripts/lib/dev-cycle-read.sh:73-76,102-106`, `LOGS/mutate-u0c.txt`

---

## Claim 4a: "rawfile, plaindir and blocker then read nothing as plain" (ROOT_REAL unset)

**Location:** `scripts/lib/dev-cycle-read.sh:11-12`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unset case only; the not-the-current-directory case is Claim 4b.
**Legibility target:** for-orchestrator-synthesis

`rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && ...` (`:77`, plaindir the same at `:80`). With ROOT_REAL unset, `blocker f file` printed `f` (blocked) for an existing regular file.

Command: `bash exp.sh .../wt-build-loop-u0a` · cwd scratch · exit 0 · 2026-10-05T00:34:06-07:00, section E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:77,80,88-98`, `LOGS/exp.txt`

---

## Claim 4b: "inrepo, dirok and skipped exit 1 (need_root) when ROOT_REAL ... is not the current directory; rawfile, plaindir and blocker then read nothing as plain."

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rawfile/plaindir/blocker called directly with ROOT_REAL set to a root other than the current directory; does not establish that dev-cycle.sh ever does this (it does not: it sets ROOT_REAL right after `cd "$ROOT"`).
**Legibility target:** for-author

The check is a string compare of the resolved relative path with `"$ROOT_REAL/$1"` (`[[ "$r" == "$ROOT_REAL/$1" ]]`, `:77`). From another directory, a symlink that leads into ROOT_REAL at the same relative path satisfies it. In E2, cwd `other/` held `d -> r2/d` and ROOT_REAL was `r2`: `rawfile d/f` → plain, `plaindir d` → plain (although `d` in the cwd is a symlink), `blocker d/f file` → empty (not blocked). So with a stale root these three can read a symlink as plain. That is the case the rules exist to refuse. Precise version: "...when ROOT_REAL is unset, rawfile, plaindir and blocker read nothing as plain; with a ROOT_REAL that is not the current directory their answer is meaningless (a symlink into the root can pass), so call them only after a need_root check."

Command: `bash exp.sh .../wt-build-loop-u0a` · exit 0 · 2026-10-05T00:34:06-07:00, section E2 (same result at U0b and U0c).

**Evidence:** `scripts/lib/dev-cycle-read.sh:77,80,88-98`, `LOGS/exp.txt`

---

## Claim 5: "Call the exiting checks in the caller's shell, not inside $(...) or `local x="$(...)"`, where an exit ends only the subshell."

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the subshell-exit mechanism and dev-cycle.sh's call sites; does not establish anything about future callers.
**Legibility target:** for-orchestrator-synthesis

With ROOT_REAL unset, `out="$(check_answer Q-001)"` printed need_root's message and the caller went on running (`after $(...): rc=1 out=[] caller still running`, E3b at U0c; the exit comes from the same `skipped`→`need_root` code as at U0a). No exiting check is called inside `$(...)` or a pipeline in dev-cycle.sh or the lib (an `rg` for `$(inrepo|dirok|skipped|...` found nothing).

Command: `bash exp.sh .../wt-build-loop-u0c` · exit 0 · 2026-10-05T00:34:06-07:00, E3b.

**Evidence:** `scripts/lib/dev-cycle-read.sh:73-76,102-106`, `LOGS/exp.txt`

---

## Claim 6: "Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker."

**Location:** `scripts/lib/dev-cycle-read.sh:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the marker name is fixed in the lib; does not establish how a second script handles the inherited marker.
**Legibility target:** for-orchestrator-synthesis

`[[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0` and `DEV_CYCLE_SCRUBBED=1 bash "$self" "$@"` (`:60,62`): the name is fixed, so a child of any caller inherits the same marker.

**Evidence:** `scripts/lib/dev-cycle-read.sh:59-64`

---

## Claim 7: "scrub_reexec takes the script to re-run and its arguments, and returns only in the child (or when the caller already set DEV_CYCLE_SCRUBBED)."

**Location:** `scripts/lib/dev-cycle-read.sh:57-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the return/exit split of the whole function; does not establish the scrub's filtering.
**Legibility target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:59-64
scrub_reexec() {
  [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0
  local self="$1"; shift
  { DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub
  exit "${PIPESTATUS[0]}"
}
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:59-64`

---

## Claim 8a: "With no ROOT_REAL nothing is plain (fail closed); need_root makes the callers below stop instead, outside the command substitution where blocker runs"

**Location:** `scripts/lib/dev-cycle-read.sh:68-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fail-closed guards and need_root's position before the substitution; the parenthetical is Claim 8b.
**Legibility target:** for-orchestrator-synthesis

`inrepo() { need_root; [[ -z "$(blocker "$1" file)" ...` (`:102`): need_root runs before the substitution. E1 and the ROOT_REAL test confirm both halves.

**Evidence:** `scripts/lib/dev-cycle-read.sh:68-80,102-106`, `LOGS/exp.txt`, `LOGS/mutate-u0c.txt`

---

## Claim 8b: "(set -u fires there, but its error, like an exit, ends only the subshell)"

**Location:** `scripts/lib/dev-cycle-read.sh:69-70`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers set -u inside blocker's substitution with ROOT_REAL unset in the code as it stands; does not cover the pre-32b9ae0e code, where it did fire.
**Legibility target:** for-author

Since 32b9ae0e, rawfile and plaindir read the variable only as `${ROOT_REAL:-}` and reach the bare `"$ROOT_REAL/$1"` only after `-n` succeeds (`:77,80`). Nothing in blocker can trip set -u. Under `set -euo pipefail` with ROOT_REAL unset, `out="$(blocker f file)"` returned 0 and printed `f` (E1: `blocker rc=0 out=[f] (survived: set -u did not fire)`). The suite's own comment agrees: "without the guards' ${ROOT_REAL:-} the comparison would abort, not close" (`test/scripts/dev-cycle.bats:1054`), and the mutation that makes the variable bare is caught there because set -u then fires. The iteration-2 report said that set -u no longer fires at all in the fixed code. 497c8cb5 inverted that finding, so the comment now describes the old code. Precise version: "(set -u would fire there without the `${ROOT_REAL:-}` guards, and its error, like an exit, would end only the subshell)", or drop the parenthetical.

Command: `bash exp.sh .../wt-build-loop-u0a` · exit 0 · 2026-10-05T00:34:06-07:00, E1 (same at U0b and U0c: the comment is unchanged at `scripts/lib/dev-cycle-read.sh:73-74` (U0b) and `:76-77` (U0c)).

**Evidence:** `scripts/lib/dev-cycle-read.sh:68-80`, `test/scripts/dev-cycle.bats:1054-1058`, `LOGS/exp.txt`, `docs/reviews/code-fact-check-report-build-loop-u0a.md:203`

---

## Claim 9: "A ROOT_REAL that is not the current directory stops them too: the checks read relative paths, so a stale root would compare one tree's files with another."

**Location:** `scripts/lib/dev-cycle-read.sh:70-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers inrepo/dirok/skipped (via need_root); does not cover rawfile/plaindir/blocker called directly (Claim 4b).
**Legibility target:** for-orchestrator-synthesis

`[[ "$ROOT_REAL" == "$(pwd -P)" ]] || { echo "...ROOT_REAL is not the current directory..." >&2; exit 1; }` (`:75`). The test's third block exercises it, and deleting that line fails the test (`need_root without pwd check: CAUGHT`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:75`, `test/scripts/dev-cycle.bats:1059-1064`, `LOGS/mutate-u0c.txt`

---

## Claim 10: "A directory dev-cycle.sh's digest globs in must be plain too, or the glob would list names from wherever a symlinked directory points."

**Location:** `scripts/lib/dev-cycle-read.sh:78-79`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the digest's globs are gated by dirok; does not establish other callers' use.
**Legibility target:** for-orchestrator-synthesis

The digest globs only after `dirok` passes: `if dirok docs/working/cycles; then for f in docs/working/cycles/cycle-...` and `if dirok docs/decisions; then decisions_glob=(docs/decisions/[0-9]...` (paraphrased — no quote available because the line numbers differ per tip; at U0c they are `scripts/dev-cycle.sh:205-206,262`).

**Evidence:** `scripts/dev-cycle.sh` (U0c `:205-206,262`)

---

## Claim 11: "The reader, kept in a lib so the planned scripts/build-loop.sh can share it, from this script's own directory: the scrub and the file and path rules."

**Location:** `scripts/dev-cycle.sh:83-84`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib's U0a contents and the SCRIPT_DIR source; does not establish build-loop.sh.
**Legibility target:** for-orchestrator-synthesis

`READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`:85`); the lib holds exactly the scrub and the file/path rules (Claim 1).

**Evidence:** `scripts/dev-cycle.sh:82-91`

---

## Claim 12: "Exit: ... 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch (for the digest, --check-brief and --check-branch)"

**Location:** `scripts/dev-cycle.sh:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-lib exit and the three no-default-branch exits; does not establish every "failed step" exit.
**Legibility target:** for-orchestrator-synthesis

T30 passes (exit 1, stderr names the lib). In a repo whose only branch is `trunk`: `--check-brief` rc=1 and `--check-branch` rc=1 with "needs a default branch"; detached HEAD with no main: digest rc=1 "Could not resolve a default branch". On `trunk` the digest runs (rc=0), which matches "no default branch" meaning none at all for the digest.

Command: `bash exp.sh .../wt-build-loop-u0a` · exit 0 · 2026-10-05T00:34:06-07:00, E9.

**Evidence:** `scripts/dev-cycle.sh:75-77,88`, `LOGS/exp.txt`, `LOGS/bats2-build-loop-u0a.txt`

---

## Claim 13: "scripts/lib/dev-cycle-read.sh now holds the output scrub and its re-exec wrapper (scrub_reexec, the one rewritten part), the plain-file rules (...), pathform, isbrief and writable, moved verbatim."

**Location:** commit `4ef450da` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the move commit's removed dev-cycle.sh lines against its added lib lines; does not establish the later fix commits' edits (those are intended changes).
**Legibility target:** for-orchestrator-synthesis

Diffing the `-` lines of dev-cycle.sh against the `+` lines of the lib in 4ef450da leaves only the new lib header, the `if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]; then ... fi` block rewritten as `scrub_reexec() {...}`, and the SCRIPT_DIR line (re-added in dev-cycle.sh). Everything else matches line for line.

Command: `git show 4ef450da -- <file> | rg ...; diff rm add` · cwd worktree · exit 1 (differences listed) · 2026-10-05T00:39.

**Evidence:** `LOGS/movediff-4ef450da.txt`, `LOGS/rm-4ef450da.txt`, `LOGS/add-4ef450da.txt`

---

## Claim 14: "Behaviour is otherwise unchanged: the 53 dev-cycle tests pass and the digest of this repo is byte-identical to main's." (also 32b9ae0e "dev-cycle.sh always sets ROOT_REAL first, so its behaviour is unchanged" and 497c8cb5 "all 56 tests at this tip pass ...; the digest of this repo is unchanged")

**Location:** commits `4ef450da`, `32b9ae0e`, `497c8cb5` messages
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this repo's digest (default window and `--since=2026-09-01 --sample=3`) and all six check modes, run from one clean main checkout, plus the suite count at each commit; does not establish identity on other repos.
**Legibility target:** for-orchestrator-synthesis

Suite at 4ef450da: 55 ok (53 + T29, T30); 32b9ae0e: 56; 497c8cb5: 56, 0 failing. Every output file and exit code from each commit's script is identical to main's (`diff -r` → identical). Note: test 21 fails if TMPDIR contains a `.`-prefixed component (git rejects the ref name), on main too; the counts above use the default TMPDIR.

Command: `bash run-commits.sh` · cwd scratch · exit 0 · 2026-10-05T00:37:40-07:00; `bash run-modes.sh` · exit 0 · 2026-10-05T00:33:19-07:00.

**Evidence:** `LOGS/run-commits.txt`, `LOGS/run-modes.txt`, `LOGS/bats2-build-loop-u0a.txt`, `LOGS/bats-main-t21.txt`

---

## Claim 15: "Tests: T29 (sourcing the lib defines its functions and calls neither git nor perl) and T30 (a copy without its lib exits 1 and names it)." / test names at `:1023` and `:1041`

**Location:** commit `4ef450da` message; `test/scripts/dev-cycle.bats:1023,1038`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers names vs assertions and that each fails when its guard is removed; does not establish completeness of T29's function list beyond the lib's own definitions.
**Legibility target:** for-orchestrator-synthesis

T29 stubs git/perl into PATH and asserts `[ ! -e "$S/called" ]`; T30 asserts `[ "$status" -eq 1 ]` and `*"needs $BATS_TEST_TMPDIR/bare/lib/dev-cycle-read.sh"*`. Mutants: lib calls git → CAUGHT; lib calls perl → CAUGHT; guard removed → CAUGHT.

**Evidence:** `test/scripts/dev-cycle.bats:1023-1044`, `LOGS/mutate-u0c.txt`

---

## Claim 16: "U0 measured over the 400-line cap (moves count twice), so it splits into three stacked units, not the plan's two ... The plan's lib list also names check_fix's predicate; it stays in dev-cycle.sh ... (plan amendment in U0c's fix commits)."

**Location:** commit `4ef450da` message (Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan's step 1 and the amendment's presence in U0c's fix commits; does not re-measure line counts.
**Legibility target:** for-orchestrator-synthesis

Plan step 1: "U0, extract the lib (~260 lines moved; U0a/U0b if it measures over 400)", and the cap line reads "moved lines count twice" (`docs/working/plan-build-loop-handoff.md:266,268`). The amendment lands in 1c7373d3/d8da1fba (`:187,192`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:266-268,187,192` (U0c tip)

---

## Claim 17: "Security L1: with no ROOT_REAL, blocker's unbound-variable error ended only its command substitution, so inrepo, dirok and skipped read a symlink as plain."

**Location:** commit `32b9ae0e` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Settled: override-log row 211 (2026-10-05, Won't-Fix). Not re-raised; listed only so the count is complete.
**Legibility target:** for-author

As recorded in iteration 2: before the fix, `skipped` exited at top level under set -e and read a symlink as plain only in an if/|| context (paraphrased — no quote available because the pre-fix code is no longer on any branch tip; see `docs/reviews/override-log.md:211`).

**Evidence:** `docs/reviews/override-log.md:211`

---

## Claim 18: 32b9ae0e's remaining bullets: need_root stops the caller and rawfile/plaindir treat everything as not plain; "the header's Exit line now names the missing lib; scrub_reexec also returns when the caller set DEV_CYCLE_SCRUBBED; moved comments name dev-cycle.sh's digest"; "T29 is named for what it asserts"; "The lib header names the shared DEV_CYCLE_SCRUBBED marker ... and uses #!/bin/bash like the sibling libs."

**Location:** commit `32b9ae0e` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each described edit at the tip; does not re-verify the reviews the bullets cite.
**Legibility target:** for-orchestrator-synthesis

Exit line names `lib/dev-cycle-read.sh` (`scripts/dev-cycle.sh:76`); scrub_reexec comment `(or when the caller already set DEV_CYCLE_SCRUBBED)` (`lib:58`); "A directory dev-cycle.sh's digest globs in" (`lib:78`) and "the digest's section 8" (`lib:85`); header `:14-15`; `#!/bin/bash` heads the lib and all eight sibling libs in `scripts/lib/` (`head -1` output).

**Evidence:** `scripts/dev-cycle.sh:75-77`, `scripts/lib/dev-cycle-read.sh:1,14-15,57-58,78,85`

---

## Claim 19: "need_root checked only that ROOT_REAL was set. With the current directory elsewhere, the import walk cached an empty set (fewer refusals)."

**Location:** commit `497c8cb5` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the pre-fix mechanism by reading; the pre-fix walk-in-lib commit no longer exists after the rebase, so it was not run.
**Legibility target:** for-orchestrator-synthesis

The walk sets `IMPORTED_DONE="$ROOT_REAL"` and then lists instruction files with `git ls-files` in the current directory, piped into `grep ... || true` (U0c `lib:350,360-362`). From a directory outside the repo the listing is empty, so the empty set is cached for that root, and a later call from the root returns it (paraphrased — no quote available because the pre-fix lib was rebased away; reasoning from the U0c walk minus the pwd check).

**Evidence:** U0c `scripts/lib/dev-cycle-read.sh:347-376`

---

## Claim 20: "the header now says which checks exit (inrepo, dirok, skipped) and which only read nothing as plain (rawfile, plaindir, blocker), and warns that an exit inside $(...) ends only the subshell"

**Location:** commit `497c8cb5` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the header says this; whether the header is right is Claims 3, 4a, 4b and 5 (4b is Incorrect).
**Legibility target:** for-orchestrator-synthesis

Header `:10-14` carries exactly these sentences (quoted in Claims 3-5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-15`

---

## Claim 21: "need_root's comment says set -u fires in the subshell rather than not at all."

**Location:** commit `497c8cb5` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the correction the bullet claims to make; the comment edit it describes did happen.
**Legibility target:** for-author

The bullet presents "fires ... rather than not at all" as a fact-check correction. In the code it ships, set -u does not fire at all (Claim 8b, E1). The iteration-2 finding it answers said the same: "In the fixed code, `${ROOT_REAL:-}` means set -u no longer fires at all" (`docs/reviews/code-fact-check-report-build-loop-u0a.md:203`). The mechanism the bullet asserts is refuted.

**Evidence:** `LOGS/exp.txt` (E1), `scripts/lib/dev-cycle-read.sh:69-70,77,80`

---

## Claim 22: "The ROOT_REAL test runs its rawfile/plaindir half under set -u, so it fails if their ${ROOT_REAL:-} guard is dropped, and adds a root that is not the current directory. Both mutations checked." / test comment "set -u: without the guards' ${ROOT_REAL:-} the comparison would abort, not close."

**Location:** commit `497c8cb5` message; `test/scripts/dev-cycle.bats:1054`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named mutations plus dropping the `-n` clause entirely; does not establish coverage of rawfile/plaindir under a mismatched root (Claim 4b).
**Legibility target:** for-orchestrator-synthesis

Mutants `rawfile guard bare ROOT_REAL`, `plaindir guard bare ROOT_REAL`, `rawfile guard dropped` and `need_root without pwd check` are all CAUGHT.

Command: `bash mutate.sh u0c` · exit 0 · 2026-10-05T00:35:38-07:00.

**Evidence:** `test/scripts/dev-cycle.bats:1046-1064`, `LOGS/mutate-u0c.txt`

---

## Claim 23: Test name "the lib's file checks stop, not pass, when ROOT_REAL is unset or not the current directory"

**Location:** `test/scripts/dev-cycle.bats:1046`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers inrepo/dirok/skipped for unset, and inrepo only for the not-current-directory case (the others share need_root); does not cover rawfile/plaindir/blocker under a mismatched root.
**Legibility target:** for-orchestrator-synthesis

The loop asserts status 1, empty stdout and "ROOT_REAL is not set" for each of the three checks; the third block asserts "ROOT_REAL is not the current directory" for `inrepo f.md`. Each mutant that removes one need_root call is caught.

**Evidence:** `test/scripts/dev-cycle.bats:1046-1064`, `LOGS/mutate-u0c.txt`

---

## Claim 24: Shellcheck-relevant claims at U0a (no `SC2034` directive needed for ROOT_REAL here, since dev-cycle.sh's own walk still reads it)

**Location:** `scripts/dev-cycle.sh:113-116`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that shellcheck is clean at the tip; does not establish shellcheck version parity with CI.
**Legibility target:** for-orchestrator-synthesis

`shellcheck -x scripts/dev-cycle.sh scripts/lib/dev-cycle-read.sh` printed nothing at U0a.

Command as stated · cwd `.../wt-build-loop-u0a` · 2026-10-05T00:38 · exit 0.

**Evidence:** `LOGS/shellcheck.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4b** (`scripts/lib/dev-cycle-read.sh:10-12`): with ROOT_REAL set but not the cwd, rawfile/plaindir/blocker can read a symlink into the root as plain; limit "read nothing as plain" to the unset case, and say to call them only after need_root.
- **Claim 8b** (`scripts/lib/dev-cycle-read.sh:69-70`): set -u does not fire in blocker's substitution since the `${ROOT_REAL:-}` guards; it would fire only without them. The comment describes the pre-fix code.
- **Claim 21** (commit `497c8cb5`): the "set -u fires rather than not at all" correction is backwards for the shipped code.

### Stale
- none

### Mostly Accurate
- **Claim 17** (commit `32b9ae0e`): settled (override-log row 211); not re-raised.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): one markdown report per unit at OUTPUT_PATTERN (unit = u0a, u0b, u0c), structured per your skill, first line `Commit: <unit tip short SHA>`, ending with the Goal-Alignment Note.
- Answered: yes. Full U0a range checked, with the suite, the digest and every check mode run from main and from each commit, mutations, and experiments.
- Out of scope: the content of the reviews the fix bullets cite; settled override rows 196-200 and 211.
- Escalate: Claims 4b and 8b are comment-only fixes in the U0a lib. The 4b hazard matters once build-loop.sh calls rawfile/plaindir directly.
- Decisions I made: ran bats with the default TMPDIR, because a scratch path containing `.claude` makes main's test 21 fail (git rejects the ref name). I counted the 497c8cb5 set -u bullet as Incorrect rather than as an accurate description of the edit.
