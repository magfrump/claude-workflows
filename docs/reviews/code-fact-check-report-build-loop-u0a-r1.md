Commit: 497c8cb5

# Code Fact-Check Report

**Commit:** 497c8cb5
**Replication:** k=3, replicate 1 (final confirming pass, iteration 3, full scope)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-handoff)
**Scope:** U0a full range `git diff feat/build-loop-handoff..feat/build-loop-u0a` (4ef450da, 32b9ae0e, 497c8cb5: scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats) and the three commit messages. U0b/U0c are context only. Scratch (execution logs, mutation copies): `/home/node/.claude/jobs/989f3e5a/tmp/review/final-fc-r1` (below: `$SCRATCH`).
**Checked:** 2026-10-05
**Total claims checked:** 21
**Summary:** 18 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim in this unit matches a logged pattern. Settled deferrals in `docs/reviews/override-log.md` (rows dated 2026-10-05 for feat/build-loop-u0*) were read; claim 17 is the subject of row 211 and is not re-raised.

Shared executions (all run 2026-10-05 between 07:30Z and 07:40Z, from detached worktrees of each commit under `$SCRATCH/wt-*`):
- E1 `bats test/scripts/dev-cycle.bats` at main, 4ef450da, 32b9ae0e and 497c8cb5 (cwd: each worktree) → exit 0 at each; counts 53 / 55 / 56 / 56, every main test name present. Logs: `$SCRATCH/logs/bats-{main,4ef450da,32b9ae0e,u0a}.log`, summary `$SCRATCH/logs/intermediate.log`.
- E2 `bash $SCRATCH/compare.sh` and `bash $SCRATCH/intermediate.sh`: digest (DEV_CYCLE_TODAY=2026-10-05) and every `--check-*` mode run on this repo (cwd `$SCRATCH/wt-main`) with each commit's script; outputs and exit codes `diff -r`'d against main's. Result: identical for 4ef450da, 32b9ae0e and 497c8cb5. Logs: `$SCRATCH/logs/compare-summary.log`, `$SCRATCH/logs/intermediate.log`, outputs `$SCRATCH/logs/out-*/`.
- E3 `bash $SCRATCH/mutate.sh`: each new test's guard removed in a scratch copy of the U0c tip (the guards below are unchanged from U0a), new tests run with `bats -f`. Every mutation fails exactly the test written for it. Log: `$SCRATCH/logs/mutate.log` (exit 0, 07:34:31Z).
- E4 `bash $SCRATCH/setu.sh` (07:35Z): blocker with ROOT_REAL unset under `set -euo pipefail`, at each tip; and rawfile with ROOT_REAL set to another tree than the cwd. Log: `$SCRATCH/logs/setu.log`.
- E5 `bash $SCRATCH/prefix-u0a.sh` (07:36:34Z): 4ef450da's lib, ROOT_REAL unset. Log: `$SCRATCH/logs/prefix-u0a.log`.
- E6 `bash $SCRATCH/walk-elsewhere.sh` (07:36:26Z): the reviewed U0c walk (27e38dc4) with ROOT_REAL set but the cwd elsewhere. Log: `$SCRATCH/logs/walk-elsewhere.log`.
- E7 `bash $SCRATCH/nomain.sh`: no default branch by name, detached and on `trunk`. Log: `$SCRATCH/logs/nomain.log`.
- E8 move check: removed lines of dev-cycle.sh vs added lines of the lib per move commit (`comm` of sorted lines). Log: `$SCRATCH/logs/move-verbatim.log`.

---

## Claim 1: "used by scripts/dev-cycle.sh and kept apart so the planned scripts/build-loop.sh can share it: the output scrub, the plain-file and path-form rules, and the cycle's own file names."

**Location:** `scripts/lib/dev-cycle-read.sh:2-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib's contents at 497c8cb5 and that build-loop.sh does not exist yet; does not establish anything about build-loop.sh's future use.
**Legibility target:** for-orchestrator-synthesis

The lib at this tip defines `scrub`, `scrub_reexec`, `need_root`, `rawfile`, `plaindir`, `blocker`, `inrepo`, `dirok`, `skipped`, `pathform`, `isbrief` and `writable` (paraphrased — no quote available because the claim is about the file's whole function list; the T29 list in `test/scripts/dev-cycle.bats` names the same set at this tip). `scripts/build-loop.sh` is absent at all three tips (`ls` → "No such file or directory"), so "planned" is right. dev-cycle.sh sources it: `source "$READ_LIB"` (`scripts/dev-cycle.sh:88`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2-4`, `scripts/dev-cycle.sh:85-89`

---

## Claim 2: "Sourced, never run: it only defines functions and variables. Each script sources it from its own directory (never from the repo it acts on), so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/lib/dev-cycle-read.sh:6-8`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sourcing side effects (no git or perl call, only definitions) and dev-cycle.sh's SCRIPT_DIR-based source path; does not establish how a future second script will source it.
**Legibility target:** for-orchestrator-synthesis

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` and `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`scripts/dev-cycle.sh:82`, `:85`) source from the script's own directory, before `cd "$ROOT"` (`:112`). The lib's top level holds only definitions and assignments such as `SKIPPED=(); SKIP_AT=""` (paraphrased — no quote available because the claim covers absence of top-level commands across the whole file). E3's M01 (a top-level `git --version` appended to the lib) fails only "sourcing the reader lib defines its functions and calls neither git nor perl"; M02 (dev-cycle.sh's `[[ -f "$READ_LIB" ]]` line removed) fails only "a copy of dev-cycle.sh without its lib exits 1 and names the lib".

**Evidence:** `scripts/dev-cycle.sh:82-89`, `scripts/lib/dev-cycle-read.sh:6-8`, `$SCRATCH/logs/mutate.log`

---

## Claim 3: "The caller sets -euo pipefail, cds to the repo root and sets ROOT_REAL (that root, symlinks resolved) before calling any file check."

**Location:** `scripts/lib/dev-cycle-read.sh:8-10`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dev-cycle.sh as the one caller at this tip; does not establish it for callers that do not exist yet (the guards in claims 4-5 cover those).
**Legibility target:** for-orchestrator-synthesis

`set -euo pipefail` (`scripts/dev-cycle.sh:79`), `cd "$ROOT"` (`:112`), `ROOT_REAL="$(pwd -P)"` (`:113`); the first file check in the script follows (`skipdir() { skipped "$1" dir; }` is defined at `:114` and every check runs after the option loop). `scrub_reexec` (`:89`) runs earlier but is not a file check.

**Evidence:** `scripts/dev-cycle.sh:79-114`

---

## Claim 4: "inrepo, dirok and skipped exit 1 (need_root) when ROOT_REAL is unset or is not the current directory"

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named functions under both conditions; does not establish that this list names every lib function that exits (at this tip it does; see the U0c report for check_answer).
**Legibility target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:73-76
need_root() {
  [[ -n "${ROOT_REAL:-}" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not set; ..." >&2; exit 1; }
  [[ "$ROOT_REAL" == "$(pwd -P)" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not the current directory; ..." >&2; exit 1; }
}
```
(messages shortened with "..."; the function is quoted whole otherwise)

`inrepo() { need_root; ...`, `dirok() { need_root; ...`, `skipped() { need_root; ...` (`:102-106`). E3: removing need_root from each of the three (M03-M05), or the cwd test (M08), fails "the lib's file checks stop, not pass, when ROOT_REAL is unset or not the current directory".

**Evidence:** `scripts/lib/dev-cycle-read.sh:73-76`, `:102-106`, `$SCRATCH/logs/mutate.log`

---

## Claim 5: "rawfile, plaindir and blocker then read nothing as plain."

**Location:** `scripts/lib/dev-cycle-read.sh:11-12`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both conditions named in the preceding clause; establishes the unset case fully and the not-the-cwd case only for paths whose real path is not `$ROOT_REAL/<path>`; does not establish any harm from the exception (what passes is ROOT_REAL's own plain file).
**Legibility target:** for-author

With ROOT_REAL unset, `rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && ...` (`:77`, and plaindir the same at `:80`) fails, and E4 shows blocker naming the first existing part: `rc=0 blocker=[real/]` for both a file and a dir. With ROOT_REAL set to another tree, the test `[[ "$r" == "$ROOT_REAL/$1" ]]` passes whenever the cwd-relative path resolves to `$ROOT_REAL/<path>`. E4 makes `other/f.md` a symlink to `../r/f.md`, sets ROOT_REAL to `r` with the cwd at `other`, and gets `rawfile f.md: plain` and `blocker f.md=[]`: a symlink read as plain. The precise version: "rawfile, plaindir and blocker then read nothing outside ROOT_REAL as plain". inrepo, dirok and skipped stop first anyway (claim 4), so this matters only to a caller of rawfile/plaindir directly.

**Evidence:** `scripts/lib/dev-cycle-read.sh:77`, `:80`, `:88-98`, `$SCRATCH/logs/setu.log`

---

## Claim 6: "Call the exiting checks in the caller's shell, not inside $(...) or `local x="$(...)"`, where an exit ends only the subshell."

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the subshell semantics of need_root's exit and dev-cycle.sh's call sites; does not establish whether a future caller follows it.
**Legibility target:** for-orchestrator-synthesis

E-probe `$SCRATCH/answer-noroot.sh` (07:38:44Z, cwd `$SCRATCH/wt-main`, U0c's lib, whose need_root is this tip's): `r="$(check_answer Q-104)" || true` prints need_root's message, then `in $(...): r=[], caller continues` and exits 0; called directly it exits 1. dev-cycle.sh calls inrepo/dirok/skipped in `if`/`&&` contexts in its own shell (paraphrased — no quote available because the call sites span the digest; `rg -n 'inrepo|dirok|skipped' scripts/dev-cycle.sh` lists none inside `$(...)`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-14`, `$SCRATCH/logs/answer-noroot.log`

---

## Claim 7: "Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker."

**Location:** `scripts/lib/dev-cycle-read.sh:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the marker name being fixed inside scrub_reexec; does not establish the consequence for nested invocations of two different scripts (only one exists).
**Legibility target:** for-orchestrator-synthesis

`[[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0` and `{ DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" ...` (`:60`, `:62`): the name is a literal, not a parameter.

**Evidence:** `scripts/lib/dev-cycle-read.sh:59-64`

---

## Claim 8: "scrub_reexec takes the script to re-run and its arguments, and returns only in the child (or when the caller already set DEV_CYCLE_SCRUBBED)."

**Location:** `scripts/lib/dev-cycle-read.sh:57-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers scrub_reexec's control flow; does not establish the scrub's filtering (moved text, unchanged; E2's identical outputs cover its effect on this repo).
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
The parent always reaches `exit`; only a process with the marker set (the child, or a caller that set it) returns.

**Evidence:** `scripts/lib/dev-cycle-read.sh:57-64`

---

## Claim 9a: "With no ROOT_REAL nothing is plain (fail closed); need_root makes the callers below stop instead, outside the command substitution where blocker runs"

**Location:** `scripts/lib/dev-cycle-read.sh:68-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rawfile/plaindir with ROOT_REAL unset and need_root's position before `$(blocker ...)` in inrepo/dirok/skipped; does not establish the not-the-cwd case (claim 5).
**Legibility target:** for-orchestrator-synthesis

`inrepo() { need_root; [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:102`): need_root runs in the caller's shell before the substitution. E4: with ROOT_REAL unset, `blocker real/f.md file` prints `real/` (not plain).

**Evidence:** `scripts/lib/dev-cycle-read.sh:68-69`, `:102-106`, `$SCRATCH/logs/setu.log`

---

## Claim 9b: "(set -u fires there, but its error, like an exit, ends only the subshell)"

**Location:** `scripts/lib/dev-cycle-read.sh:69-70`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether an unbound-variable error occurs inside `$(blocker ...)` with ROOT_REAL unset at this tip (and the unchanged U0b/U0c tips); does not dispute that an exit or error inside a substitution ends only the subshell.
**Legibility target:** for-author

The guards this unit added make every read of ROOT_REAL in blocker's path conditional: `[[ -n "${ROOT_REAL:-}" && -f "$1" ]] && ... [[ "$r" == "$ROOT_REAL/$1" ]]` (`:77`; plaindir `:80`), so `$ROOT_REAL` is never expanded when it is unset. E4 runs `x="$(blocker real/f.md file)"` and the dir form under `set -euo pipefail` with ROOT_REAL unset at 497c8cb5, 698348ac and d8da1fba: no "unbound variable" message, `rc=0`, output `real/`. set -u fired only in the pre-fix lib (E5, 4ef450da: `line 63: ROOT_REAL: unbound variable`). Iteration 2's report (Claim 8) already noted "In the fixed code, `${ROOT_REAL:-}` means set -u no longer fires at all"; the rewrite states the opposite. What the code does now: with ROOT_REAL unset nothing in the substitution errors; blocker returns the first existing part as not plain. A precise version: "(an exit there would end only the subshell; set -u no longer fires there, since rawfile and plaindir read `${ROOT_REAL:-}`)". Low impact: the conclusion (stop outside the substitution) holds.

**Evidence:** `scripts/lib/dev-cycle-read.sh:68-70`, `:77`, `:80`, `$SCRATCH/logs/setu.log`, `$SCRATCH/logs/prefix-u0a.log`

---

## Claim 10: "A ROOT_REAL that is not the current directory stops them too: the checks read relative paths, so a stale root would compare one tree's files with another."

**Location:** `scripts/lib/dev-cycle-read.sh:70-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers need_root's cwd test and its effect on inrepo/dirok/skipped; does not establish rawfile/plaindir called directly (claim 5).
**Legibility target:** for-orchestrator-synthesis

`[[ "$ROOT_REAL" == "$(pwd -P)" ]] || { ...; exit 1; }` (`:75`). The relative-path mechanism: `realpath -e -- "$1"` resolves against the cwd and is compared with `"$ROOT_REAL/$1"` (`:77`). E3's M08 (cwd test removed) fails the ROOT_REAL test's "not the current directory" half.

**Evidence:** `scripts/lib/dev-cycle-read.sh:70-77`, `$SCRATCH/logs/mutate.log`

---

## Claim 11: "The reader, kept in a lib so the planned scripts/build-loop.sh can share it, from this script's own directory: the scrub and the file and path rules."

**Location:** `scripts/dev-cycle.sh:83-84`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the source path and the lib's content summary at this tip ("path rules" read as including isbrief/writable); does not establish build-loop.sh's use.
**Legibility target:** for-orchestrator-synthesis

`READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`:85`) and `source "$READ_LIB"` (`:88`); contents per claim 1.

**Evidence:** `scripts/dev-cycle.sh:83-89`

---

## Claim 12: "1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch (for the digest, --check-brief and --check-branch)"

**Location:** `scripts/dev-cycle.sh:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-lib and no-default-branch exits; does not re-check the pre-existing bad-usage/not-a-repo/no-perl exits beyond E2's unchanged outputs.
**Legibility target:** for-orchestrator-synthesis

`[[ -f "$READ_LIB" ]] || { echo "dev-cycle.sh needs $READ_LIB" >&2; exit 1; }` (`:86`); T30 passes at this tip (E1) and M02 fails it (E3). E7: the digest, `--check-brief` and `--check-branch` exit 1 with main's messages in a repo with no main/master, at this tip as at main.

**Evidence:** `scripts/dev-cycle.sh:75-77`, `:86`, `$SCRATCH/logs/nomain.log`, `$SCRATCH/logs/mutate.log`

---

## Claim 13: 4ef450da: "scrub_reexec, the one rewritten part ... the plain-file rules (rawfile, plaindir, blocker, inrepo, dirok, skipped), pathform, isbrief and writable, moved verbatim."

**Location:** commit 4ef450da message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers line content of the moved blocks against main's dev-cycle.sh (multiset comparison); does not establish line order (E2's identical outputs cover behaviour).
**Legibility target:** for-orchestrator-synthesis

E8: lines removed from dev-cycle.sh but not added to the lib are only the old inline re-exec (`if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]; then`, its `{ DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" ...` line, `fi`) and the `SCRIPT_DIR=` line that moved up; lines added to the lib but not removed are the header, `scrub_reexec() {`, its three body lines and blank lines. Every rule function is identical.

**Evidence:** `$SCRATCH/logs/move-verbatim.log`

---

## Claim 14: 4ef450da: "dev-cycle.sh sources it from its own directory and exits 1 when it is missing. Behaviour is otherwise unchanged: the 53 dev-cycle tests pass and the digest of this repo is byte-identical to main's." / "Tests: T29 ... and T30 ..."

**Location:** commit 4ef450da message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tests and outputs at 4ef450da itself; does not establish behaviour beyond the modes E2 exercises.
**Legibility target:** for-orchestrator-synthesis

E1 at 4ef450da: `1..55`, 55 ok, all 53 main test names present. E2: digest and all check modes identical to main's.

**Evidence:** `$SCRATCH/logs/bats-4ef450da.log`, `$SCRATCH/logs/intermediate.log`

---

## Claim 15: 4ef450da Notes: "U0 measured over the 400-line cap (moves count twice), so it splits into three stacked units ... check_path, check_write and check_fix stay in dev-cycle.sh. The plan's lib list also names check_fix's predicate; it stays in dev-cycle.sh, and U2 writes the floor as its own lib function instead (plan amendment in U0c's fix commits)."

**Location:** commit 4ef450da message
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unit split, where the three checks live at the U0c tip, and the amendment's existence; does not re-measure the 400-line count.
**Legibility target:** for-orchestrator-synthesis

`check_path() {`, `check_write() {`, `check_fix() {` are in `scripts/dev-cycle.sh` at the U0c tip (`:139`, `:155`, `:167`); the plan's amendment paragraph and list line arrive in 1c7373d3/d8da1fba (`docs/working/plan-build-loop-handoff.md:187`, `:192`). The plan's "moved lines count twice" rule: "Stacked review units (log row 62: about 400 changed code lines outside `docs/`; moved lines count twice)" (plan `:264` at feat/build-loop-handoff).

**Evidence:** `scripts/dev-cycle.sh:139-181` (U0c tip), `docs/working/plan-build-loop-handoff.md:187-192`, `:264`

---

## Claim 16: 32b9ae0e: "need_root now stops the caller (exit 1) outside the substitution, and rawfile/plaindir treat everything as not plain. dev-cycle.sh always sets ROOT_REAL first, so its behaviour is unchanged. New test: each check exits 1 and rawfile/plaindir fail closed." (and the fact-check/architecture bullets: Exit line names the lib, scrub_reexec returns when the caller set DEV_CYCLE_SCRUBBED, moved comments name dev-cycle.sh's digest, T29 named for what it asserts, header names the marker, `#!/bin/bash` like the sibling libs)

**Location:** commit 32b9ae0e message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change at 32b9ae0e and the unchanged outputs; does not cover the pre-fix description (claim 17).
**Legibility target:** for-orchestrator-synthesis

E1 at 32b9ae0e: 56 ok; E2: identical outputs. Every sibling lib begins `#!/bin/bash` (`head -1 scripts/lib/*.sh`). "A directory dev-cycle.sh's digest globs in" (`scripts/lib/dev-cycle-read.sh:78`). The other bullets match claims 7, 8 and 12.

**Evidence:** `$SCRATCH/logs/bats-32b9ae0e.log`, `$SCRATCH/logs/intermediate.log`, `scripts/lib/dev-cycle-read.sh:1`, `:78`

---

## Claim 17: 32b9ae0e: "with no ROOT_REAL, blocker's unbound-variable error ended only its command substitution, so inrepo, dirok and skipped read a symlink as plain."

**Location:** commit 32b9ae0e message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parent 4ef450da in if/|| contexts; does not cover a top-level `skipped` call under set -e, which exits instead (settled: override-log row 211, not re-raised).
**Legibility target:** for-author

E5 at 4ef450da under `set -euo pipefail` with ROOT_REAL unset: `line 63: ROOT_REAL: unbound variable` then `inrepo link.md: plain`; `dirok linkdir: plain`; `skipped link.md: not skipped`. Precise version as settled: in the if/|| contexts the callers use.

**Evidence:** `$SCRATCH/logs/prefix-u0a.log`, `docs/reviews/override-log.md:211`

---

## Claim 18: 497c8cb5: "need_root checked only that ROOT_REAL was set. With the current directory elsewhere, the import walk cached an empty set (fewer refusals). need_root now also requires ROOT_REAL == $(pwd -P)."

**Location:** commit 497c8cb5 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reviewed U0c walk (27e38dc4) with ROOT_REAL set and the cwd elsewhere, and need_root's new test; does not establish the walk at the current U0c tip, where need_root now stops this case.
**Legibility target:** for-orchestrator-synthesis

Before this commit need_root was one test, `[[ -n "${ROOT_REAL:-}" ]] || {...}` (32b9ae0e). E6, 27e38dc4's lib, ROOT_REAL set to another tree: `walked, IMPORTED=$'\n' DONE=1`, an empty set marked done. At this tip, `[[ "$ROOT_REAL" == "$(pwd -P)" ]]` (`scripts/lib/dev-cycle-read.sh:75`).

**Evidence:** `$SCRATCH/logs/walk-elsewhere.log`, `scripts/lib/dev-cycle-read.sh:73-76`

---

## Claim 19: 497c8cb5: "the header now says which checks exit (inrepo, dirok, skipped) and which only read nothing as plain (rawfile, plaindir, blocker), and warns that an exit inside $(...) ends only the subshell (architecture I1); need_root's comment says set -u fires in the subshell rather than not at all." / "The ROOT_REAL test runs its rawfile/plaindir half under set -u, so it fails if their ${ROOT_REAL:-} guard is dropped, and adds a root that is not the current directory. Both mutations checked."

**Location:** commit 497c8cb5 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the message describes the commit's edits and the test's mutation sensitivity; the edited comment's own accuracy is verdicted separately (claims 5, 9b).
**Legibility target:** for-orchestrator-synthesis

The header (`:10-14`) and need_root comment (`:68-72`) say what the message says they say. E3: M06 (rawfile guard dropped) and M07 (plaindir guard dropped) each fail the ROOT_REAL test; M08 (cwd test dropped) fails it too.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-14`, `:68-72`, `$SCRATCH/logs/mutate.log`

---

## Claim 20: 497c8cb5 Notes: "all 56 tests at this tip pass (main's 53 among them); the digest of this repo is unchanged." / new tests' names vs assertions

**Location:** commit 497c8cb5 message; `test/scripts/dev-cycle.bats:1023-1064` (T29, T30, the ROOT_REAL test)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, the 53 names and the three new tests' names against what they assert and against mutations; does not establish coverage of rawfile/plaindir in the not-the-cwd case (no test, see claim 5).
**Legibility target:** for-orchestrator-synthesis

E1 at 497c8cb5: `1..56`, 56 ok, no main name missing. E2: digest identical. T29 asserts the function list, no stderr, and no stub call (`[ ! -e "$S/called" ]`); T30 asserts exit 1, empty stdout and `needs .../bare/lib/dev-cycle-read.sh`; the ROOT_REAL test asserts exit 1 with "ROOT_REAL is not set" for each check, `closed` twice under `set -u`, and "ROOT_REAL is not the current directory". Each fails under its mutation (E3).

**Evidence:** `test/scripts/dev-cycle.bats`, `$SCRATCH/logs/bats-u0a.log`, `$SCRATCH/logs/mutate.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9b** (`scripts/lib/dev-cycle-read.sh:69-70`): "set -u fires there": with the `${ROOT_REAL:-}` guards nothing in `$(blocker ...)` expands an unset ROOT_REAL, so set -u never fires (E4, at all three tips). Say instead that an exit there would end only the subshell, and that set -u no longer fires because of the guards.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`scripts/lib/dev-cycle-read.sh:11-12`): with ROOT_REAL set to another tree, rawfile reads a cwd symlink that resolves to `$ROOT_REAL/<path>` as plain. "Read nothing outside ROOT_REAL as plain" is exact.
- **Claim 17** (commit 32b9ae0e): true in the if/|| contexts the callers use. Settled by override-log row 211.

### Unverifiable
- None.

## Goal-Alignment Note

The unit's goal is a behaviour-preserving extraction with fail-closed guards. Every behaviour claim holds when executed. Tests (55/56/56 at the three commits, main's 53 among them), the digest and every check mode match main byte for byte, the moves are verbatim apart from scrub_reexec, and each new test fails when its guard is removed. The one Incorrect is a parenthetical in need_root's comment that describes the pre-guard code. It misleads a reader about why the guard matters but changes no behaviour, so it is a one-line comment fix for the author. It does not block landing.
